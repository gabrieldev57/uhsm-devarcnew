/**
 * Apex class to retrieve Lead records related to Campaign Members.
 * This class provides an invocable method that takes a list of Campaign Member IDs
 * and returns the corresponding Lead records.
 */
public class CampaignMemberLeadLookup {
    @InvocableMethod(label='Get Leads for Campaign Members' description='Retrieves Lead records related to Campaign Members')
    public static List<List<Lead>> getLeadsForCampaignMembers(List<List<CampaignMember>> campaignMemberLists) {
        List<List<Lead>> leadsList = new List<List<Lead>>();

        // Iterate over each collection of Campaign Members received from the Flow
        for (List<CampaignMember> campaignMembers : campaignMemberLists) {
            List<Lead> leads = new List<Lead>();

            // Collect the Lead IDs from the Campaign Members
            Set<Id> leadIds = new Set<Id>();
            for (CampaignMember cm : campaignMembers) {
                leadIds.add(cm.LeadId);
            }

            // Query for the Lead records using the collected Lead IDs
            leads = [SELECT Id FROM Lead WHERE Id IN :leadIds];

            leadsList.add(leads);
        }

        return leadsList;
    }
}