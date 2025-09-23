trigger ARC_AgeUpCalculationEventTrigger on Age_Up_Calculation__e (after insert) {
    // Process each platform event message
    for(Age_Up_Calculation__e event : Trigger.new) {
        // Get the comma-separated string of contract IDs
        String contractIdsString = event.ARC_ContractIds__c;
        
        // Only proceed if we have contract IDs
        if(String.isNotBlank(contractIdsString)) {
            // Split the string into a list of ID strings and convert to Set<Id>
            Set<Id> contractIds = new Set<Id>();
            for(String idStr : contractIdsString.split(',')) {
                // Add each ID to the set, trimming any whitespace
                contractIds.add(Id.valueOf(idStr.trim()));
            }
            
            // Call the age up calculation method with the set of IDs
            if(!contractIds.isEmpty()) {
                ARC_AgeUp.calculateAgeUp(contractIds);
            }
        }
    }
}