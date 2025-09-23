@isTest
public class ARC_AbandonedStepTest {
    @TestSetup
    static void makeData(){
        // Create test data
        Lead lead = new Lead();
        lead.FirstName = 'Test';
        lead.LastName = 'Lead';
        lead.Status = 'Self Enrolling';
        insert lead;
        Lead_Source__c leadSource = new Lead_Source__c();
        leadSource.Lead__c = lead.Id;
        insert leadSource;
        vlocity_ins__VlocityTrackingEntry__c trackingEntry = new vlocity_ins__VlocityTrackingEntry__c();
        trackingEntry.Name = 'OS Step Load';
        trackingEntry.ARC_LeadSource__c = leadSource.Id;
        insert trackingEntry;
    }
    @isTest
    static void testExecute() {
        // Call the method being tested
        Test.startTest();
        ARC_AbandonedStep.execute();
        Test.stopTest();

        // Verify the results
        Lead_Source__c leadSource = [SELECT ARC_LastStepEntry__c FROM Lead_Source__c LIMIT 1];
        vlocity_ins__VlocityTrackingEntry__c trackingEntry = [SELECT Id FROM vlocity_ins__VlocityTrackingEntry__c WHERE Id = :leadSource.ARC_LastStepEntry__c];
        System.assertEquals(trackingEntry.Id, leadSource.ARC_LastStepEntry__c);
    }
}