@isTest
public with sharing class ARC_CheckRunTriggerHandlerTest {

    @isTest(SeeAllData='true')
    public static void ARC_CheckRunTriggerHandlerTest() {
        //Create Account as Vendor 
        Account a = new Account(FirstName='Account', LastName='Test', BillingStreet='2nd Avenue', BillingState='NY', BillingPostalCode='12345', BillingCity='New York', ARC_Provider_Name__c='Ins Provider',ARC_Provider_Tax_Id__c=1234567, ARC_NationalProviderId__c='23322');
        insert a;
        Id personAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account acc = new Account(Firstname='testclass', Lastname='testckass', RecordTypeId=personAccRTId, BillingStreet='123 Kansas Street', BillingPostalCode='11220', BillingCity='NY', BillingCountry='US',BillingState='KS');
        insert acc;
        Contact con = [SELECT Id, Account.BillingStreet FROM Contact WHERE AccountId =: acc.Id LIMIT 1];
        
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(Name='censusTest',vlocity_ins__GroupId__c=acc.Id,ARC_PrimaryAccount__c=acc.Id);
        insert census;


        vlocity_ins__GroupCensusMember__c primaryMember = new vlocity_ins__GroupCensusMember__c(
                Name = 'Test Primary Member',
                vlocity_ins__Email__c = 'asd@asd.com',
                vlocity_ins__CensusId__c = census.Id,
                vlocity_ins__IsPrimaryMember__c = true,
                vlocity_ins__Gender__c = 'Male',
                vlocity_ins__SocialSecurityNumber__c = '999999999',
                vlocity_ins__Birthdate__c = date.today().addYears(-65).toStartOfMonth(),
                ARC_ActiveMember__c = true,
                ARC_PhysicalAddressState__c = 'KS',
                ARC_PhysicalAddressStreet__c = 'E Lincoln St',
                ARC_PhysicalAddressCity__c = 'Wichita',
                ARC_Phone__c = '3165244400',
                ARC_PhysicalAddressZipCode__c = '67209',
                vlocity_ins__ContactId__c = con.Id);
        insert primaryMember;
        acc.ARC_CensusMember__pc = primaryMember.Id; 
        update acc; 
        Contact contProv = new Contact();
        contProv.LastName = 'Test Provider Last Name';
        contProv.FirstName = 'Test Provider First Name';
        contProv.MailingStreet = 'Another Test Street';
        contProv.MailingCity = 'Wichita';
        contProv.MailingState = 'KS';
        contProv.MailingPostalCode = '67209';
        insert contProv;

        Contract contractt = new Contract();
        contractt.ContractTerm = 12;
        contractt.AccountId = acc.Id;
        contractt.ARC_Signer_Email__c = 'testEmail1@email.com';
        contractt.ARC_EffectiveDate__c = date.today().addDays(-200);
        contractt.ARC_Inactive_Date__c = date.today().addDays(165);
        insert contractt;
            
        InsurancePolicy testPolicyNumber = new InsurancePolicy(Name = '11', NameInsuredId = acc.Id, ARC_GroupAccount__c = acc.Id, ARC_Contract__c = contractt.Id);
        insert testPolicyNumber;
        
        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(InsurancePolicyId = testPolicyNumber.Id, Role = 'Primary', PrimaryParticipantContactId = con.Id  );
        insert ipp;

        ARC_CheckRun__c checkRun = new ARC_CheckRun__c();
        checkRun.ARC_Status__c	= 'Open';
        checkRun.Name = 'Test checkRun';    
        insert checkRun;
            

        //Create Claim + Claim Coverage Paymet Details
        List<ClaimCoveragePaymentDetail> ccpdList = ARC_TestUtility.createTestCoveragePayments(2);
        //Create Reason Code
        vlocity_ins__VlocityCode__c generalCode = new vlocity_ins__VlocityCode__c();
        insert generalCode;
            
        ARC_ClaimReasonCode__c reasonCode = new ARC_ClaimReasonCode__c();
        reasonCode.ARC_ClaimCoveragePaymentDetail__c = ccpdList[0].Id;
        reasonCode.ARC_ReasonCode__c = generalCode.Id;
        insert reasonCode; 
        ARC_XMLCounter__c xmlCount = new ARC_XMLCounter__c();
        xmlCount.Name = 'ZelisCheckTest';
        xmlCount.ARC_CheckNumber__c = 1000;
        insert xmlCount;

        Claim c = [SELECT Id, ARC_Vendor__r.Name,ARC_Vendor__r.BillingStreet, ARC_Vendor__r.BillingCity,ARC_Vendor__r.BillingState,ARC_Vendor__r.BillingPostalCode, 
                ARC_TotalIneligibleAmount__c,ARC_TotalPaymentAmount__c,ARC_TotalPreviouslyPaidAmount__c, ARC_Payment_To__c, ARC_TotalPatientResponsibilityAmount__c,ARC_TotalDiscountAmount__c,
                ARC_Vendor__r.ARC_Provider_Tax_Id__c , ARC_Vendor__r.ARC_Provider_Name__c, ARC_MemberContact__c, ARC_ClaimNotes__c, 
                ARC_MemberBenefitPlan__c, ARC_ClaimTotalAmount__c, ARC_TotalAdjustedAmount__c ,ARC_TotalDeductibleAmount__c, 
                ARC_TotalCoinsuranceAmount__c, ARC_TotalCopayAmount__c, ARC_TotalAllowedAmount__c,ARC_Vendor__r.ARC_NationalProviderId__c, 
                ARC_TransactionSetControlNumber__c, LossDate, ARC_OriginalReceivedDate__c, Name,ARC_CheckRun__c ,PolicyNumber.Name, ARC_ParticipantPolicyParticipant__c,ARC_Primary_Member__c, ARC_PrimaryMemberCM__c FROM Claim WHERE Id =: ccpdList[0].ARC_Claim__c LIMIT 1];

        for ( ClaimCoveragePaymentDetail ccpd : ccpdList) {
            ccpd.Status='Denied';
        }
        update ccpdList;
        c.ARC_Payment_To__c='Member';
        c.PolicyNumberId = testPolicyNumber.Id;
        c.ARC_MemberContact__c = con.Id;    
        c.ARC_ParticipantPolicyParticipant__c = ipp.Id;
        c.ARC_TotalIneligibleAmount__c = 200;
        c.ARC_TotalPaymentAmount__c= 300;
        c.ARC_TotalPreviouslyPaidAmount__c=100;
        c.ARC_TotalPatientResponsibilityAmount__c=50;
        c.ARC_TotalDiscountAmount__c=20;
        c.ARC_ClaimTotalAmount__c = 2163.20;
        c.ARC_TotalAdjustedAmount__c= 150;
        c.ARC_TotalDeductibleAmount__c= 30;
        c.ARC_TotalCoinsuranceAmount__c= 60;
        c.ARC_TotalCopayAmount__c= 600;
        c.ARC_TotalAllowedAmount__c=9000;
        c.ARC_TotalNetPaidAmount__c=9000;
        c.LossDate = date.today();    
        c.Status = 'Initial';
        c.ARC_PrimaryMemberCM__c = primaryMember.Id;
        c.ARC_Primary_Member__c = con.Id;
        update c;

        c.Status = 'Manual Denied';
        c.ARC_AuditorValidation__c = 'Approved';
        // List<User> auditorUser = [SELECT Id FROM User WHERE Name='Nahuel Moreno' AND Profile.Name='System Administrator'];
        // c.Audited_By__c = auditorUser[0].Id;
        update c;
        c.ARC_CheckRun__c = checkRun.Id;
        c.ARC_CheckRunApproval__c = 'Approved';
        update c;
            
        system.debug('checkRunId Mock' +' '+ c.ARC_CheckRun__c);

        //Create CheckNumber Custom Setting
        ARC_XMLCounter__c checkNumberCounter = new ARC_XMLCounter__c(Name='ZelisCheckTest2', ARC_CheckNumber__c=1000);
        insert checkNumberCounter;
        //Create Counter
        ARC_XMLCounter__c xmlCounter = new ARC_XMLCounter__c(Name='ZelisXMLTest',ARC_Date__c=Date.today(),ARC_Counter__c='00.00');
        insert xmlCounter;
        ARC_MockHttpResponseGenerator mockOne = new ARC_MockHttpResponseGenerator();
        
        test.startTest();
            Test.setMock(HttpCalloutMock.class, mockOne);

            checkRun.ARC_Status__c	= 'Closed';
            update checkRun;
        test.stopTest();
    }
    
    @isTest
    public static void testOptumProcessorDoesNotTriggerZelisLogic() {
        // Create Account as Vendor 
        Account a = new Account(FirstName='Account', LastName='Test', BillingStreet='2nd Avenue', BillingState='NY', BillingPostalCode='12345', BillingCity='New York', ARC_Provider_Name__c='Ins Provider',ARC_Provider_Tax_Id__c=1234567, ARC_NationalProviderId__c='23322');
        insert a;
        
        Id personAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account acc = new Account(Firstname='testclass', Lastname='testckass', RecordTypeId=personAccRTId, BillingStreet='123 Kansas Street', BillingPostalCode='11220', BillingCity='NY', BillingCountry='US',BillingState='KS');
        insert acc;
        Contact con = [SELECT Id, Account.BillingStreet FROM Contact WHERE AccountId =: acc.Id LIMIT 1];
        
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(Name='censusTest',vlocity_ins__GroupId__c=acc.Id,ARC_PrimaryAccount__c=acc.Id);
        insert census;
    
        vlocity_ins__GroupCensusMember__c primaryMember = new vlocity_ins__GroupCensusMember__c(
                Name = 'Test Primary Member',
                vlocity_ins__Email__c = 'asd@asd.com',
                vlocity_ins__CensusId__c = census.Id,
                vlocity_ins__IsPrimaryMember__c = true,
                vlocity_ins__Gender__c = 'Male',
                vlocity_ins__SocialSecurityNumber__c = '999999999',
                vlocity_ins__Birthdate__c = date.today().addYears(-65).toStartOfMonth(),
                ARC_ActiveMember__c = true,
                ARC_PhysicalAddressState__c = 'KS',
                ARC_PhysicalAddressStreet__c = 'E Lincoln St',
                ARC_PhysicalAddressCity__c = 'Wichita',
                ARC_Phone__c = '3165244400',
                ARC_PhysicalAddressZipCode__c = '67209',
                vlocity_ins__ContactId__c = con.Id);
        insert primaryMember;
        acc.ARC_CensusMember__pc = primaryMember.Id; 
        update acc; 
    
        Contract contract = new Contract();
        contract.ContractTerm = 12;
        contract.AccountId = acc.Id;
        contract.ARC_Signer_Email__c = 'testEmail1@email.com';
        contract.ARC_EffectiveDate__c = date.today().addDays(-200);
        contract.ARC_Inactive_Date__c = date.today().addDays(165);
        insert contract;
            
        InsurancePolicy testPolicyNumber = new InsurancePolicy(Name = '11', NameInsuredId = acc.Id, ARC_GroupAccount__c = acc.Id, ARC_Contract__c = contract.Id);
        insert testPolicyNumber;
        
        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(InsurancePolicyId = testPolicyNumber.Id, Role = 'Primary', PrimaryParticipantContactId = con.Id);
        insert ipp;
    
        // Create CheckRun with Optum processor
        ARC_CheckRun__c checkRun = new ARC_CheckRun__c();
        checkRun.ARC_Status__c = 'Open';
        checkRun.Name = 'Test Optum CheckRun';
        checkRun.Processor__c = 'Optum'; // Set processor to Optum
        insert checkRun;
    
        // Create Claim + Claim Coverage Payment Details
        List<ClaimCoveragePaymentDetail> ccpdList = ARC_TestUtility.createTestCoveragePayments(2);
        
        // Create Reason Code
        vlocity_ins__VlocityCode__c generalCode = new vlocity_ins__VlocityCode__c();
        insert generalCode;
            
        ARC_ClaimReasonCode__c reasonCode = new ARC_ClaimReasonCode__c();
        reasonCode.ARC_ClaimCoveragePaymentDetail__c = ccpdList[0].Id;
        reasonCode.ARC_ReasonCode__c = generalCode.Id;
        insert reasonCode; 
    
        // Note: No Zelis-specific setup needed since we're testing Optum processor
    
        Claim c = [SELECT Id, ARC_Vendor__r.Name,ARC_Vendor__r.BillingStreet, ARC_Vendor__r.BillingCity,ARC_Vendor__r.BillingState,ARC_Vendor__r.BillingPostalCode, 
                ARC_TotalIneligibleAmount__c,ARC_TotalPaymentAmount__c,ARC_TotalPreviouslyPaidAmount__c, ARC_Payment_To__c, ARC_TotalPatientResponsibilityAmount__c,ARC_TotalDiscountAmount__c,
                ARC_Vendor__r.ARC_Provider_Tax_Id__c , ARC_Vendor__r.ARC_Provider_Name__c, ARC_MemberContact__c, ARC_ClaimNotes__c, 
                ARC_MemberBenefitPlan__c, ARC_ClaimTotalAmount__c, ARC_TotalAdjustedAmount__c ,ARC_TotalDeductibleAmount__c, 
                ARC_TotalCoinsuranceAmount__c, ARC_TotalCopayAmount__c, ARC_TotalAllowedAmount__c,ARC_Vendor__r.ARC_NationalProviderId__c, 
                ARC_TransactionSetControlNumber__c, LossDate, ARC_OriginalReceivedDate__c, Name,ARC_CheckRun__c ,PolicyNumber.Name, ARC_ParticipantPolicyParticipant__c,ARC_Primary_Member__c, ARC_PrimaryMemberCM__c FROM Claim WHERE Id =: ccpdList[0].ARC_Claim__c LIMIT 1];
    
        for (ClaimCoveragePaymentDetail ccpd : ccpdList) {
            ccpd.Status = 'Denied';
        }
        update ccpdList;
        
        c.ARC_Payment_To__c = 'Member';
        c.PolicyNumberId = testPolicyNumber.Id;
        c.ARC_MemberContact__c = con.Id;    
        c.ARC_ParticipantPolicyParticipant__c = ipp.Id;
        c.ARC_TotalIneligibleAmount__c = 200;
        c.ARC_TotalPaymentAmount__c = 300;
        c.ARC_TotalPreviouslyPaidAmount__c = 100;
        c.ARC_TotalPatientResponsibilityAmount__c = 50;
        c.ARC_TotalDiscountAmount__c = 20;
        c.ARC_ClaimTotalAmount__c = 2163.20;
        c.ARC_TotalAdjustedAmount__c = 150;
        c.ARC_TotalDeductibleAmount__c = 30;
        c.ARC_TotalCoinsuranceAmount__c = 60;
        c.ARC_TotalCopayAmount__c = 600;
        c.ARC_TotalAllowedAmount__c = 9000;
        c.ARC_TotalNetPaidAmount__c = 9000;
        c.LossDate = date.today();    
        c.Status = 'Initial';
        c.ARC_PrimaryMemberCM__c = primaryMember.Id;
        c.ARC_Primary_Member__c = con.Id;
        update c;
    
        c.Status = 'Manual Denied';
        c.ARC_AuditorValidation__c = 'Approved';
        update c;
        
        c.ARC_CheckRun__c = checkRun.Id;
        c.ARC_CheckRunApproval__c = 'Approved';
        update c;
    
        test.startTest();
            // Reset the flag before testing
            ARC_CheckRunTriggerHandler.zelisLogicExecuted = false;
            
            // Update CheckRun status to Closed - this should NOT trigger Zelis logic
            checkRun.ARC_Status__c = 'Closed';
            update checkRun;
        test.stopTest();
        
        // Verify that Zelis logic was NOT executed
        System.assertEquals(false, ARC_CheckRunTriggerHandler.zelisLogicExecuted, 'Zelis logic should not have been executed for Optum processor');
        System.assertEquals('Closed', checkRun.ARC_Status__c, 'CheckRun status should be Closed');
    }
    
}