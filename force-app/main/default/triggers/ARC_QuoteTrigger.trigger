trigger ARC_QuoteTrigger on Quote (before update, after update) {

    if (Trigger.isBefore && Trigger.isUpdate) {
        ARC_QuoteTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        ARC_QuoteTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}