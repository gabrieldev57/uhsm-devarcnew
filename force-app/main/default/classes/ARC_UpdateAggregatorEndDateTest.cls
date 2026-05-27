@isTest
private class ARC_UpdateAggregatorEndDateTest {

    @TestSetup
    static void makeData() {        
        List<Contract> contracts = ARC_TestUtility.createContractsAA(4);
        
        Contract activatedContract = contracts[0];
        Contract terminatedContract = contracts[1];
        Contract activatedContractSG = contracts[2];
        Contract terminatedContractSG = contracts[3];
        
        insert contracts;

        // Individual and Family
        activatedContract.Status = 'Activated';
        
        terminatedContract.Status = 'Terminated';
        terminatedContract.ARC_Inactive_Date__c = Date.newInstance(2026, 12, 30);

        // Small Group
        activatedContractSG.Status = 'Activated';
        activatedContractSG.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();

        terminatedContractSG.Status = 'Terminated';
        terminatedContractSG.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        
        update contracts;

        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();

        Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount', LastName ='Test');
        acc.BillingStreet = '123 Avenue';
        acc.BillingState = 'NY';
        acc.BillingCity = 'New York';
        acc.BillingPostalCode='12345';
        acc.PersonEmail='test@email.com';
        acc.ARC_IsPrimaryMember__c = true;
        acc.ARC_E123MemberIdFromPolicy__c = 'W123456789';
        acc.IsActive = true;
        acc.ARC_GroupAccount__c = contracts[0].AccountId;
        acc.PersonBirthdate = Date.newInstance(2000, 1, 1);

        insert acc;

        Account accountContact = [SELECT PersonContactId FROM Account WHERE Id = :acc.Id LIMIT 1];

        InsurancePolicy activePolicy = new InsurancePolicy(
            Name = 'Active Policy I&F',
            NameInsuredId = contracts[0].AccountId,
            ARC_Contract__c = activatedContract.Id,
            Status = 'Activated'
        );
        
        InsurancePolicy terminatedPolicy = new InsurancePolicy(
            Name = 'Terminated Policy I&F',
            NameInsuredId = contracts[0].AccountId,
            ARC_Contract__c = terminatedContract.Id,
            Status = 'Terminated'
        );

        InsurancePolicy activePolicySG = new InsurancePolicy(
            Name = 'Active Policy SG',
            NameInsuredId = contracts[0].AccountId,
            ARC_Contract__c = activatedContractSG.Id,
            Status = 'Activated'
        );

        InsurancePolicy terminatedPolicySG = new InsurancePolicy(
            Name = 'Terminated Policy SG',
            NameInsuredId = contracts[0].AccountId,
            ARC_Contract__c = terminatedContractSG.Id,
            Status = 'Terminated',
            ARC_PolicyExpirationDate__c = Date.newInstance(2026, 12, 30)
        );

        insert new List<InsurancePolicy>{ activePolicy, terminatedPolicy, activePolicySG, terminatedPolicySG };

        InsurancePolicyParticipant policyParticipantActivated = new InsurancePolicyParticipant(
            Role = 'Primary',
            InsurancePolicyId = activePolicy.Id,
            PrimaryParticipantContactId = accountContact.PersonContactId
        );

        InsurancePolicyParticipant policyParticipantTerminated = new InsurancePolicyParticipant(
            Role = 'Primary',
            InsurancePolicyId = terminatedPolicy.Id,
            PrimaryParticipantContactId = accountContact.PersonContactId
        );

        InsurancePolicyParticipant policyParticipantActivatedSG = new InsurancePolicyParticipant(
            Role = 'Primary',
            InsurancePolicyId = activePolicySG.Id,
            PrimaryParticipantContactId = accountContact.PersonContactId
        );

        InsurancePolicyParticipant policyParticipantTerminatedSG = new InsurancePolicyParticipant(
            Role = 'Primary',
            InsurancePolicyId = terminatedPolicySG.Id,
            PrimaryParticipantContactId = accountContact.PersonContactId
        );

        insert new List<InsurancePolicyParticipant>{ policyParticipantActivated, policyParticipantTerminated, policyParticipantActivatedSG, policyParticipantTerminatedSG };

        Id aggregatorIndividualRecordType = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        ARC_Aggregator__c aggActivatedIandF = new ARC_Aggregator__c(
            Name = 'Aggregator Activated I&F',
            //ARC_Year__c = String.valueOf(Date.Today().year()),
            ARC_Year__c = '2026',
            RecordTypeId = aggregatorIndividualRecordType,
            //ARC_EndDate__c = Date.newInstance(Date.Today().year(), 1, 1)
            ARC_EndDate__c = Date.newInstance(2026, 1, 1)
        );

        ARC_Aggregator__c aggTerminatedIandF = new ARC_Aggregator__c(
            Name = 'Aggregator Terminated I&F',
            //ARC_Year__c = String.valueOf(Date.Today().year()),
            ARC_Year__c = '2026',
            RecordTypeId = aggregatorIndividualRecordType,
            //ARC_EndDate__c = Date.newInstance(Date.Today().year(), 1, 1)
            ARC_EndDate__c = Date.newInstance(2026, 1, 1)
        );

        ARC_Aggregator__c aggActivatedSG = new ARC_Aggregator__c(
            Name = 'Aggregator Activated SG',
            //ARC_Year__c = String.valueOf(Date.Today().year()),
            ARC_Year__c = '2026',
            RecordTypeId = aggregatorIndividualRecordType,
            //ARC_EndDate__c = Date.newInstance(Date.Today().year(), 1, 1)
            ARC_EndDate__c = Date.newInstance(2026, 1, 1)
        );

        ARC_Aggregator__c aggTerminatedSG = new ARC_Aggregator__c(
            Name = 'Aggregator Terminated SG',
            //ARC_Year__c = String.valueOf(Date.Today().year()),
            ARC_Year__c = '2026',
            RecordTypeId = aggregatorIndividualRecordType,
            //ARC_EndDate__c = Date.newInstance(Date.Today().year(), 1, 1)
            ARC_EndDate__c = Date.newInstance(2026, 1, 1)
        );

        insert new List<ARC_Aggregator__c>{ aggActivatedIandF, aggTerminatedIandF, aggActivatedSG, aggTerminatedSG };

        ARC_ParticipantAggregator__c pa1 = new ARC_ParticipantAggregator__c(
            ARC_Aggregator__c = aggActivatedIandF.Id,
            ARC_Policy__c = activePolicy.Id,
            ARC_PolicyParticipant__c = policyParticipantActivated.Id
        );

        ARC_ParticipantAggregator__c pa2 = new ARC_ParticipantAggregator__c(
            ARC_Aggregator__c = aggTerminatedIandF.Id,
            ARC_Policy__c = terminatedPolicy.Id,
            ARC_PolicyParticipant__c = policyParticipantTerminated.Id
        );

        ARC_ParticipantAggregator__c pa3 = new ARC_ParticipantAggregator__c(
            ARC_Aggregator__c = aggActivatedSG.Id,
            ARC_Policy__c = activePolicySG.Id,
            ARC_PolicyParticipant__c = policyParticipantActivatedSG.Id
        );
        
        ARC_ParticipantAggregator__c pa4 = new ARC_ParticipantAggregator__c(
            ARC_Aggregator__c = aggTerminatedSG.Id,
            ARC_Policy__c = terminatedPolicySG.Id,
            ARC_PolicyParticipant__c = policyParticipantTerminatedSG.Id
        );

        insert new List<ARC_ParticipantAggregator__c>{ pa1, pa2, pa3, pa4 };
    }

