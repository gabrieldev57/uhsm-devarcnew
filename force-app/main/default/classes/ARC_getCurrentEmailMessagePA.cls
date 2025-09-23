public without sharing class ARC_getCurrentEmailMessagePA {
    @AuraEnabled(cacheable=true)
    public static List<EmailMessage> getCurrentEmailMessage(Id recordId) {
        // Check if the environment is a sandbox
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

        // Define the filter date for production logic
        Date filterDate = Date.newInstance(2025, 1, 16);

        // Build the query
        String query = 'SELECT Id, FromAddress, Status, ToAddress, Subject, RelatedToId, HtmlBody, TextBody, CreatedDate, MessageDate ' +
                       'FROM EmailMessage ' +
                       'WHERE (ARC_CensusMember__r.vlocity_ins__ContactId__r.AccountId = :recordId OR ARC_PersonAccount__c = :recordId) ';

        if (isSandbox) {
            // In sandbox, filter by Status = '3' (Sent)
            query += 'AND Status = \'3\' ';
        } else {
            // In production, adjust filtering based on CreatedDate
            query += 'AND ((CreatedDate >= :filterDate AND Status = \'3\') OR (CreatedDate < :filterDate))';
        }

        // Sort the results by MessageDate descending
        query += 'ORDER BY MessageDate DESC';

        // Execute the query and return the results
        return Database.query(query);
    }
}