trigger ARC_GroupCensusMemberPlanTrigger on vlocity_ins__GroupCensusMemberPlan__c (after insert) {
    
    if (Trigger.isAfter && Trigger.isInsert) {
        System.debug('ARC_GroupCensusMemberPlanTrigger');
        ARC_GroupCensusMemberPlanTriggerHandler.updateRelatedContractLineItemFees(Trigger.newMap);
    }
}