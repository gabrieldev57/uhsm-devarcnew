@isTest
public class ARC_ScheduleSDRCommissionsCreationTest {

    @TestSetup
    static void makeData(){
        Profile wsSalesProfile = [SELECT Id FROM Profile WHERE Name = 'WS Sales' LIMIT 1];

        // Test data setup
        List<User> sdrUsers = new List<User>();
        for(Integer i = 0; i<2 ; i++){
            User sdrUser = new User(
                Alias='sdrtest'+i,
                FirstName = 'Tester - '+i,
                LastName = 'SDR',
                Position__c = 'Sales Development Representative',
                IsActive = true,
                username = 'sdrtestuser@test.com'+i,
                ProfileId = wsSalesProfile.Id,
                TimeZoneSidKey = 'America/New_York',
                LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'ISO-8859-1',
                LocaleSidKey = 'en_US',
                Email = 'sdttester@test.com'+i
            );
            sdrUsers.add(sdrUser);
        }
        insert sdrUsers;
        
        Date currentDate = Date.today();
        Datetime currentDateTime = datetime.now();

        //Create the Tasks
        List<Task> tasksToCreate = new List<Task>();
        for(Integer i = 1; i<21; i++){
            Task t = new Task();
            if(i<6){
                t.CreatedById = sdrUsers[0].Id;
                t.ActivityDate = Date.newInstance(currentDate.year(), currentDate.month(),i);
            }
            else{
                t.CreatedById = sdrUsers[1].Id;
                t.ActivityDate = Date.newInstance(currentDate.year(), currentDate.month(),i);
            }
            tasksToCreate.add(t);
        }
        //Create the contracts signed by the customer
        List<Contract> contracts = ARC_TestUtility.createContracts(20);
        insert contracts;
        for(Contract c: contracts) {
            c.vlocity_ins__LastDocuSignEnvelopeStatus__c = 'Completed';
            c.First_Signed_Date__c = currentDate;
            c.ARC_ContractReason__c = 'New Application';
            c.status = 'Awaiting Approval';
        }
        //Create the leads
        List<Lead> leadsToCreate = new List<Lead>();
        for(Integer i = 0; i<26;i++){
            Lead lead = new Lead();
            if(i<11) lead.Sales_Development_Rep__c = sdrUsers[0].Id;
            else lead.Sales_Development_Rep__c = sdrUsers[1].Id;
            lead.Agent_Transfer_Date_Time__c = currentDateTime;
            lead.LastName = 'Test';
            leadsToCreate.add(lead);
        }
        insert tasksToCreate;
        update contracts;
        insert leadsToCreate;
    }


    @isTest
    static void testSDRCommissionCalculation() {
        List<User> users=[SELECT Id,IsActive,Position__c  FROM User WHERE  LastName = 'SDR' AND CreatedDate = TODAY ORDER BY FirstName ASC];
        List<Task> taskList= [SELECT Id, CreatedById, CreatedDate, ActivityDate FROM Task WHERE CreatedById =: users[0].Id];
        List<Contract> contractList = [SELECT Id FROM Contract]; 
        List<Lead> leadList = [SELECT Id,Sales_Development_Rep__c FROM Lead];

        Test.startTest();
        ARC_ScheduleSDRCommissionsCreation scheduledClass = new ARC_ScheduleSDRCommissionsCreation();
            scheduledClass.execute(null); 
        Test.stopTest();
        
        // Verify the created commission and commission payment records
        List<ARC_Commission__c> commissions = [SELECT Id,RecordType.Name, OwnerId FROM ARC_Commission__c WHERE OwnerId IN :users];
        System.assertEquals(2, commissions.size());

        List<ARC_Commission_Payment__c> commissionPayments = [SELECT Id,RecordType.Name,ARC_TotalSignedContracts__c,ARC_TotalTransfers__c, Commission__r.OwnerId ,ARC_TotalLaborDays__c, ARC_ActualWorkingDays__c, Type__c FROM ARC_Commission_Payment__c];
        System.assertEquals(2, commissionPayments.size());
        if(commissionPayments[0].Commission__r.OwnerId ==users[0].Id){
            System.assertEquals(5, commissionPayments[0].ARC_ActualWorkingDays__c);
            System.assertEquals(20, commissionPayments[0].ARC_TotalLaborDays__c);
            System.assertEquals(15, commissionPayments[1].ARC_ActualWorkingDays__c);
        }
        else{
            System.assertEquals(5, commissionPayments[1].ARC_ActualWorkingDays__c);
            System.assertEquals(20, commissionPayments[1].ARC_TotalLaborDays__c);
            System.assertEquals(15, commissionPayments[0].ARC_ActualWorkingDays__c);
        }
        System.assertEquals(contractList.size(), commissionPayments[0].ARC_TotalSignedContracts__c);
        System.assertEquals(contractList.size(), commissionPayments[1].ARC_TotalSignedContracts__c);
        System.assertEquals(leadList.size(), commissionPayments[0].ARC_TotalTransfers__c);
        System.assertEquals(leadList.size(), commissionPayments[1].ARC_TotalTransfers__c);
    }

}