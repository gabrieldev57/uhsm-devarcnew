@IsTest
public with sharing class ARC_SGSelfEnrollmentHelperTest {

    // Creates reusable base data for log-related tests.
    @testSetup
    static void setupData() {
        Account groupAccount = new Account(Name = 'SG Self Enrollment Group Account');
        insert groupAccount;
    }

    // Returns a valid base enrollment payload.
    private static Map<String, Object> buildValidEnrollmentPayload() {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('enrollmentId', 'ENR-1001');
        payload.put('traceId', 'TRACE-1001');
        payload.put('generalInformation', buildValidGeneralInformation());
        payload.put('members', new List<Object>{ buildValidMember() });
        return payload;
    }

    // Returns a valid generalInformation section.
    private static Map<String, Object> buildValidGeneralInformation() {
        Map<String, Object> generalInformation = new Map<String, Object>();
        generalInformation.put('accountId', '001000000000001AAA');
        generalInformation.put('censusId', 'a1B000000000001EAA');
        generalInformation.put('groupAccountId', '001000000000002AAA');
        generalInformation.put('contractId', '800000000000001AAA');
        generalInformation.put('primaryCensusMemberId', 'a3q000000000001AAA');
        generalInformation.put('effectiveDate', '2026-01-01');
        generalInformation.put('totalMonthlyPremium', 250.50);
        generalInformation.put('signerEmail', 'primary@example.com');
        generalInformation.put('guardian', new Map<String, Object>{
            'firstName' => 'Maria',
            'lastName' => 'Lopez',
            'dob' => '1985-05-20',
            'relationship' => 'Spouse',
            'phone' => '5551112222',
            'email' => 'guardian@example.com',
            'address' => new Map<String, Object>{
                'street' => '100 Main St',
                'city' => 'Dallas',
                'state' => 'TX',
                'zip' => '75001'
            }
        });
        generalInformation.put('hipaa', new List<Object>{ buildValidHipaaEntry('Primary') });
        generalInformation.put('medicalProgram', buildValidMedicalProgram());
        return generalInformation;
    }

    // Returns a valid member entry.
    private static Map<String, Object> buildValidMember() {
        Map<String, Object> member = new Map<String, Object>();
        member.put('role', 'Primary');
        member.put('memberExternalId', 'MEM-1001');
        member.put('sameAddressAsPrimary', true);
        member.put('person', new Map<String, Object>{
            'isLegacy' => false,
            'firstName' => 'John',
            'lastName' => 'Doe',
            'dob' => '1990-01-01',
            'gender' => 'Male',
            'ssn' => '123456789',
            'heightFeet' => 5,
            'heightInches' => 10,
            'weightLbs' => 180,
            'email' => 'john.doe@example.com',
            'phone' => '5553334444',
            'smoker' => false,
            'pregnant' => false
        });
        member.put('currentCoverage', new List<Object>{
            new Map<String, Object>{
                'productCode' => 'MEDICAL',
                'memberPremium' => 100.25,
                'planName' => 'Base Medical'
            }
        });
        return member;
    }

    // Returns a valid hipaa entry for the provided relationship.
    private static Map<String, Object> buildValidHipaaEntry(String relationship) {
        Map<String, Object> hipaaEntry = new Map<String, Object>();
        hipaaEntry.put('relationship', relationship);

        if (relationship == 'Third Party') {
            hipaaEntry.put('memberId', 'MEM-2001');
            hipaaEntry.put('DAT_DOB', '1988-02-02');
            hipaaEntry.put('firstName', 'Ana');
            hipaaEntry.put('lastName', 'Third');
            hipaaEntry.put('address', new Map<String, Object>{
                'street' => '300 Third St',
                'city' => 'Dallas',
                'state' => 'TX',
                'zip' => '75003'
            });
        } else if (relationship == 'Parent') {
            hipaaEntry.put('memberId', 'MEM-3001');
            hipaaEntry.put('dob', '1965-03-03');
            hipaaEntry.put('ssn', '987654321');
            hipaaEntry.put('firstName', 'Laura');
            hipaaEntry.put('lastName', 'Parent');
        } else {
            hipaaEntry.put('memberExternalId', 'MEM-1001');
            hipaaEntry.put('dob', '1990-01-01');
            hipaaEntry.put('firstName', 'John');
            hipaaEntry.put('lastName', 'Doe');
        }

        return hipaaEntry;
    }

    // Returns a valid medicalProgram section.
    private static Map<String, Object> buildValidMedicalProgram() {
        Map<String, Object> medicalProgram = new Map<String, Object>();
        medicalProgram.put('medical', new Map<String, Object>{
            'productId' => 'PROD-1001',
            'productCode' => 'MEDICAL',
            'planName' => 'Base Medical',
            'basePrice' => 200.00,
            'priceWithContributions' => 150.00,
            'employeeContribution' => 50.00,
            'employerContribution' => 150.00,
            'coverageTier' => 'Employee Only'
        });
        return medicalProgram;
    }
    // Verifies validation fails when enrollmentId is missing.
    @IsTest
    static void testValidateEnrollmentData_missingEnrollmentId() {
        Map<String, Object> payload = buildValidEnrollmentPayload();
        payload.remove('enrollmentId');

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> response = ARC_SGSelfEnrollmentHelper.validateEnrollmentData(payload, outputMap);
        Test.stopTest();

        System.assertEquals(false, response.get('success'));
        System.assertEquals('Error enrollmentId is required', (String) response.get('errorMessage'));
        System.assertEquals(false, outputMap.get('success'));
        System.assertEquals('Error enrollmentId is required', (String) outputMap.get('errorMessage'));
    }

    // Verifies validation fails when traceId is missing.
    @IsTest
    static void testValidateEnrollmentData_missingTraceId() {
        Map<String, Object> payload = buildValidEnrollmentPayload();
        payload.remove('traceId');

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> response = ARC_SGSelfEnrollmentHelper.validateEnrollmentData(payload, outputMap);
        Test.stopTest();

        System.assertEquals(false, response.get('success'));
        System.assertEquals('Error traceId is required', (String) response.get('errorMessage'));
        System.assertEquals(false, outputMap.get('success'));
        System.assertEquals('Error traceId is required', (String) outputMap.get('errorMessage'));
    }

    // Verifies convertToBoolean handles the main supported cases.
    @IsTest
    static void testConvertToBoolean_allMainCases() {
        System.assertEquals(null, ARC_SGSelfEnrollmentHelper.convertToBoolean(null));
        System.assertEquals(true, ARC_SGSelfEnrollmentHelper.convertToBoolean(true));
        System.assertEquals(false, ARC_SGSelfEnrollmentHelper.convertToBoolean(false));
        System.assertEquals(true, ARC_SGSelfEnrollmentHelper.convertToBoolean('true'));
        System.assertEquals(true, ARC_SGSelfEnrollmentHelper.convertToBoolean('TRUE'));
        System.assertEquals(true, ARC_SGSelfEnrollmentHelper.convertToBoolean('1'));
        System.assertEquals(false, ARC_SGSelfEnrollmentHelper.convertToBoolean('false'));
        System.assertEquals(false, ARC_SGSelfEnrollmentHelper.convertToBoolean('0'));
        System.assertEquals(null, ARC_SGSelfEnrollmentHelper.convertToBoolean(123));
    }

    // Verifies createIntegrationLog inserts a log record with the expected base values.
    @IsTest
    static void testCreateIntegrationLog_happyPath() {
        Map<String, Object> payload = buildValidEnrollmentPayload();

        Test.startTest();
        String logId = ARC_SGSelfEnrollmentHelper.createIntegrationLog('Save Enrollment', payload);
        Test.stopTest();

        System.assertNotEquals(null, logId, 'Integration log Id should not be null');

        ARC_IntegrationLog__c logRecord = [
            SELECT Id,
                   Direction__c,
                   DurationMs__c,
                   Endpoint__c,
                   ErrorCode__c,
                   ErrorMessage__c,
                   FinishedAt__c,
                   HttpStatus__c,
                   Operation__c,
                   RawJSON_Part1__c,
                   RawJSON_Part2__c,
                   RetryCount__c,
                   Service__c,
                   StartedAt__c,
                   Success__c,
                   ARC_PrimaryName__c
            FROM ARC_IntegrationLog__c
            WHERE Id = :logId
            LIMIT 1
        ];

        System.assertEquals('Inbound', logRecord.Direction__c);
        System.assertEquals(0, Integer.valueOf(logRecord.DurationMs__c));
        System.assertEquals('/api/v1/small-group-enrollment/Save Enrollment', logRecord.Endpoint__c);
        System.assertEquals(null, logRecord.ErrorCode__c);
        System.assertEquals(null, logRecord.ErrorMessage__c);
        System.assertEquals(null, logRecord.FinishedAt__c);
        System.assertEquals(200, Integer.valueOf(logRecord.HttpStatus__c));
        System.assertEquals('POST', logRecord.Operation__c);
        System.assertNotEquals(null, logRecord.RawJSON_Part1__c, 'Raw JSON part 1 should be stored');
        System.assertEquals(0, Integer.valueOf(logRecord.RetryCount__c));
        System.assertEquals('processSGSelfEnrollment', logRecord.Service__c);
        System.assertNotEquals(null, logRecord.StartedAt__c, 'StartedAt should be populated');
        System.assertEquals(true, logRecord.Success__c);
        System.assertEquals('John Doe', logRecord.ARC_PrimaryName__c);
    }

    // Verifies updateIntegrationLog updates the log with the provided outcome data.
    @IsTest
    static void testUpdateIntegrationLog_happyPath() {
        Map<String, Object> payload = buildValidEnrollmentPayload();
        String logId = ARC_SGSelfEnrollmentHelper.createIntegrationLog('Save Enrollment', payload);
        DateTime finishedAt = System.now();

        Id groupAccountId = [SELECT Id FROM Account WHERE Name = 'SG Self Enrollment Group Account' LIMIT 1].Id;

        Test.startTest();
        ARC_SGSelfEnrollmentHelper.updateIntegrationLog(
            logId,
            true,
            200,
            null,
            null,
            finishedAt,
            150,
            groupAccountId,
            'SG Self Enrollment Group Account'
        );
        Test.stopTest();

        ARC_IntegrationLog__c logRecord = [
            SELECT Id,
                   Success__c,
                   HttpStatus__c,
                   ErrorCode__c,
                   ErrorMessage__c,
                   FinishedAt__c,
                   DurationMs__c,
                   ARC_GroupAccount__c,
                   ARC_GroupAccountName__c
            FROM ARC_IntegrationLog__c
            WHERE Id = :logId
            LIMIT 1
        ];

        System.assertEquals(true, logRecord.Success__c);
        System.assertEquals(200, Integer.valueOf(logRecord.HttpStatus__c));
        System.assertEquals(null, logRecord.ErrorCode__c);
        System.assertEquals(null, logRecord.ErrorMessage__c);
        System.assertEquals(finishedAt, logRecord.FinishedAt__c);
        System.assertEquals(150, Integer.valueOf(logRecord.DurationMs__c));
        System.assertEquals(groupAccountId, logRecord.ARC_GroupAccount__c);
        System.assertEquals('SG Self Enrollment Group Account', logRecord.ARC_GroupAccountName__c);
    }
    // Verifies validation fails when generalInformation is missing.
    @IsTest
    static void testValidateEnrollmentData_missingGeneralInformation() {
        Map<String, Object> payload = buildValidEnrollmentPayload();
        payload.remove('generalInformation');

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> response = ARC_SGSelfEnrollmentHelper.validateEnrollmentData(payload, outputMap);
        Test.stopTest();

        System.assertEquals(false, response.get('success'));
        System.assert(((String) response.get('errorMessage')).contains('Error generalInformation is required'));
        System.assertEquals(false, outputMap.get('success'));
        System.assert(((String) outputMap.get('errorMessage')).contains('Error generalInformation is required'));
    }

    // Verifies validation reports missing required fields inside generalInformation.
    @IsTest
    static void testValidateEnrollmentData_generalInformation_missingRequiredFields() {
        Map<String, Object> payload = buildValidEnrollmentPayload();
        payload.put('generalInformation', new Map<String, Object>());

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> response = ARC_SGSelfEnrollmentHelper.validateEnrollmentData(payload, outputMap);
        Test.stopTest();

        String errorMessage = (String) response.get('errorMessage');
        System.assertEquals(false, response.get('success'));
        System.assert(errorMessage.contains('accountId'));
        System.assert(errorMessage.contains('censusId'));
        System.assert(errorMessage.contains('groupAccountId'));
        System.assert(errorMessage.contains('contractId'));
        System.assert(errorMessage.contains('primaryCensusMemberId'));
        System.assert(errorMessage.contains('effectiveDate'));
        System.assert(errorMessage.contains('totalMonthlyPremium'));
        System.assert(errorMessage.contains('signerEmail'));
    }

    // Verifies validation fails when members is missing.
    @IsTest
    static void testValidateEnrollmentData_membersMissing() {
        Map<String, Object> payload = buildValidEnrollmentPayload();
        payload.remove('members');

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> response = ARC_SGSelfEnrollmentHelper.validateEnrollmentData(payload, outputMap);
        Test.stopTest();

        System.assertEquals(false, response.get('success'));
        System.assert(((String) response.get('errorMessage')).contains('Error members is required'));
        System.assertEquals(false, outputMap.get('success'));
    }

    // Verifies validation fails when members is an empty list.
    @IsTest
    static void testValidateEnrollmentData_membersEmpty() {
        Map<String, Object> payload = buildValidEnrollmentPayload();
        payload.put('members', new List<Object>());

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> response = ARC_SGSelfEnrollmentHelper.validateEnrollmentData(payload, outputMap);
        Test.stopTest();

        String errorMessage = (String) response.get('errorMessage');
        System.assertEquals(false, response.get('success'));
        System.assertNotEquals(null, errorMessage, 'Error message should not be null');
        System.assert(
            errorMessage.contains('members') || errorMessage.contains('member'),
            'Error message should reference members: ' + errorMessage
        );
        System.assertEquals(false, outputMap.get('success'));
    }

    // Verifies validation reports missing required fields inside member.person.
    @IsTest
    static void testValidateEnrollmentData_memberPersonMissingFields() {
        Map<String, Object> payload = buildValidEnrollmentPayload();
        List<Object> members = (List<Object>) payload.get('members');
        Map<String, Object> member = (Map<String, Object>) members[0];
        member.put('person', new Map<String, Object>());

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> response = ARC_SGSelfEnrollmentHelper.validateEnrollmentData(payload, outputMap);
        Test.stopTest();

        String errorMessage = (String) response.get('errorMessage');
        System.assertEquals(false, response.get('success'));
        System.assert(errorMessage.contains('isLegacy'));
        System.assert(errorMessage.contains('firstName'));
        System.assert(errorMessage.contains('lastName'));
        System.assert(errorMessage.contains('dob'));
        System.assert(errorMessage.contains('gender'));
        System.assert(errorMessage.contains('ssn'));
        System.assert(errorMessage.contains('heightFeet'));
        System.assert(errorMessage.contains('heightInches'));
        System.assert(errorMessage.contains('weightLbs'));
        System.assert(errorMessage.contains('email'));
        System.assert(errorMessage.contains('phone'));
        System.assert(errorMessage.contains('smoker'));
        System.assert(errorMessage.contains('pregnant'));
    }

    // Verifies validation reports missing required fields inside medicalProgram.medical.
    @IsTest
    static void testValidateEnrollmentData_medicalProgramMissingFields() {
        Map<String, Object> payload = buildValidEnrollmentPayload();
        Map<String, Object> generalInformation = (Map<String, Object>) payload.get('generalInformation');
        generalInformation.put('medicalProgram', new Map<String, Object>{
            'medical' => new Map<String, Object>()
        });

        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> response = ARC_SGSelfEnrollmentHelper.validateEnrollmentData(payload, outputMap);
        Test.stopTest();

        String errorMessage = (String) response.get('errorMessage');
        System.assertEquals(false, response.get('success'));
        System.assert(errorMessage.contains('productId'));
        System.assert(errorMessage.contains('basePrice'));
        System.assert(errorMessage.contains('priceWithContributions'));
    }
}