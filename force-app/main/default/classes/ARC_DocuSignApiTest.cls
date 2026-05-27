@isTest
private class ARC_DocuSignApiTest {
    private static Integer requestCount = 0;


    @isTest
    static void getDocusignAccountTest() {
        Test.startTest();
        String accountId = ARC_DocuSignApi.getDocuSignAccountId();
        Test.stopTest();
    }
    
    @isTest
    static void testHandleDocuSignUpdates() {

        // Create test data
        Account account = new Account(
            FirstName = 'Test',
            LastName = 'Account1',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId(),
            PersonEmail = 'test@test.com'
        );

        insert account;

        Case testCase = new Case(
            Case_Type__c = 'Contribution',
            ARC_Reason__c = 'Method Change',
            ARC_LastDocuSignEnvelopeId__c = 'test-envelope-id',
            ARC_LastDocuSignEnvelopeStatus__c = 'Completed',
            Description = 'test-description',
            Subject = 'test-subject',
            ARC_PersonAccount__c = account.Id,
            ARC_UPMSelectedPayor__c = account.Id
        );

        insert testCase;
        
        Case oldCase = new Case(
            Id = testCase.Id,
            ARC_LastDocuSignEnvelopeStatus__c = 'Not Completed'
        );
        
        Map<Id, Case> oldMap = new Map<Id, Case>{testCase.Id => oldCase};
        Map<Id, Case> newMap = new Map<Id, Case>{testCase.Id => testCase};
        
        Test.startTest();
        // Mock the callout response CREDIT CARD
        Test.setMock(HttpCalloutMock.class, new MockCreditCardResponseGenerator());
        ARC_DocuSignApi.handleDocuSignUpdates(oldMap, newMap);
        // Mock the callout response BANK ACCOUNT
        Test.setMock(HttpCalloutMock.class, new MockBankAccountResponseGenerator());
        ARC_DocuSignApi.handleDocuSignUpdates(oldMap, newMap);
        Test.stopTest();

        // Verify that the callout was made
        System.assertEquals(2, getRequestCount(), 'Expected two callouts');
    }
    
    // Mock class for credit card scenario
    private class MockCreditCardResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            requestCount++;
            
