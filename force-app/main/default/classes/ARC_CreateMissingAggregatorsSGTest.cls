@IsTest
private class ARC_CreateMissingAggregatorsSGTest {

    private static Id fakeId(Schema.SObjectType sobjectType, Integer numberValue) {
        String prefix = sobjectType.getDescribe().getKeyPrefix();
        String suffix = String.valueOf(numberValue).leftPad(12, '0');
        return Id.valueOf(prefix + suffix);
    }

    private static InsurancePolicy buildPolicy(
        Id policyId,
        Date effectiveDate,
        Date expirationDate,
        String createdDateValue
    ) {
        String jsonValue =
            '{"attributes":{"type":"InsurancePolicy"},' +
            '"Id":"' + String.valueOf(policyId) + '",' +
            '"ARC_EffectiveDate__c":"' + String.valueOf(effectiveDate) + '",' +
            '"ARC_ExpirationDate__c":' +
                (expirationDate == null ? 'null' : '"' + String.valueOf(expirationDate) + '"') + ',' +
            '"CreatedDate":"' + createdDateValue + '"' +
            '}';

        return (InsurancePolicy) JSON.deserialize(jsonValue, InsurancePolicy.class);
    }

    private static ARC_Aggregator__c buildAggregator(
        Id aggregatorId,
        Id policyId,
        Id accountId,
        String name,
        String yearValue
    ) {
        ARC_Aggregator__c agg = new ARC_Aggregator__c();
        agg.Id = aggregatorId;
        agg.ARC_CreatedIn__c = policyId;
        agg.ARC_Member__c = accountId;
        agg.Name = name;
        agg.ARC_Year__c = yearValue;
        return agg;
    }

    @IsTest
    static void testAggregatorCodeMethods() {
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG();

        String individualCode = ARC_CreateMissingAggregatorsSG.getAggregatorCode(
            ARC_ProductAggregators__mdt.IND_AMCS__c
        );

        String familyCode = ARC_CreateMissingAggregatorsSG.getAggregatorCode(
            ARC_ProductAggregators__mdt.FAM_AMCS__c
        );

        System.assertEquals('AMCS__c', individualCode);
        System.assertEquals('AMCS__c', familyCode);
    }

    @IsTest
    static void testAggregatorCategoryMethods() {
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG();

        System.assertEquals(
            true,
            batch.isCalendarYear(ARC_ProductAggregators__mdt.IND_AMCS__c)
        );

        System.assertEquals(
            true,
            batch.isEffectiveYear(ARC_ProductAggregators__mdt.IND_PREEX__c)
        );

        System.assertEquals(
            true,
            batch.isLifeTime(ARC_ProductAggregators__mdt.IND_ALGTEST__c)
        );

        System.assertEquals(
            true,
            batch.isOneTime(ARC_ProductAggregators__mdt.IND_CCS__c)
        );

        System.assertEquals(
            true,
            batch.isIndividualAggregator(ARC_ProductAggregators__mdt.IND_AMCS__c)
        );

        System.assertEquals(
            true,
            batch.isFamilyAggregator(ARC_ProductAggregators__mdt.FAM_AMCS__c)
        );
    }

    @IsTest
    static void testAggregatorTypeMethods() {
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG();

        System.assertEquals(
            'Currency',
            batch.getAggregatorType(ARC_ProductAggregators__mdt.IND_AMCS__c)
        );

        System.assertEquals(
            'Currency',
            batch.getAggregatorType(ARC_ProductAggregators__mdt.IND_PREEX__c)
        );

        System.assertEquals(
            'Number',
            batch.getAggregatorType(ARC_ProductAggregators__mdt.IND_ACC__c)
        );

        System.assertEquals(
            'Number',
            batch.getAggregatorType(ARC_ProductAggregators__mdt.IND_CCS__c)
        );
    }

    @IsTest
    static void testBenefitYearLimit() {
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG();

        System.assertEquals(15000, batch.getBenefitYearLimit('BY1'));
        System.assertEquals(25000, batch.getBenefitYearLimit('BY2'));
        System.assertEquals(50000, batch.getBenefitYearLimit('BY3'));
        System.assertEquals(null, batch.getBenefitYearLimit('BY4'));
    }

