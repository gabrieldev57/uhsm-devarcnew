/**
 * @Description: This is the service class for handling self enrollment requests for Small Groups in the system.
 * It processes self enrollment data for Small Groups received from external endpoints and manages the enrollment flow.
 * The class acts as a facade, routing requests to the appropriate processing logic.
 * 
 * @Author: Agustin Garay
 * @Date: 2025-09-10
 * @Version: 1.0
 */
global without sharing class ARC_SGSEBaseService implements vlocity_ins.VlocityOpenInterface{

    /**
     * @Description: Main entry point method that handles incoming self enrollment requests for Small Groups
     * @param methodName: The name of the method to invoke
     * @param inputMap: Map containing input data for the self enrollment for Small Groups
     * @param outputMap: Map to store output data
     * @param options: Additional options for the operation
     * @return Boolean: Always returns true to indicate successful processing
     */
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'processSmallGroupSelfEnrollment') {
            processSmallGroupSelfEnrollment(inputMap, outputMap);
        } 
        return true;   
    }

    /**
     * @Description: Processes the self enrollment request by extracting data and initializing the handler
     * @param inputData: Map containing the enrollment data
     * @param outputMap: Map to store output data
     * @return Map<String, Object>: Response data with success status and results
     */
    public static Map<String, Object> processSmallGroupSelfEnrollment(Map<String, Object> inputData, Map<String,Object> outputMap) {
        Map<String, Object> response = new Map<String, Object>();
        try {
            // Extract enrollment information from the input data
            Map<String, Object> enrollmentInfo = inputData;
            
            // Initialize the handler and process enrollment
            ARC_SGSEManager handler = new ARC_SGSEManager(enrollmentInfo);
            handler.executeEnrollment();

            Id policyId = handler.policy.Id;
            System.debug('Handler.policy.Id = ' + policyId);
            // Prepare and send DocuSign envelope asynchronously
            if (policyId != null) {
                System.debug('DocuSign Handler...');
                // Get all the required data for DocuSign envelope
                ARC_SGSE_DocuSign docuSign = new ARC_SGSE_DocuSign();
                docuSign.getDocuSignData(handler); 

                String subjectStr = 'Please DocuSign: WeShare healthcare by UHSM Application';
                String signerListStr = handler.docuSignData.containsKey('signerList') && handler.docuSignData.get('signerList') != null ? JSON.serialize(handler.docuSignData.get('signerList')) : '';
                String templatesIdListStr = handler.docuSignData.containsKey('templatesIdList') && handler.docuSignData.get('templatesIdList') != null ? JSON.serialize(handler.docuSignData.get('templatesIdList')) : '';
                String tabsMapStr = handler.docuSignData.containsKey('tabs') && handler.docuSignData.get('tabs') != null ? JSON.serialize(handler.docuSignData.get('tabs')) : '';
                
                // Send the composite envelope
                ARC_DocuSignApi.sendCompositeEnvelopeSmallGroup(subjectStr, signerListStr, templatesIdListStr, tabsMapStr, policyId);
            }
            
            System.debug('inputData SGSE BaseService: ' + inputData);
            // Add the enrollment ID to the output map so it can be used by other services
            outputMap.put('enrollmentId', 'SGSE-' + System.currentTimeMillis());
            outputMap.put('success', true);
            response.put('success', true);
            response.put('message', 'Small group self enrollment processed successfully');
            response.put('enrollmentId', 'SGSE-' + System.currentTimeMillis());
            response.put('processedAt', System.now());            
        } catch (Exception e) {
            System.debug('Error in processSmallGroupSelfEnrollment: ' + e.getMessage() + e.getStackTraceString());
            response.put('success', false);
            response.put('errorMessage', e.getMessage());
            response.put('errorStackTrace', e.getStackTraceString());
            outputMap.put('success', false);
            outputMap.put('errorMessage', e.getMessage());
            outputMap.put('errorStackTrace', e.getStackTraceString());
            
            // Send error notification email
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            String enrollmentDataString = JSON.serialize(inputData);
            String emailBody = 'Error in ARC_SGSEBaseService.processSmallGroupSelfEnrollment: ' + e.getMessage() + 
                            '\n\nEnrollment Data: ' + enrollmentDataString + 
                            '\n\nStack Trace: ' + e.getStackTraceString();
            ARC_QueableSendFileBatch.sendEmailNotification(emailBody, 'ERROR in Small Group Self Enrollment Service', apexErrorEmail);
            
            throw new AuraHandledException('Error processing Small Group self enrollment request.');
        }
        return response;
    }
}