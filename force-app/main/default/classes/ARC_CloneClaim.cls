public with sharing class ARC_CloneClaim {
    
    public class inputRequest {
        @InvocableVariable(required=true)
        public String claimId;
        
        @InvocableVariable(required=true)
        public String codeId;
    }

    @InvocableMethod
    public static List<ARC_CloneClaimResult> createNewClaim(inputRequest[] requests) {
        Id claimId = requests[0].claimId;
        Id codeId = requests[0].codeId;

        // GET ORIGINAL CLAIM USING CUSTOM LABEL FIELDS
        String claimF = System.Label.ARC_FieldForClaimCopy1 + System.Label.ARC_FieldForClaimCopy2;
        Claim originalClaim = Database.query('SELECT ' + claimF + ' FROM Claim WHERE Id = ' + '\''+ claimId + '\'' + 'LIMIT 1');

        List<ARC_CloneClaimResult> ret = createClaimRecords(originalClaim, codeId);
        ARC_CoveragePaymentsTableController.resetItems(originalClaim, 'adjust', new Set<Id>());
        addAdjustmentCodes(originalClaim, ret[0].clonedClaim);
        return ret;
    }

    public static List<ARC_CloneClaimResult> createClaimRecords(Claim originalClaim, String codeId) {
        List<Claim> claimsToUpsert = new List<Claim>();
        List<ClaimCoveragePaymentDetail> itemsToInsert = new List<ClaimCoveragePaymentDetail>();
        List<ARC_Institutional_Claim_Code__c> instCodesToInsert = new List<ARC_Institutional_Claim_Code__c>();
        List<ARC_ClaimReasonCode__c> adjustCodesToInsert = new List<ARC_ClaimReasonCode__c>();

        // UPDATE ORIGINAL CLAIM STATUS
        originalClaim.Status = 'Adjusted';
        originalClaim.ARC_ReasonCode__c = codeId;
        originalClaim.ARC_VRHelper__c = !originalClaim.ARC_VRHelper__c;
        
        // INSERT CLAIM
        Claim copyClm = originalClaim.clone(false, false, false, false);


        originalClaim.ARC_TotalCopayAmount__c = 0;
        originalClaim.ARC_TotalCoinsuranceAmount__c = 0;
        originalClaim.ARC_TotalDeductibleAmount__c = 0;
        originalClaim.ARC_TotalPatientResponsibilityAmount__c = 0;
        claimsToUpsert.add(originalClaim);        

        if(originalClaim.Name.contains('- A')){
            String name = copyClm.Name;
            String str = name.right(1); 
            Integer intVal = Integer.ValueOf( str ) + 1;
            name = name.removeEnd(str) + intVal;

            copyClm.Name = name;
            copyClm.SourceSystemIdentifier = name;
        }else{
            copyClm.Name = copyClm.Name + ' - A1';
            copyClm.SourceSystemIdentifier = copyClm.Name + ' - A1';
        }
        copyClm.FinalizedDate = null;
        copyClm.AssessmentDate = null;
        copyClm.Status = 'Initial';
        copyClm.ARC_AuditorValidation__c = 'Pending';
        copyClm.ARC_ReasonCode__c = null;
        copyClm.ARC_OriginalSMB__c = originalClaim.Id;
        copyClm.ARC_CheckRun__c = null;
        copyClm.ARC_CheckNumber__c = null;
        copyClm.ARC_Adjust__c = true;
        copyClm.Analyzed_By__c = UserInfo.getUserId();
        copyClm.ARC_TotalPreviouslyPaidAmount__c = originalClaim.ARC_TotalNetPaidAmount__c;
        copyClm.De_Duplicate_Flag__c = true;
        claimsToUpsert.add(copyClm);        
        upsert claimsToUpsert;

        // INSERT CLAIM COVERAGE TO CREATE LINE ITEMS
        ClaimCoverage cc = new ClaimCoverage();
        if(copyClm.ARC_InputJSON__c != null || copyClm.ARC_ClaimInput__c != null) {
            cc.Name = 'Not covered';
            cc.ClaimId = copyClm.Id;
            cc.InternalReserveMode = 'CoverageReserve';
            insert cc;
        }else{
            cc = [SELECT Id FROM ClaimCoverage WHERE ClaimId =: copyClm.Id]; 
        }

        // INSERT LINE ITEMS
        String claimItemF = System.Label.ARC_FieldForClaimItemCopy1;
        List<ClaimCoveragePaymentDetail> lineItems = Database.query('SELECT ' + claimItemF + ' FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =\'' + String.escapeSingleQuotes(originalClaim.Id) + '\' LIMIT 1000');

        for (ClaimCoveragePaymentDetail i : lineItems) {
            ClaimCoveragePaymentDetail item = i.clone(false, false, false, false);
            item.ARC_Claim__c = copyClm.Id;
            item.ClaimCoverageId = cc.Id;
            item.Status = 'New';
            itemsToInsert.add(item);
        }
        insert itemsToInsert;

        // INSERT INSTITUTIONAL CLAIM CODES
        List<ARC_Institutional_Claim_Code__c> claimCodes = [SELECT ARC_Amount__c, ARC_ConditionCode__c, ARC_Date__c, ARC_Date_From__c, ARC_Date_Through__c, ARC_ECodes__c, ARC_ICD_DX__c, ARC_Institutional_Claim__c, ARC_Occurrence_Code__c, ARC_Occurrence_Span_Code__c, ARC_Other_Procedure_Code__c, ARC_Patient_DX__c, ARC_POA__c, ARC_Vale_Codes__c FROM ARC_Institutional_Claim_Code__c WHERE ARC_Institutional_Claim__c =: originalClaim.Id LIMIT 1000];
        for(ARC_Institutional_Claim_Code__c instC : claimCodes){
            ARC_Institutional_Claim_Code__c clmCode = instC.clone(false, false, false, false);
            clmCode.ARC_Institutional_Claim__c = copyClm.Id;
            instCodesToInsert.add(clmCode);
        }
        insert instCodesToInsert;

        ARC_CloneClaimResult result = new ARC_CloneClaimResult();
        result.clonedClaim = claimsToUpsert[1];
        List<ARC_CloneClaimResult> resultList = new List<ARC_CloneClaimResult>();
        resultList.add(result);
        return resultList;
    }  

    
    public static void addAdjustmentCodes(Claim originalClaim, Claim newClaim) {
        List<ARC_ClaimReasonCode__c> adjustCodesToInsert = new List<ARC_ClaimReasonCode__c>();
        String claimItemF = System.Label.ARC_FieldForClaimItemCopy1;
        List<ClaimCoveragePaymentDetail> lineItems = Database.query('SELECT ' + claimItemF + ' FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =\'' + String.escapeSingleQuotes(newClaim.Id) + '\' LIMIT 1000');
        for (ClaimCoveragePaymentDetail item: lineItems){
            ARC_ClaimReasonCode__c adjustReasonCode = new ARC_ClaimReasonCode__c();
            adjustReasonCode.ARC_ReasonCode__c = originalClaim.ARC_ReasonCode__c;
            adjustReasonCode.ARC_ClaimCoveragePaymentDetail__c = item.Id;
            adjustCodesToInsert.add(adjustReasonCode);
        }
        insert adjustCodesToInsert;
    }

    public class ARC_CloneClaimResult {
        @InvocableVariable
        public Claim clonedClaim;
    }
}