public with sharing class ARC_VlocityTrackingEntryHandler {
    public static void updateLeadSource(List<vlocity_ins__VlocityTrackingEntry__c> trackingEntries) {

        for (vlocity_ins__VlocityTrackingEntry__c trackingEntry : trackingEntries) {
            if (trackingEntry.vlocity_ins__Data__c != null && trackingEntry.vlocity_ins__Data__c != '') {
                Map<String,Object> trackingEntryData = (Map<String,Object>)JSON.deserializeUntyped(trackingEntry.vlocity_ins__Data__c);
                if (trackingEntryData.get('ARC_LeadSource__c') != null && trackingEntryData.get('ARC_LeadSource__c') != '') {
                    trackingEntry.ARC_LeadSource__c = (String)trackingEntryData.get('ARC_LeadSource__c');
                }
            }
        }
    }
}