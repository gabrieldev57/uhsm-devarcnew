@IsTest
private class ARC_AccountOwnerHelperTest {

    @IsTest
    static void testGetAccountManager_HappyPath() {
        Account acc = new Account(
            Name = 'Test Account Happy Path',
            ARC_AccountManager__c = UserInfo.getUserId()
        );
        insert acc;

        Test.startTest();
        ARC_CompanyDetailsController.AccountManagerData result =
            ARC_AccountOwnerHelper.getAccountManager(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(UserInfo.getName(), result.Name, 'Manager name should match current user');
        System.assertEquals(UserInfo.getUserEmail(), result.Email, 'Manager email should match current user');
    }

    @IsTest
    static void testGetAccountManager_NoManager() {
        Account acc = new Account(
            Name = 'Test Account No Manager'
        );
        insert acc;

        Test.startTest();
        ARC_CompanyDetailsController.AccountManagerData result =
            ARC_AccountOwnerHelper.getAccountManager(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(null, result.Name, 'Name should be null when no manager exists');
        System.assertEquals(null, result.Email, 'Email should be null when no manager exists');
        System.assertEquals(null, result.Phone, 'Phone should be null when no manager exists');
    }

    @IsTest
    static void testGetAccountManager_NullAccountId() {
        Test.startTest();
        ARC_CompanyDetailsController.AccountManagerData result =
            ARC_AccountOwnerHelper.getAccountManager(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(null, result.Name, 'Name should be null for null accountId');
        System.assertEquals(null, result.Email, 'Email should be null for null accountId');
        System.assertEquals(null, result.Phone, 'Phone should be null for null accountId');
    }
}