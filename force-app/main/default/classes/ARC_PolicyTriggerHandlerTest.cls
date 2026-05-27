@isTest
public with sharing class ARC_PolicyTriggerHandlerTest {
    
    @TestSetup
    static void mockData(){
        List<InsurancePolicy> listPol = ARC_TestUtility.createTestPolicies(2, 'ARC_IndividualAndFamily');
        List<InsurancePolicyParticipant> listPolPart = ARC_TestUtility.createTestPolicyParticipant(3);
        List<Product2> listProd = ARC_TestUtility.createTestProducts(2);
        List<Contract> contList = ARC_TestUtility.createContractsAA(2);
        User user = [SELECT Id, Agent_Role__c FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
       	//user.Agent_Role__c = 'Account Executive';
        //update user;
        
		Product2 prod1 = listProd[0];
		Product2 prod2 = listProd[1];
        InsurancePolicy pol1 = listPol[0];
        InsurancePolicy pol2 = listPol[1];
        InsurancePolicyParticipant polPart1 = listPolPart[0];
        InsurancePolicyParticipant polPart2 = listPolPart[1];
        InsurancePolicyParticipant polPart3 = listPolPart[2];
        Contract cont1 = contList[0];
        Contract cont2 = contList[1];
        List<vlocity_ins__GroupCensusMember__c> censusMemList = ARc_TestUtility.createTestCensusMember(2);
        List<Contact> memberContactList = ARC_TestUtility.createTestContact(2, 'Contact');
        Contact memberContact = memberContactList[0];
        Contact memberContact2 = memberContactList[1];
        vlocity_ins__GroupCensusMember__c censusMem = censusMemList[0];
        vlocity_ins__GroupCensusMember__c censusMem2 = censusMemList[1];

        memberContact.ARC_CensusMember__c = censusMem.Id;
        memberContact2.ARC_CensusMember__c = censusMem2.Id;
        censusMem.vlocity_ins__ContactId__c = memberContact.Id;
        censusMem2.vlocity_ins__ContactId__c = memberContact2.Id;
        update censusMemList;
        update memberContactList;
        
        // CREATE DATA WITH PRODUCT NAME
        cont1.ARC_ContractReason__c = 'New Application';
        cont1.Status = 'Draft';
        cont1.vlocity_ins__EnrollmentCensusId__c = censusMem.vlocity_ins__CensusId__c;
        cont1.ARC_EffectiveDate__c = Date.newInstance(2024,01,01);
        cont1.ARC_Selling_Agent__c=user.Id;
        insert cont1;
        prod1.Name = 'WeShare 3k';
        prod1.ProductCode = 'PROG_UHSM_WeShare3k';
        update prod1;
        pol1.ProductId = prod1.Id;
        pol1.ARC_Contract__c = cont1.Id;
        update pol1;
        polPart1.InsurancePolicyId = pol1.Id;
        polPart1.PrimaryParticipantContactId = memberContact.Id;
        insert polPart1;
        
		cont2.ARC_ContractReason__c = 'Program Downgrade';
        cont2.Status = 'Draft';
        cont2.vlocity_ins__EnrollmentCensusId__c = censusMem2.vlocity_ins__CensusId__c;
        cont2.vlocity_ins__ExpiredContractId__c = cont1.Id;
        cont2.ARC_EffectiveDate__c = Date.newInstance(2025,01,01);
        insert cont2;
        prod2.Name = 'WeShare 3k';
        prod2.ProductCode = 'PROG_UHSM_WeShare3k';
        update prod2;
        pol2.ProductId = prod2.Id;
        pol2.ARC_Contract__c = cont2.Id;
        pol2.RenewedFromPolicyId = pol1.Id;
        update pol2;
        List<InsurancePolicyParticipant> parts = new List<InsurancePolicyParticipant>();
        polPart2.InsurancePolicyId = pol2.Id;
        polPart2.PrimaryParticipantContactId = memberContact.Id;
        polPart3.InsurancePolicyId = pol2.Id;
        polPart3.PrimaryParticipantContactId = memberContact2.Id;
        parts.add(polPart2);  
        parts.add(polPart3);  
        insert parts;

        ChargentOrders__ChargentOrder__c chargentOrder = new ChargentOrders__ChargentOrder__c(Id = cont1.ARC_RecurringMonthlyOrder__c, ARC_Contract__c=cont1.Id);
        update chargentOrder;

        ChargentOrders__Transaction__c t = ARC_TestUtility.createOneTransaction(10,'Charge',chargentOrder.Id);
        insert t;

        cont1.Status = 'Terminated';
        update cont1;
        cont2.Status = 'Activated';
        update cont2;
		// Database.executeBatch(new ARC_PolicyTriggerHandler());
        ARC_PolicyTriggerHandler.execute(null);
    }

    @isTest
    public static void createAggregatorTest() {
        List<InsurancePolicy> listPol = ARC_TestUtility.createTestPolicies(2, 'ARC_IndividualAndFamily');
        List<InsurancePolicyParticipant> listPolPart = ARC_TestUtility.createTestPolicyParticipant(6);
        List<Product2> listProd = ARc_TestUtility.createTestProducts(2);
        List<Contract> contList = ARc_TestUtility.createContractsAA(2);
        User user = [SELECT Id, Agent_Role__c FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

		Product2 prod1 = listProd[0];
		Product2 prod2 = listProd[1];
        InsurancePolicy pol1 = listPol[0];
        InsurancePolicy pol2 = listPol[1];
        InsurancePolicyParticipant polPart1 = listPolPart[0];
        InsurancePolicyParticipant polPart2 = listPolPart[1];
        InsurancePolicyParticipant polPart3 = listPolPart[2];
        InsurancePolicyParticipant polPart4 = listPolPart[3];
        Contract cont1 = contList[0];
        Contract cont2 = contList[1];
        List<vlocity_ins__GroupCensusMember__c> censusMemList = ARc_TestUtility.createTestCensusMember(2);
        List<Contact> memberContactList = ARc_TestUtility.createTestContact(2, 'Contact');
        Contact memberContact = memberContactList[0];
        Contact memberContact2 = memberContactList[1];
        vlocity_ins__GroupCensusMember__c censusMem = censusMemList[0];
        vlocity_ins__GroupCensusMember__c censusMem2 = censusMemList[1];

        memberContact.ARC_CensusMember__c = censusMem.Id;
        memberContact2.ARC_CensusMember__c = censusMem2.Id;
        censusMem.vlocity_ins__ContactId__c = memberContact.Id;
        censusMem.vlocity_ins__ContactId__c = memberContact2.Id;
        update censusMemList;
        update memberContactList;
        
        // CREATE DATA WITH PRODUCT NAME
        cont1.ARC_ContractReason__c = 'Remove Member';
        cont1.Status = 'Draft';
        cont1.vlocity_ins__EnrollmentCensusId__c = censusMem.vlocity_ins__CensusId__c;
        cont1.ARC_EffectiveDate__c = Date.newInstance(2024,01,01);
        cont1.ARC_Selling_Agent__c=user.Id;
        insert cont1;

        ChargentOrders__ChargentOrder__c chargentOrder = new ChargentOrders__ChargentOrder__c(Id = cont1.ARC_RecurringMonthlyOrder__c, ARC_Contract__c=cont1.Id);
        update chargentOrder;
        ChargentOrders__Transaction__c t = ARC_TestUtility.createOneTransaction(10,'Charge',chargentOrder.Id);
        insert t;

        prod1.Name = 'UHSM Bronze $10K';
        prod1.ProductCode = 'PROG_UHSMBronze';
        update prod1;
        InsurancePolicy renewPol = [SELECT Id FROM InsurancePolicy WHERE ARC_Contract__r.Status = 'Terminated' LIMIT 1];
        pol1.ProductId = prod1.Id;
        pol1.ARC_Contract__c = cont1.Id;
        pol1.RenewedFromPolicyId = renewPol.Id;
        update pol1;
        polPart1.InsurancePolicyId = pol1.Id;
        polPart1.PrimaryParticipantContactId = memberContact.Id;
        insert polPart1;
        
        // UPDATE SAME DATA WITH DIFFERENT PRODUCT NAME
        cont1.Status = 'Awaiting Activation';
        update cont1;
        prod1.Name = 'WeShare 12k';
        update prod1;
        pol1.ProductId = prod1.Id;
        pol1.ARC_Contract__c = cont1.Id;
        update pol1;
        polPart4.InsurancePolicyId = pol1.Id;
        polPart4.PrimaryParticipantContactId = memberContact.Id;
        insert polPart4;

		cont2.ARC_ContractReason__c = 'Program Downgrade';
        cont2.vlocity_ins__EnrollmentCensusId__c = censusMem.vlocity_ins__CensusId__c;
        cont2.vlocity_ins__ExpiredContractId__c = cont1.Id;
        cont2.ARC_EffectiveDate__c = Date.today();
        insert cont2;
        prod2.Name = 'WeShare 12k';
        update prod2;
        pol2.ProductId = prod2.Id;
        pol2.ARC_Contract__c = cont2.Id;
        update pol2;
        List<InsurancePolicyParticipant> parts = new List<InsurancePolicyParticipant>();
        polPart2.InsurancePolicyId = pol2.Id;
        polPart2.PrimaryParticipantContactId = memberContact.Id;
        polPart3.InsurancePolicyId = pol2.Id;
        polPart3.PrimaryParticipantContactId = memberContact2.Id;
        parts.add(polPart2);  
        parts.add(polPart3);  
        insert parts;

        // EXECUTE TRIGGER
        Test.startTest();
		cont1.Status = 'Activated';
        update cont1;
		// Database.executeBatch(new ARC_PolicyTriggerHandler());
        ARC_PolicyTriggerHandler.execute(null);
        Test.stopTest();
        
        Assert.areEqual([SELECT count() FROM ARC_Aggregator__c] > 1, true);
        Assert.areEqual([SELECT count() FROM ARC_ParticipantAggregator__c] > 1, true);
    }

}