public with sharing class ARC_ShowClaimsPerPolicyController {

    @AuraEnabled(cacheable=true)
    public static List<Claim> getData(String recordId) {
        String sObjName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
        List<Claim> output = new List<Claim>();

        // if(sObjName == 'vlocity_ins__GroupCensusMember__c'){
        //     output = [SELECT Id, PolicyNumberId, PolicyNumber.Name, PolicyNumber.ARC_Contract__r.ARC_ContractReason__c,Name, Status, ARC_DOSFrom__c, ARC_PlaceOfService__c, ARC_Vendor__c, ARC_Vendor__r.Name, ARC_OriginalReceivedDate__c, ARC_CheckRun__c, ARC_CheckRun__r.Name, ARC_TotalDeductibleAmount__c, ARC_ClaimTotalAmount__c, ARC_TotalCopayAmount__c, ARC_TotalNetPaidAmount__c, ARC_MemberBenefitPlan__c, ARC_TotalMBRLiabilityAmount__c, ARC_TotalAllowedAmount__c FROM Claim WHERE ARC_PatientCensusMember__c =: recordId ORDER BY PolicyNumber.ARC_EffectiveDate__c ASC LIMIT 5000];
        // }else
        if(sObjName == 'Account'){
			output = [SELECT Id, PolicyNumberId, PolicyNumber.Name, PolicyNumber.ARC_Contract__r.ARC_ContractReason__c,Name, Status, ARC_DOSFrom__c, ARC_PlaceOfService__c, ARC_Vendor__c, ARC_Vendor__r.Name, ARC_OriginalReceivedDate__c, ARC_CheckRun__c, ARC_CheckRun__r.Name, ARC_TotalDeductibleAmount__c, ARC_ClaimTotalAmount__c, ARC_TotalCopayAmount__c, ARC_TotalNetPaidAmount__c, ARC_MemberBenefitPlan__c, ARC_TotalMBRLiabilityAmount__c, ARC_TotalAllowedAmount__c, ARC_Total_PreExistingConditions__c, HaxSMB__c FROM Claim WHERE ARC_MemberContact__r.AccountId =: recordId ORDER BY PolicyNumber.ARC_EffectiveDate__c ASC LIMIT 5000];
        }

        return output;
    }
}