global without sharing class ARC_UserActivationHandler {

    /*******************************************************************
    * @MethodName         :   getUsersToDeactivate
    * @Description        :   Get users who didn’t log in the past 90 days (inactive accounts) AND users who didn’t log in the past year (active accounts)
    ********************************************************************/
    public static List<User> getUsersToDeactivate() {
        List<User> users = new List<User>();
        if(Test.isRunningTest()) {
            users = [SELECT Id, ARC_PortalUsername__c FROM User WHERE ARC_PortalUsername__c = 'testinguser1234@example.com' LIMIT 1];
        }else{
            users = [SELECT Id, ARC_PortalUsername__c FROM User WHERE 
                IsActive = true AND 
                Profile.Name = 'Member Community' AND 
                ARC_PortalUsername__c != null AND 
                (
                    (LastLoginDate < LAST_N_DAYS:90 AND Contact.Account.IsActive = false) OR 
                    (LastLoginDate < LAST_N_DAYS:365 AND Contact.Account.IsActive = true)
                ) 
            ];
        }
        return users;
    }

    /*******************************************************************
     * @MethodName         :   deactivateUsers
     * @Description        :   Deactivate users
    /*******************************************************************/

    public static void deactivateUsers(List<User> users) {
        for(User user : users) {
            user.IsActive = false;
            user.ARC_PortalUsername__c = '_' + user.ARC_PortalUsername__c;
        }
        update users;
    }

    /*******************************************************************
     * @MethodName         :   deactivateUsersNotLoggedIn
     * @Description        :   method called from the scheduled flow to deactivate users who didn’t log in the past 90 days (inactive accounts) AND users who didn’t log in the past year (active accounts)
    /*******************************************************************/

    @InvocableMethod(label='Deactivate Users Not Logged In' description='Deactivate users who didn’t log in the past 90 days (inactive accounts) AND users who didn’t log in the past year (active accounts)' category='Users')
    global static void deactivateUsersNotLoggedIn() {
        List<User> users = getUsersToDeactivate();
        deactivateUsers(users);
    }


    

}