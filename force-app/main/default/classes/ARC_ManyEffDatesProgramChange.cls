global without sharing class ARC_ManyEffDatesProgramChange implements vlocity_ins.VlocityOpenInterface{
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        //System.debug(methodName);
        if (methodName == 'changesList') {
            changesList(inputMap, outputMap,options);
        }        
        if (methodName == 'listToStringFormat') {
            listToStringFormat(inputMap, outputMap,options);
        }        
        return true;
    }

    public static void listToStringFormat(Map<String,Object> inputMap, Map<String,Object> outputMap,Map<String,Object> options){
        //System.debug('objInputList');
        // List<String> objInputList = (inputMap.get('inputList'));


        List<Object> reqs = (List<Object>) inputMap.get('inputList');
        List<string> lsstr= new List<string> ();

        for(Object a: reqs){
            lsstr.add(String.valueOf(a));
        }
        //System.debug(lsstr);
        // List<String>  inputList= new List<String>();
        // for (Object itemObj : objInputList) {
        //     String item = (String) itemObj;
        //     inputList.add(item);
        // }
        // System.debug(inputList);
        // String stringList = '';
        // for (String element : inputList) {
        //     System.debug(element);
        //     stringList += '\''+element+'\'';
        // }
        // System.debug(stringList);
        // stringList = '('+stringList+')';
        outputMap.put('stringList','stringList');
    }
    public static void changesList(Map<String,Object> inputMap, Map<String,Object> outputMap,Map<String,Object> options) {
        // Map<String,Object> changesObj = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes')));
        List<Map<String,Object>> changesList = new List<Map<String,Object>>();
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
            addAncillaryChanges.put('EffDate',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_AddAncillary_EffDate'))));
            addAncillaryChanges.put('Reason',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_AddAncillary_Reason'))));
            addAncillaryChanges.put('selectedProducts',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_AddAncillary_selectedProducts'))));
            addAncillaryChanges.put('ProductsToUpdate',JSON.deserializeUntyped(JSON.serialize(inputMap.get('Changes_AddAncillary_ProductsToUpdate'))));
            changesList.add(addAncillaryChanges);
        }
        
        
        
        
        Set<String> effDates = new Set<String>();
        Map<String,Object> originalValues = new Map<String,Object>();
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
        List<Object> changesForContractsObj = new List<Object>();
        List<Map<String,Object>> changesForContracts = new List<Map<String,Object>>();
        String reasons = '';

        List<Object> changesForContractsMergedSameEffDateObj = new List<Object>();
        List<Map<String,Object>> changesForContractsMergedSameEffDate = new List<Map<String,Object>>();
        List<String> listEffDates = new List<String>(effDates);
        //System.debug(effDates);
        Map<String,List<Object>> effDate_Changes = new Map<String,List<Object>>();
        Set<String> setReasons = new Set<String>();

        for (Integer i = 0; i < changesList.size(); i++) {
            Map<String,Object> change = originalValues;
            if(i>0){
                change = changesForContracts[i-1];
            }
            change.put('SingleReason',((String)changesList[i].get('Reason')));
            setReasons.add((String)changesList[i].get('Reason'));
            List<String> listReasons = new List<String>(setReasons);
            change.put('Reason',string.join(listReasons,';'));
            if(changesList[i].get('ProductsToUpdate') != null){
                change.put('ProductsToUpdate',JSON.deserializeUntyped((String)JSON.serialize(changesList[i].get('ProductsToUpdate'))));
            }
            if(changesList[i].get('selectedProducts') != null){
                change.put('selectedProducts',JSON.deserializeUntyped((String)JSON.serialize(changesList[i].get('selectedProducts'))));
            }
            if(changesList[i].get('RemovedMembers') != null){
                change.put('RemovedMembers',JSON.deserializeUntyped((String)JSON.serialize(changesList[i].get('RemovedMembers'))));
            }
            if(changesList[i].get('auxSavedMembers') != null){
                change.put('auxSavedMembers',JSON.deserializeUntyped((String)JSON.serialize(changesList[i].get('auxSavedMembers'))));
            }
            List<Object> listOfChangesEffDate = new List<Object>();
            if (effDate_Changes.get((String)changesList[i].get('EffDate'))!=null) {
                listOfChangesEffDate = effDate_Changes.get((String)changesList[i].get('EffDate'));
                //System.debug('entre a este if');
            }
            Object changeObj = JSON.deserializeUntyped(JSON.serialize(change));
            listOfChangesEffDate.add(changeObj);
            // System.debug(change);
            // System.debug(listOfChangesEffDate);
            effDate_Changes.put((String)changesList[i].get('EffDate'),listOfChangesEffDate);
            changesForContractsObj.add(changeObj);
            //System.debug(changeObj);
            changesForContracts.add((Map<String,Object>)change);
        }        
        //System.debug(effDate_Changes.values());
        for (String effDate : effDate_Changes.keySet()) {
            Map<String,Object> change = new Map<String,Object>();
            List<Object> listEffdateChanges = effDate_Changes.get(effDate);
            String singleReason = '';
            for (Object effdateChanges : listEffdateChanges) {
                Map<String,Object>  map_effdateChanges = (Map<String,Object>)effdateChanges;
                //System.debug(map_effdateChanges.get('Reason'));
                if(map_effdateChanges.get('ProductsToUpdate') != null){
                    change.put('ProductsToUpdate',map_effdateChanges.get('ProductsToUpdate'));
                }
                if(map_effdateChanges.get('selectedProducts') != null){
                    change.put('selectedProducts',map_effdateChanges.get('selectedProducts'));
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
                change.put('SingleReasonToDisplay',((String)map_effdateChanges.get('Reason')).replace(';','\n'));
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
        



        outputMap.put('changesForContracts',changesForContractsMergedSameEffDateObj);


    } 
}