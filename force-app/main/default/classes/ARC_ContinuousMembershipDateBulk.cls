/*******************************************************************
* @ClassName          :   ARC_ContinuousMembershipDateBulk
* @Description        :   Manages logic for: 
                            * Renewal Membership Start Date – Start of continuous WeShare coverage period for renewal discount (capped at 1/1/24).
                            * Continuous Coverage Start Date – Start of continuous coverage period - including UHSM and WeShare programs
                            * Last Aggregator Reset Date – Tracks the start date of yearly benefits for a user. Same as Continuous Coverage, but also updates on Program Upgrades.
* @MethodName         :   updateContinuousMembershipStartDateBulk
********************************************************************/

public without sharing class ARC_ContinuousMembershipDateBulk {

    public class RequestsVariables {
        @InvocableVariable(label='List of Record Ids' description='PA record Ids')
        public list<Id> listRecordIds;
    }

    /*******************************************************************
    * @MethodName         :   updateContinuousMembershipStartDateBulk
    * @Description        :   Used in PersonAccount Activation & Update Continuous Membership Start Date flows. 
                                Populates fields:
                                * Renewal Membership Date. 
                                * Continuous Coverage Date. 
                                * Last Aggregator Reset Date. 
    ********************************************************************/
    @InvocableMethod(label='Continuous Membership Date Bulk' description='description' category='Person Account')
    public static void updateContinuousMembershipStartDateBulk (List<RequestsVariables> requests) {

        List<Id> recordIds = new List<Id>();

        for (RequestsVariables request : requests) {
            if (request.listRecordIds != null && !request.listRecordIds.isEmpty()) {
                recordIds = request.listRecordIds;
            }
        }

        System.debug('records: ' + recordIds);
        if (!recordIds.isEmpty()) {
            Map<Id, Map<String, Date>> memberSinceDateMap = new Map<Id, Map<String, Date>>();
            List<Account> resultList = new List<Account>();
            List<vlocity_ins__GroupCensusMemberPlan__c> gcmpRelatedToEach;
            List<InsurancePolicyParticipant> policyParticipants;
            Map<String, Map<String, InsurancePolicyParticipant>> policyParticipantsMap = new Map<String, Map<String, InsurancePolicyParticipant>>();
            try {
                // Get all the medical GCMP of each record id
                gcmpRelatedToEach = [
                    SELECT vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c,
                        vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status,
                        vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c,
                        vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c,
                        vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId,
                        vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Name,
                        vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.PersonBirthdate,
                        vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_ContractReason__c,
                        vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.CreatedDate,
                        vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_AwaitingActivationDate__c,
                        vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.vlocity_ins__ExpiredContractId__c,
                        vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.vlocity_ins__ExpiredContractId__r.ARC_MedicalPlan__r.Name,
                        vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_MedicalPlan__r.Name,
                        vlocity_ins__ContractLineId__r.Name
                    FROM vlocity_ins__GroupCensusMemberPlan__c
                    WHERE vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId IN :recordIds
                    AND vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical'
                    AND (
                        vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Activated' 
                        OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Terminated'
                        OR (vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c <= TODAY
                            AND vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Awaiting Activation'))
                    ORDER BY vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c ASC, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.CreatedDate ASC];

                policyParticipants = [
                    SELECT Id, EffectiveDate, ExpirationDate, InsurancePolicy.ARC_Contract__c, PrimaryParticipantContact.AccountId
                    FROM InsurancePolicyParticipant
                    WHERE PrimaryParticipantContact.AccountId IN :recordIds
                ];
                
                for (InsurancePolicyParticipant polPart : policyParticipants) {
                    if (!policyParticipantsMap.containsKey(polPart.InsurancePolicy.ARC_Contract__c)) {
                        policyParticipantsMap.put(polPart.InsurancePolicy.ARC_Contract__c, new Map<String, InsurancePolicyParticipant>());
                    }
                    policyParticipantsMap.get(polPart.InsurancePolicy.ARC_Contract__c).put(polPart.PrimaryParticipantContact.AccountId, polPart);
                }
            } catch (Exception e) {
                throw new FlowException('error querying records: ' + e.getMessage());
            }

            try {
                if (gcmpRelatedToEach.size() == 0) throw new FlowException('No records found');
                for (vlocity_ins__GroupCensusMemberPlan__c plan: gcmpRelatedToEach) {
                    Map<String, Date> datesMap = memberSinceDateMap.containsKey(plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId)? memberSinceDateMap.get(plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId): new Map<String, Date>();
                    InsurancePolicyParticipant polPart = policyParticipantsMap.get(plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c).get(plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId);
                    System.debug('polPart.EffectiveDate: ' + polPart.EffectiveDate);
                    System.debug('polPart.ExpirationDate: ' + polPart.ExpirationDate);
                    Date effectiveDate = polPart.EffectiveDate != null ? Date.valueOf(polPart.EffectiveDate) : null;
                    Date expirationDate = polPart.ExpirationDate != null ? Date.valueOf(polPart.ExpirationDate) : null;
                    System.debug('effectiveDate: ' + effectiveDate);
                    System.debug('expirationDate: ' + expirationDate);
                    // saves last upgrade date for lastAggReset date
                    Boolean isUpgrade = plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.ARC_ContractReason__c.contains('Program Upgrade') 
                        || plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.ARC_ContractReason__c.contains('New Application')
                        || plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.ARC_ContractReason__c.contains('Upgraded Spin Off')
                        || (
                            plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.vlocity_ins__ExpiredContractId__r?.ARC_MedicalPlan__r?.Name.contains('UHSM') 
                            && plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.ARC_MedicalPlan__r?.Name.contains('WeShare')
                        );
                    if (isUpgrade) {    
                        // LARD : Last Aggregators Reset Date //
                        if (!datesMap.containsKey('LARD')) {
                            datesMap.put('LARD', effectiveDate);
                        } else if (datesMap.get('LARD') < effectiveDate) {
                            datesMap.put('LARD', effectiveDate);
                        }
                    }

                    // program is UHSM or WeShare, counts for Continuous Coverage Start Date & Last Aggregators Reset Date
                    if (
                        !datesMap.containsKey('inactiveDateForCCD')
                        || datesMap.get('inactiveDateForCCD').addDays(1) < effectiveDate
                    ) {
                        datesMap.put('sinceDateForCCD', effectiveDate);
                        datesMap.put('LARD', effectiveDate);
                    }

                    if (
                        plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status == 'Terminated'
                        && expirationDate != null
                    ) { 
                        datesMap.put('inactiveDateForCCD', expirationDate);
                    }

                    // set Renewal Membership Start Date applicable for (WeShare Only)
                    if (plan.vlocity_ins__ContractLineId__r.Name.contains('WeShare')) {
                        if (
                            !datesMap.containsKey('inactiveDateForRMD')
                            || datesMap.get('inactiveDateForRMD').addDays(1) < effectiveDate
                        ) {
                            datesMap.put('sinceDateForRMD', effectiveDate);
                        }
                    }
                    
                    if (
                        plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status == 'Terminated'
                        && expirationDate != null
                    ) {
                        datesMap.put('inactiveDateForRMD', expirationDate);
                    }

                    memberSinceDateMap.put(plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId, datesMap); 
                }
                
                // THE RENEWAL DISCOUNTS IN PROD WERE CREATED FROM 01/01/2025 GRANTING THE 1ST RENEWALS FOR MEMBERS WITH START DATE <= 01/01/24. 
                Date firstRenewalDate = Date.newInstance(2024, 01, 01);
                for (Id recordId: recordIds) {
                    System.debug('>>>debug control 1');
                    Account acc = new Account(Id=recordId);
                    Map<String, Date> datesMap = memberSinceDateMap.containsKey(acc.Id)? memberSinceDateMap.get(acc.Id): new Map<String, Date>();
                    System.debug('>>>debug datesMap' + datesMap);
                    acc.ARC_ContinuousMembershipStartDate__c = datesMap.containsKey('sinceDateForRMD') ? (datesMap.get('sinceDateForRMD') < firstRenewalDate ? firstRenewalDate : datesMap.get('sinceDateForRMD')) : null;
                    System.debug('>>>debug control 1.1');
                    acc.ARC_ContinuousCoverageStartDate__c = datesMap.containsKey('sinceDateForCCD') ? datesMap.get('sinceDateForCCD') : null;
                    System.debug('>>>debug control 1.2');
                    acc.ARC_Last_Aggregator_Reset_Date__c = datesMap.containsKey('LARD') ? datesMap.get('LARD') : null;
                    System.debug('>>>debug control 1.3');
                    resultList.add(acc);
                }
            } catch (Exception e) {
                throw new FlowException('Error processing records: ' + e.getMessage());
            }

            try {
                update resultList;
            } catch (Exception e) {
                throw new FlowException('Error inserting records: ' + e.getMessage());
            }
        }
    }
}