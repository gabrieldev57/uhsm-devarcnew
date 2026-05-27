@isTest
public with sharing class ARC_WaitingPeriodsLogicTest {
    @TestSetup
    public static void createData() {
        Account acc = ARC_TestUtility.createTestAccount(1, 'ARC_IFPPersonAccount')[0];
        List<Contract> cont = ARC_TestUtility.createContracts(2);
        List<InsurancePolicy> pol = ARC_TestUtility.createTestPolicies(2, 'ARC_IndividualAndFamily');
        List<Product2> prods = ARC_TestUtility.createTestProducts(2);
        List<InsurancePolicyParticipant> part = ARC_TestUtility.createTestPolicyParticipant(2);
        
        acc = [SELECT Id, PersonContactId, PersonBirthdate FROM Account WHERE Id = :acc.Id LIMIT 1];
        Contact personCont = [SELECT Id, Birthdate FROM Contact WHERE Id = :acc.PersonContactId LIMIT 1];
        Product2 weShare = prods[0];
        Product2 smart = prods[1];
        
        weShare.Name = 'WeShare 1k';
        weShare.ProductCode = 'WeShare_1k';
        update weShare;
        
        smart.Name = 'SMART 50000';
        smart.ProductCode = 'SMART_50000';
        update smart;
        
        if (acc.PersonBirthdate == null) {
            acc.PersonBirthdate = Date.today().addYears(-30);
            update acc;
            personCont = [SELECT Id, Birthdate FROM Contact WHERE Id = :acc.PersonContactId LIMIT 1];
        }
        
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
        //polNA.ARC_EffectiveDate__c = Date.today();
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
        
        contAM.ARC_EffectiveDate__c = Date.today().addDays(1);
        contAM.ARC_ContractReason__c = 'Add Member';
        insert contAM;
        
        polAM.ARC_Contract__c = contAM.Id;
        polAM.ProductId = weShare.Id;
        polAM.PriorPolicyId = polNA.Id;
        //polAM.ARC_EffectiveDate__c = Date.today().addDays(1);
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

        List<InsurancePolicyParticipant> parts = [
            SELECT Id, InsurancePolicyId, WP_Cancer__c, WP_Pre_Ex__c, WP_Normal__c, WP_Glacoma__c, WP_Immunizations__c, WP_Colon__c
            FROM InsurancePolicyParticipant
        ];
        Integer participantsWithWP = 0;
        for (InsurancePolicyParticipant p : parts) {
            Boolean hasWP = false;
            if (p.WP_Cancer__c != null) hasWP = true;
            if (p.WP_Pre_Ex__c != null) hasWP = true;
            if (p.WP_Normal__c != null) hasWP = true;
            if (p.WP_Glacoma__c != null) hasWP = true;
            if (p.WP_Immunizations__c != null) hasWP = true;
            if (p.WP_Colon__c != null) hasWP = true;
            if (hasWP) {
                participantsWithWP++;
            }
        }
        System.assert(participantsWithWP > 0, 'At least one participant should have WP fields populated after stampWaitingPeriods execution.');
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
    @isTest
    public static void carryOverWP_newborns_setsBirthdateOnCurrentParticipant() {
        Contract carryOverContract = [
            SELECT Id
            FROM Contract
            WHERE ARC_ContractReason__c = 'Add Member'
            LIMIT 1
        ];

        InsurancePolicy currentPolicy = [
            SELECT Id, ARC_Contract__c
            FROM InsurancePolicy
            WHERE ARC_Contract__c = :carryOverContract.Id
            LIMIT 1
        ];

        InsurancePolicyParticipant currentPart = [
            SELECT Id, PrimaryParticipantContactId, WP_Cancer__c, WP_Pre_Ex__c, WP_Normal__c,
                   WP_Glacoma__c, WP_Immunizations__c, WP_Colon__c
            FROM InsurancePolicyParticipant
            WHERE InsurancePolicyId = :currentPolicy.Id
            LIMIT 1
        ];

        Contact personCont = [
            SELECT Id, Birthdate
            FROM Contact
            WHERE Id = :currentPart.PrimaryParticipantContactId
            LIMIT 1
        ];

        currentPart.WP_Cancer__c = null;
        currentPart.WP_Pre_Ex__c = null;
        currentPart.WP_Normal__c = null;
        currentPart.WP_Glacoma__c = null;
        currentPart.WP_Immunizations__c = null;
        currentPart.WP_Colon__c = null;
        update currentPart;

        Test.startTest();
        ARC_WaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{ carryOverContract.Id }, new List<Date>{ personCont.Birthdate });
        Test.stopTest();

        InsurancePolicyParticipant updatedPart = [
            SELECT Id, WP_Cancer__c, WP_Pre_Ex__c, WP_Normal__c, WP_Glacoma__c, WP_Immunizations__c, WP_Colon__c
            FROM InsurancePolicyParticipant
            WHERE Id = :currentPart.Id
            LIMIT 1
        ];

        Boolean hasBirthdateStamped = false;
        if (updatedPart.WP_Cancer__c == personCont.Birthdate) hasBirthdateStamped = true;
        if (updatedPart.WP_Pre_Ex__c == personCont.Birthdate) hasBirthdateStamped = true;
        if (updatedPart.WP_Normal__c == personCont.Birthdate) hasBirthdateStamped = true;
        if (updatedPart.WP_Glacoma__c == personCont.Birthdate) hasBirthdateStamped = true;
        if (updatedPart.WP_Immunizations__c == personCont.Birthdate) hasBirthdateStamped = true;
        if (updatedPart.WP_Colon__c == personCont.Birthdate) hasBirthdateStamped = true;

        System.assert(hasBirthdateStamped, 'Expected carryOverWP newborn branch to stamp at least one WP field with the birthdate.');
    }

    @isTest
    public static void carryOverWP_smartRemoved_setsCancerToTwelveMonths() {
        Contract carryOverContract = [
            SELECT Id
            FROM Contract
            WHERE ARC_ContractReason__c = 'Add Member'
            LIMIT 1
        ];

        InsurancePolicy currentPolicy = [
            SELECT Id, PriorPolicyId, ARC_Contract__c
            FROM InsurancePolicy
            WHERE ARC_Contract__c = :carryOverContract.Id
            LIMIT 1
        ];

        InsurancePolicyParticipant currentPart = [
            SELECT Id, PrimaryParticipantContactId, InsurancePolicyId, Role, WP_Cancer__c, WP_Immunizations__c
            FROM InsurancePolicyParticipant
            WHERE InsurancePolicyId = :currentPolicy.Id
            LIMIT 1
        ];

        Account pa = [
            SELECT Id, ARC_LastWPResetDate__c
            FROM Account
            WHERE PersonContactId = :currentPart.PrimaryParticipantContactId
            LIMIT 1
        ];
        pa.ARC_LastWPResetDate__c = Date.today().addMonths(-2);
        update pa;

        currentPart.Role = 'Dependent';
        currentPart.WP_Cancer__c = null;
        currentPart.WP_Immunizations__c = null;
        update currentPart;

        List<ARC_CoverageParticipant__c> currentSmartCoverageParticipants = [
            SELECT Id
            FROM ARC_CoverageParticipant__c
            WHERE ARC_Policy__c = :currentPolicy.Id
              AND ARC_PolicyCoverage__r.CoverageName = 'SMART 50000'
        ];
        if (!currentSmartCoverageParticipants.isEmpty()) {
            delete currentSmartCoverageParticipants;
        }

        Test.startTest();
        ARC_WaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{ carryOverContract.Id }, null);
        Test.stopTest();

        InsurancePolicyParticipant updatedPart = [
            SELECT Id, WP_Cancer__c, WP_Immunizations__c
            FROM InsurancePolicyParticipant
            WHERE Id = :currentPart.Id
            LIMIT 1
        ];

        System.assertEquals(pa.ARC_LastWPResetDate__c.addMonths(12), updatedPart.WP_Cancer__c,
            'Expected SMART removed branch to set WP_Cancer__c to last reset date plus 12 months.');
        System.assertEquals(pa.ARC_LastWPResetDate__c.addMonths(10), updatedPart.WP_Immunizations__c,
            'Expected dependent immunizations branch to set WP_Immunizations__c to last reset date plus 10 months.');
    }

    @isTest
    public static void carryOverWP_smartAdded_setsCancerToTwoMonths() {
        Contract carryOverContract = [
            SELECT Id
            FROM Contract
            WHERE ARC_ContractReason__c = 'Add Member'
            LIMIT 1
        ];

        InsurancePolicy currentPolicy = [
            SELECT Id, PriorPolicyId, ARC_Contract__c
            FROM InsurancePolicy
            WHERE ARC_Contract__c = :carryOverContract.Id
            LIMIT 1
        ];

        InsurancePolicyParticipant currentPart = [
            SELECT Id, PrimaryParticipantContactId, InsurancePolicyId, WP_Cancer__c
            FROM InsurancePolicyParticipant
            WHERE InsurancePolicyId = :currentPolicy.Id
            LIMIT 1
        ];

        Account pa = [
            SELECT Id, ARC_LastWPResetDate__c
            FROM Account
            WHERE PersonContactId = :currentPart.PrimaryParticipantContactId
            LIMIT 1
        ];
        pa.ARC_LastWPResetDate__c = Date.today().addMonths(-2);
        update pa;

        currentPart.WP_Cancer__c = null;
        update currentPart;

        List<ARC_CoverageParticipant__c> oldSmartCoverageParticipants = [
            SELECT Id
            FROM ARC_CoverageParticipant__c
            WHERE ARC_Policy__c = :currentPolicy.PriorPolicyId
              AND ARC_PolicyCoverage__r.CoverageName = 'SMART 50000'
        ];
        if (!oldSmartCoverageParticipants.isEmpty()) {
            delete oldSmartCoverageParticipants;
        }

        Test.startTest();
        ARC_WaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{ carryOverContract.Id }, null);
        Test.stopTest();

        InsurancePolicyParticipant updatedPart = [
            SELECT Id, WP_Cancer__c
            FROM InsurancePolicyParticipant
            WHERE Id = :currentPart.Id
            LIMIT 1
        ];

        System.assertEquals(pa.ARC_LastWPResetDate__c.addMonths(2), updatedPart.WP_Cancer__c,
            'Expected SMART added branch to set WP_Cancer__c to last reset date plus 2 months.');
    }
}