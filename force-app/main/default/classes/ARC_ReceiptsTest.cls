@isTest
public with sharing class ARC_ReceiptsTest {
    @TestSetup
    public static void makeData(){
        /* CONTRACT */
        Contract c = ARC_TestUtility.createContracts(1)[0];
        insert c;
        /* CENSUS */
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(
            vlocity_ins__GroupId__c = c.AccountId
        );
        insert census;
        /* CONTRACT UPDATE WITH CENSUS */
        c.vlocity_ins__EnrollmentCensusId__c = census.Id;
        update c;
        List<Contract> contracts = [SELECT Id,ContractNumber FROM Contract LIMIT 1];
        /* PERSON ACCOUNT */
        String RecTypeId= [SELECT Id FROM RecordType WHERE (Name='Person Account') AND (SobjectType='Account')].Id;
        Account personAccount = new Account(
            RecordTypeID=RecTypeId,
            FirstName='Test FName',
            LastName='Test LName',
            PersonEmail='test@test.com'
        );
        insert personAccount;

        Account pa = [SELECT PersonContactId FROM Account WHERE Id =: personAccount.Id];
        System.debug(pa);
        /* CENSUS MEMBER */
        vlocity_ins__GroupCensusMember__c cm = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__CensusId__c = census.Id,
            vlocity_ins__ContactId__c = pa.PersonContactId
        );
        insert cm;
        /* CHARGENT ORDER */
        List<ChargentOrders__ChargentOrder__c> chargentOrders = new List<ChargentOrders__ChargentOrder__c>();
        ChargentOrders__ChargentOrder__c chargentOrder1 = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c=c.Id,
            ChargentOrders__Description__c='Recurring Monthly Order',
            ChargentOrders__Charge_Amount__c = 2000
        );
        ChargentOrders__ChargentOrder__c chargentOrder2 = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c=c.Id,
            ChargentOrders__Description__c='App Fee',
            ChargentOrders__Charge_Amount__c = 2000

        );
        chargentOrders.add(chargentOrder1);
        chargentOrders.add(chargentOrder2);
        insert chargentOrders;
        /* TRANSACTIONS */
        List<ChargentOrders__Transaction__c> transactions = new List<ChargentOrders__Transaction__c>();
        ChargentOrders__Transaction__c tr1 = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c=chargentOrders[0].Id,
            ChargentOrders__Response_Status__c='Approved',
            ARC_Reason__c = 'Recurring Monthly Order',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Amount__c=1500
        );

        ChargentOrders__Transaction__c tr2 = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c=chargentOrders[0].Id,
            ChargentOrders__Response_Status__c='Approved',
            ARC_Reason__c = 'Recurring Monthly Order',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Amount__c=1500
        );

        ChargentOrders__Transaction__c tr3 = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c=chargentOrders[1].Id,
            ChargentOrders__Response_Status__c='Approved',
            ARC_Reason__c = 'App Fee',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Amount__c=1500
        );
        transactions.add(tr1);
        transactions.add(tr2);
        transactions.add(tr3);
        insert transactions;

        Product2 testProduct = new Product2(
            Name='Test Product'
        );
        insert testProduct;

        List<ARC_TransactionLineItem__c> tlis = new List<ARC_TransactionLineItem__c>();
        ARC_TransactionLineItem__c core = new ARC_TransactionLineItem__c(
            ARC_Type__c = 'Medical',
            Name = 'WeShare 6k',
            ARC_Transaction__c=tr1.Id,
            ARC_Product__c=testProduct.Id,
            ARC_Amount__c=1
        );
        ARC_TransactionLineItem__c healthyDiscount = new ARC_TransactionLineItem__c(
            ARC_Type__c = 'Medical',
            Name = 'Healthy Discount',
            ARC_Transaction__c=tr1.Id,
            ARC_Product__c=testProduct.Id,
            ARC_Amount__c=1
        );
        ARC_TransactionLineItem__c smart = new ARC_TransactionLineItem__c(
            ARC_Transaction__c=tr1.Id,
            ARC_Product__c=testProduct.Id,
            ARC_Amount__c=1
        );
        ARC_TransactionLineItem__c aidd = new ARC_TransactionLineItem__c(
            ARC_Transaction__c=tr1.Id,
            ARC_Product__c=testProduct.Id,
            ARC_Amount__c=1
        );

        ARC_TransactionLineItem__c core2 = new ARC_TransactionLineItem__c(
            ARC_Type__c = 'Medical',
            Name = 'WeShare 6k',
            ARC_Transaction__c=tr2.Id,
            ARC_Product__c=testProduct.Id,
            ARC_Amount__c=1
        );

        ARC_TransactionLineItem__c appFeeItem = new ARC_TransactionLineItem__c(
            Name = 'App Fee',
            ARC_Transaction__c=tr3.Id,
            ARC_Product__c=testProduct.Id,
            ARC_Amount__c=1
        );

        tlis.add(core);
        tlis.add(core2);
        tlis.add(healthyDiscount);
        tlis.add(smart);
        tlis.add(aidd);
        tlis.add(appFeeItem);
        insert tlis;
    }

    @IsTest
    static void getTransactionsForDocumentPATest(){
        String RecTypeId = [SELECT Id FROM RecordType WHERE (Name='Person Account') AND (SobjectType='Account')].Id;
        Account personAccount = [SELECT Id FROM Account WHERE RecordTypeId = :RecTypeId LIMIT 1];
        List<Map<String,Object>> contractsList = new List<Map<String,Object>>();
        List<Contract> contracts = [SELECT Id,ContractNumber FROM Contract LIMIT 1];
        for (Contract c : contracts) {
            Map<String, Object> contractMap = new Map<String, Object>{'Number' => c.ContractNumber,'CHECK_ContractSelected' => true};
            contractsList.add(contractMap);
        }

        ChargentOrders__Transaction__c tr = [SELECT Id,ChargentOrders__Order__r.ARC_Contract__r.ContractNumber FROM ChargentOrders__Transaction__c LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>{
            'chargeType'=> 'Charge;Refund;Decline',
            'transactionType' => 'Recurring;Fees',
            'contextId'=> personAccount.Id,
            'Contracts' => contractsList
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Test.startTest();
        ARC_Receipts classInstance = new ARC_Receipts();
        classInstance.invokeMethod('getDocumentInformation',inputMap,outputMap,options);
        Test.stopTest();
    }

    @IsTest
    static void getTransactionsForDocumentCMTest(){
        String RecTypeId = [SELECT Id FROM RecordType WHERE (Name='Person Account') AND (SobjectType='Account')].Id;
        vlocity_ins__GroupCensusMember__c cm = [SELECT Id FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        List<Map<String,Object>> contractsList = new List<Map<String,Object>>();
        List<Contract> contracts = [SELECT Id,ContractNumber FROM Contract LIMIT 1];
        for (Contract c : contracts) {
            Map<String, Object> contractMap = new Map<String, Object>{'Number' => c.ContractNumber,'CHECK_ContractSelected' => true};
            contractsList.add(contractMap);
        }

        ChargentOrders__Transaction__c tr = [SELECT Id,ChargentOrders__Order__r.ARC_Contract__r.ContractNumber FROM ChargentOrders__Transaction__c LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>{
            'chargeType'=> 'Charge;Refund;Decline',
            'transactionType' => 'Recurring;Fees',
            'contextId'=> cm.Id,
            'Contracts' => contractsList
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Test.startTest();
        ARC_Receipts classInstance = new ARC_Receipts();
        classInstance.invokeMethod('getDocumentInformation',inputMap,outputMap,options);
        Test.stopTest();
    }

}