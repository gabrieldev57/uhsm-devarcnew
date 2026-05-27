@isTest
private class ARC_SMBUtility_Test {
    
    /******************************************************************
     * TEST DATA SETUP
     ******************************************************************/
    
    @TestSetup
    static void setupTestData() {
        
        // Create Account (Member)
        Account testAccount = new Account(
            FirstName = 'Test',
            LastName = 'Member',
            PersonBirthdate = Date.newInstance(1990, 1, 15),
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount').getRecordTypeId()
        );
        insert testAccount;
        
        // Reload account to get PersonContactId
        testAccount = [SELECT Id, PersonContactId, PersonBirthdate 
                       FROM Account WHERE Id = :testAccount.Id];
        
        // Create Product with Product Code
        Product2 testProduct = new Product2(
            Name = 'USHM Access 10k',
            ProductCode = 'PROG_UHSM_Access10k',
            vlocity_ins__Type__c = 'Medical',
            IsActive = true
        );
        insert testProduct;
        
        // Create another product for non-USHM program
        Product2 nonUSHMProduct = new Product2(
            Name = 'Standard Plan',
            ProductCode = 'PROG_STANDARD',
            vlocity_ins__Type__c = 'Medical',
            IsActive = true
        );
        insert nonUSHMProduct;
        
        // Create Custom Metadata Mock (Note: In real tests, you'll need to use mock or actual metadata)
        // For this test, we'll assume the metadata exists

        List<ChargentOrders__ChargentOrder__c> recurringOrders = ARC_TestUtility.createChargentOrders(1);
        insert recurringOrders;
        
        // Create Contract for Individual And Family
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            StartDate = Date.newInstance(2024, 1, 1),
            ContractTerm = 12,
            ARC_EffectiveDate__c = Date.newInstance(2024, 1, 1),
            ARC_Inactive_Date__c = Date.newInstance(2024, 12, 31),
            ARC_RecurringMonthlyOrder__c = recurringOrders[0].Id,
            RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
                .get('ARC_IndividualAndFamily').getRecordTypeId()
        );
        insert testContract;

        testContract.Status = 'Awaiting Activation';
        update testContract;
        
        // Create Insurance Policy - Individual And Family
        InsurancePolicy testPolicy = new InsurancePolicy(
            Name = 'Test Policy IF',
            NameInsuredId = testAccount.Id,
            ARC_Contract__c = testContract.Id,
            RecordTypeId = Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByDeveloperName()
                .get('ARC_IndividualAndFamily').getRecordTypeId(),
            Status = 'Activated',
            EffectiveDate = Date.newInstance(2024, 1, 1),
            ExpirationDate = Date.newInstance(2024, 12, 31)
        );
        insert testPolicy;
        
        // Create Insurance Policy Participant
        InsurancePolicyParticipant testIPP = new InsurancePolicyParticipant(
            InsurancePolicyId = testPolicy.Id,
            PrimaryParticipantContactId = testAccount.PersonContactId,
            Role = 'Primary'
        );
        insert testIPP;
        
        // Create Policy Coverage
        InsurancePolicyCoverage testCoverage = new InsurancePolicyCoverage(
            InsurancePolicyId = testPolicy.Id,
            vlocity_ins_fsc__Product2Id__c = testProduct.Id
        );
        insert testCoverage;

