global class AccountReferralIdBatch implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Referral_Id__c 
            FROM Account 
            WHERE Referral_Id__c = null 
            AND IsActive = true
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        AccountGenerateReferralIdController.assignReferralIds(scope);
        update scope;
    }
    
    global void finish(Database.BatchableContext BC) {
        // Optional: send completion email or other cleanup
    }
}