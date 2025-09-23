global class CaseBatchUpdate implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id,ARC_Upload_files_URL__c FROM Case'); 
    }

    global void execute(Database.BatchableContext BC, List<Case> scope) {
        List<Case> casesToUpdate = new List<Case>();

        String communityBaseUrl = URL.getOrgDomainUrl().toExternalForm();
        communityBaseUrl = communityBaseUrl.replace('salesforce', 'site');

        String communityPath = '/members/s/upload?caseId='; 
        
        for (Case c : scope) {
            if (c.Id != null) {
                Case updatedCase = new Case(Id = c.Id);            
                String encodedId = EncodingUtil.base64Encode(Blob.valueOf(c.Id));
                updatedCase.ARC_Upload_files_URL__c = '<a href="' + communityBaseUrl + communityPath + encodedId + 
                    '" target="_blank">Upload files here.</a>';
                System.debug('Generated URL: ' + updatedCase.ARC_Upload_files_URL__c);
                casesToUpdate.add(updatedCase);
            }
        }
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch update completed.');
    }
}