trigger ARC_Case on Case (before update, after update, before insert, after insert) {

    if ( Trigger.isBefore && Trigger.isUpdate ) {
        ARC_CaseHandler.preventUpdateDescription(Trigger.oldMap, Trigger.newMap); 
    }

    if ( Trigger.isAfter && Trigger.isUpdate ) {
        ARC_DocuSignApi.handleDocuSignUpdates(Trigger.oldMap, Trigger.newMap); 
    }    
    if ( Trigger.isBefore && Trigger.isInsert ) {
    	List<Case> casesList = Trigger.Old;
       System.debug(casesList);
    }
    if ( Trigger.isAfter && Trigger.isInsert ) {
    	ARC_CaseHandler.encryptCaseIds(Trigger.new);
    }


}