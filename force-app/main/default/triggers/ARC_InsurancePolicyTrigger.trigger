trigger ARC_InsurancePolicyTrigger on InsurancePolicy (before insert, before update, after insert, after update) {

    Id smallGroupRTId = Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByName().get('Small Group').getRecordTypeId();
    
    if (Trigger.isBefore && Trigger.isInsert) {
        ARC_InsurancePolicyTriggerHandler.updatePolicyName(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        Map<Id, InsurancePolicy> policyGetsActivated = new Map<Id, InsurancePolicy>();
        Map<Id, InsurancePolicy> policyGetsReactivated = new Map<Id, InsurancePolicy>();
        for (Id policyId : Trigger.newMap.keySet()) {
            InsurancePolicy oldPol = Trigger.oldMap.get(policyId);
            InsurancePolicy newPol = Trigger.newMap.get(policyId);

            if (newPol.RecordTypeId != smallGroupRTId) continue;
    
            if (
                (oldPol.Status != 'Activated' && oldPol.Status != 'Terminated' && oldPol.Status != 'Voided') &&
                (newPol.Status == 'Activated' || newPol.Status == 'Terminated' || newPol.Status == 'Voided')
            ) {
                policyGetsActivated.put(policyId, newPol);
            }
            else if (
                (oldPol.Status == 'Terminated' || oldPol.Status == 'Voided') &&
                newPol.Status == 'Activated'
            ) {
                policyGetsReactivated.put(policyId, newPol);
            }
        }
        if (!policyGetsActivated.isEmpty())
            ARC_InsurancePolicyTriggerHandler.updateActivatedDate(policyGetsActivated);
        if (!policyGetsReactivated.isEmpty())
            ARC_InsurancePolicyTriggerHandler.updateReactivatedDate(policyGetsReactivated);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        Map<Id, InsurancePolicy> policyGetsVoided = new Map<Id, InsurancePolicy>();
        Map<Id, InsurancePolicy> reactivatedVoidedPolicyMap = new Map<Id, InsurancePolicy>();
        Set<Id> effDateChangePolicySmallGroup = new Set<Id>();
        for (Id policyId: Trigger.newMap.keySet()) {
            InsurancePolicy oldPol = Trigger.oldMap.get(policyId);
            InsurancePolicy newPol = Trigger.newMap.get(policyId);

            if (newPol.RecordTypeId != smallGroupRTId) continue;

            if (oldPol.Status != 'Voided' && newPol.Status == 'Voided') {
                policyGetsVoided.put(newPol.Id, newPol);
            }
            else if (
                (newPol.Status == 'Activated' || newPol.Status == 'Terminated') && 
                oldPol.Status == 'Voided'
            ) {
                reactivatedVoidedPolicyMap.put(newPol.Id, newPol);
            }
        }
        effDateChangePolicySmallGroup = ARC_InsurancePolicyTriggerHandler.changeEffectiveDatePoliciesSG(Trigger.oldMap, Trigger.newMap);

        if (!policyGetsVoided.isEmpty())
            ARC_InsurancePolicyTriggerHandler.updateAggregators(policyGetsVoided);
        if (!reactivatedVoidedPolicyMap.isEmpty())
            ARC_InsurancePolicyTriggerHandler.reactivateAggregators(reactivatedVoidedPolicyMap);
        if (!effDateChangePolicySmallGroup.isEmpty())
            ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(effDateChangePolicySmallGroup, null);
        
        //SG Logic
        // Process billing automation for policy changes
        ARC_InsurancePolicyTriggerHandler.processBillingAutomation(Trigger.new, Trigger.oldMap);
        
        // Account Activation Logic - Activate related Account when policy is activated
        ARC_PolicyAccountHandler.processAccountActivation(Trigger.newMap, Trigger.oldMap);
    }
    
    if (Trigger.isAfter && Trigger.isInsert) {
        //SG Logic
        // Process billing automation for new policies
        ARC_InsurancePolicyTriggerHandler.processBillingAutomation(Trigger.new, null);
    }
}