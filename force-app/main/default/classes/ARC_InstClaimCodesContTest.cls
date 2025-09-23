@isTest
public with sharing class ARC_InstClaimCodesContTest {


    @TestSetup
    static void mockData() {

        Claim claimTest = ARC_TestUtility.createTestClaims(1)[0];
        ARC_Institutional_Claim_Code__c instClaimTest = new ARC_Institutional_Claim_Code__c();
        instClaimTest.ARC_Institutional_Claim__c = claimTest.Id;
        insert instClaimTest;
    }
    
    @isTest
    public static void getInstitutionalCodesTest() {
        Claim claimTest = [SELECT Id FROM Claim LIMIT 1 ];
        ARC_Institutional_Claim_Code__c instClaimTest = [SELECT Id FROM ARC_Institutional_Claim_Code__c WHERE ARC_Institutional_Claim__c =: claimTest.Id LIMIT 1 ];
        test.startTest();
        Claim claimResult = ARC_InstitutionalClaimCodesController.getInstitutionalCodes(claimTest.Id);
        test.stopTest();
        System.assertEquals(claimTest.Id, claimResult.Id);
    }

    @isTest
    public static void getRTInstClaimCodesTest() {

        test.startTest();
        List<RecordType> institutionalClaimCodeMethod = ARC_InstitutionalClaimCodesController.getRecordTypeInstClaimCodes();
        test.stopTest();
        System.debug(institutionalClaimCodeMethod);
    }

    @isTest
    public static void deleteClaimCodeTest() {

        Boolean exceptionOccurred = false;
        Claim claimTest = [SELECT Id FROM Claim LIMIT 1 ];
        ARC_Institutional_Claim_Code__c instClaimTest = [SELECT Id FROM ARC_Institutional_Claim_Code__c WHERE ARC_Institutional_Claim__c =: claimTest.Id LIMIT 1 ];
        test.startTest();
        Boolean result = ARC_InstitutionalClaimCodesController.deleteClaimCode(instClaimTest.Id);    
        Boolean resultException = ARC_InstitutionalClaimCodesController.deleteClaimCode(instClaimTest.Id);
        test.stopTest();
        System.assertEquals(true, result);
        System.assertEquals(false, resultException, 'An Exception was thrown');

    }

}