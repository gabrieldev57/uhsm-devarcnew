trigger ARC_OSInstanceTrigger on vlocity_ins__OmniScriptInstance__c (after insert) {

    if (Trigger.isAfter && Trigger.isInsert) {
        ARC_OSInstanceTriggerHandler.stampSaveForLaterDateOnLead(Trigger.new); 
    }
}