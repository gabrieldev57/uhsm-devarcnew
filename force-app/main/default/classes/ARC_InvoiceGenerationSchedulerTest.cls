@isTest
private class ARC_InvoiceGenerationSchedulerTest {

    @isTest
    static void testSchedulerExecutesBatch() {

        Test.startTest();

        String jobId = System.schedule(
            'Test Invoice Scheduler',
            '0 0 0 1 1 ? 2099',
            new ARC_InvoiceGenerationScheduler()
        );

        Test.stopTest();

        // Verify scheduler job exists
        CronTrigger ct = [
            SELECT Id, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals('WAITING', ct.State);

        // Verify batch job was triggered
        List<AsyncApexJob> jobs = [
            SELECT Id, JobType, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
        ];

        System.assert(!jobs.isEmpty(), 'Batch job should have been triggered');

        //Better assertion: ensure no errors
        for (AsyncApexJob job : jobs) {
            System.assertEquals(0, job.NumberOfErrors, 'Batch should not fail');
        }
    }
}