global with sharing class ARC_CaseBatchUpdate implements Database.Batchable<SObject> {
    
    private static final String COMMUNITY_PATH = '/members/s/upload?caseId=';
    private static final Integer DEFAULT_BATCH_SIZE = 50;  // Default batch size
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, ARC_Upload_files_URL__c FROM Case WHERE IsClosed = false AND Recordtype.Name != \'Authorization\''); 
    }

    global void execute(Database.BatchableContext BC, List<Case> scope) {
        List<Case> casesToUpdate = new List<Case>();
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
        
        try {
            String communityBaseUrl = URL.getOrgDomainUrl().toExternalForm(); 
            communityBaseUrl = communityBaseUrl.replace('salesforce', 'site');
            
            for (Case c : scope) {
                if (c.Id != null) {
                    Case updatedCase = new Case(Id = c.Id);            
                    String encodedId = EncodingUtil.base64Encode(Blob.valueOf(c.Id));
                    updatedCase.ARC_Upload_files_URL__c = '<a href="' + communityBaseUrl + COMMUNITY_PATH + encodedId + '" target="_blank">Upload files here.</a>';
                    casesToUpdate.add(updatedCase);
                }
            }
            
            if (!casesToUpdate.isEmpty()) {
                saveResults = Database.update(casesToUpdate, false);
                handleSaveResults(saveResults);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in ARC_CaseBatchUpdate.execute: ' + e.getMessage());
            throw new ARC_CaseBatchUpdateException('Error processing batch: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug(LoggingLevel.INFO, 'Batch update completed.');
    }
    
    private void handleSaveResults(List<Database.SaveResult> results) {
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug(LoggingLevel.ERROR, 'Error updating case: ' + err.getMessage());
                }
            } 
        }
    }
     
    public class ARC_CaseBatchUpdateException extends Exception {}
}