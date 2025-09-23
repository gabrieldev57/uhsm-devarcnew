@isTest
public class ARC_BackfillMedicalPlanTest {
    
    @isTest
    static void testOne() { 
        //Create Account
        Account acc = new Account(FirstName='Account', LastName='Test', BillingStreet='2nd Avenue', BillingState='NY', BillingPostalCode='12345', BillingCity='New York', ARC_Provider_Name__c='Ins Provider',ARC_Provider_Tax_Id__c=1234567, ARC_NationalProviderId__c='23322', ARC_IsPrimaryMember__c = true);
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

        // Create test products
        List<Product2> testProducts = ARC_TestUtility.createTestProducts(1);
        for(Product2 prod : testProducts) {
            prod.vlocity_ins__Type__c = 'Medical';
            prod.Name = 'WeShare Test';
        }
        update testProducts;
        
        // Create test contract line items
        List<vlocity_ins__ContractLineItem__c> testCLIs = ARC_TestUtility.createTestContractLineItem(1);
        
        // Update Contract Line Items to associate with the contract, product, and set necessary fields
        for(Integer i = 0; i < testCLIs.size(); i++) {
            vlocity_ins__ContractLineItem__c cli = testCLIs[i];
            cli.vlocity_ins__ContractId__c = cont[0].Id;
            cli.vlocity_ins__ProductId__c = testProducts[i].Id;
            cli.Name = testProducts[i].Name;
            cli.vlocity_ins__ParentItemId__c= null;
        }
        update testCLIs;

        Test.StartTest();
            Contract beforeJob = [SELECT Id, ARC_MedicalPlan__c, Status FROM Contract WHERE Id =: cont[0].Id];
            ARC_BackfillMedicalPlan batchMeidcalPlan = new ARC_BackfillMedicalPlan();
            Database.executeBatch(batchMeidcalPlan);
        Test.StopTest();
        Contract afterJob = [SELECT Id, ARC_MedicalPlan__r.Name FROM Contract WHERE Id =: cont[0].Id];
        Assert.areEqual(null, beforeJob.ARC_MedicalPlan__c);
        Assert.areEqual(testProducts[0].Name, afterJob.ARC_MedicalPlan__r.Name);
    }
}