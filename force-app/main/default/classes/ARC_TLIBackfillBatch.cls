public with sharing class ARC_TLIBackfillBatch implements Database.Batchable<sObject>, Database.Stateful {

    /*

ARC_TLIBackfillBatch batch = new ARC_TLIBackfillBatch();
Set < Id > excludeIds = new Set < Id > {
'aDE5f000000L9fbGAC',
'aDE5f000000MnDOGA0',
'aDE5f000000MJIMGA4',
'aDE5f000000N0VjGAK',
'aDE5f000000LprTGAS',
'aDE5f000000LscjGAC',
'aDE5f000000M0G7GAK',
'aDERm00000003vzOAA',
'aDERm0000000ozKOAQ',
'aDERm0000001VyIOAU',
'aDERm0000002NTyOAM',
'aDERm0000003NQ2OAM',
'aDERm0000004LuWOAU',
'aDERm0000005DRWOA2',
'aDERm0000005yZpOAI',
'aDERm0000005ybROAQ',
'aDERm0000005yd3OAA',
'aDERm00000065Y5OAI',
'aDERm0000006wr6OAA',
'aDERm0000007i4YOAQ',
'aDERm0000008ZWzOAM',
'aDERm0000009PwtOAE',
'aDERm000000AFdrOAG',
'aDERm000000B8YcOAK',
'aDE5f000000LmOgGAK',
'aDE5f000000LmOhGAK',
'aDE5f000000LmRlGAK',
'aDE5f000000LmRmGAK',
'aDE5f000000LmRnGAK',
'aDE5f000000LmRoGAK',
'aDE5f000000LmRpGAK',
'aDE5f000000LmRqGAK',
'aDE5f000000NCMqGAO',
'aDE5f000000L5LYGA0',
'aDE5f000000L6YaGAK',
'aDE5f000000LQYlGAO',
'aDE5f000000MzHHGA0',
'aDE5f000000N1tVGAS',
'aDE5f000000MbTUGA0',
'aDE5f000000LAIHGA4',
'aDERm0000000UhKOAU',
'aDERm0000001ETzOAM',
'aDERm00000020sAOAQ',
'aDERm0000002po7OAA',
'aDERm0000003uP4OAI',
'aDERm0000004rVfOAI',
'aDERm0000005jO0OAI',
'aDERm0000006atwOAA',
'aDERm0000007OYlOAM',
'aDERm0000008CDjOAM',
'aDERm00000094faOAA',
'aDERm0000009tbcOAA',
'aDERm000000Am1yOAC',
'aDERm000000BiNdOAK'};
Database.executeBatch(batch, 200);

    */

    private Integer totalProcessed = 0;
    private Integer newSmokerFee = 0;
    private Integer newExtraDependentFee = 0;
    private Integer existingTLIFee = 0;
    private Integer updatedTLIs = 0;
    public Set<Id> excludeIds = new Set<Id>();
    //start
    public Database.QueryLocator start(Database.BatchableContext context) {
        //Get transaction line items for Medical Weshare products, excluding Healthy Discount TLIs
        return Database.getQueryLocator([SELECT Id, ARC_Transaction__r.ChargentOrders__Order__r.ARC_Contract__c, ARC_Product__r.Name, ARC_Product__c, ARC_Amount__c,ARC_Transaction__r.ChargentOrders__Type__c FROM ARC_TransactionLineItem__c WHERE ARC_Product__r.vlocity_ins__Type__c = 'Medical' AND Id NOT IN :excludeIds AND Name != 'Healthy Discount' AND ARC_PromotionDiscount__c = null]);
    }

    //execute
    public void execute(Database.BatchableContext context, List<ARC_TransactionLineItem__c> transactionLineItems) {
        Set<Id> contractIds = new Set<Id>();
        Set<Id> transactionIds = new Set<Id>();
        for(ARC_TransactionLineItem__c tli : transactionLineItems) {
            contractIds.add(tli.ARC_Transaction__r.ChargentOrders__Order__r.ARC_Contract__c);
            transactionIds.add(tli.ARC_Transaction__c);
        }
        Map<vlocity_ins__ContractLineItem__c, List<ARC_TransactionLineItem__c>> planTLI = new Map<vlocity_ins__ContractLineItem__c, List<ARC_TransactionLineItem__c>>();
        List<vlocity_ins__ContractLineItem__c> plans = [
            SELECT Id,vlocity_ins__ContractId__c, vlocity_ins__Product2Id__c, vlocity_ins__Product2Id__r.vlocity_ins__Type__c,ARC_SmokerFee__c,ARC_ExtraDependentFee__c 
            FROM vlocity_ins__ContractLineItem__c 
            WHERE vlocity_ins__ContractId__c IN :contractIds AND vlocity_ins__ProductType__c = 'Medical' AND vlocity_ins__RecordTypeName__c = 'Product' 
            AND (ARC_SmokerFee__c > 0 OR ARC_ExtraDependentFee__c > 0)
        ];
        //map plans to their related TLIs
        for (vlocity_ins__ContractLineItem__c plan : plans) {
            if (!planTLI.containsKey(plan)) {
                planTLI.put(plan, new List<ARC_TransactionLineItem__c>());
            }
            for(ARC_TransactionLineItem__c tli : transactionLineItems) {
                if (tli.ARC_Transaction__r.ChargentOrders__Order__r.ARC_Contract__c == plan.vlocity_ins__ContractId__c) {
                    planTLI.get(plan).add(tli);
                }
            }
        }



        //check for existing transaction line items related to the same transaction
        List<ARC_TransactionLineItem__c> existingTLIwithFee = [
            SELECT Id, Name, ARC_Transaction__c
            FROM ARC_TransactionLineItem__c
            WHERE ARC_Transaction__c IN :transactionIds AND Name IN ('Smoker Fee', 'Extra Dependent Fee')
        ];

        Set<Id> transactionIdsWithFee = new Set<Id>();
        for(ARC_TransactionLineItem__c fee : existingTLIwithFee) {
            transactionIdsWithFee.add(fee.ARC_Transaction__c);
        }
        existingTLIFee += existingTLIwithFee.size();
        

        //for each plan, if has smoker fee or extra dependent fee, create a new TransactionLineItem for each related TLI for it related to the same transaction
        List<ARC_TransactionLineItem__c> tliToUpsert = new List<ARC_TransactionLineItem__c>();
        for(vlocity_ins__ContractLineItem__c plan : planTLI.keySet()) {
            for(ARC_TransactionLineItem__c tli : planTLI.get(plan)) {
                if(transactionIdsWithFee.contains(tli.ARC_Transaction__c)) {
                    // System.debug('Transaction already has a fee');
                    // System.debug('Transaction Id: ' + tli.ARC_Transaction__c);
                    continue;
                }
                Boolean isRefund = tli.ARC_Transaction__r.ChargentOrders__Type__c.equals('Refund');
                Decimal oldAmount = tli.ARC_Amount__c;
                // System.debug('----');
                if (plan.ARC_SmokerFee__c > 0) {
                    ARC_TransactionLineItem__c newTLI = new ARC_TransactionLineItem__c(
                        Name = 'Smoker Fee',
                        ARC_Transaction__c = tli.ARC_Transaction__c,
                        ARC_Type__c = 'Fee',
                        ARC_Amount__c = isRefund ? -plan.ARC_SmokerFee__c : plan.ARC_SmokerFee__c
                    );
                    tliToUpsert.add(newTLI);
                    newSmokerFee++;
                    //remove smoker fee from original TLI
                    tli.ARC_Amount__c += isRefund ? plan.ARC_SmokerFee__c : -plan.ARC_SmokerFee__c;
                    // System.debug('NEW TLI : SMOKER ' + newTLI);
                }
                if (plan.ARC_ExtraDependentFee__c > 0) {
                    ARC_TransactionLineItem__c newTLI = new ARC_TransactionLineItem__c(
                        Name = 'Extra Dependent Fee',
                        ARC_Transaction__c = tli.ARC_Transaction__c,
                        ARC_Type__c = 'Fee',
                        ARC_Amount__c = isRefund ? -plan.ARC_ExtraDependentFee__c : plan.ARC_ExtraDependentFee__c
                    );
                    tliToUpsert.add(newTLI);
                    newExtraDependentFee++;
                    //remove extra dependent fee from original TLI
                    tli.ARC_Amount__c += isRefund ? plan.ARC_ExtraDependentFee__c : -plan.ARC_ExtraDependentFee__c;
                    // System.debug('NEW TLI : EXTRA DEP ' + newTLI);
                }
                if (oldAmount != tli.ARC_Amount__c) {

                    tliToUpsert.add(tli);
                    updatedTLIs++;
                    // System.debug('Old Amount: ' + oldAmount);
                    // System.debug('New Amount: ' + tli.ARC_Amount__c);
                    // System.debug('UPDATED TLI: ' + tli.Id);
                }
                // System.debug('----');

            }
        }
        // System.debug('tliToUpsert: ' + tliToUpsert.size());
        totalProcessed += tliToUpsert.size();
        upsert tliToUpsert;
    }

    //finish
    public void finish(Database.BatchableContext context) {
        System.debug('Total Processed: ' + totalProcessed);
        System.debug('New Smoker Fee: ' + newSmokerFee);
        System.debug('New Extra Dependent Fee: ' + newExtraDependentFee);
        System.debug('Existing TLI with Fee: ' + existingTLIFee);
        System.debug('New TLI with Fee: ' + (newSmokerFee + newExtraDependentFee)); 
        System.debug('Updated TLIs: ' + updatedTLIs);

    }
}