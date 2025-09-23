@isTest
public class ARC_GetExistingEmailTest {

    @TestSetup
    public static void makeData(){

        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account testaccount = new Account(
            FirstName = 'Test',
            LastName = 'Account',
            RecordTypeId = recordTypeId,
            PersonEmail = 'testacountalreadyexist@test.com',
            Phone = '123123123'
        );
        insert testaccount;
    }

    @isTest 
    static void testGetExistingEmailTest(){ 
        ARC_GetExistingEmail test = new ARC_GetExistingEmail();
        String methodName = 'getExistingEmail';
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        inputMap.put('email', 'testacountalreadyexist@test.com');
        test.invokeMethod(methodName, inputMap, outputMap, options);


        inputMap.put('email', 'textaccountdoesnotalreadyexist@test.com');
        test.invokeMethod(methodName, inputMap, outputMap, options); 
    }
}