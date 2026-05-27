public with sharing class ARC_UserPermissionService {
    private static List<String> packageLicenseNamespaces = new List<String> {'vlocity_ins'};
    
   @TestVisible
   public static Boolean bypassForTest = false;
   
   //async
   @future
   public static void setPermissionSetAndLicenseToPortalUser(List<Id> userIds) {
       
       if (bypassForTest) return; 

       // Query Users + Profile
       Map<Id, User> users = new Map<Id, User>(
           [SELECT Id, ProfileId FROM User WHERE Id IN :userIds]
       );
       Set<Id> profileIds = new Set<Id>();
       for (User u : users.values()) {
            if (u.ProfileId != null) {
                profileIds.add(u.ProfileId);
            }
       }
       
       Map<Id, Profile> profileMap = new Map<Id, Profile>(
           [SELECT Id, Name FROM Profile WHERE Id IN :profileIds]
       );
       
       // Package Licenses
       List<UserPackageLicense> userPackageLicenses = new List<UserPackageLicense>();
       List<PackageLicense> packageLicenses = [
           SELECT Id, AllowedLicenses, NamespacePrefix 
           FROM PackageLicense 
           WHERE NamespacePrefix IN :packageLicenseNamespaces
       ];
       
       if (![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
           for (User u : users.values()) {
               for (PackageLicense pl : packageLicenses) {
                   userPackageLicenses.add(new UserPackageLicense(
                       PackageLicenseId = pl.Id, 
                       UserId = u.Id
                   ));
               }
           }
           if (!userPackageLicenses.isEmpty()) {
                List<Database.SaveResult> results = Database.insert(userPackageLicenses, false);
                for (Database.SaveResult sr : results) {
                    if (!sr.isSuccess()) {
                        for (Database.Error err : sr.getErrors()) {
                            if (err.getStatusCode() != StatusCode.DUPLICATE_VALUE) {
                                throw new DmlException(err.getMessage());
                            }
                        }
                    }
                }
            }
       }
       
       // Permission Sets
       Map<String, Id> permissionSetMap = new Map<String, Id>();
       for (PermissionSet ps : [
           SELECT Id, Name 
           FROM PermissionSet 
           WHERE Name IN ('Employer_Admin_Permissions','Employer_Viewer_Permissions')
       ]) {
           permissionSetMap.put(ps.Name, ps.Id);
       }
       
       // Verify assignments
       List<PermissionSetAssignment> psaRetrieved = [
           SELECT PermissionSetId, AssigneeId 
           FROM PermissionSetAssignment 
           WHERE AssigneeId IN :userIds 
             AND PermissionSetId IN :permissionSetMap.values()
       ];
       
       Set<Id> alreadyAdmin = new Set<Id>();
       Set<Id> alreadyViewer = new Set<Id>();
       
       for (PermissionSetAssignment ps : psaRetrieved) {
           if (ps.PermissionSetId == permissionSetMap.get('Employer_Admin_Permissions')) {
               alreadyAdmin.add(ps.AssigneeId);
           } else if (ps.PermissionSetId == permissionSetMap.get('Employer_Viewer_Permissions')) {
               alreadyViewer.add(ps.AssigneeId);
           }
       }
       
       // Prepare new assignments
       List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
       
       for (User u : users.values()) {
           Profile p = profileMap.get(u.ProfileId);
           if (p != null && p.Name == 'Employer Admin' && !alreadyAdmin.contains(u.Id)) {
               psaList.add(new PermissionSetAssignment(
                   PermissionSetId = permissionSetMap.get('Employer_Admin_Permissions'),
                   AssigneeId = u.Id
               ));
           }
           if (p != null && p.Name == 'Employer Viewer' && !alreadyViewer.contains(u.Id)) {
               psaList.add(new PermissionSetAssignment(
                   PermissionSetId = permissionSetMap.get('Employer_Viewer_Permissions'),
                   AssigneeId = u.Id
               ));
           }
       }
       
       if (!psaList.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(psaList, false);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        if (err.getStatusCode() != StatusCode.DUPLICATE_VALUE) {
                            throw new DmlException(err.getMessage());
                        }
                    }
                }
            }
        }
   }

   @future
   public static void createSharingForRelatedAccount(List<Id> userIds) {
    if (bypassForTest) return;
        Set<Id> accountIds = new Set<Id>();
       List<User> newUsers = [SELECT Id, AccountId FROM User WHERE Id IN :userIds];
       for (User u : newUsers) {
           if (u.AccountId != null) {
               accountIds.add(u.AccountId);
           }
       }
       
       Map<Id,Account> accountMap = new Map<Id,Account>([SELECT Id,OwnerId FROM Account WHERE Id IN :accountIds]);

       if (!accountIds.isEmpty()) {
           List<AccountShare> accountShares = new List<AccountShare>();
           for (User u : newUsers) {
               if (u.AccountId != null) {
                   AccountShare accShare = new AccountShare();
                   accShare.AccountId = u.AccountId;
                   accShare.UserOrGroupId = u.Id;
                   accShare.AccountAccessLevel = 'Edit';
                   accShare.OpportunityAccessLevel = 'Edit';
                   accShare.RowCause = Schema.AccountShare.RowCause.Manual;
                   accountShares.add(accShare);
               }
           }
           if (!accountShares.isEmpty()) {
               insert accountShares;
           }
       }
       if (!accountMap.isEmpty()) {
           // Create user share for the account owner
           List<UserShare> userShares = new List<UserShare>();
           for(User u : newUsers) {
               if(u.AccountId != null && accountMap.containsKey(u.AccountId)) {
                   UserShare userShare = new UserShare();
                   userShare.UserOrGroupId = u.Id;
                   userShare.UserId = accountMap.get(u.AccountId).OwnerId;
                   userShare.UserAccessLevel = 'Read';
                   userShare.RowCause = Schema.UserShare.RowCause.Manual;
                   userShares.add(userShare);
               }
           }
           if(!userShares.isEmpty()) {
               insert userShares;
           }
       }
   }
}