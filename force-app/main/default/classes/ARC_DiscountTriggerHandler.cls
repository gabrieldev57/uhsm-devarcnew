public with sharing class ARC_DiscountTriggerHandler {
    //This variable is used to avoid the recursion of the discounts making update on other discounts
    public static Boolean isRunning = false;
    private static Id renewalDiscountRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Renewal_Discount').getRecordTypeId();

    public static void onAfterInsert(Map<Id, ARC_PromotionDiscount__c> newDiscounts) {
        if(isRunning) {
            return;
        }
        isRunning = true;
        Set<Id> contractsToPopulate = new Set<Id>();
        Set<Id> contractsToApply = new Set<Id>();
        Set<Id> renewalDiscountContracts = new Set<Id>();
        for (ARC_PromotionDiscount__c discount : newDiscounts.values()) {
            if (discount.ARC_Status__c == 'Activated') {
                contractsToApply.add(discount.ARC_Contract__c);
                if(discount.RecordTypeId == renewalDiscountRecordTypeId) {
                    renewalDiscountContracts.add(discount.ARC_Contract__c);
                }
            } else {
                contractsToPopulate.add(discount.ARC_Contract__c);
            }
        }
        if (!contractsToPopulate.isEmpty()) {
            ARC_Discounts.populateDiscounts(contractsToPopulate);
        }
        if (!contractsToApply.isEmpty()) {
            Boolean applyOnAgeUp = true;
            if(!renewalDiscountContracts.isEmpty()) {
                handleRenewalDiscountActivation(renewalDiscountContracts, newDiscounts.keySet());
            }
            ARC_Discounts.applyDiscounts(contractsToApply, applyOnAgeUp);
        }
        isRunning = false;
    }
    
    public static void onAfterUpdate(Map<Id, ARC_PromotionDiscount__c> newDiscounts, Map<Id, ARC_PromotionDiscount__c> oldDiscounts) {
        if(isRunning) {
            return;
        }
        isRunning = true;
        Set<Id> contractsToApply = new Set<Id>();
        Set<Id> contractsToCalculate = new Set<Id>();
        Set<Id> renewalDiscountContracts = new Set<Id>();
        for(Id discountId : newDiscounts.keySet()) {
            ARC_PromotionDiscount__c newDiscount = newDiscounts.get(discountId);
            ARC_PromotionDiscount__c oldDiscount = oldDiscounts.get(discountId);
            if(afterUpdateCondition(newDiscount, oldDiscount)) {
                //Check if the discount was activated or is activated now 
                if(newDiscount.ARC_Status__c == 'Activated' || oldDiscount.ARC_Status__c == 'Activated') {
                    contractsToApply.add(newDiscount.ARC_Contract__c);
                    if(newDiscount.RecordTypeId == renewalDiscountRecordTypeId && newDiscount.ARC_Status__c == 'Activated') {
                        renewalDiscountContracts.add(newDiscount.ARC_Contract__c);
                    }
                    //Else: Calculate the discount amounts.
                } else {
                    contractsToCalculate.add(newDiscount.ARC_Contract__c);
                }
                
            }
        }
        if (!contractsToApply.isEmpty()) {
            Boolean applyOnAgeUp = true;
            if(!renewalDiscountContracts.isEmpty()) {
                handleRenewalDiscountActivation(renewalDiscountContracts, newDiscounts.keySet());
            }
            //ARC_Discounts.populateDiscounts(contractsToCalculate);
            ARC_Discounts.applyDiscounts(contractsToApply, applyOnAgeUp);
        }
        isRunning = false;
    }
    
    private static Boolean afterUpdateCondition(ARC_PromotionDiscount__c newDiscount, ARC_PromotionDiscount__c oldDiscount) {
        Boolean condition = false;
        if(newDiscount.ARC_ContractStatus__c != 'Terminated' && newDiscount.ARC_ContractStatus__c != 'Voided' && newDiscount.ARC_ContractStatus__c != 'Draft') {
            if (oldDiscount.ARC_Status__c != 'Activated' && newDiscount.ARC_Status__c == 'Activated') {
                condition = true;
            }
            if (oldDiscount.ARC_Status__c == 'Activated' && newDiscount.ARC_Status__c != 'Activated') {
                condition = true;
            }
            if(
                oldDiscount.ARC_DiscountRate__c != newDiscount.ARC_DiscountRate__c ||
                oldDiscount.ARC_DiscountedAmount__c != newDiscount.ARC_DiscountedAmount__c ||
                oldDiscount.ARC_ApplyFirst__c != newDiscount.ARC_ApplyFirst__c ||
                oldDiscount.ARC_ApplyOver__c != newDiscount.ARC_ApplyOver__c
            ) {
                condition = true;
            }
        }
        return condition;
    }

    private static void handleRenewalDiscountActivation(Set<Id> renewalDiscountContractsIds, Set<Id> newDiscountIds) {
        // Get active renewals discounts related to the same contract
        List<ARC_PromotionDiscount__c> activeRenewalDiscounts = [
            SELECT Id, ARC_Contract__c, ARC_Status__c 
            FROM ARC_PromotionDiscount__c 
            WHERE ARC_Contract__c IN :renewalDiscountContractsIds 
            AND Id NOT IN :newDiscountIds
            AND ARC_Status__c = 'Activated' 
            AND RecordType.DeveloperName = 'Renewal_Discount'
        ];
        // Deactivate active renewal discounts
        for(ARC_PromotionDiscount__c activeRenewalDiscount : activeRenewalDiscounts) {
            activeRenewalDiscount.ARC_Status__c = 'Terminated';
        }
        update activeRenewalDiscounts;
    }


}