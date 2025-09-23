global without sharing class ClassDePruebaFranCaliaba implements vlocity_ins.VlocityOpenInterface{
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        switch on methodName {
            when 'TRANSFORM_ChooseProductSelectionData'          { TRANSFORM_ChooseProductSelectionData(inputMap, outputMap, options); }
            when else                                            { throw new AuraHandledException('Unknown method: ' + methodName); }
        }
        return true;
    }

    public static void TRANSFORM_ChooseProductSelectionData(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        List<Object> selectedProducts;
        List<Object> oldProducts;

        if (inputMap.get('selectedProducts') instanceof List<Object>) {
            selectedProducts = (List<Object>)inputMap.get('selectedProducts');
        } else if (inputMap.get('oldProducts') instanceof List<Object>){
            oldProducts = (List<Object>)inputMap.get('oldProducts');
        }

        List<Object> userInputs = (List<Object>)inputMap.get('userInputs'); // Falta filtrar los removed members
        Boolean FRML_DisplayChooseProductSelectionStep = (Boolean)inputMap.get('FRML_DisplayChooseProductSelectionStep');

        if (FRML_DisplayChooseProductSelectionStep == true) {
            List<Map<String,Object>> member_list = new List<Map<String,Object>>();
            Boolean shareSMART = true;
            Boolean shareAIDD = true;
            String lastProductSmart_ContractLineItemId;
            String lastProductAidd_ContractLineItemId;
            Map<String, Object> primary_information = new Map<String, Object>{
                'memberId' => null,
                'smart' => new Map<String,Object>{'id' => null, 'name' => null},
                'aidd' => new Map<String,Object>{'id' => null, 'name' => null}
            };
            Map<String, Object> spouse_information = new Map<String, Object>{
                'memberId' => null,
                'smart' => new Map<String,Object>{'id' => null, 'name' => null},
                'aidd' => new Map<String,Object>{'id' => null, 'name' => null}
            };

            for (Object user_input_object : userInputs) {
                Map<String,Object> user_input = (Map<String,Object>)user_input_object;
                String member_relationship = (String)user_input.get('RF_Census.CM_Relationship');
                if (member_relationship == 'Primary') primary_information.put('memberId', user_input.get('Id'));
                if (member_relationship == 'Spouse') spouse_information.put('memberId', user_input.get('Id'));

                Map<String, Object> medical_product = new Map<String, Object>{'value' => null, 'name' => null};
                Map<String, Object> smart_product = new Map<String, Object>{
                    'value' => null,
                    'name' => null,
                    'options' => new List<Map<String,Object>>{
                        new Map<String,Object>{'label' => '-', 'value' => null, 'selected' => true},
                        new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false}
                    }
                };
                Map<String, Object> aidd_product = new Map<String, Object>{
                    'value' => null,
                    'name' => null,
                    'options' => new List<Map<String,Object>>{
                        new Map<String,Object>{'label' => '-', 'value' => null, 'selected' => true},
                        new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false}
                    }
                };

                Map<String, Object> selected_parent = null;

                if (member_relationship == 'Child') {
                    smart_product.put('options', null);
                    aidd_product.put('options', null);

                    selected_parent.put('value', null);
                    if (selectedProducts != null) {
                        selected_parent.put('options', new List<Map<String,Object>>{
                            new Map<String,Object>{'value' => null, 'label' => '-', 'selected' => false},
                            new Map<String,Object>{'value' => 'None', 'label' => 'None', 'selected' => false}
                        });
                    } else if (oldProducts != null){
                        selected_parent.put('value', null);
                        selected_parent.put('options', new List<Map<String,Object>>{});
                    }

                    ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'value' => primary_information.get('memberId'), 'label' => 'Primary Program', 'selected' => false});
                    ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'value' => spouse_information.get('memberId'), 'label' => 'Spouse Program', 'selected' => false});
                }

                List<String> ancillary_product_list = new List<String>();

                Map<String, Object> member = new Map<String, Object>{
                    'id' => (String)user_input.get('Id'),
                    'name' => (String)user_input.get('RF_Census.CM_FirstName') + ' ' + (String)user_input.get('RF_Census.CM_LastName'),
                    'relationship' => member_relationship,
                    'isChild' => member_relationship == 'Child',
                    'medicalProduct' => medical_product,
                    'smartProduct' => smart_product,
                    'aiddProduct' => aidd_product,
                    'selectedParent' => selected_parent,
                    'ancillaryProductsToString' => ''
                };

                if(selectedProducts != null){
                    for (Object product_object : selectedProducts) {
                        Map<String,Object> product = (Map<String,Object>)product_object;
                        String productType = (String)product.get('Type__c');
                        String productSubType = (String)product.get('SubType__c');

                        if (productType == 'Medical') {
                            medical_product.put('name', (String)product.get('Name'));
                            medical_product.put('value', (String)product.get('productId'));
                        }
                        
                        else if (productSubType == 'Smart'){
                            ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => false});
                        }
                        
                        else if (productSubType == 'Aidd'){
                            ((List<Map<String,Object>>)aidd_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => false});
                        }
                    }
                } else if (oldProducts != null) { // El producto seleccionado son los que tienen ya c/u userinputs
                    for (Object product_object : oldProducts) {
                        Map<String,Object> product = (Map<String,Object>)product_object;
                        String productType = (String)product.get('Type__c');
                        String productSubType = (String)product.get('SubType__c');
                        

                        if (productSubType == 'Smart' && product.get('Id') != lastProductSmart_ContractLineItemId) {
                            shareSMART = false;
                        } else if (productSubType == 'Aidd' && product.get('Id') != lastProductAidd_ContractLineItemId) {
                            shareAIDD = false;
                        }

                        Boolean member_has_product = false;

                        for (Object census_member_object : (List<Object>)product.get('census_members')) {
                            Map<String,Object> census_member = (Map<String,Object>)census_member_object;

                            if ((String)user_input.get('Id') == (String)census_member.get('Id')) {
                                member_has_product = true;
                            }
                        }
                        
                        if (member_has_product == true) {
                            if (member_relationship == 'Primary') {
                                if (productType == 'Medical') {
                                    medical_product.put('name', (String)product.get('Name'));
                                    medical_product.put('value', (String)product.get('productId'));
                                } else if (productSubType == 'Smart'){
                                    ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => true});
                                    smart_product.put('name', (String)product.get('Name'));
                                    smart_product.put('value', (String)product.get('productId'));
                                    primary_information.put('memberId', user_input.get('Id'));
                                    ((Map<String,Object>)primary_information.get('smart')).put('id', product.get('productId'));
                                    ((Map<String,Object>)primary_information.get('smart')).put('name', product.get('Name'));
                                } else if (productSubType == 'Aidd'){
                                    ((List<Map<String,Object>>)aidd_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => true});
                                    aidd_product.put('name', (String)product.get('Name'));
                                    aidd_product.put('value', (String)product.get('productId'));
                                    primary_information.put('memberId', user_input.get('Id'));
                                    ((Map<String,Object>)primary_information.get('aidd')).put('id', product.get('productId'));
                                    ((Map<String,Object>)primary_information.get('aidd')).put('name', product.get('Name'));
                                }
                            } else if (member_relationship == 'Spouse'){
                                if (productType == 'Medical') {
                                    medical_product.put('name', (String)product.get('Name'));
                                    medical_product.put('value', (String)product.get('productId'));
                                } else if (productSubType == 'Smart'){
                                    ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => true});
                                    smart_product.put('name', (String)product.get('Name'));
                                    smart_product.put('value', (String)product.get('productId'));
                                    spouse_information.put('memberId', user_input.get('Id'));
                                    ((Map<String,Object>)spouse_information.get('smart')).put('id', product.get('productId'));
                                    ((Map<String,Object>)spouse_information.get('smart')).put('name', product.get('Name'));
                                } else if (productSubType == 'Aidd'){
                                    ((List<Map<String,Object>>)aidd_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => true});
                                    aidd_product.put('name', (String)product.get('Name'));
                                    aidd_product.put('value', (String)product.get('productId'));
                                    spouse_information.put('memberId', user_input.get('Id'));
                                    ((Map<String,Object>)spouse_information.get('aidd')).put('id', product.get('productId'));
                                    ((Map<String,Object>)spouse_information.get('aidd')).put('name', product.get('Name'));
                                }
                            } else if(member_relationship == 'Child') {

                                if (productType == 'Medical') {
                                    medical_product.put('name', (String)product.get('Name'));
                                    medical_product.put('value', (String)product.get('productId'));
                                }
                                
                                else if (productSubType == 'Smart'){
                                    if ((String)product.get('productId') == ((Map<String,Object>)primary_information.get('smart')).get('id')) {
                                        selected_parent.put('value', primary_information.get('memberId'));
                                        ancillary_product_list.add((String)product.get('Name'));
                                        ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Primary Program', 'value' => primary_information.get('memberId'), 'selected' => true});
                                        smart_product.put('name', (String)product.get('Name'));
                                        smart_product.put('value', (String)product.get('productId'));
                                    } else if ((String)primary_information.get('memberId') != null) {
                                        ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Primary Program', 'value' => primary_information.get('memberId'), 'selected' => false});
                                    }
                                    
                                    if ((String)product.get('productId') == ((Map<String,Object>)spouse_information.get('smart')).get('id')){
                                        selected_parent.put('value', spouse_information.get('memberId'));
                                        ancillary_product_list.add((String)product.get('Name'));
                                        ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Spouse Program', 'value' => spouse_information.get('memberId'), 'selected' => true});
                                        smart_product.put('name', (String)product.get('Name'));
                                        smart_product.put('value', (String)product.get('productId'));
                                    } else if ((String)spouse_information.get('memberId') != null) {
                                        ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Spouse Program', 'value' => spouse_information.get('memberId'), 'selected' => false});
                                    }
                                }
                                
                                else if (productSubType == 'Aidd'){
                                    if (product.get('productId') == ((Map<String,Object>)primary_information.get('aidd')).get('id')) {
                                        selected_parent.put('value', primary_information.get('memberId'));
                                        ancillary_product_list.add((String)product.get('Name'));
                                        ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Primary Program', 'value' => primary_information.get('memberId'), 'selected' => true});
                                        aidd_product.put('name', (String)product.get('Name'));
                                        aidd_product.put('value', (String)product.get('productId'));
                                    } else if ((String)primary_information.get('memberId') == null) {
                                        ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Primary Program', 'value' => primary_information.get('memberId'), 'selected' => false});
                                    }
                                    
                                    if (product.get('productId') == ((Map<String,Object>)spouse_information.get('aidd')).get('id')){
                                        selected_parent.put('value', spouse_information.get('memberId'));
                                        ancillary_product_list.add((String)product.get('Name'));
                                        ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Spouse Program', 'value' => spouse_information.get('memberId'), 'selected' => true});
                                        aidd_product.put('name', (String)product.get('Name'));
                                        aidd_product.put('value', (String)product.get('productId'));
                                    } else if ((String)spouse_information.get('memberId') != null) {
                                        ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Spouse Program', 'value' => spouse_information.get('memberId'), 'selected' => false});
                                    }
                                }
                            }

                        } else if (member_has_product == false) {
                            if (member_relationship == 'Primary' || member_relationship == 'Spouse') {
                                if (productSubType == 'Smart'){
                                    ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => false});
                                } else if (productSubType == 'Aidd'){
                                    ((List<Map<String,Object>>)aidd_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => false});
                                }
                            }
                        }

                        if (productSubType == 'Smart') {
                            lastProductSmart_ContractLineItemId = (String)product.get('Id');
                        } else if (productSubType == 'Aidd') {
                            lastProductAidd_ContractLineItemId = (String)product.get('Id');
                        }
                    }

                    if ((String)smart_product.get('value') == null) {
                        smart_product.put('value', 'None');
                        ((List<Map<String,Object>>)smart_product.get('options')).add(0, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => true});
                    }

                    if ((String)aidd_product.get('value') == null) {
                        smart_product.put('value', 'None');
                        ((List<Map<String,Object>>)aidd_product.get('options')).add(0, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => true});
                    }
                    member.put('ancillaryProductsToString', String.join(ancillary_product_list, ', '));
                }
                member_list.add(member);
            }

            outputMap.put('LWC_ChooseProductSelectionInput', new Map<String,Object>{'members' => member_list, 'shareSMART' => shareSMART, 'shareAIDD' => shareAIDD});

        } else if (FRML_DisplayChooseProductSelectionStep == false) { // OK
            List<Map<String,Object>> products_list = new List<Map<String,Object>>();

            List<Object> products_to_process = selectedProducts != null? selectedProducts : oldProducts;
            if (products_to_process != null) {
                for (Object product_object : products_to_process) {
                    Map<String,Object> product = (Map<String,Object>)product_object;
                    Map<String, Object> product_map = new Map<String, Object>{'selectedProduct' => new Map<String,Object>{'Id' => (String)product.get('productId')}, 'userInputs' => userInputs};
                    products_list.add(product_map);
                }
            }
            outputMap.put('LWC_ChooseProductSelectionOutput', products_list);
        }
    }
}