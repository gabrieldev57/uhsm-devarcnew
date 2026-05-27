public with sharing class ARC_DashboardController {

    public class DashboardCounts {
        @AuraEnabled public Integer activePoliciesCount;
        @AuraEnabled public Integer inProgressPoliciesCount;
        @AuraEnabled public Integer awaitingActivationPoliciesCount;
        @AuraEnabled public Integer coverageWaivedAccountsCount;
        @AuraEnabled public Integer pendingEnrollmentMembersCount;
        @AuraEnabled public Integer upcomingTerminationPoliciesCount;
        @AuraEnabled public Decimal upcomingPaymentAmount;
        @AuraEnabled public Date coveragePaidThrough;
        @AuraEnabled public Decimal finalOutstandingBalance;
        @AuraEnabled public Contract selectedContract;
    }

    // Main method
    @AuraEnabled(cacheable=true)
    public static DashboardCounts getPoliciesfromContracts() {
        DashboardCounts result = new DashboardCounts();
        Date today = Date.today();

        User currentUser = [
            SELECT Id, AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH SECURITY_ENFORCED
        ];

        List<Contract> contracts = [
            SELECT Id,AccountId,ARC_OEStartDate__c, ARC_OEEndDate__c, ARC_NextToBeBilledAmount__c, ARC_CoveragePaidThrough__c,ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Date__c
            FROM Contract
            WHERE AccountId = :currentUser.AccountId
            AND Status NOT IN ('Draft','Voided','Terminated') WITH SECURITY_ENFORCED
            ORDER BY CreatedDate 
            LIMIT 1
        ];

        if (contracts.isEmpty()) {
            return result; // nothing to process
        }

        Contract selectedContract = contracts[0];

        result.activePoliciesCount = getActivePoliciesCount(selectedContract);
        result.inProgressPoliciesCount = getInProgressPoliciesCount(selectedContract);
        result.upcomingTerminationPoliciesCount = getUpcomingTerminationPoliciesCount(selectedContract, today);
        result.coverageWaivedAccountsCount = getCoverageWaivedAccountsCount(selectedContract);
        result.pendingEnrollmentMembersCount = getPendingEnrollmentMembersCount(selectedContract, currentUser, today);
        result.awaitingActivationPoliciesCount = getAwaitingActivationPoliciesCount(selectedContract);
        result.upcomingPaymentAmount = selectedContract.ARC_NextToBeBilledAmount__c;
        result.coveragePaidThrough = selectedContract.ARC_CoveragePaidThrough__c;
        result.selectedContract = selectedContract;

        // Outstanding Balance
        result.finalOutstandingBalance = calculateOutstandingBalance(selectedContract, today);

        return result;
    }

  
    // Helper: Active Policies
    private static Integer getActivePoliciesCount(Contract c) {
        return [SELECT COUNT()
                FROM InsurancePolicy
                WHERE ARC_Contract__c = :c.Id
                AND Status = 'Activated'
                WITH SECURITY_ENFORCED];
    }

 
    // Helper: In Progress Policies
    private static Integer getInProgressPoliciesCount(Contract c) {
        return [SELECT COUNT()
                FROM InsurancePolicy
                WHERE ARC_Contract__c = :c.Id
                AND Status = 'Awaiting Signature'
                WITH SECURITY_ENFORCED];
    }
    
    private static Integer getAwaitingActivationPoliciesCount(Contract c) {
        return [SELECT COUNT()
                FROM InsurancePolicy
                WHERE ARC_Contract__c = :c.Id
                AND Status = 'Awaiting Activation'
                WITH SECURITY_ENFORCED];
    }

 
    // Helper: Upcoming Termination Policies
    private static Integer getUpcomingTerminationPoliciesCount(Contract c, Date today) {
        // Step 1: Collect policies used as PriorPolicy
        Set<Id> usedAsPriorPolicyIds = new Set<Id>();
        for (InsurancePolicy futurePolicy : [
            SELECT PriorPolicyId
            FROM InsurancePolicy
            WHERE ARC_Contract__c = :c.Id
            AND ARC_EffectiveDate__c > :today
            AND PriorPolicyId != null
            WITH SECURITY_ENFORCED
        ]) {
            usedAsPriorPolicyIds.add(futurePolicy.PriorPolicyId);
        }

        // Step 2: Count policies excluding PriorPolicy references
        return [SELECT COUNT()
                FROM InsurancePolicy
                WHERE ARC_Contract__c = :c.Id
                AND ARC_ExpirationDate__c > :today
                AND Status NOT IN ('Voided','Terminated','Draft')
                AND Id NOT IN :usedAsPriorPolicyIds
                WITH SECURITY_ENFORCED];
    }

    // Helper: Coverage Waived Accounts
    private static Integer getCoverageWaivedAccountsCount(Contract c) {
        return [SELECT COUNT()
                FROM Account
                WHERE ARC_CoverageWaived__c = true
                AND ARC_GroupAccount__c = :c.AccountId
                WITH SECURITY_ENFORCED];
    }

    
    // Helper: Pending Enrollment Members
    // Helper: Pending Enrollment Members
    private static Integer getPendingEnrollmentMembersCount(Contract c, User u, Date today) {

        Boolean isWithinOE =
            c.ARC_OEStartDate__c != null &&
            c.ARC_OEEndDate__c != null &&
            today >= c.ARC_OEStartDate__c &&
            today <= c.ARC_OEEndDate__c;
    
        if (isWithinOE) {
            return [
                SELECT COUNT()
                FROM vlocity_ins__GroupCensusMember__c
                WHERE vlocity_ins__CensusId__r.vlocity_ins__GroupId__c = :u.AccountId
                AND vlocity_ins__AccountId__r.ARC_CoverageWaived__c = false AND vlocity_ins__IsPrimaryMember__c = true
                AND vlocity_ins__AccountId__c NOT IN (
                    SELECT NameInsuredId
                    FROM InsurancePolicy
                    WHERE ARC_Contract__c = :c.Id
                )
                WITH SECURITY_ENFORCED
            ];
        } else {
            return [
                SELECT COUNT()
                FROM vlocity_ins__GroupCensusMember__c
                WHERE vlocity_ins__CensusId__r.vlocity_ins__GroupId__c = :u.AccountId
                AND vlocity_ins__AccountId__r.ARC_CoverageWaived__c = false AND vlocity_ins__IsPrimaryMember__c = true
                AND vlocity_ins__AccountId__r.ARC_AllowEnrollmentOutsideOE__c = true
                AND vlocity_ins__AccountId__c NOT IN (
                    SELECT NameInsuredId
                    FROM InsurancePolicy
                    WHERE ARC_Contract__c = :c.Id
                )
                WITH SECURITY_ENFORCED
            ];
        }
    }
 
    // Helper: Outstanding Balance
    private static Decimal calculateOutstandingBalance(Contract c, Date todayDate) {

        if (!shouldCalculateOutstanding(c, todayDate)) {
            return 0;
        }
    
        AggregateResult[] results = [
            SELECT SUM(ARC_AmountDue__c) total
            FROM ARC_Invoice__c
            WHERE ARC_Contract__c = :c.Id
            AND ARC_CoverageDateFrom__c > :c.ARC_CoveragePaidThrough__c
            WITH SECURITY_ENFORCED
        ];

        System.debug('inside method calculateOutstandingBalance results: ' + results);
        System.debug('inside method calculateOutstandingBalance results[0].get(\'total\'): ' + results[0].get('total'));
    
        if (!results.isEmpty() && results[0].get('total') != null) {
            return (Decimal) results[0].get('total');
        }
    
        return 0;
    }

    private static Boolean shouldCalculateOutstanding(Contract c, Date todayDate) {

        System.debug('inside method shouldCalculateOutstanding c.ARC_CoveragePaidThrough__c: ' + c.ARC_CoveragePaidThrough__c);

        if (c.ARC_CoveragePaidThrough__c == null) {
            return false;
        }
    
        Date lastDayCurrentMonth = todayDate.toStartOfMonth().addMonths(1).addDays(-1);

        System.debug('inside method shouldCalculateOutstanding lastDayCurrentMonth: ' + lastDayCurrentMonth);
    
        Boolean condition1 = c.ARC_CoveragePaidThrough__c < todayDate;

        System.debug('inside method shouldCalculateOutstanding condition1: ' + condition1);
    
        Date chargeDate = getChargeDate(c, todayDate);

        System.debug('inside method shouldCalculateOutstanding chargeDate: ' + chargeDate);
    
        Boolean condition2 = chargeDate != null &&
                             chargeDate < todayDate &&
                             c.ARC_CoveragePaidThrough__c == lastDayCurrentMonth;

        System.debug('inside method shouldCalculateOutstanding condition2: ' + condition2);
    
        return condition1 || condition2;
    }

    private static Date getChargeDate(Contract c, Date todayDate) {

        System.debug('inside method getChargeDate c.ARC_RecurringMonthlyOrder__c: ' + c.ARC_RecurringMonthlyOrder__c);

        if (c.ARC_RecurringMonthlyOrder__c == null) {
            return null;
        }
    
        List<ChargentOrders__ChargentOrder__c> orders = [
            SELECT ChargentOrders__Charge_Date__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id = :c.ARC_RecurringMonthlyOrder__c WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    
        System.debug('inside method getChargeDate orders: ' + orders);
        if (orders.isEmpty() || orders[0].ChargentOrders__Charge_Date__c == null) {
            return null;
        }
    
        try {
            Integer chargeDay = Integer.valueOf(orders[0].ChargentOrders__Charge_Date__c);
            System.debug('inside method getChargeDate chargeDay: ' + chargeDay);
            Integer lastDayOfMonth = todayDate.toStartOfMonth().addMonths(1).addDays(-1).day();

            System.debug('inside method getChargeDate lastDayOfMonth: ' + lastDayOfMonth);
    
            if (chargeDay < 1 || chargeDay > lastDayOfMonth) {
                return null;
            }
    
            return Date.newInstance(todayDate.year(), todayDate.month(), chargeDay);
    
        } catch (Exception e) {
            return null;
        }
    }

}