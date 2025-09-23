@IsTest
private class ARC_ClaimLineItemReassignmentBatchTest {

    @TestSetup
    static void setupData() {
        // Account del participante
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount', LastName ='Test');
            acc.BillingStreet = '123 Avenue';
            acc.BillingState = 'NY';
            acc.BillingCity = 'New York';
            acc.BillingPostalCode='12345';
            acc.PersonEmail='test@email.com';
            acc.ARC_IsPrimaryMember__c = true;
            acc.ARC_E123MemberIdFromPolicy__c = 'W123456789';
        insert acc;

        // insert product
        Product2 prod = new Product2();
        prod.Name = 'WeShare 6k ';
        prod.ProductCode = 'PROG_UHSM_WeShare6k';
        prod.vlocity_ins__Type__c = 'Medical';
        insert prod;

        List<Contract> contract = ARC_TestUtility.createContractsAA(1);
        insert contract;
        contract[0].Status = 'Terminated';
        contract[0].ARC_ContractReason__c = 'Program Upgrade';
        contract[0].ARC_EffectiveDate__c = Date.valueOf('2021-11-12');
        contract[0].ARC_Inactive_Date__c = Date.valueOf('2022-11-12');
        update contract;
        
        ARC_Aggregator__c amcsAgg = new ARC_Aggregator__c(
            Name = 'AMCS Agg',
            ARC_Code__c = 'AMCS__c',
            ARC_Year__c = String.valueOf(System.today().year())
        );
        ARC_Aggregator__c shamcsAgg = new ARC_Aggregator__c(
            Name = 'SHAMCS Agg',
            ARC_Code__c = 'SHAMCS__c',
            ARC_Year__c = String.valueOf(System.today().year())
        );
        insert new List<ARC_Aggregator__c>{ amcsAgg, shamcsAgg };

        // Insurance Policy
        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Test Policy ',
            ProductId = prod.Id,
            ARC_Contract__c = contract[0].Id,
            NameInsuredId = acc.Id);
        insert policy;

        // Insurance Policy Participant
        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(
            Role = 'Primary',
            PrimaryParticipantContactId = acc.PersonContactId,
            InsurancePolicyId = policy.Id
        );
        insert ipp;

        // Participant Aggregators
        ARC_ParticipantAggregator__c paAmcs = new ARC_ParticipantAggregator__c(
            ARC_Aggregator__c = amcsAgg.Id,
            ARC_Policy__c = policy.Id,
            ARC_PolicyParticipant__c = ipp.Id,
            ARC_ConsumedValue__c = 100
        );
        ARC_ParticipantAggregator__c paShamcs = new ARC_ParticipantAggregator__c(
            ARC_Aggregator__c = shamcsAgg.Id,
            ARC_Policy__c = policy.Id,
            ARC_PolicyParticipant__c = ipp.Id,
            ARC_ConsumedValue__c = 50
        );
        insert new List<ARC_ParticipantAggregator__c>{ paAmcs, paShamcs };

        // Claim
        Claim claim = new Claim(
            Name = 'Test Claim',
            PolicyNumberId = policy.Id,
            ARC_DOSFrom__c = System.today(),
            ARC_MemberContact__c = acc.PersonContactId
        );
        insert claim;

        // VlocityCode Name = '99213'
        //Create Claim + Claim Coverage Paymet Details
        List<ClaimCoveragePaymentDetail> ccpdList = ARC_TestUtility.createTestCoveragePayments(2);
        //Create Reason Code
        vlocity_ins__VlocityCode__c generalCode = new vlocity_ins__VlocityCode__c();
        generalCode.ARC_Status__c = 'Informational';
        generalCode.ARC_WPCInfoCode__c = 'CO';
        generalCode.ARC_WPCClaimEditCode__c = '99213';
        generalCode.Name = '99213';
        insert generalCode;
            
        ARC_ClaimReasonCode__c reasonCode = new ARC_ClaimReasonCode__c();
        reasonCode.ARC_ClaimCoveragePaymentDetail__c = ccpdList[0].Id;
        reasonCode.ARC_ReasonCode__c = generalCode.Id;
        insert reasonCode; 

        ccpdList[0].ARC_Claim__c = claim.Id;
        ccpdList[0].ARC_Deductible__c = 20;
        ccpdList[0].ARC_Coinsurance__c = 0;
        ccpdList[0].ARC_ProcedureCode__c = generalCode.Id;
        update ccpdList;
    }

    @IsTest
    static void testBatchReportMode() {
        Set<Id> aggIds = new Map<Id,ARC_Aggregator__c>([SELECT Id FROM ARC_Aggregator__c]).keySet();

        Test.startTest();
        Database.executeBatch(new ARC_ClaimLineItemReassignmentBatch(aggIds, false), 10);
        Test.stopTest();

        ClaimCoveragePaymentDetail smb = [
            SELECT ARC_Deductible__c, ARC_Coinsurance__c 
            FROM ClaimCoveragePaymentDetail LIMIT 1
        ];
        System.assertEquals(20, smb.ARC_Deductible__c, 'Report mode should not make changes.');
    }

    @IsTest
    static void testBatchUpdateMode() {
        Set<Id> aggIds = new Map<Id,ARC_Aggregator__c>([SELECT Id FROM ARC_Aggregator__c]).keySet();

        Test.startTest();
        Database.executeBatch(new ARC_ClaimLineItemReassignmentBatch(aggIds, true), 10);
        Test.stopTest();

        ClaimCoveragePaymentDetail smb = [
            SELECT ARC_Deductible__c, ARC_Coinsurance__c 
            FROM ClaimCoveragePaymentDetail LIMIT 1
        ];
        System.assertEquals(0, smb.ARC_Deductible__c);
        System.assertEquals(20, smb.ARC_Coinsurance__c);
    }
}