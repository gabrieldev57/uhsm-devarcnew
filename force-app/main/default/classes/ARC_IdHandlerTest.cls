@isTest
public with sharing class ARC_IdHandlerTest {

    @isTest
    public static void insertPolicyIdTest() {
        List<InsurancePolicy> insurancePolicies = ARC_TestUtility.createTestPolicies(1);
        insurancePolicies[0].Name = 'ShopAndEnroll Policy';
        update insurancePolicies;
        Test.startTest();
        ARC_IdHandler.insertPolicyId(insurancePolicies);
        Test.stopTest();
    }

    @isTest
    public static void insertClaimCoveragePaymentDetail() {
        List<ClaimCoveragePaymentDetail> claimCov = new List<ClaimCoveragePaymentDetail>();
        ClaimCoverage c = ARC_TestUtility.createTestClaimCoverage(1)[0];
        ClaimCoveragePaymentDetail cc = new ClaimCoveragePaymentDetail();
        cc.Name = '1';
        cc.ClaimCoverageId = c.Id;
        cc.ARC_Claim__c = c.ClaimId;
        insert cc;
        claimCov.add(cc);

        Test.startTest();
        ARC_IdHandler.insertClaimCoveragePaymentDetail(claimCov);
        Test.stopTest();
    }
}