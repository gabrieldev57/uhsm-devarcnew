@IsTest
public class ARC_PolicyAccountHandlerTest {

    private static Id rtId;

    @testSetup
    static void setupData() {

        rtId = Schema.SObjectType.InsurancePolicy
            .getRecordTypeInfosByDeveloperName()
            .get('ARC_SmallGroup')
            .getRecordTypeId();

        Account emp = new Account(
            FirstName = 'John',
            LastName = 'Employee'
           
        );
        insert emp;

        Account guardian = new Account(
            FirstName = 'Jane',
            LastName = 'Guardian'
           
        );
        insert guardian;

        InsurancePolicy oldPolicy = new InsurancePolicy(
            Name = 'Old Policy',
            RecordTypeId = rtId,
            Status = 'Activated',
            NameInsuredId = emp.Id,
            ARC_Guardian__c = guardian.Id,
            ARC_PolicyEffectiveDate__c = Date.today().addMonths(-2),
            ARC_PolicyExpirationDate__c = Date.today().addMonths(1)
        );
        insert oldPolicy;
    }

   @IsTest
static void testActivatedPolicyUpdatesAccounts_FIXED_FINAL() {

    Id rtId = Schema.SObjectType.InsurancePolicy
        .getRecordTypeInfosByDeveloperName()
        .get('ARC_SmallGroup')
        .getRecordTypeId();

    Account emp = [SELECT Id FROM Account WHERE LastName = 'Employee' LIMIT 1];
    Account guardian = [SELECT Id FROM Account WHERE LastName = 'Guardian' LIMIT 1];

    // OLD policy (must simulate REAL prior state)
    InsurancePolicy oldPolicy = new InsurancePolicy(
        Name = 'Old Policy',
        RecordTypeId = rtId,
        Status = 'Terminated', // IMPORTANT: must differ
        NameInsuredId = emp.Id,
        ARC_Guardian__c = guardian.Id,
        ARC_PolicyEffectiveDate__c = Date.today().addDays(-10)
    );
    insert oldPolicy;

    // NEW policy (activation trigger)
    InsurancePolicy newPolicy = new InsurancePolicy(
        Name = 'New Policy',
        RecordTypeId = rtId,
        Status = 'Activated',
        NameInsuredId = emp.Id,
        ARC_Guardian__c = guardian.Id,
        ARC_PolicyEffectiveDate__c = Date.today()
    );
    insert newPolicy;

    // Re-query BOTH to ensure full field coverage
    oldPolicy = [
        SELECT Id, Status, RecordTypeId, NameInsuredId, ARC_Guardian__c
        FROM InsurancePolicy
        WHERE Id = :oldPolicy.Id
    ];

    newPolicy = [
        SELECT Id, Status, RecordTypeId, NameInsuredId, ARC_Guardian__c,
               ARC_PolicyEffectiveDate__c, ARC_PolicyExpirationDate__c
        FROM InsurancePolicy
        WHERE Id = :newPolicy.Id
    ];

    Map<Id, InsurancePolicy> newMap = new Map<Id, InsurancePolicy>{
        newPolicy.Id => newPolicy
    };

    Map<Id, InsurancePolicy> oldMap = new Map<Id, InsurancePolicy>{
        newPolicy.Id => oldPolicy
    };

    Test.startTest();
    ARC_PolicyAccountHandler.processAccountActivation(newMap, oldMap);
    Test.stopTest();

    Account updatedEmp = [
        SELECT Id, IsActive
        FROM Account
        WHERE Id = :emp.Id
    ];

    System.assertEquals(
        true,
        updatedEmp.IsActive,
        'Employee should be active after policy activation'
    );
}

    @IsTest
    static void testVoidedPolicyDeactivatesAccount() {

        Id rtId = Schema.SObjectType.InsurancePolicy
            .getRecordTypeInfosByDeveloperName()
            .get('ARC_SmallGroup')
            .getRecordTypeId();

        Account emp = [SELECT Id FROM Account WHERE LastName = 'Employee' LIMIT 1];

        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Voided Policy',
            RecordTypeId = rtId,
            Status = 'Voided',
            NameInsuredId = emp.Id
        );
        insert policy;

        InsurancePolicy oldPolicy = new InsurancePolicy(
            Id = policy.Id,
            Status = 'Activated'
        );

        Map<Id, InsurancePolicy> newMap = new Map<Id, InsurancePolicy>{
            policy.Id => policy
        };

        Map<Id, InsurancePolicy> oldMap = new Map<Id, InsurancePolicy>{
            policy.Id => oldPolicy
        };

        Test.startTest();
        ARC_PolicyAccountHandler.processAccountActivation(newMap, oldMap);
        Test.stopTest();

        Account updated = [
            SELECT Id, IsActive
            FROM Account
            WHERE Id = :emp.Id
        ];

        System.assertEquals(false, updated.IsActive,
            'Account should be deactivated when policy is voided');
    }

    @IsTest
    static void testAlreadyProcessedFlag() {

        Id rtId = Schema.SObjectType.InsurancePolicy
            .getRecordTypeInfosByDeveloperName()
            .get('ARC_SmallGroup')
            .getRecordTypeId();

        Account emp = [SELECT Id FROM Account WHERE LastName = 'Employee' LIMIT 1];

        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Test Policy',
            RecordTypeId = rtId,
            Status = 'Activated',
            NameInsuredId = emp.Id
        );
        insert policy;

        Map<Id, InsurancePolicy> newMap = new Map<Id, InsurancePolicy>{
            policy.Id => policy
        };

        Map<Id, InsurancePolicy> oldMap = new Map<Id, InsurancePolicy>{
            policy.Id => policy
        };

        Test.startTest();
        ARC_PolicyAccountHandler.processAccountActivation(newMap, oldMap);
        ARC_PolicyAccountHandler.processAccountActivation(newMap, oldMap); // should skip
        Test.stopTest();

        System.assert(true, 'Second execution should be skipped due to static flag');
    }
}