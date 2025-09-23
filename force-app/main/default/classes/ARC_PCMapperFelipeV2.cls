/**
 * @Description: This class is responsible for mapping and transforming input data into Salesforce objects.
 * It handles different types of program changes and prepares the data for database operations.
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-04-15
 * @Version: 1.0
 */

 public with sharing class ARC_PCMapperFelipeV2 {    
    private ARC_PCManagerFelipeV2 manager;

    private Set<String> actionsToExecute = new Set<String>();
 
    /**
     * @Description: Main method that executes the data mapping process
     * @param manager: The InsertManager instance containing the data to be mapped
     */
    public void executeChanges(ARC_PCManagerFelipeV2 manager) {
        this.manager = manager;
        
              
        // Collect actions with their corresponding actions to perform
        if (manager.pcReasons.containsKey('primaryChange') && (Boolean) manager.pcReasons.get('primaryChange')) {            
            manager.ActionsSelected.add('primaryChange');
            //Methods to exexcute on primary change
            //actionsToExecute.add('updateGCMprimaryChange');
            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped');
            actionsToExecute.add('createUWCase');
            actionsToExecute.add('createUWCaseMembers');
            actionsToExecute.add('insertContract');
            actionsToExecute.add('createCLI');
            actionsToExecute.add('createChargentOrders');
        }
        if (manager.pcReasons.containsKey('addressStateChange') && (Boolean) manager.pcReasons.get('addressStateChange')) {
            manager.ActionsSelected.add('addressStateChange');

            actionsToExecute.add('updateGCMaddressStateChange');
            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped');
            actionsToExecute.add('insertContract');
            actionsToExecute.add('createCLI');
            

        }
        if (manager.pcReasons.containsKey('relationshipToPrimaryChange') && (Boolean) manager.pcReasons.get('relationshipToPrimaryChange')) {
            manager.ActionsSelected.add('relationshipToPrimaryChange');

            //actionsToExecute.add('updateGCMrelationshipToPrimaryChange');
            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped');
            actionsToExecute.add('createUWCase');
            actionsToExecute.add('createUWCaseMembers');
            actionsToExecute.add('insertContract');
            actionsToExecute.add('createCLI');
            actionsToExecute.add('createChargentOrders');

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
            actionsToExecute.add('createChargentOrders');
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
            /* TO ADD START */
            actionsToExecute.add('upsertMedicalQuesitons');
            /* TO ADD END */
            actionsToExecute.add('createChargentOrders');
        }
        if (manager.pcReasons.containsKey('programDowngrade') && (Boolean) manager.pcReasons.get('programDowngrade')) {
            manager.ActionsSelected.add('programDowngrade');

            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped');
            actionsToExecute.add('createUWCase');
            actionsToExecute.add('createUWCaseMembers');
            actionsToExecute.add('insertContract');
            actionsToExecute.add('createCLI');
            actionsToExecute.add('createChargentOrders');
        }
        if (manager.pcReasons.containsKey('ancillaryChange') && (Boolean) manager.pcReasons.get('ancillaryChange')) {
            manager.ActionsSelected.add('ancillaryChange');

            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped'); 
            actionsToExecute.add('createUWCase');
            actionsToExecute.add('createUWCaseMembers');
            actionsToExecute.add('insertContract');
            actionsToExecute.add('createCLI');
            actionsToExecute.add('createChargentOrders');
        }
        if (manager.pcReasons.containsKey('removeAllAncillary') && (Boolean) manager.pcReasons.get('removeAllAncillary')) {            
            manager.ActionsSelected.add('removeAllAncillary');

            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped'); 
            actionsToExecute.add('createUWCase');
            actionsToExecute.add('createUWCaseMembers');
            actionsToExecute.add('insertContract');
            actionsToExecute.add('createCLI');
            actionsToExecute.add('createChargentOrders');
        }
        if (manager.pcReasons.containsKey('effectiveDateChange') && (Boolean) manager.pcReasons.get('effectiveDateChange')) {
            ////////
            ////////MISSING SEPARATIUON BETWEEN PAST AND FUTURE
            ////////
            manager.ActionsSelected.add('effectiveDateChange');

            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped'); 
            actionsToExecute.add('createUWCase'); //review
            actionsToExecute.add('createUWCaseMembers');
            actionsToExecute.add('insertContract');
            actionsToExecute.add('createCLI');
            //actionsToExecute.add('createChargentOrders');
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
            /* TO ADD START */
            actionsToExecute.add('upsertMedicalQuesitons');
            /* TO ADD END */
            actionsToExecute.add('createChargentOrders');
        }
        if (manager.pcReasons.containsKey('removeMember') && (Boolean) manager.pcReasons.get('removeMember')) {
            manager.ActionsSelected.add('removeMember');

            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped'); 
            actionsToExecute.add('createUWCase');
            actionsToExecute.add('createUWCaseMembers');
            actionsToExecute.add('insertContract');
            actionsToExecute.add('createCLI');
            actionsToExecute.add('createChargentOrders');
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
            actionsToExecute.add('createChargentOrders');
        }
        executeActions(actionsToExecute);        
    }


    private void executeActions(Set<String> actions){
        List<Map<String,Object>> censusMembers = getCensusMembers();
        for(String action : actions){
            if(action == 'updateGCMprimaryChange'){
                try {
                    updateGCM('primaryChange');
                } catch (Exception e) {
                    System.debug('error execute action 1');
                }            
            }
            else if(action == 'upsertGuardian'){
                try {
                    upsertGuardian(); 
                } catch (Exception e) {
                    System.debug('error execute action2');
                }
                  
            }
            else if(action == 'insertCaseForFeedSkipped'){
                try {
                    insertCaseForFeedSkipped();
                } catch (Exception e) {
                    System.debug('error execute action3');
                }            
            }
            else if(action == 'updateGCMaddressStateChange'){
                try {
                    updateGCM('addressStateChange');
                } catch (Exception e) {
                    System.debug('error execute action4');
                }
           
            }
            else if(action == 'updateGCMrelationshipToPrimaryChange'){
                try {
                    updateGCM('relationshipToPrimaryChange');
                } catch (Exception e) {
                    System.debug('error execute action5');
                }
                
            }
            else if(action == 'updateGCMdateOfBirthChange'){
                try {
                    updateGCM('dateOfBirthChange');
                } catch (Exception e) {
                    System.debug('error execute action6');
                }
                
            }
            else if(action == 'upsertGuardian'){
                try {
                    upsertGuardian();
                } catch (Exception e) {
                    System.debug('error execute action7');
                }
                
            }
            else if(action == 'updateGCMaddMember'){
                try {

                    updateGCM('addMember');
                } catch (Exception e) {
                    System.debug('error execute action8');
                }
                
            }
            else if(action == 'updateGCMaddExistingMember'){
                try {
                    updateGCM('addExistingMember');
                } catch (Exception e) {
                    System.debug('error execute action9');
                }
                
            }
            else if(action == 'updateGCMremoveMember'){

            
            }
            else if(action == 'updateGCMremoveAllAncillary'){

            } 
            else if(action == 'createUWCase') {
                try {
                    handlerUWCases();
                } catch (Exception e) {
                    System.debug('error execute action10');
                }
                    
            }
            else if(action == 'createUWCaseMembers') {
                try {
                    handlerUWCaseMembers();
                } catch (Exception e) {
                    System.debug('error execute action11');
                }
            
            }
            else if(action == 'updateContract'){
                try {    
                    upsertContracts('Update');
                } catch (Exception e) {
                    System.debug('error execute action12');
                }
            }
            else if(action == 'insertContract'){
                try {
                    upsertContracts('Insert');
                } catch (Exception e) {
                    System.debug('error execute action13');
                }
            }
            else if(action == 'createCLI'){
                try {    
                    createContractLineItems('Insert');
                } catch (Exception e) {
                    System.debug('error execute action14');
                }
            }
            /* TO ADD START */
            else if(action == 'upsertMedicalQuesitons'){
                try {    
                    upsertMedicalQuesitons();
                } catch (Exception e) {
                    System.debug('error execute action upsertMedicalQuesitons');
                }
            }              
            /* TO ADD END */            
            else if(action == 'createChargentOrders'){
                try {
                    createChargentOrders('Recurring');
                } catch (Exception e) {
                    System.debug('error execute action removeMember');
                }
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
                    if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false && member.containsKey('IsInactiveMember') && (Boolean)member.get('IsInactiveMember') == true){                
                        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();
                        /////////MISSING MAPPINGS
                        /////////
                        /////////


                          
                        // Need to confirm what to do Here:censusMember.vlocity_ins__MemberIdentifier__c = member.containsKey('vlocity_ins__MemberIdentifier__c') ? (String)member.get('vlocity_ins__MemberIdentifier__c') : null;
                        // Need to confirm what to do Here: censusMember.vlocity_ins__PrimaryMemberIdentifier__c = member.containsKey('vlocity_ins__PrimaryMemberIdentifier__c') ? (String)member.get('vlocity_ins__PrimaryMemberIdentifier__c') : null;
                        // Need to confirm what to do Here: 
                        // Not yet in JSON: censusMember.vlocity_ins__HasSpouse__c = member.containsKey('vlocity_ins__HasSpouse__c') ? (Boolean)member.get('vlocity_ins__HasSpouse__c') : null;
                                        
                        if(member.containsKey('IsNewMember') && !(Boolean)member.get('IsNewMember')){
                            censusMember.Id =(Id)(member.containsKey('Id') ? member.get('Id') : 'null');
                        }
                                       
                              
                        censusMember.ARC_HeightFeet__c = member.containsKey('ARC_HeightFeet__c') ? String.valueOf(member.get('ARC_HeightFeet__c')) : null;
                        censusMember.ARC_HeightInches__c = member.containsKey('ARC_HeightInches__c') ? String.valueOf(member.get('ARC_HeightInches__c')) : null;
                        censusMember.ARC_PhysicalAddressCity__c = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                        censusMember.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? (String)member.get('ARC_PhysicalAddressState__c') : null;
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
                         
                        // When the memeber is th primary is because theres a primary change
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
                        
                        /*  
                        else{
                            // This can never happen because we are adding new members and not changing the primary.
                            if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Primary'){
                                censusMember.ARC_DependentRelationship__c = '';
                                censusMember.vlocity_ins__IsPrimaryMember__c = true;
                            }
                            
                            if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') != 'Primary'){
                                censusMember.ARC_DependentRelationship__c = (String)member.get('ARC_Relationship__c');   
                                censusMember.vlocity_ins__IsPrimaryMember__c = false;
                            }
                            if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Spouse'){
                                censusMember.vlocity_ins__IsSpouse__c = true;
                            }
                            censusMember.vlocity_ins__RelatedCensusMemberId__c = oldPrimaryValues.get('Id');
                            censusMember.vlocity_ins__PrimaryMemberIdentifier__c = oldPrimaryValues.get('vlocity_ins__MemberIdentifier__c');
                        }*/
                        //Add Census Member to List
                        System.debug('censusMemberToAdd ' + censusMember);
                        manager.censusMembersToUpdate.add(censusMember);
                    }                       
                }            
            }
            catch(Exception e){
                System.debug('Exception updateGCM.addExistingMember ' + e.getMessage());
                throw e;
            }
        }
        else if(action == 'addMember'){
            try{
                for (Map<String,Object> member : censusMembers) {      
                    //CM Mapping
                    if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == true ){
                        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();

                        /////////MISSING MAPPINGS
                        /////////
                        ///////// 

                        // Need to confirm what to do Here:censusMember.vlocity_ins__MemberIdentifier__c = member.containsKey('vlocity_ins__MemberIdentifier__c') ? (String)member.get('vlocity_ins__MemberIdentifier__c') : null;
                        // Need to confirm what to do Here: censusMember.vlocity_ins__RelatedCensusMemberId__c = member.containsKey('vlocity_ins__RelatedCensusMemberId__c') ? (Id)member.get('vlocity_ins__RelatedCensusMemberId__c') : null;
                        // Not yet in JSON: censusMember.vlocity_ins__HasSpouse__c = member.containsKey('vlocity_ins__HasSpouse__c') ? (Boolean)member.get('vlocity_ins__HasSpouse__c') : null;
                        // Need PA Inseerted censusMember.vlocity_ins__ContactId__c = null;             
                        
                        
                        
                        censusMember.ARC_ActiveMember__c = false;              
                        censusMember.vlocity_ins__MemberIdentifier__c = member.containsKey('vlocity_ins__MemberIdentifier__c') ? (String)member.get('vlocity_ins__MemberIdentifier__c') : null;
                        censusMember.ARC_Phone__c = member.containsKey('ARC_Phone__c') ? (String)member.get('ARC_Phone__c') : null;
                        censusMember.ARC_HeightFeet__c = member.containsKey('ARC_HeightFeet__c') ? String.valueOf(member.get('ARC_HeightFeet__c')) : null;
                        censusMember.ARC_HeightInches__c = member.containsKey('ARC_HeightInches__c') ? String.valueOf(member.get('ARC_HeightInches__c')) : null;
                        censusMember.ARC_PhysicalAddressCity__c = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                        censusMember.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? (String)member.get('ARC_PhysicalAddressState__c') : null;
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
                        System.debug('censusMember ' + censusMember);
                       
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
                        System.debug('oldPrimaryValues ' + oldPrimaryValues);
                        
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
                System.debug('Exception updateGCM.addMember ' + e.getMessage());
                throw e;
            }
        }
        /*else if(action == 'primaryChange' || action == 'relationshipToPrimaryChange'){
            
            try{
                //ACA TODA ESTA LOGICA NO TIENE MAS SENTIDO PORQUE SE HACE DENTRO DE ADD MEMBER Y ADD EXITING MEMBER. PERO HAY QUE TENERLO EN CUENTA EN LA LOGICA DE LOS CONTRACT PARTICIPANT 
                    List<Map<String,Object>> censusMembersRelationship = getCensusMembers();
                    for(Map<String,Object> member : censusMembersRelationship){
                    if(member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false && member.containsKey('IsInactiveMember') && (Boolean)member.get('IsInactiveMember') == false){
                        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();
                        censusMember.Id =(Id)(member.containsKey('Id') ? member.get('Id') : 'null');                
                        if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Primary'){
                            censusMember.ARC_DependentRelationship__c = 'Future Primary';
                            censusMember.vlocity_ins__IsPrimaryMember__c = false;
                            //relatedCensusmemberId = currentPrimary.Id
                            //primarymemberIdentifier


                        }                
                        else if(member.containsKey('ARC_Relationship__c')){
                            censusMember.ARC_DependentRelationship__c = (String)member.get('ARC_Relationship__c');   
                            censusMember.vlocity_ins__IsPrimaryMember__c = false;
                        }
                        manager.censusMembersToUpdate.add(censusMember);
                    }               
                }             
            }             
            catch(Exception e){
                System.debug('Exception updateGCM.primaryChange ' + e.getMessage());
                throw e;
            }
                
        }*/
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
                System.debug('Exception updateGCM.dateOfBirthChange ' + e.getMessage());
                throw e;
            }
        }
        else if(action == 'addressStateChange'){
            try{
                List<Map<String,Object>> censusMembersAddressState = getCensusMembers();
                for(Map<String,Object> member : censusMembersAddressState){
                    if(member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false && member.containsKey('IsInactiveMember') && (Boolean)member.get('IsInactiveMember') == false){
                        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();
                        censusMember.Id =(Id)(member.containsKey('Id') ? member.get('Id') : 'null');
                        censusMember.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? (String)member.get('ARC_PhysicalAddressState__c') : null;
                        manager.censusMembersToUpdate.add(censusMember);
                    }    
                }
            }
            catch(Exception e){
                System.debug('Exception updateGCM.addressStateChange ' + e.getMessage());
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

                    Account newGuardian = new Account();
            
                    if (guardianInfo.containsKey('Id') && guardianInfo.get('Id') != null) {
                        newGuardian.Id = (Id)guardianInfo.get('Id');
                    }
            
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
                        newGuardian.BillingState = (String)addressBlock.get('TXT_GuardianState');
                    } 
                    newGuardian.ARC_GuardianRelationshipToChild__c = (String)guardianInfo.get('SEL_GuardianRelationship');
                    
                    manager.guardiansToInsert.add(newGuardian);
                }
            }
        } catch (Exception e) {
            System.debug('Exception Guardian: ' + e.getMessage());
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
            System.debug('Exception Case: ' + e.getMessage());
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
                
                if (addMember || addExistingMember || programUpgrade) {
                    newCase.ARC_Reason__c = 'Underwriting';
                    newCase.Case_Type__c = 'Underwriting';
                }
                else {
                    newCase.ARC_Reason__c = 'PC Approval';
                    newCase.Case_Type__c = 'PC Approval';
                }

                newCase.RecordTypeId = recordTypeId;
                newCase.Description = 'Underwriting';
                newCase.Origin = 'Internal Enrollment';
                newCase.Subject = 'Underwriting';
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
            System.debug('Exception handler UW Case: ' + e.getMessage());
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
            List<Map<String,Object>> censusMembers  = getCensusMembers();


            Map<String, Object> contractInfo = (Map<String, Object>)manager.inputMap.get('SelectedContractInfo');
            Id contractId = (Id)((Map<String, Object>)manager.inputMap.get('SelectedContractInfo')).get('ContractID');
            String contractStatus = (String)contractInfo.get('TXT_ContractStatus');

            // If Contract status is 'Awaiting Signature & Payment' or 'Awaiting Approval' copy the UW Case Members from the previous contract
            if (contractStatus == 'Awaiting Signature' || contractStatus == 'Awaiting Approval' || programUpgrade == true) {
                System.debug('Entra al caso de Awaiting Signature o Awaiting Approval');
                List<ARC_UnderwritingCaseMember__c> listUWCMToCopy = [SELECT ARC_ApprovalResolution__c, ARC_Member__c, ARC_PersonAccount__c, ARC_Reason__c, ARC_Score__c, Name, ARC_ReviewedBy__c, ARC_LastStatusUpdate__c, LastModifiedById, ARC_Description__c FROM ARC_UnderwritingCaseMember__c WHERE ARC_Contract__c =: contractId ];

                for (ARC_UnderwritingCaseMember__c UWCM : listUWCMToCopy) {
                    for (Map<String,Object> member : censusMembers) {
                        if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false && member.containsKey('Id') && 
                                (Id)member.get('Id') == UWCM.ARC_Member__c) { 
                                
                            try {
                                ARC_UnderwritingCaseMember__c newCaseMember = new ARC_UnderwritingCaseMember__c();
                                newCasemember.Name = UWCM.Name;
                                newCasemember.ARC_Member__c = UWCM.ARC_Member__c;
                                newCasemember.ARC_PersonAccount__c = UWCM.ARC_PersonAccount__c;
                                newCasemember.ARC_Reason__c = UWCM.ARC_Reason__c;
                                newCasemember.ARC_ApprovalResolution__c = 'Pending';

                                if (UWCM.ARC_LastStatusUpdate__c != null && UWCM.ARC_LastStatusUpdate__c.date().daysBetween(Date.today()) <= 60 ) {
                                    newCasemember.ARC_ApprovalResolution__c =  UWCM.ARC_ApprovalResolution__c;
                                    newCasemember.ARC_Score__c = UWCM.ARC_Score__c;
                                    newCasemember.ARC_ReviewedBy__c = UWCM.ARC_ReviewedBy__c;
                                    newCasemember.ARC_Description__c =  UWCM.ARC_Description__c;
                                }
                                manager.casesUWToInsert[0].ARC_Reason__c = 'Underwriting';
                                manager.censusMemberIdOrFakeIdToUWCM.put(newCaseMember.ARC_Member__c, newCaseMember);
                                     
                            } catch (Exception e) {
                                System.debug('Exception when trying to clone previous UWM Cases ' + e.getMessage());
                                throw e;
                            }
                        }
                    }
                }
            }

            // Convert the boolean values from pcReasons
            Boolean addMember = pcReasons.get('addMember') != null ? (Boolean)pcReasons.get('addMember') : false;
            Boolean addExistingMember = pcReasons.get('addExistingMember') != null ? (Boolean)pcReasons.get('addExistingMember') : false;
            Boolean removeMember = pcReasons.get('removeMember') != null ? (Boolean)pcReasons.get('removeMember') : false;
            
        
            // if the PC reasons are addMember, addExistingMember and/or removeMember
            if (addMember || addExistingMember || removeMember || programUpgrade) {

                for (Map<String, Object> cm : censusMembers) {
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
                    }
                    
                    try {
                        // if is a new member the reason must be add Member, but we dont have the Id census member for this users now
                        if ((Boolean)cm.get('IsNewMember') == true) {
                            newCaseMember.ARC_Reason__c = 'Add Member';
                            manager.censusMemberIdOrFakeIdToUWCM.put((String)cm.get('Id'), newCaseMember);

                        // if the new is an existing member the reason must be add member, in this case we have the census member id
                        } else if ((Boolean)cm.get('addExistingMember') == true) {
                            newCaseMember.ARC_Member__c = (Id)cm.get('Id');
                            newCaseMember.ARC_Reason__c = 'Add Member';
                            newCaseMember.ARC_PersonAccount__c = (Id)cm.get('PersonAccountId');
                            manager.censusMemberIdOrFakeIdToUWCM.put((String)cm.get('Id'), newCaseMember);

                        // if the member is remove the reason must be remove member
                        } else if ((Boolean)cm.get('IsRemoveMember') == true) {
                            newCaseMember.ARC_Member__c = (Id)cm.get('Id');
                            newCaseMember.ARC_Reason__c = 'Remove Member';
                            newCaseMember.ARC_PersonAccount__c = (Id)cm.get('PersonAccountId');
                            manager.censusMemberIdOrFakeIdToUWCM.put((String)cm.get('Id'), newCaseMember);
                            
                        // if is a program upgrade the reason of the UW Case Members that are not new or remove members must be Program Upgrade
                        } else if ((Boolean)cm.get('IsNewMember') == false  && (Boolean)cm.get('IsRemoveMember') == false && programUpgrade == true) {
                            newCaseMember.ARC_Member__c = (Id)cm.get('Id');
                            newCaseMember.ARC_Reason__c = 'Program Upgrade';
                            newCaseMember.ARC_PersonAccount__c = (Id)cm.get('PersonAccountId');
                            manager.censusMemberIdOrFakeIdToUWCM.put((String)cm.get('Id'), newCaseMember);
                        }
                    } catch (Exception e) {
                        System.debug('Exception creation of New UW Case Member' + e.getMessage());
                        throw e;
                    }	                  
                }

                System.debug('UwMToinsertLenght ' +  manager.censusMemberIdOrFakeIdToUWCM.values().size());
            }

        } catch (Exception e) {
            System.debug('Exception handler UW Case Member: ' + e.getMessage());
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
                
                // Get selected contract info
                Map<String, Object> selectedContractInfo = (Map<String, Object>)manager.inputMap.get('SelectedContractInfo');               
                if(selectedContractInfo != null) {                    
                    newContract.AccountId = (String)selectedContractInfo.get('GroupAccountId');
                    newContract.Account_Name_Text__c = (String)selectedContractInfo.get('GroupAccountName');                    
                }
                
                // Get effective date
                Map<String, Object> effectiveDateMap = (Map<String, Object>)manager.inputMap.get('STEP_EffectiveDate');
                Map<String, Object> datePickerMap = (Map<String, Object>)effectiveDateMap.get('aRC_DatePicker');
                Date effectiveDate = Date.valueOf((String)datePickerMap.get('DATE_SubscriberEffectiveDate'));
                
                newContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_IndividualAndFamily').getRecordTypeId();
                
                // Get PC changes
                Map<String, Object> pcChanges = (Map<String, Object>)manager.inputMap.get('pcChanges');
                if(pcChanges != null) {
                    newContract.ARC_ContractReason__c = (String)pcChanges.get('pcReasonsString');
                }
                
                newContract.ARC_Selling_Agent__c = (String)manager.inputMap.get('userId');
                
                if(guardianInfo != null && guardianInfo.containsKey('Id')) {
                    newContract.ARC_Guardian__c = (Id)guardianInfo.get('Id');
                }
                
                newContract.ARC_EffectiveDate__c = effectiveDate;
                newContract.Status = 'Draft';//'Awaiting Signature';
                newContract.vlocity_ins__EnrollmentCensusId__c = (Id)manager.inputMap.get('CensusId');
                
                if(selectedContractInfo != null && selectedContractInfo.containsKey('ContractID')) {
                    newContract.vlocity_ins__ExpiredContractId__c = (Id)selectedContractInfo.get('ContractID');
                }
                
                newContract.StartDate = effectiveDate;
                newContract.ContractTerm = 12;
                
                manager.contractsToInsert.add(newContract);
                
            }
            catch(Exception e){
                System.debug('Exception mapContractsToCreate.Insert ' + e.getMessage());
                throw e;
            }
        }
        else if(action == 'Update') {
            try{
                Map<String, Object> effectiveDateMap = (Map<String, Object>)manager.inputMap.get('STEP_EffectiveDate');
                Map<String, Object> datePickerMap = (Map<String, Object>)effectiveDateMap.get('aRC_DatePicker');
                System.debug('datePickerMap ' + datePickerMap);
                Date effectiveDate = Date.valueOf((String)datePickerMap.get('DATE_SubscriberEffectiveDate'));                
                Contract contractToUpdate = new Contract();
                Map<String, Object> SelectedContractInfo = (Map<String, Object>)manager.inputMap.get('SelectedContractInfo');
                contractToUpdate.Id = (Id)SelectedContractInfo.get('ContractID');
                contractToUpdate.ARC_EffectiveDate__c = effectiveDate;
                System.debug('contractToUpdate ' + contractToUpdate);
                //manager.contractsToInsert.add(contractToUpdate);
            } 
            catch(Exception e){
                System.debug('Exception mapContractsToCreate.Update ' + e.getMessage());
                throw e;
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   mapContractLineItemsToCreate
    * @Description        :   map Contract Line Items to create
    ********************************************************************/   
    private void createContractLineItems(String action) {
        System.debug('createContractLineItems ' + action);
        Map<String, Object> productToMembersMap = getProductsWithMembers();
        if(action == 'Insert' && productToMembersMap != null && !productToMembersMap.isEmpty()) {
            Integer index = 0;
            System.debug('productToMembersMap ' + productToMembersMap);
            try{
                // Get the contract effective date
                Map<String, Object> effectiveDateMap = (Map<String, Object>)manager.inputMap.get('STEP_EffectiveDate');
                Map<String, Object> datePickerMap = (Map<String, Object>)effectiveDateMap.get('aRC_DatePicker');
                Date contractEffectiveDate = Date.valueOf((String)datePickerMap.get('DATE_SubscriberEffectiveDate'));
                System.debug('contractEffectiveDate ' + contractEffectiveDate);
                
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
                        medicalLineItem.vlocity_ins__EffectiveStartDate__c = DateTime.newInstance(contractEffectiveDate, Time.newInstance(0, 0, 0, 0));                        
                        
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
                        System.debug('Exception mapContractLineItemsToCreate medicalLineItem ' + e.getMessage());
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
                                //manager.ParentToChildCLI.get(medicalLineItem).add(medicalChildLineItem);  

                                /*
                                if(!manager.ParentToChildCLI.containsKey(medicalLineItem)){
                                    manager.ParentToChildCLI.put(medicalLineItem,new List<vlocity_ins__ContractLineItem__c>{medicalChildLineItem});
                                }
                                else{
                                    manager.ParentToChildCLI.get(medicalLineItem).add(medicalChildLineItem);
                                }
                                */
                            }
                        }
                    }
                    catch(Exception e){
                        System.debug('Exception mapContractLineItemsToCreate medicalChildLineItem ' + e.getMessage());
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
                            ancillaryLineItem.vlocity_ins__EffectiveStartDate__c = DateTime.newInstance(contractEffectiveDate, Time.newInstance(0, 0, 0, 0));
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
                    System.debug('Exception mapContractLineItemsToCreate ancillaryLineItem ' + e.getMessage());
                    throw e;
                }


                // Process Ancillary Child Products
               /* 
                try {
                    List<Map<String, Object>> ancillaryChildProducts = (List<Map<String, Object>>)productToMembersMap.get('AncillaryChildProducts');
                    if(ancillaryChildProducts != null && !ancillaryChildProducts.isEmpty()) {
                        for(Map<String, Object> ancillaryChildProduct : ancillaryChildProducts) {
                            Map<String, Object> childProduct = (Map<String, Object>)ancillaryChildProduct.get('product');
                            if((String)childProduct.get('RecordTypeName__c') == 'CoverageSpec'  ){
                                vlocity_ins__ContractLineItem__c ancillaryChildLineItem = new vlocity_ins__ContractLineItem__c();
                                ancillaryChildLineItem.Name = (String)childProduct.get('Name');
                                ancillaryChildLineItem.vlocity_ins__Product2Id__c = (Id)childProduct.get('Id');
                                ancillaryChildLineItem.vlocity_ins__AccountId__c = accountId;
                                ancillaryChildLineItem.vlocity_ins__ProductId__c = (Id)childProduct.get('Id');                                
                                manager.contractLineItemsToInsert.add(ancillaryChildLineItem);  
                            }                 
                        }
                    }
                    System.debug('manager.contractLineItemsToInsert ' + manager.contractLineItemsToInsert);
                }
                catch(Exception e){
                    System.debug('Exception mapContractLineItemsToCreate ancillaryChildLineItem ' + e.getMessage());
                    throw e;
                }
                */                
            }
            catch(Exception e){
                System.debug('Exception mapContractLineItemsToCreate ' + e.getMessage());
                throw e;
            }
        }        
    }
   

    /*******************************************************************
    * @MethodName         :   upsertMedicalQuesitons
    * @Description        :   insert new Medical Quesionts and update (inactive) old Medical Quesions for related members
    ********************************************************************/
    private void upsertMedicalQuesitons() {
        system.debug('upsertMedicalQuesitons IN ');
        try {

            if((Map<String, Object>)manager.inputMap.get('STEP_MedicalQuestions') != null){

                Map<String, Object> stepMedicalQuestions = (Map<String, Object>)manager.inputMap.get('STEP_MedicalQuestions');
                Map<String, Object> pcReasons = (Map<String, Object>)((Map<String, Object>)manager.inputMap.get('pcChanges')).get('pcReasons');
                List<Map<String,Object>> censusMembers = getCensusMembers();

                Boolean haveAddMember = (Boolean)pcReasons.get('addMember');
                Boolean haveProgramUpgrade = (Boolean)pcReasons.get('programUpgrade');

                Map<String, Map<String, Object>> oldMembers = new Map<String, Map<String, Object>>();

                Set<Id> oldMembersIds = new Set<Id>();

                if (censusMembers != null) {
                    for (Map<String, Object> member : censusMembers) {
                        Boolean isRemoveMember = (Boolean) member.get('IsRemoveMember');
                        Boolean isNewMember = (Boolean) member.get('IsNewMember');
                        String censusId = (String) member.get('Id');
                        String accountId = (String) member.get('PersonAccountId');
                
                        if (isRemoveMember == false && isNewMember == false && String.isNotBlank(censusId) && String.isNotBlank(accountId)) {
                            Map<String, Object> memberInfo = new Map<String, Object>();
                            memberInfo.put('censusId', censusId);
                            memberInfo.put('accountId', accountId); 
                
                            oldMembers.put(censusId, memberInfo);
                            oldMembersIds.add((Id)member.get('Id'));
                        }
                    }
                }
                                
                // We need to retrieve active medical questions (ARC_MedicalConditions__c and vlocity_ins__ConsumerDrug__c) for old members to deactivate before we insert new ones if programupgrade is true
                if(haveProgramUpgrade && !oldMembersIds.isEmpty()){
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

                            mcC.Name = (String)recordMap.get('TXT_MemberNameCancer')+'-Medical Condition';
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
                
                system.debug('upsertMedicalQuesitons OUT ');
            }
        } catch  (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
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
            Id contractId = (Id)SelectedContractInfo.get('ContractID');
            Id groupAccountId = (Id)SelectedContractInfo.get('GroupAccountId');

            //Query previous Chargent Order      
            ChargentOrders__ChargentOrder__c oldChOr = [SELECT Id,ChargentOrders__Charge_Date__c, ChargentOrders__Bank_Routing_Number__c,ChargentOrders__Bank_Account_Number__c,ChargentOrders__Bank_Account_Type__c,ChargentOrders__Bank_Name__c,ChargentOrders__Billing_First_Name__c,ARC_FirstMonthPayed__c , ChargentOrders__Billing_Last_Name__c, ChargentOrders__Billing_Address__c, ChargentOrders__Billing_City__c, ChargentOrders__Billing_State__c, ChargentOrders__Billing_Zip_Postal__c, ChargentOrders__Card_Expiration_Month__c, ChargentOrders__Card_Expiration_Year__c, ChargentOrders__Card_Last_4__c, ChargentOrders__Card_Month_Indicator__c, ChargentOrders__Card_Number__c, ChargentOrders__Card_Type__c, ChargentOrders__Card_Year_Indicator__c, ChargentOrders__Charge_Amount__c, ChargentOrders__Description__c, ChargentOrders__Gateway__c, ChargentOrders__Payment_Frequency__c, ChargentOrders__Payment_Method__c, ChargentOrders__Payment_Status__c, ChargentOrders__Subtotal__c, ChargentOrders__Manual_Charge__c FROM ChargentOrders__ChargentOrder__c WHERE ARC_Contract__c =: contractId LIMIT 1];
            
            if(manager.inputMap.containsKey('pcChanges') && (Boolean)pcChanges.get('feeApplicable') == true){
                ChargentOrders__ChargentOrder__c newCOChangeFee = new ChargentOrders__ChargentOrder__c();

                Map<String, Object> primaryMember = (Map<String, Object>)manager.inputMap.get('PrimaryMember');            
                Map<String, Object> Step_PaymentChangeFee = (Map<String, Object>)manager.inputMap.get('Step_PaymentChangeFee');
                
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
                if(Step_PaymentChangeFee.containsKey('BLK_ChargeFee')){
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
                        System.debug('createChargentOrders 7');
                        newCOChangeFee.ARC_FirstMonthPayed__c = false;
                        newCOChangeFee.ChargentOrders__Description__c = 'Change Fee';   
                        newCOChangeFee.ChargentOrders__Payment_Status__c = null;
                        newCOChangeFee.ChargentOrders__Subtotal__c = (Decimal)pcChanges.get('feeAmount');
                        newCOChangeFee.ChargentOrders__Charge_Amount__c = (Decimal)pcChanges.get('feeAmount');
                        newCOChangeFee.ChargentOrders__Payment_Frequency__c = 'Once';
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
                                }
                                catch(Exception e){
                                    System.debug(e.getMessage());
                                    System.debug(e.getStackTraceString());
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
                            System.debug(e.getMessage());
                            System.debug(e.getStackTraceString());
                        }
                    }
                }
                manager.chargentOrdersChangeFee.add(newCOChangeFee);  
            }
            //Change Fee
            if(action == 'Recurring'){
                ChargentOrders__ChargentOrder__c newCORecurring = new ChargentOrders__ChargentOrder__c();
                //newCOChangeFee.ARC_Contract__c =       
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
                    
                    //newCORecurring.ChargentOrders__Charge_Date__c = oldChOr.ChargentOrders__Charge_Date__c;
                    newCORecurring.ChargentOrders__Description__c = 'Recurring Monthly Order';
                    newCORecurring.ChargentOrders__Gateway__c = oldChOr.ChargentOrders__Gateway__c;
                    newCORecurring.ChargentOrders__Payment_Frequency__c = 'Monthly';
                    newCORecurring.ChargentOrders__Payment_Method__c = oldChOr.ChargentOrders__Payment_Method__c;
                    newCORecurring.ChargentOrders__Payment_Start_Date__c  = Date.today();
                    newCORecurring.ChargentOrders__Payment_Status__c = 'Stopped';
                    newCORecurring.ChargentOrders__Subtotal__c = Decimal.valueOf(((String)BLK_ProductSummary.get('TXT_MonthlyPrice')).remove('$').trim());
                    newCORecurring.ChargentOrders__Manual_Charge__c  = true;
            
                    manager.chargentOrdersRecurringOrder.add(newCORecurring);
                }      
                catch(Exception e){
                    System.debug(e.getMessage());
                    System.debug(e.getStackTraceString());
                }            
            }
        }
        catch(Exception e){
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
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
                manager.primaryCensusMemberWithId = primary;
                Account primaryAccount = new Account();
                primaryAccount.Id = member.containsKey('PersonAccountId') ? (String)member.get('PersonAccountId') : null;
                manager.censusMemberToAccount.put((String)member.get('Id'), primaryAccount);
                System.debug('primaryAccount' + primaryAccount);
            }
            censusMembers.add(member);
        }
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
        System.debug('getProductsWithMembers IN');
        if(manager.inputMap.containsKey('price_calculation')) {
            Map<String,Object> priceCalculation = (Map<String,Object>)manager.inputMap.get('price_calculation');
            if(priceCalculation.containsKey('plans')) {
                List<Object> plans = (List<Object>)priceCalculation.get('plans');
                System.debug('plans getProductsWithMembers' + plans.size() + ' ' + plans);
                
                
                
                for(Object planObj : plans) {
                    Map<String,Object> plan = (Map<String,Object>)planObj;
                    Map<String,Object> selectedProduct = (Map<String,Object>)plan.get('selectedProduct');
                    String productType = (String)selectedProduct.get('Type__c');
                    System.debug('productType getProductsWithMembers' + productType);
                    
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
                        System.debug('productTypeAncillary == ' + productType);
                        Map<String,Object> childProducts = (Map<String,Object>)selectedProduct.get('childProducts');
                        List<Map<String,Object>> coverageSpecs = new List<Map<String,Object>>();
                        List<Object> childProductsList;

                        if(childProducts.containsKey('records')){
                            childProductsList = (List<Object>)childProducts.get('records');
                       }                       
                        for(Object childProductObj : childProductsList){
                            Map<String,Object> childProduct = (Map<String,Object>)childProductObj;
                            if(childProduct.containsKey('RecordTypeName__c') && (String)childProduct.get('RecordTypeName__c') == 'CoverageSpec'){
                                System.debug('CLIcheck insideRecordTypeChild');
                                coverageSpecs.add(childProduct);
                            }
                        }
        
                   
                        ancillaryProducts.add(new Map<String,Object>{
                            'product' => selectedProduct,
                            'members' => members,
                            'priceData' => selectedProduct.get('RawPriceData'),
                            'childProducts' => coverageSpecs
                        });                      


                        
                        /*
                        // Process child products if they exist
                        if(selectedProduct.containsKey('childProducts')) {
                            Map<String,Object> childProducts2 = (Map<String,Object>)selectedProduct.get('childProducts');
                            if(childProducts2.containsKey('records')) {
                                List<Object> childRecords = (List<Object>)childProducts2.get('records');
                                for(Object childRecord : childRecords) {
                                    Map<String,Object> childProduct = (Map<String,Object>)childRecord;
                                    ancillaryChildProducts.add(new Map<String,Object>{
                                        'product' => childProduct,
                                        'members' => members
                                    });                                   
                                }
                            }
                        }
                            */
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

        /* TO ADD START */

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
     * Processes a list of data records for a specific medical condition block
     * and updates the provided medical condition map.
     *
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
                        mc.Name = memberName + '-Medical Condition';
                        mc.ARC_Active__c = true;
                        medicalConditionMap.put(memberId, mc);
                    }
                }
            }
        }
    }
}