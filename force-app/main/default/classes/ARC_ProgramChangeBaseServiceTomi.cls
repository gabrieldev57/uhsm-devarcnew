/**
 * @Description: This is the entry point class for handling program changes in the system.
 * It implements Vlocity's Open Interface to receive and process program change requests.
 * The class acts as a facade, routing requests to the appropriate processing logic.
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-04-15
 * @Version: 1.0
 */
global without sharing class ARC_ProgramChangeBaseServiceTomi implements vlocity_ins.VlocityOpenInterface {
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
            processChanges(inputMap);
        }
        return true;       
    }

    /**
     * @Description: Processes the program change request by extracting reasons and initializing the handler
     * @param inputData: Map containing the program change data
     * @throws AuraHandledException: If there's an error during processing
     */
    public static void processChanges(Map<String, Object> inputData) {
        try {
            // Extract reasons from the input JSON node
            Map<String, Object> pcReasons = (Map<String, Object>)((Map<String, Object>) inputData.get('pcChanges')).get('pcReasons');
                       
            // Initialize the handler and process changes            
            ARC_ProgramChangeInsertManagerTomi handler = new ARC_ProgramChangeInsertManagerTomi(pcReasons,inputData);
            handler.executeAll();
        } catch (Exception e) {
            System.debug('Error in OmniScriptService: ' + e.getMessage());
            throw new AuraHandledException('Error processing member/contract changes.'); 
        }
    }
}