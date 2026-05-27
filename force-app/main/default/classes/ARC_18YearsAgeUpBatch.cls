global with sharing class ARC_18YearsAgeUpBatch implements Database.Batchable<SObject>, Schedulable {

    global void execute(SchedulableContext sc){
        ARC_18YearsAgeUpBatch b = new ARC_18YearsAgeUpBatch(); 
        Database.executeBatch(b);
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
            SELECT Id, Name, vlocity_ins__FirstName__c, vlocity_ins__Birthdate__c,
                   ARC_Age__c, vlocity_ins__CensusId__c,
                   vlocity_ins__CensusId__r.ARC_PrimaryAccount__c
            FROM vlocity_ins__GroupCensusMember__c 
            WHERE vlocity_ins__CensusId__r.ARC_CountChildren__c >= 1 
            AND vlocity_ins__CensusId__r.ARC_GuardianAccount__c != null 
            AND ARC_ActiveMember__c = true 
            AND vlocity_ins__CensusId__r.ARC_IsChildFamily__c = true 
            AND vlocity_ins__IsPrimaryMember__c = true 
            AND ARC_Age__c >= 18
            AND ARC_GroupCensusRecordTypeName__c = 'ARC_IndividualAndFamily'
        ]);
    }

    global void execute(Database.BatchableContext BC, List<vlocity_ins__GroupCensusMember__c> primaryMembers){

        try {

            Id serviceCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
            Id outboundQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'Outbound' AND Type = 'Queue' LIMIT 1].Id;

            Set<Id> primaryAccountIds = new Set<Id>();
            for (vlocity_ins__GroupCensusMember__c m : primaryMembers){
                if (m.vlocity_ins__CensusId__r.ARC_PrimaryAccount__c != null){
                    primaryAccountIds.add(m.vlocity_ins__CensusId__r.ARC_PrimaryAccount__c);
                }
            }

            Map<Id, Case> existingCasesMap = new Map<Id, Case>();
            if (!primaryAccountIds.isEmpty()){
                for (Case c : [
                    SELECT Id, ARC_PersonAccount__c
                    FROM Case
                    WHERE ARC_PersonAccount__c IN :primaryAccountIds
                    AND Case_Type__c = 'Program'
                    AND ARC_Reason__c = 'Age Out'
                    AND Subject = 'Age Out 18 Approaching'
                ]) {
                    existingCasesMap.put(c.ARC_PersonAccount__c, c);
                }
            }

            List<Case> casesToInsert = new List<Case>();

            for (vlocity_ins__GroupCensusMember__c m : primaryMembers){

                Id primaryAcc = m.vlocity_ins__CensusId__r.ARC_PrimaryAccount__c;

                if (primaryAcc != null && !existingCasesMap.containsKey(primaryAcc)){

                    Case newCase = new Case(
                        RecordTypeId = serviceCaseRecordTypeId,
                        Case_Type__c = 'Program',
                        ARC_Reason__c = 'Age Out',
                        Subject = 'Age Out 18 Approaching',
                        Description = 'Age Out Approaching',
                        Status = 'New',
                        OwnerId = outboundQueueId,
                        ARC_CensusMember__c = m.Id,
                        ARC_PersonAccount__c = primaryAcc,
                        ARC_Type__c = 'Member',
                        Origin = 'System'
                    );

                    casesToInsert.add(newCase);
                }
            }

            if (!casesToInsert.isEmpty()){
                insert casesToInsert;
            }

        } catch(Exception e) {
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification('Error in ARC_18YearsAgeUpBatch: ' + e.getMessage(), 'ERROR ARC_18YearsAgeUpBatch', apexErrorEmail);
            System.debug('ERROR ARC_18YearsAgeUpBatch: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext BC){
        System.debug('Batch ARC_18YearsAgeUpBatch completado.');
    }
}