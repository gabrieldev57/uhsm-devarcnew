@isTest
public class ARC_DocGenDirectInvokerTest {

    @isTest
    static void testGenerateDocumentWithTokenData_Success() {
        // Create a dummy record to act as referenceObjectId
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Dummy ContentVersion Id (simulate template)
        ContentVersion cv = new ContentVersion(
            Title = 'Test Template',
            PathOnClient = 'TestTemplate.docx',
            VersionData = Blob.valueOf('Dummy content')
        );
        insert cv;

        // Retrieve ContentVersion Id
        Id templateId = [SELECT Id FROM ContentVersion WHERE Id = :cv.Id].Id;

        Map<String, Object> tokenData = new Map<String, Object>{
            'Name' => 'John Doe',
            'Amount' => 100
        };

        Test.startTest();
        Id processId = ARC_DocGenDirectInvoker.generateDocumentWithTokenData(
            acc.Id,
            templateId,
            tokenData,
            'Test Document'
        );
        Test.stopTest();

        System.assertNotEquals(null, processId, 'Process Id should not be null');

        DocumentGenerationProcess insertedRecord = [
            SELECT Id, RequestText, TokenData, ReferenceObject
            FROM DocumentGenerationProcess
            WHERE Id = :processId
            LIMIT 1
        ];

        System.assertEquals(acc.Id, insertedRecord.ReferenceObject);
        System.assert(insertedRecord.RequestText.contains('Test Document'));
        System.assert(insertedRecord.TokenData.contains('John Doe'));
    }

    @isTest
    static void testGenerateDocumentWithTokenData_DefaultTitle() {
        Account acc = new Account(Name = 'Test Account 3');
        insert acc;

        ContentVersion cv = new ContentVersion(
            Title = 'Template 3',
            PathOnClient = 'Template3.docx',
            VersionData = Blob.valueOf('Dummy content')
        );
        insert cv;

        Test.startTest();
        Id processId = ARC_DocGenDirectInvoker.generateDocumentWithTokenData(
            acc.Id,
            cv.Id,
            new Map<String, Object>{'Key' => 'Value'},
            null // trigger default title
        );
        Test.stopTest();

        DocumentGenerationProcess rec = [
            SELECT RequestText
            FROM DocumentGenerationProcess
            WHERE Id = :processId
        ];

        System.assert(rec.RequestText.contains('Generated Document'), 
            'Default title should be applied');
    }

    @isTest
    static void testGenerateDocumentWithTokenData_NullReferenceObject() {
        try {
            Test.startTest();
            ARC_DocGenDirectInvoker.generateDocumentWithTokenData(
                null,
                '068XXXXXXXXXXXX', // dummy Id
                new Map<String, Object>(),
                'Test'
            );
            Test.stopTest();
            System.assert(false, 'Exception should have been thrown');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('referenceObjectId must be provided'));
        }
    }

    @isTest
    static void testGenerateDocumentWithTokenData_BlankTemplateId() {
        Account acc = new Account(Name = 'Test Account 4');
        insert acc;

        try {
            Test.startTest();
            ARC_DocGenDirectInvoker.generateDocumentWithTokenData(
                acc.Id,
                '',
                new Map<String, Object>(),
                'Test'
            );
            Test.stopTest();
            System.assert(false, 'Exception should have been thrown');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('templateContentVersionId must be provided'));
        }
    }
}