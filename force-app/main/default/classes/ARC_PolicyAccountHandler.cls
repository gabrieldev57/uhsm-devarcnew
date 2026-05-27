/**
 * @description Handler class for managing Account activation and deactivation based on Insurance Policy status changes
 * @author Angela Rodriguez
 * @date 2026-07-04 
 *              Note: ARC_GroupAccount__c (Employer) does not impact the Account activation/deactivation logic
 *              as per current requirements, but can be included in future enhancements if needed.
 */
public class ARC_PolicyAccountHandler {
    
    private static final String STATUS_ACTIVATED = 'Activated';
    private static final String STATUS_TERMINATED = 'Terminated';
    private static final String STATUS_VOIDED = 'Voided';

    private static Boolean alreadyProcessed = false;
    
    /**
     * @description Principal method to process policy status changes and update related Accounts accordingly
     * @param newPolicies Map of new policies
     * @param oldPolicies Map of previous policies
     */
    public static void processAccountActivation(Map<Id, InsurancePolicy> newPolicies, 
                                                Map<Id, InsurancePolicy> oldPolicies) {
     
        if (alreadyProcessed) return;
        alreadyProcessed = true;

        Id smallGroupRTId = Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        
        Map<Id, InsurancePolicy> policiesToActivate = new Map<Id, InsurancePolicy>();
        Map<Id, InsurancePolicy> policiesToVoid = new Map<Id, InsurancePolicy>();
        
        for (Id policyId : newPolicies.keySet()) {
            InsurancePolicy oldPolicy = oldPolicies.get(policyId);
            InsurancePolicy newPolicy = newPolicies.get(policyId);
        
            if (newPolicy.RecordTypeId != smallGroupRTId) continue;
            
            if (oldPolicy.Status != newPolicy.Status) {
                if (newPolicy.Status == STATUS_ACTIVATED) {
                    policiesToActivate.put(policyId, newPolicy);
                } else if (newPolicy.Status == STATUS_VOIDED) {
                    policiesToVoid.put(policyId, newPolicy);
                }
            }
        }
        
        if (!policiesToActivate.isEmpty()) {
            handleActivated(policiesToActivate, smallGroupRTId);
        }
        
        if (!policiesToVoid.isEmpty()) {
            handleVoided(policiesToVoid);
        }
    }
    
    // ========== Handle Activated Status ==========
    
