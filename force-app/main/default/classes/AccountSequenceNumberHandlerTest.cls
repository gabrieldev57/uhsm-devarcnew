@isTest
private class AccountSequenceNumberHandlerTest {

    @testSetup
    static void makeData() {
        // Create Product
        Product2 product = new Product2(
            Name = 'UHSM Gold',
            ProductCode = 'PROG_UHSMGold',
            vlocity_ins__Type__c = 'Medical',
            IsActive = true
        );
        insert product;

        // Create Person Accounts (Primary, Spouse, Dependent)
        Account primaryAccount = new Account(
            FirstName = 'John',
            LastName = 'Doe',
            PersonBirthdate = Date.newInstance(1980, 1, 15),
            vlocity_ins__Gender__pc = 'Male',
            ARC_SocialSecurityNumber__c = '123456789',
            BillingStreet = '123 Main St',
            BillingCity = 'Denver',
            BillingState = 'CO',
            BillingPostalCode = '80202',
            Current_Member_Id__c = 'MEM12345',
            IsActive = false  // Start inactive for testing activation
        );
        insert primaryAccount;

        Account spouseAccount = new Account(
            FirstName = 'Jane',
            LastName = 'Doe',
            PersonBirthdate = Date.newInstance(1982, 5, 20),
            vlocity_ins__Gender__pc = 'Female',
            ARC_SocialSecurityNumber__c = '987654321',
            BillingStreet = '123 Main St',
            BillingCity = 'Denver',
            BillingState = 'CO',
            BillingPostalCode = '80202',
            Current_Member_Id__c = 'MEM12345',
            IsActive = false
        );
        insert spouseAccount;

        Account dependentAccount = new Account(
            FirstName = 'Billy',
            LastName = 'Doe',
            PersonBirthdate = Date.newInstance(2010, 3, 10),
            vlocity_ins__Gender__pc = 'Male',
            ARC_SocialSecurityNumber__c = '555666777',
            BillingStreet = '123 Main St',
            BillingCity = 'Denver',
            BillingState = 'CO',
            BillingPostalCode = '80202',
            Current_Member_Id__c = 'MEM12345',
            IsActive = false
        );
        insert dependentAccount;

        // Create Contract as Draft
        Contract contract = new Contract(
            AccountId = primaryAccount.Id,
            Status = 'Draft',
            ARC_EffectiveDate__c = Date.today().addMonths(-1)
        );
        insert contract;

        // Create Recurring Monthly Order (required for activation)
        ChargentOrders__ChargentOrder__c recurringOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = contract.Id,
            ChargentOrders__Description__c = 'Recurring Monthly Order',
            ChargentOrders__Shipping__c = 0,
            ChargentOrders__Tax__c = 0,
            ChargentOrders__Charge_Amount__c = 100,
            ChargentOrders__Subtotal__c = 100,
            ChargentOrders__Charge_Date__c = '01',
            ChargentOrders__Next_Transaction_Date__c = System.today().addDays(30),
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Start_Date__c = Date.today(),
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Last_4__c = '1234',
            ChargentOrders__Card_Type__c = 'VISA',
            ChargentOrders__Card_Expiration_Month__c = '12',
            ChargentOrders__Card_Expiration_Year__c = '2030',
            ChargentOrders__Tokenization__c = 'test12345'
        );
        insert recurringOrder;

        // Link order to contract and activate
        contract.ARC_RecurringMonthlyOrder__c = recurringOrder.Id;
        contract.Status = 'Activated';
        update contract;

        // Create InsurancePolicy
        InsurancePolicy policy = new InsurancePolicy(
            Name = 'POL-12345',
            ARC_Contract__c = contract.Id,
            NameInsuredId = primaryAccount.Id
        );
        insert policy;

        // Create InsurancePolicyCoverage
        InsurancePolicyCoverage coverage = new InsurancePolicyCoverage(
            InsurancePolicyId = policy.Id,
            vlocity_ins_fsc__Product2Id__c = product.Id,
            CoverageName = 'Medical'
        );
        insert coverage;

