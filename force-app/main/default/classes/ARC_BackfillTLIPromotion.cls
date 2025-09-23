global without sharing class ARC_BackfillTLIPromotion implements Database.Batchable<sObject>{

    public Set<Id> transactionLineItemIds = new Set<Id>();

    global ARC_BackfillTLIPromotion (Set<Id> transactionLineItem){
        System.debug('EXECUTE BATCH FOR SPECIFIC TLI');
        this.transactionLineItemIds = transactionLineItem;

    }

    global ARC_BackfillTLIPromotion(){}

    global Database.QueryLocator start(Database.BatchableContext BC){

        if (this.transactionLineItemIds.size() > 0) {
            return Database.getQueryLocator([
            SELECT Id, Name, ARC_Transaction__c, ARC_Transaction__r.ChargentOrders__Order__c, ARC_Transaction__r.ARC_PromotionDiscount__c, ARC_Transaction__r.ARC_PromotionDiscount__r.ARC_AmountToDiscountPerTransaction__c, ARC_Transaction__r.ChargentOrders__Order__r.ARC_Contract__c
            FROM ARC_TransactionLineItem__c 
            WHERE Id IN: transactionLineItemIds
            AND (Name LIKE '%Healthy Discount%' OR ARC_Transaction__r.ARC_PromotionDiscount__c != null)
            ]);
            
        }else{
            return Database.getQueryLocator([
                SELECT Id, Name, ARC_Transaction__c, ARC_Transaction__r.ChargentOrders__Order__c, ARC_Transaction__r.ARC_PromotionDiscount__c, ARC_Transaction__r.ARC_PromotionDiscount__r.ARC_AmountToDiscountPerTransaction__c, ARC_Transaction__r.ChargentOrders__Order__r.ARC_Contract__c
                FROM ARC_TransactionLineItem__c 
                WHERE Name LIKE '%Healthy Discount%' OR ARC_Transaction__r.ARC_PromotionDiscount__c != null
        ]);}
        
    }

    global void execute(Database.BatchableContext BC, List<ARC_TransactionLineItem__c> transactionLineItemsFromDiscounts){
        System.debug('Executed');

        List<ARC_TransactionLineItem__c> hdDiscountTLI = new List<ARC_TransactionLineItem__c> ();
        List<ARC_TransactionLineItem__c> discountPromoTLI = new List<ARC_TransactionLineItem__c>();
        Set<Id> contractRelatedToHD = new Set<Id>();

        for (ARC_TransactionLineItem__c tli : transactionLineItemsFromDiscounts){
            if (tli.Name.contains('Healthy Discount')){
                contractrelatedtoHD.add(tli.ARC_Transaction__r.ChargentOrders__Order__r.ARC_Contract__c);
                hdDiscountTLI.add(tli);
            }
            else if (tli.ARC_Transaction__r.ARC_PromotionDiscount__c != null){
                discountPromoTLI.add(tli);    
            }
        }

        //Populate ARC_PromotionDiscount__c for Discount Promos 
        for (ARC_TransactionLineItem__c tli : discountPromoTLI){
            tli.ARC_PromotionDiscount__c = tli.ARC_Transaction__r.ARC_PromotionDiscount__c;
        }

        //Populate ARC_PromotionDiscount__c for HD 
       List <ARC_PromotionDiscount__c> hds = [SELECT Id, ARC_Contract__c, ARC_Status__c FROM ARC_PromotionDiscount__c WHERE ARC_Contract__c IN: contractRelatedToHD AND RecordType.DeveloperName = 'Healthy_Discount'];
       Map<Id, List<ARC_PromotionDiscount__c>> contractIdHDS = new  Map<Id, List<ARC_PromotionDiscount__c>>();
       for (ARC_PromotionDiscount__c hd : hds) {
            Id contractId = hd.ARC_Contract__c;
            if (contractIdHDS.containsKey(contractId)){
                contractIdHDS.get(contractId).add(hd);
            }
            else{
                contractIdHDS.put(contractId, new List<ARC_PromotionDiscount__c>{hd});
            }
       }

       for (ARC_TransactionLineItem__c tli: hdDiscountTLI) {
            if (contractIdHDS.get(tli.ARC_Transaction__r.ChargentOrders__Order__r.ARC_Contract__c) != NULL){
                if (contractIdHDS.get(tli.ARC_Transaction__r.ChargentOrders__Order__r.ARC_Contract__c).size()>1){
                    Integer hdsActive=0;
                    Id hdActiveId;
                    for ( ARC_PromotionDiscount__c hd : contractIdHDS.get(tli.ARC_Transaction__r.ChargentOrders__Order__r.ARC_Contract__c)) {
                        if (hd.ARC_Status__c == 'Activated') {
                            hdsActive ++;
                            hdActiveId = hd.Id;
                        }
                    }
                    if(hdsActive == 1){
                        tli.ARC_PromotionDiscount__c = hdActiveId;
                    }
                }
                else if (contractIdHDS.get(tli.ARC_Transaction__r.ChargentOrders__Order__r.ARC_Contract__c).size() ==1) {
                    tli.ARC_PromotionDiscount__c = contractIdHDS.get(tli.ARC_Transaction__r.ChargentOrders__Order__r.ARC_Contract__c)[0].Id;
                }
            }
       }
       update discountPromoTLI;
       update hdDiscountTLI;
    

    }

    global void finish(Database.BatchableContext BC){
        System.debug('Finished running batch job');
    }




}