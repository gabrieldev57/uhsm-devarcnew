public with sharing class ARC_VoidClaim {
    public class VoidClaim {
        @InvocableVariable(label='Claim Id' required=true)
        public String claimId;
        @InvocableVariable(label='Remove From Checkrun' required=false)
        public Boolean removed;
        @InvocableVariable(label='Void Reason' required=false)
        public String voidReason;
    }

    public class VoidClaimResponse {
        @InvocableVariable
        public String voidResponse;
    }

    @InvocableMethod(label='Void SMB' description='Execute logic to void an SMB')
    public static List<VoidClaimResponse> VoidClaim(List<VoidClaim> input) {
        // Claim clm = [SELECT Id, Status, ARC_VRHelper__c (SELECT Id, Status FROM Claim_Coverage_Payment_Details__r) FROM Claim WHERE Id =: input[0].claimId];
        Claim clm = [SELECT Id, Status, ARC_DOSFrom__c, ARC_DOSTo__c, ARC_VRHelper__c, PolicyNumberId, ARC_MemberContact__c, ARC_MemberBenefitPlan__c, 
                        (SELECT Id, Status, ARC_Deductible__c,
                            ARC_Pre_Existing_Condition__c,
                            ARC_Tobacco__c,
                            ARC_Coinsurance__c,
                            ARC_Allowed__c,
                            ARC_Medical_Visit_Reason__c
                        FROM Claim_Coverage_Payment_Details__r) 
                    FROM Claim
                    WHERE Id =: input[0].claimId];
        vlocity_ins__VlocityCode__c[] denyCode = [SELECT Id FROM vlocity_ins__VlocityCode__c WHERE Name = 'V0001' AND RecordType.Name = 'RARC' AND ARC_Status__c = 'Denied']; 
        List<ARC_ClaimReasonCode__c> itemCodes = new List<ARC_ClaimReasonCode__c>();

        VoidClaimResponse res = new VoidClaimResponse();
        res.voidResponse = 'The denied code: V0001 it is not on the system.';
        if (denyCode.size() == 0) return new List<VoidClaimResponse>{res};
        Savepoint sp = Database.setSavepoint();

        // UNLOCK THE CLAIM
        clm.Status = 'Initial';
        clm.ARC_VRHelper__c = !clm.ARC_VRHelper__c;
        if (input[0].removed == true) clm.ARC_Checkrun__c = null;
        if (input[0].voidReason != null) clm.ARC_VoidReason__c = input[0].voidReason;
        update clm;

        // RESET ITEMS AND AGGREGATORS - 1ST JANUARY
        Boolean reseted = ARC_CoveragePaymentsTableController.resetItems(clm, 'void', new Set<Id>()); 
        System.debug(clm.Claim_Coverage_Payment_Details__r[0].Id);
        System.debug(clm.Claim_Coverage_Payment_Details__r[0].ARC_Deductible__c);
        System.debug(reseted);
        if (!reseted) {
            Database.rollback(sp);
            VoidClaimResponse res2 = new VoidClaimResponse();
            res2.voidResponse = 'The Line items could not be reseted';
            return new List<VoidClaimResponse>{res2};
        }

        List<ClaimCoveragePaymentDetail> claimItemsUpdated = [SELECT Id, Status,ARC_Deductible__c, ARC_Claim__c FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c=: clm.Id];
        // DENY CLAIM AND ITEMS
        for (ClaimCoveragePaymentDetail item : claimItemsUpdated) {
            item.Status = 'Denied';
            system.debug(item.ARC_Deductible__c);

            ARC_ClaimReasonCode__c itemCode = new ARC_ClaimReasonCode__c();
            itemCode.ARC_ReasonCode__c = denyCode[0].Id;
            itemCode.ARC_ClaimCoveragePaymentDetail__c = item.Id;
            itemCodes.add(itemCode);
        }
        insert itemCodes;
        update claimItemsUpdated;

        // CLOSE THE CLAIM AGAIN
        clm.Status = 'Voided';
        update clm;
        VoidClaimResponse res3 = new VoidClaimResponse();
        res3.voidResponse = 'The SMB has been Voided successfully!';
        return new List<VoidClaimResponse>{res3};
    }
}