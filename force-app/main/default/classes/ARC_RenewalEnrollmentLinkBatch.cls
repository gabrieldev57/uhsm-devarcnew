global class ARC_RenewalEnrollmentLinkBatch implements Database.Batchable<SObject>, Schedulable {

    private Id contractId;

    global ARC_RenewalEnrollmentLinkBatch() {}

    global ARC_RenewalEnrollmentLinkBatch(Id contractId) {
        this.contractId = contractId;
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new ARC_RenewalEnrollmentLinkBatch(), 10);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (contractId != null) {
            return Database.getQueryLocator([
                SELECT Id, AccountId
                FROM Contract
                WHERE Id = :contractId
                  AND ARC_OEStartDate__c = TODAY
                  AND RecordType.DeveloperName = 'ARC_SmallGroup'
                  AND ARC_ContractReason__c INCLUDES ('Renewal')
            ]);
        }
        return Database.getQueryLocator([
            SELECT Id, AccountId
            FROM Contract
            WHERE ARC_OEStartDate__c = TODAY
              AND RecordType.DeveloperName = 'ARC_SmallGroup'
              AND ARC_ContractReason__c INCLUDES ('Renewal')
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Contract> contracts) {
        Set<Id> groupAccountIds = new Set<Id>();
        for (Contract c : contracts) {
            if (c.AccountId != null) groupAccountIds.add(c.AccountId);
        }

        List<Account> eligibleAccounts = [
            SELECT Id
            FROM Account
            WHERE ARC_GroupAccount__c IN :groupAccountIds
              AND (IsActive = true OR (ARC_CoverageWaived__c = false AND ARC_TerminationDate__c = null))
        ];

        List<Id> accountIds = new List<Id>();
        for (Account a : eligibleAccounts) {
            accountIds.add(a.Id);
        }

        if (!accountIds.isEmpty()) {
            ARC_SendEnrollmentLink360Controller.sendEmail(accountIds);
        }
    }

    global void finish(Database.BatchableContext bc) {}
}