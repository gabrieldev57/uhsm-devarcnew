public without sharing class ARC_EmailMessageQueable implements Queueable {

    public List<String> toAddresses;
    public String subject;
    public Id parentId;
    public Id recipientId;
    public Datetime messageDate;

    public ARC_EmailMessageQueable(List<String> toAddresses, String subject, Id parentId, Datetime messageDate) {
        this.toAddresses = toAddresses;
        this.subject = subject;
        this.parentId = parentId;
        this.messageDate = messageDate;
    }

    public void execute(QueueableContext context) {
        // message date needs to be within 2 minutes of the email message date
        messageDate = messageDate.addSeconds(-120);
        List<EmailMessage> emailMessages = [SELECT Id, Subject, TextBody, HtmlBody, MessageDate, ParentId FROM EmailMessage WHERE ToAddress = :toAddresses AND Subject = :subject AND ParentId = :parentId AND MessageDate >= :messageDate ORDER BY MessageDate DESC LIMIT 1];
        System.debug('EMAILMESSAGES: '+emailMessages);
        if(emailMessages.size() > 0) {
            EmailMessage emailMessage = emailMessages[0];
            if(recipientId != null){
                if (recipientId.getSObjectType().getDescribe().getname() == 'vlocity_ins__GroupCensusMember__c') {
                    emailMessage.ARC_CensusMember__c = recipientId;
                }
                else if (recipientId.getSObjectType().getDescribe().getname() == 'Account') {
                    emailMessage.ARC_PersonAccount__c = recipientId;
                }
            }
            System.debug('EMAILMESSAGE: '+emailMessage);
            update emailMessage;
        }

    }

    




}