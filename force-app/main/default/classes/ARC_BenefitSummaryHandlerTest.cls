@isTest
public with sharing class ARC_BenefitSummaryHandlerTest {

    @TestSetup
    static void makeData(){
        //Person Account
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account accountRecord = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount', LastName ='Test' ,PersonEmail='test@email.com', ARC_IsPrimaryMember__c=true);
        insert accountRecord;
        Account acc = [SELECT PersonContactId FROM Account WHERE Id =: accountRecord.Id];
        //Census  & Census Memnber
        vlocity_ins__GroupCensusMember__c censusMember = ARC_TestUtility.createTestCensusMember(1)[0];
        censusMember.vlocity_ins__ContactId__c = acc.PersonContactId;
        censusMember.vlocity_ins__SocialSecurityNumber__c = '123456789';
        update censusMember;
        List<vlocity_ins__GroupCensusMember__c> censusData =[SELECT vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c];
        acc.Census_Member__c = censusMember.Id;
        acc.ARC_Census__c = censusData[0].vlocity_ins__CensusId__c;
        update acc;

        ///Products
        Product2 smartProduct = new Product2();
        smartProduct.Name = 'SMART Share 35000';
        smartProduct.ProductCode = 'PROG_SMART_35000';
        smartProduct.vlocity_ins__Type__c = 'Ancillary';
        smartProduct.vlocity_ins__SubType__c='SMART';

        List<Product2> products = new List<Product2>();
        Product2 medicalProduct = new Product2();
        medicalProduct.Name = 'WeShare 6k ';
        medicalProduct.ProductCode = 'PROG_UHSM_WeShare6k';
        medicalProduct.vlocity_ins__Type__c = 'Medical';
        
        products.add(smartProduct);
        products.add(medicalProduct);
        insert products;
        //Contract & Contract Line Items
        Contract cont = ARC_TestUtility.createContractsAA(1)[0];
        cont.vlocity_ins__EnrollmentCensusId__c=censusMember.vlocity_ins__CensusId__c;
        cont.AccountId=acc.Id;
        insert cont;
        
        cont.Status = 'Awaiting Activation';
        cont.ARC_EffectiveDate__c = Date.today().addDays(1);
        update cont;

        cont.Status = 'Activated';
        update cont;

        List<vlocity_ins__ContractLineItem__c> lineItems = new List<vlocity_ins__ContractLineItem__c>();
        for(Integer i=0; i<2;i++){
            vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
            cli.vlocity_ins__Product2Id__c=  products[i].Id;
            cli.vlocity_ins__ContractId__c = cont.Id;
            cli.Name = products[i].Name;
            lineItems.add(cli);
        }
        insert lineItems;
        //Group Census Member Plan
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpList = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        for(Integer i=0; i<2;i++){
            vlocity_ins__GroupCensusMemberPlan__c cmp = new vlocity_ins__GroupCensusMemberPlan__c();
            cmp.vlocity_ins__ContractLineId__c = lineItems[i].Id;
            cmp.vlocity_ins__GroupCensusMemberId__c = censusMember.Id;
            cmp.Name = products[i].Name;
            gcmpList.add(cmp);
        }
        insert gcmpList;        
    }

    @isTest
    public static void testeOne(){
        List<Account> acc = [SELECT PersonContactId FROM Account];
        //Create User
        User testUser = ARC_TestUtility.createTestUsers(1, 'Member Community')[0];
        testUser.ContactId = acc[0].PersonContactId;
        insert testUser;

        Test.startTest();
            List<Object> programs = ARC_BenefitSummaryHandler.calculateDatesPerMemberAndProgram(testUser.Id);
        Test.stopTest();   
        Map<String,Object> contractDetailsMap = (Map<String,Object>)programs[0];
        List<Map<String,String>> allProducts = (List<Map<String,String>>)contractDetailsMap?.get('products');
        Assert.areEqual(2,allProducts.size());
    }

    @isTest
    public static void testeTwo(){
        List<Account> accountRecord = [SELECT Id, PersonContactId FROM Account];
        Test.startTest();
            List<Object> programs = ARC_BenefitSummaryHandler.getBenefitsSummary360Data(accountRecord[0].Id);
        Test.stopTest();   
        Assert.areEqual(2,programs.size());
        Map<String, Object> medicalProd = (Map<String, Object>) programs[0];
        Map<String, Object> smartProd = (Map<String, Object>) programs[1];
        Assert.areEqual('Medical',(String)medicalProd.get('type'));
        Assert.areEqual('Ancillary',(String)smartProd.get('type'));
    }

    @isTest
    public static void testeThree(){
        List<Account> accountRecord = [SELECT Id, PersonContactId FROM Account];
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpList = [SELECT vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId =: accountRecord[0].Id ];

        Test.startTest();
            List<Id> contractIds = ARC_BenefitSummaryHandler.getBenefitsSummary360Data(new List<Id>{accountRecord[0].Id});
        Test.stopTest();   
        Assert.areEqual(gcmpList[0].vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c,contractIds[0]);
        
    }
}