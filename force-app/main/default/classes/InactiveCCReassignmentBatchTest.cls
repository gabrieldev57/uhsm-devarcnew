@IsTest
private class InactiveCCReassignmentBatchTest {
    
    @TestSetup
    static void makeData() {
        // Reset all static state
        CCRoundRobinHelper.resetTestState();
        CaseOwnerChangeHandlerCC.resetTestState();
        
        // Create Custom Setting
        CC_RoundRobinSetting__c rrSetting = new CC_RoundRobinSetting__c(
            Name = 'OrgDefault',
            SetupOwnerId = UserInfo.getOrganizationId(),
            LastIndex__c = 0,
            LastAssignedUserId__c = null
        );
        upsert rrSetting;
        
        // Create test users - NO attempt to modify existing users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'WS Sales' LIMIT 1];
        
        User activeCC = new User(
            FirstName = 'Active',
            LastName = 'CC',
            Alias = 'accc',
            Email = 'active.cc@test.com',
            Username = 'active.cc' + System.currentTimeMillis() + '@test.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Team__c = 'Client Coordinator',
            Round_Robin_Eligibility__c = 'Eligible', 
            IsActive = true,
            Email_Template_Signature__c = 'test'
        );
        insert activeCC;
        
        User inactiveCC = new User(
            FirstName = 'Inactive',
            LastName = 'CC',
            Alias = 'iccc',
            Email = 'inactive.cc@test.com',
            Username = 'inactive.cc' + System.currentTimeMillis() + '@test.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = false, 
            Team__c = 'Client Coordinator',
            Round_Robin_Eligibility__c = 'Eligible',
            Email_Template_Signature__c = 'test'
        );
        insert inactiveCC;
        
        // Create family account owned by inactive CC
        Account familyAcc = new Account(
            Name = 'Test Family',
            OwnerId = inactiveCC.Id
        );
        insert familyAcc;
        
        // Create person account owned by inactive CC
        Id paRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount').getRecordTypeId();
        
        Account personAcc = new Account(
            RecordTypeId = paRtId,
            FirstName = 'John',
            LastName = 'Doe',
            OwnerId = inactiveCC.Id
        );
        insert personAcc;
        
        // Create ChargentOrder using dynamic SObject to avoid version dependency
        SObject chargentOrder = Schema.getGlobalDescribe().get('ChargentOrders__ChargentOrder__c').newSObject();
        chargentOrder.put('ChargentOrders__Description__c', 'Recurring Monthly Order');
        chargentOrder.put('ChargentOrders__Account__c', personAcc.Id);
        chargentOrder.put('ChargentOrders__Payment_Status__c', 'Stopped');
        chargentOrder.put('ChargentOrders__Payment_Start_Date__c', Date.today());
        insert chargentOrder;
        
        // Create contract owned by inactive CC
        Contract c = new Contract(
            AccountId = familyAcc.Id,
            OwnerId = inactiveCC.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 12,
            ARC_RecurringMonthlyOrder__c = chargentOrder.Id
        );
        insert c;
        
        // Update contract to Awaiting status
        c.Status = 'Awaiting Approval'; 
        update c;
        
        // Create contract participant linking to person account
        ARC_ContractParticipant__c cp = new ARC_ContractParticipant__c(
            ARC_Contract__c = c.Id,
            ARC_PersonAccount__c = personAcc.Id
        );
        insert cp;
    }
    
