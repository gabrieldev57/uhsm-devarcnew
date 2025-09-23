public without sharing class ARC_SpinOff_Utilities {
    
    ////Main methods/////////////////////
    /////////////////////////////////////////////

    private static integer daysToAdd = 60;

    /**
     * Transform the census members to user inputs
     * @param {Map<String,Object>} inputMap - The input map.
     * @param {Map<String,Object>} outputMap - The output map.
     * @param {Map<String,Object>} options - The options map.
     * @returns {Map<String,Object>} - The output map.
     */
    public static Map<String,Object> TRANSFORM_CensusMemberToUserInputs(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        //Main method to transform the census members to user inputs
        

        // Get the census members from the input map so we can separate them into spinned off and retained
        Map<String, Object> census_component = (Map<String, Object>) inputMap.get('census_component');
        List<Object> census_members = (List<Object>) census_component.get('census_members');
        List<Object> census_members_all = getCensusMembers(inputMap);

        Map<String, Object> STEP_AccountSelection = (Map<String, Object>)inputMap.get('STEP_AccountSelection');
        Map<String, Object> aRC_DatePicker = (Map<String, Object>)STEP_AccountSelection.get('aRC_DatePicker');
        Date effectiveDate = Date.valueOf((String)aRC_DatePicker.get('DATE_SubscriberEffectiveDate'));


        // Determine if we have multiple families (more than 2 groups)
        Boolean hasMultipleFamilies = census_members.size() > 2;

        Map<String,String> memberIdToDOBMap = getMemberIdToDOBMap(census_members_all);

        if (hasMultipleFamilies) {
           
            // Create user inputs for each family group
            Integer familyCount = 0;
            for (Object census_member : census_members) {
                List<Object> census_member_family = (List<Object>) census_member;
                List<Map<String, Object>> userInputsForFamily = getCensusMembersToUserInputs(census_member_family, effectiveDate);
                
                userInputsForFamily = setPrimaryDOBForGroup(userInputsForFamily, memberIdToDOBMap);
                outputMap.put('userInputsFamily' + familyCount, userInputsForFamily);
                outputMap.put('family' + '_count', userInputsForFamily.size()); // Count the number of members in each family group
                familyCount++;
            }            
        } else {
            // Handle current case (2 groups - retained vs spinned off)
            List<Map<String, Object>> user_input_list = new List<Map<String, Object>>();
            List<Map<String, Object>> user_input_list_retained = new List<Map<String, Object>>();

            // Create the census members lists to seprate spinned from retained and place in the output map so we can count them
            List<Object> census_members_spinned_off =  (List<Object>) census_members[1]; //members spinned-off (selected at first screen)
            List<Object> census_members_retained = (List<Object>) census_members[0];


            // Get the user inputs for the spinned off and retained members and place in the output map
            user_input_list = getCensusMembersToUserInputs(census_members_spinned_off, effectiveDate);
            user_input_list_retained = getCensusMembersToUserInputs(census_members_retained, effectiveDate);

            // Set the primary DOB in all members
            user_input_list = setPrimaryDOBForGroup(user_input_list, memberIdToDOBMap);
            user_input_list_retained = setPrimaryDOBForGroup(user_input_list_retained, memberIdToDOBMap);
           
            // Put the user inputs in the output map so we can display them in the UI
            outputMap.put('userInputs', user_input_list); // List for repricing Spinned off members During Flow
            outputMap.put('userInputsRetained', user_input_list_retained); // List for repricing Retained members
            outputMap.put('spinned_off_count', census_members_spinned_off.size()); 
            outputMap.put('retained_count', census_members_retained.size());
        }

        // Create Spin Off members links
        Map<String, Object> step_membersToSpinOff = (Map<String, Object>) inputMap.get('STEP_MembersToSpinOff');
        List<Object> membersToSpinOffList = (List<Object>) step_membersToSpinOff.get('EDITBLK_membersToSpinOff');

        List<Map<String, Object>> membersToSpinOffFilterList = new List<Map<String, Object>>();
        String htmlList = '<ul style="list-style-type: disc; padding-left: 20px;">';

        for (Object mSO : membersToSpinOffList) {
            Map<String, Object> member = (Map<String, Object>) mSO;
            Boolean isSelected = (Boolean) member.get('CHK_spinOffSelection');

            if (isSelected != null && isSelected) {
                membersToSpinOffFilterList.add(member);

                String accountId = (String) member.get('TXT_AccountId');
                String firstName = (String) member.get('TXT_FirstName');
                String lastName = (String) member.get('TXT_LastName');

                htmlList += '<li style="margin-bottom: 6px;">'
                        + '<a href="/lightning/r/Account/' + accountId + '/view" '
                        + 'style="color: #2f1ae8; font-weight: 600; text-decoration: underline; cursor: pointer;">'
                        + firstName + ' ' + lastName + '</a></li>';

            }
        }

        htmlList += '</ul>';
        outputMap.put('HTML_membersToSpinOffLinks', htmlList);

        
        return outputMap;
    }

     /**
     * Fetches active census members for a given census ID.
     * @param {Map<String,Object>} input_map - Contains the census_id.
     * @param {Map<String,Object>} output_map - Stores the fetched census members.
     * @param {Map<String,Object>} options_map - Additional options (unused).
     */
    public static void GET_CensusMembers(Map<String, Object> input_map, Map<String, Object> output_map) {
        List<Map<String, Object>> census_members_list = new List<Map<String, Object>>();
        Id contractId = (Id) input_map.get('contract_id');
        Boolean clean_output = (Boolean)input_map.get('clean_output');
        Set<Id> censusMemberIds = getContractMemberIds(contractId);


        List<ARC_ContractParticipant__c> contractParticipants = [
            SELECT Id, ARC_PersonAccount__r.Census_Member__c, ARC_Relationship__c, ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressCity__c, 
                ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressState__c, ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressStreet__c, ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressZipCode__c
            FROM ARC_ContractParticipant__c
            WHERE ARC_Contract__c = :contractId AND ARC_Relationship__c != null
        ];

        // Map census members with contract participant relationships
        Map<Id, String> censusMemberRelationshipMap = new Map<Id, String>();
        vlocity_ins__GroupCensusMember__c primaryMember;
        for (ARC_ContractParticipant__c contractParticipant : contractParticipants) {
            if (contractParticipant.ARC_Relationship__c == 'Primary') {
                primaryMember = contractParticipant.ARC_PersonAccount__r.Census_Member__r;
            }
            censusMemberRelationshipMap.put(contractParticipant.ARC_PersonAccount__r.Census_Member__c, contractParticipant.ARC_Relationship__c);
        }

        // Query active census members
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
            Map<String,Object> member_map = createMemberMap(member, censusMemberRelationshipMap, primaryMember);
            if (clean_output == true) member_map = cleanCensusMemberMapFields(member_map);
            census_members_list.add(member_map);
        }
        output_map.put('census_members', census_members_list);
    }

    
    /**
    * Method to analyze if Program is changed, a fee is applicable and build spin off reasons
     * @param {Map<String,Object>} inputMap - The input map.
     * @param {Map<String,Object>} outputMap - The output map.
     * @param {Map<String,Object>} options - The options map.
     * @returns {Map<String,Object>} - The output map.
    */ 
    public static void censusPlanSelectionChanges(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {   
        Boolean IsPCSpinOff = inputMap.get('IsPCSpinOff') instanceof Boolean ? (Boolean)inputMap.get('IsPCSpinOff') : false;

        String selectedReasons;
        String keepSameProducts;
        Boolean multipleSOChangeProgram = false;
        Boolean singleSOChangeProgram = false;

        if (IsPCSpinOff) {
            selectedReasons = (String)inputMap.get('SEL_UpdateTypes');
            multipleSOChangeProgram = selectedReasons.contains('Change to Programs') ? true : false;
        }
        else {
            keepSameProducts = inputMap.containsKey('keepSameProducts') ? (String)inputMap.get('keepSameProducts') : null;
            singleSOChangeProgram = keepSameProducts == 'No' ? true : false;
        }

        List<Object> selectedProductsList = null;
        if (inputMap.get('selectedProducts') instanceof List<Object>) {
            selectedProductsList = (List<Object>)inputMap.get('selectedProducts');
        } 
        
        List<Object> oldProductsList = null;
        if (inputMap.get('oldProducts') instanceof List<Object>){
            oldProductsList = (List<Object>)inputMap.get('oldProducts');
        }

        List<Object> censusMembersList = null;
        if (inputMap.get('censusMembers') instanceof List<Object>){
            censusMembersList = (List<Object>)inputMap.get('censusMembers');
        }
              
        //New Logic for HIPAA STEP
        Map<String,List<Map<String,Object>>> hipaaStepMap = new Map<String,List<Map<String,Object>>>();
        List<Map<String,Object>> hipaaPartiesList = new List<Map<String,Object>>();
        Map<String,Object> finalPrimaryValues = new Map<String,Object>();
        
        // Output map to be returned to the OS: soReasonsOutput
        Map<String,Object> soReasonsOutput = new Map<String,Object>();
        Map<String,Object> soReasons = new Map<String,Object>{
            'spinOff' => true,
            'programUpgrade' => false,
            'programDowngrade' => false,
            'agingOut' => false,
            'addMember' => false,
            'removeMember' => false,
            'ancillaryChange' => false
        };
        String soReasonsString = 'Spin Off; ';
        String soFeeReasonsString = '';
        soReasonsOutput.put('feeAmount', 0);

        // Get old and selected medical plans
        String oldMedicalName;
        Set<String> oldAncillaryList = new Set<String>();
        String selectedMedicalName;
        Set<String> selectedAncillaryList = new Set<String>();

        // Iterate over old product list and selected product list to get the old and new medical's name and ancillary lists
        if(oldProductsList != null) {
            for (Object oldProducts : oldProductsList) {
                Map<String,Object> old_products_map = (Map<String,Object>)oldProducts;
                String oldPlanType = (String)old_products_map.get('Type__c');

                if (oldPlanType == 'Medical') {
                    oldMedicalName = (String)old_products_map.get('Name');
                }
                if (oldPlanType == 'Ancillary') {
                    String oldAncillaryName = (String)old_products_map.get('Name');
                    oldAncillaryList.add(oldAncillaryName);
                }
            }
        }

        if (selectedProductsList != null) {
            for (Object selectedProducts : selectedProductsList) {
                Map<String,Object> selected_products_map = (Map<String,Object>)selectedProducts;
                String selectedPlanType = (String)selected_products_map.get('Type__c');

                if (selectedPlanType == 'Medical') {
                    selectedMedicalName = (String)selected_products_map.get('Name');
                }
                if (selectedPlanType == 'Ancillary') {
                    String selectedAncillaryName = (String)selected_products_map.get('Name');
                    selectedAncillaryList.add(selectedAncillaryName); 
                }
            }
        }

        // If not keep the same products and Selected Program aren't Legacy use the IP to compare the products, else if the product are Legacy agingOut must be true
        if ((singleSOChangeProgram || multipleSOChangeProgram) && (selectedMedicalName != 'WeShare Legacy')) {
            String procedureAPIName = 'GetPrograms_UpgradeAndDowngrade';
            Map<String, Object> IPOutput = (Map<String, Object>) vlocity_ins.IntegrationProcedureService.runIntegrationProcedureServiceFromApex(procedureAPIName, new Map<String, Object>{'Program' => oldMedicalName}, new Map<String, Object>());
            List<Object> resultList = (IPOutput.get('result') != null) ? (List<Object>) IPOutput.get('result') : new List<Object>();
            if (resultList[0] != null) {
                Map<String,Object> resultMap = (Map<String,Object>)resultList[0];
                String downgradePlans = (String)resultMap.get('Downgrade Result');
                String upgradePlans = (String)resultMap.get('Upgrade Result');
                if (downgradePlans.contains(selectedMedicalName)) {
                    soReasons.put('programDowngrade', true);
                    soReasonsString += 'Program Downgrade; ';
                }
                if (upgradePlans.contains(selectedMedicalName)) {
                    soReasons.put('programUpgrade', true);
                    soReasonsString += 'Program Upgrade; ';
                }
            }

            // Checks if Ancillary list sizes are different or if Ancillaries have been all removed
            // when ancillary products size is the same checks if they are different products
            if (oldAncillaryList.size() != selectedAncillaryList.size() || (oldAncillaryList.size() > 0 && selectedAncillaryList.size() == 0)) {
                soReasons.put('ancillaryChange', true);
                soReasonsString += 'Ancillary Change; ';
            }
            if (oldAncillaryList.size() == selectedAncillaryList.size() && oldAncillaryList.size() > 0) {
                Integer coincidencesCount = 0;
                for (String oldAncillaryName : oldAncillaryList) {
                    for (String selectedAncillaryName : selectedAncillaryList) {
                        if (oldAncillaryName == selectedAncillaryName) {
                            coincidencesCount++;
                        }
                    }
                }
                if(coincidencesCount != selectedAncillaryList.size()) {
                    soReasons.put('ancillaryChange', true);
                    soReasonsString += 'Ancillary Change; ';
                }
            }
        }
        else if((singleSOChangeProgram || multipleSOChangeProgram) && (selectedMedicalName == 'WeShare Legacy')) {
            soReasons.put('agingOut', true);
            soReasonsString += 'Aging Out; ';
        }

        // Check if there are multiple Primary. case when I delete the member that is to be Spinned Off and change the relationship of the other member to be the new Primary.
        List<Map<String, Object>> primaryMember = new List<Map<String, Object>>();

            if (censusMembersList != null) {
                for (Object obj : censusMembersList) {
                    Map<String, Object> member = (Map<String, Object>)obj;
                
                    if ('Primary'.equals(member.get('ARC_Relationship__c')) &&
                        !(Boolean)member.get('IsRemoveMember')) {
                        primaryMember.add(member);
                        break; // solo uno esperado
                    }
                }
            }

        // If are members with the field (addMember || removeMember) == true add the reason
        for (Object censusmember : censusMembersList) { 
            Map<String,Object> member = (Map<String,Object>)censusmember;

            //HIPAA Step
            Boolean isPrimary = (Boolean)member.get('vlocity_ins__IsPrimaryMember__c');
            Boolean isRemoved = (Boolean)member.get('IsRemoveMember');

            if ((Boolean)member.get('IsNewMember') == true) {
                soReasons.put('addMember', true);
                if (!soReasonsString.contains('Add Member')) {
                    soReasonsString += 'Add Member; ';
                } 
            }
            
            //HIPAA STEP - only include members >= 18 that will not be removed
            Integer memberAge = (Integer)member.get('ARC_Age__c'); 
            if(memberAge != null && memberAge >= 18 && isRemoved != true){
                Map<String, Object> hipaaParty = new Map<String, Object>();
            
                hipaaParty.put('TXT_FullName',(String)member.get('vlocity_ins__FirstName__c') + ' ' + (String)member.get('vlocity_ins__LastName__c'));
                hipaaParty.put('TXT_Relationship',(String)member.get('ARC_Relationship__c'));
                hipaaParty.put('DAT_DOB',(String)member.get('vlocity_ins__Birthdate__c'));
                hipaaParty.put('CHK_Authorized', true);
                String memberId = (member.containsKey('Id') && (String)member.get('Id') != null) ? (String)member.get('Id') : null;
                if(memberId != null){
                    hipaaParty.put('Id',memberId);
                }
                hipaaParty.put('TXT_firstName',(String)member.get('vlocity_ins__FirstName__c'));
                hipaaParty.put('TXT_lastName',(String)member.get('vlocity_ins__LastName__c'));
                hipaaParty.put('TXT_Address',(String)member.get('ARC_PhysicalAddressStreet__c'));
                hipaaParty.put('TXT_City',(String)member.get('ARC_PhysicalAddressCity__c'));
                hipaaParty.put('TXT_State',(String)member.get('ARC_PhysicalAddressState__c'));
                hipaaParty.put('TXT_ZipCode',(String)member.get('ARC_PhysicalAddressZipCode__c'));
                hipaaParty.put('TXT_EmailAddress',(String)member.get('vlocity_ins__Email__c'));
                hipaaParty.put('TXT_Telephone',(String)member.get('ARC_Phone__c'));

                hipaaPartiesList.add(hipaaParty);
            }  

            if ((Boolean)member.get('IsRemoveMember') == true) {
                soReasons.put('removeMember', true);
                if (!soReasonsString.contains('Remove Member')) {
                    soReasonsString += 'Remove Member; ';
                }
            }
        }

        //HIPAA Step logic to get final primary values
        if(censusMembersList != null) {
            for (Object censusmember : censusMembersList) { 
                Map<String,Object> member = (Map<String,Object>)censusmember;
                
                // Only primary member
                Boolean isPrimary = (Boolean)member.get('vlocity_ins__IsPrimaryMember__c');
                Boolean isRemoved = (Boolean)member.get('IsRemoveMember');
                
                if (isPrimary == true && isRemoved == false) {
                    Boolean isUnder18;
                    Integer primaryAge = (Integer)member.get('ARC_Age__c');
                    
                    // Get primary member address info
                    String primaryStreet = (String)member.get('ARC_PhysicalAddressStreet__c');
                    String primaryCity = (String)member.get('ARC_PhysicalAddressCity__c');
                    String primaryState = (String)member.get('ARC_PhysicalAddressState__c');
                    String primaryPostalCode = (String)member.get('ARC_PhysicalAddressZipCode__c');
                    String primaryFirstName = (String)member.get('vlocity_ins__FirstName__c');
                    String primaryLastName = (String)member.get('vlocity_ins__LastName__c');
                    // Determine if under 18
                    if (primaryAge != null && primaryAge < 18) {
                        isUnder18 = true;
                    } else {
                        isUnder18 = false;
                    }
                    
                    finalPrimaryValues.put('isUnder18', isUnder18);
                    finalPrimaryValues.put('billingState', primaryState);
                    finalPrimaryValues.put('billingAddress', primaryStreet + ', ' + primaryCity + ', ' + primaryState + ', ' + primaryPostalCode);
                    finalPrimaryValues.put('primaryStreet',primaryStreet);
                    finalPrimaryValues.put('primaryCity', primaryCity);
                    finalPrimaryValues.put('primaryState', primaryState);
                    finalPrimaryValues.put('primaryPostalCode', primaryPostalCode);
                    finalPrimaryValues.put('primaryFirstName', primaryFirstName);
                    finalPrimaryValues.put('primaryLastName', primaryLastName);
                    break; // Solo hay un primary, salir del loop
                }
            }
        }

        // If any of the reasons for the spin-off are true, it query its fee amount
        // reset the fee amount only if the new fee is higher than previous one or if fee amount was 0
        if ((Boolean)soReasons.get('addMember') || (Boolean)soReasons.get('programUpgrade') || (Boolean)soReasons.get('programDowngrade')) {
            ChargentBase__Chargent_Settings__c feeAmounts = [SELECT Id, Name, ARC_UpgradeChangeFee__c, ARC_AddMemberChangeFee__c,ARC_DowngradeChangeFee__c, ARC_AppFee__c FROM ChargentBase__Chargent_Settings__c LIMIT 1];
            Decimal addMemberFee = feeAmounts.ARC_AddMemberChangeFee__c;
            Decimal upgradeFee = feeAmounts.ARC_UpgradeChangeFee__c;
            Decimal downgradeFee = feeAmounts.ARC_DowngradeChangeFee__c;

            soReasonsOutput.put('feeApplicable', true);

            if ((Boolean)soReasons.get('addMember')) {
                if (addMemberFee > (Decimal)soReasonsOutput.get('feeAmount')) { 
                    soReasonsOutput.put('feeAmount', addMemberFee);
                    soFeeReasonsString += 'Add Member, ';
                }
                System.debug('test' + (Decimal)soReasonsOutput.get('feeAmount'));
            }
            if ((Boolean)soReasons.get('programUpgrade')) {
                if (upgradeFee > (Decimal)soReasonsOutput.get('feeAmount')) {
                    soReasonsOutput.put('feeAmount', upgradeFee);
                    soFeeReasonsString += 'Program Upgrade, ';
                }
                System.debug('test' + (Decimal)soReasonsOutput.get('feeAmount'));
            }
            if ((Boolean)soReasons.get('programDowngrade')) {
                if (downgradeFee > (Decimal)soReasonsOutput.get('feeAmount')) {
                    soReasonsOutput.put('feeAmount', downgradeFee);
                    soFeeReasonsString += 'Program Downgrade, ';
                }
                System.debug('test' + (Decimal)soReasonsOutput.get('feeAmount'));
            }
        }
        else if (!IsPCSpinOff || (IsPCSpinOff && selectedReasons.equals('Complete Spin-Off without Changes'))) {
            soReasonsOutput.put('feeApplicable', false);
        }


        if (soReasonsString.endsWith('; ')) {
            soReasonsString = soReasonsString.substring(0, soReasonsString.length() - 2);
        }

        if (soFeeReasonsString.endsWith(', ')) {
            soFeeReasonsString = soFeeReasonsString.substring(0, soFeeReasonsString.length() - 2);
        }

        if (soFeeReasonsString != null) {
            String programSummaryFeeText = 'One Time Change Fee (' + soFeeReasonsString + '): ' + (Decimal)soReasonsOutput.get('feeAmount');
            soReasonsOutput.put('programSummaryFeeText', programSummaryFeeText);
        }

        soReasonsOutput.put('soReasons', soReasons);
        soReasonsOutput.put('soReasonsString', soReasonsString);
        outputMap.put('soChanges', soReasonsOutput);

        //HIPAA STEP
        //Boolean hasAdultMembers = !hipaaPartiesList.isEmpty();
        
        if(!hipaaPartiesList.isEmpty()) {
            hipaaStepMap.put('EDITBLK_HIPAAAuthorizedParties', hipaaPartiesList);
            outputMap.put('STEP_HIPAAAuthorizationForm', hipaaStepMap);
        } else {
            hipaaStepMap.put('EDITBLK_HIPAAAuthorizedParties', new List<Map<String,Object>>());
            outputMap.put('STEP_HIPAAAuthorizationForm', hipaaStepMap);
        }
        
        //outputMap.put('showHIPAAEditBlock', hasAdultMembers);
        outputMap.put('finalPrimaryValues', finalPrimaryValues);
    }

    /*******************************************************************
    * @MethodName         :   includeGuardianAsHipaa
    * @Description        :   Method to include Guardian's information to populate its Hipaa
    ********************************************************************/
    public static void includeGuardianAsHipaa(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        System.debug('includeGuardianAsHipaa');

        //Get guardian info
        Map<String, Object> guardianValues = (Map<String, Object>)inputMap.get('STEP_GuardiansInformation');
        System.debug('guardianValues: ' + guardianValues);

        if(guardianValues != null) {
            Map<String, Object> guardianAddressBlock = (Map<String, Object>)guardianValues.get('THEADBLK_GuardianAddress-Block');
            Map<String, Object> hipaa = new Map<String, Object>();

            //Map fields to Guardian step
            hipaa.put('TXT_FullName', (String)guardianValues.get('TXT_GuardianFirstName') + ' ' + (String)guardianValues.get('TXT_GuardianLastName'));
            hipaa.put('TXT_firstName', (String)guardianValues.get('TXT_GuardianFirstName'));
            hipaa.put('TXT_lastName', (String)guardianValues.get('TXT_GuardianLastName'));
            hipaa.put('TXT_Relationship', (String)guardianValues.get('SEL_GuardianRelationship'));
            hipaa.put('DAT_DOB', (String)guardianValues.get('DATE_GuardianBirthdate'));
            hipaa.put('TXT_Telephone', (String)guardianValues.get('TXT_GuardianPhone'));
            hipaa.put('TXT_EmailAddress', (String)guardianValues.get('EMAIL_GuardianEmail'));
            hipaa.put('CHK_Authorized', true); // Default value

            if(guardianAddressBlock != null) {
                hipaa.put('TXT_State', (String)guardianAddressBlock.get('TXT_GuardianState'));
                hipaa.put('TXT_Address', (String)guardianAddressBlock.get('TXT_GuardianStreet'));
                hipaa.put('TXT_City', (String)guardianAddressBlock.get('TXT_GuardianCity'));
                hipaa.put('TXT_ZipCode', (String)guardianAddressBlock.get('TXT_GuardianZipCode'));
            }

            List<Map<String, Object>> hipaaList = new List<Map<String, Object>>();
            hipaaList.add(hipaa);

            Map<String, Object> hipaaBlock = new Map<String, Object>();
            hipaaBlock.put('EDITBLK_HIPAAAuthorizedParties', hipaaList);

            outputMap.put('STEP_HIPAAAuthorizationForm', hipaaBlock);
            System.debug('outputMap: ' + outputMap);
            //outputMap.put('showHIPAAEditBlockGuardian', true);

        } else {
            System.debug('No guardian data found in inputMap');
            //outputMap.put('showHIPAAEditBlockGuardian', false);
        }
    }

    /**
    * Method to transform data of remove member contract and send it to calculate price lwc
     * @param {Map<String,Object>} inputMap - The input map.
     * @param {Map<String,Object>} outputMap - The output map.
     * @param {Map<String,Object>} options - The options map.
     * @returns {Map<String,Object>} - The output map.
    */
    public static Map<String,Object> TRANSFORM_RemoveMemberContractCalculatePrice(Map<String, Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {

        List<Object> userInputs;
        List<Object> oldProducts;
        List<Map<String,Object>> products_list = new List<Map<String,Object>>();
        List<Map<String,Object>> products_list_to_review = new List<Map<String,Object>>();

        if (inputMap.get('userInputsOriginal') instanceof List<Object>){
            userInputs = (List<Object>)inputMap.get('userInputsOriginal');
        }

        if (inputMap.get('oldProducts') instanceof List<Object>){
            oldProducts = (List<Object>)inputMap.get('oldProducts');
        }
        
        if (oldProducts != null) {

            for (Object product_object : oldProducts) {
                Map<String,Object> product = (Map<String,Object>)product_object;
                Map<String, Object> product_map = new Map<String, Object>{'selectedProduct' => new Map<String,Object>{'Id' => (String)product.get('productId'), 'Name' => (String)product.get('Name')}, 'userInputs' => new List<Map<String,Object>>()};
                
                Integer countPrimary = 0;
                Integer countSpouse = 0;
                Integer countChilds = 0;
                Integer oldestAge = 0;
                Boolean hasOnlyChilds = false;
                
                for (Object user_input_object : userInputs) {
                    Map<String,Object> user_input = new Map<String,Object>((Map<String,Object>)user_input_object);
                    for (Object census_member_object : (List<Object>)product.get('census_members')) {
                        Map<String,Object> census_member = (Map<String,Object>)census_member_object;
                        if ((String)user_input.get('Id') == (String)census_member.get('Id')) {
                            if((String)user_input.get('RF_Census.CM_Relationship') == 'Primary'){
                                countPrimary ++;
                            } else if ((String)user_input.get('RF_Census.CM_Relationship') == 'Spouse'){
                                countSpouse ++;
                            } else if((String)user_input.get('RF_Census.CM_Relationship') == 'Child'){
                                countChilds ++;
                            }

                            if((Integer)user_input.get('RF_Census.CM_Age')>oldestAge){
                                oldestAge = (Integer)user_input.get('RF_Census.CM_Age');
                            }

                            ((List<Map<String,Object>>)product_map.get('userInputs')).add(user_input);
                        }
                    }
                }

                hasOnlyChilds = (countChilds > 0 && countPrimary == 0 && countSpouse == 0);

                if((String)product.get('Type__c') == 'Ancillary' && hasOnlyChilds == false ){
                    
                        for(Object census_Member_object : (List<Map<String,Object>>)product_map.get('userInputs')){                         
                            Map<String,Object> census_Member_instance = (Map<String,Object>)census_Member_object;

                            // Set Old member age to product
                            census_Member_instance.put('RF_Census.CRF_PrimaryMemberAge',oldestAge);

                            // If no primary, set spouse as primary to product
                            if(countPrimary == 0 && (String)census_Member_instance.get('RF_Census.CM_Relationship') == 'Spouse'){
                                census_Member_instance.put('RF_Census.CM_IsPrimary',true);
                            }

                            // Set Coverages for Anillaries
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

                        }

                }

                // If product not have userinput, not add to any list
                if (((List<Map<String,Object>>)product_map.get('userInputs')).isEmpty()) {
                    continue;
                }

                if(hasOnlyChilds){
                    products_list_to_review.add(product_map);
                } else {
                    products_list.add(product_map);
                }
            }

            List<Map<String, Object>> products_lost = new List<Map<String, Object>>();

            // If we have a product only with childs, we check if that product is in products_list and add the childs, if we don't find nothig, childs will lose ancillaries
            if (!products_list_to_review.isEmpty()) {
                for (Map<String, Object> reviewProduct : products_list_to_review) {

                    Map<String, Object> reviewSelectedProduct = (Map<String, Object>) reviewProduct.get('selectedProduct');
                    String reviewProductId = (String) reviewSelectedProduct.get('Id');

                    for (Map<String, Object> mainProduct : products_list) {
                        Map<String, Object> mainSelectedProduct = (Map<String, Object>) mainProduct.get('selectedProduct');
                        String mainProductId = (String) mainSelectedProduct.get('Id');


                        if (reviewProductId == mainProductId) {
                            List<Map<String, Object>> mainUserInputs = (List<Map<String, Object>>) mainProduct.get('userInputs');
                            List<Map<String, Object>> reviewUserInputs = (List<Map<String, Object>>) reviewProduct.get('userInputs');
                            
                            mainUserInputs.addAll(reviewUserInputs);

                            for(Map<String, Object> ui : mainUserInputs){
                                Map<String, Object> ui_instance = (Map<String,Object>)ui;
                                ui_instance.put('RF_Census.CRF_Coverage','Primary + Child');
                                ui_instance.put('RF_Census.CRF_CoverageAIDD','Primary + Children');       
                            }

                            break;
                        }
                    }
                }
            }

            outputMap.put('transformUserInputsRetainedPriceData', products_list);
        }
        return outputMap;
    }
    
    /**
    * Method to transform data of member spin off family and send it to calculate price lwc
     * @param {Map<String,Object>} inputMap - The input map.
     * @param {Map<String,Object>} outputMap - The output map.
     * @param {Map<String,Object>} options - The options map.
     * @returns {Map<String,Object>} - The output map.
    */
    public static Map<String,Object> TRANSFORM_ChooseProductSelectionData(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        List<Object> selectedProducts;
        List<Object> oldProducts;
        List<Object> userInputs;
        Boolean isPcSpinOff = inputMap.containsKey('IsPCSpinOff') ? (Boolean)inputMap.get('IsPCSpinOff') : false;

        Boolean haveAncillaryChange = inputMap.get('haveAncillaryChange') instanceof Boolean ? (Boolean)inputMap.get('haveAncillaryChange') : false;

        if (inputMap.get('selectedProducts') instanceof List<Object>) {
            selectedProducts = (List<Object>)inputMap.get('selectedProducts');
        } 
        
        if (inputMap.get('oldProducts') instanceof List<Object>){
            oldProducts = (List<Object>)inputMap.get('oldProducts');
        }

        if (inputMap.get('userInputs') instanceof List<Object>){
            userInputs = (List<Object>)inputMap.get('userInputs');
        }

        Set<String> inactiveCensusId = new Set<String>();
        Map<String,String> inactiveToactiveCensusIdMap = new Map<String,String>();
        system.debug(isPcSpinOff);
        if(isPcSpinOff){
            for (Object user_input_object : userInputs) {
                Map<String,Object> user_input = (Map<String,Object>)user_input_object;
                String memberId = (String)user_input.get('Id');

                if(!memberId.startsWith('MEM-')){
                    inactiveCensusId.add(memberId);
                }
                system.debug('memberId '+ memberId);
            }

            for(vlocity_ins__GroupCensusMember__c gc : [SELECT Id, vlocity_ins__ContactId__r.Name, vlocity_ins__ContactId__r.ARC_CensusMember__c FROM vlocity_ins__GroupCensusMember__c WHERE Id IN :inactiveCensusId]){
                inactiveToactiveCensusIdMap.put(gc.Id, gc.vlocity_ins__ContactId__r.ARC_CensusMember__c);
            }
            system.debug('inactiveToactiveCensusIdMap ' + inactiveToactiveCensusIdMap);
        }

        Boolean FRML_DisplayChooseProductSelectionStep = (Boolean)inputMap.get('FRML_DisplayChooseProductSelectionStep');

        if (FRML_DisplayChooseProductSelectionStep == true) {
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
                    System.debug(oldProducts);
                    for (Object product_object : oldProducts) {

                        Map<String,Object> product = (Map<String,Object>)product_object;
                        System.debug(product);
                        String productType = (String)product.get('Type__c');
                        String productSubType = (String)product.get('SubType__c');

                        if (productSubType == 'SMART' && product.get('Id') != lastProductSmart_ContractLineItemId && lastProductSmart_ContractLineItemId != null) {
                            shareSMART.put('value', false);
                        } else if (productSubType == 'AIDD' && product.get('Id') != lastProductAidd_ContractLineItemId && lastProductAidd_ContractLineItemId != null) {
                            shareAIDD.put('value', false);
                        }

                        Boolean member_has_product = false;

                        for (Object census_member_object : (List<Object>)product.get('census_members')) {
                            Map<String,Object> census_member = (Map<String,Object>)census_member_object;
                            System.debug(census_member);

                            system.debug('inactiveToactiveCensusIdMap IN ' + inactiveToactiveCensusIdMap);
                            system.debug('(String)user_input.get(Id) IN ' + (String)user_input.get('Id'));
                            system.debug('getmemeberid IN ' + inactiveToactiveCensusIdMap.get((String)user_input.get('Id')));
                            system.debug('census IN ' + (String)census_member.get('Id'));


                            if(isPcSpinOff && !inactiveToactiveCensusIdMap.isEmpty() && inactiveToactiveCensusIdMap.get((String)user_input.get('Id')) == (String)census_member.get('Id')){
                                member_has_product = true;
                            } else {
                                if ((String)user_input.get('Id') == (String)census_member.get('Id')) {
                                    member_has_product = true;
                                }
                            }
                        }

                        system.debug('member_has_product ' + member_has_product);
                        
                        if (member_has_product == true) {
                            if (member_relationship == 'Primary') {
                                if (productSubType == 'SMART'){
                                    ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => true});
                                    smart_product.put('name', (String)product.get('Name'));
                                    smart_product.put('value', (String)product.get('productId'));
                                    ((Map<String,Object>)primary_information.get('smart')).put('value', product.get('Id'));
                                    ((Map<String,Object>)primary_information.get('smart')).put('productId', product.get('productId'));
                                    ((Map<String,Object>)primary_information.get('smart')).put('name', product.get('Name'));
                                } else if (productSubType == 'AIDD'){
                                    ((List<Map<String,Object>>)aidd_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => true});
                                    aidd_product.put('name', (String)product.get('Name'));
                                    aidd_product.put('value', (String)product.get('productId'));
                                    ((Map<String,Object>)primary_information.get('aidd')).put('value', product.get('Id'));
                                    ((Map<String,Object>)primary_information.get('aidd')).put('productId', product.get('productId'));
                                    ((Map<String,Object>)primary_information.get('aidd')).put('name', product.get('Name'));
                                }
                            } else if (member_relationship == 'Spouse'){
                                if (productSubType == 'SMART'){
                                    ((List<Map<String,Object>>)smart_product.get('options')).add(new Map<String,Object>{'label' => product.get('Name'), 'value' => product.get('productId'), 'selected' => true});
                                    smart_product.put('name', (String)product.get('Name'));
                                    smart_product.put('value', (String)product.get('productId'));
                                    ((Map<String,Object>)spouse_information.get('smart')).put('value', product.get('Id'));
                                    ((Map<String,Object>)spouse_information.get('smart')).put('productId', product.get('productId'));
                                    ((Map<String,Object>)spouse_information.get('smart')).put('name', product.get('Name'));
                                } else if (productSubType == 'AIDD'){
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
                    
             
                    system.debug(smart_product);
                    system.debug(aidd_product);

                    member.put('ancillaryProductsToString', String.join(ancillary_product_list, ', '));
                }

                if (selectedProducts != null && haveAncillaryChange == true) {
                    shareSMART.put('value', false);
                    shareAIDD.put('value', false);

                    if (member_relationship == 'Primary' || member_relationship == 'Spouse') {
                        System.debug(smart_product);
                        System.debug(aidd_product);

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
                        System.debug(selected_parent);
                        selected_parent.put('options', new List<Map<String,Object>>{
                            new Map<String,Object>{'value' => null, 'label' => '-', 'selected' => true},
                            new Map<String,Object>{'value' => 'None', 'label' => 'None', 'selected' => false},
                            new Map<String,Object>{'value' => primary_information.get('memberId'), 'label' => 'Primary Program', 'selected' => false}
                        });

                        if ((String)spouse_information.get('memberId') != null) {
                            ((List<Map<String,Object>>)selected_parent.get('options')).add(new Map<String,Object>{'value' => spouse_information.get('memberId'), 'label' => 'Spouse Program', 'selected' => false});
                        }
                        System.debug(selected_parent);
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
                                system.debug('selected_parent IN ' + selected_parent);
                                ((List<Map<String,Object>>)selected_parent.get('options')).add(0, new Map<String,Object>{'label' => '-', 'value' => null, 'selected' => true});
                                ((List<Map<String,Object>>)selected_parent.get('options')).add(1, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                                system.debug('selected_parent OUT' + selected_parent);
                            }
                        } else if ((Boolean)user_input.get('IsNewMember') == false) {
                            if ((String)selected_parent.get('value') == null) {
                                //if (removeParent == true) {
                                    ((List<Map<String,Object>>)selected_parent.get('options')).add(0, new Map<String,Object>{'label' => '-', 'value' => null, 'selected' => true});
                                    ((List<Map<String,Object>>)selected_parent.get('options')).add(1, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => false});
                                // } else if (removeParent == false) {
                                //     ((List<Map<String,Object>>)selected_parent.get('options')).add(0, new Map<String,Object>{'label' => 'None', 'value' => 'None', 'selected' => true});
                                //     selected_parent.put('value', 'None');
                                // }
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
            if (selectedProducts != null) {
                for (Object product_object : selectedProducts) {
                    Map<String,Object> product = (Map<String,Object>)product_object;
                    Map<String, Object> product_map = new Map<String, Object>{'selectedProduct' => new Map<String,Object>{'Id' => (String)product.get('productId')}, 'userInputs' => userInputs};
                    products_list.add(product_map);
                }
                outputMap.put('LWC_ChooseProductSelectionOutput', products_list);
            }
            else if (oldProducts != null) {
                for (Object product_object : oldProducts) {
                    Map<String,Object> product = (Map<String,Object>)product_object;
                    Map<String, Object> product_map = new Map<String, Object>{'selectedProduct' => new Map<String,Object>{'Id' => (String)product.get('productId')}, 'userInputs' => userInputs};
                    products_list.add(product_map);
                }
                
                outputMap.put('LWC_ChooseProductSelectionOutput', products_list);
            }
        }
        return outputMap;
    }

    /*******************************************************************
    * @MethodName         :   readMedicalQuestions
    * @Description        :   Method to retrieve active members medical questions and populate new member fields on medical quesitons omniscript
    ********************************************************************/
    public static Map<String,Object> readMedicalQuestions(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        Map<String, Object> selectedContractInfo = (Map<String, Object>)inputMap.get('SelectedContractInfo');
        Map<String, Object> censusComponent = (Map<String, Object>) inputMap.get('census_component');
        List<Object> censusMembers = new List<Object>(); // Initialize as empty
        Boolean isPcSpinOff = inputMap.containsKey('IsPCSpinOff') ? (Boolean)inputMap.get('IsPCSpinOff') : false;
        Map<String, Object> soChanges = (Map<String, Object>) inputMap.get('soChanges');
        Map<String, Object> reasons = (Map<String, Object>) soChanges.get('soReasons'); // Catch Program Change Reasons 
        Boolean isAddMember = (Boolean) reasons.get('addMember');
        Boolean isProgramUpgrade = (Boolean) reasons.get('programUpgrade');

        if(isPcSpinOff){
            system.debug('censusComponent.get(censusMembers) ' + censusComponent.get('censusMembers'));
            censusMembers =  (List<Object>)censusComponent.get('census_members');
        } else if (!isPcSpinOff){
            List<Object> censusDataList = (List<Object>)censusComponent.get('census_members'); // Store the value in an auxiliary variable
            censusMembers = (List<Object>) censusDataList[1];
        }

        system.debug('censusMembers 1 '+ censusMembers);

        Map<Id,Id> paToNewCensusId = new Map<Id,Id>();
        
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

                    system.debug('memberMap ' + memberMap);

                    Boolean isNewMember = memberMap.containsKey('IsNewMember') ? (Boolean) memberMap.get('IsNewMember') : false;
                    Boolean isRemoveMember = memberMap.containsKey('IsRemoveMember') ? (Boolean) memberMap.get('IsRemoveMember') : false;

                    if(!isNewMember && !isRemoveMember){
                        addMemberNameToMedicalQuestions(memberMap, questionsMap, selectCensusMemberList);
                        activeMembers.add((String) memberMap.get('PersonAccountId'));
                        if(isPcSpinOff) paToNewCensusId.put((String) memberMap.get('PersonAccountId'), (String) memberMap.get('Id'));
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
                    ARC_CensusMember__c , ARC_CensusMember__r.Name, ARC_CensusMember__r.ARC_PhysicianCity__c, ARC_CensusMember__r.ARC_PhysicianName__c, ARC_CensusMember__r.ARC_PhysicianPhone__c, ARC_PersonAccount__c
                FROM ARC_MedicalConditions__c WHERE ARC_Active__c = true AND ARC_PersonAccount__c IN :activeMembers ORDER BY CreatedDate ASC];
 
                // Query consumer drug of active members (exclude remove members and new members)
                List<vlocity_ins__ConsumerDrug__c> activemembersConsumerDrugList = [SELECT Id, Name, vlocity_ins__PrescribedBy__c, vlocity_ins__MedicationStartDate__c, vlocity_ins__MedicationEndDate__c, ARC_Reason__c, ARC_Active__c, ARC_CensusMember__c, ARC_CensusMember__r.Name, ARC_PersonAccount__c FROM vlocity_ins__ConsumerDrug__c WHERE ARC_Active__c = true AND ARC_PersonAccount__c IN :activeMembers ORDER BY CreatedDate ASC];

                Integer cancerIndex = 0; 
                Integer consumerDrugIndex = 0; 

                if (activemembersMedicalConditionsList.Size() > 0) {
                    for (ARC_MedicalConditions__c memberMc : activemembersMedicalConditionsList) {
                        if(isPcSpinOff) memberMc.ARC_CensusMember__c = paToNewCensusId.get(memberMc.ARC_PersonAccount__c);
                        

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
                        if(isPcSpinOff) memberCD.ARC_CensusMember__c = paToNewCensusId.get(memberCD.ARC_PersonAccount__c);

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
        return outputMap;
        //system.debug('Final OutputMap: ' + JSON.serializePretty(outputMap));
    }

    /*******************************************************************
    * @MethodName         :   childLoseAncillary
    * @Description        :   Method to check if a child member will lose their anncillaries on Spin Off Remove Member Contract
    ********************************************************************/
    public static Map<String, Object> childLoseAncillary(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        List<Object> oldProducts;

        if (inputMap.get('oldProducts') instanceof List<Object>){
            oldProducts = (List<Object>)inputMap.get('oldProducts');
        }

        Map<String,Object> stepAccountSelectionObj = inputMap.containsKey('STEP_AccountSelection') ? (Map<String,Object>)inputMap.get('STEP_AccountSelection') : null;
        List<Object> lwcSpinOffCensusMembersTableList = stepAccountSelectionObj != null && stepAccountSelectionObj.containsKey('LWC_SpinOffCensusMembersTable') ? (List<Object>)stepAccountSelectionObj.get('LWC_SpinOffCensusMembersTable') : null;
        Map<Integer, List<Object>> getFamiliesAndMembers =  groupMembersPerFamily(lwcSpinOffCensusMembersTableList);
        List<Object> getRemoveMemberOldMembers = getFamiliesAndMembers.get(1);
        Map<String,List<String>> productLoseChildsMap = new Map<String,List<String>>();

        for (Object product_object : oldProducts) {
            Map<String,Object> product = (Map<String,Object>)product_object;
            Id cliId = (Id)product.get('Id');
            Id productId = (Id)product.get('productId');
            String productSubType = (String)product.get('SubType__c');
            String productName = (String)product.get('Name');

            if(productSubType == 'SMART' || productSubType == 'AIDD'){
                Integer countPrimary = 0;
                Integer countSpouse = 0;
                Integer countChilds = 0;
                Boolean hasOnlyChilds = false;
                List<String> childNames = new List<String>(); 

                for (Object census_member_object : (List<Object>)product.get('census_members')) {
                    Map<String,Object> census_member = (Map<String,Object>)census_member_object;

                    for (Object oldMembers_object : getRemoveMemberOldMembers) {
                        Map<String,Object> oldmembers = (Map<String,Object>)oldMembers_object;

                        if(census_member.get('Id') == oldmembers.get('TXT_GroupCensusMemberId')){
                            String memberRelationship = (String)oldmembers.get('TXT_ContractParticipantRelationship');
                            if(memberRelationship == 'Primary') {
                                countPrimary++;
                            } else if(memberRelationship == 'Spouse'){
                                countSpouse++;
                            } else if(memberRelationship == 'Child'){
                                String childName = (String)oldmembers.get('TXT_FirstName') + ' ' + (String)oldmembers.get('TXT_LastName');
                                countChilds++;
                                childNames.add(childName);
                            }
                        }
                    }
                }

                hasOnlyChilds = (countChilds > 0 && countPrimary == 0 && countSpouse == 0);

                system.debug('productName ' + productName + ' hasOnlyChilds ' + hasOnlyChilds);

                if(hasOnlyChilds){
                    Integer countCommonProducts = 0;
                    for (Object review_oldPorducts_object : oldProducts) {
                        Map<String,Object> reviewProduct = (Map<String,Object>)review_oldPorducts_object;
  
                        if(productId == (Id)reviewProduct.get('productId')){
                            countCommonProducts++;
                        }
                    }
                    if(countCommonProducts == 1) productLoseChildsMap.put(productName, childNames);
                }
            }
        }

        List<String> summarySentences = new List<String>();
        Map<String, List<String>> memberToProductsMap = new Map<String, List<String>>();

        if (!productLoseChildsMap.isEmpty()) {
            for (String productName : productLoseChildsMap.keySet()) {
                List<String> affectedChildren = productLoseChildsMap.get(productName);
                for (String childName : affectedChildren) {
                    if (!memberToProductsMap.containsKey(childName)) {
                        memberToProductsMap.put(childName, new List<String>());
                    }
                    memberToProductsMap.get(childName).add(productName);
                }
            }

            for (String childName : memberToProductsMap.keySet()) {
                List<String> products = memberToProductsMap.get(childName);
                String productList = String.join(products, ', ');
                summarySentences.add(childName + ' will lose the ancillary ' + productList +
                    ' because they are currently a dependent on the ancillary product of a different contract.');
            }

            outputMap.put('childLoseAncillary', true);
            outputMap.put('childLoseSummary', String.join(summarySentences, '<br>'));
        } else {
            outputMap.put('childLoseAncillary', false);
        }

        return outputMap;
    }




    /////////////////////////////////////////////
    ////////Auxiliary methods/////////////////////
    /////////////////////////////////////////////

    ////Auxiliay methods for the TRANSFORM_CensusMemberToUserInputs method

    /**
     * Custom comparator class to sort by relationship
     * @param {Map<String,Object>} a - The first member map.
     * @param {Map<String,Object>} b - The second member map.
     * @returns {Integer} - The comparison result.
     */
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

    /**
     * Set the primary DOB for each member in a user input list
     * @param {List<Map<String,Object>>} userInputList - The user input list.
     * @returns {List<Map<String,Object>>} - The user input list with primary DOB set for each member.
     */
    private static List<Map<String,Object>> setPrimaryDOBForGroup(List<Map<String,Object>> userInputList, Map<String,String> memberIdToDOBMap){
        String primaryDOB = null;
        
        // Find the primary member's DOB
        for (Map<String,Object> userInput : userInputList) {
            if((String)userInput.get('RF_Census.CM_Relationship') == 'Primary') { 
                String memberId = (String)userInput.get('Id');
                primaryDOB = memberIdToDOBMap.get(memberId);
                break;
            }
        }
        
        // Set the primary DOB for all members in this group
        for (Map<String,Object> userInput : userInputList) {
            userInput.put('RF_Census.CRF_PrimaryMemberDOB', primaryDOB);
        }
        
        return userInputList;
    }

    /**
     * Get the census members from the input map
     * @param {Map<String,Object>} inputMap - The input map.
     * @returns {List<Object>} - The census members. 
     */
    private static List<Object> getCensusMembers(Map<String,Object> inputMap){
        List<Object> census_members = new List<Object>();
        try {
            // Get the census component which contains the census members
            Object censusComponentObj = inputMap.get('census_component');
            if (censusComponentObj != null) {
                Map<String,Object> censusComponent = (Map<String,Object>)censusComponentObj;
                Object membersObj = censusComponent.get('census_members');
                if (membersObj != null) {
                    // Handle nested array structure - census_members is an array of arrays
                    List<Object> censusMembersGroups = (List<Object>)membersObj;
                    for (Object group_object : censusMembersGroups) {
                        if (group_object instanceof List<Object>) {
                            List<Object> groupMembers = (List<Object>)group_object;
                            census_members.addAll(groupMembers);
                        }
                    }
                    System.debug('Found ' + census_members.size() + ' census members from ' + censusMembersGroups.size() + ' groups');
                }
                if (census_members == null) {
                    census_members = new List<Object>();
                    System.debug(LoggingLevel.WARN, 'No census members found in input map');
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing census component: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }
        return census_members;
    }

    /**
     * 
     *********************************************************************************CHECK BEFORE REMOVE THIS METHOD*********************************************************************************
     * 
     * Get the member id to relationship map from the input map
     * @param {Map<String,Object>} inputMap - The input map.
     * @returns {Map<String,String>} - The member id to relationship map.
     */
    // private static Map<String,String> getMemberIdToSpinnedOffMap(Map<String,Object> inputMap){
    //     ////Create a map of members spinned off id to relationship
    //     Map<String,String> memberIdToRelationshipMap = new Map<String,String>();
    //     try {
    //         Object stepAccountSelectionObj = inputMap.get('STEP_AccountSelection');
    //         if (stepAccountSelectionObj != null) {
    //             Map<String,Object> stepAccountSelection = (Map<String,Object>)stepAccountSelectionObj;
    //             Object lwcSpinOffCensusMembersTableObj = stepAccountSelection.get('LWC_SpinOffCensusMembersTable');
    //             if (lwcSpinOffCensusMembersTableObj != null) {
    //                 List<Object> lwcSpinOffCensusMembersTable = (List<Object>)lwcSpinOffCensusMembersTableObj;                    
    //                 for (Object memberToSpin : lwcSpinOffCensusMembersTable) {
    //                     Map<String,Object> memberToSpinMap = (Map<String,Object>)memberToSpin;
    //                     if(memberToSpinMap.get('TXT_GroupCensusMemberId') != null){
    //                         String memberId = (String)memberToSpinMap.get('TXT_GroupCensusMemberId');
    //                         Object assignToFamilyObj = memberToSpinMap.get('NUM_assignToFamily');
    //                         String spinnedOff = 'false';
    //                         if (assignToFamilyObj instanceof Integer && (Integer)assignToFamilyObj != 1) {
    //                             spinnedOff = 'true';
    //                         }
    //                         memberIdToRelationshipMap.put(memberId, spinnedOff);
    //                     }
    //                 }
    //             }
    //         }
    //     } catch (Exception e) {
    //         System.debug(LoggingLevel.ERROR, 'Error processing members to spin off: ' + e.getMessage());
    //     }
    //     return memberIdToRelationshipMap;
    // }

    /**
     * Get the member id to DOB map from the census members list
     * @param {List<Object>} census_members - The census members list.
     * @returns {Map<Id,String>} - The member id to DOB map.
     */
    private static Map<String,String> getMemberIdToDOBMap(List<Object> census_members){
        Map<String,String> memberIdToDOBMap = new Map<String,String>();
        try {
            for (Object census_member_object : census_members) {
                Map<String,Object> census_member = (Map<String,Object>)census_member_object;
                if(census_member.get('Id') != null && census_member.get('vlocity_ins__Birthdate__c') != null){
                    String memberId = (String)census_member.get('Id');
                    String birthdate = (String)census_member.get('vlocity_ins__Birthdate__c');
                    memberIdToDOBMap.put(memberId, birthdate);
                } 
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing census members for DOB mapping: ' + e.getMessage());
        }
        return memberIdToDOBMap;
    }

    /**
     * Get the census members for the user inputs
     * @param {List<Object>} census_members - The census members.
     * @returns {List<Map<String, Object>>} - The user inputs.
     */
    private static List<Map<String, Object>> getCensusMembersToUserInputs(List<Object> census_members, Date effectiveDate) {
        List<Map<String, Object>> user_input_list = new List<Map<String, Object>>();
        Boolean hasPrimary = false;
        Boolean hasSpouse = false;
        Integer dependentCount = 0;
        Integer oldestAge = 0;
        String primaryDOB = null;

        for (Object cm_object : census_members) {
            Map<String,Object> census_member = (Map<String,Object>)cm_object;
            Map<String, Object> user_input = new Map<String, Object>();

            /////FIX This yhis shoudl be primary DOB in all members
            if((String)census_member.get('ARC_Relationship__c') == 'Primary') {
                primaryDOB = (String)census_member.get('vlocity_ins__Birthdate__c');
            }
            
            if ((Boolean)census_member.get('IsRemoveMember') == false) {

                Integer age;
                
                if (effectiveDate != null){
                    age = calculateAge(Date.valueOf((String)census_member.get('vlocity_ins__Birthdate__c')), effectiveDate.addDays(daysToAdd));
                } else age = (Integer)census_member.get('ARC_Age__c');
              
                // Track oldest age
                if (age > oldestAge) {
                    oldestAge = age;
                }
                user_input.put('RF_Census.CM_Age', age);
                //user_input.put('RF_Census.CRF_PrimaryMemberDOB', primaryDOB);
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
        for (Object cm_object : census_members) {
            Map<String,Object> census_member = (Map<String,Object>)cm_object;
            Map<String, Object> user_input = new Map<String, Object>();
            user_input.put('RF_Census.CRF_PrimaryMemberDOB', primaryDOB);
        }
        try{
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
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing user input ancillaries: ' + e.getMessage());
        }
        return user_input_list;
    }

    /**
     * Set the primary DOB in all members
     * @param {List<Map<String,Object>>} user_input_list - The user input list.
     * @returns {List<Map<String,Object>>} - The user input list with the primary DOB set.
     */
    private static List<Map<String,Object>> setPrimaryDOB(List<Map<String,Object>> user_input_list){
        String primaryDOB = null;
        for (Object ui_object : user_input_list) {
            Map<String,Object> user_input = (Map<String,Object>)ui_object;
            if((String)user_input.get('RF_Census.CM_Relationship') == 'Primary') {
                primaryDOB = (String)user_input.get('RF_Census.CM_Birthdate');
            }
        }
        for (Object ui_object : user_input_list) {
            Map<String,Object> user_input = (Map<String,Object>)ui_object;
            user_input.put('RF_Census.CRF_PrimaryMemberDOB', primaryDOB);
        }
        return user_input_list;
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

    

    /**
     * Group Members into new family groups After Account Selection Step
     * @param List<Object> reorder_members.
     * @returns {Map<Integer, List<Object>>} - Map of family numbers to member lists.
     */
    private static Map<Integer, List<Map<String,Object>>> groupMembersPerFamily(List<Object> reorder_members) {
        Map<Integer, List<Map<String,Object>>> familyGroups = new Map<Integer, List<Map<String,Object>>>();

        for (Object members : reorder_members) {
            Map<String,Object> memberObj = (Map<String,Object>)members;
            Integer numFamily = (Integer)memberObj.get('NUM_assignToFamily');

            if(familyGroups.containsKey(numFamily)){
                familyGroups.get(numFamily).add(memberObj);
            } else{
                List<Map<String, Object>> newList = new List<Map<String, Object>>();
                newList.add(memberObj);
                familyGroups.put(numFamily, newList);
            }
        }

        return familyGroups;
    }

    /**
     * Cleans the census member map fields.
     * @param {Map<String,Object>} member - The member map.
     * @returns {Map<String,Object>} - The cleaned member map.  
     */
    private static Map<String,Object> cleanCensusMemberMapFields(Map<String,Object> member) {
        List<String> fieldsToClean = new List<String>{'vlocity_ins__Gender__c', 'ARC_Relationship__c', 'ARC_Smoker__c', 'ARC_Phone__c', 'vlocity_ins__Email__c', 'ARC_isPregnant__c'};
        for (String field_name : fieldsToClean) {
            if (((Boolean)((Map<String,Object>)member.get(field_name)).get('DISPLAY_FIELD')) == false) {
                ((Map<String,Object>)member.get(field_name)).put('value','');
            }
            member.put(field_name, ((Map<String,Object>)member.get(field_name)).get('value'));
        }
        return member;
    }

    /**
     * Creates a member map with default values and processed fields.
     * @param {vlocity_ins__GroupCensusMember__c} member - The member record.
     * @returns {Map<String,Object>} - A map representing the member.
     */
    private static Map<String, Object> createMemberMap (vlocity_ins__GroupCensusMember__c member, Map<Id, String> censusMemberRelationshipMap, vlocity_ins__GroupCensusMember__c primaryMember) {
        String address = String.join(new List<String>{
                member.ARC_PhysicalAddressCity__c, member.ARC_PhysicalAddressState__c, 
                member.ARC_PhysicalAddressStreet__c, member.ARC_PhysicalAddressZipCode__c
            }, ', ');
        String primaryAddress;
        if (primaryMember != null) {
            primaryAddress = String.join(new List<String>{
                    primaryMember.ARC_PhysicalAddressCity__c, primaryMember.ARC_PhysicalAddressState__c, 
                    primaryMember.ARC_PhysicalAddressStreet__c, primaryMember.ARC_PhysicalAddressZipCode__c
                }, ', ');
        }
        Map<String, Object> memberMap = new Map<String, Object>{
            'Id' => member.Id,
            'vlocity_ins__FirstName__c' => member.vlocity_ins__FirstName__c,
            'vlocity_ins__LastName__c' => member.vlocity_ins__LastName__c,
            'PersonAccountId' => member.vlocity_ins__ContactId__r.AccountId,
            'PersonContactId' => member.vlocity_ins__ContactId__c,
            'vlocity_ins__MemberIdentifier__c' => member.vlocity_ins__MemberIdentifier__c,
            'ARC_MiddleInitial__c' => member.ARC_MiddleInitial__c,
            'vlocity_ins__Birthdate__c' => member.vlocity_ins__Birthdate__c,
            'vlocity_ins__IsPrimaryMember__c' => member.vlocity_ins__IsPrimaryMember__c,
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
            'IsDependent' => member.ARC_Relationship__c != 'Primary',
            'individual_errors' => new List<String>(),
            'IsNewMember' => false,
            'IsRemoveMember' => false,
            'ShowMember' => true,
            'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
            'DISABLE_INPUT_FIELDS' => false
        };

        // Show address

        if (address == primaryAddress) {
            memberMap.put('CopyAddressFromPrimary', true);
            memberMap.put('ShowAddressForDependent', false);
        } else {
            memberMap.put('CopyAddressFromPrimary', false);
            memberMap.put('ShowAddressForDependent', true);
        }
            
        // Remove all non-digit characters
        String cleanPhoneNumber = member.ARC_Phone__c;
        if (cleanPhoneNumber != null) {
            cleanPhoneNumber = member.ARC_Phone__c.replaceAll('[^0-9]', '');
            // Remove leading '1' if it's an 11-digit number starting with '1'
            if (cleanPhoneNumber.length() == 11 && cleanPhoneNumber.startsWith('1')) {
                cleanPhoneNumber = cleanPhoneNumber.substring(1);
            }
        }

        memberMap.put('ARC_Phone__c', new Map<String, Object>{
            'value' => cleanPhoneNumber,
            'DISPLAY_FIELD' => member.ARC_Age__c >= 18 
        });

        memberMap.put('vlocity_ins__Email__c', new Map<String, Object>{
            'value' => member.vlocity_ins__Email__c,
            'DISPLAY_FIELD' => member.ARC_Age__c >= 18
        });

        memberMap.put('ARC_Smoker__c', new Map<String, Object>{
            'value' => member.ARC_Smoker__c,
            'DISPLAY_FIELD' => member.ARC_Age__c >= 18 
        });

        memberMap.put('ARC_isPregnant__c', new Map<String, Object>{
            'value' => member.ARC_isPregnant__c,
            'DISPLAY_FIELD' => member.vlocity_ins__Gender__c == 'Female' && member.ARC_Age__c >= 18
        });

        system.debug('member.ARC_Relationship__c ' + member.ARC_Relationship__c);
        // Add relationship and gender options
        String relationship = member.ARC_Relationship__c;
        if (censusMemberRelationshipMap != null && censusMemberRelationshipMap.containsKey(member.Id)) {
            relationship = censusMemberRelationshipMap.get(member.Id);
        }
        memberMap.put('ARC_Relationship__c', new Map<String, Object>{
            'value' => relationship == 'Future Primary' ? 'Primary' : relationship,
            'options' => new List<Map<String, String>>{
                new Map<String, String>{ 'label' => 'Primary', 'value' => 'Primary' },
                new Map<String, String>{ 'label' => 'Spouse', 'value' => 'Spouse' },
                new Map<String, String>{ 'label' => 'Child', 'value' => 'Child' }
            }
        });

        memberMap.put('vlocity_ins__Gender__c', new Map<String, Object>{
            'value' => member.vlocity_ins__Gender__c,
            'options' => new List<Map<String, String>>{
                new Map<String, String>{ 'label' => 'Male', 'value' => 'Male' },
                new Map<String, String>{ 'label' => 'Female', 'value' => 'Female' }
            }
        });

        return memberMap;
    }

    /**
     * Fetches the census member IDs for a given contract ID.
     * @param {Id} contractId - The ID of the contract.
     * @returns {Set<Id>} - A set of census member IDs.
     */ 
    private static Set<Id> getContractMemberIds(Id contractId) {
        Set<Id> censusMemberIds = new Set<Id>();
        for (ARC_ContractParticipant__c participant : [
            SELECT Id, ARC_PersonAccount__r.Census_Member__c 
            FROM ARC_ContractParticipant__c 
            WHERE ARC_Contract__c = :contractId
        ]) {
            if (participant.ARC_PersonAccount__r != null && participant.ARC_PersonAccount__r.Census_Member__c != null) {
                censusMemberIds.add(participant.ARC_PersonAccount__r.Census_Member__c);
            }
        }
        return censusMemberIds;
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
        //addQuestionResponse(questionsMap, 'EB_Physicians', 'TXT_CensusMemberId', memberId, memberId);

        Map<String, Object> selectMemberDetail = new Map<String, Object>();
        selectMemberDetail.put('CensusMemberName', fullName);
        selectMemberDetail.put('CensusMemberId', memberId);
        selectMemberDetail.put('Birthdate', memberBirthDate);

        selectCensusMemberList.add(selectMemberDetail);
    }


    /**
     * Get the hippa recipients to send the DocuSign
     * @param {List<Object>} census_members - The census members.
     * @returns {List<Map<String, Object>>} - The hipaa recipients.
     */
    public static void getHipaaRecipients(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        List<Object> census_members = (List<Object>)inputMap.get('census_members');
        Map<String, Object> STEP_HIPAAAuthorizationForm;
        System.debug('STEP_HIPAAAuthorizationForm: ' + inputMap.get('STEP_HIPAAAuthorizationForm'));
        if (inputMap.get('STEP_HIPAAAuthorizationForm') != null && inputMap.get('STEP_HIPAAAuthorizationForm') != '') {
            STEP_HIPAAAuthorizationForm = (Map<String, Object>)inputMap.get('STEP_HIPAAAuthorizationForm');
        }
        List<Map<String, Object>> hipaaRecipients = new List<Map<String, Object>>();

        System.debug('HIPAA STEP: ' + STEP_HIPAAAuthorizationForm);
        if (STEP_HIPAAAuthorizationForm != null) {
            // Add new internal hipaas
            Object hipaaData = STEP_HIPAAAuthorizationForm.get('EDITBLK_HIPAAAuthorizedParties');
            List<Object> internalHipaaList = new List<Object>();
            if (hipaaData instanceof List<Object>) {
                internalHipaaList = (List<Object>)hipaaData;
            } else if (hipaaData instanceof Map<String, Object>) {
                internalHipaaList.add(hipaaData);
            }
            if (internalHipaaList != null) {
                for (Object internalHipaa_object : internalHipaaList) {
                    Map<String, Object> internalHipaa = (Map<String, Object>)internalHipaa_object;
                    if ((Boolean)internalHipaa.get('CHK_Authorized') == true) {
                        Map<String, Object> recipient = new Map<String, Object>();
                        String fullname = (String)internalHipaa.get('TXT_FullName');
                        String email = (String)internalHipaa.get('TXT_EmailAddress');
                        String recipientLabel = fullname + ' - ' + email;
                        String recipientRelationship = (String)internalHipaa.get('TXT_Relationship');
                        recipient.put('label', recipientLabel);
                        recipient.put('value', email);
                        recipient.put('fullName', fullname);
                        hipaaRecipients.add(recipient);
                        // Selected by default if Primary
                        if (recipientRelationship == 'Primary' || internalHipaaList.size() == 1) {
                            Map<String,Object> recipientMap = new Map<String,Object>();
                            recipient.put('Recipient', recipientLabel);
                            recipientMap.put('Recipient-Block', recipient);
                            outputMap.put('STEP_SignTheDocument', recipientMap);
                        }
                    }
                }
            }
            // Add new external hipaas
            if ((String)STEP_HIPAAAuthorizationForm.get('RAD_AuthorizeOthers') == 'Yes') {
                Map<String, Object> externalHipaa = (Map<String, Object>)STEP_HIPAAAuthorizationForm.get('BCK_addOtherPerson');
                if (externalHipaa != null) {
                    Map<String, Object> recipient = new Map<String, Object>();
                    String fullname = (String)externalHipaa.get('TXT_NewFirstName') + ' ' + (String)externalHipaa.get('TXT_NewLastName');
                    String email = (String)externalHipaa.get('TXT_NewEmail');
                    String recipientLabel = fullname + ' - ' + email;
                    recipient.put('label', recipientLabel);
                    recipient.put('value', email);
                    recipient.put('TXT_FullName', fullname);
                    
                    hipaaRecipients.add(recipient);
                }
            }
        }
        outputMap.put('FinalHipaaRecipients', hipaaRecipients);
    }

    /**
     * Get the DocuSign related data 
     * @param {List<Object>} census_members - The census members.
     * @returns {Map<String, Object>} - DocuSign data.
     */
    public static void getDocuSignData(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        List<Object> census_members = (List<Object>)inputMap.get('census_members');
        System.debug('census_members: ' + census_members);
        // Number of dependents
        Integer numberDependents = 0;
        for (Object census_member : census_members) {
            Map<String, Object> member = (Map<String, Object>)census_member;
            if ((Boolean)member.get('IsRemoveMember') == false && (String)member.get('ARC_Relationship__c') == 'Child') {
                numberDependents++;
            }
        }
        System.debug('numberDependents: ' + numberDependents);
        String signerEmail = (String)inputMap.get('signerEmail');
        System.debug('signerEmail: ' + signerEmail);
        String primaryState = (String)inputMap.get('primaryState');
        System.debug('primaryState: ' + primaryState);

        // Is Legacy
        Boolean isLegacy = false;
        Object selectedProducts_obj = inputMap.get('selectedProducts');
        if (selectedProducts_obj != null && selectedProducts_obj != '') {
            List<Object> selectedProducts = (List<Object>)selectedProducts_obj;
            for (Object selectedProduct_obj : selectedProducts) {
                Map<String, Object> selectedProduct = (Map<String, Object>)selectedProduct_obj;
                if ((String)selectedProduct.get('Type__c') == 'Medical' && (String)selectedProduct.get('Name') == 'WeShare Legacy') {
                    isLegacy = true;
                    break;
                }
            }
        }
        // Query template
        String templateNameStr = '';
        if (isLegacy) {
            if (primaryState == 'CA') {
                templateNameStr = 'WeShare Legacy Membership Application CA';
            }
            else {
                templateNameStr = 'WeShare Legacy Membership Application';
            }
        } else {
            String queryStr = 'SELECT ARC_Template_Name__c, ARC_DRTransform__c ';
            queryStr += 'FROM ARC_DocuSignTemplates__c';
            queryStr += ' WHERE ARC_Contract_Reasons__c LIKE \'%Spin Off%\'';
            queryStr += ' AND ARC_Min_Dependents__c <= ' + numberDependents;
            queryStr += ' AND ARC_Max_Dependents__c >= ' + numberDependents;
            if (primaryState == 'CA') {
                queryStr += ' AND ARC_State__c =  \'CA\'';
            }
            queryStr += ' ORDER BY ARC_Template_Name__c ASC LIMIT 1';
            ARC_DocuSignTemplates__c templateSettings = Database.query(queryStr);
            templateNameStr = templateSettings.ARC_Template_Name__c;
        }
        System.debug('templateNameStr: ' + templateNameStr);
        vlocity_ins__VlocityDocuSignTemplate__c template = [
            SELECT Id, Name, vlocity_ins__templateidentifier__c
            FROM vlocity_ins__VlocityDocuSignTemplate__c
            WHERE name = :templateNameStr
            ORDER BY LastModifiedDate DESC LIMIT 1
        ];
        System.debug('template: ' + template);
        Map<String, Object> DocuSignTemplateId = new Map<String, Object>();
        DocuSignTemplateId.put('Id', template.Id);
        DocuSignTemplateId.put('Name', template.Name);
        DocuSignTemplateId.put('TemplateId', template.vlocity_ins__templateidentifier__c);
        outputMap.put('DocuSignTemplateId', DocuSignTemplateId);
        // Signers....
        List<Object> recipients = new List<Object>();
        Integer dependentCount = 1;
        for (Object census_member_obj : census_members) {
            Map<String, Object> census_member = (Map<String, Object>)census_member_obj;
            String name = (String)census_member.get('vlocity_ins__FirstName__c') + ' ' + (String)census_member.get('vlocity_ins__LastName__c');
            String relationship = (String)census_member.get('ARC_Relationship__c');
            if ((Integer)census_member.get('ARC_Age__c') < 18 || (relationship != 'Primary' && !(Boolean)census_member.get('IsNewMember'))) continue;
            String templateRole;
            if (relationship == 'Primary' || relationship == 'Spouse') {
                templateRole = relationship == 'Primary' ? 'Primary' : 'Spouse';
            } else if (relationship == 'Child') {
                templateRole = 'Dependent' + dependentCount;
                dependentCount++;
            }
            Map<String, Object> recipient = new Map<String, Object>();
            recipient.put('templateRole', templateRole);
            recipient.put('signerEmail', signerEmail);
            recipient.put('signerName', name);
            recipients.add(recipient);
        }
        if (recipients.size() == 0) {
            String templateRole = 'Primary';
            Map<String, Object> guardianStep = (Map<String, Object>)inputMap.get('STEP_GuardiansInformation');
            String guardianName = (String)guardianStep.get('TXT_GuardianFirstName') + ' ' + (String)guardianStep.get('TXT_GuardianLastName');
            Map<String, Object> recipient = new Map<String, Object>();
            recipient.put('templateRole', templateRole);
            recipient.put('signerEmail', signerEmail);
            recipient.put('signerName', guardianName);
            recipients.add(recipient);
        }
        System.debug('SignerList: ' + recipients);
        outputMap.put('SignerList', recipients);
        // Info....
        // Transform DATA
        // GET Input DATA
        Map<String,Object> inputMapDSTrans = new Map<String,Object>();

        Map<String, Object> MembersInfo = new Map<String, Object>();
        List<Object> dependentMembers = new List<Object>();
        for (Object census_member_obj : census_members) {
            Map<String, Object> census_member = (Map<String, Object>)census_member_obj;
            String relationship = (String)census_member.get('ARC_Relationship__c');
            System.debug('Relationship: ' + relationship);

            if((Boolean)census_member.get('IsRemoveMember') == true) continue;

            if (relationship == 'Primary') {
                Map<String, Object> primaryMember = new Map<String, Object>();
                Object isPregnant_obj = census_member.get('ARC_isPregnant__c');
                primaryMember.put('Pregnant',isPregnant_obj != null && isPregnant_obj != '' ? (Boolean)isPregnant_obj : false);
                Object Smoker_obj = census_member.get('ARC_Smoker__c');
                primaryMember.put('Smoker', Smoker_obj != null && Smoker_obj != '' ? (Boolean)Smoker_obj : false);
                primaryMember.put('MI', (String)census_member.get('ARC_MiddleInitial__c'));
                primaryMember.put('Phone', (String)census_member.get('ARC_Phone__c'));
                primaryMember.put('City', (String)census_member.get('ARC_PhysicalAddressCity__c'));
                primaryMember.put('State', (String)census_member.get('ARC_PhysicalAddressState__c'));
                primaryMember.put('Address', (String)census_member.get('ARC_PhysicalAddressStreet__c'));
                primaryMember.put('ZipCode', (String)census_member.get('ARC_PhysicalAddressZipCode__c'));
                primaryMember.put('Weight', (String)census_member.get('ARC_Weight__c'));
                primaryMember.put('DayOfBirth', (Date.valueOf((String)census_member.get('vlocity_ins__Birthdate__c'))).day());
                primaryMember.put('Height', (String)census_member.get('ARC_HeightFeet__c') + '\'' + (String)census_member.get('ARC_HeightInches__c'));
                primaryMember.put('Id', (String)census_member.get('Id'));
                //primaryMember.put('IsInactiveMember', (Boolean)census_member.get('IsInactiveMember'));
                primaryMember.put('IsNewMember', (Boolean)census_member.get('IsNewMember'));
                primaryMember.put('IsRemoveMember', (Boolean)census_member.get('IsRemoveMember'));
                primaryMember.put('MonthOfBirth', (Date.valueOf((String)census_member.get('vlocity_ins__Birthdate__c'))).month());
                primaryMember.put('YearOfBirth', (Date.valueOf((String)census_member.get('vlocity_ins__Birthdate__c'))).year());
                primaryMember.put('DOB', (String)census_member.get('vlocity_ins__Birthdate__c'));
                primaryMember.put('Email', (String)census_member.get('vlocity_ins__Email__c'));
                primaryMember.put('FirstName', (String)census_member.get('vlocity_ins__FirstName__c'));
                primaryMember.put('LastName', (String)census_member.get('vlocity_ins__LastName__c'));
                primaryMember.put('Gender', (String)census_member.get('vlocity_ins__Gender__c'));
                primaryMember.put('SocialSecurity', (String)census_member.get('vlocity_ins__SocialSecurityNumber__c'));
                MembersInfo.put('primaryMember', primaryMember);
            } else if (relationship == 'Spouse') {
                Map<String, Object> spouseMember = new Map<String, Object>();
                Object isPregnant_obj = census_member.get('ARC_isPregnant__c');
                spouseMember.put('Pregnant', isPregnant_obj != null && isPregnant_obj != '' ? (Boolean)isPregnant_obj : false);
                Object Smoker_obj = census_member.get('ARC_Smoker__c');
                spouseMember.put('Smoker', Smoker_obj != null && Smoker_obj != '' ? (Boolean)Smoker_obj : false);
                spouseMember.put('MI', (String)census_member.get('ARC_MiddleInitial__c'));
                spouseMember.put('Weight', (String)census_member.get('ARC_Weight__c'));
                spouseMember.put('Height', (String)census_member.get('ARC_HeightFeet__c') + '\'' + (String)census_member.get('ARC_HeightInches__c'));
                spouseMember.put('Id', (String)census_member.get('Id'));
                //spouseMember.put('IsInactiveMember', (Boolean)census_member.get('IsInactiveMember'));
                spouseMember.put('IsNewMember', (Boolean)census_member.get('IsNewMember'));
                spouseMember.put('IsRemoveMember', (Boolean)census_member.get('IsRemoveMember'));
                spouseMember.put('DOB', (String)census_member.get('vlocity_ins__Birthdate__c'));
                spouseMember.put('Email', (String)census_member.get('vlocity_ins__Email__c'));
                spouseMember.put('FirstName', (String)census_member.get('vlocity_ins__FirstName__c'));
                spouseMember.put('LastName', (String)census_member.get('vlocity_ins__LastName__c'));
                spouseMember.put('Gender', (String)census_member.get('vlocity_ins__Gender__c'));
                spouseMember.put('SocialSecurity', (String)census_member.get('vlocity_ins__SocialSecurityNumber__c'));
                MembersInfo.put('spouseMember', spouseMember);
            } else if (relationship == 'Child') {
                Map<String, Object> dependentMember = new Map<String, Object>();
                Object isPregnant_obj = census_member.get('ARC_isPregnant__c');
                dependentMember.put('Pregnant', isPregnant_obj != null && isPregnant_obj != '' ? (Boolean)isPregnant_obj : false);
                Object Smoker_obj = census_member.get('ARC_Smoker__c');
                dependentMember.put('Smoker', Smoker_obj != null && Smoker_obj != '' ? (Boolean)Smoker_obj : false);
                dependentMember.put('MI', (String)census_member.get('ARC_MiddleInitial__c'));
                dependentMember.put('Weight', (String)census_member.get('ARC_Weight__c'));
                dependentMember.put('Height', (String)census_member.get('ARC_HeightFeet__c') + '\'' + (String)census_member.get('ARC_HeightInches__c'));
                dependentMember.put('Id', (String)census_member.get('Id'));
                //dependentMember.put('IsInactiveMember', (Boolean)census_member.get('IsInactiveMember'));
                dependentMember.put('IsNewMember', (Boolean)census_member.get('IsNewMember'));
                dependentMember.put('IsRemoveMember', (Boolean)census_member.get('IsRemoveMember'));
                dependentMember.put('DOB', (String)census_member.get('vlocity_ins__Birthdate__c'));
                dependentMember.put('Email', (String)census_member.get('vlocity_ins__Email__c'));
                dependentMember.put('FirstName', (String)census_member.get('vlocity_ins__FirstName__c'));
                dependentMember.put('LastName', (String)census_member.get('vlocity_ins__LastName__c'));
                dependentMember.put('Gender', (String)census_member.get('vlocity_ins__Gender__c'));
                dependentMember.put('SocialSecurity', (String)census_member.get('vlocity_ins__SocialSecurityNumber__c'));
                dependentMembers.add(dependentMember);
            }
        }
        if (!dependentMembers.isEmpty()) {
            MembersInfo.put('dependentMembers', dependentMembers);
        }
        System.debug('MembersInfo: ' + MembersInfo);

        // Adapt Payment Step in DocuSign Map to PC DocuSign class so information is correctly populated in DS
        Map<String, Object> DocuSignMap = (Map<String, Object>)inputMap.get('DocuSign');
        Map<String,Object> pcChangesMap = (Map<String, Object>)DocuSignMap.get('pcChanges');

        ((Map<String, Object>)((Map<String, Object>)DocuSignMap.get('Step_PaymentChangeFee')).get('BLK_ChargeFee')).put('RAD_KeepRecurringMethodOfPayment', 'No');
        (((Map<String, Object>)DocuSignMap.get('Step_PaymentChangeFee'))).put('RAD_ChargeAppFeeDefTrue', 'Yes');
        pcChangesMap.put('feeApplicable', true);

        System.debug('Updated DocuSign Map: ' + DocuSignMap);
        System.debug('pc changes map : ' + pcChangesMap);


        inputMapDSTrans.put('MembersInfo', MembersInfo);
        inputMapDSTrans.put('DocuSign', DocuSignMap);
        inputMapDSTrans.put('EffectiveDate', (String)inputMap.get('effectiveDate'));
        inputMapDSTrans.put('pcChanges', pcChangesMap);
        inputMapDSTrans.put('allMembersInfo', census_members);
        inputMapDSTrans.put('primaryState', primaryState);
        Map<String, Object> newMedicalProduct = new Map<String, Object>();
        List<Object> productList = (List<Object>)DocuSignMap.get('NewProductList');
        for (Object product_obj : productList) {
            Map<String, Object> product = (Map<String, Object>)product_obj;
            Map<String, Object> selectedProduct = (Map<String, Object>)product.get('selectedProduct');
            if (selectedProduct.get('Type__c') == 'Medical') {
                newMedicalProduct.put('selectedProduct', selectedProduct);
                break;
            }
        }
        if (newMedicalProduct.containsKey('selectedProduct')) {
            inputMapDSTrans.put('newMedicalProduct', newMedicalProduct);
        }
        inputMapDSTrans.put('UpdateType', 'Change to Programs');
        Map<String,Object> outputMapDSTrans = new Map<String,Object>();

        ARC_ProgramChange_DocuSign.DocuSignDataTransform(inputMapDSTrans, outputMapDSTrans, new Map<String,Object>());
        outputMap.put('RAresponse', outputMapDSTrans);
    }


}