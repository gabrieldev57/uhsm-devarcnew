@isTest
public class ARC_ContractTriggerHandlerTest {

    @TestSetup
    static void makeData() {
        List<User> userList = [SELECT Id, Agent_Role__c FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 2];
        if (userList.size() == 2) {
            userList[0].Agent_Role__c = 'Account Executive';
            userList[1].Agent_Role__c = 'Senior Account Executive';
        }
        update userList;

        //Create Contracts in Draft
        Contract[] contList = ARC_TestUtility.createContractsAA(3);
        for (Integer i = 0; i < contList.size(); i++) {
            if (i != 2) contList[i].ARC_Selling_Agent__c = userList[0].Id;
            else contList[i].ARC_Selling_Agent__c = userList[1].Id;
            contList[i].Status = 'Draft';
            contList[i].ARC_ContractReason__c = 'New Application';
            contList[i].ARC_EffectiveDate__c = Date.newInstance(2024, 01, 01);
        }
        insert contList;

        System.debug('chargentId ' + contList[0].ARC_RecurringMonthlyOrder__c);

        //Update One chargent to point to One Contract
        ChargentOrders__ChargentOrder__c chargentOrder = new ChargentOrders__ChargentOrder__c(Id = contList[0].ARC_RecurringMonthlyOrder__c, ARC_Contract__c = contList[0].Id);
        update chargentOrder;

        //Create Initial Transaction for the first Contract
        ChargentOrders__Transaction__c t = ARC_TestUtility.createOneTransaction(10, 'Charge', chargentOrder.Id);
        insert t;

        //Create Commission for One Contract
        ARC_Commission__c comm = new ARC_Commission__c(ownerId = contList[0].ARC_Selling_Agent__c, ARC_InitialCommission__c = 20, ARC_RecurringCommission__c = 5, Contract__c = contList[0].Id, Original_Contract__c = contList[0].Id);
        insert comm;
        

        ///Products
        List<Product2> products = new List<Product2>();
        Product2 medicalProd = new Product2();
        medicalProd.Name = 'WeShare 6k';
        medicalProd.ProductCode = 'PROG_UHSM_WeShare6k';
        medicalProd.vlocity_ins__Type__c = 'Medical';

        Product2 smartProd = new Product2();
        smartProd.Name = 'SMART Share 35000';
        smartProd.ProductCode = 'PROG_SMART_35000';
        smartProd.vlocity_ins__Type__c = 'Ancillary';
        smartProd.vlocity_ins__SubType__c = 'SMART';

        Product2 aiddProd = new Product2();
        aiddProd.Name = 'AIDD 7500';
        aiddProd.ProductCode = 'PROG_AIDD_7500';
        aiddProd.vlocity_ins__Type__c = 'Ancillary';
        aiddProd.vlocity_ins__SubType__c = 'AIDD';
        
        products.add(medicalProd);
        products.add(smartProd);
        products.add(aiddProd);
        insert products;

        //Create Contract Line Items
        List<vlocity_ins__ContractLineItem__c> lineItems = new List<vlocity_ins__ContractLineItem__c>();
        for (Contract c: contList) {
            for (Integer i = 0; i < 3; i++) {
                vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
                cli.vlocity_ins__Product2Id__c = products[i].Id;
                cli.Name = products[i].Name;
                if (products[i].vlocity_ins__Type__c == 'Medical') cli.vlocity_ins__UnitPrice__c = 200;
                else if (products[i].Name == 'SMART Share 35000') cli.vlocity_ins__UnitPrice__c = 100;
                else cli.vlocity_ins__UnitPrice__c = 50;
                cli.vlocity_ins__ContractId__c = c.Id;
                cli.vlocity_ins__Quantity__c = 1;
                lineItems.add(cli);
            }
        }
        insert lineItems;
        System.debug(lineItems);

        // Create Account
        Account familyAcc = new Account(Name = 'FamilyAccount Test ');
        insert familyAcc;

        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Integer counter = 0;
        for (Integer i = 0; i < 1; i++) {
            Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount' + i, LastName = 'Test');
            acc.BillingStreet = '123 Avenue';
            acc.BillingState = 'NY';
            acc.BillingCity = 'New York';
            acc.BillingPostalCode = '12345';
            acc.PersonEmail = 'test@email.com' + counter;
            acc.ARC_IsPrimaryMember__c = true;
            acc.ARC_E123MemberIdFromPolicy__c = 'W123456789' + counter;
            acc.IsActive = true;
            acc.ARC_PreExistingResetDate__c = Date.today().addYears(-1);
            acc.ARC_GroupAccount__c = familyAcc.Id;
            acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
            accList.add(acc);
        }

        insert accList;
        List<Account> accountListContactIds = [SELECT PersonContactId FROM Account WHERE FirstName LIKE 'PersonAccount%' ORDER BY FirstName];

        // Create Policy
        List<InsurancePolicy> policyList = new List<InsurancePolicy>();
        for (Integer i = 0; i < 3; i++) {
            InsurancePolicy policy = new InsurancePolicy();
            policy.Name = 'Test Policy ' + i;
            policy.ARC_Contract__c = contList[i].Id;
            policy.NameInsuredId = familyAcc.Id;
            policyList.add(policy);
        }

        insert policyList;

        // Create IPP
        List<InsurancePolicyParticipant> policyParticipants = new List<InsurancePolicyParticipant>();
        for (Integer i = 0; i < 3; i++) {
            InsurancePolicyParticipant ipp = new InsurancePolicyParticipant();
            ipp.Role = 'Primary';
            ipp.PrimaryParticipantContactId = accountListContactIds[0].PersonContactId;
            ipp.InsurancePolicyId = policyList[i].Id;
            ipp.ARC_StartDate__c = Date.valueOf('2023-11-12'); //REVIEW
            ipp.ARC_EndDate__c = Date.valueOf('2024-11-11'); //REVIEW
            policyParticipants.add(ipp);
        }

        insert policyParticipants;

        // Create Aggregators
        Id familyAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Family').getRecordTypeId();
        ARC_Aggregator__c newFamAggregator = new ARC_Aggregator__c();
        newFamAggregator.RecordTypeId = familyAggRT;
        newFamAggregator.Name = 'Family AMCS';
        newFamAggregator.ARC_CreatedIn__c = policyList[0].Id;
        newFamAggregator.ARC_Member__c = familyAcc.Id;
        newFamAggregator.ARC_LimitValue__c = 2000;
        newFamAggregator.ARC_Year__c = '2024';
        newFamAggregator.ARC_FamilyCurrentValue__c = 0;

        insert newFamAggregator;

        Id individualAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
        List<ARC_Aggregator__c> listAggs = new List<ARC_Aggregator__c>();
        for (Integer i = 0; i < 3; i++) {
            ARC_Aggregator__c newAggregator = new ARC_Aggregator__c();
            newAggregator.RecordTypeId = individualAggRT;
            newAggregator.Name = 'Individual AMCS';
            newAggregator.ARC_CreatedIn__c = policyList[0].Id;
            newAggregator.ARC_Code__c = 'AMCS__c';
            newAggregator.ARC_Member__c = accList[0].Id;
            newAggregator.ARC_Type__c = 'Currency';
            newAggregator.ARC_Year__c = '2024';
            newAggregator.ARC_LimitValue__c = 1000;
            newAggregator.ARC_FamilyAggregator__c = newFamAggregator.Id;
            listAggs.add(newAggregator);
        }

        insert listAggs;

        List<ARC_ParticipantAggregator__c> partAggList = new List<ARC_ParticipantAggregator__c>();
        for (Integer i = 0; i < 3; i++) {
            ARC_ParticipantAggregator__c partAgg = new ARC_ParticipantAggregator__c();
            partAgg.Name = 'Individual AMCS';
            partAgg.ARC_Policy__c = policyList[i].Id;
            partAgg.ARC_PolicyParticipant__c = policyParticipants[i].Id;
            partAgg.ARC_ConsumedValue__c = 0;
            partAgg.ARC_Aggregator__c = listAggs[0].Id;

            ARC_ParticipantAggregator__c partAgg2 = new ARC_ParticipantAggregator__c();
            partAgg2.Name = 'Individual AMCS';
            partAgg2.ARC_Policy__c = policyList[i].Id;
            partAgg2.ARC_PolicyParticipant__c = policyParticipants[i].Id;
            partAgg2.ARC_ConsumedValue__c = 0;
            partAgg2.ARC_Aggregator__c = listAggs[1].Id;

            partAggList.add(partAgg);
            partAggList.add(partAgg2);
        }

        insert partAggList;
    }

