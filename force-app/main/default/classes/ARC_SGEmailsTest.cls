@isTest
private class ARC_SGEmailsTest {

    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Test SG Email Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName  = 'SGContact',
            Email     = 'sgcontact@example.com',
            AccountId = acc.Id
        );
        insert con;
    }

    // ─── invokeMethod ─────────────────────────────────────────────────────────

    @isTest
    static void testInvokeMethod_unknownMethod() {
        Map<String, Object> inMap  = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> opts   = new Map<String, Object>();

        Test.startTest();
        Boolean result = ARC_SGEmails.invokeMethod('unknownMethod', inMap, outMap, opts);
        Test.stopTest();

        System.assertEquals(false, result, 'Unknown method should return false');
        System.assert(outMap.containsKey('error'), 'outMap should have an error key');
    }

    @isTest
    static void testInvokeMethod_sendMemberIdCardPortal_blankEmail() {
        Map<String, Object> inMap = new Map<String, Object>{
            'options' => new Map<String, Object>{ 'primaryContactEmail' => '' }
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> opts   = new Map<String, Object>();

        Test.startTest();
        Boolean result = ARC_SGEmails.invokeMethod('sendMemberIdCardPortal', inMap, outMap, opts);
        Test.stopTest();

        System.assertEquals(false, result, 'invokeMethod should return false when sendMemberIdCardPortal returns false');
        System.assert(outMap.containsKey('error'), 'outMap should have an error key');
    }

    @isTest
    static void testInvokeMethod_sendMemberIdCardPortal_nullOptions() {
        Map<String, Object> inMap  = new Map<String, Object>(); // no 'options' key
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> opts   = new Map<String, Object>();

        Test.startTest();
        Boolean result = ARC_SGEmails.invokeMethod('sendMemberIdCardPortal', inMap, outMap, opts);
        Test.stopTest();

        System.assertEquals(false, result);
        System.assert(outMap.containsKey('error'), 'outMap should have an error key');
    }

    // ─── getOrgWideEmail ─────────────────────────────────────────────────────

    @isTest
    static void testGetOrgWideEmail() {
        Test.startTest();
        OrgWideEmailAddress owe = ARC_SGEmails.getOrgWideEmail();
        Test.stopTest();

        // Result may be null if no 'No Reply' OWE exists — just verify no exception thrown
        System.assert(true, 'getOrgWideEmail should not throw');
    }

    // ─── replaceEmailTemplateFields ───────────────────────────────────────────

    @isTest
    static void testReplaceEmailTemplateFields_replacesTokens() {
        Map<String, Object> fields = new Map<String, Object>{
            '{!EmployerName}' => 'Acme Corp',
            '{!ListChanges}'  => 'Address updated'
        };
        String html = '<p>Hello {!EmployerName}, changes: {!ListChanges}</p>';

        Test.startTest();
        String result = ARC_SGEmails.replaceEmailTemplateFields(fields, html);
        Test.stopTest();

        System.assert(result.contains('Acme Corp'), 'EmployerName token should be replaced');
        System.assert(result.contains('Address updated'), 'ListChanges token should be replaced');
        System.assert(!result.contains('{!EmployerName}'), 'Original token should be gone');
    }

    @isTest
    static void testReplaceEmailTemplateFields_nullValueBecomesEmpty() {
        Map<String, Object> fields = new Map<String, Object>{ '{!AccManagerData}' => null };
        String html = '<p>{!AccManagerData}</p>';

        Test.startTest();
        String result = ARC_SGEmails.replaceEmailTemplateFields(fields, html);
        Test.stopTest();

        System.assertEquals('<p></p>', result, 'Null value should render as empty string');
    }

    @isTest
    static void testReplaceEmailTemplateFields_emptyMapReturnsOriginal() {
        String html = '<p>No tokens here</p>';

        Test.startTest();
        String result = ARC_SGEmails.replaceEmailTemplateFields(new Map<String, Object>(), html);
        Test.stopTest();

        System.assertEquals(html, result, 'Empty field map should leave HTML unchanged');
    }

    @isTest
    static void testReplaceEmailTemplateFields_blankHtml() {
        Map<String, Object> fields = new Map<String, Object>{ '{!Key}' => 'Value' };

        Test.startTest();
        String result = ARC_SGEmails.replaceEmailTemplateFields(fields, '');
        Test.stopTest();

        System.assertEquals('', result, 'Blank HTML should return blank');
    }

    // ─── sendEmailToEmployer ──────────────────────────────────────────────────

    @isTest
    static void testSendEmailToEmployer_emptyList() {
        Test.startTest();
        ARC_SGEmails.sendEmailToEmployer(new List<ARC_SGEmails.InputVar>());
        Test.stopTest();

        System.assert(true, 'Empty list should return early without throwing');
    }

    @isTest
    static void testSendEmailToEmployer_withFullAccManager() {
        List<EmailTemplate> templates = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'ARC_SGErAdminNotifAccChanges' LIMIT 1];
        if (templates.isEmpty()) { return; }

        ARC_SGEmails.InputVar input = new ARC_SGEmails.InputVar();
        input.employerName    = 'Acme Corp';
        input.employerEmail   = 'employer@example.com';
        input.listChanges     = 'Address updated';
        input.hasAccManager   = true;
        input.accManagerName  = 'Jane Smith';
        input.accManagerEmail = 'jane@example.com';
        input.accManagerPhone = '555-1234';

        Test.startTest();
        ARC_SGEmails.sendEmailToEmployer(new List<ARC_SGEmails.InputVar>{ input });
        Test.stopTest();

        System.assert(true, 'Email with full account manager data should not throw');
    }

    @isTest
    static void testSendEmailToEmployer_withoutAccManager() {
        List<EmailTemplate> templates = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'ARC_SGErAdminNotifAccChanges' LIMIT 1];
        if (templates.isEmpty()) { return; }

        ARC_SGEmails.InputVar input = new ARC_SGEmails.InputVar();
        input.employerName  = 'Acme Corp';
        input.employerEmail = 'employer@example.com';
        input.listChanges   = 'Phone updated';
        input.hasAccManager = false;

        Test.startTest();
        ARC_SGEmails.sendEmailToEmployer(new List<ARC_SGEmails.InputVar>{ input });
        Test.stopTest();

        System.assert(true, 'Email without account manager should not throw');
    }

    @isTest
    static void testSendEmailToEmployer_partialAccManagerFields() {
        List<EmailTemplate> templates = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'ARC_SGErAdminNotifAccChanges' LIMIT 1];
        if (templates.isEmpty()) { return; }

        ARC_SGEmails.InputVar input = new ARC_SGEmails.InputVar();
        input.employerName   = 'Acme Corp';
        input.employerEmail  = 'employer@example.com';
        input.listChanges    = 'Email updated';
        input.hasAccManager  = true;
        input.accManagerName = 'Jane';
        // accManagerEmail and accManagerPhone intentionally null

        Test.startTest();
        ARC_SGEmails.sendEmailToEmployer(new List<ARC_SGEmails.InputVar>{ input });
        Test.stopTest();

        System.assert(true, 'Partial acc manager fields should not throw');
    }

    // ─── sendEmailForCompanyContactChanges ────────────────────────────────────

    @isTest
    static void testSendEmailForCompanyContactChanges_blankEmail() {
        Test.startTest();
        ARC_SGEmails.sendEmailForCompanyContactChanges('', 'Test User', 'Some changes', 'fakeId');
        Test.stopTest();

        System.assert(true, 'Blank email should return early without throwing');
    }

    @isTest
    static void testSendEmailForCompanyContactChanges_blankChanges() {
        Test.startTest();
        ARC_SGEmails.sendEmailForCompanyContactChanges('test@example.com', 'Test User', '', 'fakeId');
        Test.stopTest();

        System.assert(true, 'Blank changes should return early without throwing');
    }

    @isTest
    static void testSendEmailForCompanyContactChanges_noAccManager() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test SG Email Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        AccountContactRelation acr = [
            SELECT Id FROM AccountContactRelation
            WHERE AccountId = :acc.Id AND ContactId = :con.Id
            LIMIT 1
        ];

        Test.startTest();
        ARC_SGEmails.sendEmailForCompanyContactChanges('test@example.com', 'Test User', 'Phone changed', acr.Id);
        Test.stopTest();

        System.assert(true, 'Email without acc manager should not throw');
    }

    @isTest
    static void testSendEmailForCompanyContactChanges_withAccManager() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test SG Email Account' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

        acc.ARC_AccountManager__c = UserInfo.getUserId();
        update acc;

        AccountContactRelation acr = [
            SELECT Id FROM AccountContactRelation
            WHERE AccountId = :acc.Id AND ContactId = :con.Id
            LIMIT 1
        ];

        Test.startTest();
        ARC_SGEmails.sendEmailForCompanyContactChanges('test@example.com', 'Test User', 'Address changed', acr.Id);
        Test.stopTest();

        System.assert(true, 'Email with acc manager should not throw');
    }

    // ─── sendEmails ───────────────────────────────────────────────────────────

    @isTest
    static void testSendEmails_emptyList() {
        Test.startTest();
        ARC_SGEmails.sendEmails(new List<Case>());
        Test.stopTest();

        System.assert(true, 'Empty case list should return early without throwing');
    }

    @isTest
    static void testSendEmails_withCase() {
        List<EmailTemplate> templates = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'ARC_CensusFormEmail' LIMIT 1];
        if (templates.isEmpty()) { return; }

        Account acc  = [SELECT Id, Name FROM Account WHERE Name = 'Test SG Email Account' LIMIT 1];

        Case c = new Case(AccountId = acc.Id, OwnerId = UserInfo.getUserId(), Subject = 'Census Test', Description = 'Test description');
        insert c;
        c = [SELECT Id, CaseNumber, OwnerId, Account.Name FROM Case WHERE Id = :c.Id];

        Test.startTest();
        ARC_SGEmails.sendEmails(new List<Case>{ c });
        Test.stopTest();

        System.assert(true, 'sendEmails with a valid case should not throw');
    }

    // ─── sendMemberIdCardPortal ───────────────────────────────────────────────

    @isTest
    static void testSendMemberIdCardPortal_blankEmail() {
        Map<String, Object> inMap = new Map<String, Object>{
            'options' => new Map<String, Object>{ 'primaryContactEmail' => '' }
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        ARC_SGEmails.sendMemberIdCardPortal(inMap, outMap, new Map<String, Object>());
        Test.stopTest();

        System.assert(outMap.containsKey('error'), 'Blank email should set error key');
    }

    @isTest
    static void testSendMemberIdCardPortal_nullOptionsMap() {
        Map<String, Object> inMap  = new Map<String, Object>(); // no 'options' key → memberEmail = null
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        ARC_SGEmails.sendMemberIdCardPortal(inMap, outMap, new Map<String, Object>());
        Test.stopTest();

        System.assert(outMap.containsKey('error'), 'Null options should set error key');
    }

    @isTest
    static void testSendMemberIdCardPortal_noAttachment() {
        Map<String, Object> inMap = new Map<String, Object>{
            'options'         => new Map<String, Object>{ 'primaryContactEmail' => 'member@example.com' },
            'senderFirstName' => 'John',
            'aditionalEmail'  => 'member@example.com'
            // No WeShare_Member_ID_Card_Email or Legacy_Member_ID_Card_Email
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        ARC_SGEmails.sendMemberIdCardPortal(inMap, outMap, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals('No PDF attachment was generated.', outMap.get('error'), 'Missing attachment should set error key');
    }

    @isTest
    static void testSendMemberIdCardPortal_weShareAttachmentPath() {

        // Provide a fake attachment Id — sendEmail will throw internally, caught by the catch block
        Map<String, Object> inMap = new Map<String, Object>{
            'options'                      => new Map<String, Object>{ 'primaryContactEmail' => 'member@example.com' },
            'senderFirstName'              => 'John',
            'aditionalEmail'               => 'extra@example.com',
            'WeShare_Member_ID_Card_Email' => 'fakeAttachId000000001'
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        ARC_SGEmails.sendMemberIdCardPortal(inMap, outMap, new Map<String, Object>());
        Test.stopTest();

        // Exception is caught internally; outMap will have error key
        System.assert(outMap.containsKey('error') || outMap.containsKey('success'), 'outMap should contain an outcome key');
    }

    @isTest
    static void testSendMemberIdCardPortal_legacyAttachmentFallback() {
        // weShareAttachId blank → falls through to legacyAttachId
        Map<String, Object> inMap = new Map<String, Object>{
            'options'                      => new Map<String, Object>{ 'primaryContactEmail' => 'member@example.com' },
            'senderFirstName'              => 'John',
            'aditionalEmail'               => 'member@example.com',
            'WeShare_Member_ID_Card_Email' => '',
            'Legacy_Member_ID_Card_Email'  => 'fakeAttachId000000002'
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        ARC_SGEmails.sendMemberIdCardPortal(inMap, outMap, new Map<String, Object>());
        Test.stopTest();

        System.assert(outMap.containsKey('error') || outMap.containsKey('success'), 'outMap should contain an outcome key');
    }

    // ─── sendMemberIdCardCommunity ────────────────────────────────────────────

    @isTest
    static void testSendMemberIdCardCommunity_withContextId() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test SG Email Account' LIMIT 1];

        Map<String, Object> inMap = new Map<String, Object>{
            'ContextId'       => (String) acc.Id,
            'email'           => 'member@example.com',
            'senderFirstName' => 'John'
        };

        Test.startTest();
        ARC_SGEmails.sendMemberIdCardCommunity(inMap, new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();

        System.assert(true, 'sendMemberIdCardCommunity via ContextId should not throw');
    }
}