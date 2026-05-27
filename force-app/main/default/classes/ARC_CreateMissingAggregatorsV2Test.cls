@isTest
private class ARC_CreateMissingAggregatorsV2Test {

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

        List<Contract> contract = ARC_TestUtility.createContractsAA(5);
        for (Contract cont : contract) {
            cont.AccountId = accounts[0].Id;
        }
        insert contract;

        List <vlocity_ins__GroupCensusMember__c> groupCensusMemberList = new List<vlocity_ins__GroupCensusMember__c>();
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = contract[0].AccountId;
        insert census;

        List<Account> accountListContactIds = [SELECT PersonContactId FROM Account WHERE FirstName LIKE 'PersonAccount%' ORDER BY FirstName];
        for (Integer i = 0; i < 2; i++) {
            vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();
            censusMember.Name = 'Test Census Member Primary ' + i;
            censusMember.vlocity_ins__FirstName__c = 'Test';
            censusMember.vlocity_ins__LastName__c = 'Census Member Primary ' + i;
            censusMember.vlocity_ins__CensusId__c = census.Id;
            censusMember.vlocity_ins__ContactId__c = accountListContactIds[i].PersonContactId;
            censusMember.vlocity_ins__SocialSecurityNumber__c = '123456789';
            censusMember.ARC_PhysicalAddressState__c = 'NY';
            groupCensusMemberList.add(censusMember);
        }
        insert groupCensusMemberList;


        contract[0].Status = 'Terminated';
        contract[0].ARC_ContractReason__c = 'Program Upgrade';
        contract[0].ARC_EffectiveDate__c = Date.valueOf('2023-11-12');
        contract[0].ARC_Inactive_Date__c = Date.valueOf('2024-11-11');
        contract[0].ActivatedDate = Date.valueOf('2023-11-12');
        // Per Person 2023: 15
        // Per Group 2023: 1
        // Per Person 2024: 6
        // Per Group 2024: 1
        // Total: 44
        
        contract[1].Status = 'Terminated';
        contract[1].ARC_ContractReason__c = 'Remove Member';
        contract[1].ARC_EffectiveDate__c = Date.valueOf('2024-11-12');
        contract[1].ARC_Inactive_Date__c = Date.valueOf('2025-11-11');
        contract[1].vlocity_ins__ExpiredContractId__c = contract[0].Id;
        contract[1].ActivatedDate = Date.valueOf('2024-11-12');
        // Per Person 2024: 1 Preex
        // Per Person 2025: 8 (6 Calendar + 2 New 2026 Aggs)
        // Per Group 2025: 1
        // Total: 10
        
        contract[2].Status = 'Terminated';
        contract[2].ARC_ContractReason__c = 'Add Existing Member';
        contract[2].ARC_EffectiveDate__c = Date.valueOf('2025-11-12');
        contract[2].ARC_Inactive_Date__c = Date.valueOf('2026-11-11');
        contract[2].vlocity_ins__ExpiredContractId__c = contract[1].Id;
        contract[2].ActivatedDate = Date.valueOf('2025-11-12');
        // Per Person 2025 (comeback): 10 (6 Calendar + 1 Preex + 1 Maternity + 2 New 2026 Aggs)
        // Per Person 2025 (non comeback): 1 Preex
        // Per Group 2025: 0
        // Per Person 2026: 11
        // Per Group 2026: 1
        // Total: 34

        contract[3].Status = 'Terminated';
        contract[3].ARC_ContractReason__c = 'Program Downgrade';
        contract[3].ARC_EffectiveDate__c = Date.valueOf('2026-11-12');
        contract[3].ARC_Inactive_Date__c = Date.valueOf('2027-11-11');
        contract[3].vlocity_ins__ExpiredContractId__c = contract[2].Id;
        contract[3].ActivatedDate = Date.valueOf('2026-11-12');
        // Per Person 2026: 1
        // Per Group 2026: 1
        // Per Person 2027: 7
        // Per Group 2027: 1
        // Total: 18

