@isTest
public class ARC_BackfillAEMasterCommissionTest {
    
    @TestSetup
    public static void makeData(){

        Date lastMonth = Date.today();

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(Name='censusTest',vlocity_ins__GroupId__c=acc.Id);
        insert census;
        
        User thisUser = [SELECT Id FROM User WHERE Agent_Role__c = 'Account Executive' AND IsActive = true AND Profile.Name != 'Member Community Profile' LIMIT 1];
        
        Contract con = ARC_TestUtility.createContractsAA(1)[0];
        con.vlocity_ins__EnrollmentCensusId__c=census.Id;
        con.AccountId=acc.Id;
        con.ARC_Selling_Agent__c = thisUser.Id;
        con.ARC_ContractReason__c = 'New Application';
        con.ARC_EffectiveDate__c = lastMonth.addDays(-30);
        insert con;        
        
        Product2 prod = new Product2();
        prod.Name = 'UHSM Gold $5K';
        prod.ProductCode = 'PROG_UHSMGold';
        insert prod;

        vlocity_ins__ContractLineItem__c plan = new vlocity_ins__ContractLineItem__c();
        plan.Name =prod.Name ;
        plan.vlocity_ins__Product2Id__c = prod.Id;
        plan.vlocity_ins__ContractId__c = con.Id;
        //unit price 
        insert plan;

        ChargentOrders__ChargentOrder__c chargent = new ChargentOrders__ChargentOrder__c();
        chargent.ARC_Contract__c = con.Id;
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

        ChargentOrders__Transaction__c t = ARC_TestUtility.createOneTransaction(2,'Charge',chargent.Id);
        insert t;

        con.Status = 'Terminated';
        update con;    
    }


    @isTest
    public static void createCommision() {

       List <Contract> contractList = [SELECT Id FROM Contract];    
       Test.startTest();
       Database.executeBatch(new ARC_BackfillAEMasterCommission());
       Test.stopTest();   
    }

}