global class ARC_DeleteCompletedOSInstancesJob implements Schedulable{
    global void execute(SchedulableContext sc) {
        runCleanup();
    }
 
    public static void runCleanup() {
        // Query all instances where status is '' or 'Completed'
        List<vlocity_ins__OmniScriptInstance__c> toDelete = [ 
            SELECT Id
            FROM vlocity_ins__OmniScriptInstance__c
            WHERE ARC_ResumeStatus__c = '' OR ARC_ResumeStatus__c = 'Completed'
        ]; 

        runCleanupTest(toDelete); 
    }
    
    public static void runCleanupTest(List<vlocity_ins__OmniScriptInstance__c> instancesToDelete) {
        // Delete them all
        if (!instancesToDelete.isEmpty()) {
            try {
                delete instancesToDelete;
            } catch (DmlException e) {
                System.debug('Failed to delete OmniScript Instances: ' + e.getMessage());
                //throw new AuraHandledException('Error processing member/contract changes.');
                String apexErrorEmail = System.Label.ARC_ApexErrorEmail; 
                String emailBody = 'Error in ARC_DeleteCompletedOSInstancesJob.cls: ' + e.getMessage() + 
                                    '\n\nStack Trace: ' + e.getStackTraceString();
                ARC_QueableSendFileBatch.sendEmailNotification(emailBody, 'ERROR in ARC_DeleteCompletedOSInstancesJob while deleting Completed OS Instances', apexErrorEmail);
                throw new AuraHandledException('Error processing ARC_DeleteCompletedOSInstancesJob'); 
            }
        }
    }
}