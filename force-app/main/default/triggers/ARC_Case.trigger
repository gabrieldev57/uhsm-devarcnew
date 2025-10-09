trigger ARC_Case on Case (after update, before insert, after insert) {
    if ( Trigger.isAfter && Trigger.isUpdate ) {
        ARC_DocuSignApi.handleDocuSignUpdates(Trigger.oldMap, Trigger.newMap); 
        //UHSM-2331: Onboarding Case owner change from CC to another CC: 
        CaseOwnerChangeHandlerCC.updateCaseOwnerToAnotherCC(Trigger.oldMap, Trigger.newMap); 
        CaseOwnerChangeHandlerCC.updateAccountOwnershipWhenUWCaseIsApproved(Trigger.oldMap, Trigger.newMap); 
    }    
    if ( Trigger.isBefore && Trigger.isInsert ) {
    	List<Case> casesList = Trigger.Old;
       System.debug(casesList);
    }
    if ( Trigger.isAfter && Trigger.isInsert ) {
    	ARC_CaseHandler.encryptCaseIds(Trigger.new);
    }
}