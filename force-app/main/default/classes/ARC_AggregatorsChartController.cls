/*******************************************************************
* @ClassName          :   ARC_AggregatorsChartController
* @Description        :   Controller for LWC ARC_AggregatorsChart AND ARC_AggregatorsChart360 for displaying member's aggregators
********************************************************************/
public with sharing class ARC_AggregatorsChartController {

    /*******************************************************************
    * @MethodName         :   getAggregators
    * @Description        :   Get aggregators method used in ARC_AggregatorsChart for Claim and InsurancePolicy views.
                                recordId is either a Claim id or an InsurancePolicy id
    * @Parameters         :   String recordId
    ********************************************************************/
    @AuraEnabled
    public static Map<String, Object> getAggregators(String recordId) {
        List<Id> policies = new List<Id>();
        String sObjName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
        Map<String, Object> output = new Map<String, Object>();
        List<ARC_Aggregator__c> aggregators = new List<ARC_Aggregator__c>();
        Set<Id> memberIds = new Set<Id>();
        InsurancePolicy recordPolicy;
        List<ARC_CoverageParticipant__c> covParticipants;
        Map<Id, Boolean> memberHasFamily = new Map<Id, Boolean>();
        Map<Id, Boolean> memberHasPreex = new Map<Id, Boolean>();
        Map<Id, Boolean> memberHasCritIll = new Map<Id, Boolean>();
        Date currentDate = Date.today();

        if (sObjName == 'InsurancePolicy') {
            recordPolicy = [SELECT Id,
                                   ARC_Contract__r.ARC_ContractReason__c, 
                                   RenewedFromPolicyId, ARC_PolicyReason__c,
                                   RenewedFromPolicy.ARC_Contract__r.Status, 
                                   PriorPolicy.ARC_Contract__r.Status, 
                                   PriorPolicyId ,
                                   ARC_EffectiveDate__c,
                                   ARC_ExpirationDate__c
                            FROM InsurancePolicy 
                            WHERE Id = :Id.valueOf(recordId) LIMIT 1];

        } else if (sObjName == 'Claim') {
            Claim clm = [SELECT PolicyNumber.RenewedFromPolicyId, 
                                PolicyNumberId, ARC_DOSFrom__c, 
                                ARC_MemberContact__r.AccountId 
                        FROM Claim 
                        WHERE Id = :Id.valueOf(recordId) 
                        LIMIT 1];
            recordPolicy = [SELECT Id,
                                   ARC_Contract__r.ARC_ContractReason__c, 
                                   RenewedFromPolicyId, 
                                   ARC_PolicyReason__c,
                                   RenewedFromPolicy.ARC_Contract__r.Status, 
                                   PriorPolicy.ARC_Contract__r.Status, 
                                   PriorPolicyId,
                                   ARC_EffectiveDate__c,
                                   ARC_ExpirationDate__c
                            FROM InsurancePolicy 
                            WHERE Id = :clm.PolicyNumberId 
                            LIMIT 1];
            Integer clmYear = clm?.ARC_DOSFrom__c?.year();
            output.put('clmYear', clmYear);
            output.put('clmAccount', clm?.ARC_MemberContact__r?.AccountId);

        } else if (sObjName == 'Account') {    
            List<InsurancePolicy> active_policies_query_result = [
                    SELECT 
                        Name, 
                        Id,
                        ARC_Contract__r.ARC_ContractReason__c, 
                        RenewedFromPolicyId, 
                        ARC_PolicyReason__c, 
                        RenewedFromPolicy.ARC_Contract__r.Status, 
                        PriorPolicy.ARC_Contract__r.Status, 
                        PriorPolicyId,
                        ARC_EffectiveDate__c,
                        ARC_ExpirationDate__c
                    FROM InsurancePolicy
                    WHERE Id IN (
                        SELECT InsurancePolicyId
                        FROM InsurancePolicyParticipant 
                        WHERE Participant_Account_Id__c = :recordId
                    )
                    AND ARC_Contract__r.Status != 'Voided'
                    AND ARC_isActive__c = true      
                    ORDER BY 
                        ARC_ExpirationDate__c DESC NULLS FIRST,
                        CreatedDate DESC
            ];

            if (active_policies_query_result.isEmpty() == false) { // If the first query is not empty
                recordPolicy = active_policies_query_result[0];
                output.put('accountPolicy', 'isActive');
            } else if (active_policies_query_result == null || active_policies_query_result.isEmpty()) { // If the first query is empty, tries the second option
        
                active_policies_query_result = [
                    SELECT 
                        Name, 
                        Id,
                        ARC_Contract__r.ARC_ContractReason__c, 
                        RenewedFromPolicyId, 
                        ARC_PolicyReason__c, 
                        RenewedFromPolicy.ARC_Contract__r.Status, 
                        PriorPolicy.ARC_Contract__r.Status, 
                        PriorPolicyId,
                        ARC_EffectiveDate__c,
                        ARC_ExpirationDate__c
                    FROM InsurancePolicy
                    WHERE Id IN (
                        SELECT InsurancePolicyId
                        FROM InsurancePolicyParticipant 
                        WHERE Participant_Account_Id__c = :recordId
                    )
                    AND ARC_Contract__r.Status != 'Voided'     
                    ORDER BY 
                        ARC_ExpirationDate__c DESC NULLS FIRST,
                        CreatedDate DESC
                ];
                output.put('accountPolicy', 'lastCreated');
                if (active_policies_query_result.isEmpty() == false)
                    recordPolicy = active_policies_query_result[0];
            } 
        }
        covParticipants = [
            SELECT ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode, ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId
            FROM ARC_CoverageParticipant__c
            WHERE ARC_Policy__c = :recordPolicy.Id
                AND ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c = 'Medical'
        ];
        Boolean hasCritIllProduct = false;
        for (ARC_CoverageParticipant__c covPart : covParticipants) {
            if (covPart.ARC_PolicyParticipant__r?.PrimaryParticipantContact == null) continue;
            memberIds.add(covPart.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId);
            String productCode = covPart.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode;
            Boolean isLegacy = productCode.contains('Legacy') || productCode.contains('Senior');
            memberHasFamily.put(covPart.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId, !isLegacy);
            ARC_ProductAggregators__mdt aggValues = ARC_ProductAggregators__mdt.getInstance(productCode);
            Double preexValue = (Double) aggValues.get('IND_PREEX__c');
            Double critIllValue = (Double) aggValues.get('IND_CRITILL__c');
            memberHasPreex.put(covPart.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId, preexValue != null);
            memberHasCritIll.put(covPart.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId, critIllValue != null);
            hasCritIllProduct = hasCritIllProduct || (critIllValue != null);
        }

        // Calculate coverage periods for Pre-Existing and Maternity Aggregators
        Map<Id, List<Map<String, Object>>> coveragePeriods_PREEX = ARC_SMBUtility.mapCoveragePeriods(new List<Id>(memberIds), 'PREEX__c');
        Map<Id, List<Map<String, Object>>> coveragePeriods_MAT = ARC_SMBUtility.mapCoveragePeriods(new List<Id>(memberIds), 'MAT__c');

        // Get coverage periods for each member
        Map<Id, List<String>> memberCoveragePeriods_PREEX = new Map<Id, List<String>>();
        for (Id memberId : coveragePeriods_PREEX.keySet()) {
            memberCoveragePeriods_PREEX.put(memberId, ARC_SMBUtility.calculateAggregators(coveragePeriods_PREEX.get(memberId), 'PREEX__c'));
        }

        Map<Id, List<String>> memberCoveragePeriods_MAT = new Map<Id, List<String>>();
        for (Id memberId : coveragePeriods_MAT.keySet()) {
            memberCoveragePeriods_MAT.put(memberId, ARC_SMBUtility.calculateAggregators(coveragePeriods_MAT.get(memberId), 'MAT__c'));
        }
        
        String lastValidPeriod_PREEX = '';
        Map<Id, Date> lastBY1ValidByMember = new Map<Id, Date>();
        Date oldestBY1ValidDate = recordPolicy.ARC_EffectiveDate__c;

        for (Id memberId : memberCoveragePeriods_PREEX.keySet()) {
            Date lastBY1Valid = recordPolicy.ARC_EffectiveDate__c;
            for (String period : memberCoveragePeriods_PREEX.get(memberId)) {
                Date periodStartDate = Date.valueOf(period.split('\\|\\|')[0]);
                if (periodStartDate >= recordPolicy.ARC_EffectiveDate__c) {
                    break;
                }
                if (period.split('\\|\\|')[2] == 'BY1') {
                    lastBY1Valid = periodStartDate;
                }
            }
            lastBY1ValidByMember.put(memberId, lastBY1Valid);
        }

        // Get the oldest BY1 Start Date
        for (Date by1PerMember : lastBY1ValidByMember.values()) {
            if (by1PerMember < oldestBY1ValidDate) oldestBY1ValidDate = by1PerMember;
        }

        // Ternary Expression: Get the policy from which the current policy was renewed from policy if it exists, or just the record policy if it does not exist or it is voided.
        Id policy_id = recordPolicy.Id;

        // Get the Participant Aggregators related to the policy_id
        List<ARC_ParticipantAggregator__c> participantAggregators = [
            SELECT Id, ARC_Aggregator__c, ARC_Aggregator__r.ARC_FamilyAggregator__c, ARC_Aggregator__r.ARC_Code__c
            FROM ARC_ParticipantAggregator__c
            WHERE ARC_Policy__c = :policy_id
        ];

        // Get the Id of the Aggregators and Family Aggregators
        Set<Id> aggregatorIds = new Set<Id>();
        Boolean hasPreExPartAgg = false;

        for (ARC_ParticipantAggregator__c participantAggregatorTemp : participantAggregators) {
            // Add the Aggregator related to the Participant Aggregator to the Set of ids
            aggregatorIds.add(participantAggregatorTemp.ARC_Aggregator__c);

            // Verify if the Participant Aggregator's Aggregator has a Family Aggregator
            if (participantAggregatorTemp.ARC_Aggregator__r.ARC_FamilyAggregator__c != null) {
                System.debug('FAMILY AGGREGATOR ID: ' + participantAggregatorTemp.ARC_Aggregator__r.ARC_FamilyAggregator__c);
                aggregatorIds.add(participantAggregatorTemp.ARC_Aggregator__r.ARC_FamilyAggregator__c);
            }

            hasPreExPartAgg = hasPreExPartAgg || (participantAggregatorTemp.ARC_Aggregator__r.ARC_Code__c == 'PREEX__c');
        }

        Date policyEffectiveDate = recordPolicy.ARC_EffectiveDate__c;

        String query =
            'SELECT Id, Name, ARC_CreatedIn__c, ARC_StartDate__c, ARC_EndDate__c, ARC_ConsumedTotal__c, ARC_FamilyCurrentValue__c, ARC_LimitValue__c, ' +
                'ARC_Year__c, ARC_Type__c, ARC_Member__c, ARC_Member__r.Name, ARC_Member__r.ARC_DependentRelationship__c, RecordType.Name, ' +
                'ARC_NextAvailabilityDate__c, ARC_Code__c, ARC_BenefitYear__c, ' +
            '(' +
                'SELECT Id, ARC_StartDate__c, ARC_Year__c, ARC_ConsumedTotal__c, ARC_LimitValue__c ' + 
                'FROM ComponentAggregators__r' +
            ') ' +
            'FROM ARC_Aggregator__c WHERE ';
        
        String memberCondition;
        if (sObjName == 'Account') {
            memberCondition = 'ARC_Member__c = :recordId';
        } else if (sObjName == 'InsurancePolicy' || sObjName == 'Claim') {
            memberCondition = 'ARC_Member__c IN :memberIds';
        }

        query += 
            'ARC_IsInactive__c = false ' +
            'AND RecordType.DeveloperName != \'IndividualMonthly\' ' +
            'AND (';

        query +=
            '(Id IN :aggregatorIds ' +
            'AND (' + memberCondition + ' OR RecordType.DeveloperName = \'Family\'))';

        if (hasCritIllProduct) {
            query +=
                ' OR (' + memberCondition +
                ' AND ARC_Code__c = \'CRITILL__c\'' +
                ' AND RecordType.DeveloperName = \'Individual\')';
        }

        if (hasPreExPartAgg) {
            query +=
                ' OR (' + memberCondition +
                ' AND ARC_StartDate__c <= :policyEffectiveDate ' +
                ' AND ARC_StartDate__c >= :oldestBY1ValidDate ' +
                ' AND ARC_Code__c = \'PREEX__c\')';
        }

        query += ')';

        aggregators = Database.query(query);

        List<ARC_Aggregator__c> filteredAggregators = new List<ARC_Aggregator__c>();
        for (ARC_Aggregator__c agg : aggregators) {
            if (memberHasPreex.containsKey(agg.ARC_Member__c) && !memberHasPreex.get(agg.ARC_Member__c) && agg.ARC_Code__c == 'PREEX__c') continue;
            if (agg.ARC_Code__c == 'PREEX__c' && agg.ARC_StartDate__c != null && agg.ARC_BenefitYear__c != null) {
                if (
                    (agg.ARC_BenefitYear__c == 'BY1' && agg.ARC_StartDate__c.addYears(3) < policyEffectiveDate)
                    || (agg.ARC_BenefitYear__c == 'BY2' && agg.ARC_StartDate__c.addYears(2) < policyEffectiveDate)
                    || (agg.ARC_BenefitYear__c == 'BY3' && agg.ARC_StartDate__c.addYears(1) < policyEffectiveDate)
                ) {
                    continue;
                }
            }
            filteredAggregators.add(agg);
        }

        aggregators = filteredAggregators;

        output.put('object', sObjName);
        output.put('memberIds', memberIds);
        output.put('memberHasFamily', memberHasFamily);
        output.put('aggregators', aggregators);
        output.put('policy_id', policy_id);
        output.put('policy_effective_date', recordPolicy.ARC_EffectiveDate__c);
        output.put('policy_expiration_date', recordPolicy.ARC_ExpirationDate__c);
        output.put('member_coverage_periods_preex', memberCoveragePeriods_PREEX);
        output.put('member_coverage_periods_mat', memberCoveragePeriods_MAT);
        return output;
    }

    /*******************************************************************
    * @MethodName         :   getAggregators360
    * @Description        :   Get aggregators method used in ARC_AggregatorsChart360 for Account 360 view.
                                - recordId is an Account id. 
                                - Returns: 
                                    - 'aggregators' : complete list of aggregators associated to the account 
                                    - 'defaultFromDate' : default date to be used in the chart 
    * @Parameters         :   String recordId
    ********************************************************************/
    @AuraEnabled
    public static Map<String, Object> getAggregators360(String recordId) {
        Map<String, Object> output = new Map<String, Object>();
        List<ARC_Aggregator__c> aggregators = new List<ARC_Aggregator__c>(); 
        Date defaultFromDate;

        List<AggregateResult> maxIPPEndDate = [
            SELECT MAX(ARC_EndDate__c) maxEndDate
            FROM InsurancePolicyParticipant
            WHERE PrimaryParticipantContactId IN 
                (
                    SELECT PersonContactId
                    FROM Account
                    WHERE Id = :recordId AND isActive = false
                )
                AND ARC_EndDate__c != null];
        
        if (maxIPPEndDate.size() > 0) {
            defaultFromDate = maxIPPEndDate[0].get('maxEndDate') != null ? (Date)maxIPPEndDate[0].get('maxEndDate') : Date.today();
        } else {
            defaultFromDate = Date.today();
        }

        Id individualRecordType = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();

        List<ARC_Aggregator__c> memberAggregators = [
            SELECT Id, Name, ARC_CreatedIn__c, ARC_StartDate__c, ARC_EndDate__c, ARC_ConsumedTotal__c, ARC_FamilyCurrentValue__c, ARC_LimitValue__c, 
                ARC_Year__c, ARC_Type__c, ARC_Member__c, ARC_Member__r.Name, ARC_Member__r.ARC_DependentRelationship__c, RecordType.Name,
                ARC_NextAvailabilityDate__c, ARC_Code__c, ARC_BenefitYear__c, ARC_FamilyAggregator__c,
            (
                SELECT Id, ARC_Year__c, ARC_ConsumedTotal__c, ARC_LimitValue__c, ARC_StartDate__c, ARC_EndDate__c
                FROM ComponentAggregators__r
            )
            FROM ARC_Aggregator__c 
            WHERE ARC_IsInactive__c = false
                AND ARC_Member__c = :recordId
                AND RecordTypeId = :individualRecordType
        ];

        List<Id> familyAggregatorIds = new List<Id>();
        for (ARC_Aggregator__c agg : memberAggregators) {
            if (agg.ARC_Code__c == 'AMCS__c' && agg.ARC_FamilyAggregator__c != null) {
                familyAggregatorIds.add(agg.ARC_FamilyAggregator__c);
            }
        }

        List<ARC_Aggregator__c> familyAggregators = [
            SELECT Id, Name, ARC_CreatedIn__c, ARC_StartDate__c, ARC_EndDate__c, ARC_ConsumedTotal__c, ARC_FamilyCurrentValue__c, ARC_LimitValue__c, 
                ARC_Year__c, ARC_Type__c, ARC_Member__c, ARC_Member__r.Name, ARC_Member__r.ARC_DependentRelationship__c, RecordType.Name,
                ARC_NextAvailabilityDate__c, ARC_Code__c, ARC_BenefitYear__c
            FROM ARC_Aggregator__c 
            WHERE Id IN :familyAggregatorIds
        ];

        aggregators.addAll(memberAggregators);
        aggregators.addAll(familyAggregators);

        output.put('aggregators', aggregators);
        output.put('defaultFromDate', defaultFromDate);
        return output;
    }
}