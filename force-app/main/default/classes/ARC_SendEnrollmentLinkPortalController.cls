public without sharing class ARC_SendEnrollmentLinkPortalController {

    // Wrapper for input from Flow
    public class Request {
        @InvocableVariable(required=true)
        public List<Id> personAccountIds; // List of IDs per request
    }

    // Wrapper for output to Flow
    public class Response {
    
    @InvocableVariable public Integer totalEmailsAttempted;
    @InvocableVariable public Integer numberOfEmailsSent;
    @InvocableVariable public Integer numberOfEmailsFailed;
    @InvocableVariable public Boolean emailsSent;
    @InvocableVariable public String errorDetails;

}

    //Check PS Assigned
    @AuraEnabled(cacheable=true)
    public static Boolean checkEnrollmentPermission(List<Id> personIds) {
        System.debug('Checking custom permission for user...');

        Boolean hasPS = FeatureManagement.checkPermission('Launch_Send_Enrollment_Link');
        System.debug('User has custom permission? ' + hasPS);

        Boolean hasAdminPSAssigned = [
            SELECT Id 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSet.Name = 'Employer_Admin_Permissions'
            LIMIT 1
        ].size() > 0;

        return hasPS || hasAdminPSAssigned;
    }

    //End PS Check
    @InvocableMethod(label='Send Enrollment Emails')
    public static List<Response> sendEmail(List<Request> requests) {

        System.debug('===== START: Send Enrollment Emails =====');
        System.debug('Incoming Requests Size: ' + (requests == null ? 0 : requests.size()));

        Response flowResponse = new Response();
        flowResponse.emailsSent = false;
        flowResponse.numberOfEmailsSent = 0;

        if (requests == null || requests.isEmpty()) {
            System.debug('No requests received from Flow. Exiting.');
            return new List<Response>{flowResponse};
        }

        // Collect all Person IDs from all requests
        Set<Id> personIds = new Set<Id>();
        for (Request request : requests) {
            System.debug('Processing Request personAccountIds: ' + request.personAccountIds);
            if (request.personAccountIds != null) {
                personIds.addAll(request.personAccountIds);
            }
        }

        System.debug('Collected PersonIds: ' + personIds);



        if (personIds.isEmpty()) {
            System.debug('No valid PersonIds found. Exiting.');
            return new List<Response>{flowResponse};
        }

        //get Group Account Id
        Id groupAccountId;

            if (!personIds.isEmpty()) {
                
                List<Account> persons = [
                    SELECT Id,Census_Member__c, ARC_GroupAccount__r.Account_ID_18__c
                    FROM Account WHERE Id IN :personIds 
                    LIMIT 1];
                
                if (!persons.isEmpty()) {
                    groupAccountId = persons[0].ARC_GroupAccount__r.Account_ID_18__c;
                    System.debug('Group Account Id: ' + groupAccountId);
                }
            }

            //query Contract
            List<Contract> contracts = new List<Contract>();

            Date oeEndDate;
            String formattedDate;

            if (groupAccountId != null) {
                contracts = [
                    SELECT Id, ContractNumber, Status, ARC_OEEndDate__c
                    FROM Contract
                    WHERE AccountId = :groupAccountId 
                ];

                if (!contracts.isEmpty()) {
                oeEndDate = contracts[0].ARC_OEEndDate__c;
                System.debug('OE End Date: ' + oeEndDate);
                } else {
                System.debug('No Contract found for Group Account Id: ' + groupAccountId);
            }

            Date myDate = oeEndDate;
           
            if (myDate != null) {
                    DateTime dt = DateTime.newInstance(myDate, Time.newInstance(0,0,0,0));
                    formattedDate = dt.format('MM/dd/yyyy');
                }
            }

        // Query Person Accounts
        List<Account> personAccounts = [
            SELECT Id, FirstName, PersonEmail, ARC_GroupAccount__r.Account_ID_18__c, Census_Member__c
            FROM Account
            WHERE Id IN :personIds
            AND PersonEmail != NULL 
        ];

        
       

        System.debug('Queried PersonAccounts Count: ' + personAccounts.size());

        if (personAccounts.isEmpty()) {
            System.debug('No Person Accounts with email found. Exiting.');
            return new List<Response>{flowResponse};
        }

        // Get Flow Link
        ARC_ExternalFlowLinks__mdt externalFlowLink = [
            SELECT ARC_AppBaseURL__c 
            FROM ARC_ExternalFlowLinks__mdt
            WHERE ARC_Process__c = 'Self Enroll' 
            LIMIT 1
        ];

        String appBaseUrl = externalFlowLink.ARC_AppBaseURL__c;

        // Get Email Template
        EmailTemplate emailTemplate = [
            SELECT Id, Subject, HtmlValue
            FROM EmailTemplate
            WHERE Name = 'Complete Your Enrollment Today' 
            LIMIT 1
        ];

        //Get OWE Address
        OrgWideEmailAddress owea = [
            SELECT Id, Address
            FROM OrgWideEmailAddress
            WHERE DisplayName = 'No Reply' 
            LIMIT 1
        ];

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<EmailMessage> emailMessageRecords = new List<EmailMessage>();

        // Build emails
        for (Account acc : personAccounts) {

            String personalizedLink = appBaseUrl.replace('{!memberId}', acc.Census_Member__c);

            String emailBody = String.valueOf(emailTemplate.HtmlValue);
            emailBody = emailBody.replace('{Account.FirstName}', acc.FirstName);
            emailBody = emailBody.replace('[enrollment_link]', 
                '<a href="' + personalizedLink + '" style="color: #0070d2; text-decoration: underline;">' + 'Complete enrollment' + '</a>');
            emailBody = emailBody.replace('[OE_END_DATE]', formattedDate);

            System.debug('Email Body: ' + emailBody);

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { acc.PersonEmail });
            email.setOrgWideEmailAddressId(owea.Id);
            email.setSubject(emailTemplate.Subject);
            email.setHtmlBody(emailBody);
            emailsToSend.add(email);

            EmailMessage emailMessageRecord = new EmailMessage();
            emailMessageRecord.ARC_PersonAccount__c = acc.Id;
            emailMessageRecord.ToAddress = acc.PersonEmail;
            //emailMessageRecord.FromAddress = UserInfo.getUserEmail();
            emailMessageRecord.FromAddress = owea.Address;
            emailMessageRecord.Subject = emailTemplate.Subject;
            emailMessageRecord.HtmlBody = emailBody;
            emailMessageRecord.MessageDate = Datetime.now();
            emailMessageRecord.Status = '3';
            emailMessageRecords.add(emailMessageRecord);
        }

        // Insert EmailMessage records
        if (!emailMessageRecords.isEmpty()) {
            try {
                insert emailMessageRecords;
                System.debug('EmailMessage records inserted successfully.');
            } catch (DmlException e) {
                System.debug('ERROR inserting EmailMessage records: ' + e.getMessage());
            }
        }

        // Send Emails
        Integer successCount = 0;
        Integer failureCount = 0;
        Integer totalAttempted = emailsToSend.size();
        List<String> errorMessages = new List<String>();

        try {
            if (!emailsToSend.isEmpty()) {

                // false = allow partial success
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend, false);

                for (Integer i = 0; i < results.size(); i++) {
                    Messaging.SendEmailResult result = results[i];

                    if (result.isSuccess()) {
                        successCount++;
                        System.debug('Email #' + (i+1) + ' sent successfully.');
                    } 
                    else {
                        failureCount++;

                        for (Messaging.SendEmailError err : result.getErrors()) {
                            String errorMsg = 'Email #' + (i+1) + ' failed: ' + err.getMessage();
                            errorMessages.add(errorMsg);
                            System.debug(errorMsg);
                        }
                    }
                }
            }
        } 
        catch (Exception e) {
            System.debug('EXCEPTION during sendEmail: ' + e.getMessage());
            failureCount = totalAttempted;
            errorMessages.add('System Exception: ' + e.getMessage());
        }

        // Prepare response for Flow
        flowResponse.totalEmailsAttempted = totalAttempted;
        flowResponse.numberOfEmailsSent = successCount;
        flowResponse.numberOfEmailsFailed = failureCount;
        flowResponse.emailsSent = (successCount > 0);

        // Join errors into single string for Flow display
        flowResponse.errorDetails = String.join(errorMessages, '\n');

        System.debug('===== END: Send Enrollment Emails =====');
        System.debug('Total: ' + totalAttempted +
                    ', Success: ' + successCount +
                    ', Failed: ' + failureCount);

        return new List<Response>{flowResponse};
    }
}