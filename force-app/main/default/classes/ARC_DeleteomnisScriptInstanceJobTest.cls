@isTest
private class ARC_DeleteomnisScriptInstanceJobTest {

    
    @TestSetup
    static void setupTestData() {
        // Create test OmniScript instances with different statuses
        List<vlocity_ins__OmniScriptInstance__c> testInstances = new List<vlocity_ins__OmniScriptInstance__c>();
        
        // Create instance with empty status
        testInstances.add(new vlocity_ins__OmniScriptInstance__c(
            ARC_ResumeStatus__c = ''
        ));
        
        // Create instance with Completed status
        testInstances.add(new vlocity_ins__OmniScriptInstance__c(
            ARC_ResumeStatus__c = 'Completed'
        ));
        
        // Create instance with different status (should not be deleted)
        testInstances.add(new vlocity_ins__OmniScriptInstance__c(
            ARC_ResumeStatus__c = 'Resume'
        ));
        
        insert testInstances;
    }
    
    @isTest
    static void testSuccessfulDeletion() {
        // Verify initial count
        Integer initialCount = [SELECT COUNT() FROM vlocity_ins__OmniScriptInstance__c];
        System.assertEquals(3, initialCount, 'Should have 3 test records initially');
        
        Test.startTest();
        aRC_DeleteOmniScriptInstancesJob.runCleanup();
        Test.stopTest();
        
        // Verify only records with empty or Completed status were deleted
        Integer remainingCount = [SELECT COUNT() FROM vlocity_ins__OmniScriptInstance__c];
        System.assertEquals(1, remainingCount, 'Should have 1 record remaining');
        
        // Verify the remaining record has 'Resume' status
        vlocity_ins__OmniScriptInstance__c remainingInstance = [
            SELECT ARC_ResumeStatus__c 
            FROM vlocity_ins__OmniScriptInstance__c 
            LIMIT 1
        ];
        System.assertEquals('Resume', remainingInstance.ARC_ResumeStatus__c, 
            'Remaining record should have Resume status');
    }
    
    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        aRC_DeleteOmniScriptInstancesJob job = new aRC_DeleteOmniScriptInstancesJob();
        job.execute(null);
        Test.stopTest();
        
        // Verify execution through schedulable interface
        Integer remainingCount = [SELECT COUNT() FROM vlocity_ins__OmniScriptInstance__c];
        System.assertEquals(1, remainingCount, 'Should have 1 record remaining after schedulable execution');
    }
    
    @isTest
    static void testErrorHandling() {
        // Create a test instance
        vlocity_ins__OmniScriptInstance__c testInstance = new vlocity_ins__OmniScriptInstance__c(
            ARC_ResumeStatus__c = 'Completed'
        );
        insert testInstance;
        
        Test.startTest();
        try {
            // First delete the record
            delete testInstance;
            
            // Then try to delete it again through runCleanupTest
            aRC_DeleteOmniScriptInstancesJob.runCleanupTest(new List<vlocity_ins__OmniScriptInstance__c>{testInstance});
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(),
                'Should throw AuraHandledException with exact message');
        }
        Test.stopTest();
    } 
}