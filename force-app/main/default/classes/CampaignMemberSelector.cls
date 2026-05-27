public without sharing class CampaignMemberSelector {
    
    @InvocableMethod(label='Get Campaign Members for Assignment' description='Retrieves high-risk contacts not in specified campaigns and creates Campaign Member records')
    public static List<FlowOutput> getCampaignMembersForAssignment(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();
        
        FlowInput input = inputs[0];
        FlowOutput output = new FlowOutput();
        
        // Calculate required contact count (count * 1.05)
        Integer totalContactsNeeded = (Integer)(input.count * 1.05);
        Integer SUBQUERY_LIMIT = 50000;
        Integer totalExcludedMembers = 0; // Initialize here
        
        // Check if we'll exceed the subquery limit
        if (input.excludedCampaigns != null && !input.excludedCampaigns.isEmpty()) {
            totalExcludedMembers = [
                SELECT COUNT() 
                FROM CampaignMember 
                WHERE CampaignId IN :input.excludedCampaigns
            ];
            
            if (totalExcludedMembers > SUBQUERY_LIMIT) {
                output.success = false;
                output.errorMessage = 'Too many existing campaign members (' + totalExcludedMembers + 
                                     '). Maximum supported: ' + SUBQUERY_LIMIT + 
                                     '. Please contact your administrator to enable scaled processing.';
                output.availableCount = 0;
                output.requestedCount = totalContactsNeeded;
                output.totalExcludedMembers = totalExcludedMembers;
                output.mainCampaignMembers = new List<CampaignMember>();
                output.controlCampaignMembers = new List<CampaignMember>();
                outputs.add(output);
                return outputs;
            }
        }
        
        // Query high-risk accounts that are NOT already campaign members
        List<Account> eligibleAccounts;
        
        if (input.excludedCampaigns != null && !input.excludedCampaigns.isEmpty()) {
            eligibleAccounts = [
                SELECT Id, PersonContactId, Risk_Decile__c
                FROM Account
                WHERE IsPersonAccount = true
                AND IsActive = true
                AND Risk_Decile__c > 0
                AND PersonContactId != null
                AND ARC_OptOutCall__c = FALSE
                AND PersonContactId NOT IN (
                    SELECT ContactId 
                    FROM CampaignMember 
                    WHERE CampaignId IN :input.excludedCampaigns
                    AND ContactId != null
                )
                ORDER BY Risk_Decile__c DESC, Id ASC
                LIMIT :totalContactsNeeded
            ];
        } else {
            eligibleAccounts = [
                SELECT Id, PersonContactId, Risk_Decile__c
                FROM Account
                WHERE IsPersonAccount = true
                AND IsActive = true
                AND Risk_Decile__c > 0
                AND PersonContactId != null
                ORDER BY Risk_Decile__c DESC, Id ASC
                LIMIT :totalContactsNeeded
            ];
        }
        
        // Check if we have enough contacts
        if (eligibleAccounts.size() < totalContactsNeeded) {
            output.success = false;
            output.errorMessage = 'Insufficient eligible contacts available. Needed: ' + totalContactsNeeded + 
                                 ', Found: ' + eligibleAccounts.size() + 
                                 '. All high-risk contacts may already be assigned to campaigns.';
            output.availableCount = eligibleAccounts.size();
            output.requestedCount = totalContactsNeeded;
            output.totalExcludedMembers = totalExcludedMembers; // Add here
            output.mainCampaignMembers = new List<CampaignMember>();
            output.controlCampaignMembers = new List<CampaignMember>();
            outputs.add(output);
            return outputs;
        }
        
        // We have enough - split contacts between main and control campaigns
        output.mainCampaignMembers = new List<CampaignMember>();
        output.controlCampaignMembers = new List<CampaignMember>();
        
        // Create Campaign Members for main campaign (first 'count' contacts)
        for (Integer i = 0; i < input.count; i++) {
            CampaignMember cm = new CampaignMember(
                CampaignId = input.thisCampaignId,
                ContactId = eligibleAccounts[i].PersonContactId,
                Status = 'Uncalled'
            );
            output.mainCampaignMembers.add(cm);
        }
        
        // Create Campaign Members for control campaign (remaining contacts)
        for (Integer i = input.count; i < eligibleAccounts.size(); i++) {
            CampaignMember cm = new CampaignMember(
                CampaignId = input.controlCampaignId,
                ContactId = eligibleAccounts[i].PersonContactId,
                Status = 'Uncalled'
            );
            output.controlCampaignMembers.add(cm);
        }
        
        output.success = true;
        output.availableCount = eligibleAccounts.size();
        output.requestedCount = totalContactsNeeded;
        output.totalExcludedMembers = totalExcludedMembers; // Add here too
        outputs.add(output);
        return outputs;
    }
    
    public class FlowInput {
        @InvocableVariable(required=true label='This Campaign ID' description='The main campaign to add members to')
        public Id thisCampaignId;
        
        @InvocableVariable(required=true label='Control Campaign ID' description='The control campaign to add members to')
        public Id controlCampaignId;
        
        @InvocableVariable(required=true label='Count' description='Number of main campaign members (must be multiple of 20)')
        public Integer count;
        
        @InvocableVariable(required=true label='Excluded Campaigns' description='Collection of Campaign IDs whose members should be excluded')
        public List<Id> excludedCampaigns;
    }
    
    public class FlowOutput {
        @InvocableVariable(label='Main Campaign Members' description='Campaign Members to insert for the main campaign')
        public List<CampaignMember> mainCampaignMembers;
        
        @InvocableVariable(label='Control Campaign Members' description='Campaign Members to insert for the control campaign')
        public List<CampaignMember> controlCampaignMembers;
        
        @InvocableVariable(label='Success' description='Whether the operation was successful')
        public Boolean success;
        
        @InvocableVariable(label='Error Message' description='Error message if operation failed')
        public String errorMessage;
        
        @InvocableVariable(label='Available Count' description='Number of eligible contacts found')
        public Integer availableCount;
        
        @InvocableVariable(label='Requested Count' description='Number of contacts requested')
        public Integer requestedCount;
        
        @InvocableVariable(label='Total Excluded Members' description='Total number of campaign members being excluded')
        public Integer totalExcludedMembers;
    }
}