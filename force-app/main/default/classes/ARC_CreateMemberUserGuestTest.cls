@isTest
private class ARC_CreateMemberUserGuestTest {

    @TestSetup
    static void makeData(){

        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Integer counter = 0;
        for(Integer i=0; i<2;i++){
            Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount'+i, LastName ='Test');
            acc.BillingStreet = '123 Avenue';
            acc.BillingState = 'NY';
            acc.BillingCity = 'New York';
            acc.BillingPostalCode='12345';
            acc.PersonEmail='test@email.com'+counter;
            acc.vlocity_ins__Email__c='test@email.com'+counter;
            acc.FirstName='Portal';
            acc.LastName='User';
            acc.PersonBirthdate=Date.newInstance(1994,12,07);
            acc.ARC_IsPrimaryMember__c = true;
            acc.Phone = '123456789';
            
            accList.add(acc);
        }
        insert accList;

        List <vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(2);
        counter = 0;
        List<Account> perAccList = [SELECT Id, PersonContactId FROM Account];
        for(vlocity_ins__GroupCensusMember__c censusMember: censusMemberList){
            censusMember.vlocity_ins__ContactId__c = perAccList[counter].PersonContactId;
            censusMember.vlocity_ins__SocialSecurityNumber__c = '123456789';
            censusMember.vlocity_ins__FirstName__c = 'Portal';
            censusMember.vlocity_ins__LastName__c = 'User';
            counter++;
        }
        update censusMemberList;

        List<vlocity_ins__GroupCensusMember__c> censusData =[SELECT vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c];
        accList[0].Census_Member__c = censusMemberList[0].Id;
        accList[1].Census_Member__c = censusMemberList[1].Id;
        accList[0].ARC_Census__c = censusData[0].vlocity_ins__CensusId__c;
        accList[1].ARC_Census__c = censusData[1].vlocity_ins__CensusId__c;
        update accList;

    }

    @isTest
    static void ARC_CreateMemberUserGuestTest() {        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Account acc2 = new Account(Name = 'Test Account2');
        insert acc2;
        Contact cont = new Contact(AccountId = acc.ID, LastName = 'Testcont', Email = 'testcont@test.com');
        insert cont;
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();        
        inputMap.put('firstName','Test');
        inputMap.put('lastName','Test');
        inputMap.put('email', 'test@test.com');
        inputMap.put('street', 'Testst.');
        inputMap.put('state', 'tests');
        inputMap.put('city', 'testc');
        inputMap.put('zipCode', '12100');
        inputMap.put('accountId', acc.Id);
        inputMap.put('referral', acc2.Id);

        String invokeMethod = 'CreateMemberUserAndAccount';
        ARC_CreateMemberUserGuest classname = new ARC_CreateMemberUserGuest();
        Test.startTest();
        classname.invokeMethod(invokeMethod, inputMap, outputMap, options);
        Test.stopTest();

    }
    
    @isTest
    static void ARC_CreateMemberUserGuestTestTwo() {  
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>(); 

        Account acc2 = new Account(Name = 'Test Account2');
        insert acc2;
        
        Profile p = [SELECT Name, Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = [SELECT Id, UserName FROM User WHERE ProfileId =: p.Id AND UserRoleId <> null AND isActive = true LIMIT 1];
        PageReference pageref = new PageReference('https://test.salesforce.com');
        Test.setCurrentPageReference(pageRef);
        System.runAs(adminUser){
            List<Account> accList = ARC_TestUtility.createTestAccount(1,'StandardAccount');
            accList[0].OwnerId = adminUser.Id;
            update accList;
            List<Contact> cont = ARC_TestUtility.createTestContact(1, 'Contact');
            List<vlocity_ins__GroupCensusMember__c> censusMember = ARC_TestUtility.createTestCensusMember(1);
            cont[0].accountId = accList[0].Id;
            update cont;
            censusMember[0].vlocity_ins__ContactId__c = cont[0].id;
            censusMember[0].vlocity_ins__FirstName__c = 'Testing';
            censusMember[0].vlocity_ins__LastName__c = 'Testing';
            update censusMember;

        
            inputMap.put('firstName','Test');
            inputMap.put('lastName','Test');
            inputMap.put('email', 'test@gfsdfgfffffffdss.com');
            inputMap.put('street', 'Testst.');
            inputMap.put('state', 'tests');
            inputMap.put('city', 'testc');
            inputMap.put('zipCode', '12100');
            inputMap.put('birthdate', '1994-12-07');
            inputMap.put('phone', '5465467779');
            inputMap.put('password','Random!password123');
            inputMap.put('censusMemberId', censusMember[0].Id);
            inputMap.put('accountId', accList[0].Id);
            inputMap.put('referral', acc2.Id);

            String methodName = 'CreateMemberUserAndAccount';
            ARC_CreateMemberUserGuest className = new ARC_CreateMemberUserGuest();
                
            Test.startTest();
                PageReference pag = new PageReference('https://uhsm--dev1.sandbox.my.site.com');
                System.debug('pag '+pag);
                Test.setCurrentPageReference(pag);
                className.invokeMethod(methodName, inputMap, outputMap, options);
            Test.stopTest();
            System.debug('Error on Account creation: ' + outputMap.get('Error on Account creation: '));
            System.debug('result: ' + outputMap.get('result'));                
        }
    }

    @isTest
    static void ARC_CreateMemberUserGuestTestException() {  
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
    
        inputMap.put('email', 'test@test.com');
        
        String methodName = 'CreateMemberUserAndAccount';
        ARC_CreateMemberUserGuest className = new ARC_CreateMemberUserGuest();
            
        Test.startTest();
            className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        System.assertEquals(true, outputMap.get('Error on Account creation: ') <> null);
    }

    @isTest
    static void createMemberPortalUserTest() {  
        List<vlocity_ins__GroupCensusMember__c> censusMemberList = [SELECT Id, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__FirstName__c = 'Portal' AND vlocity_ins__LastName__c='User' AND vlocity_ins__ContactId__c != null];
        System.debug('censusMemberList: '+censusMemberList);
                    
        Test.startTest();
            ARC_CreateMemberUserGuest.createMemberPortalUser(new List<Id>{censusMemberList[0].Id});
        Test.stopTest();
        List<User> testUser = [SELECT Id, email FROM User WHERE ContactId =: censusMemberList[0].vlocity_ins__ContactId__c LIMIT 1];
        List<PermissionSet> permissionSet = [SELECT Id FROM PermissionSet WHERE Label ='UHSM IFP FlowPermissions Member' ];
        List<PermissionSetAssignment> psAssignments = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId =: testUser[0].Id AND PermissionSetId =: permissionSet[0].Id ];
        System.assertEquals(1,testUser.size());
    }