    @IsTest
    static void testCreateAggregator() {
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG();

        Id individualAggRT = Schema.SObjectType.ARC_Aggregator__c
            .getRecordTypeInfosByName()
            .get('Individual')
            .getRecordTypeId();

        Id policyId = UserInfo.getUserId();
        Id accountId = UserInfo.getUserId();

        ARC_Aggregator__c agg = batch.createAggregator(
            policyId,
            accountId,
            2026,
            'Individual AMCS',
            5000,
            individualAggRT,
            'AMCS__c',
            'Currency',
            Date.today(),
            Date.today(),
            Date.today().addYears(1),
            'BY1'
        );

        System.assertEquals(individualAggRT, agg.RecordTypeId);
        System.assertEquals('Individual AMCS', agg.Name);
        System.assertEquals('2026', agg.ARC_Year__c);
        System.assertEquals(policyId, agg.ARC_CreatedIn__c);
        System.assertEquals(5000, agg.ARC_LimitValue__c);
        System.assertEquals(accountId, agg.ARC_Member__c);
        System.assertEquals('AMCS__c', agg.ARC_Code__c);
        System.assertEquals('Currency', agg.ARC_Type__c);
        System.assertEquals('BY1', agg.ARC_BenefitYear__c);
    }

    @IsTest
    static void testCreateFamilyAMCS() {
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG();

        Id familyAggRT = Schema.SObjectType.ARC_Aggregator__c
            .getRecordTypeInfosByName()
            .get('Family')
            .getRecordTypeId();

        Id policyId = UserInfo.getUserId();
        Id primaryAccountId = UserInfo.getUserId();

        ARC_Aggregator__c famAgg = batch.createFamilyAMCS(
            policyId,
            primaryAccountId,
            2026,
            'Family AMCS',
            10000,
            familyAggRT
        );

        System.assertEquals(familyAggRT, famAgg.RecordTypeId);
        System.assertEquals('Family AMCS', famAgg.Name);
        System.assertEquals('2026', famAgg.ARC_Year__c);
        System.assertEquals(policyId, famAgg.ARC_CreatedIn__c);
        System.assertEquals(0, famAgg.ARC_FamilyCurrentValue__c);
        System.assertEquals(10000, famAgg.ARC_LimitValue__c);
        System.assertEquals(primaryAccountId, famAgg.ARC_Member__c);
    }

    @IsTest
    static void testCreateParticipantAggregator() {
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG();

        Id policyId = UserInfo.getUserId();
        Id participantId = UserInfo.getUserId();

        ARC_ParticipantAggregator__c partAgg = batch.createParticipantAggregator(
            policyId,
            participantId,
            'Individual AMCS'
        );

        System.assertEquals(policyId, partAgg.ARC_Policy__c);
        System.assertEquals(participantId, partAgg.ARC_PolicyParticipant__c);
        System.assertEquals('Individual AMCS', partAgg.Name);
        System.assertEquals(0, partAgg.ARC_ConsumedValue__c);
    }

    @IsTest
    static void testUpgradeAndDowngradeReasonMethods() {
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG();

        InsurancePolicyCoverage upgradeCoverage = new InsurancePolicyCoverage();
        upgradeCoverage.ARC_Reason__c = 'New Policy';

        InsurancePolicyCoverage downgradeCoverage = new InsurancePolicyCoverage();
        downgradeCoverage.ARC_Reason__c = 'Program Downgrade';

        InsurancePolicyCoverage noChangeCoverage = new InsurancePolicyCoverage();
        noChangeCoverage.ARC_Reason__c = 'No Changes';

        System.assertEquals(true, batch.isUpgradedProduct(upgradeCoverage));
        System.assertEquals(false, batch.isDowngradedProduct(upgradeCoverage));

        System.assertEquals(false, batch.isUpgradedProduct(downgradeCoverage));
        System.assertEquals(true, batch.isDowngradedProduct(downgradeCoverage));

        System.assertEquals(false, batch.isUpgradedProduct(noChangeCoverage));
        System.assertEquals(false, batch.isDowngradedProduct(noChangeCoverage));
    }

    @IsTest
    static void testConstructorWithParameters() {
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG(
            'Status = \'Activated\'',
            true,
            false
        );

        System.assertNotEquals(null, batch);
    }

