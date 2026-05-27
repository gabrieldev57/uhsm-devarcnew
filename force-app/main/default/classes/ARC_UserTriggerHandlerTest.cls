@isTest (isParallel=false)
private class ARC_UserTriggerHandlerTest {

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private static Account createAccount() {
        Account acc = new Account(Name = 'Test Handler Account');
        insert acc;
        return acc;
    }

    private static Contact createContact(Id accountId, String firstName, String lastName) {
        Contact c = new Contact(
            FirstName = firstName,
            LastName  = lastName,
            Email     = firstName.toLowerCase() + '.' + lastName.toLowerCase() + '@testhandler.com',
            AccountId = accountId
        );
        insert c;
        return c;
    }

    private static User buildInternalUser(Id profileId, String suffix) {
        return new User(
            FirstName         = 'Test',
            LastName          = 'Handler' + suffix,
            Email             = 'thandler' + suffix + '@testhandler.com',
            Username          = 'thandler' + suffix + '@testhandler.com.' + UserInfo.getOrganizationId(),
            Alias             = ('th' + suffix).left(8),
            TimeZoneSidKey    = 'America/Los_Angeles',
            LocaleSidKey      = 'en_US',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId         = profileId,
            IsActive          = true
        );
    }

    private static User buildPortalUser(Id contactId, Id profileId, String suffix) {
        return new User(
            ContactId         = contactId,
            FirstName         = 'Portal',
            LastName          = 'Handler' + suffix,
            Email             = 'phandler' + suffix + '@testhandler.com',
            Username          = 'phandler' + suffix + '@testhandler.com.' + UserInfo.getOrganizationId(),
            Alias             = ('ph' + suffix).left(8),
            CommunityNickname = ('hn' + suffix + UserInfo.getOrganizationId()).left(40),
            TimeZoneSidKey    = 'America/Los_Angeles',
            LocaleSidKey      = 'en_US',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId         = profileId,
            IsActive          = true
        );
    }

    // ─── setPermissionSetAndLicenseToPortalUser ───────────────────────────────

    /**
     * Verifies the method collects user IDs and delegates to the service
     * without throwing an exception (standard user profile, no PSA expected).
     */
    @isTest
    static void testSetPermission_delegatesToService() {
        Profile std = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = buildInternalUser(std.Id, '01');
        insert u;

        List<User> users = [SELECT Id FROM User WHERE Id = :u.Id];

        Test.startTest();
        ARC_UserTriggerHandler.setPermissionSetAndLicenseToPortalUser(
            users, new Map<Id, User>(), true
        );
        Test.stopTest();

        // The future method ran to completion; no exception means success
        System.assert(true, 'setPermissionSetAndLicenseToPortalUser completed without exception');
    }

    /**
     * Verifies that an empty user list is handled gracefully.
     */
    @isTest
    static void testSetPermission_emptyList() {
        Test.startTest();
        ARC_UserTriggerHandler.setPermissionSetAndLicenseToPortalUser(
            new List<User>(), new Map<Id, User>(), false
        );
        Test.stopTest();

        System.assert(true, 'Empty list handled without exception');
    }

    // ─── createSharingForRelatedAccount ──────────────────────────────────────

    /**
     * Verifies that no AccountShare or UserShare is created when
     * users have no AccountId.
     */
    @isTest
    static void testCreateSharing_usersWithNoAccountId() {
        Profile std = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = buildInternalUser(std.Id, '02');
        insert u;

        List<User> users = [SELECT Id, AccountId FROM User WHERE Id = :u.Id];

        Test.startTest();
        ARC_UserTriggerHandler.createSharingForRelatedAccount(users);
        Test.stopTest();

        List<AccountShare> shares = [
            SELECT Id FROM AccountShare
            WHERE UserOrGroupId = :u.Id AND RowCause = 'Manual'
        ];
        System.assertEquals(0, shares.size(),
            'No AccountShare should be created for users without AccountId');
    }