        contract[4].Status = 'Terminated';
        contract[4].ARC_ContractReason__c = 'Program Upgrade';
        contract[4].ARC_EffectiveDate__c = Date.valueOf('2027-11-12');
        contract[4].ARC_Inactive_Date__c = Date.valueOf('2028-11-11');
        contract[4].vlocity_ins__ExpiredContractId__c = contract[3].Id;
        contract[4].ActivatedDate = Date.valueOf('2027-11-12');
        // Per Person 2027: 1
        // Per Group 2027: 1
        // Per Person 2028: 7
        // Per Group 2028: 1
        // Total: 18

        update contract;

        List<Product2> prodList = new List<Product2>();
        Product2 prod1 = new Product2();
        prod1.Name = 'WeShare 6k';
        prod1.ProductCode = 'PROG_UHSM_WeShare6k';
        prod1.vlocity_ins__Type__c = 'Medical';

        Product2 prod2 = new Product2();
        prod2.Name = 'WeShare 12k';
        prod2.ProductCode = 'PROG_UHSM_WeShare12k';
        prod2.vlocity_ins__Type__c = 'Medical';

        prodList.add(prod1);
        prodList.add(prod2);

        insert prodList;

        List<vlocity_ins__ContractLineItem__c> cliList = new List<vlocity_ins__ContractLineItem__c>();
        for (Integer i = 0; i < 5; i++) {
            vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
            cli.Name = 'WeShare test';
            cli.ARC_SmokerFee__c = 100;
            cli.ARC_ExtraDependentFee__c = 200;
            cli.ARC_OriginalPrice__c = 1000;
            cli.vlocity_ins__UnitPrice__c = 1000;
            cli.vlocity_ins__EffectiveStartDate__c = contract[i].ARC_EffectiveDate__c;
            cli.vlocity_ins__ContractId__c = contract[i].Id;
            cli.vlocity_ins__Product2Id__c = prodList[0].Id;
            cliList.add(cli);
        }
        cliList[3].vlocity_ins__Product2Id__c = prodList[1].Id;
        insert cliList;
        
        //GroupCensusMemberPlan creation
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpList = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        for (Integer i = 0; i < 5; i++) {
            vlocity_ins__GroupCensusMemberPlan__c gcmpPrimary = new vlocity_ins__GroupCensusMemberPlan__c();
            gcmpPrimary.vlocity_ins__ContractLineId__c = cliList[i].Id;
            gcmpPrimary.vlocity_ins__GroupCensusMemberId__c = groupCensusMemberList[0].Id;
            if (i != 1) {
                vlocity_ins__GroupCensusMemberPlan__c gcmpSpouse = new vlocity_ins__GroupCensusMemberPlan__c();
                gcmpSpouse.vlocity_ins__ContractLineId__c = cliList[i].Id;
                gcmpSpouse.vlocity_ins__GroupCensusMemberId__c = groupCensusMemberList[1].Id;
                gcmpList.add(gcmpSpouse);
            }
            gcmpList.add(gcmpPrimary);
        }
        insert gcmpList;

        Id indAndFamPolicyRecordType = Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByDeveloperName().get('ARC_IndividualAndFamily').getRecordTypeId();
        List<InsurancePolicy> policies = new List<InsurancePolicy>();
        for (Integer i = 0; i < 5; i++) {
            InsurancePolicy policy = new InsurancePolicy();
            policy.Name = 'Policy ' + i;
            policy.ProductId = prodList[0].Id;
            policy.ARC_Contract__c = contract[i].Id;
            policy.NameInsuredId = accounts[0].Id;
            policy.RecordTypeId = indAndFamPolicyRecordType;
            
            policies.add(policy);
        }
        policies[3].ProductId = prodList[1].Id;
        insert policies;

