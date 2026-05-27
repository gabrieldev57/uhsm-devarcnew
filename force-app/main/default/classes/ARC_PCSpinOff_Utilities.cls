public with sharing class ARC_PCSpinOff_Utilities {

    private static integer daysToAdd = 60;
    
    public static Map<String,Object> TRANSFORM_CensusMemberToUserInputs(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        System.debug('inputMap: ' + inputMap);
        List<Object> census_members = new List<Object>();
        
        try {
            // Get the census component which contains the census members
            Object censusComponentObj = inputMap.get('census_component');
            if (censusComponentObj != null) {
                Map<String,Object> censusComponent = (Map<String,Object>)censusComponentObj;
                Object membersObj = censusComponent.get('census_members');
                if (membersObj != null) {
                    census_members = (List<Object>)membersObj;
                    System.debug('Found ' + census_members.size() + ' census members');
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing census component: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }
        
        if (census_members == null) {
            census_members = new List<Object>();
            System.debug(LoggingLevel.WARN, 'No census members found in input map');
        }
        
        List<Map<String, Object>> user_input_list = new List<Map<String, Object>>();

        Boolean hasPrimary = false;
        Boolean hasSpouse = false;
        Integer dependentCount = 0;
        Integer oldestAge = 0;
        String primaryDOB = null;        
        Date effectiveDate;

        String dateStr = (String)inputMap.get('EffectiveDate');
        if(String.isNotBlank(dateStr)) {
            try {
                // Handle both MM/DD/YYYY and YYYY-MM-DD formats
                if(dateStr.contains('-')) {
                    effectiveDate = Date.valueOf(dateStr);
                } else {
                    effectiveDate = Date.parse(dateStr);
                }
            } catch(Exception e) {
                System.debug('Error parsing date: ' + dateStr + ' - ' + e.getMessage());
                throw new AuraHandledException('Invalid date format: ' + dateStr);
            }
        }

        for (Object cm_object : census_members) {
            Map<String,Object> census_member = (Map<String,Object>)cm_object;
            if((String)census_member.get('ARC_Relationship__c') == 'Primary') {
                primaryDOB = (String)census_member.get('vlocity_ins__Birthdate__c');
            }
        }

        for (Object cm_object : census_members) {
            Map<String,Object> census_member = (Map<String,Object>)cm_object;
            Map<String, Object> user_input = new Map<String, Object>();

            if ((Boolean)census_member.get('IsRemoveMember') == false) {
                Integer age;
                if (effectiveDate != null){
                    age = calculateAge(Date.valueOf((String)census_member.get('vlocity_ins__Birthdate__c')),effectiveDate.addDays(daysToAdd));
                }
                else age = (Integer)census_member.get('ARC_Age__c');
              
                // Track oldest age
                if (age > oldestAge) {
                    oldestAge = age;
                }
                user_input.put('RF_Census.CM_Age', age);
                user_input.put('RF_Census.CRF_PrimaryMemberDOB', primaryDOB);
                user_input.put('RF_Census.CM_State', census_member.get('ARC_PhysicalAddressState__c'));
                user_input.put('RF_Census.CM_IsPrimary', (String)census_member.get('ARC_Relationship__c') == 'Primary' ? true : false);
                user_input.put('RF_Census.CM_Relationship', census_member.get('ARC_Relationship__c'));
                user_input.put('RF_Census.CM_Smoker', (census_member.get('ARC_Smoker__c') instanceof Boolean && (Boolean)census_member.get('ARC_Smoker__c') == true) ? true : false);
                user_input.put('RF_Census.CM_Pregnant', (census_member.get('ARC_isPregnant__c') instanceof Boolean && (Boolean)census_member.get('ARC_isPregnant__c') == true) ? true : false);
                user_input.put('RF_Census.CM_FirstName', census_member.get('vlocity_ins__FirstName__c'));
                user_input.put('RF_Census.CM_LastName', census_member.get('vlocity_ins__LastName__c'));
                user_input.put('IsRemoveMember', census_member.get('IsRemoveMember'));
                user_input.put('IsNewMember', census_member.get('IsNewMember'));
                user_input.put('IsAddExistingMember', (census_member.get('IsNewMember') instanceof Boolean && (Boolean)census_member.get('IsNewMember') == false) && (census_member.get('IsInactiveMember') instanceof Boolean && (Boolean)census_member.get('IsInactiveMember') == true) ? true : false);
                user_input.put('Id', census_member.get('Id'));

                user_input_list.add(user_input);
                
                String relationship = (String)census_member.get('ARC_Relationship__c');
                if (relationship == 'Primary') {
                    hasPrimary = true;
                } else {
                    dependentCount++;
                    if (relationship == 'Spouse') {
                        hasSpouse = true;
                    }
                }
            }
        }
        
        // Sort the list: Primary first, Spouse second, Child last
        user_input_list.sort(new RelationshipComparator());

        Integer extraDependents = Math.max(dependentCount - 3, 0);
        String aidd = 'Family';
        String smart = 'Family';
        Integer user_input_list_size = user_input_list.size();

        if (hasPrimary && user_input_list_size == 1) {
            aidd = 'Primary';
            smart = 'Primary';
        } else if (hasPrimary && hasSpouse && user_input_list_size == 2) {
            aidd = 'Primary + Spouse';
            smart = 'Primary + Spouse';
        } else if (hasPrimary && !hasSpouse && user_input_list_size > 1) {
            aidd = 'Primary + Children';
            smart = 'Primary + Child';
        }

        for (Object ui_object : user_input_list) {
            Map<String,Object> user_input = (Map<String,Object>)ui_object;
            user_input.put('RF_Census.CRF_Coverage', smart);
            user_input.put('RF_Census.CRF_CoverageAIDD', aidd);
            user_input.put('RF_Census.CRF_ExtraDependants', extraDependents);
            user_input.put('RF_Census.CRF_PrimaryMemberAge', oldestAge);
            user_input.put('RF_Census.CRF_Dependants', dependentCount);
        }
        System.debug('Llego');

        outputMap.put('userInputs', user_input_list);
        return outputMap;
    }

    public static Map<String, Object>  getMemberBeneficiaries (Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        String contractId = (String)((Map<String,Object>)inputMap.get('SelectedContractInfo')).get('ExpiredContract');

        List<Object> censusMemberList = inputMap.containsKey('census_component') 
                && ((Map<String, Object>)inputMap.get('census_component')).containsKey('census_members') 
                && ((Map<String, Object>)inputMap.get('census_component')).get('census_members') != null 
            ? (List<Object>)((Map<String, Object>)inputMap.get('census_component')).get('census_members') 
            : new List<Object>();
        Boolean premierSelected = inputMap.get('premierSelected') instanceof Boolean ? (Boolean)inputMap.get('premierSelected') : false;

        List<ARC_CoverageParticipant__c> coverageParticipantList = [
            SELECT Id, ARC_PrimaryBeneficiaryName__c, ARC_PrimaryBeneficiaryBirthdate__c, ARC_PrimaryBeneficiaryPhone__c, ARC_PrimaryBeneficiaryRelationship__c, ARC_PrimaryBeneficiaryOther__c, ARC_SecondaryBeneficiaryName__c, ARC_SecondaryBeneficiaryBirthdate__c, ARC_SecondaryBeneficiaryPhone__c, ARC_SecondaryBeneficiaryRelationship__c, ARC_SecondaryBeneficiaryOther__c, ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId
            FROM ARC_CoverageParticipant__c
            WHERE ARC_Policy__r.ARC_Contract__c = :contractId AND ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c = 'Medical'];

        Map<String, ARC_CoverageParticipant__c> memberToCoveragePartMap = new Map<String, ARC_CoverageParticipant__c>();
        if (coverageParticipantList != null && !coverageParticipantList.isEmpty()) {
            for (ARC_CoverageParticipant__c covPart : coverageParticipantList) {
                String memberId = covPart.ARC_PolicyParticipant__r?.PrimaryParticipantContact?.AccountId;
                if (memberId != null && !memberToCoveragePartMap.containsKey(memberId)) memberToCoveragePartMap.put(memberId, covPart);
            }
        }
        
        if (censusMemberList != null && !censusMemberList.isEmpty()) {
            List<Object> finalMemberList = new List<Object>();
            for (Object member : censusMemberList) {
                Map<String, Object> memberMap = (Map<String, Object>)member;
                String memberAccountId = (String)memberMap.get('PersonAccountId');
                List<Object> memberBeneficiariesList = new List<Object>();
                if (premierSelected && memberToCoveragePartMap.get(memberAccountId) != null) {
                    ARC_CoverageParticipant__c memberCovPart = memberToCoveragePartMap.get(memberAccountId);
                    if (memberCovPart.ARC_PrimaryBeneficiaryName__c != null && memberCovPart.ARC_PrimaryBeneficiaryName__c != '') {
                        Map<String, Object> primaryBenefMap = new Map<String, Object>{
                            'Id' => String.valueOf(memberCovPart.Id + '-primary'),
                            'Label' => 'Primary Beneficiary',
                            'BeneficiaryName' => String.valueOf(memberCovPart.ARC_PrimaryBeneficiaryName__c),
                            'BeneficiaryBirthdate' => String.valueOf(memberCovPart.ARC_PrimaryBeneficiaryBirthdate__c),
                            'BeneficiaryPhone' => String.valueOf(memberCovPart.ARC_PrimaryBeneficiaryPhone__c),
                            'BeneficiaryRelationship' => String.valueOf(memberCovPart.ARC_PrimaryBeneficiaryRelationship__c),
                            'BeneficiaryOtherRelationship' => String.valueOf(memberCovPart.ARC_PrimaryBeneficiaryOther__c),
                            'isOtherRelationship' => memberCovPart.ARC_PrimaryBeneficiaryRelationship__c == 'Other' ? true : false
                        };
                        memberBeneficiariesList.add(primaryBenefMap);
                    }
                    if (memberCovPart.ARC_SecondaryBeneficiaryName__c != null && memberCovPart.ARC_SecondaryBeneficiaryName__c != '') {
                        Map<String, Object> secondaryBenefMap = new Map<String, Object>{
                            'Id' => String.valueOf(memberCovPart.Id + '-secondary'),
                            'Label' => 'Secondary Beneficiary',
                            'BeneficiaryName' => String.valueOf(memberCovPart.ARC_SecondaryBeneficiaryName__c),
                            'BeneficiaryBirthdate' => String.valueOf(memberCovPart.ARC_SecondaryBeneficiaryBirthdate__c),
                            'BeneficiaryPhone' => String.valueOf(memberCovPart.ARC_SecondaryBeneficiaryPhone__c),
                            'BeneficiaryRelationship' => String.valueOf(memberCovPart.ARC_SecondaryBeneficiaryRelationship__c),
                            'BeneficiaryOtherRelationship' => String.valueOf(memberCovPart.ARC_SecondaryBeneficiaryOther__c),
                            'isOtherRelationship' => memberCovPart.ARC_SecondaryBeneficiaryRelationship__c == 'Other' ? true : false
                        };
                        memberBeneficiariesList.add(secondaryBenefMap);
                    }
                }
                memberMap.put('beneficiaries', memberBeneficiariesList);
                finalMemberList.add(memberMap);
            }
            outputMap.put('census_component', new Map<String, Object>{
                'census_members' => finalMemberList
            });
        }
        return outputMap;
    }
     
    // Custom comparator class to sort by relationship
    private class RelationshipComparator implements Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            String relationshipA = (String)a.get('RF_Census.CM_Relationship');
            String relationshipB = (String)b.get('RF_Census.CM_Relationship');
            
            // Primary comes first (value = 1)
            if (relationshipA == 'Primary' && relationshipB != 'Primary') return -1;
            if (relationshipA != 'Primary' && relationshipB == 'Primary') return 1;
            
            // If both are Primary or neither is Primary, Spouse comes before Child (value = 2)
            if (relationshipA == 'Spouse' && relationshipB == 'Child') return -1;
            if (relationshipA == 'Child' && relationshipB == 'Spouse') return 1;
            
            // If same relationship, maintain original order
            return 0;
        }
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
}