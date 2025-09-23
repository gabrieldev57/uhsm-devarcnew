@isTest
public with sharing class ARC_ShowClaimsPerPolicyControllerTest {

    @TestSetup
    static void makeData(){
        List<Claim> clmList = ARC_TestUtility.createTestClaims(2);
        List<vlocity_ins__GroupCensusMember__c> gcmList = ARC_TestUtility.createTestCensusMember(1);
    }

    @isTest
    static void getDataTest(){
        List<vlocity_ins__GroupCensusMember__c> gcmList = [SELECT Id FROM vlocity_ins__GroupCensusMember__c];
        ARC_ShowClaimsPerPolicyController.getData(gcmList[0].Id);
    }
    
    @isTest
    static void getDataTestTwo(){
        List<Account> personAccountList = [SELECT Id FROM Account];
        ARC_ShowClaimsPerPolicyController.getData(personAccountList[0].Id);
    }
}