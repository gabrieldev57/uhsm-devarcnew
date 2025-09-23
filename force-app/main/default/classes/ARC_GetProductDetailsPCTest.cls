@isTest
global without sharing class ARC_GetProductDetailsPCTest {    
    @isTest
    static void ARC_GetProductDetailsPCTest() {

        //create products
        Product2 product = new Product2(Name = 'Test');
        insert product;

        //create accounts
        Account acc = new Account(Name = 'Test');
        insert acc;

        //create contracts
        Contract contract = new Contract(AccountId = acc.Id);
        insert contract;

        //create contract line items
        vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c(
            vlocity_ins__Product2Id__c = product.Id,
            vlocity_ins__ContractId__c = contract.Id
        );
        insert cli;

        //create census
        vlocity_ins__GroupCensus__c census= new vlocity_ins__GroupCensus__c(Name = 'Test', vlocity_ins__GroupId__c = acc.Id);
        insert census;

        //create members
        vlocity_ins__GroupCensusMember__c member= new vlocity_ins__GroupCensusMember__c(Name = 'Test', vlocity_ins__CensusId__c = census.Id);
        insert member;

        //create group census member plans
        vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c(
            vlocity_ins__GroupCensusMemberId__c = member.Id,
            vlocity_ins__ContractLineId__c = cli.Id
        );
        insert gcmp;



        ARC_GetProductDetailsPC getProductDetails = new ARC_GetProductDetailsPC();

        String inputMapString = '{"CLIs": [{"productId": "'+product.Id+'","Price": 462.73,"recordTypeName": "Product","Id": "'+cli.Id+'"}]}';
        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);
        
        Test.startTest();
        getProductDetails.invokeMethod('getProductsDetails', inputMap, new Map<String,Object>(), new Map<String,Object>());
        Test.stopTest();


    }
}