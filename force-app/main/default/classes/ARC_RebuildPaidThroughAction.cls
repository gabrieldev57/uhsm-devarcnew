/*******************************************************************
* @ClassName          :   ARC_RebuildPaidThroughAction
* @Description        :   Invocable Apex action that rebuilds Contract.ARC_CoveragePaidThrough__c
*                          from scratch by inspecting all approved Charge transactions linked to
*                          the Contract's Chargent Order and taking the latest ARC_Cover_To__c
*                          that is still net-positive (i.e. not offset by a Refund/Void).
*
*                          Intended to be called from the "Rebuild Paid Through" Screen Flow
*                          placed as a Quick Action on the Contract page layout.
*
*                          Access: admin / ops profiles only (enforce via Flow / Profile restrictions).
********************************************************************/
public without sharing class ARC_RebuildPaidThroughAction {

    public class RebuildRequest {
        @InvocableVariable(label='Contract Id' description='Id of the Contract to rebuild' required=true)
        public Id contractId;
    }

    public class RebuildResult {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='New Coverage Paid Through')
        public Date newCoveragePaidThrough;

        @InvocableVariable(label='Old Coverage Paid Through')
        public Date oldCoveragePaidThrough;
    }

    /*******************************************************************
    * @MethodName         :   rebuild
    * @Description        :   Entry point invoked by Screen Flow.
    *                          For each requested Contract:
    *                          1. Load the Contract + its Chargent Order.
    *                          2. Query every approved Transaction on that Order.
    *                          3. Walk transactions in chronological order:
    *                             - Charge   → advance coverage to trans.ARC_Cover_To__c (if later)
    *                             - Refund / Void → roll back one period
    *                          4. Write the resulting date back to the Contract.
    ********************************************************************/
    @InvocableMethod(
        label='Rebuild Coverage Paid Through'
        description='Recalculates Contract.ARC_CoveragePaidThrough__c from approved transaction history and saves the result.'
        category='Contract'
    )
    public static List<RebuildResult> rebuild(List<RebuildRequest> requests) {
        List<RebuildResult> results = new List<RebuildResult>();

        // Collect unique Contract IDs (bulkified)
        Set<Id> contractIds = new Set<Id>();
        for (RebuildRequest req : requests) {
            if (req.contractId != null) {
                contractIds.add(req.contractId);
            }
        }

        if (contractIds.isEmpty()) {
            for (RebuildRequest req : requests) {
                RebuildResult r = new RebuildResult();
                r.success = false;
                r.message = 'No Contract Id provided.';
                results.add(r);
            }
            return results;
        }

        // Load Contracts with their Chargent Order and key fields
        Map<Id, Contract> contractMap = new Map<Id, Contract>([
            SELECT Id,
                   ARC_CoveragePaidThrough__c,
                   ARC_PaymentFrequency__c,
                   ARC_EffectiveDate__c,
                   ARC_RecurringMonthlyOrder__c,
                   RecordType.DeveloperName
            FROM Contract
            WHERE Id IN :contractIds
              AND RecordType.DeveloperName = 'ARC_SmallGroup'
        ]);

        // Map Contract → Chargent Order ID (via direct lookup field)
        Map<Id, Id> contractToOrderId = new Map<Id, Id>();
        for (Contract c : contractMap.values()) {
            if (c.ARC_RecurringMonthlyOrder__c != null) {
                contractToOrderId.put(c.Id, c.ARC_RecurringMonthlyOrder__c);
            }
        }

        // Bulk-query all approved Charge / Refund / Void transactions for those orders,
        // ordered oldest → newest so we replay history in sequence.
        Set<Id> orderIds = new Set<Id>(contractToOrderId.values());
        Map<Id, List<ChargentOrders__Transaction__c>> orderTransactionsMap = new Map<Id, List<ChargentOrders__Transaction__c>>();

        if (!orderIds.isEmpty()) {
            for (ChargentOrders__Transaction__c tx : [
                SELECT Id,
                       ChargentOrders__Order__c,
                       ChargentOrders__Type__c,
                       ChargentOrders__Response_Status__c,
                       ARC_Cover_To__c,
                       CreatedDate
                FROM ChargentOrders__Transaction__c
                WHERE ChargentOrders__Order__c IN :orderIds
                  AND ChargentOrders__Response_Status__c = 'Approved'
                  AND ChargentOrders__Type__c IN ('Charge', 'Refund', 'Void')
                ORDER BY CreatedDate ASC
            ]) {
                Id orderId = tx.ChargentOrders__Order__c;
                if (!orderTransactionsMap.containsKey(orderId)) {
                    orderTransactionsMap.put(orderId, new List<ChargentOrders__Transaction__c>());
                }
                orderTransactionsMap.get(orderId).add(tx);
            }
        }

        // Compute new coverage dates and collect contracts to update
        List<Contract> contractsToUpdate = new List<Contract>();
        Map<Id, RebuildResult> resultByContractId = new Map<Id, RebuildResult>();

        for (Id contractId : contractIds) {
            RebuildResult res = new RebuildResult();

            Contract contract = contractMap.get(contractId);
            if (contract == null) {
                res.success = false;
                res.message = 'Contract not found or is not a Small Group contract (Id: ' + contractId + ').';
                resultByContractId.put(contractId, res);
                continue;
            }

            res.oldCoveragePaidThrough = contract.ARC_CoveragePaidThrough__c;

            Id orderId = contractToOrderId.get(contractId);
            if (orderId == null) {
                res.success = false;
                res.message = 'No Chargent Order found for this Contract. Cannot rebuild.';
                resultByContractId.put(contractId, res);
                continue;
            }

            List<ChargentOrders__Transaction__c> txList = orderTransactionsMap.get(orderId);
            if (txList == null || txList.isEmpty()) {
                // No approved transactions → paid through should be null
                res.newCoveragePaidThrough = null;
                res.success = true;
                res.message = 'No approved transactions found. Coverage Paid Through reset to null.';
                contractsToUpdate.add(new Contract(
                    Id = contractId,
                    ARC_CoveragePaidThrough__c = null
                ));
                resultByContractId.put(contractId, res);
                continue;
            }

            // Replay transaction history
            Date computedCoverage = null;
            String paymentFrequency = contract.ARC_PaymentFrequency__c;

            for (ChargentOrders__Transaction__c tx : txList) {
                String txType = tx.ChargentOrders__Type__c;

                if (txType == 'Charge') {
                    // Advance coverage: use ARC_Cover_To__c if it's later than current
                    if (tx.ARC_Cover_To__c != null) {
                        if (computedCoverage == null || tx.ARC_Cover_To__c > computedCoverage) {
                            computedCoverage = tx.ARC_Cover_To__c;
                        }
                    }
                } else if (txType == 'Refund' || txType == 'Void') {
                    // Roll back one payment period
                    computedCoverage = rollBackOnePeriod(computedCoverage, paymentFrequency);

                    // If we rolled back before effective date → null
                    if (contract.ARC_EffectiveDate__c != null
                        && computedCoverage != null
                        && computedCoverage < contract.ARC_EffectiveDate__c) {
                        computedCoverage = null;
                    }
                }
            }

            res.newCoveragePaidThrough = computedCoverage;
            res.success = true;
            res.message = 'Coverage Paid Through rebuilt successfully.'
                        + ' Previous: ' + formatDate(contract.ARC_CoveragePaidThrough__c)
                        + ' → New: ' + formatDate(computedCoverage);

            contractsToUpdate.add(new Contract(
                Id = contractId,
                ARC_CoveragePaidThrough__c = computedCoverage
            ));
            resultByContractId.put(contractId, res);
        }

        // Save all updated contracts
        if (!contractsToUpdate.isEmpty()) {
            Database.SaveResult[] saveResults = Database.update(contractsToUpdate, false);
            for (Integer i = 0; i < saveResults.size(); i++) {
                Database.SaveResult sr = saveResults[i];
                Id contractId = contractsToUpdate[i].Id;
                RebuildResult res = resultByContractId.get(contractId);
                if (!sr.isSuccess()) {
                    res.success = false;
                    res.message = 'Save failed: ' + sr.getErrors()[0].getMessage();
                }
            }
        }

        // Return results in the same order as the input requests
        for (RebuildRequest req : requests) {
            RebuildResult res = resultByContractId.get(req.contractId);
            if (res == null) {
                RebuildResult fallback = new RebuildResult();
                fallback.success = false;
                fallback.message = 'Unexpected error: no result produced for Contract ' + req.contractId;
                results.add(fallback);
            } else {
                results.add(res);
            }
        }

        return results;
    }

    /*******************************************************************
    * @MethodName         :   rollBackOnePeriod
    * @Description        :   Mirrors processRefund in ARC_TransactionHandler —
    *                          subtracts one payment period from the coverage date.
    *                          Uses boundary math to avoid day-loss issues.
    *                          e.g. 30/04 → +1d → 01/05 → -1m → 01/04 → -1d → 31/03
    ********************************************************************/
    private static Date rollBackOnePeriod(Date currentCoverage, String paymentFrequency) {
        if (currentCoverage == null) return null;

        Integer months = 1; // default Monthly
        if (paymentFrequency == 'Quarterly') {
            months = 3;
        } else if (paymentFrequency == 'Annual') {
            months = 12;
        }

        return currentCoverage.addDays(1).addMonths(-months).addDays(-1);
    }

    /*******************************************************************
    * @MethodName         :   formatDate
    * @Description        :   Null-safe date formatter for result messages.
    ********************************************************************/
    private static String formatDate(Date d) {
        if (d == null) return 'null';
        return String.valueOf(d);
    }
}