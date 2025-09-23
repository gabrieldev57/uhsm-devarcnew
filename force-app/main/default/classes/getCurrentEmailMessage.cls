public without sharing class getCurrentEmailMessage {

    @AuraEnabled(cacheable=true)
    public static List<EmailMessage> getCurrentEmailMessage(Id recordId) {

        List<EmailMessage> emailMess= [SELECT Id,FromAddress,Type__c,ToAddress,Subject,RelatedToId,HtmlBody,TextBody,CreatedDate,MessageDate,CreatedById,CreatedBy.Name  FROM EmailMessage WHERE ARC_CensusMember__c = :recordId ORDER BY MessageDate DESC ];
        
        return emailMess;

    }
    // @AuraEnabled
    // public static void deleteRecord(Id recordId){
    //     EmailMessage e = new EmailMessage(id = recordId);

    //     if(EmailMessage.sObjectType.getDescribe().isDeletable()){
    //         delete e;
    //     }
            
        
            
            
        
        
    // }
}