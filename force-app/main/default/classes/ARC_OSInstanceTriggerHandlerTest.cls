@isTest
public class ARC_OSInstanceTriggerHandlerTest {

    @TestSetup
    static void makeData(){

        Lead firstLead = new Lead();
        firstLead.Status = 'New';
        firstLead.LastName = 'Dude';
        insert firstLead;

        Account acc = new Account(Name = 'test');
        insert acc;

        Contract theCont = new Contract(Account_Name_Text__c = 'contTest', AccountId=acc.Id);
        insert theCont;

        Lead_Source__c leadSrcToInsert = new Lead_Source__c();
        leadSrcToInsert.Source_Name__c ='Self Enroll';
        leadSrcToInsert.Lead__c = firstLead.Id ;
        leadSrcToInsert.ARC_Contract__c = theCont.Id;
        insert leadSrcToInsert;
    }

    @isTest
    static void stampSaveForLaterDateOnLeadTest() {
        Contract cont = [SELECT Id, Account_Name_Text__c FROM Contract LIMIT 1];

        vlocity_ins__OmniScriptInstance__c instance = new vlocity_ins__OmniScriptInstance__c();
        instance.vlocity_ins__ObjectId__c = cont.Id ;
        instance.vlocity_ins__ObjectType__c = 'Contract';

        Test.startTest();
        insert instance;
        Test.stopTest();
        Lead leadAfter = [SELECT Id, Status, ARC_SESaveForLater__c FROM Lead WHERE LastName = 'Dude' LIMIT 1];
        Assert.isNotNull(leadAfter.ARC_SESaveForLater__c, 'Saved Date should be populated');
    }
}