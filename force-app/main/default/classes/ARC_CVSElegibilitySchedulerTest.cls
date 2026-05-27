@isTest
public class ARC_CVSElegibilitySchedulerTest {
    
    @isTest
    static void testDefaultConstructor() {
        Test.startTest();
        
        ARC_CVSElegibilityScheduler scheduler = new ARC_CVSElegibilityScheduler();
        
        // Should not throw exception
        System.assertNotEquals(null, scheduler, 'Scheduler should be instantiated');
        
        Test.stopTest();
    }
    
    @isTest
    static void testCustomConstructor() {
        Test.startTest();
        
        ARC_CVSElegibilityScheduler scheduler = new ARC_CVSElegibilityScheduler(20, 1000, true);
        
        // Should not throw exception
        System.assertNotEquals(null, scheduler, 'Scheduler should be instantiated with custom params');
        
        Test.stopTest();
    }
    
    @isTest
    static void testScheduleJobExecution() {
        Test.startTest();
        
        // Create scheduler instance
        ARC_CVSElegibilityScheduler scheduler = new ARC_CVSElegibilityScheduler();
        
        // Schedule the job
        String cronExp = '0 0 2 * * ?'; // Daily at 2 AM
        String jobId = System.schedule('CVS Eligibility Test Job', cronExp, scheduler);
        
        // Verify job was scheduled
        System.assertNotEquals(null, jobId, 'Job ID should not be null');
        
        // Get scheduled job details
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger WHERE Id = :jobId];
        
        System.assertEquals(cronExp, ct.CronExpression, 'Cron expression should match');
        System.assertEquals(0, ct.TimesTriggered, 'Should not have triggered yet');
        
