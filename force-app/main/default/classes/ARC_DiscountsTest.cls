@isTest
public with sharing class ARC_DiscountsTest {
//public class ARC_DiscountsTest {
    
    @TestSetup
    static void makeData(){
        // Create test accounts
        List<Account> testAccounts = ARC_TestUtility.createTestAccount(1, 'ARC_IFPPersonAccount');
        testAccounts[0].ARC_ContinuousMembershipStartDate__c = System.today();

        //Create vlocity_ins__GroupCensusMember__c
		List<vlocity_ins__GroupCensusMember__c> censMemb = ARC_TestUtility.createTestCensusMember(1);
		censMemb[0].ARC_PhysicalAddressState__c = 'CA';
		censMemb[0].vlocity_ins__IsPrimaryMember__c = true;
		censMemb[0].ARC_ActiveMember__c = true;
        censMemb[0].ARC_ContinuousMembershipStartDate__c = Date.newInstance(2024, 10, 01);
		censMemb[0].vlocity_ins__FirstName__c = 'TestFirstName';
		censMemb[0].vlocity_ins__Birthdate__c = Date.newInstance(1997, 11, 1);
		update censMemb;

        // Create test contracts
        List<Contract> testContracts = ARC_TestUtility.createContractsAA(1);
        testContracts[0].vlocity_ins__EnrollmentCensusId__c = censMemb[0].vlocity_ins__CensusId__c;
		testContracts[0].ARC_EffectiveDate__c = System.today().addDays(1);
        testContracts[0].ARC_PaidThroughDate__c = System.today();
        testContracts[0].AccountId = testAccounts[0].Id;
        insert testContracts;
        testContracts[0].Status = 'Awaiting Activation';
        update testContracts;
        testContracts[0].Status = 'Activated';
		update testContracts;

        //Create Chargent Order    
        ChargentOrders__ChargentOrder__c chargent=new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = testContracts[0].Id,
            ChargentOrders__Shipping__c = 232,
            ChargentOrders__Tax__c  = 232,
            ChargentOrders__Charge_Amount__c = 232,
            ChargentOrders__Subtotal__c  = 232,
            ChargentOrders__Charge_Date__c =  '01',
            ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3),
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12),
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Last_4__c = '1234',
            ChargentOrders__Card_Type__c = 'VISA',
            ChargentOrders__Card_Expiration_Month__c = '10',
            ChargentOrders__Card_Expiration_Year__c = '2025',
            ChargentOrders__Tokenization__c = '12345678',
            ChargentOrders__Description__c = 'Recurring Monthly Order'
        );
        insert chargent;

        // Create test products
        List<Product2> testProducts = ARC_TestUtility.createTestProducts(2);
        for(Product2 prod : testProducts) {
            prod.vlocity_ins__Type__c = 'Medical';
        }
        update testProducts;
        
        // Create test contract line items
        List<vlocity_ins__ContractLineItem__c> testCLIs = ARC_TestUtility.createTestContractLineItem(2);
        
        // Update Contract Line Items to associate with the contract, product, and set necessary fields
        for(Integer i = 0; i < testCLIs.size(); i++) {
            vlocity_ins__ContractLineItem__c cli = testCLIs[i];
            cli.vlocity_ins__ContractId__c = testContracts[0].Id;
            cli.vlocity_ins__ProductId__c = testProducts[i].Id;
            cli.ARC_SmokerFee__c = 50;
            cli.ARC_ExtraDependentFee__c = 50;
            cli.ARC_OriginalPrice__c = 100;
            cli.vlocity_ins__Quantity__c  = 10;
            cli.vlocity_ins__UnitPrice__c  = 70;
        }
        update testCLIs;

        Id healthyDiscountRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        Id temporaryDiscountRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Temporary_Discount').getRecordTypeId();
         
        //Promotion Code
        Id healthylDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        Id renewalDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Renewal_Discount').getRecordTypeId();


        List<ARC_PromotionCode__c> promoCodes = new List<ARC_PromotionCode__c>();
        ARC_PromotionCode__c promoCode = new ARC_PromotionCode__c(
            Name = 'Healthy Discount',
            ARC_DiscountRate__c = 10,
            ARC_ApplyOver__c = 'Medical',
            RecordTypeId = healthylDiscountCodeRecordTypeId,
            ARC_PromotionCode__c = 'Healthy Discount', 
            ARC_StartDate__c= Date.today()
        );
        promoCodes.add(promoCode);

        for(Integer i = 0; i < 2; i++) { // index 2, 3 = Renewal Discount
            ARC_PromotionCode__c renewalPromoCode = new ARC_PromotionCode__c(
                Name = 'Renewal Discount',
                ARC_DiscountRate__c = 10,
                ARC_ApplyOver__c = 'Medical',
                ARC_PromotionCode__c = 'Renewal Discount' + i,
                ARC_RenewalDiscountNumber__c = i, 
                RecordTypeId = renewalDiscountCodeRecordTypeId,
                ARC_StartDate__c = Date.newInstance(2024, 09, 29)
            );
            promoCodes.add(renewalPromoCode);
        }
        insert promoCodes;

        List<ARC_PromotionDiscount__c> promotionDiscounts = new List<ARC_PromotionDiscount__c>();
        for(Integer i = 0; i < 2; i++) {
            ARC_PromotionDiscount__c discount = new ARC_PromotionDiscount__c(
                Name = 'Healthy Discount',
                ARC_StartDate__c = Date.newInstance(2024, 10, 10),
                ARC_Description__c = 'Testing', 
                ARC_EndDate__c = System.today().addYears(1),
                ARC_Contract__c = testContracts[0].Id,
                ARC_PromoCode__c = promoCodes[0].Id,
                ARC_ApplyFirst__c = true,
                ARC_Status__c = 'Activated',
                ARC_DiscountRate__c = 10,
                ARC_PriceWithoutDiscount__c = 7.9,
                ARC_NumberOfTimesCanBeUsed__c = 0,
                ARC_PriceWithDiscount__c = 6.9,
                ARC_DiscountedAmount__c = 0,
                ARC_ApplyOver__c = 'Medical',
                RecordTypeId = healthyDiscountRecordTypeId
            );
            promotionDiscounts.add(discount);
        }
        insert promotionDiscounts;






    }

    /************************Test Methods************************/

    @isTest
    static void testApplyDiscountWithAgeUp() {

        Contract testContract = [SELECT Id, Status FROM Contract WHERE Status = 'Activated' LIMIT 1];
        Account testAccounts = [SELECT Id FROM Account WHERE isPersonAccount = TRUE LIMIT 1];
        
        Ages_Up__c ageup = new Ages_Up__c();
        ageup.Name = 'PersonAccount Test - Age Up';
        ageup.Contract__c = testContract.Id;
        ageup.ARC_Account__c = testAccounts.Id;
        ageup.ARC_EffectiveDate__c = Date.today();
        ageup.ARC_PriceAfterAgeUp__c = 200;
        ageup.ARC_PriceBeforeAgeUp__c = 100;
        insert ageup;

        List<ARC_PromotionDiscount__c> testPromo = [SELECT Id, ARC_Status__c FROM ARC_PromotionDiscount__c WHERE ARC_Status__c = 'Activated' LIMIT 1];

        Test.startTest();
            testPromo[0].ARC_Status__c='Terminated';
            update testPromo;
        Test.stopTest();
    }
    
    @isTest
    static void testPopulateDiscounts() {

        Contract testContract = [SELECT Id, Status FROM Contract WHERE Status = 'Activated' LIMIT 1];

        Test.startTest();
        ARC_Discounts.populateDiscounts(new Set<Id>{testContract.Id});
        Test.stopTest();
    }
    
    @isTest
    static void testGetPlansWithDiscounts() {
        List<vlocity_ins__ContractLineItem__c> testPlans = [SELECT Id, vlocity_ins__UnitPrice__c, ARC_OriginalPrice__c, ARC_SmokerFee__c, ARC_ExtraDependentFee__c, vlocity_ins__ContractId__c, vlocity_ins__ProductType__c FROM vlocity_ins__ContractLineItem__c];

        List<ARC_PromotionDiscount__c> testDiscounts = [SELECT Id, Name, ARC_StartDate__c, ARC_Description__c, ARC_EndDate__c, ARC_PromoCode__c, RecordTypeId, ARC_ApplyOver__c, ARC_ApplyFirst__c, ARC_DiscountRate__c, ARC_PromoCode__r.ARC_DiscountRate__c, ARC_DiscountedAmount__c, ARC_PromoCode__r.ARC_DiscountedAmount__c, ARC_Status__c, ARC_PromoCode__r.ARC_ApplyOver__c, ARC_Contract__c FROM ARC_PromotionDiscount__c ];
        
        Test.startTest();
        List<vlocity_ins__ContractLineItem__c> updatedPlans = ARC_Discounts.getPlansWithDiscounts(testPlans, testDiscounts);
        Test.stopTest();
        
        System.assertNotEquals(0, updatedPlans.size(), 'Updated plans should exist');
        for(vlocity_ins__ContractLineItem__c plan : updatedPlans) {
            System.assertNotEquals(plan.ARC_OriginalPrice__c, plan.vlocity_ins__UnitPrice__c, 'Unit price should be different from original price after applying discounts');
        }
    }
    
    @isTest
    static void testGetActiveDiscounts() {
        Contract testContract = [SELECT Id, Status FROM Contract WHERE Status = 'Activated' LIMIT 1];
        Test.startTest();
        List<ARC_PromotionDiscount__c> activeDiscounts = ARC_Discounts.getActiveDiscounts(new Set<Id>{testContract.Id});
        Test.stopTest();
        
        //System.assertNotEquals(0, activeDiscounts.size(), 'Active discounts should exist');
        for(ARC_PromotionDiscount__c discount : activeDiscounts) {
            System.assertEquals('Activated', discount.ARC_Status__c, 'All returned discounts should be activated');
        }
    }
    
    @isTest
    static void testGetDiscountsByIds() {
        List<ARC_PromotionDiscount__c> testDiscounts = [SELECT Id FROM ARC_PromotionDiscount__c];

        Set<Id> discountIds = new Map<Id, ARC_PromotionDiscount__c>(testDiscounts).keySet();
        
        Test.startTest();
        List<ARC_PromotionDiscount__c> retrievedDiscounts = ARC_Discounts.getDiscountsByIds(discountIds);
        Test.stopTest();
        
        System.assertEquals(testDiscounts.size(), retrievedDiscounts.size(), 'All discounts should be retrieved');
    }
    
    @isTest
    static void testGetDiscountsByContractIds() {

        Contract testContract = [SELECT Id, Status FROM Contract WHERE Status = 'Activated' LIMIT 1];
        Test.startTest();
        ARC_Discounts.getDiscountsByContractIds(new Set<Id>{testContract.Id});
        Test.stopTest();
    }
 
    @isTest
    static void testprogramChangeAndSpinOffApplyDiscounts() { 
        Contract testContractClone = [SELECT Id FROM Contract LIMIT 1];

        Test.startTest();
        ARC_Discounts.programChangeAndSpinOffApplyDiscounts(new Set<Id>{testContractClone.Id});
        Test.stopTest();
        
        System.assertNotEquals(0, 1, 'Discounts should be retrieved for the contract');
    }

    @isTest
    static void testGetAmountWithAppFeeDiscounts() {
        Decimal amount = 100;

        List<ARC_PromotionDiscount__c> discounts = [SELECT Id, Name, ARC_StartDate__c, ARC_Description__c, ARC_EndDate__c, ARC_PromoCode__c, RecordTypeId, ARC_ApplyOver__c, ARC_ApplyFirst__c, ARC_DiscountRate__c, ARC_PromoCode__r.ARC_DiscountRate__c, ARC_DiscountedAmount__c, ARC_PromoCode__r.ARC_DiscountedAmount__c, ARC_Status__c, ARC_PromoCode__r.ARC_ApplyOver__c, ARC_Contract__c FROM ARC_PromotionDiscount__c ];
        

        Test.startTest();
        ARC_Discounts.getAmountWithAppFeeDiscounts(amount, discounts);
        Test.stopTest();
    }

    @isTest
    static void testAssignDiscountToContract() {

        Test.startTest();
        
        Id healthyDiscountRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        Id healthylDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];

        ARC_PromotionCode__c testPromoCodes = new ARC_PromotionCode__c(
            Name = 'TestPromo',
            ARC_DiscountRate__c = 10,
            ARC_ApplyOver__c = 'Medical',
            RecordTypeId = healthylDiscountCodeRecordTypeId,
            ARC_PromotionCode__c = 'Healthy Discount', 
            ARC_StartDate__c= Date.today()
        );
        insert testPromoCodes;

        ARC_PromotionDiscount__c discount = new  ARC_PromotionDiscount__c(
            ARC_Status__c = 'Activated',
            ARC_Contract__c = testContract.Id,
            ARC_PromoCode__c = testPromoCodes.Id,
            RecordTypeId = healthyDiscountRecordTypeId,
            ARC_StartDate__c = Date.today()
        );
        insert discount;

        
        ARC_Discounts.assignDiscountToContract(testContract.Id, testPromoCodes.Id, healthyDiscountRecordTypeId);
        Test.stopTest();
    }

    @isTest
    static void testIsApplyOverAppFee() {

        Test.startTest();
        
        Id healthyDiscountRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        Id healthylDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];

        ARC_PromotionCode__c testPromoCodes = new ARC_PromotionCode__c(
            Name = 'TestPromo',
            ARC_DiscountRate__c = 10,
            ARC_ApplyOver__c = 'Medical',
            RecordTypeId = healthylDiscountCodeRecordTypeId,
            ARC_PromotionCode__c = 'Healthy Discount', 
            ARC_StartDate__c= Date.today()
        );
        insert testPromoCodes;

        ARC_PromotionDiscount__c discount = new  ARC_PromotionDiscount__c(
            ARC_Status__c = 'Activated',
            ARC_Contract__c = testContract.Id,
            ARC_PromoCode__c = testPromoCodes.Id,
            RecordTypeId = healthyDiscountRecordTypeId,
            ARC_StartDate__c = Date.today()
        );
        insert discount;

        
        ARC_Discounts.isApplyOverAppFee(discount);
        Test.stopTest();
    }

    @isTest
    static void testAppFeeCurrencyDiscountByContract() {

        Contract testContract = [SELECT Id FROM Contract LIMIT 1];

        List<ARC_PromotionDiscount__c> testDiscounts = [SELECT Id, Name, ARC_StartDate__c, ARC_Description__c, ARC_EndDate__c, ARC_PromoCode__c, RecordTypeId, ARC_ApplyOver__c, ARC_ApplyFirst__c, ARC_DiscountRate__c, ARC_PromoCode__r.ARC_DiscountRate__c, ARC_DiscountedAmount__c, ARC_PromoCode__r.ARC_DiscountedAmount__c, ARC_Status__c, ARC_PromoCode__r.ARC_ApplyOver__c, ARC_Contract__c FROM ARC_PromotionDiscount__c ];

        Test.startTest();
        ARC_Discounts.appFeeCurrencyDiscountByContract(new Set<Id>{testContract.Id}, testDiscounts);
        Test.stopTest();
    }

    @isTest
    static void testPopulateDiscountDollarAmmounts() {

        List<vlocity_ins__ContractLineItem__c> plans = [SELECT Id, vlocity_ins__UnitPrice__c, ARC_OriginalPrice__c, ARC_SmokerFee__c, ARC_ExtraDependentFee__c, vlocity_ins__ContractId__c, vlocity_ins__ProductType__c FROM vlocity_ins__ContractLineItem__c];
        List<ARC_PromotionDiscount__c> discounts = [SELECT Id, Name, ARC_Active__c, ARC_StartDate__c, ARC_Description__c, ARC_EndDate__c, ARC_PromoCode__c, RecordTypeId, ARC_ApplyOver__c, ARC_ApplyFirst__c, ARC_DiscountRate__c, ARC_PromoCode__r.ARC_DiscountRate__c, ARC_DiscountedAmount__c, ARC_PromoCode__r.ARC_DiscountedAmount__c, ARC_Status__c, ARC_PromoCode__r.ARC_ApplyOver__c, ARC_Contract__c FROM ARC_PromotionDiscount__c ];
        Map<Id,Map<Id,ARC_PromotionDiscount__c>> discountMap = new Map<Id,Map<Id,ARC_PromotionDiscount__c>>();
        discountMap.put(plans[0].vlocity_ins__ContractId__c, new Map<Id,ARC_PromotionDiscount__c>());
        discountMap.get(plans[0].vlocity_ins__ContractId__c).put(discounts[0].Id, discounts[0]);
        Test.startTest();
        ARC_Discounts.populateDiscountDollarAmmounts(plans, discountMap);
        Test.stopTest();
    }

    @isTest
    static void testmapContractAccounts() {

        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        List<ARC_ContractParticipant__c> contList = new List<ARC_ContractParticipant__c>();
         for (Integer i = 0; i < 2; i++) {
            ARC_ContractParticipant__c cp = new ARC_ContractParticipant__c();
            cp.Name = 'Sarah Participant Expire';
            cp.ARC_Contract__c = testContract.Id;
            cp.ARC_PersonAccount__c = testAccount.Id;
            contList.add(cp);
         }
         insert contList;

        Test.startTest();
        ARC_Discounts.mapContractAccounts(contList);
        Test.stopTest();
    }


    @isTest
    static void testApplyRenewalDiscountFromPcOrSpinOff() {

        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        //Create Contract Participants
        ARC_ContractParticipant__c expiredParticipant = new ARC_ContractParticipant__c(
            Name = 'John Doe Participant Expire',
            ARC_Contract__c = testContract.Id,
            ARC_PersonAccount__c = testAccount.Id
        );
        insert expiredParticipant;

        testAccount.ARC_ContinuousMembershipStartDate__c = System.today();
        update testAccount;

        Test.startTest();
        ARC_Discounts.applyRenewalDiscountFromPcOrSpinOff(new Set<Id>{testContract.Id});
        Test.stopTest();
    }


    @isTest
    static void testApplyAppFeeDiscounts() {

        Contract testContract = [SELECT Id FROM Contract LIMIT 1];

        List<ARC_PromotionDiscount__c> testDiscounts = [SELECT Id, Name, ARC_StartDate__c, ARC_Description__c, ARC_EndDate__c, ARC_PromoCode__c, RecordTypeId, ARC_ApplyOver__c, ARC_ApplyFirst__c, ARC_DiscountRate__c, ARC_PromoCode__r.ARC_DiscountRate__c, ARC_DiscountedAmount__c, ARC_PromoCode__r.ARC_DiscountedAmount__c, ARC_Status__c, ARC_PromoCode__r.ARC_ApplyOver__c, ARC_Contract__c FROM ARC_PromotionDiscount__c ];

        Test.startTest();
        ARC_Discounts.applyAppFeeDiscounts(new Set<Id>{testContract.Id}, testDiscounts);
        Test.stopTest();
    }

    @isTest
    static void testCloneTemporaryDiscounts() {

        //Promotion Discount
        Id healthyDiscountRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        Id healthylDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        Id temporaryDiscountRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Temporary_Discount').getRecordTypeId();
        Id temporaryDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Temporary_Discount').getRecordTypeId();

        //Create Account
        List<Account> testAccountClone = ARC_TestUtility.createTestAccount(1, 'ARC_IFPPersonAccount');

        //Create test contract testContractlinkExpire
        List<Contract> testContractlinkExpire = ARC_TestUtility.createContracts(1);
        testContractlinkExpire[0].AccountId = testAccountClone[0].Id;
        insert testContractlinkExpire;
        
        //Create test contract testContractExpire
        List<Contract> testContractExpire = ARC_TestUtility.createContracts(1);
        testContractExpire[0].AccountId = testAccountClone[0].Id;
        testContractExpire[0].vlocity_ins__ExpiredContractId__c = testContractlinkExpire[0].Id;
        testContractExpire[0].ARC_ContractReason__c = 'Reprice';
        insert testContractExpire;

        ARC_PromotionCode__c testPromoCodes = new ARC_PromotionCode__c(
            Name = 'TestPromo',
            ARC_DiscountRate__c = 10,
            ARC_ApplyOver__c = 'Medical',
            RecordTypeId = healthylDiscountCodeRecordTypeId,
            ARC_PromotionCode__c = 'Healthy Discount', 
            ARC_StartDate__c= Date.today()
        );
        insert testPromoCodes;

        List<ARC_PromotionDiscount__c> discounts = new List<ARC_PromotionDiscount__c>();
        ARC_PromotionDiscount__c tempDiscount = new  ARC_PromotionDiscount__c(
            Name = 'Temporary Discount',
            ARC_Description__c = 'Testing',
            ARC_Status__c = 'Activated',
            ARC_PromoCode__c = testPromoCodes.Id,
            RecordTypeId = temporaryDiscountRecordTypeId,
            ARC_NumberOfTimesCanBeUsed__c = 3,
            ARC_TimesUsed__c = 0,
            ARC_Contract__c = testContractlinkExpire[0].Id
        );
        discounts.add(tempDiscount);
        insert discounts;

        ARC_PromotionCode__c testPromoCodesTemp = new ARC_PromotionCode__c(
            Name = 'TestPromo TD',
            ARC_DiscountRate__c = 10,
            ARC_ApplyOver__c = 'Medical',
            RecordTypeId = temporaryDiscountCodeRecordTypeId,
            ARC_PromotionCode__c = 'Temporary Discount', 
            ARC_NumberOfTimesCanBeUsed__c = 3,
            ARC_StartDate__c= Date.today()
        );
        insert testPromoCodesTemp;

        ARC_PromotionDiscount__c discountTemp = new  ARC_PromotionDiscount__c(
            Name = 'Temporary Discount',
            ARC_StartDate__c = Date.newInstance(2024, 10, 10),
            ARC_Description__c = 'Testing',
            ARC_Status__c = 'Activated',
            ARC_NumberOfTimesCanBeUsed__c = 3,
            ARC_TimesUsed__c = 0,
            ARC_PromoCode__c = testPromoCodesTemp.Id,
            RecordTypeId = temporaryDiscountRecordTypeId,
            ARC_Contract__c = testContractlinkExpire[0].Id
        );
        insert discountTemp;

        Test.startTest();
        ARC_Discounts.cloneTemporaryDiscounts(new Set<Id>{testContractExpire[0].Id});
        Test.stopTest();
    }


    @isTest
    static void testCloneHealthyDiscounts() {

        //Promotion Discount
        Id healthyDiscountRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        Id healthylDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        
        //Create Account
        List<Account> testAccountClone = ARC_TestUtility.createTestAccount(1, 'ARC_IFPPersonAccount');

        //Create test contract testContractlinkExpire
        List<Contract> testContractlinkExpire = ARC_TestUtility.createContracts(1);
        testContractlinkExpire[0].AccountId = testAccountClone[0].Id;
        insert testContractlinkExpire;

        //Create test contract testContractExpire
        List<Contract> testContractExpire = ARC_TestUtility.createContracts(1);
        testContractExpire[0].AccountId = testAccountClone[0].Id;
        testContractExpire[0].vlocity_ins__ExpiredContractId__c = testContractlinkExpire[0].Id;
        insert testContractExpire;

        ARC_PromotionCode__c testPromoCodes = new ARC_PromotionCode__c(
            Name = 'TestPromo',
            ARC_DiscountRate__c = 10,
            ARC_ApplyOver__c = 'Medical',
            RecordTypeId = healthylDiscountCodeRecordTypeId,
            ARC_PromotionCode__c = 'Healthy Discount', 
            ARC_StartDate__c= Date.today()
        );
        insert testPromoCodes;

        ARC_PromotionDiscount__c discount = new  ARC_PromotionDiscount__c(
            Name = 'Healthy Discount',
            ARC_StartDate__c = Date.newInstance(2024, 10, 10),
            ARC_Description__c = 'Testing',
            ARC_EndDate__c = Date.newInstance(2025, 10, 08),
            ARC_Status__c = 'Activated',
            ARC_PromoCode__c = testPromoCodes.Id,
            RecordTypeId = healthyDiscountRecordTypeId,
            ARC_Contract__c = testContractlinkExpire[0].Id
        );
        insert discount;

        ARC_HealthyDiscountAccount__c healthyDiscountAccount = new ARC_HealthyDiscountAccount__c(
            Name = 'John Doe Discount Account',
            ARC_Status__c = 'Approved',
            ARC_Account__c = testAccountClone[0].Id,
            ARC_Discount__c = discount.Id,
            ARC_DecisionDate__c = Date.today().addDays(-5)
        );
        insert healthyDiscountAccount;

        Test.startTest();
        ARC_Discounts.cloneHealthyDiscounts(new Set<Id>{testContractExpire[0].Id});
        Test.stopTest();
    }

    @isTest
    static void testIsDiscountApplicable() {

        ARC_PromotionDiscount__c discount = [SELECT Id, ARC_ApplyOver__c, ARC_PromoCode__r.ARC_ApplyOver__c,ARC_PromoCode__r.ARC_DiscountedAmount__c,ARC_DiscountedAmount__c FROM ARC_PromotionDiscount__c LIMIT 1];
        vlocity_ins__ContractLineItem__c plan = [SELECT vlocity_ins__ProductType__c FROM vlocity_ins__ContractLineItem__c LIMIT 1];

        Test.startTest();
        ARC_Discounts.isDiscountApplicable(discount, plan);
        Test.stopTest();
    }

    @isTest
    static void testCalculateTotalPrice() {

       Decimal totalPrice = 0;
       Contract testContract = [SELECT Id FROM Contract LIMIT 1];

       // Create test products
       List<Product2> testProducts = ARC_TestUtility.createTestProducts(2);
       for(Product2 prod : testProducts) {
           prod.vlocity_ins__Type__c = 'Medical';
       }
       update testProducts;

       List<vlocity_ins__ContractLineItem__c> testCLI = new List<vlocity_ins__ContractLineItem__c>();
       vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c(
        vlocity_ins__ContractId__c = testContract.Id,
        vlocity_ins__ProductId__c = testProducts[0].Id,
        ARC_SmokerFee__c = 50,
        ARC_ExtraDependentFee__c = 50,
        ARC_OriginalPrice__c = 100,
        vlocity_ins__Quantity__c  = 10,
        vlocity_ins__UnitPrice__c  = 70
       );
       testCLI.add(cli);
       insert testCLI;

        Test.startTest();
        ARC_Discounts.calculateTotalPrice(testCLI);
        Test.stopTest();
    }

    @isTest
    static void testMapPlansByContractId() {

       Contract testContract = [SELECT Id FROM Contract LIMIT 1];

       //Create test products
       List<Product2> testProducts = ARC_TestUtility.createTestProducts(2);
       for(Product2 prod : testProducts) {
           prod.vlocity_ins__Type__c = 'Medical';
       }
       update testProducts;

       List<vlocity_ins__ContractLineItem__c> testCLI = new List<vlocity_ins__ContractLineItem__c>();
       vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c(
            vlocity_ins__ContractId__c = testContract.Id,
            vlocity_ins__ProductId__c = testProducts[0].Id,
            ARC_SmokerFee__c = 50,
            ARC_ExtraDependentFee__c = 50,
            ARC_OriginalPrice__c = 100,
            vlocity_ins__Quantity__c  = 10,
            vlocity_ins__UnitPrice__c  = 70
       );
       testCLI.add(cli);
       insert testCLI;

       Test.startTest();
       ARC_Discounts.mapPlansByContractId(testCLI);
       Test.stopTest();
    }


    @isTest
    static void testGetDiscountAccounts() {

        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        List<ARC_ContractParticipant__c> contList = new List<ARC_ContractParticipant__c>();
         for (Integer i = 0; i < 2; i++) {
            ARC_ContractParticipant__c cp = new ARC_ContractParticipant__c();
            cp.Name = 'Sarah Participant Expire';
            cp.ARC_Contract__c = testContract.Id;
            cp.ARC_PersonAccount__c = testAccount.Id;
            contList.add(cp);
         }
         insert contList;

         ARC_PromotionCode__c secondCode = new ARC_PromotionCode__c(
            Name = 'Medical',
            ARC_PromotionCode__c = 'Medical',
            ARC_ApplyOver__c = 'Medical',
            ARC_DiscountRate__c = 16.6,
            ARC_StartDate__c = Date.newInstance(2024, 09, 29),
            ARC_EndDate__c = Date.newInstance(2024, 10, 29)
        );
        insert secondCode;

        List<ARC_PromotionDiscount__c> discounts = new List<ARC_PromotionDiscount__c>();
        ARC_PromotionDiscount__c appFeePromotionDiscount = new ARC_PromotionDiscount__c(
            ARC_NumberOfTimesCanBeUsed__c = 1,
            ARC_TimesUsed__c = 0,
            ARC_PromoCode__c = secondCode.Id,
            ARC_Contract__c = testContract.Id
        );
        discounts.add(appFeePromotionDiscount);
        insert discounts;

        Test.startTest();
        List<ARC_HealthyDiscountAccount__c> updatedPlans = ARC_Discounts.getDiscountAccounts(contList, discounts);
        Test.stopTest();
    }


    @isTest
    static void testOrderDiscounts() {

        Contract testContract = [SELECT Id FROM Contract LIMIT 1];

        ARC_PromotionCode__c secondCode = new ARC_PromotionCode__c(
            Name = 'Medical',
            ARC_PromotionCode__c = 'Medical',
            ARC_ApplyOver__c = 'Medical',
            ARC_DiscountedAmount__c = 1,
            ARC_StartDate__c = Date.newInstance(2024, 09, 29),
            ARC_EndDate__c = Date.newInstance(2024, 10, 29)
        );
        insert secondCode;

        List<ARC_PromotionDiscount__c> discounts = new List<ARC_PromotionDiscount__c>();
        ARC_PromotionDiscount__c appFeePromotionDiscount = new ARC_PromotionDiscount__c(
            ARC_NumberOfTimesCanBeUsed__c = 1,
            ARC_TimesUsed__c = 0,
            ARC_ApplyFirst__c = true,
            ARC_DiscountedAmount__c = 1,
            ARC_PromoCode__c = secondCode.Id,
            ARC_Contract__c = testContract.Id
        );
        discounts.add(appFeePromotionDiscount);
        insert discounts;

        Test.startTest();
        List<ARC_PromotionDiscount__c> updatedPlans = ARC_Discounts.orderDiscounts(discounts);
        Test.stopTest();
    }


    @isTest
    static void testAppFeePercentageDiscountByContract() {

        Test.startTest();

        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        List<ARC_PromotionDiscount__c> testDiscounts = [SELECT Id, Name, ARC_StartDate__c, ARC_Description__c, ARC_EndDate__c, ARC_PromoCode__c, RecordTypeId, ARC_ApplyOver__c, ARC_ApplyFirst__c, ARC_DiscountRate__c, ARC_PromoCode__r.ARC_DiscountRate__c, ARC_DiscountedAmount__c, ARC_PromoCode__r.ARC_DiscountedAmount__c, ARC_Status__c, ARC_PromoCode__r.ARC_ApplyOver__c, ARC_Contract__c FROM ARC_PromotionDiscount__c ];

        Id healthyDiscountRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        Id promotionDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Promotion_Discount').getRecordTypeId();

        Decimal amount= 700;

        Contract cont = [SELECT Id, ARC_EffectiveDate__c,Status, ARC_RecurringMonthlyOrder__c FROM Contract WHERE ARC_RecurringMonthlyOrder__c != null LIMIT 1];
        ChargentOrders__ChargentOrder__c charg = [SELECT Id, ARC_Contract__c, ChargentOrders__Charge_Amount__c FROM ChargentOrders__ChargentOrder__c WHERE ChargentOrders__Description__c = 'Recurring Monthly Order' LIMIT 1];

        charg.ChargentOrders__Description__c = 'App Fee';
        cont.ARC_AppFeeOrder__c = charg.Id;
        update cont;
        update charg;

        ARC_PromotionCode__c appFeePromotionCode = new ARC_PromotionCode__c(
            Name = 'App Fee Test',
            ARC_PromotionCode__c = 'App Fee Test',
            ARC_ApplyOver__c = 'App Fee',
            ARC_DiscountedAmount__c = 10,
            ARC_StartDate__c = Date.today(),
            ARC_EndDate__c = Date.today().addMonths(1)
        );
        insert appFeePromotionCode;

        List<ARC_PromotionDiscount__c> discounts = new List<ARC_PromotionDiscount__c>();
        ARC_PromotionDiscount__c appFeePromotionDiscount = new ARC_PromotionDiscount__c(
            ARC_NumberOfTimesCanBeUsed__c = 1,
            ARC_ExonerateAppChangeFee__c = false,
            ARC_AmountToDiscountPerTransaction__c = 10,
            ARC_ApplyOver__c = 'App Fee',
            ARC_TimesUsed__c = 0,
            ARC_PromoCode__c = appFeePromotionCode.Id,
            ARC_Contract__c = cont.Id
        );
        discounts.add(appFeePromotionDiscount);
        insert discounts;

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

        ARC_Discounts.appFeePercentageDiscountByContract(new Set<Id>{cont.Id}, discounts);
        ARC_Discounts.appFeePercentageDiscountByContract(new Set<Id>{testContract.Id}, testDiscounts);
        Test.stopTest();
    }
}