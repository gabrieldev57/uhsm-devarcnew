public with sharing class ARC_DeleteCompletedOSInstancesJob
    implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM vlocity_ins__OmniScriptInstance__c
            WHERE ARC_ResumeStatus__c = 'Completed'
        ]);
    }

    public void execute(Database.BatchableContext bc, List<vlocity_ins__OmniScriptInstance__c> scope) {
        if (!scope.isEmpty()) {
            Database.delete(scope, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('ARC_DeleteCompletedOSInstancesJob completed successfully.');
    }

    @InvocableMethod(
        label='Run ARC Delete Completed OS Instances Batch'
        description='Runs the batch that deletes OmniScript Instances with ARC_ResumeStatus__c = "Completed".'
    )
    public static void runBatch() {
        ARC_DeleteCompletedOSInstancesJob job = new ARC_DeleteCompletedOSInstancesJob();
        Database.executeBatch(new ARC_DeleteCompletedOSInstancesJob(), 200);
    }
}