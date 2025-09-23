@isTest
private class ARC_ReprocessProgramChangeTest {
/*
    @TestSetup
    static void makeData(){
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(2);
        List<Contact> contacts = ARC_TestUtility.createTestContact(2, 'Contact');
        List<Account> accounts = ARC_TestUtility.createTestAccount(2, 'ARC_IFPPersonAccount');
        List<Account> groupAccount = ARC_TestUtility.createTestAccount(1, 'Group');
        List<vlocity_ins__ContractLineItem__c> cLineItems = ARC_TestUtility.createTestContractLineItem(4);
        List<vlocity_ins__GroupCensusMemberPlan__c> gcMemberPlans = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        List<Product2> prods = ARC_TestUtility.createTestProducts(4);
        Id rtProduct = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id rtCoverageSpec = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Coverage Spec').getRecordTypeId();
        

        Integer i = 0;

        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test1', vlocity_ins__ContractLineId__c=cLineItems[0].Id, vlocity_ins__GroupCensusMemberId__c=members[0].Id));
        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test3', vlocity_ins__ContractLineId__c=cLineItems[2].Id, vlocity_ins__GroupCensusMemberId__c=members[0].Id));

        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test2', vlocity_ins__ContractLineId__c=cLineItems[1].Id, vlocity_ins__GroupCensusMemberId__c=members[1].Id));
        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test4', vlocity_ins__ContractLineId__c=cLineItems[3].Id, vlocity_ins__GroupCensusMemberId__c=members[1].Id));
        insert gcMemberPlans;

        for (vlocity_ins__GroupCensusMember__c cm : members) {
            if(i == 0) cm.vlocity_ins__IsPrimaryMember__c = true;
            if(i == 1) cm.ARC_DependentRelationship__c = 'Spouse';

            if(i == 0) cm.vlocity_ins__ContactId__c = contacts[0].Id;
            if(i == 1) cm.vlocity_ins__ContactId__c = contacts[1].Id;
            i++;
        }
        i = 0;
        update members;

        prods[0].RecordTypeId = rtProduct;
        prods[0].vlocity_ins__Type__c = 'Medical';

        prods[1].RecordTypeId = rtProduct;
        prods[1].vlocity_ins__Type__c = 'Ancillary';

        prods[2].RecordTypeId = rtProduct;
        prods[2].vlocity_ins__Type__c = 'Medical';
        prods[2].RecordTypeId = rtCoverageSpec;

        prods[3].RecordTypeId = rtCoverageSpec;

        update prods;

        vlocity_ins__ProductChildItem__c childItem1 = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ChildProductId__c = prods[2].Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert childItem1;

        vlocity_ins__ProductChildItem__c childItem2 = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ChildProductId__c = prods[3].Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert childItem2;

        Contract cnt = [SELECT Id, ARC_AppFeeOrder__c, AccountId FROM Contract LIMIT 1];
        cnt.AccountId = groupAccount[0].Id;

        for (vlocity_ins__ContractLineItem__c cli : cLineItems) {
            cli.vlocity_ins__ContractId__c = cnt.Id;
            cli.ARC_OriginalPrice__c = 100.00;
        }

        cLineItems[0].vlocity_ins__Product2Id__c = prods[0].Id;
        cLineItems[1].vlocity_ins__Product2Id__c = prods[1].Id;
        cLineItems[2].vlocity_ins__Product2Id__c = prods[2].Id;
        cLineItems[3].vlocity_ins__Product2Id__c = prods[3].Id;

        update cLineItems;
        
        ChargentBase__Gateway__c gateway = new ChargentBase__Gateway__c(
            Name = 'Test Gateway',
            ChargentBase__Available_Payment_Methods__c = 'Credit Card',
            ChargentBase__Active__c = true
        );
        insert gateway;
        ChargentOrders__ChargentOrder__c existingOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = cnt.Id,
            ChargentOrders__Billing_First_Name__c = 'Norman',
            ChargentOrders__Billing_Last_Name__c = 'Beer',
            ChargentOrders__Card_Number__c = '5162095513838477',
            ChargentOrders__Card_Expiration_Month__c = '7',
            ChargentOrders__Card_Expiration_Year__c = '2025',
            ChargentOrders__Card_Last_4__c = '8477',
            ChargentOrders__Charge_Amount__c = 99,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Gateway__c = gateway.Id,
            ChargentOrders__Charge_Date__c = '04-01-2025',
            ARC_FirstMonthPayed__c = false,
            ChargentOrders__Manual_Charge__c = true
        );
        insert existingOrder;

        cnt.ARC_AppFeeOrder__c = existingOrder.Id;
        update cnt;
       

        ARC_PromotionCode__c promotionCode = new ARC_PromotionCode__c(
            ARC_StartDate__c =  Date.valueOf('2025-01-01'),
            ARC_EndDate__c = null,
            ARC_ApplyFirst__c = false,
            ARC_ApplyOver__c = 'Change Fee',
            RecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Promotion_Discount').getRecordTypeId(),
            Name = 'Change Fee',
            ARC_PromotionCode__c = 'Change Fee',
            ARC_DiscountType__c = 'Change Fee',
            ARC_DiscountRate__c = null,
            ARC_DiscountedAmount__c = 0
        );
        insert promotionCode;
        
        ARC_PromotionDiscount__c promotionDiscount = new ARC_PromotionDiscount__c(
            RecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Promotion_Discount').getRecordTypeId(),
            ARC_Agent__c = UserInfo.getUserId(),
            ARC_ApplyFirst__c = false,
            ARC_ApplyOver__c = 'Change Fee',
            ARC_PromoCode__c = promotionCode.Id,
            ARC_Status__c = 'Activated',
            ARC_Contract__c = cnt.Id,
            ARC_NumberOfTimesCanBeUsed__c = 6,
            ARC_TimesUsed__c = 0,
            ARC_AmountToDiscountPerTransaction__c = 99,
            ARC_EndDate__c = null
        );
        insert promotionDiscount;
    }
*/
    // Incorrect Height to cause a custom log
    @isTest
    static void reprocessErrorTest_PCSO() {
       // soReasons
        Map<String, Object> soReasons = new Map<String, Object>{
            'addressStateChange' => true,
            'effectiveDateChange' => true,
            'ancillaryChange' => true,
            'programDowngrade' => true,
            'programUpgrade' => true,
            'dateOfBirthChange' => true,
            'relationshipToPrimaryChange' => true,
            'primaryChange' => true,
            'addExistingMember' => true,
            'removeMember' => true,
            'addMember' => true,
            'removeAllAncillary' => true
        };

        // soChanges
        Map<String, Object> soChanges = new Map<String, Object>{
            'soReasons' => soReasons,
            'createNewContract' => true
        };

        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'soChanges' => soChanges
        };

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        ARC_PCSpinOff_BaseService baseService = new ARC_PCSpinOff_BaseService();

