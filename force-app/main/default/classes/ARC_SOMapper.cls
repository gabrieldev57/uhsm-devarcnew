/**
 * @Description: This class serves as the orchestrator for program change operations.
 * It manages the entire process of inserting and updating records across multiple objects,
 * coordinating between data mapping and DML operations.
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-06-24
 * @Version: 1.0
 */

 public without sharing class ARC_SOMapper {  
    private ARC_SOManager manager; 
    private Set<String> actionsToExecute = new Set<String>();

    public void mapSingleSpinOffData(ARC_SOManager manager) {
        this.manager = manager;       
        Map<String,Object> soReasons = (Map<String,Object>) manager.inputMap.get('soChanges');
        soReasons = (Map<String,Object>) soReasons.get('soReasons');
        System.debug('SO Reasons: ' + soReasons);
        if(soReasons != null){
            if(soReasons.containsKey('ancillaryChange') && (Boolean)soReasons.get('ancillaryChange') == true){
                manager.actionsToPerform.add('ancillaryChange');
            }
            if(soReasons.containsKey('removeMember') && (Boolean)soReasons.get('removeMember') == true){
                manager.actionsToPerform.add('removeMember');
            }
            if(soReasons.containsKey('addMember') && (Boolean)soReasons.get('addMember') == true){
                manager.actionsToPerform.add('addMember');
            }   
            if(soReasons.containsKey('agingOut') && (Boolean)soReasons.get('agingOut') == true){
                manager.actionsToPerform.add('agingOut');
                actionsToExecute.add('mapAccounts');
            }
            if(soReasons.containsKey('programDowngrade') && (Boolean)soReasons.get('programDowngrade') == true){
                manager.actionsToPerform.add('programDowngrade');
            }
            if(soReasons.containsKey('programUpgrade') && (Boolean)soReasons.get('programUpgrade') == true){            
                manager.actionsToPerform.add('programUpgrade');
            }   
            if(soReasons.containsKey('spinOff') && (Boolean)soReasons.get('spinOff') == true){
                manager.actionsToPerform.add('spinOff');
                actionsToExecute.add('mapAccounts');
                actionsToExecute.add('mapGuardian');
                actionsToExecute.add('mapCensus');
                actionsToExecute.add('mapGCM');
                actionsToExecute.add('mapContract');
                actionsToExecute.add('mapContractLineItem');
                actionsToExecute.add('mapContractParticipants');
                actionsToExecute.add('mapChargentOrders');
                actionsToExecute.add('insertHipaaAuthorization');
                actionsToExecute.add('mapMedicalQuestions');
                actionsToExecute.add('mapCases');
                actionsToExecute.add('mapCaseMember');
                actionsToExecute.add('insertPromotionDiscount');
                actionsToExecute.add('mapAncillaryDiscount');
                actionsToExecute.add('insertCaseForFeeSkipped');
                actionsToExecute.add('mapMemberBeneficiaries');
            }
        }
        else{
            actionsToExecute.add('multiSpinOff');
            manager.actionsToPerform.add('multiSpinOff');
        }
        executeActions(actionsToExecute); 
    }    

    private void executeActions(Set<String> actionsToExecute){
        getCensusMembers();
        for(String action : actionsToExecute){
            try {
                switch on action {
                    when 'mapAccounts' {
                        mapAccounts('groupAccountsToInsert');
                        mapAccounts('personAccountsToInsert');
                    }
                    when 'mapCensus' {
                        mapCensus();
                    }
                    when 'mapGuardian' {
                        mapGuardian();
                    }
                    when 'mapGCM' {
                        mapGCM();
                    }
                    when 'mapContract' {
                        mapContract('singleSpinOff');
                    }
                    when 'mapContractLineItem' {
                        mapContractLineItem('singleSpinOff');
                    }
                    when 'mapContractParticipants' {
                        mapContractParticipants();
                    }
                    when 'mapChargentOrders' {
                        mapChargentOrders();
                    }
                    when 'mapMedicalQuestions'{
                        mapMedicalQuestions();
                    }
                    when 'insertHipaaAuthorization' {
                        mapHipaaAuthorization();
                    }
                    when 'mapCases' {
                        mapCases(); 
                    }
                    when 'mapCaseMember' {
                        mapCaseMember();
                    }
                    when 'insertPromotionDiscount' {
                        insertPromotionDiscount();
                    }
                    when 'mapAncillaryDiscount' {
                        mapCriticalCarePromotionDiscount('singleSpinOff');
                    }
                    when 'insertCaseForFeeSkipped' { // this is for case fee skipped
                        insertCaseForFeeSkipped();
                    }
                    when 'mapMemberBeneficiaries' {
                        mapMemberBeneficiaries();
                    }
                    when 'multiSpinOff' { 
                        mapAccounts('groupAccountsToInsert');
                        mapCensus();
                        mapGCM();
                        mapAccounts('personAccountsToInsert');
                        mapContract('multiSpinOff');
                        mapContractLineItem('multiSpinOff');
                        mapContractParticipants();
                        mapCriticalCarePromotionDiscount('multiSpinOff');
                        mapChargentOrders();
                        mapCases(); 
                        mapCaseMember();
                        mapMemberBeneficiaries();
                    }
                    
                }
            } catch (Exception e) {
                System.debug('ERROR: ' + 'Error executing action ' + action + ': ' + e.getLineNumber() + ' ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw new AuraHandledException('Error executing action ' + action + ': ' + e.getLineNumber() + ' ' + e.getMessage() + ' ' + e.getStackTraceString());
            }
        }
    }

    private void mapAccounts(String action) {
        if(action == 'groupAccountsToInsert'){
            try{
                
                List<Map<String,Object>> censusMembersInSpinOffContract = manager.censusMembersInSpinOffContract;
                List<Map<String,Object>> newPrimaryMembers = new List<Map<String,Object>>();
                Map<String,Object> newPrimaryMember = new Map<String,Object>();                
                
                
                // we need to bulkify this for multiple spinoff using this variable manager.censusMembersMap 6-25-25
                censusMembersInSpinOffContract = manager.censusMembersInSpinOffContract;

                if(manager.spinnedCensusMembersGroupedByPrimary.keySet().size() == 1){      
                    List<Map<String,Object>> newPrimaryMemberList = new List<Map<String,Object>>(manager.spinnedCensusMembersGroupedByPrimary.keySet());
                    newPrimaryMember = newPrimaryMemberList[0];
                    
                    //Get billing Address from payment STEP
                    Map<String,Object> STEP_ChargentPayment = manager.inputMap.containsKey('STEP_ChargentPayment') ? (Map<String,Object>)manager.inputMap.get('STEP_ChargentPayment') : null;
                    Map<String,Object> BLK_ChargeFee = STEP_ChargentPayment.containsKey('BLK_ChargeFee') ? (Map<String,Object>)STEP_ChargentPayment.get('BLK_ChargeFee') : null;
                    Map<String,Object> BLK_PaymentInfo = BLK_ChargeFee.containsKey('BLK_PaymentInfo') ? (Map<String,Object>)BLK_ChargeFee.get('BLK_PaymentInfo') : null;
                    Map<String,Object> BLK_CreditCard = BLK_PaymentInfo.containsKey('BLK_CreditCard') ? (Map<String,Object>)BLK_PaymentInfo.get('BLK_CreditCard') : null;
                    Map<String,Object> BLK_BankAccount = BLK_PaymentInfo.containsKey('BLK_BankAccount') ? (Map<String,Object>)BLK_PaymentInfo.get('BLK_BankAccount') : null;
                    
                    //Create group account
                    Account groupAccount = new Account();
                    groupAccount.Name = newPrimaryMember.get('vlocity_ins__FirstName__c') + ' ' + (String)newPrimaryMember.get('vlocity_ins__LastName__c') + ' Family';
                    groupAccount.Phone = newPrimaryMember.containsKey('ARC_Phone__c') ? (String)newPrimaryMember.get('ARC_Phone__c') : null;
                    groupAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Group').getRecordTypeId();
                    groupAccount.vlocity_ins__Email__c = newPrimaryMember.containsKey('vlocity_ins__Email__c') ? (String)newPrimaryMember.get('vlocity_ins__Email__c') : null;
                    
                    //Set billing Address
                    if(BLK_CreditCard != null){
                        groupAccount.BillingStreet = BLK_CreditCard.containsKey('TXT_BillingAddress_Street') ? (String)BLK_CreditCard.get('TXT_BillingAddress_Street') : null;
                        groupAccount.BillingState = BLK_CreditCard.containsKey('TXT_BillingAddress_State') ? (String)BLK_CreditCard.get('TXT_BillingAddress_State') : null;
                        groupAccount.BillingPostalCode = BLK_CreditCard.containsKey('TXT_BillingAddress_ZipCode') ? (String)BLK_CreditCard.get('TXT_BillingAddress_ZipCode') : null;
                        groupAccount.BillingCity = BLK_CreditCard.containsKey('TXT_BillingAddress_City') ? (String)BLK_CreditCard.get('TXT_BillingAddress_City') : null;
                    }else if(BLK_BankAccount != null){
                        groupAccount.BillingStreet = BLK_BankAccount.containsKey('TXT_BillingAddress_Street') ? (String)BLK_BankAccount.get('TXT_BillingAddress_Street') : null;
                        groupAccount.BillingState = BLK_BankAccount.containsKey('TXT_BillingAddress_State') ? (String)BLK_BankAccount.get('TXT_BillingAddress_State') : null;
                        groupAccount.BillingPostalCode = BLK_BankAccount.containsKey('TXT_BillingAddress_ZipCode') ? (String)BLK_BankAccount.get('TXT_BillingAddress_ZipCode') : null;
                        groupAccount.BillingCity = BLK_BankAccount.containsKey('TXT_BillingAddress_City') ? (String)BLK_BankAccount.get('TXT_BillingAddress_City') : null;
                    }                
                    manager.groupAccountsToInsertMap.put(1,groupAccount);                    
                }
                else{
                    //Create group account for each primary member
                    Integer familyIndex = 1;
                    for(Map<String,Object> member : manager.spinnedCensusMembersGroupedByPrimary.keySet()){                        
                        Account groupAccountMulti = new Account();
                        groupAccountMulti.Name = member.get('vlocity_ins__FirstName__c') + ' ' + (String)member.get('vlocity_ins__LastName__c') + ' Family';
                        groupAccountMulti.Phone = member.containsKey('ARC_Phone__c') ? (String)member.get('ARC_Phone__c') : null;
                        groupAccountMulti.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Group').getRecordTypeId();
                        groupAccountMulti.vlocity_ins__Email__c = member.containsKey('vlocity_ins__Email__c') ? (String)member.get('vlocity_ins__Email__c') : null;

                        manager.groupAccountsToInsertMap.put(familyIndex,groupAccountMulti);
                        familyIndex++;
                    }                                        
                }
            }
            catch(Exception e){
                system.debug('Error mapping accounts: ' + e.getLineNumber() + ' ' + e.getMessage());
                throw new AuraHandledException('Error mapping accounts: Line: '+ e.getLineNumber() + ' ' + e.getMessage()); 
            }            
        }
        else if(action == 'personAccountsToInsert'){
            try{
                if(!manager.spinnedCensusMembersGroupedByPrimary.keySet().isEmpty()){
                    List<Map<String,Object>> newPrimaryMemberList = new List<Map<String,Object>>(manager.spinnedCensusMembersGroupedByPrimary.keySet());                    
                    for(List<Map<String,Object>> family : manager.spinnedCensusMembersGroupedByPrimary.values()){
                        Integer familyIndex = 0;
                        List<Account> personAccounts = new List<Account>();
                        for(Map<String,Object> member : family){
                            Account personAccount = new Account();
                            personAccount.FirstName = (String)member.get('vlocity_ins__FirstName__c');
                            personAccount.LastName = (String)member.get('vlocity_ins__LastName__c');
                            personAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();                              
                            if(member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false){
                                personAccount.Id = member.containsKey('PersonAccountId') ? (Id)member.get('PersonAccountId') : null;
                            } if(member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == true){
                                if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') != 'Primary'){
                                    personAccount.ARC_DependentRelationship__c = (String)member.get('ARC_Relationship__c');
                                }
                                personAccount.PersonBirthdate = Date.valueOf((String)member.get('vlocity_ins__Birthdate__c'));
                            }  
                            if((String)member.get('ARC_Relationship__c') == 'Primary' && manager.inputMap.containsKey('STEP_MedicareCoverage')){
                                
                                Map<String,Object> stepMedicare = (Map<String,Object>)manager.inputMap.get('STEP_MedicareCoverage');
                                if(stepMedicare != null && stepMedicare.containsKey('BLK_MedicareId') && stepMedicare.get('BLK_MedicareId') != null){
                                    Map<String,Object> stepMedicareBlock = (Map<String,Object>)stepMedicare.get('BLK_MedicareId');
                                    personAccount.Medicare_ID__c = (String)stepMedicareBlock.get('MedicareIdNumber');
                                    personAccount.Medicare_Part_A_Effective_Date__c = stepMedicareBlock.get('Medicare_A_Effective_Date') != null ? Date.valueOf((String)stepMedicareBlock.get('Medicare_A_Effective_Date')) : null;
                                    personAccount.Medicare_Part_B_Effective_Date__c = stepMedicareBlock.get('Part_B_Effective_Date') != null ? Date.valueOf((String)stepMedicareBlock.get('Part_B_Effective_Date')) : null;
                                    personAccount.Medicare_Part_D_Effective_Date__c = stepMedicareBlock.get('Part_D_Effective_Date') != null ? Date.valueOf((String)stepMedicareBlock.get('Part_D_Effective_Date')) : null;
                                }
                            }
                            personAccounts.add(personAccount);
                            if(member.containsKey('Id')){
                                manager.fictionalMemberIdToPersonAccount.put((String)member.get('Id'), personAccount);
                            }                           
                        }
                        manager.personAccountsToInsertMap.put(familyIndex, personAccounts);

                        for(String memberId : manager.fictionalMemberIdToPersonAccount.keySet()){
                            Account personAccount = manager.fictionalMemberIdToPersonAccount.get(memberId);
                        }
                        familyIndex++;
                    }
                }
            }
            catch(Exception e){
                system.debug('Error mapping person accounts: ' + e.getLineNumber() + ' ' + e.getMessage());
                throw new AuraHandledException('Error mapping person accounts: ' + e.getLineNumber() + ' ' + e.getMessage());
            }
        } 
    }

    private void mapCensus() {
        Integer familyIndex = 0;
        for(Map<String,Object> family : manager.spinnedCensusMembersGroupedByPrimary.keySet()){
            vlocity_ins__GroupCensus__c groupCensus = new vlocity_ins__GroupCensus__c();
            groupCensus.Name = family.get('vlocity_ins__FirstName__c') + ' ' +(String)family.get('vlocity_ins__LastName__c') + ' - Census';
            groupCensus.ARC_PrimaryAccount__c = (family.containsKey('PersonAccountId') && !((String)family.get('PersonAccountId')).contains('MEM')) ? (Id)family.get('PersonAccountId') : null;
            Id recordTypeId = Schema.SObjectType.vlocity_ins__GroupCensus__c.getRecordTypeInfosByDeveloperName().get('ARC_IndividualAndFamily').getRecordTypeId();
            groupCensus.RecordTypeId = recordTypeId;
            familyIndex++;
            for(Map<String,Object> member : manager.spinnedCensusMembersGroupedByPrimary.get(family)){
                if(manager.groupCensusToFictionalId.containsKey(groupCensus)){
                    String memberId = (String)member.get('Id');
                    manager.groupCensusToFictionalId.get(groupCensus).add(memberId);
                }
                else{
                    String memberId = (String)member.get('Id');
                    manager.groupCensusToFictionalId.put(groupCensus, new List<String>{memberId});
                }
            }
        }
    }    
    private void mapGCM() { 
        try{
            Integer familyIndex = 0;
            for(Map<String,Object> primaryMember : manager.spinnedCensusMembersGroupedByPrimary.keySet()){            
                List<Map<String,Object>> censusMembersList = manager.spinnedCensusMembersGroupedByPrimary.get(primaryMember);
                List<vlocity_ins__GroupCensusMember__c> groupCensusMembersToInsert = new List<vlocity_ins__GroupCensusMember__c>();
                for(Map<String,Object> member : censusMembersList){
                    
                    vlocity_ins__GroupCensusMember__c groupCensusMember = new vlocity_ins__GroupCensusMember__c();
                    String memberId = member.containsKey('Id') ? (String)member.get('Id') : null;
                    if(memberId != null && !memberId.contains('MEM')){                        
                        groupCensusMember.Id = (Id)member.get('Id');
                    }
                    groupCensusMember.Name = member.get('vlocity_ins__FirstName__c') + ' ' +(String)member.get('vlocity_ins__LastName__c');
                    groupCensusMember.vlocity_ins__FirstName__c = member.containsKey('vlocity_ins__FirstName__c') ? (String)member.get('vlocity_ins__FirstName__c') : null;
                    groupCensusMember.vlocity_ins__LastName__c = member.containsKey('vlocity_ins__LastName__c') ? (String)member.get('vlocity_ins__LastName__c') : null;
                    groupCensusMember.vlocity_ins__Gender__c = member.containsKey('vlocity_ins__Gender__c') ? (String)member.get('vlocity_ins__Gender__c') : null;
                    groupCensusMember.vlocity_ins__Email__c = member.containsKey('vlocity_ins__Email__c') ? (String)member.get('vlocity_ins__Email__c') : null;
                    groupCensusMember.ARC_PhysicalAddressZipCode__c = member.containsKey('ARC_PhysicalAddressZipCode__c') ? (String)member.get('ARC_PhysicalAddressZipCode__c') : null;
                    groupCensusMember.ARC_PhysicalAddressStreet__c = member.containsKey('ARC_PhysicalAddressStreet__c') ? (String)member.get('ARC_PhysicalAddressStreet__c') : null;
                    groupCensusMember.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? (String)member.get('ARC_PhysicalAddressState__c') : null;
                    groupCensusMember.ARC_PhysicalAddressCity__c = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                    if(member.containsKey('ARC_isPregnant__c') && member.get('vlocity_ins__Birthdate__c') != null && member.get('ARC_isPregnant__c') == true){
                        groupCensusMember.ARC_isPregnant__c =  (Boolean)member.get('ARC_isPregnant__c');
                    }
                    else{
                        groupCensusMember.ARC_isPregnant__c = false;
                    }
                    groupCensusMember.ARC_Phone__c = member.containsKey('ARC_Phone__c') ? (String)member.get('ARC_Phone__c') : null;
                    groupCensusMember.ARC_Smoker__c = member.containsKey('ARC_Smoker__c') && convertToBoolean(member.get('ARC_Smoker__c')) != null ? convertToBoolean(member.get('ARC_Smoker__c')) : false;
                    groupCensusMember.ARC_Weight__c = member.containsKey('ARC_Weight__c') ? (String)member.get('ARC_Weight__c') : null;
                    groupCensusMember.ARC_HeightInches__c = member.containsKey('ARC_HeightInches__c') ? (String)member.get('ARC_HeightInches__c') : null;
                    groupCensusMember.ARC_HeightFeet__c = member.containsKey('ARC_HeightFeet__c') ? (String)member.get('ARC_HeightFeet__c') : null;
                    groupCensusMember.vlocity_ins__SocialSecurityNumber__c = member.containsKey('vlocity_ins__SocialSecurityNumber__c') ? (String)member.get('vlocity_ins__SocialSecurityNumber__c') : null;
                    groupCensusMember.vlocity_ins__IsPrimaryMember__c = member.containsKey('vlocity_ins__IsPrimaryMember__c') ? (Boolean)member.get('vlocity_ins__IsPrimaryMember__c') : null;
                    groupCensusMember.vlocity_ins__Birthdate__c = member.containsKey('vlocity_ins__Birthdate__c') ? Date.valueOf(String.valueOf(member.get('vlocity_ins__Birthdate__c'))) : null;                    
                    groupCensusMember.ARC_MiddleInitial__c = member.containsKey('ARC_MiddleInitial__c') ? (String)member.get('ARC_MiddleInitial__c') : null;
                    groupCensusMember.vlocity_ins__MemberIdentifier__c = member.containsKey('vlocity_ins__MemberIdentifier__c') ? (String)member.get('vlocity_ins__MemberIdentifier__c') : null;
                    groupCensusMember.ARC_UseParentAddress__c = member.containsKey('CopyAddressFromPrimary') ? (Boolean)member.get('CopyAddressFromPrimary') : null;
                    groupCensusMember.vlocity_ins__PrimaryMemberIdentifier__c = primaryMember.containsKey('vlocity_ins__MemberIdentifier__c') ? (String)primaryMember.get('vlocity_ins__MemberIdentifier__c') : null;
                    if(member.containsKey('ARC_Relationship__c')){
                        String relationship = (String)member.get('ARC_Relationship__c');
                        if(relationship == 'Spouse'){
                            groupCensusMember.vlocity_ins__IsSpouse__c = true;
                            groupCensusMember.vlocity_ins__HasSpouse__c = member.containsKey('vlocity_ins__HasSpouse__c') ? (Boolean)member.get('vlocity_ins__HasSpouse__c') : false;
                            groupCensusMember.ARC_DependentRelationship__c = member.containsKey('ARC_Relationship__c') ? (String)member.get('ARC_Relationship__c') : null;
                        }
                        else if(relationship == 'Child'){
                            groupCensusMember.vlocity_ins__IsSpouse__c = false;
                            groupCensusMember.ARC_DependentRelationship__c = member.containsKey('ARC_Relationship__c') ? (String)member.get('ARC_Relationship__c') : null;
                        }
                    }
                    if(member.containsKey('Id')){
                        manager.fictionalMemberIdToGCM.put((String)member.get('Id'), groupCensusMember);
                    }

                    groupCensusMembersToInsert.add(groupCensusMember);
                }
                manager.groupCensusMembersToInsertMap.put(familyIndex,groupCensusMembersToInsert);
                familyIndex++;
            }
        }
        catch(Exception e){
            System.debug('Error mapping GCM: ' + e.getLineNumber() + ' ' + e.getMessage());
            throw new AuraHandledException('Error mapping GCM: ' + e.getLineNumber() + ' ' + e.getMessage());
        }
    }
    private void mapGuardian() {
        try {
            if (manager.guardiansToInsert == null) {
                manager.guardiansToInsert = new List<Account>();
            }
            Map<String, Object> guardianInfo = (Map<String, Object>) manager.inputMap.get('STEP_GuardiansInformation');
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
                if (guardianInfo.containsKey('DATE_GuardianBirthdate') && guardianInfo.get('DATE_GuardianBirthdate') != null) {
                    newGuardian.PersonBirthdate = Date.valueOf((String)guardianInfo.get('DATE_GuardianBirthdate'));
                }
                if (ssnMap != null) {
                    newGuardian.ARC_SocialSecurityNumber__c = (String) ssnMap.get('response');
                }
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
        } catch (Exception e) {
            throw new AuraHandledException('Error mapping guardian: ' + e.getMessage());
        }
    }
    private void mapCases() {
        try {

            Map<String, Object> soChanges = (Map<String, Object>)manager.inputMap.get('soChanges');
            Map<String, Object> membersToSpinOff = (Map<String, Object>)manager.inputMap.get('STEP_MembersToSpinOff');
            List<Object> contractSelected = (List<Object>)membersToSpinOff.get('TXTBLK_ContractSelected');
            Map<String, Object> contractInfo = (Map<String, Object>)contractSelected[0];

            Map<String, Object> soReasons = soChanges.containsKey('soReasons') ? (Map<String, Object>)soChanges.get('soReasons') : null;
            Boolean addMember = false;
            Boolean programUpgrade = false;
            Boolean isMultipleSpinOff = false;
            if(soReasons != null){
                addMember = soReasons.containsKey('addMember') ? (Boolean)soReasons.get('addMember') : false;
                programUpgrade = soReasons.containsKey('programUpgrade') ? (Boolean)soReasons.get('programUpgrade') : false;            
            }
            if(membersToSpinOff != null){
                isMultipleSpinOff = membersToSpinOff.containsKey('FRML_multipleSpinOff') ? (Boolean)membersToSpinOff.get('FRML_multipleSpinOff') : false;
            }

            Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admission').getRecordTypeId();
            Id queueId = [SELECT Id FROM Group WHERE DeveloperName = 'ProcessingQueue' LIMIT 1].Id;

            // UW Case to Remove Member Contract
            Case caseRC = new Case();
            caseRC.AccountId = (String)contractInfo.get('GroupAccountId');
            caseRC.RecordTypeId = recordTypeId;
            caseRC.ARC_Reason__c = 'PC Approval';
            caseRC.Description = 'PC Approval';  
            caseRC.Origin = 'Internal Enrollment';
            caseRC.OwnerId = queueId;
            caseRC.Status = 'New';
            caseRC.Subject = 'PC Approval';
            caseRC.Type = 'Program Change';
            caseRC.Case_Type__c = 'PC Approval';
            
            manager.casesUWToInsert.put('0', caseRC);

            if(!isMultipleSpinOff) {
                // UW Case to Single Spin Off Contract
                Case caseSO = new Case();
                caseSO.RecordTypeId = recordTypeId;
                caseSO.Origin = 'Internal Enrollment';
                caseSO.OwnerId = (Id)manager.inputMap.get('userId');
                caseSO.Status = 'Draft';
                caseSO.Type = 'Program Change';
                if (programUpgrade || addMember) {
                    caseSO.Subject = caseSO.Description = 'Underwriting';
                    caseSO.ARC_Reason__c = 'Underwriting';
                    caseSO.Case_Type__c = 'Underwriting';
                }
                else {
                    caseSO.Subject = caseSO.Description = 'PC Approval';
                    caseSO.ARC_Reason__c = 'PC Approval';
                    caseSO.Case_Type__c = 'PC Approval';
                }

                // insert the UW Cases to the Map
                manager.casesUWToInsert.put('1', caseSO);
            }

        } catch (Exception e) {
            System.debug('Exception mapCases (SOMapper): ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    private void mapCaseMember() {
        
        Map<String, Object> soChanges = (Map<String, Object>)manager.inputMap.get('soChanges');
        Map<String, Object> soReasons = (Map<String, Object>)soChanges.get('soReasons');
         Map<String, Object> membersToSpinOff = (Map<String, Object>)manager.inputMap.get('STEP_MembersToSpinOff');
        String contractId = (String)manager.inputMap.get('ContractIdSelected');

        Boolean addMember = false;
        Boolean programUpgrade = false;
        Boolean isMultipleSpinOff = false;
        if(soReasons != null){
            addMember = soReasons.containsKey('addMember') ? (Boolean)soReasons.get('addMember') : false;
            programUpgrade = soReasons.containsKey('programUpgrade') ? (Boolean)soReasons.get('programUpgrade') : false;
        }
        if(membersToSpinOff != null){
            isMultipleSpinOff = membersToSpinOff.containsKey('FRML_multipleSpinOff') ? (Boolean)membersToSpinOff.get('FRML_multipleSpinOff') : false;
        }


        try { // UWCaseMembers (Remove Member - Contract)
            for (Map<String,Object> member : manager.spinOffmembersIds) {
                
                ARC_UnderwritingCaseMember__c rcUWCM = new ARC_UnderwritingCaseMember__c();
                rcUWCM.Name = (String)member.get('name');
                rcUWCM.ARC_Member__c = member.containsKey('censusId') ? (Id)member.get('censusId') : null;
                rcUWCM.ARC_PersonAccount__c = member.containsKey('accountId') ? (Id)member.get('accountId') : null;
                rcUWCM.ARC_ApprovalResolution__c = 'Pending';
                rcUWCM.ARC_Reason__c = 'Remove Member';
                manager.censusMemberIdOrFakeIdToUWCM_RC.put(rcUWCM.ARC_Member__c, rcUWCM);                
            }
        } catch (Exception e) {
            System.debug('Exception mapCaseMember, Remove Member - Contract (SOMapper): ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }

        if(!isMultipleSpinOff){
            try { // Contract UWCaseMembers (Spin Off - Contract)
                if (programUpgrade) {
                    // ask if carry over the last UW Case Members...???
                    List<ARC_UnderwritingCaseMember__c> listUWCMToCopy = [SELECT ARC_ApprovalResolution__c, ARC_Member__c, ARC_PersonAccount__c, ARC_Reason__c, ARC_Score__c, Name, ARC_ReviewedBy__c, ARC_LastStatusUpdate__c, LastModifiedById, ARC_Description__c FROM ARC_UnderwritingCaseMember__c WHERE ARC_Contract__c =: contractId];

                    

                    for (ARC_UnderwritingCaseMember__c UWCM : listUWCMToCopy) {
                        for (Map<String,Object> member : manager.censusMembersInSpinOffContract) {
                            if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false && member.containsKey('Id') && (Id)member.get('Id') == UWCM.ARC_Member__c && member.containsKey('IsRemoveMember') && (Boolean)member.get('IsRemoveMember') == false) { 
                                try {
                                    ARC_UnderwritingCaseMember__c soUWCM = new ARC_UnderwritingCaseMember__c();
                                    soUWCM.Name = UWCM.Name;
                                    soUWCM.ARC_Member__c = UWCM.ARC_Member__c;
                                    soUWCM.ARC_PersonAccount__c = UWCM.ARC_PersonAccount__c;
                                    soUWCM.ARC_Reason__c = UWCM.ARC_Reason__c;
                                    soUWCM.ARC_ApprovalResolution__c = 'Pending';

                                    // Copy approval details if within 60 days
                                    if (UWCM.ARC_LastStatusUpdate__c != null && UWCM.ARC_LastStatusUpdate__c.date().daysBetween(Date.today()) <= 60 ) {
                                        soUWCM.ARC_ApprovalResolution__c =  UWCM.ARC_ApprovalResolution__c;
                                        soUWCM.ARC_Score__c = UWCM.ARC_Score__c;
                                        soUWCM.ARC_ReviewedBy__c = UWCM.ARC_ReviewedBy__c;
                                        soUWCM.ARC_Description__c =  UWCM.ARC_Description__c;
                                    }
                                    manager.censusMemberIdOrFakeIdToUWCM_SP.put(soUWCM.ARC_Member__c, soUWCM);       
                                } catch (Exception e) {
                                    System.debug('Exception when trying to clone previous UWM Cases ' + e.getMessage() + ' ' + e.getStackTraceString());
                                    throw e;
                                }
                            }
                        }
                    }
                }
                
                if (addMember || programUpgrade) {
                    for (Map<String, Object> cm : manager.censusMembersInSpinOffContract) {
                        ARC_UnderwritingCaseMember__c soUWCM;

                        if (manager.censusMemberIdOrFakeIdToUWCM_SP.containsKey((String)cm.get('Id'))) {
                            continue;
                        }
                        else{
                            soUWCM = new ARC_UnderwritingCaseMember__c();
                            soUWCM.ARC_ApprovalResolution__c = 'Pending';
                            soUWCM.Name = (String)cm.get('vlocity_ins__FirstName__c') + ' ' + (String)cm.get('vlocity_ins__LastName__c');
                        }

                        // Set case member details based on change type
                        if ((Boolean)cm.get('IsNewMember') == true) {
                            soUWCM.ARC_Reason__c = 'Add Member';
                            manager.censusMemberIdOrFakeIdToUWCM_SP.put((String)cm.get('Id'), soUWCM);
                        } else if ((Boolean)cm.get('IsNewMember') == false && programUpgrade == true) {
                            soUWCM.ARC_Member__c = (Id)cm.get('Id');
                            soUWCM.ARC_Reason__c = 'Program Upgrade';
                            soUWCM.ARC_PersonAccount__c = (Id)cm.get('PersonAccountId');
                            manager.censusMemberIdOrFakeIdToUWCM_SP.put((String)cm.get('Id'), soUWCM);
                        }	                  
                    }
                }
            } catch (Exception e) {
                System.debug('Exception mapCaseMember, Spin Off - Contract (SOMapper): ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw e;
            }
        }
    }
    private void mapContract(String action) {
        Contract removeContract = new Contract();
        Map<String, Object> selectedContract;
        Id selectedContractId = (Id) manager.inputMap.get('ContractIdSelected');
        Map<String, Object> STEP_MembersToSpinOff = manager.inputMap.containsKey('STEP_MembersToSpinOff') ? (Map<String, Object>)manager.inputMap.get('STEP_MembersToSpinOff') : null;
        String currentContractStatus = null;
        if(STEP_MembersToSpinOff != null){
            List<Object> TXTBLK_ContractSelected = STEP_MembersToSpinOff.containsKey('TXTBLK_ContractSelected') ? (List<Object>)STEP_MembersToSpinOff.get('TXTBLK_ContractSelected') : null;
            Map<String, Object> contractInfo = null;
            if(TXTBLK_ContractSelected != null && !TXTBLK_ContractSelected.isEmpty()) {
                Object firstElement = TXTBLK_ContractSelected[0];
                if(firstElement instanceof Map<String, Object>) {
                    contractInfo = (Map<String, Object>)firstElement;
                }
            }
            if(contractInfo != null){
                currentContractStatus = (String)contractInfo.get('TXT_ContractStatus');
            }
        }
        //If there is any Awaiting Signature || Approval && An Active contract OR only one Active Contract
        if(currentContractStatus == 'Activated'){
            List<Contract> contractsToInsert = new List<Contract>([SELECT Id, ARC_ContractReason__c, ARC_EffectiveDate__c, Status, StartDate,ARC_CancellationReason__c, vlocity_ins__ExpiredContractId__c FROM Contract WHERE vlocity_ins__ExpiredContractId__c =:selectedContractId AND Status LIKE '%Awaiting%']);
            for(Contract contract : contractsToInsert){
                contract.Status = 'Voided';
                contract.ARC_CancellationReason__c = 'Program Change'; // REPLACE TO Spin-OFF?
                manager.contractsToVoid.add(contract);
            }
        }
        else { 
            Contract oldContractToUpdate = new Contract();
            oldContractToUpdate.Id = selectedContractId;
            oldContractToUpdate.Status = 'Voided';
            oldContractToUpdate.ARC_CancellationReason__c = 'Program Change';
            manager.contractsToVoid.add(oldContractToUpdate);
        }

        List<Object> ContractList = (List<Object>)manager.inputMap.get('ContractList'); // REPLACE TO Spin-OFF?
        for (Object contract_obj : ContractList) {
            Map<String, Object> contract = (Map<String, Object>) contract_obj;
            if ((Id)contract.get('ContractID') == selectedContractId) {
                selectedContract = contract;
                break;
            }
        }

        Boolean isSOLegacy = manager.inputMap.containsKey('SV_EnforceLegacyEffectiveDate') ? (Boolean)manager.inputMap.get('SV_EnforceLegacyEffectiveDate') : false;
        Boolean isLegacy = manager.inputMap.containsKey('isLegacy') ? (Boolean)manager.inputMap.get('isLegacy') : false;
        Date effectiveDate;

        if (isSOLegacy) {
            effectiveDate = Date.valueOf((String)manager.inputMap.get('EffectiveDate'));
        } else {
            Map<String, Object> STEP_AccountSelection = (Map<String, Object>)manager.inputMap.get('STEP_AccountSelection');
            Map<String, Object> aRC_DatePicker = (Map<String, Object>)STEP_AccountSelection.get('aRC_DatePicker');
            effectiveDate = Date.valueOf((String)aRC_DatePicker.get('DATE_SubscriberEffectiveDate'));
        }

        //ASSIGN PREVIOUS SELLING AGENT OR INACTIVE SALES AGENT
        Id oldAgentId = selectedContract.get('SellingAgentId')!= null? (Id)selectedContract.get('SellingAgentId'):null;
        Id sellingAgentToAssign;
        List<User> agentUsers = [SELECT Id, Name FROM User WHERE (Id =:oldAgentId OR Name = 'Inactive Sales Agent') AND IsActive = true];
        Id integrationUserId;
        Boolean oldAgentIdActive = false;
        for(User agent: agentUsers){
            if(oldAgentId != null && agent.Id == oldAgentId) oldAgentIdActive = true;
            else integrationUserId = agent.Id;
        }
        sellingAgentToAssign = oldAgentIdActive == true?oldAgentId:integrationUserId;
        
        removeContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_IndividualAndFamily').getRecordTypeId();
        removeContract.ARC_EffectiveDate__c = effectiveDate;
        removeContract.Status = 'Draft';
        removeContract.StartDate = effectiveDate;
        removeContract.ContractTerm = 12;
        removeContract.ARC_ContractReason__c = 'Spin Off;Remove Member';
        removeContract.ARC_Selling_Agent__c = sellingAgentToAssign;
        removeContract.AccountId = (Id)selectedContract.get('GroupAccountId');
        removeContract.Account_Name_Text__c = (String)selectedContract.get('GroupAccountName');
        removeContract.vlocity_ins__EnrollmentCensusId__c = (Id)manager.inputMap.get('CensusId');
        removeContract.vlocity_ins__ExpiredContractId__c = selectedContractId;
        if (selectedContract.get('GuardianId') != null && selectedContract.get('GuardianId') != '') {
            removeContract.ARC_Guardian__c = (Id)selectedContract.get('GuardianId');
        }
        manager.contractsToInsertMap.put(0, removeContract);
        if (action == 'singleSpinOff') {
            Contract singleSpinOffContract = new Contract();
            Map<String, Object> soChanges = (Map<String, Object>)manager.inputMap.get('soChanges');
            if (soChanges != null) {
                String reasons = (String)soChanges.get('soReasonsString');
                if (reasons != null && reasons.contains('Ancillary Change')) {
                    reasons = reasons.replace('Ancillary Change', 'Add Ancillary Product');
                }
                singleSpinOffContract.ARC_ContractReason__c = reasons;
            }
            singleSpinOffContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_IndividualAndFamily').getRecordTypeId();
            singleSpinOffContract.ARC_EffectiveDate__c = effectiveDate;
            singleSpinOffContract.Status = 'Draft';
            singleSpinOffContract.StartDate = effectiveDate;
            singleSpinOffContract.ContractTerm = 12;
            singleSpinOffContract.ARC_Selling_Agent__c = isLegacy ? UserInfo.getUserId() : sellingAgentToAssign;
            singleSpinOffContract.vlocity_ins__ExpiredContractId__c = selectedContractId; 
            manager.contractsToInsertMap.put(1, singleSpinOffContract);
        } else if (action == 'multiSpinOff') {
            for (Integer familyIndex : manager.censusMembersMap.keySet()) {
                if (familyIndex == 0) continue;
                Contract multiSpinOffContract = new Contract();
                multiSpinOffContract.ARC_ContractReason__c = 'Spin Off';
                multiSpinOffContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_IndividualAndFamily').getRecordTypeId();
                multiSpinOffContract.ARC_EffectiveDate__c = effectiveDate;
                multiSpinOffContract.Status = 'Draft';
                multiSpinOffContract.StartDate = effectiveDate;
                multiSpinOffContract.ContractTerm = 12;
                multiSpinOffContract.ARC_Selling_Agent__c = sellingAgentToAssign;
                multiSpinOffContract.vlocity_ins__ExpiredContractId__c = selectedContractId;
                manager.contractsToInsertMap.put(familyIndex, multiSpinOffContract);
            }
        }
    }
    private void mapContractLineItem(String action) {
        List<Object> productToMembersByFamilyList = getProductsWithMembers(action);
        Map<String, Object> selectedContract;
        Id selectedContractId = (Id) manager.inputMap.get('ContractIdSelected');
        List<Object> ContractList = (List<Object>)manager.inputMap.get('ContractList');
        for (Object contract_obj : ContractList) {
            Map<String, Object> contract = (Map<String, Object>) contract_obj;
            if ((Id)contract.get('ContractID') == selectedContractId) {
                selectedContract = contract;
                break;
            }
        }
        Id accountId = (Id)selectedContract.get('GroupAccountId');

        Boolean isSOLegacy = manager.inputMap.containsKey('SV_EnforceLegacyEffectiveDate') ? (Boolean)manager.inputMap.get('SV_EnforceLegacyEffectiveDate') : false;
        Date contractEffectiveDate;

        if (isSOLegacy) {
            contractEffectiveDate = Date.valueOf((String)manager.inputMap.get('EffectiveDate'));
        } else {
            Map<String, Object> STEP_AccountSelection = (Map<String, Object>)manager.inputMap.get('STEP_AccountSelection');
            Map<String, Object> aRC_DatePicker = (Map<String, Object>)STEP_AccountSelection.get('aRC_DatePicker');
            contractEffectiveDate = Date.valueOf((String)aRC_DatePicker.get('DATE_SubscriberEffectiveDate'));
        }

        for (Integer familyIndex = 0; familyIndex < productToMembersByFamilyList.size(); familyIndex++) {
            Map<String, Object> productToMembersMap = (Map<String, Object>)productToMembersByFamilyList[familyIndex];
            if (productToMembersMap == null || productToMembersMap.isEmpty()) continue;
            Integer index = 0;
            try {
                Map<String, Object> medicalWithMembers = (Map<String, Object>)productToMembersMap.get('Medical');
                if (medicalWithMembers != null) {
                    Map<String, Object> medicalProduct = (Map<String, Object>)medicalWithMembers.get('product');
                    List<Object> medicalMembers = (List<Object>)medicalWithMembers.get('members');
                    
                    vlocity_ins__ContractLineItem__c medicalLineItem = new vlocity_ins__ContractLineItem__c();
                    //////// Process Medical Product
                    try {
                        if (familyIndex == 0) {
                            medicalLineItem.vlocity_ins__AccountId__c = accountId;
                        }
                        medicalLineItem.Name = (String)medicalProduct.get('Name');
                        medicalLineItem.vlocity_ins__Product2Id__c = (Id)medicalProduct.get('Id');
                        medicalLineItem.vlocity_ins__UnitPrice__c = (Decimal)medicalProduct.get('Price');
                        medicalLineItem.vlocity_ins__Quantity__c = 1;                       
                        medicalLineItem.vlocity_ins__EffectiveStartDate__c = DateTime.newInstance(contractEffectiveDate, Time.newInstance(0, 0, 0, 0)).addDays(1);                      
                        
                        manager.indexToParentCLI.put(familyIndex, new Map<Integer, vlocity_ins__ContractLineItem__c>());
                        manager.indexToParentCLI.get(familyIndex).put(index, medicalLineItem);
                        
                        for (Object member : medicalMembers) {
                            Map<String, Object> memberMap = (Map<String, Object>)member;
                            if (memberMap.containsKey('CensusMemberId')) {
                                if (!manager.indexToCLIGCM.containsKey(familyIndex)) {
                                    manager.indexToCLIGCM.put(familyIndex, new Map<Integer, List<String>>());
                                    manager.indexToCLIGCM.get(familyIndex).put(index, new List<String>{(String)memberMap.get('CensusMemberId')});
                                } else if (!manager.indexToCLIGCM.get(familyIndex).containsKey(index)) {
                                    manager.indexToCLIGCM.get(familyIndex).put(index, new List<String>{(String)memberMap.get('CensusMemberId')});
                                } else {
                                    manager.indexToCLIGCM.get(familyIndex).get(index).add((String)memberMap.get('CensusMemberId'));
                                }
                            }
                        }
                    } catch (Exception e) {
                        System.debug('Exception mapContractLineItemsToCreate medicalLineItem ' + e.getMessage() + ' ' + e.getStackTraceString());
                        throw e;
                    }

                    //////// Process Medical Child Products
                    try {
                        List<Map<String, Object>> medicalChildProducts = (List<Map<String, Object>>)productToMembersMap.get('MedicalChildProducts');

                        if (medicalChildProducts != null && !medicalChildProducts.isEmpty()) {
                            for (Map<String, Object> medicalChildProduct : medicalChildProducts) {
                                Map<String, Object> childProduct = (Map<String, Object>)medicalChildProduct.get('product');
                                
                                vlocity_ins__ContractLineItem__c medicalChildLineItem = new vlocity_ins__ContractLineItem__c();
                                if (familyIndex == 0) {
                                    medicalChildLineItem.vlocity_ins__AccountId__c = accountId;
                                }
                                medicalChildLineItem.Name = (String)childProduct.get('Name');
                                medicalChildLineItem.vlocity_ins__Product2Id__c = (Id)childProduct.get('Id');
                                medicalChildLineItem.vlocity_ins__ProductChildItemId__c = (Id)childProduct.get('pciId');
                                medicalChildLineItem.vlocity_ins__ProductId__c = (Id)medicalProduct.get('Id');
                                
                                if (!manager.indexToChildCLI.containsKey(familyIndex)) {
                                    manager.indexToChildCLI.put(familyIndex, new Map<Integer, List<vlocity_ins__ContractLineItem__c>>());
                                    manager.indexToChildCLI.get(familyIndex).put(index, new List<vlocity_ins__ContractLineItem__c>{medicalChildLineItem});
                                } else if (!manager.indexToChildCLI.get(familyIndex).containsKey(index)) {
                                    manager.indexToChildCLI.get(familyIndex).put(index, new List<vlocity_ins__ContractLineItem__c>{medicalChildLineItem});
                                } else {
                                    manager.indexToChildCLI.get(familyIndex).get(index).add(medicalChildLineItem);
                                }
                            }
                        }
                    } catch (Exception e) {
                        System.debug('Exception mapContractLineItemsToCreate medicalChildLineItem ' + e.getMessage() + ' ' + e.getStackTraceString());
                        throw e;
                    }
                }

                // Process Ancillary Products
                try {
                    List<Map<String, Object>> ancillaryProducts = (List<Map<String, Object>>)productToMembersMap.get('Ancillaries');
                    if (ancillaryProducts != null && !ancillaryProducts.isEmpty()) {
                        for (Map<String, Object> ancillaryProduct : ancillaryProducts) {
                            index++;
                            Map<String, Object> product = (Map<String, Object>)ancillaryProduct.get('product');
                            List<Object> ancilaryMembers = (List<Object>)ancillaryProduct.get('members');
                           
                            vlocity_ins__ContractLineItem__c ancillaryLineItem = new vlocity_ins__ContractLineItem__c();
                            ancillaryLineItem.Name = (String)product.get('Name');
                            ancillaryLineItem.vlocity_ins__Product2Id__c = (Id)product.get('Id');
                            if (familyIndex == 0) {
                                ancillaryLineItem.vlocity_ins__AccountId__c = accountId;
                            }
                            ancillaryLineItem.vlocity_ins__EffectiveStartDate__c = DateTime.newInstance(contractEffectiveDate, Time.newInstance(0, 0, 0, 0)).addDays(1);
                            ancillaryLineItem.vlocity_ins__Quantity__c = 1;
                            ancillaryLineItem.vlocity_ins__UnitPrice__c = (Decimal)product.get('Price');
                            manager.indexToParentCLI.get(familyIndex).put(index, ancillaryLineItem);

                            for (Object member : ancilaryMembers) {
                                Map<String, Object> memberMap = (Map<String, Object>)member;                                
                                if (memberMap.containsKey('CensusMemberId')) {
                                    if (!manager.indexToCLIGCM.containsKey(familyIndex)) {
                                        manager.indexToCLIGCM.put(familyIndex, new Map<Integer, List<String>>());
                                        manager.indexToCLIGCM.get(familyIndex).put(index, new List<String>{(String)memberMap.get('CensusMemberId')});
                                    } else if (!manager.indexToCLIGCM.get(familyIndex).containsKey(index)) {
                                        manager.indexToCLIGCM.get(familyIndex).put(index, new List<String>{(String)memberMap.get('CensusMemberId')});
                                    } else {
                                        manager.indexToCLIGCM.get(familyIndex).get(index).add((String)memberMap.get('CensusMemberId'));
                                    }
                                } else {
                                    List<vlocity_ins__ContractLineItem__c> ancillaryLineItems = new List<vlocity_ins__ContractLineItem__c>();
                                    ancillaryLineItems.add(ancillaryLineItem);
                                }
                            }
                            /////// Process Ancillary Child Products
                            if (ancillaryProduct.containsKey('childProducts')) {
                                List<Map<String, Object>> childProducts = (List<Map<String, Object>>)ancillaryProduct.get('childProducts');
                                for (Map<String, Object> childProduct : childProducts) {                 
                                    if (childProduct.containsKey('RecordTypeName__c') && (String)childProduct.get('RecordTypeName__c') == 'CoverageSpec') {
                                        vlocity_ins__ContractLineItem__c ancillaryChildLineItem = new vlocity_ins__ContractLineItem__c();
                                        ancillaryChildLineItem.Name = (String)childProduct.get('Name');
                                        ancillaryChildLineItem.vlocity_ins__Product2Id__c = (Id)childProduct.get('Id');
                                        if (familyIndex == 0) {
                                            ancillaryChildLineItem.vlocity_ins__AccountId__c = accountId;
                                        }
                                        ancillaryChildLineItem.vlocity_ins__ProductId__c = (Id)childProduct.get('Id');
                                        if (!manager.indexToChildCLI.containsKey(familyIndex)) {
                                            manager.indexToChildCLI.put(familyIndex, new Map<Integer, List<vlocity_ins__ContractLineItem__c>>());
                                            manager.indexToChildCLI.get(familyIndex).put(index, new List<vlocity_ins__ContractLineItem__c>{ancillaryChildLineItem});
                                        } else if (!manager.indexToChildCLI.get(familyIndex).containsKey(index)) {
                                            manager.indexToChildCLI.get(familyIndex).put(index, new List<vlocity_ins__ContractLineItem__c>{ancillaryChildLineItem});
                                        } else {
                                            manager.indexToChildCLI.get(familyIndex).get(index).add(ancillaryChildLineItem);
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch (Exception e) {
                    System.debug('Exception mapContractLineItemsToCreate ancillaryLineItem ' + e.getMessage() + ' ' + e.getStackTraceString());
                    throw e;
                }
            } catch (Exception e) {
                System.debug('Exception mapContractLineItemsToCreate ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw e;
            }
        }
    }
    private void mapMedicalQuestions() {
        try {
            if((Map<String, Object>)manager.inputMap.get('STEP_MedicalQuestions') != null){

                Map<String, Object> stepMedicalQuestions = (Map<String, Object>)manager.inputMap.get('STEP_MedicalQuestions');
                Map<String, Object> soChanges = (Map<String, Object>)manager.inputMap.get('soChanges');

                Map<String, Object> reasons = (Map<String, Object>) soChanges.get('soReasons');
                Boolean haveAddMember = (Boolean) reasons.get('addMember');
                Boolean haveProgramUpgrade = (Boolean) reasons.get('programUpgrade');

                Map<String, Map<String, Object>> oldMembers = new Map<String, Map<String, Object>>();
                Set<Id> oldMembersIds = new Set<Id>();

                if (manager.censusMembersInSpinOffContract != null) {
                    for (Map<String, Object> member : manager.censusMembersInSpinOffContract) {
                        Boolean isRemoveMember = (Boolean) member.get('IsRemoveMember');
                        Boolean isNewMember = (Boolean) member.get('IsNewMember');
                        String censusId = (String) member.get('Id');
                        String accountId = (String) member.get('PersonAccountId');

                        if (isNewMember == false && isRemoveMember == false) {
                            Map<String, Object> memberInfo = new Map<String, Object>();
                            memberInfo.put('censusId', censusId);
                            memberInfo.put('accountId', accountId); 
                
                            oldMembers.put(censusId, memberInfo);
   
                            oldMembersIds.add((Id)member.get('PersonAccountId'));                       
                        }
                    }
                }
                                
                // We need to retrieve active medical questions (ARC_MedicalConditions__c and vlocity_ins__ConsumerDrug__c) for old members to if we dont have a program upgrade and clone them
                if(!oldMembersIds.isEmpty()){
                    List<ARC_MedicalConditions__c> medicalConditionsToClone =   [SELECT Id, Name, ARC_Active__c, ARC_ParentsOrSiblingsDiagnosed__c, ARC_ParentsOrSiblingsDiagnosedNote__c, ARC_ParentsOrSiblingsDiagnosedDate__c, 
                                                                                        ARC_UnexplainedConditions__c, ARC_Unexplained_Conditions_Notes__c, ARC_Unexplained_Conditions_Date__c,
                                                                                        ARC_Tests__c, ARC_Tests_Notes__c, ARC_Tests_Date__c,
                                                                                        ARC_IllegalDrugsAlcohol__c, ARC_Illegal_Drugs_Alcohol_Notes__c, ARC_Illegal_Drugs_Alcohol_Date__c,
                                                                                        ARC_LicenceSuspended__c, ARC_LicenceSuspendedNote__c, ARC_LicenseSuspendedDate__c, 
                                                                                        ARC_Condition__c, ARC_OtherConditions__c,
                                                                                        ARC_Type_Of_Cancer__c, ARC_Year_Diagnosed_Cancer__c, ARC_Currently_Under_Treatment__c, ARC_PersonAccount__c, ARC_CensusMember__c 
                                                                                FROM  ARC_MedicalConditions__c 
                                                                                WHERE ARC_Active__c = true AND ARC_PersonAccount__c IN :oldMembersIds];
                    List<vlocity_ins__ConsumerDrug__c> consumerDrugToClone = [  SELECT Id, Name, vlocity_ins__PrescribedBy__c, vlocity_ins__MedicationStartDate__c, vlocity_ins__MedicationEndDate__c, ARC_Reason__c, ARC_Active__c, ARC_PersonAccount__c, ARC_CensusMember__c, vlocity_ins__IsActive__c, vlocity_ins__StopReason__c
                                                                                FROM  vlocity_ins__ConsumerDrug__c 
                                                                                WHERE ARC_Active__c = true AND ARC_PersonAccount__c IN :oldMembersIds];
                    
                    if (!medicalConditionsToClone.isEmpty()) {
                        for (ARC_MedicalConditions__c mc : medicalConditionsToClone) {

                            if(!haveProgramUpgrade){
                                ARC_MedicalConditions__c mcToClone = mc.clone();
                                mcToClone.ARC_CensusMember__c = null;
                        
                                if (!manager.mapMedicalConditionsToInsert.containsKey(mc.ARC_CensusMember__c)) {
                                    manager.mapMedicalConditionsToInsert.put(mc.ARC_CensusMember__c, new List<ARC_MedicalConditions__c>());
                                }
                                manager.mapMedicalConditionsToInsert.get(mc.ARC_CensusMember__c).add(mcToClone);
                            }

                            mc.ARC_Active__c = false;
                            manager.medicalConditionsToUpsertList.add(mc);
                        }
                    }

                    if (!consumerDrugToClone.isEmpty()) {
                        for (vlocity_ins__ConsumerDrug__c cd : consumerDrugToClone) {
                            if(!haveProgramUpgrade){
                                vlocity_ins__ConsumerDrug__c cdToClone = cd.clone();
                                cdToClone.ARC_CensusMember__c = null;
    
                                if (!manager.mapConsumerDrugsToInsert.containsKey(cd.ARC_CensusMember__c)) {
                                    manager.mapConsumerDrugsToInsert.put(cd.ARC_CensusMember__c, new List<vlocity_ins__ConsumerDrug__c>());
                                }
                                manager.mapConsumerDrugsToInsert.get(cd.ARC_CensusMember__c).add(cdToClone);
                            }

                            cd.ARC_Active__c = false;
                            cd.vlocity_ins__IsActive__c = false;
                            cd.vlocity_ins__StopReason__c = 'Duplicate';
                            cd.vlocity_ins__MedicationEndDate__c = null;
                            manager.consumerDrugsToUpsertList.add(cd);                            
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
                
                if (singleRecordBlocksMap != null) {
                    for (String memberId : singleRecordBlocksMap.keySet()) {
                        ARC_MedicalConditions__c mc = singleRecordBlocksMap.get(memberId);
                        if (!manager.mapMedicalConditionsToInsert.containsKey(memberId)) {
                            manager.mapMedicalConditionsToInsert.put(memberId, new List<ARC_MedicalConditions__c>());
                        }

                        if (!memberId.startsWith('MEM-')) {
                            mc.ARC_CensusMember__c = null;
                            mc.ARC_PersonAccount__c = oldMembers != null && oldMembers.containsKey(memberId) ? (Id)oldMembers.get(memberId).get('accountId') : null;
                        } 
                        manager.mapMedicalConditionsToInsert.get(memberId).add(mc);
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

                if(cancerMap != null){
                    for (String memberId : cancerMap.keySet()) {
                        List<ARC_MedicalConditions__c> medicalConditionsList = cancerMap.get(memberId);
                        for (ARC_MedicalConditions__c mc : medicalConditionsList) {

                            if (!manager.mapMedicalConditionsToInsert.containsKey(memberId)) {
                                manager.mapMedicalConditionsToInsert.put(memberId, new List<ARC_MedicalConditions__c>());
                            }

                            if (!memberId.startsWith('MEM-')) {
                                mc.ARC_CensusMember__c = null;
                                mc.ARC_PersonAccount__c = oldMembers != null && oldMembers.containsKey(memberId) ? (Id)oldMembers.get(memberId).get('accountId') : null;
                                
                            } 
                            manager.mapMedicalConditionsToInsert.get(memberId).add(mc);
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

                if(prescriptionsMap != null){
                    for (String memberId : prescriptionsMap.keySet()) {
                        List<vlocity_ins__ConsumerDrug__c> medicalConditionsList = prescriptionsMap.get(memberId);
                        for (vlocity_ins__ConsumerDrug__c mc : medicalConditionsList) {
                            if (!manager.mapConsumerDrugsToInsert.containsKey(memberId)) {
                                manager.mapConsumerDrugsToInsert.put(memberId, new List<vlocity_ins__ConsumerDrug__c>());
                            }
                            if (!memberId.startsWith('MEM-')) {
                                mc.ARC_CensusMember__c = null;
                                mc.ARC_PersonAccount__c = oldMembers != null && oldMembers.containsKey(memberId) ? (Id)oldMembers.get(memberId).get('accountId') : null;

                            } 
                            manager.mapConsumerDrugsToInsert.get(memberId).add(mc);
                        }
                    }
                }

                // Process Group 4 (EB_Physicians) - Question 9
                List<Object> physiciansListToProcess = convertObjectToList(stepMedicalQuestions.get('EB_Physicians'));
 
                if (physiciansListToProcess != null) {
                    for (Object recordObj : physiciansListToProcess) {
                        if (recordObj != null) {
                            Map<String, Object> recordMap = (Map<String, Object>)recordObj;
                            String memberId = (String)recordMap.get('memberId');
                            String physicianName = (String)recordMap.get('TXT_PhysicianName');
                            String physicianCity = (String)recordMap.get('TXT_PhysicianCity');
                            String physicianPhone = (String)recordMap.get('TXT_PhysicianPhone');
                            String accountId = oldMembers != null && oldMembers.containsKey(memberId) ? (Id)oldMembers.get(memberId).get('accountId') : null;

                            if (!String.isBlank(physicianName) || !String.isBlank(physicianCity) || !String.isBlank(physicianPhone)) {
                                Map<String, Object> physicianMemberInfo = new Map<String, Object>();
                                physicianMemberInfo.put('ARC_PhysicianName__c', physicianName);
                                physicianMemberInfo.put('ARC_PhysicianCity__c', physicianCity);
                                physicianMemberInfo.put('ARC_PhysicianPhone__c', physicianPhone);
                                physicianMemberInfo.put('accountId', accountId);

                                manager.mapPhysicianDataToUpdate.put(memberId, physicianMemberInfo);
                            }
                        }
                    }
                } 
            }
        } catch (Exception e) {
            System.debug('mapContractParticipants line:' + e.getLineNumber() + ' ' + e.getMessage() + ' ' + e.getStackTraceString() );
            throw e;
        }
    }
    private void mapContractParticipants() {
       try {
            // Iterate over each familiy (Remove member, Spin off / Multiple Spin Off)
            for (Integer familyGroup : manager.censusMembersMap.keySet()) {
                // Iterate over each member of each family
                for(Map<String,Object> member : manager.censusMembersMap.get(familyGroup)) {
                    if ((Boolean)member.get('IsRemoveMember') != true) {
                        ARC_ContractParticipant__c newContractParticipant = new ARC_ContractParticipant__c();
                        // ARC_ContractParticipant__c carryOverCP = familyGroup == 0 ? carryOverContractParticipantMap.get((String)member.get('Id')) : new ARC_ContractParticipant__c(); // Get CP of Remove Member contract

                        // Map record fields
                        newContractParticipant.ARC_Address__CountryCode__s = 'US';
                        newContractParticipant.ARC_Address__Street__s = String.valueOf(member.get('ARC_PhysicalAddressStreet__c'));
                        newContractParticipant.ARC_Address__City__s = String.valueOf(member.get('ARC_PhysicalAddressCity__c'));
                        newContractParticipant.ARC_Address__StateCode__s = String.valueOf(member.get('ARC_PhysicalAddressState__c'));
                        newContractParticipant.ARC_Address__PostalCode__s = String.valueOf(member.get('ARC_PhysicalAddressZipCode__c'));
                        newContractParticipant.ARC_FirstName__c = String.valueOf(member.get('vlocity_ins__FirstName__c'));
                        newContractParticipant.ARC_LastName__c = String.valueOf(member.get('vlocity_ins__LastName__c'));
                        newContractParticipant.Name = String.valueOf(String.valueOf(member.get('vlocity_ins__FirstName__c'))) + ' ' + String.valueOf(member.get('vlocity_ins__LastName__c'));
                        newContractParticipant.ARC_Email__c = String.valueOf(member.get('vlocity_ins__Email__c'));
                        newContractParticipant.ARC_Gender__c = String.valueOf(member.get('vlocity_ins__Gender__c'));
                        newContractParticipant.ARC_BirthDate__c	 = Date.valueOf(String.valueOf(member.get('vlocity_ins__Birthdate__c')));
                        newContractParticipant.ARC_Phone__c = String.valueOf(member.get('ARC_Phone__c'));
                        newContractParticipant.ARC_Height__c = String.valueOf(member.get('ARC_HeightFeet__c')) != null && String.valueOf(member.get('ARC_HeightInches__c')) != null ? String.valueOf(member.get('ARC_HeightFeet__c')) + '\'' + String.valueOf(member.get('ARC_HeightInches__c')) : null;
                        newContractParticipant.ARC_Weight__c = String.valueOf(member.get('ARC_Weight__c')) != null ? String.valueOf(member.get('ARC_Weight__c')) : null;
                        newContractParticipant.ARC_PersonAccount__c = member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false ? String.valueOf(member.get('PersonAccountId')) : null;
                        newContractParticipant.ARC_Relationship__c = member.containsKey('ARC_Relationship__c') ? String.valueOf(member.get('ARC_Relationship__c')) : null;
                        newContractParticipant.ARC_Smoker__c = member.containsKey('ARC_Smoker__c') && convertToBoolean(member.get('ARC_Smoker__c')) != null ? convertToBoolean(member.get('ARC_Smoker__c')) : false;


                        // Add mapped CP and map with Census Member ID
                        manager.fictionalMemberIdToContractParticipant.put((String)member.get('Id'), newContractParticipant); 
                    }
                }
            }
        }catch (Exception e) {
            System.debug('Exception creating Contract Participant: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }
    }
    private void mapChargentOrders() {
        try {
            // Get required information
            String previousContractId = (String)((Map<String, Object>)manager.inputMap).get('ContractIdSelected');
            Boolean isMultiSpinOff = (Boolean)((Map<String,Object>)((Map<String, Object>)manager.inputMap).get('STEP_MembersToSpinOff')).get('FRML_multipleSpinOff');
            List<Object> removeMemberPlansList = (List<Object>)((Map<String,Object>)((Map<String, Object>)manager.inputMap).get('price_calculation_removemember_spinoff')).get('plans');
        
            // Remove Member Contract Chargent Orders - JUST RECURRING IN THIS CASE

            // Iterate over Remove Member contract plans to get each plan price
            Decimal removeMemberContractRecurringPrice = 0;
            for (Object removeMemberPlan : removeMemberPlansList) {
                Map<String,Object> productMap = (Map<String,Object>)((Map<String,Object>)removeMemberPlan).get('selectedProduct');
                Decimal productPrice = (Decimal)productMap.get('Price');
                removeMemberContractRecurringPrice += productPrice != null ? productPrice : 0;
            }
            
            // Get recurring chargent order information of original contract
            ChargentOrders__ChargentOrder__c oldChargOrder = [SELECT Id,ChargentOrders__Charge_Date__c, ChargentOrders__Account__c, ChargentOrders__Bank_Account_Last_4__c, ChargentOrders__Bank_Account_Name__c, ChargentOrders__Bank_Routing_Number__c,ChargentOrders__Bank_Account_Number__c,ChargentOrders__Bank_Account_Type__c,ChargentOrders__Bank_Name__c,ChargentOrders__Billing_First_Name__c,ARC_FirstMonthPayed__c , ChargentOrders__Billing_Last_Name__c, ChargentOrders__Billing_Address__c, ChargentOrders__Billing_City__c, ChargentOrders__Billing_State__c, ChargentOrders__Billing_Zip_Postal__c, ChargentOrders__Card_Expiration_Month__c, ChargentOrders__Card_Expiration_Year__c, ChargentOrders__Card_Last_4__c, ChargentOrders__Card_Month_Indicator__c, ChargentOrders__Card_Number__c, ChargentOrders__Card_Type__c, ChargentOrders__Card_Year_Indicator__c, ChargentOrders__Charge_Amount__c, ChargentOrders__Description__c, ChargentOrders__Gateway__c, ChargentOrders__Payment_Frequency__c, ChargentOrders__Payment_Method__c, ChargentOrders__Payment_Status__c, ChargentOrders__Subtotal__c, ChargentOrders__Manual_Charge__c, ChargentOrders__Tokenization__c FROM ChargentOrders__ChargentOrder__c WHERE ARC_Contract__c = :previousContractId AND ChargentOrders__Description__c LIKE '%Recurring%' LIMIT 1];

            ChargentOrders__ChargentOrder__c recurringRemoveMemberCO = new ChargentOrders__ChargentOrder__c();
            String paymentMethodOld = (String)oldChargOrder.ChargentOrders__Payment_Method__c;

            // Map recurring CO fields of Remove Member Contract
            recurringRemoveMemberCO.ChargentOrders__Account__c = oldChargOrder.ChargentOrders__Account__c; 
            recurringRemoveMemberCO.ARC_FirstMonthPayed__c = oldChargOrder.ARC_FirstMonthPayed__c;
            recurringRemoveMemberCO.ChargentOrders__Billing_Address__c = oldChargOrder.ChargentOrders__Billing_Address__c;
            recurringRemoveMemberCO.ChargentOrders__Billing_City__c = oldChargOrder.ChargentOrders__Billing_City__c;
            recurringRemoveMemberCO.ChargentOrders__Billing_First_Name__c = oldChargOrder.ChargentOrders__Billing_First_Name__c;
            recurringRemoveMemberCO.ChargentOrders__Billing_Last_Name__c = oldChargOrder.ChargentOrders__Billing_Last_Name__c;
            recurringRemoveMemberCO.ChargentOrders__Billing_State__c = oldChargOrder.ChargentOrders__Billing_State__c;
            recurringRemoveMemberCO.ChargentOrders__Billing_Zip_Postal__c = oldChargOrder.ChargentOrders__Billing_Zip_Postal__c;
            recurringRemoveMemberCO.ChargentOrders__Card_Expiration_Month__c = oldChargOrder.ChargentOrders__Card_Expiration_Month__c;
            recurringRemoveMemberCO.ChargentOrders__Card_Expiration_Year__c = oldChargOrder.ChargentOrders__Card_Expiration_Year__c;
            recurringRemoveMemberCO.ChargentOrders__Card_Last_4__c = oldChargOrder.ChargentOrders__Card_Last_4__c;
            recurringRemoveMemberCO.ChargentOrders__Charge_Date__c = oldChargOrder.ChargentOrders__Charge_Date__c;
            recurringRemoveMemberCO.ChargentOrders__Description__c = 'Recurring Monthly Order';
            recurringRemoveMemberCO.ChargentOrders__Tokenization__c = oldChargOrder.ChargentOrders__Tokenization__c;
            recurringRemoveMemberCO.ChargentOrders__Gateway__c = oldChargOrder.ChargentOrders__Gateway__c;
            recurringRemoveMemberCO.ChargentOrders__Payment_Frequency__c = 'Monthly';
            recurringRemoveMemberCO.ChargentOrders__Payment_Method__c = oldChargOrder.ChargentOrders__Payment_Method__c;
            recurringRemoveMemberCO.ChargentOrders__Payment_Start_Date__c  = Date.today();
            recurringRemoveMemberCO.ChargentOrders__Payment_Status__c = 'Stopped';
            recurringRemoveMemberCO.ChargentOrders__Manual_Charge__c  = true;
            if(paymentMethodOld == 'Bank Account'){
                recurringRemoveMemberCO.ChargentOrders__Bank_Account_Last_4__c = oldChargOrder.ChargentOrders__Bank_Account_Last_4__c;
                recurringRemoveMemberCO.ChargentOrders__Bank_Account_Name__c = oldChargOrder.ChargentOrders__Bank_Account_Name__c;
                recurringRemoveMemberCO.ChargentOrders__Bank_Routing_Number__c = oldChargOrder.ChargentOrders__Bank_Routing_Number__c;
                recurringRemoveMemberCO.ChargentOrders__Bank_Account_Number__c = oldChargOrder.ChargentOrders__Bank_Account_Number__c;
                recurringRemoveMemberCO.ChargentOrders__Bank_Account_Type__c = oldChargOrder.ChargentOrders__Bank_Account_Type__c;
                recurringRemoveMemberCO.ChargentOrders__Bank_Name__c = oldChargOrder.ChargentOrders__Bank_Name__c;
            } else if(paymentMethodOld == 'Credit Card'){
                recurringRemoveMemberCO.ChargentOrders__Card_Month_Indicator__c = oldChargOrder.ChargentOrders__Card_Month_Indicator__c; 
                recurringRemoveMemberCO.ChargentOrders__Card_Number__c = oldChargOrder.ChargentOrders__Card_Number__c;
                recurringRemoveMemberCO.ChargentOrders__Card_Type__c = oldChargOrder.ChargentOrders__Card_Type__c;
                recurringRemoveMemberCO.ChargentOrders__Card_Year_Indicator__c = oldChargOrder.ChargentOrders__Card_Year_Indicator__c;
            }
            recurringRemoveMemberCO.ChargentOrders__Subtotal__c = removeMemberContractRecurringPrice;
            recurringRemoveMemberCO.ChargentOrders__Charge_Amount__c = removeMemberContractRecurringPrice;

            manager.chargentOrdersToInsertMap.put('recurringRemoveMemberChargent',recurringRemoveMemberCO);


            // Single Spin Off Contract Chargent Orders - RECURRING CO AND CHANGE FEE IF APPLICABLE
            if (isMultiSpinOff == false) {
                ChargentOrders__ChargentOrder__c recurringSpinOffCO = new ChargentOrders__ChargentOrder__c();

                // Get payment method and information
                
                
                Map<String,Object> creditCardInfoMap = new Map<String,Object>();
                Map<String,Object> bankAccountInfoMap = new Map<String,Object>();
                Map<String, Object> Step_PaymentChangeFee = (Map<String, Object>) manager.inputMap.get('STEP_ChargentPayment') != null ? (Map<String, Object>)manager.inputMap.get('STEP_ChargentPayment') : null;
                Map<String, Object> BLK_ChargeFee = (Map<String, Object>)Step_PaymentChangeFee.get('BLK_ChargeFee');
                Map<String,Object> BLK_PaymentInfo = (Map<String,Object>)BLK_ChargeFee.get('BLK_PaymentInfo');
                String paymentMethod = (String)BLK_ChargeFee.get('RAD_MethodOfPayment'); // Payment method chosen
                // Get payment information depending on payment method
                if (paymentMethod == 'Credit Card' && BLK_PaymentInfo.containsKey('BLK_CreditCard') && BLK_PaymentInfo.get('BLK_CreditCard') != null) {
                    creditCardInfoMap = (Map<String,Object>)BLK_PaymentInfo.get('BLK_CreditCard');
                } else if (paymentMethod == 'Bank Account' && BLK_PaymentInfo.containsKey('BLK_BankAccount') && BLK_PaymentInfo.get('BLK_BankAccount') != null) {
                    bankAccountInfoMap = (Map<String,Object>)BLK_PaymentInfo.get('BLK_BankAccount');
                }

                // Get Gateway IDs for Credit Card and Bank Account payment methods
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

                // Get spin off primary member information
                Map<String,Object> spinOffPrimaryMember = new Map<String,Object>();
                for (Map<String,Object> spinOffMember : manager.censusMembersInSpinOffContract) {
                    if ((String)spinOffMember.get('ARC_Relationship__c') == 'Primary') {
                        spinOffPrimaryMember = spinOffMember;
                    }
                }

                // Get Spin Off Products Summary
                Map<String,Object> spinOffProductsSummaryMap = (Map<String,Object>)((Map<String,Object>)((Map<String, Object>)manager.inputMap).get('PlansSummary')).get('BLK_ProductSummary');
                Decimal spinOffFeeAmount = Decimal.valueOf(((String)spinOffProductsSummaryMap.get('TXT_FeeAmount')).remove('$'));
                Decimal spinOffMonthlyAmount = Decimal.valueOf(((String)spinOffProductsSummaryMap.get('TXT_MonthlyPrice')).remove('$'));

  
                recurringSpinOffCO.ARC_FirstMonthPayed__c = false;
                
                
                
                
                recurringSpinOffCO.ChargentOrders__Description__c = 'Recurring Monthly Order';
                recurringSpinOffCO.ChargentOrders__Payment_Frequency__c = 'Monthly';
                recurringSpinOffCO.ChargentOrders__Payment_Method__c = paymentMethod;
                recurringSpinOffCO.ChargentOrders__Payment_Start_Date__c  = Date.today();
                recurringSpinOffCO.ChargentOrders__Payment_Status__c = 'Stopped';
                recurringSpinOffCO.ChargentOrders__Manual_Charge__c  = true;
                
                recurringSpinOffCO.ChargentOrders__Subtotal__c = spinOffMonthlyAmount;
                recurringSpinOffCO.ChargentOrders__Charge_Amount__c = spinOffMonthlyAmount;
                recurringSpinOffCO.ChargentOrders__Billing_Address__c = paymentMethod == 'Credit Card' && (String)creditCardInfoMap.get('TXT_BillingAddress_Street') != null ?(String)creditCardInfoMap.get('TXT_BillingAddress_Street') : (String)spinOffPrimaryMember.get('ARC_PhysicalAddressStreet__c');
                recurringSpinOffCO.ChargentOrders__Billing_City__c = paymentMethod == 'Credit Card' && (String)creditCardInfoMap.get('TXT_BillingAddress_City') != null  ? (String)creditCardInfoMap.get('TXT_BillingAddress_City') : (String)spinOffPrimaryMember.get('ARC_PhysicalAddressCity__c');
                recurringSpinOffCO.ChargentOrders__Billing_State__c = paymentMethod == 'Credit Card' && (String)creditCardInfoMap.get('TXT_BillingAddress_State') != null ?(String)creditCardInfoMap.get('TXT_BillingAddress_State') : (String)spinOffPrimaryMember.get('ARC_PhysicalAddressState__c');
                recurringSpinOffCO.ChargentOrders__Billing_Zip_Postal__c = paymentMethod == 'Credit Card' && (String)creditCardInfoMap.get('TXT_BillingAddress_ZipCode') != null ? (String)creditCardInfoMap.get('TXT_BillingAddress_ZipCode') : (String)spinOffPrimaryMember.get('ARC_PhysicalAddressZipCode__c');
                if(paymentMethod == 'Credit Card'){
                    recurringSpinOffCO.ChargentOrders__Card_Expiration_Month__c = (String)creditCardInfoMap.get('SLC_ExpirationMonth') ;
                    recurringSpinOffCO.ChargentOrders__Card_Expiration_Year__c = (String)creditCardInfoMap.get('SLC_Year') ;
                    recurringSpinOffCO.ChargentOrders__Card_Month_Indicator__c = (String)creditCardInfoMap.get('SLC_ExpirationMonth') ;
                    recurringSpinOffCO.ChargentOrders__Card_Year_Indicator__c = (String)creditCardInfoMap.get('SLC_Year') ;
                    recurringSpinOffCO.ChargentOrders__Card_Number__c = (String)creditCardInfoMap.get('TXT_CardNumber') ;
                    recurringSpinOffCO.ChargentOrders__Card_Last_4__c = ((String)creditCardInfoMap.get('TXT_CardNumber')).right(4) ;
                    recurringSpinOffCO.ChargentOrders__Card_Type__c = creditCardType((String)creditCardInfoMap.get('TXT_CardNumber')) ;
                    
                    recurringSpinOffCO.ChargentOrders__Gateway__c = gatewayIdCC ;
                    recurringSpinOffCO.ChargentOrders__Billing_First_Name__c = (String)creditCardInfoMap.get('TXT_FirstNameOnCard') != null ? (String)creditCardInfoMap.get('TXT_FirstNameOnCard') : (String)spinOffPrimaryMember.get('vlocity_ins__FirstName__c');
                    recurringSpinOffCO.ChargentOrders__Billing_Last_Name__c = (String)creditCardInfoMap.get('TXT_LastNameOnCard') != null ? (String)creditCardInfoMap.get('TXT_LastNameOnCard') : (String)spinOffPrimaryMember.get('vlocity_ins__LastName__c');
                } else if (paymentMethod == 'Bank Account') {
                    recurringSpinOffCO.ChargentOrders__Bank_Account_Number__c = (String)bankAccountInfoMap.get('TXT_AccNumber')  ;
                    recurringSpinOffCO.ChargentOrders__Bank_Account_Last_4__c = ((String)bankAccountInfoMap.get('TXT_AccNumber')).right(4) ;
                    recurringSpinOffCO.ChargentOrders__Bank_Account_Name__c =  (String)bankAccountInfoMap.get('TXT_FirstNameOnAccount') + ' ' + (String)bankAccountInfoMap.get('TXT_LastNameOnAccount') ;
                    recurringSpinOffCO.ChargentOrders__Bank_Account_Type__c = (String)bankAccountInfoMap.get('SLC_AccType') ;
                    recurringSpinOffCO.ChargentOrders__Bank_Name__c = (String)bankAccountInfoMap.get('TXT_BankName') ;
                    recurringSpinOffCO.ChargentOrders__Bank_Routing_Number__c = (String)bankAccountInfoMap.get('TXT_RoutingNumber') ;
                    recurringSpinOffCO.ChargentOrders__Gateway__c = gatewayIdBA ;
                    recurringSpinOffCO.ChargentOrders__Billing_First_Name__c = (String)bankAccountInfoMap.get('TXT_FirstNameOnAccount') != null ? (String)bankAccountInfoMap.get('TXT_FirstNameOnAccount') : (String)spinOffPrimaryMember.get('vlocity_ins__FirstName__c');
                    recurringSpinOffCO.ChargentOrders__Billing_Last_Name__c = (String)bankAccountInfoMap.get('TXT_LastNameOnAccount') != null ? (String)bankAccountInfoMap.get('TXT_LastNameOnAccount') : (String)spinOffPrimaryMember.get('vlocity_ins__LastName__c');
                }

                manager.chargentOrdersToInsertMap.put('recurringSpinOffChargent',recurringSpinOffCO);

                // Get boolean if Fee is applicable
                Boolean feeIsApplicable = (Boolean)((Map<String,Object>)((Map<String, Object>)manager.inputMap).get('soChanges')).get('feeApplicable') != null ? (Boolean)((Map<String,Object>)((Map<String, Object>)manager.inputMap).get('soChanges')).get('feeApplicable') : false;
                //  Check if change fee is waived or not
                String feeIsCharged = feeIsApplicable == true ? (String)((Map<String,Object>)((Map<String, Object>)manager.inputMap).get('STEP_ChargentPayment')).get('RAD_ChargeAppFeeDefTrue') : null;
                
                // Change fee Chargent Order if applicable - Single Spin Off Contract
                if (feeIsApplicable == true && feeIsCharged == 'Yes') {
                    ChargentOrders__ChargentOrder__c changeFeeSpinOffCO = new ChargentOrders__ChargentOrder__c();

                    // Populate change fee chargent orders depending if it is with Credit Card or Bank Account
                    
                    
                    if(paymentMethod == 'Credit Card'){
                        changeFeeSpinOffCO.ChargentOrders__Gateway__c = gatewayIdCC ;
                        changeFeeSpinOffCO.ChargentOrders__Card_Number__c = (String)creditCardInfoMap.get('TXT_CardNumber') ;
                        changeFeeSpinOffCO.ChargentOrders__Card_Month_Indicator__c = (String)creditCardInfoMap.get('SLC_ExpirationMonth') ;
                        changeFeeSpinOffCO.ChargentOrders__Card_Expiration_Month__c = (String)creditCardInfoMap.get('SLC_ExpirationMonth') ;
                        changeFeeSpinOffCO.ChargentOrders__Card_Year_Indicator__c = (String)creditCardInfoMap.get('SLC_Year') ;
                        changeFeeSpinOffCO.ChargentOrders__Card_Expiration_Year__c = (String)creditCardInfoMap.get('SLC_Year') ;
                        changeFeeSpinOffCO.ChargentOrders__Card_Last_4__c = ((String)creditCardInfoMap.get('TXT_CardNumber')).right(4) ;
                        changeFeeSpinOffCO.ChargentOrders__Billing_First_Name__c = (String)creditCardInfoMap.get('TXT_FirstNameOnCard') ;
                        changeFeeSpinOffCO.ChargentOrders__Billing_Last_Name__c = (String)creditCardInfoMap.get('TXT_LastNameOnCard') ;
                    } else if (paymentMethod == 'Bank Account') {
                        changeFeeSpinOffCO.ChargentOrders__Gateway__c = gatewayIdBA;
                        changeFeeSpinOffCO.ChargentOrders__Bank_Routing_Number__c = (String)bankAccountInfoMap.get('TXT_RoutingNumber') ;
                        changeFeeSpinOffCO.ChargentOrders__Bank_Account_Number__c = (String)bankAccountInfoMap.get('TXT_AccNumber') ;
                        changeFeeSpinOffCO.ChargentOrders__Bank_Name__c = (String)bankAccountInfoMap.get('TXT_BankName') ;
                        changeFeeSpinOffCO.ChargentOrders__Bank_Account_Type__c = (String)bankAccountInfoMap.get('SLC_AccType') ;
                        changeFeeSpinOffCO.ChargentOrders__Billing_First_Name__c = (String)bankAccountInfoMap.get('TXT_FirstNameOnAccount') ;
                        changeFeeSpinOffCO.ChargentOrders__Billing_Last_Name__c = (String)bankAccountInfoMap.get('TXT_LastNameOnAccount');
                        changeFeeSpinOffCO.ChargentOrders__Bank_Account_Name__c =  (String)bankAccountInfoMap.get('TXT_FirstNameOnAccount') + ' ' + (String)bankAccountInfoMap.get('TXT_LastNameOnAccount');
                    }
                    changeFeeSpinOffCO.ChargentOrders__Billing_Address__c = paymentMethod == 'Credit Card' && (String)creditCardInfoMap.get('TXT_BillingAddress_Street') != null ? (String)creditCardInfoMap.get('TXT_BillingAddress_Street') : (String)spinOffPrimaryMember.get('ARC_PhysicalAddressStreet__c');
                    changeFeeSpinOffCO.ChargentOrders__Billing_City__c = paymentMethod == 'Credit Card' && (String)creditCardInfoMap.get('TXT_BillingAddress_City') != null ? (String)creditCardInfoMap.get('TXT_BillingAddress_City') : (String)spinOffPrimaryMember.get('ARC_PhysicalAddressCity__c');
                    changeFeeSpinOffCO.ChargentOrders__Billing_State__c = paymentMethod == 'Credit Card' && (String)creditCardInfoMap.get('TXT_BillingAddress_State') != null ? (String)creditCardInfoMap.get('TXT_BillingAddress_State') : (String)spinOffPrimaryMember.get('ARC_PhysicalAddressState__c');
                    changeFeeSpinOffCO.ChargentOrders__Billing_Zip_Postal__c = paymentMethod == 'Credit Card' && (String)creditCardInfoMap.get('TXT_BillingAddress_ZipCode') != null ? (String)creditCardInfoMap.get('TXT_BillingAddress_ZipCode') : (String)spinOffPrimaryMember.get('ARC_PhysicalAddressZipCode__c');

                    changeFeeSpinOffCO.ChargentOrders__Payment_Method__c = paymentMethod ;
                    changeFeeSpinOffCO.ARC_FirstMonthPayed__c = false;
                    changeFeeSpinOffCO.ChargentOrders__Description__c = 'Change Fee';   
                    changeFeeSpinOffCO.ChargentOrders__Payment_Status__c = null;
                    changeFeeSpinOffCO.ChargentOrders__Subtotal__c = spinOffFeeAmount;
                    changeFeeSpinOffCO.ChargentOrders__Charge_Amount__c = spinOffFeeAmount;
                    changeFeeSpinOffCO.ChargentOrders__Payment_Frequency__c = 'Once';
                    changeFeeSpinOffCO.ChargentOrders__Manual_Charge__c = true;

                    manager.chargentOrdersToInsertMap.put('changeFeeSpinOffChargent',changeFeeSpinOffCO);
                }
            }
        } catch (Exception e) {
            System.debug(e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }
    }    
    private void mapHipaaAuthorization() { 
        try {
            if(manager.inputMap.containsKey('STEP_HIPAAAuthorizationForm') && manager.inputMap.get('STEP_HIPAAAuthorizationForm') != null) {

                Map<String, Object> stepHipaa = (Map<String, Object>)manager.inputMap.get('STEP_HIPAAAuthorizationForm');
                String authorizeOthers = (String)stepHipaa.get('RAD_AuthorizeOthers');

                if (stepHipaa.containsKey('EDITBLK_HIPAAAuthorizedParties') && stepHipaa.get('EDITBLK_HIPAAAuthorizedParties') != null) {
                    List<Object> listMembersHipaa = convertObjectToList(stepHipaa.get('EDITBLK_HIPAAAuthorizedParties'));

                    Map<String, Object> guardianInfo = (Map<String, Object>)manager.inputMap.get('STEP_GuardiansInformation');
                    // Internal members hipaa
                    for (Object o : listMembersHipaa) {
                        Map<String, Object> memberHipaa = (Map<String, Object>)o;
                        Boolean isAuthorized = (Boolean)memberHipaa.get('CHK_Authorized');

                        if (isAuthorized) {
                            ARC_HipaaAuthorization__c newHipaa = new ARC_HipaaAuthorization__c();
                            newHipaa.Name = (String)memberHipaa.get('TXT_FullName');
                            newHipaa.ARC_Census__c = null; // vlocity_ins__GroupCensus__c
                            
                            if (guardianInfo != null) {
                                // Guardian
                                newHipaa.ARC_ExternalPersonAuthorized__c = guardianInfo.containsKey('PersonContactId') && guardianInfo.get('PersonContactId') != null ?  (Id)guardianInfo.get('PersonContactId') : null;

                                manager.guardianHippa = newHipaa;
                            } else {
                                newHipaa.ARC_AuthorizedMember__c = null; // vlocity_ins__GroupCensusMember__c

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
                    if(address!= null){
                        newContact.MailingCity = (String)address.get('TXT_AddCity');
                        newContact.MailingCountry = (String)address.get('TXT_AddCountry');
                        newContact.MailingState = (String)address.get('SEL_AddState');
                        newContact.MailingPostalCode = (String)address.get('TXT_AddZipCode');
                        newContact.MailingStreet = (String)address.get('TXT_AddAddress');
                    }
                    newContact.RecordTypeId = recordTypeId;
                    newContact.AccountId = null;
                    
                    manager.hippaExternalContact = newContact;
                }

            }   
            } catch (Exception e) {
                System.debug('Exception creating Hippa Authorizations: ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw e;
            } 
    }
      
    private void insertPromotionDiscount(){
        try {
            if (manager.inputMap.get('STEP_ChargentPayment') != null) {

                Map<String, Object> stepPaymentChangeFee = (Map<String, Object>) manager.inputMap.get('STEP_ChargentPayment');
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

                        manager.promotionDiscountToInsert.add(discount);
                    } 
                }
            } 
        } catch (Exception e) {
            System.debug('Exception insertPromotionDiscount: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /*******************************************************************
    * @MethodName         :   mapCriticalCarePromotionDiscount
    * @Description        :   Detects members in the Spin Off contract that have both
    *                         PROG_CriticalCare (SMART) and PROG_AccidentalInjury (AIDD)
    *                         in price_calculation (familyIndex = 1) and stores bundle
    *                         indexes for DML resolution.
    ********************************************************************/
    private void mapCriticalCarePromotionDiscount(String action) {
        try {
            System.debug('Mapping Critical Care / Accidental Injury Promotion Discount (SO)');

            Set<String> PREMIER_ANCILLARY_CODES = new Set<String>{ 'PROG_CriticalCare', 'PROG_AccidentalInjury' };

            // REMOVE FAMILY DISCOUNT

            Map<String, Object> priceCalculationRemoveMember = (Map<String, Object>)manager.inputMap.get('price_calculation_removemember_spinoff');
            List<Object> plansRemoveMember = (List<Object>)priceCalculationRemoveMember.get('plans');

            Map<String, String> productCodeToId = new Map<String, String>();
            Map<String, Set<String>> oriProductCodeToMemberIds = new Map<String, Set<String>>();

            for (Object planObj : plansRemoveMember) {
                Map<String, Object> plan = (Map<String, Object>)planObj;
                Map<String,Object> selectedProduct = (Map<String,Object>)plan.get('selectedProduct');
                String code = (String)selectedProduct.get('ProductCode');
                String productId = (String)selectedProduct.get('Id');
                if (code == null || !PREMIER_ANCILLARY_CODES.contains(code)) continue;

                productCodeToId.put(code, productId);

                List<Object> userInputs = (List<Object>)plan.get('userInputs');
                if (userInputs == null || userInputs.isEmpty()) continue;

                if (!oriProductCodeToMemberIds.containsKey(code)) {
                    oriProductCodeToMemberIds.put(code, new Set<String>());
                }
                for (Object inputObj : userInputs) {
                    Map<String, Object> input = (Map<String, Object>)inputObj;
                    oriProductCodeToMemberIds.get(code).add((String)input.get('Id'));
                }
            }

            // Intersection: members with both Ancillaries
            String smartId = productCodeToId.get('PROG_CriticalCare');
            String aiddId = productCodeToId.get('PROG_AccidentalInjury');
            
            Set<String> oriBundledMembers = oriProductCodeToMemberIds.get('PROG_CriticalCare') ?? new Set<String>();
            oriBundledMembers.retainAll(oriProductCodeToMemberIds.get('PROG_AccidentalInjury') ?? new Set<String>());
            
            if (smartId != null && aiddId != null) {
                for (String memberId : oriBundledMembers) {
                    System.debug('SO Bundle OK → member= ' + memberId + ' SMART productId= ' + smartId + ' AIDD productId='  + aiddId);    
                    manager.memberIdToCriticalCareBundle.put(memberId, new Map<String, String>{
                        'SMART'  => smartId,
                        'AIDD'   => aiddId,
                        'Family' => 'RemoveMember'
                    });
                }
            }

            if (action != 'singleSpinOff') return;

            System.debug('Single Spin Off Ancillary Discounts');

            List<Object> productSelectionOutput = (List<Object>)manager.inputMap.get('LWC_ChooseProductSelectionOutput');
            if (productSelectionOutput == null || productSelectionOutput.isEmpty()) return;

            // Collect: code => productId, code => memberIds
            Map<String, Set<String>> productCodeToMemberIds = new Map<String, Set<String>>();

            for (Object planObj : productSelectionOutput) {
                Map<String, Object> plan = (Map<String, Object>)planObj;
                String productId = (String)((Map<String, Object>)plan.get('selectedProduct')).get('Id');
                String code = getProductCodeFromPriceCalculation(productId);
                if (code == null || !PREMIER_ANCILLARY_CODES.contains(code)) continue;

                productCodeToId.put(code, productId);

                List<Object> userInputs = (List<Object>)plan.get('userInputs');
                if (userInputs == null || userInputs.isEmpty()) continue;

                if (!productCodeToMemberIds.containsKey(code)) {
                    productCodeToMemberIds.put(code, new Set<String>());
                }
                for (Object inputObj : userInputs) {
                    Map<String, Object> input = (Map<String, Object>)inputObj;
                    productCodeToMemberIds.get(code).add((String)input.get('Id'));
                }
            }

            // Intersection: members with both Ancillaries
            smartId = productCodeToId.get('PROG_CriticalCare');
            aiddId = productCodeToId.get('PROG_AccidentalInjury');
            if (smartId == null || aiddId == null) return;

            Set<String> bundledMembers = productCodeToMemberIds.get('PROG_CriticalCare') ?? new Set<String>();
            bundledMembers.retainAll(productCodeToMemberIds.get('PROG_AccidentalInjury') ?? new Set<String>());

            for (String memberId : bundledMembers) {
                System.debug('SO Bundle OK → member= ' + memberId + ' SMART productId= ' + smartId + ' AIDD productId='  + aiddId);

                manager.memberIdToCriticalCareBundle.put(memberId, new Map<String, String>{
                    'SMART'  => smartId,
                    'AIDD'   => aiddId,
                    'Family' => 'SpinOff'
                });
            }
        } catch (Exception e) {
            System.debug('Error in mapCriticalCarePromotionDiscount (SO): '
                + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    /*******************************************************************
    * @MethodName         :   getProductCodeFromPriceCalculation
    * @Description        :   Returns ProductCode for a given productId from price_calculation.plans
    ********************************************************************/
    private String getProductCodeFromPriceCalculation(String productId) {
        if (!manager.inputMap.containsKey('price_calculation')) return null;
        Map<String, Object> priceCalc = (Map<String, Object>)manager.inputMap.get('price_calculation');
        if (!priceCalc.containsKey('plans')) return null;
        List<Object> plans = (List<Object>)priceCalc.get('plans');
        for (Object planObj : plans) {
            Map<String, Object> plan = (Map<String, Object>)planObj;
            Map<String, Object> sp = (Map<String, Object>)plan.get('selectedProduct');
            if ((String)sp.get('Id') == productId) {
                return (String)sp.get('ProductCode');
            }
        }
        return null;
    }

    /*******************************************************************
    * @MethodName         :   mapMemberBeneficiaries  
    * @Description        :   Method to map the beneficiaries for each census member
    ********************************************************************/
    private void mapMemberBeneficiaries() {
        Map<String, Object> memberToBeneficiariesMapSO = new Map<String, Object>(); // SpinOff Contract
        Map<String, Object> memberToBeneficiariesMapRC = new Map<String, Object>(); // Remove Member Contract

        // Family 1
        for (Map<String,Object> cm : manager.censusMembersRemoveContract) {
            if ((Boolean)cm.get('IsRemoveMember') == false) {
                String contactId = cm.containsKey('PersonContactId') 
                    ? (String)cm.get('PersonContactId') 
                    : null;

                if (cm.containsKey('beneficiaries') 
                    && cm.get('beneficiaries') != null 
                    && ((List<Object>)cm.get('beneficiaries')).size() > 0) {

                    List<Object> beneficiaryList = (List<Object>)cm.get('beneficiaries');
                    Map<String,Object> beneficiaryMapPerMember = buildBeneficiaryMap(beneficiaryList);

                    if (contactId != null) {
                        memberToBeneficiariesMapRC.put(contactId, beneficiaryMapPerMember);
                    }
                }
            }
        }

        // Family 2
        for (Map<String,Object> cm : manager.censusMembersInSpinOffContract) {
            if ((Boolean)cm.get('IsRemoveMember') == false) {
                String contactOrFakeId = (cm.containsKey('IsNewMember') && (Boolean)cm.get('IsNewMember') == true 
                                        && ((String)cm.get('Id')).startsWith('MEM-'))
                    ? (String)cm.get('Id')
                    : (String)cm.get('PersonContactId');

                if (cm.containsKey('beneficiaries') 
                    && cm.get('beneficiaries') != null 
                    && ((List<Object>)cm.get('beneficiaries')).size() > 0) {

                    List<Object> beneficiaryList = (List<Object>)cm.get('beneficiaries');
                    Map<String,Object> beneficiaryMapPerMember = buildBeneficiaryMap(beneficiaryList);

                    if (contactOrFakeId != null) {
                        memberToBeneficiariesMapSO.put(contactOrFakeId, beneficiaryMapPerMember);
                    }
                }
            }
        }

        if (!memberToBeneficiariesMapSO.isEmpty()) {
            manager.contactOrFakeIdToBeneficiaries = memberToBeneficiariesMapSO;
        }
        if (!memberToBeneficiariesMapRC.isEmpty()) {
            manager.contactOrFakeIdToBeneficiariesRC = memberToBeneficiariesMapRC;
        }
    }

    /*******************************************************************
    * @MethodName         :   buildBeneficiaryMap  
    * @Description        :   Helper que construye el mapa de beneficiaries 
    *                          a partir de la lista cruda de beneficiaries de un miembro
    ********************************************************************/
    private Map<String,Object> buildBeneficiaryMap(List<Object> beneficiaryList) {
        Map<String,Object> beneficiaryMapPerMember = new Map<String,Object>();
        for (Object beneficiary : beneficiaryList) {
            Map<String,Object> beneficiaryMap = (Map<String,Object>)beneficiary;
            String beneficiaryKey = (String)beneficiaryMap.get('Label') == 'Primary Beneficiary' 
                ? 'primaryBeneficiary' 
                : 'secondaryBeneficiary';
            beneficiaryMapPerMember.put(beneficiaryKey, new Map<String,Object>{
                'fullname'          => (String)beneficiaryMap.get('BeneficiaryName'),
                'birthdate'         => (String)beneficiaryMap.get('BeneficiaryBirthdate'),
                'phone'             => (String)beneficiaryMap.get('BeneficiaryPhone'),
                'relationship'      => (String)beneficiaryMap.get('BeneficiaryRelationship'),
                'otherRelationship' => (String)beneficiaryMap.get('BeneficiaryOtherRelationship')
            });
        }
        return beneficiaryMapPerMember;
    }
   
    /*******************************************************************
    * @MethodName         :   insertCaseForFeeSkipped
    * @Description        :   create and insert a case if the fee was skipped
    ********************************************************************/
    private void insertCaseForFeeSkipped() {
        try {
            if (manager.inputMap.containsKey('STEP_ChargentPayment') && manager.inputMap.get('STEP_ChargentPayment') != null) {
                Map<String, Object> paymentFee = (Map<String, Object>)manager.inputMap.get('STEP_ChargentPayment');
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
                    for (Map<String,Object> member : manager.censusMembersInSpinOffContract) {
                        if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false && member.containsKey('IsRemoveMember') && (Boolean)member.get('IsRemoveMember') == false &&  member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Primary') {
                            
                            newCase.ARC_PersonAccount__c = (Id)member.get('PersonAccountId');
                            newCase.ARC_CensusMember__c = (Id)member.get('Id');
                        }
                        else if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == true && member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Primary') {
                            // Primary member is a New Member then save the Census Member Id and the case to charge in the DML
                            manager.FakeIdToCasePc.put((String)member.get('Id'), newCase);
                        }
                    }

                    Map<String, Object> blockChargeFee = (Map<String, Object>)paymentFee.get('BLK_ChargeFee');
                    Map<String, Object> caseDetails = (Map<String, Object>)blockChargeFee.get('BLK_CaseCreationDetails');
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

    ///////////////////////
    // Helper Methods
    ///////////////////////    

    private void getCensusMembers() {
        Map<Integer, List<Map<String,Object>>> censusMembersMap = new Map<Integer, List<Map<String,Object>>>();
        Map<String, Object> censusComponent = (Map<String, Object>)manager.inputMap.get('census_component');
        List<Object> censusMembersGroups = (List<Object>)censusComponent.get('census_members');
        
        for (Integer i = 0; i < censusMembersGroups.size(); i++) {
            List<Object> censusMembersList = (List<Object>)censusMembersGroups[i];
            List<Map<String,Object>> membersInGroup = new List<Map<String,Object>>();
            Boolean HasSpouse = false;
            
            for (Object censusMember : censusMembersList) {
                Map<String,Object> member = (Map<String,Object>)censusMember;
                if (member.get('vlocity_ins__IsPrimaryMember__c') == true && (Boolean)member.get('IsNewMember') == false && (Boolean)member.get('IsRemoveMember') == false) {
                    vlocity_ins__GroupCensusMember__c primary = new vlocity_ins__GroupCensusMember__c();
                    primary.vlocity_ins__MemberIdentifier__c = member.containsKey('vlocity_ins__MemberIdentifier__c') ? (String)member.get('vlocity_ins__MemberIdentifier__c') : null;
                    primary.vlocity_ins__ContactId__c = member.containsKey('PersonContactId') ? (String)member.get('PersonContactId') : null;
                    primary.Id = member.containsKey('Id') ? (String)member.get('Id') : null;
                    primary.ARC_PhysicalAddressZipCode__c = member.containsKey('ARC_PhysicalAddressZipCode__c') ? (String)member.get('ARC_PhysicalAddressZipCode__c') : null;
                    primary.ARC_PhysicalAddressStreet__c = member.containsKey('ARC_PhysicalAddressStreet__c') ? (String)member.get('ARC_PhysicalAddressStreet__c') : null;
                    primary.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? (String)member.get('ARC_PhysicalAddressState__c') : null;
                    primary.ARC_PhysicalAddressCity__c = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                    primary.vlocity_ins__AccountId__c = member.containsKey('PersonAccountId') ? (Id)member.get('PersonAccountId') : null;
                    manager.primaryCensusMemberWithId = primary;
                    Account primaryAccount = new Account();
                    primaryAccount.Id = member.containsKey('PersonAccountId') ? (String)member.get('PersonAccountId') : null;
                    
                }
                if(member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Spouse'){
                    HasSpouse = true;
                }
                membersInGroup.add(member);
            }
            for(Map<String,Object> member : membersInGroup){
               member.put('vlocity_ins__HasSpouse__c', HasSpouse);
            }
            
            censusMembersMap.put(i, membersInGroup);
        }               
        manager.censusMembersMap = censusMembersMap; 
        if(manager.censusMembersMap.keySet().size() == 2){
            manager.censusMembersInSpinOffContract = manager.censusMembersMap.get(1);
        }
        manager.censusMembersRemoveContract = manager.censusMembersMap.get(0);
        for(Integer family : manager.censusMembersMap.keySet()){
            if(family > 0){
                Map<String,Object> primaryMember = new Map<String,Object>();
                for(Map<String,Object> member : manager.censusMembersMap.get(family)){
                    if(member.containsKey('vlocity_ins__IsPrimaryMember__c') && (Boolean)member.get('vlocity_ins__IsPrimaryMember__c') == true ){
                        primaryMember = member;
                    }
                    
                    if(member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false){
                        Map<String, String> memberIds = new Map<String, String>();
                        String name = member.get('vlocity_ins__FirstName__c') + ' ' +  member.get('vlocity_ins__LastName__c');
                        memberIds.put('name', name);
                        memberIds.put('censusId', member.containsKey('Id') ? (Id)member.get('Id') : null);
                        memberIds.put('accountId', member.containsKey('PersonAccountId') ? (Id)member.get('PersonAccountId') : null);
                        manager.spinOffmembersIds.add(memberIds);
                    }
                } 
                for(Map<String,Object> member : manager.censusMembersMap.get(family)){
                    if(member.containsKey('vlocity_ins__IsPrimaryMember__c') && (Boolean)member.get('vlocity_ins__IsPrimaryMember__c') == true ){
                        manager.spinnedCensusMembersGroupedByPrimary.put(member, manager.censusMembersMap.get(family));
                    }
                    else if(member.containsKey('vlocity_ins__IsPrimaryMember__c') && (Boolean)member.get('vlocity_ins__IsPrimaryMember__c') == false){      
                        manager.spinnedCensusMembersGroupedByPrimary.put(primaryMember, manager.censusMembersMap.get(family));
                    }                  
                }                    
            }                
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
                        if(memberName != null && memberName.length()>60){
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

    /**
    * @Description: Processes the price_calculation.plans from input map and returns a map of products organized by type
    * @return Map<String,Object>: Map containing medical, medical child products, ancillary, and ancillary child products
    */
    private List<Object> getProductsWithMembers(String action) {
        List<Object> productToMembersByFamilyList = new List<Object>();
        productToMembersByFamilyList.add(processPriceCalculation('price_calculation_removemember_spinoff'));
        if (action == 'singleSpinOff') {
            productToMembersByFamilyList.add(processPriceCalculation('price_calculation'));
        }
        return productToMembersByFamilyList;
    }

    /**
    * @Description: Shared logic for processing price calculation maps.
    * @param priceCalculationMap The key used to retrieve the price calculation map.
    * @return Map<String,Object>: Map containing medical, medical child products, ancillary, and ancillary child products
    */
    private Map<String, Object> processPriceCalculation(String priceCalculationMap) {
        Map<String, Object> productToMembersMap = new Map<String, Object>();
        List<Map<String, Object>> ancillaryProducts = new List<Map<String, Object>>();
        List<Map<String, Object>> medicalChildProducts = new List<Map<String, Object>>();
        List<Map<String, Object>> ancillaryChildProducts = new List<Map<String, Object>>();
        if (manager.inputMap.containsKey(priceCalculationMap)) {
            Map<String, Object> priceCalculation = (Map<String, Object>)manager.inputMap.get(priceCalculationMap);
            if (priceCalculation.containsKey('plans')) {
                List<Object> plans = (List<Object>)priceCalculation.get('plans');
                for (Object planObj : plans) {
                    Map<String, Object> plan = (Map<String, Object>)planObj;
                    Map<String, Object> selectedProduct = (Map<String, Object>)plan.get('selectedProduct');
                    String productType = (String)selectedProduct.get('Type__c');
                    
                    // Get the list of members for this product
                    List<Object> userInputs = (List<Object>)plan.get('userInputs');
                    List<Map<String, Object>> members = new List<Map<String, Object>>();
                    
                    for (Object userInputObj : userInputs) {
                        Map<String, Object> userInput = (Map<String, Object>)userInputObj;
                        Map<String, Object> member = new Map<String, Object>{
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
                    if (productType == 'Medical') {
                        // Add the main medical product with price calculation data
                        Map<String, Object> medicalProduct = new Map<String, Object>{
                            'product' => selectedProduct,
                            'members' => members,
                            'priceData' => selectedProduct.get('RawPriceData')
                        };
                        productToMembersMap.put('Medical', medicalProduct);

                        // Process child products if they exist
                        if (selectedProduct.containsKey('childProducts')) {
                            Map<String, Object> childProducts = (Map<String, Object>)selectedProduct.get('childProducts');
                            if (childProducts.containsKey('records')) {
                                List<Object> childRecords = (List<Object>)childProducts.get('records');
                                for (Object childRecord : childRecords) {
                                    Map<String, Object> childProduct = (Map<String, Object>)childRecord;
                                    if ((String)childProduct.get('Type__c') == 'Medical') {
                                        medicalChildProducts.add(new Map<String, Object>{
                                            'product' => childProduct,
                                            'members' => members
                                        });
                                    }
                                }
                            }
                        }
                    }
                    // For ancillary products, add to the ancillary list
                    else if (productType == 'Ancillary') {
                        Map<String, Object> childProducts = (Map<String, Object>)selectedProduct.get('childProducts');
                        List<Map<String, Object>> coverageSpecs = new List<Map<String, Object>>();
                        List<Object> childProductsList;

                        if (childProducts.containsKey('records')) {
                            childProductsList = (List<Object>)childProducts.get('records');
                        }
                        for (Object childProductObj : childProductsList) {
                            Map<String, Object> childProduct = (Map<String, Object>)childProductObj;
                            if (childProduct.containsKey('RecordTypeName__c') && (String)childProduct.get('RecordTypeName__c') == 'CoverageSpec') {
                                coverageSpecs.add(childProduct);
                            }
                        }
        
                   
                        ancillaryProducts.add(new Map<String, Object>{
                            'product' => selectedProduct,
                            'members' => members,
                            'priceData' => selectedProduct.get('RawPriceData'),
                            'childProducts' => coverageSpecs
                        });
                    }
                }
                
                // Add all ancillary products under a single key
                if (!ancillaryProducts.isEmpty()) {
                    productToMembersMap.put('Ancillaries', ancillaryProducts);
                }
                
                // Add medical child products
                if (!medicalChildProducts.isEmpty()) {
                    productToMembersMap.put('MedicalChildProducts', medicalChildProducts);
                }
                
                // Add ancillary child products
                if (!ancillaryChildProducts.isEmpty()) {
                    productToMembersMap.put('AncillaryChildProducts', ancillaryChildProducts);
                }
            }
        }
        return productToMembersMap;
    }
    

    /**
    * @Description: Determines which bank is the issuer of a credit card
    * @param creditCardNumber: The credit card number
    * @return String: The bank issuer name
    */
    private String creditCardType(String creditCardNumber) {
        if (creditCardNumber.startsWith('2') || creditCardNumber.startsWith('5')) {
            return 'Mastercard';
        } else if (creditCardNumber.startsWith('3')) {
            return 'American Express';
        } else if (creditCardNumber.startsWith('4')) {
            return 'Visa';
        } else if (creditCardNumber.startsWith('6')) {
            return 'Discover';
        } else {
            return null;
        }
    }
}