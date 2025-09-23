@isTest
global class ARC_65YearsBatchTest {

    @TestSetup
    static void mockData(){
        Date oggi = Date.today();
        Integer year = System.today().year() - 65;
        Date birthDate = Date.newInstance(year, System.today().month(), System.today().day());
        //Create Contact
        Contact contactRecord = new Contact(FirstName = 'Jack', LastName = 'Sparrow', Email = 'testemailcensusmember@membertest.com');
        insert contactRecord; 
        //Create Census Member
    	vlocity_ins__GroupCensusMember__c censusMember = ARC_TestUtility.createTestCensusMember(1)[0];
        censusMember.vlocity_ins__IsPrimaryMember__c = censusMember.ARC_ActiveMember__c = true;
        censusMember.vlocity_ins__Birthdate__c = birthDate.addDays(30);
        censusMember.ARC_PhysicalAddressState__c ='CA';
        censusMember.vlocity_ins__ContactId__c = contactRecord.Id;
        update censusMember;
        vlocity_ins__GroupCensusMember__c cMemb = [SELECT vlocity_ins__CensusId__r.vlocity_ins__GroupId__c, vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        Id accId = cMemb.vlocity_ins__CensusId__r.vlocity_ins__GroupId__c;
        Id censusId = cMemb.vlocity_ins__CensusId__c;
        //Create Order
        ChargentOrders__ChargentOrder__c ord = new ChargentOrders__ChargentOrder__c();
        ord.ARC_FirstMonthPayed__c = true;
        ord.ChargentOrders__Description__c = 'Recurring Monthly Order';
        ord.ChargentOrders__Charge_Amount__c = 10;
        insert ord;
        //Create Contract        
        Contract cont = new Contract(Name = 'Test', AccountId = accId, vlocity_ins__EnrollmentCensusId__c = censusId,ARC_RecurringMonthlyOrder__c= ord.Id, ARC_EffectiveDate__c = Date.newInstance(2023, 12, 12));
        insert cont;
        // cont.Status = 'Activated';
        // update cont;
        cont.Status = 'Awaiting Activation';
        cont.ARC_EffectiveDate__c = Date.today().addDays(1);
        update cont;

        cont.Status = 'Activated';
        update cont;
    }
    
    @isTest
    static void testOne(){
        String error;
        Test.startTest();
        try{
            ARC_65YearsBatch testBatch = new ARC_65YearsBatch();
            Database.executeBatch(testBatch);
        }catch(Exception e){
            error = e.getMessage();
        }
        Test.stopTest();
        
        System.assertEquals(true, String.isBlank(error));
    }
    
    @isTest
    static void testTwo(){
        vlocity_ins__GroupCensusMember__c censusMember = [SELECT Id, ARC_PhysicalAddressState__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        censusMember.ARC_PhysicalAddressState__c = 'NY';
        update censusMember;
        String error;
        
        Test.startTest();
        try{
            ARC_65YearsBatch testBatch = new ARC_65YearsBatch();
            Database.executeBatch(testBatch);
        }catch(Exception e){
            error = e.getMessage();
        }
        Test.stopTest();
        
        System.assertEquals(true, String.isBlank(error));
    }

}