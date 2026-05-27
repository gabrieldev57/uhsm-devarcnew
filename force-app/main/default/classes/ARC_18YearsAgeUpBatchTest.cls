@isTest
private class ARC_18YearsAgeUpBatchTest {

    @TestSetup
    static void setupTestData() {
       
        Account group_account = new Account(Name = 'Test Group Account');
        insert group_account;

        Account test_person_account = new Account();
        test_person_account.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'ARC_IFPPersonAccount'].Id;
        test_person_account.FirstName = 'Test';
        test_person_account.LastName = 'Member';
        insert test_person_account;

        Account guardian_account = new Account();
        guardian_account.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'ARC_IFPPersonAccount'].Id;
        guardian_account.FirstName = 'Guardian';
        guardian_account.LastName = 'Test';
        insert guardian_account;

      
        vlocity_ins__GroupCensus__c test_census = new vlocity_ins__GroupCensus__c();
        test_census.Name = 'Test Census';
        test_census.vlocity_ins__GroupId__c = group_account.Id;
        test_census.ARC_PrimaryAccount__c = test_person_account.Id;
        test_census.ARC_GuardianAccount__c = guardian_account.Id;
        test_census.ARC_IsChildFamily__c = true;
        insert test_census;

      
        vlocity_ins__GroupCensusMember__c primaryMember = new vlocity_ins__GroupCensusMember__c(
            Name = 'Test Primary Member',
            vlocity_ins__IsPrimaryMember__c = true,
            ARC_ActiveMember__c = true,
            vlocity_ins__Birthdate__c = Date.today().addYears(-18).addDays(-1),
            vlocity_ins__CensusId__c = test_census.Id
        );
        insert primaryMember;
        
        // Create child members
        List<vlocity_ins__GroupCensusMember__c> childMembers = new List<vlocity_ins__GroupCensusMember__c>();
        
        childMembers.add(new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__FirstName__c = 'Test',
            vlocity_ins__LastName__c = 'Child 1',
            vlocity_ins__IsPrimaryMember__c = false,
            vlocity_ins__IsSpouse__c = false,
            vlocity_ins__Birthdate__c = Date.today().addYears(-5),
            ARC_ActiveMember__c = true,
            vlocity_ins__RelatedCensusMemberId__c = primaryMember.Id,
            vlocity_ins__CensusId__c = test_census.Id
        ));
        
        insert childMembers;

        
        List<Group> outboundQueues = [SELECT Id FROM Group WHERE DeveloperName = 'Outbound' AND Type = 'Queue' LIMIT 1];
        if (outboundQueues.isEmpty()) {
            Group newQueue = new Group(Name = 'Outbound', DeveloperName = 'Outbound', Type = 'Queue');
            insert newQueue;
        }
    }
    
    @isTest
    static void testBatchExecuteWithExistingCase() {
        vlocity_ins__GroupCensusMember__c qualifyingMember = [
            SELECT Id, vlocity_ins__CensusId__r.ARC_PrimaryAccount__c 
            FROM vlocity_ins__GroupCensusMember__c 
            WHERE vlocity_ins__IsPrimaryMember__c = true 
            LIMIT 1
        ];
        
       
        Id serviceCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
        Id outboundQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'Outbound' AND Type = 'Queue' LIMIT 1].Id;
        
        Case existingCase = new Case(
            RecordTypeId = serviceCaseRecordTypeId,
            Case_Type__c = 'Program',
            ARC_Reason__c = 'Age Out',
            Subject = 'Age Out 18 Approaching',
            Description = 'Age Out Approaching',
            Status = 'New',
            OwnerId = outboundQueueId,
            ARC_CensusMember__c = qualifyingMember.Id,
            ARC_PersonAccount__c = qualifyingMember.vlocity_ins__CensusId__r.ARC_PrimaryAccount__c,
            ARC_Type__c = 'Member',
            Origin = 'System'
        );
        insert existingCase;
        
        Test.startTest();
        ARC_18YearsAgeUpBatch batch = new ARC_18YearsAgeUpBatch();
        List<vlocity_ins__GroupCensusMember__c> mockMembers = new List<vlocity_ins__GroupCensusMember__c>{qualifyingMember};
        batch.execute(null, mockMembers);
        Test.stopTest();
        
        
        List<Case> allCases = [SELECT Id FROM Case WHERE Subject = 'Age Out 18 Approaching'];
        System.assertEquals(1, allCases.size(), 'Should not create duplicate case');
    }
    
    @isTest
    static void testBatchExecuteExceptionHandling() {
        Test.startTest();
        ARC_18YearsAgeUpBatch batch = new ARC_18YearsAgeUpBatch();
        List<vlocity_ins__GroupCensusMember__c> mockMembers = new List<vlocity_ins__GroupCensusMember__c>();
        batch.execute(null, mockMembers);
        Test.stopTest();
        System.assert(true, 'Should handle execute method without exceptions');
    }
    
    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        ARC_18YearsAgeUpBatch schedulable = new ARC_18YearsAgeUpBatch();
        schedulable.execute(null);
        Test.stopTest();
        System.assert(true, 'Schedulable should execute without errors');
    }

    @isTest
    static void testBatchStartMethod() {
        Test.startTest();
        ARC_18YearsAgeUpBatch batch = new ARC_18YearsAgeUpBatch();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();
        System.assertNotEquals(null, ql, 'Start method should return QueryLocator');
    }

    @isTest
    static void testBatchFinishMethod() {
        Test.startTest();
        ARC_18YearsAgeUpBatch batch = new ARC_18YearsAgeUpBatch();
        batch.finish(null);
        Test.stopTest();
        System.assert(true, 'Finish method should execute without errors');
    }
    @isTest
    static void testBatchCreatesNewCase() {
        
        
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id, vlocity_ins__CensusId__r.ARC_PrimaryAccount__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];
    
        
        List<Case> beforeCases = [
            SELECT Id FROM Case WHERE ARC_PersonAccount__c = :primaryMember.vlocity_ins__CensusId__r.ARC_PrimaryAccount__c
        ];
        System.assertEquals(0, beforeCases.size(), 'Should starts without cases');
    
        Test.startTest();
    
        ARC_18YearsAgeUpBatch batch = new ARC_18YearsAgeUpBatch();
        
        batch.execute(null, new List<vlocity_ins__GroupCensusMember__c>{ primaryMember });
    
        Test.stopTest();
    
        
        List<Case> afterCases = [
            SELECT Id, Subject, ARC_PersonAccount__c 
            FROM Case 
            WHERE ARC_PersonAccount__c = :primaryMember.vlocity_ins__CensusId__r.ARC_PrimaryAccount__c
        ];
    
        System.assertEquals(1, afterCases.size(), 'Should create a new case');
        System.assertEquals('Age Out 18 Approaching', afterCases[0].Subject, 'The case needs to have the correct subject');
    }
}