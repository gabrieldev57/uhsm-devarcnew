trigger ARC_ClaimTriggers on Claim (before insert, before update, after insert, after update) {
    
    if (Label.Bypass_Claims_Trigger == 'true'){
    	return; // Exit the trigger if the label indicates it is disabled 
	}
    
    if(Trigger.isBefore){
        // Run JSON parsing only when needed
        List<Claim> claimsToParse = new List<Claim>();
        for (Claim cl : Trigger.new) {
            if (Trigger.isInsert) {
                claimsToParse.add(cl);
            } else {
                Claim oldCl = Trigger.oldMap.get(cl.Id);
                if (cl.ARC_SubmitterJSON__c != oldCl.ARC_SubmitterJSON__c) {
                    claimsToParse.add(cl);
                }
            }
        }
        if (!claimsToParse.isEmpty()) {
            ARC_ClaimTriggersHandler.extractClaimSubmitter(claimsToParse);
        }
        
        if (Trigger.isInsert) {
            ARC_ClaimTriggersHandler.updateNameManualSMB(null, Trigger.new); 
        }
        if(Trigger.isUpdate){
            // Collect all CheckRun IDs from all claims in the batch
            Set<Id> checkRunIds = new Set<Id>();
            for (Claim claim : Trigger.newMap.values()) {
                if (claim.ARC_CheckRun__c != null) {
                    checkRunIds.add(claim.ARC_CheckRun__c);
                }
            }
            
            // Single query for all CheckRuns in the batch
            Map<Id, String> checkRunProcessors = new Map<Id, String>();
            if (!checkRunIds.isEmpty()) {
                for (ARC_CheckRun__c cr : [SELECT Id, Processor__c FROM ARC_CheckRun__c WHERE Id IN :checkRunIds]) {
                    checkRunProcessors.put(cr.Id, cr.Processor__c);
                }
            }
            
            // Helper method to filter out Optum claims
            List<Map<Id, Claim>> filteredMaps = ARC_ClaimTriggersHandler.filterZelisClaims(Trigger.oldMap, Trigger.newMap, checkRunProcessors);
            Map<Id, Claim> zelisOldMap = filteredMaps[0];
            Map<Id, Claim> zelisNewMap = filteredMaps[1];
            
            // Always run these methods (they're not Zelis-specific)
            ARC_ClaimTriggersHandler.preventCloseIfunpaidItems(Trigger.oldMap, Trigger.newMap);
            ARC_ClaimTriggersHandler.ownerControl(Trigger.oldMap, Trigger.newMap);
            ARC_ClaimTriggersHandler.updateNameManualSMB(Trigger.old, Trigger.new); 
            ARC_ClaimTriggersHandler.refundCalculation(Trigger.oldMap, Trigger.newMap);
            
            // Only run Zelis-specific methods with filtered maps
            if (!zelisNewMap.isEmpty()) {
                ARC_ClaimTriggersHandler.populateCheckNumber(zelisOldMap, zelisNewMap);
            }
        }
    }    

    if (Trigger.isAfter) {
        // EXECUTE UPDATE ONCE THE CLAIM IS FULL MAPPED
        if (Trigger.isUpdate) {
            ARC_ClaimTriggersHandler.sumNetPaidToCheckrun(Trigger.new, Trigger.old);
            ARC_ClaimTriggersHandler.quickPayAAUpdateSMB(Trigger.oldMap, Trigger.newMap);
        }
        if (Trigger.isInsert) {
            ARC_ClaimTriggersHandler.clmCovForClmWithoutInput(Trigger.new); 
        }
    }
}