@isTest
public with sharing class ARC_GroupCensusMemberPlanTriggerTest {
    
    @testSetup
    public static void makeData() {
        vlocity_ins__CalculationProcedure__c cp = new vlocity_ins__CalculationProcedure__c(Name = 'ARC_UHSMCalculationProcedure_Individual');
        insert cp;
        insert new vlocity_ins__CalculationProcedureVersion__c(vlocity_ins__CalculationProcedureId__c = cp.Id, vlocity_ins__IsEnabled__c = true, vlocity_ins__Constants__c = '[{"name":"AmountPerExtraMember","value":"50","dataType":"Currency","isEditable":false,"userDefined":true,"precision":"","valuePlaceHolder":"Enter a Value","alias":"AmountPerExtraMember","duplicateAlias":true},{"name":"SmokerAditional","value":"50","dataType":"Currency","isEditable":false,"userDefined":true,"precision":"","valuePlaceHolder":"Enter a Value","alias":"SmokerAditional","duplicateAlias":true}]');
        List<Product2> prod = ARC_TestUtility.createTestProducts(2);
        prod[0].vlocity_ins__Type__c = 'Medical';
        prod[1].vlocity_ins__Type__c = 'Ancillary';
        update prod;
        vlocity_ins__GroupCensus__c census = ARC_TestUtility.createTestCensus(1)[0];
        List<vlocity_ins__GroupCensusMember__c> cm = new List<vlocity_ins__GroupCensusMember__c>();
        for (Integer i=0;i<6;i++) {
            cm.add(new vlocity_ins__GroupCensusMember__c(
                Name = 'Test Census Member ' + i,
                vlocity_ins__IsPrimaryMember__c = i == 0,
                ARC_Smoker__c = i == 0,
                vlocity_ins__CensusId__c = census.Id,
                ARC_PhysicalAddressState__c = 'KS'
                ));
            }
        insert cm;
        List<vlocity_ins__ContractLineItem__c> cli = ARC_TestUtility.createTestContractLineItem(2);
        for (Integer i=0;i<cli.size();i++) {
            cli[i].vlocity_ins__Product2Id__c = i == 0 ? prod[0].Id : prod[1].Id;
            cli[i].vlocity_ins__UnitPrice__c = 100;
        }
        update cli;
    }

    @isTest
    public static void updateRelatedCLIFeesTest() {
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmp = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        List<vlocity_ins__GroupCensusMember__c> cm = [SELECT Id FROM vlocity_ins__GroupCensusMember__c];
        List<vlocity_ins__ContractLineItem__c> cli = [SELECT Id FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__Product2Id__r.vlocity_ins__Type__c IN ('Medical', 'Ancillary') LIMIT 2];
        for (Integer i=0;i<6;i++) {
            gcmp.addAll(new List<vlocity_ins__GroupCensusMemberPlan__c>{
                new vlocity_ins__GroupCensusMemberPlan__c(Name = 'Test Plan Medical ' + i, vlocity_ins__GroupCensusMemberId__c = cm[i].Id, vlocity_ins__ContractLineId__c = cli[0].Id),
                new vlocity_ins__GroupCensusMemberPlan__c(Name = 'Test Plan Ancillary ' + i, vlocity_ins__GroupCensusMemberId__c = cm[i].Id, vlocity_ins__ContractLineId__c = cli[1].Id)
            });
        }
        Test.startTest();
        insert gcmp;
        Test.stopTest();
        vlocity_ins__ContractLineItem__c clisUpdated = [SELECT ARC_SmokerFee__c, ARC_ExtraDependentFee__c FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__Product2Id__r.vlocity_ins__Type__c = 'Medical' LIMIT 1];

        Assert.areEqual(50.00, clisUpdated.ARC_SmokerFee__c, 'ARC_Smoker__c should be 50.00');
        Assert.areEqual(100.00, clisUpdated.ARC_ExtraDependentFee__c, 'ARC_ExtraDependentFee__c should be 100.00');
    }
}