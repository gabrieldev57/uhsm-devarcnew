@isTest
private class ARC_EliminateDuplicatedAggregatorsTest {


    //PartAgg
    //PartAgg con valores
    @testSetup
    static void makeData() {
        // Policy 0 - No Aggregators
        // Policy 1 - Aggregator with no duplicates
        // Policy 2 - Aggregators duplicated ONE_TIME
        // Policy 3 - Aggregators duplicated LIFETIME
        // Policy 4 - Aggregators duplicated YEARLY NoAMCS
        // Policy 5 - Aggregators duplicated YEARLY NoAMCS (Exceeding limit)
        // Policy 6 - Aggregators duplicated AMCS w/o Family
        // Policy 7 - Aggregators duplicated YEARLY AMCS (ipp1-fam1, ipp2-fam1, w/ same Family)
        // Policy 8 - Aggregators duplicated YEARLY AMCS (ipp1-fam1-fam2, ipp2-fam1-fam2)
        // Policy 9 - Aggregators duplicated YEARLY AMCS (ipp1-fam1, ipp2-fam1, one w/ Family & one w/o Family)
        // Policy 10 - Aggregators duplicated YEARLY AMCS (ipp1-fam1, ipp2-fam2, w/ same Family)
        // Policy 11 - Aggregators duplicated YEARLY AMCS (ipp1-fam1, ipp2-fam2, one w/ Family & one w/o Family)
        
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

        List<Contract> contract = ARC_TestUtility.createContractsAA(1);
        insert contract;

        contract[0].Status = 'Terminated';
        contract[0].ARC_ContractReason__c = 'Program Upgrade';
        contract[0].ARC_EffectiveDate__c = Date.valueOf('2021-11-12');
        update contract;

        Product2 prod = new Product2();
        prod.Name = 'WeShare 6k ';
        prod.ProductCode = 'PROG_UHSM_WeShare6k';
        prod.vlocity_ins__Type__c = 'Medical';
        insert prod;

        List<InsurancePolicy> policies = new List<InsurancePolicy>();
        for (Integer i = 0; i < 12; i++) {
            InsurancePolicy policy = new InsurancePolicy();
            policy.Name = 'Policy ' + i;
            policy.ProductId = prod.Id;
            policy.ARC_Contract__c = contract[0].Id;
            policy.NameInsuredId = accounts[0].Id;
            policies.add(policy);
        }
        insert policies;

        List<Account> accountListContactIds = [SELECT Id, PersonContactId FROM Account WHERE FirstName Like 'PersonAccount%' ORDER BY FirstName];

        // Insert IPP
        List<InsurancePolicyParticipant> policyParticipants = new List<InsurancePolicyParticipant>();
        for (Integer i = 0; i < 12; i++) {
            InsurancePolicyParticipant ipp1 = new InsurancePolicyParticipant();
            ipp1.Role = 'Primary';
            ipp1.PrimaryParticipantContactId = accountListContactIds[0].PersonContactId;
            ipp1.InsurancePolicyId = policies[i].Id;
            InsurancePolicyParticipant ipp2 = new InsurancePolicyParticipant();
            ipp2.Role = 'Spouse';
            ipp2.PrimaryParticipantContactId = accountListContactIds[1].PersonContactId;
            ipp2.InsurancePolicyId = policies[i].Id;
            policyParticipants.add(ipp1);
            policyParticipants.add(ipp2);
        }
        insert policyParticipants;

        // Insert Family Aggregators
        Id familyAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Family').getRecordTypeId();
        List<ARC_Aggregator__c> familyAMCSAggregators = new List<ARC_Aggregator__c>();
        for (Integer i = 0; i < 10; i++) {
            ARC_Aggregator__c agg = new ARC_Aggregator__c();
            agg.Name = 'Family AMCS';
            agg.RecordTypeId = familyAggRT;
            agg.ARC_Year__c = '2025';
            agg.ARC_LimitValue__c = 12000;
            Integer indexPol = 7 + (i / 2);
            agg.ARC_CreatedIn__c = policies[indexPol].Id;
            familyAMCSAggregators.add(agg);
        }
        insert familyAMCSAggregators;

        // Insert ONE_TIME Aggregators
        Id individualAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
        List<ARC_Aggregator__c> oneTimeAggregators = new List<ARC_Aggregator__c>();
        for (Integer i = 0; i < 3; i++) {
            for (Integer j = 0; j < 2; j++) {
                ARC_Aggregator__c agg = new ARC_Aggregator__c();
                agg.Name = 'Mammograms';
                agg.ARC_Code__c = 'MAMM__c';
                agg.ARC_Type__c = 'Number';
                agg.RecordTypeId = individualAggRT;
                agg.ARC_NextAvailabilityDate__c = Date.today();
                agg.ARC_LimitValue__c = 1;
                agg.ARC_Member__c = accounts[j].Id;
                oneTimeAggregators.add(agg);
            }
        }
        oneTimeAggregators[0].ARC_CreatedIn__c = oneTimeAggregators[1].ARC_CreatedIn__c = policies[1].Id;
        oneTimeAggregators[2].ARC_CreatedIn__c = oneTimeAggregators[3].ARC_CreatedIn__c = oneTimeAggregators[4].ARC_CreatedIn__c = oneTimeAggregators[5].ARC_CreatedIn__c = policies[2].Id;

        // Insert LIFETIME Aggregators
        List<ARC_Aggregator__c> lifeTimeAggregators = new List<ARC_Aggregator__c>();
        for (Integer i = 0; i < 3; i++) {
            for (Integer j = 0; j < 2; j++) {
                ARC_Aggregator__c agg = new ARC_Aggregator__c();
                agg.Name = 'Allergy Testing';
                agg.ARC_Code__c = 'ALGTEST__c';
                agg.ARC_Type__c = 'Currency';
                agg.RecordTypeId = individualAggRT;
                agg.ARC_LimitValue__c = 1200;
                agg.ARC_Member__c = accounts[j].Id;
                lifeTimeAggregators.add(agg);
            }
        }
        lifeTimeAggregators[0].ARC_CreatedIn__c = lifeTimeAggregators[1].ARC_CreatedIn__c = policies[1].Id;
        lifeTimeAggregators[2].ARC_CreatedIn__c = lifeTimeAggregators[3].ARC_CreatedIn__c = lifeTimeAggregators[4].ARC_CreatedIn__c = lifeTimeAggregators[5].ARC_CreatedIn__c = policies[3].Id;
                
        // Insert YEARLY No AMCS Aggregators
        List<ARC_Aggregator__c> yearlyAggregators = new List<ARC_Aggregator__c>();
        for (Integer i = 0; i < 5; i++) {
            for (Integer j = 0; j < 2; j++) {
                ARC_Aggregator__c agg = new ARC_Aggregator__c();
                agg.Name = 'Maternity';
                agg.ARC_Code__c = 'MAT__c';
                agg.ARC_Type__c = 'Currency';
                agg.RecordTypeId = individualAggRT;
                agg.ARC_LimitValue__c = 15000;
                agg.ARC_Year__c = '2025';
                agg.ARC_Member__c = accounts[j].Id;
                yearlyAggregators.add(agg);
            }
        }
        yearlyAggregators[0].ARC_CreatedIn__c = yearlyAggregators[1].ARC_CreatedIn__c = policies[1].Id;
        yearlyAggregators[2].ARC_CreatedIn__c = yearlyAggregators[3].ARC_CreatedIn__c = yearlyAggregators[4].ARC_CreatedIn__c = yearlyAggregators[5].ARC_CreatedIn__c = policies[4].Id;
        yearlyAggregators[6].ARC_CreatedIn__c = yearlyAggregators[7].ARC_CreatedIn__c = yearlyAggregators[8].ARC_CreatedIn__c = yearlyAggregators[9].ARC_CreatedIn__c = policies[5].Id;

        // Insert Individual AMCS Aggregators
        List<ARC_Aggregator__c> individualAMCSAggregators = new List<ARC_Aggregator__c>();
        // AMCS 0-3 - Policy 6
        // AMCS 4-7 - Policy 7
        // ...
        for (Integer i = 6; i < 12; i++) {
            for (Integer j = 0; j < 2; j++) {
                for (Integer k = 0; k < 2; k++) {
                    ARC_Aggregator__c agg = new ARC_Aggregator__c();
                    agg.Name = 'Individual AMCS';
                    agg.ARC_Code__c = 'AMCS__c';
                    agg.ARC_Type__c = 'Currency';
                    agg.RecordTypeId = individualAggRT;
                    agg.ARC_Year__c = '2025';
                    agg.ARC_LimitValue__c = 6000;
                    agg.ARC_CreatedIn__c = policies[i].Id;
                    agg.ARC_Member__c = accounts[j].Id;
                    individualAMCSAggregators.add(agg);
                }          
            }
        }
        // Policy 7
        individualAMCSAggregators[4].ARC_FamilyAggregator__c = individualAMCSAggregators[5].ARC_FamilyAggregator__c = individualAMCSAggregators[6].ARC_FamilyAggregator__c = individualAMCSAggregators[7].ARC_FamilyAggregator__c = familyAMCSAggregators[0].Id;
        // Policy 8
        individualAMCSAggregators[8].ARC_FamilyAggregator__c = individualAMCSAggregators[10].ARC_FamilyAggregator__c = familyAMCSAggregators[2].Id;
        individualAMCSAggregators[9].ARC_FamilyAggregator__c = individualAMCSAggregators[11].ARC_FamilyAggregator__c = familyAMCSAggregators[3].Id;
        // Policy 9
        individualAMCSAggregators[12].ARC_FamilyAggregator__c = individualAMCSAggregators[14].ARC_FamilyAggregator__c = familyAMCSAggregators[4].Id;
        // Policy 10
        individualAMCSAggregators[16].ARC_FamilyAggregator__c = individualAMCSAggregators[17].ARC_FamilyAggregator__c = familyAMCSAggregators[6].Id;
        individualAMCSAggregators[18].ARC_FamilyAggregator__c = individualAMCSAggregators[19].ARC_FamilyAggregator__c = familyAMCSAggregators[7].Id;
        // Policy 11
        individualAMCSAggregators[20].ARC_FamilyAggregator__c = familyAMCSAggregators[8].Id;
        individualAMCSAggregators[22].ARC_FamilyAggregator__c = familyAMCSAggregators[9].Id;

        List<ARC_Aggregator__c> individualAggregators = new List<ARC_Aggregator__c>();
        individualAggregators.addAll(oneTimeAggregators);
        individualAggregators.addAll(lifeTimeAggregators);
        individualAggregators.addAll(yearlyAggregators);
        individualAggregators.addAll(individualAMCSAggregators);
        insert individualAggregators;
        System.debug(oneTimeAggregators.size());
        System.debug(lifeTimeAggregators.size());
        System.debug(yearlyAggregators.size());
        System.debug(individualAMCSAggregators.size());
        System.debug(individualAggregators.size());
        

        Map<Id, Id> contactToAccountMap = new Map<Id, Id>();
        for (Account acc : accountListContactIds) {
            contactToAccountMap.put(acc.PersonContactId, acc.Id);
        }
        Map<Id, Map<Id, InsurancePolicyParticipant>> policyAccountToIPPMap = new Map<Id, Map<Id, InsurancePolicyParticipant>>();
        for (InsurancePolicyParticipant ipp : policyParticipants) {
            Id policyId = ipp.InsurancePolicyId;
            Id contactId = ipp.PrimaryParticipantContactId;
            Id accountId = contactToAccountMap.get(contactId);
            if (!policyAccountToIPPMap.containsKey(policyId)) {
                policyAccountToIPPMap.put(policyId, new Map<Id, InsurancePolicyParticipant>());
            }
            policyAccountToIPPMap.get(policyId).put(accountId, ipp);
        }
        // Insert Participant Aggregators
        // 0-5 ONE_TIME; 6-11 LIFETIME; 12-21 YEARLY; 22-45 AMCS
        List<ARC_ParticipantAggregator__c> participantAggregators = new List<ARC_ParticipantAggregator__c>();
        for (ARC_Aggregator__c indAgg : individualAggregators) {
            ARC_ParticipantAggregator__c partAgg = new ARC_ParticipantAggregator__c();
            partAgg.Name = indAgg.Name;
            partAgg.ARC_Aggregator__c = indAgg.Id;
            partAgg.ARC_Policy__c = indAgg.ARC_CreatedIn__c;
            partAgg.ARC_PolicyParticipant__c = policyAccountToIPPMap.get(indAgg.ARC_CreatedIn__c).get(indAgg.ARC_Member__c).Id;
            partAgg.ARC_ConsumedValue__c = 0;
            participantAggregators.add(partAgg);
        }
        // LIFETIME
        for (Integer i = 6; i < 12; i++) {
            participantAggregators[i].ARC_ConsumedValue__c = 500;
        }
        // YEARLY
        for (Integer i = 12; i < 18; i++) {
            participantAggregators[i].ARC_ConsumedValue__c = 5000;
        }
        for (Integer i = 18; i < 22; i++) {
            participantAggregators[i].ARC_ConsumedValue__c = 10000;
        }
        // AMCS
        for (Integer i = 22; i < 46; i++) {
            participantAggregators[i].ARC_ConsumedValue__c = 200;
        }
       
        insert participantAggregators;
    }

