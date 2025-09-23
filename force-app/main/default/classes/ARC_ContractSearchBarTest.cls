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

        // Create the Contract Participant record
        ARC_ContractParticipant__c contractParticipantTest = new ARC_ContractParticipant__c(
            ARC_Contract__c = spinOffContract.Id,
            ARC_PersonAccount__c = contractTest.AccountId
        );

        insert contractParticipantTest;            

        List<Map<String,Object>> output_scenario1 = new List<Map<String,Object>>();
        List<Map<String,Object>> output_scenario2 = new List<Map<String,Object>>();

        Test.startTest();
            output_scenario1 = ARC_ContractSearchBar.getContracts360(contractTest.ContractNumber, gcm[0].Id);
            output_scenario2 = ARC_ContractSearchBar.getContracts360(contractTest.ContractNumber, contractTest.AccountId);
        Test.stopTest();
    }
}