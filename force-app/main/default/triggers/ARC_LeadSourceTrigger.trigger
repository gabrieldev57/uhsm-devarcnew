trigger ARC_LeadSourceTrigger on Lead_Source__c (after insert, before insert) {

    if (Trigger.isAfter && Trigger.isInsert) {
            ARC_LeadSourceTriggerHandler.leadToSelfEnrollingStatus(Trigger.new);

    }
    
	if (Trigger.isBefore) {
        	ARC_LeadSourceTriggerHandler.parseMarketingURL(Trigger.New);
    }

}