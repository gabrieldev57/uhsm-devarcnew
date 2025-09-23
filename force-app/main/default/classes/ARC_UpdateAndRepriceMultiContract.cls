global without sharing class ARC_UpdateAndRepriceMultiContract implements vlocity_ins.VlocityOpenInterface {

    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'updateAndRepriceContracts') {
            updateAndRepriceContracts(inputMap, outputMap,options);
        } 
        if (methodName == 'updateAndRepriceMultiContracts') {
            updateAndRepriceMultiContracts(inputMap, outputMap,options);
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
        // // system.debug(CensusId);
        
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

        Set<String> membersToActivateIds = new Set<String>();
        Set<String> membersToDeactivateIds = new Set<String>();
        
        
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
        //System.debug('auxSavedMembers :' + auxSavedMembers);        
        //System.debug('Member78' + [SELECT Id,Name, ARC_ActiveMember__c,vlocity_ins__MemberIdentifier__c,vlocity_ins__IsPrimaryMember__c,ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__MemberIdentifier__c IN :membersToActivateIds]);
		//system.debug('membersToActivateIds' + membersToActivateIds);
		//System.debug('Member Name' + [SELECT Id,Name, ARC_ActiveMember__c,vlocity_ins__MemberIdentifier__c,vlocity_ins__IsPrimaryMember__c,ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c WHERE Name = 'Test Census Member']);
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id,Name, ARC_ActiveMember__c,vlocity_ins__MemberIdentifier__c,vlocity_ins__IsPrimaryMember__c,ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__MemberIdentifier__c IN :membersToActivateIds OR Id IN :membersToDeactivateIds OR Id = :primaryId];
        // List<vlocity_ins__GroupCensusMember__c> membersToDeactivate = [SELECT Id,vlocity_ins__MemberIdentifier__c FROM vlocity_ins__GroupCensusMember__c WHERE Id IN :membersToDeactivateIds];
        // List<vlocity_ins__GroupCensusMember__c> membersToActivate = [SELECT Id,vlocity_ins__MemberIdentifier__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__MemberIdentifier__c IN :membersToActivateIds];
        String oldPrimaryId;
        String newPrimaryOldRelationship;
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
                // system.debug('kakakakaka');
                // system.debug(member.Id + ' | '+primaryId);
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
        // system.debug(members);
        String effDate = (String)inputMap.get('EffectiveDate');
        List<Map<String, Object>> userInputs2 = getUserInput(CensusId, effDate);
        // system.debug(userInputs2);
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
        for (vlocity_ins__GroupCensusMember__c m : members) {
            // system.debug(m.Name);
            // system.debug(m.ARC_ActiveMember__c);
        }
    }

    public static void updateAndRepriceMultiContracts(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){

        String CensusId = (String)inputMap.get('CensusId');
        String primaryId = (String)inputMap.get('primaryId');
        String primaryEmail = (String)inputMap.get('primaryEmail');
        String oldRelatedPrimary = '';

        List<Object> objList_changesForContracts = (List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('changesForContracts')));
        List<Object> listUserInputLists = new List<Object>();
        List<Map<String,Object>> changesForContracts = new List<Map<String,Object>>();

        Set<String> membersToActivateDeactivateIds = new Set<String>();
        Set<String> memberIdentifOfActive = new Set<String>();
        Set<String> contractsUseNewPrimarId = new Set<String>();
        Set<String> oldActiveMembers = new Set<String>();
        
        Map<String,Set<String>> contract_membersToDeactivate = new Map<String,Set<String>>();
        Map<String,Set<String>> contract_membersToActivate = new Map<String,Set<String>>();
        Map<String, Integer> contract_PrimaryMemberAge = new Map<String, Integer>();
        Map<String, Integer> contract_ExtraDeps = new Map<String, Integer>();
        Map<String,Object> chooseProductJson = new Map<String,Object> ();

        for (Object itemObj : objList_changesForContracts) {
            Map<String, Object> item = (Map<String, Object>) itemObj;
            changesForContracts.add(item);
        }
        
        for(Map<String, Object> change : changesForContracts){

            List<Object> objList_RemovedMembers = new List<Object>();
            List<Object> objList_auxSavedMembers = new List<Object>();
            List<Map<String,Object>> auxSavedMembers = new List<Map<String,Object>>();
            List<Map<String,Object>> RemovedMembers = new List<Map<String,Object>>();

            if(change.get('auxSavedMembers') != ''){
                objList_auxSavedMembers = (List<Object>)change.get('auxSavedMembers');
                for (Object itemObj : objList_auxSavedMembers) {
                    Map<String, Object> item = (Map<String, Object>) itemObj;
                    auxSavedMembers.add(item);
                }
            }
            if(change.get('RemovedMembers') != ''){
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
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id,vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__Birthdate__c, Name, vlocity_ins__Email__c, ARC_Smoker__c, ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c = :CensusId AND (ARC_ActiveMember__c = true OR vlocity_ins__MemberIdentifier__c IN :membersToActivateDeactivateIds)];
        Account censusAccount = [SELECT Id, vlocity_ins__Email__c, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, ARC_Effective_Date__c FROM Account WHERE Id =: census.vlocity_ins__GroupId__c LIMIT 1];
        Contract censusContract = [SELECT Id, RecordTypeId, StartDate FROM Contract WHERE AccountId =: censusAccount.Id ORDER BY CreatedDate DESC LIMIT 1];


        for(Map<String, Object> change : changesForContracts) {
            Integer countChildren = 0;
            String effectiveDate = (String)change.get('EffDate');
            Date minBirthdate = null;
            for (vlocity_ins__GroupCensusMember__c member: members) {
                if (member.vlocity_ins__IsPrimaryMember__c) {
                    oldRelatedPrimary = member.Id;
                }
                if(member.ARC_ActiveMember__c){
                    oldActiveMembers.add(member.Id);
                }

                if (contract_membersToActivate.get((String)change.get('Id')).contains(member.vlocity_ins__MemberIdentifier__c) || (!contract_membersToDeactivate.get((String)change.get('Id')).contains(member.Id) && member.ARC_ActiveMember__c) ) {
                    if (member.ARC_DependentRelationship__c=='Child' && !member.vlocity_ins__IsPrimaryMember__c) {
                        countChildren++;
                    }
                    Date bd = member.vlocity_ins__birthdate__c;
                    if(minBirthdate == null){
                        minBirthdate = bd;
                    } else if(bd < minBirthdate){
                        minBirthdate = bd;
                    }
                }
            }
            System.debug(' Id:' + (String)change.get('Id'));
            System.debug('minBirthdate :' + Date.valueOf(minBirthdate));
            System.debug('effectiveDate :' + Date.valueOf(effectiveDate));
            contract_PrimaryMemberAge.put((String)change.get('Id'), calculateAge(Date.valueOf(minBirthdate), Date.valueOf(effectiveDate)));
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
                System.debug('membersToActivateDeactivateIds: '+ membersToActivateDeactivateIds);
                System.debug('member : '+ member.vlocity_ins__MemberIdentifier__c);
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
                                }else{
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
                System.debug('oldActiveMembers.contains(member.Id)'+oldActiveMembers.contains(member.Id));
                System.debug('2'+!contract_membersToDeactivate.get((String)change.get('Id')).contains(member.Id));
                System.debug('3'+!contract_membersToActivate.get((String)change.get('Id')).contains(member.vlocity_ins__MemberIdentifier__c));

                //Generate UserInputs for the current active members
                if (oldActiveMembers.contains(member.Id) && !contract_membersToDeactivate.get((String)change.get('Id')).contains(member.Id) && !contract_membersToActivate.get((String)change.get('Id')).contains(member.vlocity_ins__MemberIdentifier__c)) {
                    Map<String, Object> userInputMap = new Map<String, Object>();
                    Map<String, Object> userBirthdate = new Map<String, Object>(); // use?
                    Decimal Dependants = census.ARC_CountSuscribers__c - 1;
                    Decimal ExtraDependants;

                    String oldMemberEmail = '';

                    if(contractsUseNewPrimarId.contains((String)change.get('Id'))){
                        if(member.Id == primaryId){
                            member.vlocity_ins__IsPrimaryMember__c = true;
                            oldMemberEmail = member.vlocity_ins__Email__c;
                            member.vlocity_ins__Email__c = primaryEmail;
                            oldRelatedPrimary = member.vlocity_ins__RelatedCensusMemberId__c;
                            member.vlocity_ins__RelatedCensusMemberId__c = null;
                        }else{
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
            listUserInputLists.add(userInputNode); 
        }
        outputMap.put('changesForContracts',listUserInputLists);
        System.debug(limits.getHeapSize());
    }

    private static List<Map<String, Object>> getUserInput(String censusId, String effectiveDate) {
        // system.debug('ACACACA');
        // system.debug(censusId);
        Boolean test = true;
        List<vlocity_ins__GroupCensusMember__c> censusMember = [SELECT Id, Name,ARC_Relationship__c, vlocity_ins__Email__c, ARC_Smoker__c, ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c = :censusId AND ARC_ActiveMember__c = :test];
        // system.debug(censusMember);
        

        Date minBirthdate = null;
        Decimal ExtraDependants;
        Decimal countChildren = 0;

        for(vlocity_ins__GroupCensusMember__c member : censusMember){
            Date bd = member.vlocity_ins__birthdate__c;
            if(minBirthdate == null){
                minBirthdate = bd;
            } else if(bd < minBirthdate){
                minBirthdate = bd;
            }
            if(member.ARC_Relationship__c == 'Child' && !member.vlocity_ins__IsPrimaryMember__c){
                countChildren++;
            }
        } 
        if (countChildren - 3 <= 0 ) {
            ExtraDependants = 0;
        }else {
            ExtraDependants = countChildren - 3;
        }


        vlocity_ins__GroupCensus__c census = [SELECT Id, Name, ARC_MinCensusDOB__c, ARC_CountSuscribers__c, ARC_CountChildren__c, ARC_CountSpouse__c, vlocity_ins__GroupId__c, ARC_PrimaryAccount__c FROM vlocity_ins__GroupCensus__c WHERE Id = :censusId];
        // system.debug('census');
        // system.debug(census);
        Account censusAccount = [SELECT Id, vlocity_ins__Email__c, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, ARC_Effective_Date__c FROM Account WHERE Id =: census.ARC_PrimaryAccount__c LIMIT 1];
        Contract censusContract = [SELECT Id, RecordTypeId, StartDate FROM Contract WHERE vlocity_ins__EnrollmentCensusId__c =: census.Id ORDER BY CreatedDate DESC LIMIT 1];
        Decimal Dependants = census.ARC_CountSuscribers__c - 1;

        // system.debug(censusAccount);
        // system.debug(censusContract);
        
        List<Map<String, Object>> userInputList = new List<Map<String, Object>>();

        for (vlocity_ins__GroupCensusMember__c member : censusMember) {
            Map<String, Object> userInputMap = new Map<String, Object>();
            Map<String, Object> userBirthdate = new Map<String, Object>(); // use?

            
            
            Integer PrimaryAge = -1;
            Integer age = -1;
            if(effectiveDate != null ){
                //PrimaryAge = Integer.valueOf((Date.valueOf(minBirthdate).daysBetween(Date.valueOf(effectiveDate)))/365.2425);
                PrimaryAge = calculateAge( Date.valueOf(minBirthdate), Date.valueOf(effectiveDate));
                //age = Integer.valueOf((Date.valueOf(member.vlocity_ins__Birthdate__c).daysBetween(Date.valueOf(effectiveDate)))/365.2425);
                age = calculateAge( Date.valueOf(member.vlocity_ins__Birthdate__c), Date.valueOf(effectiveDate));
            }else{
                //PrimaryAge = Integer.valueOf((Date.valueOf(minBirthdate).daysBetween(Date.today()))/365.2425);
                PrimaryAge = calculateAge( Date.valueOf(minBirthdate), Date.today());
                //age = Integer.valueOf((Date.valueOf(member.vlocity_ins__Birthdate__c).daysBetween(Date.today()))/365.2425);   
                age = calculateAge( Date.valueOf(member.vlocity_ins__Birthdate__c), Date.today());
            }


            String coverage = '';
            if(census.ARC_CountSpouse__c==1 && census.ARC_CountSuscribers__c == 2){
                coverage = 'Primary + Spouse';
            }else if(census.ARC_CountChildren__c==1 && census.ARC_CountSuscribers__c==2){
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

            String coverageAIDD = '';
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
            userInputMap.put('State', censusAccount.BillingState);
            userInputMap.put('Zipcode', censusAccount.BillingPostalCode);
            userInputMap.put('EffectiveDate', censusAccount.ARC_Effective_Date__c);
            userInputMap.put('Birthdate', member.vlocity_ins__Birthdate__c);
            userInputMap.put('RF_Census.CRF_Dependants', Dependants);
            userInputMap.put('RF_Census.CRF_ExtraDependants', ExtraDependants);
            userInputMap.put('RF_Census.CRF_PrimaryMemberAge', PrimaryAge);
            userInputMap.put('RF_Census.CM_State', member.ARC_PhysicalAddressState__c);
            userInputMap.put('RF_Census.CM_IsPrimary', member.vlocity_ins__isprimarymember__c);
            userInputMap.put('RF_Census.CM_IsSpouse', member.vlocity_ins__isspouse__c);
            userInputMap.put('RF_Census.CM_Smoker', member.ARC_Smoker__c);
            userInputMap.put('RF_Census.CM_Age', age);
            userInputMap.put('RF_Census.CRF_Coverage', coverage);
            userInputMap.put('RF_Census.CRF_CoverageAIDD', coverageAIDD);
    
            userInputList.add(userInputMap);
            // system.debug(userInputMap);
        }        
        // system.debug(userInputList);
        
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


    private static Map<String, Object> generateUserInputForMember(vlocity_ins__GroupCensusMember__c member, vlocity_ins__GroupCensus__c census,Account censusAccount, Contract censusContract, String effectiveDate, Integer ExtraDependants, Integer PrimaryMemberAge){
        Map<String, Object> userInputMap = new Map<String, Object>();
        
        Decimal Dependants = census.ARC_CountSuscribers__c - 1;
        Integer PrimaryAge = -1;
        Integer age = -1;
        String coverage = '';
        String coverageAIDD = '';
        Boolean isMinor = false;

        if(effectiveDate != null ){
            age = calculateAge( Date.valueOf(member.vlocity_ins__Birthdate__c), Date.valueOf(effectiveDate));
        }else{
            age = calculateAge( Date.valueOf(member.vlocity_ins__Birthdate__c), Date.today());
        }

        if(census.ARC_CountSpouse__c==1 && census.ARC_CountSuscribers__c == 2){
            coverage = 'Primary + Spouse';
        }else if(census.ARC_CountChildren__c==1 && census.ARC_CountSuscribers__c==2){
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
        userInputMap.put('CensusMemberFirstName', member.vlocity_ins__firstname__c);
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
        userInputMap.put('State', censusAccount.BillingState);
        userInputMap.put('Zipcode', censusAccount.BillingPostalCode);
        userInputMap.put('EffectiveDate', censusAccount.ARC_Effective_Date__c);
        userInputMap.put('Birthdate', member.vlocity_ins__Birthdate__c);
        userInputMap.put('RF_Census.CRF_Dependants', Dependants);
        userInputMap.put('RF_Census.CRF_ExtraDependants', ExtraDependants);
        userInputMap.put('RF_Census.CRF_PrimaryMemberAge', PrimaryMemberAge);
        userInputMap.put('RF_Census.CM_State', member.ARC_PhysicalAddressState__c);
        userInputMap.put('RF_Census.CM_IsPrimary', member.vlocity_ins__isprimarymember__c);
        userInputMap.put('RF_Census.CM_IsSpouse', member.vlocity_ins__isspouse__c);
        userInputMap.put('RF_Census.CM_Smoker', member.ARC_Smoker__c);
        userInputMap.put('RF_Census.CM_Age', age);
        userInputMap.put('RF_Census.CRF_Coverage', coverage);
        userInputMap.put('RF_Census.CRF_CoverageAIDD', coverageAIDD);

        return userInputMap;
    }

}