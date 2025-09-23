global without sharing class ARC_GetProductsHelper implements vlocity_ins.VlocityOpenInterface {
    public Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        if (methodName == 'transformGetProducts') {
            transformGetProducts(inputMap, outputMap);
        }
        return true;
    }

    public static void transformGetProducts(Map<String, Object> inputMap, Map<String, Object> outputMap) {
        System.debug('entra');
        Map<String, Object> productsByGroup = new Map<String, Object>();
        ARC_PlanGroupMetadata.getGroups(productsByGroup);
        System.debug('productsByGroup: ' + productsByGroup);
        Map<String, Object> groupMap = new Map<String, Object>();
        for (Object planGroupObj : (List<Object>)productsByGroup.get('groupMaps')) {
            Map<String, Object> planGroupMap = (Map<String, Object>)planGroupObj;
            for (String productCode : (List<String>)planGroupMap.get('products')) {
                Map<String, Object> groupInfo = new Map<String, Object>();
                groupInfo.put('groupName', planGroupMap.get('groupName'));
                groupInfo.put('uniqueAttributes', planGroupMap.get('uniqueAttributes'));
                groupInfo.put('description', planGroupMap.get('description'));
                groupInfo.put('hiddenAttributes', planGroupMap.get('hiddenAttributes'));
                groupMap.put(productCode, groupInfo);
            }
        }
        System.debug('groupMap: ' + groupMap);
        List<Object> products = (List<Object>)inputMap.get('products');
        clearProductsJSON(products);
        Map<String, List<Object>> groupedProducts = new Map<String, List<Object>>();
        for (Object productObj : products) {
            Map<String, Object> product = (Map<String, Object>)productObj;
            String productCode = (String)product.get('ProductCode');
            String groupName = (String)((Map<String, Object>)groupMap.get(productCode)).get('groupName');
            if (!groupedProducts.containsKey(groupName)) {
                groupedProducts.put(groupName, new List<Object>());
            }
            groupedProducts.get(groupName).add(product);
        }
        System.debug('groupedProducts: ' + groupedProducts);
        List<Object> result = new List<Object>();
        for (String groupName : groupedProducts.keySet()) {
            Map<String, Object> groupProducts = new Map<String, Object>();
            List<Object> productsInGroup = groupedProducts.get(groupName);
            String productCode = (String)((Map<String, Object>)productsInGroup[0]).get('ProductCode');
            groupProducts.put('groupName', groupName);
            groupProducts.put('products', groupedProducts.get(groupName));
            groupProducts.put('uniqueAttributes', ((Map<String, Object>)groupMap.get(productCode)).get('uniqueAttributes'));
            groupProducts.put('description', ((Map<String, Object>)groupMap.get(productCode)).get('description'));
            groupProducts.put('hiddenAttributes', ((Map<String, Object>)groupMap.get(productCode)).get('hiddenAttributes'));
            result.add(groupProducts);
        }
        System.debug('result: ' + result);
        outputMap.put('products', result);
    }

    private static void clearProductsJSON(List<Object> products) {
        Set<String> keysToKeep = new Set<String>{
            'childProducts', 'attributeCategories', 'Price',
            'Type__c', 'ProductCode', 'Name', 'productId'
        };
        for (Object productObj : products) {
            Map<String, Object> product = (Map<String, Object>)productObj;
            retainKeys(product, keysToKeep);
            Object childProducts = product.get('childProducts');
            clearChildProductsJSON(childProducts);
            Object attributeCategories = product.get('attributeCategories');
            clearAttributeCategoriesJSON(attributeCategories);
        }
    }

    private static void clearChildProductsJSON(Object childProductsJson) {
        Map<String, Object> childProducts = (Map<String, Object>)childProductsJson;
        childProducts.remove('totalSize');
        List<Object> records = (List<Object>)childProducts.get('records');
        for (Integer i = records.size() - 1; i >= 0; i--) {
            Map<String, Object> record = (Map<String, Object>)records.get(i);
            if (record.containsKey('Name') && String.valueOf(record.get('Name')) == 'Census') {
                records.remove(i);
                break;
            }
        }
        for (Object recordObj : records) {
            Map<String, Object> record = (Map<String, Object>)recordObj;
            retainKeys(record, new Set<String>{ 'Name', 'attributeCategories' });
            Map<String, Object> attrCategories = (Map<String, Object>)record.get('attributeCategories');
            attrCategories.remove('totalSize');
            List<Object> attrRecords = (List<Object>)attrCategories.get('records');
            for (Object attrRecordObj : attrRecords) {
                Map<String, Object> attrRecord = (Map<String, Object>)attrRecordObj;
                retainKeys(attrRecord, new Set<String>{ 'Name', 'productAttributes' });
                Map<String, Object> productAttributes = (Map<String, Object>)attrRecord.get('productAttributes');
                productAttributes.remove('totalSize');
                List<Object> attrList = (List<Object>)productAttributes.get('records');
                for (Object attrObj : attrList) {
                    Map<String, Object> attr = (Map<String, Object>)attrObj;
                    retainKeys(attr, new Set<String>{ 'label', 'userValues' });
                }
            }
        }
    }

    private static void clearAttributeCategoriesJSON(Object attributeCategoriesJson) {
        Map<String, Object> attributeCategories = (Map<String, Object>)attributeCategoriesJson;
        attributeCategories.remove('totalSize');
        List<Object> records = (List<Object>)attributeCategories.get('records');
        for (Object recordObj : records) {
            Map<String, Object> record = (Map<String, Object>)recordObj;
            retainKeys(record, new Set<String>{ 'Name', 'productAttributes' });
            Map<String, Object> productAttr = (Map<String, Object>)record.get('productAttributes');
            productAttr.remove('totalSize');
            List<Object> attrRecords = (List<Object>)productAttr.get('records');
            for (Object attrRecordObj : attrRecords) {
                Map<String, Object> attrRecord = (Map<String, Object>)attrRecordObj;
                retainKeys(attrRecord, new Set<String>{ 'label', 'userValues' });
            }
        }
    }

    private static void retainKeys(Map<String, Object> jsonMap, Set<String> keysToKeep) {
        List<String> keysToRemove = new List<String>();
        for (String key : jsonMap.keySet()) {
            if (!keysToKeep.contains(key)) {
                keysToRemove.add(key);
            }
        }
        for (String key : keysToRemove) {
            jsonMap.remove(key);
        }
    }
}