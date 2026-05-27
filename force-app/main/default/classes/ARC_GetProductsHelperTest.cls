@isTest
private class ARC_GetProductsHelperTest {
    
    @isTest
    static void testInvokeMethodTransformGetProducts() {
        // Test the invokeMethod entry point
        ARC_GetProductsHelper helper = new ARC_GetProductsHelper();
        Map<String, Object> inputMap = createTestInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = helper.invokeMethod('transformGetProducts', inputMap, outputMap, options);
        Test.stopTest();
        
        System.assertEquals(true, result, 'invokeMethod should return true');
        System.assert(outputMap.containsKey('products'), 'outputMap should contain products');
    }
    
    @isTest
    static void testInvokeMethodInvalidMethod() {
        // Test invokeMethod with invalid method name
        ARC_GetProductsHelper helper = new ARC_GetProductsHelper();
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        Boolean result = helper.invokeMethod('invalidMethod', inputMap, outputMap, options);
        Test.stopTest();
        
        System.assertEquals(true, result, 'invokeMethod should return true even for invalid method');
    }
    
    @isTest
    static void testTransformGetProductsBasic() {
        // Test basic transformation with products grouped by product code
        Map<String, Object> inputMap = createTestInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();
        
        List<Object> resultProducts = (List<Object>)outputMap.get('products');
        System.assertNotEquals(null, resultProducts, 'Result products should not be null');
        System.assertEquals(2, resultProducts.size(), 'Should have 2 groups');
        
        // Verify first group
        Map<String, Object> group1 = (Map<String, Object>)resultProducts[0];
        System.assert(group1.containsKey('groupName'), 'Group should have groupName');
        System.assert(group1.containsKey('products'), 'Group should have products');
        System.assert(group1.containsKey('uniqueAttributes'), 'Group should have uniqueAttributes');
        System.assert(group1.containsKey('description'), 'Group should have description');
        System.assert(group1.containsKey('hiddenAttributes'), 'Group should have hiddenAttributes');
    }
    
    @isTest
    static void testTransformGetProductsWithChildProducts() {
        // Test transformation with child products
        Map<String, Object> inputMap = createTestInputMapWithChildProducts();
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();
        
        List<Object> resultProducts = (List<Object>)outputMap.get('products');
        System.assertNotEquals(null, resultProducts, 'Result products should not be null');
        
        // Verify child products are cleaned
        Map<String, Object> group1 = (Map<String, Object>)resultProducts[0];
        List<Object> products = (List<Object>)group1.get('products');
        Map<String, Object> product = (Map<String, Object>)products[0];
        
        System.assert(product.containsKey('childProducts'), 'Product should have childProducts');
        Map<String, Object> childProducts = (Map<String, Object>)product.get('childProducts');
        System.assert(!childProducts.containsKey('totalSize'), 'totalSize should be removed from childProducts');
        
        // Verify Census record is removed
        List<Object> records = (List<Object>)childProducts.get('records');
        for (Object recordObj : records) {
            Map<String, Object> record = (Map<String, Object>)recordObj;
            if (record.containsKey('Name')) {
                System.assertNotEquals('Census', record.get('Name'), 'Census record should be removed');
            }
        }
    }
    
    @isTest
    static void testTransformGetProductsWithAttributeCategories() {
        // Test transformation with attribute categories
        Map<String, Object> inputMap = createTestInputMapWithAttributeCategories();
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();
        
        List<Object> resultProducts = (List<Object>)outputMap.get('products');
        System.assertNotEquals(null, resultProducts, 'Result products should not be null');
        
        Map<String, Object> group1 = (Map<String, Object>)resultProducts[0];
        List<Object> products = (List<Object>)group1.get('products');
        Map<String, Object> product = (Map<String, Object>)products[0];
        
        System.assert(product.containsKey('attributeCategories'), 'Product should have attributeCategories');
        Map<String, Object> attrCategories = (Map<String, Object>)product.get('attributeCategories');
        System.assert(!attrCategories.containsKey('totalSize'), 'totalSize should be removed from attributeCategories');
    }
    
