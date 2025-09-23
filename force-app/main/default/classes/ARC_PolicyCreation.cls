global without sharing class ARC_PolicyCreation implements vlocity_ins.VlocityOpenInterface {
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        if (methodName.equalsIgnoreCase('createAllPolicyRecords')) {
            createAllPolicyRecords(inputMap, outMap);
        }
        return true;
    }

    public static void createAllPolicyRecords(Map<String,Object> inputMap, Map<String,Object> outMap) {
        // GET DATA AND CREATE VARIABLES
		Id contractId = (Id)inputMap.get('contractId');
		String old_contract_reason = (String)inputMap.get('OldContractReason');
		Boolean is_reprice_omniscript = (Boolean)inputMap.get('IsRepriceOmniscript');
        Boolean is_spinoff_omniscript = (Boolean)inputMap.get('IsSpinOffOmniscript');
        Boolean is_upgraded_spinoff = (Boolean)inputMap.get('IsUpgradedSpinOff');
        List<Date> newbornsDOB = (List<Date>)inputMap.get('NewbornsDOB');
        System.debug('newbornsDOB: ' + newbornsDOB);
        Contract polContract = new Contract();
        Id medicalProduct = null;
        String accIdName = '';
        Set<Id> contrLineItemIds = new Set<Id>();

        List<vlocity_ins__ContractLineItem__c> contractPlans = [
            SELECT Id, Name, vlocity_ins__ContractId__c, vlocity_ins__ContractId__r.AccountId, vlocity_ins__ContractId__r.Account.Name, vlocity_ins__ContractId__r.vlocity_ins__ExpiredContractId__c, vlocity_ins__ContractId__r.ARC_ContractReason__c, vlocity_ins__ContractId__r.vlocity_ins__EnrollmentCensusId__c, vlocity_ins__Product2Id__c, vlocity_ins__Product2Id__r.vlocity_ins__Type__c, vlocity_ins__Product2Id__r.vlocity_ins__RecordTypeName__c, vlocity_ins__ParentItemId__r.vlocity_ins__Product2Id__c, vlocity_ins__ProductId__c, vlocity_ins__ContractId__r.ARC_EffectiveDate__c,
                (SELECT vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c, vlocity_ins__GroupCensusMemberId__r.ARC_Relationship__c, vlocity_ins__GroupCensusMemberId__r.ARC_Age__c 
                FROM vlocity_ins__Group_Census_Member_Plan__r) 
            FROM vlocity_ins__ContractLineItem__c 
            WHERE vlocity_ins__ContractId__c =: contractId LIMIT 1000
        ];
        Integer i = 0;
        for (vlocity_ins__ContractLineItem__c cLine : contractPlans) {            
            if (cLine.vlocity_ins__Product2Id__r.vlocity_ins__RecordTypeName__c == 'Product' && cLine.vlocity_ins__Product2Id__r.vlocity_ins__Type__c == 'Medical') {
                medicalProduct = cLine.vlocity_ins__Product2Id__c;
            }
            
            // ADD ONLY ON LAST ITERATION
            if (i == contractPlans.size() - 1) {
                accIdName = cLine.vlocity_ins__ContractId__r.AccountId + ';' + cLine.vlocity_ins__ContractId__r.Account.Name;
                polContract.Id = contractId;
                polContract.ARC_ContractReason__c = cLine.vlocity_ins__ContractId__r.ARC_ContractReason__c;
                polContract.vlocity_ins__ExpiredContractId__c = cLine.vlocity_ins__ContractId__r.vlocity_ins__ExpiredContractId__c;
                polContract.vlocity_ins__EnrollmentCensusId__c = cLine.vlocity_ins__ContractId__r.vlocity_ins__EnrollmentCensusId__c;
                polContract.ARC_EffectiveDate__c = cLine.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
            }
            contrLineItemIds.add(cLine.Id);
            i++;
        }
        System.debug('polContract: '+polContract);


        List<InsurancePolicy> existing_policy = [SELECT Id FROM InsurancePolicy WHERE ARC_Contract__c =: contractId];

        if (existing_policy.isEmpty() == true) {
            // CREATE AND UPDATE POLICY
            InsurancePolicy polToInsert = createPolicy(polContract, medicalProduct, accIdName, is_reprice_omniscript, is_spinoff_omniscript, is_upgraded_spinoff, old_contract_reason);
            insert polToInsert;
            
            // CREATE POLICY COVERAGES AND POLICY PARTICIPANTS
            Map<String, List<SObject>> coversAndParts = createCoveragesAndParticipants(polToInsert.Id, contractPlans);
            List<InsurancePolicyParticipant> polParticipantsToInsert = coversAndParts.get('participants');
            List<InsurancePolicyCoverage> polCoveragesToInsert = coversAndParts.get('coverages');
            insert polParticipantsToInsert;
            insert polCoveragesToInsert;

            // CREATE COVERAGE PARTICIPANT
            List<ARC_CoverageParticipant__c> partCoveragesToInsert = createParticipantCoverages(contractPlans, polParticipantsToInsert, polCoveragesToInsert, polToInsert.Id);
            insert partCoveragesToInsert;

            // UPDATE WAITING PERIODS
            ARC_WaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{contractId}, newbornsDOB);
        }
    }

    public static InsurancePolicy createPolicy(Contract contract, Id productId, String accIdName, Boolean is_reprice_omniscript, Boolean is_spinoff_omniscript, Boolean is_upgraded_spinoff, String old_contract_reason) {
        Id accId = Id.valueOf(accIdName.split(';')[0]);
        String accName = accIdName.split(';')[1];       
        
        InsurancePolicy new_policy = new InsurancePolicy();
        new_policy.Name = 'ShopAndEnroll Policy';
        new_policy.Status = 'Initial';
        new_policy.vlocity_ins_fsc__PremiumCalculationMethod__c = 'Daily';
        new_policy.vlocity_ins_fsc__PremiumPaymentType__c = 'Advance';
        new_policy.ARC_Contract__c = contract.Id;
        new_policy.ProductId = productId;
        new_policy.NameInsuredId = accId;
        new_policy.PolicyName = accName + ' - Policy';

        // POPULATE POLICY RELATIONSHIPS
        try {
            InsurancePolicy previous_policy = [
                SELECT Id, OriginalPolicyId, ARC_Contract__r.ARC_ContractReason__c, RenewedFromPolicyId, ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c, ARC_Contract__r.Status,
                    (SELECT Id
                    FROM Aggregators__r)
                FROM InsurancePolicy
                WHERE ARC_Contract__c =: contract.vlocity_ins__ExpiredContractId__c LIMIT 1
            ];
            System.debug('previous_policy: ' + previous_policy);

            System.debug('Old contract reason: ' + old_contract_reason);
            System.debug('New contract reason: ' + contract.ARC_ContractReason__c);
            String contract_reason;
            if (is_reprice_omniscript == true) {
                contract_reason = old_contract_reason;
            } else if (is_spinoff_omniscript == true && is_upgraded_spinoff == true) {
                contract_reason = 'Upgraded Spin Off';
            } else if (is_spinoff_omniscript == true) {
                contract_reason = 'Spin Off';
            } else {
                contract_reason = contract.ARC_ContractReason__c;
            }
            System.debug('Contract reason: '+contract_reason);

            // This code handles the assign of OriginalPolicy to point always to the New Application policy record.
            if (contract_reason.contains('New Application') == false) {
                if (previous_policy.OriginalPolicyId == null && previous_policy.ARC_Contract__r.ARC_ContractReason__c.contains('New Application')) {
                    new_policy.OriginalPolicyId = previous_policy.Id;
                } else {
                    new_policy.OriginalPolicyId = previous_policy.OriginalPolicyId;
                }

            // This code handles the assign of PriorPolicyId to point always to the previous policy record.
                new_policy.PriorPolicyId = previous_policy.Id;
            }

            // This code handles policy identification logic for different contract scenarios to assign the RenewedFromPolicyId
            // It determines whether a policy should be marked as renewed and links it to a previous policy with aggregators
            if (
                contract_reason.contains('New Application') == false && 
                contract_reason.contains('Program Upgrade') == false && 
                contract_reason.contains('Upgraded Spin Off') == false
            ) {
                if (previous_policy.RenewedFromPolicyId == null && previous_policy.ARC_Contract__r.Status == 'Voided') {
                    // Previous policy is upgrade and voided
                    if (previous_policy.Aggregators__r.isEmpty()) {
                        InsurancePolicy renewedPol = [
                            SELECT Id
                            FROM InsurancePolicy
                            WHERE ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c =: previous_policy.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c
                            AND ARC_Contract__r.ARC_ContractReason__c includes ('New Application' , 'Program Upgrade', 'Upgraded Spin Off')
                            AND ARC_Contract__r.Status != 'Voided'
                            ORDER BY ARC_EffectiveDate__c DESC, ARC_Contract__r.ContractNumber DESC LIMIT 1
                        ];
                        new_policy.RenewedFromPolicyId = renewedPol.Id;
                    } else {
                        new_policy.RenewedFromPolicyId = previous_policy.Id;
                    }
                } else if (previous_policy.RenewedFromPolicyId == null && previous_policy.ARC_Contract__r.Status != 'Voided') {
                    // Previous policy is upgrade not voided
                    new_policy.RenewedFromPolicyId = previous_policy.Id;
                } else {
                    // Previous policy is carry over and voided or not voided
                    new_policy.RenewedFromPolicyId = previous_policy.RenewedFromPolicyId;
                }
            } else {
                new_policy.IsRenewedPolicy = true;
            }
        } catch (Exception e) {
            System.debug('Error on policy relationships: ' + e.getMessage());
        }
        return new_policy;
    }

    public static Map<String, List<SObject>> createCoveragesAndParticipants(Id polId, List<vlocity_ins__ContractLineItem__c> contractPlans) {
        Map<String, List<SObject>> returnMap = new Map<String, List<SObject>>();
        List<InsurancePolicyCoverage> polCoverages = new List<InsurancePolicyCoverage>();
        List<InsurancePolicyParticipant> polParticipants = new List<InsurancePolicyParticipant>();

        for (vlocity_ins__ContractLineItem__c item : contractPlans) {
            InsurancePolicyCoverage polCov = new InsurancePolicyCoverage();
            polCov.CoverageName = item.Name;
            polCov.InsurancePolicyId = polId;
            polCov.vlocity_ins_fsc__Product2Id__c = item.vlocity_ins__Product2Id__c;
            polCov.ARC_ParentProduct__c = item.vlocity_ins__ProductId__c;
            polCoverages.add(polCov);
            if (item.vlocity_ins__Product2Id__r.vlocity_ins__Type__c != 'Medical' || item.vlocity_ins__Product2Id__r.vlocity_ins__RecordTypeName__c != 'Product') continue;

            // GET ROLES OF PARTICIPANTS FOR CORE PRODUCT
            Map<Id, String> partRole = new Map<Id, String>();
            Id futurePrimary;
            Id primary;
            Id spouse;
            String olderDep = '';
            for (vlocity_ins__GroupCensusMemberPlan__c gcmp : item.vlocity_ins__Group_Census_Member_Plan__r) {
                String memberRelationship = gcmp.vlocity_ins__GroupCensusMemberId__r.ARC_Relationship__c;
                partRole.put(gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c, (memberRelationship == 'Child' || memberRelationship == 'Temporary Newborn') ? 'Dependent' : memberRelationship);

                if (memberRelationship == 'Future Primary') futurePrimary = gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c;
                if (memberRelationship == 'Primary') primary = gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c;
                else if (memberRelationship == 'Spouse') spouse = gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c;
                else if (memberRelationship == 'Child') {
                    if (olderDep == '') olderDep = gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c + ';' + gcmp.vlocity_ins__GroupCensusMemberId__r.ARC_Age__c;
                    else if (gcmp.vlocity_ins__GroupCensusMemberId__r.ARC_Age__c > Integer.valueOf(olderDep.split(';')[1])) olderDep = gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c + ';' + gcmp.vlocity_ins__GroupCensusMemberId__r.ARC_Age__c;
                } 
            }

            // RESTRUCTURE ROLES OF PARTICIPANTS 
            if (primary == null) {
                if (spouse != null) partRole.put(spouse, 'Primary');
                else if (olderDep != '') partRole.put(olderDep.split(';')[0], 'Primary');
            }
            if (futurePrimary != null) {
                partRole.put(futurePrimary, 'Primary');
                partRole.put(primary, 'Dependent');
            }

            // CREATE PARTICIPANTS AND CHECK FOR FUTURE PRIMARY
            for (Id contId : partRole.keySet()) {
                InsurancePolicyParticipant polPart = new InsurancePolicyParticipant();
                polPart.InsurancePolicyId = polId;
                polPart.PrimaryParticipantContactId = contId;
                polPart.Role = partRole.get(contId);
                polPart.EffectiveDate = item.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                polPart.EffectiveDate = polPart.EffectiveDate.addHours(7);
                polParticipants.add(polPart);
            }
        }

        returnMap.put('coverages', polCoverages);
        returnMap.put('participants', polParticipants);
        return returnMap;
    }

    public static List<ARC_CoverageParticipant__c> createParticipantCoverages(List<vlocity_ins__ContractLineItem__c> contPlans, List<InsurancePolicyParticipant> parts, List<InsurancePolicyCoverage> coverags, Id polId) {
        List<ARC_CoverageParticipant__c> covPartList = new List<ARC_CoverageParticipant__c>();
        Map<Id, InsurancePolicyParticipant> mapContParticipant = new Map<Id, InsurancePolicyParticipant>(); 
        Map<String, Id> mapProdCoverage = new Map<String, Id>(); 

        Map<Id, Integer> prodNumCreation = new Map<Id, Integer>();
        for (InsurancePolicyParticipant part : parts) mapContParticipant.put(part.PrimaryParticipantContactId, part);
        for (InsurancePolicyCoverage cover : coverags) {
            if (cover.ARC_ParentProduct__c != null) continue;
            
            Integer pNum = prodNumCreation.get(cover.vlocity_ins_fsc__Product2Id__c) != null ? (Integer)prodNumCreation.get(cover.vlocity_ins_fsc__Product2Id__c) : 0; 
            Integer pTimes = ++pNum;
            prodNumCreation.put(cover.vlocity_ins_fsc__Product2Id__c, pTimes);

            mapProdCoverage.put(cover.vlocity_ins_fsc__Product2Id__c + ';' + pTimes, cover.Id);
        }

        Map<Id, List<InsurancePolicyParticipant>> covIdParticipant = new Map<Id, List<InsurancePolicyParticipant>>();
        Map<Id, Integer> prodNumIteration = new Map<Id, Integer>();
        for (vlocity_ins__ContractLineItem__c item : contPlans) {
            if (item.vlocity_ins__Product2Id__r.vlocity_ins__RecordTypeName__c == 'Product') {
                Integer pNum = prodNumIteration.get(item.vlocity_ins__Product2Id__c) != null ? (Integer)prodNumIteration.get(item.vlocity_ins__Product2Id__c) : 0; 
                Integer pTimes = ++pNum;
                prodNumIteration.put(item.vlocity_ins__Product2Id__c, pTimes);
    
                for (vlocity_ins__GroupCensusMemberPlan__c gcmp : item.vlocity_ins__Group_Census_Member_Plan__r) {
                    if (mapProdCoverage.get(item.vlocity_ins__Product2Id__c + ';' + pTimes) != null && mapContParticipant.get(gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c) != null) {
                        String prodMapKey = mapProdCoverage.get(item.vlocity_ins__Product2Id__c + ';' + pTimes);
    
                        ARC_CoverageParticipant__c cp = new ARC_CoverageParticipant__c();
                        cp.ARC_PolicyParticipant__c = mapContParticipant.get(gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c).Id;
                        cp.ARC_PolicyCoverage__c = Id.valueOf(prodMapKey.split(';')[0]);
                        cp.ARC_Policy__c = polId;
                        covPartList.add(cp);

                        List<InsurancePolicyParticipant> polParts = covIdParticipant.get(prodMapKey.split(';')[0]) != null ? covIdParticipant.get(prodMapKey.split(';')[0]) : new List<InsurancePolicyParticipant>();
                        polParts.add(mapContParticipant.get(gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c));
                        covIdParticipant.put(Id.valueOf(prodMapKey.split(';')[0]), polParts);
                    }
                }
            }
        }

        // CALCULATE COVERAGE ROLE
        Map<String, String> covParticipants = new Map<String, String>();
        Map<String, Id> rolePart = new Map<String, Id>();
        for (Id covId : covIdParticipant.keySet()) {
            Boolean primary = false;
            Boolean spouse = false;

            for (InsurancePolicyParticipant part : covIdParticipant.get(covId)) {
                if (part.Role == 'Child' || part.Role == 'Dependent') {
                    covParticipants.put(String.valueOf(part.Id) + String.valueOf(covId), 'Dependent');
                } else {
                    rolePart.put(part.Role, part.Id);
                }

                if (part.Role == 'Primary') primary = true;
                if (part.Role == 'Spouse') spouse = true;
            }

            if (primary && spouse) {
                covParticipants.put(String.valueOf(rolePart.get('Primary')) + String.valueOf(covId), 'Primary');
                covParticipants.put(String.valueOf(rolePart.get('Spouse')) + String.valueOf(covId), 'Spouse');
            } else if (!primary && spouse) {
                covParticipants.put(String.valueOf(rolePart.get('Spouse')) + String.valueOf(covId), 'Primary');
            } else if (primary && !spouse) {
                covParticipants.put(String.valueOf(rolePart.get('Primary')) + String.valueOf(covId), 'Primary');
            }
        }
        for (ARC_CoverageParticipant__c covPart : covPartList) {
            covPart.ARC_CoverageRole__c = covParticipants.get(String.valueOf(covPart.ARC_PolicyParticipant__c) + String.valueOf(covPart.ARC_PolicyCoverage__c));
        }

        return covPartList;
    }
}