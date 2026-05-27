@isTest
private class ARC_ReassignmentSMBTest {

    @TestSetup
    static void makeData(){
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Integer counter = 0;
        for(Integer i=0; i<2;i++){
            Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount'+i, LastName ='Test');
            acc.BillingStreet = '123 Avenue';
            acc.BillingState = 'NY';
            acc.BillingCity = 'New York';
            acc.BillingPostalCode='12345';
            acc.PersonEmail='test@email.com'+counter;
            acc.ARC_IsPrimaryMember__c = true;
            acc.ARC_E123MemberIdFromPolicy__c = 'W123456789'+counter;
            acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
            accList.add(acc);
        }
        insert accList;
        List <vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(2);
        counter = 0;
        List<Account> accountContacts = [SELECT PersonContactId FROM Account WHERE FirstName Like 'PersonAccount%'];
        for(vlocity_ins__GroupCensusMember__c censusMember: censusMemberList){
            censusMember.vlocity_ins__ContactId__c = accountContacts[counter].PersonContactId;
            censusMember.vlocity_ins__SocialSecurityNumber__c = '123456789';
            counter++;
        }
        update censusMemberList;
        accList[0].Census_Member__c = censusMemberList[0].Id;
        accList[1].Census_Member__c = censusMemberList[1].Id;
        accList[0].ARC_CensusMember__pc = censusMemberList[0].Id;
        accList[1].ARC_CensusMember__pc = censusMemberList[1].Id;
        accList[0].ARC_Census__c = censusMemberList[0].vlocity_ins__CensusId__c;
        accList[1].ARC_Census__c = censusMemberList[1].vlocity_ins__CensusId__c;
        update accList;
        List<Contract> cont = ARC_TestUtility.createContractsAA(1);
        cont[0].Name = 'WeShare test ';
        cont[0].vlocity_ins__EnrollmentCensusId__c = censusMemberList[0].vlocity_ins__CensusId__c;
        cont[0].AccountId = accList[0].Id;
        cont[0].ARC_ContractReason__c = 'New Application';
        insert cont;
        Id codeRT = Schema.SObjectType.vlocity_ins__VlocityCode__c.getRecordTypeInfosByDeveloperName().get('RARC').getRecordTypeId();
        vlocity_ins__VlocityCode__c code = new vlocity_ins__VlocityCode__c(Name = 'V0001', ARC_Status__c = 'Denied', RecordTypeId = codeRT);
        insert code;

        InsurancePolicy pol = ARC_TestUtility.createTestPolicies(1)[0];
        pol.ARC_Contract__c = cont[0].Id;
        upsert pol;

        List<InsurancePolicyParticipant> ippList = ARC_TestUtility.createTestPolicyParticipant(2);
        ippList[0].InsurancePolicyId = pol.Id;
        ippList[0].PrimaryParticipantContactId = censusMemberList[0].vlocity_ins__ContactId__c;
        ippList[1].InsurancePolicyId = pol.Id;
        ippList[1].PrimaryParticipantContactId = censusMemberList[1].vlocity_ins__ContactId__c;
        insert ippList;

        Claim clm = new Claim();
        clm.Name = 'Test Claim for Cloning';
        clm.ARC_TotalNetPaidAmount__c = 2512;
        clm.ARC_CheckNumber__c = '1234';
        clm.ARC_ReasonCode__c = code.Id;
        clm.PolicyNumberId = pol.Id;
        clm.ARC_ParticipantPolicyParticipant__c = ippList[0].Id;
        clm.ARC_DOSFrom__c = System.Today();
        clm.ARC_DOSTo__c = System.Today();
        insert clm;

        List<ClaimCoveragePaymentDetail> ccpds = ARC_TestUtility.createTestCoveragePayments(4); 
        for (Integer i = 0; i < 4; i++) {
            ccpds[i].ARC_Allowed__c = 1000;
            ccpds[i].ARC_Deductible__c = 100;
            ccpds[i].ARC_Claim__c = clm.Id;
            ccpds[i].Status = 'Paid';
        }
        update ccpds;
        
        vlocity_ins__vlocityCode__c newCode = new vlocity_ins__vlocityCode__c();
        newCode.Name = 'abc123';
        insert newCode;

        List<ARC_ClaimReasonCode__c> claimReasonCodes = new List<ARC_ClaimReasonCode__c>();
        for (Integer i = 0; i < 4; i++) {
            ARC_ClaimReasonCode__c crc = new ARC_ClaimReasonCode__c();
            crc.ARC_ClaimCoveragePaymentDetail__c = ccpds[i].Id;
            crc.ARC_ReasonCode__c = newCode.Id;
            claimReasonCodes.add(crc);
        }
        insert claimReasonCodes;


        //AGGREGATORS
        Id familyAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Family').getRecordTypeId();
        ARC_Aggregator__c famAgg = new ARC_Aggregator__c();
        famAgg.Name = 'Family AMCS';
        famAgg.ARC_CreatedIn__c = pol.Id;
        famAgg.ARC_LimitValue__c = 16000;
        famAgg.ARC_Year__c = System.today().year() + '';
        famAgg.ARC_Type__c = 'Currency';
        famAgg.RecordTypeId = familyAggRT;
        insert famAgg;

        List<ARC_Aggregator__c> aggs = new List<ARC_Aggregator__c>();
        ARC_Aggregator__c agg1 = new ARC_Aggregator__c();
        agg1.Name = 'Individual AMCS';
        agg1.ARC_Code__c = 'AMCS__c';
        agg1.ARC_CreatedIn__c = pol.Id;
        agg1.ARC_LimitValue__c = 8000;
        agg1.ARC_Year__c = System.today().year() + '';
        agg1.ARC_Type__c = 'Currency';
        agg1.ARC_FamilyAggregator__c = famAgg.Id;
        aggs.add(agg1);
        ARC_Aggregator__c agg2 = new ARC_Aggregator__c();
        agg2.Name = 'Individual AMCS';
        agg2.ARC_Code__c = 'AMCS__c';
        agg2.ARC_CreatedIn__c = pol.Id;
        agg2.ARC_LimitValue__c = 8000;
        agg2.ARC_Year__c = System.today().year() + '';
        agg2.ARC_Type__c = 'Currency';
        agg2.ARC_FamilyAggregator__c = famAgg.Id;
        aggs.add(agg2);
        insert aggs;

        List<ARC_ParticipantAggregator__c> pAggs = new List<ARC_ParticipantAggregator__c>();
        ARC_ParticipantAggregator__c pAgg1 = new ARC_ParticipantAggregator__c();
        pAgg1.ARC_Aggregator__c = agg1.Id;
        pAgg1.ARC_ConsumedValue__c = 500;
        pAgg1.ARC_Policy__c = pol.Id;
        pAgg1.ARC_PolicyParticipant__c = ippList[0].Id;
        pAggs.add(pAgg1);
        ARC_ParticipantAggregator__c pAgg2 = new ARC_ParticipantAggregator__c();
        pAgg2.ARC_Aggregator__c = agg2.Id;
        pAgg2.ARC_ConsumedValue__c = 0;
        pAgg2.ARC_Policy__c = pol.Id;
        pAgg2.ARC_PolicyParticipant__c = ippList[1].Id;
        pAggs.add(pAgg2);
        insert pAggs;
    
        List<ClaimPaymentSummary> pSumList = new List<ClaimPaymentSummary>();
        for (Integer i = 0; i < 4; i++) {
            ClaimPaymentSummary pSum = new ClaimPaymentSummary();
            pSum.ARC_ConsumedValue__c = 500;
            pSum.Name = 'AMCS__c - 1';
            pSum.ARC_ParticipantAggregator__c = pAgg1.Id;
            pSum.ClaimId = clm.Id;
            pSumList.add(pSum);
        }
        insert pSumList;
    }


