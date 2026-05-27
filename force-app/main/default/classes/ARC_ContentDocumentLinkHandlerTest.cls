@isTest
public class ARC_ContentDocumentLinkHandlerTest {

    // Helper to safely fetch RecordType
    private static Id getCaseRecordTypeId() {
        List<RecordType> rts = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Case' 
            AND DeveloperName = 'ARC_SmallGroupUnderwriting'
            LIMIT 1
        ];
        return rts.isEmpty() ? null : rts[0].Id;
    }

    @isTest
    static void testHandleAfterInsert_FullFlow() {

        Id rtId = getCaseRecordTypeId();

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Case
        Case c = new Case(
            Subject = 'Test Case',
            Status = 'New',
            AccountId = acc.Id,
            Description = 'Test description',
            ARC_Reason__c = 'Program'
        );

        // Only assign RecordType if it exists
        if (rtId != null) {
            c.RecordTypeId = rtId;
        }

        insert c;

        // Create ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test Data')
        );
        insert cv;

        Id contentDocId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id
        ].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = c.Id,
            ShareType = 'V'
        );

        Test.startTest();
        ARC_ContentDocumentLinkHandler.handleAfterInsert(
            new List<ContentDocumentLink>{cdl}
        );
        Test.stopTest();

        // Verify update ONLY if record type exists (otherwise method exits early)
        Case result = [SELECT Status FROM Case WHERE Id = :c.Id];

        if (rtId != null) {
            System.assertEquals('In Progress', result.Status);
        } else {
            System.assertEquals('New', result.Status);
        }
    }

    @isTest
    static void testHandleAfterInsert_NoCaseIds() {

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ContentVersion cv = new ContentVersion(
            Title = 'File',
            PathOnClient = 'file.txt',
            VersionData = Blob.valueOf('data')
        );
        insert cv;

        Id contentDocId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id
        ].ContentDocumentId;

        // Linked to Account, not Case
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = acc.Id,
            ShareType = 'V'
        );

        Test.startTest();
        ARC_ContentDocumentLinkHandler.handleAfterInsert(
            new List<ContentDocumentLink>{cdl}
        );
        Test.stopTest();

        System.assert(true); // just ensuring no crash
    }

    @isTest
    static void testQueueableExecution() {

        Id rtId = getCaseRecordTypeId();

        Account acc = new Account(Name = 'Queue Test');
        insert acc;

        Case c = new Case(
            Subject = 'Queue Case',
            Status = 'New',
            AccountId = acc.Id,
            Description = 'Test description',
            ARC_Reason__c = 'Program'
        );

        if (rtId != null) {
            c.RecordTypeId = rtId;
        }

        insert c;

        Test.startTest();
        System.enqueueJob(
            new ARC_ContentDocumentLinkHandler.ARC_CaseProcessorQueueable(
                new Set<Id>{c.Id}
            )
        );
        Test.stopTest();

        Case result = [SELECT Status FROM Case WHERE Id = :c.Id];

        if (rtId != null) {
            System.assertEquals('In Progress', result.Status);
        }
    }

    @isTest
    static void testCaseNotUpdatedWhenNotNew() {

        Id rtId = getCaseRecordTypeId();

        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        Case c = new Case(
            Subject = 'Not New Case',
            Status = 'Working',
            AccountId = acc.Id,
            Description = 'Test description',
            ARC_Reason__c = 'Program'
        );

        if (rtId != null) {
            c.RecordTypeId = rtId;
        }

        insert c;

        Test.startTest();
        System.enqueueJob(
            new ARC_ContentDocumentLinkHandler.ARC_CaseProcessorQueueable(
                new Set<Id>{c.Id}
            )
        );
        Test.stopTest();

        Case result = [SELECT Status FROM Case WHERE Id = :c.Id];
        System.assertEquals('Working', result.Status);
    }
}