    @isTest
    static void testTransformGetProductsWithNestedStructures() {
        // Test transformation with deeply nested structures (childProducts -> attributeCategories -> productAttributes)
        Map<String, Object> inputMap = createTestInputMapWithNestedStructures();
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();
        
        List<Object> resultProducts = (List<Object>)outputMap.get('products');
        System.assertNotEquals(null, resultProducts, 'Result products should not be null');
        System.assert(resultProducts.size() > 0, 'Should have at least one group');
        
        // Verify nested structure is properly cleaned
        Map<String, Object> group1 = (Map<String, Object>)resultProducts[0];
        List<Object> products = (List<Object>)group1.get('products');
        System.assert(products.size() > 0, 'Group should have products');
        
        Map<String, Object> product = (Map<String, Object>)products[0];
        System.assert(product.containsKey('childProducts'), 'Product should have childProducts');
        
        Map<String, Object> childProducts = (Map<String, Object>)product.get('childProducts');
        System.assertNotEquals(null, childProducts, 'childProducts should not be null');
        System.assert(!childProducts.containsKey('totalSize'), 'totalSize should be removed from childProducts');
        
        List<Object> records = (List<Object>)childProducts.get('records');
        System.assertNotEquals(null, records, 'records should not be null');
        
        // Find a record with attributeCategories (the Census one should be removed)
        Map<String, Object> recordWithAttrCategories = null;
        for (Object recordObj : records) {
            Map<String, Object> record = (Map<String, Object>)recordObj;
            if (record.containsKey('attributeCategories') && record.get('attributeCategories') != null) {
                recordWithAttrCategories = record;
                break;
            }
        }
        
        System.assertNotEquals(null, recordWithAttrCategories, 'Should have a record with attributeCategories');
        Map<String, Object> attrCategories = (Map<String, Object>)recordWithAttrCategories.get('attributeCategories');
        System.assert(!attrCategories.containsKey('totalSize'), 'totalSize should be removed from attributeCategories');
        
        List<Object> attrRecords = (List<Object>)attrCategories.get('records');
        if (attrRecords != null && attrRecords.size() > 0) {
            Map<String, Object> attrRecord = (Map<String, Object>)attrRecords[0];
            if (attrRecord.containsKey('productAttributes')) {
                Map<String, Object> productAttributes = (Map<String, Object>)attrRecord.get('productAttributes');
                System.assert(!productAttributes.containsKey('totalSize'), 'totalSize should be removed from productAttributes');
            }
        }
    }
    
    @isTest
    static void testTransformGetProductsEmptyInput() {
        // Test with empty products list
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('products', new List<Object>());
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();
        
        List<Object> resultProducts = (List<Object>)outputMap.get('products');
        System.assertNotEquals(null, resultProducts, 'Result products should not be null');
        System.assertEquals(0, resultProducts.size(), 'Should have 0 groups for empty input');
    }
    
    @isTest
    static void testTransformGetProductsMultipleGroups() {
        // Test with products from multiple groups
        Map<String, Object> inputMap = createTestInputMapMultipleGroups();
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();
        
        List<Object> resultProducts = (List<Object>)outputMap.get('products');
        System.assertNotEquals(null, resultProducts, 'Result products should not be null');
        System.assertEquals(2, resultProducts.size(), 'Should have 2 groups');
    }
    
    @isTest
    static void testTransformGetProductsRemovesUnwantedKeys() {
        // Test that unwanted keys are removed from products
        Map<String, Object> inputMap = createTestInputMapWithExtraKeys();
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();
        
        List<Object> resultProducts = (List<Object>)outputMap.get('products');
        Map<String, Object> group1 = (Map<String, Object>)resultProducts[0];
        List<Object> products = (List<Object>)group1.get('products');
        Map<String, Object> product = (Map<String, Object>)products[0];
        
        // Verify only allowed keys remain
        Set<String> allowedKeys = new Set<String>{
            'childProducts', 'attributeCategories', 'Price',
            'Type__c', 'ProductCode', 'Name', 'productId'
        };
        
        for (String key : product.keySet()) {
            System.assert(allowedKeys.contains(key), 'Key ' + key + ' should be in allowed keys or should have been removed');
        }
    }
    
