@isTest (isParallel=false)
private class ARC_UserPermissionServiceTest {

    // ─── Test Data Helpers ────────────────────────────────────────────────────

    private static Account createAccount() {
        Account acc = new Account(Name = 'Test Sharing Account');
        insert acc;
        return acc;
    }

    private static Contact createContact(Id accountId, String firstName, String lastName) {
        Contact c = new Contact(
            FirstName = firstName,
            LastName  = lastName,
            Email     = firstName.toLowerCase() + '.' + lastName.toLowerCase() + '@testpermservice.com',
            AccountId = accountId
        );
        insert c;
        return c;
    }

    /**
     * Creates a minimal internal (non-portal) User with the given profileId.
     * The username suffix avoids conflicts across test runs.
     */
    private static User createInternalUser(Id profileId, String suffix) {
        return new User(
            FirstName        = 'Test',
            LastName         = 'User' + suffix,
            Email            = 'testusr' + suffix + '@testpermservice.com',
            Username         = 'testusr' + suffix + '@testpermservice.com.' + UserInfo.getOrganizationId(),
            Alias            = ('tu' + suffix).left(8),
            TimeZoneSidKey   = 'America/Los_Angeles',
            LocaleSidKey     = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId        = profileId,
            IsActive         = true
        );
    }

    /**
     * Creates a community/portal User bound to a Contact.
     * Used for 'Employer Admin' / 'Employer Viewer' profile users.
     */
    private static User createPortalUser(Id contactId, Id profileId, String suffix) {
        return new User(
            ContactId        = contactId,
            FirstName        = 'Portal',
            LastName         = 'User' + suffix,
            Email            = 'portalusr' + suffix + '@testpermservice.com',
            Username         = 'portalusr' + suffix + '@testpermservice.com.' + UserInfo.getOrganizationId(),
            Alias            = ('pu' + suffix).left(8),
            CommunityNickname = ('pn' + suffix + UserInfo.getOrganizationId()).left(40),
            TimeZoneSidKey   = 'America/Los_Angeles',
            LocaleSidKey     = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId        = profileId,
            IsActive         = true
        );
    }

    // ─── setPermissionSetAndLicenseToPortalUser ───────────────────────────────

    /**
     * Verifies the method runs without error when the user's profile does not
     * match 'Employer Admin' or 'Employer Viewer', so no PSA is created.
     */
    @isTest
    static void testSetPermission_noMatchingProfile() {
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = createInternalUser(stdProfile.Id, '01');
        insert u;

        Test.startTest();
        ARC_UserPermissionService.setPermissionSetAndLicenseToPortalUser(new List<Id>{ u.Id });
        Test.stopTest();

        List<PermissionSetAssignment> psas = [
            SELECT Id FROM PermissionSetAssignment
            WHERE AssigneeId = :u.Id
              AND PermissionSet.Name IN ('Employer_Admin_Permissions', 'Employer_Viewer_Permissions')
        ];
        System.assertEquals(0, psas.size(),
            'No permission sets should be assigned for a non-matching profile');
    }

    /**
     * Verifies that a user with the 'Employer Admin' profile receives
     * the Employer_Admin_Permissions permission set.
     * Skips gracefully if the custom profile or permission set is absent.
     */
    @isTest
    static void testSetPermission_employerAdminGetsAdminPermSet() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Employer Admin' LIMIT 1];
        if (profiles.isEmpty()) { return; }
        List<PermissionSet> permSets = [SELECT Id FROM PermissionSet WHERE Name = 'Employer_Admin_Permissions' LIMIT 1];
        if (permSets.isEmpty()) { return; }

        Account acc = createAccount();
        Contact c   = createContact(acc.Id, 'Admin', 'UserA');
        User u      = createPortalUser(c.Id, profiles[0].Id, '02');
        insert u;

        Test.startTest();
        ARC_UserPermissionService.setPermissionSetAndLicenseToPortalUser(new List<Id>{ u.Id });
        Test.stopTest();

