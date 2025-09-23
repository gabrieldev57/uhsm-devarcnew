public without sharing class ARC_EmailNotification  {
    //MyCustomClass.someMethod();

    //Sends an error email using a predefined template for the message body.
    public static void sendError(String subject, String body) {
        List<String> emailAddresses = getCustomLabelEmailAddresses();
        body = errorTemplate(body);
        // System.enqueueJob(new ARC_EmailNotification(emailAddresses, subject, body));
        sendEmail(emailAddresses, subject, body);
    }

    //Sends an email with the specified subject and body.
    @future
    public static void sendEmail(String subject, String body) {
        List<String> emailAddresses = getCustomLabelEmailAddresses();
        // System.enqueueJob(new ARC_EmailNotification(emailAddresses, subject, body));
        sendEmail(emailAddresses, subject, body);
    }

    // Sends an email to the specified email addresses.
    private static void sendEmail(String[] toAddresses, String subject, String body) {
        try {            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setSubject(subject);
            mail.setPlainTextBody(body);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
        }
    }

    // Retrieves email addresses from a custom label ARC_EmailNotificationAddress.
    public static List<String> getCustomLabelEmailAddresses() {
        String emailAddresses = Label.ARC_EmailNotificationAddress;
        List<String> emailAddressesList = new List<String>();
        for(String emailAddress : emailAddresses.split(',')) {
            emailAddressesList.add(emailAddress.trim());
        }
        return emailAddressesList;
    }

    //Generates the error message body using a predefined template.
    private static String errorTemplate(String errorMessage){
        String body = 'An Error has occurred. Please see the details below: \n\n'+
                    [SELECT Name FROM Organization LIMIT 1] + 
                    '\n' +
                    'UserId: ' + UserInfo.getUserId() + 
                    '\n' + 
                    'Date: ' + Datetime.now() + 
                    '\n\n\n' +
                    'Error Message:' +
                    '\n\n' +
                    errorMessage;
        return body;
    }
    

}