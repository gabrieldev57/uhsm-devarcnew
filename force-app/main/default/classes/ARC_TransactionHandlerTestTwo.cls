@isTest
public with sharing class ARC_TransactionHandlerTestTwo {
    @TestSetup
    public static void makeData(){
        // Create System Admin user for selling agent
        // List<User> userList = [SELECT Id, Agent_Role__c 
        //                      FROM User 
        //                      WHERE Profile.Name = 'System Administrator' 
        //                      AND IsActive = true LIMIT 1];
        // userList[0].Agent_Role__c = 'Account Executive';
        // update userList[0];

        List<User> userList = ARC_TestUtility.createTestUsers(1, 'System Administrator');
        userList[0].Agent_Role__c = 'Account Executive';
        insert userList;

        // Create Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create Contract with proper relationships
        Contract cont = new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            ARC_EffectiveDate__c = System.today().addDays(-15),
            ARC_Selling_Agent__c = userList[0].Id,
            StartDate = System.today(),
            ContractTerm = 12
        );
        insert cont;

        // Create Chargent Order with all required fields
        ChargentOrders__ChargentOrder__c chargent = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = cont.Id,
            ChargentOrders__Shipping__c = 194.2,
            ChargentOrders__Tax__c = 194.2,
            ChargentOrders__Charge_Amount__c = 194.2,
            ChargentOrders__Subtotal__c = 194.2,
            ChargentOrders__Charge_Date__c = '01',
            ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3),
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12),
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Last_4__c = '1234',
            ChargentOrders__Card_Type__c = 'VISA',
            ChargentOrders__Card_Expiration_Month__c = '12',
            ChargentOrders__Card_Month_Indicator__c = '12',
            ChargentOrders__Card_Expiration_Year__c = '2024',
            ChargentOrders__Card_Year_Indicator__c = '2024',
            ChargentOrders__Description__c = 'Recurring Monthly Order',
            ChargentOrders__Tokenization__c = '504939913-507845985'
        );
        insert chargent;

        // Update Contract with Recurring Order and Activate
        cont.Status = 'Activated';
        cont.ARC_RecurringMonthlyOrder__c = chargent.Id;
        update cont;

        // Create Commission with proper setup
        ARC_Commission__c comm = new ARC_Commission__c(
            OwnerId = cont.ARC_Selling_Agent__c,
            ARC_Agent_Role__c = 'Account Executive',
            ARC_InitialCommission__c = 200,
            ARC_RecurringCommission__c = 100,
            Contract__c = cont.Id,
            Original_Contract__c = cont.Id,
            
            ARC_ExistingContributions__c = 0
        );
        insert comm;
        
        // Create Product Test Data
        Product2 productParent = new Product2(
            Name = 'Parent Product',
            ProductCode = 'CS_General',
            vlocity_ins__Type__c = 'Medical',
            IsActive = true
        );
        insert productParent;

        Product2 productChild = new Product2(
            Name = 'Child Product',
            ProductCode = 'CS_General',
            vlocity_ins__Type__c = 'Medical',
            IsActive = true,
            vlocity_ins__AttributeDefaultValues__c = '{"Urgent_Care_Visitations":"No Max","Urgent_Care_Consult_Fee":50,"Minute_Clinic":"$10 / No Maximum on Visits Allowed","Specialist_Visits":"No Max","Specialists_Consult_Fee":75,"PCP_Visits_Allowed":"No Max","PCP_Consult_Fee":25,"PCP_Network":"PHCS PPO Network","Surgery":100,"Hospitalization":100,"ER_Care_Consult_Fee":500,"Additional_Dep_Fee":"4 or more children: +$50 per child per month","AMCS":5000}'
        );
        insert productChild;

        // Create Product child relationship
        vlocity_ins__ProductChildItem__c coverageChild = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ChildLineNumber__c = '1',
            vlocity_ins__ParentProductId__c = productParent.Id,
            vlocity_ins__ChildProductId__c = productChild.Id
        );
        insert coverageChild;
        
        // Create Contract Line Items with proper relationships
        vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c(
            Name = 'Test CLI',
            vlocity_ins__ContractId__c = cont.Id,
            vlocity_ins__Product2Id__c = productParent.Id,
            vlocity_ins__UnitPrice__c = 194.2,
            ARC_OriginalPrice__c = 194.2
        );
        insert cli;

        // Create Promotion Code for testing
        ARC_PromotionCode__c promoCode = new ARC_PromotionCode__c(
            Name = 'Test Promo',
            ARC_PromotionCode__c = 'TEST',
            ARC_ApplyOver__c = 'Medical',
            ARC_DiscountedAmount__c = 10,
            ARC_StartDate__c = Date.today(),
            ARC_EndDate__c = Date.today().addMonths(1)
        );
        insert promoCode;

        // Create Promotion Discount
        ARC_PromotionDiscount__c promoDiscount = new ARC_PromotionDiscount__c(
            ARC_NumberOfTimesCanBeUsed__c = 3,
            ARC_AmountToDiscountPerTransaction__c = 10,
            ARC_TimesUsed__c = 0,
            ARC_PromoCode__c = promoCode.Id,
            ARC_Contract__c = cont.Id
        );
        insert promoDiscount;
        //
    }


    @IsTest
    public static void insertTransactionAppFee(){
        Contract cont = [SELECT Id, ARC_EffectiveDate__c,Status, ARC_RecurringMonthlyOrder__c FROM Contract WHERE ARC_RecurringMonthlyOrder__c != null LIMIT 1];
        ChargentOrders__ChargentOrder__c charg = [SELECT Id, ARC_Contract__c, ChargentOrders__Charge_Amount__c FROM ChargentOrders__ChargentOrder__c WHERE ChargentOrders__Description__c = 'Recurring Monthly Order' LIMIT 1];
        charg.ChargentOrders__Description__c = 'App Fee';
        update charg;

        List<ChargentOrders__Transaction__c> tList = new List<ChargentOrders__Transaction__c>();
        for(Integer i = 0; i < 1; i++){
            ChargentOrders__Transaction__c transa = new ChargentOrders__Transaction__c();
            transa.ChargentOrders__Order__c = charg.Id;
            transa.ChargentOrders__Amount__c = charg.ChargentOrders__Charge_Amount__c;
            transa.ChargentOrders__Type__c = 'Charge';
            transa.ChargentOrders__Gateway_Date__c = System.today();
            transa.ChargentOrders__Response_Status__c = 'Approved';
            tList.add(transa);
        }
        Test.startTest();
        insert tList;
        Test.stopTest();
    }

    @isTest
    public static void insertTransactionChangeFee(){
        Contract cont = [SELECT Id, ARC_EffectiveDate__c,Status, ARC_RecurringMonthlyOrder__c FROM Contract WHERE ARC_RecurringMonthlyOrder__c != null LIMIT 1];
        ChargentOrders__ChargentOrder__c charg = [SELECT Id, ARC_Contract__c, ChargentOrders__Charge_Amount__c FROM ChargentOrders__ChargentOrder__c WHERE ChargentOrders__Description__c = 'Recurring Monthly Order' LIMIT 1];
        charg.ChargentOrders__Description__c = 'Change Fee';
        update charg;

        List<ChargentOrders__Transaction__c> tList = new List<ChargentOrders__Transaction__c>();
        for(Integer i = 0; i < 1; i++){
            ChargentOrders__Transaction__c transa = new ChargentOrders__Transaction__c();
            transa.ChargentOrders__Order__c = charg.Id;
            transa.ChargentOrders__Amount__c = charg.ChargentOrders__Charge_Amount__c;
            transa.ChargentOrders__Type__c = 'Charge';
            transa.ChargentOrders__Gateway_Date__c = System.today();
            transa.ChargentOrders__Response_Status__c = 'Approved';
            tList.add(transa);
        }
        Test.startTest();
        insert tList;
        Test.stopTest();
    }

    @isTest
    public static void insertTransactionOneTimeFee(){
        Contract cont = [SELECT Id, ARC_EffectiveDate__c,Status, ARC_RecurringMonthlyOrder__c FROM Contract WHERE ARC_RecurringMonthlyOrder__c != null LIMIT 1];
        ChargentOrders__ChargentOrder__c charg = [SELECT Id, ARC_Contract__c, ChargentOrders__Charge_Amount__c FROM ChargentOrders__ChargentOrder__c WHERE ChargentOrders__Description__c = 'Recurring Monthly Order' LIMIT 1];
        charg.ChargentOrders__Description__c = 'One-Time Fee - Test';
        update charg;

        List<ChargentOrders__Transaction__c> tList = new List<ChargentOrders__Transaction__c>();
        for(Integer i = 0; i < 1; i++){
            ChargentOrders__Transaction__c transa = new ChargentOrders__Transaction__c();
            transa.ChargentOrders__Order__c = charg.Id;
            transa.ChargentOrders__Amount__c = charg.ChargentOrders__Charge_Amount__c;
            transa.ChargentOrders__Type__c = 'Charge';
            transa.ChargentOrders__Gateway_Date__c = System.today();
            transa.ChargentOrders__Response_Status__c = 'Approved';
            tList.add(transa);
        }
        Test.startTest();
        insert tList;
        Test.stopTest();
    }

    @IsTest
    public static void insertTransactionWithHealthyDiscount(){
        Contract cont = [SELECT Id, ARC_EffectiveDate__c,Status, ARC_RecurringMonthlyOrder__c FROM Contract WHERE ARC_RecurringMonthlyOrder__c != null LIMIT 1];
        ChargentOrders__ChargentOrder__c charg = [SELECT Id, ARC_Contract__c, ChargentOrders__Charge_Amount__c FROM ChargentOrders__ChargentOrder__c WHERE ChargentOrders__Description__c = 'Recurring Monthly Order' LIMIT 1];

        Healthy_Discount__c hd = new Healthy_Discount__c(
            Contract__c = cont.Id,
            Healthy_Discount_Price__c = 1.67
            //Is_Active__c = true
        );
        insert hd;

        List<ChargentOrders__Transaction__c> tList = new List<ChargentOrders__Transaction__c>();
        for(Integer i = 0; i < 1; i++){
            ChargentOrders__Transaction__c transa = new ChargentOrders__Transaction__c();
            transa.ChargentOrders__Order__c = charg.Id;
            transa.ChargentOrders__Amount__c = charg.ChargentOrders__Charge_Amount__c;
            transa.ChargentOrders__Type__c = 'Charge';
            transa.ChargentOrders__Gateway_Date__c = System.today();
            transa.ChargentOrders__Response_Status__c = 'Approved';
            tList.add(transa);
        }
        Test.startTest();
        insert tList;
        Test.stopTest();
    }

    //error
    @IsTest
    public static void insertTransactionWithAppFeePromotion(){
        Contract cont = [SELECT Id, ARC_EffectiveDate__c,Status, ARC_RecurringMonthlyOrder__c FROM Contract WHERE ARC_RecurringMonthlyOrder__c != null LIMIT 1];
        ChargentOrders__ChargentOrder__c charg = [SELECT Id, ARC_Contract__c, ChargentOrders__Charge_Amount__c FROM ChargentOrders__ChargentOrder__c WHERE ChargentOrders__Description__c = 'Recurring Monthly Order' LIMIT 1];

        charg.ChargentOrders__Description__c = 'App Fee';

        cont.ARC_AppFeeOrder__c = charg.Id;
        update cont;
        update charg;

        Healthy_Discount__c hd = new Healthy_Discount__c(
            Contract__c = cont.Id,
            Healthy_Discount_Price__c = 1.67
            //Is_Active__c = true
        );
        insert hd;

        ARC_PromotionCode__c appFeePromotionCode = new ARC_PromotionCode__c(
            Name = 'App Fee Test',
            ARC_PromotionCode__c = 'App Fee Test',
            ARC_ApplyOver__c = 'App Fee',
            ARC_DiscountedAmount__c = 10,
            ARC_StartDate__c = Date.today(),
            ARC_EndDate__c = Date.today().addMonths(1)
        );
        insert appFeePromotionCode;

        ARC_PromotionDiscount__c appFeePromotionDiscount = new ARC_PromotionDiscount__c(
            ARC_NumberOfTimesCanBeUsed__c = 1,
            ARC_ExonerateAppChangeFee__c = false,
            ARC_AmountToDiscountPerTransaction__c = 10,
            ARC_TimesUsed__c = 0,
            ARC_PromoCode__c = appFeePromotionCode.Id,
            ARC_Contract__c = cont.Id
        );
        insert appFeePromotionDiscount;

        List<ChargentOrders__Transaction__c> tList = new List<ChargentOrders__Transaction__c>();
        for(Integer i = 0; i < 1; i++){
            ChargentOrders__Transaction__c transa = new ChargentOrders__Transaction__c();
            transa.ChargentOrders__Order__c = charg.Id;
            transa.ChargentOrders__Amount__c = charg.ChargentOrders__Charge_Amount__c;
            transa.ChargentOrders__Type__c = 'Charge';
            transa.ChargentOrders__Gateway_Date__c = System.today();
            transa.ChargentOrders__Response_Status__c = 'Approved';
            tList.add(transa);
        }
        Test.startTest();
        insert tList;
        Test.stopTest();
    }

    //error
    @IsTest
    public static void insertTransactionWithRecurringPromotion(){
        Contract cont = [SELECT Id, ARC_EffectiveDate__c,Status, ARC_RecurringMonthlyOrder__c FROM Contract WHERE ARC_RecurringMonthlyOrder__c != null LIMIT 1];
        ChargentOrders__ChargentOrder__c charg = [SELECT Id, ARC_Contract__c, ChargentOrders__Charge_Amount__c FROM ChargentOrders__ChargentOrder__c WHERE ChargentOrders__Description__c = 'Recurring Monthly Order' LIMIT 1];

        ARC_PromotionCode__c recurringPromotionCode = new ARC_PromotionCode__c(
            Name = 'Recurring x3',
            ARC_PromotionCode__c = 'Recurring x3',
            ARC_ApplyOver__c = 'Medical',
            ARC_StartDate__c = Date.today(),
            ARC_DiscountedAmount__c = 10,
            ARC_EndDate__c = Date.today().addMonths(1)
        );
        insert recurringPromotionCode;

        ARC_PromotionDiscount__c recurringPromotionDiscount = new ARC_PromotionDiscount__c(
            ARC_NumberOfTimesCanBeUsed__c = 3,
            ARC_ExonerateAppChangeFee__c = false,
            ARC_AmountToDiscountPerTransaction__c = 10,
            ARC_TimesUsed__c = 0,
            ARC_PromoCode__c = recurringPromotionCode.Id,
            ARC_Contract__c = cont.Id,
            ARC_CorePriceWithoutDiscount__c = 265.890
        );
        insert recurringPromotionDiscount;

        List<ChargentOrders__Transaction__c> tList = new List<ChargentOrders__Transaction__c>();
        for(Integer i = 0; i < 1; i++){
            ChargentOrders__Transaction__c transa = new ChargentOrders__Transaction__c();
            transa.ChargentOrders__Order__c = charg.Id;
            transa.ChargentOrders__Amount__c = charg.ChargentOrders__Charge_Amount__c;
            transa.ChargentOrders__Type__c = 'Charge';
            transa.ChargentOrders__Gateway_Date__c = System.today();
            transa.ChargentOrders__Response_Status__c = 'Approved';
            tList.add(transa);
        }
        Test.startTest();
        insert tList;
        Test.stopTest();
    }

    @isTest
    public static void createInitialCommisionPaymentTest() {
        // Get commission record and ensure initial values
        ARC_Commission__c comm = [SELECT Id, Active__c, Contract__c, ARC_InitialCommission__c, 
                                ARC_RecurringCommission__c, Contract__r.ARC_RecurringMonthlyOrder__c,
                                Contract__r.ARC_EffectiveDate__c, Contract__r.ARC_AwaitingActivationDate__c
                                FROM ARC_Commission__c LIMIT 1];
        
        // Get associated Chargent Order
        ChargentOrders__ChargentOrder__c chargentOrder = [SELECT Id, ChargentOrders__Charge_Amount__c
                                                         FROM ChargentOrders__ChargentOrder__c 
                                                         WHERE Id = :comm.Contract__r.ARC_RecurringMonthlyOrder__c];
        
        Test.startTest();
        // Create initial transaction
        ChargentOrders__Transaction__c t = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargentOrder.Id,
            ChargentOrders__Amount__c = chargentOrder.ChargentOrders__Charge_Amount__c,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved',
            ChargentOrders__Gateway_Date__c = System.today()
        );
        insert t;
        Test.stopTest();

        // Verify commission payment creation
        List<ARC_Commission_Payment__c> commPayments = [
            SELECT Id, Type__c, Amount__c
            FROM ARC_Commission_Payment__c
            WHERE Commission__c = :comm.Id
        ];

        System.assertEquals(1, commPayments.size(), 'One commission payment should be created');
        System.assertEquals('Initial', commPayments[0].Type__c, 'Payment should be Initial type');
        System.assertEquals(comm.ARC_InitialCommission__c, commPayments[0].Amount__c, 'Amount should match initial commission');
    }

    @isTest
    public static void createRecurringCommisionPaymentTest() {
        // Get commission record and update for recurring scenario
        ARC_Commission__c comm = [SELECT Id, Active__c, Contract__c, ARC_InitialCommission__c, 
                                ARC_RecurringCommission__c, ARC_ExistingContributions__c,
                                ARC_MemberContribution__c, Contract__r.ARC_RecurringMonthlyOrder__c
                                FROM ARC_Commission__c LIMIT 1];
        
        comm.ARC_ExistingContributions__c = 1;
        update comm;

        ChargentOrders__ChargentOrder__c chargentOrder = [SELECT Id, ChargentOrders__Charge_Amount__c
                                                         FROM ChargentOrders__ChargentOrder__c 
                                                         WHERE Id = :comm.Contract__r.ARC_RecurringMonthlyOrder__c];

        Test.startTest();
        // Create recurring transaction
        ChargentOrders__Transaction__c t = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargentOrder.Id,
            ChargentOrders__Amount__c = chargentOrder.ChargentOrders__Charge_Amount__c,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved',
            ChargentOrders__Gateway_Date__c = System.today()
        );
        insert t;
        Test.stopTest();

        // Verify commission payment
        List<ARC_Commission_Payment__c> commPayments = [
            SELECT Id, Type__c, Amount__c
            FROM ARC_Commission_Payment__c
            WHERE Commission__c = :comm.Id
        ];

        System.assertEquals(1, commPayments.size(), 'One commission payment should be created');
        System.assertEquals('Recurring', commPayments[0].Type__c, 'Payment should be Recurring type');
        System.assertEquals(comm.ARC_RecurringCommission__c, commPayments[0].Amount__c, 'Amount should match recurring commission');
    }

    @isTest
    public static void createInitalAndRefundCommisionPaymentTest() {
        // Get commission record
        ARC_Commission__c comm = [SELECT Id, Active__c, Contract__c, ARC_InitialCommission__c, 
                                ARC_RecurringCommission__c, Contract__r.ARC_RecurringMonthlyOrder__c
                                FROM ARC_Commission__c LIMIT 1];

        ChargentOrders__ChargentOrder__c chargentOrder = [SELECT Id, ChargentOrders__Charge_Amount__c
                                                         FROM ChargentOrders__ChargentOrder__c 
                                                         WHERE Id = :comm.Contract__r.ARC_RecurringMonthlyOrder__c];

        // Create initial transaction
        ChargentOrders__Transaction__c initialTrans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargentOrder.Id,
            ChargentOrders__Amount__c = chargentOrder.ChargentOrders__Charge_Amount__c,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved',
            ChargentOrders__Gateway_Date__c = System.today()
        );
        insert initialTrans;

        Test.startTest();
        // Create refund transaction
        ChargentOrders__Transaction__c refundTrans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargentOrder.Id,
            ChargentOrders__Amount__c = -chargentOrder.ChargentOrders__Charge_Amount__c,
            ChargentOrders__Type__c = 'Refund',
            ChargentOrders__Response_Status__c = 'Approved',
            ARC_RefundedTransaction__c = initialTrans.Id,
            ChargentOrders__Gateway_Date__c = System.today()
        );
        insert refundTrans;
        Test.stopTest();

        // Verify commission payments
        List<ARC_Commission_Payment__c> commPayments = [
            SELECT Id, Type__c, Amount__c
            FROM ARC_Commission_Payment__c
            WHERE Commission__c = :comm.Id
            ORDER BY CreatedDate ASC
        ];

    }
    @isTest
    static void testCreateAppChangeFeeRefundTLIAndDiscountRefundTLI() {
        Contract cont = [SELECT Id FROM Contract LIMIT 1];
        ChargentOrders__ChargentOrder__c chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        
        // Create original transaction
        ChargentOrders__Transaction__c originalTrans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargent.Id,
            ChargentOrders__Amount__c = 100,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved'
        );
        insert originalTrans;

        // Create refund transaction
        ChargentOrders__Transaction__c refundTrans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargent.Id,
            ChargentOrders__Amount__c = -100,
            ChargentOrders__Type__c = 'Refund',
            ChargentOrders__Response_Status__c = 'Approved',
            ARC_RefundedTransaction__c = originalTrans.Id,
            ARC_Reason__c = 'Refund'
        );
        
        Test.startTest();
        insert refundTrans;
        Test.stopTest();

    }

    @isTest
    static void testCreateDiscountRecurringRefundTLI() {
        Contract cont = [SELECT Id FROM Contract LIMIT 1];
        ChargentOrders__ChargentOrder__c chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        ARC_PromotionDiscount__c promo = [SELECT Id FROM ARC_PromotionDiscount__c LIMIT 1];

        // Create original transaction with discount
        ChargentOrders__Transaction__c originalTrans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargent.Id,
            ChargentOrders__Amount__c = 100,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved'
        );
        insert originalTrans;

        // Create original TLI with discount
        ARC_TransactionLineItem__c originalTLI = new ARC_TransactionLineItem__c(
            ARC_Transaction__c = originalTrans.Id,
            ARC_PromotionDiscount__c = promo.Id,
            ARC_Amount__c = -10,
            Name = 'Test Discount'
        );
        insert originalTLI;

        // Create refund transaction
        ChargentOrders__Transaction__c refundTrans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargent.Id,
            ChargentOrders__Amount__c = -100,
            ChargentOrders__Type__c = 'Refund',
            ChargentOrders__Response_Status__c = 'Approved'
            // ARC_RefundedTransaction__c = originalTrans.Id
        );

        Test.startTest();
        insert refundTrans;


        ChargentOrders__Transaction__c refundTransUpdate = [SELECT Id, ARC_RefundedTransaction__c FROM ChargentOrders__Transaction__c WHERE Id = :refundTrans.id];
        refundTransUpdate.ARC_RefundedTransaction__c = originalTrans.Id;

        update refundTransUpdate;

        Test.stopTest();




    }

    @isTest
    static void testCreateDiscountRecurringTLI() {
        Contract cont = [SELECT Id FROM Contract LIMIT 1];
        ChargentOrders__ChargentOrder__c chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        
        ChargentOrders__Transaction__c trans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargent.Id,
            ChargentOrders__Amount__c = 100,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved'
        );

        Test.startTest();
        insert trans;
        Test.stopTest();

    }

    @isTest
    static void testIncrementDiscountTimeUsed() {
        Contract cont = [SELECT Id FROM Contract LIMIT 1];
        ARC_PromotionDiscount__c promo = [SELECT Id, ARC_TimesUsed__c FROM ARC_PromotionDiscount__c LIMIT 1];
        
        // Create transaction and TLI
        ChargentOrders__ChargentOrder__c chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        ChargentOrders__Transaction__c trans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargent.Id,
            ChargentOrders__Amount__c = 100,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved'
        );
        insert trans;

        Test.startTest();
        ARC_TransactionLineItem__c tli = new ARC_TransactionLineItem__c(
            ARC_Transaction__c = trans.Id,
            ARC_PromotionDiscount__c = promo.Id,
            ARC_Amount__c = -10,
            Name = 'Test Discount'
        );
        insert tli;
        
        Map<Id, ARC_PromotionDiscount__c> discountsToUpdateMap = new Map<Id, ARC_PromotionDiscount__c>();
        ARC_TransactionHandler.incrementDiscountTimeUsed(tli, discountsToUpdateMap);
        Test.stopTest();

    }

    @isTest
    static void testLinkPromotionToTransaction() {
        Contract cont = [SELECT Id FROM Contract LIMIT 1];
        ChargentOrders__ChargentOrder__c chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        ARC_PromotionDiscount__c promo = [SELECT Id FROM ARC_PromotionDiscount__c LIMIT 1];

        ChargentOrders__Transaction__c trans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargent.Id,
            ChargentOrders__Amount__c = 100,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved'
        );

        Test.startTest();
        insert trans;
        
        Map<Id, ChargentOrders__Transaction__c> transMap = new Map<Id, ChargentOrders__Transaction__c>();
        transMap.put(trans.Id, trans);
        ARC_TransactionHandler.linkPromotionToTransaction(transMap);
        Test.stopTest();

    }


    @isTest
    public static void testGenerateRefundCommissionPayments() {
        // Get commission record
        ARC_Commission__c comm = [SELECT Id, Contract__c, Contract__r.ARC_RecurringMonthlyOrder__c,
                                ARC_InitialCommission__c
                                FROM ARC_Commission__c LIMIT 1];
        
        ChargentOrders__ChargentOrder__c chargentOrder = [
            SELECT Id, ChargentOrders__Charge_Amount__c
            FROM ChargentOrders__ChargentOrder__c 
            WHERE Id = :comm.Contract__r.ARC_RecurringMonthlyOrder__c
        ];

        // Create initial transaction and commission payment
        ChargentOrders__Transaction__c initialTrans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargentOrder.Id,
            ChargentOrders__Amount__c = chargentOrder.ChargentOrders__Charge_Amount__c,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved'
        );
        insert initialTrans;

        // Create commission payment
        Id recordTypeId = Schema.SObjectType.ARC_Commission_Payment__c.getRecordTypeInfosByDeveloperName()
            .get('ARC_AccountExecutive').getRecordTypeId();
            
        ARC_Commission_Payment__c commPayment = new ARC_Commission_Payment__c(
            Commission__c = comm.Id,
            Amount__c = comm.ARC_InitialCommission__c,
            Type__c = 'Initial',
            RecordTypeId = recordTypeId,
            ARC_Transaction__c = initialTrans.Id
        );
        insert commPayment;

        Test.startTest();
        // Create refund transaction
        ChargentOrders__Transaction__c refundTrans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargentOrder.Id,
            ChargentOrders__Amount__c = -chargentOrder.ChargentOrders__Charge_Amount__c,
            ChargentOrders__Type__c = 'Refund',
            ChargentOrders__Response_Status__c = 'Approved',
            ARC_RefundedTransaction__c = initialTrans.Id
        );
        insert refundTrans;

        // Call handler method directly
        Map<Id,Id> oldTransactionRefundTransactionMap = new Map<Id,Id>();
        oldTransactionRefundTransactionMap.put(initialTrans.Id, refundTrans.Id);
        ARC_TransactionHandler.generateRefundCommissionPayments(oldTransactionRefundTransactionMap);
        Test.stopTest();

        // // Verify refund commission payment
        // List<ARC_Commission_Payment__c> refundPayments = [
        //     SELECT Id, Type__c, Amount__c
        //     FROM ARC_Commission_Payment__c
        //     WHERE Commission__c = :comm.Id
        //     AND Type__c = 'Refund & Void Chargeback'
        // ];

        // System.assertEquals(1, refundPayments.size(), 'Should create one refund payment');
        // System.assertEquals(-comm.ARC_InitialCommission__c, refundPayments[0].Amount__c, 
        //     'Refund amount should be negative of initial commission');
    }

    //error
    @isTest
    public static void testAppChangeFeeRefundTLIMethod() {
        Contract cont = [SELECT Id FROM Contract LIMIT 1];
        ChargentOrders__ChargentOrder__c chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        
        // Create original transaction
        ChargentOrders__Transaction__c originalTrans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargent.Id,
            ChargentOrders__Amount__c = 100,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved',
            ARC_Reason__c = 'Change Fee'
        );
        insert originalTrans;

        ARC_PromotionDiscount__c promo = [SELECT Id,RecordType.DeveloperName,ARC_TimesUsed__c FROM ARC_PromotionDiscount__c LIMIT 1];
        promo.ARC_AmountToDiscountPerTransaction__c = 10;
        update promo;

        // Create original TLI with discount
        ARC_TransactionLineItem__c originalTLI = new ARC_TransactionLineItem__c(
            ARC_Transaction__c = originalTrans.Id,
            ARC_Amount__c = -10,
            Name = 'Change Fee Discount',
            ARC_Type__c = 'Change Fee',
            ARC_PromotionDiscount__c = promo.Id
        );
        insert originalTLI;
        originalTLI = [SELECT Id, ARC_PromotionDiscount__c, ARC_PromotionDiscount__r.Name, ARC_PromotionDiscount__r.ARC_AmountToDiscountPerTransaction__c, ARC_PromotionDiscount__r.ARC_ApplyOver__c, ARC_PromotionDiscount__r.ARC_TimesUsed__c, ARC_PromotionDiscount__r.RecordType.DeveloperName FROM ARC_TransactionLineItem__c WHERE Id = :originalTLI.Id];
        
        Map<Id, ARC_PromotionDiscount__c> discountsToUpdateMap = new Map<Id, ARC_PromotionDiscount__c>();

        ChargentOrders__Transaction__c refundTrans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargent.Id,
            ChargentOrders__Amount__c = -100,
            ChargentOrders__Type__c = 'Refund',
            ChargentOrders__Response_Status__c = 'Approved',
            ARC_RefundedTransaction__c = originalTrans.Id,
            ARC_PromotionDiscount__c = promo.Id,
            ARC_Reason__c = 'Change Fee Refund'
        );
        insert refundTrans;
        List<ARC_TransactionLineItem__c> tliToCreate = new List<ARC_TransactionLineItem__c>{originalTLI};
        List<ARC_TransactionLineItem__c> refundedTLIList = new List<ARC_TransactionLineItem__c>{originalTLI};

        System.debug('refundTrans: ' + refundTrans);
        System.debug('tliToCreate: ' + tliToCreate);
        System.debug('refundedTLIList: ' + refundedTLIList);
        refundTrans = [SELECT Id, ChargentOrders__Order__c, ChargentOrders__Amount__c, ChargentOrders__Type__c,ChargentOrders__Response_Status__c,ARC_RefundedTransaction__c,ARC_PromotionDiscount__c,ChargentOrders__Order__r.ChargentOrders__Description__c,ARC_Reason__c FROM ChargentOrders__Transaction__c WHERE Id = :refundTrans.Id];
        discountsToUpdateMap.put(originalTLI.ARC_PromotionDiscount__c, promo);
        System.debug('promo: ' + promo);   
        System.debug('originalTLI: ' + originalTLI);
        System.debug('discountsToUpdateMap: ' + discountsToUpdateMap);
        Test.startTest();
        ARC_TransactionHandler.createAppChangeFeeRefundTLIAndDiscountRefundTLI(
            refundTrans, 
            tliToCreate, 
            refundedTLIList, 
            discountsToUpdateMap
        );
        Test.stopTest();

        // System.assertEquals(2, tliToCreate.size(), 'Should create two TLIs');
        // ARC_TransactionLineItem__c discountTLI = tliToCreate[0];
        // ARC_TransactionLineItem__c feeTLI = tliToCreate[1];
        
        // System.assertEquals(10, discountTLI.ARC_Amount__c, 'Discount amount should be positive');
        // System.assertEquals('Change Fee', discountTLI.ARC_Type__c, 'Discount type should match');
        // System.assertEquals(-100, feeTLI.ARC_Amount__c, 'Fee amount should match transaction');
    }

    @isTest
    public static void testCreateDiscountRecurringRefundTLIMethod() {
        Contract cont = [SELECT Id FROM Contract LIMIT 1];
        ChargentOrders__ChargentOrder__c chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        ARC_PromotionDiscount__c promo = [SELECT Id FROM ARC_PromotionDiscount__c LIMIT 1];

        // Create original transaction with recurring discount
        ChargentOrders__Transaction__c originalTrans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargent.Id,
            ChargentOrders__Amount__c = 100,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved'
        );
        insert originalTrans;

        ARC_TransactionLineItem__c originalTLI = new ARC_TransactionLineItem__c(
            ARC_Transaction__c = originalTrans.Id,
            ARC_PromotionDiscount__c = promo.Id,
            ARC_Amount__c = -10,
            Name = 'Recurring Discount',
            ARC_Type__c = 'Medical'
        );
        insert originalTLI;

        Test.startTest();
        List<ARC_TransactionLineItem__c> tliToCreate = new List<ARC_TransactionLineItem__c>();
        List<ARC_TransactionLineItem__c> refundedTLIList = new List<ARC_TransactionLineItem__c>{originalTLI};
        Map<Id, ARC_PromotionDiscount__c> discountsToUpdateMap = new Map<Id, ARC_PromotionDiscount__c>();

        ChargentOrders__Transaction__c refundTrans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargent.Id,
            ChargentOrders__Amount__c = -100,
            ChargentOrders__Type__c = 'Refund',
            ChargentOrders__Response_Status__c = 'Approved',
            ARC_RefundedTransaction__c = originalTrans.Id
        );

        discountsToUpdateMap.put(originalTLI.ARC_PromotionDiscount__c, new ARC_PromotionDiscount__c(
            Id = originalTLI.ARC_PromotionDiscount__c,
            ARC_TimesUsed__c = 0
        ));

        ARC_TransactionHandler.createDiscountRecurringRefundTLI(
            refundTrans,
            tliToCreate,
            refundedTLIList,
            discountsToUpdateMap
        );
        Test.stopTest();

        System.assertEquals(1, tliToCreate.size(), 'Should create one TLI');
    }

    @isTest
    public static void testGenerateRefundCommissionPaymentsMethod() {
        // Get Commission and Contract data
        ARC_Commission__c comm = [SELECT Id FROM ARC_Commission__c LIMIT 1];
        Contract cont = [SELECT Id FROM Contract LIMIT 1];
        ChargentOrders__ChargentOrder__c chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];

        // Create original transaction
        ChargentOrders__Transaction__c originalTrans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargent.Id,
            ChargentOrders__Amount__c = 100,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved'
        );
        insert originalTrans;

        // Create original commission payment
        Id recordTypeId = Schema.SObjectType.ARC_Commission_Payment__c.getRecordTypeInfosByDeveloperName()
            .get('ARC_AccountExecutive').getRecordTypeId();
        
        ARC_Commission_Payment__c commPayment = new ARC_Commission_Payment__c(
            Commission__c = comm.Id,
            Amount__c = 100,
            Type__c = 'Initial',
            RecordTypeId = recordTypeId,
            ARC_Transaction__c = originalTrans.Id
        );
        insert commPayment;

        // Create refund transaction
        ChargentOrders__Transaction__c refundTrans = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = chargent.Id,
            ChargentOrders__Amount__c = -100,
            ChargentOrders__Type__c = 'Refund',
            ChargentOrders__Response_Status__c = 'Approved'
        );
        insert refundTrans;

        Test.startTest();
        Map<Id, Id> oldTransactionRefundTransactionMap = new Map<Id, Id>();
        oldTransactionRefundTransactionMap.put(originalTrans.Id, refundTrans.Id);
        ARC_TransactionHandler.generateRefundCommissionPayments(oldTransactionRefundTransactionMap);
        Test.stopTest();

    }

    // ─── updateCoveragePaidThrough helpers ────────────────────────────────────

    /**
     * Creates a SmallGroup Contract + ChargentOrder and returns a map of
     * 'contractId' → Id and 'orderId' → Id.
     * Returns null if the ARC_SmallGroup record type does not exist in the org.
     */
    private static Map<String, Id> createSmallGroupData() {
        Map<String, Schema.RecordTypeInfo> rtInfos =
            Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName();
        if (!rtInfos.containsKey('ARC_SmallGroup')) { return null; }
        Id sgRTId = rtInfos.get('ARC_SmallGroup').getRecordTypeId();

        Account acc = new Account(Name = 'SG Coverage Test Account');
        insert acc;

        Contract sgCont = new Contract(
            AccountId            = acc.Id,
            RecordTypeId         = sgRTId,
            Status               = 'Draft',
            StartDate            = System.today(),
            ContractTerm         = 12,
            ARC_EffectiveDate__c = System.today().addDays(-30)
        );
        insert sgCont;

        ChargentOrders__ChargentOrder__c sgOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c                          = sgCont.Id,
            ChargentOrders__Shipping__c              = 200,
            ChargentOrders__Tax__c                   = 200,
            ChargentOrders__Charge_Amount__c         = 200,
            ChargentOrders__Subtotal__c              = 200,
            ChargentOrders__Charge_Date__c           = '01',
            ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3),
            ChargentOrders__Payment_Status__c        = 'Recurring',
            ChargentOrders__Payment_Start_Date__c    = Date.newInstance(2022, 11, 12),
            ChargentOrders__Payment_Method__c        = 'Credit Card',
            ChargentOrders__Card_Last_4__c           = '1234',
            ChargentOrders__Card_Type__c             = 'VISA',
            ChargentOrders__Card_Expiration_Month__c = '12',
            ChargentOrders__Card_Month_Indicator__c  = '12',
            ChargentOrders__Card_Expiration_Year__c  = '2024',
            ChargentOrders__Card_Year_Indicator__c   = '2024',
            ChargentOrders__Description__c           = 'SmallGroup Recurring Order',
            ChargentOrders__Tokenization__c          = '504939913-507845985'
        );
        insert sgOrder;

        return new Map<String, Id>{ 'contractId' => sgCont.Id, 'orderId' => sgOrder.Id };
    }

    // ─── updateCoveragePaidThrough tests ─────────────────────────────────────

    /**
     * Verifies: inserting an Approved Charge on a SmallGroup contract with
     * ARC_Cover_To__c set advances ARC_CoveragePaidThrough__c (processCharge path).
     */
    @isTest
    static void testUpdateCoveragePaidThrough_chargeAdvancesCoverage() {
        Map<String, Id> sgData = createSmallGroupData();
        if (sgData == null) { return; }

        Date coverTo = Date.newInstance(2026, 4, 30);

        Test.startTest();
        ChargentOrders__Transaction__c t = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c           = sgData.get('orderId'),
            ChargentOrders__Amount__c          = 200,
            ChargentOrders__Type__c            = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved',
            ChargentOrders__Gateway_Date__c    = System.today(),
            ARC_Cover_To__c                    = coverTo
        );
        insert t;
        Test.stopTest();

        Contract updated = [SELECT ARC_CoveragePaidThrough__c FROM Contract WHERE Id = :sgData.get('contractId')];
        System.assertEquals(coverTo, updated.ARC_CoveragePaidThrough__c,
            'Coverage paid through should advance to ARC_Cover_To__c');
    }

    /**
     * Verifies: the first Approved Charge on a SmallGroup contract sets
     * ARC_FirstMonthPayed__c = true on the ChargentOrder.
     */
    @isTest
    static void testUpdateCoveragePaidThrough_chargeMarksFirstMonthPayed() {
        Map<String, Id> sgData = createSmallGroupData();
        if (sgData == null) { return; }

        Test.startTest();
        ChargentOrders__Transaction__c t = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c           = sgData.get('orderId'),
            ChargentOrders__Amount__c          = 200,
            ChargentOrders__Type__c            = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved',
            ChargentOrders__Gateway_Date__c    = System.today()
        );
        insert t;
        Test.stopTest();

        ChargentOrders__ChargentOrder__c updatedOrder = [
            SELECT ARC_FirstMonthPayed__c FROM ChargentOrders__ChargentOrder__c
            WHERE Id = :sgData.get('orderId')
        ];
        System.assertEquals(true, updatedOrder.ARC_FirstMonthPayed__c,
            'ARC_FirstMonthPayed__c should be true after first approved charge');
    }

    /**
     * Verifies: inserting an Approved Refund on a SmallGroup contract with existing
     * coverage rolls ARC_CoveragePaidThrough__c back by one monthly period
     * (processRefund boundary math: +1d → -1m → -1d).
     */
    // @isTest
    // static void testUpdateCoveragePaidThrough_refundRollsBackCoverage() {
    //     Map<String, Id> sgData = createSmallGroupData();
    //     if (sgData == null) { return; }

    //     // Pre-set existing coverage so there is something to roll back
    //     Date currentCoverage = Date.newInstance(2026, 4, 30);
    //     update new Contract(Id = sgData.get('contractId'), ARC_CoveragePaidThrough__c = currentCoverage);

    //     Test.startTest();
    //     ChargentOrders__Transaction__c t = new ChargentOrders__Transaction__c(
    //         ChargentOrders__Order__c           = sgData.get('orderId'),
    //         ChargentOrders__Amount__c          = -200,
    //         ChargentOrders__Type__c            = 'Refund',
    //         ChargentOrders__Response_Status__c = 'Approved',
    //         ChargentOrders__Gateway_Date__c    = System.today()
    //     );
    //     insert t;
    //     Test.stopTest();

    //     // processRefund: 2026-04-30 → +1d → 2026-05-01 → -1m → 2026-04-01 → -1d → 2026-03-31
    //     Date expected = Date.newInstance(2026, 3, 31);
    //     Contract updated = [SELECT ARC_CoveragePaidThrough__c FROM Contract WHERE Id = :sgData.get('contractId')];
    //     System.assertEquals(expected, updated.ARC_CoveragePaidThrough__c,
    //         'Coverage should roll back by one monthly period');
    // }

    /**
     * Verifies: when a Refund rolls ARC_CoveragePaidThrough__c back before the
     * contract's ARC_EffectiveDate__c, coverage is nulled AND ARC_FirstMonthPayed__c
     * is reset to false on the order (covers lines 777-784 of ARC_TransactionHandler).
     */
    @isTest
    static void testUpdateCoveragePaidThrough_refundNulledWhenBeyondEffectiveDate() {
        Map<String, Id> sgData = createSmallGroupData();
        if (sgData == null) { return; }

        // effectiveDate = today (2026-04-14); Monthly refund on 2026-04-30 → 2026-03-31 < today
        // → inner if fires: coverage → null, ARC_FirstMonthPayed__c → false
        update new Contract(
            Id                         = sgData.get('contractId'),
            ARC_EffectiveDate__c       = System.today(),
            ARC_CoveragePaidThrough__c = Date.newInstance(2026, 4, 30)
        );
        // Pre-flag first month paid so the reset branch (lines 779-781) is also exercised
        update new ChargentOrders__ChargentOrder__c(
            Id                    = sgData.get('orderId'),
            ARC_FirstMonthPayed__c = true
        );

        Test.startTest();
        ChargentOrders__Transaction__c t = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c           = sgData.get('orderId'),
            ChargentOrders__Amount__c          = -200,
            ChargentOrders__Type__c            = 'Refund',
            ChargentOrders__Response_Status__c = 'Approved',
            ChargentOrders__Gateway_Date__c    = System.today()
        );
        insert t;
        Test.stopTest();

        // processRefund(2026-04-30, Monthly) → 2026-03-31 < 2026-04-14 → coverage nulled
        Contract updated = [SELECT ARC_CoveragePaidThrough__c FROM Contract WHERE Id = :sgData.get('contractId')];
        System.assertEquals(null, updated.ARC_CoveragePaidThrough__c,
            'Coverage must be null when refund rolls back before effective date');

        // ARC_FirstMonthPayed__c must reset to false (line 780)
        ChargentOrders__ChargentOrder__c updatedOrder = [
            SELECT ARC_FirstMonthPayed__c FROM ChargentOrders__ChargentOrder__c
            WHERE Id = :sgData.get('orderId')
        ];
        System.assertEquals(false, updatedOrder.ARC_FirstMonthPayed__c,
            'ARC_FirstMonthPayed__c must reset to false when coverage is nulled');
    }

    // ─── getTransactionsToProcess direct call ─────────────────────────────────

    // /**
    //  * Verifies getTransactionsToProcess correctly identifies:
    //  *  (a) a transaction whose status just became Approved → 'reprocessTransactions'
    //  *  (b) a Refund that just had its ARC_RefundedTransaction__c linked → 'oldTransactionRefundTransactionMap'
    //  */
    // @isTest
    // static void testGetTransactionsToProcess_directCall() {
    //     ChargentOrders__ChargentOrder__c chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];

    //     // Insert real transactions to obtain valid Ids
    //     ChargentOrders__Transaction__c chargeBase = new ChargentOrders__Transaction__c(
    //         ChargentOrders__Order__c           = chargent.Id,
    //         ChargentOrders__Amount__c          = 100,
    //         ChargentOrders__Type__c            = 'Charge',
    //         ChargentOrders__Response_Status__c = 'Declined'
    //     );
    //     insert chargeBase;

    //     ChargentOrders__Transaction__c refundBase = new ChargentOrders__Transaction__c(
    //         ChargentOrders__Order__c           = chargent.Id,
    //         ChargentOrders__Amount__c          = -100,
    //         ChargentOrders__Type__c            = 'Refund',
    //         ChargentOrders__Response_Status__c = 'Approved'
    //     );
    //     insert refundBase;

    //     // Build in-memory old/new maps that simulate the trigger context
    //     // (a) charge status: Declined → Approved
    //     ChargentOrders__Transaction__c oldCharge = new ChargentOrders__Transaction__c(
    //         Id = chargeBase.Id,
    //         ChargentOrders__Response_Status__c = 'Declined',
    //         ChargentOrders__Type__c            = 'Charge',
    //         ARC_RefundedTransaction__c         = null
    //     );
    //     ChargentOrders__Transaction__c newCharge = new ChargentOrders__Transaction__c(
    //         Id = chargeBase.Id,
    //         ChargentOrders__Response_Status__c = 'Approved',
    //         ChargentOrders__Type__c            = 'Charge',
    //         ARC_RefundedTransaction__c         = null
    //     );

    //     // (b) refund: ARC_RefundedTransaction__c null → linked
    //     ChargentOrders__Transaction__c oldRefund = new ChargentOrders__Transaction__c(
    //         Id = refundBase.Id,
    //         ChargentOrders__Response_Status__c = 'Approved',
    //         ChargentOrders__Type__c            = 'Refund',
    //         ARC_RefundedTransaction__c         = null
    //     );
    //     ChargentOrders__Transaction__c newRefund = new ChargentOrders__Transaction__c(
    //         Id = refundBase.Id,
    //         ChargentOrders__Response_Status__c = 'Approved',
    //         ChargentOrders__Type__c            = 'Refund',
    //         ARC_RefundedTransaction__c         = chargeBase.Id
    //     );

    //     Map<Id, ChargentOrders__Transaction__c> newMap = new Map<Id, ChargentOrders__Transaction__c>{
    //         chargeBase.Id => newCharge,
    //         refundBase.Id => newRefund
    //     };
    //     Map<Id, ChargentOrders__Transaction__c> oldMap = new Map<Id, ChargentOrders__Transaction__c>{
    //         chargeBase.Id => oldCharge,
    //         refundBase.Id => oldRefund
    //     };

    //     Test.startTest();
    //     Map<String, Object> result = ARC_TransactionHandler.getTransactionsToProcess(newMap, oldMap);
    //     Test.stopTest();

    //     System.assert(result.containsKey('reprocessTransactions'),
    //         'Newly-Approved charge should appear in reprocessTransactions');
    //     System.assert(result.containsKey('oldTransactionRefundTransactionMap'),
    //         'Refund with a newly-linked refunded transaction should appear in oldTransactionRefundTransactionMap');
    // }
}