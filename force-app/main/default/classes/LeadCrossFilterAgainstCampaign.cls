public class LeadCrossFilterAgainstCampaign {
/**
 * Apex class to filter out leads from a collection
 * If those leads are currently members of the SDR outbound dial campaign
 */
    
    @InvocableMethod(label='Remove Leads If On Outbound Campaign' 
                     description='Returns a list of Leads that are not on the outbound dial campaign')
    public static List<List<Lead>> removeLeadsIfCampaignMembers(List<List<Lead>> inputLeadLists) {
        List<List<Lead>> newLeadsList = new List<List<Lead>>();

        // Iterate over each collection of Leads received from the Flow
        for (List<Lead> inputLeads : inputLeadLists) {
            List<Lead> leads = new List<Lead>();
            List<CampaignMember> onCampaign = new List<CampaignMember>();

            // Collect the Lead IDs from the Leads
            Set<Id> leadIds = new Set<Id>();
            for (Lead iL : inputLeads) {
                leadIds.add(iL.Id);
            }
            
            // Query for the custom meta data record for the campaign id
        	List<Outbound_Dialer_Settings__mdt> dialerSettings = [SELECT Value__c 
                                                                          FROM Outbound_Dialer_Settings__mdt 
                                                                          WHERE DeveloperName = 'SDR_CampaignId'];
            
            // Query for the custom meta data record for the campaign id
        	List<Outbound_Dialer_Settings__mdt> dialerSettings_GBPM = [SELECT Value__c 
                                                                          FROM Outbound_Dialer_Settings__mdt 
                                                                          WHERE DeveloperName = 'SDR_CampaignId_GBPM'];
            
			if (!dialerSettings.isEmpty()) {
            // Retrieve the Campaign Id from the custom metadata record
                String sdrCampaignId = dialerSettings[0].Value__c;
                String sdrCampaignId_GBPM = dialerSettings_GBPM[0].Value__c;
                
                // Query for the Lead records already on the campagin using the collected Lead IDs
                onCampaign = [SELECT LeadId FROM CampaignMember 
                              			WHERE LeadId IN :leadIds 
                              			AND (CampaignId = :sdrCampaignId OR 
                                             CampaignId = :sdrCampaignId_GBPM)];
                
                // Get the Lead IDs from the onCampaign list
                Set<Id> leadIdsOnCampaign = new Set<Id>();
                    for (CampaignMember cm : onCampaign) {
                        leadIdsOnCampaign.add(cm.LeadId);
                    }
                
                // Query for the Lead records using the collected Lead IDs
                leads = [SELECT Id, Lead_Source_Domain__c FROM Lead WHERE Id IN :leadIds 
                         					 AND Id NOT IN :leadIdsOnCampaign];
                         //(SELECT LeadId FROM CampaignMember WHERE CampaignId = :sdrCampaignId)];
            }
            
            newLeadsList.add(leads);
        }

        return newLeadsList;
    }

}