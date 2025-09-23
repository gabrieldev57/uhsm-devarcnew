trigger ARC_ClaimLineItemTriggers on ClaimCoveragePaymentDetail (after insert, after update, after delete, before insert) {

    if (Trigger.isAfter) {
        if(Trigger.isInsert) {
            Set<Id> clmsToUpdate = ARC_ClaimLineItemTriggersHandler.getClaimsToUpdate(null, Trigger.newMap);
            ARC_ClaimLineItemTriggersHandler.recalculateTotals(clmsToUpdate);
        }
        if(Trigger.isUpdate) {
            Set<Id> clmsToUpdate = ARC_ClaimLineItemTriggersHandler.getClaimsToUpdate(Trigger.oldMap, Trigger.newMap);
            ARC_ClaimLineItemTriggersHandler.recalculateTotals(clmsToUpdate);
        }
        if (Trigger.isInsert || Trigger.isUpdate) {
            ARC_ClaimLineItemTriggersHandler.updateChxInClaim(Trigger.new);
        }

        if (Trigger.isDelete) {
            Boolean hasErrors = false;

            for (ClaimCoveragePaymentDetail smbItem : Trigger.old) {
                if (smbItem.Status == 'Paid') {
                    smbItem.addError('Cannot delete an SMB Item with a status of Paid.');
                    hasErrors = true; // Flag that there is an error
                }
            }

            // Only proceed if there were no errors
            if (!hasErrors) {
                Set<Id> clmsToUpdate = ARC_ClaimLineItemTriggersHandler.getClaimsToUpdate(Trigger.oldMap, null); // REMOVE VALUE FROM CLAIM TOTALS
                ARC_ClaimLineItemTriggersHandler.recalculateTotals(clmsToUpdate);
            }
        }
    }
}