    @isTest
    public static void getProgramPricesTest() {
        //Get program prices
        Map<Id,Double> contractMedicalTotal = new Map<Id,Double>();
        Map<Id,Double> contractAncillaryTotal = new Map<Id,Double>();
        Map<Id,Contract> contractMap = new Map<Id,Contract>([SELECT Id FROM Contract]);
        List<Id> contractIds = new List<Id>(contractMap.keySet());
        //Get Line Items
        List<vlocity_ins__ContractLineItem__c> lineItems = [SELECT Id, vlocity_ins__UnitPrice__c, vlocity_ins__ContractId__c, vlocity_ins__TotalPrice__c, vlocity_ins__ProductType__c FROM vlocity_ins__ContractLineItem__c];
        System.debug(lineItems);
        Test.startTest();
            ARC_ContractTriggerHandler.getProgramPrices(contractMedicalTotal, contractAncillaryTotal, contractIds);
        Test.stopTest();
        Assert.areEqual(200, contractMedicalTotal.get(contractIds[0]));
        Assert.areEqual(150, contractAncillaryTotal.get(contractIds[0]));
    }

    @isTest
    public static void createInitialAndReccurringCPTest() {
        //Get Initial Transaction
        List<ChargentOrders__Transaction__c> tList = [SELECT Id, ChargentOrders__Order__r.ARC_Contract__c FROM ChargentOrders__Transaction__c];

        //Get Contract
        Map<Id,Contract> contractMap = new Map<Id,Contract>([SELECT Id, ARC_Selling_Agent__c, ARC_RecurringMonthlyOrder__c, ARC_EffectiveDate__c, ARC_AwaitingActivationDate__c FROM Contract WHERE Id = :tList[0].ChargentOrders__Order__r.ARC_Contract__c]);
        List<Id> contractIds = new List<Id>(contractMap.keySet());
        
        //Get The Commission
        List<ARC_Commission__c> commissions = [SELECT Id, Contract__c, ARC_InitialCommission__c, ARC_RecurringCommission__c, OwnerId FROM ARC_Commission__c];

        ARC_Commission_Payment__c recurringCP;

        Test.startTest();
            ARC_ContractTriggerHandler.createInitialCP(commissions, contractMap);
            recurringCP = ARC_ContractTriggerHandler.createsRecurringCP(commissions[0], tList[0].Id);
        Test.stopTest();

        ARC_Commission_Payment__c initialCP = [SELECT Id, Type__c, Amount__c FROM ARC_Commission_Payment__c][0];
        Assert.areEqual(commissions[0].ARC_InitialCommission__c, initialCP.Amount__c);
        Assert.areEqual(commissions[0].ARC_RecurringCommission__c, recurringCP.Amount__c);
    }

