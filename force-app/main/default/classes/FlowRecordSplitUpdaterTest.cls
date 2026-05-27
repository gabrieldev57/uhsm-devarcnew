/**
 * Test class for FlowRecordSplitUpdater
 * 
 * Tests the splitting logic to ensure records with matching field values
 * are distributed across separate batches and updated correctly.
 */
@isTest
private class FlowRecordSplitUpdaterTest {
    
    /**
     * Test multiple records with the same Account - should create separate batches
     */
    @isTest
    static void testMultipleRecordsSameAccount() {
        // Setup: Create 1 Account and 3 Contacts
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < 3; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                AccountId = acc.Id,
                Title = 'Original Title'
            ));
        }
        insert contacts;
        
        // Query them back to get full records
        contacts = [SELECT Id, AccountId, Title FROM Contact WHERE Id IN :contacts];
        
        // Set new title values
        for(Contact c : contacts) {
            c.Title = 'Updated Title';
        }
        
        // Execute
        FlowRecordSplitUpdater.Request req = new FlowRecordSplitUpdater.Request();
        req.records = contacts;
        req.fieldName = 'AccountId';
        
        Test.startTest();
        List<FlowRecordSplitUpdater.Response> responses = 
            FlowRecordSplitUpdater.updateRecordsSplit(new List<FlowRecordSplitUpdater.Request>{ req });
        Test.stopTest();
        
        // Verify
        FlowRecordSplitUpdater.Response response = responses[0];
        System.assertEquals(3, response.successCount, 'Should update all 3 contacts');
        System.assertEquals(3, response.batchCount, 'Should create 3 batches (one per contact since they share an account)');
        
        // Verify records were actually updated
        List<Contact> updatedContacts = [SELECT Title FROM Contact WHERE Id IN :contacts];
        for(Contact c : updatedContacts) {
            System.assertEquals('Updated Title', c.Title, 'Contact should be updated');
        }
    }
    
    /**
     * Test records with different Accounts - should fit in one batch
     */
    @isTest
    static void testMultipleRecordsDifferentAccounts() {
        // Setup: Create 3 Accounts and 3 Contacts (one per account)
        List<Account> accounts = new List<Account>();
        for(Integer i = 0; i < 3; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;
        
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < 3; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                AccountId = accounts[i].Id,
                Title = 'Original Title'
            ));
        }
        insert contacts;
        
        // Query them back
        contacts = [SELECT Id, AccountId, Title FROM Contact WHERE Id IN :contacts];
        
        // Set new title values
        for(Contact c : contacts) {
            c.Title = 'Updated Title';
        }
        
        // Execute
        FlowRecordSplitUpdater.Request req = new FlowRecordSplitUpdater.Request();
        req.records = contacts;
        req.fieldName = 'AccountId';
        
        Test.startTest();
        List<FlowRecordSplitUpdater.Response> responses = 
            FlowRecordSplitUpdater.updateRecordsSplit(new List<FlowRecordSplitUpdater.Request>{ req });
        Test.stopTest();
        
        // Verify
        FlowRecordSplitUpdater.Response response = responses[0];
        System.assertEquals(3, response.successCount, 'Should update all 3 contacts');
        System.assertEquals(1, response.batchCount, 'Should create 1 batch (all different accounts)');
        
        // Verify records were actually updated
        List<Contact> updatedContacts = [SELECT Title FROM Contact WHERE Id IN :contacts];
        for(Contact c : updatedContacts) {
            System.assertEquals('Updated Title', c.Title, 'Contact should be updated');
        }
    }
    
    /**
     * Test mixed scenario - some contacts share accounts, some don't
     */
    @isTest
    static void testMixedAccounts() {
        // Setup: Create 2 Accounts
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Account A'),
            new Account(Name = 'Account B')
        };
        insert accounts;
        
        // Create 5 Contacts: 3 on Account A, 2 on Account B
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Test', LastName = 'Contact 1', AccountId = accounts[0].Id, Title = 'Original'),
            new Contact(FirstName = 'Test', LastName = 'Contact 2', AccountId = accounts[0].Id, Title = 'Original'),
            new Contact(FirstName = 'Test', LastName = 'Contact 3', AccountId = accounts[1].Id, Title = 'Original'),
            new Contact(FirstName = 'Test', LastName = 'Contact 4', AccountId = accounts[0].Id, Title = 'Original'),
            new Contact(FirstName = 'Test', LastName = 'Contact 5', AccountId = accounts[1].Id, Title = 'Original')
        };
        insert contacts;
        
        // Query them back
        contacts = [SELECT Id, AccountId, Title FROM Contact WHERE Id IN :contacts];
        
        // Set new title values
        for(Contact c : contacts) {
            c.Title = 'Updated Title';
        }
        
        // Execute
        FlowRecordSplitUpdater.Request req = new FlowRecordSplitUpdater.Request();
        req.records = contacts;
        req.fieldName = 'AccountId';
        
        Test.startTest();
        List<FlowRecordSplitUpdater.Response> responses = 
            FlowRecordSplitUpdater.updateRecordsSplit(new List<FlowRecordSplitUpdater.Request>{ req });
        Test.stopTest();
        
        // Verify
        FlowRecordSplitUpdater.Response response = responses[0];
        System.assertEquals(5, response.successCount, 'Should update all 5 contacts');
        // Expected batching:
        // Batch 1: Contact1(AcctA), Contact3(AcctB)
        // Batch 2: Contact2(AcctA), Contact5(AcctB)
        // Batch 3: Contact4(AcctA)
        System.assertEquals(3, response.batchCount, 'Should create 3 batches for optimal distribution');
        
        // Verify records were actually updated
        List<Contact> updatedContacts = [SELECT Title FROM Contact WHERE Id IN :contacts];
        for(Contact c : updatedContacts) {
            System.assertEquals('Updated Title', c.Title, 'Contact should be updated');
        }
    }
    
    /**
     * Test records with null field values - should be excluded
     */
    @isTest
    static void testNullFieldValues() {
        // Setup: Create 2 Contacts without Accounts
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Test', LastName = 'Contact 1', Title = 'Original'),
            new Contact(FirstName = 'Test', LastName = 'Contact 2', Title = 'Original')
        };
        insert contacts;
        
        // Query them back
        contacts = [SELECT Id, AccountId, Title FROM Contact WHERE Id IN :contacts];
        
        // Set new title values
        for(Contact c : contacts) {
            c.Title = 'Updated Title';
        }
        
        // Execute
        FlowRecordSplitUpdater.Request req = new FlowRecordSplitUpdater.Request();
        req.records = contacts;
        req.fieldName = 'AccountId';
        
        Test.startTest();
        List<FlowRecordSplitUpdater.Response> responses = 
            FlowRecordSplitUpdater.updateRecordsSplit(new List<FlowRecordSplitUpdater.Request>{ req });
        Test.stopTest();
        
        // Verify
        FlowRecordSplitUpdater.Response response = responses[0];
        System.assertEquals(0, response.successCount, 'Should update 0 contacts (null AccountIds excluded)');
        System.assertEquals(0, response.batchCount, 'Should create 0 batches');
    }
    
    /**
     * Test single record
     */
    @isTest
    static void testSingleRecord() {
        // Setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id,
            Title = 'Original Title'
        );
        insert contact;
        
        // Query back
        contact = [SELECT Id, AccountId, Title FROM Contact WHERE Id = :contact.Id];
        contact.Title = 'Updated Title';
        
        // Execute
        FlowRecordSplitUpdater.Request req = new FlowRecordSplitUpdater.Request();
        req.records = new List<Contact>{ contact };
        req.fieldName = 'AccountId';
        
        Test.startTest();
        List<FlowRecordSplitUpdater.Response> responses = 
            FlowRecordSplitUpdater.updateRecordsSplit(new List<FlowRecordSplitUpdater.Request>{ req });
        Test.stopTest();
        
        // Verify
        FlowRecordSplitUpdater.Response response = responses[0];
        System.assertEquals(1, response.successCount, 'Should update 1 contact');
        System.assertEquals(1, response.batchCount, 'Should create 1 batch');
        
        Contact updatedContact = [SELECT Title FROM Contact WHERE Id = :contact.Id];
        System.assertEquals('Updated Title', updatedContact.Title, 'Contact should be updated');
    }
    
    /**
     * Test splitting by text field instead of lookup
     */
    @isTest
    static void testTextFieldSplit() {
        // Setup: Create contacts with duplicate Department values
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'Test', LastName = 'Contact 1', Department = 'Sales', Title = 'Original'),
            new Contact(FirstName = 'Test', LastName = 'Contact 2', Department = 'Sales', Title = 'Original'),
            new Contact(FirstName = 'Test', LastName = 'Contact 3', Department = 'Engineering', Title = 'Original'),
            new Contact(FirstName = 'Test', LastName = 'Contact 4', Department = 'Sales', Title = 'Original')
        };
        insert contacts;
        
        // Query them back
        contacts = [SELECT Id, Department, Title FROM Contact WHERE Id IN :contacts];
        
        // Set new title values
        for(Contact c : contacts) {
            c.Title = 'Updated Title';
        }
        
        // Execute
        FlowRecordSplitUpdater.Request req = new FlowRecordSplitUpdater.Request();
        req.records = contacts;
        req.fieldName = 'Department';
        
        Test.startTest();
        List<FlowRecordSplitUpdater.Response> responses = 
            FlowRecordSplitUpdater.updateRecordsSplit(new List<FlowRecordSplitUpdater.Request>{ req });
        Test.stopTest();
        
        // Verify
        FlowRecordSplitUpdater.Response response = responses[0];
        System.assertEquals(4, response.successCount, 'Should update all 4 contacts');
        // Expected batching:
        // Batch 1: Contact1(Sales), Contact3(Engineering)
        // Batch 2: Contact2(Sales)
        // Batch 3: Contact4(Sales)
        System.assertEquals(3, response.batchCount, 'Should create 3 batches (3 Sales, 1 Engineering)');
        
        // Verify records were actually updated
        List<Contact> updatedContacts = [SELECT Title FROM Contact WHERE Id IN :contacts];
        for(Contact c : updatedContacts) {
            System.assertEquals('Updated Title', c.Title, 'Contact should be updated');
        }
    }
    
    /**
     * Test error handling with invalid field name
     */
    @isTest
    static void testInvalidFieldName() {
        // Setup
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert contact;
        
        contact = [SELECT Id FROM Contact WHERE Id = :contact.Id];
        
        // Execute with invalid field name
        FlowRecordSplitUpdater.Request req = new FlowRecordSplitUpdater.Request();
        req.records = new List<Contact>{ contact };
        req.fieldName = 'NonExistentField__c';
        
        Test.startTest();
        try {
            FlowRecordSplitUpdater.updateRecordsSplit(new List<FlowRecordSplitUpdater.Request>{ req });
            System.assert(false, 'Should have thrown an exception');
        } catch(FlowRecordSplitUpdater.InvocableException e) {
            System.assert(e.getMessage().contains('Error updating records'), 'Should throw InvocableException');
        }
        Test.stopTest();
    }
}