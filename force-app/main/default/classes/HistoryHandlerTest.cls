@isTest
public class HistoryHandlerTest {
    
    public static testMethod void handlerTestData(){
        Integer numOfAccs = 3;
        List<Contact> contacts = new List<Contact>();
        List<Account> accounts = new List<Account>();
        Map<Id,vlocity_ins__GroupCensus__c> accountIdCensus = new Map<Id,vlocity_ins__GroupCensus__c>();
        Map<Id,Id> censusIdAccountId = new Map<Id,Id>();
        Map<Id,List<vlocity_ins__GroupCensusMember__c>> censusIdCensusMembers = new Map<Id,List<vlocity_ins__GroupCensusMember__c>>();
        Map<Id,Contract> accountIdContract = new Map<Id,Contract>();
        Map<Id,Opportunity> accountIdOpportunity = new Map<Id,Opportunity>();
        
        
        for (Integer i=0;i<numOfAccs;i++) {
            Account acc = new Account(FirstName = 'aver',LastName = 'sifunciona',BillingState='KS',vlocity_ins__Email__c='nazar@uhsm.com');
            accounts.add(acc);
        }
        insert accounts;
        for (Account acc : accounts) {
            Contact con = new Contact();
            vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(
                Name='WeSharecensusTest',vlocity_ins__GroupId__c=acc.Id,ARC_PrimaryAccount__c=acc.Id);
            accountIdCensus.put(acc.Id,census);
            con.LastName = acc.Name;
            con.FirstName = acc.Name;
            con.AccountId=acc.Id;
            contacts.add(con);
        }
        insert accountIdCensus.values();
        Integer num = 0;
        List<vlocity_ins__GroupCensusMember__c> listOfAllMembers = new List<vlocity_ins__GroupCensusMember__c>();
        for (vlocity_ins__GroupCensus__c census : accountIdCensus.values()) {
            censusIdAccountId.put(census.Id, census.vlocity_ins__GroupId__c);
            num++;
            vlocity_ins__GroupCensusMember__c primaryMember = new vlocity_ins__GroupCensusMember__c(
                Name = 'TestWeSharePrimaryMember ' + num,vlocity_ins__Email__c='nazar@gmail.com',vlocity_ins__CensusId__c = census.Id,
                vlocity_ins__IsPrimaryMember__c=true, vlocity_ins__Birthdate__c=date.today().addYears(-65).toStartOfMonth(),
                ARC_ActiveMember__c=true,ARC_PhysicalAddressState__c = 'KS');
            List<vlocity_ins__GroupCensusMember__c> listOfMembers = new List<vlocity_ins__GroupCensusMember__c>();
            listOfMembers.add(primaryMember);
            listOfAllMembers.add(primaryMember);
            censusIdCensusMembers.put(census.Id,listOfMembers);
        }
        
        insert listOfAllMembers;
        for (vlocity_ins__GroupCensus__c census : accountIdCensus.values()) {
            List<vlocity_ins__GroupCensusMember__c> listOfMembers = censusIdCensusMembers.get(census.Id);
            for (Integer i = 0; i < 3; i++) {
                vlocity_ins__GroupCensusMember__c member = new vlocity_ins__GroupCensusMember__c(
                    vlocity_ins__FirstName__c = 'WeShareTest', vlocity_ins__LastName__c = 'aaaa',vlocity_ins__Email__c='test@noreply.com',
                    Name = 'Test Census Member ' + i,vlocity_ins__CensusId__c = census.Id,vlocity_ins__IsPrimaryMember__c=false,
                    vlocity_ins__RelatedCensusMemberId__c=listOfMembers[0].Id,vlocity_ins__Birthdate__c=date.today().addYears(-20).addDays(1),
                    ARC_ActiveMember__c=true,ARC_PhysicalAddressState__c = 'KS',ARC_OptOutEmail__c=false);
                listOfMembers.add(member);
                listOfAllMembers.add(member);
            }
            censusIdCensusMembers.put(census.Id,listOfMembers);
        }
        upsert listOfAllMembers;
        
        
        List<Contract> listContract = new List<Contract>();
        for (Account acc : accounts) {
            
            Opportunity opp = new Opportunity();
            opp.AccountId=acc.Id;
            opp.Name = 'WeShare';
            opp.StageName = 'Prospecting';
            opp.CloseDate = date.today().addMonths(1);
            accountIdOpportunity.put(acc.Id,opp);
            
        }
        insert accountIdOpportunity.values();
        
        for (Account acc : accounts) {
            Contract con = new Contract();
            con.ContractTerm = 12;
            con.AccountId = acc.Id;
            con.ARC_Signer_Email__c = 'testEmail1@email.com';
            con.vlocity_ins__OpportunityId__c = accountIdOpportunity.get(acc.Id).Id;
            // con.Status = 'Activated';
            con.StartDate = Date.today();
            con.ARC_EffectiveDate__c=system.today()-4;
            con.vlocity_ins__EnrollmentCensusId__c = accountIdCensus.get(acc.Id).Id;
            accountIdContract.put(acc.Id,con);
        }
        insert accountIdContract.values();
        
        for(Contract c:accountIdContract.values()){
            c.Status='Terminated';
            c.ARC_Inactive_Date__c=system.today()-5;
        }
        
        update accountIdContract.values();
        
        Test.startTest();
        HistoryHandler.getAllHistoryRecords(accounts[0].id);  
        HistoryHandler.SObjectWrapper wr = new HistoryHandler.SObjectWrapper(accounts[0],'test');
        Test.stopTest();
    }
    
}