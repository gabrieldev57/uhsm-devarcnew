@isTest
public with sharing class ARCRenderingProviderJSONViewerContTest {
    @TestSetup
    static void mockData() {

        Contact conTest =  ARC_TestUtility.createTestContact(1, 'Provider')[0];
        conTest.ARC_RenderingProviderJSON__c ='{"ProviderNameTest":"SomeName","Addres":"Example Street 1234"}';
        //accTest.ARC_RenderingProviderJSON__c ='{"ProviderNameTest":"SomeName","Addres":{"Street":"Example Street", "Number":"1234", "ZipCode":"11200"}}';
        update conTest;
    }
    
    @isTest
    public static void testRenderingProviderJSON() {

        Contact conTest = [SELECT Id FROM Contact LIMIT 1];
        test.startTest();
        Map<String,String> result = ARCRenderingProviderJSONViewerController.getRenderingProviderJSON(conTest.Id);
        test.stopTest();
        System.debug(result);
    }
    
}