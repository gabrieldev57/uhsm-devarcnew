global class ARC_65YearsBatch implements Database.Batchable<sObject>,Schedulable{

    global void execute(SchedulableContext sc) {
        ARC_65YearsBatch b = new ARC_65YearsBatch(); 
        database.executebatch(b);
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
            SELECT Id, Name, vlocity_ins__FirstName__c, vlocity_ins__Birthdate__c,
                   ARC_Age__c, ARC_PhysicalAddressState__c, vlocity_ins__ContactId__r.Email,
                   vlocity_ins__CensusId__c, vlocity_ins__RelatedCensusMemberId__c,
                   vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__FirstName__c,
                   vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__r.Email
            FROM vlocity_ins__GroupCensusMember__c 
            WHERE ARC_Age__c = 64 AND ARC_ActiveMember__c = true
        ]);
    }
 
    global void execute(Database.BatchableContext BC, List<vlocity_ins__GroupCensusMember__c> members){
        Id serviceCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
        Id offboardingQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'Offboarding' AND Type = 'Queue' LIMIT 1].Id;
        
        Map<Id,Case> memberCase = new Map<Id,Case>();
        Date today = Date.today();

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
                    AND Subject = 'Age Out 65 Approaching'
                    AND Status != 'Closed']) {
            existingCases.put(c.ARC_CensusMember__c, c);
        }



        
        for (vlocity_ins__GroupCensusMember__c member : members) {
            Date birthdate = member.vlocity_ins__Birthdate__c;
            Integer age = 65; 
            Date nextBirthday = birthdate.addYears(age) < today ? birthdate.addYears(age + 1) : birthdate.addYears(age);
            Integer daysUntilBirthday = today.daysBetween(nextBirthday);
            Id primaryMemberId = member.vlocity_ins__RelatedCensusMemberId__c != null ? 
                                member.vlocity_ins__RelatedCensusMemberId__c : member.Id;
            
            if((daysUntilBirthday == 90 || daysUntilBirthday == 60 || daysUntilBirthday == 30)) {
                if(!existingCases.containsKey(primaryMemberId)) {
                    Case newCase = new Case(
                        RecordTypeId = serviceCaseRecordTypeId,
                        Case_Type__c = 'Program',
                        ARC_Reason__c = 'Age Out',
                        Subject = 'Age Out 65 Approaching',
                        Description = 'Age Out Approaching',
                        Status = 'New',
                        OwnerId = offboardingQueueId,
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
            c.OwnerId = offboardingQueueId;
        }
        for (vlocity_ins__GroupCensusMember__c member : members) {
            Date birthdate = member.vlocity_ins__Birthdate__c;
            Integer age = 65;
            Date nextBirthday = birthdate.addYears(age) < today ? birthdate.addYears(age + 1) : birthdate.addYears(age);
            Integer daysUntilBirthday = today.daysBetween(nextBirthday);
            Id primaryMemberId = member.vlocity_ins__RelatedCensusMemberId__c != null ? 
                                member.vlocity_ins__RelatedCensusMemberId__c : member.Id;
            if((daysUntilBirthday == 90 || daysUntilBirthday == 60 || daysUntilBirthday == 30)) {
                if(existingCases.containsKey(primaryMemberId)) {
                    memberCase.put(primaryMemberId, existingCases.get(primaryMemberId));
                }
            }
        }


        for (vlocity_ins__GroupCensusMember__c member : members) {
            Date birthdate = member.vlocity_ins__Birthdate__c;
            Integer age = 65; 
            Date nextBirthday = birthdate.addYears(age) < today ? birthdate.addYears(age + 1) : birthdate.addYears(age);
            Integer daysUntilBirthday = today.daysBetween(nextBirthday);
            
            Id primaryMemberId = member.vlocity_ins__RelatedCensusMemberId__c != null ? 
                                member.vlocity_ins__RelatedCensusMemberId__c : member.Id;
            
            if((daysUntilBirthday == 90 || daysUntilBirthday == 60 || daysUntilBirthday == 30) &&
                member.vlocity_ins__ContactId__r.Email != null &&
                member.ARC_PhysicalAddressState__c != null) {

                try {
                    Map<String,Object> params = new Map<String,Object>();
                    params.put('censusMember', member);
                    params.put('caseId', memberCase.get(primaryMemberId).Id);
                    ARC_Emails.email_12(params, new Map<String,Object>(), new Map<String,Object>());
                } catch (Exception e) {
                    ARC_Emails.sendErrorMessage(e.getMessage(), e.getLineNumber(), 'ARC_65YearsBatch.email_12', String.valueOf(primaryMemberId));
                }
            }
        }
        update memberCase.values();
    }
 
    global void finish(Database.BatchableContext BC){
    }
}