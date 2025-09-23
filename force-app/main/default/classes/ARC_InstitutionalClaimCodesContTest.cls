@isTest
public with sharing class ARC_InstitutionalClaimCodesContTest {

    @TestSetup
    static void createData(){
        List<Claim> clm = ARC_TestUtility.createTestClaims(1);
        ARC_Institutional_Claim_Code__c clmCode = new ARC_Institutional_Claim_Code__c(ARC_Institutional_Claim__c = clm[0].Id);
        insert clmCode;
    }

    @isTest
    static void executeLogic(){
        Claim c = [SELECT Id FROM Claim];
        ARC_Institutional_Claim_Code__c cCode = [SELECT Id FROM ARC_Institutional_Claim_Code__c];

        Test.startTest();
        ARC_InstitutionalClaimCodesController.getInstitutionalCodes(String.valueOf(c.Id));
        ARC_InstitutionalClaimCodesController.getRecordTypeInstClaimCodes();
        ARC_InstitutionalClaimCodesController.deleteClaimCode(String.valueOf(cCode.Id));
        Test.stopTest();
    }
}