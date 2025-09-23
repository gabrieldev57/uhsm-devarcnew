@isTest
public class ARC_DocuSignApiVoidEnvelopeTest {

    @isTest
    static void testFlowActionVoidEnvelope() {
        // Prepare test data
        List<String> envelopeIds = new List<String>{ '12345' };

        // Mock the callout
        Test.setMock(HttpCalloutMock.class, new DocuSignVoidEnvelopeMock());

        // Call the method to be tested
        Test.startTest();
        ARC_DocuSignApiVoidEnvelope.FlowActionVoidEnvelope(envelopeIds);
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
}