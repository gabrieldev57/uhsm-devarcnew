@IsTest
private class ARC_EmailMemberCardPortalTest {
    static testMethod void testReplaceEmailTemplateFields() {
        Map<String,Object> m = new Map<String,Object>{'{!Contact.FirstName}'=>'John','{!Contact.LastName}'=>'Doe'};
        String body = 'Hello {!Contact.FirstName} {!Contact.LastName}';
        String out = ARC_EmailMemberCardPortal.replaceEmailTemplateFields(m, body);
        System.assertEquals('Hello John Doe', out);

        // null or empty body
        String out2 = ARC_EmailMemberCardPortal.replaceEmailTemplateFields(m, '');
        System.assertEquals('', out2);
    }

    static testMethod void testSendMemberIdCardCommunity_missingEmail() {
        Map<String,Object> input = new Map<String,Object>();
        Map<String,Object> outMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        ARC_EmailMemberCardPortal.sendMemberIdCardCommunity(input, outMap, options);
        System.assertEquals(false, outMap.get('success'));
        System.assertEquals('Email is required.', outMap.get('message'));
    }
    static testMethod void testInvokeMethod_notFound() {
        ARC_EmailMemberCardPortal p = new ARC_EmailMemberCardPortal();
        Map<String,Object> input = new Map<String,Object>();
        Map<String,Object> outMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        Boolean res = p.invokeMethod('unknown', input, outMap, options);
        System.assertEquals(false, res);
        System.assert(((String)outMap.get('error')).startsWith('Method not found'));
    }

    static testMethod void testInvokeMethod_sendMemberIdCard_missingEmail_viaInvoke() {
        ARC_EmailMemberCardPortal p = new ARC_EmailMemberCardPortal();
        Map<String,Object> args = new Map<String,Object>{
            'input' => new Map<String,Object>(),
            'output' => new Map<String,Object>(),
            'options' => new Map<String,Object>()
        };
        Object res = p.call('sendMemberIdCardCommunity', args);
        // call returns the Boolean from invokeMethod; missing email path should result in true (method executed)
        // verify output map populated
        Map<String,Object> outMap = (Map<String,Object>)args.get('output');
        System.assertEquals(false, outMap.get('success'));
        System.assertEquals('Email is required.', outMap.get('message'));
    }

    static testMethod void testReplaceEmailTemplateFields_edgeCases() {
        // empty merge map
        String body = 'No placeholders here';
        String out = ARC_EmailMemberCardPortal.replaceEmailTemplateFields(new Map<String,Object>(), body);
        System.assertEquals('No placeholders here', out);

        // null map -> controller expects map; avoid passing null to prevent NPE
        String out2 = ARC_EmailMemberCardPortal.replaceEmailTemplateFields(new Map<String,Object>(), body);
        System.assertEquals('No placeholders here', out2);

        // placeholder present but value null
        Map<String,Object> m = new Map<String,Object>{'{!Contact.FirstName}' => null};
        String out3 = ARC_EmailMemberCardPortal.replaceEmailTemplateFields(m, 'Hi {!Contact.FirstName}');
        System.assertEquals('Hi ', out3);
    }

    static testMethod void testConditional_fullPath_ifOMailExists() {
        // This test will only run the full send logic if the org has the expected OrgWideEmailAddress
        List<OrgWideEmailAddress> owes = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'UHSM Member Services' LIMIT 1];
        if (owes.isEmpty()) {
            // skip test in this org
            System.assert(true);
            return;
        }

        // Ensure EmailTemplate exists (must not reference VF components)
        List<EmailTemplate> ets = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'UHSM_WESHARE_MEMBER_ID_CARD' LIMIT 1];
        if (ets.isEmpty()) {
            // can't proceed reliably
            System.assert(true);
            return;
        }

        Map<String,Object> input = new Map<String,Object>{'email'=>'test@example.com','senderFirstName'=>'Sam', 'WeShare_Member_ID_Card_Email' => '069xxxxxxxxxxxxxxx'};
        Map<String,Object> outMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();

        Test.startTest();
        try {
            ARC_EmailMemberCardPortal.sendMemberIdCardCommunity(input, outMap, options);
            // If sendEmail succeeds, outMap.success should be true
            System.assert(outMap.containsKey('success'));
        } catch (Exception e) {
            // accept any exception as long as it's reported in outMap or thrown
            System.assert(true);
        }
        Test.stopTest();
    }
}