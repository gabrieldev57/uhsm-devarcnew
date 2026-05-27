global without sharing class ARC_TemporaryNewborn_Utilities {

    
    
    ////Main methods/////////////////////
    /////////////////////////////////////////////

    private static integer daysToAdd = 60;
    private static Integer dependentCount = 0;
    private static Map<String,Object> signerInfoMap = new Map<String,Object>();
    private static Map<String,Object> primaryMember = new Map<String,Object>();
    private static Map<String,Object> spouseMember = new Map<String,Object>();
    private static List<Object> dependents = new List<Object>();
    private static List<Object> allMemberList = new List<Object>();
    private static List<Object> newProductList = new List<Object>();
    private static List<String> templatesIdList = new List<String>();
    private static Map<String,Object> docuSignDataMap = new Map<String,Object>();
    private static Map<String,Object> docuSignOutputMap = new Map<String,Object>();
    private static Map<String,Object> docuSignOptionsMap = new Map<String,Object>();

    // private static Map<String,Object> legalGuardian = new Map<String,Object>();


    /*******************************************************************
    * @MethodName         :   hasTemporaryNewBornMember
    * @Description        :   Returns true if any census member qualifies as a temporary newborn
    *                         (current implementation: any Child under 18 years old).
    *                         Also places the result in outputMap under key 'hasTemporaryNewBornMember'.
    ********************************************************************/
    public static Map<String, Object> hasTemporaryNewBornMember(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        System.debug('inputMap ' + inputMap);
        Boolean result = false;
        String accountId = (String)inputMap.get('ContextId');
        Account accTNNewborn;
        //Date oneYearAgo = Date.today();
        Date oneYearAgo = Date.today().addYears(-1);

        Account account = [SELECT Id, Name,ARC_PrimaryMemberAccount__c,ARC_DependentRelationship__c FROM Account WHERE Id = :accountId LIMIT 1];
        System.debug('account 1' + account);

        if(account.ARC_PrimaryMemberAccount__c == null) {
           List<Account> accounts = [SELECT Id, Name,ARC_PrimaryMemberAccount__c,ARC_DependentRelationship__c,FirstName,LastName FROM Account WHERE ARC_PrimaryMemberAccount__c = :accountId AND CreatedDate > :oneYearAgo];
           System.debug('accounts 2' + accounts);
          
           for(Account acc : accounts) {
                if(acc.ARC_DependentRelationship__c != null && acc.ARC_DependentRelationship__c == 'Temporary Newborn') {
                    accTNNewborn = acc;
                    System.debug('accTNNewborn 3' + accTNNewborn);
                    break;
                }
           }
           if(accTNNewborn != null) {
                System.debug('accTNNewborn 4' + accTNNewborn);
                List<ARC_ContractParticipant__c> cps = [SELECT Id, ARC_Contract__c FROM ARC_ContractParticipant__c WHERE ARC_PersonAccount__c = :accTNNewborn.Id LIMIT 1];
                ARC_ContractParticipant__c cp = cps.isEmpty() ? null : cps[0];
                if(cp != null) {
                    result = false;
                }
                else {
                    result = true;
                }
            }
            if(accTNNewborn == null) {
                result = false;
            }
        }else {
            List<Account> accounts = [SELECT Id, Name,ARC_PrimaryMemberAccount__c,ARC_DependentRelationship__c,FirstName,LastName FROM Account WHERE ARC_PrimaryMemberAccount__c = :account.ARC_PrimaryMemberAccount__c AND CreatedDate > :oneYearAgo];
            
            for(Account acc : accounts) {
                    if(acc.ARC_DependentRelationship__c != null && acc.ARC_DependentRelationship__c == 'Temporary Newborn') {
                        accTNNewborn = acc;
                        break;
                    }
            }
            if(accTNNewborn != null) {
                System.debug('accTNNewborn 5' + accTNNewborn);
                List<ARC_ContractParticipant__c> cps = [SELECT Id, ARC_Contract__c FROM ARC_ContractParticipant__c WHERE ARC_PersonAccount__c = :accTNNewborn.Id LIMIT 1];
                ARC_ContractParticipant__c cp = cps.isEmpty() ? null : cps[0];
                if(cp != null) {
                    result = false;
                }
                else {
                    result = true;
                }
            }
            else {
                result = false;
            }
        }
        System.debug('result 5' + result);
        outputMap.put('hasTemporaryNewBornMember', result);
        outputMap.put('NBFirstName', accTNNewborn != null ? accTNNewborn.FirstName : null);
        outputMap.put('NBLastName', accTNNewborn != null ? accTNNewborn.LastName : null);
        return outputMap;
    }



    /*******************************************************************
    * @MethodName         :   readMedicalQuestions
    * @Description        :   Method to retrieve active members medical questions and populate new member fields on medical quesitons omniscript
    ********************************************************************/
    public static void populateMedicalQuestions(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {

        // Get the newborn data
        Map<String, Object> censusComponent = (Map<String, Object>) inputMap.get('STEP_AddNewborn');

        List<Object> censusMembers = new List<Object>(); // Initialize as empty
        List<Object> censusDataList = new List<Object>();

        try {
            censusDataList = (List<Object>)censusComponent.get('EB_TemporaryNewborn'); // Store the value in an auxiliary variable
        } catch(Exception e){
            Map<String, Object> censusDataMap = (Map<String, Object>)censusComponent.get('EB_TemporaryNewborn'); // Store the value in an auxiliary variable
            censusDataList.add(censusDataMap);
        }

        censusMembers = censusDataList;

        system.debug('censusMembers 1 '+ censusMembers);

        Map<Id,Id> paToNewCensusId = new Map<Id,Id>();
        
        // Output contractor
        Map<String, Object> stepMedicalQuestions = new Map<String, Object>();

        // Map questions values to blocks
        Map<String, List<Map<String, Object>>> questionsMap = new Map<String, List<Map<String, Object>>>();

        // Use to populate arc_SelectCensusMember and arc_SelectCensusMemberCancer LWC SELECTS on the Omniscript
        List<Object> selectCensusMemberList = new List<Object>();

        // Populate new members medical question field member name
        if (censusMembers.Size() > 0) {
            for (Object member : censusMembers) {
                Map<String, Object> memberMap = (Map<String, Object>) member;
                addMemberNameToMedicalQuestions(memberMap, questionsMap, selectCensusMemberList);
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
        system.debug('Final OutputMap: ' + JSON.serializePretty(outputMap));
    }

    public static void mergeMedicalQuestions(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        // Get census member list && medical questions step
        List<Object> censusMembers = (List<Object>)inputMap.get('censusMembers');
        Map<String,Object> medicalQuestions = (Map<String,Object>)inputMap.get('STEP_MedicalQuestions');
        // Output contractor
        Map<String, Object> stepMedicalQuestions = new Map<String, Object>();
        // Map questions values to blocks
        Map<String, List<Map<String, Object>>> questionsMap = new Map<String, List<Map<String, Object>>>();
        // Use to populate arc_SelectCensusMember and arc_SelectCensusMemberCancer LWC SELECTS on the Omniscript
        List<Object> selectCensusMemberList = new List<Object>();

        Set<Id> activeMembers = new Set<Id>();
        if (censusMembers.Size() > 0) {
            // Populate Member Names on Omniscript inputs and store active members (exclude remove members and new members) to query medical questions
            for (Object member : censusMembers) {
                Map<String, Object> memberMap = (Map<String, Object>) member;
                Boolean isNewMember = memberMap.containsKey('IsNewMember') ? (Boolean) memberMap.get('IsNewMember') : false;
                if (!isNewMember) activeMembers.add((String) memberMap.get('Id'));
            }
        }

        if (!activeMembers.isEmpty()) {
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
            FROM ARC_MedicalConditions__c WHERE ARC_Active__c = true AND ARC_CensusMember__c IN :activeMembers ORDER BY CreatedDate ASC];

            // Query consumer drug of active members (exclude remove members and new members)
            List<vlocity_ins__ConsumerDrug__c> activemembersConsumerDrugList = [SELECT Id, Name, vlocity_ins__PrescribedBy__c, vlocity_ins__MedicationStartDate__c, vlocity_ins__MedicationEndDate__c, ARC_Reason__c, ARC_Active__c, ARC_CensusMember__c, ARC_CensusMember__r.Name FROM vlocity_ins__ConsumerDrug__c WHERE ARC_Active__c = true AND ARC_CensusMember__c IN :activeMembers ORDER BY CreatedDate ASC];

            Integer cancerIndex = 0; 
            Integer consumerDrugIndex = 0; 

            if (activemembersMedicalConditionsList.Size() > 0) {
                for (ARC_MedicalConditions__c memberMc : activemembersMedicalConditionsList) {

                    if (memberMc.ARC_ParentsOrSiblingsDiagnosed__c){
                        addQuestionResponse(questionsMap, 'BLK_ParentSiblingDiagnosed', 'CHKBOX_MemberParentDiagnosed', true, memberMc.ARC_CensusMember__c);
                        addQuestionResponse(questionsMap, 'BLK_ParentSiblingDiagnosed', 'TXT_MemberIdParentDiagnosed', memberMc.ARC_CensusMember__c, memberMc.ARC_CensusMember__c);
                        if(String.isNotBlank(memberMc.ARC_ParentsOrSiblingsDiagnosedNote__c)) addQuestionResponse(questionsMap, 'BLK_ParentSiblingDiagnosed', 'TXTAREA_MemberParentDiagnosed', memberMc.ARC_ParentsOrSiblingsDiagnosedNote__c, memberMc.ARC_CensusMember__c);
                        if(memberMc.ARC_ParentsOrSiblingsDiagnosedDate__c != null) addQuestionResponse(questionsMap, 'BLK_ParentSiblingDiagnosed', 'DATE_MemberParentDiagnosed', memberMc.ARC_ParentsOrSiblingsDiagnosedDate__c, memberMc.ARC_CensusMember__c);
                        // Set Radio Button for Parent Silibing to Yes
                        stepMedicalQuestions.put('RAD_ParentSiblingDiagnosed', 'Yes');
                    } 
                    if(memberMc.ARC_UnexplainedConditions__c){

                        addQuestionResponse(questionsMap, 'BLK_UnexpectedSymptoms', 'CHKBOX_UnexpectedSymptoms', true, memberMc.ARC_CensusMember__c);
                        addQuestionResponse(questionsMap, 'BLK_UnexpectedSymptoms', 'TXT_MemberIdUnexpectedSymptoms', memberMc.ARC_CensusMember__c, memberMc.ARC_CensusMember__c); 
                        if(String.isNotBlank(memberMc.ARC_Unexplained_Conditions_Notes__c)) addQuestionResponse(questionsMap, 'BLK_UnexpectedSymptoms', 'TXTAREA_MemberUnexpectedSymptoms', memberMc.ARC_Unexplained_Conditions_Notes__c, memberMc.ARC_CensusMember__c);
                        if(memberMc.ARC_Unexplained_Conditions_Date__c != null) addQuestionResponse(questionsMap, 'BLK_UnexpectedSymptoms', 'DATE_MemberUnexpectedSymptoms', memberMc.ARC_Unexplained_Conditions_Date__c, memberMc.ARC_CensusMember__c);
                        // Set Radio Button for Unexplained Symptoms to Yes
                        stepMedicalQuestions.put('RAD_UnexplainedSymptoms', 'Yes');
                    }
                    if(memberMc.ARC_Tests__c){

                        addQuestionResponse(questionsMap, 'BLK_PendingTests', 'CHKBOX_PendingTests', true, memberMc.ARC_CensusMember__c);
                        addQuestionResponse(questionsMap, 'BLK_PendingTests', 'TXT_MemberIdPendingTests', memberMc.ARC_CensusMember__c, memberMc.ARC_CensusMember__c);
                        if(String.isNotBlank(memberMc.ARC_Tests_Notes__c)) addQuestionResponse(questionsMap, 'BLK_PendingTests', 'TXTAREA_MemberPendingTests', memberMc.ARC_Tests_Notes__c, memberMc.ARC_CensusMember__c);
                        if(memberMc.ARC_Tests_Date__c != null) addQuestionResponse(questionsMap, 'BLK_PendingTests', 'DATE_MemberPendingTests', memberMc.ARC_Tests_Date__c, memberMc.ARC_CensusMember__c);
                        // Set Radio Button for Pending Test to Yes
                        stepMedicalQuestions.put('RAD_PendingTests', 'Yes');
                    }
                    if(memberMc.ARC_IllegalDrugsAlcohol__c){

                        addQuestionResponse(questionsMap, 'BLK_Addictions', 'CHKBOX_Addictions', true, memberMc.ARC_CensusMember__c);
                        addQuestionResponse(questionsMap, 'BLK_Addictions', 'TXT_MemberIdAddictions', memberMc.ARC_CensusMember__c, memberMc.ARC_CensusMember__c);
                        if(String.isNotBlank(memberMc.ARC_Illegal_Drugs_Alcohol_Notes__c)) addQuestionResponse(questionsMap, 'BLK_Addictions', 'TXTAREA_MemberAddictions', memberMc.ARC_Illegal_Drugs_Alcohol_Notes__c, memberMc.ARC_CensusMember__c);
                        if(memberMc.ARC_Illegal_Drugs_Alcohol_Date__c != null) addQuestionResponse(questionsMap, 'BLK_Addictions', 'DATE_MemberAddictions', memberMc.ARC_Illegal_Drugs_Alcohol_Date__c, memberMc.ARC_CensusMember__c);
                        // Set Radio Button for Addictions to Yes
                        stepMedicalQuestions.put('RAD_Addictions', 'Yes');
                    }
                    if(memberMc.ARC_LicenceSuspended__c){
                        
                        addQuestionResponse(questionsMap, 'BLK_LicenceSuspended', 'CHKBOX_LicenceSuspended', true, memberMc.ARC_CensusMember__c);
                        addQuestionResponse(questionsMap, 'BLK_LicenceSuspended', 'TXT_MemberIdLicenceSuspended', memberMc.ARC_CensusMember__c, memberMc.ARC_CensusMember__c);
                        if(String.isNotBlank(memberMc.ARC_LicenceSuspendedNote__c)) addQuestionResponse(questionsMap, 'BLK_LicenceSuspended', 'TXTAREA_MemberLicenceSuspended', memberMc.ARC_LicenceSuspendedNote__c, memberMc.ARC_CensusMember__c);
                        if(memberMc.ARC_LicenseSuspendedDate__c != null) addQuestionResponse(questionsMap, 'BLK_LicenceSuspended', 'DATE_MemberLicenceSuspended', memberMc.ARC_LicenseSuspendedDate__c, memberMc.ARC_CensusMember__c);
                        // Set Radio Button for Licence Suspended to Yes
                        stepMedicalQuestions.put('RAD_LicenceSuspended', 'Yes');
                    }
                    
                    if(String.isNotBlank(memberMc.ARC_Condition__c)) {
                        
                        addQuestionResponse(questionsMap, 'EB_PastConditions', 'MULSEL_Conditions', memberMc.ARC_Condition__c, memberMc.ARC_CensusMember__c);
                        addQuestionResponse(questionsMap, 'EB_PastConditions', 'TXT_MemberIdPastConditions', memberMc.ARC_CensusMember__c, memberMc.ARC_CensusMember__c);
                        if(String.isNotBlank(memberMc.ARC_OtherConditions__c)) addQuestionResponse(questionsMap, 'EB_PastConditions', 'TXT_MemberOtherPastConditions', memberMc.ARC_OtherConditions__c, memberMc.ARC_CensusMember__c);                        
                        // Set Radio Button for Past Conditions to Yes
                        stepMedicalQuestions.put('RAD_PastConditions', 'Yes');
                    }
                    
                    if (String.isNotBlank(memberMc.ARC_Type_Of_Cancer__c)) {

                        addQuestionResponse(questionsMap, 'LWC_SelectCensusMemberCancer', 'SelectedCensusMemberId', memberMc.ARC_CensusMember__c, memberMc.ARC_CensusMember__c);
                        addQuestionResponse(questionsMap, 'LWC_SelectCensusMemberCancer', 'SelectedCensusMemberName', memberMc.ARC_CensusMember__r.Name, memberMc.ARC_CensusMember__c);                        
                        
                        // Is possible to have multiple record of cancer per member
                        addQuestionResponseList(questionsMap, 'EB_Cancer', 'TXT_TypeOfCancer', memberMc.ARC_Type_Of_Cancer__c, memberMc.ARC_CensusMember__c, cancerIndex);
                        addQuestionResponseList(questionsMap, 'EB_Cancer', 'TXT_MemberIdCancer', memberMc.ARC_CensusMember__c, memberMc.ARC_CensusMember__c, cancerIndex);
                        if(String.isNotBlank(memberMc.ARC_CensusMember__r.Name)) addQuestionResponseList(questionsMap, 'EB_Cancer', 'TXT_MemberNameCancer', memberMc.ARC_CensusMember__r.Name, memberMc.ARC_CensusMember__c, cancerIndex);
                        if(memberMc.ARC_Year_Diagnosed_Cancer__c != null) addQuestionResponseList(questionsMap, 'EB_Cancer', 'DATE_Cancer', memberMc.ARC_Year_Diagnosed_Cancer__c, memberMc.ARC_CensusMember__c, cancerIndex);
                        if(memberMc.ARC_Currently_Under_Treatment__c != null)  addQuestionResponseList(questionsMap, 'EB_Cancer', 'CHK_CheckCancer', memberMc.ARC_Currently_Under_Treatment__c, memberMc.ARC_CensusMember__c, cancerIndex);
                        // Set Radio Button for Past Conditions to Yes
                        stepMedicalQuestions.put('RAD_Cancer', 'Yes');
                        cancerIndex++;
                    }

                    if (String.isNotBlank(memberMc.ARC_CensusMember__r.ARC_PhysicianName__c)) addQuestionResponse(questionsMap, 'EB_Physicians', 'TXT_PhysicianName', memberMc.ARC_CensusMember__r.ARC_PhysicianName__c, memberMc.ARC_CensusMember__c);
                    if (String.isNotBlank(memberMc.ARC_CensusMember__r.ARC_PhysicianCity__c)) addQuestionResponse(questionsMap, 'EB_Physicians', 'TXT_PhysicianCity', memberMc.ARC_CensusMember__r.ARC_PhysicianCity__c, memberMc.ARC_CensusMember__c);
                    if (memberMc.ARC_CensusMember__r.ARC_PhysicianPhone__c != null) addQuestionResponse(questionsMap, 'EB_Physicians', 'TXT_PhysicianPhone', memberMc.ARC_CensusMember__r.ARC_PhysicianPhone__c, memberMc.ARC_CensusMember__c);
                    
                }
            }

            if (activemembersConsumerDrugList.Size() > 0) {
                for (vlocity_ins__ConsumerDrug__c memberCD : activemembersConsumerDrugList) {
                    // Is possible to have multiple record of prescription per member
                    if(String.isNotBlank(memberCD.ARC_CensusMember__r.Name)) addQuestionResponseList(questionsMap, 'ED_MemberPrescription', 'TXT_MemberName', memberCD.ARC_CensusMember__r.Name, memberCD.ARC_CensusMember__c, consumerDrugIndex);
                    if(String.isNotBlank(memberCD.Name)) addQuestionResponseList(questionsMap, 'ED_MemberPrescription', 'TXT_NameOfMedication', memberCD.Name, memberCD.ARC_CensusMember__c, consumerDrugIndex);
                    if(String.isNotBlank(memberCD.vlocity_ins__PrescribedBy__c)) addQuestionResponseList(questionsMap, 'ED_MemberPrescription', 'TXT_PrescribingPhysician', memberCD.vlocity_ins__PrescribedBy__c, memberCD.ARC_CensusMember__c, consumerDrugIndex);
                    if(memberCD.vlocity_ins__MedicationStartDate__c != null)  addQuestionResponseList(questionsMap, 'ED_MemberPrescription', 'TXT_DatePrescribed', memberCD.vlocity_ins__MedicationStartDate__c, memberCD.ARC_CensusMember__c, consumerDrugIndex);
                    if(memberCD.vlocity_ins__MedicationEndDate__c != null)  addQuestionResponseList(questionsMap, 'ED_MemberPrescription', 'TXT_DateDiscontinued', memberCD.vlocity_ins__MedicationEndDate__c, memberCD.ARC_CensusMember__c, consumerDrugIndex);
                    if(String.isNotBlank(memberCD.ARC_Reason__c)) addQuestionResponseList(questionsMap, 'ED_MemberPrescription', 'TXT_ReasonForMedication', memberCD.ARC_Reason__c, memberCD.ARC_CensusMember__c, consumerDrugIndex);
                    addQuestionResponseList(questionsMap, 'ED_MemberPrescription', 'TXT_MemberIdPrescription', memberCD.ARC_CensusMember__c, memberCD.ARC_CensusMember__c,consumerDrugIndex);
                    addQuestionResponse(questionsMap, 'LWC_SelectCensusMember', 'SelectedCensusMemberId', memberCD.ARC_CensusMember__c, memberCD.ARC_CensusMember__c);
                    addQuestionResponse(questionsMap, 'LWC_SelectCensusMember', 'SelectedCensusMemberName', memberCD.Name, memberCD.ARC_CensusMember__c);
                    
                    // Set Radio Button for Prescription Medications to Yes
                    stepMedicalQuestions.put('RAD_PrescriptionMedications', 'Yes');
                    consumerDrugIndex++;
                }
            } 
        }

        // Populate Step Medical Qustions Blocks
        if (!questionsMap.isEmpty()) {
            for (String key : questionsMap.keySet()) {
                if (medicalQuestions.containsKey(key) && medicalQuestions.get(key) != null) {
                    Map<String,Object> newbornQuestionMap = (Map<String,Object>)medicalQuestions.get(key);
                    questionsMap.get(key).add(newbornQuestionMap);
                }
                stepMedicalQuestions.put(key, questionsMap.get(key));
            }
        } else {
            return;
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

        outputMap.put('carryOverMedicalQuestions', stepMedicalQuestions);
    }


    /**
     * Transform the census members to user inputs
     * @param {Map<String,Object>} inputMap - The input map.
     * @param {Map<String,Object>} outputMap - The output map.
     * @param {Map<String,Object>} options - The options map.
     * @returns {Map<String,Object>} - The output map.
     */
    public static Map<String,Object> TRANSFORM_CensusMemberToUserInputs(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String,Object> eligibleContractInfo = (Map<String,Object>)inputMap.get('EligibleContractInfo');
        String activeCensusId = (String)inputMap.get('ActiveCensusId');
        String censusId = (String)eligibleContractInfo.get('CensusId');
        String contractId = (String)eligibleContractInfo.get('Id');
        Boolean isSpinOff = ((String)eligibleContractInfo.get('Reasons')).contains('Spin Off') && ((String)eligibleContractInfo.get('Status')).contains('Awaiting') && censusId != activeCensusId ? true : false;
       
        system.debug('inputMap ' + inputMap);
        system.debug('EffectiveDate ' + inputMap.get('EffectiveDate'));
        Date effectiveDate = (String)inputMap.get('EffectiveDate') != null && String.isNotBlank((String)inputMap.get('EffectiveDate')) ? Date.valueOf((String)inputMap.get('EffectiveDate')): null;
        
        List<Object> oldProducts;
        if (inputMap.get('oldProducts') instanceof List<Object>) {
            oldProducts = (List<Object>)inputMap.get('oldProducts');
        }
        Map<String, Object> medical = (Map<String, Object>)oldProducts[0];
        String medicalCode = (String)medical.get('ProductCode');

        Map<Id, String> censusMemberRelationshipMap = new Map<Id, String>();
        // Iterate over each CP and map their relationships to census member Id
        for (ARC_ContractParticipant__c cp : [
            SELECT Id, ARC_PersonAccount__r.Census_Member__c, ARC_Relationship__c
            FROM ARC_ContractParticipant__c
            WHERE ARC_Contract__c = :contractId AND ARC_Relationship__c != null
        ]) {
            String cpRelationship = cp.ARC_Relationship__c;
            censusMemberRelationshipMap.put(cp.ARC_PersonAccount__r.Census_Member__c, cpRelationship);
        }

        Set<Id> censusMemberIds = getContractMemberIds(contractId, censusId, isSpinOff);
        // Query active census members
        List<Map<String, Object>> census_members_list = new List<Map<String, Object>>();
        for (vlocity_ins__GroupCensusMember__c member : [
            SELECT Id, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, ARC_MiddleInitial__c, vlocity_ins__Birthdate__c, 
                   vlocity_ins__Gender__c, ARC_Relationship__c, vlocity_ins__Email__c, ARC_Phone__c, vlocity_ins__SocialSecurityNumber__c, 
                   ARC_HeightFeet__c, ARC_HeightInches__c, ARC_Weight__c, ARC_PhysicalAddressCity__c, ARC_PhysicalAddressState__c, 
                   ARC_PhysicalAddressStreet__c, ARC_PhysicalAddressZipCode__c, ARC_UpdateAllAddress__c, ARC_Age__c, ARC_Smoker__c, 
                   vlocity_ins__IsPrimaryMember__c,ARC_isPregnant__c, vlocity_ins__ContactId__r.AccountId, vlocity_ins__ContactId__c, vlocity_ins__MemberIdentifier__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE Id IN :censusMemberIds
            ORDER BY vlocity_ins__IsPrimaryMember__c DESC, vlocity_ins__IsSpouse__c DESC, vlocity_ins__Birthdate__c ASC
        ]) {
            Map<String,Object> member_map = createMemberMap (member, censusMemberRelationshipMap, isSpinOff);
            census_members_list.add(member_map);
        }

        // Variables for User Inputs
        List<Map<String, Object>> user_input_list = new List<Map<String, Object>>();
        Boolean hasPrimary = false;
        Boolean hasSpouse = false;
        Integer dependentCount = 0;
        Integer oldestAge = 0;
        String familyAddressState = '';
        String familyAddressCity = '';
        String familyAddressStreet = '';
        String familyAddressZipCode = '';

        for (Map<String,Object> cm : census_members_list) {
            Map<String,Object> censusMemberMap = (Map<String,Object>)cm;
            Map<String, Object> user_input = new Map<String, Object>();
            String cmRelationship = (String)censusMemberMap.get('ARC_Relationship__c');
            Integer age;

            if (effectiveDate != null){
                age = calculateAge((Date)censusMemberMap.get('vlocity_ins__Birthdate__c'), effectiveDate.addDays(daysToAdd));
            } else age = ((Decimal)censusMemberMap.get('ARC_Age__c')).intValue();

            // Track oldest member
            oldestAge = age > oldestAge ? age : oldestAge;

            user_input.put('Id', (String)censusMemberMap.get('Id'));
            user_input.put('RF_Census.CM_Age', age);
            user_input.put('RF_Census.CRF_PrimaryMemberDOB', String.valueOf((Date)censusMemberMap.get('vlocity_ins__Birthdate__c')));
            user_input.put('RF_Census.CM_State', (String)censusMemberMap.get('ARC_PhysicalAddressState__c'));
            user_input.put('RF_Census.CM_IsPrimary', cmRelationship == 'Primary' ? true : false);
            user_input.put('RF_Census.CM_Relationship', cmRelationship);
            user_input.put('RF_Census.CM_Smoker', (Boolean)censusMemberMap.get('ARC_Smoker__c') == true ? true : false);
            user_input.put('RF_Census.CM_Pregnant', (Boolean)censusMemberMap.get('ARC_isPregnant__c') == true ? true : false);
            user_input.put('RF_Census.CM_FirstName', (String)censusMemberMap.get('vlocity_ins__FirstName__c'));
            user_input.put('RF_Census.CM_LastName', (String)censusMemberMap.get('vlocity_ins__LastName__c'));
            user_input.put('IsRemoveMember', false);
            user_input.put('IsNewMember', false);
            user_input.put('IsAddExistingMember', false);

            user_input_list.add(user_input);

            if (cmRelationship == 'Primary') {
                hasPrimary = true;
                familyAddressState = (String)censusMemberMap.get('ARC_PhysicalAddressState__c');
                familyAddressCity = (String)censusMemberMap.get('ARC_PhysicalAddressCity__c');
                familyAddressStreet = (String)censusMemberMap.get('ARC_PhysicalAddressStreet__c');
                familyAddressZipCode = (String)censusMemberMap.get('ARC_PhysicalAddressZipCode__c');
            } else {
                dependentCount++;
                hasSpouse = cmRelationship == 'Spouse' ? true : hasSpouse;
                familyAddressState = familyAddressState == '' ? familyAddressState : (String)censusMemberMap.get('ARC_PhysicalAddressState__c');
                familyAddressCity = familyAddressCity == '' ? familyAddressCity : (String)censusMemberMap.get('ARC_PhysicalAddressCity__c');
                familyAddressStreet = familyAddressStreet == '' ? familyAddressStreet : (String)censusMemberMap.get('ARC_PhysicalAddressStreet__c');
                familyAddressZipCode = familyAddressZipCode == '' ? familyAddressZipCode : (String)censusMemberMap.get('ARC_PhysicalAddressZipCode__c');
            }
        }

        // Get added newborn members
        String familyAddress = String.join(new List<String>{familyAddressStreet, familyAddressCity, familyAddressState, familyAddressZipCode},', ');
        Object addedNewborn = inputMap.get('addedNewborn');
        List<Object> newbornList = new List<Object>();
        if (addedNewborn instanceOf List<Object>) {
            newbornList = (List<Object>)addedNewborn;
        } else {
            newbornList.add((Map<String,Object>)addedNewborn);
        }
        
        for (Object newborn : newbornList) {
            Map<String,Object> newbornMap = (Map<String,Object>)newborn;
            Map<String, Object> user_input = new Map<String, Object>();
            user_input.put('Id', newbornMap.get('Id'));
            user_input.put('RF_Census.CM_Age', 0);
            user_input.put('RF_Census.CRF_PrimaryMemberDOB', newbornMap.get('vlocity_ins__Birthdate__c'));
            user_input.put('RF_Census.CM_State', familyAddressState);
            user_input.put('RF_Census.CM_IsPrimary', false);
            user_input.put('RF_Census.CM_Relationship', 'Child');
            user_input.put('RF_Census.CM_Smoker', false);
            user_input.put('RF_Census.CM_Pregnant', false);
            user_input.put('RF_Census.CM_FirstName', newbornMap.get('vlocity_ins__FirstName__c'));
            user_input.put('RF_Census.CM_LastName', newbornMap.get('vlocity_ins__LastName__c'));
            user_input.put('IsRemoveMember', false);
            user_input.put('IsNewMember', true);
            user_input.put('IsAddExistingMember', false);

            dependentCount++;
            user_input_list.add(user_input);

            // Map newborns to census members node
            Map<String, Object> censusNewbornMap = new Map<String, Object>{
                'Id' => newbornMap.get('Id'),
                'vlocity_ins__FirstName__c' => newbornMap.get('vlocity_ins__FirstName__c'),
                'vlocity_ins__LastName__c' => newbornMap.get('vlocity_ins__LastName__c'),
                'PersonAccountId' => '',
                'PersonContactId' => '',
                'vlocity_ins__MemberIdentifier__c' => '',
                'ARC_MiddleInitial__c' => newbornMap.get('ARC_MiddleInitial__c'),
                'vlocity_ins__Birthdate__c' => newbornMap.get('vlocity_ins__Birthdate__c'),
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Age__c' => 0,
                'vlocity_ins__SocialSecurityNumber__c' => newbornMap.get('vlocity_ins__SocialSecurityNumber__c'),
                'showSSN' => 'password',
                'ARC_HeightFeet__c' => newbornMap.get('ARC_HeightFeet__c'),
                'ARC_HeightInches__c' => newbornMap.get('ARC_HeightInches__c'),
                'ARC_Weight__c' => newbornMap.get('ARC_Weight__c'),
                'ARC_Smoker__c' => false,
                'ARC_PhysicalAddressCity__c' => familyAddressCity,
                'ARC_PhysicalAddressState__c' => familyAddressState,
                'ARC_PhysicalAddressStreet__c' => familyAddressStreet,
                'ARC_PhysicalAddressZipCode__c' => familyAddressZipCode,
                'ARC_Address__c' => familyAddress,
                'IsDependent' => true,
                'individual_errors' => new List<String>(),
                'IsNewMember' => true,
                'IsRemoveMember' => false,
                'ShowMember' => true,
                'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                'DISABLE_INPUT_FIELDS' => false,
                'ARC_Phone__c' => '',
                'vlocity_ins__Email__c' => '',
                'ARC_isPregnant__c' => false,
                'ARC_Relationship__c' => 'Child',
                'vlocity_ins__Gender__c' => newbornMap.get('vlocity_ins__Gender__c')
            };
            census_members_list.add(censusNewbornMap);
        }

        // Sort the list: Primary first, Spouse second, Child last
        user_input_list.sort(new RelationshipComparator());

        Integer extraDependents = hasSpouse == true ? Math.max(dependentCount - 4, 0) : Math.max(dependentCount - 3, 0);
       
        for (Map<String, Object> ui : user_input_list) {
            Map<String,Object> user_input = (Map<String,Object>)ui;
            user_input.put('RF_Census.CRF_ExtraDependants', extraDependents);
            user_input.put('RF_Census.CRF_PrimaryMemberAge', oldestAge);
            user_input.put('RF_Census.CRF_Dependants', dependentCount);    
            user_input.put('RF_Census.CM_ProductCode', medicalCode);
        }

        Boolean applyExtraDependentFee = extraDependents > 0 ? true : false;
        outputMap.put('applyExtraDependentFee', applyExtraDependentFee);
        outputMap.put('userInputs', user_input_list);
        outputMap.put('census_members', census_members_list);

        return outputMap;
    }

    /**
     * Get the DocuSign related data 
     * @param {List<Object>} census_members - The census members.
     * @returns {Map<String, Object>} - DocuSign data.
     */
    public static void getDocuSignDataNew(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        List<Object> census_members = inputMap.containsKey('census_members') ? (List<Object>)inputMap.get('census_members') : new List<Object>();
        String recipientStepLabel;
        if (!census_members.isEmpty() && census_members != null ) {
            for (Object censusMember : census_members) {
                Map<String,Object> cm = transformMemberMapKeys((Map<String,Object>)censusMember);
                String memberRelationship = (String)cm.get('Relationship');
                if ((Boolean)cm.get('IsRemoveMember')) continue;
                if (memberRelationship == 'Primary') {
                    primaryMember = cm;
                    recipientStepLabel = (String)cm.get('FirstName') + ' ' + (String)cm.get('LastName') + ' - ' + (String)cm.get('Email');
                    signerInfoMap.put('recipientId', '1');
                    signerInfoMap.put('name', (String)cm.get('FirstName') + ' ' + (String)cm.get('LastName'));
                    signerInfoMap.put('email', (String)cm.get('Email'));
                    signerInfoMap.put('deliveryMethod', 'Email');
                    signerInfoMap.put('roleName', 'Primary');
                } 
                if (memberRelationship == 'Spouse') spouseMember = cm;
                if (memberRelationship == 'Child') dependents.add(cm);
                dependentCount = memberRelationship == 'Primary' || memberRelationship == 'Spouse' ? dependentCount : dependentCount + 1;
                allMemberList.add(cm);
            }
        }
        
        Map<String,Object> memberInfo = new Map<String,Object>();
        memberInfo.put('primaryMember', primaryMember);
        memberInfo.put('spouseMember', !spouseMember.isEmpty() ? spouseMember : null);
        if (!dependents.isEmpty() && dependents.size() > 0) memberInfo.put('dependentMembers', dependents);

        // Get medical program complete map
        newProductList = (List<Object>)inputMap.get('NewProductList');
        Map<String,Object> medicalProgramMap = new Map<String,Object>();
        System.debug('newProductList:'+ newProductList);
        for (Object product : newProductList) {
            System.debug('productMap'+((Map<String,Object>)product).get('selectedProduct'));
            Map<String,Object> productMap = (Map<String,Object>)((Map<String,Object>)product).get('selectedProduct');
            if ((String)productMap.get('Type__c') == 'Medical') medicalProgramMap = (Map<String,Object>)product;
        }

        //Build DocuSign map
        Map<String,Object> nbChangesMap = (Map<String,Object>)inputMap.get('nbChanges');
        nbChangesMap.put('pcReasonsString', nbChangesMap.get('nbReasonsString'));
        nbChangesMap.put('feeApplicable', (Boolean)nbChangesMap.get('feeApplicable') == true ? true : false);
        nbChangesMap.put('feeAmount', (Boolean)nbChangesMap.get('feeApplicable') == true ? Integer.valueOf(nbChangesMap.get('newFeeAmount')) : Integer.valueOf(nbChangesMap.get('feeAmount')));
        nbChangesMap.put('pcReasons', nbChangesMap.get('nbReasons'));
        nbChangesMap.put('createNewContract', true);

        String contractId = (String)((Map<String,Object>)((Map<String,Object>)inputMap.get('EligibleContract')).get('ContractInfo')).get('Id');

        Map<String,Object> docuSignMap = new Map<String,Object>();
        docuSignMap.put('Hipaa', new List<Object>());
        docuSignMap.put('Medicare', null);
        docuSignMap.put('NewProductList', inputMap.get('NewProductList'));
        docuSignMap.put('OldProductList', inputMap.get('OldProductList'));
        docuSignMap.put('PlanSummary', inputMap.get('PlansSummary'));
        //docuSignMap.put('PlanSummary', inputMap.get('PlanSummary'));
        docuSignMap.put('STEP_MedicalQuestions', inputMap.containsKey('carryOverMedicalQuestions') ? inputMap.get('carryOverMedicalQuestions') : inputMap.get('STEP_MedicalQuestions'));
        docuSignMap.put('STEP_SignTheDocument', inputMap.get('STEP_SignTheDocument'));
        docuSignMap.put('Step_PaymentChangeFee', inputMap.get('Step_PaymentChangeFee'));
        docuSignMap.put('pcChanges', nbChangesMap);
        docuSignMap.put('userId', String.valueOf(inputMap.get('userId')));
        docuSignMap.put('SelectedContractInfo', new Map<String,Object>{
            'ContractID' => contractId
        });

        docuSignDataMap.put('DocuSign', docuSignMap);
        docuSignDataMap.put('MembersInfo', memberInfo);
        docuSignDataMap.put('MembersList', census_members);
        docuSignDataMap.put('EffectiveDate', (String)inputMap.get('EffectiveDate'));
        docuSignDataMap.put('allMembersInfo', allMemberList);
        docuSignDataMap.put('primaryState', (String)primaryMember.get('State'));
        docuSignDataMap.put('newMedicalProduct', medicalProgramMap);
        docuSignDataMap.put('UpdateType', 'Add Newborn');
        
        System.debug('docuSignDataMap:'+ docuSignDataMap);
        System.debug('docuSignDataMap:'+ docuSignDataMap.get('DocuSign'));

        // GET ALL THE REQUIRED TEMPLATES
        getDocuSignTemplateIds();

        // MAP ALL THE PROGRAM CHANGE INFORMATION
        ARC_ProgramChange_DocuSign.DocuSignDataTransform(docuSignDataMap, docuSignOutputMap, docuSignOptionsMap);

        System.debug('OUTPUT MAP: ' + docuSignOutputMap);
        System.debug('SIGNER LIST: ' + new List<Object>{signerInfoMap});
        System.debug('TEMPLATES IDS LIST: ' + templatesIdList);
        Map<String,Object> envelopeMap = new Map<String,Object>{
            'signerList' => new List<Object>{signerInfoMap}
            ,
            'templateIdList' => templatesIdList
            ,
            'tabs' => docuSignOutputMap.get('tabs')
        };
        outputMap.put('EnvelopeInformation', envelopeMap);
        outputMap.put('recipientStepLabel', recipientStepLabel);
    }

    /**************************************************************************
    * @MethodName         :   getDocuSignTemplateIds
    * @Description        :   method to get the templates than need to be used
    ***************************************************************************/
    private static void  getDocuSignTemplateIds() {
        System.debug('Getting DocuSign templates...');

        Integer primaryAge = (Integer)primaryMember.get('Age'); System.debug('Primary Age: ' + primaryAge);
        Boolean isChildFamily = primaryAge < 18 ? true : false; System.debug('isChildFamily: ' + isChildFamily);
        Integer dependents = dependentCount; System.debug('Dependents: ' + dependents);
        String primaryState = (String)primaryMember.get('State'); System.debug('Primary State: ' + primaryState);
        String medicalPlanName = '';

        for (Object product : newProductList) {
            Map<String,Object> productMap = (Map<String,Object>)((Map<String,Object>)product).get('selectedProduct');
            if ((String)productMap.get('Type__c') == 'Medical') medicalPlanName = (String)productMap.get('Name');
        }
        System.debug('Medical Plan Name: ' + medicalPlanName); 
        String programType = medicalPlanName.contains('Legacy') ? 'Senior' : medicalPlanName.contains('Premier') ? 'Premier' : medicalPlanName.contains('Access') ? 'Essential' : 'Enhanced';
        System.debug('Program Type: ' + programType);
        Boolean isLegacy = medicalPlanName.contains('Legacy') ? true : false;

        // Section order map
        Map<String,Integer> orderMap = new Map<String,Integer> {
            'ProgramChange' => 1,
            'Application' => 2,
            'Program' => 3,
            'Beneficiaries' => 4,
            'Payment' => 5, 
            'State' => 6
        };

        List<String> clausesList = new List<String>();
        for (String section : orderMap.keySet()) {
            String sectionStr = '(ARC_Section__c = ' + '\'' + section +'\' ';
            if (section == 'ProgramChange') {
                sectionStr += 'AND ARC_BusinessSegment__c = \'IndividualAndFamily\'';
            } else if (section == 'Application') {
                sectionStr += 'AND ARC_BusinessSegment__c = \'IndividualAndFamily\' AND ARC_MinDependents__c <= ' + dependents + ' AND ARC_MaxDependents__c >= ' + dependents + ' AND ARC_ChildOnly__c = ' + isChildFamily + ' AND ARC_IsLegacy__c = ' + isLegacy;
            } else if (section == 'Program' || section == 'Beneficiaries') {
                sectionStr += 'AND ARC_ProgramType__c = \'' + programType + '\'';
            } else if (section == 'State') {
                sectionStr += 'AND ARC_BusinessSegment__c = \'IndividualAndFamily\' AND ARC_State__c = \'' + primaryState + '\'';
            }
            sectionStr += ') \n';
            clausesList.add(sectionStr);
        }

        // Query
        String queryStr = 'SELECT Id, ARC_TemplateName__c, ARC_Section__c FROM ARC_DocuSignCompositeTemplates__c '; // Base query string
        if (clausesList != null && !clausesList.isEmpty()) {
            String allClausesStr = String.join(clausesList, ' OR ');
            queryStr += 'WHERE ' + allClausesStr;
        }
        System.debug('Query String: ' + queryStr);

        List<ARC_DocuSignCompositeTemplates__c> compTemplates = Database.query(queryStr);
        List<String> templatesList = new List<String>();
        Map<Integer,String> orderToTemplateNameMap = new Map<Integer,String>();
        for (ARC_DocuSignCompositeTemplates__c compTemplate : compTemplates) {
            String templateName = compTemplate.ARC_TemplateName__c;
            orderToTemplateNameMap.put(orderMap.get(compTemplate.ARC_Section__c), templateName);
            templatesList.add(templateName);
        }
        List<vlocity_ins__VlocityDocuSignTemplate__c> templates = [
            SELECT Id, Name, vlocity_ins__templateidentifier__c
            FROM vlocity_ins__VlocityDocuSignTemplate__c
            WHERE Name IN :templatesList
        ];

        // Order the vlocity templates in the correct seciton order
        Map<String,String> tempNameToTempId = new Map<String,String>();
        for (vlocity_ins__VlocityDocuSignTemplate__c temp : templates) {
            String tempName = temp.Name;
            tempNameToTempId.put(tempName, temp.vlocity_ins__templateidentifier__c);
        }
        for (Integer i = 1 ; i <= orderMap.values().size() ; i++) {
            String tempNameToAdd = orderToTemplateNameMap.get(i);
            System.debug('Template ' + i + ': ' + tempNameToAdd);
            if (tempNameToAdd != null) templatesIdList.add(tempNameToTempId.get(tempNameToAdd));
        }
        System.debug('Final template ID list: ' + templatesIdList);
    }

        /**
    * Method to transform data of member family and send it to calculate price lwc
     * @param {Map<String,Object>} inputMap - The input map.
     * @param {Map<String,Object>} outputMap - The output map.
     * @param {Map<String,Object>} options - The options map.
     * @returns {Map<String,Object>} - The output map.
    */
    public static Map<String,Object> TRANSFORM_ChooseProductSelectionData(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        List<Object> oldProducts = (List<Object>)inputMap.get('oldProducts');
        List<Object> userInputs = (List<Object>)inputMap.get('userInputs'); 
        Map<String,Integer> ageMembersMap = getOldestAgeMap(userInputs);
        Integer oldestMemberAge = (Integer)ageMembersMap.get('oldestAge');
        System.debug('oldProduct'+  oldProducts[0]);
        Map<String, Object> medicalProduct = (Map<String, Object>)oldProducts[0];
        System.debug('medicalProduct'+ medicalProduct);
        System.debug('ProductCode'+ (String)medicalProduct.get('ProductCode'));
        System.debug('premierSelected'+ ((String)medicalProduct.get('ProductCode')).contains('Premier'));
        
        Boolean premierSelected = ((String)medicalProduct.get('ProductCode')).contains('Premier');

        if (oldProducts != null && !oldProducts.isEmpty()) {
            String oldestMemberRelationShip;
            List<Map<String,Object>> products_list = new List<Map<String,Object>>();
            for (Object product_object : oldProducts) {
                Set<String> newMemberIds = new Set<String>();
                Map<String,Object> product = (Map<String,Object>)product_object;
                
                Map<String, Object> product_map = new Map<String, Object>{'selectedProduct' => new Map<String,Object>{'Id' => (String)product.get('productId')}, 'userInputs' => new List<Map<String,Object>>()};

                Boolean hasPrimary = false;
                Boolean hasOldestMember = false;

                // We need to count relationship member per product to set coverage on Ancillaries
                Integer countPrimary = 0;
                Integer countSpouse = 0;
                Integer countChilds = 0;

                for (Object user_input_object : userInputs) {
                    Map<String,Object> user_input = new Map<String,Object>((Map<String,Object>)user_input_object);

                    for (Object census_member_object : (List<Object>)product.get('census_members')) {
                        Map<String,Object> census_member = (Map<String,Object>)census_member_object;
                        //Add the userInput if the member that we are in the loop of UserInput is included and has the product.
                        if ((String)user_input.get('Id') == (String)census_member.get('Id')) {
                            if ((Boolean)user_input.get('RF_Census.CM_IsPrimary') == true) hasPrimary = true;
                            if ((Integer)user_input.get('RF_Census.CM_Age') == oldestMemberAge) {
                                oldestMemberRelationShip = (String)user_input.get('RF_Census.CM_Relationship');
                                hasOldestMember = true;
                            }
                            user_input.put('RF_Census.CRF_PrimaryMemberAge', oldestMemberAge);
                            ((List<Map<String,Object>>)product_map.get('userInputs')).add(user_input);
                        }
                        // Add newborns only to Medical plans 
                        else if ((Boolean)user_input.get('IsNewMember') == true && !newMemberIds.contains((String)user_input.get('Id')) && (String)product.get('Type__c') == 'Medical') {
                            user_input.put('RF_Census.CRF_PrimaryMemberAge', oldestMemberAge);
                            ((List<Map<String,Object>>)product_map.get('userInputs')).add(user_input);
                            newMemberIds.add((String)user_input.get('Id'));
                        }
                    }
                }

                if ((String)product.get('Type__c') == 'Ancillary') {
                    for (Object census_Member_object : (List<Map<String,Object>>)product_map.get('userInputs')) {
                        Map<String,Object> census_Member = (Map<String,Object>)census_Member_object;
                            
                        if ((String)census_Member.get('RF_Census.CM_Relationship') == 'Primary') {
                            countPrimary ++;
                        } else if ((String)census_Member.get('RF_Census.CM_Relationship') == 'Spouse') {
                            countSpouse ++;
                        } else if ((String)census_Member.get('RF_Census.CM_Relationship') == 'Child') {
                            countChilds ++;
                        }
                    }
                }

                //Adjust the Oldest Member Age AND Primary Member on the procut if the Primary is not inlcuded or if the oldest member is not included. OR is Ancillary Product
                if ((String)product.get('Type__c') == 'Ancillary') {
                    for (Object census_Member_object : (List<Map<String,Object>>)product_map.get('userInputs')) {
                        Map<String,Object> census_Member_instance = (Map<String,Object>)census_Member_object;
                        if (premierSelected) {
                            census_Member_instance.put('RF_Census.CM_IsPrimary', true);
                        } else if (!hasPrimary) {
                            if ((String)census_Member_instance.get('RF_Census.CM_Relationship') == 'Spouse') {
                                census_Member_instance.put('RF_Census.CM_IsPrimary', true);
                            }
                        }
                        if (premierSelected) {
                            census_Member_instance.put('RF_Census.CRF_PrimaryMemberAge', (Integer)census_Member_instance.get('RF_Census.CM_Age'));
                        } else if (!hasOldestMember) {
                            if (oldestMemberRelationShip == 'Primary') {
                                census_Member_instance.put('RF_Census.CRF_PrimaryMemberAge', (Integer)ageMembersMap.get('Spouse'));
                            } else {
                                census_Member_instance.put('RF_Census.CRF_PrimaryMemberAge', (Integer)ageMembersMap.get('Primary'));
                            }
                        }

                        if ((countPrimary == 1 && countSpouse == 0 && countChilds == 0) || (countPrimary == 0 && countSpouse == 1 && countChilds == 0)) {
                            census_Member_instance.put('RF_Census.CRF_Coverage', 'Primary');
                            census_Member_instance.put('RF_Census.CRF_CoverageAIDD', 'Primary');
                        } else if (countPrimary == 1 && countSpouse == 1 && countChilds == 0) {
                            census_Member_instance.put('RF_Census.CRF_Coverage', 'Primary + Spouse');
                            census_Member_instance.put('RF_Census.CRF_CoverageAIDD', 'Primary + Spouse');
                        } else if ((countPrimary == 1 && countSpouse == 0 && countChilds > 0) || (countPrimary == 0 && countSpouse == 1 && countChilds > 0)) {
                            census_Member_instance.put('RF_Census.CRF_Coverage', 'Primary + Child');
                            census_Member_instance.put('RF_Census.CRF_CoverageAIDD', 'Primary + Children');
                        } else {
                            census_Member_instance.put('RF_Census.CRF_Coverage', 'Family');
                            census_Member_instance.put('RF_Census.CRF_CoverageAIDD', 'Family');
                        }     
                    }
                }

                products_list.add(product_map);
            }
            outputMap.put('LWC_ChooseProductSelectionOutput', products_list);
        }
        return outputMap;
    }

    /*******************************************************************
    * @MethodName         :   populateReasons
    * @Description        :   method to populate the reasons of the contract based on the contract status
    ********************************************************************/
    public static Map<String,Object> populateReasons(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        String contractStatus = (String)inputMap.get('ContractStatus');

        Set<Id> setOrderId = new Set<Id>();

        Id recurringMonthlyOrderId = inputMap.containsKey('RecurringMonthlyOrderId') && (String)inputMap.get('RecurringMonthlyOrderId') != null && (String)inputMap.get('RecurringMonthlyOrderId') != '' ? (Id)inputMap.get('RecurringMonthlyOrderId') : null;
        if (recurringMonthlyOrderId != null) setOrderId.add(recurringMonthlyOrderId);
        
        Id appFeeOrderId = inputMap.containsKey('AppFeeOrderId') && (String)inputMap.get('AppFeeOrderId') != null && (String)inputMap.get('AppFeeOrderId') != '' ? (Id)inputMap.get('AppFeeOrderId') : null;
        if (appFeeOrderId != null) setOrderId.add(appFeeOrderId);
        
        Map<Id, ChargentOrders__ChargentOrder__c> mapChargentOrders = new Map<Id, ChargentOrders__ChargentOrder__c>([SELECT Id,(SELECT Id, Name, ARC_ChargentOrder__c, ARC_Amount__c FROM FeeItems__r), ChargentOrders__Charge_Date__c, ChargentOrders__Bank_Routing_Number__c, ChargentOrders__Bank_Account_Number__c, ChargentOrders__Bank_Account_Type__c, ChargentOrders__Bank_Name__c, ChargentOrders__Billing_First_Name__c, ARC_FirstMonthPayed__c, ChargentOrders__Billing_Last_Name__c, ChargentOrders__Billing_Address__c, ChargentOrders__Billing_City__c, ChargentOrders__Billing_State__c, ChargentOrders__Billing_Zip_Postal__c, ChargentOrders__Card_Expiration_Month__c, ChargentOrders__Card_Expiration_Year__c, ChargentOrders__Card_Last_4__c, ChargentOrders__Card_Month_Indicator__c, ChargentOrders__Card_Number__c, ChargentOrders__Card_Type__c, ChargentOrders__Card_Year_Indicator__c, ChargentOrders__Charge_Amount__c, ChargentOrders__Description__c, ChargentOrders__Gateway__c, ChargentOrders__Payment_Frequency__c, ChargentOrders__Payment_Method__c, ChargentOrders__Payment_Status__c, ChargentOrders__Subtotal__c, ChargentOrders__Manual_Charge__c, ChargentOrders__Tokenization__c FROM ChargentOrders__ChargentOrder__c WHERE Id IN :setOrderId LIMIT 2 ]);

        ChargentBase__Chargent_Settings__c feeAmounts = [SELECT Id, Name, ARC_UpgradeChangeFee__c, ARC_AddMemberChangeFee__c,ARC_DowngradeChangeFee__c, ARC_AppFee__c FROM ChargentBase__Chargent_Settings__c LIMIT 1];
        
        Map<String, Object> nbReasons = new Map<String, Object> {
            'Add Newborn' => true
        };

        Boolean feeApplicable = false;
        Decimal feeAmount = 0;
        Decimal pendingFeeAmount  = 0;

        List<String> allReasons = new List<String>{'Add Newborn'};
        List<String> pendingReasons = new List<String>();
        

        //List of fee items based on the application fee order
        List<Map<String,Object>> nbFeeItems = new List<Map<String,Object>>();
        Map<String,Object> nbFeeItemMap = new Map<String,Object>{
                'Name' => 'Add Member',
                'Amount' => feeAmounts.ARC_AddMemberChangeFee__c
        };
        

        if (inputMap.containsKey('GapInPermNB') && (Boolean)inputMap.get('GapInPermNB') == true) {
            feeApplicable = true;
            feeAmount = feeAmounts.ARC_AddMemberChangeFee__c;
        }
        List<String> reasonsToMap = new List<String>{'Add Newborn','Add Member', 'Program Upgrade', 'Program Downgrade', 'New Application'};
        List<String> listReasons = new List<String>();
        
        if(inputMap.containsKey('ContractStatus') && contractStatus.contains('Awaiting')) { 
            String reasonsString = inputMap.containsKey('ContractReasons') ? (String)inputMap.get('ContractReasons') : null;

            if (reasonsString != null && reasonsString.contains('Add Ancillary Product')) {
                reasonsString = reasonsString.replace('Add Ancillary Product', 'Ancillary Change');
            }

            listReasons = reasonsString.contains(';') ? reasonsString.split(';') : new List<String>{reasonsString};
            for(String reason : listReasons) {
                if (reason != 'Add Newborn') {
                    nbReasons.put(reason, true);
                    allReasons.add(reason);
                }
                if (reasonsToMap.contains(reason) ) {
                    pendingReasons.add(reason);
                    feeApplicable = true;
                }
            }
        }
        

        ChargentOrders__ChargentOrder__c cAppOrder = appFeeOrderId != null ? mapChargentOrders.get(appFeeOrderId) : null;
        if (cAppOrder != null && cAppOrder.FeeItems__r != null && cAppOrder.ARC_FirstMonthPayed__c == false) {
            for (ARC_FeeItem__c feeItem : cAppOrder.FeeItems__r) {
                if (feeItem.ARC_Amount__c != null && feeItem.ARC_Amount__c > 0) {
                    feeAmount += feeItem.ARC_Amount__c;
                    pendingFeeAmount += feeItem.ARC_Amount__c;
                    Map<String,Object> feeItemMap = new Map<String,Object>{
                        'Name' => feeItem.Name,
                        'Amount' => feeItem.ARC_Amount__c
                    };
                    nbFeeItems.add(feeItemMap);
                }
            }
        }
        if(cAppOrder != null && cAppOrder.ARC_FirstMonthPayed__c == false 
        && cAppOrder.FeeItems__r.isEmpty() && pendingReasons != null && !pendingReasons.isEmpty() && cAppOrder.ChargentOrders__Subtotal__c != null && cAppOrder.ChargentOrders__Subtotal__c > 0) {
            pendingFeeAmount += cAppOrder.ChargentOrders__Subtotal__c;
            feeAmount += cAppOrder.ChargentOrders__Subtotal__c;
            //Create feeItem based on the reasons since there are no fee items on the order
            //If reasons are more than 1, we need to create 1 fee item with 1 reason, prioritizin: 1: Upgrade, 2: Add Member, 3: Downgrade
            
            if(pendingReasons.size() > 1) {
                Map<String,Object> feeItemMap = new Map<String,Object>();
                String prioritizedReason = '';
                if(pendingReasons.contains('Program Upgrade')) {
                    prioritizedReason = 'Program Upgrade';
                } else if(pendingReasons.contains('Add Member') || pendingReasons.contains('Add Newborn')) {
                    prioritizedReason = 'Add Member';
                } else if(pendingReasons.contains('Program Downgrade')) {
                    prioritizedReason = 'Program Downgrade';
                } 
                // else {
                //     prioritizedReason = listReasons[0];
                // }

                feeItemMap.put('Name', prioritizedReason);
                feeItemMap.put('Amount', cAppOrder.ChargentOrders__Subtotal__c);

                nbFeeItems.add(feeItemMap);
            }else{
                Map<String,Object> feeItemMap = new Map<String,Object>();
                String singleReason = listReasons[0];
                feeItemMap.put('Name', singleReason);
                feeItemMap.put('Amount', cAppOrder.ChargentOrders__Subtotal__c);
                nbFeeItems.add(feeItemMap);
            }
        }

        

        outputMap.put('nbFeeItems', nbFeeItems);
        outputMap.put('nbFeeItemMap', nbFeeItemMap);

        if(feeAmount == 0) {
            feeApplicable = false;
        }

        Map<String,Object> nbReasonsOutput = new Map<String,Object> {
            'feeApplicable' => feeApplicable,
            'feeAmount' => feeAmount
        };




        if(cAppOrder != null && pendingReasons != null && !pendingReasons.isEmpty()) {
            nbReasonsOutput.put('nbPendingFeesString', String.join(pendingReasons, ', '));
            String programSummaryPendingFeesText = 'Pending Change Fees (' + String.join(pendingReasons, ', ') + '): '; //+ pendingFeeAmount;
            nbReasonsOutput.put('programSummaryPendingFeesText', programSummaryPendingFeesText);
            
        }
        nbReasonsOutput.put('pendingFeeAmount', pendingFeeAmount);

        if (inputMap.containsKey('GapInPermNB') && (Boolean)inputMap.get('GapInPermNB') == true) {
            String programSummaryFeeText = 'New Change Fee (Add Newborn): '; //+ feeAmounts.ARC_AddMemberChangeFee__c;
            nbReasonsOutput.put('programSummaryFeeText', programSummaryFeeText);
            
        }      
        nbReasonsOutput.put('newFeeAmount', inputMap.containsKey('GapInPermNB') && (Boolean)inputMap.get('GapInPermNB') == true ? feeAmounts.ARC_AddMemberChangeFee__c : 0);

        nbReasonsOutput.put('nbReasons', nbReasons);
        nbReasonsOutput.put('nbReasonsString', String.join(allReasons, '; '));
        outputMap.put('nbChanges', nbReasonsOutput);
        outputMap.put('mapChargentOrders', mapChargentOrders);
        return outputMap;
    }

    public static Map<String,Object> getMemberBeneficiaries (Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        String contractId = (String)((Map<String,Object>)inputMap.get('ContractInfo')).get('Id');
        List<Object> censusMemberList = (List<Object>)inputMap.get('census_members');

        List<ARC_CoverageParticipant__c> coverageParticipantList = [
            SELECT Id, ARC_PrimaryBeneficiaryName__c, ARC_PrimaryBeneficiaryBirthdate__c, ARC_PrimaryBeneficiaryPhone__c, ARC_PrimaryBeneficiaryRelationship__c, ARC_PrimaryBeneficiaryOther__c, ARC_SecondaryBeneficiaryName__c, ARC_SecondaryBeneficiaryBirthdate__c, ARC_SecondaryBeneficiaryPhone__c, ARC_SecondaryBeneficiaryRelationship__c, ARC_SecondaryBeneficiaryOther__c, ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId
            FROM ARC_CoverageParticipant__c
            WHERE ARC_Policy__r.ARC_Contract__c = :contractId AND ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c = 'Medical'
        ];

        Map<String, ARC_CoverageParticipant__c> memberToCoveragePartMap = new Map<String, ARC_CoverageParticipant__c>();
        if (coverageParticipantList != null && !coverageParticipantList.isEmpty()) {
            for (ARC_CoverageParticipant__c covPart : coverageParticipantList) {
                String memberId = covPart.ARC_PolicyParticipant__r?.PrimaryParticipantContact?.AccountId;
                if (memberId != null && !memberToCoveragePartMap.containsKey(memberId))
                    memberToCoveragePartMap.put(memberId, covPart);
            }
        }
        
        if (censusMemberList != null && !censusMemberList.isEmpty()) {
            List<Object> finalMemberList = new List<Object>();
            for (Object member : censusMemberList) {
                Map<String,Object> memberMap = (Map<String,Object>)member;
                String memberAccountId = (String)memberMap.get('PersonAccountId');
                List<Object> memberBeneficiariesList = new List<Object>();
                if (memberToCoveragePartMap.get(memberAccountId) != null) {
                    ARC_CoverageParticipant__c memberCovPart = memberToCoveragePartMap.get(memberAccountId);
                    if (memberCovPart.ARC_PrimaryBeneficiaryName__c != null && memberCovPart.ARC_PrimaryBeneficiaryName__c != '') {
                        Map<String,Object> primaryBenefMap = new Map<String,Object>{
                            'Id' => String.valueOf(memberCovPart.Id + '-primary'),
                            'Label' => 'Primary Beneficiary',
                            'BeneficiaryName' => String.valueOf(memberCovPart.ARC_PrimaryBeneficiaryName__c),
                            'BeneficiaryBirthdate' => String.valueOf(memberCovPart.ARC_PrimaryBeneficiaryBirthdate__c),
                            'BeneficiaryPhone' => String.valueOf(memberCovPart.ARC_PrimaryBeneficiaryPhone__c),
                            'BeneficiaryRelationship' => String.valueOf(memberCovPart.ARC_PrimaryBeneficiaryRelationship__c),
                            'BeneficiaryOtherRelationship' => String.valueOf(memberCovPart.ARC_PrimaryBeneficiaryOther__c),
                            'isOtherRelationship' => memberCovPart.ARC_PrimaryBeneficiaryRelationship__c == 'Other' ? true : false
                        };
                        memberBeneficiariesList.add(primaryBenefMap);
                    }
                    if (memberCovPart.ARC_SecondaryBeneficiaryName__c != null && memberCovPart.ARC_SecondaryBeneficiaryName__c != '') {
                        Map<String,Object> secondaryBenefMap = new Map<String,Object>{
                            'Id' => String.valueOf(memberCovPart.Id + '-secondary'),
                            'Label' => 'Secondary Beneficiary',
                            'BeneficiaryName' => String.valueOf(memberCovPart.ARC_SecondaryBeneficiaryName__c),
                            'BeneficiaryBirthdate' => String.valueOf(memberCovPart.ARC_SecondaryBeneficiaryBirthdate__c),
                            'BeneficiaryPhone' => String.valueOf(memberCovPart.ARC_SecondaryBeneficiaryPhone__c),
                            'BeneficiaryRelationship' => String.valueOf(memberCovPart.ARC_SecondaryBeneficiaryRelationship__c),
                            'BeneficiaryOtherRelationship' => String.valueOf(memberCovPart.ARC_SecondaryBeneficiaryOther__c),
                            'isOtherRelationship' => memberCovPart.ARC_SecondaryBeneficiaryRelationship__c == 'Other' ? true : false
                        };
                        memberBeneficiariesList.add(secondaryBenefMap);
                    }
                }
                memberMap.put('beneficiaries', memberBeneficiariesList);
                finalMemberList.add(memberMap);
            }
            outputMap.put('census_members', finalMemberList);
        }

        return outputMap;
    }

    /////////////////////////////////////////////
    ////////Auxiliary methods/////////////////////
    /////////////////////////////////////////////

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
    * @MethodName         :   addQuestionResponseList
    * @Description        :   Aux method to populate input fields for the medical questions Cancer and Preescriptions
    ********************************************************************/
    private static void addQuestionResponseList(Map<String, List<Map<String, Object>>> questionMap, String blockName, String fieldName, Object value, String memberId, Integer index) {
        // Check if the block already exists in the questionMap
        if (!questionMap.containsKey(blockName)) {
            // If it doesn't exist, create a new list for that block
            questionMap.put(blockName, new List<Map<String, Object>>());
        }
    
        // Get the list of responses for the block
        List<Map<String, Object>> responsesForBlock = questionMap.get(blockName);
    
        // Check if an object with the same index and member already exists
        Boolean foundExistingIndex = false;
        for (Map<String, Object> response : responsesForBlock) {
            if (response.get('memberId') == memberId && (Integer)response.get('index') == index) {
                // If the same member and index are found, add the new field to the existing object
                response.put(fieldName, value);
                foundExistingIndex = true;
                break;
            }
        }
    
        // If the index wasn't found, create a new entry for the member
        if (!foundExistingIndex) {
            Map<String, Object> newResponse = new Map<String, Object>();
            newResponse.put(fieldName, value);
            newResponse.put('memberId', memberId);
            newResponse.put('index', index);
    
            // Add the new response to the block
            responsesForBlock.add(newResponse);
        }    
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
        addQuestionResponse(questionsMap, 'BLK_ParentSiblingDiagnosed', 'TXT_MemberIdParentDiagnosed', memberId, memberId);
        addQuestionResponse(questionsMap, 'BLK_UnexpectedSymptoms', 'TXT_MemberUnexpectedSymptoms', fullName, memberId);
        addQuestionResponse(questionsMap, 'BLK_UnexpectedSymptoms', 'TXT_MemberIdUnexpectedSymptoms', memberId, memberId);
        addQuestionResponse(questionsMap, 'BLK_PendingTests', 'TXT_MemberPendingTests', fullName, memberId);
        addQuestionResponse(questionsMap, 'BLK_PendingTests', 'TXT_MemberIdPendingTests', memberId, memberId);
        addQuestionResponse(questionsMap, 'BLK_Addictions', 'TXT_MemberAddictions', fullName, memberId);
        addQuestionResponse(questionsMap, 'BLK_Addictions', 'TXT_MemberIdAddictions', memberId, memberId);
        addQuestionResponse(questionsMap, 'BLK_LicenceSuspended', 'TXT_MemberLicenceSuspended', fullName, memberId);
        addQuestionResponse(questionsMap, 'BLK_LicenceSuspended', 'TXT_MemberIdLicenceSuspended', memberId, memberId);
        addQuestionResponse(questionsMap, 'EB_PastConditions', 'TXT_MemberPastConditions', fullName, memberId);
        addQuestionResponse(questionsMap, 'EB_PastConditions', 'TXT_MemberIdPastConditions', memberId, memberId);
        addQuestionResponse(questionsMap, 'EB_Physicians', 'TXT_CensusMemberName', fullName, memberId);

        Map<String, Object> selectMemberDetail = new Map<String, Object>();
        selectMemberDetail.put('CensusMemberName', fullName);
        selectMemberDetail.put('CensusMemberId', memberId);
        selectMemberDetail.put('Birthdate', memberBirthDate);

        selectCensusMemberList.add(selectMemberDetail);
    }

    // Custom comparator class to sort by relationship
    private class RelationshipComparator implements Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            String relationshipA = (String)a.get('RF_Census.CM_Relationship');
            String relationshipB = (String)b.get('RF_Census.CM_Relationship');
            
            // Primary comes first (value = 1)
            if (relationshipA == 'Primary' && relationshipB != 'Primary') return -1;
            if (relationshipA != 'Primary' && relationshipB == 'Primary') return 1;
            
            // If both are Primary or neither is Primary, Spouse comes before Child (value = 2)
            if (relationshipA == 'Spouse' && relationshipB == 'Child') return -1;
            if (relationshipA == 'Child' && relationshipB == 'Spouse') return 1;
            
            // If same relationship, maintain original order
            return 0;
        }
    }

    private static Map<String,Integer> getOldestAgeMap(List<Object> userInputs){
        Map<String,Integer> ageMap = new Map<String,Integer>();
        Integer oldestAge = 0;
        for (Object user_input_object : userInputs) {
            Map<String,Object> user_input = (Map<String,Object>)user_input_object;
            if (user_input.containsKey('RF_Census.CM_Age') && user_input.get('RF_Census.CM_Age')!= null) {
                if((Integer)user_input.get('RF_Census.CM_Age')>oldestAge){
                    oldestAge = (Integer)user_input.get('RF_Census.CM_Age');
                }
                if(user_input.containsKey('RF_Census.CM_Relationship') && ((String)user_input.get('RF_Census.CM_Relationship') == 'Primary' || (String)user_input.get('RF_Census.CM_Relationship') == 'Spouse')){
                    ageMap.put((String)user_input.get('RF_Census.CM_Relationship'),(Integer)user_input.get('RF_Census.CM_Age'));
                }
            }
        }
        ageMap.put('oldestAge',oldestAge);
        return ageMap;
    }

    private static Set<Id> getContractMemberIds(Id contractId, Id censusId, Boolean isSpinOff) {
        Set<Id> censusMemberIds = new Set<Id>();
        if (isSpinOff == true) {
            for (vlocity_ins__GroupCensusMember__c member : [
                SELECT Id
                FROM vlocity_ins__GroupCensusMember__c
                WHERE vlocity_ins__CensusId__c = :censusId
            ]) {
                censusMemberIds.add(member.Id);
            }
        } else {
            for (ARC_ContractParticipant__c participant : [
                SELECT Id, ARC_PersonAccount__r.Census_Member__c 
                FROM ARC_ContractParticipant__c 
                WHERE ARC_Contract__c = :contractId
            ]) {
                if (participant.ARC_PersonAccount__r != null && participant.ARC_PersonAccount__r.Census_Member__c != null) {
                    censusMemberIds.add(participant.ARC_PersonAccount__r.Census_Member__c);
                }
            }
        }
        return censusMemberIds;
    }

    private static Map<String, Object> createMemberMap (vlocity_ins__GroupCensusMember__c member, Map<Id, String> censusMemberRelationshipMap, Boolean isSpinOff) {
        String address = String.join(new List<String>{member.ARC_PhysicalAddressStreet__c, member.ARC_PhysicalAddressCity__c, member.ARC_PhysicalAddressState__c, member.ARC_PhysicalAddressZipCode__c}, ', ');

        String relationship = isSpinOff == true ? member.ARC_Relationship__c : censusMemberRelationshipMap.get(member.Id);
        
        Map<String, Object> memberMap = new Map<String, Object>{
            'Id' => member.Id,
            'vlocity_ins__FirstName__c' => member.vlocity_ins__FirstName__c,
            'vlocity_ins__LastName__c' => member.vlocity_ins__LastName__c,
            'PersonAccountId' => member.vlocity_ins__ContactId__r.AccountId,
            'PersonContactId' => member.vlocity_ins__ContactId__c,
            'vlocity_ins__MemberIdentifier__c' => member.vlocity_ins__MemberIdentifier__c,
            'ARC_MiddleInitial__c' => member.ARC_MiddleInitial__c,
            'vlocity_ins__Birthdate__c' => member.vlocity_ins__Birthdate__c,
            'vlocity_ins__IsPrimaryMember__c' => relationship == 'Primary',
            'ARC_Age__c' => member.ARC_Age__c,
            'vlocity_ins__SocialSecurityNumber__c' => member.vlocity_ins__SocialSecurityNumber__c,
            'showSSN' => 'password',
            'ARC_HeightFeet__c' => member.ARC_HeightFeet__c,
            'ARC_HeightInches__c' => member.ARC_HeightInches__c,
            'ARC_Weight__c' => member.ARC_Weight__c,
            'ARC_Smoker__c' => member.ARC_Smoker__c,
            'ARC_PhysicalAddressCity__c' => member.ARC_PhysicalAddressCity__c,
            'ARC_PhysicalAddressState__c' => member.ARC_PhysicalAddressState__c,
            'ARC_PhysicalAddressStreet__c' => member.ARC_PhysicalAddressStreet__c,
            'ARC_PhysicalAddressZipCode__c' => member.ARC_PhysicalAddressZipCode__c,
            'ARC_Address__c' => address,
            'IsDependent' => relationship != 'Primary',
            'individual_errors' => new List<String>(),
            'IsNewMember' => false,
            'IsRemoveMember' => false,
            'ShowMember' => true,
            'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
            'DISABLE_INPUT_FIELDS' => false,
            'ARC_Phone__c' => member.ARC_Phone__c,
            'vlocity_ins__Email__c' =>member.vlocity_ins__Email__c,
            'ARC_isPregnant__c' => member.ARC_isPregnant__c,
            'ARC_Relationship__c' => relationship,
            'vlocity_ins__Gender__c' => member.vlocity_ins__Gender__c
        };

        return memberMap;
    }

    /**
     * Set the member future age from effective date +60 days
     * @param Date Birthdate of Member
     * @param Date New Effective Date + 60 days or a target date
     * @returns Integer
     */
    private static Integer calculateAge(Date DOB, Date dateTo){
        Date memberBDToDate = DOB;
        Date effDate = dateTo;

        Integer DOBYear = memberBDToDate.year();
        Integer effYear = effDate.year();

        Integer DOBMonth = memberBDToDate.month();
        Integer effMonth = effDate.month();

        Integer DOBDay = memberBDToDate.day();
        Integer effDay = effDate.day();

        Integer turnsInEffYear = effYear - Dobyear;

        Boolean pastBD = false;
        if(DOBMonth < effMonth){
            pastBD = true;
        }else if(DOBMonth == effMonth){
            if(DOBDay<=effDay){
                pastBD = true;
            }
        }

        Integer age = -1;
        if(pastBD == true){
            age = turnsInEffYear;
        } else{
            age = turnsInEffYear -1;
        }

        return age;
    } 

    @TestVisible
    private static Boolean hasTemporaryNewBornMember(vlocity_ins__GroupCensusMember__c member, Map<Id, String> censusMemberRelationshipMap, Boolean isSpinOff) {
        Boolean isTemporaryNewborn = false;
        if (member.ARC_Relationship__c == 'Child' && member.ARC_Age__c < 18) {
            isTemporaryNewborn = true;
        }
        return isTemporaryNewborn;
    }

    /**
     * @Description: Auxiliar method to transform member map keys
     * @param memberMap: All the member information map received from JSON
     */
    @TestVisible
    private static Map<String,Object> transformMemberMapKeys(Map<String,Object> memberMap) {
        String height = String.valueOf(memberMap.get('ARC_HeightFeet__c')) + '\'' + String.valueOf(memberMap.get('ARC_HeightInches__c')) + '\"';
        String memberSSN = (String)memberMap.get('vlocity_ins__SocialSecurityNumber__c');
        Map<String,Object> transformedMemberMap = new Map<String,Object> {
            'Id' => (String)memberMap.get('Id'),
            'FirstName' => (String)memberMap.get('vlocity_ins__FirstName__c'),
            'MI' => (String)memberMap.get('ARC_MiddleInitial__c'),
            'LastName' => (String)memberMap.get('vlocity_ins__LastName__c'),
            'DOB' => (String)memberMap.get('vlocity_ins__Birthdate__c'),
            'Age' => Integer.valueOf(memberMap.get('ARC_Age__c')),
            'Gender' => (String)memberMap.get('vlocity_ins__Gender__c'),
            'Phone' => (String)memberMap.get('ARC_Phone__c'),
            'Email' => (String)memberMap.get('vlocity_ins__Email__c'),
            'SocialSecurity' => memberSSN != null ? 'XXX-XX-' + memberSSN.right(4) : '',
            'SSN' => memberSSN ?? '',
            'Height' => height,
            'Weight' => String.valueOf(memberMap.get('ARC_Weight__c')),
            'Pregnant' => memberMap.get('ARC_isPregnant__c') != null && memberMap.get('ARC_isPregnant__c') != '' ? (Boolean)memberMap.get('ARC_isPregnant__c') : false,
            'Smoker' => memberMap.get('ARC_Smoker__c') != null && memberMap.get('ARC_Smoker__c') != '' ? (Boolean)memberMap.get('ARC_Smoker__c') : false,
            'Address' => (String)memberMap.get('ARC_PhysicalAddressStreet__c'),
            'City' => (String)memberMap.get('ARC_PhysicalAddressCity__c'),
            'State' => (String)memberMap.get('ARC_PhysicalAddressState__c'),
            'ZipCode' => (String)memberMap.get('ARC_PhysicalAddressZipCode__c'),
            'Relationship' => (String)memberMap.get('ARC_Relationship__c'),
            'IsRemoveMember' => (Boolean)memberMap.get('IsRemoveMember'),
            'IsNewMember' => (Boolean)memberMap.get('IsNewMember')
        };

        return transformedMemberMap;
    }
}