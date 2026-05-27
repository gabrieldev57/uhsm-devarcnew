@IsTest
public class ARC_UserDeactivationServiceTest {

    private static User createTestUser() {
        String uniqueValue = String.valueOf(DateTime.now().getTime());

        User u = new User(
            FirstName = 'Test',
            LastName = 'Deactivate',
            Alias = 'tdeact',
            Email = 'test.deactivate.' + uniqueValue + '@test.com',
            Username = 'test.deactivate.' + uniqueValue + '@test.com',
            CommunityNickname = 'tdeact' + uniqueValue,
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Monterrey',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );

        insert u;
        return u;
    }

    @IsTest
    static void testDeactivateUsers_invocable_deactivatesUser() {
        User testUser = createTestUser();

        ARC_UserDeactivationService.DeactivationRequest req =
            new ARC_UserDeactivationService.DeactivationRequest();

        req.userIds = new List<String>{ testUser.Id };

        Test.startTest();
        ARC_UserDeactivationService.deactivateUsers(
            new List<ARC_UserDeactivationService.DeactivationRequest>{ req }
        );
        Test.stopTest();

        User updatedUser = [
            SELECT Id, IsActive
            FROM User
            WHERE Id = :testUser.Id
        ];

        System.assertEquals(false, updatedUser.IsActive, 'User should be deactivated.');
    }

    @IsTest
    static void testDeactivateUsersAsync_deactivatesUserDirectly() {
        User testUser = createTestUser();

        Test.startTest();
        ARC_UserDeactivationService.deactivateUsersAsync(new Set<Id>{ testUser.Id });
        Test.stopTest();

        User updatedUser = [
            SELECT Id, IsActive
            FROM User
            WHERE Id = :testUser.Id
        ];

        System.assertEquals(false, updatedUser.IsActive, 'Future method should deactivate the user.');
    }

    @IsTest
    static void testDeactivateUsers_handlesNullAndEmptyRequests() {
        Test.startTest();
        ARC_UserDeactivationService.deactivateUsers(null);
        ARC_UserDeactivationService.deactivateUsers(new List<ARC_UserDeactivationService.DeactivationRequest>());
        ARC_UserDeactivationService.deactivateUsersAsync(null);
        ARC_UserDeactivationService.deactivateUsersAsync(new Set<Id>());
        Test.stopTest();

        System.assert(true, 'Null and empty inputs should not throw exceptions.');
    }

    @IsTest
    static void testDeactivateUsers_handlesRequestWithNullUserIds() {
        ARC_UserDeactivationService.DeactivationRequest req =
            new ARC_UserDeactivationService.DeactivationRequest();

        req.userIds = null;

        Test.startTest();
        ARC_UserDeactivationService.deactivateUsers(
            new List<ARC_UserDeactivationService.DeactivationRequest>{ req }
        );
        Test.stopTest();

        System.assert(true, 'Request with null userIds should not throw exceptions.');
    }
}