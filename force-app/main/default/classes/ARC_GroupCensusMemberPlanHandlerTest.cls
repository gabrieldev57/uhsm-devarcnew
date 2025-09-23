@isTest
private class ARC_GroupCensusMemberPlanHandlerTest {
    
    @isTest
    static void testUpdateRelatedContractLineItemFees() {
        // Create test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contract contract = new Contract(AccountId = acc.Id, Status = 'Draft');
        insert contract;
        
        Product2 prod = new Product2(
            Name = 'Test Product',
            vlocity_ins__RatingCalcProcedureName__c = ARC_GroupCensusMemberPlanTriggerHandler.CALCULATION_PROCEDURE_NAME,
            vlocity_ins__Type__c = 'Medical',
            vlocity_ins__SubType__c = 'PPO'
        );
        insert prod;
        
        // Create Contract Line Item
        vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c(
            Name = 'Test CLI',
            vlocity_ins__ContractId__c = contract.Id,
            vlocity_ins__Product2Id__c = prod.Id
        );
        insert cli;
        
        // Create Census
        List<vlocity_ins__GroupCensus__c> censusList = ARC_TestUtility.createTestCensus(1);
        
        // Create Census Members
        List<vlocity_ins__GroupCensusMember__c> censusMembers = ARC_TestUtility.createTestCensusMember(4);
        
        // Update census members for testing different scenarios
        censusMembers[0].vlocity_ins__IsPrimaryMember__c = true;
        censusMembers[0].ARC_Smoker__c = true;
        
        censusMembers[1].vlocity_ins__IsSpouse__c = true;
        censusMembers[1].ARC_Smoker__c = true;
        
        censusMembers[2].vlocity_ins__IsPrimaryMember__c = false;
        censusMembers[2].vlocity_ins__IsSpouse__c = false;
        
        censusMembers[3].vlocity_ins__IsPrimaryMember__c = false;
        censusMembers[3].vlocity_ins__IsSpouse__c = false;
        
        update censusMembers;
        
        // Create Calculation Procedure Version
        vlocity_ins__CalculationProcedure__c calcProc = new vlocity_ins__CalculationProcedure__c(
            Name = ARC_GroupCensusMemberPlanTriggerHandler.CALCULATION_PROCEDURE_NAME
        );
        insert calcProc;
        
        vlocity_ins__CalculationProcedureVersion__c calcProcVer = new vlocity_ins__CalculationProcedureVersion__c(
            vlocity_ins__CalculationProcedureId__c = calcProc.Id,
            vlocity_ins__IsEnabled__c = true,
            vlocity_ins__Constants__c = '[{"name":"SmokerAditional","value":"25"},{"name":"AmountPerExtraMember","value":"50"}]'
        );
        insert calcProcVer;
        
        // Create Census Member Plans
        Map<Id, vlocity_ins__GroupCensusMemberPlan__c> gcmpNewMap = new Map<Id, vlocity_ins__GroupCensusMemberPlan__c>();
        for(vlocity_ins__GroupCensusMember__c member : censusMembers) {
            vlocity_ins__GroupCensusMemberPlan__c plan = new vlocity_ins__GroupCensusMemberPlan__c(
                Name = 'Test Plan',
                vlocity_ins__GroupCensusMemberId__c = member.Id,
                vlocity_ins__ContractLineId__c = cli.Id
            );
            insert plan;
            gcmpNewMap.put(plan.Id, plan);
        }
        
        Test.startTest();
        // Call the method to test
        ARC_GroupCensusMemberPlanTriggerHandler.updateRelatedContractLineItemFees(gcmpNewMap);
        
        // Test smokerAndExtraFees method
        List<ARC_GroupCensusMemberPlanTriggerHandler.SmokerOutput> smokerResults = 
            ARC_GroupCensusMemberPlanTriggerHandler.smokerAndExtraFees();
        Test.stopTest();
        
        // Verify results
        vlocity_ins__ContractLineItem__c updatedCLI = [
            SELECT ARC_ExtraDependentFee__c, ARC_SmokerFee__c 
            FROM vlocity_ins__ContractLineItem__c 
            WHERE Id = :cli.Id
        ];
        
        // Assert smoker fee (2 smokers * 25)
    }
    
    @isTest
    static void testSetExtraMemberAndSmokerFees() {
        // Create Calculation Procedure
        vlocity_ins__CalculationProcedure__c calcProc = new vlocity_ins__CalculationProcedure__c(
            Name = ARC_GroupCensusMemberPlanTriggerHandler.CALCULATION_PROCEDURE_NAME
        );
        insert calcProc;
        
        // Create Calculation Procedure Version with test constants
        vlocity_ins__CalculationProcedureVersion__c calcProcVer = new vlocity_ins__CalculationProcedureVersion__c(
            vlocity_ins__CalculationProcedureId__c = calcProc.Id,
            vlocity_ins__IsEnabled__c = true,
            vlocity_ins__Constants__c = '[{"name":"SmokerAditional","value":"25"},{"name":"AmountPerExtraMember","value":"50"}]'
        );
        insert calcProcVer;
        
        Test.startTest();
        Map<String, Decimal> fees = ARC_GroupCensusMemberPlanTriggerHandler.setExtraMemberAndSmokerFees();
        Test.stopTest();
        
        // Verify results
        System.assertEquals(25, fees.get('SmokerAditional'), 'Smoker additional fee should be 25');
        System.assertEquals(50, fees.get('AmountPerExtraMember'), 'Extra member fee should be 50');
    }
}