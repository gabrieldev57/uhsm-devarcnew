@isTest
public class LeadTriggerHandlerTest {

    @isTest
    static void testSendOptIn() {
        // Create a test Lead
        Lead testLead = new Lead(
            FirstName = 'TestLead122023',
            LastName = 'Lead122023',
            Phone = '17173004000',
            Add_To_Autodialer__c = True,
            Status = 'New'
        );
        

        // Set up a mock response for the callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Trigger the Lead trigger
        Test.startTest();
        insert testLead;
        // Inserting a Lead should invoke the trigger
        Test.stopTest();
    }

    // Create a mock response for the HTTP callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            // Set other response properties as needed
            return res;
        }
    }
}