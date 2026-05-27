@isTest
public with sharing class ARC_SMBUtilityTest {
    @TestSetup
    static void makeData(){
        Account familyAcc = new Account(Name = 'FamilyAccount Test ');
        insert familyAcc;

        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Integer counter = 0;
        for(Integer i=0; i<2;i++){
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

        // Add newborn
        Account accNewborn = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount2', LastName ='Test');
        accNewborn.BillingStreet = '123 Avenue';
        accNewborn.BillingState = 'NY';
        accNewborn.BillingCity = 'New York';
        accNewborn.BillingPostalCode='12345';
        accNewborn.ARC_IsPrimaryMember__c = false;
        accNewborn.ARC_E123MemberIdFromPolicy__c = 'W1234567892';
        accNewborn.IsActive = true;
        accNewborn.ARC_PreExistingResetDate__c = Date.today().addYears(-1);
        accNewborn.ARC_GroupAccount__c = familyAcc.Id;
        accNewborn.PersonBirthdate = Date.today().addDays(-10);
        accList.add(accNewborn);

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

        List<vlocity_ins__GroupCensusMember__c> censusData =[SELECT Id, vlocity_ins__CensusId__c, vlocity_ins__CensusId__r.vlocity_ins__GroupId__c FROM vlocity_ins__GroupCensusMember__c];
        accList[0].Census_Member__c = censusData[0].Id;
        accList[1].Census_Member__c = censusData[1].Id;
        accList[0].ARC_CensusMember__pc = censusData[0].Id;
        accList[1].ARC_CensusMember__pc = censusData[1].Id;
        accList[0].ARC_Census__c = censusData[0].vlocity_ins__CensusId__c;
        accList[1].ARC_Census__c = censusData[1].vlocity_ins__CensusId__c;
        update accList;

        List<Contract> cont = ARC_TestUtility.createContractsAA(4);
        for (Integer i = 0; i < 4; i++) {
            cont[i].Name = 'WeShare test ' + i;
            cont[i].vlocity_ins__EnrollmentCensusId__c = censusData[0].vlocity_ins__CensusId__c;
            cont[i].AccountId = censusData[0].vlocity_ins__CensusId__r.vlocity_ins__GroupId__c;
        }
        insert cont;

        List<ChargentOrders__ChargentOrder__c> chargentList = new List<ChargentOrders__ChargentOrder__c>();
        for (Integer i = 0; i < 4; i++) {
            ChargentOrders__ChargentOrder__c chargent = new ChargentOrders__ChargentOrder__c();
            chargent.ARC_Contract__c = cont[i].Id;
            chargent.ChargentOrders__Shipping__c = 123;
            chargent.ChargentOrders__Tax__c  = 123;
            chargent.ChargentOrders__Charge_Amount__c = 123;
            chargent.ChargentOrders__Subtotal__c  = 123;
            chargent.ChargentOrders__Charge_Date__c =  '01';
            chargent.ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3);
            chargent.ChargentOrders__Payment_Status__c = 'Recurring';
            chargent.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2021, 11, 12);
            chargent.ChargentOrders__Payment_Method__c = 'Credit Card';
            chargent.ChargentOrders__Card_Last_4__c = '1234';
            chargent.ChargentOrders__Card_Type__c = 'VISA';
            chargent.ChargentOrders__Card_Expiration_Month__c = '12';
            chargent.ChargentOrders__Card_Expiration_Year__c = '2024';
            chargent.ChargentOrders__Tokenization__c = '12345678';
            chargent.ChargentOrders__Description__c = 'Recurring Monthly Order';
            chargentList.add(chargent);
        }
        insert chargentList;

        List<Product2> prodList = ARC_TestUtility.createTestProducts(4);
        for (Integer i = 0; i < 4; i++) {
            prodList[i].vlocity_ins__Type__c = 'Medical';
            prodList[i].Name = 'WeShare';        
            prodList[i].ProductCode = 'PROG_UHSM_Access10k';
        }
        update prodList;


        List<vlocity_ins__ContractLineItem__c> cliList = new List<vlocity_ins__ContractLineItem__c>();
        for (Integer i = 0; i < 4; i++) {
            vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
            cli.Name = 'WeShare'+i;
            cli.ARC_SmokerFee__c = 100;
            cli.ARC_ExtraDependentFee__c = 200;
            cli.ARC_OriginalPrice__c = 0;
            cli.vlocity_ins__UnitPrice__c = 1000;
            cli.vlocity_ins__EffectiveStartDate__c = cont[i].StartDate.addDays(-1);
            cli.vlocity_ins__ContractId__c = cont[i].Id;
            cli.vlocity_ins__Product2Id__c = prodList[i].Id;
            cliList.add(cli);
        }
        insert cliList;

        //contrato 1
        cont[0].Status = 'Terminated';
        cont[0].ARC_ContractReason__c = 'New Application';
        cont[0].ARC_EffectiveDate__c = Date.newInstance(2020, 10, 10);
        // awaiting activation date
        cont[0].ARC_AwaitingActivationDate__c = Date.newInstance(2020, 10, 10);
        cont[0].ARC_Inactive_Date__c = Date.newInstance(2021, 10, 10);
        cont[0].vlocity_ins__ExpiredContractId__c = null;
        cont[0].ARC_MedicalPlan__c = cliList[0].Id;

        // contrato 2
        cont[1].Status = 'Terminated';
        cont[1].ARC_ContractReason__c = 'Program Upgrade';
        cont[1].ARC_EffectiveDate__c = Date.newInstance(2021, 10, 11);
        // awaiting activation date
        cont[1].ARC_AwaitingActivationDate__c = Date.newInstance(2021, 10, 11);
        cont[1].ARC_Inactive_Date__c = Date.newInstance(2023, 10, 10);
        cont[1].vlocity_ins__ExpiredContractId__c = cont[0].Id;
        cont[1].ARC_MedicalPlan__c = cliList[0].Id;
        
        // contrato 3
        cont[2].Status = 'Terminated';
        cont[2].ARC_ContractReason__c = 'Add Newborn';
        cont[2].ARC_EffectiveDate__c = Date.newInstance(2023, 10, 11);
        // awaiting activation date
        cont[2].ARC_AwaitingActivationDate__c = Date.newInstance(2023, 10, 11);
        cont[2].ARC_Inactive_Date__c = Date.today();
        cont[2].vlocity_ins__ExpiredContractId__c = cont[1].Id;
        cont[2].ARC_MedicalPlan__c = cliList[2].Id;

        // contrato 4
        cont[3].Status = 'Awaiting Activation';
        cont[3].ARC_ContractReason__c = 'Program Downgrade';
        cont[3].ARC_EffectiveDate__c = Date.today().addDays(1);
        // awaiting activation date
        cont[3].ARC_AwaitingActivationDate__c = Date.newInstance(2024, 10, 20);
        // cont[3].ARC_Inactive_Date__c = null;
        cont[3].vlocity_ins__ExpiredContractId__c = cont[2].Id;
        cont[3].ARC_MedicalPlan__c = cliList[3].Id;


        for (Integer i = 0; i < 4; i++) {
            cont[i].ARC_RecurringMonthlyOrder__c=chargentList[i].Id;
        }
        update cont;

        cont[2].ARC_Inactive_Date__c = Date.today();

        cont[3].Status = 'Activated';
        update cont;

        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpList = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        for (Integer i = 0; i < 4; i++) {
            vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c();
            gcmp.vlocity_ins__ContractLineId__c = cliList[i].Id;
            gcmp.vlocity_ins__GroupCensusMemberId__c = censusMemberList[0].Id;
            gcmpList.add(gcmp);
        }
        for (Integer i = 2; i < 4; i++) {
            vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c();
            gcmp.vlocity_ins__ContractLineId__c = cliList[i].Id;
            gcmp.vlocity_ins__GroupCensusMemberId__c = censusMemberList[1].Id;
            gcmpList.add(gcmp);
        }
        insert gcmpList;

        // ---------------------- //
        // 9. Insertar 1 Aggregator
        // ---------------------- //
        InsurancePolicy policyTest = new InsurancePolicy();
        policyTest.Name = 'Test Policy';
        policyTest.ARC_Contract__c = cont[3].Id;
        policyTest.NameInsuredId = familyAcc.Id;
        insert policyTest;

        ARC_Aggregator__c newAggregator = new ARC_Aggregator__c();
        newAggregator.Name = 'Pre Existing Conditions';
        newAggregator.ARC_CreatedIn__c = policyTest.Id;
        newAggregator.ARC_Code__c = 'PREEX__c';
        newAggregator.ARC_Member__c = accList[0].Id;
        newAggregator.ARC_Type__c = 'Currency';
        newAggregator.ARC_StartDate__c = Date.today().addYears(-1);
        newAggregator.ARC_BenefitYear__c = 'BY1';
        newAggregator.ARC_LimitValue__c = 15000;

        ARC_Aggregator__c newAggregatorMaternity = new ARC_Aggregator__c();
        newAggregatorMaternity.Name = 'Maternity';
        newAggregatorMaternity.ARC_CreatedIn__c = policyTest.Id;
        newAggregatorMaternity.ARC_Code__c = 'MAT__c';
        newAggregatorMaternity.ARC_Member__c = accList[0].Id;
        newAggregatorMaternity.ARC_Type__c = 'Currency';
        newAggregatorMaternity.ARC_StartDate__c = Date.today().addYears(-1);
        newAggregatorMaternity.ARC_BenefitYear__c = 'BY1';
        newAggregatorMaternity.ARC_LimitValue__c = 15000;

        insert new List<ARC_Aggregator__c>{newAggregator, newAggregatorMaternity};

        // ---------------------- //
        // 10. Insertar 1 Policy Participant
        // ---------------------- //
        InsurancePolicyParticipant policyParticipantTest = new InsurancePolicyParticipant();
        policyParticipantTest.Role = 'Primary';
        policyParticipantTest.InsurancePolicyId	 = policyTest.Id;
        policyParticipantTest.PrimaryParticipantContactId = accountContacts[0].PersonContactId;

        insert policyParticipantTest;

        // ---------------------- //
        // 11. Insertar 1 Claim
        // ---------------------- //
        
        Claim claimTest = ARC_TestUtility.createTestClaims(1)[0];
        claimTest.PolicyNumberId = policyTest.Id;
        update claimTest;

        // ----------------------------------- //
        // 12. Insertar Participant Aggregator //
        // ----------------------------------- //

        ARC_ParticipantAggregator__c participantAggregatorTest = new ARC_ParticipantAggregator__c();
        participantAggregatorTest.Name = 'Pre Existing Conditions';
        participantAggregatorTest.ARC_Aggregator__c = newAggregator.Id;
        participantAggregatorTest.ARC_Policy__c = policyTest.Id;
        participantAggregatorTest.ARC_PolicyParticipant__c = policyParticipantTest.Id;

        ARC_ParticipantAggregator__c participantAggregatorMaternityTest = new ARC_ParticipantAggregator__c();
        participantAggregatorMaternityTest.Name = 'Maternity';
        participantAggregatorMaternityTest.ARC_Aggregator__c = newAggregatorMaternity.Id;
        participantAggregatorMaternityTest.ARC_Policy__c = policyTest.Id;
        participantAggregatorMaternityTest.ARC_PolicyParticipant__c = policyParticipantTest.Id;

        insert new List<ARC_ParticipantAggregator__c>{participantAggregatorTest, participantAggregatorMaternityTest};
    }

    @isTest
    public static void mapCoveragePeriodsTest(){
        Account accountTest = [SELECT Id FROM Account WHERE Name LIKE 'PersonAccount%' LIMIT 1];
        InsurancePolicy policyTest = [SELECT Id, ARC_EffectiveDate__c, ARC_ExpirationDate__c FROM InsurancePolicy WHERE Name = 'Test Policy' LIMIT 1];
        Test.startTest();
        // PREEX__c
        Map<Id, List<Map<String,Object>>> mapCoveragePeriods = ARC_SMBUtility.mapCoveragePeriods(new List<Id>{accountTest.Id}, 'PREEX__c');
        List<String> calculateAggregators = ARC_SMBUtility.calculateAggregators(mapCoveragePeriods.get(accountTest.Id), 'PREEX__c');
        List<String> getPartAggForAggInPolicies = ARC_SMBUtility.getPartAggForAggInPolicies(calculateAggregators[0], new List<InsurancePolicy>{policyTest}, accountTest.Id);
        // MAT__c
        Map<Id, List<Map<String,Object>>> mapCoveragePeriodsMaternity = ARC_SMBUtility.mapCoveragePeriods(new List<Id>{accountTest.Id}, 'MAT__c');
        List<String> calculateAggregatorsMaternity = ARC_SMBUtility.calculateAggregators(mapCoveragePeriodsMaternity.get(accountTest.Id), 'MAT__c');
        List<String> getPartAggForAggInPoliciesMaternity = ARC_SMBUtility.getPartAggForAggInPolicies(calculateAggregatorsMaternity[0], new List<InsurancePolicy>{policyTest}, accountTest.Id);
        Test.stopTest();

        Assert.areEqual('2020-10-10||2021-10-09||BY1||PREEX__c', calculateAggregators[0]);
        Assert.areEqual('2020-10-10||2022-10-09||BY1||MAT__c', calculateAggregatorsMaternity[0]);

    }

    @isTest
    public static void calculateAggregators(){
        List<Map<String, Object>> periods = new List<Map<String, Object>>();

        periods.add(new Map<String, Object>{
            'UHSMProgram' => true,
            'dates' => new List<Date>{ Date.newInstance(2000, 2, 2), Date.newInstance(2001, 2, 1) }
        });
        periods.add(new Map<String, Object>{
            'UHSMProgram' => true,
            'dates' => new List<Date>{ Date.newInstance(2001, 2, 2), Date.newInstance(2001, 2, 1) }
        });
        periods.add(new Map<String, Object>{
            'UHSMProgram' => true,
            'dates' => new List<Date>{ Date.newInstance(2002, 2, 2), Date.newInstance(2003, 2, 1) }
        });
        periods.add(new Map<String, Object>{
            'UHSMProgram' => true,
            'dates' => new List<Date>{ Date.newInstance(2003, 2, 2), Date.newInstance(2004, 2, 1) }
        });

        List<Map<String, Object>> periods2 = new List<Map<String, Object>>();

        periods2.add(new Map<String, Object>{
            'UHSMProgram' => true,
            'dates' => new List<Date>{ Date.newInstance(2000, 2, 2), Date.newInstance(2001, 2, 1) }
        });
        periods2.add(new Map<String, Object>{
            'UHSMProgram' => true,
            'dates' => new List<Date>{ Date.newInstance(2001, 2, 2), Date.newInstance(2001, 2, 1) }
        });
        periods2.add(new Map<String, Object>{
            'UHSMProgram' => true,
            'dates' => new List<Date>{ Date.newInstance(2003, 2, 2), Date.newInstance(2004, 2, 1) }
        });

        Test.startTest();
        ARC_SMBUtility.calculateAggregators(periods, 'PREEX__c');
        ARC_SMBUtility.calculateAggregators(periods2, 'PREEX__c');
        Test.stopTest();
    }
}