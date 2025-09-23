public with sharing class ARC_RenewalDiscountEmail {
    public ARC_RenewalDiscountEmail() {

    }
    @InvocableMethod(label='Send Renewal Discount Email' description='Send renewal discount email to the primary contact of the account' category='Renewal Discounts')
    public static void sendRenewalDiscountEmail(List<ARC_PromotionDiscount__c> discounts) {
        Set<Id> discountIds = new Set<Id>();
        for(ARC_PromotionDiscount__c discount : discounts) {
            discountIds.add(discount.Id);
        }
        discounts = [
            SELECT Id, 
                ARC_RenewalDiscountNumber__c,
                ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__c, 
                ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.PersonContactId,
                ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.PersonContact.Email
            FROM ARC_PromotionDiscount__c 
            WHERE Id IN :discountIds
        ];
        OrgWideEmailAddress oMail = [
            SELECT Id, Address, DisplayName
            FROM OrgWideEmailAddress
            WHERE Displayname = 'UHSM Member Services' LIMIT 1
        ];
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        Map<Messaging.SingleEmailMessage, Id> messageToAccountId = new Map<Messaging.SingleEmailMessage, Id>();
        EmailTemplate firstRenewalTemplate = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Discount_First_Renewal' LIMIT 1];
        EmailTemplate increaseRenewalTemplate = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Discount_Increase_Renewal' LIMIT 1];
        for(ARC_PromotionDiscount__c discount : discounts) {
            Id accountId = discount.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__c;
            Id contactId = discount.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.PersonContactId;
            Id templateId = discount.ARC_RenewalDiscountNumber__c == 1 ? firstRenewalTemplate.Id : increaseRenewalTemplate.Id;
            String toAddress = discount.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.PersonContact.Email;
            
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setOrgWideEmailAddressId(oMail.Id);
            message.setTargetObjectId(contactId);
            message.setTemplateId(templateId);
            message.setBccSender(false);
            message.setUseSignature(false);
            message.setToAddresses(new List<String>{toAddress});
            messages.add(message);

            messageToAccountId.put(message, accountId);
        }
        


        try {
            Messaging.sendEmail(messages);
            for(Messaging.SingleEmailMessage message : messages) {
                ARC_EmailMessageQueable messageQueable = new ARC_EmailMessageQueable(
                    message.getToAddresses(),
                    message.getSubject(),
                    message.whatid,
                    Datetime.now()
                );
                messageQueable.recipientId = messageToAccountId.get(message);
                messageQueable.execute(null);
            }
    
            
        } catch(Exception e) {
            System.debug('Error sending renewal email: ' + e.getMessage());
        }
    }
}