/*******************************************************************
* @ClassName          : ARC_CommunityController
* @Description        : Handles the Community Portal logic. 
* @MethodName         : loginUser, loginWithPortalUsername, forgotUserNameEmail, forgotPasswordEmail, resetPasswordController, setUsernameAndPasswordController
                        setPortalPassword, setPortalPassword, validateUsername, getPortalUserById
********************************************************************/
public without sharing class ARC_CommunityController {

    public static String domainURLCommunity = [SELECT Domain FROM Domain WHERE HttpsOption ='CommunityAlt' LIMIT 1].Domain; 

    /*******************************************************************
    * @MethodName         :  getCommunityURL
    * @Description        :  Return the url of the community used for LWC.
    ********************************************************************/
    @AuraEnabled(cacheable=true)
    public static String getCommunityURL (){
        return [SELECT Domain FROM Domain WHERE HttpsOption ='CommunityAlt' LIMIT 1].Domain;
    }
    /*******************************************************************
    * @MethodName         :  loginUser
    * @Description        :  Return the url of the user logged in with the given username and password.
    ********************************************************************/
    @AuraEnabled 
    public static String loginUser (String userName, String password){
        Pagereference pageRef = Site.login(userName, password, '/s/');
        return pageRef?.getUrl();
    }

    /*******************************************************************
    * @MethodName         :  loginWithPortalUsername
    * @Description        :  Return the user record based on the given portal username and password.
    ********************************************************************/
    @AuraEnabled 
    public static Map<String,Object>  loginWithPortalUsername(String portalUserName, String password){
        Map<String, Object> response = new Map<String, Object>();
        //if portal username does not start with "_", add it
        //This is because the inactive users have the portal username starting with "_"
        String inactivePortalUsername = '_' + portalUsername;
        List<User> portalUser = [SELECT Id,Username, IsActive FROM User WHERE (ARC_PortalUsername__c =: portalUserName AND IsActive = true) OR (ARC_PortalUsername__c =: inactivePortalUsername AND IsActive = false)  LIMIT 1];
        if(portalUser.isEmpty()){
            return new Map<String,Object>{
                'success'=> false,
                'message'=>'Sorry, there is no User with the given username'
            };
        }else{
            if(!portalUser[0].IsActive){
                return new Map<String,Object>{
                    'success'=> false,
                    'inactiveUser'=> true,
                    'message'=>'INACTIVE_USER'
                };
            }
        }
        try{
            Pagereference pageRef = Site.login(portalUser[0].Username, password, '/s/');
            return new Map<String,Object>{'success'=> true,'loginURL'=>pageRef?.getUrl()};
        }
        catch(Exception e){
            return new Map<String,Object>{'success'=> false,'message'=>'Sorry something went wrong: '+e.getMessage()};
        }
    }

    /*******************************************************************
    * @MethodName         : forgotUserNameEmail
    * @Description        : Handles the logic of the forgot user custom component in the WeShare portal page. 
                            Send a link to the provided email with the related  portal username.
    ********************************************************************/
    @AuraEnabled 
    public static Map<String,Object> forgotUserNameEmail(String inputEmail){
        System.debug(inputEmail);
        List<User> portalUser = [SELECT Id,Name, ARC_PortalUsername__c,FirstName, Contact.Account.Census_Member__c FROM User WHERE Email =: inputEmail AND IsActive = TRUE ];
        if(portalUser.isEmpty()) return new Map<String,Object>{'success'=>false, 'message'=>'Sorry, there is no User with that email. Make sure the email is correct'};
        String resultUsernames = '';
        for (User user : portalUser) {
            resultUsernames += 'Username: '+user.ARC_PortalUsername__c+'<br>';
        }
        System.debug(resultUsernames);
        Map<String, Object> mergeFieldsMap = new Map<String, Object>();
        mergeFieldsMap.put('{!PortalUsernames}',resultUsernames);
        mergeFieldsMap.put('{!User.FirstName}',portalUser[0].FirstName);
        Map<String,Object> emailResponse = ARC_Emails.sendEmailConstructor(inputEmail, 'WeShareForgotUsernameEmail',mergeFieldsMap, portalUser[0].Contact?.Account?.Census_Member__c);
        System.debug(emailResponse);
        return emailResponse;
    }

    /*******************************************************************
    * @MethodName         : forgotPasswordEmail
    * @Description        : Handles the logic of the forgot password custom component in the WeShare portal page. 
                            Send a link to the custom reset password page to the provided email. 
    ********************************************************************/
    @AuraEnabled 
    public static Map<String,Object> forgotPasswordEmail(String portalUsername){
        //Get the user related to the provided portal username. 
        List<User> portalUser = [SELECT Id,Name,FirstName,Email, ARC_PortalUsername__c, Contact.Account.Census_Member__c  FROM User WHERE ARC_PortalUsername__c =: portalUsername AND IsActive = TRUE LIMIT 1];
        if(portalUser.isEmpty()) return new Map<String,Object>{'success'=>false, 'message'=>'Sorry, there is no User with that email. Make sure the email is correct'};
        String encryptedUserId = ARC_EncryptionHelper.encryptText(portalUser[0].Id);
		String resetPasswordUrl = 'https://'+ ARC_CommunityController.domainURLCommunity + '/members/s/reset-password?id='+encryptedUserId;
        Map<String, Object> mergeFieldsMap = new Map<String, Object>();
        mergeFieldsMap.put('{!User.FirstName}',portalUser[0].FirstName);  
        mergeFieldsMap.put('{!ResetPasswordUrl}',resetPasswordUrl);
        Map<String,Object> emailResponse = ARC_Emails.sendEmailConstructor(portalUser[0].Email, 'WeShareForgotPassword',mergeFieldsMap, portalUser[0].Contact?.Account?.Census_Member__c);
        //Create the custom setting record expiration link.
        ARC_ExpirationLinksController.createExpirationLinkBulk(portalUser,System.today() );
        return emailResponse;
    }

    /*******************************************************************
    * @MethodName         : resetPasswordController
    * @Description        : Handles the logic of the reset password custom component in the WeShare portal page. 
                            Reset the password of the user and in case of successful reset, returns the url with the logged in user. 
    ********************************************************************/
    @AuraEnabled
    public static Map<String,Object> resetPasswordController(Map<String,Object> formValues){
        // Declare Form Input values as variables
        Id userId = String.valueOf(formValues.get('userId'));
        String password = String.valueOf(formValues.get('password'));

        if(userId != null){
            // Update password
            Map<String, Object> response = setPortalPassword(userId,password);
            if((Boolean)response.get('success') != true){
                return response;
            }
            // Send email template
            User u = [SELECT Id,Username,Email,Name, Contact.Account.Census_Member__c FROM User WHERE Id =: userId];
            response = ARC_Emails.sendEmailConstructor(u.Email, 'WeSharePortalResetPasswordConfirmation', new Map<String,Object>{'{!User.Name}'=> u.Name}, u.Contact?.Account?.Census_Member__c);
            if((Boolean)response.get('success') == false) return response;
            else{
                //Close the Expiration Link 
                ARC_ExpirationLinksController.closeExpirationLink(u.Id);
                return new Map<String,Object>{'success'=>true,'message'=>'success', 'loginURL' => loginUser(u.Username, password)};
            }
        } else return new Map<String,Object>{'success'=> false,'message'=>'Missing user id'};
        
    }

    /*******************************************************************
    * @MethodName         : setUsernameAndPasswordController
    * @Description        : Sets the password and the username for a community user once the form is submitted
    ********************************************************************/
    @AuraEnabled
    public static Map<String,Object> setUsernameAndPasswordController(Map<String,Object> formValues){
        // Declare Form Input values as variables
        Id userId = String.valueOf(formValues.get('userId'));
        String username = String.valueOf(formValues.get('username'));
        String password = String.valueOf(formValues.get('password'));

        if(userId != null){
            // Update ARC_PortalUsername__c field
            Map<String,Object> response = setPortalUsername(userId,username);
            if ((Boolean)response.get('success') != true) {
                return response;
            }
            // Update password
            response = setPortalPassword(userId,password);
            if((Boolean)response.get('success') != true){
                return response;
            }
            // Send email template
            User u = [SELECT Id,Email,Name, Contact.Account.Census_Member__c FROM User WHERE Id =: userId];
            response = ARC_Emails.sendEmailConstructor(u.Email, 'WeSharePortalResetPortalUsernameAndPassword', new Map<String,Object>{'{!User.Name}'=> u.Name}, u.Contact?.Account?.Census_Member__c);
            if((Boolean)response.get('success') == false){
                return response;
            }
            ARC_ExpirationLinksController.closeExpirationLink(userId);
            response = loginWithPortalUsername(username, password);
            return response;
        } else {
            return new Map<String,Object>{'success'=> false,'message'=>'Missing user id'};
        }
    }

    /*******************************************************************
    * @MethodName         : setPortalPassword
    * @Description        : Updats the user password.
    ********************************************************************/
    public static Map<String,Object> setPortalPassword(Id userId, String password) {
        Map<String, Object> response = new Map<String, Object>();
        try{
            System.setPassword(userId, password);
        } catch (Exception e){
            response.put('success', false);
            response.put('message', e.getMessage());
            return response;
        }
        response.put('success', true);
        response.put('message', 'success');
        return response;
    }

    /*******************************************************************
    * @MethodName         : setPortalUsername
    * @Description        : Sets the new ARC_PortalUsername__c field for the user of the community experience..
    ********************************************************************/
    public static Map<String,Object> setPortalUsername(Id userId, String username){
        Map<String, Object> response = new Map<String, Object>();
        try{
            User u = [SELECT Id FROM User WHERE Id =: userId];
            u.ARC_PortalUsername__c = username;
            update u;
        } catch (DmlException e){
            response.put('success',false);
            response.put('message',e.getMessage());
            return response;
        }
        response.put('success',true);
        response.put('message','User update successful');
        return response;
    }

    /*******************************************************************
    * @MethodName         : validateUsername
    * @Description        : Validates that another user with the same ARC_PortalUsername__c does not exist already in the org.
    ********************************************************************/
    @AuraEnabled
    public static Map<String,Object> validateUsername(String username){
        Map<String, Object> response = new Map<String, Object>();
        //If the try catch catches a List has no row for assignment exception then it's good, if a user is found instead the response will be an error.
        try {
            User validateUsername = [SELECT Id FROM User WHERE ARC_PortalUsername__c =: username LIMIT 1];
            response.put('success', false);
            response.put('message', 'Username is already taken');
            return response;
        } catch (System.QueryException e) {
            System.debug(e);
            response.put('success', true);
            response.put('message', 'Username is available');
            return response;
        }
    }

    /*******************************************************************
    * @MethodName         : getPortalUserById
    * @Description        : Return a Map with the User record associated with the provided user id. 
    ********************************************************************/
    @AuraEnabled
    public static Map<String,Object>  getPortalUserById(String userId){
        try {
            List<User> portalUser = [SELECT Id,Username, Name,ARC_PortalUsername__c FROM User WHERE Id =: userId LIMIT 1];
            if(!portalUser.isEmpty()) return new Map<String,Object>{'User'=> portalUser[0],'success'=>true};
            else return new Map<String,Object>{'success'=> false,'message'=>'Sorry, we cannot find your portal user'};

        } catch (Exception e) {
            return new Map<String,Object>{'success'=> false,'message'=>'Sorry, something went wrong: '+e.getMessage()};
        }
    }

    /*******************************************************************
     * @MethodName         :   sendReactivationURL
     * @Description        :   Send an email with the reactivation url
    /*******************************************************************/
    @AuraEnabled
    public static void sendReactivationURL(String portalUsername) {
        //if portal username does not start with "_", add it
        //This is because the inactive users have the portal username starting with "_"
        String inactivePortalUsername = portalUsername.startsWith('_') ? portalUsername : '_' + portalUsername;
        User user = [
            SELECT Id, Email, Contact.Account.Census_Member__c, Name
            FROM User 
            WHERE ARC_PortalUsername__c = :inactivePortalUsername
        ];
        //Send an email with the reactivation url
        Date linkExpirationDate = System.today() + 7; 
        ARC_ExpirationLinksController.createExpirationLinkBulkIds(new List<Id>{user.Id}, linkExpirationDate);
        String encryptedUserId = ARC_EncryptionHelper.encryptText(user.Id);
        ARC_Emails.sendEmailConstructor(
            user.Email, 
            'ARC_ReactivateUser', 
            new Map<String, Object>{
                '{!ReactivateUser.url}' => 'https://'+ ARC_CommunityController.domainURLCommunity + '/members/s/re-activate-user?id='+encryptedUserId,
                '{!User.Name}' => user.Name
            }, 
            user.Contact?.Account.Census_Member__c
        );
    }
    /*******************************************************************
     * @MethodName         :   validateExpirationLink
     * @Description        :   Validate the expiration link
    /*******************************************************************/
    public static boolean validateExpirationLink(Id userId) {
        Boolean valid = false;
        List<ARC_ExpirationLink__c> validLinkRecord = [
            SELECT Id
                FROM ARC_ExpirationLink__c
                WHERE ARC_UserId__c = :userId
                AND ARC_ExpirationDate__c >= :Date.today()
                AND ARC_IsUsed__c = false
            LIMIT 1
        ];
        if(!validLinkRecord.isEmpty()) {
            valid = true;
        }
        return valid;
    }

    /*******************************************************************
     * @MethodName         :   activateUser
     * @Description        :   Activate the user  
    /*******************************************************************/
    public static void activateUser(Id userId) {
        User user = [
            SELECT Id, ARC_PortalUsername__c
            FROM User
            WHERE Id = :userId
        ];
        user.IsActive = true;
        //if username starts with "_", remove it
        if(user.ARC_PortalUsername__c.startsWith('_')) {
            user.ARC_PortalUsername__c = user.ARC_PortalUsername__c.substring(1); 
        }
        
        update user;
    }

    /*******************************************************************
     * @MethodName         :   reactivateEncryptedUser
     * @Description        :   Reactivate the user
    /*******************************************************************/
    @AuraEnabled
    public static Map<String,Object> reactivateEncryptedUser(String encryptedUserId) {
        try{
            if(validateExpirationLink(ARC_EncryptionHelper.decryptText(encryptedUserId))) {
                activateUser(ARC_EncryptionHelper.decryptText(encryptedUserId));
                //call the method to close the expiration link
                closeExpirationLink(ARC_EncryptionHelper.decryptText(encryptedUserId));
                return new Map<String,Object>{'success' => true, 'message' => 'User activated successfully'};
            }else{
                return new Map<String,Object>{'success' => false, 'message' => 'Expired URL'};
            }
        }catch(Exception e){
            return new Map<String,Object>{'success' => false, 'message' => 'Error activating the user: '+e.getMessage()};
        }
    }
    
    /*******************************************************************
     * @MethodName         :   closeExpirationLink
     * @Description        :   Close the expiration link
    /*******************************************************************/
    @future
    public static void closeExpirationLink(String userId) {
        ARC_ExpirationLinksController.closeExpirationLink(userId);
    }
    
}