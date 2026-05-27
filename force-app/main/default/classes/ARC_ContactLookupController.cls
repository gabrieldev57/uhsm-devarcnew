/**
 * @description Controller for Contact lookup functionality
 * @author lucas.benero@arcsona.com
 */
public with sharing class ARC_ContactLookupController {
    
    /**
     * @description Search for contacts related to the Opportunity's Account via AccountContactRelation
     * @param searchTerm The search term to filter contacts by name or email (can be empty to get all)
     * @param opportunityId The Id of the Opportunity to get the Account from
     * @param limitCount Maximum number of results to return
     * @return List of Contact records matching the search criteria
     */
    @AuraEnabled(cacheable=true)
    public static List<Contact> searchContactsByOpportunity(String searchTerm, Id opportunityId, Integer limitCount) {
        if (opportunityId == null) {
            return new List<Contact>();
        }

        // Support both Opportunity IDs and Account IDs
        Id accountId;
        if (String.valueOf(opportunityId).startsWith('001')) {
            // It's already an Account Id
            accountId = opportunityId;
        } else {
            // It's an Opportunity Id — resolve to Account
            Opportunity opp = [
                SELECT Id, AccountId
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];
            accountId = opp.AccountId;
        }

        if (accountId == null) {
            return new List<Contact>();
        }
        
        Integer queryLimit = (limitCount != null && limitCount > 0) ? limitCount : 10;
        
        // Get Contact Ids from AccountContactRelation junction object
        Set<Id> relatedContactIds = new Set<Id>();
        for (AccountContactRelation acr : [
            SELECT ContactId
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND IsActive = true
        ]) {
            relatedContactIds.add(acr.ContactId);
        }
        
        if (relatedContactIds.isEmpty()) {
            return new List<Contact>();
        }
        
        // If no search term, return all contacts related to the account (up to limit)
        if (String.isBlank(searchTerm)) {
            return [
                SELECT Id, Name, FirstName, LastName, Email, Title, Phone, 
                       ARC_PortalAccess__c,
                       MailingStreet, MailingCity, MailingState, MailingPostalCode
                FROM Contact
                WHERE Id IN :relatedContactIds
                ORDER BY Name ASC
                LIMIT :queryLimit
            ];
        }
        
        // Search with filter
        String searchPattern = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        
        return [
            SELECT Id, Name, FirstName, LastName, Email, Title, Phone, 
                   ARC_PortalAccess__c,
                   MailingStreet, MailingCity, MailingState, MailingPostalCode
            FROM Contact
            WHERE Id IN :relatedContactIds
            AND (Name LIKE :searchPattern OR Email LIKE :searchPattern)
            ORDER BY Name ASC
            LIMIT :queryLimit
        ];
    }
    
}