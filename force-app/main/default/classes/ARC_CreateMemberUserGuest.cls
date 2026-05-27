/*******************************************************************
* @ClassName          :   ARC_CreateMemberUserGuest
* @Description        :   Handles the logic to creates a person account and a portal users for Self-Enroll, also the creation of portal user from flow Update Contract on Eff Date and creates new portal user and reset password from Person Account 360 view.            
* @MethodName         :   CreateMemberUserAndAccount, createMemberPortalUser, checkAndCreateUser, createUserSObject,resetPasswordPersonAccount,createUserFromPersonAccount360
********************************************************************/
global without sharing class ARC_CreateMemberUserGuest implements vlocity_ins.VlocityOpenInterface{

    private static List<String> permissionSets = new List<String> {'UHSM IFP FlowPermissions Member','Permission Set for Payment Request (Base)','Permission Set for Payment Request (Chargent Orders)'};
    private static List<String> packageLicenseNamespaces = new List<String> {'vlocity_ins'};
        

    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        switch on methodName {
            when 'CreateMemberUserAndAccount' {
                CreateMemberUserAndAccount(inputMap, outputMap);
            }
            when 'resetPasswordPersonAccount' {
                resetPasswordPersonAccount(inputMap, outputMap, options);
            }
            when 'createUserFromPersonAccount360' {
                createUserFromPersonAccount360(inputMap, outputMap, options);
            }
            when 'resetUsernameAndPassword360' {
                resetUsernameAndPassword360(inputMap, outputMap, options);
            }
            when 'checkPortalUsernameWasSet'{
                checkPortalUsernameWasSet(inputMap, outputMap, options);
            }

        }
        return true;
     }
	 
    /*******************************************************************
    * @MethodName         :   CreateMemberUserAndAccount
    * @Description        :   Method used during Self-Enrollment that creates the person account, the portal user and return the URL to the Enrollment part of the process. 
    ********************************************************************/
    public static void CreateMemberUserAndAccount (Map<String,Object> inputMap, Map<String,Object> outputMap){
        String firstName = (String)inputMap.get('firstName');
        String lastName = (String)inputMap.get('lastName');
        String email = (String)inputMap.get('email');
        String street = (String) inputMap.get('street');
        String city = (String) inputMap.get('city');
        String state = (String) inputMap.get('state');
        String zipCode = (String) inputMap.get('zipCode');
        String password = (String) inputMap.get('password');
        String phone = (String) inputMap.get('phone');
        String birthdate = (String) inputMap.get('birthdate');
        String memberId = (String) inputMap.get('censusMemberId');
        String accountId = (String) inputMap.get('accountId');
        String censusId = (String) inputMap.get('censusId');
        String customUsername = (String) inputMap.get('username');
        String referral = (String) inputMap.get('referral');
        List<PermissionSetAssignment> permissionSetAsign = new List<PermissionSetAssignment>();
        List<UserPackageLicense> userPackageLicenses = new List<UserPackageLicense>();
        String personContactId = '';
        Account personAcc;
        //Create Account
        try{
            RecordType personAccRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'ARC_IFPPersonAccount' AND SobjectType = 'Account' LIMIT 1];

            Account acc = new Account();
            acc.RecordTypeId = personAccRT.Id;
            acc.FirstName = firstName;
            acc.LastName = lastName;
            acc.vlocity_ins__Email__c = email;
            acc.PersonEmail = email;
            acc.ARC_CensusMember__pc = memberId;
            acc.PersonBirthdate = Date.valueOf(birthdate);
            acc.Phone = phone;
            if (String.isNotBlank(referral)){
                acc.Referrer_Account__c = referral;
            }
            insert acc;
            
            personAcc = [SELECT Id, PersonContactId FROM Account WHERE Id =: acc.Id];
            vlocity_ins__GroupCensusMember__c memb = new vlocity_ins__GroupCensusMember__c();
            memb.Id = memberId;
            memb.vlocity_ins__ContactId__c = personAcc.PersonContactId;
            memb.vlocity_ins__Email__c = email;
            upsert memb;
            
            personContactId = personAcc.PersonContactId;
            outputMap.put('personAccId', personAcc.Id);
            outputMap.put('memb', memb.Id);
        }catch(Exception e){
            System.debug('Error on Account creation: ' + e.getMessage());
            outputMap.put('Error on Account creation: ', e.getMessage());
        }

        //Update Account on related Lead
        List< Lead_Source__c> leadSource= [SELECT Id, Lead__c  FROM Lead_Source__c WHERE Lead__r.Phone_Digits__c =:phone AND Lead__r.Email =:email AND Lead__c <> null LIMIT 1];
        if(leadSource.size()>0){
            Lead leadRecord = new Lead (Id = leadSource[0].Lead__c, Account__c =personAcc.Id);
            try{
                update leadRecord;
            }
            catch(Exception e){
                System.debug('Error on Lead Update: ' + e.getMessage());
                outputMap.put('Error on Lead Update: ', e.getMessage());
            }
        }

        //Get Guardian Account
        List<Account> guardianAccount = [SELECT Id,name, PersonContactId FROM Account WHERE ARC_GroupAccount__c =: accountId AND RecordType.DeveloperName ='ARC_Guardian' LIMIT 1];
        if(guardianAccount.size()>0){
            //Update Primary on Census
            List<vlocity_ins__GroupCensus__c> groupCensus = [SELECT Id FROM vlocity_ins__GroupCensus__c WHERE vlocity_ins__GroupId__c =:accountId LIMIT 1];
            vlocity_ins__GroupCensus__c censusToUpdate = new vlocity_ins__GroupCensus__c(Id= groupCensus[0].Id, ARC_PrimaryAccount__c= personAcc.Id);
            update censusToUpdate;
        }


        //Create user
        try{
            Profile profile = [SELECT Id FROM Profile WHERE Name = 'Member Community' LIMIT 1];
            List<PermissionSet> permissionSet = [SELECT Id FROM PermissionSet WHERE Label IN: permissionSets ];
            List<PackageLicense> packageLicenses = [SELECT Id, AllowedLicenses, NamespacePrefix FROM PackageLicense WHERE NamespacePrefix IN :packageLicenseNamespaces]; 

            String nickName = firstName.left(10) + lastName.left(20) + Integer.valueof((Math.random() * 10000));
            String alias = firstName.substring(0,1).toLowerCase() + lastName.substring(0,1).toLowerCase();
            Id primaryGuardianContactId = (guardianAccount.size()>0)? guardianAccount[0].PersonContactId:personContactId;


            User usr = new User(
                LastName = lastName,
                FirstName = firstName,
                Alias = alias,
                Email = email,
                Username = String.valueOf(personAcc.Id)+'@uhsm.com',
                Phone = phone,
                City = city,
                Street = street,
                State = state,
                PostalCode = zipCode,
                CommunityNickname = nickName,
                ContactId = primaryGuardianContactId,
                ProfileId = profile.Id,
                TimeZoneSidKey = 'America/New_York',
                LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'ISO-8859-1',
                LocaleSidKey = 'en_US',
                ARC_PortalUsername__c = customUsername != null? customUsername:String.valueOf(personAcc.Id)+'@uhsm.com'
            );  
            insert usr;

            System.setPassword(usr.Id, password);
            Pagereference pageRef = Site.login(usr.Username, password, '/s/ifp-enrollment?c__accountId='+accountId+'&c__censusId='+censusId);
            
            if (![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
                for (PackageLicense pl : packageLicenses) {
                    UserPackageLicense upl = new UserPackageLicense(PackageLicenseId = pl.Id, UserId = usr.Id);
                    userPackageLicenses.add(upl);
                }
                insert userPackageLicenses;
            }
            for (PermissionSet ps : permissionSet) {
                PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = usr.Id);
                permissionSetAsign.add(psa);
            }
            
            upsert permissionSetAsign;
            outputMap.put('memberUserId', usr.Id);
            outputMap.put('memberUsername', usr.Username);
            outputMap.put('redirectUrl', pageRef.getUrl());
            outputMap.put('ErrorDuplicateUsername', 'NoError');
        }catch(Exception e){
            System.debug('Error on User creation' + e.getMessage());
            if(e.getMessage().contains('DUPLICATE')) {
                outputMap.put('ErrorDuplicateUsername', 'Error');
            }
           
        }
    }

    /*******************************************************************
    * @MethodName         :   createMemberPortalUser
    * @Description        :   Invocable Methods that is called during the Update Contract on Effective date flow.
    ********************************************************************/
    @InvocableMethod(label='Validate & Create Portal User' description='Verifies the absence of an existing user and initiates the creation of the Member Portal user.' category='Member Portal')
    public static void createMemberPortalUser (List<Id> censusMemberIds){
        if(!censusMemberIds.IsEmpty()){
            //Call Queueable job to create Portal Users
            ARC_QueueableAssignPermissionSets qJob = new ARC_QueueableAssignPermissionSets('createUsers',censusMemberIds,null,null);
            System.enqueueJob(qJob,10);
        }
    }

    /*******************************************************************
    * @MethodName         :   createUserObject
    * @Description        :   Creates a user Object instance.
    ********************************************************************/
    public static User createUserSObject(Account PA, Id profileId) {
        User userObject = new User(
            FirstName = PA.FirstName,
            LastName = PA.LastName,
            Alias = String.valueOf(PA.FirstName.substring(0,1).toLowerCase() + PA.LastName.substring(0,1).toLowerCase()),
            Email = PA.vlocity_ins__Email__c,
            Username = String.valueOf(PA.Id)+'@uhsm.com',
            Phone = PA.Phone,
            City = PA.BillingCity,
            Street = PA.BillingStreet,
            State = PA.BillingState,
            PostalCode = PA.BillingPostalCode,
            CommunityNickname = String.valueOf(PA.FirstName + PA.LastName + Integer.valueof((Math.random() * 10000))),
            ContactId = PA.PersonContactId,
            ProfileId = profileId,
            TimeZoneSidKey = 'America/New_York',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LocaleSidKey = 'en_US',
            ARC_PortalUsername__c = String.valueOf(PA.Id)+'@uhsm.com'
        );
        return userObject;
    }


    /*******************************************************************
    * @MethodName         :   resetPasswordPersonAccount
    * @Description        :   Resets the password for a given Person Account and sends an email template to the corresponding user to log in.
    ********************************************************************/
    public static void resetPasswordPersonAccount(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        Map<String, Object> response = new Map<String, Object>();
        try {
            User user = [SELECT Id,Name,Username,Email,FirstName, Contact.Account.Census_Member__c FROM User WHERE Contact.AccountId =: (String)inputMap.get('personAccountId') AND IsPortalEnabled = true LIMIT 1];
            ARC_ExpirationLinksController.createExpirationLinkBulkIds(new List<Id>{user.Id}, System.today()+7);
            String encryptedUserId = ARC_EncryptionHelper.encryptText(user.Id);
            ARC_Emails.sendEmailConstructor(user.Email, 'WeShareForgotPassword', new Map<String, Object>{
                '{!User.FirstName}' => user.FirstName,
                '{!User.Username}' => user.Username,
                '{!ResetPasswordUrl}'=> 'https://'+ ARC_CommunityController.domainURLCommunity + '/members/s/reset-password?id='+encryptedUserId
            }, user.Contact?.Account?.Census_Member__c);
            response.put('message', 'Password reset successfully! New Password has been sent to: '+ user.Email);
            response.put('success', true);
        } catch (Exception e) {
            response.put('message', 'Error resetting user password: ' + e.getMessage());
            response.put('success', false);
        }
        outMap.put('resetPassword',response);
    }

    /*******************************************************************
    * @MethodName         :   createUserFromPersonAccount360
    * @Description        :   Handles the process of creating a new portal user from the Person Account 360 view. 
    ********************************************************************/
    public static void createUserFromPersonAccount360(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        Map<String, Object> response = new Map<String, Object>();
        List<PermissionSet> pSetList = [SELECT Id FROM PermissionSet WHERE Label IN: permissionSets ];
        try {
            Account PA =[
                SELECT Id,FirstName,LastName,PersonEmail,PersonContactId,BillingCity,BillingStreet,BillingState,BillingPostalCode,vlocity_ins__Email__c,Phone
                FROM Account
                WHERE Id =: (Id)inputMap.get('personAccountId')
                ];
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'Member Community' LIMIT 1].Id;
            User user = createUserSObject(PA, profileId);
            insert user;
            Id membId = [SELECT Id FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__ContactId__c = :PA.PersonContactId LIMIT 1].Id;

            List<Id> pSetIds = new List<Id>();
            for (PermissionSet pSet : pSetList) {
                pSetIds.add(pSet.Id);
            }

            //Assign permission sets and vlocity license to new users
            ARC_QueueableAssignPermissionSets qJob = new ARC_QueueableAssignPermissionSets('assignPermissionSetAndLicense',null,new List<Id>{user.Id},pSetIds);
            System.enqueueJob(qJob);

            response.put('message', 'User created successfully with Id: ' + user.Id);
            response.put('success', true);
            //Send an email to enter the password.
            ARC_ExpirationLinksController.createExpirationLinkBulkIds(new List<Id>{user.Id}, System.today()+7);
            String encryptedUserId = ARC_EncryptionHelper.encryptText(user.Id);
            ARC_Emails.sendEmailConstructor(user.Email, 'WeSharePortalWelcomeEmailInternal', new Map<String, Object>{
                '{!User.FirstName}' => user.FirstName,
                '{!Reset.Password.Url}'=> 'https://'+ ARC_CommunityController.domainURLCommunity + '/members/s/set-username-and-password?id='+encryptedUserId
            }, membId
            );
        } catch (Exception e) {
            response.put('message', 'Error creating user: ' + e.getMessage());
            response.put('success', false);
        }
        outMap.put('createUser', response);
    }

    public static void resetUsernameAndPassword360(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        Map<String, Object> response = new Map<String, Object>();
        try {
            User user = [SELECT Id,Name,Username,Email,FirstName, Contact.Account.Census_Member__c FROM User WHERE Contact.AccountId =: (String)inputMap.get('personAccountId') AND IsPortalEnabled = true LIMIT 1];
            ARC_ExpirationLinksController.createExpirationLinkBulkIds(new List<Id>{user.Id}, System.today()+7);
            String encryptedUserId = ARC_EncryptionHelper.encryptText(user.Id);
            ARC_Emails.sendEmailConstructor(user.Email, 'WeSharePortalWelcomeEmailInternal', new Map<String, Object>{
                '{!User.FirstName}' => user.FirstName,
                '{!Reset.Password.Url}'=> 'https://'+ ARC_CommunityController.domainURLCommunity + '/members/s/set-username-and-password?id='+encryptedUserId
            }, user.Contact?.Account?.Census_Member__c);
            response.put('message', 'Username and Password reset successfully!');
            response.put('success', true);

        } catch (Exception e) {
            response.put('message', 'Error resetting user password: ' + e.getMessage());
            response.put('success', false);
        }
        outMap.put('resetUsernameAndPassword', response);
    }

    public static void checkPortalUsernameWasSet(Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        String personAccountId = (String)inputMap.get('personAccountId');
        try {
            User user = [SELECT Id,ARC_PortalUsername__c FROM User WHERE Contact.AccountId =: personAccountId AND IsPortalEnabled = true LIMIT 1];
            Boolean usernameWasReset = user.ARC_PortalUsername__c.containsIgnoreCase(personAccountId) ? false : true;
            outMap.put('user', true);
            outMap.put('usernameWasReset', usernameWasReset);
        } catch (Exception e) {
            outMap.put('user', false);
        }

    }
}