public with sharing class ARC_ContractLineItemTriggerHandler {
    public static void handleAfterDelete(List<vlocity_ins__ContractLineItem__c> deletedCLIs) {
        Set<Id> deletedIds = new Set<Id>();
        for (vlocity_ins__ContractLineItem__c cli : deletedCLIs) {
            if (cli.Id != null) {
                deletedIds.add(cli.Id);
            }
        }
        if (!deletedIds.isEmpty()) {
            List<vlocity_ins__GroupClassContribution__c> toDelete = [
                SELECT Id FROM vlocity_ins__GroupClassContribution__c
                WHERE ARC_ContractLineItem__c IN :deletedIds
            ];
            if (!toDelete.isEmpty()) {
                delete toDelete;
            }
        }
    }
}