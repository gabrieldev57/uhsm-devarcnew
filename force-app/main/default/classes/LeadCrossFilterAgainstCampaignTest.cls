@isTest
public class LeadCrossFilterAgainstCampaignTest {

    @isTest
    static void testRemoveLeadsIfCampaignMembers() {

		// Query for the custom meta data record for the campaign id
        List<Outbound_Dialer_Settings__mdt> dialerSettings = [SELECT Value__c 
                                                              FROM Outbound_Dialer_Settings__mdt 
                                                               WHERE DeveloperName = 'SDR_CampaignId'];

        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            Lead lead = new Lead(
                FirstName = 'Lead' + i,
                LastName = 'Test',
                Company = 'Test Company'
            );
            insert lead;
            CampaignMember campaignMember = new CampaignMember(
                LeadId = lead.Id,
                CampaignId = dialerSettings[0].Value__c
            );
            insert campaignMember;
            testLeads.add(lead);
        }

        // Create a test input list
        List<List<Lead>> testInputList = new List<List<Lead>>();
        testInputList.add(testLeads);

        // Invoke the invocable method
        Test.startTest();
        List<List<Lead>> result = LeadCrossFilterAgainstCampaign.removeLeadsIfCampaignMembers(testInputList);
        Test.stopTest();

        // Verify the results
        System.assertEquals(1, result.size());
        List<Lead> filteredLeads = result[0];
        System.assertEquals(0, filteredLeads.size(), 'No leads should be in the result');
    }
}