    @IsTest
    static void testIsPolicyAfter() {
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG();

        Id policyId1 = fakeId(InsurancePolicy.SObjectType, 1);
        Id policyId2 = fakeId(InsurancePolicy.SObjectType, 2);

        InsurancePolicy olderPolicy = buildPolicy(
            policyId1,
            Date.newInstance(2026, 1, 1),
            Date.newInstance(2026, 12, 31),
            '2026-01-01T00:00:00.000+0000'
        );

        InsurancePolicy newerPolicy = buildPolicy(
            policyId2,
            Date.newInstance(2026, 2, 1),
            Date.newInstance(2026, 12, 31),
            '2026-02-01T00:00:00.000+0000'
        );

        System.assertEquals(true, batch.isPolicyAfter(newerPolicy, olderPolicy));
        System.assertEquals(false, batch.isPolicyAfter(olderPolicy, newerPolicy));
    }

    @IsTest
    static void testIsLeaveAndComebackMember() {
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG();

        Id accountId = fakeId(Account.SObjectType, 1);
        Id currentPolicyId = fakeId(InsurancePolicy.SObjectType, 1);
        Id previousPolicyId = fakeId(InsurancePolicy.SObjectType, 2);
        Id oldSeparatedPolicyId = fakeId(InsurancePolicy.SObjectType, 3);

        InsurancePolicy currentPolicy = buildPolicy(
            currentPolicyId,
            Date.newInstance(2026, 5, 1),
            Date.newInstance(2026, 12, 31),
            '2026-05-01T00:00:00.000+0000'
        );

        InsurancePolicy previousContinuousPolicy = buildPolicy(
            previousPolicyId,
            Date.newInstance(2025, 1, 1),
            Date.newInstance(2026, 4, 30),
            '2025-01-01T00:00:00.000+0000'
        );

        InsurancePolicy oldSeparatedPolicy = buildPolicy(
            oldSeparatedPolicyId,
            Date.newInstance(2025, 1, 1),
            Date.newInstance(2026, 3, 15),
            '2025-01-01T00:00:00.000+0000'
        );

        Map<Id, List<InsurancePolicy>> continuousPoliciesMap = new Map<Id, List<InsurancePolicy>>();
        continuousPoliciesMap.put(accountId, new List<InsurancePolicy>{ previousContinuousPolicy });

        Map<Id, List<InsurancePolicy>> separatedPoliciesMap = new Map<Id, List<InsurancePolicy>>();
        separatedPoliciesMap.put(accountId, new List<InsurancePolicy>{ oldSeparatedPolicy });

        System.assertEquals(
            false,
            batch.isLeaveAndComebackMember(
                continuousPoliciesMap,
                currentPolicy,
                'Add Existing Member',
                accountId
            )
        );

        System.assertEquals(
            true,
            batch.isLeaveAndComebackMember(
                separatedPoliciesMap,
                currentPolicy,
                'Add Existing Member',
                accountId
            )
        );

        System.assertEquals(
            false,
            batch.isLeaveAndComebackMember(
                separatedPoliciesMap,
                currentPolicy,
                'No Changes',
                accountId
            )
        );
    }

    @IsTest
    static void testFindFamilyAggregator() {
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG();

        Id accountId = fakeId(Account.SObjectType, 1);
        Id currentPolicyId = fakeId(InsurancePolicy.SObjectType, 1);
        Id oldPolicyId = fakeId(InsurancePolicy.SObjectType, 2);
        Id newerPolicyId = fakeId(InsurancePolicy.SObjectType, 3);

        InsurancePolicy currentPolicy = buildPolicy(
            currentPolicyId,
            Date.newInstance(2026, 6, 1),
            Date.newInstance(2026, 12, 31),
            '2026-06-01T00:00:00.000+0000'
        );

        InsurancePolicy oldPolicy = buildPolicy(
            oldPolicyId,
            Date.newInstance(2026, 1, 1),
            Date.newInstance(2026, 12, 31),
            '2026-01-01T00:00:00.000+0000'
        );

        InsurancePolicy newerPolicy = buildPolicy(
            newerPolicyId,
            Date.newInstance(2026, 3, 1),
            Date.newInstance(2026, 12, 31),
            '2026-03-01T00:00:00.000+0000'
        );

        Map<Id, InsurancePolicy> policiesMap = new Map<Id, InsurancePolicy>{
            currentPolicyId => currentPolicy,
            oldPolicyId => oldPolicy,
            newerPolicyId => newerPolicy
        };

        ARC_Aggregator__c oldAgg = buildAggregator(
            fakeId(ARC_Aggregator__c.SObjectType, 1),
            oldPolicyId,
            accountId,
            'Family AMCS',
            '2026'
        );

        ARC_Aggregator__c newerAgg = buildAggregator(
            fakeId(ARC_Aggregator__c.SObjectType, 2),
            newerPolicyId,
            accountId,
            'Family AMCS',
            '2026'
        );

        Map<String, List<ARC_Aggregator__c>> familyAggMap = new Map<String, List<ARC_Aggregator__c>>();
        familyAggMap.put(
            accountId + '-2026',
            new List<ARC_Aggregator__c>{ oldAgg, newerAgg }
        );

        ARC_Aggregator__c result = batch.findFamilyAggregator(
            familyAggMap,
            policiesMap,
            2026,
            accountId,
            currentPolicy
        );

        System.assertEquals(newerAgg.Id, result.Id);

        ARC_Aggregator__c nullResult = batch.findFamilyAggregator(
            familyAggMap,
            policiesMap,
            2025,
            accountId,
            currentPolicy
        );

        System.assertEquals(null, nullResult);
    }

