@isTest
public with sharing class aRC_JsonTreeControllerTest {
    @isTest
    public static void getJSONInputTest() {
        
        ARC_ClaimInput__c cInput = new ARC_ClaimInput__c();
        cInput.ARC_InputJSON__c = '{}';
        cInput.ARC_ExternalId__c = 'test';
        insert cInput;
        
        Claim clm = ARC_TestUtility.createTestClaims(1)[0];
        clm.ARC_ClaimInput__c = cInput.Id;
        update clm;
        
        Claim output = aRC_JsonTreeController.getJSONInput(clm.Id);
        System.assertEquals('{}', output.ARC_InputJSON__c);
    }
}