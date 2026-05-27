@isTest
public class ARC_ScheduleRenewalDiscountCreationTest {
    
    @TestSetup
    static void makeData() {
        
        //Create Record Types
        Id renewalDiscountRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Renewal_Discount').getRecordTypeId();
        Id renewalDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Renewal_Discount').getRecordTypeId();

        //Create Account
        Account acc = new Account(FirstName='Account', LastName='Test', BillingStreet='2nd Avenue', BillingState='NY', BillingPostalCode='12345', BillingCity='New York', ARC_Provider_Name__c='Ins Provider',ARC_Provider_Tax_Id__c=1234567, ARC_NationalProviderId__c='23322');
        insert acc;

        //Create Contact
        List<Contact> conta = ARC_TestUtility.createTestContact(1,'IndustriesIndividual');
		conta[0].Email = 'testEmail@email.com';
		update conta; 
		 
        //Create vlocity_ins__GroupCensusMember__c
		List<vlocity_ins__GroupCensusMember__c> censMemb = ARC_TestUtility.createTestCensusMember(1);
		censMemb[0].ARC_PhysicalAddressState__c = 'CA';
		censMemb[0].vlocity_ins__IsPrimaryMember__c = true;
		censMemb[0].ARC_ActiveMember__c = true;
        censMemb[0].ARC_ContinuousMembershipStartDate__c = Date.today().addYears(-1).addDays(-1);
		censMemb[0].vlocity_ins__ContactId__c = conta[0].Id; 
		censMemb[0].vlocity_ins__FirstName__c = 'TestFirstName';
		censMemb[0].vlocity_ins__Birthdate__c = Date.newInstance(1980, 11, 1); 
		update censMemb;

        //Create Contract
		List<Contract> cont = ARC_TestUtility.createContractsAA(1);
        Id individualAndFamilyRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_IndividualAndFamily').getRecordTypeId();
		cont[0].vlocity_ins__EnrollmentCensusId__c = censMemb[0].vlocity_ins__CensusId__c;
		cont[0].ARC_EffectiveDate__c = Date.today().addYears(-1).addDays(-1);
        cont[0].ARC_PaidThroughDate__c = System.today().addDays(1);
        cont[0].RecordTypeId = individualAndFamilyRecordTypeId;
		insert cont;
		cont[0].Status = 'Activated';
		update cont;

        //Create Chargent Order    
        ChargentOrders__ChargentOrder__c chargent=new ChargentOrders__ChargentOrder__c();
        chargent.ARC_Contract__c = cont[0].Id;
        chargent.ChargentOrders__Shipping__c = 232;
        chargent.ChargentOrders__Tax__c  = 232;
        chargent.ChargentOrders__Charge_Amount__c = 232;
        chargent.ChargentOrders__Subtotal__c  = 232;
        chargent.ChargentOrders__Charge_Date__c =  '01';
        chargent.ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3);
        chargent.ChargentOrders__Payment_Status__c = 'Recurring';
        chargent.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12);
        chargent.ChargentOrders__Payment_Method__c = 'Credit Card';
        chargent.ChargentOrders__Card_Last_4__c = '1234';
        chargent.ChargentOrders__Card_Type__c = 'VISA';
        chargent.ChargentOrders__Card_Expiration_Month__c = '10';
        chargent.ChargentOrders__Card_Expiration_Year__c = '2025';
        chargent.ChargentOrders__Tokenization__c = '12345678';
        chargent.ChargentOrders__Description__c = 'Recurring Monthly Order';
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
            cli.vlocity_ins__ContractId__c = cont[0].Id;
            cli.vlocity_ins__ProductId__c = testProducts[i].Id;
            cli.ARC_OriginalPrice__c = 100;
        }
        update testCLIs;

        // Create test promo codes
        List<ARC_PromotionCode__c> testPromoCodes = new List<ARC_PromotionCode__c>();
        for(Integer i = 0; i < 5; i++) {
            ARC_PromotionCode__c promoCode = new ARC_PromotionCode__c(
                Name = 'TestPromo' + i,
                ARC_DiscountRate__c = 10,
                ARC_ApplyOver__c = 'Medical',
                ARC_PromotionCode__c = 'Renewal Discount' + i,
                ARC_RenewalDiscountNumber__c = i,
                ARC_StartDate__c = System.today(),
                RecordTypeId = renewalDiscountCodeRecordTypeId
            );
            testPromoCodes.add(promoCode);
        }
        insert testPromoCodes;
    }

    @isTest
    static void testCreateRenewalDiscounts() {
        List<vlocity_ins__GroupCensusMember__c> censMembers = [SELECT Id, vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c];
        for(vlocity_ins__GroupCensusMember__c cm : censMembers) {
            cm.ARC_ContinuousMembershipStartDate__c = Date.today().addYears(-1).addDays(-1);
            cm.ARC_ActiveMember__c = true;
            System.debug('CENSUS MEMB: '+cm.vlocity_ins__CensusId__c);
        }
        update censMembers;

        List<Contract> c = [SELECT Id,vlocity_ins__EnrollmentCensusId__c, vlocity_ins__EnrollmentCensusId__r.ARC_MinContinuousMembershipStartDate__c FROM Contract];
        for(Contract con : c) {
            System.debug('census: '+con.vlocity_ins__EnrollmentCensusId__c);
            System.debug ('MIN CMSD: '+con.vlocity_ins__EnrollmentCensusId__r?.ARC_MinContinuousMembershipStartDate__c);
        }
        Test.startTest();
        ARC_ScheduleRenewalDiscountCreation schedulableJob = new ARC_ScheduleRenewalDiscountCreation();
        schedulableJob.execute(null);
        Test.stopTest();
    }

    @isTest
    static void testExecute() {

        Id renewalDiscountRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Renewal_Discount').getRecordTypeId();
        Id renewalDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Renewal_Discount').getRecordTypeId();

        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        ARC_PromotionCode__c testPromotionCode = [SELECT Id FROM ARC_PromotionCode__c LIMIT 1];

        // Create test promotion discounts
        List<ARC_PromotionDiscount__c> testDiscounts = new List<ARC_PromotionDiscount__c>();
        for(Integer i = 0; i < 2; i++) {
            ARC_PromotionDiscount__c discount = new ARC_PromotionDiscount__c(
                ARC_Contract__c = testContract.Id,
                ARC_PromoCode__c = testPromotionCode.Id,
                ARC_Status__c = 'Activated',
                ARC_DiscountRate__c = 10,
                ARC_ApplyOver__c = 'Medical',
                ARC_StartDate__c = date.today(),
                RecordTypeId = renewalDiscountRecordTypeId
            );
            testDiscounts.add(discount);
        }
        insert testDiscounts;

        Test.startTest();
        ARC_ScheduleRenewalDiscountCreation schedulableJob = new ARC_ScheduleRenewalDiscountCreation();
        schedulableJob.execute(null);
        Test.stopTest();
    }
}