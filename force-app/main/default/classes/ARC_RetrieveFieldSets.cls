global without sharing class ARC_RetrieveFieldSets implements vlocity_ins.VlocityOpenInterface {
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        if (methodName.equalsIgnoreCase('retrieveFields')){
            retrieveFields(outMap, inputMap);
        }
        return true;
    }

    public static void retrieveFields(Map<String,Object> outMap, Map<String,Object> inputMap) {
        
        Map<String,Schema.FieldSet> fieldsets = Schema.SObjectType.vlocity_ins__GroupCensusMember__c.fieldSets.getMap();
        System.debug('fielset ' + fieldsets.values());
        for(Schema.FieldSet fl : fieldsets.values()) {
            system.debug(fl.getLabel());
        }
        
        for(Schema.FieldSet fieldset : fieldsets.values()){
            
            List<String> allFields = new List<String>();
            List<String> requiredFields = new List<String>();
            
            List<Schema.FieldSetMember> fields;
            fields = fieldset.getFields();
            
            for(Schema.FieldSetMember field : fields){
                
                String fieldName = field.getFieldPath();
                if(field.getRequired()){
                    requiredFields.add(fieldName);
                }
                allFields.add(fieldName);
            }

            if(inputMap.get('NoMedicalPlans') == true ) {
                for (Integer i = (requiredFields.size()-1); i >= 0; i--){
                    String s = requiredFields[i];
                    if(s.contains('Medical')){
                        requiredFields.remove(i);
                    }
                }
            }

            if(inputMap.get('NoVisionPlans') == true ) {
                for (Integer i = (requiredFields.size()-1); i >= 0; i--){
                    String s = requiredFields[i];
                    if(s.contains('Vision')){
                        requiredFields.remove(i);
                    }
                }
            }

            if(inputMap.get('NoDentalPlans') == true ) {
                for (Integer i = (requiredFields.size()-1); i >= 0; i--){
                    String s = requiredFields[i];
                    if(s.contains('Dental')){
                        requiredFields.remove(i);
                    }
                }
            }
           
            // if(inputMap.get('QuoteProcess') == 'SmallGroupQuote'){
            //     if(fieldset.getLabel().contains('SGQuotePrimary')){
            //         outMap.put('requiredFieldsPrimary', requiredFields);
            //         outMap.put('visibleFieldsPrimary', allFields);
            //     } 
            //     if(fieldset.getLabel().contains('SGQuoteDependent')){
            //         outMap.put('requiredFieldsDependent', requiredFields);
            //         outMap.put('visibleFieldsDependent', allFields);
            //     }
            // }
            
            // if(inputMap.get('QuoteProcess') == 'SmallGroupEnrollment'){
            //     if(fieldset.getLabel().contains('SGEnrollmentPrimary')){
            //         outMap.put('requiredFieldsPrimary', requiredFields);
            //         outMap.put('visibleFieldsPrimary', allFields);
            //     }
            //     if(fieldset.getLabel().contains('SGEnrollmentDependent')){
            //         outMap.put('requiredFieldsDependent', requiredFields);
            //         outMap.put('visibleFieldsDependent', allFields);
            //     }
            // }

            if(inputMap.get('FieldsetType') == 'IFPShop'){
                if(fieldset.getLabel().contains('IFPShopPrimary')){
                    outMap.put('requiredFieldsPrimary', requiredFields);
                    outMap.put('visibleFieldsPrimary', allFields);
                } 
                if(fieldset.getLabel().contains('IFPShopDependent')){
                    outMap.put('requiredFieldsDependent', requiredFields);
                    outMap.put('visibleFieldsDependent', allFields);
                }
            }

                        
            if(inputMap.get('FieldsetType') == 'IFPEnroll'){
                if(fieldset.getLabel().contains('IFPEnrollmentPrimary')){
                    outMap.put('requiredFieldsPrimary', requiredFields);
                    outMap.put('visibleFieldsPrimary', allFields);
                } 
                if(fieldset.getLabel().contains('IFPEnrollmentDependent')){
                    outMap.put('requiredFieldsDependent', requiredFields);
                    outMap.put('visibleFieldsDependent', allFields);
                }
            }

            if(inputMap.get('FieldsetType') == 'IFPProgramChangeAddMember'){
                // if(fieldset.getLabel().contains('IMApplicationPrimary')){
                //     outMap.put('requiredFieldsPrimary', requiredFields);
                //     outMap.put('visibleFieldsPrimary', allFields);
                // } 
                if(fieldset.getLabel().contains('IFPProgramChangeAddMemberDependent')){
                    outMap.put('requiredFieldsDependent', requiredFields);
                    outMap.put('visibleFieldsDependent', allFields);
                }
            }
            
            if(inputMap.get('FieldsetType') == 'IFPProgramChangePlan'){
                if(fieldset.getLabel().contains('IFPProgramChangePlanPrimary')){
                    outMap.put('requiredFieldsPrimary', requiredFields);
                    outMap.put('visibleFieldsPrimary', allFields);
                } 
                if(fieldset.getLabel().contains('IFPProgramChangePlanDependent')){
                    outMap.put('requiredFieldsDependent', requiredFields);
                    outMap.put('visibleFieldsDependent', allFields);
                }
            }

            if(inputMap.get('FieldsetType') == 'IFPProgramChangeMultiple'){
                if(fieldset.getLabel().contains('IFPProgramChangeMultiPrimary')){
                    outMap.put('requiredFieldsPrimary', requiredFields);
                    outMap.put('visibleFieldsPrimary', allFields);
                } 
                if(fieldset.getLabel().contains('IFPProgramChangeMultiDependents')){
                    outMap.put('requiredFieldsDependent', requiredFields);
                    outMap.put('visibleFieldsDependent', allFields);
                }
            }
        }
        
    }}