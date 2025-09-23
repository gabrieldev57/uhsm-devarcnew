@isTest
public with sharing class ARC_RepriceCaseTest{
   
    @isTest
    public static void ARC_RepriceCaseTest(){
        Date oggi = Date.today();
        Date effDate = Date.newInstance(2022, 08, 15);
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();

        Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount', LastName ='Test');
        insert acc;
        
        insert new ChargentBase__Chargent_Settings__c(ARC_AppFee__c=1199,ARC_UpgradeChangeFee__c=1199,ARC_AddMemberChangeFee__c=1199);

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = acc.Id;
        census.ARC_PrimaryAccount__c = acc.Id;
        insert census;

        vlocity_ins__GroupCensusMember__c censusMem1 = new vlocity_ins__GroupCensusMember__c();
        censusMem1.Name = 'Test Census Member';
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        censusMem1.vlocity_ins__IsPrimaryMember__c = true;
        censusMem1.vlocity_ins__Email__c = 'soyunMail@cc.com'; 
        censusMem1.vlocity_ins__SocialSecurityNumber__c = '654654654';
        censusMem1.ARC_Weight__c = '120';
        censusMem1.vlocity_ins__FirstName__c = 'Member';
        censusMem1.vlocity_ins__LastName__c = 'Test Census';
        censusMem1.vlocity_ins__Birthdate__c = Date.newInstance(1990, 08, 15);
        censusMem1.ARC_ActiveMember__c = true;
        // censusMem1.isNew = true;
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        insert censusMem1;


        List<Contract> lCon = ARC_TestUtility.createContractsAA(2);
        Contract con = lCon[0];
        con.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con.Status = 'Draft';
        con.ARC_ContractReason__c = 'New Application';
        con.AccountId = acc.Id;
        con.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 06);
        upsert con;

        Contract con1 = lCon[1];
        con1.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con1.Status = 'Draft';
        con1.AccountId = acc.Id;
        con1.ARC_ContractReason__c = 'New Application';
        con1.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 06);
        upsert con1;
        
        List<Case> c = ARC_TestUtility.createTestCase(1, 'Admission');
        Case caseCreated = c[0];
        caseCreated.ARC_Contract__c = con.Id;
        caseCreated.OwnerId = [SELECT Id FROM Group WHERE DeveloperName = 'ProcessingQueue'].Id;
        upsert caseCreated;

        con.Status = 'Awaiting Approval';
        con.ARC_Case__c = caseCreated.Id;
        upsert con;

        con1.Status = 'Awaiting Activation';
        con1.ARC_EffectiveDate__c = Date.today().addDays(1);
        upsert con1;

        con1.Status = 'Activated';
        con1.ARC_Case__c = caseCreated.Id;
        upsert con1;
        
        
        Id recordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Product').getRecordTypeId();
 
        Product2 prod2 = new Product2();
        prod2.Name = 'Parent Product';
        prod2.ProductCode = 'CS_FinanceVisitsFramework';
        prod2.vlocity_ins__Type__c = 'Medical';
        prod2.RecordTypeId = recordTypeId;
		insert prod2;
        
        List<vlocity_ins__ContractLineItem__c> cli = ARC_Testutility.createTestContractLineItem(1);
        cli[0].vlocity_ins__Product2Id__c = prod2.Id;
        cli[0].vlocity_ins__ContractId__c = con.Id;
        update cli;
        
        ARC_UnderwritingCaseMember__c ucMember = new ARC_UnderwritingCaseMember__c();
        ucMember.ARC_Member__c = censusMem1.Id;
        ucMember.ARC_Contract__c = con1.Id;
        ucMember.ARC_UnderwritingCase__c = caseCreated.Id;
        ucMember.ARC_ApprovalResolution__c = 'Approved';
        upsert ucMember;
        
        List<User> userList = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        Id userId = userList.size()>0?userList[0].Id:null;

        test.startTest();
        ARC_RepriceCase.repriceCase(caseCreated.Id);
        ARC_RepriceCase.getCase(caseCreated.Id);
        ARC_RepriceCase.getUnderwritingCaseMembers(caseCreated.Id);
        ARC_RepriceCase.getCaseForUpdate(caseCreated.Id,userId);
        test.stopTest();
    }
    
    
}