    private static void handleActivated(Map<Id, InsurancePolicy> activatedPolicies, Id smallGroupRTId) {
        
        Map<Id, Account> accountsToUpdateMap = new Map<Id, Account>();
        List<InsurancePolicy> policiesToUpdate = new List<InsurancePolicy>();
        
        Set<Id> currentPolicyIds = activatedPolicies.keySet();
        
        Set<Id> allEmployeeIds = new Set<Id>();
        Set<Id> allGuardianIds = new Set<Id>();
        
        for (InsurancePolicy policy : activatedPolicies.values()) {
            if (policy.NameInsuredId != null) {
                allEmployeeIds.add(policy.NameInsuredId);
            }
            if (policy.ARC_Guardian__c != null) {
                allGuardianIds.add(policy.ARC_Guardian__c);
            }
        }
        
        Set<Id> allPersonAccountIds = new Set<Id>();
        allPersonAccountIds.addAll(allEmployeeIds);
        allPersonAccountIds.addAll(allGuardianIds);
        
        Map<Id, InsurancePolicy> personAccountToPreviousPolicy = getPreviousActivePoliciesByPersonAccount(allPersonAccountIds, currentPolicyIds, smallGroupRTId);
        
        for (InsurancePolicy newPolicy : activatedPolicies.values()) {
            Date newEffectiveDate = newPolicy.ARC_PolicyEffectiveDate__c;
            
            // Activate Employee
            if (newPolicy.NameInsuredId != null) {
                accountsToUpdateMap.put(newPolicy.NameInsuredId, new Account(Id = newPolicy.NameInsuredId, IsActive = true, ARC_TerminationDate__c = null));
            }
            
            // Activate Guardian
            if (newPolicy.ARC_Guardian__c != null) {
                accountsToUpdateMap.put(newPolicy.ARC_Guardian__c, new Account(Id = newPolicy.ARC_Guardian__c, IsActive = true));
            }
            
            if (newPolicy.NameInsuredId != null) {
                InsurancePolicy previousEmployeePolicy = personAccountToPreviousPolicy.get(newPolicy.NameInsuredId);
                if (previousEmployeePolicy != null && previousEmployeePolicy.Id != newPolicy.Id) {
                    
                    previousEmployeePolicy.Status = STATUS_TERMINATED;
                    
                    Date expectedExpiration = newEffectiveDate != null ? newEffectiveDate.addDays(-1) : null;
                    if (expectedExpiration != null && 
                        previousEmployeePolicy.ARC_PolicyExpirationDate__c != expectedExpiration) {
                        previousEmployeePolicy.ARC_PolicyExpirationDate__c = expectedExpiration;
                    }
                    
                    policiesToUpdate.add(previousEmployeePolicy);
                    
                    Set<Id> newPolicyAccountIds = new Set<Id>();
                    if (newPolicy.NameInsuredId != null) newPolicyAccountIds.add(newPolicy.NameInsuredId);
                    if (newPolicy.ARC_Guardian__c != null) newPolicyAccountIds.add(newPolicy.ARC_Guardian__c);
                    
                    // Fix 3: Do not overwrite IsActive = true with false for the same account
                    if (previousEmployeePolicy.NameInsuredId != null && !newPolicyAccountIds.contains(previousEmployeePolicy.NameInsuredId)) {
                        Account existing = accountsToUpdateMap.get(previousEmployeePolicy.NameInsuredId);
                        if (existing == null || existing.IsActive != true) {
                            accountsToUpdateMap.put(previousEmployeePolicy.NameInsuredId, new Account(Id = previousEmployeePolicy.NameInsuredId, IsActive = false));
                        }
                    }
                    // Fix 3: Same check for Guardian
                    if (previousEmployeePolicy.ARC_Guardian__c != null && !newPolicyAccountIds.contains(previousEmployeePolicy.ARC_Guardian__c)) {
                        Account existing = accountsToUpdateMap.get(previousEmployeePolicy.ARC_Guardian__c);
                        if (existing == null || existing.IsActive != true) {
                            accountsToUpdateMap.put(previousEmployeePolicy.ARC_Guardian__c, new Account(Id = previousEmployeePolicy.ARC_Guardian__c, IsActive = false));
                        }
                    }
                }
            }
        }
        
        if (!accountsToUpdateMap.isEmpty()) {
            update accountsToUpdateMap.values();
        }
        if (!policiesToUpdate.isEmpty()) {
            update policiesToUpdate;
        }
    }
    
    // ========== Handle Voided Status ==========
    
    private static void handleVoided(Map<Id, InsurancePolicy> voidedPolicies) {
        
        Set<Id> employeeIds = new Set<Id>();
        Set<Id> guardianIds = new Set<Id>();
        Set<Id> policyIds = voidedPolicies.keySet();
        
        for (InsurancePolicy policy : voidedPolicies.values()) {
            if (policy.NameInsuredId != null) employeeIds.add(policy.NameInsuredId);
            if (policy.ARC_Guardian__c != null) guardianIds.add(policy.ARC_Guardian__c);
        }

        // Fix 4: Combine employeeIds and guardianIds into a single set to avoid 2 separate queries
        Set<Id> allPersonAccountIds = new Set<Id>();
        allPersonAccountIds.addAll(employeeIds);
        allPersonAccountIds.addAll(guardianIds);

        Map<Id, Integer> activeCountMap = getActivePolicyCountByPersonAccount(allPersonAccountIds, policyIds);
        
        List<Account> accountsToDeactivate = new List<Account>();
        
        for (InsurancePolicy voidedPolicy : voidedPolicies.values()) {
            if (voidedPolicy.NameInsuredId != null) {
                Integer activeCount = activeCountMap.get(voidedPolicy.NameInsuredId) != null ? 
                                      activeCountMap.get(voidedPolicy.NameInsuredId) : 0;
                if (activeCount == 0) {
                    accountsToDeactivate.add(new Account(Id = voidedPolicy.NameInsuredId, IsActive = false));
                }
            }
            
            if (voidedPolicy.ARC_Guardian__c != null) {
                Integer activeCount = activeCountMap.get(voidedPolicy.ARC_Guardian__c) != null ? 
                                      activeCountMap.get(voidedPolicy.ARC_Guardian__c) : 0;
                if (activeCount == 0) {
                    accountsToDeactivate.add(new Account(Id = voidedPolicy.ARC_Guardian__c, IsActive = false));
                }
            }
        }
        
        if (!accountsToDeactivate.isEmpty()) {
            update accountsToDeactivate;
        }
    }
    
