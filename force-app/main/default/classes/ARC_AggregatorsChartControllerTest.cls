@isTest
public with sharing class ARC_AggregatorsChartControllerTest {

    @TestSetup
    static void mockData() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();

        vlocity_ins__GroupCensusMember__c cMemb = ARC_TestUtility.createTestCensusMember(1)[0];
        Contract con = ARC_TestUtility.createContracts(1)[0];
        con.vlocity_ins__EnrollmentCensusId__c = cMemb.vlocity_ins__CensusId__c;
        con.ARC_ContractReason__c = 'New Application';
        insert con;

        Contract con2 = ARC_TestUtility.createContracts(1)[0];
        con2.vlocity_ins__EnrollmentCensusId__c = cMemb.vlocity_ins__CensusId__c;
        con2.ARC_ContractReason__c = 'Program Downgrade';
        insert con2;

        Account personAcc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount', Census_Member__c = cMemb.Id, LastName ='Test');
        insert personAcc;

        Id pContactId =(Id)[SELECT Id, PersonContactId FROM Account WHERE Id =: personAcc.Id][0].PersonContactId;

        cMemb.vlocity_ins__ContactId__c = pContactId;
        update cMemb;


        List<InsurancePolicy> policyTest = ARC_TestUtility.createTestPolicies(2);
        policyTest[0].ARC_Contract__c = con.Id;
        policyTest[1].ARC_Contract__c = con2.Id;
        update policyTest[0];
        policyTest[1].RenewedFromPolicyId = policyTest[0].Id;
        update policyTest[1];
        List<Claim> clm = ARC_TestUtility.createTestClaims(2);
        clm[0].PolicyNumberId = policyTest[0].Id;
        clm[1].PolicyNumberId = policyTest[1].Id;
        update clm[0];
        update clm[1];

        vlocity_ins_fsc__InsurancePolicyTerm__c ipt1 = new vlocity_ins_fsc__InsurancePolicyTerm__c();
        ipt1.vlocity_ins_fsc__InsurancePolicyId__c = policyTest[0].Id;
        ipt1.Name = 'test1';
        insert ipt1;

        vlocity_ins_fsc__InsurancePolicyTerm__c ipt2 = new vlocity_ins_fsc__InsurancePolicyTerm__c();
        ipt2.vlocity_ins_fsc__InsurancePolicyId__c = policyTest[0].Id;
        ipt2.Name = 'test2';
        insert ipt2;

    }

    @isTest
    public static void getAllDataTest() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();

        List<InsurancePolicy> policyTest = [SELECT Id FROM InsurancePolicy];
        List<Claim> claimTest = [SELECT Id FROM Claim];
        Account personAcc = [SELECT Id FROM Account WHERE RecordTypeId =: accRecordTypeId LIMIT 1];

        test.startTest();
        Map<String, Object> resultListWithIP = ARC_AggregatorsChartController.getAllData(String.valueOf(policyTest[0].Id));
        Map<String, Object> resultListWithCLM = ARC_AggregatorsChartController.getAllData(String.valueOf(claimTest[0].Id));
        Map<String, Object> resultListWithIP2 = ARC_AggregatorsChartController.getAllData(String.valueOf(policyTest[1].Id));
        Map<String, Object> resultListWithCLM2 = ARC_AggregatorsChartController.getAllData(String.valueOf(claimTest[1].Id));
        Map<String, Object> resultListWithPA = ARC_AggregatorsChartController.getAllData(String.valueOf(personAcc.Id));
        test.stopTest();
    }
}