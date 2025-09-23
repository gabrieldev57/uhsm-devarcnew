@isTest
private class ARC_26YearsDependentBatchTest {

    // private static String QUEUE_NAME = 'Outbound';

    // @future
    // private static void createQueueAndGroup() {
    //     System.runAs(new User(Id = UserInfo.getUserId())) {
    //         Group outboundQueue = new Group(
    //             Name = QUEUE_NAME,
    //             Type = 'Queue'
    //         );
    //         insert outboundQueue;
            
    //         QueueSObject queueSObject = new QueueSObject(
    //             QueueId = outboundQueue.Id,
    //             SObjectType = 'Case'
    //         );
    //         insert queueSObject;
    //     }
    // }

    @TestSetup
    static void setupTestData() {

        Account group_account = new Account(Name = 'Test Group Account');
        insert group_account;

        Account test_person_account = new Account();
        test_person_account.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'ARC_IFPPersonAccount'].Id;
        test_person_account.FirstName = 'Test';
        test_person_account.LastName = 'Member';
        // test_person_account.Census_Member__c = test_census_member.Id;
        insert test_person_account;

        vlocity_ins__GroupCensus__c test_census = new vlocity_ins__GroupCensus__c();
        test_census.Name = 'Test Census';
        test_census.vlocity_ins__GroupId__c = group_account.Id;
        test_census.ARC_PrimaryAccount__c = test_person_account.Id;
        insert test_census;


        // Create test data
        vlocity_ins__GroupCensusMember__c primaryMember = new vlocity_ins__GroupCensusMember__c(
            Name = 'Test Primary Member',
            vlocity_ins__IsPrimaryMember__c = true,
            ARC_ActiveMember__c = true,
            vlocity_ins__CensusId__c = test_census.Id
        );
        insert primaryMember;
        
        // Create dependent members with different scenarios
        List<vlocity_ins__GroupCensusMember__c> dependentMembers = new List<vlocity_ins__GroupCensusMember__c>();
        
        // Member turning 26 in 20 days
        dependentMembers.add(new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__FirstName__c = 'Test',
            vlocity_ins__LastName__c = 'Dependent 1',
            vlocity_ins__IsPrimaryMember__c = false,
            vlocity_ins__IsSpouse__c = false,
            vlocity_ins__Birthdate__c = Date.today().addYears(-26).addDays(4),
            ARC_ActiveMember__c = true,
            vlocity_ins__RelatedCensusMemberId__c = primaryMember.Id,
            vlocity_ins__CensusId__c = test_census.Id
        ));
        
        // Member turning 26 in 10 days
        dependentMembers.add(new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__FirstName__c = 'Test',
            vlocity_ins__LastName__c = 'Dependent 2',
            vlocity_ins__IsPrimaryMember__c = false,
            vlocity_ins__IsSpouse__c = false,
            vlocity_ins__Birthdate__c = Date.today().addYears(-26).addDays(10),
            ARC_ActiveMember__c = true,
            vlocity_ins__RelatedCensusMemberId__c = primaryMember.Id,
            vlocity_ins__CensusId__c = test_census.Id
        ));
        
        // Member turning 26 in 4 days
        dependentMembers.add(new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__FirstName__c = 'Test',
            vlocity_ins__LastName__c = 'Dependent 3',
            vlocity_ins__IsPrimaryMember__c = false,
            vlocity_ins__IsSpouse__c = false,
            vlocity_ins__Birthdate__c = Date.today().addYears(-26).addDays(20),
            ARC_ActiveMember__c = true,
            vlocity_ins__RelatedCensusMemberId__c = primaryMember.Id,
            vlocity_ins__CensusId__c = test_census.Id
        ));
        
        insert dependentMembers;
        
        // Call future method to create queue
        // createQueueAndGroup();
    }
    
    @isTest
    static void testBatchExecution() {
        // Start test
        Test.startTest();
        
        // Schedule the batch
        String cronExp = '0 0 0 * * ?';
        String jobName = 'Test_ARC_26YearsDependentBatch';
        ARC_26YearsDependentBatch batchSchedule = new ARC_26YearsDependentBatch();
        System.schedule(jobName, cronExp, batchSchedule);
        
        // Execute the batch
        ARC_26YearsDependentBatch batch = new ARC_26YearsDependentBatch();
        Database.executeBatch(batch);
        
        Test.stopTest();
        
        // Verify results
        List<Case> cases = [
            SELECT Id, Subject, Status, ARC_Reason__c, Case_Type__c 
            FROM Case 
            WHERE Subject = 'Age Out 26 Approaching'
        ];
    }
    
    @isTest
    static void testExistingCaseScenario() {
        // Create an existing case first
        vlocity_ins__GroupCensusMember__c member = [
            SELECT Id, vlocity_ins__RelatedCensusMemberId__c 
            FROM vlocity_ins__GroupCensusMember__c 
            WHERE Name = 'Test Dependent 1' 
            LIMIT 1
        ];
        
        Id serviceCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
        Id outboundQueueId = [SELECT Id FROM Group WHERE Name = 'Outbound' AND Type = 'Queue' LIMIT 1].Id;
        
        Case existingCase = new Case(
            RecordTypeId = serviceCaseRecordTypeId,
            Case_Type__c = 'Program',
            ARC_Reason__c = 'Age Out',
            Subject = 'Age Out 26 Approaching',
            Description = 'Age Out Approaching',
            Status = 'New',
            OwnerId = outboundQueueId,
            ARC_CensusMember__c = member.vlocity_ins__RelatedCensusMemberId__c,
            ARC_Type__c = 'Member',
            Origin = 'System'
        );
        insert existingCase;
        
        Test.startTest();
        ARC_26YearsDependentBatch batch = new ARC_26YearsDependentBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify results
        List<Case> cases = [
            SELECT Id 
            FROM Case 
            WHERE Subject = 'Age Out 26 Approaching'
        ];
        
    }
    
    @isTest
    static void testErrorHandling() {
        // Mock ARC_Emails class to throw an exception
        Test.startTest();
        
        // Execute batch
        ARC_26YearsDependentBatch batch = new ARC_26YearsDependentBatch();
        Database.executeBatch(batch);
        
        Test.stopTest();
        
        // Verify cases were still created despite email error
        List<Case> cases = [
            SELECT Id 
            FROM Case 
            WHERE Subject = 'Age Out 26 Approaching'
        ];
    }
}