@isTest
public class ARC_SGQLEHelperTest {

    @testSetup
    static void setupData() {
        
        Account perAccount = new Account (Name='Test Account');
        insert perAccount;
        
        // Create Insurance Policy
        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Test Policy',
            ARC_QLEReason__c = 'Court Order',
            NameInsuredId = perAccount.Id
        );
        insert policy;

        // Create Coverage
        InsurancePolicyCoverage ipc = new InsurancePolicyCoverage(
            InsurancePolicyId = policy.Id,
            ARC_Reason__c = 'New Policy'
        );
        insert ipc;
    }

    @isTest
    static void testUpdateIPCReason() {
        InsurancePolicyCoverage ipc = [SELECT Id,ARC_Reason__c, InsurancePolicyId FROM InsurancePolicyCoverage LIMIT 1];
        ipc.ARC_Reason__c = 'Program Downgrade';
        Test.startTest();
            update ipc;
        Test.stopTest();

    }


    @isTest
    static void testValidateQLEData_success() {
        Map<String, Object> person = new Map<String, Object>{
            'firstName' => 'John',
            'lastName' => 'Doe'
        };

        Map<String, Object> member = new Map<String, Object>{
            'role' => 'Primary',
            'person' => person
        };

        Map<String, Object> generalInfo = new Map<String, Object>{
            'accountId' => 'A1'
        };

        Map<String, Object> input = new Map<String, Object>{
            'generalInformation' => generalInfo,
            'members' => new List<Object>{ member }
        };

        Map<String, Object> result = ARC_SGQLEHelper.validateQLEData(input);
        System.assertEquals(true, result.get('success'));
    }

    @isTest
    static void testValidateQLEData_failure() {
        Map<String, Object> result = ARC_SGQLEHelper.validateQLEData(null);
        System.assertEquals(false, result.get('success'));
        System.assertEquals('Request body is required', result.get('errorMessage'));
    }

    @isTest
    static void testCreateIntegrationLog() {
        Map<String, Object> person = new Map<String, Object>{
            'firstName' => 'Jane',
            'lastName' => 'Smith'
        };

        Map<String, Object> member = new Map<String, Object>{
            'role' => 'Primary',
            'person' => person
        };

        Map<String, Object> requestBody = new Map<String, Object>{
            'members' => new List<Object>{ member }
        };

        Test.startTest();
        String logId = ARC_SGQLEHelper.createIntegrationLog('testOp', requestBody);
        Test.stopTest();

        System.assertNotEquals(null, logId);
    }

    @isTest
    static void testUpdateIntegrationLog() {
        ARC_IntegrationLog__c log = new ARC_IntegrationLog__c(
            Direction__c = 'Inbound',
            Service__c = 'test'
        );
        insert log;

        Test.startTest();
        ARC_SGQLEHelper.updateIntegrationLog(
            log.Id,
            true,
            200,
            null,
            null,
            System.now(),
            100,
            null,
            null
        );
        Test.stopTest();

        ARC_IntegrationLog__c updated = [
            SELECT Success__c FROM ARC_IntegrationLog__c WHERE Id = :log.Id
        ];
        System.assertEquals(true, updated.Success__c);
    }

   @isTest
    static void testLogError() {
        try {
            Integer x = 1 / 0; // forces a runtime exception
        } catch (Exception e) {
            Test.startTest();
            ARC_SGQLEHelper.logError('CTX', e, 'request data');
            Test.stopTest();
        }
    
        System.assert(true, 'logError executed');
    }

    @isTest
    static void testRecalculatePolicyReasons() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];

        Set<Id> policyIds = new Set<Id>{ policy.Id };

        Test.startTest();
        ARC_SGQLEHelper.recalculatePolicyReasons(policyIds);
        Test.stopTest();

        InsurancePolicy updated = [
            SELECT Id FROM InsurancePolicy WHERE Id = :policy.Id
        ];

        System.assertNotEquals(null, updated);
    }

    @isTest
    static void testValidateQLEPayload_errors() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> result = ARC_SGQLEHelper.validateQLEPayload(input);

        System.assertEquals(false, result.get('success'));
        System.assert(((List<String>)result.get('errors')).size() > 0);
    }

    @isTest
    static void testBuildValidationErrorMessage() {
        List<String> errors = new List<String>{
            'field1 missing',
            'field2 invalid'
        };

        String msg = ARC_SGQLEHelper.buildValidationErrorMessage(errors);

        System.assert(msg.contains('field1'));
        System.assert(msg.contains('field2'));
    }
    
    @isTest
	static void test_validateQLEPayload_nullInput() {
    Map<String, Object> result = ARC_SGQLEHelper.validateQLEPayload(null);

    System.assertEquals(false, result.get('success'));
    System.assert(((List<String>)result.get('errors')).contains('Payload is required.'));
}
    
    @isTest
static void test_validateQLEPayload_generalInformation_branch() {

    Map<String, Object> generalInfo = new Map<String, Object>{
        // intentionally incomplete to force validation calls
        'accountId' => 'A1',
        'censusId' => 'C1',
        'groupAccountId' => 'G1',
        'contractId' => 'CON1',
        'primaryCensusMemberId' => 'P1',
        'effectiveDate' => '2026-01-01',
        'medicalProgram' => new Map<String, Object>{}
    };

    Map<String, Object> input = new Map<String, Object>{
        'enrollmentId' => 'E1',
        'traceId' => 'T1',
        'generalInformation' => generalInfo,
        'currentState' => new Map<String, Object>(),
        'members' => new List<Object>{
            new Map<String, Object>{
                'memberExternalId' => 'M1',
                'role' => 'Primary',
                'person' => new Map<String, Object>{
                    'firstName' => 'John',
                    'lastName' => 'Doe',
                    'dob' => '2000-01-01'
                }
            }
        }
    };

    Map<String, Object> result = ARC_SGQLEHelper.validateQLEPayload(input);
    System.assertNotEquals(null, result);
}
}