/**
 * @description Batch to update/populate the reset dates (LastWPResetDates) in the Account object.
 */
public class ARC_WPResetDateBackfillBatch implements Database.Batchable<sObject> {

    /**
     * @description Query all the .
     * @param bc The batch context.
     * @return Database.QueryLocator containing the SOQL query for the records to process.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, ARC_LastWPResetDate__c
            FROM Account 
            WHERE (RecordType.Name = 'Individual and Family Person Account' OR RecordType.Name = 'Small Group Person Account')
            AND IsActive = true
        ]);
    }

    /**
     * @description Query the ARC_CoverageParticipant__c records in order to select the best WP Reset Date for the Accounts.
     * @param bc The batch context.
     * @param scope List of Accounts with I&F or SG record types.
     */
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // Variables
        Set<Id> accountIds;
        Map<Id, Map<String, Date>> memberSinceDateMap = new Map<Id, Map<String, Date>>();
        List<Account> resultList = new List<Account>();
        List<ARC_CoverageParticipant__c> coverageParticipants;

        // Get the Account ids
        accountIds = (new Map<Id, Account> (scope)).keySet();

        // Get the Coverage Participants if accountIds is not empty
        if (!accountIds.isEmpty()) {
            // Try to get the Coverage Participants
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
                    WHERE ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId IN :accountIds
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
                throw new FlowException('Error querying Coverage Participants: ' + e.getMessage());
            }

            // Process the list of Coverage Participants
            try {
                for (ARC_CoverageParticipant__c covPart : coverageParticipants) {
                    Id accountId = covPart.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId;
                    Date lastWPResetDate = covPart.ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.ARC_LastWPResetDate__c;
                    Date effectiveDate = covPart.ARC_PolicyParticipant__r.ARC_StartDate__c != null ? covPart.ARC_PolicyParticipant__r.ARC_StartDate__c : null;
                    Date expirationDate = covPart.ARC_PolicyParticipant__r.ARC_EndDate__c != null ? covPart.ARC_PolicyParticipant__r.ARC_EndDate__c : null;
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
                        reasonsList = reasons.split('<br>');
                        isSpinnedOffFamily = reasonsList.contains('Spin Off') && familyAccountId != null && familyAccountId != renewedFamilyAccountId;
                    } else if (covPart.ARC_Policy__r.RecordType.DeveloperName == 'ARC_SmallGroup') {
                        // Get the Policy Status
                        status = covPart.ARC_Policy__r.Status;
                        // Get the Policy Reasons
                        reasons = covPart.ARC_PolicyCoverage__r.ARC_Reason__c;
                        reasonsList = reasons.split('<br>');
                    }

                    Map<String, Date> datesMap = memberSinceDateMap.containsKey(accountId) ? memberSinceDateMap.get(accountId): new Map<String, Date>();

                    if (!datesMap.containsKey('lastWPReset')) {
                        System.debug('**********First Entry**********');
                        System.debug('Member: ' + covPart.ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.Name);
                        System.debug('Last WP Reset Date: ' + lastWPResetDate);
                        System.debug('Effective Date: ' + effectiveDate);
                    } else if ((reasonsList.contains('Program Upgrade') || reasonsList.contains('Upgraded Spin Off') || (reasonsList.contains('New Application')))) {
                        System.debug('**********Program Upgrade**********');
                        System.debug('Member: ' + covPart.ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.Name);
                        System.debug('Last WP Reset Date: ' + lastWPResetDate);
                        System.debug('Effective Date: ' + effectiveDate);
                    } else if (isSpinnedOffFamily) {
                        System.debug('**********SpinnedOff Family**********');
                        System.debug('Member: ' + covPart.ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.Name);
                        System.debug('Last WP Reset Date: ' + lastWPResetDate);
                        System.debug('Effective Date: ' + effectiveDate);
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

                    if ((datesMap.containsKey('lastPolicyInactiveDate') && datesMap.get('lastPolicyInactiveDate').addDays(1) < effectiveDate)) {
                        System.debug('**********Policy Gap**********');
                        System.debug('Member: ' + covPart.ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.Name);
                        System.debug('Last WP Reset Date: ' + lastWPResetDate);
                        System.debug('Effective Date: ' + effectiveDate);
                        System.debug('Inactive Date for CCD: ' + datesMap.get('inactiveDateForCCD'));
                    } 

                    // Store the last Policy Inactive Date
                    if (status == 'Terminated' && expirationDate != null) {
                        datesMap.put('lastPolicyInactiveDate', expirationDate);
                    }

                    memberSinceDateMap.put(accountId, datesMap); 
                }

                for (Account accountTmp : scope) {
                    Map<String, Date> datesMap = memberSinceDateMap.containsKey(accountTmp.Id) ? memberSinceDateMap.get(accountTmp.Id): new Map<String, Date>();
                    Date lastWPResetDate = datesMap.containsKey('lastWPReset') ? datesMap.get('lastWPReset') : null;

                    if (lastWPResetDate != null && lastWPResetDate != accountTmp.ARC_LastWPResetDate__c) {
                        accountTmp.ARC_LastWPResetDate__c = lastWPResetDate;
                        resultList.add(accountTmp);
                    }
                }
            } catch (Exception e) {
                throw new FlowException('Error processing records: ' + e.getMessage());
            }

            // Update Accounts
            try {
                update resultList;
            } catch (Exception e) {
                throw new FlowException('Error inserting records: ' + e.getMessage());
            }
        }
    }

    /**
     * @description The finish method executes once all chunks have been processed.
     * @param bc The batch context.
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('Batch ARC_WPResetDateBackfillBatch finished successfully.');
    }
}