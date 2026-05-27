@isTest
private class ARC_DocuSignResendControllerTest {

    @testSetup
    static void setupData() {
        User accountOwner;
        User testUser;
        Account grpAcc;


        RecordType groupAccRT = [SELECT Id FROM RecordType WHERE DeveloperName='Group' AND SobjectType='Account' LIMIT 1];

        grpAcc = new Account(
            Name='Poojal Group Account', 
            IsActive=true,
            RecordTypeId=groupAccRT.Id
        );
        insert grpAcc;
        
        RecordType guardianAccRT = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_Guardian' AND SobjectType='Account' LIMIT 1];
        Account guarAcc = new Account(
            FirstName='Nacho',
            LastName='Guardian',
            PersonBirthdate = Date.today().addYears(-30),
            IsActive=true,
            RecordTypeId = guardianAccRT.Id,
            ARC_GroupAccount__c = grpAcc.Id,
            PersonEmail = 'guardian@mail.com',
            Phone = '1234567889'
        );
        insert guarAcc;
    
        vlocity_ins__GroupCensus__c grpCensus = new vlocity_ins__GroupCensus__c(
            Name='Test Group Census',
            vlocity_ins__GroupId__c = grpAcc.Id
        );
        insert grpCensus;
        
        vlocity_ins__GroupCensusMember__c census = new vlocity_ins__GroupCensusMember__c(
            Name='Poojal Person',
            vlocity_ins__FirstName__c = 'Poojal',
            vlocity_ins__LastName__c = 'Person',
            ARC_ActiveMember__c = true,
            vlocity_ins__IsPrimaryMember__c = true,
            vlocity_ins__CensusId__c = grpCensus.Id,
            vlocity_ins__SocialSecurityNumber__c = '123456789',
            vlocity_ins__Birthdate__c = Date.today().addYears(-30),
            ARC_PhysicianName__c = 'Dr. Smith',
            ARC_PhysicianCity__c = 'Los Angeles',
            ARC_PhysicianPhone__c = '555-1234'
        );
        insert census;
        
        vlocity_ins__GroupCensusMember__c census1 = new vlocity_ins__GroupCensusMember__c(
            Name='Poojal Person1',
            vlocity_ins__FirstName__c = 'Poojal',
            vlocity_ins__LastName__c = 'Person1',
            ARC_ActiveMember__c = true,
            vlocity_ins__IsPrimaryMember__c = false,
            vlocity_ins__CensusId__c = grpCensus.Id,
            vlocity_ins__SocialSecurityNumber__c = '123456780',
            vlocity_ins__Birthdate__c = Date.today().addYears(-5)
        );
        insert census1;

        RecordType personAccRT = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_IFPPersonAccount' AND SobjectType='Account' LIMIT 1];
        Account perAcc = new Account(
            FirstName='Poojal',
            LastName='Person',
            PersonBirthdate = Date.today().addYears(-30),
            IsActive=true,
            RecordTypeId = personAccRT.Id,
            ARC_GroupAccount__c = grpAcc.Id,
            PersonEmail = 'primary@mail.com',
            Phone = '1234567889',
            Census_Member__c = census.Id
        );
        insert perAcc;

        Account perAcc1 = new Account(
            FirstName='Poojal',
            LastName='Person1',
            PersonBirthdate = Date.today().addYears(-5),
            IsActive=true,
            RecordTypeId = personAccRT.Id,
            ARC_GroupAccount__c = grpAcc.Id,
            PersonEmail = 'dependent@mail.com',
            Census_Member__c = census1.Id
        );
        insert perAcc1;

        Contact perCon = [SELECT Id, AccountId, Account.Census_Member__c FROM Contact WHERE AccountId = :perAcc.Id LIMIT 1];
        Contact perCon1 = [SELECT Id, AccountId, Account.Census_Member__c FROM Contact WHERE AccountId = :perAcc1.Id LIMIT 1];

        census.vlocity_ins__ContactId__c = perCon.Id;
        census1.vlocity_ins__ContactId__c = perCon1.Id;
        
        update new List<vlocity_ins__GroupCensusMember__c>{census, census1};

        Date effectiveDate = Date.today().addDays(30);
        
        Contract con = new Contract(
            Name='Test Contract',
            AccountId = grpAcc.Id,
            Status = 'Draft',
            StartDate = Date.today().addMonths(-1),
            ARC_Guardian__c = guarAcc.Id,
            vlocity_ins__EnrollmentCensusId__c = grpCensus.Id,
            ARC_ContractReason__c = 'New Application',
            ARC_PrimaryAddress__CountryCode__s = 'US',
            ARC_PrimaryAddress__StateCode__s = 'CA',
            ARC_EffectiveDate__c = effectiveDate
        );
        insert con;

        List<InsurancePolicy> policies = new List<InsurancePolicy>();
        for(Integer i = 0; i < 2; i++){
            InsurancePolicy p = new InsurancePolicy(
                Name = 'Policy ' + (i+1),
                Status = 'Awaiting Signature',
                ARC_Contract__c = con.Id
            );
            if(i == 0) {
                p.NameInsuredId = perAcc.Id;
            } else {
                p.NameInsuredId = perAcc1.Id;
            }
            policies.add(p);
        }
        insert policies;

        Product2 prod = new Product2(
            Name = 'WeShare',        
            IsActive=true,
            vlocity_ins__Type__c = 'Medical'
        ); 
        insert prod;

        Product2 prodAncillary = new Product2(
            Name = 'Dental Plan',
            IsActive = true,
            vlocity_ins__Type__c = 'Ancillary'
        );
        insert prodAncillary;

        vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
        cli.Name = 'WeShare Medical Plan';
        cli.ARC_SmokerFee__c = 100;
        cli.ARC_ExtraDependentFee__c = 200;
        cli.ARC_OriginalPrice__c = 0;
        cli.vlocity_ins__UnitPrice__c = 1000;
        cli.vlocity_ins__EffectiveStartDate__c = con.ARC_EffectiveDate__c;
        cli.vlocity_ins__ContractId__c = con.Id;
        cli.vlocity_ins__Product2Id__c = prod.Id;
        insert cli;

        vlocity_ins__ContractLineItem__c cliAncillary = new vlocity_ins__ContractLineItem__c();
        cliAncillary.Name = 'Dental Plan';
        cliAncillary.vlocity_ins__UnitPrice__c = 500;
        cliAncillary.vlocity_ins__EffectiveStartDate__c = con.ARC_EffectiveDate__c;
        cliAncillary.vlocity_ins__ContractId__c = con.Id;
        cliAncillary.vlocity_ins__Product2Id__c = prodAncillary.Id;
        insert cliAncillary;

        con.ARC_MedicalPlan__c = cli.Id;
        update con;

        List<InsurancePolicyParticipant> participants = new List<InsurancePolicyParticipant>();

        for(InsurancePolicy p : policies){
            Id contactId = (p.NameInsuredId == perAcc.Id) 
                ? perAcc.PersonContactId 
                : perAcc1.PersonContactId;

            participants.add(new InsurancePolicyParticipant(
                InsurancePolicyId = p.Id,
                Role = 'Primary',
                PrimaryParticipantContactId = contactId
            ));
        }
        insert participants;

        InsurancePolicyCoverage cov = new InsurancePolicyCoverage( 
            InsurancePolicyId = policies[0].Id, 
            vlocity_ins_fsc__Product2Id__c = prod.Id
        ); 
        insert cov; 

        ARC_CoverageParticipant__c covParticipant = new ARC_CoverageParticipant__c(
            ARC_PolicyParticipant__c = participants[0].Id,
            ARC_PolicyCoverage__c = cov.Id,
            ARC_Policy__c = policies[0].Id
        );
        insert covParticipant;

        InsurancePolicyCoverage cov2 = new InsurancePolicyCoverage( 
            InsurancePolicyId = policies[1].Id, 
            vlocity_ins_fsc__Product2Id__c = prod.Id
        ); 
        insert cov2;

        ARC_CoverageParticipant__c covParticipant1 = new ARC_CoverageParticipant__c(
            ARC_PolicyParticipant__c = participants[1].Id,
            ARC_PolicyCoverage__c = cov2.Id,
            ARC_Policy__c = policies[1].Id
        );
        insert covParticipant1;

        vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c(
            Name = 'WeShare Medical Plan for Person',
            vlocity_ins__ContractLineId__c = cli.Id,
            vlocity_ins__GroupCensusMemberId__c = census.Id
        );  
        vlocity_ins__GroupCensusMemberPlan__c gcmp1 = new vlocity_ins__GroupCensusMemberPlan__c(
            Name = 'WeShare Medical Plan for Person1',
            vlocity_ins__ContractLineId__c = cli.Id,
            vlocity_ins__GroupCensusMemberId__c = census1.Id
        );
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpList = new List<vlocity_ins__GroupCensusMemberPlan__c>{gcmp, gcmp1};
        insert gcmpList; 

        ARC_ContractParticipant__c cp = new ARC_ContractParticipant__c(
            Name = 'Primary Participant',
            ARC_PersonAccount__c = perAcc.Id, 
            ARC_Email__c = 'primary@mail.com', 
            ARC_Relationship__c = 'Primary', 
            ARC_Phone__c = '123123',
            ARC_Contract__c = con.Id
        );
        ARC_ContractParticipant__c cp1 = new ARC_ContractParticipant__c(
            Name = 'Dependent Participant',
            ARC_PersonAccount__c = perAcc1.Id, 
            ARC_Email__c = 'dependent@mail.com', 
            ARC_Relationship__c = 'Child', 
            ARC_Phone__c = '123123',
            ARC_Contract__c = con.Id
        );

        List<ARC_ContractParticipant__c> cpList = new List<ARC_ContractParticipant__c>{cp, cp1};
        insert cpList;

        ARC_MedicalConditions__c medicalCondition1 = new ARC_MedicalConditions__c (
            Name = 'Medical Condition 1',
            ARC_CensusMember__c = census.Id,
            ARC_PersonAccount__c = perAcc.Id,
            ARC_Active__c = true,
            ARC_ParentsOrSiblingsDiagnosed__c = true,
            ARC_Type_Of_Cancer__c = 'Breast Cancer',
            ARC_Year_Diagnosed_Cancer__c = Date.valueOf('2020-05-01'),
            ARC_Currently_Under_Treatment__c = false,
            ARC_Condition__c = 'Diabetes, Type I;Lupus'
        );

        List<ARC_MedicalConditions__c> listMedical = new List<ARC_MedicalConditions__c>{medicalCondition1};

        vlocity_ins__ConsumerDrug__c medication = new vlocity_ins__ConsumerDrug__c (
            Name = 'Metformin',
            ARC_Active__c = true,
            ARC_CensusMember__c = census.Id,
            ARC_PersonAccount__c = perAcc.Id,
            vlocity_ins__MedicationStartDate__c = Date.valueOf('2024-04-01'),
            vlocity_ins__PrescribedBy__c = 'Dr. Johnson',
            ARC_Reason__c = 'Diabetes treatment'
        );

        insert listMedical;
        insert medication;

        ARC_HipaaAuthorization__c hipaa = new ARC_HipaaAuthorization__c(
            Name = 'Test HIPAA Authorization',
            ARC_Census__c = grpCensus.Id,
            ARC_AuthorizedMember__c = census1.Id
        );
        insert hipaa;
        
        List<ARC_DocuSignCompositeTemplates__c> templates = new List<ARC_DocuSignCompositeTemplates__c>();
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'Test Application Template',
            ARC_Section__c = 'Application',
            ARC_TemplateName__c = 'Test Application Template',
            ARC_BusinessSegment__c = 'IndividualAndFamily',
            ARC_MinDependents__c = 0,
            ARC_MaxDependents__c = 10,
            ARC_ChildOnly__c = false,
            ARC_IsLegacy__c = false
        ));
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'Test Program Template',
            ARC_Section__c = 'Program',
            ARC_TemplateName__c = 'Test Program Template',
            ARC_ProgramType__c = 'Essential',
            ARC_BusinessSegment__c = 'IndividualAndFamily'
        ));
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'Test State Template',
            ARC_Section__c = 'State',
            ARC_TemplateName__c = 'Test State Template',
            ARC_State__c = 'CA'
        ));
        insert templates;
        
        List<vlocity_ins__VlocityDocuSignTemplate__c> vlocityTemplates = new List<vlocity_ins__VlocityDocuSignTemplate__c>();
        vlocityTemplates.add(new vlocity_ins__VlocityDocuSignTemplate__c(
            Name = 'Test Application Template',
            vlocity_ins__templateidentifier__c = 'TMPL-APP-001'
        ));
        vlocityTemplates.add(new vlocity_ins__VlocityDocuSignTemplate__c(
            Name = 'Test Program Template',
            vlocity_ins__templateidentifier__c = 'TMPL-PROG-001'
        ));
        vlocityTemplates.add(new vlocity_ins__VlocityDocuSignTemplate__c(
            Name = 'Test State Template',
            vlocity_ins__templateidentifier__c = 'TMPL-STATE-001'
        ));
        insert vlocityTemplates;
        
        ChargentOrders__ChargentOrder__c chargentOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = con.Id,
            ChargentOrders__Payment_Status__c = 'New',
            ChargentOrders__Charge_Amount__c = 1000,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Last_4__c = '1234',
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Month_Indicator__c = '12',
            ChargentOrders__Card_Year_Indicator__c = '2025',
            ChargentOrders__Billing_Address__c = '123 Test St',
            ChargentOrders__Billing_City__c = 'Test City',
            ChargentOrders__Billing_State__c = 'CA',
            ChargentOrders__Billing_Zip_Postal__c = '12345'
        );
        insert chargentOrder;
        
        con.ARC_RecurringMonthlyOrder__c = chargentOrder.Id;
        update con;
    }

    @isTest
    static void getAllRecipientListTest() {
        Contract c = [SELECT Id, AccountId FROM Contract LIMIT 1];

        String methodName = 'getAllRecipientList';
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('contractId', c.Id);
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        ARC_DocuSignResendController DS = new ARC_DocuSignResendController();
        DS.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        
        System.assert(outputMap.containsKey('allRecipients'), 'There should be an allRecipients key');
        List<Object> recipients = (List<Object>)outputMap.get('allRecipients');
        System.assert(recipients != null && recipients.size() > 0, 'There should be at least one recipient');
    }

    @isTest
    static void getHipaaRecipientListTest() {
        Contract c = [SELECT Id, AccountId FROM Contract LIMIT 1];

        String methodName = 'getHipaaRecipientList';
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('contractId', c.Id);
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        ARC_DocuSignResendController DS = new ARC_DocuSignResendController();
        DS.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        
        System.assert(outputMap.containsKey('recipients'), 'There should be a recipients key');
    }

    @isTest
    static void getDocuSignDataTest() {
        Contract c = [SELECT Id, AccountId, vlocity_ins__EnrollmentCensusId__c, ARC_EffectiveDate__c FROM Contract LIMIT 1];
        
        String getAllMethod = 'getAllRecipientList';
        Map<String, Object> getAllInput = new Map<String, Object>();
        getAllInput.put('contractId', c.Id);
        Map<String, Object> getAllOutput = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        ARC_DocuSignResendController DS = new ARC_DocuSignResendController();
        DS.invokeMethod(getAllMethod, getAllInput, getAllOutput, options);
        
        List<Object> allRecipients = (List<Object>)getAllOutput.get('allRecipients');
        System.assert(allRecipients != null && !allRecipients.isEmpty(), 'Should have recipients for testing');
        
        Map<String, Object> selectedRecipient = new Map<String, Object>();
        if (!allRecipients.isEmpty()) {
            selectedRecipient = (Map<String, Object>)allRecipients[0];
        } else {
            selectedRecipient.put('recipientId', 'test123');
            selectedRecipient.put('recipientName', 'Test User');
            selectedRecipient.put('recipientEmail', 'test@example.com');
            selectedRecipient.put('recipientRole', 'Primary');
        }
        
        String dependentCount = '1';
        String methodName = 'getDocuSignData';
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('contractId', c.Id);
        inputMap.put('selectedRecipient', selectedRecipient);
        inputMap.put('allRecipients', allRecipients);
        inputMap.put('dependentCount', dependentCount);
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        DS.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        
        System.assert(outputMap.keySet().size() >= 1, 'There should be at least one key in output');
        System.assert(outputMap.containsKey('contractId'), 'Output should contain contractId');
        System.assert(outputMap.containsKey('signerList'), 'Output should contain signerList');
    }

    @isTest
    static void getDocuSignDataWithProgramChangeTest() {
        Contract c = [SELECT Id, AccountId, vlocity_ins__EnrollmentCensusId__c, ARC_EffectiveDate__c FROM Contract LIMIT 1];
        
        Contract expiredContract = new Contract(
            Name='Expired Contract',
            AccountId = c.AccountId,
            Status = 'Draft',
            vlocity_ins__EnrollmentCensusId__c = c.vlocity_ins__EnrollmentCensusId__c,
            ARC_ContractReason__c = 'New Application',
            ARC_EffectiveDate__c = c.ARC_EffectiveDate__c.addDays(-30)
        );
        insert expiredContract;
        
        c.ARC_ContractReason__c = 'Program Upgrade';
        c.vlocity_ins__ExpiredContractId__c = expiredContract.Id;
        update c;

        String getAllMethod = 'getAllRecipientList';
        Map<String, Object> getAllInput = new Map<String, Object>();
        getAllInput.put('contractId', c.Id);
        Map<String, Object> getAllOutput = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        ARC_DocuSignResendController DS = new ARC_DocuSignResendController();
        DS.invokeMethod(getAllMethod, getAllInput, getAllOutput, options);
        
        List<Object> allRecipients = (List<Object>)getAllOutput.get('allRecipients');
        if (allRecipients == null) {
            allRecipients = new List<Object>();
        }
        
        Map<String, Object> selectedRecipient = new Map<String, Object>();
        selectedRecipient.put('recipientId', 'test123');
        selectedRecipient.put('recipientName', 'Test User');
        selectedRecipient.put('recipientEmail', 'test@example.com');
        
        String methodName = 'getDocuSignData';
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('contractId', c.Id);
        inputMap.put('selectedRecipient', selectedRecipient);
        inputMap.put('allRecipients', allRecipients);
        inputMap.put('dependentCount', '1');
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        DS.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        
        System.assert(outputMap.containsKey('isProgramChange'), 'Should identify program change');
    }

    @isTest
    static void getDocuSignDataWithPrimaryChangeTest() {
        Contract c = [SELECT Id, AccountId, vlocity_ins__EnrollmentCensusId__c, ARC_EffectiveDate__c FROM Contract LIMIT 1];
        
        Contract expiredContract = new Contract(
            Name='Expired Contract Primary',
            AccountId = c.AccountId,
            Status = 'Draft',
            vlocity_ins__EnrollmentCensusId__c = c.vlocity_ins__EnrollmentCensusId__c,
            ARC_ContractReason__c = 'New Application',
            ARC_EffectiveDate__c = c.ARC_EffectiveDate__c.addDays(-30)
        );
        insert expiredContract;
        
        c.ARC_ContractReason__c = 'Primary Change';
        c.vlocity_ins__ExpiredContractId__c = expiredContract.Id;
        update c;

        String getAllMethod = 'getAllRecipientList';
        Map<String, Object> getAllInput = new Map<String, Object>();
        getAllInput.put('contractId', c.Id);
        Map<String, Object> getAllOutput = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        ARC_DocuSignResendController DS = new ARC_DocuSignResendController();
        DS.invokeMethod(getAllMethod, getAllInput, getAllOutput, options);
        
        List<Object> allRecipients = (List<Object>)getAllOutput.get('allRecipients');
        if (allRecipients == null) {
            allRecipients = new List<Object>();
        }
        
        Map<String, Object> selectedRecipient = new Map<String, Object>();
        selectedRecipient.put('recipientId', 'test123');
        selectedRecipient.put('recipientName', 'Test User');
        selectedRecipient.put('recipientEmail', 'test@example.com');
        
        String methodName = 'getDocuSignData';
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('contractId', c.Id);
        inputMap.put('selectedRecipient', selectedRecipient);
        inputMap.put('allRecipients', allRecipients);
        inputMap.put('dependentCount', '1');
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        DS.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        
        System.assert(outputMap.containsKey('isPrimaryChange'), 'Should identify primary change');
    }

    @isTest
    static void getDocuSignDataWithSpinOffTest() {
        Contract c = [SELECT Id, AccountId FROM Contract LIMIT 1];
        c.ARC_ContractReason__c = 'Spin Off';
        update c;

        String getAllMethod = 'getAllRecipientList';
        Map<String, Object> getAllInput = new Map<String, Object>();
        getAllInput.put('contractId', c.Id);
        Map<String, Object> getAllOutput = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        ARC_DocuSignResendController DS = new ARC_DocuSignResendController();
        DS.invokeMethod(getAllMethod, getAllInput, getAllOutput, options);
        
        List<Object> allRecipients = (List<Object>)getAllOutput.get('allRecipients');
        if (allRecipients == null) {
            allRecipients = new List<Object>();
        }
        
        Map<String, Object> selectedRecipient = new Map<String, Object>();
        selectedRecipient.put('recipientId', 'test123');
        selectedRecipient.put('recipientName', 'Test User');
        selectedRecipient.put('recipientEmail', 'test@example.com');
        
        String methodName = 'getDocuSignData';
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('contractId', c.Id);
        inputMap.put('selectedRecipient', selectedRecipient);
        inputMap.put('allRecipients', allRecipients);
        inputMap.put('dependentCount', '1');
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        DS.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        
        System.assert(outputMap.containsKey('subject'), 'Should have subject');
        String subject = (String)outputMap.get('subject');
        System.assert(subject.contains('Spin Off'), 'Subject should mention Spin Off');
    }

    @isTest
    static void getNewEnvelopeIdTest() {
        Contract c = [SELECT Id, AccountId FROM Contract LIMIT 1];
        c.vlocity_ins__LastDocuSignEnvelopeId__c = '123456';
        update c;

        String methodName = 'getNewEnvelopeId';
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('contractId', c.Id);
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        ARC_DocuSignResendController DS = new ARC_DocuSignResendController();
        DS.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        
        System.assert(outputMap.containsKey('envelopeId'), 'There should be an envelopeId key');
        System.assertEquals('123456', outputMap.get('envelopeId'), 'Envelope ID should match');
    }

    @isTest
    static void voidOldEnvelopeTest() {
        String methodName = 'voidOldEnvelope';
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('oldEnvelopeId', 'test-envelope-123');
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        ARC_DocuSignResendController DS = new ARC_DocuSignResendController();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HttpCalloutMockImpl());
        Boolean result = DS.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Method should return true');
    }
    
    @isTest
    static void getDocuSignDataWithChildFamilyTest() {
        Account guardianAcc = [SELECT Id, FirstName, LastName, PersonEmail FROM Account WHERE RecordType.DeveloperName = 'ARC_Guardian' LIMIT 1];
        Contract c = [SELECT Id, AccountId, vlocity_ins__EnrollmentCensusId__c, ARC_EffectiveDate__c FROM Contract LIMIT 1];
        c.ARC_Guardian__c = guardianAcc.Id;
        c.ARC_ContractReason__c = 'New Application';
        update c;

        String getAllMethod = 'getAllRecipientList';
        Map<String, Object> getAllInput = new Map<String, Object>();
        getAllInput.put('contractId', c.Id);
        Map<String, Object> getAllOutput = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        ARC_DocuSignResendController DS = new ARC_DocuSignResendController();
        DS.invokeMethod(getAllMethod, getAllInput, getAllOutput, options);
        
        List<Object> allRecipients = (List<Object>)getAllOutput.get('allRecipients');
        if (allRecipients == null) {
            allRecipients = new List<Object>();
        }
        
        Map<String, Object> selectedRecipient = new Map<String, Object>();
        selectedRecipient.put('recipientId', 'test123');
        selectedRecipient.put('recipientName', 'Test User');
        selectedRecipient.put('recipientEmail', 'test@example.com');
        
        String methodName = 'getDocuSignData';
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('contractId', c.Id);
        inputMap.put('selectedRecipient', selectedRecipient);
        inputMap.put('allRecipients', allRecipients);
        inputMap.put('dependentCount', '1');
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        DS.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        
        System.assert(outputMap.containsKey('guardianInfo'), 'Should contain guardian info for child family');
    }
    
    @isTest
    static void getDocuSignDataWithAddMemberTest() {
        Contract c = [SELECT Id, AccountId, vlocity_ins__EnrollmentCensusId__c, ARC_EffectiveDate__c FROM Contract LIMIT 1];
        
        Contract expiredContract = new Contract(
            Name='Expired Contract Add Member',
            AccountId = c.AccountId,
            Status = 'Draft',
            vlocity_ins__EnrollmentCensusId__c = c.vlocity_ins__EnrollmentCensusId__c,
            ARC_ContractReason__c = 'New Application',
            ARC_EffectiveDate__c = c.ARC_EffectiveDate__c.addDays(-30)
        );
        insert expiredContract;
        
        c.ARC_ContractReason__c = 'Add Member';
        c.vlocity_ins__ExpiredContractId__c = expiredContract.Id;
        update c;

        String getAllMethod = 'getAllRecipientList';
        Map<String, Object> getAllInput = new Map<String, Object>();
        getAllInput.put('contractId', c.Id);
        Map<String, Object> getAllOutput = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        ARC_DocuSignResendController DS = new ARC_DocuSignResendController();
        DS.invokeMethod(getAllMethod, getAllInput, getAllOutput, options);
        
        List<Object> allRecipients = (List<Object>)getAllOutput.get('allRecipients');
        if (allRecipients == null) {
            allRecipients = new List<Object>();
        }
        
        Map<String, Object> selectedRecipient = new Map<String, Object>();
        selectedRecipient.put('recipientId', 'test123');
        selectedRecipient.put('recipientName', 'Test User');
        selectedRecipient.put('recipientEmail', 'test@example.com');
        
        String methodName = 'getDocuSignData';
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('contractId', c.Id);
        inputMap.put('selectedRecipient', selectedRecipient);
        inputMap.put('allRecipients', allRecipients);
        inputMap.put('dependentCount', '2');
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        DS.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        
        System.assert(outputMap.containsKey('isProgramChange'), 'Should identify as program change for Add Member');
    }
    
    private class HttpCalloutMockImpl implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"envelopeId":"test-envelope-123"}');
            return response;
        }
    }
}