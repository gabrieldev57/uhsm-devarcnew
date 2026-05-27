trigger ARC_ContractTrigger on Contract (after insert, after update, before insert, before update) {
    
    // Before context: Update next invoice anchor for pre-invoice contracts
    // Small Group Logic
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        ARC_ContractTriggerHandler.updateNextInvoiceAnchor(Trigger.new, Trigger.oldMap);
    }
    
    // After context: Process billing automation
    // Small Group Logic
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        ARC_ContractTriggerHandler.processBillingAutomation(Trigger.new, Trigger.oldMap);
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        // Variables for createUpdateCommission method
        Map<Id,Contract> newContractMap = new Map<Id,Contract>();
        Map<Id,Contract> oldContractMap = new Map<Id,Contract>();
        // Variables for updateCommissionPrice method
        Map<Id,Contract> newContractUpdatedPriceMap = new Map<Id,Contract>();
        Map<Id,Contract> oldContractUpdatedPriceMap = new Map<Id,Contract>();
        // Variables for reactivateContract
        Map<Id,Contract> reactivatedContractMap = new Map<Id,Contract>();
        // Variables for voided Contract
        Map<Id, Contract> newVoidedContractMap = new Map<Id, Contract>();
        Id individualAndFamilyRTId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Individual and Family').getRecordTypeId();
        // Variables for reactivate voided Contract
        Map<Id,Contract> reactivatedVoidedContractMap = new Map<Id,Contract>();
        // Variables for effectiveDate change
        Set<Id> contractPoliciesToUpdate = new Set<Id>();
        // Variables for createPortal users method
        Map<Id, Contract> sgContractMap = new Map<Id, Contract>();
        Id smallGroupRTId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Small Group').getRecordTypeId();

        for (Id contractId : Trigger.newMap.keySet()) {

            // Exclude the Small Group Contracts
            if (Trigger.newMap.get(contractId).RecordTypeId == individualAndFamilyRTId) {
                //Reactivate Voided Contract
                if (
                    Trigger.newMap.get(contractId).Status != Trigger.oldMap.get(contractId).Status && 
                    (Trigger.newMap.get(contractId).Status == 'Activated' || Trigger.newMap.get(contractId).Status == 'Terminated') && 
                    Trigger.oldMap.get(contractId).Status == 'Voided'
                ) {
                    reactivatedVoidedContractMap.put(Trigger.newMap.get(contractId).Id, Trigger.newMap.get(contractId));
                }
                //Contract gets Activated
                if (
                    Trigger.newMap.get(contractId).Status != Trigger.oldMap.get(contractId).Status && 
                    Trigger.newMap.get(contractId).Status == 'Activated' && 
                    Trigger.oldMap.get(contractId).Status != 'Terminated'
                ) {
                    newContractMap.put(Trigger.newMap.get(contractId).Id, Trigger.newMap.get(contractId));
                    oldContractMap.put(Trigger.oldMap.get(contractId).Id, Trigger.oldMap.get(contractId));
                }
                //Reactivate contract
                else if (
                    Trigger.newMap.get(contractId).Status != Trigger.oldMap.get(contractId).Status && 
                    Trigger.newMap.get(contractId).Status == 'Activated' && 
                    Trigger.oldMap.get(contractId).Status == 'Terminated'
                ) {
                    reactivatedContractMap.put(Trigger.newMap.get(contractId).Id, Trigger.newMap.get(contractId));
                }
                //Contract already Activated but Changed the Total Price
                else if (
                    Trigger.newMap.get(contractId).Status == 'Activated' && 
                    Trigger.newMap.get(contractId).ARC_TotalPrice__c != Trigger.oldMap.get(contractId).ARC_TotalPrice__c
                ) {
                    newContractUpdatedPriceMap.put(Trigger.newMap.get(contractId).Id, Trigger.newMap.get(contractId));
                    oldContractUpdatedPriceMap.put(Trigger.oldMap.get(contractId).Id, Trigger.oldMap.get(contractId));
                }
                // Contract gets voided
                else if (
                    Trigger.newMap.get(contractId).Status == 'Voided' &&
                    (
                        Trigger.oldMap.get(contractId).Status == 'Activated' ||
                        (
                            Trigger.oldMap.get(contractId).Status == 'Terminated' && 
                            Trigger.oldMap.get(contractId).ARC_Inactive_Date__c != null &&
                            Trigger.oldMap.get(contractId).ARC_Inactive_Date__c.year() >= 2026
                        )
                    )
                ) {
                    newVoidedContractMap.put(Trigger.newMap.get(contractId).Id, Trigger.newMap.get(contractId));
                }
                contractPoliciesToUpdate = ARC_ContractTriggerHandler.changeEffectiveDatePolicies(Trigger.oldMap, Trigger.newMap);
            }

            // Create Portal Users
            if (Trigger.newMap.get(contractId).RecordTypeId == smallGroupRTId) {
                // Envelope Status is updated to Completed
                if (
                    trigger.oldMap.get(contractId).vlocity_ins__LastDocuSignEnvelopeStatus__c == 'Pending' &&
                    trigger.newMap.get(contractId).vlocity_ins__LastDocuSignEnvelopeStatus__c == 'Completed' &&
                    trigger.newMap.get(contractId).RecordTypeId == smallGroupRTId
                ) {
                    sgContractMap.put(Trigger.newMap.get(contractId).Id, Trigger.newMap.get(contractId));
                } 
            }
            
        }
        //Create Update Commissions for Account Executives
        if (!newContractMap.isEmpty() && !oldContractMap.isEmpty()) ARC_ContractTriggerHandler.createUpdateCommission(oldContractMap, newContractMap);
        if (!newContractUpdatedPriceMap.isEmpty() && !oldContractUpdatedPriceMap.isEmpty()) ARC_ContractTriggerHandler.updateCommissionPrice(newContractUpdatedPriceMap);
        if (!reactivatedContractMap.isEmpty()) ARC_ContractTriggerHandler.reactivateContractLinkToCommission(reactivatedContractMap);

        //Waiting Periods
        if (!contractPoliciesToUpdate.isEmpty()) ARC_WaitingPeriodsLogic.stampWaitingPeriods(contractPoliciesToUpdate, null);

        // Update Aggregators
        if (!newVoidedContractMap.isEmpty()) ARC_ContractTriggerHandler.updateAggregators(newVoidedContractMap);
        if (!reactivatedVoidedContractMap.isEmpty()) ARC_ContractTriggerHandler.reactivateAggregators(reactivatedVoidedContractMap);

        // Create Portal Users
        if (!sgContractMap.isEmpty()) ARC_SmallGroup_DocuSign.createPortalUsers(sgContractMap);

        // Update Small Group Contract when DocuSign is completed
        if (!sgContractMap.isEmpty()) ARC_SmallGroup_DocuSign.updateSmallGroupSignedContract(sgContractMap);
    }
}