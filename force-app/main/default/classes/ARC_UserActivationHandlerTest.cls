@isTest
private class ARC_UserActivationHandlerTest {


    @TestSetup
    static void makeData(){
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
    }

    @isTest
    static void testDeactivateUsersNotLoggedIn() {
        // List<User> users = ARC_TestUtility.createTestUsers(1, 'Standard User');
        // users[0].ARC_PortalUsername__c = 'test@uhsm.com';
        // insert users;

        Test.startTest();
        ARC_UserActivationHandler.deactivateUsersNotLoggedIn();
        Test.stopTest();

        List<User> usersToDeactivate = ARC_UserActivationHandler.getUsersToDeactivate();
        System.assertEquals(0, usersToDeactivate.size(), 'Users werent deactivated properly');
    }

    // @isTest
    // static void testSendReactivationURL() {
    //     String testUsername = 'inactiveuser';
    //     Test.startTest();
    //     ARC_UserActivationHandler.sendReactivationURL(testUsername);
    //     Test.stopTest();
    //     // Check that an email was sent, an expiration link was created, etc.
    // }

    // @isTest
    // static void testValidateExpirationLink() {
    //     // Assume there's a way to create a test expiration link
    //     List<ARC_ExpirationLink__c> testLinks = new List<ARC_ExpirationLink__c>{ 
    //         new ARC_ExpirationLink__c(
    //             ARC_UserId__c = 'testUserId',
    //             ARC_ExpirationDate__c = Date.today().addDays(7),
    //             ARC_IsUsed__c = false
    //         ) 
    //     };
    //     insert testLinks;

    //     // Test that the expiration link is valid
    //     Boolean isValid = ARC_UserActivationHandler.validateExpirationLink('testUserId');
    //     System.assertEquals(true, isValid, 'The expiration link should be valid');
    // }

    // @isTest
    // static void testActivateUser() {
    //     List<User> usersToDeactivate = ARC_UserActivationHandler.getUsersToDeactivate();
    //     ARC_UserActivationHandler.deactivateUsers(usersToDeactivate);
    //     Id testUserId = usersToDeactivate[0].Id;

    //     Test.startTest();
    //     ARC_UserActivationHandler.activateUser(testUserId);
    //     Test.stopTest();

    //     User activatedUser = [SELECT Id, IsActive, ARC_PortalUsername__c FROM User WHERE Id = :testUserId];
    //     System.assertEquals(true, activatedUser.IsActive, 'User should be activated');
    //     System.assert(!activatedUser.ARC_PortalUsername__c.startsWith('_'), 'Username should not start with _');
    // }

    // @isTest
    // static void testReactivateEncryptedUser() {
    //     // Assume encryption and decryption methods
    //     Id testUserId = [SELECT Id FROM User LIMIT 1].Id;
    //     String encryptedUserId = ARC_EncryptionHelper.encryptText(testUserId);

    //     Test.startTest();
    //     Map<String,Object> response = ARC_UserActivationHandler.reactivateEncryptedUser(encryptedUserId);
    //     Test.stopTest();

    //     System.assertEquals(true, response.get('success'), 'User reactivation should be successful');
    // }
}