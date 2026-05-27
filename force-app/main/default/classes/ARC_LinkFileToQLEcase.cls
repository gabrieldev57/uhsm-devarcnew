public without sharing class ARC_LinkFileToQLEcase {

    public class Request {
        @InvocableVariable(label='Content Document IDs' required=true)
        public List<String> contentDocumentIds;
        
        @InvocableVariable(label='Case Id' required=true)
        public String caseId;

        @InvocableVariable(label='Person Account Id' required=true)
        public String personAccountId;
    }

    @InvocableMethod(label='Re-Link Files To Case' description='Links uploaded files to a Case')
    public static void reLinkFiles(List<Request> requests) {
        Request req = requests[0];

        String lastDocumentId = req.contentDocumentIds[req.contentDocumentIds.size() - 1];

        List<ContentDocumentLink> allAccountLinks = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :req.personAccountId
        ];

        List<ContentDocument> docsToDelete = new List<ContentDocument>();
        List<ContentDocumentLink> linksToDelete = new List<ContentDocumentLink>();

        for (ContentDocumentLink cdl : allAccountLinks) {
            if (cdl.ContentDocumentId != lastDocumentId) {
                docsToDelete.add(new ContentDocument(Id = cdl.ContentDocumentId));
            } else {
                linksToDelete.add(cdl);
            }
        }

        if (!docsToDelete.isEmpty()) {
            try {
                delete docsToDelete;
            } catch (DmlException e) {
                throw new AuraHandledException('Error deleting previous files: ' + e.getMessage());
            }
        }

        try {
            insert new ContentDocumentLink(
                ContentDocumentId = lastDocumentId,
                LinkedEntityId = req.caseId,
                ShareType = 'V'
            );
        } catch (DmlException e) {
            throw new AuraHandledException('Error linking file to Case: ' + e.getMessage());
        }

        if (!linksToDelete.isEmpty()) {
            try {
                delete linksToDelete;
            } catch (DmlException e) {
                throw new AuraHandledException('Error removing file from Account: ' + e.getMessage());
            }
        }
    }      
}