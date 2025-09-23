global class ARC_CreatePartAggregatorsBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [
                SELECT Id
                FROM InsurancePolicy
                WHERE (ARC_Contract__r.Status = 'Activated' OR ARC_Contract__r.Status = 'Terminated')
                AND (ARC_ExpirationDate__c >= 2025-01-01 OR ARC_ExpirationDate__c = null)
            ]
        );
    }

    global void execute(Database.BatchableContext BC, List<InsurancePolicy> insurance_policies) {

        Set<Id> policyIds = new Map<Id, InsurancePolicy>(insurance_policies).keySet();

        insurance_policies = [
            SELECT
                Id,
                RenewedFromPolicyId,
                RenewedFromPolicy.ARC_Contract__r.Status,
                RenewedFromPolicy.ARC_Contract__r.ARC_ContractReason__c,
                ARC_Contract__r.ARC_ContractReason__c,
                // Verificar que no se crearon para 2025
                (
                    SELECT Id
                    FROM ParticipantAggregators__r
                    WHERE ARC_Aggregator__r.ARC_Year__c = '2025'
                ),
                // Para upgrade policies
                (
                    SELECT Id, Name, ARC_Member__c
                    FROM Aggregators__r
                    WHERE ARC_Year__c = '2025'
                )
            FROM InsurancePolicy
            WHERE (ARC_Contract__r.Status = 'Activated' OR ARC_Contract__r.Status = 'Terminated')
            AND (ARC_ExpirationDate__c >= 2025-01-01 OR ARC_ExpirationDate__c = null)
            AND Id IN: policyIds
        ];


        // Map policy - participant aggregator 2024 (carry over y upgrade)
        Map<Id, List<ARC_ParticipantAggregator__c>> old_participant_aggregators_by_policy = new Map<Id, List<ARC_ParticipantAggregator__c>>();
        List<InsurancePolicy> policyParticipantAggregatorList = [
            SELECT Id, 
                (SELECT Id, Name, ARC_PolicyParticipant__c, ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId
                FROM ParticipantAggregators__r 
                WHERE ARC_Aggregator__r.ARC_Year__c = '2024')
            FROM InsurancePolicy
            WHERE Id IN :policyIds
        ];
        for (InsurancePolicy policy : policyParticipantAggregatorList) {
            old_participant_aggregators_by_policy.put(policy.Id, policy.ParticipantAggregators__r);
        }

        // Aggregar los renew from ids a un set
        Set<Id> renewedFromIds = new Set<Id>();
        for (InsurancePolicy p : insurance_policies) {
            if (p.RenewedFromPolicyId != null) {
                renewedFromIds.add(p.RenewedFromPolicyId);
            }
        }

        List<ARC_Aggregator__c> renewfrom_aggregators = [
            SELECT Id, ARC_CreatedIn__c, Name, ARC_Member__c
            FROM ARC_Aggregator__c
            WHERE ARC_Year__c = '2025'
            AND ARC_CreatedIn__c IN :renewedFromIds
        ];

        // Map Policy to Aggregator Name to Account 2025
        Map<Id, Map<String, Map<Id,Id>>> policy_to_aggregatorname = new Map<Id, Map<String, Map<Id,Id>>>();
        for (ARC_Aggregator__c a : renewfrom_aggregators) {
            if (!policy_to_aggregatorname.containsKey(a.ARC_CreatedIn__c)) {
                policy_to_aggregatorname.put(a.ARC_CreatedIn__c, new Map<String, Map<Id,Id>>());
            }
            if (!policy_to_aggregatorname.get(a.ARC_CreatedIn__c).containsKey(a.Name)) {
                policy_to_aggregatorname.get(a.ARC_CreatedIn__c).put(a.Name, new Map<Id,Id>());
            }
            policy_to_aggregatorname.get(a.ARC_CreatedIn__c).get(a.Name).put(a.ARC_Member__c, a.Id);
        }
        for (InsurancePolicy policy : insurance_policies) {
            for (ARC_Aggregator__c a : policy.Aggregators__r) {
                if (!policy_to_aggregatorname.containsKey(policy.Id)) {
                    policy_to_aggregatorname.put(policy.Id, new Map<String, Map<Id,Id>>());
                }
                if (!policy_to_aggregatorname.get(policy.Id).containsKey(a.Name)) {
                    policy_to_aggregatorname.get(policy.Id).put(a.Name, new Map<Id,Id>());
                }
                policy_to_aggregatorname.get(policy.Id).get(a.Name).put(a.ARC_Member__c, a.Id);
            }
        }
        

        List<ARC_ParticipantAggregator__c> participant_aggregators_to_insert = new List<ARC_ParticipantAggregator__c>();
        for (InsurancePolicy policy : insurance_policies) {
            String contract_reason = policy.ARC_Contract__r.ARC_ContractReason__c;
            if (contract_reason != null) {
                Boolean isUpgrade = contract_reason.containsIgnoreCase('New Application') ||
                    contract_reason.containsIgnoreCase('Program Upgrade') ||
                    contract_reason.containsIgnoreCase('Upgraded Spin Off');
                if (!isUpgrade && policy.ParticipantAggregators__r.isEmpty() && policy.RenewedFromPolicyId != null && policy.RenewedFromPolicy.ARC_Contract__r.Status == 'Terminated') {
                    // Es carry over, no tiene participant aggregators 2025 y tiene un renewed policy terminated
                    // Clona participant aggregators del 2024
                    for (ARC_ParticipantAggregator__c partAgg : old_participant_aggregators_by_policy.get(policy.Id)) {
                        ARC_ParticipantAggregator__c new_participant_aggregator = new ARC_ParticipantAggregator__c();
                        if (
                            policy_to_aggregatorname.get(policy.RenewedFromPolicyId) != null
                            && policy_to_aggregatorname.get(policy.RenewedFromPolicyId).get(partAgg.Name) != null
                            && policy_to_aggregatorname.get(policy.RenewedFromPolicyId).get(partAgg.Name).get(partAgg.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId) != null
                        ){
                            new_participant_aggregator.ARC_Policy__c = policy.Id;
                            new_participant_aggregator.ARC_ConsumedValue__c = 0;
                            new_participant_aggregator.ARC_PolicyParticipant__c = partAgg.ARC_PolicyParticipant__c;
                            new_participant_aggregator.ARC_Aggregator__c = policy_to_aggregatorname.get(policy.RenewedFromPolicyId).get(partAgg.Name).get(partAgg.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId);
                            new_participant_aggregator.Name = partAgg.Name;
                            participant_aggregators_to_insert.add(new_participant_aggregator);
                        } 
                    }
                } else if (isUpgrade && policy.ParticipantAggregators__r.isEmpty()) {
                    // Es upgrade y no tiene participant aggregators 2025
                    // Clona participant aggregators del 2024
                    for (ARC_ParticipantAggregator__c partAgg : old_participant_aggregators_by_policy.get(policy.Id)) {
                        ARC_ParticipantAggregator__c new_participant_aggregator = new ARC_ParticipantAggregator__c();
                        if (
                            policy_to_aggregatorname.get(policy.Id) != null
                            && policy_to_aggregatorname.get(policy.Id).get(partAgg.Name) != null
                            && policy_to_aggregatorname.get(policy.Id).get(partAgg.Name).get(partAgg.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId) != null
                        ){
                            new_participant_aggregator.ARC_Policy__c = policy.Id;
                            new_participant_aggregator.ARC_ConsumedValue__c = 0;
                            new_participant_aggregator.ARC_PolicyParticipant__c = partAgg.ARC_PolicyParticipant__c;
                            new_participant_aggregator.ARC_Aggregator__c = policy_to_aggregatorname.get(policy.Id).get(partAgg.Name).get(partAgg.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId);
                            new_participant_aggregator.Name = partAgg.Name;
                            participant_aggregators_to_insert.add(new_participant_aggregator);
                        } 
                    }
                }
            }   
        }
        if (!participant_aggregators_to_insert.isEmpty()) {
            insert participant_aggregators_to_insert;
        }
    }

    global void finish(Database.BatchableContext BC) {
    }
}