        // Get Contacts created by Person Account triggers
        Contact primaryContact = [SELECT Id FROM Contact WHERE AccountId = :primaryAccount.Id LIMIT 1];
        Contact spouseContact = [SELECT Id FROM Contact WHERE AccountId = :spouseAccount.Id LIMIT 1];
        Contact dependentContact = [SELECT Id FROM Contact WHERE AccountId = :dependentAccount.Id LIMIT 1];

        // Create InsurancePolicyParticipants
        List<InsurancePolicyParticipant> participants = new List<InsurancePolicyParticipant>{
            new InsurancePolicyParticipant(
                InsurancePolicyId = policy.Id,
                Role = 'Primary',
                PrimaryParticipantContactId = primaryContact.Id,
                ARC_StartDate__c = Date.today().addMonths(-1),
                ARC_EndDate__c = null
            ),
            new InsurancePolicyParticipant(
                InsurancePolicyId = policy.Id,
                Role = 'Spouse',
                PrimaryParticipantContactId = spouseContact.Id,
                ARC_StartDate__c = Date.today().addMonths(-1),
                ARC_EndDate__c = null
            ),
            new InsurancePolicyParticipant(
                InsurancePolicyId = policy.Id,
                Role = 'Dependent',
                PrimaryParticipantContactId = dependentContact.Id,
                ARC_StartDate__c = Date.today().addMonths(-1),
                ARC_EndDate__c = null
            )
        };
        insert participants;

