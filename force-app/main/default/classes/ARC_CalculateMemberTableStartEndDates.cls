/*******************************************************************
* @ClassName          :   ARC_CalculateMemberTableStartEndDates
* @Description        :   Prepares the members data that will be sent to aRC_MembersPlansTableV2 
* @MethodName         :   calculateDatesPerMemberAndProgram, existGap, calculateInitialAndEndDates
********************************************************************/

public without sharing class ARC_CalculateMemberTableStartEndDates {
    
    @AuraEnabled(cacheable=true)
    public static List<Map<Id, Object>> calculateDatesPerMemberAndProgram( Id idFromMember) {

        // Set of contracts Ids where the member is involved
        Set<Id> contractsInvolved = new Set<Id>();

        // Get policy participants related to member
        List<InsurancePolicyParticipant> memberPolicyParticipantList = [
            SELECT Id, InsurancePolicy.ARC_Contract__c
            FROM InsurancePolicyParticipant
            WHERE PrimaryParticipantContact.AccountId = :idFromMember
        ];
        // Add each each contract to list in which member is involved
        for (InsurancePolicyParticipant pp : memberPolicyParticipantList) {
            contractsInvolved.add(pp.InsurancePolicy.ARC_Contract__c);
        }

        // Get ALL policy participants of each member of each contract involved
        List<ARC_CoverageParticipant__c> allMemberCoverageParticipantList = [
            SELECT Id,
            ARC_CoverageName__c,
            ARC_Policy__c,
            ARC_Policy__r.ARC_isActive__c,
            ARC_Policy__r.ARC_Contract__r.Status,
            ARC_Policy__r.ARC_Contract__r.ARC_EffectiveDate__c,
            ARC_PolicyParticipant__c,
            ARC_PolicyParticipant__r.EffectiveDate,
            ARC_PolicyParticipant__r.ExpirationDate,
            ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId,
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
            ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__SubType__c
            FROM ARC_CoverageParticipant__c
            WHERE ARC_Policy__r.ARC_Contract__c IN :contractsInvolved
            AND (
                ARC_Policy__r.ARC_Contract__r.Status = 'Activated'
                OR ARC_Policy__r.ARC_Contract__r.Status = 'Terminated'
                OR ARC_Policy__r.ARC_Contract__r.Status = 'Awaiting Activation'
            )
            ORDER BY ARC_Policy__r.ARC_Contract__r.ARC_EffectiveDate__c ASC, CreatedDate ASC
        ];
        System.debug(allMemberCoverageParticipantList.size());

        // Iterate over all coverage participants and group them by account
        
        // Map of each member Id and their plans
        Map<Id, Object> accountsAndCoverages = new  Map<Id, Object>();
        Map<Id, Object> finalAccountsAndCoverages = new  Map<Id, Object>();
        Map<Id, Object> coverageParticipantInitialDates = new Map<Id, Object>(); // Map coverage participant initial dates
        Map<Id, Object> coverageParticipantEndDates = new Map<Id, Object>(); // Map coverage participant end dates
        
        Set<Id> activeAccounts = new Set<Id>();

        for (ARC_CoverageParticipant__c coverage : allMemberCoverageParticipantList) {
            Id accountId = coverage.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId;
            String contractStatus = coverage.ARC_Policy__r.ARC_Contract__r.Status;

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
            if (contractStatus == 'Activated') {
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

            System.debug('medicals size: ' + medicals.size());
            System.debug('smarts size: ' + smarts.size());
            System.debug('aidds size: ' + aidds.size());

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
            System.debug('coverages size: ' + coverages.size());
            Id prevProductId = null;
            Date prevActiveDate = null;
            for (Integer i = coverages.size() - 1; i >= 0 ; i--) {
                ARC_CoverageParticipant__c coverage = coverages[i];
                System.debug('Coverage ID: ' + coverage.Id); 
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
                    System.debug('current active date: ' + currentActiveDate);
                    System.debug('previous active date: ' + prevActiveDate);
                    if (currentProductId == prevProductId && currentActiveDate == prevActiveDate) {
                        String contractStatus = coverage.ARC_Policy__r.ARC_Contract__r.Status;
                        if (contractStatus == 'Activated') {
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
            System.debug('Coverage Id: ' + coverage.Id);
            // First iteration
            if (prevProductId == null) {
                prevProductId = coverage.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__c;
                prevEffectiveDate = Date.valueOf(coverage.ARC_PolicyParticipant__r.EffectiveDate);
                prevExpirationDate = Date.valueOf(coverage.ARC_PolicyParticipant__r.ExpirationDate);

                coverageParticipantInitialDates.put(coverage.Id, prevEffectiveDate);
                coverageParticipantEndDates.put(coverage.Id, prevExpirationDate);
            }
            // When product is EQUAL to previous iteration
            else if (prevProductId != null && prevProductId == coverage.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__c) {
                Date currentEffDate = Date.valueOf(coverage.ARC_PolicyParticipant__r.EffectiveDate);
                Date currentExpDate = Date.valueOf(coverage.ARC_PolicyParticipant__r.ExpirationDate);
                // Check if exists gap if prev expiration date is not null
                System.debug('prev exp date: ' + prevExpirationDate);
                System.debug('current eff date: ' + currentEffDate);
                System.debug('current exp date: ' + currentExpDate);
                if (prevExpirationDate != null && currentEffDate != null && existGap(prevExpirationDate, currentEffDate)) {
                    System.debug('Entered if exists gap');
                    // Set current initial and end dates when exists gap
                    coverageParticipantInitialDates.put(coverage.Id, currentEffDate);
                    coverageParticipantEndDates.put(coverage.Id, currentExpDate);
                } else {
                    Date prevInitialDate = (Date)coverageParticipantInitialDates.get(prevCoverageId);
                    coverageParticipantInitialDates.put(coverage.Id, prevInitialDate); // Put previouse initial date to current coverage if no gap between current eff date and prev expiration date
                    coverageParticipantEndDates.put(coverage.Id, currentExpDate); // Put current exp date to previous coverage if no gap between current eff date and prev expiration date
                }
                prevExpirationDate = Date.valueOf(coverage.ARC_PolicyParticipant__r.ExpirationDate);
            }
            // When product is NOT EQUAL to previous iteration
            else if (prevProductId != null && prevProductId != coverage.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__c) {
                prevProductId = coverage.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__c;
                prevEffectiveDate = Date.valueOf(coverage.ARC_PolicyParticipant__r.EffectiveDate);
                prevExpirationDate = Date.valueOf(coverage.ARC_PolicyParticipant__r.ExpirationDate);

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