/**
 * @Description: Base service class implementing VlocityOpenInterface.
 * Acts as the entry point for OmniScript Remote Actions to handle
 * Small Group (SG) Temporary Newborn processing and DML operations.
 */
global without sharing class ARC_SGNewBorn_BaseService implements vlocity_ins.VlocityOpenInterface {
    
    /**
     * @Description: Base service class that serves as a placeholder for implementing multiple newborn-related operations.
     */
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'SGNB_TempNewBornDML') {
            SGNB_TempNewBornDML(inputMap, outputMap);
        }
        return true;       
    }

    /**
     * @Description: Processes the newborn request initializing the handler
     */
    public static Map<String, Object> SGNB_TempNewBornDML(Map<String, Object> inputData, Map<String,Object> outputMap) {       
        Map<String, Object> response = new Map<String, Object>();

        outputMap.put('BirthdateError', false);
        outputMap.put('MotherError', false);
        outputMap.put('errorMessage', null);
        
        try { 
            ARC_SGNBManager handler = new ARC_SGNBManager(inputData);
            handler.executeSingleNewBorn();
            
            response.put('success', true);
            outputMap.put('success', true);            
        } catch (Exception e) {
            response.put('success', false);
            response.put('errorMessage', e.getMessage());
            outputMap.put('success', false);
            outputMap.put('errorMessage', e.getMessage());
            
            //---------------------------------------------
            // Verify if exist a policy with a mother
            //---------------------------------------------
            if (e instanceof ARC_SGNBManager.NoMotherPolicyException) {
                outputMap.put('MotherError', true);
            } 
            //---------------------------------------------
            // Check if the newborns are less than one day apart
            //---------------------------------------------
            else if (e instanceof ARC_SGNBManager.InvalidTwinBirthdateException) {
                outputMap.put('BirthdateError', true);
            //---------------------------------------------
            // Check another error
            //---------------------------------------------
            } else {
                response.put('errorStackTrace', e.getStackTraceString());
                outputMap.put('errorStackTrace', e.getStackTraceString());
                
                String apexErrorEmail = System.Label.ARC_ApexErrorEmail; 
                String inputDataString = JSON.serialize(inputData);
                String emailBody = 'Error in ARC_SGNewBorn_BaseService.cls: ' + e.getMessage() + 
                                '\n\nInput Data: ' + inputDataString + 
                                '\n\nStack Trace: ' + e.getStackTraceString();
                ARC_QueableSendFileBatch.sendEmailNotification(emailBody, 'ERROR in DML while running NewBorn', apexErrorEmail);
            }
        }
        return response;
    }
}