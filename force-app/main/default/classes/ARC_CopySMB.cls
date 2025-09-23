public with sharing class ARC_CopySMB {
    
    public class inputRequest {
        @InvocableVariable(label = 'Claim Id' required=true)
        public String claimId;
    }

    @InvocableMethod(label='Copy SMB' description='Create a Copy of the Claim')
    public static List<ARC_CopyClaimResult> createNewCopySMB(inputRequest[] request) {
        
        Id claimId = request[0].claimId;
        String claimF = System.Label.ARC_FieldForClaimCopy1 + System.Label.ARC_FieldForClaimCopy2;
        Claim originalClaim = Database.query('SELECT ' + claimF + ' FROM Claim WHERE Id = ' + '\''+ claimId + '\'' + 'LIMIT 1');
        System.debug(originalClaim);
        List<ARC_CopyClaimResult> result = createClaimRecords(originalClaim);
        return result;
    }

    public static List<ARC_CopyClaimResult> createClaimRecords(Claim originalClaim) {
        List<Claim> claimsToUpsert = new List<Claim>();
        List<ClaimCoveragePaymentDetail> itemsToInsert = new List<ClaimCoveragePaymentDetail>();
        List<ARC_Institutional_Claim_Code__c> instCodesToInsert = new List<ARC_Institutional_Claim_Code__c>();   
        
        // INSERT CLAIM
        Claim copyClm = originalClaim.clone(false, false, false, false);
        if(originalClaim.Name.contains('- C')){
            String name = copyClm.Name;
            String str = name.right(1); 
            Integer intVal = Integer.ValueOf( str ) + 1;
            name = name.removeEnd(str) + intVal;
            copyClm.Name = name;
            copyClm.SourceSystemIdentifier = name;
        }else{
            copyClm.Name = copyClm.Name + ' - C1';
            copyClm.SourceSystemIdentifier = copyClm.SourceSystemIdentifier + ' - C1';
        }
        copyClm.ARC_OriginalSMB__c = originalClaim.Id;
        copyClm.Status = 'Initial';
        copyClm.ARC_AuditorValidation__c = 'Pending';
        copyClm.ARC_CheckRun__c = null;
        copyClm.ARC_CheckNumber__c = null;
        copyClm.ARC_Copied__c = true;
        copyClm.Analyzed_By__c = UserInfo.getUserId();
        copyClm.De_Duplicate_Flag__c = true;
        claimsToUpsert.add(copyClm);       
        try {
            upsert claimsToUpsert;
        } catch (DmlException ex) {
            String errorMessage = ex.getMessage();
            
            ARC_CopyClaimResult result = new ARC_CopyClaimResult();
            if (errorMessage.toLowerCase().contains('duplicate') && errorMessage.toLowerCase().contains('sourcesystemidentifier')) {
                result.errorMessage = 'Duplicate SourceSystemIdentifier';
            } else {
                result.errorMessage = errorMessage;
            }
            return new List<ARC_CopyClaimResult>{result};
        } catch (Exception ex) {
            String errorMessage = ex.getMessage();
            ARC_CopyClaimResult result = new ARC_CopyClaimResult();
            result.errorMessage = errorMessage;
            return new List<ARC_CopyClaimResult>{result};
        }
          
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

        List<ARC_CopyClaimResult> result = new List<ARC_CopyClaimResult>{new ARC_CopyClaimResult()};
        result[0].copiedClaim = copyClm;
        return result;
        
    }  

    public class ARC_CopyClaimResult {
        @InvocableVariable
        public Claim copiedClaim;
        public String errorMessage;
    }

}