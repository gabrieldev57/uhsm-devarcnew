@isTest
private class AccountShareHandlerTest {

    @isTest
    static void createShareTest() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test', 
            LastName = 'User', 
            Email = 'test@test.com', 
            Username = 'test' + System.currentTimeMillis() + '@test.com', 
            Alias = 'Test', 
            TimeZoneSidKey = 'America/Los_Angeles', 
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8', 
            ProfileId = p.Id
        ); 

        insert u; 

        Account a = new Account(
            Name = 'Test Account'
        );
        insert a;

        AccountShareHandler.ShareInput shareInput = new AccountShareHandler.ShareInput();
        shareInput.accountId = a.Id;
        shareInput.userId = u.Id;
        shareInput.accessLevel = 'Read';

        Test.startTest(); 
        List<AccountShareHandler.ShareResult> shareResults = AccountShareHandler.createShares(new List<AccountShareHandler.ShareInput>{shareInput}); 
        Test.stopTest(); 

        System.assertEquals(1, shareResults.size(), 'Expected 1 share result'); 
        System.assertEquals(null, shareResults[0].errorMessage, 'Expected success'); 

        List<AccountShare> shares = [SELECT Id FROM AccountShare WHERE AccountId = :a.Id AND UserOrGroupId = :u.Id];

        System.assertEquals(1, shares.size(), 'Expected 1 share'); 

        Integer shareCount = [SELECT COUNT() FROM AccountShare WHERE AccountId = :a.Id AND UserOrGroupId = :u.Id];
        System.assertEquals(1, shareCount, 'Still expecting only 1 share');
    }

    @isTest
    static void createShareDuplicateTest() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test', 
            LastName = 'User', 
            Email = 'test@test.com', 
            Username = 'test' + System.currentTimeMillis() + '@test.com', 
            Alias = 'Test', 
            TimeZoneSidKey = 'America/Los_Angeles', 
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8', 
            ProfileId = p.Id
        ); 

        insert u; 

        Account a = new Account(
            Name = 'Test Account'
        );
        insert a;

        AccountShareHandler.ShareInput shareInput = new AccountShareHandler.ShareInput();
        shareInput.accountId = a.Id;
        shareInput.userId = u.Id;
        shareInput.accessLevel = 'Read';

        Test.startTest(); 
        List<AccountShareHandler.ShareResult> shareResults = AccountShareHandler.createShares(new List<AccountShareHandler.ShareInput>{shareInput}); 
        List<AccountShareHandler.ShareResult> shareResults2 = AccountShareHandler.createShares(new List<AccountShareHandler.ShareInput>{shareInput}); 
        Test.stopTest(); 

        System.assertEquals(1, shareResults.size(), 'Expected 1 share result'); 
        System.assertEquals(null, shareResults[0].errorMessage, 'Expected success'); 

        List<AccountShare> shares = [SELECT Id FROM AccountShare WHERE AccountId = :a.Id AND UserOrGroupId = :u.Id];

        System.assertEquals(1, shares.size(), 'Expected 1 share'); 

        System.assertEquals(1, shareResults2.size(), 'Expected 1 share result'); 

        Integer shareCount = [SELECT COUNT() FROM AccountShare WHERE AccountId = :a.Id AND UserOrGroupId = :u.Id];
        System.assertEquals(1, shareCount, 'Still expecting only 1 share');
    }
}