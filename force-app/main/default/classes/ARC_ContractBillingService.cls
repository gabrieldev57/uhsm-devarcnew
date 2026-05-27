/**
 * @description Service class for contract billing operations 
 * @author lucas.benero@arcsona.com
 * @last modified date 2026-04-13 by Franca Fattoruso
 */
public without sharing class ARC_ContractBillingService {

    /**
     * @description Bulk version of evaluatePolicyEligibilityForContract.
     *              Processes all contracts in a single set of queries — avoids SOQL loops.
     * @param contractIds Set of Contract IDs to re-evaluate
     */
    public static void evaluatePolicyEligibilityForContracts(Set<Id> contractIds) {
        if (contractIds == null || contractIds.isEmpty()) return;

        Map<Id, Contract> contractMap = new Map<Id, Contract>([
            SELECT Id, ARC_NextInvoiceCoverageStart__c, ARC_CoveragePaidThrough__c, ARC_EffectiveDate__c
            FROM Contract WHERE Id IN :contractIds
        ]);

        Map<Id, Date> invoiceAnchorByContract = new Map<Id, Date>();
        Map<Id, Date> paymentAnchorByContract = new Map<Id, Date>();
        for (Contract c : contractMap.values()) {
            invoiceAnchorByContract.put(c.Id, c.ARC_NextInvoiceCoverageStart__c);
            paymentAnchorByContract.put(c.Id, c.ARC_CoveragePaidThrough__c != null
                ? c.ARC_CoveragePaidThrough__c.addDays(1) : c.ARC_EffectiveDate__c);
        }

        Map<String, List<InsurancePolicy>> policiesByEmployee = new Map<String, List<InsurancePolicy>>();
        Map<String, Id> employeeToContract = new Map<String, Id>();

        for (InsurancePolicy policy : [
            SELECT Id, Status, ARC_Contract__c, NameInsuredId,
                   ARC_PolicyEffectiveDate__c, ARC_PolicyExpirationDate__c,
                   ARC_NextInvoiceEligible__c, ARC_NextPaymentEligible__c
            FROM InsurancePolicy
            WHERE ARC_Contract__c IN :contractIds AND NameInsuredId != null
        ]) {
            String empKey = String.valueOf(policy.ARC_Contract__c) + '_' + String.valueOf(policy.NameInsuredId);
            if (!policiesByEmployee.containsKey(empKey)) {
                policiesByEmployee.put(empKey, new List<InsurancePolicy>());
                employeeToContract.put(empKey, policy.ARC_Contract__c);
            }
            policiesByEmployee.get(empKey).add(policy);
        }

        List<InsurancePolicy> policiesToUpdate = new List<InsurancePolicy>();
        for (String empKey : policiesByEmployee.keySet()) {
            Id cId = employeeToContract.get(empKey);
            policiesToUpdate.addAll(evaluateEligibilityForEmployee(
                policiesByEmployee.get(empKey),
                invoiceAnchorByContract.get(cId),
                paymentAnchorByContract.get(cId)
            ));
        }
        if (!policiesToUpdate.isEmpty()) update policiesToUpdate;
    }

    /**
     * @description BULK version of evaluateAdjustmentsForPolicies.
     *              Processes ALL employees across ALL contracts in a single set of queries,
     *              avoiding the SOQL-in-loop problem when many policies change in one transaction.
     * @param policyIdsByEmployee  Map of contractId_employeeId → List<policyId> (built in handler)
     * @param oldPolicyMap         Map of old policy versions from trigger context
     */
    public static void evaluateAdjustmentsForPoliciesBulk(
        Map<String, List<Id>> policyIdsByEmployee,
        Map<Id, InsurancePolicy> oldPolicyMap
    ) {
        if (policyIdsByEmployee == null || policyIdsByEmployee.isEmpty()) return;

        Set<Id> allChangedPolicyIds = new Set<Id>();
        for (List<Id> ids : policyIdsByEmployee.values()) allChangedPolicyIds.addAll(ids);

        Map<Id, InsurancePolicy> changedPolicyMap = new Map<Id, InsurancePolicy>([
            SELECT Id, Status, NameInsuredId, ARC_Contract__c, Name,
                   ARC_PolicyEffectiveDate__c, ARC_PolicyExpirationDate__c, ARC_TotalPremiumAmount__c
            FROM InsurancePolicy WHERE Id IN :allChangedPolicyIds
        ]);

        Map<String, Id>   contractByKey    = new Map<String, Id>();
        Map<String, Id>   employeeByKey    = new Map<String, Id>();
        Map<String, Date> impactStartByKey = new Map<String, Date>();
        Set<Id> contractIds = new Set<Id>();

        for (String empKey : policyIdsByEmployee.keySet()) {
            List<Id> pIds = policyIdsByEmployee.get(empKey);
            Date impactStart = null;
            Id contractId = null;
            Id employeeId = null;

            for (Id pId : pIds) {
                InsurancePolicy newPolicy = changedPolicyMap.get(pId);
                if (newPolicy == null) continue;
                contractId = newPolicy.ARC_Contract__c;
                employeeId = newPolicy.NameInsuredId;
                InsurancePolicy oldPolicy = oldPolicyMap != null ? oldPolicyMap.get(pId) : null;
                Date policyImpactStart = calculateImpactStart(oldPolicy, newPolicy);
                if (policyImpactStart != null && (impactStart == null || policyImpactStart < impactStart)) {
                    impactStart = policyImpactStart;
                }
            }

            if (contractId == null) continue;
            contractByKey.put(empKey, contractId);
            employeeByKey.put(empKey, employeeId);
            impactStartByKey.put(empKey, impactStart);
            contractIds.add(contractId);
        }

        if (contractIds.isEmpty()) return;

        Map<Id, Contract> contractMap = new Map<Id, Contract>([
            SELECT Id, ARC_CoverageInvoicedThrough__c, ARC_PaymentFrequency__c
            FROM Contract WHERE Id IN :contractIds
        ]);

        Map<String, List<InsurancePolicy>> allEmployeePoliciesMap = new Map<String, List<InsurancePolicy>>();
        Set<Id> allEmployeePolicyIds = new Set<Id>();

        for (InsurancePolicy policy : [
            SELECT Id, Status, Name, ARC_Contract__c, NameInsuredId,
                   ARC_PolicyEffectiveDate__c, ARC_PolicyExpirationDate__c, ARC_TotalPremiumAmount__c
            FROM InsurancePolicy
            WHERE ARC_Contract__c IN :contractIds AND NameInsuredId != null
        ]) {
            allEmployeePolicyIds.add(policy.Id);
            String key = String.valueOf(policy.ARC_Contract__c) + '_' + String.valueOf(policy.NameInsuredId);
            if (!allEmployeePoliciesMap.containsKey(key)) {
                allEmployeePoliciesMap.put(key, new List<InsurancePolicy>());
            }
            allEmployeePoliciesMap.get(key).add(policy);
        }

        Map<Id, Date> contractImpactStart = new Map<Id, Date>();
        Map<Id, Date> contractImpactEnd   = new Map<Id, Date>();

        for (String empKey : contractByKey.keySet()) {
            Id cId = contractByKey.get(empKey);
            Contract contract = contractMap.get(cId);
            if (contract == null || contract.ARC_CoverageInvoicedThrough__c == null) continue;
            Date empImpactStart = impactStartByKey.get(empKey);
            if (empImpactStart == null) continue;
            Date currentStart = contractImpactStart.get(cId);
            if (currentStart == null || empImpactStart < currentStart) contractImpactStart.put(cId, empImpactStart);
            contractImpactEnd.put(cId, contract.ARC_CoverageInvoicedThrough__c);
        }

        Set<Id> allEmployeeIds = new Set<Id>(employeeByKey.values());
        Map<Id, Map<String, Decimal>> billedAmountsByEmployee = new Map<Id, Map<String, Decimal>>();

        Date globalStart = null;
        Date globalEnd   = null;
        for (Id cId : contractImpactStart.keySet()) {
            Date s = contractImpactStart.get(cId);
            Date e = contractImpactEnd.get(cId);
            if (globalStart == null || s < globalStart) globalStart = s;
            if (globalEnd == null || e > globalEnd) globalEnd = e;
        }

        if (globalStart != null && globalEnd != null && !allEmployeeIds.isEmpty()) {
            // Include both Coverage and Adjustment ILIs so that policies "charged" via
            // adjustment line items (not direct coverage) are correctly credited when voided.
            for (ARC_InvoiceLineItem__c item : [
                SELECT Id, ARC_Employee__c, ARC_Policy__c, ARC_PolicyCoverage__c,
                       ARC_CoverageAmount__c, ARC_CoverageDateFrom__c, ARC_CoverageDateTo__c
                FROM ARC_InvoiceLineItem__c
                WHERE ARC_Employee__c IN :allEmployeeIds
                  AND ARC_CoverageDateFrom__c <= :globalEnd
                  AND ARC_CoverageDateTo__c   >= :globalStart
                  AND ARC_Type__c IN ('Coverage', 'Adjustment')
            ]) {
                if (!billedAmountsByEmployee.containsKey(item.ARC_Employee__c)) {
                    billedAmountsByEmployee.put(item.ARC_Employee__c, new Map<String, Decimal>());
                }
                String key = String.valueOf(item.ARC_Policy__c) + '_' + String.valueOf(item.ARC_PolicyCoverage__c) + '_' +
                             String.valueOf(item.ARC_CoverageDateFrom__c) + '_' + String.valueOf(item.ARC_CoverageDateTo__c);
                Decimal current = billedAmountsByEmployee.get(item.ARC_Employee__c).get(key);
                Decimal itemAmount = item.ARC_CoverageAmount__c != null ? item.ARC_CoverageAmount__c : 0;
                billedAmountsByEmployee.get(item.ARC_Employee__c).put(key, current != null ? current + itemAmount : itemAmount);
            }
        }

        Map<String, ARC_Adjustment__c> existingAdjustmentsMap = new Map<String, ARC_Adjustment__c>();
        Map<Id, List<InsurancePolicyCoverage>> policyCoveragesMap = new Map<Id, List<InsurancePolicyCoverage>>();
        if (!allEmployeePolicyIds.isEmpty() && globalStart != null && globalEnd != null) {
            existingAdjustmentsMap = buildExistingAdjustmentsMap(allEmployeePolicyIds, globalStart, globalEnd);
            policyCoveragesMap = buildPolicyCoveragesMap(allEmployeePolicyIds);
        }

        List<ARC_Adjustment__c> adjustmentsToInsert = new List<ARC_Adjustment__c>();
        List<ARC_Adjustment__c> adjustmentsToUpdate = new List<ARC_Adjustment__c>();
        List<ARC_Adjustment__c> adjustmentsToVoid   = new List<ARC_Adjustment__c>();

        for (String empKey : policyIdsByEmployee.keySet()) {
            Id cId = contractByKey.get(empKey);
            Id employeeId = employeeByKey.get(empKey);
            if (cId == null || employeeId == null) continue;

            Contract contract = contractMap.get(cId);
            if (contract == null || contract.ARC_CoverageInvoicedThrough__c == null) continue;

            Date impactStart = impactStartByKey.get(empKey);
            Date impactEnd   = contract.ARC_CoverageInvoicedThrough__c;
            if (impactStart == null || impactStart > impactEnd) continue;

            List<InsurancePolicy> employeePolicies = allEmployeePoliciesMap.get(empKey);
            if (employeePolicies == null || employeePolicies.isEmpty()) continue;

            Map<String, Decimal> billedAmounts = billedAmountsByEmployee.get(employeeId);
            if (billedAmounts == null) billedAmounts = new Map<String, Decimal>();

            List<BillingPeriod> periods = buildBillingPeriods(impactStart, impactEnd, contract.ARC_PaymentFrequency__c);
            InsurancePolicy firstChangedPolicy = changedPolicyMap.get(policyIdsByEmployee.get(empKey)[0]);

            reconcileAdjustmentsForPeriods(
                employeePolicies, policyCoveragesMap, billedAmounts, periods,
                firstChangedPolicy, allChangedPolicyIds,
                existingAdjustmentsMap, adjustmentsToInsert, adjustmentsToUpdate, adjustmentsToVoid,
                oldPolicyMap
            );
        }

        commitAdjustmentChanges(adjustmentsToInsert, adjustmentsToUpdate, adjustmentsToVoid);
    }

    /**
     * @description Bulk version of recalculateNextBillAmount.
     * @param contractIds Set of Contract IDs to recalculate
     */
    public static void recalculateNextBillAmount(Set<Id> contractIds) {
        if (contractIds == null || contractIds.isEmpty()) return;

        Map<Id, Contract> contractMap = new Map<Id, Contract>([
            SELECT Id, ARC_CoveragePaidThrough__c, ARC_PaymentFrequency__c, ARC_EffectiveDate__c
            FROM Contract WHERE Id IN :contractIds
        ]);

        Map<Id, Date> nextPeriodStartByContract = new Map<Id, Date>();
        for (Contract c : contractMap.values()) {
            Date nextPeriodStart = c.ARC_CoveragePaidThrough__c != null
                ? c.ARC_CoveragePaidThrough__c.addDays(1) : c.ARC_EffectiveDate__c;
            if (nextPeriodStart != null) nextPeriodStartByContract.put(c.Id, nextPeriodStart);
        }
        if (nextPeriodStartByContract.isEmpty()) return;

        Map<Id, ARC_Invoice__c> pendingInvoiceByContract = new Map<Id, ARC_Invoice__c>();
        for (ARC_Invoice__c inv : [
            SELECT Id, ARC_Contract__c, ARC_AmountDue__c, ARC_CoverageDateFrom__c
            FROM ARC_Invoice__c
            WHERE ARC_Contract__c IN :nextPeriodStartByContract.keySet()
            ORDER BY ARC_Contract__c, ARC_CoverageDateFrom__c ASC
        ]) {
            if (!pendingInvoiceByContract.containsKey(inv.ARC_Contract__c)) {
                Date nextStart = nextPeriodStartByContract.get(inv.ARC_Contract__c);
                if (nextStart != null && inv.ARC_CoverageDateFrom__c >= nextStart) {
                    pendingInvoiceByContract.put(inv.ARC_Contract__c, inv);
                }
            }
        }

        Set<Id> contractsNeedingCalc = new Set<Id>();
        for (Id cId : nextPeriodStartByContract.keySet()) {
            if (!pendingInvoiceByContract.containsKey(cId)) contractsNeedingCalc.add(cId);
        }

        Map<Id, Decimal> calculatedAmountByContract = new Map<Id, Decimal>();
        Map<Id, Date[]>  nextPeriodByContract        = new Map<Id, Date[]>();
        Map<Id, Set<Id>> allPolicyIdsByContract      = new Map<Id, Set<Id>>();

        if (!contractsNeedingCalc.isEmpty()) {
            for (Id cId : contractsNeedingCalc) {
                Date nextStart = nextPeriodStartByContract.get(cId);
                List<BillingPeriod> periods = buildBillingPeriods(nextStart, nextStart, contractMap.get(cId).ARC_PaymentFrequency__c);
                if (!periods.isEmpty()) nextPeriodByContract.put(cId, new Date[]{ periods[0].coverageFrom, periods[0].coverageTo });
                calculatedAmountByContract.put(cId, 0);
                allPolicyIdsByContract.put(cId, new Set<Id>());
            }

            for (InsurancePolicy policy : [
                SELECT Id, ARC_Contract__c, ARC_TotalPremiumAmount__c
                FROM InsurancePolicy
                WHERE ARC_Contract__c IN :contractsNeedingCalc AND ARC_NextPaymentEligible__c = true
            ]) {
                Decimal current = calculatedAmountByContract.get(policy.ARC_Contract__c);
                calculatedAmountByContract.put(policy.ARC_Contract__c,
                    current + (policy.ARC_TotalPremiumAmount__c != null ? policy.ARC_TotalPremiumAmount__c : 0));
            }

            for (InsurancePolicy policy : [
                SELECT Id, ARC_Contract__c FROM InsurancePolicy WHERE ARC_Contract__c IN :contractsNeedingCalc
            ]) {
                allPolicyIdsByContract.get(policy.ARC_Contract__c).add(policy.Id);
            }

            Set<Id> allPolicyIds = new Set<Id>();
            for (Set<Id> pids : allPolicyIdsByContract.values()) allPolicyIds.addAll(pids);

            if (!allPolicyIds.isEmpty()) {
                Map<Id, Id> contractByPolicy = new Map<Id, Id>();
                for (Id cId : allPolicyIdsByContract.keySet()) {
                    for (Id pId : allPolicyIdsByContract.get(cId)) contractByPolicy.put(pId, cId);
                }

                for (ARC_Adjustment__c adj : [
                    SELECT Id, ARC_Amount__c, ARC_Policy__c, ARC_CoverageDateFrom__c, ARC_CoverageDateTo__c
                    FROM ARC_Adjustment__c
                    WHERE ARC_Policy__c IN :allPolicyIds AND ARC_Status__c = 'Open'
                ]) {
                    Id cId = contractByPolicy.get(adj.ARC_Policy__c);
                    if (cId == null) continue;
                    if (adj.ARC_Amount__c != null) {
                        Decimal current = calculatedAmountByContract.get(cId) ?? 0;
                        calculatedAmountByContract.put(cId, current + adj.ARC_Amount__c);
                    }
                }
            }
        }

        List<Contract> contractsToUpdate = new List<Contract>();
        for (Id cId : nextPeriodStartByContract.keySet()) {
            ARC_Invoice__c pendingInv = pendingInvoiceByContract.get(cId);
            Decimal nextBillAmount = pendingInv != null
                ? (pendingInv.ARC_AmountDue__c != null ? pendingInv.ARC_AmountDue__c : 0)
                : (calculatedAmountByContract.get(cId) ?? 0);
            if (nextBillAmount < 0) nextBillAmount = 0;
            contractsToUpdate.add(new Contract(
                Id = cId,
                ARC_NextToBeBilledAmount__c = nextBillAmount,
                ARC_LastUnpaidInvoice__c = pendingInv != null ? pendingInv.Id : null
            ));
        }
        if (!contractsToUpdate.isEmpty()) update contractsToUpdate;
    }

    // ========== PRIVATE HELPER METHODS ==========

    /**
     * @description Reconciles adjustments for an employee across billing periods.
     *
     *              Void rules:
     *              - Inside the period loop: only void existing adjustments that belong to
     *                a changed policy (changedPolicyIds). Adjustments of other policies
     *                (e.g. credits correctly calculated in a prior event) are never touched.
     *              - Stale void at the end: same scope — only changed policies.
     *              - Special case: if a policy previously had an ExpirationDate that excluded
     *                a period, and now ExpirationDate is null, void any stale adjustments for
     *                those periods before running normal reconciliation.
     *
     *              Credit/Debit rules:
     *              - Case 1 (correctPolicy exists): Credit if billedAmount != 0, Debit if correctAmount != 0
     *                AND the period was invoiced (billedAmount != 0 OR any ILI exists for that employee/period).
     *              - Case 2 (correctPolicy is null, policy expired): Credit per coverage of billedPolicy.
     */
    private static void reconcileAdjustmentsForPeriods(
        List<InsurancePolicy> employeePolicies,
        Map<Id, List<InsurancePolicyCoverage>> policyCoveragesMap,
        Map<String, Decimal> billedAmounts,
        List<BillingPeriod> periods,
        InsurancePolicy policyForAdjustment,
        Set<Id> changedPolicyIds,
        Map<String, ARC_Adjustment__c> existingAdjustmentsMap,
        List<ARC_Adjustment__c> adjustmentsToInsert,
        List<ARC_Adjustment__c> adjustmentsToUpdate,
        List<ARC_Adjustment__c> adjustmentsToVoid,
        Map<Id, InsurancePolicy> oldPolicyMap
    ) {
        Map<Id, InsurancePolicy> policyMap = new Map<Id, InsurancePolicy>();
        for (InsurancePolicy p : employeePolicies) policyMap.put(p.Id, p);

        Set<Id> foundAdjIds = new Set<Id>();

        for (BillingPeriod period : periods) {

            // Detect if a changed policy previously had an ExpirationDate that excluded
            // this period, and now ExpirationDate is null. If so, void any stale adjustments
            // for this period that belong to that policy, then let normal reconciliation run.
            for (Id changedPolicyId : changedPolicyIds) {
                InsurancePolicy oldPol = oldPolicyMap != null ? oldPolicyMap.get(changedPolicyId) : null;
                InsurancePolicy newPol = policyMap.get(changedPolicyId);
                if (oldPol != null
                    && oldPol.ARC_PolicyExpirationDate__c != null
                    && newPol != null
                    && newPol.ARC_PolicyExpirationDate__c == null
                    && period.coverageFrom > oldPol.ARC_PolicyExpirationDate__c) {

                    List<InsurancePolicyCoverage> covs = policyCoveragesMap.containsKey(changedPolicyId)
                        ? policyCoveragesMap.get(changedPolicyId) : new List<InsurancePolicyCoverage>();
                    for (String adjType : new List<String>{ 'Credit', 'Debit' }) {
                        for (InsurancePolicyCoverage cov : covs) {
                            String key = buildMatchKey(changedPolicyId, cov.Id, adjType, period);
                            ARC_Adjustment__c existing = existingAdjustmentsMap.get(key);
                            if (existing != null) {
                                existing.ARC_Status__c = 'Void';
                                adjustmentsToVoid.add(existing);
                                foundAdjIds.add(existing.Id);
                            }
                        }
                        String nullKey = buildMatchKey(changedPolicyId, null, adjType, period);
                        ARC_Adjustment__c existingNull = existingAdjustmentsMap.get(nullKey);
                        if (existingNull != null) {
                            existingNull.ARC_Status__c = 'Void';
                            adjustmentsToVoid.add(existingNull);
                            foundAdjIds.add(existingNull.Id);
                        }
                    }
                }
            }

            Id correctPolicyId = findEligiblePolicy(employeePolicies, period.coverageFrom);
            InsurancePolicy correctPolicy = correctPolicyId != null ? policyMap.get(correctPolicyId) : null;
            List<InsurancePolicyCoverage> correctCoverages = (correctPolicyId != null && policyCoveragesMap.containsKey(correctPolicyId))
                ? policyCoveragesMap.get(correctPolicyId) : new List<InsurancePolicyCoverage>();

            InsurancePolicy billedPolicy = findBilledPolicy(employeePolicies, policyCoveragesMap, period, existingAdjustmentsMap, policyForAdjustment);
            if (billedPolicy == null) billedPolicy = correctPolicy;

            // Check if the employee had any invoiced amount in this period (any policy/coverage).
            // Used to avoid generating debits for periods that were never invoiced.
            Boolean periodWasInvoiced = false;
            if (billedAmounts != null) {
                String periodSuffix = '_' + String.valueOf(period.coverageFrom) + '_' + String.valueOf(period.coverageTo);
                for (String key : billedAmounts.keySet()) {
                    if (key.endsWith(periodSuffix) && billedAmounts.get(key) != 0) {
                        periodWasInvoiced = true;
                        break;
                    }
                }
            }

            Map<String, DesiredAdjustment> desiredState = new Map<String, DesiredAdjustment>();

            if (!correctCoverages.isEmpty()) {
                // ── Case 1: there is a correct policy for this period ──
                for (InsurancePolicyCoverage correctCov : correctCoverages) {
                    Decimal correctAmount = correctCov.ARC_UnitPrice__c != null ? correctCov.ARC_UnitPrice__c : 0;

                    Decimal billedAmount = 0;
                    if (billedPolicy != null) {
                        String billedKey = String.valueOf(billedPolicy.Id) + '_' + String.valueOf(correctCov.Id) + '_' +
                                           String.valueOf(period.coverageFrom) + '_' + String.valueOf(period.coverageTo);
                        Decimal found = billedAmounts.get(billedKey);
                        billedAmount = found != null ? found : 0;
                    }

                    if (billedAmount != correctAmount) {
                        if (billedAmount != 0 && billedPolicy != null) {
                            DesiredAdjustment credit = new DesiredAdjustment(billedPolicy, correctCov, 'Credit', -billedAmount, period);
                            desiredState.put(credit.matchKey(), credit);
                        }
                        InsurancePolicy debitPolicy = correctPolicy != null ? correctPolicy : policyForAdjustment;
                        // Only generate a debit if the period was actually invoiced — either this
                        // specific coverage was billed, or any ILI exists for the employee in this period.
                        // This prevents spurious debits when a policy has no prior invoicing at all.
                        if (correctAmount != 0 && debitPolicy != null && (billedAmount != 0 || periodWasInvoiced)) {
                            DesiredAdjustment debit = new DesiredAdjustment(debitPolicy, correctCov, 'Debit', correctAmount, period);
                            desiredState.put(debit.matchKey(), debit);
                        }
                    }
                }
            } else if (billedPolicy != null) {
                // ── Case 2: no correct policy (e.g. expired) — Credit whatever was billed ──
                List<InsurancePolicyCoverage> billedCoverages = policyCoveragesMap.containsKey(billedPolicy.Id)
                    ? policyCoveragesMap.get(billedPolicy.Id) : new List<InsurancePolicyCoverage>();

                for (InsurancePolicyCoverage billedCov : billedCoverages) {
                    String billedKey = String.valueOf(billedPolicy.Id) + '_' + String.valueOf(billedCov.Id) + '_' +
                                       String.valueOf(period.coverageFrom) + '_' + String.valueOf(period.coverageTo);
                    Decimal found = billedAmounts.get(billedKey);
                    Decimal billedAmount = found != null ? found : 0;

                    if (billedAmount != 0) {
                        DesiredAdjustment credit = new DesiredAdjustment(billedPolicy, billedCov, 'Credit', -billedAmount, period);
                        desiredState.put(credit.matchKey(), credit);
                    }
                }
            }

            // Collect existing Open adjustments for this period — only for changed policies.
            // Exclude adjustments already processed by the expiration-date-cleared block above
            // (tracked in foundAdjIds) to avoid adding them to toVoid a second time.
            Map<String, ARC_Adjustment__c> existingForPeriod = new Map<String, ARC_Adjustment__c>();
            for (InsurancePolicy p : employeePolicies) {
                if (!changedPolicyIds.contains(p.Id)) continue;

                List<InsurancePolicyCoverage> covs = policyCoveragesMap.containsKey(p.Id)
                    ? policyCoveragesMap.get(p.Id) : new List<InsurancePolicyCoverage>();
                for (String adjType : new List<String>{ 'Credit', 'Debit' }) {
                    for (InsurancePolicyCoverage cov : covs) {
                        String key = buildMatchKey(p.Id, cov.Id, adjType, period);
                        ARC_Adjustment__c existing = existingAdjustmentsMap.get(key);
                        if (existing != null && !foundAdjIds.contains(existing.Id)) existingForPeriod.put(key, existing);
                    }
                    // Backward compat: null-coverage keyed adjustments
                    String nullKey = buildMatchKey(p.Id, null, adjType, period);
                    ARC_Adjustment__c existing = existingAdjustmentsMap.get(nullKey);
                    if (existing != null && !foundAdjIds.contains(existing.Id)) existingForPeriod.put(nullKey, existing);
                }
            }

            for (ARC_Adjustment__c adj : existingForPeriod.values()) foundAdjIds.add(adj.Id);

            Set<String> processedKeys = new Set<String>();
            for (String desiredKey : desiredState.keySet()) {
                processedKeys.add(desiredKey);
                DesiredAdjustment desired = desiredState.get(desiredKey);
                ARC_Adjustment__c existing = existingForPeriod.get(desiredKey);

                if (existing == null) {
                    adjustmentsToInsert.add(buildAdjustmentRecord(desired));
                } else if (existing.ARC_Amount__c != desired.amount) {
                    existing.ARC_Amount__c = desired.amount;
                    existing.Name = desired.buildName();
                    adjustmentsToUpdate.add(existing);
                }
            }

            // Only void adjustments of changed policies that are no longer in desired state
            for (String existingKey : existingForPeriod.keySet()) {
                if (!processedKeys.contains(existingKey)) {
                    ARC_Adjustment__c adj = existingForPeriod.get(existingKey);
                    adj.ARC_Status__c = 'Void';
                    adjustmentsToVoid.add(adj);
                }
            }
        }

        // Void stale adjustments — only for changed policies
        for (ARC_Adjustment__c adj : existingAdjustmentsMap.values()) {
            if (!foundAdjIds.contains(adj.Id) && changedPolicyIds.contains(adj.ARC_Policy__c)) {
                adj.ARC_Status__c = 'Void';
                adjustmentsToVoid.add(adj);
            }
        }
    }

    private static Map<String, ARC_Adjustment__c> buildExistingAdjustmentsMap(
        Set<Id> policyIds, Date startDate, Date endDate
    ) {
        Map<String, ARC_Adjustment__c> result = new Map<String, ARC_Adjustment__c>();
        for (ARC_Adjustment__c adj : [
            SELECT Id, Name, ARC_Amount__c, ARC_Status__c, ARC_Policy__c, ARC_PolicyCoverage__c,
                   ARC_CoverageDateFrom__c, ARC_CoverageDateTo__c
            FROM ARC_Adjustment__c
            WHERE ARC_Policy__c IN :policyIds
              AND ARC_Status__c = 'Open'
              AND ARC_CoverageDateFrom__c <= :endDate
              AND ARC_CoverageDateTo__c >= :startDate
        ]) {
            String adjType = (adj.ARC_Amount__c != null && adj.ARC_Amount__c < 0) ? 'Credit' : 'Debit';
            String key = buildMatchKey(adj.ARC_Policy__c, adj.ARC_PolicyCoverage__c, adjType, adj.ARC_CoverageDateFrom__c, adj.ARC_CoverageDateTo__c);
            result.put(key, adj);
        }
        return result;
    }

    private static InsurancePolicy findBilledPolicy(
        List<InsurancePolicy> employeePolicies,
        Map<Id, List<InsurancePolicyCoverage>> policyCoveragesMap,
        BillingPeriod period,
        Map<String, ARC_Adjustment__c> existingAdjustmentsMap,
        InsurancePolicy fallback
    ) {
        for (InsurancePolicy p : employeePolicies) {
            List<InsurancePolicyCoverage> covs = policyCoveragesMap.containsKey(p.Id)
                ? policyCoveragesMap.get(p.Id) : new List<InsurancePolicyCoverage>();
            for (String adjType : new List<String>{ 'Credit', 'Debit' }) {
                for (InsurancePolicyCoverage cov : covs) {
                    if (existingAdjustmentsMap.containsKey(buildMatchKey(p.Id, cov.Id, adjType, period))) return p;
                }
                if (existingAdjustmentsMap.containsKey(buildMatchKey(p.Id, null, adjType, period))) return p;
            }
        }
        return fallback;
    }

    private static void commitAdjustmentChanges(
        List<ARC_Adjustment__c> toInsert,
        List<ARC_Adjustment__c> toUpdate,
        List<ARC_Adjustment__c> toVoid
    ) {

        {
            if (!toVoid.isEmpty()) {
                Map<Id, ARC_Adjustment__c> uniqueVoids = new Map<Id, ARC_Adjustment__c>();
                for (ARC_Adjustment__c adj : toVoid) {
                    uniqueVoids.put(adj.Id, adj);
                }
                update uniqueVoids.values();
            }
            if (!toUpdate.isEmpty()) update toUpdate;
            if (!toInsert.isEmpty()) insert toInsert;
        }
      
    }

    private static String buildMatchKey(Id policyId, Id coverageId, String adjType, BillingPeriod period) {
        return buildMatchKey(policyId, coverageId, adjType, period.coverageFrom, period.coverageTo);
    }

    private static String buildMatchKey(Id policyId, Id coverageId, String adjType, Date coverageFrom, Date coverageTo) {
        String covPart = coverageId != null ? String.valueOf(coverageId) : 'null';
        return String.valueOf(policyId) + '_' + covPart + '_' + adjType + '_' +
               String.valueOf(coverageFrom) + '_' + String.valueOf(coverageTo);
    }

    private static ARC_Adjustment__c buildAdjustmentRecord(DesiredAdjustment desired) {
        return new ARC_Adjustment__c(
            Name                    = desired.buildName(),
            ARC_Policy__c           = desired.policy.Id,
            ARC_PolicyCoverage__c   = desired.coverage != null ? desired.coverage.Id : null,
            ARC_Contract__c         = desired.policy.ARC_Contract__c,
            ARC_CoverageDateFrom__c = desired.period.coverageFrom,
            ARC_CoverageDateTo__c   = desired.period.coverageTo,
            ARC_Status__c           = 'Open',
            ARC_Amount__c           = desired.amount
        );
    }

    private static List<InsurancePolicy> evaluateEligibilityForEmployee(
        List<InsurancePolicy> policies, Date invoiceAnchorDate, Date paymentAnchorDate
    ) {
        Id nextInvoicePolicyId = findEligiblePolicy(policies, invoiceAnchorDate);
        Id nextPaymentPolicyId = findEligiblePolicy(policies, paymentAnchorDate);
        
        List<InsurancePolicy> policiesToUpdate = new List<InsurancePolicy>();
        for (InsurancePolicy policy : policies) {
            Boolean isInvoiceEligible = (policy.Id == nextInvoicePolicyId);
            Boolean isPaymentEligible = (policy.Id == nextPaymentPolicyId);
            if (policy.ARC_NextInvoiceEligible__c != isInvoiceEligible ||
                policy.ARC_NextPaymentEligible__c != isPaymentEligible) {
                policiesToUpdate.add(new InsurancePolicy(
                    Id = policy.Id,
                    ARC_NextInvoiceEligible__c = isInvoiceEligible,
                    ARC_NextPaymentEligible__c = isPaymentEligible
                ));
            }
        }
        return policiesToUpdate;
    }
    
    private static Id findEligiblePolicy(List<InsurancePolicy> policies, Date anchorDate) {
        if (anchorDate == null) return null;
        InsurancePolicy selectedPolicy = null;
        for (InsurancePolicy policy : policies) {
            if (policy.Status != 'Activated' && policy.Status != 'Awaiting Activation' && policy.Status != 'Terminated') continue;
            Boolean effectiveDateValid = policy.ARC_PolicyEffectiveDate__c != null && policy.ARC_PolicyEffectiveDate__c <= anchorDate;
            Boolean endDateValid = policy.ARC_PolicyExpirationDate__c == null || policy.ARC_PolicyExpirationDate__c >= anchorDate;
            if (effectiveDateValid && endDateValid) {
                if (selectedPolicy == null || policy.ARC_PolicyEffectiveDate__c > selectedPolicy.ARC_PolicyEffectiveDate__c) {
                    selectedPolicy = policy;
                }
            }
        }
        return selectedPolicy != null ? selectedPolicy.Id : null;
    }
    
    private static Date calculateImpactStart(InsurancePolicy oldPolicy, InsurancePolicy newPolicy) {
        List<Date> dates = new List<Date>();
        if (oldPolicy != null && oldPolicy.ARC_PolicyEffectiveDate__c  != null) dates.add(oldPolicy.ARC_PolicyEffectiveDate__c);
        if (oldPolicy != null && oldPolicy.ARC_PolicyExpirationDate__c != null) dates.add(oldPolicy.ARC_PolicyExpirationDate__c);
        if (newPolicy.ARC_PolicyEffectiveDate__c  != null) dates.add(newPolicy.ARC_PolicyEffectiveDate__c);
        if (newPolicy.ARC_PolicyExpirationDate__c != null) dates.add(newPolicy.ARC_PolicyExpirationDate__c);
        if (dates.isEmpty()) return null;
        dates.sort();
        return dates[0];
    }
    
    private static List<BillingPeriod> buildBillingPeriods(Date startDate, Date endDate, String frequency) {
        List<BillingPeriod> periods = new List<BillingPeriod>();
        Integer monthsPerPeriod = frequency == 'Quarterly' ? 3 : (frequency == 'Annual' ? 12 : 1);
        Date currentDate = startDate.toStartOfMonth();
        while (currentDate <= endDate) {
            Date periodEnd = currentDate.addMonths(monthsPerPeriod).addDays(-1);
            if (periodEnd >= startDate) periods.add(new BillingPeriod(currentDate, periodEnd));
            currentDate = periodEnd.addDays(1);
        }
        return periods;
    }

    /**
     * @description Queries parent-level InsurancePolicyCoverage records for a set of policies,
     *              grouped by policy ID.
     */
    private static Map<Id, List<InsurancePolicyCoverage>> buildPolicyCoveragesMap(Set<Id> policyIds) {
        Map<Id, List<InsurancePolicyCoverage>> result = new Map<Id, List<InsurancePolicyCoverage>>();
        for (InsurancePolicyCoverage cov : [
            SELECT Id, InsurancePolicyId, vlocity_ins_fsc__Product2Id__c, ARC_UnitPrice__c
            FROM InsurancePolicyCoverage
            WHERE InsurancePolicyId IN :policyIds
              AND ARC_ParentPolicyCoverage__c = null
        ]) {
            if (!result.containsKey(cov.InsurancePolicyId)) {
                result.put(cov.InsurancePolicyId, new List<InsurancePolicyCoverage>());
            }
            result.get(cov.InsurancePolicyId).add(cov);
        }
        return result;
    }

    // ========== INNER CLASSES ==========

    private class DesiredAdjustment {
        InsurancePolicy         policy;
        InsurancePolicyCoverage coverage;
        String                  adjType;
        Decimal                 amount;
        BillingPeriod           period;

        DesiredAdjustment(InsurancePolicy policy, InsurancePolicyCoverage coverage, String adjType, Decimal amount, BillingPeriod period) {
            this.policy   = policy;
            this.coverage = coverage;
            this.adjType  = adjType;
            this.amount   = amount;
            this.period   = period;
        }

        String matchKey() {
            String covPart = coverage != null ? String.valueOf(coverage.Id) : 'null';
            return String.valueOf(policy.Id) + '_' + covPart + '_' + adjType + '_' +
                   String.valueOf(period.coverageFrom) + '_' + String.valueOf(period.coverageTo);
        }

        String buildName() {
            String fromStr   = period.coverageFrom != null ? period.coverageFrom.format() : '';
            String toStr     = period.coverageTo   != null ? period.coverageTo.format()   : '';
            String policyNum = policy.Name         != null ? policy.Name                  : '';
            return adjType + ' ' + fromStr + '-' + toStr + ' - Policy ' + policyNum;
        }
    }

    private class BillingPeriod {
        Date coverageFrom;
        Date coverageTo;
        BillingPeriod(Date fromDate, Date toDate) {
            this.coverageFrom = fromDate;
            this.coverageTo   = toDate;
        }
    }
}