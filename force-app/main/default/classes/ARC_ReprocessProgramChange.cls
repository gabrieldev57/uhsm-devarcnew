public with sharing class ARC_ReprocessProgramChange {
    @AuraEnabled
    public static void reprocessProgramChange(Id recordId) {
        Custom_Logs__c log = [SELECT Id, Log__c, Log_2__c, Account__c, Contract__c, OwnerId, Status__c,Name 
                                  FROM Custom_Logs__c 
                                  WHERE Id = :recordId 
                                  LIMIT 1];
        String fullJson = log.Log__c;
        if (log.Log_2__c != null) {
            fullJson += log.Log_2__c;
        }

        Map<String, Object> inputMap = (Map<String, Object>) JSON.deserializeUntyped(fullJson);
        System.debug('PC SO DML Failed assignment' + inputMap);

        //SpinOff recalculation
        if(log.Name.contains('Spin Off DML Failed')|| log.Name.contains('Exception while processing UW case') || log.Name.contains('Exception in sendSpinOffNotificationEmail') || log.Name.contains('Exception while upserting census members in future context')){
            Map<String, Object> soReasons = (Map<String, Object>)((Map<String, Object>) inputMap.get('soChanges')).get('soReasons');

            try {
                // Track execution progress in result string
                String executionLog = '';
                            
                executionLog += '=== Initialization ===\n';
                executionLog += 'Record ID: ' + recordId + '\n';
                executionLog += 'SO Reasons: ' + JSON.serialize(soReasons) + '\n\n';
                
                ARC_SOManager manager = new ARC_SOManager(soReasons, inputMap);            
                
                executionLog += '=== Manager Created ===\n';
                executionLog += 'Actions Selected: ' + manager.ActionsSelected + '\n';
                executionLog += 'Input Map Size: ' + inputMap.size() + '\n\n';
                
                Savepoint sp = Database.setSavepoint();
                try {
                    executionLog += '=== Starting Execution ===\n';
                    manager.executeSingleSpinOff();
                    
                    executionLog += '=== Execution Completed Successfully ===\n';
                    executionLog += '=== Records Created/Updated ===\n';
                    //executionLog += getRecordsSummary(manager.allInsertedRecords);
                    
                    log.Reprocess_result__c = executionLog;
                    log.Status__c = 'Completed';
                    update log;
                    
                } catch (Exception innerEx) {
                    // Rollback and capture error details
                    Database.rollback(sp);
                    
                    executionLog += '=== Execution Failed ===\n';
                    executionLog += 'Error Message: ' + innerEx.getMessage() + '\n';
                    executionLog += 'Stack Trace: ' + innerEx.getStackTraceString() + '\n\n';
                    executionLog += '=== Last Successful Operation ===\n';
                    executionLog += '=== Records Processed Before Error ===\n';
                    //executionLog += getRecordsSummary(manager.allInsertedRecords);
                    
                    log.Reprocess_result__c = executionLog;
                    update log;
                    throw innerEx; // added now
                }
            } catch (Exception ex) {
                String initError = '=== Initialization Failed ===\n';
                initError += 'Error Message: ' + ex.getMessage() + '\n';
                initError += 'Stack Trace: ' + ex.getStackTraceString();
                
                log.Reprocess_result__c = initError;
                update log;
            }
        }
        
        //PC SO recalculation
        else if(log.Name.contains('PC SO DML Failed')|| log.Name.contains('PC SO Exception while processing UW case and members in')|| log.Name.contains('PC SO Exception while upserting census members in')|| log.Name.contains('Exception while processing DML operations in PC Spin Off Flow')){
            System.debug('PC SO DML Failed initialization' + inputMap);
            Map<String, Object> soReasons = (Map<String, Object>)((Map<String, Object>) inputMap.get('soChanges')).get('soReasons');

            try {
                // Track execution progress in result string
                String executionLog = ''; 
                            
                executionLog += '=== Initialization ===\n';
                executionLog += 'Record ID: ' + recordId + '\n';
                executionLog += 'SO Reasons: ' + JSON.serialize(soReasons) + '\n\n';
                
                ARC_PCSOManager manager = new ARC_PCSOManager(soReasons, inputMap);            
                
                executionLog += '=== Manager Created ===\n';
                executionLog += 'Actions Selected: ' + manager.ActionsSelected + '\n';
                executionLog += 'Input Map Size: ' + inputMap.size() + '\n\n';
                
                Savepoint sp = Database.setSavepoint();
                try {
                    executionLog += '=== Starting Execution ===\n';
                    manager.executeAll();
                    
                    executionLog += '=== Execution Completed Successfully ===\n';
                    executionLog += '=== Records Created/Updated ===\n';
                    executionLog += getRecordsSummary(manager.allInsertedRecords);
                    
                    log.Reprocess_result__c = executionLog;
                    log.Status__c = 'Completed';
                    update log;
                    
                } catch (Exception innerEx) {
                    // Rollback and capture error details
                    Database.rollback(sp);
                    
                    executionLog += '=== Execution Failed ===\n';
                    executionLog += 'Error Message: ' + innerEx.getMessage() + '\n';
                    executionLog += 'Stack Trace: ' + innerEx.getStackTraceString() + '\n\n';
                    executionLog += '=== Last Successful Operation ===\n';
                    executionLog += '=== Records Processed Before Error ===\n';
                    executionLog += getRecordsSummary(manager.allInsertedRecords);
                    
                    log.Reprocess_result__c = executionLog;
                    update log;
                    throw innerEx; // added now
                }
            } catch (Exception ex) {
                String initError = '=== Initialization Failed ===\n';
                initError += 'Error Message: ' + ex.getMessage() + '\n';
                initError += 'Stack Trace: ' + ex.getStackTraceString();
                
                log.Reprocess_result__c = initError;
                update log;
            }
        }
        //NewBorn recalculation
        else if(log.Name.contains('NewBorn DML Failed')|| log.Name.contains('NewBorn Mapping failed')|| log.Name.contains('NewBorn Exception while upserting census members in')|| log.Name.contains('Exception while processing DML operations in NewBorn Flow')){
            System.debug('NewBorn DML Failed initialization' + inputMap);
            Map<String, Object> nbReasons = (Map<String, Object>)((Map<String, Object>) inputMap.get('nbChanges')).get('nbReasons');

            try {
                // Track execution progress in result string
                String executionLog = '';
                            
                executionLog += '=== Initialization ===\n';
                executionLog += 'Record ID: ' + recordId + '\n';
                executionLog += 'NewBorn Reasons: ' + JSON.serialize(nbReasons) + '\n\n';
                
                ARC_NBManager manager = new ARC_NBManager(nbReasons, inputMap);            
                
                executionLog += '=== Manager Created ===\n';
                executionLog += 'Actions Selected: ' + manager.ActionsSelected + '\n';
                executionLog += 'Input Map Size: ' + inputMap.size() + '\n\n';
                
                Savepoint sp = Database.setSavepoint();
                try {
                    executionLog += '=== Starting Execution ===\n';
                    manager.executeSingleNewBorn();
                    
                    executionLog += '=== Execution Completed Successfully ===\n';
                    executionLog += '=== Records Created/Updated ===\n';
                    //executionLog += getRecordsSummary(manager.allInsertedRecords);
                    
                    log.Reprocess_result__c = executionLog;
                    log.Status__c = 'Completed';
                    update log;
                    
                } catch (Exception innerEx) {
                    // Rollback and capture error details
                    Database.rollback(sp);
                    
                    executionLog += '=== Execution Failed ===\n';
                    executionLog += 'Error Message: ' + innerEx.getMessage() + '\n';
                    executionLog += 'Stack Trace: ' + innerEx.getStackTraceString() + '\n\n';
                    executionLog += '=== Last Successful Operation ===\n';
                    executionLog += '=== Records Processed Before Error ===\n';
                    //executionLog += getRecordsSummary(manager.allInsertedRecords);
                    
                    log.Reprocess_result__c = executionLog;
                    update log;
                    throw innerEx; // added now
                }
            } catch (Exception ex) {
                String initError = '=== Initialization Failed ===\n';
                initError += 'Error Message: ' + ex.getMessage() + '\n';
                initError += 'Stack Trace: ' + ex.getStackTraceString();
                
                log.Reprocess_result__c = initError;
                update log;
            }
        }
        else{
            Map<String, Object> pcReasons = (Map<String, Object>)((Map<String, Object>) inputMap.get('pcChanges')).get('pcReasons');

            try {
                // Track execution progress in result string
                String executionLog = '';
                            
                executionLog += '=== Initialization ===\n';
                executionLog += 'Record ID: ' + recordId + '\n';
                executionLog += 'PC Reasons: ' + JSON.serialize(pcReasons) + '\n\n';
                
                ARC_PCManager manager = new ARC_PCManager(pcReasons, inputMap);            
                
                executionLog += '=== Manager Created ===\n';
                executionLog += 'Actions Selected: ' + manager.ActionsSelected + '\n';
                executionLog += 'Input Map Size: ' + inputMap.size() + '\n\n';
                
                Savepoint sp = Database.setSavepoint();
                try {
                    executionLog += '=== Starting Execution ===\n';
                    manager.executeAll();
                    
                    executionLog += '=== Execution Completed Successfully ===\n';
                    executionLog += '=== Records Created/Updated ===\n';
                    executionLog += getRecordsSummary(manager.allInsertedRecords);
                    
                    log.Reprocess_result__c = executionLog;
                    log.Status__c = 'Completed';
                    update log;
                    
                } catch (Exception innerEx) {
                    // Rollback and capture error details
                    Database.rollback(sp);
                    
                    executionLog += '=== Execution Failed ===\n';
                    executionLog += 'Error Message: ' + innerEx.getMessage() + '\n';
                    executionLog += 'Stack Trace: ' + innerEx.getStackTraceString() + '\n\n';
                    executionLog += '=== Last Successful Operation ===\n';
                    executionLog += getLastSuccessfulOperation(manager) + '\n\n';
                    executionLog += '=== Records Processed Before Error ===\n';
                    executionLog += getRecordsSummary(manager.allInsertedRecords);
                    
                    log.Reprocess_result__c = executionLog;
                    update log;
                    throw innerEx; // added now
                }
            } catch (Exception ex) {
                String initError = '=== Initialization Failed ===\n';
                initError += 'Error Message: ' + ex.getMessage() + '\n';
                initError += 'Stack Trace: ' + ex.getStackTraceString();
                
                log.Reprocess_result__c = initError;
                update log;
            }
        }        
    }
    
    private static String getRecordsSummary(Map<String, Map<Id, SObject>> records) {
        String summary = '';
        for(String key : records.keySet()) {
            summary += '- ' + key + ': ' + records.get(key).size() + ' records\n';
        }
        return summary;
    }
    
    private static String getLastSuccessfulOperation(ARC_PCManager manager) {
        if(manager.allInsertedRecords.isEmpty()) {
            return 'No operations completed successfully';
        }
        return 'Last successful record type: ' + new List<String>(manager.allInsertedRecords.keySet()).get(manager.allInsertedRecords.size() - 1);
    }
}