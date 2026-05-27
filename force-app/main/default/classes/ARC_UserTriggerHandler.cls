public with sharing class ARC_UserTriggerHandler {
    private static List<String> packageLicenseNamespaces = new List<String> {'vlocity_ins'};
    
    public static void setPermissionSetAndLicenseToPortalUser(List<User> userList, Map<Id, User> oldMap, Boolean isInsert) {
        List<Id> userIdList = new List<Id>();
        for(User u:userList){
            userIdList.add(u.Id);
        }
        ARC_UserPermissionService.setPermissionSetAndLicenseToPortalUser(userIdList);
    }

    public static void createSharingForRelatedAccount(List<User> newUsers) {
        if (ARC_UserPermissionService.bypassForTest) return;

        Set<Id> accountIds = new Set<Id>();
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