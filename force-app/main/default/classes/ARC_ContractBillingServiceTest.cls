@isTest
private with sharing class ARC_ContractBillingServiceTest {
    private static final Date CONTRACT_EFFECTIVE_DATE = Date.newInstance(2026, 1, 1);
    private static final Date PAID_THROUGH_DATE = Date.newInstance(2026, 1, 31);
    private static final Date INVOICED_THROUGH_DATE = Date.newInstance(2026, 1, 31);
    private static final Date NEXT_INVOICE_COVERAGE_START = Date.newInstance(2026, 2, 1);

    @testSetup
    static void setup() {
        Account groupAccount = createBusinessAccount('Test Group Account');
        insert groupAccount;

        Account insuredEmployeeA = createPersonStyleAccount('Employee A');
        Account insuredEmployeeB = createPersonStyleAccount('Employee B');
        insert new List<Account>{ insuredEmployeeA, insuredEmployeeB };

        Contract contractA = new Contract(
            AccountId = groupAccount.Id,
            Status = 'Draft',
            StartDate = CONTRACT_EFFECTIVE_DATE,
            ContractTerm = 12,
            ARC_EffectiveDate__c = CONTRACT_EFFECTIVE_DATE,
            ARC_CoveragePaidThrough__c = PAID_THROUGH_DATE,
            ARC_CoverageInvoicedThrough__c = INVOICED_THROUGH_DATE,
            ARC_NextInvoiceCoverageStart__c = NEXT_INVOICE_COVERAGE_START,
            ARC_PaymentFrequency__c = 'Monthly'
        );
        insert contractA;

        List<InsurancePolicy> policies = new List<InsurancePolicy>{
            new InsurancePolicy(
                Name = 'EMP-A-POLICY-JAN',
                ARC_Contract__c = contractA.Id,
                NameInsuredId = insuredEmployeeA.Id,
                Status = 'Activated',
                ARC_PolicyEffectiveDate__c = Date.newInstance(2026, 1, 1),
                ARC_PolicyExpirationDate__c = Date.newInstance(2026, 1, 31),
                ARC_NextInvoiceEligible__c = false,
                ARC_NextPaymentEligible__c = false
            ),
            new InsurancePolicy(
                Name = 'EMP-A-POLICY-FEB',
                ARC_Contract__c = contractA.Id,
                NameInsuredId = insuredEmployeeA.Id,
                Status = 'Activated',
                ARC_PolicyEffectiveDate__c = Date.newInstance(2026, 2, 1),
                ARC_PolicyExpirationDate__c = null,
                ARC_NextInvoiceEligible__c = false,
                ARC_NextPaymentEligible__c = false
            ),
            new InsurancePolicy(
                Name = 'EMP-A-POLICY-CANCELLED',
                ARC_Contract__c = contractA.Id,
                NameInsuredId = insuredEmployeeA.Id,
                Status = 'Initial',
                ARC_PolicyEffectiveDate__c = Date.newInstance(2026, 2, 1),
                ARC_PolicyExpirationDate__c = null,
                ARC_NextInvoiceEligible__c = false,
                ARC_NextPaymentEligible__c = false
            ),
            new InsurancePolicy(
                Name = 'EMP-B-POLICY-TERM',
                ARC_Contract__c = contractA.Id,
                NameInsuredId = insuredEmployeeB.Id,
                Status = 'Terminated',
                ARC_PolicyEffectiveDate__c = Date.newInstance(2026, 1, 15),
                ARC_PolicyExpirationDate__c = Date.newInstance(2026, 2, 15),
                ARC_NextInvoiceEligible__c = false,
                ARC_NextPaymentEligible__c = false
            )
        };
        insert policies;

        List<InsurancePolicy> insertedPolicies = [
            SELECT Id, Name
            FROM InsurancePolicy
            WHERE Name IN ('EMP-A-POLICY-JAN', 'EMP-A-POLICY-FEB', 'EMP-B-POLICY-TERM')
        ];
        Map<String, Id> policyIdByName = new Map<String, Id>();
        for (InsurancePolicy policy : insertedPolicies) {
            policyIdByName.put(policy.Name, policy.Id);
        }

        List<InsurancePolicyCoverage> coverages = new List<InsurancePolicyCoverage>{
            new InsurancePolicyCoverage(
                InsurancePolicyId = policyIdByName.get('EMP-A-POLICY-JAN'),
                ARC_UnitPrice__c = 120
            ),
            new InsurancePolicyCoverage(
                InsurancePolicyId = policyIdByName.get('EMP-A-POLICY-FEB'),
                ARC_UnitPrice__c = 135
            ),
            new InsurancePolicyCoverage(
                InsurancePolicyId = policyIdByName.get('EMP-B-POLICY-TERM'),
                ARC_UnitPrice__c = 90
            )
        };
        insert coverages;
    }

    @isTest
    static void testEvaluatePolicyEligibilityForContracts_selectsMostRecentEligiblePolicy() {
        Contract contractA = [
            SELECT Id
            FROM Contract
            WHERE Account.Name = 'Test Group Account'
            LIMIT 1
        ];

        Test.startTest();
        ARC_ContractBillingService.evaluatePolicyEligibilityForContracts(new Set<Id>{ contractA.Id });
        Test.stopTest();

        Map<String, InsurancePolicy> policyByName = getPoliciesByName();

        System.assertEquals(false, policyByName.get('EMP-A-POLICY-JAN').ARC_NextInvoiceEligible__c,
            'The January policy should not be invoice eligible for the February anchor date.');
        System.assertEquals(false, policyByName.get('EMP-A-POLICY-JAN').ARC_NextPaymentEligible__c,
            'The January policy should not be payment eligible for the February anchor date.');

        System.assertEquals(true, policyByName.get('EMP-A-POLICY-FEB').ARC_NextInvoiceEligible__c,
            'The February policy should be selected as the next invoice eligible policy.');
        System.assertEquals(true, policyByName.get('EMP-A-POLICY-FEB').ARC_NextPaymentEligible__c,
            'The February policy should be selected as the next payment eligible policy.');
    }

    @isTest
    static void testEvaluatePolicyEligibilityForContracts_ignoresInvalidStatus() {
        Contract contractA = [
            SELECT Id
            FROM Contract
            WHERE Account.Name = 'Test Group Account'
            LIMIT 1
        ];

        Test.startTest();
        ARC_ContractBillingService.evaluatePolicyEligibilityForContracts(new Set<Id>{ contractA.Id });
        Test.stopTest();

        InsurancePolicy cancelledPolicy = [
            SELECT Id, ARC_NextInvoiceEligible__c, ARC_NextPaymentEligible__c
            FROM InsurancePolicy
            WHERE Name = 'EMP-A-POLICY-CANCELLED'
            LIMIT 1
        ];

        System.assertEquals(false, cancelledPolicy.ARC_NextInvoiceEligible__c,
            'A policy with an invalid status should never be marked as next invoice eligible.');
        System.assertEquals(false, cancelledPolicy.ARC_NextPaymentEligible__c,
            'A policy with an invalid status should never be marked as next payment eligible.');
    }

    @isTest
    static void testEvaluatePolicyEligibilityForContracts_allowsTerminatedPolicyWhenDatesStillMatch() {
        Contract contractA = [
            SELECT Id
            FROM Contract
            WHERE Account.Name = 'Test Group Account'
            LIMIT 1
        ];

        Test.startTest();
        ARC_ContractBillingService.evaluatePolicyEligibilityForContracts(new Set<Id>{ contractA.Id });
        Test.stopTest();

        InsurancePolicy terminatedPolicy = [
            SELECT Id, ARC_NextInvoiceEligible__c, ARC_NextPaymentEligible__c
            FROM InsurancePolicy
            WHERE Name = 'EMP-B-POLICY-TERM'
            LIMIT 1
        ];

        System.assertEquals(true, terminatedPolicy.ARC_NextInvoiceEligible__c,
            'A terminated policy should remain invoice eligible when the anchor date is still within its valid date range.');
        System.assertEquals(true, terminatedPolicy.ARC_NextPaymentEligible__c,
            'A terminated policy should remain payment eligible when the anchor date is still within its valid date range.');
    }

    @isTest
    static void testEvaluatePolicyEligibilityForContracts_bulkProcessesContractIds() {
        Contract contractA = [
            SELECT Id
            FROM Contract
            WHERE Account.Name = 'Test Group Account'
            LIMIT 1
        ];

        Test.startTest();
        ARC_ContractBillingService.evaluatePolicyEligibilityForContracts(new Set<Id>{ contractA.Id });
        Test.stopTest();

        Map<String, InsurancePolicy> policyByName = getPoliciesByName();

        System.assertEquals(true, policyByName.get('EMP-A-POLICY-FEB').ARC_NextInvoiceEligible__c,
            'Bulk contract evaluation should mark the correct invoice-eligible policy.');
        System.assertEquals(true, policyByName.get('EMP-A-POLICY-FEB').ARC_NextPaymentEligible__c,
            'Bulk contract evaluation should mark the correct payment-eligible policy.');
        System.assertEquals(true, policyByName.get('EMP-B-POLICY-TERM').ARC_NextInvoiceEligible__c,
            'Bulk contract evaluation should also process the second insured under the same contract.');
        System.assertEquals(true, policyByName.get('EMP-B-POLICY-TERM').ARC_NextPaymentEligible__c,
            'Bulk contract evaluation should also process payment eligibility for the second insured.');
        System.assertEquals(false, policyByName.get('EMP-A-POLICY-CANCELLED').ARC_NextInvoiceEligible__c,
            'Bulk contract evaluation should continue to ignore policies with invalid status.');
        System.assertEquals(false, policyByName.get('EMP-A-POLICY-CANCELLED').ARC_NextPaymentEligible__c,
            'Bulk contract evaluation should continue to ignore policies with invalid status.');
    }

    @isTest
    static void testEvaluateAdjustmentsForPoliciesBulk_createsCreditAndDebitForSingleEmployee() {
        Contract contractA = getContractByAccountName('Test Group Account');
        Account employeeA = getAccountByName('Employee A');
        Map<String, InsurancePolicy> policyByName = getPoliciesByName();
        Map<String, InsurancePolicyCoverage> coverageByPolicyName = getCoverageByPolicyName();

        ARC_Invoice__c januaryInvoice = createInvoice(
            contractA.Id,
            Date.newInstance(2026, 1, 1),
            100
        );
        insert januaryInvoice;

        insert new ARC_InvoiceLineItem__c(
            ARC_Invoice__c = januaryInvoice.Id,
            ARC_Employee__c = employeeA.Id,
            ARC_Policy__c = policyByName.get('EMP-A-POLICY-JAN').Id,
            ARC_PolicyCoverage__c = coverageByPolicyName.get('EMP-A-POLICY-JAN').Id,
            ARC_CoverageAmount__c = 100,
            ARC_CoverageDateFrom__c = Date.newInstance(2026, 1, 1),
            ARC_CoverageDateTo__c = Date.newInstance(2026, 1, 31),
            ARC_Type__c = 'Coverage'
        );

        String empKey = String.valueOf(contractA.Id) + '_' + String.valueOf(employeeA.Id);
        Map<String, List<Id>> policyIdsByEmployee = new Map<String, List<Id>>{
            empKey => new List<Id>{ policyByName.get('EMP-A-POLICY-JAN').Id }
        };

        Test.startTest();
        ARC_ContractBillingService.evaluateAdjustmentsForPoliciesBulk(policyIdsByEmployee, null);
        Test.stopTest();

        List<ARC_Adjustment__c> adjustments = [
            SELECT Id, Name, ARC_Status__c, ARC_Amount__c, ARC_Policy__c, ARC_PolicyCoverage__c,
                   ARC_CoverageDateFrom__c, ARC_CoverageDateTo__c
            FROM ARC_Adjustment__c
            WHERE ARC_Policy__c IN :new Set<Id>{
                policyByName.get('EMP-A-POLICY-JAN').Id,
                policyByName.get('EMP-A-POLICY-FEB').Id
            }
            ORDER BY ARC_Amount__c ASC
        ];

        System.assertEquals(2, adjustments.size(),
            'The adjustment evaluation should create one credit and one debit adjustment.');
        System.assertEquals(-100, adjustments[0].ARC_Amount__c,
            'The first adjustment should reverse the billed January amount as a credit.');
        System.assertEquals('Open', adjustments[0].ARC_Status__c,
            'Newly created credit adjustments should be left open.');
        System.assertEquals(policyByName.get('EMP-A-POLICY-JAN').Id, adjustments[0].ARC_Policy__c,
            'The credit should stay attached to the billed January policy.');
        System.assertEquals(coverageByPolicyName.get('EMP-A-POLICY-JAN').Id, adjustments[0].ARC_PolicyCoverage__c,
            'The credit should be tied to the January policy coverage.');
        System.assertEquals(Date.newInstance(2026, 1, 1), adjustments[0].ARC_CoverageDateFrom__c,
            'The credit adjustment should target the January billing period start.');
        System.assertEquals(Date.newInstance(2026, 1, 31), adjustments[0].ARC_CoverageDateTo__c,
            'The credit adjustment should target the January billing period end.');

        System.assertEquals(120, adjustments[1].ARC_Amount__c,
            'The second adjustment should re-bill the correct January coverage amount as a debit.');
        System.assertEquals('Open', adjustments[1].ARC_Status__c,
            'Newly created debit adjustments should be left open.');
        System.assertEquals(policyByName.get('EMP-A-POLICY-JAN').Id, adjustments[1].ARC_Policy__c,
            'For January, the debit should remain attached to the correct policy for that period.');
        System.assertEquals(coverageByPolicyName.get('EMP-A-POLICY-JAN').Id, adjustments[1].ARC_PolicyCoverage__c,
            'The debit should be tied to the same January coverage that defines the correct amount.');
    }

    @isTest
    static void testEvaluateAdjustmentsForPoliciesBulk_processesAllEmployeesAndLeavesUnbilledEmployeeUntouched() {
        Contract contractA = getContractByAccountName('Test Group Account');
        Account employeeA = getAccountByName('Employee A');
        Account employeeB = getAccountByName('Employee B');
        Map<String, InsurancePolicy> policyByName = getPoliciesByName();
        Map<String, InsurancePolicyCoverage> coverageByPolicyName = getCoverageByPolicyName();

        ARC_Invoice__c januaryInvoiceEmployeeA = createInvoice(
            contractA.Id,
            Date.newInstance(2026, 1, 1),
            100
        );
        ARC_Invoice__c januaryInvoiceEmployeeB = createInvoice(
            contractA.Id,
            Date.newInstance(2026, 1, 15),
            90
        );
        insert new List<ARC_Invoice__c>{ januaryInvoiceEmployeeA, januaryInvoiceEmployeeB };

        insert new List<ARC_InvoiceLineItem__c>{
            new ARC_InvoiceLineItem__c(
                ARC_Invoice__c = januaryInvoiceEmployeeA.Id,
                ARC_Employee__c = employeeA.Id,
                ARC_Policy__c = policyByName.get('EMP-A-POLICY-JAN').Id,
                ARC_PolicyCoverage__c = coverageByPolicyName.get('EMP-A-POLICY-JAN').Id,
                ARC_CoverageAmount__c = 100,
                ARC_CoverageDateFrom__c = Date.newInstance(2026, 1, 1),
                ARC_CoverageDateTo__c = Date.newInstance(2026, 1, 31),
                ARC_Type__c = 'Coverage'
            ),
            new ARC_InvoiceLineItem__c(
                ARC_Invoice__c = januaryInvoiceEmployeeB.Id,
                ARC_Employee__c = employeeB.Id,
                ARC_Policy__c = policyByName.get('EMP-B-POLICY-TERM').Id,
                ARC_PolicyCoverage__c = coverageByPolicyName.get('EMP-B-POLICY-TERM').Id,
                ARC_CoverageAmount__c = 90,
                ARC_CoverageDateFrom__c = Date.newInstance(2026, 1, 15),
                ARC_CoverageDateTo__c = Date.newInstance(2026, 2, 14),
                ARC_Type__c = 'Coverage'
            )
        };

        String empKeyA = String.valueOf(contractA.Id) + '_' + String.valueOf(employeeA.Id);
        String empKeyB = String.valueOf(contractA.Id) + '_' + String.valueOf(employeeB.Id);
        Map<String, List<Id>> policyIdsByEmployee = new Map<String, List<Id>>{
            empKeyA => new List<Id>{ policyByName.get('EMP-A-POLICY-JAN').Id },
            empKeyB => new List<Id>{ policyByName.get('EMP-B-POLICY-TERM').Id }
        };

        Test.startTest();
        ARC_ContractBillingService.evaluateAdjustmentsForPoliciesBulk(policyIdsByEmployee, null);
        Test.stopTest();

        List<ARC_Adjustment__c> employeeAAdjustments = [
            SELECT Id, ARC_Amount__c, ARC_Status__c, ARC_Policy__c, ARC_CoverageDateFrom__c, ARC_CoverageDateTo__c
            FROM ARC_Adjustment__c
            WHERE ARC_Policy__c IN :new Set<Id>{
                policyByName.get('EMP-A-POLICY-JAN').Id,
                policyByName.get('EMP-A-POLICY-FEB').Id
            }
        ];
        System.assertEquals(2, employeeAAdjustments.size(),
            'Contract-wide adjustment evaluation should create the expected January credit and debit for Employee A.');

        List<ARC_Adjustment__c> employeeBAdjustments = [
            SELECT Id
            FROM ARC_Adjustment__c
            WHERE ARC_Policy__c = :policyByName.get('EMP-B-POLICY-TERM').Id
        ];
        System.assertEquals(0, employeeBAdjustments.size(),
            'Employee B should not receive adjustments when the billed amount already matches the coverage amount.');
    }

    private static ARC_Invoice__c createInvoice(Id contractId, Date coverageDateFrom, Decimal amountDue) {
        return new ARC_Invoice__c(
            ARC_Contract__c = contractId,
            ARC_CoverageDateFrom__c = coverageDateFrom,
            ARC_AmountDue__c = amountDue
        );
    }

    private static Contract getContractByAccountName(String accountName) {
        return [
            SELECT Id, AccountId, ARC_CoverageInvoicedThrough__c, ARC_PaymentFrequency__c,
                   ARC_NextInvoiceCoverageStart__c, ARC_CoveragePaidThrough__c, ARC_EffectiveDate__c
            FROM Contract
            WHERE Account.Name = :accountName
            LIMIT 1
        ];
    }

    private static Account getAccountByName(String accountName) {
        return [
            SELECT Id, Name
            FROM Account
            WHERE Name = :accountName
            LIMIT 1
        ];
    }

    private static Map<String, InsurancePolicyCoverage> getCoverageByPolicyName() {
        Map<String, InsurancePolicyCoverage> coverageByPolicyName = new Map<String, InsurancePolicyCoverage>();
        for (InsurancePolicyCoverage coverage : [
            SELECT Id, InsurancePolicyId, ARC_UnitPrice__c, InsurancePolicy.Name
            FROM InsurancePolicyCoverage
            WHERE InsurancePolicy.Name IN (
                'EMP-A-POLICY-JAN',
                'EMP-A-POLICY-FEB',
                'EMP-B-POLICY-TERM'
            )
        ]) {
            coverageByPolicyName.put(coverage.InsurancePolicy.Name, coverage);
        }
        return coverageByPolicyName;
    }

    private static Map<String, InsurancePolicy> getPoliciesByName() {
        Map<String, InsurancePolicy> policyByName = new Map<String, InsurancePolicy>();
        for (InsurancePolicy policy : [
            SELECT Id, Name, Status, NameInsuredId,
                   ARC_PolicyEffectiveDate__c, ARC_PolicyExpirationDate__c,
                   ARC_NextInvoiceEligible__c, ARC_NextPaymentEligible__c,
                   ARC_Contract__c, ARC_TotalPremiumAmount__c
            FROM InsurancePolicy
            WHERE Name IN (
                'EMP-A-POLICY-JAN',
                'EMP-A-POLICY-FEB',
                'EMP-A-POLICY-CANCELLED',
                'EMP-B-POLICY-TERM'
            )
        ]) {
            policyByName.put(policy.Name, policy);
        }
        return policyByName;
    }

    private static Account createBusinessAccount(String accountName) {
        return new Account(
            Name = accountName
        );
    }

    private static Account createPersonStyleAccount(String accountName) {
        return new Account(
            Name = accountName
        );
    }
}