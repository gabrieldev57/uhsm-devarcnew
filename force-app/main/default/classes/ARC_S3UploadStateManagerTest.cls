@isTest
public class ARC_S3UploadStateManagerTest {
    
    @TestSetup
    static void setup() {
        // Create test records for Delete_Object__c
        // Note: Adjust field names based on your actual custom object schema
    }
    
    @isTest
    static void testSaveAndGetUploadId() {
        String testFileName = 'test_file.txt';
        String testUploadId = 'testUploadId123';
        Integer testPartNumber = 5;
        
        Test.startTest();
        
        // Save upload ID
        ARC_S3UploadStateManager.saveUploadId(testFileName, testUploadId, testPartNumber);
        
        // Retrieve upload ID
        String retrievedUploadId = ARC_S3UploadStateManager.getUploadId(testFileName);
        
        System.assertEquals(testUploadId, retrievedUploadId, 'Should retrieve same upload ID');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetUploadState() {
        String testFileName = 'test_file_state.txt';
        String testUploadId = 'uploadIdABC456';
        Integer testPartNumber = 3;
        
        Test.startTest();
        
        // Save state
        ARC_S3UploadStateManager.saveUploadId(testFileName, testUploadId, testPartNumber);
        
        // Get full state
        ARC_S3UploadStateManager.UploadState state = ARC_S3UploadStateManager.getUploadState(testFileName);
        
        System.assertEquals(testUploadId, state.uploadId, 'Upload ID should match');
        System.assertEquals(testPartNumber, state.nextPartNumber, 'Part number should match');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetUploadStateNotFound() {
        Test.startTest();
        
        ARC_S3UploadStateManager.UploadState state = ARC_S3UploadStateManager.getUploadState('nonexistent_file.txt');
        
        System.assertEquals(null, state.uploadId, 'Upload ID should be null for non-existent file');
        System.assertEquals(1, state.nextPartNumber, 'Next part should default to 1');
        
        Test.stopTest();
    }
    
    @isTest
    static void testSaveAndGetPartETag() {
        String testFileName = 'test_parts.txt';
        Integer partNumber1 = 1;
        Integer partNumber2 = 2;
        String etag1 = 'etag123abc';
        String etag2 = 'etag456def';
        
        Test.startTest();
        
        // Save part ETags
        ARC_S3UploadStateManager.savePartETag(testFileName, partNumber1, etag1);
        ARC_S3UploadStateManager.savePartETag(testFileName, partNumber2, etag2);
        
        // Retrieve all parts
        Map<Integer, String> parts = ARC_S3UploadStateManager.getUploadedParts(testFileName);
        
        System.assertEquals(2, parts.size(), 'Should have 2 parts');
        System.assertEquals(etag1, parts.get(partNumber1), 'Part 1 ETag should match');
        System.assertEquals(etag2, parts.get(partNumber2), 'Part 2 ETag should match');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetUploadedPartsEmpty() {
        Test.startTest();
        
        Map<Integer, String> parts = ARC_S3UploadStateManager.getUploadedParts('no_parts_file.txt');
        
        System.assertNotEquals(null, parts, 'Parts map should not be null');
        System.assertEquals(0, parts.size(), 'Parts map should be empty');
        
        Test.stopTest();
    }
    
    @isTest
    static void testClearUploadId() {
        String testFileName = 'test_clear.txt';
        String testUploadId = 'uploadClear789';
        
        Test.startTest();
        
        // Save state and parts
        ARC_S3UploadStateManager.saveUploadId(testFileName, testUploadId, 1);
        ARC_S3UploadStateManager.savePartETag(testFileName, 1, 'etag1');
        ARC_S3UploadStateManager.savePartETag(testFileName, 2, 'etag2');
        
        // Verify they exist
        String uploadId = ARC_S3UploadStateManager.getUploadId(testFileName);
        System.assertEquals(testUploadId, uploadId, 'Upload ID should exist before clear');
        
        Map<Integer, String> partsBefore = ARC_S3UploadStateManager.getUploadedParts(testFileName);
        System.assertEquals(2, partsBefore.size(), 'Should have 2 parts before clear');
        
        // Clear everything
        ARC_S3UploadStateManager.clearUploadId(testFileName);
        
        // Verify cleared
        String clearedUploadId = ARC_S3UploadStateManager.getUploadId(testFileName);
        System.assertEquals(null, clearedUploadId, 'Upload ID should be null after clear');
        
        Map<Integer, String> partsAfter = ARC_S3UploadStateManager.getUploadedParts(testFileName);
        System.assertEquals(0, partsAfter.size(), 'Parts should be empty after clear');
        
        Test.stopTest();
    }
    
    @isTest
    static void testSaveUploadIdWithNullValues() {
        Test.startTest();
        
        // Should handle null gracefully without throwing exceptions
        ARC_S3UploadStateManager.saveUploadId(null, 'uploadId', 1);
        ARC_S3UploadStateManager.saveUploadId('file.txt', null, 1);
        ARC_S3UploadStateManager.saveUploadId('', 'uploadId', 1);
        
        // Should not crash
        System.assert(true, 'Should handle null values gracefully');
        
        Test.stopTest();
    }
    
    @isTest
    static void testSavePartETagWithNullValues() {
        Test.startTest();
        
        // Should handle null gracefully without throwing exceptions
        ARC_S3UploadStateManager.savePartETag(null, 1, 'etag');
        ARC_S3UploadStateManager.savePartETag('file.txt', null, 'etag');
        ARC_S3UploadStateManager.savePartETag('file.txt', 1, null);
        
        // Should not crash
        System.assert(true, 'Should handle null values gracefully');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetUploadIdWithNullOrEmpty() {
        Test.startTest();
        
        String result1 = ARC_S3UploadStateManager.getUploadId(null);
        String result2 = ARC_S3UploadStateManager.getUploadId('');
        
        System.assertEquals(null, result1, 'Should return null for null filename');
        System.assertEquals(null, result2, 'Should return null for empty filename');
        
        Test.stopTest();
    }
    
    @isTest
    static void testClearUploadIdWithNullOrEmpty() {
        Test.startTest();
        
        // Should not throw exceptions
        ARC_S3UploadStateManager.clearUploadId(null);
        ARC_S3UploadStateManager.clearUploadId('');
        
        System.assert(true, 'Should handle null/empty values gracefully');
        
        Test.stopTest();
    }
    
    @isTest
    static void testSaveUploadIdOverwrite() {
        String testFileName = 'overwrite_test.txt';
        
        Test.startTest();
        
        // Save first time
        ARC_S3UploadStateManager.saveUploadId(testFileName, 'uploadId1', 1);
        String firstId = ARC_S3UploadStateManager.getUploadId(testFileName);
        System.assertEquals('uploadId1', firstId, 'First upload ID should be saved');
        
        // Overwrite with new upload ID
        ARC_S3UploadStateManager.saveUploadId(testFileName, 'uploadId2', 3);
        String secondId = ARC_S3UploadStateManager.getUploadId(testFileName);
        System.assertEquals('uploadId2', secondId, 'Second upload ID should overwrite first');
        
        ARC_S3UploadStateManager.UploadState state = ARC_S3UploadStateManager.getUploadState(testFileName);
        System.assertEquals(3, state.nextPartNumber, 'Next part number should be updated');
        
        Test.stopTest();
    }
    
    @isTest
    static void testMultipleFilesConcurrent() {
        String file1 = 'concurrent_file_1.txt';
        String file2 = 'concurrent_file_2.txt';
        String file3 = 'concurrent_file_3.txt';
        
        Test.startTest();
        
        // Save state for multiple files
        ARC_S3UploadStateManager.saveUploadId(file1, 'upload1', 1);
        ARC_S3UploadStateManager.saveUploadId(file2, 'upload2', 2);
        ARC_S3UploadStateManager.saveUploadId(file3, 'upload3', 3);
        
        ARC_S3UploadStateManager.savePartETag(file1, 1, 'etag1a');
        ARC_S3UploadStateManager.savePartETag(file2, 1, 'etag2a');
        ARC_S3UploadStateManager.savePartETag(file2, 2, 'etag2b');
        
        // Verify each file maintains its own state
        String id1 = ARC_S3UploadStateManager.getUploadId(file1);
        String id2 = ARC_S3UploadStateManager.getUploadId(file2);
        String id3 = ARC_S3UploadStateManager.getUploadId(file3);
        
        System.assertEquals('upload1', id1, 'File 1 upload ID should be correct');
        System.assertEquals('upload2', id2, 'File 2 upload ID should be correct');
        System.assertEquals('upload3', id3, 'File 3 upload ID should be correct');
        
        Map<Integer, String> parts1 = ARC_S3UploadStateManager.getUploadedParts(file1);
        Map<Integer, String> parts2 = ARC_S3UploadStateManager.getUploadedParts(file2);
        
        System.assertEquals(1, parts1.size(), 'File 1 should have 1 part');
        System.assertEquals(2, parts2.size(), 'File 2 should have 2 parts');
        
        Test.stopTest();
    }
}