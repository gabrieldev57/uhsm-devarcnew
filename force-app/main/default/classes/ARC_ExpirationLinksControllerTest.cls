@isTest
public class ARC_ExpirationLinksControllerTest {

    @isTest
    public static void createExpirationLinkBulkTest() {
        List<User> userList = ARC_TestUtility.createTestUsers(1, 'Standard User');
        insert userList;
        Test.startTest();
        ARC_ExpirationLinksController.createExpirationLinkBulk(userList, Date.today()+7);
        Test.stopTest();
    }

    @isTest
    public static void createExpirationLinkBulkIdsTest() {
        Test.startTest();
        List<User> userList = ARC_TestUtility.createTestUsers(1, 'Standard User');
        insert userList;

        List<Id> userIds = new List<Id>();
        for (User u : userList) {
            userIds.add(u.Id);
        }
        ARC_ExpirationLinksController.createExpirationLinkBulkIds(userIds, Date.today()+7);
        Test.stopTest();
    }

    @isTest
    public static void validateLinkTest() {
        Test.startTest();
        List<User> userList = ARC_TestUtility.createTestUsers(1, 'Standard User');
        insert userList;

        ARC_ExpirationLinksController.createExpirationLinkBulk(userList, Date.today()+7);

        Map<String,Object> response1 = ARC_ExpirationLinksController.validateLink(userList[0].Id);
        Assert.areEqual(true, (Boolean)response1.get('success'));

        Map<String,Object> response2 = ARC_ExpirationLinksController.validateLink('001000000000001AAA');
        Assert.areEqual(false, (Boolean)response2.get('success'));
        Test.stopTest();
    }

    @isTest
    public static void closeExpirationLinkTest() {
        Test.startTest();
        List<User> userList = ARC_TestUtility.createTestUsers(1, 'Standard User');
        insert userList;
        ARC_ExpirationLinksController.closeExpirationLink(userList[0].Id);
        Test.stopTest();
    }
}