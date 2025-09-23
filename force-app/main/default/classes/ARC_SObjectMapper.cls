public class ARC_SObjectMapper {

    public static Map<String, String> getGroupCensusMemberMapping() {
        return new Map<String, String>{
            'ARC_HeightFeet__c'                 => 'ARC_HeightFeet__c',
            'ARC_HeightInches__c'               => 'ARC_HeightInches__c',
            'ARC_PhysicalAddressCity__c'        => 'ARC_PhysicalAddressCity__c',
            'ARC_PhysicalAddressState__c'       => 'ARC_PhysicalAddressState__c',
            'ARC_PhysicalAddressStreet__c'      => 'ARC_PhysicalAddressStreet__c',
            'ARC_PhysicalAddressZipCode__c'     => 'ARC_PhysicalAddressZipCode__c',
            'ARC_Smoker__c'                     => 'ARC_Smoker__c',
            'CopyAddressFromPrimary'            => 'ARC_UseParentAddress__c',
            'ARC_Weight__c'                     => 'ARC_Weight__c',
            'vlocity_ins__Birthdate__c'         => 'vlocity_ins__Birthdate__c',
            'CensusId'                          => 'vlocity_ins__CensusId__c',
            'vlocity_ins__Email__c'             => 'vlocity_ins__Email__c',
            'vlocity_ins__LastName__c'          => 'vlocity_ins__LastName__c',
            'vlocity_ins__FirstName__c'         => 'vlocity_ins__FirstName__c',
            'vlocity_ins__Gender__c'            => 'vlocity_ins__Gender__c',
            'vlocity_ins__IsPrimaryMember__c'   => 'vlocity_ins__IsPrimaryMember__c',
            'vlocity_ins__SocialSecurityNumber__c' => 'vlocity_ins__SocialSecurityNumber__c'
        };
    }

    public static List<SObject> mapListToSObjects(List<Map<String, Object>> sourceList, Schema.SObjectType targetType, Map<String, String> fieldMapping) {
        List<SObject> result = new List<SObject>();

        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(targetType.getDescribe().getName()).getDescribe().fields.getMap();

        for (Map<String, Object> source : sourceList) {
            SObject target = targetType.newSObject();

            for (String sourceKey : fieldMapping.keySet()) {
                String targetField = fieldMapping.get(sourceKey);

                if (!source.containsKey(sourceKey) || !fieldMap.containsKey(targetField)) {
                    continue;
                }

                Object rawValue = source.get(sourceKey);
                if (rawValue == null) continue;

                Schema.DisplayType fieldType = fieldMap.get(targetField).getDescribe().getType();
                Object valueToSet;

                try {
                    switch on fieldType {
                        when BOOLEAN {
                            valueToSet = (rawValue instanceof Boolean) ? rawValue : Boolean.valueOf(String.valueOf(rawValue));
                        }
                        when DATE {
                            valueToSet = (rawValue instanceof Date) ? rawValue : Date.valueOf(String.valueOf(rawValue));
                        }
                        when DATETIME {
                            valueToSet = (rawValue instanceof Datetime) ? rawValue : Datetime.valueOf(String.valueOf(rawValue));
                        }
                        when DOUBLE {
                            valueToSet = (rawValue instanceof Decimal) ? rawValue : Decimal.valueOf(String.valueOf(rawValue));
                        }
                        when INTEGER {
                            valueToSet = (rawValue instanceof Integer) ? rawValue : Integer.valueOf(String.valueOf(rawValue));
                        }
                        when STRING, EMAIL, PHONE, TEXTAREA, ID, URL, PICKLIST {
                            valueToSet = String.valueOf(rawValue);
                        }
                        when else {
                            valueToSet = rawValue;
                        }
                    }

                    target.put(targetField, valueToSet);
                } catch (Exception e) {
                    System.debug('⚠️ Error mapping field: ' + targetField + ' with value: ' + rawValue + ' - ' + e.getMessage());
                }
            }

            result.add(target);
        }

        return result;
    }
}