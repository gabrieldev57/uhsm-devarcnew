@IsTest
public class InsurancePolicyHelperTest {

    @testSetup
    static void setupData() {

        // Create Account (NameInsured)
        Account insured = new Account(
            Name = 'Test Insured'
        );
        insert insured;

        // Create Contract (ARC_Contract__c)
        Contract contract = new Contract(
            Name = 'Test Contract',
            AccountId = insured.Id
        );
        insert contract;

        // Create InsurancePolicy
        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Test Policy',
            Status = 'Active',
            ARC_Contract__c = contract.Id,
            NameInsuredId  = insured.Id
        );
        insert policy;
    }

    @IsTest
    static void testGetPoliciesByContractIds_validData() {

        Contract contract = [
            SELECT Contract_Id_18__c
            FROM Contract
            LIMIT 1
        ];

        Test.startTest();
        List<InsurancePolicy> result =
            InsurancePolicyHelper.getPoliciesByContractIds(
                new List<Id>{ contract.Contract_Id_18__c }
            );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one policy');

        System.assertEquals(
            contract.Contract_Id_18__c,
            result[0].ARC_Contract__r.Contract_Id_18__c,
            'Contract Id should match'
        );
    }

    @IsTest
    static void testGetPoliciesByContractIds_emptyInput() {

        Test.startTest();
        List<InsurancePolicy> result =
            InsurancePolicyHelper.getPoliciesByContractIds(new List<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list');
    }

    @IsTest
    static void testGetPoliciesByContractIds_nullInput() {

        Test.startTest();
        List<InsurancePolicy> result =
            InsurancePolicyHelper.getPoliciesByContractIds(null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list for null input');
    }
}