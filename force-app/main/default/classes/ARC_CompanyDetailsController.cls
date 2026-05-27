public without sharing class ARC_CompanyDetailsController {

    public class EmployerData {
        @AuraEnabled public Account employer;
        @AuraEnabled public String SIC;
    }

    public class OrderData {
        @AuraEnabled public ChargentOrders__ChargentOrder__c order;
        @AuraEnabled public String CardExpiration;
        @AuraEnabled public String BankAccountType;
        @AuraEnabled public String FullAddress;
        @AuraEnabled public String AccountHolder; //(new data for getPaymentMethod)
        @AuraEnabled public String PaymentFrequency; //(new data for getPaymentMethod)
        @AuraEnabled public String BillingStreet;
        @AuraEnabled public String BillingCity;
        @AuraEnabled public String BillingState;
        @AuraEnabled public String BillingPostalCode;
        //New data
        @AuraEnabled public Boolean isSameAsPrimaryContact;
        @AuraEnabled public Boolean isBillingSameAsHolder;
        @AuraEnabled public ContactData accountHolderContact;
        @AuraEnabled public ContactData billingContactData;
        //Group account Data
        @AuraEnabled public String AccountBillingStreet;
        @AuraEnabled public String AccountBillingCity;
        @AuraEnabled public String AccountBillingState;
        @AuraEnabled public String AccountBillingPostalCode;
    }

    public class ContactData {
        @AuraEnabled public Id contactId;
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String title;
        @AuraEnabled public String portalAccess;
        @AuraEnabled public String mailingStreet;
        @AuraEnabled public String mailingCity;
        @AuraEnabled public String mailingState;
        @AuraEnabled public String mailingPostalCode;
        @AuraEnabled public Boolean isExistingContact;
    }

    public class AccountManagerData {
        @AuraEnabled public String Name;
        @AuraEnabled public String Phone;
        @AuraEnabled public String Email;
    }

    // INSERT PROJECT NAME - 2861 ================================================
    public class AccountHolderPayload {
        @AuraEnabled public String action;
        @AuraEnabled public Id accountId; 
        @AuraEnabled public ContactDTO contact;
        @AuraEnabled public AddressDTO addressDTO;
        @AuraEnabled public Boolean isSameAsPrimaryContact;
    }

    public class BillingContactPayload {
        @AuraEnabled public String action;
        @AuraEnabled public Id accountId;
        @AuraEnabled public ContactDTO contact;
        @AuraEnabled public Boolean isSameAsAccountHolder;
    }

    public class AddressDTO {

        @AuraEnabled public String MailingStreet;
        @AuraEnabled public String MailingCity;
        @AuraEnabled public String MailingState;
        @AuraEnabled public String MailingPostalCode;
        
    }

    // UHSM - 2861 ================================================

    // UHSM -2863 ==================================================

    // =========================
    // Wrapper classes
    // =========================

    public class PBCPayload {
        @AuraEnabled public String action;
        @AuraEnabled public Id accountId;
        @AuraEnabled public ContactDTO contact;
        @AuraEnabled public String roles;
    }
    
    public virtual class SavePayload {
        @AuraEnabled public CompanyDTO company;
        @AuraEnabled public PBCPayload primaryBusinessContact;
    }

    public class CompanyDTO {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        //@AuraEnabled public String Tax;
        @AuraEnabled public String FedTaxId;
        @AuraEnabled public String SIC;
        @AuraEnabled public String SICDescription;
        @AuraEnabled public String Street;
        @AuraEnabled public String City;
        @AuraEnabled public String State;
        @AuraEnabled public String PostalCode;
        //@AuraEnabled public String Email;
        @AuraEnabled public String BillingContactEmail;
    }

    public class ContactDTO {
        @AuraEnabled public Id Id;
        @AuraEnabled public String FirstName;
        @AuraEnabled public String LastName;
        @AuraEnabled public String Email;
        @AuraEnabled public String Phone;
        @AuraEnabled public String Title;
        @AuraEnabled public String PortalAccess;
        @AuraEnabled public Decimal ContactOwnershipPercentage;
    }

    public class ContactActionDTO {
        @AuraEnabled public String action;
        @AuraEnabled public Id accountId; // for ACR
        @AuraEnabled public Id contactId;
        @AuraEnabled public ContactDTO Contact;
        @AuraEnabled public List<String> roles;
        @AuraEnabled public TpaUiDTO tpaUi;
    }

    public class TpaUiDTO {
        @AuraEnabled public Boolean useExistingAccount;
        @AuraEnabled public Id accountId; // Business AccounT
        @AuraEnabled public String companyName;
        @AuraEnabled public String mailingAddress;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String zip;
    }

    public class ContactsPayload {
        @AuraEnabled public List<ContactActionDTO> creates;
        @AuraEnabled public List<ContactActionDTO> updates;
        @AuraEnabled public List<DeleteDTO> deletes;
    }

    public class CompanyContactsDTO {
        @AuraEnabled public List<AccountContactRelation> acrs;
    
        public CompanyContactsDTO(List<AccountContactRelation> acrs){
            this.acrs = acrs;
        }
    }

    public class DeleteDTO {
        @AuraEnabled public Id contactId;
        @AuraEnabled public Id acrId;
    }

    public class SaveAllPayload extends SavePayload {
        @AuraEnabled public ContactsPayload contacts;
    }

    // INSERT PROJECT NAME-2863 ==================================================

    private static final String ROLE_COC = 'Company Officer Contact';
    private static final String ROLE_PBC   = 'Primary Business Contact';
    private static final String ROLE_OTHER = 'Other';

    private static final String RT_DEVNAME_SG = 'ARC_SmallGroup';

    // =========================
    // Test hook (Account context)
    // =========================
    @TestVisible
    private static Id testAccountId;

    private static Id resolveAccountId() {
        // En tests podemos inyectar accountId para evitar depender de User.AccountId
        if (Test.isRunningTest() && testAccountId != null) {
            return testAccountId;
        }

        return [
            SELECT AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ].AccountId;
    }

    private static void log(String label, Object value) {
        System.debug('### ARC DEBUG ### ' + label + ' => ' + JSON.serialize(value));
    }

    @AuraEnabled(cacheable=true)
    public static EmployerData getCompanyDetails() {
        Id accountId = resolveAccountId();

        Account account = [
            SELECT Name, vlocity_ins__TaxID__c, vlocity_ins__CalculatedAddress__c, vlocity_ins__Email__c, BillingStreet,
                BillingCity, BillingState, BillingPostalCode, Sic, SicDesc, ARC_FederalEmployerTaxIDNumber__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        List<AccountContactRelation> billingRelations = [
            SELECT Id,
                AccountId,
                Roles,
                Contact.Email,
                ContactId
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND Roles INCLUDES ('Billing Contact')
        ];

        String billingContactEmail;
        for (AccountContactRelation acr : billingRelations) {
            if (acr.Contact != null && String.isNotBlank(acr.Contact.Email)) {
                billingContactEmail = acr.Contact.Email;
                break;
            }
        }

        account.vlocity_ins__Email__c = String.isNotBlank(billingContactEmail)
                                        ? billingContactEmail
                                        : null;

        // if (String.isNotBlank(billingContactEmail)) {
        //     account.vlocity_ins__Email__c = billingContactEmail;
        // }

        EmployerData data = new EmployerData();

        data.employer = account;
        if (account.Sic != null) {
            data.SIC = account.Sic + ' - ' + account.SicDesc;
        } else {
            data.SIC = null;
        }
        return data;
    }

    @AuraEnabled(cacheable=true)
    public static List<AccountContactRelation> getPrimaryContact() {
        Id accountId = resolveAccountId();

        return [
            SELECT Id, Roles, Account.Name, Account.IsCustomerPortal,
                Contact.FirstName, Contact.LastName, Contact.Name,
                Contact.Title, Contact.Phone, Contact.Email, Contact.ARC_PortalAccess__c
            FROM AccountContactRelation
            WHERE AccountId = :accountId
        ];
    }

    @AuraEnabled(cacheable=true)
    public static CompanyContactsDTO loadCompanyContacts(){
        Id accountId = resolveAccountId();

        List<AccountContactRelation> acrs = [
            SELECT Id, ContactId, Roles,
               Account.Name,
               Contact.AccountId,
               Contact.Account.Name,
               Contact.Account.BillingStreet,
               Contact.Account.BillingCity,
               Contact.Account.BillingState,
               Contact.Account.BillingPostalCode,
               Contact.FirstName,
               Contact.LastName,
               Contact.Email,
               Contact.Phone,
               Contact.Title,
               Contact.ARC_PortalAccess__c,
               Contact.ARC_OwnershipPercentage__c
            FROM AccountContactRelation
            WHERE AccountId = :accountId
        ];

        return new CompanyContactsDTO(acrs);
    }

    
    //new method to load contacts with user info for company details page
    //BUG-3534: added hasUser property to identify if contact has an associated user
    // @AuraEnabled
    // public static void updateContactsWithUser(List<Contact> contacts){
    //     try {
    //         if (contacts == null || contacts.isEmpty()){
    //             return;
    //         } 
    //         update contacts;
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> loadCompanyContactsWithUsers(){
        Id accountId = resolveAccountId();

        List<AccountContactRelation> acrs = [
            SELECT Id, ContactId, Roles,
            Account.Name,
            Contact.AccountId,
            Contact.Account.Name,
            Contact.Account.BillingStreet,
            Contact.Account.BillingCity,
            Contact.Account.BillingState,
            Contact.Account.BillingPostalCode,
            Contact.FirstName,
            Contact.LastName,
            Contact.Email,
            Contact.Phone,
            Contact.Title,
            Contact.ARC_PortalAccess__c,
//            Contact.ARC_TriggerUserDeactivation__c
            Contact.ARC_OwnershipPercentage__c
            FROM AccountContactRelation
            WHERE AccountId = :accountId
        ];

        Set<Id> contactIds = new Set<Id>();
        for (AccountContactRelation acr : acrs) {
            contactIds.add(acr.ContactId);
        }
        
        Map<Id, Boolean> contactHasUserMap = new Map<Id, Boolean>();
        for (Id contactId : contactIds) {
            contactHasUserMap.put(contactId, false);
        }
        
        for (User u : [SELECT ContactId FROM User WHERE ContactId IN :contactIds]) {
            contactHasUserMap.put(u.ContactId, true);
        }

        List<Map<String, Object>> enhancedContacts = new List<Map<String, Object>>();
        
        for (AccountContactRelation acr : acrs) {
            Map<String, Object> contactData = new Map<String, Object>();
            
            contactData.put('Id', acr.Id);
            contactData.put('ContactId', acr.ContactId);
            contactData.put('Roles', acr.Roles);
            contactData.put('AccountId', acr.AccountId);
            contactData.put('Account', new Map<String, Object>{
                'Name' => acr.Account?.Name
            });
            
            Map<String, Object> contactMap = new Map<String, Object>();
            contactMap.put('Id', acr.ContactId);
            contactMap.put('FirstName', acr.Contact?.FirstName);
            contactMap.put('LastName', acr.Contact?.LastName);
            contactMap.put('Email', acr.Contact?.Email);
            contactMap.put('Phone', acr.Contact?.Phone);
            contactMap.put('Title', acr.Contact?.Title);
            contactMap.put('ARC_PortalAccess__c', acr.Contact?.ARC_PortalAccess__c);
            //contactMap.put('ARC_TriggerUserDeactivation__c', acr.Contact?.ARC_TriggerUserDeactivation__c);
            contactMap.put('ARC_OwnershipPercentage__c', acr.Contact?.ARC_OwnershipPercentage__c);
            contactMap.put('AccountId', acr.Contact?.AccountId);
            contactMap.put('Account', new Map<String, Object>{
                'Name'            => acr.Contact?.Account?.Name,
                'BillingStreet'   => acr.Contact?.Account?.BillingStreet,
                'BillingCity'     => acr.Contact?.Account?.BillingCity,
                'BillingState'    => acr.Contact?.Account?.BillingState,
                'BillingPostalCode' => acr.Contact?.Account?.BillingPostalCode
            });
            
            contactData.put('Contact', contactMap);
            
            contactData.put('hasUser', contactHasUserMap.get(acr.ContactId));
            
            enhancedContacts.add(contactData);
        }

        Map<String, Object> result = new Map<String, Object>();
        result.put('acrs', enhancedContacts);
        result.put('success', true);
        
        return result;
    }

    @AuraEnabled
    public static void requestContactDeletion(Id contactId) {
        // ++ LOG PARA VERIFICAR QUE LLEGA
        System.debug('++ requestContactDeletion RECIBIDO para contactId: ' + contactId);
        System.debug('++ Usuario: ' + UserInfo.getUserName());
        System.debug('++ Perfil: ' + [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name);
        
        try {
            // Publicar evento
            Database.SaveResult result = EventBus.publish(new SG_Portal_User_Provisioning__e(
                ContactId__c = String.valueOf(contactId),
                ARC_TriggerUserDeactivation__c = true  
            ));
            
            // ++ LOG DEL RESULTADO
            System.debug('++ Resultado de publicación: ' + result);
            System.debug('++ Success? ' + result.isSuccess());
            if (!result.isSuccess()) {
                System.debug('++ Errores: ' + result.getErrors());
            }
            
        } catch (Exception e) {
            // ++ LOG DEL ERROR
            System.debug('++ EXCEPCIÓN: ' + e.getMessage());
            System.debug('++ Stack: ' + e.getStackTraceString());
        }
        
        System.debug('++++++ FIN requestContactDeletion');
    }
    //end of bug-3534 method


    @AuraEnabled(cacheable=true)
    public static AccountManagerData getAccountManager() {

        Id accountId = resolveAccountId();
        return ARC_AccountOwnerHelper.getAccountManager(accountId);
    }

    // INSERT PROJECT NAME - 2861 ================================================
    @AuraEnabled(cacheable=true)
    public static OrderData getPaymentMethod() {

        Id accountId = resolveAccountId();
        List<Contract> contracts = [
            SELECT Id, Status, ARC_RecurringMonthlyOrder__r.ChargentOrders__Account__c, ARC_RecurringMonthlyOrder__c, ARC_RecurringMonthlyOrder__r.ChargentOrders__Payment_Method__c, ARC_RecurringMonthlyOrder__r.ChargentOrders__Credit_Card_Name__c, ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_First_Name__c, ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Last_Name__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Name__c, ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Name__c, ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Type__c, ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Number__c, ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Number__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Month_Indicator__c, ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Year_Indicator__c, ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Last_4__c, ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Last_4__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Address__c, ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_City__c, ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_State__c, ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Zip_Postal__c, ARC_RecurringMonthlyOrder__r.ChargentOrders__Payment_Frequency__c
            FROM Contract
            WHERE Status IN ('Activated', 'Awaiting Activation')
            AND AccountId = :accountId
        ];

        // pull account holder information
        List<AccountContactRelation> acrs = [
            SELECT ContactId, Roles, Contact.FirstName, Contact.LastName, Contact.Email,
                Contact.Phone, Contact.Title, Contact.ARC_PortalAccess__c,
                Contact.MailingStreet, Contact.MailingCity,
                Contact.MailingState, Contact.MailingPostalCode
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND Roles INCLUDES ('Account Holder')
            LIMIT 1
        ];

        // pull primary business contact
        List<AccountContactRelation> pbcAcrs = [
            SELECT ContactId
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND Roles INCLUDES ('Primary Business Contact')
            LIMIT 1
        ];

        // pull billing contact
        List<AccountContactRelation> billingAcrs = [
            SELECT ContactId, Roles,
                Contact.FirstName, Contact.LastName, Contact.Email,
                Contact.Phone, Contact.Title, Contact.ARC_PortalAccess__c
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND Roles INCLUDES ('Billing Contact')
            LIMIT 1
        ];

        //pull Group Account Addres
        Account groupAccount = [
           SELECT BillingStreet, BillingCity, BillingState, BillingPostalCode 
           FROM Account
           WHERE Id = :accountId
           LIMIT 1
        ];


        Id pbcContactId = !pbcAcrs.isEmpty() ? pbcAcrs[0].ContactId : null;
        Id billingContactId = !billingAcrs.isEmpty() ? billingAcrs[0].ContactId : null;

        String accountHolderName;

        if (!acrs.isEmpty() && acrs[0].Contact != null) {
            accountHolderName =
                acrs[0].Contact.FirstName + ' ' + acrs[0].Contact.LastName;
        }
        //--------------------------------

        Contract selectedContract = contracts[0];
        for (Contract cont : contracts) {
            if (cont.Status == 'Activated') {
                selectedContract = cont;
                break;
            }
        }
        OrderData data = new OrderData();
        data.order = selectedContract.ARC_RecurringMonthlyOrder__r;
        if (selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Month_Indicator__c != null && selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Year_Indicator__c != null) {
            data.CardExpiration = selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Month_Indicator__c + '/' + selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Year_Indicator__c;
        } else {
            data.CardExpiration = null;
        }
        if (selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Type__c != null) {
            data.BankAccountType = selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Type__c;
        } else {
            data.BankAccountType = '';
        }

        //---------------------------------
        //GRoup account billing Address
        data.AccountBillingStreet = groupAccount.BillingStreet;
        data.AccountBillingState = groupAccount.BillingState;
        data.AccountBillingCity = groupAccount.BillingCity;
        data.AccountBillingPostalCode = groupAccount.BillingPostalCode;
        //--------------------------------
        //set payment frequency
        if(selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Payment_Frequency__c != null){
            data.PaymentFrequency = selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Payment_Frequency__c;
        } else{
            data.PaymentFrequency = '';
        }
        //--------------------------------
        data.FullAddress = '';
        if (selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Address__c != null) {
            data.FullAddress = selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Address__c + '<br>';
        }
        if (selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_City__c != null) {
            data.FullAddress = data.FullAddress + selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_City__c;
        }
        if (selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_State__c != null) {
            data.FullAddress = data.FullAddress + ' ' + selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_State__c;
        }
        if (selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Zip_Postal__c != null) {
            data.FullAddress = data.FullAddress + ' ' + selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Zip_Postal__c;
        }

        //--------------------------------
        //set billing address fields
        data.BillingStreet = '';
        if (selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Address__c != null) {
            data.BillingStreet = selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Address__c;
        }
        data.BillingCity = '';
        if (selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_City__c != null) {
            data.BillingCity = selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_City__c;
        }
        data.BillingState = '';
        if (selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_State__c != null) {
            data.BillingState = selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_State__c;
        }
        data.BillingPostalCode = '';
        if (selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Zip_Postal__c != null) {
            data.BillingPostalCode = selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Zip_Postal__c;
        }
        //--------------------------------
        //set account holder name
        if (accountHolderName != null){
        if (accountHolderName != null) {
                data.AccountHolder = accountHolderName;
            }
        }
        //--------------------------------

        // determine if account holder is same as primary business contact
        Id accountHolderContactId = !acrs.isEmpty() ? acrs[0].ContactId : null;

        if (accountHolderContactId == null) {
            data.isSameAsPrimaryContact = true;
        } else {
            data.isSameAsPrimaryContact = (pbcContactId != null && accountHolderContactId == pbcContactId);
        }

        // determine if billing contact is same as account holder
        if (billingContactId == null) {
            data.isBillingSameAsHolder = true;
        } else {
            data.isBillingSameAsHolder = (accountHolderContactId != null && billingContactId == accountHolderContactId);
        }

        // populate account holder contact data if different from primary business contact
        if (!data.isSameAsPrimaryContact && !acrs.isEmpty()) {
            ContactData ahData = new ContactData();
            ahData.contactId         = acrs[0].ContactId;
            ahData.firstName         = acrs[0].Contact.FirstName;
            ahData.lastName          = acrs[0].Contact.LastName;
            ahData.email             = acrs[0].Contact.Email;
            ahData.phone             = acrs[0].Contact.Phone;
            ahData.title             = acrs[0].Contact.Title;
            ahData.portalAccess      = acrs[0].Contact.ARC_PortalAccess__c;
            ahData.mailingStreet     = acrs[0].Contact.MailingStreet;
            ahData.mailingCity       = acrs[0].Contact.MailingCity;
            ahData.mailingState      = acrs[0].Contact.MailingState;
            ahData.mailingPostalCode = acrs[0].Contact.MailingPostalCode;
            // if the ACR has more roles than just Account Holder, it was an existing contact
            ahData.isExistingContact = acrs[0].Roles != 'Account Holder';
            data.accountHolderContact = ahData;
        }

        // populate billing contact data if different from account holder
        if (!data.isBillingSameAsHolder && !billingAcrs.isEmpty()) {
            ContactData bcData = new ContactData();
            bcData.contactId         = billingAcrs[0].ContactId;
            bcData.firstName         = billingAcrs[0].Contact.FirstName;
            bcData.lastName          = billingAcrs[0].Contact.LastName;
            bcData.email             = billingAcrs[0].Contact.Email;
            bcData.phone             = billingAcrs[0].Contact.Phone;
            bcData.title             = billingAcrs[0].Contact.Title;
            bcData.portalAccess      = billingAcrs[0].Contact.ARC_PortalAccess__c;
            // if the ACR has more roles than just Billing Contact, it was an existing contact
            bcData.isExistingContact = billingAcrs[0].Roles != 'Billing Contact';
            data.billingContactData  = bcData;
        }

        //--------------------------------
        return data;
    }

    private static Id smallGroupRTId {
        get {
            if (smallGroupRTId == null) {
                smallGroupRTId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
                    .get('ARC_SmallGroup').getRecordTypeId();
            }
            return smallGroupRTId;
        }
        set;
    }

    //new update payment method
    @AuraEnabled
    public static void updatePaymentMethod(Map<String, Object> payload) {
        if (payload == null || !payload.containsKey('orderId')) {
            throw new AuraHandledException('Invalid payment payload.');
        }

        Id orderId = (Id) payload.get('orderId');
        
        ChargentOrders__ChargentOrder__c order = [
            SELECT Id, ChargentOrders__Account__c,
                ChargentOrders__Payment_Method__c,
                ChargentOrders__Card_Number__c,
                ChargentOrders__Card_Expiration_Month__c,
                ChargentOrders__Card_Expiration_Year__c,
                ChargentOrders__Credit_Card_Name__c,
                ChargentOrders__Bank_Name__c,
                ChargentOrders__Bank_Routing_Number__c,
                ChargentOrders__Bank_Account_Number__c,
                ChargentOrders__Bank_Account_Name__c,
                ChargentOrders__Bank_Account_Last_4__c,
                ChargentOrders__Bank_Account_Type__c,
                ChargentOrders__Billing_Address__c,
                ChargentOrders__Billing_City__c,
                ChargentOrders__Billing_State__c,
                ChargentOrders__Billing_Zip_Postal__c,
                ChargentOrders__Account__r.BillingStreet,
                ChargentOrders__Account__r.BillingCity,
                ChargentOrders__Account__r.BillingState,
                ChargentOrders__Account__r.BillingPostalCode
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id = :orderId
            LIMIT 1
        ];

        // ================= PAYMENT METHOD =================
        String paymentMethod = (String) payload.get('paymentMethod');
        order.ChargentOrders__Payment_Method__c = paymentMethod;

        // ================= CREDIT CARD =================
        if (paymentMethod == 'Credit Card') {
            order.ChargentOrders__Card_Number__c = (String) payload.get('cardNumber');
            order.ChargentOrders__Card_Expiration_Month__c = (String) payload.get('expirationMonth');
            order.ChargentOrders__Card_Expiration_Year__c = (String) payload.get('expirationYear');
            
            //clear values
            order.ChargentOrders__Bank_Name__c = null;
            order.ChargentOrders__Bank_Routing_Number__c = null;
            order.ChargentOrders__Bank_Account_Number__c = null;
            order.ChargentOrders__Bank_Account_Last_4__c = null;
            order.ChargentOrders__Bank_Account_Type__c = null;
        }

        // ================= BANK ACCOUNT =================
        if (paymentMethod == 'Bank Account') {
            order.ChargentOrders__Bank_Name__c = (String) payload.get('bankName');
            order.ChargentOrders__Bank_Routing_Number__c = (String) payload.get('bankRoutingNumber');
            order.ChargentOrders__Bank_Account_Number__c = (String) payload.get('bankAccountNumber');
            order.ChargentOrders__Bank_Account_Type__c = 'Checking';

            //clear values
            order.ChargentOrders__Card_Number__c = null;
            order.ChargentOrders__Card_Expiration_Month__c = null;
            order.ChargentOrders__Card_Expiration_Year__c = null;
        }


        //===============Billing Address ===============
         if (payload.containsKey('billingAddress')) {
            Object billingAddressObj = payload.get('billingAddress');
            
            if (billingAddressObj != null) {
                String billingAddressJson = JSON.serialize(billingAddressObj);
                if (String.isNotBlank(billingAddressJson)) {
                    Map<String, Object> billingAddress = (Map<String, Object>) JSON.deserializeUntyped(billingAddressJson);
                    
                    order.ChargentOrders__Billing_Address__c = (String) billingAddress.get('Street');
                    order.ChargentOrders__Billing_City__c = (String) billingAddress.get('City');
                    order.ChargentOrders__Billing_State__c = (String) billingAddress.get('State');
                    order.ChargentOrders__Billing_Zip_Postal__c = (String) billingAddress.get('PostalCode');
                }
            } else {
                order.ChargentOrders__Billing_Address__c = order.ChargentOrders__Account__r.BillingStreet;
                order.ChargentOrders__Billing_City__c = order.ChargentOrders__Account__r.BillingCity;
                order.ChargentOrders__Billing_State__c = order.ChargentOrders__Account__r.BillingState;
                order.ChargentOrders__Billing_Zip_Postal__c = order.ChargentOrders__Account__r.BillingPostalCode;
            }
        }

        update order;
        
        // Account Holder
        if (payload.containsKey('accountHolderPayload')) {
            String accountHolderJson = JSON.serialize(payload.get('accountHolderPayload'));
            if (String.isNotBlank(accountHolderJson)) {
                updateAccountHolderRole(accountHolderJson);
            }
        }
        
        // Billing Contact
        if (payload.containsKey('billingContactPayload')) {
            String billingContactJson = JSON.serialize(payload.get('billingContactPayload'));
            if (String.isNotBlank(billingContactJson)) {
                updateBillingContactRole(billingContactJson);
            }
        }

    }
    //updates or creates record with rol of Billing Contact
    @AuraEnabled
    public static void updateBillingContactRole(String payloadJson) {
        if (String.isBlank(payloadJson)) {
            throw new AuraHandledException('Payload is empty.');
        }
        
        BillingContactPayload payload = (BillingContactPayload) JSON.deserialize(payloadJson, BillingContactPayload.class);
        Id accountId = payload.accountId;
        String action = payload.action;
        
     
        if (payload.isSameAsAccountHolder == true) {
            List<AccountContactRelation> accountHolderRelations = [
                SELECT ContactId
                FROM AccountContactRelation
                WHERE AccountId = :accountId
                AND Roles INCLUDES ('Account Holder')
                LIMIT 1
            ];
            
            if (!accountHolderRelations.isEmpty()) {
                updateContactRole(accountId, accountHolderRelations[0].ContactId, 'Billing Contact', null);
                return;
            }
        }
        
        ContactDTO contactDTO = payload.contact;
        
        
        if (action == 'SELECT' && contactDTO != null && contactDTO.Id != null) {
            updateContactRole(accountId, contactDTO.Id, 'Billing Contact', null);
        } else if (action == 'CREATE' && contactDTO != null) {
           
            Contact newContact = new Contact(
                RecordTypeId = smallGroupRTId,
                AccountId = accountId,
                FirstName = contactDTO.FirstName,
                LastName = contactDTO.LastName,
                Email = contactDTO.Email,
                Phone = contactDTO.Phone,
                Title = contactDTO.Title,
                ARC_PortalAccess__c = contactDTO.PortalAccess
            );
            insert newContact;
            
            updateContactRole(accountId, newContact.Id, 'Billing Contact', null);
        }
    }

    //updates or creates record with rol of Acccount Holder
   @AuraEnabled
    public static void updateAccountHolderRole(String payloadJson) {
        if (String.isBlank(payloadJson)) {
            throw new AuraHandledException('Payload is empty.');
        }
        
        AccountHolderPayload payload = (AccountHolderPayload) JSON.deserialize(payloadJson, AccountHolderPayload.class);
        Id accountId = payload.accountId;
        String action = payload.action;
        
        if (payload.isSameAsPrimaryContact == true) {
            List<AccountContactRelation> pbcRelations = [
                SELECT ContactId
                FROM AccountContactRelation
                WHERE AccountId = :accountId
                AND Roles INCLUDES ('Primary Business Contact')
                LIMIT 1
            ];
            
            if (!pbcRelations.isEmpty()) {
                updateContactRole(accountId, pbcRelations[0].ContactId, 'Account Holder', null);
                return;
            }
        }
        
        ContactDTO contactDTO = payload.contact;
        AddressDTO addressDTO = payload.addressDTO;
        
        if (action == 'SELECT' && contactDTO != null && contactDTO.Id != null) {
            updateContactRole(accountId, contactDTO.Id, 'Account Holder', null);
        } else if (action == 'CREATE' && contactDTO != null) {
            
            Contact newContact = new Contact(
                RecordTypeId = smallGroupRTId, 
                AccountId = accountId,
                FirstName = contactDTO.FirstName,
                LastName = contactDTO.LastName,
                Email = contactDTO.Email,
                MailingStreet = addressDTO != null ? addressDTO.MailingStreet : null,
                MailingCity = addressDTO != null ? addressDTO.MailingCity : null,
                MailingState = addressDTO != null ? addressDTO.MailingState : null,
                MailingPostalCode = addressDTO != null ? addressDTO.MailingPostalCode : null,
                ARC_PortalAccess__c = contactDTO.PortalAccess
            );
            insert newContact;
            
            updateContactRole(accountId, newContact.Id, 'Account Holder', null);
        }
    }

   //update role
    private static void updateContactRole(Id accountId, Id contactId, String roleToAdd, String roleToRemove) {
        List<AccountContactRelation> existingAcrs = [
            SELECT Id, ContactId, Roles
            FROM AccountContactRelation
            WHERE AccountId = :accountId
        ];
        
        for (AccountContactRelation acr : existingAcrs) {
            if (acr.Roles != null && acr.Roles.contains(roleToAdd) && acr.ContactId != contactId) {
                acr.Roles = removeRole(acr.Roles, roleToAdd);
                update acr;
            }
        }
      
        AccountContactRelation targetAcr;
        for (AccountContactRelation acr : existingAcrs) {
            if (acr.ContactId == contactId) {
                targetAcr = acr;
                break;
            }
        }
        
        if (targetAcr != null) {
           
            targetAcr.Roles = addRole(targetAcr.Roles, roleToAdd);
            if (roleToRemove != null) {
                targetAcr.Roles = removeRole(targetAcr.Roles, roleToRemove);
            }
            update targetAcr;
        } else {
    
            insert new AccountContactRelation(
                AccountId = accountId,
                ContactId = contactId,
                Roles = roleToAdd
            );
        }
    }

    private static String removeRole(String roles, String roleToRemove) {
        if (String.isBlank(roles)) return null;

        Set<String> roleSet = new Set<String>();
        roleSet.addAll(roles.split(';')); 

        roleSet.remove(roleToRemove);

        return roleSet.isEmpty() ? null : String.join(new List<String>(roleSet), ';');
    }


    // UHSM - 2861 ================================================

    //-------------------------------------------------------------

    @AuraEnabled
    public static Contact updatePrimaryContact(Map<String, String> contactValues) {
        Contact contact = new Contact();
        contact.Id = contactValues.get('Id');
        contact.Title = contactValues.get('Title');
        contact.FirstName = contactValues.get('FirstName');
        contact.LastName = contactValues.get('LastName');
        contact.Email = contactValues.get('Email');
        contact.Phone = contactValues.get('Phone');
        update contact;
        return contact;
    }

    // @AuraEnabled
    private static void updateCompany(CompanyDTO c) {
        if (c == null || c.Id == null) return;

        Account company = new Account(
            Id = c.Id,
            Name = c.Name,
            aRC_FederalEmployerTaxIDNumber__c = c.FedTaxId,
            //vlocity_ins__Email__c = c.BillingContactEmail,
            BillingStreet = c.Street,
            BillingCity = c.City,
            BillingState = c.State,
            BillingPostalCode = c.PostalCode,
            Sic = c.SIC,
            SicDesc = c.SICDescription
        );

        update company;
    }

    private static void updateBillingContactEmail(Id accountId, String emailAddress) {
        if (accountId == null || String.isBlank(emailAddress)) return;
    
        List<AccountContactRelation> billingRelations = [
            SELECT Id, ContactId, Contact.Email
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND Roles INCLUDES ('Billing Contact')
            LIMIT 1
        ];

    
        if (billingRelations.isEmpty()) {
            throw new AuraHandledException('No Billing Contact found for this company.');
        }
    
        AccountContactRelation billingRelation = billingRelations[0];

        if (billingRelation.ContactId == null) {
            throw new AuraHandledException('Billing Contact is missing a related contact.');
        }

        String currentEmail = billingRelation.Contact != null ? billingRelation.Contact.Email : null;
        if (currentEmail == emailAddress) {
            return;
        }

        update new Contact(
            Id = billingRelation.ContactId,
            Email = emailAddress
        );

        System.debug('Billing contact email updated successfully.');
    }

    public static Boolean canEditCompanyDetails(){
        return FeatureManagement.checkPermission('Employer_Portal_Edit');
    }

    @AuraEnabled(cacheable=true)
    public static Boolean canEdit(){
        return FeatureManagement.checkPermission('Employer_Portal_Edit');
    }


    // UHSM-2863 ==================================================

    // =========================
    // SAVE METHOD
    // =========================

    @AuraEnabled
    public static void saveCompanyAndPBC(String payloadJson) {
        try {
            if (String.isBlank(payloadJson)) {
                throw new AuraHandledException('Payload is empty.');
            }

            SaveAllPayload payload = (SaveAllPayload) JSON.deserialize(payloadJson, SaveAllPayload.class);

            if (payload == null) {
                throw new AuraHandledException('Payload is empty or invalid.');
            }

            if (payload.primaryBusinessContact == null) {
                throw new AuraHandledException('Primary Business Contact is required.');
            }

            PBCPayload pbc = payload.primaryBusinessContact;
            Id accountId = pbc.accountId;
            String action = pbc.action;

            Id idAccPortalUser = resolveAccountId();

            // Update company first
            if (payload.company != null && payload.company.Id != null) {
                updateCompany(payload.company);
            }

            // Detect if Billing Contact = PBC
            Id billingContactId = null;
            Boolean billingIsPbc = false;

            if (payload.company != null && payload.company.Id != null && pbc.contact != null && pbc.contact.Id != null) {
                billingContactId = getBillingContactId(payload.company.Id);
                billingIsPbc = (billingContactId != null && billingContactId == pbc.contact.Id);
            }

            // If same person, use one single update path through PBC
            if (billingIsPbc && String.isNotBlank(payload.company.BillingContactEmail) && pbc.contact != null) {
                pbc.contact.Email = payload.company.BillingContactEmail;
            }
            // If different person, update Billing Contact separately
            else if (payload.company != null && payload.company.Id != null && String.isNotBlank(payload.company.BillingContactEmail)) {
                updateBillingContactEmail(payload.company.Id, payload.company.BillingContactEmail);
            }

            /* ==============================
                FIND CURRENT PBC (IF ANY)
            ============================== */
            AccountContactRelation currentPbc;
            List<AccountContactRelation> existingAcrs = [
                SELECT Id, ContactId, Roles
                FROM AccountContactRelation
                WHERE AccountId = :accountId
            ];

            for (AccountContactRelation acr : existingAcrs) {
                if (acr.Roles != null && acr.Roles.contains('Primary Business Contact')) {
                    currentPbc = acr;
                    break;
                }
            }

            List<AccountContactRelation> acrsToUpdate = new List<AccountContactRelation>();
            List<AccountContactRelation> acrsToInsert = new List<AccountContactRelation>();

            if (action == 'KEEP') {
                validateContactAccess(pbc.contact.Id, accountId);
                ensureSmallGroupRecordType(pbc.contact.Id);
                updateContact(pbc.contact);

            } else if (action == 'SELECT') {
                Id newContactId = pbc.contact.Id;

                if (currentPbc != null && currentPbc.ContactId != newContactId) {
                    removePrimaryRole(currentPbc);
                    acrsToUpdate.add(currentPbc);
                }

                AccountContactRelation selectedAcr = findAcr(existingAcrs, newContactId);

                if (selectedAcr != null) {
                    addPrimaryRole(selectedAcr);
                    acrsToUpdate.add(selectedAcr);
                } else {
                    acrsToInsert.add(new AccountContactRelation(
                        AccountId = accountId,
                        ContactId = newContactId,
                        Roles = 'Primary Business Contact'
                    ));
                }

                validateContactAccess(pbc.contact.Id, accountId);
                ensureSmallGroupRecordType(newContactId);
                updateContact(pbc.contact);

            } else if (action == 'CREATE') {
                Id sgRTId = getSmallGroupRtId();

                Contact newContact = new Contact(
                    RecordTypeId = sgRTId,
                    AccountId = idAccPortalUser,
                    FirstName = pbc.contact.FirstName,
                    LastName = pbc.contact.LastName,
                    Email = pbc.contact.Email,
                    Phone = pbc.contact.Phone,
                    Title = pbc.contact.Title,
                    ARC_PortalAccess__c = pbc.contact.PortalAccess
                );

                insert newContact;

                if (currentPbc != null) {
                    removePrimaryRole(currentPbc);
                    acrsToUpdate.add(currentPbc);
                }

                AccountContactRelation newAcr = [
                    SELECT Id, Roles
                    FROM AccountContactRelation
                    WHERE AccountId = :idAccPortalUser
                    AND ContactId = :newContact.Id
                    LIMIT 1
                ];

                newAcr.Roles = addRole(newAcr.Roles, 'Primary Business Contact');
                acrsToUpdate.add(newAcr);
            }

            if (!acrsToUpdate.isEmpty()) {
                update acrsToUpdate;
            }

            if (!acrsToInsert.isEmpty()) {
                insert acrsToInsert;
            }

            if (payload.contacts != null) {
                processContacts(payload.contacts, accountId);
            }

        } catch (DmlException dmlEx) {
            System.debug('DML ERROR: ' + dmlEx.getMessage());
            System.debug('DML STACK: ' + dmlEx.getStackTraceString());

            for (Integer i = 0; i < dmlEx.getNumDml(); i++) {
                System.debug('DML ERROR ' + i + ': ' + dmlEx.getDmlMessage(i));
            }

            throw new AuraHandledException('DML Error: ' + dmlEx.getMessage());

        } catch (Exception e) {
            System.debug('GENERAL ERROR: ' + e.getMessage());
            System.debug('STACK TRACE: ' + e.getStackTraceString());

            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
    }
    
    /* ==============================
       HELPERS
       ============================== */

    private static AccountContactRelation findAcr(
        List<AccountContactRelation> acrs,
        Id contactId
    ) {
        for (AccountContactRelation acr : acrs) {
            if (acr.ContactId == contactId) {
                return acr;
            }
        }
        return null;
    }

    //Validate that contact belongs to the portal user's account
    private static void validateContactAccess(Id contactId, Id accountId){
        Integer countAcr = [
            SELECT COUNT()
            FROM AccountContactRelation
            WHERE ContactId = :contactId
            AND AccountId = :accountId
        ];

        if (countAcr == 0){
            throw new AuraHandledException('You do not have access to modify this Contact.');
        }
    }

    private static void updateContact(ContactDTO dto) {
        if (dto == null || dto.Id == null) return;

        Contact c = new Contact(
            Id = dto.Id,
            FirstName = dto.FirstName,
            LastName  = dto.LastName,
            Email     = dto.Email,
            Phone     = dto.Phone,
            Title     = dto.Title,
            ARC_PortalAccess__c = dto.PortalAccess
        );
        update c;
    }

    private static Set<String> parseRoles(String rolesStr) {
        Set<String> out = new Set<String>();
        if (String.isBlank(rolesStr)) return out;

        for (String p : rolesStr.split('[;,]')) {
            String r = p == null ? null : p.trim();
            if (!String.isBlank(r)) out.add(r);
        }
        return out;
    }
    
    private static String serializeRoles(Set<String> roles) {
        if (roles == null || roles.isEmpty()) {
            return ROLE_OTHER;
        }
        List<String> listy = new List<String>();
        for (String r : roles) {
            if (!String.isBlank(r)) listy.add(r.trim());
        }
        if (listy.isEmpty()) listy.add(ROLE_OTHER);
        listy.sort();
        return String.join(listy, ';');
    }
    
    //Remove Primary Business to old PBC
    private static void removePrimaryRole(AccountContactRelation acr){
        Set<String> roles = parseRoles(acr.Roles);
        roles.remove(ROLE_PBC);
        acr.Roles = serializeRoles(roles);
    }

    //Add Primary Business Contact to the new contact
    private static void addPrimaryRole(AccountContactRelation acr){
        Set<String> roles = parseRoles(acr.Roles);
        roles.add(ROLE_PBC);
        acr.Roles = serializeRoles(roles);
    }

    private static String addRole(String existingRoles, String roleToAdd){
        Set<String> roles = parseRoles(existingRoles);
        if (!String.isBlank(roleToAdd)) roles.add(roleToAdd.trim());
        return serializeRoles(roles);
    }

    private static void processContacts(ContactsPayload contacts, Id accountId) {
        if (contacts.creates != null && !contacts.creates.isEmpty()) {
            handleCreates(contacts.creates);
        }

        if (contacts.updates != null && !contacts.updates.isEmpty()) {
            handleUpdates(contacts.updates, accountId);
        }

        if (contacts.deletes != null && !contacts.deletes.isEmpty()) {
            handleDeletes(contacts.deletes);
        }
    }

    private static void handleCreates(List<ContactActionDTO> creates) {
        for (ContactActionDTO row: creates) {    
            // This is the GROUP account to relate via ACR
            Id groupAccountId = row.accountId;

            if (groupAccountId == null){
                throw new AuraHandledException('CREATE contact missing accountId (groupAccountId)');
            }
            Id contactAccountId = groupAccountId; // default

            if (row.Contact == null) {
                 throw new AuraHandledException('CREATE contact missing Contact data');
            }

            // Determine the BUSINESS account where the Contact will live
            Id businessAccountId = null;

            if (row.tpaUi != null) {
                if (row.tpaUi.useExistingAccount == true && row.tpaUi.accountId != null) {
                    businessAccountId = row.tpaUi.accountId;
                } else if (row.tpaUi.useExistingAccount == false) {
                    // Create new Business Account
                    if (String.isBlank(row.tpaUi.companyName)) {
                        throw new AuraHandledException('TPA Create New Account requires companyName');
                    }
    
                    // Get Business_Account RT (developer name)
                    Id businessRtId = Schema.SObjectType.Account
                        .getRecordTypeInfosByDeveloperName()
                        .get('Business_Account')
                        .getRecordTypeId();
    
                    Account ba = new Account(
                        Name = row.tpaUi.companyName,
                        RecordTypeId = businessRtId,
                        BillingStreet = row.tpaUi.mailingAddress,
                        BillingCity = row.tpaUi.city,
                        BillingState = row.tpaUi.state,
                        BillingPostalCode = row.tpaUi.zip
                    );
                    insert ba;
                    businessAccountId = ba.Id;
                }
            }

            // Fallback: if not TPA UI provided, keep old behavior
            if (businessAccountId == null) {
                businessAccountId = groupAccountId;
            }
    
            Boolean isTpaExistingBizAcc =
                row.tpaUi != null &&
                row.tpaUi.useExistingAccount == true &&
                row.tpaUi.accountId != null;
    
            if (isTpaExistingBizAcc) {
                contactAccountId = row.tpaUi.accountId;
            }
    
            // Create Contact on the correct Account
            Contact c = new Contact(
                //AccountId = contactAccountId,
                AccountId = businessAccountId,
                RecordTypeId = smallGroupRTId,
                FirstName = row.Contact.FirstName,
                LastName  = row.Contact.LastName,
                Email     = row.Contact.Email,
                Phone     = row.Contact.Phone,
                Title     = row.Contact.Title,
                ARC_PortalAccess__c = row.Contact.PortalAccess,
                ARC_OwnershipPercentage__c = row.Contact.ContactOwnershipPercentage
            );
    
            Database.SaveResult sr = Database.insert(c, false);
            if (!sr.isSuccess()) {
                throw new AuraHandledException(
                    'Contact insert failed: ' + sr.getErrors()[0].getMessage()
                );
            }
    
            //3) Build role set
            Set<String> roleSet = new Set<String>();
            if (row.roles != null) {
                for (String r : row.roles) {
                    if (!String.isBlank(r)) roleSet.add(r.trim());
                }
            }
            if (roleSet.contains('Company Officer Contact')) {
                enforceSingleCompanyOfficer(groupAccountId, c.Id);
            }
            if (roleSet.isEmpty()) {
                roleSet.add('Other');
            }
            List<String> rolesList = new List<String>(roleSet);
            rolesList.sort();
            String rolesJoined = String.join(rolesList, ';');
    
            // 4) Ensure ACR exists on the GROUP account ()
            List<AccountContactRelation> acrs = [
                SELECT Id, Roles
                FROM AccountContactRelation
                WHERE AccountId = :groupAccountId
                AND ContactId = :c.Id
                LIMIT 1
            ];
    
            if (acrs.isEmpty()) {
                AccountContactRelation newAcr = new AccountContactRelation(
                    AccountId = groupAccountId,
                    ContactId = c.Id,
                    Roles = rolesJoined,
                    IsActive = true
                );
                insert newAcr;
            } else {
                AccountContactRelation acr = acrs[0];
                acr.Roles = rolesJoined;
                update acr;
            }
        }
    }

    private static void handleUpdates(List<ContactActionDTO> updates, Id accountId) {
        if (updates == null || updates.isEmpty()) return;
    
        List<Contact> toUpdate = new List<Contact>();
        List<Account> accToUpdate = new List<Account>();
    
        // ===== 1) Bulk create Business Accounts for rows that selected "Create New Account" =====
        Id businessAccountRtId = getBusinessAccountRtIdSafe();
    
        List<Account> newBAsToInsert = new List<Account>();
        List<Integer> rowIndexesNeedingNewBA = new List<Integer>();
    
        for (Integer i = 0; i < updates.size(); i++) {
            ContactActionDTO row = updates[i];
            if (row == null || row.contactId == null) continue;
    
            if (wantsNewBusinessAccount(row)) {
                Account newBA = new Account(
                    Name = row.tpaUi.companyName,
                    RecordTypeId = businessAccountRtId,
                    BillingStreet = row.tpaUi.mailingAddress,
                    BillingCity = row.tpaUi.city,
                    BillingState = row.tpaUi.state,
                    BillingPostalCode = row.tpaUi.zip
                );
                newBAsToInsert.add(newBA);
                rowIndexesNeedingNewBA.add(i);
            }
        }
    
        if (!newBAsToInsert.isEmpty()) {
            insert newBAsToInsert;
    
            for (Integer j = 0; j < rowIndexesNeedingNewBA.size(); j++) {
                Integer idx = rowIndexesNeedingNewBA[j];
                ContactActionDTO row = updates[idx];
    
                // Fill the Business Account Id back into the DTO so the rest of the flow can just use it
                row.tpaUi.accountId = newBAsToInsert[j].Id;
            }
        }
    
        // ===== 2) Roles (ACR) + Contact updates + Business Account updates =====
        for (ContactActionDTO row : updates) {
            if (row == null || row.contactId == null) continue;
    
            Id groupAccountId = (row.accountId != null) ? row.accountId : accountId;
    
            // 2.1 ACR roles always reconcile against the Group Account
            if (row.roles != null && groupAccountId != null) {
                reconcileRoles(groupAccountId, row.contactId, row.roles);
    
                Set<String> desired = extractRoles(row.roles);
                if (desired.contains('Company Officer Contact')) {
                    enforceSingleCompanyOfficer(groupAccountId, row.contactId);
                }
            }
    
            // 2.2 Contact update (including move Contact.AccountId to Business Account)
            Boolean hasContactChanges = false;
            Boolean hasAccountMove = false;
    
            if (row.Contact != null || row.tpaUi != null) {
                Contact c = new Contact(Id = row.contactId);

                if (row.Contact != null) {
                    if (row.Contact.FirstName != null) { c.FirstName = row.Contact.FirstName; hasContactChanges = true; }
                    if (row.Contact.LastName  != null) { c.LastName  = row.Contact.LastName;  hasContactChanges = true; }
                    if (row.Contact.Email     != null) { c.Email     = row.Contact.Email;     hasContactChanges = true; }
                    if (row.Contact.Phone     != null) { c.Phone     = row.Contact.Phone;     hasContactChanges = true; }
                    if (row.Contact.Title     != null) { c.Title     = row.Contact.Title;     hasContactChanges = true; }
                    if (row.Contact.PortalAccess != null) { c.ARC_PortalAccess__c = row.Contact.PortalAccess; hasContactChanges = true; }
                    if (row.Contact.ContactOwnershipPercentage != null) {
                        c.ARC_OwnershipPercentage__c = row.Contact.ContactOwnershipPercentage;
                        hasContactChanges = true;
                    }
                    Set<String> desiredRoleSet = extractRoles(row.roles);
                    if (!desiredRoleSet.contains('Ownership')) {
                        c.ARC_OwnershipPercentage__c = null;
                        hasContactChanges = true;
                    }
                }

                // Move the Contact to the Business Account (existing or newly created)
                if (row.tpaUi != null && row.tpaUi.accountId != null) {
                    c.AccountId = row.tpaUi.accountId;
                    hasAccountMove = true;
                }

                if (hasContactChanges || hasAccountMove) {
                    toUpdate.add(c);
                }
            }
    
            if (row.tpaUi != null && row.tpaUi.useExistingAccount == true && row.tpaUi.accountId != null) {
                Account a = new Account(Id = row.tpaUi.accountId);
    
                Boolean hasAccChanges = false;
                if (row.tpaUi.companyName != null) { a.Name = row.tpaUi.companyName; hasAccChanges = true; }
                if (row.tpaUi.mailingAddress != null) { a.BillingStreet = row.tpaUi.mailingAddress; hasAccChanges = true; }
                if (row.tpaUi.city != null) { a.BillingCity = row.tpaUi.city; hasAccChanges = true; }
                if (row.tpaUi.state != null) { a.BillingState = row.tpaUi.state; hasAccChanges = true; }
                if (row.tpaUi.zip != null) { a.BillingPostalCode = row.tpaUi.zip; hasAccChanges = true; }
    
                if (hasAccChanges) accToUpdate.add(a);
            }
        }
    
        if (!toUpdate.isEmpty()) update toUpdate;
        if (!accToUpdate.isEmpty()) update accToUpdate;
    }

    private static void handleDeletes(List<DeleteDTO> deletes) {

        Set<Id> acrIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();

        for (DeleteDTO d : deletes) {
            if (d == null) continue;
            if (d.acrId != null) acrIds.add(d.acrId);
            if (d.contactId != null) contactIds.add(d.contactId);
        }
        if (acrIds.isEmpty() && contactIds.isEmpty()) return;

        //fix to bug-3435

        List<AccountContactRelation> acrs = acrIds.isEmpty()
        ? new List<AccountContactRelation>()
        : [SELECT Id, IsDirect, ContactId FROM AccountContactRelation WHERE Id IN :acrIds];

         List<AccountContactRelation> acrsToDelete = new List<AccountContactRelation>(); 
         List<Contact> contactsToUpdate = new List<Contact>();

         for (AccountContactRelation acr : acrs) {
            if (acr.IsDirect) {
                Contact c = new Contact(Id = acr.ContactId, AccountId = null);
                contactsToUpdate.add(c);
                contactIds.add(acr.ContactId); 
            } else {
                acrsToDelete.add(acr);
            }
        }

        Savepoint sp = Database.setSavepoint();
        try {
        if (!acrsToDelete.isEmpty()) {
            delete acrsToDelete;
            System.debug('Relaciones indirectas eliminadas: ' + acrsToDelete.size());
        }

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
            System.debug('Contactos actualizados (desvinculados de la cuenta): ' + contactsToUpdate.size());
        }

        if (!contactIds.isEmpty()) {
            Map<Id, Integer> activeAcrCountByContact = new Map<Id, Integer>();
            for (AggregateResult ar : [
                SELECT ContactId c, COUNT(Id) cnt
                FROM AccountContactRelation
                WHERE ContactId IN :contactIds
                GROUP BY ContactId
            ]) {
                activeAcrCountByContact.put((Id)ar.get('c'), (Integer)ar.get('cnt'));
            }
    
            List<Contact> contactsToDelete = new List<Contact>();
            for (Id cid : contactIds) {
                Integer cnt = activeAcrCountByContact.get(cid);
                if (cnt == null || cnt == 0) {
                    contactsToDelete.add(new Contact(Id = cid));
                }
            }
    
            if (!contactsToDelete.isEmpty()) {
                delete contactsToDelete;
                System.debug('Eliminated Contacts: ' + contactsToDelete.size());
            }
        }
        
    } catch (DmlException e) {
        Database.rollback(sp);
        System.debug('Error on handleDeletes: ' + e.getMessage());
        throw new AuraHandledException('Cannot Delete ACR Relation: ' + e.getDmlMessage(0));
    }

    //     if (!acrs.isEmpty()) delete acrs;

    //     if (contactIds.isEmpty()) {
    //         // fallback 
    //         for (AccountContactRelation a : acrs) contactIds.add(a.ContactId);
    //     }
    //     if (contactIds.isEmpty()) return;

    //     Map<Id, Integer> activeAcrCountByContact = new Map<Id, Integer>();
    //     for (AggregateResult ar : [
    //         SELECT ContactId c, COUNT(Id) cnt
    //         FROM AccountContactRelation
    //         WHERE ContactId IN :contactIds
    //        // AND IsActive = true
    //         GROUP BY ContactId
    //     ]) {
    //         activeAcrCountByContact.put((Id)ar.get('c'), (Integer)ar.get('cnt'));
    //     }

    //     List<Contact> toDeleteContact = new List<Contact>();
    //     for (Id cid : contactIds) {
    //         Integer cnt = activeAcrCountByContact.get(cid);
    //         if (cnt == null || cnt == 0) {
    //             toDeleteContact.add(new Contact(Id = cid));
    //         }
    //     }

    //     if (!toDeleteContact.isEmpty()) delete toDeleteContact;
     }

    private static Boolean wantsNewBusinessAccount(ContactActionDTO row) {
        return row != null
            && row.tpaUi != null
            && row.tpaUi.useExistingAccount == false
            && row.tpaUi.accountId == null
            && !String.isBlank(row.tpaUi.companyName);
    }

    private static Id getBusinessAccountRtIdSafe() {
        Schema.RecordTypeInfo rti =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account');
    
        if (rti == null) {
            throw new AuraHandledException('Missing Account RecordType DeveloperName = Business_Account');
        }
        return rti.getRecordTypeId();
    }

    private static void reconcileRoles(Id accountId,Id contactId,List<Object> desiredRoles) {
        List<AccountContactRelation> acrs = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND ContactId = :contactId
            LIMIT 1
        ];

        AccountContactRelation acr;

        if (acrs.isEmpty()) {
            acr = new AccountContactRelation(
                AccountId = accountId,
                ContactId = contactId,
                Roles = (desiredRoles == null || desiredRoles.isEmpty())
                    ? 'Other'
                    : String.join(desiredRoles, ';')
            );
            insert acr;
            return;
        }

        // Existe → actualizar
        acr = acrs[0];

        Set<String> roleSet = extractRoles(desiredRoles);

        if (roleSet.isEmpty()) {
            roleSet.add('Other');
        }

        acr.Roles = String.join(new List<String>(roleSet), ';');
        update acr;
    }

    private static Set<String> extractRoles(List<Object> rawRoles) {
        Set<String> roleSet = new Set<String>();
    
        if (rawRoles == null) return roleSet;
    
        for (Object r : rawRoles) {
            if (r != null) {
                String value = String.valueOf(r).trim();
                if (!String.isBlank(value)) {
                    roleSet.add(value);
                }
            }
        }
    
        return roleSet;
    }

    private static void enforceSingleRole(Id accountId, Id newContactId) {
        List<AccountContactRelation> toUpdate = new List<AccountContactRelation>();

        List<AccountContactRelation> existing = [
            SELECT Id, Roles, ContactId
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND Roles INCLUDES ('Company Officer Contact')
        ];
    
        for (AccountContactRelation acr : existing) {
    
            /// NO tocar el que será el nuevo Company Officer
            if (acr.ContactId == newContactId) {
                continue;
            }

            // Convertir multipicklist a Set
            Set<String> roleSet = new Set<String>();

            if (!String.isBlank(acr.Roles)) {
                roleSet.addAll(acr.Roles.split(';'));
            }

            // Quitar Company Officer
            roleSet.remove('Company Officer Contact');

            // Si se quedó sin roles → poner Other
            if (roleSet.isEmpty()) {
                roleSet.add('Other');
            }

            // Volver a string
            acr.Roles = String.join(new List<String>(roleSet), ';');
            toUpdate.add(acr);
        }
    
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private static void enforceSingleCompanyOfficer(Id accountId, Id winnerContactId) {
        // Trae todos los ACR que actualmente tienen CO (excepto el nuevo,  el pbc si este quedo como el new coc)
        List<AccountContactRelation> acrs = [
            SELECT Id, ContactId, Roles
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND Roles INCLUDES (:ROLE_COC)
        ];

        List<AccountContactRelation> toUpdate = new List<AccountContactRelation>();

        for (AccountContactRelation acr : acrs) {
            if (acr.ContactId == winnerContactId) continue;

            // Parse robusto: soporta ';' o ',' y limpia espacios
            List<String> parts = String.isBlank(acr.Roles)
            ? new List<String>()
            : acr.Roles.split('[;,]');

            List<String> kept = new List<String>();
            for (String p : parts) {
                String role = p == null ? null : p.trim();
                if (String.isBlank(role)) continue;
                if (role == ROLE_COC) continue; // quitar CO
                kept.add(role);
            }

            // Si después de quitar CO quedó vacío → Other
            if (kept.isEmpty()) kept.add(ROLE_OTHER);

            // Para evitar diffs por orden random, ordena
            kept.sort();
            String newRoles = String.join(kept, ';');

            if (newRoles != (acr.Roles == null ? '' : acr.Roles)) {
                acr.Roles = newRoles;
                toUpdate.add(acr);
            }
        }

        if (!toUpdate.isEmpty()) update toUpdate;
    }

    private static Id getSmallGroupRtId() {
        Map<String, Schema.RecordTypeInfo> rtByDevName =
            Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName();
        if (!rtByDevName.containsKey(RT_DEVNAME_SG)) {
            throw new AuraHandledException('Missing Contact RecordType: ' + RT_DEVNAME_SG);
        }
        return rtByDevName.get(RT_DEVNAME_SG).getRecordTypeId();
    }
    
    private static void ensureSmallGroupRecordType(Id contactId) {
        if (contactId == null) return;
    
        Id sgRtId = getSmallGroupRtId();
    
        Contact existing = [
            SELECT Id, RecordTypeId
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
    
        if (existing.RecordTypeId != sgRtId) {
            update new Contact(
                Id = contactId,
                RecordTypeId = sgRtId
            );
        }
    }

    private static Id getBillingContactId(Id accountId) {
        if (accountId == null) return null;
    
        List<AccountContactRelation> billingRelations = [
            SELECT ContactId
            FROM AccountContactRelation
            WHERE AccountId = :accountId
            AND Roles INCLUDES ('Billing Contact')
            LIMIT 1
        ];
    
        return billingRelations.isEmpty() ? null : billingRelations[0].ContactId;
    }
}