public with sharing class ARC_CheckDependencies{
    
    public String componentName;
    public List<String> checkList;
    public Boolean checkActivesOnly = true;

    public List<Id> whereIsUsedIds = new List<Id>();


    @AuraEnabled(cacheable=true)
    public static List<String> checkDependencies(String componentName) {
        List<vlocity_ins__OmniscriptDefinition__c> omniScripts = [
            SELECT Id,
                vlocity_ins__OmniScriptId__c,
                vlocity_ins__OmniScriptId__r.Name,
                vlocity_ins__OmniScriptId__r.vlocity_ins__Type__c,
                vlocity_ins__OmniScriptId__r.vlocity_ins__SubType__c,
                vlocity_ins__Content__c 
            FROM vlocity_ins__OmniscriptDefinition__c 
            WHERE vlocity_ins__OmniScriptId__r.vlocity_ins__IsActive__c = true ORDER BY CreatedDate DESC
        ];
        
        List<Id> whereIsUsedIds = new List<Id>();
        for (vlocity_ins__OmniscriptDefinition__c omniScript : omniScripts) {
            if (omniScript.vlocity_ins__Content__c != null) {
                if (omniScript.vlocity_ins__Content__c.contains(componentName)) {
                    whereIsUsedIds.add(omniScript.vlocity_ins__OmniScriptId__c);
                }
                
            }
        }
        return whereIsUsedIds;
    }


    

}