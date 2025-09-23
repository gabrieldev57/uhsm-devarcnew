public with sharing class ARC_WaitingPeriodsLogic {
    
    /*******************************************************************
     * @MethodName         :   stampWaitingPeriods
     * @Description        :   Parent method to create waiting periods
     ********************************************************************/
    public static void stampWaitingPeriods(Set<Id> contractList, List<Date> newbornsDOB) {
        List<Waiting_Period_Config__mdt> wpConfig = Waiting_Period_Config__mdt.getAll().values();
        List<InsurancePolicy> policies = [
            SELECT Id, ARC_Contract__r.ARC_ContractReason__c, ARC_EffectiveDate__c, PriorPolicyId, Product.Name, NameInsuredId,
                (SELECT Id, ARC_PolicyParticipant__r.PrimaryParticipantContactId, ARC_PolicyParticipant__r.PrimaryParticipantContact.Birthdate, ARC_CoverageName__c, ARC_PolicyParticipant__r.PrimaryParticipantContact.vlocity_ins__Age__c, ARC_PolicyParticipant__r.Role
                FROM CoverageParticipants__r)
            FROM InsurancePolicy
            WHERE ARC_Contract__c IN :contractList
        ];
        List<String> upgradeReasons = new List<String>();
        Map<String, Map<String, Object>> wpFieldsMetadata = new Map<String, Map<String, Object>>();
        List<String> wpFieldsParticipant = new List<String>();
        if (policies.size() == 0) return;

        // CREATE MAPS WITH VALUES FOR WAITING PERIODS AND UPGRADE REASONS
        for (Waiting_Period_Config__mdt mtd : wpConfig) {
            if (mtd.DeveloperName == 'Upgrade_Reasons') {
                upgradeReasons = mtd.Upgrade_Reasons__c.split(',');
            } else {
                Map<String, Object> wpValues = new Map<String, Object>();
                for (Schema.SObjectField field : mtd.getSObjectType().getDescribe().fields.getMap().values()) {
                    if (String.valueOf(field).startsWith('WP')) {
                        wpValues.put(String.valueOf(field.getDescribe().getName()), mtd.get(String.valueOf(field.getDescribe().getName())));
                    }
                }
                wpFieldsMetadata.put(mtd.DeveloperName, wpValues);
            }
        }

        // ITERATE OVER CONTRACTS AND CHECK IF IT IS A UPGRADE
        List<InsurancePolicy> resetPolicies = new List<InsurancePolicy>();
        List<InsurancePolicy> carryOverPolicies = new List<InsurancePolicy>();
        for (InsurancePolicy pol : policies) {
            if (pol?.ARC_Contract__r?.ARC_ContractReason__c != null) {
                if (upgradeReasons.contains(pol.ARC_Contract__r.ARC_ContractReason__c)) {
                    resetPolicies.add(pol);
                } else {
                    carryOverPolicies.add(pol);
                }               
            }
        }

        // GET POLICY PARTICIPANT WAITING PERIODS FIELDS
        for (Schema.SObjectField field : InsurancePolicyParticipant.getSObjectType().getDescribe().fields.getMap().values()) {
            if (String.valueOf(field).startsWith('WP')) {
                wpFieldsParticipant.add(String.valueOf(field.getDescribe().getName()));
            }
        }
        
        Map<Id, InsurancePolicyParticipant> resetParts = resetPolicies.size() > 0 ? ARC_WaitingPeriodsLogic.resetWP(resetPolicies, wpFieldsMetadata, wpFieldsParticipant, new List<InsurancePolicyParticipant>(), newbornsDOB) : new Map<Id, InsurancePolicyParticipant>();
        Map<Id, InsurancePolicyParticipant> carryOverParts = carryOverPolicies.size() > 0 ? ARC_WaitingPeriodsLogic.carryOverWP(carryOverPolicies, wpFieldsMetadata, wpFieldsParticipant, newbornsDOB) : new Map<Id, InsurancePolicyParticipant>();
        if (resetParts.size() > 0) update resetParts.values();
        if (carryOverParts.size() > 0) update carryOverParts.values();
    }

    /*******************************************************************
     * @MethodName         :   resetWP
     * @Description        :   Reset waiting periods for policies that are upgrades
     ********************************************************************/
    public static Map<Id, InsurancePolicyParticipant> resetWP(List<InsurancePolicy> policies, Map<String, Map<String, Object>> wpFieldsMetadata, List<String> wpFieldsParticipant, List<InsurancePolicyParticipant> newParticipants, List<Date> newbornsDOB) {
        Map<Id, InsurancePolicyParticipant> response = new Map<Id, InsurancePolicyParticipant>();
        List<InsurancePolicyParticipant> participants = new List<InsurancePolicyParticipant>();

        // GET PARTICIPANTS AND FIELDS FOR WAITING PERIODS ONLY IF THE WP FIELDS ARE BLANK
        if (newParticipants.size() == 0) {
            String strQuery = 'SELECT Id, PrimaryParticipantContactId, PrimaryParticipantContact.Birthdate, PrimaryParticipantContact.vlocity_ins__Age__c, InsurancePolicyId, ';
            strQuery += String.join(wpFieldsParticipant, ', ');
            strQuery += ' FROM InsurancePolicyParticipant WHERE InsurancePolicyId IN :policies LIMIT 5000';
            participants = Database.query(strQuery);
        } else {
            participants = newParticipants;
        }

        Map<Id, Integer> dependentOlder = checkDependentMonths(policies);

        // ITERATE OVER PARTICIPANTS AND THEIR COVERAGES TO POPULATE WAITING PERIODS
        for (InsurancePolicy pol : policies) {
            if (pol.ARC_Contract__r.ARC_ContractReason__c == null) continue;
            Map<Id, String> memberPrograms = getMemberCoverages(pol, pol.CoverageParticipants__r);
            for (InsurancePolicyParticipant part : participants) {
                if (pol.Id == part.InsurancePolicyId) {
                    if (memberPrograms.get(part.PrimaryParticipantContactId) == null) continue;
                    List<String> periodCoverage = memberPrograms.get(part.PrimaryParticipantContactId).split('_');
                    Map<String, Object> wpForCoverages = new Map<String, Object>();
    
                    // ITERATE OVER COVERAGES TO GET WAITING PERIODS
                    for (Integer i = periodCoverage.size() - 1; i >= 0; i--) {
                        String allProds = String.join(periodCoverage, '_');
                        if (wpFieldsMetadata.get(allProds) == null) {
                            periodCoverage.remove(i);
                            continue;
                        } else {
                            wpForCoverages = wpFieldsMetadata.get(allProds);
                            break;
                        }
                    }            

                    // ITERATE OVER WAITING PERIODS TO POPULATE FIELDS
                    for (String field : wpFieldsParticipant) {
                        System.debug('field: ' + field);
                        System.debug('part.get(field): ' + part.get(field));
                        System.debug('bool: ' + part.get(field) != null && part.get(field) == part.PrimaryParticipantContact.Birthdate);
                        if (part.get(field) != null && part.get(field) == part.PrimaryParticipantContact.Birthdate) continue;
                        Date effDate = pol.ARC_EffectiveDate__c;
                        switch on field {
                            // CATARACTS/GLAUCOMA NOT INCLUDED ON ACCESS PROGRAMS
                            when 'WP_Glacoma__c' {
                                if (newbornsDOB != null && newbornsDOB.contains(part.PrimaryParticipantContact.Birthdate)) {
                                    part.put(field, part.PrimaryParticipantContact.Birthdate);
                                } else if (!pol.Product.Name.contains('Access')) {
                                    part.put(field, effDate.addMonths(Integer.ValueOf(wpForCoverages.get(field))));
                                }
                            }
                            // IMMUNIZATIONS - 10 MONTHS FOR +18 MONTHS ENROLLED AGE AND 6 MONTHS FOR -18 MONTHS ENROLLED AGE 
                            when 'WP_Immunizations__c' {
                                if (newbornsDOB != null && newbornsDOB.contains(part.PrimaryParticipantContact.Birthdate)) {
                                    part.put(field, part.PrimaryParticipantContact.Birthdate);
                                } else if (!pol.Product.Name.contains('Access') && pol.Product.Name.contains('WeShare') && dependentOlder.get(part.PrimaryParticipantContactId) != null) {
                                    if (dependentOlder.get(part.PrimaryParticipantContactId) > 18) {
                                        part.put(field, effDate.addMonths(10));
                                    } else {
                                        part.put(field, effDate.addMonths(6));
                                    }
                                }
                            }
                            when else {
                                if (newbornsDOB != null && newbornsDOB.contains(part.PrimaryParticipantContact.Birthdate)) {
                                    part.put(field, part.PrimaryParticipantContact.Birthdate);
                                } else {
                                    part.put(field, effDate.addMonths(Integer.ValueOf(wpForCoverages.get(field))));
                                }
                            }
                        }

                        response.put(part.Id, part);
                    }
                }
            }           
        }
        return response;
    }
    
    /*******************************************************************
     * @MethodName         :   getMemberCoverages
     * @Description        :   Create a map with member programs
     ********************************************************************/
    public static Map<Id, String> getMemberCoverages(InsurancePolicy pol, List<ARC_CoverageParticipant__c> coverages) {
        Map<Id, String> response = new Map<Id, String>();
        Map<Id, List<Integer>> memberProgramsOrder = new Map<Id, List<Integer>>();
        
        // GET COVERAGES FOR EVERY MEMBERS AND ORDER THEM BY PRIORITY
        for (ARC_CoverageParticipant__c cp : pol.CoverageParticipants__r) {
            List<Integer> coverageOrder = memberProgramsOrder.get(cp.ARC_PolicyParticipant__r.PrimaryParticipantContactId) != null ? memberProgramsOrder.get(cp.ARC_PolicyParticipant__r.PrimaryParticipantContactId) : new List<Integer>();
            if (cp.ARC_CoverageName__c.contains('WeShare')) {
                coverageOrder.add(1);
            } else if (cp.ARC_CoverageName__c.contains('UHSM')) {
                coverageOrder.add(2);
            } else if (cp.ARC_CoverageName__c.contains('SMART')) {
                coverageOrder.add(3);
            } else if (cp.ARC_CoverageName__c.contains('AIDD')) {
                coverageOrder.add(4);
            }
            memberProgramsOrder.put(cp.ARC_PolicyParticipant__r.PrimaryParticipantContactId, coverageOrder);
        }

        // CREATE MAP WITH MEMBER PROGRAMS AND ORDER BY PRIORITY
        for (Id memberId : memberProgramsOrder.keySet()) {
            String program = '';
            List<Integer> order = memberProgramsOrder.get(memberId);
            order.sort();

            if (order.contains(1)) program += 'WeShare_';
            if (order.contains(2)) program += 'UHSM_';
            if (order.contains(3)) program += 'SMART_';
            if (order.contains(4)) program += 'AIDD_';
            program = program.removeEnd('_');
            response.put(memberId, program);
        }

        return response;
    }

    /*******************************************************************
     * @MethodName         :   checkDependentMonths
     * @Description        :   Check for a child on family for immunization
     ********************************************************************/
    public static Map<Id, Integer> checkDependentMonths(List<InsurancePolicy> pols) {
        Map<Id, Integer> returnMap = new Map<Id, Integer>();
        for (InsurancePolicy pol : pols) {
            for (ARC_CoverageParticipant__c covPart : pol.CoverageParticipants__r) {
                if (covPart.ARC_PolicyParticipant__r.Role != 'Dependent' || returnMap.get(covPart.ARC_PolicyParticipant__r.PrimaryParticipantContactId) != null) continue;

                returnMap.put(covPart.ARC_PolicyParticipant__r.PrimaryParticipantContactId, covPart.ARC_PolicyParticipant__r.PrimaryParticipantContact.Birthdate.monthsBetween(pol.ARC_EffectiveDate__c));
            }
        }

        return returnMap;
    }

    /*******************************************************************
     * @MethodName         :   carryOverWP
     * @Description        :   Carry over waiting periods for policies that are not upgrades
     ********************************************************************/
    public static Map<Id, InsurancePolicyParticipant> carryOverWP(List<InsurancePolicy> policies, Map<String, Map<String, Object>> wpFieldsMetadata, List<String> wpFieldsParticipant, List<Date> newbornsDOB) {
        Map<Id, InsurancePolicyParticipant> response = new Map<Id, InsurancePolicyParticipant>();  
        Map<Id, InsurancePolicyParticipant> oldParticipantsMap = new Map<Id, InsurancePolicyParticipant>();
        Map<Id, List<InsurancePolicyParticipant>> newParticipantsMap = new Map<Id, List<InsurancePolicyParticipant>>();
        Set<Id> oldPolIds = new Set<Id>();
        Set<Id> newPolIds = new Set<Id>();
        List<InsurancePolicyParticipant> newParticipants = new List<InsurancePolicyParticipant>();
        List<InsurancePolicy> newPolicies = new List<InsurancePolicy>();

        // GET OLD PARTICIPANTS AND FIELDS FOR WAITING PERIODS
        for (InsurancePolicy pol : policies) {
            oldPolIds.add(pol.PriorPolicyId); 
            newPolIds.add(pol.Id);
        } 
        String strQuery = 'SELECT Id, PrimaryParticipantContactId, PrimaryParticipantContact.Name, PrimaryParticipantContact.Birthdate, PrimaryParticipantContact.vlocity_ins__Age__c, InsurancePolicyId, InsurancePolicy.ARC_EffectiveDate__c, ';
        strQuery += String.join(wpFieldsParticipant, ', ');
        strQuery += ' FROM InsurancePolicyParticipant WHERE InsurancePolicyId IN :oldPolIds OR InsurancePolicyId IN :policies';

        for (InsurancePolicyParticipant part : Database.query(strQuery)) {
            if (oldPolIds.contains(part.InsurancePolicyId)) {
                oldParticipantsMap.put(part.PrimaryParticipantContactId, part);
            } else {
                List<InsurancePolicyParticipant> partsList = newParticipantsMap.get(part.InsurancePolicyId) != null ? newParticipantsMap.get(part.InsurancePolicyId) : new List<InsurancePolicyParticipant>();
                partsList.add(part);
                newParticipantsMap.put(part.InsurancePolicyId, partsList); 
            }
        }

        // CHECK FOR PREVIOUS SMART CHANGES
        Map<String, Object> smartCheck = checkSmartPrograms(oldPolIds, newPolIds);
        Map<Id, String> smartUpgrade = (Map<Id, String>)smartCheck.get('smartUpgrade');
        Map<Id, Boolean> prevSmart = (Map<Id, Boolean>)smartCheck.get('prevSmart');
        Map<Id, Boolean> currentSmart = (Map<Id, Boolean>)smartCheck.get('currentSmart');
        Map<Id, Integer> dependentMonths = checkDependentMonths(policies);

        for (InsurancePolicy pol : policies) {
            if (pol.PriorPolicyId == null) continue;

            if (newParticipantsMap.get(pol.Id) == null) continue;
            for (InsurancePolicyParticipant part : newParticipantsMap.get(pol.Id)) {
                InsurancePolicyParticipant oldPart = oldParticipantsMap.get(part.PrimaryParticipantContactId);
                if (oldPart == null) {
                    newParticipants.add(part);
                    newPolicies.add(pol);
                    continue;
                }

                // ITERATE OVER WAITING PERIODS TO POPULATE FIELDS
                for (String field : wpFieldsParticipant) {
                    if (part.get(field) != null && part.get(field) == part.PrimaryParticipantContact.Birthdate) continue;
                    if (oldPart.get(field) != null) {
                        switch on field {
                            // ADD 2 MONTHS FROM EFFECTIVE DATE
                            when 'WP_Cancer__c' {
                                if (newbornsDOB != null && newbornsDOB.contains(part.PrimaryParticipantContact.Birthdate)) {
                                    part.put(field, part.PrimaryParticipantContact.Birthdate);
                                } else if ((prevSmart.get(part.PrimaryParticipantContactId) == null && currentSmart.get(part.PrimaryParticipantContactId) == true)) {
                                    // NEW SMART
                                    part.put(field, part.InsurancePolicy.ARC_EffectiveDate__c.addMonths(2));
                                } else if (prevSmart.get(part.PrimaryParticipantContactId) == true && currentSmart.get(part.PrimaryParticipantContactId) == null) {
                                    // REMOVE SMART
                                    part.put(field, part.InsurancePolicy.ARC_EffectiveDate__c.addMonths(12));
                                } else {
                                    part.put(field, (Date)oldPart.get(field));
                                }
                            }
                            // IMMUNIZATIONS - 10 MONTHS FOR +18 ENROLLED AGE AND 6 MONTHS FOR -18 ENROLLED AGE 
                            when 'WP_Immunizations__c' {
                                if (newbornsDOB != null && newbornsDOB.contains(part.PrimaryParticipantContact.Birthdate)) {
                                    part.put(field, part.PrimaryParticipantContact.Birthdate);
                                } else if (!pol.Product.Name.contains('Access') && pol.Product.Name.contains('WeShare') && dependentMonths.get(part.PrimaryParticipantContactId) != null) {
                                    if (dependentMonths.get(part.PrimaryParticipantContactId) > 18) {
                                        part.put(field, part.InsurancePolicy.ARC_EffectiveDate__c.addMonths(10));
                                    } else {
                                        part.put(field, part.InsurancePolicy.ARC_EffectiveDate__c.addMonths(6));
                                    }
                                }
                            }
                            when else {
                                if (newbornsDOB != null && newbornsDOB.contains(part.PrimaryParticipantContact.Birthdate)) {
                                    part.put(field, part.PrimaryParticipantContact.Birthdate);
                                } else {
                                    part.put(field, (Date)oldPart.get(field));
                                }
                            }
                        }
                        
                        response.put(part.Id, part);
                    }
                }
            }
        }

        if (newParticipants.size() > 0) response.putAll(resetWP(newPolicies, wpFieldsMetadata, wpFieldsParticipant, newParticipants, newbornsDOB));
        return response;
    }

    /*******************************************************************
     * @MethodName         :   checkSmartPrograms
     * @Description        :   Check if some participants have a smart upgrade
     ********************************************************************/
    public static Map<String, Object> checkSmartPrograms(Set<Id> oldPolicies, Set<Id> newPolicies){
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

        String queryPol = 'SELECT Id, PrimaryParticipantContactId, InsurancePolicyId, ';
        queryPol += String.join(wpFieldsParticipant, ', ');
        queryPol += ' FROM InsurancePolicyParticipant WHERE InsurancePolicyId = \''+ polId + '\' OR InsurancePolicyId = \''+ priorPolId + '\' LIMIT 5000'; 
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

}