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
        } else if (methodName == 'createIfMissingSMBItemPayments') {
            createIfMissingSMBItemPayments(inputMap, outputMap);
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
            	ARC_MemberBenefitPlanCode__c
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
            	Medicare_Adjusted__c,
                (SELECT Name, Id, ARC_CodeNameText__c, ARC_CodeDescription__c FROM Claim_Reason_Codes__r)
            FROM ClaimCoveragePaymentDetail
            WHERE ARC_Claim__c = :claimId
            ORDER BY ARC_ItemNumber__c NULLS LAST
            LIMIT 1000
        ];

        outputMap.put('items', records);
        outputMap.put('claimData', clm);
        
        // ADD CHECK TO SEE IF LEGACY IS IN NAME OF PLAN - THROTTLE COLUMNS ON TABLE ACCORDINGLY
        Boolean isLegacy = clm.ARC_MemberBenefitPlanCode__c != null && clm.ARC_MemberBenefitPlanCode__c.containsIgnoreCase('Legacy');
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
                    } else if ((String) item_reason.get('reason') == 'CC - Cologuard / Self Screen') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'CC - Cologuard / Self Screen';
                    } else if ((String) item_reason.get('reason') == 'CC - Flexible Sigmoidoscopy') {
                        ccpd.ARC_Medical_Visit_Reason__c = 'CC - Flexible Sigmoidoscopy';
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
            System.debug(err.getMessage());
            System.debug('errorOnUpdate ' + errorOnUpdate);
            outputMap.put('result', errorOnUpdate);
        }
    }

    public static void createItemPayments(Map<String, Object> inputMap, Map<String, Object> outMap) {
        Set<Id> itemIds = new Set<Id>();
        List<Object> strItemIds = (List<Object>) inputMap.get('itemIds');
        Boolean upsertOnlyPaymentItems = inputMap.containsKey('upsertOnlyPaymentItems')
            ? (Boolean) inputMap.get('upsertOnlyPaymentItems')
            : false;
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
        Date claimDOS;
        ARC_Aggregator__c shinglesVaccineAgg;
        Id individualMonthlyAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('IndividualMonthly').getRecordTypeId();
        Map<String,Boolean> vaccineConsumedInSMB = new Map<String,Boolean>(); // Map to validate if Shingle Vaccine has been consumed in previous line item of current SMB
        Case authCase;
        Integer PT_treatmentsToConsume = 0;
        List<Id> PT_newPivotCliIds = new List<Id>();
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
                ARC_MaximumType__c,
                ARC_MaximumTypeAmount__c,
                ARC_Claim__c,
                ARC_Claim__r.ARC_DOSFrom__c,
                ARC_Claim__r.ARC_MemberDOB__c,
                ARC_Claim__r.PolicyNumberId,
                ARC_Claim__r.ARC_MemberBenefitPlanCode__c,
                ARC_Claim__r.ARC_MemberBenefitEffectiveDate__c,
                ARC_Claim__r.ARC_MemberBenefitTermDate__c,
                ARC_Claim__r.ARC_ParticipantPolicyParticipant__c,
                ARC_Claim__r.ARC_ParticipantPolicyParticipant__r.PrimaryParticipantContact.AccountId,
                ARC_Claim__r.ARC_ParticipantPolicyParticipant__r.PrimaryParticipantContact.vlocity_ins__Age__c,
                ARC_Claim__r.PolicyNumber.ARC_Contract__r.Status,
                ARC_Claim__r.PolicyNumber.RenewedFromPolicyId,
                ARC_Claim__r.PolicyNumber.ARC_Contract__r.ARC_ContractReason__c,
                ARC_ProcedureCodeName__c,
                ARC_DateOfService__c,
                ARC_DOSTo__c,
                ARC_Is_PT_Pivot__c,
                ARC_Claim__r.ARC_Linked_PA_Voided__c,
                ARC_Claim__r.ARC_PriorAuthorizationCase__c,
                ARC_Claim__r.ARC_PriorAuthorizationCase__r.HealthCloudGA__SourceSystemID__c,
                ARC_Claim__r.ARC_PriorAuthorizationCase__r.Base_Source_System_Id__c,
                ARC_Claim__r.ARC_PriorAuthorizationCase__r.ARC_PT_Auth_From_Date__c,
                ARC_Claim__r.ARC_PriorAuthorizationCase__r.ARC_PT_Auth_To_Date__c,
                ARC_Claim__r.ARC_PriorAuthorizationCase__r.ARC_PT_Visits_Authorized__c,
                ARC_Claim__r.ARC_PriorAuthorizationCase__r.ARC_PT_Visits_Used__c,
                ARC_Claim__r.ARC_PriorAuthorizationCase__r.ARC_PT_Visits_Used_Total__c                
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
            // Validate PT Services
            Map<String, Object> inputMap_authCheck = new Map<String, Object>();
            inputMap_authCheck.put('claimItems', claimItems);
            inputMap_authCheck.put('voidedAuth', claimItems[0].ARC_Claim__r.ARC_PriorAuthorizationCase__r?.HealthCloudGA__SourceSystemID__c?.contains('_void'));
            inputMap_authCheck.put('caseId', claimItems[0].ARC_Claim__r.ARC_PriorAuthorizationCase__c);
            inputMap_authCheck.put('authFrom', claimItems[0].ARC_Claim__r.ARC_PriorAuthorizationCase__r?.ARC_PT_Auth_From_Date__c);
            inputMap_authCheck.put('authTo', claimItems[0].ARC_Claim__r.ARC_PriorAuthorizationCase__r?.ARC_PT_Auth_To_Date__c);
            Map<String, Object> PTCheckResult = ARC_AuthCaseUtility.checkForPhysicalTherapy(inputMap_authCheck);
            if (PTCheckResult.containsKey('error')) {
                String errMsg = (String)PTCheckResult.get('error');
                outMap.put('errorOnUpdate', errMsg);
                return;
            }
            else if (PTCheckResult.containsKey('newCliToDateMap') && PTCheckResult.get('newCliToDateMap') != null && !((Map<Id, Date>) PTCheckResult.get('newCliToDateMap')).isEmpty()) {
                PTCheckResult.put('authNumber', claimItems[0].ARC_Claim__r.ARC_PriorAuthorizationCase__r.Base_Source_System_Id__c);
                Map<String, Object> PTConsumptionResult = ARC_AuthCaseUtility.countPTConsumptionsForAuthCase(PTCheckResult);
                if(PTConsumptionResult.containsKey('error')){
                    String errMsg = (String)PTConsumptionResult.get('error');
                    outMap.put('errorOnUpdate', errMsg);
                    return;
                }else{
                    PT_treatmentsToConsume = (Integer)PTConsumptionResult.get('newDatesCount');
                    PT_newPivotCliIds = (List<Id>)PTConsumptionResult.get('newPivotCliIds');
                }
            }
            // End validate PT Services
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
            claimDOS = claimItems[0].ARC_Claim__r.ARC_DOSFrom__c;

            family_aggregator = [
                SELECT Id, ARC_FamilyCurrentValue__c, ARC_LimitValue__c
                FROM ARC_Aggregator__c
                WHERE RecordType.DeveloperName = 'Family'
                AND ARC_CreatedIn__c =: aggregators_policy_id
                AND ARC_Year__c =: claim_year_of_service
                    AND ARC_IsInactive__c = false
                LIMIT 1
            ];

        }

        List<ARC_ParticipantAggregator__c> participant_aggregators_list = [
            SELECT
                Id,
                ARC_ConsumedValue__c,
                ARC_Aggregator__r.ARC_Code__c,
                ARC_Aggregator__r.ARC_LimitValue__c,
                ARC_Aggregator__c,
                ARC_Aggregator__r.ARC_NextAvailabilityDate__c,
                ARC_Aggregator__r.ARC_StartDate__c,
                ARC_Aggregator__r.ARC_EndDate__c
            FROM ARC_ParticipantAggregator__c
            WHERE
                ARC_Aggregator__r.ARC_IsInactive__c = false
                AND (
                    (
                        ARC_Policy__c = :participant_aggregators_policyid 
                        AND ARC_PolicyParticipant__c = :participantId 
                        AND (ARC_Aggregator__r.ARC_Year__c = :claim_year_of_service OR ARC_Aggregator__r.ARC_Year__c = NULL) 
                        AND ARC_Aggregator__r.ARC_Code__c != 'MAT__c' 
                        AND ARC_Aggregator__r.ARC_Code__c != 'PREEX__c'
                    ) OR (
                        ARC_Policy__c = :participant_aggregators_policyid 
                        AND ARC_PolicyParticipant__c = :participantId 
                        AND ARC_Aggregator__r.ARC_StartDate__c <= :claimDOS 
                        AND ARC_Aggregator__r.ARC_EndDate__c >= :claimDOS
                        AND (ARC_Aggregator__r.ARC_Code__c = 'MAT__c' OR ARC_Aggregator__r.ARC_Code__c = 'PREEX__c')
                    )
                )
            LIMIT 1000
        ];

        List<String> maternityAggsList;
        List<String> preExAggsList;
        Boolean memberInMaternityPlan;
        Boolean memberInPreExPlan;
        Boolean mustHaveMaternityAgg;
        Boolean mustHavePreExAgg;

        // Get member account Id
        Id accId = claimItems[0].ARC_Claim__r.ARC_ParticipantPolicyParticipant__r.PrimaryParticipantContact.AccountId;
        // Get all Maternity/Pre Existing coverage periods of the member
        Map<Id, List<Map<String,Object>>> maternityCoveragePeriods = ARC_SMBUtility.mapCoveragePeriods(new List<Id>{accId}, 'MAT__c');
        Map<Id, List<Map<String,Object>>> preExCoveragePeriods = ARC_SMBUtility.mapCoveragePeriods(new List<Id>{accId}, 'PREEX__c');
        // Get all periods when a part agg must be created
        maternityAggsList = !maternityCoveragePeriods.isEmpty() ? ARC_SMBUtility.calculateAggregators(maternityCoveragePeriods.get(accId), 'MAT__c') : new List<String>();
        preExAggsList = !preExCoveragePeriods.isEmpty() ? ARC_SMBUtility.calculateAggregators(preExCoveragePeriods.get(accId), 'PREEX__c') : new List<String>();
        // Validate if member is in a plan with Maternity/Pre Existing in the DOS moment
        memberInMaternityPlan = !maternityCoveragePeriods.isEmpty() ? claimInCoveragePeriod(maternityCoveragePeriods.get(accId), claimDOS) : false;
        memberInPreExPlan = !preExCoveragePeriods.isEmpty() ? claimInCoveragePeriod(preExCoveragePeriods.get(accId), claimDOS) : false;
        mustHaveMaternityAgg = mustHaveAggregator(maternityAggsList, claimDOS);
        mustHavePreExAgg = mustHaveAggregator(preExAggsList, claimDOS);

        for (ARC_ParticipantAggregator__c participant_aggregator : participant_aggregators_list) {
            String aggCode = participant_aggregator.ARC_Aggregator__r.ARC_Code__c;
            Date aggStartDate = participant_aggregator.ARC_Aggregator__r.ARC_StartDate__c;
            if ((aggCode == 'MAT__c' && memberInMaternityPlan) || (aggCode == 'PREEX__c' && memberInPreExPlan)) {
                participant_aggregator_by_code.put(aggCode, participant_aggregator);
            } else if (aggCode == 'CRITILL__c') {
                participant_aggregator_by_code.put(aggCode + '-' + aggStartDate.Month() + aggStartDate.Year(), participant_aggregator);
            } else if (aggCode != 'MAT__c' || aggCode != 'PREEX__c') {
                participant_aggregator_by_code.put(aggCode, participant_aggregator);
            }
        }

        List<ARC_Aggregator__c> criticalIllnessAggregator = [
            SELECT Id,
                (
                    SELECT Id, ARC_StartDate__c, ARC_Code__c
                    FROM ComponentAggregators__r
                )
            FROM ARC_Aggregator__c
            WHERE ARC_IsInactive__c = false
                AND ARC_Code__c = 'CRITILL__c'
                AND RecordType.DeveloperName = 'Individual'
            ORDER BY ARC_CreatedIn__r.ARC_EffectiveDate__c DESC
        ];

        Map<String, ARC_Aggregator__c> criticalIllnessMonthlyMap = new Map<String, ARC_Aggregator__c>();
        Map<String, ARC_Aggregator__c> criticalIllnessMonthlyToInsert = new Map<String, ARC_Aggregator__c>();
        Map<String, ARC_ParticipantAggregator__c> criticalIllnessPartAggToInsert = new Map<String, ARC_ParticipantAggregator__c>();
        Map<String, List<ClaimPaymentSummary>> paymentsToLinkToCritIll = new Map<String, List<ClaimPaymentSummary>>();
        if (!criticalIllnessAggregator.isEmpty()) {
            for (ARC_Aggregator__c monthlyAgg : criticalIllnessAggregator[0].ComponentAggregators__r) {
                if (monthlyAgg.ARC_StartDate__c == null) continue;
                criticalIllnessMonthlyMap.put(monthlyAgg.ARC_Code__c + '-' + monthlyAgg.ARC_StartDate__c.Month() + monthlyAgg.ARC_StartDate__c.Year(), monthlyAgg);
            }
        }

        Double amcsConsumed = 0;

        // ADD VALUES INTO PARTICIPANT AGGREGATORS AND CREATE PAYMENT SUMMARIES
        for (ClaimCoveragePaymentDetail smb_item : claimItems) {
            Decimal memberAge = smb_item.ARC_Claim__r.ARC_ParticipantPolicyParticipant__r.PrimaryParticipantContact.vlocity_ins__Age__c;
            String productCode = smb_item.ARC_Claim__r.ARC_MemberBenefitPlanCode__c;
            // when upsertOnlyPaymentItems is false, SKIP ALREADY PAID ITEMS 
            // when upsertOnlyPaymentItems is true, we want to upsert payment items ONLY when the status is 'Paid'
            if (!upsertOnlyPaymentItems) {
                if (smb_item.Status == 'Paid')
                    continue;
                smb_item.Status = 'Paid';
                // flag necessary smb item to account for a Physical Therapy visit
                if(PT_newPivotCliIds.contains(smb_item.Id))
                    smb_item.ARC_Is_PT_Pivot__c = true;
            } else if (smb_item.Status != 'Paid') { 
                continue;
            }
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
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Deductible__c != 0 && smb_item.ARC_Deductible__c != null && participant_aggregator_by_code.get('AMCS__c') == null) {
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // PRE EXISTING CONDITIONS
            if (smb_item.ARC_Pre_Existing_Condition__c != 0 && smb_item.ARC_Pre_Existing_Condition__c != null && memberInPreExPlan == true) {
                // Validate if claim must have participant aggregator based on claim DOS
                if (!preExAggsList.isEmpty() && participant_aggregator_by_code.get('PREEX__c') == null && mustHavePreExAgg) {
                    outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                    return;
                } else if (participant_aggregator_by_code.get('PREEX__c') != null) {
                    participant_aggregator_by_code.get('PREEX__c').ARC_ConsumedValue__c =
                        participant_aggregator_by_code.get('PREEX__c').ARC_ConsumedValue__c != null ?
                            participant_aggregator_by_code.get('PREEX__c').ARC_ConsumedValue__c + smb_item.ARC_Pre_Existing_Condition__c
                            : smb_item.ARC_Pre_Existing_Condition__c;
                }
                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - PREEX__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.containsKey('PREEX__c') && participant_aggregator_by_code.get('PREEX__c') != null ? participant_aggregator_by_code.get('PREEX__c').Id : null;
                sum.ARC_ConsumedValue__c = smb_item.ARC_Pre_Existing_Condition__c;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Pre_Existing_Condition__c != 0 && smb_item.ARC_Pre_Existing_Condition__c != null && memberInPreExPlan == false) {
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
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
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
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
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
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
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
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
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // MATERNITY
            if (
                smb_item.ARC_MaximumTypeAmount__c != 0 &&
                smb_item.ARC_MaximumTypeAmount__c != null &&
                smb_item.ARC_MaximumType__c == 'Maternity' &&
                memberInMaternityPlan == true
            ) {
                if (Integer.valueOf(claim_year_of_service) >= 2026 && productCode.contains('Access')) {
                    outMap.put('errorOnUpdate', 'Maternity is not part of this program anymore.');
                    return;
                } else {
                    // Validate if claim must have participant aggregator based on claim DOS
                    if (!maternityAggsList.isEmpty() && participant_aggregator_by_code.get('MAT__c') == null && mustHaveMaternityAgg) {
                        outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                        return;
                    } else if (participant_aggregator_by_code.get('MAT__c') != null) {
                        participant_aggregator_by_code.get('MAT__c').ARC_ConsumedValue__c += smb_item.ARC_MaximumTypeAmount__c;
                    }
                    ClaimPaymentSummary sum = new ClaimPaymentSummary();
                    sum.Name = smb_item.Name + ' - MAT__c';
                    sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.containsKey('MAT__c') && participant_aggregator_by_code.get('MAT__c') != null ? participant_aggregator_by_code.get('MAT__c').Id : null;
                    sum.ARC_ConsumedValue__c = smb_item.ARC_MaximumTypeAmount__c;
                    sum.ARC_SMB_Item__c = smb_item.Id;
                    sum.ClaimId = smb_item.ARC_Claim__c;
                    sum.PaymentDate = System.today();
                    sum.PaymentAmount = smb_item.ClaimedAmount;
                    paymentsToCreate.add(sum);
                }
            } else if (
                smb_item.ARC_MaximumTypeAmount__c != 0 &&
                smb_item.ARC_MaximumTypeAmount__c != null &&
                smb_item.ARC_MaximumType__c == 'Maternity' &&
                memberInMaternityPlan == false
            ) {
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
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
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // ACCUPUNCTURE
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
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
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
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // PHYSICAL THERAPY
            if (smb_item.ARC_Medical_Visit_Reason__c == 'PhysicalTherapy' && smb_item.ARC_Claim__r.ARC_Linked_PA_Voided__c == false) {
                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - PHYTH__c';
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'PhysicalTherapy' && participant_aggregator_by_code.get('PHYTH__c') == null) {
                outMap.put('errorOnUpdate', 'Linked Authorization is voided.');
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
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
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
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
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
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // SLEEP/INSOMNIA COUNSELING
            if (smb_item.ARC_Medical_Visit_Reason__c == 'Sleep/Insomnia Counseling' && participant_aggregator_by_code.get('SLEEP__c') != null) {
                participant_aggregator_by_code.get('SLEEP__c').ARC_ConsumedValue__c += 1;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - SLEEP__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('SLEEP__c').Id;
                sum.ARC_ConsumedValue__c = 1;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'Sleep/Insomnia Counseling' && participant_aggregator_by_code.get('SLEEP__c') == null) {
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // CERVICAL CANCER SCREENINGS
            if (smb_item.ARC_Medical_Visit_Reason__c == 'Cervical Cancer Screenings' && participant_aggregator_by_code.get('CCS__c') != null) {
                if (productCode.contains('Legacy')) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('CCS__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = claimDOS.addYears(2)
                        )
                    );
                } else if (memberAge >= 21 && memberAge <= 29) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('CCS__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = claimDOS.addYears(3)
                        )
                    );
                } else if (memberAge >= 30 && memberAge <= 65) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('CCS__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = claimDOS.addYears(5)
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
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // SELF-SCREEN OPTION
            if (smb_item.ARC_Medical_Visit_Reason__c == 'CC - Cologuard / Self Screen' && participant_aggregator_by_code.get('SSOPT__c') != null) {
                if (memberAge >= 45) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('SSOPT__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = claimDOS.addYears(3)
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
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'CC - Cologuard / Self Screen' && participant_aggregator_by_code.get('SSOPT__c') == null) {
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // COLONOSCOPY
            if (smb_item.ARC_Medical_Visit_Reason__c == 'CC - Colonoscopy' && participant_aggregator_by_code.get('CLON__c') != null) {
                if (Integer.valueOf(claim_year_of_service) >= 2026 && productCode.contains('Access')) {
                    outMap.put('errorOnUpdate', 'Colonoscopy is not part of this program anymore.');
                    return;
                } else {
                if (memberAge >= 45) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('CLON__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = claimDOS.addYears(10)
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
                }
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'CC - Colonoscopy' && participant_aggregator_by_code.get('CLON__c') == null) {
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // FLEXIBLE SIGMOIDOSCOPY
            if (smb_item.ARC_Medical_Visit_Reason__c == 'CC - Flexible Sigmoidoscopy' && participant_aggregator_by_code.get('FLXSIG__c') != null) {
                if (Integer.valueOf(claim_year_of_service) >= 2026 && productCode.contains('Access')) {
                    outMap.put('errorOnUpdate', 'Flexible Sigmoidoscopy is not part of this program anymore.');
                    return;
                } else {
                if (productCode.contains('Legacy')) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('FLXSIG__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = claimDOS.addYears(4)
                        )
                    );
                } else if (memberAge >= 45) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('FLXSIG__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = claimDOS.addYears(5)
                        )
                    );
                } else {
                        outMap.put('errorOnUpdate', 'Member must be 45 or older to use Flexible Sigmoidoscopy');
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
                }
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'CC - Flexible Sigmoidoscopy' && participant_aggregator_by_code.get('FLXSIG__c') == null) {
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // MAMMOGRAMS
            if (smb_item.ARC_Medical_Visit_Reason__c == 'Mammograms' && participant_aggregator_by_code.get('MAMM__c') != null) {
                if (memberAge >= 40 && memberAge <= 54) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('MAMM__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = claimDOS.addYears(1)
                        )
                    );
                } else if (memberAge >= 55) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('MAMM__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = claimDOS.addYears(2)
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
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // PROSTATE SCREENINGS
            if (smb_item.ARC_Medical_Visit_Reason__c == 'Prostate Screenings' && participant_aggregator_by_code.get('PROSCRE__c') != null) {
                if (memberAge >= 45) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('PROSCRE__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = claimDOS.addYears(2)
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
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // CPAP/BIPAP Supplies
            if (
                smb_item.ARC_MaximumTypeAmount__c != 0 &&
                smb_item.ARC_MaximumTypeAmount__c != null &&
                smb_item.ARC_MaximumType__c == 'CPAP/BIPAP Supplies' &&
                participant_aggregator_by_code.get('CBIPAP__c') != null
            ) {
                if (productCode.contains('Legacy') || productCode.contains('Access')) {
                    outMap.put('errorOnUpdate', 'CPAP/BIPAP Supplies aggregator is not part of this program');
                return;
                } else {
                    participant_aggregator_by_code.get('CBIPAP__c').ARC_ConsumedValue__c += smb_item.ARC_MaximumTypeAmount__c;

                    ClaimPaymentSummary sum = new ClaimPaymentSummary();
                    sum.Name = smb_item.Name + ' - CBIPAP__c';
                    sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('CBIPAP__c').Id;
                    sum.ARC_ConsumedValue__c = smb_item.ARC_MaximumTypeAmount__c;
                    sum.ARC_SMB_Item__c = smb_item.Id;
                    sum.ClaimId = smb_item.ARC_Claim__c;
                    sum.PaymentDate = System.today();
                    sum.PaymentAmount = smb_item.ClaimedAmount;
                    paymentsToCreate.add(sum);
                }
            } else if (
                smb_item.ARC_MaximumTypeAmount__c != 0 &&   
                smb_item.ARC_MaximumTypeAmount__c != null &&
                smb_item.ARC_MaximumType__c == 'CPAP/BIPAP Supplies' &&
                participant_aggregator_by_code.get('CBIPAP__c') == null
            ) {
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // AFTER LIFE
            if (
                smb_item.ARC_MaximumTypeAmount__c != 0 &&
                smb_item.ARC_MaximumTypeAmount__c != null &&
                smb_item.ARC_MaximumType__c == 'After Life' &&
                participant_aggregator_by_code.get('LIFE__c') != null
            ) {
                participant_aggregator_by_code.get('LIFE__c').ARC_ConsumedValue__c += smb_item.ARC_MaximumTypeAmount__c;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - LIFE__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('LIFE__c').Id;
                sum.ARC_ConsumedValue__c = smb_item.ARC_MaximumTypeAmount__c;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (
                smb_item.ARC_MaximumTypeAmount__c != 0 &&
                smb_item.ARC_MaximumTypeAmount__c != null &&
                smb_item.ARC_MaximumType__c == 'After Life' &&
                participant_aggregator_by_code.get('LIFE__c') == null
            ) {
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // CRITICAL ILLNESS AND BILL
            if (
                smb_item.ARC_MaximumTypeAmount__c != 0 &&
                smb_item.ARC_MaximumTypeAmount__c != null &&
                smb_item.ARC_MaximumType__c == 'Critical Illness and Bill'
            ) {
                if (!productHasExpectedAggregator(productCode, 'CRITILL__c')) {
                    outMap.put('errorOnUpdate', 'Critical Illness and Bill is not part of this program.');
                    return;
                } else {
                    String critIllKey = 'CRITILL__c-' + claimDOS.Month() + claimDOS.Year();
                    if (participant_aggregator_by_code.containsKey(critIllKey)) {
                        participant_aggregator_by_code.get(critIllKey).ARC_ConsumedValue__c += smb_item.ARC_MaximumTypeAmount__c;

                        ClaimPaymentSummary sum = new ClaimPaymentSummary();
                        sum.Name = smb_item.Name + ' - CRITILL__c';
                        sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get(critIllKey).Id;
                        sum.ARC_ConsumedValue__c = smb_item.ARC_MaximumTypeAmount__c;
                        sum.ARC_SMB_Item__c = smb_item.Id;
                        sum.ClaimId = smb_item.ARC_Claim__c;
                        sum.PaymentDate = System.today();
                        sum.PaymentAmount = smb_item.ClaimedAmount;
                        paymentsToCreate.add(sum);
                    } else if (criticalIllnessMonthlyMap.containsKey(critIllKey)) {
                        ARC_ParticipantAggregator__c newPartAgg = new ARC_ParticipantAggregator__c(
                            Name = 'Critical Illness and Bill',
                            ARC_Policy__c = participant_aggregators_policyid,
                            ARC_PolicyParticipant__c = participantId,
                            ARC_ConsumedValue__c = smb_item.ARC_MaximumTypeAmount__c
                        );
                        participant_aggregator_by_code.put(critIllKey, newPartAgg);
                        criticalIllnessPartAggToInsert.put(critIllKey, newPartAgg);
                        
                        ClaimPaymentSummary sum = new ClaimPaymentSummary();
                        sum.Name = smb_item.Name + ' - CRITILL__c';
                        sum.ARC_ConsumedValue__c = smb_item.ARC_MaximumTypeAmount__c;
                        sum.ARC_SMB_Item__c = smb_item.Id;
                        sum.ClaimId = smb_item.ARC_Claim__c;
                        sum.PaymentDate = System.today();
                        sum.PaymentAmount = smb_item.ClaimedAmount;
                        if (!paymentsToLinkToCritIll.containsKey(critIllKey)) {
                            paymentsToLinkToCritIll.put(critIllKey, new List<ClaimPaymentSummary>());
                        }
                        paymentsToLinkToCritIll.get(critIllKey).add(sum);
                        paymentsToCreate.add(sum);
                    } else if (!criticalIllnessAggregator.isEmpty()) {
                        Date startOfMonth = claimDOS.toStartOfMonth();
                        Date endOfMonth = startOfMonth.addMonths(1).addDays(-1);
                        String year = String.valueOf(startOfMonth.year());
                        ARC_Aggregator__c monthlyAgg = new ARC_Aggregator__c(
                            RecordTypeId = individualMonthlyAggRT,
                            Name = 'Critical Illness and Bill',
                            ARC_Code__c = 'CRITILL__c',
                            ARC_Type__c = 'Currency',
                            ARC_ParentAggregator__c = criticalIllnessAggregator[0].Id,
                            ARC_CreatedIn__c = participant_aggregators_policyid,
                            ARC_LimitValue__c = 1000,
                            ARC_Member__c = accId,
                            ARC_StartDate__c = startOfMonth,
                            ARC_EndDate__c = endOfMonth,
                            ARC_Year__c = year
                        );
                        criticalIllnessMonthlyMap.put(critIllKey, monthlyAgg);
                        criticalIllnessMonthlyToInsert.put(critIllKey, monthlyAgg);
                        
                        ARC_ParticipantAggregator__c newPartAgg = new ARC_ParticipantAggregator__c(
                            Name = 'Critical Illness and Bill',
                            ARC_Policy__c = participant_aggregators_policyid,
                            ARC_PolicyParticipant__c = participantId,
                            ARC_ConsumedValue__c = smb_item.ARC_MaximumTypeAmount__c
                        );
                        participant_aggregator_by_code.put(critIllKey, newPartAgg);
                        criticalIllnessPartAggToInsert.put(critIllKey, newPartAgg);

                        ClaimPaymentSummary sum = new ClaimPaymentSummary();
                        sum.Name = smb_item.Name + ' - CRITILL__c';
                        sum.ARC_ConsumedValue__c = smb_item.ARC_MaximumTypeAmount__c;
                        sum.ARC_SMB_Item__c = smb_item.Id;
                        sum.ClaimId = smb_item.ARC_Claim__c;
                        sum.PaymentDate = System.today();
                        sum.PaymentAmount = smb_item.ClaimedAmount;
                        if (!paymentsToLinkToCritIll.containsKey(critIllKey)) {
                            paymentsToLinkToCritIll.put(critIllKey, new List<ClaimPaymentSummary>());
                        }
                        paymentsToLinkToCritIll.get(critIllKey).add(sum);
                        paymentsToCreate.add(sum);
                    } else {
                        outMap.put('errorOnUpdate', 'Some Aggregators are missing.');
                        return;
                    }
                }
            }

            // Generic Formulary Injectable Pen
            //if (smb_item.ARC_Medical_Visit_Reason__c == 'Generic Formulary Injectable Pen' && participant_aggregator_by_code.get('GENINJ__c') != null) {
            //    if (productCode.contains('Legacy')) {
            //        outMap.put('errorOnUpdate', 'Generic Formulary Injectable Pen aggregator is not part of this program.');
            //        return;
            //    } else {
            //        participant_aggregator_by_code.get('GENINJ__c').ARC_ConsumedValue__c += 1;
            //
            //        ClaimPaymentSummary sum = new ClaimPaymentSummary();
            //        sum.Name = smb_item.Name + ' - GENINJ__c';
            //        sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('GENINJ__c').Id;
            //        sum.ARC_ConsumedValue__c = 1;
            //        sum.ARC_SMB_Item__c = smb_item.Id;
            //        sum.ClaimId = smb_item.ARC_Claim__c;
            //        sum.PaymentDate = System.today();
            //        sum.PaymentAmount = smb_item.ClaimedAmount;
            //        paymentsToCreate.add(sum);
            //    }
            //} else if (smb_item.ARC_Medical_Visit_Reason__c == 'Generic Formulary Injectable Pen' && participant_aggregator_by_code.get('GENINJ__c') == null) {
            //    outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
            //    return;
            //}

            
            // Standard Brand Formulary Injectable Pen
            //if (smb_item.ARC_Medical_Visit_Reason__c == 'Standard Brand Formulary Injectable Pen' && participant_aggregator_by_code.get('STDINJ__c') != null) {
            //    if (productCode.contains('Legacy')) {
            //        outMap.put('errorOnUpdate', 'Standard Brand Formulary Injectable Pen aggregator is not part of this program.');
            //        return;
            //    } else {
            //        participant_aggregator_by_code.get('STDINJ__c').ARC_ConsumedValue__c += 1;
            //
            //        ClaimPaymentSummary sum = new ClaimPaymentSummary();
            //        sum.Name = smb_item.Name + ' - STDINJ__c';
            //        sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('STDINJ__c').Id;
            //        sum.ARC_ConsumedValue__c = 1;
            //        sum.ARC_SMB_Item__c = smb_item.Id;
            //        sum.ClaimId = smb_item.ARC_Claim__c;
            //        sum.PaymentDate = System.today();
            //        sum.PaymentAmount = smb_item.ClaimedAmount;
            //        paymentsToCreate.add(sum);
            //    }
            //} else if (smb_item.ARC_Medical_Visit_Reason__c == 'Standard Brand Formulary Injectable Pen' && participant_aggregator_by_code.get('STDINJ__c') == null) {
            //    outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
            //    return;
            //}

            
            // Non-Formulary Brand Injectable Pen
            //if (smb_item.ARC_Medical_Visit_Reason__c == 'Non-Formulary Brand Injectable Pen' && participant_aggregator_by_code.get('NONINJ__c') != null) {
            //    if (productCode.contains('Legacy')) {
            //        outMap.put('errorOnUpdate', 'Non-Formulary Brand Injectable Pen aggregator is not part of this program.');
            //        return;
            //    } else {
            //        participant_aggregator_by_code.get('NONINJ__c').ARC_ConsumedValue__c += 1;
            //
            //        ClaimPaymentSummary sum = new ClaimPaymentSummary();
            //        sum.Name = smb_item.Name + ' - NONINJ__c';
            //        sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('NONINJ__c').Id;
            //        sum.ARC_ConsumedValue__c = 1;
            //        sum.ARC_SMB_Item__c = smb_item.Id;
            //        sum.ClaimId = smb_item.ARC_Claim__c;
            //        sum.PaymentDate = System.today();
            //        sum.PaymentAmount = smb_item.ClaimedAmount;
            //        paymentsToCreate.add(sum);
            //    }
            //} else if (smb_item.ARC_Medical_Visit_Reason__c == 'Non-Formulary Brand Injectable Pen' && participant_aggregator_by_code.get('NONINJ__c') == null) {
            //    outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
            //    return;
            //}

            
            // Specialty Brand Injectable Pen
            //if (smb_item.ARC_Medical_Visit_Reason__c == 'Specialty Brand Injectable Pen' && participant_aggregator_by_code.get('SPEINJ__c') != null) {
            //    if (productCode.contains('Legacy')) {
            //        outMap.put('errorOnUpdate', 'Specialty Brand Injectable Pen aggregator is not part of this program.');
            //        return;
            //    } else {
            //        participant_aggregator_by_code.get('SPEINJ__c').ARC_ConsumedValue__c += 1;
            //
            //        ClaimPaymentSummary sum = new ClaimPaymentSummary();
            //        sum.Name = smb_item.Name + ' - SPEINJ__c';
            //        sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('SPEINJ__c').Id;
            //        sum.ARC_ConsumedValue__c = 1;
            //        sum.ARC_SMB_Item__c = smb_item.Id;
            //        sum.ClaimId = smb_item.ARC_Claim__c;
            //        sum.PaymentDate = System.today();
            //        sum.PaymentAmount = smb_item.ClaimedAmount;
            //        paymentsToCreate.add(sum);
            //    }
            //    
            //} else if (smb_item.ARC_Medical_Visit_Reason__c == 'Specialty Brand Injectable Pen' && participant_aggregator_by_code.get('SPEINJ__c') == null) {
            //    outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
            //    return;
            //}

            // Bone Density Screening
            if (smb_item.ARC_Medical_Visit_Reason__c == 'Bone Density Screening' && participant_aggregator_by_code.get('BOSCR__c') != null) {
                if (productCode.contains('Legacy')) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('BOSCR__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = claimDOS.addYears(2)
                        )
                    );
                    participant_aggregator_by_code.get('BOSCR__c').ARC_ConsumedValue__c += 1;

                    ClaimPaymentSummary sum = new ClaimPaymentSummary();
                    sum.Name = smb_item.Name + ' - BOSCR__c';
                    sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('BOSCR__c').Id;
                    sum.ARC_ConsumedValue__c = 1;
                    sum.ARC_SMB_Item__c = smb_item.Id;
                    sum.ClaimId = smb_item.ARC_Claim__c;
                    sum.PaymentDate = System.today();
                    sum.PaymentAmount = smb_item.ClaimedAmount;
                    paymentsToCreate.add(sum);
                } else {
                    outMap.put('errorOnUpdate', 'Bone Density Screening is only available in Legacy program.');
                    return;
                }
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'Bone Density Screening' && participant_aggregator_by_code.get('BOSCR__c') == null) {
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // Well Woman Visit
            if (smb_item.ARC_Medical_Visit_Reason__c == 'Well Woman Visit' && participant_aggregator_by_code.get('WOVIS__c') != null) {
                if (productCode.contains('Legacy')) {
                    aggsUpdated.add(
                        new ARC_Aggregator__c(
                            Id = participant_aggregator_by_code.get('WOVIS__c').ARC_Aggregator__c,
                            ARC_NextAvailabilityDate__c = claimDOS.addYears(2)
                        )

                    );
                    participant_aggregator_by_code.get('WOVIS__c').ARC_ConsumedValue__c += 1;

                    ClaimPaymentSummary sum = new ClaimPaymentSummary();
                    sum.Name = smb_item.Name + ' - WOVIS__c';
                    sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('WOVIS__c').Id;
                    sum.ARC_ConsumedValue__c = 1;
                    sum.ARC_SMB_Item__c = smb_item.Id;
                    sum.ClaimId = smb_item.ARC_Claim__c;
                    sum.PaymentDate = System.today();
                    sum.PaymentAmount = smb_item.ClaimedAmount;
                    paymentsToCreate.add(sum);
                } else {
                    outMap.put('errorOnUpdate', 'Well Woman Visit is only available in Legacy program.');
                    return;
                }
            } else if (smb_item.ARC_Medical_Visit_Reason__c == 'Well Woman Visit' && participant_aggregator_by_code.get('WOVIS__c') == null) {
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
                return;
            }

            // Shingles Vaccine
            if (smb_item.ARC_Medical_Visit_Reason__c != null && (smb_item.ARC_Medical_Visit_Reason__c).contains('Shingles Vaccine') && participant_aggregator_by_code.get('SHINVAC__c') != null) {
                String vaccineType = (smb_item.ARC_Medical_Visit_Reason__c).substringAfter('-').trim();
                Decimal aggLimitValue = participant_aggregator_by_code.get('SHINVAC__c').ARC_Aggregator__r.ARC_LimitValue__c;

                if (aggLimitValue == 0 || aggLimitValue == 2) {
                    // Validate if Zostavax (one shot) is trying to be consumed and already has one dose consumed in the same SMB
                    if (aggLimitValue == 0 && vaccineType == 'Zostavax 90736' && vaccineConsumedInSMB.get(vaccineType) == true) {
                        outMap.put('errorOnUpdate', 'Zostavax Vaccine can only be consumed one time.');
                        return;
                    } 
                    // Validate if Shingrix (two shots) is trying to be consumed and already has two doses consumed in the same SMB
                    else if (aggLimitValue == 0 && vaccineType == 'Shingrix 90750' && vaccineConsumedInSMB.get(vaccineType) == true && participant_aggregator_by_code.get('SHINVAC__c').ARC_ConsumedValue__c == 2) {
                        outMap.put('errorOnUpdate', 'Shingrix Vaccine can only be consumed twice.');
                        return;
                    } 
                    // Validate if two different vaccines are trying to be consumed in the same SMB
                    else if (aggLimitValue == 0 && ((vaccineType == 'Zostavax 90736' && vaccineConsumedInSMB.get('Shingrix 90750') == true) || (vaccineType == 'Shingrix 90750' && vaccineConsumedInSMB.get('Zostavax 90736') == true))) {
                        outMap.put('errorOnUpdate', 'Two different vaccines are trying to be consumed in the same SMB');
                        return;
                    } 
                    // Validate if Zostavax (one shot) is trying to be consumed and Shingrix (two shots) has been previously consumed
                    else if (aggLimitValue == 2 && vaccineType == 'Zostavax 90736') {
                        outMap.put('errorOnUpdate', 'Another Vaccine has been previously consumed.');
                        return;
                    }
                    else {
                        ARC_Aggregator__c aggToUpdate = new ARC_Aggregator__c();
                        aggToUpdate.Id = participant_aggregator_by_code.get('SHINVAC__c').ARC_Aggregator__c;
                        aggToUpdate.ARC_LimitValue__c = vaccineType == 'Zostavax 90736' ? 1 : vaccineType == 'Shingrix 90750' ? 2 : 0;
                        shinglesVaccineAgg = aggToUpdate;
                        vaccineConsumedInSMB.put(vaccineType, true);
                    }
                }

                participant_aggregator_by_code.get('SHINVAC__c').ARC_ConsumedValue__c += 1;

                ClaimPaymentSummary sum = new ClaimPaymentSummary();
                sum.Name = smb_item.Name + ' - SHINVAC__c';
                sum.ARC_ParticipantAggregator__c = participant_aggregator_by_code.get('SHINVAC__c').Id;
                sum.ARC_ConsumedValue__c = 1;
                sum.ARC_SMB_Item__c = smb_item.Id;
                sum.ClaimId = smb_item.ARC_Claim__c;
                sum.PaymentDate = System.today();
                sum.PaymentAmount = smb_item.ClaimedAmount;
                paymentsToCreate.add(sum);
            } else if (smb_item.ARC_Medical_Visit_Reason__c != null && (smb_item.ARC_Medical_Visit_Reason__c).contains('Shingles Vaccine') && participant_aggregator_by_code.get('SHINVAC__c') == null) {
                outMap.put('errorOnUpdate', 'Some Participant Aggregators are missing.');
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
            String error_messages_string;
            Boolean update_contains_partial_errors = false;

            // Critical Illness and Bill
            if (!criticalIllnessMonthlyToInsert.isEmpty()) {
                insert criticalIllnessMonthlyToInsert.values();
            }
            if (!criticalIllnessPartAggToInsert.isEmpty()) {
                for (String key : criticalIllnessPartAggToInsert.keySet()) {
                    ARC_ParticipantAggregator__c partAgg = criticalIllnessPartAggToInsert.get(key);
                    partAgg.ARC_Aggregator__c = criticalIllnessMonthlyMap.get(key).Id;
                }
                insert criticalIllnessPartAggToInsert.values();
            }
            if (!paymentsToLinkToCritIll.isEmpty()) {
                for (String key : paymentsToLinkToCritIll.keySet()) {
                    List<ClaimPaymentSummary> paymentList = paymentsToLinkToCritIll.get(key);
                    for (ClaimPaymentSummary payment : paymentList) {
                        payment.ARC_ParticipantAggregator__c = criticalIllnessPartAggToInsert.get(key).Id;
                    }
                }
            }
            
            
            
            // PartAggs update
            if (!upsertOnlyPaymentItems) {
                // Update Shingles Vaccine aggregator if consumed (need to be updated before PartAgg if != null)
                if (shinglesVaccineAgg != null) {
                    update shinglesVaccineAgg;
                }
                if(PT_treatmentsToConsume > 0){
                    authCase = [SELECT Id, ARC_PT_Visits_Used__c FROM Case WHERE Id = :claimItems[0].ARC_Claim__r.ARC_PriorAuthorizationCase__c];
                    authCase.ARC_PT_Visits_Used__c += PT_treatmentsToConsume;
                    update authCase;
                }
                Database.SaveResult[] save_results_list = Database.update(participant_aggregator_by_code.values(), true);
                for (Database.SaveResult result : save_results_list) {
                    if (result.isSuccess() == false) {
                        update_contains_partial_errors = true;
                        error_messages_string += String.join(result.getErrors(), ' - ');
                    }
                }
            }

            if (update_contains_partial_errors == false) {
                insert paymentsToCreate; // PAYMENT ITEMS
                if (!upsertOnlyPaymentItems) {
                    update itemsPaid; // SMB Items set to Paid
                    update aggsUpdated;  // Aggs
                    if (itemsPaid.size() > 0 && paymentsToCreate.size() > 0)
                        outMap.put('itemsPaid', 'Items has been paid and some aggregators were affected!');
                    else
                        outMap.put('itemsPaid', 'Items has been paid successfully!');
                }
            } else {
                outMap.put('errorOnUpdate', error_messages_string);
            }
        } catch (Exception e) {
            outMap.put('errorOnUpdate', e.getMessage());
        }
    }

    public static void uncommitAllChanges(Map<String, Object> inputMap, Map<String, Object> outMap) {
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
        outMap.put('updated', updated);
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////            
    ////////////////////////////////////////START////////////////////////////////////////////////////////////////            
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////       
    public static Boolean createIfMissingSMBItemPayments(Map<String, Object> inputMap, Map<String, Object> outMap) {
        String claimId = (String) inputMap.get('claimId');
        Set<Id> claimLineItemIds = new Set<Id>();
        List<Object> strItemIds = (List<Object>) inputMap.get('itemIds');
        List<ClaimCoveragePaymentDetail> smb_items;
        if (strItemIds != null) {
            for (Object item : strItemIds)
                claimLineItemIds.add(String.valueOf(item));
        }

        // Construct the entire base query as a single string
        String baseQuery = 'SELECT Id, ARC_Claim__r.ARC_ParticipantPolicyParticipant__r.PrimaryParticipantContact.vlocity_ins__Age__c, RecordType.DeveloperName, Status, AdjustedAmount, ARC_PrimaryPaid__c, ARC_Copay__c, ARC_Coinsurance__c, ARC_Deductible__c, ARC_MBRLiability__c, ARC_Medical_Visit_Reason__c, ARC_Pre_Existing_Condition__c, ARC_Tobacco__c, ARC_Claim__r.ARC_ParticipantPolicyParticipant__r.PrimaryParticipantContact.AccountId, ARC_Claim__r.ARC_ParticipantPolicyParticipant__c, ARC_Claim__r.PolicyNumberId,'
            + ' (SELECT Id, ARC_ParticipantAggregator__r.ARC_Aggregator__c, ARC_ParticipantAggregator__r.ARC_ConsumedValue__c, ARC_ConsumedValue__c, ARC_AMCS_amount__c, ARC_PreExistingCond__c, ARC_Tobacco__c, ARC_ShareAMCS__c, ARC_Medical_Visit__c FROM SMB_Item_Payments__r)' 
            + ' FROM ClaimCoveragePaymentDetail ';

        // Add the WHERE clause dynamically based on the size of ccpdIds
        String whereClause = (claimLineItemIds.isEmpty()) ? 'WHERE ARC_Claim__c = :claimId ' : 'WHERE Id IN :ccpdIds ';
        // Construct the final query string with LIMIT
        String fullQuery = baseQuery + whereClause + 'LIMIT 3000';
        
        Map<String, Object> bindMap = new Map<String, Object>{'claimId' => claimId, 'ccpdIds' => claimLineItemIds};

        // Execute the query
        smb_items = Database.queryWithBinds(fullQuery, bindMap, AccessLevel.SYSTEM_MODE);

        if (smb_items.size() == 0)
            return false;
     
        // RESETTING AGGREGATORS RELIES ON SMB ITEM PAYMENT SUMMARY RECORDS BEING PRESENT
        // IF THEY ARE NOT PRESENT, CALL ARC_CoveragePaymentsTableController.createItemPayments on the paid claim items
        // PASSING FLAG TO MODIFY ONLY THE PAYMENT ITEMS NOR THE AGGREGATORS NOT THE LINE ITEMS
        List<ClaimCoveragePaymentDetail> paidCLIs = new List<ClaimCoveragePaymentDetail>();
        Boolean hasPaymentSummaries = false;
        for (ClaimCoveragePaymentDetail cli : smb_items) {
            if (cli.Status == 'Paid') {
                paidCLIs.add(cli);  
                if (cli.SMB_Item_Payments__r.size() > 0) {
                    hasPaymentSummaries = true;
                }
            }
        }

        if (paidCLIs.size() != 0 && !hasPaymentSummaries) {
            List<Id> cliIds = new List<Id>();
            for (ClaimCoveragePaymentDetail cli : paidCLIs) {
                cliIds.add(cli.Id);
            }

            Map<String, Object> inputMap2 = new Map<String, Object>{
                'itemIds' => cliIds,
                'claimId' => claimId,
                'upsertOnlyPaymentItems' => true // isReassignmentFlow flag to avoid modifying original aggregators 
            };
            Map<String, Object> outMap2 = new Map<String, Object>();
            // method will set CLIs to Paid status again and create the payment items
            ARC_CoveragePaymentsTableController.createItemPayments(inputMap2, outMap2);
        }
        return true;
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////END///////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////


    public static Boolean resetItems(Claim claim, String action, Set<Id> ccpdIds) {
        Savepoint sp = Database.setSavepoint();
        try {
            Map<String, Object> inputMap = new Map<String, Object>();
            inputMap.put('claimId', claim.id);
            List<Id> ccpdIdsList = new List<Id>();
            for (Id ccpd:ccpdIds) {
                ccpdIdsList.add(ccpd);
            }
            inputMap.put('itemIds', ccpdIdsList);
            Map<String, Object> outMap = new Map<String, Object>();
            createIfMissingSMBItemPayments(inputMap, outMap);
            Map<Id, ARC_ParticipantAggregator__c> partAggs = new Map<Id, ARC_ParticipantAggregator__c>();
            List<ClaimPaymentSummary> pSummaryList = new List<ClaimPaymentSummary>();
            List<ARC_ClaimReasonCode__c> rCodeList = new List<ARC_ClaimReasonCode__c>();
            List<ClaimCoveragePaymentDetail> smb_items;

            List<Id> aggIds = new List<Id>();
            List<ARC_Aggregator__c> aggregatorsToUpdate = new List<ARC_Aggregator__c>();
            Integer memberAge;
            String productCode;

            // Construct the entire base query as a single string
            String baseQuery = 'SELECT Id, ARC_Is_PT_Pivot__c, ARC_DateOfService__c, ARC_DOSTo__c, ARC_Claim__r.ARC_PriorAuthorizationCase__c, ARC_Claim__r.ARC_PriorAuthorizationCase__r.ARC_PT_Visits_Used__c, ARC_Claim__r.ARC_PriorAuthorizationCase__r.Base_Source_System_Id__c, ARC_Claim__r.ARC_ParticipantPolicyParticipant__r.PrimaryParticipantContact.vlocity_ins__Age__c, RecordType.DeveloperName, Status, AdjustedAmount, ARC_PrimaryPaid__c, ARC_Copay__c, ARC_Coinsurance__c, ARC_Deductible__c, ARC_MBRLiability__c, ARC_Medical_Visit_Reason__c, ARC_Pre_Existing_Condition__c, ARC_Tobacco__c, ARC_Claim__r.ARC_MemberBenefitPlanCode__c, ARC_Claim__r.ARC_ParticipantPolicyParticipant__r.PrimaryParticipantContact.AccountId, ARC_Claim__r.ARC_ParticipantPolicyParticipant__c, ARC_Claim__r.PolicyNumberId,'
                + ' (SELECT Id FROM Claim_Reason_Codes__r),'
                + ' (SELECT Id, ARC_ParticipantAggregator__r.ARC_Aggregator__c, ARC_ParticipantAggregator__r.ARC_Aggregator__r.ARC_Code__c,  ARC_ParticipantAggregator__r.ARC_ConsumedValue__c, ARC_ConsumedValue__c, ARC_AMCS_amount__c, ARC_PreExistingCond__c, ARC_Tobacco__c, ARC_ShareAMCS__c, ARC_Medical_Visit__c FROM SMB_Item_Payments__r)' 
                + ' FROM ClaimCoveragePaymentDetail ';

            // Add the WHERE clause dynamically based on the size of ccpdIds
            String whereClause = (ccpdIds.isEmpty()) ? 'WHERE ARC_Claim__c = :claimId ' : 'WHERE Id IN :ccpdIds ';
            // Construct the final query string with LIMIT
            String fullQuery = baseQuery + whereClause + 'LIMIT 3000';
            Map<String, Object> bindMap = new Map<String, Object>{'claimId' => claim.Id, 'ccpdIds' => ccpdIds};

            // Execute the query
            smb_items = Database.queryWithBinds(fullQuery, bindMap, AccessLevel.SYSTEM_MODE);

            if (smb_items.size() == 0)
                return false;

            memberAge = (Integer)smb_items[0].ARC_Claim__r.ARC_ParticipantPolicyParticipant__r.PrimaryParticipantContact.vlocity_ins__Age__c;
            productCode = smb_items[0].ARC_Claim__r.ARC_MemberBenefitPlanCode__c;

            String claim_year_of_service = claim.ARC_DOSTo__c?.year() + '';

            List<ARC_ParticipantAggregator__c> participant_aggregators = [
                SELECT
                    Id,
                    ARC_ConsumedValue__c,
                    ARC_Aggregator__r.ARC_Code__c,
                    ARC_Aggregator__r.ARC_Member__c,
                    ARC_Aggregator__c,
                    ARC_Aggregator__r.ARC_NextAvailabilityDate__c,
                    ARC_Aggregator__r.ARC_CurrentValue__c
                FROM ARC_ParticipantAggregator__c
                WHERE
                    ARC_Policy__c = :smb_items[0].ARC_Claim__r.PolicyNumberId
                    AND ARC_PolicyParticipant__c = :smb_items[0].ARC_Claim__r.ARC_ParticipantPolicyParticipant__c
                    AND (
                        ARC_Aggregator__r.ARC_Year__c = :claim_year_of_service
                        OR ARC_Aggregator__r.ARC_Year__c = NULL
                    )
                LIMIT 1000
            ];

            Double shinglesVaccineValue;
            Map<String, ARC_ParticipantAggregator__c> participant_aggregator_by_code = new Map<String, ARC_ParticipantAggregator__c>();
            for (ARC_ParticipantAggregator__c participant_aggregator : participant_aggregators) {
                participant_aggregator_by_code.put(participant_aggregator.ARC_Aggregator__r.ARC_Code__c, participant_aggregator);
                if (participant_aggregator_by_code.containsKey('SHINVAC__c')) {
                    shinglesVaccineValue = participant_aggregator_by_code.get('SHINVAC__c').ARC_Aggregator__r.ARC_CurrentValue__c;
                }
            }

            // DELETE REASON CODES AND CHANGE STATUS FROM LINE ITEM
            List<ClaimCoveragePaymentDetail> PTItemsToReset = new List<ClaimCoveragePaymentDetail>();
            Boolean resetPhysicalTherapyItems = false;
            for (ClaimCoveragePaymentDetail smb_item : smb_items) {
                // flag for resetting Physical Therapy items
                if(smb_item.ARC_Medical_Visit_Reason__c == 'PhysicalTherapy'){
                    PTItemsToReset.add(smb_item);
                    resetPhysicalTherapyItems = true;
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
                    if (smb_item.ARC_Claim__r.ARC_MemberBenefitPlanCode__c != null && smb_item.ARC_Claim__r.ARC_MemberBenefitPlanCode__c.contains('Access10K'))
                        smb_item.ARC_Tobacco__c = 0;
                }

                for (ClaimPaymentSummary smb_item_payment : smb_item.SMB_Item_Payments__r) {
                    // IF THE PAYMENT SUMMARY IS FROM PREVIOUS MODEL == CONTINUE
                    if (smb_item_payment.ARC_ParticipantAggregator__c == null)
                        continue;

                    aggIds.add(smb_item_payment.ARC_ParticipantAggregator__r.ARC_Aggregator__c);
                            
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
                        if (smb_item_payment.ARC_ParticipantAggregator__r.ARC_Aggregator__r.ARC_Code__c == 'SHINVAC__c') {
                            shinglesVaccineValue -= smb_item_payment.ARC_ConsumedValue__c;
                        }
                }
                pSummaryList.addAll(smb_item.SMB_Item_Payments__r);
                rCodeList.addAll(smb_item.Claim_Reason_Codes__r);
            }

            // UPDATE AGGREGATORS
            for (ARC_Aggregator__c agg : [SELECT Id, ARC_Code__c,ARC_NextAvailabilityDate__c FROM ARC_Aggregator__c WHERE Id IN :aggIds AND ARC_NextAvailabilityDate__c != null]) {
                aggregatorsToUpdate.add(setNextAvailabilityDate(agg, claim.ARC_DOSTo__c, memberAge, productCode, action));
            }
            if (shinglesVaccineValue == 0) {
                ARC_Aggregator__c shinglesVaccineAgg = new ARC_Aggregator__c();
                shinglesVaccineAgg.Id = participant_aggregator_by_code.get('SHINVAC__c').ARC_Aggregator__c;
                shinglesVaccineAgg.ARC_LimitValue__c = 0;
                aggregatorsToUpdate.add(shinglesVaccineAgg);
            }
            List<Case> authsToUpdate = new List<Case>(); 
            if(!PTItemsToReset.isEmpty()){
                // UPDATE AUTH CASE
                Map<String, Object> uncommitPTInputMap = new Map<String, Object>(); 
                uncommitPTInputMap.put('smb_items', smb_items);
                uncommitPTInputMap.put('authCaseId', smb_items[0].ARC_Claim__r.ARC_PriorAuthorizationCase__c);
                uncommitPTInputMap.put('usedValue', smb_items[0].ARC_Claim__r.ARC_PriorAuthorizationCase__r.ARC_PT_Visits_Used__c);
                System.debug('uncommitPTInputMap: ' + uncommitPTInputMap);
                Map<String, Object> uncommitPTResponse = ARC_AuthCaseUtility.uncommitPTVisitsFromAuth(uncommitPTInputMap);
                System.debug('uncommitPTResponse: ' + uncommitPTResponse);
                if(uncommitPTResponse.containsKey('authsToUpdate')){
                Map<Id, Decimal> authVisitsMap = (Map<Id, Decimal>)uncommitPTResponse.get('authsToUpdate');
                smb_items = (List<ClaimCoveragePaymentDetail>)uncommitPTResponse.get('smb_items');
                authsToUpdate = [SELECT Id, ARC_PT_Visits_Used__c FROM Case WHERE Id IN :authVisitsMap.keySet() ];
                System.debug('authsToUpdate - before: ' + authsToUpdate);
                for(Case c : authsToUpdate){
                    c.ARC_PT_Visits_Used__c += authVisitsMap.get(c.Id);
                }
                System.debug('authsToUpdate - after: ' + authsToUpdate);
                    System.debug(' PROPAGATE JOB ');
    
                    System.enqueueJob(
                        new ARC_AuthCaseUtility.PTDeltaPropagationJob(authVisitsMap)
                    );
                }
            }


            // DML OPERATIONS
            if (action != 'adjust')
                update smb_items;
            if (!partAggs.isEmpty())
                update partAggs.values();
            if(!authsToUpdate.isEmpty())
                update authsToUpdate;
            delete pSummaryList;
            if (action != 'adjust')
                delete rCodeList;
            //if (partAggs.isEmpty())
            //    update participant_aggregators;
            if (!aggregatorsToUpdate.isEmpty()) update aggregatorsToUpdate;

            return true;
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('Error: ' + e.getMessage() + ' ' + e.getLineNumber());
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

    /////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// AUXILIARY METHODS ///////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////

    public static ARC_Aggregator__c setNextAvailabilityDate(ARC_Aggregator__c aggregator, Date DOS, Integer memberAge, String productCode, String action) {

        Integer factor = 1;
        if (action == 'void' || action == 'uncommit') factor = -1;
        else return aggregator; // only modify on void action
        Date baseDate = (action == 'void' || action == 'uncommit') ? aggregator.ARC_NextAvailabilityDate__c : DOS; 
        String aggCode = aggregator.ARC_Code__c;
        switch on aggCode {
            when 'PROSCRE__c' {
                aggregator.ARC_NextAvailabilityDate__c = baseDate.addYears(2*factor);
            }
            when 'MAMM__c' {
                if (memberAge >= 40 && memberAge <= 54)
                    aggregator.ARC_NextAvailabilityDate__c = baseDate.addYears(1*factor);
                else if (memberAge >= 55)
                    aggregator.ARC_NextAvailabilityDate__c = baseDate.addYears(2*factor);
            }
            when 'FLXSIG__c' {
                if (productCode.contains('Legacy'))
                    aggregator.ARC_NextAvailabilityDate__c = baseDate.addYears(4*factor);
                else if (memberAge >= 45)
                    aggregator.ARC_NextAvailabilityDate__c = baseDate.addYears(5*factor);
            }
            when 'CLON__c' {
                aggregator.ARC_NextAvailabilityDate__c = baseDate.addYears(10*factor);
            }
            when 'SSOPT__c' {
                aggregator.ARC_NextAvailabilityDate__c = baseDate.addYears(3*factor);
            }
            when 'CCS__c' {
                if (productCode.contains('Legacy'))
                    aggregator.ARC_NextAvailabilityDate__c = baseDate.addYears(2*factor);
                else if (memberAge >= 21 && memberAge <= 29)
                    aggregator.ARC_NextAvailabilityDate__c = baseDate.addYears(3*factor);
                else if (memberAge >= 30 && memberAge <= 65)
                    aggregator.ARC_NextAvailabilityDate__c = baseDate.addYears(5*factor);
            }
            when 'BOSCR__c', 'WOVIS__c' {
                aggregator.ARC_NextAvailabilityDate__c = baseDate.addYears(2*factor);
            }
            when else {
                // do nothing
            }
        }
        return aggregator;
    }

    /**
     * @Description: Given a list of periods of a member, validates if claim DOS is IN any of those periods and if in that specific period the plan has a specific aggregator (each list corresponds to one aggregator)
     */
    private static Boolean claimInCoveragePeriod (List<Map<String,Object>> coverageList, Date claimDOS) {
        Boolean claimInCoveragePeriod  = false;
        for (Map<String,Object> coveragePeriod : coverageList) {
            Map<String,Object> memberCoverageMap = coveragePeriod;
            if (memberCoverageMap.containsKey('UHSMProgram') && memberCoverageMap.get('UHSMProgram') != null && memberCoverageMap.get('UHSMProgram') == true) {
                Date coverageStartDate = memberCoverageMap.containsKey('dates') && memberCoverageMap.get('dates') != null ? (Date)((List<Object>)memberCoverageMap.get('dates'))[0] : null;
                Date coverageEndDate = memberCoverageMap.containsKey('dates') && memberCoverageMap.get('dates') != null ? (Date)((List<Object>)memberCoverageMap.get('dates'))[1] : null;
                claimInCoveragePeriod = coverageStartDate <= claimDOS && claimDOS <= coverageEndDate ? true : claimInCoveragePeriod;
            }
        }
        return claimInCoveragePeriod;
    }

    private static Boolean mustHaveAggregator (List<String> aggList, Date claimDOS) {
        Boolean mustHaveAggregator = false;
        for (String agg : aggList) {
            List<String> dates = agg.split('\\|\\|');
            System.debug(dates);
            Date startDate = Date.valueOf(dates[0]);
            Date endDate = Date.valueOf(dates[1]);
            if (startDate <= claimDOS && claimDOS <= endDate) {
                mustHaveAggregator = true;
            }
        }
        return mustHaveAggregator;
    }

    private static Boolean productHasExpectedAggregator(String productCode, String expectedAggregatorCode) {
        ARC_ProductAggregators__mdt aggValues = ARC_ProductAggregators__mdt.getInstance(productCode);
        return aggValues.get('IND_' + expectedAggregatorCode) != null;
    }
    
}