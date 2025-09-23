public with sharing class ARC_ProgramChangeHandler {
    private Map<String, Object> pcReasons;
    private Map<String,Object> inputMap;
    private List<String> ActionsSelected = new List<String>();
    private List<vlocity_ins__GroupCensusMember__c> censusMembersToInsert = new List<vlocity_ins__GroupCensusMember__c>();
    private List<vlocity_ins__GroupCensusMember__c> censusMembersToUpdate = new List<vlocity_ins__GroupCensusMember__c>();        
    private List<vlocity_ins__GroupCensus__c> groupCensusToInsert = new List<vlocity_ins__GroupCensus__c>();
    private List<Account> accountsToInsert = new List<Account>();
    private List<Contact> contactsToInsert = new List<Contact>();
    private List<Contract> contractsToInsert = new List<Contract>();
    private List<vlocity_ins__ContractLineItem__c> contractLineItemsToInsert = new List<vlocity_ins__ContractLineItem__c>();    
    private List<vlocity_ins__GroupCensusMemberPlan__c> groupCensusMemberPlansToInsert = new List<vlocity_ins__GroupCensusMemberPlan__c>();
    private List<ARC_ContractParticipant__c> contractParticipantsToInsert = new List<ARC_ContractParticipant__c>();
    private List<ChargentOrders__ChargentOrder__c> chargentOrdersToInsert = new List<ChargentOrders__ChargentOrder__c>();
    private List<Case> casesUWToInsert = new List<Case>();
    private List<ARC_HipaaAuthorization__c> hipaaAuthorizationsToInsert = new List<ARC_HipaaAuthorization__c>();
    private List<ARC_MedicalConditions__c> medicalConditionsToInsert = new List<ARC_MedicalConditions__c>();
    private List<vlocity_ins__ConsumerDrug__c> consumerDrugsToInsert = new List<vlocity_ins__ConsumerDrug__c>();
    private List<Case> casesPCToInsert = new List<Case>();
    private Map<Id, Account> censusMemberToAccount = new Map<Id, Account>();
    private Map<Id,Id> accountIdToMemberId = new Map<Id,Id>();

    

    // Map to store all inserted records by their type
    private Map<String, Map<Id, SObject>> allInsertedRecords = new Map<String, Map<Id, SObject>>();

    public ARC_ProgramChangeHandler(Map<String, Object> pcReasons,Map<String,Object> inputMap) {
        this.pcReasons = pcReasons;
        this.inputMap = inputMap;
    }

    public void executeChanges() {
        System.debug('executeChanges: ' + this.inputMap);
        // Create a map to hold actions with their respective priorities
        Map<Integer, List<String>> priorityActions = new Map<Integer, List<String>>();

        // Collect actions with their corresponding priorities based on input
        if (pcReasons.containsKey('primaryChange') && (Boolean) pcReasons.get('primaryChange')) {
            addActionToPriorityMap(priorityActions, 'primaryChange', 1);  // High priority
            ActionsSelected.add('primaryChange');
        }
        if (pcReasons.containsKey('addressStateChange') && (Boolean) pcReasons.get('addressStateChange')) {
            addActionToPriorityMap(priorityActions, 'addressStateChange', 2);
            ActionsSelected.add('addressStateChange');
        }
        if (pcReasons.containsKey('relationshipToPrimaryChange') && (Boolean) pcReasons.get('relationshipToPrimaryChange')) {
            addActionToPriorityMap(priorityActions, 'relationshipToPrimaryChange', 3);
            ActionsSelected.add('relationshipToPrimaryChange');
        }
        if (pcReasons.containsKey('dateOfBirthChange') && (Boolean) pcReasons.get('dateOfBirthChange')) {
            addActionToPriorityMap(priorityActions, 'dateOfBirthChange', 4);
            ActionsSelected.add('dateOfBirthChange');
        }
        // Program and Effective Date Changes
        if (pcReasons.containsKey('programUpgrade') && (Boolean) pcReasons.get('programUpgrade')) {
            addActionToPriorityMap(priorityActions, 'programUpgrade', 5); // Lower priority
            ActionsSelected.add('programUpgrade');
        }
        if (pcReasons.containsKey('programDowngrade') && (Boolean) pcReasons.get('programDowngrade')) {
            addActionToPriorityMap(priorityActions, 'programDowngrade', 6);
            ActionsSelected.add('programDowngrade');
        }
        if (pcReasons.containsKey('ancillaryChange') && (Boolean) pcReasons.get('ancillaryChange')) {
            addActionToPriorityMap(priorityActions, 'ancillaryChange', 7);
            ActionsSelected.add('ancillaryChange');
        }
        if (pcReasons.containsKey('removeAllAncillary') && (Boolean) pcReasons.get('removeAllAncillary')) {
            addActionToPriorityMap(priorityActions, 'removeAllAncillary', 8);
            ActionsSelected.add('removeAllAncillary');
        }
        if (pcReasons.containsKey('effectiveDateChange') && (Boolean) pcReasons.get('effectiveDateChange')) {
            addActionToPriorityMap(priorityActions, 'effectiveDateChange', 9);
            ActionsSelected.add('effectiveDateChange');
        }
        // Add/Remove Member Changes
        if (pcReasons.containsKey('addMember') && (Boolean) pcReasons.get('addMember')) {
            addActionToPriorityMap(priorityActions, 'addMember', 10);
            ActionsSelected.add('addMember');
        }
        if (pcReasons.containsKey('removeMember') && (Boolean) pcReasons.get('removeMember')) {
            addActionToPriorityMap(priorityActions, 'removeMember', 11);
            ActionsSelected.add('removeMember');
        }
        if (pcReasons.containsKey('addExistingMember') && (Boolean) pcReasons.get('addExistingMember')) {
            addActionToPriorityMap(priorityActions, 'addExistingMember', 12);
            ActionsSelected.add('addExistingMember');
        }
        // Process actions based on their priority
        processActionsByPriority(priorityActions);
        // DML operations after all actions are executed
        manageDML();
    }

    // Helper method to add actions to the priority map
    private void addActionToPriorityMap(Map<Integer, List<String>> priorityActions, String action, Integer priority) {
        System.debug('addActionToPriorityMap: ' + this.inputMap);
        if (!priorityActions.containsKey(priority)) {
            priorityActions.put(priority, new List<String>());
        }
        priorityActions.get(priority).add(action);
    }

    // Method to process actions in priority order
    private void processActionsByPriority(Map<Integer, List<String>> priorityActions) {
        System.debug('processActionsByPriority: ' + priorityActions);
        // Sort priorities in ascending order (lower priority = earlier execution)
        List<Integer> sortedPriorities = new List<Integer>(priorityActions.keySet());
        sortedPriorities.sort();
        System.debug('processActionsByPrioritySorted: ' + sortedPriorities);
        System.debug('priorityActions ' + priorityActions);
        // Execute actions in the order of their priorities
        for (Integer priority : sortedPriorities) {
            List<String> actions = priorityActions.get(priority);
            for (String action : actions) {
                executeAction(action);
            }
        }
    }

    // Method to execute an individual action
    private void executeAction(String action) {
        System.debug('executeAction: ' + action);
        switch on action {
            when 'primaryChange' {
                handlePrimaryChange();                
            }
            when 'addressStateChange' {
                handleAddressStateChange();
            }
            when 'relationshipToPrimaryChange' {
                handleRelationshipToPrimaryChange();
            }
            when 'dateOfBirthChange' {
                handleDateOfBirthChange();
            }
            when 'programUpgrade' {
                handleProgramUpgrade();
            }
            when 'programDowngrade' {
                handleProgramDowngrade();
            }
            when 'ancillaryChange' {
                handleAncillaryChange();
            }
            when 'removeAllAncillary' {
                handleRemoveAllAncillary();
            }
            when 'effectiveDateChange' {
                handleEffectiveDateChange();
            }
            when 'addMember' {
                //handleAddMember();
                updateGCM('addMember');
            }
            when 'removeMember' {
                handleRemoveMember();
            } 
            when 'addExistingMember' {
                updateGCM('addExistingMember');
            }
        }
    }

   
   /*******************************************************************
    * @MethodName         :   handlePrimaryChange
    * @Description        :   Method to handle primary change
    ********************************************************************

    Census Member  ---- Update
    Census  ---- No changes
    Account  ---- Update
    Contract  ---- Insert
    Contract Line Item  ---- Insert
    Group Census Member Plan  ---- Insert    
    Contract Participant  ---- Insert
    Chargent Order  ---- Insert
    Case  ---- Insert
    UW Case Members?
    PC Case  ---- Insert/Update 
    Hipaa Authorization  ---- ?
    Medical Conditions  ---- ?   
    Consumer Drug  ---- ?
    Policy? ----Insert
    Contact  ---- No changes    
    *******************************************************************/

    private void handlePrimaryChange() { 
          /* Your logic */ 
    } /* TODO: Implement: */
 


    /*******************************************************************
    * @MethodName         :   handleAddressStateChange  
    * @Description        :   Method to handle address state change
    ********************************************************************

    Census Member  ---- Update
    Census  ---- No changes
    Account  ---- Update
    Contract  ---- Insert
    Contract Line Item  ---- Insert
    Group Census Member Plan  ---- Insert    
    Contract Participant  ---- Insert
    Chargent Order  ---- Insert
    Case  ---- Insert
    UW Case Members?
    PC Case  ---- Insert/Update 
    Hipaa Authorization  ---- ?
    Medical Conditions  ---- ?   
    Consumer Drug  ---- ?
    Policy? ----Insert
    Contact  ---- No changes    
    *******************************************************************/
    private void handleAddressStateChange() { /* Your logic */ } /* TODO: Implement */



    /*******************************************************************
    * @MethodName         :   handleRelationshipToPrimaryChange  
    * @Description        :   Method to handle relationship to primary change
    ********************************************************************

    Census Member  ---- Update
    Census  ---- No changes
    Account  ---- Update
    Contract  ---- Insert
    Contract Line Item  ---- Insert
    Group Census Member Plan  ---- Insert    
    Contract Participant  ---- Insert
    Chargent Order  ---- Insert
    Case  ---- Insert
    UW Case Members?
    PC Case  ---- Insert/Update 
    Hipaa Authorization  ---- ?
    Medical Conditions  ---- ?   
    Consumer Drug  ---- ?
    Policy? ----Insert
    Contact  ---- No changes    
    *******************************************************************/
    private void handleRelationshipToPrimaryChange() { /* Your logic */ } /* TODO: Implement */
    private void handleDateOfBirthChange() { /* Your logic */ } /* TODO: Implement */
    private void handleProgramUpgrade() { /* Your logic */ } /* TODO: Implement */
    private void handleProgramDowngrade() { /* Your logic */ } /* TODO: Implement */
    private void handleAncillaryChange() { /* Your logic */ } /* TODO: Implement */
    private void handleRemoveAllAncillary() { /* Your logic */ } /* TODO: Implement */
    private void handleEffectiveDateChange() { /* Your logic */ } /* TODO: Implement */




    /*******************************************************************
    * @MethodName         :   handleAddMember  
    * @Description        :   Method to handle add member
    ********************************************************************

    Census Member  ---- Insert
    Census  ---- No changes
    Account  ---- Insert
    Contract  ---- Insert
    Contract Line Item  ---- Insert
    Group Census Member Plan  ---- Insert    
    Contract Participant  ---- Insert
    Chargent Order  ---- Insert
    Case  ---- Insert
    UW Case Members?
    PC Case  ---- Insert/Update 
    Hipaa Authorization  ---- Insert?
    Medical Conditions  ---- ?   
    Consumer Drug  ---- Insert?
    Policy ----Insert
    Contact  ---- No changes    
    *******************************************************************/
    private void handleAddMember() {
        
        List<Map<String,Object>> censusMembers = getCensusMembers();
        /*
        List<SObject> rawMapped = ARC_SObjectMapper.mapListToSObjects(
            censusMembers,
            vlocity_ins__GroupCensusMember__c.SObjectType,
            ARC_SObjectMapper.getGroupCensusMemberMapping()
        );

        List<vlocity_ins__GroupCensusMember__c> finalMapped = (List<vlocity_ins__GroupCensusMember__c>) rawMapped;

        System.debug('finalMapped ' + finalMapped );
        */

        for (Map<String,Object> member : censusMembers) {      
            //CM Mapping
            if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == true) {
                vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();

                /////////MISSING MAPPINGS
                /////////
                /////////

                // Need to confirm what to do Here:censusMember.vlocity_ins__MemberIdentifier__c = member.containsKey('vlocity_ins__MemberIdentifier__c') ? (String)member.get('vlocity_ins__MemberIdentifier__c') : null;
                // Need to confirm what to do Here: censusMember.vlocity_ins__PrimaryMemberIdentifier__c = member.containsKey('vlocity_ins__PrimaryMemberIdentifier__c') ? (String)member.get('vlocity_ins__PrimaryMemberIdentifier__c') : null;
                // Need to confirm what to do Here: censusMember.vlocity_ins__RelatedCensusMemberId__c = member.containsKey('vlocity_ins__RelatedCensusMemberId__c') ? (Id)member.get('vlocity_ins__RelatedCensusMemberId__c') : null;
                // Not yet in JSON: censusMember.vlocity_ins__HasSpouse__c = member.containsKey('vlocity_ins__HasSpouse__c') ? (Boolean)member.get('vlocity_ins__HasSpouse__c') : null;
                // Need PA Inseerted censusMember.vlocity_ins__ContactId__c = null;             
                 
                if(member.containsKey('IsNewMember') && !(Boolean)member.get('IsNewMember')){
                    censusMember.Id =(Id)(member.containsKey('Id') ? member.get('Id') : 'null');
                }
                if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Primary'){
                    censusMember.ARC_DependentRelationship__c = '';
                    censusMember.vlocity_ins__IsPrimaryMember__c = true;
                }                
                else if(member.containsKey('ARC_Relationship__c')){
                    censusMember.ARC_DependentRelationship__c = (String)member.get('ARC_Relationship__c');   
                    censusMember.vlocity_ins__IsPrimaryMember__c = false;
                }
                if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Spouse'){
                    censusMember.vlocity_ins__IsSpouse__c = true;
                }
                censusMember.ARC_ActiveMember__c = false;                
                
                censusMember.ARC_HeightFeet__c = member.containsKey('ARC_HeightFeet__c') ? String.valueOf(member.get('ARC_HeightFeet__c')) : null;
                censusMember.ARC_HeightInches__c = member.containsKey('ARC_HeightInches__c') ? String.valueOf(member.get('ARC_HeightInches__c')) : null;
                censusMember.ARC_PhysicalAddressCity__c = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                censusMember.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? (String)member.get('ARC_PhysicalAddressState__c') : null;
                censusMember.ARC_PhysicalAddressStreet__c = member.containsKey('ARC_PhysicalAddressStreet__c') ? (String)member.get('ARC_PhysicalAddressStreet__c') : null;
                censusMember.ARC_PhysicalAddressZipCode__c = member.containsKey('ARC_PhysicalAddressZipCode__c') ? (String)member.get('ARC_PhysicalAddressZipCode__c') : null;
                censusMember.ARC_Smoker__c = member.containsKey('ARC_Smoker__c') ? (Boolean)member.get('ARC_Smoker__c') : null;
                censusMember.ARC_UseParentAddress__c = member.containsKey('CopyAddressFromPrimary') ? (Boolean)member.get('CopyAddressFromPrimary') : null;
                censusMember.ARC_Weight__c = member.containsKey('ARC_Weight__c') ? String.valueOf(member.get('ARC_Weight__c')) : null;
                censusMember.vlocity_ins__Birthdate__c = (member.containsKey('vlocity_ins__Birthdate__c') && member.get('vlocity_ins__Birthdate__c') != null)? Date.valueOf((String)member.get('vlocity_ins__Birthdate__c')) : null;
                censusMember.vlocity_ins__CensusId__c = this.inputMap.containsKey('CensusId') ? (Id)this.inputMap.get('CensusId') : null;
                censusMember.vlocity_ins__Email__c = member.containsKey('vlocity_ins__Email__c') ? (String)member.get('vlocity_ins__Email__c') : null;
                censusMember.vlocity_ins__LastName__c = member.containsKey('vlocity_ins__LastName__c') ? (String)member.get('vlocity_ins__LastName__c') : null;
                censusMember.vlocity_ins__FirstName__c = member.containsKey('vlocity_ins__FirstName__c') ? (String)member.get('vlocity_ins__FirstName__c') : null;
                censusMember.vlocity_ins__Gender__c = member.containsKey('vlocity_ins__Gender__c') ? (String)member.get('vlocity_ins__Gender__c') : null;
                censusMember.vlocity_ins__IsPrimaryMember__c = member.containsKey('vlocity_ins__IsPrimaryMember__c') ? (Boolean)member.get('vlocity_ins__IsPrimaryMember__c') : null;
                censusMember.vlocity_ins__SocialSecurityNumber__c = member.containsKey('vlocity_ins__SocialSecurityNumber__c') ? (String)member.get('vlocity_ins__SocialSecurityNumber__c') : null;
                System.debug('censusMember.vlocity_ins__SocialSecurityNumber__c ' + censusMember.vlocity_ins__SocialSecurityNumber__c);
                //Add to global list
                this.censusMembersToInsert.add(censusMember);                                  
            }                      
        }        
    }

        /*******************************************************************
    * @MethodName         :   handleAddExistingMember  
    * @Description        :   Method to handle add existing member
    ********************************************************************

    Census Member  ---- Update
    Census  ---- No changes
    Account  ---- Update
    Contract  ---- Insert
    Contract Line Item  ---- Insert
    Group Census Member Plan  ---- Insert    
    Contract Participant  ---- Insert
    Chargent Order  ---- Insert
    Case  ---- Insert
    UW Case Members?
    PC Case  ---- Insert/Update 
    Hipaa Authorization  ---- Insert?
    Medical Conditions  ---- ?   
    Consumer Drug  ---- Insert?
    Policy ----Insert
    Contact  ---- No changes    
    *******************************************************************/
    private void updateGCM(String action) { 
        List<Map<String,Object>> censusMembers = getCensusMembers();
        if(action == 'addExistingMember'){
            for (Map<String,Object> member : censusMembers) {
                if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == true && member.containsKey('IsInactiveMember') && (Boolean)member.get('IsInactiveMember') == true){                
                    vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();
                    /////////MISSING MAPPINGS
                    /////////
                    /////////

                    // Need to confirm what to do Here:censusMember.vlocity_ins__MemberIdentifier__c = member.containsKey('vlocity_ins__MemberIdentifier__c') ? (String)member.get('vlocity_ins__MemberIdentifier__c') : null;
                    // Need to confirm what to do Here: censusMember.vlocity_ins__PrimaryMemberIdentifier__c = member.containsKey('vlocity_ins__PrimaryMemberIdentifier__c') ? (String)member.get('vlocity_ins__PrimaryMemberIdentifier__c') : null;
                    // Need to confirm what to do Here: censusMember.vlocity_ins__RelatedCensusMemberId__c = member.containsKey('vlocity_ins__RelatedCensusMemberId__c') ? (Id)member.get('vlocity_ins__RelatedCensusMemberId__c') : null;
                    // Not yet in JSON: censusMember.vlocity_ins__HasSpouse__c = member.containsKey('vlocity_ins__HasSpouse__c') ? (Boolean)member.get('vlocity_ins__HasSpouse__c') : null;
                                    
                    if(member.containsKey('IsNewMember') && !(Boolean)member.get('IsNewMember')){
                        censusMember.Id =(Id)(member.containsKey('Id') ? member.get('Id') : 'null');
                    }
                    if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Primary'){
                        censusMember.ARC_DependentRelationship__c = '';
                        censusMember.vlocity_ins__IsPrimaryMember__c = true;
                    }                
                    else if(member.containsKey('ARC_Relationship__c')){
                        censusMember.ARC_DependentRelationship__c = (String)member.get('ARC_Relationship__c');   
                        censusMember.vlocity_ins__IsPrimaryMember__c = false;
                    }                               
                    censusMember.ARC_HeightFeet__c = member.containsKey('ARC_HeightFeet__c') ? String.valueOf(member.get('ARC_HeightFeet__c')) : null;
                    censusMember.ARC_HeightInches__c = member.containsKey('ARC_HeightInches__c') ? String.valueOf(member.get('ARC_HeightInches__c')) : null;
                    censusMember.ARC_PhysicalAddressCity__c = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                    censusMember.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? (String)member.get('ARC_PhysicalAddressState__c') : null;
                    censusMember.ARC_PhysicalAddressStreet__c = member.containsKey('ARC_PhysicalAddressStreet__c') ? (String)member.get('ARC_PhysicalAddressStreet__c') : null;
                    censusMember.ARC_PhysicalAddressZipCode__c = member.containsKey('ARC_PhysicalAddressZipCode__c') ? (String)member.get('ARC_PhysicalAddressZipCode__c') : null;
                    censusMember.ARC_Smoker__c = member.containsKey('ARC_Smoker__c') ? (Boolean)member.get('ARC_Smoker__c') : null;
                    censusMember.ARC_UseParentAddress__c = member.containsKey('CopyAddressFromPrimary') ? (Boolean)member.get('CopyAddressFromPrimary') : null;
                    censusMember.ARC_Weight__c = member.containsKey('ARC_Weight__c') ? String.valueOf(member.get('ARC_Weight__c')) : null;
                    censusMember.vlocity_ins__Birthdate__c = (member.containsKey('vlocity_ins__Birthdate__c') && member.get('vlocity_ins__Birthdate__c') != null)? Date.valueOf((String)member.get('vlocity_ins__Birthdate__c')) : null;
                    censusMember.vlocity_ins__Email__c = member.containsKey('vlocity_ins__Email__c') ? (String)member.get('vlocity_ins__Email__c') : null;
                    censusMember.vlocity_ins__LastName__c = member.containsKey('vlocity_ins__LastName__c') ? (String)member.get('vlocity_ins__LastName__c') : null;
                    censusMember.vlocity_ins__FirstName__c = member.containsKey('vlocity_ins__FirstName__c') ? (String)member.get('vlocity_ins__FirstName__c') : null;
                    censusMember.vlocity_ins__Gender__c = member.containsKey('vlocity_ins__Gender__c') ? (String)member.get('vlocity_ins__Gender__c') : null;
                    censusMember.vlocity_ins__IsPrimaryMember__c = member.containsKey('vlocity_ins__IsPrimaryMember__c') ? (Boolean)member.get('vlocity_ins__IsPrimaryMember__c') : null;
                    censusMember.vlocity_ins__SocialSecurityNumber__c = member.containsKey('vlocity_ins__SocialSecurityNumber__c') ? (String)member.get('vlocity_ins__SocialSecurityNumber__c') : null;
                    if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Spouse'){
                        censusMember.vlocity_ins__IsSpouse__c = true;
                    }                          
                    
                    //Add Census Member to List
                    System.debug('censusMemberToAdd ' + censusMember);
                    this.censusMembersToUpdate.add(censusMember);
                }            
            }
        }
        else if(action == 'addMember'){
            for (Map<String,Object> member : censusMembers) {      
                //CM Mapping
                if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == true && !member.containsKey('IsInactiveMember') ){
                    vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();
    
                    /////////MISSING MAPPINGS
                    /////////
                    /////////
    
                    // Need to confirm what to do Here:censusMember.vlocity_ins__MemberIdentifier__c = member.containsKey('vlocity_ins__MemberIdentifier__c') ? (String)member.get('vlocity_ins__MemberIdentifier__c') : null;
                    // Need to confirm what to do Here: censusMember.vlocity_ins__PrimaryMemberIdentifier__c = member.containsKey('vlocity_ins__PrimaryMemberIdentifier__c') ? (String)member.get('vlocity_ins__PrimaryMemberIdentifier__c') : null;
                    // Need to confirm what to do Here: censusMember.vlocity_ins__RelatedCensusMemberId__c = member.containsKey('vlocity_ins__RelatedCensusMemberId__c') ? (Id)member.get('vlocity_ins__RelatedCensusMemberId__c') : null;
                    // Not yet in JSON: censusMember.vlocity_ins__HasSpouse__c = member.containsKey('vlocity_ins__HasSpouse__c') ? (Boolean)member.get('vlocity_ins__HasSpouse__c') : null;
                    // Need PA Inseerted censusMember.vlocity_ins__ContactId__c = null;             
                     
                    if(member.containsKey('IsNewMember') && !(Boolean)member.get('IsNewMember')){
                        censusMember.Id =(Id)(member.containsKey('Id') ? member.get('Id') : 'null');
                    }
                    if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Primary'){
                        censusMember.ARC_DependentRelationship__c = '';
                        censusMember.vlocity_ins__IsPrimaryMember__c = true;
                    }                
                    else if(member.containsKey('ARC_Relationship__c')){
                        censusMember.ARC_DependentRelationship__c = (String)member.get('ARC_Relationship__c');   
                        censusMember.vlocity_ins__IsPrimaryMember__c = false;
                    }
                    if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Spouse'){
                        censusMember.vlocity_ins__IsSpouse__c = true;
                    }
                    censusMember.ARC_ActiveMember__c = false;                
                    
                    censusMember.ARC_HeightFeet__c = member.containsKey('ARC_HeightFeet__c') ? String.valueOf(member.get('ARC_HeightFeet__c')) : null;
                    censusMember.ARC_HeightInches__c = member.containsKey('ARC_HeightInches__c') ? String.valueOf(member.get('ARC_HeightInches__c')) : null;
                    censusMember.ARC_PhysicalAddressCity__c = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                    censusMember.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? (String)member.get('ARC_PhysicalAddressState__c') : null;
                    censusMember.ARC_PhysicalAddressStreet__c = member.containsKey('ARC_PhysicalAddressStreet__c') ? (String)member.get('ARC_PhysicalAddressStreet__c') : null;
                    censusMember.ARC_PhysicalAddressZipCode__c = member.containsKey('ARC_PhysicalAddressZipCode__c') ? (String)member.get('ARC_PhysicalAddressZipCode__c') : null;
                    censusMember.ARC_Smoker__c = member.containsKey('ARC_Smoker__c') ? (Boolean)member.get('ARC_Smoker__c') : null;
                    censusMember.ARC_UseParentAddress__c = member.containsKey('CopyAddressFromPrimary') ? (Boolean)member.get('CopyAddressFromPrimary') : null;
                    censusMember.ARC_Weight__c = member.containsKey('ARC_Weight__c') ? String.valueOf(member.get('ARC_Weight__c')) : null;
                    censusMember.vlocity_ins__Birthdate__c = (member.containsKey('vlocity_ins__Birthdate__c') && member.get('vlocity_ins__Birthdate__c') != null)? Date.valueOf((String)member.get('vlocity_ins__Birthdate__c')) : null;
                    censusMember.vlocity_ins__CensusId__c = this.inputMap.containsKey('CensusId') ? (Id)this.inputMap.get('CensusId') : null;
                    censusMember.vlocity_ins__Email__c = member.containsKey('vlocity_ins__Email__c') ? (String)member.get('vlocity_ins__Email__c') : null;
                    censusMember.vlocity_ins__LastName__c = member.containsKey('vlocity_ins__LastName__c') ? (String)member.get('vlocity_ins__LastName__c') : null;
                    censusMember.vlocity_ins__FirstName__c = member.containsKey('vlocity_ins__FirstName__c') ? (String)member.get('vlocity_ins__FirstName__c') : null;
                    censusMember.vlocity_ins__Gender__c = member.containsKey('vlocity_ins__Gender__c') ? (String)member.get('vlocity_ins__Gender__c') : null;
                    censusMember.vlocity_ins__IsPrimaryMember__c = member.containsKey('vlocity_ins__IsPrimaryMember__c') ? (Boolean)member.get('vlocity_ins__IsPrimaryMember__c') : null;
                    censusMember.vlocity_ins__SocialSecurityNumber__c = member.containsKey('vlocity_ins__SocialSecurityNumber__c') ? (String)member.get('vlocity_ins__SocialSecurityNumber__c') : null;
                    System.debug('censusMember ' + censusMember);
                    //Add to global list
                    this.censusMembersToInsert.add(censusMember);                                  
                }
            }
            
        }       
    }

    private void handleRemoveMember() { /* Your logic */ } /* TODO: Implement */





    //////Getters
    List<Map<String,Object>> getCensusMembers() {
        List<Map<String,Object>> censusMembers = new List<Map<String,Object>>();
        Map<String, Object> censusComponent = (Map<String, Object>)this.inputMap.get('census_component');
        List<Object> censusMembersList = (List<Object>)censusComponent.get('census_members');
        for (Object censusMember : censusMembersList) {
            Map<String,Object> member = (Map<String,Object>)censusMember;
            censusMembers.add(member);
        }
        return censusMembers;
    }



    ////Auxiliary Methods
    ///////////////////////
    ///////////////////////
    /////////////////////// 

    private Account createPersonAccount(String LastName) {
        Account newPA = new Account();
        newPA.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        newPA.LastName = LastName;
        newPA.ARC_Census__c = this.inputMap.containsKey('CensusId') ? (Id)this.inputMap.get('CensusId') : null;
        return newPA;        
    } 

    private void InsertAccountsWithCensusMemberIds() {
        if (!censusMemberToAccount.isEmpty()) {
            accountsToInsert = new List<Account>(censusMemberToAccount.values());
            System.debug('accountsToInsert ' + accountsToInsert);
            insertAccounts();
        }
    }    



    /////Block for managing DML Operations
    /////////
    ////////////
    /////////////////


    

    private void manageDML() {
        Set<String> operations = new Set<String>();
        for(String action : ActionsSelected){
            switch on action {
                when 'primaryChange' {
                    //Census Member --> Update
                    operations.add('upsertCensusMembers');
                    //Census --> Not needed on PC
                    //Person Account --> Update
                    operations.add('insertAccounts');
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert?
                   // operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //operations.add('insertHIPAA');
                    //Medical Questions --> Insert (?)
                    //operations.add('insertMedicalQuestions');
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'addressStateChange' {
                    //Census Member --> Update
                    operations.add('upsertCensusMembers');
                    //Census --> Not needed on PC
                    //Person Account --> Update
                    operations.add('insertAccounts');   
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert?
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> Insert (?)
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'relationshipToPrimaryChange' {
                    //Census Member --> Update
                    operations.add('upsertCensusMembers');  
                    //Census --> Not needed on PC
                    //Person Account --> Update
                    operations.add('insertAccounts');
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert?
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> Insert (?)
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'dateOfBirthChange' {
                    //Census Member --> Update
                    operations.add('upsertCensusMembers');
                    //Census --> Not needed on PC
                    //Person Account --> Update
                    operations.add('insertAccounts');
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert?
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> Insert (?)
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'programUpgrade' {
                    //Census Member --> N/A
                    //Census --> N/A
                    //Person Account --> N/A
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert
                    operations.add('insertCasesPC');
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> Update (?)
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'programDowngrade' {
                    //Census Member --> N/A
                    //Census --> N/A
                    //Person Account --> N/A
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> ?
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> ?
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'ancillaryChange' {                    
                    //Census Member --> N/A
                    //Census --> N/A
                    //Person Account --> N/A
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> ?
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> ?
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'removeAllAncillary' {
                    //Census Member --> N/A
                    //Census --> N/A
                    //Person Account --> N/A
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> ?
                    //Case (PC) --> Insert/Update
                    //HIPAA -->  (?)
                    //Medical Questions --> ?
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'effectiveDateChange' {
                    //Census Member --> N/A
                    //Census --> Not needed on PC
                    //Person Account --> N/A
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert?
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');    
                    //HIPAA -->  (?)
                    //Medical Questions -->  (?)
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'addMember' {
                    //Census Member --> Insert
                    operations.add('upsertCensusMembers');                    
                    //Census --> Not needed on PC
                    //Person Account --> Insert
                    operations.add('insertAccounts');                     
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert
                    operations.add('insertCasesPC');
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> Insert (?)
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'removeMember' {
                    //Census Member --> Update
                    operations.add('upsertCensusMembers');
                    //Census --> Not needed on PC
                    //Person Account --> Update
                    operations.add('insertAccounts');
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert?
                    //operations.add('insertCasesPC');
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> Insert (?)
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                } 
                when 'addExistingMember' {                    
                    //Census Member --> Update
                    operations.add('upsertCensusMembers');
                    //Census --> Not needed on PC
                    //Person Account --> Update
                    operations.add('insertAccounts');
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');   
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert?
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> Insert (?)
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
            }       
        }
        executeDML(operations);
    }

    // Method to execute actions
    private void executeDML(Set<String> operations) {        
        if(operations.contains('updateCensusMembers')) {
            upsertCensusMembers();
        }
        if(operations.contains('upsertCensusMembers')) {
            upsertCensusMembers();
        }
        if(operations.contains('insertAccounts')) {
            insertAccounts();
            updateRelatedCensusMembers();
        }
        if(operations.contains('insertContracts')) {
            upsertContracts();
        }
        if(operations.contains('insertContractLineItems')) {
            upsertContractLineItems();
        }
        if(operations.contains('insertGroupCensusMemberPlans')) {
            upsertGroupCensusMemberPlans();
        }
        if(operations.contains('insertContractParticipants')) {
            upsertContractParticipants();
        }
        if(operations.contains('insertChargentOrders')) {
            upsertChargentOrders();
        }
        if(operations.contains('insertCasesUW')) {
            upsertCasesUW();
        }
        if(operations.contains('insertCasesPC')) {
            upsertCasesPC();
        }
        if(operations.contains('insertPolicy')) {
            // TODO: Implement policy insertion logic
        }
    }
    
    
    
    
    private void insertAccounts() {
        if (!accountsToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(accountsToInsert, true);//All or none = true
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting account: ' + error.getMessage());
                        }
                    } else {
                        if (!allInsertedRecords.containsKey('Account')) {
                            allInsertedRecords.put('Account', new Map<Id, SObject>());
                        }                      


                        allInsertedRecords.get('Account').put(result.getId(), accountsToInsert[i]);                        
                        System.debug(result.getId() + ' ' + ' censusMemberToAccount ' + censusMemberToAccount);
                        accountIdToMemberId.put(result.getId(), accountsToInsert[i].Census_Member__c);
                        
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting accounts: ' + e.getMessage());
                throw e;
            }
        }
    }    

    private void upsertCensusMembers() {
        if (!censusMembersToInsert.isEmpty()) {            
            try {
                // First insert the census members                
                Database.SaveResult[] results = Database.insert(censusMembersToInsert, true);
                
                // Then create and insert accounts
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting census member: ' + error.getMessage());
                        }
                    } else {
                        if (!allInsertedRecords.containsKey('GroupCensusMember')) {
                            allInsertedRecords.put('GroupCensusMember', new Map<Id, SObject>());
                        }
                        allInsertedRecords.get('GroupCensusMember').put(result.getId(), censusMembersToInsert[i]);
                        
                        // Create account and link it to the census member
                        Account newAcc = createPersonAccount((String)censusMembersToInsert[i].vlocity_ins__LastName__c);
                        newAcc.Census_Member__c = result.getId();
                        newAcc.ARC_CensusMember__pc = result.getId();
                        accountsToInsert.add(newAcc);                 

                        censusMemberToAccount.put(result.getId(), newAcc);

                        System.debug('allInsertedRecords.get(GroupCensusMember) ' + allInsertedRecords.get('GroupCensusMember') );
                        System.debug('censusMemberToAccount ' + censusMemberToAccount);
                    }
                }                
            } catch (Exception e) {
                System.debug('Exception while upserting census members: ' + e.getMessage());
                throw e;
            }
        }        
        if (!censusMembersToUpdate.isEmpty()) {
            System.debug('censusMembersToUpdateDML: ' + censusMembersToUpdate);
            try {
                Database.SaveResult[] results = Database.update(censusMembersToUpdate, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error updating census member: ' + error.getMessage());
                        }
                    } else {
                        if (!allInsertedRecords.containsKey('GroupCensusMember')) {
                            allInsertedRecords.put('GroupCensusMember', new Map<Id, SObject>());
                        }
                        allInsertedRecords.get('GroupCensusMember').put(result.getId(), censusMembersToUpdate[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while updating census members: ' + e.getMessage());
                throw e;
            }
        }
    }
    
    private void updateRelatedCensusMembers() {
        List<vlocity_ins__GroupCensusMember__c> censusMembersToUpdateContactId = new List<vlocity_ins__GroupCensusMember__c>();
        List<Account> accContacts = new List<Account>([SELECT Id, PersonContactId FROM Account WHERE Id IN :accountIdToMemberId.keySet()]);
        for(Account acc : accContacts) {
            vlocity_ins__GroupCensusMember__c censusMember = (vlocity_ins__GroupCensusMember__c)allInsertedRecords.get('GroupCensusMember').get(accountIdToMemberId.get(acc.Id));
            censusMember.vlocity_ins__ContactId__c = acc.PersonContactId;
            censusMembersToUpdateContactId.add(censusMember);
        }
        update censusMembersToUpdateContactId;
    }   

    
    private void upsertContracts() {
        if (!contractsToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(contractsToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting contract: ' + error.getMessage());
                        }
                    } else {
                        if (!allInsertedRecords.containsKey('Contract')) {
                            allInsertedRecords.put('Contract', new Map<Id, SObject>());
                        }
                        allInsertedRecords.get('Contract').put(result.getId(), contractsToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting contracts: ' + e.getMessage());
                throw e;
            }
        }
    }
    private void upsertContractLineItems() {
        if (!contractLineItemsToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(contractLineItemsToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting contract line item: ' + error.getMessage());
                        }
                    } else {
                        if (!allInsertedRecords.containsKey('ContractLineItem')) {
                            allInsertedRecords.put('ContractLineItem', new Map<Id, SObject>());
                        }
                        allInsertedRecords.get('ContractLineItem').put(result.getId(), contractLineItemsToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting contract line items: ' + e.getMessage());
                throw e;
            }
        }
    }
    private void upsertGroupCensusMemberPlans() {
        if (!groupCensusMemberPlansToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(groupCensusMemberPlansToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting group census member plan: ' + error.getMessage());
                        }
                    } else {
                        if (!allInsertedRecords.containsKey('GroupCensusMemberPlan')) {
                            allInsertedRecords.put('GroupCensusMemberPlan', new Map<Id, SObject>());
                        }
                        allInsertedRecords.get('GroupCensusMemberPlan').put(result.getId(), groupCensusMemberPlansToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting group census member plans: ' + e.getMessage());
                throw e;
            }
        }
    }
    private void upsertContractParticipants() {
        if (!contractParticipantsToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(contractParticipantsToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting contract participant: ' + error.getMessage());
                        }
                    } else {
                        if (!allInsertedRecords.containsKey('ContractParticipant')) {
                            allInsertedRecords.put('ContractParticipant', new Map<Id, SObject>());
                        }
                        allInsertedRecords.get('ContractParticipant').put(result.getId(), contractParticipantsToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting contract participants: ' + e.getMessage());
                throw e;
            }
        }
    }
    private void upsertChargentOrders() {
        if (!chargentOrdersToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(chargentOrdersToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting chargent order: ' + error.getMessage());
                        }
                    } else {
                        if (!allInsertedRecords.containsKey('ChargentOrder')) {
                            allInsertedRecords.put('ChargentOrder', new Map<Id, SObject>());
                        }
                        allInsertedRecords.get('ChargentOrder').put(result.getId(), chargentOrdersToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting chargent orders: ' + e.getMessage());
                throw e;
            }
        }
    }
    private void upsertCasesUW() {
        if (!casesUWToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(casesUWToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting UW case: ' + error.getMessage());
                        }
                    } else {
                        if (!allInsertedRecords.containsKey('CaseUW')) {
                            allInsertedRecords.put('CaseUW', new Map<Id, SObject>());
                        }
                        allInsertedRecords.get('CaseUW').put(result.getId(), casesUWToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting UW cases: ' + e.getMessage());
                throw e;
            }
        }
    }
    private void upsertHipaaAuthorizations() {
        if (!hipaaAuthorizationsToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(hipaaAuthorizationsToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting HIPAA authorization: ' + error.getMessage());
                        }
                    } else {
                        if (!allInsertedRecords.containsKey('HipaaAuthorization')) {
                            allInsertedRecords.put('HipaaAuthorization', new Map<Id, SObject>());
                        }
                        allInsertedRecords.get('HipaaAuthorization').put(result.getId(), hipaaAuthorizationsToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting HIPAA authorizations: ' + e.getMessage());
                throw e;
            }
        }
    }
    private void upsertMedicalConditions() {
        if (!medicalConditionsToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(medicalConditionsToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting medical condition: ' + error.getMessage());
                        }
                    } else {
                        if (!allInsertedRecords.containsKey('MedicalCondition')) {
                            allInsertedRecords.put('MedicalCondition', new Map<Id, SObject>());
                        }
                        allInsertedRecords.get('MedicalCondition').put(result.getId(), medicalConditionsToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting medical conditions: ' + e.getMessage());
                throw e;
            }
        }
    }
    private void upsertConsumerDrugs() {
        if (!consumerDrugsToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(consumerDrugsToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting consumer drug: ' + error.getMessage());
                        }
                    } else {
                        if (!allInsertedRecords.containsKey('ConsumerDrug')) {
                            allInsertedRecords.put('ConsumerDrug', new Map<Id, SObject>());
                        }
                        allInsertedRecords.get('ConsumerDrug').put(result.getId(), consumerDrugsToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting consumer drugs: ' + e.getMessage());
                throw e;
            }
        }
    }
    private void upsertCasesPC() {
        if (!casesPCToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(casesPCToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting PC case: ' + error.getMessage());
                        }
                    } else {
                        if (!allInsertedRecords.containsKey('CasePC')) {
                            allInsertedRecords.put('CasePC', new Map<Id, SObject>());
                        }
                        allInsertedRecords.get('CasePC').put(result.getId(), casesPCToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting PC cases: ' + e.getMessage());
                throw e;
            }
        }
    }
}