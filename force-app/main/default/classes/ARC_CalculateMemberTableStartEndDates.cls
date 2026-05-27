/*******************************************************************
* @ClassName          :   ARC_CalculateMemberTableStartEndDates
* @Description        :   Prepares the members data that will be sent to aRC_MembersPlansTableV2 
* @MethodName         :   calculateDatesPerMemberAndProgram, existGap, calculateInitialAndEndDates
********************************************************************/

public without sharing class ARC_CalculateMemberTableStartEndDates {
    
    @AuraEnabled(cacheable=true)
    public static List<Map<Id, Object>> calculateDatesPerMemberAndProgram( Id idFromMember) {

        // Set of policies Ids where the member is involved
        Set<Id> policiesInvolved = new Set<Id>();

        Account accountFromMember = [SELECT Id, PersonContactId, ARC_IsPrimaryMember__c, ARC_PrimaryMemberAccount__c, ARC_PrimaryMemberAccount__r.PersonContactId, RecordType.DeveloperName, ARC_Census__c, IsActive, ARC_DependentRelationship__c FROM Account WHERE Id =: idFromMember LIMIT 1];

        String recordType = accountFromMember.RecordType.DeveloperName;

        Id relatedCensusId = accountFromMember.ARC_Census__c;
        Boolean isMemberActive = accountFromMember.IsActive;
        Boolean memberIsTemporaryNewborn = accountFromMember.ARC_DependentRelationship__c != null && accountFromMember.ARC_DependentRelationship__c == 'Temporary Newborn' ? true : false;

        Set<Id> relatedContactIds = new Set<Id>();

        if ((recordType == 'ARC_SGPersonAccount')) {
            Id primaryAccId = null;
            if (accountFromMember?.ARC_IsPrimaryMember__c == true) {
                primaryAccId = accountFromMember.Id;
                if (accountFromMember?.PersonContactId != null) relatedContactIds.add(accountFromMember.PersonContactId);
            } else {
                primaryAccId = accountFromMember.ARC_PrimaryMemberAccount__c;
                if (accountFromMember?.ARC_PrimaryMemberAccount__r?.PersonContactId != null) relatedContactIds.add(accountFromMember.ARC_PrimaryMemberAccount__r.PersonContactId);
            }
            
            if (primaryAccId != null) {
                for (Account acc : [SELECT PersonContactId FROM Account WHERE (ARC_PrimaryMemberAccount__c = :primaryAccId AND RecordType.DeveloperName = 'ARC_SGPersonAccount')]) {
                    if (acc?.PersonContactId != null) relatedContactIds.add(acc.PersonContactId);
                }
            }
            
        } else if (recordType == 'ARC_IFPPersonAccount' && relatedCensusId != null) {
            for (vlocity_ins__GroupCensusMember__c member : [SELECT vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c = :relatedCensusId]) {
                if (member?.vlocity_ins__ContactId__c != null) relatedContactIds.add(member.vlocity_ins__ContactId__c);
            }
        }

        List<InsurancePolicyParticipant> memberPolicyParticipantList = new List<InsurancePolicyParticipant>();
        if (!relatedContactIds.isEmpty()) {
            // Get policy participants related to member
            memberPolicyParticipantList = [
                SELECT Id, InsurancePolicyId
                FROM InsurancePolicyParticipant
                WHERE PrimaryParticipantContactId = :relatedContactIds
            ];
        }

        // Add each each policy to list in which member is involved
        for (InsurancePolicyParticipant pp : memberPolicyParticipantList) {
            policiesInvolved.add(pp.InsurancePolicyId);
        }

        List<ARC_CoverageParticipant__c> allMemberCoverageParticipantList = new List<ARC_CoverageParticipant__c>();
        if (!policiesInvolved.isEmpty()) {
            // Get ALL policy participants of each member of each policy involved
            allMemberCoverageParticipantList = [
                SELECT Id,
                ARC_CoverageName__c,
                ARC_Policy__c,
                ARC_Policy__r.ARC_isActive__c,
                ARC_Policy__r.ARC_PolicyStatus__c,
                ARC_Policy__r.ARC_EffectiveDate__c,
                ARC_PolicyParticipant__c,
                ARC_PolicyParticipant__r.ARC_StartDate__c,
                ARC_PolicyParticipant__r.ARC_EndDate__c,
                ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId,
                ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.ARC_Census__c,
                ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.Name,
                ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.ARC_IsPrimaryMember__c,
                ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.PersonBirthdate,
                ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.PersonEmail,
                ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.vlocity_ins__SocialSecurityNumber__pc,
                ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.vlocity_ins__Age__pc,
                ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.IsActive,
                ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.ARC_DependentRelationship__c,
                ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__c,
                ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.Name,
                ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c,
                ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__SubType__c,
                ARC_PolicyCoverage__r.ARC_CoveragePrimaryMember__r.Name
                FROM ARC_CoverageParticipant__c
                WHERE ARC_Policy__c IN :policiesInvolved
                AND (
                    ARC_Policy__r.ARC_PolicyStatus__c = 'Activated'
                    OR ARC_Policy__r.ARC_PolicyStatus__c = 'Terminated'
                    OR ARC_Policy__r.ARC_PolicyStatus__c = 'Awaiting Activation'
                )
                ORDER BY ARC_Policy__r.ARC_EffectiveDate__c ASC, CreatedDate ASC
            ];
        }
        
        
        // Iterate over all coverage participants and group them by account
        
        // Map of each member Id and their plans
        Map<Id, Object> accountsAndCoverages = new  Map<Id, Object>();
        Map<Id, Object> finalAccountsAndCoverages = new  Map<Id, Object>();
        Map<Id, Object> coverageParticipantInitialDates = new Map<Id, Object>(); // Map coverage participant initial dates
        Map<Id, Object> coverageParticipantEndDates = new Map<Id, Object>(); // Map coverage participant end dates
        
        Set<Id> activeAccounts = new Set<Id>();

        for (ARC_CoverageParticipant__c coverage : allMemberCoverageParticipantList) {
            Id accountId = coverage.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId;
            String policyStatus = coverage.ARC_Policy__r.ARC_PolicyStatus__c;
            Id censusId = coverage.ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.ARC_Census__c; 
            
            if (recordType == 'ARC_IFPPersonAccount' && policyStatus == 'Activated' && (relatedCensusId != censusId || (isMemberActive == false && memberIsTemporaryNewborn == false))) {
                continue;   
            }

            if (accountsAndCoverages.containsKey(accountId)) {
                List<ARC_CoverageParticipant__c> coverages = (List<ARC_CoverageParticipant__c>)accountsAndCoverages.get(accountId);
                coverages.add(coverage);
                accountsAndCoverages.put(accountId, coverages);
            } 
            else {
                List<ARC_CoverageParticipant__c> coverages = new List<ARC_CoverageParticipant__c>();
                coverages.add(coverage);
                accountsAndCoverages.put(accountId, coverages);
            }
            if (policyStatus == 'Activated' && ((recordType == 'ARC_IFPPersonAccount' && relatedCensusId == censusId && (isMemberActive == true || memberIsTemporaryNewborn == true)) || (recordType == 'ARC_SGPersonAccount'))) {
                activeAccounts.add(accountId);
            }
        }

        for (Id key : accountsAndCoverages.keySet()) {
            List<ARC_CoverageParticipant__c> medicals = new List<ARC_CoverageParticipant__c>();
            List<ARC_CoverageParticipant__c> smarts = new List<ARC_CoverageParticipant__c>();
            List<ARC_CoverageParticipant__c> aidds = new List<ARC_CoverageParticipant__c>();
            List<ARC_CoverageParticipant__c> coverages = (List<ARC_CoverageParticipant__c>) accountsAndCoverages.get(key);

            // Order member coverages by type of product (Medical, SMART or AIDD)
            for (ARC_CoverageParticipant__c coverage : coverages) {
                String coverageProductType = coverage.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c;
                String coverageProductSubType = coverage.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__SubType__c;
                if (coverageProductType == 'Medical') {
                    medicals.add(coverage);
                }
                if (coverageProductSubType == 'SMART') {
                    smarts.add(coverage);
                }
                if (coverageProductSubType == 'AIDD') {
                    aidds.add(coverage);
                }
            }

            // Get MEDICAL initial and end dates
            Map<String,Object> medicalInitialAndEndDates = calculateInitialAndEndDates(medicals);
            Map<Id,Object> medicalInitialDates = (Map<Id,Object>)medicalInitialAndEndDates.get('InitialDates');
            Map<Id,Object> medicalEndDates = (Map<Id,Object>)medicalInitialAndEndDates.get('EndDates');
            // Get SMART initial and end dates
            Map<String,Object> smartInitialAndEndDates = calculateInitialAndEndDates(smarts);
            Map<Id,Object> smartInitialDates = (Map<Id,Object>)smartInitialAndEndDates.get('InitialDates');
            Map<Id,Object> smartEndDates = (Map<Id,Object>)smartInitialAndEndDates.get('EndDates');
            // Get AIDD initial and end dates
            Map<String,Object> aiddInitialAndEndDates = calculateInitialAndEndDates(aidds);
            Map<Id,Object> aiddInitialDates = (Map<Id,Object>)aiddInitialAndEndDates.get('InitialDates');
            Map<Id,Object> aiddEndDates = (Map<Id,Object>)aiddInitialAndEndDates.get('EndDates');

            // Add initial dates to final map
            coverageParticipantInitialDates.putAll(medicalInitialDates);
            coverageParticipantInitialDates.putAll(smartInitialDates);
            coverageParticipantInitialDates.putAll(aiddInitialDates);

            // Add end dates to final map
            coverageParticipantEndDates.putAll(medicalEndDates);
            coverageParticipantEndDates.putAll(smartEndDates);
            coverageParticipantEndDates.putAll(aiddEndDates);

            // Order list of coverages for each member
            if (medicals != null && !medicals.isEmpty()) {
                medicals.addAll(smarts);
                medicals.addAll(aidds);
                finalAccountsAndCoverages.put(key, medicals);
            }
        }

        // Removing duplicates lines/coverages and resetting some fields
        for (Id key : finalAccountsAndCoverages.keySet()) {
            List<ARC_CoverageParticipant__c> coverages = (List<ARC_CoverageParticipant__c>) finalAccountsAndCoverages.get(key);
            Id prevProductId = null;
            Date prevActiveDate = null;
            for (Integer i = coverages.size() - 1; i >= 0 ; i--) {
                ARC_CoverageParticipant__c coverage = coverages[i];
                Boolean isPrimaryMember = (Boolean)coverage.ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.ARC_IsPrimaryMember__c;
                Id currentProductId = (Id)coverage.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__c;
                if (!activeAccounts.contains(key)) {
                    coverage.ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.IsActive = false;
                    coverage.ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.ARC_DependentRelationship__c = '';
                }
                if (activeAccounts.contains(key) && isPrimaryMember) {
                    coverage.ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.ARC_DependentRelationship__c = 'Primary';
                }
                if (prevProductId != null) {
                    Date currentActiveDate = (Date)coverageParticipantInitialDates.get(coverage.Id);
                    if (currentProductId == prevProductId && currentActiveDate == prevActiveDate) {
                        String policyStatus = coverage.ARC_Policy__r.ARC_PolicyStatus__c;
                        if (policyStatus == 'Activated') {
                            coverages.remove(i+1);
                        } else {
                            coverages.remove(i);
                        }
                    }
                    prevProductId = coverage.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__c;
                    prevActiveDate = currentActiveDate;
                } else {
                    prevProductId = coverage.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__c;
                    prevActiveDate = (Date)coverageParticipantInitialDates.get(coverage.Id);                    
                }
            }
        }
       

        // Adding maps to final list to return
        List<Map<Id,Object>> finalMapList = new List<Map<Id,Object>>();
        finalMapList.add(finalAccountsAndCoverages);
        finalMapList.add(coverageParticipantInitialDates);
        finalMapList.add(coverageParticipantEndDates);

        return finalMapList;
    }

    // Auxiliar method to check if exists gap between expiration date and next effective date
    private static Boolean existGap (Date expirationDate, Date effectiveDate) {
        Integer daysGap = expirationDate.daysBetween(effectiveDate);
        Boolean isGap = daysGap > 3 ? true : false;
        return isGap;
    }

    // Auxiliar method to calculate start for a list of coverage participants
    private static Map<String,Object> calculateInitialAndEndDates (List<ARC_CoverageParticipant__c> coverageParticipants) {

        Map<String,Object> coverageParticipantInitialAndEndDate = new Map<String,Object>();
        Map<Id,Object> coverageParticipantInitialDates = new Map<Id,Object>();
        Map<Id,Object> coverageParticipantEndDates = new Map<Id,Object>();

        Id prevProductId = null;
        Id prevCoverageId = null;
        Date prevExpirationDate = null;
        Date prevEffectiveDate = null;

        // Iterate over medical plans and calculate initial and end dates
        for (ARC_CoverageParticipant__c coverage : coverageParticipants) {
            // First iteration
            if (prevProductId == null) {
                prevProductId = coverage.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__c;
                prevEffectiveDate = coverage.ARC_PolicyParticipant__r.ARC_StartDate__c;
                prevExpirationDate = coverage.ARC_PolicyParticipant__r.ARC_EndDate__c;

                coverageParticipantInitialDates.put(coverage.Id, prevEffectiveDate);
                coverageParticipantEndDates.put(coverage.Id, prevExpirationDate);
            }
            // When product is EQUAL to previous iteration
            else if (prevProductId != null && prevProductId == coverage.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__c) {
                Date currentEffDate = coverage.ARC_PolicyParticipant__r.ARC_StartDate__c;
                Date currentExpDate = coverage.ARC_PolicyParticipant__r.ARC_EndDate__c;
                // Check if exists gap if prev expiration date is not null
                if (prevExpirationDate != null && currentEffDate != null && existGap(prevExpirationDate, currentEffDate)) {
                    // Set current initial and end dates when exists gap
                    coverageParticipantInitialDates.put(coverage.Id, currentEffDate);
                    coverageParticipantEndDates.put(coverage.Id, currentExpDate);
                } else {
                    Date prevInitialDate = (Date)coverageParticipantInitialDates.get(prevCoverageId);
                    coverageParticipantInitialDates.put(coverage.Id, prevInitialDate); // Put previouse initial date to current coverage if no gap between current eff date and prev expiration date
                    coverageParticipantEndDates.put(coverage.Id, currentExpDate); // Put current exp date to previous coverage if no gap between current eff date and prev expiration date
                }
                prevExpirationDate = coverage.ARC_PolicyParticipant__r.ARC_EndDate__c;
            }
            // When product is NOT EQUAL to previous iteration
            else if (prevProductId != null && prevProductId != coverage.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__c) {
                prevProductId = coverage.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__c;
                prevEffectiveDate = coverage.ARC_PolicyParticipant__r.ARC_StartDate__c;
                prevExpirationDate = coverage.ARC_PolicyParticipant__r.ARC_EndDate__c;

                coverageParticipantInitialDates.put(coverage.Id, prevEffectiveDate); // Put current coverage effective date when iterating over a different product 
                coverageParticipantEndDates.put(coverage.Id, prevExpirationDate); // Put current coverage expiration date when iterating over a different product 
            }
            // Set current coverage part as previous coverage Id for next itearion
            prevCoverageId = coverage.Id;
        }
        
        coverageParticipantInitialAndEndDate.put('InitialDates', coverageParticipantInitialDates);
        coverageParticipantInitialAndEndDate.put('EndDates', coverageParticipantEndDates);

        return coverageParticipantInitialAndEndDate;
    }
}