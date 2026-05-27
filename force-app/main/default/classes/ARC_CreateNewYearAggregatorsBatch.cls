global class ARC_CreateNewYearAggregatorsBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Integer year;
    private List<String> newAggregatorsList = new List<String>{'CBIPAP__c', 'GENINJ__c', 'STDINJ__c', 'NONINJ__c', 'SPEINJ__c', 'BOSCR__c', 'WOVIS__c', 'SHINVAC__c'};
    private List<String> onetimeList = new List<String>{'CCS__c', 'MAMM__c', 'PROSCRE__c', 'FLXSIG__c', 'CLON__c', 'SSOPT__c', 'BOSCR__c', 'WOVIS__c'};
    private List<String> lifetimeList = new List<String>{'ALGTEST__c', 'SHINVAC__c'};
    private List<String> effectiveYearList = new List<String>{'PREEX__c', 'MAT__c'};

    private Integer familyAggInsertedCounter = 0;
    private Integer individualAggInsertedCounter = 0;
    private Integer partAggInsertedCounter = 0;
    
    global ARC_CreateNewYearAggregatorsBatch(Integer year) {
        this.year = year;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM InsurancePolicy';
        // Add any necessary filtering to the query
        query += ' WHERE ARC_Contract__r.Status = \'Activated\'';
        // query += ' AND Id = \'0YTU90000004VDJOA2\''; // Policy Id filter for testing
        // query += ' AND (Id = \'0YTU90000004Z5dOAE\' OR Id = \'0YTU90000004VDJOA2\')'; // Policy Id filter for testing
        query += ' ORDER BY ARC_Contract__r.ActivatedDate ASC';
        System.debug('Query: ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<InsurancePolicy> input) {
        Map<String, ARC_Aggregator__c> familyAggToInsertMap = new Map<String, ARC_Aggregator__c>(); // Key: policyId
        Map<String, ARC_Aggregator__c> individualAggToInsertMap = new Map<String, ARC_Aggregator__c>(); // Key: aggregatorKey (policyId-aggregatorName-accountId)
        Map<String, ARC_ParticipantAggregator__c> partAggToInsertMap = new Map<String, ARC_ParticipantAggregator__c>(); // Key: ParticipantAggKey (policyId-aggregatorName-participantId)
        try {
            Set<Id> policyIds = new Set<Id>();
            for (InsurancePolicy policy : input) {
                policyIds.add(policy.Id);
            }
            List<InsurancePolicy> policies = [
                SELECT Id, Product.ProductCode, NameInsuredId,
                    (SELECT Id, PrimaryParticipantContact.AccountId, ARC_StartDate__c FROM InsurancePolicyParticipants)
                FROM InsurancePolicy
                WHERE Id IN: policyIds
                ORDER BY ARC_Contract__r.ActivatedDate ASC
            ];

            Id familyAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Family').getRecordTypeId();
            Id individualAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();

            // Map to link Participant Aggregator to Aggregator (Key: partAggKey, Value: aggKey)
            Map<String, String> partAggKeyToAggKeyMap = new Map<String, String>();

            // Family AMCS
            for (InsurancePolicy policy : policies) {
                ARC_ProductAggregators__mdt aggValues = ARC_ProductAggregators__mdt.getInstance(policy.Product.ProductCode);
                for (Schema.SObjectField expectedAggregator : getAggregatorsFields(aggValues)) {
                    if (!isFamilyAggregator(expectedAggregator) || aggValues.get(expectedAggregator) == null) continue;
                    String aggCode = getAggregatorCode(expectedAggregator);
                    String aggregatorName = expectedAggregator.getDescribe().getLabel();

                    // New Family Aggregator
                    ARC_Aggregator__c famAgg = new ARC_Aggregator__c();
                    famAgg.RecordTypeId = familyAggRT;
                    famAgg.Name = aggregatorName;
                    famAgg.ARC_Year__c = String.valueOf(year);
                    famAgg.ARC_CreatedIn__c = policy.Id;
                    famAgg.ARC_FamilyCurrentValue__c = 0;
                    famAgg.ARC_LimitValue__c = Double.valueOf((Double)aggValues.get(expectedAggregator));
                    famAgg.ARC_Member__c = policy.NameInsuredId; // Group account
                    // famAgg.ARC_Code__c = aggCode;
                    // famAgg.ARC_Type__c = getAggregatorType(aggCode);
                    familyAggToInsertMap.put(policy.Id, famAgg);
                }
            }

            // Insert Family AMCS
            if (!familyAggToInsertMap.isEmpty()) {
                insert familyAggToInsertMap.values();
                familyAggInsertedCounter += familyAggToInsertMap.size();
            }

            // Individual AMCS
            for (InsurancePolicy policy : policies) {
                ARC_ProductAggregators__mdt aggValues = ARC_ProductAggregators__mdt.getInstance(policy.Product.ProductCode);
                System.debug('Agg values: ' + aggValues);
                for (Schema.SObjectField expectedAggregator : getAggregatorsFields(aggValues)) {
                    System.debug('expectedAggregator ' + expectedAggregator);
                    if (!isIndividualAggregator(expectedAggregator) || aggValues.get(expectedAggregator) == null || (isLifetimeOrOnetimeAggregator(expectedAggregator) && !newAggregatorsList.contains(getAggregatorCode(expectedAggregator))) || (newAggregatorsList.contains(String.valueOf(expectedAggregator)) && year < 2026)) continue;
                    String aggregatorName = expectedAggregator.getDescribe().getLabel();
                    System.debug('aggregatorName ' + aggregatorName);
                    String aggCode = getAggregatorCode(expectedAggregator);
                    Boolean needToLinkIndToFam = aggValues.get('FAM_AMCS__c') != null; // Only link IND AMCS to FAM AMCS if FAM AMCS exists for the product
                    for (InsurancePolicyParticipant participant : policy.InsurancePolicyParticipants) {
                        if (participant.PrimaryParticipantContact == null) continue; // Skip if missing contact information
                        System.debug('participant ' + participant);
                        String accountId = participant.PrimaryParticipantContact.AccountId;
    
                        // New Participant Aggregator
                        String partAggKey = policy.Id + '-' + aggregatorName + '-' + participant.Id;
                        ARC_ParticipantAggregator__c newPartAgg = new ARC_ParticipantAggregator__c();
                        newPartAgg.Name = aggregatorName;
                        newPartAgg.ARC_ConsumedValue__c = 0;
                        newPartAgg.ARC_Policy__c = policy.Id;
                        newPartAgg.ARC_PolicyParticipant__c = participant.Id;
                        partAggToInsertMap.put(partAggKey, newPartAgg);
                        
                        // New Aggregator
                        String aggKey = policy.Id + '-' + aggregatorName + '-' + accountId;
                        ARC_Aggregator__c newAgg = new ARC_Aggregator__c();
                        newAgg.RecordTypeId = individualAggRT;
                        newAgg.Name = aggregatorName;
                        newAgg.ARC_LimitValue__c = Double.valueOf((Double)aggValues.get(expectedAggregator));
                        newAgg.ARC_Code__c = aggCode;
                        newAgg.ARC_Type__c = getAggregatorType(aggCode);
                        newAgg.ARC_Member__c = accountId;
                        newAgg.ARC_CreatedIn__c = policy.Id;
                        newAgg.ARC_Year__c = !isLifetimeOrOnetimeAggregator(expectedAggregator) ? String.valueOf(year) : null;
                        newAgg.ARC_NextAvailabilityDate__c = onetimeList.contains(getAggregatorCode(expectedAggregator)) ? participant.ARC_StartDate__c : null;
                        if (aggCode == 'AMCS__c' && needToLinkIndToFam) newAgg.ARC_FamilyAggregator__c = familyAggToInsertMap.get(policy.Id).Id; // Link IND AMCS to FAM AMCS
                        individualAggToInsertMap.put(aggKey, newAgg);

                        // Map Participant Agg Key to Agg Key for later linking
                        partAggKeyToAggKeyMap.put(partAggKey, aggKey);
                    }
                }
            }

            // Insert Individual Aggregators
            if (!individualAggToInsertMap.isEmpty()) {
                insert individualAggToInsertMap.values();
                individualAggInsertedCounter += individualAggToInsertMap.size();
            }

            // Link Participant Aggregators to Individual Aggregators and then insert Participant Aggregators
            if (!partAggToInsertMap.isEmpty()) {
                for (String partAggKey : partAggToInsertMap.keySet()) {
                    String aggKey = partAggKeyToAggKeyMap.get(partAggKey);
                    ARC_ParticipantAggregator__c partAgg = partAggToInsertMap.get(partAggKey);
                    partAgg.ARC_Aggregator__c = individualAggToInsertMap.get(aggKey).Id;
                    partAggToInsertMap.put(partAggKey, partAgg); // Put back updated partAgg with linked agg Id
                }
                insert partAggToInsertMap.values();
                partAggInsertedCounter += partAggToInsertMap.size();
            }
        } catch (Exception e) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{
                    'ignacio.ferreiro@arcsona.com',
                    'agustin.garay@arcsona.com'
                    // 'nicolas.christophersen@arcsona.com'
                }); 
                mail.setSubject('Apex Exception Occurred');
                mail.setPlainTextBody('Exception: ' + e.getMessage() + '\nStack Trace:\n' + e.getStackTraceString());
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        }

    }
    
    global void finish(Database.BatchableContext BC) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{
            'nicolas.christophersen@arcsona.com'
        }); 
        mail.setSubject('Batch Process Completed Successfully');
        String body;
        body = 'The ARC_CreateNewYearAggregatorsBatch batch process has completed successfully for year ' + year + '.';
        body += '\n\nFamily Aggregators Created: ' + String.valueOf(familyAggInsertedCounter);
        body += '\nIndividual Aggregators Created: ' + String.valueOf(individualAggInsertedCounter);
        body += '\nParticipant Aggregators Created: ' + String.valueOf(partAggInsertedCounter);
        mail.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }


    // UTILITY METHODS //

    private List<Schema.SObjectField> getAggregatorsFields(ARC_ProductAggregators__mdt aggValues) {
        return aggValues.getSObjectType().getDescribe().fields.getMap().values();
    }

    private String getAggregatorCode(Schema.SObjectField aggregatorField) {
        String fullFieldCode = String.valueOf(aggregatorField);
        if (fullFieldCode.startsWith('IND_') || fullFieldCode.startsWith('FAM_')) {
            return fullFieldCode.substring(4);
        } else {
            return fullFieldCode;
        }
    }

    private String getAggregatorType(String aggregatorCode) {
        // String aggregatorCode = getAggregatorCode(aggregatorField);
        String aggregatorType;
        switch on aggregatorCode {
            when 'ACC__c', 'HTERAPHPY__c', 'CHIRO__c', 'OFUC__c', 'PHYTH__c', 'CCS__c', 'MAMM__c', 'PROSCRE__c', 'FLXSIG__c', 'CLON__c', 'SSOPT__c', 'PSYCH__c', 'GENINJ__c', 'STDINJ__c', 'NONINJ__c', 'SPEINJ__c', 'BOSCR__c', 'WOVIS__c', 'SHINVAC__c' {
                aggregatorType = 'Number';
            }
            when 'AMCS__c', 'PREEX__c', 'SHAMCS__c', 'TOB__c', 'ALGTEST__c', 'DME__c', 'MAT__c', 'CONGBIRTH__c', 'CBIPAP__c' {
                aggregatorType = 'Currency';
            }
        }
        return aggregatorType;
    }

    private Boolean isFamilyAggregator(Schema.SObjectField aggregatorField) {
        return String.valueOf(aggregatorField).startsWith('FAM_');
    }

    private Boolean isIndividualAggregator(Schema.SObjectField aggregatorField) {
        return String.valueOf(aggregatorField).startsWith('IND_');
    }

    private Boolean isLifetimeOrOnetimeAggregator(Schema.SObjectField aggregatorField) {
        String aggregatorCode = getAggregatorCode(aggregatorField);
        Boolean isLifetimeOrOnetime = false;
        if (onetimeList.contains(aggregatorCode) || lifetimeList.contains(aggregatorCode)) isLifetimeOrOnetime = true;
        return isLifetimeOrOnetime;
    }
    
}