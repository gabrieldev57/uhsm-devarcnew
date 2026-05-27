/**
 * @description Batch class that automatically creates renewal InsurancePolicy records for eligible members
 *              who did not complete the enrollment flow by the OE End Date.
 *
 *              Only creates policies where the member's plan and price have not changed (verified via
 *              ARC_AutoRenewalPricingService). Full policy structure is cloned from the member's active
 *              policy under the current activated contract.
 *
 *
 * @author lucas.benero@arcsona.com
 * @date 2026-05-06
 */
global without sharing class ARC_AutoRenewalPolicyBatch
        implements Database.Batchable<SObject>, Schedulable, Database.Stateful {

    // Supplied by caller (flow or scheduler)
    private Id contractId;

    // Stateful: populated once in start(), consumed in each execute()
    private Id renewalContractId;
    private Id groupAccountId;
    private Date effectiveDate;
    private Id medicalProductId;
    private Id recordTypeId;
    private Map<Id, InsurancePolicy> activePolicyByAccountId = new Map<Id, InsurancePolicy>();

    global ARC_AutoRenewalPolicyBatch() {}

    global ARC_AutoRenewalPolicyBatch(Id contractId) {
        this.contractId = contractId;
    }

    // -------------------------------------------------------------------------
    // Invocable entry point — called by ARC_AutoRenewalPolicyTrigger flow
    // -------------------------------------------------------------------------
    @InvocableMethod(
        label='Start Auto Renewal Policy Batch'
        description='Starts the ARC_AutoRenewalPolicyBatch for one Contract. Called from the OE End Date scheduled flow on Contract.'
        category='Renewal'
    )
    public static void startBatch(List<Id> contractIds) {
        if (contractIds == null || contractIds.isEmpty()) return;
        for (Id cId : contractIds) {
            Database.executeBatch(new ARC_AutoRenewalPolicyBatch(cId), 1);
        }
    }

    // -------------------------------------------------------------------------
    // Schedulable — dispatches one per-contract batch for each renewal due today
    // -------------------------------------------------------------------------
    global void execute(SchedulableContext sc) {
        List<Contract> contracts = [
            SELECT Id
            FROM Contract
            WHERE ARC_OEEndDate__c = TODAY
              AND RecordType.DeveloperName = 'ARC_SmallGroup'
              AND ARC_ContractReason__c INCLUDES ('Renewal')
        ];
        for (Contract c : contracts) {
            Database.executeBatch(new ARC_AutoRenewalPolicyBatch(c.Id), 1);
        }
    }

    // -------------------------------------------------------------------------
    // Batchable start — runs once per batch job; populates stateful context and
    //                   returns the filtered set of eligible Account records.
    //                   Returns an empty QueryLocator on any guard failure so
    //                   execute() is never called.
    // -------------------------------------------------------------------------
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (contractId == null) {
            System.debug('ARC_AutoRenewalPolicyBatch: no contractId supplied, aborting.');
            return Database.getQueryLocator('SELECT Id FROM Account WHERE Id = null');
        }

        // --- Load the renewal contract ---
        List<Contract> renewalContracts = [
            SELECT Id, AccountId, ARC_EffectiveDate__c
            FROM Contract
            WHERE Id = :contractId
              AND ARC_OEEndDate__c = TODAY
              AND RecordType.DeveloperName = 'ARC_SmallGroup'
              AND ARC_ContractReason__c INCLUDES ('Renewal')
        ];
        if (renewalContracts.isEmpty()) {
            System.debug('ARC_AutoRenewalPolicyBatch: contract ' + contractId + ' not found or not eligible today.');
            return Database.getQueryLocator('SELECT Id FROM Account WHERE Id = null');
        }
        Contract renewalContract = renewalContracts[0];
        renewalContractId = renewalContract.Id;
        groupAccountId    = renewalContract.AccountId;
        effectiveDate     = renewalContract.ARC_EffectiveDate__c;

        // --- Resolve the employer's currently activated contract ---
        List<Contract> activatedContracts = [
            SELECT Id
            FROM Contract
            WHERE AccountId = :groupAccountId
              AND Status = 'Activated'
            LIMIT 1
        ];
        if (activatedContracts.isEmpty()) {
            System.debug('ARC_AutoRenewalPolicyBatch: no Activated contract for AccountId=' + groupAccountId);
            return Database.getQueryLocator('SELECT Id FROM Account WHERE Id = null');
        }
        Id activatedContractId = activatedContracts[0].Id;

        // --- AC1: Eligible member accounts ---
        List<Account> eligibleAccounts = [
            SELECT Id
            FROM Account
            WHERE ARC_GroupAccount__c = :groupAccountId
              AND (IsActive = true OR (ARC_CoverageWaived__c = false AND ARC_TerminationDate__c = null))
        ];
        if (eligibleAccounts.isEmpty()) {
            return Database.getQueryLocator('SELECT Id FROM Account WHERE Id = null');
        }

        Set<Id> eligibleIds = new Set<Id>();
        for (Account a : eligibleAccounts) {
            eligibleIds.add(a.Id);
        }

        // --- AC2: Remove members already having a policy in the renewal contract ---
        List<InsurancePolicy> existingRenewalPolicies = [
            SELECT NameInsuredId
            FROM InsurancePolicy
            WHERE ARC_Contract__c = :renewalContractId
              AND NameInsuredId IN :eligibleIds
        ];
        for (InsurancePolicy p : existingRenewalPolicies) {
            eligibleIds.remove(p.NameInsuredId);
        }
        if (eligibleIds.isEmpty()) {
            return Database.getQueryLocator('SELECT Id FROM Account WHERE Id = null');
        }

        // --- AC3: Keep only members with an Activated policy in the current contract ---
        //     Subquery coverages and participants now
        List<InsurancePolicy> activePolicies = [
            SELECT Id, NameInsuredId,
                   EmployeeContribution, EmployerContribution, ARC_IndividualPrice__c,ARC_TotalPremiumAmount__c,
                   OriginalPolicyId, PriorPolicyId, RenewedFromPolicyId, ARC_SpinnedFromPolicy__c,
                   (SELECT Id, CoverageName, vlocity_ins_fsc__Product2Id__c,
                           ARC_ParentProduct__c, ARC_EmployeeContribution__c,
                           ARC_EmployerContribution__c, ARC_UnitPrice__c, ARC_Reason__c,ARC_CoveragePrimaryMember__c
                    FROM InsurancePolicyCoverages),
                   (SELECT Id, PrimaryParticipantContactId, Role
                    FROM InsurancePolicyParticipants)
            FROM InsurancePolicy
            WHERE ARC_Contract__c = :activatedContractId
              AND Status = 'Activated'
              AND NameInsuredId IN :eligibleIds
        ];
        if (activePolicies.isEmpty()) {
            return Database.getQueryLocator('SELECT Id FROM Account WHERE Id = null');
        }

        for (InsurancePolicy p : activePolicies) {
            activePolicyByAccountId.put(p.NameInsuredId, p);
        }
        eligibleIds = activePolicyByAccountId.keySet().clone();

        // --- AC4: Keep only members whose coverage products exist in renewal CLIs ---
        List<vlocity_ins__ContractLineItem__c> renewalCLIs = [
            SELECT Id, vlocity_ins__Product2Id__c,
                   vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                   vlocity_ins__Product2Id__r.vlocity_ins__RecordTypeName__c
            FROM vlocity_ins__ContractLineItem__c
            WHERE vlocity_ins__ContractId__c = :renewalContractId
        ];

        Set<Id> renewalCliProductIds = new Set<Id>();
        for (vlocity_ins__ContractLineItem__c cli : renewalCLIs) {
            if (cli.vlocity_ins__Product2Id__c != null) {
                renewalCliProductIds.add(cli.vlocity_ins__Product2Id__c);
                if (medicalProductId == null
                    && cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c == 'Medical'
                    && cli.vlocity_ins__Product2Id__r.vlocity_ins__RecordTypeName__c == 'Product') {
                    medicalProductId = cli.vlocity_ins__Product2Id__c;
                }
            }
        }

        // Resolve ProductCodes for renewal CLIs — product IDs differ across catalog versions
        Set<String> renewalProductCodes = new Set<String>();
        for (Product2 p : [SELECT ProductCode FROM Product2 WHERE Id IN :renewalCliProductIds]) {
            if (p.ProductCode != null) renewalProductCodes.add(p.ProductCode);
        }

        // Collect all active coverage product IDs across eligible members for a single bulk query
        Set<Id> activeCovProductIds = new Set<Id>();
        for (Id accountId : eligibleIds) {
            for (InsurancePolicyCoverage cov : activePolicyByAccountId.get(accountId).InsurancePolicyCoverages) {
                if (cov.ARC_ParentProduct__c == null && cov.vlocity_ins_fsc__Product2Id__c != null) {
                    activeCovProductIds.add(cov.vlocity_ins_fsc__Product2Id__c);
                }
            }
        }
        Map<Id, String> productCodeById = new Map<Id, String>();
        for (Product2 p : [SELECT Id, ProductCode FROM Product2 WHERE Id IN :activeCovProductIds]) {
            productCodeById.put(p.Id, p.ProductCode);
        }

        Set<Id> planEligibleIds = new Set<Id>();
        for (Id accountId : eligibleIds) {
            InsurancePolicy ap = activePolicyByAccountId.get(accountId);
            Boolean plansAvailable = true;
            for (InsurancePolicyCoverage cov : ap.InsurancePolicyCoverages) {
                if (cov.ARC_ParentProduct__c != null) continue;
                if (cov.vlocity_ins_fsc__Product2Id__c != null) {
                    String covProductCode = productCodeById.get(cov.vlocity_ins_fsc__Product2Id__c);
                    if (covProductCode == null || !renewalProductCodes.contains(covProductCode)) {
                        plansAvailable = false;
                        break;
                    }
                }
            }
            if (plansAvailable) {
                planEligibleIds.add(accountId);
            } else {
                activePolicyByAccountId.remove(accountId);
            }
        }
        if (planEligibleIds.isEmpty()) {
            return Database.getQueryLocator('SELECT Id FROM Account WHERE Id = null');
        }

        // Cache the RecordType Id once — reused across all execute() calls
        recordTypeId = InsurancePolicy.sObjectType.getDescribe()
            .getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();

        // Return eligible member accounts — one per execute() at batch size=1
        return Database.getQueryLocator([
            SELECT Id, Name
            FROM Account
            WHERE Id IN :planEligibleIds
        ]);
    }

    // -------------------------------------------------------------------------
    // Batchable execute — one Account per invocation (batch size=1)
    //                     Calls pricesMatch() exactly once per transaction:
    //                     ~8 SOQLs total, within governor limits for any group size.
    // -------------------------------------------------------------------------
    global void execute(Database.BatchableContext bc, List<SObject> accounts) {
        Account member   = (Account) accounts[0];
        Id accountId     = member.Id;

        InsurancePolicy activePolicy = activePolicyByAccountId.get(accountId);
        if (activePolicy == null) {
            System.debug('ARC_AutoRenewalPolicyBatch: no active policy in context for Account=' + accountId);
            return;
        }

        // --- AC6: Price comparison — bounded SOQL count ---
        if (!ARC_AutoRenewalPricingService.pricesMatch(accountId, activePolicy, renewalContractId)) {
            System.debug('ARC_AutoRenewalPolicyBatch: price mismatch for Account=' + accountId + ', skipping.');
            return;
        }

        // --- AC7: Create new InsurancePolicy ---
        InsurancePolicy newPolicy = new InsurancePolicy();
        newPolicy.Name = 'ShopAndEnroll Policy';
        newPolicy.PolicyName                 = member.Name + ' - Family';
        newPolicy.Status                     = 'Awaiting Activation';
        newPolicy.ARC_Reason__c              = 'Renewal';
        newPolicy.ARC_PolicyEffectiveDate__c = effectiveDate;
        newPolicy.ARC_Contract__c            = renewalContractId;
        newPolicy.ARC_GroupAccount__c        = groupAccountId;
        newPolicy.NameInsuredId              = accountId;
        newPolicy.RecordTypeId               = recordTypeId;
        newPolicy.ProductId                  = medicalProductId;
        newPolicy.EmployeeContribution       = activePolicy.EmployeeContribution;
        newPolicy.EmployerContribution       = activePolicy.EmployerContribution;
        newPolicy.ARC_IndividualPrice__c     = activePolicy.ARC_IndividualPrice__c;
        newPolicy.PriorPolicyId              = activePolicy.Id;
        newPolicy.OriginalPolicyId           = activePolicy.OriginalPolicyId != null
                                                ? activePolicy.OriginalPolicyId
                                                : activePolicy.Id;
        newPolicy.RenewedFromPolicyId        = activePolicy.Id;
        newPolicy.ARC_SpinnedFromPolicy__c   = activePolicy.ARC_SpinnedFromPolicy__c;
        newPolicy.IsRenewedPolicy = true;
        insert newPolicy;

        // --- Clone coverages ---
        List<InsurancePolicyCoverage> coveragesToInsert = new List<InsurancePolicyCoverage>();
        Map<Id, InsurancePolicyCoverage> newCoverageByActiveId = new Map<Id, InsurancePolicyCoverage>();

        for (InsurancePolicyCoverage activeCov : activePolicy.InsurancePolicyCoverages) {
            InsurancePolicyCoverage newCov = new InsurancePolicyCoverage();
            newCov.InsurancePolicyId              = newPolicy.Id;
            newCov.CoverageName                   = activeCov.CoverageName;
            newCov.vlocity_ins_fsc__Product2Id__c = activeCov.vlocity_ins_fsc__Product2Id__c;
            newCov.ARC_ParentProduct__c           = activeCov.ARC_ParentProduct__c;
            newCov.ARC_EmployeeContribution__c    = activeCov.ARC_EmployeeContribution__c;
            newCov.ARC_EmployerContribution__c    = activeCov.ARC_EmployerContribution__c;
            newCov.ARC_UnitPrice__c               = activeCov.ARC_UnitPrice__c;
            newCov.ARC_Reason__c                  = 'New Policy';
            newCov.ARC_CoveragePrimaryMember__c   = activeCov.ARC_CoveragePrimaryMember__c;
            coveragesToInsert.add(newCov);
            newCoverageByActiveId.put(activeCov.Id, newCov);
        }
        if (!coveragesToInsert.isEmpty()) insert coveragesToInsert;

        // --- Clone participants ---
        List<InsurancePolicyParticipant> participantsToInsert = new List<InsurancePolicyParticipant>();
        Map<Id, InsurancePolicyParticipant> newParticipantByActiveId = new Map<Id, InsurancePolicyParticipant>();

        for (InsurancePolicyParticipant activePart : activePolicy.InsurancePolicyParticipants) {
            InsurancePolicyParticipant newPart = new InsurancePolicyParticipant();
            newPart.InsurancePolicyId           = newPolicy.Id;
            newPart.PrimaryParticipantContactId = activePart.PrimaryParticipantContactId;
            newPart.Role                        = activePart.Role;
            newPart.ARC_StartDate__c            = effectiveDate;
            participantsToInsert.add(newPart);
            newParticipantByActiveId.put(activePart.Id, newPart);
        }
        if (!participantsToInsert.isEmpty()) insert participantsToInsert;

        // --- Clone ARC_CoverageParticipant__c ---
        if (!newCoverageByActiveId.isEmpty()) {
            List<ARC_CoverageParticipant__c> activeCovParts = [
                SELECT Id, ARC_PolicyCoverage__c, ARC_PolicyParticipant__c,
                       ARC_CoverageRole__c, ARC_Policy__c
                FROM ARC_CoverageParticipant__c
                WHERE ARC_PolicyCoverage__c IN :newCoverageByActiveId.keySet()
            ];

            List<ARC_CoverageParticipant__c> covPartsToInsert = new List<ARC_CoverageParticipant__c>();
            for (ARC_CoverageParticipant__c acp : activeCovParts) {
                InsurancePolicyCoverage    newCov  = newCoverageByActiveId.get(acp.ARC_PolicyCoverage__c);
                InsurancePolicyParticipant newPart = newParticipantByActiveId.get(acp.ARC_PolicyParticipant__c);
                if (newCov == null || newPart == null) continue;

                ARC_CoverageParticipant__c newCp = new ARC_CoverageParticipant__c();
                newCp.ARC_PolicyCoverage__c    = newCov.Id;
                newCp.ARC_PolicyParticipant__c = newPart.Id;
                newCp.ARC_CoverageRole__c      = acp.ARC_CoverageRole__c;
                newCp.ARC_Policy__c            = newPolicy.Id;
                covPartsToInsert.add(newCp);
            }
            if (!covPartsToInsert.isEmpty()) insert covPartsToInsert;
        }
    }

    global void finish(Database.BatchableContext bc) {}
}