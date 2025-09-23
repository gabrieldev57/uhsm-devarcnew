@isTest
public with sharing class ARC_DeleteContractLineItemsGUT{
    @isTest
    static void DeleteContractItems(){
        List<Contract> contList = ARC_TestUtility.createContracts(1);
        insert contList;
        List <Id> itemsId = new List<Id>();
        vlocity_ins__ContractLineItem__c[] itemToAdd = ARC_TestUtility.createTestContractLineItem(1);
        for(vlocity_ins__ContractLineItem__c cli: itemToAdd){
            cli.vlocity_ins__ContractId__c = contList[0].Id;            
            itemsId.add(cli.Id);
        }
        
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'deleteRecords';
		inputMap.put('ContractLineItemsIds', itemsId);
        
		ARC_DeleteContractLineItemsGuestUsers deleteContractItem = new ARC_DeleteContractLineItemsGuestUsers();
        
        test.startTest();
        deleteContractItem.invokeMethod(methodName, inputMap, outputMap, options);
        test.stopTest();
        
        vlocity_ins__ContractLineItem__c [] afterCliList = [SELECT Id FROM vlocity_ins__ContractLineItem__c];
        System.assertEquals(0, afterCliList.size());
    }
    
    @isTest
    static void DeleteContractItemsError(){
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        List<Contract> contList = ARC_TestUtility.createContracts(1);
        insert contList;
        
        String methodName = 'deleteRecords';
        vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
        cli.vlocity_ins__ContractId__c = contList[0].Id;
        insert cli;
        
		inputMap.put('ContractLineItemsIds', cli.Id);
        
		ARC_DeleteContractLineItemsGuestUsers deleteContractItem = new ARC_DeleteContractLineItemsGuestUsers();
        
		test.startTest();
        deleteContractItem.invokeMethod(methodName, inputMap, outputMap, options);
        test.stopTest();
        
        System.assertEquals('Only one plan', outputMap.get('Lista'));
    }
}