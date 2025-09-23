@isTest 
public without sharing class ARC_EncryptCensusAndAccountTest {

    @isTest 
    static void ARC_EncryptCensusAndAccountTestOne() {
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        List<vlocity_ins__GroupCensusMember__c> censusMember = ARC_TestUtility.createTestCensusMember(1);
        String methodName = 'ARC_EncryptCensusAndAccount';
        String beforeCensusId = censusMember[0].vlocity_ins__CensusId__c;
        inputMap.put('CensusId',beforeCensusId);  
        ARC_EncryptCensusAndAccount className = new ARC_EncryptCensusAndAccount();
            
        Test.startTest();
            className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        
        System.AssertEquals(false, beforeCensusId == (String)outputMap.get('CensusId'));
    }
}