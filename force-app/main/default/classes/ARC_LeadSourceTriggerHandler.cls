/*******************************************************************
* @ClassName          :   ARC_LeadSourceTriggerHandler
* @Description        :   
* @MethodName         :   leadToSelfEnrollingStatus, checkExistingUsers
********************************************************************/

public without sharing class ARC_LeadSourceTriggerHandler {


    /*******************************************************************
    * @MethodName         :   leadToSelfEnrollingStatus
    * @Description        :   Updates the Lead status to Self Enrolling when the Lead Soruce is Self Enroll and the Lead is not Permanently Disqualified. 
    ********************************************************************/
    public static void leadToSelfEnrollingStatus(List<Lead_Source__c> LeadSourceList) {
        Set<Id> leadsIdsToQuery = new Set<Id>();
        List<String> emails = new List<String>();
        for (Lead_Source__c ls: LeadSourceList){
            emails.add(ls.Lead_Email__c);
            if (ls.Source_Name__c == 'Self Enroll' && ls.Lead__c != null ) leadsIdsToQuery.add(ls.Lead__c);
        }
        List<Lead> leadsToUpdate = [SELECT Id, Status, Status_Category__c FROM Lead WHERE Status != 'Self Enrolling' AND Status_Category__c != 'Permanently Disqualified' AND Id IN :leadsIdsToQuery];
        if ((leadsToUpdate?.size() > 0)) {
            for (Lead l : leadsToUpdate) l.Status = 'Self Enrolling';
            update leadsToUpdate;
        }

        //Check if there are users with the same email and dsable them. 
        checkExistingUsers(emails);
    }

    /*******************************************************************
    * @MethodName         :   checkExistingUsers
    * @Description        :   Pass the member portal user ids to the platform event that deactivate them if they exist without an awaiting or activated contract.  
    ********************************************************************/
    public static void checkExistingUsers (List<String> emails){
        List<User> existingUsers = [SELECT Id,Contact.ARC_CensusMember__c, IsPortalEnabled FROM User WHERE Email IN :emails AND IsPortalEnabled = true];
        if(existingUsers.size()>0){
            Set<Id> censusMemberIds = new Set<Id>();
            for(User u: existingUsers) censusMemberIds.add(u.Contact?.ARC_CensusMember__c);
            List<vlocity_ins__GroupCensusMemberPlan__c> gcmpList= [SELECT vlocity_ins__GroupCensusMemberId__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE Id IN :censusMemberIds AND (vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Activated' OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status LIKE '%Awaiting%')];
            Set<Id> membersWithContracts = new Set<Id>();
            for(vlocity_ins__GroupCensusMemberPlan__c gcmp:gcmpList) membersWithContracts.add(gcmp.vlocity_ins__GroupCensusMemberId__c);
            Set<Id> userIdsToDisable = new Set<Id>();
            for(User u: existingUsers){
                if(!membersWithContracts.contains(u.Contact.ARC_CensusMember__c)) userIdsToDisable.add(u.Id);
            }
            if(userIdsToDisable.size()>0){
                //Calls platform event to disable portal user if exist with the same email address. 
                ARC_DisablePortalUser__e myEvent = new ARC_DisablePortalUser__e();
                myEvent.ARC_UserId__c= String.join(new List<Id>(userIdsToDisable), ';');
                EventBus.publish(myEvent);
                System.debug('dispath event!' + userIdsToDisable);
            }
        }
    }
    
    /****************************************************************************
    * Takes a String (inputString) as a parameter, parses the string into 
    * separate parameters, searches a preset map for corresponding field names
    * for each parameter and returns a map of the field names and their values from
    * the input String.
    * @param inputString The String to process
    *****************************************************************************/    
    private static Map<String, String> parseURL(String inputString){
        // Create a map of utm parameters to the field names they correlate to
		Map<String, String> mapping = new Map<String, String>{
            'utm_source' => 'utm_source__c',
            'utm_medium' => 'medium__c',
            'utm_campaign' => 'campaign_name__c',
            'utm_term' => 'search_term__c',
            'utm_content' => 'content__c',
            'campaignid' => 'google_campaign_id__c',
            'adgroupid' => 'google_ad_group_id__c',
            'targetid' => 'google_target_id__c',
            'loc_interest_ms' => 'google_loc_interest_ms__c',
            'loc_physical_ms' => 'google_loc_physical_ms__c',
            'matchtype' => 'google_match_type__c',
            'network' => 'source_referrer__c',
            'device' => 'google_device__c',
            'devicemodel' => 'device_model__c',
            'creative' => 'googlecreative__c',
            'keyword' => 'keyword__c',
            'placement' => 'google_placement__c',
            'adposition' => 'google_ad_position__c',
            'gc_id' => 'click_id__c',
            'ad_id' => 'ad_id__c',
            'fbclid' => 'meta_pixel_id__c'
            };
        // Replace the first ? with & for consistency and simplicity of the code
        Integer firstQuestionMarkIndex = inputString.indexOf('?');
        if (firstQuestionMarkIndex != -1) {
            inputString = inputString.substring(0, firstQuestionMarkIndex) + 
                '&' + inputString.substring(firstQuestionMarkIndex + 1);
        }
        // Split the string into a list with each entry after an &
        List<String> splitString = inputString.split('&');       
        // Remove the base url from the list
        splitString.remove(0);
        // Create an empty map to hold the field names and values
        Map<String, String> matchedTerms = new Map<String, String>();
        // Convert the list into a map with strings to the left of the = as the
        // Key, and strings to the right as the Value
        for (String parameter : splitString) {
            system.debug('parameter: '+ parameter);
            List<String> keyValue = parameter.split('=');
            system.debug('keyvalue.size: '+ string.valueof(keyValue.size()));
            //If the parameter exists but there is no value set the value to a blank string
            if (keyValue.size()==1){
                System.Debug('Added blank for: '+ keyValue[0]);
                keyValue.add('');
            }
            matchedTerms.put(keyValue[0], keyValue[1]);
        }        
        // Replace the Key names with the SF Field Names
        Map<String, String> translatedMap = new Map<String, String>();
        for (String key : matchedTerms.keySet()) {
            if (mapping.containsKey(key)) {
                translatedMap.put(mapping.get(key), matchedTerms.get(key));
                System.debug('translated map | ' + mapping.get(key) +  ' : '+matchedTerms.get(key));
            }
        } // Now 'translatedMap' contains the field names mapped from the input parameters
        return translatedMap;
	} // end parseURL
    
    /****************************************************************************
    * Takes a Lead_Source__c record (recordToUpdate) as a parameter, 
    * updates its fields based on the values obtained from the URL parameters, 
    * and then returns the modified record.
    * @param recordToUpdate The Lead Source record to process
    *****************************************************************************/    
    private static Lead_Source__c setLeadSourceUTMFields(Lead_Source__c recordToUpdate) {
        // Get a map of field names based on the utm_parameter names in the Landing Page FUll field
        Map<String, String> fieldValues = parseURL(recordToUpdate.Landing_Page_Full__c);        
        // Update the fields based on the translated map
        Set<String> objectFields = Schema.SObjectType.Lead_Source__c.fields.getMap().keySet();
        for (String fieldName : fieldValues.keySet()) {
            // Make sure the field exists in the object
            fieldName = fieldName.toLowerCase();
            System.debug('fieldName: ' + fieldName);
            if (objectFields.contains(fieldName)) {
            	// Make sure the value isn't blank
                if (fieldValues.get(fieldName) != ''){
                    System.debug(fieldName + ': '+ fieldValues.get(fieldName));
                    try {
                        //Try to insert the value as a String
                        recordToUpdate.put(fieldName, EncodingUtil.urlDecode(fieldValues.get(fieldName), 'UTF-8'));
                    } catch (Exception e0) {
                        try {
                            // Try to insert the value as a Decimal
                         	System.debug('Exception 0: '+ fieldName +': '+(fieldValues.get(fieldName)));
                         	recordToUpdate.put(fieldName, Decimal.valueof(fieldValues.get(fieldName)));
                        } catch (Exception e1) {
                            // If neither format work, just give up and insert nothing
                            recordToUpdate.put(fieldName, null);
                        }
                    }
                }
            }
        }
        System.debug('recordToUpdate.ad_id__c: ' + recordToUpdate.ad_id__c);
        // return the record
        return recordToUpdate;
    } // end setLeadSourceUTMFields
    
    /****************************************************************************
    * Parses marketing URLs and updates Lead Source records with UTM parameters.
    * @param LeadSourceList The list of Lead Source records to process.
    *****************************************************************************/
    public static void parseMarketingURL(List<Lead_Source__c> LeadSourceList) {
        // List to store Lead Source records that need to be updated
        List<Lead_Source__c> leadSourcesToUpdate = new List<Lead_Source__c>();
        // Iterate through each Lead Source record
        for (Lead_Source__c ls : LeadSourceList) {
            // Check if Landing_Page_Full__c is not null and contains '&'
            if (ls.Landing_Page_Full__c != null && ls.Landing_Page_Full__c.indexOf('&') != -1) {
                // Call the setLeadSourceUTMFields method to parse and set UTM fields
                //leadSourcesToUpdate.add(setLeadSourceUTMFields(ls)); 
                ls = setLeadSourceUTMFields(ls);
                System.debug('ls.Ad_Id__C: '+ ls.Ad_Id__c);
            }
            leadSourcesToUpdate.add(ls);
        }
        // Check if there are Lead Source records to update
        if (leadSourcesToUpdate != null && leadSourcesToUpdate.size() > 0) {
            // Update the Lead Source records
            //update leadSourcesToUpdate;
        }
        System.debug('leadSourcesToUpdate Size: '+string.valueof(leadSourcesToUpdate.size()));
        
        //return leadSourcesToUpdate;
    } // end parseMarketingURL
}