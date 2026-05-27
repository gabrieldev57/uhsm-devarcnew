@IsTest
public class ARC_EmployerCaseFileUploadControllerTest {

    private static Case createCase(String status) {
        Case c = new Case(
            Subject = 'Test Case',
            Status = status,
            Origin = 'Web',
            Description = 'Test description'
        );
        insert c;
        return c;
    }

    private static ContentVersion createCsvFile(Id linkedEntityId) {
        ContentVersion cv = new ContentVersion(
            Title = 'test_file',
            PathOnClient = 'test_file.csv',
            VersionData = Blob.valueOf('col1,col2\n1,2'),
            IsMajorVersion = true
        );
        insert cv;

        cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = linkedEntityId,
            ShareType = 'V'
        );
        insert cdl;

        return cv;
    }

    @IsTest
    static void testUpdateCaseAndReplaceFile_success() {
        Case c = createCase('New');
        
        ContentVersion oldFile = createCsvFile(c.Id);
        
        ContentVersion newFile = new ContentVersion(
            Title = 'new_test_file',
            PathOnClient = 'new_test_file.csv',
            VersionData = Blob.valueOf('col1,col2\n3,4'),
            IsMajorVersion = true
        );
        insert newFile;
        
        newFile = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :newFile.Id
            LIMIT 1
        ];

        Map<String, Object> params = new Map<String, Object>{
            'caseId' => c.Id,
            'newContentVersionId' => newFile.Id
        };

        Test.startTest();
        ARC_EmployerCaseFileUploadController.updateCaseAndReplaceFile(params);
        Test.stopTest();

        Case updatedCase = [
            SELECT Status
            FROM Case
            WHERE Id = :c.Id
        ];
        System.assertEquals('In Progress', updatedCase.Status, 'Case status should be updated');

        List<ContentDocumentLink> remainingLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :c.Id
        ];
        System.assertEquals(1, remainingLinks.size(), 'Only the new file should remain linked');
    }

    @IsTest
    static void testUpdateCaseAndReplaceFile_missingParams() {
        Map<String, Object> params = new Map<String, Object>();

        Test.startTest();
        try {
            ARC_EmployerCaseFileUploadController.updateCaseAndReplaceFile(params);
            System.assert(false, 'Exception should have been thrown');
        } catch (Exception e) {
            System.assert(
                e instanceof AuraHandledException,
                'Expected AuraHandledException'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testEncryptedToken_success() {
        String original = 'CASE123';
        String encoded = EncodingUtil.base64Encode(Blob.valueOf(original));

        Test.startTest();
        String result = ARC_EmployerCaseFileUploadController.encryptedToken(encoded);
        Test.stopTest();

        System.assertEquals(original, result, 'Decoded value should match original');
    }

    @IsTest
    static void testEncryptedToken_error() {
        Test.startTest();
        try {
            ARC_EmployerCaseFileUploadController.encryptedToken('%%%invalid%%%');
            System.assert(false, 'Exception should have been thrown');
        } catch (Exception e) {
            System.assert(
                e instanceof AuraHandledException,
                'Expected AuraHandledException'
            );
        }
        Test.stopTest();
    }

}