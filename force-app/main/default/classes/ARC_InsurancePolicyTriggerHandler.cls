public without sharing class ARC_InsurancePolicyTriggerHandler {


    /*******************************************************************
    * @MethodName         :   updateActivatedDate
    * @Description        :   Updates the Activated Date of the Policies to set Today's date.
    * @Developer          :   Gabriel Martinez
    ********************************************************************/
    public static void updateActivatedDate(Map<Id, InsurancePolicy> policiesToUpdateMap) {
        Date todayDate = Date.today();
        for (Id policyId : policiesToUpdateMap.keySet()) {
            policiesToUpdateMap.get(policyId).ARC_ActivatedDate__c = todayDate;
        }
    }

    /*******************************************************************
    * @MethodName         :   updateReactivatedDate
    * @Description        :   Updates the Reactivated Date of the Policies to set Today's date.
    * @Developer          :   Gabriel Martinez
    ********************************************************************/
    public static void updateReactivatedDate(Map<Id, InsurancePolicy> policiesToUpdateMap) {
        Date todayDate = Date.today();
        for (Id policyId : policiesToUpdateMap.keySet()) {
            policiesToUpdateMap.get(policyId).ARC_ReactivatedDate__c = todayDate;
        }
    }

    /*********************************************************************************************************
     * @name            updateAggregators
     * @description     When a Contract gets voided, this method verifies if the Participant Aggregators are pointing to a Terminated/Activated policy
     *                  and if they do, relocates the Aggregators to the closest future Terminated/Activated Policy from its Participant Aggregators,
     *                  otherwise, the ARC_IsInactive__c field is checked.
     * @param           voidedPoliciesMap
    ********************************************************************/
    public static void updateAggregators(Map<Id, InsurancePolicy> voidedPoliciesMap) {
        // VARIABLES
        List<ARC_Aggregator__c> aggregatorsList = new List<ARC_Aggregator__c>();
        List<ARC_Aggregator__c> aggregatorsToUpdate = new List<ARC_Aggregator__c>();
        Set<Id> familyAggregatorIds = new Set<Id>();
        String closestPolicyId = '';
        Date closestEffectiveDate = Date.today();
        Datetime closestCreatedDate = Date.today();
        Map<Id, List<Map<String, String>>> mapFamilyAggregators = new Map<Id, List<Map<String, String>>>();

        aggregatorsList = [SELECT Id,
                                  Name,
                                  RecordType.Name,
                                  ARC_FamilyAggregator__c,
                                  ARC_FamilyAggregator__r.ARC_CreatedIn__c,
                                  ARC_FamilyAggregator__r.ARC_CreatedIn__r.ARC_PolicyEffectiveDate__c,
                                  (SELECT Id,
                                          Name,
                                          ARC_PolicyParticipant__r.InsurancePolicyId,
                                          ARC_PolicyParticipant__r.InsurancePolicy.Status,
                                          ARC_PolicyParticipant__r.InsurancePolicy.ARC_PolicyEffectiveDate__c,
                                          ARC_PolicyParticipant__r.InsurancePolicy.CreatedDate
                                   FROM Participant_Aggregators__r
                                   WHERE ARC_PolicyParticipant__r.InsurancePolicy.Status = 'Activated'
                                   OR ARC_PolicyParticipant__r.InsurancePolicy.Status = 'Terminated'
                                   ORDER BY ARC_PolicyParticipant__r.InsurancePolicy.ARC_PolicyEffectiveDate__c)
                           FROM ARC_Aggregator__c
                           WHERE ARC_CreatedIn__c IN :voidedPoliciesMap.keySet()];

        for (ARC_Aggregator__c aggregatorTemp : aggregatorsList) {
            if (aggregatorTemp.RecordType.Name == 'Family') {
                familyAggregatorIds.add(aggregatorTemp.Id);
            } else if (aggregatorTemp.Participant_Aggregators__r.isEmpty()) {
                aggregatorTemp.ARC_IsInactive__c = true;
                aggregatorsToUpdate.add(aggregatorTemp);
            } else {
                closestPolicyId = '';
                closestEffectiveDate = Date.today();
                closestCreatedDate = Date.today();

                for (ARC_ParticipantAggregator__c participantAggregatorTmp : aggregatorTemp.Participant_Aggregators__r) {
                    if (closestPolicyId == '') {
                        closestPolicyId = participantAggregatorTmp.ARC_PolicyParticipant__r.InsurancePolicyId;
                        closestEffectiveDate = participantAggregatorTmp.ARC_PolicyParticipant__r.InsurancePolicy.ARC_PolicyEffectiveDate__c;
                        closestCreatedDate = participantAggregatorTmp.ARC_PolicyParticipant__r.InsurancePolicy.CreatedDate;
                    } else if (participantAggregatorTmp.ARC_PolicyParticipant__r.InsurancePolicy.ARC_PolicyEffectiveDate__c <= closestEffectiveDate) {
                        if (participantAggregatorTmp.ARC_PolicyParticipant__r.InsurancePolicy.ARC_PolicyEffectiveDate__c == closestEffectiveDate) {
                            if (participantAggregatorTmp.ARC_PolicyParticipant__r.InsurancePolicy.CreatedDate < closestCreatedDate) {
                                closestPolicyId = participantAggregatorTmp.ARC_PolicyParticipant__r.InsurancePolicyId;
                                closestEffectiveDate = participantAggregatorTmp.ARC_PolicyParticipant__r.InsurancePolicy.ARC_PolicyEffectiveDate__c;
                                closestCreatedDate = participantAggregatorTmp.ARC_PolicyParticipant__r.InsurancePolicy.CreatedDate;
                            }
                        } else {
                            closestPolicyId = participantAggregatorTmp.ARC_PolicyParticipant__r.InsurancePolicyId;
                            closestEffectiveDate = participantAggregatorTmp.ARC_PolicyParticipant__r.InsurancePolicy.ARC_PolicyEffectiveDate__c;
                            closestCreatedDate = participantAggregatorTmp.ARC_PolicyParticipant__r.InsurancePolicy.CreatedDate;
                        }
                    }
                }

                if (aggregatorTemp.ARC_FamilyAggregator__c != null) {
                    if (mapFamilyAggregators.containsKey(aggregatorTemp.ARC_FamilyAggregator__c)) {
                        List<Map<String, String>> childAggregators = mapFamilyAggregators.get(aggregatorTemp.ARC_FamilyAggregator__c);
                        childAggregators.add(new Map<String, String> {
                            'ARC_EffectiveDate__c' => String.valueOf(closestEffectiveDate),
                            'CreatedDate' => String.valueOf(closestCreatedDate),
                            'InsurancePolicyId' => String.valueOf(closestPolicyId)
                        });
                        mapFamilyAggregators.put(aggregatorTemp.ARC_FamilyAggregator__c, childAggregators);
                    } else {
                        mapFamilyAggregators.put(aggregatorTemp.ARC_FamilyAggregator__c, new List<Map<String, String>> {
                            new Map<String, String> {
                                'ARC_EffectiveDate__c' => String.valueOf(closestEffectiveDate),
                                'CreatedDate' => String.valueOf(closestCreatedDate),
                                'InsurancePolicyId' => String.valueOf(closestPolicyId)
                            }
                        });
                    }
                }

                aggregatorTemp.ARC_CreatedIn__c = closestPolicyId;
                aggregatorsToUpdate.add(aggregatorTemp);
            }
        }

        for (Id aggregatorIdTemp : familyAggregatorIds) {
            closestPolicyId = '';
            closestEffectiveDate = Date.today();
            closestCreatedDate = Date.today();
            ARC_Aggregator__c familyAggregator = new ARC_Aggregator__c(Id = aggregatorIdTemp);

            if (!mapFamilyAggregators.containsKey(aggregatorIdTemp)) {
                familyAggregator.ARC_IsInactive__c = true;
            } else {
                for (Map<String, String> mapFamilyAggregatorTemp : mapFamilyAggregators.get(aggregatorIdTemp)) {
                    if (closestPolicyId == '') {
                        closestPolicyId = mapFamilyAggregatorTemp.get('InsurancePolicyId');
                        closestEffectiveDate = Date.valueOf(mapFamilyAggregatorTemp.get('ARC_EffectiveDate__c'));
                        closestCreatedDate = Datetime.valueOf(mapFamilyAggregatorTemp.get('CreatedDate'));
                    } else {
                        Date currentEffectiveDate = Date.valueOf(mapFamilyAggregatorTemp.get('ARC_EffectiveDate__c'));
                        if (currentEffectiveDate <= closestEffectiveDate) {
                            if (currentEffectiveDate == closestEffectiveDate) {
                                if (Datetime.valueOf(mapFamilyAggregatorTemp.get('CreatedDate')) < closestCreatedDate) {
                                    closestPolicyId = mapFamilyAggregatorTemp.get('InsurancePolicyId');
                                    closestEffectiveDate = Date.valueOf(mapFamilyAggregatorTemp.get('ARC_EffectiveDate__c'));
                                    closestCreatedDate = Datetime.valueOf(mapFamilyAggregatorTemp.get('CreatedDate'));
                                }
                            } else {
                                closestPolicyId = mapFamilyAggregatorTemp.get('InsurancePolicyId');
                                closestEffectiveDate = Date.valueOf(mapFamilyAggregatorTemp.get('ARC_EffectiveDate__c'));
                                closestCreatedDate = Datetime.valueOf(mapFamilyAggregatorTemp.get('CreatedDate'));
                            }
                        }
                    }
                }
                familyAggregator.ARC_CreatedIn__c = closestPolicyId;
            }
            aggregatorsToUpdate.add(familyAggregator);
        }

        if (!aggregatorsToUpdate.isEmpty()) update aggregatorsToUpdate;
    }

    /************************************************************************************************************
     * @name            reactivateAggregators
     * @description     When a Voided Contract gets Terminated or Activated, this method unchecks the ARC_IsInactive__c fields
     *                  of the Aggregators its Participant Aggregators point to.
     * @param           reactivatedVoidedPolicyMap
     *********************************************************************************************************/
    public static void reactivateAggregators(Map<Id, InsurancePolicy> reactivatedVoidedPolicyMap) {
        Map<Id, ARC_Aggregator__c> aggregatorsToUpdate = new Map<Id, ARC_Aggregator__c>();

        List<ARC_ParticipantAggregator__c> participantAggregatorsList = [
            SELECT Id,
                   Name,
                   ARC_Aggregator__c,
                   ARC_Aggregator__r.ARC_FamilyAggregator__c,
                   ARC_Aggregator__r.ARC_FamilyAggregator__r.ARC_IsInactive__c
            FROM ARC_ParticipantAggregator__c
            WHERE ARC_Policy__c IN :reactivatedVoidedPolicyMap.keySet()
              AND ARC_Aggregator__r.ARC_IsInactive__c = true
        ];

        for (ARC_ParticipantAggregator__c partAgg : participantAggregatorsList) {
            if (!aggregatorsToUpdate.containsKey(partAgg.ARC_Aggregator__c)) {
                aggregatorsToUpdate.put(partAgg.ARC_Aggregator__c, new ARC_Aggregator__c(Id = partAgg.ARC_Aggregator__c, ARC_IsInactive__c = false));
            }
            if (
                partAgg.ARC_Aggregator__r.ARC_FamilyAggregator__c != null
                && partAgg.ARC_Aggregator__r.ARC_FamilyAggregator__r.ARC_IsInactive__c
                && !aggregatorsToUpdate.containsKey(partAgg.ARC_Aggregator__r.ARC_FamilyAggregator__c)
            ) {
                aggregatorsToUpdate.put(partAgg.ARC_Aggregator__r.ARC_FamilyAggregator__c, new ARC_Aggregator__c(Id = partAgg.ARC_Aggregator__r.ARC_FamilyAggregator__c, ARC_IsInactive__c = false));
            }
        }

        if (!aggregatorsToUpdate.isEmpty()) update aggregatorsToUpdate.values();
    }

    /************************************************************************************************************
     * @name            updatePolicyName
     * @description     Inserted policies with Name = 'ShopAndEnroll Policy' have their Name updated.
     * @param           policies
     *********************************************************************************************************/
    public static void updatePolicyName(List<InsurancePolicy> policies) {
        String currentDay = String.valueOf(System.today().day());
        String dayStr = currentDay.length() == 1 ? '0' + currentDay : currentDay;
        String currentMonth = String.valueOf(System.today().month());
        String monthStr = currentMonth.length() == 1 ? '0' + currentMonth : currentMonth;
        String currentYear = String.valueOf(System.today().year());

        Integer count = 0;

        try {
            InsurancePolicy newestPolicy = [SELECT CreatedDate, Name FROM InsurancePolicy ORDER BY CreatedDate DESC LIMIT 1];
            if (newestPolicy != null) {
                String policyDay = String.valueOf(newestPolicy.CreatedDate.day());
                String policyMonth = String.valueOf(newestPolicy.CreatedDate.month());
                String policyYear = String.valueOf(newestPolicy.CreatedDate.year());

                if (currentDay.equals(policyDay) && currentMonth.equals(policyMonth) && currentYear.equals(policyYear)) {
                    count = Integer.valueOf(newestPolicy.Name.substring(8));
                }
            }
        } catch (Exception error) {
            System.debug('Invalid Previous Policy');
        }

        for (InsurancePolicy policy : policies) {
            if (policy.Name == 'ShopAndEnroll Policy') {
                String stringId = String.valueOf(count + 1);
                String ceros = '00000000'.substring(stringId.length());
                policy.Name = currentYear + monthStr + dayStr + ceros + stringId;
                count = count + 1;
            }
        }
    }

    /************************************************************************************************************
     * @name            processBillingAutomation
     * @description     Evaluates policy changes and invokes billing service for qualified policies.
     *                  Uses bulk methods to avoid hitting SOQL governor limits when multiple policies
     *                  are updated in the same transaction.
     * @param           newPolicies  - List of new/updated policies
     * @param           oldPolicyMap - Map of old policy versions (null for insert)
     * @developer       lucas.benero@arcsona.com
     * @date            2026-01-22
     *********************************************************************************************************/
    public static void processBillingAutomation(List<InsurancePolicy> newPolicies, Map<Id, InsurancePolicy> oldPolicyMap) {
        Set<String> ELIGIBLE_STATUSES = new Set<String>{
            'Awaiting Activation', 'Activated', 'Terminated', 'Voided'
        };

        if (newPolicies == null || newPolicies.isEmpty()) return;

        Id smallGroupRTId = Schema.SObjectType.InsurancePolicy
            .getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();

        Boolean isInsert = (oldPolicyMap == null);

        // Collect qualified policies
        List<InsurancePolicy> qualifiedPolicies = new List<InsurancePolicy>();
        for (InsurancePolicy newPolicy : newPolicies) {
            if (newPolicy.RecordTypeId != smallGroupRTId) continue;

            Boolean isQualified = false;

            if (isInsert) {
                isQualified = ELIGIBLE_STATUSES.contains(newPolicy.Status);
            } else {
                InsurancePolicy oldPolicy = oldPolicyMap.get(newPolicy.Id);
                if (newPolicy.Status != oldPolicy.Status && ELIGIBLE_STATUSES.contains(newPolicy.Status)) {
                    isQualified = true;
                }
                if (newPolicy.ARC_PolicyEffectiveDate__c != oldPolicy.ARC_PolicyEffectiveDate__c ||
                    newPolicy.ARC_PolicyExpirationDate__c != oldPolicy.ARC_PolicyExpirationDate__c) {
                    isQualified = true;
                }
            }

            if (isQualified) qualifiedPolicies.add(newPolicy);
        }

        if (qualifiedPolicies.isEmpty()) return;

        // Build identifier sets
        Set<Id> contractIds = new Set<Id>();
        for (InsurancePolicy policy : qualifiedPolicies) {
            if (policy.ARC_Contract__c != null) contractIds.add(policy.ARC_Contract__c);
        }

        // ── Step 1: Evaluate eligibility — BULK (single set of queries for all contracts) ──
        ARC_ContractBillingService.evaluatePolicyEligibilityForContracts(contractIds);

        // ── Step 2: Evaluate adjustments — BULK (single set of queries for all employees) ──
        // Group qualified policies by contractId_employeeId key, excluding pure Awaiting→Activated flips
        // Key: contractId_employeeId → List<Id> policyIds
        Map<String, List<Id>> policyIdsByEmployee = new Map<String, List<Id>>();
        Map<String, Id> contractByEmployeeKey     = new Map<String, Id>();

        for (InsurancePolicy policy : qualifiedPolicies) {
            if (!isInsert && oldPolicyMap != null) {
                InsurancePolicy oldPolicy = oldPolicyMap.get(policy.Id);
                if (oldPolicy != null &&
                    oldPolicy.Status == 'Awaiting Activation' &&
                    policy.Status == 'Activated' &&
                    policy.ARC_PolicyEffectiveDate__c == oldPolicy.ARC_PolicyEffectiveDate__c &&
                    policy.ARC_PolicyExpirationDate__c == oldPolicy.ARC_PolicyExpirationDate__c) {
                    continue; // Pure status flip, no date change — skip adjustments
                }
            }
            if (policy.ARC_Contract__c != null && policy.NameInsuredId != null) {
                String key = String.valueOf(policy.ARC_Contract__c) + '_' + String.valueOf(policy.NameInsuredId);
                if (!policyIdsByEmployee.containsKey(key)) {
                    policyIdsByEmployee.put(key, new List<Id>());
                    contractByEmployeeKey.put(key, policy.ARC_Contract__c);
                }
                policyIdsByEmployee.get(key).add(policy.Id);
            }
        }

        if (!policyIdsByEmployee.isEmpty()) {
            ARC_ContractBillingService.evaluateAdjustmentsForPoliciesBulk(policyIdsByEmployee, oldPolicyMap);
        }

        // ── Step 3: Recalculate next bill amount — BULK (single set of queries for all contracts) ──
        ARC_ContractBillingService.recalculateNextBillAmount(contractIds);
    }

    /*******************************************************************
    * @MethodName         :   changeEffectiveDatePoliciesSG
    * @Description        :   Return a list of Small Group Policies whose effective date is changed.
    ********************************************************************/
    public static Set<Id> changeEffectiveDatePoliciesSG(Map<Id, InsurancePolicy> oldPolicyMap, Map<Id, InsurancePolicy> newPolicyMap) {
        Set<Id> policyList = new Set<Id>();
        Id smallGroupRTId = Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByName().get('Small Group').getRecordTypeId();
        for (Id policyId : newPolicyMap.keySet()) {
            if (
                oldPolicyMap.get(policyId).RecordTypeId == smallGroupRTId &&
                oldPolicyMap.get(policyId).ARC_EffectiveDate__c != newPolicyMap.get(policyId).ARC_EffectiveDate__c
            ) {
                policyList.add(policyId);
            }
        }
        return policyList;
    }
}