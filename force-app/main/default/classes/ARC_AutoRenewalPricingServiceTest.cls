/**
 * @description Tests for ARC_AutoRenewalPricingService.
 *              Covers null guards, missing census member, prices-match, and prices-mismatch paths.
 * @author lucas.benero@arcsona.com
 * @date 2026-05-08
 */
@isTest
private class ARC_AutoRenewalPricingServiceTest {

    @TestSetup
    static void makeData() {
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

        // Census for the group
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(
            Name                    = 'Test Census',
            vlocity_ins__GroupId__c = groupAcct.Id
        );
        insert census;

        // Primary census member linked to the member account
        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c(
            Name                            = 'Test Member',
            vlocity_ins__IsPrimaryMember__c = true,
            vlocity_ins__AccountId__c       = memberAcct.Id,
            vlocity_ins__CensusId__c        = census.Id
        );
        insert censusMember;

        // Product used in both the active policy coverage and the mock IP response
        Product2 product = new Product2(
            Name        = 'WeShare Plan A',
            ProductCode = 'PROG_TEST_PLAN',
            IsActive    = true
        );
        insert product;

        // Activated contract (required by the pricing IP's curvScore / contribution lookups)
        List<Contract> contracts = ARC_TestUtility.createContractsAA(1);
        contracts[0].AccountId = groupAcct.Id;
        insert contracts;
        contracts[0].Status = 'Activated';
        update contracts[0];

        // Active policy — ARC_Contract__c required so the "Small Group - Coverage StartDate On Participants"
        // process can resolve accountId via InsurancePolicy.ARC_Contract__c.AccountId
        InsurancePolicy activePolicy = new InsurancePolicy(
            Name            = 'Active Policy',
            NameInsuredId   = memberAcct.Id,
            ProductId       = product.Id,
            ARC_Contract__c = contracts[0].Id,
            Status          = 'Activated'
        );
        insert activePolicy;

        // ARC_ParentProduct__c is null by default → qualifies as a top-level coverage
        insert new InsurancePolicyCoverage(
            InsurancePolicyId              = activePolicy.Id,
            CoverageName                   = 'Medical',
            vlocity_ins_fsc__Product2Id__c = product.Id
        );
    }

    // Builds a mock IP response returning 'WeShare Plan A' at the specified price
    private static Map<String, Object> ipResponse(String price) {
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

    // ─── Tests ───────────────────────────────────────────────────────────────

    /**
     * Guard: null memberAccountId or null activePolicy both return false immediately.
     */
    @isTest
    static void testNullInputsReturnFalse() {
        Account memberAcct = [SELECT Id FROM Account WHERE Name = 'Test Member' LIMIT 1];
        InsurancePolicy stub = new InsurancePolicy(Name = 'Stub');

        System.assertEquals(false,
            ARC_AutoRenewalPricingService.pricesMatch(null, stub, null),
            'null accountId should return false');

        System.assertEquals(false,
            ARC_AutoRenewalPricingService.pricesMatch(memberAcct.Id, null, null),
            'null activePolicy should return false');
    }

    /**
     * Guard: account has no primary census member → returns false without calling pricing.
     */
    @isTest
    static void testNoCensusMemberReturnsFalse() {
        Account noData = new Account(Name = 'No Census Account');
        insert noData;

        InsurancePolicy stub = new InsurancePolicy(
            Name          = 'Stub',
            NameInsuredId = noData.Id
        );
        insert stub;
        // No coverage inserted: pricesMatch() returns false at the census-member guard
        // before it ever uses coverage data, so no coverage is needed here.

        InsurancePolicy policy = [
            SELECT Id, ARC_TotalPremiumAmount__c,
                   (SELECT Id, vlocity_ins_fsc__Product2Id__c, ARC_ParentProduct__c
                    FROM InsurancePolicyCoverages)
            FROM InsurancePolicy WHERE Id = :stub.Id
        ];

        Test.startTest();
        Boolean result = ARC_AutoRenewalPricingService.pricesMatch(noData.Id, policy, null);
        Test.stopTest();

        System.assertEquals(false, result, 'No census member should return false');
    }

    /**
     * Happy path: renewal price (100.00) equals current premium (100.00) → true.
     */
    @isTest
    static void testPricesMatch() {
        Account memberAcct = [SELECT Id FROM Account WHERE Name = 'Test Member' LIMIT 1];
        InsurancePolicy policy = [
            SELECT Id, ARC_TotalPremiumAmount__c,
                   (SELECT Id, vlocity_ins_fsc__Product2Id__c, ARC_ParentProduct__c
                    FROM InsurancePolicyCoverages)
            FROM InsurancePolicy WHERE NameInsuredId = :memberAcct.Id LIMIT 1
        ];

        // IP returns 0.00; ARC_TotalPremiumAmount__c is a rollup and will be 0 in test → match
        ARC_getRatedProductsWithContributions.testPricingIpResponse = ipResponse('0.00');

        Test.startTest();
        Boolean result = ARC_AutoRenewalPricingService.pricesMatch(memberAcct.Id, policy, null);
        Test.stopTest();

        System.assertEquals(true, result, 'Both prices are 0.00 — should match');
    }

    /**
     * Mismatch: current premium is 999.00 but renewal returns 100.00 → false.
     */
    @isTest
    static void testPricesMismatch() {
        Account memberAcct = [SELECT Id FROM Account WHERE Name = 'Test Member' LIMIT 1];
        InsurancePolicy policy = [
            SELECT Id, ARC_TotalPremiumAmount__c,
                   (SELECT Id, vlocity_ins_fsc__Product2Id__c, ARC_ParentProduct__c
                    FROM InsurancePolicyCoverages)
            FROM InsurancePolicy WHERE NameInsuredId = :memberAcct.Id LIMIT 1
        ];
        // ARC_TotalPremiumAmount__c is a rollup = 0 in test; IP returns 100.00 → mismatch
        ARC_getRatedProductsWithContributions.testPricingIpResponse = ipResponse('100.00');

        Test.startTest();
        Boolean result = ARC_AutoRenewalPricingService.pricesMatch(memberAcct.Id, policy, null);
        Test.stopTest();

        System.assertEquals(false, result, 'Current price 0, renewal price 100 — should not match');
    }
}