    // ========== Auxiliar Methods ==========

    private static Map<Id, InsurancePolicy> getPreviousActivePoliciesByPersonAccount(
        Set<Id> personAccountIds, 
        Set<Id> currentPolicyIds,
        Id recordTypeId
    ) {
        Map<Id, InsurancePolicy> result = new Map<Id, InsurancePolicy>();
        
        if (personAccountIds == null || personAccountIds.isEmpty()) {
            return result;
        }
        
        List<InsurancePolicy> previousPolicies = [
            SELECT Id, NameInsuredId, ARC_Guardian__c, Status, 
                   ARC_PolicyExpirationDate__c, ARC_PolicyEffectiveDate__c
            FROM InsurancePolicy
            WHERE (NameInsuredId IN :personAccountIds OR ARC_Guardian__c IN :personAccountIds)
            AND Status = :STATUS_ACTIVATED
            AND Id NOT IN :currentPolicyIds
            AND RecordTypeId = :recordTypeId
            ORDER BY ARC_PolicyEffectiveDate__c DESC
        ];
        
        for (InsurancePolicy policy : previousPolicies) {
            if (policy.NameInsuredId != null && !result.containsKey(policy.NameInsuredId)) {
                result.put(policy.NameInsuredId, policy);
            }
            if (policy.ARC_Guardian__c != null && !result.containsKey(policy.ARC_Guardian__c)) {
                result.put(policy.ARC_Guardian__c, policy);
            }
        }
        
        return result;
    }
    
    /**
     * @description Counts how many active policies exist for each Person Account (Employee or Guardian)
     */
    private static Map<Id, Integer> getActivePolicyCountByPersonAccount(Set<Id> personAccountIds, Set<Id> excludedPolicyIds) {
        Map<Id, Integer> result = new Map<Id, Integer>();
        
        if (personAccountIds == null || personAccountIds.isEmpty()) {
            return result;
        }
        
        for (Id accId : personAccountIds) {
            result.put(accId, 0);
        }

        List<AggregateResult> counts = [
            SELECT NameInsuredId, ARC_Guardian__c, COUNT(Id) total
            FROM InsurancePolicy
            WHERE (NameInsuredId IN :personAccountIds OR ARC_Guardian__c IN :personAccountIds)
            AND Status = :STATUS_ACTIVATED
            AND Id NOT IN :excludedPolicyIds
            GROUP BY NameInsuredId, ARC_Guardian__c
        ];
        
        for (AggregateResult ar : counts) {
            Id nameInsuredId = (Id) ar.get('NameInsuredId');
            Id guardianId = (Id) ar.get('ARC_Guardian__c');
            Integer total = (Integer) ar.get('total');
            
            if (nameInsuredId != null && result.containsKey(nameInsuredId)) {
                result.put(nameInsuredId, result.get(nameInsuredId) + total);
            }
            if (guardianId != null && result.containsKey(guardianId)) {
                result.put(guardianId, result.get(guardianId) + total);
            }
        }
        
        return result;
    }
}