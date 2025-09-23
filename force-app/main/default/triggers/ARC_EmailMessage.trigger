trigger ARC_EmailMessage on EmailMessage (after insert) {
    
    If(Trigger.isAfter && Trigger.isInsert){
        List<EmailMessage> emList = new List<EmailMessage>();
        //Get the Subject of the Age Up Notifications
        String ageUpSubjects = System.Label.ARC_AgeUpNotificationSubjects;
        for(EmailMessage em:Trigger.new){
            if(!em.isBounced && em.ARC_PersonAccount__c != null && em.Subject != null && ageUpSubjects.contains(em.subject)){
                emList.add(em);
            }
        }
        if(!emList.isEmpty())ARC_EmailMessageHandler.stampAgeUpNotification(emList);
    }
}