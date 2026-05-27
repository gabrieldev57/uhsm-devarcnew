global without sharing class ARC_NewBorn_BaseService implements vlocity_ins.VlocityOpenInterface {
    /**
     * @Description: Base service class that serves as a placeholder for implementing multiple newborn-related operations.
     * This class implements the VlocityOpenInterface to allow for dynamic method invocation.
     * Developers should extend this class or add methods here for specific newborn functionalities.
     * 
     * @param methodName: The name of the method to be invoked - developers should add new method names as needed
     * @param inputMap: Map containing input parameters for the method being called
     * @param outputMap: Map to store the results of the method execution
     * @param options: Additional configuration options that may be required for specific implementations
     * @return Boolean: Returns true to indicate method execution (actual validation to be implemented)
     */
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'NB_NewBornDML') {
            NB_NewBornDML(inputMap, outputMap);
        }
        else if (methodName == 'populateMedicalQuestions') {
            populateMedicalQuestions(inputMap, outputMap, options);
        }
        else if (methodName == 'TRANSFORM_CensusMemberToUserInputs') {
            TRANSFORM_CensusMemberToUserInputs(inputMap, outputMap, options);
        }
        else if (methodName == 'TRANSFORM_ChooseProductSelectionData') {
            TRANSFORM_ChooseProductSelectionData(inputMap, outputMap, options);
        }
        else if (methodName == 'populateReasons') {
            populateReasons(inputMap, outputMap, options);
        }
        else if (methodName == 'getDocuSignData') {
            getDocuSignData(inputMap, outputMap, options);
        }
        else if (methodName == 'sendEnvelope') {
            sendEnvelope(inputMap, outputMap);
        }
        else if (methodName == 'hasTemporaryNewBornMember') {
            hasTemporaryNewBornMember(inputMap, outputMap, options);
        }
        else if (methodName == 'getMemberBeneficiaries') {
            getMemberBeneficiaries(inputMap, outputMap, options);
        }
        else if (methodName == 'mergeMedicalQuestions') {
            mergeMedicalQuestions(inputMap, outputMap, options);
        }
        return true;       
    }


    /**
     * @Description: Processes the newborn request by extracting reasons and initializing the handler
     * @param inputData: Map containing the newborn data
     * @throws AuraHandledException: If there's an error during processing
     */
    public static Map<String, Object> NB_NewBornDML(Map<String, Object> inputData, Map<String,Object> outputMap) {       
        Map<String, Object> response = new Map<String, Object>();
        
        Map<String, Object> nbReasons = (Map<String, Object>)((Map<String, Object>) inputData.get('nbChanges')).get('nbReasons');
        try { 
            
            ARC_NBManager handler = new ARC_NBManager(nbReasons, inputData);
            System.debug('### NewBorn Handler initialized: ' + handler);
            handler.executeSingleNewBorn();
            if (handler.contractsToUpsert.containsKey('PermanentNewborn') && handler.contractsToUpsert.get('PermanentNewborn') != null) {
                response.put('newBornContract', ((Contract)handler.contractsToUpsert.get('PermanentNewborn')).Id); 
                outputMap.put('newBornContract', ((Contract)handler.contractsToUpsert.get('PermanentNewborn')).Id);
            }
            response.put('success', true);
            outputMap.put('success', true);
        } catch (Exception e) {
            response.put('success', false);
            response.put('errorMessage', e.getMessage());
            response.put('errorStackTrace', e.getStackTraceString());
            outputMap.put('success', false);
            outputMap.put('errorMessage', e.getMessage());
            outputMap.put('errorStackTrace', e.getStackTraceString());
            
           
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail; 
            String inputDataString = JSON.serialize(inputData);
            String emailBody = 'Error in ARC_NewBorn_BaseService.cls: ' + e.getMessage() + 
                            '\n\nInput Data: ' + inputDataString + 
                            '\n\nStack Trace: ' + e.getStackTraceString();
            ARC_QueableSendFileBatch.sendEmailNotification(emailBody, 'ERROR in DML while running NewBorn', apexErrorEmail);
            
            throw new AuraHandledException('Error processing newborn changes.'); 
        }
        System.debug('### Response: ' + response);
        return response;
    }


    public static Map<String, Object> populateMedicalQuestions(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        ARC_TemporaryNewborn_Utilities.populateMedicalQuestions(inputData, outputMap, options);

        if(outputMap.containsKey('STEP_MedicalQuestions')) outputMap.put('STEP_MedicalQuestions', outputMap.get('STEP_MedicalQuestions'));
        if(outputMap.containsKey('CensusMember')) outputMap.put('CensusMember', outputMap.get('CensusMember'));
        return outputMap;
    }

    public static Map<String, Object> mergeMedicalQuestions(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        ARC_TemporaryNewborn_Utilities.mergeMedicalQuestions(inputData, outputMap, options);
        if(outputMap.containsKey('carryOverMedicalQuestions')) outputMap.put('carryOverMedicalQuestions', outputMap.get('carryOverMedicalQuestions'));
        return outputMap;
    }
    
    public static Map<String, Object> hasTemporaryNewBornMember(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String, Object> hasTemporaryNewBornMemberResult = ARC_TemporaryNewborn_Utilities.hasTemporaryNewBornMember(inputData, outputMap, options);
        outputMap.put('hasTemporaryNewBornMember', hasTemporaryNewBornMemberResult.get('hasTemporaryNewBornMember'));
        return outputMap;
    }

    public static Map<String, Object> TRANSFORM_CensusMemberToUserInputs(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String,Object> result = ARC_TemporaryNewborn_Utilities.TRANSFORM_CensusMemberToUserInputs(inputData, outputMap, options);

        if(result.get('applyExtraDependentFee') != null) outputMap.put('applyExtraDependentFee', result.get('applyExtraDependentFee'));
        if(result.get('userInputs') != null) outputMap.put('userInputs', result.get('userInputs'));
        return outputMap;
    }

    public static Map<String, Object> TRANSFORM_ChooseProductSelectionData(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String,Object> result = ARC_TemporaryNewborn_Utilities.TRANSFORM_ChooseProductSelectionData(inputData, outputMap, options);

        if(result.get('LWC_ChooseProductSelectionOutput') != null) outputMap.put('LWC_ChooseProductSelectionOutput', result.get('LWC_ChooseProductSelectionOutput'));
        return outputMap;
    }

    public static Map<String, Object> populateReasons(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String,Object> result = ARC_TemporaryNewborn_Utilities.populateReasons(inputData, outputMap, options);

        if(result.get('nbChanges') != null) outputMap.put('nbChanges', result.get('nbChanges'));
        if(result.get('mapChargentOrders') != null) outputMap.put('mapChargentOrders', result.get('mapChargentOrders'));
        return outputMap;
    }

    public static Map<String, Object> getMemberBeneficiaries(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String, Object> result = ARC_TemporaryNewborn_Utilities.getMemberBeneficiaries(inputData, outputMap, options);

        if (result.get('census_members') != null) outputMap.put('census_members', result.get('census_members'));
        return outputMap;
    }

    public static Map<String, Object> getDocuSignData(Map<String, Object> inputData, Map<String, Object> outputMap, Map<String, Object> options) {
        ARC_TemporaryNewborn_Utilities.getDocuSignDataNew(inputData, outputMap, options);
        if(outputMap.get('EnvelopeInformation') != null) outputMap.put('EnvelopeInformation', outputMap.get('EnvelopeInformation'));
        if(outputMap.get('recipientStepLabel') != null) outputMap.put('recipientStepLabel', outputMap.get('recipientStepLabel'));

        return outputMap;
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

            String subjectStr = 'Please DocuSign: UHSM Program Change';
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
}