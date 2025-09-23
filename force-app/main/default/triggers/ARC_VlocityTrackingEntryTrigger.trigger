trigger ARC_VlocityTrackingEntryTrigger on vlocity_ins__VlocityTrackingEntry__c (before insert) {
    if ( Trigger.isBefore && Trigger.isInsert ) {
        ARC_VlocityTrackingEntryHandler.updateLeadSource(Trigger.new); 
    }
}