        for (Integer i = 1; i < 4; i++) {
            policies[i].RenewedFromPolicyId = policies[0].Id;
        }
        update policies;

        List<InsurancePolicyCoverage> ipcList = new List<InsurancePolicyCoverage>();
        for (Integer i = 0; i < 5; i++) {
            InsurancePolicyCoverage ipc = new InsurancePolicyCoverage();
            ipc.InsurancePolicyId = policies[i].Id;
            ipc.vlocity_ins_fsc__Product2Id__c = policies[i].ProductId;
            ipcList.add(ipc);
        }
        insert ipcList;

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
        ipp1.ARC_StartDate__c = Date.valueOf('2023-11-12');
        ipp1.ARC_EndDate__c = Date.valueOf('2024-11-11');
        policyParticipants.add(ipp1);

        InsurancePolicyParticipant ipp2 = new InsurancePolicyParticipant();
        ipp2.Role = 'Spouse';
        ipp2.PrimaryParticipantContactId = accountListContactIds[1].PersonContactId;
        ipp2.InsurancePolicyId = policies[0].Id;
        ipp2.ARC_StartDate__c = Date.valueOf('2023-11-12');
        ipp2.ARC_EndDate__c = Date.valueOf('2024-11-11');
        policyParticipants.add(ipp2);

        InsurancePolicyParticipant ipp3 = new InsurancePolicyParticipant();
        ipp3.Role = 'Primary';
        ipp3.PrimaryParticipantContactId = accountListContactIds[0].PersonContactId;
        ipp3.InsurancePolicyId = policies[1].Id;
        ipp3.ARC_StartDate__c = Date.valueOf('2024-11-12'); 
        ipp3.ARC_EndDate__c = Date.valueOf('2025-12-11');
        policyParticipants.add(ipp3);

        InsurancePolicyParticipant ipp4 = new InsurancePolicyParticipant();
        ipp4.Role = 'Primary';
        ipp4.PrimaryParticipantContactId = accountListContactIds[0].PersonContactId;
        ipp4.InsurancePolicyId = policies[2].Id;
        ipp4.ARC_StartDate__c = Date.valueOf('2025-11-12');
        ipp4.ARC_EndDate__c = Date.valueOf('2026-11-11');
        policyParticipants.add(ipp4);

        InsurancePolicyParticipant ipp5 = new InsurancePolicyParticipant();
        ipp5.Role = 'Spouse';
        ipp5.PrimaryParticipantContactId = accountListContactIds[1].PersonContactId;
        ipp5.InsurancePolicyId = policies[2].Id;
        ipp5.ARC_StartDate__c = Date.valueOf('2025-11-12');
        ipp5.ARC_EndDate__c = Date.valueOf('2026-11-11');
        policyParticipants.add(ipp5);

        InsurancePolicyParticipant ipp6 = new InsurancePolicyParticipant();
        ipp6.Role = 'Primary';
        ipp6.PrimaryParticipantContactId = accountListContactIds[0].PersonContactId;
        ipp6.InsurancePolicyId = policies[3].Id;
        ipp6.ARC_StartDate__c = Date.valueOf('2026-11-12');
        ipp6.ARC_EndDate__c = Date.valueOf('2027-11-11');
        policyParticipants.add(ipp6);

        InsurancePolicyParticipant ipp7 = new InsurancePolicyParticipant();
        ipp7.Role = 'Spouse';
        ipp7.PrimaryParticipantContactId = accountListContactIds[1].PersonContactId;
        ipp7.InsurancePolicyId = policies[3].Id;
        ipp7.ARC_StartDate__c = Date.valueOf('2026-11-12');
        ipp7.ARC_EndDate__c = Date.valueOf('2027-11-11');
        policyParticipants.add(ipp7);