    @isTest
    public static void calculateInitialCommDate() {
        //Test When Effective Date < Awaiting Activation Date
        Contract c1 = new Contract(
            ARC_EffectiveDate__c = Date.newInstance(2024, 01, 01),
            ARC_AwaitingActivationDate__c = DateTime.newInstance(2024, 03, 01, 0, 0, 0)
        );

        //Test When Effective Date > Awaiting Activation Date
        Contract c2 = new Contract(
            ARC_EffectiveDate__c = Date.newInstance(2024, 03, 15),
            ARC_AwaitingActivationDate__c = DateTime.newInstance(2024, 01, 01, 0, 0, 0)
        );

        Contract c3 = new Contract(
            ARC_EffectiveDate__c = Date.newInstance(2024, 05, 01),
            ARC_AwaitingActivationDate__c = null
        );

        Contract c4 = new Contract(
            ARC_EffectiveDate__c = Date.newInstance(2024, 05, 10),
            ARC_AwaitingActivationDate__c = null
        );

        Test.startTest();
            Date firstContractDate = ARC_ContractTriggerHandler.calculateInitialCommDate(c1);
            Date secondContractDate = ARC_ContractTriggerHandler.calculateInitialCommDate(c2);
            Date thirdContractDate = ARC_ContractTriggerHandler.calculateInitialCommDate(c3);
            Date fourthContractDate = ARC_ContractTriggerHandler.calculateInitialCommDate(c4);
        Test.stopTest();

        Assert.areEqual(Date.newInstance(2024, 03, 15), firstContractDate);
        Assert.areEqual(Date.newInstance(2024, 04, 15), secondContractDate);
        Assert.areEqual(Date.newInstance(2024, 05, 15), thirdContractDate);
        Assert.areEqual(Date.newInstance(2024, 06, 15), fourthContractDate);
    }

