global with sharing class ARC_PlanGroupMetadata implements vlocity_ins.VlocityOpenInterface {
    
    public List<ARC_PlanGroup__mdt> testPlanGroups = new List<ARC_PlanGroup__mdt>();
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        if (methodName.equalsIgnoreCase('getGroups')){
            getGroups(outMap);
        }
        return true;
    }
    
    public static void getGroups(Map<String,Object> outMap) {
        List<Object> groupMaps = new List<Object>();
        List<ARC_PlanGroup__mdt> planGroups = new List<ARC_PlanGroup__mdt>();
        if (Test.isRunningTest()) {
            planGroups = getTestPlanGroups();
        }else{
            planGroups = [SELECT Label, ARC_Description__c, ARC_Products__c, ARC_UniqueAttributes__c, ARC_ProgramDetailsHiddenAttributes__c FROM ARC_PlanGroup__mdt];
        }
        
        for (ARC_PlanGroup__mdt planGroup : planGroups) {
            Map<String, Object> planGroupMap = new Map<String, Object>();
            if (planGroup.ARC_UniqueAttributes__c == null) {
                planGroup.ARC_UniqueAttributes__c = '';
            }
            if (planGroup.ARC_ProgramDetailsHiddenAttributes__c == null) {
                planGroup.ARC_ProgramDetailsHiddenAttributes__c = '';
            }
            if (planGroup.ARC_Products__c == null) {
                planGroup.ARC_Products__c = '';
            }
            
            
            planGroupMap.put('groupName', planGroup.Label);
            planGroupMap.put('description', planGroup.ARC_Description__c);
            planGroupMap.put('products', planGroup.ARC_Products__c == '' ? new List<Object>() :planGroup.ARC_Products__c.replace('\r', '').split('\n'));
            System.debug('planGroup.ARC_UniqueAttributes__c: ' + planGroup.ARC_UniqueAttributes__c);
            planGroupMap.put('uniqueAttributes', planGroup.ARC_UniqueAttributes__c == '' ? new List<Object>() : planGroup.ARC_UniqueAttributes__c.replace('\r', '').split('\n'));
            planGroupMap.put('hiddenAttributes', planGroup.ARC_ProgramDetailsHiddenAttributes__c == '' ? new List<Object>() : planGroup.ARC_ProgramDetailsHiddenAttributes__c.replace('\r', '').split('\n'));

            groupMaps.add(planGroupMap);
        }

        outMap.put('groupMaps', groupMaps);
    }

    private static List<ARC_PlanGroup__mdt> getTestPlanGroups(){
        ARC_PlanGroup__mdt planGroup1 = new ARC_PlanGroup__mdt(Label='Group 1', ARC_Description__c='Description 1', ARC_Products__c='Product 1\r\nProduct 2', ARC_UniqueAttributes__c='Attribute 1\r\nAttribute 2');
        ARC_PlanGroup__mdt planGroup2 = new ARC_PlanGroup__mdt(Label='Group 2', ARC_Description__c='Description 2', ARC_Products__c='Product 3\r\nProduct 4', ARC_UniqueAttributes__c='Attribute 3\r\nAttribute 4');
        
        return new List<ARC_PlanGroup__mdt>{planGroup1, planGroup2};
    }
}