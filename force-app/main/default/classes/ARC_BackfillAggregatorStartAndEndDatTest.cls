@isTest
private class ARC_BackfillAggregatorStartAndEndDatTest {

    @TestSetup
    static void makeData() {        
       List<Contract> contracts = ARC_TestUtility.createContractsAA(2);
        
        Contract terminatedContract = contracts[0];
        Contract activatedContract = contracts[1];
        
        insert contracts;
        
        terminatedContract.Status = 'Terminated';
        terminatedContract.ARC_Inactive_Date__c = Date.Today();
        terminatedContract.ARC_EffectiveDate__c = Date.newInstance(2025, 1, 1);
        terminatedContract.ARC_Inactive_Date__c = Date.newInstance(2025, 12, 30);
        
        activatedContract.ARC_EffectiveDate__c = Date.newInstance(2026, 1, 1);
        activatedContract.Status = 'Activated';
        
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
            Name = 'Active Policy',
            NameInsuredId = contracts[0].AccountId,
            ARC_Contract__c = activatedContract.Id
        );

        InsurancePolicy terminatedPolicy = new InsurancePolicy(
            Name = 'Terminated Policy',
            NameInsuredId = contracts[0].AccountId,
            ARC_Contract__c = terminatedContract.Id
        );

        insert new List<InsurancePolicy>{ activePolicy, terminatedPolicy };

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

        insert new List<InsurancePolicyParticipant>{ policyParticipantActivated, policyParticipantTerminated };

        ARC_Aggregator__c oneTimeAgg_MostRecient = new ARC_Aggregator__c(
            Name = 'OneTime Agg',
            ARC_Code__c = 'CCS__c',
            ARC_Member__c = acc.Id,
            ARC_CreatedIn__c = terminatedPolicy.Id
        );

        ARC_Aggregator__c oneTimeAgg = new ARC_Aggregator__c(
            Name = 'OneTime Agg',
            ARC_Code__c = 'CCS__c',
            ARC_Member__c = acc.Id,
            ARC_CreatedIn__c = terminatedPolicy.Id
        );

        ARC_Aggregator__c AMCS1 = new ARC_Aggregator__c(
            Name = 'Aggregator Activated',
            ARC_Year__c = '2026',
            ARC_Code__c = 'AMCS__c',
            ARC_Member__c = acc.Id,
            ARC_CreatedIn__c = terminatedPolicy.Id
            );

        ARC_Aggregator__c AMCS2 = new ARC_Aggregator__c(
            Name = 'Aggregator Terminated',
            ARC_Year__c = '2026',
            ARC_Code__c = 'AMCS_c',
            ARC_Member__c = acc.Id,
            ARC_CreatedIn__c = activePolicy.Id
        );

        ARC_Aggregator__c standAloneAgg = new ARC_Aggregator__c(
            Name = 'StandAlone Terminated',
            ARC_Year__c = '2026',
            ARC_Code__c = 'AMCS_c',
            ARC_Member__c = acc.Id,
            ARC_CreatedIn__c = activePolicy.Id
        );

        ARC_Aggregator__c famAgg1 = new ARC_Aggregator__c(
            Name = 'Family AMCS',
            //ARC_Year__c = String.valueOf(Date.Today().year()),
            ARC_Year__c = '2026',
            //ARC_EndDate__c = Date.newInstance(Date.Today().year(), 1, 1)
            ARC_CreatedIn__c = terminatedPolicy.Id
        );
        ARC_Aggregator__c famAgg2 = new ARC_Aggregator__c(
            Name = 'Family AMCS',
            //ARC_Year__c = String.valueOf(Date.Today().year()),
            ARC_Year__c = '2026',
            ARC_CreatedIn__c = activePolicy.Id
            //ARC_EndDate__c = Date.newInstance(Date.Today().year(), 1, 1)
        );

        insert new List<ARC_Aggregator__c>{ standAloneAgg, oneTimeAgg_MostRecient, oneTimeAgg, AMCS1, AMCS2, famAgg1, famAgg2 };

        AMCS1.ARC_FamilyAggregator__c = famAgg1.Id;
        AMCS2.ARC_FamilyAggregator__c = famAgg2.Id;
        update new List<ARC_Aggregator__c>{AMCS1, AMCS2};

        ARC_ParticipantAggregator__c paOTinact_MostRecient = new ARC_ParticipantAggregator__c(
            ARC_Aggregator__c = oneTimeAgg_MostRecient.Id,
            ARC_Policy__c = terminatedPolicy.Id,
            ARC_PolicyParticipant__c = policyParticipantTerminated.Id
        );
        ARC_ParticipantAggregator__c paOTinact = new ARC_ParticipantAggregator__c(
            ARC_Aggregator__c = oneTimeAgg.Id,
            ARC_Policy__c = terminatedPolicy.Id,
            ARC_PolicyParticipant__c = policyParticipantTerminated.Id
        );
        ARC_ParticipantAggregator__c paOTact = new ARC_ParticipantAggregator__c(
            ARC_Aggregator__c = oneTimeAgg.Id,
            ARC_Policy__c = activePolicy.Id,
            ARC_PolicyParticipant__c = policyParticipantActivated.Id
        );

        ARC_ParticipantAggregator__c pa1 = new ARC_ParticipantAggregator__c(
            ARC_Aggregator__c = AMCS1.Id,
            ARC_Policy__c = terminatedPolicy.Id,
            ARC_PolicyParticipant__c = policyParticipantTerminated.Id
        );

        ARC_ParticipantAggregator__c pa2 = new ARC_ParticipantAggregator__c(
            ARC_Aggregator__c = AMCS2.Id,
            ARC_Policy__c = activePolicy.Id,
            ARC_PolicyParticipant__c = policyParticipantActivated.Id
        );


        insert new List<ARC_ParticipantAggregator__c>{paOTinact_MostRecient, paOTinact, paOTact, pa1, pa2 };
    }

    @isTest
    static void executionTest() {
        List<ARC_Aggregator__c> aggs = [SELECT Id, ARC_StartDate__c, ARC_EndDate__c FROM ARC_Aggregator__c];
        System.debug('MYAGGS:' + aggs);
        for (ARC_Aggregator__c a : aggs){
            a.ARC_StartDate__c = null;
            a.ARC_EndDate__c = null;
        }
        update aggs;
        Test.startTest();
            ARC_BackfillAggregatorStartAndEndDates batch = new ARC_BackfillAggregatorStartAndEndDates(null, true);
            Database.executeBatch(batch);
        Test.stopTest();

        List<ARC_Aggregator__c> aggList = [SELECT Id, ARC_StartDate__c, ARC_EndDate__c FROM ARC_Aggregator__c WHERE ARC_StartDate__c = null];
        System.Assert.areEqual(0, aggList.size());
    }

}