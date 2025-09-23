@isTest
public with sharing class ARC_ProviderJSONViewerControllerTest {

    @TestSetup
    static void mockData() {

        //Account accTest =  ARC_TestUtility.createTestAccount(1, 'Attending_Provider')[0];
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Attending_Provider').getRecordTypeId();
        Account a = new Account();
        a.RecordTypeId = recordTypeId;
        a.LastName = 'Test 1';
        insert a;
       
        a.ARC_RenderingProviderJSON__pc ='{"ProviderNameTest":"SomeName","Addres":"Example Street 1234"}';
        //accTest.ARC_BillingProviderJSON__c ='{"ProviderNameTest":"SomeName","Addres":{"Street":"Example Street", "Number":"1234", "ZipCode":"11200"}}';
        update a;
    }
    
    @isTest
    public static void testGetProviderJSON() {

        Account accTest = [SELECT Id FROM Account LIMIT 1];
        test.startTest();
        Map<String,String> result = ARC_ProviderJSONViewerController.getProviderJSON(accTest.Id);
        test.stopTest();
        System.debug(result);
    }

}