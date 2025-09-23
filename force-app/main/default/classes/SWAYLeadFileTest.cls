@isTest
public class SWAYLeadFileTest {

    // Test method for positive batch job execution
    @isTest
    static void testPositiveBatchExecution() {
        // Create test data for Lead records
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            Lead lead = new Lead(
                Lead_Source_Domain__c = 'Sway',
                FirstName = 'John' + i,
                LastName = 'Doe' + i,
                Phone = '123456789' + i,
                Email = 'john.doe' + i + '@example.com',
                CreatedDate = System.now(),
                Status = 'Open',
                Disqualified_Reason__c = null,
                Disqualified_Remarks__c = 'No remarks',
                next_steps__c = 'Follow up'
            );
            leads.add(lead);
        }
        insert leads;

        // Start the batch job
        Test.startTest();
        SWAYLeadFile leadFileBatch = new SWAYLeadFile();
        Database.executeBatch(leadFileBatch);
        Test.stopTest();

        // Verify the results
        ContentVersion[] contentVersions = [SELECT Id FROM ContentVersion];
        System.assertEquals(1, contentVersions.size());

        // FTP2SF.FTP.Response ftpResponse = FTP2SF.FTP.get('UHSM', 'SwayFile/' + leadFileBatch.filename + '.csv');
        // System.assertNotEquals(null, ftpResponse);

        // You can add more assertions as needed to verify the batch job's behavior.
    }
}