global class ARC_CreateClaimFromInput implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT ARC_InputJSON__c, ARC_Type__c, ARC_ExternalId__c FROM ARC_ClaimInput__c WHERE ARC_Status__c = \'New\'';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<ARC_ClaimInput__c> scope){

        // CALL HELPER TO CREATE THE CLAIMS
        Set<Id> clmIds = ARC_PopulateClaimWithEDIHandler.createClaimFromInput(scope); // POPULATE CLAIM AND LINE ITEMS
        ARC_CheckForDuplicateClaimHandler.CheckForDuplicateClaim(new List<Id>(clmIds)); // DUPLICATE DETECTION
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(new List<Id>(clmIds)); // AUTOADJUDICATION

    }

    global void finish(Database.BatchableContext BC) {
        // SEND EMAIL NOTIFYING OF JOB COMPLETION
        // AsyncApexJob a = [SELECT Id, Status,TotalJobItems, JobItemsProcessed FROM AsyncApexJob WHERE Id =:BC.getJobId()];
        
        // if(a.TotalJobItems > 0){
        //     Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        //     String[] toAddresses = new String[] {'nahuel.moreno@arcsona.com'};
        //     mail.setToAddresses(toAddresses);
        //     mail.setSubject('New SMB\'s in the system');
        //     mail.setPlainTextBody('There are ' + a.JobItemsProcessed + ' new SMB\'s in the System');
        //     Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        // }
    }
    
    global void execute(SchedulableContext SC) {
        Database.executebatch(new ARC_CreateClaimFromInput(), 20);
    }
}