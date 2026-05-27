global without sharing class ARC_SpinOff_BaseService implements vlocity_ins.VlocityOpenInterface {
    /**
     * @Description: Base service class that serves as a placeholder for implementing multiple spin-off related operations.
     * This class implements the VlocityOpenInterface to allow for dynamic method invocation.
     * Developers should extend this class or add methods here for specific spin-off functionalities.
     * 
     * @param methodName: The name of the method to be invoked - developers should add new method names as needed
     * @param inputMap: Map containing input parameters for the method being called
     * @param outputMap: Map to store the results of the method execution
     * @param options: Additional configuration options that may be required for specific implementations
     * @return Boolean: Returns true to indicate method execution (actual validation to be implemented)
     */
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'TRANSFORM_CensusMemberToUserInputs') {
            TRANSFORM_CensusMemberToUserInputs(inputMap, outputMap, options);
        } 
        else if (methodName == 'GET_CensusMembers') {
            GET_CensusMembers(inputMap, outputMap);
        }
        else if(methodName == 'censusPlanSelectionChanges') {
            censusPlanSelectionChanges(inputMap, outputMap, options);
        }
        else if(methodName == 'TRANSFORM_RemoveMemberContractCalculatePrice') {
            TRANSFORM_RemoveMemberContractCalculatePrice(inputMap, outputMap, options);
        }
        else if(methodName == 'TRANSFORM_ChooseProductSelectionData') {
            TRANSFORM_ChooseProductSelectionData(inputMap, outputMap, options);
        }
        else if(methodName == 'readMedicalQuestions') {
            readMedicalQuestions(inputMap, outputMap, options);
        }
        else if(methodName == 'childLoseAncillary') {
            childLoseAncillary(inputMap, outputMap, options);
        }
        else if(methodName == 'RA_SingleSpinOffDML') {
            RA_SingleSpinOffDML(inputMap, outputMap);
        } 
        else if(methodName == 'includeGuardianAsHipaa') {
            includeGuardianAsHipaa(inputMap, outputMap, options);
        }
        else if(methodName == 'getHipaaRecipients') {
            getHipaaRecipients(inputMap, outputMap, options);
        }
        else if (methodName == 'getDocuSignData') {
            getDocuSignData(inputMap, outputMap, options);
        }
        else if (methodName == 'sendEnvelope') {
            sendEnvelope(inputMap, outputMap);
        }
        else if (methodName == 'updateEnvelopeContractData') {
            updateEnvelopeContractData(inputMap, outputMap);
        }
        else if (methodName == 'includeProductCodeToUserInputs') {
            includeProductCodeToUserInputs(inputMap, outputMap, options);
        }
        else if (methodName == 'includePremierSelected') {
            includePremierSelected(inputMap, outputMap, options);
        }
        else if (methodName == 'removeSelectedAncillaries') {
            removeSelectedAncillaries(inputMap, outputMap, options);
        }
        
        return true;       
    }

    /**
     * @Description: Placeholder method A - Template for implementing specific spin-off functionality
     * Developers should modify this method signature and implementation according to specific requirements
     * 
     * @param inputMap: Map containing the input parameters specific to this operation
     * @param outputMap: Map to store the operation results
     * @param options: Additional configuration options that may be required for specific implementations
     * @param inputData: Map containing the input parameters specific to this operation
     * @param outputMap: Map to store the operation results
     * @return Map<String, Object>: Returns processed data (implementation pending)
     */
    public static Map<String, Object>   TRANSFORM_CensusMemberToUserInputs(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String,Object> result = ARC_SpinOff_Utilities.TRANSFORM_CensusMemberToUserInputs(inputData, outputMap, options);
        outputMap.put('userInputs', result.get('userInputs'));
        return outputMap;
    }


    /*Placeholder method B - Template for implementing specific spin-off functionality
    Developers should modify this method signature and implementation according to specific requirements
    @param inputData: Map containing the input parameters specific to this operation
    @param outputMap: Map to store the operation results
    @return Map<String, Object>: Returns processed data (implementation pending)
    */
    public static Map<String, Object> GET_CensusMembers(Map<String, Object> inputData, Map<String,Object> outputMap) {
        ARC_SpinOff_Utilities.GET_CensusMembers(inputData, outputMap);
        outputMap.put('censusMembers', outputMap.get('censusMembers'));
        return outputMap;
    }

    /**
     * @param inputMap: Map containing the input parameters specific to this operation
     * @param outputMap: Map to store the operation results
     * @param options: Additional configuration options that may be required for specific implementations
     * @param inputData: Map containing the input parameters specific to this operation
     * @param outputMap: Map to store the operation results
     * @return Map<String, Object>: Returns processed data (implementation pending)
     */
    public static Map<String, Object> censusPlanSelectionChanges(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        ARC_SpinOff_Utilities.censusPlanSelectionChanges(inputData, outputMap, options);
        outputMap.put('soChanges', outputMap.get('soChanges'));
        
        if(outputMap.containsKey('STEP_HIPAAAuthorizationForm')){
            outputMap.put('STEP_HIPAAAuthorizationForm', outputMap.get('STEP_HIPAAAuthorizationForm'));
        }

        //outputMap.put('showHIPAAEditBlock', outputMap.get('showHIPAAEditBlock'));

        return outputMap;
    }

    /**
     * @Description: Transforms the input data to remove member and contract price calculations
     * @param inputData: Map containing the input parameters specific to this operation
     * @param outputMap: Map to store the operation results
     * @param options: Additional configuration options that may be required for specific implementations
     * @return Map<String, Object>: Returns processed data (implementation pending)
     */
    public static Map<String, Object> TRANSFORM_RemoveMemberContractCalculatePrice(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
         Map<String,Object> result = ARC_SpinOff_Utilities.TRANSFORM_RemoveMemberContractCalculatePrice(inputData, outputMap, options);
            outputMap.put('transformUserInputsRetainedPriceData', result.get('transformUserInputsRetainedPriceData'));
            
        return outputMap;
    }

    /**
     * @Description: Transforms the input data to choose product selection data
     * @param inputData: Map containing the input parameters specific to this operation
     * @param outputMap: Map to store the operation results
     * @param options: Additional configuration options that may be required for specific implementations
     * @return Map<String, Object>: Returns processed data (implementation pending)
     */
    public static Map<String, Object> TRANSFORM_ChooseProductSelectionData(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String,Object> result = ARC_SpinOff_Utilities.TRANSFORM_ChooseProductSelectionData(inputData, outputMap, options);
        if(result.get('LWC_ChooseProductSelectionInput') != null) outputMap.put('LWC_ChooseProductSelectionInput', result.get('LWC_ChooseProductSelectionInput'));
        if(result.get('LWC_ChooseProductSelectionOutput') != null) outputMap.put('LWC_ChooseProductSelectionOutput', result.get('LWC_ChooseProductSelectionOutput'));
        return outputMap;
    }

    /**
     * @Description: Reads the medical questions from the input data
     * @param inputData: Map containing the input parameters specific to this operation
     * @param outputMap: Map to store the operation results
     * @param options: Additional configuration options that may be required for specific implementations
     * @return Map<String, Object>: Returns processed data (implementation pending)
     */
    public static Map<String, Object> readMedicalQuestions(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String,Object> result = ARC_SpinOff_Utilities.readMedicalQuestions(inputData, outputMap, options);
        if(result.get('STEP_MedicalQuestions') != null) outputMap.put('STEP_MedicalQuestions', result.get('STEP_MedicalQuestions'));
        
        return outputMap;
    }

    /**
     * @Description: Reads the medical questions from the input data
     * @param inputData: Map containing the input parameters specific to this operation
     * @param outputMap: Map to store the operation results
     * @param options: Additional configuration options that may be required for specific implementations
     * @return Map<String, Object>: Returns processed data (implementation pending)
     */
    public static Map<String, Object> childLoseAncillary(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String,Object> result = ARC_SpinOff_Utilities.childLoseAncillary(inputData, outputMap, options);

        return outputMap;
    }



 
    /**
     * @Description: Processes the program change request by extracting reasons and initializing the handler
     * @param inputData: Map containing the program change data
     * @throws AuraHandledException: If there's an error during processing
     */
    public static Map<String, Object> RA_SingleSpinOffDML(Map<String, Object> inputData, Map<String,Object> outputMap) {       
        Map<String, Object> response = new Map<String, Object>();
        Map<String, Object> soReasons = (Map<String, Object>)((Map<String, Object>) inputData.get('soChanges')).get('soReasons');
        try { 
            ARC_SOManager handler = new ARC_SOManager(soReasons, inputData);
            handler.executeSingleSpinOff();
            response.put('spinOffContract', handler.singleSpinOffContract.Id);
            outputMap.put('spinOffContract', handler.singleSpinOffContract.Id);
        } catch (Exception e) {
            response.put('success', false);
            response.put('errorMessage', e.getMessage());
            response.put('errorStackTrace', e.getStackTraceString());
            outputMap.put('success', false);
            outputMap.put('errorMessage', e.getMessage());
            outputMap.put('errorStackTrace', e.getStackTraceString());
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail; 
            String inputDataString = JSON.serialize(inputData);
            String emailBody = 'Error in ARC_PCBaseService.cls: ' + e.getMessage() + 
                             '\n\nInput Data: ' + inputDataString + 
                             '\n\nStack Trace: ' + e.getStackTraceString();
            ARC_QueableSendFileBatch.sendEmailNotification(emailBody, 'ERROR in DML while running SpinOff', apexErrorEmail);
            throw new AuraHandledException('Error processing member/contract changes.'); 
        }
        return response;
    }

    /**
    * @Description: Processes the program change request by extracting reasons and initializing the handler
    * @param inputMap: Map containing the input parameters specific to this operation
    * @param outputMap: Map to store the operation results  
    * @param options: Additional configuration options that may be required for specific implementations
    * @return Map<String, Object>: Returns processed data (implementation pending)
    */
    public static Map<String, Object> includeGuardianAsHipaa(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        ARC_SpinOff_Utilities.includeGuardianAsHipaa(inputData, outputMap, options);
    
        if(outputMap.containsKey('STEP_HIPAAAuthorizationForm')){
            outputMap.put('STEP_HIPAAAuthorizationForm', outputMap.get('STEP_HIPAAAuthorizationForm'));
        }

    
        return outputMap;
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
                System.debug('envelopeContractData: ' + envelopeContractData);
                Contract spinOffContract = new Contract();
                spinOffContract.Id = (Id)envelopeContractData.get('contractId');
                spinOffContract.ARC_Signer_Email__c = (String)envelopeContractData.get('signerEmail');
                spinOffContract.ARC_Signer_Name__c = (String)envelopeContractData.get('signerName');
                spinOffContract.vlocity_ins__LastDocuSignEnvelopeId__c = (String)envelopeContractData.get('envelopeId');
                update spinOffContract;
                response.put('spinOffContractUpdated', spinOffContract);
                System.debug('spinOffContract: ' + spinOffContract); 
            } catch (Exception e) {
                System.debug('Error in updateEnvelopeContractData: ' + e.getMessage() + e.getStackTraceString());
            }
        }
        return response;
    }

    /**
     * Get the hippa recipients to send the DocuSign
     * @param {List<Object>} census_members - The census members.
     * @returns {List<Map<String, Object>>} - The hipaa recipients.
     */
    public static void getHipaaRecipients(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        ARC_SpinOff_Utilities.getHipaaRecipients(inputData, outputMap, options);
        outputMap.put('FinalHipaaRecipients', outputMap.get('FinalHipaaRecipients'));

    }

        /**
     * Get the DocuSign related data 
     * @param {List<Object>} census_members - The census members.
     * @returns {Map<String, Object>} - DocuSign data.
     */
    public static void getDocuSignData(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String,Object> output = new Map<String,Object>();
        ARC_SpinOff_Utilities.getDocuSignData(inputData, output, options);
        // outputMap.put('DocuSignTemplateId', output.get('DocuSignTemplateId'));
        // outputMap.put('SignerList', output.get('SignerList'));
        // outputMap.put('RAresponse', output.get('RAresponse'));
        outputMap.put('EnvelopeInformation', output.get('EnvelopeInformation'));

    }

    /**
     * @Description: Get the input information of the envelope and call the method to send the envelope
     * @param inputData: Map containing teh envelope information
     * @throws AuraHandledException: If there's an error during processing
     */
    public static Map<String, Object> sendEnvelope(Map<String, Object> inputData, Map<String,Object> outputMap) {
        Map<String, Object> response = new Map<String, Object>();
        try {
            Map<String,Object> envelopeInfoMap = inputData.containsKey('EnvelopeInformation') ? (Map<String,Object>)inputData.get('EnvelopeInformation') : new Map<String,Object>();

            String subjectStr = 'Please DocuSign: UHSM Spin Off';
            String signerListStr = envelopeInfoMap.containsKey('signerList') ? JSON.serialize(envelopeInfoMap.get('signerList')) : null; System.debug('Signer List Str: ' + signerListStr);
            String templatesIdListStr = envelopeInfoMap.containsKey('templateIdList') ? JSON.serialize(envelopeInfoMap.get('templateIdList')) : null; System.debug('Templates Id List Str: ' + templatesIdListStr);
            String tabsMapStr = envelopeInfoMap.containsKey('tabs') ? JSON.serialize(envelopeInfoMap.get('tabs')) : null; System.debug('Tabs Map Str: ' + tabsMapStr);
            String contractId = inputData.containsKey('contractId') && inputData.get('contractId') != null ? (String)inputData.get('contractId') : null; System.debug('Contract Id: ' + contractId);

            ARC_DocuSignApi.sendCompositeEnvelope(subjectStr, signerListStr, templatesIdListStr, tabsMapStr, contractId);

            response.put('success', true);
            outputMap.put('success', true);
        } catch (Exception e) {
            System.debug('Error in sendEnvelope method: ' + e.getMessage() + e.getStackTraceString());
            response.put('success', false);
            outputMap.put('success', false);
        }
        return response;
    }

    /**
     * @Description: Include the product code in the user inputs
     * 
     * @param userInputs: Map containing the user inputs
     * @param selectedProducts: Map containing the selected products
     * @param oldProducts: Map containing the old products
     * @param planSelected: Boolean that indicates if a product was selected or the old product is needed
     * @return Map<String, Object>: Returns processed data
     */
    public static Map<String, Object> includeProductCodeToUserInputs(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String, Object> result = ARC_SpinOff_Utilities.includeProductCodeToUserInputs(inputData, outputMap, options);
        outputMap.put('userInputs', result.get('userInputs'));
        return outputMap;
    }
    
    /**
     * @Description: Indicate if the plan selected for spinned off family is a Premier
     * 
     * @param selectedProducts: Map containing the selected products
     * @param oldProducts: Map containing the old products
     * @param planSelected: Boolean that indicates if a product was selected or the old product is needed
     * @return Map<String, Object>: Boolean node
     */
    public static Map<String, Object> includePremierSelected(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String, Object> result = ARC_SpinOff_Utilities.includePremierSelected(inputData, outputMap, options);
        outputMap.put('premierSelected', result.get('premierSelected'));
        outputMap.put('originalPremierSelected', result.get('originalPremierSelected'));
        return outputMap;
    }

    /**
     * @Description: Method to remove the Ancillaries that are not related to the Medical Product
     * 
     * @param selectedProducts: Map containing the selected products
     * @return Map<String, Object>: Map selectedProducts
     */
    public static Map<String, Object> removeSelectedAncillaries(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String, Object> result = ARC_SpinOff_Utilities.removeSelectedAncillaries(inputData, outputMap, options);
        outputMap.put('selectedProducts', result.get('selectedProducts'));
        return outputMap;
    }
}