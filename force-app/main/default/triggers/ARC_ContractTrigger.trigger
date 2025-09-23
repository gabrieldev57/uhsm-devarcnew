trigger ARC_ContractTrigger on Contract (after update, before update) {
    
    if(Trigger.isAfter && Trigger.isUpdate){
        //Variables for createUpdateCommission method
        Map<Id,Contract> newContractMap = new Map<Id,Contract>();
        Map<Id,Contract> oldContractMap = new Map<Id,Contract>();
        //Variables for updateCommissionPrice method
        Map<Id,Contract> newContractUpdatedPriceMap = new Map<Id,Contract>();
        Map<Id,Contract> oldContractUpdatedPriceMap = new Map<Id,Contract>();
        //Variables for reactivateContract
        Map<Id,Contract> reactivatedContractMap = new Map<Id,Contract>();

        for(Id contractId: Trigger.newMap.keySet()){
            //Contract gets Activated
            if(
                Trigger.newMap.get(contractId).Status != Trigger.oldMap.get(contractId).Status && 
                Trigger.newMap.get(contractId).Status =='Activated' && 
                Trigger.oldMap.get(contractId).Status != 'Terminated'
            ){
                newContractMap.put(Trigger.newMap.get(contractId).Id, Trigger.newMap.get(contractId));
                oldContractMap.put(Trigger.oldMap.get(contractId).Id, Trigger.oldMap.get(contractId));
            }
            //Reactivate contract
            else if(
                Trigger.newMap.get(contractId).Status != Trigger.oldMap.get(contractId).Status && 
                Trigger.newMap.get(contractId).Status =='Activated' && 
                Trigger.oldMap.get(contractId).Status == 'Terminated'
            ){
                reactivatedContractMap.put(Trigger.newMap.get(contractId).Id, Trigger.newMap.get(contractId));
            }
            //Contract already Activated but Changed the Total Price
            else if(
                Trigger.newMap.get(contractId).Status =='Activated' && 
                Trigger.newMap.get(contractId).ARC_TotalPrice__c != Trigger.oldMap.get(contractId).ARC_TotalPrice__c
            ){
                newContractUpdatedPriceMap.put(Trigger.newMap.get(contractId).Id, Trigger.newMap.get(contractId));
                oldContractUpdatedPriceMap.put(Trigger.oldMap.get(contractId).Id, Trigger.oldMap.get(contractId));
            }
        }
        //Create Update Commissions for Account Executives
        if(!newContractMap.isEmpty() && !oldContractMap.isEmpty()) ARC_ContractTriggerHandler.createUpdateCommission(oldContractMap, newContractMap);
        if(!newContractUpdatedPriceMap.isEmpty() && !oldContractUpdatedPriceMap.isEmpty()) ARC_ContractTriggerHandler.updateCommissionPrice(newContractUpdatedPriceMap);
        if(!reactivatedContractMap.isEmpty()) ARC_ContractTriggerHandler.reactivateContractLinkToCommission(reactivatedContractMap);

        //Waiting Periods
        Set<Id> contractPoliciesToUpdate = ARC_ContractTriggerHandler.changeEffectiveDatePolicies(Trigger.oldMap, Trigger.newMap);
        if(contractPoliciesToUpdate.size() > 0) ARC_WaitingPeriodsLogic.stampWaitingPeriods(contractPoliciesToUpdate, null);

        /* Code is no longer needed, aggregator creation was moved to a batch that runs separately scheduled to run everyday */

        // try {
        // // Create Aggregators for Participants
        // Set<Id> contractIds = newContractMap.keySet();
        // String idString = '\'' + String.join(new List<Id>(contractIds), '\',\'') + '\'';
        // String whereClause = 'ARC_Contract__c IN (' + idString + ')';
        // if(contractIds.size() > 0) {
        //     Database.executeBatch(new ARC_PolicyTriggerHandler(whereClause),1);
        // }
        // } catch (Exception e) {
        //     System.debug('Error creating aggregators for participants');
        //     System.debug(e.getMessage());
        // }

    }
}