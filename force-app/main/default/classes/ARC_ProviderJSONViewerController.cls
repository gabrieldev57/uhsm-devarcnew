public with sharing class ARC_ProviderJSONViewerController {
    
    @AuraEnabled(cacheable = true)
    public static Map<String,String> getProviderJSON(Id accountId) {
        Map<String,String> toReturn = new Map<String,String>();

        Account acc = [SELECT Name, Id, RecordType.DeveloperName, ARC_RenderingProviderJSON__pc FROM Account WHERE Id =: accountId];
        
        Map<String, String> providerPre = (Map<String,String>) JSON.deserialize(acc.ARC_RenderingProviderJSON__pc, Map<String,String>.class);
       
        for (String key : providerPre.keySet()) {
            toReturn.put(key,providerPre.get(key));
        }
        return toReturn;
    }
}