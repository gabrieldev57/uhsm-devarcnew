@isTest
public class ARC_TLIBackfillBatchTest {
    
    @TestSetup
    static void makeData(){
        // Create test data
        List<Account> accounts = ARC_TestUtility.createTestAccount(1, 'ARC_IFPPersonAccount');
        
        Contract cont = ARC_TestUtility.createContractsAA(1)[0];
        cont.AccountId = accounts[0].Id;
        cont.ARC_EffectiveDate__c = System.today();
        insert cont;
        cont.Status = 'Activated';
        update cont;

        // Create Product
        Product2 medicalProduct = new Product2(
            Name = 'Test Medical Product',
            ProductCode = 'TMP-001',
            vlocity_ins__Type__c = 'Medical',
            vlocity_ins__SubType__c = 'PPO'
        );
        insert medicalProduct;

        // Create ContractLineItem
        vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c(
            vlocity_ins__ContractId__c = cont.Id,
            vlocity_ins__Product2Id__c = medicalProduct.Id,
            // vlocity_ins__RecordTypeName__c = 'Product',
            // vlocity_ins__ProductType__c = 'Medical',
            ARC_SmokerFee__c = 50,
            ARC_ExtraDependentFee__c = 30
        );
        insert cli;

        // Create ChargentOrder
        ChargentOrders__ChargentOrder__c chargentOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = cont.Id,
            ChargentOrders__Charge_Amount__c = 500,
            ChargentOrders__Description__c = 'Recurring Monthly Order'
        );
        insert chargentOrder;

        // Create Transaction
        ChargentOrders__Transaction__c transa = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargentOrder.Id,
            ChargentOrders__Amount__c = 500,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved'
        );
        insert transa;

        // Create TransactionLineItem
        ARC_TransactionLineItem__c tli = new ARC_TransactionLineItem__c(
            ARC_Transaction__c = transa.Id,
            ARC_Product__c = medicalProduct.Id,
            ARC_Amount__c = 500,
            Name = 'Test Medical Product'
        );
        insert tli;
    }

    @isTest
    static void testBatchExecution() {
        // Start test execution
        Test.startTest();
        
        ARC_TLIBackfillBatch batch = new ARC_TLIBackfillBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();

        // Verify results
        List<ARC_TransactionLineItem__c> updatedTLIs = [SELECT Id, Name, ARC_Amount__c FROM ARC_TransactionLineItem__c];
        // System.assertEquals(3, updatedTLIs.size(), 'Expected 3 TransactionLineItems after batch execution');

        Map<String, Decimal> expectedAmounts = new Map<String, Decimal>{
            'Test Medical Product' => 420,
            'Smoker Fee' => 50,
            'Extra Dependent Fee' => 30
        };

        for (ARC_TransactionLineItem__c tli : updatedTLIs) {
            // System.assert(expectedAmounts.containsKey(tli.Name), 'Unexpected TransactionLineItem: ' + tli.Name);
            // System.assertEquals(expectedAmounts.get(tli.Name), tli.ARC_Amount__c, 'Incorrect amount for ' + tli.Name);
        }
    }

    @isTest
    static void testBatchWithExcludedIds() {
        // Get the ID of the existing TransactionLineItem
        ARC_TransactionLineItem__c existingTLI = [SELECT Id FROM ARC_TransactionLineItem__c LIMIT 1];

        // Start test execution
        Test.startTest();
        
        ARC_TLIBackfillBatch batch = new ARC_TLIBackfillBatch();
        batch.excludeIds = new Set<Id>{ existingTLI.Id };
        Database.executeBatch(batch, 200);
        
        Test.stopTest();

        // Verify results
        List<ARC_TransactionLineItem__c> updatedTLIs = [SELECT Id, Name, ARC_Amount__c FROM ARC_TransactionLineItem__c];
        System.assertEquals(1, updatedTLIs.size(), 'Expected only 1 TransactionLineItem after batch execution with excluded ID');
        System.assertEquals(500, updatedTLIs[0].ARC_Amount__c, 'Amount should not have changed for excluded TransactionLineItem');
    }
}