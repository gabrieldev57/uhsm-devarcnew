@isTest
public class ARC_CaseHandlerTest {
    
    @TestSetup
    static void mockData(){
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();

        Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount', LastName ='Test');
        acc.BillingStreet = '123 Avenue';
        acc.BillingState = 'NY';
        acc.BillingCity = 'New York';
        acc.BillingPostalCode='12345';
        acc.PersonEmail='test@email.com';
        acc.ARC_IsPrimaryMember__c = true;
        acc.ARC_E123MemberIdFromPolicy__c = 'W123456789';
        insert acc;
        Account personAcc = [SELECT Id, PersonContactId FROM Account WHERE Id =:acc.Id];
        List <vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(1);
        censusMemberList[0].vlocity_ins__ContactId__c = personAcc.PersonContactId;
        censusMemberList[0].vlocity_ins__SocialSecurityNumber__c = '123456789';
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpToInsert = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        for(Integer i=0; i<4; i++ ){
            vlocity_ins__GroupCensusMemberPlan__c memberplan = new vlocity_ins__GroupCensusMemberPlan__c();
            memberplan.Name = 'Holi';
            memberplan.vlocity_ins__GroupCensusMemberId__c = censusMemberList[0].Id;
            gcmpToInsert.add(memberplan);
        }
        update censusMemberList;
        insert gcmpToInsert;

        Product2 product6k = new Product2();
        product6k.Name = 'WeShare 6k';
        product6k.ProductCode = 'CS_FinanceVisitsFramework';
        product6k.vlocity_ins__Type__c = 'Medical';
        product6k.ProductCode = 'PROG_UHSM_WeShare6k';
        insert product6k;

        Product2 product3k = new Product2();
        product3k.Name = 'WeShare 3k';
        product3k.ProductCode = 'CS_FinanceVisitsFramework';
        product3k.vlocity_ins__Type__c = 'Medical';
        product3k.ProductCode = 'PROG_UHSM_WeShare3k';
        insert product3k;

        Product2 product12k = new Product2();
        product12k.Name = 'WeShare 12k';
        product12k.ProductCode = 'CS_FinanceVisitsFramework';
        product12k.vlocity_ins__Type__c = 'Medical';
        product12k.ProductCode = 'PROG_UHSM_WeShare12k';
        insert product12k;

        Product2 smartProduct = new Product2();
        smartProduct.Name = 'Smart';
        smartProduct.vlocity_ins__Type__c = 'Ancillary';
        smartProduct.ProductCode = 'PROG_UHSM_WeShare12k';
        insert smartProduct;

        List<vlocity_ins__GroupCensusMember__c> censusData =[SELECT vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c];
        acc.Census_Member__c = censusMemberList[0].Id;
        acc.ARC_Census__c = censusData[0].vlocity_ins__CensusId__c;
        update acc;

        List<Contract> contracts = ARC_TestUtility.createContractsAA(4);
        Contract cont1 = contracts[0];
        cont1.vlocity_ins__EnrollmentCensusId__c = censusMemberList[0].vlocity_ins__CensusId__c;
        cont1.ARC_EffectiveDate__c = Date.newInstance(2022, 2, 15);
        cont1.ARC_Inactive_Date__c = Date.newInstance(2023, 1, 30);
        cont1.AccountId = acc.Id;
        cont1.ARC_ContractReason__c = 'New Application';
        cont1.Status = 'Draft';
        insert cont1;

        Contract cont2 = contracts[1];
        cont2.vlocity_ins__EnrollmentCensusId__c = censusMemberList[0].vlocity_ins__CensusId__c;
        cont2.ARC_EffectiveDate__c = Date.newInstance(2023, 2, 1);
        cont2.ARC_Inactive_Date__c = Date.newInstance(2023, 6, 30);
        cont2.AccountId = acc.Id;
        cont2.ARC_ContractReason__c = 'Program Downgrade';
        cont2.vlocity_ins__ExpiredContractId__c = cont1.Id;
        cont2.Status = 'Draft';
        insert cont2;

        Contract cont3 = contracts[2];
        cont3.vlocity_ins__EnrollmentCensusId__c = censusMemberList[0].vlocity_ins__CensusId__c;
        cont3.ARC_EffectiveDate__c = Date.newInstance(2023, 2, 1);
        cont3.ARC_Inactive_Date__c = Date.newInstance(2023, 7, 31);
        cont3.AccountId = acc.Id;
        cont3.ARC_ContractReason__c = 'Program Downgrade';
        cont3.Status = 'Draft';
        insert cont3;

        Contract cont4 = contracts[3];
        cont4.vlocity_ins__EnrollmentCensusId__c = censusMemberList[0].vlocity_ins__CensusId__c;
        cont4.ARC_EffectiveDate__c = Date.newInstance(2024, 1, 1);
        cont4.AccountId = acc.Id;
        cont4.ARC_ContractReason__c = 'Program Upgrade';
        cont4.Status = 'Draft';
        insert cont4;

        List<vlocity_ins__ContractLineItem__c> cli =ARC_TestUtility.createTestContractLineItem(5);
        cli[0].vlocity_ins__ContractId__c = cont1.Id;
        cli[0].vlocity_ins__Product2Id__c = product6k.Id;
        cli[1].vlocity_ins__ContractId__c = cont2.Id;
        cli[1].vlocity_ins__Product2Id__c = product12k.Id;
        cli[2].vlocity_ins__ContractId__c = cont3.Id;
        cli[2].vlocity_ins__Product2Id__c = product3k.Id;
        cli[3].vlocity_ins__ContractId__c = cont4.Id;
        cli[3].vlocity_ins__Product2Id__c = product6k.Id;
        cli[4].vlocity_ins__ContractId__c = cont2.Id;
        cli[4].vlocity_ins__Product2Id__c = smartProduct.Id;
        update cli;

        for(Integer i=0; i<4; i++){            
            gcmpToInsert[i].vlocity_ins__ContractLineId__c = cli[i].Id;
        }
        update gcmpToInsert;

        cont1.Status = 'Terminated';
        cont2.Status = 'Terminated';
        cont3.Status = 'Terminated';
        update cont1;
        update cont2;
        update cont3;

        Claim claim1 = new Claim();
        claim1.Name = 'Test Claim';
        insert claim1;
    }

