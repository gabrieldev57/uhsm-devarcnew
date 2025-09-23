public with sharing class ARC_SavedEnrollmentsController {
    @AuraEnabled(cacheable=false)
    public static List<Map<String,Object>> getSavedEnrollments() {
        // System.debug('searchTerm: ' + searchTerm);
        List<vlocity_ins__OmniScriptInstance__c> omniscriptInstances = [
            SELECT Id,
                vlocity_ins__ObjectId__c,
                vlocity_ins__OmniScriptType__c,
                vlocity_ins__OmniScriptSubType__c,
                vlocity_ins__OmniScriptLanguage__c,
                CreatedDate,
                LastModifiedDate
            FROM vlocity_ins__OmniScriptInstance__c
            WHERE LastModifiedDate = LAST_N_DAYS:30  
            ORDER BY CreatedDate DESC
        ];
        List<Map<String,Object>> outputMap = new List<Map<String,Object>>();
        Set<Id> contractIds = new Set<Id>();
        
        for (vlocity_ins__OmniScriptInstance__c omniscriptInstance : omniscriptInstances) {
            if (omniscriptInstance.vlocity_ins__ObjectId__c != null) {
                if (((Id)omniscriptInstance.vlocity_ins__ObjectId__c).getSObjectType() == Schema.Contract.SObjectType) {
                    contractIds.add(omniscriptInstance.vlocity_ins__ObjectId__c);
                }
            }
        }

        Map<Id,Contract> contracts = new Map<Id,Contract>([
            SELECT Id,
                ContractNumber,
                CreatedDate,
                LastModifiedDate,
                Account.Name,
                Account.vlocity_ins__Email__c
            FROM Contract 
            WHERE Id IN :contractIds AND Status = 'Draft'
        ]);

        for (vlocity_ins__OmniScriptInstance__c omniscriptInstance : omniscriptInstances) {
            if (contracts.keySet().contains(omniscriptInstance.vlocity_ins__ObjectId__c)) {
                    Map<String,Object> output = new Map<String,Object>();
                    output.put('Id',omniscriptInstance.Id);
                    output.put('contractId',omniscriptInstance.vlocity_ins__ObjectId__c);
                    output.put('contractNumber',contracts.get(omniscriptInstance.vlocity_ins__ObjectId__c).ContractNumber);
                    output.put('accountName',contracts.get(omniscriptInstance.vlocity_ins__ObjectId__c).Account.Name);
                    output.put('accountEmail',contracts.get(omniscriptInstance.vlocity_ins__ObjectId__c).Account.vlocity_ins__Email__c);
                    output.put('omniScriptType',omniscriptInstance.vlocity_ins__OmniScriptType__c);
                    output.put('omniScriptSubType',omniscriptInstance.vlocity_ins__OmniScriptSubType__c);
                    output.put('omniScriptLanguage',omniscriptInstance.vlocity_ins__OmniScriptLanguage__c);
                    output.put('createdDate',omniscriptInstance.CreatedDate);
                    output.put('lastModifiedDate',omniscriptInstance.LastModifiedDate);
                    outputMap.add(output);
            }

        }
        // return new List<Map<String,Object>>();
        return outputMap;
    }
}