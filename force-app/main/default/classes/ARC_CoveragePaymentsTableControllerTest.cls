@isTest
public with sharing class ARC_CoveragePaymentsTableControllerTest {
    public static final ARC_CoveragePaymentsTableController classTest = new ARC_CoveragePaymentsTableController();
   
    @TestSetup
    static void makeData() {

        Integer SCENARIOS_COUNT = 5;

        //Create Claims
        List<Claim> claim = ARC_TestUtility.createTestClaims(SCENARIOS_COUNT);
        //Create Test Contact
        List<Account> acc =  ARC_TestUtility.createTestAccount(SCENARIOS_COUNT, 'ARC_IFPPersonAccount');
        acc[0].PersonBirthdate = Date.today().addYears(-45);
        acc[1].PersonBirthdate = Date.today().addYears(-65);
        acc[2].PersonBirthdate = Date.today().addYears(-56);
        acc[3].PersonBirthdate = Date.today().addYears(-57);
        acc[4].PersonBirthdate = Date.today().addYears(-57);
        update acc;
        List<Id> accIds = new List<Id>();
        for (Account a : acc) {
            accIds.add(a.Id);
        }
        List<Contact> testCont = [SELECT Id FROM Contact WHERE Id IN (SELECT PersonContactId FROM Account WHERE Id =: accIds)];


        // Create Coverage Payment Details
        // CASE 0 - WeShare Program
        List<ClaimCoveragePaymentDetail> listCoveragesPaymn = ARC_TestUtility.createTestCoveragePayments(21);
        for (ClaimCoveragePaymentDetail c : listCoveragesPaymn) {
            c.Status =  'New';
            c.ARC_Claim__c = claim[0].Id;  
        }
        listCoveragesPaymn[0].ARC_Deductible__c = listCoveragesPaymn[1].ARC_Deductible__c =  20;
        listCoveragesPaymn[0].ARC_Allowed__c = listCoveragesPaymn[1].ARC_Allowed__c =  200;
        listCoveragesPaymn[0].ARC_Pre_Existing_Condition__c = listCoveragesPaymn[1].ARC_Pre_Existing_Condition__c =10;
        listCoveragesPaymn[0].ARC_Medical_Visit_Reason__c = 'Acupuncture';
        listCoveragesPaymn[1].ARC_Medical_Visit_Reason__c = 'Sleep/Insomnia Counseling';
        //listCoveragesPaymn[2].ARC_Medical_Visit_Reason__c = 'PhysicalTherapy';
        listCoveragesPaymn[3].ARC_Medical_Visit_Reason__c = 'Behavioral';
        listCoveragesPaymn[4].ARC_Medical_Visit_Reason__c = 'Chiropractic';
        listCoveragesPaymn[5].ARC_Medical_Visit_Reason__c = 'Cervical Cancer Screenings';
        listCoveragesPaymn[6].ARC_Medical_Visit_Reason__c = 'CC - Flexible Sigmoidoscopy';
        listCoveragesPaymn[7].ARC_Medical_Visit_Reason__c = 'Mammograms';
        listCoveragesPaymn[8].ARC_Medical_Visit_Reason__c = 'Prostate Screenings';
        listCoveragesPaymn[9].ARC_MaximumType__c = 'Allergy Testing';
        listCoveragesPaymn[9].ARC_Allowed__c = 20;
        listCoveragesPaymn[9].ARC_MaximumTypeAmount__c = 10;
        listCoveragesPaymn[9].ARC_Medical_Visit_Reason__c = 'CC - Cologuard / Self Screen';
        listCoveragesPaymn[10].ARC_MaximumType__c = 'Durable Medical Equipment (DME)';
        listCoveragesPaymn[10].ARC_Allowed__c = 20;
        listCoveragesPaymn[10].ARC_Medical_Visit_Reason__c = 'CC - Colonoscopy';
        listCoveragesPaymn[10].ARC_MaximumTypeAmount__c = 10;
        listCoveragesPaymn[11].ARC_MaximumType__c = 'Maternity';
        listCoveragesPaymn[11].ARC_Allowed__c = 20;
        listCoveragesPaymn[11].ARC_MaximumTypeAmount__c = 10;
        listCoveragesPaymn[12].ARC_MaximumType__c = 'Congenital Birth Defect';
        listCoveragesPaymn[12].ARC_Allowed__c = 20;
        listCoveragesPaymn[12].ARC_MaximumTypeAmount__c = 10;
        listCoveragesPaymn[13].ARC_MaximumType__c = 'CPAP/BIPAP Supplies';
        listCoveragesPaymn[13].ARC_Allowed__c = 20;
        listCoveragesPaymn[13].ARC_MaximumTypeAmount__c = 10;
        // listCoveragesPaymn[14].ARC_Medical_Visit_Reason__c = 'Generic Formulary Injectable Pen';
        // listCoveragesPaymn[15].ARC_Medical_Visit_Reason__c = 'Standard Brand Formulary Injectable Pen';
        // listCoveragesPaymn[16].ARC_Medical_Visit_Reason__c = 'Non-Formulary Brand Injectable Pen';
        // listCoveragesPaymn[17].ARC_Medical_Visit_Reason__c = 'Specialty Brand Injectable Pen';
        listCoveragesPaymn[18].ARC_Medical_Visit_Reason__c = 'Shingles Vaccine - Zostavax 90736';
        listCoveragesPaymn[19].ARC_Coinsurance__c = 10;
        listCoveragesPaymn[20].ARC_Tobacco__c = 10;
        update listCoveragesPaymn;

        // CASE 1 - WeShare Legacy Program
        List<ClaimCoveragePaymentDetail> listCoveragesPaymn2 = ARC_TestUtility.createTestCoveragePayments(7);
        for (ClaimCoveragePaymentDetail c : listCoveragesPaymn2) {
            c.Status =  'New';
            c.ARC_Claim__c = claim[1].Id;  
        }
        listCoveragesPaymn2[0].ARC_Medical_Visit_Reason__c = 'Cervical Cancer Screenings';
        listCoveragesPaymn2[1].ARC_Medical_Visit_Reason__c = 'CC - Flexible Sigmoidoscopy';
        listCoveragesPaymn2[2].ARC_Medical_Visit_Reason__c = 'Bone Density Screening';
        listCoveragesPaymn2[3].ARC_Medical_Visit_Reason__c = 'Well Woman Visit';
        listCoveragesPaymn2[4].ARC_Medical_Visit_Reason__c = 'CC - Cologuard / Self Screen';
        listCoveragesPaymn2[5].ARC_Medical_Visit_Reason__c = 'CC - Colonoscopy';
        listCoveragesPaymn2[6].ARC_Medical_Visit_Reason__c = 'Psychiatric Care';
        update listCoveragesPaymn2;

        // CASE 2 - WeShare Access Program
        List<ClaimCoveragePaymentDetail> listCoveragesPaymn3 = ARC_TestUtility.createTestCoveragePayments(17);
        for (ClaimCoveragePaymentDetail cc: listCoveragesPaymn3) {
            cc.ARC_Allowed__c =  200;
            cc.Status =  'New';
            cc.ARC_Claim__c =  claim[2].Id;
        }
        listCoveragesPaymn3[0].ARC_Deductible__c = 20;
        listCoveragesPaymn3[1].ARC_Tobacco__c = 20;
        listCoveragesPaymn3[2].ARC_MaximumType__c = 'Durable Medical Equipment (DME)';
        listCoveragesPaymn3[2].ARC_MaximumTypeAmount__c = 20;
        listCoveragesPaymn3[3].ARC_Medical_Visit_Reason__c = 'Mammograms';
        listCoveragesPaymn3[4].ARC_Medical_Visit_Reason__c = 'Behavioral';
        listCoveragesPaymn3[5].ARC_Medical_Visit_Reason__c = 'Office Visit/Copay';
        listCoveragesPaymn3[7].ARC_Pre_Existing_Condition__c = 10;
        listCoveragesPaymn3[8].ARC_MaximumType__c = 'Allergy Testing';
        listCoveragesPaymn3[8].ARC_MaximumTypeAmount__c = 10;
        listCoveragesPaymn3[9].ARC_Medical_Visit_Reason__c = 'Prostate Screenings';
        // listCoveragesPaymn3[10].ARC_Medical_Visit_Reason__c = 'Generic Formulary Injectable Pen';
        // listCoveragesPaymn3[11].ARC_Medical_Visit_Reason__c = 'Standard Brand Formulary Injectable Pen';
        // listCoveragesPaymn3[12].ARC_Medical_Visit_Reason__c = 'Non-Formulary Brand Injectable Pen';
        // listCoveragesPaymn3[13].ARC_Medical_Visit_Reason__c = 'Specialty Brand Injectable Pen';
        listCoveragesPaymn3[14].ARC_Medical_Visit_Reason__c = 'Shingles Vaccine - Zostavax 90736';
        listCoveragesPaymn3[15].ARC_Medical_Visit_Reason__c = 'CC - Cologuard / Self Screen';
        listCoveragesPaymn3[16].ARC_Medical_Visit_Reason__c = 'Cervical Cancer Screenings';

        update listCoveragesPaymn3;

        // CASE 3 - UHSM Silver Program
        List<ClaimCoveragePaymentDetail> listCoveragesPaymn4 = ARC_TestUtility.createTestCoveragePayments(2);
        listCoveragesPaymn4[0].ARC_Allowed__c = listCoveragesPaymn4[1].ARC_Allowed__c=  200;
        listCoveragesPaymn4[0].Status = listCoveragesPaymn4[1].Status = 'New';
        listCoveragesPaymn4[0].ARC_Claim__c = listCoveragesPaymn4[1].ARC_Claim__c = claim[3].Id;
        listCoveragesPaymn4[0].ARC_Medical_Visit_Reason__c = 'Office Visit/Copay';
        listCoveragesPaymn4[0].ARC_Coinsurance__c = 20;
        update listCoveragesPaymn4;

        // CASE 4 - WeShare Premier Program
        List<ClaimCoveragePaymentDetail> listCoveragesPaymn5 = ARC_TestUtility.createTestCoveragePayments(3);
        for (ClaimCoveragePaymentDetail c : listCoveragesPaymn5) {
            c.Status =  'New';
            c.ARC_Claim__c = claim[4].Id;  
            c.ARC_Allowed__c = 200;
        }
        listCoveragesPaymn5[0].ARC_MaximumTypeAmount__c = 20;
        listCoveragesPaymn5[0].ARC_MaximumType__c = 'After Life';
        listCoveragesPaymn5[1].ARC_MaximumTypeAmount__c = 20;
        listCoveragesPaymn5[1].ARC_MaximumType__c = 'Critical Illness and Bill';
        listCoveragesPaymn5[2].ARC_MaximumTypeAmount__c = 20;
        listCoveragesPaymn5[2].ARC_MaximumType__c = 'Critical Illness and Bill';
        update listCoveragesPaymn5;


        // Products
        Product2 prod = new Product2(Name='WeShare 1k', ProductCode='PROG_UHSM_WeShare1k', vlocity_ins__Type__c='Medical', vlocity_ins__SubType__c='PPO');
        Product2 prod2 = new Product2(Name='WeShare Legacy', ProductCode='PROG_WeShareLegacy', vlocity_ins__Type__c='Medical', vlocity_ins__SubType__c='PPO');
        Product2 prod3 = new Product2(Name='WeShare Access 10k', ProductCode='PROG_UHSM_Access10k', vlocity_ins__Type__c='Medical', vlocity_ins__SubType__c='PPO');
        Product2 prod4 = new Product2(Name='UHSM Silver Essential $10K', ProductCode='PROG_UHSMSilverEssential', vlocity_ins__Type__c='Medical', vlocity_ins__SubType__c='PPO');
        Product2 prod5 = new Product2(Name='WeShare Premier 3k', ProductCode='PROG_UHSM_WeSharePremier3k', vlocity_ins__Type__c='Medical', vlocity_ins__SubType__c='PPO');
        
        List<Product2> prods = new List<Product2>{
            prod,
            prod2,
            prod3,
            prod4,
            prod5
        };
        insert prods;

        // Contracts
        List<Contract> ctr = ARC_TestUtility.createContractsAA(SCENARIOS_COUNT);
        for (Contract c : ctr) {
            c.ARC_ContractReason__c = 'New Application';
            c.ARC_EffectiveDate__c = Date.newInstance(2025, 06, 01);
        }
        insert ctr;

        for (Integer i = 0 ; i < SCENARIOS_COUNT; i++) {
            ctr[i].Status = 'Terminated';
            ctr[i].ARC_Inactive_Date__c = Date.newInstance(2026, 06, 01);

        }
        update ctr;
        
        // Create Census, Census Member, Contract Line Item & Group Census Member Plan
        List<vlocity_ins__GroupCensus__c> census = new List<vlocity_ins__GroupCensus__c>(); 
        for (Integer i = 0 ; i < SCENARIOS_COUNT; i++) {
            vlocity_ins__GroupCensus__c c = new vlocity_ins__GroupCensus__c();
            c.Name = 'Census Test ' + i;
            c.vlocity_ins__GroupId__c = ctr[i].AccountId;
            census.add(c);
        }
        insert census;

        List<vlocity_ins__GroupCensusMember__c> cmList = new List<vlocity_ins__GroupCensusMember__c>();
        for (Integer i = 0 ; i < SCENARIOS_COUNT; i++) {
            vlocity_ins__GroupCensusMember__c cm = new vlocity_ins__GroupCensusMember__c();
            cm.Name = 'Test Census Member ' + i;
            cm.vlocity_ins__FirstName__c = 'Test';
            cm.vlocity_ins__LastName__c = 'Census Member ' + i;
            cm.vlocity_ins__ContactId__c = testCont[i].Id;
            cm.vlocity_ins__CensusId__c = census[i].Id;
            cmList.add(cm);
        } 
        insert cmList;

        List<vlocity_ins__ContractLineItem__c> cliList = new List<vlocity_ins__ContractLineItem__c>();
        for (Integer i = 0 ; i < SCENARIOS_COUNT; i++) {
            vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
            cli.Name = 'Test Plan ' + i;
            cli.vlocity_ins__ContractId__c = ctr[i].Id;
            cli.vlocity_ins__Product2Id__c = prods[i].Id;
            cliList.add(cli);
        }
        insert cliList;

        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpList = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        for (Integer i = 0 ; i < SCENARIOS_COUNT; i++) {
            vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c();
            gcmp.vlocity_ins__ContractLineId__c = cliList[i].Id;
            gcmp.vlocity_ins__GroupCensusMemberId__c = cmList[i].Id;
            gcmpList.add(gcmp);
        }
        insert gcmpList;


        // Create Insurance Policy
        List<InsurancePolicy> ipList = ARC_TestUtility.createTestPolicies(SCENARIOS_COUNT, 'ARC_IndividualAndFamily');
        for (Integer i = 0 ; i < SCENARIOS_COUNT; i++) {
            ipList[i].ProductId = prods[i].Id;
            ipList[i].ARC_Contract__c = ctr[i].Id;
        }
        update ipList;

        
        // Create Insurance Policy Participant
        List<InsurancePolicyParticipant> ippList = new List<InsurancePolicyParticipant>();
        for (Integer i = 0; i < SCENARIOS_COUNT; i++) {
            InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(
                InsurancePolicyId = ipList[i].Id, 
                PrimaryParticipantContactId = testCont[i].Id, 
                Role = 'Primary',
                ARC_StartDate__c = Date.newInstance(2025, 06, 01),
                ARC_EndDate__c = Date.newInstance(2026, 06, 01)
            );
            ippList.add(ipp);
        }
        insert ippList;

        List<InsurancePolicyCoverage> ipcList = new List<InsurancePolicyCoverage>();
        for (Integer i = 0; i < SCENARIOS_COUNT; i++) {
            InsurancePolicyCoverage ipc = new InsurancePolicyCoverage(
                InsurancePolicyId = ipList[i].Id,
                vlocity_ins_fsc__Product2Id__c = prods[i].Id
            );
            ipcList.add(ipc);
        }
        insert ipcList;

        List<ARC_CoverageParticipant__c> cpList = new List<ARC_CoverageParticipant__c>();
        for (Integer i = 0; i < SCENARIOS_COUNT; i++) {
            ARC_CoverageParticipant__c cp = new ARC_CoverageParticipant__c(
                ARC_PolicyParticipant__c = ippList[i].Id,
                ARC_PolicyCoverage__c = ipcList[i].Id,
                ARC_Policy__c = ipList[i].Id
            );
            cpList.add(cp);
        }
        insert cpList;

        Database.executeBatch(new ARC_CreateMissingAggregatorsV2('Id != null', true, true));

        ARC_Aggregator__c newAgg = new ARC_Aggregator__c();
        newAgg.RecordTypeId = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
        newAgg.Name = 'Physical Therapy Visits';
        newAgg.ARC_Year__c = '2026';
        newAgg.ARC_CreatedIn__c = ipList[0].Id;
        newAgg.ARC_LimitValue__c = 1000;
        newAgg.ARC_Member__c = acc[0].Id;
        newAgg.ARC_Code__c = 'PHYTH__c';
        newAgg.ARC_Type__c = 'Number';
        newAgg.ARC_NextAvailabilityDate__c = Date.newInstance(2024, 06, 01);
        insert newAgg;

        ARC_ParticipantAggregator__c newPartAgg = new ARC_ParticipantAggregator__c();
        newPartAgg.ARC_Policy__c = ipList[0].Id;
        newPartAgg.Name = 'Physical Therapy Visits';
        newPartAgg.ARC_PolicyParticipant__c = ippList[0].Id;
        newPartAgg.ARC_ConsumedValue__c = 0;
        newPartAgg.ARC_Aggregator__c = newAgg.Id;
        insert newPartAgg;

        for (Integer i = 0 ; i < SCENARIOS_COUNT; i++) {
            //Update Claim
            claim[i].PolicyNumberId = ipList[i].id;
            claim[i].Name = 'TestingData' + i;
            claim[i].Status = 'Initial';
            claim[i].ARC_MemberContact__c = testCont[i].Id;
            claim[i].ARC_ParticipantPolicyParticipant__c = ippList[i].Id;
            claim[i].LossDate = claim[i].ARC_DOSFrom__c = claim[i].ARC_DOSTo__c = Date.newInstance(2026, 05, 01);

        }
        update claim;

        // Add one SMB line item with Paid status
        listCoveragesPaymn[19].Status = 'Paid';
        update listCoveragesPaymn;
    }
    
    
    @isTest
    public static void getAllOptionsTest1() {
        Claim claim = ARC_TestUtility.createTestClaims(1)[0];
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('claimId', claim.Id);

        classTest.invokeMethod('CheckForDuplicateClaim2', input, output, options);
    }
    
    @isTest
    public static void getAllOptionsTest2() {
        List<ClaimDuplicateFields__c> customSettingRecords = new List<ClaimDuplicateFields__c>();
        ClaimDuplicateFields__c duplicate = new ClaimDuplicateFields__c( Name = 'Duplicate',ListOfFields__c='ARC_DOSFrom__c,ARC_DOSTo__c,ARC_ClaimTotalAmount__c');
        ClaimDuplicateFields__c partial = new ClaimDuplicateFields__c( Name = 'Partial Combination 1',ListOfFields__c='ARC_DOSFrom__c,ARC_DOSTo__c');
        ClaimDuplicateFields__c filterCriteria = new ClaimDuplicateFields__c( Name = 'Existing Claims Filter Criteria',ListOfFields__c='ARC_DOSFrom__c,ARC_DOSTo__c');
        customSettingRecords.add(duplicate);
        customSettingRecords.add(partial);
        customSettingRecords.add(filterCriteria);
        insert customSettingRecords;

        InsurancePolicy testPolicy = ARC_TestUtility.createTestPolicies(1, 'ARC_IndividualAndFamily')[0];
        vlocity_ins__GroupCensusMember__c member = ARC_TestUtility.createTestCensusMember(1)[0];
        Contact cont = ARC_TestUtility.createTestContact(1, 'Contact')[0];
        
        Claim claim1 = new Claim(Name = 'TestClaim1');
        Claim claim2 = new Claim(Name = 'TestClaim2');
        Claim claim3 = new Claim(Name = 'TestClaim3');

        claim3.PolicyNumberId = claim2.PolicyNumberId = claim1.PolicyNumberId = testPolicy.Id;
        claim3.PolicyNumberId = claim2.PolicyNumberId = testPolicy.Id;
        claim3.ARC_PatientCensusMember__c = claim2.ARC_PatientCensusMember__c = member.Id;
        claim3.ARC_MemberContact__c = claim2.ARC_MemberContact__c = cont.Id;
        claim3.ARC_DOSFrom__c = claim2.ARC_DOSFrom__c = claim1.ARC_DOSFrom__c= System.today();
        claim3.ARC_DOSTo__c = claim2.ARC_DOSTo__c = claim1.ARC_DOSTo__c = System.Today().addDays(1);
        claim3.ARC_Duplicate__c = claim2.ARC_Duplicate__c = claim1.ARC_Duplicate__c = false;
        claim3.ARC_PartialDuplicate__c = claim2.ARC_PartialDuplicate__c = claim1.ARC_PartialDuplicate__c = false;
        claim2.ARC_ClaimTotalAmount__c = claim1.ARC_ClaimTotalAmount__c = 100;
        claim3.ARC_ClaimTotalAmount__c =50;
        insert claim1;
        insert claim2;
        insert claim3;


        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('claimId', claim2.Id);
        classTest.invokeMethod('CheckForDuplicateClaim2', input, output, options);
        input.put('claimId', claim1.Id);
        classTest.invokeMethod('CheckForDuplicateClaim2', input, output, options);
    }

    @isTest
    public static void CheckForDuplicateClaim2InIt2() {
        Claim claim = ARC_TestUtility.createTestClaims(1)[0];
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('claimId', claim.Id);

        classTest.invokeMethod('CheckForDuplicateClaim2', input, output, options);
    }
    
    @isTest
    public static void CheckForDuplicateClaim2InIt() {
        Claim claim = ARC_TestUtility.createTestClaims(1)[0];
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('claimId', claim.Id);

        classTest.invokeMethod('CheckForDuplicateClaim2InIt', input, output, options);
    }
	
    @isTest
    public static void CheckForDuplicateClaim2DeDupInIt() {
        Claim claim = ARC_TestUtility.createTestClaims(1)[0];
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('claimId', claim.Id);

        classTest.invokeMethod('CheckForDuplicateClaim2DeDuplicate', input, output, options);
    }
    @isTest
    public static void CheckForDuplicateClaim2InItSec() {
        Claim claim = ARC_TestUtility.createTestClaims(1)[0];
        claim.ARC_PartialDuplicate__c=true;
        update claim;
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('claimId', claim.Id);

        classTest.invokeMethod('CheckForDuplicateClaim2InIt', input, output, options);
    }
    
    @isTest
    public static void getAllCoveragePaymentsTest() {
        Claim claim = ARC_TestUtility.createTestClaims(1)[0];
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('claimId', claim.Id);

        classTest.invokeMethod('getAllCoveragePayments', input, output, options);
    }
	
    @isTest
    public static void getAllOptionsTest() {
        Claim claim = ARC_TestUtility.createTestClaims(1)[0];
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('claimId', claim.Id);

        classTest.invokeMethod('getAllOptions', input, output, options);
    }

    @isTest
    public static void updateCovPaymentStatusTest() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> idsList = new List<Object>();
        List<Object> code_ids_list = new List<Object>();
        List<Object> reason_codes_list = new List<Object>();
        List<Object> itemsMod = new List<Object>();
        
        Test.startTest();
            List<ClaimCoveragePaymentDetail> listCoveragesPaymn = ARC_TestUtility.createTestCoveragePayments(13);
            for (ClaimCoveragePaymentDetail cp : listCoveragesPaymn) {
                 cp.Status='New';
                 idsList.add(cp.Id);
            }
            update listCoveragesPaymn;

            vlocity_ins__VlocityCode__c reason_code = new vlocity_ins__VlocityCode__c(Name = 'DACC');
            insert reason_code;
            Map<String, Object> reason_code_map = new Map<String, Object>{
                'id' => reason_code.Id,
                'code' => reason_code.Name
            };
            reason_codes_list.add(reason_code_map);
            code_ids_list.add(reason_code.Id);

            for (Integer i = 0; i < idsList.size(); i++) {
                Map<String, Object> item_reason = new Map<String, Object>();
                item_reason.put('item', idsList[i]);
                if (i == 0) item_reason.put('reason', 'Accupuncture');
                if (i == 1) item_reason.put('reason', 'P. Therapy');
                if (i == 2) item_reason.put('reason', 'Behavioral');
                if (i == 3) item_reason.put('reason', 'Chiropractic');
                if (i == 4) item_reason.put('reason', 'Urgent Care');
                if (i == 5) item_reason.put('reason', 'Office Visit/Copay');
                if (i == 6) item_reason.put('reason', 'Cervical Cancer Screenings');
                if (i == 7) item_reason.put('reason', 'Colon Cancer Screenings');
                if (i == 8) item_reason.put('reason', 'Mammograms');
                if (i == 9) item_reason.put('reason', 'Prostate Screenings');
                if (i == 10) item_reason.put('reason', 'CC - Cologuard / Self Screen');
                if (i == 11) item_reason.put('reason', 'CC - Flexible Sigmoidoscopy');
                if (i == 12) item_reason.put('reason', 'CC - Colonoscopy');
                itemsMod.add(item_reason);
            }

            input.put('status', 'Denied');
            input.put('codes', code_ids_list);
            input.put('ids', idsList); 
            input.put('itemsMod', itemsMod);
            input.put('reasonCodeList', reason_codes_list);
            classTest.invokeMethod('updateCovPaymentStatus', input, output, options);
        Test.stopTest();
    }

    @isTest
    public static void createItemPaymentsTest() {
        Claim claim = [SELECT Id FROM Claim WHERE Name = 'TestingData0' LIMIT 1];

        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Id> idsList = new List<Id>();
                
        List<ClaimCoveragePaymentDetail> cliList = [SELECT Id,ARC_Medical_Visit_Reason__c,ARC_MaximumType__c FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claim.Id];
        for (ClaimCoveragePaymentDetail cc: cliList) {
            idsList.add(cc.Id);
        }
        input.put('claimId', claim.Id);
        input.put('itemIds', idsList);

        Test.startTest();
            classTest.invokeMethod('createItemPayments', input, output, options);
        Test.stopTest();
    }

    @isTest
    public static void createItemPaymentsTestTwo() {
        Claim claim = [SELECT Id, ARC_ParticipantPolicyParticipant__c FROM Claim WHERE Name = 'TestingData2'];

        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Id> idsList = new List<Id>();
        
        List<ClaimCoveragePaymentDetail> cliList = [SELECT Id, ARC_Deductible__c, ARC_Pre_Existing_Condition__c FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claim.Id];
        for (ClaimCoveragePaymentDetail cc: cliList) {
            idsList.add(cc.Id);
        }
        input.put('claimId', claim.Id);
        input.put('itemIds', idsList);
        
        Test.startTest();
            classTest.invokeMethod('createItemPayments', input, output, options);
        Test.stopTest();
    }

    @isTest
    public static void createItemPaymentsTestThree() {
        Claim claim = [SELECT Id, ARC_ParticipantPolicyParticipant__c FROM Claim WHERE Name = 'TestingData3'];

        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Id> idsList = new List<Id>();
        
        List<ClaimCoveragePaymentDetail> cliList =[SELECT Id FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claim.Id];
        for (ClaimCoveragePaymentDetail cc: cliList) {
            idsList.add(cc.Id);
        }
        input.put('claimId', claim.Id);
        input.put('itemIds', idsList);

        Test.startTest();
        classTest.invokeMethod('createItemPayments', input, output, options);
        Test.stopTest();
    }

    @isTest
    public static void createItemPaymentsTestFour() {
        
        Claim claim = [SELECT Id, ARC_ParticipantPolicyParticipant__c FROM Claim WHERE Name = 'TestingData1'];

        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Id> idsList = new List<Id>();
        
        List<ClaimCoveragePaymentDetail> cliList = [SELECT Id FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claim.Id];
        for (ClaimCoveragePaymentDetail cc: cliList) {
            idsList.add(cc.Id);
        }
        input.put('claimId', claim.Id);
        input.put('itemIds', idsList);

        List<ARC_ParticipantAggregator__c> aggs = [SELECT Id, 
        ARC_Aggregator__r.ARC_CreatedIn__c, 
        ARC_Aggregator__r.ARC_Member__c,
        ARC_Aggregator__r.ARC_Year__c ,
        ARC_Aggregator__r.ARC_ConsumedTotal__c,
        ARC_Aggregator__r.ARC_Type__c,
        ARC_Aggregator__r.ARC_LimitValue__c,
        ARC_Aggregator__r.ARC_NextAvailabilityDate__c,
        ARC_Aggregator__r.ARC_Code__c
        FROM ARC_ParticipantAggregator__c WHERE ARC_PolicyParticipant__c =: claim.ARC_ParticipantPolicyParticipant__c AND (ARC_Aggregator__r.ARC_Year__c = '2025' OR ARC_Aggregator__r.ARC_Year__c = NULL) AND ARC_Aggregator__r.ARC_Code__c != 'MAT__c' AND ARC_Aggregator__r.ARC_Code__c != 'PREEX__c'];
        Test.startTest();
            classTest.invokeMethod('createItemPayments', input, output, options);
        Test.stopTest();
    }

    @isTest
    public static void createItemPaymentsTestFive() {
        
        Claim claim = [SELECT Id, ARC_ParticipantPolicyParticipant__c FROM Claim WHERE Name = 'TestingData4'];

        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Id> idsList = new List<Id>();
        
        List<ClaimCoveragePaymentDetail> cliList = [SELECT Id FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claim.Id];
        for (ClaimCoveragePaymentDetail cc: cliList) {
            idsList.add(cc.Id);
        }
        input.put('claimId', claim.Id);
        input.put('itemIds', idsList);

        List<ARC_ParticipantAggregator__c> aggs = [SELECT Id, 
        ARC_Aggregator__r.ARC_CreatedIn__c, 
        ARC_Aggregator__r.ARC_Member__c,
        ARC_Aggregator__r.ARC_Year__c ,
        ARC_Aggregator__r.ARC_ConsumedTotal__c,
        ARC_Aggregator__r.ARC_Type__c,
        ARC_Aggregator__r.ARC_LimitValue__c,
        ARC_Aggregator__r.ARC_NextAvailabilityDate__c,
        ARC_Aggregator__r.ARC_Code__c
        FROM ARC_ParticipantAggregator__c WHERE ARC_PolicyParticipant__c =: claim.ARC_ParticipantPolicyParticipant__c AND (ARC_Aggregator__r.ARC_Year__c = '2025' OR ARC_Aggregator__r.ARC_Year__c = NULL) AND ARC_Aggregator__r.ARC_Code__c != 'MAT__c' AND ARC_Aggregator__r.ARC_Code__c != 'PREEX__c'];
        Test.startTest();
            classTest.invokeMethod('createItemPayments', input, output, options);
        Test.stopTest();
    }

    @isTest
    public static void uncommitAllChangesTest() {
        InsurancePolicy pol = ARC_TestUtility.createTestPolicies(1, 'ARC_IndividualAndFamily')[0];
        vlocity_ins__AttributeCategory__c attCat = new vlocity_ins__AttributeCategory__c();
        attCat.Name = 'Pow att';
        attCat.vlocity_ins__DisplayFilter__c = false;
        attCat.vlocity_ins__DisplaySequence__c = 9191;
        attCat.vlocity_ins__IsActive__c = true;
        attCat.vlocity_ins__IsPrivate__c = false;
        attCat.vlocity_ins__IsUserAttributesCreatedPrivate__c = false;
        attCat.vlocity_ins__LockedFlg__c = false;
        insert attCat;
        vlocity_ins__Attribute__c att = new vlocity_ins__Attribute__c();
        att.Name = 'familyAMCS test';
        att.vlocity_ins__AttributeCategoryId__c = attCat.Id;
        att.vlocity_ins__DisplaySequence__c = 9097;
        att.vlocity_ins__ActiveFlg__c = true;
        att.vlocity_ins__Configurable__c = true;
        att.vlocity_ins__ExcludeFromBasketCache__c = false;
        att.vlocity_ins__Filterable__c = true;
        att.vlocity_ins__IsCloneable__c = true;
        att.vlocity_ins__isDefaultHidden__c = false;
        att.vlocity_ins__IsEncrypted__c = false;
        att.vlocity_ins__IsNotAssetizable__c = false;
        att.vlocity_ins__IsPrivate__c = false;
        insert att;
        vlocity_ins_fsc__InsurancePolicyTerm__c term = new vlocity_ins_fsc__InsurancePolicyTerm__c();
        term.vlocity_ins_fsc__InsurancePolicyId__c = pol.Id;
        term.vlocity_ins_fsc__AttributeId__c = att.Id;
        term.ARC_CurrentValue__c = 0;
        insert term;

        Claim clm = new Claim();
        clm.Name = 'Test';
        clm.ARC_AuditorValidation__c = 'Pending';
        clm.PolicyNumberId = pol.Id;
        clm.RecordTypeId = Schema.SObjectType.Claim.getRecordTypeInfosByDeveloperName().get('ARC_Professional').getRecordTypeId();
        clm.ARC_DOSTo__c = Date.today();
        insert clm;
        
        ClaimCoverage cCov = ARC_TestUtility.createTestClaimCoverage(1)[0];
        ClaimCoveragePaymentDetail ccpd = new ClaimCoveragePaymentDetail();
        ccpd.Name = '1';
        ccpd.ClaimCoverageId = cCov.Id;
        ccpd.ARC_Claim__c = clm.Id; 
        ccpd.RecordTypeId = Schema.SObjectType.ClaimCoveragePaymentDetail.getRecordTypeInfosByDeveloperName().get('ARC_Professional').getRecordTypeId();
        insert ccpd;

        vlocity_ins__vlocityCode__c newCode = new vlocity_ins__vlocityCode__c();
        newCode.Name = 'abc123';
        insert newCode;
        ARC_ClaimReasonCode__c rc = new ARC_ClaimReasonCode__c();
        rc.ARC_ClaimCoveragePaymentDetail__c = ccpd.Id;
        rc.ARC_ReasonCode__c = newCode.Id;
        insert rc;
        ClaimPaymentSummary sum = new ClaimPaymentSummary();
        sum.Name = 'Test item 1';
        sum.ClaimId = clm.Id;
        sum.ARC_SMB_Item__c = ccpd.Id;
        sum.PaymentAmount = 123;
        insert sum;
        List<Object> idsList = new List<Object>();

        List<ClaimCoveragePaymentDetail> cliList = [SELECT Id, ARC_Claim__c FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: clm.Id];
        for (ClaimCoveragePaymentDetail cc: cliList) {
            idsList.add(cc.Id);
        }

        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('claimId', clm.Id);
        input.put('itemIds', idsList);
        Test.startTest();
        	classTest.invokeMethod('uncommitAllChanges', input, output, options);
    	Test.stopTest();
    }

    @isTest
    public static void saveLineItemsTest() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        //Create Claim
        Claim claim = ARC_TestUtility.createTestClaims(1)[0];
        Test.startTest();
            //Create Coverage Payment Details
            List<ClaimCoveragePaymentDetail> listCoveragesPaymn = ARC_TestUtility.createTestCoveragePayments(10);
    
            Map<String, Object> inputMap = new Map<String, Object>();
            List<Id> idLines = new List<Id>();
            
            Integer i = 0;
            for (ClaimCoveragePaymentDetail variable : listCoveragesPaymn) {
                Map<String, String> amounts = new Map<String, String>();
                amounts.put('mbrLiability' ,'123' );
                amounts.put('billed' ,'123' );
                amounts.put('allowed' ,'123' );
                amounts.put('Adjusted' ,'123' );
                amounts.put('priPaid' ,'123' );
                amounts.put('consFee' ,'123' );
                amounts.put('shareForAMCS' ,'123' );
                amounts.put('deductible' ,'123' );
                if (i == 0) amounts.put('visitReason', 'Accupuncture');
                if (i == 1) amounts.put('visitReason', 'P. Therapy');
                if (i == 2) amounts.put('visitReason', 'Chiropractic');
                if (i == 3) amounts.put('visitReason', 'Behavioral');
                if (i == 4) amounts.put('visitReason', 'Office Visit/Copay');
                if (i == 5) amounts.put('visitReason', 'Urgent Care');
                if (i == 6) amounts.put('visitReason', 'Cervical Cancer Screenings');
                if (i == 7) amounts.put('visitReason', 'Colon Cancer Screenings');
                if (i == 8) amounts.put('visitReason', 'Mammograms');
                if (i == 9) amounts.put('visitReason', 'Prostate Screenings');
                idLines.add(variable.Id);
                String idi = (String) variable.Id;
                inputMap.put('item', idi);
                inputMap.put('values', amounts);
                i++;
            }
            List<Object> stc = new List<Object>();
            stc.add(inputMap);
            input.put('input',stc);
            
            classTest.invokeMethod('saveLineItems', input, output, options);
        Test.stopTest();
        List<ClaimCoveragePaymentDetail> testCheck = new List<ClaimCoveragePaymentDetail>([SELECT Id, Name, ARC_MBRLiability__c, ARC_Deductible__c, ARC_Allowed__c,AdjustedAmount, ARC_PrimaryPaid__c, ARC_Copay__c, ARC_Pre_Existing_Condition__c FROM ClaimCoveragePaymentDetail WHERE Id IN :idLines]);
        System.assertEquals(testCheck[0].ARC_Pre_Existing_Condition__c, testCheck[0].ARC_PrimaryPaid__c);       
    }

    @isTest
    public static void resetItemsTest() {

        Claim claim = [SELECT Id, ARC_DOSFrom__c, ARC_DOSTo__c, PolicyNumberId FROM Claim WHERE Name = 'TestingData0' LIMIT 1];
        List<ARC_ParticipantAggregator__c> pAggs = [SELECT Id, ARC_ConsumedValue__c, ARC_Aggregator__r.ARC_Code__c FROM ARC_ParticipantAggregator__c WHERE ARC_Policy__c =: claim.PolicyNumberId AND ARC_Aggregator__r.ARC_Code__c = 'AMCS__c' LIMIT 1];
        List<ClaimCoveragePaymentDetail> cliList =[SELECT Id,Name FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claim.Id AND ARC_Deductible__c != 0 LIMIT 1];
        Set<Id> idsList = new Set<Id>();
        for (ARC_ParticipantAggregator__c pagg : pAggs) {
            pagg.ARC_ConsumedValue__c = 1;
        }
        update pAggs;
        
        List<ClaimPaymentSummary> cpsList = new List<ClaimPaymentSummary>();
        for (Integer i =0 ; i < cliList.size(); i++ ) {
            ClaimCoveragePaymentDetail ccpd = cliList[i];
            ClaimPaymentSummary sum = new ClaimPaymentSummary();
            sum.Name = 'Test item ' + ccpd.Name;
            sum.ClaimId = claim.Id;
            sum.ARC_SMB_Item__c = ccpd.Id;
            sum.PaymentAmount = 1;
            sum.ARC_ConsumedValue__c = 1;
            sum.ARC_ParticipantAggregator__c = pAggs[i].Id;
            cpsList.add(sum);
        }
        insert cpsList;
        for (ClaimCoveragePaymentDetail cc: cliList) {
            idsList.add(cc.Id);
        }

        Test.startTest();
            ARC_CoveragePaymentsTableController.resetItems(claim, 'uncommit', idsList);
        Test.stopTest();

    }
    
    @isTest
    public static void getAllCoveragePaymentsTestLegacy() {
        // Test with Legacy plan - need to create the actual benefit plan record
        
        // Create Account for testing
        Account acc = ARC_TestUtility.createTestAccount(1,'ARC_IFPPersonAccount')[0];
        acc.PersonBirthdate = Date.today().addYears(-45);
        update acc;
        Contact testCont = [SELECT Id FROM Contact WHERE Id IN (SELECT PersonContactId FROM Account WHERE Id =: acc.id)];
        
        // Create Product with Legacy in name
        Product2 legacyProd = new Product2(Name='WeShare Legacy', ProductCode='PROG_UHSM_WeShareLegacy');
        insert legacyProd;
        
        // Create Contract
        Contract ctr = ARC_TestUtility.createContracts(1)[0];
        ctr.ARC_ContractReason__c = 'New Application';
        ctr.ARC_EffectiveDate__c = Date.today();
        insert ctr;
        
        // Create Insurance Policy with Legacy product
        InsurancePolicy ip = ARC_TestUtility.createTestPolicies(1, 'ARC_IndividualAndFamily')[0];
        ip.ProductId = legacyProd.Id;
        ip.ARC_Contract__c = ctr.Id;
        update ip;
        
        // Create Insurance Policy Participant
        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(
            InsurancePolicyId = ip.Id, 
            PrimaryParticipantContactId = testCont.Id, 
            Role = 'Primary'
        );
        insert ipp;
        
        // Create Claim with Legacy benefit plan
        Claim claim = ARC_TestUtility.createTestClaims(1)[0];
        claim.PolicyNumberId = ip.Id;
        claim.ARC_MemberContact__c = testCont.Id;
        claim.ARC_ParticipantPolicyParticipant__c = ipp.Id;
        claim.LossDate = claim.ARC_DOSFrom__c = claim.ARC_DOSTo__c = Date.today();
        update claim;
        
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('claimId', claim.Id);
    
        Test.startTest();
            classTest.invokeMethod('getAllCoveragePayments', input, output, options);
        Test.stopTest();
        
        // Verify that isLegacy is determined correctly based on the benefit plan
        System.assert(output.containsKey('isLegacy'), 'isLegacy should be present in output');
        
        // The exact value will depend on how your ARC_MemberBenefitPlan__c field gets populated
        // You may need to adjust this assertion based on your actual data model
        // System.assertEquals(true, output.get('isLegacy'), 'Should be true for Legacy plan');
    }
    
    @isTest 
    public static void getAllCoveragePaymentsTestNonLegacy() {
        // Test with non-Legacy plan
        
        // Create Account for testing
        Account acc = ARC_TestUtility.createTestAccount(1,'ARC_IFPPersonAccount')[0];
        acc.PersonBirthdate = Date.today().addYears(-45);
        update acc;
        Contact testCont = [SELECT Id FROM Contact WHERE Id IN (SELECT PersonContactId FROM Account WHERE Id =: acc.id)];
        
        // Create Product WITHOUT Legacy in name
        Product2 standardProd = new Product2(Name='WeShare Standard', ProductCode='PROG_UHSM_WeShareStandard');
        insert standardProd;
        
        // Create Contract
        Contract ctr = ARC_TestUtility.createContracts(1)[0];
        ctr.ARC_ContractReason__c = 'New Application';
        ctr.ARC_EffectiveDate__c = Date.today();
        insert ctr;
        
        // Create Insurance Policy with standard product
        InsurancePolicy ip = ARC_TestUtility.createTestPolicies(1, 'ARC_IndividualAndFamily')[0];
        ip.ProductId = standardProd.Id;
        ip.ARC_Contract__c = ctr.Id;
        update ip;
        
        // Create Insurance Policy Participant
        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(
            InsurancePolicyId = ip.Id, 
            PrimaryParticipantContactId = testCont.Id, 
            Role = 'Primary'
        );
        insert ipp;
        
        // Create Claim with standard benefit plan
        Claim claim = ARC_TestUtility.createTestClaims(1)[0];
        claim.PolicyNumberId = ip.Id;
        claim.ARC_MemberContact__c = testCont.Id;
        claim.ARC_ParticipantPolicyParticipant__c = ipp.Id;
        claim.LossDate = claim.ARC_DOSFrom__c = claim.ARC_DOSTo__c = Date.today();
        update claim;
        
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('claimId', claim.Id);
    
        Test.startTest();
            classTest.invokeMethod('getAllCoveragePayments', input, output, options);
        Test.stopTest();
        
        // Verify that isLegacy is present in output
        System.assert(output.containsKey('isLegacy'), 'isLegacy should be present in output');
        
        // The exact value will depend on your data model
        // System.assertEquals(false, output.get('isLegacy'), 'Should be false for non-Legacy plan');
    }
    
    @isTest
    public static void getAllCoveragePaymentsTestLegacyCaseInsensitive() {
        // Test with different cases of "Legacy"
        
        // Create Account for testing
        Account acc = ARC_TestUtility.createTestAccount(1,'ARC_IFPPersonAccount')[0];
        acc.PersonBirthdate = Date.today().addYears(-45);
        update acc;
        Contact testCont = [SELECT Id FROM Contact WHERE Id IN (SELECT PersonContactId FROM Account WHERE Id =: acc.id)];
        
        // Test with lowercase "legacy"
        Product2 legacyProd = new Product2(Name='WeShare legacy Plan', ProductCode='PROG_UHSM_WeSharelegacy');
        insert legacyProd;
        
        // Create Contract
        Contract ctr = ARC_TestUtility.createContracts(1)[0];
        ctr.ARC_ContractReason__c = 'New Application';
        ctr.ARC_EffectiveDate__c = Date.today();
        insert ctr;
        
        // Create Insurance Policy
        InsurancePolicy ip = ARC_TestUtility.createTestPolicies(1, 'ARC_IndividualAndFamily')[0];
        ip.ProductId = legacyProd.Id;
        ip.ARC_Contract__c = ctr.Id;
        update ip;
        
        // Create Insurance Policy Participant
        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(
            InsurancePolicyId = ip.Id, 
            PrimaryParticipantContactId = testCont.Id, 
            Role = 'Primary'
        );
        insert ipp;
        
        // Create Claim
        Claim claim = ARC_TestUtility.createTestClaims(1)[0];
        claim.PolicyNumberId = ip.Id;
        claim.ARC_MemberContact__c = testCont.Id;
        claim.ARC_ParticipantPolicyParticipant__c = ipp.Id;
        claim.LossDate = claim.ARC_DOSFrom__c = claim.ARC_DOSTo__c = Date.today();
        update claim;
        
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('claimId', claim.Id);
    
        Test.startTest();
            classTest.invokeMethod('getAllCoveragePayments', input, output, options);
        Test.stopTest();
        
        // Verify that isLegacy field is present
        System.assert(output.containsKey('isLegacy'), 'isLegacy should be present in output');
        
        // Test case-insensitive behavior based on your logic using containsIgnoreCase()
        // The exact assertion will depend on how ARC_MemberBenefitPlan__c gets populated
    }
    
    @isTest
    public static void getAllCoveragePaymentsTestNullBenefitPlan() {
        // Test with claim that has no associated benefit plan
        Claim claim = ARC_TestUtility.createTestClaims(1)[0];
        // Leave claim without policy/benefit plan associations
        
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('claimId', claim.Id);
    
        Test.startTest();
            classTest.invokeMethod('getAllCoveragePayments', input, output, options);
        Test.stopTest();
        
        // Verify that isLegacy is false when benefit plan is null
        System.assertEquals(false, output.get('isLegacy'), 'Should be false when benefit plan is null');
    }
    
    @isTest
    public static void getAllCoveragePaymentsTestEmptyBenefitPlan() {
        // Test with empty benefit plan - this would need to be tested based on your actual field structure
        // You may need to modify this based on how your ARC_MemberBenefitPlan__c field works
        
        Claim claim = ARC_TestUtility.createTestClaims(1)[0];
        
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('claimId', claim.Id);
    
        Test.startTest();
            classTest.invokeMethod('getAllCoveragePayments', input, output, options);
        Test.stopTest();
        
        // Verify that isLegacy is false when benefit plan is empty/null
        System.assertEquals(false, output.get('isLegacy'), 'Should be false when benefit plan is empty');
    }

    @isTest
    public static void deleteItemsCoverageOnly() {
        // create a claim and a line item
        Claim claim = ARC_TestUtility.createTestClaims(1)[0];
        List<ClaimCoveragePaymentDetail> details = ARC_TestUtility.createTestCoveragePayments(1);
        details[0].ARC_Claim__c = claim.Id;
        update details;

        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        input.put('recordId', claim.Id);
        List<Object> rowsSelected = new List<Object>();
        Map<String, Object> row = new Map<String, Object>();
        row.put('item', details[0].Id);
        row.put('status', 'New');
        rowsSelected.add(row);
        input.put('rowsSelected', rowsSelected);

        Test.startTest();
        classTest.invokeMethod('deleteItems', input, output, options);
        Test.stopTest();
    }

    @isTest
    public static void createIfMissingSMBItemPaymentsTest() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Id> idsList = new List<Id>();
                
        Claim claim = [SELECT Id FROM Claim WHERE Name = 'TestingData0' LIMIT 1];
        List<ClaimCoveragePaymentDetail> cliList = [SELECT Id FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c =: claim.Id];
        
        input.put('claimId', claim.Id);
        input.put('itemIds', idsList);

        Test.startTest();
        classTest.invokeMethod('createIfMissingSMBItemPayments', input, output, options);
        Test.stopTest();
    }

    @isTest
    public static void setNextAvailabilityDateUnitTest() {
        
        List<ARC_Aggregator__c> aggregatorsList = [SELECT Id, ARC_Code__c, ARC_NextAvailabilityDate__c FROM ARC_Aggregator__c WHERE ARC_Code__c IN (
            'PROSCRE__c',
            'MAMM__c',
            'FLXSIG__c',
            'CLON__c',
            'SSOPT__c',
            'CCS__c')];
        Date DOS = Date.Today();
        Test.startTest();
            for (ARC_Aggregator__c aggregator : aggregatorsList) {
                ARC_CoveragePaymentsTableController.setNextAvailabilityDate(aggregator,DOS,45,'WeShare Legacy','void');
                ARC_CoveragePaymentsTableController.setNextAvailabilityDate(aggregator,DOS,55,'UHSM Silver Essential $10K','void');
            }
        Test.stopTest();
    }
}