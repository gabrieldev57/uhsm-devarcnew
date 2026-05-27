@isTest
public class ARC_QueableSendFileBatchPOCTest {

    @TestSetup
    static void setupTestData() {
        // Create test ARC_S3UploadState__c records for state management
        List<ARC_S3UploadState__c> testRecords = new List<ARC_S3UploadState__c>();
        testRecords.add(new ARC_S3UploadState__c(
            ARC_FilePath__c = 'cvs_test_file.txt',
            ARC_UploadId__c = 'testUploadId123',
            ARC_NextPartNumber__c = 2,
            ARC_LastUpdated__c = System.now()
        ));
        testRecords.add(new ARC_S3UploadState__c(
            ARC_FilePath__c = 'cvs_multipart_test.txt',
            ARC_UploadId__c = 'testUploadId456',
            ARC_NextPartNumber__c = 3,
            ARC_LastUpdated__c = System.now()
        ));
        insert testRecords;
    }

    @isTest
    static void testZelisFileInTestMode() {
        String testContent = 'Test content for Zelis';
        String testFileName = 'zelis_test_file.txt';
        Integer testSegments = 10;
        Boolean isTest = true;
        Decimal testTransactionId = 12345.67;
        String testFileType = 'Zelis';

        ARC_QueableSendFileBatchPOC job = new ARC_QueableSendFileBatchPOC(
            testContent, testFileName, testSegments, isTest, testTransactionId, testFileType
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
        
        // Zelis uses @Future method which executes asynchronously
    }

    @isTest
    static void testCVSFileFirstChunk() {
        String testContent = 'First chunk content for CVS';
        String testFileName = 'cvs_first_chunk.txt';
        Boolean sendFilesToTestSites = true;
        Boolean isFirst = true;
        Boolean isFinish = false;
        Integer lastLine = 100;
        String testFileType = 'CVS';

        Test.setMock(HttpCalloutMock.class, new S3MockSuccess());

        ARC_QueableSendFileBatchPOC job = new ARC_QueableSendFileBatchPOC(
            testContent, testFileName, testFileType, sendFilesToTestSites, isFirst, isFinish, lastLine
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
    }

    @isTest
    static void testCVSFileLastChunk() {
        String testContent = 'Last chunk content for CVS';
        String testFileName = 'cvs_test_file.txt';
        Boolean sendFilesToTestSites = true;
        Boolean isFirst = false;
        Boolean isFinish = true;
        Integer lastLine = 300;
        String testFileType = 'CVS';

        Test.setMock(HttpCalloutMock.class, new S3MockSuccess());

        ARC_QueableSendFileBatchPOC job = new ARC_QueableSendFileBatchPOC(
            testContent, testFileName, testFileType, sendFilesToTestSites, isFirst, isFinish, lastLine
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
    }

    @isTest
    static void testSureCoFileSmallBatch() {
        String testContent = 'Test content for SureCo - Small Batch';
        String testFileName = 'sureco_small_batch.txt';
        Integer testMemberCount = 10;
        String testFileType = 'Eligibility';

        ARC_QueableSendFileBatchPOC job = new ARC_QueableSendFileBatchPOC(
            testContent, testFileName, testFileType, testMemberCount
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
    }

    @isTest
    static void testQwikPayFileFirstBatch() {
        String testContent = 'First batch content for QwikPay';
        String testFileName = 'qwikpay_first_batch.txt';
        Boolean isFirst = true;
        Boolean isFinish = false;
        String testSiteName = 'QwikPaySite';
        String testMoveToSite = 'ArchiveSite';
        String testMoveToPath = '/archive/qwikpay/';
        String testFileType = 'QwikPay';

        ARC_QueableSendFileBatchPOC job = new ARC_QueableSendFileBatchPOC(
            testContent, testFileName, testFileType, isFirst, isFinish, testSiteName, testMoveToSite, testMoveToPath
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
        
        // QwikPay uses @Future method which sends test emails in test context
    }

    @isTest
    static void testQwikPayFileLastBatch() {
        String testContent = 'Last batch content for QwikPay';
        String testFileName = 'qwikpay_last_batch.txt';
        Boolean isFirst = false;
        Boolean isFinish = true;
        String testSiteName = 'QwikPaySite';
        String testMoveToSite = 'ArchiveSite';
        String testMoveToPath = '/archive/qwikpay/';
        String testFileType = 'QwikPay';

        ARC_QueableSendFileBatchPOC job = new ARC_QueableSendFileBatchPOC(
            testContent, testFileName, testFileType, isFirst, isFinish, testSiteName, testMoveToSite, testMoveToPath
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
        
        // QwikPay uses @Future method
    }

    @isTest
    static void testEmailNotificationMethod() {
        Test.startTest();
        
        // Call the static email notification method directly
        ARC_QueableSendFileBatchPOC.sendEmailNotification(
            'Test error body',
            'Test Error Subject',
            System.Label.ARC_ApexErrorEmail
        );
        
        Test.stopTest();
    }

    @isTest
    static void testCVSS3ErrorWithFallback() {
        String testContent = 'Content that will trigger S3 error';
        String testFileName = 'cvs_error_fallback.txt';
        Boolean sendFilesToTestSites = true;
        Boolean isFirst = true;
        Boolean isFinish = false;
        Integer lastLine = 100;
        String testFileType = 'CVS';

        Test.setMock(HttpCalloutMock.class, new S3MockFailure());

        ARC_QueableSendFileBatchPOC job = new ARC_QueableSendFileBatchPOC(
            testContent, testFileName, testFileType, sendFilesToTestSites, isFirst, isFinish, lastLine
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
    }

    @isTest
    static void testMultipleConstructorPaths() {
        Test.startTest();
        
        // Test all 4 constructors with different parameters
        ARC_QueableSendFileBatchPOC job1 = new ARC_QueableSendFileBatchPOC(
            'content1', 'file1.txt', 100, true, 123.45, 'Zelis'
        );
        
        ARC_QueableSendFileBatchPOC job2 = new ARC_QueableSendFileBatchPOC(
            'content2', 'file2.txt', 'CVS', true, true, true, 200
        );
        
        ARC_QueableSendFileBatchPOC job3 = new ARC_QueableSendFileBatchPOC(
            'content3', 'file3.txt', 'Eligibility', 500
        );
        
        ARC_QueableSendFileBatchPOC job4 = new ARC_QueableSendFileBatchPOC(
            'content4', 'file4.txt', 'QwikPay', true, true, 'site1', 'site2', '/path/'
        );
        
        // Verify all constructors work
        System.assertNotEquals(null, job1, 'Job 1 should be created');
        System.assertNotEquals(null, job2, 'Job 2 should be created');
        System.assertNotEquals(null, job3, 'Job 3 should be created');
        System.assertNotEquals(null, job4, 'Job 4 should be created');
        
        Test.stopTest();
    }

    // Tests with bypass flag to cover production code paths without actual FTP callouts
    @isTest
    static void testHandleOnFinishWithBypass() {
        // Create state record for the file to simulate a multi-part upload in progress
        ARC_S3UploadState__c stateRecord = new ARC_S3UploadState__c(
            ARC_FilePath__c = 'cvs_handleonfinish.txt',
            ARC_UploadId__c = 'testUploadIdForFinish',
            ARC_NextPartNumber__c = 2,
            ARC_LastUpdated__c = System.now()
        );
        insert stateRecord;
        
        // Also need to save a part ETag for the completion
        ARC_S3UploadStateManager.savePartETag('cvs_handleonfinish.txt', 1, '"etag1"');
        
        ARC_QueableSendFileBatchPOC.bypassTestChecks = true;
        
        String testContent = 'Content for handleOnFinish test';
        String testFileName = 'cvs_handleonfinish.txt';
        Boolean sendFilesToTestSites = true;
        Boolean isFirst = false;
        Boolean isFinish = true;
        Integer lastLine = 100;
        String testFileType = 'CVS';

        Test.setMock(HttpCalloutMock.class, new S3MockSuccess());

        ARC_QueableSendFileBatchPOC job = new ARC_QueableSendFileBatchPOC(
            testContent, testFileName, testFileType, sendFilesToTestSites, isFirst, isFinish, lastLine
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
        
        ARC_QueableSendFileBatchPOC.bypassTestChecks = false;
    }

    @isTest
    static void testQwikPayWithBypass() {
        ARC_QueableSendFileBatchPOC.bypassTestChecks = true;
        
        String testContent = 'QwikPay bypass test';
        String testFileName = 'qwikpay_bypass.txt';
        Boolean isFirst = true;
        Boolean isFinish = false;
        String testSiteName = 'QwikPaySite';
        String testMoveToSite = 'ArchiveSite';
        String testMoveToPath = '/archive/';
        String testFileType = 'QwikPay';

        ARC_QueableSendFileBatchPOC job = new ARC_QueableSendFileBatchPOC(
            testContent, testFileName, testFileType, isFirst, isFinish, testSiteName, testMoveToSite, testMoveToPath
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
        
        ARC_QueableSendFileBatchPOC.bypassTestChecks = false;
    }

    // Mock class for successful S3 operations
    private class S3MockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            String method = req.getMethod();
            
            if (method == 'POST' && endpoint.contains('uploads')) {
                // Initialize multipart upload
                res.setStatusCode(200);
                String xmlResponse = '<?xml version="1.0" encoding="UTF-8"?>' +
                    '<InitiateMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">' +
                    '<UploadId>testUploadId123456</UploadId>' +
                    '</InitiateMultipartUploadResult>';
                res.setBody(xmlResponse);
            } else if (method == 'PUT' && endpoint.contains('partNumber=')) {
                // Upload part
                res.setStatusCode(200);
                res.setHeader('ETag', '"abc123def456"');
            } else if (method == 'POST' && endpoint.contains('uploadId=')) {
                // Complete multipart upload
                res.setStatusCode(200);
                String xmlResponse = '<?xml version="1.0" encoding="UTF-8"?>' +
                    '<CompleteMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">' +
                    '<Location>https://s3.amazonaws.com/bucket/test/file.txt</Location>' +
                    '<ETag>"finalEtag123"</ETag>' +
                    '</CompleteMultipartUploadResult>';
                res.setBody(xmlResponse);
            } else {
                res.setStatusCode(200);
            }
            
            return res;
        }
    }

    // Mock class for S3 error scenarios
    private class S3MockFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('<Error><Code>InternalError</Code><Message>S3 Internal Error</Message></Error>');
            return res;
        }
    }
}