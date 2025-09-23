@isTest
public with sharing class ARC_GetCommunityURLTest {

    @isTest
    public static void ARC_GetCommunityURLTest() {
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        String methodName = 'getCommunityURL';

        ARC_GetCommunityURL testClass = new ARC_GetCommunityURL();
        testClass.invokeMethod(methodName, inputMap, outputMap, options);
    }



    @isTest
    public static void testGetOrganizationData() {
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        String methodName = 'getOrganizationData';

        ARC_GetCommunityURL testClass = new ARC_GetCommunityURL();
        testClass.invokeMethod(methodName, inputMap, outputMap, options);
    }
}