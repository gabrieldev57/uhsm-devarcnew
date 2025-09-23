global without sharing class ARC_PCOSInstanceManager implements vlocity_ins.VlocityOpenInterface{
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'closePreviousInstances') {
            closePreviousInstances(inputMap, outputMap);
        }
        return true;       
    }

    public void closePreviousInstances(Map<String,Object> inputMap, Map<String,Object> outputMap) {
        try {
            List<vlocity_ins__OmniScriptInstance__c> instancesToClose = [SELECT Id, vlocity_ins__Status__c FROM vlocity_ins__OmniScriptInstance__c WHERE vlocity_ins__Status__c != 'Completed' AND vlocity_ins__ObjectId__c = :String.valueOf(inputMap.get('ContextId'))];
            for (vlocity_ins__OmniScriptInstance__c instance : instancesToClose) {
                instance.vlocity_ins__Status__c = 'Completed';
            }
            update instancesToClose;
        }
        catch (Exception e) {
            System.debug('Exception closing previous instances: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
}