global without sharing class ARC_ProgramChange_Utilities_Agustina implements vlocity_ins.VlocityOpenInterface{
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'compareCensusMemberChanges') {
            compareCensusMemberChanges(inputMap, outputMap, options);
        } else if (methodName == 'censusPlanSelectionChanges') {
            censusPlanSelectionChanges(inputMap, outputMap, options);
        } else if (methodName == 'readMedicalQuestions') {
            readMedicalQuestions(inputMap, outputMap, options);
        } else if (methodName == 'getOldPlansSummary') {
            getOldPlansSummary(inputMap, outputMap, options);
        }
        
        return true;
    }

    /*******************************************************************
    * @MethodName         :   compareCensusMemberChanges
    * @Description        :   Method to analyze changes in Census and identify Census PC changes
    ********************************************************************/
    public static void compareCensusMemberChanges(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
        List<Object> initial_values = (List<Object>)inputMap.get('InitialValues'); // List of members BEFORE any changes
        List<Object> final_values = (List<Object>)inputMap.get('FinalValues'); // List of members AFTER changes

        // Set<String> reasonSet = new Set<String>(); // Set of reasons to be returned to the OS
        Map<String,Object> reasonsMap = new Map<String,Object>{
            'addMember' => false,
            'removeMember' => false,
            'addExistingMember' => false,
            'primaryChange' => false,
            'addressStateChange' => false,
            'relationshipToPrimaryChange' => false,
            'dateOfBirthChange' => false,
            'programUpgrade' => false,
            'programDowngrade' => false,
            'ancillaryChange' => false,
            'removeAllAncillary' => false,
            'effectiveDateChange' => false
        }; // Map of reasons to be returned to the OS



        Map<String,Object> finalPrimaryValues = new Map<String,Object>();
        Map<String,List<Map<String,Object>>> mymap = new Map<String,List<Map<String,Object>>>();
        Map<String,Object> STEP_HIPAAAuthorizationForm = new Map<String,List<Object>>();
        Map<String,Object> EDITBLK_HIPAAAuthorizedParties = new Map<String,Object>();
        List<Map<String,Object>> EDITBLK_HIPAAAuthorizedPartiesList = new List<Map<String,Object>>();
        List<Map<String,Object>> hipaaPartiesList = new List<Map<String,Object>>();
        Integer initialAgeValue = 0;
        Integer finalAgeValue = 0;
        
        for (Object member_new : final_values) {
            Map<String,Object> member_new_map = (Map<String,Object>)member_new;

            // Get final primary values
            Boolean isFinalPrimary = (Boolean)member_new_map.get('vlocity_ins__IsPrimaryMember__c');
            Boolean isRemovedMember = (Boolean)member_new_map.get('IsRemoveMember');
            if (isFinalPrimary == true && isRemovedMember == false) {
                Boolean isUnder18;
                Integer finalPrimaryAge = (Integer)member_new_map.get('ARC_Age__c');
                if (finalPrimaryAge != null && finalPrimaryAge < 18) {
                    isUnder18 = true;
                }
                else {
                    isUnder18 = false;
                }
                finalPrimaryValues.put('isUnder18', isUnder18);
            }
            
            // Add Member PC Reason
            Boolean isAddMember = (Boolean)member_new_map.get('IsNewMember'); // Check if any member is a New Member
            if (isAddMember != null && isAddMember == true) {
                reasonsMap.put('addMember', true); // Add 'Add Member' as a PC reason if any is true
                Integer newAge = (Integer)member_new_map.get('ARC_Age__c'); 
                if(newAge > 17){
                    Map<String, Object> tempMap = new Map<String, Object>();
                    EDITBLK_HIPAAAuthorizedParties.put('TXT_FullName',(String)member_new_map.get('vlocity_ins__FirstName__c') + ' ' + (String)member_new_map.get('vlocity_ins__LastName__c'));
                    EDITBLK_HIPAAAuthorizedParties.put('TXT_Relationship',(String)member_new_map.get('ARC_Relationship__c'));
                    EDITBLK_HIPAAAuthorizedParties.put('DAT_DOB',(String)member_new_map.get('vlocity_ins__Birthdate__c'));
                    tempMap.put('TXT_FullName',(String)member_new_map.get('vlocity_ins__FirstName__c') + ' ' + (String)member_new_map.get('vlocity_ins__LastName__c'));
                    tempMap.put('TXT_Relationship',(String)member_new_map.get('ARC_Relationship__c'));
                    tempMap.put('DAT_DOB',(String)member_new_map.get('vlocity_ins__Birthdate__c'));
                    hipaaPartiesList.add(tempMap);
                    mymap.put('EDITBLK_HIPAAAuthorizedParties', hipaaPartiesList);  
                }
            }

            // Remove Member PC Reason
            Boolean isRemoveMember = (Boolean)member_new_map.get('IsRemoveMember'); // Check if any member is a Removed Member
            if (isRemoveMember != null && isRemoveMember == true) {
                reasonsMap.put('removeMember', true); // Add 'Remove Member' as a PC reasons if any is true
            }

            // Add Existing Member PC Reason
            Boolean isExistingMember = (Boolean)member_new_map.get('IsInactiveMember'); // Check if any member is a Existing Member
            if (isExistingMember != null && isExistingMember == true) {
                reasonsMap.put('addExistingMember', true); // Add 'Add Existing Member' as a PC reason if any is true
            }

            // Get the oldest final member
            Integer finalAge = (Integer)member_new_map.get('ARC_Age__c');
            if (finalAge > finalAgeValue) {
                finalAgeValue = finalAge;
            }

            // Edge case where adding a new member and change primary to new member
            String finalId = (String)member_new_map.get('Id');
            if (finalId == '' && (Boolean)member_new_map.get('vlocity_ins__IsPrimaryMember__c') == true) {
                reasonsMap.put('primaryChange', true);
            }

            // For loop to compare final values with initial values
            for (Object member_old : initial_values) {
                Map<String,Object> member_old_map = (Map<String,Object>)member_old;

                // Address State Change PC Reason
                // Compare the initial and final primary
                if ((Boolean)member_old_map.get('vlocity_ins__IsPrimaryMember__c') == true && (Boolean)member_new_map.get('vlocity_ins__IsPrimaryMember__c') == true) {
                    // Get the initial primary State and the final primary State 
                    String oldState = (String)member_old_map.get('ARC_PhysicalAddressState__c');
                    String newState = (String)member_new_map.get('ARC_PhysicalAddressState__c');
                    // Compare the State of the initial and final primary and check if changed
                    if (oldState != newState) {
                        reasonsMap.put('addressStateChange', true);
                    }
                }

                // Get inital and final IDs
                String oldMemberId = (String)member_old_map.get('Id');
                String newMemberId = (String)member_new_map.get('Id');
                if (oldMemberId == newMemberId) {
                    // Primary Change PC Reason
                    // Check if the Primary changes
                    if ((Boolean)member_old_map.get('vlocity_ins__IsPrimaryMember__c') == false && (Boolean)member_new_map.get('vlocity_ins__IsPrimaryMember__c') == true) {
                        reasonsMap.put('primaryChange', true);
                    }

                    // Relationship to Primary Change PC Reason
                    // Get initial and final Relationship values
                    Map<String,Object> oldRelationshipMap = (Map<String,Object>)member_old_map.get('ARC_Relationship__c');
                    String oldRelationship = (String)oldRelationshipMap.get('value');
                    String newRelationship = (String)member_new_map.get('ARC_Relationship__c');
                    // Check if the relationship to Primary Change
                    if (oldRelationship != newRelationship && newRelationship != 'Primary' && oldRelationship != 'Primary') {
                        reasonsMap.put('relationshipToPrimaryChange', true);
                    }
                }

                // Get the oldest initial member
                Integer initialAge = (Integer)member_old_map.get('ARC_Age__c');
                if (initialAge > initialAgeValue) {
                    initialAgeValue = initialAge;
                }
            }
        }

        // Date of Birth Change PC Reason
        // List of Age Gaps
        List<Integer> ageUp = new List<Integer>{18, 26, 31, 36, 41, 46, 51, 56, 61};
        Integer InitialAgeUpIndex;
        Integer FinalAgeUpIndex;
        // Checks if the initial Oldest Age is different from final Oldest Age
        if (initialAgeValue != finalAgeValue) {
            // Get the index of Age Gap list of initial and final Oldest Age
            InitialAgeUpIndex = getAgeGapIndex(initialAgeValue, ageUp);
            FinalAgeUpIndex = getAgeGapIndex(finalAgeValue, ageUp);
            // Checks if Indexes of initial and final Oldest Age are different
            if (InitialAgeUpIndex != FinalAgeUpIndex) {
                reasonsMap.put('dateOfBirthChange', true);
            }
        }

        //STEP_HIPAAAuthorizationForm.put('EDITBLK_HIPAAAuthorizedParties',mymap);
        outputMap.put('STEP_HIPAAAuthorizationForm',mymap);

        outputMap.put('pcReasons', reasonsMap);
        outputMap.put('finalPrimaryValues', finalPrimaryValues);
    }

    // Method to check the age gap index
    public static Integer getAgeGapIndex (Integer age, List<Integer> ageUp) {
        for (Integer i=0; i < ageUp.size(); i++) {
            if (age < ageUp[i]) {
                return i;
            }
        }
        return ageUp.size() - 1;
    }

    /*******************************************************************
    * @MethodName         :   censusPlanSelectionChanges
    * @Description        :   Method to analyze if Program is changed, a new contract is needed, a fee is applicable and which DocuSign needs to be sent
    ********************************************************************/
    public static void censusPlanSelectionChanges(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {   
        // Get JSON inputs
        List<Object> oldProductsValues = (List<Object>)inputMap.get('oldProducts');
        String updateType = (String)inputMap.get('updateType');
        Integer contractCount = (Integer)inputMap.get('ContractCount');
        String oldEffectiveDateString = (String)inputMap.get('oldEffectiveDate');
        Date oldEffectiveDate = Date.parse(oldEffectiveDateString);
        String newEffectiveDateString = (String)inputMap.get('newEffectiveDate');
        Date newEffectiveDate;
        if (newEffectiveDateString != '') {
            newEffectiveDate = Date.valueOf(newEffectiveDateString);
        }
        // Get Selected Products and only when Change to Programs is selected in OS
        List<Object> selectedProductsValues = new List<Object>();
        if (updateType.contains('Change to Programs')) {
            selectedProductsValues = (List<Object>)inputMap.get('selectedProducts');
        }
        // Build pcReasons map
        Map<String,Object> pcReasons = new Map<String,Object>{
            'addMember' => false,
            'removeMember' => false,
            'addExistingMember' => false,
            'primaryChange' => false,
            'addressStateChange' => false,
            'relationshipToPrimaryChange' => false,
            'dateOfBirthChange' => false,
            'programUpgrade' => false,
            'programDowngrade' => false,
            'ancillaryChange' => false,
            'removeAllAncillary' => false,
            'effectiveDateChange' => false
        };
        // Get census pcReasons only when census is displayed
        if (updateType.contains('Add or Remove a Member') || updateType.contains('Demographic Updates')) {
            pcReasons = (Map<String,Object>)inputMap.get('pcReasons');
        }

        // Output map to be returned to the OS
        Map<String,Object> pcChangesOutput = new Map<String,Object>();

        // Get selected medical plan
        String oldPlanName;
        String selectedPlanName;
        List<String> oldAncillaryList = new List<String>();
        List<String> selectedAncillaryList = new List<String>();

        // Iterate over old product list
        for (Object oldProducts : oldProductsValues) {
            Map<String,Object> old_products_map = (Map<String,Object>)oldProducts;
            // Get old plan type
            String oldPlanType = (String)old_products_map.get('vlocity_ins__Type__c');
            if (oldPlanType == 'Medical') {
                // Get old medical plan name
                oldPlanName = (String)old_products_map.get('Name');
            }
            if (oldPlanType == 'Ancillary') {
                String oldAncillaryName = (String)old_products_map.get('Name');
                oldAncillaryList.add(oldAncillaryName);
            }
        }
        System.debug(oldAncillaryList);

        // Iterate over selected products list
        if (selectedProductsValues != null) {
            for (Object selectedProducts : selectedProductsValues) {
                Map<String,Object> selected_products_map = (Map<String,Object>)selectedProducts;
                String selectedPlanType = (String)selected_products_map.get('Type__c');
                if (selectedPlanType == 'Medical') {
                    selectedPlanName = (String)selected_products_map.get('Name');
                }
                if (selectedPlanType == 'Ancillary') {
                    String selectedAncillaryName = (String)selected_products_map.get('Name');
                    selectedAncillaryList.add(selectedAncillaryName); 
                }
            }
            System.debug(selectedAncillaryList);    
        }
        
        // Compare if Ancillary lists have different products
        // if (oldAncillaryList != selectedAncillaryList && selectedAncillaryList.size() != 0) {
        //     pcReasons.put('Ancillary Change', true);
        // }

        // Checks if Ancillaries have been all removed
        if (oldAncillaryList.size() > 0 && selectedAncillaryList.size() == 0 && updateType.contains('Change to Programs')) {
            pcReasons.put('removeAllAncillary', true);
        }

        // Compare if old and selected medical plan are different
        if (oldPlanName != selectedPlanName && updateType.contains('Change to Programs')) {
            String procedureAPIName = 'GetPrograms_UpgradeAndDowngrade';
            // Call the Integration Procedure
            Map<String, Object> IPOutput = (Map<String, Object>) vlocity_ins.IntegrationProcedureService.runIntegrationProcedureServiceFromApex(procedureAPIName, new Map<String, Object>{'Program' => oldPlanName}, new Map<String, Object>());
            List<Object> resultList = (IPOutput.get('result') != null) ? (List<Object>) IPOutput.get('result') : new List<Object>();
            // Result Map with Upgrade and Downgrade Program results
            Map<String,Object> resultMap = (Map<String,Object>)resultList[0];
            // Get downgrade plans
            String downgradePlans = (String)resultMap.get('Downgrade Result');
            // Get upgrade plans
            String upgradePlans = (String)resultMap.get('Upgrade Result');
            if (downgradePlans.contains(selectedPlanName)) {
                pcReasons.put('programDowngrade', true);
            }
            if (upgradePlans.contains(selectedPlanName)) {
                pcReasons.put('programUpgrade', true);
            }
        }

        // Check if new Effective Date is changed
        if (newEffectiveDate != null && newEffectiveDate != oldEffectiveDate) {
            pcReasons.put('effectiveDateChange', true);
        }

        // Get pcReasons final values for conditional checking
        Boolean isAddMember = (Boolean)pcReasons.get('addMember');
        Boolean isRemoveMember = (Boolean)pcReasons.get('removeMember');
        Boolean isAddExistingMember = (Boolean)pcReasons.get('addExistingMember');
        Boolean isPrimaryChange = (Boolean)pcReasons.get('primaryChange');
        Boolean isAddressStateChange = (Boolean)pcReasons.get('addressStateChange');
        Boolean isRelationshipToPrimaryChange = (Boolean)pcReasons.get('relationshipToPrimaryChange');
        Boolean isDateOfBirthChange = (Boolean)pcReasons.get('dateOfBirthChange');
        Boolean isProgramUpgrade = (Boolean)pcReasons.get('programUpgrade');
        Boolean isProgramDowngrade = (Boolean)pcReasons.get('programDowngrade');
        Boolean isAncillaryChange = (Boolean)pcReasons.get('ancillaryChange');
        Boolean isRemoveAllAncillary = (Boolean)pcReasons.get('removeAllAncillary');
        Boolean isEffectiveDateChange = (Boolean)pcReasons.get('effectiveDateChange');
        
        // Checks if New Contract is needed
        if (isAddMember == true || isAddExistingMember == true || isRemoveMember == true || isPrimaryChange == true || isRelationshipToPrimaryChange == true || isDateOfBirthChange == true || isAddressStateChange == true || isProgramUpgrade == true || isProgramDowngrade == true || isAncillaryChange == true || isRemoveAllAncillary == true || (isEffectiveDateChange == true && newEffectiveDate > Date.today())) {
            pcChangesOutput.put('createNewContract', true);
        }
        else {
            pcChangesOutput.put('createNewContract', false);
        }

        // Determines which DocuSign needs to be sent (Amendment or DocuSign)
        if (isAddMember == true || isRemoveMember == true || isAddExistingMember == true || isPrimaryChange == true || (isDateOfBirthChange == true && contractCount > 1) || (isAddressStateChange == true && contractCount > 1) || isProgramUpgrade == true || isProgramDowngrade == true || isAncillaryChange == true || isRemoveAllAncillary == true) {
            pcChangesOutput.put('docuSign', 'PC DocuSign');
        }
        else if (isRelationshipToPrimaryChange == true || (isEffectiveDateChange && newEffectiveDate > Date.today()) || (isAddressStateChange == true && contractCount == 1) || (isDateOfBirthChange == true && contractCount == 1)) {
            pcChangesOutput.put('docuSign', 'Amendment');
        }
        else {
            pcChangesOutput.put('docuSign', null);
        }

        // Determines if Fee is aplicable or not
        if (isProgramUpgrade == true || isProgramDowngrade == true || isAddMember == true) {
            pcChangesOutput.put('feeApplicable', true);
        }
        else {
            pcChangesOutput.put('feeApplicable', false);
        }

        //Get the Fee amounts for Add Member, Program Upgrade & Program Downgrade
        ChargentBase__Chargent_Settings__c feeAmounts = [SELECT Id, Name, ARC_UpgradeChangeFee__c, ARC_AddMemberChangeFee__c,ARC_DowngradeChangeFee__c FROM ChargentBase__Chargent_Settings__c LIMIT 1];
        Decimal addMemberFee = feeAmounts.ARC_AddMemberChangeFee__c;
        Decimal upgradeFee = feeAmounts.ARC_UpgradeChangeFee__c;
        Decimal downgradeFee = feeAmounts.ARC_DowngradeChangeFee__c;

        // Determines the Fee Amount if applies fee to the corresponding scenario
        // First set the fee amount to 0
        pcChangesOutput.put('feeAmount', 0);
        // Sets the fee amount if corresponds
        if (pcChangesOutput.get('feeApplicable') == true) {
            if (isAddMember == true) {
                pcChangesOutput.put('feeAmount', addMemberFee);
            }
            else if (isProgramUpgrade == true) {
                // Reset the fee amount only if the new fee is higher than previous one or if fee amount was 0
                if (((Decimal)pcChangesOutput.get('feeAmount') > 0 && upgradeFee > (Decimal)pcChangesOutput.get('feeAmount')) || (Decimal)pcChangesOutput.get('feeAmount') == 0) {
                    pcChangesOutput.put('feeAmount', upgradeFee);
                }
            }
            else if (isProgramDowngrade == true) {
                // Reset the fee amount only if the new fee is higher than previous one or if fee amount was 0
                if (((Decimal)pcChangesOutput.get('feeAmount') > 0 && downgradeFee > (Decimal)pcChangesOutput.get('feeAmount')) || (Decimal)pcChangesOutput.get('feeAmount') == 0) {
                    pcChangesOutput.put('feeAmount', downgradeFee);
                }
            }
        }

        List<String> truePcReasons = new List<String>();
        for (String key : pcReasons.keySet()) {
            if ((Boolean) pcReasons.get(key)) {
                if (key == 'addMember') {
                    truePcReasons.add('Add Member');
                }
                if (key == 'programUpgrade') {
                    truePcReasons.add('Program Upgrade');
                }
                if (key == 'programDowngrade') {
                    truePcReasons.add('Program Downgrade');
                }
            }
        }
        
        if (truePcReasons.size() > 0) {
            String pcReasonsString = String.join(truePcReasons, ', ');
            String programSummaryFeeText = 'One Time Change Fee (' + pcReasonsString + '): ' + (Decimal)pcChangesOutput.get('feeAmount');
            pcChangesOutput.put('programSummaryFeeText', programSummaryFeeText);
        }

        // Add pcReasons map to output map
        pcChangesOutput.put('pcReasons', pcReasons);
        // Add output map to output
        outputMap.put('pcChanges',pcChangesOutput);
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

    /*******************************************************************
    * @MethodName         :   getOldPlansSummary
    * @Description        :   Aux method to concatenate the list of old products with its respective userInputs (for contracts created)
    ********************************************************************/
    public static void getOldPlansSummary(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
        
        // Extract the list of customer contract lines (CLIs) from the input map
        List<Object> CLIs = (List<Object>)inputMap.get('CLIs');
        List<Product2> products = new List<Product2>();
        List<vlocity_ins__GroupCensusMemberPlan__c> memberPlans = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        List<Map<String,Object>> ratedProducts = new List<Map<String,Object>>();
        List<Map<String,Object>> productList = new List<Map<String,Object>>();

        // Create sets to store unique IDs for CLIs and products
        Set<Id> CLIsIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
		
        // Create a mapping between product IDs and their associated CLIs
        Map<Id, List<Object>> prod_CLIs = new Map<Id, List<Object>>();

         // Iterate through each CLI in the list
        for (Object cli : CLIs) {
            List<Object> CLIsPerProduct = new List<Object>();
            
            // Extract the CLI and product IDs
            CLIsIds.add((Id)(((Map<String,Object>)cli).get('Id')));
            productIds.add((Id)(((Map<String,Object>)cli).get('productId')));
            
            // Check if there are already CLIs associated with this product
            if (prod_CLIs.get((Id)(((Map<String,Object>)cli).get('productId')))!= null) {
                CLIsPerProduct = prod_CLIs.get((Id)(((Map<String,Object>)cli).get('productId')));
            }
            
            // Add the CLI to the list of CLIs associated with this product
            CLIsPerProduct.add(cli);
            prod_CLIs.put((Id)(((Map<String,Object>)cli).get('productId')),CLIsPerProduct);
        }
		
        // Query for product details based on the extracted product IDs
        products = [SELECT Id, ProductCode, Name,vlocity_ins__RecordTypeName__c, vlocity_ins__Type__c,vlocity_ins__SubType__c  FROM Product2 WHERE Id IN :productIds];
        
        // Query for member plans associated with the extracted CLIs
        memberPlans = [SELECT Id, vlocity_ins__ContractLineId__c, vlocity_ins__GroupCensusMemberId__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c  FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__ContractLineId__c IN :CLIsIds /*AND vlocity_ins__GroupCensusMemberId__r.ARC_ActiveMember__c=true*/];

		// Iterate through products and their associated CLIs
        for (Product2 prod : products) {
            for (Object cli : prod_CLIs.get(prod.Id)) {
                Map<String,Object> ratedProduct = new Map<String, Object>();
                Map<String,Object> productListItem = new Map<String, Object>();
                List<Map<String,Object>> userInputs = new List<Map<String,Object>>(); 
                Map<String,Object> selectedProduct = new Map<String,Object>(); 
                ratedProduct.put('Price',(Decimal)(((Map<String,Object>)cli).get('Price')));
                ratedProduct.put('Id',prod.Id);
                ratedProduct.put('ProductCode',prod.ProductCode);
                ratedProduct.put('Name',prod.Name);
                ratedProduct.put('RecordTypeName__c',prod.vlocity_ins__RecordTypeName__c);
                ratedProduct.put('productId',prod.Id);
                ratedProduct.put('SubType__c',prod.vlocity_ins__SubType__c);
                ratedProduct.put('Type__c',prod.vlocity_ins__Type__c);
                selectedProduct.put('Price',(Decimal)(((Map<String,Object>)cli).get('Price')));
                selectedProduct.put('Id',prod.Id);
                selectedProduct.put('ProductCode',prod.ProductCode);
                selectedProduct.put('Name',prod.Name);
                selectedProduct.put('RecordTypeName__c',prod.vlocity_ins__RecordTypeName__c);
                selectedProduct.put('productId',prod.Id);
                selectedProduct.put('SubType__c',prod.vlocity_ins__SubType__c);
                selectedProduct.put('Type__c',prod.vlocity_ins__Type__c);
                ratedProducts.add(ratedProduct);

                // Iterate through member plans and populate user inputs
                for (vlocity_ins__GroupCensusMemberPlan__c memberPlan : memberPlans) {
                    if (memberPlan.vlocity_ins__ContractLineId__c == (Id)(((Map<String,Object>)cli).get('Id'))) {
                        Map<String, Object> userInputsItem = new Map<String, Object>();
                        userInputsItem.put('CensusMemberId', memberPlan.vlocity_ins__GroupCensusMemberId__c);
                        userInputsItem.put('CensusMemberLastName', memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c);
                        userInputsItem.put('CensusMemberFirstName', memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c);
                        userInputsItem.put('FirstName', memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c);
                        userInputsItem.put('LastName', memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c);
                        userInputs.add(userInputsItem);
                    }
                }
                
                // Populate the productListItem with user inputs and selected product details
                productListItem.put('userInputs', userInputs);
                productListItem.put('selectedProduct', selectedProduct);
                productList.add(productListItem);
            }
        }
        
        // Put the resulting data into the output map
        outputMap.put('products', ratedProducts);
        outputMap.put('OldProductList', productList);
    }

    /*******************************************************************
    * @MethodName         :   getNewPlansSummary
    * @Description        :   Aux method to concatenate the list of new products with its respective userInputs (for new contracts)
    ********************************************************************/
    public static void getNewPlansSummary(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
        
        // Extract the list of customer contract lines (CLIs) from the input map
        List<Object> CLIs = (List<Object>)inputMap.get('CLIs');
        List<Product2> products = new List<Product2>();
        List<vlocity_ins__GroupCensusMemberPlan__c> memberPlans = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        List<Map<String,Object>> ratedProducts = new List<Map<String,Object>>();
        List<Map<String,Object>> productList = new List<Map<String,Object>>();

        // Create sets to store unique IDs for CLIs and products
        Set<Id> CLIsIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
		
        // Create a mapping between product IDs and their associated CLIs
        Map<Id, List<Object>> prod_CLIs = new Map<Id, List<Object>>();

         // Iterate through each CLI in the list
        for (Object cli : CLIs) {
            List<Object> CLIsPerProduct = new List<Object>();
            
            // Extract the CLI and product IDs
            CLIsIds.add((Id)(((Map<String,Object>)cli).get('Id')));
            productIds.add((Id)(((Map<String,Object>)cli).get('productId')));
            
            // Check if there are already CLIs associated with this product
            if (prod_CLIs.get((Id)(((Map<String,Object>)cli).get('productId')))!= null) {
                CLIsPerProduct = prod_CLIs.get((Id)(((Map<String,Object>)cli).get('productId')));
            }
            
            // Add the CLI to the list of CLIs associated with this product
            CLIsPerProduct.add(cli);
            prod_CLIs.put((Id)(((Map<String,Object>)cli).get('productId')),CLIsPerProduct);
        }
		
        // Query for product details based on the extracted product IDs
        products = [SELECT Id, ProductCode, Name,vlocity_ins__RecordTypeName__c, vlocity_ins__Type__c,vlocity_ins__SubType__c  FROM Product2 WHERE Id IN :productIds];
        
        // Query for member plans associated with the extracted CLIs
        memberPlans = [SELECT Id, vlocity_ins__ContractLineId__c, vlocity_ins__GroupCensusMemberId__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c  FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__ContractLineId__c IN :CLIsIds /*AND vlocity_ins__GroupCensusMemberId__r.ARC_ActiveMember__c=true*/];

		// Iterate through products and their associated CLIs
        for (Product2 prod : products) {
            for (Object cli : prod_CLIs.get(prod.Id)) {
                Map<String,Object> ratedProduct = new Map<String, Object>();
                Map<String,Object> productListItem = new Map<String, Object>();
                List<Map<String,Object>> userInputs = new List<Map<String,Object>>(); 
                Map<String,Object> selectedProduct = new Map<String,Object>(); 
                ratedProduct.put('Price',(Decimal)(((Map<String,Object>)cli).get('Price')));
                ratedProduct.put('Id',prod.Id);
                ratedProduct.put('ProductCode',prod.ProductCode);
                ratedProduct.put('Name',prod.Name);
                ratedProduct.put('RecordTypeName__c',prod.vlocity_ins__RecordTypeName__c);
                ratedProduct.put('productId',prod.Id);
                ratedProduct.put('SubType__c',prod.vlocity_ins__SubType__c);
                ratedProduct.put('Type__c',prod.vlocity_ins__Type__c);
                selectedProduct.put('Price',(Decimal)(((Map<String,Object>)cli).get('Price')));
                selectedProduct.put('Id',prod.Id);
                selectedProduct.put('ProductCode',prod.ProductCode);
                selectedProduct.put('Name',prod.Name);
                selectedProduct.put('RecordTypeName__c',prod.vlocity_ins__RecordTypeName__c);
                selectedProduct.put('productId',prod.Id);
                selectedProduct.put('SubType__c',prod.vlocity_ins__SubType__c);
                selectedProduct.put('Type__c',prod.vlocity_ins__Type__c);
                ratedProducts.add(ratedProduct);

                // Iterate through member plans and populate user inputs
                for (vlocity_ins__GroupCensusMemberPlan__c memberPlan : memberPlans) {
                    if (memberPlan.vlocity_ins__ContractLineId__c == (Id)(((Map<String,Object>)cli).get('Id'))) {
                        Map<String, Object> userInputsItem = new Map<String, Object>();
                        userInputsItem.put('CensusMemberId', memberPlan.vlocity_ins__GroupCensusMemberId__c);
                        userInputsItem.put('CensusMemberLastName', memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c);
                        userInputsItem.put('CensusMemberFirstName', memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c);
                        userInputsItem.put('FirstName', memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c);
                        userInputsItem.put('LastName', memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c);
                        userInputs.add(userInputsItem);
                    }
                }
                
                // Populate the productListItem with user inputs and selected product details
                productListItem.put('userInputs', userInputs);
                productListItem.put('selectedProduct', selectedProduct);
                productList.add(productListItem);
            }
        }
        
        // Put the resulting data into the output map
        outputMap.put('products', ratedProducts);
        outputMap.put('productList', productList);
    }
}