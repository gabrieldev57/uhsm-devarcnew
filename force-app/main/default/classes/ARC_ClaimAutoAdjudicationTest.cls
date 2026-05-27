@IsTest
public with sharing class ARC_ClaimAutoAdjudicationTest {
    @TestSetup
    static void mockData() {
        Id idRARC = Schema.SObjectType.vlocity_ins__VlocityCode__c.getRecordTypeInfosByName().get('RARC').getRecordTypeId(); 
        Id idCPT = Schema.SObjectType.vlocity_ins__VlocityCode__c.getRecordTypeInfosByName().get('CPT').getRecordTypeId();

        List<vlocity_ins__VlocityCode__c> codesList = new List<vlocity_ins__VlocityCode__c>();

        vlocity_ins__VlocityCode__c hsZeroCode = new vlocity_ins__VlocityCode__c(Name = 'HS900', RecordTypeId = idRARC, ARC_Status__c = 'Informational');
        codesList.add(hsZeroCode);
        vlocity_ins__VlocityCode__c hsOneCode = new vlocity_ins__VlocityCode__c(Name = 'HS901', RecordTypeId = idRARC, ARC_Status__c = 'Informational');
        codesList.add(hsOneCode);
        vlocity_ins__VlocityCode__c htTwoCode = new vlocity_ins__VlocityCode__c(Name = 'HT902', RecordTypeId = idRARC, ARC_Status__c = 'Informational');
        codesList.add(htTwoCode);
        vlocity_ins__VlocityCode__c phCode = new vlocity_ins__VlocityCode__c(Name = 'PH900', RecordTypeId = idRARC, ARC_Status__c = 'Informational');
        codesList.add(phCode);
        vlocity_ins__VlocityCode__c eligOneCode = new vlocity_ins__VlocityCode__c(Name = 'ELIG01', RecordTypeId = idRARC, ARC_Status__c = 'Denied');
        codesList.add(eligOneCode);
        vlocity_ins__VlocityCode__c eligTwoCode = new vlocity_ins__VlocityCode__c(Name = 'ELIG02', RecordTypeId = idRARC, ARC_Status__c = 'Denied');
        codesList.add(eligTwoCode);
        vlocity_ins__VlocityCode__c aSixCode = new vlocity_ins__VlocityCode__c(Name = 'A0006', RecordTypeId = idRARC, ARC_Status__c = 'Denied');
        codesList.add(aSixCode);
        vlocity_ins__VlocityCode__c threeHoundredFiveCode = new vlocity_ins__VlocityCode__c(Name = '3075F', RecordTypeId = idCPT);
        codesList.add(threeHoundredFiveCode);
        vlocity_ins__VlocityCode__c threeHoundredNineCode = new vlocity_ins__VlocityCode__c(Name = '3079F', RecordTypeId = idCPT);
        codesList.add(threeHoundredNineCode);
        vlocity_ins__VlocityCode__c htFourCode = new vlocity_ins__VlocityCode__c(Name = 'HT904', RecordTypeId = idRARC, ARC_Status__c = 'Informational');
        codesList.add(htFourCode);
        insert codesList;

        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Group').getRecordTypeId();
        Id personAccRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        
        Account acc = new Account(Name = 'Pepito' , BillingState='KS', BillingCity = 'Frankfort', BillingStreet = '123 Kansas Street', BillingPostalCode = '60423', vlocity_ins__Email__c = 'asdss@asd.com',RecordTypeId = accRecordTypeId,ARC_NationalProviderId__c='9876543210');
        insert acc;

        Account vendorAcc = new Account(FirstName='Account', LastName='Test', BillingStreet='2nd Avenue', BillingState='NY', BillingPostalCode='12345', BillingCity='New York', ARC_Provider_Name__c='Ins Provider',ARC_Provider_Tax_Id__c=1234567, ARC_NationalProviderId__c='23322');
        insert vendorAcc;

        Account personAcc = new Account(Firstname='testclass', Lastname='testckass', RecordTypeId=personAccRTId, BillingStreet='123 Kansas Street', BillingPostalCode='11220', BillingCity='NY', BillingCountry='US',BillingState='KS');
        insert personAcc;
        Contact perAccCont = [SELECT Id, Account.BillingStreet FROM Contact WHERE AccountId =: personAcc.Id LIMIT 1]; 


        Contact con = new Contact();
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(Name='censusTest', vlocity_ins__GroupId__c = acc.Id, ARC_PrimaryAccount__c = acc.Id);
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
        vlocity_ins__GroupCensusMember__c dependent = new vlocity_ins__GroupCensusMember__c(
            Name = 'Test Dependent Member',
            vlocity_ins__Email__c = 'asdsd@asd.com',
            vlocity_ins__CensusId__c = census.Id,
            vlocity_ins__IsPrimaryMember__c = false,
            vlocity_ins__Gender__c = 'Male',
            vlocity_ins__SocialSecurityNumber__c = '123456789',
            vlocity_ins__Birthdate__c = date.today().addYears(-65).toStartOfMonth(),
            vlocity_ins__RelatedCensusMemberId__c = primaryMember.Id,
            ARC_PhysicalAddressState__c = 'KS',
            ARC_PhysicalAddressStreet__c = 'E Lincoln St',
            ARC_PhysicalAddressCity__c = 'Wichita',
            ARC_Phone__c = '3165244400',
            ARC_PhysicalAddressZipCode__c = '67209',
            ARC_ActiveMember__c = true,
            vlocity_ins__ContactId__c = con.Id);
        insert dependent;
        con.ARC_CensusMember__c = dependent.Id; 
        update con; 

        Contract contractt = new Contract();
        contractt.ContractTerm = 12;
        contractt.AccountId = acc.Id;
        contractt.ARC_Signer_Email__c = 'testEmail1@email.com';
        contractt.ARC_EffectiveDate__c = date.today().addDays(-200);
        contractt.ARC_Inactive_Date__c = date.today().addDays(165);
        insert contractt;

        InsurancePolicy testPolicyNumber = new InsurancePolicy(Name = '11', NameInsuredId = acc.Id, ARC_GroupAccount__c = acc.Id, ARC_Contract__c = contractt.Id);
        insert testPolicyNumber;
        
        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(InsurancePolicyId = testPolicyNumber.Id, Role = 'Primary', PrimaryParticipantContactId = con.Id );
        insert ipp;


        Claim testClaim = new Claim(
            Name = 'Something', 
            PolicyNumberId = testPolicyNumber.Id, 
            ARC_CCToCompare__c = 'Something',
            Status = 'Initial',
            ARC_Payment_To__c = 'Provider',
            ARC_PayToStreet__c = 'Street',
            ARC_PayToCity__c = 'City',
            ARC_PayTo_State__c = 'ST',
            ARC_PayTo_ZipCode__c = '12345', 
            ARC_MemberContact__c = con.Id,
            ARC_ParticipantPolicyParticipant__c = ipp.Id,
            ARC_Vendor__c = vendorAcc.Id,
            ARC_PrimaryMemberCM__c = primaryMember.Id,
            ARC_Primary_Member__c = con.Id);
        insert testClaim;

        ClaimCoverage cc = new ClaimCoverage();
        cc.Name = 'Not covered';
        cc.ClaimId = testClaim.Id;
        cc.InternalReserveMode = 'CoverageReserve';
        insert cc;
        ClaimCoveragePaymentDetail testLineItem = new ClaimCoveragePaymentDetail(ARC_Claim__c = testClaim.Id, Name = '1', ClaimCoverageId = cc.Id, ARC_Allowed__c = 100 );
        insert testLineItem;
    }

    @IsTest
    static void testAAClaimHET() {

        List<Claim> claimsForAA = [SELECT Id, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c, 
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r)
         FROM Claim];
        claimsForAA[0].ARC_NTE837IBNoteSegment__c = 'something##HET';

        update claimsForAA;
        List<Id> claimIds = new List<Id>();
        for (Claim claim : claimsForAA) {
            claimIds.add(claim.Id);
        }

        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        // Retrieve the updated claims for assertions
        List<Claim> updatedClaims = [SELECT Id, Status, ARC_AutoAdjudicationReview__c, (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r)
                                     FROM Claim
                                     WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Name, Status, ARC_ProcedureCode__c, ARC_Allowed__c, ARC_Claim__c FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: updatedClaims[0].Id];

        // Perform assertions to verify the expected results
        //System.assertEquals(expectedStatus, updatedClaims[0].Status);
        System.assertEquals('Informational', lineItems[0].Status);
        System.assertEquals('Code HS900 added to line items', updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }

    @IsTest
    static void testAAClaimGJ5() {
        
        List<Claim> claimsForAA = [SELECT Id,ARC_PayToStreet__c, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c, 
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r)
         FROM Claim];
        claimsForAA[0].ARC_NTE837IBNoteSegment__c = 'something##GJ5';

        update claimsForAA;
        List<Id> claimIds = new List<Id>();
        for (Claim claim : claimsForAA) {
            claimIds.add(claim.Id);
        }

        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        // Retrieve the updated claims for assertions
        List<Claim> updatedClaims = [SELECT Id, Status, ARC_AutoAdjudicationReview__c, (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r)
                                     FROM Claim
                                     WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Name, Status, ARC_ProcedureCode__c, ARC_Allowed__c, ARC_Claim__c FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: updatedClaims[0].Id];

        // Perform assertions to verify the expected results
        //System.assertEquals(expectedStatus, updatedClaims[0].Status);
        System.assertEquals('Informational', lineItems[0].Status);
        System.assertEquals('Code PH900 added to line items', updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }
    @IsTest
    static void testAAClaimElig01() {

        List<Claim> claimsForAA = [SELECT Id, ARC_Vendor__c,ARC_PayTo_ZipCode__c,ARC_PayTo_State__c,ARC_PayToCity__c,ARC_PayToStreet__c, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c,
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r)
         FROM Claim];

        claimsForAA[0].ARC_DOSTo__c = claimsForAA[0].PolicyNumber.ARC_EffectiveDate__c.addDays(-10);
        update claimsForAA;

        List<Id> claimIds = new List<Id>();
        for (Claim claim : claimsForAA) {
            claimIds.add(claim.Id);
        }

        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        List<Claim> updatedClaims = [SELECT Id, Status, ARC_AutoAdjudicationReview__c FROM Claim WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Status FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: updatedClaims[0].Id];

        System.assertEquals('Denied', lineItems[0].Status);
        System.assertEquals('AA Denied', updatedClaims[0].Status);
        System.assertEquals('SMB DOS before Policy Effective Date', updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }

    @IsTest
    static void testAAClaimElig02() {

        List<Claim> claimsForAA = [SELECT Id, ARC_Vendor__c,ARC_PayTo_ZipCode__c,ARC_PayTo_State__c,ARC_PayToCity__c,ARC_PayToStreet__c, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c,
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r)
         FROM Claim];

        claimsForAA[0].ARC_DOSFrom__c = claimsForAA[0].PolicyNumber.ARC_ExpirationDate__c.addDays(10);
        update claimsForAA;

        List<Id> claimIds = new List<Id>();
        for (Claim claim : claimsForAA) {
            claimIds.add(claim.Id);
        }

        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        List<Claim> updatedClaims = [SELECT Id, Status, ARC_AutoAdjudicationReview__c FROM Claim WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Status FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: updatedClaims[0].Id];

        System.assertEquals('Denied', lineItems[0].Status);
        System.assertEquals('AA Denied', updatedClaims[0].Status);
        System.assertEquals('SMB DOS after Policy Expiration Date', updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }
    @IsTest
    static void testAADuplicateClm() {
        
        List<Claim> claimsForAA = [SELECT Id, ARC_Vendor__c,ARC_PayTo_ZipCode__c,ARC_PayTo_State__c,ARC_PayToCity__c,ARC_PayToStreet__c, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c, 
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r)
         FROM Claim];

        claimsForAA[0].ARC_Duplicate__c = true;
        update claimsForAA;

        List<Id> claimIds = new List<Id>();
        for (Claim claim : claimsForAA) {
            claimIds.add(claim.Id);
        }

        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        // Retrieve the updated claims for assertions
        List<Claim> updatedClaims = [SELECT Id, Status, ARC_AutoAdjudicationReview__c, (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r)
                                     FROM Claim
                                     WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Name, Status, ARC_ProcedureCode__c, ARC_Allowed__c, ARC_Claim__c FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: updatedClaims[0].Id];

        // Perform assertions to verify the expected results
        System.assertEquals('Denied', lineItems[0].Status);
        System.assertEquals('AA Denied', updatedClaims[0].Status);
        System.assertEquals('Duplicate SMB', updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }

    @IsTest
    static void testAAClaimHES() {

        List<Claim> claimsForAA = [SELECT Id, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c, 
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r)
         FROM Claim];
        claimsForAA[0].ARC_NTE837IBNoteSegment__c = 'something##HES';

        update claimsForAA;
        List<Id> claimIds = new List<Id>();
        for (Claim claim : claimsForAA) {
            claimIds.add(claim.Id);
        }

        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        // Retrieve the updated claims for assertions
        List<Claim> updatedClaims = [SELECT Id, Status, ARC_AutoAdjudicationReview__c, (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r)
                                     FROM Claim
                                     WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Name, Status, ARC_ProcedureCode__c, ARC_Allowed__c, ARC_Claim__c FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: updatedClaims[0].Id];

        //System.assertEquals(expectedStatus, updatedClaims[0].Status);
        System.assertEquals('Informational', lineItems[0].Status);
        System.assertEquals('Code HS901 added to line items', updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }

    @IsTest
    static void testAAClaimHEU() {

        List<Claim> claimsForAA = [SELECT Id, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c,
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r)
         FROM Claim];
        claimsForAA[0].ARC_NTE837IBNoteSegment__c = 'something##HEU';

        update claimsForAA;
        List<Id> claimIds = new List<Id>();
        for (Claim claim : claimsForAA) {
            claimIds.add(claim.Id);
        }

        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        List<Claim> updatedClaims = [SELECT Id, Status, ARC_AutoAdjudicationReview__c FROM Claim WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Status, ARC_ProcedureCode__c, ARC_Allowed__c FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: updatedClaims[0].Id];

        System.assertEquals('Informational', lineItems[0].Status);
        System.assertEquals('Code HT902 added to line items', updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }

    // --- Optum plain-text NTE format tests ---

    @IsTest
    static void testAAClaimOptum140Pricing() {
        List<Claim> claimsForAA = [SELECT Id, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c,
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r) FROM Claim];
        claimsForAA[0].ARC_NTE837IBNoteSegment__c = '140 Pricing - Medicare'; // 140 Pricing → HS900
        update claimsForAA;

        List<Id> claimIds = new List<Id>{ claimsForAA[0].Id };
        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        List<Claim> updatedClaims = [SELECT Id, ARC_AutoAdjudicationReview__c FROM Claim WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Status FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claimIds[0]];
        System.assertEquals('Informational', lineItems[0].Status);
        System.assertEquals('Code HS900 added to line items', updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }

    @IsTest
    static void testAAClaimOptumA1Exact() {
        List<Claim> claimsForAA = [SELECT Id, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c,
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r) FROM Claim];
        claimsForAA[0].ARC_NTE837IBNoteSegment__c = 'A1';
        update claimsForAA;

        List<Id> claimIds = new List<Id>{ claimsForAA[0].Id };
        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        List<Claim> updatedClaims = [SELECT Id, ARC_AutoAdjudicationReview__c FROM Claim WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Status FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claimIds[0]];
        System.assertEquals('Informational', lineItems[0].Status);
        System.assertEquals('Code PH900 added to line items', updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }

    @IsTest
    static void testAAClaimOptumA1Space() {
        List<Claim> claimsForAA = [SELECT Id, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c,
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r) FROM Claim];
        claimsForAA[0].ARC_NTE837IBNoteSegment__c = 'A1 Multiplan repricing';
        update claimsForAA;

        List<Id> claimIds = new List<Id>{ claimsForAA[0].Id };
        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        List<Claim> updatedClaims = [SELECT Id, ARC_AutoAdjudicationReview__c FROM Claim WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Status FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claimIds[0]];
        System.assertEquals('Informational', lineItems[0].Status);
        System.assertEquals('Code PH900 added to line items', updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }

    @IsTest
    static void testAAClaimOptumA1CollisionNoAdjudication() {
        // 'A10' must NOT match PH900 — validates the length-2 / startsWith-space guard
        List<Claim> claimsForAA = [SELECT Id, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c,
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r) FROM Claim];
        claimsForAA[0].ARC_NTE837IBNoteSegment__c = 'A10';
        update claimsForAA;

        List<Id> claimIds = new List<Id>{ claimsForAA[0].Id };
        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        List<Claim> updatedClaims = [SELECT Id, ARC_AutoAdjudicationReview__c FROM Claim WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Status FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claimIds[0]];
        System.assertNotEquals('Informational', lineItems[0].Status);
        System.assertEquals(null, updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }

    @IsTest
    static void testAAClaimOptum120Pricing() {
        List<Claim> claimsForAA = [SELECT Id, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c,
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r) FROM Claim];
        claimsForAA[0].ARC_NTE837IBNoteSegment__c = '120 Pricing - Medicare'; // 120 Pricing → HS901
        update claimsForAA;

        List<Id> claimIds = new List<Id>{ claimsForAA[0].Id };
        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        List<Claim> updatedClaims = [SELECT Id, ARC_AutoAdjudicationReview__c FROM Claim WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Status FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claimIds[0]];
        System.assertEquals('Informational', lineItems[0].Status);
        System.assertEquals('Code HS901 added to line items', updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }

    @IsTest
    static void testAAClaimOptumFNR() {
        List<Claim> claimsForAA = [SELECT Id, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c,
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r) FROM Claim];
        claimsForAA[0].ARC_NTE837IBNoteSegment__c = 'FNR';
        update claimsForAA;

        List<Id> claimIds = new List<Id>{ claimsForAA[0].Id };
        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        List<Claim> updatedClaims = [SELECT Id, ARC_AutoAdjudicationReview__c FROM Claim WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Status FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claimIds[0]];
        System.assertEquals('Informational', lineItems[0].Status);
        System.assertEquals('Code HT902 added to line items', updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }

    /*
    @IsTest
    static void testAAClaimZelisHEV() {
        List<Claim> claimsForAA = [SELECT Id, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c,
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r) FROM Claim];
        claimsForAA[0].ARC_NTE837IBNoteSegment__c = 'something#HEV';
        update claimsForAA;

        List<Id> claimIds = new List<Id>{ claimsForAA[0].Id };
        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        List<Claim> updatedClaims = [SELECT Id, ARC_AutoAdjudicationReview__c FROM Claim WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Status FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claimIds[0]];
        System.assertEquals('Informational', lineItems[0].Status);
        System.assertEquals('Code HT904 added to line items', updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }
    */

    @IsTest
    static void testAAClaimOptumNEG() {
        List<Claim> claimsForAA = [SELECT Id, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c,
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r) FROM Claim];
        claimsForAA[0].ARC_NTE837IBNoteSegment__c = 'NEG';
        update claimsForAA;

        List<Id> claimIds = new List<Id>{ claimsForAA[0].Id };
        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        List<Claim> updatedClaims = [SELECT Id, ARC_AutoAdjudicationReview__c FROM Claim WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Status FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claimIds[0]];
        System.assertEquals('Informational', lineItems[0].Status);
        System.assertEquals('Code HT904 added to line items', updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }

    // --- Exclusion / no-match tests ---

    @IsTest
    static void testAAClaimExcludedProcedureCode3075F() {
        // Line item with 3075F procedure code must not be adjudicated even with a valid NTE
        vlocity_ins__VlocityCode__c excCode = [SELECT Id FROM vlocity_ins__VlocityCode__c WHERE Name = '3075F' LIMIT 1];

        List<Claim> claimsForAA = [SELECT Id, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c,
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r) FROM Claim];
        claimsForAA[0].ARC_NTE837IBNoteSegment__c = '#HET';
        update claimsForAA;

        ClaimCoveragePaymentDetail li = [SELECT Id, Status FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claimsForAA[0].Id LIMIT 1];
        li.ARC_ProcedureCode__c = excCode.Id;
        update li;

        List<Id> claimIds = new List<Id>{ claimsForAA[0].Id };
        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        List<Claim> updatedClaims = [SELECT Id, ARC_AutoAdjudicationReview__c FROM Claim WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Status FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claimIds[0]];
        List<ARC_ClaimReasonCode__c> crcs = [SELECT Id FROM ARC_ClaimReasonCode__c WHERE ARC_ClaimCoveragePaymentDetail__c =: lineItems[0].Id];
        System.assertNotEquals('Informational', lineItems[0].Status);
        System.assertEquals(0, crcs.size());
        System.assertEquals(null, updatedClaims[0].ARC_AutoAdjudicationReview__c);
    }

    @IsTest
    static void testAAClaimNoNTEMatch() {
        // An unrecognized NTE note must leave line items untouched and insert no CRCs
        List<Claim> claimsForAA = [SELECT Id, ARC_CCToCompare__c, ARC_NTE837IBNoteSegment__c, ARC_Duplicate__c, Status, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumber.ARC_isActive__c, PolicyNumber.ARC_EffectiveDate__c, PolicyNumber.ARC_ExpirationDate__c,
        (SELECT Id, Name, Status, ARC_Claim__c FROM Claim_Coverage_Payment_Details__r) FROM Claim];
        claimsForAA[0].ARC_NTE837IBNoteSegment__c = 'UNKNOWN NOTE';
        update claimsForAA;

        List<Id> claimIds = new List<Id>{ claimsForAA[0].Id };
        String originalStatus = claimsForAA[0].Claim_Coverage_Payment_Details__r[0].Status;

        Test.startTest();
        ARC_ClaimAutoAdjudication.autoAdjudicateClaim(claimIds);
        Test.stopTest();

        List<Claim> updatedClaims = [SELECT Id, ARC_AutoAdjudicationReview__c FROM Claim WHERE Id IN :claimIds];
        List<ClaimCoveragePaymentDetail> lineItems = [SELECT Id, Status FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claimIds[0]];
        List<ARC_ClaimReasonCode__c> crcs = [SELECT Id FROM ARC_ClaimReasonCode__c WHERE ARC_ClaimCoveragePaymentDetail__c =: lineItems[0].Id];
        System.assertEquals(originalStatus, lineItems[0].Status);
        System.assertEquals(null, updatedClaims[0].ARC_AutoAdjudicationReview__c);
        System.assertEquals(0, crcs.size());
    }
}