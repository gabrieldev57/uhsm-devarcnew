/*******************************************************************
 * @ClassName          :   ARC_CreateMissingAggregatorsNoLimit
 * @Description        :   Batchable Apex class that detects if a ParticipantAggregator is missing, and its corresponding Aggregator
 *                         ***DOES NOT CONSIDER EXCEEDING LIMIT VALUE***
 *                         ***NEEDS THAT VR FOR AGGREGATORS EXCEEDING LIMITS DEACTIVATED***
 *                         In case of having missing records they are created
 *                         Upserts the existing aggregators: in case of being changes in the limit values (according to the latest policy for a participant), limit values will be updated. 
 *                          Limit value for 'Maternity' and 'Pre Exisitng Condition' aggregators are not updated.
 *                         - Batch execution can be run to update or create any missing aggregators on the queried Policies. 
 ********************************************************************/
global class ARC_CreateMissingAggregatorsNoLimit implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    private String whereClause;
    private Boolean shouldCreateMissingAggregators = false;
    private Boolean isScheduled = false;
    private Set<Id> missingCongenitalBirth = new Set<Id>();
    private Integer missingParticipantAggregatorsCounter = 0;
    private Integer missingRecordsEarlyYearsCounter = 0;
    private Integer missingAggregatorsCounter = 0;
    private Set<Id> aggregatorsExceedingLimit = new Set<Id>();
    private Set<Id> policiesWithMissingPartAggSet = new Set<Id>(); 
    private Integer partAggToBeInsertedCounter = 0;
    private Integer partAggInsertedCounter = 0;
    private List<String> partAggNotInsertedList = new List<String>();
    private Set<Id> policiesVoidedExceptions = new Set<Id>();
    private Set<Id> policyParticipantsMissingInformation = new Set<Id>();
    private Set<Id> aggregatorsMissingPolicy = new Set<Id>();
    private Set<Id> aggregatorsWrongPolicy = new Set<Id>();
    private Set<Id> aggregatorsMisslabeled = new Set<Id>();
    private Set<Id> noRelatedPoliciesFound = new Set<Id>();
    private Set<Id> familyAggregatorsMissingIndividual = new Set<Id>();
    private Set<Id> policiesFromPreviousYears = new Set<Id>();
    private Integer partAggregatorsFromPreviousYearsCounter = 0;
    
        /*********************************************************************************************************     * 
     * @name            ARC_CreateMissingAggregatorsNoLimit     * 
     * @description     Batch can be executed on demand for any set of policies that fulfill the WHERE clause . 
     *                  isScheduled flag will be set in false and the user WILL recieve the report by email. (flag is not an input parameter)
     *                  - whereClause: can be set as an input param.
     *                  - shouldCreateMissingAggregators if set to FALSE will NOT upsert records, 
     *                    generating the report without making any changes in the org.
     *                  EXAMPLE:
     *                  ARC_CreateMissingAggregatorsNoLimit batch = new ARC_CreateMissingAggregatorsNoLimit('Id = \'XXXXX\')', false);
                        Database.executeBatch(batch, 100); --> use batch 100 on large sets of policies to avoid DML limits * 
     * @param           String whereClause   * 
     * @param           Boolean shouldCreateMissingAggregators   * 
     * *********************************************************************************************************/
    global ARC_CreateMissingAggregatorsNoLimit(String whereClause, Boolean shouldCreateMissingAggregators) {
        this.whereClause = whereClause;
        this.shouldCreateMissingAggregators = shouldCreateMissingAggregators;
    }

    global ARC_CreateMissingAggregatorsNoLimit() {
        this.whereClause = whereClause;
        this.shouldCreateMissingAggregators = shouldCreateMissingAggregators;
    }

    /*********************************************************************************************************     * 
     * @name            execute     * 
     * @description     Executes daily for policies activated or reactivated on that date. 
     *                  isScheduled flag will prevent report email to be sent. 
     *                  shouldCreateMissingAggregators = true will enable the upsert of necessary aggregators* 
     * @param           SchedulableContext     * 
     * *********************************************************************************************************/
    global void execute(SchedulableContext SC) {
        this.whereClause = '(ARC_Contract__r.ActivatedDate = TODAY OR ARC_Contract__r.ARC_Reactivated__c = TODAY) AND ARC_Contract__r.Status != \'Voided\'';
        this.shouldCreateMissingAggregators = true;
        this.isScheduled = true;

        Database.executeBatch(this, 100);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM InsurancePolicy';
        if (this.whereClause != null) {
            query += ' WHERE ' + this.whereClause;
        } else {
            query += ' WHERE ARC_Contract__r.Status = \'Activated\' OR ARC_Contract__r.Status = \'Terminated\'';
            query += ' ORDER BY ARC_Contract__r.ActivatedDate ASC';
        }
        return Database.getQueryLocator(query);
    }


    global void execute(Database.BatchableContext BC, List<InsurancePolicy> input) {
        Set<Id> policyIds = new Set<Id>();
        for (InsurancePolicy pol : input) {
            policyIds.add(pol.Id);
        }
        List<InsurancePolicy> policies = [
            SELECT Id, RenewedFromPolicyId, ARC_PolicyReason__c, Product.ProductCode, ARC_EffectiveDate__c, ARC_ExpirationDate__c,
                (SELECT Id, PrimaryParticipantContact.AccountId, PrimaryParticipantContact.Birthdate
                FROM InsurancePolicyParticipants)
            FROM InsurancePolicy
            WHERE Id IN: policyIds
            ORDER BY ARC_Contract__r.ActivatedDate ASC
        ];
        
        Set<Id> renewedFromPolicyIds = new Set<Id>();
        for (InsurancePolicy policy : policies) {
            if (policy.RenewedFromPolicyId != null) {
                renewedFromPolicyIds.add(policy.RenewedFromPolicyId);
            }
        }
        List<ARC_Aggregator__c> aggregators = [
            SELECT Id, Name, ARC_Member__c, ARC_Year__c, RecordTypeId, ARC_CurrentValue__c, ARC_LimitValue__c, ARC_FamilyAggregator__c, ARC_FamilyCurrentValue__c, ARC_CreatedIn__c
            FROM ARC_Aggregator__c
            WHERE ARC_CreatedIn__c IN: policyIds OR ARC_CreatedIn__c IN: renewedFromPolicyIds
        ];

        Id familyAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Family').getRecordTypeId();
        Id individualAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();

        // Key: policyId-name-year-participantAccount
        Map<String, ARC_Aggregator__c> individualAggMap = new Map<String, ARC_Aggregator__c>();
        // Key: policyId-year
        Map<String, ARC_Aggregator__c> familyAggMap = new Map<String, ARC_Aggregator__c>();

        for (ARC_Aggregator__c agg : aggregators) {
            String key;
            if (agg.RecordTypeId == individualAggRT) {
                key = agg.ARC_CreatedIn__c + '-' + agg.Name;
                if (agg.ARC_Year__c != null) {
                    key += '-' + agg.ARC_Year__c;
                } else {
                    key += '-null';
                }
                if (agg.ARC_Member__c != null) {
                    key += '-' + agg.ARC_Member__c;
                } else {
                    key += '-null';
                }
                individualAggMap.put(key, agg);
            } else if (agg.RecordTypeId == familyAggRT) {
                key = agg.ARC_CreatedIn__c;
                if (agg.ARC_Year__c != null) {
                    key += '-' + agg.ARC_Year__c;
                    familyAggMap.put(key, agg);
                }
            }
        }

        List<ARC_ParticipantAggregator__c> partAggregators = [
            SELECT Id, Name, ARC_Aggregator__c, ARC_PolicyParticipant__c, ARC_Policy__c, ARC_Aggregator__r.ARC_Year__c, ARC_Aggregator__r.ARC_CreatedIn__c, ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId
            FROM ARC_ParticipantAggregator__c
            WHERE ARC_Policy__c IN: policyIds
        ];
        // Key: policyId-name-year-participant
        Map<String, ARC_ParticipantAggregator__c> existingPartAggMap = new Map<String, ARC_ParticipantAggregator__c>();
        for (ARC_ParticipantAggregator__c partAgg : partAggregators) {
            String key = partAgg.ARC_Policy__c + '-' + partAgg.Name;
            if (partAgg.ARC_Aggregator__r.ARC_Year__c != null) {
                key += '-' + partAgg.ARC_Aggregator__r.ARC_Year__c;
            } else {
                key += '-null';
            }
            if (partAgg.ARC_PolicyParticipant__c != null) {
                key += '-' + partAgg.ARC_PolicyParticipant__c;
            } else {
                key += '-null';
            }
            existingPartAggMap.put(key, partAgg);
        }
        // Map with Participant Aggregator Key (unique), and its Aggregator Key to be linked to the corresponding Aggregator
        Map<String, String> partAggKeyToAggKey = new Map<String, String>();
        Map<String, ARC_ParticipantAggregator__c> partAggToInsert = new Map<String, ARC_ParticipantAggregator__c>();

        // Related carry-over policies
        List<InsurancePolicy> policiesRenewedFrom = [
            SELECT Id, RenewedFromPolicyId, Product.ProductCode, ARC_Contract__r.Status, ARC_Contract__r.ActivatedDate, ARC_Contract__r.ARC_Reactivated__c, ARC_EffectiveDate__c, ARC_ExpirationDate__c, ARC_PolicyReason__c,
                (SELECT Id, PrimaryParticipantContact.AccountId
                FROM InsurancePolicyParticipants)
            FROM InsurancePolicy
            WHERE (Id IN: policyIds OR RenewedFromPolicyId IN :policyIds) AND (ARC_Contract__r.Status = 'Activated' OR ARC_Contract__r.Status = 'Terminated')
        ];

        // Map for policies renewed from, for each participant per year
        // Used to select the correct LimitValue for Individual Aggregators
        // relatedPoliciesOfParticipantPerYearMap: RenewedPolicyId - AccountId - Year - List Policies
        Map<Id, Map<Id, Map<Integer, List<InsurancePolicy>>>> relatedPoliciesOfParticipantPerYearMap = new Map<Id, Map<Id, Map<Integer, List<InsurancePolicy>>>>();
        for (InsurancePolicy pol : policiesRenewedFrom) {
            Id polKey;
            if (isUpgradePolicy(pol.ARC_PolicyReason__c)) {
                polKey = pol.Id;
            } else {
                polKey = pol.RenewedFromPolicyId;
            }
            if (!relatedPoliciesOfParticipantPerYearMap.containsKey(polKey)) {
                relatedPoliciesOfParticipantPerYearMap.put(polKey, new Map<Id, Map<Integer, List<InsurancePolicy>>>());
            }
            Map<Id, Map<Integer, List<InsurancePolicy>>> participantYearPolicyMap = relatedPoliciesOfParticipantPerYearMap.get(polKey);
            for (InsurancePolicyParticipant participant : pol.InsurancePolicyParticipants) {
                Id partKey = participant.PrimaryParticipantContact.AccountId;
                if (!participantYearPolicyMap.containsKey(partKey)) {
                    participantYearPolicyMap.put(partKey, new Map<Integer, List<InsurancePolicy>>());
                }
                Map<Integer, List<InsurancePolicy>> yearPolicyMap = participantYearPolicyMap.get(partKey);
                Integer minYear = pol.ARC_EffectiveDate__c.year();
                Integer maxYear = pol.ARC_ExpirationDate__c == null ? Date.Today().year() : pol.ARC_ExpirationDate__c.year();
                for (Integer year = minYear; year <= maxYear; year++) {
                    if (!yearPolicyMap.containsKey(year)) {
                        yearPolicyMap.put(year, new List<InsurancePolicy>());
                    }
                    yearPolicyMap.get(year).add(pol);
                }
                if (pol.ARC_Contract__r.ARC_Reactivated__c != null) {
                    Integer reactivatedYear = pol.ARC_Contract__r.ARC_Reactivated__c.year();
                    for (Integer year = reactivatedYear; year <= Date.Today().year(); year++) {
                        if (!yearPolicyMap.containsKey(year)) {
                            yearPolicyMap.put(year, new List<InsurancePolicy>());
                        }
                        yearPolicyMap.get(year).add(pol);
                    }
                } 
            }
        }

        // Map for policies renewed from, for each participant
        // Used to select the correct LimitValue for Individual OneTime and LifeTime Aggregators
        // relatedPoliciesOfParticipantMap: RenewedPolicyId - Account - List Policies
        Map<Id, Map<Id, List<InsurancePolicy>>> relatedPoliciesOfParticipantMap = new Map<Id, Map<Id, List<InsurancePolicy>>>();
        for (InsurancePolicy pol : policiesRenewedFrom) {
            Id polKey;
            if (isUpgradePolicy(pol.ARC_PolicyReason__c)) {
                polKey = pol.Id;
            } else {
                polKey = pol.RenewedFromPolicyId;
            }
            if (!relatedPoliciesOfParticipantMap.containsKey(polKey)) {
                relatedPoliciesOfParticipantMap.put(polKey, new Map<Id, List<InsurancePolicy>>());
            }
            Map<Id, List<InsurancePolicy>> relatedPoliciesPerParticipantMap = relatedPoliciesOfParticipantMap.get(polKey);
            for (Id participant : relatedPoliciesOfParticipantPerYearMap.get(polKey).keySet()) {
                if (!relatedPoliciesPerParticipantMap.containsKey(participant)) {
                    relatedPoliciesPerParticipantMap.put(participant, new List<InsurancePolicy>());
                }
                List<InsurancePolicy> policyList = relatedPoliciesPerParticipantMap.get(participant);
                Map<Integer, List<InsurancePolicy>> yearPolicyMap = relatedPoliciesOfParticipantPerYearMap.get(polKey).get(participant);
                for (Integer year : yearPolicyMap.keySet()) {
                    policyList.addAll(yearPolicyMap.get(year));
                }
            }
        }

        // Map for policies renewed from
        // Used to select the correct LimitValue for Family AMCS
        // relatedPoliciesMap: RenewedPolicyId - Year - List Policies
        Map<Id, Map<Integer, List<InsurancePolicy>>> relatedPoliciesMap = new Map<Id, Map<Integer, List<InsurancePolicy>>>();
        for (InsurancePolicy pol : policiesRenewedFrom) {
            Id polKey;
            if (isUpgradePolicy(pol.ARC_PolicyReason__c)) {
                polKey = pol.Id;
            } else {
                polKey = pol.RenewedFromPolicyId;
            }
            if (!relatedPoliciesMap.containsKey(polKey)) {
                relatedPoliciesMap.put(polKey, new Map<Integer, List<InsurancePolicy>>());
            }
            Map<Integer, List<InsurancePolicy>> relatedPoliciesPerYearMap = relatedPoliciesMap.get(polKey);
            for (Id participant : relatedPoliciesOfParticipantPerYearMap.get(polKey).keySet()) {
                for (Integer year : relatedPoliciesOfParticipantPerYearMap.get(polKey).get(participant).keySet()) {
                    if (!relatedPoliciesPerYearMap.containsKey(year)) {
                        relatedPoliciesPerYearMap.put(year, new List<InsurancePolicy>());
                    }
                    List<InsurancePolicy> policyList = relatedPoliciesPerYearMap.get(year);
                    policyList.addAll(relatedPoliciesOfParticipantPerYearMap.get(polKey).get(participant).get(year));
                }
            }
        }

        // Family AMCS Missing
        String InsurancePolicyId = '';
        for (InsurancePolicy policy : policies) {
            InsurancePolicyId = policy.Id;
            ARC_ProductAggregators__mdt aggValues = ARC_ProductAggregators__mdt.getInstance(policy.Product.ProductCode);
            for (Schema.SObjectField expectedAggregator : getAggregatorsFields(aggValues)) {
                if (!isFamilyAggregator(expectedAggregator) || aggValues.get(expectedAggregator) == null) continue;
                String aggregatorName = expectedAggregator.getDescribe().getLabel();
                Integer minYear = policy.ARC_EffectiveDate__c.year();
                Integer maxYear = policy.ARC_ExpirationDate__c == null ? Date.Today().year() : policy.ARC_ExpirationDate__c.year();
                for (Integer year = minYear; year <= maxYear; year++) {
                    Id renewedPol = isUpgradePolicy(policy.ARC_PolicyReason__c) ? policy.Id : policy.RenewedFromPolicyId;
                    String famAggKey = renewedPol + '-' + String.valueOf(year);
                    List<InsurancePolicy> relatedPolicies;
                    if (!relatedPoliciesMap.containsKey(renewedPol)) {
                        policiesVoidedExceptions.add(renewedPol);
                        continue;
                    } else {
                        relatedPolicies = relatedPoliciesMap.get(renewedPol).get(year);
                        if (relatedPolicies == null) {
                            noRelatedPoliciesFound.add(policy.Id);
                            continue;
                        }
                    }
                    ARC_ProductAggregators__mdt lastAggregatorsMetadata = getLastValidAggregatorLimits(relatedPolicies);
                    if (familyAggMap.get(famAggKey) == null) {
                        // Create Family AMCS
                        if (year <= 2022) {
                            policiesFromPreviousYears.add(policy.Id);
                            missingRecordsEarlyYearsCounter++;
                        }
                        missingAggregatorsCounter++;
                        policiesWithMissingPartAggSet.add(policy.Id);
                        ARC_Aggregator__c famAgg = new ARC_Aggregator__c();
                        famAgg.RecordTypeId = familyAggRT;
                        famAgg.Name = aggregatorName;
                        famAgg.ARC_Year__c = String.valueOf(year);
                        famAgg.ARC_CreatedIn__c = renewedPol;
                        famAgg.ARC_FamilyCurrentValue__c = 0;
                        if (lastAggregatorsMetadata.get(expectedAggregator) != null) {
                            famAgg.ARC_LimitValue__c = Double.valueOf((Double)lastAggregatorsMetadata.get(expectedAggregator));
                        } else {
                            famAgg.ARC_LimitValue__c = Double.valueOf((Double)aggValues.get(expectedAggregator));
                        }
                        familyAggMap.put(famAggKey, famAgg);
                    } else {
                        // Update Family AMCS LimitValue
                        ARC_Aggregator__c famAgg = familyAggMap.get(famAggKey);
                        Double newLimitValue;
                        if (lastAggregatorsMetadata.get(expectedAggregator) != null) {
                            newLimitValue = Double.valueOf((Double)lastAggregatorsMetadata.get(expectedAggregator));
                        } else {
                            newLimitValue = Double.valueOf((Double)aggValues.get(expectedAggregator));
                        }
                        if (newLimitValue >= famAgg.ARC_FamilyCurrentValue__c) {
                            famAgg.ARC_LimitValue__c = newLimitValue;
                        } else {
                            famAgg.ARC_LimitValue__c = newLimitValue;
                            aggregatorsExceedingLimit.add(famAgg.Id);
                        }
                    }
                }                
            }
        }

        // Upsertion of Family AMCS
        if (this.shouldCreateMissingAggregators) {
            try {
                upsert familyAggMap.values();
            } catch (Exception e) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{
                    'ignacio.ferreiro@arcsona.com', 
                    'agustin.garay@arcsona.com'
                }); 
                mail.setSubject('Apex Exception Occurred');
                mail.setPlainTextBody('Exception: ' + e.getMessage() + '\nStack Trace:\n' + e.getStackTraceString());
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
            }
        }

        // Participant Aggregators Missing 
        InsurancePolicyId = '';
        for (InsurancePolicy policy : policies) {
            InsurancePolicyId = policy.Id;
            ARC_ProductAggregators__mdt aggValues = ARC_ProductAggregators__mdt.getInstance(policy.Product.ProductCode);
            for (Schema.SObjectField expectedAggregator : getAggregatorsFields(aggValues)) {
                if (!isIndividualAggregator(expectedAggregator) || aggValues.get(expectedAggregator) == null) continue;
                String aggregatorName = expectedAggregator.getDescribe().getLabel();
                for (InsurancePolicyParticipant participant : policy.InsurancePolicyParticipants) {
                    if (participant.PrimaryParticipantContact == null || participant.PrimaryParticipantContact.Birthdate == null) {
                        continue;
                    } // Skip IPP with missing information (contact, birthdate)
                    Integer minYear = policy.ARC_EffectiveDate__c > participant.PrimaryParticipantContact.Birthdate ? policy.ARC_EffectiveDate__c.year() : participant.PrimaryParticipantContact.Birthdate.year();
                    Integer maxYear;
                    if (isOneTime(expectedAggregator) || isLifeTime(expectedAggregator)) {
                        maxYear = minYear;
                    } else {
                        maxYear = policy.ARC_ExpirationDate__c == null ? Date.Today().year() : policy.ARC_ExpirationDate__c.year();
                    }
                    for (Integer year = minYear; year <= maxYear; year++) {
                        String partAggKey;
                        List<InsurancePolicy> relatedPolicies;
                        Id renewedPol = isUpgradePolicy(policy.ARC_PolicyReason__c) ? policy.Id : policy.RenewedFromPolicyId;
                        Id accountId = participant.PrimaryParticipantContact.AccountId;
                        // Get related policies to find correct limit values
                        if (isOneTime(expectedAggregator) || isLifeTime(expectedAggregator)) {
                            partAggKey = policy.Id + '-' + aggregatorName + '-null-' + participant.Id;  
                            if (!relatedPoliciesOfParticipantMap.containsKey(renewedPol)) {
                                policiesVoidedExceptions.add(renewedPol);
                                continue;
                            } else {
                                relatedPolicies = relatedPoliciesOfParticipantMap.get(renewedPol).get(accountId);
                            }
                        } else {
                            partAggKey = policy.Id + '-' + aggregatorName + '-' + year + '-' + participant.Id;
                            if (!relatedPoliciesOfParticipantPerYearMap.containsKey(renewedPol)) {
                                policiesVoidedExceptions.add(renewedPol);
                                continue;
                            } else {
                                relatedPolicies = relatedPoliciesOfParticipantPerYearMap.get(renewedPol).get(accountId).get(Integer.valueOf(year));
                            }
                        }
                        ARC_ProductAggregators__mdt lastAggregatorsMetadata = getLastValidAggregatorLimits(relatedPolicies);
                        if (existingPartAggMap.get(partAggKey) == null) {
                            // Create new Participant Aggregator
                            if (year <= 2022) {
                                policiesFromPreviousYears.add(policy.Id);
                                partAggregatorsFromPreviousYearsCounter++;
                                missingRecordsEarlyYearsCounter++;
                            }
                            missingParticipantAggregatorsCounter++;

                            if (isCongenitalBirthDefectAggregator(expectedAggregator)) {
                                missingCongenitalBirth.add(policy.Id);
                            } else {
                                policiesWithMissingPartAggSet.add(policy.Id);
                            }

                            ARC_ParticipantAggregator__c newPartAgg = new ARC_ParticipantAggregator__c();
                            newPartAgg.Name = aggregatorName;
                            newPartAgg.ARC_ConsumedValue__c = 0;
                            newPartAgg.ARC_Policy__c = policy.Id;
                            newPartAgg.ARC_PolicyParticipant__c = participant.Id;
                            // Key to locate its Aggregator
                            String aggKey;
                            if (isOneTime(expectedAggregator) || isLifeTime(expectedAggregator)) {
                                aggKey = renewedPol + '-' + aggregatorName + '-null-' + accountId;     
                            } else {
                                aggKey = renewedPol + '-' + aggregatorName + '-' + year + '-' + accountId;
                            }                            
                            partAggKeyToAggKey.put(partAggKey, aggKey);

                            if (individualAggMap.get(aggKey) != null) {
                                // Aggregator exists
                                ARC_Aggregator__c aggregator = individualAggMap.get(aggKey);
                                if (aggregatorName != 'Maternity' && aggregatorName != 'Pre Existing Conditions' && lastAggregatorsMetadata.get(expectedAggregator) != null) {
                                    Double newLimitValue = Double.valueOf((Double)lastAggregatorsMetadata.get(expectedAggregator));
                                    if (aggregator.ARC_CurrentValue__c == null || (aggregator.ARC_CurrentValue__c != null && newLimitValue >= aggregator.ARC_CurrentValue__c)) {
                                        aggregator.ARC_LimitValue__c = newLimitValue;
                                        partAggToInsert.put(partAggKey, newPartAgg);
                                    } else {
                                        aggregator.ARC_LimitValue__c = newLimitValue;
                                        partAggToInsert.put(partAggKey, newPartAgg);
                                        aggregatorsExceedingLimit.add(aggregator.Id);
                                    }
                                // For 'Maternity' or 'Pre Existing Conditions' does not update limit value
                                } else if (aggregatorName == 'Maternity' || aggregatorName == 'Pre Existing Conditions') {
                                    if (aggregator.ARC_CurrentValue__c == null || (aggregator.ARC_CurrentValue__c != null && aggregator.ARC_LimitValue__c >= aggregator.ARC_CurrentValue__c)) {
                                        partAggToInsert.put(partAggKey, newPartAgg);
                                    } else {
                                        partAggToInsert.put(partAggKey, newPartAgg);
                                        aggregatorsExceedingLimit.add(aggregator.Id);
                                    }
                                }
                            } else {
                                // Create new Aggregator
                                partAggToInsert.put(partAggKey, newPartAgg);
                                if (year <= 2022) {
                                    policiesFromPreviousYears.add(policy.Id);
                                    missingRecordsEarlyYearsCounter++;
                                }
                                if (isCongenitalBirthDefectAggregator(expectedAggregator)) {
                                    missingCongenitalBirth.add(policy.Id);
                                }
                                missingAggregatorsCounter++;
                                ARC_Aggregator__c newAggregator = new ARC_Aggregator__c();
                                newAggregator.RecordTypeId = individualAggRT;
                                newAggregator.Name = aggregatorName;
                                if (lastAggregatorsMetadata.get(expectedAggregator) != null) {
                                    newAggregator.ARC_LimitValue__c = Double.valueOf((Double)lastAggregatorsMetadata.get(expectedAggregator));
                                } else {
                                    newAggregator.ARC_LimitValue__c = Double.valueOf((Double)aggValues.get(expectedAggregator));
                                }
                                newAggregator.ARC_Code__c = getAggregatorCode(expectedAggregator);
                                newAggregator.ARC_Type__c = getAggregatorType(expectedAggregator);
                                newAggregator.ARC_Member__c = accountId;
                                newAggregator.ARC_CreatedIn__c = renewedPol;
                                if (!isLifeTime(expectedAggregator) && !isOneTime(expectedAggregator)) {
                                    newAggregator.ARC_Year__c = String.valueOf(year);
                                }
                                if (isOneTime(expectedAggregator)) {
                                    newAggregator.ARC_NextAvailabilityDate__c = policy.ARC_EffectiveDate__c;
                                }
                                individualAggMap.put(aggKey, newAggregator);
                            }
                        } else {
                            // Update Aggregator LimitValue (for non 'Maternity' or 'Pre Existing Conditions')
                            ARC_ParticipantAggregator__c existingPartAgg = existingPartAggMap.get(partAggKey);
                            String aggKey;
                            if (existingPartAgg.ARC_Aggregator__r.ARC_CreatedIn__c == null) {
                                aggregatorsMissingPolicy.add(existingPartAgg.ARC_Aggregator__c);
                                continue;
                            } else if (isUpgradePolicy(policy.ARC_PolicyReason__c) && existingPartAgg.ARC_Aggregator__r.ARC_CreatedIn__c != policy.Id) {
                                aggregatorsWrongPolicy.add(policy.Id);
                                continue;
                            }
                            if (isOneTime(expectedAggregator) || isLifeTime(expectedAggregator)) {
                                aggKey = existingPartAgg.ARC_Aggregator__r.ARC_CreatedIn__c + '-' + existingPartAgg.Name + '-null-' + accountId; // esta es la poliza antigua que es a donde apunta el agg existente, pero esta misslabled como upgrade
                            } else {
                                aggKey = existingPartAgg.ARC_Aggregator__r.ARC_CreatedIn__c + '-' + existingPartAgg.Name + '-' + year + '-' + accountId;
                            }
                            if (aggregatorName != 'Maternity' && aggregatorName != 'Pre Existing Conditions' && lastAggregatorsMetadata.get(expectedAggregator) != null) {
                                ARC_Aggregator__c aggregator = individualAggMap.get(aggKey);
                                if (aggregator == null) {
                                    aggregatorsMisslabeled.add(existingPartAgg.Id);
                                    continue;
                                }
                                Double newLimitValue = Double.valueOf((Double)lastAggregatorsMetadata.get(expectedAggregator));
                                if (aggregator.ARC_CurrentValue__c == null || (aggregator.ARC_CurrentValue__c != null && newLimitValue >= aggregator.ARC_CurrentValue__c)) {
                                    aggregator.ARC_LimitValue__c = newLimitValue;
                                } else {
                                    aggregator.ARC_LimitValue__c = newLimitValue;
                                    aggregatorsExceedingLimit.add(aggregator.Id);
                                }
                            }
                        }
                    }
                }
            }
        }

        // links individual AMCS to Family aggregator
        InsurancePolicyId = '';
        for (InsurancePolicy policy : policies) {
            InsurancePolicyId = policy.Id;
            ARC_ProductAggregators__mdt aggValues = ARC_ProductAggregators__mdt.getInstance(policy.Product.ProductCode);
            Boolean linkIndividualsToFamily = aggValues.get('FAM_AMCS__c') != null;
            if (linkIndividualsToFamily) {

                Integer minYear = policy.ARC_EffectiveDate__c.year();
                Integer maxYear = policy.ARC_ExpirationDate__c == null ? Date.Today().year() : policy.ARC_ExpirationDate__c.year();
                
                for (Integer year = minYear; year <= maxYear; year++) {
                    String famKey = isUpgradePolicy(policy.ARC_PolicyReason__c) ? policy.Id + '-' + year : policy.RenewedFromPolicyId + '-' + year;  
                    ARC_Aggregator__c famAgg = familyAggMap.get(famKey);
                    
                    for (InsurancePolicyParticipant participant : policy.InsurancePolicyParticipants) {
                        String IPPAccount = participant.PrimaryParticipantContact.AccountId;
                        if (IPPAccount == null) continue;
                        if (famAgg.ARC_CreatedIn__c == null) { 
                            aggregatorsMissingPolicy.add(famAgg.Id); 
                            continue;
                        } else if (isUpgradePolicy(policy.ARC_PolicyReason__c) && famAgg.ARC_CreatedIn__c != policy.Id) {
                            aggregatorsWrongPolicy.add(policy.Id);
                            continue;
                        }
                        String indKeyPrefix = famAgg.ARC_CreatedIn__c +'-Individual Max AMCS-' + year + '-' + IPPAccount;
                        
                        ARC_Aggregator__c indAMCS = individualAggMap.get(indKeyPrefix);
                        if (indAMCS == null) {
                            familyAggregatorsMissingIndividual.add(famAgg.Id);
                            continue;
                        }
                        if (indAMCS.ARC_FamilyAggregator__c != famAgg.Id && indAMCS.ARC_CurrentValue__c != null) {
                            famAgg.ARC_FamilyCurrentValue__c += indAMCS.ARC_CurrentValue__c;   
                            if (famAgg.ARC_FamilyCurrentValue__c > famAgg.ARC_LimitValue__c ) {
                                famAgg.ARC_FamilyCurrentValue__c -= indAMCS.ARC_CurrentValue__c;
                                aggregatorsExceedingLimit.add(famAgg.Id);
                                continue;
                            }
                        }
                       if (indAMCS.ARC_FamilyAggregator__c != famAgg.Id) {
                           indAMCS.ARC_FamilyAggregator__c = famAgg.Id;
                       }
                    }
                }
            }         
        }

        // upserts individual aggregators
        if (this.shouldCreateMissingAggregators) {
            try {
                upsert individualAggMap.values();
            } catch (Exception e) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{
                    'ignacio.ferreiro@arcsona.com', 
                    'agustin.garay@arcsona.com'
                }); 
                mail.setSubject('Apex Exception Occurred');
                mail.setPlainTextBody('Exception: ' + e.getMessage() + '\nStack Trace:\n' + e.getStackTraceString());
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
            }
        }
        
        // Relate Participant Aggregators to Aggregators
        for (String partAggKey : partAggToInsert.keySet()) {
            String aggKey = partAggKeyToAggKey.get(partAggKey);
            ARC_Aggregator__c aggregator = individualAggMap.get(aggKey);
            ARC_ParticipantAggregator__c partAgg = partAggToInsert.get(partAggKey);
            partAgg.ARC_Aggregator__c = aggregator.Id;
        }
        
        // inserts Participant Aggregators
        if (this.shouldCreateMissingAggregators) {
            try {
                partAggToBeInsertedCounter += partAggToInsert.size();
                insert partAggToInsert.values();
                partAggInsertedCounter += partAggToInsert.size();
            }  catch (Exception e) {
                partAggNotInsertedList.addAll(partAggToInsert.keySet());
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{
                    'ignacio.ferreiro@arcsona.com', 
                    'agustin.garay@arcsona.com'
                }); 
                mail.setSubject('Apex Exception Occurred');
                mail.setPlainTextBody('Exception: ' + e.getMessage() + '\nStack Trace:\n' + e.getStackTraceString());
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
            }
        }
    }

    // UTILITY METHODS //

    public List<Schema.SObjectField> getAggregatorsFields(ARC_ProductAggregators__mdt aggregatorValues) {
        return aggregatorValues.getSObjectType().getDescribe().fields.getMap().values();
    }

    public Boolean isUpgradePolicy(String policyReasons) {
        List<String> UPGRADE_REASONS = new List<String>{'Program Upgrade', 'New Application', 'Upgraded Spin Off'};
        List<String> polReasons = policyReasons.split('<br>');
        Boolean isUpgrade = false;
        for (String reason : polReasons) {
            if (UPGRADE_REASONS.contains(reason)) {
                isUpgrade = true;
                break;
            }
        }
        return isUpgrade;
    }

    public Boolean isOneTime(Schema.SObjectField aggregatorField) {
        String aggregatorCode = getAggregatorCode(aggregatorField);
        List<String> ONE_TIME = new List<String>{'CCS__c', 'MAMM__c', 'PROSCRE__c', 'FLXSIG__c', 'CLON__c', 'SSOPT__c'};
        return ONE_TIME.contains(aggregatorCode);
    }

    public Boolean isLifeTime(Schema.SObjectField aggregatorField) {
        String aggregatorCode = getAggregatorCode(aggregatorField);
        List<String> LIFETIME = new List<String>{'ALGTEST__c'};
        return LIFETIME.contains(aggregatorCode);
    }

    public Boolean isIndividualAggregator(Schema.SObjectField aggregatorField) {
        return String.valueOf(aggregatorField).startsWith('IND_');
    }

    public Boolean isFamilyAggregator(Schema.SObjectField aggregatorField) {
        return String.valueOf(aggregatorField).startsWith('FAM_');
    }

    public Boolean isCongenitalBirthDefectAggregator(Schema.SObjectField aggregatorField) {
        return String.valueOf(aggregatorField) == 'IND_CONGBIRTH__c';
    }

    public static String getAggregatorCode(Schema.SObjectField aggregatorField) {
        String fullFieldCode = String.valueOf(aggregatorField);
        if (fullFieldCode.startsWith('IND_') || fullFieldCode.startsWith('FAM_')) {
            return fullFieldCode.substring(4);
        } else {
            return fullFieldCode;
        }
    }

    public String getAggregatorType(Schema.SObjectField aggregatorField) {
        String aggregatorCode = getAggregatorCode(aggregatorField);
        String aggregatorType;
        switch on aggregatorCode {
            when 'ACC__c', 'HTERAPHPY__c', 'CHIRO__c', 'OFUC__c', 'PHYTH__c', 'CCS__c', 'MAMM__c', 'PROSCRE__c', 'FLXSIG__c', 'CLON__c', 'SSOPT__c', 'PSYCH__c' {
                aggregatorType = 'Number';
            }
            when 'AMCS__c', 'PREEX__c', 'SHAMCS__c', 'TOB__c', 'ALGTEST__c', 'DME__c', 'MAT__c', 'CONGBIRTH__c' {
                aggregatorType = 'Currency';
            }
        }
        return aggregatorType;
    }

    private ARC_ProductAggregators__mdt getLastValidAggregatorLimits(List<insurancePolicy> policies) {
        InsurancePolicy latestPolicy;
        DateTime latestDate;
        ARC_ProductAggregators__mdt result; 

        for (InsurancePolicy policy : policies) {
            if (policy.ARC_Contract__r.Status == 'Activated') {
                latestpolicy = policy;
                break;
            }
            DateTime activatedDate = policy.ARC_Contract__r.ActivatedDate;
            DateTime reactivatedDate = policy.ARC_Contract__r.ARC_Reactivated__c;
            // Pick the latest of the two dates, ReactivatedDate time is always 00:00:00
            DateTime effectiveDate;
            if (activatedDate != null && reactivatedDate != null) {
                effectiveDate = (activatedDate > reactivatedDate) ? activatedDate : reactivatedDate;
            } else if (activatedDate != null) {
                effectiveDate = activatedDate;
            } else if (reactivatedDate != null) {
                effectiveDate = reactivatedDate;
            } else {
                continue; // Skip this policy if both dates are null
            }

            if (latestDate == null || effectiveDate > latestDate) {
                latestDate = effectiveDate;
                latestPolicy = policy;
            }
        }
        if (latestPolicy != null) {
            result = ARC_ProductAggregators__mdt.getInstance(latestPolicy.Product.ProductCode);
        }
        return result;
    }

    global void finish(Database.BatchableContext BC) {


        Set<Id> policiesMissingOnlyCBDAggregator = new Set<Id>();
        for (String policyId : missingCongenitalBirth) {
            if (!policiesWithMissingPartAggSet.contains(policyId)) {
                policiesMissingOnlyCBDAggregator.add(policyId);
            }
        }

        String emailAddress = UserInfo.getUserEmail();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<OrgWideEmailAddress> oMailNoReplay = [
            SELECT Id, Address, DisplayName
            FROM OrgWideEmailAddress
            WHERE Displayname = 'No Reply'
        ];
        mail.setOrgWideEmailAddressId(oMailNoReplay[0].Id);
        mail.setToAddresses(new List<String>{emailAddress});
        mail.setSubject('Create Missing Aggregators Batch Completed');
        String body;
        if(!this.isScheduled){
            body = 'Batch Completed  -  Create Aggregators: ' + this.shouldCreateMissingAggregators + '\n\n\n';
            body += 'Number of missing Participant Aggregators: ' + missingParticipantAggregatorsCounter + '\n\n';
            body += 'Number of missing records 2022 and earlier: ' + missingRecordsEarlyYearsCounter  + '\n\n';
            body += 'Number of policies from 2022 or earlier: ' + policiesFromPreviousYears.size() + '\n\n';
            body += 'Number of missing aggregators earlier from 2022: ' + partAggregatorsFromPreviousYearsCounter + '\n\n';
            body += 'Number of missing Aggregators: ' + missingAggregatorsCounter + '\n\n';
            body += 'Number of Aggregators exceeding limits: ' + aggregatorsExceedingLimit.size() + '\n\n';
            body += 'Number of Participant Aggregators to be inserted: ' + partAggToBeInsertedCounter + '\n\n';
            body += 'Number of Participant Aggregators inserted: ' + partAggInsertedCounter + '\n\n';
            body += 'Number of Participant Aggregators processed with errors: ' + partAggNotInsertedList.size();
            body += '\n\n\n' + 'Participant Aggregators processed with errors: ' + '\n' + '(Policy - Aggregator - Year - Participant)' + '\n' + String.join(partAggNotInsertedList, '\n');
            body += '\n\n' + 'Policies missing only Congenital Birth Aggregator: ' + policiesMissingOnlyCBDAggregator.size() + '\n';
            body += '\n\n' + 'Aggregators exceeding limits: ' + '\n' + String.join(aggregatorsExceedingLimit, '\n');
            body += '\n\n' + 'Voided Policies: ' + '\n' + String.join(policiesVoidedExceptions, '\n');
            body += '\n\n' + 'Policy Participants Missing Information: ' + '\n' + String.join(policyParticipantsMissingInformation, '\n');
            body += '\n\n' + 'Misplaced aggregators policies (' + aggregatorsWrongPolicy.size() + '): ' + '\n' + String.join(aggregatorsWrongPolicy, '\n');
            body += '\n\n' + 'Family aggregators missing Individual AMCS: ' + '\n' + String.join(familyAggregatorsMissingIndividual, '\n');
            body += '\n\n' + 'Misslabeled aggregator / part-aggregator: ' + '\n' + String.join(aggregatorsMisslabeled, '\n');
            body += '\n\n' + 'Cound not generate related policies list: ' + '\n' + String.join(noRelatedPoliciesFound, '\n');
            body += '\n\n' + 'Policies with missing Participant Aggregators ('+ policiesWithMissingPartAggSet.size()+'): \n'; 
            body +=  String.join(policiesWithMissingPartAggSet, '\n');
            mail.setPlainTextBody(body);
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        }

        System.debug('--- Number of Policies: ' + policiesWithMissingPartAggSet.size());
        System.debug('--- Where clause: ' + this.whereClause);
        System.debug('Number of missing Aggregators: ' + missingAggregatorsCounter);
        System.debug('Number of Aggregators exceeding limits: ' + aggregatorsExceedingLimit.size());
        System.debug('Number of Participant Aggregators to be inserted: ' + partAggToBeInsertedCounter);
        System.debug('Number of Participant Aggregators inserted: ' + partAggInsertedCounter);
        System.debug('Number of Participant Aggregators processed with errors: ' + partAggNotInsertedList.size());
        System.debug('Policies with missing Participant Aggregators: ' + policiesWithMissingPartAggSet.size());
        System.debug('Policies missing only Congenital Birth Aggregator: ' + policiesMissingOnlyCBDAggregator.size());
    }

    public class CreateMissingAggregatosException extends Exception {}
}