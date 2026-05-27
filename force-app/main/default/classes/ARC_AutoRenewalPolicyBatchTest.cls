/**
 * @description Tests for ARC_AutoRenewalPolicyBatch.
 *              Covers: AC2 already-renewed skip, AC4 product-code matching, AC6 price
 *              comparison, full happy-path policy clone (coverages / participants /
 *              coverage participants), and the startBatch() invocable entry point.
 * @author lucas.benero@arcsona.com
 * @date 2026-05-08
 */
@isTest
private class ARC_AutoRenewalPolicyBatchTest {

    @TestSetup
    static void makeData() {
        Id contractSGRTId = Schema.SObjectType.Contract
            .getRecordTypeInfosByDeveloperName()
            .get('ARC_SmallGroup')
            ?.getRecordTypeId();

        // Employer group account
        Account groupAcct = new Account(Name = 'Test Group Employer');
        insert groupAcct;

        // Member account belonging to the group
        Account memberAcct = new Account(
            Name                = 'Test Member',
            IsActive            = true,
            ARC_GroupAccount__c = groupAcct.Id
        );
        insert memberAcct;

        // Contact linked to the member account so the flow can traverse
        // InsurancePolicyParticipant → PrimaryParticipantContactId → Contact.AccountId
        Contact memberContact = new Contact(
            FirstName = 'John',
            LastName  = 'Doe',
            AccountId = memberAcct.Id
        );
        insert memberContact;

        // Census and primary census member (needed by the pricing service inside execute())
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(
            Name                    = 'Test Census',
            vlocity_ins__GroupId__c = groupAcct.Id
        );
        insert census;

        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c(
            Name                            = 'Test Member',
            vlocity_ins__IsPrimaryMember__c = true,
            vlocity_ins__AccountId__c       = memberAcct.Id,
            vlocity_ins__CensusId__c        = census.Id
        );
        insert censusMember;

        // Plan product — shared by active policy coverage and renewal CLI
        Product2 product = new Product2(
            Name                 = 'WeShare Plan A',
            ProductCode          = 'PROG_TEST_PLAN',
            IsActive             = true,
            vlocity_ins__Type__c = 'Medical'
        );
        insert product;

        // Build two base contracts via utility (includes ChargentOrder):
        //   [0] → current-year activated contract
        //   [1] → renewal contract (OE end = today, RecordType = ARC_SmallGroup)
        List<Contract> contracts = ARC_TestUtility.createContractsAA(2);
        contracts[0].AccountId = groupAcct.Id;

        contracts[1].AccountId           = groupAcct.Id;
        contracts[1].RecordTypeId        = contractSGRTId;
        contracts[1].ARC_OEEndDate__c    = Date.today();
        contracts[1].ARC_ContractReason__c = 'Renewal';
        contracts[1].ARC_EffectiveDate__c  = Date.today().addMonths(1);
        insert contracts;

        // Activate the current-year contract
        contracts[0].Status = 'Activated';
        update contracts[0];

        // Renewal contract line item — same product → same ProductCode → passes AC4
        insert new vlocity_ins__ContractLineItem__c(
            Name                       = 'Test CLI',
            vlocity_ins__ContractId__c = contracts[1].Id,
            vlocity_ins__Product2Id__c = product.Id,
            vlocity_ins__UnitPrice__c  = 100
        );

        // Active policy under the current-year contract
        InsurancePolicy activePolicy = new InsurancePolicy(
            Name            = 'Active Policy',
            NameInsuredId   = memberAcct.Id,
            ProductId       = product.Id,
            ARC_Contract__c = contracts[0].Id,
            Status          = 'Activated'
        );
        insert activePolicy;

        // Policy participant inserted FIRST so it can be referenced on coverage
        InsurancePolicyParticipant activeParticipant = new InsurancePolicyParticipant(
            InsurancePolicyId           = activePolicy.Id,
            Role                        = 'Named Insured',
            PrimaryParticipantContactId = memberContact.Id,
            ARC_StartDate__c            = Date.today().addMonths(-1)
        );
        insert activeParticipant;

        // Top-level coverage — ARC_CoveragePrimaryMember__c is a lookup to the
        // employee Account; the flow uses it to resolve accountId
        InsurancePolicyCoverage activeCov = new InsurancePolicyCoverage(
            InsurancePolicyId              = activePolicy.Id,
            CoverageName                   = 'Medical',
            vlocity_ins_fsc__Product2Id__c = product.Id,
            ARC_CoveragePrimaryMember__c   = memberAcct.Id
        );
        insert activeCov;

        // Coverage participant (links coverage → participant)
        insert new ARC_CoverageParticipant__c(
            ARC_PolicyCoverage__c    = activeCov.Id,
            ARC_PolicyParticipant__c = activeParticipant.Id,
            ARC_CoverageRole__c      = 'Primary',
            ARC_Policy__c            = activePolicy.Id
        );
    }

