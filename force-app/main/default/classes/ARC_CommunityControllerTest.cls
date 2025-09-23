@isTest
private class ARC_CommunityControllerTest {

    @TestSetup
    static void makeData(){
        
    }

    @isTest
    public static void getCommunityURLTest() {
        Test.startTest();
        Assert.areEqual([SELECT Domain FROM Domain WHERE HttpsOption ='CommunityAlt' LIMIT 1].Domain, ARC_CommunityController.getCommunityURL());
        Test.stopTest();
    }

    @isTest
    public static void loginUserTest() {
        List<User> users = ARC_TestUtility.createTestUsers(1, 'Member Community');
        Test.startTest();
        String response = ARC_CommunityController.loginUser(users[0].Username , 'testPassword1234');
        Test.stopTest();
    }

    @isTest
    public static void loginWithPortalUsernameTest() {
        List<User> users = ARC_TestUtility.createTestUsers(1, 'Standard User');
        users[0].ARC_PortalUsername__c = 'test@uhsm.com';
        insert users;
        Test.startTest();
        Map<String,Object> response = ARC_CommunityController.loginWithPortalUsername(users[0].ARC_PortalUsername__c, 'testPassword1234');
        Test.stopTest();
    }


    @IsTest
    public static void forgotUserNameEmailTest(){
        Account a = new Account(Name='Test Account Name');
        insert a;

        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'Contact';
        testContact.AccountId = a.Id;
        insert testContact;

        List<User> users = ARC_TestUtility.createTestUsers(1, 'Member Community');
        users[0].ContactId = testContact.Id;
        insert users;

        Test.startTest();
        Map<String,Object> response = ARC_CommunityController.forgotUserNameEmail(users[0].Email);
        Assert.areEqual(true, (Boolean)response.get('success'));
        Test.stopTest();
    }

    @IsTest
    public static void forgotPasswordEmailTest(){

        Account a = new Account(Name='Test Account Name');
        insert a;

        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'Contact';
        testContact.AccountId = a.Id;
        insert testContact;

        List<User> users = ARC_TestUtility.createTestUsers(1, 'Member Community');
        users[0].ARC_PortalUsername__c = 'test@uhsm.com';
        users[0].ContactId = testContact.Id;
        insert users;

        Test.startTest();
        Map<String,Object> response = ARC_CommunityController.forgotPasswordEmail(users[0].ARC_PortalUsername__c);
        Assert.areEqual(true, (Boolean)response.get('success'));
        Test.stopTest();
    }
    
    @IsTest
    public static void resetPasswordControllerTest(){
        Account a = new Account(Name='Test Account Name');
        insert a;

        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'Contact';
        testContact.AccountId = a.Id;
        insert testContact;

        List<User> users = ARC_TestUtility.createTestUsers(1, 'Member Community');
        users[0].ContactId = testContact.Id;
        insert users;


        Map<String, Object> formValues = new Map<String, Object>{
            'userId' => users[0].Id,
            'password' => 'NewPassword1234'
        };

        Test.startTest();
        Map<String,Object> response = ARC_CommunityController.resetPasswordController(formValues);
        Test.stopTest();
    }
        
    @IsTest
    public static void setUsernameAndPasswordControllerTest(){

        Account a = new Account(Name='Test Account Name');
        insert a;

        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'Contact';
        testContact.AccountId = a.Id;
        insert testContact;

        List<User> users = ARC_TestUtility.createTestUsers(1, 'Member Community');
        users[0].ContactId = testContact.Id;
        insert users;
        
        Map<String, Object> formValues = new Map<String, Object>{
            'userId' => users[0].Id,
            'username' => users[0].Username,
            'password' => 'TestNewPassword1234'
        };

        Test.startTest();
        System.runAs(users[0]){
            Map<String,Object> response1 = ARC_CommunityController.setUsernameAndPasswordController(formValues);
            Assert.areEqual(true, (Boolean)response1.get('success'));

            formValues.put('username','invalidUsername!$%&$');
            Map<String,Object> response2 = ARC_CommunityController.setUsernameAndPasswordController(formValues);
            Assert.areEqual(false, (Boolean)response2.get('success'));
        }
        Test.stopTest();
    }

            
    @IsTest
    public static void setPortalPasswordTest(){
        List<User> users = ARC_TestUtility.createTestUsers(1, 'Standard User');
        insert users;

        Test.startTest();
        Map<String,Object> response = ARC_CommunityController.setPortalPassword(users[0].Id,'TestNewPassword123456');
        System.debug(response);
        Test.stopTest();
    }

                
    @IsTest
    public static void validateUsernameTest(){
        List<User> users = ARC_TestUtility.createTestUsers(1, 'Standard User');
        users[0].ARC_PortalUsername__c = 'test@uhsm.com';
        insert users;

        Test.startTest();
        Map<String,Object> response1 = ARC_CommunityController.validateUsername(users[0].ARC_PortalUsername__c);
        Map<String,Object> response2 = ARC_CommunityController.validateUsername('TestAvailableUsername943259');
        Test.stopTest();
    }

    @IsTest
    public static void getPortalUserByIdTest(){
        List<User> users = ARC_TestUtility.createTestUsers(1, 'Standard User');
        Test.startTest();
        Map<String,Object> response1 = ARC_CommunityController.getPortalUserById(users[0].Id);
        Map<String,Object> response2 = ARC_CommunityController.getPortalUserById('invalidId');
        Test.stopTest();
    }


    @isTest
    static void testSendReactivationURL() {
        createData();
        Test.startTest();
        ARC_CommunityController.sendReactivationURL('_testinguser1234@example.com');
        Test.stopTest();
        // Check that an email was sent, an expiration link was created, etc.
    }

    @isTest
    static void testReactivateEncryptedUser() {
        createData();
        // Assume encryption and decryption methods
        Id testUserId = [SELECT Id FROM User WHERE ARC_PortalUsername__c = '_testinguser1234@example.com'].Id;
        String encryptedUserId = ARC_EncryptionHelper.encryptText(testUserId);
        Date linkExpirationDate = System.today() + 7; 
        ARC_ExpirationLinksController.createExpirationLinkBulkIds(new List<Id>{testUserId}, linkExpirationDate);
        Test.startTest();
        Map<String,Object> response = ARC_CommunityController.reactivateEncryptedUser(encryptedUserId);
        Test.stopTest();

        // System.assertEquals(true, response.get('success'), 'User reactivation should be successful');
    }


    private static void createData(){
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
            ARC_PortalUsername__c = '_testinguser1234@example.com'
            
        );
        insert testUser;

    }
}