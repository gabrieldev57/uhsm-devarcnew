@isTest
public class ARC_ClaimTriggersHandlerTest {
    @TestSetup
    static void makeData(){
        Id idRARC = Schema.SObjectType.vlocity_ins__VlocityCode__c.getRecordTypeInfosByName().get('RARC').getRecordTypeId(); 
        vlocity_ins__VlocityCode__c generalInfCode = new vlocity_ins__VlocityCode__c(Name = 'HT904', RecordTypeId = idRARC, ARC_Status__c = 'Informational');
        insert generalInfCode;
        //Create CheckNumber Custom Setting
        ARC_XMLCounter__c checkNumberCounter = new ARC_XMLCounter__c(Name='ZelisCheck', ARC_CheckNumber__c=1000);
        insert checkNumberCounter;
        //Create Counter
        ARC_XMLCounter__c xmlCounter = new ARC_XMLCounter__c(Name='ZelisXML',ARC_Date__c=Date.today(),ARC_Counter__c='00.00');
        insert xmlCounter;
        
        
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Group').getRecordTypeId();
        Id personAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account acc = new Account(Name = 'TestAccountName',BillingState='KS', BillingCity='Coffeyville', BillingPostalCode ='67337', BillingStreet='412 Penn Street', vlocity_ins__Email__c = randomEmail(),RecordTypeId=accRecordTypeId,ARC_NationalProviderId__c='9876543210');
        insert acc;
        
        Account personAcc = new Account(Firstname='testclass', Lastname='testckass', RecordTypeId=personAccRTId, BillingStreet='123 Kansas Street', BillingPostalCode='11220', BillingCity='NY', BillingCountry='US',BillingState='KS');
        insert personAcc;
        Contact perAccCont = [SELECT Id, Account.BillingStreet FROM Contact WHERE AccountId =: personAcc.Id LIMIT 1]; 

        
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(Name='censusTest',vlocity_ins__GroupId__c=acc.Id,ARC_PrimaryAccount__c=acc.Id);
        insert census;
        
        vlocity_ins__GroupCensusMember__c primaryMember = new vlocity_ins__GroupCensusMember__c(
                Name = 'Test Primary Member',
                vlocity_ins__Email__c = randomEmail(),
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
        List<ClaimCoveragePaymentDetail> clilist = ARC_TestUtility.createTestCoveragePayments(3);
        clilist[0].ARC_Mod1__c = '123456789';
        clilist[0].ARC_Mod2__c = '123456789';
        clilist[0].ARC_Mod3__c = '123456789';
        clilist[0].ARC_Mod4__c = '123456789';
        clilist[0].ARC_Allowed__c = 1000;
        clilist[0].ARC_Copay__c = 100.5;
        clilist[0].ARC_Deductible__c = 300;
        clilist[0].ARC_Coinsurance__c = 150;
        clilist[0].ClaimedAmount = 200;
        clilist[0].ARC_DateOfService__c = date.today(); 
        clilist[0].ARC_RevenueCode__c = 'test';
        clilist[0].ARC_Quantity__c = 2;
        clilist[0].ARC_ProcedureCode__c = testCode.Id;
        
        update clilist[0];
        ARC_ClaimReasonCode__c cReasonCodeTest = new ARC_ClaimReasonCode__c();
        cReasonCodeTest.ARC_ClaimCoveragePaymentDetail__c = clilist[0].Id;
        cReasonCodeTest.ARC_ReasonCode__c = testCode.Id;
        insert cReasonCodeTest;

        Product2 prod = new Product2();
        prod.Name = 'UHSM Gold $5K';
        prod.ProductCode = 'PROG_UHSMGold';
        prod.vlocity_ins__Type__c = 'Medical';
        insert prod;

        Claim c = [SELECT Id FROM Claim WHERE Id =: clilist[0].ARC_Claim__c];
        InsurancePolicy p = new InsurancePolicy();
        p.Name = 'Test Policy';
        p.NameInsuredId = acc.Id;
        p.ProductId = prod.Id;
        insert p;

        ClaimPaymentSummary cps = new ClaimPaymentSummary();
        cps.Name = 'testcps';
        cps.ARC_SMB_Item__c = clilist[0].Id;
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
        c.ARC_Payment_To__c = 'Provider';
        c.Status = 'Initial';
        c.ARC_AuditorValidation__c = 'Approved';
        c.ARC_PrimaryMemberCM__c = primaryMember.Id;
        c.ARC_Primary_Member__c = perAccCont.Id;
        c.ARC_ParticipantPolicyParticipant__c = ipp.Id;
        c.ARC_Refund__c = false;
        update c;
       /* c.ARC_CheckRun__c = checkRunTest.Id;
        update c;*/
        // comment
    }

    @isTest
    static void sumNetPaidToCheckrunTestOne() {
        Account a = new Account(FirstName='Account', LastName='Test', BillingStreet='2nd Avenue', BillingState='NY', BillingPostalCode='12345', BillingCity='New York', ARC_Provider_Name__c='Ins Provider',ARC_Provider_Tax_Id__c=1234567, ARC_NationalProviderId__c='23322');
        insert a;
    
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Group').getRecordTypeId();
        Account acc = new Account(Name = 'TestAccountName',BillingState='KS',vlocity_ins__Email__c='asdss@asd.com',RecordTypeId=accRecordTypeId);
        insert acc;
    
        
        Contact con = new Contact();
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(Name='censusTest',vlocity_ins__GroupId__c=acc.Id,ARC_PrimaryAccount__c=acc.Id);
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

        List<Claim> cList = new List<Claim>();
        cList.add(new Claim(Name='Test sumNetPaidToCheckrunTestOne 1'));
        cList.add(new Claim(Name='Test sumNetPaidToCheckrunTestOne 2'));
        cList.add(new Claim(Name='Test sumNetPaidToCheckrunTestOne 3'));
        cList.add(new Claim(Name='Test sumNetPaidToCheckrunTestOne 4'));
        ARC_CheckRun__c checkRun = new ARC_CheckRun__c(ARC_Status__c='Open');
        insert checkRun;

        cList[0].ARC_TotalNetPaidAmount__c = 100;
        cList[1].ARC_TotalNetPaidAmount__c = 200;
        cList[2].ARC_TotalNetPaidAmount__c = 300;
        cList[3].ARC_TotalNetPaidAmount__c = 400;
        
        for (Claim clm : cList) {
            clm.ARC_MemberContact__c = con.Id;
            clm.ARC_Payment_To__c = 'Member';
            clm.ARC_AuditorValidation__c = 'Approved';
        }
        insert cList;
        for (Claim clm : cList) {
            clm.Status = 'Manual Approved';            
        }
        update cList;
        cList[0].ARC_CheckRunApproval__c =cList[1].ARC_CheckRunApproval__c =cList[2].ARC_CheckRunApproval__c =cList[3].ARC_CheckRunApproval__c = 'Approved';
        cList[0].ARC_CheckRun__c =cList[1].ARC_CheckRun__c =cList[2].ARC_CheckRun__c =cList[3].ARC_CheckRun__c = checkRun.Id;
        Test.startTest();
            update cList;
        Test.stopTest();
        ARC_CheckRun__c checkRunUpdated = [SELECT ARC_TotalPaid__c FROM ARC_CheckRun__c WHERE Id = :checkRun.Id];
        System.assertEquals(1000.00,checkRunUpdated.ARC_TotalPaid__c);
    }   

    @isTest
    static void sumNetPaidToCheckrunTestTwo() {

        Account a = new Account(FirstName='Account', LastName='Test', BillingStreet='2nd Avenue', BillingState='NY', BillingPostalCode='12345', BillingCity='New York', ARC_Provider_Name__c='Ins Provider',ARC_Provider_Tax_Id__c=1234567, ARC_NationalProviderId__c='23322');
        insert a;
    
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Group').getRecordTypeId();
        Account acc = new Account(Name = 'TestAccountName',BillingState='KS',vlocity_ins__Email__c='asdss@asd.com',RecordTypeId=accRecordTypeId);
        insert acc;
    
        
        Contact con = new Contact();
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(Name='censusTest',vlocity_ins__GroupId__c=acc.Id,ARC_PrimaryAccount__c=acc.Id);
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

        List<Claim> cList = new List<Claim>();
        cList.add(new Claim(Name='sumNetPaidToCheckrunTestTwo 1'));
        cList.add(new Claim(Name='sumNetPaidToCheckrunTestTwo 2'));
        ARC_CheckRun__c checkRun = new ARC_CheckRun__c(ARC_Status__c='Open');
        insert checkRun;
        for (Claim clm : cList) {
            clm.ARC_Payment_To__c = 'Member';
            clm.ARC_MemberContact__c = con.Id;
            clm.ARC_AuditorValidation__c = 'Approved';
        }
        insert cList;
        for (Claim clm : cList) {
            clm.Status = 'Manual Approved';            
        }
        update cList;
        cList[0].ARC_CheckRunApproval__c = 'Approved';
        cList[1].ARC_CheckRunApproval__c = 'Approved';
        cList[0].ARC_CheckRun__c = checkRun.Id;
        cList[1].ARC_CheckRun__c = checkRun.Id;
        
        
        Test.startTest();
            cList[0].ARC_TotalNetPaidAmount__c = 100;
            cList[1].ARC_TotalNetPaidAmount__c = 200;
            update cList[0];
            update cList[1];
        Test.stopTest();
        ARC_CheckRun__c checkRunUpdated = [SELECT ARC_TotalPaid__c FROM ARC_CheckRun__c WHERE Id = :checkRun.Id];
        System.assertEquals(300.00 ,checkRunUpdated.ARC_TotalPaid__c);
    }   

    @isTest
    static void preventCloseIfunpaidItems(){
        Claim c = [SELECT Id,ARC_VRHelper__c,ARC_MemberXMLFieldsCompleted__c, ARC_PrimaryMemberCM__r.vlocity_ins__ContactId__r.Account.BillingStreet,
        ARC_PrimaryMemberCM__r.vlocity_ins__ContactId__r.Account.BillingPostalCode, ARC_PrimaryMemberCM__r.vlocity_ins__ContactId__r.Account.BillingState,
        ARC_PrimaryMemberCM__r.vlocity_ins__ContactId__r.Account.BillingCity, ARC_PayToStreet__c, ARC_PayToCity__c, ARC_PayTo_State__c, ARC_PayTo_ZipCode__c
        FROM Claim];
        
        c.ARC_AuditorValidation__c = 'Approved';
        System.debug('ARC_PayToStreet__c: ' + c.ARC_PayToStreet__c);
        System.debug('ARC_PayToCity__c: ' + c.ARC_PayToCity__c);
        System.debug('ARC_PayTo_State__c: ' + c.ARC_PayTo_State__c);
        System.debug('ARC_PayTo_ZipCode__c: ' + c.ARC_PayTo_ZipCode__c);
        update c;
        List<ClaimCoveragePaymentDetail> cliList = [SELECT Id, ARC_Claim__c, Status, ClaimPaymentSummaryId FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: c.Id];
        
        ClaimPaymentSummary cps = new ClaimPaymentSummary(Name = 'ItemPay', ARC_SMB_Item__c =  cliList[2].Id, ClaimId = c.Id);
        insert cps;
        clilist[0].Status = 'Denied'; 
        clilist[0].ARC_Copay__c = 0;
        clilist[0].ARC_Deductible__c = 0;
        clilist[0].ARC_Coinsurance__c = 0;
        cliList[1].Status = 'Denied';
        clilist[1].ARC_Copay__c = 0;
        clilist[1].ARC_Deductible__c = 0;
        clilist[1].ARC_Coinsurance__c = 0;
        cliList[2].Status = 'Denied';
        update cliList;

        Test.startTest();
            c.Status ='Manual Denied';
            update c;
        Test.stopTest();

        Claim cUpdated = [SELECT Id, Status,ARC_VRHelper__c,ARC_MemberXMLFieldsCompleted__c FROM Claim WHERE Id =:c.Id];

        System.assertEquals('Manual Denied',cUpdated.Status);
    }

    @isTest
    static void testUpdateNameManualSMBWhenInsert() {
        Claim clm = new Claim();
        clm.Name = 'Old Name';
        clm.ARC_RovType__c = 'Paper Claim';

        Test.startTest();
            clm.ARC_Paper_Claim_Type__c = 'Adjustments';
            insert clm;
        Test.stopTest();

        Claim insertedClaim = [SELECT Id, Name, ARC_Paper_Claim_Type__c FROM Claim WHERE Id =:clm.Id LIMIT 1];
        String expectedName = 'WS2';
        System.assertEquals(expectedName, insertedClaim.Name.substring(insertedClaim.Name.length() - 3));
    }

    @isTest
    static void testUpdateNameManualSMBWhenUpdate() {
        Claim clm = new Claim();
        clm.Name = 'Old Name';
        clm.ARC_RovType__c = 'Paper Claim';
        clm.ARC_Paper_Claim_Type__c = 'Appeals';
        insert clm;
        Claim insertedClaim = [SELECT Id, Name, ARC_Paper_Claim_Type__c FROM Claim WHERE Id =:clm.Id LIMIT 1];

        Test.startTest();
            insertedClaim.ARC_Paper_Claim_Type__c = 'Service Exceptions';
            update insertedClaim;
        Test.stopTest();

        Claim updatedClaim = [SELECT Id, Name, ARC_Paper_Claim_Type__c FROM Claim WHERE Id =:clm.Id LIMIT 1];

        String expectedName = 'WS3';
        System.assertEquals(expectedName, updatedClaim.Name.substring(updatedClaim.Name.length() - 3));
    }

    @isTest
    static void testUpdateNameManualSMBManyTimes() {
        Claim clm = new Claim();
        clm.Name = 'Old Name';
        clm.ARC_RovType__c = 'Paper Claim';
        clm.ARC_Paper_Claim_Type__c = 'Offboarding Exceptions';
        insert clm;
        Claim insertedClaim = [SELECT Id, Name, ARC_Paper_Claim_Type__c FROM Claim WHERE Id =:clm.Id LIMIT 1];
        insertedClaim.ARC_Paper_Claim_Type__c = 'AIDD';
        update insertedClaim;
        Claim firstUpdatedClaim = [SELECT Id, Name, ARC_Paper_Claim_Type__c FROM Claim WHERE Id =:insertedClaim.Id LIMIT 1];
        firstUpdatedClaim.ARC_Paper_Claim_Type__c = 'SMART';
        update firstUpdatedClaim;
        Claim secondUpdatedClaim = [SELECT Id, Name, ARC_Paper_Claim_Type__c FROM Claim WHERE Id =:firstUpdatedClaim.Id LIMIT 1];
        secondUpdatedClaim.ARC_Paper_Claim_Type__c = 'Member Reimbursement';
        update secondUpdatedClaim;
        Claim thirdUpdatedClaim = [SELECT Id, Name, ARC_Paper_Claim_Type__c FROM Claim WHERE Id =:secondUpdatedClaim.Id LIMIT 1];
        
        Test.startTest();
            thirdUpdatedClaim.ARC_Paper_Claim_Type__c = 'Manual Processing Pricing';
            update thirdUpdatedClaim;
        Test.stopTest();
        Claim lastUpdateClaim = [SELECT Id, Name, ARC_Paper_Claim_Type__c FROM Claim WHERE Id =:thirdUpdatedClaim.Id LIMIT 1];
        String expectedName = 'WS8';
        System.assertEquals(expectedName, lastUpdateClaim.Name.substring(lastUpdateClaim.Name.length() - 3));
    }

    @isTest
    static void testUpdateNameManualSMBInsertWithoutType() {
        Claim clm = new Claim();
        clm.Name = 'Old Name';
        clm.ARC_RovType__c = 'Paper Claim';

        Test.startTest();
            insert clm;
        Test.stopTest();
        Claim insertedClaim = [SELECT Id, Name, ARC_Paper_Claim_Type__c FROM Claim WHERE Id =:clm.Id LIMIT 1];
        String expectedName = '- M';
        System.assertEquals(expectedName, insertedClaim.Name.substring(insertedClaim.Name.length() - 3));
    }

    @IsTest
    static void testQuickPayAAUpdatePendingReviewSMB() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        InsurancePolicy testPolicyNumber = new InsurancePolicy(Name = '11', NameInsuredId = testAccount.Id, ARC_GroupAccount__c = testAccount.Id);
        insert testPolicyNumber;
        
        Claim testClaim = new Claim(Name = 'Something', PolicyNumberId = testPolicyNumber.Id);
        insert testClaim;

        ClaimCoverage cc = new ClaimCoverage();
        cc.Name = 'Not covered';
        cc.ClaimId = testClaim.Id;
        cc.InternalReserveMode = 'CoverageReserve';
        insert cc;

        ClaimCoveragePaymentDetail testLineItem = new ClaimCoveragePaymentDetail(ARC_Claim__c = testClaim.Id, Name = '1', ClaimCoverageId = cc.Id);
        insert testLineItem;

        Test.startTest();
        testClaim.ARC_QwikPay__c = true;
        update testClaim;
        Test.stopTest();

        testClaim = [SELECT Id, Status, ARC_AreItemsClosed__c FROM Claim WHERE Id = :testClaim.Id];
        testLineItem = [SELECT Id, Status FROM ClaimCoveragePaymentDetail WHERE Id = :testLineItem.Id];
        System.assertEquals('Initial', testClaim.Status, 'Claim should be initial since the items need to be modified');
        System.assertEquals('Informational', testLineItem.Status, 'Line item status should be Informational');
    }

