public with sharing class ARC_AbandonedStep implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    

    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, (SELECT Id FROM Vlocity_Tracking_Entries__r WHERE Name = \'OS Step Load\' ORDER BY CreatedDate DESC LIMIT 1) FROM Lead_Source__c WHERE Lead__r.Status = \'Self Enrolling\'');
    }
    public void execute(Database.BatchableContext BC, List<Lead_Source__c> leadSources) {
        for (Lead_Source__c leadSource : leadSources) {
            leadSource.ARC_LastStepEntry__c = leadSource.Vlocity_Tracking_Entries__r.isEmpty() ? null : leadSource.Vlocity_Tracking_Entries__r[0].Id;
        }
        update leadSources;
    }
    public void finish(Database.BatchableContext BC) {
        
    }


    @InvocableMethod(label='Update Abandoned Steps on Lead Sources' description='Update Abandoned Steps on Lead Sources' category='Lead Source')
    public static void execute(){
        Database.executeBatch(new ARC_AbandonedStep());
    }
}