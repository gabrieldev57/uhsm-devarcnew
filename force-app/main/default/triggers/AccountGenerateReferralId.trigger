trigger AccountGenerateReferralId on Account (before insert) {
    
    if (Trigger.isBefore && Trigger.isInsert) {
        // Get the record type Id for ARC_IFPPersonAccount
      	Id targetRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        	.get('ARC_IFPPersonAccount').getRecordTypeId();
        
        List<Account> toProcess = new List<Account>();

        for (Account acc : Trigger.new) {
            if (acc.RecordTypeId == targetRecordTypeId) {
                toProcess.add(acc);
            }
        }
            
     if (!toProcess.isEmpty()) {
            AccountGenerateReferralIdController.assignReferralIds(toProcess);
        }
    }
}