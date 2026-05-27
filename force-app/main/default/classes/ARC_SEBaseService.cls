/**
 * @Description: This is the service class for handling self enrollment requests in the system.
 * It processes self enrollment data received from external endpoints and manages the enrollment flow.
 * The class acts as a facade, routing requests to the appropriate processing logic.
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-01-27
 * @Version: 1.0
 */
global without sharing class ARC_SEBaseService {
    
    /**
     * @Description: Main entry point method that handles incoming self enrollment requests
     * @param methodName: The name of the method to invoke
     * @param inputMap: Map containing input data for the self enrollment
     * @param outputMap: Map to store output data
     * @param options: Additional options for the operation
     * @return Boolean: Always returns true to indicate successful processing
     */
    global Map<String, Object> invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'processSelfEnrollment') {
            processSelfEnrollment(inputMap, outputMap);
        }
        else if (methodName == 'validateEnrollmentData') {
            validateEnrollmentData(inputMap, outputMap);
        }
        return outputMap;       
    }

    /**
     * @Description: Processes the self enrollment request by extracting data and initializing the handler
     * @param inputData: Map containing the enrollment data
     * @param outputMap: Map to store output data
     * @return Map<String, Object>: Response data with success status and results
     */
    public static Map<String, Object> processSelfEnrollment(Map<String, Object> inputData, Map<String,Object> outputMap) {
        Map<String, Object> response = new Map<String, Object>();
        try {
            // Extract enrollment information from the input data
            Map<String, Object> enrollmentInfo = inputData;
            
            // Initialize the handler and process enrollment
            ARC_SEManager handler = new ARC_SEManager(enrollmentInfo);
            handler.executeEnrollment();

            Id groupAccountId = handler.groupAccount.Id;
            String groupAccountName = handler.groupAccount.Name;
            Id contractId = handler.contractId;

            // Prepare and send DocuSign envelope asynchronously
            if (contractId != null) {
                System.debug('DocuSign Handler...');
                ARC_SE_DocuSign docuSign = new ARC_SE_DocuSign();
                docuSign.getDocuSignData(handler); // Get all the required data for DocuSign envelope
                // ARC_SE_DocuSign.sendEnvelopeAsync(handler.serializedDocuSignData, handler.contractId); // Send envelope and update contract related information
                String subjectStr = 'Please DocuSign: WeShare healthcare by UHSM Application';
                String signerListStr = handler.docuSignData.containsKey('signerList') && handler.docuSignData.get('signerList') != null ? JSON.serialize(handler.docuSignData.get('signerList')) : '';
                String templatesIdListStr = handler.docuSignData.containsKey('templatesIdList') && handler.docuSignData.get('templatesIdList') != null ? JSON.serialize(handler.docuSignData.get('templatesIdList')) : '';
                String tabsMapStr = handler.docuSignData.containsKey('tabs') && handler.docuSignData.get('tabs') != null ? JSON.serialize(handler.docuSignData.get('tabs')) : '';
                ARC_DocuSignApi.sendCompositeEnvelope(subjectStr, signerListStr, templatesIdListStr, tabsMapStr, contractId);
            }
            
            System.debug('inputData SE BAseService: ' + inputData);
            // Add the enrollment ID to the output map so it can be used by other services
            outputMap.put('enrollmentId', 'SE-' + System.currentTimeMillis());
            outputMap.put('success', true);
            response.put('success', true);
            response.put('message', 'Self enrollment processed successfully');
            response.put('enrollmentId', 'SE-' + System.currentTimeMillis());
            response.put('processedAt', System.now());
            outputMap.put('groupAccountId',groupAccountId);
            outputMap.put('groupAccountName',groupAccountName);

        } catch (Exception e) {
            System.debug('Error in processSelfEnrollment: ' + e.getMessage() + e.getStackTraceString());
            response.put('success', false);
            response.put('errorMessage', e.getMessage());
            response.put('errorStackTrace', e.getStackTraceString());
            outputMap.put('success', false);
            outputMap.put('errorMessage', e.getMessage());
            outputMap.put('errorStackTrace', e.getStackTraceString());
            
            // Send error notification email
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            String enrollmentDataString = JSON.serialize(inputData);
            String emailBody = 'Error in ARC_SEBaseService.processSelfEnrollment: ' + e.getMessage() + 
                            '\n\nEnrollment Data: ' + enrollmentDataString + 
                            '\n\nStack Trace: ' + e.getStackTraceString();
            ARC_QueableSendFileBatch.sendEmailNotification(emailBody, 'ERROR in Self Enrollment Service', apexErrorEmail);
            
            throw new CalloutException(
                'Error processing self enrollment request. Root cause: ' + e.getMessage() +
                ' | Line: ' + e.getLineNumber() +
                ' | StackTrace: ' + e.getStackTraceString()
            );
        }        
        return response;
    }
    
    /** fields in the enrollment data
     * @param inputData: Map containing the enrollment data to validate
     * @param outputMap: Map to store validation results
     * @return Map<String, Object>: Response data with validation results
     */
    public static Map<String, Object> validateEnrollmentData(Map<String, Object> inputData, Map<String,Object> outputMap) {
        Map<String, Object> response = new Map<String, Object>();
        
        try {
            if (inputData == null) {
                response.put('success', false);
                response.put('errorMessage', 'Enrollment data is required');
                outputMap.put('success', false);
                outputMap.put('errorMessage', 'Enrollment data is required');
                return response;
            }
            
            // Validate enrollment info
            Map<String, Object> generalInformation = (Map<String, Object>)inputData.get('generalInformation');
            if (generalInformation == null) {
                response.put('success', false);
                response.put('errorMessage', 'generalInformation is required');
                outputMap.put('success', false); 
                outputMap.put('errorMessage', 'generalInformation is required');
                return response;
            }
            
            // Validate member data
            List<Object> memebersData = (List<Object>)inputData.get('members');
            if (memebersData == null) {
                response.put('success', false);
                response.put('errorMessage', 'memebersData is required');
                outputMap.put('success', false);
                outputMap.put('errorMessage', 'memebersData is required');
                return response;
            }
            
            // Add more specific validations as needed
            // Example: Check for required fields like email, name, etc.
            
            response.put('success', true);
            response.put('message', 'Validation passed');
            outputMap.put('success', true);
            outputMap.put('validationPassed', true);
            
        } catch (Exception e) {
            System.debug('Error in validateEnrollmentData: ' + e.getMessage() + e.getStackTraceString());
            response.put('success', false);
            response.put('errorMessage', e.getMessage());
            outputMap.put('success', false);
            outputMap.put('errorMessage', e.getMessage());
        }
        
        return response;
    }
    
    /**
     * @Description: Logs errors to Custom_Logs__c for debugging purposes
     * @param errorContext: Context where the error occurred
     * @param e: The exception that occurred
     * @param requestData: The request data that caused the error
     */
    private static void logError(String errorContext, Exception e, String requestData) {
        try {
            Integer MAX_FIELD_SIZE = 131072 - 10;
            
            Custom_Logs__c log = new Custom_Logs__c();
            log.Name = errorContext;
            log.OwnerId = UserInfo.getUserId();
            log.Status__c = 'New';
            
            String logData = 'Error: ' + e.getMessage() + '\n\nRequest Data: ' + requestData + '\n\nStack Trace: ' + e.getStackTraceString();
            
            if (logData.length() > MAX_FIELD_SIZE) {
                log.Log__c = logData.substring(0, MAX_FIELD_SIZE);
                if (logData.length() > MAX_FIELD_SIZE) {
                    Integer remainingLength = Math.min(logData.length() - MAX_FIELD_SIZE, MAX_FIELD_SIZE);
                    log.Log_2__c = logData.substring(MAX_FIELD_SIZE, MAX_FIELD_SIZE + remainingLength);
                }
            } else {
                log.Log__c = logData;
            }
            
            insert log;
        } catch (Exception logException) {
            System.debug('Failed to log error: ' + logException.getMessage());
        }
    }

    private static void updateContractEnvelopeId (Map<String,Object> docuSignData) {
        System.debug('Updating contract envelope id...');
        try {
            String envelopeId = (String)docuSignData.get('envelopeId');
            String contractId = (String)docuSignData.get('contractId');
            if (String.isNotBlank(envelopeId) && String.isNotBlank(contractId)) {
                
            }
        } catch (Exception e) {
            System.debug('Error in updateContractEnvelopeId: ' + e.getMessage() + e.getStackTraceString());
        }
    }
}