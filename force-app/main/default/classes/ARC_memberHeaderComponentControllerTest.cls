@isTest
private class ARC_memberHeaderComponentControllerTest {

    @isTest
    static void getMemberHeader_withFullData_returnsPopulatedDTO() {
        ARC_TestUtility.createCompleteEnrollments(1);

        Account acc = [
            SELECT Id, PersonContactId 
            FROM Account 
            WHERE FirstName LIKE 'PersonAccount Primary%' 
            LIMIT 1
        ];

        Test.startTest();
        ARC_memberHeaderComponentController.MemberHeaderDTO dto =
            ARC_memberHeaderComponentController.getMemberHeader(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, dto,               'DTO should not be null');
        System.assertNotEquals(null, dto.fullName,      'Full name should not be null');
        System.assertNotEquals(null, dto.initials,      'Initials should not be null');
        System.assertEquals('Active',   dto.status,     'Status should be Active');
        System.assertEquals(true,       dto.isActive,   'isActive should be true');
        System.assertEquals('•••-••-6789', dto.maskedSsn, 'Masked SSN mismatch');
        System.assertEquals(true,       dto.hasSsn,     'hasSsn should be true');
    }

    @isTest
    static void getMemberHeader_noCensusMember_defaultsPrimaryRelationship() {
        Id recordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('ARC_IFPPersonAccount')
            .getRecordTypeId();

        Account acc = new Account(
            RecordTypeId    = recordTypeId,
            FirstName       = 'Jane',
            LastName        = 'Smith',
            PersonBirthdate = Date.newInstance(1985, 1, 1)
        );
        insert acc;

        Test.startTest();
        ARC_memberHeaderComponentController.MemberHeaderDTO dto =
            ARC_memberHeaderComponentController.getMemberHeader(acc.Id);
        Test.stopTest();

        System.assertEquals('Primary',  dto.relationship, 'Should default to Primary');
        System.assertEquals(false,      dto.hasSsn,       'hasSsn should be false');
        System.assertEquals(null,       dto.maskedSsn,    'Masked SSN should be null');
    }

    @isTest
    static void getMemberHeader_nullAccountId_throwsException() {
        Test.startTest();
        try {
            ARC_memberHeaderComponentController.getMemberHeader(null);
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(true, 'Caught expected exception');
        }
        Test.stopTest();
    }

    @isTest
    static void getMemberHeader_noDob_ageAndDobAreNull() {
        Id recordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('ARC_IFPPersonAccount')
            .getRecordTypeId();

        Account acc = new Account(
            RecordTypeId = recordTypeId,
            FirstName    = 'No',
            LastName     = 'Dob'
        );
        insert acc;

        Test.startTest();
        ARC_memberHeaderComponentController.MemberHeaderDTO dto =
            ARC_memberHeaderComponentController.getMemberHeader(acc.Id);
        Test.stopTest();

        System.assertEquals(null, dto.dateOfBirth, 'DOB should be null');
        System.assertEquals(null, dto.age,         'Age should be null');
    }

    @isTest
    static void revealSsn_withCensusMember_returnsSsn() {
        ARC_TestUtility.createCompleteEnrollments(1);

        Account acc = [
            SELECT Id 
            FROM Account 
            WHERE FirstName LIKE 'PersonAccount Primary%' 
            LIMIT 1
        ];

        Test.startTest();
        String ssn = ARC_memberHeaderComponentController.revealSsn(acc.Id);
        Test.stopTest();

        System.assertEquals('123456789', ssn, 'SSN should match inserted value');
    }

    @isTest
    static void revealSsn_noCensusMember_returnsNull() {
        Id recordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('ARC_IFPPersonAccount')
            .getRecordTypeId();

        Account acc = new Account(
            RecordTypeId = recordTypeId,
            FirstName    = 'No',
            LastName     = 'Member'
        );
        insert acc;

        Test.startTest();
        String ssn = ARC_memberHeaderComponentController.revealSsn(acc.Id);
        Test.stopTest();

        System.assertEquals(null, ssn, 'SSN should be null when no census member');
    }

    @isTest
    static void revealSsn_nullAccountId_throwsException() {
        Test.startTest();
        try {
            ARC_memberHeaderComponentController.revealSsn(null);
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(true, 'Caught expected exception');
        }
        Test.stopTest();
    }
}