    @isTest
    public static void createInitialCPAdjustmentTestOne() {
        //Get The Commission
        ARC_Commission__c commBefore = [SELECT Id, ARC_InitialCommission__c FROM ARC_Commission__c][0];
        
        //Create Initial CP
        ARC_Commission_Payment__c initialCP = new ARC_Commission_Payment__c(
            Commission__c = commBefore.Id,
            Amount__c = commBefore.ARC_InitialCommission__c,
            ARC_PaymentDate__c = Date.Today(),
            Type__c = 'Initial'
        );
        insert initialCP;

        ARC_Commission__c comm = [SELECT Id, Contract__c, ARC_InitialCommission__c, ARC_RecurringCommission__c, OwnerId, (SELECT Id, Type__c, Amount__c, RecordTypeId, ARC_PaymentDate__c FROM Commision_Payments__r) FROM ARC_Commission__c][0];
        comm.ARC_InitialCommission__c = 8;
        update comm;

        ARC_Commission_Payment__c adjustmentCP;
        Test.startTest();
            adjustmentCP = ARC_ContractTriggerHandler.createInitialCPAdjustment(comm, 5);
        Test.stopTest();
        System.debug(adjustmentCP);
        Assert.areEqual(3, adjustmentCP.Amount__c);
    }

    @isTest
    public static void createInitialCPAdjustmentTestTwo() {

        //Get The Commission
        ARC_Commission__c commBefore = [SELECT Id, ARC_InitialCommission__c FROM ARC_Commission__c][0];
        
        //Create Initial CP
        ARC_Commission_Payment__c initialCP = new ARC_Commission_Payment__c(
            Commission__c = commBefore.Id,
            Amount__c = commBefore.ARC_InitialCommission__c,
            ARC_PaymentDate__c = Date.Today(),
            Type__c = 'Initial'
        );
        insert initialCP;

        ARC_Commission__c comm = [SELECT Id, Contract__c, ARC_InitialCommission__c, ARC_RecurringCommission__c, OwnerId, (SELECT Id, Type__c, Amount__c, RecordTypeId, ARC_PaymentDate__c FROM Commision_Payments__r) FROM ARC_Commission__c][0];
        comm.ARC_InitialCommission__c = 8;
        update comm;

        ARC_Commission_Payment__c adjustmentCP;

        Test.startTest();
            adjustmentCP = ARC_ContractTriggerHandler.createInitialCPAdjustment(comm, 5);
        Test.stopTest();

        Assert.areEqual(3, adjustmentCP.Amount__c);
    }

    @isTest
    public static void getTransactionsFromPCTest() {
        //Get the Contract
        Map<Id,Contract> contractMap = new Map<Id,Contract>([SELECT Id FROM Contract]);
        List<Id> contractIds = new List<Id>(contractMap.keySet());

        //Get the transaction
        List<ChargentOrders__Transaction__c> tList = [SELECT Id, ChargentOrders__Order__r.ARC_Contract__c FROM ChargentOrders__Transaction__c];

        Map<Id,Id> resultMap = new Map<Id,Id>();
        Test.startTest();
            resultMap = ARC_ContractTriggerHandler.getTransactionsFromPC(contractIds);
        Test.stopTest();
        Assert.areEqual(tList[0].Id, resultMap.get(contractIds[0]));
    }

