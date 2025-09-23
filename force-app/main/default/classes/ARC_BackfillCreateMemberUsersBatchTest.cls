@isTest
public class ARC_BackfillCreateMemberUsersBatchTest {

     @TestSetup
    public static void makeData(){

        List<Account> acc = ARC_TestUtility.createTestAccount(1,'ARC_IFPPersonAccount');
        acc[0].PersonBirthdate = Date.newInstance(1997, 11, 1); 
        acc[0].ARC_IsPrimaryMember__c = true;
        acc[0].IsActive = true;
        acc[0].vlocity_ins__Email__c = 'testEmail@email.com';
		update acc;
        
        Contact cont = [Select Id, Email From Contact WHERE AccountId =: acc[0].Id];
        
            
        List<vlocity_ins__GroupCensusMember__c> censMemb = ARC_TestUtility.createTestCensusMember(1);
        censMemb[0].ARC_PhysicalAddressState__c = 'CA';
        censMemb[0].vlocity_ins__IsPrimaryMember__c = true;
        censMemb[0].ARC_ActiveMember__c = true;
        censMemb[0].vlocity_ins__ContactId__c = cont.Id; 
        censMemb[0].vlocity_ins__FirstName__c = 'TestFirstName';
        censMemb[0].vlocity_ins__Birthdate__c = Date.newInstance(1994, 11, 1);
        censMemb[0].e123_member_id_from_policy__c = 'asd123';
        censMemb[0].vlocity_ins__Email__c = 'testEmail@email.com';
        update censMemb;     
        
        List<Contract> contract = ARC_TestUtility.createContracts(1);
        contract[0].vlocity_ins__EnrollmentCensusId__c = censMemb[0].vlocity_ins__CensusId__c;
        contract[0].ARC_EffectiveDate__c = System.today()+1;
        insert contract;
        
        ChargentOrders__ChargentOrder__c chargent = new ChargentOrders__ChargentOrder__c();
        chargent.ARC_Contract__c = contract[0].Id;
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

        contract[0].ARC_RecurringMonthlyOrder__c = chargent.Id;
        contract[0].Status = 'Awaiting Activation';
        update contract;

        contract[0].Status = 'Activated';
        update contract;
        
        Product2 product1 = new Product2();
        product1.Name = 'WeShare';
        product1.ProductCode = 'CS_FinanceVisitsFramework';
        product1.vlocity_ins__Type__c = 'Medical';
        product1.vlocity_ins__SubType__c = 'AIDD';
        
        insert product1;
        
        vlocity_ins__ContractLineItem__c cli1 =ARC_TestUtility.createTestContractLineItem(1)[0];
        cli1.vlocity_ins__ContractId__c= contract[0].Id;
        cli1.vlocity_ins__Product2Id__c = product1.Id;
        
        update cli1;
        
        vlocity_ins__GroupCensusMemberPlan__c gcmp1 = new vlocity_ins__GroupCensusMemberPlan__c();
        gcmp1.vlocity_ins__GroupCensusMemberId__c = censMemb[0].Id;
        gcmp1.vlocity_ins__ContractLineId__c = cli1.Id;
        gcmp1.Name = 'WeShare';
        insert gcmp1;
        
    }
    
     @isTest
    public static void sendEmail() {
       List<Account> acc = [Select Id from Account WHERE vlocity_ins__Email__c = 'testEmail@email.com'];
       Set<Id> accsId = new Set<Id>{acc[0].Id};
       System.debug('here '+acc);
       Test.startTest();
        //Execute schedule job
        ARC_SchedulePortalUserCreation scheduledClass = new ARC_SchedulePortalUserCreation();
        scheduledClass.execute(null); 
       Test.stopTest();
        
    }

        
}