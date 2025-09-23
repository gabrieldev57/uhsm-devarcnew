@isTest
private class ARC_ZelisPostToApiTest {
    @TestSetup
    static void setupTestData() {
        // Create test data
        ARC_CheckRun__c testCheckRun = new ARC_CheckRun__c(
            ARC_SkipAutomation__c = false,
            ARC_DocumentSent__c = false,
            ARC_Status__c = 'Open'
        );
        insert testCheckRun;
    }
    
    @isTest
    static void testSuccessfulExecution() {
        // Set up test data
        ARC_CheckRun__c checkRun = [SELECT Id,ARC_SkipAutomation__c FROM ARC_CheckRun__c LIMIT 1];
        Set<Id> claimIds = new Set<Id>();
        List<Claim> claims = ARC_TestUtility.createTestClaims(1);
        for(Claim clm : claims) claimIds.add(clm.Id);
        
        // Execute the queueable
        Test.startTest();
        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new SuccessfulHttpCalloutMock());
        System.enqueueJob(new ARC_ZelisPostToApi('TestFile', checkRun.Id, 'TestFolder', true, claimIds, true));
        Test.stopTest();
        
        // Verify results
        checkRun = [SELECT Id,ARC_SkipAutomation__c, ARC_DocumentSent__c, ARC_DocumentSentDate__c, ARC_Document_Name__c FROM ARC_CheckRun__c WHERE Id = :checkRun.Id];
        System.assertEquals(true, checkRun.ARC_DocumentSent__c, 'Document should be marked as sent');
        System.assertEquals(Date.today(), checkRun.ARC_DocumentSentDate__c, 'Document sent date should be today');
        System.assertEquals('TestFile', checkRun.ARC_Document_Name__c, 'Document name should be set correctly');
    }

    @isTest
    static void testSuccessfulExecution2() {
        // Set up test data
        ARC_CheckRun__c checkRun = [SELECT Id,ARC_SkipAutomation__c FROM ARC_CheckRun__c LIMIT 1];
        Set<Id> claimIds = new Set<Id>();
        List<Claim> claims = ARC_TestUtility.createTestClaims(1);
        for(Claim clm : claims) claimIds.add(clm.Id);
        
        // Execute the queueable
        Test.startTest();
        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new SuccessfulHttpCalloutMock());
        System.enqueueJob(new ARC_ZelisPostToApi('TestFile', checkRun.Id, 'TestFolder', false, claimIds, true));
        Test.stopTest();
        
        // Verify results
        checkRun = [SELECT Id,ARC_SkipAutomation__c, ARC_DocumentSent__c, ARC_DocumentSentDate__c, ARC_Document_Name__c FROM ARC_CheckRun__c WHERE Id = :checkRun.Id];
    }
    
    @isTest
    static void testFailedExecution() {
        // Set up test data
        ARC_CheckRun__c checkRun = [SELECT Id,ARC_SkipAutomation__c FROM ARC_CheckRun__c LIMIT 1];
        Set<Id> claimIds = new Set<Id>();
        List<Claim> claims = ARC_TestUtility.createTestClaims(1);
        for(Claim clm : claims) claimIds.add(clm.Id);
        
        // Execute the queueable
        Test.startTest();
        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new FailedHttpCalloutMock());
        System.enqueueJob(new ARC_ZelisPostToApi('TestFile', checkRun.Id, 'TestFolder', true, claimIds, true));
        Test.stopTest();
        
        // Verify results
        checkRun = [SELECT Id, ARC_Status__c FROM ARC_CheckRun__c WHERE Id = :checkRun.Id];
        System.assertEquals('Failed', checkRun.ARC_Status__c, 'Check run status should be set to Failed');
    }

    @isTest
    static void testFailedExecution2() {
        // Set up test data
        ARC_CheckRun__c checkRun = [SELECT Id,ARC_SkipAutomation__c FROM ARC_CheckRun__c LIMIT 1];
        Set<Id> claimIds = new Set<Id>();
        List<Claim> claims = ARC_TestUtility.createTestClaims(1);
        for(Claim clm : claims) claimIds.add(clm.Id);
        

        // Execute the queueable
        Test.startTest();

        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new FailedHttpCalloutMock());
        System.enqueueJob(new ARC_ZelisPostToApi('TestFile', checkRun.Id, 'TestFolder', false, claimIds, true));
        Test.stopTest();
        
        // Verify results
        checkRun = [SELECT Id, ARC_Status__c FROM ARC_CheckRun__c WHERE Id = :checkRun.Id];
    }
    
    @isTest
    static void testResendToZelis() {
        // Set up test data
        ARC_CheckRun__c checkRun = [SELECT Id,ARC_SkipAutomation__c FROM ARC_CheckRun__c LIMIT 1];
        Set<Id> claimIds = new Set<Id>();
        List<Claim> claims = ARC_TestUtility.createTestClaims(1);
        for(Claim clm : claims) claimIds.add(clm.Id);
        
        // Execute the queueable
        Test.startTest();
        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new SuccessfulHttpCalloutMock());
        System.enqueueJob(new ARC_ZelisPostToApi('TestFile', checkRun.Id, 'TestFolder', false, claimIds, true));
        Test.stopTest();
    }
    
    @isTest
    static void testSkipAutomation() {
        // Set up test data
        ARC_CheckRun__c checkRun = [SELECT Id,ARC_SkipAutomation__c FROM ARC_CheckRun__c LIMIT 1];
        checkRun.ARC_SkipAutomation__c = true;
        update checkRun;
        Set<Id> claimIds = new Set<Id>();
        List<Claim> claims = ARC_TestUtility.createTestClaims(1);
        for(Claim clm : claims) claimIds.add(clm.Id);
        
        // Execute the queueable
        Test.startTest();
        System.enqueueJob(new ARC_ZelisPostToApi('TestFile', checkRun.Id, 'TestFolder', true, claimIds, true));
        Test.stopTest();
        
        // Verify results
        checkRun = [SELECT Id, ARC_DocumentSent__c, ARC_DocumentSentDate__c, ARC_Document_Name__c FROM ARC_CheckRun__c WHERE Id = :checkRun.Id];
        System.assertEquals(false, checkRun.ARC_DocumentSent__c, 'Document should not be marked as sent when automation is skipped');
        System.assertEquals(null, checkRun.ARC_DocumentSentDate__c, 'Document sent date should remain null when automation is skipped');
        System.assertEquals(null, checkRun.ARC_Document_Name__c, 'Document name should remain null when automation is skipped');
    }
    
    // Mock classes
    public class SuccessfulHttpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true}');
            return res;
        }
    }
    
    public class FailedHttpCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error": "Bad Request"}');
            return res;
        }
    }
}