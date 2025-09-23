global without sharing class ARC_UpdateCensusMembersGuestUser implements vlocity_ins.VlocityOpenInterface {
    
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'updateCensusMembers') {
            updateCensusMembers(inputMap, outputMap, options);
        }
        return true;
    }

    public static void updateCensusMembers(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        List<Object> members = (List<Object>)inputMap.get('Members');
        List<Map<String,Object>> listOfMembers = new List<Map<String,Object>>();
        for (Object obj : members) {
            Map<String,Object> tempMap = (Map<String, Object>)obj;
            listOfMembers.add(tempMap);
        }

        String censusId = vlocity_ins.UserSecurity.decrypt(String.valueOf(inputMap.get('censusId')));
        // String censusId = /*vlocity_ins.UserSecurity.decrypt(*/String.valueOf(inputMap.get('censusId'))/*)*/;
        String userId = String.valueOf(inputMap.get('UserId'));

        Set<String> SetPrimaryMemberIds = new Set<String>();
        for (Map<String,Object> currentMember : listOfMembers) {
            for (String member : currentMember.keySet()) {
                String PriMemberId = String.valueOf(currentMember.get('vlocity_ins__PrimaryMemberIdentifier__c'));
                if (PriMemberId != null || PriMemberId != '') {
                    SetPrimaryMemberIds.add(PriMemberId);
                }
            }
        }
        
        Map<String, Id> MapPrimaryMemberIds = new Map<String, Id>();
        
        for (vlocity_ins__GroupCensusMember__c PriMember : [SELECT Id, vlocity_ins__MemberIdentifier__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__MemberIdentifier__c IN :SetPrimaryMemberIds]){
            MapPrimaryMemberIds.put(PriMember.vlocity_ins__MemberIdentifier__c,PriMember.Id);
        }
        
        List<vlocity_ins__GroupCensusMember__c> listPrimaryMembers = new List<vlocity_ins__GroupCensusMember__c>();
        List<vlocity_ins__GroupCensusMember__c> listCensusMembers = new List<vlocity_ins__GroupCensusMember__c>();
        
        for (Map<String,Object> currentMember : listOfMembers) {
            vlocity_ins__GroupCensusMember__c newCensusMember = new vlocity_ins__GroupCensusMember__c();
            newCensusMember.vlocity_ins__MemberIdentifier__c = String.valueOf(currentMember.get('vlocity_ins__MemberIdentifier__c'));
            Boolean IsPrimaryMember = Boolean.valueOf(currentMember.get('vlocity_ins__IsPrimaryMember__c'));
            newCensusMember.vlocity_ins__IsPrimaryMember__c = IsPrimaryMember;
            if (!IsPrimaryMember && MapPrimaryMemberIds.keySet().contains(String.valueOf(currentMember.get('vlocity_ins__PrimaryMemberIdentifier__c')))) {
                newCensusMember.vlocity_ins__RelatedCensusMemberId__c = MapPrimaryMemberIds.get(String.valueOf(currentMember.get('vlocity_ins__PrimaryMemberIdentifier__c')));
            }
            newCensusMember.vlocity_ins__PrimaryMemberIdentifier__c = String.valueOf(currentMember.get('vlocity_ins__PrimaryMemberIdentifier__c'));
            newCensusMember.vlocity_ins__FirstName__c = String.valueOf(currentMember.get('vlocity_ins__FirstName__c'));
            newCensusMember.vlocity_ins__LastName__c = String.valueOf(currentMember.get('vlocity_ins__LastName__c'));
            newCensusMember.vlocity_ins__Birthdate__c = Date.valueOf(String.valueOf(currentMember.get('vlocity_ins__Birthdate__c')));
            newCensusMember.ARC_DependentRelationship__c = String.valueOf(currentMember.get('ARC_DependentRelationship__c'));
            newCensusMember.vlocity_ins__Gender__c = String.valueOf(currentMember.get('vlocity_ins__Gender__c'));
            // newCensusMember.vlocity_ins__Email__c = String.valueOf(currentMember.get('vlocity_ins__Email__c'));
            newCensusMember.ARC_IgnoreMailing__c = Boolean.valueOf(currentMember.get('ARC_IgnoreMailing__c'));
            newCensusMember.ARC_UseParentAddress__c = Boolean.valueOf(currentMember.get('ARC_UseParentAddress__c'));
            newCensusMember.ARC_MailingAddressCity__c = String.valueOf(currentMember.get('ARC_MailingAddressCity__c'));
            newCensusMember.ARC_MailingAddressState__c = String.valueOf(currentMember.get('ARC_MailingAddressState__c'));
            newCensusMember.ARC_MailingAddressStreet__c = String.valueOf(currentMember.get('ARC_MailingAddressStreet__c'));
            // newCensusMember.ARC_MailingAddressStreet2__c = String.valueOf(currentMember.get('ARC_MailingAddressStreet2__c'));
            newCensusMember.ARC_MailingAddressZipCode__c = String.valueOf(currentMember.get('ARC_MailingAddressZipCode__c'));
            newCensusMember.ARC_PhysicalAddressCity__c = String.valueOf(currentMember.get('ARC_PhysicalAddressCity__c'));
            newCensusMember.ARC_PhysicalAddressState__c = String.valueOf(currentMember.get('ARC_PhysicalAddressState__c'));
            // newCensusMember.ARC_MailingAddressStreet2__c = String.valueOf(currentMember.get('ARC_MailingAddressStreet2__c'));
            newCensusMember.ARC_MailingAddressZipCode__c = String.valueOf(currentMember.get('ARC_MailingAddressZipCode__c'));
            newCensusMember.ARC_PhysicalAddressCity__c = String.valueOf(currentMember.get('ARC_PhysicalAddressCity__c'));
            newCensusMember.ARC_PhysicalAddressState__c = String.valueOf(currentMember.get('ARC_PhysicalAddressState__c'));
            newCensusMember.ARC_PhysicalAddressStreet__c = String.valueOf(currentMember.get('ARC_PhysicalAddressStreet__c'));
            // newCensusMember.ARC_PhysicalAddressStreet2__c = String.valueOf(currentMember.get('ARC_PhysicalAddressStreet2__c'));
            newCensusMember.ARC_PhysicalAddressZipCode__c = String.valueOf(currentMember.get('ARC_PhysicalAddressZipCode__c'));
            newCensusMember.vlocity_ins__IsSpouse__c = Boolean.valueOf(currentMember.get('vlocity_ins__IsSpouse__c'));

            newCensusMember.ARC_MiddleInitial__c = String.valueOf(currentMember.get('ARC_MiddleInitial__c'));
            newCensusMember.vlocity_ins__SocialSecurityNumber__c = String.valueOf(currentMember.get('vlocity_ins__SocialSecurityNumber__c'));
            newCensusMember.ARC_Smoker__c = Boolean.valueOf(currentMember.get('ARC_Smoker__c'));

            newCensusMember.ARC_Weight__c = String.valueOf(currentMember.get('ARC_Weight__c'));
            newCensusMember.ARC_HeightFeet__c = String.valueOf(currentMember.get('ARC_HeightFeet__c'));
            newCensusMember.ARC_HeightInches__c = String.valueOf(currentMember.get('ARC_HeightInches__c'));

            System.debug('error1234');
            // if (String.valueOf(currentMember.get('ARC_MedicalProduct__c')) != '') {
            //     newCensusMember.ARC_MedicalProduct__c = String.valueOf(currentMember.get('ARC_MedicalProduct__c'));
            // }
            // if (String.valueOf(currentMember.get('ARC_DentalProduct__c')) != '') {
            // newCensusMember.ARC_DentalProduct__c = String.valueOf(currentMember.get('ARC_DentalProduct__c'));
            // }
            // if (String.valueOf(currentMember.get('ARC_VisionProduct__c')) != '') {
            // newCensusMember.ARC_VisionProduct__c = String.valueOf(currentMember.get('ARC_VisionProduct__c'));
            // }
            if (currentMember.keySet().contains('Id')) {
                newCensusMember.Id = vlocity_ins.UserSecurity.decrypt(String.valueOf(currentMember.get('Id')));
                // newCensusMember.Id = /*vlocity_ins.UserSecurity.decrypt(*/String.valueOf(currentMember.get('Id'))/*)*/;
            } else if (!currentMember.keySet().contains('Id')) {
                newCensusMember.vlocity_ins__CensusId__c = String.valueOf(censusId);
            }

            if (IsPrimaryMember) {
                listPrimaryMembers.add(newCensusMember);
            } else {   
                listCensusMembers.add(newCensusMember);
            }
        }

        try {
            upsert listPrimaryMembers;
            upsert listCensusMembers;
        } catch (DmlException e) {
            system.debug('ERROR' + e);
        }

        List<vlocity_ins__GroupCensusMember__c> finalListCensusMembers = new List<vlocity_ins__GroupCensusMember__c>();
        finalListCensusMembers.addAll(listPrimaryMembers);
        finalListCensusMembers.addAll(listCensusMembers);

        Set<Id> censusMemberIds = new Set<Id>();
        for (vlocity_ins__GroupCensusMember__c member : finalListCensusMembers) {
            censusMemberIds.add(member.Id);
        }

        outputMap.put('members', finalListCensusMembers);
        outputMap.put('censusMemberIds', censusMemberIds);
    }
}