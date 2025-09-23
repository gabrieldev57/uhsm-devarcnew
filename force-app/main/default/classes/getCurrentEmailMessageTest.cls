@isTest
public with sharing class getCurrentEmailMessageTest {

    @TestSetup
    static void makeData(){
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account acc = new Account(FirstName='Test', LastName = 'Account');
        insert acc;

        vlocity_ins__GroupCensus__c c = new vlocity_ins__GroupCensus__c(vlocity_ins__GroupId__c=acc.Id);
        insert c;
        
        Account personAcc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount', LastName ='Test');
        insert personAcc;
  
        vlocity_ins__GroupCensusMember__c v = new vlocity_ins__GroupCensusMember__c(vlocity_ins__CensusId__c=c.Id, vlocity_ins__ContactId__c = personAcc.PersonContactId);
        insert v;

        EmailMessage e = new EmailMessage(ARC_CensusMember__c = v.Id);
        insert e;

    }

    @isTest
     static void getCurrentEmailMessageTest() {
        List<EmailMessage> test = new List<EmailMessage> ();
        Id recordId = [SELECT Id,ARC_CensusMember__c FROM EmailMessage WHERE ARC_CensusMember__c != NULL ORDER BY CreatedDate DESC LIMIT 1].ARC_CensusMember__c;

        List<EmailMessage> query = [SELECT Id,FromAddress,ToAddress,Subject,RelatedToId,HtmlBody,CreatedDate,MessageDate  FROM EmailMessage WHERE ARC_CensusMember__c = :recordId ORDER BY CreatedDate DESC ];
        
        test = getCurrentEmailMessage.getCurrentEmailMessage(recordId);
        System.assertEquals(test.size(),query.size(),'need same size');
    }

    @isTest
    static void getCurrentEmailMessagePATest() {
       List<EmailMessage> test = new List<EmailMessage> ();
       Id recordId = [SELECT Id,vlocity_ins__ContactId__r.AccountId FROM vlocity_ins__GroupCensusMember__c LIMIT 1].vlocity_ins__ContactId__r.AccountId;
    
       List<EmailMessage> query = [SELECT Id,Status,FromAddress,ToAddress,Subject,RelatedToId,HtmlBody,CreatedDate,MessageDate  FROM EmailMessage WHERE ARC_CensusMember__r.vlocity_ins__ContactId__r.AccountId= :recordId AND Status = '3' ORDER BY CreatedDate DESC ];
       
       test = ARC_getCurrentEmailMessagePA.getCurrentEmailMessage(recordId);
       System.assertEquals(test.size(),query.size(),'need same size');
   }
}