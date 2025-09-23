public with sharing class ARC_caseFileUploadController {
    @AuraEnabled
    public static void uploadFiles(Id caseId, List<Id> contentDocumentIds) {
        if (caseId == null || contentDocumentIds.isEmpty()) {
            throw new AuraHandledException('Invalid Case ID or file list.');
        }

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Id fileId : contentDocumentIds) {
            links.add(new ContentDocumentLink( 
                //LinkedEntityId = caseId,
                ContentDocumentId = fileId
                //ShareType = 'V', // Allows Case Owner to view files
                //Visibility = 'InternalUsers' // Restricts Guest Users after upload
            ));
        }
        System.debug('links Debug' + links);
        //upsert links;
    }
    @AuraEnabled(cacheable=true)
    public static String encryptedToken(String encrypted){
        String decodedId = EncodingUtil.base64Decode(encrypted).toString();
        System.debug('decodedId ' + decodedId);
        return decodedId;        
    }
}