/*******************************************************************
 * @ClassName          :   ARC_EliminateDuplicatedAggregators
 * @Description        :   Batchable Apex class that detects and eliminates duplicated Aggregators
 *                         shouldRemoveDuplicates = false:
 *                         - Executes the batch without removing duplicated Aggregators
 *                         - Counts all the duplicated Aggregators
 *                         shouldRemoveDuplicates = true:
 *                         - Assigns the Participant Aggregators linked to the duplicated Aggregators to the Aggregators that will remain
 *                         - Removes the duplicated Aggregators
 *                         - The remaining Aggregator is the one with an appropriate Limit Value (and related to a Family AMCS in case of finding more than one)
 *                         - The appropriate Limit Value is determined based on the participant's latest Policy for that year,
 *                           for OneTime and LifeTime the year is not considered
 *                         - Maternity and Pre-Existing will always pick the one with the greatest Limit Value
 *                         - Individual AMCS duplicates will not be deleted if their sum surpasses the Family AMCS Limit Value
 *                         - Family AMCS duplicates will be eliminated only if the sum of the Individual AMCS related to them does not exceed the 
 *                           Family AMCS Limit Value
 *                         - If the Aggregator is not part of the Product of the latest Policy, the selection is random (Aggregators that fall in this scenario 
 *                           have a unique Limit Value that does not differ accross Products)
 *                         - If an Aggregator with a proper Limit Value could not be found, duplicates are not eliminated and the Id is reported
 ********************************************************************/

