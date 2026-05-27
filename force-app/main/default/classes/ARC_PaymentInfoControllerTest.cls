@isTest
private class ARC_PaymentInfoControllerTest {

    // ─── Test Data Helpers ────────────────────────────────────────────────────

    private static Account createAccount(String name) {
        Account acc = new Account(
            Name             = name,
            BillingStreet    = '123 Main St',
            BillingCity      = 'Austin',
            BillingState     = 'TX',
            BillingPostalCode = '78701'
        );
        insert acc;
        return acc;
    }

    private static Opportunity createOpportunity(String name, Id accountId, Id contractId) {
        Opportunity opp = new Opportunity(
            Name       = name,
            StageName  = 'Prospecting',
            CloseDate  = Date.today().addDays(30),
            AccountId  = accountId,
            ContractId = contractId
        );
        insert opp;
        return opp;
    }

    private static Contract createContract(Id accountId) {
        Contract c = new Contract(
            AccountId    = accountId,
            StartDate    = Date.today(),
            ContractTerm = 12,
            Status       = 'Draft'
        );
        insert c;
        return c;
    }

    /**
     * Creates a ChargentOrder with full billing, bank, and card data.
     * Pass null for contractId to omit ARC_Contract__c.
     */
    private static ChargentOrders__ChargentOrder__c createChargentOrder(
        Id accountId,
        Id contractId,
        String paymentMethod
    ) {
        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c            = accountId,
            ARC_Contract__c                       = contractId,
            ChargentOrders__Billing_Address__c    = '456 Elm St',
            ChargentOrders__Billing_City__c       = 'Dallas',
            ChargentOrders__Billing_State__c      = 'TX',
            ChargentOrders__Billing_Zip_Postal__c = '75201',
            ChargentOrders__Payment_Method__c     = paymentMethod,
            ChargentOrders__Bank_Name__c          = 'Test Bank',
            ChargentOrders__Bank_Account_Last_4__c = '1234',
            ChargentOrders__Bank_Routing_Number__c = '021000021',
            ChargentOrders__Card_Last_4__c         = '4242',
            ChargentOrders__Card_Month_Indicator__c = '12',
            ChargentOrders__Card_Year_Indicator__c  = '2027'
        );
        insert order;
        return order;
    }

    private static Contact createContact(Id accountId, String firstName, String lastName) {
        Contact c = new Contact(
            FirstName       = firstName,
            LastName        = lastName,
            AccountId       = accountId,
            Email           = firstName.toLowerCase() + '.' + lastName.toLowerCase() + '@test.com',
            Phone           = '5125551234',
            Title           = 'Test Title',
            MailingStreet   = '789 Oak Ave',
            MailingCity     = 'Houston',
            MailingState    = 'TX',
            MailingPostalCode = '77001'
        );
        insert c;
        return c;
    }

    // ─── getAccountBillingAddress ─────────────────────────────────────────────

    /**
     * Verifies that the billing address is returned for a valid Opportunity
     * that is linked to an Account.
     */
    @isTest
    static void testGetAccountBillingAddress_positive() {
        Account acc = createAccount('Test Account');
        Opportunity opp = createOpportunity('Test Opp', acc.Id, null);

        Test.startTest();
        Account result = ARC_PaymentInfoController.getAccountBillingAddress(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Account should be returned for a valid opportunity');
        System.assertEquals(acc.Id, result.Id, 'Returned Account Id should match');
        System.assertEquals('123 Main St', result.BillingStreet, 'BillingStreet should match');
        System.assertEquals('Austin', result.BillingCity, 'BillingCity should match');
        System.assertEquals('TX', result.BillingState, 'BillingState should match');
        System.assertEquals('78701', result.BillingPostalCode, 'BillingPostalCode should match');
    }

    /**
     * Verifies that null is returned when opportunityId is null.
     */
    @isTest
    static void testGetAccountBillingAddress_nullOpportunityId() {
        Test.startTest();
        Account result = ARC_PaymentInfoController.getAccountBillingAddress(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null when opportunityId is null');
    }

    /**
     * Verifies that null is returned when the Opportunity has no linked Account.
     */
    @isTest
    static void testGetAccountBillingAddress_noLinkedAccount() {
        Opportunity opp = new Opportunity(
            Name      = 'No Account Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Test.startTest();
        Account result = ARC_PaymentInfoController.getAccountBillingAddress(opp.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null when Opportunity has no AccountId');
    }

    // ─── getChargentOrder ────────────────────────────────────────────────────

    /**
     * Verifies that null is returned when opportunityId is null.
     */
    @isTest
    static void testGetChargentOrder_nullOpportunityId() {
        Test.startTest();
        ARC_PaymentInfoController.ChargentOrderData result =
            ARC_PaymentInfoController.getChargentOrder(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null when opportunityId is null');
    }

    /**
     * Verifies that null is returned when the Opportunity has no AccountId.
     */
    @isTest
    static void testGetChargentOrder_noAccountId() {
        Opportunity opp = new Opportunity(
            Name      = 'No Account Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Test.startTest();
        ARC_PaymentInfoController.ChargentOrderData result =
            ARC_PaymentInfoController.getChargentOrder(opp.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null when Opportunity has no AccountId');
    }

    /**
     * Verifies that null is returned when no ChargentOrder exists for the Account.
     */
    @isTest
    static void testGetChargentOrder_noOrderFound() {
        Account acc = createAccount('Test Account');
        Opportunity opp = createOpportunity('Test Opp', acc.Id, null);

        Test.startTest();
        ARC_PaymentInfoController.ChargentOrderData result =
            ARC_PaymentInfoController.getChargentOrder(opp.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null when no ChargentOrder exists');
    }

    /**
     * Verifies that a ChargentOrder linked via ARC_Contract__c is found when
     * the Opportunity has a ContractId.
     */
    // @isTest
    // static void testGetChargentOrder_foundByContract() {
    //     Account acc      = createAccount('Test Account');
    //     Contract contract = createContract(acc.Id);
    //     ChargentOrders__ChargentOrder__c order =
    //         createChargentOrder(acc.Id, contract.Id, 'Bank Account');
    //     Opportunity opp  = createOpportunity('Test Opp', acc.Id, contract.Id);

    //     Test.startTest();
    //     ARC_PaymentInfoController.ChargentOrderData result =
    //         ARC_PaymentInfoController.getChargentOrder(opp.Id);
    //     Test.stopTest();

    //     System.assertNotEquals(null, result, 'ChargentOrderData should be returned');
    //     System.assertEquals(order.Id, result.id, 'Order Id should match the contract-linked order');
    //     System.assertEquals(acc.Id, result.accountId, 'Account Id should match');
    //     System.assertEquals('456 Elm St', result.billingStreet, 'Billing street should match');
    //     System.assertEquals('Dallas', result.billingCity, 'Billing city should match');
    //     System.assertEquals('TX', result.billingState, 'Billing state should match');
    //     System.assertEquals('75201', result.billingZip, 'Billing zip should match');
    // }

    /**
     * Verifies that a ChargentOrder is found by AccountId when no contract-linked order exists.
     */
    // @isTest
    // static void testGetChargentOrder_foundByAccount() {
    //     Account acc = createAccount('Test Account');
    //     ChargentOrders__ChargentOrder__c order =
    //         createChargentOrder(acc.Id, null, 'Credit Card');
    //     Opportunity opp = createOpportunity('Test Opp', acc.Id, null);

    //     Test.startTest();
    //     ARC_PaymentInfoController.ChargentOrderData result =
    //         ARC_PaymentInfoController.getChargentOrder(opp.Id);
    //     Test.stopTest();

    //     System.assertNotEquals(null, result, 'ChargentOrderData should be returned via account lookup');
    //     System.assertEquals(order.Id, result.id, 'Order Id should match the account-linked order');
    // }

    /**
     * Verifies that payment method 'Bank Account' maps to 'bank'.
     */
    // @isTest
    // static void testGetChargentOrder_paymentMethodBankAccount() {
    //     Account acc = createAccount('Test Account');
    //     createChargentOrder(acc.Id, null, 'Bank Account');
    //     Opportunity opp = createOpportunity('Test Opp', acc.Id, null);

    //     Test.startTest();
    //     ARC_PaymentInfoController.ChargentOrderData result =
    //         ARC_PaymentInfoController.getChargentOrder(opp.Id);
    //     Test.stopTest();

    //     System.assertEquals('bank', result.paymentMethod,
    //         'Payment method "Bank Account" should map to "bank"');
    // }

    // /**
    //  * Verifies that payment method 'ACH' maps to 'bank'.
    //  */
    // @isTest
    // static void testGetChargentOrder_paymentMethodACH() {
    //     Account acc = createAccount('Test Account');
    //     createChargentOrder(acc.Id, null, 'ACH');
    //     Opportunity opp = createOpportunity('Test Opp', acc.Id, null);

    //     Test.startTest();
    //     ARC_PaymentInfoController.ChargentOrderData result =
    //         ARC_PaymentInfoController.getChargentOrder(opp.Id);
    //     Test.stopTest();

    //     System.assertEquals('bank', result.paymentMethod,
    //         'Payment method "ACH" should map to "bank"');
    // }

    /**
     * Verifies that a payment method that is neither 'Bank Account' nor 'ACH' maps to 'card'.
     */
    // @isTest
    // static void testGetChargentOrder_paymentMethodCard() {
    //     Account acc = createAccount('Test Account');
    //     createChargentOrder(acc.Id, null, 'Credit Card');
    //     Opportunity opp = createOpportunity('Test Opp', acc.Id, null);

    //     Test.startTest();
    //     ARC_PaymentInfoController.ChargentOrderData result =
    //         ARC_PaymentInfoController.getChargentOrder(opp.Id);
    //     Test.stopTest();

    //     System.assertEquals('card', result.paymentMethod,
    //         'Payment method "Credit Card" should map to "card"');
    // }

    /**
     * Verifies that routingNumber is returned as 'ENCRYPTED' when the field has a value.
     */
    // @isTest
    // static void testGetChargentOrder_routingNumberEncrypted() {
    //     Account acc = createAccount('Test Account');
    //     createChargentOrder(acc.Id, null, 'Bank Account'); // routing = '021000021'
    //     Opportunity opp = createOpportunity('Test Opp', acc.Id, null);

    //     Test.startTest();
    //     ARC_PaymentInfoController.ChargentOrderData result =
    //         ARC_PaymentInfoController.getChargentOrder(opp.Id);
    //     Test.stopTest();

    //     System.assertEquals('ENCRYPTED', result.routingNumber,
    //         'A non-blank routing number should be returned as ENCRYPTED');
    //     System.assertEquals('Test Bank', result.bankName, 'Bank name should match');
    //     System.assertEquals('1234', result.bankLast4, 'Bank last 4 should match');
    // }

    /**
     * Verifies that routingNumber is null when the field is blank on the ChargentOrder.
     */
    // @isTest
    // static void testGetChargentOrder_routingNumberNull() {
    //     Account acc = createAccount('Test Account');
    //     ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
    //         ChargentOrders__Account__c        = acc.Id,
    //         ChargentOrders__Payment_Method__c = 'Bank Account',
    //         ChargentOrders__Bank_Name__c      = 'Test Bank'
    //         // ChargentOrders__Bank_Routing_Number__c intentionally omitted
    //     );
    //     insert order;
    //     Opportunity opp = createOpportunity('Test Opp', acc.Id, null);

    //     Test.startTest();
    //     ARC_PaymentInfoController.ChargentOrderData result =
    //         ARC_PaymentInfoController.getChargentOrder(opp.Id);
    //     Test.stopTest();

    //     System.assertEquals(null, result.routingNumber, 'routingNumber should be null when the field is blank');
    // }

    

    /**
     * Verifies that card expiration fields are NOT populated when both
     * Card_Month_Indicator__c and Card_Year_Indicator__c are null.
     * Covers the false branch of the null-check in getChargentOrder.
     */
    // @isTest
    // static void testGetChargentOrder_cardIndicatorsNull() {
    //     Account acc = createAccount('Test Account');
    //     ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
    //         ChargentOrders__Account__c        = acc.Id,
    //         ChargentOrders__Payment_Method__c = 'Credit Card',
    //         ChargentOrders__Card_Last_4__c    = '9999'
    //         // Card_Month_Indicator__c and Card_Year_Indicator__c intentionally omitted
    //     );
    //     insert order;
    //     Opportunity opp = createOpportunity('Test Opp', acc.Id, null);

    //     Test.startTest();
    //     ARC_PaymentInfoController.ChargentOrderData result =
    //         ARC_PaymentInfoController.getChargentOrder(opp.Id);
    //     Test.stopTest();

    //     System.assertNotEquals(null, result, 'Should return a result even with null card indicators');
    //     System.assertEquals(null, result.cardExpirationMonth,
    //         'cardExpirationMonth should be null when Card_Month_Indicator__c is null');
    //     System.assertEquals(null, result.cardExpirationYear,
    //         'cardExpirationYear should be null when Card_Year_Indicator__c is null');
    // }

    // // ─── getChargentOrder – Renewal path ─────────────────────────────────────

    // /** Helper: safely retrieve the ARC_Renewal Opportunity RecordType Id, or null. */
    private static Id getRenewalRecordTypeId() {
        try {
            Schema.RecordTypeInfo rti =
                Schema.SObjectType.Opportunity
                    .getRecordTypeInfosByDeveloperName()
                    .get('ARC_Renewal');
            return rti != null ? rti.getRecordTypeId() : null;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Renewal path – ContractId populated on the Opportunity, and the Contract
     * has ARC_RecurringMonthlyOrder__c set.  Verifies the recurring order is returned.
     */
    @isTest
    static void testGetChargentOrder_renewalWithContractId() {
        Id renewalRTId = getRenewalRecordTypeId();
        if (renewalRTId == null) return; // RecordType absent in this org – skip

        Account acc      = createAccount('Renewal Account');
        Contract cont    = createContract(acc.Id);

        // ChargentOrder that will be the recurring order on the Contract
        ChargentOrders__ChargentOrder__c recurringOrder =
            createChargentOrder(acc.Id, cont.Id, 'Credit Card');

        cont.ARC_RecurringMonthlyOrder__c = recurringOrder.Id;
        update cont;

        Opportunity opp = new Opportunity(
            Name         = 'Renewal Opp',
            StageName    = 'Prospecting',
            CloseDate    = Date.today().addDays(30),
            AccountId    = acc.Id,
            ContractId   = cont.Id,
            RecordTypeId = renewalRTId
        );
        insert opp;

        Test.startTest();
        ARC_PaymentInfoController.ChargentOrderData result =
            ARC_PaymentInfoController.getChargentOrder(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result,
            'Renewal with ContractId and recurring order should return ChargentOrderData');
        System.assertEquals(recurringOrder.Id, result.id,
            'Returned order Id should match ARC_RecurringMonthlyOrder__c');
    }

    /**
     * Renewal path – ContractId is null on the Opportunity, so the controller
     * falls back to finding the most recent Activated Contract for the Account.
     */
    // @isTest
    // static void testGetChargentOrder_renewalWithoutContractId_findsActiveContract() {
    //     Id renewalRTId = getRenewalRecordTypeId();
    //     if (renewalRTId == null) return;

    //     Account acc   = createAccount('Renewal Account NoContractId');
    //     Contract cont = createContract(acc.Id);
    //     cont.Status   = 'Activated';
    //     update cont;

    //     ChargentOrders__ChargentOrder__c recurringOrder =
    //         createChargentOrder(acc.Id, cont.Id, 'Bank Account');

    //     // Some orgs have a validation rule preventing direct Contract Status changes.
    //     // Wrap in try/catch and skip gracefully if activation is blocked.
    //     try {
    //         cont.ARC_RecurringMonthlyOrder__c = recurringOrder.Id;
    //         cont.Status = 'Activated';
    //         update cont;
    //     } catch (DmlException e) {
    //         // Cannot activate contract in this org's test environment – skip.
    //         return;
    //     }

    //     // Opportunity has NO ContractId – controller must find Activated Contract
    //     Opportunity opp = new Opportunity(
    //         Name         = 'Renewal No ContractId Opp',
    //         StageName    = 'Prospecting',
    //         CloseDate    = Date.today().addDays(30),
    //         AccountId    = acc.Id,
    //         RecordTypeId = renewalRTId
    //     );
    //     insert opp;

    //     Test.startTest();
    //     ARC_PaymentInfoController.ChargentOrderData result =
    //         ARC_PaymentInfoController.getChargentOrder(opp.Id);
    //     Test.stopTest();

    //     System.assertNotEquals(null, result,
    //         'Renewal without ContractId should find active contract and return order');
    //     System.assertEquals(recurringOrder.Id, result.id,
    //         'Returned order Id should match the recurring order on the active contract');
    // }

    /**
     * Renewal path – no ContractId on Opp and no Activated Contract exists.
     * Verifies the method returns null without throwing.
     */
    @isTest
    static void testGetChargentOrder_renewalNoContractFound() {
        Id renewalRTId = getRenewalRecordTypeId();
        if (renewalRTId == null) return;

        Account acc = createAccount('Renewal No Contract Account');
        // No contract is created for this Account

        Opportunity opp = new Opportunity(
            Name         = 'Renewal No Contract Opp',
            StageName    = 'Prospecting',
            CloseDate    = Date.today().addDays(30),
            AccountId    = acc.Id,
            RecordTypeId = renewalRTId
        );
        insert opp;

        Test.startTest();
        ARC_PaymentInfoController.ChargentOrderData result =
            ARC_PaymentInfoController.getChargentOrder(opp.Id);
        Test.stopTest();

        System.assertEquals(null, result,
            'Renewal with no active contract should return null');
    }

    /**
     * Renewal path – Contract exists and is linked via ContractId, but it has
     * no ARC_RecurringMonthlyOrder__c.  Verifies null is returned gracefully.
     */
    @isTest
    static void testGetChargentOrder_renewalContractHasNoRecurringOrder() {
        Id renewalRTId = getRenewalRecordTypeId();
        if (renewalRTId == null) return;

        Account acc   = createAccount('Renewal No Recurring Order Account');
        Contract cont = createContract(acc.Id);
        // ARC_RecurringMonthlyOrder__c intentionally left null

        Opportunity opp = new Opportunity(
            Name         = 'Renewal No Recurring Opp',
            StageName    = 'Prospecting',
            CloseDate    = Date.today().addDays(30),
            AccountId    = acc.Id,
            ContractId   = cont.Id,
            RecordTypeId = renewalRTId
        );
        insert opp;

        Test.startTest();
        ARC_PaymentInfoController.ChargentOrderData result =
            ARC_PaymentInfoController.getChargentOrder(opp.Id);
        Test.stopTest();

        System.assertEquals(null, result,
            'Renewal with contract but no recurring order should return null');
    }

    /**
     * Verifies bulk robustness: multiple opportunities all resolve their ChargentOrder.
     */
    // @isTest
    // static void testGetChargentOrder_bulkOpportunities() {
    //     Account acc = createAccount('Bulk Account');
    //     // Insert one order linked by account; all opportunities share the same account
    //     createChargentOrder(acc.Id, null, 'Bank Account');

    //     List<Opportunity> opps = new List<Opportunity>();
    //     for (Integer i = 0; i < 10; i++) {
    //         opps.add(new Opportunity(
    //             Name      = 'Bulk Opp ' + i,
    //             StageName = 'Prospecting',
    //             CloseDate = Date.today().addDays(30),
    //             AccountId = acc.Id
    //         ));
    //     }
    //     insert opps;

    //     Test.startTest();
    //     for (Opportunity opp : opps) {
    //         ARC_PaymentInfoController.ChargentOrderData result =
    //             ARC_PaymentInfoController.getChargentOrder(opp.Id);
    //         System.assertNotEquals(null, result,
    //             'Each opportunity should find the ChargentOrder for its account');
    //     }
    //     Test.stopTest();
    //}

    // ─── getPaymentContacts ───────────────────────────────────────────────────

    /**
     * Verifies that null is returned when opportunityId is null.
     */
    @isTest
    static void testGetPaymentContacts_nullOpportunityId() {
        Test.startTest();
        ARC_PaymentInfoController.PaymentContactsData result =
            ARC_PaymentInfoController.getPaymentContacts(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null when opportunityId is null');
    }

    /**
     * Verifies that null is returned when the Opportunity has no AccountId.
     */
    @isTest
    static void testGetPaymentContacts_noAccountId() {
        Opportunity opp = new Opportunity(
            Name      = 'No Account Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Test.startTest();
        ARC_PaymentInfoController.PaymentContactsData result =
            ARC_PaymentInfoController.getPaymentContacts(opp.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null when Opportunity has no AccountId');
    }

    /**
     * Verifies that distinct contacts are assigned to the correct role fields
     * (primaryBusinessContact, accountHolder, billingContact).
     */
    @isTest
    static void testGetPaymentContacts_contactsByRole() {
        Account acc     = createAccount('Test Account');
        Opportunity opp = createOpportunity('Test Opp', acc.Id, null);

        Contact primaryContact  = createContact(acc.Id, 'Primary',  'Contact');
        Contact holderContact   = createContact(acc.Id, 'Account',  'Holder');
        Contact billingContact  = createContact(acc.Id, 'Billing',  'Contact');

        // Update the auto-created AccountContactRelation records with the correct roles
        Map<Id, String> roleByContactId = new Map<Id, String>{
            primaryContact.Id => 'Primary Business Contact',
            holderContact.Id  => 'Account Holder',
            billingContact.Id => 'Billing Contact'
        };
        List<AccountContactRelation> acrs = [
            SELECT Id, ContactId, Roles
            FROM AccountContactRelation
            WHERE AccountId = :acc.Id
              AND ContactId IN :roleByContactId.keySet()
        ];
        for (AccountContactRelation acr : acrs) {
            acr.Roles = roleByContactId.get(acr.ContactId);
        }
        update acrs;

        Test.startTest();
        ARC_PaymentInfoController.PaymentContactsData result =
            ARC_PaymentInfoController.getPaymentContacts(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'PaymentContactsData should not be null');
        System.assertNotEquals(null, result.primaryBusinessContact,
            'primaryBusinessContact should not be null');
        System.assertEquals(primaryContact.Id, result.primaryBusinessContact.id,
            'primaryBusinessContact Id should match');
        System.assertNotEquals(null, result.accountHolder, 'accountHolder should not be null');
        System.assertEquals(holderContact.Id, result.accountHolder.id,
            'accountHolder Id should match');
        System.assertNotEquals(null, result.billingContact, 'billingContact should not be null');
        System.assertEquals(billingContact.Id, result.billingContact.id,
            'billingContact Id should match');
    }

    /**
     * Verifies that all ContactData fields are correctly mapped from the Contact record.
     */
    @isTest
    static void testGetPaymentContacts_contactDataFieldMapping() {
        Account acc     = createAccount('Test Account');
        Opportunity opp = createOpportunity('Test Opp', acc.Id, null);
        Contact c       = createContact(acc.Id, 'John', 'Doe');

        List<AccountContactRelation> acrs = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE AccountId = :acc.Id AND ContactId = :c.Id
        ];
        acrs[0].Roles = 'Primary Business Contact';
        update acrs;

        Test.startTest();
        ARC_PaymentInfoController.PaymentContactsData result =
            ARC_PaymentInfoController.getPaymentContacts(opp.Id);
        Test.stopTest();

        ARC_PaymentInfoController.ContactData cd = result.primaryBusinessContact;
        System.assertNotEquals(null, cd, 'ContactData should not be null');
        System.assertEquals(c.Id,           cd.id,        'Contact Id should match');
        System.assertEquals('John',         cd.firstName, 'First name should match');
        System.assertEquals('Doe',          cd.lastName,  'Last name should match');
        System.assertEquals('John Doe',     cd.name,      'Full name should match');
        System.assertEquals('john.doe@test.com', cd.email, 'Email should match');
        System.assertEquals('5125551234',   cd.phone,     'Phone should match');
        System.assertEquals('Test Title',   cd.title,     'Title should match');
        System.assertEquals('789 Oak Ave',  cd.street,    'Street should match');
        System.assertEquals('Houston',      cd.city,      'City should match');
        System.assertEquals('TX',           cd.state,     'State should match');
        System.assertEquals('77001',        cd.zip,       'Zip should match');
        System.assert(cd.roles.contains('Primary Business Contact'),
            'Roles list should contain Primary Business Contact');
    }

    /**
     * Verifies that a contact with multiple roles is assigned to all matching role fields.
     */
    @isTest
    static void testGetPaymentContacts_contactWithMultipleRoles() {
        Account acc     = createAccount('Test Account');
        Opportunity opp = createOpportunity('Test Opp', acc.Id, null);
        Contact c       = createContact(acc.Id, 'Multi', 'Role');

        List<AccountContactRelation> acrs = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE AccountId = :acc.Id AND ContactId = :c.Id
        ];
        acrs[0].Roles = 'Primary Business Contact;Account Holder;Billing Contact';
        update acrs;

        Test.startTest();
        ARC_PaymentInfoController.PaymentContactsData result =
            ARC_PaymentInfoController.getPaymentContacts(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.primaryBusinessContact,
            'primaryBusinessContact should be populated for a multi-role contact');
        System.assertNotEquals(null, result.accountHolder,
            'accountHolder should be populated for a multi-role contact');
        System.assertNotEquals(null, result.billingContact,
            'billingContact should be populated for a multi-role contact');
        System.assertEquals(c.Id, result.primaryBusinessContact.id,
            'Multi-role contact should be assigned as primaryBusinessContact');
        System.assertEquals(c.Id, result.accountHolder.id,
            'Multi-role contact should be assigned as accountHolder');
        System.assertEquals(c.Id, result.billingContact.id,
            'Multi-role contact should be assigned as billingContact');
    }

    /**
     * Verifies that an empty PaymentContactsData wrapper is returned (no nulls thrown)
     * when the Account has contacts but none carry the expected roles.
     */
    @isTest
    static void testGetPaymentContacts_noMatchingRoles() {
        Account acc     = createAccount('Test Account');
        Opportunity opp = createOpportunity('Test Opp', acc.Id, null);
        // Contact is inserted but ACR Roles field is intentionally left blank
        createContact(acc.Id, 'NoRole', 'Contact');

        Test.startTest();
        ARC_PaymentInfoController.PaymentContactsData result =
            ARC_PaymentInfoController.getPaymentContacts(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result,
            'PaymentContactsData wrapper should not be null even with no matching roles');
        System.assertEquals(null, result.primaryBusinessContact, 'primaryBusinessContact should be null when no contact has that role');
        System.assertEquals(null, result.accountHolder, 'accountHolder should be null when no contact has that role');
        System.assertEquals(null, result.billingContact, 'billingContact should be null when no contact has that role');
    }
}