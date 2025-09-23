public without sharing class ARC_AgeUpReportController {

    private static List<Integer> ageUpNotificationNumbers = new List<Integer>{60,30,14};

    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> getAgeUpsData(){
        List<Map<String,Object>> result = new List<Map<String,Object>>();
        Map<Id,Map<String,Object>> primaryMemberResultMap = new Map<Id,Map<String,Object>>();
        
        List<Ages_Up__c> ageUps = [SELECT ID, ARC_Account__c,ARC_Account__r.Name,ARC_Account__r.PersonBirthdate,ARC_EffectiveDate__c,ARC_PriceAfterAgeUp__c,ARC_PriceBeforeAgeUp__c, Contract__r.ARC_TotalPrice__c, ARC_Applied__c, Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__c, Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.Census_Member__c FROM Ages_Up__c WHERE ARC_Account__c != null AND Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__c!= null LIMIT 100];

        Set<Id> primaryAccounts = new Set<Id>();

        for(Ages_Up__c ageUp: ageUps){
            Map<String,Object> memberMap = new Map<String,Object>();
            //Get the Primary Member
            primaryAccounts.add(ageUp.Contract__r?.vlocity_ins__EnrollmentCensusId__r?.ARC_PrimaryAccount__c);            
            //Get the Olderst Member
            memberMap.put('recordId',ageUp.Id);
            memberMap.put('OldestMemberId',ageUp.ARC_Account__c);
            memberMap.put('oldestMember',ageUp.ARC_Account__r.Name);
            if(ageUp.ARC_Account__r.PersonBirthdate != null) memberMap.put('birthdate',ageUp.ARC_Account__r.PersonBirthdate);
            if(ageUp.ARC_EffectiveDate__c != null){
                memberMap.put('effectiveDate',ageUp.ARC_EffectiveDate__c);
                memberMap.put('remainingDays',Date.today().daysBetween(ageUp.ARC_EffectiveDate__c));
            } 
            if(ageUp.ARC_PriceAfterAgeUp__c != null) memberMap.put('newPrice',ageUp.ARC_PriceAfterAgeUp__c);
            if(ageUp.ARC_PriceBeforeAgeUp__c != null) memberMap.put('oldPrice',ageUp.ARC_PriceBeforeAgeUp__c);
            if(ageUp.Contract__r?.ARC_TotalPrice__c != null) memberMap.put('contractTotalPrice',ageUp.Contract__r.ARC_TotalPrice__c);
            if(ageUp.ARC_Applied__c!= null) memberMap.put('isApplied',ageUp.ARC_Applied__c);
            primaryMemberResultMap.put(ageUp.Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__c,memberMap);
        }

        List<EmailMessage> emailList = [SELECT Id,ARC_PersonAccount__c,ARC_CensusMember__r.vlocity_ins__ContactId__r.AccountId, Subject, TextBody FROM EmailMessage WHERE (ARC_CensusMember__r.vlocity_ins__ContactId__r.AccountId IN: primaryAccounts OR ARC_PersonAccount__c IN :primaryAccounts) AND (Subject LIKE 'Reminder of upcoming change to your WeShare monthly sharing amount' OR Subject LIKE 'Notice of upcoming change to your WeShare monthly sharing amount')];
        
        Map<Id, Map<Integer,Boolean>> memberEmails = new Map<Id,Map<Integer,Boolean>>();

        for(EmailMessage em: emailList){
            Id memberId;
            if(em.ARC_CensusMember__r?.vlocity_ins__ContactId__r?.AccountId != null){
                memberId = em.ARC_CensusMember__r?.vlocity_ins__ContactId__r.AccountId;
            }
            else if(em.ARC_PersonAccount__c != null){
                memberId = em.ARC_PersonAccount__c;
            }
            Map<Integer,Boolean> memberEmailsMap = memberEmails.containsKey(memberId)? memberEmails.get(memberId) : new Map<Integer,Boolean>();
            Integer notificationnumber = getEmailNotificationNumber(em);
            memberEmailsMap.put(notificationnumber,true);
            memberEmails.put(memberId,memberEmailsMap);
        }

        for(Id primaryMemberId: primaryMemberResultMap.keySet()){
            Map<String,Object> memberMap = primaryMemberResultMap.get(primaryMemberId);
            Map<Integer,Boolean> memberEmailsMap = memberEmails.containsKey(primaryMemberId)? memberEmails.get(primaryMemberId) : new Map<Integer,Boolean>();
            for(Integer num:ageUpNotificationNumbers){
                switch on num {
                    when 60  {
                        if(memberEmailsMap.containsKey(num)){
                            memberMap.put('firstNotification',true);
                        }
                        else memberMap.put('firstNotification',false);
                    }
                    when 14  {
                        if(memberEmailsMap.containsKey(num)){
                            memberMap.put('finalNotification',true);
                        }
                        else memberMap.put('finalNotification',false);
                    }
                    when else  {
                        if(memberEmailsMap.containsKey(num)){
                            memberMap.put('secondNotification',true);
                        }
                        else memberMap.put('secondNotification',false);
                    }
                }
            }
            
        }
        return primaryMemberResultMap.values();
    }

    public static Integer getEmailNotificationNumber(EmailMessage em){
        if(em.subject.contains('Notice of upcoming change to your WeShare monthly sharing amount')) return 60;
        else if(em.TextBody != null && em.TextBody.contains('final')) return 14;
        else return 30;
    }
}