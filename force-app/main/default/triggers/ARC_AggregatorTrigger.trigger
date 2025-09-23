trigger ARC_AggregatorTrigger on ARC_Aggregator__c (after delete) {
    if (trigger.isAfter && trigger.isDelete) {
        Set<Id> familyAggregatorIds = new Set<Id>();
        for (ARC_Aggregator__c agg : Trigger.old) {
            if (agg.ARC_FamilyAggregator__c != null) {
                familyAggregatorIds.add(agg.ARC_FamilyAggregator__c);
            }
        }
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
            if (aggregatorFamilyMap.get(agg.ARC_FamilyAggregator__c) == null) {
                aggregatorFamilyMap.put(agg.ARC_FamilyAggregator__c, new List<ARC_Aggregator__c>());
            }
            aggregatorFamilyMap.get(agg.ARC_FamilyAggregator__c).add(agg);
        }
        for (ARC_Aggregator__c aggFamily : familyAggregators) {
            Double currentValue = 0;
            if (aggregatorFamilyMap.get(aggFamily.Id) != null) {
                for (ARC_Aggregator__c aggIndividual : aggregatorFamilyMap.get(aggFamily.Id)) {
                    currentValue += aggIndividual.ARC_CurrentValue__c;
                }
            }
            if (currentValue > aggFamily.ARC_LimitValue__c) {
                aggFamily.ARC_FamilyCurrentValue__c = aggFamily.ARC_LimitValue__c;
            } else {
                aggFamily.ARC_FamilyCurrentValue__c = currentValue;
            }
        }
        update familyAggregators;
    }
}