public without sharing class ARC_PolicyUtilities {

    public static Id FAMILY_AGGREGATOR_RECORD_TYPE_ID;

    public ARC_PolicyUtilities(){
        FAMILY_AGGREGATOR_RECORD_TYPE_ID = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Family').getRecordTypeId();
    }

    public static Boolean validation_policy_is_upgrade(InsurancePolicy policy){
        if (new List<String>{'New Application', 'Program Upgrade', 'Upgraded Spin Off'}.contains(policy.ARC_Contract__r.ARC_ContractReason__c)) {
            return true;
        } else {
            return false;
        }
    }

    public static Map<String, ARC_Aggregator__c> create_family_aggregators_for_upgrade_policy(InsurancePolicy policy){
        ARC_ProductAggregators__mdt aggregator_metadata = ARC_AggregatorUtilities.get_product_aggregators_metadata(policy.Product.ProductCode);
        List<Schema.SObjectField> aggregator_fields_metadata = aggregator_metadata.getSObjectType().getDescribe().fields.getMap().values();
        Map<String,ARC_Aggregator__c> family_aggregators_map = new Map<String,ARC_Aggregator__c>();

        for (Schema.SObjectField field : aggregator_fields_metadata) {
            String api_name = String.valueOf(field);
            String name = field.getDescribe().getLabel(); 
            Double value = Double.valueOf(aggregator_metadata.get(field));
            String year = String.valueOf(policy.ARC_EffectiveDate__c.year());
            Id family_record_type_id = FAMILY_AGGREGATOR_RECORD_TYPE_ID;
            Id policy_id = policy.Id;

            if (api_name.startsWith('FAM_') && value != null) {
                ARC_Aggregator__c family_aggregator = ARC_AggregatorUtilities.create_family_aggregator_object(name, value, year, family_record_type_id, policy_id);
                family_aggregators_map.put(api_name, family_aggregator);
            }
        }

        return family_aggregators_map;
    }

    public static Map<ARC_Aggregator__c,ARC_Aggregator__c> create_individual_aggregators_for_upgrade_policy(InsurancePolicy policy, Map<String, ARC_Aggregator__c> family_aggregators){
        ARC_ProductAggregators__mdt aggregator_metadata = ARC_AggregatorUtilities.get_product_aggregators_metadata(policy.Product.ProductCode);
        List<Schema.SObjectField> aggregator_fields_metadata = aggregator_metadata.getSObjectType().getDescribe().fields.getMap().values();
        Map<ARC_Aggregator__c,ARC_Aggregator__c> individual_to_family_aggregators_map = new Map<ARC_Aggregator__c,ARC_Aggregator__c>();

        for (InsurancePolicyParticipant participant : policy.InsurancePolicyParticipants) {
            
            for (Schema.SObjectField field : aggregator_fields_metadata) {
                String api_name = String.valueOf(field);
                String name = field.getDescribe().getLabel(); 
                Double value = Double.valueOf(aggregator_metadata.get(field));
                String year = String.valueOf(policy.ARC_EffectiveDate__c.year());
                Id family_record_type_id = FAMILY_AGGREGATOR_RECORD_TYPE_ID;
                Id policy_id = policy.Id;
                Id participant_account_id = participant.PrimaryParticipantContact.AccountId;

                if (api_name.startsWith('IND_') && value != null) {
                    ARC_Aggregator__c individual_aggregator = ARC_AggregatorUtilities.create_individual_aggregator_object(name, value, year, family_record_type_id, policy_id, participant_account_id);
                    ARC_Aggregator__c family_aggregator_found = ARC_AggregatorUtilities.find_family_aggregator(api_name, family_aggregators);

                    if (family_aggregator_found != null) {
                        individual_to_family_aggregators_map.put(individual_aggregator, family_aggregator_found);
                    } else {
                        individual_to_family_aggregators_map.put(individual_aggregator, null);
                    }
                }
            }

        }

        return individual_to_family_aggregators_map;
    }

}