        InsurancePolicyParticipant ipp8 = new InsurancePolicyParticipant();
        ipp8.Role = 'Primary';
        ipp8.PrimaryParticipantContactId = accountListContactIds[0].PersonContactId;
        ipp8.InsurancePolicyId = policies[4].Id;
        ipp8.ARC_StartDate__c = Date.valueOf('2027-11-12');
        ipp8.ARC_EndDate__c = Date.valueOf('2028-11-11');
        policyParticipants.add(ipp8);

        InsurancePolicyParticipant ipp9 = new InsurancePolicyParticipant();
        ipp9.Role = 'Spouse';
        ipp9.PrimaryParticipantContactId = accountListContactIds[1].PersonContactId;
        ipp9.InsurancePolicyId = policies[4].Id;
        ipp9.ARC_StartDate__c = Date.valueOf('2027-11-12');
        ipp9.ARC_EndDate__c = Date.valueOf('2028-11-11');
        policyParticipants.add(ipp9);

        insert policyParticipants;

        List<ARC_CoverageParticipant__c> covPartList = new List<ARC_CoverageParticipant__c>();
        
        ARC_CoverageParticipant__c polCov1 = new ARC_CoverageParticipant__c();
        polCov1.ARC_PolicyCoverage__c = ipcList[0].Id;
        polCov1.ARC_Policy__c = policies[0].Id;
        polCov1.ARC_PolicyParticipant__c = policyParticipants[0].Id;
        polCov1.ARC_CoverageRole__c = 'Primary';
        covPartList.add(polCov1);

        ARC_CoverageParticipant__c polCov2 = new ARC_CoverageParticipant__c();
        polCov2.ARC_PolicyCoverage__c = ipcList[0].Id;
        polCov2.ARC_Policy__c = policies[0].Id;
        polCov2.ARC_PolicyParticipant__c = policyParticipants[1].Id;
        polCov2.ARC_CoverageRole__c = 'Spouse';
        covPartList.add(polCov2);

        ARC_CoverageParticipant__c polCov3 = new ARC_CoverageParticipant__c();
        polCov3.ARC_PolicyCoverage__c = ipcList[1].Id;
        polCov3.ARC_Policy__c = policies[1].Id;
        polCov3.ARC_PolicyParticipant__c = policyParticipants[2].Id;
        polCov3.ARC_CoverageRole__c = 'Primary';
        covPartList.add(polCov3);

        ARC_CoverageParticipant__c polCov4 = new ARC_CoverageParticipant__c();
        polCov4.ARC_PolicyCoverage__c = ipcList[2].Id;
        polCov4.ARC_Policy__c = policies[2].Id;
        polCov4.ARC_PolicyParticipant__c = policyParticipants[3].Id;
        polCov4.ARC_CoverageRole__c = 'Primary';
        covPartList.add(polCov4);

        ARC_CoverageParticipant__c polCov5 = new ARC_CoverageParticipant__c();
        polCov5.ARC_PolicyCoverage__c = ipcList[2].Id;
        polCov5.ARC_Policy__c = policies[2].Id;
        polCov5.ARC_PolicyParticipant__c = policyParticipants[4].Id;
        polCov5.ARC_CoverageRole__c = 'Spouse';
        covPartList.add(polCov5);

        ARC_CoverageParticipant__c polCov6 = new ARC_CoverageParticipant__c();
        polCov6.ARC_PolicyCoverage__c = ipcList[3].Id;
        polCov6.ARC_Policy__c = policies[3].Id;
        polCov6.ARC_PolicyParticipant__c = policyParticipants[5].Id;
        polCov6.ARC_CoverageRole__c = 'Primary';
        covPartList.add(polCov6);

        ARC_CoverageParticipant__c polCov7 = new ARC_CoverageParticipant__c();
        polCov7.ARC_PolicyCoverage__c = ipcList[3].Id;
        polCov7.ARC_Policy__c = policies[3].Id;
        polCov7.ARC_PolicyParticipant__c = policyParticipants[6].Id;
        polCov7.ARC_CoverageRole__c = 'Spouse';
        covPartList.add(polCov7);