            // Create a mock response for credit card scenario
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"dateTabs":[{"tabLabel":"IssueDate","value":"01/01/2024"},{"tabLabel":"ExpirationDate","value":"01/01/2030"}],"textTabs":[{"tabLabel":"FirstName","value":"Test"},{"tabLabel":"LastName","value":"Test"},{"tabLabel":"FirstName","value":"John"},{"tabLabel":"LastName","value":"Doe"},{"tabLabel":"CardNumber","value":"4111111111111111"},{"tabLabel":"CardExpiration","value":"01/30"}],"checkboxTabs":[{"tabLabel":"CreditCard","selected":"true"},{"tabLabel":"ACH","selected":"false"}]}');            return res;
        }
    }

    // Mock class for bank account scenario
    private class MockBankAccountResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            requestCount++;
            
            // Create a mock response for bank account scenario
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"dateTabs":[{"tabLabel":"FirstName","value":"Test"}],"textTabs":[{"tabLabel":"FirstName","value":"Test"},{"tabLabel":"LastName","value":"Test"},{"tabLabel":"AccountName","value":"John Doe"},{"tabLabel":"BankName","value":"Test Bank"},{"tabLabel":"AccountNumber","value":"1234567890"}],"checkboxTabs":[{"tabLabel":"ACH","selected":"true"},{"tabLabel":"Checking","selected":"true"},{"tabLabel":"Savings","selected":"false"},{"tabLabel":"CreditCard","selected":"false"}]}');
            return res;
        }
    }

    public static Integer getRequestCount() {
        return requestCount;
    }
            @isTest
    static void testVoidEnvelope() {
        // Prepare test data
        // Mock the callout
        Test.setMock(HttpCalloutMock.class, new DocuSignVoidEnvelopeMock());

        // Call the method to be tested
        Test.startTest();
        ARC_DocusignAPI.voidEnvelope('12345');
        Test.stopTest();

        // Verify the behavior
        // In this case, since it's a callout, we don't have much to verify except that no exceptions were thrown.
    }

    // Mock class to simulate the HTTP response from DocuSign
    public class DocuSignVoidEnvelopeMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "voided"}');
            res.setStatusCode(200);
            return res;
        }
    }

      @isTest
    static void testGetRecipientTabs() {
        // Mock successful HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"testKey": "testValue"}'));
        
        Test.startTest();
        Map<String, Object> result = ARC_DocuSignApi.httpGetRecipientsTabs('testEnvelopeId');
        Test.stopTest();
        
        System.assertEquals('testValue', result.get('testKey'), 'The response should contain the expected key-value pair');
    }
    
    
    // Mock HTTP response generator
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String body;
        
        public MockHttpResponseGenerator(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    @isTest
    static void testSendCompositeEnvelope_phoneError_updatesContract() {
        Contract testContract = ARC_TestUtility.createContracts(1)[0];
        insert testContract;

        String serializedSignerList = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'roleName' => 'Primary',
                'name' => 'John Doe',
                'email' => 'john.doe@test.com',
                'recipientId' => '1',
                'routingOrder' => '1'
            }
        });

        String serializedTemplatesId = JSON.serialize(new List<Object>{
            'template-id-001',
            'template-id-002'
        });

        String serializedTabs = JSON.serialize(new Map<String, Object>{
            'checkboxTabs' => new Map<String, Object>{
                'ACH' => 'true',
                'CreditCard' => 'false'
            },
            'textTabs' => new Map<String, Object>{
                'FirstName' => 'John',
                'LastName' => 'Doe'
            }
        });

        Test.setMock(HttpCalloutMock.class, new SendCompositeEnvelopeErrorPhoneMock());

        Test.startTest();
        ARC_DocuSignApi.sendCompositeEnvelope(
            'Test Composite Envelope',
            serializedSignerList,
            serializedTemplatesId,
            serializedTabs,
            String.valueOf(testContract.Id)
        );
        Test.stopTest();

        Contract updatedContract = [
            SELECT Id, vlocity_ins__LastDocuSignEnvelopeId__c, vlocity_ins__LastDocuSignEnvelopeStatus__c
            FROM Contract
            WHERE Id = :testContract.Id
            LIMIT 1
        ];

        System.assertEquals(null, updatedContract.vlocity_ins__LastDocuSignEnvelopeId__c,
            'Expected the Contract not to store any envelope id.'
        );
    }

    @isTest
    static void testSendCompositeEnvelope_happyPath_updatesContract() {
        Contract testContract = ARC_TestUtility.createContracts(1)[0];
        insert testContract;

        String serializedSignerList = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'roleName' => 'Primary',
                'name' => 'John Doe',
                'email' => 'john.doe@test.com',
                'recipientId' => '1',
                'routingOrder' => '1'
            }
        });

        String serializedTemplatesId = JSON.serialize(new List<Object>{
            'template-id-001',
            'template-id-002'
        });

        String serializedTabs = JSON.serialize(new Map<String, Object>{
            'checkboxTabs' => new Map<String, Object>{
                'ACH' => 'true',
                'CreditCard' => 'false'
            },
            'textTabs' => new Map<String, Object>{
                'FirstName' => 'John',
                'LastName' => 'Doe'
            }
        });

        Test.setMock(HttpCalloutMock.class, new SendCompositeEnvelopeMock());

        Test.startTest();
        ARC_DocuSignApi.sendCompositeEnvelope(
            'Test Composite Envelope',
            serializedSignerList,
            serializedTemplatesId,
            serializedTabs,
            String.valueOf(testContract.Id)
        );
        Test.stopTest();

        Contract updatedContract = [
            SELECT Id, vlocity_ins__LastDocuSignEnvelopeId__c, vlocity_ins__LastDocuSignEnvelopeStatus__c
            FROM Contract
            WHERE Id = :testContract.Id
            LIMIT 1
        ];
        
        System.assertEquals('env-test-123', updatedContract.vlocity_ins__LastDocuSignEnvelopeId__c,
            'Expected the Contract to store the envelope id returned by DocuSign.');
        System.assertEquals('Pending', updatedContract.vlocity_ins__LastDocuSignEnvelopeStatus__c,
            'Expected the Contract DocuSign status to be set to Pending.');
    }

    private class SendCompositeEnvelopeMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(201);
            res.setBody('{"envelopeId":"env-test-123","status":"sent"}');
            return res;
        }
    }

    private class SendCompositeEnvelopeErrorPhoneMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(201);
            res.setBody('{"errorCode":"PHONE","status":"sent"}');
            return res;
        }
    }

    private class SmallGroupEnvelopeSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"envelopeId":"small-group-env-123"}');
            return res;
        }
    }

    private class SmallGroupEnvelopeMissingEnvelopeIdMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"sent","message":"Envelope created but id was not returned"}');
            return res;
        }
    }

    private class SmallGroupEnvelopeExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Forced small group DocuSign failure');
        }
    }

    private static String buildSmallGroupSignerListJson() {
        List<Object> signers = new List<Object>{
            new Map<String, Object>{
                'roleName' => 'Primary',
                'name' => 'Primary Signer',
                'email' => 'primary.smallgroup@test.com',
                'recipientId' => '1'
            },
            new Map<String, Object>{
                'roleName' => 'Legacy',
                'name' => 'Legacy Signer',
                'email' => 'legacy.smallgroup@test.com',
                'recipientId' => '2'
            }
        };
        return JSON.serialize(signers);
    }

    private static String buildSmallGroupTemplateListJson() {
        List<Object> templates = new List<Object>{
            new Map<String, Object>{
                'templateId' => 'template-primary-001',
                'signerRole' => 'Primary'
            },
            new Map<String, Object>{
                'templateId' => 'template-legacy-001',
                'signerRole' => 'Legacy',
                'legacyIndex' => 0
            },
            new Map<String, Object>{
                'templateId' => 'template-legacy-missing-001',
                'signerRole' => 'Legacy',
                'legacyIndex' => 5
            }
        };
        return JSON.serialize(templates);
    }

    private static String buildSmallGroupTabsJson() {
        Map<String, Object> tabs = new Map<String, Object>{
            'global' => new Map<String, Object>{
                'textTabs' => new Map<String, Object>{
                    'EffectiveDate' => '2026-01-01',
                    'Primary.FirstName' => 'Primary'
                },
                'checkboxTabs' => new Map<String, Object>{
                    'Primary.AcceptedTerms' => 'true'
                }
            },
            'legacyMembers' => new List<Object>{
                new Map<String, Object>{
                    'textTabs' => new Map<String, Object>{
                        'Legacy.FirstName' => 'Legacy'
                    },
                    'checkboxTabs' => new Map<String, Object>{
                        'Legacy.AcceptedTerms' => 'true'
                    }
                }
            }
        };
        return JSON.serialize(tabs);
    }

    private static Case createSmallGroupDocuSignCase() {
        Case c = new Case(
            Subject = 'Small Group DocuSign Test Case',
            Status = 'New',
            Origin = 'Phone',
            Description = 'Description Test'
        );
        insert c;
        return c;
    }

    @IsTest
    static void testSendCompositeEnvelopeSmallGroup_caseHappyPath_updatesCaseEnvelopeFields() {
        Case c = createSmallGroupDocuSignCase();
        Test.setMock(HttpCalloutMock.class, new SmallGroupEnvelopeSuccessMock());

        Test.startTest();
        ARC_DocuSignApi.sendCompositeEnvelopeSmallGroup(
            'Small Group Happy Path',
            buildSmallGroupSignerListJson(),
            buildSmallGroupTemplateListJson(),
            buildSmallGroupTabsJson(),
            c.Id
        );
        Test.stopTest();

        Case updatedCase = [
            SELECT Id, ARC_LastDocuSignEnvelopeId__c, ARC_LastDocuSignEnvelopeStatus__c
            FROM Case
            WHERE Id = :c.Id
        ];

        System.assertEquals('small-group-env-123', updatedCase.ARC_LastDocuSignEnvelopeId__c);
        System.assertEquals('Pending', updatedCase.ARC_LastDocuSignEnvelopeStatus__c);
    }

    @IsTest
    static void testSendCompositeEnvelopeSmallGroup_missingEnvelopeId_createsLog() {
        Case c = createSmallGroupDocuSignCase();
        Test.setMock(HttpCalloutMock.class, new SmallGroupEnvelopeMissingEnvelopeIdMock());

        Test.startTest();
        ARC_DocuSignApi.sendCompositeEnvelopeSmallGroup(
            'Small Group Missing Envelope Id',
            buildSmallGroupSignerListJson(),
            buildSmallGroupTemplateListJson(),
            buildSmallGroupTabsJson(),
            c.Id
        );
        Test.stopTest();

        List<Custom_Logs__c> logs = [
            SELECT Id, Name, Log__c, Status__c
            FROM Custom_Logs__c
            WHERE Name LIKE 'Exception while updating envelope ID in policy or case:%'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(1, logs.size(), 'A log should be created when DocuSign does not return envelopeId.');
        System.assertEquals('New', logs[0].Status__c);
        System.assert(logs[0].Log__c.contains('Envelope created but id was not returned'));
    }

    @IsTest
    static void testSendCompositeEnvelopeSmallGroup_calloutException_createsLog() {
        Case c = createSmallGroupDocuSignCase();
        Test.setMock(HttpCalloutMock.class, new SmallGroupEnvelopeExceptionMock());

        Test.startTest();
        ARC_DocuSignApi.sendCompositeEnvelopeSmallGroup(
            'Small Group Callout Exception',
            buildSmallGroupSignerListJson(),
            buildSmallGroupTemplateListJson(),
            buildSmallGroupTabsJson(),
            c.Id
        );
        Test.stopTest();

        List<Custom_Logs__c> logs = [
            SELECT Id, Name, Log__c, Status__c
            FROM Custom_Logs__c
            WHERE Name LIKE 'Exception while envelope in policy or case Id:%'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(1, logs.size(), 'A log should be created when the small group callout fails.');
        System.assertEquals('New', logs[0].Status__c);
        System.assert(logs[0].Log__c.contains('Forced small group DocuSign failure'));
    }

    private class SmallGroupEnvelopePhoneRetryMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            requestCount++;
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (requestCount == 1) {
                res.setStatusCode(400);
                res.setBody('{"errorCode":"PHONE","message":"Phone authentication metadata is invalid"}');
            } else {
                res.setStatusCode(201);
                res.setBody('{"envelopeId":"small-group-env-phone-retry-123","status":"sent"}');
            }
            return res;
        }
    }

    private static String buildSmallGroupSignerListWithPhoneJson() {
        List<Object> signers = new List<Object>{
            new Map<String, Object>{
                'roleName' => 'Primary',
                'name' => 'Primary Phone Signer',
                'email' => 'primary.phone.smallgroup@test.com',
                'recipientId' => '1',
                'routingOrder' => '1',
                'additionalNotifications' => new List<Object>{
                    new Map<String, Object>{
                        'phoneNumber' => '+15555550100'
                    }
                }
            },
            new Map<String, Object>{
                'roleName' => 'Legacy',
                'name' => 'Legacy Phone Signer',
                'email' => 'legacy.phone.smallgroup@test.com',
                'recipientId' => '2',
                'routingOrder' => '2',
                'additionalNotifications' => new List<Object>{
                    new Map<String, Object>{
                        'phoneNumber' => '+15555550101'
                    }
                }
            }
        };
        return JSON.serialize(signers);
    }

    private static String buildSmallGroupRoleResolvedTabsJson() {
        Map<String, Object> tabs = new Map<String, Object>{
            'textTabs' => new Map<String, Object>{
                'Primary.FirstName' => 'Primary',
                'Legacy.FirstName' => 'Legacy',
                'UnknownRole.FirstName' => 'FallbackValue'
            },
            'checkboxTabs' => new Map<String, Object>{
                'Primary.AcceptedTerms' => 'true',
                'Legacy.AcceptedTerms' => 'true'
            }
        };
        return JSON.serialize(tabs);
    }

    @IsTest
    static void testSendCompositeEnvelopeSmallGroup_phoneErrorCreatesLog() {
        requestCount = 0;
        Case c = createSmallGroupDocuSignCase();
        Test.setMock(HttpCalloutMock.class, new SmallGroupEnvelopePhoneRetryMock());

        Test.startTest();
        ARC_DocuSignApi.sendCompositeEnvelopeSmallGroup(
            'Small Group Phone Error',
            buildSmallGroupSignerListWithPhoneJson(),
            buildSmallGroupTemplateListJson(),
            buildSmallGroupRoleResolvedTabsJson(),
            c.Id
        );
        Test.stopTest();

        Case updatedCase = [
            SELECT Id, ARC_LastDocuSignEnvelopeId__c, ARC_LastDocuSignEnvelopeStatus__c
            FROM Case
            WHERE Id = :c.Id
        ];

        System.assertEquals(1, requestCount, 'Small Group PHONE error path currently performs only one DocuSign callout.');
        System.assertEquals(null, updatedCase.ARC_LastDocuSignEnvelopeId__c, 'Envelope Id should not be stored when DocuSign returns a PHONE error.');

        List<Custom_Logs__c> logs = [
            SELECT Id, Name, Log__c, Status__c
            FROM Custom_Logs__c
            WHERE Name LIKE 'Exception while updating envelope ID in policy or case:%'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(1, logs.size(), 'A log should be created when DocuSign returns a PHONE error without envelopeId.');
        System.assertEquals('New', logs[0].Status__c);
        System.assert(logs[0].Log__c.contains('PHONE'), 'The log should include the PHONE error response.');
    }
    @IsTest
    static void testSendCompositeEnvelopeInvocable_setsProcessingAndSendsEnvelope() {
        Contract testContract = ARC_TestUtility.createContracts(1)[0];
        insert testContract;

        String serializedSignerList = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'roleName' => 'Primary',
                'name' => 'Invocable Signer',
                'email' => 'invocable.signer@test.com',
                'recipientId' => '1',
                'routingOrder' => '1'
            }
        });

        String serializedTemplatesId = JSON.serialize(new List<Object>{
            'template-invocable-001'
        });

        String serializedTabs = JSON.serialize(new Map<String, Object>{
            'checkboxTabs' => new Map<String, Object>{
                'ACH' => 'true'
            },
            'textTabs' => new Map<String, Object>{
                'FirstName' => 'Invocable',
                'LastName' => 'Signer'
            }
        });

        Map<String, Object> inputMap = new Map<String, Object>{
            'subject' => 'Invocable Composite Envelope',
            'signerList' => serializedSignerList,
            'templateIdList' => serializedTemplatesId,
            'tabs' => serializedTabs,
            'contractId' => String.valueOf(testContract.Id)
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.setMock(HttpCalloutMock.class, new SendCompositeEnvelopeMock());

        Test.startTest();
        ARC_DocuSignApi.sendCompositeEnvelopeInvocable(inputMap, outputMap, options);
        Test.stopTest();

        System.assertEquals('processing', outputMap.get('status'), 'Invocable method should mark the request as processing.');

        Contract updatedContract = [
            SELECT Id, vlocity_ins__LastDocuSignEnvelopeId__c, vlocity_ins__LastDocuSignEnvelopeStatus__c
            FROM Contract
            WHERE Id = :testContract.Id
            LIMIT 1
        ];

        System.assertEquals('env-test-123', updatedContract.vlocity_ins__LastDocuSignEnvelopeId__c);
        System.assertEquals('Pending', updatedContract.vlocity_ins__LastDocuSignEnvelopeStatus__c);
    }
}