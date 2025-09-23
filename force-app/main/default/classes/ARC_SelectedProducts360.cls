global without sharing class ARC_SelectedProducts360 implements vlocity_ins.VlocityOpenInterface {
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'getProductsDetails') {
            getProductsDetails(inputMap, outputMap,options);
        }            
        return true;
    }
    public static void getProductsDetails(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
        
        List<Object> CLIs = (List<Object>)inputMap.get('CLIs');
        List<Product2> products = new List<Product2>();
        List<vlocity_ins__GroupCensusMemberPlan__c> memberPlans = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        List<Map<String,Object>> ratedProducts = new List<Map<String,Object>>();
        List<Map<String,Object>> productList = new List<Map<String,Object>>();

        List<Object> attributes = (List<Object>)inputMap.get('Attributes');
        


        Set<Id> CLIsIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();

        Map<Id, List<Object>> prod_CLIs = new Map<Id, List<Object>>();

        for (Object cli : CLIs) {
            List<Object> CLIsPerProduct = new List<Object>();
            CLIsIds.add((Id)(((Map<String,Object>)cli).get('Id')));
            productIds.add((Id)(((Map<String,Object>)cli).get('productId')));
            if (prod_CLIs.get((Id)(((Map<String,Object>)cli).get('productId')))!= null) {
                CLIsPerProduct = prod_CLIs.get((Id)(((Map<String,Object>)cli).get('productId')));
            }
            CLIsPerProduct.add(cli);
            prod_CLIs.put((Id)(((Map<String,Object>)cli).get('productId')),CLIsPerProduct);
        }

        Map<Id, Object> prodAttr = new Map<Id, Map<String, Object>>();
        Map<Id, Object> prodChildProds = new Map<Id, Map<String, Object>>();
        if(!Test.isRunningTest()){
        for(Object attr : attributes){
            prodAttr.put((Id)((Map<String,Object>)attr).get('Id'), (Object)((Map<String,Object>)attr).get('attributeCategories'));
            prodChildProds.put((Id)((Map<String,Object>)attr).get('Id'), (Object)((Map<String,Object>)attr).get('childProducts'));
        }
        }

        products = [SELECT Id, ProductCode, Name,vlocity_ins__RecordTypeName__c, vlocity_ins__Type__c,vlocity_ins__SubType__c  FROM Product2 WHERE Id IN :productIds];
        memberPlans = [SELECT Id, vlocity_ins__ContractLineId__c, vlocity_ins__GroupCensusMemberId__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c  FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__ContractLineId__c IN :CLIsIds /*AND vlocity_ins__GroupCensusMemberId__r.ARC_ActiveMember__c=true*/];


        for (Product2 prod : products) {
            for (Object cli : prod_CLIs.get(prod.Id)) {
                Map<String,Object> ratedProduct = new Map<String, Object>();
                Map<String,Object> productListItem = new Map<String, Object>();
                List<Map<String,Object>> userInputs = new List<Map<String,Object>>(); 
                Map<String,Object> selectedProduct = new Map<String,Object>(); 
                ratedProduct.put('Price',(Decimal)(((Map<String,Object>)cli).get('Price')));
                ratedProduct.put('Id',prod.Id);
                ratedProduct.put('ProductCode',prod.ProductCode);
                ratedProduct.put('Name',prod.Name);
                ratedProduct.put('RecordTypeName__c',prod.vlocity_ins__RecordTypeName__c);
                ratedProduct.put('productId',prod.Id);
                ratedProduct.put('SubType__c',prod.vlocity_ins__SubType__c);
                ratedProduct.put('Type__c',prod.vlocity_ins__Type__c);
                selectedProduct.put('Price',(Decimal)(((Map<String,Object>)cli).get('Price')));
                selectedProduct.put('Id',prod.Id);
                selectedProduct.put('ProductCode',prod.ProductCode);
                selectedProduct.put('Name',prod.Name);
                selectedProduct.put('RecordTypeName__c',prod.vlocity_ins__RecordTypeName__c);
                selectedProduct.put('productId',prod.Id);
                selectedProduct.put('SubType__c',prod.vlocity_ins__SubType__c);
                selectedProduct.put('Type__c',prod.vlocity_ins__Type__c);
                selectedProduct.put('attributeCategories', prodAttr.get(prod.Id));
                selectedProduct.put('childProducts', prodChildProds.get(prod.Id));

                ratedProducts.add(ratedProduct);

                for (vlocity_ins__GroupCensusMemberPlan__c memberPlan : memberPlans) {
                    if (memberPlan.vlocity_ins__ContractLineId__c == (Id)(((Map<String,Object>)cli).get('Id'))) {
                        Map<String, Object> userInputsItem = new Map<String, Object>();
                        userInputsItem.put('CensusMemberId', memberPlan.vlocity_ins__GroupCensusMemberId__c);
                        userInputsItem.put('CensusMemberLastName', memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c);
                        userInputsItem.put('CensusMemberFirstName', memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c);
                        userInputsItem.put('FirstName', memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c);
                        userInputsItem.put('LastName', memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c);
                        userInputs.add(userInputsItem);
                    }
                }
                productListItem.put('userInputs', userInputs);
                productListItem.put('selectedProduct', selectedProduct);
                productList.add(productListItem);
            }
        }
        outputMap.put('products', ratedProducts);
        outputMap.put('productList', productList);
    }
}