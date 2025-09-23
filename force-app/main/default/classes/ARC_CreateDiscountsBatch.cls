public without sharing class ARC_CreateDiscountsBatch implements Database.Batchable<ARC_PromotionDiscount__c> {
    private List<ARC_PromotionDiscount__c> discountsToProcess;
    // private List<ARC_PromotionDiscount__c> discountsToDeactivate;

    // Constructor to receive the list
    public ARC_CreateDiscountsBatch(List<ARC_PromotionDiscount__c> discounts) {
        this.discountsToProcess = discounts;
    }

    // start method to return an iterable of the discounts
    public Iterable<ARC_PromotionDiscount__c> start(Database.BatchableContext bc) {
        return discountsToProcess;
    }

    // execute method to process chunks of the list
    public void execute(Database.BatchableContext bc, List<ARC_PromotionDiscount__c> discounts) {
        insert discounts;
    }

    // finish method
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch processing completed.');
    }
}



// List<MyObject__c> myRecords = [SELECT Id, Name FROM MyObject__c WHERE Status__c = 'Pending'];
// MyBatchClass batch = new MyBatchClass(myRecords);
// Database.executeBatch(batch, 200); // 200 is the batch size