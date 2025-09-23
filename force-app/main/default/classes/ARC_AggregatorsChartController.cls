public with sharing class ARC_AggregatorsChartController {
    @AuraEnabled
    public static Map<String, Object> getAllData(String recordId) {
        List<Id> policies = new List<Id>();
        String sObjName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
        Map<String, Object> output = new Map<String, Object>();
        List<ARC_Aggregator__c> aggregators = new List<ARC_Aggregator__c>();
        Set<Id> memberIds = new Set<Id>();
        InsurancePolicy recordPolicy;
        List<InsurancePolicyParticipant> polparticipants;

        if (sObjName == 'InsurancePolicy') {
            recordPolicy = [SELECT Id,ARC_Contract__r.ARC_ContractReason__c, RenewedFromPolicyId, ARC_PolicyReason__c,RenewedFromPolicy.ARC_Contract__r.Status, PriorPolicy.ARC_Contract__r.Status, PriorPolicyId FROM InsurancePolicy WHERE Id = :Id.valueOf(recordId) LIMIT 1];

        } else if (sObjName == 'Claim') {
            Claim clm = [SELECT PolicyNumber.RenewedFromPolicyId, PolicyNumberId, ARC_DOSFrom__c, ARC_MemberContact__r.AccountId FROM Claim WHERE Id = :Id.valueOf(recordId) LIMIT 1];
            recordPolicy = [SELECT Id,ARC_Contract__r.ARC_ContractReason__c, RenewedFromPolicyId, ARC_PolicyReason__c,RenewedFromPolicy.ARC_Contract__r.Status, PriorPolicy.ARC_Contract__r.Status, PriorPolicyId FROM InsurancePolicy WHERE Id = :clm.PolicyNumberId LIMIT 1];
            Integer clmYear = clm?.ARC_DOSFrom__c?.year();
            output.put('clmYear', clmYear);
            output.put('clmAccount', clm?.ARC_MemberContact__r?.AccountId);

        } else if (sObjName == 'Account') {
            Account personAcc = [SELECT Id, Census_Member__c FROM Account WHERE Id = :Id.valueOf(recordId)];

            vlocity_ins__GroupCensusMember__c cm = [
                SELECT Name, Id, vlocity_ins__CensusId__c, vlocity_ins__ContactId__r.Name
                FROM vlocity_ins__GroupCensusMember__c
                WHERE vlocity_ins__ContactId__r.AccountId = :Id.valueOf(recordId) AND Id = :personAcc.Census_Member__c
                LIMIT 1
            ];

            List<InsurancePolicy> active_policies_query_result = [
                SELECT Name, Id,ARC_Contract__r.ARC_ContractReason__c, RenewedFromPolicyId, ARC_PolicyReason__c, RenewedFromPolicy.ARC_Contract__r.Status, PriorPolicy.ARC_Contract__r.Status, PriorPolicyId
                FROM InsurancePolicy
                WHERE ARC_isActive__c = true AND ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c = :cm.vlocity_ins__CensusId__c
                AND ARC_Contract__r.Status != 'Voided'
                ORDER BY CreatedDate DESC
            ];

            if(active_policies_query_result.isEmpty() == false){ // If the first query is not empty
                recordPolicy = active_policies_query_result[0];
                output.put('accountPolicy', 'isActive');
            } else if (active_policies_query_result == null || active_policies_query_result.isEmpty()){ // If the first query is empty, tries the second option
                active_policies_query_result = [
                    SELECT Name, Id,ARC_Contract__r.ARC_ContractReason__c, RenewedFromPolicyId, ARC_PolicyReason__c, RenewedFromPolicy.ARC_Contract__r.Status, PriorPolicy.ARC_Contract__r.Status, PriorPolicyId
                    FROM InsurancePolicy
                    WHERE ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c = :cm.vlocity_ins__CensusId__c
                    AND ARC_Contract__r.Status != 'Voided'
                    ORDER BY ARC_EffectiveDate__c DESC
                ];
                output.put('accountPolicy', 'lastCreated');
                if (active_policies_query_result.isEmpty() == false)
                    recordPolicy = active_policies_query_result[0];
            } 
        }

        polparticipants = [SELECT Id, PrimaryParticipantContact.AccountId, InsurancePolicyId FROM InsurancePolicyParticipant WHERE InsurancePolicyId = :recordPolicy.Id];

        for (InsurancePolicyParticipant polpart : polparticipants){
            memberIds.add(polpart.PrimaryParticipantContact?.AccountId);
        }

        // Ternary Expression: Get the policy from which the current policy was renewed from policy if it exists, or just the record policy if it does not exist or it is voided.
        Id policy_id;

        Boolean is_upgrade =
        recordPolicy.ARC_Contract__r.ARC_ContractReason__c.containsIgnoreCase('New Application') ||
        recordPolicy.ARC_Contract__r.ARC_ContractReason__c.containsIgnoreCase('Program Upgrade') ||
        recordPolicy.ARC_Contract__r.ARC_ContractReason__c.containsIgnoreCase('Upgraded Spin Off');

        if (is_upgrade) {
            policy_id = recordPolicy.Id;
        }
        else if (is_upgrade == false && recordPolicy.RenewedFromPolicyId != null){
            policy_id = recordPolicy.RenewedFromPolicyId;
        }

        policies.add(policy_id);
        if (!policies.isEmpty())
            aggregators = [
                SELECT
                    Id,
                    Name,
                    ARC_CreatedIn__c,
                    ARC_CurrentValue__c,
                    ARC_FamilyCurrentValue__c,
                    ARC_LimitValue__c,
                    ARC_Year__c,
                    ARC_Type__c,
                    ARC_Member__c,
                    ARC_Member__r.Name,
                    ARC_Member__r.ARC_DependentRelationship__c,
                    RecordType.Name,
                    ARC_NextAvailabilityDate__c,
                    ARC_Code__c,
                    ARC_BY1_Date__c,
                    ARC_BY1_Current__c,
                    ARC_BY1_Limit__c,
                    ARC_BY2_Date__c,
                    ARC_BY2_Current__c,
                    ARC_BY2_Limit__c,
                    ARC_BY3_Date__c,
                    ARC_BY3_Current__c,
                    ARC_BY3_Limit__c
                FROM ARC_Aggregator__c
                WHERE ARC_CreatedIn__c IN :policies AND (ARC_Member__c IN :memberIds OR RecordType.Name = 'Family')
                LIMIT 1000
            ];
        output.put('object', sObjName);
        output.put('aggregators', aggregators);
        return output;
    }
}