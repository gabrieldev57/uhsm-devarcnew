public without sharing class InsurancePolicyHelper {
       @AuraEnabled(cacheable=true)
    public static List<InsurancePolicy> getPoliciesByContractIds(List<Id> contractIds) {
        System.debug('Fetching InsurancePolicy records for ContractIds: ' + contractIds);

        if (contractIds == null || contractIds.isEmpty()) {
            return new List<InsurancePolicy>();
        }

        List<InsurancePolicy> policies = [
            SELECT Id, Status, ARC_Contract__r.Contract_Id_18__c, LastModifiedDate,NameInsured.Name
            FROM InsurancePolicy
            WHERE ARC_Contract__r.Contract_Id_18__c IN :contractIds
            ORDER BY LastModifiedDate DESC
        ];

        System.debug('InsurancePolicy rows fetched: ' + policies.size());
        return policies;
    }
    }