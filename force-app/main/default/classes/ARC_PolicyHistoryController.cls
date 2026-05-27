public with sharing class ARC_PolicyHistoryController {
    @AuraEnabled(cacheable=true)
    public static List<InsurancePolicy> getPolicyHistory(Id personAccountId) {
        return [
            SELECT Id,ARC_Contract__c,ARC_GroupAccount__c,ARC_EmployeeAccount__c,PolicyName,ARC_EmployeeAccount__r.Name, ARC_Reason__c, ARC_EffectiveDate__c, ARC_PolicyExpirationDate__c,Name,NameInsured.Name,Status
            FROM InsurancePolicy
            WHERE Status!='Draft'and Status != 'Voided' AND 
            NameInsuredId = :personAccountId WITH SECURITY_ENFORCED
            ORDER BY ARC_EffectiveDate__c  DESC
        ];
    }
}