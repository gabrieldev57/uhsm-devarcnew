global class ARC_CreateParticipantAggregatorsBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id,
                    RenewedFromPolicyId,
                    RenewedFromPolicy.ARC_Contract__r.Status,
                    RenewedFromPolicy.ARC_Contract__r.ARC_ContractReason__c,
                    ARC_Contract__r.Status,
                    ARC_Contract__r.ARC_ContractReason__c,
                    Product.ProductCode,
                    (
                        SELECT Id
                        FROM ParticipantAggregators__r
                        WHERE ARC_Aggregator__r.ARC_Year__c = '2025'
                        OR ARC_Aggregator__r.ARC_Year__c = null
                    ),
                     // El order es importante aqui, para que el aggregator familiar se itere antes que el individual
                    (SELECT Id, InsurancePolicyId, PrimaryParticipantContact.AccountId FROM InsurancePolicyParticipants)
                FROM InsurancePolicy
                WHERE (ARC_Contract__r.Status = 'Activated'
                OR ARC_Contract__r.Status = 'Terminated')
                AND RenewedFromPolicyId != null
            ]
        );
    }

    global void execute(Database.BatchableContext BC, List<InsurancePolicy> insurance_policies) {
        // Aggregar los renew from ids a un set
        Set<Id> renewedFromIds = new Set<Id>();
        for (InsurancePolicy p : insurance_policies) {
            renewedFromIds.add(p.RenewedFromPolicyId);
        }

        List<ARC_Aggregator__c> renewfrom_aggregators = [
            SELECT Id,ARC_CreatedIn__c,Name
            FROM ARC_Aggregator__c
            WHERE (ARC_Year__c = '2025' OR ARC_Year__c = null)
            AND ARC_CreatedIn__c IN :renewedFromIds
        ];


        Map<String, Map<String,Id>> renewfromid_to_aggregatorname = new Map<String, Map<String,Id>>();
        for (ARC_Aggregator__c a : renewfrom_aggregators) {
            if (renewfromid_to_aggregatorname.containsKey(a.ARC_CreatedIn__c) == false) {
                renewfromid_to_aggregatorname.put(a.ARC_CreatedIn__c, new Map<String,Id>());
            }
            renewfromid_to_aggregatorname.get(a.ARC_CreatedIn__c).put(a.Name,a.Id);
        }

        List<ARC_ParticipantAggregator__c> participant_aggregators_to_insert = new List<ARC_ParticipantAggregator__c>();
        for (InsurancePolicy policy : insurance_policies) {
            String contract_reason = policy.ARC_Contract__r.ARC_ContractReason__c;
            if (
                contract_reason.containsIgnoreCase('New Application') == false &&
                contract_reason.containsIgnoreCase('Program Upgrade') == false &&
                contract_reason.containsIgnoreCase('Upgraded Spin Off') == false &&
                policy.ParticipantAggregators__r.isEmpty() == true
            ) {
                // Es carry over y no tiene participant aggregators
                ARC_ProductAggregators__mdt product_aggregators_mdt = ARC_ProductAggregators__mdt.getInstance(policy.Product.ProductCode);

                List<Schema.SObjectField> fields_metadata = product_aggregators_mdt.getSObjectType().getDescribe().fields.getMap().values();

                for (Schema.SObjectField field_mdt : fields_metadata) {
                    if (String.valueOf(field_mdt).startsWith('IND_') && product_aggregators_mdt.get(field_mdt) != null){

                        String aggregator_label = field_mdt.getDescribe().getLabel();

                        for (InsurancePolicyParticipant participant : policy.InsurancePolicyParticipants) {
                                ARC_ParticipantAggregator__c new_participant_aggregator = new ARC_ParticipantAggregator__c();
                                new_participant_aggregator.ARC_Policy__c = policy.Id;
                                new_participant_aggregator.ARC_ConsumedValue__c = 0;
                                new_participant_aggregator.ARC_PolicyParticipant__c = participant.Id;
                                if (renewfromid_to_aggregatorname.get(policy.RenewedFromPolicyId) != null && renewfromid_to_aggregatorname.get(policy.RenewedFromPolicyId).get(aggregator_label) != null) {
                                    new_participant_aggregator.ARC_Aggregator__c = renewfromid_to_aggregatorname.get(policy.RenewedFromPolicyId).get(aggregator_label);
                                }
                                new_participant_aggregator.Name = aggregator_label;
                                participant_aggregators_to_insert.add(new_participant_aggregator);
                        }
                    }
                }
            }
        }
        if (participant_aggregators_to_insert.size() > 0) {
            insert participant_aggregators_to_insert;
        }
    }

    global void finish(Database.BatchableContext BC) {
    }
}