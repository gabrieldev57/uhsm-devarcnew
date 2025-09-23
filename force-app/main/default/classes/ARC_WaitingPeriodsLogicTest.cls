@isTest
public with sharing class ARC_WaitingPeriodsLogicTest {
    @TestSetup
    public static void createData() {
        Account acc = ARC_TestUtility.createTestAccount(1, 'ARC_IFPPersonAccount')[0];
        List<Contract> cont = ARC_TestUtility.createContracts(2);
        List<InsurancePolicy> pol = ARC_TestUtility.createTestPolicies(2);
        List<Product2> prods = ARC_TestUtility.createTestProducts(2);
        List<InsurancePolicyParticipant> part = ARC_TestUtility.createTestPolicyParticipant(2);
        
        Contact personCont = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
        Product2 weShare = prods[0];
        Product2 smart = prods[1];
        
        weShare.Name = 'WeShare 1k';
        update weShare;
        smart.Name = 'SMART 50000';
        update smart;
        
        // RESET WPs
        Contract contNA = cont[0];
        InsurancePolicy polNA = pol[0];
        InsurancePolicyParticipant partNA = part[0];
        InsurancePolicyCoverage covWeShareNA = new InsurancePolicyCoverage();
        InsurancePolicyCoverage covSmartNA = new InsurancePolicyCoverage();
        ARC_CoverageParticipant__c covPartWeshareNA = new ARC_CoverageParticipant__c();
        ARC_CoverageParticipant__c covPartSmartNA = new ARC_CoverageParticipant__c();
        contNA.ARC_EffectiveDate__c = Date.today();
        contNA.ARC_ContractReason__c = 'New Application';
        insert contNA;
        polNA.ARC_Contract__c = contNA.Id;
        polNA.ProductId = weShare.Id;
        update polNA;
        partNA.InsurancePolicyId = polNA.Id;
        partNA.PrimaryParticipantContactId = personCont.Id;
        insert partNA;
        covWeShareNA.vlocity_ins_fsc__Product2Id__c = weShare.Id;
        covWeShareNA.InsurancePolicyId = polNA.Id;
        covWeShareNA.CoverageName = 'WeShare 1k';
        insert covWeShareNA;
        covSmartNA.vlocity_ins_fsc__Product2Id__c = smart.Id;
        covSmartNA.InsurancePolicyId = polNA.Id;
        covSmartNA.CoverageName = 'SMART 50000';
        insert covSmartNA;
        covPartWeshareNA.ARC_PolicyCoverage__c = covWeShareNA.Id;
        covPartWeshareNA.ARC_PolicyParticipant__c = partNA.Id;
        covPartWeshareNA.ARC_Policy__c = polNA.Id;
        insert covPartWeshareNA;
        covPartSmartNA.ARC_PolicyCoverage__c = covSmartNA.Id;
        covPartSmartNA.ARC_PolicyParticipant__c = partNA.Id;
        covPartSmartNA.ARC_Policy__c = polNA.Id;
        insert covPartSmartNA;

        // CARRY OVER WPs
        Contract contAM = cont[1];
        InsurancePolicy polAM = pol[1];
        InsurancePolicyParticipant partAM = part[1];
        InsurancePolicyCoverage covWeShareAM = new InsurancePolicyCoverage();
        InsurancePolicyCoverage covSmartAM = new InsurancePolicyCoverage();
        ARC_CoverageParticipant__c covPartWeshareAM = new ARC_CoverageParticipant__c();
        ARC_CoverageParticipant__c covPartSmartAM = new ARC_CoverageParticipant__c();
        contAM.ARC_EffectiveDate__c = Date.today() + 1;
        contAM.ARC_ContractReason__c = 'Add Member';
        insert contAM;
        polAM.ARC_Contract__c = contAM.Id;
        polAM.ProductId = weShare.Id;
        polAM.PriorPolicyId = polNA.Id;
        update polAM;
        partAM.InsurancePolicyId = polAM.Id;
        partAM.PrimaryParticipantContactId = personCont.Id;
        insert partAM;
        covWeShareAM.vlocity_ins_fsc__Product2Id__c = weShare.Id;
        covWeShareAM.InsurancePolicyId = polAM.Id;
        covWeShareAM.CoverageName = 'WeShare 1k';
        insert covWeShareAM;
        covSmartAM.vlocity_ins_fsc__Product2Id__c = smart.Id;
        covSmartAM.InsurancePolicyId = polAM.Id;
        covSmartAM.CoverageName = 'SMART 50000';
        insert covSmartAM;
        covPartWeshareAM.ARC_PolicyCoverage__c = covWeShareAM.Id;
        covPartWeshareAM.ARC_PolicyParticipant__c = partAM.Id;
        covPartWeshareAM.ARC_Policy__c = polAM.Id;
        insert covPartWeshareAM;
        covPartSmartAM.ARC_PolicyCoverage__c = covSmartAM.Id;
        covPartSmartAM.ARC_PolicyParticipant__c = partAM.Id;
        covPartSmartAM.ARC_Policy__c = polAM.Id;
        insert covPartSmartAM;

    }

    @isTest
    public static void stampWaitingPeriodsTest(){
        List<Date> dates = new List<Date>{ Date.today(), Date.today().addDays(-1) };
        Test.startTest();
        ARC_WaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{[SELECT Id FROM Contract ORDER BY CreatedDate ASC LIMIT 1].Id}, dates);
        ARC_WaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{[SELECT Id FROM Contract ORDER BY CreatedDate DESC LIMIT 1].Id}, null);
        Test.stopTest();

        List<InsurancePolicyParticipant> parts = [SELECT Id, WP_Cancer__c, WP_Pre_Ex__c, WP_Normal__c, WP_Glacoma__c, WP_Immunizations__c, WP_Colon__c FROM InsurancePolicyParticipant];
        Map<String, Schema.SObjectType> detail = Schema.getGlobalDescribe();
        for (InsurancePolicyParticipant p : parts) {
            Boolean hasWP = false;
            if (p.WP_Cancer__c != null) hasWP = true;
            if (p.WP_Pre_Ex__c != null) hasWP = true;
            if (p.WP_Normal__c != null) hasWP = true;
            if (p.WP_Glacoma__c != null) hasWP = true;
            if (p.WP_Immunizations__c != null) hasWP = true;
            if (p.WP_Colon__c != null) hasWP = true;
            System.assert(hasWP, 'At least one WP field should be set for participant: ' + p.Id);
        }
    }

    @isTest
    public static void prevPolCarryOverTest() {
        List<InsurancePolicy> policies = [SELECT Id, ARC_Contract__c, PriorPolicyId FROM InsurancePolicy ORDER BY CreatedDate ASC];
        List<InsurancePolicyParticipant> participants = [SELECT Id, InsurancePolicyId, PrimaryParticipantContactId, WP_Cancer__c, WP_Pre_Ex__c FROM InsurancePolicyParticipant ORDER BY CreatedDate ASC];

        InsurancePolicy priorPolicy = policies[0];
        InsurancePolicy newPolicy = policies[1];

        InsurancePolicyParticipant priorPart = null;
        InsurancePolicyParticipant newPart = null;
        for (InsurancePolicyParticipant p : participants) {
            if (p.InsurancePolicyId == priorPolicy.Id) priorPart = p;
            if (p.InsurancePolicyId == newPolicy.Id) newPart = p;
        }

        // Set WP fields on prior participant
        priorPart.WP_Cancer__c = Date.today().addMonths(1);
        priorPart.WP_Pre_Ex__c = Date.today().addMonths(2);
        update priorPart;

        newPart.WP_Cancer__c = null;
        newPart.WP_Pre_Ex__c = null;
        update newPart;

        // Prepare input for invocable method
        ARC_WaitingPeriodsLogic.InputVariables input = new ARC_WaitingPeriodsLogic.InputVariables();
        input.policyId = newPolicy.Id;
        input.priorPolicyId = priorPolicy.Id;

        Test.startTest();
        ARC_WaitingPeriodsLogic.prevPolCarryOver(new List<ARC_WaitingPeriodsLogic.InputVariables>{input});
        Test.stopTest();

        InsurancePolicyParticipant updatedNewPart = [
            SELECT Id, WP_Cancer__c, WP_Pre_Ex__c
            FROM InsurancePolicyParticipant
            WHERE Id = :newPart.Id
        ];
        System.assertEquals(priorPart.WP_Cancer__c, updatedNewPart.WP_Cancer__c, 'WP_Cancer__c should be copied from prior policy');
        System.assertEquals(priorPart.WP_Pre_Ex__c, updatedNewPart.WP_Pre_Ex__c, 'WP_Pre_Ex__c should be copied from prior policy');
    }
}