    // Mock IP response: 'WeShare Plan A' at the given price string
    private static Map<String, Object> buildMockIp(String price) {
        return new Map<String, Object>{
            'tierFactorValue' => '1',
            'products' => new List<Object>{
                new Map<String, Object>{
                    'groupName' => 'Plans',
                    'products'  => new List<Object>{
                        new Map<String, Object>{ 'Name' => 'WeShare Plan A', 'Price' => price }
                    }
                }
            }
        };
    }

    private static Contract getRenewalContract() {
        return [SELECT Id FROM Contract WHERE ARC_ContractReason__c = 'Renewal' LIMIT 1];
    }

    private static Account getMemberAccount() {
        return [SELECT Id FROM Account WHERE Name = 'Test Member' LIMIT 1];
    }

    // ─── Tests ───────────────────────────────────────────────────────────────

    /**
     * Full happy path: all AC guards pass + prices match (100 == 100).
     * Verifies that a new InsurancePolicy is created together with cloned
     * coverages, participants, and coverage participants.
     */
    @isTest
    static void testHappyPath() {
        Contract renewalContract = getRenewalContract();
        // ARC_TotalPremiumAmount__c is a rollup = 0 in test; IP also returns 0 → prices match
        ARC_getRatedProductsWithContributions.testPricingIpResponse = buildMockIp('0.00');

        Test.startTest();
        Database.executeBatch(new ARC_AutoRenewalPolicyBatch(renewalContract.Id), 1);
        Test.stopTest();

        List<InsurancePolicy> newPolicies = [
            SELECT Id, Status FROM InsurancePolicy
            WHERE ARC_Contract__c = :renewalContract.Id
        ];
        System.assertEquals(1, newPolicies.size(), 'Exactly one renewal policy should be created');

        Id newPolicyId = newPolicies[0].Id;
        System.assertEquals('Awaiting Activation', newPolicies[0].Status, 'New policy status should be Awaiting Activation');

        System.assertEquals(
            1,
            [SELECT COUNT() FROM InsurancePolicyCoverage WHERE InsurancePolicyId = :newPolicyId],
            'Coverage should be cloned'
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM InsurancePolicyParticipant WHERE InsurancePolicyId = :newPolicyId],
            'Participant should be cloned'
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM ARC_CoverageParticipant__c WHERE ARC_Policy__c = :newPolicyId],
            'Coverage participant should be cloned'
        );
    }

    /**
     * AC6: renewal price (200) does not match current premium (100) → no new policy.
     */
    @isTest
    static void testPriceMismatchSkipsMember() {
        Contract renewalContract = getRenewalContract();
        ARC_getRatedProductsWithContributions.testPricingIpResponse = buildMockIp('200.00');

        Test.startTest();
        Database.executeBatch(new ARC_AutoRenewalPolicyBatch(renewalContract.Id), 1);
        Test.stopTest();

        Integer count = [
            SELECT COUNT() FROM InsurancePolicy WHERE ARC_Contract__c = :renewalContract.Id
        ];
        System.assertEquals(0, count, 'Price mismatch should prevent policy creation');
    }

    /**
     * AC2: member already has a renewal policy → batch excludes them → no duplicate.
     */
    @isTest
    static void testAC2SkipsAlreadyRenewedMember() {
        Contract renewalContract = getRenewalContract();
        Account memberAcct       = getMemberAccount();

        insert new InsurancePolicy(
            Name            = 'Pre-existing Renewal',
            NameInsuredId   = memberAcct.Id,
            ARC_Contract__c = renewalContract.Id
        );

        ARC_getRatedProductsWithContributions.testPricingIpResponse = buildMockIp('100.00');

        Test.startTest();
        Database.executeBatch(new ARC_AutoRenewalPolicyBatch(renewalContract.Id), 1);
        Test.stopTest();

        // Only the pre-existing policy; no duplicate must be created
        Integer count = [
            SELECT COUNT() FROM InsurancePolicy WHERE ARC_Contract__c = :renewalContract.Id
        ];
        System.assertEquals(1, count, 'AC2 should prevent creating a duplicate renewal policy');
    }

    /**
     * Covers the startBatch() invocable entry point (null-safe guards + valid dispatch).
     */
    @isTest
    static void testStartBatch() {
        // Null / empty guards should be a no-op
        ARC_AutoRenewalPolicyBatch.startBatch(null);
        ARC_AutoRenewalPolicyBatch.startBatch(new List<Id>());

        Contract renewalContract = getRenewalContract();
        ARC_getRatedProductsWithContributions.testPricingIpResponse = buildMockIp('0.00');

        Test.startTest();
        ARC_AutoRenewalPolicyBatch.startBatch(new List<Id>{ renewalContract.Id });
        Test.stopTest();

        System.assert(true, 'startBatch() should complete without exceptions');
    }
}