    @IsTest
    static void testActivatedOverridesEndDate() {
        ARC_Aggregator__c agg = [
            SELECT Id
            FROM ARC_Aggregator__c
            WHERE Name = 'Aggregator Activated SG'
            LIMIT 1
        ];

        List<List<Id>> input = new List<List<Id>>{
            new List<Id>{ agg.Id }
        };

        Test.startTest();
        ARC_UpdateAggregatorEndDate.updateEndDate(input);
        Test.stopTest();

        ARC_Aggregator__c updatedAgg = [
            SELECT ARC_EndDate__c
            FROM ARC_Aggregator__c
            WHERE Id = :agg.Id
        ];

        Assert.areEqual(null, updatedAgg.ARC_EndDate__c, 'EndDate must be null when there is an Activated contract');
    }

    @IsTest
    static void testActivatedOverridesEndDatePreviousYearAgg() {
        ARC_Aggregator__c agg = [
            SELECT Id
            FROM ARC_Aggregator__c
            WHERE Name = 'Aggregator Activated SG'
            LIMIT 1
        ];

        agg.ARC_Year__c = '2025';
        update agg;

        List<List<Id>> input = new List<List<Id>>{
            new List<Id>{ agg.Id }
        };

        Test.startTest();
        ARC_UpdateAggregatorEndDate.updateEndDate(input);
        Test.stopTest();

        ARC_Aggregator__c updatedAgg = [
            SELECT ARC_EndDate__c
            FROM ARC_Aggregator__c
            WHERE Id = :agg.Id
        ];

        Assert.areEqual(Date.newInstance(Integer.valueOf(agg.ARC_Year__c), 12, 31), updatedAgg.ARC_EndDate__c, 'EndDate must be null when there is an Activated contract');
    }

