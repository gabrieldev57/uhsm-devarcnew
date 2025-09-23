@isTest
public with sharing class ARC_ValidateClaimAfterMapTest {
    @TestSetup
    static void mockData() {

        ClaimCoveragePaymentDetail ccpd = ARC_TestUtility.createTestCoveragePayments(1)[0];
        Claim claimTest = [SELECT Id FROM Claim LIMIT 1];
        vlocity_ins__VlocityCode__c generalCode = new vlocity_ins__VlocityCode__c();
        generalCode.Name = 'Test general code';
        insert generalCode;
        claimTest.DX_A__c = generalCode.Id;
        claimTest.DX_B__c = generalCode.Id;
        claimTest.DX_C__c = generalCode.Id;
        claimTest.DX_D__c = generalCode.Id;
        claimTest.DX_E__c = generalCode.Id;
        claimTest.DX_F__c = generalCode.Id;
        claimTest.DX_G__c = generalCode.Id;
        claimTest.DX_H__c = generalCode.Id;
        claimTest.DX_I__c = generalCode.Id;
        claimTest.DX_J__c = generalCode.Id;
        claimTest.DX_K__c = generalCode.Id;
        claimTest.DX_L__c = generalCode.Id;
        claimTest.ARC_CCToCompare__c = 'something;another thing';
        update claimTest;
        ccpd.ARC_ProcedureCode__c = generalCode.Id;
        update ccpd;
        ARC_Institutional_Claim_Code__c instClaim = new ARC_Institutional_Claim_Code__c();
        instClaim.ARC_Institutional_Claim__c = claimTest.Id;
        instClaim.ARC_ICD_DX__c = generalCode.Id;
        instClaim.ARC_Other_Procedure_Code__c = generalCode.Id;
        insert instClaim;
    }
    
    @isTest
    public static void getAllClaimCodesTest() {

        Claim claimTest = [SELECT Id FROM Claim LIMIT 1];
        test.startTest();
        Map<String, Object> result = ARC_ValidateClaimAfterMapping.getAllClaimCodes(claimTest.Id);
        test.stopTest();
        Set<String> s = (Set<String>) result.get('codesClaim');
        List<String> l=new List<String>();
        l.addAll(s);
        String stringResult = (String) l.get(0);
        System.assertEquals('Test general code', stringResult);
        System.debug(result);
    }
}