    @isTest
    static void createSMBReassignmentTest() {
        ARC_ReassignmentSMB.inputRequest req = new ARC_ReassignmentSMB.inputRequest();
        List<ARC_ReassignmentSMB.inputRequest> reqList = new List<ARC_ReassignmentSMB.inputRequest>();
        List<InsurancePolicyParticipant> ipps = [SELECT Id, PrimaryParticipantContactId, InsurancePolicyId FROM InsurancePolicyParticipant ORDER BY Name LIMIT 2];
        Claim clm = [SELECT Id, Name FROM Claim LIMIT 1];
        req.claimId = clm.Id;
        req.newContactId = ipps[1].PrimaryParticipantContactId;
        req.InsurancePolicyParticipantsList = ipps;
        reqList.add(req); 
        Test.startTest();
        ARC_ReassignmentSMB.createSMBReassignment(reqList);
        Test.stopTest();
        // Assert that the claim's participant was reassigned
        List<Claim> claims = [SELECT Id, ARC_ParticipantPolicyParticipant__c FROM Claim];
        Claim updatedClm = [SELECT Id, ARC_ParticipantPolicyParticipant__c FROM Claim WHERE Id != :clm.Id ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(ipps[1].Id, updatedClm.ARC_ParticipantPolicyParticipant__c, 'Claim participant should be reassigned.');
    }

    @isTest
    static void createSMBReassignmentReassignedTest() {
        ARC_ReassignmentSMB.inputRequest req = new ARC_ReassignmentSMB.inputRequest();
        List<ARC_ReassignmentSMB.inputRequest> reqList = new List<ARC_ReassignmentSMB.inputRequest>();
        List<InsurancePolicyParticipant> ipps = [SELECT Id, PrimaryParticipantContactId, InsurancePolicyId FROM InsurancePolicyParticipant ORDER BY Name LIMIT 2];
        Claim clm = [SELECT Id, Name FROM Claim LIMIT 1];
        
        req.claimId = clm.Id;
        req.newContactId = ipps[1].PrimaryParticipantContactId;
        req.InsurancePolicyParticipantsList = ipps;
        reqList.add(req); 
        ARC_ReassignmentSMB.createSMBReassignment(reqList);

        Test.startTest();
        ARC_ReassignmentSMB.inputRequest req2 = new ARC_ReassignmentSMB.inputRequest();
        List<ARC_ReassignmentSMB.inputRequest> reqList2 = new List<ARC_ReassignmentSMB.inputRequest>();
        Claim rClm = [SELECT Id, Name, Status, ARC_OriginalSMB__c FROM Claim WHERE Name LIKE '%REASSIGNMENT%' LIMIT 1];
        req2.claimId = rClm.Id;
        req2.newContactId = ipps[0].PrimaryParticipantContactId;
        req2.InsurancePolicyParticipantsList = ipps;
        reqList2.add(req2); 
        System.debug('req2:' + req2);
        ARC_ReassignmentSMB.createSMBReassignment(reqList2);
        Test.stopTest();
        // Assert that the claim's participant was reassigned
        List<Claim> claims = [SELECT Id, ARC_ParticipantPolicyParticipant__c FROM Claim];
        Claim updatedClm = [SELECT Id, ARC_ParticipantPolicyParticipant__c FROM Claim WHERE Id != :clm.Id ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(ipps[0].Id, updatedClm.ARC_ParticipantPolicyParticipant__c, 'Claim participant should be reassigned.');
    }

    @isTest
    static void createSMBReassignmentTest_NoSMBItemPayments() {
        ClaimPaymentSummary[] cpsToDelete = [SELECT Id FROM ClaimPaymentSummary WHERE Claim.ARC_ParticipantPolicyParticipant__c != null];
        delete cpsToDelete;
        ARC_ReassignmentSMB.inputRequest req = new ARC_ReassignmentSMB.inputRequest();
        List<ARC_ReassignmentSMB.inputRequest> reqList = new List<ARC_ReassignmentSMB.inputRequest>();
        List<InsurancePolicyParticipant> ipps = [SELECT Id, PrimaryParticipantContactId, InsurancePolicyId FROM InsurancePolicyParticipant ORDER BY Name LIMIT 2];
        Claim clm = [SELECT Id, Name FROM Claim LIMIT 1];
        req.claimId = clm.Id;
        req.newContactId = ipps[1].PrimaryParticipantContactId;
        req.InsurancePolicyParticipantsList = ipps;
        reqList.add(req); 
        Test.startTest();
        ARC_ReassignmentSMB.createSMBReassignment(reqList);
        Test.stopTest();
        // Assert that the claim's participant was reassigned
        List<Claim> claims = [SELECT Id, ARC_ParticipantPolicyParticipant__c FROM Claim];
        Claim updatedClm = [SELECT Id, ARC_ParticipantPolicyParticipant__c FROM Claim WHERE Id != :clm.Id ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(ipps[1].Id, updatedClm.ARC_ParticipantPolicyParticipant__c, 'Claim participant should be reassigned.');
    }

    @isTest
    static void createSMBReassignmentTestError_UncommitedCLIs() {
        ARC_ReassignmentSMB.inputRequest req = new ARC_ReassignmentSMB.inputRequest();
        List<ARC_ReassignmentSMB.inputRequest> reqList = new List<ARC_ReassignmentSMB.inputRequest>();
        List<InsurancePolicyParticipant> ipps = [SELECT Id, PrimaryParticipantContactId, InsurancePolicyId FROM InsurancePolicyParticipant ORDER BY Name LIMIT 2];
        Claim clm = [SELECT Id, Name FROM Claim LIMIT 1];
        integer initclaims = [SELECT Id, ARC_ParticipantPolicyParticipant__c FROM Claim].size();
        req.claimId = clm.Id;
        req.newContactId = ipps[1].PrimaryParticipantContactId;
        req.InsurancePolicyParticipantsList = ipps;
        reqList.add(req); 
        // set all CLIs to Informational status (uncommited)
        List<ClaimCoveragePaymentDetail> CLIList = [SELECT id, Status FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c = :clm.Id];
        for( ClaimCoveragePaymentDetail cli : CLIList){
            cli.Status = 'Informational';
        }
        update CLIList;
        String errorMsg;
        Test.startTest();
        try{
            ARC_ReassignmentSMB.createSMBReassignment(reqList);
        } catch (Exception e) {
            errorMsg = e.getMessage();  
        }
        Test.stopTest();
        // Assert that the claim's participant was reassigned
        Integer endclaims = [SELECT Id, ARC_ParticipantPolicyParticipant__c FROM Claim].size();
        System.assertEquals(initclaims, endclaims, 'No new claims should have been submitted.');
        System.assertEquals(true, errorMsg.contains('SMBs with unprocessed line items cannot be reassigned.'), 'Error message should contain unprocessed claim error refference.');
    }

    
}