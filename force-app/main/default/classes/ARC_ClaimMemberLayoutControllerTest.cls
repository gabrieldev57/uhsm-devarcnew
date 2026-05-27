@isTest
public with sharing class ARC_ClaimMemberLayoutControllerTest {

    @isTest
    public static void testMethods() {
        vlocity_ins__GroupCensusMember__c cm = ARC_TestUtility.createTestCensusMember(1)[0];
        Claim clm = ARC_TestUtility.createTestClaims(1)[0];
        InsurancePolicy pol = ARC_TestUtility.createTestPolicies(1, 'ARC_IndividualAndFamily')[0];
        Contract cont = ARC_TestUtility.createContractsAA(1)[0];
        InsurancePolicyParticipant polPart = ARC_TestUtility.createTestPolicyParticipant(1)[0];
        Contact con = ARC_TestUtility.createTestContact(1, 'Contact')[0];

        vlocity_ins__GroupCensusMember__c anotherCM = ARC_TestUtility.createTestCensusMember(1)[0];
        anotherCM.Name = 'Another CensusMember';
        update anotherCM;

        cont.vlocity_ins__EnrollmentCensusId__c = cm.vlocity_ins__CensusId__c;
        cont.ARC_EffectiveDate__c = Date.newInstance(2023, 1, 1);
        insert cont;
        cont.ARC_ContractReason__c = 'New Application';
        cont.Status = 'Activated';
        update cont;
        
        pol.ARC_Contract__c = cont.Id;
        clm.ARC_DOSFrom__c = Date.newInstance(2023, 1, 2);
        clm.ARC_DOSTo__c = Date.newInstance(2023, 1, 2);
        polPart.InsurancePolicyId = pol.Id;
        cm.vlocity_ins__ContactId__c = con.Id;
        polPart.PrimaryParticipantContactId = con.Id;
        con.ARC_CensusMember__c = cm.Id;

        update cm;
        update clm;
        update pol;
        insert polPart;
        update con;

        ARC_ClaimMemberLayoutController.getPolicyParticipants('Member', Date.newInstance(1960, 2, 17), 'PO BOX 671244', Date.newInstance(2023, 5, 17), Date.newInstance(2023, 5, 17) );
        ARC_ClaimMemberLayoutController.selectPolParticipant(String.valueOf(clm.Id), String.valueOf(polPart.Id));
        ARC_ClaimMemberLayoutController.resetPatient(String.valueOf(clm.Id));       
        ARC_ClaimMemberLayoutController.policyAssignment(String.valueOf(cm.Id), String.valueOf(pol.Id), String.valueOf(clm.Id));
    }
}