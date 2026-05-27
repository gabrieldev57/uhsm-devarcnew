/**
 * @Description: Utility class responsible for parsing input data, validating business rules 
 * (Fail Fast principle), and mapping the JSON structures into Salesforce sObjects 
 * (Account, GroupCensusMember, InsurancePolicyParticipant, ARC_CoverageParticipant__c) 
 * for the Temporary Newborn process.
 */
public without sharing class ARC_SGNBMapper {

    private ARC_SGNBManager manager; 
    
    /**
     * @Description: Main orchestration method for data extraction, validation, and mapping.
     * @param manager: The ARC_SGNBManager instance containing the context state.
     */
    public void manageMapper(ARC_SGNBManager manager) {
        this.manager = manager;
        try {
            getCensusMembers();
            getPolAndCLI();     

            mapAccounts();
            mapGCM();
            mapPolicyRelatedRecords();
        } catch (Exception e) {
            throw e;
        }
    }

    /**
     * @Description: Maps temporary newborn information into Account sObjects (Person Accounts).
     * Populates manager.mapAccToInsert.
     */
    private void mapAccounts() {
        try{
            Map<String, Object> primaryValue = manager.mapPrimaryInfo;

            //---------------------------------------------
            // Temporary Newborns Accounts
            //---------------------------------------------
            for (Map<String,Object> member : manager.listTemporaryNewborns) {
                Account newAccount = new Account();
                
                newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_SGPersonAccount').getRecordTypeId();
                newAccount.PersonBirthdate = member.containsKey('vlocity_ins__Birthdate__c') ? Date.valueOf((String)member.get('vlocity_ins__Birthdate__c')) : null;
                newAccount.IsActive = (newAccount.PersonBirthdate != null) && newAccount.PersonBirthdate.daysBetween(Date.today()) <= 30 ? true : false;
                newAccount.ARC_DependentRelationship__c = 'Temporary Newborn';
                newAccount.ARC_Census__c = primaryValue.containsKey('censusId') && primaryValue.get('censusId') != null ? (Id)primaryValue.get('censusId') : null;
                newAccount.FirstName = member.containsKey('vlocity_ins__FirstName__c') ? (String)member.get('vlocity_ins__FirstName__c') : null;
                newAccount.LastName = member.containsKey('vlocity_ins__LastName__c') ? (String)member.get('vlocity_ins__LastName__c') : null;
                newAccount.vlocity_ins__MiddleName__pc = member.containsKey('ARC_MiddleInitial__c') ? (String)member.get('ARC_MiddleInitial__c') : null;
                newAccount.PersonGender = member.containsKey('vlocity_ins__Gender__c') ? (String)member.get('vlocity_ins__Gender__c') : null;
                newAccount.vlocity_ins__SocialSecurityNumber__pc = member.containsKey('vlocity_ins__SocialSecurityNumber__c') ? (String)member.get('vlocity_ins__SocialSecurityNumber__c') : null;
                String height = null;
                Object feetObj = member.containsKey('ARC_HeightFeet__c') ? member.get('ARC_HeightFeet__c') : null;
                Object inchesObj = member.containsKey('ARC_HeightInches__c') ? member.get('ARC_HeightInches__c') : null;
                String feetStr = null;
                String inchesStr = null;
                try { if (feetObj != null && String.valueOf(feetObj).trim() != '') feetStr = String.valueOf(Integer.valueOf(String.valueOf(feetObj))); } catch (Exception e) { }
                try { if (inchesObj != null && String.valueOf(inchesObj).trim() != '') inchesStr = String.valueOf(Integer.valueOf(String.valueOf(inchesObj))); } catch (Exception e) { }
                if (feetStr != null) {
                    height = feetStr + '\'';
                }
                if (inchesStr != null) {
                    if (height != null) height += inchesStr;
                    else height = '\'' + inchesStr;
                }
                newAccount.ARC_Height__c = height;
                newAccount.ARC_Weight__c = member.containsKey('ARC_Weight__c') && member.get('ARC_Weight__c') != null && String.valueOf(member.get('ARC_Weight__c')).trim() != '' ? String.valueOf(Integer.valueOf(String.valueOf(member.get('ARC_Weight__c')))) : null;
                
                manager.mapAccToInsert.put((String)member.get('Id') , newAccount);
            }
        }
        catch(Exception e){
            throw new IllegalArgumentException('Error mapping person accounts: ' + e.getLineNumber() + ' ' + e.getMessage());
        }
    }

    /**
     * @Description: Maps temporary newborn information into vlocity_ins__GroupCensusMember__c sObjects.
     * Populates manager.mapGCMToInsert.
     */
    private void mapGCM() { 
        try{
            Map<String, Object> primaryValue = manager.mapPrimaryInfo;

            Map<String, vlocity_ins__GroupCensusMember__c> fakeIdToGcm = new Map<String, vlocity_ins__GroupCensusMember__c>();

            //---------------------------------------------
            // Temporary Newborns Census Members
            //---------------------------------------------
            for (Map<String,Object> member : manager.listTemporaryNewborns) {
                vlocity_ins__GroupCensusMember__c newGCM = new vlocity_ins__GroupCensusMember__c();

                newGCM.vlocity_ins__RelatedCensusMemberId__c = primaryValue.containsKey('Id') && primaryValue.get('Id') != null ? (Id)primaryValue.get('Id') : null;
                newGCM.vlocity_ins__PrimaryMemberIdentifier__c = primaryValue.containsKey('vlocity_ins__MemberIdentifier__c') && primaryValue.get('vlocity_ins__MemberIdentifier__c') != null ? (String)primaryValue.get('vlocity_ins__MemberIdentifier__c') : null;
                newGCM.vlocity_ins__CensusId__c = primaryValue.containsKey('censusId') && primaryValue.get('censusId') != null ? (Id)primaryValue.get('censusId') : null;
                newGCM.ARC_DependentRelationship__c = 'Temporary Newborn';
                newGCM.vlocity_ins__IsPrimaryMember__c = false;
                newGCM.vlocity_ins__IsSpouse__c = false;
                newGCM.vlocity_ins__Birthdate__c = member.containsKey('vlocity_ins__Birthdate__c') ? Date.valueOf((String)member.get('vlocity_ins__Birthdate__c')) : null;
                newGCM.ARC_ActiveMember__c = (newGCM.vlocity_ins__Birthdate__c != null) && (newGCM.vlocity_ins__Birthdate__c.daysBetween(Date.today()) <= 30) ? true : false;

                newGCM.vlocity_ins__FirstName__c = member.containsKey('vlocity_ins__FirstName__c') ? (String)member.get('vlocity_ins__FirstName__c') : null;
                newGCM.vlocity_ins__LastName__c = member.containsKey('vlocity_ins__LastName__c') ? (String)member.get('vlocity_ins__LastName__c') : null;
                if (newGCM.vlocity_ins__FirstName__c != null && newGCM.vlocity_ins__LastName__c != null) {
                    newGCM.Name = newGCM.vlocity_ins__FirstName__c + ' ' + newGCM.vlocity_ins__LastName__c;
                }
                
                newGCM.ARC_MiddleInitial__c = member.containsKey('ARC_MiddleInitial__c') ? (String)member.get('ARC_MiddleInitial__c') : null;
                newGCM.vlocity_ins__Gender__c = member.containsKey('vlocity_ins__Gender__c') ? (String)member.get('vlocity_ins__Gender__c') : null;
                newGCM.vlocity_ins__SocialSecurityNumber__c = member.containsKey('vlocity_ins__SocialSecurityNumber__c') ? (String)member.get('vlocity_ins__SocialSecurityNumber__c') : null;
                newGCM.ARC_HeightFeet__c = member.containsKey('ARC_HeightFeet__c') ? member.get('ARC_HeightFeet__c') != null && member.get('ARC_HeightFeet__c') != '' ? String.valueOf(Integer.valueOf(member.get('ARC_HeightFeet__c'))) : null : null ;
                newGCM.ARC_HeightInches__c = member.containsKey('ARC_HeightInches__c') ? member.get('ARC_HeightInches__c') != null && member.get('ARC_HeightInches__c') != '' ? String.valueOf(Integer.valueOf(member.get('ARC_HeightInches__c'))) : null : null ;
                newGCM.ARC_Weight__c = member.containsKey('ARC_Weight__c') ? member.get('ARC_Weight__c') != null && member.get('ARC_Weight__c') != '' ? String.valueOf(Integer.valueOf(member.get('ARC_Weight__c'))) : null : null;

                newGCM.ARC_PhysicalAddressCity__c = primaryValue.containsKey('ARC_PhysicalAddressCity__c') ? (String)primaryValue.get('ARC_PhysicalAddressCity__c') : null;
                newGCM.ARC_PhysicalAddressState__c = primaryValue.containsKey('ARC_PhysicalAddressState__c') ? (String)primaryValue.get('ARC_PhysicalAddressState__c') : null;
                newGCM.ARC_PhysicalAddressStreet__c = primaryValue.containsKey('ARC_PhysicalAddressStreet__c') ? (String)primaryValue.get('ARC_PhysicalAddressStreet__c') : null;
                newGCM.ARC_PhysicalAddressZipCode__c = primaryValue.containsKey('ARC_PhysicalAddressZipCode__c') ? (String)primaryValue.get('ARC_PhysicalAddressZipCode__c') : null;
                
                manager.mapGCMToInsert.put((String)member.get('Id'), newGCM);
            }  
        }
        catch(Exception e){
            throw new IllegalArgumentException('Error mapping GCM: ' + e.getLineNumber() + ' ' + e.getMessage());
        }
    }

    /**
     * @Description: Maps Policy Participant and Coverage Participant records for newborns.
     * Populates manager.mapPolIdToPolPart and manager.mapPolIdToCovPart.
     */
    private void mapPolicyRelatedRecords() {
        try {
            if (!manager.listPol.isEmpty()) {
                Date firstDate = manager.oldestNewbornBirthdate;
                Date lastDate = manager.youngestNewbornBirthdate + 30;

                for (InsurancePolicy ip : manager.listPol) {
                    for (String fakeId : manager.mapAccToInsert.keySet()) {

                        //---------------------------------------------
                        // Temporary Newborns Policy Participant
                        //---------------------------------------------
                        InsurancePolicyParticipant newPolPart = new InsurancePolicyParticipant();
                        newPolPart.InsurancePolicyId = ip.Id;
                        newPolPart.Role = 'Dependent';
                        newPolPart.WP_Cancer__c = ((Account)manager.mapAccToInsert.get(fakeId)).PersonBirthdate;
                        newPolPart.WP_Colon__c = ((Account)manager.mapAccToInsert.get(fakeId)).PersonBirthdate;
                        newPolPart.WP_Glacoma__c = ((Account)manager.mapAccToInsert.get(fakeId)).PersonBirthdate;
                        newPolPart.WP_Immunizations__c = ((Account)manager.mapAccToInsert.get(fakeId)).PersonBirthdate;
                        newPolPart.WP_Normal__c = ((Account)manager.mapAccToInsert.get(fakeId)).PersonBirthdate;
                        newPolPart.WP_Pre_Ex__c = ((Account)manager.mapAccToInsert.get(fakeId)).PersonBirthdate;
                        if(((Account)manager.mapAccToInsert.get(fakeId)).ARC_DependentRelationship__c == 'Temporary Newborn'){
                            newPolPart.RelationshipToInsured = 'Temporary Newborn';
                        }
                        if (ip.Status == 'Terminated') {
                            if (ip.ARC_PolicyExpirationDate__c < lastDate) {
                                newPolPart.ARC_EndDate__c = ip.ARC_PolicyExpirationDate__c;
                            } else {
                                newPolPart.ARC_EndDate__c = lastDate;
                            }
                            if (ip.ARC_PolicyEffectiveDate__c < firstDate) {
                                newPolPart.ARC_StartDate__c = firstDate;
                            } else {
                                newPolPart.ARC_StartDate__c = ip.ARC_PolicyEffectiveDate__c;
                            }
                        } else {
                            if (ip.ARC_PolicyEffectiveDate__c < firstDate) {
                                newPolPart.ARC_StartDate__c = firstDate;
                                newPolPart.ARC_EndDate__c = lastDate;
                            } else {
                                newPolPart.ARC_StartDate__c = ip.ARC_PolicyEffectiveDate__c;
                                newPolPart.ARC_EndDate__c = lastDate;
                            }    
                        }

                        Map<String, InsurancePolicyParticipant> innerMapPolPart = manager.mapPolIdToPolPart.containsKey(ip.Id) ? manager.mapPolIdToPolPart.get(ip.Id) : new Map<String, InsurancePolicyParticipant>();
                        innerMapPolPart.put(fakeId, newPolPart);
                        manager.mapPolIdToPolPart.put(ip.Id, innerMapPolPart);

                        //---------------------------------------------
                        // Temporary Newborns Coverage Participant
                        //---------------------------------------------
                        ARC_CoverageParticipant__c newCoverPart = new ARC_CoverageParticipant__c();
                        newCoverPart.ARC_Policy__c = ip.Id;
                        newCoverPart.ARC_PolicyCoverage__c = manager.mapPolIdToMotherCovPartId.get(ip.Id);
                        newCoverPart.ARC_CoverageRole__c = 'Dependent';
                        
                        Map<String, ARC_CoverageParticipant__c> innerMapCovPart = manager.mapPolIdToCovPart.containsKey(ip.Id) ? manager.mapPolIdToCovPart.get(ip.Id) : new Map<String, ARC_CoverageParticipant__c>();
                        innerMapCovPart.put(fakeId, newCoverPart);
                        manager.mapPolIdToCovPart.put(ip.Id, innerMapCovPart);
                    }
                }
            }
        } catch (Exception e) {
            throw new IllegalArgumentException('Error mapping Policy/Coverage Participants: ' + e.getMessage());
        }
    }

    ///////////////////////
    // Helper Methods
    ///////////////////////    

    /**
     * @Description: Extracts temporary newborn data from the OmniScript payload,
     * calculates the oldest and youngest birthdates, and validates that the dates
     * do not differ by 2 or more days.
     * @throws ARC_SGNBManager.InvalidTwinBirthdateException if dates differ by >= 2 days.
     */
    private void getCensusMembers() {
        Map<String, Object> stepAddNewborn = manager.inputMap.containsKey('STEP_AddNewborn') && manager.inputMap.get('STEP_AddNewborn') != null ? (Map<String, Object>)manager.inputMap.get('STEP_AddNewborn') : null;
        List<Object> tempNewborns = new List<Object>();
        
        if (stepAddNewborn != null && stepAddNewborn.containsKey('EB_TemporaryNewborn') && stepAddNewborn.get('EB_TemporaryNewborn') != null) {
            Object ebData = stepAddNewborn.get('EB_TemporaryNewborn');
            if (ebData instanceof List<Object>) {
                tempNewborns = (List<Object>)ebData;
            } else if (ebData instanceof Map<String, Object>) {
                tempNewborns.add(ebData);
            }
        }

        Date minDate = null;
        Date maxDate = null;

        for (Object newborn : tempNewborns) {
            Map<String,Object> member = (Map<String,Object>)newborn; 
            
            manager.listTemporaryNewborns.add(member);
            
            if (member.containsKey('vlocity_ins__Birthdate__c') && member.get('vlocity_ins__Birthdate__c') != null) {
                Date bDate = Date.valueOf((String)member.get('vlocity_ins__Birthdate__c'));
                if (minDate == null || bDate < minDate) minDate = bDate;
                if (maxDate == null || bDate > maxDate) maxDate = bDate;
            }
        }

        manager.oldestNewbornBirthdate = minDate;
        manager.youngestNewbornBirthdate = maxDate;

        //-------------------------------------------------------------------
        // Validate if Newborns’ birthdates are differ by more than one day
        //-------------------------------------------------------------------
        if (minDate != null && maxDate != null) {
            Integer daysDifference = minDate.daysBetween(maxDate);
            if (daysDifference >= 2) {
                throw new ARC_SGNBManager.InvalidTwinBirthdateException('Newborns birthdate difference exceeds 1 day');
            }
        }
    }

    /**
     * @Description: Queries the Context Account, related Primary Member Info, and related Policies.
     * Extracts policies where a Female Primary or Spouse is present (mothers).
     * @throws ARC_SGNBManager.NoMotherPolicyException if no valid mother policies are found.
     */
    private void getPolAndCLI() {
        Date firstDate = manager.oldestNewbornBirthdate;
        Date lastDate = manager.youngestNewbornBirthdate + 30;
        String accountId = manager.inputMap.containsKey('ContextId') && manager.inputMap.get('ContextId') != null ? (String)manager.inputMap.get('ContextId') : null;
        String primaryAccId = null;

        Account acc = [
            SELECT 
                Id, 
                ARC_IsPrimaryMember__c, 
                ARC_Census__c,
                Census_Member__c,
                Census_Member__r.vlocity_ins__MemberIdentifier__c,
                Census_Member__r.ARC_PhysicalAddressCity__c,
                Census_Member__r.ARC_PhysicalAddressState__c,
                Census_Member__r.ARC_PhysicalAddressStreet__c,
                Census_Member__r.ARC_PhysicalAddressZipCode__c,
                ARC_PrimaryMemberAccount__c, 
                ARC_PrimaryMemberAccount__r.ARC_Census__c,
                ARC_PrimaryMemberAccount__r.Census_Member__c,
                ARC_PrimaryMemberAccount__r.Census_Member__r.vlocity_ins__MemberIdentifier__c,
                ARC_PrimaryMemberAccount__r.Census_Member__r.ARC_PhysicalAddressCity__c,
                ARC_PrimaryMemberAccount__r.Census_Member__r.ARC_PhysicalAddressState__c,
                ARC_PrimaryMemberAccount__r.Census_Member__r.ARC_PhysicalAddressStreet__c,
                ARC_PrimaryMemberAccount__r.Census_Member__r.ARC_PhysicalAddressZipCode__c
            FROM Account 
            WHERE Id =:accountId
            LIMIT 1
        ];

        if (acc?.ARC_IsPrimaryMember__c) {
            primaryAccId = acc?.Id;
        } else {
            primaryAccId = acc.ARC_PrimaryMemberAccount__c;
        }

        //---------------------------------------------
        // Map of Primary Member Info
        //---------------------------------------------
        manager.mapPrimaryInfo = new Map<String, Object> {
            'Id' => acc?.ARC_IsPrimaryMember__c ? acc?.Census_Member__c : acc?.ARC_PrimaryMemberAccount__r.Census_Member__c,
            'censusId' => acc?.ARC_IsPrimaryMember__c ? acc?.ARC_Census__c : acc?.ARC_PrimaryMemberAccount__r.ARC_Census__c,
            'vlocity_ins__MemberIdentifier__c' => acc?.ARC_IsPrimaryMember__c ? acc?.Census_Member__r.vlocity_ins__MemberIdentifier__c : acc?.ARC_PrimaryMemberAccount__r.Census_Member__r.vlocity_ins__MemberIdentifier__c,
            'ARC_PhysicalAddressCity__c' => acc?.ARC_IsPrimaryMember__c ? acc?.Census_Member__r.ARC_PhysicalAddressCity__c : acc?.ARC_PrimaryMemberAccount__r.Census_Member__r.ARC_PhysicalAddressCity__c,
            'ARC_PhysicalAddressState__c' => acc?.ARC_IsPrimaryMember__c ? acc?.Census_Member__r.ARC_PhysicalAddressState__c : acc?.ARC_PrimaryMemberAccount__r.Census_Member__r.ARC_PhysicalAddressState__c,
            'ARC_PhysicalAddressStreet__c' => acc?.ARC_IsPrimaryMember__c ? acc?.Census_Member__r.ARC_PhysicalAddressStreet__c : acc?.ARC_PrimaryMemberAccount__r.Census_Member__r.ARC_PhysicalAddressStreet__c,
            'ARC_PhysicalAddressZipCode__c' => acc?.ARC_IsPrimaryMember__c ? acc?.Census_Member__r.ARC_PhysicalAddressZipCode__c : acc?.ARC_PrimaryMemberAccount__r.Census_Member__r.ARC_PhysicalAddressZipCode__c
        };  

        //---------------------------------------------
        // List of all related Policies
        //---------------------------------------------
        List<InsurancePolicy> listIPRelated = null;
        if (primaryAccId != null) {
            listIPRelated = [
                SELECT Id, NameInsuredId, Status, ARC_PolicyExpirationDate__c,ARC_PolicyEffectiveDate__c,
                    (
                        SELECT Id, 
                        ARC_PolicyParticipant__r.Role, 
                        ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.PersonGender, 
                        ARC_PolicyCoverage__r.Id
                        FROM CoverageParticipants__r
                        WHERE (
                            ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__RecordTypeName__c ='Product' AND ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c ='Medical'
                        )
                    )
                FROM InsurancePolicy 
                WHERE 
                    NameInsuredId =: primaryAccId 
                    AND Status NOT IN ('Draft','Voided')
                    AND (
                        (Status = 'Terminated' AND ARC_PolicyEffectiveDate__c <= :lastDate AND ARC_PolicyExpirationDate__c >= :firstDate)
                        OR
                        (Status != 'Terminated' AND ARC_PolicyEffectiveDate__c <= :lastDate)
                    )
                ORDER BY CreatedDate ASC
            ];
        }

        //---------------------------------------------
        // List of related Policies with mothers
        //---------------------------------------------
        for (InsurancePolicy ip : listIPRelated) {
            Integer i = 0;
            for (ARC_CoverageParticipant__c cp : ip.CoverageParticipants__r) {
                if ((cp?.ARC_PolicyParticipant__r?.Role == 'Primary' || cp?.ARC_PolicyParticipant__r?.Role == 'Spouse') && cp?.ARC_PolicyParticipant__r?.PrimaryParticipantContact?.Account?.PersonGender == 'Female') {
                    manager.listPol.add(ip); 
                    manager.mapPolIdToMotherCovPartId.put(ip?.Id, cp?.ARC_PolicyCoverage__r?.Id);
                    break;
                }
            }
        }

        //-------------------------------------------------------------------
        // Validate if policies have mothers
        //-------------------------------------------------------------------
        if (manager.listPol.isEmpty()) {
            throw new ARC_SGNBManager.NoMotherPolicyException('No mother policy found');
        }
    }
}