@isTest
private class ARC_BackfillTLIPromotionTest {

    @TestSetup
    static void makeData(){
        List<Contract> cont = ARC_TestUtility.createContractsAA(1);
        cont[0].Name = 'WeShare test 0';
        insert cont;
/*
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account acc = new Account(
            RecordTypeId = accRecordTypeId,
            FirstName = 'PersonAccount', 
            LastName ='Test',
            BillingStreet = '123 Avenue',
            BillingState = 'NY',
            BillingCity = 'New York',
            BillingPostalCode='12345',
            PersonEmail='test@email.com',
            ARC_IsPrimaryMember__c = true,
            ARC_E123MemberIdFromPolicy__c = 'W123456789',
            IsActive = True
        );
        insert acc;

        Account accGroup = new Account(Name = 'Test');
        insert accGroup;
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(
            Name = 'census test',
            vlocity_ins__GroupId__c = accGroup.Id,
            ARC_PrimaryAccount__c = acc.Id
        );
        insert census;

        List <Account> accountListContactIds = [SELECT PersonContactId FROM Account WHERE FirstName Like 'PersonAccount%' ORDER BY FirstName];
        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c(
            Name = 'Test Census Member',
            vlocity_ins__FirstName__c = 'Test',
            vlocity_ins__LastName__c = 'Census Member',
            vlocity_ins__CensusId__c = census.Id,
            vlocity_ins__SocialSecurityNumber__c = '123456789',
            vlocity_ins__ContactId__c = accountListContactIds[0].PersonContactId
        );
        insert censusMember;

        List<vlocity_ins__GroupCensusMember__c> censusData =[SELECT Id, vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c];
        acc.Census_Member__c = censusMember.Id;
        acc.ARC_CensusMember__pc = censusMember.Id;
        acc.ARC_Census__c = censusMember.vlocity_ins__CensusId__c;
        update acc;
        */
        List<ChargentOrders__ChargentOrder__c> chargentList = new List<ChargentOrders__ChargentOrder__c>();
        for (Integer i = 0; i < 3; i++) {
            ChargentOrders__ChargentOrder__c chargent = new ChargentOrders__ChargentOrder__c();
            chargent.ARC_Contract__c = cont[0].Id;
            chargent.ChargentOrders__Shipping__c = 123;
            chargent.ChargentOrders__Tax__c  = 123;
            chargent.ChargentOrders__Charge_Amount__c = 123;
            chargent.ChargentOrders__Subtotal__c  = 123;
            chargent.ChargentOrders__Charge_Date__c =  '01';
            chargent.ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3);
            chargent.ChargentOrders__Payment_Status__c = 'Recurring';
            chargent.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2021, 11, 12);
            chargent.ChargentOrders__Payment_Method__c = 'Credit Card';
            chargent.ChargentOrders__Card_Last_4__c = '1234';
            chargent.ChargentOrders__Card_Type__c = 'VISA';
            chargent.ChargentOrders__Card_Expiration_Month__c = '12';
            chargent.ChargentOrders__Card_Expiration_Year__c = '2024';
            chargent.ChargentOrders__Tokenization__c = '12345678';
            chargent.ChargentOrders__Description__c = 'Recurring Monthly Order';
            chargentList.add(chargent);
        }
        insert chargentList;

        //cont[0].vlocity_ins__EnrollmentCensusId__c = census.Id;
        cont[0].Status = 'Activated';
        update cont;
        
        // Create test promo codes Renewal Discount
        Id renewalDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Renewal_Discount').getRecordTypeId();
        ARC_PromotionCode__c renewalPromoCode = new ARC_PromotionCode__c(
            Name = 'Renewal Discount',
            ARC_DiscountRate__c = 10,
            ARC_ApplyOver__c = 'Medical',
            ARC_PromotionCode__c = 'Renewal Discount 0',
            ARC_RenewalDiscountNumber__c = 0, 
            RecordTypeId = renewalDiscountCodeRecordTypeId,
            ARC_StartDate__c = Date.newInstance(2024, 09, 29)
        );
        insert renewalPromoCode;

        Id renRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Renewal_Discount').getRecordTypeId();
        ARC_PromotionDiscount__c renDiscount = new ARC_PromotionDiscount__c(
            Name = 'Renewal Discount',
            ARC_StartDate__c = Date.today(),
            ARC_Description__c = 'Testing', 
            ARC_EndDate__c = Date.today().addYears(1).addDays(-1),
            ARC_Contract__c = cont[0].Id,
            ARC_PromoCode__c = renewalPromoCode.Id,
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
        insert renDiscount;

        Id healthyDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        List<ARC_PromotionCode__c> testPromoCodes = new List<ARC_PromotionCode__c>();
        for(Integer i = 0; i < 1; i++) {
            ARC_PromotionCode__c promoCode = new ARC_PromotionCode__c(
                Name = 'TestPromo' + i,
                ARC_DiscountRate__c = 10,
                ARC_ApplyOver__c = 'Medical',
                RecordTypeId = healthyDiscountCodeRecordTypeId,
                ARC_PromotionCode__c = 'Healthy Discount' + i, 
                ARC_StartDate__c= Date.today()
            );
            testPromoCodes.add(promoCode);
        }
        insert testPromoCodes;

        Id hdRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        List<ARC_PromotionDiscount__c> hdDiscountList = new List<ARC_PromotionDiscount__c>();
        for(Integer i = 0; i < 1; i++) {
            ARC_PromotionDiscount__c discount = new ARC_PromotionDiscount__c(
                Name = 'Healthy Discount',
                ARC_StartDate__c = Date.today(),
                ARC_Description__c = 'Testing', 
                ARC_EndDate__c = Date.today().addYears(1).addDays(-1),
                ARC_Contract__c = cont[0].Id,
                ARC_PromoCode__c = testPromoCodes[i].Id,
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
            hdDiscountList.add(discount);
        }
        //hdDiscountList[1].ARC_Status__c = 'Terminated';
        //hdDiscountList[1].ARC_StartDate__c = Date.today().addDays(-1);
        //hdDiscountList[1].ARC_EndDate__c = Date.today().addDays(-1);
        insert hdDiscountList;

        List<ChargentOrders__Transaction__c> coTransactions = new List<ChargentOrders__Transaction__c>();
        for (Integer i = 0; i < 2; i++) {
            ChargentOrders__Transaction__c coTransaction = new ChargentOrders__Transaction__c();
            coTransaction.ChargentOrders__Order__c = chargentList[i].Id;
            coTransactions.add(coTransaction);
        }
        coTransactions[0].ARC_PromotionDiscount__c = hdDiscountList[0].Id;
        //coTransactions[1].ARC_PromotionDiscount__c = hdDiscountList[1].Id;
        coTransactions[1].ARC_PromotionDiscount__c = renDiscount.Id;
        insert coTransactions;

        List<ARC_TransactionLineItem__c> transactionLIList = new List<ARC_TransactionLineItem__c>();
        for (Integer i = 0; i < 2; i++) {
            ARC_TransactionLineItem__c tli = new ARC_TransactionLineItem__c();
            tli.ARC_Transaction__c = coTransactions[i].Id;
            transactionLIList.add(tli);
        }
        transactionLIList[0].Name = 'Healthy Discount 0';
        //transactionLIList[1].Name = 'Healthy Discount 1';
        transactionLIList[1].Name = 'Renewal Discount 0';
        insert transactionLIList;
    }

    @isTest
    static void ARC_BackfillTLIPromotionTest() {
        Test.startTest();
        ARC_BackfillTLIPromotion batch = new ARC_BackfillTLIPromotion();
        Database.executeBatch(batch);
        Test.stopTest();

        List<ARC_TransactionLineItem__c> results = [SELECT Name, ARC_Transaction__r.ARC_PromotionDiscount__c, ARC_PromotionDiscount__c FROM ARC_TransactionLineItem__c WHERE Name LIKE '%Discount%'];
        List<ARC_PromotionDiscount__c> hdActiveList = [SELECT Id FROM ARC_PromotionDiscount__c WHERE ARC_Status__c = 'Activated' AND Name = 'Healthy Discount'];
        for (ARC_TransactionLineItem__c tli : results) {
            if (tli.Name == 'Renewal Discount 0') {
                Assert.areEqual(tli.ARC_Transaction__r.ARC_PromotionDiscount__c, tli.ARC_PromotionDiscount__c);
            } else {
                Assert.areEqual(hdActiveList[0].Id, tli.ARC_PromotionDiscount__c);
            }
        }
    }

    @isTest
    static void ARC_BackfillTLIPromotionWithIdsTest() {
        List<ARC_TransactionLineItem__c> tliList = [SELECT Id FROM ARC_TransactionLineItem__c WHERE Name LIKE '%Discount%'];
        Set<Id> tliIds = new Set<Id>();
        for (ARC_TransactionLineItem__c tli : tliList) {
            tliIds.add(tli.Id);
        }

        Test.startTest();
        ARC_BackfillTLIPromotion batch = new ARC_BackfillTLIPromotion(tliIds);
        Database.executeBatch(batch);
        Test.stopTest();

        List<ARC_TransactionLineItem__c> results = [SELECT Name, ARC_Transaction__r.ARC_PromotionDiscount__c, ARC_PromotionDiscount__c FROM ARC_TransactionLineItem__c WHERE Name LIKE '%Discount%'];
        List<ARC_PromotionDiscount__c> hdActiveList = [SELECT Id FROM ARC_PromotionDiscount__c WHERE ARC_Status__c = 'Activated' AND Name = 'Healthy Discount'];
        for (ARC_TransactionLineItem__c tli : results) {
            if (tli.Name == 'Renewal Discount 0') {
                Assert.areEqual(tli.ARC_Transaction__r.ARC_PromotionDiscount__c, tli.ARC_PromotionDiscount__c);
            } else {
                Assert.areEqual(hdActiveList[0].Id, tli.ARC_PromotionDiscount__c);
            }
        }
    }
}