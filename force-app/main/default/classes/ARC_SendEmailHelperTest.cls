@isTest 
public with sharing class ARC_SendEmailHelperTest {
 
    @isTest 
    static void ARC_SendEmailHelperTest() {
        List<ARC_EmailCampaign__c> campaigns = ARC_TestUtility.createTestEmailCampaign(1);
        insert campaigns;
        List<Account> account = ARC_TestUtility.createTestAccount(1, 'StandardAccount');
        List<Contact> contact = ARC_TestUtility.createTestContact(1,'Contact');
        contact[0].accountId = account[0].Id;
        update contact;
        List<ARC_Email__c> emailsList = ARC_TestUtility.createEmails(campaigns[0],account[0].Id);
        insert emailsList;
        emailsList[0].ARC_EmailCC__c='aaa@test.com';
        update emailsList;
        Account onlyOneAccount = account[0];
        Map<String, EmailTemplate> templateMap = new Map<String, EmailTemplate>();
        OrgWideEmailAddress fromAddress = new OrgWideEmailAddress();
        fromAddress.Address = 'TestAddress';
        fromAddress.DisplayName = 'TestDisplay';

        EmailTemplate template = ARC_TestUtility.createEmailTemplate(account);
        
        test.startTest();
        for (ARC_Email__c current : emailsList) {
            current.ARC_ManuallySend__c = true;
            for (ARC_EmailCampaign__c camp : campaigns) {
                if (current.ARC_ManuallySend__c) {
                    String emailReciver = current.ARC_EmailReciever__c;
                    String sender = current.ARC_From__c;
                    // String template = camp.ARC_Template__c;
                    // EmailTemplate template = new EmailTemplate();
                    for (String temp : templateMap.keySet()) {
                        if (temp == camp.ARC_Template__c) {
                            template = templateMap.get(temp);
                        }
                    }
                    system.debug('currentObjectid :' + current.ARC_ObjectId__c);
                    system.debug('the template!: '+ template);
                    String cc = current.ARC_EmailCC__c;
                    Id ObjectId = contact[0].Id;
                    //Id ObjectId = Id.valueOf(current.ARC_ObjectId__c
                    ARC_SendEmailHelper.sendEmail(sender,emailReciver, template, cc, ObjectId, fromAddress);
					
                }
            }
        }
        test.stopTest();
        
        List<EmailMessage> emailMessage = [SELECT Id, Subject, TextBody FROM EmailMessage];
                    system.debug('emailMessage' + emailMessage);
        

    }
}