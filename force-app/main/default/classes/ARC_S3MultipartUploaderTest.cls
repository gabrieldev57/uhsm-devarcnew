@isTest
public class ARC_S3MultipartUploaderTest {
    
    @isTest
    static void testConstructors() {
        Test.startTest();
        
        // Test single parameter constructor
        ARC_S3MultipartUploader uploader1 = new ARC_S3MultipartUploader('test/file.txt');
        System.assertNotEquals(null, uploader1, 'Uploader should be instantiated');
        
        // Test two parameter constructor
        ARC_S3MultipartUploader uploader2 = new ARC_S3MultipartUploader('test/file.txt', 'uploadId123');
        System.assertNotEquals(null, uploader2, 'Uploader should be instantiated with uploadId');
        
        // Test three parameter constructor
        ARC_S3MultipartUploader uploader3 = new ARC_S3MultipartUploader('test/file.txt', 'uploadId456', 5);
        System.assertNotEquals(null, uploader3, 'Uploader should be instantiated with all parameters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testConstructorWithInvalidPath() {
        Test.startTest();
        
        Boolean exceptionThrown = false;
        try {
            ARC_S3MultipartUploader uploader = new ARC_S3MultipartUploader('');
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('filePath cannot be null or empty'), 'Should throw correct error message');
        }
        
        System.assert(exceptionThrown, 'Exception should be thrown for empty file path');
        
        Test.stopTest();
    }
    
    @isTest
    static void testInitializeUploadSuccess() {
        Test.setMock(HttpCalloutMock.class, new S3InitializeUploadMock(200));
        
        Test.startTest();
        
        ARC_S3MultipartUploader uploader = new ARC_S3MultipartUploader('test/file.txt');
        String uploadId = uploader.initializeUpload();
        
        System.assertNotEquals(null, uploadId, 'Upload ID should not be null');
        System.assert(uploadId.length() > 0, 'Upload ID should have content');
        
        Test.stopTest();
    }
    
    @isTest
    static void testInitializeUploadFailure() {
        Test.setMock(HttpCalloutMock.class, new S3InitializeUploadMock(500));
        
        Test.startTest();
        
        Boolean exceptionThrown = false;
        try {
            ARC_S3MultipartUploader uploader = new ARC_S3MultipartUploader('test/file.txt');
            String uploadId = uploader.initializeUpload();
        } catch (ARC_S3MultipartUploader.S3Exception e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Failed to initialize'), 'Should contain failure message');
        }
        
        System.assert(exceptionThrown, 'Exception should be thrown for failed initialization');
        
        Test.stopTest();
    }
    
    @isTest
    static void testUploadPartSuccess() {
        Test.setMock(HttpCalloutMock.class, new S3UploadPartMock(200));
        
        Test.startTest();
        
        ARC_S3MultipartUploader uploader = new ARC_S3MultipartUploader('test/file.txt', 'testUploadId123', 1);
        String etag = uploader.uploadPart(1, 'Test content for part 1');
        
        System.assertNotEquals(null, etag, 'ETag should not be null');
        System.assert(etag.length() > 0, 'ETag should have content');
        
        Test.stopTest();
    }
    
