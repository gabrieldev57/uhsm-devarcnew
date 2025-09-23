global without sharing class ARC_PCAncillaryUserInputs implements vlocity_ins.VlocityOpenInterface {
    private static integer daysToAdd = 60;
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'updateAndRepriceContracts') {
            updateAndRepriceContracts(inputMap, outputMap,options);
        } 
        if (methodName == 'updateAndRepriceMultiContracts') {
            updateAndRepriceMultiContracts(inputMap, outputMap,options);
        } 
        if (methodName == 'getInputForChooseProducts') {
            getInputForChooseProducts(inputMap, outputMap,options);
        }           
        if (methodName == 'updateAndRepriceMultiContractsCase') {
            updateAndRepriceMultiContractsCase(inputMap, outputMap,options);
        }  
        return true;
    }
    public static void updateAndRepriceContracts(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
        // "CensusId": "%CensusId%",
        // "selectedProducts": "%IP_ContractCreation:changesForContracts:selectedProducts%",
        // "listProdIds": "%SV_ProductsIds:listProdIds%",
        // "RemovedMembers": "%IP_ContractCreation:changesForContracts:RemovedMembers%",
        // "Reason": "%IP_ContractCreation:changesForContracts:Reason%",
        // "auxSavedMembers": "%IP_ContractCreation:changesForContracts:auxSavedMembers%",
        // "oldProducts": "%oldProducts%"
        String CensusId = (String)inputMap.get('CensusId');
        String effDate = (String)inputMap.get('EffectiveDate');
        String contractId = (String)inputMap.get('contractId');
        String oldPrimaryId;
        String newPrimaryOldRelationship;

        Set<String> membersToActivateIds = new Set<String>();
        Set<String> membersToDeactivateIds = new Set<String>();
        List<Object> objList_RemovedMembers = new List<Object>();
        List<Object> objList_auxSavedMembers = new List<Object>();
        List<Map<String,Object>> auxSavedMembers = new List<Map<String,Object>>();
        List<Map<String,Object>> RemovedMembers = new List<Map<String,Object>>();
        String primaryId = (String)inputMap.get('primaryId');
        String primaryEmail = (String)inputMap.get('primaryEmail');

        if(inputMap.get('auxSavedMembers') != ''){
            objList_auxSavedMembers = (List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('auxSavedMembers')));
            for (Object itemObj : objList_auxSavedMembers) {
                Map<String, Object> item = (Map<String, Object>) itemObj;
                auxSavedMembers.add(item);
            }
        }
        if(inputMap.get('RemovedMembers') != ''){
            objList_RemovedMembers = (List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('RemovedMembers')));
            for (Object itemObj : objList_RemovedMembers) {
                Map<String, Object> item = (Map<String, Object>) itemObj;
                RemovedMembers.add(item);
            }
        }


        
        
        for (Map<String, Object> member : auxSavedMembers) {
            if((Boolean)member.get('isNew')==true){
                membersToActivateIds.add((String)member.get('vlocity_ins__MemberIdentifier__c'));
            }
        }
        for (Map<String, Object> member : RemovedMembers) {
            if ((Boolean)member.get('CHK_Delete')==true) {
                membersToDeactivateIds.add((String)member.get('TXT_CensusMemberId'));
            }
        }
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id, Name,vlocity_ins__RelatedCensusMemberId__c, vlocity_ins__Email__c, ARC_Smoker__c, ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c ,vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__MemberIdentifier__c IN :membersToActivateIds OR Id IN :membersToDeactivateIds OR Id = :primaryId];

        for (vlocity_ins__GroupCensusMember__c member : members) {
            if (member.ARC_DependentRelationship__c == 'Future Primary') {
                primaryId = member.Id;
                primaryEmail = member.vlocity_ins__Email__c;
            }
        }

        for (vlocity_ins__GroupCensusMember__c member : members) {
            if(membersToActivateIds.contains(member.vlocity_ins__MemberIdentifier__c)){
                member.ARC_ActiveMember__c = true;
            }
            if(membersToDeactivateIds.contains(member.Id) ){
                member.ARC_ActiveMember__c = false;
                if(member.vlocity_ins__IsPrimaryMember__c){
                    oldPrimaryId = member.Id;
                    member.vlocity_ins__IsPrimaryMember__c = false;
                }
            }
            if(primaryId!=''){
                if(member.Id == primaryId){
                    member.vlocity_ins__IsPrimaryMember__c = true;
                    member.vlocity_ins__Email__c = primaryEmail;
                    member.vlocity_ins__RelatedCensusMemberId__c = null;
                }else{
                    member.vlocity_ins__RelatedCensusMemberId__c = primaryId;
                }
            }
            
        }
        // for (vlocity_ins__GroupCensusMember__c member : members) {
        // }
        // List<vlocity_ins__GroupCensusMember__c> members = new List<vlocity_ins__GroupCensusMember__c>();
        // members.addAll(membersToActivate);
        // members.addAll(membersToDeactivate);

        update members; 
        List<Map<String, Object>> userInputs2 = getUserInput(CensusId, effDate, contractId, members, membersToActivateIds, membersToDeactivateIds);
        outputMap.put('userInputs2',userInputs2);

        for (vlocity_ins__GroupCensusMember__c member : members) {
            if(membersToActivateIds.contains(member.vlocity_ins__MemberIdentifier__c)){
                member.ARC_ActiveMember__c = false;
            }
            if(membersToDeactivateIds.contains(member.Id)){
                member.ARC_ActiveMember__c = true;
                if(member.Id == oldPrimaryId){
                    member.vlocity_ins__IsPrimaryMember__c = true;
                }
            }
            if(primaryId!=''){
                if(member.Id == primaryId){
                    member.vlocity_ins__IsPrimaryMember__c = false;
                }
                if (member.Id == oldPrimaryId) {
                    member.vlocity_ins__RelatedCensusMemberId__c = null;
                }else{
                    member.vlocity_ins__RelatedCensusMemberId__c = oldPrimaryId;
                }
            }
            
        }
        update members; 

    }
    public static void updateAndRepriceMultiContracts(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){

        String CensusId = (String)inputMap.get('CensusId');
        String primaryId = (String)inputMap.get('primaryId');
        String primaryEmail = (String)inputMap.get('primaryEmail');
        String contractId = (String)inputMap.get('contractId');
        String oldRelatedPrimary = '';
        String futurePrimaryIdientifier;

        List<Object> objList_changesForContracts = (List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('changesForContracts')));
        List<Object> listUserInputLists = new List<Object>();
        List<Map<String,Object>> changesForContracts = new List<Map<String,Object>>();
        List<Object> chooseProductsOutput = new List<Object>();
        // List<Object> dependants = (List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('dependants')));
        List<Object> obj_formatedDependants = (List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('productList')));
        List<Map<String,Object>> formatedDependants = new List<Map<String,Object>>();
    
        Set<String> membersToActivateDeactivateIds = new Set<String>();
        Set<String> memberIdentifOfActive = new Set<String>();
        Set<String> contractsUseNewPrimarId = new Set<String>();
        Set<String> oldActiveMembers = new Set<String>();
        Set<String> depProds = new Set<String>();
        Set<String> addAncillaryProds = new Set<String>();
        Set<String> addMemberProds = new Set<String>();
    
        Map<String,Set<String>> contract_membersToDeactivate = new Map<String,Set<String>>();
        Map<String,Set<String>> contract_membersToActivate = new Map<String,Set<String>>();
        Map<String, Integer> contract_PrimaryMemberAge = new Map<String, Integer>();
        Map<String, Integer> contract_ExtraDeps = new Map<String, Integer>();
        Map<String,Object> chooseProductJson = new Map<String,Object> ();

        Boolean futurePrimaryExist = false;
    
    
        if (inputMap.get('chooseProductsAncillaryOutput')!='' && inputMap.get('chooseProductsAncillaryOutput')!=null) {
            chooseProductsOutput.addAll((List<Object>)inputMap.get('chooseProductsAncillaryOutput'));
            for (Object item : (List<Object>)inputMap.get('chooseProductsAncillaryOutput')) {
                addAncillaryProds.add((String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Id'));
            }
        }
        if (inputMap.get('chooseProductsAddMemberOutput')!='' && inputMap.get('chooseProductsAddMemberOutput')!=null) {
            chooseProductsOutput.addAll((List<Object>)inputMap.get('chooseProductsAddMemberOutput'));
            for (Object item : (List<Object>)inputMap.get('chooseProductsAddMemberOutput')) {
                addMemberProds.add((String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Id'));
            }
        }
        
        for (Object item : obj_formatedDependants) {
            formatedDependants.add((Map<String,Object>)item);
        }
    
        chooseProductsOutput.addAll(formatedDependants);
    
        for (Object itemObj : objList_changesForContracts) {
            Map<String, Object> item = (Map<String, Object>) itemObj;
            changesForContracts.add(item);
        }
    
    
    
        for(Map<String, Object> change : changesForContracts){
    
            if ((((String)change.get('SingleReason')).contains('Program Upgrade') || ((String)change.get('SingleReason')).contains('Program Downgrade') || ((String)change.get('SingleReason')).contains('Remove Ancillary')) && !((String)change.get('SingleReason')).contains('Add Newborn')  && !((String)change.get('SingleReason')).contains('Add Member') && !((String)change.get('SingleReason')).contains('Add Ancillary')) {
                List<Object> products = (List<Object>)change.get('ProductsToUpdate');
                if (change.get('selectedProducts') != '') {
                    products = mergeOldAndNewProducts((List<Object>)change.get('selectedProducts'),(List<Object>)change.get('ProductsToUpdate'));
                }
                Set<String> productsAdded = new Set<String>();
                for (Map<String,Object> oldFormatedDependantsItem : formatedDependants) {
                    for (Object prod : products) {
                        if ((String)((Map<String, Object>)((Map<String, Object>)oldFormatedDependantsItem).get('selectedProduct')).get('Id') == (String)((Map<String,Object>)prod).get('Id') || ( (String)((Map<String, Object>)((Map<String, Object>)oldFormatedDependantsItem).get('selectedProduct')).get('Type__c') == 'Medical' && (String)((Map<String,Object>)prod).get('Type__c') == 'Medical' )) {
                            if (!productsAdded.contains((String)((Map<String,Object>)prod).get('Id'))) {
                                oldFormatedDependantsItem.put('selectedProduct', prod);
                                oldFormatedDependantsItem.put('userInputs', oldFormatedDependantsItem.get('userInputs'));
                                chooseProductsOutput.add(oldFormatedDependantsItem);
                                productsAdded.add((String)((Map<String,Object>)prod).get('Id'));
                            }
                        }
                    }
                }
            }
        }
        
        for(Map<String, Object> change : changesForContracts){
    
            List<Object> objList_RemovedMembers = new List<Object>();
            List<Object> objList_auxSavedMembers = new List<Object>();
            List<Map<String,Object>> auxSavedMembers = new List<Map<String,Object>>();
            List<Map<String,Object>> RemovedMembers = new List<Map<String,Object>>();
    
            if(change.get('auxSavedMembers') != '' && change.get('auxSavedMembers') != null){
                objList_auxSavedMembers = (List<Object>)change.get('auxSavedMembers');
                for (Object itemObj : objList_auxSavedMembers) {
                    Map<String, Object> item = (Map<String, Object>) itemObj;
                    auxSavedMembers.add(item);
                }
            }
            if(change.get('RemovedMembers') != '' && change.get('RemovedMembers') != null){
                objList_RemovedMembers = (List<Object>)change.get('RemovedMembers');
                for (Object itemObj : objList_RemovedMembers) {
                    Map<String, Object> item = (Map<String, Object>) itemObj;
                    RemovedMembers.add(item);
                }
            }
            Set<String> membersToActivateIds = new Set<String>();
            Set<String> membersToDeactivateIds = new Set<String>();
            for (Map<String, Object> member : auxSavedMembers) {
                if((Boolean)member.get('isNew')==true){
                    membersToActivateIds.add((String)member.get('vlocity_ins__MemberIdentifier__c'));
                    membersToActivateDeactivateIds.add((String)member.get('vlocity_ins__MemberIdentifier__c'));
                    memberIdentifOfActive.add((String)member.get('vlocity_ins__MemberIdentifier__c'));
                    if((String)member.get('ARC_DependentRelationship__c') == 'Future Primary'){
                        futurePrimaryExist = true;
                        futurePrimaryIdientifier = (String)member.get('vlocity_ins__MemberIdentifier__c');
                    }
                }
            }
            for (Map<String, Object> member : RemovedMembers) {
                if ((Boolean)member.get('CHK_Delete')==true) {
                    membersToDeactivateIds.add((String)member.get('TXT_CensusMemberId'));
                    // membersToActivateDeactivateIds.add((String)member.get('vlocity_ins__MemberIdentifier__c'));
                    membersToActivateDeactivateIds.add((String)member.get('CensusMemberIdentifier'));
                    if ((Boolean)member.get('CHK_isPrimary')) {
                        contractsUseNewPrimarId.add((String)change.get('Id'));
                    }
                }
            }
            contract_membersToActivate.put((String)change.get('Id'),membersToActivateIds);
            contract_membersToDeactivate.put((String)change.get('Id'),membersToDeactivateIds);
        }
        vlocity_ins__GroupCensus__c census = [SELECT Id, Name, ARC_MinCensusDOB__c, ARC_CountSuscribers__c, ARC_CountChildren__c, ARC_CountSpouse__c, vlocity_ins__GroupId__c, ARC_PrimaryAccount__c FROM vlocity_ins__GroupCensus__c WHERE Id = :CensusId];
        Account censusAccount = [SELECT Id, vlocity_ins__Email__c, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, ARC_Effective_Date__c FROM Account WHERE Id =: census.vlocity_ins__GroupId__c LIMIT 1];
        List<vlocity_ins__GroupCensusMember__c> members = new List<vlocity_ins__GroupCensusMember__c>();
        Contract censusContract;
        if ( contractId != '' && contractId != null ) {
            Map<Id, vlocity_ins__GroupCensusMember__c> uniqueMembersMap = new Map<Id, vlocity_ins__GroupCensusMember__c>();
            for ( vlocity_ins__GroupCensusMemberPlan__c gcmp : [ 
                SELECT Id, ARC_Active__c, Name, vlocity_ins__GroupCensusMemberId__r.Id, 
                vlocity_ins__GroupCensusMemberId__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__Birthdate__c, 
                vlocity_ins__GroupCensusMemberId__r.Name, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c, 
                vlocity_ins__GroupCensusMemberId__r.ARC_Smoker__c, vlocity_ins__GroupCensusMemberId__r.ARC_ActiveMember__c, 
                vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressState__c, 
                vlocity_ins__GroupCensusMemberId__r.vlocity_ins__MemberIdentifier__c, 
                vlocity_ins__GroupCensusMemberId__r.arc_medicalproduct__c, vlocity_ins__GroupCensusMemberId__r.arc_dentalproduct__c, 
                vlocity_ins__GroupCensusMemberId__r.arc_visionproduct__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__censusid__c, 
                vlocity_ins__GroupCensusMemberId__r.vlocity_ins__birthdate__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__isprimarymember__c, 
                vlocity_ins__GroupCensusMemberId__r.vlocity_ins__gender__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__isspouse__c, 
                vlocity_ins__GroupCensusMemberId__r.vlocity_ins__lastname__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__firstname__c, 
                vlocity_ins__GroupCensusMemberId__r.ARC_AgeInSixMonths__c, vlocity_ins__GroupCensusMemberId__r.ARC_DependentRelationship__c, 
                vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c, vlocity_ins__ContractLineId__r.Name, vlocity_ins__ContractLineId__c 
                FROM vlocity_ins__GroupCensusMemberPlan__c 
                WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c = :contractId 
                OR vlocity_ins__GroupCensusMemberId__r.vlocity_ins__MemberIdentifier__c IN :membersToActivateDeactivateIds ]
            ) {
                uniqueMembersMap.put(gcmp.vlocity_ins__GroupCensusMemberId__c, gcmp.vlocity_ins__GroupCensusMemberId__r);
            }
            members = uniqueMembersMap.values();
            members.addAll([ 
                SELECT Id,vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__Birthdate__c, Name, vlocity_ins__Email__c, ARC_Smoker__c, 
                ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, 
                arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, 
                vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c,
                vlocity_ins__ContactId__c 
                FROM vlocity_ins__GroupCensusMember__c 
                WHERE vlocity_ins__MemberIdentifier__c IN :membersToActivateDeactivateIds AND Id NOT IN :uniqueMembersMap.keySet()]);
            censusContract = [SELECT Id, RecordTypeId, StartDate FROM Contract WHERE Id = :contractId];
        } else {
            members = [SELECT Id,vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__Birthdate__c, Name, vlocity_ins__Email__c, ARC_Smoker__c, ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c ,vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c = :CensusId AND (ARC_ActiveMember__c = true OR vlocity_ins__MemberIdentifier__c IN :membersToActivateDeactivateIds)];
            censusContract = [SELECT Id, RecordTypeId, StartDate FROM Contract WHERE AccountId =: censusAccount.Id ORDER BY CreatedDate DESC LIMIT 1];
        }
    

    
        for(Map<String, Object> change : changesForContracts) {
            Integer countChildren = 0;
            Integer maxDate = 0;
            String effectiveDate = ((String)change.get('SingleReason')).contains('Add Newborn') ? Datetime.now().format('yyyy-MM-dd') :(String)change.get('EffDate');
            Date minBirthdate = null;
            for (vlocity_ins__GroupCensusMember__c member: members) {

                if(member.vlocity_ins__MemberIdentifier__c == futurePrimaryIdientifier){
                    primaryId = member.Id;
                }

                if (member.vlocity_ins__IsPrimaryMember__c) {
                    oldRelatedPrimary = member.Id;
                }
                // if(member.ARC_ActiveMember__c){
                    oldActiveMembers.add(member.Id);
                // }
    
                if (contract_membersToActivate.get((String)change.get('Id')).contains(member.vlocity_ins__MemberIdentifier__c) || (!contract_membersToDeactivate.get((String)change.get('Id')).contains(member.Id) /* && member.ARC_ActiveMember__c */ ) ) {
                    if (member.ARC_DependentRelationship__c=='Child' && !member.vlocity_ins__IsPrimaryMember__c) {
                        countChildren++;
                    }
                    Date bd = member.vlocity_ins__birthdate__c;
                    if(minBirthdate == null){
                        minBirthdate = bd;
                    } else if(bd < minBirthdate){
                        minBirthdate = bd;
                    }
                    if (calculateAge(member.vlocity_ins__birthdate__c, Date.valueOf(effectiveDate).addDays(daysToAdd)) > maxDate) {
                        maxDate = calculateAge(member.vlocity_ins__birthdate__c, Date.valueOf(effectiveDate).addDays(daysToAdd));
                    }
                }
            }
            contract_PrimaryMemberAge.put((String)change.get('Id'), maxDate);
            if (countChildren - 3 <= 0) {
                contract_ExtraDeps.put((String)change.get('Id'), 0);
            }else {
                contract_ExtraDeps.put((String)change.get('Id'), countChildren - 3);
            }
        }
        for(Map<String, Object> change : changesForContracts) {
            String effectiveDate = ((String)change.get('SingleReason')).contains('Add Newborn') ? Datetime.now().format('yyyy-MM-dd') :(String)change.get('EffDate');
            String oldPrimaryId;
            Date minBirthdate = null;
            List<Map<String, Object>> userInputList = new List<Map<String, Object>>();
            for (vlocity_ins__GroupCensusMember__c member: members) {
                //Generate UserInputs for the new members
                if (membersToActivateDeactivateIds.contains(member.vlocity_ins__MemberIdentifier__c)) {
                    if (contract_membersToActivate.get((String)change.get('Id')) != null) {
                        if (contract_membersToActivate.get((String)change.get('Id')).contains(member.vlocity_ins__MemberIdentifier__c)) {
                            String oldMemberEmail = '';
                            if(contractsUseNewPrimarId.contains((String)change.get('Id'))){
                                if(member.Id == primaryId){
                                    member.vlocity_ins__IsPrimaryMember__c = true;
                                    oldMemberEmail = member.vlocity_ins__Email__c;
                                    member.vlocity_ins__Email__c = primaryEmail;
                                    oldRelatedPrimary = member.vlocity_ins__RelatedCensusMemberId__c;
                                    member.vlocity_ins__RelatedCensusMemberId__c = null;
                                }else if(primaryId != ''){
                                    if (member.vlocity_ins__IsPrimaryMember__c) {
                                        member.vlocity_ins__IsPrimaryMember__c = false;
                                    }
                                    member.vlocity_ins__RelatedCensusMemberId__c = primaryId;
                                }
                            }
    
                            //Start calculateUserInputs
    
                            userInputList.add(generateUserInputForMember(member, census, censusAccount, censusContract, effectiveDate, contract_ExtraDeps.get((String)change.get('Id')), contract_PrimaryMemberAge.get((String)change.get('Id'))));
    
                            //Start calculateUserInputs
    
    
                            if(contractsUseNewPrimarId.contains((String)change.get('Id'))){
                                if(member.Id == primaryId){
                                    member.vlocity_ins__IsPrimaryMember__c = false;
                                    member.vlocity_ins__Email__c = oldMemberEmail;
                                    member.vlocity_ins__RelatedCensusMemberId__c = oldRelatedPrimary;
                                }else{
                                    if (member.Id == oldRelatedPrimary) {
                                        member.vlocity_ins__IsPrimaryMember__c = true;
                                    }
                                    member.vlocity_ins__RelatedCensusMemberId__c = primaryId;
                                }
                            }
                        }
                    }
                }
    
                //Generate UserInputs for the current active members
                if (oldActiveMembers.contains(member.Id) && !contract_membersToDeactivate.get((String)change.get('Id')).contains(member.Id) && !contract_membersToActivate.get((String)change.get('Id')).contains(member.vlocity_ins__MemberIdentifier__c)) {
    
    
                    String oldMemberEmail = '';
    
                    if(contractsUseNewPrimarId.contains((String)change.get('Id'))){
                        if(member.Id == primaryId){
                            member.vlocity_ins__IsPrimaryMember__c = true;
                            oldMemberEmail = member.vlocity_ins__Email__c;
                            member.vlocity_ins__Email__c = primaryEmail;
                            oldRelatedPrimary = member.vlocity_ins__RelatedCensusMemberId__c;
                            member.vlocity_ins__RelatedCensusMemberId__c = null;
                        }else if(primaryId != ''){
                            if (member.vlocity_ins__IsPrimaryMember__c) {
                                member.vlocity_ins__IsPrimaryMember__c = false;
                            }
                            member.vlocity_ins__RelatedCensusMemberId__c = primaryId;
                        }
                    }
    
    
                    //Start GenerateUserInputs
                    userInputList.add(generateUserInputForMember(member, census, censusAccount, censusContract, effectiveDate, contract_ExtraDeps.get((String)change.get('Id')), contract_PrimaryMemberAge.get((String)change.get('Id'))));
                    
                    //End GenerateUserInputs
    
                    if(contractsUseNewPrimarId.contains((String)change.get('Id'))){
                        if(member.Id == primaryId){
                            member.vlocity_ins__IsPrimaryMember__c = false;
                            member.vlocity_ins__Email__c = oldMemberEmail;
                            member.vlocity_ins__RelatedCensusMemberId__c = oldRelatedPrimary;
                        }else{
                            if (member.Id == oldRelatedPrimary) {
                                member.vlocity_ins__IsPrimaryMember__c = true;
                            }
                            member.vlocity_ins__RelatedCensusMemberId__c = primaryId;
                        }
                    }
                }
            }
    
            Set<String> productIds = new Set<String>();
            Set<String> productIdMemberIds = new Set<String>();
            List<Map<String,Object>> productList = new List<Map<String,Object>>();
            List<Object> products = (List<Object>)change.get('ProductsToUpdate');
            if (change.get('selectedProducts') != '') {
                products = mergeOldAndNewProducts((List<Object>)change.get('selectedProducts'),(List<Object>)change.get('ProductsToUpdate'));
            }
            
            // if ((((String)change.get('SingleReason')).contains('Program Upgrade') ||((String)change.get('SingleReason')).contains('Remove Member') || ((String)change.get('SingleReason')).contains('Program Downgrade') || ((String)change.get('SingleReason')).contains('Remove Ancillary')) && /*!((String)change.get('SingleReason')).contains('Add Newborn')  && !((String)change.get('SingleReason')).contains('Add Member') &&*/ !((String)change.get('SingleReason')).contains('Add Ancillary')) {
            for (Object product : products) {
                if ((String)((Map<String,Object>)product).get('Type__c')=='Medical') {
                    Map<String,Object> productListItem = new Map<String,Object>();
                    
                    productListItem.put('selectedProduct',product);
    
                    productListItem.put('userInputs',userInputList);
    
                    productList.add(productListItem);
    
                    productIds.add((String)((Map<String,Object>)product).get('Id'));
    
                }
            }
            if (!((String)change.get('Reason')).contains('Remove Ancillary')) {
                if(((String)change.get('Reason')).contains('Add Ancillary') && !( ( inputMap.get('showAddAncillaryChooseProductsKeepSMART') != null && inputMap.get('showAddAncillaryChooseProductsKeepSMART') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepSMART') ) || ( inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != null && inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepAIDD' ) ) ) ) {
                    for (Object item : (List<Object>)inputMap.get('chooseProductsAncillaryOutput')) {
                        if ( (String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Type__c') != 'Medical' && ((Map<String,Object>)item).get('selectedProduct')!= null && ((Map<String,Object>)item).get('selectedProduct')!= '') {
                            Map<String, Object> pListItem = generateProductListItem((Map<String,Object>)item, userInputList);
                            String productIdMemberIdsItem = (String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Id');
                            
                            for (Object membs : (List<Object>)pListItem.get('userInputs')) {
                                productIdMemberIdsItem = productIdMemberIdsItem +(String)((Map<String,Object>)membs).get('CensusMemberId');
                            }
                            if (pListItem != null && !productIdMemberIds.contains(productIdMemberIdsItem) ) {
                                productList.add(pListItem);
                                productIds.add((String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Id'));
                                productIdMemberIds.add(productIdMemberIdsItem);
                            }
                        }
                    }
                    
                    
                }else if ( ( ( (String)change.get('Reason')).contains('Add Member') || ((String)change.get('Reason')).contains('Add Newborn') || ((String)change.get('Reason')).contains('Remove Member') || ( ( inputMap.get('showAddAncillaryChooseProductsKeepSMART') != null && inputMap.get('showAddAncillaryChooseProductsKeepSMART') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepSMART') ) ) || ( ( inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != null && inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepAIDD' ) ) ) ) &&  inputMap.get('chooseProductsAddMemberOutput') !='' && inputMap.get('chooseProductsAddMemberOutput') !=null) {
                    
                    for (Object item : (List<Object>)inputMap.get('chooseProductsAddMemberOutput')) {
                        if ((String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Type__c') != 'Medical' && ((Map<String,Object>)item).get('selectedProduct')!= null && ((Map<String,Object>)item).get('selectedProduct')!= '') {
                            Map<String, Object> pListItem = generateProductListItem((Map<String,Object>)item, userInputList);
                            String productIdMemberIdsItem = (String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Id');
                            for (Object membs : (List<Object>)pListItem.get('userInputs')) {
                                productIdMemberIdsItem = productIdMemberIdsItem +(String)((Map<String,Object>)membs).get('CensusMemberId');
                            }
                            if (pListItem != null && !productIdMemberIds.contains(productIdMemberIdsItem) ) {
                                productList.add(pListItem);
                                productIds.add((String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Id'));
                                productIdMemberIds.add(productIdMemberIdsItem);
                            }
                        }
                    }
                }else {
                    
                    for (Map<String,Object> item : formatedDependants) {
                        if ((String)((Map<String,Object>)item.get('selectedProduct')).get('Type__c') != 'Medical') {
                            
                            Map<String, Object> pListItem = generateProductListItem(item, userInputList);
                            if (pListItem!= null) {
                                if (pListItem.get('userInputs')!= null) {
                                    String productIdMemberIdsItem = (String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Id');
                                    for (Object membs : (List<Object>)pListItem.get('userInputs')) {
                                        productIdMemberIdsItem = productIdMemberIdsItem +(String)((Map<String,Object>)membs).get('CensusMemberId');
                                    }
                                    if (pListItem != null && !productIdMemberIds.contains(productIdMemberIdsItem) ) {
                                        productList.add(pListItem);
                                        productIds.add((String)((Map<String,Object>)item.get('selectedProduct')).get('Id'));
                                        
                                        
                                        productIdMemberIds.add(productIdMemberIdsItem);
                                    }
                                }
                            }
                        }
                    }
                }
            }
    
            List<Object> pList2 = new List<Object>();
            for (Map<String,Object> pListItem : productList) {
                for ( Object o : (List<Object>)pListItem.get('userInputs') ) {
                    
                    
                }
                List<Map<String,Object>> userInputList2 = new List<Map<String,Object>>();
                List<Object> userInputsObj = (List<Object>)pListItem.get('userInputs');
                Map<String, Object> plistItem22 = new Map<String, Object>();
                Boolean hasSpouse = false;
                Boolean hasFuturePrimary = false;
                Integer subscribers = userInputsObj.size();
                Integer countChildren = 0;
                Boolean hasPrimary = false;
                Boolean useSpouseAsPrimary = false;
                Integer olderAge = 0;
                String olderMemberId = '';
                Integer extraDeps = 0;
    
    
                for (Object memberObj : userInputsObj) {
                    Map<String,Object> memb = (Map<String, Object>) memberObj;
    
                    if (calculateAge((Date)memb.get('Birthdate'), Date.valueOf(effectiveDate).addDays(daysToAdd)) > olderAge) {
                        olderAge = calculateAge((Date)memb.get('Birthdate'), Date.valueOf(effectiveDate).addDays(daysToAdd));
                    }
                }
    
                for (Object memberObj : userInputsObj) {
                    Map<String,Object> memb = (Map<String, Object>) memberObj;
                    if ((Boolean)memb.get('RF_Census.CM_IsPrimary') && memb.get('CensusMemberRelationship')==null) {
                        
                        
                        hasPrimary=true;
                        // olderMemberId =(String)memb.get('CensusMemberId'); 
                        // olderAge = calculateAge((Date)memb.get('Birthdate'), Date.valueOf(effectiveDate));
                    }
                    if((String)memb.get('CensusMemberRelationship')=='Future Primary'){
                        hasFuturePrimary = true;
                    }
                }
                
                for (Object memberObj : userInputsObj) {
                    Map<String,Object> memb = (Map<String, Object>) memberObj;
                    if ((String)memb.get('CensusMemberRelationship') == 'Child') {
                        countChildren++;
                    }
                    if ((String)memb.get('CensusMemberRelationship') == 'Spouse') {
                        if (hasPrimary) {
                            hasSpouse=true;
                        }
                    }
                }
    
    
                for (Object memberObj : userInputsObj) {
                    Map<String,Object> memb = (Map<String, Object>) memberObj;
                    if (!hasSpouse && !hasPrimary) {
                        if (calculateAge((Date)memb.get('Birthdate'), Date.valueOf(effectiveDate).addDays(daysToAdd)) > olderAge){
                            olderAge = calculateAge((Date)memb.get('Birthdate'), Date.valueOf(effectiveDate).addDays(daysToAdd));
                            olderMemberId = (String)memb.get('CensusMemberId');
                        }
                    }
                }
    
                for (Object memberObj : userInputsObj) {
                    Map<String,Object> memb = (Map<String, Object>) memberObj;
                    if (olderMemberId == (String)memb.get('CensusMemberId')) {   
                        // countChildren--;
                    }
                }
    
    
                if (countChildren - 3 <= 0) {
                    extraDeps = 0;
                }else {
                    extraDeps = countChildren - 3;
                }
    
                
                String coverageAIDD = getCoverageAidd(hasSpouse&&hasPrimary, subscribers, countChildren);
                String coverageSMART = getCoverageSmart(hasSpouse&&hasPrimary, subscribers, countChildren);
                
    
                for (Object memberObj : userInputsObj) {
                    Map<String,Object> memb = (Map<String, Object>) memberObj;
                    Map<String,Object> memb2 = new Map<String,Object>();
                    Boolean relationshipChanged = false;
                    memb2.put('RF_Census.CM_IsPrimary', memb.get('RF_Census.CM_IsPrimary'));
                    memb2.put('RF_Census.CM_IsSpouse', memb.get('RF_Census.CM_IsSpouse'));
                    memb2.put('CensusMemberRelationship', memb.get('CensusMemberRelationship'));
                    if ((olderMemberId == (String)memb.get('CensusMemberId') && !hasFuturePrimary) || (hasFuturePrimary && (String)memb.get('CensusMemberRelationship')=='Future Primary')) {
                        memb2.put('RF_Census.CM_IsPrimary', true);
                        memb2.put('RF_Census.CM_IsSpouse', false);
                        memb2.put('CensusMemberRelationship', null);
                        relationshipChanged = true;
                    }
                    if (((String)memb.get('CensusMemberRelationship') == 'Spouse' && !hasFuturePrimary)|| (hasFuturePrimary && (String)memb.get('CensusMemberRelationship')=='Future Primary')) {
                        if (!hasPrimary) {
                            memb2.put('RF_Census.CM_IsPrimary', true);
                            memb2.put('RF_Census.CM_IsSpouse', false);
                            memb2.put('CensusMemberRelationship', null);
                            // olderAge = calculateAge((Date)memb.get('Birthdate'), Date.valueOf(effectiveDate));
                        }else {
                            memb2.put('RF_Census.CM_IsPrimary', false);
                            memb2.put('RF_Census.CM_IsSpouse', true);
                            memb2.put('CensusMemberRelationship', 'Spouse');
                        }
                        relationshipChanged = true; 
                    }
                    memb2.put('RF_Census.CRF_CoverageAIDD', coverageAIDD);
                    memb2.put('RF_Census.CRF_Coverage', coverageSMART);
                    
                    memb2.put('CensusMemberId',memb.get('CensusMemberId'));
                    memb2.put('CensusMemberName',memb.get('CensusMemberName'));
                    memb2.put('isMinor',memb.get('isMinor'));
                    memb2.put('CensusMemberLastName',memb.get('CensusMemberLastName'));
                    memb2.put('FirstName',memb.get('FirstName'));
                    if (!relationshipChanged) {
                        memb2.put('CensusMemberRelationship',memb.get('CensusMemberRelationship'));
                    }
                    memb2.put('CensusMemberFirstName',memb.get('CensusMemberFirstName'));
                    memb2.put('LastName',memb.get('LastName'));
                    memb2.put('CensusMemberRelationship',memb.get('CensusMemberRelationship'));
                    memb2.put('CensusMemberIdentifier',memb.get('CensusMemberIdentifier'));
                    memb2.put('CensusEmail',memb.get('CensusEmail'));
                    memb2.put('ContractId',memb.get('ContractId'));
                    memb2.put('AccountId',memb.get('AccountId'));
                    memb2.put('ContractRecType',memb.get('ContractRecType'));
                    memb2.put('ContractStartDate',memb.get('ContractStartDate'));
                    memb2.put('Email',memb.get('Email'));
                    memb2.put('Phone',memb.get('Phone'));
                    memb2.put('Street',memb.get('Street'));
                    memb2.put('City',memb.get('City'));
                    memb2.put('State',memb.get('State'));
                    memb2.put('Zipcode',memb.get('Zipcode'));
                    memb2.put('EffectiveDate',memb.get('EffectiveDate'));
                    memb2.put('Birthdate',memb.get('Birthdate'));
                    memb2.put('RF_Census.CRF_Dependants',subscribers-1);
                    memb2.put('RF_Census.CRF_ExtraDependants',extraDeps);
                    memb2.put('RF_Census.CRF_PrimaryMemberAge',olderAge);
                    memb2.put('RF_Census.CM_State',memb.get('RF_Census.CM_State'));
                    // memb2.put('RF_Census.CM_IsPrimary',memb.get(''));
                    memb2.put('contact',memb.get('contact'));
    
                    // if (member.ARC_DependentRelationship__c=='Spouse' && !member.vlocity_ins__isprimarymember__c) {
                        // userInputMap.put('RF_Census.CM_IsSpouse', member.vlocity_ins__IsSpouse__c));
                    // }else {
                    //     userInputMap.put('RF_Census.CM_IsSpouse', false));
                    // }        
                    memb2.put('RF_Census.CM_Smoker', memb.get('RF_Census.CM_Smoker'));
                    memb2.put('RF_Census.CM_Age', memb.get('RF_Census.CM_Age'));
    
                    userInputList2.add(memb2);
                }
                if (pListItem.get('selectedProduct')!=null && pListItem.get('selectedProduct')!= '') {
                    plistItem22.put('userInputs', userInputList2);
                    plistItem22.put('selectedProduct', pListItem.get('selectedProduct'));
                    pList2.add(plistItem22);
                }
            }
            
    
    
            Map<String,Object> userInputNode = new Map<String,Object> ();
            userInputNode.put('userInputs2',userInputList);
            userInputNode.put('Reason',(String)change.get('Reason'));
            userInputNode.put('SingleReason',(String)change.get('SingleReason'));
            userInputNode.put('SingleReasonToDisplay',(String)change.get('SingleReasonToDisplay'));
            userInputNode.put('EffDate',(String)change.get('EffDate'));
            userInputNode.put('Id',(String)change.get('Id'));
            userInputNode.put('censusId',(String)change.get('censusId'));
            userInputNode.put('caseId',(String)change.get('caseId'));
            userInputNode.put('accountId',(String)change.get('accountId'));
            userInputNode.put('auxSavedMembers',change.get('auxSavedMembers'));
            userInputNode.put('RemovedMembers',change.get('RemovedMembers'));
            userInputNode.put('selectedProducts',change.get('selectedProducts'));
            userInputNode.put('ProductsToUpdate',change.get('ProductsToUpdate'));
            // userInputNode.put('productList',productList);
            userInputNode.put('productList',pList2);
    
            listUserInputLists.add(userInputNode); 
        }
        outputMap.put('changesForContracts',listUserInputLists);
    }
    public static void updateAndRepriceMultiContractsCase(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){

        String CensusId = (String)inputMap.get('CensusId');
        String primaryId = (String)inputMap.get('primaryId');
        String primaryEmail = (String)inputMap.get('primaryEmail');
        String oldRelatedPrimary = '';

        List<Object> objList_changesForContracts = (List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('changesForContracts')));
        List<Object> listUserInputLists = new List<Object>();
        List<Map<String,Object>> changesForContracts = new List<Map<String,Object>>();
        List<Object> chooseProductsOutput = new List<Object>();
        List<Object> OBJmemberIds = (List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('memberIds')));
        List<Object> obj_formatedDependants = (List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('productList')));
        List<Map<String,Object>> formatedDependants = new List<Map<String,Object>>();

        Set<String> membersToActivateDeactivateIds = new Set<String>();
        Set<String> memberIdentifOfActive = new Set<String>();
        Set<String> contractsUseNewPrimarId = new Set<String>();
        Set<String> oldActiveMembers = new Set<String>();
        Set<String> depProds = new Set<String>();
        Set<String> addAncillaryProds = new Set<String>();
        Set<String> addMemberProds = new Set<String>();

        Map<String,Set<String>> contract_membersToDeactivate = new Map<String,Set<String>>();
        Map<String,Set<String>> contract_membersToActivate = new Map<String,Set<String>>();
        Map<String, Integer> contract_PrimaryMemberAge = new Map<String, Integer>();
        Map<String, Integer> contract_ExtraDeps = new Map<String, Integer>();
        Map<String,Object> chooseProductJson = new Map<String,Object> ();

        Set<String> memberIds = new Set<String>();
        
        Boolean notRejectedMembers = (Boolean)inputMap.get('notRejectedMembers');

        for (Object mId : OBJmemberIds) {
            memberIds.add((String)mId);
        }




        if (inputMap.get('chooseProductsAncillaryOutput')!='' && inputMap.get('chooseProductsAncillaryOutput')!=null) {
            chooseProductsOutput.addAll((List<Object>)inputMap.get('chooseProductsAncillaryOutput'));
            for (Object item : (List<Object>)inputMap.get('chooseProductsAncillaryOutput')) {
                
                addAncillaryProds.add((String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Id'));
            }
        }
        if (inputMap.get('chooseProductsAddMemberOutput')!='' && inputMap.get('chooseProductsAddMemberOutput')!=null) {
            chooseProductsOutput.addAll((List<Object>)inputMap.get('chooseProductsAddMemberOutput'));
            for (Object item : (List<Object>)inputMap.get('chooseProductsAddMemberOutput')) {
                addMemberProds.add((String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Id'));
                formatedDependants.add((Map<String,Object>)item);
            }
        }
        

        if ( notRejectedMembers == true ) {            
            for (Object item : obj_formatedDependants) {
                Map<String,Object> pListItem = (Map<String,Object>)item;
                formatedDependants.add(pListItem);
            }
        }
        

        chooseProductsOutput.addAll(formatedDependants);

        for (Object itemObj : objList_changesForContracts) {
            Map<String, Object> item = (Map<String, Object>) itemObj;
            changesForContracts.add(item);
        }



        for(Map<String, Object> change : changesForContracts){

            if ((((String)change.get('SingleReason')).contains('Program Upgrade') || ((String)change.get('SingleReason')).contains('Program Downgrade') || ((String)change.get('SingleReason')).contains('Remove Ancillary')) && !((String)change.get('SingleReason')).contains('Add Newborn')  && !((String)change.get('SingleReason')).contains('Add Member') && !((String)change.get('SingleReason')).contains('Add Ancillary')) {
                List<Object> products = (List<Object>)change.get('ProductsToUpdate');
                if (change.get('selectedProducts') != '') {
                    products = mergeOldAndNewProducts((List<Object>)change.get('selectedProducts'),(List<Object>)change.get('ProductsToUpdate'));
                }
                Set<String> productsAdded = new Set<String>();
                for (Map<String,Object> oldFormatedDependantsItem : formatedDependants) {
                    for (Object prod : products) {
                        
                        
                        
                        
                        
                        if ((String)((Map<String, Object>)((Map<String, Object>)oldFormatedDependantsItem).get('selectedProduct')).get('Id') == (String)((Map<String,Object>)prod).get('Id') || ( (String)((Map<String, Object>)((Map<String, Object>)oldFormatedDependantsItem).get('selectedProduct')).get('Type__c') == 'Medical' && (String)((Map<String,Object>)prod).get('Type__c') == 'Medical' )) {
                            if (!productsAdded.contains((String)((Map<String,Object>)prod).get('Id'))) {
                                
                                List<Map<String,Object>> membersIds = new List<Map<String,Object>>();
                                Map<String,Object> selectedProduct = new Map<String,Object>();
                                // selectedProduct.put('Type__c', ((Map<String,Object>)prod).get('Type__c'));
                                // selectedProduct.put('Id', ((Map<String,Object>)prod).get('Id'));
                                oldFormatedDependantsItem.put('selectedProduct', prod);
                                oldFormatedDependantsItem.put('userInputs', oldFormatedDependantsItem.get('userInputs'));
                                chooseProductsOutput.add(oldFormatedDependantsItem);
                                productsAdded.add((String)((Map<String,Object>)prod).get('Id'));
                            }
                        }
                    }
                }
            }
        }
        
        for(Map<String, Object> change : changesForContracts){

            List<Object> objList_RemovedMembers = new List<Object>();
            List<Object> objList_auxSavedMembers = new List<Object>();
            List<Map<String,Object>> auxSavedMembers = new List<Map<String,Object>>();
            List<Map<String,Object>> RemovedMembers = new List<Map<String,Object>>();

            if(change.get('auxSavedMembers') != '' && change.get('auxSavedMembers') != null){
                objList_auxSavedMembers = (List<Object>)change.get('auxSavedMembers');
                for (Object itemObj : objList_auxSavedMembers) {
                    Map<String, Object> item = (Map<String, Object>) itemObj;
                    auxSavedMembers.add(item);
                }
            }
            if(change.get('RemovedMembers') != '' && change.get('RemovedMembers') != null){
                objList_RemovedMembers = (List<Object>)change.get('RemovedMembers');
                for (Object itemObj : objList_RemovedMembers) {
                    Map<String, Object> item = (Map<String, Object>) itemObj;
                    RemovedMembers.add(item);
                }
            }
            Set<String> membersToActivateIds = new Set<String>();
            Set<String> membersToDeactivateIds = new Set<String>();
            for (Map<String, Object> member : auxSavedMembers) {
                if((Boolean)member.get('isNew')==true){
                    membersToActivateIds.add((String)member.get('vlocity_ins__MemberIdentifier__c'));
                    membersToActivateDeactivateIds.add((String)member.get('vlocity_ins__MemberIdentifier__c'));
                    memberIdentifOfActive.add((String)member.get('vlocity_ins__MemberIdentifier__c'));
                }
            }
            for (Map<String, Object> member : RemovedMembers) {
                if ((Boolean)member.get('CHK_Delete')==true) {
                    membersToDeactivateIds.add((String)member.get('TXT_CensusMemberId'));
                    membersToActivateDeactivateIds.add((String)member.get('vlocity_ins__MemberIdentifier__c'));
                    if ((Boolean)member.get('CHK_isPrimary')) {
                        contractsUseNewPrimarId.add((String)change.get('Id'));
                    }
                }
            }
            contract_membersToActivate.put((String)change.get('Id'),membersToActivateIds);
            contract_membersToDeactivate.put((String)change.get('Id'),membersToDeactivateIds);
        }
        vlocity_ins__GroupCensus__c census = [SELECT Id, Name, ARC_MinCensusDOB__c, ARC_CountSuscribers__c, ARC_CountChildren__c, ARC_CountSpouse__c, vlocity_ins__GroupId__c, ARC_PrimaryAccount__c FROM vlocity_ins__GroupCensus__c WHERE Id = :CensusId];
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id,vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__Birthdate__c, Name, vlocity_ins__Email__c, ARC_Smoker__c, ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c ,vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE Id IN :memberIds];
        Account censusAccount = [SELECT Id, vlocity_ins__Email__c, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, ARC_Effective_Date__c FROM Account WHERE Id =: census.vlocity_ins__GroupId__c LIMIT 1];
        Contract censusContract = [SELECT Id, RecordTypeId, StartDate FROM Contract WHERE AccountId =: censusAccount.Id ORDER BY CreatedDate DESC LIMIT 1];


        for(Map<String, Object> change : changesForContracts) {
            Integer countChildren = 0;
            String effectiveDate = (String)change.get('EffDate');
            Date minBirthdate = null;
            Integer maxAge = 0;
            for (vlocity_ins__GroupCensusMember__c member: members) {
                if (member.vlocity_ins__IsPrimaryMember__c) {
                    oldRelatedPrimary = member.Id;
                }
                if(member.ARC_ActiveMember__c){
                    oldActiveMembers.add(member.Id);
                }

                // if (contract_membersToActivate.get((String)change.get('Id')).contains(member.vlocity_ins__MemberIdentifier__c) || (!contract_membersToDeactivate.get((String)change.get('Id')).contains(member.Id) && member.ARC_ActiveMember__c) ) {
                if (member.ARC_DependentRelationship__c=='Child' && !member.vlocity_ins__IsPrimaryMember__c) {
                    countChildren++;
                }
                Date bd = member.vlocity_ins__birthdate__c;
                if(minBirthdate == null){
                    minBirthdate = bd;
                } else if(bd < minBirthdate){
                minBirthdate = bd;
                }
                if (calculateAge(member.vlocity_ins__birthdate__c, Date.valueOf(effectiveDate).addDays(daysToAdd)) > maxAge ) {
                    maxAge = calculateAge(member.vlocity_ins__birthdate__c, Date.valueOf(effectiveDate).addDays(daysToAdd));
                }
                // }
            }
            contract_PrimaryMemberAge.put((String)change.get('Id'), maxAge);
            if (countChildren - 3 <= 0) {
                contract_ExtraDeps.put((String)change.get('Id'), 0);
            }else {
                contract_ExtraDeps.put((String)change.get('Id'), countChildren - 3);
            }
        }
        
        for(Map<String, Object> change : changesForContracts) {
            String effectiveDate = (String)change.get('EffDate');
            String oldPrimaryId;
            Date minBirthdate = null;
            List<Map<String, Object>> userInputList = new List<Map<String, Object>>();
            for (vlocity_ins__GroupCensusMember__c member: members) {
                //Generate UserInputs for the new members
                // if (membersToActivateDeactivateIds.contains(member.vlocity_ins__MemberIdentifier__c)) {
                //     if (contract_membersToActivate.get((String)change.get('Id')) != null) {
                //         if (contract_membersToActivate.get((String)change.get('Id')).contains(member.vlocity_ins__MemberIdentifier__c)) {
                            String oldMemberEmail = '';
                            if(contractsUseNewPrimarId.contains((String)change.get('Id'))){

                                if(member.Id == primaryId){
                                    member.vlocity_ins__IsPrimaryMember__c = true;
                                    oldMemberEmail = member.vlocity_ins__Email__c;
                                    member.vlocity_ins__Email__c = primaryEmail;
                                    oldRelatedPrimary = member.vlocity_ins__RelatedCensusMemberId__c;
                                    member.vlocity_ins__RelatedCensusMemberId__c = null;
                                }else if(primaryId != ''){
                                    if (member.vlocity_ins__IsPrimaryMember__c) {
                                        member.vlocity_ins__IsPrimaryMember__c = false;
                                    }
                                    member.vlocity_ins__RelatedCensusMemberId__c = primaryId;
                                }
                            }

                            //Start calculateUserInputs

                            userInputList.add(generateUserInputForMember(member, census, censusAccount, censusContract, effectiveDate, contract_ExtraDeps.get((String)change.get('Id')), contract_PrimaryMemberAge.get((String)change.get('Id'))));

                            //Start calculateUserInputs


                            if(contractsUseNewPrimarId.contains((String)change.get('Id'))){
                                if(member.Id == primaryId){
                                    member.vlocity_ins__IsPrimaryMember__c = false;
                                    member.vlocity_ins__Email__c = oldMemberEmail;
                                    member.vlocity_ins__RelatedCensusMemberId__c = oldRelatedPrimary;
                                }else{
                                    if (member.Id == oldRelatedPrimary) {
                                        member.vlocity_ins__IsPrimaryMember__c = true;
                                    }
                                    member.vlocity_ins__RelatedCensusMemberId__c = primaryId;
                                }
                            }
                //         }
                //     }
                // }

                //Generate UserInputs for the current active members
                /*
                if (oldActiveMembers.contains(member.Id) && !contract_membersToDeactivate.get((String)change.get('Id')).contains(member.Id) && !contract_membersToActivate.get((String)change.get('Id')).contains(member.vlocity_ins__MemberIdentifier__c)) {
                    String oldMemberEmail = '';
                    if(contractsUseNewPrimarId.contains((String)change.get('Id'))){
                        if(member.Id == primaryId){
                            member.vlocity_ins__IsPrimaryMember__c = true;
                            oldMemberEmail = member.vlocity_ins__Email__c;
                            member.vlocity_ins__Email__c = primaryEmail;
                            oldRelatedPrimary = member.vlocity_ins__RelatedCensusMemberId__c;
                            member.vlocity_ins__RelatedCensusMemberId__c = null;
                        }else if(primaryId != ''){
                            if (member.vlocity_ins__IsPrimaryMember__c) {
                                member.vlocity_ins__IsPrimaryMember__c = false;
                            }
                            member.vlocity_ins__RelatedCensusMemberId__c = primaryId;
                        }
                    }


                    //Start GenerateUserInputs
                    userInputList.add(generateUserInputForMember(member, census, censusAccount, censusContract, effectiveDate, contract_ExtraDeps.get((String)change.get('Id')), contract_PrimaryMemberAge.get((String)change.get('Id'))));
                    
                    //End GenerateUserInputs

                    if(contractsUseNewPrimarId.contains((String)change.get('Id'))){
                        if(member.Id == primaryId){
                            member.vlocity_ins__IsPrimaryMember__c = false;
                            member.vlocity_ins__Email__c = oldMemberEmail;
                            member.vlocity_ins__RelatedCensusMemberId__c = oldRelatedPrimary;
                        }else{
                            if (member.Id == oldRelatedPrimary) {
                                member.vlocity_ins__IsPrimaryMember__c = true;
                            }
                            member.vlocity_ins__RelatedCensusMemberId__c = primaryId;
                        }
                    }
                }*/

                



            }
            Set<String> productIds = new Set<String>();
            Set<String> productIdMemberIds = new Set<String>();
            List<Map<String,Object>> productList = new List<Map<String,Object>>();
            List<Object> products = (List<Object>)change.get('ProductsToUpdate');
            if (change.get('selectedProducts') != '') {
                products = mergeOldAndNewProducts((List<Object>)change.get('selectedProducts'),(List<Object>)change.get('ProductsToUpdate'));
            }
            
            // if ((((String)change.get('SingleReason')).contains('Program Upgrade') ||((String)change.get('SingleReason')).contains('Remove Member') || ((String)change.get('SingleReason')).contains('Program Downgrade') || ((String)change.get('SingleReason')).contains('Remove Ancillary')) && /*!((String)change.get('SingleReason')).contains('Add Newborn')  && !((String)change.get('SingleReason')).contains('Add Member') &&*/ !((String)change.get('SingleReason')).contains('Add Ancillary')) {
            for (Object product : products) {
                if ((String)((Map<String,Object>)product).get('Type__c')=='Medical') {
                    Map<String,Object> productListItem = new Map<String,Object>();
                    
                    productListItem.put('selectedProduct',product);

                    productListItem.put('userInputs',userInputList);

                    productList.add(productListItem);

                    productIds.add((String)((Map<String,Object>)product).get('Id'));

                }
            }
            if (!((String)change.get('Reason')).contains('Remove Ancillary')) {
                
                if(((String)change.get('Reason')).contains('Add Ancillary') && !( ( inputMap.get('showAddAncillaryChooseProductsKeepSMART') != null && inputMap.get('showAddAncillaryChooseProductsKeepSMART') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepSMART') ) || ( inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != null && inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepAIDD' ) ) ) ) {
                    
                    for (Object item : (List<Object>)inputMap.get('chooseProductsAncillaryOutput')) {
                        if ( (String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Type__c') != 'Medical' && ((Map<String,Object>)item).get('selectedProduct')!= null && ((Map<String,Object>)item).get('selectedProduct')!= '') {
                            Map<String, Object> pListItem = generateProductListItem((Map<String,Object>)item, userInputList);
                            String productIdMemberIdsItem = (String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Id');
                            
                            for (Object membs : (List<Object>)pListItem.get('userInputs')) {
                                productIdMemberIdsItem = productIdMemberIdsItem +(String)((Map<String,Object>)membs).get('CensusMemberId');
                            }
                            if (pListItem != null && !productIdMemberIds.contains(productIdMemberIdsItem) ) {
                                productList.add(pListItem);
                                productIds.add((String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Id'));
                                productIdMemberIds.add(productIdMemberIdsItem);
                            }
                        }
                    }
                    
                    
                }else if ((((String)change.get('Reason')).contains('Add Member') || ((String)change.get('Reason')).contains('Add Newborn') || ((String)change.get('Reason')).contains('Remove Member') || ( ( inputMap.get('showAddAncillaryChooseProductsKeepSMART') != null && inputMap.get('showAddAncillaryChooseProductsKeepSMART') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepSMART') ) ) || ( ( inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != null && inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepAIDD' ) ) ) ) &&  inputMap.get('chooseProductsAddMemberOutput') !='' && inputMap.get('chooseProductsAddMemberOutput') !=null) {
                    
                    for (Object item : (List<Object>)inputMap.get('chooseProductsAddMemberOutput')) {
                        if ((String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Type__c') != 'Medical' && ((Map<String,Object>)item).get('selectedProduct')!= null && ((Map<String,Object>)item).get('selectedProduct')!= '') {
                            Map<String, Object> pListItem = generateProductListItem((Map<String,Object>)item, userInputList);
                            String productIdMemberIdsItem = (String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Id');
                            for (Object membs : (List<Object>)pListItem.get('userInputs')) {
                                productIdMemberIdsItem = productIdMemberIdsItem +(String)((Map<String,Object>)membs).get('CensusMemberId');
                            }
                            if (pListItem != null && !productIdMemberIds.contains(productIdMemberIdsItem) ) {
                                productList.add(pListItem);
                                productIds.add((String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Id'));
                                productIdMemberIds.add(productIdMemberIdsItem);
                            }
                        }
                    }
                }else {

                    for (Map<String,Object> item : formatedDependants) {
                        if ((String)((Map<String,Object>)item.get('selectedProduct')).get('Type__c') != 'Medical') {
                            
                            Map<String, Object> pListItem = generateProductListItem(item, userInputList);
                            if (pListItem!= null) {
                                if (pListItem.get('userInputs')!= null) {
                                    String productIdMemberIdsItem = (String)((Map<String,Object>)(((Map<String,Object>)item).get('selectedProduct'))).get('Id');
                                    for (Object membs : (List<Object>)pListItem.get('userInputs')) {
                                        productIdMemberIdsItem = productIdMemberIdsItem +(String)((Map<String,Object>)membs).get('CensusMemberId');
                                    }
                                    if (pListItem != null && !productIdMemberIds.contains(productIdMemberIdsItem) ) {
                                        productList.add(pListItem);
                                        productIds.add((String)((Map<String,Object>)item.get('selectedProduct')).get('Id'));
                                        
                                        
                                        productIdMemberIds.add(productIdMemberIdsItem);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            List<Object> pList2 = new List<Object>();
            for (Map<String,Object> pListItem : productList) {
                List<Map<String,Object>> userInputList2 = new List<Map<String,Object>>();
                List<Object> userInputsObj = (List<Object>)pListItem.get('userInputs');
                Map<String, Object> plistItem22 = new Map<String, Object>();
                Boolean hasSpouse = false;
                Integer subscribers = userInputsObj.size();
                Integer countChildren = 0;
                Boolean hasPrimary = false;
                Boolean useSpouseAsPrimary = false;
                Integer olderAge = 0;
                String olderMemberId = '';
                Integer extraDeps = 0;




                for (Object memberObj : userInputsObj) {
                    Map<String,Object> memb = (Map<String, Object>) memberObj;
                    if ((Boolean)memb.get('RF_Census.CM_IsPrimary') && memb.get('CensusMemberRelationship')==null) {
                        
                        
                        hasPrimary=true;
                        // olderMemberId =(String)memb.get('CensusMemberId'); 
                        olderAge = calculateAge((Date)memb.get('Birthdate'), Date.valueOf(effectiveDate).addDays(daysToAdd));
                    }
                }
                // 
                for (Object memberObj : userInputsObj) {
                    Map<String,Object> memb = (Map<String, Object>) memberObj;
                    if ((String)memb.get('CensusMemberRelationship') == 'Child') {
                        countChildren++;
                    }
                    if ((String)memb.get('CensusMemberRelationship') == 'Spouse') {
                        if (hasPrimary) {
                            hasSpouse=true;
                        }
                    }
                }


                for (Object memberObj : userInputsObj) {
                    Map<String,Object> memb = (Map<String, Object>) memberObj;
                    if (!hasSpouse && !hasPrimary) {
                        if (calculateAge((Date)memb.get('Birthdate'), Date.valueOf(effectiveDate).addDays(daysToAdd)) > olderAge){
                            olderAge = calculateAge((Date)memb.get('Birthdate'), Date.valueOf(effectiveDate).addDays(daysToAdd));
                            olderMemberId = (String)memb.get('CensusMemberId');
                        }
                    }
                }

                for (Object memberObj : userInputsObj) {
                    Map<String,Object> memb = (Map<String, Object>) memberObj;
                    if (olderMemberId == (String)memb.get('CensusMemberId')) {   
                        // countChildren--;
                    }
                }


                if (countChildren - 3 <= 0) {
                    extraDeps = 0;
                }else {
                    extraDeps = countChildren - 3;
                }

                
                String coverageAIDD = getCoverageAidd(hasSpouse&&hasPrimary, subscribers, countChildren);
                String coverageSMART = getCoverageSmart(hasSpouse&&hasPrimary, subscribers, countChildren);

                for (Object memberObj : userInputsObj) {
                    Map<String,Object> memb = (Map<String, Object>) memberObj;

                    if (calculateAge((Date)memb.get('Birthdate'), Date.valueOf(effectiveDate).addDays(daysToAdd)) > olderAge) {
                        olderAge = calculateAge((Date)memb.get('Birthdate'), Date.valueOf(effectiveDate).addDays(daysToAdd));
                    }
                }

                
                for (Object memberObj : userInputsObj) {
                    Map<String,Object> memb = (Map<String, Object>) memberObj;
                    Map<String,Object> memb2 = new Map<String,Object>();
                    memb2.put('RF_Census.CM_IsPrimary', memb.get('RF_Census.CM_IsPrimary'));
                    memb2.put('RF_Census.CM_IsSpouse', memb.get('RF_Census.CM_IsSpouse'));
                    memb2.put('CensusMemberRelationship', memb.get('CensusMemberRelationship'));
                    if (olderMemberId == (String)memb.get('CensusMemberId')) {
                        memb2.put('RF_Census.CM_IsPrimary', true);
                        memb2.put('RF_Census.CM_IsSpouse', false);
                        memb2.put('CensusMemberRelationship', null);
                    }
                    if ((String)memb.get('CensusMemberRelationship') == 'Spouse') {
                        if (!hasPrimary) {
                            memb2.put('RF_Census.CM_IsPrimary', true);
                            memb2.put('RF_Census.CM_IsSpouse', false);
                            memb2.put('CensusMemberRelationship', null);
                            // olderAge = calculateAge((Date)memb.get('Birthdate'), Date.valueOf(effectiveDate));
                        }else {
                            memb2.put('RF_Census.CM_IsPrimary', false);
                            memb2.put('RF_Census.CM_IsSpouse', true);
                            memb2.put('CensusMemberRelationship', 'Spouse');
                        }
                    }
                    memb2.put('RF_Census.CRF_CoverageAIDD', coverageAIDD);
                    memb2.put('RF_Census.CRF_Coverage', coverageSMART);




                    memb2.put('CensusMemberId',memb.get('CensusMemberId'));
                    memb2.put('CensusMemberName',memb.get('CensusMemberName'));
                    memb2.put('isMinor',memb.get('isMinor'));
                    memb2.put('CensusMemberLastName',memb.get('CensusMemberLastName'));
                    memb2.put('FirstName',memb.get('FirstName'));
                    memb2.put('CensusMemberFirstName',memb.get('CensusMemberFirstName'));
                    memb2.put('LastName',memb.get('LastName'));
                    memb2.put('CensusMemberRelationship',memb.get('CensusMemberRelationship'));
                    memb2.put('CensusMemberIdentifier',memb.get('CensusMemberIdentifier'));
                    memb2.put('CensusEmail',memb.get('CensusEmail'));
                    memb2.put('ContractId',memb.get('ContractId'));
                    memb2.put('AccountId',memb.get('AccountId'));
                    memb2.put('ContractRecType',memb.get('ContractRecType'));
                    memb2.put('ContractStartDate',memb.get('ContractStartDate'));
                    memb2.put('Email',memb.get('Email'));
                    memb2.put('Phone',memb.get('Phone'));
                    memb2.put('Street',memb.get('Street'));
                    memb2.put('City',memb.get('City'));
                    memb2.put('State',memb.get('State'));
                    memb2.put('Zipcode',memb.get('Zipcode'));
                    memb2.put('EffectiveDate',memb.get('EffectiveDate'));
                    memb2.put('Birthdate',memb.get('Birthdate'));
                    memb2.put('RF_Census.CRF_Dependants',subscribers-1);
                    memb2.put('RF_Census.CRF_ExtraDependants',extraDeps);
                    memb2.put('RF_Census.CRF_PrimaryMemberAge',olderAge);
                    memb2.put('RF_Census.CM_State',memb.get('RF_Census.CM_State'));
                    // memb2.put('RF_Census.CM_IsPrimary',memb.get(''));
                    memb2.put('contact',memb.get('contact'));

                    // if (member.ARC_DependentRelationship__c=='Spouse' && !member.vlocity_ins__isprimarymember__c) {
                        // userInputMap.put('RF_Census.CM_IsSpouse', member.vlocity_ins__IsSpouse__c));
                    // }else {
                    //     userInputMap.put('RF_Census.CM_IsSpouse', false));
                    // }        
                    memb2.put('RF_Census.CM_Smoker', memb.get('RF_Census.CM_Smoker'));
                    memb2.put('RF_Census.CM_Age', memb.get('RF_Census.CM_Age'));

                    userInputList2.add(memb2);
                }
                if (pListItem.get('selectedProduct')!=null && pListItem.get('selectedProduct')!= '') {
                    plistItem22.put('userInputs', userInputList2);
                    plistItem22.put('selectedProduct', pListItem.get('selectedProduct'));
                    pList2.add(plistItem22);
                }
            }
            


            Map<String,Object> userInputNode = new Map<String,Object> ();
            userInputNode.put('userInputs2',userInputList);
            userInputNode.put('Reason',(String)change.get('Reason'));
            userInputNode.put('SingleReason',(String)change.get('SingleReason'));
            userInputNode.put('SingleReasonToDisplay',(String)change.get('SingleReasonToDisplay'));
            userInputNode.put('EffDate',(String)change.get('EffDate'));
            userInputNode.put('Id',(String)change.get('Id'));
            userInputNode.put('censusId',(String)change.get('censusId'));
            userInputNode.put('caseId',(String)change.get('caseId'));
            userInputNode.put('accountId',(String)change.get('accountId'));
            userInputNode.put('auxSavedMembers',change.get('auxSavedMembers'));
            userInputNode.put('RemovedMembers',change.get('RemovedMembers'));
            userInputNode.put('selectedProducts',change.get('selectedProducts'));
            userInputNode.put('ProductsToUpdate',change.get('ProductsToUpdate'));
            // userInputNode.put('productList',productList);
            userInputNode.put('productList',pList2);

            listUserInputLists.add(userInputNode); 
        }
        outputMap.put('changesForContracts',listUserInputLists);
    }
    private static List<Map<String, Object>> getUserInput(String censusId, String effectiveDate, String contractId, List<vlocity_ins__GroupCensusMember__c> members, Set<String> membersToActivateIds, Set<String> membersToDeactivateIds) {
        List<vlocity_ins__GroupCensusMember__c> censusMember = new List<vlocity_ins__GroupCensusMember__c>();
        if ( contractId != null && contractId != '' ) {
            Map<String, vlocity_ins__GroupCensusMember__c> uniqueMembersMap = new Map<String, vlocity_ins__GroupCensusMember__c>();
            for ( vlocity_ins__GroupCensusMemberPlan__c gcmp : [ SELECT Id, ARC_Active__c, Name, vlocity_ins__GroupCensusMemberId__r.Id, vlocity_ins__GroupCensusMemberId__r.Name, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c, vlocity_ins__GroupCensusMemberId__r.ARC_Smoker__c, vlocity_ins__GroupCensusMemberId__r.ARC_ActiveMember__c, vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressState__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__MemberIdentifier__c, vlocity_ins__GroupCensusMemberId__r.arc_medicalproduct__c, vlocity_ins__GroupCensusMemberId__r.arc_dentalproduct__c, vlocity_ins__GroupCensusMemberId__r.arc_visionproduct__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__censusid__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__birthdate__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__isprimarymember__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__gender__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__isspouse__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__lastname__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__firstname__c, vlocity_ins__GroupCensusMemberId__r.ARC_AgeInSixMonths__c, vlocity_ins__GroupCensusMemberId__r.ARC_DependentRelationship__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c = :contractId AND vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical' ] ) {
                
                uniqueMembersMap.put(gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__MemberIdentifier__c, gcmp.vlocity_ins__GroupCensusMemberId__r);
            }
            
            if ( !members.isEmpty() ) {
                for (vlocity_ins__GroupCensusMember__c member : members) {
                    if ( !membersToActivateIds.isEmpty() ) {
                        if ( membersToActivateIds.contains(member.vlocity_ins__MemberIdentifier__c) ) {
                            uniqueMembersMap.put(member.vlocity_ins__MemberIdentifier__c, member);
                        }
                    }
                    
                    if ( !membersToDeactivateIds.isEmpty() ) {
                        if ( membersToDeactivateIds.contains(member.Id) ) {
                            uniqueMembersMap.remove(member.vlocity_ins__MemberIdentifier__c);
                        }
                    }
                }
            }
            censusMember = uniqueMembersMap.values();
        } else {
            Boolean test = true;
            censusMember = [SELECT Id, Name, vlocity_ins__Email__c, ARC_Smoker__c, ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c ,vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c = :censusId AND ARC_ActiveMember__c = :test];
        }

        Date minBirthdate = null;

        for(vlocity_ins__GroupCensusMember__c member : censusMember){
            Date bd = member.vlocity_ins__birthdate__c;
            if(minBirthdate == null){
                minBirthdate = bd;
            } else if(bd < minBirthdate){
                minBirthdate = bd;
            }
        } 


        vlocity_ins__GroupCensus__c census = [SELECT Id, Name, ARC_MinCensusDOB__c, ARC_CountSuscribers__c, ARC_CountChildren__c, ARC_CountSpouse__c, vlocity_ins__GroupId__c, ARC_PrimaryAccount__c FROM vlocity_ins__GroupCensus__c WHERE Id = :censusId];
        Account censusAccount = [SELECT Id, vlocity_ins__Email__c, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, ARC_Effective_Date__c FROM Account WHERE Id =: census.ARC_PrimaryAccount__c LIMIT 1];
        Contract censusContract;
        if ( contractId != null && contractId != '' ) {
            censusContract = [SELECT Id, RecordTypeId, StartDate FROM Contract WHERE Id = :contractId];
        } else {
            censusContract = [SELECT Id, RecordTypeId, StartDate FROM Contract WHERE vlocity_ins__EnrollmentCensusId__c =: census.Id ORDER BY CreatedDate DESC LIMIT 1];
        }

        
        
        List<Map<String, Object>> userInputList = new List<Map<String, Object>>();

        
            Boolean hasSpouse = false;
            Integer subscribers = censusMember.size();
            Integer countChildren = 0;
            Boolean hasPrimary = false;
            Boolean useSpouseAsPrimary = false;
            Integer olderAge = 0;
            Id olderMemberId;
            Integer extraDeps = 0;



        // aaaaaaa
            for (vlocity_ins__GroupCensusMember__c memb : censusMember) {
                if (memb.vlocity_ins__IsPrimaryMember__c && memb.ARC_DependentRelationship__c==null) {
                    hasPrimary=true;
                    olderAge = calculateAge(memb.vlocity_ins__Birthdate__c, Date.valueOf(effectiveDate).addDays(daysToAdd));
                    olderMemberId = memb.Id;
                }
            }
            // 
            for (vlocity_ins__GroupCensusMember__c memb : censusMember) {
                if (memb.ARC_DependentRelationship__c == 'Child') {
                    countChildren++;
                }
                if (memb.ARC_DependentRelationship__c == 'Spouse') {
                    if (hasPrimary) {
                        hasSpouse=true;
                    }
                }
            }


            


            for (vlocity_ins__GroupCensusMember__c memb : censusMember) {
                if (!hasSpouse && !hasPrimary) {
                    if (calculateAge(memb.vlocity_ins__Birthdate__c, Date.valueOf(effectiveDate).addDays(daysToAdd)) > olderAge){
                        olderAge = calculateAge(memb.vlocity_ins__Birthdate__c, Date.valueOf(effectiveDate).addDays(daysToAdd));
                        olderMemberId = memb.Id;
                    }
                }
            }

            for (vlocity_ins__GroupCensusMember__c memb : censusMember) {
                if (olderMemberId == memb.Id) {   
                    // countChildren--;
                }
            }


            if (countChildren - 3 <= 0) {
                extraDeps = 0;
            }else {
                extraDeps = countChildren - 3;
            }

            
            String coverageAIDD = getCoverageAidd(hasSpouse&&hasPrimary, subscribers, countChildren);
            String coverageSMART = getCoverageSmart(hasSpouse&&hasPrimary, subscribers, countChildren);
        // aaaaaaa
        
        
        
        Decimal Dependants = censusMember.size() - 1;
        for (vlocity_ins__GroupCensusMember__c member : censusMember) {
            Map<String, Object> userInputMap = new Map<String, Object>();
            Map<String, Object> userBirthdate = new Map<String, Object>(); // use?
            Decimal ExtraDependants;
            if (censusMember.size() - 5 < 0){
                ExtraDependants = 0;
            } else{
                ExtraDependants = censusMember.size() - 5;
            }

            
            
            Integer PrimaryAge = -1;
            Integer age = -1;
            if(effectiveDate != null ){
                //PrimaryAge = Integer.valueOf((Date.valueOf(minBirthdate).daysBetween(Date.valueOf(effectiveDate)))/365.2425);
                PrimaryAge = calculateAge( Date.valueOf(minBirthdate), Date.valueOf(effectiveDate).addDays(daysToAdd));
                //age = Integer.valueOf((Date.valueOf(member.vlocity_ins__Birthdate__c).daysBetween(Date.valueOf(effectiveDate)))/365.2425);
                age = calculateAge( Date.valueOf(member.vlocity_ins__Birthdate__c), Date.valueOf(effectiveDate).addDays(daysToAdd));
            }else{
                //PrimaryAge = Integer.valueOf((Date.valueOf(minBirthdate).daysBetween(Date.today()))/365.2425);
                PrimaryAge = calculateAge( Date.valueOf(minBirthdate), Date.today().addDays(daysToAdd));
                //age = Integer.valueOf((Date.valueOf(member.vlocity_ins__Birthdate__c).daysBetween(Date.today()))/365.2425);   
                age = calculateAge( Date.valueOf(member.vlocity_ins__Birthdate__c), Date.today().addDays(daysToAdd));
            }


            String coverage = '';
            if(census.ARC_CountSpouse__c==1 && census.ARC_CountSuscribers__c == 2){
                coverage = 'Primary + Spouse';
        }else if(census.ARC_CountSpouse__c == 0 && census.ARC_CountChildren__c>0){
                coverage = 'Primary + Child';
            }else if(census.ARC_CountSuscribers__c==1){
                coverage = 'Primary';
            }else{
                coverage = 'Family';
            }

            Boolean isMinor = false;
            if(age < 18){
                isMinor = true;
            }

            // String coverageAIDD = '';
            // if(census.ARC_CountSpouse__c==1 && census.ARC_CountSuscribers__c == 2){
            //     coverageAIDD = 'Primary + Spouse';
            // }else if(census.ARC_CountSpouse__c == 0 && census.ARC_CountChildren__c>0){
            //     coverageAIDD = 'Primary + Children';
            // }else if(census.ARC_CountSuscribers__c==1){
            //     coverageAIDD = 'Primary';
            // }else{
            //     coverageAIDD = 'Family';
            // }

            
            userInputMap.put('CensusMemberId', member.Id);
            userInputMap.put('CensusMemberName', member.Name);
            userInputMap.put('isMinor', isMinor);
            userInputMap.put('CensusMemberLastName', member.vlocity_ins__lastname__c);
            userInputMap.put('CensusMemberFirstName', member.vlocity_ins__firstname__c);
            userInputMap.put('CensusMemberRelationship', member.ARC_DependentRelationship__c);
            userInputMap.put('CensusMemberIdentifier', member.vlocity_ins__MemberIdentifier__c);
            userInputMap.put('CensusEmail', censusAccount.vlocity_ins__Email__c);
            userInputMap.put('ContractId', censusContract.Id);
            userInputMap.put('AccountId', censusAccount.Id);
            userInputMap.put('ContractRecType', censusContract.RecordTypeId);
            userInputMap.put('ContractStartDate', censusContract.StartDate);
            userInputMap.put('Email', member.vlocity_ins__Email__c);
            userInputMap.put('Phone', censusAccount.Phone);
            userInputMap.put('Street', censusAccount.BillingStreet);
            userInputMap.put('City', censusAccount.BillingCity);
            userInputMap.put('State', member.ARC_PhysicalAddressState__c);
            userInputMap.put('Zipcode', censusAccount.BillingPostalCode);
            userInputMap.put('EffectiveDate', censusAccount.ARC_Effective_Date__c);
            userInputMap.put('Birthdate', member.vlocity_ins__Birthdate__c);
            userInputMap.put('RF_Census.CRF_Dependants', Dependants);
            userInputMap.put('RF_Census.CRF_ExtraDependants', ExtraDependants);
            userInputMap.put('RF_Census.CRF_PrimaryMemberAge', PrimaryAge);
            userInputMap.put('RF_Census.CM_State', member.ARC_PhysicalAddressState__c);
            userInputMap.put('RF_Census.CM_IsPrimary', member.ARC_DependentRelationship__c == 'Future Primary' ? false : member.vlocity_ins__isprimarymember__c);
            userInputMap.put('contact', member.vlocity_ins__ContactId__c);
            if (member.ARC_DependentRelationship__c=='Spouse' && !member.vlocity_ins__isprimarymember__c) {
                userInputMap.put('RF_Census.CM_IsSpouse', true);
            }else {
                userInputMap.put('RF_Census.CM_IsSpouse', false);
            }
                        userInputMap.put('RF_Census.CM_Smoker', member.ARC_Smoker__c);
            userInputMap.put('RF_Census.CM_Age', age);
            userInputMap.put('RF_Census.CRF_Coverage', coverageSMART);
            userInputMap.put('RF_Census.CRF_CoverageAIDD', coverageAIDD);
    
            userInputList.add(userInputMap);
        }        
        
        return userInputList;
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

    public static void getInputForChooseProducts(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
        List<Object> objList_changesForContracts = (List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('changesForContracts')));
        List<Object> objList_dependants = (List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('dependants')));
        List<Map<String,Object>> changesForContracts = new List<Map<String,Object>>();
        List<Map<String,Object>> dependants = new List<Map<String,Object>>();
        List<Object> membersWithoutPrimary = new List<Object>();
        
        if (inputMap.get('membersWithoutPrimary')!='') {
            membersWithoutPrimary = (List<Object>)inputMap.get('membersWithoutPrimary');
        }

        for (Object itemObj : objList_changesForContracts) {
            Map<String, Object> item = (Map<String, Object>) itemObj;
            changesForContracts.add(item);
        }
        for (Object itemObj : objList_dependants) {
            Map<String, Object> item = (Map<String, Object>) itemObj;
            if (item != null) {
                
                dependants.add(item);
            }
        }
        Map<Date, Map<String, Object>> effectiveDate_change = new Map<Date, Map<String, Object>>();
        Map<String, Object> changeToDisplay = new Map<String, Object>();
        Boolean showRemovedMembers = false;
        Boolean thereIsAncillaryWithoutRemoveMember = false;
        Boolean futurePrimaryExist = false; //true when there is a new member with a relaitonship of "Future Primary"
        Date removeDate;

        List<Object> OBJrejectedMembersIds = inputMap.get('rejectedMemberIds') != null && inputMap.get('rejectedMemberIds') != ''  ? (List<Object>)inputMap.get('rejectedMemberIds') : new List<Object>();
        Set<String> rejectedMembersIds = new Set<String>();
        for (Object item : OBJrejectedMembersIds) {
            rejectedMembersIds.add((String)item);
        }

        for(Map<String, Object> change : changesForContracts){
            if (((String)change.get('SingleReason')).contains('Add Ancillary') && !((String)change.get('Reason')).contains('Remove Member')){
                thereIsAncillaryWithoutRemoveMember = true;
            }
        }

        for(Map<String, Object> change : changesForContracts){
            if (((String)change.get('Reason')).contains('Add Ancillary') && ((String)change.get('Reason')).contains('Remove Member') && thereIsAncillaryWithoutRemoveMember){
                change.put('RemovedMembers', '');
            }
            if (((String)change.get('Reason')).contains('Add Member') || ((String)change.get('Reason')).contains('Add Ancillary Product') || ((String)change.get('Reason')).contains('Add Newborn') || (((String)change.get('Reason')).contains('Remove Member')) || inputMap.get('rejectedMemberIds') != null) {
                effectiveDate_change.put(Date.valueOf((String)change.get('EffDate')),change);
            }
        }

        Date lastEffDate = Date.valueOf((String)changesForContracts[0].get('EffDate'));
        Date lastAddMemberEffDate = Date.valueOf((String)changesForContracts[0].get('EffDate'));
        for (Date effDate : effectiveDate_change.keySet()){ 
            if (effDate > lastAddMemberEffDate && ((((String)((Map<String, Object>)effectiveDate_change.get(effDate)).get('SingleReason')).contains('Add Member') || ((String)((Map<String, Object>)effectiveDate_change.get(effDate)).get('SingleReason')).contains('Add Newborn')) && !((String)((Map<String, Object>)effectiveDate_change.get(effDate)).get('Reason')).contains('Add Ancillary Product'))) {
                lastAddMemberEffDate = effDate; 
            }
            if (effDate > lastEffDate) {
                lastEffDate = effDate;
            }
        }

        changeToDisplay = effectiveDate_change.get(lastEffDate);
        String contractId = (String)inputMap.get('contractId');
        List<vlocity_ins__GroupCensusMember__c> members = new List<vlocity_ins__GroupCensusMember__c>();
        if ( contractId != '' && contractId != null ) {
            members = getGroupCensusMembersFromContract(contractId, rejectedMembersIds);
        } else {
            members = getGroupCensusMembers((String)inputMap.get('CensusId'));
        }
        
        List<Map<String,Object>> changesForContracts2 = new List<Map<String,Object>>();
        changesForContracts2.add(changeToDisplay);
        changesForContracts2.add((Map<String,Object>)effectiveDate_change.get(lastAddMemberEffDate));


        vlocity_ins__GroupCensus__c census = getGroupCensus((String)inputMap.get('CensusId'));
        // List<vlocity_ins__GroupCensusMember__c> membersToAddOrRemove = getMembersToAddOrRemove(changesForContracts,primaryId);

        Account censusAccount = getCensusAccount(census.vlocity_ins__GroupId__c);
        Contract censusContract;
        if ( contractId != '' && contractId != null ) {
            censusContract = getCensusContractFromId(contractId);
        } else {
            censusContract = getCensusContract(censusAccount.Id);
        }

        Map<String,Object> chooseProductsJsonAddAncillary = new Map<String,Object>();
        Map<String,Object> chooseProductsJsonAddMember = new Map<String,Object>();
        Map<String,Set<String>> contract_membersToDeactivate = getMemberToDeactivateIds(changesForContracts2);
        Map<String,Set<String>> contract_membersToActivate = getMemberToActivateIds(changesForContracts2);
        // Add members to activate to members
        Set<String> membersToActivate = new Set<String>();
        if ( !contract_membersToActivate.isEmpty() ) {
            for ( Set<String> ids : contract_membersToActivate.values() ) {
                membersToActivate.addAll(ids);
            }
        }
        if ( !membersToActivate.isEmpty() ) {
            members.addAll([ SELECT Id, Name, ARC_Relationship__c, vlocity_ins__Email__c, vlocity_ins__RelatedCensusMemberId__c,ARC_Smoker__c, ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c ,vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__MemberIdentifier__c IN :membersToActivate ]);
        }
        
        // Remove members to deactivate from members
        Set<String> membersToDeactivate = new Set<String>();
        if ( !contract_membersToDeactivate.isEmpty() ) {
            for ( Set<String> ids : contract_membersToDeactivate.values() ) {
                membersToDeactivate.addAll(ids);
            }
        }
        if ( !membersToDeactivate.isEmpty() ) {
            for ( Integer i = members.size() - 1; i >= 0; i-- ) {
                if ( membersToDeactivate.contains(members[i].Id) ) {
                    members.remove(i);
                }
            }
        }

        String primaryId = '';
        String primaryEmail = '';
        if (inputMap.get('primaryId') != '') {
            primaryId = (String)inputMap.get('primaryId');
        }
        if (inputMap.get('primaryEmail') != '') {
            primaryEmail = (String)inputMap.get('primaryEmail');
        }
        String tempPrimaryId;
        String tempPrimaryEmail;
        Date maxBirthdate;
        Boolean primaryFound = false;
        Boolean preventProductIds = false;
        for ( vlocity_ins__GroupCensusMember__c m : members ) {
            if ( m.vlocity_ins__isprimarymember__c ) {
                primaryFound = true;
                break;
            } else {
                if ( maxBirthdate == null || m.vlocity_ins__birthdate__c < maxBirthdate ) {
                    if ( !m.vlocity_ins__IsPrimaryMember__c && !m.vlocity_ins__IsSpouse__c ) {
                        preventProductIds = true;
                    } else {
                        preventProductIds = false;
                    }
                    maxBirthdate = m.vlocity_ins__birthdate__c;
                    tempPrimaryId = m.Id;
                    tempPrimaryEmail = m.vlocity_ins__Email__c;
                }
            }
        }
        if ( !primaryFound ) {
            if ( primaryId == '' ) {
                primaryId = tempPrimaryId;
            }
            if ( primaryEmail == '' ) {
                primaryEmail = tempPrimaryEmail;
            }
        }

        
        for (Map<String,Object> change : changesForContracts2) {
            if (change != null) {
                
                List<Map<String,Object>> member = new List<Map<String,Object>>();
                for (vlocity_ins__GroupCensusMember__c mem : members) {
                    if (mem.ARC_DependentRelationship__c =='Future Primary') {
                        futurePrimaryExist = true;
                    }
                }
                for (vlocity_ins__GroupCensusMember__c mem : members) {
                    // If new primary is a child then no programs should be shown
                    
                    if(primaryId!='' && !futurePrimaryExist ){
                        if(mem.Id == primaryId ){
                            mem.vlocity_ins__IsPrimaryMember__c = true;
                            mem.vlocity_ins__IsSpouse__c = false;
                            mem.vlocity_ins__Email__c = primaryEmail;
                            mem.vlocity_ins__RelatedCensusMemberId__c = null;
                        }else{
                            mem.vlocity_ins__RelatedCensusMemberId__c = primaryId;
                        }
                    }

                    
                    if ( !contract_membersToDeactivate.get((String)change.get('Id')).contains(mem.Id)) {
                        Map<String,Object> memItem = new Map<String, Object>();
                        memItem.put('CensusMemberId',mem.Id);
                        memItem.put('CensusMemberName',mem.Name);
                        memItem.put('RF_Census.CM_IsPrimary',mem.vlocity_ins__IsPrimaryMember__c);
                        memItem.put('RF_Census.CM_IsSpouse',mem.vlocity_ins__IsSpouse__c);
                        
                        if (mem.vlocity_ins__RelatedCensusMemberId__c == null) {
                            
                            memItem.put('CensusMemberRelationship',null);//NO
                        } else {
                            
                            memItem.put('CensusMemberRelationship',mem.ARC_DependentRelationship__c);//SI
                        }
                        if ( !mem.vlocity_ins__IsPrimaryMember__c && !mem.vlocity_ins__IsSpouse__c ) {
                            memItem.put('CensusMemberRelationship',mem.ARC_DependentRelationship__c);
                        }
                        if ( !preventProductIds ) {
                            for (Map<String,Object> depend : dependants) {
                                if ( depend != null ) {
                                    if ( mem.Id == (String)depend.get('Id') ) {
                                        if (depend.get('parentSMART') != null) {
                                            memItem.put('parentSMART',depend.get('parentSMART'));
                                        }
                                        if (depend.get('parentAIDD') != null) {
                                            memItem.put('parentAIDD',depend.get('parentAIDD'));
                                        }
                                        if ( !((String)change.get('Reason')).contains('Add Ancillary Product') || ( ( inputMap.get('showAddAncillaryChooseProductsKeepSMART') != null && inputMap.get('showAddAncillaryChooseProductsKeepSMART') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepSMART') ) || ( inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != null && inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepAIDD') ) ) ) {
                                            if ( membersWithoutPrimary.contains(mem.Id) || (inputMap.get('rejectedMemberIds')!= null && !( ( inputMap.get('showAddAncillaryChooseProductsKeepSMART') != null && inputMap.get('showAddAncillaryChooseProductsKeepSMART') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepSMART') ) || ( inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != null && inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepAIDD') ) ) ) ) {
                                                memItem.put('productIds', new List<Object>());
                                            } else {
                                                if ( ( inputMap.get('showAddAncillaryChooseProductsKeepSMART') != null && inputMap.get('showAddAncillaryChooseProductsKeepSMART') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepSMART') ) || ( inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != null && inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepAIDD') ) ) {
                                                    List<Object> keepedProducts = new List<Object>();
                                                    for ( Object prod : (List<Object>)((Map<String,Object>)((List<Object>)inputMap.get('changesForContracts'))[0]).get('ProductsToUpdate') ) {
                                                        Map<String, Object> productMap = (Map<String,Object>)prod;
                                                        String keepSmartCondition = ( inputMap.get('showAddAncillaryChooseProductsKeepSMART') != null && inputMap.get('showAddAncillaryChooseProductsKeepSMART') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepSMART') ) ? 'SMART' : '';
                                                        String keepAiddCondition = ( inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != null && inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepAIDD') ) ? 'AIDD' : '';
                                                        if ( (String)productMap.get('Type__c') == 'Medical' || ( (String)productMap.get('SubType__c') == keepSmartCondition || (String)productMap.get('SubType__c') == keepAiddCondition ) ) {
                                                            keepedProducts.add((String)productMap.get('Id'));
                                                        }
                                                    }
                                                    List<Object> productIds = new List<Object>();
                                                    for ( Object prodId : (List<Object>)depend.get('productsIds') ) {
                                                        if ( keepedProducts.contains(prodId) ) {
                                                            productIds.add(prodId);
                                                        }
                                                    }
                                                    memItem.put('productIds', productIds);
                                                } else {
                                                    memItem.put('productIds',depend.get('productsIds'));
                                                }
                                                
                                            }
                                        }
                                        if(!member.contains(memItem)){
                                            
                                            
                                            member.add(memItem);
                                        }

                                    }
                                }
                            }
                        } else {
                            
                            if(!member.contains(memItem)){
                                
                                
                                member.add(memItem);
                            }
                        }
                        if ( contract_membersToActivate.get((String)change.get('Id')).contains(mem.vlocity_ins__MemberIdentifier__c) ) {
                            

                            if(!member.contains(memItem)){
                                
                                member.add(memItem);
                            }
                        }

                    }  
                }
                

                
                
                if(futurePrimaryExist){
                    member = getFuturePrimaryUserInputs(member);
                }
                
                
                
                List<Object> finalProducts = (List<Object>)change.get('ProductsToUpdate');

                if (change.get('selectedProducts') != null && change.get('selectedProducts') != '') {
                    finalProducts = mergeOldAndNewProducts((List<Object>)change.get('selectedProducts'),(List<Object>)change.get('ProductsToUpdate'));
                }
                List<Object> smartProducts = new List<Object>();
                List<Object> aiddProducts = new List<Object>();
                List<Object> coreProducts = new List<Object>();
                for (Object prod : finalProducts) {
                    if ((String)((Map<String,Object>)prod).get('Type__c') == 'Medical') {
                        coreProducts.add(prod);
                    }else if((String)((Map<String,Object>)prod).get('SubType__c') == 'AIDD'){
                        aiddProducts.add(prod);
                    }else if((String)((Map<String,Object>)prod).get('SubType__c') == 'SMART'){
                        smartProducts.add(prod);
                    }
                }
                
                if (((String)change.get('Reason')).contains('Add Ancillary Product') && !( ( inputMap.get('showAddAncillaryChooseProductsKeepSMART') != null && inputMap.get('showAddAncillaryChooseProductsKeepSMART') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepSMART') ) || ( inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != null && inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != '' && (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepAIDD') ) ) ) {
                    chooseProductsJsonAddAncillary.put('member',member);
                    chooseProductsJsonAddAncillary.put('coreProducts',coreProducts);
                    chooseProductsJsonAddAncillary.put('smartProducts',smartProducts);
                    chooseProductsJsonAddAncillary.put('aiddProducts',aiddProducts);
                }else{
                    chooseProductsJsonAddMember.put('member',member);
                    chooseProductsJsonAddMember.put('coreProducts',coreProducts);
                    List<Object> filteredSmart = new List<Object>();
                    Set<String> smartProdIds = new Set<String>();
                    for (Object prod : smartProducts) {
                        if (!smartProdIds.contains((String)((Map<String,Object>)prod).get('Id'))) {
                            filteredSmart.add(prod);
                            smartProdIds.add((String)((Map<String,Object>)prod).get('Id'));
                        }
                    }
                    chooseProductsJsonAddMember.put('smartProducts',filteredSmart);
                    chooseProductsJsonAddMember.put('aiddProducts',aiddProducts);
                }
            }

        }

        //remove products from dependents that have no parent with those products
        
        if(((Boolean)inputMap.get('removedParentWithDependents') == true && !((String)changesForContracts[0].get('Reason')).contains('Add Ancillary Product'))){

            List<List<Object>> parentProducts = new List<List<Object>>();

            //Populate list of parent Products
            
            for(Object objectMember : (List<Object>) chooseProductsJsonAddMember.get('member')){

                Map<String, Object> member = (Map<String, Object>)objectMember;
                
                Boolean isPrimary = Boolean.valueOf(member.get('RF_Census.CM_IsPrimary'));
                Boolean isSpouse = Boolean.valueOf(member.get('RF_Census.CM_IsSpouse'));
                String memberId = String.valueOf(member.get('TXT_CensusMemberId'));
                List<Object> productList = (List<Object>) member.get('productIds');
                

                if ( ( isPrimary == true || isSpouse == true ) && productList != null && productList.size() > 1 ) {
                    //Add productIds of the parent into parentProducts list to later compare with dependents
                    parentProducts.add(productList);
                }
            }

            //Compare if dependents have products that are not included in parentProducts list to know if we need to remove them
            for(Object objectMember : (List<Object>) chooseProductsJsonAddMember.get('member')){

                Map<String, Object> member = (Map<String, Object>)objectMember;
                
                Boolean isPrimary = Boolean.valueOf(member.get('RF_Census.CM_IsPrimary'));
                Boolean isSpouse = Boolean.valueOf(member.get('RF_Census.CM_IsSpouse'));
                String memberId = String.valueOf(member.get('TXT_CensusMemberId'));
                List<Object> productList = (List<Object>) member.get('productIds');
                

                if ( isPrimary == false && isSpouse == false && productList != null && parentProducts != null && !parentProducts.contains(productList) && productList.size() > 1 ) {
                    
                    member.remove('productIds');
                }
            }

            

        }

        Boolean AddMemberHasAncillary = false;

        if (chooseProductsJsonAddMember.get('member')!= null) {
            if (((List<Object>) chooseProductsJsonAddMember.get('smartProducts')).size() > 0) {
                AddMemberHasAncillary = true;
            }
        }

        outputMap.put('addMemberHasAncillary',AddMemberHasAncillary);
        outputMap.put('chooseProductsJsonAddMember',chooseProductsJsonAddMember);  
        outputMap.put('chooseProductsJsonAddAncillary',chooseProductsJsonAddAncillary);
    }

    public static List<vlocity_ins__GroupCensusMember__c> getGroupCensusMembers(String CensusId) {
        return [SELECT Id, Name, ARC_Relationship__c, vlocity_ins__Email__c, vlocity_ins__RelatedCensusMemberId__c,ARC_Smoker__c, ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c ,vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c = :CensusId];
    }
    public static List<vlocity_ins__GroupCensusMember__c> getGroupCensusMembersFromContract(String contractId, Set<String> rejectedMembersIds) {
        Map<Id, vlocity_ins__GroupCensusMember__c> uniqueMembersMap = new Map<Id, vlocity_ins__GroupCensusMember__c>();
        for ( vlocity_ins__GroupCensusMemberPlan__c gcmp : [ SELECT Id, vlocity_ins__GroupCensusMemberId__r.Id, vlocity_ins__GroupCensusMemberId__r.Name, vlocity_ins__GroupCensusMemberId__r.ARC_Relationship__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__RelatedCensusMemberId__c, vlocity_ins__GroupCensusMemberId__r.ARC_Smoker__c, vlocity_ins__GroupCensusMemberId__r.ARC_ActiveMember__c, vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressState__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__MemberIdentifier__c, vlocity_ins__GroupCensusMemberId__r.arc_medicalproduct__c, vlocity_ins__GroupCensusMemberId__r.arc_dentalproduct__c, vlocity_ins__GroupCensusMemberId__r.arc_visionproduct__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__censusid__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__birthdate__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__isprimarymember__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__gender__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__isspouse__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__lastname__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__firstname__c, vlocity_ins__GroupCensusMemberId__r.ARC_AgeInSixMonths__c, vlocity_ins__GroupCensusMemberId__r.ARC_DependentRelationship__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c = :contractId ] ) {
            if (rejectedMembersIds!= null) {
                if (!rejectedMembersIds.contains(gcmp.vlocity_ins__GroupCensusMemberId__c)) {
                    uniqueMembersMap.put(gcmp.vlocity_ins__GroupCensusMemberId__c, gcmp.vlocity_ins__GroupCensusMemberId__r);
                }
            }else{
                uniqueMembersMap.put(gcmp.vlocity_ins__GroupCensusMemberId__c, gcmp.vlocity_ins__GroupCensusMemberId__r);
            }


            

        }
        
        return uniqueMembersMap.values();
    }   
    public static List<vlocity_ins__GroupCensusMember__c> getMembersToAddOrRemove(List<Map<String, Object>> changesForContracts, String primaryId){

        Map<String,Set<String>> contract_membersToDeactivate =getMemberToDeactivateIds(changesForContracts);
        Map<String,Set<String>> contract_membersToActivate = getMemberToActivateIds(changesForContracts);
        Set<String> membersToActivateDeactivateIds = new Set<String>();
        for (String contractId : contract_membersToDeactivate.keySet()) {
            for (String mId : contract_membersToDeactivate.get(contractId)) {
                membersToActivateDeactivateIds.add(mId);
            }
        }
        for (String contractId : contract_membersToActivate.keySet()) {
            for (String mId : contract_membersToActivate.get(contractId)) {
                membersToActivateDeactivateIds.add(mId);
            }
        }
        

        return [SELECT Id, Name, vlocity_ins__Email__c, ARC_Smoker__c, ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c ,vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__MemberIdentifier__c IN :membersToActivateDeactivateIds OR Id = :primaryId];
    }
    public static Map<String,Set<String>> getMemberToActivateIds(List<Map<String, Object>> changesForContracts) { 

        Map<String,Set<String>> contract_membersToActivate = new Map<String,Set<String>>();
        for(Map<String, Object> change : changesForContracts){
            List<Object> objList_auxSavedMembers = new List<Object>();
            List<Map<String,Object>> auxSavedMembers = new List<Map<String,Object>>();
            if (change != null) {
                if(change.get('auxSavedMembers') != '' && change.get('auxSavedMembers') != null){
                    objList_auxSavedMembers = (List<Object>)change.get('auxSavedMembers');
                    for (Object itemObj : objList_auxSavedMembers) {
                        Map<String, Object> item = (Map<String, Object>) itemObj;
                        auxSavedMembers.add(item);
                    }
                }
                Set<String> membersToActivateIds = new Set<String>();
                for (Map<String, Object> member : auxSavedMembers) {
                    if((Boolean)member.get('isNew')==true){
                        membersToActivateIds.add((String)member.get('vlocity_ins__MemberIdentifier__c'));
                    }
                }
                contract_membersToActivate.put((String)change.get('Id'),membersToActivateIds);
            }
            
        }
        return contract_membersToActivate;
    }
    public static Map<String,Set<String>> getMemberToDeactivateIds(List<Map<String, Object>> changesForContracts) { 
        Map<String,Set<String>> contract_membersToDeactivate = new Map<String,Set<String>>();
        for(Map<String, Object> change : changesForContracts){
            List<Object> objList_RemovedMembers = new List<Object>();
            List<Map<String,Object>> RemovedMembers = new List<Map<String,Object>>();
            if (change != null ) {

                if( change.get('RemovedMembers') != null){
    
                    if( change.get('RemovedMembers') != ''){
    
                        objList_RemovedMembers = (List<Object>)change.get('RemovedMembers');
                        for (Object itemObj : objList_RemovedMembers) {
                            Map<String, Object> item = (Map<String, Object>) itemObj;
                            RemovedMembers.add(item);
                        }
                    }
                }
                Set<String> membersToDeactivateIds = new Set<String>();
                for (Map<String, Object> member : RemovedMembers) {
                    if ((Boolean)member.get('CHK_Delete')==true) {
                        membersToDeactivateIds.add((String)member.get('TXT_CensusMemberId'));
                    }
                }
    
                contract_membersToDeactivate.put((String)change.get('Id'),membersToDeactivateIds);
            }

        }
        return contract_membersToDeactivate;
    }
    public static vlocity_ins__GroupCensus__c getGroupCensus(String CensusId){
        return [SELECT Id, Name, ARC_MinCensusDOB__c, ARC_CountSuscribers__c, ARC_CountChildren__c, ARC_CountSpouse__c, vlocity_ins__GroupId__c, ARC_PrimaryAccount__c FROM vlocity_ins__GroupCensus__c WHERE Id = :CensusId LIMIT 1];
    }
    public static Account getCensusAccount(String AccountId){
        return [SELECT Id, vlocity_ins__Email__c, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, ARC_Effective_Date__c FROM Account WHERE Id = :AccountId LIMIT 1];
    }
    public static Contract getCensusContract(String AccountId){
        return [SELECT Id, RecordTypeId, StartDate FROM Contract WHERE AccountId = :AccountId ORDER BY CreatedDate DESC LIMIT 1];
    }
    public static Contract getCensusContractFromId(String contractId){
        return [SELECT Id, RecordTypeId, StartDate FROM Contract WHERE Id = :contractId];
    }
    public static List<Object> mergeOldAndNewProducts(List<Object> selectedProducts, List<Object> ProductsToUpdate){
        List<Object> finalProducts = new List<Object>();
        List<Object> smartProducts = new List<Object>();
        List<Object> aiddProducts = new List<Object>();
        List<Object> coreProducts = new List<Object>();
        if(selectedProducts!=null){
            for (Object prod : selectedProducts) {
                if ((String)((Map<String,Object>)prod).get('Type__c') == 'Ancillary') {
                    if ((String)((Map<String,Object>)prod).get('SubType__c') == 'SMART') {
                        smartProducts.add(prod);
                    }
                    if ((String)((Map<String,Object>)prod).get('SubType__c') == 'AIDD') {
                        aiddProducts.add(prod);
                    }
                }
                if ((String)((Map<String,Object>)prod).get('Type__c') == 'Medical') {
                    coreProducts.add(prod);
                }
            }
        }
        if (coreProducts.size()==0) {
            for (Object prod : ProductsToUpdate) {
                if ((String)((Map<String,Object>)prod).get('Type__c') == 'Medical') {
                    coreProducts.add(prod);
                }
            }
        }
        if (smartProducts.size()==0) {
            for (Object prod : ProductsToUpdate) {
                if ((String)((Map<String,Object>)prod).get('SubType__c') == 'SMART') {
                    smartProducts.add(prod);
                }
                if ((String)((Map<String,Object>)prod).get('SubType__c') == 'AIDD') {
                    aiddProducts.add(prod);
                }
            }
        }
        finalProducts.addAll(coreProducts);
        finalProducts.addAll(aiddProducts);
        finalProducts.addAll(smartProducts);
        return finalProducts;
    }
    public static Map<String, Object> generateUserInputForMember(vlocity_ins__GroupCensusMember__c member, vlocity_ins__GroupCensus__c census,Account censusAccount, Contract censusContract, String effectiveDate, Integer ExtraDependants, Integer PrimaryMemberAge){
        Map<String, Object> userInputMap = new Map<String, Object>();
        
        Decimal Dependants = census.ARC_CountSuscribers__c - 1;
        Integer PrimaryAge = -1;
        Integer age = -1;
        String coverage = '';
        String coverageAIDD = '';
        Boolean isMinor = false;

        if(effectiveDate != null ){
            age = calculateAge( Date.valueOf(member.vlocity_ins__Birthdate__c), Date.valueOf(effectiveDate).addDays(daysToAdd));
        }else{
            age = calculateAge( Date.valueOf(member.vlocity_ins__Birthdate__c), Date.today().addDays(daysToAdd));
        }

        if(census.ARC_CountSpouse__c==1 && census.ARC_CountSuscribers__c == 2){
            coverage = 'Primary + Spouse';
        }else if(census.ARC_CountSpouse__c == 0 && census.ARC_CountChildren__c>0){
            coverage = 'Primary + Child';
        }else if(census.ARC_CountSuscribers__c==1){
            coverage = 'Primary';
        }else{
            coverage = 'Family';
        }

        if(age < 18){
            isMinor = true;
        }

        if(census.ARC_CountSpouse__c==1 && census.ARC_CountSuscribers__c == 2){
            coverageAIDD = 'Primary + Spouse';
        }else if(census.ARC_CountSpouse__c == 0 && census.ARC_CountChildren__c>0){
            coverageAIDD = 'Primary + Children';
        }else if(census.ARC_CountSuscribers__c==1){
            coverageAIDD = 'Primary';
        }else{
            coverageAIDD = 'Family';
        }

        
        userInputMap.put('CensusMemberId', member.Id);
        userInputMap.put('CensusMemberName', member.Name);
        userInputMap.put('isMinor', isMinor);
        userInputMap.put('CensusMemberLastName', member.vlocity_ins__lastname__c);
        userInputMap.put('FirstName', member.vlocity_ins__lastname__c);
        userInputMap.put('CensusMemberFirstName', member.vlocity_ins__firstname__c);
        userInputMap.put('LastName', member.vlocity_ins__firstname__c);
        userInputMap.put('CensusMemberRelationship', member.ARC_DependentRelationship__c);
        userInputMap.put('CensusMemberIdentifier', member.vlocity_ins__MemberIdentifier__c);
        userInputMap.put('CensusEmail', censusAccount.vlocity_ins__Email__c);
        // userInputMap.put('ContractId', (String)change.get('Id'));
        userInputMap.put('AccountId', censusAccount.Id);
        userInputMap.put('ContractRecType', censusContract.RecordTypeId);
        // userInputMap.put('ContractStartDate', (String)change.get('EffDate'));
        userInputMap.put('Email', member.vlocity_ins__Email__c);
        userInputMap.put('Phone', censusAccount.Phone);
        userInputMap.put('Street', censusAccount.BillingStreet);
        userInputMap.put('City', censusAccount.BillingCity);
        userInputMap.put('State', member.ARC_PhysicalAddressState__c);
        userInputMap.put('Zipcode', censusAccount.BillingPostalCode);
        userInputMap.put('EffectiveDate', censusAccount.ARC_Effective_Date__c);
        userInputMap.put('Birthdate', member.vlocity_ins__Birthdate__c);
        userInputMap.put('RF_Census.CRF_Dependants', Dependants);
        userInputMap.put('RF_Census.CRF_ExtraDependants', ExtraDependants);
        userInputMap.put('RF_Census.CRF_PrimaryMemberAge', PrimaryMemberAge);
        userInputMap.put('RF_Census.CM_State', member.ARC_PhysicalAddressState__c);
        userInputMap.put('RF_Census.CM_IsPrimary', member.vlocity_ins__isprimarymember__c);
        userInputMap.put('contact', member.vlocity_ins__ContactId__c);

        // if (member.ARC_DependentRelationship__c=='Spouse' && !member.vlocity_ins__isprimarymember__c) {
            userInputMap.put('RF_Census.CM_IsSpouse', member.vlocity_ins__IsSpouse__c);
        // }else {
        //     userInputMap.put('RF_Census.CM_IsSpouse', false);
        // }        
        userInputMap.put('RF_Census.CM_Smoker', member.ARC_Smoker__c);
        userInputMap.put('RF_Census.CM_Age', age);
        // userInputMap.put('RF_Census.CRF_Coverage', coverage);
        // userInputMap.put('RF_Census.CRF_CoverageAIDD', coverageAIDD);

        return userInputMap;
    }

    public static Map<String,Object> generateProductListItem(Map<String,Object> chooseProductsOutputItem, List<Object> userInputList){
        Map<String,Object> productListItem = new Map<String,Object>();
        List<Object> memberList = new List<Object>();
        Boolean memberListHasPrimary = false;
        String olderBdate;
        String olderBdateId;
        for (Object chooseProdMemb : (List<Object>)(chooseProductsOutputItem).get('userInputs')) {
            for (Object memb : userInputList) {
                
                
                if ((String)((Map<String,Object>)chooseProdMemb).get('CensusMemberId') == (String)((Map<String,Object>)memb).get('CensusMemberId')) {
                    if (olderBdate == null) {
                        olderBdate = (String)((Map<String,Object>)chooseProdMemb).get('Birthdate');
                        olderBdateId = (String)((Map<String,Object>)chooseProdMemb).get('CensusMemberId');
                    }else{
                        if (Date.valueOf((String)((Map<String,Object>)chooseProdMemb).get('Birthdate'))<Date.valueOf(olderBdate)) {
                            olderBdate = (String)((Map<String,Object>)chooseProdMemb).get('Birthdate');
                            olderBdateId = (String)((Map<String,Object>)chooseProdMemb).get('CensusMemberId');

                        }
                    }
                    memberList.add(memb);
                    if ((Boolean)((Map<String,Object>)memb).get('RF_Census.CM_IsPrimary')) {
                        memberListHasPrimary = true;
                    }
                }
            }
        }

        for (Object memberListItem : memberList) {
            if (!memberListHasPrimary && (String)((Map<String,Object>)memberListItem).get('CensusMemberId')==olderBdateId) {
                // ((Map<String,Object>)memberListItem).put('RF_Census.CM_IsPrimary', true);
            }
        }

        if (memberList.size()>0 && chooseProductsOutputItem.get('selectedProduct')!= null) {
            productListItem.put('selectedProduct',chooseProductsOutputItem.get('selectedProduct'));
            productListItem.put('userInputs',memberList);
            // productIds.add(productId);
            return productListItem;
        }else {
            return null;
        }
    }

    public static String getCoverageSmart(Boolean hasSpouse, Integer suscribers, integer countChildren){
        String coverage = '';
        if(hasSpouse && suscribers == 2){
            coverage = 'Primary + Spouse';
        }else if(!hasSpouse && countChildren>0){
            coverage = 'Primary + Child';
        }else if(suscribers==1){
            coverage = 'Primary';
        }else{
            coverage = 'Family';
        }
        return coverage;
    }

    public static String getCoverageAidd(Boolean hasSpouse, Integer suscribers, integer countChildren){
        String coverageAIDD = '';
        if(hasSpouse && suscribers == 2){
            coverageAIDD = 'Primary + Spouse';
        }else if(!hasSpouse && countChildren>0){
            coverageAIDD = 'Primary + Children';
        }else if(suscribers==1){
            coverageAIDD = 'Primary';
        }else{
            coverageAIDD = 'Family';
        }
        return coverageAIDD;
    }

    //Only when there is a new member with "Future Primary" relationship, transfoms "Future Primary" to "Primary" and "Primary" to "Child"
    public static List<Map<String,Object>> getFuturePrimaryUserInputs(List<Map<String,Object>> members){
        for (Map<String,Object> member : members) {
            if ((String)member.get('CensusMemberRelationship') == 'Future Primary') {
                member.put('CensusMemberRelationship',null);
                member.put('RF_Census.CM_IsPrimary',true);
            }else{
                if ((String)member.get('CensusMemberRelationship') == null) {
                    member.put('CensusMemberRelationship','Child');
                    member.put('RF_Census.CM_IsPrimary',false);
                }
                member.put('productIds', null);
            }
        }
        return members;
    }



}