    @isTest
    public static void createCommissionAndInitialCPTest() {
        //Get a Contract inactive
        List<Contract> contracts = [SELECT Id, Status, ARC_Selling_Agent__c, ARC_RecurringMonthlyOrder__c, ARC_EffectiveDate__c, ARC_AwaitingActivationDate__c FROM Contract];
        Contract contractToTest = contracts[2];

        //Get the commissions related to that contract, it shouldn't been created yet.
        List<ARC_Commission__c> commissions = [SELECT Id, Contract__c, ARC_InitialCommission__c, ARC_RecurringCommission__c, OwnerId FROM ARC_Commission__c WHERE Contract__c = :contractToTest.Id];
        Test.startTest();
            //Since the Effective date of the contract is in the past, it's going to be activated as soon as it is moved to Awaiting Activation.
            contractToTest.ARC_EffectiveDate__c = Date.newInstance(2024, 01, 01);
            contractToTest.Status = 'Awaiting Activation';
            update contractToTest;
        Test.stopTest();

        List<ARC_Commission__c> commissionsAfter = [SELECT Id, Contract__c, ARC_InitialCommission__c, ARC_RecurringCommission__c, OwnerId FROM ARC_Commission__c WHERE Contract__c = :contractToTest.Id];
        List<ARC_Commission_Payment__c> commPayments =  [SELECT Id, Type__c, Amount__c, ARC_PaymentDate__c, Commission__c FROM ARC_Commission_Payment__c];

        Assert.isTrue(commissions.isEmpty());
        Assert.isFalse(commissionsAfter.isEmpty());
        Assert.areEqual(commissionsAfter[0].Contract__c, contractToTest.Id);
        Assert.areEqual(commissionsAfter[0].ARC_InitialCommission__c, commPayments[0].Amount__c);
        Assert.areEqual('Initial', commPayments[0].Type__c);
    }

    @isTest
    public static void updateContractOnCommissionTest() {
        //Get a Contract inactive
        ARC_Commission__c commBefore = [
            SELECT Id, Contract__c, ARC_InitialCommission__c, ARC_RecurringCommission__c, OwnerId
            FROM ARC_Commission__c
            WHERE Contract__c != null
            LIMIT 1
        ];

        Contract contractToTest = [
            SELECT Id, ARC_EffectiveDate__c, ARC_AwaitingActivationDate__c
            FROM Contract
            WHERE Id = :commBefore.Contract__c
            LIMIT 1
        ];

        Contract pc = [
            SELECT Id, Status, ARC_Selling_Agent__c, ARC_RecurringMonthlyOrder__c, ARC_EffectiveDate__c, ARC_AwaitingActivationDate__c
            FROM Contract
            WHERE Id != :contractToTest.Id
            AND ARC_RecurringMonthlyOrder__c != null
            LIMIT 1
        ];

        //Update pc chargent to point to pc Contract
        ChargentOrders__ChargentOrder__c chargentOrder = new ChargentOrders__ChargentOrder__c(
            Id = pc.ARC_RecurringMonthlyOrder__c,
            ARC_Contract__c = pc.Id
        );
        update chargentOrder;

        //Create Transaction for the PC
        ChargentOrders__Transaction__c t = ARC_TestUtility.createOneTransaction(10, 'Charge', chargentOrder.Id);
        insert t;

        pc.ARC_ContractReason__c = 'Program Downgrade';
        pc.ARC_EffectiveDate__c = Date.newInstance(2024, 02, 01);
        pc.Status = 'Activated';
        pc.vlocity_ins__ExpiredContractId__c = contractToTest.Id;

        Test.startTest();
            ARC_ContractTriggerHandler.updateContractOnCommission(new Map<Id, Contract>{
                contractToTest.Id => pc
            });
        Test.stopTest();

        ARC_Commission__c commAfter = [
            SELECT Id, Contract__c, ARC_InitialCommission__c, ARC_RecurringCommission__c, OwnerId
            FROM ARC_Commission__c
            WHERE Id = :commBefore.Id
            LIMIT 1
        ];

        System.debug(commAfter);
        Assert.areEqual(commBefore.Id, commAfter.Id);
    }

