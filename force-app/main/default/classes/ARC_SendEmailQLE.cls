public without sharing class ARC_SendEmailQLE {
    public class InputVar {
        @InvocableVariable public String recordId;
        @InvocableVariable public String varCreatedCaseId; 
    }

    public class OutputVar{
        @InvocableVariable public String errorDetails;
        @InvocableVariable public Boolean emailSent;
    }

    //UHSM-3117
    private class EmailContext {
        public Id personAccountId;
        public Id caseId;
        public Id personContactId;
        public String personEmail;
        public Messaging.SingleEmailMessage outboundMail;
        public Messaging.SingleEmailMessage renderedMail;
    }

    public static OrgWideEmailAddress getOrgWideEmail() {
        List<OrgWideEmailAddress> emails = [
            SELECT Id, Address, DisplayName
            FROM OrgWideEmailAddress
            WHERE Displayname = 'No Reply'
            LIMIT 1
        ];
        return emails.isEmpty() ? null : emails[0];
    }

    private static OrgWideEmailAddress senderEmail = getOrgWideEmail();

    //Send Email to Employee QLE Flow
    @InvocableMethod(
        label='send Email To Employee QLE'
        description='sends a enrollment link email to employee when they have a QLE event'
        category='Employer Portal'
    )
    public static void sendEmailToEmployeeQLE(List<InputVar> inputs){

        if (inputs == null || inputs.isEmpty()) return;

        Set<Id> accountIds = new Set<Id>();
        // for(InputVar input : inputs){
        //     accountIds.add(input.recordId);
        // }
        for (InputVar input : inputs) {
            if (String.isNotBlank(input.recordId)) {
                accountIds.add((Id) input.recordId);
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, PersonContactId, PersonEmail
            FROM Account
            WHERE Id IN :accountIds]
        );

        EmailTemplate template = [
            SELECT Id 
            FROM EmailTemplate 
            WHERE Name = 'QLE Email v2'
            LIMIT 1
        ];

        List<EmailContext> contexts = new List<EmailContext>();
        List<Messaging.SingleEmailMessage> outboundEmails = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for(InputVar input : inputs){
            if (String.isBlank(input.recordId) || String.isBlank(input.varCreatedCaseId)) {
                continue;
            }
            //Account acc = accountMap.get(input.recordId);
            Account acc = accountMap.get((Id) input.recordId);
            if(acc == null || acc.PersonContactId == null) continue;

            //UHSM-3117
            EmailContext ctx = new EmailContext();
            ctx.personAccountId = acc.Id;
            ctx.caseId = (Id) input.varCreatedCaseId;
            ctx.personContactId = acc.PersonContactId;
            ctx.personEmail = acc.PersonEmail != null ? acc.PersonEmail : '';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(template.Id);
            mail.setTargetObjectId(acc.PersonContactId);
            mail.setWhatId(input.varCreatedCaseId);

            if(senderEmail != null){
                mail.setOrgWideEmailAddressId(senderEmail.Id);
            }

            //keep curren hehaviour: do not save as standard activity
            mail.setSaveAsActivity(false);
            ctx.outboundMail = mail;
            //Render the template so we can persist the actual subject/body into Email Message
            ctx.renderedMail = Messaging.renderStoredEmailTemplate(
                template.Id, 
                acc.PersonContactId, 
                ctx.caseId
            );
            contexts.add(ctx);
            outboundEmails.add(mail);
            //emails.add(mail);
        }

        if(outboundEmails.isEmpty()){
            return;
        }

        Messaging.SendEmailResult[] results = Messaging.sendEmail(outboundEmails);

        List<EmailMessage> EmailMessagesToInsert = new List<EmailMessage>();

        for (Integer i = 0; i < results.size(); i++) {
            Messaging.SendEmailResult result = results[i];
            EmailContext ctx = contexts[i];

            if (result != null && result.isSuccess()) {
                EmailMessage em = new EmailMessage();
                // Match the custom lookup the LWC query expects
                em.ARC_PersonAccount__c = ctx.personAccountId;
                // Helpful record association
                em.RelatedToId = ctx.caseId;
                // Outbound email
                em.Incoming = false;
                // Current retrieval logic expects sent emails with Status = '3'
                em.Status = '3';
                em.MessageDate = System.now();
                // Basic addressing
                em.ToAddress = ctx.personEmail;
                if (senderEmail != null) {
                    em.FromAddress = senderEmail.Address;
                }
                // Persist rendered content
                if (ctx.renderedMail != null) {
                    em.Subject = ctx.renderedMail.getSubject();
                    em.HtmlBody = ctx.renderedMail.getHtmlBody();
                    em.TextBody = ctx.renderedMail.getPlainTextBody();
                } else {
                    em.Subject = 'QLE Email';
                }
                emailMessagesToInsert.add(em);
            }
        }

        if (!emailMessagesToInsert.isEmpty()) {
            insert emailMessagesToInsert;
        }

        // if(!emails.isEmpty()){
        //     Messaging.sendEmail(emails);
        // }
    }
}