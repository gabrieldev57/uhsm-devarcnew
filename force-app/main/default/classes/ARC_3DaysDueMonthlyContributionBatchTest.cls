@isTest
public without sharing class ARC_3DaysDueMonthlyContributionBatchTest {
    @TestSetup
    static void makeData(){

        List<Account> GroupAccount = ARC_TestUtility.createTestAccount(1,'StandardAccount');

        Contact contactRecord = new Contact();
        contactRecord.FirstName = 'Test';
        contactRecord.LastName = 'Test';
        contactRecord.Email = 'test@test.com';
        insert contactRecord;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.vlocity_ins__GroupId__c = GroupAccount[0].Id;
        insert census;

        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();
        censusMember.vlocity_ins__FirstName__c = 'Test FirstName';
        censusMember.vlocity_ins__CensusId__c = census.Id;
        censusMember.vlocity_ins__IsPrimaryMember__c = true;
        censusMember.ARC_ActiveMember__c = true;
        censusMember.vlocity_ins__ContactId__c = contactRecord.Id;
        insert censusMember;

        ChargentOrders__ChargentOrder__c ord = new ChargentOrders__ChargentOrder__c();
        ord.ARC_FirstMonthPayed__c = true;
        ord.ChargentOrders__Description__c = 'Recurring Monthly Order';
        ord.ChargentOrders__Charge_Amount__c = 10;
        insert ord;

        Contract contract = new Contract();
        contract.vlocity_ins__EnrollmentCensusId__c = census.Id;
        contract.AccountId = GroupAccount[0].Id;
        contract.ARC_RecurringMonthlyOrder__c = ord.Id;
        insert contract;
        contract.Status = 'Activated';
		update contract;

        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c();
        order.ARC_Contract__c = contract.Id;
        order.ChargentOrders__Payment_Status__c = 'Recurring';
		order.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12);
        order.ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3);
		order.ChargentOrders__Description__c = 'Recurring Monthly Order';
        insert order;
    }

    @isTest
    public static void Test3DaysDueMonthlyContribution(){
        Test.startTest();
        Database.executeBatch(new ARC_3DaysDueMonthlyContributionBatch());
        Test.stopTest();
    }

    @isTest
    public static void Test3DaysDueMonthlyContribution2(){
        List<ChargentOrders__ChargentOrder__c> orderList = [SELECT Id FROM ChargentOrders__ChargentOrder__c];
        Set<Id> chargentOrderIds = new Set<Id>();
        for(ChargentOrders__ChargentOrder__c chargentOrder : orderList){ 
            chargentOrderIds.add(chargentOrder.Id);
        }

        Test.startTest();
        Database.executeBatch(new ARC_3DaysDueMonthlyContributionBatch(chargentOrderIds));
        Test.stopTest();
    }
}