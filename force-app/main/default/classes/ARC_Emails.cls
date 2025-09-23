/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 01-23-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
global without sharing class ARC_Emails implements vlocity_ins.VlocityOpenInterface2 {
	public static OrgWideEmailAddress oMail = [
		SELECT Id, Address, DisplayName
		FROM OrgWideEmailAddress
		WHERE Displayname = 'UHSM Member Services'
	];
	public static List<OrgWideEmailAddress> oMailNoReplay = [
		SELECT Id, Address, DisplayName
		FROM OrgWideEmailAddress
		WHERE Displayname = 'No Reply'
	];
	public static String orgURL =
		'https://' + String.valueof(System.Url.getOrgDomainURL().getHost());
	public static Organization organization = [
		SELECT Id, Name
		FROM Organization
	];
	public static string noReplyEmails = System.Label.ARC_NoReplyEmails;
	public static List<Document> orgImages = [
		SELECT Id, Name
		FROM Document
		WHERE
			Name = 'FacebookIcon'
			OR Name = 'TwitterIcon'
			OR Name = 'LinkedinIcon'
			OR Name = 'InstagramIcon'
			OR Name = 'WeShareLogo'
			OR Name = 'WeShareAsterisk'
			OR Name = 'Separator'
			OR Name = 'WeShareUHSM'
	];

	public static Boolean invokeMethod(
		String methodName,
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		if (methodName == 'handleEmail') {
			handleEmail(inputMap, outMap, options);
		}
		if (methodName == 'email_4') {
			email_4(inputMap, outMap, options);
		}
		if (methodName == 'email_6') {
			email_6(inputMap, outMap, options);
		}
		if (methodName == 'email_7') {
			email_7(inputMap, outMap, options);
		}
		if (methodName == 'email_9') {
			email_9(inputMap, outMap, options);
		}
		if (methodName == 'email_11') {
			email_11(inputMap, outMap, options);
		}
		if (methodName == 'email_12') {
			email_12(inputMap, outMap, options);
		}
		if (methodName == 'email_14') {
			email_14(inputMap, outMap, options);
		}
		if (methodName == 'email_21') {
			email_21(inputMap, outMap, options);
		}
		if (methodName == 'email_22') {
			email_22(inputMap, outMap, options);
		}
		if (methodName == 'email_23') {
			email_23(inputMap, outMap, options);
		}
		if (methodName == 'email_59') {
			email_59(inputMap, outMap, options);
		}
		if (methodName == 'email_60') {
			email_60(inputMap, outMap, options);
		}
		if (methodName == 'sendMemberIdCardInternal') {
			sendMemberIdCardInternal(inputMap, outMap, options);
		}
		if (methodName == 'sendMemberIdCardCommunity') {
			sendMemberIdCardCommunity(inputMap, outMap, options);
		}
		if (methodName == 'sendIdCardResendConfirmation') {
			sendIdCardResendConfirmation(inputMap, outMap, options);
		}
		if (methodName == 'sendWelcomeKitResendConfirmation') {
			sendWelcomeKitResendConfirmation(inputMap, outMap, options);
		}
		if (methodName == 'sendChangePaymentMethodConfirmation') {
			sendChangePaymentMethodConfirmation(inputMap, outMap, options);
		}
		if (methodName == 'sendPaymentReceipts') {
			sendPaymentReceipts(inputMap, outMap, options);
		}
		return true;
	}

	/* This method is called in the LWC aRC_EmailTemplatesOnDemand whenever an email template is manually sent,
	 this handler receives the template and member emails and sends all the corresponding mails. */
	public static void handleEmail(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		List<EmailMessage> emailMessageHistoryList = new List<EmailMessage>();
		List<Object> emailListToSend = (List<Object>) inputMap.get(
			'emailListToSend'
		);
		Id recordId = (Id) inputMap.get('recordId');

		/*List<Case> closedRejectedUC = [
			SELECT CaseNumber, Subject
			FROM Case
			WHERE
				ARC_PersonAccount__c = :recordId
				AND Status = 'Closed Rejected'
			ORDER BY CreatedDate DESC
			LIMIT 1
		];
		System.debug('UWCase ' + closedRejectedUC);*/

		List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
		for (Object em : emailListToSend) {
			Map<String, Object> email = (Map<String, Object>) em;
			Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
			message.setOrgWideEmailAddressId(oMail.Id);
			message.setSubject((String) email.get('emailSubject'));

			switch on (String) email.get('templateSelected') {
				when '6', '21', '25', '30', '31' {
					message.setEntityAttachments(
						new List<Id>{
							[
								SELECT Id
								FROM Document
								WHERE Name = 'EFTForm'
								LIMIT 1
							]
							.Id
						}
					);
				}
				when '55', '56' {
					message.setEntityAttachments(
						new List<Id>{
							[
								SELECT Id
								FROM Document
								WHERE Name = 'UHSMLabOrder'
								LIMIT 1
							]
							.Id
						}
					);
				}
				when '51' {
					message.setEntityAttachments(
						new List<Id>{
							[
								SELECT Id
								FROM Document
								WHERE Name = 'HealthyDiscountLabResultsCriteria'
								LIMIT 1
							]
							.Id
						}
					);
				}
				when '57' {
					message.setEntityAttachments(
						new List<Id>{
							[
								SELECT Id
								FROM Document
								WHERE Name = 'NonLocatesLabOrderForm'
								LIMIT 1
							]
							.Id
						}
					);
				}
			}
			if (new List<String>{'53'}.contains((String)email.get('templateSelected'))) {
				List<Case> closedRejectedUC = [
					SELECT Id
					FROM Case
					WHERE
						ARC_PersonAccount__c = :recordId
						AND Status = 'Closed Rejected'
						AND ARC_CaseType__c = 'Underwriting'
					ORDER BY CreatedDate DESC
					LIMIT 1
				];
				if (closedRejectedUC.size() != 0) {
					message.setWhatId(closedRejectedUC[0].Id);
				} else {
					message.setWhatId(recordId);
				}
			} else {
				message.setWhatId(recordId);
			}

			message.setBccSender(false);
			message.setUseSignature(false);
			message.setToAddresses(
				new List<String>{ (String) email.get('emailAddress') }
			);
			message.setHtmlBody((String) email.get('templateHtml'));
			/*if (!closedRejectedUC.isEmpty()) {
				message.setWhatId(closedRejectedUC[0].Id);
			}*/
			messages.add(message);
/*
			//generate email with the member id for each member
			if (
				((Id) email.get('recipientId'))
					.getSObjectType()
					.getDescribe()
					.getname() == 'Account'
			) {
				emailMessageHistoryList.add(
					generateEmailMessages(
						message,
						(Id) email.get('recipientId')
					)
				);
			}
			//record id va a ser una personaccountid o un case id
			if (
				(recordId.getSObjectType().getDescribe().getname() ==
				'Account' ||
				recordId.getSObjectType().getDescribe().getname() ==
				'Contact') && recordId != (Id) email.get('recipientId')
			) {
				emailMessageHistoryList.add(
					generateEmailMessages(message, recordId)
				);
			}*/
		}

		try {
			System.debug(Messaging.sendEmail(messages));
			// for(Messaging.SingleEmailMessage message : messages){
			// 	System.debug('toAddress '+message.toAddresses);
			// 	System.debug('subject '+message.subject);
			// 	System.debug('whatid '+message.whatId);
			// 	System.debug('recipientId '+recordId);
			// 	Id parentId;
			// 	if (message.whatId.getSObjectType() == Case.SObjectType) {
			// 		parentId = message.whatId;
			// 	} else {
			// 		parentId = null;
			// 	}
				// ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
				// 	message.toAddresses,
				// 	message.subject,
				// 	parentId,
				// 	Datetime.now()
				// );
				// messageQueable.recipientId = recordId;
				// messageQueable.execute(null);
			// }
		} catch (Exception e) {
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails handleEmail: '+e.getMessage()), 'ERROR ARC_Emails handleEmail', apexErrorEmail);
		}
/*
		for (EmailMessage ed : emailMessageHistoryList) {
		}
		insert emailMessageHistoryList;*/
	}

	// Healthy Discount End Date Auto Communication
	public static void email_23(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {

		List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
		Map<Messaging.SingleEmailMessage, Id> messageRecipient = new Map<Messaging.SingleEmailMessage, Id>();
		//List<EmailMessage> emList = new List<EmailMessage>();
		Date today = Date.today();
		List<Document> icons = getIconDocuments();

		for (String key : inputMap.keySet()) {
			ARC_PromotionDiscount__c discount = ((ARC_PromotionDiscount__c) inputMap.get(key));

			// Primary Member Information
			String primaryFirstName = discount.ARC_Contract__r?.vlocity_ins__EnrollmentCensusId__r?.ARC_PrimaryAccount__r?.FirstName;
			String primaryEmail = discount.ARC_Contract__r?.vlocity_ins__EnrollmentCensusId__r?.ARC_PrimaryAccount__r?.PersonEmail;
			Id primaryMemberId = discount.ARC_Contract__r?.vlocity_ins__EnrollmentCensusId__r?.ARC_PrimaryAccount__c;
			Date healthyDiscountEndDate = discount.ARC_EndDate__c;

			
			if (String.isNotBlank(primaryEmail)) {
				String daysUntilEndDate = String.valueOf(today.daysBetween(healthyDiscountEndDate));
				
				String healthyDiscountEndDateformat = string.valueOf(healthyDiscountEndDate);
				

				Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
				String HtmlTemplate = '';

				if (daysUntilEndDate == '90') {
					HtmlTemplate = ARC_Templates.Template42(primaryFirstName, healthyDiscountEndDateformat, icons);
					message.setSubject('ACTION REQUIRED: RENEW YOUR HEALTHY DISCOUNT BEFORE EXPIRATION');
					System.debug('90 --- primaryMemberId ' + primaryMemberId + ' ' + healthyDiscountEndDateformat);
				} else if (daysUntilEndDate == '30'){
					HtmlTemplate = ARC_Templates.Template43(primaryFirstName, healthyDiscountEndDateformat, icons);
					message.setSubject('REMINDER ACTION REQUIRED: RENEW YOUR HEALTHY DISCOUNT BEFORE EXPIRATION');
					System.debug('30 --- primaryMemberId ' + primaryMemberId + ' ' + healthyDiscountEndDateformat);
				}
					message.setOrgWideEmailAddressId(oMail.Id);
					message.setBccSender(false);
					message.setUseSignature(false);
					message.setToAddresses(new List<String>{ primaryEmail });
					message.setHtmlBody(HtmlTemplate);
					message.setWhatId(primaryMemberId);
					messages.add(message);
					messageRecipient.put(message, primaryMemberId);
					
			}

		}

		if (!messages.isEmpty()) {
			try {
				Messaging.sendEmail(messages);
			} catch (Exception e) {
				String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
				ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails email_23: '+ e.getMessage()), 'ERROR ARC_Emails email_23', apexErrorEmail);
			}
		}
		
        // for(Messaging.SingleEmailMessage message : messages){
        //     ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(message.toAddresses, message.subject, null, Datetime.now());
        //     messageQueable.recipientId = messageRecipient.get(message);
        //     messageQueable.execute(null);
        // }
	}

	/*******************************************************************
	 * @MethodName         :   email_22
	 * @Description        :   Age Up effective date communication
	 ********************************************************************/
	public static void email_22(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
        Map<Messaging.SingleEmailMessage, Id> messageRecipient = new Map<Messaging.SingleEmailMessage, Id>();
		List<EmailMessage> emList = new List<EmailMessage>();
		List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
		List<Document> icons = getIconDocuments();
		Date today = Date.today();

		for (String key : inputMap.keySet()) {
			Account account = ((Account) inputMap.get(key));

			// Primary Member Information
			String primaryEmail = account.ARC_Census__r.ARC_PrimaryAccount__r.PersonEmail;
			Id primaryMemberId = account.ARC_Census__r.ARC_PrimaryAccount__r.Id;

			if (String.isNotBlank(primaryEmail)) {
				// Account Information
				String firstName = account.ARC_Census__r.ARC_PrimaryAccount__r.FirstName;
				Date accountBirthdate = account.PersonBirthdate;
				String ageOffbirthdateformat =
					accountBirthdate.month() +
					'/' +
					accountBirthdate.day();
				String ageOffName = account.ARC_IsPrimaryMember__c == true
					? 'your'
					: account.FirstName + '’s';

				// Age Up record information
				String currentMonthlycontribution = String.valueOf(
					account.Age_Up__r[0].ARC_PriceBeforeAgeUp__c
				);
				String newMonthlyContribution = String.valueOf(
					account.Age_Up__r[0].ARC_PriceAfterAgeUp__c
				);
				Date ageUpEffectiveDate = account.Age_Up__r[0]
						.ARC_ManualDelay__c != null
					? account.Age_Up__r[0].ARC_ManualDelay__c
					: account.Age_Up__r[0].ARC_EffectiveDate__c;
				String nextTransactionDateformat =
					ageUpEffectiveDate.month() +
					'/' +
					ageUpEffectiveDate.day() +
					'/' +
					ageUpEffectiveDate.year();
				String daysUntilEffectiveDate = String.valueOf(
					today.daysBetween(ageUpEffectiveDate)
				);
				Integer nextTransactionMonth = ageUpEffectiveDate.month();

				Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

				String HtmlTemplate = '';

				if (daysUntilEffectiveDate == '60') {
					HtmlTemplate = ARC_Templates.Template39(
						firstName,
						ageOffName,
						ageOffbirthdateformat,
						currentMonthlycontribution,
						newMonthlyContribution,
						nextTransactionMonth,
						icons
					);
					message.setSubject(
						'Notice of upcoming change to your WeShare monthly sharing amount'
					);
				} else if (daysUntilEffectiveDate == '30') {
					HtmlTemplate = ARC_Templates.Template40(
						firstName,
						ageOffName,
						ageOffbirthdateformat,
						currentMonthlycontribution,
						newMonthlyContribution,
						nextTransactionMonth,
						icons
					);
					message.setSubject(
						'Reminder of upcoming change to your WeShare monthly sharing amount'
					);
				} else if (daysUntilEffectiveDate == '14') {
					HtmlTemplate = ARC_Templates.Template41(
						firstName,
						ageOffName,
						ageOffbirthdateformat,
						currentMonthlycontribution,
						newMonthlyContribution,
						nextTransactionMonth,
						icons
					);
					message.setSubject(
						'Reminder of upcoming change to your WeShare monthly sharing amount'
					);
				}

				message.setOrgWideEmailAddressId(oMail.Id);
				message.setBccSender(false);
				message.setUseSignature(false);
				message.setToAddresses(new List<String>{ primaryEmail });
				message.setHtmlBody(HtmlTemplate);
				message.setWhatId(primaryMemberId);
				messages.add(message);
                messageRecipient.put(message, primaryMemberId);
			}
		}

		if (!messages.isEmpty()) {
			try {
				Messaging.sendEmail(messages);
				// for(Messaging.SingleEmailMessage message : messages){
                //     ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(message.toAddresses, message.subject, null, Datetime.now());
                //     messageQueable.recipientId = messageRecipient.get(message);
                //     messageQueable.execute(null);
                // }
			} catch (Exception e) {
				System.debug('error' + e);
				String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            	ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails email_22: '+e.getMessage()), 'ERROR ARC_Emails email_22', apexErrorEmail);
			}
		}
	}

	//Monthly Contribution Received
	public static void email_4(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
        Map<Messaging.SingleEmailMessage, Id> messageRecipient = new Map<Messaging.SingleEmailMessage, Id>();

		List<EmailMessage> emList = new List<EmailMessage>();
		List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
		List<Document> icons = getIconDocuments();
		Set<Id> censusMemberIds = new Set<Id>();
		for (String key : inputMap.keySet()) {
			Map<String, Object> email = (Map<String, Object>) inputMap.get(key);
			vlocity_ins__GroupCensusMember__c cm = (vlocity_ins__GroupCensusMember__c) email.get(
				'censusMember'
			);
			censusMemberIds.add(cm.Id);
		}
		List<Account> accounts = [SELECT Id, Census_Member__c FROM Account WHERE Census_Member__c IN :censusMemberIds];
		Map<Id, Id> accountsMap = new Map<Id, Id>();
		for (Account acc : accounts) {
			accountsMap.put(acc.Census_Member__c, acc.Id);
		}

		for (String key : inputMap.keySet()) {
			Map<String, Object> email = (Map<String, Object>) inputMap.get(key);

			vlocity_ins__GroupCensusMember__c cm = (vlocity_ins__GroupCensusMember__c) email.get(
				'censusMember'
			);
			if (String.isBlank(cm?.vlocity_ins__ContactId__r?.Email))
				continue;
			ChargentOrders__Transaction__c t = (ChargentOrders__Transaction__c) email.get(
				'transaction'
			);
			String firstName = cm.vlocity_ins__FirstName__c,
				emailAddress = cm.vlocity_ins__ContactId__r.Email,
				plans = '',
				medical = '',
				smart = '',
				aidd = '';
			Decimal chargeAmount = t.ChargentOrders__Amount__c.setScale(
				2
			);

			for (
				vlocity_ins__GroupCensusMemberPlan__c gcmp : cm.vlocity_ins__GroupCensusMemberPlan__r
			) {
				if (
					gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c ==
					'Medical'
				) {
					medical =
						'<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;">' +
						gcmp.vlocity_ins__ContractLineId__r.Name +
						'</p>';
				}
				if (
					gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c ==
					'SMART'
				) {
					smart =
						'<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;">' +
						gcmp.vlocity_ins__ContractLineId__r.Name +
						'</p>';
				}
				if (
					gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c ==
					'AIDD'
				) {
					aidd =
						'<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;">' +
						gcmp.vlocity_ins__ContractLineId__r.Name +
						'</p>';
				}
			}

			plans = medical + smart + aidd;

			Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
			message.setOrgWideEmailAddressId(oMail.Id);
			message.setSubject('WeShare Healthcare by UHSM: Monthly Contribution Received');
			message.setBccSender(false);
			message.setUseSignature(false);
			message.setToAddresses(new List<String>{ emailAddress });
			message.setWhatId(accountsMap.get(cm.Id));
			String HtmlTemplate = ARC_Templates.Template4(
				firstName,
				plans,
				chargeAmount,
				icons
			);
			message.setHtmlBody(HtmlTemplate);
			messages.add(message);
            messageRecipient.put(message, accountsMap.get(cm.Id));
		}

		if (messages.isEmpty() == false) {
			try {
				Messaging.sendEmail(messages);
			} catch (Exception e) {
				String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            	ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails email_4: '+e.getMessage()), 'ERROR ARC_Emails email_4', apexErrorEmail);
			}
			
			// for (Messaging.SingleEmailMessage message : messages) {
            //     ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
            //         message.toAddresses,
            //         message.subject,
            //         null,
            //         Datetime.now()
            //     );
            //     messageQueable.recipientId = messageRecipient.get(message);
            //     messageQueable.execute(null);
            // }
		}
	}

	//Monthly Contribution Notice
	public static void email_5(List<Map<String, Object>> emailsInformation) {
		List<EmailMessage> emailMessagesRecords = new List<EmailMessage>();
		List<Messaging.SingleEmailMessage> emailMessagesList = new List<Messaging.SingleEmailMessage>();
		List<Document> icons = getIconDocuments();
        //Map<Messaging.SingleEmailMessage, Id> emailRecipient = new Map<Messaging.SingleEmailMessage, Id>();

		Set<Id> censusMemberIds = new Set<Id>();
		for (Integer i = 0; i < emailsInformation.size(); i++) {
			vlocity_ins__GroupCensusMember__c censusMember = (vlocity_ins__GroupCensusMember__c) emailsInformation[i]
				.get('censusMember');
			if (censusMember != null) {
				censusMemberIds.add(censusMember.Id);
			}
		}
		List<Account> accounts = [SELECT Id, Census_Member__c FROM Account WHERE Census_Member__c IN :censusMemberIds];
		Map<Id, Id> accountsMap = new Map<Id, Id>();
		for (Account acc : accounts) {
			accountsMap.put(acc.Census_Member__c, acc.Id);
		}

		for (Integer i = 0; i < emailsInformation.size(); i++) {
			vlocity_ins__GroupCensusMember__c censusMember = (vlocity_ins__GroupCensusMember__c) emailsInformation[i]
				.get('censusMember');
			if (censusMember != null) {
				ChargentOrders__ChargentOrder__c chargent = (ChargentOrders__ChargentOrder__c) emailsInformation[
						i
					]
					.get('chargent');
				Date nextTransactionDate = chargent.ChargentOrders__Next_Transaction_Date__c;
				String monthlyContributionDate =
					String.valueOf(nextTransactionDate.month()) +
					'/' +
					String.valueOf(nextTransactionDate.day()) +
					'/' +
					String.valueOf(nextTransactionDate.year());
				String monthlyContributionAmount = String.valueOf(
					chargent.ChargentOrders__Total__c
				);
				String firstName = censusMember?.vlocity_ins__FirstName__c;
				String emailAddress = censusMember
					?.vlocity_ins__ContactId__r.Email;
				Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
				message.setOrgWideEmailAddressId(oMail.Id);
				message.setSubject(
					'WeShare Healthcare by UHSM: Monthly Contribution Notice'
				);
				message.setBccSender(false);
				message.setUseSignature(false);
				message.setToAddresses(new List<String>{ emailAddress });
				message.setWhatId(accountsMap.get(censusMember.Id));
				String HtmlTemplate = ARC_Templates.Template5(
					firstName,
					monthlyContributionDate,
					monthlyContributionAmount,
					icons
				);
				message.setHtmlBody(HtmlTemplate);
				emailMessagesList.add(message);
				//emailRecipient.put(message, accountsMap.get(censusMember.Id));
			}
		}

		try {
			Messaging.sendEmail(emailMessagesList);
            // for (Messaging.SingleEmailMessage message : emailMessagesList) {
			// 	ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
			// 		message.toAddresses,
			// 		message.subject,
			// 		null,
			// 		Datetime.now()
			// 	);
			// 	messageQueable.recipientId = emailRecipient.get(message);
			// 	messageQueable.execute(null);
			// }
		} catch (Exception e) {
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails email_5: '+e.getMessage()), 'ERROR ARC_Emails email_5', apexErrorEmail);
		}
	}

	//AUTO UHSM: Initial Payment Decline - Automated
	public static void email_6(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		List<EmailMessage> emList = new List<EmailMessage>();
		List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

		Set<Id> censusMemberIds = new Set<Id>();
		for (String key : inputMap.keySet()) {
			Map<String, Object> email = (Map<String, Object>) inputMap.get(key);
			vlocity_ins__GroupCensusMember__c censusMember = (vlocity_ins__GroupCensusMember__c) email
				.get('censusMember');
			if (censusMember != null) {
				censusMemberIds.add(censusMember.Id);
			}
		}
		List<Account> accounts = [SELECT Id, Census_Member__c FROM Account WHERE Census_Member__c IN :censusMemberIds];
		Map<Id, Id> accountsMap = new Map<Id, Id>();
		for (Account acc : accounts) {
			accountsMap.put(acc.Census_Member__c, acc.Id);
		}

		Set<String> tokens = new Set<String>();
		for (String key : inputMap.keySet()) {
			Map<String, Object> item = (Map<String, Object>) inputMap.get(key);
			ChargentOrders__Transaction__c t = (ChargentOrders__Transaction__c) item.get(
				'transaction'
			);
			String token = t.ChargentOrders__Tokenization__c;
			tokens.add(token);
		}

		List<ChargentOrders__ChargentOrder__c> chargents = [
			SELECT
				Id,
				ChargentOrders__Payment_Method__c,
				ChargentOrders__Card_Last_4__c,
				ChargentOrders__Card_Type__c,
				ChargentOrders__Card_Month_Indicator__c,
				ChargentOrders__Card_Year_Indicator__c,
				ChargentOrders__Bank_Account_Last_4__c,
				ChargentOrders__Bank_Account_Name__c,
				ChargentOrders__Tokenization__c
			FROM ChargentOrders__ChargentOrder__c
			WHERE
				ChargentOrders__Tokenization__c IN :tokens
				AND ChargentOrders__Card_Month_Indicator__c != NULL
				AND ChargentOrders__Card_Year_Indicator__c != NULL
		];

        //Map<Messaging.SingleEmailMessage, Id> emailRecipient = new Map<Messaging.SingleEmailMessage, Id>();
		for (String key : inputMap.keySet()) {
			Map<String, Object> email = (Map<String, Object>) inputMap.get(key);
			vlocity_ins__GroupCensusMember__c cm = (vlocity_ins__GroupCensusMember__c) email.get(
				'censusMember'
			);
			if (String.isBlank(cm?.vlocity_ins__ContactId__r?.Email))
				continue;
			ChargentOrders__Transaction__c t = (ChargentOrders__Transaction__c) email.get(
				'transaction'
			);
			ChargentOrders__ChargentOrder__c chargent = null;
			String firstname = cm.vlocity_ins__FirstName__c,
				emailAddress = cm.vlocity_ins__ContactId__r.Email,
				plans = '',
				medical = '',
				smart = '',
				aidd = '',
				paymentMethodName = null,
				memberID = null,
				last4Digits = null;
			List<Document> icons = getIconDocuments();

			if (cm.e123_member_id_from_policy__c != null) {
				memberID = cm.e123_member_id_from_policy__c;
			} else {
				memberID = cm.Member_ID__c;
			}

			for (ChargentOrders__ChargentOrder__c c : chargents) {
				if (
					t.ChargentOrders__Tokenization__c ==
					c.ChargentOrders__Tokenization__c
				) {
					chargent = c;
					paymentMethodName = c.ChargentOrders__Payment_Method__c;
				}
			}

			if (paymentMethodName == 'Credit Card') {
				last4Digits = chargent.ChargentOrders__Card_Last_4__c;
			} else if (paymentMethodName == 'Bank Account') {
				last4Digits = chargent.ChargentOrders__Bank_Account_Last_4__c;
			}

			for (
				vlocity_ins__GroupCensusMemberPlan__c gcmp : cm.vlocity_ins__GroupCensusMemberPlan__r
			) {
				if (
					gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c ==
					'Medical'
				) {
					medical =
						'<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;">' +
						gcmp.vlocity_ins__ContractLineId__r.Name +
						'</p>';
				}
				if (
					gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c ==
					'SMART'
				) {
					smart =
						'<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;">' +
						gcmp.vlocity_ins__ContractLineId__r.Name +
						'</p>';
				}
				if (
					gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c ==
					'AIDD'
				) {
					aidd =
						'<p style="margin-top:0in;margin-right:0in;margin-bottom:0in;margin-left:0in;">' +
						gcmp.vlocity_ins__ContractLineId__r.Name +
						'</p>';
				}
			}

			plans = medical + smart + aidd;

			Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
			message.setOrgWideEmailAddressId(oMail.Id);
			message.setSubject('PLEASE ACT NOW TO KEEP YOUR UHSM MEMBERSHIP.');
			message.setBccSender(false);
			message.setUseSignature(false);
			message.setToAddresses(new List<String>{ emailAddress });
			String HtmlTemplate = ARC_Templates.Template6(
				firstName,
				memberID,
				plans,
				paymentMethodName,
				last4Digits,
				icons
			);
			message.setHtmlBody(HtmlTemplate);
			message.setWhatId(accountsMap.get(cm.Id));
			messages.add(message);
			//emailRecipient.put(message, accountsMap.get(cm.Id));
		}
		//Send emails
		if (messages.isEmpty() == false) {
			try {
				Messaging.sendEmail(messages);
			} catch(Exception e) {
				String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            	ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails email_6: '+e.getMessage()), 'ERROR ARC_Emails email_6', apexErrorEmail);
			}
			// for (Messaging.SingleEmailMessage message : messages) {
            //     ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
            //         message.toAddresses,
            //         message.subject,
            //         null,
            //         Datetime.now()
            //     );
            //     messageQueable.recipientId = emailRecipient.get(message);
            //     messageQueable.execute(null);
            // }
		}
	}

	public static void email_7(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		List<EmailMessage> emList = new List<EmailMessage>();
		Set<Id> censusMemberIds = (Set<Id>) inputMap.get('censusMemberIds');
		List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
		List<EmailTemplate> Template = [
			SELECT Id, Subject, HTMLValue
			FROM EmailTemplate
			WHERE DeveloperName = 'UHSM_Demographic_update_Notice'
			LIMIT 1
		];

		List<vlocity_ins__GroupCensusMember__c> cms = [
			SELECT
				Id,
				vlocity_ins__ContactId__r.Email,
				vlocity_ins__ContactId__r.Id
			FROM vlocity_ins__GroupCensusMember__c
			WHERE
				Id IN :censusMemberIds
				AND vlocity_ins__ContactId__r.Email != NULL
		];
		Set<Id> cmsSet = new Set<Id>();
		for (vlocity_ins__GroupCensusMember__c cm :cms) {
			cmsSet.add(cm.Id);
		}
		List<Account> accounts = [SELECT Id, Census_Member__c FROM Account WHERE Census_Member__c IN :cmsSet];
		Map<Id, Id> accMap = new Map<Id, Id>();
		for (Account acc : accounts) {
			accMap.put(acc.Census_Member__c, acc.Id);
		}

        //Map<Messaging.SingleEmailMessage, Id> emailRecipient = new Map<Messaging.SingleEmailMessage, Id>();
		for (vlocity_ins__GroupCensusMember__c cm : cms) {
			if (String.isBlank(cm.vlocity_ins__ContactId__r.Email))
				continue;
			Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
			message.setTreatBodiesAsTemplate(true);
			message.setTargetObjectId(cm.vlocity_ins__ContactId__r.Id);

			if (!Test.isRunningTest()) {
				message.setOrgWideEmailAddressId(oMail.Id);
				message.setSubject(Template[0].Subject);
				message.setHtmlBody(Template[0].HTMLValue);
				message.setWhatId(accMap.get(cm.Id));
			} else {
				message.setHtmlBody('Test Class Body');
			}

			message.setBccSender(false);
			message.setUseSignature(false);
			messages.add(message);
			//emailRecipient.put(message, accMap.get(cm.Id));
		}

		//Send emails
		try {
			Messaging.sendEmail(messages);
			// for (Messaging.SingleEmailMessage message : messages) {
            //     ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
            //         message.toAddresses,
            //         message.subject,
            //         null,
            //         Datetime.now()
            //     );
            //     messageQueable.recipientId = emailRecipient.get(message);
            //     messageQueable.execute(null);
            // }
		} catch (Exception e) {
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails email_7: '+e.getMessage()), 'ERROR ARC_Emails email_7', apexErrorEmail);
		}
	}

	//Payment CC Expiration – WeShare
	public static void email_9(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
		List<Document> icons = getIconDocuments();

		String last4Digits, firstName;
		String subject = 'Important Notice Regarding Your WeShare Membership';

        Set<Id> cm_ids = new Set<Id>();

        for (Object email : (List<Object>) inputMap.get('emails')) {
			vlocity_ins__GroupCensusMember__c cm = (vlocity_ins__GroupCensusMember__c)((Map<String, Object>)email).get('censusMember');
            cm_ids.add(cm.Id);
        }

        List<vlocity_ins__GroupCensusMemberPlan__c> plans = [
            SELECT vlocity_ins__GroupCensusMemberId__c,vlocity_ins__ContractLineId__r.Name
            FROM vlocity_ins__GroupCensusMemberPlan__c
            WHERE vlocity_ins__GroupCensusMemberId__c IN: cm_ids
            AND vlocity_ins__ContractLineId__r.vlocity_ins__ParentItemId__c = null
            AND vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical'
        ];

        Map<Id, String> censusmemberid_to_planname = new Map<Id, String>();
        for (vlocity_ins__GroupCensusMemberPlan__c plan : plans) {
            if (censusmemberid_to_planname.containsKey(plan.vlocity_ins__GroupCensusMemberId__c) == false) {
                censusmemberid_to_planname.put(plan.vlocity_ins__GroupCensusMemberId__c , plan.vlocity_ins__ContractLineId__r.Name);
            }
        }

		for (Object e : (List<Object>) inputMap.get('emails')) {
			Map<String, Object> email = (Map<String, Object>) e;
			vlocity_ins__GroupCensusMember__c cm = (vlocity_ins__GroupCensusMember__c) email.get(
				'censusMember'
			);
			if (String.isBlank(cm?.vlocity_ins__ContactId__r?.Email))
				continue;
			ChargentOrders__ChargentOrder__c co = (ChargentOrders__ChargentOrder__c) email.get(
				'chargentOrder'
			);
			last4Digits = co.ChargentOrders__Card_Last_4__c;
			firstName = cm.vlocity_ins__FirstName__c;
            Boolean hasMetalPlan = ((String)censusmemberid_to_planname.get(cm.Id)).contains('UHSM');
			Boolean eftFormSent = (Boolean)email.get('eftFormSent');

			Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
			message.setOrgWideEmailAddressId(oMail.Id);
			message.setSubject(hasMetalPlan == true
            ? 'Important Notice Regarding Your UHSM Membership'
            : 'Important Notice Regarding Your WeShare Membership'
            );
			message.setBccSender(false);
			message.setUseSignature(false);
			message.setToAddresses(
				new List<String>{ cm.vlocity_ins__ContactId__r.Email }
			);
			/* Template for each member */


			String HtmlTemplate = ARC_Templates.Template9(
				firstName,
				last4Digits,
				icons,
                hasMetalPlan,
				eftFormSent
			);
			message.setHtmlBody(HtmlTemplate);
			message.setWhatId((String)email.get('caseId'));
			System.debug(
				firstName +
					' ' +
					cm.vlocity_ins__ContactId__r.Email +
					' ' +
					last4Digits
			);
			messages.add(message);
		}

		/* Send Emails */
		try {
			Messaging.sendEmail(messages);
		} catch(Exception e) {
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails email_9: '+e.getMessage()), 'ERROR ARC_Emails email_9', apexErrorEmail);
		}
			//Datetime messageDate = Datetime.now().addSeconds(-120);
			//List<EmailMessage> emList = [
			//	SELECT Id, ParentId
			//	FROM EmailMessage
			//	WHERE Subject = :subject AND MessageDate >= :messageDate
			//];
			//Set<Id> caseIds = new Set<Id>();
			//for (EmailMessage em : emList) {
			//	caseIds.add(em.ParentId);
			//}
			//Map<Id, Case> caseMap = new Map<Id, Case>(
			//	[SELECT Id, ARC_PersonAccount__c FROM Case WHERE Id IN :caseIds]
			//);
			//for (EmailMessage em : emList) {
			//	em.ARC_PersonAccount__c = caseMap.get(em.ParentId)
			//		.ARC_PersonAccount__c;
			//}
			//update emList;
	}

	public static void email_11(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		List<Document> icons = getIconDocuments();

		List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
		List<EmailMessage> emList = new List<EmailMessage>();

		List<Id> contractId = (List<Id>) JSON.deserialize(
			JSON.serialize(inputMap.get('contractId')),
			List<Id>.class
		);
		if (!(contractId.isEmpty())) {
			List<Contract> c = [
				SELECT
					ARC_Inactive_Date__c,
					vlocity_ins__EnrollmentEndDate__c,
					vlocity_ins__EnrollmentCensusId__c
				FROM Contract
				WHERE Id IN :contractId
			];

			List<vlocity_ins__GroupCensusMember__c> censusMembers = [
				SELECT
					Id, 
					vlocity_ins__FirstName__c,
					vlocity_ins__ContactId__r.Email,
					(
						SELECT Name
						FROM vlocity_ins__GroupCensusMemberPlan__r
						WHERE
							vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical'
							AND vlocity_ins__ContractLineId__r.vlocity_ins__ParentItemId__c = NULL
						ORDER BY CreatedDate ASC
						LIMIT 1
					)
				FROM vlocity_ins__GroupCensusMember__c
				WHERE
					vlocity_ins__CensusId__c = :c[0]
						.vlocity_ins__EnrollmentCensusId__c
					AND (vlocity_ins__IsPrimaryMember__c = TRUE
					OR vlocity_ins__IsSpouse__c = TRUE)
			];
			Set<Id> censusMembersIds = new Set<Id>();
			for (vlocity_ins__GroupCensusMember__c cm : censusMembers) {
				censusMembersIds.add(cm.Id);
			}

			//Getting the accounts information
			List<Account> accounts = [
				SELECT Id, Census_Member__c 
				FROM Account
				WHERE Census_Member__c IN :censusMembersIds
			];
			Map<Id, Id> accountsMap = new Map<Id, Id>();
			for (Account acc : accounts) {
				if (acc.Census_Member__c != null)
					accountsMap.put(acc.Census_Member__c, acc.Id);
			}

            //Map<Messaging.SingleEmailMessage, Id> emailRecipient = new Map<Messaging.SingleEmailMessage, Id>();
			for (vlocity_ins__GroupCensusMember__c cm : censusMembers) {
				//Variables to obtain for each member
				String firstName,
					email,
					medical,
					contractInactiveDate,
					enrollmentEndDate;
				firstName = cm.vlocity_ins__FirstName__c;
				email = cm?.vlocity_ins__ContactId__r?.Email;
				if (String.isBlank(email))
					continue;
				medical = cm.vlocity_ins__GroupCensusMemberPlan__r[0].Name;
				contractInactiveDate = String.valueOf(
					c[0].ARC_Inactive_Date__c
				);
				enrollmentEndDate = String.valueOf(
					c[0].vlocity_ins__EnrollmentEndDate__c
				);

				//Email for each member
				Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
				message.setOrgWideEmailAddressId(oMail.Id);
				message.setSubject(
					'IMPORTANT NOTICE REGARDING YOUR MEMBERSHIP STATUS'
				);
				message.setBccSender(false);
				message.setUseSignature(false);
				message.setToAddresses(new List<String>{ email });
				//Template for each member
				String HtmlTemplate = ARC_Templates.Template11(
					firstName,
					medical,
					contractInactiveDate,
					enrollmentEndDate,
					icons
				);
				message.setHtmlBody(HtmlTemplate);
				message.setWhatId(accountsMap.get(cm.Id));
				//Add to message list
				messages.add(message);

				//emailRecipient.put(message, accountsMap.get(cm.Id));
			}
			//Send emails
			try {
				Messaging.sendEmail(messages);
				// for(Messaging.SingleEmailMessage message : messages){
                //     ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
                //         message.toAddresses,
                //         message.subject,
                //         null,
                //         Datetime.now()
                //     );
                //     messageQueable.recipientId = emailRecipient.get(message);
                //     messageQueable.execute(null);
                // }
			} catch (Exception e) {
				String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            	ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails email_11: '+e.getMessage()), 'ERROR ARC_Emails email_11', apexErrorEmail);
			}
		}
	}

	//EMAIL MEMBERS TURNING 65
	public static void email_12(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		List<EmailMessage> emList = new List<EmailMessage>();
		vlocity_ins__GroupCensusMember__c cm = (vlocity_ins__GroupCensusMember__c) inputMap.get(
			'censusMember'
		);
		Id primaryMemberId = cm.vlocity_ins__RelatedCensusMemberId__c != null
				? cm.vlocity_ins__RelatedCensusMemberId__c
				: cm.Id;
		Account primaryMemberAccount = [SELECT Id FROM Account WHERE Census_Member__c = :primaryMemberId];
		Id caseId = inputMap.get('caseId') != null
			? (Id) inputMap.get('caseId')
			: null;

		List<Document> icons = getIconDocuments();
		List<Contract> contracts = [
			SELECT
				Id,
				ARC_EffectiveDate__c,
				ARC_PaidThroughDate__c,
				vlocity_ins__EnrollmentCensusId__c,
				Status
			FROM Contract
			WHERE
				vlocity_ins__EnrollmentCensusId__c = :cm.vlocity_ins__CensusId__c
				AND Status != 'Terminated'
			ORDER BY CreatedDate ASC
		];

		Map<String, List<Contract>> contractsByStatus = new Map<String, List<Contract>>();

		for (Contract c : contracts) {
			if (!contractsByStatus.containsKey(c.Status)) {
				contractsByStatus.put(c.Status, new List<Contract>());
			}
			contractsByStatus.get(c.Status).add(c);
		}

		Contract contract;
		if (contractsByStatus.get('Activated') != null) {
			contract = contractsByStatus.get('Activated')[0];
		} else if (contractsByStatus.get('Awaiting Activation') != null) {
			contract = contractsByStatus.get('Awaiting Activation')[0];
		} else if (contractsByStatus.get('Awaiting Signature') != null) {
			contract = contractsByStatus.get('Awaiting Signature')[0];
		} else if (
			contractsByStatus.get('Awaiting for First Payment') != null
		) {
			contract = contractsByStatus.get('Awaiting for First Payment')[0];
		}

		if (contract != null) {
			List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
			String emailAddress = cm.vlocity_ins__RelatedCensusMemberId__c != null
				? cm?.vlocity_ins__RelatedCensusMemberId__r?.vlocity_ins__ContactId__r?.Email
				: cm?.vlocity_ins__ContactId__r?.Email;

			if (String.isNotBlank(emailAddress)) {
				String firstName = cm.vlocity_ins__FirstName__c;
				String fullName = cm.Name;
				Date birthDate = cm.vlocity_ins__Birthdate__c;
				String primaryName = cm.vlocity_ins__RelatedCensusMemberId__c != null
					? cm.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__FirstName__c
					: cm.vlocity_ins__FirstName__c;
				Date today = Date.today();
				//Calculate the Projected Paid Through Date
				Date nextBirthday;
				if ((today.month() != birthDate.month()) && (birthDate.month() == 1)) {
					nextBirthday = Date.newInstance(
						today.year()+1,
						birthDate.month(),
						birthDate.day()
					);
				} else {
					nextBirthday = Date.newInstance(
						today.year(),
						birthDate.month(),
						birthDate.day()
					);
					//if(nextBirthday < today) nextBirthday = nextBirthday.addYears(1);
				}
				Date paidThroughDate = contract.ARC_PaidThroughDate__c;
				if(paidThroughDate == null){
					paidThroughDate = contract.ARC_EffectiveDate__c.addMonths(1);
					paidThroughDate = paidThroughDate.addDays(-1); 
				}

				Date projectedPaidThroughDate = Date.newInstance(nextBirthday.year(),nextBirthday.month(),paidThroughDate.day());
				if(projectedPaidThroughDate.day() == 1){
					projectedPaidThroughDate = projectedPaidThroughDate.addDays(-1);
				}
				if(projectedPaidThroughDate <nextBirthday){
					projectedPaidThroughDate = projectedPaidThroughDate.addMonths(1);
				}
				String HtmlTemplate = '';

				HtmlTemplate = ARC_Templates.Template13(
					primaryName,
					firstName,
					fullName,
					String.valueOf(projectedPaidThroughDate),
					icons
				);

				Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
				message.setOrgWideEmailAddressId(oMail.Id);
				message.setSubject('Age 65 Notice');
				message.setBccSender(false);
				message.setUseSignature(false);
				message.setToAddresses(new List<String>{ emailAddress });
				message.setHtmlBody(HtmlTemplate);
				if (caseId != null) {
					message.setWhatId(caseId);
				} else {
					message.setWhatId(primaryMemberAccount.Id);
				}
				messages.add(message);
			}
			try {
				Messaging.sendEmail(messages);
			} catch(Exception e) {
				String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            	ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails email_12: '+e.getMessage()), 'ERROR ARC_Emails email_12', apexErrorEmail);
			}
		}
	}

	//Age 26 Notice
	public static void email_14(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		List<EmailMessage> emList = new List<EmailMessage>();
		List<String> censusMemberIds = new List<String>();
		List<Document> icons = getIconDocuments();
		Map<Id, Case> memberCase = new Map<Id, Case>();
		//Map<Messaging.SingleEmailMessage, Id> messageMember = new Map<Messaging.SingleEmailMessage, Id>();
		System.debug('inputMap: ' + inputMap);
		if (inputMap.get('memberCase') != null) {
			memberCase = (Map<Id, Case>) inputMap.get('memberCase');
		}

		for (
			Object censusMemberId : (List<Object>) inputMap.get(
				'censusMemberIds'
			)
		) {
			censusMemberIds.add(String.valueOf(censusMemberId));
		}

		System.debug('censusMemberIds: ' + censusMemberIds);
		//Getting the census information
		List<vlocity_ins__GroupCensusMember__c> censusMembers = [
			SELECT
				Name,
				vlocity_ins__FirstName__c,
				vlocity_ins__ContactId__r.Email,
				vlocity_ins__RelatedCensusMemberId__c,
				vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__r.Email,
				vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__FirstName__c
			FROM vlocity_ins__GroupCensusMember__c
			WHERE Id IN :censusMemberIds
		];

		System.debug('censusMembers: ' + censusMembers);
		//Email creation for each member
		List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
		for (vlocity_ins__GroupCensusMember__c gcm : censusMembers) {
			String firstName = gcm.vlocity_ins__FirstName__c;
			String fullName = gcm.Name;
			String email = gcm.vlocity_ins__RelatedCensusMemberId__c != null
				? gcm.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__r.Email
				: gcm.vlocity_ins__ContactId__r.Email;
			Id primaryMemberId = gcm.vlocity_ins__RelatedCensusMemberId__c != null ? gcm.vlocity_ins__RelatedCensusMemberId__c : gcm.Id;
			String primaryName = gcm.vlocity_ins__RelatedCensusMemberId__c != null
				? gcm.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__FirstName__c
				: gcm.vlocity_ins__FirstName__c;
			if (String.isBlank(email))
				continue;
			Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
			message.setOrgWideEmailAddressId(oMail.Id);
			message.setSubject('Age 26 Dependent Aging Out');
			message.setBccSender(false);
			message.setUseSignature(false);
			message.setToAddresses(new List<String>{ email });
			message.setHtmlBody(
				ARC_Templates.Template14(primaryName, firstName, fullName, icons)
			);
			System.debug('memberCase: ' + memberCase);
			if (memberCase.get(primaryMemberId) != null) {
				message.setWhatId(memberCase.get(primaryMemberId).Id);
			}
			messages.add(message);
			//messageMember.put(message, primaryMemberId);
		}
		try {
			Messaging.sendEmail(messages);
		} catch(Exception e) {
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails email_14: '+e.getMessage()), 'ERROR ARC_Emails email_14', apexErrorEmail);
		}
		// for (Messaging.SingleEmailMessage message : messages) {
		// 	ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
		// 		message.toAddresses,
		// 		message.subject,
		// 		message.whatId,
		// 		Datetime.now()
		// 	);
		// 	messageQueable.recipientId = messageMember.get(message);
		// 	messageQueable.execute(null);
		// }
	}

	//Payment Decline – Recurring Metal
	public static void email_21(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		List<Document> icons = getIconDocuments();
		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		message.setOrgWideEmailAddressId(oMail.Id);
		message.setSubject('Please Act Now To Keep Your WeShare Membership');
		message.setBccSender(false);
		message.setUseSignature(false);
		message.setToAddresses(
			new List<String>{ (String) inputMap.get('email') }
		);
		message.setEntityAttachments(
			new List<Id>{
				[SELECT Id FROM Document WHERE Name = 'EFTForm' LIMIT 1]
				.Id
			}
		);
		String firstName = (String) inputMap.get('firstName');
		String HtmlTemplate = ARC_Templates.Template21(firstName, icons);
		message.setHtmlBody(HtmlTemplate);
		message.setWhatId((String) inputMap.get('caseId'));

		//Send emails
		try {
			Messaging.sendEmail(
				new List<Messaging.SingleEmailMessage>{ message }
			);
			// ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
			// 	message.toAddresses,
			// 	message.subject,
			// 	message.whatId,
			// 	Datetime.now()
			// );
			// messageQueable.recipientId = (String) inputMap.get(
			// 	'censusMemberId'
			// );
			// System.debug('RECIPIENT ID: ' + messageQueable.recipientId);
			// System.debug('MESSAGE: ' + message);
			// messageQueable.execute(null);
		} catch (Exception e) {
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails email_21: '+e.getMessage()), 'ERROR ARC_Emails email_21', apexErrorEmail);
		}
	}

	//Payment Decline – Recurring WeShare
	public static void email_59(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		List<Document> icons = getIconDocuments();
		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		message.setOrgWideEmailAddressId(oMail.Id);
		message.setSubject('Please Act Now To Keep Your WeShare Membership');
		message.setBccSender(false);
		message.setUseSignature(false);
		message.setToAddresses(
			new List<String>{ (String) inputMap.get('email') }
		);
		String firstName = (String) inputMap.get('firstName');
		String HtmlTemplate = ARC_Templates.Template59(firstName, icons);
		message.setHtmlBody(HtmlTemplate);
		message.setWhatId((String) inputMap.get('caseId'));

		//Send emails
		try {
			Messaging.sendEmail(
				new List<Messaging.SingleEmailMessage>{ message }
			);
			// ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
			// 	message.toAddresses,
			// 	message.subject,
			// 	message.whatId,
			// 	Datetime.now()
			// );
			// messageQueable.recipientId = (String) inputMap.get(
			// 	'censusMemberId'
			// );
			// System.debug('RECIPIENT ID: ' + messageQueable.recipientId);
			// System.debug('MESSAGE: ' + message);
			// messageQueable.execute(null);
		} catch (Exception e) {
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails email_59: '+e.getMessage()), 'ERROR ARC_Emails email_59', apexErrorEmail);
		}
	}

	//Payment CC Expiration – Metal
	public static void email_60(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
		List<Document> icons = getIconDocuments();

		String firstName, last4Digits;
		String subject = 'Important Notice Regarding Your UHSM Membership';

		for (Object e : (List<Object>) inputMap.get('emails')) {
			Map<String, Object> email = (Map<String, Object>) e;
			vlocity_ins__GroupCensusMember__c cm = (vlocity_ins__GroupCensusMember__c) email.get(
				'censusMember'
			);
			if (String.isBlank(cm?.vlocity_ins__ContactId__r?.Email))
				continue;
			firstName = cm.vlocity_ins__FirstName__c;

			Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
			message.setOrgWideEmailAddressId(oMail.Id);
			message.setSubject(subject);
			message.setBccSender(false);
			message.setUseSignature(false);
			message.setToAddresses(
				new List<String>{ cm.vlocity_ins__ContactId__r.Email }
			);
			/* Template for each member */
			String HtmlTemplate = ARC_Templates.Template60(firstName, icons);
			message.setHtmlBody(HtmlTemplate);
			message.setWhatId((String) email.get('caseId'));
			messages.add(message);
		}

		/* Send Emails */
		try {
			Messaging.sendEmail(messages);
			//Datetime messageDate = Datetime.now().addSeconds(-120);
			//List<EmailMessage> emList = [
			//	SELECT Id, ParentId
			//	FROM EmailMessage
			//	WHERE Subject = :subject AND MessageDate >= :messageDate
			//];
			//Set<Id> caseIds = new Set<Id>();
			//for (EmailMessage em : emList) {
			//	caseIds.add(em.ParentId);
			//}
			//Map<Id, Case> caseMap = new Map<Id, Case>(
			//	[SELECT Id, ARC_PersonAccount__c FROM Case WHERE Id IN :caseIds]
			//);
			//for (EmailMessage em : emList) {
			//	em.ARC_PersonAccount__c = caseMap.get(em.ParentId)
			//		.ARC_PersonAccount__c;
			//}
			//update emList;
		} catch (Exception e) {
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails email_60: '+e.getMessage()), 'ERROR ARC_Emails email_60', apexErrorEmail);
		}
	}

	public static void sendMemberIdCardInternal(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		Object editBlockMapOrList = inputMap.get('EB_SelectMembers');
		String additionalEmail = (String) inputMap.get('additionalEmail');
		List<Object> members = new List<Object>();

		if (editBlockMapOrList != null) {
			if (editBlockMapOrList instanceof Map<String, Object>) {
				members.add(editBlockMapOrList);
			} else if (
				editBlockMapOrList instanceof List<Object> &&
				!((List<Object>) editBlockMapOrList).isEmpty()
			) {
				members = (List<Object>) editBlockMapOrList;
			}
		}

		if (additionalEmail != null && additionalEmail != '') {
			Map<String, Object> additionalEmailMap = new Map<String, Object>{
				'FirstName' => '',
				'Email' => additionalEmail,
				'isSelected' => true
			};
			members.add(additionalEmailMap);
		}
		outMap.put('members', members);
		EmailTemplate template = [
			SELECT Id, Subject, HtmlValue
			FROM EmailTemplate
			WHERE DeveloperName = 'UHSM_WESHARE_MEMBER_ID_CARD'
		];

		String attachmentId = '';
		Boolean isWeSharePlan = Test.isRunningTest()
			? false
			: (Boolean) inputMap.get('weSharePlan');
		Boolean isAccessPlan = Test.isRunningTest()
			? false
			: (Boolean) inputMap.get('accessPlan');
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

		Set<Id> memberIds = new Set<Id>();
		for (Object m : members) {
			Map<String, Object> member = (Map<String, Object>) m;
			if ((Id)member.get('Id') != null) {
				memberIds.add((Id)member.get('Id'));
			}
		}
		List<Account> accounts = [SELECT Id, Census_Member__c FROM Account WHERE Census_Member__c IN :memberIds];

		Map<Id, Id> accountsMap = new Map<Id, Id>();
		for (Account acc : accounts) {
			accountsMap.put(acc.Census_Member__c, acc.Id);
		}

		List<Messaging.SingleEmailMessage> emailMessagesList = new List<Messaging.SingleEmailMessage>();
		List<EmailMessage> emailTrackingList = new List<EmailMessage>();
        //Map<Messaging.SingleEmailMessage, Id> emailRecipient = new Map<Messaging.SingleEmailMessage, Id>();
		for (Object m : members) {
			Map<String, Object> member = (Map<String, Object>) m;
			if ((Boolean) member.get('isSelected') == true) {
				//Message creation
				Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
				message.setOrgWideEmailAddressId(oMail.Id);
				message.setBccSender(false);
				message.setUseSignature(false);
				message.setToAddresses(
					new List<String>{ (String) member.get('Email') }
				);
				message.setWhatId(accountsMap.get((Id)member.get('Id')));
				//message.setCcAddresses(new List<String>{(String)inputMap.get('userEmail')});
				message.setSubject(template.Subject);

				Map<String, Object> mergeFieldsMap = new Map<String, Object>{
					'{!FirstName}' => member.get('FirstName')
				};
				addSignatureImagesToMap(mergeFieldsMap);
				message.setHtmlBody(
					ARC_Emails.replaceEmailTemplateFields(
						mergeFieldsMap,
						template.HtmlValue
					)
				);
				if (!Test.isRunningTest())
					message.setEntityAttachments(
						new List<String>{ attachmentId }
					);
				emailMessagesList.add(message);
				//emailRecipient.put(message, accountsMap.get((Id)member.get('Id')));
			}

			
            // for(Messaging.SingleEmailMessage message : emailMessagesList){
				//     ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
					//         message.toAddresses,
					//         message.subject,
					//         null,
					//         Datetime.now()
					//     );
					//     messageQueable.recipientId = emailRecipient.get(message);
					//     messageQueable.execute(null);
					
            // }
            
		}
		/* Send Email */
		try {
			outMap.put('emailMessagesList', emailMessagesList);
			Messaging.sendEmail(emailMessagesList, true);
			insert emailTrackingList;
		} catch (Exception e) {
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails sendMemberIdCardInternal: '+e.getMessage()), 'ERROR ARC_Emails sendMemberIdCardInternal', apexErrorEmail);
		}
	}

	public static void sendMemberIdCardCommunity(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		List<EmailMessage> emList = new List<EmailMessage>();
		String additionalEmail = (String) inputMap.get('additionalEmail');
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
				WHERE Census_Member__c = :memberId
				LIMIT 1
			];
		}
		String memberEmail = (String) inputMap.get('email');
		String userEmail = (String) inputMap.get('userEmail');
		String senderFirstName = (String) inputMap.get('senderFirstName');
		EmailTemplate template = [
			SELECT Id, Subject, HtmlValue
			FROM EmailTemplate
			WHERE DeveloperName = 'UHSM_WESHARE_MEMBER_ID_CARD'
		];
		Map<String, Object> mergeFieldsMap = new Map<String, Object>{
			'{!Contact.FirstName}' => senderFirstName
		};
		addSignatureImagesToMap(mergeFieldsMap);
		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		message.setOrgWideEmailAddressId(oMail.Id);
		message.setBccSender(false);
		message.setUseSignature(false);
		message.setToAddresses(new List<String>{ memberEmail });
		message.setCcAddresses(new List<String>{ userEmail });
		message.setSubject(template.Subject);
		message.setWhatId(acc.Id);
		message.setHtmlBody(
			ARC_Emails.replaceEmailTemplateFields(
				mergeFieldsMap,
				template.HtmlValue
			)
		);

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

		/* Send Email */
		try {
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
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails sendMemberIdCardCommunity: '+e.getMessage()), 'ERROR ARC_Emails sendMemberIdCardCommunity', apexErrorEmail);
		}
	}

	public static void sendIdCardResendConfirmation(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		EmailTemplate template = [
			SELECT Id, Subject, HtmlValue
			FROM EmailTemplate
			WHERE DeveloperName = 'Materials_Request_ID_Card'
		];
		Map<String, Object> mergeFieldsMap = new Map<String, Object>{
			'{!Contact.FirstName}' => inputMap.get('senderFirstName')
		};
		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		message.setOrgWideEmailAddressId(oMail.Id);
		message.setBccSender(false);
		message.setUseSignature(false);
		message.setToAddresses(
			new List<String>{ (String) inputMap.get('email') }
		);
		message.setSubject(template.Subject);
		message.setHtmlBody(
			ARC_Emails.replaceEmailTemplateFields(
				mergeFieldsMap,
				template.HtmlValue
			)
		);
		message.setWhatId((String) inputMap.get('caseId'));
		/* Send Email */
		try {
			Messaging.sendEmail(
				new List<Messaging.SingleEmailMessage>{ message }
			);
			// ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
			// 	message.toAddresses,
			// 	message.subject,
			// 	message.whatId,
			// 	Datetime.now()
			// );
			// messageQueable.recipientId = (String) inputMap.get(
			// 	'censusMemberId'
			// );
			// messageQueable.execute(null);
		} catch (Exception e) {
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails sendIdCardResendConfirmation: '+e.getMessage()), 'ERROR ARC_Emails sendIdCardResendConfirmation', apexErrorEmail);
		}
	}

	public static void sendWelcomeKitResendConfirmation(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		EmailTemplate template = [
			SELECT Id, Subject, HtmlValue
			FROM EmailTemplate
			WHERE DeveloperName = 'Materials_Request_Welcome_Kit'
		];
		Map<String, Object> mergeFieldsMap = new Map<String, Object>{
			'{!Contact.FirstName}' => inputMap.get('senderFirstName')
		};
		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		message.setOrgWideEmailAddressId(oMail.Id);
		message.setBccSender(false);
		message.setUseSignature(false);
		message.setToAddresses(
			new List<String>{ (String) inputMap.get('email') }
		);
		message.setSubject(template.Subject);
		message.setHtmlBody(
			ARC_Emails.replaceEmailTemplateFields(
				mergeFieldsMap,
				template.HtmlValue
			)
		);
		message.setWhatId((String) inputMap.get('caseId'));
		/* Send Email */
		try {
			Messaging.sendEmail(
				new List<Messaging.SingleEmailMessage>{ message }
			);
			// ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
			// 	message.toAddresses,
			// 	message.subject,
			// 	message.whatId,
			// 	Datetime.now()
			// );
			// messageQueable.recipientId = (String) inputMap.get(
			// 	'censusMemberId'
			// );
			// messageQueable.execute(null);
		} catch (Exception e) {
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails sendWelcomeKitResendConfirmation: '+e.getMessage()), 'ERROR ARC_Emails sendWelcomeKitResendConfirmation', apexErrorEmail);
		}
	}

	public static void sendChangePaymentMethodConfirmation(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		String memberId = (String) inputMap.get('MemberId');
		String memberEmail = (String) inputMap.get('MemberEmail');
		EmailTemplate template = [
			SELECT Id, Subject, HtmlValue
			FROM EmailTemplate
			WHERE DeveloperName = 'MEMBER_UPDATE_PAYMENT_METHOD'
		];

		String htmlBody = template.HtmlValue;
		//Building email body
		htmlBody = String.valueOf(inputMap.get('firstName')) != null
			? htmlBody.replace(
					'{!Account.Name}',
					String.valueOf(inputMap.get('firstName'))
			  )
			: htmlBody;
		String paymentMethod = (Map<String, Object>) inputMap.get(
				'STEP_ChooseMethod'
			) != null &&
			String.valueOf(
				((Map<String, Object>) inputMap.get('STEP_ChooseMethod'))
					.get('RAD_MethodOfPayment')
			) != null
			? String.valueOf(
					((Map<String, Object>) inputMap.get('STEP_ChooseMethod'))
						.get('RAD_MethodOfPayment')
			  )
			: '';
		htmlBody = paymentMethod == 'Credit Card'
			? (htmlBody.replace('{!Bank Account}', ''))
					.replace('{!Card}', 'card')
			: paymentMethod == 'Bank Account'
					? (htmlBody.replace('{!Card}', ''))
							.replace('{!Bank Account}', 'bank account')
					: htmlBody;

		String lastNumbers = paymentMethod == 'Credit Card'
			? String.valueOf(
					((Map<String, Object>) ((Map<String, Object>) (((Map<String, Object>) inputMap.get(
									'Step_Instructions'
								))
								.get('BLK_PaymentInfo')))
							.get('BLK_UpdateCreditCard'))
						.get('TXT_CardNumber')
			  )
			: paymentMethod == 'Bank Account'
					? String.valueOf(
							((Map<String, Object>) ((Map<String, Object>) (((Map<String, Object>) inputMap.get(
											'Step_Instructions'
										))
										.get('BLK_PaymentInfo')))
									.get('BLK_BankAccount'))
								.get('TXT_UpdateAccNumber')
					  )
					: '';

		htmlBody = htmlBody.replace('{!LastNumbers}', lastNumbers.right(4));

		Integer chargeDate = String.valueOf(inputMap.get('OldChargeDate')) !=
			null
			? Integer.valueof(String.valueOf(inputMap.get('OldChargeDate')))
			: 0;
		Date nextPayment = System.today().day() > chargeDate
			? (Date.newInstance(
					(System.today().addMonths(1)).year(),
					(System.today().addMonths(1)).month(),
					chargeDate
			  ))
			: Date.newInstance((System.today()).year(), (System.today()).month(), chargeDate);
		System.debug('charge date: '+chargeDate);
		System.debug('next payment: '+nextPayment);
		htmlBody = chargeDate != 0
			? htmlBody.replace(
					'{!NextContribution}',
					String.valueof(nextPayment)
			  )
			: String.valueOf(inputMap.get('OldPaymentNextTransactionDate')) !=
					null
					? htmlBody.replace(
							'{!NextContribution}',
							String.valueOf(
								inputMap.get('OldPaymentNextTransactionDate')
							)
					  )
					: String.valueOf(inputMap.get('OldPaymentStartDate')) !=
							null
							? htmlBody.replace(
									'{!NextContribution}',
									String.valueOf(
										inputMap.get('OldPaymentStartDate')
									)
							  )
							: htmlBody.replace(
									' The next contribution will draft on {!NextContribution}.',
									''
							  );

		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		Id caseId = (Id) inputMap.get('caseId');
		message.setOrgWideEmailAddressId(oMail.Id);
		message.setBccSender(false);
		message.setUseSignature(false);
		message.setToAddresses(new List<String>{ memberEmail });
		message.setSubject(template.Subject);
		message.setHtmlBody(htmlBody);
		message.setWhatId(caseId);

		/* Send Email */
		try {
			Case caseUPM = [SELECT Id, Status FROM Case WHERE Id = :caseId];
			Messaging.sendEmail(
				new List<Messaging.SingleEmailMessage>{ message }
			);
			// ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
            //     message.toAddresses,
            //     message.subject,
            //     message.whatId,
            //     Datetime.now()
            // );
            // messageQueable.recipientId = memberId;
            // messageQueable.execute(null);
			if (caseUPM.Status == 'Closed') {
				caseUPM.Status = 'Closed';
				upsert caseUPM;
			}
		} catch (Exception e) {
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails sendChangePaymentMethodConfirmation: '+e.getMessage() + 'memberID -> ' + memberId + 'memberEmail -> ' + memberEmail), 'ERROR ARC_Emails sendChangePaymentMethodConfirmation', apexErrorEmail);
		}
	}

	public static void sendErrorMessage(
		String message,
		Integer line,
		String classname,
		String recordIds
	) {
		Organization org = [SELECT IsSandbox FROM Organization];

		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setToAddresses(new List<String>{ 'integrations@uhsm.org','christian.fortunato@arcsona.com' });
		email.setSubject('Custom Email Exception Occured');
		email.setPlainTextBody(
			'Custom Exception Ocurred while executing Apex Class: ' +
				classname +
				'\n' +
				'Error Message: ' +
				message +
				'\n' +
				'Line: ' +
				line +
				'\n' +
				'Sandbox: ' +
				org.IsSandbox +
				'\n' +
				'Records: ' +
				recordIds
		);
		Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
	}

	@AuraEnabled
	public static Map<String, Object> sendEmailConstructor(
		String emailAddress,
		String templateDeveloperName,
		Map<String, Object> mergeFieldsMap,
		Id censusMemberId
	) {
		Map<String, Object> response = new Map<String, Object>();
		List<EmailTemplate> emailTemp = [
			SELECT Subject, HtmlValue
			FROM EmailTemplate
			WHERE DeveloperName = :templateDeveloperName
			LIMIT 1
		];
		Account accountMember = [SELECT Id FROM Account WHERE Census_Member__c = :censusMemberId LIMIT 1];
		if (
			String.isBlank(emailAddress) ||
			emailTemp.isEmpty() ||
			mergeFieldsMap.isEmpty()
		) {
			response.put('success', false);
			response.put(
				'message',
				'One of the arguments provided is invalid .'
			);
			return response;
		}
		//Add Signature Images
		addSignatureImagesToMap(mergeFieldsMap);

		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		//Use Member Service or Nor Reply Email
		if (
			noReplyEmails.contains(templateDeveloperName) &&
			oMailNoReplay.size() > 0
		)
			message.setOrgWideEmailAddressId(oMailNoReplay[0].Id);
		else
			message.setOrgWideEmailAddressId(oMail.Id);
			message.setSubject(emailTemp[0].Subject);
			message.setBccSender(false);
			message.setUseSignature(false);
			message.setToAddresses(new List<String>{ emailAddress });
			message.setWhatId(accountMember.Id);
			message.setHtmlBody(
			ARC_Emails.replaceEmailTemplateFields(
				mergeFieldsMap,
				emailTemp[0].HtmlValue
			)
		);
		try {
			List<Messaging.SendEmailResult> result = Messaging.sendEmail(
				new List<Messaging.SingleEmailMessage>{ message }
			);
            
            // ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
            //     message.toAddresses,
            //     message.subject,
            //     null,
            //     Datetime.now()
            // );
            // messageQueable.recipientId = accountMember.Id;
            // messageQueable.execute(null);


			if (result[0].isSuccess()) {
				response.put('success', true);
				response.put('message', 'Email sent!');
			} else {
				throw new EmailException();
			}
		} catch (EmailException e) {
			response.put('success', false);
			response.put('message', 'Email not sent! ' + e.getMessage());
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails sendEmailConstructor: '+e.getMessage()), 'ERROR ARC_Emails sendEmailConstructor', apexErrorEmail);
		}
		return response;
	}

	/*******************************************************************
	 * @MethodName         :   sendResetUsernameAndPasswordEmailConstructor
	 * @Description        :   Constructs and sends the email responsable for welcoming the user and resetting the user's username and password.
	 * @Author             :   Francisco Caliaba
	 ********************************************************************/
	@AuraEnabled
	public static Map<String, Object> sendResetUsernameAndPasswordEmailConstructor(
		List<User> users,
		String templateDeveloperName,
		Map<String, String> mergeSyntaxToApiNameMap,
		Map<Id, Id> userToMember
	) {
		Map<String, Object> response = new Map<String, Object>();
		List<EmailMessage> emList = new List<EmailMessage>();
		List<EmailTemplate> emailTemp = [
			SELECT Subject, HtmlValue
			FROM EmailTemplate
			WHERE DeveloperName = :templateDeveloperName
			LIMIT 1
		];
		List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
		List<Id> userIds = new List<Id>();
		for (User user : users) {
			userIds.add(user.Id);
		}
		List<User> usersList = [
			SELECT FirstName, Username, Name, Email, AccountId 
			FROM USER
			WHERE Id IN :userIds
		];
		String resetPasswordUrl =
			'https://' +
			ARC_CommunityController.domainURLCommunity +
			'/members/s/set-username-and-password?';
		if (!emailTemp.isEmpty() && !usersList.isEmpty()) {
            //Map<Messaging.SingleEmailMessage, Id> emailRecipient = new Map<Messaging.SingleEmailMessage, Id>();
			for (User u : usersList) {
				Map<String, Object> mergeFieldsMap = new Map<String, Object>();
				Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

				//Add Signature Images
				addSignatureImagesToMap(mergeFieldsMap);

				email.setOrgWideEmailAddressId(oMail.Id);
				email.setSubject(emailTemp[0].Subject);
				email.setBccSender(false);
				email.setUseSignature(false);
				email.setToAddresses(new List<String>{ u.Email });
				email.setWhatId(u.AccountId);

				for (String key : mergeSyntaxToApiNameMap.keySet()) {
					String value = (String) mergeSyntaxToApiNameMap.get(key);
					mergeFieldsMap.put(key, u.get(value));
				}

				String encryptedUserId = ARC_EncryptionHelper.encryptText(u.Id);
				mergeFieldsMap.put(
					'{!Reset.Password.Url}',
					resetPasswordUrl + 'id=' + encryptedUserId
				);

				email.setHtmlBody(
					ARC_Emails.replaceEmailTemplateFields(
						mergeFieldsMap,
						emailTemp[0].HtmlValue
					)
				);
				emailList.add(email);
                //emailRecipient.put(email, u.AccountId);
			}
			try {
				List<Messaging.SendEmailResult> results = Messaging.sendEmail(
					emailList
				);
                for (Messaging.SendEmailResult r : results) {
					if (!r.isSuccess())
						throw new EmailException();
				}
                // for(Messaging.SingleEmailMessage message : emailList){
                //     ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
                //         message.toAddresses,
                //         message.subject,
                //         null,
                //         Datetime.now()
                //     );
                //     messageQueable.recipientId = emailRecipient.get(message);
                //     messageQueable.execute(null);
                // }
			} catch (EmailException e) {
				response.put('success', false);
				response.put('message', e.getMessage());
				String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            	ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails sendResetUsernameAndPasswordEmailConstructor: '+e.getMessage()), 'ERROR ARC_Emails sendResetUsernameAndPasswordEmailConstructor', apexErrorEmail);
				return response;
			}
		} else {
			response.put('success', false);
			response.put('message', 'Invalid arguments');
			return response;
		}
		response.put('success', true);
		response.put('message', 'Email List sent successfully!');
		return response;
	}

	public static String replaceEmailTemplateFields(
		Map<String, Object> mergeFieldsMap,
		String htmlEmailBody
	) {
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
	 * @MethodName         :   sendWelcomeEmail
	 * @Description        :   Invocable Methods that is called during the Update Contract on Effective date flow.
	 ********************************************************************/
	@InvocableMethod(
		label='Send Welcome Email'
		description='Send a Welcome Email with the Portal login URL + Portal Username'
		category='Member Portal'
	)
	public static void sendWelcomeEmail(List<Id> contactId) {
		List<EmailTemplate> emailTemp = [
			SELECT Subject, HtmlValue
			FROM EmailTemplate
			WHERE DeveloperName = 'WeSharePortalWelcomeEmailSelfEnroll'
			LIMIT 1
		];
		//Map<Messaging.SingleEmailMessage, Id> emailRecipient = new Map<Messaging.SingleEmailMessage, Id>();
		List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
		List<User> portalUsers = [
			SELECT Id, FirstName, Name, ARC_PortalUsername__c, Email, AccountId
			FROM User
			WHERE ContactId IN :contactId
		];
		String loginUrl =
			'https://' +
			ARC_CommunityController.domainURLCommunity +
			'/members/s/login';
		Id memberServicesId = ARC_Emails.oMail.Id;

		if (!portalUsers.isEmpty()) {
			for (User u : portalUsers) {
				Map<String, Object> mergeFieldsMap = new Map<String, Object>();
				Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
				addSignatureImagesToMap(mergeFieldsMap);

				email.setOrgWideEmailAddressId(memberServicesId);
				email.setSubject(emailTemp[0].Subject);
				email.setBccSender(false);
				email.setUseSignature(false);
				email.setWhatId(u.AccountId);
				email.setToAddresses(new List<String>{ u.Email });
				//Generate the Merge Field Map
				mergeFieldsMap.put('{!User.FirstName}', u.FirstName);
				mergeFieldsMap.put(
					'{!User.PortalUsername}',
					u.ARC_PortalUsername__c
				);
				mergeFieldsMap.put('{!Portal.LoginUrl}', loginUrl);
				//Repalce the merge fields.
				email.setHtmlBody(
					ARC_Emails.replaceEmailTemplateFields(
						mergeFieldsMap,
						emailTemp[0].HtmlValue
					)
				);
				emailList.add(email);
				//emailRecipient.put(email, u.AccountId);
			}
			//Send the Emails
			try {
				List<Messaging.SendEmailResult> results = Messaging.sendEmail(
					emailList
				);
				// for(Messaging.SingleEmailMessage message : emailList){
                //     ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
                //         message.toAddresses,
                //         message.subject,
                //         null,
                //         Datetime.now()
                //     );
                //     messageQueable.recipientId = emailRecipient.get(message);
                //     messageQueable.execute(null);
                // }
			} catch (Exception e) {
				String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            	ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails sendWelcomeEmail: '+e.getMessage()), 'ERROR ARC_Emails sendWelcomeEmail', apexErrorEmail);
			}
		}
	}

	
	public static List<Document> getIconDocuments() {
		return [
			SELECT Id, Name
			FROM Document
			WHERE
				Name IN (
					'EFTForm',
					'FacebookIcon',
					'TwitterIcon',
					'LinkedinIcon',
					'InstagramIcon',
					'WeShareLogo',
					'WeShareAsterisk',
					'Separator',
					'WeShareUHSM'
				)
		];
	}

	/**
	 * @Description: Optimized SpinOff email - receives pre-extracted data to avoid SOQL queries
	 * Reduces queries from 6 to 1 by receiving data from JSON instead of querying
	 */
	public static void sendNotificationEmailSpinOffFlowCompletionOptimized(
	    Id accountId,
	    String primaryMemberName,
	    String primaryMemberEmail,
	    List<String> spinOffMemberNames,
	    String formattedEffectiveDate
	) {
	    System.debug('sendNotificationEmailSpinOffFlowCompletionOptimized IN');
	
	    // Validate required data
	    if (accountId == null || String.isBlank(primaryMemberName) || 
	        String.isBlank(primaryMemberEmail) || spinOffMemberNames.isEmpty() ||
	        String.isBlank(formattedEffectiveDate)) {
	        System.debug('Invalid parameters for optimized email');
	        return;
	    }
	
	    // Get Email Template
	    List<EmailTemplate> emailTemp = [
	        SELECT Subject, HtmlValue
	        FROM EmailTemplate
	        WHERE DeveloperName = 'SpinOffNotifyThePrimaryUponSpinOffFlowCompletion'
	        LIMIT 1
	    ];
	
	    if (emailTemp.isEmpty()) {
	        System.debug('Email template not found');
	        return;
	    }
	
	    // Create string with names of members that were 'Spin-Off'
	    String spinOffMembers = String.join(spinOffMemberNames, ', ');
		String accountPhrase = spinOffMemberNames.size() == 1 ? 'their own account' : 'their own accounts';

	
	    System.debug('Primary Member Name: ' + primaryMemberName);
	    System.debug('Effective Date: ' + formattedEffectiveDate);
	    System.debug('Spin-Off Members: ' + spinOffMembers);
		System.debug('Primary Member Email: ' + primaryMemberEmail);
	
	    // Construct and send email
	    Id memberServicesId = ARC_Emails.oMail.Id;
	    List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
	
	    Map<String, Object> mergeFieldsMap = new Map<String, Object>();
	    addSignatureImagesToMap(mergeFieldsMap);
	
	    // Merge fields
	    mergeFieldsMap.put('{!Contact.FirstName}', primaryMemberName);
	    mergeFieldsMap.put('{!Contract.ARC_EffectiveDate__c}', formattedEffectiveDate);
	    mergeFieldsMap.put('{!Member.Name}', spinOffMembers);
	    mergeFieldsMap.put('{!accountPhrase}', accountPhrase);
	
	    // Create email
	    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
	    email.setOrgWideEmailAddressId(memberServicesId);
	    email.setSubject(emailTemp[0].Subject);
	    email.setBccSender(false);
	    email.setUseSignature(false);
	    email.setWhatId(accountId);
	    email.setToAddresses(new List<String>{ primaryMemberEmail });
	
	    // Replace merge fields
	    email.setHtmlBody(
	        ARC_Emails.replaceEmailTemplateFields(
	            mergeFieldsMap,
	            emailTemp[0].HtmlValue
	        )
	    );
	
	    emailList.add(email);
	
	    // Send email
	    try {
	        List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailList);
			
	    } catch (Exception e) {
	        String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
	        ARC_QueableSendFileBatch.sendEmailNotification(
	            ('Error in sendNotificationEmailSpinOffFlowCompletionOptimized: ' + e.getMessage()), 
	            'ERROR ARC_Emails sendSpinOffEmailOptimized', 
	            apexErrorEmail
	        );
	    }
	}

	/*******************************************************************
	 * @MethodName         :   addSignatureImagesToMap
	 * @Description        :   Adds the Signature Images to the merge field map: {Images.FacebookIcon} => "https://orgUrl+imageID"
	 ********************************************************************/
	public static void addSignatureImagesToMap(
		Map<String, Object> mergeFieldMap
	) {
		if (orgImages.size() > 0) {
			for (Document img : orgImages) {
				mergeFieldMap.put(
					'{Images.' + img.Name + '}',
					orgURL +
						'/servlet/servlet.ImageServer?id=' +
						img.Id +
						'&oid=' +
						organization?.Id
				);
			}

			for (String key : mergeFieldMap.keySet()) {
			}
		}
	}

	/*******************************************************************
	 * @MethodName         :   sendPaymentReceipts
	 * @Description        :   Invocable Methods that is called during the Update Contract on Effective date flow.
	 ********************************************************************/
	public static void sendPaymentReceipts(
		Map<String, Object> inputMap,
		Map<String, Object> outMap,
		Map<String, Object> options
	) {
		List<EmailMessage> emList = new List<EmailMessage>();
		String memberId = (String) inputMap.get('censusMemberId');
		Account accountMember = [SELECT Id FROM Account WHERE Census_Member__c = :memberId LIMIT 1];
		String memberEmail = (String) inputMap.get('email');
		String ccString = (String) inputMap.get('CCString');
		String memberName = (String) inputMap.get('MemberName');
		String memberFirstName = memberName != null &&
			memberName != ''
			? memberName.split(' ')[0]
			: null;
		List<String> ccAddresses = new List<String>();
		if (ccString != null && ccString != '') {
			if (ccString.contains(','))
				ccAddresses = ccString.split(',');
			else
				ccAddresses = new List<String>{ ccString };
		}
		Id attachmentId = Test.isRunningTest()
			? null
			: (Id) inputMap.get('pdfGenContentVersionId');
		EmailTemplate template = [
			SELECT Id, Subject, HtmlValue
			FROM EmailTemplate
			WHERE DeveloperName = 'WeSharePortalPaymentReceipts'
		];
		Map<String, Object> mergeFieldsMap = new Map<String, Object>{
			'{!Account.FirstName}' => memberFirstName
		};
		addSignatureImagesToMap(mergeFieldsMap);
		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		message.setOrgWideEmailAddressId(oMail.Id);
		message.setBccSender(false);
		message.setUseSignature(false);
		message.setToAddresses(new List<String>{ memberEmail });
		if (ccAddresses.size() > 0)
			message.setCcAddresses(ccAddresses);
		message.setSubject(template.Subject);
		message.setHtmlBody(
			ARC_Emails.replaceEmailTemplateFields(
				mergeFieldsMap,
				template.HtmlValue
			)
		);
		message.setWhatId(accountMember.Id);
		if (!Test.isRunningTest())
			message.setEntityAttachments(new List<Id>{ attachmentId });
		/* Send Email */
		try {
			Messaging.sendEmail(
				new List<Messaging.SingleEmailMessage>{ message }
			);

            // ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
            //     message.toAddresses,
            //     message.subject,
            //     null,
            //     Datetime.now()
            // );
            // messageQueable.recipientId = accountMember.Id;
            // messageQueable.execute(null);
            
			outMap.put('success', true);
			outMap.put('EmailSent', true);
		} catch (Exception e) {
			outMap.put('success', false);
			outMap.put('EmailSent', false);
			outMap.put('error: ', e.getMessage());
			String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_Emails sendPaymentReceipts: '+e.getMessage()), 'ERROR ARC_Emails sendPaymentReceipts', apexErrorEmail);
		}
	}

	//public static EmailMessage generateEmailMessages(
	//	Messaging.SingleEmailMessage email,
	//	Id recipientId
	//) {
    //    return new EmailMessage(
    //        Subject = email.getSubject(),
    //        ToAddress = email.getToAddresses().get(0),
    //        RelatedToId = recipientId
    //    );
	//}

}