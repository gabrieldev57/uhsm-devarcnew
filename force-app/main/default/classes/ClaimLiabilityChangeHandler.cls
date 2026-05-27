public class ClaimLiabilityChangeHandler {
    
    // Valid statuses for liability
    private static final Set<String> VALID_STATUSES = new Set<String>{
        'AA Approved',
        'Manual Approved',
        'AA Denied',
        'Manual Denied',
        'Manual Pending',
        'Audit Pending'
    };
    
    /**
     * Check if a claim qualifies as liability
     */
    private static Boolean isLiability(Claim claim) {
        return VALID_STATUSES.contains(claim.Status)
            && claim.ARC_CheckRunApproval__c == 'Approved'
            && claim.HaxSMB__c == false
            && String.isBlank(claim.ARC_CheckRun__c)
            && claim.ARC_AuditorValidation__c == 'Approved';
    }
    
    /**
     * Prevent deletion of claims that are currently liability
     */
    public static void preventLiabilityDeletion(List<Claim> oldClaims) {
        for (Claim claim : oldClaims) {
            if (isLiability(claim)) {
                claim.addError('Cannot delete a claim that is currently counted as liability. ' +
                              'Please remove it from liability status first (e.g., add to a Check Run or change approval status).');
            }
        }
    }
    
    /**
     * Handle new claim records
     */
    public static void handleInsert(List<Claim> newClaims) {
        List<SMB_Liability_Change__c> changes = new List<SMB_Liability_Change__c>();
        
        for (Claim claim : newClaims) {
            if (isLiability(claim)) {
                changes.add(new SMB_Liability_Change__c(
                    Change_Type__c = 'Added',
                    Net_Paid_Amount__c = claim.ARC_TotalNetPaidAmount__c,
                    Shareable_Medical_Bill__c = claim.Id,
                    SMB_Name__c = claim.Name,
                    Notes__c = 'New claim added to liability'
                ));
            }
        }
        
        if (!changes.isEmpty()) {
            insert changes;
        }
    }
    
    /**
     * Handle updated claim records
     */
    public static void handleUpdate(List<Claim> newClaims, Map<Id, Claim> oldClaimsMap) {
        List<SMB_Liability_Change__c> changes = new List<SMB_Liability_Change__c>();
        
        for (Claim newClaim : newClaims) {
            Claim oldClaim = oldClaimsMap.get(newClaim.Id);
            
            Boolean wasLiability = isLiability(oldClaim);
            Boolean isNowLiability = isLiability(newClaim);
            
            // Scenario 1: Wasn't liability, now is (Added)
            if (!wasLiability && isNowLiability) {
                changes.add(new SMB_Liability_Change__c(
                    Change_Type__c = 'Added',
                    Net_Paid_Amount__c = newClaim.ARC_TotalNetPaidAmount__c,
                    Shareable_Medical_Bill__c = newClaim.Id,
                    SMB_Name__c = newClaim.Name,
                    Notes__c = 'Claim now meets liability criteria'
                ));
            }
            // Scenario 2: Was liability, no longer is
            else if (wasLiability && !isNowLiability) {
                String changeType;
                String notes;
                
                // Check if added to check run
                if (String.isNotBlank(newClaim.ARC_CheckRun__c) && String.isBlank(oldClaim.ARC_CheckRun__c)) {
                    changeType = 'Added to Check Run';
                    notes = 'Claim added to check run: ' + newClaim.ARC_CheckRun__c;
                } else {
                    changeType = 'Disapproved';
                    notes = buildDisapprovalReason(oldClaim, newClaim);
                }
                
                changes.add(new SMB_Liability_Change__c(
                    Change_Type__c = changeType,
                    Net_Paid_Amount__c = -oldClaim.ARC_TotalNetPaidAmount__c, // Negative to show reduction
                    Shareable_Medical_Bill__c = newClaim.Id,
                    SMB_Name__c = newClaim.Name,
                    Notes__c = notes
                    // User_Note__c will be populated by flow if required
                ));
            }
            // Scenario 3: Still liability, but amount changed (Adjusted)
            else if (wasLiability && isNowLiability && 
                     oldClaim.ARC_TotalNetPaidAmount__c != newClaim.ARC_TotalNetPaidAmount__c) {
                Decimal amountChange = newClaim.ARC_TotalNetPaidAmount__c - oldClaim.ARC_TotalNetPaidAmount__c;
                
                changes.add(new SMB_Liability_Change__c(
                    Change_Type__c = 'Adjusted',
                    Net_Paid_Amount__c = amountChange,
                    Shareable_Medical_Bill__c = newClaim.Id,
                    SMB_Name__c = newClaim.Name,
                    Notes__c = 'Amount changed from ' + oldClaim.ARC_TotalNetPaidAmount__c + ' to ' + newClaim.ARC_TotalNetPaidAmount__c
                    // User_Note__c will be populated by flow if required
                ));
            }
        }
        
        if (!changes.isEmpty()) {
            insert changes;
        }
    }
    
    /**
     * Handle undeleted claim records
     */
    public static void handleUndelete(List<Claim> newClaims) {
        List<SMB_Liability_Change__c> changes = new List<SMB_Liability_Change__c>();
        
        for (Claim claim : newClaims) {
            if (isLiability(claim)) {
                changes.add(new SMB_Liability_Change__c(
                    Change_Type__c = 'Added',
                    Net_Paid_Amount__c = claim.ARC_TotalNetPaidAmount__c,
                    Shareable_Medical_Bill__c = claim.Id,
                    SMB_Name__c = claim.Name,
                    Notes__c = 'Claim record restored from recycle bin'
                ));
            }
        }
        
        if (!changes.isEmpty()) {
            insert changes;
        }
    }
    
    /**
     * Build a detailed reason for why claim no longer qualifies
     */
    private static String buildDisapprovalReason(Claim oldClaim, Claim newClaim) {
        List<String> reasons = new List<String>();
        
        if (oldClaim.Status != newClaim.Status && !VALID_STATUSES.contains(newClaim.Status)) {
            reasons.add('Status changed from "' + oldClaim.Status + '" to "' + newClaim.Status + '"');
        }
        
        if (oldClaim.ARC_CheckRunApproval__c != newClaim.ARC_CheckRunApproval__c && newClaim.ARC_CheckRunApproval__c != 'Approved') {
            reasons.add('Check Run Approval changed from "' + oldClaim.ARC_CheckRunApproval__c + '" to "' + newClaim.ARC_CheckRunApproval__c + '"');
        }
        
        if (oldClaim.HaxSMB__c != newClaim.HaxSMB__c && newClaim.HaxSMB__c == true) {
            reasons.add('HaxSMB changed to True');
        }
        
        if (oldClaim.ARC_AuditorValidation__c != newClaim.ARC_AuditorValidation__c && newClaim.ARC_AuditorValidation__c != 'Approved') {
            reasons.add('Auditor Validation changed from "' + oldClaim.ARC_AuditorValidation__c + '" to "' + newClaim.ARC_AuditorValidation__c + '"');
        }
        
        if (reasons.isEmpty()) {
            return 'Claim no longer meets liability criteria';
        }
        
        return 'Claim no longer meets criteria: ' + String.join(reasons, '; ');
    }
}