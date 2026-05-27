public without sharing class ARC_EmployerCaseFileUploadController {

    @AuraEnabled(cacheable=false)
    public static void updateCaseAndReplaceFile(Map<String, Object> mapIds) {
        String caseId = (String) mapIds.get('caseId');
        String newContentVersionId = (String) mapIds.get('newContentVersionId');
 
        if (caseId == null || newContentVersionId == null) {
            throw new AuraHandledException('Invalid request parameters.');
        }
 
        ContentVersion cv = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :newContentVersionId 
            LIMIT 1
        ];
 
        List<ContentDocumentLink> existingLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :caseId
            AND ContentDocument.FileExtension = 'csv'
            AND ContentDocumentId != :cv.ContentDocumentId
        ];
 
        if (!existingLinks.isEmpty()) {
            Set<Id> docIds = new Set<Id>();
            for (ContentDocumentLink cdl : existingLinks) {
                docIds.add(cdl.ContentDocumentId);
            }
            delete [SELECT Id FROM ContentDocument WHERE Id IN :docIds];
        }
 
        insert new ContentDocumentLink(
            LinkedEntityId = caseId,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
 
        Case currentCase = [SELECT Status FROM Case WHERE Id = :caseId LIMIT 1];
        if (currentCase.Status != 'In Progress') {
            currentCase.Status = 'In Progress';
            update currentCase;
        }
    }
    
    // @AuraEnabled(cacheable=false)
    // public static void updateCaseAndReplaceFile(Map<String, Object> mapIds) {
    //     String caseId = (String) mapIds.get('caseId');
    //     String newContentVersionId = (String) mapIds.get('newContentVersionId');

    //     if (caseId == null || newContentVersionId == null) {
    //         throw new AuraHandledException('Invalid request parameters.');
    //     }
        
        
    //     List<ContentDocumentLink> existingLinks = [
    //         SELECT ContentDocumentId, ContentDocument.FileExtension 
    //         FROM ContentDocumentLink 
    //         WHERE LinkedEntityId = :caseId
    //         AND ContentDocument.FileExtension = 'csv' 
    //         AND ContentDocument.LatestPublishedVersionId != :newContentVersionId
    //     ];
        
       
        
    //     if (!existingLinks.isEmpty()) {
    //         delete existingLinks;
    //     }
        
      
      
    //     Case currentCase = [SELECT Status FROM Case WHERE Id = :caseId LIMIT 1];
        
    //     if (currentCase.Status != 'In Progress') {
    //         currentCase.Status = 'In Progress';
    //        update currentCase;
    //     }
    // }
    
    @AuraEnabled(cacheable=true)
    public static String encryptedToken(String encrypted) {
        try {
            return EncodingUtil.base64Decode(encrypted).toString();
        } catch (Exception e) {
            throw new AuraHandledException('Failed to decrypt Case ID.');
        }
    }
}