global without sharing class ARC_GuestUserActions implements vlocity_ins.VlocityOpenInterface {
    
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
       
        Boolean success = true;

        try {
            if (methodName.equals('createUpdateSObject')) {
                createUpdateSObject(inputMap,outputMap);
            }
            if (methodName.equals('readSObject')) {
                readSObject(inputMap,outputMap);
            }
        } catch (Exception e) {
            outputMap.put('Error:', e.getMessage());
            outputMap.put('Line:', e.getLineNumber());
            success = false;
        }

        return success;
    }

    public static void createUpdateSObject(Map<String,Object> inputMap, Map<String,Object> outputMap) { 
        
        String strObjectName = (String)inputMap.get('Object');
        sObject obj = Schema.getGlobalDescribe().get(strObjectName).newSObject();  



        for (String field : inputMap.keySet()) {
            if (field != 'Object') {
                try {
                    String objectName = strObjectName;
                    String fieldName = field;
                    SObjectType r = ((SObject)(Type.forName('Schema.'+objectName).newInstance())).getSObjectType();
                    DescribeSObjectResult d = r.getDescribe();

                    Schema.DisplayType fieldType = d.fields
                                            .getMap()
                                            .get(fieldName)
                                            .getDescribe()
                                            .getType(); 

                    String strType = String.valueOf(fieldType);
                    if (strType == 'DATE') {
                        String newDate = inputMap.get(field).toString();
                        Date effDate = date.valueOf(newDate);
                        obj.put(field, effDate );  
                        
                    }
                    else{            
                        obj.put(field, inputMap.get(field)); 
                    }   
                } catch (Exception e) {
                    outputMap.put('field error','Error: '+e.getMessage());
                }
                
            }     
        }   

        try {
            upsert obj;
            outputMap.put(strObjectName + 'Id', obj.Id);           
        } catch (Exception e) {            
            outputMap.put('result','Error: '+e.getMessage());
        }  
    }

    public static void readSObject(Map<String,Object> inputMap, Map<String,Object> outputMap) { 
        String strObjectName = (String)inputMap.get('Object');      
        String query='SELECT ';
        List<SObject> sObjectRecords = new List<SObject>();
        List<Map<String,Object>> response = new List<Map<String,Object>>();
        Set<String> keySet = new Set<String>();
        System.debug('query1'+ query);
    
        if (inputMap.get('FullQuery') != null) {
            
            System.debug('query posta'+ (String)inputMap.get('FullQuery'));
            query = (String)inputMap.get('FullQuery');

        } else {
            keyset = inputMap.keySet().clone();

            if (inputMap.get('Fields') != null ) {
                query += inputMap.get('Fields');
                String fieldsMap = (String)inputMap.get('Fields');
                List<String> fields = fieldsMap.split(',');
                for (String field : fields) {
                keySet.add(field.deleteWhitespace());
                }
            } else {
                for (String field: keySet) {
                    if (field != 'Object' && field != 'ConditionalExpression' && field != 'Options' && field != 'Fields') {
                        query += inputMap.get(field) + ',';                
                    }
                }
            }
            query = query.removeEnd(',');
            
            if (inputMap.get('ConditionalExpression') != null ) {
                query += ' FROM ' + strObjectName + ' WHERE ' + inputMap.get('ConditionalExpression');
            } else {
                query += ' FROM ' + strObjectName;
            }

            if (inputMap.get('Options') != null ) {
                query += inputMap.get('Options');
            }
        
        }
        sObjectRecords = Database.query(query);
        System.debug('query' + sObjectRecords);
        
        if (sObjectRecords.size() == 1) {
            Map<String,Object> temp = new Map<String,Object>();
                for (String field: keySet) {
                    if (field != 'Object' && field != 'ConditionalExpression' && field != 'Options' && field != 'Fields') {
                       temp.put(field, sObjectRecords[0].get(field));               
                    }
                }
                outputmap.put('response', temp);
        } else{
            for (sObject obj : sObjectRecords) {
                Map<String,Object> temp = new Map<String,Object>();
                for (String field: keySet) {
                    if (field != 'Object' && field != 'ConditionalExpression' && field != 'Options' && field != 'Fields') {
                       temp.put(field, obj.get(field));               
                    }
                }
                response.add(temp);
            }
            outputmap.put('response', response);
        }
        outputmap.put('SObjectRecords', sObjectRecords);
    }
}