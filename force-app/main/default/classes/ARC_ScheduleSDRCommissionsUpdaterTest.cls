@isTest
public class ARC_ScheduleSDRCommissionsUpdaterTest {

    @isTest (SeeAllData = true)
    static void testOne(){
        Profile wsSalesProfile = [SELECT Id FROM Profile WHERE Name = 'WS Sales' LIMIT 1];
        Id rtCommSDR = Schema.SObjectType.ARC_Commission__c.getRecordTypeInfosByDeveloperName().get('ARC_SalesDevelopmentRep').getRecordTypeId();
        Id rtCommPaymentSDR = Schema.SObjectType.ARC_Commission_Payment__c.getRecordTypeInfosByDeveloperName().get('ARC_SalesDevelopmentRep').getRecordTypeId();
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

        List<ARC_Commission__c> commissionsToCreate = new List<ARC_Commission__c>();
        for(User sdr: sdrUsers){
            //Creates the master Commission record
            ARC_Commission__c monthlySDRCommission = new ARC_Commission__c(RecordTypeId = rtCommSDR, OwnerId = sdr.Id);
            commissionsToCreate.add(monthlySDRCommission);
        }
        insert commissionsToCreate;

        List<ARC_Commission_Payment__c> cpToCreate = new List<ARC_Commission_Payment__c>();
        for(ARC_Commission__c comm:commissionsToCreate){
            ARC_Commission_Payment__c cp = new ARC_Commission_Payment__c(
                RecordTypeId = rtCommPaymentSDR,
                Commission__c = comm.Id,
                ARC_TotalSignedContracts__c = 20,
                ARC_TotalTransfers__c = 20, //Total Transfers made by all SDR
                ARC_TotalLaborDays__c = 20, //Total labor days for all SDRs
                ARC_ActualWorkingDays__c = 20, //Actual labour days for that SDR
                Type__c ='Monthly Payout'
            );
            cpToCreate.add(cp);
        }
        insert cpToCreate;

        //Create the leads (Transfer Calls)
        //Transfer calls (User 0-> 3, User 1->4)
        List<Lead> leadsToCreate = new List<Lead>();
        for(Integer i = 0; i<7;i++){
            Lead lead = new Lead();
            if(i<3) lead.Sales_Development_Rep__c = sdrUsers[0].Id;
            else lead.Sales_Development_Rep__c = sdrUsers[1].Id;
            lead.Agent_Transfer_Date_Time__c = Datetime.now().addMonths(-1);
            lead.LastName = 'Test';
            leadsToCreate.add(lead);
        }
        //Create Tasks (Total Calls)
        //TOTAL calls (User 0-> 11, User 1->14) 
        //TRANSFER RATE (User 0 ->27%, User 1-> 29%)
        List<Task> tasksToCreate = new List<Task>();
        for(Integer i = 1; i<26; i++){
            Task t = new Task();
            if(i<12) t.CreatedById = sdrUsers[0].Id;
            else t.CreatedById = sdrUsers[1].Id;
            t.CallDisposition = 'New Deal';
            t.Five9Campaign__c = 'IN - SDR Unbranded';
            t.calltype = 'Inbound';
            tasksToCreate.add(t);
        }
        insert tasksToCreate;
        insert leadsToCreate;

        Test.startTest();
        ARC_ScheduleSDRCommissionsUpdater scheduledClass = new ARC_ScheduleSDRCommissionsUpdater();
            scheduledClass.execute(null); 
        Test.stopTest();

        List<ARC_Commission_Payment__c> commissionPayments = [SELECT Id,RecordType.Name,Commission__r.OwnerId,ARC_SalesFloorConversion__c,ARC_TotalLaborDays__c,ARC_WorkingDays__c, ARC_ActualTransfers__c ,ARC_ActualWorkingDays__c, Type__c, Amount__c, ARC_PaymentDate__c,ARC_BonusAmount__c,ARC_TotalCalls__c, ARC_TransferRate__c FROM ARC_Commission_Payment__c WHERE Commission__r.OwnerId IN: sdrUsers];
        ARC_Commission_Payment__c cpSDR0;
        ARC_Commission_Payment__c cpSDR1;
        System.debug(commissionPayments);
        for(ARC_Commission_Payment__c cp: commissionPayments){
            if(cp.Commission__r.OwnerId == sdrUsers[0].Id) cpSDR0 = cp;
            else if(cp.Commission__r.OwnerId == sdrUsers[1].Id) cpSDR1 = cp;
            System.debug(cp.Commission__r.OwnerId+ ' TOTAL LABOR: '+cp.ARC_TotalLaborDays__c + ' ACTUAL WD: '+cp.ARC_ActualWorkingDays__c + ' BONUS: '+cp.ARC_BonusAmount__c+ ' PAYMENT DATE: '+cp.ARC_PaymentDate__c+ ' AMOUNT: '+cp.Amount__c+' ACTUAL TRANSFER: '+cp.ARC_ActualTransfers__c+' TOTALCALLS: '+cp.ARC_TotalCalls__c + ' TRANSFER RATE: '+cp.ARC_TransferRate__c);
        }
        //SDR 0
        System.assertEquals(sdrUsers[0].Id, cpSDR0.Commission__r.OwnerId);
        System.assertEquals(3, cpSDR0.ARC_ActualTransfers__c);
        System.assertEquals(11, cpSDR0.ARC_TotalCalls__c);
        System.assertEquals(1000, cpSDR0.ARC_BonusAmount__c);
        System.assertEquals(100, cpSDR0.ARC_WorkingDays__c);
        System.assertEquals(100, cpSDR0.ARC_SalesFloorConversion__c);
        System.assertEquals(1000, cpSDR0.Amount__c);
        //SDR 1
        System.assertEquals(sdrUsers[0].Id, cpSDR0.Commission__r.OwnerId);
        System.assertEquals(4, cpSDR1.ARC_ActualTransfers__c);
        System.assertEquals(14, cpSDR1.ARC_TotalCalls__c);
        System.assertEquals(1500, cpSDR1.ARC_BonusAmount__c);
        System.assertEquals(100, cpSDR1.ARC_WorkingDays__c);
        System.assertEquals(100, cpSDR1.ARC_SalesFloorConversion__c);
        System.assertEquals(1500, cpSDR1.Amount__c);
    }

