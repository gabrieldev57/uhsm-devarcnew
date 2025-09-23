@isTest
public class ARC_ContractTriggerHandlerTest {

    @TestSetup
    static void makeData(){
        List<User> userList = [SELECT Id, Agent_Role__c FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 2];
        if(userList.size()==2){
            userList[0].Agent_Role__c = 'Account Executive';
            userList[1].Agent_Role__c = 'Senior Account Executive';
        }
        update userList;

        //Create Contracts in Draft
        Contract[] contList = ARC_TestUtility.createContractsAA(3);
        for(Integer i = 0; i< contList.size(); i++){
            if(i != 2) contList[i].ARC_Selling_Agent__c=userList[0].Id;
            else contList[i].ARC_Selling_Agent__c=userList[1].Id;
            contList[i].Status = 'Draft';
            contList[i].ARC_ContractReason__c = 'New Application';
            contList[i].ARC_EffectiveDate__c = Date.newInstance(2024,01,01);
        }
        insert contList;

        System.debug('chargentId '+contList[0].ARC_RecurringMonthlyOrder__c);

        //Update One chargent to point to One Contract
        ChargentOrders__ChargentOrder__c chargentOrder = new ChargentOrders__ChargentOrder__c(Id = contList[0].ARC_RecurringMonthlyOrder__c, ARC_Contract__c=contList[0].Id);
        update chargentOrder;

        //Create Initial Transaction for the first Contract
        ChargentOrders__Transaction__c t = ARC_TestUtility.createOneTransaction(10,'Charge',chargentOrder.Id);
        insert t;

        //Create Commission for One Contract
        ARC_Commission__c comm = new ARC_Commission__c(ownerId =contList[0].ARC_Selling_Agent__c, ARC_InitialCommission__c = 20,ARC_RecurringCommission__c=5, Contract__c= contList[0].Id, Original_Contract__c = contList[0].Id);
        insert comm;
        

        ///Products
        List<Product2> products = new List<Product2>();
        Product2 medicalProd = new Product2();
        medicalProd.Name = 'WeShare 6k ';
        medicalProd.ProductCode = 'PROG_UHSM_WeShare6k';
        medicalProd.vlocity_ins__Type__c = 'Medical';

        Product2 smartProd = new Product2();
        smartProd.Name = 'SMART Share 35000';
        smartProd.ProductCode = 'PROG_SMART_35000';
        smartProd.vlocity_ins__Type__c = 'Ancillary';
        smartProd.vlocity_ins__SubType__c='SMART';

        Product2 aiddProd = new Product2();
        aiddProd.Name = 'AIDD 7500';
        aiddProd.ProductCode = 'PROG_AIDD_7500';
        aiddProd.vlocity_ins__Type__c = 'Ancillary';
        aiddProd.vlocity_ins__SubType__c='AIDD';
        
        products.add(medicalProd);
        products.add(smartProd);
        products.add(aiddProd);
        insert products;

        //Create Contract Line Items
        List<vlocity_ins__ContractLineItem__c> lineItems = new List<vlocity_ins__ContractLineItem__c>();
        for(Contract c: contList){
            for(Integer i=0; i<3;i++){
                vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
                cli.vlocity_ins__Product2Id__c=  products[i].Id;
                cli.Name = products[i].Name;
                if(products[i].vlocity_ins__Type__c == 'Medical') cli.vlocity_ins__UnitPrice__c=  200;
                else if(products[i].Name == 'SMART Share 35000') cli.vlocity_ins__UnitPrice__c=  100;
                else cli.vlocity_ins__UnitPrice__c =  50;
                cli.vlocity_ins__ContractId__c = c.Id;
                cli.vlocity_ins__Quantity__c = 1;
                lineItems.add(cli);
            }
        }
        insert lineItems;
        System.debug(lineItems);
    }

    @isTest
    public static void getProgramPricesTest(){
        //Get program prices
        Map<Id,Double> contractMedicalTotal = new Map<Id,Double>();
        Map<Id,Double> contractAncillaryTotal = new Map<Id,Double>();
        Map<Id,Contract> contractMap = new Map<Id,Contract>([SELECT Id FROM Contract]);
        List<Id> contractIds = new List<Id>(contractMap.keySet());
        //Get Line Items
        List<vlocity_ins__ContractLineItem__c> lineItems = [SELECT Id,vlocity_ins__UnitPrice__c, vlocity_ins__ContractId__c, vlocity_ins__TotalPrice__c, vlocity_ins__ProductType__c  FROM vlocity_ins__ContractLineItem__c];
        System.debug(lineItems);
        Test.startTest();
            ARC_ContractTriggerHandler.getProgramPrices(contractMedicalTotal,contractAncillaryTotal,contractIds);
        Test.stopTest();
        Assert.areEqual(200,contractMedicalTotal.get(contractIds[0]));
        Assert.areEqual(150,contractAncillaryTotal.get(contractIds[0]));
    }

