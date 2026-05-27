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
            // ARC_StartDate__c = Date.today().addDays(-10),
            // ARC_EndDate__c = Date.today().addDays(365),
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
        InsurancePolicyParticipant ipp = [SELECT ARC_StartDate__c, ARC_EndDate__c FROM InsurancePolicyParticipant LIMIT 1];
        Date policyEffDate = Date.newInstance(policy.ARC_EffectiveDate__c.year(), policy.ARC_EffectiveDate__c.month(), policy.ARC_EffectiveDate__c.day());
        Date ippEffDate = Date.newInstance(ipp.ARC_StartDate__c.year(), ipp.ARC_StartDate__c.month(), ipp.ARC_StartDate__c.day());
        Date policyExpDate = Date.newInstance(policy.ARC_ExpirationDate__c.year(), policy.ARC_ExpirationDate__c.month(), policy.ARC_ExpirationDate__c.day());
        Date ippExpDate = Date.newInstance(ipp.ARC_EndDate__c.year(), ipp.ARC_EndDate__c.month(), ipp.ARC_EndDate__c.day());
        System.assertEquals(policyEffDate, ippEffDate, 'ARC_StartDate__c should match policy');
        System.assertEquals(policyExpDate, ippExpDate, 'ARC_EndDate__c should match policy');
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
        InsurancePolicyParticipant ipp = [SELECT ARC_StartDate__c, ARC_EndDate__c FROM InsurancePolicyParticipant LIMIT 1];
        Date policyEffDate = Date.newInstance(policy2.ARC_EffectiveDate__c.year(), policy2.ARC_EffectiveDate__c.month(), policy2.ARC_EffectiveDate__c.day());
        Date ippEffDate = Date.newInstance(ipp.ARC_StartDate__c.year(), ipp.ARC_StartDate__c.month(), ipp.ARC_StartDate__c.day());
        Date policyExpDate = Date.newInstance(policy2.ARC_ExpirationDate__c.year(), policy2.ARC_ExpirationDate__c.month(), policy2.ARC_ExpirationDate__c.day());
        Date ippExpDate = Date.newInstance(ipp.ARC_EndDate__c.year(), ipp.ARC_EndDate__c.month(), ipp.ARC_EndDate__c.day());
        System.assertEquals(policyEffDate, ippEffDate, 'ARC_StartDate__c should match policy');
        System.assertEquals(policyExpDate, ippExpDate, 'ARC_EndDate__c should match policy');
    }
}