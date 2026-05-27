/*******************************************************************
* @ClassName          :   ARC_ContinuousMembershipDateBulk
* @Description        :   Manages logic for: 
                            * Renewal Membership Start Date – Start of continuous WeShare coverage period for renewal discount (capped at 1/1/24).
                            * Continuous Coverage Start Date – Start of continuous coverage period - including UHSM and WeShare programs
* @MethodName         :   updateContinuousMembershipStartDateBulk
********************************************************************/

public without sharing class ARC_ContinuousMembershipDateBulk {

    public class RequestsVariables {
        @InvocableVariable(label='List of Record Ids' description='PA record Ids')
        public list<Id> listRecordIds;
    }

    // Comment for testing purposes

    /*******************************************************************
    * @MethodName         :   updateContinuousMembershipStartDateBulk
    * @Description        :   Used in PersonAccount Activation & Update Continuous Membership Start Date flows. 
                                Populates fields:
                                * Renewal Membership Date. 
                                * Continuous Coverage Date. 
    ********************************************************************/
    @InvocableMethod(label='Continuous Membership Date Bulk' description='description' category='Person Account')
    public static void updateContinuousMembershipStartDateBulk (List<RequestsVariables> requests) {

        Set<Id> recordIds = new Set<Id>();

        for (RequestsVariables request : requests) {
            if (request.listRecordIds != null && !request.listRecordIds.isEmpty()) {
                recordIds.addAll(request.listRecordIds);
            }
        }

        if (!recordIds.isEmpty()) {
            Map<Id, Map<String, Date>> memberSinceDateMap = new Map<Id, Map<String, Date>>();
            List<Account> resultList = new List<Account>();
            List<ARC_CoverageParticipant__c> coverageParticipants;
            try {
                coverageParticipants = [
                    SELECT Id, 
                           ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId,
                           ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.Name,
                           ARC_PolicyParticipant__r.ARC_StartDate__c, 
                           ARC_PolicyParticipant__r.ARC_EndDate__c,
                           ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.ARC_LastWPResetDate__c,
                           ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.Name, 
                           ARC_PolicyCoverage__r.ARC_Reason__c,
                           ARC_Policy__r.RecordType.DeveloperName, 
                           ARC_Policy__r.Status, 
                           ARC_Policy__r.ARC_Contract__r.Status,
                           ARC_Policy__r.ARC_PolicyReason__c,
                           ARC_Policy__r.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.vlocity_ins__GroupId__c,
                           ARC_Policy__r.ARC_SpinnedFromPolicy__r.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.vlocity_ins__GroupId__c
                    FROM ARC_CoverageParticipant__c
                    WHERE ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId IN :recordIds
                        AND ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c = 'Medical'
                        AND ARC_PolicyCoverage__r.ARC_ParentProduct__c = null
                        AND (
                            (
                                ARC_Policy__r.RecordType.DeveloperName = 'ARC_IndividualAndFamily'
                                AND (
                                    ARC_Policy__r.ARC_Contract__r.Status IN ('Activated', 'Terminated', 'Awaiting Activation')
                                    AND ARC_Policy__r.ARC_Contract__r.ARC_EffectiveDate__c <= TODAY
                                )
                            )
                            OR
                            (
                                ARC_Policy__r.RecordType.DeveloperName = 'ARC_SmallGroup'
                                AND (
                                    ARC_Policy__r.Status IN ('Activated', 'Terminated', 'Awaiting Activation')
                                    AND ARC_Policy__r.ARC_EffectiveDate__c <= TODAY
                                )
                            )
                        )
                    ORDER BY ARC_Policy__r.ARC_EffectiveDate__c ASC, ARC_Policy__r.CreatedDate ASC
                ];
            } catch (Exception e) {
                throw new FlowException('error querying records: ' + e.getMessage());
            }

            try {
                for (ARC_CoverageParticipant__c covPart : coverageParticipants) {
                    Id accountId = covPart.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId;
                    Date lastWPResetDate = covPart.ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.ARC_LastWPResetDate__c;
                    Date effectiveDate = covPart.ARC_PolicyParticipant__r.ARC_StartDate__c != null ? covPart.ARC_PolicyParticipant__r.ARC_StartDate__c : null;
                    Date expirationDate = covPart.ARC_PolicyParticipant__r.ARC_EndDate__c != null ? covPart.ARC_PolicyParticipant__r.ARC_EndDate__c : null;
                    String planName = covPart.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.Name;
                    String status;
                    String reasons = '';
                    List<String> reasonsList = new List<String>();
                    Id familyAccountId = covPart.ARC_Policy__r.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c != null ? covPart.ARC_Policy__r.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.vlocity_ins__GroupId__c : null;
                    Id renewedFamilyAccountId = covPart.ARC_Policy__r.ARC_SpinnedFromPolicy__c != null ? covPart.ARC_Policy__r.ARC_SpinnedFromPolicy__r.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.vlocity_ins__GroupId__c : null;
                    Boolean isSpinnedOffFamily = false;

                    if (covPart.ARC_Policy__r.RecordType.DeveloperName == 'ARC_IndividualAndFamily') {
                        // Get the Policy Status
                        status = covPart.ARC_Policy__r.ARC_Contract__r.Status;
                        // Get the Policy Reasons
                        reasons = covPart.ARC_Policy__r.ARC_PolicyReason__c;
                        //reasonsList = reasons.split('<br>');
                        reasonsList = String.isNotBlank(reasons) ? reasons.split('<br>') : new List<String>();
                        isSpinnedOffFamily = reasonsList.contains('Spin Off') && familyAccountId != null && familyAccountId != renewedFamilyAccountId;
                    } else if (covPart.ARC_Policy__r.RecordType.DeveloperName == 'ARC_SmallGroup') {
                        // Get the Policy Status
                        status = covPart.ARC_Policy__r.Status;
                        // Get the Policy Reasons
                        reasons = covPart.ARC_PolicyCoverage__r.ARC_Reason__c;
                        //reasonsList = reasons.split('<br>');
                        reasonsList = String.isNotBlank(reasons) ? reasons.split('<br>') : new List<String>();
                    }

                    Map<String, Date> datesMap = memberSinceDateMap.containsKey(accountId) ? memberSinceDateMap.get(accountId): new Map<String, Date>();

                    // Program is UHSM or WeShare, counts for Continuous Coverage Start Date
                    if (
                        !datesMap.containsKey('inactiveDateForCCD')
                        || datesMap.get('inactiveDateForCCD').addDays(1) < effectiveDate
                    ) {
                        datesMap.put('sinceDateForCCD', effectiveDate);
                    }

                    if (status == 'Terminated' && expirationDate != null) { 
                        datesMap.put('inactiveDateForCCD', expirationDate);
                    }

                    // Set Renewal Membership Start Date applicable for (WeShare Only)
                    if (
                        planName.contains('WeShare')
                        && (
                            !datesMap.containsKey('sinceDateForRMD') 
                            || !datesMap.containsKey('inactiveDateForRMD')
                            || datesMap.get('inactiveDateForRMD').addDays(1) < effectiveDate
                        )
                    ) {
                        datesMap.put('sinceDateForRMD', effectiveDate);
                    }
                    
                    if (status == 'Terminated' && expirationDate != null) {
                        datesMap.put('inactiveDateForRMD', expirationDate);
                    }

                    
                    // Get the best Policy for Last Waiting Period Reset Date field
                    if (
                        !datesMap.containsKey('lastWPReset') ||
                        (reasonsList.contains('Program Upgrade') || reasonsList.contains('Upgraded Spin Off') || (reasonsList.contains('New Application'))) ||
                        isSpinnedOffFamily ||
                        (datesMap.containsKey('lastPolicyInactiveDate') && datesMap.get('lastPolicyInactiveDate').addDays(1) < effectiveDate)
                        ) 
                    {
                        datesMap.put('lastWPReset', effectiveDate);
                    }

                    // Store the last Policy Inactive Date
                    if (status == 'Terminated' && expirationDate != null) {
                        datesMap.put('lastPolicyInactiveDate', expirationDate);
                    }

                    memberSinceDateMap.put(accountId, datesMap); 
                }
                
                // THE RENEWAL DISCOUNTS IN PROD WERE CREATED FROM 01/01/2025 GRANTING THE 1ST RENEWALS FOR MEMBERS WITH START DATE <= 01/01/24. 
                Date firstRenewalDate = Date.newInstance(2024, 01, 01);
                for (Id recordId : recordIds) {
                    Account acc = new Account(Id=recordId);
                    Map<String, Date> datesMap = memberSinceDateMap.containsKey(acc.Id) ? memberSinceDateMap.get(acc.Id): new Map<String, Date>();
                    acc.ARC_ContinuousMembershipStartDate__c = datesMap.containsKey('sinceDateForRMD') 
                        ? (datesMap.get('sinceDateForRMD') < firstRenewalDate 
                            ? firstRenewalDate 
                            : datesMap.get('sinceDateForRMD')) 
                        : null;
                    acc.ARC_ContinuousCoverageStartDate__c = datesMap.containsKey('sinceDateForCCD') ? datesMap.get('sinceDateForCCD') : null;
                    acc.ARC_LastWPResetDate__c = datesMap.containsKey('lastWPReset') ? datesMap.get('lastWPReset') : null;
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