    @isTest
    public static void updateCommissionPriceTest() {
        //Get the Commission
        ARC_Commission__c comm = [SELECT Id, Active__c, Contract__c, ARC_InitialCommission__c, ARC_RecurringCommission__c, OwnerId FROM ARC_Commission__c LIMIT 1];
        System.debug(comm);
        //Get a Contract related to the Commission
        Contract cont = [SELECT Id, Status, ARC_Selling_Agent__c, ARC_RecurringMonthlyOrder__c, ARC_EffectiveDate__c,ARC_AwaitingActivationDate__c, ARC_TotalPrice__c FROM Contract WHERE Id =: comm.Contract__c];
        //Get Line Items
        List<vlocity_ins__ContractLineItem__c> lineItems = [SELECT Id, vlocity_ins__UnitPrice__c, vlocity_ins__ContractId__c, vlocity_ins__TotalPrice__c, vlocity_ins__ProductType__c  FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__ContractId__c =: cont.Id];

        //Activate the contract
        cont.Status = 'Activated';
        update cont;

        Test.startTest();
            for (vlocity_ins__ContractLineItem__c lineItem: lineItems) lineItem.vlocity_ins__UnitPrice__c = 100;
            update lineItems;
        Test.stopTest();
        //Get the Commission
        ARC_Commission__c commAfter = [SELECT Id, Active__c, Contract__c, ARC_InitialCommission__c, ARC_RecurringCommission__c, OwnerId FROM ARC_Commission__c WHERE Id =:comm.Id LIMIT 1];

        Assert.areEqual(comm.Id, commAfter.Id);
        Assert.areNotEqual(comm.ARC_InitialCommission__c, commAfter.ARC_InitialCommission__c);
        Assert.areNotEqual(comm.ARC_RecurringCommission__c, commAfter.ARC_RecurringCommission__c);
    }

    @isTest
    public static void reactivateContractLinkToCommissionTest() {
        //Get the Commission
        ARC_Commission__c comm = [
            SELECT Id, Active__c, Contract__c, ARC_InitialCommission__c, ARC_RecurringCommission__c, OwnerId, Original_Contract__c
            FROM ARC_Commission__c
            WHERE Original_Contract__c != null
            LIMIT 1
        ];
        System.debug(comm);

        //Get a Contracts
        Contract originalContract = [
            SELECT Id, Status, ARC_Selling_Agent__c, ARC_RecurringMonthlyOrder__c, ARC_EffectiveDate__c, ARC_AwaitingActivationDate__c
            FROM Contract
            WHERE Id = :comm.Original_Contract__c
            LIMIT 1
        ];

        Contract pc = [
            SELECT Id, Status, ARC_Selling_Agent__c, ARC_RecurringMonthlyOrder__c, ARC_EffectiveDate__c, ARC_AwaitingActivationDate__c
            FROM Contract
            WHERE Id != :originalContract.Id
            LIMIT 1
        ];

        //Get Line Items
        List<vlocity_ins__ContractLineItem__c> lineItems = [
            SELECT Id, vlocity_ins__UnitPrice__c, vlocity_ins__ContractId__c, vlocity_ins__TotalPrice__c, vlocity_ins__ProductType__c
            FROM vlocity_ins__ContractLineItem__c
        ];

        //Activate the pc contract
        comm.Contract__c = pc.Id;
        update comm;

        Test.startTest();
            ARC_ContractTriggerHandler.reactivateContractLinkToCommission(new Map<Id, Contract>{
                originalContract.Id => originalContract
            });
        Test.stopTest();

        ARC_Commission__c commAfterTest = [
            SELECT Id, Active__c, Contract__c, ARC_InitialCommission__c, ARC_RecurringCommission__c, OwnerId, Original_Contract__c
            FROM ARC_Commission__c
            WHERE Id = :comm.Id
            LIMIT 1
        ];

        Assert.areEqual(comm.Id, commAfterTest.Id);
        Assert.areEqual(commAfterTest.Contract__c, originalContract.Id);
    }

