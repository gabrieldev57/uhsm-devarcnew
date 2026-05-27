@isTest
global class ARC_CreateAggregatorsPerYearTest {
    @isTest
    static void testBatchExecution() {
        // Setup test data

        // Create an account
        Account testGroupAccount = new Account(
            Name = 'Test Group Account',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Group'].Id
        );
        insert testGroupAccount;

        // Create a person account
        Account testPersonAccount = new Account(
            FirstName = 'Test Person',
            LastName = 'Account',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'ARC_IFPPersonAccount'].Id
        );
        insert testPersonAccount;

        // Create a contract in draft status associated with the account
        Contract draftContract = new Contract(
            Name = 'Test Contract',
            Status = 'Draft',
            ARC_ContractReason__c = 'Program Upgrade',
            StartDate = Date.today(),
            AccountId = testGroupAccount.Id
        );
        insert draftContract;

        // Create an insurance policy associated with the draft contract
        InsurancePolicy testPolicy = new InsurancePolicy(
            Name = 'Test Policy',
            ARC_Contract__c = draftContract.Id,
            NameInsuredId = testPersonAccount.Id
        );
        insert testPolicy;

        ARC_Aggregator__c testAggregator1 = new ARC_Aggregator__c();
        testAggregator1.Name = 'Individual AMCS';
        testAggregator1.ARC_Year__c = '2024';
        testAggregator1.ARC_CreatedIn__c = testPolicy.Id;

        ARC_Aggregator__c testAggregator2 = new ARC_Aggregator__c();
        testAggregator2.Name = 'Family AMCS';
        testAggregator2.ARC_FamilyCurrentValue__c = 0;
        testAggregator2.ARC_Year__c = '2024';
        testAggregator2.ARC_CreatedIn__c = testPolicy.Id;

        insert testAggregator1;
        insert testAggregator2;

        ChargentOrders__ChargentOrder__c testRecurringChargentOrder = new ChargentOrders__ChargentOrder__c();
        testRecurringChargentOrder.ARC_Contract__c = draftContract.Id;
        testRecurringChargentOrder.ChargentOrders__Shipping__c = 232;
        testRecurringChargentOrder.ChargentOrders__Tax__c  = 232;
        testRecurringChargentOrder.ChargentOrders__Charge_Amount__c = 232;
        testRecurringChargentOrder.ChargentOrders__Subtotal__c  = 232;
        testRecurringChargentOrder.ChargentOrders__Charge_Date__c =  '01';
        testRecurringChargentOrder.ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3);
        testRecurringChargentOrder.ChargentOrders__Payment_Status__c = 'Recurring';
        testRecurringChargentOrder.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12);
        testRecurringChargentOrder.ChargentOrders__Payment_Method__c = 'Credit Card';
        testRecurringChargentOrder.ChargentOrders__Card_Last_4__c = '1234';
        testRecurringChargentOrder.ChargentOrders__Card_Type__c = 'VISA';
        testRecurringChargentOrder.ChargentOrders__Card_Expiration_Month__c = '12';
        testRecurringChargentOrder.ChargentOrders__Card_Expiration_Year__c = '2024';
        testRecurringChargentOrder.ChargentOrders__Tokenization__c = '12345678';
        testRecurringChargentOrder.ChargentOrders__Description__c = 'Recurring Monthly Order';

    
        insert testRecurringChargentOrder;

        // Update the contract to activated and assing a recurring order
        draftContract.Status = 'Activated';
        draftContract.ARC_RecurringMonthlyOrder__c = testRecurringChargentOrder.Id;
        update draftContract;

        Test.startTest();
        // Run the batch
        ARC_CreateAggregatorsPerYear batch = new ARC_CreateAggregatorsPerYear();
        Database.executeBatch(batch);
        Test.stopTest();
    }
}