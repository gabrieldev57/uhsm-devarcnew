trigger ARC_CheckRunTrigger on ARC_CheckRun__c (after update, before insert, before update) {

    if (trigger.isInsert && trigger.isBefore) {
        ARC_CheckRunTriggerHandler.populateScheduleClosingDate(Trigger.new);
    }

    if (trigger.isUpdate && trigger.isBefore) {
        ARC_CheckRunTriggerHandler.recalculateTotal(Trigger.oldMap, Trigger.newMap);
    }

    if (trigger.isUpdate && trigger.isAfter) {
        Map<Id, ARC_CheckRun__c> newMap = Trigger.newMap;
        Map<Id, ARC_CheckRun__c> oldMap = Trigger.oldMap;

        // Split records by processor
        Map<Id, ARC_CheckRun__c> zelisNewMap = new Map<Id, ARC_CheckRun__c>();
        Map<Id, ARC_CheckRun__c> zelisOldMap = new Map<Id, ARC_CheckRun__c>();

        Map<Id, ARC_CheckRun__c> optumNewMap = new Map<Id, ARC_CheckRun__c>();
        Map<Id, ARC_CheckRun__c> optumOldMap = new Map<Id, ARC_CheckRun__c>();

        // Add relevant check runs to each map
        for (Id id : newMap.keySet()) {
            String processor = newMap.get(id).Processor__c;
            // If processor field is blank, continue to default to Zelis
            if (processor == 'Zelis' || String.isBlank(processor)) {
                zelisNewMap.put(id, newMap.get(id));
                zelisOldMap.put(id, oldMap.get(id));
            } else if (processor == 'Optum') {
                optumNewMap.put(id, newMap.get(id));
                optumOldMap.put(id, oldMap.get(id));
            }
        }

        // Only run Zelis logic if applicable
        if (!zelisNewMap.isEmpty()) {
            ARC_CheckRunTriggerHandler.sendClaimsToZelis(zelisOldMap, zelisNewMap); 
            ARC_CheckRunTriggerHandler.sendSMBPaidReportEmail(zelisOldMap, zelisNewMap);
        }

    }
}