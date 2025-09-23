public with sharing class ARC_ValidateClaimAfterMapping {
    
    @AuraEnabled
    public static Map<String, Object> getAllClaimCodes(String clmId) {
        Claim clm = [SELECT Id, ARC_CCToCompare__c, DX_A__r.Name, DX_B__r.Name, DX_C__r.Name, DX_D__r.Name, DX_E__r.Name, DX_F__r.Name, DX_G__r.Name, DX_H__r.Name, DX_I__r.Name, DX_J__r.Name, DX_K__r.Name, DX_L__r.Name, ARC_AdmitDX_Code__r.Name, ARC_Submitted_DRG_Code__r.Name, ARC_Principal_Procedure__r.Name, (SELECT Id, Name, ARC_ProcedureCode__r.Name FROM Claim_Coverage_Payment_Details__r), (SELECT Id, ARC_ICD_DX__r.Name, ARC_Other_Procedure_Code__r.Name, ARC_ConditionCode__r.Name, ARC_ECode__r.Name FROM Institutional_Claim_Codes__r) FROM Claim WHERE Id =: clmId LIMIT 1];
        Map<String, Object> output = new Map<String, Object>();
        Set<String> codesClaim = new Set<String>();
        List<String> cInput = clm.ARC_CCToCompare__c.split(';');
        Set<String> codesInput = new Set<String>(cInput);

        // CODES FROM: CLAIM
        if (clm.DX_A__r.Name != null) codesClaim.add(clm.DX_A__r.Name);
        if (clm.DX_B__r.Name != null) codesClaim.add(clm.DX_B__r.Name);
        if (clm.DX_C__r.Name != null) codesClaim.add(clm.DX_C__r.Name);
        if (clm.DX_D__r.Name != null) codesClaim.add(clm.DX_D__r.Name);
        if (clm.DX_E__r.Name != null) codesClaim.add(clm.DX_E__r.Name);
        if (clm.DX_F__r.Name != null) codesClaim.add(clm.DX_F__r.Name);
        if (clm.DX_G__r.Name != null) codesClaim.add(clm.DX_G__r.Name);
        if (clm.DX_H__r.Name != null) codesClaim.add(clm.DX_H__r.Name);
        if (clm.DX_I__r.Name != null) codesClaim.add(clm.DX_I__r.Name);
        if (clm.DX_J__r.Name != null) codesClaim.add(clm.DX_J__r.Name);
        if (clm.DX_K__r.Name != null) codesClaim.add(clm.DX_K__r.Name);
        if (clm.DX_L__r.Name != null) codesClaim.add(clm.DX_L__r.Name);
        if (clm.ARC_AdmitDX_Code__r.Name != null) codesClaim.add(clm.ARC_AdmitDX_Code__r.Name);
        if (clm.ARC_Submitted_DRG_Code__r.Name != null) codesClaim.add(clm.ARC_Submitted_DRG_Code__r.Name);
        if (clm.ARC_Principal_Procedure__r.Name != null) codesClaim.add(clm.ARC_Principal_Procedure__r.Name);

        // CODES FROM: LINE ITEMS
        for (ClaimCoveragePaymentDetail ccpd : clm.Claim_Coverage_Payment_Details__r) {
            if (ccpd.ARC_ProcedureCode__r.Name != null) codesClaim.add(ccpd.ARC_ProcedureCode__r.Name);
        }

        // CODES FROM: INSTITUTIONAL CODES
        for (ARC_Institutional_Claim_Code__c cc : clm.Institutional_Claim_Codes__r) {
            if (cc.ARC_ICD_DX__r.Name != null) codesClaim.add(cc.ARC_ICD_DX__r.Name);
            if (cc.ARC_Other_Procedure_Code__r.Name != null) codesClaim.add(cc.ARC_Other_Procedure_Code__r.Name);
            if (cc.ARC_ConditionCode__r.Name != null) codesClaim.add(cc.ARC_ConditionCode__r.Name);
            if (cc.ARC_ECode__r.Name != null) codesClaim.add(cc.ARC_ECode__r.Name);
        }

        output.put('codesClaim', codesClaim);
        output.put('codesInput', codesInput);
        return output;
    }

    @AuraEnabled
    public static Claim getOriginalClaim(String originalClaim){
        return [SELECT Name, ARC_TotalNetPaidAmount__c FROM Claim WHERE Id =: originalClaim AND ARC_ReasonCode__c != NULL LIMIT 1]; 
    }

    @AuraEnabled
    public static List<Claim> getClonedClaims(String clmId){
        return [SELECT Name, Id FROM Claim WHERE ARC_OriginalSMB__c =: clmId LIMIT 10];
    }

    @AuraEnabled
    public static Claim getOriginalCopy(String originalClaim){
        return [SELECT Name, Id FROM Claim WHERE Id =: originalClaim AND ARC_ReasonCode__c = NULL LIMIT 1];
    }

    @AuraEnabled
    public static Claim getClaimToValidate(String clmId){
        return [SELECT Name, Id, ARC_Attending_Provider__c, ARC_Attending_Provider__r.Name, (SELECT Id FROM Claim_Coverage_Payment_Details__r WHERE ARC_NetPaid__c < 0) FROM Claim WHERE Id =: clmId LIMIT 1];
    }
}