/**
 * @Description: This class serves as the orchestrator for newborn operations.
 * It manages the entire process of inserting and updating records across multiple objects,
 * coordinating between data mapping and DML operations.
 * 
 * @Author: [Developer Name]
 * @Date: [Current Date]
 * @Version: 1.0
 */

public without sharing class ARC_NBMapper {  
    private ARC_NBManager manager; 
    private Set<String> actionsToExecute = new Set<String>();

    /**
     * @Description: Main method to map single newborn data
     * @param manager: The ARC_NBManager instance
     */
    public void mapSingleNewBornData(ARC_NBManager manager) {
        this.manager = manager;
        
        manager.isPermanentNewborn = manager.inputMap.containsKey('STEP_PermanentNewborn') && ((Map<String,Object>)manager.inputMap.get('STEP_PermanentNewborn') != null) && ((Map<String,Object>)manager.inputMap.get('STEP_PermanentNewborn')).containsKey('FRML_PermanentNewborn') && (Boolean)((Map<String,Object>)manager.inputMap.get('STEP_PermanentNewborn')).get('FRML_PermanentNewborn');

        actionsToExecute.add('mapAccounts');
        actionsToExecute.add('mapGCM');
        actionsToExecute.add('mapGCMPlan');
        actionsToExecute.add('mapPolicyParticipant');

        if(manager.isPermanentNewborn){
            actionsToExecute.add('mapContract');
            actionsToExecute.add('mapContractLineItem');
            actionsToExecute.add('mapContractParticipants');
            //actionsToExecute.add('mapGuardian');
            //actionsToExecute.add('mapCensus');
            actionsToExecute.add('mapChargentOrders');
            actionsToExecute.add('insertHipaaAuthorization');
            actionsToExecute.add('mapMedicalQuestions');
            actionsToExecute.add('mapCases');
            actionsToExecute.add('mapCaseMember');
            actionsToExecute.add('insertPromotionDiscount');
            actionsToExecute.add('insertCaseForFeeSkipped');
        }
        
        System.debug('actions to execute: ' + actionsToExecute);
        executeActions(actionsToExecute);
    }    

    /**
     * @Description: Executes the specified actions in sequence
     * @param actionsToExecute: Set of actions to execute
     */
    private void executeActions(Set<String> actionsToExecute){
        getCensusMembers();
        getContractPolAndCLI();
        for(String action : actionsToExecute){
            try {
                switch on action {
                    when 'mapAccounts' {
                        mapAccounts();
                    }
                    when 'mapGCM' {
                        mapGCM();
                    }
                    when 'mapGCMPlan' {
                        mapGCMPlan();
                    }
                    when 'mapPolicyParticipant' {
                        mapPolicyParticipant();
                    }
                    when 'mapContract' {
                        mapContract();
                    }
                    when 'mapContractLineItem' {
                        mapContractLineItem();
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
                    when 'insertCaseForFeeSkipped' {
                        insertCaseForFeeSkipped();
                    }
                }
            } catch (Exception e) {
                System.debug('ERROR: ' + 'Error executing action ' + action + ': ' + e.getLineNumber() + ' ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw new AuraHandledException('Error executing action ' + action + ': ' + e.getLineNumber() + ' ' + e.getMessage() + ' ' + e.getStackTraceString());
            }
        }
    }

    /**
     * @Description: Maps account information for newborns
     */
    private void mapAccounts() {
        try{
            for (Map<String,Object> member : manager.censusMembersMap) {
                Account newAccount = new Account();
                
                newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
                newAccount.PersonBirthdate = member.containsKey('vlocity_ins__Birthdate__c') ? Date.valueOf((String)member.get('vlocity_ins__Birthdate__c')) : null;
                newAccount.IsActive = (manager.allContractsTerminated == false) && (newAccount.PersonBirthdate != null) && newAccount.PersonBirthdate.daysBetween(Date.today()) <= 30 ? true : false;
                newAccount.ARC_DependentRelationship__c = 'Temporary Newborn';
                newAccount.ARC_Census__c = manager.inputMap.containsKey('EligibleCensusId') ? (String)manager.inputMap.get('EligibleCensusId') : null;
                newAccount.FirstName = member.containsKey('vlocity_ins__FirstName__c') ? (String)member.get('vlocity_ins__FirstName__c') : null;
                newAccount.LastName = member.containsKey('vlocity_ins__LastName__c') ? (String)member.get('vlocity_ins__LastName__c') : null;
                newAccount.vlocity_ins__MiddleName__pc = member.containsKey('ARC_MiddleInitial__c') ? (String)member.get('ARC_MiddleInitial__c') : null;
                newAccount.PersonGender = member.containsKey('vlocity_ins__Gender__c') ? (String)member.get('vlocity_ins__Gender__c') : null;
                newAccount.vlocity_ins__SocialSecurityNumber__pc = member.containsKey('vlocity_ins__SocialSecurityNumber__c') ? (String)member.get('vlocity_ins__SocialSecurityNumber__c') : null;
                newAccount.ARC_Height__c = String.valueOf((Integer)member.get('ARC_HeightFeet__c')) + '\'' + String.valueOf((Integer)member.get('ARC_HeightInches__c'));
                newAccount.ARC_Weight__c = member.containsKey('ARC_Weight__c') ? String.valueOf((Integer)member.get('ARC_Weight__c')) : null;
                
                manager.accountFakeIdToInsertNB.put((String)member.get('Id') , newAccount);
            }
        }
        catch(Exception e){
            system.debug('Error mapping person accounts: ' + e.getLineNumber() + ' ' + e.getMessage());
            throw new AuraHandledException('Error mapping person accounts: ' + e.getLineNumber() + ' ' + e.getMessage());
        }
    }    

    /**
     * @Description: Maps Group Census Member information for newborns
     */
    private void mapGCM() { 
        try{
            for (Id censusId : manager.primaryValuesCnt.keySet()) {
                Map<String, Object> primaryValue = manager.primaryValuesCnt.get(censusId);

                Map<String, vlocity_ins__GroupCensusMember__c> fakeIdToGcm = new Map<String, vlocity_ins__GroupCensusMember__c>();

                for (Map<String,Object> member : manager.censusMembersMap) {
                    vlocity_ins__GroupCensusMember__c newGCM = new vlocity_ins__GroupCensusMember__c();

                    newGCM.vlocity_ins__RelatedCensusMemberId__c = (Id)primaryValue.get('Id');
                    newGCM.vlocity_ins__PrimaryMemberIdentifier__c =  (String)primaryValue.get('vlocity_ins__MemberIdentifier__c');
                    newGCM.vlocity_ins__CensusId__c = censusId;
                    newGCM.ARC_DependentRelationship__c = 'Temporary Newborn';
                    newGCM.vlocity_ins__IsPrimaryMember__c = false;
                    newGCM.vlocity_ins__IsSpouse__c = false;
                    newGCM.vlocity_ins__Birthdate__c = member.containsKey('vlocity_ins__Birthdate__c') ? Date.valueOf((String)member.get('vlocity_ins__Birthdate__c')) : null;
                    newGCM.ARC_ActiveMember__c = (censusId == manager.censusIdActiveCnt) && (manager.allContractsTerminated == false) && (newGCM.vlocity_ins__Birthdate__c != null) && (newGCM.vlocity_ins__Birthdate__c.daysBetween(Date.today()) <= 30) ? true : false;

                    newGCM.vlocity_ins__FirstName__c = member.containsKey('vlocity_ins__FirstName__c') ? (String)member.get('vlocity_ins__FirstName__c') : null;
                    newGCM.vlocity_ins__LastName__c = member.containsKey('vlocity_ins__LastName__c') ? (String)member.get('vlocity_ins__LastName__c') : null;
                    if (newGCM.vlocity_ins__FirstName__c != null && newGCM.vlocity_ins__LastName__c != null) {
                        newGCM.Name = newGCM.vlocity_ins__FirstName__c + ' ' + newGCM.vlocity_ins__LastName__c;
                    }
                    
                    newGCM.ARC_MiddleInitial__c = member.containsKey('ARC_MiddleInitial__c') ? (String)member.get('ARC_MiddleInitial__c') : null;
                    newGCM.vlocity_ins__Gender__c = member.containsKey('vlocity_ins__Gender__c') ? (String)member.get('vlocity_ins__Gender__c') : null;
                    newGCM.vlocity_ins__SocialSecurityNumber__c = member.containsKey('vlocity_ins__SocialSecurityNumber__c') ? (String)member.get('vlocity_ins__SocialSecurityNumber__c') : null;
                    newGCM.ARC_HeightFeet__c = member.containsKey('ARC_HeightFeet__c') ? String.valueOf((Integer)member.get('ARC_HeightFeet__c')) : null;
                    newGCM.ARC_HeightInches__c = member.containsKey('ARC_HeightInches__c') ? String.valueOf((Integer)member.get('ARC_HeightInches__c')) : null;
                    newGCM.ARC_Weight__c = member.containsKey('ARC_Weight__c') ? String.valueOf((Integer)member.get('ARC_Weight__c')) : null;

                    newGCM.ARC_PhysicalAddressCity__c = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                    newGCM.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? (String)member.get('ARC_PhysicalAddressState__c') : null;
                    newGCM.ARC_PhysicalAddressStreet__c = member.containsKey('ARC_PhysicalAddressStreet__c') ? (String)member.get('ARC_PhysicalAddressStreet__c') : null;
                    newGCM.ARC_PhysicalAddressZipCode__c = member.containsKey('ARC_PhysicalAddressZipCode__c') ? (String)member.get('ARC_PhysicalAddressZipCode__c') : null;
                    
                    fakeIdToGcm.put((String)member.get('Id'), newGCM);

                    System.debug('gcm' + JSON.serializePretty(newGCM));
                }
                manager.censusGroupToGCM.put(censusId, fakeIdToGcm);
            }    
        }
        catch(Exception e){
            System.debug('Error mapping GCM: ' + e.getLineNumber() + ' ' + e.getMessage());
            throw new AuraHandledException('Error mapping GCM: ' + e.getLineNumber() + ' ' + e.getMessage());
        }
    }

    /**
     * @Description: Maps Group Census Member Plan information for newborns
     */
    private void mapGCMPlan() {
        try {
            if (!manager.listContractsTNB.isEmpty()) {
                Map<String, vlocity_ins__GroupCensusMember__c> censusActiveToGCM = (Map<String, vlocity_ins__GroupCensusMember__c>)manager.censusGroupToGCM.get(manager.censusIdActiveCnt);
                for (Contract cnt : manager.listContractsTNB) {
                    for (String fakeId : censusActiveToGCM.keySet()) {
                        vlocity_ins__GroupCensusMemberPlan__c gcmPlan = new vlocity_ins__GroupCensusMemberPlan__c();

                        gcmPlan.vlocity_ins__ContractLineId__c = cnt.ARC_MedicalPlan__c;
                        gcmPlan.Name = cnt.ARC_MedicalPlan__r.Name;
                        
                        Map<String, vlocity_ins__GroupCensusMemberPlan__c> innerMap = manager.contractIdToGCMP.containsKey(cnt.Id) ? manager.contractIdToGCMP.get(cnt.Id) : new Map<String, vlocity_ins__GroupCensusMemberPlan__c>();

                        innerMap.put(fakeId, gcmPlan);
                        manager.contractIdToGCMP.put(cnt.Id, innerMap);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error mapping Group Census Member Plan: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }    
    }

    /**
     * @Description: Maps Policy Participant information for newborns
     */
    private void mapPolicyParticipant() {
        try {
            if (!manager.listContractsTNB.isEmpty()) {
                Date firstDate = Date.valueOf((String)manager.inputMap.get('OldestNewbornBirthdate'));
                Date lastDate = Date.valueOf((String)manager.inputMap.get('YoungestNewbornBirthdate')) + 30; 

                for (Contract cnt : manager.listContractsTNB) {
                    for (String fakeId : manager.accountFakeIdToInsertNB.keySet()) {
                        // Policy Participant
                        InsurancePolicyParticipant newPolPart = new InsurancePolicyParticipant();

                        newPolPart.InsurancePolicyId = cnt.Insurance_Policies__r[0].Id;
                        newPolPart.Role = 'Dependent';
                        newPolPart.WP_Cancer__c = ((Account)manager.accountFakeIdToInsertNB.get(fakeId)).PersonBirthdate;
                        newPolPart.WP_Colon__c = ((Account)manager.accountFakeIdToInsertNB.get(fakeId)).PersonBirthdate;
                        newPolPart.WP_Glacoma__c = ((Account)manager.accountFakeIdToInsertNB.get(fakeId)).PersonBirthdate;
                        newPolPart.WP_Immunizations__c = ((Account)manager.accountFakeIdToInsertNB.get(fakeId)).PersonBirthdate;
                        newPolPart.WP_Normal__c = ((Account)manager.accountFakeIdToInsertNB.get(fakeId)).PersonBirthdate;
                        newPolPart.WP_Pre_Ex__c = ((Account)manager.accountFakeIdToInsertNB.get(fakeId)).PersonBirthdate;

                        if (cnt.Status == 'Terminated') {
                            if (cnt.ARC_Inactive_Date__c < lastDate) {
                                newPolPart.ARC_EndDate__c = cnt.ARC_Inactive_Date__c;
                            } else {
                                newPolPart.ARC_EndDate__c = lastDate;
                            }
                            if (cnt.ARC_EffectiveDate__c < firstDate) {
                                newPolPart.ARC_StartDate__c = firstDate;
                            } else {
                                newPolPart.ARC_StartDate__c = cnt.ARC_EffectiveDate__c;
                            }
                        } else {
                            if (cnt.ARC_EffectiveDate__c < firstDate) {
                                newPolPart.ARC_StartDate__c = firstDate;
                                newPolPart.ARC_EndDate__c = lastDate;
                            } else {
                                newPolPart.ARC_StartDate__c = cnt.ARC_EffectiveDate__c;
                                newPolPart.ARC_EndDate__c = lastDate;
                            }    
                        }

                        Map<String, InsurancePolicyParticipant> innerMapPolPart = manager.contractIdToPolPart.containsKey(cnt.Id) ? manager.contractIdToPolPart.get(cnt.Id) : new Map<String, InsurancePolicyParticipant>();

                        innerMapPolPart.put(fakeId, newPolPart);
                        manager.contractIdToPolPart.put(cnt.Id, innerMapPolPart);

                        // Coverage Participant
                        ARC_CoverageParticipant__c newCoverPart = new ARC_CoverageParticipant__c();
                        newCoverPart.ARC_Policy__c = cnt.Insurance_Policies__r[0].Id;
                        newCoverPart.ARC_PolicyCoverage__c = cnt.Insurance_Policies__r[0].InsurancePolicyCoverages[0].Id;
                        newCoverPart.ARC_CoverageRole__c = 'Dependent';

                        Map<String, ARC_CoverageParticipant__c> innerMapCovPart = manager.contractIdToCoverPart.containsKey(cnt.Id) ? manager.contractIdToCoverPart.get(cnt.Id) : new Map<String, ARC_CoverageParticipant__c>();

                        innerMapCovPart.put(fakeId, newCoverPart);
                        manager.contractIdToCoverPart.put(cnt.Id, innerMapCovPart);
                    }
                }
                
                // Extend the last policy if it's a permanent newborn and the current date is between the first and last dates
                if (manager.isPermanentNewborn && (firstDate <= Date.today()) && (Date.today() <= lastDate) && manager.isMotherInActualContract) {
                    String IdlastCnt =  (manager.listContractsTNB.get(manager.listContractsTNB.size() -1 )).Id; // get the Id of the last contract
        
                    for (String fakeId : manager.contractIdToPolPart.get(IdlastCnt).keySet()) {
                        if (manager.inputMap.containsKey('EffectiveDate')) {
                            Date newDate = Date.valueOf((String)manager.inputMap.get('EffectiveDate'));
                            (manager.contractIdToPolPart.get(IdlastCnt)).get(fakeId).ARC_EndDate__c = Date.today().addDays(-1);
                        }
                    }
                } 
            }
        } catch (Exception e) {
            System.debug('Error mapping Policy Participant: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
     * @Description: Maps contract information for newborns
     */
    private void mapContract() {
        try {
            Contract newContract = new Contract();
            // Get Reasons and eligible contract info
            Map<String, Object> nbChanges = (Map<String, Object>)manager.inputMap.get('nbChanges');
            Map<String, Object> eligibleContract = (Map<String, Object>)manager.inputMap.get('EligibleContract');     
            Map<String, Object> contractInfo = (Map<String, Object>)eligibleContract.get('ContractInfo');

            if(nbChanges != null) { //nbReasonsString is carry over the reasons if the contract is 'Awaiting', if is not 'Awaiting' only have the reason 'Add Newborn'
                String reasons = (String)nbChanges.get('nbReasonsString');
                if (reasons != null && reasons.contains('Ancillary Change')) {
                    reasons = reasons.replace('Ancillary Change', 'Add Ancillary Product');
                }
                newContract.ARC_ContractReason__c = reasons;
            }
            
            if(contractInfo != null) {
                newContract.vlocity_ins__ExpiredContractId__c = (Id)contractInfo.get('Id');   
                newContract.vlocity_ins__EnrollmentCensusId__c = (Id)contractInfo.get('CensusId');                 
                newContract.AccountId = (String)contractInfo.get('GroupAccountId');
                newContract.Account_Name_Text__c = (String)contractInfo.get('GroupAccountName');
                newContract.ARC_Selling_Agent__c = (String)contractInfo.get('Selling_Agent');

                if (((String)contractInfo.get('Status')).contains('Awaiting')) {
                    if (contractInfo.containsKey('SubReasons') && (String)contractInfo.get('SubReasons') != null) {
                        newContract.ARC_ContractSubReason__c = (String)contractInfo.get('SubReasons');
                    }
                    if (contractInfo.containsKey('OtherSubReasons') && (String)contractInfo.get('OtherSubReasons') != null ) {
                        newContract.ARC_ContractOtherSubReason__c = (String)contractInfo.get('OtherSubReasons');
                    }

                    // Contract to void (Void eligible contract only if the status contain awaiting)
                    Contract lastContract = new Contract();
                    lastContract.Id = (Id)contractInfo.get('Id');
                    lastContract.Status = 'Voided';
                    manager.contractsToUpsert.put('EligibleContract', lastContract);
                }                
            } 

            newContract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_IndividualAndFamily').getRecordTypeId();
            newContract.ARC_EffectiveDate__c = Date.valueOf((String)manager.inputMap.get('EffectiveDate'));
            newContract.StartDate = Date.valueOf((String)manager.inputMap.get('EffectiveDate'));
            newContract.Status = 'Draft';
            newContract.ContractTerm = 12;
            
            newContract.ARC_PrimaryAddress__Street__s = (String)manager.primaryCensusMemberAddress.get('ARC_PhysicalAddressStreet__c');
            newContract.ARC_PrimaryAddress__City__s = (String)manager.primaryCensusMemberAddress.get('ARC_PhysicalAddressCity__c');
            newContract.ARC_PrimaryAddress__StateCode__s = (String)manager.primaryCensusMemberAddress.get('ARC_PhysicalAddressState__c');
            newContract.ARC_PrimaryAddress__PostalCode__s = (String)manager.primaryCensusMemberAddress.get('ARC_PhysicalAddressZipCode__c');
            newContract.ARC_PrimaryAddress__CountryCode__s = 'US';

            manager.contractsToUpsert.put('PermanentNewborn', newContract); 
        } catch(Exception e){
            System.debug('Error mapping Contract: ' + e.getLineNumber() + ' ' + e.getMessage());
            throw new AuraHandledException('Error mapping Contract: ' + e.getLineNumber() + ' ' + e.getMessage());
        }
    }

    /**
     * @Description: Maps contract line item information for newborns
     */
    private void mapContractLineItem() {
        try {
            Map<String, Object> productToMembersMap = getProductsWithMembers();
            if(productToMembersMap != null && !productToMembersMap.isEmpty()) {
                Integer index = 0;
                
                // Get account ID
                Map<String, Object> eligibleContract = (Map<String, Object>)manager.inputMap.get('EligibleContract');     
                Map<String, Object> contractInfo = (Map<String, Object>)eligibleContract.get('ContractInfo');
                String accountId = (String)contractInfo.get('GroupAccountId'); 

                // Get the contract effective date
                Date contractEffectiveDate = Date.valueOf((String)manager.inputMap.get('EffectiveDate'));
                
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
        } catch(Exception e){
            System.debug('Error mapping Contract Line Items: ' + e.getLineNumber() + ' ' + e.getMessage());
            throw new AuraHandledException('Error mapping Contract Line Items: ' + e.getLineNumber() + ' ' + e.getMessage());
        }
    }

    /**
     * @Description: Maps contract participant information for newborns
     */
    private void mapContractParticipants() {
        try {
            for (Map<String,Object> member : manager.allMembersToContPart) {
                ARC_ContractParticipant__c newContractParticipant = new ARC_ContractParticipant__c();

                if (member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == true) {
                    newContractParticipant.ARC_Relationship__c = 'Child';
                    newContractParticipant.ARC_PersonAccount__c = null;
                    newContractParticipant.ARC_Smoker__c = false;
                }
                else if (member.containsKey('IsNewMember')) {
                    newContractParticipant.ARC_Relationship__c = (String)member.get('ARC_Relationship__c');
                    newContractParticipant.ARC_PersonAccount__c = (String)member.get('PersonAccountId');
                    newContractParticipant.ARC_Smoker__c = member.containsKey('ARC_Smoker__c') ? (Boolean)member.get('ARC_Smoker__c') : false;
                }
                newContractParticipant.ARC_Gender__c = member.containsKey('vlocity_ins__Gender__c') ? (String)member.get('vlocity_ins__Gender__c') : null;
                newContractParticipant.ARC_BirthDate__c	 = member.containsKey('vlocity_ins__Birthdate__c') ? Date.valueOf((String)member.get('vlocity_ins__Birthdate__c')) : null;
                newContractParticipant.ARC_Email__c = member.containsKey('vlocity_ins__Email__c') ? (String)member.get('vlocity_ins__Email__c') : null;
                newContractParticipant.ARC_Phone__c =  member.containsKey('ARC_Phone__c') ? (String)member.get('ARC_Phone__c') : null;
                newContractParticipant.ARC_FirstName__c = member.containsKey('vlocity_ins__FirstName__c') ? (String)member.get('vlocity_ins__FirstName__c') : null;
                newContractParticipant.ARC_LastName__c = member.containsKey('vlocity_ins__LastName__c') ? (String)member.get('vlocity_ins__LastName__c') : null;
                if (newContractParticipant.ARC_FirstName__c != null && newContractParticipant.ARC_LastName__c != null) {
                    newContractParticipant.Name = newContractParticipant.ARC_FirstName__c + ' ' + newContractParticipant.ARC_LastName__c;
                }

                newContractParticipant.ARC_Address__CountryCode__s = 'US';
                newContractParticipant.ARC_Address__City__s = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                newContractParticipant.ARC_Address__StateCode__s = member.containsKey('ARC_PhysicalAddressState__c') ? (String)member.get('ARC_PhysicalAddressState__c') : null;
                newContractParticipant.ARC_Address__Street__s = member.containsKey('ARC_PhysicalAddressStreet__c') ? (String)member.get('ARC_PhysicalAddressStreet__c') : null;
                newContractParticipant.ARC_Address__PostalCode__s = member.containsKey('ARC_PhysicalAddressZipCode__c') ? (String)member.get('ARC_PhysicalAddressZipCode__c') : null;
                
                newContractParticipant.ARC_Weight__c =  member.containsKey('ARC_Weight__c') != null ? String.valueOf(member.get('ARC_Weight__c')) : null;
                if(String.valueOf(member.get('ARC_HeightFeet__c')) != null && String.valueOf(member.get('ARC_HeightInches__c')) != null) {
                    newContractParticipant.ARC_Height__c = String.valueOf(member.get('ARC_HeightFeet__c')) + '\'' + String.valueOf(member.get('ARC_HeightInches__c'));
                }
                
                manager.fakeIdToContractPart.put((String)member.get('Id'), newContractParticipant);
            }
        } catch (Exception e) {
            System.debug('Error mapping Contract Participant: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        } 
    }

    /**
     * @Description: Maps case information for newborns
     */
    private void mapCases() {
        try {
            Map<String, Object> eligibleContract = (Map<String, Object>)manager.inputMap.get('EligibleContract');     
            Map<String, Object> contractInfo = (Map<String, Object>)eligibleContract.get('ContractInfo');

            Case newCase = new Case();                
            
            newCase.ARC_Reason__c = 'Underwriting';
            newCase.Case_Type__c = 'Underwriting';
            newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admission').getRecordTypeId();
            newCase.Description = 'Underwriting';
            newCase.Origin = 'Internal Enrollment';
            newCase.Subject = 'Underwriting';
            newCase.Type = 'Program Change';
          //  newCase.Status =  'Draft';
            newCase.OwnerId = (Id)manager.inputMap.get('userId');
            
            if (contractInfo != null) newCase.AccountId = (String)contractInfo.get('GroupAccountId');

            if (contractInfo != null && ((String)contractInfo.get('Status') == 'Awaiting Signature' || (String)contractInfo.get('Status') == 'Awaiting Approval')) {
                newCase.Status =  'Draft';
            } else if ((String)contractInfo.get('Status') == 'Awaiting First Payment' || (String)contractInfo.get('Status') == 'Awaiting Activation' || (String)contractInfo.get('Status') == 'Activated') {
                newCase.Status = 'Closed Approved';
            }

            manager.casesUWToInsert.add(newCase);    
        } catch (Exception e) {
            System.debug('Error Mapping UW Case: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }
    }


    /**
     * @Description: Maps case member information for newborns
     */
    private void mapCaseMember() {
        try {
            Map<String, Object> eligibleContract = (Map<String, Object>)manager.inputMap.get('EligibleContract');     
            Map<String, Object> contractInfo = (Map<String, Object>)eligibleContract.get('ContractInfo');
            Id contractId = contractInfo != null ? (String)contractInfo.get('Id') : null;
            String contractStatus = (String)contractInfo.get('TXT_ContractStatus');

            // Copy existing UW case members if applicable
            if ( contractInfo != null && ((String)contractInfo.get('Status')).contains('Awaiting')) {
                List<ARC_UnderwritingCaseMember__c> listUWCMToCopy = [SELECT ARC_ApprovalResolution__c, ARC_Member__c, ARC_PersonAccount__c, ARC_Reason__c, ARC_Score__c, Name, ARC_ReviewedBy__c,  ARC_LastStatusUpdate__c, LastModifiedById, ARC_Description__c FROM ARC_UnderwritingCaseMember__c WHERE ARC_Contract__c =: contractId ];

                List<Object> censusMembers = (List<Object>)manager.inputMap.get('census_members');
                for (ARC_UnderwritingCaseMember__c UWCM : listUWCMToCopy) {
                    for (Object censusMember : censusMembers) {
                        Map<String,Object> member = (Map<String,Object>)censusMember;
                        if (member != null && member.containsKey('IsNewMember') && (Boolean)member.get('IsNewMember') == false 
                            && member.containsKey('PersonAccountId') && (Id)member.get('PersonAccountId') == UWCM.ARC_PersonAccount__c && member.containsKey('IsRemoveMember') && (Boolean)member.get('IsRemoveMember') == false) { 
                           
                            try {
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

                                manager.censusMemberIdOrFakeIdToUWCM.put(newCaseMember.ARC_Member__c, newCaseMember);      
                            } catch (Exception e) {
                                System.debug('Exception when trying to clone previous UWM Cases ' + e.getMessage() + ' ' + e.getStackTraceString());
                                throw e;
                            }
                        }
                    }
                }
            }
            
            // UWCM to Newborns
            for (Map<String,Object> member : manager.censusMembersMap) { // manager.censusMembersMap only have the newborns
                ARC_UnderwritingCaseMember__c newCaseMember;

                newCaseMember = new ARC_UnderwritingCaseMember__c();
                newCaseMember.ARC_ApprovalResolution__c = 'Approved';
                newCasemember.Name = (String)member.get('vlocity_ins__FirstName__c') + ' ' + (String)member.get('vlocity_ins__LastName__c');                
                newCaseMember.ARC_Reason__c = 'Add Member';
                manager.censusMemberIdOrFakeIdToUWCM.put((String)member.get('Id'), newCaseMember);
            }
        } catch (Exception e) {
            System.debug('Error mapping UW Case Member: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }	
    }

    /**
     * @Description: Maps Chargent order information for newborns
     */
    private void mapChargentOrders() {
        try {
            Map<String, Object> plansSummary = (Map<String, Object>)manager.inputMap.get('PlansSummary');
            Map<String, Object> blkProductSummary = (Map<String, Object>)plansSummary.get('BLK_ProductSummary');

            Map<String, Object> nbChanges = manager.inputMap.containsKey('nbChanges') ? (Map<String, Object>)manager.inputMap.get('nbChanges') : null;
            Decimal feeAmount = (nbChanges != null) && nbChanges.containsKey('feeAmount') ? (Decimal)nbChanges.get('feeAmount') : null;

            Map<String, Object> eligibleContract = (Map<String, Object>)manager.inputMap.get('EligibleContract');     
            Map<String, Object> contractInfo = (Map<String, Object>)eligibleContract.get('ContractInfo');
            String groupAccountId = (String)contractInfo.get('GroupAccountId');
            Map<String, Object> appFeeOrder = contractInfo.containsKey('AppFeeOrder') ? (Map<String, Object>)contractInfo.get('AppFeeOrder') : null;
            Boolean carryOverAppFee = (appFeeOrder != null) && appFeeOrder.containsKey('CarryOverAppFee') ? (Boolean)appFeeOrder.get('CarryOverAppFee') : false;

            Map<String, Map<String, Object>> chargentOrders = new Map<String, Map<String, Object>>();
            if (manager.inputMap.containsKey('mapChargentOrders')) {
                Map<String, Object> rawChargentOrders = (Map<String, Object>)manager.inputMap.get('mapChargentOrders');
                for (String key : rawChargentOrders.keySet()) {
                    chargentOrders.put(key, (Map<String, Object>)rawChargentOrders.get(key));
                }
            }

            // Carry Over App Fee Order
            if (carryOverAppFee) { 
                Id appFeeOrderId = (Id)appFeeOrder.get('Id');
                Map<String, Object> coAppFee = chargentOrders.get(appFeeOrderId);

                ChargentOrders__ChargentOrder__c newCOAppFee = new ChargentOrders__ChargentOrder__c();
    
                newCOAppFee.ChargentOrders__Account__c = groupAccountId;
                newCOAppFee.ARC_FirstMonthPayed__c = false;
                newCOAppFee.ChargentOrders__Billing_First_Name__c = (String)coAppFee.get('ChargentOrders__Billing_First_Name__c');
                newCOAppFee.ChargentOrders__Billing_Last_Name__c = (String)coAppFee.get('ChargentOrders__Billing_Last_Name__c');
                newCOAppFee.ChargentOrders__Billing_Address__c = (String)coAppFee.get('ChargentOrders__Billing_Address__c');
                newCOAppFee.ChargentOrders__Billing_City__c = (String)coAppFee.get('ChargentOrders__Billing_City__c');
                newCOAppFee.ChargentOrders__Billing_State__c = (String)coAppFee.get('ChargentOrders__Billing_State__c');
                newCOAppFee.ChargentOrders__Billing_Zip_Postal__c = (String)coAppFee.get('ChargentOrders__Billing_Zip_Postal__c');
                newCOAppFee.ChargentOrders__Tokenization__c = (String)coAppFee.get('ChargentOrders__Tokenization__c');

                if((String)coAppFee.get('ChargentOrders__Payment_Method__c') == 'Credit Card'){
                    newCOAppFee.ChargentOrders__Card_Number__c = (String)coAppFee.get('ChargentOrders__Card_Number__c');
                    newCOAppFee.ChargentOrders__Card_Expiration_Month__c = (String)coAppFee.get('ChargentOrders__Card_Expiration_Month__c');
                    newCOAppFee.ChargentOrders__Card_Expiration_Year__c = (String)coAppFee.get('ChargentOrders__Card_Expiration_Year__c');
                    newCOAppFee.ChargentOrders__Card_Last_4__c = (String)coAppFee.get('ChargentOrders__Card_Last_4__c');
                }
                else if((String)coAppFee.get('ChargentOrders__Payment_Method__c') == 'Bank Account'){
                    newCOAppFee.ChargentOrders__Bank_Routing_Number__c = (String)coAppFee.get('ChargentOrders__Bank_Routing_Number__c');
                    newCOAppFee.ChargentOrders__Bank_Account_Number__c = (String)coAppFee.get('ChargentOrders__Bank_Account_Number__c');
                    newCOAppFee.ChargentOrders__Bank_Name__c = (String)coAppFee.get('ChargentOrders__Bank_Name__c');
                    newCOAppFee.ChargentOrders__Bank_Account_Type__c = (String)coAppFee.get('ChargentOrders__Bank_Account_Type__c');                   
                }

                newCOAppFee.ChargentOrders__Card_Month_Indicator__c = (String)coAppFee.get('ChargentOrders__Card_Month_Indicator__c');
                newCOAppFee.ChargentOrders__Card_Type__c = (String)coAppFee.get('ChargentOrders__Card_Type__c');     
                newCOAppFee.ChargentOrders__Card_Year_Indicator__c = (String)coAppFee.get('ChargentOrders__Card_Year_Indicator__c');
                newCOAppFee.ChargentOrders__Charge_Amount__c = feeAmount;
                newCOAppFee.ChargentOrders__Description__c = 'Change Fee';
                newCOAppFee.ChargentOrders__Gateway__c = (String)coAppFee.get('ChargentOrders__Gateway__c');
                newCOAppFee.ChargentOrders__Payment_Frequency__c = 'Once';
                newCOAppFee.ChargentOrders__Payment_Method__c = (String)coAppFee.get('ChargentOrders__Payment_Method__c');
                newCOAppFee.ChargentOrders__Payment_Status__c = null;
                newCOAppFee.ChargentOrders__Subtotal__c = feeAmount;
                newCOAppFee.ChargentOrders__Manual_Charge__c = (Boolean)coAppFee.get('ChargentOrders__Manual_Charge__c');  
                
                manager.chargentOrdersToInsert.put('coAppFee', newCOAppFee);
            }
            
            // Recurring
            Id recurringMonthlyOrderId = contractInfo.containsKey('RecurringMonthlyOrderId') ? (Id)contractInfo.get('RecurringMonthlyOrderId') : null;
            Map<String, Object> coRecurring = chargentOrders.get(recurringMonthlyOrderId);

            ChargentOrders__ChargentOrder__c newCORecurring = new ChargentOrders__ChargentOrder__c();

            newCORecurring.ChargentOrders__Account__c = groupAccountId;
            newCORecurring.ARC_FirstMonthPayed__c = (Boolean)coRecurring.get('ARC_FirstMonthPayed__c');
            newCORecurring.ChargentOrders__Billing_Address__c = (String)coRecurring.get('ChargentOrders__Billing_Address__c');
            newCORecurring.ChargentOrders__Billing_City__c = (String)coRecurring.get('ChargentOrders__Billing_City__c');
            newCORecurring.ChargentOrders__Billing_First_Name__c = (String)coRecurring.get('ChargentOrders__Billing_First_Name__c');
            newCORecurring.ChargentOrders__Billing_Last_Name__c = (String)coRecurring.get('ChargentOrders__Billing_Last_Name__c');
            newCORecurring.ChargentOrders__Billing_State__c = (String)coRecurring.get('ChargentOrders__Billing_State__c');
            newCORecurring.ChargentOrders__Billing_Zip_Postal__c = (String)coRecurring.get('ChargentOrders__Billing_Zip_Postal__c');
            newCORecurring.ChargentOrders__Card_Expiration_Month__c = (String)coRecurring.get('ChargentOrders__Card_Expiration_Month__c');
            newCORecurring.ChargentOrders__Card_Expiration_Year__c = (String)coRecurring.get('ChargentOrders__Card_Expiration_Year__c');
            newCORecurring.ChargentOrders__Card_Last_4__c = (String)coRecurring.get('ChargentOrders__Card_Last_4__c');
            newCORecurring.ChargentOrders__Card_Month_Indicator__c = (String)coRecurring.get('ChargentOrders__Card_Month_Indicator__c'); 
            newCORecurring.ChargentOrders__Card_Number__c = (String)coRecurring.get('ChargentOrders__Card_Number__c');
            newCORecurring.ChargentOrders__Card_Type__c = (String)coRecurring.get('ChargentOrders__Card_Type__c');
            newCORecurring.ChargentOrders__Card_Year_Indicator__c = (String)coRecurring.get('ChargentOrders__Card_Year_Indicator__c');
            newCORecurring.ChargentOrders__Charge_Amount__c = Decimal.valueOf(((String)blkProductSummary.get('TXT_MonthlyPrice')).remove('$').trim());
            newCORecurring.ChargentOrders__Charge_Date__c = (String)coRecurring.get('ChargentOrders__Charge_Date__c');
            newCORecurring.ChargentOrders__Description__c = 'Recurring Monthly Order';
            newCORecurring.ChargentOrders__Tokenization__c = (String)coRecurring.get('ChargentOrders__Tokenization__c');
            newCORecurring.ChargentOrders__Gateway__c = (String)coRecurring.get('ChargentOrders__Gateway__c');
            newCORecurring.ChargentOrders__Payment_Frequency__c = 'Monthly';
            newCORecurring.ChargentOrders__Payment_Method__c = (String)coRecurring.get('ChargentOrders__Payment_Method__c');
            newCORecurring.ChargentOrders__Payment_Start_Date__c = Date.today();
            newCORecurring.ChargentOrders__Payment_Status__c = 'Stopped';
            newCORecurring.ChargentOrders__Subtotal__c = Decimal.valueOf(((String)blkProductSummary.get('TXT_MonthlyPrice')).remove('$').trim());
            newCORecurring.ChargentOrders__Manual_Charge__c  = true;

            manager.chargentOrdersToInsert.put('coRecurring', newCORecurring);
        } catch (Exception e) {
            System.debug('Error mapping Chargent Order: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        } 
    }    

    /**
     * @Description: Maps HIPAA authorization information for newborns
     */
    private void mapHipaaAuthorization() { 
        // TODO: Implement HIPAA authorization mapping logic for newborns
        // This method should create HIPAA authorization records for newborns
    }

    /**
     * @Description: Maps medical questions for newborns
     */
    private void mapMedicalQuestions() {
        try {
            if((Map<String, Object>)manager.inputMap.get('STEP_MedicalQuestions') != null){

                Map<String, Object> stepMedicalQuestions = (Map<String, Object>)manager.inputMap.get('STEP_MedicalQuestions');

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
                        mc.ARC_CensusMember__c = null;
                        mc.ARC_PersonAccount__c = null;
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

                            mc.ARC_CensusMember__c = null;
                            mc.ARC_PersonAccount__c = null;
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
                            
                            mc.ARC_CensusMember__c = null;
                            mc.ARC_PersonAccount__c = null;
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
                            String accountId = null;

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
     * @Description: Inserts promotion discount information for newborns
     */
    private void insertPromotionDiscount(){
        // TODO: Implement promotion discount logic for newborns
        // This method should create promotion discount records for newborns
    }
   
    /**
     * @Description: Creates and inserts a case if the fee was skipped for newborns
     */
    private void insertCaseForFeeSkipped() {
        // TODO: Implement case creation logic for fee skipping in newborns
        // This method should create cases when fees are waived for newborns
    }

    ///////////////////////
    // Helper Methods
    ///////////////////////    

    /**
     * @Description: Retrieves and processes census member information for newborns
     */
    private void getCensusMembers() {
        List<Object> censusMembers = (List<Object>)manager.inputMap.get('census_members');
    
        for (Object censusMember : censusMembers) {
            Map<String,Object> member = (Map<String,Object>)censusMember;

            // Primary Census Member Address
            if ((String)member.get('ARC_Relationship__c') == 'Primary' && (Boolean)member.get('IsNewMember') == false && (Boolean)member.get('IsRemoveMember') == false) {

                manager.primaryCensusMember.Id = member.containsKey('Id') ? (String)member.get('Id') : null;
                manager.primaryCensusMember.vlocity_ins__ContactId__c = member.containsKey('PersonContactId') ? (String)member.get('PersonContactId') : null;
                manager.primaryAccountId = member.containsKey('PersonAccountId') ? (String)member.get('PersonAccountId') : null;

                manager.primaryCensusMemberAddress.ARC_PhysicalAddressCity__c = member.containsKey('ARC_PhysicalAddressCity__c') ? (String)member.get('ARC_PhysicalAddressCity__c') : null;
                manager.primaryCensusMemberAddress.ARC_PhysicalAddressState__c = member.containsKey('ARC_PhysicalAddressState__c') ? (String)member.get('ARC_PhysicalAddressState__c') : null;
                manager.primaryCensusMemberAddress.ARC_PhysicalAddressStreet__c = member.containsKey('ARC_PhysicalAddressStreet__c') ? (String)member.get('ARC_PhysicalAddressStreet__c') : null;
                manager.primaryCensusMemberAddress.ARC_PhysicalAddressZipCode__c = member.containsKey('ARC_PhysicalAddressZipCode__c') ? (String)member.get('ARC_PhysicalAddressZipCode__c') : null;
            }

            // Check if mother is in the actual contract
            if (((String)member.get('ARC_Relationship__c') == 'Primary' || (String)member.get('ARC_Relationship__c') == 'Spouse') && ((String)member.get('vlocity_ins__Gender__c') == 'Female')) {
                manager.isMotherInActualContract = true;
            }

            // Add to Map only the newborns
            if ((Boolean)member.get('IsNewMember') == true && (Boolean)member.get('IsRemoveMember') == false) {
                manager.censusMembersMap.add(member);
                manager.newbornsDOB.add(Date.valueOf((String)member.get('vlocity_ins__Birthdate__c')));
                System.debug('manager.newbornsDOB Mapper: ' + manager.newbornsDOB);
            }
            
            if ((Boolean)member.get('IsRemoveMember') == false) {
                manager.allMembersToContPart.add(member);
            }
        }
    }
    
    /**
     * @Description: Retrieves and processes contracts, policy and contract line items information for newborns
     */
    private void getContractPolAndCLI() {
        Date firstDate = Date.valueOf((String)manager.inputMap.get('OldestNewbornBirthdate'));
        Date lastDate = Date.valueOf((String)manager.inputMap.get('YoungestNewbornBirthdate')) + 30; 
        
        List<String> listIdCnt = new List<String>();
        Object contracts = manager.inputMap.get('ContractsIdforMothers');

        if (contracts instanceof String) {
            listIdCnt.add((String)contracts);
        } else {
            for (Object o : (List<Object>)contracts) {
                listIdCnt.add((String)o);
            }
        }

        List<vlocity_ins__ContractLineItem__c> listCLIMedProd = [SELECT vlocity_ins__Product2Id__c FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__ContractId__c IN :listIdCnt AND vlocity_ins__ProductType__c = 'Medical' AND vlocity_ins__ParentItemId__c = null];

        List<String> medProdId = new List<String>();

        for (vlocity_ins__ContractLineItem__c cliMedProd: listCLIMedProd) medProdId.add(cliMedProd.vlocity_ins__Product2Id__c);

        manager.listContractsTNB = [
            SELECT Id, ARC_MedicalPlan__c, ARC_MedicalPlan__r.Name, Status, ARC_EffectiveDate__c, ARC_Inactive_Date__c, vlocity_ins__EnrollmentCensusId__c, vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.Census_Member__c, vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.Census_Member__r.ARC_NewCensusMember__c, vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.Census_Member__r.vlocity_ins__MemberIdentifier__c, vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.Census_Member__r.ARC_NewCensusMember__r.vlocity_ins__MemberIdentifier__c, ARC_ContractReason__c,
                (SELECT Id, 
                    (SELECT Id 
                    FROM InsurancePolicyCoverages 
                    WHERE vlocity_ins_fsc__Product2Id__c IN :medProdId
                    LIMIT 1) 
                FROM Insurance_Policies__r
                LIMIT 1)
            FROM Contract 
            WHERE Id IN :listIdCnt 
                AND Status NOT IN ('Draft','Voided')
                AND ((Status = 'Terminated' AND ARC_EffectiveDate__c <= :lastDate AND ARC_Inactive_Date__c >= :firstDate)
                    OR 
                    (Status != 'Terminated' AND ARC_EffectiveDate__c <= :lastDate))
                ORDER BY CreatedDate ASC
        ];

        Integer aux = 0;
       // Boolean isSpinOffActive = false;
       // String censusIdSpinOffInactive = null;
        for (Contract cnt : manager.listContractsTNB) {
            if (cnt.Status == 'Terminated') aux++;
           
            if (cnt.Status == 'Activated') {
                manager.censusIdActiveCnt = cnt.vlocity_ins__EnrollmentCensusId__c;
            }

            Id censusId;
            Id relatedCensusMemberId;
            String primaryMemberIdentifier;

            if (cnt.vlocity_ins__EnrollmentCensusId__c != null) {
                manager.cntIdtoCensusId.put(cnt.Id, cnt.vlocity_ins__EnrollmentCensusId__c);
                censusId = cnt.vlocity_ins__EnrollmentCensusId__c;

                if (cnt.ARC_ContractReason__c.contains('Spin Off')) {
                    relatedCensusMemberId = cnt.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.Census_Member__r.ARC_NewCensusMember__c;
                    primaryMemberIdentifier = cnt.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.Census_Member__r.ARC_NewCensusMember__r.vlocity_ins__MemberIdentifier__c;
                }
                else {
                    relatedCensusMemberId = cnt.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.Census_Member__c;
                    primaryMemberIdentifier = cnt.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.Census_Member__r.vlocity_ins__MemberIdentifier__c;
                }
            }

            manager.primaryValuesCnt.put(
                censusId,
                new Map<String, Object>{
                    'Id' => relatedCensusMemberId,
                    'vlocity_ins__MemberIdentifier__c' => primaryMemberIdentifier
                }
            );
        }
        manager.allContractsTerminated = aux == manager.listContractsTNB.size();
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