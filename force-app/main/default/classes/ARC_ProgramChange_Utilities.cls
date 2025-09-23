global without sharing class ARC_ProgramChange_Utilities implements vlocity_ins.VlocityOpenInterface{
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        switch on methodName {
            when 'compareCensusMemberChanges'                    { compareCensusMemberChanges(inputMap, outputMap, options); }
            when 'censusPlanSelectionChanges'                    { censusPlanSelectionChanges(inputMap, outputMap, options); }
            when 'readMedicalQuestions'                          { readMedicalQuestions(inputMap, outputMap, options); }
            //when 'DocuSignDataTransform'                         { DocuSignDataTransform(inputMap, outputMap, options); }
            when 'TRANSFORM_CensusMemberToUserInputs'            { TRANSFORM_CensusMemberToUserInputs(inputMap, outputMap, options); }
            when 'TRANSFORM_ChooseProductSelectionData'          { TRANSFORM_ChooseProductSelectionData(inputMap, outputMap, options); }
            when 'includeGuardianAsHipaa'                        { includeGuardianAsHipaa(inputMap, outputMap, options); }
            when 'validateUpgradeAndMissingDemoInfo'             { validateUpgradeAndMissingDemoInfo(inputMap, outputMap, options); }
            when 'getUserPermission'                             { getUserPermission(inputMap, outputMap, options); }
            when else                                            { throw new AuraHandledException('Unknown method: ' + methodName); }
        }
        return true;
    }
    private static integer daysToAdd = 60;

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
            'effectiveDateChange' => false
        }; // Map of reasons to be returned to the OS


        Map<String,Object> finalPrimaryValues = new Map<String,Object>();
        Map<String,List<Map<String,Object>>> mymap = new Map<String,List<Map<String,Object>>>();
        Map<String,Object> STEP_HIPAAAuthorizationForm = new Map<String,List<Object>>();
        Map<String,Object> EDITBLK_HIPAAAuthorizedParties = new Map<String,Object>();
        List<Map<String,Object>> EDITBLK_HIPAAAuthorizedPartiesList = new List<Map<String,Object>>();
        List<Map<String,Object>> hipaaPartiesList = new List<Map<String,Object>>();
        Set<String> processedMemberIds = new Set<String>(); // Add this line to track processed members
        Integer initialOldestAge = 0;
        Integer finalOldestAge = 0;
        Boolean removeParent = false;
        Boolean DOBIsChange = false;

        //Build a Map for new and old values using id as the key
        Map<String,Object> newValuesMap = new Map<String,Object>();
        Map<String,Object> oldValuesMap = new Map<String,Object>();
        for (Object member_new : final_values) {
            Map<String,Object> member_new_map = (Map<String,Object>)member_new;
            newValuesMap.put((String)member_new_map.get('Id'), member_new_map);
        }
        for (Object member_old : initial_values) {
            Map<String,Object> member_old_map = (Map<String,Object>)member_old;
            oldValuesMap.put((String)member_old_map.get('Id'), member_old_map);
        }
        
        for (Object member_new : final_values) {
            
            Map<String,Object> member_new_map = (Map<String,Object>)member_new;

            // Get final primary values
            Boolean isFinalPrimary = (Boolean)member_new_map.get('vlocity_ins__IsPrimaryMember__c');
            Boolean isRemoveMember = (Boolean)member_new_map.get('IsRemoveMember');
            if (isFinalPrimary == true && isRemoveMember == false) {
                Boolean isUnder18;
                Integer finalPrimaryAge = (Integer)member_new_map.get('ARC_Age__c');
                // Get final primary member billing STATE
                String finalPrimaryStreet = member_new_map.containsKey('ARC_PhysicalAddressStreet__c')?(String)member_new_map.get('ARC_PhysicalAddressStreet__c'):'';
                String finalPrimaryCity = member_new_map.containsKey('ARC_PhysicalAddressCity__c')?(String)member_new_map.get('ARC_PhysicalAddressCity__c'):'';
                String finalPrimaryState = member_new_map.containsKey('ARC_PhysicalAddressState__c')?(String)member_new_map.get('ARC_PhysicalAddressState__c'):'';
                String finalPrimaryPostalCode = member_new_map.containsKey('ARC_PhysicalAddressZipCode__c')?(String)member_new_map.get('ARC_PhysicalAddressZipCode__c'):'';
                //Get final billing address
                if (finalPrimaryAge != null && finalPrimaryAge < 18) {
                    isUnder18 = true;
                }
                else {
                    isUnder18 = false;
                }
                finalPrimaryValues.put('isUnder18', isUnder18);
                finalPrimaryValues.put('billingState', finalPrimaryState);
                finalPrimaryValues.put('billingAddress', finalPrimaryStreet +', '+finalPrimaryCity+', '+finalPrimaryState+', '+finalPrimaryPostalCode);
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
                    //TXT_FirstName
                    EDITBLK_HIPAAAuthorizedParties.put('TXT_FirstName',(String)member_new_map.get('vlocity_ins__FirstName__c'));
                    //TXT_LastName
                    EDITBLK_HIPAAAuthorizedParties.put('TXT_LastName',(String)member_new_map.get('vlocity_ins__LastName__c'));
                    //TXT_Address
                    EDITBLK_HIPAAAuthorizedParties.put('TXT_Address',(String)member_new_map.get('ARC_Address__c'));
                    //TXT_City
                    EDITBLK_HIPAAAuthorizedParties.put('TXT_City',(String)member_new_map.get('ARC_PhysicalAddressCity__c'));
                    //TXT_ZipCode
                    EDITBLK_HIPAAAuthorizedParties.put('TXT_ZipCode',(String)member_new_map.get('ARC_PhysicalAddressZipCode__c'));
                    //TXT_Telephone
                    EDITBLK_HIPAAAuthorizedParties.put('TXT_Telephone',(String)member_new_map.get('ARC_Phone__c'));
                    //TXT_EmailAddress
                    EDITBLK_HIPAAAuthorizedParties.put('TXT_EmailAddress',(String)member_new_map.get('vlocity_ins__Email__c'));

                    EDITBLK_HIPAAAuthorizedParties.put('TXT_State',(String)member_new_map.get('ARC_PhysicalAddressState__c'));
                    tempMap.put('TXT_State',(String)member_new_map.get('ARC_PhysicalAddressState__c'));
                    tempMap.put('TXT_FullName',(String)member_new_map.get('vlocity_ins__FirstName__c') + ' ' + (String)member_new_map.get('vlocity_ins__LastName__c'));
                    tempMap.put('TXT_Relationship',(String)member_new_map.get('ARC_Relationship__c'));
                    tempMap.put('DAT_DOB',(String)member_new_map.get('vlocity_ins__Birthdate__c'));
                    tempMap.put('TXT_FirstName',(String)member_new_map.get('vlocity_ins__FirstName__c'));
                    tempMap.put('TXT_LastName',(String)member_new_map.get('vlocity_ins__LastName__c'));
                    tempMap.put('TXT_Address',(String)member_new_map.get('ARC_Address__c'));
                    tempMap.put('TXT_City',(String)member_new_map.get('ARC_PhysicalAddressCity__c'));
                    tempMap.put('TXT_ZipCode',(String)member_new_map.get('ARC_PhysicalAddressZipCode__c'));
                    tempMap.put('TXT_Telephone',(String)member_new_map.get('ARC_Phone__c'));
                    tempMap.put('TXT_EmailAddress',(String)member_new_map.get('vlocity_ins__Email__c'));
                    tempMap.put('Id',(String)member_new_map.get('Id'));
                    
                    hipaaPartiesList.add(tempMap);                    
                }
            }
            else if (isAddMember != null && isAddMember == false) {
                if(!oldValuesMap.containsKey((String)member_new_map.get('Id'))) {
                    Integer newAge = (Integer)member_new_map.get('ARC_Age__c'); 
                    if(newAge > 17){
                        Map<String, Object> tempMap = new Map<String, Object>();
                        EDITBLK_HIPAAAuthorizedParties.put('TXT_FullName',(String)member_new_map.get('vlocity_ins__FirstName__c') + ' ' + (String)member_new_map.get('vlocity_ins__LastName__c'));
                        EDITBLK_HIPAAAuthorizedParties.put('TXT_Relationship',(String)member_new_map.get('ARC_Relationship__c'));
                        EDITBLK_HIPAAAuthorizedParties.put('DAT_DOB',(String)member_new_map.get('vlocity_ins__Birthdate__c'));
                        //TXT_FirstName
                        EDITBLK_HIPAAAuthorizedParties.put('TXT_FirstName',(String)member_new_map.get('vlocity_ins__FirstName__c'));
                        //TXT_LastName
                        EDITBLK_HIPAAAuthorizedParties.put('TXT_LastName',(String)member_new_map.get('vlocity_ins__LastName__c'));
                        //TXT_Address
                        EDITBLK_HIPAAAuthorizedParties.put('TXT_Address',(String)member_new_map.get('ARC_Address__c'));
                        //TXT_City
                        EDITBLK_HIPAAAuthorizedParties.put('TXT_City',(String)member_new_map.get('ARC_PhysicalAddressCity__c'));
                        //TXT_ZipCode
                        EDITBLK_HIPAAAuthorizedParties.put('TXT_ZipCode',(String)member_new_map.get('ARC_PhysicalAddressZipCode__c'));
                        //TXT_Telephone
                        EDITBLK_HIPAAAuthorizedParties.put('TXT_Telephone',(String)member_new_map.get('ARC_Phone__c'));
                        //TXT_EmailAddress
                        EDITBLK_HIPAAAuthorizedParties.put('TXT_EmailAddress',(String)member_new_map.get('vlocity_ins__Email__c'));
                        EDITBLK_HIPAAAuthorizedParties.put('TXT_State',(String)member_new_map.get('ARC_PhysicalAddressState__c'));
                        tempMap.put('TXT_State',(String)member_new_map.get('ARC_PhysicalAddressState__c'));
                        tempMap.put('TXT_FullName',(String)member_new_map.get('vlocity_ins__FirstName__c') + ' ' + (String)member_new_map.get('vlocity_ins__LastName__c'));
                        tempMap.put('TXT_Relationship',(String)member_new_map.get('ARC_Relationship__c'));
                        tempMap.put('DAT_DOB',(String)member_new_map.get('vlocity_ins__Birthdate__c'));
                        tempMap.put('TXT_FirstName',(String)member_new_map.get('vlocity_ins__FirstName__c'));
                        tempMap.put('TXT_LastName',(String)member_new_map.get('vlocity_ins__LastName__c'));
                        tempMap.put('TXT_Address',(String)member_new_map.get('ARC_Address__c'));
                        tempMap.put('TXT_City',(String)member_new_map.get('ARC_PhysicalAddressCity__c'));
                        tempMap.put('TXT_ZipCode',(String)member_new_map.get('ARC_PhysicalAddressZipCode__c'));
                        tempMap.put('TXT_Telephone',(String)member_new_map.get('ARC_Phone__c'));
                        tempMap.put('TXT_EmailAddress',(String)member_new_map.get('vlocity_ins__Email__c'));
                        tempMap.put('Id',(String)member_new_map.get('Id'));
                        hipaaPartiesList.add(tempMap);                                           
                    }
                }
            }
            

            // Remove Member PC Reason
            if (isRemoveMember != null && isRemoveMember == true) {
                reasonsMap.put('removeMember', true); // Add 'Remove Member' as a PC reasons if any is true
            }

            // Add Existing Member PC Reason
            Boolean isExistingMember = (Boolean)member_new_map.get('IsInactiveMember'); // Check if any member is a Existing Member
            if (isExistingMember != null && isExistingMember == true) {
                reasonsMap.put('addExistingMember', true); // Add 'Add Existing Member' as a PC reason if any is true
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
                    Boolean isOldPrimary = (Boolean)member_old_map.get('vlocity_ins__IsPrimaryMember__c');
                    Boolean isNewPrimary = (Boolean)member_new_map.get('vlocity_ins__IsPrimaryMember__c');
                    Boolean isRemovedMember = (Boolean)member_new_map.get('IsRemoveMember');

                    if ((isOldPrimary == true && isNewPrimary == false) || (isOldPrimary == false && isNewPrimary == true && isRemovedMember == false) || (isOldPrimary == true && isNewPrimary == true && isRemovedMember == true)) {
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

                    // Check if any initial Primary or Spouse is removed
                    if (isRemoveMember == true && (oldRelationship == 'Primary' || oldRelationship == 'Spouse')) {
                        removeParent = true;
                    }

                    // DOB Change
                    Integer initialMemberAge = (Integer)member_old_map.get('ARC_Age__c');
                    Integer finalMemberAge = (Integer)member_new_map.get('ARC_Age__c');
                    // Overrides de initial age value when is older than the previous one to get the oldest initial value
                    if (initialMemberAge > initialOldestAge) {
                        initialOldestAge = initialMemberAge;
                    }
                    // Overrides de final age value when is older than the previous one to get the oldest final value
                    if (finalMemberAge > finalOldestAge) {
                        finalOldestAge = finalMemberAge;
                    }
                    // Checks if age of the member has changed and is older thanthe initial oldest age
                    if (finalOldestAge != initialOldestAge) {
                        DOBIsChange = true;
                    }
                }
            }
        }

        if(!mymap.containsKey('EDITBLK_HIPAAAuthorizedParties')) {
            mymap.put('EDITBLK_HIPAAAuthorizedParties', hipaaPartiesList);  
        }
        else {
            mymap.get('EDITBLK_HIPAAAuthorizedParties').addAll(hipaaPartiesList);
        } 

        // Date of Birth Change PC Reason
        // List of Age Gaps
        List<Integer> ageUp = new List<Integer>();
        List<String> ageBrackets = System.Label.ARC_AgeBracket.trim().split(',');
        for(String age:ageBrackets) ageUp.add(Integer.valueOf(age));
        Integer initialAgeUpIndex;
        Integer finalAgeUpIndex;
        // Checks if the initial Oldest Age is different from final Oldest Age
        if (DOBIsChange == true && initialOldestAge != finalOldestAge) {
            // Get the index of Age Gap list of initial and final Oldest Age
            initialAgeUpIndex = getAgeGapIndex(initialOldestAge, ageUp);
            finalAgeUpIndex = getAgeGapIndex(finalOldestAge, ageUp);
            // Checks if Indexes of initial and final Oldest Age are different
            if (initialAgeUpIndex != finalAgeUpIndex) {
                reasonsMap.put('dateOfBirthChange', true);
            }
        }

        Map<String,Object> pcChangesMap = new Map<String,Object>{
            'pcReasons' => reasonsMap
        };

        //STEP_HIPAAAuthorizationForm.put('EDITBLK_HIPAAAuthorizedParties',mymap);
        outputMap.put('STEP_HIPAAAuthorizationForm',mymap);

        outputMap.put('removeParent', removeParent);
        outputMap.put('pcChanges', pcChangesMap);
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
    * @MethodName         :   includeGuardianAsHipaa
    * @Description        :   Method to include Guardian's information to populate its Hipaa
    ********************************************************************/
    public static void includeGuardianAsHipaa(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String, Object> guardianValues = (Map<String, Object>)inputMap.get('STEP_GuardiansInfo');
        Map<String, Object> guardianAddressBlock = (Map<String, Object>)guardianValues.get('THEADBLK_GuardianAddress-Block');
        Map<String, Object> hipaa = new Map<String, Object>();

        hipaa.put('TXT_State',(String)guardianAddressBlock.get('TXT_GuardianState'));
        hipaa.put('TXT_FullName',(String)guardianValues.get('TXT_GuardianFirstName') + ' ' + (String)guardianValues.get('TXT_GuardianLastName'));
        hipaa.put('TXT_Relationship',(String)guardianValues.get('SEL_GuardianRelationship'));
        hipaa.put('DAT_DOB',(String)guardianValues.get('DATE_GuardianBirthdate'));
        hipaa.put('TXT_FirstName',(String)guardianValues.get('TXT_GuardianFirstName'));
        hipaa.put('TXT_LastName',(String)guardianValues.get('TXT_GuardianLastName'));
        hipaa.put('TXT_Address',(String)guardianAddressBlock.get('THEADBLK_GuardianAddress'));
        hipaa.put('TXT_City',(String)guardianAddressBlock.get('TXT_GuardianCity'));
        hipaa.put('TXT_ZipCode',(String)guardianAddressBlock.get('TXT_GuardianZipCode'));
        hipaa.put('TXT_Telephone',(String)guardianValues.get('TXT_GuardianPhone'));
        hipaa.put('TXT_EmailAddress',(String)guardianValues.get('EMAIL_GuardianEmail'));
        List<Map<String, Object>> hipaaList = new List<Map<String, Object>>();
        hipaaList.add(hipaa);

        Map<String, Object> hipaaBlock = new Map<String, Object>();
        hipaaBlock.put('EDITBLK_HIPAAAuthorizedParties', hipaaList);

        outputMap.put('STEP_HIPAAAuthorizationForm', hipaaBlock);
    }


    /*******************************************************************
    * @MethodName         :   censusPlanSelectionChanges
    * @Description        :   Method to analyze if Program is changed, a new contract is needed, a fee is applicable and which DocuSign needs to be sent
    ********************************************************************/
    public static void censusPlanSelectionChanges(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {   
        // Get JSON inputs
        List<Object> oldProductsValues = (List<Object>)inputMap.get('oldProducts');
        //List<Object> newProductsValues = (List<Object>)inputMap.get('newProducts');
        List<Object> newProductsValues = inputMap.containsKey('newProducts') && inputMap.get('newProducts') != null && inputMap.get('newProducts') != '' ? (List<Object>)inputMap.get('newProducts') : null;

        String updateType = (String)inputMap.get('updateType');
        Integer contractCount = (Integer)inputMap.get('contractCount');
        String oldEffectiveDateString = (String)inputMap.get('oldEffectiveDate');
        Date oldEffectiveDate = Date.parse(oldEffectiveDateString);
        String newEffectiveDateString = (String)inputMap.get('newEffectiveDate');
        Map<String,Object> finalPrimaryValuesMap;
        if (inputMap.containsKey('FinalPrimaryValues') && inputMap.get('FinalPrimaryValues') != null && inputMap.get('FinalPrimaryValues') != 'null') {
            Object finalPrimaryValues = inputMap.get('FinalPrimaryValues');
            if (finalPrimaryValues instanceof Map<String,Object>) {
                finalPrimaryValuesMap = (Map<String,Object>)finalPrimaryValues;
            } else if (finalPrimaryValues instanceof String) {
                try {
                    finalPrimaryValuesMap = (Map<String,Object>)JSON.deserializeUntyped((String)finalPrimaryValues);
                } catch (Exception e) {
                    finalPrimaryValuesMap = new Map<String,Object>();
                }
            } else {
                finalPrimaryValuesMap = new Map<String,Object>();
            }
        } else {
            finalPrimaryValuesMap = new Map<String,Object>();
        }
        String newBillingAddress = finalPrimaryValuesMap != null && finalPrimaryValuesMap.containsKey('billingAddress') ? (String)finalPrimaryValuesMap.get('billingAddress'): null;

        Date newEffectiveDate;
        Map <String,Object> selectedContractInfo = (Map<String,Object>)inputMap.get('selectedContractInfo');
        if (newEffectiveDateString != '') {
            newEffectiveDate = Date.valueOf(newEffectiveDateString);
        }
        // Get Selected Products and only when Change to Programs is selected in OS
        List<Object> selectedProductsValues = new List<Object>();
        if (updateType.contains('Change to Programs') && inputMap.containsKey('selectedProducts') && inputMap.get('selectedProducts') != '' && inputMap.get('selectedProducts') != null) {
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
            'effectiveDateChange' => false
        };
        // Get census pcReasons only when census is displayed
        if (updateType.contains('Add or Remove a Member') || updateType.contains('Demographic Updates')) {
            pcReasons = (Map<String,Object>)inputMap.get('pcReasons');
            if (updateType.contains('Demographic Updates')) {
                outputMap.put('demographicUpdates', true);
            } else {
                outputMap.put('demographicUpdates', false);
            }
        }

        // Output map to be returned to the OS
        Map<String,Object> pcChangesOutput = new Map<String,Object>();

        pcChangesOutput.put('carryOverMedicalQuestions', false);

        // Get selected medical plan
        String oldPlanName;
        String selectedPlanName;
        Set<String> oldAncillaryList = new Set<String>();
        Set<String> selectedAncillaryList = new Set<String>();
        Double oldMedicalPrice;
        Double newMedicalPrice;

        // Iterate over old product list
        for (Object oldProducts : oldProductsValues) {
            Map<String,Object> old_products_map = (Map<String,Object>)oldProducts;
            // Get old plan type
            String oldPlanType = (String)old_products_map.get('Type__c');
            if (oldPlanType == 'Medical') {
                // Get old medical plan name
                oldPlanName = (String)old_products_map.get('Name');
                oldMedicalPrice = (Double) old_products_map.get('Price');
            }
            if (oldPlanType == 'Ancillary') {
                String oldAncillaryName = (String)old_products_map.get('Name');
                oldAncillaryList.add(oldAncillaryName);
            }
        }

        // Iterate over selected products list
        if (selectedProductsValues != null && !selectedProductsValues.isEmpty()) {
            for (Object selectedProducts : selectedProductsValues) {
                Map<String,Object> selected_products_map = (Map<String,Object>)selectedProducts;
                String selectedPlanType = (String)selected_products_map.get('Type__c');
                if (selectedPlanType == 'Medical') {
                    selectedPlanName = (String)selected_products_map.get('Name');
                    newMedicalPrice= (Double) selected_products_map.get('Price');
                }
                if (selectedPlanType == 'Ancillary') {
                    String selectedAncillaryName = (String)selected_products_map.get('Name');
                    selectedAncillaryList.add(selectedAncillaryName); 
                }
            }
        }
        // Iterate over new products list
        if (newProductsValues != null) {
            for (Object newProduct : newProductsValues) {
                Map<String,Object> new_products_map = (Map<String,Object>)newProduct;
                Map<String,Object> selectedProduct_map = (Map<String,Object>)new_products_map.get('selectedProduct');
                String selectedProduct = (String)selectedProduct_map.get('Type__c');
                if (selectedProduct == 'Medical') {
                    newMedicalPrice= (Double)selectedProduct_map.get('Price');
                }
            }
        }


        if (updateType.contains('Change to Programs')) {
            // Checks if Ancillary list sizes are different or if Ancillaries have been all removed
            if (oldAncillaryList.size() != selectedAncillaryList.size() || (oldAncillaryList.size() > 0 && selectedAncillaryList.size() == 0)) {
                pcReasons.put('ancillaryChange', true);
            }
            // Checks when ancillary products size is the same but checks if they are different products
            if (oldAncillaryList.size() == selectedAncillaryList.size() && oldAncillaryList.size() > 0) {
                Integer coincidencesCount = 0;
                for (String oldAncillaryName : oldAncillaryList) {
                    for (String selectedAncillaryName : selectedAncillaryList) {
                        if (oldAncillaryName == selectedAncillaryName) {
                            coincidencesCount++;
                        }
                    }
                }
                // Coincidences should be the same as ancillary products, if not, there is an ancillary change
                pcReasons.put('ancillaryChange', coincidencesCount != selectedAncillaryList.size() ? true : false);
            }
        }

        Boolean isLegacyPlan = false;
        for (Object selectedProducts : selectedProductsValues) {
            Map<String,Object> selected_products_map = (Map<String,Object>)selectedProducts;
            String selectedPlanType = (String)selected_products_map.get('Type__c');
            if (selectedPlanType == 'Medical') {
                String selectedLegacyPlanType = (String)selected_products_map.get('Name');
                if (selectedLegacyPlanType != null && selectedLegacyPlanType.trim().toLowerCase() == 'weshare legacy'.toLowerCase()) {
                    isLegacyPlan = true;
                    break;
                }
            }
        }
        outputMap.put('isLegacyPlan', isLegacyPlan);
        pcReasons.put('agingOut',isLegacyPlan);


        // Get activated medical plan if contract list has more than one contract 
        if (contractCount > 1) {
            List<Object> contractList = (List<Object>)inputMap.get('contractList');
            for (Object contract : contractList) {
                Map<String,Object> contractMap = (Map<String,Object>)contract;
                String contractStatus = (String)contractMap.get('TXT_ContractStatus');
                if (contractStatus == 'Activated') {
                    String activatedMedicalPlan = (String)contractMap.get('TXT_MedicalPlan');
                    if (oldPlanName != activatedMedicalPlan) {
                        oldPlanName = activatedMedicalPlan;                 
                    }
                }
            }
        }

        // Handle PC reasons
        List<String> trueFeePcReasons = new List<String>();
        List<String> truePcReasons = new List<String>();
        String pcReasonsString;

        //Get the Fee amounts for Add Member, Program Upgrade & Program Downgrade
        ChargentBase__Chargent_Settings__c feeAmounts = [SELECT Id, Name, ARC_UpgradeChangeFee__c, ARC_AddMemberChangeFee__c,ARC_DowngradeChangeFee__c, ARC_AppFee__c FROM ChargentBase__Chargent_Settings__c LIMIT 1];
        Decimal addMemberFee = feeAmounts.ARC_AddMemberChangeFee__c;
        Decimal upgradeFee = feeAmounts.ARC_UpgradeChangeFee__c;
        Decimal downgradeFee = feeAmounts.ARC_DowngradeChangeFee__c;
        Decimal appFee = feeAmounts.ARC_AppFee__c;
        Boolean carryOverFeeApplicable = false;

        // Determines the Fee Amount if applies fee to the corresponding scenario
        // First set the fee amount to 0
        pcChangesOutput.put('feeAmount', 0);


        // Compare if old and selected medical plan are different
        if (oldPlanName != selectedPlanName && selectedPlanName != null && updateType.contains('Change to Programs')) {
            String procedureAPIName = 'GetPrograms_UpgradeAndDowngrade';
            // Call the Integration Procedure
            Map<String, Object> IPOutput = (Map<String, Object>) vlocity_ins.IntegrationProcedureService.runIntegrationProcedureServiceFromApex(procedureAPIName, new Map<String, Object>{'Program' => oldPlanName}, new Map<String, Object>());
            List<Object> resultList = (IPOutput.get('result') != null) ? (List<Object>) IPOutput.get('result') : new List<Object>();
            if (resultList[0] != null) {
                // Result Map with Upgrade and Downgrade Program results
                Map<String,Object> resultMap = (Map<String,Object>)resultList[0];
                // Get downgrade plans
                String downgradePlans = (String)resultMap.get('Downgrade Result');
                // Get upgrade plans
                String upgradePlans = (String)resultMap.get('Upgrade Result');
                if (downgradePlans.contains(selectedPlanName)  && !isLegacyPlan) {
                    pcReasons.put('programDowngrade', true);
                }
                if (upgradePlans.contains(selectedPlanName) && !isLegacyPlan) {
                    pcReasons.put('programUpgrade', true);
                }
            }
        }
        else if(updateType.contains('Change to Programs') && ((String)selectedContractInfo.get('TXT_ContractStatus')).contains('Awaiting')){
            if(((String)selectedContractInfo.get('TXT_ContractReason')).contains('Program Upgrade')){
                truePcReasons.add('Program Upgrade');
                carryOverFeeApplicable = true;
                pcChangesOutput.put('feeApplicable', true);
                pcChangesOutput.put('feeAmount', upgradeFee);
                pcChangesOutput.put('docuSign', 'PC DocuSign');
                pcChangesOutput.put('carryOverMedicalQuestions', true);
            }
            if(((String)selectedContractInfo.get('TXT_ContractReason')).contains('Program Downgrade')){
                carryOverFeeApplicable = true;
                truePcReasons.add('Program Downgrade');
                pcChangesOutput.put('feeApplicable', true);
                pcChangesOutput.put('feeAmount', downgradeFee);
                pcChangesOutput.put('docuSign', 'PC DocuSign');
            }
            if(((String)selectedContractInfo.get('TXT_ContractReason')).contains('New Application')){
                pcChangesOutput.put('feeApplicable', true);
                pcChangesOutput.put('feeAmount', appFee);
                trueFeePcReasons.add('New Application');
            }
        }
        // Boolean isActiveContract = (Boolean)((String)selectedContractInfo.get('TXT_ContractStatus')).contains('Activated');
        Boolean medicalPriceChange = (oldMedicalPrice ==  null || newMedicalPrice == null)? false:oldMedicalPrice != newMedicalPrice;

        if(medicalPriceChange){
            pcChangesOutput.put('priceChanged', true);
        }
        else{
            pcChangesOutput.put('priceChanged', false);
        }
        
        // Check if new Effective Date is changed
        if (newEffectiveDate != null && newEffectiveDate != oldEffectiveDate && 
            (newEffectiveDate > Date.today() && newEffectiveDate>oldEffectiveDate )||
            medicalPriceChange) {
            pcReasons.put('effectiveDateChange', true);
        }
        else if(newEffectiveDate != null && newEffectiveDate != oldEffectiveDate){
            pcChangesOutput.put('updateEffectiveDateChange', true);
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
        Boolean isEffectiveDateChange = (Boolean)pcReasons.get('effectiveDateChange');
        Boolean isAgingOut = (Boolean)pcReasons.get('agingOut');
        Boolean isLegacyProgramFlag = (Boolean)((String)selectedContractInfo.get('TXT_MedicalPlan')).contains('Legacy');
        
        // Checks if New Contract is needed
        if (isAddMember == true || isAddExistingMember == true || isRemoveMember == true || isPrimaryChange == true || isRelationshipToPrimaryChange == true || isDateOfBirthChange == true || isAddressStateChange == true || isProgramUpgrade == true || isProgramDowngrade == true || isAncillaryChange == true || isEffectiveDateChange == true || medicalPriceChange == true) {
            pcChangesOutput.put('createNewContract', true);
        }
        else {
            pcChangesOutput.put('createNewContract', false);
        }

        // Determines which DocuSign needs to be sent (Amendment or DocuSign)
        if (isAddMember == true || isRemoveMember == true || isAddExistingMember == true || isPrimaryChange == true || isProgramUpgrade == true || isProgramDowngrade == true || isAncillaryChange == true) {
            pcChangesOutput.put('docuSign', 'PC DocuSign');
        }
        else if(isAgingOut == true){
            pcChangesOutput.put('docuSign', 'Legacy'); 
        }
        else if (isRelationshipToPrimaryChange == true || isEffectiveDateChange || isAddressStateChange == true || isDateOfBirthChange == true || isLegacyProgramFlag == true) {
            if(!pcChangesOutput.containsKey('docuSign')){
                pcChangesOutput.put('docuSign', 'Amendment');
            }
        }
        else {
            pcChangesOutput.put('docuSign', null);
        }

        // Determines if Fee is aplicable or not
        if (isProgramUpgrade == true || isProgramDowngrade == true || isAddMember == true || isAddExistingMember == true || carryOverFeeApplicable) {
            pcChangesOutput.put('feeApplicable', true);
        }
        else {
            pcChangesOutput.put('feeApplicable', false);
        }
        
        // Sets the fee amount if corresponds
        if (pcChangesOutput.get('feeApplicable') == true) {
            if (isAddMember == true || isAddExistingMember == true) {
                if (addMemberFee > (Decimal)pcChangesOutput.get('feeAmount')) {
                    pcChangesOutput.put('feeAmount', addMemberFee);
                }
            }
            if (isProgramUpgrade == true) {
                // Reset the fee amount only if the new fee is higher than previous one or if fee amount was 0
                if (upgradeFee > (Decimal)pcChangesOutput.get('feeAmount')) {
                    pcChangesOutput.put('feeAmount', upgradeFee);
                }
            }
            if (isProgramDowngrade == true) {
                // Reset the fee amount only if the new fee is higher than previous one or if fee amount was 0
                if (downgradeFee > (Decimal)pcChangesOutput.get('feeAmount')) {
                    pcChangesOutput.put('feeAmount', downgradeFee);
                }
            }
        }



        // Get previous pc reasons
        if(pcChangesOutput.get('createNewContract') == true){
           
            if (((String)selectedContractInfo.get('TXT_ContractStatus')).contains('Awaiting')) {
                String previousTruePcReasonsString = (String)selectedContractInfo.get('TXT_ContractReason');
                List<String> previousTruePcReasonsList = previousTruePcReasonsString.split(';');
                for (String previousTrueReason : previousTruePcReasonsList) {
                    // Add previous true reason if reason is different from Program Downgrade/Upgrade
                    if (previousTrueReason != 'Program Upgrade' && previousTrueReason != 'Program Downgrade' ) {
                        // Add previouse true reason to list that will concatenate all reasons in a string
                        truePcReasons.add(previousTrueReason);
                        if (previousTrueReason == 'Add Member' || previousTrueReason == 'Add Existing Member') {
                            pcChangesOutput.put('carryOverMedicalQuestions', true);
                            pcChangesOutput.put('createNewContract', true);
                            pcChangesOutput.put('docuSign', 'PC DocuSign');
                            pcChangesOutput.put('feeApplicable', true);
                            pcChangesOutput.put('feeAmount', addMemberFee);
                        } else if (previousTrueReason == 'Remove Member' || previousTrueReason == 'Primary Change' || previousTrueReason == 'Add Ancillary Product') {
                            pcChangesOutput.put('docuSign', 'PC DocuSign');
                            pcChangesOutput.put('createNewContract', true);
                            if (previousTrueReason == 'Add Ancillary Product') {
                                previousTrueReason = 'Ancillary Change';
                            }
                        } else if (previousTrueReason == 'Effective Date Change' || previousTrueReason == 'Relationship to Primary Change' || previousTrueReason == 'Date of Birth Change' || previousTrueReason == 'State Change') {
                            pcChangesOutput.put('docuSign', pcChangesOutput.get('docuSign') == 'PC DocuSign' ? 'PC DocuSign' : 'Amendment');
                            pcChangesOutput.put('createNewContract', true);
                        }
                    } else if ((previousTrueReason == 'Program Upgrade' || previousTrueReason == 'Program Downgrade') && !updateType.contains('Change to Programs')) {
                        truePcReasons.add(previousTrueReason);
                        pcChangesOutput.put('createNewContract', true);
                        pcChangesOutput.put('docuSign', 'PC DocuSign');
                        pcChangesOutput.put('feeApplicable', true);
                        
                        if(previousTrueReason == 'Program Upgrade') {
                            pcChangesOutput.put('carryOverMedicalQuestions', true);
                        }

                        if (previousTrueReason == 'Program Upgrade' && (Decimal)pcChangesOutput.get('feeAmount') < upgradeFee) {
                            pcChangesOutput.put('feeAmount', upgradeFee);
                        }
                        if (previousTrueReason == 'Program Downgrade' && (Decimal)pcChangesOutput.get('feeAmount') < downgradeFee) {
                            pcChangesOutput.put('feeAmount', downgradeFee);
                        }
                    }
                }

                if(((String)selectedContractInfo.get('TXT_ContractReason')).contains('New Application')){
                    pcChangesOutput.put('feeAmount', appFee);
                    pcChangesOutput.put('feeApplicable', true);
                    trueFeePcReasons.add('New Application');
                }
            }
        }

        for (String key : pcReasons.keySet()) {
            if ((Boolean) pcReasons.get(key)) {
                if (key == 'addMember' && !truePcReasons.contains('Add Member')) {
                    truePcReasons.add('Add Member');
                    trueFeePcReasons.add('Add Member');
                }
                if (key == 'removeMember' && !truePcReasons.contains('Remove Member')) {
                    truePcReasons.add('Remove Member');
                }
                if (key == 'programUpgrade' && !truePcReasons.contains('Program Upgrade')) {
                    truePcReasons.add('Program Upgrade');
                    trueFeePcReasons.add('Program Upgrade');
                }
                if (key == 'programDowngrade' && !truePcReasons.contains('Program Downgrade')) {
                    truePcReasons.add('Program Downgrade');
                    trueFeePcReasons.add('Program Downgrade');
                }
                if (key == 'effectiveDateChange' && !truePcReasons.contains('Effective Date Change')) {
                    truePcReasons.add('Effective Date Change');
                }
                if (key == 'dateOfBirthChange' && !truePcReasons.contains('Date of Birth Change')) {
                    truePcReasons.add('Date of Birth Change');
                }
                if (key == 'relationshipToPrimaryChange' && !truePcReasons.contains('Relationship to Primary Change')) {
                    truePcReasons.add('Relationship to Primary Change');
                }
                if (key == 'addressStateChange' && !truePcReasons.contains('State Change')) {
                    truePcReasons.add('State Change');
                }
                if (key == 'ancillaryChange' && !truePcReasons.contains('Add Ancillary Product')) {
                    truePcReasons.add('Ancillary Change');
                }
                if (key == 'addExistingMember' && !truePcReasons.contains('Add Existing Member')) {
                    truePcReasons.add('Add Existing Member');
                }
                if (key == 'primaryChange' && !truePcReasons.contains('Primary Change')) {
                    truePcReasons.add('Primary Change');
                }
                if (key == 'agingOut' && !truePcReasons.contains('Aging Out')) {
                    truePcReasons.add('Aging Out');
                }
            }
            // Turn Eff Date Change to false if any other reason is true
            if (key != 'effectiveDateChange' && pcReasons.get(key) == true) {
                pcReasons.put('effectiveDateChange', false);
                Integer effDateIndex = truePcReasons.indexOf('Effective Date Change');
                if (effDateIndex >= 0) {
                    truePcReasons.remove(effDateIndex);
                }
            }
        }
        // Convert pc reason list into a string and add to output
        pcReasonsString = String.join(truePcReasons, '; ');
        pcChangesOutput.put('pcReasonsString', pcReasonsString);
        
        if (trueFeePcReasons.size() > 0) {
            String feePcReasonsString = String.join(trueFeePcReasons, ', ');
            String programSummaryFeeText = 'One Time Change Fee (' + feePcReasonsString + '): ' + (Decimal)pcChangesOutput.get('feeAmount');
            pcChangesOutput.put('programSummaryFeeText', programSummaryFeeText);
        }

        // True PC reasons for Amendment in case it corresponds
        List<String> amendmentReasons = new List<String>();
        for (String key : pcReasons.keySet()) {
            if ((Boolean) pcReasons.get(key) && pcChangesOutput.get('docuSign')=='Amendment') {
                if (key == 'effectiveDateChange' && newEffectiveDate > Date.today()) {
                    amendmentReasons.add('Effective Date Change To: '+newEffectiveDateString);
                }
                if (key == 'addressStateChange') {
                    amendmentReasons.add('Effective Date: '+newEffectiveDateString);
                    amendmentReasons.add('Primary Address State Changed: '+newBillingAddress);

                }
                if (key == 'dateOfBirthChange') {
                    String effDate = (newEffectiveDateString != null && newEffectiveDateString != '')? newEffectiveDateString:String.valueOf(oldEffectiveDate).substring(0,10);
                    amendmentReasons.add('Effective Date: '+effDate.replaceAll('/','-'));
                    amendmentReasons.add('DOB update cause a change in age bracket');

                }
                if (key == 'relationshipToPrimaryChange') {
                    String effDate = (newEffectiveDateString != null && newEffectiveDateString != '')? newEffectiveDateString:String.valueOf(oldEffectiveDate).substring(0,10);
                    amendmentReasons.add('Effective Date: '+effDate.replaceAll('/','-'));
                    amendmentReasons.add('Relationship to Primary Change');
                }
            }
        }
        if (amendmentReasons.size()>0) {
            String amendmentReasonsString = String.join(amendmentReasons, ' / ');
            // Add Amendment reasons string to output
            pcChangesOutput.put('amendmentReasons', amendmentReasonsString);
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
        Map<String, Object> pcChanges = (Map<String, Object>) inputMap.get('pcChanges');
        Map<String, Object> reasons =  new Map<String, Object>();

        if(pcChanges.containsKey('pcReasons')){
            reasons = (Map<String, Object>) pcChanges.get('pcReasons'); // Catch Program Change Reasons
        } 
 
        Boolean isAddMember = reasons.containsKey('addMember') ? (Boolean) reasons.get('addMember') : false;
        Boolean isProgramUpgrade = reasons.containsKey('programUpgrade') ?  (Boolean) reasons.get('programUpgrade') : false;
        Boolean isAddExistingMember = reasons.containsKey('addExistingMember') ? (Boolean) reasons.get('addExistingMember') : false;

        Boolean isCarryOverMedicalQuestions = pcChanges.containsKey('carryOverMedicalQuestions') ? (Boolean) pcChanges.get('carryOverMedicalQuestions') : false;
        
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
        

        
        // Output contractor
        Map<String, Object> stepMedicalQuestions = new Map<String, Object>();

        // Map questions values to blocks
        Map<String, List<Map<String, Object>>> questionsMap = new Map<String, List<Map<String, Object>>>();

        // Use to populate arc_SelectCensusMember and arc_SelectCensusMemberCancer LWC SELECTS on the Omniscript
        List<Object> selectCensusMemberList = new List<Object>();

        if (isProgramUpgrade || isAddExistingMember || isCarryOverMedicalQuestions) {
            
            Set<Id> activeMembers = new Set<Id>();

            if (censusMembers.Size() > 0) {
                // Populate Member Names on Omniscript inputs and store active members (exclude remove members and new members) to query medical questions
                for (Object member : censusMembers) {
                    Map<String, Object> memberMap = (Map<String, Object>) member;

                    Boolean isNewMember = memberMap.containsKey('IsNewMember') ? (Boolean) memberMap.get('IsNewMember') : false;
                    Boolean isRemoveMember = memberMap.containsKey('IsRemoveMember') ? (Boolean) memberMap.get('IsRemoveMember') : false;
                    Boolean isInactiveMember = memberMap.containsKey('IsInactiveMember') ? (Boolean) memberMap.get('IsInactiveMember') : false;

                    Boolean processMember = false;

                    // We add the member on the activeMembers set depending if is only programUpgrade, only addExisitingMember or both
                    if (isProgramUpgrade && !isAddExistingMember) {
                        processMember = !isNewMember && !isRemoveMember && !isInactiveMember;
                    } else if (!isProgramUpgrade && isAddExistingMember) {
                        processMember = !isNewMember && !isRemoveMember && isInactiveMember;
                    } else if (isProgramUpgrade && isAddExistingMember) {
                        processMember = !isNewMember && !isRemoveMember;
                    } else if (isCarryOverMedicalQuestions && !isNewMember && !isRemoveMember){
                        processMember = true;
                    }

                    if (processMember) {
                        addMemberNameToMedicalQuestions(memberMap, questionsMap, selectCensusMemberList);
                        activeMembers.add((String) memberMap.get('Id'));
                    }

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
        addQuestionResponse(questionsMap, 'EB_Physicians', 'TXT_CensusMemberId', memberId, memberId);

        Map<String, Object> selectMemberDetail = new Map<String, Object>();
        selectMemberDetail.put('CensusMemberName', fullName);
        selectMemberDetail.put('CensusMemberId', memberId);
        selectMemberDetail.put('Birthdate', memberBirthDate);

        selectCensusMemberList.add(selectMemberDetail);
    }

    /*******************************************************************
    * @MethodName         :   checkAncillaryChange
    * @Description        :   Method to check if we have an ancillarychange to pre populate each member product on choose products
    ********************************************************************/

    public static Boolean checkAncillaryChange(List<Object> selectedProductsValues, List<Object> oldProductsValues) {

        // Lists to hold the names of ancillary products
        Set<String> oldAncillaryList = new Set<String>();
        Set<String> selectedAncillaryList = new Set<String>();

        // Extract ancillary products from the old product list
        if (oldProductsValues != null) {
            for (Object oldProduct : oldProductsValues) {
                Map<String,Object> productMap = (Map<String,Object>)oldProduct;
                if ((String)productMap.get('Type__c') == 'Ancillary') {
                    oldAncillaryList.add((String)productMap.get('Name'));
                }
            }
        }

        // Extract ancillary products from the selected product list
        if (selectedProductsValues != null) {
            for (Object selectedProduct : selectedProductsValues) {
                Map<String,Object> productMap = (Map<String,Object>)selectedProduct;
                if ((String)productMap.get('Type__c') == 'Ancillary') {
                    selectedAncillaryList.add((String)productMap.get('Name'));
                }
            }
        }

        // If the list sizes are different or all ancillaries were removed, it's a change
        if (oldAncillaryList.size() != selectedAncillaryList.size() || 
            (oldAncillaryList.size() > 0 && selectedAncillaryList.size() == 0)) {
            return true;
        }

        // If the sizes are the same, check if the contents are different
        if (oldAncillaryList.size() == selectedAncillaryList.size() && oldAncillaryList.size() > 0) {
            Integer matchCount = 0;
            for (String oldName : oldAncillaryList) {
                if (selectedAncillaryList.contains(oldName)) {
                    matchCount++;
                }
            }        
            // If not all ancillaries match, then there's a change
            return matchCount != selectedAncillaryList.size();
        }

        // No ancillary change detected
        return false;
    }


    public static void TRANSFORM_CensusMemberToUserInputs(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        //HERE CHRIS
        List<Object> census_members = (List<Object>)inputMap.get('census_members');
        Date effectiveDate;
        String dateStr = (String)inputMap.get('effectiveDate');
        if(String.isNotBlank(dateStr)) {
            try {
                // Handle both MM/DD/YYYY and YYYY-MM-DD formats
                if(dateStr.contains('-')) {
                    effectiveDate = Date.valueOf(dateStr);
                } else {
                    effectiveDate = Date.parse(dateStr);
                }
            } catch(Exception e) {
                System.debug('Error parsing date: ' + dateStr + ' - ' + e.getMessage());
                throw new AuraHandledException('Invalid date format: ' + dateStr);
            }
        }
        List<Map<String, Object>> user_input_list = new List<Map<String, Object>>();

        Boolean hasPrimary = false;
        Boolean hasSpouse = false;
        Integer dependentCount = 0;
        Integer oldestAge = 0;

        for (Object cm_object : census_members) {
            Map<String,Object> census_member = (Map<String,Object>)cm_object;
            Map<String, Object> user_input = new Map<String, Object>();

            if ((Boolean)census_member.get('IsRemoveMember') == false) {
                Integer age;
                if (effectiveDate != null){
                    age = calculateAge(Date.valueOf((String)census_member.get('vlocity_ins__Birthdate__c')),effectiveDate.addDays(daysToAdd));
                }
                else age = (Integer)census_member.get('ARC_Age__c');
                
                // Track oldest age
                if (age > oldestAge) {
                    oldestAge = age;
                }

                user_input.put('RF_Census.CM_Age', age);
                user_input.put('RF_Census.CRF_PrimaryMemberDOB', (String)census_member.get('vlocity_ins__Birthdate__c'));
                user_input.put('RF_Census.CM_State', census_member.get('ARC_PhysicalAddressState__c'));
                user_input.put('RF_Census.CM_IsPrimary', (String)census_member.get('ARC_Relationship__c') == 'Primary' ? true : false);
                user_input.put('RF_Census.CM_Relationship', census_member.get('ARC_Relationship__c'));
                user_input.put('RF_Census.CM_Smoker', (census_member.get('ARC_Smoker__c') instanceof Boolean && (Boolean)census_member.get('ARC_Smoker__c') == true) ? true : false);
                user_input.put('RF_Census.CM_Pregnant', (census_member.get('ARC_isPregnant__c') instanceof Boolean && (Boolean)census_member.get('ARC_isPregnant__c') == true) ? true : false);
                user_input.put('RF_Census.CM_FirstName', census_member.get('vlocity_ins__FirstName__c'));
                user_input.put('RF_Census.CM_LastName', census_member.get('vlocity_ins__LastName__c'));
                user_input.put('IsRemoveMember', census_member.get('IsRemoveMember'));
                user_input.put('IsNewMember', census_member.get('IsNewMember'));
                user_input.put('IsAddExistingMember', (census_member.get('IsNewMember') instanceof Boolean && (Boolean)census_member.get('IsNewMember') == false) && (census_member.get('IsInactiveMember') instanceof Boolean && (Boolean)census_member.get('IsInactiveMember') == true) ? true : false);


                user_input.put('Id', census_member.get('Id'));
                user_input_list.add(user_input);
                
                String relationship = (String)census_member.get('ARC_Relationship__c');
                if (relationship == 'Primary') {
                    hasPrimary = true;
                } else {
                    dependentCount++;
                    if (relationship == 'Spouse') {
                        hasSpouse = true;
                    }
                }
            }
        }
        // Sort the list: Primary first, Spouse second, Child last
        user_input_list.sort(new RelationshipComparator());

        Integer extraDependents = hasSpouse == true ? Math.max(dependentCount - 4, 0) : Math.max(dependentCount - 3, 0);
        String aidd = 'Family';
        String smart = 'Family';
        Integer user_input_list_size = user_input_list.size();

        if (hasPrimary && user_input_list_size == 1) {
            aidd = 'Primary';
            smart = 'Primary';
        } else if (hasPrimary && hasSpouse && user_input_list_size == 2) {
            aidd = 'Primary + Spouse';
            smart = 'Primary + Spouse';
        } else if (hasPrimary && !hasSpouse && user_input_list_size > 1) {
            aidd = 'Primary + Children';
            smart = 'Primary + Child';
        }

        for (Object ui_object : user_input_list) {
            Map<String,Object> user_input = (Map<String,Object>)ui_object;
            user_input.put('RF_Census.CRF_Coverage', smart);
            user_input.put('RF_Census.CRF_CoverageAIDD', aidd);
            user_input.put('RF_Census.CRF_ExtraDependants', extraDependents);
            user_input.put('RF_Census.CRF_PrimaryMemberAge', oldestAge);
            user_input.put('RF_Census.CRF_Dependants', dependentCount);
        }

        outputMap.put('userInputs', user_input_list);

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

    public static void TRANSFORM_ChooseProductSelectionData(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        List<Object> selectedProducts;
        List<Object> oldProducts;
        Boolean haveAncillaryChange = false;
        Boolean removeParent = inputMap.get('removeParent') instanceof Boolean ? (Boolean)inputMap.get('removeParent') : false;

        // if (inputMap.get('selectedProducts') instanceof List<Object>) {
        //     selectedProducts = (List<Object>)inputMap.get('selectedProducts');
        // } else if (inputMap.get('oldProducts') instanceof List<Object>){
        //     oldProducts = (List<Object>)inputMap.get('oldProducts');
        // }
        if (inputMap.get('selectedProducts') instanceof List<Object>) {
            selectedProducts = (List<Object>)inputMap.get('selectedProducts');
        } 
        
        if (inputMap.get('oldProducts') instanceof List<Object>){
            oldProducts = (List<Object>)inputMap.get('oldProducts');
        }

        List<Object> userInputs = (List<Object>)inputMap.get('userInputs'); 
        Map<String,Integer> ageMembersMap = getOldestAgeMap(userInputs);
        Integer oldestMemberAge = (Integer)ageMembersMap.get('oldestAge');
        Boolean FRML_DisplayChooseProductSelectionStep = (Boolean)inputMap.get('FRML_DisplayChooseProductSelectionStep');

        if (FRML_DisplayChooseProductSelectionStep == true) {

            if (selectedProducts != null) {
                haveAncillaryChange = checkAncillaryChange(selectedProducts, oldProducts);
            }

            List<Map<String,Object>> member_list = new List<Map<String,Object>>();
            Map<String,Boolean> shareSMART = new Map<String,Boolean>{'value' => true, 'disabled' => true};
            Map<String,Boolean> shareAIDD = new Map<String,Boolean>{'value' => true, 'disabled' => true};
            String lastProductSmart_ContractLineItemId;
            String lastProductAidd_ContractLineItemId;
            Map<String, Object> primary_information = new Map<String, Object>{
                'memberId' => null,
                'medical' => new Map<String,Object>{'value' => null, 'name' => null},
                'smart' => new Map<String,Object>{'value' => null, 'productId' => null, 'name' => null},
                'aidd' => new Map<String,Object>{'value' => null, 'productId' => null, 'name' => null}
            };
            Map<String, Object> spouse_information = new Map<String, Object>{
                'memberId' => null,
                'medical' => new Map<String,Object>{'value' => null, 'name' => null},
                'smart' => new Map<String,Object>{'value' => null, 'productId' => null, 'name' => null},
                'aidd' => new Map<String,Object>{'value' => null, 'productId' => null, 'name' => null}
            };

            for (Object user_input_object : userInputs) {
                Map<String,Object> user_input = (Map<String,Object>)user_input_object;
                String member_relationship = (String)user_input.get('RF_Census.CM_Relationship');
                if (member_relationship == 'Primary') primary_information.put('memberId', user_input.get('Id'));
                if (member_relationship == 'Spouse') spouse_information.put('memberId', user_input.get('Id'));

                Map<String, Object> medical_product = new Map<String, Object>{'value' => null, 'name' => null};
                Map<String, Object> smart_product = new Map<String, Object>{
                    'value' => null,
                    'name' => null,
                    'options' => new List<Map<String,Object>>()
                };
                Map<String, Object> aidd_product = new Map<String, Object>{
                    'value' => null,
                    'name' => null,
                    'options' => new List<Map<String,Object>>()
                };

                Map<String, Object> selected_parent = member_relationship == 'Child'? new Map<String,Object>{'value' => null, 'options' => new List<Map<String,Object>>()} : null;

                List<String> ancillary_product_list = new List<String>();

                Map<String, Object> member = new Map<String, Object>{
                    'id' => (String)user_input.get('Id'),
                    'name' => (String)user_input.get('RF_Census.CM_FirstName') + ' ' + (String)user_input.get('RF_Census.CM_LastName'),
                    'relationship' => member_relationship,
                    'isChild' => member_relationship == 'Child',
                    'medicalProduct' => medical_product,
                    'smartProduct' => smart_product,
                    'aiddProduct' => aidd_product,
                    'selectedParent' => selected_parent,
                    'ancillaryProductsToString' => '',
                    'user_input' => user_input
                };

                // Set Medical Product for all members
                if(selectedProducts != null){
                    for (Object product_object : selectedProducts) {
                        Map<String,Object> product = (Map<String,Object>)product_object;
                        String productType = (String)product.get('Type__c');
                        if (productType == 'Medical') {

                            medical_product.put('name', (String)product.get('Name'));
                            medical_product.put('value', (String)product.get('productId'));
                        }
                        
                    }
                } else if (oldProducts != null) {
                    for (Object product_object : oldProducts) {
                        Map<String,Object> product = (Map<String,Object>)product_object;
                        String productType = (String)product.get('Type__c');

                        if (productType == 'Medical') {
                            medical_product.put('name', (String)product.get('Name'));
                            medical_product.put('value', (String)product.get('productId'));
                        }
                    }
                }

                // Set Ancillary products for each member
                if(selectedProducts != null && haveAncillaryChange == true){
                    for (Object product_object : selectedProducts) {
                        Map<String,Object> product = (Map<String,Object>)product_object;
                        String productType = (String)product.get('Type__c');
                        String productSubType = (String)product.get('SubType__c');

                        // if (productType == 'Medical') {
                        //     medical_product.put('name', (String)product.get('Name'));
                        //     medical_product.put('value', (String)product.get('productId'));
                        // }
                        
                        if (member_relationship == 'Primary' || member_relationship == 'Spouse') {
                            if (productSubType == 'SMART'){
                                ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => false});
                            }
                            
                            else if (productSubType == 'AIDD'){
                                ((List<Map<String,Object>>)aidd_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => false});
                            }
                        }
                    }
                } else if (oldProducts != null) {
                    for (Object product_object : oldProducts) {

                        Map<String,Object> product = (Map<String,Object>)product_object;
                        String productType = (String)product.get('Type__c');
                        String productSubType = (String)product.get('SubType__c');

                        // if (productType == 'Medical') {
                        //     medical_product.put('name', (String)product.get('Name'));
                        //     medical_product.put('value', (String)product.get('productId'));
                        // }
                        

                        if (productSubType == 'SMART' && product.get('Id') != lastProductSmart_ContractLineItemId && lastProductSmart_ContractLineItemId != null) {
                            shareSMART.put('value', false);
                        } else if (productSubType == 'AIDD' && product.get('Id') != lastProductAidd_ContractLineItemId && lastProductAidd_ContractLineItemId != null) {
                            shareAIDD.put('value', false);
                        }

                        Boolean member_has_product = false;

                        for (Object census_member_object : (List<Object>)product.get('census_members')) {
                            Map<String,Object> census_member = (Map<String,Object>)census_member_object;
                            if ((String)user_input.get('Id') == (String)census_member.get('Id')) {
                                member_has_product = true;
                            }
                        }
                        
                        if (member_has_product == true) {
                            if (member_relationship == 'Primary') {
                                if (productSubType == 'SMART'){
                                    // ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                                    ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => true});
                                    smart_product.put('name', (String)product.get('Name'));
                                    smart_product.put('value', (String)product.get('productId'));
                                    ((Map<String,Object>)primary_information.get('smart')).put('value', product.get('Id'));
                                    ((Map<String,Object>)primary_information.get('smart')).put('productId', product.get('productId'));
                                    ((Map<String,Object>)primary_information.get('smart')).put('name', product.get('Name'));
                                } else if (productSubType == 'AIDD'){
                                    // ((List<Map<String,Object>>)aidd_product.get('options')).add(new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                                    ((List<Map<String,Object>>)aidd_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => true});
                                    aidd_product.put('name', (String)product.get('Name'));
                                    aidd_product.put('value', (String)product.get('productId'));
                                    ((Map<String,Object>)primary_information.get('aidd')).put('value', product.get('Id'));
                                    ((Map<String,Object>)primary_information.get('aidd')).put('productId', product.get('productId'));
                                    ((Map<String,Object>)primary_information.get('aidd')).put('name', product.get('Name'));
                                }
                            } else if (member_relationship == 'Spouse'){
                                if (productSubType == 'SMART'){
                                    // ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                                    ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => true});
                                    smart_product.put('name', (String)product.get('Name'));
                                    smart_product.put('value', (String)product.get('productId'));
                                    ((Map<String,Object>)spouse_information.get('smart')).put('value', product.get('Id'));
                                    ((Map<String,Object>)spouse_information.get('smart')).put('productId', product.get('productId'));
                                    ((Map<String,Object>)spouse_information.get('smart')).put('name', product.get('Name'));
                                } else if (productSubType == 'AIDD'){
                                    // ((List<Map<String,Object>>)aidd_product.get('options')).add(new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                                    ((List<Map<String,Object>>)aidd_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => true});
                                    aidd_product.put('name', (String)product.get('Name'));
                                    aidd_product.put('value', (String)product.get('productId'));
                                    ((Map<String,Object>)spouse_information.get('aidd')).put('value', product.get('Id'));
                                    ((Map<String,Object>)spouse_information.get('aidd')).put('productId', product.get('productId'));
                                    ((Map<String,Object>)spouse_information.get('aidd')).put('name', product.get('Name'));
                                }
                            } else if(member_relationship == 'Child') {

                                if (productSubType == 'SMART' || productSubType == 'AIDD'){
                                    if (
                                        (String)product.get('Id') == ((Map<String,Object>)primary_information.get(productSubType.toLowerCase())).get('value') &&
                                        (String)product.get('Id') == ((Map<String,Object>)spouse_information.get(productSubType.toLowerCase())).get('value')
                                    )
                                    {   
                                        if(((List<Map<String,Object>>)selected_parent.get('options')).isEmpty()){
                                            selected_parent.put('value', primary_information.get('memberId'));
                                            ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                                            ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Primary Program', 'value' => primary_information.get('memberId'), 'selected' => true});

                                            if((String)spouse_information.get('memberId') != null){
                                                ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Spouse Program', 'value' => spouse_information.get('memberId'), 'selected' => false});
                                            }

                                            smart_product.put('value', ((Map<String,Object>)primary_information.get('smart')).get('productId'));
                                            smart_product.put('name', ((Map<String,Object>)primary_information.get('smart')).get('name'));
                                            aidd_product.put('value', ((Map<String,Object>)primary_information.get('aidd')).get('productId'));
                                            aidd_product.put('name', ((Map<String,Object>)primary_information.get('aidd')).get('name'));

                                            ancillary_product_list.add((String)(((Map<String,Object>)primary_information.get('smart')).get('name')));
                                            ancillary_product_list.add((String)(((Map<String,Object>)primary_information.get('aidd')).get('name')));

                                        }
                                    }
                                    else if ((String)product.get('Id') == ((Map<String,Object>)primary_information.get(productSubType.toLowerCase())).get('value')) {
                                        if(((List<Map<String,Object>>)selected_parent.get('options')).isEmpty()){
                                            selected_parent.put('value', primary_information.get('memberId'));
                                            ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                                            ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Primary Program', 'value' => primary_information.get('memberId'), 'selected' => true});

                                            if((String)spouse_information.get('memberId') != null){
                                                ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Spouse Program', 'value' => spouse_information.get('memberId'), 'selected' => false});
                                            }

                                            smart_product.put('value', ((Map<String,Object>)primary_information.get('smart')).get('productId'));
                                            smart_product.put('name', ((Map<String,Object>)primary_information.get('smart')).get('name'));
                                            aidd_product.put('value', ((Map<String,Object>)primary_information.get('aidd')).get('productId'));
                                            aidd_product.put('name', ((Map<String,Object>)primary_information.get('aidd')).get('name'));

                                            ancillary_product_list.add((String)(((Map<String,Object>)primary_information.get('smart')).get('name')));
                                            ancillary_product_list.add((String)(((Map<String,Object>)primary_information.get('aidd')).get('name')));

                                        }

                                    }
                                    else if ((String)product.get('Id') == ((Map<String,Object>)spouse_information.get(productSubType.toLowerCase())).get('value')){
                                        if(((List<Map<String,Object>>)selected_parent.get('options')).isEmpty()){
                                            selected_parent.put('value', spouse_information.get('memberId'));
                                            ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                                            ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Primary Program', 'value' => primary_information.get('memberId'), 'selected' => false});
                                            ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Spouse Program', 'value' => spouse_information.get('memberId'), 'selected' => true});

                                            smart_product.put('value', ((Map<String,Object>)spouse_information.get('smart')).get('productId'));
                                            smart_product.put('name', ((Map<String,Object>)spouse_information.get('smart')).get('name'));
                                            aidd_product.put('value', ((Map<String,Object>)spouse_information.get('aidd')).get('productId'));
                                            aidd_product.put('name', ((Map<String,Object>)spouse_information.get('aidd')).get('name'));

                                            ancillary_product_list.add((String)(((Map<String,Object>)spouse_information.get('smart')).get('name')));
                                            ancillary_product_list.add((String)(((Map<String,Object>)spouse_information.get('aidd')).get('name')));

                                        }
                                    }
                                    else if (
                                        (String)product.get('Id') != ((Map<String,Object>)primary_information.get(productSubType.toLowerCase())).get('value') &&
                                        (String)product.get('Id') != ((Map<String,Object>)spouse_information.get(productSubType.toLowerCase())).get('value')
                                    ){
                                        if(((List<Map<String,Object>>)selected_parent.get('options')).isEmpty()){
                                            selected_parent.put('value', null);
                                            ancillary_product_list.add('None');
                                            ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Primary Program', 'value' => primary_information.get('memberId'), 'selected' => false});
                                            if((String)spouse_information.get('memberId') != null){
                                                ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Spouse Program', 'value' => spouse_information.get('memberId'), 'selected' => false});
                                            }
                                        }

                                        }
                                }
                            }

                        } else if (member_has_product == false) {
                            if (member_relationship == 'Primary' || member_relationship == 'Spouse') {

                                
                                if (productSubType == 'SMART'){
                                    ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => false});

                                } else if (productSubType == 'AIDD'){
                                    ((List<Map<String,Object>>)aidd_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => false});

                                }
                            } else if(member_relationship == 'Child'){
                                if(((List<Map<String,Object>>)selected_parent.get('options')).isEmpty()){
                                
                                        selected_parent.put('value', null);
                                        ancillary_product_list.add('None');

                                        ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Primary Program', 'value' => primary_information.get('memberId'), 'selected' => false});
                                        if((String)spouse_information.get('memberId') != null){
                                            ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Spouse Program', 'value' => spouse_information.get('memberId'), 'selected' => false});
                                        }
                                }
                            }
                        }

                        if (productSubType == 'SMART') {
                            lastProductSmart_ContractLineItemId = (String)product.get('Id');
                        } else if (productSubType == 'AIDD') {
                            lastProductAidd_ContractLineItemId = (String)product.get('Id');
                        }
                    }


                    // Delete duplicates options on smart_product
                    if (smart_product != null && smart_product.containsKey('options')) {
                        List<Map<String, Object>> smartOptions = (List<Map<String, Object>>) smart_product.get('options');
                        Map<Object, Map<String, Object>> uniqueSmartOptionsMap = new Map<Object, Map<String, Object>>();
                        for (Map<String, Object> option : smartOptions) {
                            Object value = option.get('value');
                            if (!uniqueSmartOptionsMap.containsKey(value)) {
                                uniqueSmartOptionsMap.put(value, option);
                            } else {
    
                                if ((Boolean)option.get('selected') == true) {
                                    uniqueSmartOptionsMap.put(value, option); 
                                }
                            }
                        }
                        smart_product.put('options', new List<Map<String, Object>>(uniqueSmartOptionsMap.values()));
                    }
                    
                    // Delete duplicates options on  aidd_product
                    if (aidd_product != null && aidd_product.containsKey('options')) {
                        List<Map<String, Object>> aiddOptions = (List<Map<String, Object>>) aidd_product.get('options');
                        Map<Object, Map<String, Object>> uniqueAiddOptionsMap = new Map<Object, Map<String, Object>>();
                        for (Map<String, Object> option : aiddOptions) {
                            Object value = option.get('value');
                            if (!uniqueAiddOptionsMap.containsKey(value)) {
                                uniqueAiddOptionsMap.put(value, option);
                            } else {
                                if ((Boolean)option.get('selected') == true) {
                                    uniqueAiddOptionsMap.put(value, option); 
                                }
                            }
                        }
                        aidd_product.put('options', new List<Map<String, Object>>(uniqueAiddOptionsMap.values()));
                    }
                    
                    member.put('ancillaryProductsToString', String.join(ancillary_product_list, ', '));
                }

                if (selectedProducts != null && haveAncillaryChange == true) {
                    shareSMART.put('value', false);
                    shareAIDD.put('value', false);

                    if (member_relationship == 'Primary' || member_relationship == 'Spouse') {

                        if (((List<Map<String,Object>>)smart_product.get('options')).isEmpty() == true) {
                            ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => true});
                            smart_product.put('value', 'None');
                            smart_product.put('name', 'None');
                        } else if (((List<Map<String,Object>>)smart_product.get('options')).isEmpty() == false) {
                            ((List<Map<String,Object>>)smart_product.get('options')).add(0, new Map<String,Object>{'label' => '-', 'value' => null, 'selected' => true});
                            ((List<Map<String,Object>>)smart_product.get('options')).add(1, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                        }

                        if (((List<Map<String,Object>>)aidd_product.get('options')).isEmpty() == true) {
                            ((List<Map<String,Object>>)aidd_product.get('options')).add(new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => true});
                            aidd_product.put('value', 'None');
                            aidd_product.put('name', 'None');
                        } else if (((List<Map<String,Object>>)aidd_product.get('options')).isEmpty() == false) {
                            ((List<Map<String,Object>>)aidd_product.get('options')).add(0, new Map<String,Object>{'label' => '-', 'value' => null, 'selected' => true});
                            ((List<Map<String,Object>>)aidd_product.get('options')).add(1, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                        }

                    } else if (member_relationship == 'Child') {
                        selected_parent.put('options', new List<Map<String,Object>>{
                            new Map<String,Object>{'value' => null, 'label' => '-', 'selected' => true},
                            new Map<String,Object>{'value' => 'None', 'label' => 'None', 'selected' => false},
                            new Map<String,Object>{'value' => primary_information.get('memberId'), 'label' => 'Primary Program', 'selected' => false}
                        });

                        if ((String)spouse_information.get('memberId') != null) {
                            ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'value' => spouse_information.get('memberId'), 'label' => 'Spouse Program', 'selected' => false});
                        }
                    }
                } else if(oldProducts != null) {
                    if (member_relationship == 'Primary' || member_relationship == 'Spouse') {
                        if ((Boolean)user_input.get('IsNewMember') == true || (Boolean)user_input.get('IsAddExistingMember') == true) {
                            if ((String)smart_product.get('value') == null) {
                                if (((List<Map<String,Object>>)smart_product.get('options')).isEmpty() == true) {
                                    ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => true});
                                    smart_product.put('value', 'None');
                                    smart_product.put('name', 'None');
                                } else if (((List<Map<String,Object>>)smart_product.get('options')).isEmpty() == false) {
                                    ((List<Map<String,Object>>)smart_product.get('options')).add(0, new Map<String,Object>{'label' => '-', 'value' => null, 'selected' => true});
                                    ((List<Map<String,Object>>)smart_product.get('options')).add(1, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                                }
                            }

                            if ((String)aidd_product.get('value') == null) {

                                if (((List<Map<String,Object>>)aidd_product.get('options')).isEmpty() == true) {
                                    ((List<Map<String,Object>>)aidd_product.get('options')).add(new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => true});
                                    aidd_product.put('value', 'None');
                                    aidd_product.put('name', 'None');
                                } else if (((List<Map<String,Object>>)aidd_product.get('options')).isEmpty() == false) {
                                    ((List<Map<String,Object>>)aidd_product.get('options')).add(0, new Map<String,Object>{'label' => '-', 'value' => null, 'selected' => true});
                                    ((List<Map<String,Object>>)aidd_product.get('options')).add(1, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                                }
                            }

                        } else if ((Boolean)user_input.get('IsNewMember') == false) {

                            if ((String)smart_product.get('value') == null) {
                                smart_product.put('value', 'None');
                                smart_product.put('name', 'None');
                                if (((List<Map<String,Object>>)smart_product.get('options')).isEmpty() == true) {
                                    ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => true});
                                } else if (((List<Map<String,Object>>)smart_product.get('options')).isEmpty() == false) {
                                    ((List<Map<String,Object>>)smart_product.get('options')).add(0, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => true});
                                }
                            } else {
                                if (((List<Map<String,Object>>)smart_product.get('options')).isEmpty() == true) {
                                    ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});

                                } else if (((List<Map<String,Object>>)smart_product.get('options')).isEmpty() == false) {
                                    ((List<Map<String,Object>>)smart_product.get('options')).add(0, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                                }
                            }
    
                            if ((String)aidd_product.get('value') == null) {
                                aidd_product.put('value', 'None');
                                aidd_product.put('name', 'None');
                                if (((List<Map<String,Object>>)aidd_product.get('options')).isEmpty() == true) {
                                    ((List<Map<String,Object>>)aidd_product.get('options')).add(new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => true});
                                } else if (((List<Map<String,Object>>)aidd_product.get('options')).isEmpty() == false) {
                                    ((List<Map<String,Object>>)aidd_product.get('options')).add(0, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => true});
                                }
                            } else {
                                if (((List<Map<String,Object>>)aidd_product.get('options')).isEmpty() == true) {
                                    ((List<Map<String,Object>>)aidd_product.get('options')).add(new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});

                                } else if (((List<Map<String,Object>>)aidd_product.get('options')).isEmpty() == false) {
                                    ((List<Map<String,Object>>)aidd_product.get('options')).add(0, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                                }
                            }

                        }

                    } else if (member_relationship == 'Child') {
                        if ((Boolean)user_input.get('IsNewMember') == true  || (Boolean)user_input.get('IsAddExistingMember') == true) {
                            if ((String)selected_parent.get('value') == null) {
                                ((List<Map<String,Object>>)selected_parent.get('options')).add(0, new Map<String,Object>{'label' => '-', 'value' => null, 'selected' => true});
                                ((List<Map<String,Object>>)selected_parent.get('options')).add(1, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                                // ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Primary Program', 'value' => (String)primary_information.get('memberId'), 'selected' => false});
                                // if ((String)spouse_information.get('memberId') != null) {
                                //     ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'label' => 'Spouse Program', 'value' => (String)spouse_information.get('memberId'), 'selected' => false});
                                //}
                            }
                        } else if ((Boolean)user_input.get('IsNewMember') == false) {
                            if ((String)selected_parent.get('value') == null) {
                                if (removeParent == true) {
                                    ((List<Map<String,Object>>)selected_parent.get('options')).add(0, new Map<String,Object>{'label' => '-', 'value' => null, 'selected' => true});
                                    ((List<Map<String,Object>>)selected_parent.get('options')).add(1, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                                } else if (removeParent == false) {
                                    ((List<Map<String,Object>>)selected_parent.get('options')).add(0, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => true});
                                    selected_parent.put('value', 'None');
                                }
                            }
                        }
                    }
                }

                member_list.add(member);
            }

            if (
                (String)spouse_information.get('memberId') != null && 
                ((Map<String,Object>)primary_information.get('smart')).get('value') == ((Map<String,Object>)spouse_information.get('smart')).get('value') &&
                ((Map<String,Object>)primary_information.get('smart')).get('value') != null && ((Map<String,Object>)spouse_information.get('smart')).get('value') != null
            ) {
                shareSMART.put('disabled', false);
                shareSMART.put('value', true);
            } else if (
                (String)spouse_information.get('memberId') != null && 
                ((Map<String,Object>)primary_information.get('smart')).get('value') != ((Map<String,Object>)spouse_information.get('smart')).get('value') &&
                ((Map<String,Object>)primary_information.get('smart')).get('value') != null && ((Map<String,Object>)spouse_information.get('smart')).get('value') != null &&
                ((Map<String,Object>)primary_information.get('smart')).get('productId') == ((Map<String,Object>)spouse_information.get('smart')).get('productId') &&
                ((Map<String,Object>)primary_information.get('smart')).get('productId') != null && ((Map<String,Object>)spouse_information.get('smart')).get('productId') != null
            ){

                shareSMART.put('disabled', false);
                shareSMART.put('value', false);
            } else {
                shareSMART.put('disabled', true);
                shareSMART.put('value', false);
            }

            // Here we check if spouse exist, and if spouse exist then check if is in the same CLI as the Primary, if not, then we check if they have the same product
            if (
                (String)spouse_information.get('memberId') != null &&
                ((Map<String,Object>)primary_information.get('aidd')).get('value') == ((Map<String,Object>)spouse_information.get('aidd')).get('value') &&
                ((Map<String,Object>)primary_information.get('aidd')).get('value') != null && ((Map<String,Object>)spouse_information.get('aidd')).get('value') != null
            ) {
                shareAIDD.put('disabled', false);
                shareAIDD.put('value', true);
            } else if(
                (String)spouse_information.get('memberId') != null &&
                ((Map<String,Object>)primary_information.get('aidd')).get('value') != ((Map<String,Object>)spouse_information.get('aidd')).get('value') &&
                ((Map<String,Object>)primary_information.get('aidd')).get('value') != null && ((Map<String,Object>)spouse_information.get('aidd')).get('value') != null &&
                ((Map<String,Object>)primary_information.get('aidd')).get('productId') == ((Map<String,Object>)spouse_information.get('aidd')).get('productId') &&
                ((Map<String,Object>)primary_information.get('aidd')).get('productId') != null && ((Map<String,Object>)spouse_information.get('aidd')).get('productId') != null
            ){
                shareAIDD.put('disabled', false);
                shareAIDD.put('value', false);
            }else {
                shareAIDD.put('disabled', true);
                shareAIDD.put('value', false);
            }

            outputMap.put('LWC_ChooseProductSelectionInput', new Map<String,Object>{'members' => member_list, 'shareSMART' => shareSMART, 'shareAIDD' => shareAIDD});

        } else if (FRML_DisplayChooseProductSelectionStep == false) {

            List<Map<String,Object>> products_list = new List<Map<String,Object>>();

             // Only when medical change
            if (selectedProducts != null) {
                for (Object product_object : selectedProducts) {
                    Map<String,Object> product = (Map<String,Object>)product_object;
                    
                    Map<String, Object> product_map = new Map<String, Object>{'selectedProduct' => new Map<String,Object>{'Id' => (String)product.get('productId')}, 'userInputs' => userInputs};
                    //Stamp oldestAge on each Member
                    for (Object user_input_object : (List<Object>)product_map.get('userInputs') ) {

                        Map<String,Object> user_input = (Map<String,Object>)user_input_object;
                        user_input.put('RF_Census.CRF_PrimaryMemberAge',oldestMemberAge);
                    }
                    products_list.add(product_map);
                }
                outputMap.put('LWC_ChooseProductSelectionOutput', products_list);
            }
            // The initial contract had ancillary, and nothing was changed || it was an add member action with no product changes and without previous ancillary
            else if (oldProducts != null) {

                String oldestMemberRelationShip;
                //For Each Line Item
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
                    
                    //For Each NEW USER INPUT
                    for (Object user_input_object : userInputs) {
                        Map<String,Object> user_input = new Map<String,Object>((Map<String,Object>)user_input_object);
                        //Primary -> Spouse -> Child

                        //FOR EACH OLD USER INPUT
                        for (Object census_member_object : (List<Object>)product.get('census_members')) {
                            Map<String,Object> census_member = (Map<String,Object>)census_member_object;
                            //Add the userInput if the member that we are in the loop of UserInput is included has the product.
                            if ((String)user_input.get('Id') == (String)census_member.get('Id')) {
                                if((Boolean)user_input.get('RF_Census.CM_IsPrimary') == true) hasPrimary = true;
                                if((Integer)user_input.get('RF_Census.CM_Age') == oldestMemberAge){
                                    oldestMemberRelationShip= (String)user_input.get('RF_Census.CM_Relationship');
                                    hasOldestMember=true;
                                }
                             
                                user_input.put('RF_Census.CRF_PrimaryMemberAge',oldestMemberAge);
                                ((List<Map<String,Object>>)product_map.get('userInputs')).add(user_input);
                            }
                            //Add new Members to the UserInputs of that product if they are included
                            else if (((Boolean)user_input.get('IsNewMember') == true || (Boolean)user_input.get('IsAddExistingMember') == true)&& !newMemberIds.contains((String)user_input.get('Id'))){
                                user_input.put('RF_Census.CRF_PrimaryMemberAge',oldestMemberAge);
                                if((Integer)user_input.get('RF_Census.CM_Age')== oldestMemberAge){
                                    oldestMemberRelationShip= (String)user_input.get('RF_Census.CM_Relationship');
                                    hasOldestMember=true;
                                }
                                ((List<Map<String,Object>>)product_map.get('userInputs')).add(user_input);
                                newMemberIds.add((String)user_input.get('Id'));
                            }
                        }

                    }

                    if((String)product.get('Type__c') == 'Ancillary'){
                        for(Object census_Member_object : (List<Map<String,Object>>)product_map.get('userInputs')){
                            Map<String,Object> census_Member_instance = (Map<String,Object>)census_Member_object;
                               
                            if((String)census_Member_instance.get('RF_Census.CM_Relationship') == 'Primary'){
                                countPrimary ++;
                            } else if ((String)census_Member_instance.get('RF_Census.CM_Relationship') == 'Spouse'){
                                countSpouse ++;
                            } else if((String)census_Member_instance.get('RF_Census.CM_Relationship') == 'Child'){
                                countChilds ++;
                            }
                        }
                    }

                    //Adjust the Oldest Member Age AND Primary Member on the procut if the Primary is not inlcuded or if the oldest member is not included. OR is Ancillary Product
                    if((String)product.get('Type__c') == 'Ancillary'){

                        for(Object census_Member_object : (List<Map<String,Object>>)product_map.get('userInputs')){
                            Map<String,Object> census_Member_instance = (Map<String,Object>)census_Member_object;
                            if(!hasPrimary){
                                if((String)census_Member_instance.get('RF_Census.CM_Relationship') == 'Spouse'){
                                    census_Member_instance.put('RF_Census.CM_IsPrimary',true);
                                }
                            }
                            if(!hasOldestMember){
                                if(oldestMemberRelationShip == 'Primary'){
                                    census_Member_instance.put('RF_Census.CRF_PrimaryMemberAge',(Integer)ageMembersMap.get('Spouse'));
                                }
                                else{
                                    census_Member_instance.put('RF_Census.CRF_PrimaryMemberAge',(Integer)ageMembersMap.get('Primary'));
                                }
                            }
                            // Set Coverages for Anillaries
                            // if ((String)product.get('Type__c') == 'Ancillary') {

                            if((countPrimary == 1 && countSpouse == 0 && countChilds == 0) || (countPrimary == 0 && countSpouse == 1 && countChilds == 0)){
                                census_Member_instance.put('RF_Census.CRF_Coverage','Primary');
                                census_Member_instance.put('RF_Census.CRF_CoverageAIDD','Primary');
                            } else if(countPrimary == 1 && countSpouse == 1 && countChilds == 0){ 
                                census_Member_instance.put('RF_Census.CRF_Coverage','Primary + Spouse');
                                census_Member_instance.put('RF_Census.CRF_CoverageAIDD','Primary + Spouse');
                            } else if((countPrimary == 1 && countSpouse == 0 && countChilds > 0) || (countPrimary == 0 && countSpouse == 1 && countChilds > 0)){
                                census_Member_instance.put('RF_Census.CRF_Coverage','Primary + Child');
                                census_Member_instance.put('RF_Census.CRF_CoverageAIDD','Primary + Children');
                            } else {
                                census_Member_instance.put('RF_Census.CRF_Coverage','Family');
                                census_Member_instance.put('RF_Census.CRF_CoverageAIDD','Family');
                            }
                                
                            // }
                        }
                    }

                    products_list.add(product_map);
                }
                
                outputMap.put('LWC_ChooseProductSelectionOutput', products_list);
            }
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

    /*******************************************************************
    * @MethodName         :   validateUpgradeAndMissingDemoInfo
    * @Description        :   Method to analyze if there is an Upgrade and member demographic information is missing
    ********************************************************************/
    public static void validateUpgradeAndMissingDemoInfo(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
        List<Object> census_Members = (List<Object>)inputMap.get('census_members'); // List of members BEFORE any changes
        String  oldMedical = (String)(inputMap.get('oldMedical')); // List of members BEFORE any changes
        List<Object> selectedProducts = (List<Object>)inputMap.get('selectedProducts'); // List of members BEFORE any changes
        String procedureAPIName = 'GetPrograms_UpgradeAndDowngrade';
        // Call the Integration Procedure
        Map<String, Object> IPOutput = (Map<String, Object>) vlocity_ins.IntegrationProcedureService.runIntegrationProcedureServiceFromApex(procedureAPIName, new Map<String, Object>{'Program' => oldMedical
    }, new Map<String, Object>());
        String selectedPlanName;
        // Iterate over selected products list
        if (selectedProducts != null) {
            for (Object selectedProduct : selectedProducts) {
                Map<String,Object> selected_products_map = (Map<String,Object>)selectedProduct;
                String selectedPlanType = (String)selected_products_map.get('Type__c');
                if (selectedPlanType == 'Medical') {
                    selectedPlanName = (String)selected_products_map.get('Name');
                    break;
                }
            }
        }
        List<Object> resultList = (IPOutput.get('result') != null) ? (List<Object>) IPOutput.get('result') : new List<Object>();
        if(Test.isRunningTest()){
            resultList = new List<Object>{
                new Map<String,Object>{'Upgrade Result'=>'WeShare 3k'}
            };
        }
        else{
            resultList = (IPOutput.get('result') != null) ? (List<Object>) IPOutput.get('result') : new List<Object>();
        }
        Boolean pcUpgrade=false;
        if (resultList[0] != null) {
            // Result Map with Upgrade and Downgrade Program results
            Map<String,Object> resultMap = (Map<String,Object>)resultList[0];
            // Get upgrade plans
            String upgradePlans = (String)resultMap.get('Upgrade Result');
            if (upgradePlans.contains(selectedPlanName)) {
                pcUpgrade = true;
            }
        }

        Boolean missingUWDemoInfo = false;
        for (Object cm_object : census_members) {
            Map<String,Object> census_member = (Map<String,Object>)cm_object;
            if(census_member.get('IsRemoveMember')==false){
                if((census_member.get('ARC_HeightFeet__c') == null)||
                (census_member.get('ARC_HeightInches__c') == null)||
                (census_member.get('ARC_Weight__c') == null)
                ){
                    missingUWDemoInfo=true;
                }
            }
        }
        if(missingUWDemoInfo && pcUpgrade){
            outputMap.put('isUpgradeAndMissingUWDemoInfo',true);
        }
        else{
            outputMap.put('isUpgradeAndMissingUWDemoInfo',false);
        }
    }

    /*******************************************************************
    * @MethodName         :   getUserPermission
    * @Description        :   Method to get all the Permissions assigned to the user
    ********************************************************************/
    public static void getUserPermission(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
        String userId = inputMap.containsKey('userId')? (String)inputMap.get('userId') : null;
        if(userId != null){
            Set<String> permissionSetList = new Set<String>();
            Set<Id> permissionSetGroupIds = new Set<Id>();
            List<PermissionSetAssignment> psAssignments = [SELECT Id,PermissionSet.Name,PermissionSetGroupId,PermissionSetId FROM PermissionSetAssignment WHERE (AssigneeId =: userId)];
            for(PermissionSetAssignment ps: psAssignments){
                permissionSetList.add(ps.PermissionSet?.Name);
                if(ps.PermissionSetGroupId != null) permissionSetGroupIds.add(ps.PermissionSetGroupId);
            }
            if(permissionSetGroupIds!= null){
                List<PermissionSetGroupComponent> psGroupAssignments = [SELECT Id,Permissionset.Name,PermissionSetGroupId,PermissionSetId FROM PermissionSetGroupComponent WHERE PermissionSetGroupId  IN: permissionSetGroupIds];
                for(PermissionSetGroupComponent psg: psGroupAssignments){
                    permissionSetList.add(psg.permissionset?.name);
                }
            }
            outputMap.put('Assignments',permissionSetList);
        }
    }

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

}