global class ARC_EliminateDuplicatedAggregators implements Database.Batchable<sObject>, Database.Stateful {
    private static final List<String> ONE_TIME = new List<String>{'CCS__c', 'MAMM__c', 'PROSCRE__c', 'FLXSIG__c', 'CLON__c', 'SSOPT__c'};
    private static final List<String> LIFETIME = new List<String>{'ALGTEST__c'};
    private String whereClause;
    private Boolean shouldRemoveDuplicates = false;
    private Integer duplicatedAggCounter = 0;
    private Integer duplicatedAggExceedingLimitCounter = 0;
    private Integer aggToBeEliminatedCounter = 0;
    private Integer aggEliminatedCounter = 0;
    private Integer aggNotEliminatedCounter = 0;
    private List<Id> aggNotEliminatedList = new List<Id>();
    private List<Id> aggExceedingLimitList = new List<Id>();
    private List<Id> aggAMCSExceedingLimitList = new List<Id>();
    private Set<Id> policiesWithDuplicatesSet = new Set<Id>();
    private Set<Id> policiesWithConflictingAggregatorLimitValues = new Set<Id>();
    private Set<Id> policiesVoidedExceptions = new Set<Id>();
    private Set<Id> policiesUnnecesaryAggregatorsExceptions = new Set<Id>();

    global ARC_EliminateDuplicatedAggregators (String whereClause, Boolean shouldRemoveDuplicates) {
        this.whereClause = whereClause;
        this.shouldRemoveDuplicates = shouldRemoveDuplicates;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM InsurancePolicy';
        if (this.whereClause != null) {
            query += ' WHERE ' + this.whereClause;
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<InsurancePolicy> input) {
        Set<Id> policyIds = new Set<Id>();
        for (InsurancePolicy pol : input) {
            policyIds.add(pol.Id);
        }
        List<InsurancePolicy> policies = [
            SELECT Id,
                (SELECT Id, PrimaryParticipantContact.AccountId
                FROM InsurancePolicyParticipants)
            FROM InsurancePolicy
            WHERE Id IN: policyIds
        ];
        // Related carry-over policies
        List<InsurancePolicy> policiesRenewedFrom = [
            SELECT Id, RenewedFromPolicyId, Product.ProductCode, ARC_Contract__r.Status, ARC_Contract__r.ActivatedDate, ARC_Contract__r.ARC_Reactivated__c, ARC_EffectiveDate__c, ARC_ExpirationDate__c, ARC_PolicyReason__c,
                (SELECT Id, PrimaryParticipantContact.AccountId
                FROM InsurancePolicyParticipants)
            FROM InsurancePolicy
            WHERE (Id IN: policyIds OR RenewedFromPolicyId IN :policyIds) AND (ARC_Contract__r.Status = 'Activated' OR ARC_Contract__r.Status = 'Terminated')
        ];

        // Map for policies renewed from, for each participant per year
        // Used to select the correct remaining aggregator for Individual Aggregators
        // Map: RenewedPolicyId - AccountId - Year - List Policies
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
        System.debug('----relatedPoliciesOfParticipantPerYearMap: ' + relatedPoliciesOfParticipantPerYearMap);

        // Map for policies renewed from, for each participant
        // Used to select the correct remaining Aggregator for Individual OneTime and LifeTime Aggregators
        // Map: RenewedPolicyId - Account - List Policies
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
        System.debug('----relatedPoliciesOfParticipantMap: ' + relatedPoliciesOfParticipantMap);

        // Map for policies renewed from
        // Used to select the correct remaining Aggregator for Family AMCS
        // Map: RenewedPolicyId - Year - List Policies
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
        System.debug('----relatedPoliciesMap: ' + relatedPoliciesMap);

        // Eliminate Duplicated Individual Aggregators
        Id individualAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
        List<ARC_Aggregator__c> indAggregators = [
            SELECT Id, Name, ARC_Member__c, ARC_CreatedIn__c, ARC_Year__c, ARC_CurrentValue__c, ARC_LimitValue__c, ARC_Code__c, ARC_FamilyAggregator__c, ARC_FamilyAggregator__r.ARC_LimitValue__c,
                (SELECT Id, Name, ARC_Aggregator__c, ARC_ConsumedValue__c, ARC_PolicyParticipant__c, ARC_Policy__c
                FROM Participant_Aggregators__r)
            FROM ARC_Aggregator__c
            WHERE ARC_CreatedIn__c IN: policyIds
            AND recordTypeId =: individualAggRT
        ];
        // Map Policy - Member - AggregatorName - Year - ListAggregators
        // Year key for ONE TIME and LIFETIME is 'none'
        Map<Id, Map<Id, Map<String, Map<String, List<ARC_Aggregator__c>>>>> aggregatorsMap = new Map<Id, Map<Id, Map<String, Map<String, List<ARC_Aggregator__c>>>>>();
        for (ARC_Aggregator__c agg : indAggregators) {
            if (aggregatorsMap.get(agg.ARC_CreatedIn__c) == null) {
                aggregatorsMap.put(agg.ARC_CreatedIn__c, new Map<Id, Map<String, Map<String, List<ARC_Aggregator__c>>>>());
            }
            
            if (aggregatorsMap.get(agg.ARC_CreatedIn__c).get(agg.ARC_Member__c) == null) {
                aggregatorsMap.get(agg.ARC_CreatedIn__c).put(agg.ARC_Member__c, new Map<String, Map<String, List<ARC_Aggregator__c>>>());
            }
            
            if (aggregatorsMap.get(agg.ARC_CreatedIn__c).get(agg.ARC_Member__c).get(agg.Name) == null) {
                aggregatorsMap.get(agg.ARC_CreatedIn__c).get(agg.ARC_Member__c).put(agg.Name, new Map<String, List<ARC_Aggregator__c>>());
            }
            String yearKey;
            if (!ONE_TIME.contains(agg.ARC_Code__c) && !LIFETIME.contains(agg.ARC_Code__c) && agg.ARC_Year__c != null) {
                yearKey = agg.ARC_Year__c;
            } else if ((ONE_TIME.contains(agg.ARC_Code__c) || LIFETIME.contains(agg.ARC_Code__c)) && agg.ARC_Year__c == null) {
                yearKey = 'none';
            } else {
                continue;
            }
            if (aggregatorsMap.get(agg.ARC_CreatedIn__c).get(agg.ARC_Member__c).get(agg.Name).get(yearKey) == null) {
                aggregatorsMap.get(agg.ARC_CreatedIn__c).get(agg.ARC_Member__c).get(agg.Name).put(yearKey, new List<ARC_Aggregator__c>());
            }
            aggregatorsMap.get(agg.ARC_CreatedIn__c).get(agg.ARC_Member__c).get(agg.Name).get(yearKey).add(agg);
        }
        System.debug('aggregatorsMap----: ' + aggregatorsMap);

        List<ARC_ParticipantAggregator__c> partAggToInsert = new List<ARC_ParticipantAggregator__c>();
        List<ARC_ParticipantAggregator__c> partAggToUpdate = new List<ARC_ParticipantAggregator__c>();
        Map<Id, ARC_ParticipantAggregator__c> originalToCloneMap = new Map<Id, ARC_ParticipantAggregator__c>();
        Map<Id, Double> originalToValueMap = new Map<Id, Double>();
        List<ClaimPaymentSummary> itemPaymentsToUpdate = new List<ClaimPaymentSummary>();
        List<ARC_Aggregator__c> aggToEliminate = new List<ARC_Aggregator__c>();
        Set<String> policiesExceedingAMCS = new Set<String>(); // PolicyId-Year
        for (Id policyId : aggregatorsMap.keySet()) {
            Map<Id, Map<String, Map<String, List<ARC_Aggregator__c>>>> membersMap = aggregatorsMap.get(policyId);
            if (membersMap == null) continue;
            for (Id accountId : membersMap.keySet()) {
                Map<String, Map<String, List<ARC_Aggregator__c>>> aggregatorNameMap = membersMap.get(accountId);
                if (aggregatorNameMap == null) continue;
                for (String aggName : aggregatorNameMap.keySet()) {
                    Map<String, List<ARC_Aggregator__c>> yearMap = aggregatorNameMap.get(aggName);
                    if (yearMap == null) continue;
                    for (String year : yearMap.keySet()) {
                        List<ARC_Aggregator__c> aggList = yearMap.get(year);
                        if (aggList.size() <= 1) continue;
                        policiesWithDuplicatesSet.add(policyId);
                        duplicatedAggCounter += aggList.size() - 1;

                        System.debug('--------------------------SELECTION OF REMAINING AGGREGATOR------------------------');
                        ARC_Aggregator__c aggRemain = null;
                        String aggCode = aggList[0].ARC_Code__c;
                        // Get related policies to find correct limit values
                        List<InsurancePolicy> relatedPolicies;
                        
                        if (year != 'none') {
                            if (!relatedPoliciesOfParticipantPerYearMap.containsKey(policyId)) {
                                policiesVoidedExceptions.add(policyId);
                                continue;
                            } else if (!relatedPoliciesOfParticipantPerYearMap.get(policyId).get(accountId).containsKey(Integer.valueOf(year))) {
                                policiesUnnecesaryAggregatorsExceptions.add(policyId);
                                continue;
                            } else {
                                relatedPolicies = relatedPoliciesOfParticipantPerYearMap.get(policyId).get(accountId).get(Integer.valueOf(year));
                            }
                        } else {
                            // Onetime OR Lifetime
                            if (!relatedPoliciesOfParticipantMap.containsKey(policyId)) {
                                policiesVoidedExceptions.add(policyId);
                                continue;
                            } else {
                                relatedPolicies = relatedPoliciesOfParticipantMap.get(policyId).get(accountId);
                            }
                        }
                                                
                        ARC_ProductAggregators__mdt aggregatorsMetadata = getLastValidAggregatorLimits(relatedPolicies);
                        System.debug('----aggCode: ' + aggCode);
                        if (aggregatorsMetadata.getSObjectType().getDescribe().fields.getMap().containsKey('IND_'+aggCode)) {
                            aggCode = 'IND_'+aggCode;
                        }
                        //Boolean aggIsInMetadata = aggregatorsMetadata.getSObjectType().getDescribe().fields.getMap().containsKey(aggCode);
                        // Maternity and Preexisting, their limit can be raised in time
                        if (aggList[0].ARC_Code__c.contains('MAT__c') || aggList[0].ARC_Code__c.contains('PREEX__c')) {
                            // Select highest limit
                            System.debug(aggList[0].ARC_Code__c);
                            for (ARC_Aggregator__c agg : aggList) {
                                if (aggRemain == null || agg.ARC_LimitValue__c > aggRemain.ARC_LimitValue__c) {
                                    aggRemain = agg;
                                }
                            }
                        } else {
                            // System.debug('---- is Agg in Metadata?? --> ' + aggIsInMetadata);
                            // if (aggIsInMetadata) {
                            // }
                            // System.debug('Aggregator Map?? -->' + aggregatorsMetadata.getSObjectType().getDescribe().fields.getMap());
                            // System.debug('Aggregator value?? -->' + aggregatorsMetadata.getSObjectType().getDescribe().fields.getMap().get(aggCode));
                            // System.debug('VALUE OF ?? -->' + Double.valueOf(aggregatorsMetadata.get(aggCode)));
                            // if (aggregatorsMetadata.getSObjectType().getDescribe().fields.getMap().get(aggCode) != null) {
                            if (Double.valueOf(aggregatorsMetadata.get(aggCode)) != null) {
                                Double finalLimit = Double.valueOf(aggregatorsMetadata.get(aggCode)); 
                                // Selects a Family Aggregator w/ limit creteria
                                for (ARC_Aggregator__c agg : aggList) {
                                    if (agg.ARC_FamilyAggregator__c != null) {
                                        if (agg.ARC_LimitValue__c == finalLimit) {
                                            aggRemain = agg;
                                            break;
                                        }
                                    }
                                }
                                // If no family aggregator, select the Aggregator with the limit criteria
                                if (aggRemain == null) {
                                    for (ARC_Aggregator__c agg : aggList) {
                                        if (agg.ARC_LimitValue__c == finalLimit) {
                                            aggRemain = agg;
                                            break;
                                        }
                                    }
                                } 
                            } else {
                                // Limit value not found on last product's metadata
                                System.debug('---CONFLICTING AGG LIST---' + aggList);
                                
                                aggRemain = aggList[0];
                            }
                        }
                        if (aggRemain == null) {
                            
                            System.debug('---CONFLICTING AGG---' + aggCode);
                            policiesWithConflictingAggregatorLimitValues.add(policyId);
                            continue;
                        }

                        System.debug('----aggRemain Limit: ' + aggRemain.ARC_LimitValue__c);

                        // Control Aggregator limit
                        Double consumedTotal = 0;
                        for (ARC_Aggregator__c agg : aggList) {
                            consumedTotal += agg.ARC_CurrentValue__c;
                        }
                        if (aggRemain.ARC_LimitValue__c < consumedTotal) {
                            duplicatedAggExceedingLimitCounter++;
                            aggExceedingLimitList.add(aggRemain.Id);
                            if (aggRemain.ARC_Code__c == 'AMCS__c') {
                                String policyYearKey = policyId + '-' + year;
                                policiesExceedingAMCS.add(policyYearKey);
                                aggAMCSExceedingLimitList.add(aggRemain.Id);
                            }
                            continue;
                        }
                        // Control Family AMCS limit in case AMCS duplicates are not linked to the same Family
                        if (aggRemain.ARC_Code__c == 'AMCS__c') {
                            Double familyLimit = 0;
                            for (Id familyCheckMemberId : membersMap.keySet()) {
                                Map<String, Map<String, List<ARC_Aggregator__c>>> aggregatorNameMapFamilyCheck = membersMap.get(familyCheckMemberId);
                                if (aggregatorNameMapFamilyCheck == null || !aggregatorNameMapFamilyCheck.containsKey('Individual AMCS')) continue;
                                Map<String, List<ARC_Aggregator__c>> yearMapFamilyCheck = aggregatorNameMapFamilyCheck.get('Individual AMCS');
                                if (yearMapFamilyCheck == null || yearMapFamilyCheck.get(year) == null) continue;
                                List<ARC_Aggregator__c> aggregators = yearMapFamilyCheck.get(year);
                                for (ARC_Aggregator__c agg : aggregators) {
                                    familyLimit += agg.ARC_CurrentValue__c;
                                }
                            }

                            System.debug('Family Limit calculated: '+familyLimit);
                            if (aggRemain.ARC_FamilyAggregator__r.ARC_LimitValue__c < familyLimit) {
                                duplicatedAggExceedingLimitCounter++;
                                aggExceedingLimitList.add(aggRemain.Id);
                                continue;
                            }
                        }
                        for (ARC_Aggregator__c agg : aggList) {
                            if (agg.Id == aggRemain.Id) continue;
                            for (ARC_ParticipantAggregator__c partAgg : agg.Participant_Aggregators__r) {
                                partAgg.ARC_Aggregator__c = aggRemain.Id;
                                partAggToUpdate.add(partAgg);
                            }
                            aggToEliminate.add(agg); 
                        }
                    }
                }
            }
        }

// PART 2: //

        if (this.shouldRemoveDuplicates) {
            try {
                aggToBeEliminatedCounter += aggToEliminate.size();
                update partAggToUpdate;
                delete aggToEliminate; 
                
                aggEliminatedCounter += aggToEliminate.size();
            } catch (Exception e) {
                aggNotEliminatedCounter += aggToEliminate.size();
                for (ARC_Aggregator__c agg : aggToEliminate) {
                    aggNotEliminatedList.add(agg.Id);
                }
                throw e;
            }
        }

        // Eliminate Duplicated Family Aggregators
        Id familyAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Family').getRecordTypeId();
        List<ARC_Aggregator__c> famAggregators = [
            SELECT Id, Name, ARC_CreatedIn__c, ARC_Year__c, ARC_FamilyCurrentValue__c, ARC_LimitValue__c,
                (SELECT Id, ARC_FamilyAggregator__c, ARC_CurrentValue__c
                FROM Aggregators__r)
            FROM ARC_Aggregator__c
            WHERE ARC_CreatedIn__c IN: policyIds
            AND RecordTypeId =: familyAggRT
        ];

        // Map Policy - Year - ListFamAggregators
        Map<Id, Map<String, List<ARC_Aggregator__c>>> famAggregatorsMap = new Map<Id, Map<String, List<ARC_Aggregator__c>>>();
        for (ARC_Aggregator__c agg : famAggregators) {
            if (famAggregatorsMap.get(agg.ARC_CreatedIn__c) == null) {
                famAggregatorsMap.put(agg.ARC_CreatedIn__c, new Map<String, List<ARC_Aggregator__c>>());
            }
            if (famAggregatorsMap.get(agg.ARC_CreatedIn__c).get(agg.ARC_Year__c) == null) {
                famAggregatorsMap.get(agg.ARC_CreatedIn__c).put(agg.ARC_Year__c, new List<ARC_Aggregator__c>());
            }
            famAggregatorsMap.get(agg.ARC_CreatedIn__c).get(agg.ARC_Year__c).add(agg);
        }
        List<ARC_Aggregator__c> aggToUpdate = new List<ARC_Aggregator__c>();
        List<ARC_Aggregator__c> famAggToEliminate = new List<ARC_Aggregator__c>();
        List<ARC_Aggregator__c> famAggAndIndExceedingLimit = new List<ARC_Aggregator__c>();
        for (InsurancePolicy pol : policies) {
            if (famAggregatorsMap.get(pol.Id) == null) continue;
            for (String year : famAggregatorsMap.get(pol.Id).keySet()) {
                List<ARC_Aggregator__c> famAggList = famAggregatorsMap.get(pol.Id).get(year);
                if (famAggList.size() <= 1) continue;
                policiesWithDuplicatesSet.add(pol.Id);
                duplicatedAggCounter += famAggList.size() - 1;

                List<InsurancePolicy> relatedPolicies;
                if (!relatedPoliciesMap.containsKey(pol.Id)) {
                    policiesVoidedExceptions.add(pol.Id);
                    continue; 
                } else if (!relatedPoliciesMap.get(pol.Id).containsKey(Integer.valueOf(year))) {
                    policiesUnnecesaryAggregatorsExceptions.add(pol.Id);
                    continue;
                } else {
                    relatedPolicies = relatedPoliciesMap.get(pol.Id).get(Integer.valueOf(year));
                }
                 
                ARC_ProductAggregators__mdt aggregatorsMetadata = getLastValidAggregatorLimits(relatedPolicies);
                Double limitFamilyAgg = Double.valueOf(aggregatorsMetadata.get('FAM_AMCS__c'));

                ARC_Aggregator__c famAggRemain;
                if (famAggRemain == null) {
                    for (ARC_Aggregator__c agg : famAggList) {
                        if (agg.ARC_LimitValue__c == limitFamilyAgg) {
                            famAggRemain = agg;
                            break;
                        }
                    }
                } 
                if (famAggRemain == null) {
                    policiesWithConflictingAggregatorLimitValues.add(pol.Id);
                    continue;
                }

                // Control limit is not exceeded, consumedTotal is calculated with the Family Aggregator Summary flow logic
                Double consumedTotal = famAggRemain.ARC_FamilyCurrentValue__c;
                for (ARC_Aggregator__c famAgg : famAggList) {
                    if (famAgg.id == famAggRemain.id) continue;
                    for (ARC_Aggregator__c indAgg : famAgg.Aggregators__r) {
                        consumedTotal += indAgg.ARC_CurrentValue__c;
                    }
                }

                // validate limit new sum - add to report if exceeded and not included by individual
                String policyYearKey = pol.Id + '-' + year;
                if (famAggRemain.ARC_LimitValue__c < consumedTotal) {
                    if (!policiesExceedingAMCS.contains(policyYearKey)) {
                        duplicatedAggExceedingLimitCounter++;
                        aggExceedingLimitList.add(famAggRemain.Id);
                    }
                    continue;
                }

                if (policiesExceedingAMCS.contains(policyYearKey)) continue;
                for (ARC_Aggregator__c famAgg : famAggList) {
                    if (famAgg.id == famAggRemain.id) continue;
                    for (ARC_Aggregator__c indAgg : famAgg.Aggregators__r) {
                        indAgg.ARC_FamilyAggregator__c = famAggRemain.Id;
                        aggToUpdate.add(indAgg);
                    }
                    famAggToEliminate.add(famAgg);
                }
            }
        }
        if (this.shouldRemoveDuplicates) {
            try {
                aggToBeEliminatedCounter += famAggToEliminate.size();
                update aggToUpdate;
                delete famAggToEliminate;
                aggEliminatedCounter += famAggToEliminate.size();
            } catch (Exception e) {
                aggNotEliminatedCounter += famAggToEliminate.size();
                for (ARC_Aggregator__c agg : famAggToEliminate) {
                    aggNotEliminatedList.add(agg.Id);
                }
            }
        }
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

    private ARC_ProductAggregators__mdt getLastValidAggregatorLimits(List<insurancePolicy> policies) {
        System.debug('----Policies: ' + policies);
        InsurancePolicy latestPolicy;
        DateTime latestDate;
        ARC_ProductAggregators__mdt result; 

        for (InsurancePolicy policy : policies) {
            if (policy.ARC_Contract__r.Status == 'Activated') {
                latestpolicy = policy;
                break;
            }
            System.debug('-------Policy: ' + policy.Id);
            DateTime activatedDate = policy.ARC_Contract__r.ActivatedDate;
            DateTime reactivatedDate = policy.ARC_Contract__r.ARC_Reactivated__c;
            System.debug('--------activatedDate: ' + activatedDate);
            System.debug('--------reactivatedDate: ' + reactivatedDate);
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
        System.debug('--------latestPolicy: ' + latestPolicy);
        if (latestPolicy != null) {
            System.debug('--------product_code: ' + latestPolicy.Product.ProductCode);
            result = ARC_ProductAggregators__mdt.getInstance(latestPolicy.Product.ProductCode);
        }
        System.debug('metadata for aggregator : ' + result);
        return result;
    }

    global void finish(Database.BatchableContext BC) {
        String emailAddress = UserInfo.getUserEmail();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<OrgWideEmailAddress> oMailNoReplay = [
            SELECT Id, Address, DisplayName
            FROM OrgWideEmailAddress
            WHERE Displayname = 'No Reply'
        ];
        mail.setOrgWideEmailAddressId(oMailNoReplay[0].Id);
        mail.setToAddresses(new List<String>{emailAddress});
        mail.setSubject('Eliminate Duplicated Aggregators Batch Completed');
        String body = 'Batch Completed  -  Remove Members: ' + this.shouldRemoveDuplicates + '\n\n\n';
        body += 'Number of duplicated Aggregators: ' + duplicatedAggCounter + '\n\n';
        body += 'Number of duplicated Aggregators exceeding limits: ' + duplicatedAggExceedingLimitCounter + '\n\n';
        body += 'Number of duplicated Individual AMCS Aggregators exceeding limits: ' + aggAMCSExceedingLimitList.size() + '\n\n';
        body += 'Number of Aggregators to be eliminated: ' + aggToBeEliminatedCounter + '\n\n';
        body += 'Number of Aggregators eliminated: ' + aggEliminatedCounter + '\n\n';
        body += 'Number of Aggregators processed with errors: ' + aggNotEliminatedCounter;
        body += '\n\n\n' + 'Aggregators processed with errors: ' + '\n' + String.join(aggNotEliminatedList, '\n');
        body += '\n\n' + 'Aggregators exceeding limits: ' + '\n' + String.join(aggExceedingLimitList, '\n');
        body += '\n\n' + 'Individual AMCS Aggregators exceeding limits: ' + '\n' + String.join(aggAMCSExceedingLimitList, '\n');
        body += '\n\n' + 'Policies with conflicting Aggregator Limit Values: ' + '\n' + String.join(policiesWithConflictingAggregatorLimitValues, '\n');
        body += '\n\n' + 'Voided Policies: ' + '\n' + String.join(policiesVoidedExceptions, '\n');
        body += '\n\n' + 'Unnecesary Aggregators Policies: ' + '\n' + String.join(policiesUnnecesaryAggregatorsExceptions, '\n');
        body += '\n\n' + 'Policies with duplicated Aggregators: ' + '\n' + String.join(policiesWithDuplicatesSet, '\n');
        mail.setPlainTextBody(body);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});

        System.debug('Number of duplicated Aggregators: ' + duplicatedAggCounter);
        System.debug('Number of duplicated Aggregators exceeding limits: ' + duplicatedAggExceedingLimitCounter);
        System.debug('Number of Aggregators to be eliminated: ' + aggToBeEliminatedCounter);
        System.debug('Number of Aggregators eliminated: ' + aggEliminatedCounter);
        System.debug('Number of Aggregators processed with errors: ' + aggNotEliminatedCounter);
        System.debug('Aggregators processed with errors: ' + aggNotEliminatedList.size());
        System.debug('Aggregators exceeding limits: ' + aggExceedingLimitList.size());
        System.debug('Individual AMCS Aggregators exceeding limits: ' + aggAMCSExceedingLimitList.size());
        System.debug('Policies with duplicated Aggregators: ' + policiesWithDuplicatesSet.size());
    }

}