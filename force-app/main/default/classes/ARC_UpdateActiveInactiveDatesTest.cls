@isTest 
public with sharing class ARC_UpdateActiveInactiveDatesTest {
    

   @TestSetup
    private static void createData(){
  
        List<Contract> contracts = ARC_TestUtility.createContractsAA(2);
        Contract contract = contracts[0];
        contract.ARC_EffectiveDate__c = Date.valueOf('2022-11-12');
        contract.ARC_Inactive_Date__c = Date.valueOf('2023-01-01');
        contract.Status = 'Draft';
        contract.ARC_ContractReason__c = 'New Application';
        upsert contract;

        List<Product2> products = ARC_TestUtility.createTestProducts(1);
        Product2 p = products[0];
        p.ProductCode = 'PROG_UHSM_WeShare3k';
        p.vlocity_ins__Type__c = 'Medical';
        upsert p;

        List<vlocity_ins__ContractLineItem__c> contractLineItems = ARC_TestUtility.createTestContractLineItem(1);
        vlocity_ins__ContractLineItem__c cli = contractLineItems[0];
        cli.vlocity_ins__ContractId__c = contract.Id;
        cli.vlocity_ins__Product2Id__c = p.Id;
        update cli;

        List<InsurancePolicy> policies = ARC_TestUtility.createTestPolicies(1);
        InsurancePolicy pol = policies[0];
        pol.ARC_Contract__c = contract.Id;
        pol.Product = p;
        upsert pol;

        List<vlocity_ins__GroupCensusMember__c> cms = ARC_TestUtility.createTestCensusMember(1);
        vlocity_ins__GroupCensusMember__c cm = cms[0];
        cm.vlocity_ins__Email__c = 'testMail@itsAMail.com';
        cm.vlocity_ins__SocialSecurityNumber__c = '164244245';
        cm.vlocity_ins__Birthdate__c  = Date.valueOf('1988-06-03');
        cm.vlocity_ins__IsPrimaryMember__c = true;
        cm.ARC_ActiveMember__c = true;
        upsert cm;

        contract.vlocity_ins__EnrollmentCensusId__c = cm.vlocity_ins__CensusId__c;
        //contract.Status = 'Awaiting Activation';
        upsert contract;
    
        Id IdFromMember = cm.Id;

        List<Case> cases = ARC_TestUtility.createTestCase(1, 'Admission');
        Case cas = cases[0];

        cas.ARC_Contract__c = contract.Id;
        upsert cas;

        contract.ARC_Case__c = cas.Id;
        upsert contract;

        // List<ARC_UnderwritingCaseMember__c> ucms = ARC_TestUtility.createTestUndCaseMember(1);
        // ARC_UnderwritingCaseMember__c ucm = ucms[0];
        ARC_UnderwritingCaseMember__c ucm = new ARC_UnderwritingCaseMember__c();
        ucm.Name = 'Test Underwriting Case Item ';
        ucm.ARC_Member__c = cm.Id;
        ucm.ARC_UnderwritingCase__c = cas.Id;
        ucm.ARC_ApprovalResolution__c = 'Approved';
        ucm.ARC_Contract__c = contract.Id;
        ucm.ARC_Member__c =cm.Id;
        upsert ucm;

        List<Contact> contacts = ARC_TestUtility.createTestContact(1, 'Contact');
        Contact contact = contacts[0];
        contact.ARC_CensusMember__c = IdFromMember;
        upsert contact;

        cm.vlocity_ins__ContactId__c = contact.Id;
        upsert cm;

        List<InsurancePolicyParticipant> pps = ARC_TestUtility.createTestPolicyParticipant(1);
        InsurancePolicyParticipant pp = pps[0];
        pp.InsurancePolicyId = pol.Id;
        pp.PrimaryParticipantContactId = contact.Id;
        System.debug('pp');
        System.debug(pp);
        upsert pp;

        cas.Status = 'Closed Approved';
        upsert cas;

        contract.Status = 'Activated';
        upsert contract;

        Product2 productPPO = new Product2();
        productPPO.Name = 'PPO';
        productPPO.vlocity_ins__Type__c = 'Medical';
        upsert productPPO;

        Product2 productSMART = new Product2();
        productSMART.Name = 'SMART';
        productSMART.vlocity_ins__SubType__c = 'SMART';
        upsert productSMART;

        Product2 productAIDD = new Product2();
        productAIDD.Name = 'AIDD';
        productAIDD.vlocity_ins__SubType__c = 'AIDD';
        upsert productAIDD;

        vlocity_ins__ContractLineItem__c cliOne = new vlocity_ins__ContractLineItem__c();
        cliOne.Name = 'Plan PPO';
        cliOne.vlocity_ins__Product2Id__c = productPPO.Id;
        cliOne.vlocity_ins__ContractId__c = contract.Id;
        upsert cliOne;
        
        vlocity_ins__ContractLineItem__c cliTwo = new vlocity_ins__ContractLineItem__c();
        cliTwo.Name = 'Plan SMART';
        cliTwo.vlocity_ins__Product2Id__c = productSMART.Id;
        cliTwo.vlocity_ins__ContractId__c = contract.Id;
        upsert cliTwo;
        
        vlocity_ins__ContractLineItem__c cliThree = new vlocity_ins__ContractLineItem__c();
        cliThree.Name = 'Plan AIDD';
        cliThree.vlocity_ins__Product2Id__c = productSMART.Id;
        cliThree.vlocity_ins__ContractId__c = contract.Id;
        upsert cliThree;

        vlocity_ins__GroupCensusMemberPlan__c gpcmp = new vlocity_ins__GroupCensusMemberPlan__c();
        gpcmp.Name = 'Test GCMP';
        gpcmp.vlocity_ins__GroupCensusMemberId__c = cm.Id;
        gpcmp.vlocity_ins__ContractLineId__c = cliOne.Id;
        upsert gpcmp;
        
        vlocity_ins__GroupCensusMemberPlan__c gpcmpTwo = new vlocity_ins__GroupCensusMemberPlan__c();
        gpcmpTwo.Name = 'Test GCMP TWO';
        gpcmpTwo.vlocity_ins__ContractLineId__c = cliTwo.Id;
        gpcmpTwo.vlocity_ins__GroupCensusMemberId__c = cm.Id;
        upsert gpcmpTwo;
        
        vlocity_ins__GroupCensusMemberPlan__c gpcmpThree = new vlocity_ins__GroupCensusMemberPlan__c();
        gpcmpThree.Name = 'Test GCMP THREE';
        gpcmpThree.vlocity_ins__ContractLineId__c = cliThree.Id;
        gpcmpThree.vlocity_ins__GroupCensusMemberId__c = cm.Id;
        upsert gpcmpThree;

    }

    @isTest 
    public static void calculateDatesPerMemberAndProgramTest() {

        vlocity_ins__GroupCensusMember__c gcm = [SELECT Id,vlocity_ins__IsPrimaryMember__c,vlocity_ins__Birthdate__c, Name, vlocity_ins__ContactId__r.Account.IsActive,vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__Email__c = 'testMail@itsAMail.com'];
        System.debug(gcm.vlocity_ins__ContactId__c);
        System.debug(gcm.vlocity_ins__ContactId__r.Account);
        System.debug(gcm.vlocity_ins__ContactId__r.Account.IsActive);
        vlocity_ins__GroupCensusMemberPlan__c gcmpOne = [SELECT Id FROM vlocity_ins__GroupCensusMemberPlan__c WHERE Name = 'Test GCMP'];
        vlocity_ins__ContractLineItem__c cli =  [SELECT Id FROM vlocity_ins__ContractLineItem__c WHERE Name = 'Plan PPO'];
        Product2 prod = [SELECT Id From Product2 WHERE Name = 'PPO'];
        List<Contract> clist = [SELECT Id, Status FROM Contract];
        System.debug(clist);
        
        vlocity_ins__GroupCensusMemberPlan__c gcmpTwo = new vlocity_ins__GroupCensusMemberPlan__c();
        gcmpTwo.Name = 'Test GCMP';
        gcmpTwo.vlocity_ins__GroupCensusMemberId__c = gcm.Id;
        gcmpTwo.vlocity_ins__ContractLineId__c = cli.Id;
        upsert gcmpTwo;
        
        Test.startTest();
        List <Map<Id, Object>> finalListOfMaps2 = ARC_UpdateActiveInactiveDatesPA.calculateDatesPerMemberAndProgram(gcm.Id);

        Test.stopTest();

    }
     @isTest 
    public static void calculateDatesPerMemberAndProgramTestTwo() {

        vlocity_ins__GroupCensusMember__c gcm = [SELECT Id, Name FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__Email__c = 'testMail@itsAMail.com'];
        
        vlocity_ins__GroupCensusMemberPlan__c gcmp = [SELECT Id FROM vlocity_ins__GroupCensusMemberPlan__c WHERE Name = 'Test GCMP TWO'];
        
        vlocity_ins__ContractLineItem__c cli =  [SELECT Id FROM vlocity_ins__ContractLineItem__c WHERE Name = 'Plan SMART'];
		vlocity_ins__GroupCensusMemberPlan__c gcmpTwo = new vlocity_ins__GroupCensusMemberPlan__c();
        gcmpTwo.Name = 'Test GCMP';
        gcmpTwo.vlocity_ins__GroupCensusMemberId__c = gcm.Id;
        gcmpTwo.vlocity_ins__ContractLineId__c = cli.Id;
        upsert gcmpTwo;        
        Product2 prod = [SELECT Id From Product2 WHERE Name = 'SMART'];
        cli.vlocity_ins__Product2Id__c = prod.Id;
        
       	gcmp.vlocity_ins__ContractLineId__c = cli.Id;
        update gcmp;

        Test.startTest();
        List <Map<Id, Object>> finalListOfMaps2 = ARC_UpdateActiveInactiveDatesPA.calculateDatesPerMemberAndProgram(gcm.Id);
        Test.stopTest();

    }
    
      @isTest 
    public static void calculateDatesPerMemberAndProgramTestFour() {

        vlocity_ins__GroupCensusMember__c gcm = [SELECT Id,Name FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__Email__c = 'testMail@itsAMail.com'];
        
        vlocity_ins__GroupCensusMemberPlan__c gcmp = [SELECT Id FROM vlocity_ins__GroupCensusMemberPlan__c WHERE Name = 'Test GCMP THREE'];
        vlocity_ins__ContractLineItem__c cli =  [SELECT Id FROM vlocity_ins__ContractLineItem__c WHERE Name = 'Plan AIDD'];
        vlocity_ins__GroupCensusMemberPlan__c gcmpTwo = new vlocity_ins__GroupCensusMemberPlan__c();
        gcmpTwo.Name = 'Test GCMP';
        gcmpTwo.vlocity_ins__GroupCensusMemberId__c = gcm.Id;
        gcmpTwo.vlocity_ins__ContractLineId__c = cli.Id;
        upsert gcmpTwo;
        
        Product2 prod = [SELECT Id From Product2 WHERE Name = 'AIDD'];
        cli.vlocity_ins__Product2Id__c = prod.Id;
        update cli;
        vlocity_ins__ContractLineItem__c cliTwo =  [SELECT Id FROM vlocity_ins__ContractLineItem__c WHERE Name = 'Plan SMART'];
        
                
        Contract cont = [SELECT Id From Contract WHERE Status = 'Activated'];
      
        
        Test.startTest();
        List <Map<Id, Object>> finalListOfMaps2 = ARC_UpdateActiveInactiveDatesPA.calculateDatesPerMemberAndProgram(gcm.Id);
        Test.stopTest();

    }

}