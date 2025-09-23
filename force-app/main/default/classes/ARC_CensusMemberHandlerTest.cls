@isTest
public with sharing class ARC_CensusMemberHandlerTest {
    @isTest
    static void testBatchCensusMember(){
        vlocity_ins__GroupCensusMember__c censusMember = ARC_TestUtility.createTestCensusMember(1)[0];
        censusMember.ARC_Phone__c = '1023456789';
        Test.startTest();
		update censusMember;
        Test.stopTest();
    }
    
    @isTest
    static void testBatchCensusMemberTwo(){
        Contact cont = new Contact(FirstName = 'Jack', LastName = 'Sparrow', Email = 'testemailcensusmember@membertest.com');
        insert cont; 
        vlocity_ins__GroupCensusMember__c censusMember = ARC_TestUtility.createTestCensusMember(1)[0];
        censusMember.vlocity_ins__ContactId__c = cont.Id;
        censusMember.ARC_Phone__c = '2563253589';
        update censusMember;
        Integer afterInvocations;
        Integer beforeInvocations = Limits.getEmailInvocations();

        Test.startTest();
        censusMember.ARC_Phone__c = '2554746589';
        update censusMember;
        Test.stopTest();
    }

}