@isTest
public class ARC_ZelisClaimsFileBatchTest {

    @TestSetup
    static void mockData() {
    
        //Create Account as Vendor 
        Account a = new Account(FirstName = 'Account', LastName = 'Test', BillingStreet = '2nd Avenue', BillingState = 'NY', BillingPostalCode = '12345', BillingCity = 'New York', ARC_Provider_Name__c = 'Ins Provider', ARC_Provider_Tax_Id__c = 1234567, ARC_NationalProviderId__c = '23322');
        insert a;

        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Group').getRecordTypeId();
        Account acc = new Account(Name = 'TestAccountName', BillingState = 'KS', BillingCity = 'Frankfort', BillingStreet = '123 Kansas Street', BillingPostalCode = '60423', vlocity_ins__Email__c = 'asdss@asd.com', RecordTypeId = accRecordTypeId, ARC_NationalProviderId__c = '9876543210');
        insert acc;
        Id personAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account personAcc = new Account(Firstname = 'testclass', Lastname = 'testckass', RecordTypeId = personAccRTId, BillingStreet = '123 Kansas Street', BillingPostalCode = '11220', BillingCity = 'NY', BillingCountry = 'US', BillingState = 'KS');
        insert personAcc;
        Contact perAccCont = [SELECT Id, Account.BillingStreet FROM Contact WHERE AccountId =: personAcc.Id LIMIT 1]; 

        InsurancePolicy testPolicyNumber = new InsurancePolicy(Name = '11', NameInsuredId = acc.Id, ARC_GroupAccount__c = acc.Id);
        insert testPolicyNumber;

        ARC_XMLCounter__c xmlCount = new ARC_XMLCounter__c();
        xmlCount.Name = 'ZelisCheck';
        xmlCount.ARC_CheckNumber__c = 1000;
        insert xmlCount;
            
        Contact con = new Contact();
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(Name = 'censusTest', vlocity_ins__GroupId__c = acc.Id, ARC_PrimaryAccount__c = acc.Id);
        con.LastName = 'safd';
        con.FirstName = 'asdasd';
        con.AccountId = acc.Id;
        insert census;
        insert con;
        vlocity_ins__GroupCensusMember__c primaryMember = new vlocity_ins__GroupCensusMember__c(
            Name = 'Test Primary Member',
            vlocity_ins__Email__c = 'asd@asd.com',
            vlocity_ins__CensusId__c = census.Id,
            vlocity_ins__IsPrimaryMember__c = true,
            vlocity_ins__Gender__c = 'Male',
            vlocity_ins__SocialSecurityNumber__c = '345678901',
            vlocity_ins__Birthdate__c = date.today().addYears(-65).toStartOfMonth(),
            ARC_ActiveMember__c = true,
            ARC_PhysicalAddressState__c = 'KS',
            ARC_PhysicalAddressStreet__c = 'E Lincoln St',
            ARC_PhysicalAddressCity__c = 'Wichita',
            ARC_Phone__c = '3165244400',
            ARC_PhysicalAddressZipCode__c = '67209',
            vlocity_ins__ContactId__c = perAccCont.Id);
        insert primaryMember;
        con.ARC_CensusMember__c = primaryMember.Id; 
        update con; 
        Contact contProv = new Contact();
        contProv.LastName = 'Test Provider Last Name';
        contProv.FirstName = 'Test Provider First Name';
        contProv.MailingStreet = 'Another Test Street';
        contProv.MailingCity = 'Wichita';
        contProv.MailingState = 'KS';
        contProv.MailingPostalCode = '67209';
        insert contProv;
            
        ARC_CheckRun__c checkRun = new ARC_CheckRun__c();
        checkRun.ARC_Status__c	= 'Open';
        checkRun.Name = 'Test checkRun';
        checkRun.Processor__c = 'Zelis';
        insert checkRun;
        
        //Create Claim + Claim Coverage Paymet Details
        List<ClaimCoveragePaymentDetail> ccpdList = ARC_TestUtility.createTestCoveragePayments(2);
        //Create Reason Code
        vlocity_ins__VlocityCode__c generalCode = new vlocity_ins__VlocityCode__c();
        generalCode.ARC_Status__c = 'Informational';
        generalCode.ARC_WPCInfoCode__c = 'CO';
        generalCode.ARC_WPCClaimEditCode__c = '131';
        insert generalCode;
            
        ARC_ClaimReasonCode__c reasonCode = new ARC_ClaimReasonCode__c();
        reasonCode.ARC_ClaimCoveragePaymentDetail__c = ccpdList[0].Id;
        reasonCode.ARC_ReasonCode__c = generalCode.Id;
        insert reasonCode; 

        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(InsurancePolicyId = testPolicyNumber.Id, Role = 'Primary', PrimaryParticipantContactId = con.Id);
        insert ipp;
            
    
        Claim c = [SELECT Id, ARC_Vendor__r.Name,ARC_Vendor__r.BillingStreet, ARC_Vendor__r.BillingCity,ARC_Vendor__r.BillingState,ARC_Vendor__r.BillingPostalCode, 
                ARC_TotalIneligibleAmount__c,ARC_TotalPaymentAmount__c,ARC_TotalPreviouslyPaidAmount__c,ARC_TotalPatientResponsibilityAmount__c,ARC_TotalDiscountAmount__c,
                ARC_Vendor__r.ARC_Provider_Tax_Id__c , ARC_Vendor__r.ARC_Provider_Name__c, ARC_MemberContact__c, ARC_ClaimNotes__c, ARC_Payment_To__c, ARC_PayToStreet__c, ARC_PayToCity__c, ARC_PayTo_State__c, ARC_PayTo_ZipCode__c,
                ARC_MemberBenefitPlan__c, ARC_ClaimTotalAmount__c, ARC_TotalAdjustedAmount__c ,ARC_TotalDeductibleAmount__c, 
                ARC_TotalCoinsuranceAmount__c, ARC_TotalCopayAmount__c, ARC_TotalAllowedAmount__c,ARC_Vendor__r.ARC_NationalProviderId__c, 
                ARC_TransactionSetControlNumber__c, LossDate, ARC_OriginalReceivedDate__c, Name,ARC_CheckRun__c ,PolicyNumber.Name FROM Claim WHERE Id =: ccpdList[0].ARC_Claim__c LIMIT 1];
        for (ClaimCoveragePaymentDetail ccpd : ccpdList) {
            ccpd.Status = 'Denied';
        }
        update ccpdList;
        c.ARC_MemberContact__c = con.Id;    
        c.ARC_Payment_To__c = 'Provider'; //Member
        c.ARC_PayToStreet__c = '2nd Avenue';
        c.ARC_PayToCity__c = 'New York';
        c.ARC_PayTo_State__c = 'NY';
        c.ARC_PayTo_ZipCode__c = '12345'; 
        c.ARC_Vendor__c = a.Id;
        c.PolicyNumberId = testPolicyNumber.Id;
        c.ARC_ParticipantPolicyParticipant__c = ipp.Id;
        c.ARC_TotalIneligibleAmount__c = 200;
        c.ARC_TotalPaymentAmount__c = 300;
        c.ARC_TotalPreviouslyPaidAmount__c =100;
        c.ARC_TotalPatientResponsibilityAmount__c = 50;
        c.ARC_TotalDiscountAmount__c = 20;
        c.ARC_ClaimTotalAmount__c = 2163.20;
        c.ARC_TotalAdjustedAmount__c = 150;
        c.ARC_TotalDeductibleAmount__c = 30;
        c.ARC_TotalCoinsuranceAmount__c = 60;
        c.ARC_TotalCopayAmount__c = 600;
        c.ARC_TotalAllowedAmount__c = 9000;
        c.ARC_TotalNetPaidAmount__c = 9000;
        c.ARC_PrimaryMemberCM__c = primaryMember.Id;
        c.ARC_Primary_Member__c = perAccCont.Id;
        c.LossDate = date.today();    
        c.Status = 'Initial';
        update c;
        c.Status = 'Manual Denied';
        c.ARC_AuditorValidation__c = 'Approved';
        c.ARC_CheckRunApproval__c = 'Approved';
        update c;
        c.ARC_CheckRun__c = checkRun.Id;
        update c;


        // Create Adjusted Claim
        
        //Create Claim + Claim Coverage Paymet Details
        List<ClaimCoveragePaymentDetail> ccpdListAdj = ARC_TestUtility.createTestCoveragePayments(2);
            
        ARC_ClaimReasonCode__c reasonCodeAdj = new ARC_ClaimReasonCode__c();
        reasonCodeAdj.ARC_ClaimCoveragePaymentDetail__c = ccpdListAdj[0].Id;
        reasonCodeAdj.ARC_ReasonCode__c = generalCode.Id;
        insert reasonCodeAdj;
    
        Claim cAdj = [SELECT Id, ARC_Vendor__r.Name,ARC_Vendor__r.BillingStreet, ARC_Vendor__r.BillingCity,ARC_Vendor__r.BillingState,ARC_Vendor__r.BillingPostalCode, 
                ARC_TotalIneligibleAmount__c,ARC_TotalPaymentAmount__c,ARC_TotalPreviouslyPaidAmount__c,ARC_TotalPatientResponsibilityAmount__c,ARC_TotalDiscountAmount__c,
                ARC_Vendor__r.ARC_Provider_Tax_Id__c , ARC_Vendor__r.ARC_Provider_Name__c, ARC_MemberContact__c, ARC_ClaimNotes__c, ARC_Payment_To__c, ARC_PayToStreet__c, ARC_PayToCity__c, ARC_PayTo_State__c, ARC_PayTo_ZipCode__c,
                ARC_MemberBenefitPlan__c, ARC_ClaimTotalAmount__c, ARC_TotalAdjustedAmount__c ,ARC_TotalDeductibleAmount__c, 
                ARC_TotalCoinsuranceAmount__c, ARC_TotalCopayAmount__c, ARC_TotalAllowedAmount__c,ARC_Vendor__r.ARC_NationalProviderId__c, 
                ARC_TransactionSetControlNumber__c, LossDate, ARC_OriginalReceivedDate__c, Name,ARC_CheckRun__c ,PolicyNumber.Name FROM Claim WHERE Id =: ccpdListAdj[0].ARC_Claim__c LIMIT 1];
        for (ClaimCoveragePaymentDetail ccpd : ccpdListAdj) {
            ccpd.Status = 'Denied';
        }
        update ccpdListAdj;
        cAdj.ARC_MemberContact__c = con.Id;    
        cAdj.ARC_Payment_To__c = 'Member';
        cAdj.ARC_PayToStreet__c = '2nd Avenue';
        cAdj.ARC_PayToCity__c = 'New York';
        cAdj.ARC_PayTo_State__c = 'NY';
        cAdj.ARC_PayTo_ZipCode__c = '12345'; 
        cAdj.ARC_Vendor__c = a.Id;
        cAdj.PolicyNumberId = testPolicyNumber.Id;
        cAdj.ARC_ParticipantPolicyParticipant__c = ipp.Id;
        cAdj.ARC_TotalIneligibleAmount__c = 200;
        cAdj.ARC_TotalPaymentAmount__c = 300;
        cAdj.ARC_TotalPreviouslyPaidAmount__c =100;
        cAdj.ARC_TotalPatientResponsibilityAmount__c = 50;
        cAdj.ARC_TotalDiscountAmount__c = 20;
        cAdj.ARC_ClaimTotalAmount__c = 2163.20;
        cAdj.ARC_TotalAdjustedAmount__c = 150;
        cAdj.ARC_TotalDeductibleAmount__c = 30;
        cAdj.ARC_TotalCoinsuranceAmount__c = 60;
        cAdj.ARC_TotalCopayAmount__c = 600;
        cAdj.ARC_TotalAllowedAmount__c = 9000;
        cAdj.ARC_TotalNetPaidAmount__c = 9000;
        cAdj.ARC_PrimaryMemberCM__c = primaryMember.Id;
        cAdj.ARC_Primary_Member__c = perAccCont.Id;
        cAdj.LossDate = date.today();
        cAdj.ARC_OriginalSMB__c = c.Id;
        cAdj.ARC_Adjust__c = true;
        cAdj.Status = 'Initial';
        update cAdj;
        cAdj.Status = 'Manual Denied';
        cAdj.ARC_AuditorValidation__c = 'Approved';
        cAdj.ARC_CheckRunApproval__c = 'Approved';
        update cAdj;
        cAdj.ARC_CheckRun__c = checkRun.Id;
        update cAdj;

            
        System.debug('checkRunId Mock' + ' ' + c.ARC_CheckRun__c);

        //Create CheckNumber Custom Setting
        ARC_XMLCounter__c checkNumberCounter = new ARC_XMLCounter__c(Name = 'ZelisCheck', ARC_CheckNumber__c = 1000);
        insert checkNumberCounter;
        //Create Counter
        ARC_XMLCounter__c xmlCounter = new ARC_XMLCounter__c(Name = 'ZelisXML', ARC_Date__c = Date.today(), ARC_Counter__c = '00.00');
        insert xmlCounter;


        /*CLAIM + Account + 	InsurancePolicy:
        SELECT Id, ARC_Payment_To__c , ARC_Vendor__r.Name,ARC_Vendor__r.BillingStreet, ARC_Vendor__r.BillingCity,ARC_Vendor__r.BillingState,ARC_Vendor__r.BillingPostalCode, 
        ARC_TotalIneligibleAmount__c,ARC_TotalPaymentAmount__c,ARC_TotalPreviouslyPaidAmount__c,ARC_TotalPatientResponsibilityAmount__c,ARC_TotalDiscountAmount__c,
        ARC_Vendor__r.ARC_Provider_Tax_Id__c , ARC_Vendor__r.ARC_Provider_Name__c, ARC_MemberContact__c, ARC_ClaimNotes__c, 
        ARC_MemberBenefitPlan__c, ARC_ClaimTotalAmount__c, ARC_TotalAdjustedAmount__c ,ARC_TotalDeductibleAmount__c, 
        ARC_TotalCoinsuranceAmount__c, ARC_TotalCopayAmount__c, ARC_TotalAllowedAmount__c,ARC_Vendor__r.ARC_NationalProviderId__c, 
        ARC_TransactionSetControlNumber__c, LossDate, ARC_OriginalReceivedDate__c, Name, PolicyNumber.Name FROM Claim WHERE ARC_CheckRun__c = :checkRunId');
        */
    }


    @isTest
    static void ARC_ZelisClaimsFileBatchTest() {
        ARC_CheckRun__c checkRun = [SELECT Id FROM ARC_CheckRun__c LIMIT 1];
        System.debug('checkRunId Test1' + ' ' + checkRun.Id);
        Set<Id> clmIds = new Set<Id>();
        List<Claim> claims = [SELECT Id FROM Claim WHERE ARC_CheckRun__c =: checkRun.Id];
        for (Claim clm : claims) clmIds.add(clm.Id);

        Test.startTest();
        ARC_ZelisClaimsFileBatch.runZelisBatch(new List<Id>{ checkRun.Id });
        ARC_ZelisClaimsFileBatch batch = new ARC_ZelisClaimsFileBatch(clmIds, true, checkrun.Id, false);
        Database.executeBatch(batch);
        Test.stopTest();
    }
}