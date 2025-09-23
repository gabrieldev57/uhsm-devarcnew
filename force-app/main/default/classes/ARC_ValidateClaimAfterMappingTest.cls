@isTest
public with sharing class ARC_ValidateClaimAfterMappingTest {
    
    @isTest
    public static void getAllClaimCodesTest() {
        Claim clm = ARC_TestUtility.createTestClaims(1)[0];
        ClaimCoveragePaymentDetail ccpd = ARC_TestUtility.createTestCoveragePayments(1)[0];

        vlocity_ins__vlocityCode__c code = new vlocity_ins__vlocityCode__c(Name = 'TestCode');
        ARC_Institutional_Claim_Code__c claimCode = new ARC_Institutional_Claim_Code__c(ARC_Institutional_Claim__c= clm.Id);
        insert code;
        
        clm.ARC_CCToCompare__c = 'TestCode';
        clm.DX_A__c = code.Id;
        clm.DX_B__c = code.Id;
        clm.DX_C__c = code.Id;
        clm.DX_D__c = code.Id;
        clm.DX_E__c = code.Id;
        clm.DX_F__c = code.Id;
        clm.DX_G__c = code.Id;
        clm.DX_H__c = code.Id;
        clm.DX_I__c = code.Id;
        clm.DX_J__c = code.Id;
        clm.DX_K__c = code.Id;
        clm.DX_L__c = code.Id;
        clm.ARC_AdmitDX_Code__c = code.Id;
        clm.ARC_Submitted_DRG_Code__c = code.Id;
        clm.ARC_Principal_Procedure__c = code.Id;
        ccpd.ARC_Claim__c = clm.Id;
        ccpd.ARC_ProcedureCode__c = code.Id;
        claimCode.ARC_ICD_DX__c = code.Id;
        claimCode.ARC_Other_Procedure_Code__c = code.Id;
        claimCode.ARC_ConditionCode__c = code.Id;

        update clm;
        update ccpd;
        insert claimCode;
        
        Map<String, Object> expect = ARC_ValidateClaimAfterMapping.getAllClaimCodes(String.valueOf(clm.Id));
        Set<String> codesInput = (Set<String>)expect.get('codesInput');
        Set<String> codesClaim = (Set<String>)expect.get('codesClaim');
        System.assertEquals(codesInput.size(), 1);
        System.assertEquals(codesClaim.size(), 1);
    }
}