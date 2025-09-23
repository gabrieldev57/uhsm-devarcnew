@isTest
public with sharing class ARC_ReadPicklistValuesTest {
    @isTest
    static void ARC_ReadPicklistValuesTest() {
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('object','ARC_ExternalInsurancePolicy__c');
        inputMap.put('field','ARC_SourceOfCoverage__c');
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_ReadPicklistValues classInstance = new ARC_ReadPicklistValues();

        classInstance.invokeMethod(
            'returnPicklistValuesAsAList',
            inputMap,
            outMap,
            options
        );
    }
}