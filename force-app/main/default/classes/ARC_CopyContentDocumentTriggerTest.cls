@isTest
global with sharing class ARC_CopyContentDocumentTriggerTest {
    
    @TestSetup
    static void makeData() {
        // Create Person Account
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account personAcc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount', LastName ='Test');
        insert personAcc;

        Account personAccData = [SELECT Id, PersonContactId FROM Account WHERE Id = :personAcc.Id];

        // Create Census Member
        List<vlocity_ins__GroupCensusMember__c> censMemb = ARC_TestUtility.createTestCensusMember(1);
        censMemb[0].vlocity_ins__IsPrimaryMember__c = true;
        censMemb[0].vlocity_ins__ContactId__c = personAccData.PersonContactId;
        update censMemb;

        // Create Cases
        List<Case> testCase = ARC_TestUtility.createTestCase(1, 'Admission');
        List<Case> testCaseTwo = ARC_TestUtility.createTestCase(1, 'Service');

        // Create Contract
        Contract cont = new Contract(
            Name = 'Test Contract', 
            AccountId = personAcc.Id, 
            vlocity_ins__EnrollmentCensusId__c = censMemb[0].vlocity_ins__CensusId__c, 
            ARC_Case__c = testCase[0].Id
        );
        insert cont;

        // Update Cases with Contract
        testCase[0].ARC_Contract__c = cont.Id;
        testCaseTwo[0].ARC_Contract__c = cont.Id;
        testCaseTwo[0].ARC_CensusMember__c = censMemb[0].Id;
        update testCase;
        update testCaseTwo;

        // Create Task
        Task t = new Task(
            Subject = 'Donni', 
            Status = 'New', 
            Priority = 'Normal', 
            CallType = 'Outbound', 
            WhatId = testCaseTwo[0].Id
        );
        insert t;

        // Create ContentVersions
        ContentVersion content = new ContentVersion(); 
        content.Title = 'Header_Picture1'; 
        content.PathOnClient = '/' + content.Title + '.jpg'; 
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData = bodyBlob; 
        content.origin = 'H';
        insert content;

        ContentVersion contentTwo = new ContentVersion(); 
        contentTwo.Title = 'Header_PictureTwo'; 
        contentTwo.PathOnClient = '/' + contentTwo.Title + '.jpg'; 
        Blob bodyBlobTwo = Blob.valueOf('Unit Test ContentVersion Body'); 
        contentTwo.VersionData = bodyBlobTwo; 
        contentTwo.origin = 'H';
        insert contentTwo;
    }

    @isTest    
    static void onBeforeTest() {
        Case caseObj = [SELECT Id FROM Case WHERE ARC_CaseType__c = 'Underwriting' LIMIT 1];
        ContentVersion contDoc = [SELECT Id FROM ContentVersion WHERE Title = 'Header_Picture1' LIMIT 1];
        vlocity_ins__GroupCensusMember__c censusMember = [SELECT Id FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        
        List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = caseObj.Id;
        contentlink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contDoc.Id].ContentDocumentId;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        cdList.add(contentlink);
         
        Test.startTest();
        insert cdList;
        Test.stopTest();
        
        // Assert that the ContentDocumentLink was created correctly
        List<ContentDocumentLink> assertCdList = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :caseObj.Id];
        System.assertEquals(1, assertCdList.size());        
    } 

    @isTest    
    static void onBeforeTestTwo() {
        Contract contObj = [SELECT Id FROM Contract LIMIT 1];
        vlocity_ins__GroupCensusMember__c censusMember = [SELECT Id FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        ContentVersion contDoc = [SELECT Id FROM ContentVersion WHERE Title = 'Header_Picture1' LIMIT 1];
        ContentVersion contDocTwo = [SELECT Id FROM ContentVersion WHERE Title = 'Header_PictureTwo' LIMIT 1];
        
        List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
        ContentDocumentLink contentlink = new ContentDocumentLink();
        ContentDocumentLink contentlinkTwo = new ContentDocumentLink();
        contentlink.LinkedEntityId = contObj.Id;
        contentlinkTwo.LinkedEntityId = contObj.Id;
        contentlink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contDoc.Id].ContentDocumentId;
        contentlinkTwo.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contDocTwo.Id].ContentDocumentId;
        contentlink.ShareType = contentlinkTwo.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';
        cdList.add(contentlink);
        cdList.add(contentlinkTwo);
        
        Test.startTest();
        insert cdList;
        Test.stopTest();

        // Assert that two ContentDocumentLinks were created correctly
        List<ContentDocumentLink> assertCdList = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :contObj.Id];
        System.assertEquals(2, assertCdList.size());
    } 

    @isTest  
    static void onBeforeTestThree() {
        Task taskObj = [SELECT Id FROM Task LIMIT 1];
        ContentVersion contDoc = [SELECT Id FROM ContentVersion WHERE Title = 'Header_Picture1' LIMIT 1];
        vlocity_ins__GroupCensusMember__c censusMember = [SELECT Id FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
         
        List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = taskObj.Id;
        contentlink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contDoc.Id].ContentDocumentId;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        cdList.add(contentlink);
         
        Test.startTest();
        insert cdList;
        Test.stopTest();
        
        // Assert that the ContentDocumentLink was created correctly
        List<ContentDocumentLink> assertCdList = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :taskObj.Id];
        System.assertEquals(1, assertCdList.size());
    } 
}