@isTest
public class CallLeadScoreAPITest {
    
    // Mock HTTP response
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{' +
                '"lead_id": "00QRi00000TestLead",' +
                '"score": 0.39012739062309265,' +
                '"score_uncalibrated": 0.8847446441650391,' +
                '"score_type": "calibrated",' +
                '"snapshot_type": "phone_info",' +
                '"days_since_creation": 2.89,' +
                '"scored_at": "2025-12-12T20:44:51.634033",' +
                '"model_version": "20251208_203435"' +
            '}');
            return res;
        }
    }
    
    // Mock for error response
    private class MockHttpErrorResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }
    
    @isTest
    static void testGetLeadScoreSuccess() {
        // Create test Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company'
        );
        insert testLead;
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        Test.startTest();
        List<CallLeadScoreAPI.LeadScoreResult> results = 
            CallLeadScoreAPI.getLeadScore(new List<Id>{testLead.Id});
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].success);
        System.assertNotEquals(null, results[0].score);
        
        // Verify Lead was updated
        Lead updatedLead = [
            SELECT Conversion_Probability__c, Conversion_Probability_Uncalibrated__c, 
                   Score_Generated_Date__c, Model_Used_for_Score__c 
            FROM Lead 
            WHERE Id = :testLead.Id
        ];
        System.assertEquals(39.0127, updatedLead.Conversion_Probability__c.setScale(4));
        System.assertEquals('20251208_203435', updatedLead.Model_Used_for_Score__c);
    }
    
    @isTest
    static void testGetLeadScoreError() {
        // Create test Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company'
        );
        insert testLead;
        
        // Set mock error callout
        Test.setMock(HttpCalloutMock.class, new MockHttpErrorResponse());
        
        Test.startTest();
        List<CallLeadScoreAPI.LeadScoreResult> results = 
            CallLeadScoreAPI.getLeadScore(new List<Id>{testLead.Id});
        Test.stopTest();
        
        // Verify error handling
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].success);
        System.assert(results[0].message.contains('500'));
    }
}