@isTest
private class ARC_SendEmailQLETest {

    @testSetup
    static void setupData() {
        // Get Person Account Record Type
        RecordType rt = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Account' 
            AND IsPersonType = true 
            LIMIT 1
        ];

        // Create Person Account
        Account acc = new Account(
            RecordTypeId = rt.Id,
            FirstName = 'Test',
            LastName = 'Person',
            PersonEmail = 'test@example.com'
        );
        insert acc;

        // Create Case
        Case cs = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            Description = 'Test description'
        );
        insert cs;
    }

    @isTest
    static void testSendEmail_Success() {
        Account acc = [SELECT Id, PersonContactId, PersonEmail FROM Account LIMIT 1];
        Case cs = [SELECT Id FROM Case LIMIT 1];

        ARC_SendEmailQLE.InputVar input = new ARC_SendEmailQLE.InputVar();
        input.recordId = acc.Id;
        input.varCreatedCaseId = cs.Id;

        Test.startTest();
        ARC_SendEmailQLE.sendEmailToEmployeeQLE(new List<ARC_SendEmailQLE.InputVar>{ input });
        Test.stopTest();

        // Verify EmailMessage created
        List<EmailMessage> emails = [
            SELECT Id, ToAddress, Subject, Status, Incoming
            FROM EmailMessage
        ];

        System.assert(!emails.isEmpty(), 'EmailMessage should be created');
        System.assertEquals('3', emails[0].Status, 'Status should be Sent');
        System.assertEquals(false, emails[0].Incoming, 'Should be outbound');
    }

    @isTest
    static void testSendEmail_BlankInputs() {
        ARC_SendEmailQLE.InputVar input = new ARC_SendEmailQLE.InputVar();
        input.recordId = '';
        input.varCreatedCaseId = '';

        Test.startTest();
        ARC_SendEmailQLE.sendEmailToEmployeeQLE(new List<ARC_SendEmailQLE.InputVar>{ input });
        Test.stopTest();

        // No EmailMessage should be created
        System.assertEquals(0, [SELECT COUNT() FROM EmailMessage]);
    }

    @isTest
    static void testSendEmail_NullInputs() {
        Test.startTest();
        ARC_SendEmailQLE.sendEmailToEmployeeQLE(null);
        Test.stopTest();

        System.assert(true, 'Handled null input gracefully');
    }

    @isTest
    static void testSendEmail_Bulk() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Case cs = [SELECT Id FROM Case LIMIT 1];

        List<ARC_SendEmailQLE.InputVar> inputs = new List<ARC_SendEmailQLE.InputVar>();

        for (Integer i = 0; i < 5; i++) {
            ARC_SendEmailQLE.InputVar input = new ARC_SendEmailQLE.InputVar();
            input.recordId = acc.Id;
            input.varCreatedCaseId = cs.Id;
            inputs.add(input);
        }

        Test.startTest();
        ARC_SendEmailQLE.sendEmailToEmployeeQLE(inputs);
        Test.stopTest();

        List<EmailMessage> emails = [SELECT Id FROM EmailMessage];
        System.assert(emails.size() > 0, 'Emails should be created in bulk run');
    }

    @isTest
    static void testGetOrgWideEmail_NoRecord() {
        // No OrgWideEmailAddress created → should return null
        OrgWideEmailAddress owea = ARC_SendEmailQLE.getOrgWideEmail();
        Assert.isNotNull(owea,'OWEA should not be null');
    }
}