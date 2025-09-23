@isTest
private class ARC_RenewalDiscountEmailTest {
    @TestSetup
    static void setupTestData() {
        // Create test account with person contact and insert
        List<Account> testAccounts = ARC_TestUtility.createTestAccount(1, 'ARC_IFPPersonAccount');
        // insert testAccounts;
        
        // Now update the account with email
        Account testAccount = testAccounts[0];
        testAccount.PersonEmail = 'test@example.com';
        update testAccount;
        
        // Create Census
        vlocity_ins__GroupCensus__c census = ARC_TestUtility.createTestCensus(1)[0];
        census.ARC_PrimaryAccount__c = testAccount.Id;
        update census;
        
        // Create Contract
        Contract testContract = ARC_TestUtility.createContracts(1)[0];
        testContract.vlocity_ins__EnrollmentCensusId__c = census.Id;
        insert testContract;
        
        // Create Email Template for First Renewal
        // EmailTemplate firstRenewalTemplate = new EmailTemplate(
        //     Name = 'Discount First Renewal',
        //     DeveloperName = 'Discount_First_Renewal',
        //     TemplateType = 'text',
        //     FolderId = UserInfo.getUserId(),
        //     Subject = 'First Renewal Discount',
        //     Body = 'Test Template Body'
        // );
        // insert firstRenewalTemplate;
        
        // Create Email Template for Increase Renewal
        // EmailTemplate increaseRenewalTemplate = new EmailTemplate(
        //     Name = 'Discount Increase Renewal',
        //     DeveloperName = 'Discount_Increase_Renewal',
        //     TemplateType = 'text',
        //     FolderId = UserInfo.getUserId(),
        //     Subject = 'Increase Renewal Discount',
        //     Body = 'Test Template Body'
        // );
        // insert increaseRenewalTemplate;
        
    }
    
    @isTest
    static void testFirstRenewalDiscountEmail() {
        // Get the test contract
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        
        ARC_PromotionCode__c promoCode = new ARC_PromotionCode__c(
            Name = 'Healthy Discount',
            ARC_DiscountRate__c = 10,
            ARC_ApplyOver__c = 'Medical',
            ARC_PromotionCode__c = 'Healthy Discount', 
            ARC_StartDate__c= Date.today()
        );
        insert promoCode;

        // Create Promotion Discount record for first renewal
        ARC_PromotionDiscount__c discount = new ARC_PromotionDiscount__c(
            ARC_Contract__c = testContract.Id,
            ARC_RenewalDiscountNumber__c = 1,
            ARC_ApplyFirst__c = false,
            ARC_PromoCode__c = promoCode.Id
        );
        insert discount;
        
        Test.startTest();
        ARC_RenewalDiscountEmail.sendRenewalDiscountEmail(new List<ARC_PromotionDiscount__c>{discount});
        Test.stopTest();
        
    }
    
    @isTest
    static void testIncreaseRenewalDiscountEmail() {
        // Get the test contract
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        
        // Create Promotion Discount record for increase renewal
        ARC_PromotionCode__c promoCode = new ARC_PromotionCode__c(
            Name = 'Healthy Discount',
            ARC_DiscountRate__c = 10,
            ARC_ApplyOver__c = 'Medical',
            ARC_PromotionCode__c = 'Healthy Discount', 
            ARC_StartDate__c= Date.today()
        );
        insert promoCode;

        // Create Promotion Discount record for first renewal
        ARC_PromotionDiscount__c discount = new ARC_PromotionDiscount__c(
            ARC_Contract__c = testContract.Id,
            ARC_RenewalDiscountNumber__c = 2,
            ARC_ApplyFirst__c = false,
            ARC_PromoCode__c = promoCode.Id
        );
        insert discount;
        
        Test.startTest();
        ARC_RenewalDiscountEmail.sendRenewalDiscountEmail(new List<ARC_PromotionDiscount__c>{discount});
        Test.stopTest();
        
        // Verify email was sent
    }
    
    @isTest
    static void testEmailSendingError() {
        // Get the test contract and account
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Update account with invalid email
        testAccount.PersonEmail = 'invalidemail@invalid.com';
        update testAccount;
        
        // Create Promotion Discount record
        ARC_PromotionCode__c promoCode = new ARC_PromotionCode__c(
            Name = 'Healthy Discount',
            ARC_DiscountRate__c = 10,
            ARC_ApplyOver__c = 'Medical',
            ARC_PromotionCode__c = 'Healthy Discount', 
            ARC_StartDate__c= Date.today()
        );
        insert promoCode;

        // Create Promotion Discount record for first renewal
        ARC_PromotionDiscount__c discount = new ARC_PromotionDiscount__c(
            ARC_Contract__c = testContract.Id,
            ARC_RenewalDiscountNumber__c = 1,
            ARC_ApplyFirst__c = false,
            ARC_PromoCode__c = promoCode.Id
        );
        insert discount;
        
        Test.startTest();
        ARC_RenewalDiscountEmail.sendRenewalDiscountEmail(new List<ARC_PromotionDiscount__c>{discount});
        Test.stopTest();
        
        // Verify that the code handles the error gracefully
        // The method should not throw an exception even with invalid email
    }
}