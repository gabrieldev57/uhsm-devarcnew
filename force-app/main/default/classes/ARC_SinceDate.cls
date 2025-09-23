public without sharing class ARC_SinceDate {


    public static Date getSinceDate(List<Id> recordIds) {
        System.debug(recordIds);

        Map<Id,Map<String,Date>> memberSinceDateMap = new Map<Id,Map<String,Date>>();


        //Get All the Medical GCMP of current member 
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpRelatedToCm = Database.query(
            'SELECT vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId '+
            'FROM vlocity_ins__GroupCensusMemberPlan__c ' +
            'WHERE vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId IN :recordIds '+
            'AND (vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = \'Medical\' '+
                'AND vlocity_ins__ContractLineId__r.Name  LIKE \'WeShare%\' '+
                +')'+
            'AND ('+
                'vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = \'Activated\' '+
                'OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = \'Terminated\' '+
                ') '+
            'ORDER BY vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c ASC'
        );


        for(vlocity_ins__GroupCensusMemberPlan__c plan: gcmpRelatedToCm) {

            Map<String,Date> datesMap = memberSinceDateMap.containsKey(plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId)? memberSinceDateMap.get(plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId): new Map<String,Date>();
            System.debug('datesMap before'+ datesMap);
            System.debug('contract Effective Date - '+ plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c);
            
            if(!datesMap.containsKey('inactiveDate')){
                //Set Since Date
                datesMap.put('sinceDate', plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c);
                System.debug('Set SinceDate');
            }
            else if(datesMap.containsKey('inactiveDate')){
                System.debug('Inactive Date Add 1 Day - '+datesMap.get('inactiveDate').addDays(1));
                if(datesMap.get('inactiveDate').addDays(1) < plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c){
                    //Reset Since Date
                    datesMap.put('sinceDate', plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c);
                    System.debug('ReseSet SinceDate');
                }
            }
            if(plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status == 'Terminated') datesMap.put('inactiveDate', plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c);
            System.debug('datesMap after'+ datesMap);
            memberSinceDateMap.put(plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId,datesMap);
        }
        System.debug(memberSinceDateMap);
        return null;
    }

    public class ReturnVariables{
        public Id recordId;
        public Date sinceDate;
    }

    //[Status:Terminated, InactiveDate: 31 marzo, EffectiveDate: 1 enero], [Status:Terminated, InactiveDate: 31 junio, EffectiveDate: 1 abril], [Status:Activated, InactiveDate: null, EffectiveDate: 1 julio] --> SinceDate = 1 enero OK
    //[Status:Terminated, InactiveDate: 31 marzo, EffectiveDate: 1 enero], [Status:Terminated, InactiveDate: 31 junio, EffectiveDate:  1 mayo], [Status:Activated, InactiveDate: null, EffectiveDate: 1 julio] --> SinceDate = 1 mayo
    //[Status:Terminated, InactiveDate: 31 marzo, EffectiveDate: 1 enero], [Status:Terminated, InactiveDate: 31 junio, EffectiveDate: 1 abril], [Status:Activated, InactiveDate: null, EffectiveDate: 1 Agosto] --> SinceDate = 1 Agosto
    //[Status:Activated, InactiveDate: null, EffectiveDate: 1 julio] --> SinceDate = 1 julio
}