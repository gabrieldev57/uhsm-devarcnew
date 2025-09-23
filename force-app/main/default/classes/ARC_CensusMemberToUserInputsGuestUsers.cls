global without sharing class ARC_CensusMemberToUserInputsGuestUsers implements vlocity_ins.VlocityOpenInterface {
    //This integer adds days to calculate the age for the effective date in the product selection.
    private static integer daysToAdd = 60;
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'ARC_CensusMemberToUserInputsGuestUsers') {
            ARC_CensusMemberToUserInputsGuestUsers(inputMap, outputMap, options);
        } else if(methodName == 'ARC_UserInputsFromCensusMembersGuestUsers' ){
            ARC_UserInputsFromCensusMembersGuestUsers(inputMap, outputMap, options);
        } else if(methodName == 'ARC_UserInputsForAncillaryPrograms'){
            ARC_UserInputsForAncillaryPrograms(inputMap, outputMap, options);
        }
        return true;
    }
    public static void ARC_CensusMemberToUserInputsGuestUsers(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        String censusId =  String.valueOf(inputMap.get('censusId'));
        String onlyActiveMembers = String.valueOf(inputMap.get('onlyActiveMembers'));
        String censusMemberIdForFilter = String.valueOf(inputMap.get('censusMemberIdForFilter'));
        String oldUserInputs2 = String.valueOf(inputMap.get('oldUserInputs2'));
        String contractId = String.valueOf(inputMap.get('contractId'));
        Boolean changedRatingParams = false;
        Boolean isChildFamily = false;
        Decimal maxChildDependents = 3;
        String effectiveDate =  String.valueOf(inputMap.get('effectiveDate'));

        List<Object> OBJrejectedMembersIds = inputMap.get('rejectedMembersIds') != null ? (List<Object>)inputMap.get('rejectedMembersIds') : new List<Object>();
        Set<String> rejectedMembersIds = new Set<String>();
        for (Object item : OBJrejectedMembersIds) {
            rejectedMembersIds.add((String)item);
        }

        List<vlocity_ins__GroupCensusMember__c> censusMember = new List<vlocity_ins__GroupCensusMember__c>();
        if(onlyActiveMembers == 'true'){
            censusMember = [SELECT Id, Name, vlocity_ins__Email__c, ARC_Smoker__c, ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c WHERE (vlocity_ins__CensusId__c = :censusId AND ARC_ActiveMember__c = true )];
        } else if ( contractId != null && contractId != '' ) {
            Map<Id, vlocity_ins__GroupCensusMember__c> uniqueMembersMap = new Map<Id, vlocity_ins__GroupCensusMember__c>();
            if (rejectedMembersIds!= null) {
                for ( vlocity_ins__GroupCensusMemberPlan__c gcmp : [ SELECT Id, ARC_Active__c, Name, vlocity_ins__GroupCensusMemberId__r.Id,vlocity_ins__GroupCensusMemberId__r.Name,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c,vlocity_ins__GroupCensusMemberId__r.ARC_Smoker__c,vlocity_ins__GroupCensusMemberId__r.ARC_ActiveMember__c,vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressState__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__MemberIdentifier__c,vlocity_ins__GroupCensusMemberId__r.arc_medicalproduct__c,vlocity_ins__GroupCensusMemberId__r.arc_dentalproduct__c,vlocity_ins__GroupCensusMemberId__r.arc_visionproduct__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__censusid__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__birthdate__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__isprimarymember__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__gender__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__isspouse__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__lastname__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__firstname__c,vlocity_ins__GroupCensusMemberId__r.ARC_AgeInSixMonths__c,vlocity_ins__GroupCensusMemberId__r.ARC_DependentRelationship__c, vlocity_ins__ContractLineId__r.Name, vlocity_ins__ContractLineId__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c = :contractId AND vlocity_ins__GroupCensusMemberId__c NOT IN : rejectedMembersIds] ) {
                    uniqueMembersMap.put(gcmp.vlocity_ins__GroupCensusMemberId__c, gcmp.vlocity_ins__GroupCensusMemberId__r);
                }              
            }else {
                for ( vlocity_ins__GroupCensusMemberPlan__c gcmp : [ SELECT Id, ARC_Active__c, Name, vlocity_ins__GroupCensusMemberId__r.Id,vlocity_ins__GroupCensusMemberId__r.Name,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c,vlocity_ins__GroupCensusMemberId__r.ARC_Smoker__c,vlocity_ins__GroupCensusMemberId__r.ARC_ActiveMember__c,vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressState__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__MemberIdentifier__c,vlocity_ins__GroupCensusMemberId__r.arc_medicalproduct__c,vlocity_ins__GroupCensusMemberId__r.arc_dentalproduct__c,vlocity_ins__GroupCensusMemberId__r.arc_visionproduct__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__censusid__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__birthdate__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__isprimarymember__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__gender__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__isspouse__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__lastname__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__firstname__c,vlocity_ins__GroupCensusMemberId__r.ARC_AgeInSixMonths__c,vlocity_ins__GroupCensusMemberId__r.ARC_DependentRelationship__c, vlocity_ins__ContractLineId__r.Name, vlocity_ins__ContractLineId__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c = :contractId ] ) {
                    uniqueMembersMap.put(gcmp.vlocity_ins__GroupCensusMemberId__c, gcmp.vlocity_ins__GroupCensusMemberId__r);
                }
            }
            censusMember = uniqueMembersMap.values();

        } else {
            censusMember = [SELECT Id, Name, vlocity_ins__Email__c, ARC_Smoker__c, ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c = :censusId];
        
        }

        Set<Id> censusMembersId = new Set<Id>();
        if (censusMember.size() > 0) {
            for (vlocity_ins__GroupCensusMember__c member : censusMember) {
                censusMembersId.add(member.Id);
            }
        }

        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpList = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        if ( contractId != null && contractId != '' ) { 
            gcmpList = [SELECT Id, vlocity_ins__GroupCensusMemberId__c, vlocity_ins__ContractLineId__c, vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__r.Id, vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c, vlocity_ins__GroupCensusMemberId__r.ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__GroupCensusMemberId__c IN: censusMembersId AND vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c = :contractId LIMIT 500];
        } else {
            gcmpList = [SELECT Id, vlocity_ins__GroupCensusMemberId__c, vlocity_ins__ContractLineId__c, vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__r.Id, vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c, vlocity_ins__GroupCensusMemberId__r.ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__GroupCensusMemberId__c IN: censusMembersId AND ARC_Active__c = TRUE LIMIT 500];
        }
        Map<Id,String> cliParent = getCLIParent(gcmpList);

        Date minBirthdate = null;
        Date maxBirthdate = null;
        Id oldestMemberId = null;
        // Boolean hasPrimary = false;
        for(vlocity_ins__GroupCensusMember__c member : censusMember){
            Date bd = member.vlocity_ins__birthdate__c;
            if(minBirthdate == null){
                minBirthdate = bd;
            } else if(bd < minBirthdate){
                minBirthdate = bd;
            }
            if( maxBirthdate == null ) {
                maxBirthdate = bd;
                oldestMemberId = member.Id;
            } else if ( bd < minBirthdate ) {
                maxBirthdate = bd;
            }
            if ( member.vlocity_ins__isprimarymember__c ) {
                // hasPrimary = true;
            }
        } 
        vlocity_ins__GroupCensus__c census = [SELECT Id, Name, ARC_MinCensusDOB__c, ARC_CountSuscribers__c, ARC_CountChildren__c, ARC_CountSpouse__c, vlocity_ins__GroupId__c, ARC_PrimaryAccount__c FROM vlocity_ins__GroupCensus__c WHERE Id = :censusId];
        Account censusAccount = [SELECT Id, vlocity_ins__Email__c, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, ARC_Effective_Date__c FROM Account WHERE Id =: census.vlocity_ins__GroupId__c LIMIT 1];
    
        Contract censusContract;
        if ( contractId != null && contractId != '' ) { 
            censusContract = [SELECT Id, RecordTypeId, StartDate FROM Contract WHERE Id = :contractId];
        } else {
            censusContract = [SELECT Id, RecordTypeId, StartDate FROM Contract WHERE AccountId =: censusAccount.Id ORDER BY CreatedDate DESC LIMIT 1];
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
        for (vlocity_ins__GroupCensusMember__c memb : censusMember) {
            if (memb.vlocity_ins__IsPrimaryMember__c && memb.ARC_DependentRelationship__c==null) {
                hasPrimary=true;
                olderAge = calculateAge(memb.vlocity_ins__Birthdate__c, Date.valueOf(effectiveDate));
                olderMemberId = memb.Id;
            }
        }
        if (!hasPrimary) {
            for (vlocity_ins__GroupCensusMember__c member : censusMember) {
                if (member.vlocity_ins__isspouse__c) {
                    member.vlocity_ins__isspouse__c = false;
                    member.ARC_DependentRelationship__c = null;
                    member.vlocity_ins__IsPrimaryMember__c = true;
                    hasPrimary = true;
                }
            }
        }
        if (!hasPrimary) {
            for (vlocity_ins__GroupCensusMember__c member : censusMember) {
                if (member.Id == olderMemberId) {
                    member.vlocity_ins__IsPrimaryMember__c = true;
                    member.ARC_DependentRelationship__c = null;
                    hasPrimary = true;
                }
            }
        }


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
                    if (calculateAge(memb.vlocity_ins__Birthdate__c, Date.valueOf(effectiveDate)) > olderAge){
                        olderAge = calculateAge(memb.vlocity_ins__Birthdate__c, Date.valueOf(effectiveDate));
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
            
            
            
            
            
        Integer CurrentPrimaryAge = calculateAge( Date.valueOf(minBirthdate), Date.valueOf(effectiveDate));

        for (vlocity_ins__GroupCensusMember__c member : censusMember) {
            Map<String, Object> userInputMap = new Map<String, Object>();
            Map<String, Object> userBirthdate = new Map<String, Object>(); // use?

            Decimal Dependants = census.ARC_CountSuscribers__c - 1;
            
            Decimal ExtraDependants;
            Decimal childDependents = countChildDependents(censusMember);
            if (childDependents - maxChildDependents <= 0){
                ExtraDependants = 0;
            } else{
                ExtraDependants = childDependents - maxChildDependents;
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

            userInputMap.put('Id', member.Id);
            userInputMap.put('CensusMemberId', member.Id);
            userInputMap.put('CensusMemberName', member.Name);
            userInputMap.put('isMinor', isMinor);
            userInputMap.put('CensusMemberLastName', member.vlocity_ins__lastname__c);
            userInputMap.put('CensusMemberFirstName', member.vlocity_ins__firstname__c);
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
            userInputMap.put('RF_Census.CM_Smoker', member.ARC_Smoker__c);
            userInputMap.put('RF_Census.CM_Age', age);
            userInputMap.put('RF_Census.CRF_Coverage', coverageSMART);
            userInputMap.put('RF_Census.CRF_CoverageAIDD', coverageAIDD);
            if ( !hasPrimary && member.Id == oldestMemberId ) {
                userInputMap.put('RF_Census.CM_IsPrimary', true);
                userInputMap.put('RF_Census.CM_IsSpouse', false);
                userInputMap.put('CensusMemberRelationship', null);
                userInputMap.put('Relationship', 'Primary');
            } else {
                userInputMap.put('CensusMemberRelationship', member.ARC_DependentRelationship__c);
                userInputMap.put('Relationship', String.isBlank(member.ARC_DependentRelationship__c) ? 'Primary' : member.ARC_DependentRelationship__c);
                userInputMap.put('RF_Census.CM_IsPrimary', member.vlocity_ins__IsPrimaryMember__c);
                userInputMap.put('RF_Census.CM_IsSpouse', member.vlocity_ins__isspouse__c);
            }

            if (gcmpList.size() > 0) {
                List<Id> planIdsList = new List<Id>();

                for (vlocity_ins__GroupCensusMemberPlan__c plan : gcmpList) {
                    if (plan.vlocity_ins__GroupCensusMemberId__c == member.Id) {
                        planIdsList.add(plan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__r.Id);
                        if (member.ARC_DependentRelationship__c == 'Child') {
                            userInputMap.put('parent'+plan.vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c, cliParent.get(plan.vlocity_ins__ContractLineId__c));
                        }

                    }
                }
                userInputMap.put('Products', planIdsList);
            }
            
            userInputList.add(userInputMap);

            if (member.vlocity_ins__IsPrimaryMember__c && age < 18) {
                isChildFamily = true;
            }
            System.debug(userInputMap);
        }     

        if(String.isNotBlank(censusMemberIdForFilter)){
            String s = censusMemberIdForFilter;
            s = s.substring(1, s.length() - 1);
            List<String> bulkCensusMemberId = s.split('\\, ');
            Date aux = date.today();
            Map<String, Object>  memberAux = new Map<String, Object>();
            
            for (Map<String, Object> censusMemberAux  : userInputList) {
                Date bd = date.valueOf(censusMemberAux.get('Birthdate'));
                Integer age = Integer.valueOf(censusMemberAux.get('RF_Census.CM_Age'));
                String censusMemberIdFromBulk = String.valueOf(censusMemberAux.get('CensusMemberId'));
                
                for(String censusMemberIdAux : bulkCensusMemberId){

                    if(bd < aux && censusMemberIdFromBulk == censusMemberIdAux) {
                        aux = bd;
                        memberAux = censusMemberAux;
                    }
                }
                outputMap.put('oldestMember', memberAux);
            }

        }

        Date aux = date.today();
        Map<String, Object>  memberAux = new Map<String, Object>();
        
        if (!hasPrimary) {
            
            for (Map<String, Object> censusMemberAux  : userInputList) {
                Date bd = date.valueOf(censusMemberAux.get('Birthdate'));
                Integer age = Integer.valueOf(censusMemberAux.get('RF_Census.CM_Age'));
                String censusMemberIdFromBulk = String.valueOf(censusMemberAux.get('CensusMemberId'));
                if(bd < aux) {
                    aux = bd;
                    memberAux = censusMemberAux;
                }
            }
        }


        
        if(oldUserInputs2 != ''){
            changedRatingParams = true;
        }

        outputMap.put('changedRatingParams', changedRatingParams);
        outputMap.put('userInputs2', userInputList);
        outputMap.put('primaryId', memberAux.get('Id'));
        outputMap.put('primaryEmail', memberAux.get('Email'));
        outputMap.put('isChildFamily', isChildFamily);
    }

    public static void ARC_UserInputsFromCensusMembersGuestUsers(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        List<Object> censusMemberIds =  (List<Object>)inputMap.get('censusMemberIds');
        List<String> censusMemberIdsList = new List<String>();

        for(Object a: censusMemberIds){
            censusMemberIdsList.add(String.valueOf(a));
        }
        String userId = String.valueOf(inputMap.get('userId'));
        String onlyActiveMembers = String.valueOf(inputMap.get('onlyActiveMembers'));
        String censusMemberIdForFilter = String.valueOf(inputMap.get('censusMemberIdForFilter'));
        String effectiveDate =  String.valueOf(inputMap.get('effectiveDate'));


        List<vlocity_ins__GroupCensusMember__c> censusMembers = new List<vlocity_ins__GroupCensusMember__c>();

        if(onlyActiveMembers == 'true'){
            censusMembers = [SELECT Id, Name, vlocity_ins__Email__c, ARC_Smoker__c, ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c WHERE (Id IN :censusMemberIdsList AND ARC_ActiveMember__c = true )];
        }else{
            censusMembers = [SELECT Id, Name, vlocity_ins__Email__c, ARC_Smoker__c, ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c WHERE Id IN :censusMemberIdsList];
        }

        Map<String,Object> stats = getCensusMembersStats(censusMembers, effectiveDate);

        // Date minBirthdate = null;
        // for(vlocity_ins__GroupCensusMember__c member : censusMembers){
        //     Date bd = member.vlocity_ins__birthdate__c;
        //     if(minBirthdate == null){
        //         minBirthdate = bd;
        //     } else if(bd < minBirthdate){
        //         minBirthdate = bd;
        //     }
        // } 
        Date minBirthdate = Date.valueOf(stats.get('MinBirthdate'));

        
        // vlocity_ins__GroupCensus__c census = [SELECT Id, Name, ARC_MinCensusDOB__c, ARC_CountSuscribers__c, ARC_CountChildren__c, ARC_CountSpouse__c, vlocity_ins__GroupId__c, ARC_PrimaryAccount__c FROM vlocity_ins__GroupCensus__c WHERE Id = :censusId];
        // Account censusAccount = [SELECT Id, vlocity_ins__Email__c, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, ARC_Effective_Date__c FROM Account WHERE Id =: census.ARC_PrimaryAccount__c LIMIT 1];
        // Contract censusContract = [SELECT Id, RecordTypeId, StartDate FROM Contract WHERE AccountId =: censusAccount.Id ORDER BY CreatedDate DESC LIMIT 1];
    
        Decimal Dependants = (Decimal)stats.get('Dependants') - 1;
        Decimal ExtraDependants = (Decimal)(stats.get('ExtraDependants'));
        Integer PrimaryAge = Integer.valueOf(stats.get('PrimaryAge'));
        String coverage = String.valueOf(stats.get('Coverage'));
        String coverageAIDD = String.valueOf(stats.get('CoverageAIDD'));
        
        List<Map<String, Object>> userInputList = new List<Map<String, Object>>();
        for (vlocity_ins__GroupCensusMember__c member : censusMembers) {
            Map<String, Object> userInputMap = new Map<String, Object>();
            //Map<String, Object> userBirthdate = new Map<String, Object>();

            
            // Decimal ExtraDependants;
            // if (dependants - 5 < 0){
            //     ExtraDependants = 0;
            // } else{
            //     ExtraDependants = dependants - 5;
            // }
            
            Integer age = -1;
            if(effectiveDate != null ){
                Date DOB = Date.valueOf(minBirthdate);
                Date effDate = Date.valueOf(effectiveDate).addDays(daysToAdd);
                age = calculateAge( DOB, effDate);
                //age = Integer.valueOf((Date.valueOf(minBirthdate).daysBetween(Date.valueOf(effectiveDate)))/365.2425);
            }else{
                Date DOB = Date.valueOf(minBirthdate);
                Date effDate = Date.today().addDays(daysToAdd);
                age = calculateAge( DOB, effDate);
                //age = Integer.valueOf((Date.valueOf(minBirthdate).daysBetween(Date.today()))/365.2425);  
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

            

            userInputMap.put('isOldest', '');
            userInputMap.put('CensusMemberId', member.Id);
            userInputMap.put('CensusMemberName', member.Name);
            userInputMap.put('isMinor', isMinor);
            userInputMap.put('CensusMemberLastName', member.vlocity_ins__lastname__c);
            userInputMap.put('CensusMemberFirstName', member.vlocity_ins__firstname__c);
            userInputMap.put('CensusMemberRelationship', member.ARC_DependentRelationship__c);
            userInputMap.put('CensusMemberIdentifier', member.vlocity_ins__MemberIdentifier__c);
            //userInputMap.put('CensusEmail', censusAccount.vlocity_ins__Email__c);
            //userInputMap.put('ContractId', censusContract.Id);
            //userInputMap.put('AccountId', censusAccount.Id);
            //userInputMap.put('ContractRecType', censusContract.RecordTypeId);
            //userInputMap.put('ContractStartDate', censusContract.StartDate);
            //userInputMap.put('Email', member.vlocity_ins__Email__c);
            //userInputMap.put('Phone', censusAccount.Phone);
            //userInputMap.put('Street', censusAccount.BillingStreet);
            //userInputMap.put('City', censusAccount.BillingCity);
            //userInputMap.put('State', censusAccount.BillingState);
            //userInputMap.put('Zipcode', censusAccount.BillingPostalCode);
            //userInputMap.put('EffectiveDate', censusAccount.ARC_Effective_Date__c);
            userInputMap.put('EffectiveDate', effectiveDate);
            userInputMap.put('Birthdate', member.vlocity_ins__Birthdate__c);
            userInputMap.put('RF_Census.CRF_Dependants', Dependants);
            userInputMap.put('RF_Census.CRF_ExtraDependants', ExtraDependants);
            userInputMap.put('RF_Census.CRF_PrimaryMemberAge', PrimaryAge);
            userInputMap.put('RF_Census.CM_State', member.ARC_PhysicalAddressState__c);
            userInputMap.put('RF_Census.CM_IsPrimary', member.vlocity_ins__IsPrimaryMember__c);
            userInputMap.put('RF_Census.CM_Smoker', member.ARC_Smoker__c);
            userInputMap.put('RF_Census.CM_Age', age);
            userInputMap.put('RF_Census.CRF_Coverage', coverage);
            userInputMap.put('RF_Census.CRF_CoverageAIDD', coverageAIDD);
    
            userInputList.add(userInputMap);
        }        

        if(String.isNotBlank(censusMemberIdForFilter)){
             String s = censusMemberIdForFilter;
			 s = s.substring(1, s.length() - 1);
             List<String> bulkCensusMemberId = s.split('\\, ');
             Date aux = date.today();
            Map<String, Object>  memberAux = new Map<String, Object>();
            
            for (Map<String, Object> censusMemberAux  : userInputList) {
                Date bd = date.valueOf(censusMemberAux.get('Birthdate'));
                Integer age = Integer.valueOf(censusMemberAux.get('RF_Census.CM_Age'));
                String censusMemberIdFromBulk = String.valueOf(censusMemberAux.get('CensusMemberId'));
                
                for(String censusMemberIdAux : bulkCensusMemberId){

                    if(bd < aux && censusMemberIdFromBulk == censusMemberIdAux) {
                        aux = bd;
                        memberAux = censusMemberAux;
                    }
                }
                memberAux.put('isOldest', true);
                outputMap.put('oldestMember', memberAux);
            }
           
        }
        outputMap.put('userInputs2', userInputList);
    }

    private static Map<String,Object> getCensusMembersStats(List<vlocity_ins__GroupCensusMember__c> censusMembers, String effectiveDate){
        Map<String,Object> censusStats = new Map<String,Object>();
        Decimal maxChildDependents = 3;
        Date minBirthdate = null;
        Boolean hasSpouse = false;
        Integer countChildren = 0;
        //loop for general values on the members group
        for(vlocity_ins__GroupCensusMember__c member : censusMembers){
            if(!hasSpouse){
                if(member.ARC_DependentRelationship__c == 'Spouse'){
                    hasSpouse = true;
                }
            }
            if(member.ARC_DependentRelationship__c == 'Child'){
                countChildren = countChildren + 1;
            }

            Date bd = member.vlocity_ins__birthdate__c;
            if(minBirthdate == null){
                minBirthdate = bd;
            } else if(bd < minBirthdate){
                minBirthdate = bd;
            }

        } 
        censusStats.put('MinBirthdate', minBirthdate);
        censusStats.put('HasSpouse', hasSpouse);
        censusStats.put('CountChildren', countChildren);

        Integer suscribers = censusMembers.size();
        censusStats.put('Suscribers', suscribers);
        censusStats.put('Dependants', suscribers -1);

        Decimal dependants = suscribers -1;
        Decimal ExtraDependants;
        Decimal childDependents = countChildDependents(censusMembers);
        if (childDependents - maxChildDependents <= 0){
            ExtraDependants = 0;
        } else{
            ExtraDependants = childDependents - maxChildDependents;
        }
        censusStats.put('ExtraDependants', ExtraDependants);

        Integer primaryAge = -1;
        if(effectiveDate != null ){
            Date DOB = Date.valueOf(minBirthdate);
            Date effDate = Date.valueOf(effectiveDate).addDays(daysToAdd);
            primaryAge = calculateAge( DOB, effDate);
            //primaryAge = Integer.valueOf((Date.valueOf(minBirthdate).daysBetween(Date.valueOf(effectiveDate)))/365.2425);
        }else{
            Date DOB = Date.valueOf(minBirthdate);
            Date effDate = Date.today().addDays(daysToAdd);
            primaryAge = calculateAge( DOB, effDate);
            //primaryAge = Integer.valueOf((Date.valueOf(minBirthdate).daysBetween(Date.today()))/365.2425);  
        }
        censusStats.put('PrimaryAge', primaryAge);

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
        censusStats.put('Coverage', coverage);

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
        censusStats.put('CoverageAIDD', coverageAIDD);

        return censusStats;
    }

    public static void ARC_UserInputsForAncillaryPrograms(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
        List<Object> censusMemberDataList =  (List<Object>)inputMap.get('censusMemberDataList');
        Boolean shareAiddPrograms = (Boolean)inputMap.get('shareAiddPrograms');
        Boolean shareSmartPrograms = (Boolean)inputMap.get('shareSmartPrograms');
        Map< String, List<Map<String,Object>> > membersByProgram = new Map< String, List<Map<String,Object>> >();
        for(Object memberObj : censusMemberDataList){
            Map<String,Object> member = (Map<String,Object>)memberObj; 
            
            membersByProgram = sortMemberByPlan(membersByProgram, member, shareSmartPrograms, shareAiddPrograms); 
        }
        System.debug(membersByProgram);

        Map< String, List<Map<String,Object>> > response = new Map< String, List<Map<String,Object>> >();
        //for(List<Map<String,Object>> membersList : membersByProgram.values()){
        for(String key : membersByProgram.keySet()){
            List<Map<String,Object>> membersListUpdated = new List<Map<String,Object>>();
            List<Map<String,Object>> membersList = membersByProgram.get(key); 

            Integer suscribers = membersList.size();
            Boolean includesPrimary = false;
            Boolean includesSpouse = false;
            Integer countChildren = 0;
            Integer maxgroupAge = 0;

            //first loop takes general group data
            for(Map<String,Object> member : membersList){
                String relationship = (String)member.get('CensusMemberRelationship');
                if(relationship == 'Primary'){
                    includesPrimary = true;
                } else if(relationship == 'Spouse'){
                    includesSpouse = true;
                } else {
                    countChildren = countChildren +1;
                }
                Integer memberAge = (Integer)member.get('RF_Census.CM_Age');
                if(memberAge > maxgroupAge){
                    maxgroupAge = memberAge;
                }
            }


            Boolean hasSpouse = false;
            if(includesSpouse && !includesPrimary){
                hasSpouse = false;
            } else if(includesSpouse && includesPrimary){
                hasSpouse = true;
            } else if(!includesSpouse && includesPrimary){
                hasSpouse = false;
            }

            String covSmart =getCoverageSmart(hasSpouse, suscribers,countChildren);
            String covAidd =getCoverageAidd(hasSpouse, suscribers,countChildren);
            for(Map<String,Object> member : membersList){
                Map<String,Object> memberUpdated = new Map<String,Object>(member);
                String name = (String)memberUpdated.get('CensusMemberName');
                String relationship = (String)memberUpdated.get('CensusMemberRelationship');
                
                if(includesSpouse && !includesPrimary && relationship == 'Spouse'){
                    memberUpdated.put('RF_Census.CM_IsPrimary', true);
                }
                memberUpdated.put('RF_Census.CRF_Coverage',covSmart);
                memberUpdated.put('RF_Census.CRF_CoverageAIDD', covAidd );
                memberUpdated.put('RF_Census.CRF_PrimaryMemberAge', maxgroupAge );
                memberUpdated.put('ProductCode', key );
                membersListUpdated.add(memberUpdated);
            }
            response.put(key, membersListUpdated);
        }

        outputMap.put('resp', response);


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


    private static Map<String, List<Map<String,Object>>> sortMemberByPlan(Map<String, List<Map<String,Object>> > membersByProgram, Map<String,Object> member, Boolean shareSmartPrograms, Boolean shareAiddPrograms){
        String SMARTrelationShipIdentifier;
        String AIDDrelationShipIdentifier;
        if (member.get('SMARTchildOf')!=null) {
            SMARTrelationShipIdentifier=(String)member.get('SMARTchildOf');
        }else {
            if (shareSmartPrograms) {
                SMARTrelationShipIdentifier = 'Primary';
            }else {
                SMARTrelationShipIdentifier = (String)member.get('CensusMemberRelationship');
            }
        }
        if (member.get('AIDDchildOf')!=null) {
            AIDDrelationShipIdentifier=(String)member.get('AIDDchildOf');
        }else {
            if (shareAiddPrograms) {
                AIDDrelationShipIdentifier = 'Primary';
            }else {
                AIDDrelationShipIdentifier = (String)member.get('CensusMemberRelationship');
            }
        }
        String selectedSmart = String.valueOf(member.get('codeSMART'));
        String selectedAidd = String.valueOf(member.get('codeAIDD'));
        if(selectedSmart != null){
            selectedSmart = selectedSmart +'|'+SMARTrelationShipIdentifier;
            if(membersByProgram.containsKey(selectedSmart)){
                membersByProgram.get(selectedSmart).add(member);
            }else{
                membersByProgram.put(selectedSmart, new List<Map<String,Object>>() );
                membersByProgram.get(selectedSmart).add(member);
            }
        }
                
        if(selectedAidd != null){
            selectedAidd = selectedAidd +'|'+AIDDrelationShipIdentifier;
            if(membersByProgram.containsKey(selectedAidd)){
                membersByProgram.get(selectedAidd).add(member);
            }else{
                membersByProgram.put(selectedAidd, new List<Map<String,Object>>() );
                membersByProgram.get(selectedAidd).add(member);
            }
        }

        return membersByProgram;
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

    public static Decimal countChildDependents(List<vlocity_ins__GroupCensusMember__c> censusMembers){
        Decimal childDependents = 0;
        for(vlocity_ins__GroupCensusMember__c cm : censusMembers){
            if(cm.ARC_DependentRelationship__c == 'Child' && cm.vlocity_ins__isprimarymember__c == false){
                childDependents++;
            }
        }
        return childDependents;
    }


    private static Map<Id, String> getCLIParent(List<vlocity_ins__GroupCensusMemberPlan__c> memberPlans){
        Map<Id, String> cliParent = new Map<Id, String>();

        for (vlocity_ins__GroupCensusMemberPlan__c memberPlan : memberPlans) {
            switch on memberPlan.vlocity_ins__GroupCensusMemberId__r.ARC_DependentRelationship__c {
                when null {
                    cliParent.put(memberPlan.vlocity_ins__ContractLineId__c, 'Primary');
                }
                when 'Spouse' {
                    if (cliParent.get(memberPlan.vlocity_ins__ContractLineId__c) == null) {
                        cliParent.put(memberPlan.vlocity_ins__ContractLineId__c, 'Spouse');
                    }
                }
            }
        }

        return cliParent;
    }
}