        // Create ARC_CoverageParticipant__c records
        List<ARC_CoverageParticipant__c> coverageParticipants = new List<ARC_CoverageParticipant__c>{
            new ARC_CoverageParticipant__c(
                ARC_Policy__c = policy.Id,
                ARC_PolicyCoverage__c = coverage.Id,
                ARC_PolicyParticipant__c = participants[0].Id,
                ARC_CoverageRole__c = 'Primary'
            ),
            new ARC_CoverageParticipant__c(
                ARC_Policy__c = policy.Id,
                ARC_PolicyCoverage__c = coverage.Id,
                ARC_PolicyParticipant__c = participants[1].Id,
                ARC_CoverageRole__c = 'Spouse'
            ),
            new ARC_CoverageParticipant__c(
                ARC_Policy__c = policy.Id,
                ARC_PolicyCoverage__c = coverage.Id,
                ARC_PolicyParticipant__c = participants[2].Id,
                ARC_CoverageRole__c = 'Dependent'
            )
        };
        insert coverageParticipants;
    }

    @isTest
    static void testSequenceAssignmentOnActivation() {
        // Get test accounts
        Account primaryAccount = [SELECT Id, ARC_HAXFamilySequenceNumber__c, Current_Member_Id__c
                                  FROM Account
                                  WHERE FirstName = 'John' LIMIT 1];
        Account spouseAccount = [SELECT Id, ARC_HAXFamilySequenceNumber__c, Current_Member_Id__c
                                 FROM Account
                                 WHERE FirstName = 'Jane' LIMIT 1];
        Account dependentAccount = [SELECT Id, ARC_HAXFamilySequenceNumber__c, Current_Member_Id__c
                                    FROM Account
                                    WHERE FirstName = 'Billy' LIMIT 1];

        // Verify no sequences assigned yet
        System.assertEquals(null, primaryAccount.ARC_HAXFamilySequenceNumber__c, 'Primary should not have sequence yet');
        System.assertEquals(null, spouseAccount.ARC_HAXFamilySequenceNumber__c, 'Spouse should not have sequence yet');
        System.assertEquals(null, dependentAccount.ARC_HAXFamilySequenceNumber__c, 'Dependent should not have sequence yet');

        Test.startTest();

        // Activate all accounts - should trigger sequence assignment
        primaryAccount.IsActive = true;
        spouseAccount.IsActive = true;
        dependentAccount.IsActive = true;

        update new List<Account>{ primaryAccount, spouseAccount, dependentAccount };

        Test.stopTest();

        // Query updated accounts
        primaryAccount = [SELECT Id, ARC_HAXFamilySequenceNumber__c FROM Account WHERE Id = :primaryAccount.Id];
        spouseAccount = [SELECT Id, ARC_HAXFamilySequenceNumber__c FROM Account WHERE Id = :spouseAccount.Id];
        dependentAccount = [SELECT Id, ARC_HAXFamilySequenceNumber__c FROM Account WHERE Id = :dependentAccount.Id];

        // Verify sequences assigned correctly
        System.assertEquals(1, primaryAccount.ARC_HAXFamilySequenceNumber__c, 'Primary should be sequence 1');
        System.assertEquals(2, spouseAccount.ARC_HAXFamilySequenceNumber__c, 'Spouse should be sequence 2');
        System.assertEquals(3, dependentAccount.ARC_HAXFamilySequenceNumber__c, 'Dependent should be sequence 3');
    }

    @isTest
    static void testSequenceClearedOnMemberIdChange() {
        // Get test account
        Account primaryAccount = [SELECT Id, Current_Member_Id__c, IsActive,
                                         ARC_HAXFamilySequenceNumber__c
                                  FROM Account
                                  WHERE FirstName = 'John' LIMIT 1];

        Test.startTest();

        // First activation - triggers @future to assign sequence
        primaryAccount.IsActive = true;
        update primaryAccount;

        // Change Member ID - clears sequence (synchronous) and triggers @future to reassign
        primaryAccount.Current_Member_Id__c = 'NEWMEM999';
        update primaryAccount;

        Test.stopTest(); // Both @future methods execute here

        // Query updated account
        primaryAccount = [SELECT Id, ARC_HAXFamilySequenceNumber__c, Current_Member_Id__c
                         FROM Account
                         WHERE Id = :primaryAccount.Id];

        // Verify sequence was cleared and reassigned as 1 (new family)
        System.assertEquals(1, primaryAccount.ARC_HAXFamilySequenceNumber__c,
            'Should be reassigned as sequence 1 for new Member ID');
        System.assertEquals('NEWMEM999', primaryAccount.Current_Member_Id__c, 'Member ID should be updated');
    }

    @isTest
    static void testDependentSequenceIncrement() {
        // Get existing accounts
        List<Account> accounts = [SELECT Id, IsActive FROM Account];

        // Create a new dependent account with same Member ID
        Account newDependent = new Account(
            FirstName = 'Sarah',
            LastName = 'Doe',
            PersonBirthdate = Date.newInstance(2012, 8, 15),
            vlocity_ins__Gender__pc = 'Female',
            ARC_SocialSecurityNumber__c = '888999000',
            BillingStreet = '123 Main St',
            BillingCity = 'Denver',
            BillingState = 'CO',
            BillingPostalCode = '80202',
            Current_Member_Id__c = 'MEM12345',
            IsActive = false
        );
        insert newDependent;

        // Get policy and coverage
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        InsurancePolicyCoverage coverage = [SELECT Id FROM InsurancePolicyCoverage LIMIT 1];
        Contact newDependentContact = [SELECT Id FROM Contact WHERE AccountId = :newDependent.Id LIMIT 1];

        // Create participant and coverage participant
        InsurancePolicyParticipant participant = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            Role = 'Dependent',
            PrimaryParticipantContactId = newDependentContact.Id,
            ARC_StartDate__c = Date.today(),
            ARC_EndDate__c = null
        );
        insert participant;

        ARC_CoverageParticipant__c coverageParticipant = new ARC_CoverageParticipant__c(
            ARC_Policy__c = policy.Id,
            ARC_PolicyCoverage__c = coverage.Id,
            ARC_PolicyParticipant__c = participant.Id,
            ARC_CoverageRole__c = 'Dependent'
        );
        insert coverageParticipant;

        Test.startTest();

        // Activate all existing accounts to assign initial sequences (1, 2, 3)
        for (Account acc : accounts) {
            acc.IsActive = true;
        }
        update accounts;

        // Activate new dependent - should get sequence 4
        newDependent.IsActive = true;
        update newDependent;

        Test.stopTest(); // All @future methods execute here

        // Query updated account
        newDependent = [SELECT Id, ARC_HAXFamilySequenceNumber__c FROM Account WHERE Id = :newDependent.Id];

        // Should be assigned sequence 4 (after 1=Primary, 2=Spouse, 3=First Dependent)
        System.assertEquals(4, newDependent.ARC_HAXFamilySequenceNumber__c,
            'New dependent should be sequence 4');
    }

    @isTest
    static void testNoSequenceWithoutCoverage() {
        // Create account without any coverage participants
        Account orphanAccount = new Account(
            FirstName = 'Orphan',
            LastName = 'User',
            PersonBirthdate = Date.newInstance(1990, 6, 1),
            vlocity_ins__Gender__pc = 'Male',
            ARC_SocialSecurityNumber__c = '111222333',
            Current_Member_Id__c = 'MEM99999',
            IsActive = false
        );
        insert orphanAccount;

        Test.startTest();

        // Activate account - should NOT get sequence (no coverage)
        orphanAccount.IsActive = true;
        update orphanAccount;

        Test.stopTest();

        // Query updated account
        orphanAccount = [SELECT Id, ARC_HAXFamilySequenceNumber__c FROM Account WHERE Id = :orphanAccount.Id];

        // Should NOT have sequence assigned
        System.assertEquals(null, orphanAccount.ARC_HAXFamilySequenceNumber__c,
            'Account without coverage should not get sequence');
    }

    @isTest
    static void testSequenceWithInactivePolicy() {
        // Create account with inactive contract/policy
        Account testAccount = new Account(
            FirstName = 'Inactive',
            LastName = 'Test',
            PersonBirthdate = Date.newInstance(1985, 3, 15),
            vlocity_ins__Gender__pc = 'Male',
            ARC_SocialSecurityNumber__c = '999888777',
            Current_Member_Id__c = 'MEM55555',
            IsActive = false
        );
        insert testAccount;

        // Create Contract with Draft status (not Activated) - this will make ARC_isActive__c = false
        Contract inactiveContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            ARC_EffectiveDate__c = Date.today()
        );
        insert inactiveContract;

        // Create InsurancePolicy linked to inactive contract
        InsurancePolicy policy = new InsurancePolicy(
            Name = 'POL-INACTIVE',
            ARC_Contract__c = inactiveContract.Id,
            NameInsuredId = testAccount.Id
        );
        insert policy;

        // Create coverage, participant, and coverage participant
        Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'PROG_UHSMGold' LIMIT 1];
        InsurancePolicyCoverage coverage = new InsurancePolicyCoverage(
            InsurancePolicyId = policy.Id,
            vlocity_ins_fsc__Product2Id__c = product.Id,
            CoverageName = 'Medical'
        );
        insert coverage;

        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];
        InsurancePolicyParticipant participant = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            Role = 'Primary',
            PrimaryParticipantContactId = testContact.Id,
            ARC_StartDate__c = Date.today()
        );
        insert participant;

        ARC_CoverageParticipant__c coverageParticipant = new ARC_CoverageParticipant__c(
            ARC_Policy__c = policy.Id,
            ARC_PolicyCoverage__c = coverage.Id,
            ARC_PolicyParticipant__c = participant.Id,
            ARC_CoverageRole__c = 'Primary'
        );
        insert coverageParticipant;

        Test.startTest();

        // Try to activate account - should NOT get sequence (policy inactive due to Draft contract)
        testAccount.IsActive = true;
        update testAccount;

        Test.stopTest();

        // Query updated account
        testAccount = [SELECT Id, ARC_HAXFamilySequenceNumber__c FROM Account WHERE Id = :testAccount.Id];

        // Should NOT have sequence assigned (Contract is Draft, so policy is inactive)
        System.assertEquals(null, testAccount.ARC_HAXFamilySequenceNumber__c,
            'Account with inactive policy should not get sequence');
    }

    @isTest
    static void testSequenceWithNonMedicalCoverage() {
        // Create dental product
        Product2 dentalProduct = new Product2(
            Name = 'Dental Plan',
            ProductCode = 'DENTAL_BASIC',
            vlocity_ins__Type__c = 'Dental',
            IsActive = true
        );
        insert dentalProduct;

        // Create account
        Account dentalAccount = new Account(
            FirstName = 'Dental',
            LastName = 'Only',
            PersonBirthdate = Date.newInstance(1985, 4, 12),
            vlocity_ins__Gender__pc = 'Female',
            ARC_SocialSecurityNumber__c = '444555666',
            Current_Member_Id__c = 'MEM77777',
            IsActive = false
        );
        insert dentalAccount;

        // Create contract as Draft
        Contract contract = new Contract(
            AccountId = dentalAccount.Id,
            Status = 'Draft',
            ARC_EffectiveDate__c = Date.today()
        );
        insert contract;

        // Create Recurring Monthly Order (required for activation)
        ChargentOrders__ChargentOrder__c recurringOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = contract.Id,
            ChargentOrders__Description__c = 'Recurring Monthly Order',
            ChargentOrders__Shipping__c = 0,
            ChargentOrders__Tax__c = 0,
            ChargentOrders__Charge_Amount__c = 100,
            ChargentOrders__Subtotal__c = 100,
            ChargentOrders__Charge_Date__c = '01',
            ChargentOrders__Next_Transaction_Date__c = System.today().addDays(30),
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Start_Date__c = Date.today(),
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Last_4__c = '1234',
            ChargentOrders__Card_Type__c = 'VISA',
            ChargentOrders__Card_Expiration_Month__c = '12',
            ChargentOrders__Card_Expiration_Year__c = '2030',
            ChargentOrders__Tokenization__c = 'test12345'
        );
        insert recurringOrder;

        // Link order to contract and activate
        contract.ARC_RecurringMonthlyOrder__c = recurringOrder.Id;
        contract.Status = 'Activated';
        update contract;

        InsurancePolicy policy = new InsurancePolicy(
            Name = 'POL-DENTAL',
            ARC_Contract__c = contract.Id,
            NameInsuredId = dentalAccount.Id
        );
        insert policy;

        // Create dental coverage (not medical)
        InsurancePolicyCoverage dentalCoverage = new InsurancePolicyCoverage(
            InsurancePolicyId = policy.Id,
            vlocity_ins_fsc__Product2Id__c = dentalProduct.Id,
            CoverageName = 'Dental'
        );
        insert dentalCoverage;

        Contact dentalContact = [SELECT Id FROM Contact WHERE AccountId = :dentalAccount.Id LIMIT 1];

        InsurancePolicyParticipant participant = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            Role = 'Primary',
            PrimaryParticipantContactId = dentalContact.Id,
            ARC_StartDate__c = Date.today()
        );
        insert participant;

        ARC_CoverageParticipant__c coverageParticipant = new ARC_CoverageParticipant__c(
            ARC_Policy__c = policy.Id,
            ARC_PolicyCoverage__c = dentalCoverage.Id,
            ARC_PolicyParticipant__c = participant.Id,
            ARC_CoverageRole__c = 'Primary'
        );
        insert coverageParticipant;

        Test.startTest();

        // Activate account - should NOT get sequence (only dental coverage)
        dentalAccount.IsActive = true;
        update dentalAccount;

        Test.stopTest();

        // Query updated account
        dentalAccount = [SELECT Id, ARC_HAXFamilySequenceNumber__c FROM Account WHERE Id = :dentalAccount.Id];

        // Should NOT have sequence assigned (only Medical coverage qualifies)
        System.assertEquals(null, dentalAccount.ARC_HAXFamilySequenceNumber__c,
            'Account with only non-Medical coverage should not get sequence');
    }
}