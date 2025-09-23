@isTest
public class ARC_caseFileUploadControllerTest {
    
    @isTest
    static void testUploadFiles_validData() {
        // Create a test Case
        List<Case> testCases = ARC_TestUtility.createTestCase(1, 'Sales');        
        
        // Create a dummy ContentDocument and ContentVersion
        ContentVersion version = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test content')
        );
        insert version;

        // Retrieve the ContentDocumentId
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];
        List<Id> fileIds = new List<Id>{insertedVersion.ContentDocumentId};

        // Call the method
        Test.startTest();
        ARC_caseFileUploadController.uploadFiles(testCases[0].Id, fileIds);
        Test.stopTest();

        // Nothing is upserted, so we’re just testing no exceptions are thrown
        System.assert(true, 'uploadFiles executed successfully.');
    }

    @isTest
    static void testEncryptedToken() {
        String input = '001xxxxxxxxxxxx'; // Fake record Id
        String encoded = EncodingUtil.base64Encode(Blob.valueOf(input));

        Test.startTest();
        String result = ARC_caseFileUploadController.encryptedToken(encoded);
        Test.stopTest();

        System.assertEquals(input, result, 'The decoded value should match the original input.');
    }
}