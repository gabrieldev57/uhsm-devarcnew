/**
 * ARC_BusinessFormController - Main Apex controller for the Business Application Form
 * 
 * @description Handles all backend operations for the Business Application Form.
 *              Contains methods for saving different sections and shared utilities.
 * 
 * @author lucas.benero@arcsona.com
 */
public without sharing class ARC_BusinessFormController {
    
    // ═══════════════════════════════════════════════════════════════════════
    // CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════
    
    private static final String ROLE_PRIMARY_CONTACT = 'Primary Business Contact';
    private static final String ROLE_COMPANY_OFFICER = 'Company Officer Contact';
    private static final String ROLE_OTHER = 'Other';
    private static final String ROLE_TPA = 'Third Party Administrator';
    private static final String ROLE_ACCOUNT_HOLDER = 'Account Holder';
    private static final String ROLE_BILLING_CONTACT = 'Billing Contact';
    private static final String ROLE_OWNERSHIP = 'Ownership';
    
    private static final String RECORDTYPE_BUSINESS_ACCOUNT = 'Business_Account';
    
    private static final String COUNTRY_US = 'United States';
    
    // ═══════════════════════════════════════════════════════════════════════
    // HELPER METHODS - COMMON UTILITIES
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * Get Account Id from Opportunity OR return the Id if it's already an Account Id
     * Reusable method to avoid duplicate queries
     */
    private static Id getAccountIdFromOpportunity(Id opportunityId) {
        // Check if the Id is an Account Id (starts with '001')
        String idString = String.valueOf(opportunityId);
        if (idString.startsWith('001')) {
            return opportunityId; // It's already an Account Id
        }
        
        // It's an Opportunity Id, get the Account Id
        Opportunity opp = [
            SELECT Id, AccountId 
            FROM Opportunity 
            WHERE Id = :opportunityId 
            LIMIT 1
        ];
        
        if (opp.AccountId == null) {
            throw new AuraHandledException('Account not found for this Opportunity');
        }
        
        return opp.AccountId;
    }
    
    /**
     * Handle exceptions and populate SaveResult
     * Centralized error handling to maintain consistency
     */
    private static void handleException(SaveResult result, Exception e) {
        result.isSuccess = false;
        result.message = e.getMessage();
        
        if (e instanceof DmlException) {
            result.message = 'Database error: ' + ((DmlException)e).getDmlMessage(0);
            result.errorType = 'DML_ERROR';
        } else if (e instanceof AuraHandledException) {
            result.errorType = 'VALIDATION_ERROR';
        } else {
            result.message = 'Unexpected error: ' + e.getMessage();
            result.errorType = 'UNEXPECTED_ERROR';
        }
    }
    
    /**
     * Convert Object to Decimal safely
     */
    private static Decimal toDecimal(Object value) {
        if (value == null || String.valueOf(value).trim() == '') return null;
        return Decimal.valueOf(String.valueOf(value));
    }
    
    /**
     * Deserialize object to Map safely
     */
    private static Map<String, Object> deserializeToMap(Object obj) {
        if (obj == null) return null;
        return (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
    }
    
    /**
     * Bulk update ACR roles for multiple contacts
     * Centralizes the ACR query and DML pattern used across save methods
     * 
     * @param accountId - The Account Id
     * @param roleContactMap - Map of role -> new contactId
     * @param oldRoleContactMap - Map of role -> old contactId to remove role from
     */
    private static void bulkUpdateContactRoles(
        Id accountId,
        Map<String, Id> roleContactMap,
        Map<String, Id> oldRoleContactMap
    ) {
        // Collect all contact IDs for ACR query
        Set<Id> allContactIds = new Set<Id>();
        for (Id contactId : roleContactMap.values()) {
            if (contactId != null) allContactIds.add(contactId);
        }
        for (Id contactId : oldRoleContactMap.values()) {
            if (contactId != null) allContactIds.add(contactId);
        }
        
        if (allContactIds.isEmpty()) return;
        
        // Query existing ACRs
        Map<Id, AccountContactRelation> existingAcrsMap = new Map<Id, AccountContactRelation>();
        List<AccountContactRelation> acrs = [
            SELECT Id, ContactId, Roles
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND ContactId IN :allContactIds
        ];
        
        for (AccountContactRelation acr : acrs) {
            existingAcrsMap.put(acr.ContactId, acr);
        }
        
        // Use Maps to deduplicate (same contact may have multiple roles)
        Map<Id, AccountContactRelation> acrsToUpdateMap = new Map<Id, AccountContactRelation>();
        List<AccountContactRelation> acrsToInsert = new List<AccountContactRelation>();
        
        // Process each role
        for (String role : roleContactMap.keySet()) {
            Id newContactId = roleContactMap.get(role);
            Id oldContactId = oldRoleContactMap.get(role);
            
            if (newContactId != null) {
                // Get or create ACR for new contact
                AccountContactRelation newAcr = existingAcrsMap.get(newContactId);
                if (newAcr != null) {
                    // Existing ACR - add role
                    newAcr.Roles = addRole(newAcr.Roles, role);
                    acrsToUpdateMap.put(newAcr.Id, newAcr);
                } else {
                    // No existing ACR - check if we already created one for this contact
                    AccountContactRelation pendingAcr = null;
                    for (AccountContactRelation acr : acrsToInsert) {
                        if (acr.ContactId == newContactId) {
                            pendingAcr = acr;
                            break;
                        }
                    }
                    
                    if (pendingAcr != null) {
                        // Already created ACR for this contact, just add role
                        pendingAcr.Roles = addRole(pendingAcr.Roles, role);
                    } else {
                        // Create new ACR
                        AccountContactRelation newAcrToInsert = new AccountContactRelation(
                            AccountId = accountId,
                            ContactId = newContactId,
                            Roles = role
                        );
                        acrsToInsert.add(newAcrToInsert);
                    }
                }
                
                // Remove role from old contact if different
                if (oldContactId != null && oldContactId != newContactId) {
                    AccountContactRelation oldAcr = existingAcrsMap.get(oldContactId);
                    if (oldAcr != null) {
                        oldAcr.Roles = removeRole(oldAcr.Roles, role);
                        if (String.isBlank(oldAcr.Roles)) {
                            oldAcr.Roles = ROLE_OTHER;
                        }
                        acrsToUpdateMap.put(oldAcr.Id, oldAcr);
                    }
                }
            }
        }
        
        // Bulk DML
        if (!acrsToInsert.isEmpty()) {
            insert acrsToInsert;
        }
        if (!acrsToUpdateMap.isEmpty()) {
            update acrsToUpdateMap.values();
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // BUSINESS DETAILS SECTION
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * Save Account Manager - Simple dedicated method for Account Manager field only
     * 
     * @param opportunityId - The Opportunity Id (used to get Account context)
     * @param accountManagerId - The User Id to set as Account Manager
     * @return SaveResult with success status and any errors
     */
    @AuraEnabled
    public static SaveResult saveAccountManager(Id opportunityId, Id accountManagerId) {
        SaveResult result = new SaveResult();
        
        try {
            // Validate input
            if (opportunityId == null) {
                throw new AuraHandledException('Opportunity Id is required');
            }
            
            // Get Account Id
            Id accountId = getAccountIdFromOpportunity(opportunityId);
            
            // Update Account with Account Manager
            Account account = new Account(Id = accountId);
            account.ARC_AccountManager__c = accountManagerId;
            
            update account;
            
            result.isSuccess = true;
            result.recordId = account.Id;
            result.message = 'Account Manager saved successfully';
            
        } catch (Exception e) {
            handleException(result, e);
        }
        
        return result;
    }
    
    /**
     * Save Business Details - Updates Account record with business information
     * 
     * @param opportunityId - The Opportunity Id (used to get Account context)
     * @param businessData - Map containing business details
     * @return SaveResult with success status and any errors
     */
    @AuraEnabled
    public static SaveResult saveBusinessDetails(Id opportunityId, Map<String, Object> businessData) {
        SaveResult result = new SaveResult();
        
        try {
            // Validate input
            if (opportunityId == null) {
                throw new AuraHandledException('Opportunity Id is required');
            }
            if (businessData == null || businessData.isEmpty()) {
                throw new AuraHandledException('Business data is required');
            }
            
            // Get Account Id
            Id accountId = getAccountIdFromOpportunity(opportunityId);
            
            // Get Opportunity and Account records to update
            Opportunity opp = [SELECT Id, ARC_RequestedEffectiveDate__c, ContractId FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            Account account = [SELECT Id FROM Account WHERE Id = :accountId LIMIT 1];
            
            // Track if Opportunity needs updating
            Boolean updateOpp = false;
            
            // Update Opportunity fields - only if provided
            if (businessData.containsKey('requestedEffectiveDate')) {
                Object requestedEffectiveDateObj = businessData.get('requestedEffectiveDate');
                if (requestedEffectiveDateObj != null) {
                    opp.ARC_RequestedEffectiveDate__c = Date.valueOf((String) requestedEffectiveDateObj);
                } else {
                    opp.ARC_RequestedEffectiveDate__c = null;
                }
                updateOpp = true;
            }
            
            // NEW FIELDS - Company Info
            if (businessData.containsKey('companyName')) {
                account.Name = (String) businessData.get('companyName');
            }
            if (businessData.containsKey('legalCompanyName')) {
                account.ARC_LegalCompanyName__c = (String) businessData.get('legalCompanyName');
            }
            if (businessData.containsKey('accountManagerId')) {
                String accountManagerId = (String) businessData.get('accountManagerId');
                account.ARC_AccountManager__c = String.isNotBlank(accountManagerId) ? (Id) accountManagerId : null;
            }
            if (businessData.containsKey('companyStreet')) {
                account.BillingStreet = (String) businessData.get('companyStreet');
            }
            if (businessData.containsKey('companyCity')) {
                account.BillingCity = (String) businessData.get('companyCity');
            }
            if (businessData.containsKey('companyState')) {
                account.BillingState = (String) businessData.get('companyState');
            }
            if (businessData.containsKey('companyZip')) {
                account.BillingPostalCode = (String) businessData.get('companyZip');
            }
            
            // NEW FIELDS - Other States
            if (businessData.containsKey('employeesInOtherStates')) {
                account.ARC_EmployeesInOtherStates__c = (Boolean) businessData.get('employeesInOtherStates');
            }
            if (businessData.containsKey('otherStates')) {
                account.ARC_OtherStates__c = (String) businessData.get('otherStates');
            }
            if (businessData.containsKey('employeesInOtherStatesCount')) {
                account.ARC_EmployeesInOtherStatesCount__c = toDecimal(businessData.get('employeesInOtherStatesCount'));
            }
            
            // NEW FIELDS - Benefits & COBRA
            if (businessData.containsKey('offerBenefitsDuringWaitingPeriod')) {
                account.ARC_OfferSharingBenefitsDuringWaitingPer__c = (Boolean) businessData.get('offerBenefitsDuringWaitingPeriod');
            }
            if (businessData.containsKey('subjectToCalCOBRA')) {
                account.ARC_SubjectToCalCOBRA__c = (Boolean) businessData.get('subjectToCalCOBRA');
            }
            if (businessData.containsKey('calCOBRAEnrolleesCount')) {
                account.ARC_CalCOBRAEnrolleesCount__c = toDecimal(businessData.get('calCOBRAEnrolleesCount'));
            }
            if (businessData.containsKey('subjectToCOBRA')) {
                account.ARC_SubjectToCOBRA__c = (Boolean) businessData.get('subjectToCOBRA');
            }
            if (businessData.containsKey('cobraEnrolleesCount')) {
                account.ARC_COBRAEnrolleesCount__c = toDecimal(businessData.get('cobraEnrolleesCount'));
            }
            
            // Populate Account fields from business data
            account.ARC_FederalEmployerTaxIDNumber__c = (String) businessData.get('federalTaxId');
            account.ARC_Doing_Business_As_Name__c = (String) businessData.get('doingBusinessAs');
            account.Sic = (String) businessData.get('sicCode');
            account.SicDesc = (String) businessData.get('sicCodeDescription');
            account.ARC_NAICSCode__c = (String) businessData.get('naicsCode');
            account.ARC_TypeOfBusiness__c = (String) businessData.get('typeOfBusiness');
            account.ARC_OtherTypeOfBusiness__c = (String) businessData.get('otherTypeOfBusiness');
            
            // Date field - handle as String ISO format from LWC
            Object dateEstablishedObj = businessData.get('dateEstablished');
            if (dateEstablishedObj != null) {
                account.vlocity_ins__DateFounded__c = Date.valueOf((String) dateEstablishedObj);
            }
            
            account.ARC_Entity_Type__c = (String) businessData.get('organizationType');
            account.ARC_OtherEntityType__c = (String) businessData.get('otherOrganizationType');
            account.ARC_PayPeriod__c = (String) businessData.get('payPeriod');
            account.ARC_MedicalLeaveAllowedMonths__c = (String) businessData.get('medicalLeaveMonths');
            
            // Number fields using helper
            account.ARC_TotalEmployees__c = toDecimal(businessData.get('totalEmployees'));
            account.ARC_NumberOfIneligibleEmployees__c = toDecimal(businessData.get('ineligibleEmployees'));
            
            account.ARC_NewEmployeeWaitingPeriod__c = (String) businessData.get('newEmployeeWaitingPeriod');
            
            // Boolean fields
            account.ARC_MeetsSmallEmployerDefinition__c = (Boolean) businessData.get('meetsSmallEmployerDefinition');
            account.ARC_AllowDependents__c = (Boolean) businessData.get('allowDependentsToEnroll');
            
            // Picklist field (Yes/No)
            account.ARC_IsNonProfit__c = (String) businessData.get('isNonProfit');
            
            // Association fields
            account.ARC_MemberOfAssociation__c = (Boolean) businessData.get('isAssociationMember');
            account.ARC_AssociationName__c = (String) businessData.get('associationName');
            
            // Other Coverage fields
            account.ARC_OfferingOtherCoverage__c = (Boolean) businessData.get('hasOtherCoverage');
            account.ARC_OtherCoverageCarrierName__c = account.ARC_OfferingOtherCoverage__c ? (String) businessData.get('carrierName') : null;
            account.ARC_OtherCoverageRenewalMonth__c =  account.ARC_OfferingOtherCoverage__c ? (String) businessData.get('renewalMonth') : null;
            account.ARC_OtherCoverageEmployeesCovered__c =  account.ARC_OfferingOtherCoverage__c ? toDecimal(businessData.get('employeesCovered')) : null;
            
            // Handle Open Enrollment dates for Opportunity
            if (businessData.containsKey('openEnrollmentStartDate')) {
                Object oeStartObj = businessData.get('openEnrollmentStartDate');
                if (oeStartObj != null) {
                    opp.ARC_OEStartDate__c = Date.valueOf((String) oeStartObj);
                } else {
                    opp.ARC_OEStartDate__c = null;
                }
                updateOpp = true;
            }
            if (businessData.containsKey('openEnrollmentEndDate')) {
                Object oeEndObj = businessData.get('openEnrollmentEndDate');
                if (oeEndObj != null) {
                    opp.ARC_OEEndDate__c = Date.valueOf((String) oeEndObj);
                } else {
                    opp.ARC_OEEndDate__c = null;
                }
                updateOpp = true;
            }
            
            // Update Opportunity if changes were made
            if (updateOpp) {
                update opp;
            }
            
            // Always update Account
            update account;
            
            // Handle Contract fields for Open Enrollment dates and Effective Date (if Contract exists)
            if (businessData.containsKey('openEnrollmentStartDate') || businessData.containsKey('openEnrollmentEndDate') || businessData.containsKey('requestedEffectiveDate')) {
                Object requestedEffectiveDateObj = businessData.get('requestedEffectiveDate');
                Object oeStartObj = businessData.get('openEnrollmentStartDate');
                Object oeEndObj = businessData.get('openEnrollmentEndDate');

                List<Contract> contracts = new List<Contract>();
                if (opp.ContractId != null) {
                    contracts = [
                        SELECT Id, Status, CreatedDate
                        FROM Contract
                        WHERE Id = :opp.ContractId
                        LIMIT 1
                    ];
                }
                
                if (!contracts.isEmpty()) {
                    Contract contract = contracts[0];
                    if (oeStartObj != null) {
                        contract.ARC_OEStartDate__c = Date.valueOf((String) oeStartObj);
                    } else {
                        contract.ARC_OEStartDate__c = null;
                    }
                    if (oeEndObj != null) {
                        contract.ARC_OEEndDate__c = Date.valueOf((String) oeEndObj);
                    } else {
                        contract.ARC_OEEndDate__c = null;
                    }
                    // Save Requested Effective Date to Contract Effective Date
                    if (requestedEffectiveDateObj != null) {
                        contract.ARC_EffectiveDate__c = Date.valueOf((String) requestedEffectiveDateObj);
                    } else {
                        contract.ARC_EffectiveDate__c = null;
                    }
                    update contract;
                }
            }
            
            result.isSuccess = true;
            result.recordId = account.Id;
            result.message = 'Business details saved successfully';
            
        } catch (Exception e) {
            handleException(result, e);
        }
        
        return result;
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // PAYMENT INFORMATION SECTION
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * Save Payment Information - Creates or updates ChargentOrder record
     * ChargentOrder is related to Account
     * 
     * @param opportunityId - The Opportunity Id (used to get Account context)
     * @param chargentOrderId - Existing ChargentOrder Id (null if creating new)
     * @param paymentData - Map containing payment information
     * @return SaveResult with success status and any errors
     */
    @AuraEnabled
    public static SaveResult savePaymentInformation(Id opportunityId, Id chargentOrderId, Map<String, Object> paymentData) {
        SaveResult result = new SaveResult();
        Savepoint sp = Database.setSavepoint();
        
        try {
            // Validate input
            if (opportunityId == null) {
                throw new AuraHandledException('Opportunity Id is required');
            }
            if (paymentData == null || paymentData.isEmpty()) {
                throw new AuraHandledException('Payment data is required');
            }
            
            // Get Opportunity with related Account and RecordType
            Opportunity opp = [
                SELECT Id, AccountId, ContractId, RecordType.DeveloperName
                FROM Opportunity 
                WHERE Id = :opportunityId 
                LIMIT 1
            ];
            
            Id accountId = opp.AccountId;
            Boolean isRenewal = opp.RecordType != null && opp.RecordType.DeveloperName == 'ARC_Renewal';

            Id contractId = null;
            if (isRenewal) {
                // ── Renewal path ──────────────────────────────────────────────────────
                // ContractId populated → use it directly
                // ContractId null      → find the Activated Contract for this Account
                if (opp.ContractId != null) {
                    contractId = opp.ContractId;
                } else {
                    List<Contract> activeContracts = [
                        SELECT Id
                        FROM Contract
                        WHERE AccountId = :accountId
                          AND Status = 'Activated'
                        ORDER BY StartDate DESC
                        LIMIT 1
                    ];
                    if (!activeContracts.isEmpty()) {
                        contractId = activeContracts[0].Id;
                    }
                }
            } else {
                // ── Small Group (default) path ─────────────────────────────────────
                contractId = opp.ContractId; // may be null for a new enrollment
            }
            
            // Collections for bulk DML
            List<Contact> contactsToUpsert = new List<Contact>();
            Map<String, Id> roleContactMap = new Map<String, Id>();
            Map<String, Id> oldRoleContactMap = new Map<String, Id>();
            
            // Track which contact is for which role (by list index or direct ID)
            Integer accountHolderIndex = -1;
            Integer billingContactIndex = -1;
            
            // Query current roles
            List<AccountContactRelation> currentAcrs = [
                SELECT ContactId, Roles
                FROM AccountContactRelation
                WHERE AccountId = :accountId
                AND (Roles INCLUDES (:ROLE_ACCOUNT_HOLDER) OR Roles INCLUDES (:ROLE_BILLING_CONTACT) OR Roles INCLUDES (:ROLE_PRIMARY_CONTACT))
            ];
            
            Id primaryContactId = null;
            for (AccountContactRelation acr : currentAcrs) {
                if (acr.Roles != null && acr.Roles.contains(ROLE_ACCOUNT_HOLDER)) {
                    oldRoleContactMap.put(ROLE_ACCOUNT_HOLDER, acr.ContactId);
                }
                if (acr.Roles != null && acr.Roles.contains(ROLE_BILLING_CONTACT)) {
                    oldRoleContactMap.put(ROLE_BILLING_CONTACT, acr.ContactId);
                }
                if (acr.Roles != null && acr.Roles.contains(ROLE_PRIMARY_CONTACT)) {
                    primaryContactId = acr.ContactId;
                }
            }
            
            // Process Account Holder
            Object accountHolderObj = paymentData.get('accountHolder');
            if (accountHolderObj != null) {
                Map<String, Object> accountHolder = deserializeToMap(accountHolderObj);
                
                if ((Boolean) accountHolder.get('sameAsPrimary') == true) {
                    // Validate Primary Contact exists
                    if (primaryContactId == null) {
                        AuraHandledException ex = new AuraHandledException('Primary Business Contact must be saved before selecting "Same as Primary" for Account Holder. Please save the Contact Section first.');
                        ex.setMessage('Primary Business Contact must be saved before selecting "Same as Primary" for Account Holder. Please save the Contact Section first.');
                        throw ex;
                    }
                    // Use primary contact as account holder
                    roleContactMap.put(ROLE_ACCOUNT_HOLDER, primaryContactId);
                } else {
                    // Build account holder contact
                    Object dataObj = accountHolder.get('data');
                    if (dataObj != null) {
                        Map<String, Object> data = deserializeToMap(dataObj);
                        String contactId = (String) accountHolder.get('contactId');
                        if (String.isNotBlank(contactId)) {
                            data.put('contactId', contactId);
                        }
                        
                        Contact contact = buildContact(data, accountId, 'Account Holder');
                        // Check if this existing contact is already in list
                        if (contact.Id != null) {
                            Boolean alreadyInList = false;
                            for (Integer i = 0; i < contactsToUpsert.size(); i++) {
                                if (contactsToUpsert[i].Id == contact.Id) {
                                    accountHolderIndex = i;
                                    alreadyInList = true;
                                    break;
                                }
                            }
                            if (!alreadyInList) {
                                contactsToUpsert.add(contact);
                                accountHolderIndex = contactsToUpsert.size() - 1;
                            }
                        } else {
                            // New contact
                            contactsToUpsert.add(contact);
                            accountHolderIndex = contactsToUpsert.size() - 1;
                        }
                    }
                }
            }
            
            // Process Billing Contact
            Object billingContactObj = paymentData.get('billingContact');
            Boolean billingSameAsAccountHolder = false;
            if (billingContactObj != null) {
                Map<String, Object> billingContact = deserializeToMap(billingContactObj);
                billingSameAsAccountHolder = (Boolean) billingContact.get('sameAsAccountHolder') == true;
                
                if (billingSameAsAccountHolder) {
                    // Billing contact is same as Account Holder - use same index
                    billingContactIndex = accountHolderIndex;
                } else {
                    // Different contact - process separately
                    Object dataObj = billingContact.get('data');
                    if (dataObj != null) {
                        Map<String, Object> data = deserializeToMap(dataObj);
                        String contactId = (String) billingContact.get('contactId');
                        if (String.isNotBlank(contactId)) {
                            data.put('contactId', contactId);
                        }
                        
                        String defaultTitle = 'Billing Contact';
                        if (String.isNotBlank((String) data.get('title'))) {
                            defaultTitle = null;
                        }
                        
                        Contact contact = buildContact(data, accountId, defaultTitle);
                        
                        // Check if this existing contact is already in list (same as Account Holder)
                        if (contact.Id != null) {
                            Boolean alreadyInList = false;
                            for (Integer i = 0; i < contactsToUpsert.size(); i++) {
                                if (contactsToUpsert[i].Id == contact.Id) {
                                    billingContactIndex = i;
                                    billingSameAsAccountHolder = true;
                                    alreadyInList = true;
                                    break;
                                }
                            }
                            if (!alreadyInList) {
                                contactsToUpsert.add(contact);
                                billingContactIndex = contactsToUpsert.size() - 1;
                            }
                        } else {
                            // New contact
                            contactsToUpsert.add(contact);
                            billingContactIndex = contactsToUpsert.size() - 1;
                        }
                    }
                }
            }
            
            // BULK UPSERT Contacts
            if (!contactsToUpsert.isEmpty()) {
                upsert contactsToUpsert;
                
                // Map role contact IDs after upsert using tracked indices
                if (accountHolderIndex >= 0) {
                    roleContactMap.put(ROLE_ACCOUNT_HOLDER, contactsToUpsert[accountHolderIndex].Id);
                }
                
                if (billingContactIndex >= 0) {
                    roleContactMap.put(ROLE_BILLING_CONTACT, contactsToUpsert[billingContactIndex].Id);
                }
            } else if (billingSameAsAccountHolder && roleContactMap.containsKey(ROLE_ACCOUNT_HOLDER)) {
                // No contacts to upsert, but billing should use account holder (which is primary)
                roleContactMap.put(ROLE_BILLING_CONTACT, roleContactMap.get(ROLE_ACCOUNT_HOLDER));
            }
            
            // Update ACR roles (BULKIFIED)
            bulkUpdateContactRoles(accountId, roleContactMap, oldRoleContactMap);
            
            // Process ChargentOrder
            ChargentOrders__ChargentOrder__c chargentOrder;
            if (chargentOrderId != null) {
                chargentOrder = new ChargentOrders__ChargentOrder__c(Id = chargentOrderId);
            } else {
                chargentOrder = new ChargentOrders__ChargentOrder__c();
                chargentOrder.ChargentOrders__Account__c = accountId;
            }
            
            populateChargentOrderFields(chargentOrder, paymentData, contractId);
            upsert chargentOrder;
            
            // If Contract exists, link ChargentOrder to Contract's ARC_RecurringMonthlyOrder__c
            if (contractId != null) {
                Contract contractToUpdate = new Contract(Id = contractId);
                contractToUpdate.ARC_RecurringMonthlyOrder__c = chargentOrder.Id;
                update contractToUpdate;
            }
            
            result.isSuccess = true;
            result.recordId = chargentOrder.Id;
            result.message = 'Payment information saved successfully';
            
            // Return contact IDs
            result.data.put('accountHolderContactId', roleContactMap.get(ROLE_ACCOUNT_HOLDER));
            result.data.put('billingContactId', roleContactMap.get(ROLE_BILLING_CONTACT));
            
        } catch (Exception e) {
            Database.rollback(sp);
            result.isSuccess = false;
            
            // Handle AuraHandledException specifically to preserve custom message
            if (e instanceof AuraHandledException) {
                // The message is already set on the AuraHandledException, get it directly
                String errorMessage = e.getMessage();
                // Remove "Script-thrown exception" prefix if present
                if (errorMessage != null && !errorMessage.contains('Script-thrown exception')) {
                    result.message = errorMessage;
                } else {
                    // If getMessage() returns generic text, the original message might be lost
                    // Try to extract from the exception itself
                    result.message = String.valueOf(e).substringAfter(': ');
                }
            } else {
                result.message = e.getMessage();
            }
            
            result.errorType = e.getTypeName();
            System.debug(LoggingLevel.ERROR, 'Payment save error type: ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, 'Payment save error message: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Add a role to the Roles multipicklist if not already present
     * "Other" role is removed when adding a real role (Other is only used when no other roles exist)
     */
    private static String addRole(String currentRoles, String roleToAdd) {
        Set<String> roles = new Set<String>();
        
        // Parse existing roles
        if (String.isNotBlank(currentRoles)) {
            for (String role : currentRoles.split(';')) {
                String trimmedRole = role.trim();
                // Skip "Other" role when adding a real role
                if (trimmedRole != ROLE_OTHER) {
                    roles.add(trimmedRole);
                }
            }
        }
        
        // Add new role
        roles.add(roleToAdd);
        
        // Return semicolon-separated list
        List<String> roleList = new List<String>(roles);
        return String.join(roleList, ';');
    }
    
    /**
     * Remove a role from the Roles multipicklist
     * If no roles remain, set to "Other"
     */
    private static String removeRole(String currentRoles, String roleToRemove) {
        Set<String> roles = new Set<String>();
        
        // Parse existing roles
        if (String.isNotBlank(currentRoles)) {
            for (String role : currentRoles.split(';')) {
                String trimmedRole = role.trim();
                if (trimmedRole != roleToRemove) {
                    roles.add(trimmedRole);
                }
            }
        }
        
        // If no roles remain, set to "Other"
        if (roles.isEmpty()) {
            return ROLE_OTHER;
        }
        
        // Return semicolon-separated list
        List<String> roleList = new List<String>(roles);
        return String.join(roleList, ';');
    }
    
    /**
     * Get active payment gateways for Credit Card and Bank Account
     * 
     * @return Map with 'cc' and 'ba' keys containing gateway Ids
     */
    private static Map<String, Id> getActiveGateways() {
        Map<String, Id> gateways = new Map<String, Id>();
        
        List<ChargentBase__Gateway__c> gatewayList = [
            SELECT Id, ChargentBase__Available_Payment_Methods__c 
            FROM ChargentBase__Gateway__c 
            WHERE ChargentBase__Active__c = true 
            AND (ChargentBase__Available_Payment_Methods__c INCLUDES ('Credit Card') 
                OR ChargentBase__Available_Payment_Methods__c INCLUDES ('Bank Account'))
        ];
        
        for (ChargentBase__Gateway__c gateway : gatewayList) {
            if (gateway.ChargentBase__Available_Payment_Methods__c.contains('Credit Card')) {
                gateways.put('cc', gateway.Id);
            }
            if (gateway.ChargentBase__Available_Payment_Methods__c.contains('Bank Account')) {
                gateways.put('ba', gateway.Id);
            }
        }
        
        return gateways;
    }
    
    /**
     * Populate ChargentOrder fields from payment data map
     * Billing address comes from the Payment Section's billing address field
     */
    private static void populateChargentOrderFields(
        ChargentOrders__ChargentOrder__c order, 
        Map<String, Object> paymentData,
        Id contractId
    ) {
        // Set Contract if exists
        if (contractId != null) {
            order.ARC_Contract__c = contractId;
        }

        // Get active gateways
        Map<String, Id> gateways = getActiveGateways();
        
        // Get payment method
        String paymentMethod = (String) paymentData.get('method');
        order.ChargentOrders__Payment_Method__c = paymentMethod == 'bank' ? 'Bank Account' : 'Credit Card';

        
        // Set description 
        order.ChargentOrders__Description__c = 'Recurring Monthly Order';
        
        // Billing Address - from the payment section's billing address field
        Object billingAddressObj = paymentData.get('billingAddress');
        if (billingAddressObj != null) {
            Map<String, Object> billingAddress = deserializeToMap(billingAddressObj);
            order.ChargentOrders__Billing_Address__c = (String) billingAddress.get('street');
            order.ChargentOrders__Billing_City__c = (String) billingAddress.get('city');
            order.ChargentOrders__Billing_State__c = (String) billingAddress.get('state');
            order.ChargentOrders__Billing_Zip_Postal__c = (String) billingAddress.get('zipCode');
        }
        
        // Payment-specific fields
        if (paymentMethod == 'bank') {
            // Bank Account fields
            Object bankDataObj = paymentData.get('data');
            if (bankDataObj != null) {
                Map<String, Object> bankData = deserializeToMap(bankDataObj);
                order.ChargentOrders__Bank_Name__c = (String) bankData.get('financialInstitutionName');
                order.ChargentOrders__Bank_Account_Name__c = (String) bankData.get('financialInstitutionName');
                // Only update routing/account numbers if new values provided (not null)
                String routingNumber = (String) bankData.get('routingNumber');
                String accountNumber = (String) bankData.get('accountNumber');
                if (String.isNotBlank(routingNumber)) {
                    order.ChargentOrders__Bank_Routing_Number__c = routingNumber;
                }
                if (String.isNotBlank(accountNumber)) {
                    order.ChargentOrders__Bank_Account_Number__c = accountNumber;
                    order.ChargentOrders__Bank_Account_Type__c = 'Checking';
                }
            }
            // Clear credit card fields when using bank
            order.ChargentOrders__Card_Number__c = null;
            order.ChargentOrders__Card_Expiration_Month__c = null;
            order.ChargentOrders__Card_Expiration_Year__c = null;
            order.ChargentOrders__Gateway__c = gateways.get('ba');
            
        } else if (paymentMethod == 'card') {
            // Credit Card fields
            Object cardDataObj = paymentData.get('data');
            if (cardDataObj != null) {
                Map<String, Object> cardData = deserializeToMap(cardDataObj);
                // Only update card number if new value provided (not null)
                String cardNumber = (String) cardData.get('cardNumber');
                if (String.isNotBlank(cardNumber)) {
                    order.ChargentOrders__Card_Number__c = cardNumber;
                }else {
                    order.ChargentOrders__Card_Number__c = null;
                }
                order.ChargentOrders__Card_Expiration_Month__c = (String) cardData.get('expirationMonth');
                order.ChargentOrders__Card_Expiration_Year__c = (String) cardData.get('expirationYear');
                order.ChargentOrders__Gateway__c = gateways.get('cc');
            }
            // Clear bank fields when using credit card
            order.ChargentOrders__Bank_Name__c = null;
            order.ChargentOrders__Bank_Routing_Number__c = null;
            order.ChargentOrders__Bank_Account_Number__c = null;
            
        }
    }
    
    

    // ═══════════════════════════════════════════════════════════════════════
    // OWNERSHIP SECTION
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * Save Ownership Information - Creates/updates owner contacts with Ownership role
     * Removes Ownership role from contacts that are no longer owners
     * 
     * @param opportunityId - The Opportunity Id
     * @param ownersData - List of owner data maps
     * @param ownersToRemoveRole - List of Contact Ids to remove Ownership role from
     * @return SaveResult with success status and saved data
     */
    @AuraEnabled
    public static SaveResult saveOwnership(
        Id opportunityId,
        List<Object> ownersData,
        List<Id> ownersToRemoveRole
    ) {
        SaveResult result = new SaveResult();
        Savepoint sp = Database.setSavepoint();
        
        try {
            // Validate input
            if (opportunityId == null) {
                throw new AuraHandledException('Opportunity Id is required');
            }
            
            // Get Account Id
            Id accountId = getAccountIdFromOpportunity(opportunityId);
            
            // Collections for bulk DML
            List<Contact> contactsToUpsert = new List<Contact>();
            Map<Integer, String> indexToTempIdMap = new Map<Integer, String>();
            Set<Id> existingContactIds = new Set<Id>();
            
            // Process each owner - reuse buildContact with ownership fields
            if (ownersData != null && !ownersData.isEmpty()) {
                for (Integer i = 0; i < ownersData.size(); i++) {
                    Map<String, Object> ownerMap = deserializeToMap(ownersData[i]);
                    
                    // Check if selecting existing contact or creating new
                    String contactId = (String) ownerMap.get('contactId');
                    Boolean isExistingContact = String.isNotBlank(contactId);
                    Boolean isModified = ownerMap.get('isModified') == true;
                    
                    Contact ownerContact;
                    if (isExistingContact) {
                        // Existing contact - check if modified
                        if (isModified) {
                            // Contact was edited - update all fields
                            ownerContact = buildContact(ownerMap, accountId, (Id) contactId);
                        } else {
                            // Contact not modified - only update ownership fields
                            ownerContact = new Contact(Id = (Id) contactId);
                        }
                        existingContactIds.add((Id) contactId);
                    } else {
                        // New contact - build with all fields
                        ownerContact = buildContact(ownerMap, accountId, null);
                        
                        // Store temp id for tracking new contacts
                        String tempId = (String) ownerMap.get('id');
                        if (String.isNotBlank(tempId)) {
                            indexToTempIdMap.put(i, tempId);
                        }
                    }
                    
                    // Add ownership-specific fields (always set these)
                    ownerContact.vlocity_ins__MiddleName__c = (String) ownerMap.get('middleInitial');
                    ownerContact.ARC_OwnershipPercentage__c = toDecimal(ownerMap.get('ownershipPercentage'));
                    ownerContact.ARC_Eligible__c = (Boolean) ownerMap.get('isEligible');
                    
                    // Portal access (always set)
                    if (ownerMap.containsKey('portalAccess')) {
                        ownerContact.ARC_PortalAccess__c = (String) ownerMap.get('portalAccess');
                    }
                    
                    contactsToUpsert.add(ownerContact);
                }
            }
            
            // Validate total ownership = 100%
            // Decimal totalOwnership = 0;
            // for (Contact c : contactsToUpsert) {
            //     if (c.ARC_OwnershipPercentage__c != null) {
            //         totalOwnership += c.ARC_OwnershipPercentage__c;
            //     }
            // }
            
            // if (totalOwnership != 100) {
            //     throw new AuraHandledException('Total ownership must equal 100%. Current total: ' + totalOwnership + '%');
            // }
            
            // BULK UPSERT Contacts
            if (!contactsToUpsert.isEmpty()) {
                upsert contactsToUpsert;
            }
            
            // Update ACRs with Ownership role - add role to all owner contacts
            if (!contactsToUpsert.isEmpty()) {
                Set<Id> ownerContactIds = new Set<Id>();
                for (Contact c : contactsToUpsert) {
                    ownerContactIds.add(c.Id);
                }
                
                // Query existing ACRs
                Map<Id, AccountContactRelation> existingAcrsMap = new Map<Id, AccountContactRelation>();
                List<AccountContactRelation> acrs = [
                    SELECT Id, ContactId, Roles
                    FROM AccountContactRelation
                    WHERE AccountId = :accountId
                    AND ContactId IN :ownerContactIds
                ];
                
                for (AccountContactRelation acr : acrs) {
                    existingAcrsMap.put(acr.ContactId, acr);
                }
                
                List<AccountContactRelation> acrsToUpdate = new List<AccountContactRelation>();
                List<AccountContactRelation> acrsToInsert = new List<AccountContactRelation>();
                
                // Add Ownership role to each contact
                for (Id contactId : ownerContactIds) {
                    AccountContactRelation acr = existingAcrsMap.get(contactId);
                    if (acr != null) {
                        // Update existing ACR - reuse addRole helper
                        acr.Roles = addRole(acr.Roles, ROLE_OWNERSHIP);
                        acrsToUpdate.add(acr);
                    } else {
                        // Create new ACR
                        AccountContactRelation newAcr = new AccountContactRelation(
                            AccountId = accountId,
                            ContactId = contactId,
                            Roles = ROLE_OWNERSHIP
                        );
                        acrsToInsert.add(newAcr);
                    }
                }
                
                // Bulk DML
                if (!acrsToInsert.isEmpty()) {
                    insert acrsToInsert;
                }
                if (!acrsToUpdate.isEmpty()) {
                    update acrsToUpdate;
                }
            }
            
            // Remove Ownership role from contacts that are no longer owners
            if (ownersToRemoveRole != null && !ownersToRemoveRole.isEmpty()) {
                List<AccountContactRelation> acrsToRemoveRole = [
                    SELECT Id, ContactId, Roles
                    FROM AccountContactRelation
                    WHERE AccountId = :accountId
                    AND ContactId IN :ownersToRemoveRole
                ];
                
                List<AccountContactRelation> acrsToUpdateRemove = new List<AccountContactRelation>();
                for (AccountContactRelation acr : acrsToRemoveRole) {
                    // Remove Ownership role using helper
                    acr.Roles = removeRole(acr.Roles, ROLE_OWNERSHIP);
                    acrsToUpdateRemove.add(acr);
                }
                
                if (!acrsToUpdateRemove.isEmpty()) {
                    update acrsToUpdateRemove;
                }
            }
            
            // Build response
            List<Map<String, Object>> savedOwners = new List<Map<String, Object>>();
            for (Integer i = 0; i < contactsToUpsert.size(); i++) {
                Contact c = contactsToUpsert[i];
                Map<String, Object> savedOwner = new Map<String, Object>();
                savedOwner.put('contactId', c.Id);
                savedOwner.put('id', c.Id);
                
                // Include temp id if it was a new contact
                if (indexToTempIdMap.containsKey(i)) {
                    savedOwner.put('tempId', indexToTempIdMap.get(i));
                }
                
                savedOwners.add(savedOwner);
            }
            
            // Persist section-complete flag on Opportunity
            Opportunity opp = new Opportunity(Id = opportunityId, ARC_SFOwnershipComplete__c = true);
            update opp;

            result.isSuccess = true;
            result.message = 'Ownership information saved successfully';
            result.data.put('owners', savedOwners);
            
        } catch (Exception e) {
            Database.rollback(sp);
            handleException(result, e);
        }
        
        return result;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // COMPANY CONTACT SECTION
    // ═══════════════════════════════════════════════════════════════════════
    

    /**
     * Save all Contact Section data in a single transaction with BULKIFIED DML
     * Supports rollback if any part fails
     * 
     * @param opportunityId - The Opportunity Id
     * @param contactSectionData - Map containing all contact section data
     * @return SaveResult with success status and saved data
     */
    @AuraEnabled
    public static SaveResult saveContactSection(
        Id opportunityId,
        Map<String, Object> contactSectionData
    ) {
        SaveResult result = new SaveResult();
        Savepoint sp = Database.setSavepoint();
        
        try {
            // Validate input
            if (opportunityId == null) {
                throw new AuraHandledException('Opportunity Id is required');
            }
            if (contactSectionData == null || contactSectionData.isEmpty()) {
                throw new AuraHandledException('Contact section data is required');
            }
            
            // Get Account Id from Opportunity
            Id accountId = getAccountIdFromOpportunity(opportunityId);
            
            // Collections for bulk DML
            List<Contact> contactsToUpsert = new List<Contact>();
            List<Account> tpaAccountsToUpsert = new List<Account>();
            List<Contact> tpaContactsToUpsert = new List<Contact>();
            
            // Track roles for ACR updates
            Map<String, Id> roleContactMap = new Map<String, Id>(); // role -> new contactId
            Map<String, Id> oldRoleContactMap = new Map<String, Id>(); // role -> old contactId
            
            // Get TPA RecordType once
            Id tpaRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get(RECORDTYPE_BUSINESS_ACCOUNT).getRecordTypeId();
            
            // Track contact and TPA indices for result mapping
            Map<String, Integer> contactIndexMap = new Map<String, Integer>();
            List<Map<String, Object>> tpaDataList = new List<Map<String, Object>>();
            
            // ═══════════════════════════════════════════════════════════════
            // STEP 1: Query current roles to handle role removal
            // ═══════════════════════════════════════════════════════════════
            List<AccountContactRelation> currentAcrs = [
                SELECT ContactId, Roles
                FROM AccountContactRelation
                WHERE AccountId = :accountId
                AND (Roles INCLUDES (:ROLE_PRIMARY_CONTACT)
                    OR Roles INCLUDES (:ROLE_COMPANY_OFFICER)
                    OR Roles INCLUDES (:ROLE_OTHER)
                    OR Roles INCLUDES (:ROLE_TPA)
                    OR Roles INCLUDES (:ROLE_ACCOUNT_HOLDER)
                    OR Roles INCLUDES (:ROLE_BILLING_CONTACT)
                    OR Roles INCLUDES (:ROLE_OWNERSHIP))
            ];
            
            for (AccountContactRelation acr : currentAcrs) {
                if (acr.Roles != null && acr.Roles.contains(ROLE_PRIMARY_CONTACT)) {
                    oldRoleContactMap.put(ROLE_PRIMARY_CONTACT, acr.ContactId);
                }
                if (acr.Roles != null && acr.Roles.contains(ROLE_COMPANY_OFFICER)) {
                    oldRoleContactMap.put(ROLE_COMPANY_OFFICER, acr.ContactId);
                }
                if (acr.Roles != null && acr.Roles.contains(ROLE_ACCOUNT_HOLDER)) {
                    oldRoleContactMap.put(ROLE_ACCOUNT_HOLDER, acr.ContactId);
                }
                if (acr.Roles != null && acr.Roles.contains(ROLE_BILLING_CONTACT)) {
                    oldRoleContactMap.put(ROLE_BILLING_CONTACT, acr.ContactId);
                }
            }
            
            // ═══════════════════════════════════════════════════════════════
            // STEP 2: Build Primary Contact
            // ═══════════════════════════════════════════════════════════════
            if (contactSectionData.containsKey('primaryContact')) {
                Map<String, Object> primaryData = deserializeToMap(contactSectionData.get('primaryContact'));
                Map<String, Object> contactData = deserializeToMap(primaryData.get('contactData'));
                
                if (contactData != null) {
                    Contact contact = buildContact(contactData, accountId, null);
                    contactsToUpsert.add(contact);
                    contactIndexMap.put('primary', contactsToUpsert.size() - 1);
                    roleContactMap.put(ROLE_PRIMARY_CONTACT, null); // Will be set after upsert
                }
            }
            
            // ═══════════════════════════════════════════════════════════════
            // STEP 3: Build Company Officer Contact
            // ═══════════════════════════════════════════════════════════════
            if (contactSectionData.containsKey('officerContact')) {
                Map<String, Object> officerData = deserializeToMap(contactSectionData.get('officerContact'));
                Boolean sameAsPrimary = (Boolean) officerData.get('sameAsPrimary');
                
                if (sameAsPrimary == true) {
                    // Officer is same as Primary - mark Primary Contact to get both roles
                    roleContactMap.put(ROLE_COMPANY_OFFICER, null); // Will be set to Primary Contact Id after upsert
                } else if (sameAsPrimary == false) {
                    // Officer is a different contact
                    Map<String, Object> contactData = deserializeToMap(officerData.get('contactData'));
                    
                    if (contactData != null) {
                        Contact contact = buildContact(contactData, accountId, null);
                        contactsToUpsert.add(contact);
                        contactIndexMap.put('officer', contactsToUpsert.size() - 1);
                        roleContactMap.put(ROLE_COMPANY_OFFICER, null); // Will be set after upsert
                    }
                }
            }
            
            // ═══════════════════════════════════════════════════════════════
            // STEP 4: Build Other Contacts
            // ═══════════════════════════════════════════════════════════════
            Integer otherContactStartIndex = contactsToUpsert.size();
            if (contactSectionData.containsKey('otherContacts')) {
                List<Object> otherContactsList = (List<Object>) contactSectionData.get('otherContacts');
                
                if (otherContactsList != null && !otherContactsList.isEmpty()) {
                    for (Object obj : otherContactsList) {
                        Map<String, Object> otherContactData = deserializeToMap(obj);
                        Boolean isNew = (Boolean) otherContactData.get('isNew');
                        Boolean isModified = (Boolean) otherContactData.get('isModified');
                        
                        // Only process if new or modified
                        if (isNew == true || isModified == true) {
                            Map<String, Object> contactDataMap = deserializeToMap(otherContactData.get('contact'));
                            
                            // Normalize field names
                            Map<String, Object> normalizedData = new Map<String, Object>();
                            normalizedData.put('contactId', contactDataMap.get('Id'));
                            normalizedData.put('firstName', contactDataMap.get('FirstName'));
                            normalizedData.put('lastName', contactDataMap.get('LastName'));
                            normalizedData.put('title', contactDataMap.get('Title'));
                            normalizedData.put('email', contactDataMap.get('Email'));
                            normalizedData.put('phone', contactDataMap.get('Phone'));
                            normalizedData.put('portalAccess', contactDataMap.get('ARC_PortalAccess__c'));
                            normalizedData.put('street', contactDataMap.get('MailingStreet'));
                            normalizedData.put('city', contactDataMap.get('MailingCity'));
                            normalizedData.put('state', contactDataMap.get('MailingState'));
                            normalizedData.put('zip', contactDataMap.get('MailingPostalCode'));
                            
                            
                            Contact contact = buildContact(normalizedData, accountId, null);
                            contactsToUpsert.add(contact);
                        }
                    }
                }
            }
            
            // Track ownership contacts index
            Integer otherContactEndIndex = contactsToUpsert.size(); // end of Other Contacts (exclusive)
            Set<Id> ownershipContactIds = new Set<Id>();
            Integer ownershipContactStartIndex = -1; // kept for response-building compat
            Integer ownershipContactCount = 0;       // kept for response-building compat
            Boolean accountHolderSameAsPrimary = false;
            Boolean billingContactSameAsAccountHolder = false;

            // ═══════════════════════════════════════════════════════════════
            // STEP 4b: Build Account Holder Contact (account mode)
            // ═══════════════════════════════════════════════════════════════
            if (contactSectionData.containsKey('accountHolderContact')) {
                Map<String, Object> ahData = deserializeToMap(contactSectionData.get('accountHolderContact'));
                Boolean sameAsPrimary = ahData.get('sameAsPrimary') == true;
                accountHolderSameAsPrimary = sameAsPrimary;
                if (sameAsPrimary) {
                    roleContactMap.put(ROLE_ACCOUNT_HOLDER, null);
                } else {
                    Map<String, Object> contactData = deserializeToMap(ahData.get('contactData'));
                    if (contactData != null) {
                        String ahContactId = (String) contactData.get('contactId');
                        // Check if this contact is already in the list (e.g. same as primary)
                        Integer existingIdx = findContactIndexById(contactsToUpsert, ahContactId);
                        if (existingIdx >= 0) {
                            contactIndexMap.put('accountHolder', existingIdx);
                        } else {
                            Contact contact = buildContact(contactData, accountId, null);
                            contactsToUpsert.add(contact);
                            contactIndexMap.put('accountHolder', contactsToUpsert.size() - 1);
                        }
                        roleContactMap.put(ROLE_ACCOUNT_HOLDER, null);
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // STEP 4c: Build Billing Contact (account mode)
            // ═══════════════════════════════════════════════════════════════
            if (contactSectionData.containsKey('billingContact')) {
                Map<String, Object> bcData = deserializeToMap(contactSectionData.get('billingContact'));
                Boolean sameAsAccountHolder = bcData.get('sameAsAccountHolder') == true;
                billingContactSameAsAccountHolder = sameAsAccountHolder;
                if (sameAsAccountHolder) {
                    roleContactMap.put(ROLE_BILLING_CONTACT, null);
                } else {
                    Map<String, Object> contactData = deserializeToMap(bcData.get('contactData'));
                    if (contactData != null) {
                        String bcContactId = (String) contactData.get('contactId');
                        // Check if this contact is already in the list (e.g. same as AH or primary)
                        Integer existingIdx = findContactIndexById(contactsToUpsert, bcContactId);
                        if (existingIdx >= 0) {
                            contactIndexMap.put('billingContact', existingIdx);
                        } else {
                            Contact contact = buildContact(contactData, accountId, null);
                            contactsToUpsert.add(contact);
                            contactIndexMap.put('billingContact', contactsToUpsert.size() - 1);
                        }
                        roleContactMap.put(ROLE_BILLING_CONTACT, null);
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // STEP 4d: Build Ownership Contacts (account mode)
            // ═══════════════════════════════════════════════════════════════
            if (contactSectionData.containsKey('ownershipContacts')) {
                List<Object> ownershipList = (List<Object>) contactSectionData.get('ownershipContacts');
                if (ownershipList != null && !ownershipList.isEmpty()) {
                    for (Object obj : ownershipList) {
                        Map<String, Object> ownerData = deserializeToMap(obj);
                        Map<String, Object> contactDataMap = deserializeToMap(ownerData.get('contact'));
                        if (contactDataMap != null) {
                            String existingContactId = (String) contactDataMap.get('Id');
                            // Check if this contact is already queued (e.g. same person as primary)
                            Integer dupeIdx = findContactIndexById(contactsToUpsert, existingContactId);
                            if (dupeIdx >= 0) {
                                // Already in list — just update ownership fields on the existing entry
                                Contact existing = contactsToUpsert[dupeIdx];
                                Object ownershipPct = contactDataMap.get('ARC_OwnershipPercentage__c');
                                if (ownershipPct != null) {
                                    existing.ARC_OwnershipPercentage__c = Decimal.valueOf(String.valueOf(ownershipPct));
                                }
                                Object isEligible = contactDataMap.get('ARC_Eligible__c');
                                if (isEligible != null) {
                                    existing.ARC_Eligible__c = (Boolean) isEligible;
                                }
                                if (String.isNotBlank(existingContactId)) {
                                    ownershipContactIds.add((Id) existingContactId);
                                }
                            } else {
                                Map<String, Object> normalized = new Map<String, Object>();
                                normalized.put('contactId', existingContactId);
                                normalized.put('firstName', contactDataMap.get('FirstName'));
                                normalized.put('lastName', contactDataMap.get('LastName'));
                                normalized.put('title', contactDataMap.get('Title'));
                                normalized.put('email', contactDataMap.get('Email'));
                                normalized.put('phone', contactDataMap.get('Phone'));
                                normalized.put('portalAccess', contactDataMap.get('ARC_PortalAccess__c'));
                                normalized.put('street', contactDataMap.get('MailingStreet'));
                                normalized.put('city', contactDataMap.get('MailingCity'));
                                normalized.put('state', contactDataMap.get('MailingState'));
                                normalized.put('zip', contactDataMap.get('MailingPostalCode'));
                                Contact contact = buildContact(normalized, accountId, null);
                                Object ownershipPct = contactDataMap.get('ARC_OwnershipPercentage__c');
                                if (ownershipPct != null) {
                                    contact.ARC_OwnershipPercentage__c = Decimal.valueOf(String.valueOf(ownershipPct));
                                }
                                Object isEligible = contactDataMap.get('ARC_Eligible__c');
                                if (isEligible != null) {
                                    contact.ARC_Eligible__c = (Boolean) isEligible;
                                }
                                if (ownershipContactStartIndex < 0) ownershipContactStartIndex = contactsToUpsert.size();
                                contactsToUpsert.add(contact);
                                ownershipContactCount++;
                                if (String.isNotBlank(existingContactId)) {
                                    ownershipContactIds.add((Id) existingContactId);
                                }
                            }
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // STEP 5: Build TPA Accounts and Contacts
            // ═══════════════════════════════════════════════════════════════
            if (contactSectionData.containsKey('tpas')) {
                List<Object> tpasList = (List<Object>) contactSectionData.get('tpas');
                
                if (tpasList != null && !tpasList.isEmpty()) {
                    for (Object obj : tpasList) {
                        Map<String, Object> tpaData = deserializeToMap(obj);
                        Boolean isNew = (Boolean) tpaData.get('isNew');
                        Boolean isModified = (Boolean) tpaData.get('isModified');
                        
                        // Only process if new or modified
                        if (isNew == true || isModified == true) {
                            Account tpaAccount = buildTpaAccount(tpaData, tpaRecordTypeId);
                            tpaAccountsToUpsert.add(tpaAccount);
                            tpaDataList.add(tpaData); // Save for contact processing after account upsert
                        }
                    }
                }
            }
            
            // ═══════════════════════════════════════════════════════════════
            // STEP 6: BULK UPSERT - Contacts
            // ═══════════════════════════════════════════════════════════════
            if (!contactsToUpsert.isEmpty()) {
                upsert contactsToUpsert;
            }
            
            // ═══════════════════════════════════════════════════════════════
            // STEP 7: BULK UPSERT - TPA Accounts
            // ═══════════════════════════════════════════════════════════════
            if (!tpaAccountsToUpsert.isEmpty()) {
                upsert tpaAccountsToUpsert;
            }
            
            // ═══════════════════════════════════════════════════════════════
            // STEP 8: Build TPA Contacts (now that we have Account Ids)
            // ═══════════════════════════════════════════════════════════════
            Integer tpaContactStartIndex = 0;
            if (!tpaAccountsToUpsert.isEmpty()) {
                for (Integer i = 0; i < tpaAccountsToUpsert.size(); i++) {
                    Account tpaAccount = tpaAccountsToUpsert[i];
                    Map<String, Object> tpaData = tpaDataList[i];
                    
                    Contact tpaContact = buildTpaContact(tpaData, tpaAccount.Id);
                    tpaContactsToUpsert.add(tpaContact);
                }
                
                // BULK UPSERT - TPA Contacts
                if (!tpaContactsToUpsert.isEmpty()) {
                    upsert tpaContactsToUpsert;
                }
            }
            
            // ═══════════════════════════════════════════════════════════════
            // STEP 9: Update ACR Roles (BULKIFIED)
            // ═══════════════════════════════════════════════════════════════
            
            // Populate roleContactMap for primary/officer contacts
            if (contactIndexMap.containsKey('primary')) {
                Id primaryContactId = contactsToUpsert[contactIndexMap.get('primary')].Id;
                roleContactMap.put(ROLE_PRIMARY_CONTACT, primaryContactId);
                if (roleContactMap.containsKey(ROLE_COMPANY_OFFICER) && roleContactMap.get(ROLE_COMPANY_OFFICER) == null) {
                    roleContactMap.put(ROLE_COMPANY_OFFICER, primaryContactId);
                }
                if (accountHolderSameAsPrimary && roleContactMap.containsKey(ROLE_ACCOUNT_HOLDER)) {
                    roleContactMap.put(ROLE_ACCOUNT_HOLDER, primaryContactId);
                }
            }
            if (contactIndexMap.containsKey('officer')) {
                roleContactMap.put(ROLE_COMPANY_OFFICER, contactsToUpsert[contactIndexMap.get('officer')].Id);
            }
            if (contactIndexMap.containsKey('accountHolder')) {
                Id ahId = contactsToUpsert[contactIndexMap.get('accountHolder')].Id;
                roleContactMap.put(ROLE_ACCOUNT_HOLDER, ahId);
                if (billingContactSameAsAccountHolder && roleContactMap.containsKey(ROLE_BILLING_CONTACT)) {
                    roleContactMap.put(ROLE_BILLING_CONTACT, ahId);
                }
            }
            if (contactIndexMap.containsKey('billingContact')) {
                roleContactMap.put(ROLE_BILLING_CONTACT, contactsToUpsert[contactIndexMap.get('billingContact')].Id);
            }

            // Fallback: AH same-as-primary but primary was not saved this round
            if (accountHolderSameAsPrimary
                    && roleContactMap.containsKey(ROLE_ACCOUNT_HOLDER)
                    && roleContactMap.get(ROLE_ACCOUNT_HOLDER) == null) {
                Id currentPrimaryId = oldRoleContactMap.get(ROLE_PRIMARY_CONTACT);
                if (currentPrimaryId != null) {
                    roleContactMap.put(ROLE_ACCOUNT_HOLDER, currentPrimaryId);
                    // Billing same-as-AH also gets the primary id when AH resolves to primary
                    if (billingContactSameAsAccountHolder && roleContactMap.containsKey(ROLE_BILLING_CONTACT)
                            && roleContactMap.get(ROLE_BILLING_CONTACT) == null) {
                        roleContactMap.put(ROLE_BILLING_CONTACT, currentPrimaryId);
                    }
                }
            }

            // Fallback: Billing same-as-AH but AH was not saved this round
            if (billingContactSameAsAccountHolder
                    && roleContactMap.containsKey(ROLE_BILLING_CONTACT)
                    && roleContactMap.get(ROLE_BILLING_CONTACT) == null) {
                Id currentAhId = oldRoleContactMap.get(ROLE_ACCOUNT_HOLDER);
                if (currentAhId != null) {
                    roleContactMap.put(ROLE_BILLING_CONTACT, currentAhId);
                }
            }
            
            // Update primary, officer, account holder, and billing roles
            bulkUpdateContactRoles(accountId, roleContactMap, oldRoleContactMap);

            // Collect IDs for newly created ownership contacts (had no contactId before upsert)
            if (ownershipContactStartIndex >= 0) {
                for (Integer i = ownershipContactStartIndex; i < ownershipContactStartIndex + ownershipContactCount; i++) {
                    if (contactsToUpsert[i].Id != null) {
                        ownershipContactIds.add(contactsToUpsert[i].Id);
                    }
                }
            }

            // Handle Ownership Contacts ACRs
            if (!ownershipContactIds.isEmpty()) {
                Map<Id, AccountContactRelation> ownershipAcrsMap = new Map<Id, AccountContactRelation>();
                for (AccountContactRelation acr : [
                    SELECT Id, ContactId, Roles FROM AccountContactRelation
                    WHERE AccountId = :accountId AND ContactId IN :ownershipContactIds
                ]) {
                    ownershipAcrsMap.put(acr.ContactId, acr);
                }
                List<AccountContactRelation> ownerAcrsToUpdate = new List<AccountContactRelation>();
                List<AccountContactRelation> ownerAcrsToInsert = new List<AccountContactRelation>();
                for (Id ownerId : ownershipContactIds) {
                    prepareContactRoleUpdate(accountId, ownerId, null, ROLE_OWNERSHIP, ownershipAcrsMap, ownerAcrsToUpdate, ownerAcrsToInsert);
                }
                if (!ownerAcrsToInsert.isEmpty()) insert ownerAcrsToInsert;
                if (!ownerAcrsToUpdate.isEmpty()) update ownerAcrsToUpdate;
            }
            
            // Handle Other Contacts and TPAs separately (they don't need old contact removal)
            if (otherContactStartIndex < otherContactEndIndex || !tpaContactsToUpsert.isEmpty()) {
                Set<Id> otherAndTpaContactIds = new Set<Id>();
                
                // Collect Other Contact IDs
                for (Integer i = otherContactStartIndex; i < otherContactEndIndex; i++) {
                    otherAndTpaContactIds.add(contactsToUpsert[i].Id);
                }
                
                // Collect TPA Contact IDs
                for (Contact tpaContact : tpaContactsToUpsert) {
                    otherAndTpaContactIds.add(tpaContact.Id);
                }
                
                // Query ACRs for Other Contacts and TPAs
                Map<Id, AccountContactRelation> otherAcrsMap = new Map<Id, AccountContactRelation>();
                if (!otherAndTpaContactIds.isEmpty()) {
                    List<AccountContactRelation> acrs = [
                        SELECT Id, ContactId, Roles
                        FROM AccountContactRelation
                        WHERE AccountId = :accountId
                        AND ContactId IN :otherAndTpaContactIds
                    ];
                    
                    for (AccountContactRelation acr : acrs) {
                        otherAcrsMap.put(acr.ContactId, acr);
                    }
                }
                
                List<AccountContactRelation> acrsToUpdate = new List<AccountContactRelation>();
                List<AccountContactRelation> acrsToInsert = new List<AccountContactRelation>();
                
                // Prepare Other Contacts role updates
                for (Integer i = otherContactStartIndex; i < otherContactEndIndex; i++) {
                    Contact c = contactsToUpsert[i];
                    prepareContactRoleUpdate(
                        accountId,
                        c.Id,
                        null,
                        ROLE_OTHER,
                        otherAcrsMap,
                        acrsToUpdate,
                        acrsToInsert
                    );
                }
                
                // Prepare TPA role updates
                for (Contact tpaContact : tpaContactsToUpsert) {
                    prepareContactRoleUpdate(
                        accountId,
                        tpaContact.Id,
                        null,
                        ROLE_TPA,
                        otherAcrsMap,
                        acrsToUpdate,
                        acrsToInsert
                    );
                }
                
                // Bulk DML for Other/TPA ACRs
                if (!acrsToInsert.isEmpty()) {
                    insert acrsToInsert;
                }
                if (!acrsToUpdate.isEmpty()) {
                    update acrsToUpdate;
                }
            }
            
            // ═══════════════════════════════════════════════════════════════
            // STEP 10: Delete Contacts and TPAs
            // ═══════════════════════════════════════════════════════════════
            if (contactSectionData.containsKey('otherContactsToDelete')) {
                List<Object> contactsToDeleteList = (List<Object>) contactSectionData.get('otherContactsToDelete');
                
                if (contactsToDeleteList != null && !contactsToDeleteList.isEmpty()) {
                    if (!Schema.sObjectType.Contact.isDeletable()) {
                        throw new AuraHandledException('You do not have permission to delete Contact records');
                    }
                    
                    List<Id> contactIds = new List<Id>();
                    for (Object obj : contactsToDeleteList) {
                        contactIds.add((Id) obj);
                    }
                    
                    if (!contactIds.isEmpty()) {
                        delete [SELECT Id FROM Contact WHERE Id IN :contactIds];
                    }
                }
            }
            
            if (contactSectionData.containsKey('ownershipContactsToRemoveRole')) {
                List<Object> ownershipToRemoveRoleList = (List<Object>) contactSectionData.get('ownershipContactsToRemoveRole');
                if (ownershipToRemoveRoleList != null && !ownershipToRemoveRoleList.isEmpty()) {
                    Set<Id> contactIdSet = new Set<Id>();
                    for (Object obj : ownershipToRemoveRoleList) { contactIdSet.add((Id) obj); }
                    if (!contactIdSet.isEmpty()) {
                        List<AccountContactRelation> acrsToRemoveRole = [
                            SELECT Id, ContactId, Roles
                            FROM AccountContactRelation
                            WHERE AccountId = :accountId
                            AND ContactId IN :contactIdSet
                        ];
                        List<AccountContactRelation> acrsToUpdate = new List<AccountContactRelation>();
                        for (AccountContactRelation acr : acrsToRemoveRole) {
                            acr.Roles = removeRole(acr.Roles, ROLE_OWNERSHIP);
                            acrsToUpdate.add(acr);
                        }
                        if (!acrsToUpdate.isEmpty()) {
                            update acrsToUpdate;
                        }
                    }
                }
            }

            if (contactSectionData.containsKey('tpasToDelete')) {
                List<Object> tpasToDeleteList = (List<Object>) contactSectionData.get('tpasToDelete');
                
                if (tpasToDeleteList != null && !tpasToDeleteList.isEmpty()) {
                    if (!Schema.sObjectType.Contact.isDeletable() || !Schema.sObjectType.Account.isDeletable()) {
                        throw new AuraHandledException('You do not have permission to delete Contact and Account records');
                    }
                    
                    List<Id> contactIdsToDelete = new List<Id>();
                    List<Id> accountIdsToDelete = new List<Id>();
                    
                    for (Object obj : tpasToDeleteList) {
                        Map<String, Object> tpaToDelete = deserializeToMap(obj);
                        String contactId = (String) tpaToDelete.get('contactId');
                        String tpaAccountId = (String) tpaToDelete.get('accountId');
                        
                        if (String.isNotBlank(contactId)) {
                            contactIdsToDelete.add((Id) contactId);
                        }
                        if (String.isNotBlank(tpaAccountId)) {
                            accountIdsToDelete.add((Id) tpaAccountId);
                        }
                    }
                    
                    // Always delete Contacts
                    if (!contactIdsToDelete.isEmpty()) {
                        delete [SELECT Id FROM Contact WHERE Id IN :contactIdsToDelete];
                    }
                    
                    // Only delete Accounts if they have 1 or fewer Contacts (not being used elsewhere)
                    if (!accountIdsToDelete.isEmpty()) {
                        // Query each Account to check Contact count
                        List<Id> accountsToDelete = new List<Id>();
                        for (Id accountIdd : accountIdsToDelete) {
                            Integer contactCount = [
                                SELECT COUNT() 
                                FROM Contact 
                                WHERE AccountId = :accountIdd
                            ];
                            
                            // Only delete if no contacts remain (the TPA contact was the only one)
                            if (contactCount <= 0) {
                                accountsToDelete.add(accountIdd);
                            }
                        }
                        
                        if (!accountsToDelete.isEmpty()) {
                            delete [SELECT Id FROM Account WHERE Id IN :accountsToDelete];
                        }
                    }
                }
            }
            
            // ═══════════════════════════════════════════════════════════════
            // STEP 11: Build Response
            // ═══════════════════════════════════════════════════════════════
            Map<String, Object> savedData = new Map<String, Object>();
            
            // Primary Contact
            if (contactIndexMap.containsKey('primary')) {
                Contact primaryContact = contactsToUpsert[contactIndexMap.get('primary')];
                Id acrId = getAcrId(accountId, primaryContact.Id);
                
                Map<String, Object> primaryResult = new Map<String, Object>();
                primaryResult.put('contactId', primaryContact.Id);
                primaryResult.put('acrId', acrId);
                savedData.put('primaryContact', primaryResult);
            }
            
            // Officer Contact
            if (contactIndexMap.containsKey('officer')) {
                Contact officerContact = contactsToUpsert[contactIndexMap.get('officer')];
                Id acrId = getAcrId(accountId, officerContact.Id);
                
                Map<String, Object> officerResult = new Map<String, Object>();
                officerResult.put('contactId', officerContact.Id);
                officerResult.put('acrId', acrId);
                savedData.put('officerContact', officerResult);
            }
            
            // Other Contacts
            if (otherContactStartIndex < otherContactEndIndex) {
                List<Id> otherContactIds = new List<Id>();
                for (Integer i = otherContactStartIndex; i < otherContactEndIndex; i++) {
                    otherContactIds.add(contactsToUpsert[i].Id);
                }
                
                Map<Id, Id> contactToAcrMap = getAcrIds(accountId, new Set<Id>(otherContactIds));
                
                List<Map<String, Object>> savedOtherContacts = new List<Map<String, Object>>();
                for (Id contactId : otherContactIds) {
                    Map<String, Object> savedContact = new Map<String, Object>();
                    savedContact.put('contactId', contactId);
                    savedContact.put('acrId', contactToAcrMap.get(contactId));
                    savedOtherContacts.add(savedContact);
                }
                
                savedData.put('otherContacts', savedOtherContacts);
            }
            
            // TPAs
            if (!tpaAccountsToUpsert.isEmpty()) {
                List<Map<String, Object>> savedTPAs = new List<Map<String, Object>>();
                for (Integer i = 0; i < tpaAccountsToUpsert.size(); i++) {
                    Map<String, Object> savedTPA = new Map<String, Object>();
                    savedTPA.put('accountId', tpaAccountsToUpsert[i].Id);
                    savedTPA.put('contactId', tpaContactsToUpsert[i].Id);
                    savedTPAs.add(savedTPA);
                }
                savedData.put('tpas', savedTPAs);
            }

            // Account Holder
            if (roleContactMap.containsKey(ROLE_ACCOUNT_HOLDER) && roleContactMap.get(ROLE_ACCOUNT_HOLDER) != null) {
                Id ahId = roleContactMap.get(ROLE_ACCOUNT_HOLDER);
                Map<String, Object> ahResult = new Map<String, Object>();
                ahResult.put('contactId', ahId);
                ahResult.put('acrId', getAcrId(accountId, ahId));
                savedData.put('accountHolder', ahResult);
            }

            // Billing Contact
            if (roleContactMap.containsKey(ROLE_BILLING_CONTACT) && roleContactMap.get(ROLE_BILLING_CONTACT) != null) {
                Id bcId = roleContactMap.get(ROLE_BILLING_CONTACT);
                Map<String, Object> bcResult = new Map<String, Object>();
                bcResult.put('contactId', bcId);
                bcResult.put('acrId', getAcrId(accountId, bcId));
                savedData.put('billingContact', bcResult);
            }

            // Ownership Contacts
            if (!ownershipContactIds.isEmpty()) {
                Map<Id, Id> ownerAcrMap = getAcrIds(accountId, ownershipContactIds);
                List<Map<String, Object>> savedOwners = new List<Map<String, Object>>();
                for (Id ownerId : ownershipContactIds) {
                    Map<String, Object> ownerResult = new Map<String, Object>();
                    ownerResult.put('contactId', ownerId);
                    ownerResult.put('acrId', ownerAcrMap.get(ownerId));
                    savedOwners.add(ownerResult);
                }
                savedData.put('ownershipContacts', savedOwners);
            }

            result.isSuccess = true;
            result.message = 'Contact section saved successfully';
            result.data = savedData;
            
        } catch (Exception e) {
            Database.rollback(sp);
            result.isSuccess = false;
            result.message = e.getMessage();
            result.errorType = e.getTypeName();
        }
        
        return result;
    }
    
    /**
     * Get current contact Id by role (queries ACR to get latest info)
     */
    private static Id getCurrentContactIdByRole(Id accountId, String role) {
        List<AccountContactRelation> acrs = [
            SELECT ContactId 
            FROM AccountContactRelation 
            WHERE AccountId = :accountId 
            AND Roles INCLUDES (:role)
            LIMIT 1
        ];
        
        return !acrs.isEmpty() ? acrs[0].ContactId : null;
    }

    /**
     * Find the index of a contact with a given Id already in the upsert list.
     * Returns -1 if not found or if contactId is blank (new contact).
     */
    private static Integer findContactIndexById(List<Contact> contacts, String contactId) {
        if (String.isBlank(contactId)) return -1;
        // Cast to Id first so Salesforce normalises both to 18-char before comparing
        Id searchId;
        try { searchId = (Id) contactId; } catch (Exception e) { return -1; }
        for (Integer i = 0; i < contacts.size(); i++) {
            if (contacts[i].Id != null && contacts[i].Id == searchId) {
                return i;
            }
        }
        return -1;
    }

    /**
     * Build a Contact record from data map
     * Returns Contact object ready for DML (does NOT perform DML)
     * 
     * @param contactData - Map containing contact fields
     * @param accountId - The Account Id to associate contact with
     * @param defaultTitle - Default title for new contacts (optional)
     * @return Contact record
     */
    private static Contact buildContact(Map<String, Object> contactData, Id accountId, String defaultTitle) {
        Contact contact = new Contact();
        Id SGRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
                .get('ARC_SmallGroup').getRecordTypeId();

        contact.RecordTypeId = SGRecordTypeId;
        
        // Set Id if existing contact
        String contactId = (String) contactData.get('contactId');
        if (String.isNotBlank(contactId)) {
            contact.Id = (Id) contactId;
        } else {
            // New contact needs AccountId
            contact.AccountId = accountId;
        }
        
        // Required fields
        if (contactData.containsKey('firstName')) contact.FirstName = (String) contactData.get('firstName');
        if (contactData.containsKey('lastName')) contact.LastName = (String) contactData.get('lastName');
        if (contactData.containsKey('email')) contact.Email = (String) contactData.get('email');

        
        // Optional fields
        if (contactData.containsKey('title')) {
            contact.Title = (String) contactData.get('title');
        } else if (String.isNotBlank(defaultTitle) && contact.Id == null) {
            // Only set default title for new contacts
            contact.Title = defaultTitle;
        }
        
        if (contactData.containsKey('phone')) contact.Phone = (String) contactData.get('phone');
        if (contactData.containsKey('portalAccess')) contact.ARC_PortalAccess__c = (String) contactData.get('portalAccess');
        
        // Mailing address fields
        if (contactData.containsKey('street')) contact.MailingStreet = (String) contactData.get('street');
        if (contactData.containsKey('city')) contact.MailingCity = (String) contactData.get('city');
        if (contactData.containsKey('state')) contact.MailingState = (String) contactData.get('state');
        if (contactData.containsKey('zip')) contact.MailingPostalCode = (String) contactData.get('zip');
        
        return contact;
    }
    
    /**
     * Check if user has permission to delete Contact and Account records
     * 
     * @return Map with permissions { hasContactDelete: Boolean, hasAccountDelete: Boolean }
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean> checkDeletePermissions() {
        Map<String, Boolean> permissions = new Map<String, Boolean>();
        permissions.put('hasContactDelete', Schema.sObjectType.Contact.isDeletable());
        permissions.put('hasAccountDelete', Schema.sObjectType.Account.isDeletable());
        return permissions;
    }

    /**
     * Get ACR Id for a given contact and account
     * Helper method to avoid repeated SOQL queries
     * 
     * @param accountId - The Account Id
     * @param contactId - The Contact Id
     * @return ACR Id or null if not found
     */
    private static Id getAcrId(Id accountId, Id contactId) {
        if (accountId == null || contactId == null) {
            return null;
        }
        
        List<AccountContactRelation> acrs = [
            SELECT Id 
            FROM AccountContactRelation 
            WHERE AccountId = :accountId 
            AND ContactId = :contactId 
            LIMIT 1
        ];
        
        return !acrs.isEmpty() ? acrs[0].Id : null;
    }

    /**
     * Bulk get ACR Ids for multiple contacts
     * 
     * @param accountId - The Account Id
     * @param contactIds - Set of Contact Ids
     * @return Map of ContactId to ACR Id
     */
    private static Map<Id, Id> getAcrIds(Id accountId, Set<Id> contactIds) {
        Map<Id, Id> contactToAcrMap = new Map<Id, Id>();
        
        if (accountId == null || contactIds == null || contactIds.isEmpty()) {
            return contactToAcrMap;
        }
        
        List<AccountContactRelation> acrs = [
            SELECT Id, ContactId
            FROM AccountContactRelation 
            WHERE AccountId = :accountId 
            AND ContactId IN :contactIds
        ];
        
        for (AccountContactRelation acr : acrs) {
            contactToAcrMap.put(acr.ContactId, acr.Id);
        }
        
        return contactToAcrMap;
    }

    /**
     * Process TPA Account (build record for bulk upsert)
     * Does NOT perform DML
     * 
     * @param tpaData - Map containing TPA account data
     * @param recordTypeId - Business_Account RecordType Id
     * @return TPA Account record
     */
    private static Account buildTpaAccount(Map<String, Object> tpaData, Id recordTypeId) {
        String tpaAccountId = (String) tpaData.get('accountId');
        
        Account tpaAccount = new Account(
            RecordTypeId = recordTypeId,
            Name = (String) tpaData.get('companyName'),
            BillingStreet = (String) tpaData.get('mailingAddress'),
            BillingCity = (String) tpaData.get('city'),
            BillingState = (String) tpaData.get('state'),
            BillingPostalCode = (String) tpaData.get('zip'),
            BillingCountry = COUNTRY_US
        );
        
        if (String.isNotBlank(tpaAccountId)) {
            tpaAccount.Id = (Id) tpaAccountId;
        }
        
        return tpaAccount;
    }

    /**
     * Process TPA Contact (build record for bulk upsert)
     * Does NOT perform DML
     * 
     * @param tpaData - Map containing TPA contact data
     * @param tpaAccountId - The TPA Account Id (for new contacts)
     * @return TPA Contact record
     */
    private static Contact buildTpaContact(Map<String, Object> tpaData, Id tpaAccountId) {
        String tpaContactId = (String) tpaData.get('contactId');
        Id SGRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
                .get('ARC_SmallGroup').getRecordTypeId();

        
        Contact tpaContact = new Contact(
            FirstName = (String) tpaData.get('firstName'),
            LastName = (String) tpaData.get('lastName'),
            Email = (String) tpaData.get('email'),
            Phone = (String) tpaData.get('phone'),
            ARC_PortalAccess__c = (String) tpaData.get('portalAccess'),
            RecordTypeId = SGRecordTypeId
        );
        
        if (String.isNotBlank(tpaContactId)) {
            tpaContact.Id = (Id) tpaContactId;
        } else {
            // New contact needs AccountId
            tpaContact.AccountId = tpaAccountId;
        }
        
        return tpaContact;
    }
    
    /**
     * Update contact role - removes role from old contact, adds to new contact
     * Builds ACR records for bulk update (does NOT perform DML)
     * 
     * @param accountId - The Account Id
     * @param newContactId - The new Contact Id to add role to
     * @param oldContactId - The old Contact Id to remove role from
     * @param role - The role to manage
     * @param acrsToUpdate - List to add ACR records that need updating
     * @param acrsToInsert - List to add new ACR records
     */
    private static void prepareContactRoleUpdate(
        Id accountId, 
        Id newContactId, 
        Id oldContactId, 
        String role,
        Map<Id, AccountContactRelation> existingAcrs,
        List<AccountContactRelation> acrsToUpdate,
        List<AccountContactRelation> acrsToInsert
    ) {
        // Remove role from old contact (if different from new contact)
        if (oldContactId != null && oldContactId != newContactId) {
            AccountContactRelation oldAcr = existingAcrs.get(oldContactId);
            if (oldAcr != null) {
                // Remove only the specific role
                oldAcr.Roles = removeRole(oldAcr.Roles, role);
                
                // If no roles remain after removal, set to "Other"
                if (String.isBlank(oldAcr.Roles)) {
                    oldAcr.Roles = ROLE_OTHER;
                }
                
                acrsToUpdate.add(oldAcr);
            }
        }
        
        // Add role to new contact
        if (newContactId != null) {
            AccountContactRelation newAcr = existingAcrs.get(newContactId);
            if (newAcr != null) {
                // Update existing ACR
                newAcr.Roles = addRole(newAcr.Roles, role);
                acrsToUpdate.add(newAcr);
            } else {
                // Create new ACR
                AccountContactRelation acrToInsert = new AccountContactRelation(
                    AccountId = accountId,
                    ContactId = newContactId,
                    Roles = role
                );
                acrsToInsert.add(acrToInsert);
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // AFFILIATED ENTITIES SECTION
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * Save affiliated entities (child Accounts) for the employer
     * Each entity is stored as a child Account with ParentId = Employer Account
     * 
     * @param opportunityId - The Opportunity Id
     * @param entitiesData - List of entity data from the UI
     * @return SaveResult with success/error information
     */
    @AuraEnabled
    public static SaveResult saveAffiliatedEntities(Id opportunityId, String entitiesData) {
        SaveResult result = new SaveResult();
        
        try {
            if (opportunityId == null) {
                throw new AuraHandledException('Opportunity Id is required');
            }
            
            // Get the employer Account ID
            Id accountId = getAccountIdFromOpportunity(opportunityId);
            
            // Parse entities data
            List<Object> entities = (List<Object>) JSON.deserializeUntyped(entitiesData);
            
            // Get Business RecordType
            Id businessRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get(RECORDTYPE_BUSINESS_ACCOUNT).getRecordTypeId();
            
            List<Account> accountsToUpsert = new List<Account>();
            Set<Id> entityIdsToKeep = new Set<Id>();
            
            // Process each entity from the UI
            for (Object entityObj : entities) {
                Map<String, Object> entity = (Map<String, Object>) entityObj;
                
                Account acc = new Account();
                
                // Set ID if updating existing record
                String entityId = (String) entity.get('id');
                if (entityId != null && entityId.startsWith('006')) {
                    acc.Id = entityId;
                    //entityIdsToKeep.add(entityId);
                }
                
                // Set required fields
                acc.Name = (String) entity.get('legalName');
                acc.ARC_FederalEmployerTaxIDNumber__c = (String) entity.get('federalTaxId');
                
                // Set optional fields
                Object numEmployees = entity.get('numberOfEmployees');
                if (numEmployees != null) {
                    acc.ARC_Number_Of_Employees__c = toDecimal(numEmployees);
                }
                
                // Set parent relationship
                acc.ParentId = accountId;
                acc.RecordTypeId = businessRecordTypeId;
                
                accountsToUpsert.add(acc);
            }
            
            // Upsert entities
            if (!accountsToUpsert.isEmpty()) {
                upsert accountsToUpsert;
            }

            // Update idsToKeep
            for (Account acc : accountsToUpsert) {
                entityIdsToKeep.add(acc.Id);
            }
            
            // Delete entities that were removed in the UI
            List<Account> existingEntities = [
                SELECT Id 
                FROM Account 
                WHERE ParentId = :accountId 
                AND RecordTypeId = :businessRecordTypeId
            ];
            
            List<Account> accountsToDelete = new List<Account>();
            for (Account existingEntity : existingEntities) {
                if (!entityIdsToKeep.contains(existingEntity.Id)) {
                    accountsToDelete.add(existingEntity);
                }
            }
            
            if (!accountsToDelete.isEmpty()) {
                delete accountsToDelete;
            }
            
            // Persist section-complete flag on Opportunity
            Opportunity oppAff = new Opportunity(Id = opportunityId, ARC_SFAffiliatedComplete__c = true);
            update oppAff;

            result.isSuccess = true;
            result.message = 'Affiliated entities saved successfully';
            
        } catch (Exception e) {
            handleException(result, e);
        }
        
        return result;
    }
    
    // ═══════════════════════════════════════════════════════════════════════
    // FORM COMPLETION TRACKING
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * Update Opportunity.ARC_SalesFormCompleted__c field
     * Called by FormContainer when checking form completion status
     * 
     * @param opportunityId - The Opportunity Id
     * @param isComplete - Whether the form is complete
     */
    @AuraEnabled
    public static void updateFormCompletion(Id opportunityId, Boolean isComplete) {
        try {
            if (opportunityId == null) {
                throw new AuraHandledException('Opportunity Id is required');
            }
            
            Opportunity opp = [SELECT Id, ARC_SalesFormCompleted__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            opp.ARC_SalesFormCompleted__c = isComplete;
            update opp;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error updating form completion: ' + e.getMessage());
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // WRAPPER CLASSES
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * Standard result wrapper for save operations
     */
    public class SaveResult {
        @AuraEnabled public Boolean isSuccess { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String errorType { get; set; }
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public Map<String, Object> data { get; set; }
        
        public SaveResult() {
            this.isSuccess = false;
            this.data = new Map<String, Object>();
        }
    }
}