    @isTest
    public static void createInitialAndReccurringCPTest(){
        //Get Initial Transaction
        List<ChargentOrders__Transaction__c> tList = [SELECT Id, ChargentOrders__Order__r.ARC_Contract__c FROM ChargentOrders__Transaction__c];

        //Get Contract
        Map<Id,Contract> contractMap = new Map<Id,Contract>([SELECT Id,ARC_Selling_Agent__c, ARC_RecurringMonthlyOrder__c, ARC_EffectiveDate__c,ARC_AwaitingActivationDate__c FROM Contract WHERE Id = :tList[0].ChargentOrders__Order__r.ARC_Contract__c]);
        List<Id> contractIds = new List<Id>(contractMap.keySet());
        
        //Get The Commission
        List<ARC_Commission__c> commissions = [SELECT Id,Contract__c,ARC_InitialCommission__c,ARC_RecurringCommission__c,OwnerId  FROM ARC_Commission__c];

        ARC_Commission_Payment__c recurringCP;

        Test.startTest();
            ARC_ContractTriggerHandler.createInitialCP(commissions, contractMap);
            recurringCP =ARC_ContractTriggerHandler.createsRecurringCP(commissions[0], tList[0].Id);
        Test.stopTest();

        ARC_Commission_Payment__c initialCP = [SELECT Id, Type__c,Amount__c  FROM ARC_Commission_Payment__c][0];
        Assert.areEqual(commissions[0].ARC_InitialCommission__c,initialCP.Amount__c);
        Assert.areEqual(commissions[0].ARC_RecurringCommission__c,recurringCP.Amount__c);
    }

    @isTest
    public static void calculateInitialCommDate(){
        List<Contract> contracts = [SELECT Id, ARC_EffectiveDate__c, ARC_AwaitingActivationDate__c FROM Contract];
        //Test When Effective Date < Awaiting Activation Date
        contracts[0].ARC_EffectiveDate__c = Date.newInstance(2024,01,01);
        contracts[0].ARC_AwaitingActivationDate__c = Date.newInstance(2024,03,01);
        //Test When Effective Date > Awaiting Activation Date
        contracts[1].ARC_EffectiveDate__c = Date.newInstance(2024,03,15);
        contracts[1].ARC_AwaitingActivationDate__c = Date.newInstance(2024,01,01);
        update contracts;

        Test.startTest();
            Date firstContractDate = ARC_ContractTriggerHandler.calculateInitialCommDate(contracts[0]);
            Date secondContractDate = ARC_ContractTriggerHandler.calculateInitialCommDate(contracts[1]);
        Test.stopTest();

        Assert.areEqual(Date.newInstance(2024,03,15),firstContractDate);
        Assert.areEqual(Date.newInstance(2024,04,15),secondContractDate);
    }

    @isTest
    public static void createInitialCPAdjustmentTestOne(){
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

        ARC_Commission__c comm = [SELECT Id,Contract__c,ARC_InitialCommission__c,ARC_RecurringCommission__c,OwnerId, (SELECT Id, Type__c, Amount__c, RecordTypeId, ARC_PaymentDate__c FROM Commision_Payments__r) FROM ARC_Commission__c][0];
        comm.ARC_InitialCommission__c = 8;
        update comm;

        ARC_Commission_Payment__c adjustmentCP;
        Test.startTest();
            adjustmentCP = ARC_ContractTriggerHandler.createInitialCPAdjustment(comm, 5);
        Test.stopTest();
        System.debug(adjustmentCP);
        Assert.areEqual(3,adjustmentCP.Amount__c);
    }

