@isTest
private class ARC_ContactLookupControllerTest {

    @TestSetup
    static void testSetup() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        List<Contact> testContacts = new List<Contact>();
        testContacts.add(new Contact(AccountId = testAccount.Id, FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com', Phone = '555-0001'));
        testContacts.add(new Contact(AccountId = testAccount.Id, FirstName = 'Jane', LastName = 'Smith', Email = 'jane.smith@example.com', Phone = '555-0002'));
        testContacts.add(new Contact(AccountId = testAccount.Id, FirstName = 'Bob', LastName = 'Johnson', Email = 'bob.johnson@example.com', Phone = '555-0003'));
        insert testContacts;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30)
        );
        insert testOpp;
    }

    /**
     * Test searchContactsByOpportunity without search term
     * Expected: Should return all related contacts
     */
    @isTest
    static void testSearchContactsByOpportunity_NoSearchTerm() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<Contact> result = ARC_ContactLookupController.searchContactsByOpportunity('', testOpp.Id, 10);
        Test.stopTest();

        System.assertEquals(3, result.size());
        System.assertEquals('Johnson', result[0].LastName);
        System.assertNotEquals(null, result[0].Id);
        System.assertNotEquals(null, result[0].Email);
        System.assertNotEquals(null, result[0].Phone);
    }

    /**
     * Test searchContactsByOpportunity with search term
     * Expected: Should return filtered contacts by name or email
     */
    @isTest
    static void testSearchContactsByOpportunity_WithSearchTerm() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<Contact> resultByName = ARC_ContactLookupController.searchContactsByOpportunity('Smith', testOpp.Id, 10);
        List<Contact> resultByEmail = ARC_ContactLookupController.searchContactsByOpportunity('john.doe', testOpp.Id, 10);
        List<Contact> resultNoMatch = ARC_ContactLookupController.searchContactsByOpportunity('NoMatch', testOpp.Id, 10);
        Test.stopTest();

        System.assertEquals(1, resultByName.size());
        System.assertEquals('Smith', resultByName[0].LastName);
        
        System.assertEquals(1, resultByEmail.size());
        System.assertEquals('Doe', resultByEmail[0].LastName);
        
        System.assertEquals(0, resultNoMatch.size());
    }

    /**
     * Test searchContactsByOpportunity with edge cases
     * Expected: Should handle null input, no related contacts, and limit properly
     */
    @isTest
    static void testSearchContactsByOpportunity_EdgeCases() {
        Test.startTest();
        List<Contact> resultNullOpp = ARC_ContactLookupController.searchContactsByOpportunity('', null, 10);
        
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        List<Contact> resultWithLimit = ARC_ContactLookupController.searchContactsByOpportunity('', testOpp.Id, 1);
        
        Test.stopTest();

        System.assertEquals(0, resultNullOpp.size());
        System.assertEquals(1, resultWithLimit.size());

        Account newAccount = new Account(Name = 'Account No Contacts');
        insert newAccount;
        Opportunity oppNoContacts = new Opportunity(
            Name = 'Opp No Contacts',
            AccountId = newAccount.Id,
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30)
        );
        insert oppNoContacts;
        List<Contact> resultNoContacts = ARC_ContactLookupController.searchContactsByOpportunity('', oppNoContacts.Id, 10);
        
        System.assertEquals(0, resultNoContacts.size());
    }
}