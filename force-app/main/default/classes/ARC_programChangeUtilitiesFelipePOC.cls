global without sharing class ARC_programChangeUtilitiesFelipePOC implements vlocity_ins.VlocityOpenInterface{
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'CompareCensusMemberChanges') {
            CompareCensusMemberChanges(inputMap, outputMap, options);
        }
        
        if (methodName == 'ComparePlanSelectionChanges') {
            ComparePlanSelectionChanges(inputMap, outputMap, options);
        }
        
        return true;
    }

    // Method that compares the initial with the final Census Members values and
    public static void CompareCensusMemberChanges(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
        List<Object> initial_values = (List<Object>)inputMap.get('InitialValues'); // List of members BEFORE any changes
        List<Object> final_values = (List<Object>)inputMap.get('FinalValues'); // List of members AFTER changes

        Set<String> reasonSet = new Set<String>(); // Set of reasons to be returned to the OS
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
                
                reasonSet.add('Add Member');
                Integer newAge = (Integer)member_new_map.get('ARC_Age__c'); // Add 'Add Member' as a PC reason if any is true
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
                reasonSet.add('Remove Member'); // Add 'Remove Member' as a PC reasons if any is true
            }

            // Add Existing Member PC Reason
            Boolean isExistingMember = (Boolean)member_new_map.get('IsInactiveMember'); // Check if any member is a Existing Member
            if (isExistingMember != null && isExistingMember == true) {
                reasonSet.add('Add Existing Member'); // Add 'Add Existing Member' as a PC reason if any is true
            }

            // Get the oldest final member
            Integer finalAge = (Integer)member_new_map.get('ARC_Age__c');
            if (finalAge > finalAgeValue) {
                finalAgeValue = finalAge;
            }

            // Edge case where adding a new member and change primary to new member
            String finalId = (String)member_new_map.get('Id');
            if (finalId == '' && (Boolean)member_new_map.get('vlocity_ins__IsPrimaryMember__c') == true) {
                reasonSet.add('Primary Change');
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
                        reasonSet.add('Address State Change');
                    }
                }

                // Get inital and final IDs
                String oldMemberId = (String)member_old_map.get('Id');
                String newMemberId = (String)member_new_map.get('Id');
                if (oldMemberId == newMemberId) {
                    // Primary Change PC Reason
                    // Check if the Primary changes
                    if ((Boolean)member_old_map.get('vlocity_ins__IsPrimaryMember__c') == false && (Boolean)member_new_map.get('vlocity_ins__IsPrimaryMember__c') == true) {
                        reasonSet.add('Primary Change');
                    }

                    // Relationship to Primary Change PC Reason
                    // Get initial and final Relationship values
                    Map<String,Object> oldRelationshipMap = (Map<String,Object>)member_old_map.get('ARC_Relationship__c');
                    String oldRelationship = (String)oldRelationshipMap.get('value');
                    String newRelationship = (String)member_new_map.get('ARC_Relationship__c');
                    // Check if the relationship to Primary Change
                    if (oldRelationship != newRelationship && newRelationship != 'Primary' && oldRelationship != 'Primary') {
                        reasonSet.add('Relationship to Primary Change');
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
                reasonSet.add('Date of Birth Change');
            }
        }

        String pcReasonsString = String.join(reasonSet, ', '); 
        outputMap.put('PC_Reasons', pcReasonsString);
        outputMap.put('finalPrimaryValues', finalPrimaryValues);       
        
        //STEP_HIPAAAuthorizationForm.put('EDITBLK_HIPAAAuthorizedParties',mymap);
        System.debug(STEP_HIPAAAuthorizationForm);
        outputMap.put('STEP_HIPAAAuthorizationForm',mymap);
        
        //Add New Member Fl
        if(reasonSet.contains('Add Member')){
            outputMap.put('AddNewMember', true);    
        }
        else{
            outputMap.put('AddNewMember', false);
        }

        

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

    public static void ComparePlanSelectionChanges(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        // Get JSON inputs
        List<Object> oldProductsValues = (List<Object>)inputMap.get('oldProducts'); 
        List<Object> selectedProductsValues = (List<Object>)inputMap.get('selectedProducts');
        String updateType = (String)inputMap.get('updateType');
        String censusPcReasons = (String)inputMap.get('PC_Reasons');

        Map<String,Object> planSelectionOutput = new Map<String,Object>();
        List<String> pcReasonsList = new List<String>();
        pcReasonsList.add(censusPcReasons);        

        // Checks if New Contract is needed
        if (updateType.contains('Effective Date') || censusPcReasons.contains('Add Member') || censusPcReasons.contains('Add Existing Member') || censusPcReasons.contains('Remove Member') || censusPcReasons.contains('Primary Change') || censusPcReasons.contains('Relationship to Primary Change') || censusPcReasons.contains('Date of Birth Change') || censusPcReasons.contains('Address State Change')) {
            planSelectionOutput.put('createNewContract', true);
        }
        else {
            planSelectionOutput.put('createNewContract', false);
        }


        // Get selected medical plan
        List<String> MedicalNames = new List<String>(); // For test purpose
        String oldPlanName;
        String selectedPlanName;

        // Get old medical plan
        for (Object oldProducts : oldProductsValues) {
            Map<String,Object> old_products_map = (Map<String,Object>)oldProducts;
            String oldPlanType = (String)old_products_map.get('vlocity_ins__Type__c');
            if (oldPlanType == 'Medical') {
                oldPlanName = (String)old_products_map.get('Name');
                // for TEST purpose
                System.debug(oldPlanName);
                MedicalNames.add(oldPlanName);
            }
        }

        // Get selected medical plan
        for (Object selectedProducts : selectedProductsValues) {
            Map<String,Object> selected_products_map = (Map<String,Object>)selectedProducts;
            String selectedPlanType = (String)selected_products_map.get('Type__c');
            if (selectedPlanType == 'Medical') {
                selectedPlanName = (String)selected_products_map.get('Name');
                // for TEST purpose
                system.debug(selectedPlanName);
                MedicalNames.add(selectedPlanName);
            }
        }

        if (oldPlanName != selectedPlanName) {
            Integer oldPlanNameLastIndex = oldPlanName.lastIndexOf('k');
            String oldPlanString = oldPlanName.substring(oldPlanNameLastIndex-2,oldPlanNameLastIndex);
            Integer oldPlanNumber;
            if (oldPlanString.contains(' ')) {
                oldPlanNumber = Integer.valueOf(oldPlanString.substring(1));
            }
            else {
                oldPlanNumber = Integer.valueOf(oldPlanString);
            }
            System.debug(oldPlanNumber);        

            Integer selectedPlanNameLastIndex = selectedPlanName.lastIndexOf('k');
            String selectedPlanString = selectedPlanName.substring(selectedPlanNameLastIndex-2,selectedPlanNameLastIndex);
            Integer selectedPlanNumber;
            if (selectedPlanString.contains(' ')) {
                selectedPlanNumber = Integer.valueOf(selectedPlanString.substring(1));
            }
            else {
                selectedPlanNumber = Integer.valueOf(selectedPlanString);
            }
            System.debug(selectedPlanNumber);

            if (oldPlanNumber>selectedPlanNumber) {
                pcReasonsList.add('Program Upgrade');
            }
            if (oldPlanNumber<selectedPlanNumber) {
                pcReasonsList.add('Program Downgrade');
            }
        }


        
        String pcReasons = String.join(pcReasonsList, ', ');
        planSelectionOutput.put('test', MedicalNames);
        planSelectionOutput.put('pcReasons', pcReasons);

        outputMap.put('planSelectionChanges',planSelectionOutput);
    }
}