@isTest
public class AgesUpEmailBatchClassTest {
  @TestSetup
    static void mockData(){
        Date oggi = Date.today();
        Integer year = System.today().year() - 31;
        Date birthDate = Date.newInstance(year, System.today().month(), System.today().day());
        //Create Contact
        Contact contactRecord = new Contact(FirstName = 'Jack', LastName = 'Sparrow', Email = 'testemailcensusmember@membertest.com');
        insert contactRecord; 
        //Create Census Member
    	vlocity_ins__GroupCensusMember__c censusMember = ARC_TestUtility.createTestCensusMember(1)[0];
        censusMember.vlocity_ins__IsPrimaryMember__c = censusMember.ARC_ActiveMember__c = true;
        censusMember.vlocity_ins__Birthdate__c = birthDate.addDays(60);
        censusMember.vlocity_ins__ContactId__c = contactRecord.Id;
        censusMember.vlocity_ins__IsPrimaryMember__c =true;
        update censusMember;
        
        vlocity_ins__GroupCensusMember__c cMemb = [SELECT Id,vlocity_ins__CensusId__r.vlocity_ins__GroupId__c, vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        System.debug('CensusMemberId :' + cMemb.Id);
        Id accId = cMemb.vlocity_ins__CensusId__r.vlocity_ins__GroupId__c;
        Id censusId = cMemb.vlocity_ins__CensusId__c;
        Decimal subtotal=400.6;
        
        //Create Contract        
        Contract cont = new Contract(Name = 'Test', AccountId = accId, vlocity_ins__EnrollmentCensusId__c = censusId,ARC_EffectiveDate__c = Date.newInstance(2023, 12, 12));
        insert cont;
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
        Product2 product=new Product2(Name='WeShare',vlocity_ins__Type__c='Medical',vlocity_ins__SubType__c='PPO');
        insert product;
        vlocity_ins__ContractLineItem__c CLI=new vlocity_ins__ContractLineItem__c(Name = 'WeShare',vlocity_ins__ContractId__c=cont.Id,vlocity_ins__Product2Id__c=product.Id);
       	insert CLI;
        Ages_Up__c AgeUp=new Ages_Up__c();
        AgeUp.Name='Test';
        AgeUp.AgesUp_Census_Member_Name__c='Test';
        AgeUp.vlocity_Ins_CensusMemberId__c=cMemb.Id;
        AgeUp.Contract__c=cont.Id;
        AgeUp.Age_up_Created_Date__c=oggi;
        AgeUp.AgesUp_Birth_Date__c=birthDate.addDays(60);
        AgeUp.Draft_Date__c=birthDate.addDays(90);
        insert AgeUp;
        cont.Status = 'Activated';
        cont.ARC_RecurringMonthlyOrder__c=chargent.Id;
        cont.Ages_Up_Manuel_Delay__c=null;
        update cont;
        // System.debug('cont'+ Order);
    }
    
    @isTest
    static void testOne(){
        String error;
        vlocity_ins__GroupCensusMember__c censusMember = [SELECT Id,ARC_Age__c, vlocity_ins__Birthdate__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
       
        Test.startTest();
        try{
            AgesUpEmailBatchClass testBatch = new AgesUpEmailBatchClass();
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
            AgesUpEmailBatchClass testBatch = new AgesUpEmailBatchClass();
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
        Contract contract = [Select Id,Ages_Up_Manuel_Delay__c FROM Contract LIMIT 1];
        contract.Ages_Up_Manuel_Delay__c=Date.newInstance(2024, 1, 13);
        update contract;
        Integer year = System.today().year() - 31;
        Date birthDate = Date.newInstance(year, System.today().month(), System.today().day());
     	censusMember.vlocity_ins__Birthdate__c = birthDate.addDays(14);
        update censusMember;
        String error;
        
        Test.startTest();
        try{
            AgesUpEmailBatchClass testBatch = new AgesUpEmailBatchClass();
            Database.executeBatch(testBatch);
        }catch(Exception e){
            error = e.getMessage();
        }
        Test.stopTest();
        
        System.assertEquals(true, String.isBlank(error));
    }
}