    @isTest (SeeAllData = true)
    static void testSalesFloorConversion5(){
        Profile wsSalesProfile = [SELECT Id FROM Profile WHERE Name = 'WS Sales' LIMIT 1];
        Id rtCommSDR = Schema.SObjectType.ARC_Commission__c.getRecordTypeInfosByDeveloperName().get('ARC_SalesDevelopmentRep').getRecordTypeId();
        Id rtCommPaymentSDR = Schema.SObjectType.ARC_Commission_Payment__c.getRecordTypeInfosByDeveloperName().get('ARC_SalesDevelopmentRep').getRecordTypeId();
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

        //Create Commisison And CP Records
        List<ARC_Commission__c> commissionsToCreate = new List<ARC_Commission__c>();
        for(User sdr: sdrUsers){
            //Creates the master Commission record
            ARC_Commission__c monthlySDRCommission = new ARC_Commission__c(RecordTypeId = rtCommSDR, OwnerId = sdr.Id);
            commissionsToCreate.add(monthlySDRCommission);
        }
        insert commissionsToCreate;

        List<ARC_Commission_Payment__c> cpToCreate = new List<ARC_Commission_Payment__c>();
        for(ARC_Commission__c comm:commissionsToCreate){
            ARC_Commission_Payment__c cp = new ARC_Commission_Payment__c(
                RecordTypeId = rtCommPaymentSDR,
                Commission__c = comm.Id,
                ARC_TotalSignedContracts__c = 5,
                ARC_TotalTransfers__c = 100, //Total Transfers made by all SDR
                ARC_TotalLaborDays__c = 20, //Total labor days for all SDRs
                ARC_ActualWorkingDays__c = 20, //Actual labour days for that SDR
                Type__c ='Monthly Payout'
            );
            cpToCreate.add(cp);
        }
        insert cpToCreate;


        //Create the leads (Transfer Calls)
        //Transfer calls (User 0-> 3, User 1->4)
        List<Lead> leadsToCreate = new List<Lead>();
        for(Integer i = 0; i<7;i++){
            Lead lead = new Lead();
            if(i<3) lead.Sales_Development_Rep__c = sdrUsers[0].Id;
            else lead.Sales_Development_Rep__c = sdrUsers[1].Id;
            lead.Agent_Transfer_Date_Time__c = Datetime.now().addMonths(-1);
            lead.LastName = 'Test';
            leadsToCreate.add(lead);
        }
        //Create Tasks (Total Calls)
        //TOTAL calls (User 0-> 11, User 1->14) 
        //TRANSFER RATE (User 0 ->27%, User 1-> 29%)
        List<Task> tasksToCreate = new List<Task>();
        for(Integer i = 1; i<26; i++){
            Task t = new Task();
            if(i<12) t.CreatedById = sdrUsers[0].Id;
            else t.CreatedById = sdrUsers[1].Id;
            t.CallDisposition = 'New Deal';
            t.Five9Campaign__c = 'IN - SDR Unbranded';
            t.calltype = 'Inbound';
            tasksToCreate.add(t);
        }
        insert tasksToCreate;
        insert leadsToCreate;

        Test.startTest();
        ARC_ScheduleSDRCommissionsUpdater scheduledClass = new ARC_ScheduleSDRCommissionsUpdater();
            scheduledClass.execute(null); 
        Test.stopTest();

        List<ARC_Commission_Payment__c> commissionPayments = [SELECT Id,RecordType.Name,Commission__r.OwnerId,ARC_SalesFloorConversion__c,ARC_TotalLaborDays__c,ARC_WorkingDays__c, ARC_ActualTransfers__c ,ARC_ActualWorkingDays__c, Type__c, Amount__c, ARC_PaymentDate__c,ARC_BonusAmount__c,ARC_TotalCalls__c, ARC_TransferRate__c FROM ARC_Commission_Payment__c WHERE Commission__r.OwnerId IN: sdrUsers];
        ARC_Commission_Payment__c cpSDR0;
        ARC_Commission_Payment__c cpSDR1;
        for(ARC_Commission_Payment__c cp: commissionPayments){
            if(cp.Commission__r.OwnerId == sdrUsers[0].Id) cpSDR0 = cp;
            else if(cp.Commission__r.OwnerId == sdrUsers[1].Id) cpSDR1 = cp;
            System.debug(cp.Commission__r.OwnerId+ ' TOTAL LABOR: '+cp.ARC_TotalLaborDays__c + ' ACTUAL WD: '+cp.ARC_ActualWorkingDays__c + ' BONUS: '+cp.ARC_BonusAmount__c+ ' PAYMENT DATE: '+cp.ARC_PaymentDate__c+ ' AMOUNT: '+cp.Amount__c+' TOTAL TRANSFER: '+cp.ARC_ActualTransfers__c+' TOTALCALLS: '+cp.ARC_TotalCalls__c + ' TRANSFER RATE: '+cp.ARC_TransferRate__c);
        }
        //SDR 0
        System.assertEquals(sdrUsers[0].Id, cpSDR0.Commission__r.OwnerId);
        System.assertEquals(3, cpSDR0.ARC_ActualTransfers__c);
        System.assertEquals(11, cpSDR0.ARC_TotalCalls__c);
        System.assertEquals(1000, cpSDR0.ARC_BonusAmount__c);
        System.assertEquals(100, cpSDR0.ARC_WorkingDays__c);
        System.assertEquals(5, cpSDR0.ARC_SalesFloorConversion__c);
        System.assertEquals(0, cpSDR0.Amount__c);
        //SDR 1
        System.assertEquals(sdrUsers[0].Id, cpSDR0.Commission__r.OwnerId);
        System.assertEquals(4, cpSDR1.ARC_ActualTransfers__c);
        System.assertEquals(14, cpSDR1.ARC_TotalCalls__c);
        System.assertEquals(1500, cpSDR1.ARC_BonusAmount__c);
        System.assertEquals(100, cpSDR1.ARC_WorkingDays__c);
        System.assertEquals(5, cpSDR1.ARC_SalesFloorConversion__c);
        System.assertEquals(0, cpSDR1.Amount__c);
    }

