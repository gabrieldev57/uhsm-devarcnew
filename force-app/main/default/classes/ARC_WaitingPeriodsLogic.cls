public without sharing class ARC_WaitingPeriodsLogic {
    private class WaitingPeriodContext {
        public List<String> upgradeReasons;
        public Map<String, Map<String, Object>> wpFieldsMetadata;
        public List<String> wpFieldsParticipant;
        public Map<Id, InsurancePolicy> accountIdToPreviousPolicy;

        public WaitingPeriodContext() {
            upgradeReasons = new List<String>();
            wpFieldsMetadata = new Map<String, Map<String, Object>>();
            wpFieldsParticipant = new List<String>();
            accountIdToPreviousPolicy = new Map<Id, InsurancePolicy>();
        }
    }
    
    /*******************************************************************
     * @MethodName         :   stampWaitingPeriods
     * @Description        :   Parent method to create waiting periods
     ********************************************************************/
    public static void stampWaitingPeriods(Set<Id> contractList, List<Date> newbornsDOB) {

        List<InsurancePolicyParticipant> participants = [
            SELECT Id, InsurancePolicy.ARC_Contract__r.ARC_ContractReason__c, InsurancePolicy.ARC_EffectiveDate__c, InsurancePolicy.Product.ProductCode, Role,
                PrimaryParticipantContactId, PrimaryParticipantContact.Birthdate, PrimaryParticipantContact.AccountId, 
                InsurancePolicy.ARC_SpinnedFromPolicy__c, InsurancePolicy.ARC_SpinnedFromPolicy__r.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.vlocity_ins__GroupId__c,
                InsurancePolicy.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.vlocity_ins__GroupId__c, PrimaryParticipantContact.Account.ARC_LastWPResetDate__c,
                WP_Normal__c, WP_Cancer__c, WP_Pre_Ex__c, WP_Death_Benefit__c, WP_Glacoma__c, WP_Colon__c, WP_Immunizations__c, WP_Critical_Illness__c,
                (SELECT Id, ARC_PolicyParticipant__r.PrimaryParticipantContactId, ARC_CoverageName__c
                FROM Coverage_Participants__r)
            FROM InsurancePolicyParticipant
            WHERE InsurancePolicy.ARC_Contract__c IN :contractList
        ];
        if (participants.size() == 0) return;

        WaitingPeriodContext ctx = new WaitingPeriodContext();
        loadWaitingPeriodContext(ctx, participants);

        // RESET/CARRY PARTICIPANTS
        List<InsurancePolicyParticipant> resetParticipants = new List<InsurancePolicyParticipant>();
        List<InsurancePolicyParticipant> carryOverParticipants = new List<InsurancePolicyParticipant>();
        for (InsurancePolicyParticipant part : participants) {
            if (part?.InsurancePolicy?.ARC_Contract__r?.ARC_ContractReason__c == null) continue;
            if (shouldResetWP(ctx, part)) {
                resetParticipants.add(part);
                System.debug('Reset by Gabriel');
            } else {
                carryOverParticipants.add(part);
                System.debug('Carry Over by Gabriel');
            }
        }
        
        Map<Id, InsurancePolicyParticipant> resetPartsUpdate = resetParticipants.size() > 0 ? ARC_WaitingPeriodsLogic.resetWP(ctx, resetParticipants, newbornsDOB) : new Map<Id, InsurancePolicyParticipant>();
        Map<Id, InsurancePolicyParticipant> carryPartsUpdate = carryOverParticipants.size() > 0 ? ARC_WaitingPeriodsLogic.carryOverWP(ctx, carryOverParticipants, newbornsDOB) : new Map<Id, InsurancePolicyParticipant>();
        if (resetPartsUpdate.size() > 0) update resetPartsUpdate.values();
        if (carryPartsUpdate.size() > 0) update carryPartsUpdate.values();
    }

    /*******************************************************************
     * @MethodName         :   resetWP
     * @Description        :   Reset waiting periods for participants
     ********************************************************************/
    public static Map<Id, InsurancePolicyParticipant> resetWP(WaitingPeriodContext ctx, List<InsurancePolicyParticipant> participants, List<Date> newbornsDOB) {
        Map<Id, InsurancePolicyParticipant> response = new Map<Id, InsurancePolicyParticipant>();

        // GET PARTICIPANTS AND FIELDS FOR WAITING PERIODS ONLY IF THE WP FIELDS ARE BLANK
        Map<Id, Integer> dependentOlder = checkDependentMonths(participants);

        // ITERATE OVER PARTICIPANTS AND THEIR COVERAGES TO POPULATE WAITING PERIODS
        for (InsurancePolicyParticipant part : participants) {
            String productCode = part.InsurancePolicy.Product.ProductCode;
            if (productCode.contains('Legacy')) continue;
            Map<Id, String> memberPrograms = getMemberCoverages(part.Coverage_Participants__r);
            if (memberPrograms.get(part.PrimaryParticipantContactId) == null) continue;
            List<String> periodCoverage = memberPrograms.get(part.PrimaryParticipantContactId).split('_');
            Map<String, Object> wpForCoverages = new Map<String, Object>();
    
            // ITERATE OVER COVERAGES TO GET WAITING PERIODS
            for (Integer i = periodCoverage.size() - 1; i >= 0; i--) {
                String allProds = String.join(periodCoverage, '_');
                if (ctx.wpFieldsMetadata.get(allProds) == null) {
                    periodCoverage.remove(i);
                    continue;
                } else {
                    wpForCoverages = ctx.wpFieldsMetadata.get(allProds);
                    break;
                }
            }

            // ITERATE OVER WAITING PERIODS TO POPULATE FIELDS
            for (String field : ctx.wpFieldsParticipant) {
                if ((part.get(field) != null && part.get(field) == part.PrimaryParticipantContact.Birthdate) || wpForCoverages.get(field) == null) continue;
                if (newbornsDOB != null && newbornsDOB.contains(part.PrimaryParticipantContact.Birthdate)) {
                    part.put(field, part.PrimaryParticipantContact.Birthdate);
                    response.put(part.Id, part);
                    continue;
                }
                Date effDate = part.InsurancePolicy.ARC_EffectiveDate__c;
                switch on field {
                    // CATARACTS/GLAUCOMA NOT INCLUDED ON ACCESS PROGRAMS
                    when 'WP_Glacoma__c' {
                        if (!productCode.contains('Access')) {
                            part.put(field, effDate.addMonths(Integer.ValueOf(wpForCoverages.get(field))));
                        }
                    }
                    // IMMUNIZATIONS - 10 MONTHS FOR +18 MONTHS ENROLLED AGE AND 6 MONTHS FOR -18 MONTHS ENROLLED AGE 
                    when 'WP_Immunizations__c' {
                        if (!productCode.contains('Access') && productCode.contains('WeShare') && dependentOlder.get(part.PrimaryParticipantContactId) != null) {
                            if (dependentOlder.get(part.PrimaryParticipantContactId) > 18) {
                                part.put(field, effDate.addMonths(10));
                            } else {
                                part.put(field, effDate.addMonths(6));
                            }
                        }
                    }
                    when else {
                        part.put(field, effDate.addMonths(Integer.ValueOf(wpForCoverages.get(field))));
                    }
                }
                response.put(part.Id, part);
            }
        }
        return response;
    }
    
    /*******************************************************************
     * @MethodName         :   getMemberCoverages
     * @Description        :   Create a map with member programs
     ********************************************************************/
    public static Map<Id, String> getMemberCoverages(List<ARC_CoverageParticipant__c> coverages) {
        Map<Id, String> response = new Map<Id, String>();
        Map<Id, List<Integer>> memberProgramsOrder = new Map<Id, List<Integer>>();
        
        // GET COVERAGES FOR EVERY MEMBERS AND ORDER THEM BY PRIORITY
        for (ARC_CoverageParticipant__c cp : coverages) {
            List<Integer> coverageOrder = 
                memberProgramsOrder.get(cp.ARC_PolicyParticipant__r.PrimaryParticipantContactId) != null 
                    ? memberProgramsOrder.get(cp.ARC_PolicyParticipant__r.PrimaryParticipantContactId) 
                    : new List<Integer>();
            if (cp.ARC_CoverageName__c.contains('Premier')) {
                coverageOrder.add(1);
            } else if (cp.ARC_CoverageName__c.contains('WeShare')) {
                coverageOrder.add(2);
            } else if (cp.ARC_CoverageName__c.contains('UHSM')) {
                coverageOrder.add(3);
            } else if (cp.ARC_CoverageName__c.contains('SMART')) {
                coverageOrder.add(4);
            } else if (cp.ARC_CoverageName__c.contains('AIDD')) {
                coverageOrder.add(5);
            }
            memberProgramsOrder.put(cp.ARC_PolicyParticipant__r.PrimaryParticipantContactId, coverageOrder);
        }

        // CREATE MAP WITH MEMBER PROGRAMS AND ORDER BY PRIORITY
        for (Id memberId : memberProgramsOrder.keySet()) {
            String program = '';
            List<Integer> order = memberProgramsOrder.get(memberId);
            order.sort();

            if (order.contains(1)) program += 'Premier_';
            if (order.contains(2)) program += 'WeShare_';
            if (order.contains(3)) program += 'UHSM_';
            if (order.contains(4)) program += 'SMART_';
            if (order.contains(5)) program += 'AIDD_';
            program = program.removeEnd('_');
            response.put(memberId, program);
        }

        return response;
    }

    /*******************************************************************
     * @MethodName         :   checkDependentMonths
     * @Description        :   Check for a child on family for immunization
     ********************************************************************/
    public static Map<Id, Integer> checkDependentMonths(List<InsurancePolicyParticipant> participants) {
        Map<Id, Integer> returnMap = new Map<Id, Integer>();
        for (InsurancePolicyParticipant part : participants) {
            if (part.Role != 'Dependent' || returnMap.get(part.PrimaryParticipantContactId) != null) continue;
            returnMap.put(part.PrimaryParticipantContactId, part.PrimaryParticipantContact.Birthdate.monthsBetween(part.InsurancePolicy.ARC_EffectiveDate__c));
        }

        return returnMap;
    }

    /*******************************************************************
     * @MethodName         :   carryOverWP
     * @Description        :   Carry over waiting periods for participants
     ********************************************************************/
    public static Map<Id, InsurancePolicyParticipant> carryOverWP(WaitingPeriodContext ctx, List<InsurancePolicyParticipant> participants, List<Date> newbornsDOB) {
        Map<Id, InsurancePolicyParticipant> response = new Map<Id, InsurancePolicyParticipant>();
        Set<Id> oldPolIds = new Set<Id>();
        Set<Id> newPolIds = new Set<Id>();
        // CHECK FOR PREVIOUS SMART CHANGES
        for (InsurancePolicyParticipant participant : participants) {
            newPolIds.add(participant.InsurancePolicyId);
        }
        for (InsurancePolicy policy : ctx.accountIdToPreviousPolicy.values()) {
            oldPolIds.add(policy.Id);
        }
        Map<String, Object> smartCheck = checkSmartPrograms(oldPolIds, newPolIds);
        Map<Id, String> smartUpgrade = (Map<Id, String>)smartCheck.get('smartUpgrade');
        Map<Id, Boolean> prevSmart = (Map<Id, Boolean>)smartCheck.get('prevSmart');
        Map<Id, Boolean> currentSmart = (Map<Id, Boolean>)smartCheck.get('currentSmart');
        Map<Id, Integer> dependentMonths = checkDependentMonths(participants);

        for (InsurancePolicyParticipant part : participants) {
            String productCode = part.InsurancePolicy.Product.ProductCode;
            if (productCode.contains('Legacy')) continue;
            Map<Id, String> memberPrograms = getMemberCoverages(part.Coverage_Participants__r);
            if (memberPrograms.get(part.PrimaryParticipantContactId) == null) continue;
            List<String> periodCoverage = memberPrograms.get(part.PrimaryParticipantContactId).split('_');
            Map<String, Object> wpForCoverages = new Map<String, Object>();
    
            // ITERATE OVER COVERAGES TO GET WAITING PERIODS
            for (Integer i = periodCoverage.size() - 1; i >= 0; i--) {
                String allProds = String.join(periodCoverage, '_');
                if (ctx.wpFieldsMetadata.get(allProds) == null) {
                    periodCoverage.remove(i);
                    continue;
                } else {
                    wpForCoverages = ctx.wpFieldsMetadata.get(allProds);
                    break;
                }
            }

            // ITERATE OVER WAITING PERIODS TO POPULATE FIELDS
            for (String field : ctx.wpFieldsParticipant) {
                if ((part.get(field) != null && part.get(field) == part.PrimaryParticipantContact.Birthdate) || wpForCoverages.get(field) == null) continue;
                if (newbornsDOB != null && newbornsDOB.contains(part.PrimaryParticipantContact.Birthdate)) {
                    part.put(field, part.PrimaryParticipantContact.Birthdate);
                    response.put(part.Id, part);
                    continue;
                }
                Date effDate = part.InsurancePolicy.ARC_EffectiveDate__c;
                Date lastWPResetDate = part.PrimaryParticipantContact.Account.ARC_LastWPResetDate__c;
                if (lastWPResetDate > effDate || lastWPResetDate == null) continue;
                switch on field {
                    // CATARACTS/GLAUCOMA NOT INCLUDED ON ACCESS PROGRAMS
                    when 'WP_Glacoma__c' {
                        if (!productCode.contains('Access')) {
                            part.put(field, lastWPResetDate.addMonths(Integer.ValueOf(wpForCoverages.get(field))));
                        }
                    }
                    when 'WP_Cancer__c' {
                        if ((prevSmart.get(part.PrimaryParticipantContactId) == null && currentSmart.get(part.PrimaryParticipantContactId) == true)) {
                            // SMART ADDED
                            part.put(field, lastWPResetDate.addMonths(2));
                        } else if (prevSmart.get(part.PrimaryParticipantContactId) == true && currentSmart.get(part.PrimaryParticipantContactId) == null) {
                            // SMART REMOVED
                            part.put(field, lastWPResetDate.addMonths(12));
                        } else {
                            part.put(field, lastWPResetDate.addMonths(Integer.ValueOf(wpForCoverages.get(field))));
                        }
                    }
                    // IMMUNIZATIONS - 10 MONTHS FOR +18 ENROLLED AGE AND 6 MONTHS FOR -18 ENROLLED AGE 
                    when 'WP_Immunizations__c' {
                        if (!productCode.contains('Access') && productCode.contains('WeShare') && dependentMonths.get(part.PrimaryParticipantContactId) != null) {
                            if (dependentMonths.get(part.PrimaryParticipantContactId) > 18) {
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
                response.put(part.Id, part);
            }
        }
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
     * @MethodName         :   prevPolCarryOver
     * @Description        :   Carry over WP using the screen flow button
     ********************************************************************/
    public class InputVariables {
        @InvocableVariable
        public Id policyId;

        @InvocableVariable
        public Id priorPolicyId;
    }
    @InvocableMethod(label='CarryOverWP' description='Carry over WP from previous Policy' category='Policy')
    public static void prevPolCarryOver(List<InputVariables> inpVariables) {
        String polId = inpVariables[0].policyId;
        String priorPolId = inpVariables[0].priorPolicyId;
        List<String> wpFieldsParticipant = new List<String>();
        List<InsurancePolicyParticipant> partsToUpdate = new List<InsurancePolicyParticipant>();

        // GET POLICY AND PARTICIPANTS TO CARRY OVER
        for (Schema.SObjectField field : InsurancePolicyParticipant.getSObjectType().getDescribe().fields.getMap().values()) {
            if (String.valueOf(field).startsWith('WP')) {
                wpFieldsParticipant.add(String.valueOf(field.getDescribe().getName()));
            }  
        }

        String queryPol = 
            'SELECT Id, PrimaryParticipantContactId, InsurancePolicyId, ' +
                String.join(wpFieldsParticipant, ', ') + ' ' +
            'FROM InsurancePolicyParticipant ' +
            'WHERE InsurancePolicyId = \''+ polId + '\' OR InsurancePolicyId = \''+ priorPolId + '\' LIMIT 5000'; 
        List<InsurancePolicyParticipant> parts = Database.query(queryPol);
        if (parts.size() == 0) return;

        // CARRY OVER WP
        Map<Id, InsurancePolicyParticipant> oldPartsMap = new Map<Id, InsurancePolicyParticipant>();
        for (InsurancePolicyParticipant part : parts) {
            if (part.InsurancePolicyId == priorPolId) {
                oldPartsMap.put(part.PrimaryParticipantContactId, part);
            }
        }
        for (InsurancePolicyParticipant part : parts) {
            if (part.InsurancePolicyId == priorPolId) continue;
            InsurancePolicyParticipant oldPart = oldPartsMap.get(part.PrimaryParticipantContactId);
            if (oldPart == null) continue;

            for (String field : wpFieldsParticipant) {
                part.put(field, oldPart.get(field));
            }
            partsToUpdate.add(part);
        }

        if (partsToUpdate.size() > 0) update partsToUpdate;
    }

    /*******************************************************************
     * @MethodName  : isUpgrade
     * @Description : Determines whether a participant represents an upgrade based on configured upgrade reasons.
     ********************************************************************/
    private static Boolean isUpgrade(WaitingPeriodContext ctx, InsurancePolicyParticipant participant) {
        List<String> reasons = participant.InsurancePolicy.ARC_Contract__r.ARC_ContractReason__c.split(';');
        for (String reason : reasons) {
            if (ctx.upgradeReasons.contains(reason)) return true;
        }
        return false;
    }

    /*******************************************************************
     * @MethodName  : isSpinnedOffFamily
     * @Description : Determines whether a participant is part of a spinned off family.
     ********************************************************************/
    private static Boolean isSpinnedOffFamily(InsurancePolicyParticipant participant) {
        Id familyAccountId = participant.InsurancePolicy.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.vlocity_ins__GroupId__c;
        Id renewedFamilyAccountId = 
            participant.InsurancePolicy.ARC_SpinnedFromPolicy__c != null 
                ? participant.InsurancePolicy.ARC_SpinnedFromPolicy__r.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.vlocity_ins__GroupId__c 
                : null;
        List<String> reasons = participant.InsurancePolicy.ARC_Contract__r.ARC_ContractReason__c.split(';');
        Boolean isSpinOff = false;
        for (String reason : reasons) {
            if (reason == 'Spin Off') {
                isSpinOff = true;
                break;
            }
        }
        return (familyAccountId != renewedFamilyAccountId) && isSpinOff;
    }

    /*******************************************************************
     * @MethodName  : isLeaveAndComeback
     * @Description : Determines whether a participant has a gap in their membership.
     ********************************************************************/
    private static Boolean isLeaveAndComeback(WaitingPeriodContext ctx, InsurancePolicyParticipant participant) {
        Id accountId = participant.PrimaryParticipantContact.AccountId;
        Date partEffDate = participant.InsurancePolicy.ARC_EffectiveDate__c;

        if (!ctx.accountIdToPreviousPolicy.containsKey(accountId)) {
            return false;
        }

        InsurancePolicy previousPolicy = ctx.accountIdToPreviousPolicy.get(accountId);
        Date prevExpDate = previousPolicy.ARC_ExpirationDate__c;

        if (prevExpDate == null) {
            return false;
        }

        return prevExpDate != partEffDate &&
            prevExpDate.addDays(1) != partEffDate;
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
    private static void loadWaitingPeriodContext(WaitingPeriodContext ctx, List<InsurancePolicyParticipant> participants) {
        List<Waiting_Period_Config__mdt> wpConfig = Waiting_Period_Config__mdt.getAll().values();
        for (Waiting_Period_Config__mdt mtd : wpConfig) {
            if (mtd.DeveloperName == 'Upgrade_Reasons') {
                ctx.upgradeReasons = mtd.Upgrade_Reasons__c.split(',');
            } else {
                ctx.wpFieldsMetadata.put(mtd.DeveloperName, extractWpFields(mtd));
            }
        }
        ctx.wpFieldsParticipant = getWpParticipantFields();
        ctx.accountIdToPreviousPolicy = getPreviousPolicies(participants);
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

    /*******************************************************************
     * @MethodName  : shouldResetWP
     * @Description : Return true if WP should be reset for that participant, else returns false.
     ********************************************************************/
    private static Boolean shouldResetWP(WaitingPeriodContext ctx, InsurancePolicyParticipant part) {
        Boolean upgrade = isUpgrade(ctx, part);
        Boolean spinOff = isSpinnedOffFamily(part);
        Boolean comeback = isLeaveAndComeback(ctx, part);
        System.debug('upgrade: ' + upgrade + ', spinOff: ' + spinOff + ', comeback: ' + comeback);
        return upgrade || spinOff || comeback;
    }

    /*******************************************************************
     * @MethodName  : getPreviousPolicies
     * @Description : Returns a map of the last activated policy for the provided participants.
     ********************************************************************/
    private static Map<Id, InsurancePolicy> getPreviousPolicies(List<InsurancePolicyParticipant> participants) {
        Map<Id, List<InsurancePolicy>> accountIdToRelatedPolicies = getRelatedPolicies(participants);
        Map<Id, InsurancePolicy> accountIdToPreviousPolicy = new Map<Id, InsurancePolicy>();
        for (InsurancePolicyParticipant participant : participants) {
            if (participant.PrimaryParticipantContact?.AccountId == null) continue;
            Id accountId = participant.PrimaryParticipantContact.AccountId;
            List<InsurancePolicy> relatedPolicies = accountIdToRelatedPolicies.get(accountId);
            if (relatedPolicies == null) continue;
            for (InsurancePolicy policy : relatedPolicies) {
                Date partEffDate = participant.InsurancePolicy.ARC_EffectiveDate__c;
                Id partPolicy = participant.InsurancePolicyId;
                if ((policy.Id == partPolicy) || (policy.ARC_ExpirationDate__c == null)) continue;
                if ((policy.ARC_ExpirationDate__c == partEffDate) || ((policy.ARC_ExpirationDate__c).addDays(1) == partEffDate)) {
                    accountIdToPreviousPolicy.put(accountId, policy);
                }
            }
        }
        return accountIdToPreviousPolicy;
    }

    /*******************************************************************
     * @MethodName  : getRelatedPolicies
     * @Description : Returns a map of related policies for the provided participants.
     ********************************************************************/
    private static Map<Id, List<InsurancePolicy>> getRelatedPolicies(List<InsurancePolicyParticipant> participants) {
        Set<Id> accountIds = new Set<Id>();
        for (InsurancePolicyParticipant participant : participants) {
            if (participant.PrimaryParticipantContact?.AccountId != null) {
                accountIds.add(participant.PrimaryParticipantContact.AccountId);
            }
        }
        List<vlocity_ins__GroupCensusMemberPlan__c> relatedGCMP = [
            SELECT Id, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c
            FROM vlocity_ins__GroupCensusMemberPlan__c
            WHERE vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId IN :accountIds
                AND (vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Activated' OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Terminated')
                AND vlocity_ins__ContractLineId__r.vlocity_ins__ParentItemId__c = null
                AND vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical'
        ];
        Map<Id, Set<Id>> contractToAccounts = new Map<Id, Set<Id>>();
        for (vlocity_ins__GroupCensusMemberPlan__c gcmp : relatedGCMP) {
            Id contractId = gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c;
            Id accountId = gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId;
            if (contractId == null || accountId == null) continue;

            if (!contractToAccounts.containsKey(contractId)) {
                contractToAccounts.put(contractId, new Set<Id>());
            }
            contractToAccounts.get(contractId).add(accountId);
        }
        Set<Id> contractIds = new Set<Id>();
        for (vlocity_ins__GroupCensusMemberPlan__c gcmp : relatedGCMP) {
            contractIds.add(gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c);
        }
        List<InsurancePolicy> relatedPolicies = [
            SELECT Id, ARC_EffectiveDate__c, ARC_ExpirationDate__c, ARC_Contract__c
            FROM InsurancePolicy
            WHERE ARC_Contract__c IN :contractIds
            ORDER BY ARC_Contract__r.ARC_EffectiveDate__c ASC, ARC_Contract__r.CreatedDate ASC
        ];
        Map<Id, List<InsurancePolicy>> accountIdToRelatedPolicies = new Map<Id, List<InsurancePolicy>>();
        for (InsurancePolicy policy : relatedPolicies) {
            Set<Id> accounts = contractToAccounts.get(policy.ARC_Contract__c);
            if (accounts == null) continue;
            for (Id accId : accounts) {
                if (!accountIdToRelatedPolicies.containsKey(accId)) {
                    accountIdToRelatedPolicies.put(accId, new List<InsurancePolicy>());
                }
                accountIdToRelatedPolicies.get(accId).add(policy);
            }
        }
        return accountIdToRelatedPolicies;
    }
}