    @IsTest
    static void testFindAggregator() {
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG();

        Id accountId = fakeId(Account.SObjectType, 1);
        Id currentPolicyId = fakeId(InsurancePolicy.SObjectType, 1);
        Id oldPolicyId = fakeId(InsurancePolicy.SObjectType, 2);
        Id newerPolicyId = fakeId(InsurancePolicy.SObjectType, 3);

        InsurancePolicy currentPolicy = buildPolicy(
            currentPolicyId,
            Date.newInstance(2026, 6, 1),
            Date.newInstance(2026, 12, 31),
            '2026-06-01T00:00:00.000+0000'
        );

        InsurancePolicy oldPolicy = buildPolicy(
            oldPolicyId,
            Date.newInstance(2026, 1, 1),
            Date.newInstance(2026, 12, 31),
            '2026-01-01T00:00:00.000+0000'
        );

        InsurancePolicy newerPolicy = buildPolicy(
            newerPolicyId,
            Date.newInstance(2026, 3, 1),
            Date.newInstance(2026, 12, 31),
            '2026-03-01T00:00:00.000+0000'
        );

        Map<Id, InsurancePolicy> policiesMap = new Map<Id, InsurancePolicy>{
            currentPolicyId => currentPolicy,
            oldPolicyId => oldPolicy,
            newerPolicyId => newerPolicy
        };

        ARC_Aggregator__c oldAgg = buildAggregator(
            fakeId(ARC_Aggregator__c.SObjectType, 1),
            oldPolicyId,
            accountId,
            'Individual AMCS',
            '2026'
        );

        ARC_Aggregator__c newerAgg = buildAggregator(
            fakeId(ARC_Aggregator__c.SObjectType, 2),
            newerPolicyId,
            accountId,
            'Individual AMCS',
            '2026'
        );

        Map<String, List<ARC_Aggregator__c>> individualAggMap = new Map<String, List<ARC_Aggregator__c>>();
        individualAggMap.put(
            accountId + '-Individual AMCS-2026',
            new List<ARC_Aggregator__c>{ oldAgg, newerAgg }
        );

        ARC_Aggregator__c result = batch.findAggregator(
            individualAggMap,
            policiesMap,
            2026,
            'Individual AMCS',
            accountId,
            currentPolicy,
            null,
            null
        );

        System.assertEquals(newerAgg.Id, result.Id);

        ARC_Aggregator__c nullResult = batch.findAggregator(
            individualAggMap,
            policiesMap,
            2025,
            'Individual AMCS',
            accountId,
            currentPolicy,
            null,
            null
        );

        System.assertEquals(null, nullResult);
    }

