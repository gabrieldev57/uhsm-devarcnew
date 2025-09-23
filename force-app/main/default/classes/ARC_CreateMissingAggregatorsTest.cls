@isTest
private class ARC_CreateMissingAggregatorsTest {

    @testSetup
    static void makeData() {
        // Insert Accounts
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount '+ i, LastName = 'Test');
            acc.BillingStreet = '123 Avenue';
            acc.BillingState = 'NY';
            acc.BillingCity = 'New York';
            acc.BillingPostalCode = '12345';
            acc.PersonEmail = 'test@email.com';
            acc.ARC_IsPrimaryMember__c = true;
            acc.ARC_E123MemberIdFromPolicy__c = 'W123456789';
            acc.IsActive = true;
            accounts.add(acc);
        }
        insert accounts;

        List<Contract> contract = ARC_TestUtility.createContractsAA(2);
        insert contract;

        contract[0].Status = 'Terminated';
        contract[0].ARC_ContractReason__c = 'Program Upgrade';
        contract[0].ARC_EffectiveDate__c = Date.valueOf('2021-11-12');
        contract[0].ARC_Inactive_Date__c = Date.valueOf('2022-11-12');
        contract[1].Status = 'Terminated';
        contract[1].ARC_ContractReason__c = 'Remove Member';
        contract[1].ARC_EffectiveDate__c = Date.valueOf('2022-11-12');
        contract[1].ARC_Inactive_Date__c = Date.valueOf('2022-12-12');
        contract[1].vlocity_ins__ExpiredContractId__c = contract[0].Id;
        update contract;

        List<Product2> prodList = new List<Product2>();
        Product2 prod1 = new Product2();
        prod1.Name = 'WeShare 6k ';
        prod1.ProductCode = 'PROG_UHSM_WeShare6k';
        prod1.vlocity_ins__Type__c = 'Medical';
        Product2 prod2 = new Product2();
        prod2.Name = 'WeShare 12k ';
        prod2.ProductCode = 'PROG_UHSM_WeShare12k';
        prod2.vlocity_ins__Type__c = 'Medical';
        prodList.add(prod1);
        prodList.add(prod2);
        insert prodList;

        List<InsurancePolicy> policies = new List<InsurancePolicy>();
        for (Integer i = 0; i < 2; i++) {
            InsurancePolicy policy = new InsurancePolicy();
            policy.Name = 'Policy ' + i;
            policy.ProductId = prodList[i].Id;
            policy.ARC_Contract__c = contract[i].Id;
            policy.NameInsuredId = accounts[0].Id;
            policies.add(policy);
        }
        insert policies;

        policies[1].RenewedFromPolicyId = policies[0].Id;
        update policies;

        List<Account> accountListContactIds = [SELECT Id, PersonContactId FROM Account WHERE FirstName Like 'PersonAccount%' ORDER BY FirstName];

        List<Contact> contacts = new List<Contact>();
        for (Account acc : accountListContactIds) {
            Contact cont = new Contact();
            cont.Id = acc.PersonContactId;
            cont.Birthdate = Date.valueOf('2000-11-12');
            contacts.add(cont);
        }
        update contacts;

        // Insert IPP
        List<InsurancePolicyParticipant> policyParticipants = new List<InsurancePolicyParticipant>();
        InsurancePolicyParticipant ipp1 = new InsurancePolicyParticipant();
        ipp1.Role = 'Primary';
        ipp1.PrimaryParticipantContactId = accountListContactIds[0].PersonContactId;
        ipp1.InsurancePolicyId = policies[0].Id;
        InsurancePolicyParticipant ipp2 = new InsurancePolicyParticipant();
        ipp2.Role = 'Spouse';
        ipp2.PrimaryParticipantContactId = accountListContactIds[1].PersonContactId;
        ipp2.InsurancePolicyId = policies[0].Id;
        InsurancePolicyParticipant ipp3 = new InsurancePolicyParticipant();
        ipp3.Role = 'Primary';
        ipp3.PrimaryParticipantContactId = accountListContactIds[0].PersonContactId;
        ipp3.InsurancePolicyId = policies[1].Id;
        policyParticipants.add(ipp1);
        policyParticipants.add(ipp2);
        policyParticipants.add(ipp3);
        insert policyParticipants;

