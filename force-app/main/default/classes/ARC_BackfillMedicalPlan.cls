global without sharing class ARC_BackfillMedicalPlan implements Database.Batchable<sObject> {

    public Set<Id> contractIds = new Set<Id>();

    global ARC_BackfillMedicalPlan (Set<Id> contractIds){
        this.contractIds = contractIds;
    }

    global ARC_BackfillMedicalPlan(){}

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (this.contractIds.size() > 0) {
            return  Database.getQueryLocator([SELECT Id, (SELECT Id, Name FROM vlocity_ins__ContractLineItems__r WHERE vlocity_ins__ParentItemId__c = null AND vlocity_ins__ProductType__c = 'Medical') FROM Contract WHERE Status != 'Draft' AND ARC_MedicalPlan__c =null AND Id IN:this.contractIds]);
        } 
        else {
            return Database.getQueryLocator([SELECT Id, (SELECT Id, Name FROM vlocity_ins__ContractLineItems__r WHERE vlocity_ins__ParentItemId__c = null AND vlocity_ins__ProductType__c = 'Medical') FROM Contract WHERE Status != 'Draft' AND ARC_MedicalPlan__c =null]);
        }
    }

    global void execute(Database.BatchableContext bc, List<Contract> records){
        List<Contract> contractsToUpdate = new List<Contract>();
        for(Contract c:records){
            for(vlocity_ins__ContractLineItem__c lineItem:c.vlocity_ins__ContractLineItems__r){
                c.ARC_MedicalPlan__c = lineItem.Id;
                contractsToUpdate.add(c);
                System.debug(lineItem.Name);
                break;
            }
        }
        update contractsToUpdate;
    }

    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
}