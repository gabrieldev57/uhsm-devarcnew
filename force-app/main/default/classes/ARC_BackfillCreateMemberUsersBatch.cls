/*******************************************************************
* @ClassName          :   ARC_BackfillCreateMeberUserBatch
* @Description        :   Batch that creates the portal users for the specified accounts or for the applicable accounts.
* @MethodName         :   execute(SchedulableContext SC)
********************************************************************/
global class ARC_BackfillCreateMemberUsersBatch implements Database.Batchable<SObject> {
    
    public Set<Id> accountIds = new Set<Id>();
    public static OrgWideEmailAddress oMail = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Displayname = 'UHSM Member Services'];
    private static List<String> permissionSets = new List<String> {'UHSM IFP FlowPermissions Member','Permission Set for Payment Request (Base)','Permission Set for Payment Request (Chargent Orders)'};
    private static List<String> packageLicenseNamespaces = new List<String> {'vlocity_ins'};
    public static Organization organization = [SELECT Id, Name FROM Organization];
	public static String orgURL = 'https://'+ String.valueof(System.Url.getOrgDomainURL().getHost());
    public static  List<Document> orgImages = [
        SELECT
        Id,
        Name
        FROM Document
        WHERE Name = 'FacebookIcon'
        OR Name = 'TwitterIcon'
        OR Name = 'LinkedinIcon'
        OR Name = 'InstagramIcon'
        OR Name = 'WeShareLogo'
        OR Name = 'WeShareAsterisk'
        OR Name = 'Separator'
        OR Name = 'WeShareUHSM'
    ];

    global ARC_BackfillCreateMemberUsersBatch(Set<Id> accs){
        this.accountIds = accs;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        if(this.accountIds.size()>0){
            return Database.getQueryLocator([SELECT Id, Name,FirstName,LastName,Phone,vlocity_ins__Email__c,BillingCity,BillingStreet,BillingState,BillingPostalCode, PersonContactId,Census_Member__c FROM Account WHERE Id IN :accountIds]);
        }else{
            return null;
        }
        
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        List<User> newUsers = new List<User>();
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Member Community' LIMIT 1].Id;
        for (Account acc : scope) {
            User userObject = new User(
            FirstName = acc.FirstName,
            LastName = acc.LastName,
            Alias = String.valueOf(acc.FirstName.substring(0,1).toLowerCase() + acc.LastName.substring(0,1).toLowerCase()),
            Email = acc.vlocity_ins__Email__c,
            Username = String.valueOf(acc.Id)+'@uhsm.com',
            Phone = acc.Phone,
            City = acc.BillingCity,
            Street = acc.BillingStreet,
            State = acc.BillingState,
            PostalCode = acc.BillingPostalCode,
            CommunityNickname = String.valueOf(acc.FirstName + acc.LastName + Integer.valueof((Math.random() * 10000))),
            ContactId = acc.PersonContactId,
            ProfileId = profileId,
            TimeZoneSidKey = 'America/New_York',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LocaleSidKey = 'en_US',
            ARC_PortalUsername__c = String.valueOf(acc.Id)+'@uhsm.com');
            newUsers.add(userObject);
        }
        try{
            insert newUsers;
            List<PermissionSet> permissionSet = [SELECT Id FROM PermissionSet WHERE Label IN: permissionSets ];
            List<PackageLicense> packageLicenses = [SELECT Id, AllowedLicenses, NamespacePrefix FROM PackageLicense WHERE NamespacePrefix IN :packageLicenseNamespaces]; 

            List<Id> userIds = new List<Id>();
                for (User user : newUsers) {
                    userIds.add(user.Id);
                }

                List<Id> pSetIds = new List<Id>();
                for (PermissionSet pSet : permissionSet) {
                    pSetIds.add(pSet.Id);
                }
            //Assign permission sets and vlocity license to new users
            ARC_QueueableAssignPermissionSets qJob = new ARC_QueueableAssignPermissionSets('assignPermissionSetAndLicense',null,userIds,pSetIds);
            System.enqueueJob(qJob);
            //Send Welcome Email
            sendEmailConstructor('WeSharePortalWelcomeEmailInternal',newUsers);    
        }catch(Exception e){
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_BackfillCreateMemberUsersBatch: '+e.getMessage()), 'ERROR ARC_BackfillCreateMemberUsersBatch', apexErrorEmail);
        }

    }

    public static Map<String,Object> sendEmailConstructor(String templateDeveloperName, List<User> newUsers){
        Map<String,Object> response = new Map<String, Object>();
        List<EmailTemplate> emailTemp = [SELECT Subject,HtmlValue FROM EmailTemplate WHERE DeveloperName =: templateDeveloperName LIMIT 1];
        List<User> newUsersToSendEmail = [SELECT Id,Email,FirstName,Contact.Account.Census_Member__c, Contact.AccountId FROM User WHERE Id IN :newUsers];

        if(emailTemp.isEmpty()) {
            response.put('success', false);
            response.put('message', 'Email Template was not Found');
            return response;
        }
        List<Messaging.SingleEmailMessage> emailsList = new List<Messaging.SingleEmailMessage>();
        List<EmailMessage> emailMessageList = new List<EmailMessage>();
        List<Id> usersIds = new List<Id>();        
        for(User us: newUsersToSendEmail){
            usersIds.add(us.Id);
            String encryptedUserId = ARC_EncryptionHelper.encryptText(us.Id);
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setOrgWideEmailAddressId(oMail.Id);
            message.setSubject(emailTemp[0].Subject);
            message.setBccSender(false);
            message.setUseSignature(false); 
            message.setToAddresses(new List<String>{us.Email});
            Map<String, Object> mergeFieldsMap = new Map<String, Object>{'{!User.FirstName}' => us.FirstName, '{!Reset.Password.Url}'=> 'https://'+ ARC_CommunityController.domainURLCommunity + '/members/s/set-username-and-password?id='+encryptedUserId};
            addSignatureImagesToMap(mergeFieldsMap);
            message.setHtmlBody(replaceEmailTemplateFields(mergeFieldsMap,emailTemp[0].HtmlValue));
            //Add email to email to send
            emailsList.add(message);
            //Generate EmailMessage
            EmailMessage em = generateEmailMessages(message, us.Contact.AccountId);
            emailMessageList.add(em);
        }
        ARC_ExpirationLinksController.createExpirationLinkBulkIds(usersIds, System.today()+7);
        
        try{
            List<Messaging.SendEmailResult> resultList = Messaging.sendEmail(emailsList);

            insert emailMessageList;
            for(Messaging.SendEmailResult result: resultList){
                if(result.isSuccess()){
                    response.put('success',true);
                    response.put('message','Email sent!');
                } else {
                    throw new EmailException();
                }
            }
            
        }
        catch(EmailException e){
            response.put('success',false);
            response.put('message','Email not sent! '+ e.getMessage());
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_BackfillCreateMemberUsersBatch: '+e.getMessage()), 'ERROR ARC_BackfillCreateMemberUsersBatch', apexErrorEmail);
        }
        return response;
    }
   
    public static EmailMessage generateEmailMessages(Messaging.SingleEmailMessage email, Id memberId) {
        
        EmailMessage em = new EmailMessage();
        em.ARC_PersonAccount__c = memberId;
        em.BccAddress = email.getBccAddresses() != null ? String.join(email.getBccAddresses(), '; ') : null;
        em.CcAddress = email.getCcAddresses() != null ? String.join(email.getCcAddresses(), '; ') : null;
        em.FromAddress = email.getOrgWideEmailAddressId() != null ? oMail.Address : UserInfo.getUserEmail();
        em.HtmlBody = email.getHtmlBody();
        em.Subject = email.getSubject();
        em.ToAddress = email.getToAddresses() != null ? String.join(email.getToAddresses(), '; ') : null;
        em.MessageDate = Datetime.now();
        em.Status = '3';
        return em;
    }
    
    public static String replaceEmailTemplateFields(Map<String, Object> mergeFieldsMap, String htmlEmailBody) {
        if (!mergeFieldsMap.isEmpty() && String.isNotBlank(htmlEmailBody)) {
            for (String key : mergeFieldsMap.keySet()) {
                String entryValue = mergeFieldsMap.get(key) != null ? String.valueOf(mergeFieldsMap.get(key)) : '';
                htmlEmailBody = htmlEmailBody.replace(key, entryValue);
            }
        }
        return htmlEmailBody;
    }

    public static void addSignatureImagesToMap(Map<String, Object> mergeFieldMap){
        if(orgImages.size()>0){
            for (Document img : orgImages) {
                mergeFieldMap.put('{Images.'+img.Name+'}',orgURL+'/servlet/servlet.ImageServer?id='+ img.Id + '&oid=' + organization?.Id);
            }
    
            for(String key: mergeFieldMap.keySet()){
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
    }
}