    @IsTest
    static void testQuickPayAAUpdateApprovedSMB() {
        Claim c = [SELECT Id,ARC_QwikPay__c FROM Claim];

        Test.startTest();
        c.ARC_QwikPay__c = true;
        update c;
        Test.stopTest();

        Claim testClaim = [SELECT Id, Status, ARC_AreItemsClosed__c FROM Claim WHERE Id = :c.Id];
        System.assertEquals('Initial', testClaim.Status, 'Claim should be initial');
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

    @IsTest
    static void testRefundCalculation() {
        Claim c = [SELECT Id,ARC_Refund__c FROM Claim];

        Test.startTest();
        c.ARC_Refund__c = true;
        c.ARC_RefundAmount__c = 5;
        update c;
        Test.stopTest();
    }
    
    @isTest
    static void testExtractClaimSubmitter() {
        List<Claim> claims = new List<Claim>{
            new Claim(
                Name = 'Missing Key',
                ARC_SubmitterJSON__c = '{ "SomeOtherKey": "SomeValue" }'
            ),
            new Claim(
                Name = 'Zelis Key',
                ARC_SubmitterJSON__c = '{ "SubmitterName.ResponseContactLastorOrganizationName_03": "ZELIS" }'
            ),
            new Claim(
                Name = 'Optum Key',
                ARC_SubmitterJSON__c = '{ "SubmitterName.ResponseContactLastorOrganizationName_03": "OPTUM" }'
            )
        };
    
        insert claims;
    
        // Build map of expected values by ID
        Map<Id, String> expectedById = new Map<Id, String>();
        for (Claim c : claims) {
            if (c.Name == 'Missing Key') {
                expectedById.put(c.Id, null);
            } else if (c.Name == 'Zelis Key') {
                expectedById.put(c.Id, 'ZELIS');
            } else if (c.Name == 'Optum Key') {
                expectedById.put(c.Id, 'OPTUM');
            }
        }
    
        // Re-query the claims after trigger execution
        List<Claim> updatedClaims = [
            SELECT Id, Name, Claim_Submitter__c
            FROM Claim
            WHERE Id IN :expectedById.keySet()
        ];
    
        // Assert each value
        for (Claim c : updatedClaims) {
            System.assertEquals(
                expectedById.get(c.Id),
                c.Claim_Submitter__c,
                'Unexpected value for claim: ' + c.Name + ' (Id: ' + c.Id + ')'
            );
        }
    }
}