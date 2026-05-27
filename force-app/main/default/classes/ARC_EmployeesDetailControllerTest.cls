@IsTest
private class ARC_EmployeesDetailControllerTest {

    @TestSetup
    static void setupData() {
        // Create group/business account
        Account groupAccount = new Account(
            Name = 'Test Group Account'
        );
        insert groupAccount;

        // Create primary member account
        Account primaryMember = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().containsKey('PersonAccount')
                ? Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_SGPersonAccount').getRecordTypeId()
                : null,
            FirstName = 'John',
            LastName = 'Primary',
            PersonEmail = 'john.primary@test.com',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            ARC_IsPrimaryMember__c = true,
            Current_Member_Id__c = 'MID-PRIMARY-001',
            ARC_GroupAccount__c = groupAccount.Id,
            ARC_EmployeeType__c = 'Full Time',
            ARC_EmployeeDivision__c = 'Exempt',
            ARC_JobTitle__c = 'Manager',
            ARC_ContinuousMembershipStartDate__c = Date.today().addYears(-1),
            BillingStreet = '123 Main St',
            BillingCity = 'Dallas',
            BillingState = 'TX',
            BillingPostalCode = '75001',
            BillingCountry = 'USA',
            Phone = '5551234567'
        );
        insert primaryMember;

        // Create dependent member account
        Account dependentMember = new Account(
            RecordTypeId = primaryMember.RecordTypeId,
            FirstName = 'Jane',
            LastName = 'Dependent',
            PersonEmail = 'jane.dependent@test.com',
            PersonBirthdate = Date.newInstance(2015, 5, 10),
            ARC_IsPrimaryMember__c = false,
            Current_Member_Id__c = 'MID-DEPENDENT-001',
            ARC_PrimaryMemberAccount__c = primaryMember.Id,
            ARC_DependentRelationship__c = 'Child',
            ARC_GroupAccount__c = groupAccount.Id,
            ARC_ContinuousMembershipStartDate__c = Date.today().addMonths(-6),
            BillingStreet = '123 Main St',
            BillingCity = 'Dallas',
            BillingState = 'TX',
            BillingPostalCode = '75001',
            BillingCountry = 'USA'
        );
        insert dependentMember;

        // Reload Person Account contact ids for participant records.
        primaryMember = [
            SELECT Id, PersonContactId, RecordTypeId
            FROM Account
            WHERE Id = :primaryMember.Id
            LIMIT 1
        ];
        dependentMember = [
            SELECT Id, PersonContactId, RecordTypeId
            FROM Account
            WHERE Id = :dependentMember.Id
            LIMIT 1
        ];

