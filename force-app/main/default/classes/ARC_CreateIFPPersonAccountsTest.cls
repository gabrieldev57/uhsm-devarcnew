@isTest
private class ARC_CreateIFPPersonAccountsTest {

    @testSetup
    private static void mockTest() {
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
            acc.ARC_IsPrimaryMember__c = true;
            acc.ARC_E123MemberIdFromPolicy__c = 'W123456789'+counter;
            accList.add(acc);
        }
        insert accList;

        List <vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(2);
        counter = 0;
        for(vlocity_ins__GroupCensusMember__c censusMember: censusMemberList){
            censusMember.vlocity_ins__ContactId__c = accList[counter].PersonContactId;
            censusMember.vlocity_ins__SocialSecurityNumber__c = '123456789';
            counter++;
        }
        update censusMemberList;
    }

    @isTest
    static void testCreatePersonAccounts() {
        List<vlocity_ins__GroupCensusMember__c> censusMemberList = [SELECT Id, vlocity_ins__LastName__c,vlocity_ins__FirstName__c FROM vlocity_ins__GroupCensusMember__c];
        
        // Create test data
        List<Object> oldMembers = new List<Object>();
        List<Object> newMembers = new List<Object>();
        Map<String, Object> oldMember = new Map<String, Object>{'Id' => censusMemberList[0].Id, 'Name' => 'Old Member'};
        Map<String, Object> newMember = new Map<String, Object>{'CensusMemberId' => censusMemberList[1].Id, 'CensusMemberFirstName' => 'New', 'CensusMemberLastName' => 'Member', 'CensusEmail' => 'newmember@example.com', 'Birthdate' => '1990-01-01'};
        newMembers.add(newMember);
        Map<String, Object> inputMap = new Map<String, Object>{'oldMembers' => oldMembers, 'newMembers' => newMembers};
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // Call the method being tested
        Test.startTest();
        ARC_CreateIFPPersonAccounts.createPersonAccounts(inputMap, outputMap, options);
        Test.stopTest();
        
    }
    
    @isTest
    static void testRelateMembersToAccount() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        
        List<Account> accList = [SELECT Id, ARC_E123MemberIdFromPolicy__c,ARC_IsPrimaryMember__c,PersonEmail,BillingPostalCode,BillingCity,BillingState,BillingStreet FROM Account WHERE RecordTypeId = :accRecordTypeId];
        // Call the method being tested
        List<vlocity_ins__GroupCensusMember__c> membersToUpdate = ARC_CreateIFPPersonAccounts.relateMembersToAccount(accList);
        
    }
    
    @isTest
    static void testAddContactIdToNewMembers() {
        List<vlocity_ins__GroupCensusMember__c> censusMemberList = [SELECT Id, vlocity_ins__LastName__c,vlocity_ins__FirstName__c FROM vlocity_ins__GroupCensusMember__c];

        // Create test data
        List<Object> userInputs2 = new List<Object>();
        Map<String, Object> newMember = new Map<String, Object>{'Id' => censusMemberList[0].Id, 'CensusMemberFirstName' => 'New', 'CensusMemberLastName' => 'Member', 'CensusEmail' => 'newmember@example.com', 'Birthdate' => '1990-01-01'};
        userInputs2.add(newMember);
        List<vlocity_ins__GroupCensusMember__c> membersToUpdate = new List<vlocity_ins__GroupCensusMember__c>();
        membersToUpdate.add(censusMemberList[1]);
        
        // Call the method being tested
        List<Object> result = ARC_CreateIFPPersonAccounts.addContactIdToNewMembers(userInputs2, membersToUpdate);
        
      
    }
}