@isTest
private class SG_PortalUserProvisionSubscriberTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'ProvisionTest Account');
        insert acc;
        Id sgRtId;
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName();
        if (rtMap.containsKey('ARC_SmallGroup')) sgRtId = rtMap.get('ARC_SmallGroup').getRecordTypeId();
        insert new List<Contact>{
            new Contact(FirstName='Admin',    LastName='PUser', Email='provision.admin@test.com',    AccountId=acc.Id, RecordTypeId=sgRtId, ARC_PortalAccess__c='Admin'),
            new Contact(FirstName='Viewer',   LastName='PUser', Email='provision.viewer@test.com',   AccountId=acc.Id, RecordTypeId=sgRtId, ARC_PortalAccess__c='Viewer'),
            new Contact(FirstName='NoAccess', LastName='PUser', Email='provision.noaccess@test.com', AccountId=acc.Id, RecordTypeId=sgRtId, ARC_PortalAccess__c='No Access'),
            new Contact(FirstName='Orphan',   LastName='PUser', Email='provision.orphan@test.com',   AccountId=acc.Id, RecordTypeId=sgRtId, ARC_PortalAccess__c='No Access')
        };
    }

    // ==========================================
    // Pure helper methods (no DML / no async)
    // ==========================================

    @isTest
    static void testPureHelpers() {
        System.assertEquals('Admin',     SG_PortalUserProvisionSubscriber.normalizeAccess('Admin'));
        System.assertEquals('Viewer',    SG_PortalUserProvisionSubscriber.normalizeAccess('Viewer'));
        System.assertEquals('No Access', SG_PortalUserProvisionSubscriber.normalizeAccess(null));
        System.assertEquals('No Access', SG_PortalUserProvisionSubscriber.normalizeAccess(''));
        System.assertEquals('No Access', SG_PortalUserProvisionSubscriber.normalizeAccess('Unknown'));

        User u1 = new User(Email='old@t.com', Username='old@t.com');
        SG_PortalUserProvisionSubscriber.syncUserInfoFromContact(u1, new Contact(FirstName='N', LastName='L', Email='new@t.com'));
        System.assertEquals('new@t.com', u1.Email);
        User u2 = new User(Email='keep@t.com', Username='keep@t.com');
        SG_PortalUserProvisionSubscriber.syncUserInfoFromContact(u2, new Contact(FirstName='F', LastName='', Email=''));
        System.assertEquals('keep@t.com', u2.Email);
        System.assertEquals('Portal', u2.LastName);

        Map<Id, Set<Id>> m = new Map<Id, Set<Id>>();
        Id uid = UserInfo.getUserId();
        Id psId = [SELECT Id FROM PermissionSet LIMIT 1].Id;
        SG_PortalUserProvisionSubscriber.add(m, null, psId);
        SG_PortalUserProvisionSubscriber.add(m, uid, null);
        System.assert(m.isEmpty());
        SG_PortalUserProvisionSubscriber.add(m, uid, psId);
        SG_PortalUserProvisionSubscriber.add(m, uid, psId);
        System.assertEquals(1, m.get(uid).size());

        List<PermissionSet> ps = [SELECT Id FROM PermissionSet LIMIT 2];
        Map<String, Id> psMap = new Map<String, Id>{
            'Employer_Admin_Permissions'  => ps[0].Id,
            'Employer_Viewer_Permissions' => ps.size() > 1 ? ps[1].Id : ps[0].Id
        };
        Map<Id, Set<Id>> toAdd = new Map<Id, Set<Id>>(), toRem = new Map<Id, Set<Id>>();
        SG_PortalUserProvisionSubscriber.planPermissionSets(uid, 'Admin',  psMap, toAdd, toRem);
        System.assert(toAdd.get(uid).contains(ps[0].Id));
        toAdd.clear(); toRem.clear();
        SG_PortalUserProvisionSubscriber.planPermissionSets(uid, 'Viewer', psMap, toAdd, toRem);
        System.assert(toAdd.get(uid).contains(psMap.get('Employer_Viewer_Permissions')));
    }

    @isTest
    static void testBuildUserForCreate() {
        Map<String, Id> profiles = buildProfileMap();
        Contact c = [SELECT Id, FirstName, LastName, Email, AccountId FROM Contact WHERE Email = 'provision.admin@test.com' LIMIT 1];
        User u = SG_PortalUserProvisionSubscriber.buildUserForCreate(c, 'Admin', profiles);
        System.assertEquals(c.Email, u.Email);
        System.assertEquals(c.Email, u.Username);
        System.assertEquals(profiles.get('Employer Admin'), u.ProfileId);
        System.assert(u.Alias.length() <= 8);
        System.assert(u.CommunityNickname.startsWith('sg_'));
        System.assertEquals(profiles.get('Employer Viewer'), SG_PortalUserProvisionSubscriber.buildUserForCreate(c, 'Viewer', profiles).ProfileId);
        c.Email = 'averylongemailaddressthatexceedseightycharacterslimithere@verylongdomain.example.com';
        System.assert(SG_PortalUserProvisionSubscriber.buildUserForCreate(c, 'Admin', profiles).Username.length() <= 80);
        c.FirstName = null;
        System.assertEquals('p', SG_PortalUserProvisionSubscriber.buildUserForCreate(c, 'Admin', profiles).Alias.left(1));
    }

    @isTest
    static void testApplyPermissionSetChanges() {
        SG_PortalUserProvisionSubscriber.applyPermissionSetChanges(null, null);
        SG_PortalUserProvisionSubscriber.applyPermissionSetChanges(new Map<Id,Set<Id>>(), new Map<Id,Set<Id>>());
        Id uid = UserInfo.getUserId();
        Id psId = [SELECT Id FROM PermissionSet LIMIT 1].Id;
        Test.startTest();
        SG_PortalUserProvisionSubscriber.applyPermissionSetChanges(
            new Map<Id, Set<Id>>{ uid => new Set<Id>{ psId } },
            new Map<Id, Set<Id>>{ uid => new Set<Id>{ psId } }
        );
        Test.stopTest();
    }

    // ==========================================
    // run()
    // ==========================================

    @isTest
    static void testRun_EdgeCases() {
        // Empty list, blank/invalid ContactIds → all early returns, no async
        SG_PortalUserProvisionSubscriber.run(new List<SG_Portal_User_Provisioning__e>());
        SG_PortalUserProvisionSubscriber.run(new List<SG_Portal_User_Provisioning__e>{
            new SG_Portal_User_Provisioning__e(ContactId__c = ''),
            new SG_Portal_User_Provisioning__e(ContactId__c = 'BAD_ID')
        });
        // No Access contact with no user → usersToInsert+usersToUpdate empty → no job enqueued
        Contact noAccC  = [SELECT Id FROM Contact WHERE Email = 'provision.noaccess@test.com' LIMIT 1];
        SG_PortalUserProvisionSubscriber.run(new List<SG_Portal_User_Provisioning__e>{
            new SG_Portal_User_Provisioning__e(ContactId__c = noAccC.Id, ARC_TriggerUserDeactivation__c = false)
        });
        // Deactivation, no existing user → ContactDeleteQueueable (depth 1, no further chain)
        Contact orphanC = [SELECT Id FROM Contact WHERE Email = 'provision.orphan@test.com' LIMIT 1];
        Test.startTest();
        SG_PortalUserProvisionSubscriber.run(new List<SG_Portal_User_Provisioning__e>{
            new SG_Portal_User_Provisioning__e(ContactId__c = orphanC.Id, ARC_TriggerUserDeactivation__c = true)
        });
        Test.stopTest();
    }

    @isTest
    static void testRun_ProvisioningPaths() {
        // Admin + Viewer (no existing user) → InsertQueueable → PermsAndGroupsQueueable (depth 2).
        // No deactivation event so contactsToDelete is empty, preventing a 3-level chain.
        Contact adminC  = [SELECT Id FROM Contact WHERE Email = 'provision.admin@test.com'  LIMIT 1];
        Contact viewerC = [SELECT Id FROM Contact WHERE Email = 'provision.viewer@test.com' LIMIT 1];
        Test.startTest();
        SG_PortalUserProvisionSubscriber.run(new List<SG_Portal_User_Provisioning__e>{
            new SG_Portal_User_Provisioning__e(ContactId__c = adminC.Id,  ARC_TriggerUserDeactivation__c = false),
            new SG_Portal_User_Provisioning__e(ContactId__c = viewerC.Id, ARC_TriggerUserDeactivation__c = false)
        });
        Test.stopTest();
    }

    // ==========================================
    // Queueables — one enqueue per startTest/stopTest to avoid async stack depth errors
    // ==========================================

    @isTest
    static void testUpdateQueueable_InsertsChain() {
        Test.startTest();
        System.enqueueJob(new SG_PortalUserProvisionSubscriber.UpdateQueueable(
            new List<User>(),
            new List<User>(),
            new Map<Id,String>(),
            new Map<String,Id>(),
            new List<User>(),
            new Set<Id>()
        ));
        Test.stopTest();
    }

    @isTest
    static void testUpdateQueueable_SuccessChain() {
        Test.startTest();
        System.enqueueJob(new SG_PortalUserProvisionSubscriber.UpdateQueueable(
            new List<User>{ new User(Id = UserInfo.getUserId()) },
            new List<User>(),
            new Map<Id,String>{ UserInfo.getUserId() => 'No Access' },
            new Map<String,Id>(),
            new List<User>(),
            new Set<Id>()
        ));
        Test.stopTest();
    }

    @isTest
    static void testUpdateQueueable_ContactsToDeleteChain() {
        Contact c = [SELECT Id FROM Contact WHERE Email = 'provision.orphan@test.com' LIMIT 1];
        Test.startTest();
        System.enqueueJob(new SG_PortalUserProvisionSubscriber.UpdateQueueable(
            new List<User>(),
            new List<User>(),
            new Map<Id,String>(),
            new Map<String,Id>(),
            new List<User>(),
            new Set<Id>{ c.Id }
        ));
        Test.stopTest();
        System.assert(
            [SELECT Id FROM Contact WHERE Id = :c.Id].isEmpty(),
            'Orphan should be deleted'
        );
    }

    @isTest
    static void testInsertQueueable_FailedInsert() {
        // Malformed user → failed insert → results loop runs, no chain (depth 1)
        Test.startTest();
        System.enqueueJob(new SG_PortalUserProvisionSubscriber.InsertQueueable(
            new List<User>{ new User() },
            new Map<Id,String>(), new Map<String,Id>(), new List<User>(), new Set<Id>()
        ));
        Test.stopTest();
    }

    @isTest
    static void testInsertQueueable_ContactsToDeleteChain() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'ProvisionTest Account' LIMIT 1];
        Contact orphan = new Contact(FirstName='Ins', LastName='Chain', Email='ins.chain@test.com', AccountId=acc.Id);
        insert orphan;
        Test.startTest();
        System.enqueueJob(new SG_PortalUserProvisionSubscriber.InsertQueueable(
            new List<User>{ new User() },
            new Map<Id,String>(),
            new Map<String,Id>(),
            new List<User>(),
            new Set<Id>{ orphan.Id }
        ));
        Test.stopTest();
        System.assert(
            [SELECT Id FROM Contact WHERE Id = :orphan.Id].isEmpty(),
            'Orphan should be deleted'
        );
    }

    @isTest
    static void testPermsAndGroupsQueueable_ContactsToDeleteChain() {
        // PermsAndGroupsQueueable chains ContactDeleteQueueable (depth 2); orphan contact is deleted
        Account acc = [SELECT Id FROM Account WHERE Name = 'ProvisionTest Account' LIMIT 1];
        Contact orphan = new Contact(FirstName='D1', LastName='Q', Email='d1.q@test.com', AccountId=acc.Id);
        insert orphan;
        Test.startTest();
        System.enqueueJob(new SG_PortalUserProvisionSubscriber.PermsAndGroupsQueueable(
            new List<User>(), new Map<Id,String>(), new Map<String,Id>(), new Set<Id>{ orphan.Id }
        ));
        Test.stopTest();
        System.assert([SELECT Id FROM Contact WHERE Id = :orphan.Id].isEmpty(), 'Orphan should be deleted');
    }

    @isTest
    static void testContactDeleteQueueable() {
        // Directly tests ContactDeleteQueueable: orphaned contact (no linked user) gets deleted
        Account acc = [SELECT Id FROM Account WHERE Name = 'ProvisionTest Account' LIMIT 1];
        Contact orphan = new Contact(FirstName='D2', LastName='Q', Email='d2.q@test.com', AccountId=acc.Id);
        insert orphan;
        Test.startTest();
        System.enqueueJob(new SG_PortalUserProvisionSubscriber.ContactDeleteQueueable(new List<Id>{ orphan.Id }));
        Test.stopTest();
        System.assert([SELECT Id FROM Contact WHERE Id = :orphan.Id].isEmpty(), 'Orphan should be deleted');
    }

    // ==========================================
    // addRemoveFromPublicGroupSync (synchronous — no startTest/stopTest needed)
    // ==========================================

    @isTest
    static void testAddRemoveFromPublicGroupSync() {
        Id groupId = ensureEmployerPortalGroup();
        Id userId  = UserInfo.getUserId();

        SG_PortalUserProvisionSubscriber.addRemoveFromPublicGroupSync(new List<Id>(), new List<Id>()); // early return

        SG_PortalUserProvisionSubscriber.addRemoveFromPublicGroupSync(new List<Id>(), new List<Id>{ userId }); // add
        System.assertEquals(false,[SELECT Id FROM GroupMember WHERE GroupId=:groupId AND UserOrGroupId=:userId].isEmpty(), 'User should be added');

        SG_PortalUserProvisionSubscriber.addRemoveFromPublicGroupSync(new List<Id>(), new List<Id>{ userId }); // no duplicate
        System.assertEquals(1, [SELECT Id FROM GroupMember WHERE GroupId=:groupId AND UserOrGroupId=:userId].size(), 'No duplicate');

        SG_PortalUserProvisionSubscriber.addRemoveFromPublicGroupSync(new List<Id>{ userId }, new List<Id>()); // remove
        System.assert([SELECT Id FROM GroupMember WHERE GroupId=:groupId AND UserOrGroupId=:userId].isEmpty(), 'User should be removed');
    }

    // ==========================================
    // processPermsAndGroups
    // ==========================================

    @isTest
    static void testProcessPermsAndGroups_AllBranches() {
        ensureEmployerPortalGroup();
        Contact c = [SELECT Id FROM Contact WHERE Email = 'provision.admin@test.com' LIMIT 1];
        List<PermissionSet> psList = [SELECT Id FROM PermissionSet WHERE IsOwnedByProfile = false LIMIT 2];
        Map<String, Id> psMap = new Map<String, Id>();
        if (!psList.isEmpty()) {
            psMap.put('Employer_Admin_Permissions',  psList[0].Id);
            psMap.put('Employer_Viewer_Permissions', psList.size() > 1 ? psList[1].Id : psList[0].Id);
        }

        // Null Id user → skipped silently (no DML)
        SG_PortalUserProvisionSubscriber.processPermsAndGroups(
            new List<User>{ new User(ContactId = c.Id) }, new Map<Id,String>{ c.Id => 'Admin' }, psMap
        );

        // Admin access (real user Id) → planPermissionSets + add to group
        User u = new User(Id = UserInfo.getUserId());
        u.ContactId = c.Id;
        Test.startTest();
        SG_PortalUserProvisionSubscriber.processPermsAndGroups(
            new List<User>{ u }, new Map<Id,String>{ c.Id => 'Admin' }, psMap
        );
        Test.stopTest();

        // No Access (null ContactId → access null) → usersToRemovePG branch + remove from group
        SG_PortalUserProvisionSubscriber.processPermsAndGroups(
            new List<User>{ new User(Id = UserInfo.getUserId()) }, new Map<Id,String>(), psMap
        );
    }

    // ==========================================
    // Helpers
    // ==========================================

    private static Id ensureEmployerPortalGroup() {
        List<Group> g = [SELECT Id FROM Group WHERE DeveloperName = 'Employer_Portal_Users' LIMIT 1];
        if (!g.isEmpty()) return g[0].Id;
        Group ng = new Group(Name='Employer Portal Users', DeveloperName='Employer_Portal_Users', Type='Regular');
        insert ng;
        return ng.Id;
    }

    private static Map<String, Id> buildProfileMap() {
        Map<String, Id> profiles = new Map<String, Id>();
        for (Profile p : [SELECT Id, Name FROM Profile WHERE Name IN ('Employer Admin', 'Employer Viewer') LIMIT 2]) {
            profiles.put(p.Name, p.Id);
        }
        if (!profiles.containsKey('Employer Admin') || !profiles.containsKey('Employer Viewer')) {
            Id fallback = [SELECT Id FROM Profile WHERE UserLicense.Name = 'Salesforce' LIMIT 1].Id;
            if (!profiles.containsKey('Employer Admin'))  profiles.put('Employer Admin',  fallback);
            if (!profiles.containsKey('Employer Viewer')) profiles.put('Employer Viewer', fallback);
        }
        return profiles;
    }
}