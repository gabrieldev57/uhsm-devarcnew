global without sharing class ARC_ReadPicklistValues implements vlocity_ins.VlocityOpenInterface {

	public Boolean invokeMethod(String methodName, Map <String,Object> inputMap, Map <String,Object> outputMap, Map <String,Object> options) {
  
        if (methodName == 'returnPicklistValuesAsAList') {
            returnPicklistValuesAsAList(inputMap, outputMap);
        }

        return true;
    }

	public static void returnPicklistValuesAsAList(Map <String,Object> inputMap, Map <String,Object> outMap) {
        // Define the object and field names
        String objectName = String.valueOf(inputMap.get('object'));
        String fieldName = String.valueOf(inputMap.get('field'));

        // Get the SObject description
        Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();

        // Get the field description
        Schema.DescribeFieldResult fieldDescribe = objectDescribe.fields.getMap().get(fieldName).getDescribe();


        // Get the picklist values
        List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
    
        List<Map<String,String>> picklistAsList = new List<Map<String,String>>();
        // Iterate through the picklist values
        for (Schema.PicklistEntry picklistEntry : picklistValues) {
            if(picklistEntry.isActive()){
                String picklistLabel = picklistEntry.getLabel();
                String picklistValue = picklistEntry.getValue();

                Map<String, String> picklistEntryAsObject = new Map<String, String>{
                    'label'=>picklistLabel,
                    'value'=>picklistValue
                };

                picklistAsList.add(picklistEntryAsObject);
            }
        }

        outMap.put('response',picklistAsList);

    }

}