@isTest
public class HDEmailBatchclassTest {
  @TestSetup
    static void mockData(){
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
		testContracts[0].ARC_EffectiveDate__c = System.today();
        testContracts[0].ARC_PaidThroughDate__c = System.today();
        testContracts[0].AccountId = testAccounts[0].Id;
        insert testContracts;

        testContracts[0].Status = 'Awaiting Activation';
		testContracts[0].ARC_EffectiveDate__c = Date.today().addDays(2);
		update testContracts;

        testContracts[0].Status = 'Activated';
		testContracts[0].ARC_EffectiveDate__c = System.today();
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
         
        //Promotion Code
        Id healthylDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();

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

        insert promoCodes;

        Date dateToday = Date.today(); 

        List<ARC_PromotionDiscount__c> promotionDiscounts = new List<ARC_PromotionDiscount__c>();
        for(Integer i = 0; i < 2; i++) {
            ARC_PromotionDiscount__c discount = new ARC_PromotionDiscount__c(
                Name = 'Healthy Discount',
                ARC_StartDate__c = dateToday,
                ARC_Description__c = 'Testing', 
                ARC_EndDate__c = dateToday.addDays(90),
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
    
    @isTest
    static void testBatchExecution(){
        Test.startTest();
        HDEmailBatchclass testBatch = new HDEmailBatchclass();
        Database.executeBatch(testBatch);
        Test.stopTest();
    }

    @isTest
    static void testSchedulableExecution(){
        Test.startTest();
        HDEmailBatchclass testSchedulable = new HDEmailBatchclass();
        testSchedulable.execute(null); 
        Test.stopTest();
    }

    @isTest
    static void testBatchWithException(){
        Test.startTest();
        try {
            HDEmailBatchclass testBatch = new HDEmailBatchclass();
            Database.executeBatch(testBatch);
        } catch(Exception e) {
            System.assert(e.getMessage() != null, 'Should recieved error');
        }
        Test.stopTest();
    }
    
}