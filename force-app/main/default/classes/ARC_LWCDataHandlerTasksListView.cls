public with sharing class ARC_LWCDataHandlerTasksListView {
    @AuraEnabled (cacheable=true)
    public static List<Task> getTasks(Id CaseId){
        return [SELECT Id, Subject, ActivityDate, Owner.Name, Description, CreatedDate, CompletedDateTime, LastModifiedDate,Case_Type1__c,Case_Reason1__c, Priority, Status, Whatid FROM Task WHERE Whatid =:CaseId ORDER BY LastModifiedDate DESC];
    }
}