        ARC_CoverageParticipant__c covParticipant = new ARC_CoverageParticipant__c(
            ARC_PolicyCoverage__c = testCoverage.Id,
            ARC_PolicyParticipant__c = testIPP.Id
        );
        insert covParticipant;
    }
    
    /******************************************************************
     * HELPER METHODS
     ******************************************************************/
    
    // Helper method to create additional policies for testing
    private static InsurancePolicy createAdditionalPolicy(
        Id accountId, 
        Id contactId,
        String recordTypeName,
        String productCode,
        Id contractId
    ) {
        Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = :productCode LIMIT 1];

        String resolvedRecordTypeName = recordTypeName;
        if (recordTypeName == 'Individual_And_Family') {
            resolvedRecordTypeName = 'ARC_IndividualAndFamily';
        }
        if (recordTypeName == 'Small_Group') {
            resolvedRecordTypeName = 'ARC_SmallGroup';
        }
        
        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Additional Policy ',
            NameInsuredId = accountId,
            RecordTypeId = Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByDeveloperName()
                .get(resolvedRecordTypeName).getRecordTypeId(),
            Status = 'Activated',
            EffectiveDate = Date.newInstance(2025, 1, 1),
            ExpirationDate = Date.newInstance(2025, 12, 31)
        );
        
        if (contractId != null) {
            policy.ARC_Contract__c = contractId;
        }
        
        insert policy;
        
        // Create IPP
        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            PrimaryParticipantContactId = contactId,
            Role = 'Primary'
        );
        insert ipp;
        
        // Create Coverage
        InsurancePolicyCoverage coverage = new InsurancePolicyCoverage(
            InsurancePolicyId = policy.Id,
            vlocity_ins_fsc__Product2Id__c = product.Id
        );
        insert coverage;
        
        // Create Coverage Participant
        ARC_CoverageParticipant__c covPart = new ARC_CoverageParticipant__c(
            ARC_PolicyCoverage__c = coverage.Id,
            ARC_PolicyParticipant__c = ipp.Id
        );
        insert covPart;
        
        return policy;
    }
    
    // Helper to create contract
    private static Contract createContract(
        Id accountId, 
        Date effectiveDate, 
        Date inactiveDate,
        String status
    ) {
        List<ChargentOrders__ChargentOrder__c> recurringOrders = ARC_TestUtility.createChargentOrders(1);
        insert recurringOrders;

        Contract contract = new Contract(
            AccountId = accountId,
            Status = 'Draft',
            StartDate = effectiveDate,
            ContractTerm = 12,
            ARC_EffectiveDate__c = effectiveDate,
            ARC_Inactive_Date__c = inactiveDate,
            ARC_RecurringMonthlyOrder__c = recurringOrders[0].Id,
            RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
                .get('ARC_IndividualAndFamily').getRecordTypeId()
        );
        insert contract;

        contract.Status = status == 'Draft' ? 'Awaiting Activation' : status;
        update contract;

        return contract;
    }
    
    /******************************************************************
     * TEST METHODS - mapCoveragePeriods
     ******************************************************************/
    
    @isTest
    static void testMapCoveragePeriods_SinglePeriod_USHM() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Id> accountIds = new List<Id>{acc.Id};
        
        // When
        Test.startTest();
        Map<Id, List<Map<String,Object>>> result = 
            ARC_SMBUtility.mapCoveragePeriods(accountIds, 'MAT__c');
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey(acc.Id), 'Result should contain account ID');
        System.assertNotEquals(0, result.get(acc.Id).size(), 'Should have at least one period');
    }
    
    @isTest
    static void testMapCoveragePeriods_MultipleContinuousPeriods() {
        // Given
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        
        // Create continuous periods
        createAdditionalPolicy(
            acc.Id, 
            acc.PersonContactId,
            'Individual_And_Family',
            'PROG_UHSM_Access10k',
            contract.Id
        );
        
        List<Id> accountIds = new List<Id>{acc.Id};
        
        // When
        Test.startTest();
        Map<Id, List<Map<String,Object>>> result = 
            ARC_SMBUtility.mapCoveragePeriods(accountIds, 'PREEX__c');
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey(acc.Id), 'Result should contain account ID');
        List<Map<String,Object>> periods = result.get(acc.Id);
        System.assertNotEquals(0, periods.size(), 'Should have merged periods');
    }
    
    @isTest
    static void testMapCoveragePeriods_GapInCoverage() {
        // Given
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        
        // Create contract with gap
        Contract gapContract = createContract(
            acc.Id,
            Date.newInstance(2025, 6, 1),
            Date.newInstance(2025, 12, 31),
            'Draft'
        );
        
        // Create policy with gap
        createAdditionalPolicy(
            acc.Id, 
            acc.PersonContactId,
            'Individual_And_Family',
            'PROG_UHSM_Access10k',
            gapContract.Id
        );
        
        List<Id> accountIds = new List<Id>{acc.Id};
        
        // When
        Test.startTest();
        Map<Id, List<Map<String,Object>>> result = 
            ARC_SMBUtility.mapCoveragePeriods(accountIds, 'MAT__c');
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey(acc.Id), 'Result should contain account ID');
    }
    
    @isTest
    static void testMapCoveragePeriods_MaternityHingeYear2026() {
        // Given - Test the 2026 hinge year logic for maternity
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        
        // Create contract spanning 2026
        Contract contract2026 = createContract(
            acc.Id,
            Date.newInstance(2025, 6, 1),
            Date.newInstance(2026, 6, 30),
            'Draft'
        );
        
        // Create policy spanning the hinge year
        createAdditionalPolicy(
            acc.Id,  
            acc.PersonContactId,
            'Individual_And_Family',
            'PROG_UHSM_Access10k',
            contract2026.Id
        );
        
        List<Id> accountIds = new List<Id>{acc.Id};
        
        // When
        Test.startTest();
        Map<Id, List<Map<String,Object>>> result = 
            ARC_SMBUtility.mapCoveragePeriods(accountIds, 'MAT__c');
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey(acc.Id), 'Result should contain account ID');
        List<Map<String,Object>> periods = result.get(acc.Id);
        System.assertNotEquals(0, periods.size(), 'Should have periods');
    }
    
    @isTest
    static void testMapCoveragePeriods_SmallGroup() {
        // Given - Test Small Group policy
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        
        // Create Small Group Policy (no contract needed)
        Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'PROG_UHSM_Access10k' LIMIT 1];
        
        InsurancePolicy sgPolicy = new InsurancePolicy(
            Name = 'Small Group Policy',
            NameInsuredId = acc.Id,
            RecordTypeId = Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByDeveloperName()
                .get('ARC_SmallGroup').getRecordTypeId(),
            Status = 'Activated',
            EffectiveDate = Date.newInstance(2024, 1, 1),
            ExpirationDate = Date.newInstance(2024, 12, 31)
        );
        insert sgPolicy;
        
        InsurancePolicyParticipant sgIPP = new InsurancePolicyParticipant(
            InsurancePolicyId = sgPolicy.Id,
            PrimaryParticipantContactId = acc.PersonContactId,
            Role = 'Primary'
        );
        insert sgIPP;
        
        InsurancePolicyCoverage sgCoverage = new InsurancePolicyCoverage(
            InsurancePolicyId = sgPolicy.Id,
            vlocity_ins_fsc__Product2Id__c = product.Id
        );
        insert sgCoverage;
        
        ARC_CoverageParticipant__c sgCovPart = new ARC_CoverageParticipant__c(
            ARC_PolicyCoverage__c = sgCoverage.Id,
            ARC_PolicyParticipant__c = sgIPP.Id
        );
        insert sgCovPart;
        
        List<Id> accountIds = new List<Id>{acc.Id};
        
        // When
        Test.startTest();
        Map<Id, List<Map<String,Object>>> result = 
            ARC_SMBUtility.mapCoveragePeriods(accountIds, 'PREEX__c');
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @isTest
    static void testMapCoveragePeriods_Reinstatement() {
        // Given - Test reinstatement scenario
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'PROG_UHSM_Access10k' LIMIT 1];
        
        // Create policy with reinstatement reason
        InsurancePolicy reinstatePolicy = new InsurancePolicy(
            Name = 'Reinstatement Policy',
            NameInsuredId = acc.Id,
            RecordTypeId = Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByDeveloperName()
                .get('ARC_SmallGroup').getRecordTypeId(),
            Status = 'Activated',
            ARC_Reason__c = 'Reinstatement',
            EffectiveDate = Date.newInstance(2024, 1, 1),
            ExpirationDate = Date.newInstance(2024, 12, 31)
        );
        insert reinstatePolicy;
        
        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(
            InsurancePolicyId = reinstatePolicy.Id,
            PrimaryParticipantContactId = acc.PersonContactId,
            Role = 'Primary'
        );
        insert ipp;
        
        InsurancePolicyCoverage coverage = new InsurancePolicyCoverage(
            InsurancePolicyId = reinstatePolicy.Id,
            vlocity_ins_fsc__Product2Id__c = product.Id
        );
        insert coverage;
        
        ARC_CoverageParticipant__c covPart = new ARC_CoverageParticipant__c(
            ARC_PolicyCoverage__c = coverage.Id,
            ARC_PolicyParticipant__c = ipp.Id
        );
        insert covPart;
        
        List<Id> accountIds = new List<Id>{acc.Id};
        
        // When
        Test.startTest();
        Map<Id, List<Map<String,Object>>> result = 
            ARC_SMBUtility.mapCoveragePeriods(accountIds, 'MAT__c');
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @isTest
    static void testMapCoveragePeriods_NewbornScenario() {
        // Given - Create newborn account (birthdate after policy effective date)
        Account newbornAccount = new Account(
            FirstName = 'Baby',
            LastName = 'Newborn',
            PersonBirthdate = Date.newInstance(2024, 6, 15),
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount').getRecordTypeId()
        );
        insert newbornAccount;
        
        newbornAccount = [SELECT Id, PersonContactId, PersonBirthdate 
                          FROM Account WHERE Id = :newbornAccount.Id];
        
        Product2 product = [SELECT Id FROM Product2 WHERE ProductCode = 'PROG_UHSM_Access10k' LIMIT 1];
        
        Contract nbContract = createContract(
            newbornAccount.Id,
            Date.newInstance(2024, 5, 1),
            Date.newInstance(2024, 12, 31),
            'Draft'
        );
        
        InsurancePolicy nbPolicy = new InsurancePolicy(
            Name = 'Newborn Policy',
            NameInsuredId = newbornAccount.Id,
            ARC_Contract__c = nbContract.Id,
            RecordTypeId = Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByDeveloperName()
                .get('ARC_IndividualAndFamily').getRecordTypeId(),
            Status = 'Activated',
            EffectiveDate = Date.newInstance(2024, 5, 1),
            ExpirationDate = Date.newInstance(2024, 12, 31)
        );
        insert nbPolicy;
        
        InsurancePolicyParticipant nbIPP = new InsurancePolicyParticipant(
            InsurancePolicyId = nbPolicy.Id,
            PrimaryParticipantContactId = newbornAccount.PersonContactId,
            Role = 'Dependent'
        );
        insert nbIPP;
        
        InsurancePolicyCoverage nbCoverage = new InsurancePolicyCoverage(
            InsurancePolicyId = nbPolicy.Id,
            vlocity_ins_fsc__Product2Id__c = product.Id
        );
        insert nbCoverage;
        
        ARC_CoverageParticipant__c nbCovPart = new ARC_CoverageParticipant__c(
            ARC_PolicyCoverage__c = nbCoverage.Id,
            ARC_PolicyParticipant__c = nbIPP.Id
        );
        insert nbCovPart;
        
        List<Id> accountIds = new List<Id>{newbornAccount.Id};
        
        // When
        Test.startTest();
        Map<Id, List<Map<String,Object>>> result = 
            ARC_SMBUtility.mapCoveragePeriods(accountIds, 'MAT__c');
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey(newbornAccount.Id), 'Should contain newborn account');
    }
    
    /******************************************************************
     * TEST METHODS - calculateAggregators
     ******************************************************************/
    
    @isTest
    static void testCalculateAggregators_SinglePeriod_Maternity() {
        // Given - Single period for maternity (2 year duration, 1 BY)
        List<Map<String, Object>> memberCoveragePeriods = new List<Map<String, Object>>{
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2024, 1, 1), 
                    Date.newInstance(2025, 12, 31)
                },
                'UHSMProgram' => true
            }
        };
        
        // When
        Test.startTest();
        List<String> result = ARC_SMBUtility.calculateAggregators(
            memberCoveragePeriods, 
            'MAT__c'
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should create 1 maternity aggregator (BY1)');
        
        // Verify aggregator format: startDate||endDate||benefitYear||type
        String aggregator = result[0];
        List<String> aggParts = aggregator.split('\\|\\|');
        System.assertEquals(4, aggParts.size(), 'Aggregator should have 4 parts');
        System.assertEquals('BY1', aggParts[2], 'Should be Benefit Year 1');
        System.assertEquals('MAT__c', aggParts[3], 'Should be Maternity type');
    }
    
    @isTest
    static void testCalculateAggregators_SinglePeriod_PreExisting() {
        // Given - Single period for pre-existing (1 year duration, 3 BY max)
        List<Map<String, Object>> memberCoveragePeriods = new List<Map<String, Object>>{
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2024, 1, 1), 
                    Date.newInstance(2026, 12, 31)
                },
                'UHSMProgram' => true
            }
        };
        
        // When
        Test.startTest();
        List<String> result = ARC_SMBUtility.calculateAggregators(
            memberCoveragePeriods, 
            'PREEX__c'
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(3, result.size(), 'Should create 3 pre-existing aggregators (BY1-BY3)');
        
        // Verify all benefit years are created
        Set<String> benefitYears = new Set<String>();
        for (String agg : result) {
            List<String> parts = agg.split('\\|\\|');
            benefitYears.add(parts[2]);
        }
        System.assert(benefitYears.contains('BY1'), 'Should contain BY1');
        System.assert(benefitYears.contains('BY2'), 'Should contain BY2');
        System.assert(benefitYears.contains('BY3'), 'Should contain BY3');
    }
    
    @isTest
    static void testCalculateAggregators_MultiplePeriods_Continuous() {
        // Given - Multiple continuous periods with USHM program
        List<Map<String, Object>> memberCoveragePeriods = new List<Map<String, Object>>{
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2024, 1, 1), 
                    Date.newInstance(2024, 12, 31)
                },
                'UHSMProgram' => true
            },
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2025, 1, 1), 
                    Date.newInstance(2025, 12, 31)
                },
                'UHSMProgram' => true
            }
        };
        
        // When
        Test.startTest();
        List<String> result = ARC_SMBUtility.calculateAggregators(
            memberCoveragePeriods, 
            'MAT__c'
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 1, 'Should create maternity aggregator(s)');
    }
    
    @isTest
    static void testCalculateAggregators_NonUSHMProgram() {
        // Given - Period without USHM program
        List<Map<String, Object>> memberCoveragePeriods = new List<Map<String, Object>>{
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2024, 1, 1), 
                    Date.newInstance(2024, 12, 31)
                },
                'UHSMProgram' => false
            }
        };
        
        // When
        Test.startTest();
        List<String> result = ARC_SMBUtility.calculateAggregators(
            memberCoveragePeriods, 
            'MAT__c'
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should not create aggregators for non-USHM programs');
    }
    
    @isTest
    static void testCalculateAggregators_MixedUSHMAndNonUSHM() {
        // Given - Mixed periods
        List<Map<String, Object>> memberCoveragePeriods = new List<Map<String, Object>>{
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2024, 1, 1), 
                    Date.newInstance(2024, 12, 31)
                },
                'UHSMProgram' => true
            },
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2025, 1, 1), 
                    Date.newInstance(2025, 12, 31)
                },
                'UHSMProgram' => false
            },
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2026, 1, 1), 
                    Date.newInstance(2026, 12, 31)
                },
                'UHSMProgram' => true
            }
        };
        
        // When
        Test.startTest();
        List<String> result = ARC_SMBUtility.calculateAggregators(
            memberCoveragePeriods, 
            'PREEX__c'
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        // Should create aggregators only for USHM periods
    }
    
    @isTest
    static void testCalculateAggregators_EmptyPeriods() {
        // Given - Empty periods list
        List<Map<String, Object>> memberCoveragePeriods = new List<Map<String, Object>>();
        
        // When
        Test.startTest();
        List<String> result = ARC_SMBUtility.calculateAggregators(
            memberCoveragePeriods, 
            'MAT__c'
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list for empty periods');
    }
    
    @isTest
    static void testCalculateAggregators_BenefitYearRenewal() {
        // Given - Period spanning multiple benefit years
        List<Map<String, Object>> memberCoveragePeriods = new List<Map<String, Object>>{
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2024, 1, 1), 
                    Date.newInstance(2027, 6, 30)
                },
                'UHSMProgram' => true
            }
        };
        
        // When
        Test.startTest();
        List<String> result = ARC_SMBUtility.calculateAggregators(
            memberCoveragePeriods, 
            'PREEX__c'
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 3, 'Should create multiple benefit years');
    }

    @isTest
    static void testCalculateAggregators_ResetBenefitAfterGap() {
        // Given
        List<Map<String, Object>> memberCoveragePeriods = new List<Map<String, Object>>{
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2020, 1, 1),
                    Date.newInstance(2020, 12, 31)
                },
                'UHSMProgram' => true
            },
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2025, 1, 1),
                    Date.newInstance(2025, 12, 31)
                },
                'UHSMProgram' => true
            }
        };
        
        // When
        Test.startTest();
        List<String> result = ARC_SMBUtility.calculateAggregators(
            memberCoveragePeriods,
            'MAT__c'
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 2, 'Should create aggregators after reset');
    }

    @isTest
    static void testCalculateAggregators_ResetBenefitToNonUSHM() {
        // Given
        List<Map<String, Object>> memberCoveragePeriods = new List<Map<String, Object>>{
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2020, 1, 1),
                    Date.newInstance(2020, 12, 31)
                },
                'UHSMProgram' => true
            },
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2025, 1, 1),
                    Date.newInstance(2025, 12, 31)
                },
                'UHSMProgram' => false
            }
        };
        
        // When
        Test.startTest();
        List<String> result = ARC_SMBUtility.calculateAggregators(
            memberCoveragePeriods,
            'PREEX__c'
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(!result.isEmpty(), 'Should keep aggregators from first USHM period');
    }

    @isTest
    static void testCalculateAggregators_PreviousAggregatorAdjustment() {
        // Given
        List<Map<String, Object>> memberCoveragePeriods = new List<Map<String, Object>>{
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2024, 1, 1),
                    Date.newInstance(2024, 6, 30)
                },
                'UHSMProgram' => true
            },
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2024, 10, 1),
                    Date.newInstance(2026, 12, 31)
                },
                'UHSMProgram' => true
            }
        };
        
        // When
        Test.startTest();
        List<String> result = ARC_SMBUtility.calculateAggregators(
            memberCoveragePeriods,
            'PREEX__c'
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 2, 'Should create multiple aggregators');
    }

    @isTest
    static void testCalculateAggregators_StartWithNonUSHMThenUSHM() {
        // Given
        List<Map<String, Object>> memberCoveragePeriods = new List<Map<String, Object>>{
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2023, 1, 1),
                    Date.newInstance(2023, 12, 31)
                },
                'UHSMProgram' => false
            },
            new Map<String, Object>{
                'dates' => new Date[]{
                    Date.newInstance(2024, 1, 1),
                    Date.newInstance(2026, 12, 31)
                },
                'UHSMProgram' => true
            }
        };
        
        // When
        Test.startTest();
        List<String> result = ARC_SMBUtility.calculateAggregators(
            memberCoveragePeriods,
            'PREEX__c'
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(3, result.size(), 'Should create three pre-existing aggregators');
    }
    
    /******************************************************************
     * TEST METHODS - createAggregatorsForPeriod
     ******************************************************************/
    
    @isTest
    static void testCreateAggregatorsForPeriod_Maternity() {
        // Given
        Date[] period = new Date[]{
            Date.newInstance(2024, 1, 1),
            Date.newInstance(2025, 12, 31)
        };
        Date renewalDate = Date.newInstance(2024, 1, 1);
        Integer byCounter = 1;
        Date benefitEndDate = Date.newInstance(2026, 1, 1);
        String type = 'MAT__c';
        Boolean createAggregators = true;
        
        // When
        Test.startTest();
        Map<String, Object> result = ARC_SMBUtility.createAggregatorsForPeriod(
            period, 
            renewalDate, 
            byCounter, 
            benefitEndDate, 
            type, 
            createAggregators
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('renewalDate'), 'Should contain renewalDate');
        System.assert(result.containsKey('BYCounter'), 'Should contain BYCounter');
        System.assert(result.containsKey('createdAggregators'), 'Should contain createdAggregators');
        
        List<String> aggregators = (List<String>) result.get('createdAggregators');
        System.assertEquals(1, aggregators.size(), 'Should create 1 maternity aggregator');
    }
    
    @isTest
    static void testCreateAggregatorsForPeriod_PreExisting() {
        // Given
        Date[] period = new Date[]{
            Date.newInstance(2024, 1, 1),
            Date.newInstance(2026, 12, 31)
        };
        Date renewalDate = Date.newInstance(2024, 1, 1);
        Integer byCounter = 1;
        Date benefitEndDate = Date.newInstance(2027, 1, 1);
        String type = 'PREEX__c';
        Boolean createAggregators = true;
        
        // When
        Test.startTest();
        Map<String, Object> result = ARC_SMBUtility.createAggregatorsForPeriod(
            period, 
            renewalDate, 
            byCounter, 
            benefitEndDate, 
            type, 
            createAggregators
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');

        List<String> aggregators = (List<String>) result.get('createdAggregators');
        System.assertEquals(3, aggregators.size(), 'Should create 3 pre-existing aggregators');
    }
    
    @isTest
    static void testCreateAggregatorsForPeriod_NoAggregators() {
        // Given
        Date[] period = new Date[]{
            Date.newInstance(2024, 1, 1),
            Date.newInstance(2024, 12, 31)
        };
        Date renewalDate = Date.newInstance(2024, 1, 1);
        Integer byCounter = 1;
        Date benefitEndDate = Date.newInstance(2024, 12, 31);
        String type = 'MAT__c';
        Boolean createAggregators = false;
        
        // When
        Test.startTest();
        Map<String, Object> result = ARC_SMBUtility.createAggregatorsForPeriod(
            period, 
            renewalDate, 
            byCounter, 
            benefitEndDate, 
            type, 
            createAggregators
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        List<String> aggregators = (List<String>) result.get('createdAggregators');
        System.assertEquals(0, aggregators.size(), 'Should not create aggregators');
    }

    @isTest
    static void testCreateAggregatorsForPeriod_StartAfterEndDate() {
        // Given
        Date[] period = new Date[]{
            Date.newInstance(2024, 1, 1),
            Date.newInstance(2024, 12, 31)
        };
        
        // When
        Test.startTest();
        Map<String, Object> result = ARC_SMBUtility.createAggregatorsForPeriod(
            period,
            Date.newInstance(2025, 1, 1),
            1,
            Date.newInstance(2026, 1, 1),
            'MAT__c',
            true
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        List<String> aggregators = (List<String>) result.get('createdAggregators');
        System.assertEquals(0, aggregators.size(), 'Should not create aggregators');
    }

    @isTest
    static void testCreateAggregatorsForPeriod_MaxBenefitYearExceeded() {
        // Given
        Date[] period = new Date[]{
            Date.newInstance(2024, 1, 1),
            Date.newInstance(2026, 12, 31)
        };
        
        // When
        Test.startTest();
        Map<String, Object> result = ARC_SMBUtility.createAggregatorsForPeriod(
            period,
            Date.newInstance(2024, 1, 1),
            4,
            Date.newInstance(2027, 1, 1),
            'PREEX__c',
            true
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        List<String> aggregators = (List<String>) result.get('createdAggregators');
        System.assertEquals(0, aggregators.size(), 'Should not create aggregators');
    }
    
    /******************************************************************
     * TEST METHODS - Utility Methods
     ******************************************************************/
    
    @isTest
    static void testDebugAggregator() {
        // Given
        Date aggStart = Date.newInstance(2024, 1, 1);
        Date aggEnd = Date.newInstance(2025, 12, 31);
        String benefitYear = 'BY1';
        String type = 'MAT__c';
        
        // When
        Test.startTest();
        String result = ARC_SMBUtility.debugAggregator(aggStart, aggEnd, benefitYear, type);
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        List<String> parts = result.split('\\|\\|');
        System.assertEquals(4, parts.size(), 'Should have 4 parts');
        System.assertEquals(String.valueOf(aggStart), parts[0], 'First part should be start date');
        System.assertEquals(String.valueOf(aggEnd), parts[1], 'Second part should be end date');
        System.assertEquals(benefitYear, parts[2], 'Third part should be benefit year');
        System.assertEquals(type, parts[3], 'Fourth part should be type');
    }
    
    @isTest
    static void testGetMatPeexProductCodes() {
        // Note: This test assumes you have metadata records for Product Aggregators
        
        // When
        Test.startTest();
        List<String> matCodes = ARC_SMBUtility.getMatPeexProductCodes('MAT__c');
        List<String> preexCodes = ARC_SMBUtility.getMatPeexProductCodes('PREEX__c');
        List<String> bothCodes = ARC_SMBUtility.getMatPeexProductCodes('BOTH');
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, matCodes, 'Maternity codes should not be null');
        System.assertNotEquals(null, preexCodes, 'Pre-existing codes should not be null');
        System.assertNotEquals(null, bothCodes, 'Both codes should not be null');
    }
    
    @isTest
    static void testDebugParticipantAggregator() {
        // Given
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];

        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Debug Policy',
            NameInsuredId = acc.Id,
            Status = 'Activated',
            EffectiveDate = Date.today().addMonths(-1),
            ExpirationDate = Date.today().addMonths(11)
        );
        insert policy;

        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            PrimaryParticipantContactId = acc.PersonContactId,
            Role = 'Primary'
        );
        insert ipp;
        
        // When
        Test.startTest();
        String result = ARC_SMBUtility.debugParticipantAggregator(policy.Id, ipp.Id);
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        List<String> parts = result.split('\\|\\|');
        System.assertEquals(2, parts.size(), 'Should have 2 parts');
        System.assertEquals(policy.Id, parts[0], 'First part should be policy Id');
        System.assertEquals(ipp.Id, parts[1], 'Second part should be IPP Id');
    }
    
    @isTest
    static void testGetPartAggForAggInPolicies() {
        // Given
        Account acc = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        
        // Create multiple policies
        List<InsurancePolicy> memberPolicies = new List<InsurancePolicy>();
        
        // Policy 1
        InsurancePolicy policy1 = new InsurancePolicy(
            Name = 'Test Policy 1',
            NameInsuredId = acc.Id,
            Status = 'Activated',
            EffectiveDate = Date.newInstance(2024, 1, 1),
            ExpirationDate = Date.newInstance(2024, 12, 31)
        );
        insert policy1;
        
        InsurancePolicyParticipant ipp1 = new InsurancePolicyParticipant(
            InsurancePolicyId = policy1.Id,
            PrimaryParticipantContactId = acc.PersonContactId,
            Role = 'Primary'
        );
        insert ipp1;
        
        // Policy 2
        InsurancePolicy policy2 = new InsurancePolicy(
            Name = 'Test Policy 2',
            NameInsuredId = acc.Id,
            Status = 'Activated',
            EffectiveDate = Date.newInstance(2024, 6, 1),
            ExpirationDate = Date.newInstance(2025, 5, 31)
        );
        insert policy2;
        
        InsurancePolicyParticipant ipp2 = new InsurancePolicyParticipant(
            InsurancePolicyId = policy2.Id,
            PrimaryParticipantContactId = acc.PersonContactId,
            Role = 'Primary'
        );
        insert ipp2;
        
        memberPolicies = [
            SELECT Id,
                   ARC_EffectiveDate__c,
                   ARC_ExpirationDate__c,
                   EffectiveDate,
                   ExpirationDate,
                   (
                       SELECT Id, Participant_Account_Id__c
                       FROM InsurancePolicyParticipants
                   )
            FROM InsurancePolicy
            WHERE Id IN :new List<Id>{policy1.Id, policy2.Id}
        ];
        
        // Aggregator description
        String aggDescription = '2024-01-01||2024-12-31||BY1||MAT__c';
        
        // When
        Test.startTest();
        List<String> result = ARC_SMBUtility.getPartAggForAggInPolicies(
            aggDescription, 
            memberPolicies, 
            acc.Id
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetPartAggForAggInPolicies_NullPolicies() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // When
        Test.startTest();
        List<String> result = ARC_SMBUtility.getPartAggForAggInPolicies(
            '2024-01-01||2024-12-31||BY1||MAT__c',
            null,
            acc.Id
        );
        Test.stopTest();
        
        // Then
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list');
    }

    @isTest
    static void testRangeComparatorSort() {
        // Given
        List<Map<String, Object>> ranges = new List<Map<String, Object>>{
            new Map<String, Object>{
                'start' => Date.newInstance(2025, 1, 1),
                'end' => Date.newInstance(2025, 12, 31),
                'UHSMProgram' => true
            },
            new Map<String, Object>{
                'start' => Date.newInstance(2024, 1, 1),
                'end' => Date.newInstance(2024, 12, 31),
                'UHSMProgram' => false
            }
        };
        
        // When
        Test.startTest();
        ranges.sort(new ARC_SMBUtility.RangeComparator());
        Test.stopTest();
        
        // Then
        System.assertEquals(Date.newInstance(2024, 1, 1), ranges[0].get('start'), 'First range should start in 2024');
        System.assertEquals(Date.newInstance(2025, 1, 1), ranges[1].get('start'), 'Second range should start in 2025');
    }
}