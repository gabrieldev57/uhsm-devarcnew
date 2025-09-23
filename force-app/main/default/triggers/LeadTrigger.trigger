trigger LeadTrigger on Lead (after insert) {

    if (Trigger.isAfter && Trigger.isInsert) {
        LeadTriggerHandler handler = new LeadTriggerHandler();
        handler.sendFive9SMSOptIn(Trigger.new);
    }
    
}