    @isTest
    static void createMemberPortalUserTestChild() {  
        List<vlocity_ins__GroupCensusMember__c> censusMemberList = [SELECT Id, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__FirstName__c = 'Portal' AND vlocity_ins__LastName__c='User' AND vlocity_ins__ContactId__c != null];
        Account childAcc = [SELECT Id, PersonBirthdate FROM Account WHERE PersonContactId=: censusMemberList[0].vlocity_ins__ContactId__c];
        childAcc.PersonBirthdate= Date.today().addYears(-10);
        update childAcc;
                    
        Test.startTest();
            ARC_CreateMemberUserGuest.createMemberPortalUser(new List<Id>{censusMemberList[0].Id});
        Test.stopTest();
        List<User> testUser = [SELECT Id, email FROM User WHERE ContactId =: censusMemberList[0].vlocity_ins__ContactId__c LIMIT 1];        
        System.assertEquals(0,testUser.size());
    }

    @IsTest
    static void resetPasswordPersonAccountTest(){

        Account testAccount = [SELECT Id,FirstName,LastName,vlocity_ins__Email__c,Phone,BillingCity,BillingState,BillingPostalCode,BillingStreet,PersonContactId FROM Account LIMIT 1];
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Member Community' LIMIT 1].Id;
        User testUser = ARC_CreateMemberUserGuest.createUserSObject(testAccount, profileId);
        insert testUser;
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('personAccountId', testAccount.Id);
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        ARC_CreateMemberUserGuest newClassInstance = new ARC_CreateMemberUserGuest();
        newClassInstance.invokeMethod('resetPasswordPersonAccount', inputMap, outputMap, options);
        Test.stopTest();
    }

    @IsTest
    public static void createUserFromPersonAccount360Test(){
        Account personAccount = [SELECT Id,FirstName,LastName,vlocity_ins__Email__c,Phone,BillingCity,BillingState,BillingPostalCode,BillingStreet,PersonContactId FROM Account LIMIT 1];
        Map<String, Object> inputMap = new Map<String, Object>{'personAccountId' => personAccount.Id};
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        Test.startTest();
        ARC_CreateMemberUserGuest newClassInstance = new ARC_CreateMemberUserGuest();
        newClassInstance.invokeMethod('createUserFromPersonAccount360',inputMap,outputMap,options);
        Test.stopTest();
        
    }


    @IsTest
    static void resetPasswordPersonAccountTest360(){

        Account testAccount = [SELECT Id,FirstName,LastName,vlocity_ins__Email__c,Phone,BillingCity,BillingState,BillingPostalCode,BillingStreet,PersonContactId FROM Account LIMIT 1];
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Member Community' LIMIT 1].Id;
        User testUser = ARC_CreateMemberUserGuest.createUserSObject(testAccount, profileId);
        insert testUser;
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('personAccountId', testAccount.Id);
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        ARC_CreateMemberUserGuest newClassInstance = new ARC_CreateMemberUserGuest();
        newClassInstance.invokeMethod('resetUsernameAndPassword360', inputMap, outputMap, options);
        Test.stopTest();

        System.assert(outputMap.containsKey('resetUsernameAndPassword'), 'OutputMap should contain  the resetUsernameAndPassword key');
    }

    @IsTest
    static void checkPortalUsernameWasSetTest(){
        Account testAccount = [SELECT Id,FirstName,LastName,vlocity_ins__Email__c,Phone,BillingCity,BillingState,BillingPostalCode,BillingStreet,PersonContactId FROM Account LIMIT 1];
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Member Community' LIMIT 1].Id;
        User testUser = ARC_CreateMemberUserGuest.createUserSObject(testAccount, profileId);
        testUser.ARC_PortalUsername__c = 'TestUsername'; 
        insert testUser;

        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('personAccountId', testAccount.Id);
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        ARC_CreateMemberUserGuest newClassInstance = new ARC_CreateMemberUserGuest();
        newClassInstance.invokeMethod('checkPortalUsernameWasSet', inputMap, outputMap, options);
        Test.stopTest();

        System.assertEquals(true, outputMap.get('user'), 'User exists'); 
        System.assertNotEquals(null, outputMap.get('usernameWasReset'), 'Username reset should not be null'); 

    }

}