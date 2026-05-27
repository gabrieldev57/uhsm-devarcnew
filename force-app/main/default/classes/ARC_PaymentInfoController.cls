public with sharing class ARC_PaymentInfoController {
    
    /**
     * @description Get the billing address from the Opportunity's Account
     * @param opportunityId The Id of the Opportunity
     * @return Account record with billing address fields
     */
    @AuraEnabled(cacheable=true)
    public static Account getAccountBillingAddress(Id opportunityId) {
        try {
            if (opportunityId == null) {
                return null;
            }
            
            Opportunity opp = [
                SELECT Id, AccountId
                FROM Opportunity 
                WHERE Id = :opportunityId 
                LIMIT 1
            ];
            
            if (opp.AccountId != null) {
                return [
                    SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode
                    FROM Account
                    WHERE Id = :opp.AccountId
                    LIMIT 1
                ];
            }
            
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving account billing address: ' + e.getMessage());
        }
    }

    /**
     * @description Get existing ChargentOrder for the Account related to the Opportunity
     * @param opportunityId The Id of the Opportunity
     * @return ChargentOrderData wrapper with order info or null if not found
     */
    @AuraEnabled(cacheable=true)
    public static ChargentOrderData getChargentOrder(Id opportunityId) {
        try {
            if (opportunityId == null) {
                return null;
            }
            
            // Get Account and RecordType from Opportunity
            Opportunity opp = [
                SELECT Id, AccountId, ContractId, RecordType.DeveloperName
                FROM Opportunity 
                WHERE Id = :opportunityId 
                LIMIT 1
            ];
            
            if (opp.AccountId == null) {
                return null;
            }
            
            ChargentOrders__ChargentOrder__c order = null;
            Boolean isRenewal = opp.RecordType != null && opp.RecordType.DeveloperName == 'ARC_Renewal';
            
            if (isRenewal) {
                // ── Renewal path ──────────────────────────────────────────────────────
                // Resolve the Contract to read from:
                //   - ContractId populated → use that Contract directly
                //   - ContractId null      → find the Active Contract for this Account
                Id renewalContractId = null;
                if (opp.ContractId != null) {
                    renewalContractId = opp.ContractId;
                } else {
                    List<Contract> activeContracts = [
                        SELECT Id
                        FROM Contract
                        WHERE AccountId = :opp.AccountId
                          AND Status = 'Activated'
                        ORDER BY StartDate DESC
                        LIMIT 1
                    ];
                    if (!activeContracts.isEmpty()) {
                        renewalContractId = activeContracts[0].Id;
                    }
                }
                
                // Retrieve the Recurring Order linked to that Contract
                if (renewalContractId != null) {
                    List<Contract> contractsWithOrder = [
                        SELECT Id, ARC_RecurringMonthlyOrder__c
                        FROM Contract
                        WHERE Id = :renewalContractId
                        LIMIT 1
                    ];
                    if (!contractsWithOrder.isEmpty() && contractsWithOrder[0].ARC_RecurringMonthlyOrder__c != null) {
                        Id recurringOrderId = contractsWithOrder[0].ARC_RecurringMonthlyOrder__c;
                        List<ChargentOrders__ChargentOrder__c> recurringOrders = [
                            SELECT Id, ChargentOrders__Billing_Address__c, ChargentOrders__Billing_City__c,
                                   ChargentOrders__Billing_State__c, ChargentOrders__Billing_Zip_Postal__c,
                                   ChargentOrders__Bank_Name__c, ChargentOrders__Bank_Account_Last_4__c,
                                   ChargentOrders__Bank_Routing_Number__c,
                                   ChargentOrders__Card_Last_4__c,
                                   ChargentOrders__Card_Month_Indicator__c, ChargentOrders__Card_Year_Indicator__c,
                                   ChargentOrders__Card_Expiration_Month__c, ChargentOrders__Card_Expiration_Year__c,
                                   ChargentOrders__Payment_Method__c, ARC_Contract__c
                            FROM ChargentOrders__ChargentOrder__c
                            WHERE Id = :recurringOrderId
                            LIMIT 1
                        ];
                        if (!recurringOrders.isEmpty()) {
                            order = recurringOrders[0];
                        }
                    }
                }
            } else {
                // ── Small Group (default) path ─────────────────────────────────────
                // 1. Resolve Contract via Opportunity.ContractId
                Id contractId = opp.ContractId; // may be null for a new enrollment
                
                // 2. Try to find existing ChargentOrder by Contract first
                if (contractId != null) {
                    List<ChargentOrders__ChargentOrder__c> contractOrders = [
                        SELECT Id, ChargentOrders__Billing_Address__c, ChargentOrders__Billing_City__c,
                               ChargentOrders__Billing_State__c, ChargentOrders__Billing_Zip_Postal__c,
                               ChargentOrders__Bank_Name__c, ChargentOrders__Bank_Account_Last_4__c,
                               ChargentOrders__Bank_Routing_Number__c,
                               ChargentOrders__Card_Last_4__c,
                               ChargentOrders__Card_Month_Indicator__c, ChargentOrders__Card_Year_Indicator__c,
                               ChargentOrders__Card_Expiration_Month__c, ChargentOrders__Card_Expiration_Year__c,
                               ChargentOrders__Payment_Method__c, ARC_Contract__c
                        FROM ChargentOrders__ChargentOrder__c
                        WHERE ARC_Contract__c = :contractId
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];
                    if (!contractOrders.isEmpty()) {
                        order = contractOrders[0];
                    }
                }
                
                // 3. If not found by Contract, find by Account
                if (order == null) {
                    List<ChargentOrders__ChargentOrder__c> accountOrders = [
                        SELECT Id, ChargentOrders__Billing_Address__c, ChargentOrders__Billing_City__c,
                               ChargentOrders__Billing_State__c, ChargentOrders__Billing_Zip_Postal__c,
                               ChargentOrders__Bank_Name__c, ChargentOrders__Bank_Account_Last_4__c,
                               ChargentOrders__Bank_Routing_Number__c,
                               ChargentOrders__Card_Last_4__c,
                               ChargentOrders__Card_Month_Indicator__c, ChargentOrders__Card_Year_Indicator__c,
                               ChargentOrders__Card_Expiration_Month__c, ChargentOrders__Card_Expiration_Year__c,
                               ChargentOrders__Payment_Method__c, ARC_Contract__c
                        FROM ChargentOrders__ChargentOrder__c
                        WHERE ChargentOrders__Account__c = :opp.AccountId
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];
                    if (!accountOrders.isEmpty()) {
                        order = accountOrders[0];
                    }
                }
            }
            
            if (order == null) {
                return null;
            }
            
            ChargentOrderData result = new ChargentOrderData();
            result.id = order.Id;
            result.accountId = opp.AccountId;
            
            // Billing address
            result.billingStreet = order.ChargentOrders__Billing_Address__c;
            result.billingCity = order.ChargentOrders__Billing_City__c;
            result.billingState = order.ChargentOrders__Billing_State__c;
            result.billingZip = order.ChargentOrders__Billing_Zip_Postal__c;
            
            // Payment method
            String paymentMethod = order.ChargentOrders__Payment_Method__c;
            result.paymentMethod = (paymentMethod == 'Bank Account' || paymentMethod == 'ACH') ? 'bank' : 'card';
            
            // Bank data - only return last 4 digits for display
            result.bankName = order.ChargentOrders__Bank_Name__c;
            result.bankLast4 = order.ChargentOrders__Bank_Account_Last_4__c;
            // Return 'ENCRYPTED' if routing number exists (encrypted field)
            result.routingNumber = String.isNotBlank(order.ChargentOrders__Bank_Routing_Number__c) ? 'ENCRYPTED' : null;
            
            // Credit card data - only return last 4 digits for display
            result.cardLast4 = order.ChargentOrders__Card_Last_4__c;
            
            // Use Card_Month_Indicator and Card_Year_Indicator if available
            if (order.ChargentOrders__Card_Month_Indicator__c != null && order.ChargentOrders__Card_Year_Indicator__c != null) {
                result.cardExpirationMonth = order.ChargentOrders__Card_Month_Indicator__c;
                result.cardExpirationYear = order.ChargentOrders__Card_Year_Indicator__c;
            }
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving Chargent Order: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get payment contacts (Account Holder, Billing Contact, Primary Business Contact)
     * @param opportunityId The Id of the Opportunity
     * @return PaymentContactsData wrapper with contact information
     */
    @AuraEnabled(cacheable=false)
    public static PaymentContactsData getPaymentContacts(Id opportunityId) {
        try {
            if (opportunityId == null) {
                return null;
            }
            
            // Get Account from Opportunity
            Opportunity opp = [
                SELECT Id, AccountId
                FROM Opportunity 
                WHERE Id = :opportunityId 
                LIMIT 1
            ];
            
            if (opp.AccountId == null) {
                return null;
            }
            
            PaymentContactsData result = new PaymentContactsData();
            
            // Query AccountContactRelations with roles
            List<AccountContactRelation> acrs = [
                SELECT Id, ContactId, Roles, Contact.Name,
                       Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone, Contact.Title,
                       Contact.ARC_PortalAccess__c,
                       Contact.MailingStreet, Contact.MailingCity, Contact.MailingState, Contact.MailingPostalCode
                FROM AccountContactRelation
                WHERE AccountId = :opp.AccountId
                  AND (Roles INCLUDES ('Primary Business Contact', 'Account Holder', 'Billing Contact'))
                ORDER BY CreatedDate DESC
            ];
            
            // Process contacts by role
            for (AccountContactRelation acr : acrs) {
                if (acr.Roles == null) continue;
                
                List<String> roles = acr.Roles.split(';');
                ContactData contactData = new ContactData();
                contactData.id = acr.ContactId;
                contactData.name = acr.Contact.Name;
                contactData.firstName = acr.Contact.FirstName;
                contactData.lastName = acr.Contact.LastName;
                contactData.email = acr.Contact.Email;
                contactData.phone = acr.Contact.Phone;
                contactData.title = acr.Contact.Title;
                contactData.portalAccess = acr.Contact.ARC_PortalAccess__c;
                contactData.street = acr.Contact.MailingStreet;
                contactData.city = acr.Contact.MailingCity;
                contactData.state = acr.Contact.MailingState;
                contactData.zip = acr.Contact.MailingPostalCode;
                contactData.roles = roles;
                
                // Assign to appropriate role fields
                if (roles.contains('Primary Business Contact') && result.primaryBusinessContact == null) {
                    result.primaryBusinessContact = contactData;
                }
                if (roles.contains('Account Holder') && result.accountHolder == null) {
                    result.accountHolder = contactData;
                }
                if (roles.contains('Billing Contact') && result.billingContact == null) {
                    result.billingContact = contactData;
                }
            }
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving payment contacts: ' + e.getMessage());
        }
    }
    
    /**
     * Wrapper class for ChargentOrder data
     */
    public class ChargentOrderData {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public Id accountId { get; set; }
        
        // Billing address
        @AuraEnabled public String billingStreet { get; set; }
        @AuraEnabled public String billingCity { get; set; }
        @AuraEnabled public String billingState { get; set; }
        @AuraEnabled public String billingZip { get; set; }
        
        // Payment method
        @AuraEnabled public String paymentMethod { get; set; }
        
        // Bank data
        @AuraEnabled public String bankName { get; set; }
        @AuraEnabled public String bankLast4 { get; set; }
        @AuraEnabled public String routingNumber { get; set; }
        
        // Credit card data
        @AuraEnabled public String cardLast4 { get; set; }
        @AuraEnabled public String cardExpirationMonth { get; set; }
        @AuraEnabled public String cardExpirationYear { get; set; }
    }
    
    /**
     * Wrapper class for Payment Contacts data
     */
    public class PaymentContactsData {
        @AuraEnabled public ContactData primaryBusinessContact { get; set; }
        @AuraEnabled public ContactData accountHolder { get; set; }
        @AuraEnabled public ContactData billingContact { get; set; }
    }
    
    /**
     * Wrapper class for Contact data
     */
    public class ContactData {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String portalAccess { get; set; }
        @AuraEnabled public String street { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String zip { get; set; }
        @AuraEnabled public List<String> roles { get; set; }
    }
}