global without sharing class ARC_GetMembersForRepriceCase implements vlocity_ins.VlocityOpenInterface2 {

    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'getApprovedMembers') {
            getApprovedMembers(inputMap, outputMap, options);
        }
        return true;
    }

    global static void getApprovedMembers(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {        

        String changeReason = (String)inputMap.get('changeReason');
        Map<String, Object> docuSignData = (Map<String, Object>)inputMap.get('DocuSignData');
        List<Object> userInputs = (List<Object>)inputMap.get('userInputs');
        Object rejectedMemberIdsObj = inputMap.get('RejectedMemberIds');
        List<Map<String, Object>> userInputsMaps = new List<Map<String, Object>>();
        Set<Id> censusMemberIds = new Set<Id>();
        Map<Id, String> censusMapRelationship = new Map<Id, String>();
        List<String> rejectedMembersList = new List<String>();
        List<String> approvedMembersList = new List<String>();
        List<Object> rejectedMemberIds = new List<Object>();
        Boolean futurePrimaryExist = false; //true when there is a new member with a relaitonship of "Future Primary"

        if(rejectedMemberIdsObj != null && rejectedMemberIdsObj != ''){
            rejectedMemberIds = (List<Object>)rejectedMemberIdsObj;
        }

        for(Object user : userInputs){
            Map<String,Object> u = (Map<String,Object>)user;
            userInputsMaps.add(u);
            if((String)u.get('CensusMemberRelationship') == 'Future Primary'){
                futurePrimaryExist = true;
            }
        }


        
        if(futurePrimaryExist){
            userInputs = ARC_PCAncillaryUserInputs.getFuturePrimaryUserInputs(userInputsMaps);
        }
        

        for (Object user : userInputs) {
            Map<String,Object> u = (Map<String,Object>)user;
            censusMemberIds.add((String)u.get('CensusMemberId'));
            censusMapRelationship.put((String)u.get('CensusMemberId'), (Boolean)u.get('RF_Census.CM_IsPrimary') ? 'Primary' : (Boolean)u.get('RF_Census.CM_IsSpouse') ? 'Spouse' : 'Child');
            System.debug(u.get('CensusMemberName'));
            System.debug(u.get('CensusMemberRelationship'));
            System.debug((Boolean)u.get('RF_Census.CM_IsPrimary') ? 'Primary' : (Boolean)u.get('RF_Census.CM_IsSpouse') ? 'Spouse' : 'Child');
        }     
        
        Map<String,Object> changeList = new Map<String,Object>();
        List<Map<String, Object>> dependentsList = new List<Map<String, Object>>();
        for ( vlocity_ins__GroupCensusMember__c m : [ SELECT id,vlocity_ins__censusid__c,name,arc_dependentrelationship__c,vlocity_ins__isprimarymember__c,vlocity_ins__isspouse__c,arc_smoker__c,vlocity_ins__socialsecuritynumber__c,arc_height__c,arc_weight__c,arc_middleinitial__c,vlocity_ins__birthdate__c,vlocity_ins__firstname__c,vlocity_ins__lastname__c,vlocity_ins__gender__c,arc_physicaladdresscity__c,arc_physicaladdressstreet__c,arc_physicaladdresszipcode__c,arc_physicaladdressstate__c,vlocity_ins__email__c,arc_age__c,arc_phone__c,arc_ispregnant__c,Member_ID__c, e123_member_id_from_policy__c FROM vlocity_ins__GroupCensusMember__c WHERE Id IN :censusMemberIds ] ) {
            
            Map<String,Object> memberData = new Map<String,Object>();
            
            memberData.put('isSmoker', m.arc_smoker__c);
            memberData.put('SocialSecurity', m.vlocity_ins__socialsecuritynumber__c);
            memberData.put('Height', m.arc_height__c);
            memberData.put('Weight', m.arc_weight__c);
            memberData.put('MI', m.arc_middleinitial__c);
            memberData.put('DOB', m.vlocity_ins__birthdate__c);
            memberData.put('Gender', m.vlocity_ins__gender__c);
            memberData.put('FirstName', m.vlocity_ins__firstname__c);
            memberData.put('LastName', m.vlocity_ins__lastname__c);
            memberData.put('Name', m.name);
            memberData.put('Id', m.Id);
            memberData.put('isPregnant', m.arc_ispregnant__c);
            memberData.put('internalId', m.e123_member_id_from_policy__c != null ? m.e123_member_id_from_policy__c : m.Member_ID__c);


            if ( censusMapRelationship.get(m.Id) == 'Primary' ) {
                System.debug(m.Name);
                memberData.put('City', m.arc_physicaladdresscity__c);
                memberData.put('Address', m.arc_physicaladdressstreet__c);
                memberData.put('ZipCode', m.arc_physicaladdresszipcode__c);
                memberData.put('State', m.arc_physicaladdressstate__c);
                memberData.put('Email', m.vlocity_ins__email__c);
                memberData.put('Phone', m.arc_phone__c);

                memberData.put('DayOfBirth', ((Map<String,Object>)docuSignData.get('Primary'))?.get('DayOfBirth'));
                memberData.put('MonthOfBirth', ((Map<String,Object>)docuSignData.get('Primary'))?.get('MonthOfBirth'));
                memberData.put('YearOfBirth', ((Map<String,Object>)docuSignData.get('Primary'))?.get('YearOfBirth'));
                
                docuSignData.put(censusMapRelationship.get(m.Id), memberData);
            } else if ( censusMapRelationship.get(m.Id) == 'Spouse' ) {
                if ( changeReason != 'Add Member' && changeReason != 'Add Newborn' ) {
                    docuSignData.put(censusMapRelationship.get(m.Id), memberData);
                }
            } else {
                if ( changeReason != 'Add Member' && changeReason != 'Add Newborn' ) {
                    System.debug(m.Name);
                    dependentsList.add(memberData);
                }
            }

            approvedMembersList.add(m.name);
        }
        
        if(rejectedMemberIds != null){
            List<String> rejectedMemberIdsStr = new List<String>();
            for(Object id : rejectedMemberIds){
                String idStr = (String)id;
                rejectedMemberIdsStr.add(idStr);
            }
            for ( vlocity_ins__GroupCensusMember__c m : [ SELECT id,name FROM vlocity_ins__GroupCensusMember__c WHERE Id IN :rejectedMemberIdsStr ] ) {
                rejectedMembersList.add(m.name);
            }
        }

        if ( !dependentsList.isEmpty() ) {
            docuSignData.put('Dependents', dependentsList);
        }

        outputMap.put('RejectedMemberList', rejectedMembersList);
        outputMap.put('ApprovedMemberList', approvedMembersList);
        outputMap.put('DocuSignData', docuSignData);
    }

}