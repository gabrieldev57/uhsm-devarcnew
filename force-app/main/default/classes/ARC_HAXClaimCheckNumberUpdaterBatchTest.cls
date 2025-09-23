@isTest
private class ARC_HAXClaimCheckNumberUpdaterBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Create test user similar to the Neil mentioned in the original query
        User testUser = new User(
            FirstName = 'Neil',
            LastName = 'TestUser',
            Username = 'neil.testuser@testorg.com',
            Email = 'neil.testuser@testorg.com',
            Alias = 'ntest',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Create test claims with duplicate check numbers
        List<Claim> testClaims = new List<Claim>();
        
        // Scenario 1: Duplicate check numbers
        testClaims.add(new Claim(
            Name = 'Test Claim 1',
            HaxSMB__c = true,
            CreatedById = testUser.Id,
            ARC_CheckNumber__c = 'CHK-001'
        ));
        testClaims.add(new Claim(
            Name = 'Test Claim 2',
            HaxSMB__c = true,
            CreatedById = testUser.Id,
            ARC_CheckNumber__c = 'CHK-001'
        ));
        
        // Scenario 2: Multiple duplicate check numbers
        testClaims.add(new Claim(
            Name = 'Test Claim 3',
            HaxSMB__c = true,
            CreatedById = testUser.Id,
            ARC_CheckNumber__c = 'CHK-002'
        ));
        testClaims.add(new Claim(
            Name = 'Test Claim 4',
            HaxSMB__c = true,
            CreatedById = testUser.Id,
            ARC_CheckNumber__c = 'CHK-002'
        ));
        testClaims.add(new Claim(
            Name = 'Test Claim 5',
            HaxSMB__c = true,
            CreatedById = testUser.Id,
            ARC_CheckNumber__c = 'CHK-002'
        ));
        
        // Scenario 3: No duplicate (to test no-change scenario)
        testClaims.add(new Claim(
            Name = 'Test Claim 6',
            HaxSMB__c = true,
            CreatedById = testUser.Id,
            ARC_CheckNumber__c = 'CHK-003'
        ));

        insert testClaims;
    }
    
    @isTest
    static void testBatchUpdatesCheckNumbers() {

        Test.startTest();
        List<AggregateResult> aggregated_results = [SELECT ARC_CheckNumber__c, COUNT(Id) 
        FROM Claim WHERE HaxSMB__c = true AND ARC_CheckNumber__c != null AND CreatedBy.Name LIKE '%Neil%'
        GROUP BY ARC_CheckNumber__c 
        HAVING COUNT(Id) > 2];

        Database.executeBatch(new ARC_HAXClaimCheckNumberUpdaterBatch(aggregated_results));
        Test.stopTest();
        
        // Retrieve updated claims
        List<Claim> updatedClaims = [
            SELECT Id, ARC_CheckNumber__c 
            FROM Claim 
            WHERE HaxSMB__c = true 
            AND CreatedBy.Name LIKE '%Neil%' 
            ORDER BY ARC_CheckNumber__c
        ];
    }
}