@isTest
private class ARC_AggregatorTriggerTest {

    @TestSetup
    static void makeData() {
        Account familyAcc = new Account(Name = 'FamilyAccount Test ');
        insert familyAcc;

        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Integer counter = 0;
        for (Integer i = 0; i < 2; i++) {
            Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount'+i, LastName ='Test');
            acc.BillingStreet = '123 Avenue';
            acc.BillingState = 'NY';
            acc.BillingCity = 'New York';
            acc.BillingPostalCode='12345';
            acc.PersonEmail='test@email.com'+counter;
            acc.ARC_IsPrimaryMember__c = true;
            acc.ARC_E123MemberIdFromPolicy__c = 'W123456789'+counter;
            acc.IsActive = true;
            acc.ARC_PreExistingResetDate__c = Date.today().addYears(-1);
            acc.ARC_GroupAccount__c = familyAcc.Id;
            acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
            accList.add(acc);
        }
        insert accList;

        List <vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(2);
        
        counter = 0;
        List<Account> accountContacts = [SELECT PersonContactId FROM Account WHERE FirstName Like 'PersonAccount%'];
        for(vlocity_ins__GroupCensusMember__c censusMember: censusMemberList){
            censusMember.vlocity_ins__ContactId__c = accountContacts[counter].PersonContactId;
            censusMember.vlocity_ins__SocialSecurityNumber__c = '123456789';
            counter++;
        }
        update censusMemberList;

        List<vlocity_ins__GroupCensusMember__c> censusData = [SELECT Id, vlocity_ins__CensusId__c, vlocity_ins__CensusId__r.vlocity_ins__GroupId__c FROM vlocity_ins__GroupCensusMember__c];
        accList[0].Census_Member__c = censusData[0].Id;
        accList[1].Census_Member__c = censusData[1].Id;
        accList[0].ARC_CensusMember__pc = censusData[0].Id;
        accList[1].ARC_CensusMember__pc = censusData[1].Id;
        accList[0].ARC_Census__c = censusData[0].vlocity_ins__CensusId__c;
        accList[1].ARC_Census__c = censusData[1].vlocity_ins__CensusId__c;
        update accList;

        InsurancePolicy policy = new InsurancePolicy();
        policy.Name = 'Test Policy';
        policy.NameInsuredId = familyAcc.Id;
        insert policy;

        InsurancePolicyParticipant policyParticipant = new InsurancePolicyParticipant();
        policyParticipant.Role = 'Primary';
        policyParticipant.InsurancePolicyId = policy.Id;
        insert policyParticipant;

        Id aggregatorIndMonRecordType = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByDeveloperName().get('IndividualMonthly').getRecordTypeId();
        Id aggregatorFamRecordType = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByDeveloperName().get('Family').getRecordTypeId();
        Id aggregatorIndRecordType = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        ARC_Aggregator__c familyAMCS = new ARC_Aggregator__c(
            Name = 'Family AMCS',
            ARC_Year__c = '2026',
            RecordTypeId = aggregatorFamRecordType,
            ARC_LimitValue__c = 2000
        );

        ARC_Aggregator__c indAMCS = new ARC_Aggregator__c(
            Name = 'Individual AMCS',
            ARC_Year__c = '2026',
            RecordTypeId = aggregatorIndRecordType,
            ARC_StartDate__c = Date.newInstance(2026, 1, 1),
            ARC_EndDate__c = Date.newInstance(2026, 1, 31),
            ARC_LimitValue__c = 1000
        );

        ARC_Aggregator__c indAMCS2 = new ARC_Aggregator__c(
            Name = 'Individual AMCS 2',
            ARC_Year__c = '2026',
            RecordTypeId = aggregatorIndRecordType,
            ARC_StartDate__c = Date.newInstance(2026, 1, 1),
            ARC_EndDate__c = Date.newInstance(2026, 1, 31),
            ARC_LimitValue__c = 1000
        );

        ARC_Aggregator__c critIll = new ARC_Aggregator__c(
            Name = 'Critical Illness and Bill',
            RecordTypeId = aggregatorIndRecordType,
            ARC_EndDate__c = Date.newInstance(2026, 1, 1),
            ARC_LimitValue__c = 2000
        );

        ARC_Aggregator__c critIllMonth = new ARC_Aggregator__c(
            Name = 'Critical Illness and Bill Monthly',
            ARC_Year__c = '2026',
            RecordTypeId = aggregatorIndMonRecordType,
            ARC_StartDate__c = Date.newInstance(2026, 1, 1),
            ARC_EndDate__c = Date.newInstance(2026, 1, 31),
            ARC_LimitValue__c = 1000
        );

        ARC_Aggregator__c critIllMonth2 = new ARC_Aggregator__c(
            Name = 'Critical Illness and Bill Monthly 2',
            ARC_Year__c = '2026',
            RecordTypeId = aggregatorIndMonRecordType,
            ARC_StartDate__c = Date.newInstance(2026, 1, 1),
            ARC_EndDate__c = Date.newInstance(2026, 1, 31),
            ARC_LimitValue__c = 1000
        );

        insert new List<ARC_Aggregator__c>{ familyAMCS, indAMCS, indAMCS2, critIll, critIllMonth, critIllMonth2 };

        indAMCS.ARC_FamilyAggregator__c = familyAMCS.Id;
        critIllMonth.ARC_ParentAggregator__c = critIll.Id;
        indAMCS2.ARC_FamilyAggregator__c = familyAMCS.Id;
        critIllMonth2.ARC_ParentAggregator__c = critIll.Id;
        update new List<ARC_Aggregator__c>{ indAMCS, indAMCS2, critIllMonth, critIllMonth2 };

        ARC_ParticipantAggregator__c pa1 = new ARC_ParticipantAggregator__c(
            ARC_Aggregator__c = indAMCS.Id,
            ARC_ConsumedValue__c = 1000,
            ARC_PolicyParticipant__c = policyParticipant.Id
        );

        ARC_ParticipantAggregator__c pa2 = new ARC_ParticipantAggregator__c(
            ARC_Aggregator__c = indAMCS2.Id,
            ARC_ConsumedValue__c = 1000,
            ARC_PolicyParticipant__c = policyParticipant.Id
        );

        ARC_ParticipantAggregator__c pa3 = new ARC_ParticipantAggregator__c(
            ARC_Aggregator__c = critIllMonth.Id,
            ARC_ConsumedValue__c = 1000,
            ARC_PolicyParticipant__c = policyParticipant.Id
        );

        ARC_ParticipantAggregator__c pa4 = new ARC_ParticipantAggregator__c(
            ARC_Aggregator__c = critIllMonth2.Id,
            ARC_ConsumedValue__c = 1000,
            ARC_PolicyParticipant__c = policyParticipant.Id
        );
        
        insert new List<ARC_ParticipantAggregator__c>{ pa1, pa2, pa3, pa4 };
    }

    @isTest
    static void ARC_AggregatorTriggerTest() {
        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c WHERE Name = 'Individual AMCS' OR Name = 'Critical Illness and Bill Monthly'];
        
        Test.startTest();
        delete aggregators;
        Test.stopTest();

        List<ARC_Aggregator__c> aggregatorsAfter = [SELECT Id, Name, ARC_ParentCurrentValue__c, ARC_FamilyCurrentValue__c FROM ARC_Aggregator__c WHERE Name = 'Family AMCS' OR Name = 'Critical Illness and Bill'];
        ARC_Aggregator__c famAgg;
        ARC_Aggregator__c critAgg;
        for (ARC_Aggregator__c agg : aggregatorsAfter) {
            if (agg.Name == 'Family AMCS') {
                famAgg = agg;
            } else {
                critAgg = agg;
            }
        }
        Assert.areEqual(1000, famAgg.ARC_FamilyCurrentValue__c, 'Family AMCS did not update its consumed value');
        Assert.areEqual(1000, critAgg.ARC_ParentCurrentValue__c, 'Critical Illness did not update its consumed value');
    }
}