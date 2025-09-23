@isTest
private class ARC_PaymentMethodChangesTest {

    @TestSetup
    static void makeData(){
        Account a = ARC_TestUtility.createTestAccount(1, 'ARC_IFPPersonAccount')[0];

        vlocity_ins__GroupCensusMember__c cm = ARC_TestUtility.createTestCensusMember(1)[0];
        cm.vlocity_ins__ContactId__c = [SELECT PersonContactId FROM Account WHERE Id =: a.Id].PersonContactId;
        update cm;

        Product2 p = ARC_TestUtility.createTestProducts(1)[0];
        p.vlocity_ins__Type__c = 'Medical';
        update p;

        Contract contract = ARC_TestUtility.createContracts(1)[0];
        insert contract;

        vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
        cli.vlocity_ins__Product2Id__c = p.Id;
        cli.vlocity_ins__ContractId__c = contract.Id;
        insert cli;

        vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c();
        gcmp.vlocity_ins__ContractLineId__c = cli.Id;
        gcmp.vlocity_ins__GroupCensusMemberId__c = cm.Id;
        insert gcmp;

        ChargentOrders__ChargentOrder__c chargent1=new ChargentOrders__ChargentOrder__c();
        chargent1.ARC_Contract__c = contract.Id;
        chargent1.ChargentOrders__Shipping__c = 232;
        chargent1.ChargentOrders__Tax__c  = 232;
        chargent1.ChargentOrders__Charge_Amount__c = 232;
        chargent1.ChargentOrders__Subtotal__c  = 232;
        chargent1.ChargentOrders__Charge_Date__c =  '01';
        chargent1.ChargentOrders__Payment_Status__c = 'Recurring';
        chargent1.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12);
        chargent1.ChargentOrders__Payment_Method__c = 'Credit Card';
        chargent1.ChargentOrders__Card_Last_4__c = '1234';
        chargent1.ChargentOrders__Card_Type__c = 'VISA';
        chargent1.ChargentOrders__Card_Expiration_Month__c = '12';
        chargent1.ChargentOrders__Card_Expiration_Year__c = '2024';
        chargent1.ChargentOrders__Tokenization__c = '12345678';
        chargent1.ChargentOrders__Description__c = 'Recurring Monthly Order';
        chargent1.ARC_UpdatePaymentMethod__c = true;
        chargent1.ChargentOrders__Billing_First_Name__c = 'Test';
        chargent1.ChargentOrders__Billing_Last_Name__c = 'User';
        insert chargent1;

        ChargentOrders__ChargentOrder__c chargent2=new ChargentOrders__ChargentOrder__c();
        chargent2.ARC_Contract__c = contract.Id;
        chargent2.ChargentOrders__Shipping__c = 232;
        chargent2.ChargentOrders__Tax__c  = 232;
        chargent2.ChargentOrders__Charge_Amount__c = 232;
        chargent2.ChargentOrders__Subtotal__c  = 232;
        chargent2.ChargentOrders__Charge_Date__c =  '01';
        chargent2.ChargentOrders__Payment_Status__c = 'Recurring';
        chargent2.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12);
        chargent2.ChargentOrders__Payment_Method__c = 'Credit Card';
        chargent2.ChargentOrders__Card_Last_4__c = '1234';
        chargent2.ChargentOrders__Card_Type__c = 'VISA';
        chargent2.ChargentOrders__Card_Expiration_Month__c = '12';
        chargent2.ChargentOrders__Card_Expiration_Year__c = '2024';
        chargent2.ChargentOrders__Tokenization__c = '12345678';
        chargent2.ChargentOrders__Description__c = 'Recurring Monthly Order';
        chargent2.ARC_UpdatePaymentMethod__c = true;
        chargent2.ChargentOrders__Billing_First_Name__c = 'Test';
        chargent2.ChargentOrders__Billing_Last_Name__c = 'User';
        insert chargent2;


        ChargentOrders__ChargentOrder__History objectHistory1 = new ChargentOrders__ChargentOrder__History();
        objectHistory1.ParentId = chargent2.Id;
        objectHistory1.Field = 'ChargentOrders__Billing_First_Name__c';
        insert objectHistory1;

        ChargentOrders__ChargentOrder__History objectHistory2 = new ChargentOrders__ChargentOrder__History();
        objectHistory2.ParentId = chargent2.Id;
        objectHistory2.Field = 'ChargentOrders__Billing_Last_Name__c';
        insert objectHistory2;
        
        ChargentOrders__ChargentOrder__History objectHistory3 = new ChargentOrders__ChargentOrder__History();
        objectHistory3.ParentId = chargent2.Id;
        objectHistory3.Field = 'ARC_LastPaymentMethodUpdate__c';
        insert objectHistory3;

    }

    @isTest
    static void getPaymentMethodUpdatesTest() {

        List<ChargentOrders__ChargentOrder__History> test = [SELECT Id FROM ChargentOrders__ChargentOrder__History];
        System.debug(test);

        Account a = [SELECT Id,Name,Firstname,Lastname FROM Account WHERE Firstname = 'Test' LIMIT 1];

        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('recordId', a.Id);

        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_PaymentMethodChanges.invokeMethod('getPaymentMethodUpdates', inputMap, outMap, options);

    }
}