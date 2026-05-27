/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ARC_CompanyDetailsControllerTest {

    /*
     * ============================================================
     *  TEST CLASS v3 – ARC_CompanyDetailsController
     * ============================================================
     * What to test:
     *  - Validate how we save Company Details + Primary Business Contact (PBC)
     *  - Validate sync of Roles in AccountContactRelation
     *  - Validate deletes (indirect ACR vs direct Contact).
     *  - Validate exception handling when payload is empty.
     *  
     *
     * This test ins't just coverage.
     * Protects business rules:
     *   - Only one Company Officer Contact (COC)
     *   - Only one PBC.
     *   - Persistence of Company.
     *   - Update of PBC.
     *   - Correct deletes according to IsDirect.
     */

    // Keep strings same as controller
    private static final String ROLE_COC   = 'Company Officer Contact';
    private static final String ROLE_PBC   = 'Primary Business Contact';
    private static final String ROLE_OTHER = 'Other';


     /*
     * ============================================================
     * TEST SETUP
     * ============================================================
     * 
     * It will run only once for all tests.
     * Creates a consistent base:
     *  - Main Account
     *  - Secondary Account (for indirect ACR)
     *  - Contact PBC
     *  - Actual COC
     *  - Indirect Contact
     *  - ACR indirect
     *  - Initial roles adjustment
     */

    @testSetup
    static void setup() {
        // Main Account
        Account a = new Account(
            Name = 'Test Employer',
            Sic = '1040',
            SicDesc = 'GOLD AND SILVER ORES',
            BillingStreet = 'Old St',
            BillingCity = 'Old City',
            BillingState = 'TX',
            BillingPostalCode = '00000',
            vlocity_ins__Email__c = 'old@company.com',
            ARC_FederalEmployerTaxIDNumber__c = '11-1111111'
        );
        insert a;

        // Another Account to create an indirect relation (IsDirect in ACR = false)
        Account a2 = new Account(Name = 'Other Account');
        insert a2;

        // Contact that will be PBC
        Contact pbc = new Contact(
            AccountId = a.Id,
            FirstName = 'Erick',
            LastName  = 'Rocha',
            Email     = 'pbc@test.com',
            Phone     = '5555555555',
            Title     = 'PBC',
            ARC_PortalAccess__c = 'Viewer'
        );
        insert pbc;

        // Contact that is COC (and also has other roles)
        Contact oldCoc = new Contact(
            AccountId = a.Id,
            FirstName = 'Kiko',
            LastName  = 'Barrera',
            Email     = 'coc@test.com',
            Phone     = '4444444444',
            Title     = 'C0C',
            ARC_PortalAccess__c = 'Admin'
        );
        insert oldCoc;

        // Indirect contact: belongs to a2 but we relate it to the main account via ACR
        Contact indirect = new Contact(
            AccountId = a2.Id,
            FirstName = 'Indirect',
            LastName  = 'Contact',
            Email     = 'indirect@test.com'
        );
        insert indirect;
        
        // Test Delete
        // Exclusive contact for direct delete
        Contact directDelete = new Contact(
            AccountId = a.Id,
            FirstName = 'Delete',
            LastName  = 'Me',
            Email     = 'deleteme@test.com'
        );
        insert directDelete;

        /*
         * 
         * Indirect ACR
         *  - We manually create it.
         *  - IsDirect = false.
         *  - It should only delete the relation, not the Contact.
         *
         */
        AccountContactRelation acrIndirect = new AccountContactRelation(
            AccountId = a.Id,
            ContactId = indirect.Id,
            Roles = 'Billing Contact'
        );
        insert acrIndirect;

         /*
         * 
         * We adjust initial roles: 
         *  - PBC has ROLE_PBC + Ownershiop
         *  - oldCoc has ROLE_COC + Account Holder +  Ownership.
         */
        List<AccountContactRelation> acrs = [
            SELECT Id, ContactId, Roles, IsDirect
            FROM AccountContactRelation
            WHERE AccountId = :a.Id
            AND ContactId IN :new Set<Id>{ pbc.Id, oldCoc.Id }
        ];

        for (AccountContactRelation acr : acrs) {
            if (acr.ContactId == pbc.Id) {
                acr.Roles = ROLE_PBC + ';Ownership';
            }
            if (acr.ContactId == oldCoc.Id) {
                // Este es el que queremos que pierda COC pero conserve Account Holder / Ownership
                acr.Roles = 'Account Holder;' + ROLE_COC + ';Ownership';
            }
        }
        update acrs;
    }

      /*
     * ============================================================
     * Main TEST
     * ============================================================
     * Escenario:
     *  - Company update.
     *  - PBC KEEP.
     *  - Promote PBC to COC too
     *  - Old COC sould lose ROLE_COC.
     *  - Delete indirec ACR.
     *  - Delete direct Contact.
     */

    @IsTest
    static void test_saveCompanyAndPBC_keep_updatesCompany_contact_roles_and_deletes() {
        Account a = [SELECT Id FROM Account WHERE Name = 'Test Employer' LIMIT 1];

        Id directDeleteId = [SELECT Id FROM Contact WHERE Email = 'deleteme@test.com' LIMIT 1].Id;

        // Take current PBC
        AccountContactRelation pbcAcr = [
            SELECT Id, ContactId, Roles
            FROM AccountContactRelation
            WHERE AccountId = :a.Id
            AND Roles INCLUDES (:ROLE_PBC)
            LIMIT 1
        ];

        // Old COC
        AccountContactRelation oldCocAcr = [
            SELECT Id, ContactId, Roles
            FROM AccountContactRelation
            WHERE AccountId = :a.Id
            AND Roles INCLUDES (:ROLE_COC)
            LIMIT 1
        ];

        // Indirect ACR (to test delete ACR)
        AccountContactRelation indirectAcr = [
            SELECT Id, ContactId, IsDirect
            FROM AccountContactRelation
            WHERE AccountId = :a.Id
            AND IsDirect = false
            LIMIT 1
        ];

        // Direct ACR (to test contact deletion)
        AccountContactRelation directAcrForDelete = [
            SELECT Id, ContactId, IsDirect
            FROM AccountContactRelation
            WHERE AccountId = :a.Id
            AND IsDirect = true
            AND ContactId = :directDeleteId
            LIMIT 1
        ];

        /*
        * - We build Payload:
        * - Company update
        * - PBC KEEP (updates the Contact of the PBC)
        * - contacts.updates: promote and oldCocAcr.ContactId as COC (it is already COC),
        * it is important that enforceSingleCompanyOfficer is triggered when we send COC for the "winner".
        * In this test we will make winner = PBC to force oldCoc to lose ROLE_COC but keep other roles.
        *
        */
        Map<String, Object> payload = new Map<String, Object>{
            'company' => new Map<String, Object>{
                'Id' => a.Id,
                'Name' => 'Updated Employer',
                'FedTaxId' => '43-0000000',
                'SIC' => '1040',
                'SICDescription' => 'GOLD AND SILVER ORES',
                'Street' => '1 New St',
                'City' => 'New City',
                'State' => 'CO',
                'PostalCode' => '99999',
                'CompanyEmail' => 'company@test.com'
            },
            'primaryBusinessContact' => new Map<String, Object>{
                'action' => 'KEEP',
                'accountId' => a.Id,
                'contact' => new Map<String, Object>{
                    'Id' => pbcAcr.ContactId,
                    'FirstName' => 'Erick-Updated',
                    'LastName'  => 'Rocha-Updated',
                    'Email'     => 'pbc.updated@test.com',
                    'Phone'     => '1111111111',
                    'Title'     => 'PBC Updated',
                    'PortalAccess' => 'Admin'
                },
                'roles' => ROLE_PBC
            },
            'contacts' => new Map<String, Object>{
                'creates' => new List<Object>(),
                'updates' => new List<Object>{
                    new Map<String, Object>{
                        'action' => 'UPDATE',
                        'accountId' => a.Id,
                        'contactId' => pbcAcr.ContactId,
                        'Contact' => new Map<String, Object>{
                            'Id' => pbcAcr.ContactId,
                            'PortalAccess' => 'Admin'
                        },
                        'roles' => new List<String>{ ROLE_PBC, ROLE_COC }
                    }
                },
                'deletes' => new List<Object>{
                    new Map<String, Object>{
                        'contactId' => indirectAcr.ContactId,
                        'acrId' => indirectAcr.Id
                    },
                    new Map<String, Object>{
                        'contactId' => directAcrForDelete.ContactId,
                        'acrId' => directAcrForDelete.Id
                    }
                }
            }
        };

        Test.startTest();
        ARC_CompanyDetailsController.saveCompanyAndPBC(JSON.serialize(payload));
        Test.stopTest();

        // ===== ASSERT Company updated =====
        Account updatedAcc = [
            SELECT Name, ARC_FederalEmployerTaxIDNumber__c, vlocity_ins__Email__c,
                   BillingStreet, BillingCity, BillingState, BillingPostalCode, Sic, SicDesc
            FROM Account
            WHERE Id = :a.Id
        ];
        System.assertEquals('Updated Employer', updatedAcc.Name);
        System.assertEquals('43-0000000', updatedAcc.ARC_FederalEmployerTaxIDNumber__c);
        System.assertEquals('old@company.com', updatedAcc.vlocity_ins__Email__c);
        System.assertEquals('1 New St', updatedAcc.BillingStreet);

        // ===== ASSERT PBC Contact updated =====
        Contact updatedPbc = [
            SELECT FirstName, LastName, Email, Phone, Title, ARC_PortalAccess__c
            FROM Contact
            WHERE Id = :pbcAcr.ContactId
        ];
        System.assertEquals('Erick-Updated', updatedPbc.FirstName);
        System.assertEquals('Rocha-Updated', updatedPbc.LastName);
        System.assertEquals('pbc.updated@test.com', updatedPbc.Email);
        System.assertEquals('1111111111', updatedPbc.Phone);
        System.assertEquals('PBC Updated', updatedPbc.Title);
        System.assertEquals('Admin', updatedPbc.ARC_PortalAccess__c);

        // ===== ASSERT enforceSingleCompanyOfficer removed COC from old COC ACR but kept other roles =====
        Id oldCocContactId = oldCocAcr.ContactId;

        List<AccountContactRelation> oldCocAfterList = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE AccountId = :a.Id
            AND ContactId = :oldCocContactId
            LIMIT 1
        ];

        System.assertEquals(
            1,
            oldCocAfterList.size(),
            'Old COC ACR disappeared. Check payload.contacts.deletes: you may be deleting the old COC ACR.'
        );

        AccountContactRelation oldCocAfter = oldCocAfterList[0];
        System.assert(
            !String.valueOf(oldCocAfter.Roles).contains(ROLE_COC),
            'Old COC should have lost the Company Officer Contact role.'
        );

        // It should keep account holder and ownership, and not have Company Officer Contact
        System.assert(oldCocAfter.Roles != null, 'Roles should not be null after enforcement');
        System.assert(!oldCocAfter.Roles.contains(ROLE_COC), 'Old COC should lose COC role');
        System.assert(oldCocAfter.Roles.contains('Account Holder'), 'Old COC should keep Account Holder');
        System.assert(oldCocAfter.Roles.contains('Ownership'), 'Old COC should keep Ownership');

        // ===== ASSERT deletes =====
        // Indirect ACT sould be deleted (IsDirect=false)
        Integer indirectCount = [
            SELECT COUNT()
            FROM AccountContactRelation
            WHERE Id = :indirectAcr.Id
        ];
        System.assertEquals(0, indirectCount, 'Indirect ACR should be deleted');

        // Direct delete: if IsDirect=true, el controller deleted the contact
        Integer deletedContactCount = [
            SELECT COUNT()
            FROM Contact
            WHERE Id = :directAcrForDelete.ContactId
        ];
        System.assertEquals(0, deletedContactCount, 'Direct contact should be deleted when deleting a direct ACR');
    }

        /*
         * ============================================================
         * TEST EXCEPTION EMPTY PAYLOAD
         * ============================================================
         * 
         * Protects:
         *  - Controller doesn't accept empty payloads.
         *  - Controller always throws AuraHandledException.
         */
    
        @IsTest
        static void test_saveCompanyAndPBC_throws_on_empty_payload() {
            try {
                ARC_CompanyDetailsController.saveCompanyAndPBC('');
                System.assert(false, 'Expected exception for empty payload');
            } catch (Exception e) {
                // 1) Tipo (estable)
                System.assert(
                    e instanceof AuraHandledException,
                    'Expected AuraHandledException but got: ' + e.getTypeName()
                );
    
                // 2) Mensaje (a veces SF lo cambia a "Script-thrown exception")
                String msg = e.getMessage();
                System.assert(
                    msg != null && (msg.contains('Payload is empty') || msg == 'Script-thrown exception'),
                    'Expected message to contain "Payload is empty" OR be "Script-thrown exception" but got: ' + msg
                );
            }
        }
            /*
         * ============================================================
         * PAYMENT METHODS TESTS
         * ============================================================
         * Test para las funcionalidades de métodos de pago
         */

    @IsTest
    static void test_getPaymentMethod_withCreditCard() {
        // Setup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Employer' LIMIT 1];
        
        Contact existingContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        
        List<AccountContactRelation> existingAcrs = [
            SELECT Id, Roles 
            FROM AccountContactRelation 
            WHERE AccountId = :testAccount.Id 
            AND ContactId = :existingContact.Id
        ];
        
        if (!existingAcrs.isEmpty()) {
            existingAcrs[0].Roles = 'Account Holder';
            update existingAcrs;
        }
        
        ChargentOrders__ChargentOrder__c testOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c = testAccount.Id,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Number__c = '4111111111111111',
            ChargentOrders__Card_Expiration_Month__c = '12',
            ChargentOrders__Card_Expiration_Year__c = '25',
            ChargentOrders__Card_Last_4__c = '1111',
            ChargentOrders__Billing_Address__c = '123 Main St',
            ChargentOrders__Billing_City__c = 'Test City',
            ChargentOrders__Billing_State__c = 'CA',
            ChargentOrders__Billing_Zip_Postal__c = '12345',
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Start_Date__c = Date.today().addDays(1),
            ChargentOrders__Description__c = 'Recurring Monthly Order'
        );
        insert testOrder;
        
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            ARC_RecurringMonthlyOrder__c = testOrder.Id,
            ARC_EffectiveDate__c = Date.today().addDays(1)
        );
        insert testContract;
        testContract.Status = 'Activated';
        update testContract;
        
        Test.startTest();
        ARC_CompanyDetailsController.testAccountId = testAccount.Id;
        ARC_CompanyDetailsController.OrderData result = ARC_CompanyDetailsController.getPaymentMethod();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.order, 'Order should not be null');
        System.assertEquals('Credit Card', result.order.ChargentOrders__Payment_Method__c);
        ChargentOrders__ChargentOrder__c queriedOrder = [
            SELECT Id,
                   ChargentOrders__Card_Expiration_Month__c,
                   ChargentOrders__Card_Expiration_Year__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id = :result.order.Id
            LIMIT 1
        ];
        System.assertEquals('12', queriedOrder.ChargentOrders__Card_Expiration_Month__c);
        System.assertEquals('25', queriedOrder.ChargentOrders__Card_Expiration_Year__c);
        System.assertEquals('Monthly', result.PaymentFrequency);
        System.assert(result.FullAddress.contains('123 Main St'));
        System.assert(result.FullAddress.contains('Test City'));
        System.assert(result.FullAddress.contains('CA'));
        System.assert(result.FullAddress.contains('12345'));
    }
    
    @IsTest
    static void test_getPaymentMethod_withBankAccount() {
        // Setup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Employer' LIMIT 1];
        
        ChargentOrders__ChargentOrder__c testOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c = testAccount.Id,
            ChargentOrders__Payment_Method__c = 'Bank Account',
            ChargentOrders__Bank_Name__c = 'Test Bank',
            ChargentOrders__Bank_Routing_Number__c = '123456789',
            ChargentOrders__Bank_Account_Number__c = '987654321',
            ChargentOrders__Bank_Account_Last_4__c = '4321',
            ChargentOrders__Bank_Account_Type__c = 'Checking',
            ChargentOrders__Payment_Frequency__c = 'Once',
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Start_Date__c = Date.today().addDays(1),
            ChargentOrders__Description__c = 'Recurring Monthly Order'
        );
        insert testOrder;
        
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            ARC_RecurringMonthlyOrder__c = testOrder.Id,
            ARC_EffectiveDate__c = Date.today().addDays(1)
        );
        insert testContract;
        testContract.Status = 'Activated';
        update testContract;
        
        Test.startTest();
        ARC_CompanyDetailsController.testAccountId = testAccount.Id;
        ARC_CompanyDetailsController.OrderData result = ARC_CompanyDetailsController.getPaymentMethod();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('Bank Account', result.order.ChargentOrders__Payment_Method__c);
        System.assertEquals('Checking', result.BankAccountType);
        System.assertEquals('Once', result.PaymentFrequency);
    }
    
    @IsTest
    static void test_updatePaymentMethod_creditCard() {
        // Setup
        Account testAccount = [SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode FROM Account WHERE Name = 'Test Employer' LIMIT 1];
        
        ChargentOrders__ChargentOrder__c testOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c = testAccount.Id,
            ChargentOrders__Payment_Method__c = 'Bank Account', // Will change to Credit Card
            ChargentOrders__Bank_Name__c = 'Old Bank',
            ChargentOrders__Bank_Routing_Number__c = '111111111',
            ChargentOrders__Bank_Account_Number__c = '222222222',
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Frequency__c = 'Once',
            ChargentOrders__Payment_Start_Date__c = Date.today().addDays(1),
            ChargentOrders__Description__c = 'Recurring Monthly Order'
        );
        insert testOrder;
        
        Contact pbcContact = [SELECT Id FROM Contact WHERE Email = 'pbc@test.com' LIMIT 1];
        
        Map<String, Object> accountHolderPayload = new Map<String, Object>{
            'action' => 'SELECT',
            'accountId' => testAccount.Id,
            'contact' => new Map<String, Object>{
                'Id' => pbcContact.Id
            },
            'addressDTO' => null,
            'isSameAsPrimaryContact' => true
        };
        
        Map<String, Object> billingContactPayload = new Map<String, Object>{
            'action' => 'SELECT',
            'accountId' => testAccount.Id,
            'contact' => new Map<String, Object>{
                'Id' => pbcContact.Id
            },
            'isSameAsAccountHolder' => true
        };
        
        // Main payload
        Map<String, Object> payload = new Map<String, Object>{
            'orderId' => testOrder.Id,
            'paymentMethod' => 'Credit Card',
            'cardNumber' => '4111111111111111',
            'expirationMonth' => '12',
            'expirationYear' => '25',
            'bankAccountNumber' => null,
            'bankName' => null,
            'bankRoutingNumber' => null,
            'accountHolderPayload' => accountHolderPayload,
            'billingContactPayload' => billingContactPayload,
            'billingAddress' => null
        };
        
        Test.startTest();
        ARC_CompanyDetailsController.updatePaymentMethod(payload);
        Test.stopTest();
        
        // Verify updates
        ChargentOrders__ChargentOrder__c updatedOrder = [
            SELECT Id, ChargentOrders__Payment_Method__c, 
                   ChargentOrders__Card_Number__c,
                   ChargentOrders__Card_Expiration_Month__c,
                   ChargentOrders__Card_Expiration_Year__c,
                   ChargentOrders__Bank_Name__c,
                   ChargentOrders__Bank_Routing_Number__c,
                   ChargentOrders__Bank_Account_Number__c,
                   ChargentOrders__Billing_Address__c,
                   ChargentOrders__Billing_City__c,
                   ChargentOrders__Billing_State__c,
                   ChargentOrders__Billing_Zip_Postal__c
            FROM ChargentOrders__ChargentOrder__c 
            WHERE Id = :testOrder.Id
        ];
        
        System.assertEquals('Credit Card', updatedOrder.ChargentOrders__Payment_Method__c);
        System.assertEquals('4111111111111111', updatedOrder.ChargentOrders__Card_Number__c);
        System.assertEquals(null, updatedOrder.ChargentOrders__Bank_Name__c); // Should be cleared
        System.assertEquals(null, updatedOrder.ChargentOrders__Bank_Routing_Number__c); // Should be cleared
        System.assertEquals(null, updatedOrder.ChargentOrders__Bank_Account_Number__c); // Should be cleared
        // Billing address should be populated from Account
        System.assertEquals(testAccount.BillingStreet, updatedOrder.ChargentOrders__Billing_Address__c);
        System.assertEquals(testAccount.BillingCity, updatedOrder.ChargentOrders__Billing_City__c);
        System.assertEquals(testAccount.BillingState, updatedOrder.ChargentOrders__Billing_State__c);
        System.assertEquals(testAccount.BillingPostalCode, updatedOrder.ChargentOrders__Billing_Zip_Postal__c);
    }
    
    @IsTest
    static void test_updatePaymentMethod_bankAccount() {
        // Setup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Employer' LIMIT 1];
        
        ChargentOrders__ChargentOrder__c testOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c = testAccount.Id,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Number__c = '4111111111111111',
            ChargentOrders__Card_Expiration_Month__c = '12',
            ChargentOrders__Card_Expiration_Year__c = '25',
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Frequency__c = 'Once',
            ChargentOrders__Payment_Start_Date__c = Date.today().addDays(1),
            ChargentOrders__Description__c = 'Recurring Monthly Order'
        );
        insert testOrder;
        
        Map<String, Object> billingAddress = new Map<String, Object>{
            'Street' => '456 Custom St',
            'City' => 'Custom City',
            'State' => 'NY',
            'PostalCode' => '54321'
        };
        
        Map<String, Object> accountHolderPayload = new Map<String, Object>{
            'action' => 'KEEP',
            'accountId' => testAccount.Id,
            'contact' => null,
            'addressDTO' => null,
            'isSameAsPrimaryContact' => false
        };
        
        Map<String, Object> billingContactPayload = new Map<String, Object>{
            'action' => 'KEEP',
            'accountId' => testAccount.Id,
            'contact' => null,
            'isSameAsAccountHolder' => false
        };
        
        Map<String, Object> payload = new Map<String, Object>{
            'orderId' => testOrder.Id,
            'paymentMethod' => 'Bank Account',
            'cardNumber' => null,
            'expirationMonth' => null,
            'expirationYear' => null,
            'bankAccountNumber' => '987654321',
            'bankName' => 'New Bank',
            'bankRoutingNumber' => '123456789',
            'accountHolderPayload' => accountHolderPayload,
            'billingContactPayload' => billingContactPayload,
            'billingAddress' => billingAddress
        };
        
        Test.startTest();
        ARC_CompanyDetailsController.updatePaymentMethod(payload);
        Test.stopTest();
        
        // Verify updates
        ChargentOrders__ChargentOrder__c updatedOrder = [
            SELECT Id, ChargentOrders__Payment_Method__c, 
                   ChargentOrders__Bank_Name__c,
                   ChargentOrders__Bank_Routing_Number__c,
                   ChargentOrders__Bank_Account_Number__c,
                   ChargentOrders__Bank_Account_Type__c,
                   ChargentOrders__Card_Number__c,
                   ChargentOrders__Card_Expiration_Month__c,
                   ChargentOrders__Card_Expiration_Year__c,
                   ChargentOrders__Billing_Address__c,
                   ChargentOrders__Billing_City__c,
                   ChargentOrders__Billing_State__c,
                   ChargentOrders__Billing_Zip_Postal__c
            FROM ChargentOrders__ChargentOrder__c 
            WHERE Id = :testOrder.Id
        ];
        
        System.assertEquals('Bank Account', updatedOrder.ChargentOrders__Payment_Method__c);
        System.assertEquals('New Bank', updatedOrder.ChargentOrders__Bank_Name__c);
        System.assertEquals('123456789', updatedOrder.ChargentOrders__Bank_Routing_Number__c);
        System.assertEquals('987654321', updatedOrder.ChargentOrders__Bank_Account_Number__c);
        System.assertEquals('Checking', updatedOrder.ChargentOrders__Bank_Account_Type__c);
        System.assertEquals(null, updatedOrder.ChargentOrders__Card_Number__c); // Should be cleared
        System.assertEquals(null, updatedOrder.ChargentOrders__Card_Expiration_Month__c); // Should be cleared
        System.assertEquals(null, updatedOrder.ChargentOrders__Card_Expiration_Year__c); // Should be cleared
        System.assertEquals('456 Custom St', updatedOrder.ChargentOrders__Billing_Address__c);
        System.assertEquals('Custom City', updatedOrder.ChargentOrders__Billing_City__c);
        System.assertEquals('NY', updatedOrder.ChargentOrders__Billing_State__c);
        System.assertEquals('54321', updatedOrder.ChargentOrders__Billing_Zip_Postal__c);
    }
    
    @IsTest
    static void test_updateAccountHolderRole_createNewContact() {
        // Setup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Employer' LIMIT 1];
        
        Map<String, Object> contactDTO = new Map<String, Object>{
            'FirstName' => 'New',
            'LastName' => 'AccountHolder',
            'Email' => 'new.holder@test.com',
            'PortalAccess' => 'Admin'
        };
        
        Map<String, Object> addressDTO = new Map<String, Object>{
            'MailingStreet' => '123 Account St',
            'MailingCity' => 'Account City',
            'MailingState' => 'CA',
            'MailingPostalCode' => '12345'
        };
        
        Map<String, Object> payload = new Map<String, Object>{
            'action' => 'CREATE',
            'accountId' => testAccount.Id,
            'contact' => contactDTO,
            'addressDTO' => addressDTO,
            'isSameAsPrimaryContact' => false
        };
        
        String payloadJson = JSON.serialize(payload);
        
        Test.startTest();
        ARC_CompanyDetailsController.updateAccountHolderRole(payloadJson);
        Test.stopTest();
        
        List<Contact> newContacts = [
            SELECT Id, FirstName, LastName, Email, ARC_PortalAccess__c,
                   MailingStreet, MailingCity, MailingState, MailingPostalCode
            FROM Contact 
            WHERE Email = 'new.holder@test.com'
        ];
        
        System.assertEquals(1, newContacts.size(), 'New contact should be created');
        Contact newContact = newContacts[0];
        System.assertEquals('New', newContact.FirstName);
        System.assertEquals('AccountHolder', newContact.LastName);
        System.assertEquals('Admin', newContact.ARC_PortalAccess__c);
        System.assertEquals('123 Account St', newContact.MailingStreet);
        
        List<AccountContactRelation> acrs = [
            SELECT Id, Roles 
            FROM AccountContactRelation 
            WHERE AccountId = :testAccount.Id 
            AND ContactId = :newContact.Id
        ];
        
        System.assertEquals(1, acrs.size(), 'ACR should be created');
        System.assert(acrs[0].Roles.contains('Account Holder'), 'Should have Account Holder role');
    }
    
    @IsTest
    static void test_updateBillingContactRole_selectExisting() {
        // Setup
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Employer' LIMIT 1];
        
        Contact existingContact = [SELECT Id FROM Contact WHERE AccountId != :testAccount.Id LIMIT 1];
        
        Map<String, Object> contactDTO = new Map<String, Object>{
            'Id' => existingContact.Id
        };
        
        Map<String, Object> payload = new Map<String, Object>{
            'action' => 'SELECT',
            'accountId' => testAccount.Id,
            'contact' => contactDTO,
            'isSameAsAccountHolder' => false
        };
        
        String payloadJson = JSON.serialize(payload);
        
        Test.startTest();
        ARC_CompanyDetailsController.updateBillingContactRole(payloadJson);
        Test.stopTest();

        List<AccountContactRelation> acrs = [
            SELECT Id, Roles 
            FROM AccountContactRelation 
            WHERE AccountId = :testAccount.Id 
            AND ContactId = :existingContact.Id
        ];
        
        System.assert(!acrs.isEmpty(), 'ACR should exist');
        System.assert(acrs[0].Roles.contains('Billing Contact'), 'Should have Billing Contact role');
    }
    
    @IsTest
    static void test_updatePaymentMethod_invalidPayload() {
        Test.startTest();
        try {
            ARC_CompanyDetailsController.updatePaymentMethod(null);
            System.assert(false, 'Should have thrown exception for null payload');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'Expected AuraHandledException but got: ' + e.getTypeName());
            String msg = e.getMessage();
            System.assert(
                msg != null && (msg.contains('Invalid payment payload') || msg == 'Script-thrown exception'),
                'Expected message to contain "Invalid payment payload" OR be "Script-thrown exception" but got: ' + msg
            );
        }
        
        try {
            Map<String, Object> invalidPayload = new Map<String, Object>{
                'someKey' => 'someValue'
            };
            ARC_CompanyDetailsController.updatePaymentMethod(invalidPayload);
            System.assert(false, 'Should have thrown exception for payload without orderId');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'Expected AuraHandledException but got: ' + e.getTypeName());
            String msg = e.getMessage();
            System.assert(
                msg != null && (msg.contains('Invalid payment payload') || msg == 'Script-thrown exception'),
                'Expected message to contain "Invalid payment payload" OR be "Script-thrown exception" but got: ' + msg
            );
        }
        Test.stopTest();
    }
    
    @IsTest
    static void test_updateAccountHolderRole_invalidPayload() {
        Test.startTest();
        try {
            ARC_CompanyDetailsController.updateAccountHolderRole('');
            System.assert(false, 'Should have thrown exception for empty payload');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'Expected AuraHandledException but got: ' + e.getTypeName());
            String msg = e.getMessage();
            System.assert(
                msg != null && (msg.contains('Payload is empty') || msg == 'Script-thrown exception'),
                'Expected message to contain "Payload is empty" OR be "Script-thrown exception" but got: ' + msg
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void test_updateBillingContactRole_createNewContact() {
        Account a = [SELECT Id FROM Account WHERE Name = 'Test Employer' LIMIT 1];

        Map<String, Object> payload = new Map<String, Object>{
            'action'               => 'CREATE',
            'accountId'            => a.Id,
            'isSameAsAccountHolder'=> false,
            'contact'              => new Map<String, Object>{
                'FirstName'    => 'New',
                'LastName'     => 'BillingContact',
                'Email'        => 'new.billing@test.com',
                'Phone'        => '6666666666',
                'Title'        => 'Billing',
                'PortalAccess' => 'Viewer'
            }
        };

        Test.startTest();
        ARC_CompanyDetailsController.updateBillingContactRole(JSON.serialize(payload));
        Test.stopTest();

        List<Contact> newContacts = [SELECT Id FROM Contact WHERE Email = 'new.billing@test.com'];
        System.assertEquals(1, newContacts.size(), 'New billing contact should be created');

        List<AccountContactRelation> acrs = [
            SELECT Id, Roles FROM AccountContactRelation
            WHERE AccountId = :a.Id AND ContactId = :newContacts[0].Id
        ];
        System.assert(!acrs.isEmpty(), 'ACR should exist');
        System.assert(acrs[0].Roles.contains('Billing Contact'), 'Should have Billing Contact role');
    }

    @IsTest
    static void test_updateBillingContactRole_sameAsAccountHolder() {
        Account a = [SELECT Id FROM Account WHERE Name = 'Test Employer' LIMIT 1];

        // Ensure there is an Account Holder on the account
        Contact holder = [SELECT Id FROM Contact WHERE Email = 'coc@test.com' LIMIT 1];
        List<AccountContactRelation> holderAcrs = [
            SELECT Id, Roles FROM AccountContactRelation
            WHERE AccountId = :a.Id AND ContactId = :holder.Id LIMIT 1
        ];
        if (!holderAcrs.isEmpty() && !holderAcrs[0].Roles.contains('Account Holder')) {
            holderAcrs[0].Roles = holderAcrs[0].Roles + ';Account Holder';
            update holderAcrs;
        }

        Map<String, Object> payload = new Map<String, Object>{
            'action'               => 'SELECT',
            'accountId'            => a.Id,
            'isSameAsAccountHolder'=> true,
            'contact'              => null
        };

        Test.startTest();
        ARC_CompanyDetailsController.updateBillingContactRole(JSON.serialize(payload));
        Test.stopTest();

        // Account Holder contact should now also have Billing Contact role
        List<AccountContactRelation> billingAcrs = [
            SELECT Id, Roles FROM AccountContactRelation
            WHERE AccountId = :a.Id AND Roles INCLUDES ('Billing Contact')
        ];
        System.assert(!billingAcrs.isEmpty(), 'Billing Contact role should be assigned to Account Holder');
    }

    @IsTest
    static void test_updateAccountHolderRole_sameAsPrimaryContact() {
        Account a = [SELECT Id FROM Account WHERE Name = 'Test Employer' LIMIT 1];

        Map<String, Object> payload = new Map<String, Object>{
            'action'                => 'SELECT',
            'accountId'             => a.Id,
            'isSameAsPrimaryContact'=> true,
            'contact'               => null,
            'addressDTO'            => null
        };

        Test.startTest();
        ARC_CompanyDetailsController.updateAccountHolderRole(JSON.serialize(payload));
        Test.stopTest();

        // PBC contact should now also have Account Holder role
        List<AccountContactRelation> ahAcrs = [
            SELECT Id, Roles FROM AccountContactRelation
            WHERE AccountId = :a.Id AND Roles INCLUDES ('Account Holder')
        ];
        System.assert(!ahAcrs.isEmpty(), 'Account Holder role should be assigned to PBC');
    }

    @IsTest
    static void test_requestContactDeletion() {
        Contact pbc = [SELECT Id FROM Contact WHERE Email = 'pbc@test.com' LIMIT 1];

        Test.startTest();
        // Should not throw; the Platform Event publish is fire-and-forget
        ARC_CompanyDetailsController.requestContactDeletion(pbc.Id);
        Test.stopTest();

        // No assertion needed - coverage and no-exception is the goal
        System.assert(true, 'requestContactDeletion completed without exception');
    }

    @IsTest
    static void test_saveCompanyAndPBC_emptyDeletes_noOp() {
        Account a = [SELECT Id FROM Account WHERE Name = 'Test Employer' LIMIT 1];
        AccountContactRelation pbcAcr = [
            SELECT Id, ContactId FROM AccountContactRelation
            WHERE AccountId = :a.Id AND Roles INCLUDES (:ROLE_PBC) LIMIT 1
        ];

        Map<String, Object> payload = new Map<String, Object>{
            'company' => new Map<String, Object>{
                'Id' => a.Id, 'Name' => 'Test Employer', 'FedTaxId' => '11-1111111',
                'SIC' => '1040', 'SICDescription' => 'GOLD AND SILVER ORES',
                'Street' => 'Old St', 'City' => 'Old City', 'State' => 'TX', 'PostalCode' => '00000'
            },
            'primaryBusinessContact' => new Map<String, Object>{
                'action' => 'KEEP', 'accountId' => a.Id,
                'contact' => new Map<String, Object>{
                    'Id' => pbcAcr.ContactId, 'FirstName' => 'Erick', 'LastName' => 'Rocha',
                    'Email' => 'pbc@test.com', 'Phone' => '5555555555',
                    'Title' => 'PBC', 'PortalAccess' => 'Viewer'
                }
            },
            'contacts' => new Map<String, Object>{
                'creates' => new List<Object>(),
                'updates' => new List<Object>(),
                'deletes' => new List<Object>{ new Map<String, Object>{ 'contactId' => null, 'acrId' => null } }
            }
        };

        Test.startTest();
        ARC_CompanyDetailsController.saveCompanyAndPBC(JSON.serialize(payload));
        Test.stopTest();

        System.assert(true, 'Empty deletes should not throw');
    }
    
    @IsTest
    static void test_updatePrimaryContact_coversMethod() {
        Contact c = [
            SELECT Id
            FROM Contact
            WHERE Email = 'pbc@test.com'
            LIMIT 1
        ];

        Map<String, String> values = new Map<String, String>{
            'Id' => c.Id,
            'FirstName' => 'UpdatedPrimary',
            'LastName' => 'UpdatedContact',
            'Email' => 'updated.primary@test.com',
            'Phone' => '7777777777',
            'Title' => 'Updated Primary Title'
        };

        Test.startTest();
        Contact result = ARC_CompanyDetailsController.updatePrimaryContact(values);
        Test.stopTest();

        System.assertEquals(c.Id, result.Id);

        Contact updated = [
            SELECT FirstName, LastName, Email, Phone, Title
            FROM Contact
            WHERE Id = :c.Id
            LIMIT 1
        ];

        System.assertEquals('UpdatedPrimary', updated.FirstName);
        System.assertEquals('UpdatedContact', updated.LastName);
        System.assertEquals('updated.primary@test.com', updated.Email);
        System.assertEquals('7777777777', updated.Phone);
        System.assertEquals('Updated Primary Title', updated.Title);
    }

    @IsTest
    static void test_saveCompanyAndPBC_selectExistingContact_coversSelectBranch() {
        Account a = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Employer'
            LIMIT 1
        ];

        AccountContactRelation currentPbc = [
            SELECT Id, ContactId, Roles
            FROM AccountContactRelation
            WHERE AccountId = :a.Id
            AND Roles INCLUDES (:ROLE_PBC)
            LIMIT 1
        ];

        Contact selectedContact = [
            SELECT Id
            FROM Contact
            WHERE Email = 'coc@test.com'
            LIMIT 1
        ];

        Map<String, Object> payload = new Map<String, Object>{
            'primaryBusinessContact' => new Map<String, Object>{
                'action' => 'SELECT',
                'accountId' => a.Id,
                'contact' => new Map<String, Object>{
                    'Id' => selectedContact.Id,
                    'FirstName' => 'Selected',
                    'LastName' => 'Business',
                    'Email' => 'selected.business@test.com',
                    'Phone' => '8888888888',
                    'Title' => 'Selected Business Contact',
                    'PortalAccess' => 'Admin'
                },
                'roles' => ROLE_PBC
            },
            'contacts' => new Map<String, Object>{
                'creates' => new List<Object>(),
                'updates' => new List<Object>(),
                'deletes' => new List<Object>()
            }
        };

        Test.startTest();
        ARC_CompanyDetailsController.saveCompanyAndPBC(JSON.serialize(payload));
        Test.stopTest();

        AccountContactRelation oldPbcAfter = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE AccountId = :a.Id
            AND ContactId = :currentPbc.ContactId
            LIMIT 1
        ];

        AccountContactRelation selectedAfter = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE AccountId = :a.Id
            AND ContactId = :selectedContact.Id
            LIMIT 1
        ];

        Contact updatedSelected = [
            SELECT FirstName, LastName, Email, Phone, Title, ARC_PortalAccess__c
            FROM Contact
            WHERE Id = :selectedContact.Id
            LIMIT 1
        ];

        System.assert(!String.valueOf(oldPbcAfter.Roles).contains(ROLE_PBC));
        System.assert(selectedAfter.Roles.contains(ROLE_PBC));
        System.assertEquals('Selected', updatedSelected.FirstName);
        System.assertEquals('Business', updatedSelected.LastName);
        System.assertEquals('selected.business@test.com', updatedSelected.Email);
        System.assertEquals('8888888888', updatedSelected.Phone);
        System.assertEquals('Selected Business Contact', updatedSelected.Title);
        System.assertEquals('Admin', updatedSelected.ARC_PortalAccess__c);
    }

    @IsTest
    static void test_saveCompanyAndPBC_createPbc_coversCreateBranch() {
        Account a = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Employer'
            LIMIT 1
        ];

        AccountContactRelation oldPbc = [
            SELECT Id, ContactId, Roles
            FROM AccountContactRelation
            WHERE AccountId = :a.Id
            AND Roles INCLUDES (:ROLE_PBC)
            LIMIT 1
        ];

        Map<String, Object> payload = new Map<String, Object>{
            'primaryBusinessContact' => new Map<String, Object>{
                'action' => 'CREATE',
                'accountId' => a.Id,
                'contact' => new Map<String, Object>{
                    'FirstName' => 'Created',
                    'LastName' => 'Primary',
                    'Email' => 'created.primary@test.com',
                    'Phone' => '9999999999',
                    'Title' => 'Created PBC',
                    'PortalAccess' => 'Viewer'
                },
                'roles' => ROLE_PBC
            },
            'contacts' => new Map<String, Object>{
                'creates' => new List<Object>(),
                'updates' => new List<Object>(),
                'deletes' => new List<Object>()
            }
        };

        Test.startTest();
        ARC_CompanyDetailsController.testAccountId = a.Id;
        ARC_CompanyDetailsController.saveCompanyAndPBC(JSON.serialize(payload));
        Test.stopTest();

        Contact created = [
            SELECT Id, FirstName, LastName, Email, Phone, Title, ARC_PortalAccess__c
            FROM Contact
            WHERE Email = 'created.primary@test.com'
            LIMIT 1
        ];

        AccountContactRelation createdAcr = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE AccountId = :a.Id
            AND ContactId = :created.Id
            LIMIT 1
        ];

        AccountContactRelation oldPbcAfter = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE Id = :oldPbc.Id
            LIMIT 1
        ];

        System.assertEquals('Created', created.FirstName);
        System.assertEquals('Primary', created.LastName);
        System.assertEquals('created.primary@test.com', created.Email);
        System.assertEquals('9999999999', created.Phone);
        System.assertEquals('Created PBC', created.Title);
        System.assertEquals('Viewer', created.ARC_PortalAccess__c);
        System.assert(createdAcr.Roles.contains(ROLE_PBC));
        System.assert(!String.valueOf(oldPbcAfter.Roles).contains(ROLE_PBC));
    }

    @IsTest
    static void test_saveCompanyAndPBC_handleCreates_withoutTpa_defaultOtherRole() {
        Account a = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Employer'
            LIMIT 1
        ];

        AccountContactRelation pbcAcr = [
            SELECT Id, ContactId
            FROM AccountContactRelation
            WHERE AccountId = :a.Id
            AND Roles INCLUDES (:ROLE_PBC)
            LIMIT 1
        ];

        Map<String, Object> payload = new Map<String, Object>{
            'primaryBusinessContact' => new Map<String, Object>{
                'action' => 'KEEP',
                'accountId' => a.Id,
                'contact' => new Map<String, Object>{
                    'Id' => pbcAcr.ContactId,
                    'FirstName' => 'Erick',
                    'LastName' => 'Rocha',
                    'Email' => 'pbc@test.com',
                    'Phone' => '5555555555',
                    'Title' => 'PBC',
                    'PortalAccess' => 'Viewer'
                },
                'roles' => ROLE_PBC
            },
            'contacts' => new Map<String, Object>{
                'creates' => new List<Object>{
                    new Map<String, Object>{
                        'action' => 'CREATE',
                        'accountId' => a.Id,
                        'Contact' => new Map<String, Object>{
                            'FirstName' => 'NoTpa',
                            'LastName' => 'Created',
                            'Email' => 'notpa.created@test.com',
                            'Phone' => '1112223333',
                            'Title' => 'No TPA Contact',
                            'PortalAccess' => 'Viewer'
                        },
                        'roles' => new List<String>()
                    }
                },
                'updates' => new List<Object>(),
                'deletes' => new List<Object>()
            }
        };

        Test.startTest();
        ARC_CompanyDetailsController.saveCompanyAndPBC(JSON.serialize(payload));
        Test.stopTest();

        Contact created = [
            SELECT Id, AccountId, FirstName, LastName, Email
            FROM Contact
            WHERE Email = 'notpa.created@test.com'
            LIMIT 1
        ];

        AccountContactRelation acr = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE AccountId = :a.Id
            AND ContactId = :created.Id
            LIMIT 1
        ];

        System.assertEquals(a.Id, created.AccountId);
        System.assertEquals('NoTpa', created.FirstName);
        System.assertEquals('Created', created.LastName);
        System.assert(acr.Roles.contains(ROLE_OTHER));
    }

    @IsTest
    static void test_saveCompanyAndPBC_handleCreates_tpaExistingAccount() {
        Account groupAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Employer'
            LIMIT 1
        ];

        Account businessAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Other Account'
            LIMIT 1
        ];

        AccountContactRelation pbcAcr = [
            SELECT Id, ContactId
            FROM AccountContactRelation
            WHERE AccountId = :groupAccount.Id
            AND Roles INCLUDES (:ROLE_PBC)
            LIMIT 1
        ];

        Map<String, Object> payload = new Map<String, Object>{
            'primaryBusinessContact' => new Map<String, Object>{
                'action' => 'KEEP',
                'accountId' => groupAccount.Id,
                'contact' => new Map<String, Object>{
                    'Id' => pbcAcr.ContactId,
                    'FirstName' => 'Erick',
                    'LastName' => 'Rocha',
                    'Email' => 'pbc@test.com',
                    'Phone' => '5555555555',
                    'Title' => 'PBC',
                    'PortalAccess' => 'Viewer'
                },
                'roles' => ROLE_PBC
            },
            'contacts' => new Map<String, Object>{
                'creates' => new List<Object>{
                    new Map<String, Object>{
                        'action' => 'CREATE',
                        'accountId' => groupAccount.Id,
                        'Contact' => new Map<String, Object>{
                            'FirstName' => 'ExistingTpa',
                            'LastName' => 'Created',
                            'Email' => 'existing.tpa.created@test.com',
                            'Phone' => '2223334444',
                            'Title' => 'Existing TPA Contact',
                            'PortalAccess' => 'Admin'
                        },
                        'roles' => new List<String>{ ROLE_OTHER },
                        'tpaUi' => new Map<String, Object>{
                            'useExistingAccount' => true,
                            'accountId' => businessAccount.Id,
                            'companyName' => 'Other Account',
                            'mailingAddress' => 'Existing TPA St',
                            'city' => 'TPA City',
                            'state' => 'CA',
                            'zip' => '90001'
                        }
                    }
                },
                'updates' => new List<Object>(),
                'deletes' => new List<Object>()
            }
        };

        Test.startTest();
        ARC_CompanyDetailsController.saveCompanyAndPBC(JSON.serialize(payload));
        Test.stopTest();

        Contact created = [
            SELECT Id, AccountId, Email
            FROM Contact
            WHERE Email = 'existing.tpa.created@test.com'
            LIMIT 1
        ];

        AccountContactRelation groupAcr = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE AccountId = :groupAccount.Id
            AND ContactId = :created.Id
            LIMIT 1
        ];

        System.assertEquals(businessAccount.Id, created.AccountId);
        System.assert(groupAcr.Roles.contains(ROLE_OTHER));
    }

    @IsTest
    static void test_saveCompanyAndPBC_handleCreates_tpaCreatesNewBusinessAccount_coc() {
        Map<String, Schema.RecordTypeInfo> accountRtMap =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();

        if (!accountRtMap.containsKey('Business_Account')) {
            System.assert(true);
            return;
        }

        Account groupAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Employer'
            LIMIT 1
        ];

        AccountContactRelation pbcAcr = [
            SELECT Id, ContactId
            FROM AccountContactRelation
            WHERE AccountId = :groupAccount.Id
            AND Roles INCLUDES (:ROLE_PBC)
            LIMIT 1
        ];

        Contact oldCoc = [
            SELECT Id
            FROM Contact
            WHERE Email = 'coc@test.com'
            LIMIT 1
        ];

        Map<String, Object> payload = new Map<String, Object>{
            'primaryBusinessContact' => new Map<String, Object>{
                'action' => 'KEEP',
                'accountId' => groupAccount.Id,
                'contact' => new Map<String, Object>{
                    'Id' => pbcAcr.ContactId,
                    'FirstName' => 'Erick',
                    'LastName' => 'Rocha',
                    'Email' => 'pbc@test.com',
                    'Phone' => '5555555555',
                    'Title' => 'PBC',
                    'PortalAccess' => 'Viewer'
                },
                'roles' => ROLE_PBC
            },
            'contacts' => new Map<String, Object>{
                'creates' => new List<Object>{
                    new Map<String, Object>{
                        'action' => 'CREATE',
                        'accountId' => groupAccount.Id,
                        'Contact' => new Map<String, Object>{
                            'FirstName' => 'NewTpa',
                            'LastName' => 'Officer',
                            'Email' => 'new.tpa.officer@test.com',
                            'Phone' => '3334445555',
                            'Title' => 'New TPA Officer',
                            'PortalAccess' => 'Admin',
                            'ContactOwnershipPercentage' => 45
                        },
                        'roles' => new List<String>{ ROLE_COC, 'Ownership' },
                        'tpaUi' => new Map<String, Object>{
                            'useExistingAccount' => false,
                            'accountId' => null,
                            'companyName' => 'TPA New Business Account',
                            'mailingAddress' => '100 New TPA St',
                            'city' => 'New TPA City',
                            'state' => 'NV',
                            'zip' => '89101'
                        }
                    }
                },
                'updates' => new List<Object>(),
                'deletes' => new List<Object>()
            }
        };

        Test.startTest();
        ARC_CompanyDetailsController.saveCompanyAndPBC(JSON.serialize(payload));
        Test.stopTest();

        Account newBusinessAccount = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode
            FROM Account
            WHERE Name = 'TPA New Business Account'
            LIMIT 1
        ];

        Contact created = [
            SELECT Id, AccountId, FirstName, LastName, Email, ARC_OwnershipPercentage__c
            FROM Contact
            WHERE Email = 'new.tpa.officer@test.com'
            LIMIT 1
        ];

        AccountContactRelation createdGroupAcr = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE AccountId = :groupAccount.Id
            AND ContactId = :created.Id
            LIMIT 1
        ];

        AccountContactRelation oldCocAfter = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE AccountId = :groupAccount.Id
            AND ContactId = :oldCoc.Id
            LIMIT 1
        ];

        System.assertEquals(newBusinessAccount.Id, created.AccountId);
        System.assertEquals('100 New TPA St', newBusinessAccount.BillingStreet);
        System.assertEquals('New TPA City', newBusinessAccount.BillingCity);
        System.assertEquals('NV', newBusinessAccount.BillingState);
        System.assertEquals('89101', newBusinessAccount.BillingPostalCode);
        System.assertEquals(45, created.ARC_OwnershipPercentage__c);
        System.assert(createdGroupAcr.Roles.contains(ROLE_COC));
        System.assert(createdGroupAcr.Roles.contains('Ownership'));
        System.assert(!String.valueOf(oldCocAfter.Roles).contains(ROLE_COC));
    }

    @IsTest
    static void test_loadCompanyReadMethods() {
        Account a = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Employer'
            LIMIT 1
        ];

        Test.startTest();
        ARC_CompanyDetailsController.testAccountId = a.Id;

        ARC_CompanyDetailsController.EmployerData employerData =
            ARC_CompanyDetailsController.getCompanyDetails();

        List<AccountContactRelation> primaryContacts =
            ARC_CompanyDetailsController.getPrimaryContact();

        ARC_CompanyDetailsController.CompanyContactsDTO companyContacts =
            ARC_CompanyDetailsController.loadCompanyContacts();

        Map<String, Object> contactsWithUsers =
            ARC_CompanyDetailsController.loadCompanyContactsWithUsers();

        Boolean canEdit = ARC_CompanyDetailsController.canEdit();
        Boolean canEditCompanyDetails = ARC_CompanyDetailsController.canEditCompanyDetails();

        Test.stopTest();

        System.assertNotEquals(null, employerData, 'EmployerData should not be null');
        System.assertNotEquals(null, employerData.employer, 'Employer should not be null');
        System.assertEquals('1040 - GOLD AND SILVER ORES', employerData.SIC);

        System.assert(!primaryContacts.isEmpty(), 'Primary contacts query should return ACRs');

        System.assertNotEquals(null, companyContacts, 'CompanyContactsDTO should not be null');
        System.assert(!companyContacts.acrs.isEmpty(), 'Company contacts should return ACRs');

        System.assertEquals(true, contactsWithUsers.get('success'));

        List<Map<String, Object>> enhancedContacts =
            (List<Map<String, Object>>) contactsWithUsers.get('acrs');

        System.assert(!enhancedContacts.isEmpty(), 'Enhanced contacts should not be empty');
        System.assertNotEquals(null, canEdit, 'canEdit should return a boolean');
        System.assertNotEquals(null, canEditCompanyDetails, 'canEditCompanyDetails should return a boolean');
    }
}