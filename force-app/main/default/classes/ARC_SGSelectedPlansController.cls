public with sharing class ARC_SGSelectedPlansController {
    
    @AuraEnabled(cacheable=true)
    public static List<PlanWrapper> getSelectedPlans(Id accountId) {
        List<PlanWrapper> results = new List<PlanWrapper>();
        
        Map<String, Integer> priorityMap = new Map<String, Integer>{
            'Activated' => 1,
            'Awaiting Activation' => 2,
            'Awaiting Signature' => 3,
            'Terminated' => 4,
            'Voided' => 5
        };

        List<InsurancePolicy> policies = [
            SELECT Id, Status,
                   (SELECT Id, ARC_UnitPrice__c, 
                           vlocity_ins_fsc__Product2Id__r.Name, 
                           vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c,
                           (SELECT ARC_ParticipantName__c 
                            FROM Coverage_Participants__r) 
                    FROM InsurancePolicyCoverages 
                    WHERE ARC_ParentProduct__c = NULL)
            FROM InsurancePolicy
            WHERE NameInsuredId = :accountId
        ];

        if (policies.isEmpty()) return results;

        InsurancePolicy winningPolicy = null;
        Integer bestPriority = 999;

        for (InsurancePolicy pol : policies) {
            Integer currentPriority = priorityMap.containsKey(pol.Status) ? priorityMap.get(pol.Status) : 99;
            if (currentPriority < bestPriority) {
                bestPriority = currentPriority;
                winningPolicy = pol;
            }
        }

        if (winningPolicy != null && winningPolicy.InsurancePolicyCoverages != null) {
            for (InsurancePolicyCoverage ipc : winningPolicy.InsurancePolicyCoverages) {
                PlanWrapper pw = new PlanWrapper();
                pw.planId = ipc.Id;
                pw.planName = ipc.vlocity_ins_fsc__Product2Id__r != null ? ipc.vlocity_ins_fsc__Product2Id__r.Name : 'N/A';
                pw.programType = ipc.vlocity_ins_fsc__Product2Id__r != null ? ipc.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c : '';
                pw.unitPrice = ipc.ARC_UnitPrice__c != null ? ipc.ARC_UnitPrice__c : 0.00;
                
                List<String> names = new List<String>();
                if (ipc.Coverage_Participants__r != null) {
                    for (ARC_CoverageParticipant__c junction : ipc.Coverage_Participants__r) {
                        if (junction != null && 
                            junction.ARC_ParticipantName__c != null) {
                            names.add(junction.ARC_ParticipantName__c);
                        }
                    }
                }
                pw.activeMembers = String.join(names, '\n');
                
                results.add(pw);
            }
        }

        return results;
    }

    public class PlanWrapper {
        @AuraEnabled public Id planId;
        @AuraEnabled public String planName;
        @AuraEnabled public String programType;
        @AuraEnabled public String activeMembers;
        @AuraEnabled public Decimal unitPrice;
    }
}