        // Insert Aggregators
        Id individualAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
        List<ARC_Aggregator__c> aggregators = new List<ARC_Aggregator__c>();
        ARC_Aggregator__c oneTimeAgg = new ARC_Aggregator__c();
        oneTimeAgg.Name = 'Mammograms';
        oneTimeAgg.ARC_Code__c = 'MAMM__c';
        oneTimeAgg.ARC_Type__c = 'Number';
        oneTimeAgg.RecordTypeId = individualAggRT;
        oneTimeAgg.ARC_NextAvailabilityDate__c = Date.today();
        oneTimeAgg.ARC_LimitValue__c = 1;
        oneTimeAgg.ARC_Member__c = accounts[0].Id;
        oneTimeAgg.ARC_CreatedIn__c = policies[0].Id;

        ARC_Aggregator__c individualAgg = new ARC_Aggregator__c();
        individualAgg.Name = 'Maternity';
        individualAgg.ARC_Code__c = 'MAT__c';
        individualAgg.ARC_Type__c = 'Currency';
        individualAgg.RecordTypeId = individualAggRT;
        individualAgg.ARC_LimitValue__c = 15000;
        individualAgg.ARC_Year__c = '2021';
        individualAgg.ARC_Member__c = accounts[0].Id;
        individualAgg.ARC_CreatedIn__c = policies[0].Id;

        aggregators.add(oneTimeAgg);
        aggregators.add(individualAgg);
        insert aggregators;

        // Insert Participant Aggregators
        List<ARC_ParticipantAggregator__c> partAggList = new List<ARC_ParticipantAggregator__c>();
        ARC_ParticipantAggregator__c partAgg1 = new ARC_ParticipantAggregator__c();
        partAgg1.Name = 'Mammograms';
        partAgg1.ARC_Policy__c = policies[0].Id;
        partAgg1.ARC_PolicyParticipant__c = policyParticipants[0].Id;
        partAgg1.ARC_ConsumedValue__c = 0;
        partAgg1.ARC_Aggregator__c = aggregators[0].Id;

        ARC_ParticipantAggregator__c partAgg2 = new ARC_ParticipantAggregator__c();
        partAgg2.Name = 'Maternity';
        partAgg2.ARC_Policy__c = policies[0].Id;
        partAgg2.ARC_PolicyParticipant__c = policyParticipants[0].Id;
        partAgg2.ARC_ConsumedValue__c = 0;
        partAgg2.ARC_Aggregator__c = aggregators[1].Id;

        partAggList.add(partAgg1);
        partAggList.add(partAgg2);
        insert partAggList;
    }

    @isTest
    static void ARC_CreateMissingAggregatorsTrueTest() {
        Test.startTest();
        ARC_CreateMissingAggregators batch = new ARC_CreateMissingAggregators(null, true);
        Database.executeBatch(batch);
        Test.stopTest();

        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c];
        List<ARC_ParticipantAggregator__c> participantAggregators = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Assert.areEqual(52, aggregators.size(), 'Aggregators were not correctly created'); 
        Assert.areEqual(66, participantAggregators.size(), 'Participant Aggregators were not correctly created');
    }

    @isTest
    static void ARC_CreateMissingAggregatorsFalseTest() {
        Test.startTest();
        ARC_CreateMissingAggregators batch = new ARC_CreateMissingAggregators(null, false);
        Database.executeBatch(batch);
        Test.stopTest();

        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c];
        List<ARC_ParticipantAggregator__c> participantAggregators = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Assert.areEqual(2, aggregators.size(), 'Aggregators were not correctly created');
        Assert.areEqual(2, participantAggregators.size(), 'Participant Aggregators were not correctly created');
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        ARC_CreateMissingAggregators scheduleJob = new ARC_CreateMissingAggregators(null, true);
        scheduleJob.execute(null);
        Test.stopTest();

        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c];
        List<ARC_ParticipantAggregator__c> participantAggregators = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(52, aggregators.size(), 'Aggregators were not correctly created'); 
        Assert.areEqual(66, participantAggregators.size(), 'Participant Aggregators were not correctly created');
    }
}