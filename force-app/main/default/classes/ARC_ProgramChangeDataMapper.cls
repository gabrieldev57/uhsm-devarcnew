/**
 * @Description: This class is responsible for mapping and transforming input data into Salesforce objects.
 * It handles different types of program changes and prepares the data for database operations.
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-04-15
 * @Version: 1.0
 */

 public with sharing class ARC_ProgramChangeDataMapper {   
    private ARC_ProgramChangeInsertManager manager;

    private Set<String> actionsToExecute = new Set<String>();

    /**
     * @Description: Main method that executes the data mapping process
     * @param manager: The InsertManager instance containing the data to be mapped
     */
    public void executeChanges(ARC_ProgramChangeInsertManager manager) {
        this.manager = manager;
        
              
        // Collect actions with their corresponding actions to perform
        if (manager.pcReasons.containsKey('primaryChange') && (Boolean) manager.pcReasons.get('primaryChange')) {            
            manager.ActionsSelected.add('primaryChange');
            //Methods to exexcute on primary change
            actionsToExecute.add('updateGCMprimaryChange');
            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped');
            actionsToExecute.add('insertContract');


        }
        if (manager.pcReasons.containsKey('addressStateChange') && (Boolean) manager.pcReasons.get('addressStateChange')) {
            manager.ActionsSelected.add('addressStateChange');

            actionsToExecute.add('updateGCMaddressStateChange');
            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped');
            actionsToExecute.add('insertContract');
        }
        if (manager.pcReasons.containsKey('relationshipToPrimaryChange') && (Boolean) manager.pcReasons.get('relationshipToPrimaryChange')) {
            manager.ActionsSelected.add('relationshipToPrimaryChange');

            actionsToExecute.add('updateGCMrelationshipToPrimaryChange');
            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped');
            actionsToExecute.add('insertContract');
        }
        if (manager.pcReasons.containsKey('dateOfBirthChange') && (Boolean) manager.pcReasons.get('dateOfBirthChange')) {            
            manager.ActionsSelected.add('dateOfBirthChange');

            actionsToExecute.add('updateGCMdateOfBirthChange');
            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped');
            actionsToExecute.add('insertContract');
        }
        // Program and Effective Date Changes
        if (manager.pcReasons.containsKey('programUpgrade') && (Boolean) manager.pcReasons.get('programUpgrade')) {
            manager.ActionsSelected.add('programUpgrade');

            actionsToExecute.add('upsertMedicalQuesitons');
            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped');
            actionsToExecute.add('insertContract'); 
        }
        if (manager.pcReasons.containsKey('programDowngrade') && (Boolean) manager.pcReasons.get('programDowngrade')) {
            manager.ActionsSelected.add('programDowngrade');

            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped');
            actionsToExecute.add('insertContract');
        }
        if (manager.pcReasons.containsKey('ancillaryChange') && (Boolean) manager.pcReasons.get('ancillaryChange')) {
            manager.ActionsSelected.add('ancillaryChange');

            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped');
            actionsToExecute.add('insertContract'); 
        }
        if (manager.pcReasons.containsKey('removeAllAncillary') && (Boolean) manager.pcReasons.get('removeAllAncillary')) {            
            manager.ActionsSelected.add('removeAllAncillary');

            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped'); 
            actionsToExecute.add('insertContract');
        }
        if (manager.pcReasons.containsKey('effectiveDateChange') && (Boolean) manager.pcReasons.get('effectiveDateChange')) {
            manager.ActionsSelected.add('effectiveDateChange');

            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped'); 
        }
        // Add/Remove Member Changes
        if (manager.pcReasons.containsKey('addMember') && (Boolean) manager.pcReasons.get('addMember')) {
            manager.ActionsSelected.add('addMember');

            actionsToExecute.add('updateGCMaddMember');
            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('upsertMedicalQuesitons');
            actionsToExecute.add('insertCaseForFeedSkipped');
            actionsToExecute.add('insertContract');
        }
        if (manager.pcReasons.containsKey('removeMember') && (Boolean) manager.pcReasons.get('removeMember')) {
            manager.ActionsSelected.add('removeMember');

            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped'); 
            actionsToExecute.add('insertContract');
        }
        if (manager.pcReasons.containsKey('addExistingMember') && (Boolean) manager.pcReasons.get('addExistingMember')) {
            manager.ActionsSelected.add('addExistingMember');

            actionsToExecute.add('updateGCMaddExistingMember');
            actionsToExecute.add('upsertGuardian');
            actionsToExecute.add('insertCaseForFeedSkipped'); 
            actionsToExecute.add('insertContract');
        }
        executeActions(actionsToExecute);        
    }


    private void executeActions(Set<String> actions){
        for(String action : actions){
           if(action == 'updateGCMprimaryChange'){
            updateGCM('primaryChange');
           }
           else if(action == 'upsertGuardian'){
            upsertGuardian();       
           }
           else if(action == 'insertCaseForFeedSkipped'){
            insertCaseForFeedSkipped();
           }
           else if(action == 'updateGCMaddressStateChange'){
            updateGCM('addressStateChange');
           }
           else if(action == 'updateGCMrelationshipToPrimaryChange'){
            updateGCM('relationshipToPrimaryChange');
           }
           else if(action == 'updateGCMdateOfBirthChange'){
            updateGCM('dateOfBirthChange');
           }
           else if(action == 'upsertGuardian'){
            upsertGuardian();
           }
           else if(action == 'updateGCMaddMember'){
            updateGCM('addMember');
           }
           else if(action == 'updateGCMaddExistingMember'){
            updateGCM('addExistingMember');
           }
           else if(action == 'updateGCMremoveMember'){
           
           }
           else if(action == 'updateGCMremoveAllAncillary'){

           }  
           else if(action == 'upsertMedicalQuesitons'){
                upsertMedicalQuesitons();
           }
           else if(action == 'updateContract'){
                upsertContracts('Update');
            }
            else if(action == 'insertContract'){
                upsertContracts('Insert');
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   updateGCM  
    * @Description        :   Method to handle add existing member
    ********************************************************************/
    private void updateGCM(String action) { 
        List<Map<String,Object>> censusMembers = getCensusMembers();
        String PrimaryMemberIdentifier = null;
        Id primaryId = null;
        try{            
            for (Map<String,Object> member : censusMembers) { 
                if(member.containsKey('vlocity_ins__MemberIdentifier__c') && (String)member.get('ARC_Relationship__c') == 'Primary'){
                    PrimaryMemberIdentifier = (String)member.get('vlocity_ins__MemberIdentifier__c');
                    primaryId = (Id)member.get('Id');
                }
            }
        }
        catch(Exception e){
            System.debug('Exception updateGCMPrimaryId: ' + e.getMessage());
            throw e;
        }
        
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
                        if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Primary'){
                            censusMember.ARC_DependentRelationship__c = '';
                            censusMember.vlocity_ins__IsPrimaryMember__c = true;
                        }                
                        else if(member.containsKey('ARC_Relationship__c')){
                            censusMember.ARC_DependentRelationship__c = (String)member.get('ARC_Relationship__c');   
                            censusMember.vlocity_ins__IsPrimaryMember__c = false;
                            censusMember.vlocity_ins__RelatedCensusMemberId__c = primaryId;
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
                        censusMember.vlocity_ins__IsPrimaryMember__c = member.containsKey('vlocity_ins__IsPrimaryMember__c') ? convertToBoolean(member.get('vlocity_ins__IsPrimaryMember__c')) : null;
                        censusMember.vlocity_ins__SocialSecurityNumber__c = member.containsKey('vlocity_ins__SocialSecurityNumber__c') ? (String)member.get('vlocity_ins__SocialSecurityNumber__c') : null;
                        if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Spouse'){
                            censusMember.vlocity_ins__IsSpouse__c = true;
                        }                        
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
                    if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == true && !(Boolean)member.get('IsInactiveMember') ){
                        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();

                        /////////MISSING MAPPINGS
                        /////////
                        ///////// 

                        // Need to confirm what to do Here:censusMember.vlocity_ins__MemberIdentifier__c = member.containsKey('vlocity_ins__MemberIdentifier__c') ? (String)member.get('vlocity_ins__MemberIdentifier__c') : null;
                        // Need to confirm what to do Here: censusMember.vlocity_ins__RelatedCensusMemberId__c = member.containsKey('vlocity_ins__RelatedCensusMemberId__c') ? (Id)member.get('vlocity_ins__RelatedCensusMemberId__c') : null;
                        // Not yet in JSON: censusMember.vlocity_ins__HasSpouse__c = member.containsKey('vlocity_ins__HasSpouse__c') ? (Boolean)member.get('vlocity_ins__HasSpouse__c') : null;
                        // Need PA Inseerted censusMember.vlocity_ins__ContactId__c = null;             
                        
                        if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Primary'){
                            censusMember.ARC_DependentRelationship__c = '';
                            censusMember.vlocity_ins__IsPrimaryMember__c = true;
                        }                
                        else if(member.containsKey('ARC_Relationship__c')){
                            censusMember.ARC_DependentRelationship__c = (String)member.get('ARC_Relationship__c');   
                            censusMember.vlocity_ins__IsPrimaryMember__c = false;
                            censusMember.vlocity_ins__PrimaryMemberIdentifier__c = PrimaryMemberIdentifier; 
                            censusMember.vlocity_ins__RelatedCensusMemberId__c = primaryId;
                        }
                        if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Spouse'){
                            censusMember.vlocity_ins__IsSpouse__c = true;
                        }
                        censusMember.ARC_ActiveMember__c = false;
                        DateTime now = DateTime.now();
                        String timestamp = now.format('yyyyMMddHHmmss'); 
                        Integer randomSuffix = Math.mod(Crypto.getRandomInteger(), 1000); 
                        String uniqueId = timestamp + String.valueOf(randomSuffix);                
                        censusMember.vlocity_ins__MemberIdentifier__c = uniqueId;
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
                        censusMember.vlocity_ins__IsPrimaryMember__c = member.containsKey('vlocity_ins__IsPrimaryMember__c') ? convertToBoolean(member.get('vlocity_ins__IsPrimaryMember__c')) : null;
                        censusMember.vlocity_ins__SocialSecurityNumber__c = member.containsKey('vlocity_ins__SocialSecurityNumber__c') ? (String)member.get('vlocity_ins__SocialSecurityNumber__c') : null;
                        System.debug('censusMember ' + censusMember);
                        //Add to global list
                        manager.temporalIdToCensusMembers.put((String)member.get('Id'), censusMember);
                        manager.censusMemberByTemporalId.put((String)member.get('Id'), censusMember);
                        manager.censusMembersToInsert.add(censusMember);
                        for(String key : manager.censusMemberByTemporalId.keySet()){
                            manager.censusMemberByTemporalId.get(key).Id = null; 
                        }
                    }
                }             
            }
            catch(Exception e){
                System.debug('Exception updateGCM.addMember ' + e.getMessage());
                throw e;
            }
        }
        else if(action == 'primaryChange' || action == 'relationshipToPrimaryChange'){
            try{
                    List<Map<String,Object>> censusMembersRelationship = getCensusMembers();
                    for(Map<String,Object> member : censusMembersRelationship){
                    if(member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false && member.containsKey('IsInactiveMember') && (Boolean)member.get('IsInactiveMember') == false){
                        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();
                        censusMember.Id =(Id)(member.containsKey('Id') ? member.get('Id') : 'null');                
                        if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Primary'){
                            censusMember.ARC_DependentRelationship__c = '';
                            censusMember.vlocity_ins__IsPrimaryMember__c = true;
                            PrimaryMemberIdentifier = (String)member.get('vlocity_ins__MemberIdentifier__c');
                        }                
                        else if(member.containsKey('ARC_Relationship__c')){
                            censusMember.ARC_DependentRelationship__c = (String)member.get('ARC_Relationship__c');   
                            censusMember.vlocity_ins__IsPrimaryMember__c = false;
                            censusMember.vlocity_ins__PrimaryMemberIdentifier__c = PrimaryMemberIdentifier;
                            if(primaryId != null){
                                censusMember.vlocity_ins__RelatedCensusMemberId__c = primaryId;
                            }
                        }
                        manager.censusMembersToUpdate.add(censusMember);
                    }               
                }             
            }             
            catch(Exception e){
                System.debug('Exception updateGCM.primaryChange ' + e.getMessage());
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
           
            if ((Boolean)pcChanges.get('createNewContract') == true) {
                Map<String, Boolean> pcReasons = (Map<String, Boolean>)pcChanges.get('pcReasons');
                List<Map<String,Object>> censusMembers = getCensusMembers();
                Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admission').getRecordTypeId();

                Case newCase = new Case();

                //obtengo el ID del primary member solo si el primary no es un nuevo member
                for (Map<String, Object> m : censusMembers) {
                    if (((String)m.get('ARC_Relationship__c') == 'Primary') && ((Boolean)m.get('IsRemoveMember') == false) && ((Boolean)m.get('IsNewMember') == false)) {
                        newCase.ARC_CensusMember__c = (Id)m.get('Id');
                    }
                }
                
                if (((Boolean)pcReasons.get('addMember') == true) || ((Boolean)pcReasons.get('programUpgrade') == true)) {
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

                
                //newCase.ARC_CensusMember__c Id del primary si es un nuevo member
                // newCase.AccountId = GroupAccountId;
                // newCase.ARC_Contract__c = ContractId;
                // newCase.ARC_PersonAccount__c = PrimaryAccount.Id;
                // newCase.ContactId = PrimaryAccount.PersonContactId;
                
        
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
            Map<String, Boolean> pcReasons = (Map<String, Boolean>)pcChanges.get('pcReasons');

            List<Map<String,Object>> censusMembers = getCensusMembers();
            
            if (((Boolean)pcReasons.get('addMember') == true) || ((Boolean)pcReasons.get('removeMember') == true) || ((Boolean)pcReasons.get('programUpgrade') == true)) {
                for (Map<String, Object> m : censusMembers) {
                    ARC_UnderwritingCaseMember__c newCaseMember = new ARC_UnderwritingCaseMember__c();

                    if ((Boolean)m.get('IsNewMember') == true) {
                        newCaseMember.ARC_Reason__c = 'Add Member';
                        // newCaseMember.ARC_Member__c = m.Id; Tengo que obtener el ID luego de que se cree el census member
                    } else if ((Boolean)m.get('IsRemoveMember') == true) {
                        newCaseMember.ARC_Reason__c = 'Remove Member';
                        newCaseMember.ARC_Member__c = (Id)m.get('Id');
                    } else if ((Boolean)m.get('IsNewMember') != true && (Boolean)m.get('IsRemoveMember') != true) {
                        newCaseMember.ARC_Reason__c = 'Program Upgrade';
                        newCaseMember.ARC_Member__c = (Id)m.get('Id');
                    }

                    newCaseMember.ARC_ApprovalResolution__c = 'Pending';
                    // newCaseMember.ARC_Contract__c = Tengo que obtener el Id del nuevo contract
                    // newCaseMember.ARC_PersonAccount__c = Tengo que obtener el Id del person Account
                    // newCaseMember.ARC_UnderwritingCase__c = Tengo que obtener el Id del UW Case

                    manager.UWCaseMembersToInsert.add(newCaseMember);
                }
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
                System.debug('selectedContractInfo 1 ' + selectedContractInfo);
                if(selectedContractInfo != null) {
                    System.debug('selectedContractInfo 2 ' + selectedContractInfo);
                    newContract.AccountId = (String)selectedContractInfo.get('GroupAccountId');
                    newContract.Account_Name_Text__c = (String)selectedContractInfo.get('GroupAccountName');
                    System.debug('newContract acc ' + newContract.AccountId + 'newContract acc name ' + newContract.Account_Name_Text__c);
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
    private void mapContractLineItemsToCreate(String action) {
        Map<String, Object> productToMembersMap = getProductsWithMembers();
        if(action == 'Insert' && productToMembersMap != null && !productToMembersMap.isEmpty()) {
            try{
                // Get the contract effective date
                Map<String, Object> effectiveDateMap = (Map<String, Object>)manager.inputMap.get('STEP_EffectiveDate');
                Map<String, Object> datePickerMap = (Map<String, Object>)effectiveDateMap.get('aRC_DatePicker');
                Date contractEffectiveDate = (Date)datePickerMap.get('DATE_SubscriberEffectiveDate');
                
                // Get account ID
                Map<String, Object> selectedContractInfo = (Map<String, Object>)manager.inputMap.get('selectedContractInfo');
                String accountId = selectedContractInfo != null ? (String)selectedContractInfo.get('GroupAccountId') : null;
                
                
                Map<String, Object> medicalWithMembers = (Map<String, Object>)productToMembersMap.get('Medical');
                if(medicalWithMembers != null) {
                    Map<String, Object> medicalProduct = (Map<String, Object>)medicalWithMembers.get('product');
                    List<Object> medicalMembers = (List<Object>)medicalWithMembers.get('members');
                    // Process Medical Product
                    vlocity_ins__ContractLineItem__c medicalLineItem = new vlocity_ins__ContractLineItem__c();
                    medicalLineItem.vlocity_ins__AccountId__c = accountId;
                    medicalLineItem.Name = (String)medicalProduct.get('Name');
                    medicalLineItem.vlocity_ins__Product2Id__c = (Id)medicalProduct.get('Id');
                    medicalLineItem.vlocity_ins__UnitPrice__c = (Decimal)medicalProduct.get('Price');
                    medicalLineItem.vlocity_ins__Quantity__c = 1;
                    medicalLineItem.vlocity_ins__EffectiveStartDate__c = DateTime.newInstance(contractEffectiveDate, Time.newInstance(0, 0, 0, 0));
                    
                    manager.contractLineItemsToInsert.add(medicalLineItem);

                    for(Object member : medicalMembers){
                        Map<String,Object> memberMap = (Map<String,Object>)member;
                        if(memberMap.containsKey('CensusMemberId')){
                            manager.CMIdToCLI.get((Id)memberMap.get('CensusMemberId')).add(medicalLineItem);
                        }
                        else{
                            List<vlocity_ins__ContractLineItem__c> medicalLineItems = new List<vlocity_ins__ContractLineItem__c>();
                            medicalLineItems.add(medicalLineItem);
                            manager.CMIdToCLI.put((Id)memberMap.get('CensusMemberId'),medicalLineItems);
                        }
                    }
                    // Process Medical Child Products
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
                        }
                    }
                }

                // Process Ancillary Products
                List<Map<String, Object>> ancillaryProducts = (List<Map<String, Object>>)productToMembersMap.get('Ancillaries');
                if(ancillaryProducts != null && !ancillaryProducts.isEmpty()) {
                    for(Map<String, Object> ancillaryProduct : ancillaryProducts) {
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

                        for(Object member : ancilaryMembers){
                            Map<String,Object> memberMap = (Map<String,Object>)member;
                            if(memberMap.containsKey('CensusMemberId')){
                                manager.CMIdToCLI.get((Id)memberMap.get('CensusMemberId')).add(ancillaryLineItem);
                            }
                            else{
                                List<vlocity_ins__ContractLineItem__c> ancillaryLineItems = new List<vlocity_ins__ContractLineItem__c>();
                                ancillaryLineItems.add(ancillaryLineItem);
                                manager.CMIdToCLI.put((Id)memberMap.get('CensusMemberId'),ancillaryLineItems);
                            }
                        }
                    }
                }

                // Process Ancillary Child Products
                List<Map<String, Object>> ancillaryChildProducts = (List<Map<String, Object>>)productToMembersMap.get('AncillaryChildProducts');
                if(ancillaryChildProducts != null && !ancillaryChildProducts.isEmpty()) {
                    for(Map<String, Object> ancillaryChildProduct : ancillaryChildProducts) {
                        Map<String, Object> childProduct = (Map<String, Object>)ancillaryChildProduct.get('product');
                        
                        vlocity_ins__ContractLineItem__c ancillaryChildLineItem = new vlocity_ins__ContractLineItem__c();
                        ancillaryChildLineItem.Name = (String)childProduct.get('Name');
                        ancillaryChildLineItem.vlocity_ins__Product2Id__c = (Id)childProduct.get('Id');
                        ancillaryChildLineItem.vlocity_ins__AccountId__c = accountId;
                        ancillaryChildLineItem.vlocity_ins__ProductId__c = (Id)childProduct.get('Id');
                        
                        manager.contractLineItemsToInsert.add(ancillaryChildLineItem);                   
                    }
                }
            }
            catch(Exception e){
                System.debug('Exception mapContractLineItemsToCreate ' + e.getMessage());
                throw e;
            }
        }        
    }
   
    private void mapGCMPToCreate() {
        /*
        Name
        vlocity_ins__GroupCensusMemberId__c
        vlocity_ins__ContractLineId__c
        vlocity_ins__ContractLineItem__c
        */
    }

    /*******************************************************************
    * @MethodName         :   upsertMedicalQuesitons
    * @Description        :   insert new Medical Quesionts and update (inactive) old Medical Quesions for related members
    ********************************************************************/
    private void upsertMedicalQuesitons() {
        system.debug('upsertMedicalQuesitons IN ');
        try {

            Map<String, Object> stepMedicalQuestions = (Map<String, Object>)manager.inputMap.get('STEP_MedicalQuestions');
            List<Object> userInputs = (List<Object>)manager.inputMap.get('userInputs');
            Map<String, Object> pcReasons = (Map<String, Object>)((Map<String, Object>)manager.inputMap.get('pcChanges')).get('pcReasons');

            Boolean haveAddMember = (Boolean)pcReasons.get('addMember');
            Boolean haveProgramUpgrade = (Boolean)pcReasons.get('programUpgrade');
            Set<Id> oldMembersIds = new Set<Id>();
            List<String> newMembersIds = new List<String>();

            // Separate old and new members
            for (Object membObj  : userInputs) {
                Map<String, Object> memb = (Map<String, Object>)membObj;
    
                Boolean isNew = (Boolean)memb.get('IsNewMember');
   
                if (isNew == true) {
                    newMembersIds.add((String)memb.get('Id'));
                } else {
                    oldMembersIds.add((Id)memb.get('Id'));
                }
            }
            
            // We need to retrieve active medical questions (ARC_MedicalConditions__c and vlocity_ins__ConsumerDrug__c) for old members to deactivate before we insert new ones
            List<ARC_MedicalConditions__c> medicalConditionsToDeactivate = [SELECT Id, ARC_Active__c FROM  ARC_MedicalConditions__c WHERE ARC_Active__c = true AND ARC_CensusMember__c IN :oldMembersIds];
            List<vlocity_ins__ConsumerDrug__c> consumerDrugToDeactivate = [SELECT Id, ARC_Active__c FROM  vlocity_ins__ConsumerDrug__c WHERE ARC_Active__c = true AND ARC_CensusMember__c IN :oldMembersIds];

            if (!medicalConditionsToDeactivate.isEmpty()) {
                for (ARC_MedicalConditions__c mc : medicalConditionsToDeactivate) {
                    mc.ARC_Active__c = false;
                    manager.medicalConditionsToUpdate.add(mc);
                }
            }
            
            if (!consumerDrugToDeactivate.isEmpty()) {
                for (vlocity_ins__ConsumerDrug__c cd : consumerDrugToDeactivate) {
                    cd.ARC_Active__c = false;
                    manager.consumerDrugsToUpdate.add(cd);
                }
            }
            
            

            
            system.debug('upsertMedicalQuesitons stepMedicalQuestions ' + stepMedicalQuestions);
            //system.debug('upsertMedicalQuesitons userInputs ' + userInputs);
            system.debug('upsertMedicalQuesitons medicalConditionsToUpdate ' + manager.medicalConditionsToUpdate);
            system.debug('upsertMedicalQuesitons consumerDrugsToUpdate ' + manager.consumerDrugsToUpdate);






            system.debug('upsertMedicalQuesitons OUT ');





        } catch  (Exception e) {
            System.debug('Exception upsertMedicalQuesitons: ' + e.getMessage());
            System.debug('Exception upsertMedicalQuesitons: ' + e.getStackTraceString());

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
            censusMembers.add(member);
        }
        return censusMembers;
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
                        ancillaryProducts.add(new Map<String,Object>{
                            'product' => selectedProduct,
                            'members' => members,
                            'priceData' => selectedProduct.get('RawPriceData')
                        });

                        // Process child products if they exist
                        if(selectedProduct.containsKey('childProducts')) {
                            Map<String,Object> childProducts = (Map<String,Object>)selectedProduct.get('childProducts');
                            if(childProducts.containsKey('records')) {
                                List<Object> childRecords = (List<Object>)childProducts.get('records');
                                for(Object childRecord : childRecords) {
                                    Map<String,Object> childProduct = (Map<String,Object>)childRecord;
                                    if((String)childProduct.get('Type__c') == 'Ancillary') {
                                        ancillaryChildProducts.add(new Map<String,Object>{
                                            'product' => childProduct,
                                            'members' => members
                                        });
                                    }
                                }
                            }
                        }
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

}