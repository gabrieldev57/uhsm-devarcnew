public with sharing class ARC_MemberJSONController {

    @AuraEnabled(cacheable = true)
    public static List<Map<String,String>> getJSONFields(Id claimId) {
        List<Map<String,String>> toReturn = new List<Map<String,String>>();
        Claim clm = [SELECT Name, Id, RecordType.DeveloperName, ARC_SubmitterJSON__c, ARC_ServiceFacility__c, ARC_ReferringProvider__c, ARC_PatientJSON__c FROM Claim WHERE Id =: claimId];
        
        Map<String, String> submitterPre = (Map<String,String>) JSON.deserialize(clm.ARC_SubmitterJSON__c, Map<String,String>.class);
        Map<String, String> submitter = new Map<String, String>();
        for (String key : submitterPre.keySet()) {
            submitter.put(key,submitterPre.get(key));
        }
        toReturn.add(submitter);

        Map<String, String> ServiceFacilityPre = (Map<String,String>) JSON.deserialize(clm.ARC_ServiceFacility__c, Map<String,String>.class);
        Map<String, String> ServiceFacility = new Map<String, String>();
        for (String key : ServiceFacilityPre.keySet()) {
            ServiceFacility.put(key,ServiceFacilityPre.get(key));            
        }
        toReturn.add(ServiceFacility);

        Map<String, String> ReferringProviderPre = (Map<String,String>) JSON.deserialize(clm.ARC_ReferringProvider__c, Map<String,String>.class);
        Map<String, String> ReferringProvider = new Map<String, String>();
        for (String key : ReferringProviderPre.keySet()) {
            ReferringProvider.put(key,ReferringProviderPre.get(key));
        }
        toReturn.add(ReferringProvider);

        Map<String, String> PatientPre = (Map<String,String>) JSON.deserialize(clm.ARC_PatientJSON__c, Map<String,String>.class);
        Map<String, String> Patient = new Map<String, String>();
        for (String key : PatientPre.keySet()) {
            Patient.put(key,PatientPre.get(key));
        }
        toReturn.add(Patient);   
        
        
        return toReturn;
    }
}