@IsTest
public with sharing class ARC_ClaimFlowUtilsTest {

    public static final Id GROUP_ACCOUNT_RECORD_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Group').getRecordTypeId();
    public static final Id PERSON_ACCOUNT_RECORD_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();


    @TestSetup
    static void makeData(){

        Account test_group_account = new Account();
        test_group_account.Name = 'TestAccountName';
        test_group_account.BillingState='KS';
        test_group_account.vlocity_ins__Email__c='testingmail@testint.com';
        test_group_account.RecordTypeId= GROUP_ACCOUNT_RECORD_TYPE;
        test_group_account.ARC_NationalProviderId__c='9876543210';
        insert test_group_account;
        
        Account test_person_account = new Account();
        test_person_account.Firstname ='testclass';
        test_person_account.Lastname ='testckass';
        test_person_account.RecordTypeId = PERSON_ACCOUNT_RECORD_TYPE;
        test_person_account.BillingStreet ='123 Kansas Street';
        test_person_account.BillingPostalCode ='11220';
        test_person_account.BillingCity ='NY';
        test_person_account.BillingCountry ='US';
        test_person_account.BillingState ='KS';
        insert test_person_account;

        Contact test_person_account_contact = [SELECT Id, Account.BillingStreet FROM Contact WHERE AccountId =: test_person_account.Id LIMIT 1]; 

        vlocity_ins__GroupCensus__c test_census = new vlocity_ins__GroupCensus__c(Name='censusTest',vlocity_ins__GroupId__c=test_group_account.Id,ARC_PrimaryAccount__c=test_group_account.Id);
        insert test_census;
        
        vlocity_ins__GroupCensusMember__c test_primary_member = new vlocity_ins__GroupCensusMember__c();
        test_primary_member.Name = 'Test Primary Member';
        test_primary_member.vlocity_ins__Email__c = 'testingmail2@testint.com';
        test_primary_member.vlocity_ins__CensusId__c = test_census.Id;
        test_primary_member.vlocity_ins__IsPrimaryMember__c = true;
        test_primary_member.vlocity_ins__Gender__c = 'Male';
        test_primary_member.vlocity_ins__SocialSecurityNumber__c = '123456789';
        test_primary_member.vlocity_ins__Birthdate__c = date.today().addYears(-65).toStartOfMonth();
        test_primary_member.ARC_ActiveMember__c = true;
        test_primary_member.ARC_PhysicalAddressState__c = 'KS';
        test_primary_member.ARC_PhysicalAddressStreet__c = 'E Lincoln St';
        test_primary_member.ARC_PhysicalAddressCity__c = 'Wichita';
        test_primary_member.ARC_Phone__c = '3165244400';
        test_primary_member.ARC_PhysicalAddressZipCode__c = '67209';
        test_primary_member.vlocity_ins__ContactId__c = test_person_account_contact.Id;
        insert test_primary_member;

        test_person_account.ARC_CensusMember__pc = test_primary_member.Id; 
        update test_person_account;
        
        Account accProv = new Account();
        accProv.LastName = 'Test Provider Last Name';
        accProv.FirstName = 'Test Provider First Name';
        accProv.PersonMailingStreet = 'Another Test Street';
        accProv.PersonMailingCity = 'Wichita';
        accProv.PersonMailingState = 'KS';
        accProv.PersonMailingPostalCode = '67209';
        insert accProv;

        ARC_CheckRun__c checkRunTest = new ARC_CheckRun__c();
        checkRunTest.ARC_Status__c = 'Open';
        insert checkRunTest;
        vlocity_ins__VlocityCode__c testCode = new vlocity_ins__VlocityCode__c();
        testCode.Name = 'Test Code';
        testCode.vlocity_ins__ShortDescription__c = 'This is a short description';
        insert testCode;


        Product2 prod = new Product2();
        prod.Name = 'UHSM Gold $5K';
        prod.ProductCode = 'PROG_UHSMGold';
        prod.vlocity_ins__Type__c = 'Medical';
        insert prod;

        InsurancePolicy test_policy = new InsurancePolicy();
        test_policy.Name = 'Test Policy';
        test_policy.NameInsuredId = test_group_account.Id;
        test_policy.ProductId = prod.Id;
        insert test_policy;

        Claim test_claim = new Claim();
        test_claim.Name = 'Test Claim';
        test_claim.PolicyNumberId = test_policy.Id;
        test_claim.RecordTypeId = Schema.SObjectType.Claim.getRecordTypeInfosByDeveloperName().get('ARC_Institutional').getRecordTypeId();
        test_claim.ARC_MemberContact__c = test_person_account_contact.Id;
        test_claim.ARC_Vendor__c = test_group_account.Id;        
        test_claim.SourceSystemIdentifier = 'testSysID123456';
        test_claim.DX_A__c = testCode.Id;
        test_claim.DX_B__c = testCode.Id;
        test_claim.DX_C__c = testCode.Id;
        test_claim.DX_D__c = testCode.Id;
        test_claim.DX_E__c = testCode.Id;
        test_claim.DX_F__c = testCode.Id;
        test_claim.DX_G__c = testCode.Id;
        test_claim.DX_H__c = testCode.Id;
        test_claim.DX_I__c = testCode.Id;
        test_claim.DX_J__c = testCode.Id;
        test_claim.DX_K__c = testCode.Id;
        test_claim.DX_L__c = testCode.Id;
        test_claim.ARC_TypeofBill__c = 'abcd';
        test_claim.PolicyNumberId = test_policy.Id;
        test_claim.ARC_Attending_Provider__c = accProv.Id;
        test_claim.ARC_PlaceOfService__c = 'KS';
        test_claim.ARC_Submitted_DRG_Code__c = testCode.Id;
        test_claim.ARC_AdmitDX_Code__c = testCode.Id;
        test_claim.ARC_DOSFrom__c = date.today();
        test_claim.ARC_DOSTo__c = date.today();
        test_claim.ARC_Payment_To__c = 'Member';
        test_claim.Status = 'Initial';
        test_claim.ARC_AuditorValidation__c = 'Approved';
        test_claim.ARC_PrimaryMemberCM__c = test_primary_member.Id;
        test_claim.ARC_Primary_Member__c = test_person_account_contact.Id;
        insert test_claim;

        ClaimCoverage test_claim_coverage = new ClaimCoverage();
        test_claim_coverage.Name = 'Test Claim Coverage';
        test_claim_coverage.ClaimId = test_claim.Id;
        test_claim_coverage.InternalReserveMode = 'CoverageReserve';
        insert test_claim_coverage;

        ClaimCoveragePaymentDetail test_claim_coverage_payment_detail = new ClaimCoveragePaymentDetail();
        test_claim_coverage_payment_detail.Name = 'Test Claim Item';
        test_claim_coverage_payment_detail.ClaimCoverageId = test_claim_coverage.Id;
        test_claim_coverage_payment_detail.ARC_Claim__c = test_claim.Id;
        insert test_claim_coverage_payment_detail;

        test_claim_coverage_payment_detail.ARC_Mod1__c = '123456789';
        test_claim_coverage_payment_detail.ARC_Mod2__c = '123456789';
        test_claim_coverage_payment_detail.ARC_Mod3__c = '123456789';
        test_claim_coverage_payment_detail.ARC_Mod4__c = '123456789';
        test_claim_coverage_payment_detail.ARC_Allowed__c = 1000;
        test_claim_coverage_payment_detail.ARC_Copay__c = 100.5;
        test_claim_coverage_payment_detail.ARC_Deductible__c = 300;
        test_claim_coverage_payment_detail.ARC_Coinsurance__c = 150;
        test_claim_coverage_payment_detail.ClaimedAmount = 200;
        test_claim_coverage_payment_detail.ARC_DateOfService__c = date.today(); 
        test_claim_coverage_payment_detail.ARC_RevenueCode__c = 'test';
        test_claim_coverage_payment_detail.ARC_Quantity__c = 2;
        test_claim_coverage_payment_detail.ARC_ProcedureCode__c = testCode.Id;
        test_claim_coverage_payment_detail.Status = 'paid';
        update test_claim_coverage_payment_detail;
        
        ARC_ClaimReasonCode__c test_reason_code = new ARC_ClaimReasonCode__c();
        test_reason_code.ARC_ClaimCoveragePaymentDetail__c = test_claim_coverage_payment_detail.Id;
        test_reason_code.ARC_ReasonCode__c = testCode.Id;
        insert test_reason_code;

        ClaimPaymentSummary cps = new ClaimPaymentSummary();
        cps.Name = 'testcps';
        cps.ARC_SMB_Item__c = test_claim_coverage_payment_detail.Id;
        cps.PaymentAmount = 150;
        cps.PaymentDate = date.today(); 
        cps.ClaimId = test_claim.Id;
        insert cps;

        InsurancePolicyParticipant test_insurance_policy_participant = new InsurancePolicyParticipant();
        test_insurance_policy_participant.InsurancePolicyId = test_policy.Id;
        test_insurance_policy_participant.vlocity_ins_fsc__InsuredPartySpecId__c = prod.Id;
        test_insurance_policy_participant.PrimaryParticipantContactId = test_person_account_contact.Id;
        test_insurance_policy_participant.Role = 'Primary';
        insert test_insurance_policy_participant;

        test_claim.ARC_ParticipantPolicyParticipant__c = test_insurance_policy_participant.Id;
        update test_claim;

        //Create CheckNumber Custom Setting
        ARC_XMLCounter__c checkNumberCounter = new ARC_XMLCounter__c(Name='ZelisCheck', ARC_CheckNumber__c=1000);
        insert checkNumberCounter;
        //Create Counter
        ARC_XMLCounter__c xmlCounter = new ARC_XMLCounter__c(Name='ZelisXML',ARC_Date__c=Date.today(),ARC_Counter__c='00.00');
        insert xmlCounter;
    }


    @isTest
    static void testRecalculateTotals() {

        Claim test_claim = [SELECT Id FROM Claim WHERE SourceSystemIdentifier = 'testSysID123456' LIMIT 1];
        
        //Commented for testing without flow 
        ARC_ClaimFlowUtils.RecalculateTotalsInput input = new ARC_ClaimFlowUtils.RecalculateTotalsInput();
        input.claimId = test_claim.Id;
        List<ARC_ClaimFlowUtils.RecalculateTotalsInput> inputs = new List<ARC_ClaimFlowUtils.RecalculateTotalsInput>{ input };
        
        ARC_MockHttpResponseGenerator mockOne = new ARC_MockHttpResponseGenerator();

        Test.startTest();
        //Test.setMock(StubProvider.HttpCalloutMock, mock);
        //Test.setMock(ARC_ZelisPostToApi.ARC_MockHttpResponseGenerator.class, new ARC_MockHttpResponseGenerator());
        //Test.setMock(Queueable.class, mockTwo);
        Test.setMock(HttpCalloutMock.class, mockOne);
        ARC_ClaimFlowUtils.recalculateTotals(inputs);
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id, JobType FROM AsyncApexJob WHERE ParentJobId = NULL];
        System.assertEquals(2, jobs.size()); // Assuming only two jobs are enqueued
    }
}