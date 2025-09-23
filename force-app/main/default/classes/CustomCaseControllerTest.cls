@isTest
public class CustomCaseControllerTest {
    
    @testSetup
    static void setup() {
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
        Account personAcc = [SELECT Id, PersonContactId FROM Account WHERE Id =:acc.Id];
        List <vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(1);
        censusMemberList[0].vlocity_ins__ContactId__c = personAcc.PersonContactId;
        censusMemberList[0].vlocity_ins__SocialSecurityNumber__c = '123456789';
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpToInsert = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        for(Integer i=0; i<4; i++ ){
            vlocity_ins__GroupCensusMemberPlan__c memberplan = new vlocity_ins__GroupCensusMemberPlan__c();
            memberplan.Name = 'Holi';
            memberplan.vlocity_ins__GroupCensusMemberId__c = censusMemberList[0].Id;
            gcmpToInsert.add(memberplan);
        }
        update censusMemberList;
        insert gcmpToInsert;

        Product2 product6k = new Product2();
        product6k.Name = 'WeShare 6k';
        product6k.ProductCode = 'CS_FinanceVisitsFramework';
        product6k.vlocity_ins__Type__c = 'Medical';
        product6k.ProductCode = 'PROG_UHSM_WeShare6k';
        insert product6k;

        Product2 product3k = new Product2();
        product3k.Name = 'WeShare 3k';
        product3k.ProductCode = 'CS_FinanceVisitsFramework';
        product3k.vlocity_ins__Type__c = 'Medical';
        product3k.ProductCode = 'PROG_UHSM_WeShare3k';
        insert product3k;

        Product2 product12k = new Product2();
        product12k.Name = 'WeShare 12k';
        product12k.ProductCode = 'CS_FinanceVisitsFramework';
        product12k.vlocity_ins__Type__c = 'Medical';
        product12k.ProductCode = 'PROG_UHSM_WeShare12k';
        insert product12k;

        Product2 smartProduct = new Product2();
        smartProduct.Name = 'Smart';
        smartProduct.vlocity_ins__Type__c = 'Ancillary';
        smartProduct.ProductCode = 'PROG_UHSM_WeShare12k';
        insert smartProduct;

        List<vlocity_ins__GroupCensusMember__c> censusData =[SELECT vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c];
        acc.Census_Member__c = censusMemberList[0].Id;
        acc.ARC_Census__c = censusData[0].vlocity_ins__CensusId__c;
        update acc;

        List<Contract> contracts = ARC_TestUtility.createContractsAA(4);
        Contract cont1 = contracts[0];
        cont1.vlocity_ins__EnrollmentCensusId__c = censusMemberList[0].vlocity_ins__CensusId__c;
        cont1.ARC_EffectiveDate__c = Date.newInstance(2022, 2, 15);
        cont1.ARC_Inactive_Date__c = Date.newInstance(2023, 1, 30);
        cont1.AccountId = acc.Id;
        cont1.ARC_ContractReason__c = 'New Application';
        cont1.Status = 'Draft';
        insert cont1;

        Contract cont2 = contracts[1];
        cont2.vlocity_ins__EnrollmentCensusId__c = censusMemberList[0].vlocity_ins__CensusId__c;
        cont2.ARC_EffectiveDate__c = Date.newInstance(2023, 2, 1);
        cont2.ARC_Inactive_Date__c = Date.newInstance(2023, 6, 30);
        cont2.AccountId = acc.Id;
        cont2.ARC_ContractReason__c = 'Program Downgrade';
        cont2.vlocity_ins__ExpiredContractId__c = cont1.Id;
        cont2.Status = 'Draft';
        insert cont2;

        Contract cont3 = contracts[2];
        cont3.vlocity_ins__EnrollmentCensusId__c = censusMemberList[0].vlocity_ins__CensusId__c;
        cont3.ARC_EffectiveDate__c = Date.newInstance(2023, 2, 1);
        cont3.ARC_Inactive_Date__c = Date.newInstance(2023, 7, 31);
        cont3.AccountId = acc.Id;
        cont3.ARC_ContractReason__c = 'Program Downgrade';
        cont3.Status = 'Draft';
        insert cont3;

        Contract cont4 = contracts[3];
        cont4.vlocity_ins__EnrollmentCensusId__c = censusMemberList[0].vlocity_ins__CensusId__c;
        cont4.ARC_EffectiveDate__c = Date.newInstance(2024, 1, 1);
        cont4.AccountId = acc.Id;
        cont4.ARC_ContractReason__c = 'Program Upgrade';
        cont4.Status = 'Draft';
        insert cont4;

        List<vlocity_ins__ContractLineItem__c> cli =ARC_TestUtility.createTestContractLineItem(5);
        cli[0].vlocity_ins__ContractId__c = cont1.Id;
        cli[0].vlocity_ins__Product2Id__c = product6k.Id;
        cli[1].vlocity_ins__ContractId__c = cont2.Id;
        cli[1].vlocity_ins__Product2Id__c = product12k.Id;
        cli[2].vlocity_ins__ContractId__c = cont3.Id;
        cli[2].vlocity_ins__Product2Id__c = product3k.Id;
        cli[3].vlocity_ins__ContractId__c = cont4.Id;
        cli[3].vlocity_ins__Product2Id__c = product6k.Id;
        cli[4].vlocity_ins__ContractId__c = cont2.Id;
        cli[4].vlocity_ins__Product2Id__c = smartProduct.Id;
        update cli;

        for(Integer i=0; i<4; i++){            
            gcmpToInsert[i].vlocity_ins__ContractLineId__c = cli[i].Id;
        }
        update gcmpToInsert;

        cont1.Status = 'Terminated';
        cont2.Status = 'Terminated';

        update cont1;
        update cont2;

   
        DATE TODAY = system.today();

     	system.debug('acc.Census_Member__c='+acc.Census_Member__c);
        system.debug('acc.Id='+acc.Id);
	
        // Create test Case records
        Case unappealedCase = new Case(Status = 'New', Description='TestunappealedCase', 
                                       Subject = 'TestunappealedCase082624', ARC_CensusMember__c = acc.Census_Member__c,
                                       Member__c = acc.Id, ARC_Contract__c = cont1.Id,
                                       ARC_Appealed__c = null);
        insert unappealedCase;
        
        Case appealedCase = new Case(Status = 'New', Description='Test',
                                     Subject = 'Test', ARC_CensusMember__c = acc.Census_Member__c,
                                     Member__c = acc.Id, ARC_Contract__c = cont2.Id,
                                     ARC_Appealed__c = TODAY);
        insert appealedCase;

        // Create test ARC_UnderwritingCaseMember__c records
        ARC_UnderwritingCaseMember__c pendingMember = new ARC_UnderwritingCaseMember__c(
            ARC_ApprovalResolution__c = 'Pending',
            ARC_Member__c = acc.Census_Member__c,
            ARC_Contract__c = cont1.Id,
            ARC_UnderwritingCase__c = unappealedCase.Id
        );
        insert pendingMember;
        
        ARC_UnderwritingCaseMember__c deniedMember = new ARC_UnderwritingCaseMember__c(
            ARC_ApprovalResolution__c = 'Rejected',
            ARC_Member__c = acc.Census_Member__c,
            ARC_Contract__c = cont2.Id,
            ARC_UnderwritingCase__c = appealedCase.Id
        );
        insert deniedMember;
        
        ARC_UnderwritingCaseMember__c approvedMember = new ARC_UnderwritingCaseMember__c(
            ARC_ApprovalResolution__c = 'Approved',
            ARC_Member__c = acc.Census_Member__c,
            ARC_Contract__c = cont2.Id,
            ARC_UnderwritingCase__c = appealedCase.Id
        );
        insert approvedMember;
        
        ARC_UnderwritingCaseMember__c pendingMember2 = new ARC_UnderwritingCaseMember__c(
            ARC_ApprovalResolution__c = 'Pending',
            ARC_Member__c = acc.Census_Member__c,
            ARC_Contract__c = cont2.Id,
            ARC_UnderwritingCase__c = appealedCase.Id
        );
        insert pendingMember2;
    }
    
