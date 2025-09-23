@isTest
public class  ARC_CreateContLineItemsGuestUsersTest {
    
    @isTest
    public static void createContractLineItemsGuestUsersTest() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'CreateContractLineItems';
        Map<String,Object> contractJson = new Map<String,Object>();
        Map<String,Object> productConfigurationDetail = new Map<String,Object>();
        List<Object> records = new List<Object>();
        Map<String,Object> record1 = new Map<String,Object>();
        Map<String,Object> childProducts = new Map<String,Object>();
        List<Object> childRecords = new List<Object>();
        Map<String,Object> childRecord1 = new Map<String,Object>();
        List<Object> rawPriceData = new List<Object>();
        Map<String,Object> rawPriceRecord = new Map<String,Object>();
        List<Object> calculationResults = new List<Object>();
        Map<String,Object> calcResRecord = new Map<String,Object>();
        Account acc = new Account(Name = 'test');
        insert acc;
        Contract contr = new Contract(AccountId=acc.Id);
        insert contr;
        Product2 prod = new Product2(Name='test');
        insert prod;
        Product2 childProd = new Product2(Name='childTest');
        insert childProd;
        List<vlocity_ins__GroupCensusMember__c> censMember = ARC_TestUtility.createTestCensusMember(1);
        record1.put('Name', 'test');
        record1.put('productId', prod.Id);
        record1.put('Price', 12.30);
        record1.put('Id', prod.Id);
        record1.put('EndDate', Date.valueOf('2022-10-10'));
        childRecord1.put('Name', 'childTest');
        childRecord1.put('productId', childProd.Id);
        childRecord1.put('Price', 12.30);
        childRecord1.put('Id',childProd.Id);
        childRecord1.put('EndDate', Date.valueOf('2022-10-10'));
        Map<String,Object> listRecords = new  Map<String,Object>();
        listRecords.put('calculationResults','Test1');
        childRecord1.put('RawPriceData', listRecords);
        childRecords.add(childRecord1);
        childProducts.put('records', childRecords);
        system.debug('records'+ childRecords);
        calcResRecord.put('CensusMemberId', censMember[0].Id);
        calculationResults.add(calcResRecord);
        rawPriceRecord.put('calculationResults', calculationResults);
        rawPriceData.add(rawPriceRecord);
        record1.put('RawPriceData', rawPriceData);
        system.debug('record1'+' '+ record1);
        record1.put('childProducts', childProducts);
        records.add(record1);
        productConfigurationDetail.put('records', records);
        
        contractJson.put('productConfigurationDetail', productConfigurationDetail);

        inputMap.put('ContractId', contr.Id);
        inputMap.put('contractJson', contractJson);

        ARC_CreateContractLineItemsGuestUsers newInst = new ARC_CreateContractLineItemsGuestUsers();

        Test.startTest();
            newInst.invokeMethod(methodName, inputMap, outMap, options);
        Test.stopTest();
    }

    @isTest
    public static void createMultiContractLineItemsGuestUsersTest() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'CreateMultiContractLineItems';
        Map<String,Object> contractJson = new Map<String,Object>();
        Map<String, Object> contract1 = new Map<String, Object>();
        Map<String, Object> contract2 = new Map<String, Object>();
        Map<String, Object> contract3 = new Map<String, Object>();
        Map<String, Object> contractJsonContainer = new Map<String, Object>();
        Map<String,Object> productConfigurationDetail = new Map<String,Object>();
        List<Object> records = new List<Object>();
        List<Object> listContractJson = new List<Object>();
        Map<String,Object> record1 = new Map<String,Object>();
        Map<String,Object> childProducts = new Map<String,Object>();
        List<Object> childRecords = new List<Object>();
        Map<String,Object> childRecord1 = new Map<String,Object>();

        Account acc = new Account(Name = 'test');
        insert acc;
        Contract contr1 = new Contract(AccountId=acc.Id);
        insert contr1;
        Contract contr2 = new Contract(AccountId=acc.Id);
        insert contr2;
        Contract contr3 = new Contract(AccountId=acc.Id);
        insert contr3;
        Product2 prod = new Product2(Name='test');
        insert prod;
        Product2 childProd = new Product2(Name='childTest');
        insert childProd;

        record1.put('Name', 'test');
        record1.put('productId', prod.Id);
        record1.put('Price', 12.30);
        record1.put('Id', prod.Id);
        record1.put('EndDate', Date.valueOf('2022-10-10'));
        childRecord1.put('Name', 'childTest');
        childRecord1.put('productId', childProd.Id);
        childRecord1.put('Price', 12.30);
        childRecord1.put('Id',childProd.Id);
        childRecord1.put('EndDate', Date.valueOf('2022-10-10'));
        childRecords.add(childRecord1);
        childProducts.put('records', childRecords);
        record1.put('childProducts', childProducts);
        records.add(record1);
        productConfigurationDetail.put('records', records);

        contractJson.put('productConfigurationDetail', productConfigurationDetail);
        contract1.put('ContractId', contr1.Id);
        contract1.put('contractJson', contractJson);
        contract2.put('ContractId', contr2.Id);
        contract2.put('contractJson', contractJson);
        contract3.put('ContractId', contr3.Id);
        contract3.put('contractJson', contractJson);
        // contractJsonContainer.put('contractJson', contractJson);
        listContractJson.add(contract1);
        listContractJson.add(contract2);
        listContractJson.add(contract3);
        // listContractJson.add(contractJsonContainer);

        inputMap.put('listContractJson', listContractJson);
        ARC_CreateContractLineItemsGuestUsers newInst = new ARC_CreateContractLineItemsGuestUsers();

        Test.startTest();
            newInst.invokeMethod(methodName, inputMap, outMap, options);
        Test.stopTest();
    }
}