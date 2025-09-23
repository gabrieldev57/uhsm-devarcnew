@isTest
public with sharing class ARC_MemberJSONControllerTest {

    @TestSetup
    static void mockData() {

        Claim cTest =  ARC_TestUtility.createTestClaims(1)[0];
        cTest.Name = 'ExampleWithJson';
        cTest.ARC_SubmitterJSON__c = '{"NameTest":"OneTestName","LastNameTest":"OneLastName"}';
        cTest.ARC_ServiceFacility__c = '{"AgeTest":"50","AnotherField":"null"}';
        //cTest.ARC_ReferringProvider__c ='{"ProviderNameTest":"SomeName","Addres":{"Street":"Example Street", "Number":"1234", "ZipCode":"11200"}}';
        cTest.ARC_ReferringProvider__c ='{"ProviderNameTest":"SomeName","Addres":"Example Street 1234"}';
        cTest.ARC_PatientJSON__c = '{"SimpleField":"Write something","AnotherField":"null", "LastField":"Write another thing"}';
        update cTest;
    }
    
    @isTest
    public static void testGetJsonFieldsFromClaim() {

        Claim claimTest = [SELECT Id FROM Claim WHERE Name = 'ExampleWithJson' LIMIT 1];
        test.startTest();
        List<Map<String,String>> result = ARC_MemberJSONController.getJSONFields(claimTest.Id);
        test.stopTest();
        System.debug(result);
    }
}