    @isTest
    static void testUploadNextPart() {
        Test.setMock(HttpCalloutMock.class, new S3UploadPartMock(200));
        
        Test.startTest();
        
        ARC_S3MultipartUploader uploader = new ARC_S3MultipartUploader('test/file.txt', 'testUploadId123', 1);
        String etag1 = uploader.uploadNextPart('Content chunk 1');
        String etag2 = uploader.uploadNextPart('Content chunk 2');
        
        System.assertNotEquals(null, etag1, 'First ETag should not be null');
        System.assertNotEquals(null, etag2, 'Second ETag should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testCompleteUploadWithMap() {
        Test.setMock(HttpCalloutMock.class, new S3CompleteUploadMock(200));
        
        Test.startTest();
        
        ARC_S3MultipartUploader uploader = new ARC_S3MultipartUploader('test/file.txt', 'testUploadId123', 1);
        Map<Integer, String> parts = new Map<Integer, String>{
            1 => 'etag1',
            2 => 'etag2'
        };
        
        // Should not throw exception
        uploader.completeUpload(parts);
        
        Test.stopTest();
    }
    
    @isTest
    static void testAbortUpload() {
        Test.setMock(HttpCalloutMock.class, new S3AbortUploadMock(204));
        
        Test.startTest();
        
        ARC_S3MultipartUploader uploader = new ARC_S3MultipartUploader('test/file.txt', 'testUploadId123', 1);
        
        // Should not throw exception
        uploader.abortUpload();
        
        Test.stopTest();
    }
    
    @isTest
    static void testEncodeS3Path() {
        Test.startTest();
        
        // Test constructor with complex path (internal encodeS3Path will be used)
        ARC_S3MultipartUploader uploader = new ARC_S3MultipartUploader('folder/subfolder/file with spaces.txt', 'uploadId789', 3);
        
        System.assertNotEquals(null, uploader, 'Uploader should handle paths with spaces');
        
        Test.stopTest();
    }
    
    // Mock classes for HTTP callouts
    private class S3InitializeUploadMock implements HttpCalloutMock {
        Integer statusCode;
        
        public S3InitializeUploadMock(Integer statusCode) {
            this.statusCode = statusCode;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            
            if (statusCode == 200) {
                String xmlResponse = '<?xml version="1.0" encoding="UTF-8"?>' +
                    '<InitiateMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">' +
                    '<Bucket>test-bucket</Bucket>' +
                    '<Key>test/file.txt</Key>' +
                    '<UploadId>testUploadId12345</UploadId>' +
                    '</InitiateMultipartUploadResult>';
                res.setBody(xmlResponse);
            } else {
                res.setBody('<Error><Code>InternalError</Code><Message>Test error</Message></Error>');
            }
            
            return res;
        }
    }
    
    private class S3UploadPartMock implements HttpCalloutMock {
        Integer statusCode;
        
        public S3UploadPartMock(Integer statusCode) {
            this.statusCode = statusCode;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setHeader('ETag', '"abc123def456"');
            return res;
        }
    }
    
    private class S3CompleteUploadMock implements HttpCalloutMock {
        Integer statusCode;
        
        public S3CompleteUploadMock(Integer statusCode) {
            this.statusCode = statusCode;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            
            if (statusCode == 200) {
                String xmlResponse = '<?xml version="1.0" encoding="UTF-8"?>' +
                    '<CompleteMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">' +
                    '<Location>https://s3.amazonaws.com/bucket/test/file.txt</Location>' +
                    '<Bucket>bucket</Bucket>' +
                    '<Key>test/file.txt</Key>' +
                    '<ETag>"etag123"</ETag>' +
                    '</CompleteMultipartUploadResult>';
                res.setBody(xmlResponse);
            } else {
                res.setBody('<Error><Code>EntityTooSmall</Code><Message>Part too small</Message></Error>');
            }
            
            return res;
        }
    }
    
    private class S3AbortUploadMock implements HttpCalloutMock {
        Integer statusCode;
        
        public S3AbortUploadMock(Integer statusCode) {
            this.statusCode = statusCode;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            return res;
        }
    }
    
    // Multi-purpose mock that handles upload and complete requests
    private class S3MultiMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            
            // Check request type based on URL and method
            String endpoint = req.getEndpoint();
            String method = req.getMethod();
            
            if (method == 'PUT' && endpoint.contains('partNumber=')) {
                // Upload part request
                res.setStatusCode(200);
                res.setHeader('ETag', '"abc123def456"');
            } else if (method == 'POST' && endpoint.contains('uploadId=')) {
                // Complete upload request
                res.setStatusCode(200);
                String xmlResponse = '<?xml version="1.0" encoding="UTF-8"?>' +
                    '<CompleteMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">' +
                    '<Location>https://s3.amazonaws.com/bucket/test/file.txt</Location>' +
                    '<Bucket>bucket</Bucket>' +
                    '<Key>test/file.txt</Key>' +
                    '<ETag>"etag123"</ETag>' +
                    '</CompleteMultipartUploadResult>';
                res.setBody(xmlResponse);
            } else {
                // Default response
                res.setStatusCode(200);
            }
            
            return res;
        }
    }
}