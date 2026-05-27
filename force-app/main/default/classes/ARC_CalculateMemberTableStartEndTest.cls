@isTest
public class ARC_CalculateMemberTableStartEndTest {

    @testSetup
    static void setupData() {
        // Create Person Account RecordType
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account a = new Account(Name='TestAccount');
        insert a;
        // Create Person Account
        Account pa = new Account(
            RecordTypeId = accRecordTypeId,
            LastName = 'Test Member',
            PersonEmail = 'test@example.com',
            PersonBirthdate = Date.today().addYears(-30),
            ARC_IsPrimaryMember__c = true,
            vlocity_ins__SocialSecurityNumber__pc = '123456789',
            //vlocity_ins__Age__pc = 30,
            IsActive = true,
            ARC_DependentRelationship__c = 'Spouse',
            ARC_GroupAccount__c = a.Id
        );
        Account pa2 = new Account(
            RecordTypeId = accRecordTypeId,
            LastName = 'Test Member 2',
            PersonEmail = 'test@example.com',
            PersonBirthdate = Date.today().addYears(-30),
            ARC_IsPrimaryMember__c = true,
            vlocity_ins__SocialSecurityNumber__pc = '123456789',
            //vlocity_ins__Age__pc = 30,
            IsActive = true,
            ARC_DependentRelationship__c = 'Spouse',
            ARC_GroupAccount__c = a.Id
        );
        List<Account> accounts = new List<Account>{pa, pa2};
        insert accounts;

        vlocity_ins__GroupCensus__c groupCensus = new vlocity_ins__GroupCensus__c();
        groupCensus.vlocity_ins__GroupId__c = a.Id;
        groupCensus.Name = 'Group Census Test';
        groupCensus.ARC_PrimaryAccount__c = pa.Id;

        insert groupCensus; 

        Contact[] c = [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accounts];

        vlocity_ins__GroupCensusMember__c censusMember1 = new vlocity_ins__GroupCensusMember__c();  
        censusMember1.vlocity_ins__LastName__c = 'Test Member';
        censusMember1.vlocity_ins__CensusId__c = groupCensus.Id;
        censusMember1.vlocity_ins__ContactId__c = c[0].Id;
        censusMember1.ARC_ActiveMember__c = true;

        vlocity_ins__GroupCensusMember__c censusMember2 = new vlocity_ins__GroupCensusMember__c();  
        censusMember2.vlocity_ins__LastName__c = 'Test Member 2';
        censusMember2.vlocity_ins__CensusId__c = groupCensus.Id;
        censusMember2.vlocity_ins__ContactId__c = c[1].Id;
        censusMember2.ARC_ActiveMember__c = true;

        List<vlocity_ins__GroupCensusMember__c> censusMembers = new List<vlocity_ins__GroupCensusMember__c>{censusMember1, censusMember2};
        insert censusMembers;

        pa.ARC_Census__c = groupCensus.Id;
        pa.ARC_CensusMember__pc = censusMember1.Id;
        pa2.ARC_Census__c = groupCensus.Id;
        pa2.ARC_CensusMember__pc = censusMember2.Id;

        List<Account> accountsUpdate = new List<Account>{pa, pa2};

        update accountsUpdate;

        List<Contract> contracts = ARC_TestUtility.createContractsAA(1);
        insert contracts;
        Contract contract = contracts[0];
        
        contract.ARC_EffectiveDate__c = Date.today().addDays(-10);
        contract.ARC_Inactive_Date__c = Date.today().addDays(365);
        contract.AccountId = a.Id;
        contract.StartDate = Date.today().addDays(-10);
        contract.vlocity_ins__EnrollmentCensusId__c = groupCensus.Id;
        update contract;
        contract.Status = 'Activated';
        update contract;

        // Create InsurancePolicy related to Contract
        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Test Policy',
            ARC_Contract__c = contract.Id,
            NameInsuredId = a.Id
        );
        insert policy;

