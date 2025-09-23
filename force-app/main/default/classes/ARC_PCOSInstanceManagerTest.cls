/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ARC_PCOSInstanceManagerTest {

    @isTest
    static void closePreviousInstancesTest() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();

        List<Account> accounts = ARC_TestUtility.createTestAccount(1, 'ARC_IFPPersonAccount');

        List<vlocity_ins__OmniScriptInstance__c> osInstance = ARC_TestUtility.createSavedOsFromObject(accounts, 1);

        Map<String,Object> inputMap = new Map<String,Object> {
            'ContextId' => accounts[0].Id
        };

        ARC_PCOSInstanceManager className = new ARC_PCOSInstanceManager();
        String methodName = 'closePreviousInstances';

        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
    }

    @isTest
    static void closePreviousInstancesTestCatchError() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();

        List<Account> accounts = ARC_TestUtility.createTestAccount(1, 'ARC_IFPPersonAccount');

        List<vlocity_ins__OmniScriptInstance__c> osInstance = ARC_TestUtility.createSavedOsFromObject(accounts, 1);

        Map<String,Object> inputMap = null;

        ARC_PCOSInstanceManager className = new ARC_PCOSInstanceManager();
        String methodName = 'closePreviousInstances';

        Boolean error = false;
        Test.startTest();
        try {
            className.invokeMethod(methodName, inputMap, outputMap, options);
        } catch (Exception e) {
            System.assert(e instanceof NullPointerException, 'Expected NullPointerException');
            error = true;
        }        
        Test.stopTest();
        System.assert(error);
    }
}