@IsTest
public without sharing class ARC_VoidChargentOrderTest {

    @TestSetup
    static void makeChargentData(){

        List<RecordType> RT = [ SELECT Id FROM RecordType WHERE sObjectType='ChargentBase__Gateway__c' AND Name = 'Authorize.net' AND isActive=true ];
        System.assertEquals(1, RT.size(), 'Expected a single rtype to be returned');
        ChargentBase__Gateway__c GW = new ChargentBase__Gateway__c();
        GW.name='Chargent Test Gateway';
        GW.recordtypeID = RT.get(0).Id;
        GW.ChargentBase__Available_Payment_Methods__c = 'Credit Card';
        GW.ChargentBase__Default_Payment_Method_for_PC__c = 'Credit Card';
        insert GW;

        ChargentOrders__ChargentOrder__c CO = new ChargentOrders__ChargentOrder__c();
        CO.ChargentOrders__Gateway__c = GW.Id;
        CO.ChargentOrders__Description__c = 'Recurring Monthly Order';
        CO.ChargentOrders__Billing_Address__c = '870 Market St Suite 809';
        CO.ChargentOrders__Billing_Address_Line_2__c = null;
        CO.ChargentOrders__Billing_City__c = 'San Francisco';
        CO.ChargentOrders__Billing_Company__c = null;
        CO.ChargentOrders__Billing_Country__c = 'United States';
        CO.ChargentOrders__Billing_Email__c = 'name@email.com';
        CO.ChargentOrders__Billing_Fax__c = null;
        CO.ChargentOrders__Billing_First_Name__c = 'John';
        CO.ChargentOrders__Billing_Last_Name__c = 'Doe';
        CO.ChargentOrders__Billing_Phone__c = '4152751115';
        CO.ChargentOrders__Billing_State__c = 'CA';
        CO.ChargentOrders__Billing_State_Province__c = null;
        CO.ChargentOrders__Billing_Zip_Postal__c = '94102';
        CO.ChargentOrders__Subtotal__c = 25.00;
        CO.ChargentOrders__Card_Type__c = 'Visa';
        CO.ChargentOrders__Card_Number__c = '4111111111111111';
        CO.ChargentOrders__Card_Expiration_Month__c = '12';
        CO.ChargentOrders__Card_Expiration_Year__c = '26';
        CO.ChargentOrders__Payment_Method__c = 'Credit Card';
        CO.ChargentOrders__Charge_Amount__c = 10;
        insert CO;

        ChargentOrders__Transaction__c TR = ARC_TestUtility.createOneTransaction(10,'Charge',CO.Id);
        insert TR;
    }

    @isTest 
    public static void VoidTest(){ 

        Test.startTest();
        
            ChargentOrders__Transaction__c chargTransaction = [ SELECT Id FROM ChargentOrders__Transaction__c LIMIT 1 ];
            String response = ARC_VoidChargentOrder.callout(chargTransaction.id,'Test'); 
            Assert.areEqual('Test Void',response); 
    
        Test.stopTest();
    } 
    @isTest 
    public static void flowVoidTest(){
        Test.startTest();
        
            ChargentOrders__Transaction__c chargTransaction = [ SELECT Id FROM ChargentOrders__Transaction__c LIMIT 1 ];
            ARC_VoidChargentOrder.FlowInputs params = new ARC_VoidChargentOrder.FlowInputs();
            params.transactionId = chargTransaction.Id;
        	params.VoidExplanation = 'Test';
            
            ARC_VoidChargentOrder.voidOrder(new List<ARC_VoidChargentOrder.FlowInputs>{params});
      
        Test.stopTest();
    }
}