    @isTest
    public static void createInitialCPAdjustmentTestTwo(){

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

        ARC_Commission__c comm = [SELECT Id,Contract__c,ARC_InitialCommission__c,ARC_RecurringCommission__c,OwnerId, (SELECT Id, Type__c, Amount__c, RecordTypeId, ARC_PaymentDate__c FROM Commision_Payments__r) FROM ARC_Commission__c][0];
        comm.ARC_InitialCommission__c = 8;
        update comm;

        ARC_Commission_Payment__c adjustmentCP;

        Test.startTest();
            adjustmentCP = ARC_ContractTriggerHandler.createInitialCPAdjustment(comm, 5);
        Test.stopTest();

        Assert.areEqual(3,adjustmentCP.Amount__c);
    }

    @isTest
    public static void getTransactionsFromPCTest(){
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
    public static void createCommissionAndInitialCPTest(){
        //Get a Contract inactive
        List<Contract> contracts = [SELECT Id,Status, ARC_Selling_Agent__c, ARC_RecurringMonthlyOrder__c, ARC_EffectiveDate__c,ARC_AwaitingActivationDate__c FROM Contract];
        Contract contractToTest = contracts[2];

        //Get the commissions related to that contract, it shouldn't been created yet.
        List<ARC_Commission__c> commissions = [SELECT Id,Contract__c,ARC_InitialCommission__c,ARC_RecurringCommission__c,OwnerId  FROM ARC_Commission__c WHERE Contract__c = :contractToTest.Id];
        Test.startTest();
            //Since the Effective date of the contract is in the past, it's going to be activated as soon as it is moved to Awaiting Activation.
            contractToTest.ARC_EffectiveDate__c = Date.newInstance(2024,01,01);
            contractToTest.Status = 'Awaiting Activation';
            update contractToTest;
        Test.stopTest();

        List<ARC_Commission__c> commissionsAfter = [SELECT Id,Contract__c,ARC_InitialCommission__c,ARC_RecurringCommission__c,OwnerId  FROM ARC_Commission__c WHERE Contract__c = :contractToTest.Id];
        List<ARC_Commission_Payment__c> commPayments =  [SELECT Id, Type__c,Amount__c, ARC_PaymentDate__c,Commission__c  FROM ARC_Commission_Payment__c];

        Assert.isTrue(commissions.isEmpty());
        Assert.isFalse(commissionsAfter.isEmpty());
        Assert.areEqual(commissionsAfter[0].Contract__c, contractToTest.Id);
        Assert.areEqual(commissionsAfter[0].ARC_InitialCommission__c, commPayments[0].Amount__c);
        Assert.areEqual('Initial', commPayments[0].Type__c);
    }

    @isTest
    public static void updateContractOnCommissionTest(){
        //Get a Contract inactive
        List<Contract> contracts = [SELECT Id,Status, ARC_Selling_Agent__c, ARC_RecurringMonthlyOrder__c, ARC_EffectiveDate__c,ARC_AwaitingActivationDate__c FROM Contract];
        Contract contractToTest = contracts[1];

        contractToTest.ARC_EffectiveDate__c = Date.newInstance(2024,01,01);
        contractToTest.Status = 'Awaiting Activation';
        update contractToTest;

        ARC_Commission__c commBefore = [SELECT Id,Contract__c,ARC_InitialCommission__c,ARC_RecurringCommission__c,OwnerId  FROM ARC_Commission__c WHERE Contract__c = :contractToTest.Id][0];
        System.debug(commBefore);
        Contract pc = contracts[2];
        //Update pc chargent to point to pc Contract
        ChargentOrders__ChargentOrder__c chargentOrder = new ChargentOrders__ChargentOrder__c(Id = pc.ARC_RecurringMonthlyOrder__c, ARC_Contract__c=pc.Id);
        update chargentOrder;

        //Create Transaction for the PC
        ChargentOrders__Transaction__c t = ARC_TestUtility.createOneTransaction(10,'Charge',chargentOrder.Id);
        insert t;

        Test.startTest();
            pc.ARC_ContractReason__c = 'Program Downgrade';
            pc.ARC_EffectiveDate__c = Date.newInstance(2024,02,01);
            pc.Status = 'Activated';
            pc.vlocity_ins__ExpiredContractId__c = contractToTest.Id;
            update pc;
        Test.stopTest();

        List<ARC_Commission__c> commAfter = [SELECT Id,Contract__c,ARC_InitialCommission__c,ARC_RecurringCommission__c,OwnerId  FROM ARC_Commission__c WHERE Contract__c = :pc.Id];
        System.debug(commAfter);
        Assert.areEqual(commAfter.size()>0,true);
    }

    @isTest
    public static void updateCommissionPriceTest(){
        //Get the Commission
        ARC_Commission__c comm = [SELECT Id,Active__c,Contract__c,ARC_InitialCommission__c,ARC_RecurringCommission__c,OwnerId  FROM ARC_Commission__c LIMIT 1];
        System.debug(comm);
        //Get a Contract related to the Commission
        Contract cont = [SELECT Id,Status, ARC_Selling_Agent__c, ARC_RecurringMonthlyOrder__c, ARC_EffectiveDate__c,ARC_AwaitingActivationDate__c, ARC_TotalPrice__c FROM Contract WHERE Id =: comm.Contract__c];
        //Get Line Items
        List<vlocity_ins__ContractLineItem__c> lineItems = [SELECT Id,vlocity_ins__UnitPrice__c, vlocity_ins__ContractId__c, vlocity_ins__TotalPrice__c, vlocity_ins__ProductType__c  FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__ContractId__c =: cont.Id];

        //Activate the contract
        cont.Status = 'Activated';
        update cont;

        Test.startTest();
            for(vlocity_ins__ContractLineItem__c lineItem: lineItems) lineItem.vlocity_ins__UnitPrice__c = 100;
            update lineItems;
        Test.stopTest();
        //Get the Commission
        ARC_Commission__c commAfter = [SELECT Id,Active__c,Contract__c,ARC_InitialCommission__c,ARC_RecurringCommission__c,OwnerId  FROM ARC_Commission__c WHERE Id =:comm.Id LIMIT 1];

        Assert.areEqual(comm.Id, commAfter.Id);
        Assert.areNotEqual(comm.ARC_InitialCommission__c, commAfter.ARC_InitialCommission__c);
        Assert.areNotEqual(comm.ARC_RecurringCommission__c, commAfter.ARC_RecurringCommission__c);
    }

    @isTest
    public static void reactivateContractLinkToCommissionTest(){
        //Get the Commission
        ARC_Commission__c comm = [SELECT Id,Active__c,Contract__c,ARC_InitialCommission__c,ARC_RecurringCommission__c,OwnerId, Original_Contract__c  FROM ARC_Commission__c LIMIT 1];
        System.debug(comm);
        //Get a Contracts
        List<Contract> contracts = [SELECT Id,Status, ARC_Selling_Agent__c, ARC_RecurringMonthlyOrder__c, ARC_EffectiveDate__c,ARC_AwaitingActivationDate__c FROM Contract];
        //Get Line Items
        List<vlocity_ins__ContractLineItem__c> lineItems = [SELECT Id,vlocity_ins__UnitPrice__c, vlocity_ins__ContractId__c, vlocity_ins__TotalPrice__c, vlocity_ins__ProductType__c  FROM vlocity_ins__ContractLineItem__c];

        List<Contract> contractsToUpdate = new List<Contract>();
        Contract originalContract;
        Contract pc;
        Boolean pcFound  = false;
        for(Contract c:contracts){
            if(c.Id != comm.Contract__c && !pcFound){
                pc = c;
                pc.vlocity_ins__ExpiredContractId__c = comm.Contract__c;
                pc.ARC_EffectiveDate__c = Date.newInstance(2024,02,01);
                pc.status = 'Activated';
                pcFound = true;
                contractsToUpdate.add(pc);
            }
            else if(c.Id == comm.Contract__c) {
                originalContract = c;
                originalContract.status  = 'Terminated';
                originalContract.ARC_Inactive_Date__c  = Date.today().addDays(-1);
                contractsToUpdate.add(originalContract);
            }
        }

        Test.startTest();
            //Activate the pc contract
            update contractsToUpdate;
            //Update the Commission Contract to point to the PC Contract. 
            comm.Contract__c = pc.Id;
            update comm;

            ARC_ContractTriggerHandler.reactivateContractLinkToCommission(new Map<Id,Contract>{originalContract.id => originalContract});
        Test.stopTest();

        ARC_Commission__c commAfterTest = [SELECT Id,Active__c,Contract__c,ARC_InitialCommission__c,ARC_RecurringCommission__c,OwnerId, Original_Contract__c  FROM ARC_Commission__c LIMIT 1];
        Assert.areEqual(comm.Id,commAfterTest.Id);
        Assert.areEqual(commAfterTest.Contract__c,originalContract.Id);

    }
}