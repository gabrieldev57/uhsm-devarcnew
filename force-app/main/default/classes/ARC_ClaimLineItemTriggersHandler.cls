public with sharing class ARC_ClaimLineItemTriggersHandler {
    
    public static void updateChxInClaim(List<ClaimCoveragePaymentDetail> claimItemList) {
        Set<Id> claimIds = new Set<Id>();
        List<Claim> claimsToUpdate = new List<Claim>();
        for (ClaimCoveragePaymentDetail item : claimItemList) claimIds.add(item.ARC_Claim__c);
        List <ClaimCoveragePaymentDetail> items = [SELECT Name, Id, Status, ARC_Claim__c FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c IN: claimIds LIMIT 1000];

        // CREATE MAP WITH CLAIM IDS - BOOLEAN IF THE ITEMS ARE ALL APPROVED/DENIED
        Map<Id, Map<String, Boolean>> claimId_itemStatus = new Map<Id, Map<String, Boolean>>();
        for (Id claimId : claimIds){
            Map<String, Boolean> mapBoolean = new Map<String, Boolean>();
            mapBoolean.put('allApproved', true);
            
            claimId_itemStatus.put(claimId, mapBoolean);
        }
        
        // IF ONE OF THE ITEMS ARE NOT DENIED, THE MAP WILL BE: allDenied = false AND VICEVERSA
        Map<Id, Integer> claimId_numOfItems = new Map<Id, Integer>();
        for (ClaimCoveragePaymentDetail item : items) {
            Map<String, Boolean> claimMap = (Map<String, Boolean>)claimId_itemStatus.get(item.ARC_Claim__c);
            Integer numOfItems = (Integer)claimId_numOfItems.get(item.ARC_Claim__c) != null ? (Integer)claimId_numOfItems.get(item.ARC_Claim__c) + 1 : 1; 

            if (item.Status != 'Capitated') claimMap.put('allApproved', false);
            claimId_numOfItems.put(item.ARC_Claim__c, numOfItems);
        }

        // UPDATE THE CHECKBOX ON THE CLAIM
        for (Id claimId : claimId_itemStatus.keySet()) {
            Map<String, Boolean> claimMap = (Map<String, Boolean>)claimId_itemStatus.get(claimId);
            
            Claim clm = new Claim();
            clm.Id = claimId;
            clm.ARC_ItemsApproved__c = Boolean.valueOf(claimMap.get('allApproved'));
            clm.ARC_ItemsCounter__c = (Integer)claimId_numOfItems.get(claimId);
            claimsToUpdate.add(clm);
        }

        update claimsToUpdate;
    }

    public static Set<Id> getClaimsToUpdate(Map<Id, ClaimCoveragePaymentDetail> oldItems, Map<Id, ClaimCoveragePaymentDetail> newItems){
        Set<Id> clmIds = new Set<Id>();
        Set<Id> clmIdsToDelete = new Set<Id>();
        List<ClaimCoveragePaymentDetail> itemToDelete = new List<ClaimCoveragePaymentDetail>();

        if(oldItems == null && newItems != null) { // INSERT METHOD
            for (String itemId : newItems.keySet()) {
                if(newItems.get(itemId).ARC_Claim__c != null) clmIds.add(newItems.get(itemId).ARC_Claim__c);
            }
        }else if(oldItems != null && newItems != null) { // UPDATE METHOD
            for (String itemId : newItems.keySet()) {
                if(
                    newItems.get(itemId).ClaimedAmount != oldItems.get(itemId).ClaimedAmount ||
                    newItems.get(itemId).ARC_Pre_Existing_Condition__c != oldItems.get(itemId).ARC_Pre_Existing_Condition__c ||
                    newItems.get(itemId).AdjustedAmount != oldItems.get(itemId).AdjustedAmount ||
                    newItems.get(itemId).ARC_Allowed__c != oldItems.get(itemId).ARC_Allowed__c ||
                    newItems.get(itemId).ARC_Coinsurance__c != oldItems.get(itemId).ARC_Coinsurance__c ||
                    newItems.get(itemId).ARC_Copay__c != oldItems.get(itemId).ARC_Copay__c ||
                    newItems.get(itemId).ARC_Deductible__c != oldItems.get(itemId).ARC_Deductible__c ||
                    newItems.get(itemId).ARC_MBRLiability__c != oldItems.get(itemId).ARC_MBRLiability__c ||
                    newItems.get(itemId).ARC_PrimaryPaid__c != oldItems.get(itemId).ARC_PrimaryPaid__c ||
                    newItems.get(itemId).ARC_Tobacco__c != oldItems.get(itemId).ARC_Tobacco__c ||
                    newItems.get(itemId).ARC_MaximumTypeAmount__c != oldItems.get(itemId).ARC_MaximumTypeAmount__c ||
                    (newItems.get(itemId).Status == 'Denied' && oldItems.get(itemId).Status != 'Denied') ||
                    (newItems.get(itemId).Status != 'Denied' && oldItems.get(itemId).Status == 'Denied')
                ){
                    if(newItems.get(itemId).ARC_Claim__c != null) clmIds.add(newItems.get(itemId).ARC_Claim__c);
                }
            }
        }else if(oldItems != null && newItems == null) { // DELETE METHOD
            for (String itemId : oldItems.keySet()) {
                if(oldItems.get(itemId).ARC_Claim__c != null){
                    clmIds.add(oldItems.get(itemId).ARC_Claim__c);
                }
            }
        }
        return clmIds;
    }
    
    public static void recalculateTotals(Set<Id> clmIds){
        // NEW OR MODIFIED ITEM
        if(clmIds.size() > 0) {
            List<Claim> affectedClaims = [SELECT Id, Status, ARC_ClaimTotalAmount__c, ARC_Total_PreExistingConditions__c, ARC_TotalAdjustedAmount__c, ARC_TotalAllowedAmount__c, ARC_TotalCoinsuranceAmount__c, ARC_TotalCopayAmount__c, ARC_TotalDeductibleAmount__c, ARC_TotalMBRLiabilityAmount__c, ARC_TotalPrimaryPaidAmount__c, ARC_TotalTobacco__c, ARC_TotalNetPaidAmount__c, ARC_TotalPatientResponsibilityAmount__c, ARC_OriginalSMB__c, ARC_OriginalSMB__r.Status, ARC_OriginalSMB__r.ARC_TotalNetPaidAmount__c, ARC_Refund__c, ARC_RefundAmount__c, (SELECT Id, ClaimedAmount, ARC_Pre_Existing_Condition__c, AdjustedAmount, ARC_Allowed__c, ARC_Coinsurance__c, ARC_Copay__c, ARC_Deductible__c, ARC_MBRLiability__c, ARC_Tobacco__c, ARC_PrimaryPaid__c, ARC_NetPaid__c, ARC_PatientResp__c FROM Claim_Coverage_Payment_Details__r) FROM Claim WHERE Id IN: clmIds LIMIT 5000];

            for (Claim clm : affectedClaims) {
                Double totalAmount = 0;
                Double totalPreEx = 0;
                Double totalAdjust = 0;
                Double totalAllow = 0;
                Double totalCoinsu = 0;
                Double totalCopay = 0;
                Double totalDeduc = 0;
                Double totalMBR = 0;
                Double totalPrimaryPaid = 0;
                Double totalTobacco = 0;
                Double totalNetPaid = 0;
                Double totalPatResp = 0;
                
                for (ClaimCoveragePaymentDetail item : clm.Claim_Coverage_Payment_Details__r) {
                    totalAmount += item.ClaimedAmount != null ? item.ClaimedAmount : 0;
                    totalPreEx += item.ARC_Pre_Existing_Condition__c != null ? item.ARC_Pre_Existing_Condition__c : 0;
                    totalAdjust += item.AdjustedAmount != null ? item.AdjustedAmount : 0;
                    totalAllow += item.ARC_Allowed__c != null ? item.ARC_Allowed__c : 0;
                    totalMBR += item.ARC_MBRLiability__c != null ? item.ARC_MBRLiability__c : 0;
                    totalPrimaryPaid += item.ARC_PrimaryPaid__c != null ? item.ARC_PrimaryPaid__c : 0;
                    totalTobacco += item.ARC_Tobacco__c != null ? item.ARC_Tobacco__c : 0;
                    totalNetPaid += item.ARC_NetPaid__c != null ? item.ARC_NetPaid__c : 0;
                    if(clm.Status != 'Adjusted'){ 
                        totalDeduc += item.ARC_Deductible__c != null ? item.ARC_Deductible__c : 0;
                        totalCopay += item.ARC_Copay__c != null ? item.ARC_Copay__c : 0;
                        totalCoinsu += item.ARC_Coinsurance__c != null ? item.ARC_Coinsurance__c : 0;
                        totalPatResp += item.ARC_PatientResp__c != null ? item.ARC_PatientResp__c : 0;
                    }
                } 

                clm.ARC_ClaimTotalAmount__c = totalAmount;
                clm.ARC_Total_PreExistingConditions__c = totalPreEx;
                clm.ARC_TotalAdjustedAmount__c = totalAdjust;
                clm.ARC_TotalAllowedAmount__c = totalAllow;
                clm.ARC_TotalCoinsuranceAmount__c = totalCoinsu;
                clm.ARC_TotalCopayAmount__c = totalCopay;
                clm.ARC_TotalDeductibleAmount__c = totalDeduc;
                clm.ARC_TotalMBRLiabilityAmount__c = totalMBR;
                clm.ARC_TotalPrimaryPaidAmount__c = totalPrimaryPaid;
                clm.ARC_TotalTobacco__c = totalTobacco;
                clm.ARC_TotalPatientResponsibilityAmount__c = totalPatResp;
                clm.ARC_TotalNetPaidAmount__c = totalNetPaid;

                // NET PAID VALIDATIONS
                if(clm.ARC_OriginalSMB__c != null && clm.ARC_OriginalSMB__r.Status == 'Adjusted'){
                    clm.ARC_TotalNetPaidAmount__c -= clm.ARC_OriginalSMB__r.ARC_TotalNetPaidAmount__c;
                }
                if(clm.ARC_Refund__c == true && clm.ARC_RefundAmount__c != null) {
                    clm.ARC_TotalNetPaidAmount__c -= clm.ARC_RefundAmount__c;
                }
            }

            update affectedClaims;
        }
    }
}