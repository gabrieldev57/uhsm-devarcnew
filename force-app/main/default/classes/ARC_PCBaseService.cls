/**
 * @Description: This is the entry point class for handling program changes in the system.
 * It implements Vlocity's Open Interface to receive and process program change requests.
 * The class acts as a facade, routing requests to the appropriate processing logic.
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-04-15
 * @Version: 1.0
 */
global without sharing class ARC_PCBaseService implements vlocity_ins.VlocityOpenInterface {
    /**
     * @Description: Main entry point method that handles incoming program change requests
     * @param methodName: The name of the method to invoke
     * @param inputMap: Map containing input data for the program change
     * @param outputMap: Map to store output data
     * @param options: Additional options for the operation
     * @return Boolean: Always returns true to indicate successful processing
     */
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'processChanges') {
            processChanges(inputMap, outputMap);
        } else if (methodName == 'updateEnvelopeContractData') {
            updateEnvelopeContractData(inputMap, outputMap);
        }
        return true;       
    }

    /**
     * @Description: Processes the program change request by extracting reasons and initializing the handler
     * @param inputData: Map containing the program change data
     * @throws AuraHandledException: If there's an error during processing
     */
    public static Map<String, Object> processChanges(Map<String, Object> inputData, Map<String,Object> outputMap) {
        Map<String, Object> response = new Map<String, Object>();
        
        try {
            // Extract reasons from the input JSON node
            Map<String, Object> pcReasons = (Map<String, Object>)((Map<String, Object>) inputData.get('pcChanges')).get('pcReasons');
                       
            // Initialize the handler and process changes            
            ARC_PCManager handler = new ARC_PCManager(pcReasons,inputData);
            handler.executeAll();
            
            // Add the new contract ID to the output map so It can be used by the DocuSign Service
            outputMap.put('newContractId', handler.newContractId);
            response.put('success', true);
            outputMap.put('success', true);
            // Updated Amendment map with medicare information
            outputMap.put('AmendmentDocuSignMapData', handler.amendmentInfoMap);
        } catch (Exception e) {
            System.debug('Error in OmniScriptService: ' + e.getMessage() + e.getStackTraceString());
            response.put('success', false);
            response.put('errorMessage', e.getMessage());
            response.put('errorStackTrace', e.getStackTraceString());
            outputMap.put('success', false);
            outputMap.put('errorMessage', e.getMessage());
            outputMap.put('errorStackTrace', e.getStackTraceString());
            //throw new AuraHandledException('Error processing member/contract changes.');
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail; 
            String inputDataString = JSON.serialize(inputData);
            String emailBody = 'Error in ARC_PCBaseService.cls: ' + e.getMessage() + 
                             '\n\nInput Data: ' + inputDataString + 
                             '\n\nStack Trace: ' + e.getStackTraceString();
            ARC_QueableSendFileBatch.sendEmailNotification(emailBody, 'ERROR in DML while running program change', apexErrorEmail);
            throw new AuraHandledException('Error processing member/contract changes.'); 
        }
        return response;
    }

    /**
     * @Description: Updates the envelope contract data
     * @param inputData: Map containing the program change data and the contract id
     * @throws AuraHandledException: If there's an error during processing
     */
    public static Map<String, Object> updateEnvelopeContractData(Map<String, Object> inputData, Map<String,Object> outputMap) {
        Map<String, Object> response = new Map<String, Object>();
    
        Map<String, Object> envelopeContractData = inputData.containsKey('EnvelopeContractData') ? (Map<String, Object>)((Map<String, Object>) inputData.get('EnvelopeContractData')) : null;
        System.debug('envelopeContractData: ' + envelopeContractData);
        if(envelopeContractData != null){
            System.debug('envelopeContractData: ' + envelopeContractData);
            try {
                Integer retries = 3;
                while (retries > 0) {
                    try {
                        // Extract reasons from the input JSON node
                        System.debug('envelopeContractData: ' + envelopeContractData);
                        Contract newContract = new Contract();  
                        newContract.Id = (Id)envelopeContractData.get('contractId');
                        newContract.ARC_Signer_Email__c = (String)envelopeContractData.get('signerEmail');
                        newContract.ARC_Signer_Name__c = (String)envelopeContractData.get('signerName');
                        newContract.vlocity_ins__LastDocuSignEnvelopeId__c = (String)envelopeContractData.get('envelopeId');
                        //newContract.vlocity_ins__LastDocuSignEnvelopeStatus__c = (String)envelopeContractData.get('vlocity_ins__LastDocuSignEnvelopeStatus__c');
                        update newContract;
                        retries = 0;
                        System.debug('newContract: ' + newContract); 
                    } catch (System.DmlException e) {
                        if (e.getMessage().contains('UNABLE_TO_LOCK_ROW') && retries > 1) {
                            retries--;
                            Long startTime = System.currentTimeMillis();
                            while(System.currentTimeMillis() - startTime < 2000) {
                                // Adding a small delay
                            }
                        } else {
                            System.debug('Error in updateEnvelopeContractData: ' + e.getMessage() + e.getStackTraceString());
                            Integer MAX_FIELD_SIZE = 131072-10;
                
                            String serializedData = JSON.serialize(envelopeContractData);
                            Custom_Logs__c log = new Custom_Logs__c();
                            log.Name = 'Exception while updating envelope contract data';
                            log.OwnerId = UserInfo.getUserId();
                            log.Status__c = 'New';                
                            if(serializedData.length() > MAX_FIELD_SIZE) {
                                log.Log__c = serializedData.substring(0, MAX_FIELD_SIZE);
                                if(serializedData.length() > MAX_FIELD_SIZE) {
                                    Integer remainingLength = Math.min(serializedData.length() - MAX_FIELD_SIZE, MAX_FIELD_SIZE);
                                    log.Log_2__c = serializedData.substring(MAX_FIELD_SIZE, MAX_FIELD_SIZE + remainingLength);
                                }
                            } else {
                                log.Log__c = serializedData;
                            }
                        
                        insert log;
                        System.debug('Exception while updating envelope contract data: ' + e.getMessage() + e.getStackTraceString());
                        throw e;                            
                        }
                    }
                }   
            } catch (Exception e) {
                System.debug('Error in updateEnvelopeContractData: ' + e.getMessage() + e.getStackTraceString());
                Integer MAX_FIELD_SIZE = 131072-10;
    
                String serializedData = JSON.serialize(envelopeContractData);
                Custom_Logs__c log = new Custom_Logs__c();
                log.Name = 'Exception while updating envelope contract data';
                log.OwnerId = UserInfo.getUserId();
                log.Status__c = 'New';                
                if(serializedData.length() > MAX_FIELD_SIZE) {
                    log.Log__c = serializedData.substring(0, MAX_FIELD_SIZE);
                    if(serializedData.length() > MAX_FIELD_SIZE) {
                        Integer remainingLength = Math.min(serializedData.length() - MAX_FIELD_SIZE, MAX_FIELD_SIZE);
                        log.Log_2__c = serializedData.substring(MAX_FIELD_SIZE, MAX_FIELD_SIZE + remainingLength);
                    }
                } else {
                    log.Log__c = serializedData;
                }            
            insert log;
            System.debug('Exception while updating envelope contract data: ' + e.getMessage() + e.getStackTraceString());
            throw e;                
            }
        }        
        return response;
    }
}