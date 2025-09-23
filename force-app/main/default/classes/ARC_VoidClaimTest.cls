@isTest
public with sharing class ARC_VoidClaimTest {
    
    @isTest(SeeAllData=true)
    public static void testVoid() {
        Claim clm = new Claim();
        clm.Name = 'Test Claim for Voiding';
        clm.ARC_DOSTo__c = Date.today();
        clm.ARC_TotalNetPaidAmount__c = 2512;
        
        Id codeRT = Schema.SObjectType.vlocity_ins__VlocityCode__c.getRecordTypeInfosByDeveloperName().get('RARC').getRecordTypeId();
        vlocity_ins__VlocityCode__c code = new vlocity_ins__VlocityCode__c(Name = 'V0001', ARC_Status__c = 'Denied', RecordTypeId = codeRT);
        insert code;
        clm.ARC_ReasonCode__c = code.Id;

        InsurancePolicyParticipant ipp = ARC_TestUtility.createTestPolicyParticipant(1)[0];

        InsurancePolicy pol = ARC_TestUtility.createTestPolicies(1)[0];
        clm.PolicyNumberId = pol.Id;
        clm.ARC_ParticipantPolicyParticipant__c = ipp.Id;
        clm.ARC_DOSFrom__c = System.Today();
        insert clm;

        ClaimCoverage cc = new ClaimCoverage();
        cc.Name = 'Not covered';
        cc.ClaimId = clm.Id;
        cc.InternalReserveMode = 'CoverageReserve';
        insert cc;

        List<vlocity_ins__Attribute__c> atts =[ SELECT Id, Name, vlocity_ins__Code__c FROM vlocity_ins__Attribute__c WHERE vlocity_ins__Code__c ='WELL_PreExistingConditions' OR vlocity_ins__Code__c = 'familyAMCS' OR vlocity_ins__Code__c ='WELL_ChiropracticVisits' OR vlocity_ins__Code__c ='WELL_Behavioral Health Therapy Sessions' OR vlocity_ins__Code__c ='WELL_AccupuntureTreatmentFramework' OR vlocity_ins__Code__c ='POW_COPAY' OR vlocity_ins__Code__c = 'POW_COIN'];
        List<ClaimCoveragePaymentDetail> ccpds = ARC_TestUtility.createTestCoveragePayments(4);
        for (Integer i = 0; i < 4; i++) {
            ccpds[i].ARC_Allowed__c = 1000;
            switch on i {
                when 0 {
                    ccpds[i].ARC_Medical_Visit_Reason__c = 'Acupuncture';
                    ccpds[i].ARC_Deductible__c = 100;
                    ccpds[i].ARC_Pre_Existing_Condition__c = 100;
                    ccpds[i].ARC_Coinsurance__c = 100;
                }
                when 1 {
                    ccpds[i].ARC_Medical_Visit_Reason__c = 'Behavioral';
                    ccpds[i].ARC_Deductible__c = 150;
                    ccpds[i].ARC_Pre_Existing_Condition__c = 150;
                    ccpds[i].ARC_Coinsurance__c = 100;
                }
                when 2 {
                    ccpds[i].ARC_Medical_Visit_Reason__c = 'PhysicalTherapy';
                    ccpds[i].ARC_Deductible__c = 232;
                    ccpds[i].ARC_Pre_Existing_Condition__c = 232;
                    ccpds[i].ARC_Coinsurance__c = 100;
                }            
                when 3 {
                    ccpds[i].ARC_Medical_Visit_Reason__c = 'Office Visit/Copay';
                    ccpds[i].ARC_Deductible__c = 252.02;
                    ccpds[i].ARC_Pre_Existing_Condition__c = 252.02;
                    ccpds[i].ARC_Coinsurance__c = 100;
                }
            }
            ccpds[i].ARC_Claim__c = clm.Id;
            //ccpds[i].ARC_Claim__c = cc.Id;
        }
        update ccpds;

        List<vlocity_ins_fsc__InsurancePolicyTerm__c> ipts = ARC_TestUtility.createTestPolicyTerm(7);

        Integer ij = 0;
        for (vlocity_ins_fsc__InsurancePolicyTerm__c ipt : ipts) {
            
            ipt.vlocity_ins_fsc__InsurancePolicyId__c = pol.Id;                
            ipt.ARC_CurrentValue__c = 100;
            ipt.ARC_Remaining_Number__c = 100;      
            ipt.vlocity_ins_fsc__InsurancePolicyParticipantId__c=ipp.Id;   
            ipt.ARC_Year__c=System.Today().Year();
            switch on ij {
                when 0 {
                    ipt.vlocity_ins_fsc__AttributeId__c =atts[ij].Id ;              }
                when 1 {
                    ipt.vlocity_ins_fsc__AttributeId__c =atts[ij].Id;               }
                when 2 {
                    ipt.vlocity_ins_fsc__AttributeId__c =atts[ij].Id;               }
                when 3 {
                    ipt.vlocity_ins_fsc__AttributeId__c =atts[ij].Id;               }
                when 4 {
                    ipt.vlocity_ins_fsc__AttributeId__c =atts[ij].Id;               }
                when 5 {
                    ipt.vlocity_ins_fsc__AttributeId__c =atts[ij].Id;               }
                when 6 {
                    ipt.vlocity_ins_fsc__AttributeId__c =atts[ij].Id;               }
            } 
            ij++;
        }
        List<FormulaRecalcResult> results = Formula.recalculateFormulas(ipts); 
        upsert ipts;
    
        List<ClaimPaymentSummary> cpss = new List<ClaimPaymentSummary>();
        for (Integer i = 0; i < 4; i++) {
            ClaimPaymentSummary cps = new ClaimPaymentSummary();
            cps.ClaimId = clm.Id;
            cps.Name = 'Test Clone ' + i;
            switch on i {
                when 0 {
                    cps.ARC_SMB_Item__c = ccpds[0].Id;
                }
                when 1 {
                    cps.ARC_SMB_Item__c = ccpds[1].Id;
                }
                when 2 {
                    cps.ARC_SMB_Item__c = ccpds[2].Id;
                }            
                when 3 {
                    cps.ARC_SMB_Item__c = ccpds[3].Id;
                }}
            cpss.add(cps);                    
        }
        insert cpss;

      
        ARC_VoidClaim.VoidClaim input = new ARC_VoidClaim.VoidClaim();
        input.ClaimId = clm.Id;
        input.removed = false;

        Test.startTest();
            ARC_VoidClaim.VoidClaim(new List<ARC_VoidClaim.VoidClaim>{input});   
        Test.stopTest();
    }
}