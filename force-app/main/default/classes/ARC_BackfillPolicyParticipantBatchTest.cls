@isTest
public class ARC_BackfillPolicyParticipantBatchTest {

    @testSetup
    static void setupData() {
        // Create a contract in Awaiting Activation and activate it
        List<Contract> contracts = ARC_TestUtility.createContractsAA(1);
        insert contracts;
        Contract contract = contracts[0];
        contract.Status = 'Activated';
        contract.ARC_EffectiveDate__c = Date.today().addDays(-10);
        contract.ARC_Inactive_Date__c = Date.today().addDays(365);
        update contract;
        Account a = new Account(Name='TestAccount');
        insert a;

        // Create InsurancePolicy related to the contract
        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Test Policy',
            ARC_Contract__c = contract.Id,
            // EffectiveDate = Date.today().addDays(-10),
            // ExpirationDate = Date.today().addDays(365),
            NameInsuredId = a.Id
        );
        insert policy;

        // Create a Contact for the participant
        Contact c = new Contact(FirstName='Test', LastName='Contact', Birthdate=Date.today().addYears(-30));
        insert c;

        // Create InsurancePolicyParticipant related to the policy and contact
        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            PrimaryParticipantContactId = c.Id,
            Role = 'Dependent'
        );
        insert ipp;
    }

    @isTest
    static void testBatchWithoutIds() {
        Test.startTest();
        ARC_BackfillPolicyParticipantBatch batch = new ARC_BackfillPolicyParticipantBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Verify update
        InsurancePolicy policy = [SELECT ARC_EffectiveDate__c, ARC_ExpirationDate__c FROM InsurancePolicy LIMIT 1];
        InsurancePolicyParticipant ipp = [SELECT EffectiveDate, ExpirationDate FROM InsurancePolicyParticipant LIMIT 1];
        System.assertEquals(policy.ARC_EffectiveDate__c, ipp.EffectiveDate, 'EffectiveDate should match policy');
        System.assertEquals(policy.ARC_ExpirationDate__c, ipp.ExpirationDate, 'ExpirationDate should match policy');
    }

    @isTest
    static void testBatchWithIds() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        Test.startTest();
        ARC_BackfillPolicyParticipantBatch batch = new ARC_BackfillPolicyParticipantBatch(new List<String>{policy.Id});
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Verify update
        InsurancePolicy policy2 = [SELECT ARC_EffectiveDate__c, ARC_ExpirationDate__c FROM InsurancePolicy LIMIT 1];
        InsurancePolicyParticipant ipp = [SELECT EffectiveDate, ExpirationDate FROM InsurancePolicyParticipant LIMIT 1];
        System.assertEquals(policy2.ARC_EffectiveDate__c, ipp.EffectiveDate, 'EffectiveDate should match policy');
        System.assertEquals(policy2.ARC_ExpirationDate__c, ipp.ExpirationDate, 'ExpirationDate should match policy');
    }
}