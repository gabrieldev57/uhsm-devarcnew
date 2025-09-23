global without sharing class ARC_DeleteContractLineItemsGuestUsers implements vlocity_ins.VlocityOpenInterface {
    
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'deleteRecords') {
            deleteRecords(inputMap, outputMap, options);
        }
        return true;
    }
    
    public static void deleteRecords(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        
        
        Boolean success;
        Object tempList;
        String error;
        String a;
        Id CLItem;
        try {
            tempList = (List<Object>)inputMap.get('ContractLineItemsIds');
        } catch (System.TypeException e) {
            CLItem = (Id)inputMap.get('ContractLineItemsIds');
            error = e.getMessage();
            outputMap.put('error delete: ', e.getMessage());
        }

        Set<Id> SetIds = new Set<Id>();

        if (error == null) {
            a = 'List of plans';
            for (Object conId : (List<Object>)inputMap.get('ContractLineItemsIds')) {
                SetIds.add((String)conId);
            }
            List<vlocity_ins__ContractLineItem__c> CLIToDelete = [SELECT Id, Name, vlocity_ins__ContractId__c FROM vlocity_ins__ContractLineItem__c WHERE Id IN :SetIds];

            try {
                delete CLIToDelete;
                success = true;
            } catch (DmlException e) {
                System.debug(e);
                success = false;
            }
        } else {
            a = 'Only one plan';

            vlocity_ins__ContractLineItem__c CLItemToDelete = [SELECT Id, Name, vlocity_ins__ContractId__c FROM vlocity_ins__ContractLineItem__c WHERE Id =: CLItem];
            try {
                delete CLItemToDelete;
                success = true;
            } catch (System.TypeException e) {
                System.debug(e);
                success = false;
            }
        }

        outputMap.put('Lista', a);
        outputMap.put('Success', success);
        outputMap.put('CLItem', CLItem);
        outputMap.put('tempList', tempList);
    }
}