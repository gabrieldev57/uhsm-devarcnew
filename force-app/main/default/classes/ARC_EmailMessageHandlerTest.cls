@isTest
public without sharing class ARC_EmailMessageHandlerTest {

    @TestSetup
    static void makeData(){
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Integer counter = 0;
        for(Integer i=0; i<2;i++){
            Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount'+i, LastName ='Test');
            acc.BillingStreet = '123 Avenue';
            acc.BillingState = 'NY';
            acc.BillingCity = 'New York';
            acc.BillingPostalCode='12345';
            acc.PersonEmail='test@email.com'+counter;
            if(i==0)acc.ARC_IsPrimaryMember__c = true;
            else acc.ARC_IsPrimaryMember__c = false;
            acc.ARC_E123MemberIdFromPolicy__c = 'W123456789'+counter;
            acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
            accList.add(acc);
        }
        insert accList;

        List <vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(2);
        counter = 0;
        List<Account> accountContacts = [SELECT PersonContactId FROM Account WHERE FirstName Like 'PersonAccount%'];
        for(vlocity_ins__GroupCensusMember__c censusMember: censusMemberList){
            censusMember.vlocity_ins__ContactId__c = accountContacts[counter].PersonContactId;
            censusMember.vlocity_ins__SocialSecurityNumber__c = '123456789';
            counter++;
        }
        update censusMemberList;

        List<vlocity_ins__GroupCensusMember__c> censusData =[SELECT Id, vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c];
        accList[0].Census_Member__c = censusData[0].Id;
        accList[1].Census_Member__c = censusData[1].Id;
        accList[0].ARC_CensusMember__pc = censusData[0].Id;
        accList[1].ARC_CensusMember__pc = censusData[1].Id;
        accList[0].ARC_Census__c = censusData[0].vlocity_ins__CensusId__c;
        accList[1].ARC_Census__c = censusData[1].vlocity_ins__CensusId__c;
        accList[1].ARC_PrimaryMemberAccount__c = accList[0].Id;

        update accList;

        List<Contract> cont = ARC_TestUtility.createContractsAA(1);
        cont[0].Name = 'WeShare test ';
        cont[0].vlocity_ins__EnrollmentCensusId__c = censusData[0].vlocity_ins__CensusId__c;
        cont[0].AccountId = accList[0].Id;
        insert cont;

        List<Ages_Up__c> ageUps = new List<Ages_Up__c>();
        Ages_Up__c ageUp1 = new Ages_Up__c(ARC_Account__c = accList[0].Id, Contract__c= cont[0].Id);
        Ages_Up__c ageUp2 = new Ages_Up__c(ARC_Account__c = accList[1].Id, Contract__c= cont[0].Id);
        ageUps.add(ageUp1);
        ageUps.add(ageUp2);
        insert ageUps;
    }

    @isTest
    public static void testDependent60Days() {
        List<Ages_Up__c> ageUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE ARC_Account__r.ARC_PrimaryMemberAccount__c != null];
        EmailMessage em = new EmailMessage(Subject = 'Notice of upcoming change to your WeShare monthly sharing amount', ARC_PersonAccount__c =  ageUp[0].ARC_Account__r.ARC_PrimaryMemberAccount__c, TextBody = 'Test');
        
        Test.startTest();
            insert em;
        Test.stopTest();
        List<Ages_Up__c> afterAgeUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE Id =: ageUp[0].Id];
        System.debug(afterAgeUp);
        Assert.areEqual(Date.Today(),afterAgeUp[0].ARC_FirstNotification__c);
    }

    @isTest
    public static void testDependent30Days() {
        List<Ages_Up__c> ageUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE ARC_Account__r.ARC_PrimaryMemberAccount__c != null];
        EmailMessage em = new EmailMessage(Subject = 'Reminder of upcoming change to your WeShare monthly sharing amount', ARC_PersonAccount__c =  ageUp[0].ARC_Account__r.ARC_PrimaryMemberAccount__c, TextBody = 'Test');
        
        Test.startTest();
            insert em;
        Test.stopTest();
        List<Ages_Up__c> afterAgeUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE Id =: ageUp[0].Id];
        System.debug(afterAgeUp);
        Assert.areEqual(Date.Today(),afterAgeUp[0].ARC_SecondNotification__c);
    }

    @isTest
    public static void testDependent14Days() {
        List<Ages_Up__c> ageUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE ARC_Account__r.ARC_PrimaryMemberAccount__c != null];
        EmailMessage em = new EmailMessage(Subject = 'Reminder of upcoming change to your WeShare monthly sharing amount', ARC_PersonAccount__c =  ageUp[0].ARC_Account__r.ARC_PrimaryMemberAccount__c, TextBody = 'final');
        
        Test.startTest();
            insert em;
        Test.stopTest();
        List<Ages_Up__c> afterAgeUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE Id =: ageUp[0].Id];
        System.debug(afterAgeUp);
        Assert.areEqual(Date.Today(),afterAgeUp[0].ARC_FinalNotification__c);
    }

    @isTest
    public static void testDependentNone() {
        List<Ages_Up__c> ageUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE ARC_Account__r.ARC_PrimaryMemberAccount__c != null];
        EmailMessage em = new EmailMessage(Subject = 'Test', ARC_PersonAccount__c =  ageUp[0].ARC_Account__r.ARC_PrimaryMemberAccount__c, TextBody = 'final');
        
        Test.startTest();
            insert em;
        Test.stopTest();
        List<Ages_Up__c> afterAgeUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE Id =: ageUp[0].Id];
        System.debug(afterAgeUp);
        Assert.areEqual(null,afterAgeUp[0].ARC_FinalNotification__c);

    }
    @isTest
    public static void testPrimary60Days() {
        List<Ages_Up__c> ageUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE ARC_Account__r.ARC_PrimaryMemberAccount__c = null];
        EmailMessage em = new EmailMessage(Subject = 'Notice of upcoming change to your WeShare monthly sharing amount', ARC_PersonAccount__c =  ageUp[0].ARC_Account__c, TextBody = 'Test');
        
        Test.startTest();
            insert em;
        Test.stopTest();
        List<Ages_Up__c> afterAgeUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE Id =: ageUp[0].Id];
        System.debug(afterAgeUp);
        Assert.areEqual(Date.Today(),afterAgeUp[0].ARC_FirstNotification__c);
    }

    @isTest
    public static void testPrimary30Days() {
        List<Ages_Up__c> ageUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE ARC_Account__r.ARC_PrimaryMemberAccount__c = null];
        EmailMessage em = new EmailMessage(Subject = 'Reminder of upcoming change to your WeShare monthly sharing amount', ARC_PersonAccount__c =  ageUp[0].ARC_Account__c, TextBody = 'Test');
        
        Test.startTest();
            insert em;
        Test.stopTest();
        List<Ages_Up__c> afterAgeUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE Id =: ageUp[0].Id];
        System.debug(afterAgeUp);
        Assert.areEqual(Date.Today(),afterAgeUp[0].ARC_SecondNotification__c);
    }

    @isTest
    public static void testPrimary14Days() {
        List<Ages_Up__c> ageUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE ARC_Account__r.ARC_PrimaryMemberAccount__c = null];
        EmailMessage em = new EmailMessage(Subject = 'Reminder of upcoming change to your WeShare monthly sharing amount', ARC_PersonAccount__c =  ageUp[0].ARC_Account__c, TextBody = 'final');
        
        Test.startTest();
            insert em;
        Test.stopTest();
        List<Ages_Up__c> afterAgeUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE Id =: ageUp[0].Id];
        System.debug(afterAgeUp);
        Assert.areEqual(Date.Today(),afterAgeUp[0].ARC_FinalNotification__c);
    }

    @isTest
    public static void testPrimaryNone() {
        List<Ages_Up__c> ageUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE ARC_Account__r.ARC_PrimaryMemberAccount__c = null];
        EmailMessage em = new EmailMessage(Subject = 'Test', ARC_PersonAccount__c =  ageUp[0].ARC_Account__r.ARC_PrimaryMemberAccount__c, TextBody = 'final');
        
        Test.startTest();
            insert em;
        Test.stopTest();
        List<Ages_Up__c> afterAgeUp = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE Id =: ageUp[0].Id];
        System.debug(afterAgeUp);
        Assert.areEqual(null,afterAgeUp[0].ARC_FinalNotification__c);
    }



}