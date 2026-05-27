public with sharing class ARC_SGWaitingPeriodsLogic {
    private class WaitingPeriodContext {
        public List<String> resetReasons;
        public Map<String, Map<String, Object>> wpFieldsMetadata;
        public List<String> wpFieldsParticipant;

        public WaitingPeriodContext() {
            resetReasons = new List<String>();
            wpFieldsMetadata = new Map<String, Map<String, Object>>();
            wpFieldsParticipant = new List<String>();
        }
    }

    /*******************************************************************
     * @MethodName         :   stampWaitingPeriods
     * @Description        :   Parent method to create waiting periods
     ********************************************************************/
    public static void stampWaitingPeriods(Set<Id> policyList, List<Date> newbornsDOB) {
        // CREATE MAPS WITH VALUES FOR WAITING PERIODS AND UPGRADE REASONS
        // List<Waiting_Period_Config__mdt> wpConfig = Waiting_Period_Config__mdt.getAll().values();
        WaitingPeriodContext ctx = new WaitingPeriodContext();
        loadWaitingPeriodContext(ctx);
        // loadWaitingPeriodContext(wpConfig, ctx);
        

        List<InsurancePolicyParticipant> participants = [
            SELECT Id, InsurancePolicy.ARC_EffectiveDate__c, Role, InsurancePolicy.PriorPolicyId,
                PrimaryParticipantContactId, PrimaryParticipantContact.Birthdate, PrimaryParticipantContact.Account.ARC_LastWPResetDate__c,
                WP_Normal__c, WP_Cancer__c, WP_Pre_Ex__c, WP_Death_Benefit__c, WP_Glacoma__c, WP_Colon__c, WP_Immunizations__c, WP_Critical_Illness__c,
                (
                    SELECT Id, ARC_PolicyParticipant__r.PrimaryParticipantContactId, ARC_CoverageName__c, ARC_PolicyCoverage__r.ARC_Reason__c,
                        ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c, ARC_PolicyCoverage__r.ARC_ParentProduct__c
                    FROM Coverage_Participants__r
                )
            FROM InsurancePolicyParticipant
            WHERE InsurancePolicyId IN :policyList
                AND InsurancePolicy.RecordType.Name = 'Small Group'
        ];


        // String polPartQuery =
        //     'SELECT Id, PrimaryParticipantContactId, PrimaryParticipantContact.Birthdate, Role, ' +
        //         'InsurancePolicy.ARC_EffectiveDate__c, InsurancePolicy.PriorPolicyId, InsurancePolicyId, ' +
        //         'PrimaryParticipantContact.Account.ARC_LastWPResetDate__c ' +
        //         String.join(ctx.wpFieldsParticipant, ', ') + ', ' +
        //     '(' +
        //         'SELECT Id, ARC_CoverageName__c, ' +
        //             'ARC_PolicyCoverage__r.ARC_Reason__c, ' +
        //             'ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c, ' +
        //             'ARC_PolicyCoverage__r.ARC_ParentProduct__c ' +
        //         'FROM Coverage_Participants__r' +
        //     ') ' +
        //     'FROM InsurancePolicyParticipant ' +
        //     'WHERE InsurancePolicyId IN :policyList ' +
        //         'AND InsurancePolicy.RecordType.Name = \'Small Group\'';

        // String strQuery = 
        //     'SELECT Id, PrimaryParticipantContactId, PrimaryParticipantContact.Birthdate, InsurancePolicyId, InsurancePolicy.ARC_EffectiveDate__c, ' +
        //         String.join(ctx.wpFieldsParticipant, ', ') + ' ' +
        //     'FROM InsurancePolicyParticipant ' +
        //     'WHERE InsurancePolicyId IN :oldPolIds AND InsurancePolicy.RecordType.Name = \'Small Group\'';

        // List<InsurancePolicyParticipant> policyParticipants = Database.query(polPartQuery);
        // if (policyParticipants.size() == 0) return;
        if (participants.size() == 0) return;

        // ITERATE OVER PARTICIPANTS AND CHECK IF IT IS AN UPGRADE
        List<InsurancePolicyParticipant> resetParticipants = new List<InsurancePolicyParticipant>();
        List<InsurancePolicyParticipant> carryOverParticipants = new List<InsurancePolicyParticipant>();
        // for (InsurancePolicyParticipant polPart : policyParticipants) {
        for (InsurancePolicyParticipant part : participants) {
            List<String> reasons = getReasons(part);
            if (reasons.isEmpty()) continue;
            if (shouldResetWP(reasons, ctx)) {
                resetParticipants.add(part);
            } else {
                carryOverParticipants.add(part);
            }
        }
        
        // Map<Id, InsurancePolicyParticipant> resetPartsUpdate = resetParticipants.size() > 0 ? resetWP(resetParticipants, ctx, new List<InsurancePolicyParticipant>(), newbornsDOB) : new Map<Id, InsurancePolicyParticipant>();
        // Map<Id, InsurancePolicyParticipant> carryPartsUpdate = carryOverParticipants.size() > 0 ? carryOverWP(carryOverParticipants, ctx, newbornsDOB) : new Map<Id, InsurancePolicyParticipant>();
        Map<Id, InsurancePolicyParticipant> resetPartsUpdate = resetParticipants.size() > 0 ? resetWP(ctx, resetParticipants, newbornsDOB) : new Map<Id, InsurancePolicyParticipant>();
        Map<Id, InsurancePolicyParticipant> carryPartsUpdate = carryOverParticipants.size() > 0 ? carryOverWP(ctx, carryOverParticipants, newbornsDOB) : new Map<Id, InsurancePolicyParticipant>();
        if (resetPartsUpdate.size() > 0) update resetPartsUpdate.values();
        if (carryPartsUpdate.size() > 0) update carryPartsUpdate.values();
    }

    /*******************************************************************
     * @MethodName         :   resetWP
     * @Description        :   Reset waiting periods for policies that are upgrades
     ********************************************************************/
    // public static Map<Id, InsurancePolicyParticipant> resetWP(List<InsurancePolicyParticipant> policyParticipants, WaitingPeriodContext ctx, List<InsurancePolicyParticipant> newParticipants, List<Date> newbornsDOB) {
    public static Map<Id, InsurancePolicyParticipant> resetWP(WaitingPeriodContext ctx, List<InsurancePolicyParticipant> participants, List<Date> newbornsDOB) {
        Map<Id, InsurancePolicyParticipant> response = new Map<Id, InsurancePolicyParticipant>();

        // GET PARTICIPANTS AND FIELDS FOR WAITING PERIODS ONLY IF THE WP FIELDS ARE BLANK
        // List<InsurancePolicyParticipant> participants = newParticipants.isEmpty() ? policyParticipants : newParticipants;
        
        // ITERATE OVER PARTICIPANTS AND THEIR COVERAGES TO POPULATE WAITING PERIODS
        for (InsurancePolicyParticipant part : participants) {
            if (part.PrimaryParticipantContact == null) continue;
            String memberPrograms = getMemberCoverages(part);
            if (memberPrograms == '') continue;
            List<String> periodCoverage = memberPrograms.split('_');
            Map<String, Object> wpForCoverages = getWaitingPeriods(periodCoverage, ctx);
            Integer dependentAgeMonths = checkDependentMonths(part);

            // ITERATE OVER WAITING PERIODS TO POPULATE FIELDS
            for (String field : ctx.wpFieldsParticipant) {
                if (
                    (part.get(field) != null && part.get(field) == part.PrimaryParticipantContact.Birthdate) || 
                    wpForCoverages.get(field) == null
                ) {
                    continue;
                }
                if (isNewborn(part, newbornsDOB)) {
                    part.put(field, part.PrimaryParticipantContact.Birthdate);
                    response.put(part.Id, part);
                    continue;
                }
                Date effDate = part.InsurancePolicy.ARC_EffectiveDate__c;
                switch on field {
                    // IMMUNIZATIONS - 10 MONTHS FOR +18 MONTHS ENROLLED AGE AND 6 MONTHS FOR -18 MONTHS ENROLLED AGE 
                    when 'WP_Immunizations__c' {
                        if (dependentAgeMonths != null) {
                            if (dependentAgeMonths > 18) {
                                part.put(field, effDate.addMonths(10));
                            } else {
                                part.put(field, effDate.addMonths(6));
                            }
                        }
                    }
                    when else {
                        System.debug('TestDebug wpForCoverages:' + wpForCoverages);
                        System.debug('TestDebug field:' + field);
                        System.debug('TestDebug wpForCoverages.get(field):' + wpForCoverages.get(field));
                        part.put(field, effDate.addMonths(Integer.ValueOf(wpForCoverages.get(field))));
                    }
                }
                response.put(part.Id, part);
            }
        }
        return response;
    }

    /*******************************************************************
     * @MethodName         :   carryOverWP
     * @Description        :   Carry over waiting periods for policies that are not upgrades
     ********************************************************************/
    // private static Map<Id, InsurancePolicyParticipant> carryOverWP(List<InsurancePolicyParticipant> policyParticipants, WaitingPeriodContext ctx, List<Date> newbornsDOB) {
    private static Map<Id, InsurancePolicyParticipant> carryOverWP(WaitingPeriodContext ctx, List<InsurancePolicyParticipant> participants, List<Date> newbornsDOB) {
        Map<Id, InsurancePolicyParticipant> response = new Map<Id, InsurancePolicyParticipant>();  
        Map<Id, InsurancePolicyParticipant> oldParticipantsMap = new Map<Id, InsurancePolicyParticipant>();
        Set<Id> oldPolIds = new Set<Id>();
        Set<Id> newPolIds = new Set<Id>();
        // List<InsurancePolicyParticipant> newParticipants = new List<InsurancePolicyParticipant>();

        // GET OLD PARTICIPANTS AND FIELDS FOR WAITING PERIODS
        // for (InsurancePolicyParticipant part : policyParticipants) {
        for (InsurancePolicyParticipant part : participants) {
            if (part.InsurancePolicy.PriorPolicyId != null) {
                oldPolIds.add(part.InsurancePolicy.PriorPolicyId);
            }
            newPolIds.add(part.InsurancePolicyId);
        }
        
        // String strQuery = 
        //     'SELECT Id, PrimaryParticipantContactId, PrimaryParticipantContact.Birthdate, InsurancePolicyId, InsurancePolicy.ARC_EffectiveDate__c, ' +
        //         String.join(ctx.wpFieldsParticipant, ', ') + ' ' +
        //     'FROM InsurancePolicyParticipant ' +
        //     'WHERE InsurancePolicyId IN :oldPolIds AND InsurancePolicy.RecordType.Name = \'Small Group\'';
 
        // for (InsurancePolicyParticipant part : Database.query(strQuery)) {
        //     if (oldPolIds.contains(part.InsurancePolicyId)) {
        //         oldParticipantsMap.put(part.PrimaryParticipantContactId, part);
        //     }
        // }

        // CHECK FOR PREVIOUS SMART CHANGES
        Map<String, Object> smartCheck = checkSmartPrograms(oldPolIds, newPolIds);
        Map<Id, String> smartUpgrade = (Map<Id, String>)smartCheck.get('smartUpgrade');
        Map<Id, Boolean> prevSmart = (Map<Id, Boolean>)smartCheck.get('prevSmart');
        Map<Id, Boolean> currentSmart = (Map<Id, Boolean>)smartCheck.get('currentSmart');
        
        // for (InsurancePolicyParticipant part : policyParticipants) {
        for (InsurancePolicyParticipant part : participants) {
            if (part.PrimaryParticipantContact == null) continue;
            String memberPrograms = getMemberCoverages(part);
            if (memberPrograms == '') continue;
            List<String> periodCoverage = memberPrograms.split('_');
            Map<String, Object> wpForCoverages = getWaitingPeriods(periodCoverage, ctx);
            Integer dependentAgeMonths = checkDependentMonths(part);
            // InsurancePolicyParticipant oldPart = oldParticipantsMap.get(part.PrimaryParticipantContactId);
            // if (oldPart == null) {
            //     newParticipants.add(part);
            //     continue;
            // }

            // ITERATE OVER WAITING PERIODS TO POPULATE FIELDS
            for (String field : ctx.wpFieldsParticipant) {
                if (
                    (part.get(field) != null && part.get(field) == part.PrimaryParticipantContact.Birthdate) ||
                    // oldPart.get(field) == null ||
                    wpForCoverages.get(field) == null
                ) {
                    continue;
                }
                if (isNewborn(part, newbornsDOB)) {
                    part.put(field, part.PrimaryParticipantContact.Birthdate);
                    response.put(part.Id, part);
                    continue;
                }
                Date effDate = part.InsurancePolicy.ARC_EffectiveDate__c;
                Date lastWPResetDate = part.PrimaryParticipantContact.Account.ARC_LastWPResetDate__c;
                if (lastWPResetDate > effDate || lastWPResetDate == null) continue;
                switch on field {
                    // CATARACTS/GLAUCOMA NOT INCLUDED ON ACCESS PROGRAMS
                    // when 'WP_Glacoma__c' {
                    //     if (!productCode.contains('Access')) {
                    //         part.put(field, lastWPResetDate.addMonths(Integer.ValueOf(wpForCoverages.get(field))));
                    //     }
                    // }
                    // IMMUNIZATIONS - 10 MONTHS FOR +18 ENROLLED AGE AND 6 MONTHS FOR -18 ENROLLED AGE 
                    when 'WP_Immunizations__c' {
                        if (dependentAgeMonths != null) {
                            if (dependentAgeMonths > 18) {
                                part.put(field, lastWPResetDate.addMonths(10));
                            } else {
                                part.put(field, lastWPResetDate.addMonths(6));
                            }
                        }
                    }
                    when else {
                        part.put(field, lastWPResetDate.addMonths(Integer.ValueOf(wpForCoverages.get(field))));
                    }
                }
                // part.put(field, (Date)oldPart.get(field));
                response.put(part.Id, part);
            }
        }
        // if (newParticipants.size() > 0) response.putAll(resetWP(policyParticipants, ctx, newParticipants, newbornsDOB));
        return response;
    }

    /*******************************************************************
     * @MethodName         :   checkSmartPrograms
     * @Description        :   Check if some participants have a smart upgrade
     ********************************************************************/
    public static Map<String, Object> checkSmartPrograms(Set<Id> oldPolicies, Set<Id> newPolicies) {
        Map<String, Object> response = new Map<String, Object>();
        Map<Id, String> smartUpgrade = new Map<Id, String>();
        Map<Id, Boolean> prevSmart = new Map<Id, Boolean>();
        Map<Id, Boolean> currentSmart = new Map<Id, Boolean>();
        Map<Id, String> oldSmarts = new Map<Id, String>();

        List<ARC_CoverageParticipant__c> coveragesCheck = [
            SELECT Id, ARC_CoverageName__c, ARC_PolicyParticipant__r.PrimaryParticipantContactId, ARC_Policy__c
            FROM ARC_CoverageParticipant__c
            WHERE ARC_CoverageName__c LIKE 'SMART%'
            AND (ARC_Policy__c IN :oldPolicies OR ARC_Policy__c IN :newPolicies) LIMIT 5000
        ];

        // SEARCH FOR OLD COVERAGES
        for (ARC_CoverageParticipant__c cov : coveragesCheck) {
            if (newPolicies.contains(cov.ARC_Policy__c)) continue;

            oldSmarts.put(cov.ARC_PolicyParticipant__r.PrimaryParticipantContactId, cov.ARC_CoverageName__c); 
            prevSmart.put(cov.ARC_PolicyParticipant__r.PrimaryParticipantContactId, true);             
        }

        // COMPARE WITH NEW COVERAGES
        for (ARC_CoverageParticipant__c cov : coveragesCheck) {
            if (oldPolicies.contains(cov.ARC_Policy__c)) continue;

            if (oldSmarts.get(cov.ARC_PolicyParticipant__r.PrimaryParticipantContactId) == null) {
                smartUpgrade.put(cov.ARC_PolicyParticipant__r.PrimaryParticipantContactId, 'upgrade');
            } else if (oldSmarts.get(cov.ARC_PolicyParticipant__r.PrimaryParticipantContactId) != null) {
                Integer newSmart = Integer.valueOf(cov.ARC_CoverageName__c.split(' ')[cov.ARC_CoverageName__c.split(' ').size() - 1]);
                Integer oldSmart = Integer.valueOf(oldSmarts.get(cov.ARC_PolicyParticipant__r.PrimaryParticipantContactId).split(' ')[(oldSmarts.get(cov.ARC_PolicyParticipant__r.PrimaryParticipantContactId).split(' ').size() - 1)]);

                if (newSmart > oldSmart) {
                    smartUpgrade.put(cov.ARC_PolicyParticipant__r.PrimaryParticipantContactId, 'upgrade');
                } else {
                    smartUpgrade.put(cov.ARC_PolicyParticipant__r.PrimaryParticipantContactId, 'downgrade');
                }
            }

            currentSmart.put(cov.ARC_PolicyParticipant__r.PrimaryParticipantContactId, true);
        }

        response.put('smartUpgrade', smartUpgrade);
        response.put('prevSmart', prevSmart);
        response.put('currentSmart', currentSmart);
        return response;
    }

    /*******************************************************************
     * @MethodName         :   getMemberCoverages
     * @Description        :   Create a map with member programs
     ********************************************************************/
    private static String getMemberCoverages(InsurancePolicyParticipant polPart) {
        String memberProgram = '';
        List<Integer> memberProgramsOrder = new List<Integer>();
        
        // GET COVERAGES FOR EVERY MEMBERS AND ORDER THEM BY PRIORITY
        for (ARC_CoverageParticipant__c cp : polPart.Coverage_Participants__r) {
            System.debug('TestDebug cp.ARC_CoverageName__c: ' + cp.ARC_CoverageName__c);
            if (cp.ARC_CoverageName__c.contains('WeShare Group Enhanced')) {
                memberProgramsOrder.add(1);
            } else if (cp.ARC_CoverageName__c.contains('WeShare Group Essential')) {
                memberProgramsOrder.add(2);
            } else if (cp.ARC_CoverageName__c.contains('WeShare Group Senior')) {
                memberProgramsOrder.add(3);
            } else if (cp.ARC_CoverageName__c.contains('SMART')) {
                memberProgramsOrder.add(4);
            } else if (cp.ARC_CoverageName__c.contains('AIDD')) {
                memberProgramsOrder.add(5);
            }
        }

        // CREATE MAP WITH MEMBER PROGRAMS AND ORDER BY PRIORITY
        memberProgramsOrder.sort();
        if (memberProgramsOrder.contains(1)) memberProgram += 'WeShareGroupEnhanced_';
        if (memberProgramsOrder.contains(2)) memberProgram += 'WeShareGroupEssential_';
        if (memberProgramsOrder.contains(3)) memberProgram += 'WeShareGroupSenior_';
        if (memberProgramsOrder.contains(4)) memberProgram += 'SMART_';
        if (memberProgramsOrder.contains(5)) memberProgram += 'AIDD_';
        memberProgram = memberProgram.removeEnd('_');

        return memberProgram;
    }

    /*******************************************************************
     * @MethodName  : getWaitingPeriods
     * @Description : Returns the waiting period configuration that best matches the member's coverages. Tries the full coverage combination first and progressively
     *                removes the lowest-priority coverage until a match is found.
     ********************************************************************/
    private static Map<String, Object> getWaitingPeriods(List<String> periodCoverage, WaitingPeriodContext ctx) {
        // ITERATE OVER COVERAGES TO GET WAITING PERIODS
        while (!periodCoverage.isEmpty()) {
            String key = String.join(periodCoverage, '_');
            if (ctx.wpFieldsMetadata.containsKey(key)) {
                return ctx.wpFieldsMetadata.get(key);
            }
            periodCoverage.remove(periodCoverage.size() - 1);
        }
        return new Map<String, Object>();
    }

    /*******************************************************************
     * @MethodName  : checkDependentMonths
     * @Description : Calculates the dependent's age in months at policy effective date. Returns null if the participant is not a dependent.
     ********************************************************************/
    private static Integer checkDependentMonths(InsurancePolicyParticipant polPart) {
        Integer ageMonths;
        if (polPart.Role == 'Dependent') {
            ageMonths = polPart.PrimaryParticipantContact.Birthdate.monthsBetween(polPart.InsurancePolicy.ARC_EffectiveDate__c);
        }
        return ageMonths;
    }

    /*******************************************************************
     * @MethodName  : getReasons
     * @Description : Retrieves the list of upgrade/downgrade reasons from the participant's medical coverage.
     ********************************************************************/
    private static List<String> getReasons(InsurancePolicyParticipant polPart) {
        List<String> reasonList = new List<String>();
        for (ARC_CoverageParticipant__c cp : polPart.Coverage_Participants__r) {
            if (
                cp.ARC_PolicyCoverage__r?.vlocity_ins_fsc__Product2Id__r?.vlocity_ins__Type__c == 'Medical'
                && cp.ARC_PolicyCoverage__r?.ARC_ParentProduct__c == null
            ) {
                String reasons = cp?.ARC_PolicyCoverage__r?.ARC_Reason__c;
                if (reasons != null) reasonList = reasons.split(';');
                break;
            }
        }
        return reasonList;
    }

    /*******************************************************************
     * @MethodName  : shouldResetWP
     * @Description : Determines whether a participant should reset the WP (based on insurancePolicy).
     ********************************************************************/
    private static Boolean shouldResetWP(List<String> reasons, WaitingPeriodContext ctx) {
        for (String reason : reasons) {
            if (ctx.resetReasons.contains(reason)) return true;
        }
        return false;
    }
    
    /*******************************************************************
     * @MethodName  : isNewborn
     * @Description : Checks whether the participant is a newborn by matching their birthdate against the provided newborn date list.
     ********************************************************************/
    private static Boolean isNewborn(InsurancePolicyParticipant part, List<Date> newbornsDOB) {
        return newbornsDOB != null && newbornsDOB.contains(part.PrimaryParticipantContact.Birthdate);
    }

    /*******************************************************************
     * @MethodName  : getWpParticipantFields
     * @Description : Returns all InsurancePolicyParticipant field names that represent waiting periods (WP_* fields).
     ********************************************************************/
    private static List<String> getWpParticipantFields() {
        List<String> fields = new List<String>();
        for (Schema.SObjectField field : InsurancePolicyParticipant.getSObjectType().getDescribe().fields.getMap().values()) {
            String name = field.getDescribe().getName();
            if (name.startsWith('WP_')) fields.add(name);
        }
        return fields;
    }

    /*******************************************************************
     * @MethodName  : loadWaitingPeriodContext
     * @Description : Loads waiting period metadata and upgrade reasons into the provided WaitingPeriodContext instance.
     ********************************************************************/
    private static void loadWaitingPeriodContext(WaitingPeriodContext ctx) {
        List<Waiting_Period_Config__mdt> wpConfig = Waiting_Period_Config__mdt.getAll().values();
        for (Waiting_Period_Config__mdt mtd : wpConfig) {
            if (mtd.DeveloperName == 'Reset_Reasons_SG'){
                ctx.resetReasons = mtd.Reset_Reasons_SG__c.split(',');
            } else {
                ctx.wpFieldsMetadata.put(mtd.DeveloperName, extractWpFields(mtd));
            }
        }
        ctx.wpFieldsParticipant = getWpParticipantFields();
    }

    /*******************************************************************
     * @MethodName  : extractWpFields
     * @Description : Extracts all waiting period (WP_*) field values from a Waiting_Period_Config__mdt record.
     ********************************************************************/
    private static Map<String, Object> extractWpFields(Waiting_Period_Config__mdt mtd) {
        Map<String, Object> result = new Map<String, Object>();
        for (Schema.SObjectField field : mtd.getSObjectType().getDescribe().fields.getMap().values()) {
            String name = field.getDescribe().getName();
            if (name.startsWith('WP_')) {
                result.put(name, mtd.get(name));
            }
        }
        return result;
    }
}