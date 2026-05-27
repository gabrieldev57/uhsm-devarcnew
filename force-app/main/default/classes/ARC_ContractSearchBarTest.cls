@isTest
public class ARC_ContractSearchBarTest {

    @isTest  
    static void getContractbyCensusMemberTest() {
        List<Contract> enrollmentData = ARC_TestUtility.createCompleteEnrollments(1);
        Contract contractTest = [SELECT ContractNumber, vlocity_ins__EnrollmentCensusId__c, vlocity_ins__EnrollmentCensusId__r.Id, AccountId, Status
                                 FROM Contract 
                                 WHERE Id = :enrollmentData[0].Id][0];
        contractTest.Status = 'Awaiting Signature';
        contractTest.ARC_PaidThroughDate__c = Date.today();
        contractTest.ARC_Inactive_Date__c = Date.today();
        update contractTest;

        List<vlocity_ins__GroupCensusMember__c> gcm = [SELECT Id FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c = :contractTest.vlocity_ins__EnrollmentCensusId__c];

        // Create the contract with the Spin Off reason
        Contract spinOffContract = new Contract(
            ContractTerm = 12,
            ARC_Selling_Agent__c = UserInfo.getUserId(),
            AccountId = contractTest.AccountId,
            StartDate = Date.today(),
            // ARC_RecurringMonthlyOrder__c = ordList[i].Id,
            vlocity_ins__EnrollmentCensusId__c = contractTest.vlocity_ins__EnrollmentCensusId__r.Id,
            ARC_ContractReason__c = 'Spin Off'
        );

        insert spinOffContract;
        Contract anotherContract = new Contract(
            ContractTerm = 12,
            ARC_Selling_Agent__c = UserInfo.getUserId(),
            AccountId = contractTest.AccountId,
            StartDate = Date.today(),
            // ARC_RecurringMonthlyOrder__c = ordList[i].Id,
            vlocity_ins__EnrollmentCensusId__c = contractTest.vlocity_ins__EnrollmentCensusId__r.Id,
            ARC_ContractReason__c = 'Spin Off',
            Status = 'Draft',
            vlocity_ins__ExpiredContractId__c = contractTest.Id
        );
        insert anotherContract;

        // Create the Contract Participant record
        ARC_ContractParticipant__c contractParticipantTest = new ARC_ContractParticipant__c(
            ARC_Contract__c = spinOffContract.Id,
            ARC_PersonAccount__c = contractTest.AccountId
        );

        insert contractParticipantTest;   
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId(); 
        Account accChild = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount Child ', LastName ='Test');
            accChild.BillingStreet = '123 Avenue';
            accChild.BillingState = 'NY';
            accChild.BillingCity = 'New York';
            accChild.BillingPostalCode='12345';
            accChild.PersonEmail='test@email.com';
            accChild.ARC_IsPrimaryMember__c = false;
            accChild.ARC_E123MemberIdFromPolicy__c = 'W123456789';
            accChild.ARC_ContinuousMembershipStartDate__c = Date.Today().addYears(-1);
            accChild.IsActive = true;
            accChild.ARC_GroupAccount__c = contractTest.AccountId;
            accChild.ARC_DependentRelationship__c = 'Temporary Newborn'; 
        insert accChild;
        Account accChildRetrieve = [SELECT Id, PersonContactId FROM Account WHERE Id = :accChild.Id];
            vlocity_ins__GroupCensusMember__c censusMemberChild = new vlocity_ins__GroupCensusMember__c();
            censusMemberChild.Name = 'Test Census Member Child ';
            censusMemberChild.vlocity_ins__FirstName__c = 'Test';
            censusMemberChild.vlocity_ins__LastName__c = 'Census Member Child ' ;
            censusMemberChild.vlocity_ins__CensusId__c = contractTest.vlocity_ins__EnrollmentCensusId__c;
            censusMemberChild.vlocity_ins__ContactId__c = accChildRetrieve.PersonContactId;
            censusMemberChild.vlocity_ins__SocialSecurityNumber__c = '123456789';
            censusMemberChild.ARC_PhysicalAddressStreet__c = '123 Avenue';
            censusMemberChild.ARC_PhysicalAddressCity__c = 'New York';
            censusMemberChild.ARC_PhysicalAddressState__c = 'NY';
            censusMemberChild.ARC_PhysicalAddressZipCode__c = '12345';
            censusMemberChild.ARC_DependentRelationship__c = 'Temporary Newborn';
        insert censusMemberChild;
        vlocity_ins__ContractLineItem__c cliRetrieved = [SELECT Id FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__ContractId__c = :contractTest.Id ];
        vlocity_ins__GroupCensusMemberPlan__c gcmpChild = new vlocity_ins__GroupCensusMemberPlan__c();
            gcmpChild.vlocity_ins__ContractLineId__c = cliRetrieved.Id;
            gcmpChild.vlocity_ins__GroupCensusMemberId__c = censusMemberChild.Id;
        insert gcmpChild;
        List<Map<String,Object>> output_scenario1 = new List<Map<String,Object>>();
        List<Map<String,Object>> output_scenario2 = new List<Map<String,Object>>();

        Test.startTest();
            output_scenario1 = ARC_ContractSearchBar.getContracts360(contractTest.ContractNumber, gcm[0].Id);
            output_scenario2 = ARC_ContractSearchBar.getContracts360(contractTest.ContractNumber, contractTest.AccountId);
        Test.stopTest();
    }
}