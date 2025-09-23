global class ARC_CreateTermsForEveryone implements Database.Batchable<sObject>, Database.Stateful {
    private String strParameter;
    private Boolean approved;

    public ARC_CreateTermsForEveryone(String strParam, Boolean approveSMBs) {
        strParameter = strParam;
        approved = approveSMBs;
    }
        
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id FROM Claim WHERE ' + strParameter );
    }

    global void execute(Database.BatchableContext BC, List<Claim> scope){       

        for (Claim c : scope) {
            c.ARC_CheckrunApproval__c = approved ? 'Approved' : 'Pending';
        }

        update scope;
    }
    
    global void finish(Database.BatchableContext BC) {

    }
}