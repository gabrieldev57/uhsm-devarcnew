@isTest
public with sharing class ARC_OneTimeChargeHandlerTest {


    @TestSetup
    static void makeChargentData(){
        
        //Query for the Account record types
        List<RecordType> RT = [ SELECT Id FROM RecordType WHERE sObjectType='ChargentBase__Gateway__c' AND Name = 'Authorize.net' AND isActive=true ];
        System.assertEquals(1, RT.size(), 'Expected a single rtype to be returned');
        //Create the Gateway
        ChargentBase__Gateway__c GW = new ChargentBase__Gateway__c();
        GW.name='Chargent Test Gateway';
        GW.recordtypeID = RT.get(0).Id;
        GW.ChargentBase__Available_Payment_Methods__c = 'Credit Card';
        GW.ChargentBase__Default_Payment_Method_for_PC__c = 'Credit Card';
        insert GW;

        Id currentUserId = UserInfo.getUserId();

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contract con = new Contract(AccountId = acc.Id, ARC_EffectiveDate__c = date.newInstance(2022, 10, 10), ARC_ContractReason__c = 'New Application', ARC_Selling_Agent__c = currentUserId, CustomerSignedDate = Date.today(), vlocity_ins__LastDocuSignEnvelopeStatus__c = 'Completed');
        insert con;

        //Create the Chargent Order
        ChargentOrders__ChargentOrder__c CO = new ChargentOrders__ChargentOrder__c();
        CO.ChargentOrders__Gateway__c = GW.Id;
        CO.ChargentOrders__Billing_Address__c = '870 Market St Suite 809';
        CO.ChargentOrders__Billing_Address_Line_2__c = NULL;
        CO.ChargentOrders__Billing_City__c = 'San Francisco';
        CO.ChargentOrders__Billing_Company__c = Null;
        CO.ChargentOrders__Billing_Country__c = 'United States';
        CO.ChargentOrders__Billing_Email__c = 'name@email.com';
        CO.ChargentOrders__Billing_Fax__c = Null;
        CO.ChargentOrders__Billing_First_Name__c = 'John';
        CO.ChargentOrders__Billing_Last_Name__c = 'Doe';
        CO.ChargentOrders__Billing_Phone__c = '4152751115';
        CO.ChargentOrders__Billing_State__c = 'CA';
        CO.ChargentOrders__Billing_State_Province__c = Null;
        CO.ChargentOrders__Billing_Zip_Postal__c = '94102';
        CO.ChargentOrders__Subtotal__c = 25.00;
        CO.ChargentOrders__Card_Type__c = 'Visa';
        CO.ChargentOrders__Card_Number__c = '4111111111111111';
        CO.ChargentOrders__Card_Expiration_Month__c = '12';
        CO.ChargentOrders__Card_Expiration_Year__c = '26';
        CO.ChargentOrders__Payment_Method__c = 'Credit Card';
        CO.ARC_Contract__c = con.Id;
        insert CO;
    }

    @isTest
    static void testCreateOneTimeChargeUseRecurring() {
        // Test data setup
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('useRecurringOrder', true);
        inputMap.put('chargeFeeAmount', 100.0);
        inputMap.put('reason', 'Test Reason');
        Map<String, Object> contractOrders = new Map<String, Object>{
            'ARC_OneTimeFeeOrder__c' => [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1].Id,
            'ARC_RecurringMonthlyOrder__c' => [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1].Id,
            'ARC_AppFeeOrder__c' => [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1].Id
        };
        inputMap.put('contractOrders', contractOrders);

        // Invoke the method
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        ARC_OneTimeChargeHandler.createOneTimeCharge(inputMap, outputMap, options);

        // Assertions

    }
        @isTest
    static void testCreateOneTimeChargeNotUseRecurring() {
        // Test data setup
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('useRecurringOrder', false);
        inputMap.put('chargeFeeAmount', 100.0);
        inputMap.put('reason', 'Test Reason');
        Map<String, Object> contractOrders = new Map<String, Object>{
            'ARC_OneTimeFeeOrder__c' => [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1].Id,
            'ARC_RecurringMonthlyOrder__c' => [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1].Id,
            'ARC_AppFeeOrder__c' => [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1].Id
        };
        inputMap.put('contractOrders', contractOrders);

        // Invoke the method
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        ARC_OneTimeChargeHandler.createOneTimeCharge(inputMap, outputMap, options);

        // Assertions

    }

        @isTest
    static void testCreateOneTimeChargeNotUseRecurringDoNotHavePreviousOneTimeFeeOrder() {
        // Test data setup
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('useRecurringOrder', false);
        inputMap.put('chargeFeeAmount', 100.0);
        inputMap.put('reason', 'Test Reason');
        Map<String, Object> contractOrders = new Map<String, Object>{
            'ARC_OneTimeFeeOrder__c' => null,
            'ARC_RecurringMonthlyOrder__c' => [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1].Id,
            'ARC_AppFeeOrder__c' => [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1].Id
        };
        inputMap.put('contractOrders', contractOrders);

        // Invoke the method
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        ARC_OneTimeChargeHandler.createOneTimeCharge(inputMap, outputMap, options);

        // Assertions

    }

    @isTest
    static void testLeaveOrderAsBefore() {
        // Test data setup
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> orderBackup = new Map<String, Object>();
        orderBackup.put('Id', [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1].Id);
        orderBackup.put('ChargentOrders__Subtotal__c', 100.0);
        orderBackup.put('ChargentOrders__Charge_Amount__c', 100.0);
        orderBackup.put('ChargentOrders__Description__c', 'Test Description');
        inputMap.put('orderBackup', orderBackup);

        // Invoke the method
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        ARC_OneTimeChargeHandler.leaveOrderAsBefore(inputMap, outputMap, options);


    }
}