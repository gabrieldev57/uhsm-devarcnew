@isTest
public with sharing class ARC_CloneClaimTest {
    public static final ARC_CloneClaim classTest = new ARC_CloneClaim();

    @isTest(SeeAllData=true)
    static void ARC_CloneClaimTest() {
       
        Claim clm = new Claim();
        clm.Name = 'Test Claim for Cloning';
        clm.ARC_TotalNetPaidAmount__c = 2512;
        
        vlocity_ins__VlocityCode__c code = [SELECT Id, Name FROM vlocity_ins__VlocityCode__c LIMIT 1];
        clm.ARC_ReasonCode__c = code.Id;
        System.debug(code);

        InsurancePolicy pol = ARC_TestUtility.createTestPolicies(1, 'ARC_IndividualAndFamily')[0];
        
        InsurancePolicyParticipant ipp = ARC_TestUtility.createTestPolicyParticipant(1)[0];
        ipp.InsurancePolicyId = pol.Id;
        insert ipp;

        clm.PolicyNumberId = pol.Id;
        clm.ARC_ParticipantPolicyParticipant__c = ipp.Id;
        clm.ARC_DOSFrom__c = System.Today();
        clm.ARC_DOSTo__c = System.Today();
        insert clm;
    

        ClaimCoverage cc = new ClaimCoverage();
        cc.Name = 'Not covered';
        cc.ClaimId = clm.Id;
        cc.InternalReserveMode = 'CoverageReserve';
        insert cc;

        List<ClaimCoveragePaymentDetail> ccpds = ARC_TestUtility.createTestCoveragePayments(4);
        for (Integer i = 0; i < 4; i++) {
            ccpds[i].ARC_Allowed__c = 1000;
            ccpds[i].ARC_Deductible__c = 100;
            ccpds[i].ARC_Claim__c = clm.Id;
            ccpds[i].Status = 'Paid';
        }
        update ccpds;

        vlocity_ins__vlocityCode__c code2 = new vlocity_ins__vlocityCode__c(Name = 'TestCode2');
        ARC_Institutional_Claim_Code__c claimCode = new ARC_Institutional_Claim_Code__c(ARC_Institutional_Claim__c= clm.Id);
        insert code2;
        
        clm.ARC_CCToCompare__c = 'TestCode2';
        clm.DX_A__c = code2.Id;
        clm.DX_B__c = code2.Id;
        clm.DX_C__c = code2.Id;
        clm.DX_D__c = code2.Id;
        clm.DX_E__c = code2.Id;
        clm.DX_F__c = code2.Id;
        clm.DX_G__c = code2.Id;
        clm.DX_H__c = code2.Id;
        clm.DX_I__c = code2.Id;
        clm.DX_J__c = code2.Id;
        clm.DX_K__c = code2.Id;
        clm.DX_L__c = code2.Id;
        clm.ARC_AdmitDX_Code__c = code2.Id;
        clm.ARC_Submitted_DRG_Code__c = code2.Id;
        clm.ARC_Principal_Procedure__c = code2.Id;
        claimCode.ARC_ICD_DX__c = code2.Id;
        claimCode.ARC_Other_Procedure_Code__c = code2.Id;
        claimCode.ARC_ConditionCode__c = code2.Id;

        update clm;
        insert claimCode;

        ARC_Aggregator__c agg = new ARC_Aggregator__c();
        agg.Name = 'Individual AMCS';
        agg.ARC_Code__c = 'AMCS__c';
        agg.ARC_CreatedIn__c = pol.Id;
        agg.ARC_LimitValue__c = 8000;
        agg.ARC_Year__c = System.today().year() + '';
        agg.ARC_Type__c = 'Currency';
        insert agg;

        ARC_ParticipantAggregator__c pAgg = new ARC_ParticipantAggregator__c();
        pAgg.ARC_Aggregator__c = agg.Id;
        pAgg.ARC_ConsumedValue__c = 500;
        pAgg.ARC_Policy__c = pol.Id;
        pAgg.ARC_PolicyParticipant__c = ipp.Id;
        insert pAgg;
    
        List<ClaimPaymentSummary> pSumList = new List<ClaimPaymentSummary>();
        for (Integer i = 0; i < 4; i++) {
            ClaimPaymentSummary pSum = new ClaimPaymentSummary();
            pSum.ARC_ConsumedValue__c = 500;
            pSum.Name = 'AMCS__c - 1';
            pSum.ARC_ParticipantAggregator__c = pAgg.Id;
            pSum.ClaimId = clm.Id;
            pSumList.add(pSum);
        }
        insert pSumList;

        ARC_CloneClaim.inputRequest input = new ARC_CloneClaim.inputRequest();
        input.ClaimId = clm.Id;
        input.codeId = clm.ARC_ReasonCode__c;

        Test.startTest();
            ARC_CloneClaim.createNewClaim(new List<ARC_CloneClaim.inputRequest>{input});
        Test.stopTest();
    }
}