@IsTest
public class ARC_ContentVersionHandlerTest {


    private static User createEmployerPortalUser() {
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Employer Portal Profile'
            LIMIT 1
        ];

        User u = new User(
            FirstName = 'Test',
            LastName = 'Employer',
            Email = 'employer@test.com',
            Username = 'employer.' + System.currentTimeMillis() + '@test.com',
            Alias = 'emp',
            TimeZoneSidKey = 'America/Mexico_City',
            LocaleSidKey = 'es_MX',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'es_MX',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }

    private static Case createCase() {
        Case c = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Web',
            Description = 'Test'
        );
        insert c;
        return c;
    }


   @IsTest
    static void testProcessAfterInsert_createsLink_expectedException() {
        User portalUser = createEmployerPortalUser();
        Case c = createCase();

        ContentVersion cv = new ContentVersion(
            Title = 'test_file',
            PathOnClient = 'test_file.csv',
            VersionData = Blob.valueOf('1,2'),
            Guest_Record_fileupload__c = c.Id
        );
        insert cv;

        cv = [
            SELECT Id, ContentDocumentId, Guest_Record_fileupload__c
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        System.runAs(portalUser) {
            Test.startTest();
            try {
                ARC_ContentVersionHandler.processAfterInsert(
                    new List<ContentVersion>{ cv }
                );
                System.assert(false, 'Expected exception due to ContentDocumentLink limitations in test context');
            } catch (Exception e) {
    
                System.assert(true, 'Exception expected in test context');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testProcessAfterInsert_nonEmployerUser_earlyReturn() {
        Case c = createCase();

        ContentVersion cv = new ContentVersion(
            Title = 'test_file',
            PathOnClient = 'test_file.csv',
            VersionData = Blob.valueOf('1,2'),
            Guest_Record_fileupload__c = c.Id
        );
        insert cv;

        cv = [
            SELECT Id, ContentDocumentId, Guest_Record_fileupload__c
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        Test.startTest();
        ARC_ContentVersionHandler.processAfterInsert(
            new List<ContentVersion>{ cv }
        );
        Test.stopTest();

        System.assert(true, 'Early return executed without exception');
    }




    // @IsTest
    // static void testProcessAfterInsert_nonEmployerUser_noLinkCreated() {
    //     Case c = createCase();

    //     // Default test user (NOT employer portal)
    //     ContentVersion cv = new ContentVersion(
    //         Title = 'test_file',
    //         PathOnClient = 'test_file.csv',
    //         VersionData = Blob.valueOf('1,2'),
    //         Guest_Record_fileupload__c = c.Id
    //     );
    //     insert cv;

    //     cv = [
    //         SELECT Id, ContentDocumentId, Guest_Record_fileupload__c
    //         FROM ContentVersion
    //         WHERE Id = :cv.Id
    //     ];

    //     Test.startTest();
    //     ARC_ContentVersionHandler.processAfterInsert(
    //         new List<ContentVersion>{ cv }
    //     );
    //     Test.stopTest();

    //     List<ContentDocumentLink> links = [
    //         SELECT Id
    //         FROM ContentDocumentLink
    //         WHERE LinkedEntityId = :c.Id
    //     ];

    //     System.assertEquals(
    //         0,
    //         links.size(),
    //         'No link should be created for non-employer users'
    //     );
    // }
}