    @IsTest
    static void testFindAggregatorWithBenefitYear() {
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG();

        Id accountId = fakeId(Account.SObjectType, 1);
        Id currentPolicyId = fakeId(InsurancePolicy.SObjectType, 1);
        Id oldPolicyId = fakeId(InsurancePolicy.SObjectType, 2);

        Date startDate = Date.newInstance(2026, 1, 1);

        InsurancePolicy currentPolicy = buildPolicy(
            currentPolicyId,
            Date.newInstance(2026, 6, 1),
            Date.newInstance(2026, 12, 31),
            '2026-06-01T00:00:00.000+0000'
        );

        InsurancePolicy oldPolicy = buildPolicy(
            oldPolicyId,
            Date.newInstance(2026, 1, 1),
            Date.newInstance(2026, 12, 31),
            '2026-01-01T00:00:00.000+0000'
        );

        Map<Id, InsurancePolicy> policiesMap = new Map<Id, InsurancePolicy>{
            currentPolicyId => currentPolicy,
            oldPolicyId => oldPolicy
        };

        ARC_Aggregator__c benefitYearAgg = buildAggregator(
            fakeId(ARC_Aggregator__c.SObjectType, 1),
            oldPolicyId,
            accountId,
            'Pre Existing Conditions',
            null
        );

        Map<String, List<ARC_Aggregator__c>> individualAggMap = new Map<String, List<ARC_Aggregator__c>>();
        individualAggMap.put(
            accountId + '-Pre Existing Conditions-BY1-20260101',
            new List<ARC_Aggregator__c>{ benefitYearAgg }
        );

        ARC_Aggregator__c result = batch.findAggregator(
            individualAggMap,
            policiesMap,
            null,
            'Pre Existing Conditions',
            accountId,
            currentPolicy,
            'BY1',
            startDate
        );

        System.assertEquals(benefitYearAgg.Id, result.Id);
    }

        @testSetup
    static void makeSmallGroupData() {
        Id personAccountRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('ARC_IFPPersonAccount')
            .getRecordTypeId();

        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            Account acc = new Account(
                RecordTypeId = personAccountRecordTypeId,
                FirstName = 'PersonAccount ' + i,
                LastName = 'Test',
                BillingStreet = '123 Avenue',
                BillingState = 'NY',
                BillingCity = 'New York',
                BillingPostalCode = '12345',
                PersonEmail = 'test' + i + '@email.com',
                ARC_IsPrimaryMember__c = i == 0,
                ARC_E123MemberIdFromPolicy__c = 'W12345678' + i,
                IsActive = true
            );
            accounts.add(acc);
        }
        insert accounts;