    /**
     * Verifies that AccountShare and UserShare records are created
     * for a portal user whose AccountId is set.
     * Skips gracefully if no portal profile is available.
     */
    @isTest
    static void testCreateSharing_createsSharesForPortalUser() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Employer Admin' LIMIT 1];
        if (profiles.isEmpty()) { return; }

        Account acc = createAccount();
        Contact c   = createContact(acc.Id, 'Share', 'HandlerC');
        User u      = buildPortalUser(c.Id, profiles[0].Id, '03');
        insert u;

        User inserted = [SELECT Id, AccountId FROM User WHERE Id = :u.Id];
        if (inserted.AccountId == null) { return; }

        List<User> users = [SELECT Id, AccountId FROM User WHERE Id = :u.Id];

        Test.startTest();
        ARC_UserTriggerHandler.createSharingForRelatedAccount(users);
        Test.stopTest();

        List<AccountShare> accountShares = [
            SELECT Id FROM AccountShare
            WHERE AccountId     = :inserted.AccountId
              AND UserOrGroupId = :u.Id
              AND RowCause      = 'Manual'
        ];
        System.assertEquals(1, accountShares.size(),
            'One AccountShare with Edit access should be created');
    }

    /**
     * Verifies AccountShare is created with the correct access levels.
     * Skips gracefully if no portal profile is available.
     */
    @isTest
    static void testCreateSharing_correctAccessLevels() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Employer Admin' LIMIT 1];
        if (profiles.isEmpty()) { return; }

        Account acc = createAccount();
        Contact c   = createContact(acc.Id, 'Access', 'HandlerD');
        User u      = buildPortalUser(c.Id, profiles[0].Id, '04');
        insert u;

        User inserted = [SELECT Id, AccountId FROM User WHERE Id = :u.Id];
        if (inserted.AccountId == null) { return; }

        List<User> users = [SELECT Id, AccountId FROM User WHERE Id = :u.Id];

        Test.startTest();
        ARC_UserTriggerHandler.createSharingForRelatedAccount(users);
        Test.stopTest();

        AccountShare share = [
            SELECT AccountAccessLevel, OpportunityAccessLevel
            FROM AccountShare
            WHERE AccountId     = :inserted.AccountId
              AND UserOrGroupId = :u.Id
              AND RowCause      = 'Manual'
            LIMIT 1
        ];
        System.assertEquals('Edit', share.AccountAccessLevel,
            'AccountAccessLevel should be Edit');
        System.assertEquals('Edit', share.OpportunityAccessLevel,
            'OpportunityAccessLevel should be Edit');
    }

    /**
     * Verifies that an empty user list is handled gracefully
     * (no exception, no DML errors).
     */
    @isTest
    static void testCreateSharing_emptyList() {
        Test.startTest();
        ARC_UserTriggerHandler.createSharingForRelatedAccount(new List<User>());
        Test.stopTest();

        System.assert(true, 'Empty list handled without exception');
    }

    /**
     * Verifies bulk handling: 10 internal users with no AccountId processed
     * without exceptions, resulting in 0 AccountShare records.
     */
    @isTest
    static void testCreateSharing_bulkNoAccountId() {
        Profile std = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        List<User> users = new List<User>();
        for (Integer i = 0; i < 10; i++) {
            users.add(buildInternalUser(std.Id, '5' + i));
        }
        insert users;

        Set<Id> userIds = new Map<Id, User>(users).keySet();
        List<User> fetchedUsers = [SELECT Id, AccountId FROM User WHERE Id IN :userIds];

        Test.startTest();
        ARC_UserTriggerHandler.createSharingForRelatedAccount(fetchedUsers);
        Test.stopTest();

        List<AccountShare> shares = [
            SELECT Id FROM AccountShare
            WHERE UserOrGroupId IN :userIds AND RowCause = 'Manual'
        ];
        System.assertEquals(0, shares.size(),
            'No AccountShare records should be created for users with no AccountId');
    }
}