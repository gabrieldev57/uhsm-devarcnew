/**
 * @description Handles sending invoice email notifications when a PDF is attached to an Invoice.
 *              Triggered via ContentDocumentLink after insert.
 *              Uses the "Invoice_Notification" Classic Email Template for the email body.
 * @author lucas.benero@arcsona.com
 */
public with sharing class ARC_InvoiceEmailHandler {

    private static final String BILLING_CONTACT_ROLE  = 'Billing Contact';
    private static final String EMAIL_TEMPLATE_NAME   = 'Invoice_Notification';

    /**
     * @description Entry point from ContentDocumentLink trigger.
     *              Filters only links where the related entity is an ARC_Invoice__c.
     */
    public static void handleContentDocumentLinkInsert(List<ContentDocumentLink> newLinks) {
        String invoicePrefix = ARC_Invoice__c.getSObjectType().getDescribe().getKeyPrefix();

        // Collect Invoice Ids and their associated ContentDocument Ids
        Map<Id, Id> invoiceIdToDocumentId = new Map<Id, Id>();
        for (ContentDocumentLink cdl : newLinks) {
            if (cdl.LinkedEntityId != null &&
                String.valueOf(cdl.LinkedEntityId).startsWith(invoicePrefix)) {
                invoiceIdToDocumentId.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
            }
        }

        if (invoiceIdToDocumentId.isEmpty()) {
            return;
        }

        // Verify the ContentDocuments are PDFs
        Map<Id, ContentDocument> pdfDocuments = new Map<Id, ContentDocument>([
            SELECT Id, Title, FileExtension, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Id IN :invoiceIdToDocumentId.values()
              AND FileExtension = 'pdf'
        ]);

        // Keep only invoice Ids whose document is a PDF
        Map<Id, Id> invoiceIdToPdfVersionId = new Map<Id, Id>();
        for (Id invoiceId : invoiceIdToDocumentId.keySet()) {
            Id docId = invoiceIdToDocumentId.get(invoiceId);
            if (pdfDocuments.containsKey(docId)) {
                invoiceIdToPdfVersionId.put(invoiceId, pdfDocuments.get(docId).LatestPublishedVersionId);
            }
        }

        if (invoiceIdToPdfVersionId.isEmpty()) {
            return;
        }

        // Query Invoices with Contract → Account
        List<ARC_Invoice__c> invoices = [
            SELECT Id, Name, ARC_DueDate__c, ARC_AmountDue__c,
                   ARC_CoverageDateFrom__c,
                   ARC_Contract__r.AccountId
            FROM ARC_Invoice__c
            WHERE Id IN :invoiceIdToPdfVersionId.keySet()
        ];

        // Collect Account Ids to find Billing Contacts
        Set<Id> accountIds = new Set<Id>();
        for (ARC_Invoice__c inv : invoices) {
            if (inv.ARC_Contract__r?.AccountId != null) {
                accountIds.add(inv.ARC_Contract__r.AccountId);
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        // Query Billing Contacts via AccountContactRelation — need Contact Id for targetObjectId
        Map<Id, Id> accountIdToBillingContactId = new Map<Id, Id>();
        for (AccountContactRelation acr : [
            SELECT AccountId, ContactId, Contact.Email
            FROM AccountContactRelation
            WHERE AccountId IN :accountIds
              AND Roles INCLUDES (:BILLING_CONTACT_ROLE)
              AND Contact.Email != null
        ]) {
            if (!accountIdToBillingContactId.containsKey(acr.AccountId)) {
                accountIdToBillingContactId.put(acr.AccountId, acr.ContactId);
            }
        }

        if (accountIdToBillingContactId.isEmpty()) {
            return;
        }

        // Query PDF version bodies
        Map<Id, ContentVersion> versionMap = new Map<Id, ContentVersion>([
            SELECT Id, Title, VersionData
            FROM ContentVersion
            WHERE Id IN :invoiceIdToPdfVersionId.values()
        ]);

        // Query the Classic email template by developer name
        List<EmailTemplate> templates = [
            SELECT Id
            FROM EmailTemplate
            WHERE DeveloperName = :EMAIL_TEMPLATE_NAME
            LIMIT 1
        ];
        if (templates.isEmpty()) {
            throw new IllegalArgumentException(
                'Email template "' + EMAIL_TEMPLATE_NAME + '" not found. ' +
                'Please create it in Setup → Classic Email Templates.'
            );
        }
        Id templateId = templates[0].Id;

        // Query org-wide email address
        Id orgWideEmailId = null;
        List<OrgWideEmailAddress> owas = [
            SELECT Id
            FROM OrgWideEmailAddress
            WHERE Address = 'noreply@uhsm.org'
            LIMIT 1
        ];
        if (!owas.isEmpty()) {
            orgWideEmailId = owas[0].Id;
        }

        // Build and send emails
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (ARC_Invoice__c inv : invoices) {
            Id accountId = inv.ARC_Contract__r?.AccountId;
            if (accountId == null || !accountIdToBillingContactId.containsKey(accountId)) {
                continue;
            }

            Id versionId = invoiceIdToPdfVersionId.get(inv.Id);
            if (!versionMap.containsKey(versionId)) {
                continue;
            }

            ContentVersion cv = versionMap.get(versionId);

            // Build PDF attachment
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(cv.Title + '.pdf');
            attachment.setBody(cv.VersionData);
            attachment.setContentType('application/pdf');

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTargetObjectId(accountIdToBillingContactId.get(accountId));
            email.setWhatId(inv.Id);
            email.setTemplateId(templateId);
            email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
            email.setSaveAsActivity(false);
            if (orgWideEmailId != null) {
                email.setOrgWideEmailAddressId(orgWideEmailId);
            }

            emails.add(email);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false); // false = don't throw on partial failure
        }
    }
}