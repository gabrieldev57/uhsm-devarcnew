@isTest
global without sharing class ARC_CardExpirationBatchTest {
    @TestSetup
    static void data(){
        Date oggi = Date.today();
        //Create Contact
        Contact contactRecord = new Contact(FirstName = 'Jack', LastName = 'Sparrow', Email = 'testemailcensusmember@membertest.com');
        insert contactRecord; 
        //Create Census Member
    	vlocity_ins__GroupCensusMember__c censusMember = ARC_TestUtility.createTestCensusMember(1)[0];
        censusMember.vlocity_ins__IsPrimaryMember__c = censusMember.ARC_ActiveMember__c = true;
        censusMember.vlocity_ins__ContactId__c = contactRecord.Id;
        update censusMember;
        vlocity_ins__GroupCensusMember__c cMemb = [SELECT vlocity_ins__CensusId__r.vlocity_ins__GroupId__c, vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        Id accId = cMemb.vlocity_ins__CensusId__r.vlocity_ins__GroupId__c;
        Id censusId = cMemb.vlocity_ins__CensusId__c;
        //Create Chargent Order
        String nextMonth = String.valueOf(System.today().addMonths(1).month());
        String currentYear4 = nextMonth == '1'? String.valueOf(System.today().year() + 1) : String.valueOf(System.today().year());


        ChargentOrders__ChargentOrder__c co = new ChargentOrders__ChargentOrder__c();
        co.ChargentOrders__Payment_End_Date__c = oggi.addYears(1);
        co.ChargentOrders__Payment_Start_Date__c = oggi;
        co.ChargentOrders__Card_Last_4__c = '1234';
        co.ChargentOrders__Card_Type__c = 'Mastercard';
        co.ChargentOrders__Payment_Stop__c = 'Unending';
        co.ChargentOrders__Card_Expiration_Month__c  = String.valueOf(System.today().addMonths(1).month());
        co.ChargentOrders__Card_Expiration_Year__c = String.valueOf(System.today().year());
       // co.ChargentOrders__Next_Transaction_Date__c = Date.newInstance(2022, 10, 1);
        co.ChargentOrders__Payment_Method__c = 'Credit Card';
        co.ChargentOrders__Payment_Status__c = 'Recurring';
        co.ChargentOrders__Description__c = 'Recurring Monthly Order';
        co.ChargentOrders__Tokenization__c = String.valueOf((1+ Math.random()*1000000000).round());
        co.ChargentOrders__Card_Year_Indicator__c = currentYear4;
        co.ChargentOrders__Card_Month_Indicator__c = nextMonth;
        insert co;
        //Create Contract        
        Contract cont = new Contract(Name = 'Test', AccountId = accId, vlocity_ins__EnrollmentCensusId__c = censusId, ARC_RecurringMonthlyOrder__c = co.Id);
        insert cont;
        cont.Status = 'Activated';
        update cont;

        co.ARC_Contract__c = cont.Id;
        update co;
        
        //Query to get the Service Record Type
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Service' AND  SObjectType = 'Case' LIMIT 1]?.Id;
        //Create expiring CC Case
        Case caseInfo = new Case();
        caseInfo.RecordTypeId = recordTypeId;
        caseInfo.Status = 'New';
        caseInfo.Case_Type__c = 'Contribution';
        caseInfo.ARC_Reason__c = 'CC Expiration Date';
        caseInfo.Origin = 'System';
        caseInfo.ARC_Type__c = 'Member';
        caseInfo.Subject = 'CC expiring ';
        caseInfo.Description = 'CC expiring ';
        caseInfo.ARC_Contract__c = cont.Id;
        insert caseInfo;
                       
    }
    
    @isTest 
    static void testOne() {
        Test.startTest();
        ARC_CardExpirationBatch batch = new ARC_CardExpirationBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
    }
}