@isTest
global with sharing class ARC_CreatePicklistValuesTest {

    @isTest
    public static void getValues(){
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        String methodName = 'PopulatePicklist';
        ARC_CreatePicklistValues className = new ARC_CreatePicklistValues();
            
        Test.startTest();
            className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        
        List<Map<String,String>> maps = (List<Map<String,String>>)outputMap.get('options'); 
        System.assertEquals(9,maps.size());
    }
    
    @isTest
    public static void getValuesTwo(){
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        String methodName = 'PopulatePicklist';
        ARC_CreatePicklistValues className = new ARC_CreatePicklistValues();
            
        Test.startTest();
            className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        
        List<Map<String,String>> maps = (List<Map<String,String>>)outputMap.get('options'); 
        Map<String,String> mapTwo = (Map<String,String>) maps[1];
        Integer currentYear = System.Today().year();
        System.assertEquals(String.valueOf(currentYear+1),mapTwo.get('name'));
    }

}