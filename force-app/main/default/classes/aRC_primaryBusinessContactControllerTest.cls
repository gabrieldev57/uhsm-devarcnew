@isTest
private class aRC_primaryBusinessContactControllerTest {

    @testSetup
    static void setupData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Contact WITH AccountId (important)
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = acc.Id,
            Title = 'Manager',
            Phone = '1234567890',
            Email = 'john.doe@test.com',
            MailingStreet = '123 Main St',
            MailingCity = 'Toronto',
            MailingState = 'ON',
            MailingPostalCode = 'A1A1A1',
            MailingCountry = 'Canada'
        );
        insert con;

        // Update the auto-created AccountContactRelation
        AccountContactRelation acr = [
            SELECT Id, Roles, IsActive
            FROM AccountContactRelation
            WHERE AccountId = :acc.Id
              AND ContactId = :con.Id
            LIMIT 1
        ];

        acr.Roles = 'Primary Business Contact';
        acr.IsActive = true;
        update acr;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;
    }

    @isTest
    static void testNullOpportunityId() {
        Test.startTest();
        aRC_primaryBusinessContactController.PrimaryBusinessContactDTO result =
            aRC_primaryBusinessContactController.getPrimaryBusinessContact(null);
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @isTest
    static void testOpportunityWithoutAccount() {
        Opportunity opp = new Opportunity(
            Name = 'No Account Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5)
        );
        insert opp;

        Test.startTest();
        aRC_primaryBusinessContactController.PrimaryBusinessContactDTO result =
            aRC_primaryBusinessContactController.getPrimaryBusinessContact(opp.Id);
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @isTest
    static void testNoPrimaryBusinessContactFound() {
        Account acc = new Account(Name = 'No Contact Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Opp Without Proper Role',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            AccountId = acc.Id
        );
        insert opp;

        // Create contact + ACR but WITHOUT required role
        Contact con = new Contact(
            LastName = 'Smith',
            AccountId = acc.Id
        );
        insert con;

        Test.startTest();
        aRC_primaryBusinessContactController.PrimaryBusinessContactDTO result =
            aRC_primaryBusinessContactController.getPrimaryBusinessContact(opp.Id);
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @isTest
    static void testPrimaryBusinessContactFound() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        aRC_primaryBusinessContactController.PrimaryBusinessContactDTO result =
            aRC_primaryBusinessContactController.getPrimaryBusinessContact(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('John Doe', result.name);
        System.assertEquals('Manager', result.title);
        System.assertEquals('1234567890', result.phone);
        System.assertEquals('john.doe@test.com', result.email);

        System.assert(result.address.contains('123 Main St'));
        System.assert(result.address.contains('Toronto, ON, A1A1A1'));
        System.assert(result.address.contains('Canada'));
    }

    @isTest
    static void testPartialAddressFormatting() {
        Account acc = new Account(Name = 'Partial Address Account');
        insert acc;

        Contact con = new Contact(
            LastName = 'Partial',
            AccountId = acc.Id,
            MailingCity = 'Vancouver',
            MailingCountry = 'Canada'
        );
        insert con;

        // Update auto-created ACR
        AccountContactRelation acr = [
            SELECT Id, Roles, IsActive
            FROM AccountContactRelation
            WHERE AccountId = :acc.Id
              AND ContactId = :con.Id
            LIMIT 1
        ];
        acr.Roles = 'Primary Business Contact';
        acr.IsActive = true;
        update acr;

        Opportunity opp = new Opportunity(
            Name = 'Partial Address Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;

        Test.startTest();
        aRC_primaryBusinessContactController.PrimaryBusinessContactDTO result =
            aRC_primaryBusinessContactController.getPrimaryBusinessContact(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.address.contains('Vancouver'));
        System.assert(result.address.contains('Canada'));
    }
}