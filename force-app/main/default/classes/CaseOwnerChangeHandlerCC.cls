public class CaseOwnerChangeHandlerCC {
    
    @TestVisible 
    private static Id primaryAccOwnerId;
    
    // Track which case IDs we've already processed to prevent recursion
    private static Set<Id> processedCaseIds = new Set<Id>();

    public static void updateCaseOwnerToAnotherCC(Map<Id, Case> oldMap, Map<Id, Case> newMap){
        
        List<Case> cases = new List<Case>();
        Set<Id> newOwners = new Set<Id>();
        Set<Id> oldOwners = new Set<Id>();
        Set<Id> caseIdsToMap = new Set<Id>();
 
        // Get Cases that got updated AND haven't been processed yet
        for (Id caseId : newMap.keySet()){
            // Skip if already processed in this transaction
            if (processedCaseIds.contains(caseId)) continue;
            
            if(newMap.get(caseId).OwnerId != oldMap.get(caseId).OwnerId && 
               newMap.get(caseId).OwnerId != null){
                oldOwners.add(oldMap.get(caseId).OwnerId);
                newOwners.add(newMap.get(caseId).OwnerId);
                caseIdsToMap.add(caseId);
                cases.add(newMap.get(caseId));
                
                // Mark as processed
                processedCaseIds.add(caseId);
            }
        }
 
        if (cases.isEmpty()) return;
 
        // Get onboarding recordtype and filter by RT
        Map<Id, Case> onboardingCases = new Map<Id, Case>([
            SELECT Id, OwnerId, RecordType.DeveloperName 
            FROM Case 
            WHERE Id IN :caseIdsToMap 
            AND RecordType.DeveloperName = 'Onboarding'
        ]);
 
        if (onboardingCases.isEmpty()) return;
 
        // Check if old/new owners are CC
        Map<Id, User> usersToQuery = new Map<Id, User>([
            SELECT Id, Team__c, FirstName, LastName 
            FROM User 
            WHERE Id IN :oldOwners OR Id IN :newOwners
        ]);
 
        // Filter out CC users and onboarding cases
        List<Case> casesToUpdate = new List<Case>();
 
        for (Case c : cases){
            if (onboardingCases.containsKey(c.Id)){
                User oldOwner = usersToQuery.get(oldMap.get(c.Id).OwnerId);
                User newOwner = usersToQuery.get(newMap.get(c.Id).OwnerId);
                
                if (oldOwner != null && newOwner != null && 
                    oldOwner.Team__c == 'Client Coordinator' && 
                    newOwner.Team__c == 'Client Coordinator'){
                    casesToUpdate.add(c);
                }
            }
        }
 
        if (!casesToUpdate.isEmpty()){
            updateAccountOwnership(casesToUpdate);
        }
    }
    
    private static void updateAccountOwnership(List<Case> ccCases){
        if (ccCases.isEmpty()) return;
        
        // Collect accounts and their new owners
        Map<Id, Id> accountToNewOwner = new Map<Id, Id>(); // AccountId → New OwnerId
        
        for (Case c : ccCases){
            if (c.AccountId != null){
                accountToNewOwner.put(c.AccountId, c.OwnerId);
            }
        }
        
        if (accountToNewOwner.isEmpty()) return;
        
        // Get contracts for these specific accounts
        Map<Id, List<Contract>> contractsByAccount = new Map<Id, List<Contract>>();
        for (Contract co : [
            SELECT Id, AccountId, Status 
            FROM Contract 
            WHERE AccountId IN :accountToNewOwner.keySet()
            AND Status NOT IN ('Voided','Terminated')
        ]){
            if (!contractsByAccount.containsKey(co.AccountId)){
                contractsByAccount.put(co.AccountId, new List<Contract>());
            }
            contractsByAccount.get(co.AccountId).add(co);
        }
        
        // Collect all contract IDs
        Set<Id> allContractIds = new Set<Id>();
        for (List<Contract> contracts : contractsByAccount.values()){
            for (Contract c : contracts){
                allContractIds.add(c.Id);
            }
        }
        
        // Get participants organized by contract
        Map<Id, List<ARC_ContractParticipant__c>> participantsByContract = new Map<Id, List<ARC_ContractParticipant__c>>();
        for (ARC_ContractParticipant__c p : [
            SELECT Id, ARC_PersonAccount__c, ARC_Contract__c, ARC_Contract__r.AccountId
            FROM ARC_ContractParticipant__c 
            WHERE ARC_Contract__c IN :allContractIds
            AND ARC_PersonAccount__c != null
        ]){
            if (!participantsByContract.containsKey(p.ARC_Contract__c)){
                participantsByContract.put(p.ARC_Contract__c, new List<ARC_ContractParticipant__c>());
            }
            participantsByContract.get(p.ARC_Contract__c).add(p);
        }
        
        // Build accounts to update
        List<Account> accsToUpd = new List<Account>();
        Set<Id> processedAccountIds = new Set<Id>();
        
        // Process each family account that needs updating
        for (Id familyAccountId : accountToNewOwner.keySet()){
            Id newOwnerId = accountToNewOwner.get(familyAccountId);
            
            // Update the family account itself
            if (!processedAccountIds.contains(familyAccountId)){
                accsToUpd.add(new Account(Id = familyAccountId, OwnerId = newOwnerId));
                processedAccountIds.add(familyAccountId);
            }
            
            // Update person accounts from this family's contracts
            if (contractsByAccount.containsKey(familyAccountId)){
                for (Contract contract : contractsByAccount.get(familyAccountId)){
                    if (participantsByContract.containsKey(contract.Id)){
                        for (ARC_ContractParticipant__c p : participantsByContract.get(contract.Id)){
                            if (p.ARC_PersonAccount__c != null && 
                                !processedAccountIds.contains(p.ARC_PersonAccount__c)){
                                accsToUpd.add(new Account(Id = p.ARC_PersonAccount__c, OwnerId = newOwnerId));
                                processedAccountIds.add(p.ARC_PersonAccount__c);
                            }
                        }
                    }
                }
            }
        }
        
        if (!accsToUpd.isEmpty()){
            System.debug('Accounts to update CC for: ' + accsToUpd.size());
            update accsToUpd;
        }
    }
 
    private static Set<Id> processedUWCaseIds = new Set<Id>();
    
    public static void updateAccountOwnershipWhenUWCaseIsApproved(Map<Id, Case> oldMap, Map<Id, Case> newMap){
        
        List<Case> casesForUpd = new List<Case>();
        Id underWritingRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admission').getRecordTypeId();
        Set<Id> contractIds = new Set<Id>();
        
        for (Id caseId : newMap.keySet()){
            // Skip if already processed
            if (processedUWCaseIds.contains(caseId)) continue;
            
            Case newCase = newMap.get(caseId);
            Case oldCase = oldMap.get(caseId);
            
            if (newCase.RecordTypeId == underWritingRTId && 
                newCase.Status == 'Closed Approved' && 
                newCase.Status != oldCase.Status &&
                newCase.ARC_Contract__c != null){
                contractIds.add(newCase.ARC_Contract__c);
                casesForUpd.add(newCase);
                
                // Mark as processed
                processedUWCaseIds.add(caseId);
            }
        }
        
        if (casesForUpd.isEmpty()) return;
        
        // Filter out cases where selling agents are already CCs
        Map<Id, Contract> contractMap = new Map<Id, Contract>([
            SELECT Id, ARC_Selling_Agent__c, ARC_Selling_Agent__r.Team__c 
            FROM Contract 
            WHERE Id IN :contractIds
        ]);
        
        List<Case> finalCasesForUpd = new List<Case>();
        
        for (Case uwCase : casesForUpd){
            Contract con = contractMap.get(uwCase.ARC_Contract__c);
            if (con != null){
                // Skip if no selling agent
                if (con.ARC_Selling_Agent__c == null){
                    System.debug('Skipping contract ' + con.Id + ' - no selling agent assigned');
                    continue;
                }
                
                // Only process if selling agent is not a CC
                if (con.ARC_Selling_Agent__r.Team__c != 'Client Coordinator'){
                    finalCasesForUpd.add(uwCase);
                }
            }
        }
        
        if (!finalCasesForUpd.isEmpty()){
            System.debug('Called RR assignment');
            handleAssignmentsViaRoundRobin(finalCasesForUpd);
        }
    }

    private static void handleAssignmentsViaRoundRobin(List<Case> cases){
        Set<Id> contractIds = new Set<Id>(); 
    
        for (Case c : cases){
            if (c.ARC_Contract__c != null){
                contractIds.add(c.ARC_Contract__c);
            }
        }
        
        if (contractIds.isEmpty()) return;
        
        // LIMIT enforcement with graceful degradation
        final Integer MAX_CONTRACTS = 30;
        List<Id> contractIdList = new List<Id>(contractIds);
        Set<Id> processableContracts = new Set<Id>();
        List<Id> skippedContracts = new List<Id>();
        
        if (contractIdList.size() > MAX_CONTRACTS){
            System.debug(LoggingLevel.WARN, 
                'WARNING: ' + contractIdList.size() + ' contracts requested, but can only process ' + 
                MAX_CONTRACTS + ' due to governor limits. Remaining contracts will be skipped.');
            
            // Take first 30 contracts
            for (Integer i = 0; i < MAX_CONTRACTS; i++){
                processableContracts.add(contractIdList[i]);
            }
            
            // Track skipped contracts
            for (Integer i = MAX_CONTRACTS; i < contractIdList.size(); i++){
                skippedContracts.add(contractIdList[i]);
            }
            
            // Optional: Send email notification about skipped contracts
            notifyAdminAboutSkippedContracts(skippedContracts);
        } else {
            processableContracts = contractIds;
        }
        
        // Continue with limited set
        contractIds = processableContracts;
        
        // Get contracts and participants in one query each
        Map<Id, Contract> contractsWithFamilyAccounts = new Map<Id, Contract>([
            SELECT Id, AccountId, Status 
            FROM Contract 
            WHERE Id IN :contractIds 
            AND Status NOT IN ('Voided','Terminated')
        ]); 

        Map<Id, List<ARC_ContractParticipant__c>> contractParticipants = new Map<Id, List<ARC_ContractParticipant__c>>(); 
        
        for (ARC_ContractParticipant__c p : [
            SELECT Id, ARC_PersonAccount__c, ARC_Contract__c 
            FROM ARC_ContractParticipant__c 
            WHERE ARC_Contract__c IN :contractIds
        ]){
            if (!contractParticipants.containsKey(p.ARC_Contract__c)){
                contractParticipants.put(p.ARC_Contract__c, new List<ARC_ContractParticipant__c>());
            }
            contractParticipants.get(p.ARC_Contract__c).add(p); 
        }
        
        List<Account> accountsToUpdate = new List<Account>(); 
        Map<Id, List<Account>> accountsByOwner = new Map<Id, List<Account>>(); 
        Set<Id> ownerIds = new Set<Id>();

        // Iterate over contracts and assign via round robin
        for (Id contractId : contractIds){
            User nextUser = CCRoundRobinHelper.getNextRoundRobinUser(); 
            
            if (nextUser == null) continue;
            
            if (Test.isRunningTest()){
                primaryAccOwnerId = nextUser.Id; 
            }
            
            ownerIds.add(nextUser.Id);
            
            if (!accountsByOwner.containsKey(nextUser.Id)){
                accountsByOwner.put(nextUser.Id, new List<Account>());
            }
            
            // Family accounts
            Contract co = contractsWithFamilyAccounts.get(contractId); 
            if (co != null && co.AccountId != null){
                Account acc = new Account(Id = co.AccountId, OwnerId = nextUser.Id); 
                accountsToUpdate.add(acc); 
                accountsByOwner.get(nextUser.Id).add(acc); 
            }
            
            // Person accounts
            if (contractParticipants.containsKey(contractId)){
                for (ARC_ContractParticipant__c p : contractParticipants.get(contractId)){
                    if (p.ARC_PersonAccount__c != null){
                        Account acc = new Account(Id = p.ARC_PersonAccount__c, OwnerId = nextUser.Id); 
                        accountsToUpdate.add(acc); 
                        accountsByOwner.get(nextUser.Id).add(acc); 
                    }
                }
            }
        }
        
        if (!accountsToUpdate.isEmpty()){
            update accountsToUpdate; 
            
            // Query all users once, outside the loop
            Map<Id, User> ccUsers = new Map<Id, User>([
                SELECT Id, Name 
                FROM User 
                WHERE Id IN :ownerIds
            ]);
            
            // Query all accounts once with necessary fields
            Map<Id, Account> accountMap = new Map<Id, Account>([
                SELECT Id, Name, IsPersonAccount, PersonContactId, 
                       PersonContact.FirstName, PersonContact.LastName 
                FROM Account 
                WHERE Id IN :accountsToUpdate
            ]);
            
            // Send notifications
            for (Id ownerId : accountsByOwner.keySet()){
                User ccUser = ccUsers.get(ownerId);
                List<Account> ownerAccounts = accountsByOwner.get(ownerId);
                
                // Get full account objects
                List<Account> fullAccounts = new List<Account>();
                for (Account acc : ownerAccounts){
                    if (accountMap.containsKey(acc.Id)){
                        fullAccounts.add(accountMap.get(acc.Id));
                    }
                }
                
                if (ccUser != null && !fullAccounts.isEmpty()){
                    sendNotificationToCaseOwner(ccUser, fullAccounts); 
                }
            }
        }
    }

    // Accepts full Account objects and batch notifications
    public static void sendNotificationToCaseOwner(User ccUser, List<Account> accounts){
        if (ccUser == null || accounts == null || accounts.isEmpty()) return;
        
        List<CustomNotificationType> notifTypes = [
            SELECT Id 
            FROM CustomNotificationType 
            WHERE DeveloperName = 'CC_Account_Assignment' 
            LIMIT 1
        ];
        
        if (notifTypes.isEmpty()){
            System.debug('CustomNotificationType CC_Account_Assignment not found. Skipping notification.');
            return;
        }
        
        Id notificationType = notifTypes[0].Id;
        
        // Send one summary notification (better UX for bulk assignments)
        if (accounts.size() == 1){
            // Single account - specific notification
            Account acc = accounts[0];
            String accountName = acc.IsPersonAccount ? 
                acc.PersonContact.FirstName + ' ' + acc.PersonContact.LastName : 
                acc.Name;
            
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTargetId(acc.Id);
            notification.setTitle('New Account Assigned');
            notification.setBody('You have been assigned as an owner for account: ' + accountName);
            notification.setNotificationTypeId(notificationType);
            notification.send(new Set<String>{ccUser.Id});
        } else {
            // Multiple accounts - summary notification
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTargetId(accounts[0].Id); // Link to first account
            notification.setTitle('New Accounts Assigned');
            notification.setBody('You have been assigned as an owner for ' + accounts.size() + ' accounts');
            notification.setNotificationTypeId(notificationType);
            notification.send(new Set<String>{ccUser.Id});
        }
    }
    
    public class HandlerException extends Exception {}
    
    private static void notifyAdminAboutSkippedContracts(List<Id> skippedContracts){
        if (skippedContracts.isEmpty()) return;
        
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{'integrations@uhsm.org'});
            mail.setSubject('Round Robin Assignment - Contracts Skipped Due to Governor Limits');
            mail.setPlainTextBody(
                'The following ' + skippedContracts.size() + ' contracts were skipped due to ' +
                'governor limit constraints during UW case approval:\n\n' +
                'Contract IDs:\n' + String.join(skippedContracts, '\n') + '\n\n' +
                'These contracts will need to be processed manually or via scheduled batch job.\n' +
                'Please review and take appropriate action.'
            );
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to send notification email: ' + e.getMessage());
        }
    }
    
    @TestVisible
    public static void resetTestState() {
        processedCaseIds.clear();
        processedUWCaseIds.clear();
    }
}