@isTest
private class ARC_AffiliatedEntitiesControllerTest {

    @testSetup
    static void setupData() {
        Account parentAcc = new Account(
            Name = 'Parent Holding Company'
        );
        insert parentAcc;

        List<Account> childAccounts = new List<Account>();
        
        Account child1 = new Account(
            Name = 'Affiliated Entity A',
            ParentId = parentAcc.Id,
            ARC_FederalEmployerTaxIDNumber__c = '12-3456789',
            ARC_Number_Of_Employees__c = 100
        );
        childAccounts.add(child1);

        Account child2 = new Account(
            Name = 'Affiliated Entity B',
            ParentId = parentAcc.Id,
            ARC_FederalEmployerTaxIDNumber__c = '98-7654321',
            ARC_Number_Of_Employees__c = 50
        );
        childAccounts.add(child2);
        
        insert childAccounts;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = parentAcc.Id
        );
        insert opp;
    }

    @isTest
    static void testGetAffiliatedEntities_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = ARC_AffiliatedEntitiesController.getAffiliatedEntities(opp.Id);
        Test.stopTest();

        List<Account> results = (List<Account>) result.get('entities');
        System.assertNotEquals(null, results, 'The list should not be null');
        System.assertEquals(2, results.size(), 'Should retrieve 2 affiliated entities');
        System.assertEquals('Affiliated Entity A', results[0].Name, 'Sorting should be by Name ASC');
        System.assertEquals(false, (Boolean) result.get('sectionComplete'), 'sectionComplete should be false');
    }

    @isTest
    static void testGetAffiliatedEntities_NoAccountOnOpp() {
        Opportunity orphanOpp = new Opportunity(
            Name = 'Orphan Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert orphanOpp;

        Test.startTest();
        Map<String, Object> result = ARC_AffiliatedEntitiesController.getAffiliatedEntities(orphanOpp.Id);
        Test.stopTest();

        List<Account> results = (List<Account>) result.get('entities');
        System.assertNotEquals(null, results, 'The list should not be null even if empty');
        System.assertEquals(0, results.size(), 'The list should be empty');
        System.assertEquals(false, (Boolean) result.get('sectionComplete'));
    }

    @isTest
    static void testGetAffiliatedEntities_NoChildren() {
        // Create lonely account and its opportunity
        Account lonelyAcc = new Account(Name = 'Lonely Account');
        insert lonelyAcc;

        Opportunity opp = new Opportunity(
            Name = 'Lonely Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = lonelyAcc.Id
        );
        insert opp;

        Test.startTest();
        Map<String, Object> result = ARC_AffiliatedEntitiesController.getAffiliatedEntities(opp.Id);
        Test.stopTest();

        List<Account> results = (List<Account>) result.get('entities');
        System.assertEquals(0, results.size(), 'There should be no affiliated entities');
    }

    @isTest
    static void testGetAffiliatedEntities_NullOpportunityId() {
        Test.startTest();
        Map<String, Object> result = ARC_AffiliatedEntitiesController.getAffiliatedEntities(null);
        Test.stopTest();

        List<Account> results = (List<Account>) result.get('entities');
        System.assertEquals(0, results.size(), 'Null Id should return empty list');
        System.assertEquals(false, (Boolean) result.get('sectionComplete'));
    }

    // @isTest
    // static void testGetAffiliatedEntities_Exception() {
    //     Id fakeOppId = Opportunity.sObjectType.getDescribe().getKeyPrefix() + '000000000001'; 

    //     Test.startTest();
    //     try {
    //         ARC_AffiliatedEntitiesController.getAffiliatedEntities(fakeOppId);
    //         System.assert(false, 'Should have thrown an exception');
    //     } catch (Exception e) {
    //         System.assert(e instanceof AuraHandledException, 'Exception must be AuraHandledException');
    //         System.debug('Error message received: ' + e.getMessage());
    //     }
    //     Test.stopTest();
    // }
}