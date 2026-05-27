public with sharing class ARC_CreateMissingAggregators2025 {
    
    public static Map<String, Object> createAggregators2025(Set<Id> policyIds, Boolean shouldCreateMissingAggregators) {
        
        Integer missingParticipantAggregatorsCounter2025 = 0;
        Integer missingAggregatorsCounter2025 = 0;
        Set<Id> aggregatorsExceedingLimit2025 = new Set<Id>();
        Set<Id> policiesWithMissingPartAggSet2025 = new Set<Id>(); 
        Integer partAggToBeInsertedCounter2025 = 0;
        Integer partAggInsertedCounter2025 = 0;
        List<String> partAggNotInsertedList2025 = new List<String>();
        Set<Id> policiesVoidedExceptions2025 = new Set<Id>();
        Set<Id> aggregatorsMissingPolicy2025 = new Set<Id>();
        Set<Id> aggregatorsWrongPolicy2025 = new Set<Id>();
        Set<Id> aggregatorsMisslabeled2025 = new Set<Id>();
        Set<Id> noRelatedPoliciesFound2025 = new Set<Id>();
        Set<Id> familyAggregatorsMissingIndividual2025 = new Set<Id>();

        Map<String, Double> prevAggsWeShareAccess = new Map<String, Double>{
            'FLXSIG__c' => 1,
            'CLON__c' => 1,
            'CONGBIRTH__c' => 50000,
            'MAT__c' => 15000
        };

        List<InsurancePolicy> policies = [
            SELECT Id, RenewedFromPolicyId, ARC_PolicyReason__c, Product.ProductCode, ARC_EffectiveDate__c, ARC_ExpirationDate__c,
                (SELECT Id, PrimaryParticipantContact.AccountId, PrimaryParticipantContact.Birthdate, ARC_StartDate__c, ARC_EndDate__c
                FROM InsurancePolicyParticipants)
            FROM InsurancePolicy
            WHERE Id IN: policyIds
            ORDER BY ARC_Contract__r.ActivatedDate ASC
        ];
        
        Set<Id> accountIds = new Set<Id>();
        Set<Id> renewedFromPolicyIds = new Set<Id>();
        for (InsurancePolicy policy : policies) {
            if (policy.RenewedFromPolicyId != null) {
                renewedFromPolicyIds.add(policy.RenewedFromPolicyId);
            }
            for (InsurancePolicyParticipant ipp :policy.InsurancePolicyParticipants) {
                if (ipp.PrimaryParticipantContact != null) {
                    accountIds.add(ipp.PrimaryParticipantContact.AccountId);
                }
            }
        }
        Id familyAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Family').getRecordTypeId();
        Id individualAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
        List<ARC_Aggregator__c> aggregators = [
            SELECT Id, Name, ARC_Member__c, ARC_Year__c, RecordTypeId, ARC_CurrentValue__c, ARC_LimitValue__c, ARC_FamilyAggregator__c, ARC_FamilyCurrentValue__c, ARC_CreatedIn__c,
                ARC_BenefitYear__c, ARC_StartDate__c, ARC_Code__c
            FROM ARC_Aggregator__c
            WHERE ARC_IsInactive__c = false
                AND (RecordTypeId = :familyAggRT OR RecordTypeId = :individualAggRT)
                AND (
                    (ARC_CreatedIn__c IN: policyIds OR ARC_CreatedIn__c IN: renewedFromPolicyIds)
                    OR (ARC_Member__c IN: accountIds AND ARC_Code__c IN ('PREEX__c', 'MAT__c'))
                )
        ];
        // Key: policyId-name-year-participantAccount
        Map<String, ARC_Aggregator__c> individualAggMap = new Map<String, ARC_Aggregator__c>();
        // Key: policyId-year
        Map<String, ARC_Aggregator__c> familyAggMap = new Map<String, ARC_Aggregator__c>();
        // Key: name-participantAccount-benefitYear-startDate
        Map<String, ARC_Aggregator__c> individualAggEffectiveYearMap = new Map<String, ARC_Aggregator__c>();
        for (ARC_Aggregator__c agg : aggregators) {
            String key;
            if (agg.RecordTypeId == individualAggRT) {
                if (isEffectiveYear(agg.ARC_Code__c)) {
                    key = agg.Name;
                    if (agg.ARC_Member__c != null) {
                        key += '-' + agg.ARC_Member__c;
                    } else {
                        key += '-null';
                    }
                    if (agg.ARC_BenefitYear__c != null) {
                        key += '-' + agg.ARC_BenefitYear__c;
                    } else {
                        key += '-null';
                    }
                    if (agg.ARC_StartDate__c != null) {
                        key += '-' + (String.valueOf(agg.ARC_StartDate__c).replace('-', ''));
                    } else {
                        key += '-null';
                    }
                    individualAggEffectiveYearMap.put(key, agg);
                } else {
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
                }
            } else if (agg.RecordTypeId == familyAggRT) {
                key = agg.ARC_CreatedIn__c;
                if (agg.ARC_Year__c != null) {
                    key += '-' + agg.ARC_Year__c;
                    familyAggMap.put(key, agg);
                }
            }
        }
        List<ARC_ParticipantAggregator__c> partAggregators = [
            SELECT Id, Name, ARC_Aggregator__c, ARC_PolicyParticipant__c, ARC_Policy__c, ARC_Aggregator__r.ARC_Year__c, ARC_Aggregator__r.ARC_CreatedIn__c, ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId,
                ARC_Aggregator__r.ARC_StartDate__c, ARC_Aggregator__r.ARC_BenefitYear__c, ARC_Aggregator__r.ARC_Code__c
            FROM ARC_ParticipantAggregator__c
            WHERE ARC_Policy__c IN: policyIds
        ];
        // Key: policyId-name-year-participant
        Map<String, ARC_ParticipantAggregator__c> existingPartAggMap = new Map<String, ARC_ParticipantAggregator__c>();
        // Key: policyId-name-participant-benefitYear-startDate
        Map<String, ARC_ParticipantAggregator__c> existingPartAggEffectiveYearMap = new Map<String, ARC_ParticipantAggregator__c>();
        for (ARC_ParticipantAggregator__c partAgg : partAggregators) {
            String key = partAgg.ARC_Policy__c + '-' + partAgg.Name;
            if (isEffectiveYear(partAgg.ARC_Aggregator__r.ARC_Code__c)) {
                if (partAgg.ARC_PolicyParticipant__c != null) {
                    key += '-' + partAgg.ARC_PolicyParticipant__c;
                } else {
                    key += '-null';
                }
                if (partAgg.ARC_Aggregator__r.ARC_BenefitYear__c != null) {
                    key += '-' + partAgg.ARC_Aggregator__r.ARC_BenefitYear__c;
                } else {
                    key += '-null';
                }
                if (partAgg.ARC_Aggregator__r.ARC_StartDate__c != null) {
                    key += '-' + (String.valueOf(partAgg.ARC_Aggregator__r.ARC_StartDate__c).replace('-', ''));
                } else {
                    key += '-null';
                }
                existingPartAggEffectiveYearMap.put(key, partAgg);
            } else {
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
        }

        Map<Id, List<String>> preExBenefitYearMapByAccount = createBenefitYearMap(accountIds, 'PREEX__c');
        Map<Id, List<String>> matBenefitYearMapByAccount = createBenefitYearMap(accountIds, 'MAT__c');

        // Map with Participant Aggregator Key (unique), and its Aggregator Key to be linked to the corresponding Aggregator
        Map<String, String> partAggKeyToAggKey = new Map<String, String>();
        Map<String, ARC_ParticipantAggregator__c> partAggToInsert = new Map<String, ARC_ParticipantAggregator__c>();
        
        // Related carry-over policies
        List<InsurancePolicy> policiesRenewedFrom = [
            SELECT Id, RenewedFromPolicyId, Product.ProductCode, ARC_Contract__r.Status, ARC_Contract__r.ActivatedDate, ARC_Contract__r.ARC_Reactivated__c, ARC_EffectiveDate__c, ARC_ExpirationDate__c, ARC_PolicyReason__c,
                (SELECT Id, PrimaryParticipantContact.AccountId
                FROM InsurancePolicyParticipants)
            FROM InsurancePolicy
            WHERE (Id IN: policyIds OR RenewedFromPolicyId IN :policyIds) 
                AND (ARC_Contract__r.Status = 'Activated' OR ARC_Contract__r.Status = 'Terminated')
                AND CALENDAR_YEAR(ARC_EffectiveDate__c) <= 2025
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
                if (maxYear > 2025) maxYear = 2025;
                for (Integer year = minYear; year <= maxYear; year++) {
                    System.debug('policy.Product.ProductCode: ' + policy.Product.ProductCode);
                    System.debug('year: ' + year);
                    Id renewedPol = isUpgradePolicy(policy.ARC_PolicyReason__c) ? policy.Id : policy.RenewedFromPolicyId;
                    String famAggKey = renewedPol + '-' + String.valueOf(year);
                    List<InsurancePolicy> relatedPolicies;
                    if (!relatedPoliciesMap.containsKey(renewedPol)) {
                        policiesVoidedExceptions2025.add(renewedPol);
                        System.debug('entro 1');
                        continue;
                    } else {
                        System.debug('entro 2');
                        relatedPolicies = relatedPoliciesMap.get(renewedPol).get(year);
                        if (relatedPolicies == null) {
                            System.debug('entro 3');
                            noRelatedPoliciesFound2025.add(policy.Id);
                            continue;
                        }
                    }
                    ARC_ProductAggregators__mdt lastAggregatorsMetadata = getLastValidAggregatorLimits(relatedPolicies);
                    if (familyAggMap.get(famAggKey) == null) {
                        System.debug('famAggKey creation: ' + famAggKey);
                        // Create Family AMCS
                        missingAggregatorsCounter2025++;
                        policiesWithMissingPartAggSet2025.add(policy.Id);
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
                        System.debug('famAgg created: ' + famAgg);
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
                            aggregatorsExceedingLimit2025.add(famAgg.Id);
                        }
                    }
                }                
            }
        }

        // Upsertion of Family AMCS
        if (shouldCreateMissingAggregators) {
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
                String planCode = policy.Product.ProductCode;
                String aggCode = getAggregatorCode(expectedAggregator);
                if (aggCode == 'TOB__c' && planCode != 'PROG_UHSM_Access10k' && planCode != 'PROG_WeShareLegacy') {
                    continue;
                }
                Boolean allowNullForAccessPlans =
                    (planCode == 'PROG_UHSM_Access10k' || planCode == 'PROG_UHSM_Access5k')
                    && prevAggsWeShareAccess.containsKey(aggCode);
                if (
                    isNewAggregator2026(expectedAggregator) 
                    || !isIndividualAggregator(expectedAggregator) 
                    || (aggValues.get(expectedAggregator) == null && !allowNullForAccessPlans)
                ) {
                    continue;
                }
                String aggregatorName = expectedAggregator.getDescribe().getLabel();
                System.debug('aggregatorName ' + aggregatorName);
                for (InsurancePolicyParticipant participant : policy.InsurancePolicyParticipants) {
                    if (participant.PrimaryParticipantContact == null || participant.PrimaryParticipantContact.Birthdate == null) {
                        continue;
                    } // Skip IPP with missing information (contact, birthdate)
                    Id accountId = participant.PrimaryParticipantContact.AccountId;
                    Id renewedPol = isUpgradePolicy(policy.ARC_PolicyReason__c) ? policy.Id : policy.RenewedFromPolicyId;
                    if (!isEffectiveYear(expectedAggregator)) {
                        Integer minYear = participant.ARC_StartDate__c.year();
                        Integer maxYear;
                        if (isOneTime(expectedAggregator) || isLifeTime(expectedAggregator)) {
                            maxYear = minYear;
                        } else {
                            maxYear = participant.ARC_EndDate__c == null ? Date.Today().year() : participant.ARC_EndDate__c.year();
                            if (maxYear > 2025) maxYear = 2025;
                        }
                        System.debug('participant ' + participant);
                        System.debug('minYear ' + minYear);
                        System.debug('maxYear ' + maxYear);
                        for (Integer year = minYear; year <= maxYear; year++) {
                            System.debug('year ' + year);
                            String partAggKey;
                            List<InsurancePolicy> relatedPolicies;
                            // Get related policies to find correct limit values
                            if (isOneTime(expectedAggregator) || isLifeTime(expectedAggregator)) {
                                partAggKey = policy.Id + '-' + aggregatorName + '-null-' + participant.Id;  
                                if (!relatedPoliciesOfParticipantMap.containsKey(renewedPol)) {
                                    policiesVoidedExceptions2025.add(renewedPol);
                                    continue;
                                } else {
                                    relatedPolicies = relatedPoliciesOfParticipantMap.get(renewedPol).get(accountId);
                                }
                            } else {
                                partAggKey = policy.Id + '-' + aggregatorName + '-' + year + '-' + participant.Id;
                                if (!relatedPoliciesOfParticipantPerYearMap.containsKey(renewedPol)) {
                                    policiesVoidedExceptions2025.add(renewedPol);
                                    continue;
                                } else {
                                    relatedPolicies = relatedPoliciesOfParticipantPerYearMap.get(renewedPol).get(accountId).get(Integer.valueOf(year));
                                }
                            }
                            ARC_ProductAggregators__mdt lastAggregatorsMetadata = getLastValidAggregatorLimits(relatedPolicies);
                            if (existingPartAggMap.get(partAggKey) == null) {
                                // Create new Participant Aggregator
                                missingParticipantAggregatorsCounter2025++;
                                policiesWithMissingPartAggSet2025.add(policy.Id);
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
                                            aggregatorsExceedingLimit2025.add(aggregator.Id);
                                        }
                                    // For 'Maternity' or 'Pre Existing Conditions' does not update limit value
                                    } else if (aggregatorName == 'Maternity' || aggregatorName == 'Pre Existing Conditions') {
                                        if (aggregator.ARC_CurrentValue__c == null || (aggregator.ARC_CurrentValue__c != null && aggregator.ARC_LimitValue__c >= aggregator.ARC_CurrentValue__c)) {
                                            partAggToInsert.put(partAggKey, newPartAgg);
                                        } else {
                                            aggregatorsExceedingLimit2025.add(aggregator.Id);
                                        }
                                    }
                                } else {
                                    // Create new Aggregator
                                    partAggToInsert.put(partAggKey, newPartAgg);
                                    missingAggregatorsCounter2025++;
                                    ARC_Aggregator__c newAggregator = new ARC_Aggregator__c();
                                    newAggregator.RecordTypeId = individualAggRT;
                                    newAggregator.Name = aggregatorName;
                                    if (lastAggregatorsMetadata.get(expectedAggregator) != null) {
                                        newAggregator.ARC_LimitValue__c = Double.valueOf((Double)lastAggregatorsMetadata.get(expectedAggregator));
                                    } else if (allowNullForAccessPlans) {
                                        newAggregator.ARC_LimitValue__c = prevAggsWeShareAccess.get(aggCode);
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
                                        newAggregator.ARC_NextAvailabilityDate__c = participant.ARC_StartDate__c;
                                    }
                                    individualAggMap.put(aggKey, newAggregator);
                                }
                            } else {
                                // Update Aggregator LimitValue (for non 'Maternity' or 'Pre Existing Conditions')
                                ARC_ParticipantAggregator__c existingPartAgg = existingPartAggMap.get(partAggKey);
                                String aggKey;
                                if (existingPartAgg.ARC_Aggregator__r.ARC_CreatedIn__c == null) {
                                    aggregatorsMissingPolicy2025.add(existingPartAgg.ARC_Aggregator__c);
                                    continue;
                                } else if (isUpgradePolicy(policy.ARC_PolicyReason__c) && existingPartAgg.ARC_Aggregator__r.ARC_CreatedIn__c != policy.Id) {
                                    aggregatorsWrongPolicy2025.add(policy.Id);
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
                                        aggregatorsMisslabeled2025.add(existingPartAgg.Id);
                                        continue;
                                    }
                                    Double newLimitValue = Double.valueOf((Double)lastAggregatorsMetadata.get(expectedAggregator));
                                    if (aggregator.ARC_CurrentValue__c == null || (aggregator.ARC_CurrentValue__c != null && newLimitValue >= aggregator.ARC_CurrentValue__c)) {
                                        aggregator.ARC_LimitValue__c = newLimitValue;
                                    } else {
                                        aggregatorsExceedingLimit2025.add(aggregator.Id);
                                    }
                                }
                            }
                        }
                    } else {
                        // Effective Year
                        List<String> benefitYearList;
                        String code = getAggregatorCode(expectedAggregator);
                        if (code == 'PREEX__c' && preExBenefitYearMapByAccount.containsKey(accountId)) {
                            benefitYearList = preExBenefitYearMapByAccount.get(accountId);
                        } else if (code == 'MAT__c' && matBenefitYearMapByAccount.containsKey(accountId)) {
                            benefitYearList = matBenefitYearMapByAccount.get(accountId);
                        }
                        if (benefitYearList == null) continue;
                        for (String benefitYear : benefitYearList) {
                            List<String> benefitYearSections = benefitYear.split('\\|\\|');
                            Date startDate = Date.valueOf(benefitYearSections[0]);
                            Date endDate = Date.valueOf(benefitYearSections[1]);
                            String year = benefitYearSections[2];
                            if (endDate < participant.ARC_StartDate__c) continue;
                            if (endDate >= participant.ARC_StartDate__c && (participant.ARC_EndDate__c == null || participant.ARC_EndDate__c >= startDate)) {
                                String partAggKey = policy.Id + '-' + aggregatorName + '-' + participant.Id + '-' + year + '-' + (String.valueOf(startDate).replace('-', ''));
                                if (existingPartAggEffectiveYearMap.containsKey(partAggKey)) continue;
                                missingParticipantAggregatorsCounter2025++;
                                policiesWithMissingPartAggSet2025.add(policy.Id);
                                String aggKey = aggregatorName + '-' + accountId + '-' + year + '-' + (String.valueOf(startDate).replace('-', ''));
                                ARC_Aggregator__c agg = individualAggEffectiveYearMap.get(aggKey);
                                if (agg == null) {
                                    missingAggregatorsCounter2025++;
                                    agg = new ARC_Aggregator__c();
                                    agg.RecordTypeId = individualAggRT;
                                    agg.Name = aggregatorName;
                                    agg.ARC_LimitValue__c = getBenefitYearLimit(year);
                                    agg.ARC_Code__c = code;
                                    agg.ARC_Type__c = getAggregatorType(expectedAggregator);
                                    agg.ARC_Member__c = accountId;
                                    agg.ARC_CreatedIn__c = renewedPol;
                                    agg.ARC_StartDate__c = startDate;
                                    agg.ARC_EndDate__c = endDate;
                                    agg.ARC_BenefitYear__c = year;
                                    individualAggEffectiveYearMap.put(aggKey, agg);
                                }
                                ARC_ParticipantAggregator__c newPartAgg = new ARC_ParticipantAggregator__c();
                                newPartAgg.Name = aggregatorName;
                                newPartAgg.ARC_ConsumedValue__c = 0;
                                newPartAgg.ARC_Policy__c = policy.Id;
                                newPartAgg.ARC_PolicyParticipant__c = participant.Id;
                                partAggToInsert.put(partAggKey, newPartAgg);
                                partAggKeyToAggKey.put(partAggKey, aggKey);
                            }
                        }
                    }
                }
            }
        }

        // Links individual AMCS to Family aggregator
        InsurancePolicyId = '';
        for (InsurancePolicy policy : policies) {
            InsurancePolicyId = policy.Id;
            ARC_ProductAggregators__mdt aggValues = ARC_ProductAggregators__mdt.getInstance(policy.Product.ProductCode);
            Boolean linkIndividualsToFamily = aggValues.get('FAM_AMCS__c') != null;
            System.debug('policy.Product.ProductCode: ' + policy.Product.ProductCode);
            System.debug('aggValues: ' + aggValues);
            System.debug('aggValues.get(FAM_AMCS__c): ' + aggValues.get('FAM_AMCS__c'));
            System.debug('linkIndividualsToFamily: ' + linkIndividualsToFamily);
            if (linkIndividualsToFamily) {
                Integer minYear = policy.ARC_EffectiveDate__c.year();
                Integer maxYear = policy.ARC_ExpirationDate__c == null ? Date.Today().year() : policy.ARC_ExpirationDate__c.year();
                if (maxYear > 2025) maxYear = 2025;
                
                for (Integer year = minYear; year <= maxYear; year++) {
                    String famKey = isUpgradePolicy(policy.ARC_PolicyReason__c) ? policy.Id + '-' + year : policy.RenewedFromPolicyId + '-' + year;
                    System.debug('famKey: ' + famKey);
                    ARC_Aggregator__c famAgg = familyAggMap.get(famKey);
                    
                    for (InsurancePolicyParticipant participant : policy.InsurancePolicyParticipants) {
                        String IPPAccount = participant.PrimaryParticipantContact.AccountId;
                        if (IPPAccount == null || famAgg == null) continue;
                        if (famAgg.ARC_CreatedIn__c == null) { 
                            aggregatorsMissingPolicy2025.add(famAgg.Id); 
                            continue;
                        } else if (isUpgradePolicy(policy.ARC_PolicyReason__c) && famAgg.ARC_CreatedIn__c != policy.Id) {
                            aggregatorsWrongPolicy2025.add(policy.Id);
                            continue;
                        }
                        String indKeyPrefix = famAgg.ARC_CreatedIn__c + '-Individual AMCS-' + year + '-' + IPPAccount;
                        
                        ARC_Aggregator__c indAMCS = individualAggMap.get(indKeyPrefix);
                        if (indAMCS == null) {
                            familyAggregatorsMissingIndividual2025.add(famAgg.Id);
                            continue;
                        }
                        if (indAMCS.ARC_FamilyAggregator__c != famAgg.Id && indAMCS.ARC_CurrentValue__c != null) {
                            famAgg.ARC_FamilyCurrentValue__c += indAMCS.ARC_CurrentValue__c;   
                            if (famAgg.ARC_FamilyCurrentValue__c > famAgg.ARC_LimitValue__c ) {
                                famAgg.ARC_FamilyCurrentValue__c -= indAMCS.ARC_CurrentValue__c;
                                aggregatorsExceedingLimit2025.add(famAgg.Id);
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

        // Upserts individual aggregators
        if (shouldCreateMissingAggregators) {
            try {
                for (String key : individualAggMap.keySet()) {
                    ARC_Aggregator__c agg = individualAggMap.get(key);
                    if (agg.ARC_CurrentValue__c != null && agg.ARC_CurrentValue__c > agg.ARC_LimitValue__c) {
                        individualAggMap.remove(key);
                    }
                }
                List<ARC_Aggregator__c> aggToUpsert = new List<ARC_Aggregator__c>();
                if (!individualAggMap.isEmpty()) aggToUpsert.addAll(individualAggMap.values());
                if (!individualAggEffectiveYearMap.isEmpty()) aggToUpsert.addAll(individualAggEffectiveYearMap.values());
                if (!aggToUpsert.isEmpty()) upsert aggToUpsert;
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
            ARC_Aggregator__c aggregator = individualAggMap.containsKey(aggKey) ? individualAggMap.get(aggKey) : individualAggEffectiveYearMap.get(aggKey);
            ARC_ParticipantAggregator__c partAgg = partAggToInsert.get(partAggKey);
            partAgg.ARC_Aggregator__c = aggregator.Id;
        }
        
        // Insert Participant Aggregators
        if (shouldCreateMissingAggregators) {
            try {
                partAggToBeInsertedCounter2025 += partAggToInsert.size();
                insert partAggToInsert.values();
                partAggInsertedCounter2025 += partAggToInsert.size();
            }  catch (Exception e) {
                partAggNotInsertedList2025.addAll(partAggToInsert.keySet());
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

        Map<String, Object> results = new Map<String, Object>{
            'missingParticipantAggregatorsCounter2025' => missingParticipantAggregatorsCounter2025,
            'missingAggregatorsCounter2025' => missingAggregatorsCounter2025,
            'aggregatorsExceedingLimit2025' => aggregatorsExceedingLimit2025,
            'policiesWithMissingPartAggSet2025' => policiesWithMissingPartAggSet2025,
            'partAggToBeInsertedCounter2025' => partAggToBeInsertedCounter2025,
            'partAggInsertedCounter2025' => partAggInsertedCounter2025,
            'partAggNotInsertedList2025' => partAggNotInsertedList2025,
            'policiesVoidedExceptions2025' => policiesVoidedExceptions2025,
            'aggregatorsMissingPolicy2025' => aggregatorsMissingPolicy2025,
            'aggregatorsWrongPolicy2025' => aggregatorsWrongPolicy2025,
            'aggregatorsMisslabeled2025' => aggregatorsMisslabeled2025,
            'noRelatedPoliciesFound2025' => noRelatedPoliciesFound2025,
            'familyAggregatorsMissingIndividual2025' => familyAggregatorsMissingIndividual2025
        };

        return results;
    }

    // UTILITY METHODS //

    private static List<Schema.SObjectField> getAggregatorsFields(ARC_ProductAggregators__mdt aggregatorValues) {
        return aggregatorValues.getSObjectType().getDescribe().fields.getMap().values();
    }

    private static Boolean isUpgradePolicy(String policyReasons) {
        List<String> UPGRADE_REASONS = new List<String>{'Aging Out', 'New Application', 'Program Upgrade', 'Upgraded Spin Off'};
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

    private static Boolean isOneTime(Schema.SObjectField aggregatorField) {
        String aggregatorCode = getAggregatorCode(aggregatorField);
        List<String> ONE_TIME = new List<String>{'CCS__c', 'CLON__c', 'FLXSIG__c', 'MAMM__c', 'PROSCRE__c', 'SSOPT__c'};
        return ONE_TIME.contains(aggregatorCode);
    }

    private static Boolean isLifeTime(Schema.SObjectField aggregatorField) {
        String aggregatorCode = getAggregatorCode(aggregatorField);
        List<String> LIFETIME = new List<String>{'ALGTEST__c'};
        return LIFETIME.contains(aggregatorCode);
    }

    private static Boolean isIndividualAggregator(Schema.SObjectField aggregatorField) {
        return String.valueOf(aggregatorField).startsWith('IND_');
    }

    private static Boolean isFamilyAggregator(Schema.SObjectField aggregatorField) {
        return String.valueOf(aggregatorField).startsWith('FAM_');
    }

    private static String getAggregatorCode(Schema.SObjectField aggregatorField) {
        String fullFieldCode = String.valueOf(aggregatorField);
        if (fullFieldCode.startsWith('IND_') || fullFieldCode.startsWith('FAM_')) {
            return fullFieldCode.substring(4);
        } else {
            return fullFieldCode;
        }
    }

    private static String getAggregatorType(Schema.SObjectField aggregatorField) {
        String aggregatorCode = getAggregatorCode(aggregatorField);
        String aggregatorType;
        switch on aggregatorCode {
            when 'ACC__c', 'CCS__c', 'CHIRO__c', 'CLON__c', 'FLXSIG__c', 'HTERAPHPY__c', 'MAMM__c', 'OFUC__c', 'PHYTH__c', 'PROSCRE__c', 'PSYCH__c', 'SSOPT__c' {
                aggregatorType = 'Number';
            }
            when 'ALGTEST__c', 'AMCS__c', 'CONGBIRTH__c', 'DME__c', 'MAT__c', 'PREEX__c', 'SHAMCS__c', 'TOB__c' {
                aggregatorType = 'Currency';
            }
        }
        return aggregatorType;
    }

    private static Boolean isNewAggregator2026(Schema.SObjectField aggregatorField) {
        String aggregatorCode = getAggregatorCode(aggregatorField);
        List<String> NEW_AGGS = new List<String>{'BOSCR__c', 'CBIPAP__c', 'CRITILL__c', 'GENINJ__c', 'LIFE__c', 'NONINJ__c', 'SHINVAC__c', 'SLEEP__c', 'SPEINJ__c', 'STDINJ__c', 'WOVIS__c'};
        return NEW_AGGS.contains(aggregatorCode);
    }

    private static ARC_ProductAggregators__mdt getLastValidAggregatorLimits(List<insurancePolicy> policies) {
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

    private static Map<Id, List<String>> createBenefitYearMap(Set<Id> personAccounts, String code) {
        Map<Id, List<String>> benefitYearMap = new Map<Id, List<String>>();
        Map<Id, List<Map<String, Object>>> coveragePeriodsMap = ARC_SMBUtility.mapCoveragePeriods(new List<Id>(personAccounts), code);
        for (Id accountId : coveragePeriodsMap.keySet()) {
            List<String> aggregatorsPerPeriod = ARC_SMBUtility.calculateAggregators(coveragePeriodsMap.get(accountId), code);
            benefitYearMap.put(accountId, aggregatorsPerPeriod);
        }
        return benefitYearMap;
    }

    private static Boolean isEffectiveYear(String aggregatorCode) {
        List<String> EFFECTIVE_YEAR = new List<String>{'MAT__c', 'PREEX__c'};
        return EFFECTIVE_YEAR.contains(aggregatorCode);
    }

    private static Boolean isEffectiveYear(Schema.SObjectField aggregatorField) {
        String aggregatorCode = getAggregatorCode(aggregatorField);
        List<String> EFFECTIVE_YEAR = new List<String>{'MAT__c', 'PREEX__c'};
        return EFFECTIVE_YEAR.contains(aggregatorCode);
    }

    private static Double getBenefitYearLimit(String benefitYear) {
        switch on benefitYear {
            when 'BY1' {
                return 15000;
            }
            when 'BY2' {
                return 25000;
            }
            when 'BY3' {
                return 50000;
            }
            when else {
                return null;
            }
        }
    }
}