    @isTest
    static void testClearChildProductsWithEmptyRecords() {
        // Test clearChildProductsJSON with empty records (covers line 65 when childProducts exists)
        Map<String, Object> inputMap = new Map<String, Object>();
        List<Object> products = new List<Object>();
        
        Map<String, Object> product1 = new Map<String, Object>();
        product1.put('ProductCode', 'Product 1');
        product1.put('Name', 'Product Name 1');
        product1.put('Type__c', 'Type1');
        product1.put('Price', 100.00);
        
        Map<String, Object> childProducts = new Map<String, Object>();
        childProducts.put('totalSize', 0);
        childProducts.put('records', new List<Object>());
        product1.put('childProducts', childProducts);
        
        // Add empty attributeCategories to avoid NPE on line 67 (clearAttributeCategoriesJSON)
        product1.put('attributeCategories', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        
        products.add(product1);
        inputMap.put('products', products);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();
        
        List<Object> resultProducts = (List<Object>)outputMap.get('products');
        System.assertNotEquals(null, resultProducts, 'Result products should not be null');
        
        // Verify childProducts totalSize was removed (line 65 coverage - clearChildProductsJSON was called)
        Map<String, Object> group1 = (Map<String, Object>)resultProducts[0];
        List<Object> resultProductsList = (List<Object>)group1.get('products');
        Map<String, Object> resultProduct = (Map<String, Object>)resultProductsList[0];
        Map<String, Object> resultChildProducts = (Map<String, Object>)resultProduct.get('childProducts');
        System.assert(!resultChildProducts.containsKey('totalSize'), 'totalSize should be removed');
    }
    
    @isTest
    static void testClearChildProductsWithAttributeCategories() {
        // Test clearChildProductsJSON with records that have attributeCategories (covers line 86)
        Map<String, Object> inputMap = new Map<String, Object>();
        List<Object> products = new List<Object>();
        
        Map<String, Object> product1 = new Map<String, Object>();
        product1.put('ProductCode', 'Product 1');
        product1.put('Name', 'Product Name 1');
        product1.put('Type__c', 'Type1');
        product1.put('Price', 100.00);
        // Add empty attributeCategories at product level
        product1.put('attributeCategories', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        
        Map<String, Object> childProducts = new Map<String, Object>();
        childProducts.put('totalSize', 1);
        List<Object> records = new List<Object>();
        
        // Create a record with attributeCategories (to cover line 86)
        Map<String, Object> record = new Map<String, Object>();
        record.put('Name', 'Test Child Product');
        record.put('Id', 'child1');
        
        Map<String, Object> attrCategories = new Map<String, Object>();
        attrCategories.put('totalSize', 1);
        attrCategories.put('records', new List<Object>());
        record.put('attributeCategories', attrCategories);
        
        records.add(record);
        childProducts.put('records', records);
        product1.put('childProducts', childProducts);
        
        products.add(product1);
        inputMap.put('products', products);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();
        
        List<Object> resultProducts = (List<Object>)outputMap.get('products');
        System.assertNotEquals(null, resultProducts, 'Result products should not be null');
        
        // Verify attributeCategories totalSize was removed (line 86 coverage)
        Map<String, Object> group1 = (Map<String, Object>)resultProducts[0];
        List<Object> resultProductsList = (List<Object>)group1.get('products');
        Map<String, Object> resultProduct = (Map<String, Object>)resultProductsList[0];
        Map<String, Object> resultChildProducts = (Map<String, Object>)resultProduct.get('childProducts');
        List<Object> resultRecords = (List<Object>)resultChildProducts.get('records');
        System.assert(resultRecords.size() > 0, 'Should have records in childProducts');
        Map<String, Object> resultRecord = (Map<String, Object>)resultRecords[0];
        System.assert(resultRecord.containsKey('attributeCategories'), 'Record should have attributeCategories');
        Map<String, Object> resultAttrCategories = (Map<String, Object>)resultRecord.get('attributeCategories');
        System.assert(!resultAttrCategories.containsKey('totalSize'), 'totalSize should be removed from attributeCategories in childProducts');
    }
    
    @isTest
    static void testClearAttributeCategoriesWithEmptyRecords() {
        // Test clearAttributeCategoriesJSON with empty records
        Map<String, Object> inputMap = new Map<String, Object>();
        List<Object> products = new List<Object>();
        
        Map<String, Object> product1 = new Map<String, Object>();
        product1.put('ProductCode', 'Product 1');
        product1.put('Name', 'Product Name 1');
        product1.put('Type__c', 'Type1');
        product1.put('Price', 100.00);
        
        // Add empty childProducts to avoid NPE on line 65 (clearChildProductsJSON)
        product1.put('childProducts', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        
        Map<String, Object> attributeCategories = new Map<String, Object>();
        attributeCategories.put('totalSize', 0);
        attributeCategories.put('records', new List<Object>());
        product1.put('attributeCategories', attributeCategories);
        
        products.add(product1);
        inputMap.put('products', products);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();
        
        List<Object> resultProducts = (List<Object>)outputMap.get('products');
        System.assertNotEquals(null, resultProducts, 'Result products should not be null');
    }
    
    @isTest
    static void testTransformGetProductsAllFourProducts() {
        // Test with all four products from the test metadata (Product 1, 2, 3, 4)
        Map<String, Object> inputMap = new Map<String, Object>();
        List<Object> products = new List<Object>();
        
        Map<String, Object> product1 = new Map<String, Object>();
        product1.put('ProductCode', 'Product 1');
        product1.put('Name', 'Product Name 1');
        product1.put('childProducts', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        product1.put('attributeCategories', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        products.add(product1);
        
        Map<String, Object> product2 = new Map<String, Object>();
        product2.put('ProductCode', 'Product 2');
        product2.put('Name', 'Product Name 2');
        product2.put('childProducts', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        product2.put('attributeCategories', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        products.add(product2);
        
        Map<String, Object> product3 = new Map<String, Object>();
        product3.put('ProductCode', 'Product 3');
        product3.put('Name', 'Product Name 3');
        product3.put('childProducts', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        product3.put('attributeCategories', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        products.add(product3);
        
        Map<String, Object> product4 = new Map<String, Object>();
        product4.put('ProductCode', 'Product 4');
        product4.put('Name', 'Product Name 4');
        product4.put('childProducts', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        product4.put('attributeCategories', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        products.add(product4);
        
        inputMap.put('products', products);
        
        Map<String, Object> outputMap = new Map<String, Object>();
        
        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();
        
        List<Object> resultProducts = (List<Object>)outputMap.get('products');
        System.assertNotEquals(null, resultProducts, 'Result products should not be null');
        System.assertEquals(2, resultProducts.size(), 'Should have 2 groups');
        
        // Verify Group 1 has 2 products
        Map<String, Object> group1 = (Map<String, Object>)resultProducts[0];
        List<Object> group1Products = (List<Object>)group1.get('products');
        System.assertEquals(2, group1Products.size(), 'Group 1 should have 2 products');
        
        // Verify Group 2 has 2 products
        Map<String, Object> group2 = (Map<String, Object>)resultProducts[1];
        List<Object> group2Products = (List<Object>)group2.get('products');
        System.assertEquals(2, group2Products.size(), 'Group 2 should have 2 products');
    }

    @isTest
    static void testTransformGetProducts_NullProducts() {
        Map<String, Object> inputMap = new Map<String, Object>{
            'products' => null
        };
        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();

        System.assert(outputMap.containsKey('tierFactorValue'));
        System.assert(outputMap.containsKey('products'));

        List<Object> resultProducts = (List<Object>)outputMap.get('products');
        System.assertNotEquals(null, resultProducts);
        System.assertEquals(0, resultProducts.size());
        System.assertEquals(null, outputMap.get('tierFactorValue'));
    }

    @isTest
static void testTransformGetProducts_UnmappedProductCode_GoesToLegacy() {
    Map<String, Object> inputMap = new Map<String, Object>();
    List<Object> products = new List<Object>();

    Map<String, Object> product = new Map<String, Object>();
    product.put('ProductCode', 'UNMAPPED_PRODUCT');
    product.put('Name', 'Legacy Product');
    product.put('Type__c', 'TypeX');
    product.put('Price', 150);
    product.put('productId', 'legacy1');
    product.put('childProducts', new Map<String, Object>{ 'totalSize' => 0, 'records' => new List<Object>() });
    product.put('attributeCategories', new Map<String, Object>{ 'totalSize' => 0, 'records' => new List<Object>() });

    products.add(product);
    inputMap.put('products', products);

    Map<String, Object> outputMap = new Map<String, Object>();

    Test.startTest();
    ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
    Test.stopTest();

    List<Object> resultProducts = (List<Object>)outputMap.get('products');
    System.assertEquals(1, resultProducts.size());

    Map<String, Object> groupData = (Map<String, Object>)resultProducts[0];
    System.assertEquals('Legacy', groupData.get('groupName'));
    System.assertEquals(null, groupData.get('uniqueAttributes'));
    System.assertEquals(null, groupData.get('description'));
    System.assertEquals(null, groupData.get('hiddenAttributes'));
}
    @isTest
    static void testTransformGetProducts_TierFactor_FromRawPriceData() {
        Map<String, Object> inputMap = new Map<String, Object>();
        List<Object> products = new List<Object>();

        Map<String, Object> product = new Map<String, Object>();
        product.put('ProductCode', 'Product 1');
        product.put('Name', 'Product Name 1');
        product.put('Type__c', 'Type1');
        product.put('Price', 100);
        product.put('productId', 'prod1');
        product.put('childProducts', new Map<String, Object>{ 'totalSize' => 0, 'records' => new List<Object>() });
        product.put('attributeCategories', new Map<String, Object>{ 'totalSize' => 0, 'records' => new List<Object>() });

        product.put(
            'RawPriceData',
            new List<Object>{
                new Map<String, Object>{
                    'calculationResults' => new List<Object>{
                        new Map<String, Object>{
                            'ARC_SmallGroupTierMultiplier__TierFactor' => '1.25'
                        }
                    }
                }
            }
        );

        products.add(product);
        inputMap.put('products', products);

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();

        Decimal tierFactor = (Decimal)outputMap.get('tierFactorValue');
        System.assertEquals(1.25, tierFactor);
    }

    @isTest
    static void testTransformGetProducts_TierFactor_FromCalculatedDetailPrice() {
        Map<String, Object> inputMap = new Map<String, Object>();
        List<Object> products = new List<Object>();

        Map<String, Object> product = new Map<String, Object>();
        product.put('ProductCode', 'Product 1');
        product.put('Name', 'Product Name 1');
        product.put('Type__c', 'Type1');
        product.put('Price', 100);
        product.put('productId', 'prod1');
        product.put('childProducts', new Map<String, Object>{ 'totalSize' => 0, 'records' => new List<Object>() });
        product.put('attributeCategories', new Map<String, Object>{ 'totalSize' => 0, 'records' => new List<Object>() });

        product.put(
            'CalculatedPriceData',
            new Map<String, Object>{
                'detailPrice' => new List<Object>{
                    new Map<String, Object>{
                        'ARC_SmallGroupTierMultiplier__TierFactor' => '1.50'
                    }
                }
            }
        );

        products.add(product);
        inputMap.put('products', products);

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();

        Decimal tierFactor = (Decimal)outputMap.get('tierFactorValue');
        System.assertEquals(1.50, tierFactor);
    }

    @isTest
    static void testTransformGetProducts_TierFactor_FromCalculatedTopLevel() {
        Map<String, Object> inputMap = new Map<String, Object>();
        List<Object> products = new List<Object>();

        Map<String, Object> product = new Map<String, Object>();
        product.put('ProductCode', 'Product 1');
        product.put('Name', 'Product Name 1');
        product.put('Type__c', 'Type1');
        product.put('Price', 100);
        product.put('productId', 'prod1');
        product.put('childProducts', new Map<String, Object>{ 'totalSize' => 0, 'records' => new List<Object>() });
        product.put('attributeCategories', new Map<String, Object>{ 'totalSize' => 0, 'records' => new List<Object>() });

        product.put(
            'CalculatedPriceData',
            new Map<String, Object>{
                'ARC_SmallGroupTierMultiplier__TierFactor' => '1.75'
            }
        );

        products.add(product);
        inputMap.put('products', products);

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();

        Decimal tierFactor = (Decimal)outputMap.get('tierFactorValue');
        System.assertEquals(1.75, tierFactor);
    }

    @isTest
    static void testTransformGetProducts_TierFactor_InvalidValue_ReturnsNull() {
        Map<String, Object> inputMap = new Map<String, Object>();
        List<Object> products = new List<Object>();

        Map<String, Object> product = new Map<String, Object>();
        product.put('ProductCode', 'Product 1');
        product.put('Name', 'Product Name 1');
        product.put('Type__c', 'Type1');
        product.put('Price', 100);
        product.put('productId', 'prod1');
        product.put('childProducts', new Map<String, Object>{ 'totalSize' => 0, 'records' => new List<Object>() });
        product.put('attributeCategories', new Map<String, Object>{ 'totalSize' => 0, 'records' => new List<Object>() });

        product.put(
            'RawPriceData',
            new List<Object>{
                new Map<String, Object>{
                    'calculationResults' => new List<Object>{
                        new Map<String, Object>{
                            'ARC_SmallGroupTierMultiplier__TierFactor' => 'abc'
                        }
                    }
                }
            }
        );

        products.add(product);
        inputMap.put('products', products);

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_GetProductsHelper.transformGetProducts(inputMap, outputMap);
        Test.stopTest();

        System.assertEquals(null, outputMap.get('tierFactorValue'));
    }
    
    // Helper methods to create test data
    
    private static Map<String, Object> createTestInputMap() {
        Map<String, Object> inputMap = new Map<String, Object>();
        List<Object> products = new List<Object>();
        
        Map<String, Object> product1 = new Map<String, Object>();
        product1.put('ProductCode', 'Product 1');
        product1.put('Name', 'Product Name 1');
        product1.put('Type__c', 'Type1');
        product1.put('Price', 100.00);
        product1.put('productId', 'prod1');
        product1.put('childProducts', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        product1.put('attributeCategories', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        
        Map<String, Object> product2 = new Map<String, Object>();
        product2.put('ProductCode', 'Product 3');
        product2.put('Name', 'Product Name 2');
        product2.put('Type__c', 'Type2');
        product2.put('Price', 200.00);
        product2.put('productId', 'prod2');
        product2.put('childProducts', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        product2.put('attributeCategories', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        
        products.add(product1);
        products.add(product2);
        inputMap.put('products', products);
        
        return inputMap;
    }
    
    private static Map<String, Object> createTestInputMapWithChildProducts() {
        Map<String, Object> inputMap = createTestInputMap();
        List<Object> products = (List<Object>)inputMap.get('products');
        Map<String, Object> product = (Map<String, Object>)products[0];
        
        Map<String, Object> childProducts = new Map<String, Object>();
        childProducts.put('totalSize', 3);
        List<Object> records = new List<Object>();
        
        Map<String, Object> censusRecord = new Map<String, Object>();
        censusRecord.put('Name', 'Census');
        censusRecord.put('Id', 'census1');
        censusRecord.put('attributeCategories', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        records.add(censusRecord);
        
        Map<String, Object> regularRecord = new Map<String, Object>();
        regularRecord.put('Name', 'Regular Child');
        regularRecord.put('Id', 'child1');
        regularRecord.put('attributeCategories', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        records.add(regularRecord);
        
        childProducts.put('records', records);
        product.put('childProducts', childProducts);
        
        return inputMap;
    }
    
    private static Map<String, Object> createTestInputMapWithAttributeCategories() {
        Map<String, Object> inputMap = createTestInputMap();
        List<Object> products = (List<Object>)inputMap.get('products');
        Map<String, Object> product = (Map<String, Object>)products[0];
        
        Map<String, Object> attributeCategories = new Map<String, Object>();
        attributeCategories.put('totalSize', 2);
        List<Object> records = new List<Object>();
        
        Map<String, Object> attrRecord = new Map<String, Object>();
        attrRecord.put('Name', 'Attribute Category 1');
        attrRecord.put('productAttributes', new Map<String, Object>{
            'totalSize' => 0, 
            'records' => new List<Object>()
        });
        records.add(attrRecord);
        
        attributeCategories.put('records', records);
        product.put('attributeCategories', attributeCategories);
        
        return inputMap;
    }
    
    private static Map<String, Object> createTestInputMapWithNestedStructures() {
        Map<String, Object> inputMap = new Map<String, Object>();
        List<Object> products = new List<Object>();
        
        Map<String, Object> product1 = new Map<String, Object>();
        product1.put('ProductCode', 'Product 1');
        product1.put('Name', 'Product Name 1');
        product1.put('Type__c', 'Type1');
        product1.put('Price', 100.00);
        product1.put('productId', 'prod1');
        
        Map<String, Object> childProducts = new Map<String, Object>();
        childProducts.put('totalSize', 2);
        List<Object> records = new List<Object>();
        
        Map<String, Object> censusRecord = new Map<String, Object>();
        censusRecord.put('Name', 'Census');
        censusRecord.put('Id', 'census1');
        censusRecord.put('attributeCategories', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        records.add(censusRecord);
        
        Map<String, Object> regularRecord = new Map<String, Object>();
        regularRecord.put('Name', 'Regular Child');
        regularRecord.put('Id', 'child1');
        
        Map<String, Object> attrCategories = new Map<String, Object>();
        attrCategories.put('totalSize', 1);
        List<Object> attrRecords = new List<Object>();
        
        Map<String, Object> attrRecord = new Map<String, Object>();
        attrRecord.put('Name', 'Nested Attribute Category');
        attrRecord.put('Id', 'attrCat1');
        
        Map<String, Object> productAttributes = new Map<String, Object>();
        productAttributes.put('totalSize', 1);
        List<Object> attrList = new List<Object>();
        
        Map<String, Object> attr = new Map<String, Object>();
        attr.put('label', 'Test Label');
        attr.put('userValues', 'Test Value');
        attr.put('extraKey', 'Should be removed');
        attrList.add(attr);
        
        productAttributes.put('records', attrList);
        attrRecord.put('productAttributes', productAttributes);
        attrRecords.add(attrRecord);
        
        attrCategories.put('records', attrRecords);
        regularRecord.put('attributeCategories', attrCategories);
        records.add(regularRecord);
        
        childProducts.put('records', records);
        product1.put('childProducts', childProducts);
        product1.put('attributeCategories', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        
        products.add(product1);
        inputMap.put('products', products);
        
        return inputMap;
    }
    
    private static Map<String, Object> createTestInputMapMultipleGroups() {
        Map<String, Object> inputMap = new Map<String, Object>();
        List<Object> products = new List<Object>();
        
        Map<String, Object> product1 = new Map<String, Object>();
        product1.put('ProductCode', 'Product 1');
        product1.put('Name', 'Product Name 1');
        product1.put('Type__c', 'Type1');
        product1.put('Price', 100.00);
        product1.put('childProducts', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        product1.put('attributeCategories', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        products.add(product1);
        
        Map<String, Object> product2 = new Map<String, Object>();
        product2.put('ProductCode', 'Product 2');
        product2.put('Name', 'Product Name 2');
        product2.put('Type__c', 'Type2');
        product2.put('Price', 200.00);
        product2.put('childProducts', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        product2.put('attributeCategories', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        products.add(product2);
        
        Map<String, Object> product3 = new Map<String, Object>();
        product3.put('ProductCode', 'Product 3');
        product3.put('Name', 'Product Name 3');
        product3.put('Type__c', 'Type3');
        product3.put('Price', 300.00);
        product3.put('childProducts', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        product3.put('attributeCategories', new Map<String, Object>{'totalSize' => 0, 'records' => new List<Object>()});
        products.add(product3);
        
        inputMap.put('products', products);
        
        return inputMap;
    }
    
    private static Map<String, Object> createTestInputMapWithExtraKeys() {
        Map<String, Object> inputMap = createTestInputMap();
        List<Object> products = (List<Object>)inputMap.get('products');
        Map<String, Object> product = (Map<String, Object>)products[0];
        
        product.put('ExtraKey1', 'Value1');
        product.put('ExtraKey2', 'Value2');
        product.put('Id', 'recordId');
        product.put('CreatedDate', Date.today());
        
        return inputMap;
    }
}