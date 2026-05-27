public with sharing class ARC_DocGenDirectInvoker {
    /**
     * Generates a DocGen document (server-side) by inserting a DocumentGenerationProcess record
     * using explicit token data (TokenData). Returns the inserted DocumentGenerationProcess Id.
     *
     * @param referenceObjectId  Id of the sObject the document will reference (e.g., ARC_Invoice__c Id)
     * @param templateContentVersionId  ContentVersion Id of the DOCX template (string or Id)
     * @param tokenDataMap       Map of token names to values that will be used by the template
     * @param title              Title to give the generated file (used to find the ContentVersion later)
     * @return Id of the inserted DocumentGenerationProcess record
     */
    public static Id generateDocumentWithTokenData(Id referenceObjectId, String templateContentVersionId, Map<String, Object> tokenDataMap, String title) {
        if (referenceObjectId == null) {
            throw new IllegalArgumentException('referenceObjectId must be provided');
        }
        if (String.isBlank(templateContentVersionId)) {
            throw new IllegalArgumentException('templateContentVersionId must be provided');
        }
        if (String.isBlank(title)) {
            title = 'Generated Document - ' + Datetime.now().getTime();
        }

        DocumentGenerationProcess docGen = new DocumentGenerationProcess();
        docGen.Type = 'GenerateAndConvert';

        Map<String, Object> requestText = new Map<String, Object>{
            'keepIntermediate' => true,
            'title' => title,
            'templateContentVersionId' => templateContentVersionId
        };
        docGen.RequestText = JSON.serialize(requestText);

        docGen.ReferenceObject = referenceObjectId;

        if (tokenDataMap != null) {
            // TokenData must be a JSON string of the token map
            docGen.TokenData = JSON.serialize(tokenDataMap);
        }

        docGen.DocGenApiVersionType = 'Advanced';

        insert docGen;
        return docGen.Id;
    }

    
}