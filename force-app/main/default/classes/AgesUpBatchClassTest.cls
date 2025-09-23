@isTest
public class AgesUpBatchClassTest {
     @TestSetup
    static void mockData(){
        Date oggi = Date.today();
        Integer year = System.today().year() - 31;
        Date birthDate = Date.newInstance(year, System.today().month(), System.today().day());
        //Create Contact
        Contact contactRecord = new Contact(FirstName = 'Jack', LastName = 'Sparrow', 
                                            Email = 'testemailcensusmember@membertest.com');
        Contact contactRecord2 = New Contact(FirstName = 'Jack', LastName = 'SecondTest',
                                            Email = 'secondtest@uhsm.org.test');
        insert contactRecord;
        insert contactRecord2;
        
        //Create Census Member 1
    	vlocity_ins__GroupCensusMember__c censusMember = ARC_TestUtility.createTestCensusMember(1)[0];
        censusMember.vlocity_ins__IsPrimaryMember__c = censusMember.ARC_ActiveMember__c = true;
        censusMember.vlocity_ins__Birthdate__c = birthDate.addDays(59);
        censusMember.vlocity_ins__ContactId__c = contactRecord.Id;
        censusMember.vlocity_ins__IsPrimaryMember__c =true;
        Date createdDateLimit = oggi;
        Test.setCreatedDate(censusMember.Id, createdDateLimit);
        update censusMember;
        
        //Create Census Member 2
    	vlocity_ins__GroupCensusMember__c censusMember2 = ARC_TestUtility.createTestCensusMember(1)[0];
        censusMember2.vlocity_ins__IsPrimaryMember__c = censusMember2.ARC_ActiveMember__c = true;
        year = System.today().year() - 31;
        birthDate = Date.newInstance(year, System.today().month(), System.today().day());
        censusMember2.vlocity_ins__Birthdate__c = birthDate.addDays(59);
        censusMember2.vlocity_ins__ContactId__c = contactRecord2.Id;
        censusMember2.vlocity_ins__IsPrimaryMember__c =true;
        Test.setCreatedDate(censusMember2.Id, createdDateLimit);
        update censusMember2;
        
        //Get GroupCensusMember1 and account and census
        vlocity_ins__GroupCensusMember__c cMemb = [SELECT Id,vlocity_ins__CensusId__r.vlocity_ins__GroupId__c, vlocity_ins__CensusId__c,vlocity_ins__Birthdate__c,Age_Change_In_60_Days__c,ARC_ActiveMember__c 
                                                   FROM vlocity_ins__GroupCensusMember__c WHERE Id =: censusMember.Id LIMIT 1];
        System.debug('CensusMemberId :' + cMemb.Id);
        System.debug('CensusMemberbirthdate :' + cMemb.vlocity_ins__Birthdate__c);
        System.debug('CMAGeChangeIn60Days :' + cMemb.Age_Change_In_60_Days__c);
        System.debug('CMActiveMember :' + cMemb.ARC_ActiveMember__c);
        Id accId = cMemb.vlocity_ins__CensusId__r.vlocity_ins__GroupId__c;
        Id censusId = cMemb.vlocity_ins__CensusId__c;
        Decimal subtotal=400.6;
        
        //Get GroupCensusMember2 and account and census
        vlocity_ins__GroupCensusMember__c cMemb2 = [SELECT Id,vlocity_ins__CensusId__r.vlocity_ins__GroupId__c, vlocity_ins__CensusId__c,vlocity_ins__Birthdate__c,Age_Change_In_60_Days__c,ARC_ActiveMember__c 
                                                   FROM vlocity_ins__GroupCensusMember__c WHERE Id =: censusMember2.Id LIMIT 1];
        System.debug('CensusMemberId :' + cMemb2.Id);
        System.debug('CensusMemberbirthdate :' + cMemb2.vlocity_ins__Birthdate__c);
        System.debug('CMAGeChangeIn60Days :' + cMemb2.Age_Change_In_60_Days__c);
        System.debug('CMActiveMember :' + cMemb2.ARC_ActiveMember__c);
        Id accId2 = cMemb2.vlocity_ins__CensusId__r.vlocity_ins__GroupId__c;
        Id censusId2 = cMemb2.vlocity_ins__CensusId__c;
        
        //Create Contract1
        Contract cont = new Contract(Name = 'Test', AccountId = accId, 
                                     vlocity_ins__EnrollmentCensusId__c = censusId,ARC_EffectiveDate__c = Date.newInstance(2023, 8, 1),
                                    	createddate = Date.newInstance(2023, 8, 2));
        //Create Contract2      
        Contract cont2 = new Contract(Name = 'Test', AccountId = accId2, 
                                     vlocity_ins__EnrollmentCensusId__c = censusId2,ARC_EffectiveDate__c = oggi.adddays(60), 
                                            createddate = Date.newInstance(2023, 5, 1));
        
        System.debug('ContractCreatedDate :' + Contract.createddate);
        
        insert cont;
        insert cont2;
        System.debug('ContractCreatedDate :' + cont.createddate);
        System.debug('ContractCreatedDate :' + cont2.createddate);
        
        
        ChargentOrders__ChargentOrder__c chargent=new ChargentOrders__ChargentOrder__c();
        chargent.ARC_Contract__c = cont.Id;
       chargent.ChargentOrders__Shipping__c = 232;
       chargent.ChargentOrders__Tax__c  = 232;
       chargent.ChargentOrders__Charge_Amount__c = 232;
       chargent.ChargentOrders__Subtotal__c  = 232;
       chargent.ChargentOrders__Charge_Date__c =  '01';
       chargent.ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3);
	   chargent.ChargentOrders__Payment_Status__c = 'Recurring';
	   chargent.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12);
       chargent.ChargentOrders__Payment_Method__c = 'Credit Card';
	   chargent.ChargentOrders__Card_Last_4__c = '1234';
	   chargent.ChargentOrders__Card_Type__c = 'VISA';
	   chargent.ChargentOrders__Card_Expiration_Month__c = '12';
	   chargent.ChargentOrders__Card_Expiration_Year__c = '2024';
	   chargent.ChargentOrders__Tokenization__c = '12345678';
       chargent.ChargentOrders__Description__c = 'Recurring Monthly Order';
    
        insert chargent;
        ChargentOrders__ChargentOrder__c chargent2 = chargent;
        chargent2.ARC_Contract__c = cont2.Id;
        chargent2.Id = null;
        insert chargent2;
        
        Product2 product=new Product2(Name='WeShare',vlocity_ins__Type__c='Medical',vlocity_ins__SubType__c='PPO');
        insert product;
        
        vlocity_ins__ContractLineItem__c CLI=new vlocity_ins__ContractLineItem__c(Name = 'WeShare',vlocity_ins__ContractId__c=cont.Id,vlocity_ins__Product2Id__c=product.Id);
       	insert CLI;
        vlocity_ins__ContractLineItem__c CLI2=new vlocity_ins__ContractLineItem__c(Name = 'WeShare',vlocity_ins__ContractId__c=cont2.Id,vlocity_ins__Product2Id__c=product.Id);
        insert CLI2;
        
        Ages_Up__c AgeUp=new Ages_Up__c(Name='Test',vlocity_Ins_CensusMemberId__c=cMemb.Id,Contract__c=cont.Id);
        insert AgeUp;
        Ages_Up__c AgeUp2=new Ages_Up__c(Name='Test',vlocity_Ins_CensusMemberId__c=cMemb2.Id,Contract__c=cont2.Id);
        insert AgeUp2;
        
        
        System.debug('AgeUp: '+ AgeUp);
        System.debug('AgeUp2: '+ AgeUp2);
        cont.Status = 'Activated';
        cont.ARC_RecurringMonthlyOrder__c=chargent.Id;
        cont2.Status= 'Activated';
        cont2.ARC_RecurringMonthlyOrder__c=chargent2.Id;
        
        update cont;
        update cont2;
        // System.debug('cont'+ Order);
    }
    
    @isTest
    static void testOne(){
        String error;
        //vlocity_ins__GroupCensusMember__c censusMember = [SELECT Id,ARC_Age__c, vlocity_ins__Birthdate__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
       
        Test.startTest();
        try{
            AgesUpBatchClass testBatch = new AgesUpBatchClass();
            Database.executeBatch(testBatch);
        }catch(Exception e){
            error = e.getMessage();
        }
        Test.stopTest();
        
        System.assertEquals(true, String.isBlank(error));
    }
      @isTest
    static void testTwo(){
        vlocity_ins__GroupCensusMember__c censusMember = [SELECT Id,ARC_Age__c, vlocity_ins__Birthdate__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        Integer year = System.today().year() - 31;
        System.debug('censusMember.vlocity_ins__Birthdate__c' + censusMember.vlocity_ins__Birthdate__c);
        System.debug('censusMember.ARC_Age__c' + censusMember.ARC_Age__c);
        Date birthDate = Date.newInstance(year, System.today().month(), System.today().day());
     	censusMember.vlocity_ins__Birthdate__c = birthDate.addDays(30);
        update censusMember;
        String error;
        
        Test.startTest();
        try{
            AgesUpBatchClass testBatch = new AgesUpBatchClass();
            Database.executeBatch(testBatch);
        }catch(Exception e){
            error = e.getMessage();
        }
        Test.stopTest();
        
        System.assertEquals(true, String.isBlank(error));
    }
      @isTest
    static void testthree(){
        vlocity_ins__GroupCensusMember__c censusMember = [SELECT Id,vlocity_ins__Birthdate__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        Integer year = System.today().year() - 31;
        Date birthDate = Date.newInstance(year, System.today().month(), System.today().day());
     	censusMember.vlocity_ins__Birthdate__c = birthDate.addDays(14);
        update censusMember;
        String error;
        
        Test.startTest();
        try{
            AgesUpBatchClass testBatch = new AgesUpBatchClass();
            Database.executeBatch(testBatch);
        }catch(Exception e){
            error = e.getMessage();
        }
        Test.stopTest();
        
        System.assertEquals(true, String.isBlank(error));
    }
}