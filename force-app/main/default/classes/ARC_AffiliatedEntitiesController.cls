public with sharing class ARC_AffiliatedEntitiesController {
    
    /**
     * Retrieves affiliated entities (child Accounts) for the given opportunity
     * @param opportunityId - The ID of the opportunity
     * @return List of Account records representing affiliated entities
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAffiliatedEntities(Id opportunityId) {
        try {
            if (opportunityId == null) {
                return new Map<String, Object>{ 'entities' => new List<Account>(), 'sectionComplete' => false };
            }

            List<Opportunity> opps = [
                SELECT AccountId, ARC_SFAffiliatedComplete__c
                FROM Opportunity 
                WHERE Id = :opportunityId 
                LIMIT 1
            ];

            if (opps.isEmpty() || opps[0].AccountId == null) {
                return new Map<String, Object>{ 'entities' => new List<Account>(), 'sectionComplete' => false };
            }

            Opportunity opp = opps[0];
            Boolean sectionComplete = opp.ARC_SFAffiliatedComplete__c == true;
            
            // Query child Accounts (affiliated entities)
            List<Account> affiliatedEntities = [
                SELECT 
                    Id, 
                    Name,
                    ARC_FederalEmployerTaxIDNumber__c,
                    ARC_Number_Of_Employees__c
                FROM Account
                WHERE ParentId = :opp.AccountId
                ORDER BY Name ASC
            ];
            
            return new Map<String, Object>{ 'entities' => affiliatedEntities, 'sectionComplete' => sectionComplete };
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving affiliated entities: ' + e.getMessage());
        }
    }
}