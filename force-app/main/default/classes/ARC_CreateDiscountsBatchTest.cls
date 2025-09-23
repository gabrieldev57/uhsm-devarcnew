@isTest
public with sharing class ARC_CreateDiscountsBatchTest {
    @TestSetup
    static void makeData(){
        Id renewalDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Renewal_Discount').getRecordTypeId();
        ARC_PromotionCode__c renewalPromoCode = new ARC_PromotionCode__c(
            Name = 'Ren Promo',
            ARC_DiscountRate__c = 10,
            ARC_ApplyOver__c = 'Medical',
            ARC_PromotionCode__c = 'Renewal Discount 0',
            ARC_RenewalDiscountNumber__c = 0, 
            RecordTypeId = renewalDiscountCodeRecordTypeId,
            ARC_StartDate__c= Date.today()
        );
        upsert renewalPromoCode;

        Id healthyDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        ARC_PromotionCode__c hdPromoCode = new ARC_PromotionCode__c(
            Name = 'HD Promo',
            ARC_DiscountRate__c = 10,
            ARC_ApplyOver__c = 'Medical',
            RecordTypeId = healthyDiscountCodeRecordTypeId,
            ARC_PromotionCode__c = 'Healthy Discount', 
            ARC_StartDate__c= Date.today()
        );
        upsert hdPromoCode;

        List<Contract> enrollmentsCreated = ARC_TestUtility.createCompleteEnrollments(1);
    }

    @isTest
    static void ARC_CreateDiscountsBatchTest() {
        List<Contract> contract = [SELECT Id FROM Contract];

        Id renRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Renewal_Discount').getRecordTypeId();
        List<ARC_PromotionCode__c> renewalPromoCode = [SELECT Id FROM ARC_PromotionCode__c WHERE Name = 'Ren Promo'];
        ARC_PromotionDiscount__c renDiscount = new ARC_PromotionDiscount__c(
            Name = 'Renewal Discount',
            ARC_StartDate__c = Date.today(),
            ARC_Description__c = 'Testing', 
            ARC_EndDate__c = Date.today().addYears(1).addDays(-1),
            ARC_Contract__c = contract[0].Id,
            ARC_PromoCode__c = renewalPromoCode[0].Id,
            ARC_ApplyFirst__c = true,
            ARC_Status__c = 'Activated',
            ARC_DiscountRate__c = 10,
            ARC_PriceWithoutDiscount__c = 7.9,
            ARC_NumberOfTimesCanBeUsed__c = 0,
            ARC_PriceWithDiscount__c = 6.9,
            ARC_DiscountedAmount__c = 0,
            ARC_ApplyOver__c = 'Medical',
            RecordTypeId = renRecordTypeId
        );

        Id hdRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        List<ARC_PromotionCode__c> hdPromoCode = [SELECT Id FROM ARC_PromotionCode__c WHERE Name = 'HD Promo'];
        ARC_PromotionDiscount__c hdDiscount = new ARC_PromotionDiscount__c(
            Name = 'Healthy Discount',
            ARC_StartDate__c = Date.today(),
            ARC_Description__c = 'Testing', 
            ARC_EndDate__c = Date.today().addYears(1).addDays(-1),
            ARC_Contract__c = contract[0].Id,
            ARC_PromoCode__c = hdPromoCode[0].Id,
            ARC_ApplyFirst__c = true,
            ARC_Status__c = 'Activated',
            ARC_DiscountRate__c = 10,
            ARC_PriceWithoutDiscount__c = 7.9,
            ARC_NumberOfTimesCanBeUsed__c = 0,
            ARC_PriceWithDiscount__c = 6.9,
            ARC_DiscountedAmount__c = 0,
            ARC_ApplyOver__c = 'Medical',
            RecordTypeId = hdRecordTypeId
        );

        List<ARC_PromotionDiscount__c> discounts = new List<ARC_PromotionDiscount__c>();
        discounts.add(renDiscount);
        discounts.add(hdDiscount);

        Test.startTest();
        ARC_CreateDiscountsBatch batch = new ARC_CreateDiscountsBatch(discounts);
        Database.executeBatch(batch);
        Test.stopTest();

        List<ARC_PromotionDiscount__c> results = [SELECT Id FROM ARC_PromotionDiscount__c];
        System.assertEquals(2, results.size());
    }
}