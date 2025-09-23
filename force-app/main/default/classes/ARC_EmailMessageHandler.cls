public without sharing class ARC_EmailMessageHandler {

    public static void stampAgeUpNotification(List<EmailMessage>emList) {
        Map<Id,EmailMessage> primaryAccountEmailsMap = new Map<Id,EmailMessage>();
        for(EmailMessage em : emList) {
            primaryAccountEmailsMap.put(em.ARC_PersonAccount__c,em);
        }
        List<Ages_Up__c> ageUps = [SELECT Id, ARC_FirstNotification__c, ARC_SecondNotification__c, ARC_FinalNotification__c, ARC_Account__c, ARC_Account__r.ARC_PrimaryMemberAccount__c FROM Ages_Up__c WHERE ARC_Account__c IN:primaryAccountEmailsMap.keySet() OR ARC_Account__r.ARC_PrimaryMemberAccount__c IN:primaryAccountEmailsMap.keySet() ORDER BY CreatedDate DESC];
        List<Ages_Up__c> ageUpsToUpdate = new List<Ages_Up__c>();
        if(ageUps.size()>0){
            for(Ages_Up__c ageUp:ageUps){
                EmailMessage em;
                if(ageUp.ARC_Account__r?.ARC_PrimaryMemberAccount__c != null){
                    em = primaryAccountEmailsMap.get(ageUp.ARC_Account__r.ARC_PrimaryMemberAccount__c);
                }
                else {
                    em = primaryAccountEmailsMap.get(ageUp.ARC_Account__c);
                }
                if(em != null){
                    if(em.subject.contains('Notice of upcoming change to your WeShare monthly sharing amount')) ageUp.ARC_FirstNotification__c = Date.Today();
                    else if(em.TextBody != null && em.TextBody.contains('final')) ageUp.ARC_FinalNotification__c = Date.Today();
                    else ageUp.ARC_SecondNotification__c = Date.Today();
                    ageUpsToUpdate.add(ageUp);
                }
            }
            try{
                if(ageUpsToUpdate.size()>0) update ageUpsToUpdate;
            }catch(Exception e){
                String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
                ARC_QueableSendFileBatch.sendEmailNotification(('ARC_EmailMessageHandler error : '+e.getMessage()), 'ERROR in Email Message Handler', apexErrorEmail);
            }
        }

    }
}