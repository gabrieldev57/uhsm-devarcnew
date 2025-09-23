@isTest
public with sharing class ARC_CheckForDuplicateClaimHandlerTest {

    @isTest
    public static void CheckForDuplicateClaimTest() {
        InsurancePolicy testPolicy = ARC_TestUtility.createTestPolicies(1)[0];
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

        Test.startTest();
            ARC_CheckForDuplicateClaimHandler.CheckForDuplicateClaim(new List<Id>{claim2.Id});
            ARC_CheckForDuplicateClaimHandler.CheckForDuplicateClaim(new List<Id>{claim3.Id});
        Test.stopTest();
    }  
 
}