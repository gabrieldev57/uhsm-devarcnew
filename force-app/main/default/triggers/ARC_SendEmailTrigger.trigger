trigger ARC_SendEmailTrigger on ARC_Email__c (after insert, after delete, after update, before delete, before insert, before update) {

    if(trigger.isAfter && trigger.isUpdate) {
        for (ARC_Email__c email : Trigger.new) {
            if (email.ARC_Error__c ==  null) {
                ARC_EmailSenderTriggerHandler.updateEmailsSent(Trigger.new);
            }
        }
    }
    
    if(trigger.isBefore && trigger.isInsert) {
        for (ARC_Email__c email : Trigger.new) {
            if (email.ARC_Error__c ==  null) {
                ARC_EmailSenderTriggerHandler.onBeforeInsert(Trigger.new);
            }
        }
    }

}