public without sharing class ARC_IFrameController {
   
    @AuraEnabled
    public static Case getSMBLegacyURL(String caseId){
        try {
            return [SELECT Id, ARC_SMBUrl__c,ARC_SMBSearchUrl__c FROM Case WHERE Id =:caseId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('Error in ARC_IFrameController.geSMBLegacyURL: '+ e.getMessage());
        }
    }
}