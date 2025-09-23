global class ARC_HealthyDiscountsBackfill implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
         
        return Database.getQueryLocator([
            SELECT Id, ContractNumber, 
            (SELECT Id, Name, Contract__c FROM Healthy_Discounts__r WHERE Is_Active__c = true AND (Healthy_Status__c = 'Approved' OR Healthy_Status__c = 'Pending')),
            (SELECT Id, Name, ARC_PromoCode__c FROM Promotions__r WHERE ARC_PromoCode__r.Name = 'Healthy Discount') 
            FROM Contract WHERE Status != 'Draft' AND Id = '800VA000005tqhTYAQ']);
            //FROM Contract WHERE Status != 'Draft']);
            
    }

    global void execute(Database.BatchableContext bc, List<Contract> records){

        //Query to get the Health Discount Record Type
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Healthy_Discount' AND  SObjectType = 'ARC_PromotionDiscount__c' LIMIT 1]?.Id;

        If(recordTypeId != null && records.size()>0){

            List<ARC_PromotionDiscount__c> discountsToUpdate = new List<ARC_PromotionDiscount__c>();
          
            for(Contract record: records) {    
                
                String PromotionCode;
                for(ARC_PromotionDiscount__c pd: record.Promotions__r) {
                    if(pd.ARC_PromoCode__c != null){
                        PromotionCode = pd.ARC_PromoCode__c;
                    }
                }
                
                ARC_PromotionDiscount__c discountInfo = new ARC_PromotionDiscount__c();
                discountInfo.RecordTypeId = recordTypeId;
                discountInfo.Name = record.Healthy_Discounts__r?.Name;
                discountInfo.ARC_Contract__c = record.Id;
                discountInfo.ARC_PromoCode__c = PromotionCode;
                
        
                discountsToUpdate.add(discountInfo);
                    
            }
            insert discountsToUpdate;
        }
    }

    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
}