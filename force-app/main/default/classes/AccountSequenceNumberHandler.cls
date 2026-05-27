/**
 * AccountSequenceNumberHandler
 *
 * Manages automatic assignment of ARC_HAXFamilySequenceNumber__c on Account records.
 * Triggered when accounts become active or when Member ID changes.
 *
 * Sequence Assignment Rules:
 * - Primary member: 01
 * - Spouse: 02
 * - Dependents: 03, 04, 05, etc. (incrementing from max used sequence)
 * - Sequence numbers persist across policy changes (same Member ID)
 * - Sequence numbers reset when Current_Member_Id__c changes (new family)
 */
public with sharing class AccountSequenceNumberHandler {

    /**
     * Before Update Handler - Clear sequence numbers when Member ID changes
     *
     * @param newAccounts Updated Account records
     * @param oldAccountsMap Old Account records by ID
     */
    public static void clearSequenceOnMemberIdChange(
        List<Account> newAccounts,
        Map<Id, Account> oldAccountsMap
    ) {
        List<Account> accountsToClear = new List<Account>();

        for (Account acc : newAccounts) {
            Account oldAcc = oldAccountsMap.get(acc.Id);

            // Check if Member ID changed
            if (acc.Current_Member_Id__c != oldAcc.Current_Member_Id__c) {
                acc.ARC_HAXFamilySequenceNumber__c = null;
            }
        }
    }

    /**
     * After Insert/Update Handler - Assign sequence numbers when needed
     *
     * Triggers on:
     * - Account becomes active (IsActive changes to true)
     * - Member ID changes (Current_Member_Id__c updated)
     *
     * Uses @future method to avoid timing issues with formula field evaluation
     *
     * @param newAccounts Updated/Inserted Account records
     * @param oldAccountsMap Old Account records by ID (null for inserts)
     */
    public static void assignSequenceNumbers(
        List<Account> newAccounts,
        Map<Id, Account> oldAccountsMap
    ) {
        Set<Id> accountIds = new Set<Id>();

        for (Account acc : newAccounts) {
            Boolean needsSequence = false;

            // Check if sequence is missing AND account is active with Member ID
            if (acc.ARC_HAXFamilySequenceNumber__c == null &&
                acc.IsActive == true &&
                acc.Current_Member_Id__c != null) {

                // For inserts - always assign if criteria met
                if (oldAccountsMap == null) {
                    needsSequence = true;
                }
                // For updates - check if IsActive or Member ID just changed
                else {
                    Account oldAcc = oldAccountsMap.get(acc.Id);
                    if (acc.IsActive != oldAcc.IsActive ||
                        acc.Current_Member_Id__c != oldAcc.Current_Member_Id__c) {
                        needsSequence = true;
                    }
                }
            }

            if (needsSequence) {
                accountIds.add(acc.Id);
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        System.debug('=== SEQUENCE ASSIGNMENT DEBUG ===');
        System.debug('Enqueuing ' + accountIds.size() + ' accounts for async sequence assignment');
        System.debug('AccountIds: ' + accountIds);

        // In batch/scheduled flow contexts, only 1 Queueable can be enqueued per execute() call.
        // The trigger fires twice in the scheduled flow (once for primary members, once for dependents),
        // so we run synchronously instead. Formula field timing is not a concern here because
        // the DML has already committed and formula fields recalculate at query time.
        if (System.isBatch() || System.isFuture()) {
            assignSequenceNumbersAsync(accountIds);
        } else {
            System.enqueueJob(new SequenceAssignmentJob(accountIds));
        }
    }

    /**
     * Queueable wrapper so sequence assignment can be enqueued from any context,
     * including batch and scheduled flows (which prohibit @future calls).
     */
    public class SequenceAssignmentJob implements Queueable {
        private Set<Id> accountIds;
        public SequenceAssignmentJob(Set<Id> accountIds) {
            this.accountIds = accountIds;
        }
        public void execute(QueueableContext ctx) {
            assignSequenceNumbersAsync(accountIds);
        }
    }

    /**
     * Async method to assign sequence numbers
     * Runs in separate transaction context to avoid timing issues with formula fields
     *
     * @param accountIds Set of Account IDs needing sequence assignment
     */
    public static void assignSequenceNumbersAsync(Set<Id> accountIds) {
        System.debug('=== ASYNC SEQUENCE ASSIGNMENT START ===');
        System.debug('Processing accountIds: ' + accountIds);

        // Re-query accounts in async context (fresh data with evaluated formula fields)
        List<Account> accountsNeedingSequence = [
            SELECT Id, Current_Member_Id__c, IsActive, PersonBirthdate,
                   ARC_HAXFamilySequenceNumber__c
            FROM Account
            WHERE Id IN :accountIds
            AND IsActive = true
            AND Current_Member_Id__c != null
            AND ARC_HAXFamilySequenceNumber__c = null
        ];

        System.debug('Re-queried ' + accountsNeedingSequence.size() + ' accounts still needing sequences');

        if (accountsNeedingSequence.isEmpty()) {
            System.debug('No accounts need sequence assignment (may have been assigned elsewhere)');
            return;
        }

        // Get roles from Coverage Participants (Primary, Spouse, Dependent)
        Map<Id, String> accountIdToRole = getAccountRoles(accountIds);
        System.debug('Roles found: ' + accountIdToRole);

        // Get max used sequences by Member ID
        Map<String, Integer> memberIdToMaxSequence = getMaxSequencesByMemberId(accountsNeedingSequence);

        // Sort accounts: Primary first, Spouse second, then Dependents by birthdate (oldest first)
        List<Account> sortedAccounts = new List<Account>(accountsNeedingSequence);
        sortedAccounts.sort(new AccountSequenceComparator(accountIdToRole));

        // Assign sequences
        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : sortedAccounts) {
            String role = accountIdToRole.get(acc.Id);
            System.debug('Processing Account ' + acc.Id + ' - Role found: ' + role);
            Integer sequenceNumber;

            if (role == 'Primary') {
                sequenceNumber = 1;
                System.debug('Assigning sequence 1 (Primary) to Account ' + acc.Id);
            } else if (role == 'Spouse') {
                sequenceNumber = 2;
                System.debug('Assigning sequence 2 (Spouse) to Account ' + acc.Id);
            } else if (role == 'Dependent') {
                // Get next available sequence (max + 1)
                Integer maxUsed = memberIdToMaxSequence.get(acc.Current_Member_Id__c);
                sequenceNumber = (maxUsed != null) ? maxUsed + 1 : 3;
                System.debug('Assigning sequence ' + sequenceNumber + ' (Dependent) to Account ' + acc.Id);
            } else {
                // No valid role found - skip assignment
                System.debug('WARNING: No coverage participant role found for Account ' + acc.Id);
                System.debug('WARNING: This account will be skipped. Check if Coverage Participant exists and meets query filters.');
                continue;
            }

            // Update the max sequence tracker for this Member ID (includes sequences assigned in this transaction)
            Integer currentMax = memberIdToMaxSequence.get(acc.Current_Member_Id__c);
            if (currentMax == null || sequenceNumber > currentMax) {
                memberIdToMaxSequence.put(acc.Current_Member_Id__c, sequenceNumber);
            }

            // Create new Account record for update
            Account accountToUpdate = new Account(
                Id = acc.Id,
                ARC_HAXFamilySequenceNumber__c = sequenceNumber
            );
            accountsToUpdate.add(accountToUpdate);
        }

        // Perform DML update if there are accounts to update
        System.debug('Total accounts to update: ' + accountsToUpdate.size());
        if (!accountsToUpdate.isEmpty()) {
            System.debug('Updating accounts with sequence numbers: ' + accountsToUpdate);
            update accountsToUpdate;
            System.debug('Async sequence assignment complete');
        } else {
            System.debug('No accounts to update - no roles were found');
        }
    }

    /**
     * Query Account roles from Coverage Participants
     * Filters to Medical coverage only with activated contracts
     * Note: ARC_isActive__c formula field filter moved to Apex to avoid SOQL timing issues
     *
     * @param accountIds Set of Account IDs to look up
     * @return Map of Account ID to coverage role (Primary/Spouse/Dependent)
     */
    private static Map<Id, String> getAccountRoles(Set<Id> accountIds) {
        Map<Id, String> accountIdToRole = new Map<Id, String>();

        System.debug('--- getAccountRoles() called with accountIds: ' + accountIds);

        // Query coverage participants with Medical coverage filters
        // NOTE: ARC_isActive__c filter removed from WHERE clause to avoid query optimizer timing issues
        List<ARC_CoverageParticipant__c> coverageParticipants = [
            SELECT ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId,
                   ARC_CoverageRole__c,
                   Id,
                   ARC_Policy__r.ARC_Contract__r.Status,
                   ARC_Policy__r.ARC_isActive__c,
                   ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c,
                   ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode
            FROM ARC_CoverageParticipant__c
            WHERE ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId IN :accountIds
            AND ARC_Policy__r.ARC_Contract__r.Status = 'Activated'
            AND ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c = 'Medical'
            AND ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode != 'PROG_WeShareLegacy'
            ORDER BY CreatedDate DESC
        ];

        System.debug('--- Query returned ' + coverageParticipants.size() + ' Coverage Participants (before isActive filter)');

        for (ARC_CoverageParticipant__c cp : coverageParticipants) {
            System.debug('--- Coverage Participant: ' + cp.Id);
            System.debug('    AccountId: ' + cp.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId);
            System.debug('    Role: ' + cp.ARC_CoverageRole__c);
            System.debug('    Contract Status: ' + cp.ARC_Policy__r.ARC_Contract__r.Status);
            System.debug('    Policy isActive: ' + cp.ARC_Policy__r.ARC_isActive__c);
            System.debug('    Product Type: ' + cp.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c);
            System.debug('    ProductCode: ' + cp.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode);

            // Filter by Policy isActive in Apex (instead of SOQL WHERE clause)
            if (cp.ARC_Policy__r.ARC_isActive__c != true) {
                System.debug('    FILTERED OUT: Policy isActive is false, skipping');
                continue;
            }

            Id acctId = cp.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId;
            // Only add if not already present (keeps the first/newest due to ORDER BY CreatedDate DESC)
            if (!accountIdToRole.containsKey(acctId)) {
                accountIdToRole.put(acctId, cp.ARC_CoverageRole__c);
                System.debug('    ADDED to accountIdToRole map');
            }
        }

        System.debug('--- Final accountIdToRole map: ' + accountIdToRole);
        return accountIdToRole;
    }

    /**
     * Find max used sequence number for each Member ID
     * This ensures new dependents don't reuse sequence numbers from former members
     *
     * @param accounts Accounts needing sequence assignment
     * @return Map of Member ID to max used sequence number
     */
    private static Map<String, Integer> getMaxSequencesByMemberId(List<Account> accounts) {
        Set<String> memberIds = new Set<String>();
        for (Account acc : accounts) {
            if (acc.Current_Member_Id__c != null) {
                memberIds.add(acc.Current_Member_Id__c);
            }
        }

        Map<String, Integer> memberIdToMaxSequence = new Map<String, Integer>();

        // Query all accounts with same Member IDs to find max sequence
        List<AggregateResult> results = [
            SELECT Current_Member_Id__c, MAX(ARC_HAXFamilySequenceNumber__c) maxSeq
            FROM Account
            WHERE Current_Member_Id__c IN :memberIds
            AND ARC_HAXFamilySequenceNumber__c != null
            GROUP BY Current_Member_Id__c
        ];

        for (AggregateResult ar : results) {
            String memberId = (String) ar.get('Current_Member_Id__c');
            Decimal maxSeq = (Decimal) ar.get('maxSeq');
            memberIdToMaxSequence.put(memberId, Integer.valueOf(maxSeq));
        }

        return memberIdToMaxSequence;
    }

    /**
     * Comparator to sort accounts for sequence assignment
     * Primary first, Spouse second, then Dependents sorted by birthdate (oldest first)
     */
    private class AccountSequenceComparator implements Comparator<Account> {
        Map<Id, String> accountIdToRole;

        public AccountSequenceComparator(Map<Id, String> roleMap) {
            this.accountIdToRole = roleMap;
        }

        public Integer compare(Account a1, Account a2) {
            String role1 = accountIdToRole.get(a1.Id);
            String role2 = accountIdToRole.get(a2.Id);

            // Assign priority: Primary=1, Spouse=2, Dependent=3, Unknown=4
            Integer priority1 = getRolePriority(role1);
            Integer priority2 = getRolePriority(role2);

            // First sort by role priority
            if (priority1 != priority2) {
                return priority1 - priority2;
            }

            // For same role (Dependents), sort by birthdate (oldest first)
            if (role1 == 'Dependent' && role2 == 'Dependent') {
                if (a1.PersonBirthdate != null && a2.PersonBirthdate != null) {
                    return a1.PersonBirthdate < a2.PersonBirthdate ? -1 :
                           (a1.PersonBirthdate > a2.PersonBirthdate ? 1 : 0);
                } else if (a1.PersonBirthdate != null) {
                    return -1; // a1 has birthdate, a2 doesn't - a1 comes first
                } else if (a2.PersonBirthdate != null) {
                    return 1; // a2 has birthdate, a1 doesn't - a2 comes first
                }
            }

            return 0; // Same role and no birthdate difference
        }

        private Integer getRolePriority(String role) {
            if (role == 'Primary') return 1;
            if (role == 'Spouse') return 2;
            if (role == 'Dependent') return 3;
            return 4; // Unknown role
        }
    }
}