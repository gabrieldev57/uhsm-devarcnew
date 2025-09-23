@isTest

public class ARC_BackfillNewHDBatchTest {
    
    @isTest
    static void testBackfillNewHDBatch() { 

        Id healthyDiscountRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
        Id healthylDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();

        //Create Account
        Account acc = new Account(FirstName='Account', LastName='Test', BillingStreet='2nd Avenue', BillingState='NY', BillingPostalCode='12345', BillingCity='New York', ARC_Provider_Name__c='Ins Provider',ARC_Provider_Tax_Id__c=1234567, ARC_NationalProviderId__c='23322', ARC_IsPrimaryMember__c = true);
        insert acc;

        //Create Spouse Account
        Account spacc = new Account(FirstName='Account Spouse', LastName='Spouse Test', BillingStreet='2nd Avenue', BillingState='NY', BillingPostalCode='12345', BillingCity='New York', ARC_Provider_Name__c='Ins Provider',ARC_Provider_Tax_Id__c=7654321, ARC_NationalProviderId__c='22222', ARC_IsPrimaryMember__c = false, ARC_DependentRelationship__c = 'Spouse');
        insert spacc;

        //Create Contact
        List<Contact> conta = ARC_TestUtility.createTestContact(1,'IndustriesIndividual');
		conta[0].Email = 'testEmail@email.com';
		update conta; 
		
        //Create vlocity_ins__GroupCensusMember__c
		List<vlocity_ins__GroupCensusMember__c> censMemb = ARC_TestUtility.createTestCensusMember(1);
		censMemb[0].ARC_PhysicalAddressState__c = 'CA';
		censMemb[0].vlocity_ins__IsPrimaryMember__c = true;
		censMemb[0].ARC_ActiveMember__c = true;
        censMemb[0].ARC_ContinuousMembershipStartDate__c = Date.newInstance(2024, 10, 01);
		censMemb[0].vlocity_ins__ContactId__c = conta[0].Id; 
		censMemb[0].vlocity_ins__FirstName__c = 'TestFirstName';
		censMemb[0].vlocity_ins__Birthdate__c = Date.newInstance(1997, 11, 1);
		update censMemb;

        //Create Contract
		List<Contract> cont = ARC_TestUtility.createContractsAA(1);
		cont[0].vlocity_ins__EnrollmentCensusId__c = censMemb[0].vlocity_ins__CensusId__c;
		cont[0].ARC_EffectiveDate__c = System.today();
        cont[0].ARC_PaidThroughDate__c = System.today();
		insert cont;
		cont[0].Status = 'Activated';
		update cont;

        //Terminated Contract 
        List<Contract> contTerminated = ARC_TestUtility.createContractsAA(1);
		contTerminated[0].vlocity_ins__EnrollmentCensusId__c = censMemb[0].vlocity_ins__CensusId__c;
		contTerminated[0].ARC_EffectiveDate__c = System.today();
        contTerminated[0].ARC_PaidThroughDate__c = System.today();
		insert contTerminated;
		contTerminated[0].Status = 'Terminated';
		update contTerminated;

        //Awaiting Activation 
        List<Contract> contAA = ARC_TestUtility.createContractsAA(1);
		contAA[0].vlocity_ins__EnrollmentCensusId__c = censMemb[0].vlocity_ins__CensusId__c;
		contAA[0].ARC_EffectiveDate__c = System.today();
        contAA[0].ARC_PaidThroughDate__c = System.today();
		insert contAA;
		contAA[0].Status = 'Awaiting Activation';
		update contAA;

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
        for(Integer i = 0; i < 2; i++) {
            ARC_PromotionCode__c promoCode = new ARC_PromotionCode__c(
                Name = 'Healthy Discount',
                ARC_DiscountRate__c = 10,
                ARC_ApplyOver__c = 'Medical',
                ARC_PromotionCode__c = 'Healthy Discount' + i,
                ARC_RenewalDiscountNumber__c = i, 
                RecordTypeId = healthylDiscountCodeRecordTypeId,
                ARC_StartDate__c = Date.newInstance(2024, 09, 29)
            );
            testPromoCodes.add(promoCode);
        }
        insert testPromoCodes;
        
        // Create test promotion discounts
        List<ARC_PromotionDiscount__c> testDiscounts = new List<ARC_PromotionDiscount__c>();
        for(Integer i = 0; i < 2; i++) {
            ARC_PromotionDiscount__c discount = new ARC_PromotionDiscount__c(
                Name = 'Healthy Discount',
                ARC_Contract__c = cont[0].Id,
                ARC_PromoCode__c = testPromoCodes[i].Id,
                ARC_Status__c = 'Activated',
                ARC_StartDate__c = System.today(),
                ARC_EndDate__c = System.today().addDays(20),
                ARC_DiscountRate__c = 10,
                ARC_ApplyOver__c = 'Medical',
                RecordTypeId = healthyDiscountRecordTypeId
            );
            testDiscounts.add(discount);
        }
        insert testDiscounts;

        //Create Healthy Discount 
        List<Healthy_Discount__c> hdList = new List<Healthy_Discount__c>();
        for (Integer i = 0; i < 2; i++) {
            Healthy_Discount__c hd = new Healthy_Discount__c();
            hd.Name = 'hd test' + i;
            hd.New_Order_Price__c = 500;
            hd.Healthy_Discount_Price__c = 1000;
            hd.Is_Active__c = true;
            hd.PrimaryEffectivedate__c = Date.newInstance(2024, 08, 13);
            hd.Healthy_Status__c = 'Approved';
            hd.PrimaryStatus__c = 'True';
            hd.SpouseStatus__c = 'Pending';
            hd.PrimaryDecisionDate__c = Date.newInstance(2024, 08, 15);
            hd.SpouseDecisionDate__c = Date.newInstance(2024, 08, 15);
            hd.Contract__c = cont[0].Id;
            hdList.add(hd);
        }
        insert hdList;

        //Create Healthy Discount Spouse Approved
        List<Healthy_Discount__c> hdListSpApproved = new List<Healthy_Discount__c>();
        for (Integer i = 0; i < 2; i++) {
            Healthy_Discount__c hdspapproved = new Healthy_Discount__c();
            hdspapproved.Name = 'hd spouse approved';
            hdspapproved.New_Order_Price__c = 500;
            hdspapproved.Healthy_Discount_Price__c = 1000;
            hdspapproved.Is_Active__c = true;
            hdspapproved.PrimaryEffectivedate__c = Date.newInstance(2024, 08, 13);
            hdspapproved.Healthy_Status__c = 'Pending';
            hdspapproved.PrimaryStatus__c = 'Pending';
            hdspapproved.SpouseStatus__c = 'Approved';
            hdspapproved.PrimaryDecisionDate__c = Date.newInstance(2024, 08, 15);
            hdspapproved.SpouseDecisionDate__c = Date.newInstance(2024, 08, 15);
            hdspapproved.Contract__c = cont[0].Id;
            hdListSpApproved.add(hdspapproved);
        }
        insert hdListSpApproved;

        //Create Healthy Discount Spouse Denied
        List<Healthy_Discount__c> hdListSpDenied = new List<Healthy_Discount__c>();
        for (Integer i = 0; i < 2; i++) {
            Healthy_Discount__c hdspdenied = new Healthy_Discount__c();
            hdspdenied.Name = 'hd spouse Denied';
            hdspdenied.New_Order_Price__c = 500;
            hdspdenied.Healthy_Discount_Price__c = 1000;
            hdspdenied.Is_Active__c = true;
            hdspdenied.PrimaryEffectivedate__c = Date.newInstance(2024, 08, 13);
            hdspdenied.Healthy_Status__c = 'Approved';
            hdspdenied.PrimaryStatus__c = 'Denied';
            hdspdenied.SpouseStatus__c = 'Denied';
            hdspdenied.PrimaryDecisionDate__c = Date.newInstance(2024, 08, 15);
            hdspdenied.SpouseDecisionDate__c = Date.newInstance(2024, 08, 15);
            hdspdenied.Contract__c = cont[0].Id;
            hdListSpDenied.add(hdspdenied);
        }
        insert hdListSpDenied;

        //Create Contract Participants
        List<ARC_ContractParticipant__c> contractParticipantsList = new List<ARC_ContractParticipant__c>();
        for (Integer i = 0; i < 2; i++) {
            ARC_ContractParticipant__c contp = new ARC_ContractParticipant__c();
            contp.Name = 'aDdVA0000000lyD';
            contp.ARC_PersonAccount__c = acc.Id;
            contp.ARC_Contract__c = cont[0].Id;
            contractParticipantsList.add(contp);
        }
        insert contractParticipantsList;

        //Create Contract Participants
        List<ARC_ContractParticipant__c> contractParticipantSpouseList = new List<ARC_ContractParticipant__c>();
        for (Integer i = 0; i < 2; i++) {
            ARC_ContractParticipant__c contsp = new ARC_ContractParticipant__c();
            contsp.Name = 'aDdVA0000000lyF';
            contsp.ARC_PersonAccount__c = spacc.Id;
            contsp.ARC_Contract__c = cont[0].Id;
            contractParticipantSpouseList.add(contsp);
        }
        insert contractParticipantSpouseList;

        //Start Testing
        List<Contract> contracts = [SELECT Id FROM Contract WHERE Status != 'Draft'];
        Set<Id> contractIds = new Set<Id>();
        for (Contract cont2 : contracts) {
            contractIds.add(cont2.Id);
        }

        Test.startTest();
        ARC_BackfillNewHDBatch contractWithId = new ARC_BackfillNewHDBatch(contractIds);
        Database.executeBatch(contractWithId);
        ARC_BackfillNewHDBatch scheduledJobId = new ARC_BackfillNewHDBatch();
        Database.executeBatch(scheduledJobId);
        Test.stopTest();
    }
}