        ARC_CoverageParticipant__c polCov8 = new ARC_CoverageParticipant__c();
        polCov8.ARC_PolicyCoverage__c = ipcList[4].Id;
        polCov8.ARC_Policy__c = policies[4].Id;
        polCov8.ARC_PolicyParticipant__c = policyParticipants[7].Id;
        polCov8.ARC_CoverageRole__c = 'Primary';
        covPartList.add(polCov8);

        ARC_CoverageParticipant__c polCov9 = new ARC_CoverageParticipant__c();
        polCov9.ARC_PolicyCoverage__c = ipcList[4].Id;
        polCov9.ARC_Policy__c = policies[4].Id;
        polCov9.ARC_PolicyParticipant__c = policyParticipants[8].Id;
        polCov9.ARC_CoverageRole__c = 'Spouse';
        covPartList.add(polCov9);

        insert covPartList;

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
        individualAgg.Name = 'Individual AMCS';
        individualAgg.ARC_Code__c = 'AMCS__c';
        individualAgg.ARC_Type__c = 'Currency';
        individualAgg.RecordTypeId = individualAggRT;
        individualAgg.ARC_LimitValue__c = 6000;
        individualAgg.ARC_Year__c = '2024';
        individualAgg.ARC_Member__c = accounts[0].Id;
        individualAgg.ARC_CreatedIn__c = policies[0].Id;
        
        aggregators.add(oneTimeAgg);
        aggregators.add(individualAgg);
        insert aggregators;

       
        List<ARC_ParticipantAggregator__c> partAggList = new List<ARC_ParticipantAggregator__c>();
        ARC_ParticipantAggregator__c partAgg1 = new ARC_ParticipantAggregator__c();
        partAgg1.Name = 'Mammograms';
        partAgg1.ARC_Policy__c = policies[0].Id;
        partAgg1.ARC_PolicyParticipant__c = policyParticipants[0].Id;
        partAgg1.ARC_ConsumedValue__c = 0;
        partAgg1.ARC_Aggregator__c = aggregators[0].Id; 


        ARC_ParticipantAggregator__c partAgg2 = new ARC_ParticipantAggregator__c();
        partAgg2.Name = 'Individual AMCS';
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
        List<InsurancePolicy> policies = [SELECT Id FROM InsurancePolicy];
        Set<Id> policiesId = new Set<Id>();
        for (InsurancePolicy pol : policies) {
            policiesId.add(pol.Id);
        }
        String idsString = '\'' + String.join(policiesId, '\', \'') + '\'';
        String whereClause = 'Id IN (' + idsString + ')';
        Test.startTest();
        ARC_CreateMissingAggregatorsV2 batch = new ARC_CreateMissingAggregatorsV2(whereClause, true, false);
        Database.executeBatch(batch);
        Test.stopTest();

