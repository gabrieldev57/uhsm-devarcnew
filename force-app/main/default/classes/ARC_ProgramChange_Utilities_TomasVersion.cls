global without sharing class ARC_ProgramChange_Utilities_TomasVersion implements vlocity_ins.VlocityOpenInterface{

    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'readMedicalQuestions') {
                readMedicalQuestions(inputMap, outputMap, options);
            }
            return true;
    }


    /*******************************************************************
    * @MethodName         :   readMedicalQuestions
    * @Description        :   Method to retrieve active members medical questions and populate new member fields on medical quesitons omniscript
    ********************************************************************/
    public static void readMedicalQuestions(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {

        Object censusData = inputMap.get('censusMembers'); // Store the value in an auxiliary variable
        List<Object> censusMembers = new List<Object>(); // Initialize as empty
        
        if (censusData instanceof List<Object>) {
        
            censusMembers = (List<Object>) censusData;

        } else if (censusData instanceof String) {
            // Populate censusMembers List with contract participant on selected contract if censusData is empty
            Id contractId = (Id) inputMap.get('oldContractId');
        
            List<ARC_ContractParticipant__c> contractParticipantsList = [SELECT Id, ARC_PersonAccount__r.Census_Member__c, ARC_PersonAccount__r.Census_Member__r.vlocity_ins__FirstName__c, ARC_PersonAccount__r.Census_Member__r.vlocity_ins__LastName__c,  ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Birthdate__c FROM ARC_ContractParticipant__c WHERE ARC_Contract__c = :contractId];
        
            // Construct objects with the data from the query
            for (ARC_ContractParticipant__c cp : contractParticipantsList) {
                if (cp.ARC_PersonAccount__r != null && cp.ARC_PersonAccount__r.Census_Member__r != null) {
                    Map<String, Object> participantData = new Map<String, Object>{
                        'vlocity_ins__FirstName__c' => cp.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__FirstName__c,
                        'vlocity_ins__LastName__c' => cp.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__LastName__c,
                        'vlocity_ins__Birthdate__c' => (cp.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Birthdate__c != null) ? cp.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Birthdate__c.format() : null,
                        'Id' => cp.ARC_PersonAccount__r.Census_Member__c,
                        'IsNewMember' => false,
                        'IsRemoveMember' => false
                    };
    
                    // Add to censusMembers list
                    censusMembers.add(participantData);
                }
            }
        }
        

        Map<String, Object> reasons = (Map<String, Object>) inputMap.get('reasons'); // Catch Program Change Reasons 
        Boolean isAddMember = (Boolean) reasons.get('addMember');
        Boolean isProgramUpgrade = (Boolean) reasons.get('programUpgrade');
        
        // Output contractor
        Map<String, Object> stepMedicalQuestions = new Map<String, Object>();

        // Map questions values to blocks
        Map<String, List<Map<String, Object>>> questionsMap = new Map<String, List<Map<String, Object>>>();

        // Use to populate arc_SelectCensusMember and arc_SelectCensusMemberCancer LWC SELECTS on the Omniscript
        List<Object> selectCensusMemberList = new List<Object>();

        if (isProgramUpgrade) {
            
            Set<Id> activeMembers = new Set<Id>();

            if (censusMembers.Size() > 0) {
                // Populate Member Names on Omniscript inputs and store active members (exclude remove members and new members) to query medical questions
                for (Object member : censusMembers) {
                    Map<String, Object> memberMap = (Map<String, Object>) member;
                    if (Boolean.valueOf(memberMap.get('IsNewMember')) == false && Boolean.valueOf(memberMap.get('IsRemoveMember')) == false) {
    
                        addMemberNameToMedicalQuestions(memberMap, questionsMap, selectCensusMemberList);
                        activeMembers.add((String) memberMap.get('Id'));
                    }
                }
            }

            // Query medical questions of active members (exclude remove members and new members)
            List<ARC_MedicalConditions__c> activemembersMedicalConditionsList = 
                        [SELECT Id, 
                            ARC_ParentsOrSiblingsDiagnosed__c, ARC_ParentsOrSiblingsDiagnosedNote__c, ARC_ParentsOrSiblingsDiagnosedDate__c, 
                            ARC_UnexplainedConditions__c, ARC_Unexplained_Conditions_Notes__c, ARC_Unexplained_Conditions_Date__c,
                            ARC_Tests__c, ARC_Tests_Notes__c, ARC_Tests_Date__c,
                            ARC_IllegalDrugsAlcohol__c, ARC_Illegal_Drugs_Alcohol_Notes__c, ARC_Illegal_Drugs_Alcohol_Date__c,
                            ARC_LicenceSuspended__c, ARC_LicenceSuspendedNote__c, ARC_LicenseSuspendedDate__c, 
                            ARC_Condition__c, ARC_OtherConditions__c,
                            ARC_Type_Of_Cancer__c, ARC_Year_Diagnosed_Cancer__c, ARC_Currently_Under_Treatment__c,
                            ARC_CensusMember__c , ARC_CensusMember__r.Name, ARC_CensusMember__r.ARC_PhysicianCity__c, ARC_CensusMember__r.ARC_PhysicianName__c, ARC_CensusMember__r.ARC_PhysicianPhone__c
                        FROM ARC_MedicalConditions__c WHERE ARC_CensusMember__c IN :activeMembers ORDER BY CreatedDate ASC];
             
            // Query consumer drug of active members (exclude remove members and new members)
            List<vlocity_ins__ConsumerDrug__c> activemembersConsumerDrugList = [SELECT Id, Name, vlocity_ins__PrescribedBy__c, vlocity_ins__MedicationStartDate__c, vlocity_ins__MedicationEndDate__c, ARC_Reason__c, ARC_Active__c, ARC_CensusMember__c, ARC_CensusMember__r.Name FROM vlocity_ins__ConsumerDrug__c WHERE ARC_CensusMember__c IN :activeMembers ORDER BY CreatedDate ASC];

            if (activemembersMedicalConditionsList.Size() > 0) {
                for (ARC_MedicalConditions__c memberMc : activemembersMedicalConditionsList) {
    
                    if (memberMc.ARC_ParentsOrSiblingsDiagnosed__c){
                        addQuestionResponse(questionsMap, 'BLK_ParentSiblingDiagnosed', 'CHKBOX_MemberParentDiagnosed', true, memberMc.ARC_CensusMember__c);
                        if(String.isNotBlank(memberMc.ARC_ParentsOrSiblingsDiagnosedNote__c)) addQuestionResponse(questionsMap, 'BLK_ParentSiblingDiagnosed', 'TXTAREA_MemberParentDiagnosed', memberMc.ARC_ParentsOrSiblingsDiagnosedNote__c, memberMc.ARC_CensusMember__c);
                        if(memberMc.ARC_ParentsOrSiblingsDiagnosedDate__c != null) addQuestionResponse(questionsMap, 'BLK_ParentSiblingDiagnosed', 'DATE_MemberParentDiagnosed', memberMc.ARC_ParentsOrSiblingsDiagnosedDate__c, memberMc.ARC_CensusMember__c);
                        // Set Radio Button for Parent Silibing to Yes
                        stepMedicalQuestions.put('RAD_ParentSiblingDiagnosed', 'Yes');
                    } 
                    if(memberMc.ARC_UnexplainedConditions__c){

                        addQuestionResponse(questionsMap, 'BLK_UnexpectedSymptoms', 'CHKBOX_UnexpectedSymptoms', true, memberMc.ARC_CensusMember__c);
                        if(String.isNotBlank(memberMc.ARC_Unexplained_Conditions_Notes__c)) addQuestionResponse(questionsMap, 'BLK_UnexpectedSymptoms', 'TXTAREA_MemberUnexpectedSymptoms', memberMc.ARC_Unexplained_Conditions_Notes__c, memberMc.ARC_CensusMember__c);
                        if(memberMc.ARC_Unexplained_Conditions_Date__c != null) addQuestionResponse(questionsMap, 'BLK_UnexpectedSymptoms', 'DATE_MemberUnexpectedSymptoms', memberMc.ARC_Unexplained_Conditions_Date__c, memberMc.ARC_CensusMember__c);
                        // Set Radio Button for Unexplained Symptoms to Yes
                        stepMedicalQuestions.put('RAD_UnexplainedSymptoms', 'Yes');
                    }
                    if(memberMc.ARC_Tests__c){

                        addQuestionResponse(questionsMap, 'BLK_PendingTests', 'CHKBOX_PendingTests', true, memberMc.ARC_CensusMember__c);
                        if(String.isNotBlank(memberMc.ARC_Tests_Notes__c)) addQuestionResponse(questionsMap, 'BLK_PendingTests', 'TXTAREA_MemberPendingTests', memberMc.ARC_Tests_Notes__c, memberMc.ARC_CensusMember__c);
                        if(memberMc.ARC_Tests_Date__c != null) addQuestionResponse(questionsMap, 'BLK_PendingTests', 'DATE_MemberPendingTests', memberMc.ARC_Tests_Date__c, memberMc.ARC_CensusMember__c);
                        // Set Radio Button for Pending Test to Yes
                        stepMedicalQuestions.put('RAD_PendingTests', 'Yes');
                    }
                    if(memberMc.ARC_IllegalDrugsAlcohol__c){

                        addQuestionResponse(questionsMap, 'BLK_Addictions', 'CHKBOX_Addictions', true, memberMc.ARC_CensusMember__c);
                        if(String.isNotBlank(memberMc.ARC_Illegal_Drugs_Alcohol_Notes__c)) addQuestionResponse(questionsMap, 'BLK_Addictions', 'TXTAREA_MemberAddictions', memberMc.ARC_Illegal_Drugs_Alcohol_Notes__c, memberMc.ARC_CensusMember__c);
                        if(memberMc.ARC_Illegal_Drugs_Alcohol_Date__c != null) addQuestionResponse(questionsMap, 'BLK_Addictions', 'DATE_MemberAddictions', memberMc.ARC_Illegal_Drugs_Alcohol_Date__c, memberMc.ARC_CensusMember__c);
                        // Set Radio Button for Addictions to Yes
                        stepMedicalQuestions.put('RAD_Addictions', 'Yes');
                    }
                    if(memberMc.ARC_LicenceSuspended__c){
                        
                        addQuestionResponse(questionsMap, 'BLK_LicenceSuspended', 'CHKBOX_LicenceSuspended', true, memberMc.ARC_CensusMember__c);
                        if(String.isNotBlank(memberMc.ARC_LicenceSuspendedNote__c)) addQuestionResponse(questionsMap, 'BLK_LicenceSuspended', 'TXTAREA_MemberLicenceSuspended', memberMc.ARC_LicenceSuspendedNote__c, memberMc.ARC_CensusMember__c);
                        if(memberMc.ARC_LicenseSuspendedDate__c != null) addQuestionResponse(questionsMap, 'BLK_LicenceSuspended', 'DATE_MemberLicenceSuspended', memberMc.ARC_LicenseSuspendedDate__c, memberMc.ARC_CensusMember__c);
                        // Set Radio Button for Licence Suspended to Yes
                        stepMedicalQuestions.put('RAD_LicenceSuspended', 'Yes');
                    }
                    
                    if(String.isNotBlank(memberMc.ARC_Condition__c)) {
                        
                        addQuestionResponse(questionsMap, 'EB_PastConditions', 'MULSEL_Conditions', memberMc.ARC_Condition__c, memberMc.ARC_CensusMember__c);
                        if(String.isNotBlank(memberMc.ARC_OtherConditions__c)) addQuestionResponse(questionsMap, 'EB_PastConditions', 'TXT_MemberOtherPastConditions', memberMc.ARC_OtherConditions__c, memberMc.ARC_CensusMember__c);                        
                        // Set Radio Button for Past Conditions to Yes
                        stepMedicalQuestions.put('RAD_PastConditions', 'Yes');
                    }
                    
                    if (String.isNotBlank(memberMc.ARC_Type_Of_Cancer__c)) {
                        
                        addQuestionResponse(questionsMap, 'EB_Cancer', 'TXT_TypeOfCancer', memberMc.ARC_Type_Of_Cancer__c, memberMc.ARC_CensusMember__c);
                        addQuestionResponse(questionsMap, 'EB_Cancer', 'TXT_MemberIdCancer', memberMc.ARC_CensusMember__c, memberMc.ARC_CensusMember__c);
                        if(String.isNotBlank(memberMc.ARC_CensusMember__r.Name)) addQuestionResponse(questionsMap, 'EB_Cancer', 'TXT_MemberNameCancer', memberMc.ARC_CensusMember__r.Name, memberMc.ARC_CensusMember__c);
                        if(memberMc.ARC_Year_Diagnosed_Cancer__c != null) addQuestionResponse(questionsMap, 'EB_Cancer', 'DATE_Cancer', memberMc.ARC_Year_Diagnosed_Cancer__c, memberMc.ARC_CensusMember__c);
                        if(memberMc.ARC_Currently_Under_Treatment__c != null)  addQuestionResponse(questionsMap, 'EB_Cancer', 'CHK_CheckCancer', memberMc.ARC_Currently_Under_Treatment__c, memberMc.ARC_CensusMember__c);
                        // Set Radio Button for Past Conditions to Yes
                        stepMedicalQuestions.put('RAD_Cancer', 'Yes');
                    }


                    if (String.isNotBlank(memberMc.ARC_CensusMember__r.ARC_PhysicianName__c)) addQuestionResponse(questionsMap, 'EB_Physicians', 'TXT_PhysicianName', memberMc.ARC_CensusMember__r.ARC_PhysicianName__c, memberMc.ARC_CensusMember__c);
                    if (String.isNotBlank(memberMc.ARC_CensusMember__r.ARC_PhysicianCity__c)) addQuestionResponse(questionsMap, 'EB_Physicians', 'TXT_PhysicianCity', memberMc.ARC_CensusMember__r.ARC_PhysicianCity__c, memberMc.ARC_CensusMember__c);
                    if (memberMc.ARC_CensusMember__r.ARC_PhysicianPhone__c != null) addQuestionResponse(questionsMap, 'EB_Physicians', 'TXT_PhysicianPhone', memberMc.ARC_CensusMember__r.ARC_PhysicianPhone__c, memberMc.ARC_CensusMember__c);
                    
                }
                
            }

            if (activemembersConsumerDrugList.Size() > 0) {
                for (vlocity_ins__ConsumerDrug__c memberCD : activemembersConsumerDrugList) {
                      
                    if(String.isNotBlank(memberCD.ARC_CensusMember__r.Name)) addQuestionResponse(questionsMap, 'ED_MemberPrescription', 'TXT_MemberName', memberCD.ARC_CensusMember__r.Name, memberCD.ARC_CensusMember__c);
                    if(String.isNotBlank(memberCD.Name)) addQuestionResponse(questionsMap, 'ED_MemberPrescription', 'TXT_NameOfMedication', memberCD.Name, memberCD.ARC_CensusMember__c);
                    if(String.isNotBlank(memberCD.vlocity_ins__PrescribedBy__c)) addQuestionResponse(questionsMap, 'ED_MemberPrescription', 'TXT_PrescribingPhysician', memberCD.vlocity_ins__PrescribedBy__c, memberCD.ARC_CensusMember__c);
                    if(memberCD.vlocity_ins__MedicationStartDate__c != null)  addQuestionResponse(questionsMap, 'ED_MemberPrescription', 'TXT_DatePrescribed', memberCD.vlocity_ins__MedicationStartDate__c, memberCD.ARC_CensusMember__c);
                    if(memberCD.vlocity_ins__MedicationEndDate__c != null)  addQuestionResponse(questionsMap, 'ED_MemberPrescription', 'TXT_DateDiscontinued', memberCD.vlocity_ins__MedicationEndDate__c, memberCD.ARC_CensusMember__c);
                    if(String.isNotBlank(memberCD.ARC_Reason__c)) addQuestionResponse(questionsMap, 'ED_MemberPrescription', 'TXT_ReasonForMedication', memberCD.ARC_Reason__c, memberCD.ARC_CensusMember__c);
                    addQuestionResponse(questionsMap, 'ED_MemberPrescription', 'TXT_MemberIdPrescription', memberCD.ARC_CensusMember__c, memberCD.ARC_CensusMember__c);
                    
                    // Set Radio Button for Prescription Medications to Yes
                    stepMedicalQuestions.put('RAD_PrescriptionMedications', 'Yes');
                }

            }

        }

        // Populate new members medical question field member name
        if (isAddMember) {
            
            if (censusMembers.Size() > 0) {
                for (Object member : censusMembers) {
                    Map<String, Object> memberMap = (Map<String, Object>) member;
        
                    if (Boolean.valueOf(memberMap.get('IsNewMember'))) {
    
                        addMemberNameToMedicalQuestions(memberMap, questionsMap, selectCensusMemberList);
                    }
                }
            }
        }
        
        // Populate Step Medical Qustions Blocks
        for (String key : questionsMap.keySet()) {
            stepMedicalQuestions.put(key, questionsMap.get(key));
        }
        
        // If Radio Buttons are null we will set them to 'No'
        if(stepMedicalQuestions.get('RAD_ParentSiblingDiagnosed') == null) stepMedicalQuestions.put('RAD_ParentSiblingDiagnosed', 'No');
        if(stepMedicalQuestions.get('RAD_UnexplainedSymptoms') == null) stepMedicalQuestions.put('RAD_UnexplainedSymptoms', 'No');
        if(stepMedicalQuestions.get('RAD_PendingTests') == null) stepMedicalQuestions.put('RAD_PendingTests', 'No');
        if(stepMedicalQuestions.get('RAD_Cancer') == null) stepMedicalQuestions.put('RAD_Cancer', 'No');
        if(stepMedicalQuestions.get('RAD_Addictions') == null) stepMedicalQuestions.put('RAD_Addictions', 'No');
        if(stepMedicalQuestions.get('RAD_LicenceSuspended') == null) stepMedicalQuestions.put('RAD_LicenceSuspended', 'No');
        if(stepMedicalQuestions.get('RAD_PastConditions') == null) stepMedicalQuestions.put('RAD_PastConditions', 'No');
        if(stepMedicalQuestions.get('RAD_PrescriptionMedications') == null) stepMedicalQuestions.put('RAD_PrescriptionMedications', 'No');

        // Save Output on STEP_MedicalQuestions
        outputMap.put('STEP_MedicalQuestions', stepMedicalQuestions);
        // Save Output for LWC Select arc_SelectCensusMember and arc_SelectCensusMemberCancer
        outputMap.put('CensusMember', selectCensusMemberList);

        //system.debug('Final OutputMap: ' + JSON.serializePretty(outputMap));
    }

    /*******************************************************************
    * @MethodName         :   addQuestionResponse
    * @Description        :   Aux method to populate input fields for the medical questions omniscript if apply
    ********************************************************************/
    private static void addQuestionResponse(Map<String, List<Map<String, Object>>> questionMap, String blockName, String fieldName, Object value, String memberId) {
        if (value == null) {
            return; // Skip null values
        }
    
        // Get the list of responses for the block or create a new one if it does not exist
        if (!questionMap.containsKey(blockName)) {
            questionMap.put(blockName, new List<Map<String, Object>>());
        }
    
        List<Map<String, Object>> responses = questionMap.get(blockName);
    
        // Check if a response already exists for the same member
        Map<String, Object> response = null;
        for (Map<String, Object> existingResponse : responses) {
            if (existingResponse.containsKey('memberId') && existingResponse.get('memberId') == memberId) {
                response = existingResponse;
                break;
            }
        }
    
        // If no response is found for this member, create a new one
        if (response == null) {
            response = new Map<String, Object>();
            response.put('memberId', memberId); // Store the member identifier
            
            responses.add(response);
        }
    
        // Add the new field to the same object in the list
        response.put(fieldName, value);
    }

    /*******************************************************************
    * @MethodName         :   addMemberNameToMedicalQuestions
    * @Description        :   Aux method to populate member name fields on Medical Questions Omniscript
    ********************************************************************/
    private static void addMemberNameToMedicalQuestions(Map<String, Object> memberMap, Map<String, List<Map<String, Object>>> questionsMap, List<Object> selectCensusMemberList ) {
        String fullName = (String) memberMap.get('vlocity_ins__FirstName__c') + ' ' + (String) memberMap.get('vlocity_ins__LastName__c');
        String memberId = (String) memberMap.get('Id');
        String memberBirthDate = (String) memberMap.get('vlocity_ins__Birthdate__c');

        // Generic responses that apply to all members name fields
        addQuestionResponse(questionsMap, 'BLK_ParentSiblingDiagnosed', 'TXT_MemberParentDiagnosed', fullName, memberId);
        addQuestionResponse(questionsMap, 'BLK_UnexpectedSymptoms', 'TXT_MemberUnexpectedSymptoms', fullName, memberId);
        addQuestionResponse(questionsMap, 'BLK_PendingTests', 'TXT_MemberPendingTests', fullName, memberId);
        addQuestionResponse(questionsMap, 'BLK_Addictions', 'TXT_MemberAddictions', fullName, memberId);
        addQuestionResponse(questionsMap, 'BLK_LicenceSuspended', 'TXT_MemberLicenceSuspended', fullName, memberId);
        addQuestionResponse(questionsMap, 'EB_PastConditions', 'TXT_MemberPastConditions', fullName, memberId);
        addQuestionResponse(questionsMap, 'EB_Physicians', 'TXT_CensusMemberName', fullName, memberId);

        Map<String, Object> selectMemberDetail = new Map<String, Object>();
        selectMemberDetail.put('CensusMemberName', fullName);
        selectMemberDetail.put('CensusMemberId', memberId);
        selectMemberDetail.put('Birthdate', memberBirthDate);

        selectCensusMemberList.add(selectMemberDetail);
    }
    
}