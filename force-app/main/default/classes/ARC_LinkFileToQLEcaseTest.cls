@isTest
private class ARC_LinkFileToQLEcaseTest {

    @isTest
    static void testReLinkFiles_Success() {

        // Create Account (Person Account if enabled, otherwise standard Account works for test)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Case
        Case cs = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            AccountId = acc.Id,
            Description = 'Test Description'
        );
        insert cs;

        // Create first file
        ContentVersion cv1 = new ContentVersion(
            Title = 'Test File 1',
            PathOnClient = 'TestFile1.txt',
            VersionData = Blob.valueOf('Test data 1')
        );
        insert cv1;

        Id docId1 = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv1.Id
        ].ContentDocumentId;

        // Create second file (this will be the "lastDocumentId")
        ContentVersion cv2 = new ContentVersion(
            Title = 'Test File 2',
            PathOnClient = 'TestFile2.txt',
            VersionData = Blob.valueOf('Test data 2')
        );
        insert cv2;

        Id docId2 = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv2.Id
        ].ContentDocumentId;

        // Link both files to Account
        List<ContentDocumentLink> links = new List<ContentDocumentLink>{
            new ContentDocumentLink(
                ContentDocumentId = docId1,
                LinkedEntityId = acc.Id,
                ShareType = 'V'
            ),
            new ContentDocumentLink(
                ContentDocumentId = docId2,
                LinkedEntityId = acc.Id,
                ShareType = 'V'
            )
        };
        insert links;

        // Prepare request
        ARC_LinkFileToQLEcase.Request req = new ARC_LinkFileToQLEcase.Request();
        req.contentDocumentIds = new List<String>{docId1, docId2};
        req.caseId = cs.Id;
        req.personAccountId = acc.Id;

        Test.startTest();
        ARC_LinkFileToQLEcase.reLinkFiles(new List<ARC_LinkFileToQLEcase.Request>{req});
        Test.stopTest();

        // Validate: Only last document linked to Case
        List<ContentDocumentLink> caseLinks = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :cs.Id
        ];
        System.assertEquals(1, caseLinks.size());
        System.assertEquals(docId2, caseLinks[0].ContentDocumentId);

        // Validate: First document deleted
        Integer docCount = [
            SELECT COUNT()
            FROM ContentDocument
            WHERE Id = :docId1
        ];
        System.assertEquals(0, docCount);

        // Validate: Last document removed from Account
        Integer remainingLinks = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :acc.Id
            AND ContentDocumentId = :docId2
        ];
        System.assertEquals(0, remainingLinks);
    }

    @isTest
    static void testReLinkFiles_NoExtraDocs() {

        // Create Account
        Account acc = new Account(Name = 'Test Account 2');
        insert acc;

        // Create Case
        Case cs = new Case(
            Subject = 'Test Case 2',
            Status = 'New',
            Origin = 'Email',
            AccountId = acc.Id,
            Description = 'Test Description'
        );
        insert cs;

        // Create one file only
        ContentVersion cv = new ContentVersion(
            Title = 'Single File',
            PathOnClient = 'Single.txt',
            VersionData = Blob.valueOf('Only file')
        );
        insert cv;

        Id docId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id
        ].ContentDocumentId;

        // Link file to Account
        insert new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId = acc.Id,
            ShareType = 'V'
        );

        // Prepare request
        ARC_LinkFileToQLEcase.Request req = new ARC_LinkFileToQLEcase.Request();
        req.contentDocumentIds = new List<String>{docId};
        req.caseId = cs.Id;
        req.personAccountId = acc.Id;

        Test.startTest();
        ARC_LinkFileToQLEcase.reLinkFiles(new List<ARC_LinkFileToQLEcase.Request>{req});
        Test.stopTest();

        // Validate: File linked to Case
        List<ContentDocumentLink> caseLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :cs.Id
        ];
        System.assertEquals(1, caseLinks.size());
    }
}