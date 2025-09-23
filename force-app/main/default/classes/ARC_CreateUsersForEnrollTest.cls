/*
Pre-Requisit: A System Administrator user with a role assigned must exist in the deployment environment for this test class to run successfully.  
*/

@isTest
public without sharing class ARC_CreateUsersForEnrollTest {
    
    @isTest
    static void ARC_CreateUsersForEnrollTestOne() {
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Profile p = [SELECT Name, Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = [SELECT Id FROM User WHERE ProfileId =: p.Id AND UserRoleId <> null AND isActive = true LIMIT 1];
        
        List<Account> accList = ARC_TestUtility.createTestAccount(1,'StandardAccount');
        List<Contact> cont = ARC_TestUtility.createTestContact(2, 'Contact');
        List<vlocity_ins__GroupCensusMember__c> censusMember = ARC_TestUtility.createTestCensusMember(1);
        cont[0].accountId = accList[0].Id;
        update cont;
        accList[0].OwnerId = adminUser.Id;
        update accList;
        censusMember[0].vlocity_ins__IsPortalUser__c = true;
        censusMember[0].vlocity_ins__LastName__c = 'TestLastName';
        censusMember[0].vlocity_ins__FirstName__c ='TestFirstName';
        censusMember[0].vlocity_ins__Email__c='testcensusmemberemail@test.com';
        censusMember[0].vlocity_ins__ContactId__c = cont[0].id;
        update censusMember;
        
        String methodName = 'createUsers';
        inputMap.put('censusId', censusMember[0].vlocity_ins__CensusId__c); 
        inputMap.put('accountId', censusMember[0].vlocity_ins__AccountId__c);
        ARC_CreateUsersForEnroll className = new ARC_CreateUsersForEnroll();
        
        
        Test.startTest();
        	className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        System.assert(true, outputMap.get('primaryMember') <> null);
    }
    
    @isTest
    static void ARC_CreateUsersForEnrollTestTwo() {
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Profile p = [SELECT Name, Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = [SELECT Id FROM User WHERE ProfileId =: p.Id AND UserRoleId <> null AND isActive = true LIMIT 1];
        
        List<Account> accList = ARC_TestUtility.createTestAccount(1,'StandardAccount');
        List<Contact> cont = ARC_TestUtility.createTestContact(1, 'Contact');
        List<vlocity_ins__GroupCensusMember__c> censusMember = ARC_TestUtility.createTestCensusMember(1);
        censusMember[0].vlocity_ins__IsPortalUser__c = true;
        censusMember[0].vlocity_ins__LastName__c = 'TestLastName';
        censusMember[0].vlocity_ins__FirstName__c ='TestFirstName';
        censusMember[0].vlocity_ins__Email__c='testcensusmemberemail@test.com';
        censusMember[0].vlocity_ins__ContactId__c = cont[0].id;
        update censusMember;
        
        String methodName = 'createUsers';
        inputMap.put('censusId', censusMember[0].vlocity_ins__CensusId__c); 
        inputMap.put('accountId', censusMember[0].vlocity_ins__AccountId__c);
        ARC_CreateUsersForEnroll className = new ARC_CreateUsersForEnroll();
        
        Test.startTest();
       		className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        System.assert(true, outputMap.get('primaryMember') == null);
    }
}