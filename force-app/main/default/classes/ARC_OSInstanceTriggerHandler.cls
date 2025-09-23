/*******************************************************************
* @ClassName          :   ARC_OSInstanceTriggerHandler
* @Description        :   
* @MethodName         :   stampSaveForLaterDateOnLead, 
********************************************************************/

public without sharing class ARC_OSInstanceTriggerHandler {

    /*******************************************************************
    * @MethodName         :   stampSaveForLaterDateOnLead
    * @Description        :   Populates the Lead Saved Date field when during the self Shop & Enroll process the customer clicks "Save for later". 
    ********************************************************************/
    public static void stampSaveForLaterDateOnLead(List<vlocity_ins__OmniScriptInstance__c> OSInstances) {
        Set<Id> contractsToQuery = new Set<Id>();
        for (vlocity_ins__OmniScriptInstance__c instance: OSInstances){
            if (instance.vlocity_ins__ObjectId__c != null && instance.vlocity_ins__ObjectType__c == 'Contract') contractsToQuery.add(instance.vlocity_ins__ObjectId__c);
        }
        List<Lead_Source__c> leadsSources = [SELECT Id, Lead__c, ARC_Contract__c FROM Lead_Source__c WHERE ARC_Contract__c IN :contractsToQuery];
        Set<Id> leadsIdsToUpdate = new Set<Id>();
        if ((leadsSources?.size() > 0)) {
            for (Lead_Source__c l : leadsSources) leadsIdsToUpdate.add(l.Lead__c);
        }
        List<Lead> leadsToUpdate = new List<Lead>();
        if ((leadsIdsToUpdate?.size() > 0)) {
            for (Id leadId: leadsIdsToUpdate){
                Lead leadUpdated = new Lead( Id = leadId, ARC_SESaveForLater__c = datetime.now());
                leadsToUpdate.add(leadUpdated);
            }
            update leadsToUpdate;
        }

    }

}