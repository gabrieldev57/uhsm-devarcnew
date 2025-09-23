public with sharing class ARCRenderingProviderJSONViewerController {

    @AuraEnabled(cacheable = true)
    public static Map<String,String> getRenderingProviderJSON(Id contactId) {
        Map<String,String> toReturn = new Map<String,String>();

        Contact con = [SELECT Name, Id, RecordType.DeveloperName, ARC_RenderingProviderJSON__c FROM Contact WHERE Id =: contactId];
        
        Map<String, String> providerPre = (Map<String,String>) JSON.deserialize(con.ARC_RenderingProviderJSON__c, Map<String,String>.class);
        
        for (String key : providerPre.keySet()) {
            toReturn.put(key,providerPre.get(key));
        }
        return toReturn;
    }
    
}