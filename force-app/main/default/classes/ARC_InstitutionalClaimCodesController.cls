public without sharing class ARC_InstitutionalClaimCodesController {

      @AuraEnabled 
      public static Claim getInstitutionalCodes(String claimId) {
         System.debug('claimId: '+ claimId);
         //List<RecordType> institutionalRT = [SELECT Id, Name, DeveloperName, SobjectType, NamespacePrefix FROM RecordType WHERE SobjectType = 'Claim' AND Name Like 'Institutional%'];
         Claim cData = [SELECT Id,ARC_Submitted_DRG_Code__c, ARC_Calculated_DRG_Code__c, ARC_PPS_Code__c, ARC_AdmitDX_Code__c, ARC_Principal_Procedure__c,ARC_Principal_Procedure_Date__c, 
                     (SELECT Id, ARC_Vale_Codes__c, ARC_Patient_DX__c, ARC_POA__c, ARC_Other_Procedure_Code__r.Name, ARC_Occurrence_Span_Code__c, ARC_Occurrence_Code__c, ARC_ICD_DX__r.Name, ARC_ICD_DX__c, ARC_ECode__r.Name,
                      ARC_Date__c, ARC_Date_Through__c, ARC_Date_From__c, ARC_ConditionCode__r.Name , ARC_Amount__c, Name FROM Institutional_Claim_Codes__r ORDER BY CreatedDate ASC) RecordTypeId FROM CLaim WHERE Id =: claimId Limit 1];
         return cData;
     }

    @AuraEnabled
    public static List<RecordType> getRecordTypeInstClaimCodes() {
        List<RecordType> institutionalClaimCodeRT = [SELECT Id, SobjectType, DeveloperName FROM RecordType Where SobjectType = 'ARC_Institutional_Claim_Code__c'];
        return institutionalClaimCodeRT;
    }

    @AuraEnabled
    public static Boolean deleteClaimCode(String claimCodeId){
        try{
            ARC_Institutional_Claim_Code__c claimCode = [SELECT Id FROM ARC_Institutional_Claim_Code__c WHERE Id = :claimCodeId];
            delete claimCode;
            return true;
        }catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        return false;
    }
}