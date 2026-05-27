/*******************************************************************
 * @ClassName          :   ARC_CreateMissingAggregatorsV2
 * @Description        :   Batchable Apex class that detects if a ParticipantAggregator is missing, and its corresponding Aggregator
 *                         In case of having missing records they are created
 *                         New Aggregators get created if the corresponding Aggregator is not found; AMCS/Tobacco if it's an Upgrade or Spin Off; AMCS if it's a Downgrade 
 *                         For years previous 2026, a new set of Aggregators was created in every Program Upgrade
 *                         - Batch execution can be run to update or create any missing aggregators on the queried Policies. 
 *                         - Shedulable execution runs daily for Policies activated or reactivated on that date.
 *                         - It assumes that all previous Policies have their set of Aggregators correct. 
 ********************************************************************/
global class ARC_CreateMissingAggregatorsV2 implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    // Definitions
    private List<String> ONE_TIME = new List<String>{'BOSCR__c', 'CCS__c', 'CLON__c', 'FLXSIG__c', 'MAMM__c', 'PROSCRE__c', 'SSOPT__c', 'WOVIS__c'};
    private List<String> LIFETIME = new List<String>{'ALGTEST__c', 'LIFE__c', 'SHINVAC__c'};
    private List<String> MONTHLY = new List<String>{'CRITILL__c'};
    private List<String> EFFECTIVE_YEAR = new List<String>{'MAT__c', 'PREEX__c'};
    private List<String> CALENDAR_YEAR = new List<String>{'ACC__c', 'AMCS__c', 'CBIPAP__c', 'CHIRO__c', 'CONGBIRTH__c', 'DME__c', 'GENINJ__c', 'HTERAPHPY__c', 'NONINJ__c', 'OFUC__c', 'PHYTH__c', 'PSYCH__c', 'SHAMCS__c', 'SLEEP__c', 'SPEINJ__c', 'STDINJ__c', 'TOB__c'};
    private List<String> NUMBER_TYPE = new List<String>{'ACC__c', 'BOSCR__c', 'CCS__c', 'CHIRO__c', 'CLON__c', 'FLXSIG__c', 'GENINJ__c', 'HTERAPHPY__c', 'MAMM__c', 'NONINJ__c', 'OFUC__c', 'PHYTH__c', 'PROSCRE__c', 'PSYCH__c', 'SHINVAC__c', 'SLEEP__c', 'SPEINJ__c', 'SSOPT__c', 'STDINJ__c', 'WOVIS__c'};
    private List<String> CURRENCY_TYPE = new List<String>{'ALGTEST__c', 'AMCS__c', 'CBIPAP__c', 'CONGBIRTH__c', 'CRITILL__c', 'DME__c', 'LIFE__c', 'MAT__c', 'PREEX__c', 'SHAMCS__c', 'TOB__c'};
    private List<String> UPGRADE_REASONS = new List<String>{'Aging Out', 'New Application', 'Program Upgrade', 'Upgraded Spin Off'};

    // Settings
    private String whereClause;
    private Boolean shouldCreateMissingAggregators = false;
    private Boolean sendEmail = true;

    // Report Counters
    private Integer missingAggregatorsCounter = 0;
    private Integer missingParticipantAggregatorsCounter = 0;
    private Set<Id> policiesWithMissingPartAggSet = new Set<Id>();
    private Integer partAggToBeInsertedCounter = 0;
    private Integer partAggInsertedCounter = 0;
    private List<String> partAggNotInsertedList = new List<String>();
    private Integer aggToBeInsertedCounter = 0;
    private Integer aggInsertedCounter = 0;
    private List<String> aggNotInsertedList = new List<String>();

    // Report Counters (< 2026)
    Boolean hadPrev2026Policy = false;
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

    
        /*********************************************************************************************************
     * @name            ARC_CreateMissingAggregatorsV2 
     * @description     Batch can be executed on demand for any set of policies that fulfill the WHERE clause. 
     *                  sendEmail flag will be set in false and the user WILL recieve the report by email. (flag is not an input parameter)
     *                  - whereClause: can be set as an input param.
     *                  - shouldCreateMissingAggregators if set to FALSE will NOT upsert records, 
     *                    generating the report without making any changes in the org.
     *                  EXAMPLE:
     *                  ARC_CreateMissingAggregatorsV2 batch = new ARC_CreateMissingAggregatorsV2('Id = \'XXXXX\')', false);
     *                  Database.executeBatch(batch, 100); --> use batch 100 on large sets of policies to avoid DML limits
     * @param           String whereClause
     * @param           Boolean shouldCreateMissingAggregatorsV2
     * *********************************************************************************************************/
    global ARC_CreateMissingAggregatorsV2(String whereClause, Boolean shouldCreateMissingAggregators, Boolean sendEmail) {
        this.whereClause = whereClause;
        this.shouldCreateMissingAggregators = shouldCreateMissingAggregators;
        this.sendEmail = sendEmail;
    }

    global ARC_CreateMissingAggregatorsV2() {
        this.whereClause = whereClause;
        this.shouldCreateMissingAggregators = shouldCreateMissingAggregators;
    }

    /********************************************************************************************************* 
     * @name            execute
     * @description     Executes daily for policies activated or reactivated on that date. 
     *                  sendEmail flag will prevent report email to be sent. 
     *                  shouldCreateMissingAggregators = true will enable the upsert of necessary aggregators*
     * @param           SchedulableContext
     * *********************************************************************************************************/
    global void execute(SchedulableContext SC) {
        this.whereClause = '(ARC_Contract__r.ActivatedDate = TODAY OR ARC_Contract__r.ARC_Reactivated__c = TODAY) AND ARC_Contract__r.Status != \'Voided\'';
        this.shouldCreateMissingAggregators = true;
        this.sendEmail = false;

        Database.executeBatch(this, 30);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM InsurancePolicy';
        if (this.whereClause != null) {
            query += ' WHERE ARC_Contract__r.RecordType.Name = \'Individual and Family\' AND (' + this.whereClause + ')';
        } else {
            query += ' WHERE ARC_Contract__r.RecordType.Name = \'Individual and Family\' AND (ARC_Contract__r.Status = \'Activated\' OR ARC_Contract__r.Status = \'Terminated\')';
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
            SELECT Id, RenewedFromPolicyId, ARC_PolicyReason__c, Product.ProductCode, ARC_EffectiveDate__c, ARC_ExpirationDate__c, ARC_Contract__r.CreatedDate, ARC_SpinnedFromPolicy__c,
                ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.vlocity_ins__GroupId__c, ARC_SpinnedFromPolicy__r.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.vlocity_ins__GroupId__c,
                (SELECT Id, PrimaryParticipantContact.AccountId, ARC_StartDate__c, ARC_EndDate__c
                FROM InsurancePolicyParticipants)
            FROM InsurancePolicy
            WHERE Id IN: policyIds
            ORDER BY ARC_Contract__r.ActivatedDate ASC
        ];
        
        Set<Id> accountIds = new Set<Id>();
        Set<Id> personAccountIds = new Set<Id>();
        Set<Id> prev2026PolicySet = new Set<Id>();
        Map<Id, InsurancePolicy> policiesMap = new Map<Id, InsurancePolicy>();
        for (InsurancePolicy policy : policies) {
            policiesMap.put(policy.Id, policy);
            for (InsurancePolicyParticipant participant : policy.InsurancePolicyParticipants) {
                if (participant.PrimaryParticipantContact.AccountId != null) {
                    accountIds.add(participant.PrimaryParticipantContact.AccountId);
                    personAccountIds.add(participant.PrimaryParticipantContact.AccountId);
                }
                if (policy.ARC_EffectiveDate__c.year() < 2026) {
                    prev2026PolicySet.add(policy.Id);
                }
            }
            accountIds.add(policy.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.vlocity_ins__GroupId__c);
        }

        Map<String, Object> report2025;

        //******************************//
        // Process policies before 2025 //
        //******************************//

        if (!prev2026PolicySet.isEmpty()) {
            hadPrev2026Policy = true;
            report2025 = ARC_CreateMissingAggregators2025.createAggregators2025(prev2026PolicySet, shouldCreateMissingAggregators);

            missingParticipantAggregatorsCounter2025 += (Integer) report2025.get('missingParticipantAggregatorsCounter2025');
            missingAggregatorsCounter2025 += (Integer) report2025.get('missingAggregatorsCounter2025');
            partAggToBeInsertedCounter2025 += (Integer) report2025.get('partAggToBeInsertedCounter2025');
            partAggInsertedCounter2025 += (Integer) report2025.get('partAggInsertedCounter2025');
            aggregatorsExceedingLimit2025.addAll((Set<Id>) report2025.get('aggregatorsExceedingLimit2025'));
            policiesWithMissingPartAggSet2025.addAll((Set<Id>) report2025.get('policiesWithMissingPartAggSet2025'));
            policiesVoidedExceptions2025.addAll((Set<Id>) report2025.get('policiesVoidedExceptions2025'));
            aggregatorsMissingPolicy2025.addAll((Set<Id>) report2025.get('aggregatorsMissingPolicy2025'));
            aggregatorsWrongPolicy2025.addAll((Set<Id>) report2025.get('aggregatorsWrongPolicy2025'));
            aggregatorsMisslabeled2025.addAll((Set<Id>) report2025.get('aggregatorsMisslabeled2025'));
            noRelatedPoliciesFound2025.addAll((Set<Id>) report2025.get('noRelatedPoliciesFound2025'));
            familyAggregatorsMissingIndividual2025.addAll((Set<Id>) report2025.get('familyAggregatorsMissingIndividual2025'));
            partAggNotInsertedList2025.addAll((List<String>) report2025.get('partAggNotInsertedList2025'));
        }

        Map<Id, List<String>> preExBenefitYearMapByAccount = createBenefitYearMap(personAccountIds, 'PREEX__c');
        Map<Id, List<String>> matBenefitYearMapByAccount = createBenefitYearMap(personAccountIds, 'MAT__c');
        
        Id familyAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Family').getRecordTypeId();
        Id individualAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
        List<ARC_Aggregator__c> aggregators = [
            SELECT Id, Name, ARC_Member__c, ARC_Year__c, RecordTypeId, ARC_CurrentValue__c, ARC_LimitValue__c, ARC_FamilyAggregator__c, ARC_FamilyCurrentValue__c, ARC_CarryOverConsumed__c,
                ARC_CreatedIn__c, ARC_CreatedIn__r.ARC_EffectiveDate__c, ARC_CreatedIn__r.ARC_Contract__r.CreatedDate, ARC_Code__c, ARC_BenefitYear__c, ARC_StartDate__c
            FROM ARC_Aggregator__c
            WHERE ARC_Member__c IN: accountIds 
                AND ARC_IsInactive__c = false
                AND (RecordTypeId = :familyAggRT OR RecordTypeId = :individualAggRT)
        ];
        List<vlocity_ins__GroupCensusMemberPlan__c> relatedGCMP = [
            SELECT Id, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c
            FROM vlocity_ins__GroupCensusMemberPlan__c
            WHERE vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId IN :accountIds
                AND (vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Activated' OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Terminated')
                AND vlocity_ins__ContractLineId__r.vlocity_ins__ParentItemId__c = null
                AND vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical'
        ];
        Map<Id, Set<Id>> contractToAccounts = new Map<Id, Set<Id>>();
        for (vlocity_ins__GroupCensusMemberPlan__c gcmp : relatedGCMP) {
            Id contractId = gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c;
            Id accountId = gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId;
            if (contractId == null || accountId == null) continue;

            if (!contractToAccounts.containsKey(contractId)) {
                contractToAccounts.put(contractId, new Set<Id>());
            }
            contractToAccounts.get(contractId).add(accountId);
        }
        Set<Id> contractIds = new Set<Id>();
        for (vlocity_ins__GroupCensusMemberPlan__c gcmp : relatedGCMP) {
            contractIds.add(gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c);
        }
        List<InsurancePolicy> relatedPolicies = [
            SELECT Id, ARC_EffectiveDate__c, ARC_ExpirationDate__c, ARC_Contract__c
            FROM InsurancePolicy
            WHERE ARC_Contract__c IN :contractIds
            ORDER BY ARC_Contract__r.ARC_EffectiveDate__c ASC, ARC_Contract__r.CreatedDate ASC
        ];
        Map<Id, List<InsurancePolicy>> accountIdToRelatedPolicies = new Map<Id, List<InsurancePolicy>>();
        for (InsurancePolicy policy : relatedPolicies) {
            Set<Id> accounts = contractToAccounts.get(policy.ARC_Contract__c);
            if (accounts == null) continue;
            for (Id accId : accounts) {
                if (!accountIdToRelatedPolicies.containsKey(accId)) {
                    accountIdToRelatedPolicies.put(accId, new List<InsurancePolicy>());
                }
                accountIdToRelatedPolicies.get(accId).add(policy);
            }
        }


        // Key: participantAccount-name-(year//benefitYear)
        Map<String, List<ARC_Aggregator__c>> individualAggMap = new Map<String, List<ARC_Aggregator__c>>();
        // Key: familyAccount-year
        Map<String, List<ARC_Aggregator__c>> familyAggMap = new Map<String, List<ARC_Aggregator__c>>();

        for (ARC_Aggregator__c agg : aggregators) {
            policiesMap.put(agg.ARC_CreatedIn__c, agg.ARC_CreatedIn__r);
            String key;
            if (agg.RecordTypeId == individualAggRT) {
                if (isMonthly(agg.ARC_Code__c) || isOneTime(agg.ARC_Code__c) || isLifeTime(agg.ARC_Code__c)) {
                    key = agg.ARC_Member__c + '-' + agg.Name + '-null';
                    List<ARC_Aggregator__c> aggList = individualAggMap.get(key);
                    if (aggList == null) {
                        aggList = new List<ARC_Aggregator__c>{agg};
                        individualAggMap.put(key, aggList);
                    } else {
                        ARC_Aggregator__c aggIncluded = aggList[0];
                        if (
                            (aggIncluded.ARC_CreatedIn__r.ARC_EffectiveDate__c < agg.ARC_CreatedIn__r.ARC_EffectiveDate__c) 
                            || ((aggIncluded.ARC_CreatedIn__r.ARC_EffectiveDate__c == agg.ARC_CreatedIn__r.ARC_EffectiveDate__c)
                                && aggIncluded.ARC_CreatedIn__r.ARC_Contract__r.CreatedDate < agg.ARC_CreatedIn__r.ARC_Contract__r.CreatedDate)
                        ) {
                            aggList[0] = agg;
                        }
                    }
                } else if (isCalendarYear(agg.ARC_Code__c)) {
                    key = agg.ARC_Member__c + '-' + agg.Name + '-' + agg.ARC_Year__c;
                    List<ARC_Aggregator__c> aggList = individualAggMap.get(key);
                    if (aggList == null) {
                        aggList = new List<ARC_Aggregator__c>{agg};
                        individualAggMap.put(key, aggList);
                    } else {
                        aggList.add(agg);
                    }
                } else if (isEffectiveYear(agg.ARC_Code__c)) {
                    key = agg.ARC_Member__c + '-' + agg.Name + '-' + agg.ARC_BenefitYear__c + '-' + (String.valueOf(agg.ARC_StartDate__c).replace('-', ''));
                    List<ARC_Aggregator__c> aggList = individualAggMap.get(key);
                    if (aggList == null) {
                        aggList = new List<ARC_Aggregator__c>{agg};
                        individualAggMap.put(key, aggList);
                    } else {
                        aggList.add(agg);
                    }
                }
            } else if (agg.RecordTypeId == familyAggRT) {
                key = agg.ARC_Member__c + '-' + agg.ARC_Year__c;
                List<ARC_Aggregator__c> aggList = familyAggMap.get(key);
                if (aggList == null) {
                    aggList = new List<ARC_Aggregator__c>{agg};
                    familyAggMap.put(key, aggList);
                } else {
                    aggList.add(agg);
                }
            }
        }

        List<ARC_ParticipantAggregator__c> partAggregators = [
            SELECT Id, Name, ARC_Aggregator__c, ARC_PolicyParticipant__c, ARC_Policy__c, ARC_Aggregator__r.ARC_Year__c, ARC_Aggregator__r.ARC_CreatedIn__c, ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId,
                ARC_Aggregator__r.ARC_StartDate__c, ARC_Aggregator__r.ARC_BenefitYear__c
            FROM ARC_ParticipantAggregator__c
            WHERE ARC_Policy__c IN: policyIds
        ];
        // Key: policyId-participantAccount-name-year
        Map<String, ARC_ParticipantAggregator__c> existingPartAggMap = new Map<String, ARC_ParticipantAggregator__c>();
        for (ARC_ParticipantAggregator__c partAgg : partAggregators) {
            String key = partAgg.ARC_Policy__c + '-' + partAgg.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId + '-' + partAgg.Name;
            if (partAgg.ARC_Aggregator__r.ARC_Year__c != null) {
                key += '-' + partAgg.ARC_Aggregator__r.ARC_Year__c;
            } else if (partAgg.ARC_Aggregator__r.ARC_BenefitYear__c != null) {
                key += '-' + partAgg.ARC_Aggregator__r.ARC_BenefitYear__c + '-' + (String.valueOf(partAgg.ARC_Aggregator__r.ARC_StartDate__c).replace('-', ''));
            } else {
                key += '-null';
            }
            existingPartAggMap.put(key, partAgg);
        }

        // Map with Participant Aggregator Key (unique), and its Aggregators' Policy to be linked to the corresponding Aggregator
        Map<String, String> partAggKeyToAggPolicyKey = new Map<String, String>();
        Map<String, ARC_ParticipantAggregator__c> partAggToInsert = new Map<String, ARC_ParticipantAggregator__c>();
        Map<String, ARC_Aggregator__c> familyAggToInsert = new Map<String, ARC_Aggregator__c>();
        Map<String, ARC_Aggregator__c> aggToInsert = new Map<String, ARC_Aggregator__c>();

        // Map 'policy-famAccount-year' => previousFamAMCSPolicy
        Map<String, Id> downgradeNewToOldFamAggMap = new Map<String, Id>();
        // Map 'policy-account-name-year' => previousAMCSPolicy
        Map<String, Id> downgradeNewToOldAggMap = new Map<String, Id>();


        // Family AMCS Missing

        for (InsurancePolicy policy : policies) {
            Id familyAccountId = policy.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.vlocity_ins__GroupId__c;
            ARC_ProductAggregators__mdt aggValues = ARC_ProductAggregators__mdt.getInstance(policy.Product.ProductCode);
            for (Schema.SObjectField expectedAggregator : getAggregatorsFields(aggValues)) {
                if (!isFamilyAggregator(expectedAggregator) || aggValues.get(expectedAggregator) == null) continue;
                String aggregatorName = expectedAggregator.getDescribe().getLabel();
                Integer minYear = policy.ARC_EffectiveDate__c.year();
                Integer maxYear = policy.ARC_ExpirationDate__c == null ? Date.Today().year() : policy.ARC_ExpirationDate__c.year();
                if (minYear < 2026) {
                    if (maxYear >= 2026) {
                        minYear = 2026;
                    } else {
                        continue;
                    }
                }
                for (Integer year = minYear; year <= maxYear; year++) {
                    String famAggKey = familyAccountId + '-' + year;
                    Double limitValue = Double.valueOf((Double)aggValues.get(expectedAggregator));
                    if (isSpinnedOffFamily(policy) || isUpgradePolicy(policy)) {
                        ARC_Aggregator__c existingFamilyAMCS = findFamilyAggregator(familyAggMap, policiesMap, year, familyAccountId, policy);
                        if (existingFamilyAMCS != null && existingFamilyAMCS.ARC_CreatedIn__c == policy.Id) continue;
                        missingAggregatorsCounter++;
                        ARC_Aggregator__c familyAMCS = createFamilyAMCS(policy.Id, familyAccountId, year, aggregatorName, limitValue, familyAggRT);
                        familyAggToInsert.put(aggregatorName + '-' + policy.Id + '-' + famAggKey, familyAMCS);
                        if (!familyAggMap.containsKey(famAggKey)) {
                            familyAggMap.put(famAggKey, new List<ARC_Aggregator__c>());
                        }
                        familyAggMap.get(famAggKey).add(familyAMCS);
                    } else if (isDowngradePolicy(policy)) {
                        ARC_Aggregator__c previousFamilyAMCS = findFamilyAggregator(familyAggMap, policiesMap, year, familyAccountId, policy);
                        if (previousFamilyAMCS != null && previousFamilyAMCS.ARC_CreatedIn__c == policy.Id) continue;
                        missingAggregatorsCounter++;
                        ARC_Aggregator__c familyAMCS = createFamilyAMCS(policy.Id, familyAccountId, year, aggregatorName, limitValue, familyAggRT);
                        familyAggToInsert.put(aggregatorName + '-' + policy.Id + '-' + famAggKey, familyAMCS);
                        if (!familyAggMap.containsKey(famAggKey)) {
                            familyAggMap.put(famAggKey, new List<ARC_Aggregator__c>());
                        }
                        familyAggMap.get(famAggKey).add(familyAMCS);
                        if (previousFamilyAMCS != null) {
                            familyAMCS.ARC_CarryOverConsumed__c = 0;
                            if (previousFamilyAMCS.ARC_CarryOverConsumed__c != null) {
                                familyAMCS.ARC_CarryOverConsumed__c += previousFamilyAMCS.ARC_CarryOverConsumed__c;
                            }
                            if (previousFamilyAMCS.ARC_FamilyCurrentValue__c != null) {
                                familyAMCS.ARC_CarryOverConsumed__c += previousFamilyAMCS.ARC_FamilyCurrentValue__c;
                            }
                            familyAMCS.ARC_ConsumedTotal__c = familyAMCS.ARC_CarryOverConsumed__c;
                            if (familyAMCS.ARC_ConsumedTotal__c > limitValue) {
                                familyAMCS.ARC_ConsumedTotal__c = limitValue;
                            }
                            downgradeNewToOldFamAggMap.put(policy.Id + '-' + famAggKey, previousFamilyAMCS.ARC_CreatedIn__c);
                        }
                    } else {
                        ARC_Aggregator__c familyAMCS = findFamilyAggregator(familyAggMap, policiesMap, year, familyAccountId, policy);
                        if (familyAMCS == null) {
                            missingAggregatorsCounter++;
                            familyAMCS = createFamilyAMCS(policy.Id, familyAccountId, year, aggregatorName, limitValue, familyAggRT);
                            familyAggToInsert.put(aggregatorName + '-' + policy.Id + '-' + famAggKey, familyAMCS);
                            if (!familyAggMap.containsKey(famAggKey)) {
                                familyAggMap.put(famAggKey, new List<ARC_Aggregator__c>());
                            }
                            familyAggMap.get(famAggKey).add(familyAMCS);
                        }
                    }
                }
            }
        }


        // Upsertion of Family AMCS

        if (this.shouldCreateMissingAggregators) {
            try {
                aggToBeInsertedCounter += familyAggToInsert.size();
                upsert familyAggToInsert.values();
                aggInsertedCounter += familyAggToInsert.size();
            } catch (Exception e) {
                aggNotInsertedList.addAll(familyAggToInsert.keySet());
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


        // ParticipantAggregators/Aggregators Missing

        for (InsurancePolicy policy : policies) {
            ARC_ProductAggregators__mdt aggValues = ARC_ProductAggregators__mdt.getInstance(policy.Product.ProductCode);
            for (Schema.SObjectField expectedAggregator : getAggregatorsFields(aggValues)) {
                if (!isIndividualAggregator(expectedAggregator) || aggValues.get(expectedAggregator) == null) continue;
                String aggregatorName = expectedAggregator.getDescribe().getLabel();
                for (InsurancePolicyParticipant participant : policy.InsurancePolicyParticipants) {
                    if (participant.PrimaryParticipantContact == null) {
                        continue;
                    } // Skip IPP with missing information (contact, birthdate)
                    Integer maxYearPol = policy.ARC_ExpirationDate__c == null ? Date.Today().year() : policy.ARC_ExpirationDate__c.year();
                    if (maxYearPol < 2026) {
                        continue;
                    }
                    Id accountId = participant.PrimaryParticipantContact.AccountId;
                    Double limitValue = Double.valueOf((Double)aggValues.get(expectedAggregator));
                    String code = getAggregatorCode(expectedAggregator);
                    String type = getAggregatorType(expectedAggregator);
                    if (isMonthly(expectedAggregator)) {
                        String aggKey = accountId + '-' + aggregatorName + '-null';
                        ARC_Aggregator__c agg = findAggregator(individualAggMap, policiesMap, null, aggregatorName, accountId, policy, null, null);
                        if (agg == null) {
                            missingAggregatorsCounter++;
                            String partAggKey = policy.Id + '-' + accountId + '-' + aggregatorName + '-null';
                            agg = createAggregator(policy.Id, accountId, null, aggregatorName, limitValue, individualAggRT, code, type, null, null, null, null);
                            aggToInsert.put(partAggKey, agg);
                            if (!individualAggMap.containsKey(aggKey)) {
                                individualAggMap.put(aggKey, new List<ARC_Aggregator__c>());
                            }
                            individualAggMap.get(aggKey).add(agg);
                        }
                    } else if (isOneTime(expectedAggregator) || isLifeTime(expectedAggregator)) {
                        String partAggKey = policy.Id + '-' + accountId + '-' + aggregatorName + '-null';
                        if (existingPartAggMap.containsKey(partAggKey)) continue;
                        missingParticipantAggregatorsCounter++;
                        policiesWithMissingPartAggSet.add(policy.Id);
                        String aggKey = accountId + '-' + aggregatorName + '-null';
                        ARC_Aggregator__c agg = findAggregator(individualAggMap, policiesMap, null, aggregatorName, accountId, policy, null, null);
                        if (agg == null) {
                            missingAggregatorsCounter++;
                            if (isOneTime(expectedAggregator)) {
                                agg = createAggregator(policy.Id, accountId, null, aggregatorName, limitValue, individualAggRT, code, type, policy.ARC_EffectiveDate__c, null, null, null);
                            } else if (isLifeTime(expectedAggregator)) {
                                agg = createAggregator(policy.Id, accountId, null, aggregatorName, limitValue, individualAggRT, code, type, null, null, null, null);
                            }
                            aggToInsert.put(partAggKey, agg);
                            if (!individualAggMap.containsKey(aggKey)) {
                                individualAggMap.put(aggKey, new List<ARC_Aggregator__c>());
                            }
                            individualAggMap.get(aggKey).add(agg);
                        }
                        ARC_ParticipantAggregator__c partAgg = createParticipantAggregator(policy.Id, participant.Id, aggregatorName);
                        partAggToInsert.put(partAggKey, partAgg);
                        partAggKeyToAggPolicyKey.put(partAggKey, agg.ARC_CreatedIn__c);
                    } else if (isCalendarYear(expectedAggregator)) {
                        Integer minYear = participant.ARC_StartDate__c.year();
                        Integer maxYear = participant.ARC_EndDate__c == null ? Date.Today().year() : participant.ARC_EndDate__c.year();
                        if (minYear < 2026) {
                            if (maxYear >= 2026) {
                                minYear = 2026;
                            } else {
                                continue;
                            }
                        }
                        for (Integer year = minYear; year <= maxYear; year++) {
                            String partAggKey = policy.Id + '-' + accountId + '-' + aggregatorName + '-' + String.valueOf(year);
                            if (existingPartAggMap.containsKey(partAggKey)) continue;
                            missingParticipantAggregatorsCounter++;
                            policiesWithMissingPartAggSet.add(policy.Id);
                            String aggKey = accountId + '-' + aggregatorName + '-' + String.valueOf(year);
                            if ((code == 'AMCS__c' || code == 'TOB__c') && (isUpgradePolicy(policy) || isSpinnedOffFamily(policy) || isLeaveAndComebackMember(accountIdToRelatedPolicies, policy, accountId))) {
                                ARC_Aggregator__c agg = createAggregator(policy.Id, accountId, year, aggregatorName, limitValue, individualAggRT, code, type, null, null, null, null);
                                missingAggregatorsCounter++;
                                aggToInsert.put(partAggKey, agg);
                                if (!individualAggMap.containsKey(aggKey)) {
                                    individualAggMap.put(aggKey, new List<ARC_Aggregator__c>());
                                }
                                individualAggMap.get(aggKey).add(agg);
                                ARC_ParticipantAggregator__c partAgg = createParticipantAggregator(policy.Id, participant.Id, aggregatorName);
                                partAggToInsert.put(partAggKey, partAgg);
                                partAggKeyToAggPolicyKey.put(partAggKey, agg.ARC_CreatedIn__c);
                            } else if (code == 'AMCS__c' && isDowngradePolicy(policy)) {
                                ARC_Aggregator__c prevAgg = findAggregator(individualAggMap, policiesMap, year, aggregatorName, accountId, policy, null, null);
                                ARC_Aggregator__c agg;
                                if (prevAgg != null && prevAgg.ARC_CreatedIn__c == policy.Id) {
                                    agg = prevAgg;
                                } else {
                                    agg = createAggregator(policy.Id, accountId, year, aggregatorName, limitValue, individualAggRT, code, type, null, null, null, null);
                                    missingAggregatorsCounter++;
                                    aggToInsert.put(partAggKey, agg);
                                    if (!individualAggMap.containsKey(aggKey)) {
                                        individualAggMap.put(aggKey, new List<ARC_Aggregator__c>());
                                    }
                                    individualAggMap.get(aggKey).add(agg);
                                }
                                ARC_ParticipantAggregator__c partAgg = createParticipantAggregator(policy.Id, participant.Id, aggregatorName);
                                partAggToInsert.put(partAggKey, partAgg);
                                partAggKeyToAggPolicyKey.put(partAggKey, agg.ARC_CreatedIn__c);
                                if (prevAgg != null && prevAgg.ARC_CreatedIn__c != policy.Id) {
                                    agg.ARC_CarryOverConsumed__c = 0;
                                    if (prevAgg.ARC_CarryOverConsumed__c != null) {
                                        agg.ARC_CarryOverConsumed__c += prevAgg.ARC_CarryOverConsumed__c;
                                    }
                                    if (prevAgg.ARC_CurrentValue__c != null) {
                                        agg.ARC_CarryOverConsumed__c += prevAgg.ARC_CurrentValue__c;
                                    }
                                    agg.ARC_ConsumedTotal__c = agg.ARC_CarryOverConsumed__c;
                                    if (agg.ARC_ConsumedTotal__c > limitValue) {
                                        agg.ARC_ConsumedTotal__c = limitValue;
                                    }
                                    downgradeNewToOldAggMap.put(partAggKey, prevAgg.ARC_CreatedIn__c);
                                }
                            } else {
                                ARC_Aggregator__c agg = findAggregator(individualAggMap, policiesMap, year, aggregatorName, accountId, policy, null, null);
                                if (agg == null) {
                                    missingAggregatorsCounter++;
                                    agg = createAggregator(policy.Id, accountId, year, aggregatorName, limitValue, individualAggRT, code, type, null, null, null, null);
                                    aggToInsert.put(partAggKey, agg);
                                    if (!individualAggMap.containsKey(aggKey)) {
                                        individualAggMap.put(aggKey, new List<ARC_Aggregator__c>());
                                    }
                                    individualAggMap.get(aggKey).add(agg);
                                }
                                ARC_ParticipantAggregator__c partAgg = createParticipantAggregator(policy.Id, participant.Id, aggregatorName);
                                partAggToInsert.put(partAggKey, partAgg);
                                partAggKeyToAggPolicyKey.put(partAggKey, agg.ARC_CreatedIn__c);
                            }
                        }
                    } else if (isEffectiveYear(expectedAggregator)) {
                        List<String> benefitYearList;
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
                                String partAggKey = policy.Id + '-' + accountId + '-' + aggregatorName + '-' + year + '-' + (String.valueOf(startDate).replace('-', ''));
                                if (existingPartAggMap.containsKey(partAggKey)) continue;
                                missingParticipantAggregatorsCounter++;
                                policiesWithMissingPartAggSet.add(policy.Id);
                                String aggKey = accountId + '-' + aggregatorName + '-' + year + '-' + (String.valueOf(startDate).replace('-', ''));
                                ARC_Aggregator__c agg = findAggregator(individualAggMap, policiesMap, null, aggregatorName, accountId, policy, year, startDate);
                                if (agg == null) {
                                    missingAggregatorsCounter++;
                                    limitValue = getBenefitYearLimit(year);
                                    agg = createAggregator(policy.Id, accountId, null, aggregatorName, limitValue, individualAggRT, code, type, null, startDate, endDate, year);
                                    if (!individualAggMap.containsKey(aggKey)) {
                                        individualAggMap.put(aggKey, new List<ARC_Aggregator__c>());
                                    }
                                    individualAggMap.get(aggKey).add(agg);
                                    aggToInsert.put(partAggKey, agg);
                                }
                                ARC_ParticipantAggregator__c partAgg = createParticipantAggregator(policy.Id, participant.Id, aggregatorName);
                                partAggToInsert.put(partAggKey, partAgg);
                                partAggKeyToAggPolicyKey.put(partAggKey, agg.ARC_CreatedIn__c);
                            }
                        }
                    }
                }
            }
        }


        // Links Individual AMCS to Family aggregator

        for (InsurancePolicy policy : policies) {
            ARC_ProductAggregators__mdt aggValues = ARC_ProductAggregators__mdt.getInstance(policy.Product.ProductCode);
            Boolean linkIndividualsToFamily = aggValues.get('FAM_AMCS__c') != null;
            if (linkIndividualsToFamily) {

                Integer minYear = policy.ARC_EffectiveDate__c.year();
                Integer maxYear = policy.ARC_ExpirationDate__c == null ? Date.Today().year() : policy.ARC_ExpirationDate__c.year();
                Id familyAccountId = policy.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.vlocity_ins__GroupId__c;
                
                if (minYear < 2026) {
                    if (maxYear >= 2026) {
                        minYear = 2026;
                    } else {
                        continue;
                    }
                }
                for (Integer year = minYear; year <= maxYear; year++) {
                    ARC_Aggregator__c famAgg = findFamilyAggregator(familyAggMap, policiesMap, year, familyAccountId, policy);
                    
                    for (InsurancePolicyParticipant participant : policy.InsurancePolicyParticipants) {
                        String IPPAccount = participant.PrimaryParticipantContact.AccountId;
                        if (IPPAccount == null) continue;
                        String indAggKey = IPPAccount + '-Individual AMCS-' + String.valueOf(year);
                        List<ARC_Aggregator__c> indAMCSList = individualAggMap.get(indAggKey);
                        if (indAMCSList == null) continue;
                        ARC_Aggregator__c indAMCS;
                        for (ARC_Aggregator__c agg : indAMCSList) {
                            if (agg.ARC_CreatedIn__c == policy.Id) {
                                indAMCS = agg;
                                break;
                            }
                        }
                        if (indAMCS == null) continue;
                        if (indAMCS.ARC_FamilyAggregator__c == null) {
                            indAMCS.ARC_FamilyAggregator__c = famAgg.Id;
                        }
                    }
                }
            }         
        }
        
        
        // Upserts Individual Aggregators
        
        if (this.shouldCreateMissingAggregators) {
            try {
                aggToBeInsertedCounter += aggToInsert.size();
                upsert aggToInsert.values();
                aggInsertedCounter += aggToInsert.size();
            } catch (Exception e) {
                aggNotInsertedList.addAll(aggToInsert.keySet());
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{
                    'ignacio.ferreiro@arcsona.com',
                    'agustin.garay@arcsona.com'
                }); 
                mail.setSubject('Apex Exception Occurred');
                String body;
                body += 'Exception: ' + e.getMessage() + '\nStack Trace:\n' + e.getStackTraceString() + '\n\n';
                body +=  String.join(policiesWithMissingPartAggSet, '\n');
                mail.setPlainTextBody(body);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
            }
        }


        // Relate AMCS Downgrades

        List<ARC_Aggregator__c> downgradeAMCSToLink = new List<ARC_Aggregator__c>();
        for (String newFamilyKey : downgradeNewToOldFamAggMap.keySet()) {
            Id oldFamPolicy = downgradeNewToOldFamAggMap.get(newFamilyKey);
            List<String> splitKey = newFamilyKey.split('-');
            Id newFamPolicy = splitKey[0];
            splitKey.remove(0);
            String aggKey = String.join(splitKey, '-');

            ARC_Aggregator__c oldFamilyAMCS;
            ARC_Aggregator__c newFamilyAMCS;
            List<ARC_Aggregator__c> famAggList = familyAggMap.get(aggKey);
            for (ARC_Aggregator__c famAgg : famAggList) {
                if (famAgg.ARC_CreatedIn__c == oldFamPolicy) {
                    oldFamilyAMCS = famAgg;
                }
                if (famAgg.ARC_CreatedIn__c == newFamPolicy) {
                    newFamilyAMCS = famAgg;
                }
            }
            newFamilyAMCS.ARC_FromCarryOver__c = oldFamilyAMCS.Id;
            downgradeAMCSToLink.add(newFamilyAMCS);
        }
        for (String newAggKey : downgradeNewToOldAggMap.keySet()) {
            Id oldAggPolicy = downgradeNewToOldAggMap.get(newAggKey);
            List<String> splitKey = newAggKey.split('-');
            Id newAggPolicy = splitKey[0];
            splitKey.remove(0);
            String aggKey = String.join(splitKey, '-');

            ARC_Aggregator__c oldAMCS;
            ARC_Aggregator__c newAMCS;
            List<ARC_Aggregator__c> aggList = individualAggMap.get(aggKey);
            for (ARC_Aggregator__c agg : aggList) {
                if (agg.ARC_CreatedIn__c == oldAggPolicy) {
                    oldAMCS = agg;
                }
                if (agg.ARC_CreatedIn__c == newAggPolicy) {
                    newAMCS = agg;
                }
            }
            newAMCS.ARC_FromCarryOver__c = oldAMCS.Id;
            downgradeAMCSToLink.add(newAMCS);
        }

        // Update Downgrade Aggregators

        if (this.shouldCreateMissingAggregators) {
            try {
                upsert downgradeAMCSToLink;
            } catch (Exception e) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{
                    'ignacio.ferreiro@arcsona.com',
                    'agustin.garay@arcsona.com'
                }); 
                mail.setSubject('Apex Exception Occurred');
                String body;
                body += 'Exception: ' + e.getMessage() + '\nStack Trace:\n' + e.getStackTraceString() + '\n\n';
                body +=  String.join(policiesWithMissingPartAggSet, '\n');
                mail.setPlainTextBody(body);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
            }
        }
        

        // Relate Participant Aggregators to Aggregators

        for (String partAggKey : partAggToInsert.keySet()) {
            String aggPolicy = partAggKeyToAggPolicyKey.get(partAggKey);
            List<String> splitKey = partAggKey.split('-');
            splitKey.remove(0);
            String aggKey = String.join(splitKey, '-');
            List<ARC_Aggregator__c> aggregatorList = individualAggMap.get(aggKey);
            ARC_Aggregator__c aggregator;
            for (ARC_Aggregator__c agg : aggregatorList) {
                if (agg.ARC_CreatedIn__c == aggPolicy) {
                    aggregator = agg;
                    break;
                }
            }
            ARC_ParticipantAggregator__c partAgg = partAggToInsert.get(partAggKey);
            partAgg.ARC_Aggregator__c = aggregator.Id;
        }
        

        // Insert Participant Aggregators

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
                String body;
                body += 'Exception: ' + e.getMessage() + '\nStack Trace:\n' + e.getStackTraceString() + '\n\n';
                body +=  String.join(policiesWithMissingPartAggSet, '\n');
                mail.setPlainTextBody(body);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
            }
        }
    }


    // UTILITY METHODS //

    public List<Schema.SObjectField> getAggregatorsFields(ARC_ProductAggregators__mdt aggregatorValues) {
        return aggregatorValues.getSObjectType().getDescribe().fields.getMap().values();
    }

    public Boolean isUpgradePolicy(InsurancePolicy policy) {
        String policyReasons = policy.ARC_PolicyReason__c;
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

    public Boolean isDowngradePolicy(InsurancePolicy policy) {
        String policyReasons = policy.ARC_PolicyReason__c;
        List<String> polReasons = policyReasons.split('<br>');
        Boolean isDowngrade = false;
        Boolean isSpinOff = false;
        for (String reason : polReasons) {
            if (reason == 'Program Downgrade') {
                isDowngrade = true;
            } else if (reason == 'Spin Off') {
                isSpinOff = true;
            }
        }
        return isDowngrade && !isSpinOff;
    }

    public Boolean isSpinnedOffFamily(InsurancePolicy policy) {
        Id familyAccountId = policy.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.vlocity_ins__GroupId__c;
        Id renewedFamilyAccountId = policy.ARC_SpinnedFromPolicy__c != null ? policy.ARC_SpinnedFromPolicy__r.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.vlocity_ins__GroupId__c : null;
        String policyReasons = policy.ARC_PolicyReason__c;
        List<String> polReasons = policyReasons.split('<br>');
        Boolean isSpinOff = false;
        for (String reason : polReasons) {
            if (reason == 'Spin Off') {
                isSpinOff = true;
                break;
            }
        }
        return (familyAccountId != renewedFamilyAccountId) && isSpinOff;
    }

    public Boolean isLeaveAndComebackMember(Map<Id, List<InsurancePolicy>> accountIdToRelatedPolicies, InsurancePolicy policy, Id accountId) {
        Boolean leaveAndComeback = false;
        String policyReasons = policy.ARC_PolicyReason__c;
        List<String> polReasons = policyReasons.split('<br>');
        Boolean isAddExistingMember = false;
        for (String reason : polReasons) {
            if (reason == 'Add Existing Member') {
                isAddExistingMember = true;
                break;
            }
        }
        if (isAddExistingMember) {
            List<InsurancePolicy> relatedPolicies = accountIdToRelatedPolicies.get(accountId);
            leaveAndComeback = true;
            if (relatedPolicies != null) {
                for (InsurancePolicy relatedPolicy : relatedPolicies) {
                    if ((relatedPolicy.Id == policy.Id) || (relatedPolicy.ARC_ExpirationDate__c == null)) continue;
                    if ((relatedPolicy.ARC_ExpirationDate__c == policy.ARC_EffectiveDate__c) || ((relatedPolicy.ARC_ExpirationDate__c).addDays(1) == policy.ARC_EffectiveDate__c)) {
                        leaveAndComeback = false;
                        break;
                    }
                }
            }
        }
        return leaveAndComeback;
    }

    public ARC_Aggregator__c findFamilyAggregator(Map<String, List<ARC_Aggregator__c>> familyAggMap, Map<Id, InsurancePolicy> policiesMap, Integer year, Id familyAccountId, InsurancePolicy policy) {
        String yearKey = year != null ? String.valueOf(year) : 'null';
        String key = familyAccountId + '-' + yearKey;
        List<ARC_Aggregator__c> aggregatorsList = familyAggMap.get(key);
        if (aggregatorsList == null || aggregatorsList.isEmpty()) {
            return null;
        }
        ARC_Aggregator__c foundAgg;
        for (ARC_Aggregator__c agg : aggregatorsList) {
            if (foundAgg == null) {
                foundAgg = aggregatorsList[0];
            } else if (isPolicyAfter(policy, policiesMap.get(agg.ARC_CreatedIn__c)) && isPolicyAfter(policiesMap.get(agg.ARC_CreatedIn__c), policiesMap.get(foundAgg.ARC_CreatedIn__c))) {
                foundAgg = agg;
            }
        }
        return foundAgg;
    }

    public ARC_Aggregator__c findAggregator(Map<String, List<ARC_Aggregator__c>> individualAggMap, Map<Id, InsurancePolicy> policiesMap, Integer year, String name, Id accountId, InsurancePolicy policy, String benefitYear, Date startDate) {
        String yearKey = 'null';
        if (year != null) {
            yearKey = String.valueOf(year);
        } else if (benefitYear != null && startDate != null) {
            yearKey = benefitYear + '-' + (String.valueOf(startDate).replace('-', ''));
        }
        String key = accountId + '-' + name + '-' + yearKey;

        List<ARC_Aggregator__c> aggregatorsList = individualAggMap.get(key);
        if (aggregatorsList == null || aggregatorsList.isEmpty()) {
            return null;
        }
        ARC_Aggregator__c foundAgg;
        for (ARC_Aggregator__c agg : aggregatorsList) {
            if (foundAgg == null) {
                foundAgg = aggregatorsList[0];
            } else if (isPolicyAfter(policy, policiesMap.get(agg.ARC_CreatedIn__c)) && isPolicyAfter(policiesMap.get(agg.ARC_CreatedIn__c), policiesMap.get(foundAgg.ARC_CreatedIn__c))) {
                foundAgg = agg;
            }
        }
        return foundAgg;
    }

    public Boolean isPolicyAfter(InsurancePolicy policy1, InsurancePolicy policy2) {
        Boolean effectiveDateComp = policy1.ARC_EffectiveDate__c > policy2.ARC_EffectiveDate__c;
        Boolean createdDateComp = (policy1.ARC_EffectiveDate__c == policy2.ARC_EffectiveDate__c) && (policy1.ARC_Contract__r.CreatedDate >= policy2.ARC_Contract__r.CreatedDate);
        return (effectiveDateComp || createdDateComp);
    }

    public ARC_ParticipantAggregator__c createParticipantAggregator(Id policyId, Id participant, String name) {
        ARC_ParticipantAggregator__c newPartAgg = new ARC_ParticipantAggregator__c();
        newPartAgg.ARC_Policy__c = policyId;
        newPartAgg.Name = name;
        newPartAgg.ARC_PolicyParticipant__c = participant;
        newPartAgg.ARC_ConsumedValue__c = 0;
        return newPartAgg;
    }

    public ARC_Aggregator__c createAggregator(Id policyId, Id accountId, Integer year, String aggregatorName, Double limitValue, Id individualAggRT, String code, String type, Date nextAvailabilityDate, Date startDate, Date endDate, String benefitYear) {
        ARC_Aggregator__c newAgg = new ARC_Aggregator__c();
        newAgg.RecordTypeId = individualAggRT;
        newAgg.Name = aggregatorName;
        newAgg.ARC_Year__c = year != null ? String.valueOf(year) : null;
        newAgg.ARC_CreatedIn__c = policyId;
        newAgg.ARC_LimitValue__c = limitValue;
        newAgg.ARC_Member__c = accountId;
        newAgg.ARC_Code__c = code;
        newAgg.ARC_Type__c = type;
        newAgg.ARC_NextAvailabilityDate__c = nextAvailabilityDate;
        if (startDate != null) {
            newAgg.ARC_StartDate__c = startDate;
        }
        if (endDate != null) {
            newAgg.ARC_EndDate__c = endDate;
        }
        newAgg.ARC_BenefitYear__c = benefitYear;
        return newAgg;
    }

    public ARC_Aggregator__c createFamilyAMCS(Id policyId, Id familyAccountId, Integer year, String aggregatorName, Double limitValue, Id familyAggRT) {
        ARC_Aggregator__c newFamilyAgg = new ARC_Aggregator__c();
        newFamilyAgg.RecordTypeId = familyAggRT;
        newFamilyAgg.Name = aggregatorName;
        newFamilyAgg.ARC_Year__c = String.valueOf(year);
        newFamilyAgg.ARC_CreatedIn__c = policyId;
        newFamilyAgg.ARC_FamilyCurrentValue__c = 0;
        newFamilyAgg.ARC_LimitValue__c = limitValue;
        newFamilyAgg.ARC_Member__c = familyAccountId;
        return newFamilyAgg;
    }

    public Boolean isOneTime(Schema.SObjectField aggregatorField) {
        String aggregatorCode = getAggregatorCode(aggregatorField);
        return ONE_TIME.contains(aggregatorCode);
    }

    public Boolean isLifeTime(Schema.SObjectField aggregatorField) {
        String aggregatorCode = getAggregatorCode(aggregatorField);
        return LIFETIME.contains(aggregatorCode);
    }

    public Boolean isMonthly(Schema.SObjectField aggregatorField) {
        String aggregatorCode = getAggregatorCode(aggregatorField);
        return MONTHLY.contains(aggregatorCode);
    }

    public Boolean isEffectiveYear(Schema.SObjectField aggregatorField) {
        String aggregatorCode = getAggregatorCode(aggregatorField);
        return EFFECTIVE_YEAR.contains(aggregatorCode);
    }

    public Boolean isCalendarYear(Schema.SObjectField aggregatorField) {
        String aggregatorCode = getAggregatorCode(aggregatorField);
        return CALENDAR_YEAR.contains(aggregatorCode);
    }

    public Boolean isOneTime(String aggregatorCode) {
        return ONE_TIME.contains(aggregatorCode);
    }

    public Boolean isLifeTime(String aggregatorCode) {
        return LIFETIME.contains(aggregatorCode);
    }

    public Boolean isMonthly(String aggregatorCode) {
        return MONTHLY.contains(aggregatorCode);
    }

    public Boolean isEffectiveYear(String aggregatorCode) {
        return EFFECTIVE_YEAR.contains(aggregatorCode);
    }

    public Boolean isCalendarYear(String aggregatorCode) {
        return CALENDAR_YEAR.contains(aggregatorCode);
    }

    public Boolean isIndividualAggregator(Schema.SObjectField aggregatorField) {
        return String.valueOf(aggregatorField).startsWith('IND_');
    }

    public Boolean isFamilyAggregator(Schema.SObjectField aggregatorField) {
        return String.valueOf(aggregatorField).startsWith('FAM_');
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
        if (NUMBER_TYPE.contains(aggregatorCode)) {
            aggregatorType = 'Number';
        } else if (CURRENCY_TYPE.contains(aggregatorCode)) {
            aggregatorType = 'Currency';
        }
        return aggregatorType;
    }

    public Double getBenefitYearLimit(String benefitYear) {
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

    public Map<Id, List<String>> createBenefitYearMap(Set<Id> personAccounts, String code) {
        Map<Id, List<String>> benefitYearMap = new Map<Id, List<String>>();
        Map<Id, List<Map<String, Object>>> coveragePeriodsMap = ARC_SMBUtility.mapCoveragePeriods(new List<Id>(personAccounts), code);
        for (Id accountId : coveragePeriodsMap.keySet()) {
            List<String> aggregatorsPerPeriod = ARC_SMBUtility.calculateAggregators(coveragePeriodsMap.get(accountId), code);
            benefitYearMap.put(accountId, aggregatorsPerPeriod);
        }
        return benefitYearMap;
    }

    global void finish(Database.BatchableContext BC) {

        if (this.sendEmail) {
            String emailAddress = UserInfo.getUserEmail();

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<OrgWideEmailAddress> oMailNoReplay = [
                SELECT Id, Address, DisplayName
                FROM OrgWideEmailAddress
                WHERE Displayname = 'No Reply'
            ];
            mail.setToAddresses(new List<String>{emailAddress});
            mail.setSubject('Create Missing Aggregators Batch Completed');
            String body;
            body = 'Batch Completed  -  Create Aggregators: ' + this.shouldCreateMissingAggregators + '\n\n\n';
            body += 'Number of missing Participant Aggregators: ' + missingParticipantAggregatorsCounter + '\n\n';
            body += 'Number of missing Aggregators: ' + missingAggregatorsCounter + '\n\n';
            body += 'Number of Participant Aggregators to be inserted: ' + partAggToBeInsertedCounter + '\n\n';
            body += 'Number of Participant Aggregators inserted: ' + partAggInsertedCounter + '\n\n';
            body += 'Number of Participant Aggregators processed with errors: ' + partAggNotInsertedList.size();
            body += '\n\n\n' + 'Participant Aggregators processed with errors: ' + '\n' + '(Policy - Aggregator - Year - Participant)' + '\n' + String.join(partAggNotInsertedList, '\n');

            body += 'Number of Aggregators to be inserted: ' + aggToBeInsertedCounter + '\n\n';
            body += 'Number of Aggregators inserted: ' + aggInsertedCounter + '\n\n';
            body += 'Number of Aggregators processed with errors: ' + aggNotInsertedList.size();
            body += '\n\n\n' + 'Aggregators processed with errors: ' + '\n' + '(Policy - Aggregator - Year - Participant)' + '\n' + String.join(aggNotInsertedList, '\n');
            body += '\n\n' + 'Policies with missing Participant Aggregators ('+ policiesWithMissingPartAggSet.size()+'): \n'; 
            body +=  String.join(policiesWithMissingPartAggSet, '\n');

            if (hadPrev2026Policy) {
                body += '\n\n\n\n';
                body += '---------- Report for years previous 2026 ----------';
                body += '\n\n';
                body += 'Number of missing Participant Aggregators: ' + missingParticipantAggregatorsCounter2025 + '\n\n';
                body += 'Number of missing Aggregators: ' + missingAggregatorsCounter2025 + '\n\n';
                body += 'Number of Participant Aggregators to be inserted: ' + partAggToBeInsertedCounter2025 + '\n\n';
                body += 'Number of Participant Aggregators inserted: ' + partAggInsertedCounter2025 + '\n\n';
                body += 'Number of Participant Aggregators processed with errors: ' + partAggNotInsertedList2025.size();
                body += '\n\n\n' + 'Participant Aggregators processed with errors: ' + '\n' + '(Policy - Aggregator - Year - Participant)' + '\n' + String.join(partAggNotInsertedList2025, '\n');
                body += '\n\n' + 'Aggregators exceeding limits: ' + '\n' + String.join(aggregatorsExceedingLimit2025, '\n');
                body += '\n\n' + 'Voided Policies: ' + '\n' + String.join(policiesVoidedExceptions2025, '\n');
                body += '\n\n' + 'Misplaced aggregators policies (' + aggregatorsWrongPolicy2025.size() + '): ' + '\n' + String.join(aggregatorsWrongPolicy2025, '\n');
                body += '\n\n' + 'Family aggregators missing Individual AMCS: ' + '\n' + String.join(familyAggregatorsMissingIndividual2025, '\n');
                body += '\n\n' + 'Misslabeled aggregator / part-aggregator: ' + '\n' + String.join(aggregatorsMisslabeled2025, '\n');
                body += '\n\n' + 'Cound not generate related policies list: ' + '\n' + String.join(noRelatedPoliciesFound2025, '\n');
                body += '\n\n' + 'Policies with missing Participant Aggregators ('+ policiesWithMissingPartAggSet2025.size()+'): \n' + String.join(policiesWithMissingPartAggSet2025, '\n'); 
            }
            mail.setPlainTextBody(body);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        }


        System.debug('--- Number of Policies: ' + policiesWithMissingPartAggSet.size());
        System.debug('--- Where clause: ' + this.whereClause);
        System.debug('Number of missing Particpant Aggregators: ' + missingParticipantAggregatorsCounter);
        System.debug('Number of missing Aggregators: ' + missingAggregatorsCounter);
        System.debug('Number of Participant Aggregators to be inserted: ' + partAggToBeInsertedCounter);
        System.debug('Number of Participant Aggregators inserted: ' + partAggInsertedCounter);
        System.debug('Number of Participant Aggregators processed with errors: ' + partAggNotInsertedList.size());
        System.debug('Policies with missing Participant Aggregators: ' + policiesWithMissingPartAggSet.size());
    }

    public class CreateMissingAggregatosException extends Exception {}
}