    @isTest
    static void testUnappealedCase() {
        // Retrieve a Case record with ARC_Appealed__c = null
        Case unappealedCase = [SELECT Id FROM Case WHERE Subject = 'TestunappealedCase082624' LIMIT 1];

        // Set up the controller with the unappealed case Id
        ApexPages.currentPage().getParameters().put('id', unappealedCase.Id);
        CustomCaseController controller = new CustomCaseController();
        
        // Verify that only Pending members are returned
        System.assertEquals(1, controller.caseMembers.size(), 'There should be 1 pending member for unappealed case.');
        System.assertEquals('Pending', controller.caseMembers[0].ARC_ApprovalResolution__c);
    }
    
    @isTest
    static void testAppealedCase() {
        // Retrieve a Case record with ARC_Appealed__c = true
		
        Case appealedCase = [SELECT Id FROM Case WHERE ARC_Appealed__c <> null LIMIT 1];
        
        // Set up the controller with the appealed case Id
        ApexPages.currentPage().getParameters().put('id', appealedCase.Id);
        CustomCaseController controller = new CustomCaseController();
        
        // Verify that both Pending and Denied members are returned
        System.assertEquals(2, controller.caseMembers.size(), 'There should be 2 members for appealed case (Pending and Rejected).');
        
        // Check for specific statuses
        Set<String> expectedStatuses = new Set<String>{'Pending', 'Rejected'};
        for (ARC_UnderwritingCaseMember__c member : controller.caseMembers) {
            System.assert(expectedStatuses.contains(member.ARC_ApprovalResolution__c), 'Member status should be Pending or Rejected.');
        }
    }
}