    @isTest
    public static void testCaseNotUW() {

        List<Account> acc = [SELECT Id, Name, PersonContactId FROM Account WHERE FirstName='PersonAccount'];
        List<Contract> cont = [SELECT Id,ARC_EffectiveDate__c FROM Contract WHERE ARC_ContractReason__c='Program Upgrade'];

        List <vlocity_ins__GroupCensusMember__c> censusMemberList = [SELECT Id, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__ContactId__c=:acc[0].PersonContactId];

        List<Case> cases = ARC_TestUtility.createTestCase(1, 'Sales');
        Case cas = cases[0]; 

        cas.ARC_Contract__c = cont[0].Id;
        cas.ARC_CensusMember__c = censusMemberList[0].Id;
        cas.ARC_PersonAccount__c =acc[0].Id;
        upsert cas;

        cont[0].ARC_Case__c = cas.Id;
        cont[0].Status = 'Awaiting Approval';
        update cont;

        test.startTest();
        Object result = ARC_CaseHandler.getMemberAndProgramData(cas.Id);
        test.stopTest();
        Map<String, Object> responseData = (Map<String, Object>)result;
        Account accData = (Account)responseData.get('accountData');
        Date effectiveDate = (Date)responseData.get('effectiveDate');
        String program = (String)responseData.get('currentProgram');
        
        Case updatedCase = [SELECT Id, ARC_Upload_files_URL__c FROM Case WHERE Id = :cas.Id]; 	
        System.assertNotEquals(null, updatedCase.ARC_Upload_files_URL__c, 'Field should not be null');
        
        // Assert.areEqual(acc[0].Id, accData.Id, 'Account must be the case related account');
        // Assert.areEqual(cont[0].ARC_EffectiveDate__c, effectiveDate, 'First Effective Date should be the one of the last contract');
        // Assert.areEqual('WeShare 6k', program, 'Program should be the one of the last contract');

    }
    
    @isTest
    public static void testCaseUW() {

        List<Account> acc = [SELECT Id, Name, PersonContactId FROM Account WHERE FirstName='PersonAccount'];
        List<Contract> cont = [SELECT Id,ARC_EffectiveDate__c FROM Contract WHERE ARC_ContractReason__c='Program Upgrade'];

        List <vlocity_ins__GroupCensusMember__c> censusMemberList = [SELECT Id, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__ContactId__c=:acc[0].PersonContactId];

        List<Case> cases = ARC_TestUtility.createTestCase(1, 'Admission');
        Case cas = cases[0]; 

        cas.ARC_Contract__c = cont[0].Id;
        cas.ARC_CensusMember__c = censusMemberList[0].Id;
        cas.ARC_PersonAccount__c =acc[0].Id;
        upsert cas;

        cont[0].ARC_Case__c = cas.Id;
        cont[0].Status = 'Awaiting Approval';
        update cont;


        ARC_UnderwritingCaseMember__c ucm = new ARC_UnderwritingCaseMember__c();
        ucm.Name = 'Test Underwriting Case Item ';
        ucm.ARC_Member__c = censusMemberList[0].Id;
        ucm.ARC_UnderwritingCase__c = cas.Id;
        ucm.ARC_ApprovalResolution__c = 'Approved';
        ucm.ARC_PersonAccount__c = acc[0].Id;
        ucm.ARC_Contract__c = cont[0].Id;
        upsert ucm;


        test.startTest();
        Object result = ARC_CaseHandler.getMemberAndProgramData(cas.Id);
        test.stopTest();
        Map<String, Object> responseData = (Map<String, Object>)result;
        Account accData = (Account)responseData.get('accountData');
        Date effectiveDate = (Date)responseData.get('effectiveDate');
        String program = (String)responseData.get('currentProgram');

        Assert.areEqual(acc[0].Id, accData.Id, 'Account must be the case related account');
        Assert.areEqual(cont[0].ARC_EffectiveDate__c, effectiveDate, 'First Effective Date should be the one of the UW Case contract');
        Assert.areEqual('WeShare 6k', program, 'Program should be the one of the UW Case contract');
    }