        List<ARC_Aggregator__c> aggregators = [SELECT Id, Name, ARC_Member__r.Name, ARC_Year__c, ARC_CreatedIn__r.Name, ARC_BenefitYear__c, ARC_StartDate__c FROM ARC_Aggregator__c ORDER BY ARC_CreatedIn__r.Name ASC, ARC_Member__c ASC, ARC_Year__c ASC];
        List<ARC_ParticipantAggregator__c> participantAggregators = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Integer policy0Member0 = 0;
        Integer policy0Member1 = 0;
        Integer policy1Member0 = 0;
        Integer policy1Member1 = 0;
        Integer policy2Member0 = 0;
        Integer policy2Member1 = 0;
        Integer policy3Member0 = 0;
        Integer policy3Member1 = 0;
        Integer policy4Member0 = 0;
        Integer policy4Member1 = 0;
        System.debug('-------Aggregators---------');
        for (ARC_Aggregator__c agg : aggregators) {
            System.debug('-------Agg---------');
            System.debug(agg.Name);
            System.debug(agg.ARC_Member__r.Name);
            System.debug(agg.ARC_Year__c);
            System.debug(agg.ARC_BenefitYear__c);
            System.debug(agg.ARC_StartDate__c);
            System.debug(agg.ARC_CreatedIn__r.Name);
            if (agg.ARC_CreatedIn__r.Name == 'Policy 0' && agg.ARC_Member__r.Name == 'PersonAccount 0 Test') {
                policy0Member0++;
            }
            if (agg.ARC_CreatedIn__r.Name == 'Policy 0' && agg.ARC_Member__r.Name == 'PersonAccount 1 Test') {
                policy0Member1++;
            }
            if (agg.ARC_CreatedIn__r.Name == 'Policy 1' && agg.ARC_Member__r.Name == 'PersonAccount 0 Test') {
                policy1Member0++;
            }
            if (agg.ARC_CreatedIn__r.Name == 'Policy 1' && agg.ARC_Member__r.Name == 'PersonAccount 1 Test') {
                policy1Member1++;
            }
            if (agg.ARC_CreatedIn__r.Name == 'Policy 2' && agg.ARC_Member__r.Name == 'PersonAccount 0 Test') {
                policy2Member0++;
            }
            if (agg.ARC_CreatedIn__r.Name == 'Policy 2' && agg.ARC_Member__r.Name == 'PersonAccount 1 Test') {
                policy2Member1++;
            }
            if (agg.ARC_CreatedIn__r.Name == 'Policy 3' && agg.ARC_Member__r.Name == 'PersonAccount 0 Test') {
                policy3Member0++;
            }
            if (agg.ARC_CreatedIn__r.Name == 'Policy 3' && agg.ARC_Member__r.Name == 'PersonAccount 1 Test') {
                policy3Member1++;
            }
            if (agg.ARC_CreatedIn__r.Name == 'Policy 4' && agg.ARC_Member__r.Name == 'PersonAccount 0 Test') {
                policy4Member0++;
            }
            if (agg.ARC_CreatedIn__r.Name == 'Policy 4' && agg.ARC_Member__r.Name == 'PersonAccount 1 Test') {
                policy4Member1++;
            }
        }
        System.debug('-------Policy Aggregators Counter---------');
        System.debug(policy0Member0);
        System.debug(policy0Member1);
        System.debug(policy1Member0);
        System.debug(policy1Member1);
        System.debug(policy2Member0);
        System.debug(policy2Member1);
        System.debug(policy3Member0);
        System.debug(policy3Member1);
        System.debug(policy4Member0);
        System.debug(policy4Member1);

        Assert.areEqual(128, aggregators.size(), 'Aggregators were not correctly created'); 
        Assert.areEqual(218, participantAggregators.size(), 'Participant Aggregators were not correctly created');
    }

    @isTest
    static void ARC_CreateMissingAggregatorsFalseTest() {
        List<InsurancePolicy> policies = [SELECT Id FROM InsurancePolicy];
        Set<Id> policiesId = new Set<Id>();
        for (InsurancePolicy pol : policies) {
            policiesId.add(pol.Id);
        }
        String idsString = '\'' + String.join(policiesId, '\', \'') + '\'';
        String whereClause = 'Id IN (' + idsString + ')';
        Test.startTest();
        ARC_CreateMissingAggregatorsV2 batch = new ARC_CreateMissingAggregatorsV2(whereClause, false, true);
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
        ARC_CreateMissingAggregatorsV2 scheduleJob = new ARC_CreateMissingAggregatorsV2(null, true, true);
        scheduleJob.execute(null);
        Test.stopTest();

        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c];
        List<ARC_ParticipantAggregator__c> participantAggregators = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(128, aggregators.size(), 'Aggregators were not correctly created'); 
        Assert.areEqual(218, participantAggregators.size(), 'Participant Aggregators were not correctly created');
    }
}