        // Create InsurancePolicyParticipant
        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            PrimaryParticipantContactId = c[0].Id,
            ARC_StartDate__c = Date.today().addDays(-100),
            ARC_EndDate__c = Date.today().addDays(100),
            Role = 'Dependent'
        );
        InsurancePolicyParticipant ipp2 = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            PrimaryParticipantContactId = c[1].Id,
            ARC_StartDate__c = Date.today().addDays(-100),
            ARC_EndDate__c = Date.today().addDays(100),
            Role = 'Dependent'
        );
        List<InsurancePolicyParticipant> ipps = new List<InsurancePolicyParticipant>{ipp, ipp2};
        insert ipps;

        // Create Product2 (Medical)
        Product2 prod = new Product2(
            Name = 'Medical Plan',
            IsActive = true,
            vlocity_ins__Type__c = 'Medical',
            vlocity_ins__SubType__c = 'SMART'
        );
        Product2 prod2 = new Product2(
            Name = 'Medical Plan 2',
            IsActive = true,
            vlocity_ins__Type__c = 'Medical',
            vlocity_ins__SubType__c = 'AIDD'
        );
        List<Product2> products = new List<Product2>{prod, prod2};
        insert products;

        // Create InsurancePolicyCoverage (custom object, assumed)
        InsurancePolicyCoverage policyCoverage = new InsurancePolicyCoverage(
            vlocity_ins_fsc__Product2Id__c = products[0].Id,
            InsurancePolicyId = policy.Id
        );
        InsurancePolicyCoverage policyCoverage2 = new InsurancePolicyCoverage(
            vlocity_ins_fsc__Product2Id__c = products[1].Id,
            InsurancePolicyId = policy.Id
        );
        List<InsurancePolicyCoverage> policyCoverages = new List<InsurancePolicyCoverage>{policyCoverage, policyCoverage2};
        insert policyCoverages;

        // Create ARC_CoverageParticipant__c
        ARC_CoverageParticipant__c cp = new ARC_CoverageParticipant__c(
            ARC_Policy__c = policy.Id,
            ARC_PolicyParticipant__c = ipps[0].Id,
            ARC_PolicyCoverage__c = policyCoverages[0].Id
        );
        ARC_CoverageParticipant__c cp2 = new ARC_CoverageParticipant__c(
            ARC_Policy__c = policy.Id,
            ARC_PolicyParticipant__c = ipps[1].Id,
            ARC_PolicyCoverage__c = policyCoverages[1].Id
        );
        List<ARC_CoverageParticipant__c> cps = new List<ARC_CoverageParticipant__c>{cp, cp2};
        insert cps;
    }

    @isTest
    static void testCalculateDatesPerMemberAndProgram() {
        // Get the Person Account Id
        Account pa = [SELECT Id, ARC_Census__c, isActive FROM Account WHERE LastName = 'Test Member' LIMIT 1];
        pa.isActive = true;
        update pa;

        // Call the method
        Test.startTest();
        List<Map<Id, Object>> result = ARC_CalculateMemberTableStartEndDates.calculateDatesPerMemberAndProgram(pa.Id);
        Test.stopTest();

        // Basic assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() == 3, 'Result should have 3 maps (coverages, initial dates, end dates)');

        // Check that the maps contain the expected keys
        Map<Id, Object> coverages = (Map<Id, Object>)result[0];
        Map<Id, Object> initialDates = (Map<Id, Object>)result[1];
        Map<Id, Object> endDates = (Map<Id, Object>)result[2];

        System.assert(!coverages.isEmpty(), 'Coverages map should not be empty');
        System.assert(!initialDates.isEmpty(), 'Initial dates map should not be empty');
        System.assert(!endDates.isEmpty(), 'End dates map should not be empty');
    }

    @isTest
    static void testCalculateDatesPerMemberAndProgramSG() {
        // Get the Person Account Id
        // Create Person Account RecordType
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_SGPersonAccount').getRecordTypeId();
        Account a = new Account(Name='TestAccount');
        insert a;
        // Create Person Account
        Account paSG = new Account(
            RecordTypeId = accRecordTypeId,
            LastName = 'Test Member',
            PersonEmail = 'test@example.com',
            PersonBirthdate = Date.today().addYears(-30),
            ARC_IsPrimaryMember__c = true,
            vlocity_ins__SocialSecurityNumber__pc = '123456781',
            //vlocity_ins__Age__pc = 30,
            IsActive = true,
            ARC_DependentRelationship__c = 'Spouse',
            ARC_GroupAccount__c = a.Id
        );
        insert paSG;

        // Call the method
        Test.startTest();
        List<Map<Id, Object>> result = ARC_CalculateMemberTableStartEndDates.calculateDatesPerMemberAndProgram(paSG.Id);
        Test.stopTest();
    }

    @isTest
    static void testCalculateDates_GapsAndDifferentProducts() {
        Account pa = [SELECT Id, PersonContactId, ARC_Census__c FROM Account WHERE LastName = 'Test Member' LIMIT 1];
        pa.IsActive = true;
        update pa;

        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        Product2 prodMedical = [SELECT Id FROM Product2 WHERE vlocity_ins__SubType__c = 'SMART' LIMIT 1];
        Product2 prodAidd = [SELECT Id FROM Product2 WHERE vlocity_ins__SubType__c = 'AIDD' LIMIT 1];

        Date baseDate = Date.today().addDays(-100);

            List<Contract> testContracts = ARC_TestUtility.createContractsAA(4);
            insert testContracts;

            testContracts[0].AccountId = pa.Id;
            testContracts[0].ARC_EffectiveDate__c = baseDate;
            testContracts[0].StartDate = baseDate;

            testContracts[1].AccountId = pa.Id;
            testContracts[1].ARC_EffectiveDate__c = baseDate.addDays(32);
            testContracts[1].StartDate = baseDate.addDays(32);

            testContracts[2].AccountId = pa.Id;
            testContracts[2].ARC_EffectiveDate__c = baseDate.addDays(65);
            testContracts[2].StartDate = baseDate.addDays(65);

            testContracts[3].AccountId = pa.Id;
            testContracts[3].ARC_EffectiveDate__c = baseDate.addDays(100);
            testContracts[3].StartDate = baseDate.addDays(100);

            update testContracts;

            for(Contract c : testContracts) {
                c.Status = 'Activated';
            }
            update testContracts;

            List<InsurancePolicy> testPolicies = new List<InsurancePolicy>{
                new InsurancePolicy(Name='Pol Base', ARC_Contract__c=testContracts[0].Id, NameInsuredId=pa.Id),
                new InsurancePolicy(Name='Pol No Gap', ARC_Contract__c=testContracts[1].Id, NameInsuredId=pa.Id),
                new InsurancePolicy(Name='Pol With Gap', ARC_Contract__c=testContracts[2].Id, NameInsuredId=pa.Id),
                new InsurancePolicy(Name='Pol Diff Prod', ARC_Contract__c=testContracts[3].Id, NameInsuredId=pa.Id)
            };
            insert testPolicies;

        List<InsurancePolicyParticipant> ipps = new List<InsurancePolicyParticipant>{
            new InsurancePolicyParticipant(InsurancePolicyId=testPolicies[0].Id, PrimaryParticipantContactId=pa.PersonContactId, Role='Primary', ARC_StartDate__c=baseDate, ARC_EndDate__c=baseDate.addDays(30)),
            new InsurancePolicyParticipant(InsurancePolicyId=testPolicies[1].Id, PrimaryParticipantContactId=pa.PersonContactId, Role='Primary', ARC_StartDate__c=baseDate.addDays(32), ARC_EndDate__c=baseDate.addDays(60)),
            new InsurancePolicyParticipant(InsurancePolicyId=testPolicies[2].Id, PrimaryParticipantContactId=pa.PersonContactId, Role='Primary', ARC_StartDate__c=baseDate.addDays(65), ARC_EndDate__c=baseDate.addDays(90)),
            new InsurancePolicyParticipant(InsurancePolicyId=testPolicies[3].Id, PrimaryParticipantContactId=pa.PersonContactId, Role='Primary', ARC_StartDate__c=baseDate.addDays(100), ARC_EndDate__c=baseDate.addDays(130))
        };
        insert ipps;

        List<InsurancePolicyCoverage> coverages = new List<InsurancePolicyCoverage>{
            new InsurancePolicyCoverage(vlocity_ins_fsc__Product2Id__c=prodMedical.Id, InsurancePolicyId=testPolicies[0].Id),
            new InsurancePolicyCoverage(vlocity_ins_fsc__Product2Id__c=prodMedical.Id, InsurancePolicyId=testPolicies[1].Id),
            new InsurancePolicyCoverage(vlocity_ins_fsc__Product2Id__c=prodMedical.Id, InsurancePolicyId=testPolicies[2].Id),
            new InsurancePolicyCoverage(vlocity_ins_fsc__Product2Id__c=prodAidd.Id, InsurancePolicyId=testPolicies[3].Id)
        };
        insert coverages;

        List<ARC_CoverageParticipant__c> cps = new List<ARC_CoverageParticipant__c>{
            new ARC_CoverageParticipant__c(ARC_Policy__c=testPolicies[0].Id, ARC_PolicyParticipant__c=ipps[0].Id, ARC_PolicyCoverage__c=coverages[0].Id),
            new ARC_CoverageParticipant__c(ARC_Policy__c=testPolicies[1].Id, ARC_PolicyParticipant__c=ipps[1].Id, ARC_PolicyCoverage__c=coverages[1].Id),
            new ARC_CoverageParticipant__c(ARC_Policy__c=testPolicies[2].Id, ARC_PolicyParticipant__c=ipps[2].Id, ARC_PolicyCoverage__c=coverages[2].Id),
            new ARC_CoverageParticipant__c(ARC_Policy__c=testPolicies[3].Id, ARC_PolicyParticipant__c=ipps[3].Id, ARC_PolicyCoverage__c=coverages[3].Id)
        };
        insert cps;

        Test.startTest();
        List<Map<Id, Object>> result = ARC_CalculateMemberTableStartEndDates.calculateDatesPerMemberAndProgram(pa.Id);
        Test.stopTest();
    }
}