    @isTest
    public static void updateCasePersonAccountTest(){
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        
        List<Account> existingAcc = [SELECT Id, Name, PersonContactId FROM Account WHERE FirstName='PersonAccount'];
        List<Contract> cont = [SELECT Id,ARC_EffectiveDate__c FROM Contract WHERE ARC_ContractReason__c='Program Upgrade'];

        List <vlocity_ins__GroupCensusMember__c> censusMemberList = [SELECT Id, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__ContactId__c=:existingAcc[0].PersonContactId];

        List<Case> cases = ARC_TestUtility.createTestCase(1, 'Sales');
        Case cas = cases[0]; 

        cas.ARC_Contract__c = cont[0].Id;
        cas.ARC_CensusMember__c = censusMemberList[0].Id;
        cas.ARC_PersonAccount__c =existingAcc[0].Id;
        upsert cas;

        cont[0].ARC_Case__c = cas.Id;
        cont[0].Status = 'Awaiting Approval';
        update cont;
        
        Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'AnotherAccount', LastName ='Test');
        acc.BillingStreet = '111 Avenue';
        acc.BillingState = 'NY';
        acc.BillingCity = 'New York';
        acc.BillingPostalCode='67891';
        acc.PersonEmail='test2@email.com';
        acc.ARC_IsPrimaryMember__c = true;
        acc.ARC_E123MemberIdFromPolicy__c = 'W987654321';
        insert acc;
        Account personAcc = [SELECT Id, Name, PersonContactId FROM Account WHERE Id =:acc.Id];

        test.startTest();
        ARC_CaseHandler.updateCasePersonAccount(cas.Id, personAcc.Id);
        test.stopTest();

        Case caseAfterChange = [SELECT Id, ARC_PersonAccount__c, ARC_PersonAccount__r.Name FROM Case WHERE Id =: cas.Id];
        Assert.areEqual(personAcc.Id, caseAfterChange.ARC_PersonAccount__c, 'Case Account must be the new account');
    }

    @isTest
    public static void getContractComparisonTestNull(){
        Map<String, Object> responseData = new Map<String, Object>();
        Test.startTest();
            responseData = (Map<String, Object>) ARC_CaseHandler.getContractComparison(null);
        Test.stopTest();
        Assert.areEqual(responseData,null);
    }

    @isTest
    public static void getContractComparisonTest(){
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        
        List<Account> existingAcc = [SELECT Id, Name, PersonContactId FROM Account WHERE FirstName='PersonAccount'];
        List<Contract> cont = [SELECT Id,ARC_EffectiveDate__c FROM Contract WHERE vlocity_ins__ExpiredContractId__c != null];

        List <vlocity_ins__GroupCensusMember__c> censusMemberList = [SELECT Id, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__ContactId__c=:existingAcc[0].PersonContactId];

        Case uwCase = ARC_TestUtility.createTestCase(1, 'Admission')[0];
        uwCase.ARC_Contract__c = cont[0].Id;
        uwCase.ARC_CensusMember__c = censusMemberList[0].Id;
        uwCase.ARC_PersonAccount__c =existingAcc[0].Id;
        upsert uwCase;

        cont[0].ARC_Case__c = uwCase.Id;
        update cont;

        Map<String, Object> responseData = new Map<String, Object>();
        Test.startTest();
            responseData = (Map<String, Object>) ARC_CaseHandler.getContractComparison(uwCase.Id);
        Test.stopTest();
        List<vlocity_ins__ContractLineItem__c> newCli = (List<vlocity_ins__ContractLineItem__c> )responseData.get('newContractLineItems');
        List<vlocity_ins__ContractLineItem__c> oldCli = (List<vlocity_ins__ContractLineItem__c> )responseData.get('oldContractLineItems');
        
        Assert.areEqual(newCli.size(),oldCli.size());


    }
}