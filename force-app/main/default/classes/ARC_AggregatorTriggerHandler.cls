public with sharing class ARC_AggregatorTriggerHandler {
    public static void updateFamilyAggregatorsOnDelete(List<ARC_Aggregator__c> oldAggregatorsList) {
         Set<Id> familyAggregatorIds = new Set<Id>();
        for (ARC_Aggregator__c agg : oldAggregatorsList) {
            if (agg.ARC_FamilyAggregator__c != null) {
                familyAggregatorIds.add(agg.ARC_FamilyAggregator__c);
            }
        }

        if (familyAggregatorIds.isEmpty()) return;

        List<ARC_Aggregator__c> familyAggregators = [
            SELECT Id, ARC_FamilyCurrentValue__c, ARC_LimitValue__c
            FROM ARC_Aggregator__c
            WHERE Id IN: familyAggregatorIds
        ];
        List<ARC_Aggregator__c> aggregatorsRelated = [
            SELECT Id, ARC_CurrentValue__c, ARC_FamilyAggregator__c
            FROM ARC_Aggregator__c
            WHERE ARC_FamilyAggregator__c IN: familyAggregatorIds
        ];
        Map<Id, List<ARC_Aggregator__c>> aggregatorFamilyMap = new Map<Id, List<ARC_Aggregator__c>>();
        for (ARC_Aggregator__c agg : aggregatorsRelated) {
            if (!aggregatorFamilyMap.containsKey(agg.ARC_FamilyAggregator__c)) {
                aggregatorFamilyMap.put(agg.ARC_FamilyAggregator__c, new List<ARC_Aggregator__c>());
            }
            aggregatorFamilyMap.get(agg.ARC_FamilyAggregator__c).add(agg);
        }
        for (ARC_Aggregator__c aggFamily : familyAggregators) {
            Double currentValue = 0;
            if (aggregatorFamilyMap.containsKey(aggFamily.Id)) {
                for (ARC_Aggregator__c aggIndividual : aggregatorFamilyMap.get(aggFamily.Id)) {
                    currentValue += aggIndividual.ARC_CurrentValue__c;
                }
            }
            aggFamily.ARC_FamilyCurrentValue__c = currentValue;
        }
        update familyAggregators;
    }

    public static void updateParentAggregatorsOnDelete(List<ARC_Aggregator__c> oldAggregatorsList) {
         Set<Id> parentAggregatorIds = new Set<Id>();
        for (ARC_Aggregator__c agg : oldAggregatorsList) {
            if (agg.ARC_ParentAggregator__c != null) {
                parentAggregatorIds.add(agg.ARC_ParentAggregator__c);
            }
        }

        if (parentAggregatorIds.isEmpty()) return;
        
        List<ARC_Aggregator__c> parentAggregators = [
            SELECT Id, ARC_ParentCurrentValue__c, ARC_LimitValue__c
            FROM ARC_Aggregator__c
            WHERE Id IN: parentAggregatorIds
        ];
        List<ARC_Aggregator__c> aggregatorsRelated = [
            SELECT Id, ARC_CurrentValue__c, ARC_ParentAggregator__c
            FROM ARC_Aggregator__c
            WHERE ARC_ParentAggregator__c IN: parentAggregatorIds
        ];
        Map<Id, List<ARC_Aggregator__c>> aggregatorParentMap = new Map<Id, List<ARC_Aggregator__c>>();
        for (ARC_Aggregator__c agg : aggregatorsRelated) {
            if (!aggregatorParentMap.containsKey(agg.ARC_ParentAggregator__c)) {
                aggregatorParentMap.put(agg.ARC_ParentAggregator__c, new List<ARC_Aggregator__c>());
            }
            aggregatorParentMap.get(agg.ARC_ParentAggregator__c).add(agg);
        }
        for (ARC_Aggregator__c aggParent : parentAggregators) {
            Double currentValue = 0;
            if (aggregatorParentMap.containsKey(aggParent.Id)) {
                for (ARC_Aggregator__c aggIndividual : aggregatorParentMap.get(aggParent.Id)) {
                    currentValue += aggIndividual.ARC_CurrentValue__c;
                }
            }
            aggParent.ARC_ParentCurrentValue__c = currentValue;
        }
        update parentAggregators;
    }
}