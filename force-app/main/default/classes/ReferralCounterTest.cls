@isTest
private class ReferralCounterTest {

    @isTest
    static void testSchedulableJobRun(){
        User u = [SELECT Id FROM User WHERE Profile.Name = 'Standard User' LIMIT 1]; 

        RecordType groupAccountRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Group'];
        RecordType personAccRT = [SELECT Id FROM RecordType WHERE (Name = 'Person Account') AND (SobjectType = 'Account') LIMIT 1];

        Account groupAccount = new Account(
            Name = 'Test Group Account',
            RecordTypeId = groupAccountRT.Id
        );
        insert groupAccount;
        
        Contract c = new Contract(
            AccountId = groupAccount.Id,
            Status = 'Draft',
            ContractTerm = 5, 
            ARC_ContractReason__c = 'New Application', 
            StartDate = Date.today().addDays(-30), 
            ARC_EffectiveDate__c = Date.today().addDays(-30)       
             ); 
        insert c; 

        Lead_Source__c ls = new Lead_Source__c(
            ARC_GroupAccount__c = groupAccount.Id, 
            IncludeInReferralDLRSCount__c = false
            );
        insert ls; 

        // Test job: 
        String CRON_EXP = '0 0 0 1 1 ? 2026';
        Test.startTest();
        // Schedule the test job
        String jobId = System.schedule('ReferralCounterTest', CRON_EXP, new ReferralCounter());
        Test.stopTest(); 

        Lead_Source__c updatedLS = [SELECT Id, IncludeInReferralDLRSCount__c FROM Lead_Source__c WHERE Id = :ls.Id];
        System.assertEquals(true, updatedLS.IncludeInReferralDLRSCount__c, 'Expected Lead Source to be marked to true');
   }
}