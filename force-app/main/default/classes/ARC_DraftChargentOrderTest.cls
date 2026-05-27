@isTest
public without sharing class ARC_DraftChargentOrderTest {

    @TestSetup
    static void makeChargentData(){
    
     List<RecordType> RT = [ SELECT Id FROM RecordType WHERE sObjectType='ChargentBase__Gateway__c' AND Name = 'Authorize.net' AND isActive=true ];
        System.assertEquals(1, RT.size(), 'Expected a single rtype to be returned');
        //Create the Gateway
        ChargentBase__Gateway__c GW = new ChargentBase__Gateway__c();
        GW.Name = 'Chargent Test Gateway';
        GW.RecordTypeId = RT.get(0).Id;
        GW.ChargentBase__Available_Payment_Methods__c = 'Credit Card';
        GW.ChargentBase__Default_Payment_Method_for_PC__c = 'Credit Card';
        insert GW;

        //Create the Chargent Order
        ChargentOrders__ChargentOrder__c CO = new ChargentOrders__ChargentOrder__c();
        CO.ChargentOrders__Gateway__c = GW.Id;
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
        insert CO;
       
        //create transaction related to order 
        ChargentOrders__Transaction__c tr = new ChargentOrders__Transaction__c();
        tr.ChargentOrders__Order__c = CO.Id;
        insert tr;
    }

   
    @IsTest
    public static void ChargeTest() {
        Test.startTest();
        ChargentOrders__ChargentOrder__c chargeOrder = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        String response = ARC_DraftChargentOrder.callout(chargeOrder.Id, 'Test');
        System.assertEquals('Approved', response);
        Test.stopTest();
    }

    @IsTest
    public static void ChargeFlowTest() {
        Test.startTest();
        ChargentOrders__ChargentOrder__c chargeOrder = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        ARC_DraftChargentOrder.FlowInputs params = new ARC_DraftChargentOrder.FlowInputs();
        params.orderId = chargeOrder.Id;
        params.transactionExp = 'Test';
        List<ARC_DraftChargentOrder.FlowOutputs> results = ARC_DraftChargentOrder.chargeOrder(new List<ARC_DraftChargentOrder.FlowInputs>{ params });
        
        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess);
        System.assertEquals('Approved', results[0].responseStatus);
        Test.stopTest();
    }
    
    @IsTest
    public static void ChargeFlowTest_NullRequest() {
        Test.startTest();
        List<ARC_DraftChargentOrder.FlowOutputs> results = ARC_DraftChargentOrder.chargeOrder(null);
        
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        System.assert(results[0].errorMessage.contains('Request list cannot be null or empty'));
        Test.stopTest();
    }
    
    @IsTest
    public static void ChargeFlowTest_EmptyRequest() {
        Test.startTest();
        List<ARC_DraftChargentOrder.FlowOutputs> results = ARC_DraftChargentOrder.chargeOrder(new List<ARC_DraftChargentOrder.FlowInputs>());
        
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        System.assert(results[0].errorMessage.contains('Request list cannot be null or empty'));
        Test.stopTest();
    }
    
    @IsTest
    public static void ChargeFlowTest_BlankOrderId() {
        Test.startTest();
        ARC_DraftChargentOrder.FlowInputs params = new ARC_DraftChargentOrder.FlowInputs();
        params.orderId = '';
        params.transactionExp = 'Test';
        List<ARC_DraftChargentOrder.FlowOutputs> results = ARC_DraftChargentOrder.chargeOrder(new List<ARC_DraftChargentOrder.FlowInputs>{ params });
        
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        System.assert(results[0].errorMessage.contains('Order ID is required'));
        Test.stopTest();
    }
    
    @IsTest
    public static void ChargeFlowTest_InvalidOrderId() {
        Test.startTest();
        ARC_DraftChargentOrder.FlowInputs params = new ARC_DraftChargentOrder.FlowInputs();
        params.orderId = 'fakeId123';
        params.transactionExp = 'Test';
        List<ARC_DraftChargentOrder.FlowOutputs> results = ARC_DraftChargentOrder.chargeOrder(new List<ARC_DraftChargentOrder.FlowInputs>{ params });
        
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        System.assert(results[0].errorMessage.contains('Chargent Order not found'));
        Test.stopTest();
    }
    
    @IsTest
    public static void HandleResponse_EmptyJson() {
        ChargentOrders__ChargentOrder__c orderRec = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        
        Test.startTest();
        try {
            ARC_DraftChargentOrder.handleChargentResponse(orderRec.Id, '', 'Test');
            System.assert(false, 'Expected exception');
        } catch (ARC_DraftChargentOrder.ChargentException e) {
            System.assert(e.getMessage().contains('Empty response from Chargent API'));
        }
        Test.stopTest();
    }
    
    @IsTest
    public static void HandleResponse_MissingResponseStatus() {
        ChargentOrders__ChargentOrder__c orderRec = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        
        Test.startTest();
        try {
            ARC_DraftChargentOrder.handleChargentResponse(orderRec.Id, '{"someField":"value"}', 'Test');
            System.assert(false, 'Expected exception');
        } catch (ARC_DraftChargentOrder.ChargentException e) {
            System.assert(e.getMessage().contains('Response missing responseStatus field'));
        }
        Test.stopTest();
    }
    
    @IsTest
    public static void CoverRedBlock_HandleResponse() {
        ChargentOrders__ChargentOrder__c orderRec = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];

        String fakeJson = '{"responseStatus":"Approved"}';

        Test.startTest();
        String status = ARC_DraftChargentOrder.handleChargentResponse(
            orderRec.Id,
            fakeJson,
            'Test explanation'
        );
        Test.stopTest();

        System.assertEquals('Approved', status);
        
        ChargentOrders__Transaction__c updatedTr =
            [SELECT Transaction_Explanation__c
                FROM ChargentOrders__Transaction__c
               WHERE ChargentOrders__Order__c = :orderRec.Id
               ORDER BY CreatedDate DESC
               LIMIT 1 ];
        System.assertEquals('Test explanation', updatedTr.Transaction_Explanation__c);
    }
}