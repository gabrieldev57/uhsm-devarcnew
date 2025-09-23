@isTest
private class ARC_EmailNotificationTest {

    @isTest
    static void sendErrorTest() {
        String subject = 'Test Subject';
        String body = 'Test Body';

        Test.startTest();
        ARC_EmailNotification.sendError(subject, body);
        Test.stopTest();
    }

    @isTest
    static void sendEmailTest() {
        String subject = 'Test Subject';
        String body = 'Test Body';
        Test.startTest();
        ARC_EmailNotification.sendEmail(subject, body);
        Test.stopTest();
    }

}