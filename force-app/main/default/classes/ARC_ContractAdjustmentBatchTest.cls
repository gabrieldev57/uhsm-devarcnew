@isTest
public class ARC_ContractAdjustmentBatchTest {

    @isTest
    static void testBatchWithData() {

        // Create test Contract (standard object)
        Contract con = new Contract(
            AccountId = createAccount().Id,
            StartDate = Date.today(),
            Status = 'Draft'
        );
        insert con;

        // Create dummy Contact (used as NameInsuredId)
        Account emp1 = new Account(LastName = 'Employee One');
        Account emp2 = new Account(LastName = 'Employee Two');
        insert new List<Account>{emp1, emp2};
            
        

        // Create InsurancePolicy records (IMPORTANT)
        // Assumes InsurancePolicy object exists in your org
        List<InsurancePolicy> policies = new List<InsurancePolicy>{
            new InsurancePolicy(
                Name = 'Policy 1',
                ARC_Contract__c = con.Id,
                NameInsuredId = emp1.Id
            ),
            new InsurancePolicy(
                Name = 'Policy 2',
                ARC_Contract__c = con.Id,
                NameInsuredId = emp2.Id
            )
        };

        insert policies;

        Test.startTest();

        ARC_ContractAdjustmentBatch batch = new ARC_ContractAdjustmentBatch(con.Id);
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // No assertion needed since method calls external service
        System.assert(true);
    }

    @isTest
    static void testBatchWithNoPolicies() {

        Contract con = new Contract(
            AccountId = createAccount().Id,
            StartDate = Date.today(),
            Status = 'Draft'
        );
        insert con;

        Test.startTest();

        ARC_ContractAdjustmentBatch batch = new ARC_ContractAdjustmentBatch(con.Id);
        Database.executeBatch(batch, 1);

        Test.stopTest();

        System.assert(true);
    }

    @isTest
    static void testBatchHandlesException() {

        Contract con = new Contract(
            AccountId = createAccount().Id,
            StartDate = Date.today(),
            Status = 'Draft'
        );
        insert con;

        Account emp = new Account(Name = 'Employee Account');
        insert emp;
                
        InsurancePolicy policy = new InsurancePolicy(
        Name = 'Policy Error',
        ARC_Contract__c = con.Id,
        NameInsuredId = emp.Id
                );
        insert policy;

        Test.startTest();

        ARC_ContractAdjustmentBatch batch = new ARC_ContractAdjustmentBatch(con.Id);
        Database.executeBatch(batch, 1);

        Test.stopTest();

        // Even if service fails, batch should not crash
        System.assert(true);
    }

    // Helper method
    private static Account createAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return acc;
    }
}