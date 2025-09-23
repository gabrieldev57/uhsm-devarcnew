public with sharing class ARC_EmailSenderTriggerHandler {
    
    public static void onBeforeInsert(List<ARC_Email__c> TriggerNew) {
        Set<Id> emailCampaignId = new Set<Id>();
        List<String> templatesList = new List<String>();
        Map<String, EmailTemplate> templateMap = new Map<String, EmailTemplate>();
        OrgWideEmailAddress fromAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 1];
        for (ARC_Email__c email : TriggerNew) {
            emailCampaignId.add(email.ARC_Email_Campaign__c);
        }
        List<ARC_EmailCampaign__c> emailCamp = [SELECT ARC_Template__c,ARC_AutoEmail__c, ARC_EmailsSent__c FROM ARC_EmailCampaign__c WHERE Id IN :emailCampaignId];
        for (ARC_EmailCampaign__c camp : emailCamp) {
            templatesList.add(camp.ARC_Template__c);
        }
        for (EmailTemplate template : [SELECT Id, Name, HtmlValue, Subject, Body, Markup FROM EmailTemplate WHERE Name IN :templatesList]) {
            templateMap.put(template.Name, template);
        }

        for(ARC_Email__c newEmail : TriggerNew) {
            for (ARC_EmailCampaign__c camp : emailCamp) {
                if(camp.ARC_AutoEmail__c){
                    String emailReciever = newEmail.ARC_EmailReciever__c;
                    String sender = newEmail.ARC_From__c;
                    //String template = camp.ARC_Template__c;
                    EmailTemplate template = new EmailTemplate();
                    for (String temp : templateMap.keySet()) {
                        if (temp == camp.ARC_Template__c) {
                            template = templateMap.get(temp);
                        }
                    }
                    String cc = newEmail.ARC_EmailCC__c;
                    Id ObjectId = Id.valueOf(newEmail.ARC_ObjectId__c);
                    newEmail.ARC_Status__c = 'Sent';
                    ARC_SendEmailHelper.sendEmail(sender,emailReciever, template, cc, ObjectId, fromAddress);
                    camp.ARC_EmailsSent__c = camp.ARC_EmailsSent__c + 1;
                }    
            }
        }
        update emailCamp;
    }

    public static void updateEmailsSent(List<ARC_Email__c> insertedEmails) {
        Set<Id> emailCampaignId = new Set<Id>();
        List<String> templatesList = new List<String>();
        Map<String, EmailTemplate> templateMap = new Map<String, EmailTemplate>();
        OrgWideEmailAddress fromAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 1];
        for (ARC_Email__c email : insertedEmails) {
            emailCampaignId.add(email.ARC_Email_Campaign__c);
        }
        List<ARC_EmailCampaign__c> emailCamp = [SELECT ARC_Template__c, ARC_EmailsSent__c FROM ARC_EmailCampaign__c WHERE Id IN :emailCampaignId];
        for (ARC_EmailCampaign__c camp : emailCamp) {
            templatesList.add(camp.ARC_Template__c);
        }
        for (EmailTemplate template : [SELECT Id, Name, HtmlValue, Subject, Body, Markup FROM EmailTemplate WHERE Name IN :templatesList]) {
            templateMap.put(template.Name, template);
        }
        for (ARC_Email__c current : insertedEmails) {
            for (ARC_EmailCampaign__c camp : emailCamp) {
                if (current.ARC_ManuallySend__c) {
                    String emailReciver = current.ARC_EmailReciever__c;
                    String sender = current.ARC_From__c;
                    //String template = camp.ARC_Template__c;
                    EmailTemplate template = new EmailTemplate();
                    for (String temp : templateMap.keySet()) {
                        if (temp == camp.ARC_Template__c) {
                            template = templateMap.get(temp);
                        }
                    }
                    String cc = current.ARC_EmailCC__c;
                    Id ObjectId = Id.valueOf(current.ARC_ObjectId__c);
                    ARC_SendEmailHelper.sendEmail(sender,emailReciver, template, cc, ObjectId, fromAddress);
                    camp.ARC_EmailsSent__c = camp.ARC_EmailsSent__c + 1;    
                }
            }
        }
        update emailCamp;
    }
}