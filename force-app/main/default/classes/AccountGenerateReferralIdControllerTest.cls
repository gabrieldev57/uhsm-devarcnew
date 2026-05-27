@IsTest
public with sharing class AccountGenerateReferralIdControllerTest {
   
    @IsTest
    static void testTriggerAssignsReferralId(){
        Account testAcc = new Account(); 
        testAcc.FirstName = 'Test';
        testAcc.LastName = 'Account'; 
        testAcc.RecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName()
            .get('ARC_IFPPersonAccount').getRecordTypeId();
        
        Test.startTest();
        insert testAcc;
        Test.stopTest();
        
        // Query the account to verify trigger assigned referral ID
        Account insertedAccount = [SELECT Id, Referral_Id__c FROM Account WHERE Id = :testAcc.Id];
        System.assertNotEquals(null, insertedAccount.Referral_Id__c);
        System.assertEquals(15, insertedAccount.Referral_Id__c.length());
    }
        
    @IsTest
    static void testCollisionHandling() {
        // Setup: Create an existing account with a known referral ID
        Account existingAcc = new Account();
        existingAcc.FirstName = 'Existing';
        existingAcc.LastName = 'Account';
        existingAcc.RecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName()
            .get('ARC_IFPPersonAccount').getRecordTypeId();
        insert existingAcc;
        
        existingAcc.Referral_Id__c = 'COLLISION12345'; // Known ID that will cause collision
        update existingAcc;
        
        // Setup: Create new account for testing
        Account newAcc = new Account();
        newAcc.FirstName = 'New';
        newAcc.LastName = 'Account';
        newAcc.RecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName()
            .get('ARC_IFPPersonAccount').getRecordTypeId();
        
        // Setup: Mock the random ID generation to first return the colliding ID, then a unique one
        AccountGenerateReferralIdController.mockIds = new List<String>{
            'COLLISION12345', // This will collide with existing account
            'UNIQUE123456789'  // This should be unique
        };
        AccountGenerateReferralIdController.mockIdIndex = 0;
        
        List<Account> newAccounts = new List<Account>{newAcc};
        
        Test.startTest();
        AccountGenerateReferralIdController.assignReferralIds(newAccounts);
        Test.stopTest();
        
        // Assert: The new account should have the unique ID, not the colliding one
        System.assertEquals('UNIQUE123456789', newAcc.Referral_Id__c);
        System.assertNotEquals('COLLISION12345', newAcc.Referral_Id__c);
    }
    
    @IsTest
    static void testMultipleCollisionResolution() {
        // Setup: Create existing accounts with known referral IDs
        List<Account> existingAccs = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            Account existingAcc = new Account();
            existingAcc.FirstName = 'Existing' + i;
            existingAcc.LastName = 'Account';
            existingAcc.RecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName()
                .get('ARC_IFPPersonAccount').getRecordTypeId();
            existingAccs.add(existingAcc);
        }
        insert existingAccs;
        
        // Update with known IDs
        existingAccs[0].Referral_Id__c = 'COLLISION12345';
        existingAccs[1].Referral_Id__c = 'COLLISION67890';
        existingAccs[2].Referral_Id__c = 'FINALCOLLISION1'; // This will test Step 4
        update existingAccs;
        
        // Setup: Create new account for testing
        Account newAcc = new Account();
        newAcc.FirstName = 'New';
        newAcc.LastName = 'Account';
        newAcc.RecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName()
            .get('ARC_IFPPersonAccount').getRecordTypeId();
        
        // Setup: Mock IDs to simulate collision in Step 3 and Step 4
        AccountGenerateReferralIdController.mockIds = new List<String>{
            'COLLISION12345', // Initial collision
            'FINALCOLLISION1', // Regenerated ID that also collides (tests Step 4)
            'UNIQUE123456789'  // Final unique ID
        };
        AccountGenerateReferralIdController.mockIdIndex = 0;
        
        List<Account> newAccounts = new List<Account>{newAcc};
        
        Test.startTest();
        AccountGenerateReferralIdController.assignReferralIds(newAccounts);
        Test.stopTest();
        
        // Assert: Should end up with the final unique ID
        System.assertEquals('UNIQUE123456789', newAcc.Referral_Id__c);
    }
    
    @IsTest
    static void testAccountsWithExistingReferralIds() {
        // Test accounts that already have referral IDs (should be skipped)
        Account accWithId = new Account();
        accWithId.FirstName = 'HasId';
        accWithId.LastName = 'Account';
        accWithId.Referral_Id__c = 'EXISTING1234567'; // Already has an ID
        accWithId.RecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName()
            .get('ARC_IFPPersonAccount').getRecordTypeId();
        
        Account accWithoutId = new Account();
        accWithoutId.FirstName = 'NoId';
        accWithoutId.LastName = 'Account';
        accWithoutId.RecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName()
            .get('ARC_IFPPersonAccount').getRecordTypeId();
        
        AccountGenerateReferralIdController.mockIds = new List<String>{'NEWID1234567890'};
        AccountGenerateReferralIdController.mockIdIndex = 0;
        
        List<Account> accounts = new List<Account>{accWithId, accWithoutId};
        
        Test.startTest();
        AccountGenerateReferralIdController.assignReferralIds(accounts);
        Test.stopTest();
        
        // Assert: Account with existing ID should be unchanged
        System.assertEquals('EXISTING1234567', accWithId.Referral_Id__c);
        // Assert: Account without ID should get new ID
        System.assertEquals('NEWID1234567890', accWithoutId.Referral_Id__c);
    }
    
    @IsTest
    static void testEmptyAccountList() {
        // Test with empty list
        List<Account> emptyList = new List<Account>();
        
        Test.startTest();
        AccountGenerateReferralIdController.assignReferralIds(emptyList);
        Test.stopTest();
        
        // Should complete without error
        System.assertEquals(0, emptyList.size());
    }
    
    @IsTest 
    static void testGenerateRandomIdWithoutMocks() {
        // Clear mocks to test actual random generation
        AccountGenerateReferralIdController.mockIds = new List<String>();
        AccountGenerateReferralIdController.mockIdIndex = 0;
        
        Account testAcc = new Account();
        testAcc.FirstName = 'Random';
        testAcc.LastName = 'Account';
        testAcc.RecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName()
            .get('ARC_IFPPersonAccount').getRecordTypeId();
        
        List<Account> accounts = new List<Account>{testAcc};
        
        Test.startTest();
        AccountGenerateReferralIdController.assignReferralIds(accounts);
        Test.stopTest();
        
        // Should generate a random ID
        System.assertNotEquals(null, testAcc.Referral_Id__c);
        System.assertEquals(15, testAcc.Referral_Id__c.length());
    }
}