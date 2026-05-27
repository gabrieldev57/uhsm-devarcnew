public with sharing class ARC_SendEnrollmentLink360Controller {

    /*
     * Invocable entry point for the Record-Triggered Scheduled Flow on Contract.
     * The Flow passes the Contract Id on its scheduled date (ARC_OEStartDate__c).
     * This method resolves all eligible member accounts for the contract and delegates to sendEmail().
     */
    @InvocableMethod(
        label='Send Renewal Enrollment Links'
        description='Sends renewal enrollment link emails to all eligible members for one or more Contracts. Called from the OE Start Date scheduled flow on Contract.'
        category='Enrollment'
    )
    public static void sendRenewalEnrollmentLinks(List<Id> contractIds) {
        if (contractIds == null || contractIds.isEmpty()) return;
        for (Id contractId : contractIds) {
            Database.executeBatch(new ARC_RenewalEnrollmentLinkBatch(contractId), 50);
        }
    }

    @AuraEnabled
    public static void sendEmail(List<Id> personAccountIds) {
        if (personAccountIds == null || personAccountIds.isEmpty()) return;

        ARC_ExternalFlowLinks__mdt externalFlowLink = [
            SELECT ARC_AppBaseURL__c
            FROM ARC_ExternalFlowLinks__mdt
            WHERE ARC_Process__c = 'Self Enroll'
            LIMIT 1
        ];

        EmailTemplate emailTemplate = [
            SELECT Subject, HtmlValue
            FROM EmailTemplate
            WHERE Name = 'Complete Your WeShare Enrollment Today'
            LIMIT 1
        ];

        List<Account> accounts = [
            SELECT Id, FirstName, PersonEmail, ARC_GroupAccount__r.Name
            FROM Account
            WHERE Id IN :personAccountIds
        ];

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<EmailMessage> emailRecords = new List<EmailMessage>();

        for (Account acc : accounts) {
            String appBaseUrl = externalFlowLink.ARC_AppBaseURL__c.replace('{!memberId}', acc.Id);

            String emailBody = emailTemplate.HtmlValue;
            emailBody = emailBody.replace('{!Account.FirstName}', acc.FirstName);
            emailBody = emailBody.replace('{!Account.ARC_GroupAccount__c}', acc.ARC_GroupAccount__r.Name);
            emailBody = emailBody.replace('[enrollment_link]', '<a href="' + appBaseUrl + '">' + appBaseUrl + '</a>');

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ acc.PersonEmail });
            email.setSubject(emailTemplate.Subject);
            email.setHtmlBody(emailBody);
            emailsToSend.add(email);

            EmailMessage emailRecord = new EmailMessage();
            emailRecord.ARC_PersonAccount__c = acc.Id;
            emailRecord.FromAddress = UserInfo.getUserEmail();
            emailRecord.HtmlBody = emailBody;
            emailRecord.Subject = emailTemplate.Subject;
            emailRecord.ToAddress = acc.PersonEmail;
            emailRecord.MessageDate = Datetime.now();
            emailRecord.Status = '3';
            emailRecords.add(emailRecord);
        }

        try {
            insert emailRecords;
            Messaging.sendEmail(emailsToSend);
        } catch (EmailException e) {
            System.debug('Exception sending email: ' + e.getMessage());
        }
    }
}