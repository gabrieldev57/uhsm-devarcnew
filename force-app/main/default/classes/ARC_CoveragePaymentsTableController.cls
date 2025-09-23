global without sharing class ARC_CoveragePaymentsTableController implements vlocity_ins.VlocityOpenInterface {
    public Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {
        if (methodName == 'getAllOptions') {
            getAllOptions(inputMap, outputMap);
        } else if (methodName == 'getAllCoveragePayments') {
            getAllCoveragePayments(inputMap, outputMap);
        } else if (methodName == 'updateCovPaymentStatus') {
            updateCovPaymentStatus(inputMap, outputMap);
        } else if (methodName == 'createItemPayments') {
            createItemPayments(inputMap, outputMap);
        } else if (methodName == 'uncommitAllChanges') {
            uncommitAllChanges(inputMap, outputMap);
        } else if (methodName == 'saveLineItems') {
            saveLineItems(inputMap, outputMap);
        } else if (methodName == 'CheckForDuplicateClaim2') {
            CheckForDuplicateClaim2(inputMap, outputMap);
        } else if (methodName == 'CheckForDuplicateClaim2DeDuplicate') {
            CheckForDuplicateClaim2DeDuplicate(inputMap, outputMap);
        } else if (methodName == 'CheckForDuplicateClaim2InIt') {
            CheckForDuplicateClaim2InIt(inputMap, outputMap);
        } else if (methodName == 'deleteItems') {
            deleteItems(inputMap, outputMap);
        }
        return true;
    }

    @AuraEnabled
    public static void CheckForDuplicateClaim2DeDuplicate(Map<String, Object> inputMap, Map<String, Object> outputMap) {
        String duplicateStatus;
        List<Claim> ClaimLists = new List<Claim>();
        String claimId = String.valueOf(inputMap.get('claimId'));
        List<Claim> claimList = [
            SELECT id, ARC_PartialDuplicate__c, ARC_Duplicate__c, De_Duplicate_Flag__c, ARC_Duplicate_SMB__c
            FROM Claim
            WHERE id = :claimId
        ];
        for (Claim clm : claimList) {
            clm.De_Duplicate_Flag__c = true;
            ClaimLists.add(clm);
            if (!clm.ARC_PartialDuplicate__c && !clm.ARC_Duplicate__c) {
                duplicateStatus = 'duplicatesChecked';
            } else if (clm.ARC_PartialDuplicate__c && !clm.ARC_Duplicate__c) {
                duplicateStatus = 'partialDupeClaims';
            } else if (clm.ARC_Duplicate__c) {
                duplicateStatus = 'duplicatesFound';
            }
        }

        if (ClaimLists.size() > 0) {
            update ClaimLists;
        }

        outputMap.put('duplicateStatus', duplicateStatus);
    }

    @AuraEnabled
    public static void CheckForDuplicateClaim2InIt(Map<String, Object> inputMap, Map<String, Object> outputMap) {
        String claimId = String.valueOf(inputMap.get('claimId'));
        List<Claim> claimList = [
            SELECT id, ARC_PartialDuplicate__c, ARC_Duplicate__c, De_Duplicate_Flag__c, ARC_Duplicate_SMB__c
            FROM Claim
            WHERE id = :claimId
        ];
        String duplicateStatus;
        if (claimList[0].ARC_PartialDuplicate__c && !claimList[0].ARC_Duplicate__c && claimList[0].De_Duplicate_Flag__c) {
            duplicateStatus = 'partialMoveAheadDupeClaims';
        } else if (claimList[0].ARC_Duplicate__c && claimList[0].De_Duplicate_Flag__c) {
            duplicateStatus = 'duplicatesMoveAheadFound';
        } else if (claimList[0].ARC_PartialDuplicate__c && !claimList[0].ARC_Duplicate__c) {
            duplicateStatus = 'partialDupeClaims';
        } else if (claimList[0].ARC_Duplicate__c) {
            duplicateStatus = 'duplicatesFound';
        } else if (claimList[0].De_Duplicate_Flag__c) {
            duplicateStatus = 'duplicatesChecked';
        } else {
            duplicateStatus = 'None';
        }

        outputMap.put('duplicateStatus', duplicateStatus);
    }
    @AuraEnabled
    public static void CheckForDuplicateClaim2(Map<String, Object> inputMap, Map<String, Object> outputMap) {
        String claimId = String.valueOf(inputMap.get('claimId'));
        Claim claim = [
            SELECT Id, Name, ARC_MemberContact__c, PolicyNumberId, ARC_ClaimTotalAmount__c, ARC_DOSFrom__c, ARC_Vendor__r.Name
            FROM Claim
            WHERE Id =: claimId
            LIMIT 1
        ];
        if (claim.ARC_MemberContact__c == null) {
            outputMap.put('errorMessage', 'Duplicate detection warning: Member missing');
            return;
        } else if (claim.PolicyNumberId == null) {
            outputMap.put('errorMessage', 'Duplicate detection warning: Policy number missing');
            return;
        } else if (claim.ARC_DOSFrom__c == null) {
            outputMap.put('errorMessage', 'Duplicate detection warning: DOS missing');
            return;
        } else if (claim.ARC_ClaimTotalAmount__c == null) {
            outputMap.put('errorMessage', 'Duplicate detection warning: Total ammount missing');
            return;
        } else if (claim.ARC_Vendor__r.Name == null) {
            outputMap.put('errorMessage', 'Duplicate detection warning: Vendor name missing');
            return;
        }
        String duplicateType = ARC_CheckForDuplicateClaimHandler.CheckForDuplicateClaim(new List<Id>{ claimId });
        outputMap.put('duplicatesFound', duplicateType);
    }

    public static void getAllOptions(Map<String, Object> inputMap, Map<String, Object> outputMap) {
        String claimId = String.valueOf(inputMap.get('claimId'));
        List<String> pickListValuesList = new List<String>();
        RecordType rarcRT = [SELECT Id FROM RecordType WHERE sObjectType = 'vlocity_ins__Vlocitycode__c' AND Name = 'RARC' LIMIT 1];

        List<vlocity_ins__VlocityCode__c> codes = [
            SELECT Name, Id, vlocity_ins__ShortDescription__c, ARC_Status__c
            FROM vlocity_ins__VlocityCode__c
            WHERE ARC_Level__c = 'Line' AND vlocity_ins__IsActive__c = TRUE AND RecordTypeId = :rarcRT.Id
            LIMIT 50000
        ];
        List<ClaimCoverage> coverages = [SELECT Id, Name FROM ClaimCoverage WHERE ClaimId = :claimId AND Name = 'Not covered' LIMIT 1000];
        Claim clm = [SELECT Id, RecordTypeId, RecordType.Name, ARC_DOSFrom__c, ARC_DOSTo__c, ARC_ItemsCounter__c FROM Claim WHERE Id = :claimId];
        RecordType clmRt = [SELECT Id, Name FROM RecordType WHERE sObjectType = 'Claim' AND Id = :clm.RecordTypeId LIMIT 1];
        RecordType itemRt = new RecordType();
        if (clmRt.Name == 'Professional') {
            itemRt = [SELECT Id FROM RecordType WHERE sObjectType = 'ClaimCoveragePaymentDetail' AND DeveloperName = 'ARC_Professional' LIMIT 1];
        } else if (clmRt.Name == 'Institutional') {
            itemRt = [SELECT Id FROM RecordType WHERE sObjectType = 'ClaimCoveragePaymentDetail' AND DeveloperName = 'ARC_Institutional' LIMIT 1];
        }

        Schema.DescribeFieldResult fieldResult = ClaimCoveragePaymentDetail.Status.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            pickListValuesList.add(pickListVal.getLabel());
        }
        outputMap.put('statuses', pickListValuesList);
        outputMap.put('coverages', coverages);
        outputMap.put('reasonCodes', codes);
        outputMap.put('claimItemRTypeId', itemRt.Id);
        outputMap.put('clmInfo', clm);
    }

    public static void getAllCoveragePayments(Map<String, Object> inputMap, Map<String, Object> outputMap) {
        Map<String, Object> covPayments = new Map<String, Object>();
        String claimId = String.valueOf(inputMap.get('claimId'));
        Claim clm = [
            SELECT
                Name,
                Id,
                Status,
                RecordType.DeveloperName,
                ARC_Refund__c,
                ARC_RefundAmount__c,
                ARC_Total_PreExistingConditions__c,
                ARC_ClaimTotalAmount__c,
                ARC_TotalAllowedAmount__c,
                ARC_TotalAdjustedAmount__c,
                ARC_TotalPrimaryPaidAmount__c,
                ARC_TotalCopayAmount__c,
                ARC_TotalCoinsuranceAmount__c,
                ARC_TotalDeductibleAmount__c,
                ARC_TotalMBRLiabilityAmount__c,
                ARC_TotalNetPaidAmount__c,
                ARC_TotalTobacco__c,
                ARC_Adjust__c,
                ARC_OriginalSMB__c,
                ARC_OriginalSMB__r.ARC_TotalNetPaidAmount__c,
            	ARC_MemberBenefitPlan__c
            FROM Claim
            WHERE Id = :claimId
        ];
        List<ClaimCoveragePaymentDetail> records = [
            SELECT
                Id,
                Name,
                AdjustedAmount,
                ARC_Medical_Visit_Reason__c,
                ARC_MaximumType__c,
                ARC_MaximumTypeAmount__c,
                ARC_Pre_Existing_Condition__c,
                ARC_Tobacco__c,
                ClaimedAmount,
                ClaimCoverage.Name,
                Status,
                ClaimParticipantRecipient.ParticipantContact.Name,
                ARC_ProcedureCode__c,
                ARC_ProcedureCodeName__c,
                ARC_PlaceOfService__c,
                ARC_Quantity__c,
                ARC_DOSFrom__c,
                ARC_RevenueCode__c,
                ARC_RateCode__c,
                ARC_Mod1__c,
                ARC_Mod2__c,
                ARC_Mod3__c,
                ARC_Mod4__c,
                ARC_FreqType__c,
                ARC_Allowed__c,
                ARC_PrimaryPaid__c,
                ARC_Copay__c,
                ARC_Coinsurance__c,
                ARC_Deductible__c,
                ARC_MBRLiability__c,
                ARC_Interest__c,
                ARC_Penalty__c,
                ARC_NetPaid__c,
                ARC_NonCoveragesCharges__c,
                ARC_WHold__c,
                ARC_DOSTo__c,
                ARC_DateOfService__c,
                ICD_Codes__c,
            	Medicare_Allowed__c,
                Medicare_Paid__c,
                Medicare_Member_Liability__c,
                (SELECT Name, Id, ARC_CodeNameText__c, ARC_CodeDescription__c FROM Claim_Reason_Codes__r)
            FROM ClaimCoveragePaymentDetail
            WHERE ARC_Claim__c = :claimId
            ORDER BY ARC_ItemNumber__c NULLS LAST
            LIMIT 1000
        ];

        outputMap.put('items', records);
        outputMap.put('claimData', clm);
        
        // ADD CHECK TO SEE IF LEGACY IS IN NAME OF PLAN - THROTTLE COLUMNS ON TABLE ACCORDINGLY
        Boolean isLegacy = clm.ARC_MemberBenefitPlan__c != null && clm.ARC_MemberBenefitPlan__c.containsIgnoreCase('Legacy');
		outputMap.put('isLegacy', isLegacy);
        
    }

    public static void updateCovPaymentStatus(Map<String, Object> inputMap, Map<String, Object> outputMap) {
        String status = (String) inputMap.get('status');
        List<Object> reasonCodeList = (List<Object>) inputMap.get('reasonCodeList');
        Map<String, String> reasonCodeMap = new Map<String, String>();
        for (Object reasonCode : (List<Object>)reasonCodeList) {
            Map<String, Object> reasonCodeM = (Map<String, Object>) reasonCode;
            String id = (String)reasonCodeM.get('id');
            String code = (String)reasonCodeM.get('code');
            reasonCodeMap.put(id, code);
        }
        System.debug(reasonCodeList);
        System.debug(reasonCodeMap);
        List<Object> codes = (List<Object>) inputMap.get('codes');
        List<Object> itemsList = (List<Object>) inputMap.get('ids');
        List<Object> itemsMod = (List<Object>) inputMap.get('itemsMod');
        Set<Id> itemIdsSet = (Set<Id>) JSON.deserialize(JSON.serialize(itemsList), Set<Id>.class);
        String errorOnUpdate;
        Boolean updateDone = true;
        try {
            List<ClaimCoveragePaymentDetail> items = [SELECT Id, Name, Status, ARC_Allowed__c FROM ClaimCoveragePaymentDetail WHERE Id IN :itemIdsSet LIMIT 1000];
            if (items.size() > 0) {
                List<sObject> itemsToUpdate = new List<sObject>();
                List<sObject> itemList = new List<sObject>();

                for (ClaimCoveragePaymentDetail item : items) {
                    if (item.Status != 'Paid') {
                        item.Status = status;
                        itemsToUpdate.add(item);
                    }

                    if (codes.size() > 0) {
                        for (Object codeId : codes) {
                            ARC_ClaimReasonCode__c reasonCode = new ARC_ClaimReasonCode__c();
                            reasonCode.ARC_ClaimCoveragePaymentDetail__c = item.Id;
                            reasonCode.ARC_ReasonCode__c = Id.valueOf(String.valueOf(codeId));
                            System.debug(reasonCodeMap.get(reasonCode.ARC_ReasonCode__c));
                            if (reasonCodeMap.get(String.valueOf(codeId)) == 'DACC') {
                                item.ARC_MBRLiability__c = item.ARC_Allowed__c;
                            }
                            itemList.add(reasonCode);
                        }
                    }
                }
                if (itemList.size() > 0)
                    insert itemList;
                if (itemsToUpdate.size() > 0) {
                    Database.SaveResult[] results = Database.update(itemsToUpdate, false);
                    for (Database.SaveResult result : results) {
                        if (!result.isSuccess()) {
                            for (Database.Error err : result.getErrors())
                                errorOnUpdate = errorOnUpdate == null ? err.getMessage() : errorOnUpdate + ' - ' + err.getMessage();
                            updateDone = false;
                        }
                    }
                    if (!updateDone)
                        throw new AuraHandledException('Error updating items');
                }
                outputMap.put('result', 'updated');
            }
            if (itemsMod.size() > 0) {
                List<ClaimCoveragePaymentDetail> ccpdToUpdate = new List<ClaimCoveragePaymentDetail>();

                for (Object itemMap : itemsMod) {
                    Map<String, Object> item_reason = (Map<String, Object>) itemMap;

                    ClaimCoveragePaymentDetail ccpd = new ClaimCoveragePaymentDetail();
                    ccpd.Id = Id.valueOf((String) item_reason.get('item'));

                    if ((String) item_reason.get('reason') == 'Accupuncture') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'Acupuncture';
                    } else if ((String) item_reason.get('reason') == 'P. Therapy') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'PhysicalTherapy';
                    } else if ((String) item_reason.get('reason') == 'Behavioral') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'Behavioral';
                    } else if ((String) item_reason.get('reason') == 'Chiropractic') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'Chiropractic';
                    } else if ((String) item_reason.get('reason') == 'Urgent Care') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'Urgent Care';
                    } else if ((String) item_reason.get('reason') == 'Office Visit/Copay') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'Office Visit/Copay';
                    } else if ((String) item_reason.get('reason') == 'Cervical Cancer Screenings') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'Cervical Cancer Screenings';
                    } else if ((String) item_reason.get('reason') == 'CC - Self-Screen Option') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'CC - Self-Screen Option';
                    } else if ((String) item_reason.get('reason') == 'CC - Flexible Sigmoisoscopy') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'CC - Flexible Sigmoisoscopy';
                    } else if ((String) item_reason.get('reason') == 'CC - Colonoscopy') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'CC - Colonoscopy';
                    } else if ((String) item_reason.get('reason') == 'Mammograms') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'Mammograms';
                    } else if ((String) item_reason.get('reason') == 'Prostate Screenings') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'Prostate Screenings';
                    }
                    ccpdToUpdate.add(ccpd);
                }
                Database.SaveResult[] results = Database.update(ccpdToUpdate, false);
                for (Database.SaveResult result : results) {
                    if (!result.isSuccess()) {
                        for (Database.Error err : result.getErrors())
                            errorOnUpdate = errorOnUpdate == null ? err.getMessage() : errorOnUpdate + ' - ' + err.getMessage();
                        updateDone = false;
                    }
                }
                if (!updateDone)
                    throw new AuraHandledException('error on update');
                //update ccpdToUpdate;
                outputMap.put('result', 'updated');
            }
        } catch (Exception err) {
            system.debug(err.getMessage());
            system.debug('errorOnUpdate ' + errorOnUpdate);
            outputMap.put('result', errorOnUpdate);
        }
    }

    public static void createItemPayments(Map<String, Object> inputMap, Map<String, Object> outMap) {
        Set<Id> itemIds = new Set<Id>();
        List<Object> strItemIds = (List<Object>) inputMap.get('itemIds');
        for (Object item : strItemIds)
            itemIds.add(String.valueOf(item));
        List<ClaimPaymentSummary> paymentsToCreate = new List<ClaimPaymentSummary>();
        Map<String, ARC_ParticipantAggregator__c> participant_aggregator_by_code = new Map<String, ARC_ParticipantAggregator__c>();
        List<ClaimCoveragePaymentDetail> itemsPaid = new List<ClaimCoveragePaymentDetail>();
        List<ARC_Aggregator__c> aggsUpdated = new List<ARC_Aggregator__c>();
        Id renewed_from_policy_id;
        Id participant_aggregators_policyid;
        Id participantId;
        List<ARC_Aggregator__c> family_aggregator;
        String claim_year_of_service;

        List<ClaimCoveragePaymentDetail> claimItems = [
            SELECT
                Id,
                ARC_Medical_Visit_Reason__c,
                ARC_Coinsurance__c,
                ARC_Deductible__c,
                ARC_Pre_Existing_Condition__c,
                ARC_Tobacco__c,
                Status,
                Name,
                ARC_NetPaid__c,
                ClaimedAmount,
                ARC_Claim__r.ARC_DOSFrom__c,
                ARC_Claim__r.ARC_MemberDOB__c,
                ARC_Claim__r.PolicyNumberId,
                ARC_Claim__r.ARC_MemberBenefitEffectiveDate__c,
                ARC_Claim__r.ARC_MemberBenefitTermDate__c,
                ARC_Claim__c,
                ARC_Claim__r.ARC_ParticipantPolicyParticipant__c,
                ARC_Claim__r.ARC_ParticipantPolicyParticipant__r.PrimaryParticipantContact.AccountId,
                ARC_Claim__r.ARC_ParticipantPolicyParticipant__r.PrimaryParticipantContact.vlocity_ins__Age__c,
                ARC_MaximumTypeAmount__c,
                ARC_MaximumType__c,
                ARC_Claim__r.PolicyNumber.ARC_Contract__r.Status,
                ARC_Claim__r.PolicyNumber.RenewedFromPolicyId,
                ARC_Claim__r.PolicyNumber.ARC_Contract__r.ARC_ContractReason__c,
                ARC_Claim__r.PolicyNumber.Product.Name
            FROM ClaimCoveragePaymentDetail
            WHERE Id IN :itemIds
            LIMIT 1000
        ];
        if (claimItems.size() == 0)
            return;
        else {
            if (claimItems[0].ARC_Claim__r.PolicyNumber?.ARC_Contract__r?.Status == 'Voided') {
                outMap.put('errorOnUpdate', 'This member belongs to a Voided contract, you cannot pay items');
                return;
            }
            if (
                claimItems[0].ARC_Claim__r.ARC_MemberDOB__c > claimItems[0].ARC_Claim__r.ARC_DOSFrom__c ||
                claimItems[0].ARC_Claim__r.ARC_MemberBenefitEffectiveDate__c > claimItems[0].ARC_Claim__r.ARC_DOSFrom__c
            ) {
                outMap.put('errorOnUpdate', 'Services before DOB/Effective date');
                return;
            }
            if (
                claimItems[0].ARC_Claim__r.ARC_MemberBenefitTermDate__c != null
                && claimItems[0].ARC_Claim__r.ARC_MemberBenefitTermDate__c < claimItems[0].ARC_Claim__r.ARC_DOSFrom__c
            ) {
                outMap.put('errorOnUpdate', 'Services after Termination date');
                return;
            }

            participant_aggregators_policyid = claimItems[0].ARC_Claim__r.PolicyNumberId;
            renewed_from_policy_id = claimItems[0].ARC_Claim__r.PolicyNumber.RenewedFromPolicyId;
            
            String policy_reason = claimItems[0].ARC_Claim__r.PolicyNumber.ARC_Contract__r.ARC_ContractReason__c;
            Boolean is_upgrade = false;

            for (String upgrade_reason : new List<String>{'New Application', 'Program Upgrade', 'Upgraded Spin Off'}) {
                if (policy_reason.containsIgnoreCase(upgrade_reason)) {
                    is_upgrade = true;
                }
            }

            Id aggregators_policy_id;
            if (is_upgrade) {
                aggregators_policy_id = participant_aggregators_policyid;
            } else {
                aggregators_policy_id = renewed_from_policy_id;
            }

            participantId = claimItems[0].ARC_Claim__r.ARC_ParticipantPolicyParticipant__c;
            claim_year_of_service = String.valueOf(claimItems[0].ARC_Claim__r.ARC_DOSFrom__c.year());

            family_aggregator = [
                SELECT Id, ARC_FamilyCurrentValue__c, ARC_LimitValue__c
                FROM ARC_Aggregator__c
                WHERE RecordType.DeveloperName = 'Family'
                AND ARC_CreatedIn__c =: aggregators_policy_id
                AND ARC_Year__c =: claim_year_of_service
                LIMIT 1
            ];

        }
        List<ARC_ParticipantAggregator__c> participant_aggregators_list = [
            SELECT
                Id,
                ARC_ConsumedValue__c,
                ARC_Aggregator__r.ARC_Code__c,
                ARC_Aggregator__c,
                ARC_Aggregator__r.ARC_NextAvailabilityDate__c,
                ARC_Aggregator__r.ARC_BY1_Date__c,
                ARC_Aggregator__r.ARC_BY1_Current__c,
                ARC_Aggregator__r.ARC_BY1_Limit__c,
                ARC_Aggregator__r.ARC_BY2_Date__c,
                ARC_Aggregator__r.ARC_BY2_Current__c,
                ARC_Aggregator__r.ARC_BY2_Limit__c,
                ARC_Aggregator__r.ARC_BY3_Date__c,
                ARC_Aggregator__r.ARC_BY3_Current__c,
                ARC_Aggregator__r.ARC_BY3_Limit__c
            FROM ARC_ParticipantAggregator__c
            WHERE
                ARC_Policy__c = :participant_aggregators_policyid
                AND ARC_PolicyParticipant__c = :participantId
                AND (ARC_Aggregator__r.ARC_Year__c = :claim_year_of_service
                OR ARC_Aggregator__r.ARC_Year__c = NULL)
            LIMIT 1000
        ];

        for (ARC_ParticipantAggregator__c participant_aggregator : participant_aggregators_list)
            participant_aggregator_by_code.put(participant_aggregator.ARC_Aggregator__r.ARC_Code__c, participant_aggregator);
        Double amcsConsumed = 0;

        // QUERY PRE EXISTING AGGREGATORS FOR NEXT YEARS
        ARC_Aggregator__c aggregator_preexisting_conditions = new ARC_Aggregator__c();

        List<String> nextYears = new List<String>{
            String.valueOf(Integer.valueOf(claim_year_of_service) + 1),
            String.valueOf(Integer.valueOf(claim_year_of_service) + 2),
            String.valueOf(Integer.valueOf(claim_year_of_service) + 3)
        };
        List<ARC_Aggregator__c> nextPreExConditions = [
            SELECT Id, ARC_Year__c, ARC_BY1_Current__c, ARC_BY2_Current__c, ARC_BY3_Current__c, ARC_BY1_Limit__c, ARC_BY2_Limit__c, ARC_BY3_Limit__c
            FROM ARC_Aggregator__c
            WHERE
                ARC_Code__c = 'PREEX__c'
                AND ARC_Member__c = :claimItems[0].ARC_Claim__r.ARC_ParticipantPolicyParticipant__r.PrimaryParticipantContact.AccountId
                AND ARC_Year__c IN :nextYears
            LIMIT 1000
        ];

		// BENEFIT DATES
		Date first_benefit_year_end_date = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY1_Date__c;
		Date second_benefit_year_end_date = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY2_Date__c;
		Date third_benefit_year_end_date = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY3_Date__c;
		// BENEFIT CURRENT VALUES
		Decimal first_benefit_year_current = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY1_Current__c;
		Decimal second_benefit_year_current = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY2_Current__c;
		Decimal third_benefit_year_current = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY3_Current__c;
		// BENEFIT LIMITS
		Decimal first_benefit_year_max_limit = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY1_Limit__c;
		Decimal second_benefit_year_max_limit = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY2_Limit__c;
		Decimal third_benefit_year_max_limit = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY3_Limit__c;

		// System.debug(first_benefit_year_end_date);
		// System.debug(second_benefit_year_end_date);
		// System.debug(third_benefit_year_end_date);
		// System.debug(first_benefit_year_current);
		// System.debug(second_benefit_year_current);
		// System.debug(third_benefit_year_current);
		// System.debug(first_benefit_year_max_limit);
		// System.debug(second_benefit_year_max_limit);
		// System.debug(third_benefit_year_max_limit);

        // ADD VALUES INTO PARTICIPANT AGGREGATORS AND CREATE PAYMENT SUMMARIES
        for (ClaimCoveragePaymentDetail smb_item : claimItems) {
            Decimal memberAge = smb_item.ARC_Claim__r.ARC_ParticipantPolicyParticipant__r.PrimaryParticipantContact.vlocity_ins__Age__c;
            String productName = smb_item.ARC_Claim__r.PolicyNumber.Product.Name;
            if (smb_item.Status == 'Paid')
                continue;
            smb_item.Status = 'Paid';
            smb_item.ARC_PaidDate__c = System.today();
            itemsPaid.add(smb_item);

            // DEDUCTIBLE/AMCS
            if (smb_item.ARC_Deductible__c != 0 && smb_item.ARC_Deductible__c != null && participant_aggregator_by_code.get('AMCS__c') != null) {
                if (participant_aggregator_by_code.get('AMCS__c').ARC_ConsumedValue__c != null) {
                    participant_aggregator_by_code.get('AMCS__c').ARC_ConsumedValue__c += smb_item.ARC_Deductible__c;
                } else {
                    participant_aggregator_by_code.get('AMCS__c').ARC_ConsumedValue__c = smb_item.ARC_Deductible__c;
                }

                amcsConsumed += smb_item.ARC_Deductible__c;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - AMCS__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('AMCS__c').Id;
                sum.ARC_ConsumedValue__c = smb_item.ARC_Deductible__c;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                System.debug('Llego');
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                System.debug('Llego');
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Deductible__c != 0 && smb_item.ARC_Deductible__c != null && participant_aggregator_by_code.get('AMCS__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

			// System.debug(smb_item.ARC_Pre_Existing_Condition__c != 0);
			// System.debug(smb_item.ARC_Pre_Existing_Condition__c != null);
			// System.debug(participant_aggregator_by_code.get('PREEX__c') != null);

            // PRE EXIST. CONDITIONS
            if (smb_item.ARC_Pre_Existing_Condition__c != 0 && smb_item.ARC_Pre_Existing_Condition__c != null && participant_aggregator_by_code.get('PREEX__c') != null) {
                Date claimDOS = claimItems[0].ARC_Claim__r.ARC_DOSFrom__c;
                String errorString = 'The Pre-Existing Aggregator has been exceeded for the time period!';

                // System.debug(second_benefit_year_end_date);
                // System.debug(second_benefit_year_current);
                // System.debug(second_benefit_year_max_limit);
                // System.debug(claimDOS);

				Boolean belongs_in_first_benefit_year = first_benefit_year_end_date != null && first_benefit_year_current != null && first_benefit_year_max_limit != null && claimDOS < first_benefit_year_end_date;
				Boolean belongs_in_second_benefit_year = second_benefit_year_end_date != null && second_benefit_year_current != null && second_benefit_year_max_limit != null && claimDOS < second_benefit_year_end_date;
				Boolean belongs_in_third_benefit_year = third_benefit_year_end_date != null && third_benefit_year_current != null && third_benefit_year_max_limit != null && claimDOS < third_benefit_year_end_date;

				// System.debug(belongs_in_first_benefit_year);
				// System.debug(belongs_in_second_benefit_year);
				// System.debug(belongs_in_third_benefit_year);


                if (belongs_in_third_benefit_year) {// IF CLAIM DATE OF SERVICE IS LESS THAN END DATE FOR BENEFIT 3
                    if (third_benefit_year_current + smb_item.ARC_Pre_Existing_Condition__c > third_benefit_year_max_limit == false) {// CHECK IF EXCEEDED PREVIOUS BENEFIT YEAR 3
						aggregator_preexisting_conditions.Id = participant_aggregator_by_code.get('PREEX__c').ARC_Aggregator__c;
						third_benefit_year_current = third_benefit_year_current + smb_item.ARC_Pre_Existing_Condition__c;
						aggregator_preexisting_conditions.ARC_BY3_Current__c = third_benefit_year_current;
						// System.debug(aggregator_preexisting_conditions.ARC_BY3_Current__c);
                    } else {
                        outMap.put('errorOnUpdate', errorString);
                        return;
					}
                }

				else if (belongs_in_second_benefit_year) {// IF CLAIM DATE OF SERVICE IS LESS THAN END DATE FOR BENEFIT 2
                    if (second_benefit_year_current + smb_item.ARC_Pre_Existing_Condition__c > second_benefit_year_max_limit == false) {// CHECK IF EXCEEDED PREVIOUS BENEFIT YEAR 2
						aggregator_preexisting_conditions.Id = participant_aggregator_by_code.get('PREEX__c').ARC_Aggregator__c;
						second_benefit_year_current = second_benefit_year_current + smb_item.ARC_Pre_Existing_Condition__c;
						aggregator_preexisting_conditions.ARC_BY2_Current__c = second_benefit_year_current;
						// System.debug(aggregator_preexisting_conditions.ARC_BY2_Current__c);
                    } else {
                        outMap.put('errorOnUpdate', errorString);
                        return;
					}
                }

				else if (belongs_in_first_benefit_year) {// IF CLAIM DATE OF SERVICE IS LESS THAN END DATE FOR BENEFIT 1
                    if (first_benefit_year_current + smb_item.ARC_Pre_Existing_Condition__c > first_benefit_year_max_limit == false) {// CHECK IF EXCEEDED PREVIOUS BENEFIT YEAR 1
						aggregator_preexisting_conditions.Id = participant_aggregator_by_code.get('PREEX__c').ARC_Aggregator__c;
						first_benefit_year_current = first_benefit_year_current + smb_item.ARC_Pre_Existing_Condition__c;
						aggregator_preexisting_conditions.ARC_BY1_Current__c = first_benefit_year_current;
						// System.debug(aggregator_preexisting_conditions.ARC_BY1_Current__c);
                    } else {
                        outMap.put('errorOnUpdate', errorString);
                        return;
					}
                }

                // INCREMENT PRE-EX OF NEXT YEARS
                if (nextPreExConditions.size() > 0) {
                    for (ARC_Aggregator__c agg : nextPreExConditions) {
                        Integer benefitYear = Integer.valueOf(agg.ARC_Year__c) - Integer.valueOf(claim_year_of_service);
                        if (benefitYear > 3 || agg.get('ARC_BY' + benefitYear + '_Current__c') == null || agg.get('ARC_BY' + benefitYear + '_Limit__c') == null)
                            continue;

                        // BENEFITS LIMITS
                        Decimal benefitCurrent = (Decimal) agg.get('ARC_BY' + benefitYear + '_Current__c');
                        Decimal benefitLimit = (Decimal) agg.get('ARC_BY' + benefitYear + '_Limit__c');

                        // VALIDATE
                        if (benefitCurrent + smb_item.ARC_Pre_Existing_Condition__c > benefitLimit) {
                            outMap.put('errorOnUpdate', errorString);
                            return;
                        }

                        // INCREMENT
                        agg.put('ARC_BY' + benefitYear + '_Current__c', benefitCurrent + smb_item.ARC_Pre_Existing_Condition__c);
                    }
                }

                participant_aggregator_by_code.get('PREEX__c').ARC_ConsumedValue__c += smb_item.ARC_Pre_Existing_Condition__c;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - PREEX__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('PREEX__c').Id;
                sum.ARC_ConsumedValue__c = smb_item.ARC_Pre_Existing_Condition__c;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            }  else if (smb_item.ARC_Pre_Existing_Condition__c != 0 && smb_item.ARC_Pre_Existing_Condition__c != null && participant_aggregator_by_code.get('PREEX__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // SHARE FOR AMCS/COINSURANCE
            if (smb_item.ARC_Coinsurance__c != 0 && smb_item.ARC_Coinsurance__c != null && participant_aggregator_by_code.get('SHAMCS__c') != null) {
                participant_aggregator_by_code.get('SHAMCS__c').ARC_ConsumedValue__c += smb_item.ARC_Coinsurance__c;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - SHAMCS__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('SHAMCS__c').Id;
                sum.ARC_ConsumedValue__c = smb_item.ARC_Coinsurance__c;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            }  else if (smb_item.ARC_Coinsurance__c != 0 && smb_item.ARC_Coinsurance__c != null && participant_aggregator_by_code.get('SHAMCS__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // TOBACCO
            if (smb_item.ARC_Tobacco__c != 0 && smb_item.ARC_Tobacco__c != null && participant_aggregator_by_code.get('TOB__c') != null) {
                participant_aggregator_by_code.get('TOB__c').ARC_ConsumedValue__c += smb_item.ARC_Tobacco__c;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - TOB__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('TOB__c').Id;
                sum.ARC_ConsumedValue__c = smb_item.ARC_Tobacco__c;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Tobacco__c != 0 && smb_item.ARC_Tobacco__c != null && participant_aggregator_by_code.get('TOB__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // ALLERGY TESTING
            if (
                smb_item.ARC_MaximumTypeAmount__c != 0 &&
                smb_item.ARC_MaximumTypeAmount__c != null &&
                smb_item.ARC_MaximumType__c == 'Allergy Testing' &&
                participant_aggregator_by_code.get('ALGTEST__c') != null
            ) {
                participant_aggregator_by_code.get('ALGTEST__c').ARC_ConsumedValue__c += smb_item.ARC_MaximumTypeAmount__c;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - ALGTEST__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('ALGTEST__c').Id;
                sum.ARC_ConsumedValue__c = smb_item.ARC_MaximumTypeAmount__c;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (
                smb_item.ARC_MaximumTypeAmount__c != 0 &&
                smb_item.ARC_MaximumTypeAmount__c != null &&
                smb_item.ARC_MaximumType__c == 'Allergy Testing' &&
                participant_aggregator_by_code.get('ALGTEST__c') == null
            ) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // DURABLE MEDICAL EQUIPMENT (DME)
            if (
                smb_item.ARC_MaximumTypeAmount__c != 0 &&
                smb_item.ARC_MaximumTypeAmount__c != null &&
                smb_item.ARC_MaximumType__c == 'Durable Medical Equipment (DME)' &&
                participant_aggregator_by_code.get('DME__c') != null
            ) {
                participant_aggregator_by_code.get('DME__c').ARC_ConsumedValue__c += smb_item.ARC_MaximumTypeAmount__c;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - DME__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('DME__c').Id;
                sum.ARC_ConsumedValue__c = smb_item.ARC_MaximumTypeAmount__c;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (
                smb_item.ARC_MaximumTypeAmount__c != 0 &&
                smb_item.ARC_MaximumTypeAmount__c != null &&
                smb_item.ARC_MaximumType__c == 'Durable Medical Equipment (DME)' &&
                participant_aggregator_by_code.get('DME__c') == null
            ) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // MATERNITY
            if (
                smb_item.ARC_MaximumTypeAmount__c != 0 &&
                smb_item.ARC_MaximumTypeAmount__c != null &&
                smb_item.ARC_MaximumType__c == 'Maternity' &&
                participant_aggregator_by_code.get('MAT__c') != null
            ) {
                participant_aggregator_by_code.get('MAT__c').ARC_ConsumedValue__c += smb_item.ARC_MaximumTypeAmount__c;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - MAT__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('MAT__c').Id;
                sum.ARC_ConsumedValue__c = smb_item.ARC_MaximumTypeAmount__c;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (
                smb_item.ARC_MaximumTypeAmount__c != 0 &&
                smb_item.ARC_MaximumTypeAmount__c != null &&
                smb_item.ARC_MaximumType__c == 'Maternity' &&
                participant_aggregator_by_code.get('MAT__c') == null
            ) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // CONGENITAL BIRTH DEFECT
            if (
                smb_item.ARC_MaximumTypeAmount__c != 0 &&
                smb_item.ARC_MaximumTypeAmount__c != null &&
                smb_item.ARC_MaximumType__c == 'Congenital Birth Defect' &&
                participant_aggregator_by_code.get('CONGBIRTH__c') != null
            ) {
                participant_aggregator_by_code.get('CONGBIRTH__c').ARC_ConsumedValue__c += smb_item.ARC_MaximumTypeAmount__c;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - CONGBIRTH__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('CONGBIRTH__c').Id;
                sum.ARC_ConsumedValue__c = smb_item.ARC_MaximumTypeAmount__c;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (
                smb_item.ARC_MaximumTypeAmount__c != 0 &&
                smb_item.ARC_MaximumTypeAmount__c != null &&
                smb_item.ARC_MaximumType__c == 'Congenital Birth Defect' &&
                participant_aggregator_by_code.get('CONGBIRTH__c') == null
            ) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // ACCUPUNTURE
            if (smb_item.ARC_Medical_Visit_Reason__c == 'Acupuncture' && participant_aggregator_by_code.get('ACC__c') != null) {
                participant_aggregator_by_code.get('ACC__c').ARC_ConsumedValue__c += 1;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - ACC__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('ACC__c').Id;
                sum.ARC_ConsumedValue__c = 1;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'Acupuncture' && participant_aggregator_by_code.get('ACC__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // URGENT CARE AND OFFICE VISITS
            if ((smb_item.ARC_Medical_Visit_Reason__c == 'Urgent Care' || smb_item.ARC_Medical_Visit_Reason__c == 'Office Visit/Copay') && participant_aggregator_by_code.get('OFUC__c') != null) {
                participant_aggregator_by_code.get('OFUC__c').ARC_ConsumedValue__c += 1;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - OFUC__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('OFUC__c').Id;
                sum.ARC_ConsumedValue__c = 1;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if ((smb_item.ARC_Medical_Visit_Reason__c == 'Urgent Care' || smb_item.ARC_Medical_Visit_Reason__c == 'Office Visit/Copay') && participant_aggregator_by_code.get('OFUC__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // PHYSICAL THERAPY
            if (smb_item.ARC_Medical_Visit_Reason__c == 'PhysicalTherapy' && participant_aggregator_by_code.get('PHYTH__c') != null) {
                participant_aggregator_by_code.get('PHYTH__c').ARC_ConsumedValue__c += 1;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - PHYTH__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('PHYTH__c').Id;
                sum.ARC_ConsumedValue__c = 1;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'PhysicalTherapy' && participant_aggregator_by_code.get('PHYTH__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // BEHAVIORAL
            if (smb_item.ARC_Medical_Visit_Reason__c == 'Behavioral' && participant_aggregator_by_code.get('HTERAPHPY__c') != null) {
                participant_aggregator_by_code.get('HTERAPHPY__c').ARC_ConsumedValue__c += 1;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - HTERAPHPY__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('HTERAPHPY__c').Id;
                sum.ARC_ConsumedValue__c = 1;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'Behavioral' && participant_aggregator_by_code.get('HTERAPHPY__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // CHIROPRACTIC
            if (smb_item.ARC_Medical_Visit_Reason__c == 'Chiropractic' && participant_aggregator_by_code.get('CHIRO__c') != null) {
                participant_aggregator_by_code.get('CHIRO__c').ARC_ConsumedValue__c += 1;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - CHIRO__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('CHIRO__c').Id;
                sum.ARC_ConsumedValue__c = 1;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'Chiropractic' && participant_aggregator_by_code.get('CHIRO__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // PSYCHIATRIC CARE
            if (smb_item.ARC_Medical_Visit_Reason__c == 'Psychiatric Care' && participant_aggregator_by_code.get('PSYCH__c') != null) {
                participant_aggregator_by_code.get('PSYCH__c').ARC_ConsumedValue__c += 1;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - PSYCH__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('PSYCH__c').Id;
                sum.ARC_ConsumedValue__c = 1;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'Psychiatric Care' && participant_aggregator_by_code.get('PSYCH__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // CERVICAL CANCER SCREENINGS
            if (smb_item.ARC_Medical_Visit_Reason__c == 'Cervical Cancer Screenings' && participant_aggregator_by_code.get('CCS__c') != null) {
                if (productName == 'WeShare Legacy') {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('CCS__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = participant_aggregator_by_code.get('CCS__c').ARC_Aggregator__r.ARC_NextAvailabilityDate__c.addYears(2)
                        )
                    );
                } else if (memberAge >= 21 && memberAge <= 29) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('CCS__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = participant_aggregator_by_code.get('CCS__c').ARC_Aggregator__r.ARC_NextAvailabilityDate__c.addYears(3)
                        )
                    );
                } else if (memberAge >= 30 && memberAge <= 65) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('CCS__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = participant_aggregator_by_code.get('CCS__c').ARC_Aggregator__r.ARC_NextAvailabilityDate__c.addYears(5)
                        )
                    );
                } else {
                    outMap.put('errorOnUpdate', 'Member must be between 21 and 65 to use Cervical Cancer Screenings');
                    return;
                }

                participant_aggregator_by_code.get('CCS__c').ARC_ConsumedValue__c += 1;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - CCS__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('CCS__c').Id;
                sum.ARC_ConsumedValue__c = 1;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'Cervical Cancer Screenings' && participant_aggregator_by_code.get('CCS__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // SELF-SCREEN OPTION
            if (smb_item.ARC_Medical_Visit_Reason__c == 'CC - Self-Screen Option' && participant_aggregator_by_code.get('SSOPT__c') != null) {
                if (memberAge >= 45) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('SSOPT__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = participant_aggregator_by_code.get('SSOPT__c').ARC_Aggregator__r.ARC_NextAvailabilityDate__c.addYears(3)
                        )
                    );
                } else {
                    outMap.put('errorOnUpdate', 'Member must be 45 or older to use Self-Screen Option');
                    return;
                }

                participant_aggregator_by_code.get('SSOPT__c').ARC_ConsumedValue__c += 1;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - SSOPT__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('SSOPT__c').Id;
                sum.ARC_ConsumedValue__c = 1;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'CC - Self-Screen Option' && participant_aggregator_by_code.get('SSOPT__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // COLONOSCOPY
            if (smb_item.ARC_Medical_Visit_Reason__c == 'CC - Colonoscopy' && participant_aggregator_by_code.get('CLON__c') != null) {
                if (memberAge >= 45) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('CLON__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = participant_aggregator_by_code.get('CLON__c').ARC_Aggregator__r.ARC_NextAvailabilityDate__c.addYears(10)
                        )
                    );
                } else {
                    outMap.put('errorOnUpdate', 'Member must be 45 or older to use Colonoscopy');
                    return;
                }

                participant_aggregator_by_code.get('CLON__c').ARC_ConsumedValue__c += 1;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - CLON__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('CLON__c').Id;
                sum.ARC_ConsumedValue__c = 1;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'CC - Colonoscopy' && participant_aggregator_by_code.get('CLON__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // FLEXIBLE SIGMOISOSCOPY
            if (smb_item.ARC_Medical_Visit_Reason__c == 'CC - Flexible Sigmoisoscopy' && participant_aggregator_by_code.get('FLXSIG__c') != null) {
                if (productName == 'WeShare Legacy') {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('FLXSIG__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = participant_aggregator_by_code.get('FLXSIG__c').ARC_Aggregator__r.ARC_NextAvailabilityDate__c.addYears(4)
                        )
                    );
                } else if (memberAge >= 45) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('FLXSIG__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = participant_aggregator_by_code.get('FLXSIG__c').ARC_Aggregator__r.ARC_NextAvailabilityDate__c.addYears(5)
                        )
                    );
                } else {
                    outMap.put('errorOnUpdate', 'Member must be 45 or older to use Flexible Sigmoisoscopy');
                    return;
                }

                participant_aggregator_by_code.get('FLXSIG__c').ARC_ConsumedValue__c += 1;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - FLXSIG__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('FLXSIG__c').Id;
                sum.ARC_ConsumedValue__c = 1;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'CC - Flexible Sigmoisoscopy' && participant_aggregator_by_code.get('FLXSIG__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // MAMMOGRAMS
            if (smb_item.ARC_Medical_Visit_Reason__c == 'Mammograms' && participant_aggregator_by_code.get('MAMM__c') != null) {
                if (memberAge >= 40 && memberAge <= 54) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('MAMM__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = participant_aggregator_by_code.get('MAMM__c').ARC_Aggregator__r.ARC_NextAvailabilityDate__c.addYears(1)
                        )
                    );
                } else if (memberAge >= 55) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('MAMM__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = participant_aggregator_by_code.get('MAMM__c').ARC_Aggregator__r.ARC_NextAvailabilityDate__c.addYears(2)
                        )
                    );
                } else {
                    outMap.put('errorOnUpdate', 'Member must be 40 or older to use Mammograms');
                    return;
                }

                participant_aggregator_by_code.get('MAMM__c').ARC_ConsumedValue__c += 1;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - MAMM__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('MAMM__c').Id;
                sum.ARC_ConsumedValue__c = 1;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'Mammograms' && participant_aggregator_by_code.get('MAMM__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }

            // PROSTATE SCREENINGS
            if (smb_item.ARC_Medical_Visit_Reason__c == 'Prostate Screenings' && participant_aggregator_by_code.get('PROSCRE__c') != null) {
                if (memberAge >= 45) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('PROSCRE__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = participant_aggregator_by_code.get('PROSCRE__c').ARC_Aggregator__r.ARC_NextAvailabilityDate__c.addYears(2)
                        )
                    );
                } else {
                    outMap.put('errorOnUpdate', 'Member must be 45 or older to use Prostate Screenings');
                    return;
                }

                participant_aggregator_by_code.get('PROSCRE__c').ARC_ConsumedValue__c += 1;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - PROSCRE__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('PROSCRE__c').Id;
                sum.ARC_ConsumedValue__c = 1;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'Prostate Screenings' && participant_aggregator_by_code.get('PROSCRE__c') == null) {
                outMap.put('errorOnUpdate', 'Participant Aggregator missing!');
                return;
            }
            
        }

        /* UHSM Metal plans don't have a family aggregator and WeShare plans have a family aggregator, so only if a family aggregators exists for the plan and it exceeds display this error. */
        if (
            family_aggregator.isEmpty() == false && family_aggregator[0].ARC_FamilyCurrentValue__c + amcsConsumed > family_aggregator[0].ARC_LimitValue__c
        ) {
            outMap.put('errorOnUpdate', 'Family AMCS has been reached!');
            return;
        }

        try {
            String error_messages_string; Boolean update_contains_partial_errors = false;
            
            Database.SaveResult[] save_results_list = Database.update(participant_aggregator_by_code.values(), true);
            for (Database.SaveResult result : save_results_list) {
                if (result.isSuccess() == false) {
                    update_contains_partial_errors = true;
                    error_messages_string += String.join(result.getErrors(), ' - ');
                }
            }

            if (update_contains_partial_errors == false) {
                insert paymentsToCreate;
                update itemsPaid;
                update aggsUpdated;
                update nextPreExConditions;
                if (aggregator_preexisting_conditions.Id != null)
                    update aggregator_preexisting_conditions;

                if (itemsPaid.size() > 0 && paymentsToCreate.size() > 0)
                    outMap.put('itemsPaid', 'Items has been paid and some aggregators were affected!');
                else
                    outMap.put('itemsPaid', 'Items has been paid successfully!');
            } else {
                outMap.put('errorOnUpdate', error_messages_string);
            }
        } catch (Exception e) {
            outMap.put('errorOnUpdate', e.getMessage());
            system.debug('errorOnUpdate ' + e.getMessage());
        }
    }

    public static void uncommitAllChanges(Map<String, Object> inputMap, Map<String, Object> outMap) {
        system.debug('uncommit');
        String claimId = (String) inputMap.get('claimId');
        Set<Id> claimLineItemIds = new Set<Id>();
        List<Object> strItemIds = (List<Object>) inputMap.get('itemIds');
        if (strItemIds != null) {
            for (Object item : strItemIds)
                claimLineItemIds.add(String.valueOf(item));
        }

        Claim clm = [
            SELECT
                Id,
                ARC_AuditorValidation__c,
                ARC_DOSFrom__c,
                ARC_DOSTo__c,
                ARC_ParticipantPolicyParticipant__c,
                RecordType.Name,
                Status,
                ARC_MemberContact__c,
                PolicyNumberId
            FROM Claim
            WHERE Id = :claimId
        ];
        if (
            (clm.ARC_AuditorValidation__c == 'Approved' ||
            clm.Status == 'Manual Approved' ||
            clm.Status == 'Manual Denied' ||
            clm.Status == 'AA Approved' ||
            clm.Status == 'AA Denied' ||
            clm.Status == 'Adjusted' ||
            clm.Status == 'Voided')
        ) {
            outMap.put('updated', false);
            return;
        }
        if (clm.ARC_DOSTo__c == null) {
            outMap.put('updated', false);
            outMap.put('DOSToMissing', true);
            return;
        }
        Boolean updated = resetItems(clm, 'uncommit', claimLineItemIds);
        system.debug(updated);
        outMap.put('updated', updated);
    }

    public static Boolean resetItems(Claim claim, String action, Set<Id> ccpdIds) {
        try {
        Map<Id, ARC_ParticipantAggregator__c> partAggs = new Map<Id, ARC_ParticipantAggregator__c>();
        List<ClaimPaymentSummary> pSummaryList = new List<ClaimPaymentSummary>();
        List<ARC_ClaimReasonCode__c> rCodeList = new List<ARC_ClaimReasonCode__c>();
        List<ClaimCoveragePaymentDetail> smb_items;

        // Construct the entire base query as a single string
        String baseQuery = 'SELECT Id, RecordType.DeveloperName, Status, AdjustedAmount, ARC_PrimaryPaid__c, ARC_Copay__c, ARC_Coinsurance__c, ARC_Deductible__c, ARC_MBRLiability__c, ARC_Medical_Visit_Reason__c, ARC_Pre_Existing_Condition__c, ARC_Tobacco__c, ARC_Claim__r.ARC_MemberBenefitPlan__c,ARC_Claim__r.ARC_ParticipantPolicyParticipant__r.PrimaryParticipantContact.AccountId,ARC_Claim__r.ARC_ParticipantPolicyParticipant__c,ARC_Claim__r.PolicyNumberId, (SELECT Id FROM Claim_Reason_Codes__r), (SELECT Id, ARC_ParticipantAggregator__r.ARC_ConsumedValue__c, ARC_ConsumedValue__c, ARC_AMCS_amount__c, ARC_PreExistingCond__c, ARC_Tobacco__c, ARC_ShareAMCS__c, ARC_Medical_Visit__c FROM SMB_Item_Payments__r) FROM ClaimCoveragePaymentDetail ';

        // Add the WHERE clause dynamically based on the size of ccpdIds
        String whereClause = (ccpdIds.isEmpty()) ? 'WHERE ARC_Claim__c = :claimId ' : 'WHERE Id IN :ccpdIds ';
        // Construct the final query string with LIMIT
        String fullQuery = baseQuery + whereClause + 'LIMIT 3000';

        Map<String, Object> bindMap = new Map<String, Object>{'claimId' => claim.Id, 'ccpdIds' => ccpdIds};

        // Execute the query
        smb_items = Database.queryWithBinds(fullQuery, bindMap, AccessLevel.SYSTEM_MODE);

        if (smb_items.size() == 0)
            return false;

        String claim_year_of_service = claim.ARC_DOSTo__c?.year() + '';

        List<ARC_ParticipantAggregator__c> participant_aggregators = [
            SELECT
                Id,
                ARC_ConsumedValue__c,
                ARC_Aggregator__r.ARC_Code__c,
                ARC_Aggregator__r.ARC_BY1_Date__c,
                ARC_Aggregator__r.ARC_BY1_Current__c,
                ARC_Aggregator__r.ARC_BY1_Limit__c,
                ARC_Aggregator__r.ARC_BY2_Date__c,
                ARC_Aggregator__r.ARC_BY2_Current__c,
                ARC_Aggregator__r.ARC_BY2_Limit__c,
                ARC_Aggregator__r.ARC_BY3_Date__c,
                ARC_Aggregator__r.ARC_BY3_Current__c,
                ARC_Aggregator__r.ARC_BY3_Limit__c
            FROM ARC_ParticipantAggregator__c
            WHERE
                ARC_Policy__c = :smb_items[0].ARC_Claim__r.PolicyNumberId
                AND ARC_PolicyParticipant__c = :smb_items[0].ARC_Claim__r.ARC_ParticipantPolicyParticipant__c
                AND (ARC_Aggregator__r.ARC_Year__c = :claim_year_of_service
                OR ARC_Aggregator__r.ARC_Year__c = NULL)
            LIMIT 1000
        ];

        List<String> nextYears = new List<String>{
            String.valueOf(Integer.valueOf(claim_year_of_service) + 1),
            String.valueOf(Integer.valueOf(claim_year_of_service) + 2),
            String.valueOf(Integer.valueOf(claim_year_of_service) + 3)
        };
        List<ARC_Aggregator__c> nextPreExConditions = [
            SELECT Id, ARC_Year__c, ARC_BY1_Current__c, ARC_BY2_Current__c, ARC_BY3_Current__c, ARC_BY1_Limit__c, ARC_BY2_Limit__c, ARC_BY3_Limit__c
            FROM ARC_Aggregator__c
            WHERE
                ARC_Code__c = 'PREEX__c'
                AND ARC_Member__c = :smb_items[0].ARC_Claim__r.ARC_ParticipantPolicyParticipant__r.PrimaryParticipantContact.AccountId
                AND ARC_Year__c IN :nextYears
            LIMIT 1000
        ];

        Map<String, ARC_ParticipantAggregator__c> participant_aggregator_by_code = new Map<String, ARC_ParticipantAggregator__c>();
        for (ARC_ParticipantAggregator__c participant_aggregator : participant_aggregators) {
			// System.debug(participant_aggregator);
            participant_aggregator_by_code.put(participant_aggregator.ARC_Aggregator__r.ARC_Code__c, participant_aggregator);
        }

        // QUERY PRE EXISTING AGGREGATORS FOR NEXT YEARS
        ARC_Aggregator__c aggregator_preexisting_conditions = new ARC_Aggregator__c();

		// BENEFIT DATES
		Date first_benefit_year_end_date = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY1_Date__c;
		Date second_benefit_year_end_date = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY2_Date__c;
		Date third_benefit_year_end_date = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY3_Date__c;
		// BENEFIT CURRENT VALUES
		Decimal first_benefit_year_current = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY1_Current__c;
		Decimal second_benefit_year_current = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY2_Current__c;
		Decimal third_benefit_year_current = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY3_Current__c;
		// BENEFIT LIMITS
		Decimal first_benefit_year_max_limit = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY1_Limit__c;
		Decimal second_benefit_year_max_limit = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY2_Limit__c;
		Decimal third_benefit_year_max_limit = participant_aggregator_by_code.get('PREEX__c')?.ARC_Aggregator__r.ARC_BY3_Limit__c;

        // DELETE REASON CODES AND CHANGE STATUS FROM LINE ITEM
        for (ClaimCoveragePaymentDetail smb_item : smb_items) {

			// System.debug(participant_aggregator_by_code.get('PREEX__c'));
			// System.debug(smb_item.ARC_Pre_Existing_Condition__c != 0);
			// System.debug(smb_item.ARC_Pre_Existing_Condition__c != null);
			// System.debug(participant_aggregator_by_code.get('PREEX__c') != null);

            // PRE EXIST. CONDITIONS //
            if (smb_item.ARC_Pre_Existing_Condition__c != 0 && smb_item.ARC_Pre_Existing_Condition__c != null && participant_aggregator_by_code.get('PREEX__c') != null) {
                Date claimDOS = claim.ARC_DOSFrom__c;

                // System.debug(first_benefit_year_end_date != null);
                // System.debug(first_benefit_year_current != null);
                // System.debug(first_benefit_year_max_limit != null);
                // System.debug(first_benefit_year_end_date > claimDOS);

                // System.debug(second_benefit_year_end_date != null);
                // System.debug(second_benefit_year_current != null);
                // System.debug(second_benefit_year_max_limit != null);
                // System.debug(second_benefit_year_end_date > claimDOS);

                // System.debug(third_benefit_year_end_date != null);
                // System.debug(third_benefit_year_current != null);
                // System.debug(third_benefit_year_max_limit != null);
                // System.debug(third_benefit_year_end_date > claimDOS);

				Boolean belongs_in_first_benefit_year = first_benefit_year_end_date != null && first_benefit_year_current != null && first_benefit_year_max_limit != null && claimDOS < first_benefit_year_end_date;
				Boolean belongs_in_second_benefit_year = second_benefit_year_end_date != null && second_benefit_year_current != null && second_benefit_year_max_limit != null && claimDOS < second_benefit_year_end_date;
				Boolean belongs_in_third_benefit_year = third_benefit_year_end_date != null && third_benefit_year_current != null && third_benefit_year_max_limit != null && claimDOS < third_benefit_year_end_date;

                // System.debug(belongs_in_first_benefit_year);
				// System.debug(belongs_in_second_benefit_year);
				// System.debug(belongs_in_third_benefit_year);

				if (belongs_in_third_benefit_year) { // IF CLAIM DATE OF SERVICE IS LESS THAN END DATE FOR BENEFIT 3
					aggregator_preexisting_conditions.Id = participant_aggregator_by_code.get('PREEX__c').ARC_Aggregator__c;
					third_benefit_year_current = third_benefit_year_current - smb_item.ARC_Pre_Existing_Condition__c;
					aggregator_preexisting_conditions.ARC_BY3_Current__c = third_benefit_year_current;
				}

				else if (belongs_in_second_benefit_year) { // IF CLAIM DATE OF SERVICE IS LESS THAN END DATE FOR BENEFIT 2
					aggregator_preexisting_conditions.Id = participant_aggregator_by_code.get('PREEX__c').ARC_Aggregator__c;
					second_benefit_year_current = second_benefit_year_current - smb_item.ARC_Pre_Existing_Condition__c;
					aggregator_preexisting_conditions.ARC_BY2_Current__c = second_benefit_year_current;
				}

                else if (belongs_in_first_benefit_year) { // IF CLAIM DATE OF SERVICE IS LESS THAN END DATE FOR BENEFIT 1
                    aggregator_preexisting_conditions.Id = participant_aggregator_by_code.get('PREEX__c').ARC_Aggregator__c;
					first_benefit_year_current = first_benefit_year_current - smb_item.ARC_Pre_Existing_Condition__c;
					aggregator_preexisting_conditions.ARC_BY1_Current__c = first_benefit_year_current;
                }

                // DECREMENT PRE-EX AGGREGATOR OF NEXT YEARS
                if (nextPreExConditions.size() > 0) {
                    for (ARC_Aggregator__c agg : nextPreExConditions) {
                        Integer benefitYear = Integer.valueOf(agg.ARC_Year__c) - Integer.valueOf(claim_year_of_service);
                        if (benefitYear > 3 || agg.get('ARC_BY' + benefitYear + '_Current__c') == null || agg.get('ARC_BY' + benefitYear + '_Limit__c') == null)
                            continue;

                        // BENEFITS LIMITS
                        Decimal benefitCurrent = (Decimal) agg.get('ARC_BY' + benefitYear + '_Current__c');

                        // INCREMENT
                        agg.put('ARC_BY' + benefitYear + '_Current__c', benefitCurrent - smb_item.ARC_Pre_Existing_Condition__c);
                    }
                }
            }
			
            if (action != 'adjust') {
                smb_item.Status = 'New';
                smb_item.AdjustedAmount = 0;
                smb_item.ARC_MaximumTypeAmount__c = 0;
                smb_item.ARC_PrimaryPaid__c = 0;
                smb_item.ARC_Copay__c = 0;
                smb_item.ARC_Coinsurance__c = 0;
                smb_item.ARC_Deductible__c = 0;
                smb_item.ARC_MBRLiability__c = 0;
                smb_item.ARC_Pre_Existing_Condition__c = 0;
                smb_item.ARC_Medical_Visit_Reason__c = null;
                smb_item.ARC_MaximumType__c = null;
                if (action == 'void')
                    smb_item.ARC_Allowed__c = 0;
                if (smb_item.ARC_Claim__r.ARC_MemberBenefitPlan__c != null && smb_item.ARC_Claim__r.ARC_MemberBenefitPlan__c.contains('Access 10K'))
                    smb_item.ARC_Tobacco__c = 0;
            }

            // RESTORE AGREGGATORS
            for (ClaimPaymentSummary smb_item_payment : smb_item.SMB_Item_Payments__r) {
                // IF THE PAYMENT SUMMARY IS FROM PREVIOUS MODEL == CONTINUE
                if (smb_item_payment.ARC_ParticipantAggregator__c == null)
                    continue;

                ARC_ParticipantAggregator__c aggToModify = partAggs.get(smb_item_payment.ARC_ParticipantAggregator__c) != null
                    ? partAggs.get(smb_item_payment.ARC_ParticipantAggregator__c)
                    : new ARC_ParticipantAggregator__c();
                aggToModify.Id = smb_item_payment.ARC_ParticipantAggregator__c;

                // CHECK IF THE CONSUMED VALUE WAS RESTORED PREVIOUSLY
                if (partAggs.get(smb_item_payment.ARC_ParticipantAggregator__c) != null)
                    aggToModify.ARC_ConsumedValue__c =
                        partAggs.get(smb_item_payment.ARC_ParticipantAggregator__c).ARC_ConsumedValue__c - smb_item_payment.ARC_ConsumedValue__c;
                else
                    aggToModify.ARC_ConsumedValue__c = smb_item_payment.ARC_ParticipantAggregator__r.ARC_ConsumedValue__c - smb_item_payment.ARC_ConsumedValue__c;

                partAggs.put(aggToModify.Id, aggToModify);
            }

            pSummaryList.addAll(smb_item.SMB_Item_Payments__r);
            rCodeList.addAll(smb_item.Claim_Reason_Codes__r);
        }

            // DML OPERATIONS
            if (action != 'adjust')
                update smb_items;
            update nextPreExConditions;
            // System.debug(aggregator_preexisting_conditions);
            if (aggregator_preexisting_conditions.Id != null)
                update aggregator_preexisting_conditions;
            system.debug('update');
            update partAggs.values();
            delete pSummaryList;
            if (action != 'adjust')
                delete rCodeList;
            system.debug(smb_items[0].Id);
            system.debug(smb_items[0].ARC_Deductible__c);

            if (partAggs.isEmpty())
                update participant_aggregators;
            system.debug('true');
            return true;
        } catch (Exception e) {
            // System.debug('Error: ' + e.getCause());
            // System.debug('Error: ' + e.getMessage());
            // System.debug('Error: ' + e.getLineNumber());
            // System.debug('Error: ' + e.getStackTraceString());
            return false;
        }
    }

    public static void saveLineItems(Map<String, Object> inputMap, Map<String, Object> outMap) {
        List<Object> itemList = (List<Object>) inputMap.get('input');
        Map<Id, Map<String, Object>> mapLineItems = new Map<Id, Map<String, Object>>();
        List<ClaimCoveragePaymentDetail> toUpdate = new List<ClaimCoveragePaymentDetail>();
        List<String> lineItemsIds = new List<String>();

        if (inputMap != null) {
            for (Object lineItem : itemList) {
                Map<String, Object> line = (Map<String, Object>) lineItem;
                if (line.get('item') != null) {
                    lineItemsIds.add(String.valueOf(line.get('item')));
                    Map<String, Object> valuesMap = (Map<String, Object>) line.get('values');
                    mapLineItems.put(String.valueOf(line.get('item')), valuesMap);
                }
            }
        }
        if (lineItemsIds != null) {
            List<ClaimCoveragePaymentDetail> items = new List<ClaimCoveragePaymentDetail>(
                [
                    SELECT
                        Id,
                        Name,
                        ARC_MBRLiability__c,
                        ARC_Deductible__c,
                        ARC_Allowed__c,
                        AdjustedAmount,
                        ARC_PrimaryPaid__c,
                        ARC_Copay__c,
                        ARC_Pre_Existing_Condition__c
                    FROM ClaimCoveragePaymentDetail
                    WHERE Id IN :lineItemsIds
                ]
            );
            for (ClaimCoveragePaymentDetail ccpd : items) {
                Map<String, Object> valueMap = new Map<String, Object>();
                valueMap = (Map<String, Object>) mapLineItems.get(ccpd.Id);
                if (valueMap.get('mbrLiability') != null)
                    ccpd.ARC_MBRLiability__c = double.valueOf(valueMap.get('mbrLiability'));
                if (valueMap.get('billed') != null)
                    ccpd.ClaimedAmount = double.valueOf(valueMap.get('billed'));
                if (valueMap.get('allowed') != null)
                    ccpd.ARC_Allowed__c = double.valueOf(valueMap.get('allowed'));
                if (valueMap.get('adjusted') != null)
                    ccpd.AdjustedAmount = double.valueOf(valueMap.get('adjusted'));
                if (valueMap.get('tobacco') != null)
                    ccpd.ARC_Tobacco__c = double.valueOf(valueMap.get('tobacco'));
                if (valueMap.get('copay') != null)
                    ccpd.ARC_Copay__c = double.valueOf(valueMap.get('copay'));
                if (valueMap.get('coinsurance') != null)
                    ccpd.ARC_Coinsurance__c = double.valueOf(valueMap.get('coinsurance'));
                if (valueMap.get('deductible') != null)
                    ccpd.ARC_Deductible__c = double.valueOf(valueMap.get('deductible'));
                if (valueMap.get('preExistingCond') != null)
                    ccpd.ARC_Pre_Existing_Condition__c = double.valueOf(valueMap.get('preExistingCond'));
                if (valueMap.get('visitReason') != null) {
                    if ((String) valueMap.get('visitReason') == 'Accupuncture') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'Acupuncture';
                    } else if ((String) valueMap.get('visitReason') == 'P. Therapy') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'PhysicalTherapy';
                    } else if ((String) valueMap.get('visitReason') == 'Chiropractic') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'Chiropractic';
                    } else if ((String) valueMap.get('visitReason') == 'Behavioral') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'Behavioral';
                    } else if ((String) valueMap.get('visitReason') == 'Office Visit/Copay') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'Office Visit/Copay';
                    } else if ((String) valueMap.get('visitReason') == 'Urgent Care') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'Urgent Care';
                    }
                }
            }
            String error;
            try {
                //upsert items;
                Database.SaveResult[] results = Database.update(items, false);
                for (Database.SaveResult result : results) {
                    if (!result.isSuccess()) {
                        error = result.getErrors()[0].getMessage();
                        throw new AuraHandledException(result.getErrors()[0].getMessage());
                    }
                }
                outMap.put('updated', true);
            } catch (Exception ex) {
                outMap.put('updated', false);
                outMap.put('updateError', error);
                //throw new AuraHandledException(ex.getMessage());
            }
        }
    }

    public static void deleteItems(Map<String, Object> inputMap, Map<String, Object> outMap) {
        Id recordId = (Id) inputMap.get('recordId');
        String ClaimStatus = [SELECT Status FROM Claim WHERE Id = :recordId].Status;

        system.debug(ClaimStatus);
        if (new List<String>{ 'Manual Approved', 'AA Approved', 'Manual Denied', 'AA Denied', 'Adjusted' }.contains(ClaimStatus)) {
            outMap.put('Status', 'Error');
            outMap.put('Message', 'This item cannot be deleted because the SMB is closed.');
            return;
        }

        List<Object> rowsSelected = (List<Object>) inputMap.get('rowsSelected');
        List<Id> deleteIds = new List<Id>();
        for (Object r : rowsSelected) {
            Map<String, Object> row = (Map<String, Object>) r;
            if ((String) row.get('status') == 'Paid') {
                outMap.put('Status', 'Error');
                outMap.put('Message', 'The item has already been paid and cannot be removed.');
            }
            deleteIds.add((Id) row.get('item'));
        }

        Database.delete(deleteIds);

        outMap.put('Status', 'Success');
        outMap.put('Message', 'Items have been successfully deleted.');
    }
}