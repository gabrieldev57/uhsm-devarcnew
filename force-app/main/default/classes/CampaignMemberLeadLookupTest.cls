@isTest
public class CampaignMemberLeadLookupTest {
    @isTest
    static void testGetLeadsForCampaignMembers() {
        // Create test Campaign Members and Leads
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        List<Lead> leads = new List<Lead>();
        Campaign camp = new Campaign(name='LookupTestCampaign', isactive=True);
        insert camp;
        system.debug('Camp.id: ' + camp.id);

        for (Integer i = 0; i < 5; i++) {
            Lead lead = new Lead(
                FirstName = 'Lead' + i,
                LastName = 'Test',
                Company = 'Test Company'
            );
            insert lead;
            leads.add(lead);

            CampaignMember campaignMember = new CampaignMember(
                CampaignId = camp.id,
                LeadId = lead.Id
            );
            campaignMembers.add(campaignMember);
        }

        insert campaignMembers;

        // Prepare input data for the Apex method
        List<List<CampaignMember>> campaignMemberLists = new List<List<CampaignMember>>();
        campaignMemberLists.add(campaignMembers);

        Test.startTest();
        // Call the Apex method
        List<List<Lead>> resultLeadsList = CampaignMemberLeadLookup.getLeadsForCampaignMembers(campaignMemberLists);
        Test.stopTest();

        // Perform assertions to verify the result
        System.assertEquals(1, resultLeadsList.size()); // Since we are passing a single collection in this test
        List<Lead> resultLeads = resultLeadsList[0];
        System.assertEquals(campaignMembers.size(), resultLeads.size());
        for (Integer i = 0; i < campaignMembers.size(); i++) {
            System.assertEquals(campaignMembers[i].LeadId, resultLeads[i].Id);
            // Add more assertions for other fields if necessary
        }
    }
}