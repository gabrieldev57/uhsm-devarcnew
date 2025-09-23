public with sharing class ARC_groupCensusMembersPlansPA {
    @AuraEnabled
    public static List<Map<String, Object>> getCensusMemberPlan(Id recordId) {
        List<Map<String, Object>> gcmpListMap = new List<Map<String, Object>>();
        List<vlocity_ins__GroupCensusMemberPlan__c> groupCensusMemberPlans = [
            SELECT Id, 
            ARC_Active__c,
            Name          
            FROM vlocity_ins__GroupCensusMemberPlan__c
            WHERE vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId = :recordId
            ];
        for (vlocity_ins__GroupCensusMemberPlan__c gcmp : groupCensusMemberPlans) {
            Map<String, Object> memberPlanMap = new Map<String, Object>();
            memberPlanMap.put('id',gcmp.Id);
            memberPlanMap.put('idURL', '/' + gcmp.Id);
            memberPlanMap.put('Active',gcmp.ARC_Active__c);
            memberPlanMap.put('Name',gcmp.Name);
            gcmpListMap.add(memberPlanMap);
        }
        return gcmpListMap;
    }
}