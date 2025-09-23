/**
 *  Created By : Nazar
 *  Description : To get history data
 *  Created date : 25 May 2023
 *  Test Class : HistoryHandlerTest
 * */

public class HistoryHandler {

    
    public class SObjectWrapper {
        @AuraEnabled public SObject record;
        @AuraEnabled public String label;
    
       
        public SObjectWrapper(SObject record, String label) {
            this.record = record;
            this.label = label;
        }
    }
    
    @AuraEnabled(cacheable=true)
     public static List<HistoryHandler.SObjectWrapper> getAllHistoryRecords(String recordIds){
        List<SObject> temp = new List<SObject>();
        List<HistoryHandler.SObjectWrapper> tempList = new List<HistoryHandler.SObjectWrapper>();
        List<HistoryHandler.SObjectWrapper> historyList = new List<HistoryHandler.SObjectWrapper>();

         Set<Id> censusIds = new Set<Id>();
  
/**
* Retrieves a list of Account to get PersonContactId
 */
        
        List<Account> getContacts =[select id,PersonContactId 
                                    FROM Account
                                    WHERE id=:recordIds
                                    ORDER BY CreatedDate DESC
                                   ];
        
/**
 * Retrieves a list of Group Census Member records.
 * @return A list of Group Census Member records.
 */
        
        temp = [
                SELECT  id,ParentId,Parent.Name,Field,DataType, OldValue,
            		    CreatedDate, CreatedBy.Name,NewValue 
                        FROM vlocity_ins__GroupCensusMember__History 
                        WHERE ParentId IN (select id from vlocity_ins__GroupCensusMember__c 
                                           where vlocity_ins__ContactId__c=: getContacts[0].PersonContactId)
                        ORDER BY CreatedDate DESC
              ];
        //Assign all data to global History List  
        historyList.addAll(appendLabels(temp, 'vlocity_ins__GroupCensusMember__c'));


// Get Census Record to fetch related contracts 

       List<vlocity_ins__GroupCensus__c> censusList = [
                                                       SELECT Id, ARC_PrimaryAccount__c
                                                       FROM vlocity_ins__GroupCensus__c
                                                       WHERE ARC_PrimaryAccount__c=: recordIds
                                                       ORDER BY CreatedDate DESC
                                                      ];
        
        for(vlocity_ins__GroupCensus__c censuses: censusList){
           censusIds.add(censuses.Id); 
        }
 /**
 * Retrieves a list of ContractHistory records.
 * @return A list of ContractHistory records.
 */
        
        temp = [
                SELECT Id, ContractId, Field, DataType, OldValue, CreatedDate, 
            			CreatedBy.Name, NewValue 
                FROM ContractHistory
                WHERE ContractId IN (select Id from Contract where vlocity_ins__EnrollmentCensusId__c IN: censusIds)
                ORDER BY CreatedDate DESC
               ];
		 //Assign all data to global History List 
         historyList.addAll(appendLabels(temp, 'Contract'));        

        
        
        List<Contract> contractsList = [
                                       SELECT Id 
                                       FROM Contract 
                                       WHERE vlocity_ins__EnrollmentCensusId__c IN: censusIds
                                       ORDER BY CreatedDate DESC
                                      ];
        Set<Id> contractIds = new Set<Id>();
        for(Contract C: contractsList){
           contractIds.add(C.Id); 
        }

 /**
 * Retrieves a list of ChargentOrders__ChargentOrder__History  records.
 * @return A list of ChargentOrders__ChargentOrder__History  records.
 */      

        
        temp = [
                SELECT  id, ParentId, Parent.Name, Field, DataType, OldValue,
            		    CreatedDate, CreatedBy.Name, NewValue 
                        FROM ChargentOrders__ChargentOrder__History 
                        WHERE ParentId IN (SELECT Id 
                                           FROM ChargentOrders__ChargentOrder__c 
                                           WHERE ARC_Contract__c IN: contractIds)
                        ORDER BY CreatedDate DESC
              ];
		//Assign all data to global History List
        historyList.addAll(appendLabels(temp, 'ChargentOrders__ChargentOrder__c'));  
       
/**
 * Retrieves a list of AccountHistory records.
 * @return A list of AccountHistory records.
 */
        temp = [
                SELECT Id,AccountId,Field,DataType, OldValue,CreatedDate, 
            	       CreatedBy.Name,NewValue 
                       FROM AccountHistory 
                       WHERE AccountId IN (select id from Account where id=: recordIds)
                       ORDER BY CreatedDate DESC
              ];

        //Assign all data to global History List
        historyList.addAll( appendLabels(temp, 'Account') );

     
        return historyList;
    }
    

    // Convert the SObject records to SObjectWrapper records with labels   
    private static List<SObjectWrapper> appendLabels(List<SObject> sObjectList, String objectApiName) {
        //Create a map of field name to field label based on the objectApiName
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeSObjectResult typeDescription = targetType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = typeDescription.fields.getMap();
        
        //Convert sObject list to an SObjectWrapperList called tempList
        List<HistoryHandler.SObjectWrapper> tempList = new List<HistoryHandler.SObjectWrapper>();
        tempList.clear();
        for (SObject record : sObjectList) {
            String label = '';
            tempList.add(new HistoryHandler.SObjectWrapper(record, label));
        }
		
		//For each record in tempList set the label = to the result from the mapping of Field
		//if the Field in the record doesn't match a field in the map, set lable = Field
        for (SObjectWrapper wrapper : tempList) {
            SObject record = wrapper.record;
            String fieldName = String.valueOf(record.get('Field'));
            if (fieldMap.containsKey(fieldName)) {
                Schema.SObjectField field = fieldMap.get(fieldName);
                Schema.DescribeFieldResult fieldDescription = field.getDescribe();
                String fieldLabel = fieldDescription.getLabel();
                wrapper.label = fieldLabel;
            } else {
                wrapper.label = fieldName;
            }
        }

        return tempList;
    }

    
}