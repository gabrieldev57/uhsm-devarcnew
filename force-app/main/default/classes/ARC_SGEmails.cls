global without sharing class ARC_SGEmails implements vlocity_ins.VlocityOpenInterface2 {

    public static Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        Boolean result = true;
        try {
            if (methodName == 'sendMemberIdCardPortal') {
                result = sendMemberIdCardPortal(inputMap, outMap, options);
            } else {
                outMap.put('error', 'Method not found: ' + methodName);
                result = false;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception in invokeMethod: ' + e.getMessage() + '\n' + e.getStackTraceString());
            outMap.put('error', e.getMessage());
            result = false;
        }
        return result;
    }

    public class InputVar {
        @InvocableVariable(label='employerName' required=true)
        public String employerName;

        @InvocableVariable(label='employerEmail' required=true)
        public String employerEmail;
        
        @InvocableVariable(label='listChanges' required=true)
        public String listChanges;    

        @InvocableVariable(label='hasAccManager' required=true)
        public Boolean hasAccManager;
        
        @InvocableVariable(label='accManagerName' required=false)
        public String accManagerName;

        @InvocableVariable(label='accManagerEmail' required=false)
        public String accManagerEmail;
        
        @InvocableVariable(label='accManagerPhone' required=false)
        public String accManagerPhone;  
    }

    public static OrgWideEmailAddress oMail = [
		SELECT Id, Address, DisplayName
		FROM OrgWideEmailAddress
		WHERE Displayname = 'No Reply'
	];

    public static OrgWideEmailAddress getOrgWideEmail() {
        List<OrgWideEmailAddress> emails = [
            SELECT Id, Address, DisplayName
            FROM OrgWideEmailAddress
            WHERE Displayname = 'No Reply'
            LIMIT 1
        ];
        return emails.isEmpty() ? null : emails[0];
    }

    /*******************************************************************
     * @MethodName         :   sendEmailToEmployer
     * @Description        :   Invocable Methods that sends a confirmation email when an internal agent makes changes.
     ********************************************************************/
    @InvocableMethod(
        label='send Email To Employer'
        description='sends a confirmation email when an internal agent makes changes'
        category='Member Portal'
    )
    public static void sendEmailToEmployer(List<InputVar> inputMap) {
        if (inputMap == null || inputMap.isEmpty()) return;

        EmailTemplate template = [
            SELECT Id, Subject, HtmlValue
            FROM EmailTemplate
            WHERE DeveloperName = 'ARC_SGErAdminNotifAccChanges'
            LIMIT 1
        ];

        OrgWideEmailAddress senderEmail = getOrgWideEmail();
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (InputVar input : inputMap) {
            String accManagerData = null;

            if (input.hasAccManager == true) {
                accManagerData = 'If you think this was done in error, please reach out to ';

                if (input.accManagerName != null) {
                    accManagerData += input.accManagerName;
                }
                if (input.accManagerEmail != null) {
                    accManagerData += ' at ' + input.accManagerEmail;
                }
                if (input.accManagerPhone != null) {
                    accManagerData += ' or ' + input.accManagerPhone;
                }
            }
            
            Map<String, Object> mergeFieldsMap = new Map<String, Object>{
                '{!EmployerName}' => input.employerName,
                '{!ListChanges}' => input.listChanges,
                '{!AccManagerData}' => accManagerData != null ? accManagerData : null
            };
            
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            if (senderEmail != null) {
                message.setOrgWideEmailAddressId(senderEmail.Id);
            }
            message.setBccSender(false);
            message.setUseSignature(false);
            message.setToAddresses(new List<String>{ input.employerEmail });
            message.setSubject(template.Subject);
            
            message.setHtmlBody(
                replaceEmailTemplateFields(mergeFieldsMap, template.HtmlValue)
            );

            emailsToSend.add(message);
        }

        try {
            if (!emailsToSend.isEmpty()) {
                Messaging.sendEmail(emailsToSend);
            }
        } catch (Exception e) {
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_SGEmails sendEmailToEmployer: '+e.getMessage()), 'ERROR ARC_SGEmails sendEmailToEmployer', apexErrorEmail);
        }
    }


    public static String replaceEmailTemplateFields(Map<String, Object> mergeFieldsMap, String htmlEmailBody) {
        if (!mergeFieldsMap.isEmpty() && String.isNotBlank(htmlEmailBody)) {
            for (String key : mergeFieldsMap.keySet()) {
                String entryValue = mergeFieldsMap.get(key) != null
                    ? String.valueOf(mergeFieldsMap.get(key))
                    : '';
                htmlEmailBody = htmlEmailBody.replace(key, entryValue);
            }
        }
        return htmlEmailBody;
    }

    /*******************************************************************
     * @MethodName         :   sendEmailForCompanyContactChanges
     * @Description        :   Method that sends a confirmation email when an internal agent makes changes via LWC.
     * @param email        :   Primary Contact Email
     * @param primaryContactName : Primary Contact Name
     * @param changes      :   String with changes
     * @param primaryContactAcrId:   String with account Id
     ********************************************************************/
    @AuraEnabled
    public static void sendEmailForCompanyContactChanges(String email, String primaryContactName, String changes, String primaryContactAcrId) {
        if (String.isBlank(email) || String.isBlank(changes)) return;

        EmailTemplate template = [
            SELECT Id, Subject, HtmlValue
            FROM EmailTemplate
            WHERE DeveloperName = 'ARC_SGErAdminNotifAccChanges'
            LIMIT 1
        ];

        AccountContactRelation acr = [SELECT Id, Account.ARC_AccountManager__c, Account.ARC_AccountManager__r.FirstName, Account.ARC_AccountManager__r.LastName, Account.ARC_AccountManager__r.email, Account.ARC_AccountManager__r.phone FROM AccountContactRelation WHERE Id =: primaryContactAcrId LIMIT 1];

        String accManagerData = null;

        if (acr?.Account?.ARC_AccountManager__c != null) {
            accManagerData = 'If you think this was done in error, please reach out to ';

            if (acr?.Account.ARC_AccountManager__r?.FirstName != null && acr?.Account.ARC_AccountManager__r.LastName != null) {
                accManagerData += acr?.Account.ARC_AccountManager__r?.FirstName + ' ' + acr?.Account.ARC_AccountManager__r.LastName;
            }
            if (acr?.Account?.ARC_AccountManager__r.email != null) {
                accManagerData += ' at ' + acr?.Account?.ARC_AccountManager__r.email;
            }
            if (acr?.Account?.ARC_AccountManager__r?.phone != null) {
                accManagerData += ' or ' + acr?.Account?.ARC_AccountManager__r?.phone;
            }
        }
            
        Map<String, Object> mergeFieldsMap = new Map<String, Object>{
            '{!EmployerName}' => primaryContactName,
            '{!ListChanges}' => changes,
            '{!AccManagerData}' => accManagerData != null ? accManagerData : null
        }; 

        OrgWideEmailAddress senderEmail = getOrgWideEmail();
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        
        if (senderEmail != null) {
            message.setOrgWideEmailAddressId(senderEmail.Id);
        }
        message.setBccSender(false);
        message.setUseSignature(false);
        message.setToAddresses(new List<String>{ email });
        
        message.setSubject('Company Contact Changes'); 
        
        message.setHtmlBody(
            replaceEmailTemplateFields(mergeFieldsMap, template.HtmlValue)
        );

        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ message });
        } catch (Exception e) {
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_SGEmails sendEmailForCompanyContactChanges: '+e.getMessage()), 'ERROR ARC_SGEmails sendEmailForCompanyContactChanges', apexErrorEmail);
        }
    }
    //send email to case owner on Sales Process
    public static void sendEmails(List<Case> cases) {
        if (cases.isEmpty()) return;

        try {
            EmailTemplate tmpl = [
                SELECT Id, HtmlValue, Body
                FROM EmailTemplate
                WHERE DeveloperName = 'ARC_CensusFormEmail'
                LIMIT 1
            ];

            OrgWideEmailAddress senderEmail = getOrgWideEmail();
            
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

            for (Case c : cases) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                Map<String, Object> mergeFields = new Map<String, Object>{
                    '{!Case.CaseNumber}'   => c.CaseNumber,
                    '{!Case.Account}' => c.Account.Name
                };
                
                if (senderEmail != null) {
                    mail.setOrgWideEmailAddressId(senderEmail.Id);
                }
                
                mail.setTargetObjectId(c.OwnerId);
                mail.setBccSender(false);
                mail.setUseSignature(false);
                mail.setSubject('Census Submitted – Ready for Review');
                mail.setHtmlBody(
                    replaceEmailTemplateFields( mergeFields, tmpl.HtmlValue)
                );
                mail.setSaveAsActivity(false);
                
                emails.add(mail);
            }

            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
                System.debug('sent emails: ' + emails.size());
            }
            
        } catch (Exception e) {
            System.debug('Error sending emails: ' + e.getMessage());
        }
    }

    /****Send email MemberIdCard - Portal (Integration Procedure compatible) ****/
    /**
     * @MethodName  : sendMemberIdCardPortal
     * @Description : Sends a Member ID Card email from an Integration Procedure context.
     *                Mirrors ARC_EmailMemberCardPortal.sendMemberIdCardCommunity.
     * Input keys   : email, aditionalEmail, senderFirstName,
     *                WeShare_Member_ID_Card_Email, Legacy_Member_ID_Card_Email
     * Output keys  : success (Boolean), message (String)
     */
    public static Boolean sendMemberIdCardPortal(
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        System.debug('sendMemberIdCardPortal inputMap => ' + JSON.serializePretty(inputMap));

        Map<String, Object> optionsMap = (Map<String, Object>) inputMap.get('options');
        String memberEmail      = optionsMap != null
            ? (String) optionsMap.get('primaryContactEmail')
            : null;
        String aditionalEmail   = (String) inputMap.get('aditionalEmail');
        String senderFirstName  = (String) inputMap.get('senderFirstName');
        String weShareAttachId  = (String) inputMap.get('WeShare_Member_ID_Card_Email');
        String legacyAttachId   = (String) inputMap.get('Legacy_Member_ID_Card_Email');

        String userProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Profile.Name;
        Boolean isEmployerProfile = userProfileName.equalsIgnoreCase('Employer Admin') ||
                                    userProfileName.equalsIgnoreCase('Employer Viewer');

        if (isEmployerProfile && String.isBlank(memberEmail)) {
            outMap.put('error', 'Email is required.');
            return false;
        }

        EmailTemplate template = [
            SELECT Id, Subject, HtmlValue
            FROM EmailTemplate
            WHERE DeveloperName = 'UHSM_WESHARE_MEMBER_ID_CARD'
            LIMIT 1
        ];

        Map<String, Object> mergeFieldsMap = new Map<String, Object>{
            '{!Contact.FirstName}' => senderFirstName
        };

        List<String> toAddresses = new List<String>();
        if (isEmployerProfile) {
            if (String.isNotBlank(memberEmail)) {
                toAddresses.add(memberEmail);
            }
            if (String.isNotBlank(aditionalEmail)) {
                toAddresses.add(aditionalEmail);
            }
        } else {
            // Internal agent: send to members selected in STEP_WeShareMemberId:EB_SelectEmails
            Map<String,Object> stepMap = inputMap.get('STEP_WeShareMemberId') instanceof Map<String,Object>
                ? (Map<String,Object>) inputMap.get('STEP_WeShareMemberId') : null;
            Map<String,Object> ebMap = stepMap != null && stepMap.get('EB_SelectEmails') instanceof Map<String,Object>
                ? (Map<String,Object>) stepMap.get('EB_SelectEmails') : null;
            if (ebMap != null) {
                if (ebMap.get('isSelected') == true && String.isNotBlank((String) ebMap.get('Email'))) {
                        toAddresses.add((String) ebMap.get('Email'));
                    }
            }
            // Fall back to additionalEmail when no members are selected
            if (String.isNotBlank(aditionalEmail)) {
                toAddresses.add(aditionalEmail);
            }
            if (toAddresses.isEmpty()) {
                outMap.put('error', 'Please select at least one member or enter an email address in the Other field.');
                return false;
            }
        }

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setOrgWideEmailAddressId(oMail.Id);
        message.setBccSender(false);
        message.setUseSignature(false);
        message.setToAddresses(toAddresses);
        message.setSubject(template.Subject);
        message.setHtmlBody(
            replaceEmailTemplateFields(mergeFieldsMap, template.HtmlValue)
        );

        String attachmentId = '';
        if (String.isNotBlank(weShareAttachId)) {
            attachmentId = weShareAttachId;
        } else if (String.isNotBlank(legacyAttachId)) {
            attachmentId = legacyAttachId;
        }

        if (String.isBlank(attachmentId)) {
            outMap.put('error', 'No PDF attachment was generated.');
            return false;
        }

        message.setEntityAttachments(new List<String>{ attachmentId });

        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ message });
            outMap.put('success', true);
            outMap.put('message', 'Member ID Card email sent successfully.');
            return true;
        } catch (Exception e) {
            System.debug('Error sending Member ID Card email: ' + e.getMessage());
            outMap.put('error', e.getMessage());

            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(
                'Error in ARC_SGEmails sendMemberIdCardPortal: ' + e.getMessage(),
                'ERROR ARC_SGEmails sendMemberIdCardPortal',
                apexErrorEmail
            );
            return false;
        }
    }

    /****Send email MemberIdCard****/
    public static void sendMemberIdCardCommunity(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
        System.debug('Start method');
		List<EmailMessage> emList = new List<EmailMessage>();
		// String additionalEmail = (String) inputMap.get('additionalEmail');
		String memberId = (String) inputMap.get('ContextId');
		String contactId = (String) inputMap.get('contactId');
		Account acc;
		if (!String.isBlank(contactId)) {
			acc = [
				SELECT Id, Census_Member__c
				FROM Account
				WHERE PersonContactId = :contactId
				LIMIT 1
			];
			memberId = String.valueof(acc.Census_Member__c);
		} else if (!String.isBlank(memberId)) {
			acc = [
				SELECT Id 
				FROM Account
				WHERE Id = :memberId
				LIMIT 1
			];
		}
		String memberEmail = (String) inputMap.get('email');
		// String userEmail = (String) inputMap.get('userEmail');
		String senderFirstName = (String) inputMap.get('senderFirstName');
		EmailTemplate template = [
			SELECT Id, Subject, HtmlValue
			FROM EmailTemplate
			WHERE DeveloperName = 'UHSM_WESHARE_MEMBER_ID_CARD'
		];
		Map<String, Object> mergeFieldsMap = new Map<String, Object>{
			'{!Contact.FirstName}' => senderFirstName
		};
		// addSignatureImagesToMap(mergeFieldsMap);
		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		message.setOrgWideEmailAddressId(oMail.Id);
		message.setBccSender(false);
		message.setUseSignature(false);
		message.setToAddresses(new List<String>{ memberEmail });
		// message.setCcAddresses(new List<String>{ userEmail });
		message.setSubject(template.Subject);
		message.setWhatId(acc.Id);
		message.setHtmlBody(
			ARC_Emails.replaceEmailTemplateFields(
				mergeFieldsMap,
				template.HtmlValue
			)
		);
        System.debug('Member ID Card email sent successfully. ' + message);
		Boolean isWeSharePlan = Test.isRunningTest()
			? false
			: (Boolean) inputMap.get('weSharePlan');
		Boolean isAccessPlan = Test.isRunningTest()
			? false
			: (Boolean) inputMap.get('accessPlan');
		String attachmentId = '';
		if (isAccessPlan) {
			attachmentId = Test.isRunningTest()
				? ''
				: (String) inputMap.get('Access_Member_Card');
		} else if (isWeSharePlan) {
			attachmentId = Test.isRunningTest()
				? ''
				: (String) inputMap.get('WeShare_Member_Card');
		} else {
			attachmentId = Test.isRunningTest()
				? ''
				: (String) inputMap.get('UHSM_Member_Card');
		}
		if (!Test.isRunningTest())
			message.setEntityAttachments(new List<String>{ attachmentId });
        System.debug('Member ID Card email sent successfully. ' + message);
		/* Send Email */
		try {
            System.debug('Member ID Card email sent successfully. ' + message);
			Messaging.sendEmail(
				new List<Messaging.SingleEmailMessage>{ message }
			);
            // ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
            //     message.toAddresses,
            //     message.subject,
            //     null,
            //     Datetime.now()
            // );
            // messageQueable.recipientId = acc.Id;
            // messageQueable.execute(null);
            
		} catch (Exception e) {
            System.debug('Error sending Member ID Card email: ' + e.getMessage());
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails sendMemberIdCardCommunity: '+e.getMessage()), 'ERROR ARC_Emails sendMemberIdCardCommunity', apexErrorEmail);
		}
	}

}