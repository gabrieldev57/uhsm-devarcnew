@isTest
private class ARC_VlocityTrackingEntryTriggerTest {
    
    @TestSetup
    static void makeData(){
        Lead lead = new Lead(
            Status = 'New',
            LastName = 'Dude'
        );
        insert lead;
        Lead_Source__c leadSource = new Lead_Source__c(
            Source_Name__c ='LSTest',
            Lead__c = lead.Id 
        );
        insert leadSource;
    }
    

    @isTest
    static void testUpdateLeadSource() {
        Id leadSourceId = [SELECT Id FROM Lead_Source__c LIMIT 1].Id;
        vlocity_ins__VlocityTrackingEntry__c testVlocityTrackingEntry = new vlocity_ins__VlocityTrackingEntry__c(
            vlocity_ins__Data__c = '{"ARC_LeadSource__c":"'+leadSourceId+'"}'
        );
        
        // Call trigger handler
        Test.startTest();
        insert testVlocityTrackingEntry;
        Test.stopTest();
        
        // Verify lead source was updated
        vlocity_ins__VlocityTrackingEntry__c updatedTrackingEntity = [SELECT Id, ARC_LeadSource__c FROM vlocity_ins__VlocityTrackingEntry__c WHERE Id = :testVlocityTrackingEntry.Id];
        System.assertEquals(leadSourceId, updatedTrackingEntity.ARC_LeadSource__c);
    }
}