@isTest
private class ARC_SGSelectedPlansControllerTest {

    private static Account createAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return acc;
    }

    private static InsurancePolicy createPolicy(Id accountId, String status) {
        InsurancePolicy pol = new InsurancePolicy(
            Name = 'Test Policy ' + status,
            NameInsuredId = accountId,
            Status = status,
            PolicyName = 'Test Policy ' + status
        );
        insert pol;
        return pol;
    }

    private static Product2 createProduct(String name, String type) {
        Product2 prod = new Product2(
            Name = name,
            vlocity_ins__Type__c = type,
            IsActive = true
        );
        insert prod;
        return prod;
    }

    private static InsurancePolicyCoverage createCoverage(Id policyId, Id productId, Decimal unitPrice) {
        InsurancePolicyCoverage ipc = new InsurancePolicyCoverage(
            InsurancePolicyId = policyId,
            vlocity_ins_fsc__Product2Id__c = productId,
            ARC_UnitPrice__c = unitPrice,
            ARC_ParentProduct__c = null
        );
        insert ipc;
        return ipc;
    }

    private static InsurancePolicyParticipant createPolicyParticipant(Id policyId, String participantName) {
        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(
            InsurancePolicyId = policyId,
            vlocity_ins_fsc__ParticipantName__c = participantName
        );
        insert ipp;
        return ipp;
    }

    private static ARC_CoverageParticipant__c createParticipant(Id coverageId, Id policyParticipantId) {
        ARC_CoverageParticipant__c cp = new ARC_CoverageParticipant__c(
            ARC_PolicyCoverage__c = coverageId,
            ARC_PolicyParticipant__c = policyParticipantId
        );
        insert cp;
        return cp;
    }

    @isTest
    static void testGetSelectedPlans_NoPolicies() {
        Account acc = createAccount();

        Test.startTest();
        List<ARC_SGSelectedPlansController.PlanWrapper> results =
            ARC_SGSelectedPlansController.getSelectedPlans(acc.Id);
        Test.stopTest();

        System.assertEquals(0, results.size());
    }

    @isTest
    static void testGetSelectedPlans_VoidedStatus() {
        Account acc = createAccount();
        InsurancePolicy pol = createPolicy(acc.Id, 'Voided');
        Product2 prod = createProduct('Voided Plan', 'Medical');
        createCoverage(pol.Id, prod.Id, 10.00);

        Test.startTest();
        List<ARC_SGSelectedPlansController.PlanWrapper> results =
            ARC_SGSelectedPlansController.getSelectedPlans(acc.Id);
        Test.stopTest();

        System.assertEquals(1, results.size());
    }
}