    @IsTest
    static void testBatchReassignsInactiveCCs() {
        CCRoundRobinHelper.resetTestState();
        
        // Get users
        User activeCC = [SELECT Id, Name FROM User WHERE Email = 'active.cc@test.com' LIMIT 1];
        User inactiveCC = [SELECT Id FROM User WHERE Email = 'inactive.cc@test.com' LIMIT 1];
        
        // Use mock to ensure predictable assignment
        CCRoundRobinHelper.setMockUser(activeCC);
        
        // Verify initial state - accounts owned by inactive CC
        Account beforeFamilyAcc = [SELECT Id, OwnerId FROM Account WHERE Name = 'Test Family' LIMIT 1];
        Account beforePersonAcc = [SELECT Id, OwnerId FROM Account WHERE FirstName = 'John' LIMIT 1];
        Contract beforeContract = [SELECT Id, OwnerId FROM Contract LIMIT 1];
        
        System.assertEquals(inactiveCC.Id, beforeFamilyAcc.OwnerId, 'Family account should start owned by inactive CC');
        System.assertEquals(inactiveCC.Id, beforePersonAcc.OwnerId, 'Person account should start owned by inactive CC');
        System.assertEquals(inactiveCC.Id, beforeContract.OwnerId, 'Contract should start owned by inactive CC');
        
        Test.startTest();
        InactiveCCReassignmentBatch batch = new InactiveCCReassignmentBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify records were reassigned to active CC
        Account afterFamilyAcc = [SELECT Id, OwnerId FROM Account WHERE Name = 'Test Family' LIMIT 1];
        Account afterPersonAcc = [SELECT Id, OwnerId FROM Account WHERE FirstName = 'John' LIMIT 1];
        Contract afterContract = [SELECT Id, OwnerId FROM Contract LIMIT 1];
        
        System.assertEquals(activeCC.Id, afterFamilyAcc.OwnerId, 'Family account should be reassigned to active CC');
        System.assertEquals(activeCC.Id, afterPersonAcc.OwnerId, 'Person account should be reassigned to active CC');
        System.assertEquals(activeCC.Id, afterContract.OwnerId, 'Contract should be reassigned to active CC');
        
        CCRoundRobinHelper.clearMock();
    }
    
    @IsTest
    static void testBatchWithMultipleContracts() {
        CCRoundRobinHelper.resetTestState();
        
        // Get users
        User activeCC = [SELECT Id, Name FROM User WHERE Email = 'active.cc@test.com' LIMIT 1];
        User inactiveCC = [SELECT Id FROM User WHERE Email = 'inactive.cc@test.com' LIMIT 1];
        
        // Get the existing contract from testSetup
        Contract existingContract = [SELECT Id, OwnerId, AccountId FROM Contract LIMIT 1];
        System.assertEquals(inactiveCC.Id, existingContract.OwnerId, 'Setup contract should be owned by inactive CC');
        
        // Create additional test data
        Account familyAcc2 = new Account(
            Name = 'Test Family 2',
            OwnerId = inactiveCC.Id
        );
        insert familyAcc2;
        
        // Create ChargentOrder using dynamic SObject
        SObject chargentOrder2 = Schema.getGlobalDescribe().get('ChargentOrders__ChargentOrder__c').newSObject();
        chargentOrder2.put('ChargentOrders__Description__c', 'Recurring Monthly Order');
        chargentOrder2.put('ChargentOrders__Account__c', familyAcc2.Id);
        chargentOrder2.put('ChargentOrders__Payment_Status__c', 'Stopped');
        chargentOrder2.put('ChargentOrders__Payment_Start_Date__c', Date.today());
        insert chargentOrder2;
        
        Contract c2 = new Contract(
            AccountId = familyAcc2.Id,
            OwnerId = inactiveCC.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 12,
            ARC_RecurringMonthlyOrder__c = chargentOrder2.Id
        );
        insert c2;
        
        c2.Status = 'Activated';
        update c2;
        
        // Verify c2 is still owned by inactive CC
        c2 = [SELECT Id, OwnerId FROM Contract WHERE Id = :c2.Id];
        System.assertEquals(inactiveCC.Id, c2.OwnerId, 'Contract 2 should still be owned by inactive CC');
        
        // Set mock
        CCRoundRobinHelper.setMockUser(activeCC);
        
        Test.startTest();
        Database.executeBatch(new InactiveCCReassignmentBatch());
        Test.stopTest();
        
        // Verify both contracts and accounts were reassigned
        List<Contract> contracts = [SELECT Id, OwnerId, Status 
                                    FROM Contract 
                                    ORDER BY CreatedDate];
        System.assertEquals(2, contracts.size(), 'Should have 2 contracts');
        
        for (Contract c : contracts) {
            System.assertEquals(activeCC.Id, c.OwnerId, 
                'Contract ' + c.Id + ' should be owned by active CC. Status: ' + c.Status);
        }
        
        List<Account> accounts = [SELECT Id, OwnerId, Name FROM Account WHERE Name LIKE 'Test Family%'];
        System.assertEquals(2, accounts.size(), 'Should have 2 family accounts');
        for (Account a : accounts) {
            System.assertEquals(activeCC.Id, a.OwnerId, 
                'Account ' + a.Name + ' should be owned by active CC');
        }
        
        CCRoundRobinHelper.clearMock();
    }
    
