public class ARC_CaseContactIdBackfillBatch implements Database.Batchable<SObject> {

    private Set<Id> caseIds;
    
    public ARC_CaseContactIdBackfillBatch(Set<Id> caseIds) {
        this.caseIds = caseIds;
    }

    public ARC_CaseContactIdBackfillBatch() {
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (caseIds != null && !caseIds.isEmpty()) {
            System.debug(caseIds);
            String query = 'SELECT Id, ARC_PersonAccount__c, ARC_PersonAccount__r.PersonContactId, ContactId, AccountId, ARC_PersonAccount__r.RecordType.DeveloperName ' +
                           'FROM Case WHERE Id IN :caseIds';
            return Database.getQueryLocator(query);
        } else {
            System.debug('No caseIds');
            String query = 'SELECT Id, ARC_PersonAccount__c, ARC_PersonAccount__r.PersonContactId, ContactId, AccountId, ARC_PersonAccount__r.RecordType.DeveloperName ' +
                           'FROM Case WHERE isClosed = false ' +
                           'AND ContactId = null AND (ARC_PersonAccount__c != null OR AccountId != null)';
            return Database.getQueryLocator(query);
        }
    }
    
    public void execute(Database.BatchableContext bc, List<Case> scope) {
        List<Case> casesToUpdate = new List<Case>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        
        for (Case c : scope) {
            if (c.ARC_PersonAccount__c == null && c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }

        List<Account> personAccounts = [SELECT Id, ARC_GroupAccount__c, PersonContactId FROM Account WHERE ((ARC_IsPrimaryMember__c = true) AND (ARC_GroupAccount__c IN :accountIds)) OR (((RecordType.DeveloperName = 'ARC_IFPPersonAccount') OR (RecordType.DeveloperName = 'ARC_Guardian')) AND (Id IN :accountIds))];
        Map<Id, Account> personAccountsMap = new Map<Id, Account>();
        for (Account acc : personAccounts) {
            if (acc.ARC_GroupAccount__c != null) {
                personAccountsMap.put(acc.ARC_GroupAccount__c, acc);
            } else {
                personAccountsMap.put(acc.Id, acc);
            }
            
        }

        for (Case c : scope) {
            if (c.ARC_PersonAccount__c != null && c.ARC_PersonAccount__r.PersonContactId != null && c.ARC_PersonAccount__r.RecordType.DeveloperName == 'ARC_IFPPersonAccount') {
                c.ContactId = c.ARC_PersonAccount__r.PersonContactId;
                casesToUpdate.add(c);
            } else if (c.AccountId != null && c.ARC_PersonAccount__c == null) {
                Account primaryAccount = personAccountsMap.get(c.AccountId);
                if (primaryAccount != null && primaryAccount.PersonContactId != null) {
                    c.ContactId = primaryAccount.PersonContactId;
                    casesToUpdate.add(c);
                }
            }
        }
        
        if (!casesToUpdate.isEmpty()) {
            try {
                update casesToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating cases: ' + e.getMessage());
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
    }
}