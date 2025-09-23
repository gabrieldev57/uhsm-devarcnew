public without sharing class ARC_RetrieveBenefitCards {
    private static final String  BASE_URL = URL.getSalesforceBaseUrl().toExternalForm();

    @AuraEnabled(cacheable=true)
    public static List<Object> getBenefitCards() {  
        
        
        List<BenefitCard__c> benefitCardRecordList = [SELECT ID, ARC_Description__c,ARC_Link__c,ARC_Title__c FROM BenefitCard__c];
        
        return benefitCardRecordList;

    }

    @AuraEnabled(cacheable=true)
    public static List<Object> getContentVersionInfo(String cardsList) {
        
        List<Object> returnList = new List<Object>();
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        
        List<ContentDocumentLink> contentDocumentLinks = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN ( SELECT Id FROM BenefitCard__c WHERE ARC_CardsList__C INCLUDES (:cardsList) )];
        if (contentDocumentLinks.size() > 0) {          
            List<Id> contentDocLinkIds = new List<Id>();
            Map<Id,Id> mapContentDocEntity = new Map<Id,Id>();
            
            for (ContentDocumentLink cdl : contentDocumentLinks ) {
                contentDocLinkIds.add(cdl.ContentDocumentId);
                mapContentDocEntity.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
            }
            
            contentVersions = [SELECT Id,ContentDocumentId,Title,VersionData,isLatest FROM ContentVersion WHERE ContentDocumentId IN :contentDocLinkIds AND IsLatest = true];
            System.debug(contentDocLinkIds);
            for (ContentVersion cv : contentVersions) {
                Map<String,Object> record = new Map<String,Object>();
                record.put('ContentDocumentId', cv.ContentDocumentId);
                record.put('ImageId', cv.Id); //content version Id (image)
                record.put('RecordId', mapContentDocEntity.get(cv.ContentDocumentId));
                record.put('ImageURL', BASE_URL + '/sfc/servlet.shepherd/document/download/' + cv.Id);

                returnList.add(record);
            }
        }
       
        return returnList;
        
    }

}