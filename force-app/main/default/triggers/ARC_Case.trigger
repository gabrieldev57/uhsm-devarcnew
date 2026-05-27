trigger ARC_Case on Case (before update, after update, before insert, after insert) {

    if ( Trigger.isBefore && Trigger.isUpdate ) {
        ARC_CaseHandler.preventUpdateDescription(Trigger.oldMap, Trigger.newMap); 
    }

    if ( Trigger.isAfter && Trigger.isUpdate ) {
        ARC_DocuSignApi.handleDocuSignUpdates(Trigger.oldMap, Trigger.newMap); 

        // QLE — only for Case Record Type Name = "Qualify Event"
        Schema.RecordTypeInfo qleRtInfo = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Qualify Event');
        Id qleRecordTypeId = (qleRtInfo != null) ? qleRtInfo.getRecordTypeId() : null;

        if (qleRecordTypeId != null) {
            for (Case currentCase : Trigger.new) {
                Case oldCase = Trigger.oldMap.get(currentCase.Id);

                if (currentCase.RecordTypeId == qleRecordTypeId
                    && currentCase.Status == 'Closed Approved'
                    && oldCase.Status != 'Closed Approved') {
                    ARC_SGQLEBaseService.executeAsync(currentCase.Id, oldCase.Status);
                }
            }
        }
    }    

    if ( Trigger.isBefore && Trigger.isInsert ) {
    	List<Case> casesList = Trigger.Old;
       System.debug(casesList);
    }
    
    if ( Trigger.isAfter && Trigger.isInsert ) {
    	ARC_CaseHandler.encryptCaseIds(Trigger.new);
    }
}