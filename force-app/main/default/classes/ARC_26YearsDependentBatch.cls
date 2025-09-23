global class ARC_26YearsDependentBatch implements Database.Batchable<sObject>,Schedulable{

    global void execute(SchedulableContext sc) {
        ARC_26YearsDependentBatch b = new ARC_26YearsDependentBatch(); 
        database.executebatch(b);
    }

    public static List<Object> memberIds = new List<Object>();
 
    global Database.QueryLocator start(Database.BatchableContext BC){

        return Database.getQueryLocator([
            SELECT Id,vlocity_ins__Birthdate__c, Name, vlocity_ins__RelatedCensusMemberId__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE ARC_Age__c = 25
            AND ARC_ActiveMember__c = true
            AND vlocity_ins__IsPrimaryMember__c = false
            AND vlocity_ins__IsSpouse__c = false
        ]);

    }
 
    global void execute(Database.BatchableContext BC, List<vlocity_ins__GroupCensusMember__c> members){
        Id serviceCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
        Id outboundQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'Outbound' AND Type = 'Queue' LIMIT 1].Id;
        
        Set<Id> primaryMemberIds = new Set<Id>();
        for(vlocity_ins__GroupCensusMember__c member : members) {
            primaryMemberIds.add(member.vlocity_ins__RelatedCensusMemberId__c != null ? member.vlocity_ins__RelatedCensusMemberId__c : member.Id);
        }
        
        Map<Id, Case> existingCases = new Map<Id, Case>();
        for(Case c : [SELECT Id, ARC_CensusMember__c 
                    FROM Case 
                    WHERE ARC_CensusMember__c IN :primaryMemberIds 
                    AND Case_Type__c = 'Program' 
                    AND ARC_Reason__c = 'Age Out'
                    AND Subject = 'Age Out 26 Approaching'
                    AND Status != 'Closed' ]) {
            existingCases.put(c.ARC_CensusMember__c, c);
        }
        
        Map<Id,Case> memberCase = new Map<Id,Case>();
        Date today = Date.today();

        for (vlocity_ins__GroupCensusMember__c member : members) {
            Date birthdate = member.vlocity_ins__Birthdate__c;
            Integer age = 26;
            Date nextBirthday = birthdate.addYears(age) < today ? birthdate.addYears(age + 1) : birthdate.addYears(age);
            Integer daysUntilBirthday = today.daysBetween(nextBirthday);
            Id primaryMemberId = member.vlocity_ins__RelatedCensusMemberId__c != null ? 
                                member.vlocity_ins__RelatedCensusMemberId__c : member.Id;
            
            if (daysUntilBirthday == 20 || daysUntilBirthday == 10 || daysUntilBirthday == 4) {
                memberIds.add(member.Id);
                if(!existingCases.containsKey(primaryMemberId)) {
                    Case newCase = new Case(
                        RecordTypeId = serviceCaseRecordTypeId,
                        Case_Type__c = 'Program',
                        ARC_Reason__c = 'Age Out',
                        Subject = 'Age Out 26 Approaching',
                        Description = 'Age Out Approaching',
                        Status = 'New',
                        OwnerId = outboundQueueId,
                        ARC_CensusMember__c = primaryMemberId,
                        ARC_Type__c = 'Member',
                        Origin = 'System'
                    );
                    memberCase.put(primaryMemberId, newCase);
                }
            }
        }
        insert memberCase.values();
        for(Case c : existingCases.values()) {
            c.OwnerId = outboundQueueId;
        }
        for (vlocity_ins__GroupCensusMember__c member : members) {
            Date birthdate = member.vlocity_ins__Birthdate__c;
            Integer age = 26;
            Date nextBirthday = birthdate.addYears(age) < today ? birthdate.addYears(age + 1) : birthdate.addYears(age);
            Integer daysUntilBirthday = today.daysBetween(nextBirthday);
            Id primaryMemberId = member.vlocity_ins__RelatedCensusMemberId__c != null ? 
                                member.vlocity_ins__RelatedCensusMemberId__c : member.Id;
            if (daysUntilBirthday == 20 || daysUntilBirthday == 10 || daysUntilBirthday == 4) {
                if(existingCases.containsKey(primaryMemberId)) {
                    memberCase.put(primaryMemberId, existingCases.get(primaryMemberId));
                }
            }
        }

        if (!memberIds.isEmpty()) {
            try {
                Map<String,Object> emailParams = new Map<String,Object>();
                emailParams.put('censusMemberIds', memberIds);
                emailParams.put('memberCase', memberCase);
                ARC_Emails.email_14(emailParams, new Map<String,Object>(), new Map<String,Object>());
            } catch (Exception e) {
                System.debug(e);
                ARC_Emails.sendErrorMessage(e.getMessage(), e.getLineNumber(), 'ARC_26YearsDependentBatch.email_14',String.valueOf(memberIds));
            }
        }
        update memberCase.values();
    }
 
    global void finish(Database.BatchableContext BC){
    }
}