    @IsTest
    static void testBatchWithNoEligibleUsers() {
        CCRoundRobinHelper.resetTestState();
        
        User inactiveCC = [SELECT Id FROM User WHERE Email = 'inactive.cc@test.com' LIMIT 1];
        User activeCC = [SELECT Id FROM User WHERE Email = 'active.cc@test.com' LIMIT 1];
        
        // Make the only test CC ineligible
        activeCC.Round_Robin_Eligibility__c = 'Ineligible';
        update activeCC;
        
        // CRITICAL: Limit round robin to only our test users (which are now all ineligible)
        CCRoundRobinHelper.setTestUsers(new Set<Id>{ activeCC.Id });
        
        Test.startTest();
        InactiveCCReassignmentBatch batch = new InactiveCCReassignmentBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify records were NOT updated (owners remain inactive CC due to no eligible users)
        Account familyAcc = [SELECT Id, OwnerId FROM Account WHERE Name = 'Test Family' LIMIT 1];
        Contract contract = [SELECT Id, OwnerId FROM Contract LIMIT 1];
        
        System.assertEquals(inactiveCC.Id, familyAcc.OwnerId, 
            'Account should remain with inactive CC when no eligible users');
        System.assertEquals(inactiveCC.Id, contract.OwnerId, 
            'Contract should remain with inactive CC when no eligible users');
        
        CCRoundRobinHelper.clearTestUsers();
    }
    
    @IsTest
    static void testBatchStatefulVariables() {
        CCRoundRobinHelper.resetTestState();
        
        User activeCC = [SELECT Id, Name FROM User WHERE Email = 'active.cc@test.com' LIMIT 1];
        CCRoundRobinHelper.setMockUser(activeCC);
        
        Test.startTest();
        InactiveCCReassignmentBatch batch = new InactiveCCReassignmentBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify the batch executed successfully
        List<Contract> contracts = [SELECT Id, OwnerId FROM Contract];
        for (Contract c : contracts) {
            System.assertEquals(activeCC.Id, c.OwnerId, 'Contracts should be assigned to active CC');
        }
        
        List<Account> accounts = [SELECT Id, OwnerId FROM Account WHERE Name LIKE 'Test Family%'];
        for (Account a : accounts) {
            System.assertEquals(activeCC.Id, a.OwnerId, 'Accounts should be assigned to active CC');
        }
        
        CCRoundRobinHelper.clearMock();
    }
    
    @IsTest
    static void testSchedulerCoversBatch() {
        CCRoundRobinHelper.resetTestState();
        
        Test.startTest();
        String cronExp = '0 0 12 * * ?'; // Every day at noon
        String jobId = System.schedule('TestInactiveCCReassignment', cronExp, new InactiveCCReassignmentSched());
        Test.stopTest();
        
        // Verify job was scheduled
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExp, ct.CronExpression, 'Cron expression should match');
        System.assertEquals(0, ct.TimesTriggered, 'Should not have fired yet in test context');
    }
    
    @IsTest
    static void testBatchWithActivatedContract() {
        CCRoundRobinHelper.resetTestState();
        
        User activeCC = [SELECT Id, Name FROM User WHERE Email = 'active.cc@test.com' LIMIT 1];
        User inactiveCC = [SELECT Id FROM User WHERE Email = 'inactive.cc@test.com' LIMIT 1];
        
        // Update existing contract to Activated
        Contract c = [SELECT Id, Status FROM Contract LIMIT 1];
        c.Status = 'Activated';
        update c;
        
        CCRoundRobinHelper.setMockUser(activeCC);
        
        Test.startTest();
        Database.executeBatch(new InactiveCCReassignmentBatch());
        Test.stopTest();
        
        Contract afterContract = [SELECT Id, OwnerId FROM Contract LIMIT 1];
        System.assertEquals(activeCC.Id, afterContract.OwnerId, 'Activated contract should be reassigned');
        
        CCRoundRobinHelper.clearMock();
    }
}