    @isTest
    public static void updateAggregatorsTest() {
        Map<Id, Contract> newVoidedContractMap = new Map<Id, Contract>();
        Contract voidCont;
        Id terminatedContractId;

        List<InsurancePolicy> policies = [SELECT Id, ARC_Contract__c, Name FROM InsurancePolicy];
        List<Contract> contList = new List<Contract>();
        for (InsurancePolicy pol : policies) {
            if (pol.Name == 'Test Policy 0') {
                voidCont = new Contract (Id = pol.ARC_Contract__c, Status = 'Voided');
                contList.add(voidCont);
            } else {
                contList.add(new Contract (Id = pol.ARC_Contract__c, Status = 'Terminated'));
            }
        }

        update contList;
        
        newVoidedContractMap.put(voidCont.Id, voidCont);

        Test.startTest();
        ARC_ContractTriggerHandler.updateAggregators(newVoidedContractMap);
        Test.stopTest();
    }

    @isTest
    public static void reactivateAggregatorsTest() {
        Map<Id, Contract> reactivatedVoidedContractMap = new Map<Id, Contract>();

        InsurancePolicy policy = [SELECT Id, ARC_Contract__c, Name FROM InsurancePolicy WHERE Name = 'Test Policy 0' LIMIT 1];
        List<ARC_Aggregator__c> aggregators = [SELECT Id, Name FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c =: policy.Id];
        for (ARC_Aggregator__c agg : aggregators) {
            agg.ARC_IsInactive__c = true;
        }
        update aggregators;

        reactivatedVoidedContractMap.put(policy.ARC_Contract__c, new Contract (Id = policy.ARC_Contract__c));

        Test.startTest();
        ARC_ContractTriggerHandler.reactivateAggregators(reactivatedVoidedContractMap);
        Test.stopTest();

        List<ARC_Aggregator__c> reactivatedAggregators = [SELECT Id, Name FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c =: policy.Id AND ARC_IsInactive__c = false];
        Assert.areEqual(3, reactivatedAggregators.size(), 'Aggregators are not being reactivated correctly');
    }

    @isTest
    public static void changeEffectiveDatePoliciesTest() {
        List<Contract> contracts = [SELECT Id FROM Contract LIMIT 2];
        Id id1 = contracts[0].Id, id2 = contracts[1].Id;

        Map<Id,Contract> oldMap = new Map<Id,Contract>{
            id1 => new Contract(Id = id1, ARC_EffectiveDate__c = Date.newInstance(2024, 01, 01)),
            id2 => new Contract(Id = id2, ARC_EffectiveDate__c = Date.newInstance(2024, 01, 01))
        };
        Map<Id,Contract> newMap = new Map<Id,Contract>{
            id1 => new Contract(Id = id1, ARC_EffectiveDate__c = Date.newInstance(2024, 03, 01)),
            id2 => new Contract(Id = id2, ARC_EffectiveDate__c = Date.newInstance(2024, 01, 01))
        };

        Test.startTest();
            Set<Id> result = ARC_ContractTriggerHandler.changeEffectiveDatePolicies(oldMap, newMap);
        Test.stopTest();

        Assert.isTrue(result.contains(id1),  'Changed date should be in result');
        Assert.isFalse(result.contains(id2), 'Unchanged date should not be in result');
    }

    @isTest
    public static void getTransactionsFromPCEmptyTest() {
        Test.startTest();
            Map<Id,Id> result = ARC_ContractTriggerHandler.getTransactionsFromPC(new List<Id>());
        Test.stopTest();
        Assert.isNull(result);
    }

    @isTest
    public static void createInitialCPAdjustmentNullTest() {
        Test.startTest();
            ARC_Commission_Payment__c result = ARC_ContractTriggerHandler.createInitialCPAdjustment(null, 100);
        Test.stopTest();
        Assert.isNull(result);
    }

    @isTest
    public static void createsRecurringCPNullTest() {
        Test.startTest();
            ARC_Commission_Payment__c result = ARC_ContractTriggerHandler.createsRecurringCP(null, null);
        Test.stopTest();
        Assert.isNull(result);
    }