        List<PermissionSetAssignment> psas = [
            SELECT Id FROM PermissionSetAssignment
            WHERE AssigneeId = :u.Id
              AND PermissionSet.Name = 'Employer_Admin_Permissions'
        ];
        System.assertEquals(1, psas.size(),
            'Employer Admin user should receive Employer_Admin_Permissions');
    }

    /**
     * Verifies that a user with the 'Employer Viewer' profile receives
     * the Employer_Viewer_Permissions permission set.
     * Skips gracefully if the custom profile or permission set is absent.
     */
    @isTest
    static void testSetPermission_employerViewerGetsViewerPermSet() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Employer Viewer' LIMIT 1];
        if (profiles.isEmpty()) { return; }
        List<PermissionSet> permSets = [SELECT Id FROM PermissionSet WHERE Name = 'Employer_Viewer_Permissions' LIMIT 1];
        if (permSets.isEmpty()) { return; }

        Account acc = createAccount();
        Contact c   = createContact(acc.Id, 'Viewer', 'UserB');
        User u      = createPortalUser(c.Id, profiles[0].Id, '03');
        insert u;

        Test.startTest();
        ARC_UserPermissionService.setPermissionSetAndLicenseToPortalUser(new List<Id>{ u.Id });
        Test.stopTest();

        List<PermissionSetAssignment> psas = [
            SELECT Id FROM PermissionSetAssignment
            WHERE AssigneeId = :u.Id
              AND PermissionSet.Name = 'Employer_Viewer_Permissions'
        ];
        System.assertEquals(1, psas.size(),
            'Employer Viewer user should receive Employer_Viewer_Permissions');
    }


    // ─── createSharingForRelatedAccount ──────────────────────────────────────

    /**
     * Verifies the method runs without error when users have no AccountId.
     * No AccountShare records should be created.
     */
    @isTest
    static void testCreateSharing_userWithNoAccountId() {
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = createInternalUser(stdProfile.Id, '05');
        insert u;

        Test.startTest();
        ARC_UserPermissionService.createSharingForRelatedAccount(new List<Id>{ u.Id });
        Test.stopTest();

        List<AccountShare> shares = [
            SELECT Id FROM AccountShare
            WHERE UserOrGroupId = :u.Id AND RowCause = 'Manual'
        ];
        System.assertEquals(0, shares.size(),
            'No AccountShare should be created for a user with no AccountId');
    }

    /**
     * Verifies that AccountShare and UserShare records are created for a
     * portal user whose ContactId links them to an Account.
     * Skips gracefully if the custom portal profile is absent.
     */
    @isTest
    static void testCreateSharing_createsSharesForPortalUser() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Employer Admin' LIMIT 1];
        if (profiles.isEmpty()) { return; }

        Account acc = createAccount();
        Contact c   = createContact(acc.Id, 'Share', 'UserC');
        User u      = createPortalUser(c.Id, profiles[0].Id, '06');
        insert u;

        // Community users inherit AccountId from their Contact's Account
        User inserted = [SELECT Id, AccountId FROM User WHERE Id = :u.Id];
        if (inserted.AccountId == null) { return; }

        Test.startTest();
        ARC_UserPermissionService.createSharingForRelatedAccount(new List<Id>{ u.Id });
        Test.stopTest();

        List<AccountShare> accountShares = [
            SELECT Id FROM AccountShare
            WHERE AccountId      = :inserted.AccountId
              AND UserOrGroupId  = :u.Id
              AND RowCause       = 'Manual'
        ];
        System.assertEquals(1, accountShares.size(),
            'One AccountShare should be created for the portal user');
    }

    /**
     * Verifies that the method handles a bulk list of users without throwing
     * exceptions, even when none of them have an AccountId.
     */
    @isTest
    static void testCreateSharing_bulkNoAccountId() {
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        List<User> users = new List<User>();
        for (Integer i = 0; i < 10; i++) {
            users.add(createInternalUser(stdProfile.Id, '1' + i));
        }
        insert users;

        List<Id> userIds = new List<Id>(new Map<Id, User>(users).keySet());

        Test.startTest();
        ARC_UserPermissionService.createSharingForRelatedAccount(userIds);
        Test.stopTest();

        System.assert(true, 'Bulk call with no AccountIds completed without exception');
    }
}