public without sharing class ARC_HealthProgramRecords {
    private static final String  BASE_URL = URL.getSalesforceBaseUrl().toExternalForm();
    
    @AuraEnabled(cacheable=true)
    public static List<Object> getContentVersionInfo(String programsList) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId, LinkedEntityId, LinkedEntity.Name FROM ContentDocumentLink WHERE LinkedEntityId IN ( SELECT Id FROM ARC_HealthProgram__c WHERE ARC_Active__c = true AND ARC_ProgramsList__c INCLUDES (:programsList) )];
        List<Object> healthRecords = new List<Object>();

        if (contentDocumentLinks.size() > 0) {
            
            List<Id> contentDocLinkIds = new List<Id>();
            Map<Id,Id> mapContentDocEntity = new Map<Id,Id>();
            Map<Id,String> mapContentDocEntityName = new Map<Id,String>();

            for (ContentDocumentLink cdl : contentDocumentLinks ) {
                contentDocLinkIds.add(cdl.ContentDocumentId);
            }                
            
            for (ContentDocumentLink cdl : contentDocumentLinks) {
                mapContentDocEntity.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
            }

            for (ContentDocumentLink cdl : contentDocumentLinks) {
                mapContentDocEntityName.put(cdl.ContentDocumentId, cdl.LinkedEntity.Name);
            }
            
            contentVersions = [SELECT Id,ContentDocumentId,Title,VersionData,isLatest FROM ContentVersion WHERE ContentDocumentId IN :contentDocLinkIds AND IsLatest = true];
            
            for (ContentVersion cv : contentVersions) {
                Map<String,Object> record = new Map<String,Object>();
                record.put('ContentDocumentId', cv.ContentDocumentId);
                record.put('Id', cv.Id);
                record.put('RecordId', mapContentDocEntity.get(cv.ContentDocumentId));
                record.put('RecordName', mapContentDocEntityName.get(cv.ContentDocumentId));
                record.put('ImageURL', BASE_URL + '/sfc/servlet.shepherd/document/download/' + cv.Id);
                healthRecords.add(record);
            }
        }
        //return contentVersions;
        return healthRecords;
    }

    @AuraEnabled(cacheable=true)
    public static List<ARC_HealthProgramSpec__c> getHealthProgramSpecs(){
        try {
            return [SELECT Id, Name, ARC_Description__c, ARC_HealthProgram__c, ARC_Order__c FROM ARC_HealthProgramSpec__c WHERE ARC_HealthProgram__c IN (SELECT Id FROM ARC_HealthProgram__c WHERE ARC_Active__c = true)];
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}