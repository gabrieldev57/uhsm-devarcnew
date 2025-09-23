trigger ARC_CensusMember on vlocity_ins__GroupCensusMember__c (before insert, before update, after update) {
    // if (Trigger.isAfter && Trigger.isUpdate) {
    //     ARC_CensusMemberHandler.SendEmailNotification(Trigger.oldMap, Trigger.new); 
    // }
    if ( Trigger.isBefore && ( Trigger.isInsert || Trigger.isUpdate ) ) {
        ARC_CensusMemberHandler.updateOldSSN(Trigger.oldMap, Trigger.new, Trigger.isInsert); 
    }
}