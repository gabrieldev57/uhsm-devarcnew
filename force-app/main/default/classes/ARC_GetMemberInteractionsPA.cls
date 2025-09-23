public with sharing class ARC_GetMemberInteractionsPA {
    @AuraEnabled
    public static List<Map<String, Object>> getInteractions(Id recordId) {
        List<Map<String, Object>> interactionListMap = new List<Map<String, Object>>();
        List<ARC_MemberInteraction__c> interactions = [
            SELECT Id, 
            Name, 
            Date__c, 
            Status__c, 
            Type__c, 
            E123_User__c, 
            Description__c, 
            Notes__c 
            FROM ARC_MemberInteraction__c
            WHERE MemberId__r.vlocity_ins__ContactId__r.AccountId = :recordId
            ];
        for (ARC_MemberInteraction__c interaction : interactions) {
            Map<String, Object> interactionsMap = new Map<String, Object>();
            interactionsMap.put('id',interaction.Id);
            interactionsMap.put('idURL', '/' + interaction.Id);
            interactionsMap.put('Name',interaction.Name);
            interactionsMap.put('Date',interaction.Date__c);
            interactionsMap.put('Status',interaction.Status__c);
            interactionsMap.put('Type',interaction.Type__c);
            interactionsMap.put('E123 User',interaction.E123_User__c);
            interactionsMap.put('Description',interaction.Description__c);
            interactionsMap.put('Notes',interaction.Notes__c);
            interactionListMap.add(interactionsMap);
        }
        return interactionListMap;
    }
}