@isTest
public without sharing class ARC_LeadHandlerTest {

   
    
    @isTest
    public static void testQualifyLead() {
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();

        Lead leadRecord = new Lead(FirstName = 'Test', LastName = 'Lead',Status = 'New', Phone = '1112221110', Email ='testemaillead@test.com');
        insert leadRecord;
        Lead_Source__c leadSourceRecord = new Lead_Source__c(Source_Name__c = 'Self Enroll',Lead_Phone__c='1112221110',Lead_Email__c='testemaillead@test.com',Lead__c = leadRecord.Id);
        insert leadSourceRecord;
        
        inputMap.put('userEmail',leadSourceRecord.Lead_Email__c);
        inputMap.put('userPhone',leadSourceRecord.Lead_Phone__c);

        Test.startTest();
            Boolean objBool = new ARC_LeadHandler().invokeMethod('qualifyLead', inputMap, outputMap, new Map<String,Object>());
            Lead leadAfterUpdate = [SELECT Id, Status FROM Lead LIMIT 1];

            System.assertEquals(true, outputMap.get('success'));
            System.assertEquals('Qualified', leadAfterUpdate.Status);
        Test.stopTest();
    }

    @isTest
    public static void testTwoQualifyLead() {
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();

        Lead leadRecord = new Lead(FirstName = 'Test', LastName = 'Lead',Status = 'New');
        insert leadRecord;
        Lead_Source__c leadSourceRecord = new Lead_Source__c(Source_Name__c = 'Self Enroll',Lead_Phone__c=null,Lead_Email__c='testemaillead@test.com',Lead__c = leadRecord.Id);
        insert leadSourceRecord;
        
        inputMap.put('userEmail',leadSourceRecord.Lead_Email__c);
        inputMap.put('userPhone',leadSourceRecord.Lead_Phone__c);

        Test.startTest();
            Boolean objBool = new ARC_LeadHandler().invokeMethod('qualifyLead', inputMap, outputMap, new Map<String,Object>());
            System.debug(outputMap);

            System.assertEquals(null, outputMap.get('success'));
        Test.stopTest();
    }

    @isTest
    public static void testThree(){
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        inputMap.put('email','test123@test.com');
        inputMap.put('phone','12343543');
        inputMap.put('city','New York');
        inputMap.put('state','NY');
        inputMap.put('firstName','Test');
        inputMap.put('lastName','User');
        inputMap.put('street','123 avenue');
        inputMap.put('zipCode','12345');
        inputMap.put('gender','Male');
        inputMap.put('birthdate',Date.today());
        inputMap.put('cookieId', '1234567890');


        Test.startTest();
            Boolean objBool = new ARC_LeadHandler().invokeMethod('getCreateLeadAndLeadSource', inputMap, outputMap, new Map<String,Object>());
            System.debug(outputMap);

            System.assertEquals(true, outputMap.get('success'));
        Test.stopTest();
    }

    @isTest
    public static void testFour(){
        Lead leadRecord = new Lead(FirstName = 'Test', LastName = 'Lead',Status = 'New', Phone = '1112221110', Email ='testemaillead@test.com');
        insert leadRecord; 
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        inputMap.put('email','testemaillead@test.com');
        inputMap.put('phone','1112221110');
        inputMap.put('city','New York');
        inputMap.put('state','NY');
        inputMap.put('firstName','Test');
        inputMap.put('lastName','User');
        inputMap.put('street','123 avenue');
        inputMap.put('zipCode','12345');
        inputMap.put('gender','Male');
        inputMap.put('birthdate',Date.today());


        Test.startTest();
            Boolean objBool = new ARC_LeadHandler().invokeMethod('getCreateLeadAndLeadSource', inputMap, outputMap, new Map<String,Object>());
            System.debug(outputMap);

            System.assertEquals(true, outputMap.get('success'));
            System.assertEquals(leadRecord.Id, outputMap.get('LeadId'));
        Test.stopTest();
    }

    @isTest
    public static void testGetCreateLeadSourceReferral(){
        Lead leadRecord = new Lead(FirstName = 'Test', LastName = 'Lead',Status = 'New', Phone = '1112221110', Email ='testemaillead@test.com');
        insert leadRecord; 
        
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        inputMap.put('email','testemaillead@test.com');
        inputMap.put('phone','1112221110');
        inputMap.put('city','New York');
        inputMap.put('state','NY');
        inputMap.put('firstName','Test');
        inputMap.put('lastName','User');
        inputMap.put('street','123 avenue');
        inputMap.put('zipCode','12345');
        inputMap.put('gender','Male');
        inputMap.put('birthdate',Date.today());
        inputMap.put('leadId', leadRecord.Id);

        Test.startTest();
            Boolean objBool = new ARC_LeadHandler().invokeMethod('getCreateLeadSourceReferral', inputMap, outputMap, new Map<String,Object>());
            System.debug('testGetCreateLeadSourceReferral: ' + outputMap);
        Test.stopTest();

        System.assertEquals(true, outputMap.get('success'));
        Assert.areNotEqual(null, outputMap.get('ReferralLeadSourceId'), 'leadsource id should not be null');
    }

    @isTest
    static void testUpdateLeadStatusUC() {
        Id personAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account acc = new Account(Firstname='Test', Lastname='Lead', RecordTypeId=personAccRTId, BillingStreet='123 Kansas Street', BillingPostalCode='11220', BillingCity='NY', BillingCountry='US',BillingState='KS', vlocity_ins__Email__c = 'testemaillead@test.com');
        insert acc;
        List<Id> leadIds = new List<Id>();
        Lead leadRecord = new Lead(FirstName = 'Test', LastName = 'Lead',Status = 'New', Email = 'testemaillead@test.com', Account__c = acc.Id);
        insert leadRecord;

        leadIds.add(leadRecord.Id);
        Test.startTest();
            ARC_LeadHandler.updateLeadStatusUC(leadIds);        
            Lead updatedLead = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedDate, Account__c, Status FROM Lead WHERE Id = :leadRecord.Id LIMIT 1];
            
            Assert.areEqual(true, updatedLead.IsConverted, 'Lead should be converted');
            Assert.areEqual('Converted', updatedLead.Status, 'Lead status should be Converted');
            Assert.areNotEqual(null, updatedLead.ConvertedAccountId, 'Converted Account Id should not be null');
            Assert.areNotEqual(null, updatedLead.ConvertedContactId, 'Converted Contact Id should not be null');
            Assert.areNotEqual(null, updatedLead.ConvertedDate, 'Converted Date should not be null');
        Test.stopTest();
            
    }

    @isTest
    static void testPopulateAccountOnLead() {
        Id personAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account primaryAccount = new Account(
            Firstname='Test', 
            Lastname='Lead',
            Phone = '+1234567890',
            PersonEmail = 'testaccount@example.com',
            vlocity_ins__Email__c = 'alternate@test.com',
            RecordTypeId=personAccRTId
        );
        insert primaryAccount;

        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Status = 'New',
            Email = 'testaccount@example.com',
            Phone = '+1234567890'
        );
        insert testLead;

        Lead otherLead = new Lead(
            FirstName = 'Other',
            LastName = 'Lead',
            Status = 'New',
            Email = 'otherlead@test.com',
            Phone = '+9876543210'
        );
        insert otherLead;

        Map<String, Object> inputMap = new Map<String, Object>{
            'primaryAccountId' => primaryAccount.Id
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Test.startTest();

            ARC_LeadHandler.populateAccoutnOnLead(inputMap, outputMap, options);

            Lead updatedLead = [SELECT Id, Account__c FROM Lead WHERE Id = :testLead.Id LIMIT 1];

            Assert.areEqual(primaryAccount.Id, updatedLead.Account__c, 'Lead Account should be updated to the primary Account');

            Assert.areEqual(true, outputMap.get('success'), 'The method should indicate success');
        Test.stopTest();

    }
    @isTest
    static void testPopulateAccountOnLead2() {
        Id personAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account primaryAccount = new Account(
            Firstname='Test', 
            Lastname='Lead',
            Phone = '+1234567890',
            PersonEmail = 'testaccount@example.com',
            vlocity_ins__Email__c = 'alternate@test.com',
            RecordTypeId=personAccRTId
        );
        insert primaryAccount;

        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Status = 'New',
            Email = 'testaccount@example.com',
            Phone = '+1234567890'
        );
        insert testLead;

        Lead otherLead = new Lead(
            FirstName = 'Other',
            LastName = 'Lead',
            Status = 'New',
            Email = 'otherlead@test.com',
            Phone = '+1876543210'
        );
        insert otherLead;

        Lead thirdLead = new Lead(
            FirstName = 'Other',
            LastName = 'Lead',
            Status = 'New',
            Email = 'testaccount@example.com',
            Phone = '+1826541111'
        );
        insert thirdLead;
        Map<String, Object> inputMap = new Map<String, Object>{
            'primaryAccountId' => primaryAccount.Id
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Test.startTest();

            ARC_LeadHandler.populateAccoutnOnLead(inputMap, outputMap, options);

            Lead updatedLead = [SELECT Id, Account__c FROM Lead WHERE Id = :testLead.Id LIMIT 1];

            Assert.areEqual(primaryAccount.Id, updatedLead.Account__c, 'Lead Account should be updated to the primary Account');

            Assert.areEqual(true, outputMap.get('success'), 'The method should indicate success');
        Test.stopTest();

    }

    
}