    @isTest
    static void policy0Test() {
        Id policyId = [SELECT Id FROM InsurancePolicy WHERE Name = 'Policy 0' LIMIT 1].Id;
        String whereClause = 'Id = \'' + policyId + '\'';
        List<ARC_ParticipantAggregator__c> participantAggregatorsBefore = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_EliminateDuplicatedAggregators batch_false = new ARC_EliminateDuplicatedAggregators(whereClause, false);
        Database.executeBatch(batch_false);
        ARC_EliminateDuplicatedAggregators batch_true = new ARC_EliminateDuplicatedAggregators(whereClause, true);
        Database.executeBatch(batch_true);
        Test.stopTest();

        List<ARC_ParticipantAggregator__c> participantAggregatorsAfter = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(participantAggregatorsBefore.size(), participantAggregatorsAfter.size(), 'Participant Aggregators are being modified');
        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c =: policyId];
        Assert.areEqual(0, aggregators.size(), 'Number of aggregators eliminated is not the expected');
    }

    @isTest
    static void policy1Test() {
        Id policyId = [SELECT Id FROM InsurancePolicy WHERE Name = 'Policy 1' LIMIT 1].Id;
        String whereClause = 'Id = \'' + policyId + '\'';
        List<ARC_ParticipantAggregator__c> participantAggregatorsBefore = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_EliminateDuplicatedAggregators batch_false = new ARC_EliminateDuplicatedAggregators(whereClause, false);
        Database.executeBatch(batch_false);
        ARC_EliminateDuplicatedAggregators batch_true = new ARC_EliminateDuplicatedAggregators(whereClause, true);
        Database.executeBatch(batch_true);
        Test.stopTest();

        List<ARC_ParticipantAggregator__c> participantAggregatorsAfter = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(participantAggregatorsBefore.size(), participantAggregatorsAfter.size(), 'Participant Aggregators are being modified');
        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c =: policyId];
        Assert.areEqual(6, aggregators.size(), 'Number of aggregators eliminated is not the expected');
    }

    @isTest
    static void policy2Test() {
        Id policyId = [SELECT Id FROM InsurancePolicy WHERE Name = 'Policy 2' LIMIT 1].Id;
        String whereClause = 'Id = \'' + policyId + '\'';
        List<ARC_ParticipantAggregator__c> participantAggregatorsBefore = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_EliminateDuplicatedAggregators batch_false = new ARC_EliminateDuplicatedAggregators(whereClause, false);
        Database.executeBatch(batch_false);
        ARC_EliminateDuplicatedAggregators batch_true = new ARC_EliminateDuplicatedAggregators(whereClause, true);
        Database.executeBatch(batch_true);
        Test.stopTest();
        
        List<ARC_ParticipantAggregator__c> participantAggregatorsAfter = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(participantAggregatorsBefore.size(), participantAggregatorsAfter.size(), 'Participant Aggregators are being modified');
        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c =: policyId];
        Assert.areEqual(2, aggregators.size(), 'Number of aggregators eliminated is not the expected');
    }

    @isTest
    static void policy3Test() {
        Id policyId = [SELECT Id FROM InsurancePolicy WHERE Name = 'Policy 3' LIMIT 1].Id;
        String whereClause = 'Id = \'' + policyId + '\'';
        List<ARC_ParticipantAggregator__c> participantAggregatorsBefore = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_EliminateDuplicatedAggregators batch_false = new ARC_EliminateDuplicatedAggregators(whereClause, false);
        Database.executeBatch(batch_false);
        ARC_EliminateDuplicatedAggregators batch_true = new ARC_EliminateDuplicatedAggregators(whereClause, true);
        Database.executeBatch(batch_true);
        Test.stopTest();

        List<ARC_ParticipantAggregator__c> participantAggregatorsAfter = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(participantAggregatorsBefore.size(), participantAggregatorsAfter.size(), 'Participant Aggregators are being modified');
        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c =: policyId];
        Assert.areEqual(2, aggregators.size(), 'Number of aggregators eliminated is not the expected');
    }

    @isTest
    static void policy4Test() {
        Id policyId = [SELECT Id FROM InsurancePolicy WHERE Name = 'Policy 4' LIMIT 1].Id;
        String whereClause = 'Id = \'' + policyId + '\'';
        List<ARC_ParticipantAggregator__c> participantAggregatorsBefore = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_EliminateDuplicatedAggregators batch_false = new ARC_EliminateDuplicatedAggregators(whereClause, false);
        Database.executeBatch(batch_false);
        ARC_EliminateDuplicatedAggregators batch_true = new ARC_EliminateDuplicatedAggregators(whereClause, true);
        Database.executeBatch(batch_true);
        Test.stopTest();

        List<ARC_ParticipantAggregator__c> participantAggregatorsAfter = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(participantAggregatorsBefore.size(), participantAggregatorsAfter.size(), 'Participant Aggregators are being modified');
        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c =: policyId];
        Assert.areEqual(2, aggregators.size(), 'Number of aggregators eliminated is not the expected');
    }

    @isTest
    static void policy5Test() {
        Id policyId = [SELECT Id FROM InsurancePolicy WHERE Name = 'Policy 5' LIMIT 1].Id;
        String whereClause = 'Id = \'' + policyId + '\'';
        List<ARC_ParticipantAggregator__c> participantAggregatorsBefore = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_EliminateDuplicatedAggregators batch_false = new ARC_EliminateDuplicatedAggregators(whereClause, false);
        Database.executeBatch(batch_false);
        ARC_EliminateDuplicatedAggregators batch_true = new ARC_EliminateDuplicatedAggregators(whereClause, true);
        Database.executeBatch(batch_true);
        Test.stopTest();

        List<ARC_ParticipantAggregator__c> participantAggregatorsAfter = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(participantAggregatorsBefore.size(), participantAggregatorsAfter.size(), 'Participant Aggregators are being modified');
        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c =: policyId];
        Assert.areEqual(4, aggregators.size(), 'Number of aggregators eliminated is not the expected');
    }

    @isTest
    static void policy6Test() {
        Id policyId = [SELECT Id FROM InsurancePolicy WHERE Name = 'Policy 6' LIMIT 1].Id;
        String whereClause = 'Id = \'' + policyId + '\'';
        List<ARC_ParticipantAggregator__c> participantAggregatorsBefore = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_EliminateDuplicatedAggregators batch_false = new ARC_EliminateDuplicatedAggregators(whereClause, false);
        Database.executeBatch(batch_false);
        ARC_EliminateDuplicatedAggregators batch_true = new ARC_EliminateDuplicatedAggregators(whereClause, true);
        Database.executeBatch(batch_true);
        Test.stopTest();

        List<ARC_ParticipantAggregator__c> participantAggregatorsAfter = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(participantAggregatorsBefore.size(), participantAggregatorsAfter.size(), 'Participant Aggregators are being modified');
        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c =: policyId];
        Assert.areEqual(2, aggregators.size(), 'Number of aggregators eliminated is not the expected');
    }

    @isTest
    static void policy7Test() {
        Id policyId = [SELECT Id FROM InsurancePolicy WHERE Name = 'Policy 7' LIMIT 1].Id;
        String whereClause = 'Id = \'' + policyId + '\'';
        List<ARC_ParticipantAggregator__c> participantAggregatorsBefore = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_EliminateDuplicatedAggregators batch_false = new ARC_EliminateDuplicatedAggregators(whereClause, false);
        Database.executeBatch(batch_false);
        ARC_EliminateDuplicatedAggregators batch_true = new ARC_EliminateDuplicatedAggregators(whereClause, true);
        Database.executeBatch(batch_true);
        Test.stopTest();

        List<ARC_ParticipantAggregator__c> participantAggregatorsAfter = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(participantAggregatorsBefore.size(), participantAggregatorsAfter.size(), 'Participant Aggregators are being modified');
        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c =: policyId];
        Assert.areEqual(3, aggregators.size(), 'Number of aggregators eliminated is not the expected');
    }

    @isTest
    static void policy8Test() {
        Id policyId = [SELECT Id FROM InsurancePolicy WHERE Name = 'Policy 8' LIMIT 1].Id;
        String whereClause = 'Id = \'' + policyId + '\'';
        List<ARC_ParticipantAggregator__c> participantAggregatorsBefore = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_EliminateDuplicatedAggregators batch_false = new ARC_EliminateDuplicatedAggregators(whereClause, false);
        Database.executeBatch(batch_false);
        ARC_EliminateDuplicatedAggregators batch_true = new ARC_EliminateDuplicatedAggregators(whereClause, true);
        Database.executeBatch(batch_true);
        Test.stopTest();

        List<ARC_ParticipantAggregator__c> participantAggregatorsAfter = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(participantAggregatorsBefore.size(), participantAggregatorsAfter.size(), 'Participant Aggregators are being modified');
        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c =: policyId];
        Assert.areEqual(3, aggregators.size(), 'Number of aggregators eliminated is not the expected');
    }

    @isTest
    static void policy9Test() {
        Id policyId = [SELECT Id FROM InsurancePolicy WHERE Name = 'Policy 9' LIMIT 1].Id;
        String whereClause = 'Id = \'' + policyId + '\'';
        List<ARC_ParticipantAggregator__c> participantAggregatorsBefore = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_EliminateDuplicatedAggregators batch_false = new ARC_EliminateDuplicatedAggregators(whereClause, false);
        Database.executeBatch(batch_false);
        ARC_EliminateDuplicatedAggregators batch_true = new ARC_EliminateDuplicatedAggregators(whereClause, true);
        Database.executeBatch(batch_true);
        Test.stopTest();

        List<ARC_ParticipantAggregator__c> participantAggregatorsAfter = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(participantAggregatorsBefore.size(), participantAggregatorsAfter.size(), 'Participant Aggregators are being modified');
        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c =: policyId];
        Assert.areEqual(3, aggregators.size(), 'Number of aggregators eliminated is not the expected');
    }

    @isTest
    static void policy10Test() {
        Id policyId = [SELECT Id FROM InsurancePolicy WHERE Name = 'Policy 10' LIMIT 1].Id;
        String whereClause = 'Id = \'' + policyId + '\'';
        List<ARC_ParticipantAggregator__c> participantAggregatorsBefore = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_EliminateDuplicatedAggregators batch_false = new ARC_EliminateDuplicatedAggregators(whereClause, false);
        Database.executeBatch(batch_false);
        ARC_EliminateDuplicatedAggregators batch_true = new ARC_EliminateDuplicatedAggregators(whereClause, true);
        Database.executeBatch(batch_true);
        Test.stopTest();

        List<ARC_ParticipantAggregator__c> participantAggregatorsAfter = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(participantAggregatorsBefore.size(), participantAggregatorsAfter.size(), 'Participant Aggregators are being modified');
        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c =: policyId];
        Assert.areEqual(3, aggregators.size(), 'Number of aggregators eliminated is not the expected');
    }

    @isTest
    static void policy11Test() {
        Id policyId = [SELECT Id FROM InsurancePolicy WHERE Name = 'Policy 11' LIMIT 1].Id;
        String whereClause = 'Id = \'' + policyId + '\'';
        List<ARC_ParticipantAggregator__c> participantAggregatorsBefore = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_EliminateDuplicatedAggregators batch_false = new ARC_EliminateDuplicatedAggregators(whereClause, false);
        Database.executeBatch(batch_false);
        ARC_EliminateDuplicatedAggregators batch_true = new ARC_EliminateDuplicatedAggregators(whereClause, true);
        Database.executeBatch(batch_true);
        Test.stopTest();

        List<ARC_ParticipantAggregator__c> participantAggregatorsAfter = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(participantAggregatorsBefore.size(), participantAggregatorsAfter.size(), 'Participant Aggregators are being modified');
        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c =: policyId];
        Assert.areEqual(3, aggregators.size(), 'Number of aggregators eliminated is not the expected');
    }

    @isTest
    static void policyAllTrueTest() {
        String whereClause = null;
        List<ARC_ParticipantAggregator__c> participantAggregatorsBefore = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_EliminateDuplicatedAggregators batch_true = new ARC_EliminateDuplicatedAggregators(whereClause, true);
        Database.executeBatch(batch_true);
        Test.stopTest();

        List<ARC_ParticipantAggregator__c> participantAggregatorsAfter = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(participantAggregatorsBefore.size(), participantAggregatorsAfter.size(), 'Participant Aggregators are being modified');
        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c];
        Assert.areEqual(33, aggregators.size(), 'Number of aggregators eliminated is not the expected');
    }

    @isTest
    static void policyAllFalseTest() {
        String whereClause = null;
        List<ARC_ParticipantAggregator__c> participantAggregatorsBefore = [SELECT Id FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_EliminateDuplicatedAggregators batch_false = new ARC_EliminateDuplicatedAggregators(whereClause, false);
        Database.executeBatch(batch_false);
        Test.stopTest();
        
        List<ARC_ParticipantAggregator__c> participantAggregatorsAfter = [SELECT Id FROM ARC_ParticipantAggregator__c];
        Assert.areEqual(participantAggregatorsBefore.size(), participantAggregatorsAfter.size(), 'Participant Aggregators are being modified');
        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c];
        Assert.areEqual(56, aggregators.size(), 'Number of aggregators eliminated is not the expected');
    }
}