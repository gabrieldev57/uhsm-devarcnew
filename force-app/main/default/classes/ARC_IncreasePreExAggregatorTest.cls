@isTest
public with sharing class ARC_IncreasePreExAggregatorTest {

    @testSetup
    public static void createData() {
        List<Contract> contList = ARC_TestUtility.createContracts(3);
        contList[0].ARC_EffectiveDate__c =  Date.newInstance(System.today().year() - 1, System.today().month(), System.today().day());
        contList[1].ARC_EffectiveDate__c =  Date.newInstance(System.today().year() - 2, System.today().month(), System.today().day());
        contList[2].ARC_EffectiveDate__c =  Date.newInstance(System.today().year() - 3, System.today().month(), System.today().day());
        contList[0].Status = contList[1].Status = contList[2].Status = 'Draft'; 
        insert contList;

        List<InsurancePolicy> polList = ARC_TestUtility.createTestPolicies(3);
        polList[0].ARC_Contract__c = contList[0].Id;
        polList[1].ARC_Contract__c = contList[1].Id;
        polList[2].ARC_Contract__c = contList[2].Id;
        update polList;

        List<ARC_Aggregator__c> aggList = new List<ARC_Aggregator__c>();
        ARC_Aggregator__c agg0 = new ARC_Aggregator__c();
        ARC_Aggregator__c agg1 = new ARC_Aggregator__c();
        ARC_Aggregator__c agg2 = new ARC_Aggregator__c();
        ARC_Aggregator__c agg3 = new ARC_Aggregator__c();
        agg0.Name = agg1.Name = agg2.Name = 'Pre Existing Conditions';
        agg0.ARC_Year__c = agg1.ARC_Year__c = agg2.ARC_Year__c = agg3.ARC_Year__c = System.today().year() + '';
        agg3.Name = 'Maternity';
        agg0.ARC_Code__c = agg1.ARC_Code__c = agg2.ARC_Code__c = 'PREEX__c';
        agg3.ARC_Code__c = 'MAT__c';
        agg0.ARC_CreatedIn__c = polList[0].Id;
        agg1.ARC_CreatedIn__c = polList[1].Id;
        agg2.ARC_CreatedIn__c = polList[2].Id;
        agg3.ARC_CreatedIn__c = polList[1].Id;
        agg0.ARC_LimitValue__c = 15000;
        agg1.ARC_LimitValue__c = 25000;
        agg2.ARC_LimitValue__c = 50000;
        agg3.ARC_LimitValue__c = 15000;
        aggList.add(agg0);
        aggList.add(agg1);
        aggList.add(agg2);
        aggList.add(agg3);
        insert aggList;
    }

    @IsTest
    static void IncreaseAggregatorsTest() {
        Test.startTest();
        Database.executeBatch(new ARC_IncreasePreExAggregator());
        Test.stopTest();
        Date dateMinusOne = Date.newInstance(System.today().year() - 1, System.today().month(), System.today().day());
        Date dateMinusTwo = Date.newInstance(System.today().year() - 2, System.today().month(), System.today().day());
        Date dateMinusThree = Date.newInstance(System.today().year() - 3, System.today().month(), System.today().day());

        Assert.areEqual(25000, [SELECT Id, ARC_LimitValue__c FROM ARC_Aggregator__c WHERE ARC_CreatedIn__r.ARC_EffectiveDate__c =: dateMinusOne  LIMIT 1].ARC_LimitValue__c, 'Pre ex should be increased');
        Assert.areEqual(50000, [SELECT Id, ARC_LimitValue__c FROM ARC_Aggregator__c WHERE ARC_CreatedIn__r.ARC_EffectiveDate__c =: dateMinusTwo AND ARC_Code__c = 'PREEX__c' LIMIT 1].ARC_LimitValue__c, 'Pre ex should be increased');
        Assert.areEqual(99999999, [SELECT Id, ARC_LimitValue__c FROM ARC_Aggregator__c WHERE ARC_CreatedIn__r.ARC_EffectiveDate__c =: dateMinusThree LIMIT 1].ARC_LimitValue__c, 'Pre ex should be increased');
        Assert.areEqual(99999999, [SELECT Id, ARC_LimitValue__c FROM ARC_Aggregator__c WHERE ARC_CreatedIn__r.ARC_EffectiveDate__c =: dateMinusTwo AND ARC_Code__c = 'MAT__c' LIMIT 1].ARC_LimitValue__c, 'Maternity should be increased');
    }
}