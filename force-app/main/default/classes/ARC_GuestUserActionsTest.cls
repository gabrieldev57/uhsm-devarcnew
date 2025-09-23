@isTest
public with sharing class ARC_GuestUserActionsTest {
    
    //createUpdateSObject
    @isTest
    public static void createSObjectTest() {

        String methodName = 'createUpdateSObject';
        String createObject = 'Account';
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        inputMap.put('Object', createObject);
        inputMap.put('Name', 'Account + 1');

        ARC_GuestUserActions guestUserAction = new ARC_GuestUserActions();
        guestUserAction.invokeMethod(methodName, inputMap, outputMap, options);

        String queryStr='SELECT Id FROM ' + createObject;
        List<SObject> sObjectList = new List<SObject>();
        sObjectList = Database.query(queryStr);

        System.assertEquals(1, sObjectList.size(), 'SObject Created');
    }

    @isTest
    public static void createNoRequiredFieldSObjectTest() {

        String methodName = 'createUpdateSObject';
        String createObject = 'Account';
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        inputMap.put('Object', createObject);

        ARC_GuestUserActions guestUserAction = new ARC_GuestUserActions();
        Test.startTest();
        guestUserAction.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        String queryStr='SELECT Id FROM ' + createObject;
        List<SObject> sObjectList = new List<SObject>();
        sObjectList = Database.query(queryStr);

        System.assert(String.isNotEmpty((String)outputMap.get('result')), 'Exception thrown due to required fields missing');
        System.assertEquals(0, sObjectList.size(), 'No object created');
    }

    @isTest
    public static void createInvalidFieldSObjectTest() {

        String methodName = 'createUpdateSObject';
        String createObject = 'Account';
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        inputMap.put('Object', createObject);
        inputMap.put('Name', 'Account + 1');
        inputMap.put('InexistentField', 'Account + 1');

        ARC_GuestUserActions guestUserAction = new ARC_GuestUserActions();
        Test.startTest();
        guestUserAction.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        String queryStr='SELECT Id FROM ' + createObject;
        List<SObject> sObjectList = new List<SObject>();
        sObjectList = Database.query(queryStr);

        System.assert(String.isNotEmpty((String)outputMap.get('field error')), 'Exception thrown due to invalid field');
    }

    @isTest
    public static void updateSObjectTest() {

        String methodName = 'createUpdateSObject';
        String createObject = 'Account';
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        Account account = new Account(Name = 'Account1');
        insert account;

        inputMap.put('Object', createObject);
        inputMap.put('Id', account.Id);
        

        ARC_GuestUserActions guestUserAction = new ARC_GuestUserActions();
        Test.startTest();
        guestUserAction.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        String queryStr='SELECT Id FROM ' + createObject;
        List<SObject> sObjectList = new List<SObject>();
        sObjectList = Database.query(queryStr);

        System.assertEquals(1,sObjectList.size(), 'SObject Updated');
    }

    //invalid methodName
    @isTest
    public static void invalidMethodName() {

        String methodName = null;
        String createObject = 'Account';
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        Account account = new Account(Name = 'Account1');
        insert account;

        inputMap.put('Object', createObject);
        inputMap.put('Id', account.Id);
        

        ARC_GuestUserActions guestUserAction = new ARC_GuestUserActions();
        Test.startTest();
        guestUserAction.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        String queryStr='SELECT Id FROM ' + createObject;
        List<SObject> sObjectList = new List<SObject>();
        sObjectList = Database.query(queryStr);

        System.assert(String.isNotEmpty((String)outputMap.get('Error:')), 'Invalid methodName Error');
        System.assert((Integer)outputMap.get('Line:') > 0, 'Invalid methodName Line error');
    }


    //readSObject
    @isTest
    public static void readSingleSObjectTest() {

        Account acc = new Account(Name = 'Acc1');
        insert acc;

        String methodName = 'readSObject';
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        inputMap.put('Object', 'Account');
        inputMap.put('Fields', 'Name,Id');

        ARC_GuestUserActions guestUserAction = new ARC_GuestUserActions();
        guestUserAction.invokeMethod(methodName, inputMap, outputMap, options);

    }

    @isTest
    public static void readMultipleSObjectTest() {

        List<Account> listAcc = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            Account acc = new Account(Name = 'Acc' + i );
            listAcc.add(acc);
        }
        insert listAcc;

        String methodName = 'readSObject';
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        
        inputMap.put('Object', 'Account');
        inputMap.put('Fields', 'Name,Id');

        ARC_GuestUserActions guestUserAction = new ARC_GuestUserActions();
        guestUserAction.invokeMethod(methodName, inputMap, outputMap, options);

    }
}