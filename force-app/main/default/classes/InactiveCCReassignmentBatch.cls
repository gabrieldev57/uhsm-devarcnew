global class InactiveCCReassignmentBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private Integer totalAccountsUpdated = 0;
    private Integer totalContractsUpdated = 0;
    private Integer totalErrors = 0;
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, AccountId, Status, Account.OwnerId, Account.Owner.IsActive, Account.Owner.Team__c ' +
            'FROM Contract ' +
            'WHERE (Status = \'Activated\' OR Status LIKE \'Awaiting%\') ' +
            'AND Account.Owner.Team__c = \'Client Coordinator\' ' +
            'AND Account.Owner.IsActive = false '+
            'AND RecordType.DeveloperName = \'ARC_IndividualAndFamily\''
        );
    }
    
    global void execute(Database.BatchableContext bc, List<Contract> scope) {
        // Group contracts by family account to ensure related contracts get same CC
        Map<Id, List<Contract>> contractsByFamily = new Map<Id, List<Contract>>();
        
        for (Contract c : scope) {
            if (!contractsByFamily.containsKey(c.AccountId)) {
                contractsByFamily.put(c.AccountId, new List<Contract>());
            }
            contractsByFamily.get(c.AccountId).add(c);
        }
        
        // Get related Contract Participants for all contracts at once
        Set<Id> allContractIds = new Set<Id>();
        for (Contract c : scope) {
            allContractIds.add(c.Id);
        }
        
        Map<Id, Set<Id>> contractToPersonAccounts = new Map<Id, Set<Id>>();
        for (ARC_ContractParticipant__c cp : [
            SELECT Id, ARC_PersonAccount__c, ARC_Contract__c 
            FROM ARC_ContractParticipant__c
            WHERE ARC_Contract__c IN :allContractIds
            AND ARC_PersonAccount__c != null
        ]) {
            if (!contractToPersonAccounts.containsKey(cp.ARC_Contract__c)) {
                contractToPersonAccounts.put(cp.ARC_Contract__c, new Set<Id>());
            }
            contractToPersonAccounts.get(cp.ARC_Contract__c).add(cp.ARC_PersonAccount__c);
        }
        
        // Build map of accounts to update (prevents duplicates)
        Map<Id, Account> accountsToUpdateMap = new Map<Id, Account>();
        List<Contract> contractsToUpdate = new List<Contract>();
        
        // Process each FAMILY (not each contract) separately for round robin
        // This ensures all contracts for the same family get the same CC
        for (Id familyAccountId : contractsByFamily.keySet()) {
            // Get next CC for this FAMILY
            User nextCC;
            try {
                nextCC = CCRoundRobinHelper.getNextRoundRobinUser();
            } catch (Exception e) {
                System.debug('Error getting next CC for Family Account ' + familyAccountId + ': ' + e.getMessage());
                totalErrors++;
                continue;
            }
            
            if (nextCC == null) {
                System.debug('No eligible CC found for Family Account: ' + familyAccountId);
                totalErrors++;
                continue;
            }
            
            // Update the family account
            accountsToUpdateMap.put(familyAccountId, new Account(Id = familyAccountId, OwnerId = nextCC.Id));
            
            // Process all contracts for this family
            List<Contract> familyContracts = contractsByFamily.get(familyAccountId);
            Set<Id> processedPersonAccounts = new Set<Id>(); // Track to avoid duplicates
            
            for (Contract c : familyContracts) {
                // Update contract
                contractsToUpdate.add(new Contract(Id = c.Id, OwnerId = nextCC.Id));
                
                // Update related person accounts
                if (contractToPersonAccounts.containsKey(c.Id)) {
                    for (Id paId : contractToPersonAccounts.get(c.Id)) {
                        if (!processedPersonAccounts.contains(paId)) {
                            accountsToUpdateMap.put(paId, new Account(Id = paId, OwnerId = nextCC.Id));
                            processedPersonAccounts.add(paId);
                        }
                    }
                }
            }
        }
        
        // Perform updates with error handling
        if (!accountsToUpdateMap.isEmpty()) {
            Database.SaveResult[] accountResults = Database.update(accountsToUpdateMap.values(), false);
            for (Database.SaveResult sr : accountResults) {
                if (sr.isSuccess()) {
                    totalAccountsUpdated++;
                } else {
                    totalErrors++;
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('Error updating Account ' + sr.getId() + ': ' + err.getMessage());
                    }
                }
            }
        }
        
        if (!contractsToUpdate.isEmpty()) {
            Database.SaveResult[] contractResults = Database.update(contractsToUpdate, false);
            for (Database.SaveResult sr : contractResults) {
                if (sr.isSuccess()) {
                    totalContractsUpdated++;
                } else {
                    totalErrors++;
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('Error updating Contract ' + sr.getId() + ': ' + err.getMessage());
                    }
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('=== Inactive CC Reassignment Batch Complete ===');
        System.debug('Total Accounts Updated: ' + totalAccountsUpdated);
        System.debug('Total Contracts Updated: ' + totalContractsUpdated);
        System.debug('Total Errors: ' + totalErrors);
        
        // Send email notification if there were errors
        if (totalErrors > 0) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{'integrations@uhsm.org'}); 
            mail.setSubject('Inactive CC Reassignment Batch - Errors Detected');
            mail.setPlainTextBody(
                'The Inactive CC Reassignment batch completed with errors:\n\n' +
                'Accounts Updated: ' + totalAccountsUpdated + '\n' +
                'Contracts Updated: ' + totalContractsUpdated + '\n' +
                'Errors: ' + totalErrors + '\n\n' +
                'Please check debug logs for details.'
            );
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        }
    }
}