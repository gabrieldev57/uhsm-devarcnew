public with sharing class ARC_CensusMemberHandler {

	// public static void SendEmailNotification(Map<Id,vlocity_ins__GroupCensusMember__c> oldValues,List<vlocity_ins__GroupCensusMember__c> newValues) {

    //     Set<Id> censusMemberIds = new Set<Id>();
    //     for (vlocity_ins__GroupCensusMember__c newV : newValues) {
    //         if( newV.vlocity_ins__FirstName__c != oldValues.get(newV.Id).vlocity_ins__FirstName__c && String.isNotBlank(String.valueOf(oldValues.get(newV.Id).vlocity_ins__FirstName__c))||
    //             newV.vlocity_ins__LastName__c != oldValues.get(newV.Id).vlocity_ins__LastName__c && String.isNotBlank(String.valueOf(oldValues.get(newV.Id).vlocity_ins__LastName__c))||
    //             newV.ARC_Phone__c != oldValues.get(newV.Id).ARC_Phone__c && String.isNotBlank(String.valueOf(oldValues.get(newV.Id).ARC_Phone__c))||
    //             newV.ARC_PhysicalAddressCity__c != oldValues.get(newV.Id).ARC_PhysicalAddressCity__c && String.isNotBlank(String.valueOf(oldValues.get(newV.Id).ARC_PhysicalAddressCity__c))||
    //             newV.ARC_PhysicalAddressStreet__c != oldValues.get(newV.Id).ARC_PhysicalAddressStreet__c && String.isNotBlank(String.valueOf(oldValues.get(newV.Id).ARC_PhysicalAddressStreet__c))||
    //             newV.ARC_PhysicalAddressState__c != oldValues.get(newV.Id).ARC_PhysicalAddressState__c && String.isNotBlank(String.valueOf(oldValues.get(newV.Id).ARC_PhysicalAddressState__c))||
    //             newV.ARC_PhysicalAddressZipCode__c != oldValues.get(newV.Id).ARC_PhysicalAddressZipCode__c && String.isNotBlank(String.valueOf(oldValues.get(newV.Id).ARC_PhysicalAddressZipCode__c))
    //         ){
    //             censusMemberIds.add(newV.Id);
    //         }
    //     }

    //     if (!censusMemberIds.isEmpty()) {
	// 		Map<String, Object> inputMap = new Map<String, Object>{'censusMemberIds' => censusMemberIds};
	// 		Map<String, Object> outMap = new Map<String, Object>();
	// 		Map<String, Object> options = new Map<String, Object>();
	// 		System.debug(censusMemberIds);
	// 		ARC_Emails.invokeMethod('email_7', inputMap, outMap, options);
	// 	}


    // }

    public static void updateOldSSN(Map<Id,vlocity_ins__GroupCensusMember__c> oldValues, List<vlocity_ins__GroupCensusMember__c> newList, Boolean isInsert) {
        for ( vlocity_ins__GroupCensusMember__c m : newList ) {
            if ( m.ARC_OldSSN__c == null && ( isInsert || oldValues.get(m.Id).vlocity_ins__SocialSecurityNumber__c != m.vlocity_ins__SocialSecurityNumber__c ) ) {
                m.ARC_OldSSN__c = m.vlocity_ins__SocialSecurityNumber__c;
            }
        }
    }
}