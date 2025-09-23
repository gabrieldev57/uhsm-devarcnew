/*******************************************************************
* @ClassName          :   ARC_SchedulePortalUserCreation
* @Description        :   Schedulable apex that automate the creation of Portal Users if they were not created after bulk activation of the contracts
* @MethodName         :   execute(SchedulableContext SC)
********************************************************************/
public with sharing class ARC_SchedulePortalUserCreation implements Schedulable { 
    
    public void execute(SchedulableContext SC) {
        Date currentDay = Date.today();
        //Execute the job the following date of the massive activations of the contracts (1 & 15)
        if(currentDay.day() == 2 || currentDay.day() == 16 || Test.isRunningTest()){
            //Get all the Available States of WeShare Programs
            List<ARC_Available_States__mdt> allStates = [SELECT Id, Label, allStatesAbbreviation__c 
                                                         FROM ARC_Available_States__mdt 
                                                         WHERE DeveloperName ='All'];
            //Get the list of all the primaries over 18 in a WeShare Plan and check whether they have a portal user or not
            List<Account> listAccounts = [SELECT id, personcontactid,Census_Member__c, BillingState, vlocity_ins__Email__c 
                                          FROM Account 
                                          WHERE vlocity_ins__Age__pc >= 18 
                                          AND vlocity_ins__Age__pc < 65
                                          AND ARC_IsPrimaryMember__c = true 
                                          AND IsActive = true 
                                          AND BillingState != null];
            List<vlocity_ins__GroupCensusMemberPlan__c> censusMemberPlans = [SELECT Id, vlocity_ins__GroupCensusMemberId__c, Name 
                                                                             FROM vlocity_ins__GroupCensusMemberPlan__c 
                                                                             WHERE Name LIKE 'WeShare%' 
                                                                             AND (NOT Name LIKE '%Legacy') 
                                                                             AND vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status ='Activated'];
            Set<Id> personContactIds = new Set<Id>();
            Set<Id> censusMemberIds = new Set<Id>();
            Set<String> memberEmails = new Set<String>();


            for (vlocity_ins__GroupCensusMemberPlan__c censusMemberPlan : censusMemberPlans) {
                censusMemberIds.add(censusMemberPlan.vlocity_ins__GroupCensusMemberId__c);
            }
            for (Account acc : listAccounts) {
                System.debug(acc.Id);
                System.debug(acc.BillingState);
                memberEmails.add(acc.vlocity_ins__Email__c);
                //Get the Contact record for the person contact id
                //Filter Accounts whose billing state is available and with a WeShare program
                if (allStates[0].allStatesAbbreviation__c.contains(acc.BillingState) && censusMemberIds.contains(acc.Census_Member__c)) {
                    personContactIds.add(acc.PersonContactId);
                }
            }
            List<User> existingUsers = [SELECT Id, Email,  Contactid  FROM USER WHERE contactId IN :personContactIds OR Email IN: memberEmails];
            Set<String> existingUserEmails = new Set<String>();
            Set<Id> existingUserContactIds = new Set<Id>();
            for(User existingUser : existingUsers){
                if(existingUser.ContactId != null) existingUserContactIds.add(existingUser.ContactId);
                existingUserEmails.add(existingUser.Email);
            }
            
            Set<Id> missingContactIds = new Set<Id>();
            
            for (Id contactId : personContactIds) {
                if (!existingUserContactIds.contains(contactId)) {
                    missingContactIds.add(contactId);
                }
            }
            System.debug(existingUserEmails);
            List<Contact> missingContactList = [SELECT Id, AccountId FROM Contact WHERE Id IN: missingContactIds AND Account.vlocity_ins__Email__c NOT IN:existingUserEmails];
            if(missingContactList!=null){
                //Call the Batch that created the Portal Users
                Set<Id> accsIdsToCreate = new Set<Id>();
                for(Contact c: missingContactList){
                    accsIdsToCreate.add(c.AccountId);
                }
                Database.executeBatch(new ARC_BackfillCreateMemberUsersBatch(accsIdsToCreate));
            }
        }
    }
}