trigger ARC_DiscountTrigger on ARC_PromotionDiscount__c (after insert, after update) {
    // ARC_DiscountTriggerHandler handler = new ARC_DiscountTriggerHandler();
    if (Trigger.isInsert) {
        if(Trigger.isAfter){
            ARC_DiscountTriggerHandler.onAfterInsert(Trigger.newMap);
        }
    }
    if (Trigger.isUpdate) {
        if(Trigger.isAfter){
            ARC_DiscountTriggerHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }
    }
}