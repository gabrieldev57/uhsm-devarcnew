/**
 * @Description: DML class for Self Enrollment Flow operations.
 * This class handles all database operations for the self enrollment process.
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-10-17
 * @Version: 1.0
 */
global without sharing class ARC_SEDML {
    
    // Properties to store created record IDs
    public Id censusId { get; set; }
    public List<Id> personAccountsId { get; set; }
    public Id groupAccountId { get; set; }
    public List<Id> censusMembersId { get; set; }
    public Id contractId { get; set; }
    public List<Id> contractLineItem { get; set; }
    public List<Id> groupCensusMemberPlan { get; set; }
    public List<Id> externalInsurancePolicyId { get; set; }
    public List<Id> externalInsurancePolicyMemberId { get; set; }
    // public Id contractParticipantId { get; set; }
    public List<Id> contractParticipantIds { get; set; }
    // public Id chargentOrderId { get; set; }
    // public Id uwCaseId { get; set; }
    // public Id uwCaseMemberId { get; set; }
    // public Id hippaId { get; set; }
    // public Id medicalQuestionId { get; set; }
    
    public ARC_SEManager manager;
    public Map<String, Object> enrollmentInfo;

    /**
     * @Description: Main method to process enrollment DML operations
     * @param manager: ARC_SEManager instance containing mapped objects
     */
    public void processEnrollment(ARC_SEManager manager) {
        Savepoint sp = Database.setSavepoint();
        this.manager = manager;
        this.enrollmentInfo = manager.enrollmentInfo;
        try {
            System.debug('Starting DML operations for Self Enrollment');
            
            // Process each object in the correct order
            processGroupAccount();
            processCensus();
            processCensusMembers();
            processPersonAccount();
            processGuardianAccount();
            processContract();
            processContractLineItem();
            processGroupCensusMemberPlan();
            processCriticalCarePromotionDiscount();
            processExternalInsurancePolicy();
            processExternalInsurancePolicyMember();
            processContractParticipant();
            processChargentOrder();
            processUWCaseAndOnboarding();
            processHIPPA();
            processConsumerDrugs();
            processMedicalConditions();
            insertPolicy();
            qualifyLead();
            
            System.debug('DML operations completed successfully');
            
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('Exception while executing DML operations - changes will be rolled back: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    /**
     * @Description: Processes Census DML operations
     */
    private void processCensus() {
        try {
            System.debug('Processing Census DML');
            if (this.manager.census != null) {
                this.manager.census.vlocity_ins__GroupId__c = this.manager.groupAccount.Id;
                //ARC_PrimaryAccount__c
                Database.UpsertResult result = Database.upsert(this.manager.census, true);
                if (result.isSuccess()) {
                    this.censusId = result.getId();
                    System.debug('Census created/updated successfully: ' + this.censusId);
                } else {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error upserting census: ' + error.getMessage());
                    }
                    throw new DmlException('Failed to upsert census: ' + result.getErrors());
                }
            }
        } catch (Exception e) {
            System.debug('Error in processCensus: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString()); 
            throw e;
        }
    }
    
    /**
     * @Description: Processes Census Members DML operations
     */
    private void processCensusMembers() {
        try {
            System.debug('Processing Census DML');  
            if (!this.manager.memberIdToCensusMemberMap.isEmpty()) {
                this.censusMembersId = new List<Id>();
                for (String key : this.manager.memberIdToCensusMemberMap.keySet()) {
                    vlocity_ins__GroupCensusMember__c member = this.manager.memberIdToCensusMemberMap.get(key);
                    member.vlocity_ins__CensusId__c = this.manager.census.Id;
                }
                List<Database.UpsertResult> resultsCreate = Database.upsert(this.manager.memberIdToCensusMemberMap.values(), true);
                for (Database.UpsertResult result : resultsCreate) {
                    if (result.isSuccess()) {
                        System.debug('Census member created successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting census: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert census: ' + result.getErrors());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in processCensus: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString()); 
            throw e;
        }
    }
    
    /**
     * @Description: Processes Person Account DML operations
     */
    private void processPersonAccount() {
        try {
            System.debug('Processing Person Account DML');
            
            if (!this.manager.memberIdToAccountMap.isEmpty()) {
                for (String key : this.manager.memberIdToAccountMap.keySet()) {
                    Account personAccount = this.manager.memberIdToAccountMap.get(key);
                    System.debug('personAccount: ' + personAccount);
                    personAccount.ARC_Census__c = this.manager.census.Id;
                    personAccount.Census_Member__c = this.manager.memberIdToCensusMemberMap.get(key).Id;
                    personAccount.ARC_CensusMember__pc = this.manager.memberIdToCensusMemberMap.get(key).Id;
                }
                this.personAccountsId = new List<Id>();
                List<Database.UpsertResult> results = Database.upsert(this.manager.memberIdToAccountMap.values(), true);
                for (Database.UpsertResult result : results) {
                    if (result.isSuccess()) {
                        this.personAccountsId.add(result.getId());
                        System.debug('Person Account created/updated successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting person account: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert person account: ' + result.getErrors());
                    }
                }

                List<Account> personAccounts = [SELECT Id, PersonContactId FROM Account WHERE Id IN :this.personAccountsId];
                    
                System.debug('accounts retrieve: ' + personAccounts);
                for (Account personAccount : personAccounts) {
                    for (String key : this.manager.memberIdToAccountMap.keySet()) {
                        if (personAccount.Id == this.manager.memberIdToAccountMap.get(key).Id) {
                            this.manager.memberIdToPersonContactId.put(key, personAccount.PersonContactId);
                        }
                    }
                }
                updateRelatedCensus();
                updateRelatedCensusMembers();
            }
            
        } catch (Exception e) {
            System.debug('Error in processPersonAccount: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @Description: Processes Group Account DML operations
     */
    private void processGroupAccount() {
        try {
            System.debug('Processing Group Account DML');
            if (this.manager.groupAccount != null) {
                Database.UpsertResult result = Database.upsert(this.manager.groupAccount, true);
                if (result.isSuccess()) {
                    this.groupAccountId = result.getId();
                    System.debug('Group Account created/updated successfully: ' + this.groupAccountId);
                } else {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error upserting group account: ' + error.getMessage());
                    }
                    throw new DmlException('Failed to upsert group account: ' + result.getErrors());
                }
            }
        } catch (Exception e) {
            System.debug('Error in processGroupAccount: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    /**
     * @Description: Processes Group Account DML operations
     */
    private void processGuardianAccount() {
        try {
            System.debug('Processing Guardian Account DML');

            if (this.manager.guardianToInsert != null) {
                // Map group account
                Account guardian = this.manager.guardianToInsert;
                guardian.ARC_GroupAccount__c = this.groupAccountId;
                
                if (guardian != null) {
                    Database.UpsertResult result = Database.upsert(guardian, true);
                    if (result.isSuccess()) {
                        manager.guardianInserted = result.getId();
                        System.debug('Guardian Account created/updated successfully: ' + this.manager.guardianInserted);
                    } else {
                        for (Database.Error error : result.getErrors()) {
                        System.debug('Error upserting guardian account: ' + error.getMessage());
                        }
                    throw new DmlException('Failed to upsert guardian account: ' + result.getErrors());
                    }
                    
                    updateCensusFieldGuardian();
                }
            }
        } catch (Exception e) {
            System.debug('Error in processGuardianAccount: ' + e.getMessage());
            throw e;
        }
    }

    private void updateCensusFieldGuardian () {
        try {
            if (this.censusId !=null) {

                vlocity_ins__GroupCensus__c updatedCensus = new vlocity_ins__GroupCensus__c();
                updatedCensus.Id = this.censusId;
                updatedCensus.ARC_IsChildFamily__c = true;
                updatedCensus.ARC_GuardianAccount__c = this.manager.guardianInserted != null ? this.manager.guardianInserted : null;

                update updatedCensus;
            }
            
        } catch (Exception e) {
            System.debug('Error in updateCensusFieldGuardian: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Processes Contract DML operations
     */
    private void processContract() {
        try {
            System.debug('Processing Contract DML');
            if (this.manager.contract != null) {
                this.manager.contract.vlocity_ins__EnrollmentCensusId__c = this.manager.census.Id;
                this.manager.contract.AccountId = this.manager.groupAccount.Id;
                this.manager.contract.Account_Name_Text__c = this.manager.groupAccount.Name;
                this.manager.contract.ARC_Guardian__c = this.manager.guardianInserted;
                Database.UpsertResult result = Database.upsert(this.manager.contract, true);
                if (result.isSuccess()) {
                    this.contractId = result.getId();
                    manager.contractId = result.getId();
                    System.debug('Contract created successfully: ' + this.contractId);
                } else {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error inserting contract: ' + error.getMessage());
                    }
                    throw new DmlException('Failed to insert contract: ' + result.getErrors());
                }
            }
            
        } catch (Exception e) {
            System.debug('Error in processContract: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @Description: Processes Contract Line Item DML operations
     */
    private void processContractLineItem() {
        try {
            System.debug('Processing Contract Line Item DML');
            
            if (!this.manager.indexToParentCLIToInsert.isEmpty() && !this.manager.indexToChildCLIToInsert.isEmpty()) {
                Id contractId = this.manager.contract.Id;
                Id groupAccountId = this.manager.groupAccount.Id;
                for (String key : this.manager.indexToParentCLIToInsert.keySet()) {
                    vlocity_ins__ContractLineItem__c parentCLI = this.manager.indexToParentCLIToInsert.get(key);
                    parentCLI.vlocity_ins__ContractId__c = contractId;
                    parentCLI.vlocity_ins__AccountId__c = groupAccountId;
                    for (vlocity_ins__ContractLineItem__c childCLI : this.manager.indexToChildCLIToInsert.get(key)) {    
                        childCLI.vlocity_ins__ContractId__c = contractId;
                        childCLI.vlocity_ins__AccountId__c = groupAccountId;
                    }
                }
                this.contractLineItem = new List<Id>();
                Database.UpsertResult[] results = Database.upsert(this.manager.indexToParentCLIToInsert.values(), true);
                for (Database.UpsertResult result : results) {
                    if (result.isSuccess()) {
                        this.contractLineItem.add(result.getId());
                        System.debug('Parent Contract Line Item created successfully: ' + result.getId());
                    } 
                    else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error inserting parent contract line item: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to insert Parent Contract Line Item: ' + result.getErrors());
                    }
                }
                List<vlocity_ins__ContractLineItem__c> childCLIList = new List<vlocity_ins__ContractLineItem__c>();
                for (String key : this.manager.indexToChildCLIToInsert.keySet()) {
                    vlocity_ins__ContractLineItem__c parentCLI = this.manager.indexToParentCLIToInsert.get(key);
                    for (vlocity_ins__ContractLineItem__c childCLI : this.manager.indexToChildCLIToInsert.get(key)) {
                        childCLI.vlocity_ins__ParentItemId__c = parentCLI.Id;
                        childCLIList.add(childCLI);
                    }
                }
                Database.UpsertResult[] resultsChild = Database.upsert(childCLIList, true);
                for (Database.UpsertResult result : resultsChild) {
                    if (result.isSuccess()) {
                        this.contractLineItem.add(result.getId());
                        System.debug('Child Contract Line Item created successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error inserting child contract line item: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to insert Child Contract Line Item: ' + result.getErrors());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in processContractLineItem: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @Description: Processes Group Census Member Plan DML operations
     */
    private void processGroupCensusMemberPlan() {
        try {
            System.debug('Processing Group Census Member Plan DML');
            if (!this.manager.indexToParentCLIToInsert.isEmpty() && !this.manager.indexToMemberIds.isEmpty()) {
                List<vlocity_ins__GroupCensusMemberPlan__c> gcmpListToInsert = new List<vlocity_ins__GroupCensusMemberPlan__c> ();
                for (String key : this.manager.indexToParentCLIToInsert.keySet()) {
                    for (String memberId : this.manager.indexToMemberIds.get(key)) {
                        Id censusMemberId = this.manager.memberIdToCensusMemberMap.get(memberId).Id;
                        vlocity_ins__GroupCensusMemberPlan__c newGCMP = new vlocity_ins__GroupCensusMemberPlan__c();
                        newGCMP.Name = this.manager.indexToParentCLIToInsert.get(key).Name;
                        newGCMP.vlocity_ins__GroupCensusMemberId__c = censusMemberId;
                        newGCMP.vlocity_ins__ContractLineId__c = this.manager.indexToParentCLIToInsert.get(key).Id;
                        gcmpListToInsert.add(newGCMP);
                    }
                }
                this.groupCensusMemberPlan = new List<Id>();
                if (!gcmpListToInsert.isEmpty()) {
                    Database.UpsertResult[] results = Database.upsert(gcmpListToInsert, true);
                    for (Database.UpsertResult result : results) {
                        if (result.isSuccess()) {
                            this.groupCensusMemberPlan.add(result.getId());
                            System.debug('Group Census Member Plan created successfully: ' + result.getId());
                        } else {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error inserting Group Census Member Plan: ' + error.getMessage());
                            }
                            throw new DmlException('Failed to insert Group Census Member Plan: ' + result.getErrors());
                        }
                    }
                }

                this.groupCensusMemberPlan = new List<Id>();
                if (!gcmpListToInsert.isEmpty()) {
                    Database.UpsertResult[] results = Database.upsert(gcmpListToInsert, true);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results[i];
                        if (result.isSuccess()) {
                            this.groupCensusMemberPlan.add(result.getId());
                            System.debug('Group Census Member Plan created successfully: ' + result.getId());

                            // ── Bundle resolution ──────────────────────────────────────────
                            // gcmpListToInsert[i] was built from key + memberId; we need to
                            // match it back using the CLI name stored in the GCMP.
                            vlocity_ins__GroupCensusMemberPlan__c insertedGcmp = gcmpListToInsert[i];
                            String gcmpCliId = insertedGcmp.vlocity_ins__ContractLineId__c; // parent CLI Id

                            for (String memberId : this.manager.memberIdToCriticalCareBundle.keySet()) {
                                Map<String, String> bundleKeys = this.manager.memberIdToCriticalCareBundle.get(memberId);

                                for (String bundleType : bundleKeys.keySet()) { // 'SMART' or 'AIDD'
                                    String ancKey = bundleKeys.get(bundleType);
                                    vlocity_ins__ContractLineItem__c matchCli = this.manager.indexToParentCLIToInsert.get(ancKey);

                                    if (matchCli != null && matchCli.Id == gcmpCliId) {
                                        // Also verify this GCMP belongs to the right member
                                        Id expectedCensusMemberId = this.manager.memberIdToCensusMemberMap.get(memberId).Id;

                                        if (insertedGcmp.vlocity_ins__GroupCensusMemberId__c == expectedCensusMemberId) {

                                            if (!this.manager.memberIdToBundleGcmpIds.containsKey(memberId)) {
                                                this.manager.memberIdToBundleGcmpIds.put(memberId, new Map<String, Id>());
                                            }

                                            this.manager.memberIdToBundleGcmpIds.get(memberId).put(bundleType, result.getId());

                                            System.debug('Bundle GCMP resolved | member: ' + memberId + ' | type: ' + bundleType + ' | GCMP Id: ' + result.getId());
                                        }
                                    }
                                }
                            }
                            // ── End bundle resolution 

                        } else {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error inserting Group Census Member Plan: ' + error.getMessage());
                            }
                            throw new DmlException('Failed to insert Group Census Member Plan: ' + result.getErrors());
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Exception while upserting group census member plans: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    /**
     * @Description: Links resolved GCMP IDs (SMART / AIDD) to the 
     * ARC_PromotionDiscount__c records created for the Critical Care bundle,
     * then upserts them.
     */
    private void processCriticalCarePromotionDiscount() {
        try {
            System.debug('Processing Critical Care Promotion Discount DML');

            if (this.manager.memberIdToCriticalCareBundle.isEmpty()) return;

            List<ARC_PromotionDiscount__c> bundleDiscounts = new List<ARC_PromotionDiscount__c>();
            ARC_PromotionCode__c ancillaryCode = [
                SELECT Id
                FROM ARC_PromotionCode__c
                WHERE Name = 'Ancillary Discount'
                LIMIT 1
            ];
            Id ancillaryDiscountRT = Schema.SObjectType.ARC_PromotionDiscount__c
                        .getRecordTypeInfosByDeveloperName()
                        .get('Ancillary_Discount')
                        .getRecordTypeId();

            for (String memberId : this.manager.memberIdToCriticalCareBundle.keySet()) {

                // Locate the matching PromotionDiscount shell created in the mapper.
                // Convention: bundle discounts have ARC_SMART__c == null at this point;
                // promo-code discounts may or may not have it. We match by position:
                // mapCriticalCarePromotionDiscount() appends one record per bundle member,
                // so we use the memberIdToCriticalCareBundle keyset order to find them.
                ARC_PromotionDiscount__c targetPd = null;
                for (ARC_PromotionDiscount__c pd : this.manager.promotionDiscountToInsert) {
                    if (pd.ARC_SMART__c == null && pd.ARC_AIDD__c == null && pd.ARC_Contract__c == null && pd.RecordTypeId == ancillaryDiscountRT) {
                        targetPd = pd;
                        break;
                    }
                }

                if (targetPd == null) {
                    System.debug('No matching PromotionDiscount shell found for member: ' + memberId);
                    continue;
                }

                Map<String, Id> gcmpIds = this.manager.memberIdToBundleGcmpIds.get(memberId);
                if (gcmpIds == null || !gcmpIds.containsKey('SMART') || !gcmpIds.containsKey('AIDD')) {
                    System.debug('Incomplete GCMP IDs for bundle member: ' + memberId + ' | resolved: ' + gcmpIds);
                    continue;
                }

                targetPd.ARC_Contract__c = this.manager.contract.Id;
                targetPd.ARC_SMART__c = gcmpIds.get('SMART');
                targetPd.ARC_AIDD__c = gcmpIds.get('AIDD');
                targetPd.ARC_PromoCode__c = ancillaryCode.Id;

                bundleDiscounts.add(targetPd);
            }

            if (!bundleDiscounts.isEmpty()) {
                List<Database.UpsertResult> results = Database.upsert(bundleDiscounts, true);
                for (Database.UpsertResult result : results) {
                    if (result.isSuccess()) {
                        System.debug('Critical Care PromotionDiscount upserted: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting Critical Care PromotionDiscount: ' + error.getMessage());
                        }
                        throw new DmlException(
                            'Failed to upsert Critical Care PromotionDiscount: ' + result.getErrors());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in processCriticalCarePromotionDiscount: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @Description: Processes ARC External Insurance Policy Member DML operations
     */
    private void processExternalInsurancePolicy() {
        try {
            System.debug('Processing ARC External Insurance Policy DML');
            this.externalInsurancePolicyId = new List<Id>();

            if (!this.manager.externalPoliciesToInsert.isEmpty()) {
                List<Database.UpsertResult> resultsUpdate = Database.upsert(this.manager.externalPoliciesToInsert.values(), true);
                for (Database.UpsertResult result : resultsUpdate) {
                    if (result.isSuccess()) {
                        this.externalInsurancePolicyId.add(result.getId());
                        System.debug('External Insurance Policy created/updated successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting external insurance policy: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert external insurance policy: ' + result.getErrors());
                    }
                }
            }            
        } catch (Exception e) {
            System.debug('Error in processExternalInsurancePolicy: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Processes ARC External Insurance Policy Member DML operations
     */
    private void processExternalInsurancePolicyMember() {
        try {
            System.debug('Processing ARC External Insurance Policy Member DML');

            if (!this.manager.policyKeyToMemberIds.isEmpty()) {
                this.externalInsurancePolicyMemberId = new List<Id>();
                // List<ARC_ExternalInsurancePolicyMember__c> externalPolicyMembersToInsert = new List<ARC_ExternalInsurancePolicyMember__c>();
                for (String policyKey : manager.policyKeyToMemberIds.keySet()) {
                    for (String memberId : manager.policyKeyToMemberIds.get(policyKey)) {
                        ARC_ExternalInsurancePolicyMember__c externalPolicyMember = new ARC_ExternalInsurancePolicyMember__c ();
                        externalPolicyMember.ARC_ExternalInsurancePolicy__c = manager.externalPoliciesToInsert.get(policyKey).Id;
                        externalPolicyMember.ARC_PersonAccount__c = manager.memberIdToAccountMap.get(memberId).Id;
                        externalPolicyMember.ARC_CensusMember__c = manager.memberIdToCensusMemberMap.get(memberId).Id;
                        // Add external policy member to list to insert
                        manager.externalPolicyMembersToInsert.add(externalPolicyMember);
                        System.debug('Ext Policy Member of ' + memberId + ': ' + externalPolicyMember);
                    }
                }

                if (!this.manager.externalPolicyMembersToInsert.isEmpty() && this.manager.externalPolicyMembersToInsert.size() > 0) {
                    List<Database.UpsertResult> resultsUpdate = Database.upsert(this.manager.externalPolicyMembersToInsert, true);
                    for (Database.UpsertResult result : resultsUpdate) {
                        if (result.isSuccess()) {
                            this.externalInsurancePolicyMemberId.add(result.getId());
                            System.debug('External Insurance Policy Member created/updated successfully: ' + result.getId());
                        } else {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error upserting external insurance policy member: ' + error.getMessage());
                            }
                            throw new DmlException('Failed to upsert external insurance policy member: ' + result.getErrors());
                        }
                    }
                }
            }
            

            
        } catch (Exception e) {
            System.debug('Error in processExternalInsurancePolicyMember: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Processes Contract Participant DML operations
     */
    private void processContractParticipant() {
        try {
            System.debug('Processing Contract Participant DML');
            
            if (!this.manager.memberIdtoContractParticipantMap.isEmpty()) {
                for(String key : this.manager.memberIdtoContractParticipantMap.keySet()){
                    ARC_ContractParticipant__c contractParticipantTemp = this.manager.memberIdtoContractParticipantMap.get(key);
                    contractParticipantTemp.ARC_Contract__c = this.contractId;
                    contractParticipantTemp.ARC_PersonAccount__c = this.manager.memberIdToAccountMap.get(key).Id;
                }
                this.contractParticipantIds = new List<Id>();
                List<Database.UpsertResult> results = Database.upsert(this.manager.memberIdtoContractParticipantMap.values(), true);

                for (Database.UpsertResult result : results) {
                    if(result.isSuccess()) {
                        this.contractParticipantIds.add(result.getId());
                        System.debug('Contract Participant created/updated successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting contract participant: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert contract participant: ' + result.getErrors());
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug('Error in processContractParticipant: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Processes Chargent Order DML operations
     */
    private void processChargentOrder() {
        try {
            System.debug('Processing Chargent Order DML');

            ChargentOrders__ChargentOrder__c appFeeOrder = this.manager.appFeeOrderToInsert;
            appFeeOrder.ARC_Contract__c = this.contractId;
            appFeeOrder.ChargentOrders__Account__c = this.groupAccountId;

            if (appFeeOrder != null) {
                Database.UpsertResult result = Database.upsert(appFeeOrder, true);
                if (result.isSuccess()) {
                    manager.appFeeOrderInserted = result.getId();
                    System.debug('Chargent Order created/updated successfully: ' + this.manager.appFeeOrderInserted);
                } else {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error upserting chargent order: ' + error.getMessage());
                    }
                    throw new DmlException('Failed to upsert chargent order: ' + result.getErrors());
                }
            }
        } catch (Exception e) {
            System.debug('Error in processChargentOrder: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Processes HIPPA DML operations
     */
    private void processHIPPA() {
        try {
            System.debug('Processing HIPPA DML');
            List<ARC_HipaaAuthorization__c> listOfHipaaToInsert = new List<ARC_HipaaAuthorization__c>();
 
            // 1. hipaaCensusMember
            if (!this.manager.hipaaCensusMember.isEmpty()) {
 
                for(String key : this.manager.hipaaCensusMember.keySet()) {
 
                    ARC_HipaaAuthorization__c hipaa = this.manager.hipaaCensusMember.get(key);
                    hipaa.ARC_Census__c = this.manager.census.Id;
                    hipaa.ARC_AuthorizedMember__c = this.manager.memberIdToCensusMemberMap.get(key).Id;
                    listOfHipaaToInsert.add(hipaa);
                }
 
                // listOfHipaaToInsert.addAll(this.manager.hipaaCensusMember.values());
            } // end of hipaaCensusMember
 
            // 2. hipaaThirdParty
            if (!this.manager.hipaaThirdParty.isEmpty()) {
                // Update the AccountId in the Contacts to insert
                for(String contactKey : this.manager.hippaExternalContact.keySet()) {
                    Contact newContact = this.manager.hippaExternalContact.get(contactKey);
                    newContact.AccountId = this.manager.groupAccount.Id;
                }
 
                // Insert the Contacts
                List<Database.UpsertResult> resultsContact = Database.upsert(this.manager.hippaExternalContact.values(), true);
                for (Database.UpsertResult result : resultsContact) {
                    if(result.isSuccess()) {
                        System.debug('HIPAA Contact created/updated successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting HIPAA Contact: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert HIPAA Contact: ' + result.getErrors());
                    }
                }
 
                for(String key : this.manager.hipaaThirdParty.keySet()) {
                    ARC_HipaaAuthorization__c hipaa = this.manager.hipaaThirdParty.get(key);
                    hipaa.ARC_Census__c = this.manager.census.Id;
                    // hipaa.ARC_AuthorizedMember__c = this.manager.memberIdToCensusMemberMap.get(key).Id;
                    hipaa.ARC_ExternalPersonAuthorized__c = this.manager.hippaExternalContact.get(key).Id;
                    listOfHipaaToInsert.add(hipaa);
                }
 
                // listOfHipaaToInsert.addAll(this.manager.hipaaThirdParty.values());
            } // end of hipaaThirdParty
 
            // 3. hipaaLegalGuardian
            if (!this.manager.hipaaLegalGuardian.isEmpty()) {
                Account guardian = [SELECT PersonContactId FROM Account WHERE Id =: this.manager.guardianInserted LIMIT 1][0];
                Id personContactId = guardian.PersonContactId;
 
                for(String key : this.manager.hipaaLegalGuardian.keySet()) {
 
                    ARC_HipaaAuthorization__c hipaa = this.manager.hipaaLegalGuardian.get(key);
                    hipaa.ARC_Census__c = this.manager.census.Id;
                    hipaa.ARC_ExternalPersonAuthorized__c = personContactId;
                    listOfHipaaToInsert.add(hipaa);
                }
 
                // listOfHipaaToInsert.addAll(this.manager.hipaaLegalGuardian.values());
            }
 
            // Insert the HIPPA records
            if (!listOfHipaaToInsert.isEmpty()) {
                List<Database.UpsertResult> results = Database.upsert(listOfHipaaToInsert, true);
                for (Database.UpsertResult result : results) {
                    if (result.isSuccess()) {
                        System.debug('HIPAA created/updated successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting HIPAA records: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert HIPAA records: ' + result.getErrors());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in processHIPPA: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Processes Medical Questions DML operations
     */
    private void processMedicalConditions() {
        try {
            System.debug('Processing Medical Conditions DML');

            if (!this.manager.medicalConditionsByMemberToInsert.isEmpty()) {
                for (String memberId : this.manager.medicalConditionsByMemberToInsert.keySet()) {

                    List<ARC_MedicalConditions__c> medicalConditions = this.manager.medicalConditionsByMemberToInsert.get(memberId);
                    for (ARC_MedicalConditions__c medicalCondition : medicalConditions) {
                        medicalCondition.ARC_CensusMember__c = this.manager.memberIdToCensusMemberMap.get(memberId).Id;
                        medicalCondition.ARC_PersonAccount__c = this.manager.memberIdToAccountMap.get(memberId).Id;
                    }
                }
                // Flatten nested lists before upsert
                List<ARC_MedicalConditions__c> allMedicalConditions = new List<ARC_MedicalConditions__c>();
                for (List<ARC_MedicalConditions__c> mcList : this.manager.medicalConditionsByMemberToInsert.values()) {
                    allMedicalConditions.addAll(mcList);
                }
                if (!allMedicalConditions.isEmpty()) {
                    List<Database.UpsertResult> resultsCreate = Database.upsert(allMedicalConditions, true);
                    for (Database.UpsertResult result : resultsCreate) {
                        if (result.isSuccess()) {
                            System.debug('Medical condition created successfully: ' + result.getId());
                        } else {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error upserting medical condition: ' + error.getMessage());
                            }
                            throw new DmlException('Failed to upsert medical condition: ' + result.getErrors());
                        }
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug('Error in processMedicalConditions: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Processes Consumer Drugs DML operations
     */
    private void processConsumerDrugs() {
        try {
            System.debug('Processing Consumer Drugs DML');

            if (!this.manager.consumerDrugsByMemberToInsert.isEmpty()) {
                for (String memberId : this.manager.consumerDrugsByMemberToInsert.keySet()) {
                    List<vlocity_ins__ConsumerDrug__c> consumerDrugs = this.manager.consumerDrugsByMemberToInsert.get(memberId);
                    for (vlocity_ins__ConsumerDrug__c consumerDrug : consumerDrugs) {
                        consumerDrug.ARC_CensusMember__c = this.manager.memberIdToCensusMemberMap.get(memberId).Id;
                        consumerDrug.ARC_PersonAccount__c = this.manager.memberIdToAccountMap.get(memberId).Id;
                    }
                }
                // Flatten nested lists before upsert
                List<vlocity_ins__ConsumerDrug__c> allConsumerDrugs = new List<vlocity_ins__ConsumerDrug__c>();
                for (List<vlocity_ins__ConsumerDrug__c> cdList : this.manager.consumerDrugsByMemberToInsert.values()) {
                    allConsumerDrugs.addAll(cdList);
                }
                if (!allConsumerDrugs.isEmpty()) {
                    List<Database.UpsertResult> resultsCreate = Database.upsert(allConsumerDrugs, true);
                    for (Database.UpsertResult result : resultsCreate) {
                        if (result.isSuccess()) {
                            System.debug('Consumer drug created successfully: ' + result.getId());
                        } else {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error upserting consumer drug: ' + error.getMessage());
                            }
                            throw new DmlException('Failed to upsert consumer drug: ' + result.getErrors());
                        }
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug('Error in processConsumerDrugs: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Processes Policy DML operations
     */
    private void insertPolicy() {
        try {
            Map<String, Object> inputMapRemove = new Map<String, Object>();
            Map<String, Object> outMapRemove = new Map<String, Object>();
            inputMapRemove.put('contractId', this.contractId);
            inputMapRemove.put('contactIdToBeneficiaries', this.manager.contactIdToBeneficiaries);
            ARC_PolicyCreation.createAllPolicyRecords(inputMapRemove, outMapRemove);
        } catch (Exception e) {
            System.debug('Exception while inserting policy: ' + e.getMessage() + e.getStackTraceString() );
            throw e;
        }
    }

    /**
     * @Description: Processes underwriting case records.
     * This method:
     * 1. Creates underwriting cases
     * 2. Links cases to contracts and members
     * 3. Sets case status and details
     * 4. Manages case relationships
     * 
     * @throws Exception If case operations fail
     */
    private void processUWCaseAndOnboarding() {
        try {
            Case uwCase = this.manager.uwCase;
            Id contractId = this.manager.contract.Id;
            String primaryMemberId = getPrimaryMemberId();
            uwCase.ARC_Contract__c = contractId;
            uwCase.AccountId = this.manager.groupAccount.Id;
            uwCase.ARC_CensusMember__c = this.manager.memberIdToCensusMemberMap.get(primaryMemberId).Id;
            uwCase.ContactId = this.manager.memberIdToPersonContactId.get(primaryMemberId);
            uwCase.ARC_PersonAccount__c = this.manager.memberIdToAccountMap.get(primaryMemberId).Id;
            
            Case onboardingCase = this.manager.onboardingCase;
            if(this.manager.onboardingCase != null){
                onboardingCase.ARC_PersonAccount__c = this.manager.memberIdToAccountMap.get(primaryMemberId).Id;
            }


            for (String memberId : this.manager.uwCaseMembers.keySet()) {
                ARC_UnderwritingCaseMember__c uwCaseMember = this.manager.uwCaseMembers.get(memberId);
                uwCaseMember.ARC_Member__c = this.manager.memberIdToCensusMemberMap.get(memberId).Id;
                uwCaseMember.ARC_Contract__c = contractId;
                uwCaseMember.ARC_PersonAccount__c = this.manager.memberIdToAccountMap.get(memberId).Id;
            }

            String jsonUWCase = JSON.serialize(this.manager.uwCase);
            String jsonUWCaseMembers = JSON.serialize(this.manager.uwCaseMembers);
            String jsonOnboardingCase = this.manager.onboardingCase != null? JSON.serialize(this.manager.onboardingCase): '';
            Id appFeeOrderInserted = this.manager.appFeeOrderInserted;

            // Serialize ARC_PromotionDiscount__c
            String jsonPromotionDiscount = '';
            if (!manager.promotionDiscountToInsert.isEmpty()) {
                List<ARC_PromotionDiscount__c> promoCodeOnly = new List<ARC_PromotionDiscount__c>();
                for (ARC_PromotionDiscount__c pd : manager.promotionDiscountToInsert) {
                    if (pd.ARC_SMART__c == null && pd.ARC_AIDD__c == null) {
                        promoCodeOnly.add(pd);
                    }
                }
                if (!promoCodeOnly.isEmpty()) {
                    jsonPromotionDiscount = JSON.serialize(promoCodeOnly);
                }
            }

            // Call the future method with all necessary data
            handleUWCaseAndMembersFuture(contractId, appFeeOrderInserted, jsonUWCase, jsonUWCaseMembers, jsonPromotionDiscount,jsonOnboardingCase);
        } catch (Exception e) {
            System.debug('Exception while preparing UW case for future processing: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    @future
    public static void handleUWCaseAndMembersFuture(Id contractId, Id appFeeOrderInserted, String jsonUWCase, String jsonUWCaseMembers, String jsonPromotionDiscount, String jsonOnboardingCase) {
        try {
            // Create UW Case
            Case uwCase = (Case)JSON.deserialize(jsonUWCase, Case.class);
            Database.UpsertResult resultCase = Database.upsert(uwCase, true);
            if (resultCase.isSuccess()) {
                System.debug('UW Case created successfully: ' + resultCase.getId());
            } else {
                for (Database.Error error : resultCase.getErrors()) {
                    System.debug('Error upserting UW case in future context: ' + error.getMessage());
                }
                throw new DmlException('Failed to create UW Case: ' + resultCase.getErrors());
            }
            
            // Create Onboarding Case
            if(jsonOnboardingCase != null && jsonOnboardingCase != ''){
                Case onboardingCase = (Case)JSON.deserialize(jsonOnboardingCase, Case.class);
        
                Database.UpsertResult resultOnboardingCase = Database.upsert(onboardingCase, true);
                if (resultOnboardingCase.isSuccess()) {
                    System.debug('Onboarding Case created successfully: ' + resultOnboardingCase.getId());
                } else {
                    for (Database.Error error : resultOnboardingCase.getErrors()) {
                        System.debug('Error upserting Onboarding case in future context: ' + error.getMessage());
                    }
                    throw new DmlException('Failed to create Onboarding Case: ' + resultOnboardingCase.getErrors());
                }
            }


            // Update the contract with the new case and orders
            if (contractId != null) {
                Contract contractToUpdate = new Contract();

                contractToUpdate.Status = 'Awaiting Signature';
                contractToUpdate.Id = contractId;
                if (appFeeOrderInserted != null) contractToUpdate.ARC_AppFeeOrder__c = appFeeOrderInserted;
                //if (recurringOrderId != null) contractToUpdate.ARC_RecurringMonthlyOrder__c = recurringOrderId;
                if (uwCase.Id != null) contractToUpdate.ARC_Case__c = uwCase.Id;

                Database.UpsertResult contractResult = Database.upsert(contractToUpdate, true);
                    if (contractResult.isSuccess()) {
                        System.debug('Successfully inserted UW Case Member: ' + contractResult.getId());
                    } else {
                        for (Database.Error error : contractResult.getErrors()) {
                            System.debug('Error inserting UW Case Member in future context: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to create UW Case Members: ' + contractResult.getErrors());
                    }
            }

            // Create UW Case Members if we have a successful case creation
            if (uwCase.Id != null) {
                Map<String, ARC_UnderwritingCaseMember__c> uwCaseMembers = (Map<String, ARC_UnderwritingCaseMember__c>)JSON.deserialize(jsonUWCaseMembers, Map<String, ARC_UnderwritingCaseMember__c>.class);
                
                for (ARC_UnderwritingCaseMember__c uwCaseMember : uwCaseMembers.values()) {
                    uwCaseMember.ARC_UnderwritingCase__c = uwCase.Id;
                }

                if (!uwCaseMembers.isEmpty()) {
                    Database.UpsertResult[] memberResults = Database.upsert(uwCaseMembers.values(), true);
                    for (Database.UpsertResult memberResult : memberResults) {
                        if (memberResult.isSuccess()) {
                            System.debug('Successfully inserted UW Case Member: ' + memberResult.getId());
                        } else {
                            for (Database.Error error : memberResult.getErrors()) {
                                System.debug('Error inserting UW Case Member in future context: ' + error.getMessage());
                            }
                            throw new DmlException('Failed to create UW Case Members: ' + memberResult.getErrors());
                        }
                    }
                }
            }

            // Promotion Discount
            List<ARC_PromotionDiscount__c> promotionDiscounts = new List<ARC_PromotionDiscount__c>();
            if(jsonPromotionDiscount != null && jsonPromotionDiscount != ''){
                //Deserialize the promotion discount
                promotionDiscounts = (List<ARC_PromotionDiscount__c>)JSON.deserialize(jsonPromotionDiscount, List<ARC_PromotionDiscount__c>.class);
            }
            if (!promotionDiscounts.isEmpty()) {    
                try {
    
                    for(ARC_PromotionDiscount__c d : promotionDiscounts) {
                        d.ARC_Contract__c = contractId;
                    }
    
                    Database.UpsertResult[] resultsPD   = Database.upsert(promotionDiscounts, true);//All or none = true
                    for (Integer i = 0; i < resultsPD.size(); i++) {
                        Database.UpsertResult result = resultsPD[i];
                        if (!result.isSuccess()) {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error promotion discount: ' + error.getMessage());
                            }
                        } else {                                              
                            System.debug('Promotion discount upserted successfully');                
                        }
                    }
                } catch (Exception e) {
                    System.debug('Exception while upserting promotion discount: ' + e.getMessage() + e.getStackTraceString());
                    throw e;
                }
            }
        } catch (Exception e) {
            System.debug('Exception while processing UW case and members in future context: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
        }
    }

    /*******************************************************************
    * @MethodName         :   qualifyLead
    * @Description        :   Moves the status of the Lead Source related Lead to Qualified. 
    ********************************************************************/
    public void qualifyLead() {             
        String primaryMemberId = getPrimaryMemberId();
        Map<String, Object> generalInformation = (Map<String, Object>)this.enrollmentInfo.get('generalInformation');
        Id leadId = generalInformation.containsKey('leadId') ? (Id)generalInformation.get('leadId') : null;        
        if(leadId != null){
            Lead leadRecord = new Lead();
            leadRecord.Id = leadId;
            leadRecord.Status = 'Qualified';
            leadRecord.Account__c = this.manager.memberIdToAccountMap.get(primaryMemberId).Id;
            try{
                update leadRecord;
                System.debug('Lead Updated');
            }
            catch(Exception e){
                System.debug('Exception in ARC_SEDML.qualifyLead: '+e.getMessage());
            }
        }
    }

    ///////////////////////
    // Auxiliary Methods //
    ///////////////////////
    
    /**
     * @Description: Updates census member records with contact IDs.
     * This method:
     * 1. Links census members to contacts
     * 2. Updates member information
     * 3. Maintains record relationships
     * 4. Ensures data consistency
     * 
     * @throws Exception If member casesUWToInsert fails
     */
    private void updateRelatedCensusMembers() {
        try {
            if (!this.manager.memberIdToCensusMemberMap.isEmpty()) {
                String primaryMemberId = getPrimaryMemberId();
                Id primaryCensusMemberId = this.manager.memberIdToCensusMemberMap.get(primaryMemberId).Id;
                for (String key : this.manager.memberIdToCensusMemberMap.keySet()) {
                    vlocity_ins__GroupCensusMember__c member = this.manager.memberIdToCensusMemberMap.get(key);
                    member.vlocity_ins__ContactId__c = this.manager.memberIdToPersonContactId.get(key);

                    // Verify if this Census Member has Beneficiaries
                    if (this.manager.memberIdToBeneficiaries.containsKey(key)) {
                        Id contactId = this.manager.memberIdToPersonContactId.get(key);
                        Object beneficiaries = this.manager.memberIdToBeneficiaries.get(key);
                       this.manager.contactIdToBeneficiaries.put(contactId, beneficiaries);
                    }

                    if (key != primaryMemberId) {
                        member.vlocity_ins__RelatedCensusMemberId__c = primaryCensusMemberId;
                    }
                    //member.vlocity_ins__SocialSecurityNumber__c = ((vlocity_ins__GroupCensusMember__c)manager.gcmFakeIdToInsertNB.get(fakeId)).vlocity_ins__SocialSecurityNumber__c;
                }
                Database.UpsertResult[] resultsCreate = Database.upsert(this.manager.memberIdToCensusMemberMap.values(), true);
                for (Database.UpsertResult result : resultsCreate) {
                    if (result.isSuccess()) {
                        System.debug('Census member created successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            this.censusMembersId.add(result.getId());
                            System.debug('Error upserting census: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert census: ' + result.getErrors());
                    }
                }

                // Map Census Member Contact Id to Beneficiaries

            }
        } catch (Exception e) {
            System.debug('Error in updateRelatedCensusMembers: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    private void updateRelatedCensus() {
        try {
            if (this.manager.census != null) {
                String primaryMemberId = getPrimaryMemberId();
                Account primaryAccount = this.manager.memberIdToAccountMap.get(primaryMemberId);
                this.manager.census.ARC_PrimaryAccount__c = primaryAccount.Id;
                Database.UpsertResult result = Database.upsert(this.manager.census, true);
                if (result.isSuccess()) {
                    System.debug('Census updated successfully: ' + result.getId());
                } else {
                    for (Database.Error error : result.getErrors()) {
                        this.censusMembersId.add(result.getId());
                        System.debug('Error upserting census: ' + error.getMessage());
                    }
                    throw new DmlException('Failed to upsert census: ' + result.getErrors());
                }
            }
        } catch (Exception e) {
            System.debug('Error in updateRelatedCensus: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    private String getPrimaryMemberId() {
        List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
        for (Object memberInfo_obj : members) {
            Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
            if ((String)memberInfo.get('role') == 'Primary') {
                return (String)memberInfo.get('memberExternalId');
            }
        }
        return null;
    }
}