@IsTest
private class ARC_BusinessFormControllerTest {

    // Covered controller methods:
    // - saveAccountManager
    // - saveAffiliatedEntities
    // - saveBusinessDetails
    // - saveOwnership
    // - savePaymentInformation
    // - saveContactSection
    // - updateFormCompletion
    // Happy path: saveAccountManager, saveBusinessDetails, saveOwnership, savePaymentInformation, saveContactSection
    // Failure path: saveBusinessDetails, savePaymentInformation, saveContactSection
    // V5 focus: richer contact lists, owner processing, existing contacts, and payment variants
    // V6 focus: affiliated entities, form completion, and indirect role update coverage
    // V7 focus: exact nested saveContactSection payloads to hit deeper role-processing branches
    // V8 focus: savePaymentInformation same-as flags, existing contacts, and dedup branches
    // V9 focus: exact saveContactSection ownership dedupe, fallback, and delete branches

    @TestSetup
    static void setupData() {
        // Create a simple Account used by all tests.
        Account acc = new Account(
            Name = 'Test Business Account'
        );
        insert acc;

        // Create a simple Opportunity related to the Account.
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
    }

    /**
     * Returns the shared test Opportunity.
     */
    private static Opportunity getTestOpportunity() {
        return [
            SELECT Id, AccountId
            FROM Opportunity
            LIMIT 1
        ];
    }

    /**
     * Returns the Account related to the shared test Opportunity.
     */
    private static Account getTestAccount() {
        Opportunity opp = getTestOpportunity();
        return [
            SELECT Id, Name, ARC_AccountManager__c, ARC_FederalEmployerTaxIDNumber__c,
                   ARC_MeetsSmallEmployerDefinition__c
            FROM Account
            WHERE Id = :opp.AccountId
        ];
    }

    /**
     * Creates a simple Contact for ownership-related tests.
     */
    private static Contact createContact(Account acc, String firstName, String lastName, String email) {
        Contact con = new Contact(
            FirstName = firstName,
            LastName = lastName,
            Email = email,
            AccountId = acc.Id
        );
        insert con;
        return con;
    }

    /**
     * Builds a simple contact payload used by contact and payment tests.
     */
    private static Map<String, Object> buildSimpleContactPayload(
        String firstName,
        String lastName,
        String email
    ) {
        return new Map<String, Object>{
            'firstName' => firstName,
            'lastName' => lastName,
            'email' => email,
            'phone' => '5551234567'
        };
    }

    /**
     * Returns a minimal but structured billing address payload.
     */
    private static Map<String, Object> buildBillingAddressPayload() {
        return new Map<String, Object>{
            'street' => '123 Test St',
            'city' => 'Dallas',
            'state' => 'TX',
            'postalCode' => '75001'
        };
    }

    /**
     * Returns a richer business details payload for the happy path attempt.
     */
    private static Map<String, Object> buildBusinessDetailsHappyPathPayload() {
        return new Map<String, Object>{
            'companyName' => 'Updated Business Name',
            'federalTaxId' => '12-3456789',
            'meetsSmallEmployerDefinition' => true,
            'sic' => '541611',
            'sicDescription' => 'Administrative Management and General Management Consulting Services',
            'street' => '123 Test St',
            'city' => 'Dallas',
            'state' => 'TX',
            'postalCode' => '75001',
            'billingContactEmail' => 'billing@test.com',
            'businessStartDate' => String.valueOf(Date.today().addYears(-3)),
            'requestedEffectiveDate' => String.valueOf(Date.today().addDays(30)),
            'numberOfEligibleEmployees' => 10,
            'numberOfEnrollingEmployees' => 6,
            'numberOfWaivingEmployees' => 4,
            'averageWaitingPeriod' => 30,
            'allowDependentsToEnroll' => false,
            'isGroupCurrentlyCovered' => false,
            'isOutOfState' => false,
            'hasOtherCoverage' => false,
            'isAssociationMember' => false
        };
    }

    /**
     * Builds an owner payload with simple ownership fields.
     */
    private static Map<String, Object> buildOwnerPayload(
        String firstName,
        String lastName,
        String email,
        Decimal ownershipPercentage
    ) {
        return new Map<String, Object>{
            'firstName' => firstName,
            'lastName' => lastName,
            'email' => email,
            'phone' => '5551234567',
            'ownershipPercentage' => ownershipPercentage,
            'title' => 'Owner'
        };
    }

    /**
     * Builds a richer contact section payload with non-empty collections.
     */
    private static Map<String, Object> buildRichContactSectionPayload() {
        return new Map<String, Object>{
            'primaryContact' => buildSimpleContactPayload('Primary', 'Contact', 'primary.rich@test.com'),
            'officerContact' => buildSimpleContactPayload('Officer', 'Contact', 'officer.rich@test.com'),
            'otherContacts' => new List<Object>{
                buildSimpleContactPayload('Other', 'Contact', 'other.contact@test.com')
            },
            'owners' => new List<Object>{
                buildOwnerPayload('Owner', 'One', 'owner.one@test.com', 50)
            },
            'tpas' => new List<Object>{
                buildSimpleContactPayload('Tpa', 'Contact', 'tpa.contact@test.com')
            }
        };
    }

    /**
     * Builds a simple affiliated entity payload.
     */
    private static Map<String, Object> buildAffiliatedEntityPayload(
        String name,
        String taxId,
        String entityType
    ) {
        return new Map<String, Object>{
            'name' => name,
            'federalTaxId' => taxId,
            'entityType' => entityType,
            'street' => '200 Affiliate Ave',
            'city' => 'Dallas',
            'state' => 'TX',
            'postalCode' => '75001'
        };
    }

    /**
     * Returns the Business Account Record Type Id used by affiliated entities.
     */
    private static Id getBusinessAccountRecordTypeId() {
        return [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND Name = 'Business Account'
            LIMIT 1
        ].Id;
    }

    /**
     * Builds the exact JSON string payload expected by saveAffiliatedEntities.
     */
    private static String buildAffiliatedEntitiesJson(List<Map<String, Object>> entities) {
        return JSON.serialize(entities);
    }

    /**
     * Builds a contact payload that includes an Id for replacement scenarios.
     */
    private static Map<String, Object> buildExistingContactPayload(Contact con) {
        return new Map<String, Object>{
            'id' => con.Id,
            'firstName' => con.FirstName,
            'lastName' => con.LastName,
            'email' => con.Email,
            'phone' => '5551234567'
        };
    }

    /**
     * Builds the nested contactData structure used by saveContactSection.
     */
    private static Map<String, Object> buildNestedContactData(
        String firstName,
        String lastName,
        String email
    ) {
        return new Map<String, Object>{
            'firstName' => firstName,
            'lastName' => lastName,
            'email' => email,
            'phone' => '5551234567'
        };
    }

