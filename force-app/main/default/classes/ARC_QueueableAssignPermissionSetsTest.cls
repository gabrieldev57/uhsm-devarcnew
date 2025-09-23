@isTest
private class ARC_QueueableAssignPermissionSetsTest {

    @isTest
    static void testQueueableExecution() {
        // Create test data
        Account a = new Account(Name='Test Account Name');
        insert a;

        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'Contact';
        testContact.AccountId = a.Id;
        insert testContact;

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testinguser1234@example.com',
            Username = 'testinguser1234@example.com',
            Alias = 'tuser',
            ContactId = testContact.Id,
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Member Community' LIMIT 1].Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ARC_PortalUsername__c = 'testinguser1234@example.com'
            
        );
        insert testUser;

        List<Id> userIds = new List<Id>{testUser.Id};

        List<String> permissionSets = new List<String> {'UHSM IFP FlowPermissions Member','Permission Set for Payment Request (Base)','Permission Set for Payment Request (Chargent Orders)'};
        List<PermissionSet> pSetList = [SELECT Id FROM PermissionSet WHERE Label IN: permissionSets ];

        List<Id> permissionSetIds = new List<Id>();
        for (PermissionSet pSet : pSetList) {
            permissionSetIds.add(pSet.Id);
        }

        Test.startTest();
        // Enqueue the Queueable job
            System.enqueueJob(new ARC_QueueableAssignPermissionSets('assignPermissionSetAndLicense',null,userIds, permissionSetIds));
        Test.stopTest();

        // Add assertions or queries to verify the expected behavior after the Queueable job has executed
        // For example, you can query PermissionSetAssignment and UserPackageLicense records and assert their existence
        System.debug([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :testUser.Id]);
        // System.assertEquals(1, [SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :testUser.Id]);
        // Add similar assertions for UserPackageLicense records if applicable
    }

    @isTest
    static void testCheckAndCreateUser() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount', LastName ='Test');
        acc.BillingStreet = '123 Avenue';
        acc.BillingState = 'NY';
        acc.BillingCity = 'New York';
        acc.BillingPostalCode='12345';
        acc.PersonEmail='test@email.com';
        acc.ARC_IsPrimaryMember__c = true;
        acc.ARC_E123MemberIdFromPolicy__c = 'W123456789';
        acc.PersonBirthdate = Date.newInstance(1994,04,01);
        insert acc;

        Account persAcc = [SELECT Id, ARC_Census__c,Census_Member__c,PersonContactId FROM Account WHERE Id =: acc.Id];

        List <vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(1);
        for(vlocity_ins__GroupCensusMember__c censusMember: censusMemberList){
            censusMember.vlocity_ins__ContactId__c = persAcc.PersonContactId;
            censusMember.vlocity_ins__SocialSecurityNumber__c = '123456789';
        }
        update censusMemberList;

        List<vlocity_ins__GroupCensusMember__c> censusData =[SELECT vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c];
        persAcc.Census_Member__c = censusMemberList[0].Id;
        persAcc.ARC_Census__c = censusData[0].vlocity_ins__CensusId__c;
        update persAcc;

        // List<Id> userIds = new List<Id>{testUser.Id};

        // List<String> permissionSets = new List<String> {'UHSM IFP FlowPermissions Member','Permission Set for Payment Request (Base)','Permission Set for Payment Request (Chargent Orders)'};
        // List<PermissionSet> pSetList = [SELECT Id FROM PermissionSet WHERE Label IN: permissionSets ];

        // List<Id> permissionSetIds = new List<Id>();
        // for (PermissionSet pSet : pSetList) {
        //     permissionSetIds.add(pSet.Id);
        // }

        Test.startTest();
            //Call Queueable job to create Portal Users
            ARC_QueueableAssignPermissionSets qJob = new ARC_QueueableAssignPermissionSets('createUsers',new List<Id>{censusMemberList[0].Id},null,null);
            System.enqueueJob(qJob);
        Test.stopTest();

    }
}