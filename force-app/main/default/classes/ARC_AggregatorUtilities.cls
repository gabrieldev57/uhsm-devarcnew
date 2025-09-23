public without sharing class ARC_AggregatorUtilities {
    public static ARC_ProductAggregators__mdt get_product_aggregators_metadata(String product_code){
        return ARC_ProductAggregators__mdt.getInstance(product_code);
    }

    public static ARC_Aggregator__c create_family_aggregator_object(String name, Double value, String year, Id family_record_type_id, Id policy_id){
        ARC_Aggregator__c family_aggregator = new ARC_Aggregator__c(
            Name = name,
            ARC_LimitValue__c = value,
            ARC_Year__c = year,
            RecordTypeId = family_record_type_id,
            ARC_CreatedIn__c = policy_id
        );
        return family_aggregator;
    }

    public static ARC_Aggregator__c create_individual_aggregator_object(String name, Double value, String year, Id family_record_type_id, Id policy_id, Id participant_account_id){
        ARC_Aggregator__c family_aggregator = new ARC_Aggregator__c(
            Name = name,
            ARC_LimitValue__c = value,
            ARC_Year__c = year,
            RecordTypeId = family_record_type_id,
            ARC_CreatedIn__c = policy_id,
            ARC_Member__c = participant_account_id
        );
        return family_aggregator;
    }

    public static List<ARC_Aggregator__c> get_existing_aggregators(Set<Id> renewed_from_policy_ids){
        return [SELECT Id, Name, ARC_Year__c, ARC_Code__c, ARC_Member__c, RecordType.Name, ARC_CreatedIn__c,ARC_LimitValue__c FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c IN: renewed_from_policy_ids LIMIT 10000];
    }

    public static Map<Id,List<ARC_Aggregator__c>> map_aggregators_by_policy(List<ARC_Aggregator__c> aggregators){
        Map<Id, List<ARC_Aggregator__c>> policyid_aggregators_map = new Map<Id, List<ARC_Aggregator__c>>();
        for (ARC_Aggregator__c aggregator : aggregators) {
            Id policy_id = aggregator.ARC_CreatedIn__c;

            if (policyid_aggregators_map.containsKey(policy_id) == false) {
                policyid_aggregators_map.put(policy_id, new List<ARC_Aggregator__c>());
            }
            ((List<ARC_Aggregator__c>) policyid_aggregators_map.get(policy_id)).add(aggregator);
        }

        return policyid_aggregators_map;
    }

    public static ARC_Aggregator__c find_family_aggregator(String individual_aggregator_api, Map<String, ARC_Aggregator__c> family_aggregators){
        // Compares both api names FAM_AMCS__c IND_AMCS__c
        for (String family_aggregator_api : family_aggregators.keySet()) {
            if (family_aggregator_api.contains(individual_aggregator_api.substringAfter('IND_'))) {
                return family_aggregators.get(family_aggregator_api);
            }
        }
        return null;
    }
    // public static ARC_Aggregator__c find_existing_family_aggregator(InsurancePolicy policy){
    //     for (ARC_Aggregator__c aggregator : previous_policy_aggregators) {
    //         Boolean is_family_aggregator = aggregator.RecordType.Name == 'Family';
    //         Boolean same_year_as_policy = aggregator.ARC_Year__c == String.valueOf(policy.ARC_EffectiveDate__c.year());
    //         Boolean created_in_previous_policy = aggregator.ARC_CreatedIn__c == policy.RenewedFromPolicyId;
    //         if (is_family_aggregator && same_year_as_policy && created_in_previous_policy) {
    //             return aggregator;
    //         }
    //     }

    //     return null;
    // }
}