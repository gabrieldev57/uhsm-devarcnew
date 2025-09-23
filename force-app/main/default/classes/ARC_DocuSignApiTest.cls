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
}