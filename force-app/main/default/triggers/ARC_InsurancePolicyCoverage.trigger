trigger ARC_InsurancePolicyCoverage on InsurancePolicyCoverage (after insert, after update, after delete, after undelete) {
    Set<Id> policyIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUndelete || Trigger.isUpdate) { 
        for (InsurancePolicyCoverage ipc : Trigger.new) {
            if (ipc.InsurancePolicyId != null) {
                if (Trigger.isUpdate) {
                    InsurancePolicyCoverage oldIpc = Trigger.oldMap.get(ipc.Id);
                    
                    if (ipc.ARC_Reason__c != oldIpc.ARC_Reason__c || ipc.InsurancePolicyId != oldIpc.InsurancePolicyId) {
                        policyIds.add(ipc.InsurancePolicyId);
                        
                        if (oldIpc.InsurancePolicyId != null && ipc.InsurancePolicyId != oldIpc.InsurancePolicyId) {
                            policyIds.add(oldIpc.InsurancePolicyId); 
                        }
                    }
                } else {
                    policyIds.add(ipc.InsurancePolicyId);
                }
            }
        }
    }

    if (Trigger.isDelete) {
        for (InsurancePolicyCoverage ipc : Trigger.old) {
            if (ipc.InsurancePolicyId != null) {
                policyIds.add(ipc.InsurancePolicyId);
            }
        }
    }

    if (!policyIds.isEmpty()) {
        ARC_SGQLEHelper.recalculatePolicyReasons(policyIds);
    }
}