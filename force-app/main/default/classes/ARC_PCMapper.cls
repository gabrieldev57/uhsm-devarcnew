/**
 * @Description: This class is responsible for mapping and transforming input data into Salesforce objects.
 * It handles different types of program changes and prepares the data for database operations.
 * The class follows a modular approach where each type of change (primary change, address change, etc.)
 * triggers specific actions that are executed in sequence.
 * 
 * Key Features:
 * - Handles program changes (upgrades, downgrades, ancillary changes)
 * - Manages member changes (add, remove, update)
 * - Processes medical conditions and authorizations
 * - Creates and updates contracts and related records
 * - Handles payment processing and promotions
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-04-15
 * @Version: 1.0
 */

public without sharing class ARC_PCMapper {    
    private ARC_PCManager manager;
    private Set<String> actionsToExecute = new Set<String>();
    

 
    /**
     * @Description: Main entry point that orchestrates the program change process.
     * This method:
     * 1. Initializes the manager with input data
     * 2. Processes all program changes
     * 3. Executes the required actions in sequence
     * 
     * @param manager: The InsertManager instance containing all input data and state
     * @throws AuraHandledException if there is an error during execution
     */
    public void executeChanges(ARC_PCManager manager) {
        this.manager = manager;
        Map<String,Object> pcChangesMap = (Map<String,Object>)manager.inputMap.get('pcChanges');

        if(pcChangesMap.containsKey('createNewContract') && (Boolean)pcChangesMap.get('createNewContract') == true){
             // Process each type of program change and collect required actions
            if (manager.pcReasons.containsKey('primaryChange') && (Boolean) manager.pcReasons.get('primaryChange')) {            
                manager.ActionsSelected.add('primaryChange');
                actionsToExecute.add('upsertGuardian');
                actionsToExecute.add('insertCaseForFeedSkipped');
                actionsToExecute.add('createUWCase');
                actionsToExecute.add('createUWCaseMembers');
                actionsToExecute.add('insertContract');
                actionsToExecute.add('createCLI');
                actionsToExecute.add('insertContractParticipants');
                actionsToExecute.add('createChargentOrders');
                actionsToExecute.add('insertHipaaAuthorization');
                actionsToExecute.add('insertPromotionDiscount');
            }
            if (manager.pcReasons.containsKey('addressStateChange') && (Boolean) manager.pcReasons.get('addressStateChange')) {
                
                manager.ActionsSelected.add('addressStateChange');
                actionsToExecute.add('updateGCMaddressStateChange');
                actionsToExecute.add('upsertGuardian');
                actionsToExecute.add('insertCaseForFeedSkipped');
                actionsToExecute.add('createUWCase');
                actionsToExecute.add('createUWCaseMembers');
                actionsToExecute.add('insertContract');
                actionsToExecute.add('createCLI');
                actionsToExecute.add('createChargentOrders');
                actionsToExecute.add('insertContractParticipants');
                actionsToExecute.add('insertHipaaAuthorization');
                actionsToExecute.add('insertPromotionDiscount');
                actionsToExecute.add('updatePersonMedicareInformation');
            }
            if (manager.pcReasons.containsKey('relationshipToPrimaryChange') && (Boolean) manager.pcReasons.get('relationshipToPrimaryChange')) {
                
                manager.ActionsSelected.add('relationshipToPrimaryChange');
                actionsToExecute.add('upsertGuardian');
                actionsToExecute.add('insertCaseForFeedSkipped');
                actionsToExecute.add('createUWCase');
                actionsToExecute.add('createUWCaseMembers');
                actionsToExecute.add('insertContract');
                actionsToExecute.add('createCLI');
                actionsToExecute.add('insertContractParticipants');
                actionsToExecute.add('createChargentOrders');
                actionsToExecute.add('insertHipaaAuthorization');
                actionsToExecute.add('insertPromotionDiscount');
            }
            if (manager.pcReasons.containsKey('dateOfBirthChange') && (Boolean) manager.pcReasons.get('dateOfBirthChange')) {            
                
                manager.ActionsSelected.add('dateOfBirthChange');
                actionsToExecute.add('updateGCMdateOfBirthChange');
                actionsToExecute.add('upsertGuardian');
                actionsToExecute.add('insertCaseForFeedSkipped');
                actionsToExecute.add('createUWCase');
                actionsToExecute.add('createUWCaseMembers');
                actionsToExecute.add('insertContract');
                actionsToExecute.add('createCLI');
                actionsToExecute.add('insertContractParticipants');
                actionsToExecute.add('createChargentOrders');
                actionsToExecute.add('insertHipaaAuthorization');
                actionsToExecute.add('insertPromotionDiscount');
                actionsToExecute.add('updatePersonMedicareInformation');
            }
            // Program and Effective Date Changes
            if (manager.pcReasons.containsKey('programUpgrade') && (Boolean) manager.pcReasons.get('programUpgrade')) {
                
                manager.ActionsSelected.add('programUpgrade');            
                actionsToExecute.add('upsertGuardian');
                actionsToExecute.add('insertCaseForFeedSkipped'); 
                actionsToExecute.add('createUWCase');
                actionsToExecute.add('createUWCaseMembers');
                actionsToExecute.add('insertContract');
                actionsToExecute.add('createCLI');
                actionsToExecute.add('upsertMedicalQuesitons');
                actionsToExecute.add('insertContractParticipants');
                actionsToExecute.add('createChargentOrders');
                actionsToExecute.add('insertHipaaAuthorization');
                actionsToExecute.add('insertPromotionDiscount');
            }
            if (manager.pcReasons.containsKey('programDowngrade') && (Boolean) manager.pcReasons.get('programDowngrade')) {
                
                manager.ActionsSelected.add('programDowngrade');
                actionsToExecute.add('upsertGuardian');
                actionsToExecute.add('insertCaseForFeedSkipped');
                actionsToExecute.add('createUWCase');
                actionsToExecute.add('createUWCaseMembers');
                actionsToExecute.add('insertContract');
                actionsToExecute.add('createCLI');
                actionsToExecute.add('insertContractParticipants');
                actionsToExecute.add('createChargentOrders');
                actionsToExecute.add('insertHipaaAuthorization');
                actionsToExecute.add('insertPromotionDiscount');
            }
            if (manager.pcReasons.containsKey('ancillaryChange') && (Boolean) manager.pcReasons.get('ancillaryChange')) {
                
                manager.ActionsSelected.add('ancillaryChange');
                actionsToExecute.add('upsertGuardian');
                actionsToExecute.add('insertCaseForFeedSkipped'); 
                actionsToExecute.add('createUWCase');
                actionsToExecute.add('createUWCaseMembers');
                actionsToExecute.add('insertContract');
                actionsToExecute.add('createCLI');
                actionsToExecute.add('insertContractParticipants');
                actionsToExecute.add('createChargentOrders');
                actionsToExecute.add('insertHipaaAuthorization');
                actionsToExecute.add('insertPromotionDiscount');
            }
            if (manager.pcReasons.containsKey('removeAllAncillary') && (Boolean) manager.pcReasons.get('removeAllAncillary')) {            
                
                manager.ActionsSelected.add('removeAllAncillary');
                actionsToExecute.add('upsertGuardian');
                actionsToExecute.add('insertCaseForFeedSkipped'); 
                actionsToExecute.add('createUWCase');
                actionsToExecute.add('createUWCaseMembers');
                actionsToExecute.add('insertContract');
                actionsToExecute.add('createCLI');
                actionsToExecute.add('insertContractParticipants');
                actionsToExecute.add('createChargentOrders');
                actionsToExecute.add('insertHipaaAuthorization');
                actionsToExecute.add('insertPromotionDiscount');
            }
            if (manager.pcReasons.containsKey('effectiveDateChange') && (Boolean) manager.pcReasons.get('effectiveDateChange')) {//Future
            
                manager.ActionsSelected.add('effectiveDateChange');
                actionsToExecute.add('upsertGuardian');
                actionsToExecute.add('insertCaseForFeedSkipped'); 
                actionsToExecute.add('createUWCase'); //review
                actionsToExecute.add('createUWCaseMembers');
                actionsToExecute.add('insertContract');
                actionsToExecute.add('createCLI');
                actionsToExecute.add('insertContractParticipants');
                actionsToExecute.add('createChargentOrders'); 
                actionsToExecute.add('insertHipaaAuthorization');
                actionsToExecute.add('insertPromotionDiscount');
                actionsToExecute.add('updatePersonMedicareInformation');
            }
            // Add/Remove Member Changes
            if (manager.pcReasons.containsKey('addMember') && (Boolean) manager.pcReasons.get('addMember')) {
                
                manager.ActionsSelected.add('addMember');
                actionsToExecute.add('updateGCMaddMember');
                actionsToExecute.add('upsertGuardian');
                actionsToExecute.add('insertCaseForFeedSkipped');
                actionsToExecute.add('createUWCase');
                actionsToExecute.add('createUWCaseMembers');
                actionsToExecute.add('insertContract');
                actionsToExecute.add('createCLI');
                actionsToExecute.add('upsertMedicalQuesitons');
                actionsToExecute.add('insertContractParticipants');
                actionsToExecute.add('createChargentOrders');
                actionsToExecute.add('insertHipaaAuthorization');
                actionsToExecute.add('insertPromotionDiscount');
            }
            if (manager.pcReasons.containsKey('removeMember') && (Boolean) manager.pcReasons.get('removeMember')) {
                
                manager.ActionsSelected.add('removeMember');
                actionsToExecute.add('upsertGuardian');
                actionsToExecute.add('insertCaseForFeedSkipped'); 
                actionsToExecute.add('createUWCase');
                actionsToExecute.add('createUWCaseMembers');
                actionsToExecute.add('insertContract');
                actionsToExecute.add('createCLI');
                actionsToExecute.add('insertContractParticipants');
                actionsToExecute.add('createChargentOrders');
                actionsToExecute.add('insertHipaaAuthorization');
                actionsToExecute.add('insertPromotionDiscount');
            }
            if (manager.pcReasons.containsKey('addExistingMember') && (Boolean) manager.pcReasons.get('addExistingMember')) {
                
                manager.ActionsSelected.add('addExistingMember');
                actionsToExecute.add('updateGCMaddExistingMember');
                actionsToExecute.add('upsertGuardian');
                actionsToExecute.add('insertCaseForFeedSkipped'); 
                actionsToExecute.add('createUWCase');
                actionsToExecute.add('createUWCaseMembers');
                actionsToExecute.add('insertContract');
                actionsToExecute.add('createCLI');
                actionsToExecute.add('upsertMedicalQuesitons');
                actionsToExecute.add('insertContractParticipants');
                actionsToExecute.add('createChargentOrders');
                actionsToExecute.add('insertHipaaAuthorization');
                actionsToExecute.add('insertPromotionDiscount');
            }
            if (manager.pcReasons.containsKey('agingOut') && (Boolean)manager.pcReasons.get('agingOut')) {
                manager.ActionsSelected.add('agingOut');
                actionsToExecute.add('upsertGuardian');
                actionsToExecute.add('insertCaseForFeedSkipped');
                actionsToExecute.add('createUWCase');
                actionsToExecute.add('createUWCaseMembers');
                actionsToExecute.add('insertContract');
                actionsToExecute.add('createCLI');
                actionsToExecute.add('createChargentOrders');
                actionsToExecute.add('insertContractParticipants');
                actionsToExecute.add('insertHipaaAuthorization');
                actionsToExecute.add('insertPromotionDiscount');
                actionsToExecute.add('updatePersonMedicareInformation');
            }
            if(manager.inputMap.containsKey('demographicUpdates') && (Boolean)manager.inputMap.get('demographicUpdates') == true){            
                actionsToExecute.add('updateGCMdemographicChange');
                actionsToExecute.add('insertHipaaAuthorization'); 
            }
        }
        else if (pcChangesMap.containsKey('createNewContract') && (Boolean)pcChangesMap.get('createNewContract') == false){
            if(manager.inputMap.containsKey('demographicUpdates') && (Boolean)manager.inputMap.get('demographicUpdates') == true){            
                actionsToExecute.add('updateGCMdemographicChange');
                actionsToExecute.add('insertHipaaAuthorization');
                if (manager.inputMap.containsKey('isLegacyContract') && manager.inputMap.get('isLegacyContract') == true && manager.inputMap.containsKey('STEP_MedicareCoverage') && manager.inputMap.get('STEP_MedicareCoverage') != null) {
                    manager.ActionsSelected.add('demographicChange');
                    actionsToExecute.add('updatePersonMedicareInformation');
                }
            }       
            if( pcChangesMap.containsKey('updateEffectiveDateChange') && (Boolean) pcChangesMap.get('updateEffectiveDateChange') == true){
                manager.ActionsSelected.add('updateEffectiveDateChange');
                actionsToExecute.add('updateContract');
                //actionsToExecute.add('createChargentOrders');
                actionsToExecute.add('insertHipaaAuthorization');
            }             
        }  
        if(manager.pcReasons.containsKey('addExistingNewborn') && (Boolean) manager.inputMap.get('extendNewbornPolicyCoverage'))  {
            actionsToExecute.add('updatePolicyEndDateForNewborns');
        }    
         executeActions(actionsToExecute);        
    }

    /**
     * @Description: Executes a set of actions in sequence, handling each action's specific requirements.
     * Each action is executed in a try-catch block to ensure proper error handling.
     * 
     * @param actions: Set of action names to execute
     * @throws AuraHandledException if any action fails to execute
     */
    private void executeActions(Set<String> actions){
        List<Map<String,Object>> censusMembers = getCensusMembers();
        for(String action : actions){
            try {
                switch on action {
                    when 'updateGCMprimaryChange' {
                        updateGCM('primaryChange');
                    }
                    when 'upsertGuardian' {
                        upsertGuardian();
                    }
                    when 'insertCaseForFeedSkipped' {
                        insertCaseForFeedSkipped();
                    }
                    when 'updateGCMaddressStateChange' {
                        updateGCM('addressStateChange');
                    }
                    when 'updateGCMrelationshipToPrimaryChange' {
                        updateGCM('relationshipToPrimaryChange');
                    }
                    when 'updateGCMdateOfBirthChange' {
                        updateGCM('dateOfBirthChange');
                    }
                    when 'updateGCMaddMember' {
                        updateGCM('addMember');
                    }
                    when 'updateGCMaddExistingMember' {
                        updateGCM('addExistingMember');
                    }
                    when 'updateGCMremoveMember' {
                        updateGCM('removeMember');
                    }
                    when 'updateGCMremoveAllAncillary' {
                        updateGCM('removeAllAncillary');
                    }
                    when 'createUWCase' {
                        handlerUWCases();
                    }
                    when 'createUWCaseMembers' {
                        handlerUWCaseMembers();
                    }
                    when 'updateContract' {
                        upsertContracts('Update');
                    }
                    when 'insertContract' {
                        upsertContracts('Insert');
                        upsertContracts('oldContracts');
                    }
                    when 'createCLI' {
                        createContractLineItems('Insert');
                    }
                    when 'upsertMedicalQuesitons' {
                        upsertMedicalQuesitons();
                    }
                    when 'insertContractParticipants' {
                        createContractParticipants();
                    }
                    when 'createChargentOrders' {
                        createChargentOrders('Recurring');
                    }
                    when 'insertHipaaAuthorization' {
                        createHipaaAuthorization();
                    }
                    when 'insertPromotionDiscount' {
                        insertPromotionDiscount();
                    }
                    when 'updateGCMdemographicChange' {
                        updateGCM('demographicChange');
                    }
                    when 'updateEffectiveDateChange' {
                        upsertContracts('Update');
                    }
                    when 'updatePersonMedicareInformation' {
                        updatePersonMedicareInformation();
                    }
                    when 'updatePolicyEndDateForNewborns' {
                        updatePolicyEndDateForNewborns();
                    }
                }
            } catch (Exception e) {
                system.debug('Error executing action ' + action + ': ' + e.getMessage());
                throw new AuraHandledException('Error executing action ' + action + ': ' + e.getMessage());
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   updateGCM  
    * @Description        :   Method to handle add existing member
    ********************************************************************/
    private void updateGCM(String action) { 
        List<Map<String,Object>> censusMembers  = getCensusMembers();
        Map<String,String> oldPrimaryValues = getOldPrimaryValues();
        
        if(action == 'addExistingMember'){
            try{
                for (Map<String,Object> member : censusMembers) {
                    if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false 
                        && member.containsKey('IsInactiveMember') && (Boolean)member.get('IsInactiveMember') == true){                
                        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();
                
                        if(member.containsKey('IsNewMember') && !(Boolean)member.get('IsNewMember')){
                            censusMember.Id =(Id)(member.containsKey('Id') ? member.get('Id') : 'null');
                        }
                                                                  
                        censusMember.ARC_HeightFeet__c = member.containsKey('ARC_HeightFeet__c') ? String.valueOf(member.get('ARC_HeightFeet__c')) : null;
                        censusMember.ARC_HeightInches__c = member.containsKey('ARC_HeightInches__c') ? String.valueOf(member.get('ARC_HeightInches__c')) : null;
                        censusMember.ARC_PhysicalAddressCity__c = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                        censusMember.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? String.valueOf(member.get('ARC_PhysicalAddressState__c')).toUpperCase() : null;
                        censusMember.ARC_PhysicalAddressStreet__c = member.containsKey('ARC_PhysicalAddressStreet__c') ? (String)member.get('ARC_PhysicalAddressStreet__c') : null;
                        censusMember.ARC_PhysicalAddressZipCode__c = member.containsKey('ARC_PhysicalAddressZipCode__c') ? (String)member.get('ARC_PhysicalAddressZipCode__c') : null;
                        censusMember.ARC_Smoker__c = member.containsKey('ARC_Smoker__c') ? convertToBoolean(member.get('ARC_Smoker__c')) : null;
                        censusMember.ARC_UseParentAddress__c = member.containsKey('CopyAddressFromPrimary') ? convertToBoolean(member.get('CopyAddressFromPrimary')) : null;
                        censusMember.ARC_Weight__c = member.containsKey('ARC_Weight__c') ? String.valueOf(member.get('ARC_Weight__c')) : null;
                        censusMember.vlocity_ins__Birthdate__c = (member.containsKey('vlocity_ins__Birthdate__c') && member.get('vlocity_ins__Birthdate__c') != null)? Date.valueOf((String)member.get('vlocity_ins__Birthdate__c')) : null;
                        censusMember.vlocity_ins__Email__c = member.containsKey('vlocity_ins__Email__c') ? (String)member.get('vlocity_ins__Email__c') : null;
                        censusMember.vlocity_ins__LastName__c = member.containsKey('vlocity_ins__LastName__c') ? (String)member.get('vlocity_ins__LastName__c') : null;
                        censusMember.vlocity_ins__FirstName__c = member.containsKey('vlocity_ins__FirstName__c') ? (String)member.get('vlocity_ins__FirstName__c') : null;
                        censusMember.vlocity_ins__Gender__c = member.containsKey('vlocity_ins__Gender__c') ? (String)member.get('vlocity_ins__Gender__c') : null;
                        
                        censusMember.vlocity_ins__SocialSecurityNumber__c = member.containsKey('vlocity_ins__SocialSecurityNumber__c') ? (String)member.get('vlocity_ins__SocialSecurityNumber__c') : null;
                         
                        // Handle primary member relationship
                        if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Primary'){
                            censusMember.ARC_DependentRelationship__c = 'Future Primary';
                            censusMember.vlocity_ins__IsPrimaryMember__c = false;
                        }
                        else if(member.containsKey('ARC_Relationship__c')){
                            censusMember.ARC_DependentRelationship__c = (String)member.get('ARC_Relationship__c');   
                            censusMember.vlocity_ins__IsPrimaryMember__c = false;
                        }
                        if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Spouse'){
                            censusMember.vlocity_ins__IsSpouse__c = true;
                        }
                        censusMember.vlocity_ins__RelatedCensusMemberId__c = oldPrimaryValues.get('Id');
                        censusMember.vlocity_ins__PrimaryMemberIdentifier__c = oldPrimaryValues.get('vlocity_ins__MemberIdentifier__c');

                        manager.censusMembersToUpdate.add(censusMember);
                    }                       
                }            
            }
            catch(Exception e){
                System.debug('Exception updateGCM.addExistingMember ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw e;
            }
        }
        else if(action == 'addMember'){
            try{
                for (Map<String,Object> member : censusMembers) {      
                    //CM Mapping
                    if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == true ){
                        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();               
                        censusMember.ARC_ActiveMember__c = false;              
                        censusMember.vlocity_ins__MemberIdentifier__c = member.containsKey('vlocity_ins__MemberIdentifier__c') ? (String)member.get('vlocity_ins__MemberIdentifier__c') : null;
                        censusMember.ARC_Phone__c = member.containsKey('ARC_Phone__c') ? (String)member.get('ARC_Phone__c') : null;
                        censusMember.ARC_HeightFeet__c = member.containsKey('ARC_HeightFeet__c') ? String.valueOf(member.get('ARC_HeightFeet__c')) : null;
                        censusMember.ARC_HeightInches__c = member.containsKey('ARC_HeightInches__c') ? String.valueOf(member.get('ARC_HeightInches__c')) : null;
                        censusMember.ARC_PhysicalAddressCity__c = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                        censusMember.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? String.valueOf(member.get('ARC_PhysicalAddressState__c')).toUpperCase() : null;
                        censusMember.ARC_PhysicalAddressStreet__c = member.containsKey('ARC_PhysicalAddressStreet__c') ? (String)member.get('ARC_PhysicalAddressStreet__c') : null;
                        censusMember.ARC_PhysicalAddressZipCode__c = member.containsKey('ARC_PhysicalAddressZipCode__c') ? (String)member.get('ARC_PhysicalAddressZipCode__c') : null;
                        censusMember.ARC_Smoker__c = member.containsKey('ARC_Smoker__c') ?convertToBoolean(member.get('ARC_Smoker__c')) : null;
                        censusMember.ARC_UseParentAddress__c = member.containsKey('CopyAddressFromPrimary') ? convertToBoolean(member.get('CopyAddressFromPrimary')) : null;
                        censusMember.ARC_Weight__c = member.containsKey('ARC_Weight__c') ? String.valueOf(member.get('ARC_Weight__c')) : null;
                        censusMember.vlocity_ins__Birthdate__c = (member.containsKey('vlocity_ins__Birthdate__c') && member.get('vlocity_ins__Birthdate__c') != null)? Date.valueOf((String)member.get('vlocity_ins__Birthdate__c')) : null;
                        censusMember.vlocity_ins__CensusId__c = manager.inputMap.containsKey('CensusId') ? (Id)manager.inputMap.get('CensusId') : null;
                        censusMember.vlocity_ins__Email__c = member.containsKey('vlocity_ins__Email__c') ? (String)member.get('vlocity_ins__Email__c') : null;
                        censusMember.vlocity_ins__LastName__c = member.containsKey('vlocity_ins__LastName__c') ? (String)member.get('vlocity_ins__LastName__c') : null;
                        censusMember.vlocity_ins__FirstName__c = member.containsKey('vlocity_ins__FirstName__c') ? (String)member.get('vlocity_ins__FirstName__c') : null;
                        censusMember.vlocity_ins__Gender__c = member.containsKey('vlocity_ins__Gender__c') ? (String)member.get('vlocity_ins__Gender__c') : null;
                        
                        censusMember.vlocity_ins__SocialSecurityNumber__c = member.containsKey('vlocity_ins__SocialSecurityNumber__c') ? (String)member.get('vlocity_ins__SocialSecurityNumber__c') : null;
                       
                        for(String key : manager.censusMemberByTemporalId.keySet()){
                            manager.censusMemberByTemporalId.get(key).Id = null; 
                        }
                        
                        if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Primary'){
                            censusMember.ARC_DependentRelationship__c = 'Future Primary';
                            censusMember.vlocity_ins__IsPrimaryMember__c = false;
                        }
                        else if(member.containsKey('ARC_Relationship__c')){
                            censusMember.ARC_DependentRelationship__c = (String)member.get('ARC_Relationship__c');   
                            censusMember.vlocity_ins__IsPrimaryMember__c = false;
                        }
                        if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Spouse'){
                            censusMember.vlocity_ins__IsSpouse__c = true;
                        }
                        
                        censusMember.vlocity_ins__RelatedCensusMemberId__c = oldPrimaryValues.get('Id');
                        censusMember.vlocity_ins__PrimaryMemberIdentifier__c = oldPrimaryValues.get('vlocity_ins__MemberIdentifier__c');
                        
                         //Add to global list
                        manager.temporalIdToCensusMembers.put((String)member.get('Id'), censusMember);
                        manager.censusMemberByTemporalId.put((String)member.get('Id'), censusMember);
                       
                        manager.censusMembersToInsert.add(censusMember);
                    }
                }             
            }
            catch(Exception e){
                System.debug('Exception updateGCM.addMember ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw e;
            }
        }       
        else if(action == 'dateOfBirthChange'){
            try{
                List<Map<String,Object>> censusMembersDateOfBirth = getCensusMembers();
                for(Map<String,Object> member : censusMembersDateOfBirth){
                    if(member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false && member.containsKey('IsInactiveMember') && (Boolean)member.get('IsInactiveMember') == false){
                        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();
                        censusMember.Id =(Id)(member.containsKey('Id') ? member.get('Id') : 'null');
                        censusMember.vlocity_ins__Birthdate__c = (member.containsKey('vlocity_ins__Birthdate__c') && member.get('vlocity_ins__Birthdate__c') != null)? Date.valueOf((String)member.get('vlocity_ins__Birthdate__c')) : null;
                        manager.censusMembersToUpdate.add(censusMember);
                    }
                }    
            }
            catch(Exception e){
                System.debug('Exception updateGCM.dateOfBirthChange ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw e;
            }
        }
        else if(action == 'addressStateChange'){
            try{
                List<Map<String,Object>> censusMembersAddressState = getCensusMembers();
                for(Map<String,Object> member : censusMembersAddressState){
                    if(member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false && !member.containsKey('IsInactiveMember')){
                        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();
                        censusMember.Id =(Id)(member.containsKey('Id') ? member.get('Id') : 'null');
                       
                        censusMember.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? String.valueOf(member.get('ARC_PhysicalAddressState__c')).toUpperCase() : null;
                        censusMember.ARC_PhysicalAddressCity__c = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                        censusMember.vlocity_ins__Email__c = member.containsKey('vlocity_ins__Email__c') ? (String)member.get('vlocity_ins__Email__c') : null;
                        censusMember.ARC_Phone__c = member.containsKey('ARC_Phone__c') ? (String)member.get('ARC_Phone__c') : null;
                        censusMember.ARC_PhysicalAddressZipCode__c = member.containsKey('ARC_PhysicalAddressZipCode__c') ? (String)member.get('ARC_PhysicalAddressZipCode__c') : null;
                        censusMember.ARC_PhysicalAddressStreet__c = member.containsKey('ARC_PhysicalAddressStreet__c') ? (String)member.get('ARC_PhysicalAddressStreet__c') : null;
                        
                        
                        ///////

                        censusMember.ARC_PhysicalAddressCity__c = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                        censusMember.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? String.valueOf(member.get('ARC_PhysicalAddressState__c')).toUpperCase() : null;
                        censusMember.ARC_PhysicalAddressStreet__c = member.containsKey('ARC_PhysicalAddressStreet__c') ? (String)member.get('ARC_PhysicalAddressStreet__c') : null;
                        censusMember.ARC_PhysicalAddressZipCode__c = member.containsKey('ARC_PhysicalAddressZipCode__c') ? (String)member.get('ARC_PhysicalAddressZipCode__c') : null;
                        censusMember.vlocity_ins__Email__c = member.containsKey('vlocity_ins__Email__c') ? (String)member.get('vlocity_ins__Email__c') : null;

                        manager.censusMembersToUpdate.add(censusMember);
                    }    
                }
            }
            catch(Exception e){
                System.debug('Exception updateGCM.addressStateChange ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw e;
            }
        }
        else if(action == 'demographicChange'){
            try{
                for (Map<String,Object> member : censusMembers) {      
                    //CM Mapping
                    if (member.containsKey('Id') && member.get('Id') != null ){
                        String memberId = (String)member.get('Id');
                        if (!memberId.startsWith('MEM-') && !(boolean)member.get('IsNewMember') ) {
                            vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();               
                        
                            censusMember.Id = (Id)member.get('Id');
                            censusMember.vlocity_ins__MemberIdentifier__c = member.containsKey('vlocity_ins__MemberIdentifier__c') ? (String)member.get('vlocity_ins__MemberIdentifier__c') : null;
                            censusMember.ARC_Phone__c = member.containsKey('ARC_Phone__c') ? (String)member.get('ARC_Phone__c') : null;
                            censusMember.ARC_HeightFeet__c = member.containsKey('ARC_HeightFeet__c') ? String.valueOf(member.get('ARC_HeightFeet__c')) : null;
                            censusMember.ARC_HeightInches__c = member.containsKey('ARC_HeightInches__c') ? String.valueOf(member.get('ARC_HeightInches__c')) : null;
                            censusMember.ARC_PhysicalAddressCity__c = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                            censusMember.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? String.valueOf(member.get('ARC_PhysicalAddressState__c')).toUpperCase() : null;
                            censusMember.ARC_PhysicalAddressStreet__c = member.containsKey('ARC_PhysicalAddressStreet__c') ? (String)member.get('ARC_PhysicalAddressStreet__c') : null;
                            censusMember.ARC_PhysicalAddressZipCode__c = member.containsKey('ARC_PhysicalAddressZipCode__c') ? (String)member.get('ARC_PhysicalAddressZipCode__c') : null;
                            censusMember.ARC_Smoker__c = member.containsKey('ARC_Smoker__c') ?convertToBoolean(member.get('ARC_Smoker__c')) : null;
                            censusMember.ARC_isPregnant__c = member.containsKey('ARC_isPregnant__c') ?convertToBoolean(member.get('ARC_isPregnant__c')) : null;
                            censusMember.ARC_UseParentAddress__c = member.containsKey('CopyAddressFromPrimary') ? convertToBoolean(member.get('CopyAddressFromPrimary')) : null;
                            censusMember.ARC_Weight__c = member.containsKey('ARC_Weight__c') ? String.valueOf(member.get('ARC_Weight__c')) : null;
                            censusMember.vlocity_ins__Birthdate__c = (member.containsKey('vlocity_ins__Birthdate__c') && member.get('vlocity_ins__Birthdate__c') != null)? Date.valueOf((String)member.get('vlocity_ins__Birthdate__c')) : null;
                            censusMember.vlocity_ins__Email__c = member.containsKey('vlocity_ins__Email__c') ? (String)member.get('vlocity_ins__Email__c') : null;
                            censusMember.vlocity_ins__LastName__c = member.containsKey('vlocity_ins__LastName__c') ? (String)member.get('vlocity_ins__LastName__c') : null;
                            censusMember.vlocity_ins__FirstName__c = member.containsKey('vlocity_ins__FirstName__c') ? (String)member.get('vlocity_ins__FirstName__c') : null;
                            censusMember.vlocity_ins__Gender__c = member.containsKey('vlocity_ins__Gender__c') ? (String)member.get('vlocity_ins__Gender__c') : null;
                            censusMember.vlocity_ins__SocialSecurityNumber__c = member.containsKey('vlocity_ins__SocialSecurityNumber__c') ? (String)member.get('vlocity_ins__SocialSecurityNumber__c') : null;
                            
                            
                            if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Spouse'){
                                censusMember.vlocity_ins__IsSpouse__c = true;
                            }                        
                            censusMember.vlocity_ins__PrimaryMemberIdentifier__c = oldPrimaryValues.get('vlocity_ins__MemberIdentifier__c');
                            //Add to global list                       
                            manager.censusMembersDemographicChange.add(censusMember);
                            manager.ActionsSelected.add('demographicChange');
                        }                       
                    }                    
                }             
            }
            catch(Exception e){
                System.debug('Exception updateGCM.addMember ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw e;
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   upsertGuardian
    * @Description        :   insert or update a guardian
    ********************************************************************/
    private void upsertGuardian() {
        try {
            if (manager.guardiansToInsert.isEmpty()) {
                Map<String, Object> guardianInfo = (Map<String, Object>) manager.inputMap.get('STEP_GuardiansInfo');
                String GuardianPhysicalStreetApt = (String)manager.inputMap.get('GuardianPhysicalStreetApt');
                
                if (guardianInfo != null) {
                    Map<String, Object> ssnMap = (Map<String, Object>) guardianInfo.get('TXT_GuardianSSN');
                    Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_Guardian').getRecordTypeId();

                    Account newGuardian = new Account();
            
                    if (guardianInfo.containsKey('Id') && guardianInfo.get('Id') != null) {
                        newGuardian.Id = (Id)guardianInfo.get('Id');
                    }
                    
                    newGuardian.RecordTypeId = recordTypeId;
                    newGuardian.FirstName = (String)guardianInfo.get('TXT_GuardianFirstName');
                    newGuardian.LastName = (String)guardianInfo.get('TXT_GuardianLastName');
                    newGuardian.Phone = (String)guardianInfo.get('TXT_GuardianPhone');
                    newGuardian.PersonEmail = (String)guardianInfo.get('EMAIL_GuardianEmail');
                    newGuardian.PersonGender = (String)guardianInfo.get('SEL_GuardianGender');
                    newGuardian.PersonBirthdate = (Date)Date.valueOf((String)guardianInfo.get('DATE_GuardianBirthdate'));
                    newGuardian.ARC_SocialSecurityNumber__c = (String) ssnMap.get('response');
                    newGuardian.BillingStreet = GuardianPhysicalStreetApt;
                    Map<String, Object> addressBlock = (Map<String, Object>)guardianInfo.get('THEADBLK_GuardianAddress-Block');
                    if (addressBlock != null) {
                        newGuardian.BillingCity = (String)addressBlock.get('TXT_GuardianCity');
                        newGuardian.BillingPostalCode = (String)addressBlock.get('TXT_GuardianZipCode');
                        newGuardian.BillingState = String.valueOf(addressBlock.get('TXT_GuardianState')).toUpperCase();
                    } 
                    newGuardian.ARC_GuardianRelationshipToChild__c = (String)guardianInfo.get('SEL_GuardianRelationship');
                    
                    manager.guardiansToInsert.add(newGuardian);
                }
            }
        } catch (Exception e) {
            System.debug('Exception Guardian: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /*******************************************************************
    * @MethodName         :   insertCaseForFeedSkipped
    * @Description        :   create and insert a case if the fee was skipped
    ********************************************************************/
    private void insertCaseForFeedSkipped() {
        try {
            if (manager.inputMap.get('Step_PaymentChangeFee') != null) {
                Map<String, Object> paymentFee = (Map<String, Object>)manager.inputMap.get('Step_PaymentChangeFee');
                if ('No'.equals((String)paymentFee.get('RAD_ChargeAppFeeDefTrue'))) {
                    Case newCase = new Case();
        
                    Id queueId = [SELECT Id FROM Group WHERE DeveloperName = 'ProcessingQueue' LIMIT 1].Id;
                    Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
    
                    newCase.RecordTypeId = recordTypeId;
                    newCase.Case_Type__c = 'Program';
                    newCase.ARC_Reason__c = 'Change Fee Waived';
                    newCase.ARC_Type__c = 'Member';
                    newCase.Origin = 'System';
                    newCase.Subject = 'Program change fee waived';

                    // Get Primary Member 
                    for (Map<String,Object> member : manager.censusMembersInPcContract) {
                        if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false && member.containsKey('IsRemoveMember') && (Boolean)member.get('IsRemoveMember') == false &&  member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Primary') {
                            // Primary member is not a New Member then save the person account id
                            newCase.AccountId = (Id)member.get('PersonAccountId');
                            newCase.ARC_PersonAccount__c = (Id)member.get('PersonAccountId');
                        }
                        else if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == true && member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Primary') {
                            // Primary member is a New Member then save the Census Member Id and the case to charge in the DML
                            manager.FakeIdToCasePc.put((String)member.get('Id'), newCase);
                        }
                    }

                    Map<String, Object> caseDetails = (Map<String, Object>)paymentFee.get('BLK_CaseCreationDetails');
                    if (caseDetails != null) {
                        newCase.Description = (String)caseDetails.get('TXT_NoChargeChangeFeeReason');
                    }
                    
                    newCase.Status = 'New';
                    newCase.OwnerId = queueId;
                    
                    manager.casesPCToInsert.add(newCase);
                }
            }
        } catch (Exception e) {
            System.debug('Exception Case: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }        
    }

    /*******************************************************************
    * @MethodName         :   handlerUWCases
    * @Description        :   create the UW Case
    ********************************************************************/
    public void handlerUWCases() {
        try {
            Map<String, Object> pcChanges = (Map<String, Object>)manager.inputMap.get('pcChanges');
            List<Object> userInputs = (List<Object>)manager.inputMap.get('userInputs');
            Map<String, Object> pcReasonsObj = (Map<String, Object>)pcChanges.get('pcReasons');

            if ((Boolean)pcChanges.get('createNewContract') == true) {
                Case newCase = new Case();                
                Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admission').getRecordTypeId();

                Boolean addMember = pcReasonsObj.get('addMember') != null ? (Boolean)pcReasonsObj.get('addMember') : false;
                Boolean addExistingMember = pcReasonsObj.get('addExistingMember') != null ? (Boolean)pcReasonsObj.get('addExistingMember') : false;
                Boolean programUpgrade = pcReasonsObj.get('programUpgrade') != null ? (Boolean)pcReasonsObj.get('programUpgrade') : false;
                
                // Set case type based on program change reason
                if (addMember || addExistingMember || programUpgrade) {
                    newCase.ARC_Reason__c = 'Underwriting';
                    newCase.Case_Type__c = 'Underwriting';
                    newCase.Subject = newCase.Description = 'Underwriting';
                }
                else {
                    newCase.ARC_Reason__c = 'PC Approval';
                    newCase.Case_Type__c = 'PC Approval';
                    newCase.Subject = newCase.Description = 'PC Approval';
                }

                newCase.RecordTypeId = recordTypeId;
                newCase.Origin = 'Internal Enrollment';
                newCase.Type = 'Program Change';
                newCase.Status = 'Draft';
                newCase.OwnerId = (Id)manager.inputMap.get('userId');
                
                Map<String, Object> selectedContractInfo = (Map<String, Object>)manager.inputMap.get('selectedContractInfo');
                if(selectedContractInfo != null) {
                    newCase.AccountId = (String)selectedContractInfo.get('GroupAccountId');
                }
                manager.casesUWToInsert.add(newCase);
            }
    
        } catch (Exception e) {
            System.debug('Exception handler UW Case: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }	
    }

    /*******************************************************************
    * @MethodName         :   handlerUWCases
    * @Description        :   create the UW Case Members
    ********************************************************************/
    public void handlerUWCaseMembers() {
        try {
            Map<String, Object> pcChanges = (Map<String, Object>)manager.inputMap.get('pcChanges');
            Map<String, Object> pcReasons = (Map<String, Object>)pcChanges.get('pcReasons');
            Boolean programUpgrade = pcReasons.get('programUpgrade') != null ? (Boolean)pcReasons.get('programUpgrade') : false;

            Map<String, Object> contractInfo = (Map<String, Object>)manager.inputMap.get('SelectedContractInfo');
            Id contractId = (Id)((Map<String, Object>)manager.inputMap.get('SelectedContractInfo')).get('ContractID');
            String contractStatus = (String)contractInfo.get('TXT_ContractStatus');
            Boolean pendingMemberForReview = false;


            // Copy existing UW case members if applicable
            if (contractStatus == 'Awaiting Signature' || contractStatus == 'Awaiting Approval' || programUpgrade == true) {
                List<ARC_UnderwritingCaseMember__c> listUWCMToCopy = [SELECT ARC_ApprovalResolution__c, ARC_Member__c, ARC_PersonAccount__c, 
                    ARC_Reason__c, ARC_Score__c, Name, ARC_ReviewedBy__c, ARC_LastStatusUpdate__c, LastModifiedById, ARC_Description__c 
                    FROM ARC_UnderwritingCaseMember__c WHERE ARC_Contract__c =: contractId ];

                    //Add condition to not void previous UW Case if the case is already closed
                    List<Case> previousUWCase  = [SELECT Id, Status, (SELECT Id,ActivityDate,Priority, Status, Subject,Description, OwnerId, RecordTypeId  FROM Tasks WHERE isClosed = false) FROM Case WHERE ARC_Contract__c =: contractId AND RecordType.Name =: 'Underwriting' AND IsClosed = false];
                    if(!previousUWCase.isEmpty()){
                        previousUWCase[0].Status = 'Closed Voided';
                        manager.casesUWToInsert.add(previousUWCase[0]);

                        for(Task t:previousUWCase[0].Tasks){
                            manager.tasksToInsert.add(
                                new Task(
                                    ActivityDate = t.ActivityDate,
                                    Status = t.Status,
                                    Subject = t.Subject,
                                    Description = t.Description,
                                    OwnerId = t.OwnerId,
                                    Priority = t.Priority,
                                    RecordTypeId = t.RecordTypeId
                                )
                            );
                            t.Status = 'Completed';
                            manager.tasksToUpdate.add(t);
                            
                        }
                    }

                for (ARC_UnderwritingCaseMember__c UWCM : listUWCMToCopy) {
                    for (Map<String,Object> member : manager.censusMembersInPcContract) {
                        if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false 
                            && member.containsKey('Id') && (Id)member.get('Id') == UWCM.ARC_Member__c && member.containsKey('IsRemoveMember') && (Boolean)member.get('IsRemoveMember') == false) { 
                            try {
                                pendingMemberForReview = true;
                                ARC_UnderwritingCaseMember__c newCaseMember = new ARC_UnderwritingCaseMember__c();
                                newCasemember.Name = UWCM.Name;
                                newCasemember.ARC_Member__c = UWCM.ARC_Member__c;
                                newCasemember.ARC_PersonAccount__c = UWCM.ARC_PersonAccount__c;
                                newCasemember.ARC_Reason__c = UWCM.ARC_Reason__c;
                                newCasemember.ARC_ApprovalResolution__c = 'Pending';

                                // Copy approval details if within 60 days
                                if (UWCM.ARC_LastStatusUpdate__c != null && UWCM.ARC_LastStatusUpdate__c.date().daysBetween(Date.today()) <= 60 ) {
                                    newCasemember.ARC_ApprovalResolution__c =  UWCM.ARC_ApprovalResolution__c;
                                    newCasemember.ARC_Score__c = UWCM.ARC_Score__c;
                                    newCasemember.ARC_ReviewedBy__c = UWCM.ARC_ReviewedBy__c;
                                    newCasemember.ARC_Description__c =  UWCM.ARC_Description__c;
                                }
                                manager.casesUWToInsert[0].ARC_Reason__c = 'Underwriting';
                                manager.censusMemberIdOrFakeIdToUWCM.put(newCaseMember.ARC_Member__c, newCaseMember);
                                     
                            } catch (Exception e) {
                                System.debug('Exception when trying to clone previous UWM Cases ' + e.getMessage() + ' ' + e.getStackTraceString());
                                throw e;
                            }
                        }
                    }
                }
            }

            // Process new member changes
            Boolean addMember = pcReasons.get('addMember') != null ? (Boolean)pcReasons.get('addMember') : false;
            Boolean addExistingMember = pcReasons.get('addExistingMember') != null ? (Boolean)pcReasons.get('addExistingMember') : false;
            Boolean removeMember = pcReasons.get('removeMember') != null ? (Boolean)pcReasons.get('removeMember') : false;
            
            if (addMember || addExistingMember || removeMember || programUpgrade) {
                for (Map<String, Object> cm : manager.censusMembersInPcContract) {
                    ARC_UnderwritingCaseMember__c newCaseMember;

                    if (manager.censusMemberIdOrFakeIdToUWCM.containsKey((String)cm.get('Id'))) {
                        newCaseMember = manager.censusMemberIdOrFakeIdToUWCM.get((String)cm.get('Id'));
                        if (newCaseMember.ARC_Reason__c == 'Add Member' && programUpgrade == false){
                            continue;
                        }
                    }
                    else{
                        newCaseMember = new ARC_UnderwritingCaseMember__c();
                        newCaseMember.ARC_ApprovalResolution__c = 'Pending';
                        newCasemember.Name = (String)cm.get('vlocity_ins__FirstName__c') + ' ' + (String)cm.get('vlocity_ins__LastName__c');
                        System.debug('creating UW of ' +  newCasemember.Name);
                    }
                    
                    try {
                        // Set case member details based on change type
                        if ((Boolean)cm.get('IsNewMember') == true) {
                            System.debug('debug UW 1');
                            newCaseMember.ARC_Reason__c = 'Add Member';
                            manager.censusMemberIdOrFakeIdToUWCM.put((String)cm.get('Id'), newCaseMember);
                        } else if ((Boolean)cm.get('IsInactiveMember') == true) {
                            System.debug('debug UW 2');
                            newCaseMember.ARC_Member__c = (Id)cm.get('Id');
                            newCaseMember.ARC_Reason__c = 'Add Member';
                            newCaseMember.ARC_PersonAccount__c = (Id)cm.get('PersonAccountId');
                            manager.censusMemberIdOrFakeIdToUWCM.put((String)cm.get('Id'), newCaseMember);
                        } else if ((Boolean)cm.get('IsRemoveMember') == true) {
                            System.debug('debug UW 3');
                            newCaseMember.ARC_Member__c = (Id)cm.get('Id');
                            newCaseMember.ARC_Reason__c = 'Remove Member';
                            newCaseMember.ARC_PersonAccount__c = (Id)cm.get('PersonAccountId');
                            manager.censusMemberIdOrFakeIdToUWCM.put((String)cm.get('Id'), newCaseMember);
                        } else if ((Boolean)cm.get('IsNewMember') == false && (Boolean)cm.get('IsRemoveMember') == false && programUpgrade == true) {
                            System.debug('debug UW 4');
                            newCaseMember.ARC_Member__c = (Id)cm.get('Id');
                            newCaseMember.ARC_Reason__c = 'Program Upgrade';
                            newCaseMember.ARC_PersonAccount__c = (Id)cm.get('PersonAccountId');
                            manager.censusMemberIdOrFakeIdToUWCM.put((String)cm.get('Id'), newCaseMember);
                        }
                    } catch (Exception e) {
                        System.debug('Exception creation of New UW Case Member' + e.getMessage() + ' ' + e.getStackTraceString());
                        throw e;
                    }	                  
                }
            }
            //Evaluate if the UW Case should be created in Draft or Closed Approved
            Boolean medicalPriceChanged = pcChanges.get('priceChanged') != null ? (Boolean)pcChanges.get('priceChanged') : true;
            // Boolean uwCaseNeedsEvaluation = false;
            // for (ARC_UnderwritingCaseMember__c UWCM : manager.censusMemberIdOrFakeIdToUWCM.values()) {
            //     System.debug('UWCM: ' + UWCM);
            //     if (UWCM.ARC_Reason__c != 'Remove Member') {
            //         uwCaseNeedsEvaluation = true;
            //     }
            // }
            //Close the UW Case
            if (!medicalPriceChanged && !pendingMemberForReview) {
                manager.casesUWToInsert[0].Status = 'Closed Approved';
            }
        } catch (Exception e) {
            System.debug('Exception handler UW Case Member: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }	     
    } 

    /*******************************************************************
    * @MethodName         :   mapContractsToCreate
    * @Description        :   map Contracts to create
    ********************************************************************/
    private void upsertContracts(String action) {
        if(action == 'Insert') {
            try{
                Map<String, Object> guardianInfo = (Map<String, Object>)manager.inputMap.get('STEP_GuardiansInfo');
                Contract newContract = new Contract();
                String oldEffectiveDateString;
                String paidThroughDate;
                String recurringOrderId;
                // Get selected contract info
                Map<String, Object> selectedContractInfo = (Map<String, Object>)manager.inputMap.get('SelectedContractInfo');
                String oldContractReasons = (String)selectedContractInfo.get('TXT_ContractReason');              
                if(selectedContractInfo != null) {                    
                    newContract.AccountId = (String)selectedContractInfo.get('GroupAccountId');
                    newContract.Account_Name_Text__c = (String)selectedContractInfo.get('GroupAccountName');    
                    oldEffectiveDateString = (String)selectedContractInfo.get('EffectiveDate');
                    paidThroughDate = (String)selectedContractInfo.get('PaidThroughDate');
                    recurringOrderId = (String)selectedContractInfo.get('RecurringOrderId');
                }
                Date oldEffectiveDate = (oldEffectiveDateString != null && oldEffectiveDateString != '')? Date.parse(oldEffectiveDateString):null;
                Date oldPaidThroughDate = (paidThroughDate != null && paidThroughDate != '')?Date.parse(paidThroughDate):null;

                // Get effective date
                Date effectiveDate;

                // REMOVE START
                // Map<String, Object> effectiveDateMap = (Map<String, Object>)manager.inputMap.get('STEP_EffectiveDate') !=null ? (Map<String, Object>)manager.inputMap.get('STEP_EffectiveDate') : new Map<String, Object>();
                // if(effectiveDateMap != null && effectiveDateMap.containsKey('aRC_DatePicker')){
                //     Map<String, Object> datePickerMap = (Map<String, Object>)effectiveDateMap.get('aRC_DatePicker');
                //     if(datePickerMap != null && datePickerMap.containsKey('DATE_SubscriberEffectiveDate')) {
                //         String dateStr = (String)datePickerMap.get('DATE_SubscriberEffectiveDate');
                //         if(String.isNotBlank(dateStr)) {
                //             try {
                //                 // Handle both MM/DD/YYYY and YYYY-MM-DD formats
                //                 if(dateStr.contains('-')) {
                //                     effectiveDate = Date.valueOf(dateStr);
                //                 } else {
                //                     effectiveDate = Date.parse(dateStr);
                //                 }
                //             } catch(Exception e) {
                //                 System.debug('Error parsing date: ' + dateStr + ' - ' + e.getMessage());
                //                 throw new AuraHandledException('Invalid date format: ' + dateStr);
                //             }
                //         }
                //     }
                // }
                // REMOVE END                
                if(effectiveDate == null && manager.inputMap.containsKey('EffectiveDate')) {
                    String dateStr = (String)manager.inputMap.get('EffectiveDate');
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
                }                
                else if(effectiveDate == null) {
                    throw new AuraHandledException('Effective date is required');
                }                
                newContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_IndividualAndFamily').getRecordTypeId();
                
                // Get PC changes
                Map<String, Object> pcChanges = (Map<String, Object>)manager.inputMap.get('pcChanges');
                if(pcChanges != null) {
                    String reasons = (String)pcChanges.get('pcReasonsString');
                    if (reasons != null && reasons.contains('Ancillary Change')) {
                        reasons = reasons.replace('Ancillary Change', 'Add Ancillary Product');
                    }
                    newContract.ARC_ContractReason__c = reasons;
                }
                 //RECALCULATE PTD && RECURRING CHARGE DAY
                 if( newContract.ARC_ContractReason__c != null &&
                 newContract.ARC_ContractReason__c.contains('Effective Date Change') && 
                 oldContractReasons.contains('New Application')){
                    Boolean isSameDay = oldEffectiveDate.day() == effectiveDate.day();
                    Boolean isFirstDay = effectiveDate.day() == 1;
                    if(oldPaidThroughDate != null ){
                        //CALCULATE PAID THROUGH DATE
                        Integer monthsBetweenEffectiveAndPTD = oldEffectiveDate.monthsBetween(oldPaidThroughDate);
                        Date resultDate;
                        if(!isSameDay){
                            resultDate =isFirstDay?
                                        lastDateOfMonth(effectiveDate.addMonths(monthsBetweenEffectiveAndPTD-1)):
                                        Date.newInstance(effectiveDate.year(),effectiveDate.month()+(monthsBetweenEffectiveAndPTD+1), 14);
                        }
                        else{
                            resultDate =isFirstDay?
                                        lastDateOfMonth(effectiveDate.addMonths(monthsBetweenEffectiveAndPTD)):
                                        Date.newInstance(effectiveDate.year(),effectiveDate.month()+monthsBetweenEffectiveAndPTD, 14);
                        }
                        newContract.ARC_PaidThroughDate__c = resultDate;
                        //Recalculate Payment Start Date
                        if(resultDate > Date.Today()){
                            if(isFirstDay){
                                manager.paymentStartDate = Date.newInstance(resultDate.year(),resultDate.month(),20);
                            }
                            else{
                                manager.paymentStartDate = Date.newInstance(resultDate.year(),resultDate.month(),05);
                            }
                        }
                    }
                }
             //ASSIGN PREVIOUS SELLING AGENT OR INACTIVE SALES AGENT
                Id oldAgentId = selectedContractInfo.get('SellingAgentId')!= null? (Id)selectedContractInfo.get('SellingAgentId'):null;
                if(oldAgentId != null){
                    List<User> agentUsers = [SELECT Id, Name FROM User WHERE (Id =:oldAgentId OR Name = 'Inactive Sales Agent') AND IsActive = true];
                    Id integrationUserId;
                    Boolean oldAgentIdActive = false;
                    for(User agent: agentUsers){
                        if(agent.Id == oldAgentId) oldAgentIdActive = true;
                        else integrationUserId = agent.Id;
                    }
                    newContract.ARC_Selling_Agent__c = oldAgentIdActive == true?oldAgentId:integrationUserId;
                }
                
                if(guardianInfo != null && guardianInfo.containsKey('Id')) {
                    newContract.ARC_Guardian__c = (Id)guardianInfo.get('Id');
                }
                
                newContract.ARC_EffectiveDate__c = effectiveDate;
                manager.newChargeDate = effectiveDate.day() == 15? '05':'20';
                newContract.Status = 'Draft';
                newContract.vlocity_ins__EnrollmentCensusId__c = (Id)manager.inputMap.get('CensusId');
                
                if(selectedContractInfo != null && selectedContractInfo.containsKey('ContractID')) {
                    newContract.vlocity_ins__ExpiredContractId__c = (Id)selectedContractInfo.get('ContractID');
                } 
                
                newContract.StartDate = effectiveDate;
                newContract.ContractTerm = 12;

                vlocity_ins__GroupCensusMember__c primary = manager.primaryCensusMemberWithId;

                List<ARC_Available_States__mdt> availableStates = [SELECT id, allStatesAbbreviation__c, Abbreviation__c, DeveloperName FROM ARC_Available_States__mdt WHERE allStatesAbbreviation__c = null AND Abbreviation__c =:primary.ARC_PhysicalAddressState__c];

                String fullSate = availableStates.size() > 0 ? availableStates[0].DeveloperName : null;
                newContract.ARC_PrimaryAddress__Street__s = primary.ARC_PhysicalAddressStreet__c;
                newContract.ARC_PrimaryAddress__City__s = primary.ARC_PhysicalAddressCity__c;
                newContract.ARC_PrimaryAddress__StateCode__s = primary.ARC_PhysicalAddressState__c;
                newContract.ARC_PrimaryAddress__PostalCode__s = primary.ARC_PhysicalAddressZipCode__c;
                newContract.ARC_PrimaryAddress__CountryCode__s = 'US';

                Map<String, Object> changeSelect = (Map<String, Object>)manager.inputMap.get('STEP_ChangeSelect');
                if(changeSelect != null){
                    if(changeSelect.containsKey('SEL_ReasonsForChange')){
                        String changeSelectValue = (String)changeSelect.get('SEL_ReasonsForChange');
                        if(changeSelectValue != null ){
                            newContract.ARC_ContractSubReason__c = changeSelectValue;
                        }
                    }
                    if(changeSelect.containsKey('TXT_OtherReason')){
                        String otherReason = (String)changeSelect.get('TXT_OtherReason');
                        if(otherReason != null){
                            newContract.ARC_ContractOtherSubReason__c = otherReason;
                        }
                    }
                }
                
                
                manager.contractsToInsert.add(newContract);                
            }
            catch(Exception e){
                System.debug('Exception mapContractsToCreate.Insert ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw e;
            }
        }
        else if(action == 'Update') {
            try{
                Map<String, Object> SelectedContractInfo = (Map<String, Object>)manager.inputMap.get('SelectedContractInfo');
                String oldEffectiveDateString = (String)SelectedContractInfo.get('EffectiveDate');
                String paidThroughDate = (String)SelectedContractInfo.get('PaidThroughDate');
                String recurringOrderId = (String)SelectedContractInfo.get('RecurringOrderId');
                if(recurringOrderId == '') recurringOrderId = null;
                Date oldEffectiveDate = Date.parse(oldEffectiveDateString);
                Date oldPaidThroughDate = (paidThroughDate != null && paidThroughDate != '')?Date.parse(paidThroughDate):null;
                Date effectiveDate;
                // REMOVE START
                // Map<String, Object> effectiveDateMap = (Map<String, Object>)manager.inputMap.get('STEP_EffectiveDate') !=null ? (Map<String, Object>)manager.inputMap.get('STEP_EffectiveDate') : new Map<String, Object>();
                // if(effectiveDateMap != null && effectiveDateMap.containsKey('aRC_DatePicker')){
                //     Map<String, Object> datePickerMap = (Map<String, Object>)effectiveDateMap.get('aRC_DatePicker');
                //     if(datePickerMap != null && datePickerMap.containsKey('DATE_SubscriberEffectiveDate')) {
                //         String dateStr = (String)datePickerMap.get('DATE_SubscriberEffectiveDate');
                //         if(String.isNotBlank(dateStr)) {
                //             try {
                //                 // Handle both MM/DD/YYYY and YYYY-MM-DD formats
                //                 if(dateStr.contains('-')) {
                //                     effectiveDate = Date.valueOf(dateStr);
                //                 } else {
                //                     effectiveDate = Date.parse(dateStr);
                //                 }
                //             } catch(Exception e) {
                //                 System.debug('Error parsing date: ' + dateStr + ' - ' + e.getMessage());
                //                 throw new AuraHandledException('Invalid date format: ' + dateStr);
                //             }
                //         }
                //     }
                // }
                // REMOVE END                
                if(effectiveDate == null && manager.inputMap.containsKey('EffectiveDate')) {
                    String dateStr = (String)manager.inputMap.get('EffectiveDate');
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
                }         
                Contract contractToUpdate = new Contract();
                contractToUpdate.Id = (Id)SelectedContractInfo.get('ContractID');
                contractToUpdate.ARC_EffectiveDate__c = effectiveDate;
                //RECALCULATE PTD AND RECURRING CHARGE DAY
                if (effectiveDate != null && oldEffectiveDate != null && effectiveDate != oldEffectiveDate) {
                    Boolean isSameDay = oldEffectiveDate.day() == effectiveDate.day();
                    Boolean isFirstDay = effectiveDate.day() == 1;
                    if(oldPaidThroughDate != null ){
                        //UPDATE PAID THROUGH DATE
                        Integer monthsBetweenEffectiveAndPTD = oldEffectiveDate.monthsBetween(oldPaidThroughDate);
                        Date resultDate;
                        if(!isSameDay){
                            resultDate =isFirstDay?
                                        lastDateOfMonth(effectiveDate.addMonths(monthsBetweenEffectiveAndPTD-1)):
                                        Date.newInstance(effectiveDate.year(),effectiveDate.month()+(monthsBetweenEffectiveAndPTD+1), 14);
                        }
                        else{
                            resultDate =isFirstDay?
                                        lastDateOfMonth(effectiveDate.addMonths(monthsBetweenEffectiveAndPTD)):
                                        Date.newInstance(effectiveDate.year(),effectiveDate.month()+monthsBetweenEffectiveAndPTD, 14);
                        }
                        contractToUpdate.ARC_PaidThroughDate__c = resultDate;
                        // Recalculate Payment Start Date
                        if(resultDate > Date.Today()){
                            if(isFirstDay){
                                manager.paymentStartDate = Date.newInstance(resultDate.year(),resultDate.month(),20);
                            }
                            else{
                                manager.paymentStartDate = Date.newInstance(resultDate.year(),resultDate.month(),05);
                            }
                        }
                    }
                    //UPDATE CHARGE DATE ON CHARGENT ORDER IF EXIST
                    if(recurringOrderId != null && recurringOrderId != '' ){
                        if(!isSameDay || oldPaidThroughDate != null){
                            ChargentOrders__ChargentOrder__c recurring = new ChargentOrders__ChargentOrder__c();
                            recurring.Id = recurringOrderId;
                            recurring.ChargentOrders__Charge_Date__c = isFirstDay?'20':'05';
                            if(oldPaidThroughDate != null && manager.paymentStartDate != null){
                                recurring.ChargentOrders__Payment_Start_Date__c  = manager.paymentStartDate;
                            }
                            manager.chargentOrdersRecurringOrder.add(recurring);
                        }
                    }
                }
                manager.contractsToInsert.add(contractToUpdate);
            } 
            catch(Exception e){
                System.debug('Exception mapContractsToCreate.Update ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw e;
            }
        }
        if(action == 'oldContracts'){
            try{               
                
                if(manager.inputMap != null && manager.inputMap.containsKey('STEP_SelectContract') && (Integer)manager.inputMap.get('ContractCount') != 1){
                    Map<String, Object> oldContracts = (Map<String, Object>)manager.inputMap.get('STEP_SelectContract');
                    if(oldContracts != null && oldContracts.containsKey('EB_ContractList')){
                        List<Object> EB_ContractList = new List<Object>();
                        if (oldContracts.get('EB_ContractList') instanceof List<Object>) {
                            EB_ContractList = (List<Object>)oldContracts.get('EB_ContractList');
                        } else if (oldContracts.get('EB_ContractList') instanceof Map<String,Object>) {
                            EB_ContractList.add((Map<String,Object>)oldContracts.get('EB_ContractList'));
                        }
                        if(EB_ContractList != null){
                            for(Object oldContract : EB_ContractList){
                                Map<String, Object> oldContractMap = (Map<String, Object>)oldContract;
                                //Add more statuses to void  
                                if(oldContractMap != null && ((String)oldContractMap.get('TXT_ContractStatus')).contains('Awaiting') && !((String)oldContractMap.get('TXT_ContractStatus')).contains('Activated')){
                                    Contract oldContractToUpdate = new Contract();
                                    oldContractToUpdate.Id = (Id)oldContractMap.get('ContractID');
                                    oldContractToUpdate.Status = 'Voided';
                                    oldContractToUpdate.ARC_CancellationReason__c = 'Program Change';
                                    manager.contractsToUpdate.add(oldContractToUpdate);
                                }
                            }
                        }
                    } 
                }
                else if((Integer)manager.inputMap.get('ContractCount') == 1 ){
                    // Get selected contract info
                    Map<String, Object> selectedContractInfo = (Map<String, Object>)manager.inputMap.get('SelectedContractInfo');               
                    if(selectedContractInfo != null && ((String)selectedContractInfo.get('TXT_ContractStatus')).contains('Awaiting') && !((String)selectedContractInfo.get('TXT_ContractStatus')).contains('Activated')) {                    
                        Contract con = new Contract();
                        con.Id = (Id)selectedContractInfo.get('ContractID');
                        con.Status = 'Voided';
                        con.ARC_CancellationReason__c = 'Program Change';
                        manager.contractsToUpdate.add(con);
                    }
                }   
            }
            catch(Exception e){
                System.debug('Exception mapContractsToCreate.oldContracts ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw e;
            }
        }
    }   
    
    /*******************************************************************
    * @MethodName         :   mapContractLineItemsToCreate
    * @Description        :   map Contract Line Items to create
    ********************************************************************/   
    private void createContractLineItems(String action) {
        Map<String, Object> productToMembersMap = getProductsWithMembers();
        if(action == 'Insert' && productToMembersMap != null && !productToMembersMap.isEmpty()) {
            Integer index = 0;
            try{
                // Get the contract effective date
                //Map<String, Object> effectiveDateMap = (Map<String, Object>)manager.inputMap.get('STEP_EffectiveDate');
                //Map<String, Object> datePickerMap = (Map<String, Object>)effectiveDateMap.get('aRC_DatePicker');
                //Date contractEffectiveDate = Date.parse((String)manager.inputMap.get('EffectiveDate'));
                Date contractEffectiveDate;
                // REMOVE START
                // Map<String, Object> effectiveDateMap = (Map<String, Object>)manager.inputMap.get('STEP_EffectiveDate');
                // if(effectiveDateMap != null && effectiveDateMap.containsKey('aRC_DatePicker')){
                //     Map<String, Object> datePickerMap = (Map<String, Object>)effectiveDateMap.get('aRC_DatePicker');
                //     if(datePickerMap != null && datePickerMap.containsKey('DATE_SubscriberEffectiveDate')) {
                //         String dateStr = (String)datePickerMap.get('DATE_SubscriberEffectiveDate');
                //         if(String.isNotBlank(dateStr)) {
                //             try {
                //                 // Handle both MM/DD/YYYY and YYYY-MM-DD formats
                //                 if(dateStr.contains('-')) {
                //                     contractEffectiveDate = Date.valueOf(dateStr);
                //                 } else {
                //                     contractEffectiveDate = Date.parse(dateStr);
                //                 }
                //             } catch(Exception e) {
                //                 System.debug('Error parsing date: ' + dateStr + ' - ' + e.getMessage());
                //                 throw new AuraHandledException('Invalid date format: ' + dateStr);
                //             }
                //         }
                //     }
                // }
                // REMOVE END                
                if(contractEffectiveDate == null && manager.inputMap.containsKey('EffectiveDate')) {
                    String dateStr = (String)manager.inputMap.get('EffectiveDate');
                    if(String.isNotBlank(dateStr)) {
                        try {
                            // Handle both MM/DD/YYYY and YYYY-MM-DD formats
                            if(dateStr.contains('-')) {
                                contractEffectiveDate = Date.valueOf(dateStr);
                            } else {
                                contractEffectiveDate = Date.parse(dateStr);
                            }
                        } catch(Exception e) {
                            System.debug('Error parsing date: ' + dateStr + ' - ' + e.getMessage());
                            throw new AuraHandledException('Invalid date format: ' + dateStr);
                        }
                    }
                }
                
                if(contractEffectiveDate == null) {
                    throw new AuraHandledException('Effective date is required');
                }
                
                // Get account ID
                Map<String, Object> selectedContractInfo = (Map<String, Object>)manager.inputMap.get('SelectedContractInfo');
                String accountId = selectedContractInfo != null ? (String)selectedContractInfo.get('GroupAccountId') : null;
                
                
                Map<String, Object> medicalWithMembers = (Map<String, Object>)productToMembersMap.get('Medical');
                if(medicalWithMembers != null) {
                    Map<String, Object> medicalProduct = (Map<String, Object>)medicalWithMembers.get('product');
                    List<Object> medicalMembers = (List<Object>)medicalWithMembers.get('members');
                    
                    vlocity_ins__ContractLineItem__c medicalLineItem = new vlocity_ins__ContractLineItem__c();
                    //////// Process Medical Product
                    try {
                        
                        medicalLineItem.vlocity_ins__AccountId__c = accountId;
                        medicalLineItem.Name = (String)medicalProduct.get('Name');
                        medicalLineItem.vlocity_ins__Product2Id__c = (Id)medicalProduct.get('Id');
                        medicalLineItem.vlocity_ins__UnitPrice__c = (Decimal)medicalProduct.get('Price');
                        medicalLineItem.vlocity_ins__Quantity__c = 1;                       
                        medicalLineItem.vlocity_ins__EffectiveStartDate__c = DateTime.newInstance(contractEffectiveDate, Time.newInstance(0, 0, 0, 0)).addDays(1);                      
                        
                        manager.contractLineItemsToInsert.add(medicalLineItem);
                        manager.indexToParentCLI.put(index,medicalLineItem);
                        
                        //manager.ParentToChildCLI.put(medicalLineItem,new List<vlocity_ins__ContractLineItem__c>());
                        for(Object member : medicalMembers){
                            Map<String,Object> memberMap = (Map<String,Object>)member;
                            if(memberMap.containsKey('CensusMemberId')){
                                if(!manager.indexToCLIGCM.containsKey(index)){
                                    manager.indexToCLIGCM.put(index,new List<String>{(String)memberMap.get('CensusMemberId')});
                                }
                                else{
                                    manager.indexToCLIGCM.get(index).add((String)memberMap.get('CensusMemberId'));
                                }
                            }
                        }
                    }
                    catch(Exception e){
                        System.debug('Exception mapContractLineItemsToCreate medicalLineItem ' + e.getMessage() + ' ' + e.getStackTraceString());
                        throw e;
                    }

                    //////// Process Medical Child Products
                    try {                        
                        List<Map<String, Object>> medicalChildProducts = (List<Map<String, Object>>)productToMembersMap.get('MedicalChildProducts');

                        if(medicalChildProducts != null && !medicalChildProducts.isEmpty()) {
                            for(Map<String, Object> medicalChildProduct : medicalChildProducts) {
                                Map<String, Object> childProduct = (Map<String, Object>)medicalChildProduct.get('product');
                                
                                vlocity_ins__ContractLineItem__c medicalChildLineItem = new vlocity_ins__ContractLineItem__c();
                                medicalChildLineItem.Name = (String)childProduct.get('Name');
                                medicalChildLineItem.vlocity_ins__Product2Id__c = (Id)childProduct.get('Id');
                                medicalChildLineItem.vlocity_ins__ProductChildItemId__c = (Id)childProduct.get('pciId');
                                medicalChildLineItem.vlocity_ins__AccountId__c = accountId;
                                medicalChildLineItem.vlocity_ins__ProductId__c = (Id)medicalProduct.get('Id');
                                
                                manager.contractLineItemsToInsert.add(medicalChildLineItem);
                                if(!manager.indexToChildCLI.containsKey(index)){
                                    manager.indexToChildCLI.put(index,new List<vlocity_ins__ContractLineItem__c>{medicalChildLineItem});
                                }
                                else{
                                    manager.indexToChildCLI.get(index).add(medicalChildLineItem);
                                }
                            }
                        }
                    }
                    catch(Exception e){
                        System.debug('Exception mapContractLineItemsToCreate medicalChildLineItem ' + e.getMessage() + ' ' + e.getStackTraceString());
                        throw e;
                    }
                }

                // Process Ancillary Products
                try {
                    List<Map<String, Object>> ancillaryProducts = (List<Map<String, Object>>)productToMembersMap.get('Ancillaries');
                    if(ancillaryProducts != null && !ancillaryProducts.isEmpty()) {
                        for(Map<String, Object> ancillaryProduct : ancillaryProducts) {
                            index++;
                            Map<String, Object> product = (Map<String, Object>)ancillaryProduct.get('product');
                            List<Object> ancilaryMembers = (List<Object>)ancillaryProduct.get('members');
                           
                            
                            vlocity_ins__ContractLineItem__c ancillaryLineItem = new vlocity_ins__ContractLineItem__c();
                            ancillaryLineItem.Name = (String)product.get('Name');
                            ancillaryLineItem.vlocity_ins__Product2Id__c = (Id)product.get('Id');
                            ancillaryLineItem.vlocity_ins__AccountId__c = accountId;
                            ancillaryLineItem.vlocity_ins__EffectiveStartDate__c = DateTime.newInstance(contractEffectiveDate, Time.newInstance(0, 0, 0, 0)).addDays(1);
                            ancillaryLineItem.vlocity_ins__Quantity__c = 1;
                            ancillaryLineItem.vlocity_ins__UnitPrice__c = (Decimal)product.get('Price');
                            manager.contractLineItemsToInsert.add(ancillaryLineItem);
                            manager.indexToParentCLI.put(index,ancillaryLineItem);

                            for(Object member : ancilaryMembers){
                                Map<String,Object> memberMap = (Map<String,Object>)member;                                
                                if(memberMap.containsKey('CensusMemberId')){
                                    if(!manager.indexToCLIGCM.containsKey(index)){
                                        manager.indexToCLIGCM.put(index,new List<String>{(String)memberMap.get('CensusMemberId')});
                                    }
                                    else{
                                        manager.indexToCLIGCM.get(index).add((String)memberMap.get('CensusMemberId'));
                                    }
                                }
                                else{
                                    List<vlocity_ins__ContractLineItem__c> ancillaryLineItems = new List<vlocity_ins__ContractLineItem__c>();
                                    ancillaryLineItems.add(ancillaryLineItem);
                                    manager.CMIdToCLI.put((String)memberMap.get('CensusMemberId'),ancillaryLineItems);
                                }
                            }
                            /////// Process Ancillary Child Products
                            if(ancillaryProduct.containsKey('childProducts')){
                                List<Map<String,Object>> childProducts = (List<Map<String,Object>>)ancillaryProduct.get('childProducts');
                                for(Map<String, Object> childProduct : childProducts) {                 
   
                                    if(childProduct.containsKey('RecordTypeName__c') && (String)childProduct.get('RecordTypeName__c') == 'CoverageSpec'  ){

                                        vlocity_ins__ContractLineItem__c ancillaryChildLineItem = new vlocity_ins__ContractLineItem__c();
                                        ancillaryChildLineItem.Name = (String)childProduct.get('Name');
                                        ancillaryChildLineItem.vlocity_ins__Product2Id__c = (Id)childProduct.get('Id');
                                        ancillaryChildLineItem.vlocity_ins__AccountId__c = accountId;
                                        ancillaryChildLineItem.vlocity_ins__ProductId__c = (Id)childProduct.get('Id');
                                        if(!manager.indexToChildCLI.containsKey(index)){
                                            manager.indexToChildCLI.put(index,new List<vlocity_ins__ContractLineItem__c>{ancillaryChildLineItem});
                                        }
                                        else{
                                            manager.indexToChildCLI.get(index).add(ancillaryChildLineItem); 
                                        }
                                    }                                                   
                                }
                            }                                                      
                        }
                    }
                }
                catch(Exception e){
                    System.debug('Exception mapContractLineItemsToCreate ancillaryLineItem ' + e.getMessage() + ' ' + e.getStackTraceString());
                    throw e;
                }              
            }
            catch(Exception e){
                System.debug('Exception mapContractLineItemsToCreate ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw e;
            }
        }        
    }

    /*******************************************************************
    * @MethodName         :   upsertMedicalQuesitons
    * @Description        :   insert new Medical Quesionts and update (inactive) old Medical Quesions for related members
    ********************************************************************/
    private void upsertMedicalQuesitons() {
        try {
            if((Map<String, Object>)manager.inputMap.get('STEP_MedicalQuestions') != null){

                Map<String, Object> stepMedicalQuestions = (Map<String, Object>)manager.inputMap.get('STEP_MedicalQuestions');
                Map<String, Object> pcChanges = (Map<String, Object>)manager.inputMap.get('pcChanges');

                Map<String, Object> reasons = (Map<String, Object>) pcChanges.get('pcReasons'); // Catch Program Change Reasons 
                Boolean haveAddMember = (Boolean) reasons.get('addMember');
                Boolean haveProgramUpgrade = (Boolean) reasons.get('programUpgrade');
                Boolean haveExistingMember = (Boolean) reasons.get('addExistingMember');

                Boolean isCarryOver = pcChanges.containsKey('carryOverMedicalQuestions') ? (Boolean) pcChanges.get('carryOverMedicalQuestions') : false;

                Map<String, Map<String, Object>> oldMembers = new Map<String, Map<String, Object>>();
                Set<Id> oldMembersIds = new Set<Id>();

                if (manager.censusMembersInPcContract != null) {
                    for (Map<String, Object> member : manager.censusMembersInPcContract) {
                        Boolean isRemoveMember = (Boolean) member.get('IsRemoveMember');
                        Boolean isNewMember = (Boolean) member.get('IsNewMember');
                        Boolean isInactiveMember = member.containsKey('IsInactiveMember') ? (Boolean) member.get('IsInactiveMember') : false;

                        String censusId = (String) member.get('Id');
                        String accountId = (String) member.get('PersonAccountId');

                        if (isNewMember == false && isRemoveMember == false) {
                            Map<String, Object> memberInfo = new Map<String, Object>();
                            memberInfo.put('censusId', censusId);
                            memberInfo.put('accountId', accountId); 
                
                            oldMembers.put(censusId, memberInfo);

                            Boolean processMember = false;

                            if((haveProgramUpgrade && !haveExistingMember && !isInactiveMember) ||
                                (!haveProgramUpgrade && haveExistingMember && isInactiveMember) ||
                                (haveProgramUpgrade && haveExistingMember) ||
                                (isCarryOver) ) {
                                processMember = true;
                            }

                            if (processMember) {
                                oldMembersIds.add((Id)member.get('Id'));
                            }

                            // system.debug('censusId ' + censusId + ' - accountId ' +accountId + ' - isRemoveMember ' + isRemoveMember + ' - isNewMember ' +isNewMember + ' - isInactiveMember ' + isInactiveMember);
                        }
                    }
                }
                                
                // We need to retrieve active medical questions (ARC_MedicalConditions__c and vlocity_ins__ConsumerDrug__c) for old members to deactivate before we insert new ones if programupgrade is true
                if((haveProgramUpgrade || haveExistingMember) && !oldMembersIds.isEmpty()){
                    List<ARC_MedicalConditions__c> medicalConditionsToDeactivate = [SELECT Id, ARC_Active__c FROM  ARC_MedicalConditions__c WHERE ARC_Active__c = true AND ARC_CensusMember__c IN :oldMembersIds];
                    List<vlocity_ins__ConsumerDrug__c> consumerDrugToDeactivate = [SELECT Id, ARC_Active__c, vlocity_ins__IsActive__c, vlocity_ins__StopReason__c, vlocity_ins__MedicationEndDate__c  FROM  vlocity_ins__ConsumerDrug__c WHERE ARC_Active__c = true AND ARC_CensusMember__c IN :oldMembersIds];
                    
                    if (!medicalConditionsToDeactivate.isEmpty()) {
                        for (ARC_MedicalConditions__c mc : medicalConditionsToDeactivate) {
                            mc.ARC_Active__c = false;
                            manager.medicalConditionsToUpsert.add(mc);
                        }
                    }

                    if (!consumerDrugToDeactivate.isEmpty()) {
                        for (vlocity_ins__ConsumerDrug__c cd : consumerDrugToDeactivate) {
                            cd.ARC_Active__c = false;
                            cd.vlocity_ins__IsActive__c = false;
                            cd.vlocity_ins__StopReason__c = 'Duplicate';
                            cd.vlocity_ins__MedicationEndDate__c = null;
                            manager.consumerDrugsToUpsert.add(cd);
                        }
                    }
                }


                Map<String, ARC_MedicalConditions__c> singleRecordBlocksMap = new Map<String, ARC_MedicalConditions__c>(); // For Questions Group 1
                Map<String, List<ARC_MedicalConditions__c>> cancerMap = new Map<String, List<ARC_MedicalConditions__c>>(); // For Questions Group 2
                Map<String, List<vlocity_ins__ConsumerDrug__c>> prescriptionsMap = new Map<String, List<vlocity_ins__ConsumerDrug__c>>(); // For Questions Group 3
   
                // Process Group 1 - Question 1, 2, 3, 5, 6 and 7
                // Question 1
                List<Object> parentSiblingDiagnosedListToProcess = convertObjectToList(stepMedicalQuestions.get('BLK_ParentSiblingDiagnosed'));
                if(parentSiblingDiagnosedListToProcess != null) processMedicalQuestionsFirstGroup(singleRecordBlocksMap, parentSiblingDiagnosedListToProcess, 'BLK_ParentSiblingDiagnosed');
                // Question 2
                List<Object> unexpectedSymptomsListToProcess = convertObjectToList(stepMedicalQuestions.get('BLK_UnexpectedSymptoms'));
                if(unexpectedSymptomsListToProcess != null) processMedicalQuestionsFirstGroup(singleRecordBlocksMap, unexpectedSymptomsListToProcess, 'BLK_UnexpectedSymptoms');
                // Question 3
                List<Object> pendingTestsListToProcess = convertObjectToList(stepMedicalQuestions.get('BLK_PendingTests'));
                if(pendingTestsListToProcess != null) processMedicalQuestionsFirstGroup(singleRecordBlocksMap, pendingTestsListToProcess, 'BLK_PendingTests');
                // Question 5
                List<Object> addictionsListToProcess = convertObjectToList(stepMedicalQuestions.get('BLK_Addictions'));
                if(addictionsListToProcess != null) processMedicalQuestionsFirstGroup(singleRecordBlocksMap, addictionsListToProcess, 'BLK_Addictions');
                // Question 6
                List<Object> licenceSuspendedListToProcess = convertObjectToList(stepMedicalQuestions.get('BLK_LicenceSuspended'));
                if(licenceSuspendedListToProcess != null) processMedicalQuestionsFirstGroup(singleRecordBlocksMap, licenceSuspendedListToProcess, 'BLK_LicenceSuspended');
                // Question 7
                List<Object> pastConditionsListToProcess = convertObjectToList(stepMedicalQuestions.get('EB_PastConditions'));
                if(pastConditionsListToProcess != null)  processMedicalQuestionsFirstGroup(singleRecordBlocksMap, pastConditionsListToProcess, 'EB_PastConditions');
                
            
                // Proccess singleRecordBlocksMap only for oldMembers, new members we will procees them on DML to get real ids
                if (singleRecordBlocksMap != null) {
                    for (String memberId : singleRecordBlocksMap.keySet()) {
                        ARC_MedicalConditions__c mc = singleRecordBlocksMap.get(memberId);
                        if (!memberId.startsWith('MEM-')) {
                            mc.ARC_CensusMember__c = oldMembers != null && oldMembers.containsKey(memberId) ? (Id)oldMembers.get(memberId).get('censusId') : null;
                            mc.ARC_PersonAccount__c = oldMembers != null && oldMembers.containsKey(memberId) ? (Id)oldMembers.get(memberId).get('accountId') : null;
                            manager.medicalConditionsToUpsert.add(mc);
                        } else {
                            if (!manager.newMembersMapMedicalConditionsToInsert.containsKey(memberId)) {
                                manager.newMembersMapMedicalConditionsToInsert.put(memberId, new List<ARC_MedicalConditions__c>());
                            }
                            manager.newMembersMapMedicalConditionsToInsert.get(memberId).add(mc);
                        }
                    }
                }

                // Process Group 2 (EB_Cancer) - Question 4
                List<Object> cancerListToProcess = convertObjectToList(stepMedicalQuestions.get('EB_Cancer'));
 
                if (cancerListToProcess != null) {
                    
                    for (Object recordObj : cancerListToProcess) {
                        if (recordObj != null) {
                            Map<String, Object> recordMap = (Map<String, Object>)recordObj;
    
                            String memberId = (String)recordMap.get('TXT_MemberIdCancer');
                            ARC_MedicalConditions__c mcC = new ARC_MedicalConditions__c();
                            String memberNameForMedical = (String)recordMap.get('TXT_MemberNameCancer');
                            if(memberNameForMedical.length()>60){
                                mcC.Name = memberNameForMedical.substring(0,60) + '-Medical Condition';
                            }
                            else mcC.Name = memberNameForMedical+'-Medical Condition';
                            mcC.ARC_Currently_Under_Treatment__c = (Boolean)recordMap.get('CHK_CheckCancer');
                            mcC.ARC_Type_Of_Cancer__c =(String)recordMap.get('TXT_TypeOfCancer');
                            mcC.ARC_Year_Diagnosed_Cancer__c = (String)recordMap.get('DATE_Cancer') != null ? Date.valueOf((String)recordMap.get('DATE_Cancer')) : null;
                            mcC.ARC_Active__c = true;
                        
                            if (!cancerMap.containsKey(memberId)) {
                                cancerMap.put(memberId, new List<ARC_MedicalConditions__c>());
                            }
                            cancerMap.get(memberId).add(mcC);
                        }
                    }
                }

                // Proccess cancerMap only for oldMembers, new members we will procees them on DML to get real ids
                if(cancerMap != null){
                    for (String memberId : cancerMap.keySet()) {
                        List<ARC_MedicalConditions__c> medicalConditionsList = cancerMap.get(memberId);
                        for (ARC_MedicalConditions__c mc : medicalConditionsList) {
                            if (!memberId.startsWith('MEM-')) {
                                mc.ARC_CensusMember__c = oldMembers != null && oldMembers.containsKey(memberId) ? (Id)oldMembers.get(memberId).get('censusId') : null;
                                mc.ARC_PersonAccount__c = oldMembers != null && oldMembers.containsKey(memberId) ? (Id)oldMembers.get(memberId).get('accountId') : null;

                                manager.medicalConditionsToUpsert.add(mc); 
                            } else {
                                if (!manager.newMembersMapMedicalConditionsToInsert.containsKey(memberId)) {
                                    manager.newMembersMapMedicalConditionsToInsert.put(memberId, new List<ARC_MedicalConditions__c>());
                                }
                                manager.newMembersMapMedicalConditionsToInsert.get(memberId).add(mc);
                            }
                        }
                    }
                }
                

                // Process Group 3 (ED_MemberPrescription) - Question 8
                List<Object> memberPrescriptionListToProcess = convertObjectToList(stepMedicalQuestions.get('ED_MemberPrescription'));
 
                if (memberPrescriptionListToProcess != null) {
                    
                    for (Object recordObj : memberPrescriptionListToProcess) {
                        if (recordObj != null) {
                            Map<String, Object> recordMap = (Map<String, Object>)recordObj;
    
                            String memberId = (String)recordMap.get('TXT_MemberIdPrescription');
                            vlocity_ins__ConsumerDrug__c  cd = new vlocity_ins__ConsumerDrug__c ();

                            cd.Name = (String)recordMap.get('TXT_NameOfMedication');
                            cd.vlocity_ins__PrescribedBy__c = (String)recordMap.get('TXT_PrescribingPhysician');
                            cd.vlocity_ins__MedicationStartDate__c = (String)recordMap.get('TXT_DatePrescribed') != null ? Date.valueOf((String)recordMap.get('TXT_DatePrescribed')) : null;
                            cd.vlocity_ins__MedicationEndDate__c = (String)recordMap.get('TXT_DateDiscontinued') != null ? Date.valueOf((String)recordMap.get('TXT_DateDiscontinued')) : null;
                            cd.ARC_Reason__c = (String)recordMap.get('TXT_ReasonForMedication');
                            // Medication can't be active if end date is in the past
                            if(cd.vlocity_ins__MedicationEndDate__c != null &&  cd.vlocity_ins__MedicationEndDate__c <= Date.today()){
                                cd.ARC_Active__c = false;
                                cd.vlocity_ins__IsActive__c = false;
                            } else {
                                cd.ARC_Active__c = true;
                                cd.vlocity_ins__IsActive__c = true;
                            }

                            if (!prescriptionsMap.containsKey(memberId)) {
                                prescriptionsMap.put(memberId, new List<vlocity_ins__ConsumerDrug__c>());
                            }
                            prescriptionsMap.get(memberId).add(cd);
                        }
                    }
                }

                // Proccess prescriptionsMap only for oldMembers, new members we will procees them on DML to get real ids
                if(prescriptionsMap != null){
                    for (String memberId : prescriptionsMap.keySet()) {
                        List<vlocity_ins__ConsumerDrug__c> medicalConditionsList = prescriptionsMap.get(memberId);
                        for (vlocity_ins__ConsumerDrug__c mc : medicalConditionsList) {
                            if (!memberId.startsWith('MEM-')) {
                                mc.ARC_CensusMember__c = oldMembers != null && oldMembers.containsKey(memberId) ? (Id)oldMembers.get(memberId).get('censusId') : null;
                                mc.ARC_PersonAccount__c = oldMembers != null && oldMembers.containsKey(memberId) ? (Id)oldMembers.get(memberId).get('accountId') : null;

                                manager.consumerDrugsToUpsert.add(mc);
                            } else {
                                if (!manager.NewMembersMapConsumerDrugsToInsert.containsKey(memberId)) {
                                    manager.NewMembersMapConsumerDrugsToInsert.put(memberId, new List<vlocity_ins__ConsumerDrug__c>());
                                }
                                manager.NewMembersMapConsumerDrugsToInsert.get(memberId).add(mc);
                            }
                            
                        }
                    }
                }

                // Process Group 4 (EB_Physicians) - Question 8
                List<Object> physiciansListToProcess = convertObjectToList(stepMedicalQuestions.get('EB_Physicians'));
 
                if (physiciansListToProcess != null) {
                    for (Object recordObj : physiciansListToProcess) {
                        if (recordObj != null) {
                            Map<String, Object> recordMap = (Map<String, Object>)recordObj;
                            String memberId = (String)recordMap.get('memberId');
                            String physicianName = (String)recordMap.get('TXT_PhysicianName');
                            String physicianCity = (String)recordMap.get('TXT_PhysicianCity');
                            String physicianPhone = (String)recordMap.get('TXT_PhysicianPhone');
                
                            if (!String.isBlank(physicianName) || !String.isBlank(physicianCity) || !String.isBlank(physicianPhone)) {
                                if (!memberId.startsWith('MEM-')) {
                                    Account phA = new Account();
                                    phA.Id = oldMembers != null && oldMembers.containsKey(memberId) ? (Id)oldMembers.get(memberId).get('accountId') : null;
                                    phA.ARC_PhysicianName__c = physicianName;
                                    phA.ARC_PhysicianCity__c = physicianCity;
                                    phA.ARC_PhysicianPhone__c = physicianPhone;
                    
                                    vlocity_ins__GroupCensusMember__c phGCM = new vlocity_ins__GroupCensusMember__c();
                                    phGCM.Id = oldMembers != null && oldMembers.containsKey(memberId) ? (Id)oldMembers.get(memberId).get('censusId') : null;
                                    phGCM.ARC_PhysicianName__c = physicianName;
                                    phGCM.ARC_PhysicianCity__c = physicianCity;
                                    phGCM.ARC_PhysicianPhone__c = physicianPhone;

                                    manager.physicianAccountToUpdate.add(phA);
                                    manager.physicianGCMToUpdate.add(phGCM);

                                } else {
                                    Map<String, Object> physicianMemberInfo = new Map<String, Object>();
                                    physicianMemberInfo.put('ARC_PhysicianName__c', physicianName);
                                    physicianMemberInfo.put('ARC_PhysicianCity__c', physicianCity);
                                    physicianMemberInfo.put('ARC_PhysicianPhone__c', physicianPhone);

                                    manager.physicianNewMemberDataToUpdate.put(memberId, physicianMemberInfo);
                                }
                            }
                        }
                    }
                } 
            }
        } catch  (Exception e) {
            System.debug(e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /*******************************************************************
    * @MethodName         :   createContractParticipants
    * @Description        :   create the contract participants of the new contract
    ********************************************************************/
    public void createContractParticipants () {
        try {
            for (Map<String,Object> member : manager.censusMembersInPcContract) {
                if (member.containsKey('IsRemoveMember') && (Boolean)member.get('IsRemoveMember') == false) {
                    ARC_ContractParticipant__c newContractParticipant = new ARC_ContractParticipant__c();

                    newContractParticipant.ARC_Address__CountryCode__s = 'US';
                    newContractParticipant.ARC_Address__Street__s = String.valueOf(member.get('ARC_PhysicalAddressStreet__c'));
                    newContractParticipant.ARC_Address__City__s = String.valueOf(member.get('ARC_PhysicalAddressCity__c'));
                    newContractParticipant.ARC_Address__StateCode__s = String.valueOf(member.get('ARC_PhysicalAddressState__c')).toUpperCase();
                    newContractParticipant.ARC_Address__PostalCode__s = String.valueOf(member.get('ARC_PhysicalAddressZipCode__c'));
                    newContractParticipant.ARC_FirstName__c = String.valueOf(member.get('vlocity_ins__FirstName__c'));
                    newContractParticipant.ARC_LastName__c = String.valueOf(member.get('vlocity_ins__LastName__c'));
                    newContractParticipant.Name = String.valueOf(member.get('vlocity_ins__FirstName__c')) + ' ' + String.valueOf(member.get('vlocity_ins__LastName__c'));
                    newContractParticipant.ARC_Gender__c = String.valueOf(member.get('vlocity_ins__Gender__c'));
                    newContractParticipant.ARC_BirthDate__c	 = Date.valueOf(String.valueOf(member.get('vlocity_ins__Birthdate__c')));
                    newContractParticipant.ARC_Email__c = String.valueOf(member.get('vlocity_ins__Email__c'));
                    newContractParticipant.ARC_Phone__c =  String.valueOf(member.get('ARC_Phone__c'));
                    if(String.valueOf(member.get('ARC_HeightFeet__c')) != null && String.valueOf(member.get('ARC_HeightInches__c')) != null) {
                        newContractParticipant.ARC_Height__c = String.valueOf(member.get('ARC_HeightFeet__c')) + '\'' + String.valueOf(member.get('ARC_HeightInches__c'));
                    }
                    newContractParticipant.ARC_Weight__c =  String.valueOf(member.get('ARC_Weight__c')) != null ? String.valueOf(member.get('ARC_Weight__c')) : null;
                    newContractParticipant.ARC_PersonAccount__c = member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false ? String.valueOf(member.get('PersonAccountId')) : null;
                    newContractParticipant.ARC_Relationship__c = member.containsKey('ARC_Relationship__c') ? String.valueOf(member.get('ARC_Relationship__c')) : null;
                    newContractParticipant.ARC_Smoker__c = member.containsKey('ARC_Smoker__c') && convertToBoolean(member.get('ARC_Smoker__c')) != null ? convertToBoolean(member.get('ARC_Smoker__c')) : false;


                    manager.personAccIdOrFakeIdToContractPart.put((String)member.get('Id'), newContractParticipant);
                }
            }
        } catch (Exception e) {
            System.debug('Exception creating Contract Participant: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }  
    }

    /*******************************************************************
    * @MethodName         :   createChargentOrders
    * @Description        :   map Chargent Orders to create
    /********************************************************************/   
    private void createChargentOrders(String action) {
        //manager.chargentOrdersRecurringOrder
        //manager.chargentOrdersChangeFee        
        try{
            //Get Contract Id from JSON
            Map<String,Object> pcChanges = (Map<String,Object>)manager.inputMap.get('pcChanges');
            Map<String,Object> SelectedContractInfo = (Map<String,Object>)manager.inputMap.get('SelectedContractInfo');
            Map<String,Object> PlansSummary = (Map<String,Object>)manager.inputMap.get('PlansSummary');
            Map<String,Object> BLK_ProductSummary = (Map<String,Object>)PlansSummary.get('BLK_ProductSummary');
            Map<String, Object> Step_PaymentChangeFee = (Map<String, Object>)manager.inputMap.get('Step_PaymentChangeFee');
            Id contractId = (Id)SelectedContractInfo.get('ContractID');
            Id groupAccountId = (Id)SelectedContractInfo.get('GroupAccountId');

            //Query previous Chargent Order      
            List<ChargentOrders__ChargentOrder__c> oldChOrders = [SELECT Id,ChargentOrders__Charge_Date__c, ChargentOrders__Bank_Routing_Number__c,ChargentOrders__Bank_Account_Number__c,ChargentOrders__Bank_Account_Type__c,ChargentOrders__Bank_Name__c,ChargentOrders__Billing_First_Name__c,ARC_FirstMonthPayed__c , ChargentOrders__Billing_Last_Name__c, ChargentOrders__Billing_Address__c, ChargentOrders__Billing_City__c, ChargentOrders__Billing_State__c, ChargentOrders__Billing_Zip_Postal__c, ChargentOrders__Card_Expiration_Month__c, ChargentOrders__Card_Expiration_Year__c, ChargentOrders__Card_Last_4__c, ChargentOrders__Card_Month_Indicator__c, ChargentOrders__Card_Number__c, ChargentOrders__Card_Type__c, ChargentOrders__Card_Year_Indicator__c, ChargentOrders__Charge_Amount__c, ChargentOrders__Description__c, ChargentOrders__Gateway__c, ChargentOrders__Payment_Frequency__c, ChargentOrders__Payment_Method__c, ChargentOrders__Payment_Status__c, ChargentOrders__Subtotal__c, ChargentOrders__Manual_Charge__c, ChargentOrders__Tokenization__c, ChargentOrders__Payment_Start_Date__c, ChargentOrders__Bank_Account_Name__c FROM ChargentOrders__ChargentOrder__c WHERE ARC_Contract__c =: contractId ORDER BY CreatedDate ASC];
            
            ChargentOrders__ChargentOrder__c oldChOr;
            ChargentOrders__ChargentOrder__c oldRecurring;
            ChargentOrders__ChargentOrder__c oldAppFee;


            for(ChargentOrders__ChargentOrder__c order: oldChOrders){
                oldChOr = order;
                if(order.ChargentOrders__Description__c == 'Recurring Monthly Order') {
                    oldRecurring = order;
                }
                if(order.ChargentOrders__Description__c =='App Fee' ||order.ChargentOrders__Description__c =='Change Fee'){
                    oldAppFee = order;
                }
            }
            if(oldRecurring != null && oldChOr != oldRecurring){
                oldChOr = oldRecurring;
            }
            
            if(manager.inputMap.containsKey('pcChanges') && (Boolean)pcChanges.get('feeApplicable') == true && (String)Step_PaymentChangeFee.get('RAD_ChargeAppFeeDefTrue') == 'Yes'){
                ChargentOrders__ChargentOrder__c newCOChangeFee = new ChargentOrders__ChargentOrder__c();

                Map<String, Object> primaryMember = (Map<String, Object>)manager.inputMap.get('PrimaryMember'); 
                Date futurePaymentDate;
                if(oldAppFee != null && oldAppFee.ARC_FirstMonthPayed__c == false && oldAppFee.ChargentOrders__Payment_Start_Date__c != null && oldAppFee.ChargentOrders__Payment_Start_Date__c > Date.Today()){
                    futurePaymentDate = oldAppFee.ChargentOrders__Payment_Start_Date__c;
                }
                Id gatewayIdCC = null;
                Id gatewayIdBA = null;
                List<ChargentBase__Gateway__c>  gateways = [SELECT Id, ChargentBase__Available_Payment_Methods__c  FROM ChargentBase__Gateway__c  WHERE ChargentBase__Active__c = true AND ( ChargentBase__Available_Payment_Methods__c INCLUDES ('Credit Card') OR ChargentBase__Available_Payment_Methods__c INCLUDES ('Bank Account'))];
                for(ChargentBase__Gateway__c gateway : gateways){
                    if(gateway.ChargentBase__Available_Payment_Methods__c.contains('Credit Card')){
                        gatewayIdCC = gateway.Id;
                    }
                    if(gateway.ChargentBase__Available_Payment_Methods__c.contains('Bank Account')){
                        gatewayIdBA = gateway.Id;
                    }
                }

                newCOChangeFee.ChargentOrders__Account__c = groupAccountId;
                if(Step_PaymentChangeFee.containsKey('BLK_ChargeFee') != null && Step_PaymentChangeFee.containsKey('BLK_ChargeFee')){
                    Map<String, Object> BLK_ChargeFee = (Map<String, Object>)Step_PaymentChangeFee.get('BLK_ChargeFee');
                    if(BLK_ChargeFee.containsKey('RAD_KeepRecurringMethodOfPayment') && (String)BLK_ChargeFee.get('RAD_KeepRecurringMethodOfPayment') == 'No'){
                        Map<String,Object> BLK_PaymentInfo = (Map<String,Object>)BLK_ChargeFee.get('BLK_PaymentInfo');
                        //Credit Card
                        if(BLK_ChargeFee.containsKey('RAD_MethodOfPayment') && (String)BLK_ChargeFee.get('RAD_MethodOfPayment') == 'Credit Card'){
                            Map<String,Object> BLK_CreditCard = (Map<String,Object>)BLK_PaymentInfo.get('BLK_CreditCard');
                            newCOChangeFee.ChargentOrders__Billing_First_Name__c = BLK_CreditCard.containsKey   ('TXT_FirstNameOnCard') ? (String)BLK_CreditCard.get('TXT_FirstNameOnCard') : null;
                            newCOChangeFee.ChargentOrders__Billing_Last_Name__c = BLK_CreditCard.containsKey('TXT_LastNameOnCard') ? (String)BLK_CreditCard.get('TXT_LastNameOnCard') : null;
                            newCOChangeFee.ChargentOrders__Billing_Address__c = BLK_CreditCard.containsKey('TXT_BillingAddress_Street') ? (String)BLK_CreditCard.get('TXT_BillingAddress_Street') : null;
                            newCOChangeFee.ChargentOrders__Billing_City__c = BLK_CreditCard.containsKey('TXT_BillingAddress_City') ? (String)BLK_CreditCard.get('TXT_BillingAddress_City') : null;
                            newCOChangeFee.ChargentOrders__Billing_State__c = BLK_CreditCard.containsKey('TXT_BillingAddress_State') ? (String)BLK_CreditCard.get('TXT_BillingAddress_State') : null;
                            newCOChangeFee.ChargentOrders__Billing_Zip_Postal__c = BLK_CreditCard.containsKey('TXT_BillingAddress_ZipCode') ? (String)BLK_CreditCard.get('TXT_BillingAddress_ZipCode') : null;
                            newCOChangeFee.ChargentOrders__Card_Number__c = BLK_CreditCard.containsKey('TXT_CardNumber') ? (String)BLK_CreditCard.get('TXT_CardNumber') : null;
                            newCOChangeFee.ChargentOrders__Card_Expiration_Month__c = BLK_CreditCard.containsKey('SLC_ExpirationMonth') ? (String)BLK_CreditCard.get('SLC_ExpirationMonth') : null;
                            newCOChangeFee.ChargentOrders__Card_Month_Indicator__c = BLK_CreditCard.containsKey('SLC_ExpirationMonth') ? (String)BLK_CreditCard.get('SLC_ExpirationMonth') : null;
                            newCOChangeFee.ChargentOrders__Card_Expiration_Year__c = BLK_CreditCard.containsKey('SLC_Year') ? (String)BLK_CreditCard.get('SLC_Year') : null;
                            newCOChangeFee.ChargentOrders__Card_Year_Indicator__c =BLK_CreditCard.containsKey('SLC_Year') ? (String)BLK_CreditCard.get('SLC_Year') : null;
                            newCOChangeFee.ChargentOrders__Card_Last_4__c = BLK_CreditCard.containsKey('TXT_CardNumber') ? ((String)BLK_CreditCard.get('TXT_CardNumber')).right(4) : null;
                            newCOChangeFee.ChargentOrders__Payment_Method__c = 'Credit Card';
                            newCOChangeFee.ChargentOrders__Gateway__c = gatewayIdCC;
                            ///MISSING FIELDS 
                            /*
                            //Chargent Takes Care of this
                            newCOChangeFee.ChargentOrders__Card_Type__c = Card Type(Visa, Mastercard, etc)
                            */
                        }                   
                        //Bank Account
                        if(BLK_ChargeFee.containsKey('RAD_MethodOfPayment') && (String)BLK_ChargeFee.get('RAD_MethodOfPayment') == 'Bank Account'){
                            if(BLK_PaymentInfo.containsKey('BLK_BankAccount')){    
                                Map<String,Object> BLK_BankAccount = (Map<String,Object>)BLK_PaymentInfo.get('BLK_BankAccount');
                                newCOChangeFee.ChargentOrders__Bank_Routing_Number__c = BLK_BankAccount.containsKey('TXT_RoutingNumber') ? (String)BLK_BankAccount.get('TXT_RoutingNumber') : null;
                                newCOChangeFee.ChargentOrders__Bank_Account_Number__c = BLK_BankAccount.containsKey('TXT_AccNumber') ? (String)BLK_BankAccount.get('TXT_AccNumber') : null;
                                newCOChangeFee.ChargentOrders__Billing_First_Name__c = BLK_BankAccount.containsKey('TXT_FirstNameOnAccount') ? (String)BLK_BankAccount.get('TXT_FirstNameOnAccount') : null;
                                newCOChangeFee.ChargentOrders__Billing_Last_Name__c = BLK_BankAccount.containsKey('TXT_LastNameOnAccount') ? (String)BLK_BankAccount.get('TXT_LastNameOnAccount') : null;
                                newCOChangeFee.ChargentOrders__Bank_Account_Name__c = newCOChangeFee.ChargentOrders__Billing_First_Name__c != null? newCOChangeFee.ChargentOrders__Billing_First_Name__c + ' '+newCOChangeFee.ChargentOrders__Billing_Last_Name__c: null;
                                newCOChangeFee.ChargentOrders__Bank_Name__c = BLK_BankAccount.containsKey('TXT_BankName') ? (String)BLK_BankAccount.get('TXT_BankName') : null;
                                newCOChangeFee.ChargentOrders__Bank_Account_Type__c = BLK_BankAccount.containsKey('SLC_AccType') ? (String)BLK_BankAccount.get('SLC_AccType') : null;
                                newCOChangeFee.ChargentOrders__Payment_Method__c = 'Bank Account';
                                newCOChangeFee.ChargentOrders__Gateway__c = gatewayIdBA;
                                ///MISSING FIELDS 
                                /*
                                //Chargent Takes Care of this
                                newCOChangeFee.ChargentOrders__Card_Type__c = Card Type(Visa, Mastercard, etc)                            
                                */                          
                            }
                        }
                        newCOChangeFee.ARC_FirstMonthPayed__c = false;
                        newCOChangeFee.ChargentOrders__Description__c = 'Change Fee';   
                        newCOChangeFee.ChargentOrders__Payment_Status__c = null;
                        newCOChangeFee.ChargentOrders__Subtotal__c = (Decimal)pcChanges.get('feeAmount');
                        newCOChangeFee.ChargentOrders__Charge_Amount__c = (Decimal)pcChanges.get('feeAmount');
                        newCOChangeFee.ChargentOrders__Payment_Frequency__c = 'Once';
                        newCOChangeFee.ChargentOrders__Payment_Start_Date__c = futurePaymentDate != null?futurePaymentDate:null;
                        newCOChangeFee.ChargentOrders__Manual_Charge__c = true;                                        
                    }
                    //OLD Payment Method
                    else if(BLK_ChargeFee.containsKey('RAD_KeepRecurringMethodOfPayment') && (String)BLK_ChargeFee.get('RAD_KeepRecurringMethodOfPayment') == 'Yes'){
                        //Populate Payment Fields
                        if(oldChOr != null){
                            newCOChangeFee.ChargentOrders__Billing_First_Name__c = oldChOr.ChargentOrders__Billing_First_Name__c;
                            newCOChangeFee.ChargentOrders__Billing_Last_Name__c = oldChOr.ChargentOrders__Billing_Last_Name__c;
                            newCOChangeFee.ChargentOrders__Billing_Address__c = oldChOr.ChargentOrders__Billing_Address__c;
                            newCOChangeFee.ChargentOrders__Billing_City__c = oldChOr.ChargentOrders__Billing_City__c;
                            newCOChangeFee.ChargentOrders__Billing_State__c = oldChOr.ChargentOrders__Billing_State__c;
                            newCOChangeFee.ChargentOrders__Billing_Zip_Postal__c = oldChOr.ChargentOrders__Billing_Zip_Postal__c;
                            newCOChangeFee.ChargentOrders__Tokenization__c = oldChOr.ChargentOrders__Tokenization__c;
                            newCOChangeFee.ChargentOrders__Payment_Start_Date__c = futurePaymentDate != null?futurePaymentDate:null;

                            if(oldChOr.ChargentOrders__Payment_Method__c == 'Credit Card'){
                                newCOChangeFee.ChargentOrders__Card_Number__c = oldChOr.ChargentOrders__Card_Number__c;
                                newCOChangeFee.ChargentOrders__Card_Expiration_Month__c = oldChOr.ChargentOrders__Card_Expiration_Month__c;
                                newCOChangeFee.ChargentOrders__Card_Expiration_Year__c = oldChOr.ChargentOrders__Card_Expiration_Year__c;
                                newCOChangeFee.ChargentOrders__Card_Last_4__c = oldChOr.ChargentOrders__Card_Last_4__c;
                            }
                            else if(oldChOr.ChargentOrders__Payment_Method__c == 'Bank Account'){
                                try{
                                    newCOChangeFee.ChargentOrders__Bank_Routing_Number__c = oldChOr.ChargentOrders__Bank_Routing_Number__c;
                                    newCOChangeFee.ChargentOrders__Bank_Account_Number__c = oldChOr.ChargentOrders__Bank_Account_Number__c;
                                    newCOChangeFee.ChargentOrders__Billing_First_Name__c = oldChOr.ChargentOrders__Billing_First_Name__c;
                                    newCOChangeFee.ChargentOrders__Billing_Last_Name__c = oldChOr.ChargentOrders__Billing_Last_Name__c;
                                    newCOChangeFee.ChargentOrders__Bank_Name__c = oldChOr.ChargentOrders__Bank_Name__c;
                                    newCOChangeFee.ChargentOrders__Bank_Account_Type__c = oldChOr.ChargentOrders__Bank_Account_Type__c;
                                    newCOChangeFee.ChargentOrders__Bank_Account_Name__c = oldChOr.ChargentOrders__Bank_Account_Name__c;
                                }
                                catch(Exception e){
                                    System.debug(e.getMessage() + ' ' + e.getStackTraceString());
                                    throw e;
                                }                     
                            }
                        }
                        //Set other fields
                        
                        try{
                            newCOChangeFee.ChargentOrders__Card_Month_Indicator__c = oldChOr.ChargentOrders__Card_Month_Indicator__c;
                            newCOChangeFee.ChargentOrders__Card_Type__c = oldChOr.ChargentOrders__Card_Type__c;
                            newCOChangeFee.ChargentOrders__Card_Year_Indicator__c = oldChOr.ChargentOrders__Card_Year_Indicator__c;
                            newCOChangeFee.ChargentOrders__Charge_Amount__c =  (Decimal)pcChanges.get('feeAmount');
                            newCOChangeFee.ChargentOrders__Description__c = 'Change Fee';
                            newCOChangeFee.ChargentOrders__Gateway__c = oldChOr.ChargentOrders__Gateway__c;
                            newCOChangeFee.ChargentOrders__Payment_Frequency__c = 'Once';
                            newCOChangeFee.ChargentOrders__Payment_Method__c = oldChOr.ChargentOrders__Payment_Method__c;
                            newCOChangeFee.ChargentOrders__Payment_Status__c = null;
                            newCOChangeFee.ChargentOrders__Subtotal__c =  (Decimal)pcChanges.get('feeAmount');
                            newCOChangeFee.ChargentOrders__Manual_Charge__c = oldChOr.ChargentOrders__Manual_Charge__c;                        
                        }
                        catch(Exception e){                        
                            System.debug(e.getMessage() + ' ' + e.getStackTraceString());
                            throw e;
                        }
                    }
                }
                manager.chargentOrdersChangeFee.add(newCOChangeFee);   
            }
            //Recurring Order Fee
            if(action == 'Recurring'){
                ChargentOrders__ChargentOrder__c newCORecurring = new ChargentOrders__ChargentOrder__c();  
                try{
                    newCORecurring.ChargentOrders__Account__c = groupAccountId;
                    newCORecurring.ARC_FirstMonthPayed__c = oldChOr.ARC_FirstMonthPayed__c;
                    newCORecurring.ChargentOrders__Billing_Address__c = oldChOr.ChargentOrders__Billing_Address__c;
                    newCORecurring.ChargentOrders__Billing_City__c = oldChOr.ChargentOrders__Billing_City__c;
                    newCORecurring.ChargentOrders__Billing_First_Name__c = oldChOr.ChargentOrders__Billing_First_Name__c;
                    newCORecurring.ChargentOrders__Billing_Last_Name__c = oldChOr.ChargentOrders__Billing_Last_Name__c;
                    newCORecurring.ChargentOrders__Billing_State__c = oldChOr.ChargentOrders__Billing_State__c;
                    newCORecurring.ChargentOrders__Billing_Zip_Postal__c = oldChOr.ChargentOrders__Billing_Zip_Postal__c;
                    newCORecurring.ChargentOrders__Card_Expiration_Month__c = oldChOr.ChargentOrders__Card_Expiration_Month__c;
                    newCORecurring.ChargentOrders__Card_Expiration_Year__c = oldChOr.ChargentOrders__Card_Expiration_Year__c;
                    newCORecurring.ChargentOrders__Card_Last_4__c = oldChOr.ChargentOrders__Card_Last_4__c;
                    newCORecurring.ChargentOrders__Card_Month_Indicator__c = oldChOr.ChargentOrders__Card_Month_Indicator__c; 
                    newCORecurring.ChargentOrders__Card_Number__c = oldChOr.ChargentOrders__Card_Number__c;
                    newCORecurring.ChargentOrders__Card_Type__c = oldChOr.ChargentOrders__Card_Type__c;
                    newCORecurring.ChargentOrders__Card_Year_Indicator__c = oldChOr.ChargentOrders__Card_Year_Indicator__c;
                    newCORecurring.ChargentOrders__Charge_Amount__c = Decimal.valueOf(((String)BLK_ProductSummary.get('TXT_MonthlyPrice')).remove('$').trim());
                    newCORecurring.ChargentOrders__Charge_Date__c =  manager.newChargeDate != null? manager.newChargeDate:oldChOr.ChargentOrders__Charge_Date__c;                    
                    newCORecurring.ChargentOrders__Description__c = 'Recurring Monthly Order';
                    newCORecurring.ChargentOrders__Tokenization__c = oldChOr.ChargentOrders__Tokenization__c;
                    newCORecurring.ChargentOrders__Gateway__c = oldChOr.ChargentOrders__Gateway__c;
                    newCORecurring.ChargentOrders__Payment_Frequency__c = 'Monthly';
                    newCORecurring.ChargentOrders__Payment_Method__c = oldChOr.ChargentOrders__Payment_Method__c;
                    newCORecurring.ChargentOrders__Payment_Start_Date__c  = manager.paymentStartDate != null? manager.paymentStartDate:Date.today();
                    newCORecurring.ChargentOrders__Payment_Status__c = 'Stopped';
                    newCORecurring.ChargentOrders__Subtotal__c = Decimal.valueOf(((String)BLK_ProductSummary.get('TXT_MonthlyPrice')).remove('$').trim());
                    newCORecurring.ChargentOrders__Manual_Charge__c  = true;
                    //Bank Account Fields
                    newCORecurring.ChargentOrders__Bank_Routing_Number__c = oldChOr.ChargentOrders__Bank_Routing_Number__c;
                    newCORecurring.ChargentOrders__Bank_Account_Number__c = oldChOr.ChargentOrders__Bank_Account_Number__c;
                    newCORecurring.ChargentOrders__Bank_Name__c = oldChOr.ChargentOrders__Bank_Name__c;
                    newCORecurring.ChargentOrders__Bank_Account_Name__c = oldChOr.ChargentOrders__Bank_Account_Name__c;
                    newCORecurring.ChargentOrders__Bank_Account_Type__c = oldChOr.ChargentOrders__Bank_Account_Type__c;
                    manager.chargentOrdersRecurringOrder.add(newCORecurring);
                }      
                catch(Exception e){
                    System.debug(e.getMessage() + ' ' + e.getStackTraceString());
                    throw e;
                }            
            }
        }
        catch(Exception e){
            System.debug(e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /*******************************************************************
    * @MethodName         :   createHipaaAuthorization
    * @Description        :   create the hipaa authorization
    ********************************************************************/
    public void createHipaaAuthorization() {
        try {
           
            if(manager.inputMap.containsKey('STEP_HIPAAAuthorizationForm') && manager.inputMap.get('STEP_HIPAAAuthorizationForm') != null) {
                Map<String, Object> stepHipaa = (Map<String, Object>)manager.inputMap.get('STEP_HIPAAAuthorizationForm');
                String authorizeOthers = (String)stepHipaa.get('RAD_AuthorizeOthers');

                if (stepHipaa.containsKey('EDITBLK_HIPAAAuthorizedParties') && stepHipaa.get('EDITBLK_HIPAAAuthorizedParties') != null) {
                    List<Object> listMembersHipaa = convertObjectToList(stepHipaa.get('EDITBLK_HIPAAAuthorizedParties'));
                    // Internal members hipaa
                    for (Object o : listMembersHipaa) {
                        Map<String, Object> memberHipaa = (Map<String, Object>)o;
                        Boolean isAuthorized = (Boolean)memberHipaa.get('CHK_Authorized');
                        if (isAuthorized) {
                            ARC_HipaaAuthorization__c newHipaa;
                            Map<String, Object> guardianInfo = (Map<String, Object>)manager.inputMap.get('STEP_GuardiansInfo');
                            if (guardianInfo != null) {
                                // Guardian
                                if (guardianInfo.containsKey('PersonContactId') && guardianInfo.get('PersonContactId') != null) {
                                    Id guardianContactId = (Id)guardianInfo.get('PersonContactId');
                                    newHipaa = [SELECT Id FROM ARC_HipaaAuthorization__c WHERE ARC_ExternalPersonAuthorized__c =: guardianContactId];
                                } else {
                                    newHipaa = new ARC_HipaaAuthorization__c();
                                    newHipaa.Name = (String)memberHipaa.get('TXT_FullName');
                                    newHipaa.ARC_Census__c = manager.inputMap.containsKey('CensusId') ? (Id)manager.inputMap.get('CensusId') : null;
                                    manager.guardianHippa = newHipaa;
                                }
                            } else {
                                // Not guardian
                                newHipaa = new ARC_HipaaAuthorization__c();
                                newHipaa.Name = (String)memberHipaa.get('TXT_FullName');
                                newHipaa.ARC_Census__c = manager.inputMap.containsKey('CensusId') ? (Id)manager.inputMap.get('CensusId') : null;
                                manager.fakeIdToHipaaAuth.put((String)memberHipaa.get('Id'), newHipaa);
                            }
                        }
                    }
                }         

                // External member hipaa
                if (authorizeOthers == 'Yes') {
                    Map<String, Object> otherAuth = (Map<String, Object>)stepHipaa.get('NewHipaa');
                    Map<String, Object> address = (Map<String, Object>)otherAuth.get('TXT_NewAdress-Block');
                    Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('ARC_HipaaAuthorization').getRecordTypeId();

                    Contact newContact = new Contact();
                    newContact.FirstName = (String)otherAuth.get('TXT_NewFirstName');
                    newContact.LastName = (String)otherAuth.get('TXT_NewLastName');
                    newContact.Birthdate = Date.valueOf((String)otherAuth.get('TXT_NewBirthdate'));
                    newContact.Email = (String)otherAuth.get('TXT_NewEmailAdress');
                    newContact.Phone = (String)otherAuth.get('TXT_NewTelephone');
                    newContact.MailingCity = (String)address.get('TXT_AddCity');
                    newContact.MailingCountry = (String)address.get('TXT_AddCountry');
                    newContact.MailingState = (String)address.get('SEL_AddState');
                    newContact.MailingPostalCode = (String)address.get('TXT_AddZipCode');
                    newContact.MailingStreet = (String)address.get('TXT_AddAddress');
                    newContact.RecordTypeId = recordTypeId;
                    Map<String, Object> selectedContractInfo = (Map<String, Object>)manager.inputMap.get('SelectedContractInfo');
                    if (selectedContractInfo != null) {
                        newContact.AccountId = (String)selectedContractInfo.get('GroupAccountId');
                    }

                    manager.hippaExternalContact = newContact;
                }
            }   
        } catch (Exception e) {
            System.debug('Exception creating Hippa Authorizations: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }  
    }

    /*******************************************************************
    * @MethodName         :   insertPromotionDiscount  
    * @Description        :   Method to insert promotion discount if apply
    ********************************************************************/
    private void insertPromotionDiscount(){
        try {
            if (manager.inputMap.get('Step_PaymentChangeFee') != null) {

                Map<String, Object> stepPaymentChangeFee = (Map<String, Object>) manager.inputMap.get('Step_PaymentChangeFee');
                Map<String, Object> blkChargeFee = stepPaymentChangeFee.containsKey('BLK_ChargeFee') && (Map<String, Object>)stepPaymentChangeFee.get('BLK_ChargeFee') != null ? (Map<String, Object>)stepPaymentChangeFee.get('BLK_ChargeFee') : null;

                if(blkChargeFee != null) {
                    Map<String, Object> promoDiscount = blkChargeFee.containsKey('LWC_PromoDiscountCodeRefactor') && (Map<String, Object>) blkChargeFee.get('LWC_PromoDiscountCodeRefactor') != null ? (Map<String, Object>) blkChargeFee.get('LWC_PromoDiscountCodeRefactor') :  new Map<String, Object>();                
                    if (!promoDiscount.isEmpty() && promoDiscount != null) { 
                        
                        Id recordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Promotion_Discount').getRecordTypeId();
    
                        ARC_PromotionDiscount__c discount = new ARC_PromotionDiscount__c();
    
                        discount.Name = promoDiscount.containsKey('PromotionCodeName') ? (String) promoDiscount.get('PromotionCodeName') : null;
                        discount.ARC_PromoCode__c = promoDiscount.containsKey('PromotionCodeId') ? (Id) promoDiscount.get('PromotionCodeId') : null;
                        discount.ARC_Contract__c = null;
                        discount.ARC_AmountToDiscountPerTransaction__c = promoDiscount.containsKey('DiscountAmount') ? Decimal.valueOf((String)promoDiscount.get('DiscountAmount')) : null;
                        discount.ARC_CorePriceWithoutDiscount__c = promoDiscount.containsKey('MedicalPrice') ? (Decimal)promoDiscount.get('MedicalPrice') : null;
                        discount.ARC_NumberOfTimesCanBeUsed__c = promoDiscount.containsKey('NumberOfPayments') ? (Integer) promoDiscount.get('NumberOfPayments') : 1;
                        discount.ARC_ExonerateAppChangeFee__c = promoDiscount.containsKey('DiscountPrice') && Decimal.valueOf((String)promoDiscount.get('DiscountPrice')) == 0 ? true : false ;
                        discount.ARC_Agent__c = promoDiscount.containsKey('AgentId') ? (Id) promoDiscount.get('AgentId') : null;
                        discount.RecordTypeId = recordTypeId; 
                       
                        // discount.ARC_ApplyOver__c = promoDiscount.containsKey('ApplyOver') ? (String) promoDiscount.get('ApplyOver') : null;
                        // discount.ARC_StartDate__c = Date.today();
                        // discount.ARC_TimesUsed__c = 0;
                        // discount.ARC_TypeOfDiscount__c =  promoDiscount.containsKey('ApplyOver') ? (String) promoDiscount.get('ApplyOver') : null;
                        manager.promotionDiscountToInsert.add(discount);
                    } 
                }
            } 
        } catch (Exception e) {
            System.debug('Exception insertPromotionDiscount: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

     /************************************************************************************
    * @MethodName         :   updatePersonMedicareInformation  
    * @Description        :   Method to update the person account and Medicare information
    *************************************************************************************/

    private void updatePersonMedicareInformation() {
        
        if(manager.inputMap.containsKey('STEP_MedicareCoverage') && manager.inputMap.get('STEP_MedicareCoverage') != null) {
            if ((Map<String,Object>)((Map<String,Object>)manager.inputMap.get('STEP_MedicareCoverage')).get('BLK_MedicareId') != null) {
                Map<String,Object> medicareInfoMap = (Map<String,Object>)((Map<String,Object>)manager.inputMap.get('STEP_MedicareCoverage')).get('BLK_MedicareId');
                String accountToUpdateID = (String)manager.inputMap.get('SV_AccountId');
                String medicareId = (String)medicareInfoMap.get('MedicareIdNumber');
                Date partAEffectiveDate = (String)medicareInfoMap.get('Medicare_A_Effective_Date') != null ? Date.valueOf((String)medicareInfoMap.get('Medicare_A_Effective_Date')) : null;
                Date partBEffectiveDate = (String)medicareInfoMap.get('Part_B_Effective_Date') != null ? Date.valueOf((String)medicareInfoMap.get('Part_B_Effective_Date')) : null;
                Date partDEffectiveDate = (String)medicareInfoMap.get('Part_D_Effective_Date') != null ? Date.valueOf((String)medicareInfoMap.get('Part_D_Effective_Date')) : null;
            
                // Update of person account medicare information 
                Account accountToUpdate = new Account ();
                accountToUpdate.Id = accountToUpdateID;
                accountToUpdate.Medicare_ID__c = medicareId;
                accountToUpdate.Medicare_Part_A_Effective_Date__c = partAEffectiveDate != null ? partAEffectiveDate : null;
                accountToUpdate.Medicare_Part_B_Effective_Date__c = partBEffectiveDate != null ? partBEffectiveDate : null;
                accountToUpdate.Medicare_Part_D_Effective_Date__c = partDEffectiveDate != null ? partDEffectiveDate : null;

                // Medicare string for Amendment DocuSign
                Boolean medicareInfoWasChange = (Boolean)medicareInfoMap.get('FRML_MedicareInformationChange');
                if (medicareInfoWasChange == true && manager.inputMap.containsKey('AmendmentDocuSignMapData')) {
                    Map<String,Object> amendmentMap = (Map<String,Object>)manager.inputMap.get('AmendmentDocuSignMapData');
                    String initialAmendmentInfo = amendmentMap.containsKey('AmendmentInfo') && amendmentMap.get('AmendmentInfo') != null ? (String)amendmentMap.get('AmendmentInfo') : null;
                    String finalAmendmentInfo = '';
                    String medicareIdString = medicareId != null ? 'Medicare ID: ' + medicareId : null;
                    String partAEffectiveDateString = partAEffectiveDate != null ? 'Part A: ' + String.valueOf(partAEffectiveDate) : null;
                    String partBEffectiveDateString = partBEffectiveDate != null ? 'Part B: ' + String.valueOf(partBEffectiveDate) : null;
                    String partDEffectiveDateString = partDEffectiveDate != null ? 'Part D: ' + String.valueOf(partDEffectiveDate) : null;
                    List<String> amendmentInfoList = new List<String>{
                    initialAmendmentInfo, medicareIdString, partAEffectiveDateString, partBEffectiveDateString, partDEffectiveDateString
                    };

                    if (!amendmentInfoList.isEmpty()) {
                        for (Integer i=0; i < amendmentInfoList.size(); i++) {
                            if (amendmentInfoList[i] == null) {
                                amendmentInfoList.remove(i);
                            }
                        }
                        finalAmendmentInfo = String.join(amendmentInfoList, '\n');
                        amendmentMap.put('AmendmentInfo', finalAmendmentInfo);
                        System.debug('Final Amendment Info: ' + finalAmendmentInfo);
                    }

                    manager.amendmentInfoMap = amendmentMap;
                }
                
                manager.legacyAccountToUpdate = accountToUpdate;
            }
        }


        
    }

    ///////////////////////
    /////// Getters ///////
    ///////////////////////
    
    /**
    * @Description: Retrieves census members from the input data
    * @return List<Map<String,Object>>: List of census member data 
    */
    List<Map<String,Object>> getCensusMembers() {
        List<Map<String,Object>> censusMembers = new List<Map<String,Object>>();
        Map<String, Object> censusComponent = (Map<String, Object>)manager.inputMap.get('census_component');
        List<Object> censusMembersList = (List<Object>)censusComponent.get('census_members');
        for (Object censusMember : censusMembersList) {
            Map<String,Object> member = (Map<String,Object>)censusMember;
            if (member.get('vlocity_ins__IsPrimaryMember__c') == true && (Boolean)member.get('IsNewMember') == false && (Boolean)member.get('IsRemoveMember')==false) {
                vlocity_ins__GroupCensusMember__c primary = new vlocity_ins__GroupCensusMember__c();
                primary.vlocity_ins__MemberIdentifier__c = member.containsKey('vlocity_ins__MemberIdentifier__c') ? (String)member.get('vlocity_ins__MemberIdentifier__c') : null;
                primary.vlocity_ins__ContactId__c = member.containsKey('PersonContactId') ? (String)member.get('PersonContactId') : null;
                primary.Id = member.containsKey('Id') ? (String)member.get('Id') : null;
                //primary.ARC_Address__c = member.containsKey('ARC_Address__c') ? (String)member.get('ARC_Address__c') : null;
                primary.ARC_PhysicalAddressZipCode__c = member.containsKey('ARC_PhysicalAddressZipCode__c') ? (String)member.get('ARC_PhysicalAddressZipCode__c') : null;
                primary.ARC_PhysicalAddressStreet__c = member.containsKey('ARC_PhysicalAddressStreet__c') ? (String)member.get('ARC_PhysicalAddressStreet__c') : null;
                primary.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? String.valueOf(member.get('ARC_PhysicalAddressState__c')).toUpperCase() : null;
                primary.ARC_PhysicalAddressCity__c = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                manager.primaryCensusMemberWithId = primary;
                Account primaryAccount = new Account();
                primaryAccount.Id = member.containsKey('PersonAccountId') ? (String)member.get('PersonAccountId') : null;
                manager.censusMemberToAccount.put((String)member.get('Id'), primaryAccount);
            }
            censusMembers.add(member);
        }
        manager.censusMembersInPcContract= censusMembers;
      
        return censusMembers;
    } 
    

    /**
     * @Description: Retrieves old census members from the input data
     * @return List<Map<String,Object>>: List of census member data 
    /*  
    Map<String,String> getOldPrimaryValues() {
        Map<String,String> oldPrimaryValues = new Map<String,String>();
        Id CensusId = (Id)manager.inputMap.get('CensusId');
        vlocity_ins__GroupCensusMember__c primaryCM = [SELECT Id, vlocity_ins__MemberIdentifier__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c  = :CensusId AND vlocity_ins__IsPrimaryMember__c = true LIMIT 1];
        oldPrimaryValues.put('Id', primaryCM.Id);
        oldPrimaryValues.put('vlocity_ins__MemberIdentifier__c', primaryCM.vlocity_ins__MemberIdentifier__c);
        
        return oldPrimaryValues;
    } 
    */

    /**
    * @Description: Retrieves old census members from the input data
    * @return List<Map<String,Object>>: List of census member data 
    */
    Map<String,String> getOldPrimaryValues() {
        Map<String,String> oldPrimaryValues = new Map<String,String>();Object oldProductsObject = manager.inputMap.get('oldProducts');
        List<Object> oldProductsList = new List<Object>();
        if (oldProductsObject != null) {
            if (oldProductsObject instanceof Map<String,Object>) {               
                oldProductsList.add(oldProductsObject);
            } 
            else if(oldProductsObject instanceof List<Object>){
                oldProductsList = (List<Object>)oldProductsObject;
            }
        }
        for(Object productObj : oldProductsList) {
            Map<String,Object> product = (Map<String,Object>)productObj;
            if((String)product.get('Type__c') == 'Medical') {               
                Object censusMembers = product.get('census_members');
                List<Object> censusMembersList = new List<Object>();
                if (censusMembers != null) {                    
                    if (censusMembers instanceof Map<String,Object>) {
                        censusMembersList.add(censusMembers);
                    }
                    else if(censusMembers instanceof List<Object>){
                        censusMembersList = (List<Object>)censusMembers;
                    }
                }
                for(Object memberObj : censusMembersList) {
                    Map<String,Object> member = (Map<String,Object>)memberObj;                    
                    if(member.containsKey('vlocity_ins__IsPrimaryMember__c') && (Boolean)member.get('vlocity_ins__IsPrimaryMember__c') == true) {                       
                        oldPrimaryValues.put('Id', (String)member.get('Id'));
                        oldPrimaryValues.put('vlocity_ins__MemberIdentifier__c', (String)member.get('vlocity_ins__MemberIdentifier__c'));
                        break;
                    }
                }
            }
        }
        return oldPrimaryValues;
    } 

    /**
    * @Description: Processes the price_calculation.plans from input map and returns a map of products organized by type
    * @return Map<String,Object>: Map containing medical, medical child products, ancillary, and ancillary child products
    */
    private Map<String,Object> getProductsWithMembers() {
        Map<String,Object> productToMembersMap = new Map<String,Object>();
        List<Map<String,Object>> ancillaryProducts = new List<Map<String,Object>>();
        List<Map<String,Object>> medicalChildProducts = new List<Map<String,Object>>();
        List<Map<String,Object>> ancillaryChildProducts = new List<Map<String,Object>>();
        if(manager.inputMap.containsKey('price_calculation')) {
            Map<String,Object> priceCalculation = (Map<String,Object>)manager.inputMap.get('price_calculation');
            if(priceCalculation.containsKey('plans')) {
                List<Object> plans = (List<Object>)priceCalculation.get('plans');
                
                for(Object planObj : plans) {
                    Map<String,Object> plan = (Map<String,Object>)planObj;
                    Map<String,Object> selectedProduct = (Map<String,Object>)plan.get('selectedProduct');
                    String productType = (String)selectedProduct.get('Type__c');
                    
                    // Get the list of members for this product
                    List<Object> userInputs = (List<Object>)plan.get('userInputs');
                    List<Map<String,Object>> members = new List<Map<String,Object>>();
                    
                    for(Object userInputObj : userInputs) {
                        Map<String,Object> userInput = (Map<String,Object>)userInputObj;
                        Map<String,Object> member = new Map<String,Object>{
                            'CensusMemberId' => userInput.get('Id'),
                            'FirstName' => userInput.get('RF_Census.CM_FirstName'),
                            'LastName' => userInput.get('RF_Census.CM_LastName'),
                            'IsPrimary' => userInput.get('RF_Census.CM_IsPrimary'),
                            'Relationship' => userInput.get('RF_Census.CM_Relationship'),
                            'Age' => userInput.get('RF_Census.CM_Age'),
                            'State' => userInput.get('RF_Census.CM_State'),
                            'Smoker' => userInput.get('RF_Census.CM_Smoker')
                        };
                        members.add(member);
                    }
                    
                    // If it's a medical product, use a specific key
                    if(productType == 'Medical') {
                        // Add the main medical product with price calculation data
                        Map<String,Object> medicalProduct = new Map<String,Object>{
                            'product' => selectedProduct,
                            'members' => members,
                            'priceData' => selectedProduct.get('RawPriceData')
                        };
                        productToMembersMap.put('Medical', medicalProduct);

                        // Process child products if they exist
                        if(selectedProduct.containsKey('childProducts')) {
                            Map<String,Object> childProducts = (Map<String,Object>)selectedProduct.get('childProducts');
                            if(childProducts.containsKey('records')) {
                                List<Object> childRecords = (List<Object>)childProducts.get('records');
                                for(Object childRecord : childRecords) {
                                    Map<String,Object> childProduct = (Map<String,Object>)childRecord;
                                    if((String)childProduct.get('Type__c') == 'Medical') {
                                        medicalChildProducts.add(new Map<String,Object>{
                                            'product' => childProduct,
                                            'members' => members
                                        });
                                    }
                                }
                            }
                        }
                    } 
                    // For ancillary products, add to the ancillary list
                    else if(productType == 'Ancillary') {
                        Map<String,Object> childProducts = (Map<String,Object>)selectedProduct.get('childProducts');
                        List<Map<String,Object>> coverageSpecs = new List<Map<String,Object>>();
                        List<Object> childProductsList;

                        if(childProducts.containsKey('records')){
                            childProductsList = (List<Object>)childProducts.get('records');
                       }                       
                        for(Object childProductObj : childProductsList){
                            Map<String,Object> childProduct = (Map<String,Object>)childProductObj;
                            if(childProduct.containsKey('RecordTypeName__c') && (String)childProduct.get('RecordTypeName__c') == 'CoverageSpec'){
                                coverageSpecs.add(childProduct);
                            }
                        }
        
                   
                        ancillaryProducts.add(new Map<String,Object>{
                            'product' => selectedProduct,
                            'members' => members,
                            'priceData' => selectedProduct.get('RawPriceData'),
                            'childProducts' => coverageSpecs
                        });                      
                    }
                }
                
                // Add all ancillary products under a single key
                if(!ancillaryProducts.isEmpty()) {
                    productToMembersMap.put('Ancillaries', ancillaryProducts);
                }
                
                // Add medical child products
                if(!medicalChildProducts.isEmpty()) {
                    productToMembersMap.put('MedicalChildProducts', medicalChildProducts);
                }
                
                // Add ancillary child products
                if(!ancillaryChildProducts.isEmpty()) {
                    productToMembersMap.put('AncillaryChildProducts', ancillaryChildProducts);
                }
            }
        }        
        return productToMembersMap;
    } 
/**
    * @Description: Process the newborns and update the policy end date to match effectiveDate
    * @return void
    */
    public void updatePolicyEndDateForNewborns(){
        List<Map<String,Object>> censusMembers  = getCensusMembers();
        Date effectiveDate = (Date)manager.inputMap.get('EffectiveDate');
        Set<Id> newbornCensusMemberIds = new Set<Id>();
        for(Map<String,Object> member : censusMembers){
            if(member.containsKey('IsNewborn') && (Boolean)member.get('IsNewborn') == true && member.containsKey('Id')){
                newbornCensusMemberIds.add((Id)member.get('Id'));
            }

        }
        if(!newbornCensusMemberIds.isEmpty()){
            List<InsurancePolicyParticipant> ippToUpdate = [SELECT Id, ARC_EndDate__c, PrimaryParticipantContactId 
                                                FROM InsurancePolicyParticipant 
                                                WHERE PrimaryParticipantContactId IN :newbornCensusMemberIds AND 
                                                (InsurancePolicy.ARC_Contract__r.Status = 'Activated' OR
                                                InsurancePolicy.ARC_Contract__r.Status LIKE 'Awaiting%')];
            for(InsurancePolicyParticipant ipp : ippToUpdate){
                ipp.ARC_EndDate__c = effectiveDate;
            }
            if(!ippToUpdate.isEmpty()){
                update ippToUpdate;
            }
        }
    }

    ///////////////////////
    // Auxiliary Methods //
    ///////////////////////   

    private void InsertAccountsWithCensusMemberIds() {
        if (!manager.censusMemberToAccount.isEmpty()) {
            manager.accountsToInsert = new List<Account>(manager.censusMemberToAccount.values());
        }
    }
    
    /**
    * @Description: Converts a value to Boolean
    * @param value: The value to convert
    * @return Boolean: The converted boolean value
    */
    private Boolean convertToBoolean(Object value) {
        if (value == null) return null;
        if (value instanceof Boolean) return (Boolean)value;
        if (value instanceof String) {
            String strValue = (String)value;
            return strValue.equalsIgnoreCase('true') || strValue.equals('1');
        }
        return null;
    }

    /**
    * @Description: Converts an Object to a List of Objects. If the Object is a Map,
    * it wraps it in a new List. If it's already a List, it returns it.
    * Returns null if the input Object is null.
    * @param value: The Object to convert.
    * @return List<Object>: The converted List of Objects.
    */
    private List<Object> convertObjectToList(Object value) {
        if (value == null) return null;

        List<Object> objectList = new List<Object>();

        if (value instanceof Map<String, Object>) {
            objectList.add(value); 
        } else if (value instanceof List<Object>) {
            objectList = (List<Object>)value;
        }

        return objectList;
    }

    /**
    * Processes a list of data records for a specific medical condition block and updates the provided medical condition map.
    * @param medicalConditionMap A map where the key is the member ID (String) and the value is the corresponding ARC_MedicalConditions__c record. This map will be updated with information extracted from the block data.
    * @param blockData A list of Objects, where each Object represents a record containing data for the specific medical condition block. Each Object is expected to be a Map<String, Object>.
    * @param blockName A String indicating the name of the medical condition block being processed. This is used to determine the specific fields to extract and the logic to apply.
    */
    private void processMedicalQuestionsFirstGroup(Map<String, ARC_MedicalConditions__c> medicalConditionMap, List<Object> blockData, String blockName) {
        if (blockData != null) {
            for (Object recordObj : blockData) {
                if (recordObj != null) {
                    Map<String, Object> recordMap = (Map<String, Object>)recordObj;
                    Boolean isBlockActiveForMember = false; // Variable to check if any block is activated per member
                    String memberId = (String)recordMap.get('memberId');
                    String memberName;
    
                    ARC_MedicalConditions__c mc = medicalConditionMap.get(memberId) != null ? medicalConditionMap.get(memberId): new ARC_MedicalConditions__c();
       
                    // Logic per blocke
                    if (blockName == 'BLK_ParentSiblingDiagnosed') {
                        Boolean hasParentSiblingDiagnosed = (Boolean)recordMap.get('CHKBOX_MemberParentDiagnosed');
                        if (hasParentSiblingDiagnosed == true) {
                            isBlockActiveForMember = true;
                            mc.ARC_ParentsOrSiblingsDiagnosed__c = hasParentSiblingDiagnosed;
                            mc.ARC_ParentsOrSiblingsDiagnosedDate__c = (String)recordMap.get('DATE_MemberParentDiagnosed') != null ? Date.valueOf((String)recordMap.get('DATE_MemberParentDiagnosed')) : null;
                            mc.ARC_ParentsOrSiblingsDiagnosedNote__c = (String)recordMap.get('TXTAREA_MemberParentDiagnosed');
                            memberName = (String)recordMap.get('TXT_MemberParentDiagnosed');
                        }
                    } else if (blockName == 'BLK_UnexpectedSymptoms') {
                        Boolean hasUnexpectedSymptoms = (Boolean)recordMap.get('CHKBOX_UnexpectedSymptoms');
                        if (hasUnexpectedSymptoms == true) {
                            isBlockActiveForMember = true;
                            mc.ARC_UnexplainedConditions__c = hasUnexpectedSymptoms;
                            mc.ARC_Unexplained_Conditions_Date__c = (String)recordMap.get('DATE_MemberUnexpectedSymptoms') != null ? Date.valueOf((String)recordMap.get('DATE_MemberUnexpectedSymptoms')) : null;
                            mc.ARC_Unexplained_Conditions_Notes__c = (String)recordMap.get('TXTAREA_MemberUnexpectedSymptoms');
                            memberName = (String)recordMap.get('TXT_MemberUnexpectedSymptoms');
                        }
                    } else if (blockName == 'BLK_PendingTests') {
                        Boolean hasPendingTests = (Boolean)recordMap.get('CHKBOX_PendingTests');
                        if (hasPendingTests == true) {
                            isBlockActiveForMember = true;
                            mc.ARC_Tests__c = hasPendingTests;
                            mc.ARC_Tests_Date__c = (String)recordMap.get('DATE_MemberPendingTests') != null ? Date.valueOf((String)recordMap.get('DATE_MemberPendingTests')) : null;
                            mc.ARC_Tests_Notes__c = (String)recordMap.get('TXTAREA_MemberPendingTests');
                            memberName = (String)recordMap.get('TXT_MemberPendingTests');
                        }
                    } else if (blockName == 'BLK_Addictions') {
                        Boolean hasAddiction = (Boolean)recordMap.get('CHKBOX_Addictions');
                        if (hasAddiction == true) {
                            isBlockActiveForMember = true;
                            mc.ARC_IllegalDrugsAlcohol__c = hasAddiction;
                            mc.ARC_Illegal_Drugs_Alcohol_Date__c = (String)recordMap.get('DATE_MemberAddictions') != null ? Date.valueOf((String)recordMap.get('DATE_MemberAddictions')) : null;
                            mc.ARC_Illegal_Drugs_Alcohol_Notes__c = (String)recordMap.get('TXTAREA_MemberAddictions');
                            memberName = (String)recordMap.get('TXT_MemberAddictions');
                        }
                    } else if (blockName == 'BLK_LicenceSuspended') {
                        Boolean hasLicenceSuspended = (Boolean)recordMap.get('CHKBOX_LicenceSuspended');
                        if (hasLicenceSuspended == true) {
                            isBlockActiveForMember = true;
                            mc.ARC_LicenceSuspended__c = hasLicenceSuspended;
                            mc.ARC_LicenseSuspendedDate__c = (String)recordMap.get('DATE_MemberLicenceSuspended') != null ? Date.valueOf((String)recordMap.get('DATE_MemberLicenceSuspended')) : null;
                            mc.ARC_LicenceSuspendedNote__c = (String)recordMap.get('TXTAREA_MemberLicenceSuspended');
                            memberName = (String)recordMap.get('TXT_MemberLicenceSuspended');
                        }
                    } else if (blockName == 'EB_PastConditions') {
                        String conditions = (String)recordMap.get('MULSEL_Conditions');
                        String otherConditions = (String)recordMap.get('TXT_MemberOtherPastConditions');
    
                        if (!String.isBlank(conditions) || !String.isBlank(otherConditions)) {
                            isBlockActiveForMember = true;
                            mc.ARC_Condition__c = conditions;
                            mc.ARC_OtherConditions__c = otherConditions;
                            memberName = (String)recordMap.get('TXT_MemberPastConditions');
                        }
                    }
                    // Only add to the map if any block is activated per member
                    if (isBlockActiveForMember) {
                        if(memberName.length()>60){
                            mc.Name = memberName.substring(0,60) + '-Medical Condition';
                        }
                        else mc.Name = memberName + '-Medical Condition';
                        mc.ARC_Active__c = true;
                        medicalConditionMap.put(memberId, mc);
                    }
                }
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   lastDateOfMonth
    * @Description        :   Returns the last date of the month based on the input date.
    ********************************************************************/
    public static Date lastDateOfMonth(Date d){
        if(d!= null){
            Integer numberOfDays = Date.daysInMonth(d.year(), d.month());
            return Date.newInstance(d.year(), d.month(), numberOfDays);
        }
        else return null;
    }

    
}