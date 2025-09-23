@isTest
public with sharing class ARC_TransactionLineItemsBatchTest {
    
    @isTest 
    public static void ARC_TransactionLineItemsBatchStandardCasesTest() {
       //Create Records
        List<Product2> products = ARC_TestUtility.createTestProducts(1);
        products[0].vlocity_ins__Type__c = 'Medical';
        update products;

        List<vlocity_ins__ContractLineItem__c> clis =ARC_TestUtility.createTestContractLineItem(2);
        clis[0].vlocity_ins__UnitPrice__c = 400;
        clis[0].vlocity_ins__Product2Id__c = products[0].Id;
        update clis;

        List<Contract> contracts = [SELECT Id, ARC_RecurringMonthlyOrder__c FROM Contract];
     
       
        List<ChargentOrders__Transaction__c> transactions1 =ARC_TestUtility.createChargentTransactions(2);
        List<ChargentOrders__Transaction__c> transactions2 =ARC_TestUtility.createChargentTransactions(1);
        List<ChargentOrders__Transaction__c> transactions3 =ARC_TestUtility.createChargentTransactions(1);
        List<ChargentOrders__Transaction__c> transactions4 =ARC_TestUtility.createChargentTransactions(1);

        List<ChargentOrders__ChargentOrder__c> orders = [SELECT Id, ARC_Contract__c FROM ChargentOrders__ChargentOrder__c];
        
        orders[0].ARC_Contract__c = contracts[0].Id;
        orders[1].ARC_Contract__c = contracts[0].Id;
        orders[2].ARC_Contract__c = contracts[0].Id;
        orders[3].ARC_Contract__c = contracts[0].Id;

        orders[1].ChargentOrders__Description__c = 'App Fee';
        orders[2].ChargentOrders__Description__c = 'Change Fee';
        orders[3].ChargentOrders__Description__c = 'One-Time Fee Testing';
        
        update orders;
        
        contracts[0].ARC_RecurringMonthlyOrder__c = orders[0].Id;
        update contracts;
      
        transactions1[0].ChargentOrders__Order__c = orders[0].Id;
        transactions1[0].ChargentOrders__Type__c = 'Charge';
        transactions1[0].ChargentOrders__Response_Status__c = 'Approved';
        transactions1[0].ChargentOrders__Amount__c = 400;
        
        transactions1[1].ChargentOrders__Order__c = orders[0].Id;
        transactions1[1].ChargentOrders__Type__c = 'Refund';
        transactions1[1].ChargentOrders__Response_Status__c = 'Approved';
        transactions1[1].ChargentOrders__Amount__c = 400;

        transactions2[0].ChargentOrders__Order__c = orders[1].Id;
        transactions2[0].ChargentOrders__Type__c = 'Charge';
        transactions2[0].ChargentOrders__Response_Status__c = 'Approved';
        transactions2[0].ChargentOrders__Amount__c = 99;

        transactions3[0].ChargentOrders__Order__c = orders[2].Id;
        transactions3[0].ChargentOrders__Type__c = 'Charge';
        transactions3[0].ChargentOrders__Response_Status__c = 'Approved';
        transactions3[0].ChargentOrders__Amount__c = 50;

        transactions4[0].ChargentOrders__Order__c = orders[3].Id;
        transactions4[0].ChargentOrders__Type__c = 'Charge';
        transactions4[0].ChargentOrders__Response_Status__c = 'Approved';
        transactions4[0].ChargentOrders__Amount__c = 120;

        List<ChargentOrders__Transaction__c> transactions = transactions1;
        transactions.addAll(transactions2);
        transactions.addAll(transactions3);
        transactions.addAll(transactions4);

        insert transactions;

        List<ARC_TransactionLineItem__c> tli = [SELECT Id FROM ARC_TransactionLineItem__c];
        delete tli;


        ARC_TransactionLineItemsBackfillBatch batch = new ARC_TransactionLineItemsBackfillBatch();
        Database.executeBatch(batch);
        
    }

    @isTest
    public static void ARC_TransactionLineItemsBatchE123Test() {
        //Create Records
         List<Product2> products = ARC_TestUtility.createTestProducts(1);
         products[0].vlocity_ins__Type__c = 'Medical';
         update products;
 
         List<vlocity_ins__ContractLineItem__c> clis =ARC_TestUtility.createTestContractLineItem(2);
         clis[0].vlocity_ins__UnitPrice__c = 400;
         clis[0].vlocity_ins__Product2Id__c = products[0].Id;
         update clis;
 
         List<Contract> contracts = [SELECT Id, ARC_RecurringMonthlyOrder__c FROM Contract];
      
        
         List<ChargentOrders__Transaction__c> transactions1 =ARC_TestUtility.createChargentTransactions(2);
 
         List<ChargentOrders__ChargentOrder__c> orders = [SELECT Id, ARC_Contract__c FROM ChargentOrders__ChargentOrder__c];
         
         orders[0].ARC_Contract__c = contracts[0].Id;
         
         orders[0].ChargentOrders__Description__c = 'Chargent Order to Hold E123 Transactions Only';
         
         update orders;
         
         contracts[0].ARC_RecurringMonthlyOrder__c = orders[0].Id;
         update contracts;
       
         transactions1[0].ChargentOrders__Order__c = orders[0].Id;
         transactions1[0].ChargentOrders__Type__c = 'Charge';
         transactions1[0].ChargentOrders__Response_Status__c = 'Approved';
         transactions1[0].ChargentOrders__Amount__c = 400;
         
         transactions1[1].ChargentOrders__Order__c = orders[0].Id;
         transactions1[1].ChargentOrders__Type__c = 'Refund';
         transactions1[1].ChargentOrders__Response_Status__c = 'Approved';
         transactions1[1].ChargentOrders__Amount__c = 400;
 
 
         insert transactions1;
 
         List<ARC_TransactionLineItem__c> tli = [SELECT Id FROM ARC_TransactionLineItem__c];
         delete tli;
 
 
         ARC_TransactionLineItemsBackfillBatch batch = new ARC_TransactionLineItemsBackfillBatch();
         Database.executeBatch(batch);
         
     }

     @isTest
     public static void ARC_TransactionLineItemsBatchE123HDTest() {
        //Create Records
         List<Product2> products = ARC_TestUtility.createTestProducts(1);
         products[0].vlocity_ins__Type__c = 'Medical';
         update products;
 
         List<vlocity_ins__ContractLineItem__c> clis =ARC_TestUtility.createTestContractLineItem(2);
         clis[0].vlocity_ins__UnitPrice__c = 300;
         clis[0].vlocity_ins__Product2Id__c = products[0].Id;
         update clis;
 
         List<Contract> contracts = [SELECT Id, ARC_RecurringMonthlyOrder__c FROM Contract];
      
        
         List<ChargentOrders__Transaction__c> transactions1 =ARC_TestUtility.createChargentTransactions(3);
 
         List<ChargentOrders__ChargentOrder__c> orders = [SELECT Id, ARC_Contract__c FROM ChargentOrders__ChargentOrder__c];
         
         orders[0].ARC_Contract__c = contracts[0].Id;
         
         orders[0].ChargentOrders__Description__c = 'Chargent Order to Hold E123 Transactions Only';
         
         update orders;
         
         contracts[0].ARC_RecurringMonthlyOrder__c = orders[0].Id;
         update contracts;
       
         transactions1[0].ChargentOrders__Order__c = orders[0].Id;
         transactions1[0].ChargentOrders__Type__c = 'Charge';
         transactions1[0].ChargentOrders__Response_Status__c = 'Approved';
         transactions1[0].ChargentOrders__Gateway_Date__c = System.today().addMonths(-4);
         transactions1[0].ChargentOrders__Amount__c = 400;
         
         transactions1[1].ChargentOrders__Order__c = orders[0].Id;
         transactions1[1].ChargentOrders__Type__c = 'Refund';
         transactions1[1].ChargentOrders__Response_Status__c = 'Approved';
         transactions1[0].ChargentOrders__Gateway_Date__c = System.today().addMonths(-4);
         transactions1[1].ChargentOrders__Amount__c = 400;

         transactions1[2].ChargentOrders__Order__c = orders[0].Id;
         transactions1[2].ChargentOrders__Type__c = 'Charge';
         transactions1[2].ChargentOrders__Response_Status__c = 'Approved';
         transactions1[2].ChargentOrders__Gateway_Date__c = System.today().addMonths(-1);
         transactions1[2].ChargentOrders__Amount__c = 300;
 
 
         insert transactions1;

         Healthy_Discount__c hd = new Healthy_Discount__c();
         hd.Contract__c = contracts[0].Id;
         hd.Old_Contract_Price__c = 400;
         hd.Healthy_Discount_Price__c = 300;
         hd.Is_Active__c = true;
         hd.Date_Approved__c = System.today().addMonths(-2);
         hd.Healthy_Status__c = 'Approved';
         insert hd;
 
         List<ARC_TransactionLineItem__c> tli = [SELECT Id FROM ARC_TransactionLineItem__c];
         delete tli;
 
 
         ARC_TransactionLineItemsBackfillBatch batch = new ARC_TransactionLineItemsBackfillBatch();
         Database.executeBatch(batch);
         
     }

     @isTest 
     public static void ARC_TransactionLineItemsBatchStandardCasesHDTest() {
        //Create Records
         List<Product2> products = ARC_TestUtility.createTestProducts(1);
         products[0].vlocity_ins__Type__c = 'Medical';
         update products;
 
         List<vlocity_ins__ContractLineItem__c> clis =ARC_TestUtility.createTestContractLineItem(2);
         clis[0].vlocity_ins__UnitPrice__c = 300;
         clis[0].vlocity_ins__Product2Id__c = products[0].Id;
         update clis;
 
         List<Contract> contracts = [SELECT Id, ARC_RecurringMonthlyOrder__c FROM Contract];
      
        
         List<ChargentOrders__Transaction__c> transactions1 =ARC_TestUtility.createChargentTransactions(3);
      
         List<ChargentOrders__ChargentOrder__c> orders = [SELECT Id, ARC_Contract__c FROM ChargentOrders__ChargentOrder__c];
         
         orders[0].ARC_Contract__c = contracts[0].Id;     
         
         update orders;
         
         contracts[0].ARC_RecurringMonthlyOrder__c = orders[0].Id;
         update contracts;
         
         transactions1[0].ChargentOrders__Order__c = orders[0].Id;
         transactions1[0].ChargentOrders__Type__c = 'Charge';
         transactions1[0].ChargentOrders__Response_Status__c = 'Approved';
         transactions1[0].ChargentOrders__Amount__c = 400;
         transactions1[0].ChargentOrders__Gateway_Date__c = System.today().addMonths(-4);
         
         transactions1[1].ChargentOrders__Order__c = orders[0].Id;
         transactions1[1].ChargentOrders__Type__c = 'Refund';
         transactions1[1].ChargentOrders__Response_Status__c = 'Approved';
         transactions1[1].ChargentOrders__Amount__c = 400;
         transactions1[1].ChargentOrders__Gateway_Date__c = System.today().addMonths(-4);
 
         transactions1[2].ChargentOrders__Order__c = orders[0].Id;
         transactions1[2].ChargentOrders__Type__c = 'Charge';
         transactions1[2].ChargentOrders__Response_Status__c = 'Approved';
         transactions1[2].ChargentOrders__Gateway_Date__c = System.today().addMonths(-1);
         transactions1[2].ChargentOrders__Amount__c = 300;
         insert transactions1;

         Healthy_Discount__c hd = new Healthy_Discount__c();
         hd.Contract__c = contracts[0].Id;
         hd.Old_Contract_Price__c = 400;
         hd.Healthy_Discount_Price__c = 300;
         hd.Is_Active__c = true;
         hd.Date_Approved__c = System.today().addMonths(-2);
         hd.Healthy_Status__c = 'Approved';
         insert hd;
 
         List<ARC_TransactionLineItem__c> tli = [SELECT Id FROM ARC_TransactionLineItem__c];
         delete tli;
 
 
         ARC_TransactionLineItemsBackfillBatch batch = new ARC_TransactionLineItemsBackfillBatch();
         Database.executeBatch(batch);
         
     }
 

    }