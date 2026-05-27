/**
 * @description Controller for Company Contact Section data retrieval
 * @author lucas.benero@arcsona.com
 */
public with sharing class ARC_CompanyContactSectionController {
    
    // Roles to exclude from Other Contacts
    private static final Set<String> EXCLUDED_ROLES = new Set<String>{
        'Company Officer Contact',
        'Primary Business Contact',
        'Account Holder',
        'Billing Contact',
        'Ownership'
    };

    // ═══════════════════════════════════════════════════════════════════════
    // PRIVATE HELPER METHODS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @description Get Account Id from Opportunity OR return the Id if it's already an Account Id
     * @param opportunityId The Id of the Opportunity or Account
     * @return Account Id or null if not found
     */
    private static Id getAccountIdFromOpportunity(Id opportunityId) {
        if (opportunityId == null) {
            return null;
        }
        
        // Check if the Id is an Account Id (starts with '001')
        String idString = String.valueOf(opportunityId);
        if (idString.startsWith('001')) {
            return opportunityId; // It's already an Account Id
        }
        
        // It's an Opportunity Id, get the Account Id
        List<Opportunity> opps = [
            SELECT AccountId
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        
        return opps.isEmpty() ? null : opps[0].AccountId;
    }

    /**
     * @description Get Contact by ACR role with additional ACR fields
     * @param accountId The Account Id
     * @param role The ACR role to filter by
     * @return ContactData wrapper with Contact and ACR information
     */
    private static ContactData getContactDataByRole(Id accountId, String role) {
        if (accountId == null) {
            return null;
        }
        
        List<AccountContactRelation> acrList = [
            SELECT ContactId, Roles
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND Roles INCLUDES (:role)
            AND IsActive = true
            LIMIT 1
        ];
        
        if (acrList.isEmpty()) {
            return null;
        }
        
        Contact contact = [
            SELECT Id, Name, FirstName, LastName, Email, Title, Phone,
                   MailingStreet, MailingCity, MailingState, MailingPostalCode,
                   ARC_PortalAccess__c
            FROM Contact
            WHERE Id = :acrList[0].ContactId
            LIMIT 1
        ];
        
        ContactData result = new ContactData();
        result.contact = contact;
        result.acrId = acrList[0].Id;
        result.roles = acrList[0].Roles;
        result.portalAccess = contact.ARC_PortalAccess__c;
        
        return result;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC METHODS
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * @description Get the Primary Business Contact from AccountContactRelation
     * @param opportunityId The Id of the Opportunity
     * @return ContactData wrapper with Contact and ACR info or null
     */
    @AuraEnabled(cacheable=true)
    public static ContactData getPrimaryBusinessContact(Id opportunityId) {
        Id accountId = getAccountIdFromOpportunity(opportunityId);
        return getContactDataByRole(accountId, 'Primary Business Contact');
    }
    
    /**
     * @description Get the Company Officer Contact from AccountContactRelation
     * @param opportunityId The Id of the Opportunity
     * @return ContactData wrapper with Contact and ACR info or null
     */
    @AuraEnabled(cacheable=true)
    public static ContactData getCompanyOfficerContact(Id opportunityId) {
        Id accountId = getAccountIdFromOpportunity(opportunityId);
        return getContactDataByRole(accountId, 'Company Officer Contact');
    }

    /**
     * @description Get the Account Holder Contact from AccountContactRelation
     * @param opportunityId The Id of the Opportunity or Account
     * @return ContactData wrapper with Contact and ACR info or null
     */
    @AuraEnabled(cacheable=true)
    public static ContactData getAccountHolderContact(Id opportunityId) {
        Id accountId = getAccountIdFromOpportunity(opportunityId);
        return getContactDataByRole(accountId, 'Account Holder');
    }

    /**
     * @description Get the Billing Contact from AccountContactRelation
     * @param opportunityId The Id of the Opportunity or Account
     * @return ContactData wrapper with Contact and ACR info or null
     */
    @AuraEnabled(cacheable=true)
    public static ContactData getBillingContact(Id opportunityId) {
        Id accountId = getAccountIdFromOpportunity(opportunityId);
        return getContactDataByRole(accountId, 'Billing Contact');
    }
    
    /**
     * @description Get Other Contacts - contacts related via Contact.AccountId but NOT through ACR with excluded roles
     * @param opportunityId The Id of the Opportunity
     * @return List of Other Contact records
     */
    @AuraEnabled(cacheable=true)
    public static List<Contact> getOtherContacts(Id opportunityId) {
        Id accountId = getAccountIdFromOpportunity(opportunityId);
        
        if (accountId == null) {
            return new List<Contact>();
        }
        
        // Get Contact Ids that have excluded roles through ACR
        Set<Id> excludedContactIds = new Set<Id>();
        for (AccountContactRelation acr : [
            SELECT ContactId, Roles
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND IsActive = true
        ]) {
            if (acr.Roles != null) {
                for (String role : acr.Roles.split(';')) {
                    if (EXCLUDED_ROLES.contains(role.trim())) {
                        excludedContactIds.add(acr.ContactId);
                        break;
                    }
                }
            }
        }
        
        // Get all contacts related to the account, excluding those with special roles
        return [
            SELECT Id, Name, FirstName, LastName, Email, Title, Phone,
                   MailingStreet, MailingCity, MailingState, MailingPostalCode,
                   ARC_PortalAccess__c
            FROM Contact
            WHERE AccountId = :accountId
            AND Id NOT IN :excludedContactIds
            ORDER BY Name ASC
        ];
    }
    
    /**
     * @description Get Third Party Administrators - contacts related via ACR with TPA role
     * @param opportunityId The Id of the Opportunity
     * @return List of TPA Contact records with ACR info
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getTPAContacts(Id opportunityId) {
        Id accountId = getAccountIdFromOpportunity(opportunityId);
        
        if (accountId == null) {
            return new List<Map<String, Object>>();
        }
        
        List<AccountContactRelation> acrList = [
            SELECT ContactId, Contact.Name, Contact.FirstName, Contact.LastName, 
                   Contact.Email, Contact.Title, Contact.Phone, Contact.AccountId,
                   Contact.Account.Name, Contact.Account.BillingStreet, Contact.Account.BillingCity, 
                   Contact.Account.BillingState, Contact.Account.BillingPostalCode,
                   Contact.ARC_PortalAccess__c
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND Roles INCLUDES ('Third Party Administrator')
            AND IsActive = true
            ORDER BY Contact.Name ASC
        ];
        
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        for (AccountContactRelation acr : acrList) {
            Map<String, Object> tpaRecord = new Map<String, Object>();
            tpaRecord.put('id', acr.ContactId);
            tpaRecord.put('contactId', acr.ContactId);
            tpaRecord.put('accountId', acr.Contact.AccountId);
            tpaRecord.put('companyName', acr.Contact.Account != null ? acr.Contact.Account.Name : '');
            tpaRecord.put('firstName', acr.Contact.FirstName);
            tpaRecord.put('lastName', acr.Contact.LastName);
            tpaRecord.put('contactName',acr.Contact.FirstName + ' ' + acr.Contact.LastName);
            tpaRecord.put('email', acr.Contact.Email);
            tpaRecord.put('phone', acr.Contact.Phone);
            // Address from TPA Account (not Contact)
            tpaRecord.put('mailingAddress', acr.Contact.Account != null ? acr.Contact.Account.BillingStreet : '');
            tpaRecord.put('city', acr.Contact.Account != null ? acr.Contact.Account.BillingCity : '');
            tpaRecord.put('state', acr.Contact.Account != null ? acr.Contact.Account.BillingState : '');
            tpaRecord.put('zip', acr.Contact.Account != null ? acr.Contact.Account.BillingPostalCode : '');
            tpaRecord.put('portalAccess', acr.Contact.ARC_PortalAccess__c != null ? acr.Contact.ARC_PortalAccess__c : 'No Access');
            results.add(tpaRecord);
        }
        
        return results;
    }
    
    /**
     * @description Get Owner Contacts - contacts related via ACR with Ownership role
     * @param opportunityId The Id of the Opportunity
     * @return List of Owner Contact records with ownership info
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getOwnerContacts(Id opportunityId) {
        if (opportunityId == null) {
            return new Map<String, Object>{ 'owners' => new List<Map<String, Object>>(), 'sectionComplete' => false };
        }

        // Resolve Account Id — recordId may be an Account Id (001...) or an Opportunity Id
        Id accountId;
        Boolean sectionComplete = false;

        String idStr = String.valueOf(opportunityId);
        if (idStr.startsWith('001')) {
            // Already an Account Id
            accountId = opportunityId;
        } else {
            // Opportunity Id — fetch AccountId and section-complete flag
            List<Opportunity> opps = [
                SELECT AccountId, ARC_SFOwnershipComplete__c
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];
            if (opps.isEmpty() || opps[0].AccountId == null) {
                return new Map<String, Object>{ 'owners' => new List<Map<String, Object>>(), 'sectionComplete' => false };
            }
            accountId = opps[0].AccountId;
            sectionComplete = opps[0].ARC_SFOwnershipComplete__c == true;
        }
        
        List<AccountContactRelation> acrList = [
            SELECT ContactId, Contact.Name, Contact.FirstName, Contact.LastName, 
                   Contact.Email, Contact.Title, Contact.Phone, Contact.vlocity_ins__MiddleName__c,
                   Contact.ARC_OwnershipPercentage__c, Contact.ARC_Eligible__c,
                   Contact.ARC_PortalAccess__c, Roles
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND Roles INCLUDES ('Ownership')
            AND IsActive = true
            ORDER BY Contact.Name ASC
        ];
        
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        for (AccountContactRelation acr : acrList) {
            Map<String, Object> ownerRecord = new Map<String, Object>();
            ownerRecord.put('id', acr.ContactId);
            ownerRecord.put('contactId', acr.ContactId);
            ownerRecord.put('firstName', acr.Contact.FirstName);
            ownerRecord.put('lastName', acr.Contact.LastName);
            ownerRecord.put('middleInitial', acr.Contact.vlocity_ins__MiddleName__c); 
            ownerRecord.put('email', acr.Contact.Email);
            ownerRecord.put('phone', acr.Contact.Phone);
            ownerRecord.put('ownershipPercentage', acr.Contact.ARC_OwnershipPercentage__c);
            ownerRecord.put('isEligible', acr.Contact.ARC_Eligible__c != null ? acr.Contact.ARC_Eligible__c : false);
            ownerRecord.put('portalAccess', acr.Contact.ARC_PortalAccess__c != null ? acr.Contact.ARC_PortalAccess__c : 'No Access');
            results.add(ownerRecord);
        }
        
        return new Map<String, Object>{ 'owners' => results, 'sectionComplete' => sectionComplete };
    }
    
    /**
     * @description Search for Business_Account type Accounts with their primary Contact (for TPA lookup)
     * @param searchTerm The search term to filter accounts by name (can be empty to get all)
     * @param limitCount Maximum number of results to return
     * @return List of Account records with Contact subquery
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> searchBusinessAccounts(String searchTerm, Integer limitCount) {
        Integer queryLimit = (limitCount != null && limitCount > 0) ? limitCount : 10;
        
        // Get Business_Account RecordType Id
        Id businessAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Business_Account').getRecordTypeId();
        
        // If no search term, return recent Business Accounts (up to limit)
        if (String.isBlank(searchTerm)) {
            return [
                SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                       (SELECT Id, FirstName, LastName, Email, Phone, ARC_PortalAccess__c 
                        FROM Contacts 
                        ORDER BY CreatedDate ASC 
                        LIMIT 1)
                FROM Account
                WHERE RecordTypeId = :businessAccountRecordTypeId
                ORDER BY Name ASC
                LIMIT :queryLimit
            ];
        }
        
        // Search with filter
        String searchPattern = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        
        return [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                   (SELECT Id, FirstName, LastName, Email, Phone, ARC_PortalAccess__c 
                    FROM Contacts 
                    ORDER BY CreatedDate ASC 
                    LIMIT 1)
            FROM Account
            WHERE RecordTypeId = :businessAccountRecordTypeId
            AND Name LIKE :searchPattern
            ORDER BY Name ASC
            LIMIT :queryLimit
        ];
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // WRAPPER CLASSES
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * @description Wrapper class for Contact data with ACR information
     */
    public class ContactData {
        @AuraEnabled public Contact contact { get; set; }
        @AuraEnabled public Id acrId { get; set; }
        @AuraEnabled public String roles { get; set; }
        @AuraEnabled public String portalAccess { get; set; }
        
        public ContactData() {
            this.contact = null;
            this.acrId = null;
            this.roles = '';
            this.portalAccess = 'No Access';
        }
    }
}