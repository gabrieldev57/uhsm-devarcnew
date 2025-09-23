@isTest private with sharing class ARC_SendEmailTriggerTest {
    @isTest static void ARC_SendEmailTriggerTest() {
        List<Account> account = ARC_TestUtility.createTestAccount(1, 'StandardAccount');
        List<ARC_EmailCampaign__c> campaigns = ARC_TestUtility.createTestEmailCampaign(1);
        campaigns[0].ARC_AutoEmail__c = true;
        insert campaigns;
        List<ARC_Email__c> emailsList = ARC_TestUtility.createEmails(campaigns[0],account[0].Id);
        emailsList[0].ARC_ManuallySend__c=true;
        
        insert emailsList;
        emailsList[0].ARC_EmailCC__c='aaa@test.com';
        update emailsList;

        //Test.startTest();
       // List<ARC_Email__c> emailTest = [SELECT Id from ARC_Email__c];
        //ARC_EmailSenderTriggerHandler startTest = new ARC_EmailSenderTriggerHandler();
        //System.assertEquals(emailTest.size(),emailsList.size());
        //System.assertEquals(emailTest[0].ARC_EmailCC__c = 'aaa@test.com',emailsList[0].ARC_EmailCC__c = 'aaa@test.com');
        //ARC_EmailSenderTriggerHandler.onBeforeInsert(emailsList);
       // ARC_EmailSenderTriggerHandler.updateEmailsSent(emailsList);
        //Test.stopTest();
    }

}