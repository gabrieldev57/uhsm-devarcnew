@isTest
public with sharing class ARC_HealthriveClaimsBatchTest {
    @isTest
    static void testHealthriveClaimsBatch() {

        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Group').getRecordTypeId();
        Id personAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account acc = new Account(Name = 'TestAccountName',BillingState='KS',vlocity_ins__Email__c=randomEmail(),RecordTypeId=accRecordTypeId,ARC_NationalProviderId__c='9876543210');
        insert acc;
        
        Account personAcc = new Account(Firstname='testclass', Lastname='testckass', RecordTypeId=personAccRTId, BillingStreet='123 Kansas Street', BillingPostalCode='11220', BillingCity='NY', BillingCountry='US',BillingState='KS');
        insert personAcc;
        Contact perAccCont = [SELECT Id, Account.BillingStreet FROM Contact WHERE AccountId =: personAcc.Id LIMIT 1]; 
        system.debug(personAcc);
        system.debug(perAccCont.Account.BillingStreet);
        
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(Name='censusTest',vlocity_ins__GroupId__c=acc.Id,ARC_PrimaryAccount__c=acc.Id);
        insert census;
        
        vlocity_ins__GroupCensusMember__c primaryMember = new vlocity_ins__GroupCensusMember__c(
                Name = 'Test Primary Member',
                vlocity_ins__Email__c = randomEmail(),
                vlocity_ins__CensusId__c = census.Id,
                vlocity_ins__IsPrimaryMember__c = true,
                vlocity_ins__Gender__c = 'Male',
                vlocity_ins__SocialSecurityNumber__c = '123456789',
                vlocity_ins__Birthdate__c = date.today().addYears(-65).toStartOfMonth(),
                ARC_ActiveMember__c = true,
                ARC_PhysicalAddressState__c = 'KS',
                ARC_PhysicalAddressStreet__c = 'E Lincoln St',
                ARC_PhysicalAddressCity__c = 'Wichita',
                ARC_Phone__c = '3165244400',
                ARC_PhysicalAddressZipCode__c = '67209',
                vlocity_ins__ContactId__c = perAccCont.Id);
        insert primaryMember;
        personAcc.ARC_CensusMember__pc = primaryMember.Id; 
        update personAcc;
        
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
        Id claimRecordTypeId = Schema.SObjectType.Claim.getRecordTypeInfosByDeveloperName().get('ARC_Institutional').getRecordTypeId();
        ClaimCoveragePaymentDetail ccpd = ARC_TestUtility.createTestCoveragePayments(1)[0];
        ccpd.ARC_Mod1__c = '123456789';
        ccpd.ARC_Mod2__c = '123456789';
        ccpd.ARC_Mod3__c = '123456789';
        ccpd.ARC_Mod4__c = '123456789';
        ccpd.ARC_Allowed__c = 1000;
        ccpd.ARC_Copay__c = 0;
        ccpd.ARC_Deductible__c = 0;
        ccpd.ARC_Coinsurance__c = 0;
        ccpd.ClaimedAmount = 200;
        ccpd.ARC_DateOfService__c = date.today(); 
        ccpd.ARC_RevenueCode__c = 'test';
        ccpd.ARC_Quantity__c = 2;
        ccpd.ARC_ProcedureCode__c = testCode.Id;
        ccpd.Status = 'Denied'; 
        update ccpd;
        ARC_ClaimReasonCode__c cReasonCodeTest = new ARC_ClaimReasonCode__c();
        cReasonCodeTest.ARC_ClaimCoveragePaymentDetail__c = ccpd.Id;
        cReasonCodeTest.ARC_ReasonCode__c = testCode.Id;
        insert cReasonCodeTest;

        Product2 prod = new Product2();
        prod.Name = 'UHSM Gold $5K';
        prod.ProductCode = 'PROG_UHSMGold';
        prod.vlocity_ins__Type__c = 'Medical';
        insert prod;

        Claim c = [SELECT Id FROM Claim WHERE Id =: ccpd.ARC_Claim__c];
        InsurancePolicy p = new InsurancePolicy();
        p.Name = 'Test Policy';
        p.NameInsuredId = acc.Id;
        p.ProductId = prod.Id;
        insert p;

        ClaimPaymentSummary cps = new ClaimPaymentSummary();
        cps.Name = 'testcps';
        cps.ARC_SMB_Item__c = ccpd.Id;
        cps.PaymentAmount = 150;
        cps.PaymentDate = date.today(); 
        cps.ClaimId = c.Id;
        insert cps;

        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant();
        ipp.InsurancePolicyId = p.Id;
        ipp.vlocity_ins_fsc__InsuredPartySpecId__c = prod.Id;
        ipp.PrimaryParticipantContactId = perAccCont.Id;
        ipp.Role = 'Primary';
        insert ipp;

        c.RecordTypeId = claimRecordTypeId;
        c.ARC_MemberContact__c = perAccCont.Id;
        c.ARC_Vendor__c = acc.Id;        
        c.SourceSystemIdentifier = 'testSysID123456';
        c.DX_A__c = testCode.Id;
        c.DX_B__c = testCode.Id;
        c.DX_C__c = testCode.Id;
        c.DX_D__c = testCode.Id;
        c.DX_E__c = testCode.Id;
        c.DX_F__c = testCode.Id;
        c.DX_G__c = testCode.Id;
        c.DX_H__c = testCode.Id;
        c.DX_I__c = testCode.Id;
        c.DX_J__c = testCode.Id;
        c.DX_K__c = testCode.Id;
        c.DX_L__c = testCode.Id;
        c.ARC_TypeofBill__c = 'abcd';
        c.PolicyNumberId = p.Id;
        c.ARC_Attending_Provider__c = accProv.Id;
        c.ARC_PlaceOfService__c = 'KS';
        c.ARC_Submitted_DRG_Code__c = testCode.Id;
        c.ARC_AdmitDX_Code__c = testCode.Id;
        c.ARC_DOSFrom__c = date.today();
        c.ARC_DOSTo__c = date.today();
        c.ARC_Payment_To__c = 'Member';
        c.ARC_ParticipantPolicyParticipant__c = ipp.Id;
        c.ARC_PrimaryMemberCM__c = primaryMember.Id;
        c.ARC_Primary_Member__c = perAccCont.Id;
        update c;

        c.Status='Manual Denied';
        update c;
        c.ARC_CheckRun__c = checkRunTest.Id;
        
        ARC_SureCoClaim__c sureCoClaim = new ARC_SureCoClaim__c(ARC_LastSent__c=date.today().addDays(-1),Name='SureCoClaim');
        insert sureCoClaim ; 

        Test.startTest();
        ARC_HealthriveClaimsBatch.runSureCoBatch();
        Test.stopTest();
    }

    public static String randomEmail(){
        String orgId = UserInfo.getOrganizationId();  
        String dateString =   
        String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');  
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));  
        String uniqueName = orgId + dateString + randomInt;  
        String email = uniqueName + '@test' + orgId + '.org';  
        return email;  
    }
}