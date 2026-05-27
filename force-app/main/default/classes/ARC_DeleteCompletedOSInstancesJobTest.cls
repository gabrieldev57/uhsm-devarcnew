@IsTest
public class ARC_DeleteCompletedOSInstancesJobTest {
    
    @TestSetup
    static void setupTestData() {
        List<vlocity_ins__OmniScriptInstance__c> testInstances = new List<vlocity_ins__OmniScriptInstance__c>();

        // Instance with empty status
        testInstances.add(new vlocity_ins__OmniScriptInstance__c(
            ARC_ResumeStatus__c = ''
        ));

        // Instance with null status
        testInstances.add(new vlocity_ins__OmniScriptInstance__c(
            ARC_ResumeStatus__c = null
        ));

        // Instance with Completed status (this one should be deleted)
        testInstances.add(new vlocity_ins__OmniScriptInstance__c(
            ARC_ResumeStatus__c = 'Completed'
        ));

        // Instance with Resume status (this one should remain)
        testInstances.add(new vlocity_ins__OmniScriptInstance__c(
            ARC_ResumeStatus__c = 'Resume'
        ));

        insert testInstances;
    }

    @IsTest
    static void testBatchExecution() {

        Test.startTest();
        ARC_DeleteCompletedOSInstancesJob.runBatch();
        Test.stopTest();
        
        List<vlocity_ins__OmniScriptInstance__c> remainingInstances = [
            SELECT Id, ARC_ResumeStatus__c
            FROM vlocity_ins__OmniScriptInstance__c
            ORDER BY ARC_ResumeStatus__c NULLS FIRST
        ];

        System.assertEquals(
            3, 
            remainingInstances.size(), 
            'Only the instance with status Completed should be deleted.'
        );

        for (vlocity_ins__OmniScriptInstance__c inst : remainingInstances) {
            System.assertNotEquals(
                'Completed', 
                inst.ARC_ResumeStatus__c, 
                'No instance with status Completed should remain.'
            );
        }
    }
}