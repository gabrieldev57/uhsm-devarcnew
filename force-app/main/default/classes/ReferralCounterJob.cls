public with sharing class ReferralCounterJob {

    public static void run(){
        // Calculate the dates: 
        Date today = Date.today();
        Date plusThirtyDays = today.addDays(-30); 
    
        List<Contract> contractList = [SELECT Id, ARC_EffectiveDate__c, ARC_ContractReason__c, AccountId
        FROM Contract WHERE ARC_ContractReason__c = 'New Application' AND ARC_EffectiveDate__c = :plusThirtyDays]; 

        Map<Id, Contract> accountContractMap = new Map<Id, Contract>();

        // Get account Ids
        Set<Id> accounts = new Set<Id>(); 

        for (Contract c : contractList){
                accountContractMap.put(c.AccountId, c); 
                accounts.add(c.AccountId);
        }
        // Get only family accounts
        Map<Id, Account> familyAccountsOnly = new Map<Id, Account>([SELECT Id, RecordType.DeveloperName FROM Account WHERE Id IN :accounts and RecordType.DeveloperName = 'Group']); 

        // Get lead sources for those accounts: 

        List<Lead_Source__c> lsToUpdates = new List<Lead_Source__c>();

        List<Lead_Source__c> leadSources = [SELECT Id, ARC_GroupAccount__c, Referrer_Account__c, CreatedDate, IncludeInReferralDLRSCount__c FROM Lead_Source__c WHERE ARC_GroupAccount__c IN :familyAccountsOnly.keySet()];
        for (Lead_Source__c l : leadSources){

            System.debug('referrer: ' + l.Referrer_Account__c);
            System.debug('include in DLRS: ' + l.IncludeInReferralDLRSCount__c);
            
            if (l.Referrer_Account__c != null || l.IncludeInReferralDLRSCount__c == true) continue; 
            
             Contract contractFromLS = accountContractMap.get(l.ARC_GroupAccount__c);

            // 30 days rule: 

            Date effectiveDateOnContract = contractFromLS.ARC_EffectiveDate__c;
            Date createdDate = l.CreatedDate.date();
            if (createdDate <= effectiveDateOnContract.addDays(30)){
                l.IncludeInReferralDLRSCount__c = true; //mark checkbox for DLRS to recalculate
                lsToUpdates.add(l);
            } 

        }

        if (lsToUpdates.size() > 0) {
            update lsToUpdates;
        }

    }
    
}