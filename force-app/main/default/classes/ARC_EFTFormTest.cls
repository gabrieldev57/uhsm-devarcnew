@isTest
private class ARC_EFTFormTest {
    private static Integer requestCount = 0;
    

    @TestSetup
    static void makeData(){
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
    }

    @isTest
    static void testGetDocusignData() {

        Case testCase = [SELECT Id, ARC_LastDocuSignEnvelopeId__c, ARC_LastDocuSignEnvelopeStatus__c FROM Case LIMIT 1];
        
        Case oldCase = new Case(
            Id = testCase.Id,
            ARC_LastDocuSignEnvelopeStatus__c = 'Not Completed'
        );
        
        Map<String,Object> inputMap = new Map<String,Object>{'caseId' => testCase.Id};
        Test.startTest();
        // Mock the callout response CREDIT CARD
        Test.setMock(HttpCalloutMock.class, new MockCreditCardResponseGenerator());
        ARC_EFTForm.getData(inputMap, new Map<String,Object>(), new Map<String,Object>());
        // Mock the callout response BANK ACCOUNT
        Test.stopTest();
    }

    @isTest
    static void testUpdateCase() {
        Map<String,Object> inputMap = new Map<String,Object>{'caseId' => [SELECT Id FROM Case LIMIT 1].Id, 'envelopeId' => 'test-envelope-id', 'envelopeStatus' => 'Completed'};
        Test.startTest();
        ARC_EFTForm.updateCase(inputMap, new Map<String,Object>(), new Map<String,Object>());
        Test.stopTest();
    }

    @isTest
    static void testInvokeMethod() {
        Map<String,Object> inputMap = new Map<String,Object>{'caseId' => [SELECT Id FROM Case LIMIT 1].Id};
        Map<String,Object> outMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        Test.startTest();
        ARC_EFTForm eftForm = new ARC_EFTForm();
        Test.setMock(HttpCalloutMock.class, new MockCreditCardResponseGenerator());
        eftForm.invokeMethod('getData', inputMap, outMap, options);
        eftForm.invokeMethod('updateCase', inputMap, outMap, options);
        Test.stopTest();
    }


    
    // Mock class for credit card scenario
    private class MockCreditCardResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            requestCount++;
            
            // Create a mock response for credit card scenario
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"textTabs": [{"tabLabel": "FirstName", "value": "Test"},{"tabLabel": "LastName", "value": "Test"},{"tabLabel": "FirstName", "value": "John"}, {"tabLabel": "LastName", "value": "Doe"}, {"tabLabel": "CardNumber", "value": "4111111111111111"}, {"tabLabel": "CardExpiration", "value": "01/30"}], "checkboxTabs": [{"tabLabel": "CreditCard", "selected": "true"},{"tabLabel": "ACH", "selected": "false"}]}');
            return res;
        }
    }

    // Mock class for bank account scenario
    private class MockBankAccountResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            requestCount++;
            
            // Create a mock response for bank account scenario
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"textTabs": [{"tabLabel": "FirstName", "value": "Test"},{"tabLabel": "LastName", "value": "Test"},{"tabLabel": "AccountName", "value": "John Doe"}, {"tabLabel": "BankName", "value": "Test Bank"}, {"tabLabel": "AccountNumber", "value": "1234567890"}], "checkboxTabs": [{"tabLabel": "ACH", "selected": "true"}, {"tabLabel": "Checking", "selected": "true"}, {"tabLabel": "Savings", "selected": "false"},{"tabLabel": "CreditCard", "selected": "false"}]}');
            return res;
        }
    }

    public static Integer getRequestCount() {
        return requestCount;
    }
}