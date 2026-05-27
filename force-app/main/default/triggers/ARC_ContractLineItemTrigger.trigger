trigger ARC_ContractLineItemTrigger on vlocity_ins__ContractLineItem__c (after delete) {
	if (Trigger.isAfter && Trigger.isDelete) {
		ARC_ContractLineItemTriggerHandler.handleAfterDelete(Trigger.old);
	}
}