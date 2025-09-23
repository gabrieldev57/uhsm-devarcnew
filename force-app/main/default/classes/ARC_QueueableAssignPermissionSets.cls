/*******************************************************************
* @ClassName          :   ARC_QueueableAssignPermissionSets
* @Description        :   Queueable Apex that creates the portal users and assign both the vlocity license and the permission sets to these users. 
* @MethodName         :   execute,assignPermissionSetAndLicense
********************************************************************/
public without sharing class ARC_QueueableAssignPermissionSets implements Queueable{
    private String methodName;
    private List<Id> censusMemberIds;
    private List<Id> userIds;
    private List<Id> permissionSetIds;
    private static List<String> permissionSets = new List<String> {'UHSM IFP FlowPermissions Member','Permission Set for Payment Request (Base)','Permission Set for Payment Request (Chargent Orders)'};


    public ARC_QueueableAssignPermissionSets(String methodName,List<Id> censusMemberIds, List<Id> userIds, List<Id> permissionSetIds) {
        this.methodName = methodName;
        this.censusMemberIds = censusMemberIds;
        this.userIds = userIds;
        this.permissionSetIds = permissionSetIds;
    }

    /*******************************************************************
    * @MethodName         :   execute
    * @Description        :   createUsers calls the method to create the portal users from the Apex class ARC_CreateMemberUserGuest.checkAndCreateUser
                              assignPermissionSetAndLicense call the method of this class. 
    ********************************************************************/
    public void execute(QueueableContext context) {
        switch on this.methodName {
            when 'createUsers' {
                checkAndCreateUser(this.censusMemberIds);
            }
            when 'assignPermissionSetAndLicense' {
                assignPermissionSetAndLicense(this.userIds,this.permissionSetIds);
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   checkAndCreateUser
    * @Description        :   Verifies the abscense of the existing user and initiates the creation of the portal user if the member is over 18 years old. 
    ********************************************************************/
    public void checkAndCreateUser (List<Id> censusMemberIds) {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Member Community' LIMIT 1];
        Set<Id> personContactIds = new Set<Id>();
        Set<String> emails = new Set<String>();
        Map<Id, User> existingMembersMap = new Map<Id, User>();
        List<User> usersToInsert = new List<User>();
        Map<Id, Id> personAccToMember = new Map<Id, Id>();
        Map<Id, Id> userToMember = new Map<Id, Id>();

        //Get the Person Account related to the Census member Ids. 
        List<Account> personAccounts = [SELECT Id, Name, FirstName, LastName, vlocity_ins__Email__c, Phone, BillingPostalCode, BillingStreet, BillingState, BillingCity, PersonContactId, vlocity_ins__Age__pc, Census_Member__c FROM Account WHERE Census_Member__c IN :censusMemberIds]; 
        for(Account primaryMemberAcc: personAccounts){
            personContactIds.add(primaryMemberAcc.PersonContactId);
            emails.add(primaryMemberAcc.vlocity_ins__Email__c);
            personAccToMember.put(primaryMemberAcc.PersonContactId, primaryMemberAcc.Census_Member__c);
        }

        for (User existingMember : [SELECT Id, IsActive, IsPortalEnabled, ContactId FROM User WHERE ContactId IN :personContactIds AND ProfileId = :profile.Id AND Email IN :emails]) {
            existingMembersMap.put(existingMember.ContactId, existingMember);
        }

        for (Account personAccount : personAccounts) {
            User existingMemberPortal = existingMembersMap.get(personAccount.PersonContactId);
            if (existingMemberPortal == null && personAccount.vlocity_ins__Age__pc > 18) {
                // Create new Member Portal User
                usersToInsert.add(ARC_CreateMemberUserGuest.createUserSObject(personAccount,profile.Id));
            } 
            else System.debug('Portal User '+ personAccount.FirstName+' '+personAccount.LastName+' already Exists or Primary Member is a child');
        }
        if (!usersToInsert.isEmpty()) {
            List<PermissionSet> pSetList = [SELECT Id FROM PermissionSet WHERE Label IN: permissionSets ];
            try{
                List<Id> usersCreatedIds = new List<Id>();
                String errorMessage = 'The following errors were encountered: \n';

                Map<Integer,Id> indexContactIdMap = new Map<Integer,Id>();
                Integer counter = 0;

                for(User u: usersToInsert){
                    indexContactIdMap.put(counter,u.ContactId);
                    counter ++;
                }
                //Create the Portal Users
                Database.SaveResult[] srList = Database.insert(usersToInsert, false);
                counter = 0;
                Boolean errorsFound = false;

                //Iterate through the list of users and check if they were created or not
                for (Database.SaveResult sr : srList) {
                    if(sr.isSuccess()) {
                        usersCreatedIds.add(sr.getId());
                        counter++;
                    }
                    else {
                        errorsFound = true;
                        Id contactIdFailed = indexContactIdMap.containsKey(counter)? indexContactIdMap.get(counter):null;
                        for(Database.Error err : sr.getErrors()) {
                            errorMessage = errorMessage + 'ContactId: '+contactIdFailed +' - ErrorCode '+ err.getStatusCode() + ': ' + err.getMessage()+ ' ErrorFields:' + err.getFields() +'\n';
                        }
                        counter++;
                    }
                }
                
                //Send an email in case of errors
                if(errorsFound){
                    ARC_QueableSendFileBatch.sendEmailNotification(('Portal users inser failed : '+errorMessage), 'ERROR inserting users in QueueableAssignPermissionSet ', 'christian.fortunato@arcsona.com');
                }

                //Get the portal users created in this trasaction
                List<User> usersCreated = [SELECT Id,ContactId FROM User WHERE Id IN:usersCreatedIds];
                if(!usersCreated.isEmpty()){                    
                    for (User u : usersCreated) {
                        userToMember.put(u.Id, personAccToMember.get(u.ContactId));
                    }
    
                    List<Id> pSetIds = new List<Id>();
                    for (PermissionSet pSet : pSetList) pSetIds.add(pSet.Id);
    
                    //Send an email to enter the password.
                    ARC_ExpirationLinksController.createExpirationLinkBulk(usersCreated, System.today()+7);
    
                    Map<String,Object> response = ARC_Emails.sendResetUsernameAndPasswordEmailConstructor(usersCreated, 'WeSharePortalWelcomeEmailInternal', new Map<String, String>{
                        '{!User.FirstName}' => 'FirstName',
                        '{!User.Username}' => 'Username'
                    }, userToMember);
    
                    //Assign permission sets and vlocity license to new users
                    assignPermissionSetAndLicense(usersCreatedIds,pSetIds);
                }

            }
            catch(Exception e){
              ARC_QueableSendFileBatch.sendEmailNotification(('Error in checkAndCreateUsers: '+e.getMessage()), 'ERROR QueueableAssignPermissionSet', 'christian.fortunato@arcsona.com');
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   assignPermissionSetAndLicense
    * @Description        :   Method used during Self-Enrollment that creates the person account, the portal user and return the URL to the Enrollment part of the process. 
    ********************************************************************/
    @future(callout=true)
    private static void assignPermissionSetAndLicense(List<Id> userIds, List<Id> permissionSetIds) {
        List<PackageLicense> packageLicenses = [SELECT Id, AllowedLicenses, NamespacePrefix FROM PackageLicense WHERE NamespacePrefix = 'vlocity_ins']; 
        List<PermissionSetAssignment> permissionSetAssignmentsToInsert = new List<PermissionSetAssignment>();
        List<UserPackageLicense> userPackageLicensesToInsert = new List<UserPackageLicense>();

        if(!userIds.isEmpty()){
            Boolean isSandboxOrg = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            for( Id userId : userIds){
                // Permission Set Assignment
                for (Id pSetId : permissionSetIds) {
                    PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(PermissionSetId = pSetId, AssigneeId = userId);
                    permissionSetAssignmentsToInsert.add(permissionSetAssignment);
                }

                if (!packageLicenses.isEmpty() && !isSandboxOrg) {
                    // Vlocity_ins License assignment
                    for (PackageLicense pl : packageLicenses) {
                        UserPackageLicense upl = new UserPackageLicense(PackageLicenseId = pl.Id, UserId = userId);
                        userPackageLicensesToInsert.add(upl);
                    }
                }
            }
            try{
                insert userPackageLicensesToInsert;
                insert permissionSetAssignmentsToInsert;
            }catch (Exception e) {
                ARC_QueableSendFileBatch.sendEmailNotification(('Error in assignPermissionSetAndLicense: '+e.getMessage()), 'ERROR QueueableAssignPermissionSet', 'christian.fortunato@arcsona.com');
            }
        }
    }
}