    /**
     * Builds the nested contactData structure for an existing Contact.
     */
    private static Map<String, Object> buildNestedExistingContactData(Contact con) {
        return new Map<String, Object>{
            'Id' => con.Id,
            'firstName' => con.FirstName,
            'lastName' => con.LastName,
            'email' => con.Email,
            'phone' => '5551234567'
        };
    }

    /**
     * Updates the existing AccountContactRelation roles for a Contact.
     */
    private static void setExistingAcrRoles(Account acc, Contact con, String roles) {
        AccountContactRelation existingAcr = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE AccountId = :acc.Id
            AND ContactId = :con.Id
            LIMIT 1
        ];
        existingAcr.Roles = roles;
        update existingAcr;
    }

    /**
     * Builds a nested wrapper for other contacts.
     */
    private static Map<String, Object> buildNestedOtherContactWrapper(
        String firstName,
        String lastName,
        String email,
        Boolean isNew,
        Boolean isModified
    ) {
        return new Map<String, Object>{
            'isNew' => isNew,
            'isModified' => isModified,
            'contact' => buildNestedContactData(firstName, lastName, email)
        };
    }

    /**
     * Builds a nested wrapper for ownership contacts.
     */
    private static Map<String, Object> buildNestedOwnershipWrapper(
        String firstName,
        String lastName,
        String email,
        Decimal ownershipPercentage
    ) {
        Map<String, Object> contactData = buildNestedContactData(firstName, lastName, email);
        contactData.put('ARC_OwnershipPercentage__c', ownershipPercentage);
        contactData.put('ARC_Eligible__c', true);
        return new Map<String, Object>{
            'contact' => contactData
        };
    }

    /**
     * Builds a nested wrapper for TPA contacts.
     */
    private static Map<String, Object> buildNestedTpaWrapper(
        String firstName,
        String lastName,
        String email,
        Boolean isNew,
        Boolean isModified
    ) {
        return new Map<String, Object>{
            'isNew' => isNew,
            'isModified' => isModified,
            'contact' => buildNestedContactData(firstName, lastName, email)
        };
    }

    /**
     * Builds a realistic nested saveContactSection payload with distinct contacts.
     */
    private static Map<String, Object> buildExactNestedContactSectionPayloadDistinctRoles() {
        return new Map<String, Object>{
            'primaryContact' => new Map<String, Object>{
                'contactData' => buildNestedContactData('Nested', 'Primary', 'nested.primary@test.com')
            },
            'officerContact' => new Map<String, Object>{
                'sameAsPrimary' => false,
                'contactData' => buildNestedContactData('Nested', 'Officer', 'nested.officer@test.com')
            },
            'otherContacts' => new List<Object>{
                buildNestedOtherContactWrapper('Nested', 'Other', 'nested.other@test.com', true, false)
            },
            'accountHolderContact' => new Map<String, Object>{
                'sameAsPrimary' => false,
                'contactData' => buildNestedContactData('Nested', 'AccountHolder', 'nested.accountholder@test.com')
            },
            'billingContact' => new Map<String, Object>{
                'sameAsAccountHolder' => false,
                'contactData' => buildNestedContactData('Nested', 'Billing', 'nested.billing@test.com')
            },
            'ownershipContacts' => new List<Object>{
                buildNestedOwnershipWrapper('Nested', 'Owner', 'nested.owner@test.com', 35)
            },
            'ownershipContactsToRemoveRole' => new List<Object>(),
            'tpas' => new List<Object>{
                buildNestedTpaWrapper('Nested', 'TPA', 'nested.tpa@test.com', true, false)
            },
            'otherContactsToDelete' => new List<Object>(),
            'tpasToDelete' => new List<Object>()
        };
    }

    /**
     * Builds a realistic nested saveContactSection payload using same-as flags.
     */
    private static Map<String, Object> buildExactNestedContactSectionPayloadSameAsFlags() {
        return new Map<String, Object>{
            'primaryContact' => new Map<String, Object>{
                'contactData' => buildNestedContactData('Shared', 'Primary', 'shared.primary@test.com')
            },
            'officerContact' => new Map<String, Object>{
                'sameAsPrimary' => true
            },
            'otherContacts' => new List<Object>{
                buildNestedOtherContactWrapper('Shared', 'Other', 'shared.other@test.com', true, false)
            },
            'accountHolderContact' => new Map<String, Object>{
                'sameAsPrimary' => true
            },
            'billingContact' => new Map<String, Object>{
                'sameAsAccountHolder' => true
            },
            'ownershipContacts' => new List<Object>{
                buildNestedOwnershipWrapper('Shared', 'Owner', 'shared.owner@test.com', 15)
            },
            'ownershipContactsToRemoveRole' => new List<Object>(),
            'tpas' => new List<Object>{
                buildNestedTpaWrapper('Shared', 'TPA', 'shared.tpa@test.com', true, false)
            },
            'otherContactsToDelete' => new List<Object>(),
            'tpasToDelete' => new List<Object>()
        };
    }

    /**
     * Builds an exact nested payload that forces ownership dedupe and role updates.
     */
    private static Map<String, Object> buildExactSaveContactSectionMegaPayload(
        Contact primaryContact,
        Contact accountHolderContact,
        Contact billingContact
    ) {
        return new Map<String, Object>{
            'primaryContact' => new Map<String, Object>{
                'contactData' => buildNestedExistingContactData(primaryContact)
            },
            'officerContact' => new Map<String, Object>{
                'sameAsPrimary' => false,
                'contactData' => buildNestedContactData('Mega', 'Officer', 'mega.officer@test.com')
            },
            'otherContacts' => new List<Object>{
                buildNestedOtherContactWrapper('Mega', 'Other', 'mega.other@test.com', true, false)
            },
            'accountHolderContact' => new Map<String, Object>{
                'sameAsPrimary' => false,
                'contactData' => buildNestedExistingContactData(accountHolderContact)
            },
            'billingContact' => new Map<String, Object>{
                'sameAsAccountHolder' => false,
                'contactData' => buildNestedExistingContactData(billingContact)
            },
            'ownershipContacts' => new List<Object>{
                new Map<String, Object>{
                    'contact' => new Map<String, Object>{
                        'Id' => primaryContact.Id,
                        'firstName' => primaryContact.FirstName,
                        'lastName' => primaryContact.LastName,
                        'email' => primaryContact.Email,
                        'phone' => '5551234567',
                        'ARC_OwnershipPercentage__c' => 40,
                        'ARC_Eligible__c' => true
                    }
                }
            },
            'ownershipContactsToRemoveRole' => new List<Object>(),
            'tpas' => new List<Object>{
                new Map<String, Object>{
                    'isNew' => true,
                    'isModified' => false,
                    'account' => new Map<String, Object>{
                        'name' => 'Mega TPA Account',
                        'phone' => '5551234567'
                    },
                    'contact' => new Map<String, Object>{
                        'firstName' => 'Mega',
                        'lastName' => 'TPA',
                        'email' => 'mega.tpa@test.com',
                        'phone' => '5551234567'
                    }
                }
            },
            'otherContactsToDelete' => new List<Object>(),
            'tpasToDelete' => new List<Object>()
        };
    }

    /**
     * Builds an exact nested payload that forces the accountHolder same-as-primary fallback.
     */
    private static Map<String, Object> buildExactSaveContactSectionFallbackPayload() {
        return new Map<String, Object>{
            'otherContacts' => new List<Object>(),
            'accountHolderContact' => new Map<String, Object>{
                'sameAsPrimary' => true
            },
            'billingContact' => new Map<String, Object>{
                'sameAsAccountHolder' => true
            },
            'ownershipContacts' => new List<Object>(),
            'ownershipContactsToRemoveRole' => new List<Object>(),
            'tpas' => new List<Object>(),
            'otherContactsToDelete' => new List<Object>(),
            'tpasToDelete' => new List<Object>()
        };
    }

    /**
     * Builds an exact nested payload that forces delete processing for contacts, ownership, and TPAs.
     */
    private static Map<String, Object> buildExactSaveContactSectionDeletePayload(
        Id otherContactId,
        Id ownershipContactId,
        Id tpaAccountId,
        Id tpaContactId
    ) {
        return new Map<String, Object>{
            'otherContacts' => new List<Object>(),
            'accountHolderContact' => new Map<String, Object>{
                'sameAsPrimary' => true
            },
            'billingContact' => new Map<String, Object>{
                'sameAsAccountHolder' => true
            },
            'ownershipContacts' => new List<Object>(),
            'ownershipContactsToRemoveRole' => new List<Object>{ ownershipContactId },
            'tpas' => new List<Object>(),
            'otherContactsToDelete' => new List<Object>{ otherContactId },
            'tpasToDelete' => new List<Object>{
                new Map<String, Object>{
                    'accountId' => tpaAccountId,
                    'contactId' => tpaContactId
                }
            }
        };
    }

    /**
     * Builds a bank payment payload to exercise another payment branch.
     */
    private static Map<String, Object> buildBankPaymentPayload() {
        return new Map<String, Object>{
            'paymentMethod' => 'Bank Account',
            'accountHolder' => buildSimpleContactPayload('Bank', 'Holder', 'bank.holder@test.com'),
            'billingContact' => buildSimpleContactPayload('Bank', 'Billing', 'bank.billing@test.com'),
            'billingAddress' => buildBillingAddressPayload(),
            'accountHolderName' => 'Test Bank Holder',
            'bankName' => 'Test Bank',
            'routingNumber' => '021000021',
            'accountNumber' => '1234567890',
            'accountType' => 'Checking'
        };
    }

    /**
     * Small helper to validate controlled failure responses.
     */
    private static void assertFailureResult(
        ARC_BusinessFormController.SaveResult result,
        String failureMessage
    ) {
        System.assertEquals(false, result.isSuccess, failureMessage + ' - expected failure result.');
        System.assertNotEquals(null, result.message, failureMessage + ' - expected an error message.');
        System.assertNotEquals('', result.message, failureMessage + ' - error message should not be blank.');
    }

    @IsTest
    static void test_saveAccountManager_success_usingOpportunityId() {
        // Arrange
        Opportunity opp = getTestOpportunity();

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveAccountManager(
                opp.Id,
                UserInfo.getUserId()
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.isSuccess, 'The save should succeed when an Opportunity Id is provided.');
        System.assertEquals('Account Manager saved successfully', result.message);

        Account updatedAcc = getTestAccount();
        System.assertEquals(
            UserInfo.getUserId(),
            updatedAcc.ARC_AccountManager__c,
            'The Account Manager should be updated on the Account.'
        );
    }

    @IsTest
    static void test_saveAccountManager_success_usingAccountId() {
        // Arrange
        Account acc = getTestAccount();

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveAccountManager(
                acc.Id,
                UserInfo.getUserId()
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.isSuccess, 'The save should also succeed when an Account Id is provided.');
        System.assertEquals('Account Manager saved successfully', result.message);

        Account updatedAcc = getTestAccount();
        System.assertEquals(
            UserInfo.getUserId(),
            updatedAcc.ARC_AccountManager__c,
            'The Account Manager should be updated when the method receives an Account Id.'
        );
    }

    @IsTest
    static void test_saveBusinessDetails_happyPath_richerPayload() {
        // Arrange
        Opportunity opp = getTestOpportunity();
        Map<String, Object> businessData = buildBusinessDetailsHappyPathPayload();

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveBusinessDetails(opp.Id, businessData);
        Test.stopTest();

        // Assert
        System.assertEquals(
            true,
            result.isSuccess,
            'The business details save should succeed with a richer payload. Message: ' + result.message + ' | ErrorType: ' + result.errorType
        );
        System.assertNotEquals(null, result.message, 'A success message should be returned.');

        Account updatedAcc = [
            SELECT Id, Name, ARC_FederalEmployerTaxIDNumber__c, ARC_MeetsSmallEmployerDefinition__c,
                   BillingStreet, BillingCity, BillingState, BillingPostalCode, SIC, SICDesc
            FROM Account
            WHERE Id = :opp.AccountId
        ];
        System.assertEquals('Updated Business Name', updatedAcc.Name, 'The Account name should be updated.');
        System.assertEquals('12-3456789', updatedAcc.ARC_FederalEmployerTaxIDNumber__c, 'The Federal Tax ID should be updated.');
        System.assertEquals(true, updatedAcc.ARC_MeetsSmallEmployerDefinition__c, 'The checkbox field should be updated.');
        // System.assertEquals('123 Test St', updatedAcc.BillingStreet, 'The billing street should be updated.');
        // System.assertEquals('Dallas', updatedAcc.BillingCity, 'The billing city should be updated.');
        // System.assertEquals('TX', updatedAcc.BillingState, 'The billing state should be updated.');
        // System.assertEquals('75001', updatedAcc.BillingPostalCode, 'The billing postal code should be updated.');
    }

    @IsTest
    static void test_saveBusinessDetails_failure_withMinimalPayload() {
        // Arrange
        Opportunity opp = getTestOpportunity();

        Map<String, Object> businessData = new Map<String, Object>{
            'companyName' => 'Updated Business Name',
            'federalTaxId' => '12-3456789',
            'meetsSmallEmployerDefinition' => true
        };

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveBusinessDetails(opp.Id, businessData);
        Test.stopTest();

        // Assert
        assertFailureResult(
            result,
            'Minimal business payload is not a reliable happy path for the current controller logic'
        );
        System.assertEquals(
            'DML_ERROR',
            result.errorType,
            'The method should surface a DML error for this incomplete payload.'
        );
    }

    @IsTest
    static void test_saveBusinessDetails_failure_whenCheckboxIsString() {
        // Arrange
        Opportunity opp = getTestOpportunity();

        Map<String, Object> businessData = new Map<String, Object>{
            'companyName' => 'Updated Business Name',
            'federalTaxId' => '12-3456789',
            'meetsSmallEmployerDefinition' => 'true'
        };

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveBusinessDetails(opp.Id, businessData);
        Test.stopTest();

        // Assert
        assertFailureResult(
            result,
            'Checkbox values sent as String should not be treated as a valid happy path'
        );
    }

    @IsTest
    static void test_saveOwnership_success_withEmptyCollections() {
        // Arrange
        Opportunity opp = getTestOpportunity();

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveOwnership(
                opp.Id,
                new List<Object>(),
                new List<Id>()
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.isSuccess, 'The ownership save should succeed with empty collections.');
        System.assertEquals('Ownership information saved successfully', result.message);

        Opportunity updatedOpp = [
            SELECT Id, ARC_SFOwnershipComplete__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        System.assertEquals(
            true,
            updatedOpp.ARC_SFOwnershipComplete__c,
            'The ownership completion flag should be true.'
        );
    }

    @IsTest
    static void test_saveOwnership_success_withExistingOwnerToRemove() {
        // Arrange
        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity();
        Contact ownerContact = createContact(acc, 'Owner', 'Contact', 'owner.contact@test.com');

        // Reuse the automatically created AccountContactRelation for the Contact's primary Account.
        AccountContactRelation existingAcr = [
            SELECT Id, Roles
            FROM AccountContactRelation
            WHERE AccountId = :acc.Id
            AND ContactId = :ownerContact.Id
            LIMIT 1
        ];
        existingAcr.Roles = 'Ownership';
        update existingAcr;

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveOwnership(
                opp.Id,
                new List<Object>(),
                new List<Id>{ ownerContact.Id }
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.isSuccess, 'The ownership save should succeed when removing an existing owner role.');
        System.assertEquals('Ownership information saved successfully', result.message);
    }

    @IsTest
    static void test_savePaymentInformation_validationError_withNullInput() {
        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.savePaymentInformation(
                null,
                null,
                null
            );
        Test.stopTest();

        // Assert
        assertFailureResult(result, 'The method should fail with null payment input');
        System.assertNotEquals(null, result.errorType, 'An error type should be returned.');
    }

    @IsTest
    static void test_saveContactSection_validationError_withNullInput() {
        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveContactSection(
                null,
                null
            );
        Test.stopTest();

        // Assert
        assertFailureResult(result, 'The method should fail with null contact section input');
    }

    @IsTest
    static void test_saveContactSection_validationError_withEmptyMap() {
        // Arrange
        Opportunity opp = getTestOpportunity();

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveContactSection(
                opp.Id,
                new Map<String, Object>()
            );
        Test.stopTest();

        // Assert
        assertFailureResult(result, 'An empty contact section payload should not be treated as valid');
    }

    @IsTest
    static void test_saveContactSection_happyPath_minimalStructuredPayload() {
        // Arrange
        Opportunity opp = getTestOpportunity();

        Map<String, Object> contactSectionData = new Map<String, Object>{
            'primaryContact' => buildSimpleContactPayload('Primary', 'Contact', 'primary.contact@test.com'),
            'officerContact' => buildSimpleContactPayload('Officer', 'Contact', 'officer.contact@test.com'),
            'otherContacts' => new List<Object>(),
            'owners' => new List<Object>(),
            'tpas' => new List<Object>()
        };

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveContactSection(
                opp.Id,
                contactSectionData
            );
        Test.stopTest();

        // Assert
        System.assertEquals(
            true,
            result.isSuccess,
            'The contact section save should succeed with a minimal structured payload.'
        );
        System.assertNotEquals(null, result.message, 'A success message should be returned.');
    }

    @IsTest
    static void test_savePaymentInformation_happyPath_minimalStructuredPayload() {
        // Arrange
        Opportunity opp = getTestOpportunity();

        Map<String, Object> paymentData = new Map<String, Object>{
            'paymentMethod' => 'Credit Card',
            'accountHolder' => buildSimpleContactPayload('Account', 'Holder', 'account.holder@test.com'),
            'billingContact' => buildSimpleContactPayload('Billing', 'Contact', 'billing.contact@test.com'),
            'billingAddress' => buildBillingAddressPayload(),
            'cardHolderName' => 'Test Card Holder',
            'cardType' => 'Visa',
            'cardNumber' => '4111111111111111',
            'expirationMonth' => '12',
            'expirationYear' => String.valueOf(Date.today().year() + 2),
            'securityCode' => '123'
        };

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.savePaymentInformation(
                opp.Id,
                null, 
                paymentData
            );
        Test.stopTest();

        // Assert
        System.assertEquals(
            true,
            result.isSuccess,
            'The payment information save should succeed with a minimal structured payload.'
        );
        System.assertNotEquals(null, result.message, 'A success message should be returned.');
    }
    @IsTest
    static void test_saveOwnership_withOwnerPayload_returnsResponse() {
        // Arrange
        Opportunity opp = getTestOpportunity();
        List<Object> ownersData = new List<Object>{
            buildOwnerPayload('Owner', 'Payload', 'owner.payload@test.com', 25)
        };

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveOwnership(
                opp.Id,
                ownersData,
                new List<Id>()
            );
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'The method should return a response for a populated owner payload.');
        System.assertNotEquals(null, result.message, 'The method should return a message for a populated owner payload.');
    }

    @IsTest
    static void test_saveContactSection_happyPath_withPopulatedLists() {
        // Arrange
        Opportunity opp = getTestOpportunity();
        Map<String, Object> contactSectionData = buildRichContactSectionPayload();

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveContactSection(
                opp.Id,
                contactSectionData
            );
        Test.stopTest();

        // Assert
        System.assertEquals(
            true,
            result.isSuccess,
            'The contact section save should succeed with populated contact lists. Message: ' + result.message + ' | ErrorType: ' + result.errorType
        );
        System.assertNotEquals(null, result.message, 'A success message should be returned.');
    }

    @IsTest
    static void test_savePaymentInformation_happyPath_withExistingContacts() {
        // Arrange
        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity();
        Contact accountHolder = createContact(acc, 'Existing', 'Holder', 'existing.holder@test.com');
        Contact billingContact = createContact(acc, 'Existing', 'Billing', 'existing.billing@test.com');

        Map<String, Object> paymentData = new Map<String, Object>{
            'paymentMethod' => 'Credit Card',
            'accountHolder' => new Map<String, Object>{
                'id' => accountHolder.Id,
                'firstName' => accountHolder.FirstName,
                'lastName' => accountHolder.LastName,
                'email' => accountHolder.Email,
                'phone' => '5551234567'
            },
            'billingContact' => new Map<String, Object>{
                'id' => billingContact.Id,
                'firstName' => billingContact.FirstName,
                'lastName' => billingContact.LastName,
                'email' => billingContact.Email,
                'phone' => '5551234567'
            },
            'billingAddress' => buildBillingAddressPayload(),
            'cardHolderName' => 'Existing Card Holder',
            'cardType' => 'Visa',
            'cardNumber' => '4111111111111111',
            'expirationMonth' => '12',
            'expirationYear' => String.valueOf(Date.today().year() + 2),
            'securityCode' => '123'
        };

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.savePaymentInformation(
                opp.Id,
                null,
                paymentData
            );
        Test.stopTest();

        // Assert
        System.assertEquals(
            true,
            result.isSuccess,
            'The payment information save should succeed with existing contacts. Message: ' + result.message + ' | ErrorType: ' + result.errorType
        );
        System.assertNotEquals(null, result.message, 'A success message should be returned.');
    }

    @IsTest
    static void test_savePaymentInformation_happyPath_bankAccount() {
        // Arrange
        Opportunity opp = getTestOpportunity();
        Map<String, Object> paymentData = buildBankPaymentPayload();

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.savePaymentInformation(
                opp.Id,
                null,
                paymentData
            );
        Test.stopTest();

        // Assert
        System.assertEquals(
            true,
            result.isSuccess,
            'The bank payment save should succeed with a structured bank payload. Message: ' + result.message + ' | ErrorType: ' + result.errorType
        );
        System.assertNotEquals(null, result.message, 'A success message should be returned.');
    }
    @IsTest
    static void test_updateFormCompletion_success() {
        // Arrange
        Opportunity opp = getTestOpportunity();

        // Act
        Test.startTest();
        ARC_BusinessFormController.updateFormCompletion(
            opp.Id,
            true
        );
        Test.stopTest();

        // Assert
        Opportunity updatedOpp = [
            SELECT Id, ARC_SalesFormCompleted__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        System.assertEquals(true, updatedOpp.ARC_SalesFormCompleted__c, 'The form completion flag should be updated.');
    }

    @IsTest
    static void test_updateFormCompletion_failure_withNullOpportunity() {
        // Act + Assert
        Test.startTest();
        try {
            ARC_BusinessFormController.updateFormCompletion(
                null,
                true
            );
            System.assert(false, 'An exception was expected when the Opportunity Id is null.');
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage(), 'The exception should include a message.');
        }
        Test.stopTest();
    }


    @IsTest
    static void test_saveContactSection_happyPath_replaceExistingPrimaryContact() {
        // Arrange
        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity();
        Contact existingPrimary = createContact(acc, 'Existing', 'Primary', 'existing.primary@test.com');
        Contact replacementPrimary = createContact(acc, 'Replacement', 'Primary', 'replacement.primary@test.com');
        Contact officer = createContact(acc, 'Existing', 'Officer', 'existing.officer@test.com');

        Map<String, Object> initialPayload = new Map<String, Object>{
            'primaryContact' => buildExistingContactPayload(existingPrimary),
            'officerContact' => buildExistingContactPayload(officer),
            'otherContacts' => new List<Object>(),
            'owners' => new List<Object>(),
            'tpas' => new List<Object>()
        };

        ARC_BusinessFormController.SaveResult initialResult =
            ARC_BusinessFormController.saveContactSection(
                opp.Id,
                initialPayload
            );

        System.assertNotEquals(null, initialResult, 'The initial contact section save should return a response.');

        Map<String, Object> replacementPayload = new Map<String, Object>{
            'primaryContact' => buildExistingContactPayload(replacementPrimary),
            'officerContact' => buildExistingContactPayload(officer),
            'otherContacts' => new List<Object>(),
            'owners' => new List<Object>(),
            'tpas' => new List<Object>()
        };

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveContactSection(
                opp.Id,
                replacementPayload
            );
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'The replacement contact section save should return a response.');
        System.assertNotEquals(null, result.message, 'The replacement contact section save should return a message.');
    }
    @IsTest
    static void test_saveContactSection_nestedPayload_distinctRoles_returnsResponse() {
        // Arrange
        Opportunity opp = getTestOpportunity();
        Map<String, Object> contactSectionData = buildExactNestedContactSectionPayloadDistinctRoles();

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveContactSection(
                opp.Id,
                contactSectionData
            );
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'The nested saveContactSection call should return a response.');
        System.assertNotEquals(null, result.message, 'The nested saveContactSection call should return a message.');
    }

    @IsTest
    static void test_saveContactSection_nestedPayload_sameAsFlags_returnsResponse() {
        // Arrange
        Opportunity opp = getTestOpportunity();
        Map<String, Object> contactSectionData = buildExactNestedContactSectionPayloadSameAsFlags();

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveContactSection(
                opp.Id,
                contactSectionData
            );
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'The same-as nested saveContactSection call should return a response.');
        System.assertNotEquals(null, result.message, 'The same-as nested saveContactSection call should return a message.');
    }

    @IsTest
    static void test_saveContactSection_nestedPayload_replaceExistingPrimary_returnsResponse() {
        // Arrange
        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity();
        Contact existingPrimary = createContact(acc, 'Nested', 'ExistingPrimary', 'nested.existing.primary@test.com');
        Contact replacementPrimary = createContact(acc, 'Nested', 'ReplacementPrimary', 'nested.replacement.primary@test.com');
        Contact officer = createContact(acc, 'Nested', 'ExistingOfficer', 'nested.existing.officer@test.com');

        Map<String, Object> initialPayload = new Map<String, Object>{
            'primaryContact' => new Map<String, Object>{
                'contactData' => buildNestedExistingContactData(existingPrimary)
            },
            'officerContact' => new Map<String, Object>{
                'sameAsPrimary' => false,
                'contactData' => buildNestedExistingContactData(officer)
            },
            'otherContacts' => new List<Object>(),
            'accountHolderContact' => new Map<String, Object>{
                'sameAsPrimary' => true
            },
            'billingContact' => new Map<String, Object>{
                'sameAsAccountHolder' => true
            },
            'ownershipContacts' => new List<Object>(),
            'ownershipContactsToRemoveRole' => new List<Object>(),
            'tpas' => new List<Object>(),
            'otherContactsToDelete' => new List<Object>(),
            'tpasToDelete' => new List<Object>()
        };

        ARC_BusinessFormController.SaveResult initialResult =
            ARC_BusinessFormController.saveContactSection(
                opp.Id,
                initialPayload
            );
        System.assertNotEquals(null, initialResult, 'The initial nested saveContactSection call should return a response.');

        Map<String, Object> replacementPayload = new Map<String, Object>{
            'primaryContact' => new Map<String, Object>{
                'contactData' => buildNestedExistingContactData(replacementPrimary)
            },
            'officerContact' => new Map<String, Object>{
                'sameAsPrimary' => false,
                'contactData' => buildNestedExistingContactData(officer)
            },
            'otherContacts' => new List<Object>(),
            'accountHolderContact' => new Map<String, Object>{
                'sameAsPrimary' => true
            },
            'billingContact' => new Map<String, Object>{
                'sameAsAccountHolder' => true
            },
            'ownershipContacts' => new List<Object>(),
            'ownershipContactsToRemoveRole' => new List<Object>(),
            'tpas' => new List<Object>(),
            'otherContactsToDelete' => new List<Object>(),
            'tpasToDelete' => new List<Object>()
        };

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveContactSection(
                opp.Id,
                replacementPayload
            );
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'The replacement nested saveContactSection call should return a response.');
        System.assertNotEquals(null, result.message, 'The replacement nested saveContactSection call should return a message.');
    }
    @IsTest
    static void test_savePaymentInformation_sameAsPrimary_and_sameAsAccountHolder_returnsResponse() {
        // Arrange
        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity();
        Contact primaryContact = createContact(acc, 'Primary', 'ExistingPayment', 'primary.existing.payment@test.com');
        setExistingAcrRoles(acc, primaryContact, 'Primary Business Contact');

        Map<String, Object> paymentData = new Map<String, Object>{
            'paymentMethod' => 'Credit Card',
            'accountHolder' => new Map<String, Object>{
                'sameAsPrimary' => true
            },
            'billingContact' => new Map<String, Object>{
                'sameAsAccountHolder' => true
            },
            'billingAddress' => buildBillingAddressPayload(),
            'cardHolderName' => 'Shared Card Holder',
            'cardType' => 'Visa',
            'cardNumber' => '4111111111111111',
            'expirationMonth' => '12',
            'expirationYear' => String.valueOf(Date.today().year() + 2),
            'securityCode' => '123'
        };

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.savePaymentInformation(
                opp.Id,
                null,
                paymentData
            );
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'The same-as payment save should return a response.');
        System.assertNotEquals(null, result.message, 'The same-as payment save should return a message.');
    }

    @IsTest
    static void test_savePaymentInformation_existingDistinctContacts_returnsResponse() {
        // Arrange
        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity();
        Contact accountHolder = createContact(acc, 'Existing', 'DistinctHolder', 'existing.distinct.holder@test.com');
        Contact billingContact = createContact(acc, 'Existing', 'DistinctBilling', 'existing.distinct.billing@test.com');
        setExistingAcrRoles(acc, accountHolder, 'Account Holder');
        setExistingAcrRoles(acc, billingContact, 'Billing Contact');

        Map<String, Object> paymentData = new Map<String, Object>{
            'paymentMethod' => 'Credit Card',
            'accountHolder' => new Map<String, Object>{
                'sameAsPrimary' => false,
                'contactId' => accountHolder.Id,
                'data' => buildSimpleContactPayload(accountHolder.FirstName, accountHolder.LastName, accountHolder.Email)
            },
            'billingContact' => new Map<String, Object>{
                'sameAsAccountHolder' => false,
                'contactId' => billingContact.Id,
                'data' => buildSimpleContactPayload(billingContact.FirstName, billingContact.LastName, billingContact.Email)
            },
            'billingAddress' => buildBillingAddressPayload(),
            'cardHolderName' => 'Distinct Card Holder',
            'cardType' => 'Visa',
            'cardNumber' => '4111111111111111',
            'expirationMonth' => '12',
            'expirationYear' => String.valueOf(Date.today().year() + 2),
            'securityCode' => '123'
        };

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.savePaymentInformation(
                opp.Id,
                null,
                paymentData
            );
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'The distinct existing contact payment save should return a response.');
        System.assertNotEquals(null, result.message, 'The distinct existing contact payment save should return a message.');
    }

    @IsTest
    static void test_savePaymentInformation_existingSameContactDedup_returnsResponse() {
        // Arrange
        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity();
        Contact sharedContact = createContact(acc, 'Existing', 'SharedPayment', 'existing.shared.payment@test.com');
        setExistingAcrRoles(acc, sharedContact, 'Account Holder;Billing Contact');

        Map<String, Object> paymentData = new Map<String, Object>{
            'paymentMethod' => 'Credit Card',
            'accountHolder' => new Map<String, Object>{
                'sameAsPrimary' => false,
                'contactId' => sharedContact.Id,
                'data' => buildSimpleContactPayload(sharedContact.FirstName, sharedContact.LastName, sharedContact.Email)
            },
            'billingContact' => new Map<String, Object>{
                'sameAsAccountHolder' => false,
                'contactId' => sharedContact.Id,
                'data' => buildSimpleContactPayload(sharedContact.FirstName, sharedContact.LastName, sharedContact.Email)
            },
            'billingAddress' => buildBillingAddressPayload(),
            'cardHolderName' => 'Shared Existing Holder',
            'cardType' => 'Visa',
            'cardNumber' => '4111111111111111',
            'expirationMonth' => '12',
            'expirationYear' => String.valueOf(Date.today().year() + 2),
            'securityCode' => '123'
        };

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.savePaymentInformation(
                opp.Id,
                null,
                paymentData
            );
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'The shared existing contact payment save should return a response.');
        System.assertNotEquals(null, result.message, 'The shared existing contact payment save should return a message.');
    }
    @IsTest
    static void test_saveAffiliatedEntities_happyPath_insertWithExactStringPayload() {
        // Arrange
        Opportunity opp = getTestOpportunity();
        Account parentAccount = getTestAccount();

        List<Map<String, Object>> entities = new List<Map<String, Object>>{
            new Map<String, Object>{
                'legalName' => 'Affiliate One LLC',
                'federalTaxId' => '98-7654321',
                'numberOfEmployees' => 25
            },
            new Map<String, Object>{
                'legalName' => 'Affiliate Two LLC',
                'federalTaxId' => '98-7654322',
                'numberOfEmployees' => null
            }
        };
        String entitiesData = buildAffiliatedEntitiesJson(entities);

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveAffiliatedEntities(
                opp.Id,
                entitiesData
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.isSuccess, 'The affiliated entities save should succeed with the exact JSON string payload.');
        System.assertNotEquals(null, result.message, 'A success message should be returned.');

        List<Account> affiliatedAccounts = [
            SELECT Id, Name, ParentId, ARC_FederalEmployerTaxIDNumber__c, ARC_Number_Of_Employees__c
            FROM Account
            WHERE ParentId = :parentAccount.Id
            ORDER BY Name
        ];
        System.assertEquals(2, affiliatedAccounts.size(), 'Two affiliated entities should be inserted.');
        System.assertEquals('Affiliate One LLC', affiliatedAccounts[0].Name, 'The first affiliated entity should be inserted.');
        System.assertEquals('Affiliate Two LLC', affiliatedAccounts[1].Name, 'The second affiliated entity should be inserted.');

        Opportunity updatedOpp = [
            SELECT Id, ARC_SFAffiliatedComplete__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        System.assertEquals(true, updatedOpp.ARC_SFAffiliatedComplete__c, 'The affiliated entities completion flag should be updated.');
    }

    @IsTest
    static void test_saveAffiliatedEntities_happyPath_deletesMissingExistingEntities() {
        // Arrange
        Opportunity opp = getTestOpportunity();
        Account parentAccount = getTestAccount();
        Id businessRtId = getBusinessAccountRecordTypeId();

        Account oldAffiliateOne = new Account(
            Name = 'Old Affiliate One',
            ParentId = parentAccount.Id,
            RecordTypeId = businessRtId
        );
        Account oldAffiliateTwo = new Account(
            Name = 'Old Affiliate Two',
            ParentId = parentAccount.Id,
            RecordTypeId = businessRtId
        );
        insert new List<Account>{ oldAffiliateOne, oldAffiliateTwo };

        List<Map<String, Object>> entities = new List<Map<String, Object>>{
            new Map<String, Object>{
                'legalName' => 'Replacement Affiliate',
                'federalTaxId' => '98-7654399',
                'numberOfEmployees' => 12
            }
        };
        String entitiesData = buildAffiliatedEntitiesJson(entities);

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveAffiliatedEntities(
                opp.Id,
                entitiesData
            );
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.isSuccess, 'The affiliated entities save should succeed when deleting missing existing entities.');
        System.assertNotEquals(null, result.message, 'A success message should be returned.');

        Integer remainingOldEntities = [
            SELECT COUNT()
            FROM Account
            WHERE Id IN :new List<Id>{ oldAffiliateOne.Id, oldAffiliateTwo.Id }
        ];
        System.assertEquals(0, remainingOldEntities, 'Old affiliated entities should be deleted when they are not included in the payload.');

        List<Account> currentAffiliates = [
            SELECT Id, Name
            FROM Account
            WHERE ParentId = :parentAccount.Id
        ];
        System.assertEquals(1, currentAffiliates.size(), 'Only the replacement affiliated entity should remain.');
        System.assertEquals('Replacement Affiliate', currentAffiliates[0].Name, 'The new affiliated entity should remain after delete processing.');
    }

    @IsTest
    static void test_saveAffiliatedEntities_failure_withNullOpportunity() {
        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveAffiliatedEntities(
                null,
                '[]'
            );
        Test.stopTest();

        // Assert
        assertFailureResult(result, 'The affiliated entities save should fail when the Opportunity Id is null');
    }
    @IsTest
    static void test_saveContactSection_exactMegaPayload_returnsResponse() {
        // Arrange
        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity();
        Contact primaryContact = createContact(acc, 'Mega', 'Primary', 'mega.primary@test.com');
        Contact accountHolderContact = createContact(acc, 'Mega', 'AccountHolder', 'mega.accountholder@test.com');
        Contact billingContact = createContact(acc, 'Mega', 'Billing', 'mega.billing@test.com');
        setExistingAcrRoles(acc, primaryContact, 'Primary Business Contact');

        Map<String, Object> contactSectionData = buildExactSaveContactSectionMegaPayload(
            primaryContact,
            accountHolderContact,
            billingContact
        );

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveContactSection(
                opp.Id,
                contactSectionData
            );
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'The mega saveContactSection call should return a response.');
        System.assertNotEquals(null, result.message, 'The mega saveContactSection call should return a message.');
    }

    @IsTest
    static void test_saveContactSection_exactFallbackPayload_returnsResponse() {
        // Arrange
        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity();
        Contact existingPrimary = createContact(acc, 'Fallback', 'Primary', 'fallback.primary@test.com');
        setExistingAcrRoles(acc, existingPrimary, 'Primary Business Contact');

        Map<String, Object> contactSectionData = buildExactSaveContactSectionFallbackPayload();

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveContactSection(
                opp.Id,
                contactSectionData
            );
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'The fallback saveContactSection call should return a response.');
        System.assertNotEquals(null, result.message, 'The fallback saveContactSection call should return a message.');
    }

    @IsTest
    static void test_saveContactSection_exactDeletePayload_returnsResponse() {
        // Arrange
        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity();

        Contact existingPrimary = createContact(acc, 'Delete', 'Primary', 'delete.primary@test.com');
        Contact otherContact = createContact(acc, 'Delete', 'Other', 'delete.other@test.com');
        Contact ownershipContact = createContact(acc, 'Delete', 'Owner', 'delete.owner@test.com');
        setExistingAcrRoles(acc, existingPrimary, 'Primary Business Contact');
        setExistingAcrRoles(acc, ownershipContact, 'Ownership');

        Id businessRtId = getBusinessAccountRecordTypeId();
        Account tpaAccount = new Account(
            Name = 'Delete TPA Account',
            ParentId = acc.Id,
            RecordTypeId = businessRtId
        );
        insert tpaAccount;

        Contact tpaContact = new Contact(
            FirstName = 'Delete',
            LastName = 'TPA',
            Email = 'delete.tpa@test.com',
            AccountId = tpaAccount.Id
        );
        insert tpaContact;

        Map<String, Object> contactSectionData = buildExactSaveContactSectionDeletePayload(
            otherContact.Id,
            ownershipContact.Id,
            tpaAccount.Id,
            tpaContact.Id
        );

        // Act
        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveContactSection(
                opp.Id,
                contactSectionData
            );
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'The delete saveContactSection call should return a response.');
        System.assertNotEquals(null, result.message, 'The delete saveContactSection call should return a message.');
    }

    // ─── v10: targeted coverage for missing branches ──────────────────────────

    /**
     * Covers saveOwnership's upsert-contacts block.
     * The existing test only weakly asserts result != null; this one asserts
     * isSuccess = true so the upsert lines are confirmed to execute.
     */
    @IsTest
    static void test_saveOwnership_newContact_coversUpsertBlock() {
        Opportunity opp = getTestOpportunity();

        Map<String, Object> ownerData = new Map<String, Object>{
            'firstName'           => 'Covered',
            'lastName'            => 'Owner',
            'email'               => 'covered.owner@test.com',
            'phone'               => '5551234567',
            'title'               => 'CEO',
            'ownershipPercentage' => 51,
            'isEligible'          => true
        };

        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveOwnership(
                opp.Id,
                new List<Object>{ ownerData },
                new List<Id>()
            );
        Test.stopTest();

        System.assertEquals(true, result.isSuccess,
            'saveOwnership with a valid new owner should succeed. Msg: ' + result.message);
    }

    /**
     * Covers populateChargentOrderFields — 'bank' branch.
     * The controller reads paymentData.get('method') (value 'bank'), NOT 'paymentMethod'.
     * Existing tests all used the wrong key and never entered either branch.
     */
    @IsTest
    static void test_savePaymentInformation_methodBank_coversChargentFields() {
        Opportunity opp = getTestOpportunity();

        Map<String, Object> paymentData = new Map<String, Object>{
            'method'         => 'bank',
            'data'           => new Map<String, Object>{
                'financialInstitutionName' => 'First National Bank',
                'routingNumber'            => '021000021',
                'accountNumber'            => '9876543210'
            },
            'billingAddress' => new Map<String, Object>{
                'street'  => '1 Bank St',
                'city'    => 'Dallas',
                'state'   => 'TX',
                'zipCode' => '75201'
            }
        };

        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.savePaymentInformation(opp.Id, null, paymentData);
        Test.stopTest();

        System.assertEquals(true, result.isSuccess,
            'savePaymentInformation bank branch should succeed. Msg: ' + result.message);
    }

    /**
     * Covers populateChargentOrderFields — 'card' branch.
     * Uses 'method' => 'card' with a nested 'data' map containing card fields.
     */
    @IsTest
    static void test_savePaymentInformation_methodCard_coversChargentFields() {
        Opportunity opp = getTestOpportunity();

        Map<String, Object> paymentData = new Map<String, Object>{
            'method'         => 'card',
            'data'           => new Map<String, Object>{
                'cardNumber'      => '4111111111111111',
                'expirationMonth' => '12',
                'expirationYear'  => '2027'
            },
            'billingAddress' => new Map<String, Object>{
                'street'  => '1 Card Ave',
                'city'    => 'Dallas',
                'state'   => 'TX',
                'zipCode' => '75202'
            }
        };

        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.savePaymentInformation(opp.Id, null, paymentData);
        Test.stopTest();

        System.assertEquals(true, result.isSuccess,
            'savePaymentInformation card branch should succeed. Msg: ' + result.message);
    }

    /**
     * Covers prepareContactRoleUpdate — update-existing-ACR path.
     * Passes an existing contact (already related to the account, so it has an ACR)
     * as an ownershipContact.  The ownershipAcrsMap finds the ACR and routes to
     * acrsToUpdate instead of acrsToInsert.
     * NOTE: ownershipContacts.contact map must use API-name-cased keys ('FirstName',
     * 'LastName', 'Email') because the controller normalizes via those exact keys.
     */
    @IsTest
    static void test_saveContactSection_prepareContactRoleUpdate_updateExistingACR() {
        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity();

        Contact existingOwner = createContact(acc, 'RoleUpd', 'Owner', 'roleupd.owner@test.com');

        Map<String, Object> contactSectionData = new Map<String, Object>{
            'otherContacts'                 => new List<Object>(),
            'accountHolderContact'          => new Map<String, Object>{ 'sameAsPrimary' => true },
            'billingContact'                => new Map<String, Object>{ 'sameAsAccountHolder' => true },
            'ownershipContacts'             => new List<Object>{
                new Map<String, Object>{
                    'contact' => new Map<String, Object>{
                        'Id'                         => existingOwner.Id,
                        'FirstName'                  => existingOwner.FirstName,
                        'LastName'                   => existingOwner.LastName,
                        'Email'                      => existingOwner.Email,
                        'Phone'                      => '5551234567',
                        'ARC_OwnershipPercentage__c' => 30,
                        'ARC_Eligible__c'            => true
                    }
                }
            },
            'ownershipContactsToRemoveRole' => new List<Object>(),
            'tpas'                          => new List<Object>(),
            'otherContactsToDelete'         => new List<Object>(),
            'tpasToDelete'                  => new List<Object>()
        };

        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveContactSection(opp.Id, contactSectionData);
        Test.stopTest();

        System.assertEquals(true, result.isSuccess,
            'saveContactSection with existing-ACR ownership contact should succeed. Msg: ' + result.message);
    }

    /**
     * Covers prepareContactRoleUpdate — insert-new-ACR path.
     * A contact created under a DIFFERENT account has no ACR for the test account,
     * so prepareContactRoleUpdate adds a new AccountContactRelation to acrsToInsert.
     */
    @IsTest
    static void test_saveContactSection_prepareContactRoleUpdate_insertNewACR() {
        Account acc = getTestAccount();
        Opportunity opp = getTestOpportunity();

        // Contact linked to an unrelated account → no ACR for acc
        Account otherAcc = new Account(Name = 'ACR Insert Test Account');
        insert otherAcc;
        Contact unlinkedContact = new Contact(
            FirstName = 'Unlinked',
            LastName  = 'OwnerACR',
            Email     = 'unlinked.owner.acr@test.com',
            AccountId = otherAcc.Id
        );
        insert unlinkedContact;

        Map<String, Object> contactSectionData = new Map<String, Object>{
            'otherContacts'                 => new List<Object>(),
            'accountHolderContact'          => new Map<String, Object>{ 'sameAsPrimary' => true },
            'billingContact'                => new Map<String, Object>{ 'sameAsAccountHolder' => true },
            'ownershipContacts'             => new List<Object>{
                new Map<String, Object>{
                    'contact' => new Map<String, Object>{
                        'Id'                         => unlinkedContact.Id,
                        'FirstName'                  => 'Unlinked',
                        'LastName'                   => 'OwnerACR',
                        'Email'                      => 'unlinked.owner.acr@test.com',
                        'Phone'                      => '5551234567',
                        'ARC_OwnershipPercentage__c' => 25,
                        'ARC_Eligible__c'            => true
                    }
                }
            },
            'ownershipContactsToRemoveRole' => new List<Object>(),
            'tpas'                          => new List<Object>(),
            'otherContactsToDelete'         => new List<Object>(),
            'tpasToDelete'                  => new List<Object>()
        };

        Test.startTest();
        ARC_BusinessFormController.SaveResult result =
            ARC_BusinessFormController.saveContactSection(opp.Id, contactSectionData);
        Test.stopTest();

        System.assertEquals(true, result.isSuccess,
            'saveContactSection with cross-account ownership contact (new ACR) should succeed. Msg: ' + result.message);
    }
}