/**
 * @description Batch class to re-evaluate billing adjustments for a single contract by employee
 * @author lucas.benero@arcsona.com
 * @date 2026-01-27
 */
global class ARC_ContractAdjustmentBatch implements Database.Batchable<Id> {
    
    private Id contractId;
    private List<Id> employeeIds;
    
    /**
     * @description Constructor to specify which contract to process
     * @param contractId The Contract ID to re-evaluate
     */
    global ARC_ContractAdjustmentBatch(Id contractId) {
        this.contractId = contractId;
        
        // Preload employee IDs
        this.employeeIds = new List<Id>();
        Set<Id> uniqueEmployeeIds = new Set<Id>();
        for (InsurancePolicy policy : [
            SELECT NameInsuredId
            FROM InsurancePolicy
            WHERE ARC_Contract__c = :contractId
              AND NameInsuredId != null
        ]) {
            uniqueEmployeeIds.add(policy.NameInsuredId);
        }
        this.employeeIds.addAll(uniqueEmployeeIds);
    }
    
    /**
     * @description Returns the list of employee IDs to process
     * @param bc BatchableContext
     * @return Iterable of employee IDs
     */
    global Iterable<Id> start(Database.BatchableContext bc) {
        return this.employeeIds;
    }
    
    /**
     * @description Process each batch of employees.
     *              Builds the policyIdsByEmployee map expected by evaluateAdjustmentsForPoliciesBulk
     *              and delegates to the bulk service method.
     * @param bc BatchableContext
     * @param scope List of employee IDs to process
     */
    global void execute(Database.BatchableContext bc, List<Id> scope) {
        Map<String, List<Id>> policyIdsByEmployee = new Map<String, List<Id>>();

        for (InsurancePolicy policy : [
            SELECT Id, NameInsuredId
            FROM InsurancePolicy
            WHERE ARC_Contract__c = :contractId
              AND NameInsuredId IN :scope
              AND NameInsuredId != null
        ]) {
            String empKey = String.valueOf(contractId) + '_' + String.valueOf(policy.NameInsuredId);
            if (!policyIdsByEmployee.containsKey(empKey)) {
                policyIdsByEmployee.put(empKey, new List<Id>());
            }
            policyIdsByEmployee.get(empKey).add(policy.Id);
        }

        if (!policyIdsByEmployee.isEmpty()) {
            ARC_ContractBillingService.evaluateAdjustmentsForPoliciesBulk(policyIdsByEmployee, null);
        }
    }
    
    /**
     * @description Finish method (currently no post-processing needed)
     * @param bc BatchableContext
     */
    global void finish(Database.BatchableContext bc) {
        System.debug('ARC_ContractAdjustmentBatch completed for contract: ' + contractId);
    }
}