        // Create Insurance Policy
        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Test Policy',
            NameInsuredId = primaryMember.Id,
            Status = 'Activated',
            //ARC_EffectiveDate__c = Date.today().addMonths(-1),
            //ARC_ExpirationDate__c = Date.today().addYears(1),
            //ARC_TotalPremiumAmount__c = 1000,
            ARC_EmployeeMonthlyContribution__c = 300,
            ARC_EmployerMonthlyContribution__c = 700
        );
        insert policy;

        // Create Insurance Policy Participants
        InsurancePolicyParticipant primaryParticipant = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            PrimaryParticipantContactId = primaryMember.PersonContactId,
            Role = 'Primary'
        );
        insert primaryParticipant;

        InsurancePolicyParticipant dependentParticipant = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            PrimaryParticipantContactId = dependentMember.PersonContactId,
            Role = 'Dependent'
        );
        insert dependentParticipant;

        // Try to create product and coverage only if Product2 is available in org context
        Product2 product = new Product2(
            Name = 'Medical Plan'
        );
        insert product;

        InsurancePolicyCoverage coverage = new InsurancePolicyCoverage(
            InsurancePolicyId = policy.Id,
            vlocity_ins_fsc__Product2Id__c = product.Id
        );
        insert coverage;

        // Coverage participant records
        ARC_CoverageParticipant__c cp1 = new ARC_CoverageParticipant__c(
            ARC_PolicyParticipant__c = primaryParticipant.Id,
            ARC_PolicyCoverage__c = coverage.Id
        );
        ARC_CoverageParticipant__c cp2 = new ARC_CoverageParticipant__c(
            ARC_PolicyParticipant__c = dependentParticipant.Id,
            ARC_PolicyCoverage__c = coverage.Id
        );
        insert new List<ARC_CoverageParticipant__c>{ cp1, cp2 };
    }

    private static Account getPrimaryMember() {
        return [
            SELECT Id
            FROM Account
            WHERE FirstName = 'John'
            AND LastName = 'Primary'
            LIMIT 1
        ];
    }

    @IsTest
    static void test_getParticipantsFromAccount_noPrimaryParticipant() {
        Account acc = new Account(Name = 'No Participant Account');
        insert acc;

        Test.startTest();
        List<Map<String, Object>> result =
            ARC_EmployeesDetailController.getParticipantsFromAccount(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(0, result.size(), 'Result should be empty when no primary participant exists.');
    }

    @IsTest
    static void test_getParticipantsFromAccount_success() {
        Account primaryMember = getPrimaryMember();

        Test.startTest();
        List<Map<String, Object>> result =
            ARC_EmployeesDetailController.getParticipantsFromAccount(primaryMember.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assert(result.size() > 0, 'At least one participant should be returned.');
    }

    @IsTest
    static void test_getCurrentPolicy_noPolicy() {
        Account acc = new Account(Name = 'No Policy Account');
        insert acc;

        Test.startTest();
        Map<String, Object> result =
            ARC_EmployeesDetailController.getCurrentPolicy(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(0, result.size(), 'Result should be empty when no policy exists.');
    }

    @IsTest
    static void test_getCurrentPolicy_success() {
        Account primaryMember = getPrimaryMember();

        Test.startTest();
        Map<String, Object> result =
            ARC_EmployeesDetailController.getCurrentPolicy(primaryMember.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assert(result.containsKey('InsurancePolicyId'), 'InsurancePolicyId should be returned.');
        System.assertEquals('Activated', (String) result.get('Status'), 'Activated policy should be selected.');
    }

    @IsTest
    static void test_getDownloadableData_success() {
        Account primaryMember = getPrimaryMember();

        Test.startTest();
        List<Map<String, Object>> result =
            ARC_EmployeesDetailController.getDownloadableData(primaryMember.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assert(result.size() > 0, 'At least one downloadable row should be returned.');
    }

    @IsTest
    static void test_orderFamilyMembers_direct() {
        List<Map<String, Object>> inputFamily = new List<Map<String, Object>>{
            new Map<String, Object>{ 'Relationship' => 'Child', 'IsPrimary' => false, 'Name' => 'Child 1' },
            new Map<String, Object>{ 'Relationship' => 'Spouse', 'IsPrimary' => false, 'Name' => 'Spouse 1' },
            new Map<String, Object>{ 'Relationship' => 'Primary', 'IsPrimary' => true, 'Name' => 'Primary 1' },
            new Map<String, Object>{ 'Relationship' => 'Other', 'IsPrimary' => false, 'Name' => 'Other 1' }
        };

        Test.startTest();
        List<Map<String, Object>> ordered =
            ARC_EmployeesDetailController.orderFamilyMembers(inputFamily);
        Test.stopTest();

        System.assertEquals(4, ordered.size(), 'All family members should be preserved.');
        System.assertEquals('Primary', (String) ordered[0].get('Relationship'), 'Primary should be first.');
        System.assertEquals('Spouse', (String) ordered[1].get('Relationship'), 'Spouse should be second.');
        System.assertEquals('Child', (String) ordered[2].get('Relationship'), 'Child should be third.');
    }

    @IsTest
    static void test_isAdminOnly_false() {
        Test.startTest();
        Boolean result = ARC_EmployeesDetailController.isAdminOnly();
        Test.stopTest();

        System.assertEquals(false, result, 'Without the permission set assignment, result should be false.');
    }

    @IsTest
    static void test_getProgramsWithMembers_noAccount_returnsEmptyList() {
        Test.startTest();
        List<Map<String, Object>> result =
            ARC_EmployeesDetailController.getProgramsWithMembers(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should never be null.');
        System.assertEquals(0, result.size(), 'Null accountId should return no program rows.');
    }

    @IsTest
    static void test_getProgramsWithMembers_success() {
        Account primaryMember = getPrimaryMember();

        Test.startTest();
        List<Map<String, Object>> result =
            ARC_EmployeesDetailController.getProgramsWithMembers(primaryMember.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should never be null.');
        System.assert(result.size() > 0, 'At least one program row should be returned for the seeded active policy.');
    }

    @IsTest
    static void test_getActiveQLEs_noCases_returnsEmptyList() {
        Account primaryMember = getPrimaryMember();

        Test.startTest();
        List<Map<String, Object>> result =
            ARC_EmployeesDetailController.getActiveQLEs(primaryMember.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(0, result.size());
    }
}