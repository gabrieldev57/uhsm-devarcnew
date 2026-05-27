public with sharing class ARC_Beneficiaries360Controller {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCoverageParticipantId(Id accountId) {
        // Variables
        Map<String, Object> output = new Map<String, Object>();
        InsurancePolicy bestPolicyOption = null;
        InsurancePolicyParticipant bestPolicyParticipant = null;
        Boolean displayComponent = false;

        // Get the Account data
        Account accountRecord = [
            SELECT Id,
                   Name,
                   Census_Member__r.vlocity_ins__ContactId__c,
                   vlocity_ins__Age__pc
            FROM Account
            WHERE Id = :accountId
        ];

        // Get all Policy Participants
        List<InsurancePolicyParticipant> policyParticipantList = [
            SELECT Id,
                   InsurancePolicyId
            FROM InsurancePolicyParticipant
            WHERE PrimaryParticipantContactId = :accountRecord.Census_Member__r.vlocity_ins__ContactId__c
        ];

        // Get all InsurancePolicyId
        Set<Id> policyIdSet = new Set<Id>();

        for (InsurancePolicyParticipant policyParticipant : policyParticipantList) {
            policyIdSet.add(policyParticipant.InsurancePolicyId);
        }

        // Get all Policies
        List<InsurancePolicy> policyList = [
            SELECT Id,
                   ARC_ExpirationDate__c,
                   ARC_PolicyStatus__c
            FROM InsurancePolicy
            WHERE Id IN :policyIdSet
        ];

        // Get the best Policy record
        for (InsurancePolicy policy : policyList) {
            if (getPriority(policy) == 99) continue;

            if (bestPolicyOption == null) {
                bestPolicyOption = policy;
                if (policy.ARC_PolicyStatus__c == 'Activated') break;
                continue;
            }

            Integer currentPriority = getPriority(policy);
            Integer bestPriority = getPriority(bestPolicyOption);

            if (currentPriority < bestPriority) {
                bestPolicyOption = policy;
                if (policy.ARC_PolicyStatus__c == 'Activated') break;
            } else if (currentPriority == bestPriority) {
                if (policy.ARC_ExpirationDate__c > bestPolicyOption.ARC_ExpirationDate__c) {
                    bestPolicyOption = policy;
                }
            }
        }

        if (bestPolicyOption == null) {
            output.put('coverageParticipantId', null);
            output.put('displayComponent', false);
            return output;
        }

        // Find the Insurance Policy Participant
        for (InsurancePolicyParticipant policyParticipant : policyParticipantList) {
            if (policyParticipant.InsurancePolicyId == bestPolicyOption.Id) {
                bestPolicyParticipant = policyParticipant;
            }
        }

        // Get the Coverage Participants
        ARC_CoverageParticipant__c coverageParticipant = [
            SELECT Id
            FROM ARC_CoverageParticipant__c
            WHERE ARC_PolicyParticipant__c = :bestPolicyParticipant.Id
            AND ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode LIKE '%Premier%'
            AND ARC_Policy__c = :bestPolicyOption.Id
            LIMIT 1
        ];

        // Return the best Policy Id
        if (accountRecord.vlocity_ins__Age__pc >= 18 && coverageParticipant != null) displayComponent = true;
        output.put('coverageParticipantId', coverageParticipant != null ? coverageParticipant.Id : null);
        output.put('displayComponent', displayComponent);
        return output;
    }

    private static Integer getPriority(InsurancePolicy p) {
        if (p.ARC_PolicyStatus__c == 'Activated') return 1;
        if (p.ARC_PolicyStatus__c == 'Terminated') return 2;
        if (p.ARC_PolicyStatus__c.contains('Awaiting')) return 3;
        return 99;
    }
}