    @IsTest
    static void testTerminatedOverridesEndDatePreviousYearAgg() {
        ARC_Aggregator__c agg = [
            SELECT Id
            FROM ARC_Aggregator__c
            WHERE Name = 'Aggregator Terminated SG'
            LIMIT 1
        ];

        agg.ARC_Year__c = '2025';
        update agg;

        List<List<Id>> input = new List<List<Id>>{
            new List<Id>{ agg.Id }
        };

        Test.startTest();
        ARC_UpdateAggregatorEndDate.updateEndDate(input);
        Test.stopTest();

        ARC_Aggregator__c updatedAgg = [
            SELECT ARC_EndDate__c
            FROM ARC_Aggregator__c
            WHERE Id = :agg.Id
        ];

        Assert.areEqual(Date.newInstance(Integer.valueOf(agg.ARC_Year__c), 12, 31), updatedAgg.ARC_EndDate__c, 'EndDate must be null when there is an Activated contract');
    }

    @IsTest
    static void testTerminatedSetsEndDate() {

        ARC_Aggregator__c agg = [
            SELECT Id
            FROM ARC_Aggregator__c
            WHERE Name = 'Aggregator Terminated I&F'
            LIMIT 1
        ];

        List<List<Id>> input = new List<List<Id>>{
            new List<Id>{ agg.Id }
        };

        Test.startTest();
        ARC_UpdateAggregatorEndDate.updateEndDate(input);
        Test.stopTest();

        ARC_Aggregator__c updatedAgg = [
            SELECT ARC_EndDate__c
            FROM ARC_Aggregator__c
            WHERE Id = :agg.Id
        ];

        //Assert.areEqual(Date.Today(), updatedAgg.ARC_EndDate__c, 'EndDate should be inactive date when only Terminated contracts exist');
        Assert.areEqual(Date.newInstance(2026, 12, 30), updatedAgg.ARC_EndDate__c, 'EndDate should be inactive date when only Terminated contracts exist');
    }

    @isTest
    static void testActivatedOverridesEndDateForSmallGroup() {
        ARC_Aggregator__c agg = [
            SELECT Id
            FROM ARC_Aggregator__c
            WHERE Name = 'Aggregator Activated SG'
            LIMIT 1
        ];

        List<List<Id>> input = new List<List<Id>>{
            new List<Id>{ agg.Id }
        };

        Test.startTest();
        ARC_UpdateAggregatorEndDate.updateEndDate(input);
        Test.stopTest();

        ARC_Aggregator__c updatedAgg = [
            SELECT ARC_EndDate__c
            FROM ARC_Aggregator__c
            WHERE Id = :agg.Id
        ];

        Assert.areEqual(null, updatedAgg.ARC_EndDate__c, 'EndDate must be null when there is an Activated contract');
    }

    @IsTest
    static void testTerminatedSetsEndDateForSmallGroup() {

        ARC_Aggregator__c agg = [
            SELECT Id
            FROM ARC_Aggregator__c
            WHERE Name = 'Aggregator Terminated SG'
            LIMIT 1
        ];

        List<List<Id>> input = new List<List<Id>>{
            new List<Id>{ agg.Id }
        };

        Test.startTest();
        ARC_UpdateAggregatorEndDate.updateEndDate(input);
        Test.stopTest();

        ARC_Aggregator__c updatedAgg = [
            SELECT ARC_EndDate__c
            FROM ARC_Aggregator__c
            WHERE Id = :agg.Id
        ];

        //Assert.areEqual(Date.Today(), updatedAgg.ARC_EndDate__c, 'EndDate should be inactive date when only Terminated contracts exist');
        Assert.areEqual(Date.newInstance(2026, 12, 30), updatedAgg.ARC_EndDate__c, 'EndDate should be inactive date when only Terminated contracts exist');
    }

    
}