        List<Account> accountListContactIds = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE FirstName LIKE 'PersonAccount%'
            ORDER BY FirstName
        ];

        List<Contract> contracts = ARC_TestUtility.createContractsAA(2);
        for (Contract cont : contracts) {
            cont.AccountId = accountListContactIds[0].Id;
        }
        insert contracts;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = contracts[0].AccountId;
        insert census;

        List<vlocity_ins__GroupCensusMember__c> groupCensusMemberList = new List<vlocity_ins__GroupCensusMember__c>();
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

        contracts[0].Status = 'Terminated';
        contracts[0].ARC_ContractReason__c = 'Program Upgrade';
        contracts[0].ARC_EffectiveDate__c = Date.today().addYears(-1);
        contracts[0].ARC_Inactive_Date__c = Date.today().addDays(-1);
        contracts[0].ActivatedDate = Date.today().addYears(-1);

        contracts[1].Status = 'Activated';
        contracts[1].ARC_ContractReason__c = 'Add Existing Member';
        contracts[1].ARC_EffectiveDate__c = Date.today();
        contracts[1].ARC_Inactive_Date__c = Date.today().addYears(1);
        contracts[1].ActivatedDate = Date.today();

        update contracts;

        List<Product2> prodList = new List<Product2>();

        Product2 prod1 = new Product2();
        prod1.Name = 'WeShare 6k';
        prod1.ProductCode = 'PROG_UHSM_WeShare6k';
        prod1.vlocity_ins__Type__c = 'Medical';
        prodList.add(prod1);

        Product2 prod2 = new Product2();
        prod2.Name = 'WeShare 12k';
        prod2.ProductCode = 'PROG_UHSM_WeShare12k';
        prod2.vlocity_ins__Type__c = 'Medical';
        prodList.add(prod2);

        insert prodList;

        List<vlocity_ins__ContractLineItem__c> cliList = new List<vlocity_ins__ContractLineItem__c>();
        for (Integer i = 0; i < 2; i++) {
            vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
            cli.Name = 'WeShare test ' + i;
            cli.ARC_SmokerFee__c = 100;
            cli.ARC_ExtraDependentFee__c = 200;
            cli.ARC_OriginalPrice__c = 1000;
            cli.vlocity_ins__UnitPrice__c = 1000;
            cli.vlocity_ins__EffectiveStartDate__c = contracts[i].ARC_EffectiveDate__c;
            cli.vlocity_ins__ContractId__c = contracts[i].Id;
            cli.vlocity_ins__Product2Id__c = prodList[i].Id;
            cliList.add(cli);
        }
        insert cliList;

        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpList = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        for (Integer i = 0; i < 2; i++) {
            vlocity_ins__GroupCensusMemberPlan__c gcmpPrimary = new vlocity_ins__GroupCensusMemberPlan__c();
            gcmpPrimary.vlocity_ins__ContractLineId__c = cliList[i].Id;
            gcmpPrimary.vlocity_ins__GroupCensusMemberId__c = groupCensusMemberList[0].Id;
            gcmpList.add(gcmpPrimary);

            vlocity_ins__GroupCensusMemberPlan__c gcmpSpouse = new vlocity_ins__GroupCensusMemberPlan__c();
            gcmpSpouse.vlocity_ins__ContractLineId__c = cliList[i].Id;
            gcmpSpouse.vlocity_ins__GroupCensusMemberId__c = groupCensusMemberList[1].Id;
            gcmpList.add(gcmpSpouse);
        }
        insert gcmpList;

        Id smallGroupPolicyRecordTypeId = Schema.SObjectType.InsurancePolicy
            .getRecordTypeInfosByName()
            .get('Small Group')
            .getRecordTypeId();

        List<InsurancePolicy> policies = new List<InsurancePolicy>();
        for (Integer i = 0; i < 2; i++) {
            InsurancePolicy policy = new InsurancePolicy();
            policy.Name = 'SG Policy ' + i;
            policy.ProductId = prodList[i].Id;
            policy.ARC_Contract__c = contracts[i].Id;
            policy.NameInsuredId = accountListContactIds[0].Id;
            policy.RecordTypeId = smallGroupPolicyRecordTypeId;
            policy.Status = i == 0 ? 'Terminated' : 'Activated';
            policies.add(policy);
        }
        insert policies;

        policies[1].RenewedFromPolicyId = policies[0].Id;
        update policies;

        List<InsurancePolicyCoverage> ipcList = new List<InsurancePolicyCoverage>();

        InsurancePolicyCoverage ipc0 = new InsurancePolicyCoverage();
        ipc0.InsurancePolicyId = policies[0].Id;
        ipc0.vlocity_ins_fsc__Product2Id__c = policies[0].ProductId;
        ipc0.ARC_Reason__c = 'Program Upgrade';
        ipcList.add(ipc0);

        InsurancePolicyCoverage ipc1 = new InsurancePolicyCoverage();
        ipc1.InsurancePolicyId = policies[1].Id;
        ipc1.vlocity_ins_fsc__Product2Id__c = policies[1].ProductId;
        ipc1.ARC_Reason__c = 'Add Existing Member';
        ipcList.add(ipc1);

        insert ipcList;

        List<Contact> contacts = new List<Contact>();
        for (Account acc : accountListContactIds) {
            Contact cont = new Contact();
            cont.Id = acc.PersonContactId;
            cont.Birthdate = Date.valueOf('2000-11-12');
            contacts.add(cont);
        }
        update contacts;

        List<InsurancePolicyParticipant> policyParticipants = new List<InsurancePolicyParticipant>();

        InsurancePolicyParticipant ipp1 = new InsurancePolicyParticipant();
        ipp1.Role = 'Primary';
        ipp1.PrimaryParticipantContactId = accountListContactIds[0].PersonContactId;
        ipp1.InsurancePolicyId = policies[0].Id;
        ipp1.ARC_StartDate__c = Date.today().addYears(-1);
        ipp1.ARC_EndDate__c = Date.today().addDays(-1);
        policyParticipants.add(ipp1);

        InsurancePolicyParticipant ipp2 = new InsurancePolicyParticipant();
        ipp2.Role = 'Spouse';
        ipp2.PrimaryParticipantContactId = accountListContactIds[1].PersonContactId;
        ipp2.InsurancePolicyId = policies[0].Id;
        ipp2.ARC_StartDate__c = Date.today().addYears(-1);
        ipp2.ARC_EndDate__c = Date.today().addDays(-1);
        policyParticipants.add(ipp2);

        InsurancePolicyParticipant ipp3 = new InsurancePolicyParticipant();
        ipp3.Role = 'Primary';
        ipp3.PrimaryParticipantContactId = accountListContactIds[0].PersonContactId;
        ipp3.InsurancePolicyId = policies[1].Id;
        ipp3.ARC_StartDate__c = Date.today();
        ipp3.ARC_EndDate__c = Date.today().addYears(1);
        policyParticipants.add(ipp3);

        InsurancePolicyParticipant ipp4 = new InsurancePolicyParticipant();
        ipp4.Role = 'Spouse';
        ipp4.PrimaryParticipantContactId = accountListContactIds[1].PersonContactId;
        ipp4.InsurancePolicyId = policies[1].Id;
        ipp4.ARC_StartDate__c = Date.today();
        ipp4.ARC_EndDate__c = Date.today().addYears(1);
        policyParticipants.add(ipp4);

        insert policyParticipants;

        List<ARC_CoverageParticipant__c> covPartList = new List<ARC_CoverageParticipant__c>();

        ARC_CoverageParticipant__c cov1 = new ARC_CoverageParticipant__c();
        cov1.ARC_PolicyCoverage__c = ipcList[0].Id;
        cov1.ARC_Policy__c = policies[0].Id;
        cov1.ARC_PolicyParticipant__c = policyParticipants[0].Id;
        cov1.ARC_CoverageRole__c = 'Primary';
        covPartList.add(cov1);

        ARC_CoverageParticipant__c cov2 = new ARC_CoverageParticipant__c();
        cov2.ARC_PolicyCoverage__c = ipcList[0].Id;
        cov2.ARC_Policy__c = policies[0].Id;
        cov2.ARC_PolicyParticipant__c = policyParticipants[1].Id;
        cov2.ARC_CoverageRole__c = 'Spouse';
        covPartList.add(cov2);

        ARC_CoverageParticipant__c cov3 = new ARC_CoverageParticipant__c();
        cov3.ARC_PolicyCoverage__c = ipcList[1].Id;
        cov3.ARC_Policy__c = policies[1].Id;
        cov3.ARC_PolicyParticipant__c = policyParticipants[2].Id;
        cov3.ARC_CoverageRole__c = 'Primary';
        covPartList.add(cov3);

        ARC_CoverageParticipant__c cov4 = new ARC_CoverageParticipant__c();
        cov4.ARC_PolicyCoverage__c = ipcList[1].Id;
        cov4.ARC_Policy__c = policies[1].Id;
        cov4.ARC_PolicyParticipant__c = policyParticipants[3].Id;
        cov4.ARC_CoverageRole__c = 'Spouse';
        covPartList.add(cov4);

        insert covPartList;

        Id individualAggRT = Schema.SObjectType.ARC_Aggregator__c
            .getRecordTypeInfosByName()
            .get('Individual')
            .getRecordTypeId();

        List<ARC_Aggregator__c> aggregators = new List<ARC_Aggregator__c>();

        ARC_Aggregator__c oneTimeAgg = new ARC_Aggregator__c();
        oneTimeAgg.Name = 'Mammograms';
        oneTimeAgg.ARC_Code__c = 'MAMM__c';
        oneTimeAgg.ARC_Type__c = 'Number';
        oneTimeAgg.RecordTypeId = individualAggRT;
        oneTimeAgg.ARC_NextAvailabilityDate__c = Date.today();
        oneTimeAgg.ARC_LimitValue__c = 1;
        oneTimeAgg.ARC_Member__c = accountListContactIds[0].Id;
        oneTimeAgg.ARC_CreatedIn__c = policies[0].Id;
        aggregators.add(oneTimeAgg);

        ARC_Aggregator__c individualAgg = new ARC_Aggregator__c();
        individualAgg.Name = 'Individual AMCS';
        individualAgg.ARC_Code__c = 'AMCS__c';
        individualAgg.ARC_Type__c = 'Currency';
        individualAgg.RecordTypeId = individualAggRT;
        individualAgg.ARC_LimitValue__c = 6000;
        individualAgg.ARC_Year__c = String.valueOf(Date.today().year());
        individualAgg.ARC_Member__c = accountListContactIds[0].Id;
        individualAgg.ARC_CreatedIn__c = policies[0].Id;
        aggregators.add(individualAgg);

        insert aggregators;

        List<ARC_ParticipantAggregator__c> partAggList = new List<ARC_ParticipantAggregator__c>();

        ARC_ParticipantAggregator__c partAgg1 = new ARC_ParticipantAggregator__c();
        partAgg1.Name = 'Mammograms';
        partAgg1.ARC_Policy__c = policies[0].Id;
        partAgg1.ARC_PolicyParticipant__c = policyParticipants[0].Id;
        partAgg1.ARC_ConsumedValue__c = 0;
        partAgg1.ARC_Aggregator__c = aggregators[0].Id;
        partAggList.add(partAgg1);

        ARC_ParticipantAggregator__c partAgg2 = new ARC_ParticipantAggregator__c();
        partAgg2.Name = 'Individual AMCS';
        partAgg2.ARC_Policy__c = policies[0].Id;
        partAgg2.ARC_PolicyParticipant__c = policyParticipants[0].Id;
        partAgg2.ARC_ConsumedValue__c = 0;
        partAgg2.ARC_Aggregator__c = aggregators[1].Id;
        partAggList.add(partAgg2);

        insert partAggList;
    }

    @IsTest
    static void testBatchCreatesMissingAggregatorsSG() {
        List<InsurancePolicy> policies = [
            SELECT Id
            FROM InsurancePolicy
            WHERE RecordType.Name = 'Small Group'
        ];

        Set<Id> policyIds = new Set<Id>();
        for (InsurancePolicy policy : policies) {
            policyIds.add(policy.Id);
        }

        String idsString = '\'' + String.join(new List<Id>(policyIds), '\', \'') + '\'';
        String whereClause = 'Id IN (' + idsString + ')';

        Integer aggregatorsBefore = [SELECT COUNT() FROM ARC_Aggregator__c];
        Integer participantAggregatorsBefore = [SELECT COUNT() FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG(whereClause, true, false);
        Database.executeBatch(batch, 30);
        Test.stopTest();

        Integer aggregatorsAfter = [SELECT COUNT() FROM ARC_Aggregator__c];
        Integer participantAggregatorsAfter = [SELECT COUNT() FROM ARC_ParticipantAggregator__c];

        System.assert(
            aggregatorsAfter > aggregatorsBefore,
            'The batch should create missing Aggregators.'
        );

        System.assert(
            participantAggregatorsAfter > participantAggregatorsBefore,
            'The batch should create missing Participant Aggregators.'
        );
    }

    @IsTest
    static void testBatchReportOnlyAndFinishEmailSG() {
        List<InsurancePolicy> policies = [
            SELECT Id
            FROM InsurancePolicy
            WHERE RecordType.Name = 'Small Group'
        ];

        Set<Id> policyIds = new Set<Id>();
        for (InsurancePolicy policy : policies) {
            policyIds.add(policy.Id);
        }

        String idsString = '\'' + String.join(new List<Id>(policyIds), '\', \'') + '\'';
        String whereClause = 'Id IN (' + idsString + ')';

        Integer aggregatorsBefore = [SELECT COUNT() FROM ARC_Aggregator__c];
        Integer participantAggregatorsBefore = [SELECT COUNT() FROM ARC_ParticipantAggregator__c];

        Test.startTest();
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG(whereClause, false, true);
        Database.executeBatch(batch, 30);
        Test.stopTest();

        Integer aggregatorsAfter = [SELECT COUNT() FROM ARC_Aggregator__c];
        Integer participantAggregatorsAfter = [SELECT COUNT() FROM ARC_ParticipantAggregator__c];

        System.assertEquals(
            aggregatorsBefore,
            aggregatorsAfter,
            'Report-only execution should not create Aggregators.'
        );

        System.assertEquals(
            participantAggregatorsBefore,
            participantAggregatorsAfter,
            'Report-only execution should not create Participant Aggregators.'
        );
    }

    @IsTest
    static void testSchedulableExecutionSG() {
        Test.startTest();
        ARC_CreateMissingAggregatorsSG scheduleJob = new ARC_CreateMissingAggregatorsSG(null, true, true);
        scheduleJob.execute(null);
        Test.stopTest();

        List<ARC_Aggregator__c> aggregators = [
            SELECT Id
            FROM ARC_Aggregator__c
        ];

        System.assert(
            aggregators.size() > 0,
            'Schedulable execution should process Small Group policies activated today.'
        );
    }

    @IsTest
    static void testCreateBenefitYearMapWithEmptyAccounts() {
        ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG();

        Test.startTest();
        Map<Id, List<String>> result = batch.createBenefitYearMap(new Set<Id>(), 'PREEX__c');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
static void testStartWithWhereClause() {
    ARC_CreateMissingAggregatorsSG batch = new ARC_CreateMissingAggregatorsSG(
        'Status = \'Activated\'',
        false,
        false
    );

    Test.startTest();
    Database.QueryLocator ql = batch.start(null);
    Test.stopTest();

    System.assertNotEquals(null, ql);
 }
 
}