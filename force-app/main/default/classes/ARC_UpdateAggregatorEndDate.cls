/*******************************************************************
* @ClassName          :   ARC_UpdateAggregatorEndDate
* @Description        :   Methods to calculate EndDate value for year != null aggregators, used in flows for automation.

********************************************************************/

public with sharing class ARC_UpdateAggregatorEndDate {

    /*******************************************************************
    * @MethodName         :   updateEndDate
    * @Description        :   Recieves a list of ARC_Aggregator__c Ids and stamps the EndDate values.
    * @Parameters         :   List<List<Id>> aggregatorIdList
    ********************************************************************/
    @InvocableMethod(label='Update Aggregators EndDate' description='Calculates the EndDate value per Aggregator')
    public static void updateEndDate(List<List<Id>> aggregatorIdList) {
        Set<Id> aggregatorIds = new Set<Id>();
        for (List<Id> aggList : aggregatorIdList) {
            if (aggList != null && !aggList.isEmpty()) {
                aggregatorIds.addAll(aggList);
            }
        }

        if (aggregatorIds.isEmpty()) return;

        List<ARC_Aggregator__c> aggregators = [
            SELECT Id, 
                   ARC_Year__c, 
                   ARC_EndDate__c,
                (SELECT Id, 
                        ARC_Aggregator__c,
                        ARC_Aggregator__r.Name,
                        ARC_Policy__r.ARC_Contract__r.RecordType.Name,
                        ARC_Policy__r.ARC_Contract__r.ARC_Inactive_Date__c, 
                        ARC_Policy__r.ARC_Contract__r.Status,
                        ARC_Policy__r.ARC_PolicyExpirationDate__c, 
                        ARC_Policy__r.Status
                FROM Participant_Aggregators__r
                WHERE
                    (
                        ARC_Policy__r.ARC_Contract__r.RecordType.Name = 'Individual and Family' 
                        AND
                        ARC_Policy__r.ARC_Contract__r.Status IN ('Activated', 'Terminated')
                    )
                    OR
                    (
                        ARC_Policy__r.ARC_Contract__r.RecordType.Name = 'Small Group'
                        AND ARC_Policy__r.Status IN ('Activated', 'Terminated')
                    )
                ORDER BY ARC_Policy__r.ARC_Contract__r.Status, ARC_Policy__r.Status DESC)
            FROM ARC_Aggregator__c
            WHERE Id IN :aggregatorIds
                AND ARC_Year__c != null
                AND RecordType.DeveloperName = 'Individual'
        ];

        Integer currentYear = Date.Today().year();

        List<ARC_Aggregator__c> aggregatorsToUpdate = new List<ARC_Aggregator__c>();
        Map<Id,Date> familyAggregatorToEndDate = new Map<Id,Date>();

        for (ARC_Aggregator__c agg : aggregators) {
            Integer aggYear = Integer.valueOf(agg.ARC_Year__c);

            Date currentEndDate = Date.newInstance(aggYear, 1, 1);
            for (ARC_ParticipantAggregator__c partAgg : agg.Participant_Aggregators__r) {
                System.debug('=====================================================');
                System.debug('Aggregator Name: ' + partAgg.ARC_Aggregator__r.Name);
                Date inactiveDate;
                String status;

                if (partAgg.ARC_Policy__r.ARC_Contract__r.RecordType.Name == 'Individual and Family') {
                    inactiveDate = partAgg.ARC_Policy__r.ARC_Contract__r.ARC_Inactive_Date__c;
                    status = partAgg.ARC_Policy__r.ARC_Contract__r.Status;
                    System.debug('Contract RT = Individual and Family');
                } else if (partAgg.ARC_Policy__r.ARC_Contract__r.RecordType.Name == 'Small Group') {
                    inactiveDate = partAGg.ARC_Policy__r.ARC_PolicyExpirationDate__c;
                    status = partAgg.ARC_Policy__r.Status;
                    System.debug('Contract RT = Small Group');
                }
                System.debug('Inactive Date: ' + inactiveDate);
                System.debug('Status: ' + status);

                if (status == 'Activated') {
                    if (currentYear > aggYear) {
                        currentEndDate = Date.newInstance(aggYear, 12, 31);
                        System.debug('Current End Date: ' + currentEndDate);
                    } else {
                        currentEndDate = null;
                        System.debug('Current End Date: ' + currentEndDate);
                    }
                    break;
                } else if (status == 'Terminated' && inactiveDate != null) {
                    if (aggYear == inactiveDate.year() && currentEndDate != null && inactiveDate > currentEndDate) {
                        currentEndDate = inactiveDate;
                    } else if (aggYear < inactiveDate.year() && currentEndDate != null && inactiveDate > currentEndDate) {
                        currentEndDate = Date.newInstance(aggYear, 12, 31);
                    }
                }
            }

            if (agg.ARC_EndDate__c != currentEndDate) {
                agg.ARC_EndDate__c = currentEndDate;
                aggregatorsToUpdate.add(agg);
            }
        }
        System.debug('Aggregators to update: ' + aggregatorsToUpdate);
        if (!aggregatorsToUpdate.isEmpty()) {
            update aggregatorsToUpdate;
        }
    }
}