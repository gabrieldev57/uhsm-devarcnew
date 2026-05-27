@isTest
private class ARC_SGNewBorn_BaseServiceTest {

    /**
    * Preparation of the simulated data in the database so that the SOQL
    * of the ARC_SGNBMapper finds the policies and medical coverages.
    */
    @testSetup
    static void setupData() {

        Account groupAcc = new Account(Name = 'Test Employer Group');
        insert groupAcc;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(
            Name = 'Test Census',
            vlocity_ins__GroupId__c = groupAcc.Id
        );
        insert census;

        Id personAccRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_SGPersonAccount').getRecordTypeId();
        
        Account motherAcc = new Account(
            FirstName = 'Jane',
            LastName = 'Doe',
            RecordTypeId = personAccRecTypeId,
            PersonGender = 'Female',
            ARC_IsPrimaryMember__c = true,
            ARC_Census__c = census.Id
        );
        insert motherAcc;

        vlocity_ins__GroupCensusMember__c motherGcm = new vlocity_ins__GroupCensusMember__c(
            Name = 'Jane Doe',
            vlocity_ins__CensusId__c = census.Id,
            vlocity_ins__IsPrimaryMember__c = true
        );
        insert motherGcm;

        motherAcc.Census_Member__c = motherGcm.Id;
        update motherAcc;

        Product2 medProd = new Product2(
            Name = 'Medical Plan Test', 
            vlocity_ins__Type__c = 'Medical'
        );
        insert medProd;

        InsurancePolicy policy = new InsurancePolicy(
            NameInsuredId = motherAcc.Id,
            Name = 'Test Policy',
            Status = 'Active', 
            ARC_PolicyEffectiveDate__c = Date.today().addDays(-100),
            ARC_PolicyExpirationDate__c = Date.today().addDays(100)
        );
        insert policy;

        InsurancePolicyCoverage ipc = new InsurancePolicyCoverage(
            InsurancePolicyId = policy.Id,
            CoverageName = 'Medical Coverage',
            vlocity_ins_fsc__Product2Id__c = medProd.Id
            // ARC_ParentPolicyCoverage__c = null 
        );
        insert ipc;

        Contact motherContact = [SELECT Id FROM Contact WHERE AccountId = :motherAcc.Id LIMIT 1];

        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            PrimaryParticipantContactId = motherContact.Id,
            Role = 'Primary'
        );
        insert ipp;