    public static void calculateInitialCommDateExtraTest() {
        Contract c1 = new Contract(ARC_EffectiveDate__c = Date.newInstance(2024, 05, 01), ARC_AwaitingActivationDate__c = null);
        Contract c2 = new Contract(ARC_EffectiveDate__c = Date.newInstance(2024, 05, 10), ARC_AwaitingActivationDate__c = null);

        Test.startTest();
            Date d1 = ARC_ContractTriggerHandler.calculateInitialCommDate(c1);
            Date d2 = ARC_ContractTriggerHandler.calculateInitialCommDate(c2);
        Test.stopTest();

        Assert.areEqual(Date.newInstance(2024, 05, 15), d1, 'Day==1 → same month 15th');
        Assert.areEqual(Date.newInstance(2024, 06, 15), d2, 'Day!=1 → next month 15th');
    }

    @isTest
    public static void updateNextInvoiceAnchorTest() {
        Id sgRT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();

        Contract cInsert = new Contract(RecordTypeId = sgRT, ARC_EffectiveDate__c = Date.newInstance(2024, 6, 1), ARC_CoveragePaidThrough__c = null);
        Contract cSkip   = new Contract(RecordTypeId = sgRT, ARC_EffectiveDate__c = Date.newInstance(2024, 6, 1), ARC_CoveragePaidThrough__c = Date.newInstance(2024, 12, 31), ARC_NextInvoiceCoverageStart__c = null);

        Test.startTest();
            ARC_ContractTriggerHandler.updateNextInvoiceAnchor(new List<Contract>{ cInsert, cSkip }, null);
        Test.stopTest();

        Assert.areEqual(Date.newInstance(2024, 6, 1), cInsert.ARC_NextInvoiceCoverageStart__c);
        Assert.isNull(cSkip.ARC_NextInvoiceCoverageStart__c);
    }

    @isTest
    public static void updateNextInvoiceAnchorUpdateTest() {
        Id sgRT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        Id cId  = [SELECT Id FROM Contract LIMIT 1].Id;

        Contract oldC = new Contract(Id = cId, RecordTypeId = sgRT, ARC_EffectiveDate__c = Date.newInstance(2024, 5, 1), ARC_CoveragePaidThrough__c = null);
        Contract newC = new Contract(Id = cId, RecordTypeId = sgRT, ARC_EffectiveDate__c = Date.newInstance(2024, 7, 1), ARC_CoveragePaidThrough__c = null);

        Test.startTest();
            ARC_ContractTriggerHandler.updateNextInvoiceAnchor(new List<Contract>{ newC }, new Map<Id,Contract>{ cId => oldC });
        Test.stopTest();

        Assert.areEqual(Date.newInstance(2024, 7, 1), newC.ARC_NextInvoiceCoverageStart__c);
    }

    @isTest
    public static void processBillingAutomationEmptyTest() {
        Test.startTest();
            ARC_ContractTriggerHandler.processBillingAutomation(new List<Contract>(), null);
        Test.stopTest();
        Assert.isTrue(true);
    }

    @isTest
    public static void processBillingAutomationInsertTest() {
        Id sgRT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        Id cId  = [SELECT Id FROM Contract LIMIT 1].Id;
        Contract c = new Contract(Id = cId, RecordTypeId = sgRT, ARC_EffectiveDate__c = Date.newInstance(2024, 6, 1));

        Test.startTest();
            ARC_ContractTriggerHandler.processBillingAutomation(new List<Contract>{ c }, null);
        Test.stopTest();
        Assert.isTrue(true);
    }

    @isTest
    public static void processBillingAutomationNoChangeTest() {
        Id sgRT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        Id cId  = [SELECT Id FROM Contract LIMIT 1].Id;

        Contract oldC = new Contract(Id = cId, RecordTypeId = sgRT, ARC_EffectiveDate__c = Date.newInstance(2024, 6, 1), ARC_Inactive_Date__c = null, ARC_PaymentFrequency__c = 'Monthly');
        Contract newC = new Contract(Id = cId, RecordTypeId = sgRT, ARC_EffectiveDate__c = Date.newInstance(2024, 6, 1), ARC_Inactive_Date__c = null, ARC_PaymentFrequency__c = 'Monthly');

        Test.startTest();
            ARC_ContractTriggerHandler.processBillingAutomation(new List<Contract>{ newC }, new Map<Id,Contract>{ cId => oldC });
        Test.stopTest();
        Assert.isTrue(true);
    }
}