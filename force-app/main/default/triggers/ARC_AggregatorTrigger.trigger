trigger ARC_AggregatorTrigger on ARC_Aggregator__c (after delete) {
    if (trigger.isAfter && trigger.isDelete) {
        ARC_AggregatorTriggerHandler.updateFamilyAggregatorsOnDelete(Trigger.old);
        ARC_AggregatorTriggerHandler.updateParentAggregatorsOnDelete(Trigger.old);
    }
}