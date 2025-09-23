global without sharing class ARC_ManyEffDatesProgramChangeAncillary implements vlocity_ins.VlocityOpenInterface{
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'changesList') {
            changesList(inputMap, outputMap,options);
        }        
        if (methodName == 'listToStringFormat') {
            listToStringFormat(inputMap, outputMap,options);
        }        
        return true;
    }

    public static void listToStringFormat(Map<String,Object> inputMap, Map<String,Object> outputMap,Map<String,Object> options){

        List<Object> reqs = (List<Object>) inputMap.get('inputList');
        List<string> lsstr= new List<string> ();

        for(Object a: reqs){
            lsstr.add(String.valueOf(a));
        }

        outputMap.put('stringList','stringList');
    }

    public static void changesList(Map<String,Object> inputMap, Map<String,Object> outputMap,Map<String,Object> options) {

        Map<String, Object> selChangeReason = new Map<String, Object>();
        Map<String,Object> originalValues = new Map<String,Object>();
        Map<String,List<Object>> effDate_Changes = new Map<String,List<Object>>();
        Map<Id, String> memberAncillaryDependence = getMemberAncillaryDependence((String)inputMap.get('OldContractId'));

        List<String> reasons = new List<String>();
        List<String> listEffDates = new List<String>();
        List<Map<String,Object>> changesList = new List<Map<String,Object>>();
        List<Map<String,Object>> changesForContractsMergedSameEffDate = new List<Map<String,Object>>();
        List<Map<String,Object>> changesForContracts = new List<Map<String,Object>>();
        List<Map<String,Object>> auxSavedMembers = new List<Map<String,Object>>();
        List<Map<String,Object>> existingMembers = new List<Map<String,Object>>();
        List<Object> changesForContractsObj = new List<Object>();
        List<Object> changesForContractsMergedSameEffDateObj = new List<Object>();
        List<Object> obj_existingMembers = new List<Object>();
        List<String> membersWithoutPrimary = new List<String>();

        Set<String> effDates = new Set<String>();
        Set<String> setReasons = new Set<String>();

        Boolean showAddAncillaryChooseProducts = false;
        Boolean showAddMemberChooseProducts = false;
        Boolean removedParentWithDependents = false;
        Boolean showAddAncillaryChooseProductsKeepSMART = false;
        Boolean showAddAncillaryChooseProductsKeepAIDD = false;
        
        if(inputMap.get('existingMembers') != null && inputMap.get('existingMembers') != ''){
            try {
                obj_existingMembers = (List<Object>)inputMap.get('existingMembers');
            } catch (Exception e) {
                obj_existingMembers.add(inputMap.get('existingMembers'));
            }
            for (Object existingMember : obj_existingMembers) {
                existingMembers.add((Map<String, Object>)existingMember);
            }
        }

        if(JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_AddMember_EffDate')))!=null && JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_AddMember_EffDate')))!=''){
            Map<String,Object> addMemberChanges = new Map<String,Object>();
            addMemberChanges.put('EffDate',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_AddMember_EffDate'))));
            addMemberChanges.put('Reason',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_AddMember_Reason'))));
            addMemberChanges.put('auxSavedMembers',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_AddMember_auxSavedMembers'))));
            changesList.add(addMemberChanges);
        }
        
        if(JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_ProgramUpdate_EffDate')))!=null && JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_ProgramUpdate_EffDate')))!='' ){
            Map<String,Object> programUpdateChanges = new Map<String,Object>();
            programUpdateChanges.put('EffDate',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_ProgramUpdate_EffDate'))));
            programUpdateChanges.put('Reason',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_ProgramUpdate_Reason'))));
            programUpdateChanges.put('selectedProducts',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_ProgramUpdate_selectedProducts'))));
            programUpdateChanges.put('ProductsToUpdate',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_ProgramUpdate_ProductsToUpdate'))));
            changesList.add(programUpdateChanges);
        }
        
        if(JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_RemoveMember_EffDate')))!=null && JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_RemoveMember_EffDate'))) != ''){
            Map<String,Object> removedMemberChanges = new Map<String,Object>();

            removedMemberChanges.put('EffDate',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_RemoveMember_EffDate'))));
            removedMemberChanges.put('Reason',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_RemoveMember_Reason'))));
            removedMemberChanges.put('RemovedMembers',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_RemoveMember_RemovedMembers'))));
            changesList.add(removedMemberChanges);
        }

        if(JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_AddAncillary_EffDate')))!=null && JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_AddAncillary_EffDate')))!='' ){
            Map<String,Object> addAncillaryChanges = new Map<String,Object>();
            List<Map<String,Object>> ancillary_selectedProducts = new List<Map<String,Object>>();
            List<Object> selectedProducts = new List<Object>();
            Object medicalProduct;

            addAncillaryChanges.put('EffDate',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_AddAncillary_EffDate'))));
            addAncillaryChanges.put('Reason',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_AddAncillary_Reason'))));
            selectedProducts=(List<Object>)JSON.deserializeUntyped((String)JSON.serialize(inputMap.get('Changes_AddAncillary_selectedProducts')));

            for (Object prod : selectedProducts) {
                Map<String,Object> prodObj = (Map<String,Object>)prod;
                if ((String)prodObj.get('Type__c')=='Ancillary') {
                    ancillary_selectedProducts.add(prodObj);
                }
                if ((String)prodObj.get('Type__c')=='Medical') {
                    medicalProduct=prod;
                }
            }
            addAncillaryChanges.put('selectedProducts',ancillary_selectedProducts);
            List<Object> productsToUpdate = (List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_AddAncillary_ProductsToUpdate')));
            for (Object prodObj : productsToUpdate) {
                Map<String,Object> prod = (Map<String,Object>)prodObj;
                if ((String)prod.get('Type__c')=='Medical') {
                    prodObj = medicalProduct;
                }
            }
            addAncillaryChanges.put('ProductsToUpdate',productsToUpdate);

            changesList.add(addAncillaryChanges);
        }

        if(JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_RemoveAncillary_EffDate')))!=null && JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_RemoveAncillary_EffDate')))!='' ){
            Map<String,Object> removeAncillaryChanges = new Map<String,Object>();

            removeAncillaryChanges.put('EffDate',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_RemoveAncillary_EffDate'))));
            removeAncillaryChanges.put('Reason',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_RemoveAncillary_Reason'))));
            changesList.add(removeAncillaryChanges);
        }

        originalValues.put('ProductsToUpdate',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_OriginalValues_ProductsToUpdate'))));

        for (Integer i = 0; i < changesList.size(); i++) {
            if(changesList[i].get('EffDate')!=null){
                
                effDates.add((String)changesList[i].get('EffDate'));
    
                for (Integer j = i+1; j < changesList.size(); j++) {
                    if(Date.valueOf(String.valueOf(changesList[i].get('EffDate')))>=Date.valueOf(String.valueOf(changesList[j].get('EffDate')))){
                        Map<String,Object> aux = changesList[i];
                        changesList[i] = changesList[j];
                        changesList[j] = aux;
                    }
                }
            }
        }

        listEffDates.addAll(effDates);
        

        for (Integer i = 0; i < changesList.size(); i++) {
            Map<String,Object> change = originalValues;
            auxSavedMembers = new List<Map<String,Object>>();

            List<String> listReasons = new List<String>();
            List<Object> listOfChangesEffDate = new List<Object>();

            if(i>0){
                change = changesForContracts[i-1];
            }

            change.put('SingleReason',((String)changesList[i].get('Reason')));
            setReasons.add((String)changesList[i].get('Reason'));
            listReasons.addAll(setReasons);

            change.put('Reason',string.join(listReasons,';'));

            if(changesList[i].get('ProductsToUpdate') != null){
                change.put('ProductsToUpdate',JSON.deserializeUntyped((String)JSON.serialize(changesList[i].get('ProductsToUpdate'))));
            }

            if(changesList[i].get('selectedProducts') != null){
                List<Object> selectedProducts = new List<Object>();
                selectedProducts=(List<Object>)JSON.deserializeUntyped((String)JSON.serialize(changesList[i].get('selectedProducts')));
                change.put('selectedProducts',selectedProducts);
            }

            if(changesList[i].get('RemovedMembers') != null){
                change.put('RemovedMembers',JSON.deserializeUntyped((String)JSON.serialize(changesList[i].get('RemovedMembers'))));
            }

            if(changesList[i].get('auxSavedMembers') != null){
                if (existingMembers.size()>0) {
                    for (Object auxSavedMembersItem : (List<Object>)JSON.deserializeUntyped((String)JSON.serialize(changesList[i].get('auxSavedMembers')))) {
                        auxSavedMembers.add((Map<String,Object>) auxSavedMembersItem);
                    }
                    change.put('auxSavedMembers',setAsNewMembers(auxSavedMembers, existingMembers));
                }else{
                    change.put('auxSavedMembers',JSON.deserializeUntyped((String)JSON.serialize(changesList[i].get('auxSavedMembers'))));
                }
            }
            
            if (((String)change.get('Reason')).contains('Remove Ancillary')) {
                if (change.get('selectedProducts') != null) {
                    change.put('selectedProducts',removeAncillaryProducts((List<Object>)change.get('selectedProducts')));
                }
                if (change.get('ProductsToUpdate') != null) {
                    change.put('ProductsToUpdate',removeAncillaryProducts((List<Object>)change.get('ProductsToUpdate')));
                }
            }

            if (effDate_Changes.get((String)changesList[i].get('EffDate'))!=null) {
                listOfChangesEffDate = effDate_Changes.get((String)changesList[i].get('EffDate'));
            }

            Object changeObj = JSON.deserializeUntyped(JSON.serialize(change));

            listOfChangesEffDate.add(changeObj);
            effDate_Changes.put((String)changesList[i].get('EffDate'),listOfChangesEffDate);
            changesForContractsObj.add(changeObj);
            changesForContracts.add((Map<String,Object>)change);
        }    

        for (String effDate : effDate_Changes.keySet()) {
            Map<String,Object> change = new Map<String,Object>();
            List<Object> listEffdateChanges = effDate_Changes.get(effDate);
            String singleReason = '';
            for (Object effdateChanges : listEffdateChanges) {
                Map<String,Object>  map_effdateChanges = (Map<String,Object>)effdateChanges;
                if(map_effdateChanges.get('ProductsToUpdate') != null){
                    change.put('ProductsToUpdate',map_effdateChanges.get('ProductsToUpdate'));
                }

                if(map_effdateChanges.get('selectedProducts') != null){
                    List<Object> selectedProducts = new List<Object>();
                    Set<String> prodIds = new Set<String>();
                    for (Object prd : (List<Object>)map_effdateChanges.get('selectedProducts')) {
                        prodIds.add((String)((Map<String,Object>)prd).get('Id'));
                    }
                    if (change.get('selectedProducts') != null) {
                        for (Object prd : (List<Object>)change.get('selectedProducts')) {
                            if (!prodIds.contains((String)((Map<String,Object>)prd).get('Id'))) {
                                selectedProducts.add(prd);
                            }
                        }
                    }
                    
                    selectedProducts.addAll((List<Object>)map_effdateChanges.get('selectedProducts'));
                    change.put('selectedProducts',selectedProducts);
                }
                if(map_effdateChanges.get('RemovedMembers') != null){
                    change.put('RemovedMembers',map_effdateChanges.get('RemovedMembers'));
                }
                if(map_effdateChanges.get('auxSavedMembers') != null){
                    change.put('auxSavedMembers',map_effdateChanges.get('auxSavedMembers'));
                }
                change.put('Reason',map_effdateChanges.get('Reason'));
                if(singleReason==''){
                    singleReason = (String)map_effdateChanges.get('SingleReason');
                }else{
                    singleReason = singleReason + ';'+ map_effdateChanges.get('SingleReason');
                }
                change.put('SingleReason',singleReason);
                String singleReasonToDisplay  = ((String)map_effdateChanges.get('Reason')).replace(';','\n');
                singleReasonToDisplay = singleReasonToDisplay.replace('Add Ancillary Product', 'Ancillary Change');
                change.put('SingleReasonToDisplay',singleReasonToDisplay);

                if ((String)inputMap.get('existingContractId') != null) {
                    change.put('Id',(String)inputMap.get('existingContractId'));
                }
            }
            String dDay = String.valueOf(Date.valueOf(effDate).day());
            String dMonth = String.valueOf(Date.valueOf(effDate).month());
            if (dDay.length()==1) {
                dDay = '0'+dDay;
            }
            if (dMonth.length()==1) {
                dMonth = '0'+dMonth;
            }
            change.put('EffDate',Date.valueOf(effDate).year()+'-'+dMonth+'-'+dDay);
            changesForContractsMergedSameEffDate.add(change);
            Object changeObj = JSON.deserializeUntyped(JSON.serialize(change));
            changesForContractsMergedSameEffDateObj.add(changeObj);
        }



        //Check Remove Member && Removed Spouse or Primary with dependents sharing program
        if(String.valueOf(inputMap.get('Changes_RemoveMember_Reason')) == 'Remove Member'){

            String parentDeleted;
            List<List<Object>> parentProducts = new List<List<Object>>();
            Map<String, Object> memberList = new Map<String, Object>();

            //Populate memberList as a map of MemberId - ProductIds
            for(Object dependentObject : (List<Object>) inputMap.get('dependants')){

                Map<String, Object> dependent = (Map<String, Object>) dependentObject;
                String memberId = String.valueOf(dependent.get('Id'));
                List<Object> productList = (List<Object>) dependent.get('productsIds');
                memberList.put(memberId, productList);
            }

            //Check if parent is deleted and add it to parentProducts Aux list
            for(Object objectMember : (List<Object>) inputMap.get('Changes_RemoveMember_RemovedMembers')){

                Map<String, Object> member = (Map<String, Object>)objectMember;
                String memberRelationship = String.valueOf(member.get('TXT_Relationships'));
                Boolean memberDeleted = Boolean.valueOf(member.get('CHK_Delete'));
                String memberId = String.valueOf(member.get('TXT_CensusMemberId'));
                List<Object> productList = (List<Object>) memberList.get(memberId);
                if((memberRelationship == 'Primary' || memberRelationship == 'Spouse') && memberDeleted == true && productList.size() > 1){
                    //Add productIds of the parent into parentProducts list to later compare with dependents
                    parentProducts.add(productList);
                    parentDeleted = memberRelationship;
                }
            }
                
            //Compare if dependents have the same products as a removed parent to know if we need to go into chooseProducts LWC
            for(Object objectMember : (List<Object>) inputMap.get('Changes_RemoveMember_RemovedMembers')){

                Map<String, Object> member = (Map<String, Object>)objectMember;
                String memberRelationship = String.valueOf(member.get('TXT_Relationships'));
                Boolean memberDeleted = Boolean.valueOf(member.get('CHK_Delete'));
                String memberId = String.valueOf(member.get('TXT_CensusMemberId'));
                List<Object> productList = (List<Object>) memberList.get(memberId);

                if(memberRelationship == 'Child' && memberDeleted == false && parentProducts.contains(productList) && productList.size() > 1 && memberAncillaryDependence.get(memberId) == parentDeleted){
                    removedParentWithDependents = true;
                    membersWithoutPrimary.add(memberId);
                }
            }
        }
        
        
        for (Object change : changesForContractsMergedSameEffDateObj) {
            System.debug((String)((Map<String,Object>)change).get('Reason'));
            selChangeReason.put('SEL_ChangeReason', (String)((Map<String,Object>)change).get('Reason'));

            if ((((String)((Map<String,Object>)change).get('SingleReason')).contains('Add Member') || ((String)((Map<String,Object>)change).get('SingleReason')).contains('Add Newborn') ) && !((String)((Map<String,Object>)change).get('Reason')).contains('Add Ancillary')&& !((String)((Map<String,Object>)change).get('Reason')).contains('Remove Ancillary')) {
                if(((List<Object>)((Map<String,Object>)change).get('ProductsToUpdate')).size() > 1) {
                    showAddMemberChooseProducts = true;
                }
            }
            if (((String)((Map<String,Object>)change).get('Reason')).contains('Add Ancillary')) {
                if ( inputMap.get('Changes_AddAncillary_KeepSMART') != null && inputMap.get('Changes_AddAncillary_KeepSMART') != '' && (Boolean)inputMap.get('Changes_AddAncillary_KeepSMART') ) {
                    showAddAncillaryChooseProductsKeepSMART = true;
                }
                if ( inputMap.get('Changes_AddAncillary_KeepAIDD') != null && inputMap.get('Changes_AddAncillary_KeepAIDD') != '' && (Boolean)inputMap.get('Changes_AddAncillary_KeepAIDD') ) {
                    showAddAncillaryChooseProductsKeepAIDD = true;
                } 
                if ( !showAddAncillaryChooseProductsKeepSMART && !showAddAncillaryChooseProductsKeepAIDD  ) {
                    showAddAncillaryChooseProducts = true;
                }
            }
        }
        
        if (removedParentWithDependents && !showAddAncillaryChooseProducts && !showAddMemberChooseProducts) {
            outputMap.put('FieldsetType', 'IFPProgramChangeAddMember');
        }
        if (existingMembers.size()>0) {
            outputMap.put('auxSavedMembers',auxSavedMembers);
        }

        outputMap.put('changesForContracts',changesForContractsMergedSameEffDateObj);
        outputMap.put('showAddAncillaryChooseProducts',showAddAncillaryChooseProducts);
        outputMap.put('showAddAncillaryChooseProductsKeepSMART',showAddAncillaryChooseProductsKeepSMART);
        outputMap.put('showAddAncillaryChooseProductsKeepAIDD',showAddAncillaryChooseProductsKeepAIDD);
        outputMap.put('showAddMemberChooseProducts',showAddMemberChooseProducts);
        outputMap.put('removedParentWithDependents',removedParentWithDependents);
        outputMap.put('membersWithoutPrimary',membersWithoutPrimary);

        // outputMap.put('STEP_ChangeReason',selChangeReason);


    } 


    private static List<Object> removeAncillaryProducts(List<Object> products){
        List<Object> result = new List<Object>();
        for (Object product : products) {
            if ((String)((Map<String,Object>)product).get('Type__c')!= 'Ancillary') {
                result.add(product);
            }
        }
        return result;
    }


    private static Map<Id,String> getMemberAncillaryDependence(String contractId){

        List<vlocity_ins__GroupCensusMemberPlan__c> gcmps = [SELECT Id, vlocity_ins__GroupCensusMemberId__c, vlocity_ins__GroupCensusMemberId__r.ARC_Relationship__c, vlocity_ins__ContractLineId__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c = :contractId AND vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Ancillary'];
        System.debug(gcmps);
        Map<Id,String> memberAncillaryDependences = new Map<Id,String>();
        Map<Id, String> member_relationship = new Map<Id, String>();
        Map<Id, Set<Id>> lineItem_memberIds = new Map<Id, Set<Id>>();

        for (vlocity_ins__GroupCensusMemberPlan__c gcmp : gcmps) {
            Set<Id> memberIds = new Set<Id>();
            if (lineItem_memberIds.get(gcmp.vlocity_ins__ContractLineId__c) != null) {
                memberIds.addAll(lineItem_memberIds.get(gcmp.vlocity_ins__ContractLineId__c));
            }
            memberIds.add(gcmp.vlocity_ins__GroupCensusMemberId__c);

            member_relationship.put(gcmp.vlocity_ins__GroupCensusMemberId__c, gcmp.vlocity_ins__GroupCensusMemberId__r.ARC_Relationship__c);

            lineItem_memberIds.put(gcmp.vlocity_ins__ContractLineId__c, memberIds);
        }

        for (Id lineItemId : lineItem_memberIds.keySet()) {
            Integer countPrimaries = 0; // Primary Or Spouse
            String primaryType;
            
            for (Id memberId : lineItem_memberIds.get(lineItemId)) {
                if (member_relationship.get(memberId) == 'Primary' || member_relationship.get(memberId) == 'Spouse') {
                    countPrimaries++;
                    primaryType = countPrimaries < 2 ? member_relationship.get(memberId) : 'Shared';
                }
            }
            
            for (Id memberId : lineItem_memberIds.get(lineItemId)) {
                if (memberAncillaryDependences.get(memberId)!=null) {
                    if (memberAncillaryDependences.get(memberId)!=primaryType) {
                        if (primaryType!='Shared') {
                            memberAncillaryDependences.put(memberId, primaryType);
                        }
                    }
                }else {
                    memberAncillaryDependences.put(memberId, primaryType);
                }
            }
        }
        System.debug(memberAncillaryDependences);
        return memberAncillaryDependences;
    }

    public static List<Map<String, Object>> setAsNewMembers(List<Map<String, Object>> auxSavedMembers, List<Map<String, Object>> existingMembers) {
        Set<Id> existingMembersIds = new Set<Id>();
        for (Map<String, Object> member : existingMembers) {
            existingMembersIds.add((Id)member.get('Id'));
        }
        
        
        for (Map<String, Object> member : auxSavedMembers) {
            if (existingMembersIds.contains((Id)member.get('Id'))) {
                member.put('isNew',true);
            }
        }
        return auxSavedMembers;
    }


}