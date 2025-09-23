trigger AccountGenerateReferralId on Account (before insert, before update) {
    
    // Get the record type Id for ARC_IFPPersonAccount
    Id targetRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('ARC_IFPPersonAccount').getRecordTypeId();
    
    if (Trigger.isBefore && Trigger.isInsert) {
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
    
    if (Trigger.isBefore && Trigger.isUpdate) {
        List<Account> toProcess = new List<Account>();
        for (Account acc : Trigger.new) {
            Account oldAcc = Trigger.oldMap.get(acc.Id);
            
            // Check if: 1) correct record type, 2) IsActive changed to true, 3) ReferralId is blank
            if (acc.RecordTypeId == targetRecordTypeId && 
                acc.IsActive == true && 
                String.isBlank(acc.Referral_ID__c)) {
                
                toProcess.add(acc);
            }
        }
        
        if (!toProcess.isEmpty()) {
            AccountGenerateReferralIdController.assignReferralIds(toProcess);
        }
    }
}