        Test.stopTest();
    }
    
    @isTest
    static void testExecuteMethodWithDefaultSettings() {
        Test.startTest();
        
        ARC_CVSElegibilityScheduler scheduler = new ARC_CVSElegibilityScheduler();
        
        // Schedule and execute
        String cronExp = '0 0 2 * * ?';
        String jobId = System.schedule('CVS Test Default', cronExp, scheduler);
        
        // Verify batch was queued (check AsyncApexJob)
        // Note: In test context, batch won't actually execute, but we can verify it was enqueued
        
        Test.stopTest();
        
        // Verify batch job was created
        List<AsyncApexJob> jobs = [SELECT Id, Status, ApexClass.Name 
                                   FROM AsyncApexJob 
                                   WHERE ApexClass.Name = 'ARC_CVSElegibilityFileBatchPOC' 
                                   AND JobType = 'BatchApex'];
        
        System.assert(jobs.size() > 0, 'Batch job should be created');
    }
    
    @isTest
    static void testExecuteMethodWithCustomSettings() {
        Test.startTest();
        
        // Custom settings: smaller batch, send to test sites
        ARC_CVSElegibilityScheduler scheduler = new ARC_CVSElegibilityScheduler(5, 100, true);
        
        String cronExp = '0 0 3 * * ?';
        String jobId = System.schedule('CVS Test Custom', cronExp, scheduler);
        
        Test.stopTest();
        
        // Verify batch job was created
        List<AsyncApexJob> jobs = [SELECT Id, Status, ApexClass.Name 
                                   FROM AsyncApexJob 
                                   WHERE ApexClass.Name = 'ARC_CVSElegibilityFileBatchPOC' 
                                   AND JobType = 'BatchApex'];
        
        System.assert(jobs.size() > 0, 'Batch job with custom settings should be created');
    }
    
    @isTest
    static void testScheduleMultipleJobs() {
        Test.startTest();
        
        // Schedule multiple jobs with different settings
        ARC_CVSElegibilityScheduler scheduler1 = new ARC_CVSElegibilityScheduler(10, 500, false);
        ARC_CVSElegibilityScheduler scheduler2 = new ARC_CVSElegibilityScheduler(20, 1000, true);
        
        String jobId1 = System.schedule('CVS Job 1', '0 0 2 * * ?', scheduler1);
        String jobId2 = System.schedule('CVS Job 2', '0 0 14 * * ?', scheduler2);
        
        System.assertNotEquals(null, jobId1, 'First job should be scheduled');
        System.assertNotEquals(null, jobId2, 'Second job should be scheduled');
        System.assertNotEquals(jobId1, jobId2, 'Job IDs should be different');
        
        Test.stopTest();
        
        // Verify both jobs exist
        List<CronTrigger> jobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger 
                                  WHERE Id IN (:jobId1, :jobId2)];
        
        System.assertEquals(2, jobs.size(), 'Both jobs should be scheduled');
    }
    
    @isTest
    static void testScheduleAndAbort() {
        Test.startTest();
        
        ARC_CVSElegibilityScheduler scheduler = new ARC_CVSElegibilityScheduler();
        String jobId = System.schedule('CVS Test Abort', '0 0 2 * * ?', scheduler);
        
        // Abort the scheduled job
        System.abortJob(jobId);
        
        Test.stopTest();
        
        // Verify job was aborted
        List<CronTrigger> jobs = [SELECT Id, State FROM CronTrigger WHERE Id = :jobId];
        
        if (!jobs.isEmpty()) {
            System.assertEquals('DELETED', jobs[0].State, 'Job should be in DELETED state');
        }
    }
    
    @isTest
    static void testSchedulerWithDifferentCronExpressions() {
        Test.startTest();
        
        ARC_CVSElegibilityScheduler scheduler = new ARC_CVSElegibilityScheduler();
        
        // Test various cron expressions
        String dailyJobId = System.schedule('Daily', '0 0 2 * * ?', new ARC_CVSElegibilityScheduler());
        String weeklyJobId = System.schedule('Weekly', '0 0 6 ? * MON', new ARC_CVSElegibilityScheduler());
        String weekdaysJobId = System.schedule('Weekdays', '0 0 3 ? * MON-FRI', new ARC_CVSElegibilityScheduler());
        
        System.assertNotEquals(null, dailyJobId, 'Daily job should be scheduled');
        System.assertNotEquals(null, weeklyJobId, 'Weekly job should be scheduled');
        System.assertNotEquals(null, weekdaysJobId, 'Weekdays job should be scheduled');
        
        Test.stopTest();
    }
    
    @isTest
    static void testSchedulerCoverage() {
        // This test ensures we hit all branches and achieve >75% coverage
        Test.startTest();
        
        // Test all constructor variations
        ARC_CVSElegibilityScheduler scheduler1 = new ARC_CVSElegibilityScheduler();
        ARC_CVSElegibilityScheduler scheduler2 = new ARC_CVSElegibilityScheduler(15, 750, false);
        ARC_CVSElegibilityScheduler scheduler3 = new ARC_CVSElegibilityScheduler(5, 250, true);
        
        // Schedule with different settings
        String jobId1 = System.schedule('Coverage Test 1', '0 0 1 * * ?', scheduler1);
        String jobId2 = System.schedule('Coverage Test 2', '0 0 2 * * ?', scheduler2);
        String jobId3 = System.schedule('Coverage Test 3', '0 0 3 * * ?', scheduler3);
        
        System.assertNotEquals(null, jobId1, 'Job 1 should be scheduled');
        System.assertNotEquals(null, jobId2, 'Job 2 should be scheduled');
        System.assertNotEquals(null, jobId3, 'Job 3 should be scheduled');
        
        Test.stopTest();
        
        // Verify batch jobs were created for all scheduled executions
        List<AsyncApexJob> batchJobs = [SELECT Id, ApexClass.Name 
                                        FROM AsyncApexJob 
                                        WHERE ApexClass.Name = 'ARC_CVSElegibilityFileBatchPOC'];
        
        System.assert(batchJobs.size() >= 3, 'At least 3 batch jobs should be created');
    }
}