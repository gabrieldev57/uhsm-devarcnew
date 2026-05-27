/**
 * Purpose:
 * - Orchestrates portal user provisioning using a State-Based (Idempotent) approach.
 * - Uses Chained Queueable Apex (Update -> Insert -> Perms) to fully isolate Inserts 
 * from Permission/Group assignments, avoiding the implicit AccountShare Mixed DML.
 */
public without sharing class SG_PortalUserProvisionSubscriber {

    public static void run(List<SG_Portal_User_Provisioning__e> events) {

        if (events == null || events.isEmpty()) return;

        System.debug('=== SG_PortalUserProvisionSubscriber.run() Started ===');
        System.debug('Events received: ' + events.size());
        
        for (SG_Portal_User_Provisioning__e e : events) {
            System.debug('Event: ContactId=' + e.ContactId__c + ', ARC_TriggerUserDeactivation__c=' + e.ARC_TriggerUserDeactivation__c);
        }

        Set<Id> contactIds = new Set<Id>();
        Map<Id, Boolean> contactDeactivation = new Map<Id, Boolean>();
        for (SG_Portal_User_Provisioning__e e : events) {
            if (String.isNotBlank(e.ContactId__c)) { 
                try {
                    Id contactId = (Id)e.ContactId__c;
                    contactIds.add(contactId);
                    if(e.ARC_TriggerUserDeactivation__c == true){
                        contactDeactivation.put(contactId, true);
                    }
                } catch (Exception ex) {
                    continue;
                }
            }
        }
        if (contactIds.isEmpty()) return;

        Map<Id, Contact> contacts = new Map<Id, Contact>([
            SELECT Id, AccountId, FirstName, LastName, Email, ARC_PortalAccess__c
            FROM Contact WHERE Id IN :contactIds
        ]);

        Map<Id, User> usersByContact = new Map<Id, User>();
        for (User u : [SELECT Id, ContactId, IsActive, ProfileId, FirstName, LastName, Email, Username FROM User WHERE ContactId IN :contactIds]) {
            usersByContact.put(u.ContactId, u);
        }

        Map<String, Id> profiles = new Map<String, Id>();
        for (Profile p : [SELECT Id, Name FROM Profile WHERE Name IN ('Employer Admin','Employer Viewer')]) profiles.put(p.Name, p.Id);
        
        Map<String, Id> psMap = new Map<String, Id>();
        for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN ('Employer_Admin_Permissions','Employer_Viewer_Permissions')]) psMap.put(ps.Name, ps.Id);

        List<User> usersToInsert = new List<User>();
        List<User> usersToUpdate = new List<User>();
        Map<Id, String> desiredAccessByContact = new Map<Id, String>();

        Set<Id> contactsToDeleteAfter = new Set<Id>(); 

        for (Contact c : contacts.values()) {
            String desiredAccess = normalizeAccess(c.ARC_PortalAccess__c);
            User existingUser = usersByContact.get(c.Id);
            
            desiredAccessByContact.put(c.Id, desiredAccess);

            if(contactDeactivation.containsKey(c.Id)){
                if(existingUser != null){
                    existingUser.IsActive = false;
                    existingUser.IsPortalEnabled = false;

                    System.debug('User is active?: ' + existingUser.IsActive);
                    System.debug('Users is enabled to portal?: ' + existingUser.IsPortalEnabled);
                    usersToUpdate.add(existingUser);
                    contactsToDeleteAfter.add(c.Id);
                }else{
                    contactsToDeleteAfter.add(c.Id);
                }
            }

            else if (desiredAccess == 'Admin' || desiredAccess == 'Viewer') {
                Id targetProfileId = (desiredAccess == 'Admin') ? profiles.get('Employer Admin') : profiles.get('Employer Viewer');
                
                if (existingUser == null) {
                    User u = buildUserForCreate(c, desiredAccess, profiles);
                    usersToInsert.add(u);
                } else {
                    existingUser.IsActive = true;
                    existingUser.ProfileId = targetProfileId;
                    syncUserInfoFromContact(existingUser, c);
                    usersToUpdate.add(existingUser);
                }
            } else {
                if (existingUser != null && existingUser.IsActive) {  
                    existingUser.IsActive = false;
                    syncUserInfoFromContact(existingUser, c);
                    usersToUpdate.add(existingUser);
                }
            }
        }

        if (!usersToUpdate.isEmpty()) {
            System.enqueueJob(new UpdateQueueable(usersToUpdate, usersToInsert, desiredAccessByContact, psMap, new List<User>(), contactsToDeleteAfter));
        } else if (!usersToInsert.isEmpty()) {
            System.enqueueJob(new InsertQueueable(usersToInsert, desiredAccessByContact, psMap, new List<User>(), contactsToDeleteAfter));
        } else if(!contactsToDeleteAfter.isEmpty()){
            System.enqueueJob(new ContactDeleteQueueable(new List<Id>(contactsToDeleteAfter)));
        }
    }
    // ==========================================
    // QUEUEABLE
    // ==========================================

    public class UpdateQueueable implements Queueable {
        private List<User> updates;
        private List<User> inserts;
        private Map<Id, String> accessMap;
        private Map<String, Id> psMap;
        private List<User> successfulUsers;
        private Set<Id> contactsToDelete; // For bug-3534: pass contact IDs that should be deleted after user deactivation

        public UpdateQueueable(List<User> updates, List<User> inserts, Map<Id, String> accessMap, Map<String, Id> psMap, List<User> successfulUsers, Set<Id> contactsToDelete) {
            this.updates = updates;
            this.inserts = inserts;
            this.accessMap = accessMap;
            this.psMap = psMap;
            this.successfulUsers = successfulUsers != null ? successfulUsers : new List<User>();
            this.contactsToDelete = contactsToDelete; // for bug-3534
        }

        public void execute(QueueableContext context) {
            try {
                Database.SaveResult[] results = Database.update(updates, false);
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        successfulUsers.add(updates[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Error in UpdateQueueable: ' + e.getMessage());
                } finally {
                    if (inserts != null && !inserts.isEmpty()) {
                        SG_PortalUserProvisionSubscriber.enqueueChainedJob(new InsertQueueable(inserts, accessMap, psMap, successfulUsers, contactsToDelete));
                    } else if (!successfulUsers.isEmpty()) {
                        SG_PortalUserProvisionSubscriber.enqueueChainedJob(new PermsAndGroupsQueueable(successfulUsers, accessMap, psMap, contactsToDelete));
                    }else if(contactsToDelete != null && !contactsToDelete.isEmpty()){
                        // If there are no successful user updates but there are contacts to delete, we should still enqueue the ContactDeleteQueueable
                        SG_PortalUserProvisionSubscriber.enqueueChainedJob(new ContactDeleteQueueable(new List<Id>(contactsToDelete)));
                    }
        }
        }
    }

    public class InsertQueueable implements Queueable {
        private List<User> inserts;
        private Map<Id, String> accessMap;
        private Map<String, Id> psMap;
        private List<User> successfulUsers;
        private Set<Id> contactsToDelete; // For bug-3534: pass contact IDs that should be deleted after user deactivation

        public InsertQueueable(List<User> inserts, Map<Id, String> accessMap, Map<String, Id> psMap, List<User> successfulUsers, Set<Id> contactsToDelete) {
            this.inserts = inserts;
            this.accessMap = accessMap;
            this.psMap = psMap;
            this.successfulUsers = successfulUsers != null ? successfulUsers : new List<User>();
            this.contactsToDelete = contactsToDelete; // for bug-3534
        }

        public void execute(QueueableContext context) {
            try {
                // Salesforce throws "Cannot create users or roles in an account owned by a portal user"
                // when the contact's account owner is a portal/community user.
                // Fix: reassign those accounts to the current internal (integration) user first.
                Set<Id> contactIds = new Set<Id>();
                for (User u : inserts) {
                    if (u.ContactId != null) contactIds.add(u.ContactId);
                }
                if (!contactIds.isEmpty()) {
                    Set<Id> accountIds = new Set<Id>();
                    for (Contact c : [SELECT AccountId FROM Contact WHERE Id IN :contactIds AND AccountId != null]) {
                        accountIds.add(c.AccountId);
                    }
                    User integrationUser = [
                        SELECT Id, Name, UserType, UserRoleId, IsActive
                        FROM User
                        WHERE Alias = 'iuser'
                        LIMIT 1
                    ];
                    if (!accountIds.isEmpty()) {
                        List<Account> toReown = new List<Account>();
                        for (Account a : [
                            SELECT Id FROM Account
                            WHERE Id IN :accountIds
                            AND Owner.UserType IN ('PowerPartner', 'PowerCustomerSuccess', 'CustomerSuccess', 'CspLitePortal')
                        ]) {
                            toReown.add(new Account(Id = a.Id, OwnerId = integrationUser.Id));
                        }
                        if (!toReown.isEmpty()) {
                            Database.update(toReown, false);
                        }
                    }
                }

                Database.SaveResult[] results = Database.insert(inserts, false);
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        successfulUsers.add(inserts[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Error in InsertQueueable: ' + e.getMessage());
            } finally {
                if (!successfulUsers.isEmpty()) {
                    SG_PortalUserProvisionSubscriber.enqueueChainedJob(new PermsAndGroupsQueueable(successfulUsers, accessMap, psMap, contactsToDelete));
                }else if (contactsToDelete != null && !contactsToDelete.isEmpty()){
                    // If there are no successful user inserts but there are contacts to delete, we should still enqueue the ContactDeleteQueueable
                    SG_PortalUserProvisionSubscriber.enqueueChainedJob(new ContactDeleteQueueable(new List<Id>(contactsToDelete)));
                }
            }
        }
    }

    public class PermsAndGroupsQueueable implements Queueable {
        private List<User> processedUsers;
        private Map<Id, String> accessMap;
        private Map<String, Id> psMap;
        private Set<Id> contactsToDelete;

        public PermsAndGroupsQueueable(List<User> processedUsers, Map<Id, String> accessMap, Map<String, Id> psMap, Set<Id> contactsToDelete) {
            this.processedUsers = processedUsers;
            this.accessMap = accessMap;
            this.psMap = psMap;
            this.contactsToDelete = contactsToDelete;
        }

        public void execute(QueueableContext context) {
            try {
                SG_PortalUserProvisionSubscriber.processPermsAndGroups(processedUsers, accessMap, psMap);
                SG_PortalUserProvisionSubscriber.grantAccountEditAccess(processedUsers, accessMap);

                //BUG-3534: new logic to handle deactivation of users from portal when contacts are deleted 
                
                if (contactsToDelete != null && !contactsToDelete.isEmpty()) {
                SG_PortalUserProvisionSubscriber.enqueueChainedJob(new ContactDeleteQueueable(new List<Id>(contactsToDelete)));
                }
                
            } catch (Exception e) {
                System.debug('Error in PermsAndGroupsQueueable: ' + e.getMessage());
            }
        }
    }

    public class ContactDeleteQueueable implements Queueable{
        private List<Id> contactIds;

        public ContactDeleteQueueable(List<Id>contactIds){
            this.contactIds = contactIds;
        }

        public void execute(QueueableContext context){
            try {
                Map<Id, Integer> userCountByContact = new Map<Id, Integer>();
                    
                for (User u : [SELECT ContactId FROM User WHERE ContactId IN :contactIds AND IsActive = false]) {
                    userCountByContact.put(u.ContactId, 
                        (userCountByContact.containsKey(u.ContactId) ? userCountByContact.get(u.ContactId) : 0) + 1);
                }
                
                List<Contact> contactsToDelete = new List<Contact>();
                for (Id contactId : contactIds) {
                    if (!userCountByContact.containsKey(contactId)) {
                        contactsToDelete.add(new Contact(Id = contactId));
                    }
                }
                
                if (!contactsToDelete.isEmpty()) {
                    delete contactsToDelete;
                    System.debug('Deleted Contacts: ' + contactsToDelete.size());
                }
                
            } catch (Exception e) {
                System.debug('Error Deleting Contacts: ' + e.getMessage());
            }
        }
    }

    private static void enqueueChainedJob(Queueable nextJob) {
        if (nextJob == null) return;

        if (Test.isRunningTest()) {
            return;
        }

        System.enqueueJob(nextJob);
    }

    private static void enqueueChainedJob(ContactDeleteQueueable nextJob) {
        if (nextJob == null) return;

        if (Test.isRunningTest()) {
            nextJob.execute(null);
            return;
        }

        System.enqueueJob(nextJob);
    }
    //END of fix to Bug-3534 logic

    // ==========================================
    // HELPERS
    // ==========================================

    public static void processPermsAndGroups(List<User> processedUsers, Map<Id, String> accessMap, Map<String, Id> psMap) {
        Map<Id, Set<Id>> psToAddByUser = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> psToRemoveByUser = new Map<Id, Set<Id>>();
        List<Id> usersToRemovePG = new List<Id>();
        List<Id> usersToAddToPG = new List<Id>();

        for (User u : processedUsers) {
            if (u.Id == null) continue; 
            String access = accessMap.get(u.ContactId);

            if (access == 'Admin' || access == 'Viewer') {
                planPermissionSets(u.Id, access, psMap, psToAddByUser, psToRemoveByUser);
                usersToAddToPG.add(u.Id);
            } else {
                usersToRemovePG.add(u.Id);
            }
        }

        applyPermissionSetChanges(psToRemoveByUser, psToAddByUser);
        
        if (!usersToRemovePG.isEmpty() || !usersToAddToPG.isEmpty()) {
            addRemoveFromPublicGroupSync(usersToRemovePG, usersToAddToPG);
        }
    }

    public static void grantAccountEditAccess(List<User> processedUsers, Map<Id, String> accessMap) {
        Set<Id> adminContactIds = new Set<Id>();
        Set<Id> nonAdminContactIds = new Set<Id>();
        Map<Id, Id> userIdByContactId = new Map<Id, Id>();

        for (User u : processedUsers) {
            if (u.Id == null || u.ContactId == null) continue;
            String access = accessMap.get(u.ContactId);
            userIdByContactId.put(u.ContactId, u.Id);
            if (access == 'Admin' || access == 'Viewer') {
                adminContactIds.add(u.ContactId);
            } else {
                nonAdminContactIds.add(u.ContactId);
            }
        }
        if (userIdByContactId.isEmpty()) return;

        Set<Id> allContactIds = new Set<Id>();
        allContactIds.addAll(adminContactIds);
        allContactIds.addAll(nonAdminContactIds);

        // Map ContactId -> AccountId
        Map<Id, Id> accountIdByContactId = new Map<Id, Id>();
        for (Contact c : [SELECT Id, AccountId FROM Contact WHERE Id IN :allContactIds AND AccountId != null]) {
            accountIdByContactId.put(c.Id, c.AccountId);
        }
        if (accountIdByContactId.isEmpty()) return;

        Set<Id> allAccountIds = new Set<Id>(accountIdByContactId.values());
        Set<Id> allUserIds = new Set<Id>(userIdByContactId.values());

        // Load all existing manual shares for these users/accounts
        Map<String, AccountShare> existingSharesByKey = new Map<String, AccountShare>();
        for (AccountShare share : [
            SELECT Id, AccountId, UserOrGroupId
            FROM AccountShare
            WHERE AccountId IN :allAccountIds AND UserOrGroupId IN :allUserIds AND RowCause = 'Manual'
        ]) {
            existingSharesByKey.put(String.valueOf(share.AccountId) + ':' + String.valueOf(share.UserOrGroupId), share);
        }

        List<AccountShare> sharesToInsert = new List<AccountShare>();
        List<AccountShare> sharesToDelete = new List<AccountShare>();

        for (Id contactId : accountIdByContactId.keySet()) {
            Id accountId = accountIdByContactId.get(contactId);
            Id userId = userIdByContactId.get(contactId);
            if (accountId == null || userId == null) continue;
            String key = String.valueOf(accountId) + ':' + String.valueOf(userId);

            if (adminContactIds.contains(contactId)) {
                // Grant Edit if not already shared
                if (!existingSharesByKey.containsKey(key)) {
                    sharesToInsert.add(new AccountShare(
                        AccountId = accountId,
                        UserOrGroupId = userId,
                        AccountAccessLevel = 'Edit',
                        OpportunityAccessLevel = 'None',
                        CaseAccessLevel = 'None',
                        RowCause = 'Manual'
                    ));
                }
            } else {
                // Remove manual Edit share if downgraded to Viewer / No Access
                if (existingSharesByKey.containsKey(key)) {
                    sharesToDelete.add(existingSharesByKey.get(key));
                }
            }
        }

        if (!sharesToInsert.isEmpty()) {
            Database.insert(sharesToInsert, false);
        }
        if (!sharesToDelete.isEmpty()) {
            Database.delete(sharesToDelete, false);
        }
    }

    public static String normalizeAccess(String raw) {
        if (String.isBlank(raw)) return 'No Access';
        String v = raw.trim();
        if (v == 'Admin' || v == 'Viewer') return v;
        return 'No Access';
    }

    public static User buildUserForCreate(Contact c, String access, Map<String, Id> profiles) {
        String last = c.LastName;
        String first = c.FirstName;
        String email = c.Email.trim();
        
        String username = email;
        if (username.length() > 80) username = username.substring(0, 80);

        String alias = (String.isBlank(first) ? 'p' : first.left(1)) + last.left(Math.min(4, last.length()));
        alias = alias.left(8);

        return new User(
            ContactId = c.Id,
            FirstName = c.FirstName,
            LastName = last,
            Email = email,
            Username = username,
            Alias = alias,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            CommunityNickname = ('sg_' + c.Id).left(40),
            ProfileId = (access == 'Admin') ? profiles.get('Employer Admin') : profiles.get('Employer Viewer'),
            IsActive = true
        );
    }

    public static void planPermissionSets(Id userId, String access, Map<String, Id> psMap, Map<Id, Set<Id>> psToAddByUser, Map<Id, Set<Id>> psToRemoveByUser) {
        Id adminPs  = psMap.get('Employer_Admin_Permissions');
        Id viewerPs = psMap.get('Employer_Viewer_Permissions');

        if (access == 'Admin') {
            add(psToAddByUser, userId, adminPs);
            add(psToRemoveByUser, userId, viewerPs);
        } else if (access == 'Viewer') {
            add(psToAddByUser, userId, viewerPs);
            add(psToRemoveByUser, userId, adminPs);
        }
    }

    public static void add(Map<Id, Set<Id>> m, Id userId, Id psId) {
        if (userId == null || psId == null) return;
        if (!m.containsKey(userId)) m.put(userId, new Set<Id>());
        m.get(userId).add(psId);
    }

    public static void applyPermissionSetChanges(Map<Id, Set<Id>> psToRemoveByUser, Map<Id, Set<Id>> psToAddByUser) {
        if (psToRemoveByUser == null) psToRemoveByUser = new Map<Id, Set<Id>>();
        if (psToAddByUser == null) psToAddByUser = new Map<Id, Set<Id>>();

        Set<Id> userIds = new Set<Id>();
        userIds.addAll(psToRemoveByUser.keySet());
        userIds.addAll(psToAddByUser.keySet());
        if (userIds.isEmpty()) return;

        Set<Id> targetPsIds = new Set<Id>();
        for (Set<Id> s : psToRemoveByUser.values()) if (s != null) targetPsIds.addAll(s);
        for (Set<Id> s : psToAddByUser.values()) if (s != null) targetPsIds.addAll(s);
        targetPsIds.remove(null);

        if (targetPsIds.isEmpty()) return;

        List<PermissionSetAssignment> existing = [
            SELECT Id, AssigneeId, PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId IN :userIds AND PermissionSetId IN :targetPsIds
        ];

        Map<Id, Set<Id>> currentPsByUser = new Map<Id, Set<Id>>();
        Map<String, PermissionSetAssignment> psaByKey = new Map<String, PermissionSetAssignment>();

        for (PermissionSetAssignment psa : existing) {
            if (!currentPsByUser.containsKey(psa.AssigneeId)) currentPsByUser.put(psa.AssigneeId, new Set<Id>());
            currentPsByUser.get(psa.AssigneeId).add(psa.PermissionSetId);
            psaByKey.put(String.valueOf(psa.AssigneeId) + ':' + String.valueOf(psa.PermissionSetId), psa);
        }

        List<PermissionSetAssignment> toDelete = new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> toInsert = new List<PermissionSetAssignment>();

        for (Id userId : psToRemoveByUser.keySet()) {
            if (psToRemoveByUser.get(userId) == null) continue;
            for (Id psId : psToRemoveByUser.get(userId)) {
                if (psId == null) continue;
                PermissionSetAssignment psa = psaByKey.get(String.valueOf(userId) + ':' + String.valueOf(psId));
                if (psa != null) toDelete.add(psa);
            }
        }

        for (Id userId : psToAddByUser.keySet()) {
            if (psToAddByUser.get(userId) == null) continue;
            Set<Id> current = currentPsByUser.containsKey(userId) ? currentPsByUser.get(userId) : new Set<Id>();
            for (Id psId : psToAddByUser.get(userId)) {
                if (psId != null && !current.contains(psId)) {
                    toInsert.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = psId));
                }
            }
        }

        try {
            if (!toDelete.isEmpty()) Database.delete(toDelete, false);
        } catch (Exception e) {
            System.debug('error deleting permission: ' + e.getMessage());
        }

        try {
            if (!toInsert.isEmpty()) Database.insert(toInsert, false);
        } catch (Exception e) {
            System.debug('permission already assigned: ' + e.getMessage());
        }
    }

    public static void syncUserInfoFromContact(User u, Contact c) {
        u.FirstName = c.FirstName;
        u.LastName  = String.isBlank(c.LastName) ? 'Portal' : c.LastName;
    
        if (!String.isBlank(c.Email)) {
            String email = c.Email.trim();
            u.Email = email;
            String username = email;
            if (username.length() > 80) username = username.substring(0, 80);
            u.Username = username;
        }
    }

    public static void addRemoveFromPublicGroupSync(List<Id> usersIdToRemove, List<Id> usersIdToAdd) {
        if (usersIdToRemove.isEmpty() && usersIdToAdd.isEmpty()) return;

        Group publicGroup = [SELECT Id FROM Group WHERE DeveloperName = 'Employer_Portal_Users' LIMIT 1];

        Set<Id> allIds = new Set<Id>();
        allIds.addAll(usersIdToAdd);
        allIds.addAll(usersIdToRemove);

        List<GroupMember> existingGM = [
            SELECT Id, UserOrGroupId 
            FROM GroupMember 
            WHERE GroupId = :publicGroup.Id AND UserOrGroupId IN :allIds
        ];

        Set<Id> usersAlreadyInGroup = new Set<Id>();
        List<GroupMember> gmToRemove = new List<GroupMember>();

        for (GroupMember gm : existingGM) {
            usersAlreadyInGroup.add(gm.UserOrGroupId);
            
            if (usersIdToRemove.contains(gm.UserOrGroupId)) {
                gmToRemove.add(gm);
            }
        }

        List<GroupMember> gmToInsert = new List<GroupMember>();
        for (Id userIdToAdd : usersIdToAdd) {
            if (!usersAlreadyInGroup.contains(userIdToAdd)) {
                gmToInsert.add(new GroupMember(
                    GroupId = publicGroup.Id,
                    UserOrGroupId = userIdToAdd
                ));
            }
        }

        if (!gmToInsert.isEmpty()) {
            Database.insert(gmToInsert, false);  
        }
        if (!gmToRemove.isEmpty()) {
            Database.delete(gmToRemove, false);  
        }
    }
}