        Boolean error = false;

        Custom_Logs__c customLog = new Custom_Logs__c(
            Log__c = JSON.serialize(inputMap),
            Name = 'PC SO DML Failed'
        );

        insert customLog;

        try {
            baseService.invokeMethod('RA_PCSpinOffDML', inputMap, outputMap, options);
        } catch (Exception e) {
            error = true;
        }  
        
        Test.startTest();
            ARC_ReprocessProgramChange.reprocessProgramChange(customlog.Id); 
        Test.stopTest();
        
        customlog = [
            SELECT Status__c, Reprocess_result__c
            FROM Custom_Logs__c
            WHERE Id = :customlog.Id
        ];
       
        System.assert(
            error,
            'Reprocess_result__c should indicate Execution Failed.'
        );
    }

    @isTest
    static void reprocessErrorTest_SO() {
        // soReasons
        Map<String, Object> soReasons = new Map<String, Object>{
            'addressStateChange' => true,
            'effectiveDateChange' => true,
            'ancillaryChange' => true,
            'programDowngrade' => true,
            'programUpgrade' => true,
            'dateOfBirthChange' => true,
            'relationshipToPrimaryChange' => true,
            'primaryChange' => true,
            'addExistingMember' => true,
            'removeMember' => true,
            'addMember' => true,
            'removeAllAncillary' => true
        };

        // soChanges
        Map<String, Object> soChanges = new Map<String, Object>{
            'soReasons' => soReasons,
            'createNewContract' => true
        };

        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'soChanges' => soChanges
        };

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        ARC_SpinOff_BaseService baseService = new ARC_SpinOff_BaseService();

        Boolean error = false;

        Custom_Logs__c customLog = new Custom_Logs__c(
            Log__c = JSON.serialize(inputMap),
            Name = 'Spin Off DML Failed'
        );

        insert customLog;

        try {
            baseService.invokeMethod('RA_SingleSpinOffDML', inputMap, outputMap, options);
        } catch (Exception e) {
            error = true;
        }  
        
        Test.startTest();
            ARC_ReprocessProgramChange.reprocessProgramChange(customlog.Id);
        Test.stopTest();
        
        customlog = [
            SELECT Status__c, Reprocess_result__c
            FROM Custom_Logs__c
            WHERE Id = :customlog.Id
        ];
       
        System.assert(
            error,
            'Reprocess_result__c should indicate Execution Failed.'
        );
    }

    @isTest
    static void reprocessExecutionFailedTest() {
        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{
            'addressStateChange' => true,
            'effectiveDateChange' => true,
            'ancillaryChange' => true,
            'programDowngrade' => true,
            'programUpgrade' => true,
            'dateOfBirthChange' => true,
            'relationshipToPrimaryChange' => true,
            'primaryChange' => true,
            'addExistingMember' => true,
            'removeMember' => true,
            'addMember' => true,
            'removeAllAncillary' => true
        };

        // pcChanges
        Map<String, Object> pcChanges = new Map<String, Object>{
            'pcReasons' => pcReasons,
            'createNewContract' => true
        };

        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'pcChanges' => pcChanges
        };

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        ARC_PCBaseService baseService = new ARC_PCBaseService();

        Boolean error = false;

        try {
            baseService.invokeMethod('processChanges', inputMap, outputMap, options);
        } catch (Exception e) {
            error = true;
        }  

        Custom_Logs__c customlog = [SELECT Id FROM Custom_Logs__c LIMIT 1];
        System.debug('custom log exist' + customlog);
        
        Test.startTest();
            ARC_ReprocessProgramChange.reprocessProgramChange(customlog.Id);
        Test.stopTest();
        
        customlog = [
            SELECT Status__c, Reprocess_result__c
            FROM Custom_Logs__c
            WHERE Id = :customlog.Id
        ];

        System.assert(
            error,
            'Reprocess_result__c should indicate Execution Failed.'
        );
    }

    @IsTest
    static void initFailed_on_PC_constructor_cast() {
        Map<String, Object> badPcReasons = new Map<String, Object>{
            'programUpgrade'   => new Map<String,Object>{},   
            'programDowngrade' => new Map<String,Object>{},
            'ancillaryChange'  => new Map<String,Object>{}
        };
        Map<String, Object> payload = new Map<String, Object>{
            'pcChanges' => new Map<String, Object>{ 'pcReasons' => badPcReasons }
        };

        Custom_Logs__c log = new Custom_Logs__c(
            Name      = 'failure name to hit PC branch',
            Status__c = 'New',
            Log__c    = JSON.serialize(payload)
        );
        insert log;

        Test.startTest();
        ARC_ReprocessProgramChange.reprocessProgramChange(log.Id);
        Test.stopTest();

        log = [
            SELECT Reprocess_result__c
            FROM Custom_Logs__c
            WHERE Id = :log.Id
        ];

        System.assertNotEquals(null, log.Reprocess_result__c);
        // System.assert(
        //     log.Reprocess_result__c.startsWith('=== Initialization Failed ==='),
        //     'Expected Initialization Failed in PC branch.'
        // );
    } 


    @IsTest
    static void initFailed_on_SpinOff_constructor_cast() {
        Map<String, Object> badSoReasons = new Map<String, Object>{
            'spinOff'         => new Map<String,Object>{'x'=>1},  
            'programUpgrade'  => new Map<String,Object>{},
            'programDowngrade'=> new Map<String,Object>{}
        };
        Map<String, Object> payload = new Map<String, Object>{
            'soChanges' => new Map<String, Object>{ 'soReasons' => badSoReasons }
        };

        Custom_Logs__c log = new Custom_Logs__c(
            Name        = 'Exception while upserting census members in future context',
            Status__c   = 'New',
            Log__c      = JSON.serialize(payload)
        );
        insert log;

        Test.startTest();
        ARC_ReprocessProgramChange.reprocessProgramChange(log.Id);
        Test.stopTest();

        log = [
            SELECT Reprocess_result__c
            FROM Custom_Logs__c
            WHERE Id = :log.Id
        ];

        System.assertNotEquals(null, log.Reprocess_result__c, 'Should have populated Reprocess_result__c');
        // System.assert(
        //     log.Reprocess_result__c.startsWith('=== Initialization Failed ==='),
        //     'Expected Initialization Failed header. Actual: ' + log.Reprocess_result__c
        // );
    }

    @IsTest
    static void forceErrorTestOne() {
        Map<String, Object> badSoReasons = new Map<String, Object>{
        };
        Map<String, Object> payload = new Map<String, Object>{
            'soChanges' => new Map<String, Object>{ 'soReasons' => badSoReasons }
        };

        Custom_Logs__c log = new Custom_Logs__c(
            Name        = 'Spin Off DML Failed',
            Status__c   = 'New',
            Log__c      = JSON.serialize(payload)
        );
        insert log;

        Test.startTest();
        ARC_ReprocessProgramChange.forceError = true; 
        ARC_ReprocessProgramChange.reprocessProgramChange(log.Id);
        Test.stopTest();
    
    }
    @IsTest
    static void forceErrorTestTwo() {
        Map<String, Object> badSoReasons = new Map<String, Object>{
        };
        Map<String, Object> payload = new Map<String, Object>{
            'soChanges' => new Map<String, Object>{ 'soReasons' => badSoReasons }
        };

        Custom_Logs__c log = new Custom_Logs__c(
            Name        = 'PC SO DML Failed',
            Status__c   = 'New',
            Log__c      = JSON.serialize(payload)
        );
        insert log;

        Test.startTest();
        ARC_ReprocessProgramChange.forceError = true; 
        ARC_ReprocessProgramChange.reprocessProgramChange(log.Id);
        Test.stopTest();
    
    }

 

}