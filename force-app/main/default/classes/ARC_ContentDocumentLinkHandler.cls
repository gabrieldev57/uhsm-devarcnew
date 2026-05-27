public without sharing class ARC_ContentDocumentLinkHandler {

    public static void handleAfterInsert(List<ContentDocumentLink> newRecords) {
        
        Set<Id> caseIds = new Set<Id>();

        for (ContentDocumentLink cdl : newRecords) {
            if (cdl.LinkedEntityId != null &&
                String.valueOf(cdl.LinkedEntityId).startsWith('500')) {
                caseIds.add(cdl.LinkedEntityId);
            }
        }

        if (caseIds.isEmpty()) return;

        System.enqueueJob(new ARC_CaseProcessorQueueable(caseIds));
    }

    public class ARC_CaseProcessorQueueable implements Queueable {
        
        private Set<Id> caseIds;
        
        public ARC_CaseProcessorQueueable(Set<Id> caseIds) {
            this.caseIds = caseIds;
        }
        
        public void execute(QueueableContext context) {
            processCasesAfterUpload(caseIds);
        }
    }

    private static void processCasesAfterUpload(Set<Id> caseIds) {
        
        RecordType smallGroupRT = [
            SELECT Id 
            FROM RecordType 
            WHERE SobjectType = 'Case' 
            AND DeveloperName = 'ARC_SmallGroupUnderwriting' 
            LIMIT 1
        ];
        
        List<Case> cases = [
            SELECT Id, CaseNumber, Status, OwnerId, Account.Name, Owner.Email
            FROM Case
            WHERE Id IN :caseIds 
            AND RecordTypeId = :smallGroupRT.Id
        ];

        if (cases.isEmpty()) return;

        List<Case> casesToUpdate = new List<Case>();
        for (Case c : cases) {
            if(c.Status == 'New'){
                c.Status = 'In Progress';
                casesToUpdate.add(c);
            }
        }

        sendCustomNotifications(cases);
        sendEmails(cases);
        
        if (!casesToUpdate.isEmpty()) {
            try {
                update casesToUpdate;

            } catch (Exception e) {
                System.debug('Error updating cases or sending notifications: ' + e.getMessage());
            }
        }
    }

    

    // private static void sendEmails(List<Case> cases) {
    //     if (cases.isEmpty()) return;

    //     try {
    //         List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    //         for (Case c : cases) {
    //             Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
    //             mail.setTargetObjectId(c.OwnerId);
    //             mail.setSubject('Census Submitted – Ready for Review');
                
    //             String body = 'Hello,\n\n';
    //             body += 'The employer has successfully submitted the census form.\n\n';
    //             body += 'Case Number: ' + c.CaseNumber + '\n';
    //             body += 'Employer: ' + c.Account.Name + '\n\n';
    //             body += 'The case status has been updated To Review and is now ready for your review.\n\n';
    //             body += 'Thank you.';
                
    //             mail.setPlainTextBody(body);
    //             mail.setWhatId(c.Id);  
    //             mail.setSaveAsActivity(false);  
                
    //             emails.add(mail);
    //         }

    //         if (!emails.isEmpty()) {
    //             Messaging.sendEmail(emails);
    //             System.debug('sent emails: ' + emails.size());
    //         }
            
    //     } catch (Exception e) {
    //         System.debug('Error sending emails: ' + e.getMessage());
    //     }
    // }
    private static void sendEmails(List<Case> cases) {
        if (cases.isEmpty()) return;
        ARC_SGEmails.sendEmails(cases);
    }

    private static void sendCustomNotifications(List<Case> cases) {
        if (cases.isEmpty()) return;

        try {
            CustomNotificationType notifType = [
                SELECT Id 
                FROM CustomNotificationType 
                WHERE DeveloperName = 'ARC_SendCaseNotification'
                LIMIT 1
            ];

            for (Case c : cases) {
                
                Messaging.CustomNotification notif = new Messaging.CustomNotification();
                notif.setNotificationTypeId(notifType.Id);
                notif.setTargetId(c.Id);
                notif.setTitle('Case Updated ' + c.Account.Name);
                notif.setBody('The Census form was submitted on case ' + c.CaseNumber + ' and is ready for review.');
                
                notif.send(new Set<String>{c.OwnerId});
            }
        } catch (Exception e) {
            System.debug('Error sending notifications: ' + e.getMessage());
        }
    }
}