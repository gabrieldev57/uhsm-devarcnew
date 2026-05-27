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
        // Extract tier factor from the first product BEFORE mutating/cleaning the input structure
        Decimal tierFactor = extractTierFactorFromProducts(products);
        if (products == null) {
            outputMap.put('tierFactorValue', tierFactor);
            outputMap.put('products', new List<Object>());
            return;
        }
        clearProductsJSON(products);
        Map<String, List<Object>> groupedProducts = new Map<String, List<Object>>();
        for (Object productObj : products) {
            Map<String, Object> product = (Map<String, Object>)productObj;
            String productCode = (String)product.get('ProductCode');
            Map<String, Object> productGroupInfo = (Map<String, Object>)groupMap.get(productCode);
            if (productGroupInfo == null) {
                // Default a safe group metadata for unmapped/legacy products
                Map<String, Object> defaultInfo = new Map<String, Object>();
                defaultInfo.put('groupName', 'Legacy');
                defaultInfo.put('uniqueAttributes', null);
                defaultInfo.put('description', null);
                defaultInfo.put('hiddenAttributes', null);
                groupMap.put(productCode, defaultInfo);
                productGroupInfo = defaultInfo;
            }
            String groupName = (String)productGroupInfo.get('groupName');
            if (groupName == null) {
                groupName = 'Legacy';
            }
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
            Map<String, Object> info = (Map<String, Object>)groupMap.get(productCode);
            groupProducts.put('uniqueAttributes', info == null ? null : info.get('uniqueAttributes'));
            groupProducts.put('description', info == null ? null : info.get('description'));
            groupProducts.put('hiddenAttributes', info == null ? null : info.get('hiddenAttributes'));
            result.add(groupProducts);
        }
        System.debug('result: ' + result);

        outputMap.put('tierFactorValue', tierFactor);
        outputMap.put('products', result);
    }

    private static void clearProductsJSON(List<Object> products) {
        if (products == null) {
            return;
        }
        Set<String> keysToKeep = new Set<String>{
            'childProducts', 'attributeCategories', 'Price',
            'Type__c', 'ProductCode', 'Name', 'productId'
        };
        for (Object productObj : products) {
            Map<String, Object> product = (Map<String, Object>)productObj;
            retainKeys(product, keysToKeep);
            Object childProducts = product.get('childProducts');
            if (childProducts != null) {
                clearChildProductsJSON(childProducts);
            }
            Object attributeCategories = product.get('attributeCategories');
            if (attributeCategories != null) {
                clearAttributeCategoriesJSON(attributeCategories);
            }
        }
    }

    private static void clearChildProductsJSON(Object childProductsJson) {
        if (childProductsJson == null) {
            return;
        }
        Map<String, Object> childProducts = (Map<String, Object>)childProductsJson;
        if (childProducts == null) {
            return;
        }
        childProducts.remove('totalSize');
        List<Object> records = (List<Object>)childProducts.get('records');
        if (records == null) {
            return;
        }
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
            if (attrCategories == null) {
                continue;
            }
            attrCategories.remove('totalSize');
            List<Object> attrRecords = (List<Object>)attrCategories.get('records');
            if (attrRecords == null) {
                continue;
            }
            for (Object attrRecordObj : attrRecords) {
                Map<String, Object> attrRecord = (Map<String, Object>)attrRecordObj;
                retainKeys(attrRecord, new Set<String>{ 'Name', 'productAttributes' });
                Map<String, Object> productAttributes = (Map<String, Object>)attrRecord.get('productAttributes');
                if (productAttributes == null) {
                    continue;
                }
                productAttributes.remove('totalSize');
                List<Object> attrList = (List<Object>)productAttributes.get('records');
                if (attrList == null) {
                    continue;
                }
                for (Object attrObj : attrList) {
                    Map<String, Object> attr = (Map<String, Object>)attrObj;
                    retainKeys(attr, new Set<String>{ 'label', 'userValues' });
                }
            }
        }
    }

    private static void clearAttributeCategoriesJSON(Object attributeCategoriesJson) {
        if (attributeCategoriesJson == null) {
            return;
        }
        Map<String, Object> attributeCategories = (Map<String, Object>)attributeCategoriesJson;
        if (attributeCategories == null) {
            return;
        }
        attributeCategories.remove('totalSize');
        List<Object> records = (List<Object>)attributeCategories.get('records');
        if (records == null) {
            return;
        }
        for (Object recordObj : records) {
            Map<String, Object> record = (Map<String, Object>)recordObj;
            retainKeys(record, new Set<String>{ 'Name', 'productAttributes' });
            Map<String, Object> productAttr = (Map<String, Object>)record.get('productAttributes');
            if (productAttr == null) {
                continue;
            }
            productAttr.remove('totalSize');
            List<Object> attrRecords = (List<Object>)productAttr.get('records');
            if (attrRecords == null) {
                continue;
            }
            for (Object attrRecordObj : attrRecords) {
                Map<String, Object> attrRecord = (Map<String, Object>)attrRecordObj;
                retainKeys(attrRecord, new Set<String>{ 'label', 'userValues' });
            }
        }
    }

    private static Decimal extractTierFactorFromProducts(List<Object> products) {
        if (products == null || products.isEmpty()) {
            return null;
        }
        Map<String, Object> first = (Map<String, Object>)products[0];

        // 1) Preferred: RawPriceData[0].calculationResults[0].ARC_SmallGroupTierMultiplier__TierFactor
        List<Object> raw = (List<Object>)first.get('RawPriceData');
        if (raw != null && !raw.isEmpty()) {
            Map<String, Object> raw0 = (Map<String, Object>)raw[0];
            List<Object> calc = (List<Object>)raw0.get('calculationResults');
            if (calc != null && !calc.isEmpty()) {
                Map<String, Object> calc0 = (Map<String, Object>)calc[0];
                Decimal fromRaw = coerceDecimal(calc0.get('ARC_SmallGroupTierMultiplier__TierFactor'));
                if (fromRaw != null) {
                    return fromRaw;
                }
            }
        }

        // 2) Fallback: CalculatedPriceData.detailPrice[0].ARC_SmallGroupTierMultiplier__TierFactor
        Map<String, Object> calcData = (Map<String, Object>)first.get('CalculatedPriceData');
        if (calcData != null) {
            List<Object> detail = (List<Object>)calcData.get('detailPrice');
            if (detail != null && !detail.isEmpty()) {
                Map<String, Object> detail0 = (Map<String, Object>)detail[0];
                Decimal fromDetail = coerceDecimal(detail0.get('ARC_SmallGroupTierMultiplier__TierFactor'));
                if (fromDetail != null) {
                    return fromDetail;
                }
            }
            // 3) Fallback: CalculatedPriceData.ARC_SmallGroupTierMultiplier__TierFactor
            Decimal fromCalcTop = coerceDecimal(calcData.get('ARC_SmallGroupTierMultiplier__TierFactor'));
            if (fromCalcTop != null) {
                return fromCalcTop;
            }
        }

        return null;
    }

    private static Decimal coerceDecimal(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return Decimal.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return null;
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