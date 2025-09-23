@isTest

public class ReferralCounterJobTest {
    @isTest 
    static void testReferralAssignments(){
        User u = [SELECT Id FROM User WHERE Profile.Name = 'Standard User' LIMIT 1]; 

        RecordType groupAccountRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Group'];
        RecordType personAccRT = [SELECT Id FROM RecordType WHERE (Name = 'Person Account') AND (SobjectType = 'Account') LIMIT 1];

        Account referrerAccount = new Account(
            FirstName = 'Test',
            LastName = 'Test', 
            RecordTypeId = personAccRT.Id,
            OwnerId = u.Id
        ); 

        insert referrerAccount; 

        Account groupAccount = new Account(
            Name = 'Test Family', 
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

        Lead_Source__c lsToSkip = new Lead_Source__c(
            Referrer_Account__c = referrerAccount.Id, 
            ARC_GroupAccount__c = groupAccount.Id, 
            IncludeInReferralDLRSCount__c = false
            );
        insert lsToSkip; 
        
        Test.startTest(); 
            ReferralCounterJob.run(); 
        Test.stopTest(); 

        Lead_Source__c updatedLS = [SELECT Id, IncludeInReferralDLRSCount__c FROM Lead_Source__c WHERE Id = : ls.Id];
        System.assertEquals(true, updatedLS.IncludeInReferralDLRSCount__c, 'Lead source should be marked for DLRS'); 
        
        Lead_Source__c updatedLSToSkip = [SELECT Id, IncludeInReferralDLRSCount__c FROM Lead_Source__c WHERE Id = : lsToSkip.Id];
        System.assertEquals(false, updatedLSToSkip.IncludeInReferralDLRSCount__c, 'Lead source should NOT be marked for DLRS'); 

        //check dlrs: 
        //System.assertEquals(1, [SELECT CountReferrals__c FROM Account WHERE Id = : referrerAccount.Id].CountReferrals__c, 'referral count does not match '); 
    }
}