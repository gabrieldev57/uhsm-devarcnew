global without sharing class ARC_EmailMemberCardPortal implements Callable {

    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }

    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        Boolean result = true;
        
        try {
            if (methodName == 'sendMemberIdCardCommunity') {
                sendMemberIdCardCommunity(inputMap, outMap, options);
            } 
            else {
                outMap.put('error', 'Method not found: ' + methodName);
                result = false;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception in invokeMethod: ' + e.getMessage() + '\n' + e.getStackTraceString());
            outMap.put('error', e.getMessage());
            result = false;
        }
        
        return result;
    }

    public static OrgWideEmailAddress oMail = [
        SELECT Id, Address, DisplayName
        FROM OrgWideEmailAddress
        WHERE Displayname = 'UHSM Member Services'
        LIMIT 1
    ];

    public static OrgWideEmailAddress getOrgWideEmail() {
        List<OrgWideEmailAddress> emails = [
            SELECT Id, Address, DisplayName
            FROM OrgWideEmailAddress
            WHERE Displayname = 'No Reply'
            LIMIT 1
        ];
        return emails.isEmpty() ? null : emails[0];
    }

    public static String replaceEmailTemplateFields(Map<String, Object> mergeFieldsMap, String htmlEmailBody) {
        if (!mergeFieldsMap.isEmpty() && String.isNotBlank(htmlEmailBody)) {
            for (String key : mergeFieldsMap.keySet()) {
                String entryValue = mergeFieldsMap.get(key) != null
                    ? String.valueOf(mergeFieldsMap.get(key))
                    : '';
                htmlEmailBody = htmlEmailBody.replace(key, entryValue);
            }
        }
        return htmlEmailBody;
    }

    public static void sendMemberIdCardCommunity(
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options) 
    {
        System.debug('sendMemberIdCardCommunity inputMap => ' + JSON.serializePretty(inputMap));

        String memberEmail = (String) inputMap.get('email');
        String aditionalEmail = (String) inputMap.get('aditionalEmail');
        String senderFirstName = (String) inputMap.get('senderFirstName');
        String weShareAttachmentId = (String) inputMap.get('WeShare_Member_ID_Card_Email');
        String legacyAttachmentId = (String) inputMap.get('Legacy_Member_ID_Card_Email');

        if (String.isBlank(memberEmail)) {
            outMap.put('success', false);
            outMap.put('message', 'Email is required.');
            return;
        }

        EmailTemplate template = [
            SELECT Id, Subject, HtmlValue
            FROM EmailTemplate
            WHERE DeveloperName = 'UHSM_WESHARE_MEMBER_ID_CARD'
            LIMIT 1
        ];

        Map<String, Object> mergeFieldsMap = new Map<String, Object>{
            '{!Contact.FirstName}' => senderFirstName
        };

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setOrgWideEmailAddressId(oMail.Id);
        message.setBccSender(false);
        message.setUseSignature(false);
        message.setToAddresses(new List<String>{ memberEmail, aditionalEmail });
        message.setSubject(template.Subject);
        
        message.setHtmlBody(
            replaceEmailTemplateFields(mergeFieldsMap, template.HtmlValue)
        );

        String attachmentId = '';
        if (String.isNotBlank(weShareAttachmentId)) {
            attachmentId = weShareAttachmentId;
        } else if (String.isNotBlank(legacyAttachmentId)) {
            attachmentId = legacyAttachmentId;
        }

        if (String.isBlank(attachmentId)) {
            outMap.put('success', false);
            outMap.put('message', 'No PDF attachment was generated.');
            return;
        }

        message.setEntityAttachments(new List<String>{ attachmentId });

        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ message });
            outMap.put('success', true);
            outMap.put('message', 'Member ID Card email sent successfully.');
        } catch (Exception e) {
            System.debug('Error sending Member ID Card email: ' + e.getMessage());
            outMap.put('success', false);
            outMap.put('message', e.getMessage());

            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(
                'Error in ARC_SGEmails sendMemberIdCardCommunity: ' + e.getMessage(),
                'ERROR ARC_SGEmails sendMemberIdCardCommunity',
                apexErrorEmail
            );
        }
    }
}