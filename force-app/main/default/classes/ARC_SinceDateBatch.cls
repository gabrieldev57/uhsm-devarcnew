global without sharing class ARC_SinceDateBatch implements Database.Batchable<sObject>{

    public Set<Id> personAccountIds = new Set<Id>();

    global ARC_SinceDateBatch (Set<Id> personAccounts){
        System.debug('EXECUTE BATCH FOR SPECIFIC ACCOUNTS');
        this.personAccountIds = personAccounts;
    }

    global ARC_SinceDateBatch(){}

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id FROM vlocity_ins__GroupCensus__c]);
    }
 
    global void execute(Database.BatchableContext BC, List<vlocity_ins__GroupCensus__c> censusList){

        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpRelatedToCm = [SELECT Id, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_ContractReason__c, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.CreatedDate, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId
            FROM vlocity_ins__GroupCensusMemberPlan__c 
            WHERE vlocity_ins__GroupCensusMemberId__r.vlocity_ins__CensusId__c IN: censusList
            AND vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId <> null
            AND vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.IsActive = True
            AND vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical'
            AND vlocity_ins__ContractLineId__r.Name  LIKE 'WeShare%'
            AND (
                vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Activated' 
                OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Terminated')
            ORDER BY vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c ASC];


        Map<Id,Map<String,Date>> memberSinceDateMap = new Map<Id,Map<String,Date>>();
        List<Account> paToUpdate = new List<Account>();

        for(vlocity_ins__GroupCensusMemberPlan__c plan: gcmpRelatedToCm) {
            Map<String,Date> datesMap = memberSinceDateMap.containsKey(plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId)? memberSinceDateMap.get(plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId): new Map<String,Date>();
            Boolean isAddNewBorn = plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.ARC_ContractReason__c.contains('Add Newborn');
            System.debug('newborn: '+isAddNewBorn);
            System.debug('plan '+ plan);
            System.debug('contract Effective Date - '+ plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c);
            
            if(!datesMap.containsKey('inactiveDate')){
                //Set Since Date
                if(!isAddNewBorn) datesMap.put('sinceDate', plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c);
                else datesMap.put('sinceDate',Date.ValueOf(plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.CreatedDate));
            }
            else if(datesMap.containsKey('inactiveDate')){
                System.debug('Inactive Date Add 1 Day - '+datesMap.get('inactiveDate').addDays(1));
                if(datesMap.get('inactiveDate').addDays(1) < plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c){
                    //Reset Since Date
                    System.debug('reset'+datesMap.get('inactiveDate').addDays(1));
                    if(!isAddNewBorn)datesMap.put('sinceDate', plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c);
                    else datesMap.put('sinceDate', Date.ValueOf(plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.CreatedDate));
                }
            }
            if(plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status == 'Terminated') datesMap.put('inactiveDate', plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c);
            System.debug('datesMap after'+ datesMap);
            memberSinceDateMap.put(plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId,datesMap);
        }
        System.debug('memberSinceDateMap ' + memberSinceDateMap);

        //THE RENEWAL DISCOUNTS IN PROD WERE CREATED FROM 01/01/2025 GRANTING THE 1ST RENEWALS FOR MEMBERS WITH START DATE <=01/01/24. 
        Date firstRenewalDate = Date.newInstance(2024,01,01);

        for(Id memberId: memberSinceDateMap.keySet()){
            Map<String,Date> datesMap = memberSinceDateMap.containsKey(memberId)? memberSinceDateMap.get(memberId): new Map<String,Date>();
            if(!datesMap.isEmpty() &&  datesMap.containsKey('sinceDate')) {
                Account pa = new Account(Id = memberId);
                pa.ARC_ContinuousMembershipStartDate__c = datesMap.get('sinceDate') < firstRenewalDate? firstRenewalDate : datesMap.get('sinceDate');
                paToUpdate.add(pa);
            }
        }
        System.debug('UPDATED: '+paToUpdate);
        try{
            update paToUpdate;
        }
        catch(Exception e){
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_SinceDateBatch: '+e.getMessage()), 'ERROR ARC_SinceDateBatch', 'christian.fortunato@arcsona.com');
        }
    }

    global void finish(Database.BatchableContext BC){
        System.debug('Finished running batch job');
    }

}