    @isTest (SeeAllData = true)
    static void testSalesFloorConversion30(){
        Profile wsSalesProfile = [SELECT Id FROM Profile WHERE Name = 'WS Sales' LIMIT 1];
        Id rtCommSDR = Schema.SObjectType.ARC_Commission__c.getRecordTypeInfosByDeveloperName().get('ARC_SalesDevelopmentRep').getRecordTypeId();
        Id rtCommPaymentSDR = Schema.SObjectType.ARC_Commission_Payment__c.getRecordTypeInfosByDeveloperName().get('ARC_SalesDevelopmentRep').getRecordTypeId();
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

        //Create Commisison And CP Records
        List<ARC_Commission__c> commissionsToCreate = new List<ARC_Commission__c>();
        for(User sdr: sdrUsers){
            //Creates the master Commission record
            ARC_Commission__c monthlySDRCommission = new ARC_Commission__c(RecordTypeId = rtCommSDR, OwnerId = sdr.Id);
            commissionsToCreate.add(monthlySDRCommission);
        }
        insert commissionsToCreate;

        List<ARC_Commission_Payment__c> cpToCreate = new List<ARC_Commission_Payment__c>();
        for(ARC_Commission__c comm:commissionsToCreate){
            ARC_Commission_Payment__c cp = new ARC_Commission_Payment__c(
                RecordTypeId = rtCommPaymentSDR,
                Commission__c = comm.Id,
                ARC_TotalSignedContracts__c = 30,
                ARC_TotalTransfers__c = 100, //Total Transfers made by all SDR
                ARC_TotalLaborDays__c = 20, //Total labor days for all SDRs
                ARC_ActualWorkingDays__c = 10, //Actual labour days for that SDR
                Type__c ='Monthly Payout'
            );
            cpToCreate.add(cp);
        }
        insert cpToCreate;


        //Create the leads (Transfer Calls)
        //Transfer calls (User 0-> 2, User 1->4)
        List<Lead> leadsToCreate = new List<Lead>();
        for(Integer i = 0; i<6;i++){
            Lead lead = new Lead();
            if(i<2) lead.Sales_Development_Rep__c = sdrUsers[0].Id;
            else lead.Sales_Development_Rep__c = sdrUsers[1].Id;
            lead.Agent_Transfer_Date_Time__c = Datetime.now().addMonths(-1);
            lead.LastName = 'Test';
            leadsToCreate.add(lead);
        }
        //Create Tasks (Total Calls)
        //TOTAL calls (User 0-> 11, User 1->10) 
        //TRANSFER RATE (User 0 ->18%, User 1-> 40%)
        List<Task> tasksToCreate = new List<Task>();
        for(Integer i = 1; i<22; i++){
            Task t = new Task();
            if(i<12) t.CreatedById = sdrUsers[0].Id;
            else t.CreatedById = sdrUsers[1].Id;
            t.CallDisposition = 'New Deal';
            t.Five9Campaign__c = 'IN - SDR Unbranded';
            t.calltype = 'Inbound';
            tasksToCreate.add(t);
        }
        insert tasksToCreate;
        insert leadsToCreate;

        Test.startTest();
        ARC_ScheduleSDRCommissionsUpdater scheduledClass = new ARC_ScheduleSDRCommissionsUpdater();
            scheduledClass.execute(null); 
        Test.stopTest();

        List<ARC_Commission_Payment__c> commissionPayments = [SELECT Id,RecordType.Name,Commission__r.OwnerId,ARC_SalesFloorConversion__c,ARC_TotalLaborDays__c,ARC_WorkingDays__c, ARC_ActualTransfers__c ,ARC_ActualWorkingDays__c, Type__c, Amount__c, ARC_PaymentDate__c,ARC_BonusAmount__c,ARC_TotalCalls__c, ARC_TransferRate__c FROM ARC_Commission_Payment__c WHERE Commission__r.OwnerId IN: sdrUsers];
        ARC_Commission_Payment__c cpSDR0;
        ARC_Commission_Payment__c cpSDR1;
        for(ARC_Commission_Payment__c cp: commissionPayments){
            if(cp.Commission__r.OwnerId == sdrUsers[0].Id) cpSDR0 = cp;
            else if(cp.Commission__r.OwnerId == sdrUsers[1].Id) cpSDR1 = cp;
            System.debug(cp.Commission__r.OwnerId+ ' TOTAL LABOR: '+cp.ARC_TotalLaborDays__c + ' ACTUAL WD: '+cp.ARC_ActualWorkingDays__c + ' BONUS: '+cp.ARC_BonusAmount__c+ ' PAYMENT DATE: '+cp.ARC_PaymentDate__c+ ' AMOUNT: '+cp.Amount__c+' TOTAL TRANSFER: '+cp.ARC_ActualTransfers__c+' TOTALCALLS: '+cp.ARC_TotalCalls__c + ' TRANSFER RATE: '+cp.ARC_TransferRate__c);
        }
        //SDR 0
        System.assertEquals(sdrUsers[0].Id, cpSDR0.Commission__r.OwnerId);
        System.assertEquals(2, cpSDR0.ARC_ActualTransfers__c);
        System.assertEquals(11, cpSDR0.ARC_TotalCalls__c);
        System.assertEquals(0, cpSDR0.ARC_BonusAmount__c);
        System.assertEquals(50, cpSDR0.ARC_WorkingDays__c);
        System.assertEquals(30, cpSDR0.ARC_SalesFloorConversion__c);
        System.assertEquals(0, cpSDR0.Amount__c);
        //SDR 1
        System.assertEquals(sdrUsers[0].Id, cpSDR0.Commission__r.OwnerId);
        System.assertEquals(4, cpSDR1.ARC_ActualTransfers__c);
        System.assertEquals(10, cpSDR1.ARC_TotalCalls__c);
        System.assertEquals(2000, cpSDR1.ARC_BonusAmount__c);
        System.assertEquals(50, cpSDR1.ARC_WorkingDays__c);
        System.assertEquals(30, cpSDR1.ARC_SalesFloorConversion__c);
        System.assertEquals(1000, cpSDR1.Amount__c);
    }
}