        ARC_CoverageParticipant__c covPart = new ARC_CoverageParticipant__c(
            ARC_Policy__c = policy.Id,
            ARC_PolicyCoverage__c = ipc.Id,
            ARC_PolicyParticipant__c = ipp.Id,
            ARC_CoverageRole__c = 'Primary'
        );
        insert covPart;
    }

    /**
    * Scenario 1: Inserts the babies correctly and returns success = true.
    */
    @isTest
    static void testSuccessfulNewbornDML() {
        Account contextAcc = [SELECT Id FROM Account WHERE FirstName = 'Jane' LIMIT 1];

        Map<String, Object> inputData = new Map<String, Object>();
        inputData.put('ContextId', contextAcc.Id);

        Map<String, Object> member1 = new Map<String, Object>{
            'Id' => 'MEM-1234',
            'vlocity_ins__Birthdate__c' => String.valueOf(Date.today().addDays(-5)),
            'vlocity_ins__FirstName__c' => 'Baby',
            'vlocity_ins__LastName__c' => 'Doe',
            'vlocity_ins__Gender__c' => 'Male'
        };

        Map<String, Object> stepAddNewborn = new Map<String, Object>{
            'EB_TemporaryNewborn' => new List<Object>{ member1 }
        };
        inputData.put('STEP_AddNewborn', stepAddNewborn);

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_SGNewBorn_BaseService service = new ARC_SGNewBorn_BaseService();
        Boolean isInvoked = service.invokeMethod('SGNB_TempNewBornDML', inputData, outputMap, new Map<String, Object>());
        Test.stopTest();

        String realError = outputMap.containsKey('errorMessage') ? (String)outputMap.get('errorMessage') : 'Unknown Error';
        Boolean isSuccess = outputMap.containsKey('success') ? (Boolean)outputMap.get('success') : false;

        Assert.isTrue(isInvoked, 'The invokeMethod method must return true');
        Assert.isTrue(isSuccess, 'The operation failed. Real org error: ' + realError);
    }

    /**
     * Scenario 2: Validate Date Exception (Twins > 1 day)
     */
    @isTest
    static void testTwinDateException() {
        Account contextAcc = [SELECT Id FROM Account WHERE FirstName = 'Jane' LIMIT 1];

        Map<String, Object> inputData = new Map<String, Object>();
        inputData.put('ContextId', contextAcc.Id);

        Map<String, Object> member1 = new Map<String, Object>{
            'Id' => 'MEM-1111',
            'vlocity_ins__Birthdate__c' => String.valueOf(Date.today().addDays(-10))
        };
        Map<String, Object> member2 = new Map<String, Object>{
            'Id' => 'MEM-2222',
            'vlocity_ins__Birthdate__c' => String.valueOf(Date.today().addDays(-5))
        };

        inputData.put('STEP_AddNewborn', new Map<String, Object>{
            'EB_TemporaryNewborn' => new List<Object>{ member1, member2 }
        });

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_SGNewBorn_BaseService service = new ARC_SGNewBorn_BaseService();
        service.invokeMethod('SGNB_TempNewBornDML', inputData, outputMap, new Map<String, Object>());
        Test.stopTest();

        Assert.isFalse((Boolean)outputMap.get('success'), 'The operation must fail');
        Assert.isTrue((Boolean)outputMap.get('BirthdateError'), 'Must send the BirthdateError flag as true to the screen');
    }

    /**
     * Scenario 3: Validate Missing Mother Exception
     */
    @isTest
    static void testNoMotherException() {
        Id personAccRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_SGPersonAccount').getRecordTypeId();
        
        Account emptyAcc = new Account(
            FirstName = 'Empty', 
            LastName = 'Acc', 
            RecordTypeId = personAccRecTypeId,
            ARC_IsPrimaryMember__c = true
        );
        insert emptyAcc;

        Map<String, Object> inputData = new Map<String, Object>();
        inputData.put('ContextId', emptyAcc.Id);

        Map<String, Object> member1 = new Map<String, Object>{
            'Id' => 'MEM-3333',
            'vlocity_ins__Birthdate__c' => String.valueOf(Date.today().addDays(-2))
        };

        inputData.put('STEP_AddNewborn', new Map<String, Object>{
            'EB_TemporaryNewborn' => new List<Object>{ member1 }
        });

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_SGNewBorn_BaseService service = new ARC_SGNewBorn_BaseService();
        service.invokeMethod('SGNB_TempNewBornDML', inputData, outputMap, new Map<String, Object>());
        Test.stopTest();

        Assert.isFalse((Boolean)outputMap.get('success'), 'The operation must fail');
        Assert.isTrue((Boolean)outputMap.get('MotherError'), 'Must send the MotherError flag as true to the screen');
    }

    /**
    * Scenario 4: Mapper Coverage (Completed Policy)
    * Covers the if/else blocks that assign the start and end dates
    * when the mother's policy is completed.
    */
    @isTest
    static void testTerminatedPolicyMapping() {
        Account contextAcc = [SELECT Id FROM Account WHERE FirstName = 'Jane' LIMIT 1];

        InsurancePolicy testPolicy = [SELECT Id FROM InsurancePolicy WHERE NameInsuredId = :contextAcc.Id LIMIT 1];
        testPolicy.Status = 'Terminated';
        testPolicy.ARC_PolicyEffectiveDate__c = Date.today().addDays(-10);
        testPolicy.ARC_PolicyExpirationDate__c = Date.today().addDays(10);
        update testPolicy;

        Map<String, Object> inputData = new Map<String, Object>();
        inputData.put('ContextId', contextAcc.Id);

        Map<String, Object> member1 = new Map<String, Object>{
            'Id' => 'MEM-TERM',
            'vlocity_ins__Birthdate__c' => String.valueOf(Date.today().addDays(-5)),
            'vlocity_ins__FirstName__c' => 'BabyTerm',
            'vlocity_ins__LastName__c' => 'Doe'
        };

        inputData.put('STEP_AddNewborn', new Map<String, Object>{
            'EB_TemporaryNewborn' => new List<Object>{ member1 }
        });

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_SGNewBorn_BaseService service = new ARC_SGNewBorn_BaseService();
        service.invokeMethod('SGNB_TempNewBornDML', inputData, outputMap, new Map<String, Object>());
        Test.stopTest();

        Assert.isTrue((Boolean)outputMap.get('success'), 'The operation should have mapped the finished policy correctly.');
    }

    /**
    * Scenario 5: BaseService Coverage (Generic Exception)
    * We force a data format error (TypeException) so that
    * the catch falls into the final "else" and prepares the email sending.
    */
    @isTest
    static void testGenericSystemException() {
        Account contextAcc = [SELECT Id FROM Account WHERE FirstName = 'Jane' LIMIT 1];

        Map<String, Object> inputData = new Map<String, Object>();
        inputData.put('ContextId', contextAcc.Id);

        Map<String, Object> member1 = new Map<String, Object>{
            'Id' => 'MEM-ERROR',
            'vlocity_ins__Birthdate__c' => 'THIS-IS-NOT-A-DATE', 
            'vlocity_ins__FirstName__c' => 'ErrorBaby',
            'vlocity_ins__LastName__c' => 'Doe'
        };

        inputData.put('STEP_AddNewborn', new Map<String, Object>{
            'EB_TemporaryNewborn' => new List<Object>{ member1 }
        });

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_SGNewBorn_BaseService service = new ARC_SGNewBorn_BaseService();
        service.invokeMethod('SGNB_TempNewBornDML', inputData, outputMap, new Map<String, Object>());
        Test.stopTest();

        Assert.isFalse((Boolean)outputMap.get('success'), 'The operation must fail');
        Boolean hasMotherError = outputMap.containsKey('MotherError') && (Boolean)outputMap.get('MotherError');
        Boolean hasBirthdateError = outputMap.containsKey('BirthdateError') && (Boolean)outputMap.get('BirthdateError');

        Assert.isFalse(hasMotherError, 'It should not return a mother error');
        Assert.isFalse(hasBirthdateError, 'It should not return a twin date error');
        
        Assert.isTrue(outputMap.containsKey('errorStackTrace'), 'Must capture the generic error in the else block and fill the errorStackTrace');
    }
}