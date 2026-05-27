/**
 * Purpose:
 * - Business rules engine for portal user provisioning based on Contact changes.
 * - Detects relevant field changes and ALWAYS publishes SG_Portal_User_Provisioning__e,
 * delegating the DML to the async subscriber (avoiding Mixed DML naturally).
 */
public without sharing class ARC_SGContactPortalUserHandler {

    private static final String RT_DEVNAME_SG        = 'ARC_SmallGroup';
    private static final Set<String> INELIGIBLE_STATUSES = new Set<String>{ 'Draft', 'Voided', 'Terminated' };
    private static final String DOCUSIGN_COMPLETED        = 'Completed';

    public static void run(List<Contact> newList, Map<Id, Contact> oldMap, Boolean isInsert, Boolean isUpdate) {
        if (newList == null || newList.isEmpty()) return;

        Id sgRtId = getContactRecordTypeId(RT_DEVNAME_SG);
        if (sgRtId == null) return;

        List<Contact> candidates = new List<Contact>();

        for (Contact c : newList) {
            if (c.RecordTypeId != sgRtId || c.AccountId == null) continue;

            if (isInsert) {
                if (isAdminOrViewer(c.ARC_PortalAccess__c)) {
                    candidates.add(c);
                }
            } else if (isUpdate) {
                Contact oldC = oldMap != null ? oldMap.get(c.Id) : null;
                if (oldC == null) continue;

                if (hasPortalAccessChanged(oldC.ARC_PortalAccess__c, c.ARC_PortalAccess__c) ||
                    hasEmailChanged(oldC, c) ||
                    hasNameChanged(oldC, c)) {

                    candidates.add(c);
                }
                //fix to bug-3534

                //end fix to bug-3534
            }
        }

        if (candidates.isEmpty()) return;

        // Deactivations always publish regardless of contract state —
        // a terminated contract should not prevent a user from being disabled.
        Set<Id> provisioningIds = new Set<Id>();
        Set<Id> deactivationIds = new Set<Id>();
        for (Contact c : candidates) {
            if (isAdminOrViewer(c.ARC_PortalAccess__c)) {
                provisioningIds.add(c.Id);
            } else {
                deactivationIds.add(c.Id);
            }
        }

        Set<Id> eligibleContactIds = computeEligibleContactIds(provisioningIds);

        List<SObject> eventsToPublish = new List<SObject>();
        for (Contact c : candidates) {
            if (deactivationIds.contains(c.Id) || eligibleContactIds.contains(c.Id)) {
                eventsToPublish.add(new SG_Portal_User_Provisioning__e(ContactId__c = String.valueOf(c.Id)));
            }
        }
        // fix to bug-3534
        // for(Contact c : deactivationCandidates){
        //     eventsToPublish.add(new SG_Portal_User_Provisioning__e(ContactId__c = String.valueOf(c.Id)));
        // }
        //end fix to bug-3534

        if (!eventsToPublish.isEmpty()) EventBus.publish(eventsToPublish);
    }

    /**
     * Entry point for the AccountContactRelation trigger.
     * Handles the TPA case where the ACR is created AFTER the Contact save,
     * so the Contact trigger couldn't verify eligibility at that time.
     */
    public static void runFromACR(List<AccountContactRelation> newACRs) {
        if (newACRs == null || newACRs.isEmpty()) return;

        Id sgRtId = getContactRecordTypeId(RT_DEVNAME_SG);
        if (sgRtId == null) return;

        // Collect contact IDs from the new ACRs
        Set<Id> contactIds = new Set<Id>();
        for (AccountContactRelation acr : newACRs) {
            if (acr.ContactId != null) contactIds.add(acr.ContactId);
        }

        // Re-fetch full Contact records to check RecordType and PortalAccess
        List<Contact> contacts = [
            SELECT Id, AccountId, RecordTypeId, ARC_PortalAccess__c, FirstName, LastName, Email
            FROM Contact
            WHERE Id IN :contactIds
              AND RecordTypeId = :sgRtId
              AND ARC_PortalAccess__c IN ('Admin', 'Viewer')
        ];
        if (contacts.isEmpty()) return;

        // Build eligible set from the filtered contacts only (SG RT + Admin/Viewer)
        Set<Id> filteredContactIds = new Map<Id, Contact>(contacts).keySet();
        Set<Id> eligibleContactIds = computeEligibleContactIds(filteredContactIds);

        List<SObject> eventsToPublish = new List<SObject>();
        for (Contact c : contacts) {
            if (eligibleContactIds.contains(c.Id)) {
                eventsToPublish.add(new SG_Portal_User_Provisioning__e(ContactId__c = String.valueOf(c.Id)));
            }
        }

        if (!eventsToPublish.isEmpty()) EventBus.publish(eventsToPublish);
    }

    // ===================== Helpers =====================

    private static Boolean isAdminOrViewer(String access) {
        String v = String.isBlank(access) ? '' : access.trim();
        return v == 'Admin' || v == 'Viewer';
    }

    private static Boolean hasPortalAccessChanged(String oldV, String newV) {
        System.debug('is here: ' + oldV + ' - ' + newV);
        String o = String.isBlank(oldV) ? 'no access' : oldV.trim().toLowerCase();
        String n = String.isBlank(newV) ? 'no access' : newV.trim().toLowerCase();
        
        if (o != 'admin' && o != 'viewer') o = 'no access';
        if (n != 'admin' && n != 'viewer') n = 'no access';
        
        return o != n;
    }

    private static Id getContactRecordTypeId(String devName) {
        Map<String, Schema.RecordTypeInfo> byDevName = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName();
        return (byDevName != null && byDevName.containsKey(devName)) ? byDevName.get(devName).getRecordTypeId() : null;
    }

    /**
     * Returns the subset of contactIds that are eligible for portal provisioning.
     * Eligibility = the contact has an ACR to a Small group employer that has
     * at least one Contract with Status NOT IN (Draft, Voided, Terminated).
     */
    private static Set<Id> computeEligibleContactIds(Set<Id> contactIds) {
        if (contactIds == null || contactIds.isEmpty()) return new Set<Id>();

        Id employerRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get(RT_DEVNAME_SG)
            .getRecordTypeId();

        System.debug('### employerRtId=' + employerRtId + ' | contactIds=' + contactIds);

        Set<Id> employerAccountIds = new Set<Id>();
        Map<Id, Set<Id>> contactToEmployerAccounts = new Map<Id, Set<Id>>();
        List<AccountContactRelation> allAcrs = [SELECT ContactId, AccountId, Account.RecordType.DeveloperName FROM AccountContactRelation WHERE ContactId IN :contactIds];
        System.debug('### all ACRs (unfiltered): ' + allAcrs);

        for (AccountContactRelation acr : allAcrs) {
            if (acr.Account.RecordTypeId != employerRtId) continue;
            if (!contactToEmployerAccounts.containsKey(acr.ContactId)) {
                contactToEmployerAccounts.put(acr.ContactId, new Set<Id>());
            }
            contactToEmployerAccounts.get(acr.ContactId).add(acr.AccountId);
            employerAccountIds.add(acr.AccountId);
        }

        System.debug('### employerAccountIds after RT filter: ' + employerAccountIds);
        if (employerAccountIds.isEmpty()) return new Set<Id>();

        List<Contract> allContracts = [SELECT AccountId, Status, vlocity_ins__LastDocuSignEnvelopeStatus__c FROM Contract WHERE AccountId IN :employerAccountIds];
        System.debug('### contracts (unfiltered): ' + allContracts);

        Set<Id> eligibleEmployerIds = new Set<Id>();
        for (Contract c : allContracts) {
            if (!INELIGIBLE_STATUSES.contains(c.Status) && c.vlocity_ins__LastDocuSignEnvelopeStatus__c == DOCUSIGN_COMPLETED) {
                eligibleEmployerIds.add(c.AccountId);
            }
        }

        System.debug('### eligibleEmployerIds: ' + eligibleEmployerIds);

        Set<Id> eligibleContactIds = new Set<Id>();
        for (Id contactId : contactToEmployerAccounts.keySet()) {
            for (Id empAccId : contactToEmployerAccounts.get(contactId)) {
                if (eligibleEmployerIds.contains(empAccId)) {
                    eligibleContactIds.add(contactId);
                    break;
                }
            }
        }
        System.debug('### eligibleContactIds: ' + eligibleContactIds);
        return eligibleContactIds;
    }

    private static Boolean hasEmailChanged(Contact oldC, Contact newC){
        String o = oldC == null || oldC.Email == null ? '' : oldC.Email.trim().toLowerCase();
        String n = newC == null || newC.Email == null ? '' : newC.Email.trim().toLowerCase();
        return o != n;
    }

    private static Boolean hasNameChanged(Contact oldC, Contact newC){
        String oFN = oldC == null || oldC.FirstName == null ? '' : oldC.FirstName.trim().toLowerCase();
        String nFN = newC == null || newC.FirstName == null ? '' : newC.FirstName.trim().toLowerCase();
        String oLN = oldC == null || oldC.LastName == null ? '' : oldC.LastName.trim().toLowerCase();
        String nLN = newC == null || newC.LastName == null ? '' : newC.LastName.trim().toLowerCase();
        return oFN != nFN || oLN != nLN;
    }
}