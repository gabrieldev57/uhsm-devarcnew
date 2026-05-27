@IsTest
private class CaseOwnerChangeHandlerCCTest {
    
   @TestSetup
    static void makeData(){
        // Create Custom Setting
        CC_RoundRobinSetting__c rrSetting = new CC_RoundRobinSetting__c(
            Name = 'OrgDefault',
            SetupOwnerId = UserInfo.getOrganizationId(),
            LastIndex__c = 0,
            LastAssignedUserId__c = null
        );
        upsert rrSetting;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1]; 
        
        // Create non-CC user FIRST
        User nonCC = new User(
            Alias = 'nonCC',
            Email = 'test.noncc@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test Non-CC',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'nonCC' + System.currentTimeMillis() + '@test.com',
            Team__c = 'Sales',
            IsActive = true,
            Email_Template_Signature__c = 'test'
        );
        insert nonCC;
    
        // Create test CC users
        User cc1 = new User(
            Alias = 'cc1',
            Email = 'test.cc1@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test CC1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'cc1' + System.currentTimeMillis() + '@test.com',
            Team__c = 'Client Coordinator',
            Round_Robin_Eligibility__c = 'Eligible',
            IsActive = true,
            Email_Template_Signature__c = 'test'
        );
        insert cc1;
    
        User cc2 = new User(
            Alias = 'cc2',
            Email = 'test.cc2@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test CC2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'cc2' + System.currentTimeMillis() + '@test.com',
            Team__c = 'Client Coordinator',
            Round_Robin_Eligibility__c = 'Eligible',
            IsActive = true,
            Email_Template_Signature__c = 'test'
        );
        insert cc2;
        
        // REMOVED: Don't try to update existing users
        
        // Create accounts
        Id personAccRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount').getRecordTypeId();
            
        Account personAcc = new Account(
            RecordTypeId = personAccRtId,
            FirstName = 'Test',
            LastName = 'Person',
            OwnerId = nonCC.Id
        );
        insert personAcc; 
    
        Account famAccount = new Account(
            Name = 'Test Family Account',
            OwnerId = nonCC.Id
        );
        insert famAccount;
    
        Account famAccount2 = new Account(
            Name = 'Test Family Account2',
            OwnerId = cc1.Id
        );
        insert famAccount2;
    
        // Create contract WITH selling agent set to non-CC
        Contract c = new Contract(
            AccountId = famAccount.Id,
            Status = 'Draft',
            StartDate = System.today(),
            ContractTerm = 12,
            ARC_Selling_Agent__c = nonCC.Id
        );
        insert c;
    
        // Create contract participant
        ARC_ContractParticipant__c cp = new ARC_ContractParticipant__c(
            ARC_PersonAccount__c = personAcc.Id,
            ARC_Contract__c = c.Id
        );
        insert cp;
    
        // Create cases
        Id underwritingRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Admission').getRecordTypeId();
        Id onboardingRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Onboarding').getRecordTypeId();
    
        Case uwCase = new Case(
            RecordTypeId = underwritingRT,
            AccountId = famAccount.Id,
            Status = 'New',
            OwnerId = cc1.Id,
            Subject = 'Test UW Case',
            Description = 'Test',
            ARC_Contract__c = c.Id
        );
        insert uwCase;
    
        Case onboardingCase = new Case(
            RecordTypeId = onboardingRT,
            AccountId = famAccount.Id,
            Status = 'New',
            Subject = 'Test Onboarding Case',
            Description = 'Test',
            OwnerId = cc1.Id
        );
        insert onboardingCase;
    }

    @IsTest
    static void testRRAssignments() {
        CaseOwnerChangeHandlerCC.resetTestState();
        Case uwCase = [SELECT Id, Status, OwnerId, ARC_Contract__c FROM Case WHERE Subject = 'Test UW Case' LIMIT 1]; 
        Account famAccount = [SELECT Id, OwnerId FROM Account WHERE Name = 'Test Family Account' LIMIT 1];
        Account personAcc = [SELECT Id, OwnerId FROM Account WHERE FirstName = 'Test' AND IsPersonAccount = true LIMIT 1];
        User cc1 = [SELECT Id, Name FROM User WHERE Alias = 'cc1' LIMIT 1];
        User cc2 = [SELECT Id, Name FROM User WHERE Alias = 'cc2' LIMIT 1];
        
        System.debug('Initial famAccount owner: ' + famAccount.OwnerId);
        System.debug('CC1 ID: ' + cc1.Id);
        System.debug('CC2 ID: ' + cc2.Id);
        
        // Verify contract has non-CC selling agent
        Contract con = [SELECT Id, ARC_Selling_Agent__c, ARC_Selling_Agent__r.Team__c 
                        FROM Contract 
                        WHERE Id = :uwCase.ARC_Contract__c];
        System.debug('Contract selling agent team: ' + con.ARC_Selling_Agent__r.Team__c);
        System.assert(con.ARC_Selling_Agent__r.Team__c != 'Client Coordinator', 
                      'Selling agent should not be a CC for this test');
        
        uwCase.Status = 'Closed Approved';
        
        Test.startTest();
        CCRoundRobinHelper.setMockUser(cc2);
        System.debug('Mock set to: ' + cc2.Name);
        update uwCase; 
        Test.stopTest();
        
        // Verify accounts were reassigned
        Account famAccountUpd = [SELECT Id, OwnerId FROM Account WHERE Id = :famAccount.Id LIMIT 1];
        Account personAccUpd = [SELECT Id, OwnerId FROM Account WHERE Id = :personAcc.Id LIMIT 1];
        
        System.debug('Final famAccount owner: ' + famAccountUpd.OwnerId);
        System.debug('Expected (CC2): ' + cc2.Id);
        System.debug('primaryAccOwnerId: ' + CaseOwnerChangeHandlerCC.primaryAccOwnerId);
        
        System.assertEquals(cc2.Id, famAccountUpd.OwnerId, 'Family account should be reassigned to CC2');
        System.assertEquals(cc2.Id, personAccUpd.OwnerId, 'Person account should be reassigned to CC2');
        System.assertEquals(cc2.Id, CaseOwnerChangeHandlerCC.primaryAccOwnerId, 'RR should have assigned to CC2');
        
        CCRoundRobinHelper.clearMock();
    }


    @IsTest
    static void testCCToCCChange() {
        CaseOwnerChangeHandlerCC.resetTestState();
        CCRoundRobinHelper.resetTestState();
        
        User cc1 = [SELECT Id FROM User WHERE Alias = 'cc1' LIMIT 1];
        User cc2 = [SELECT Id, Team__c, Round_Robin_Eligibility__c FROM User WHERE Alias = 'cc2' LIMIT 1]; 
        Case onboardingCase = [SELECT Id, OwnerId FROM Case WHERE Subject = 'Test Onboarding Case' LIMIT 1]; 
        Account famAccount = [SELECT Id, OwnerId FROM Account WHERE Name = 'Test Family Account' LIMIT 1];
        Account personAccount = [SELECT Id, OwnerId FROM Account WHERE FirstName = 'Test' AND IsPersonAccount = true LIMIT 1];
    
        // Verify initial state
        System.assertEquals(cc1.Id, onboardingCase.OwnerId, 'Case should start with CC1');
    
        // Change case owner from CC1 to CC2
        onboardingCase.OwnerId = cc2.Id;
        
        // ADD: Set test users to prevent querying all CCs
        CCRoundRobinHelper.setTestUsers(new Set<Id>{ cc1.Id, cc2.Id });
        
        Test.startTest();
        update onboardingCase; 
        Test.stopTest();
    
        // Verify accounts were reassigned to CC2
        Account famAccountUpd = [SELECT Id, OwnerId FROM Account WHERE Id = :famAccount.Id LIMIT 1];
        Account personAccountUpd = [SELECT Id, OwnerId FROM Account WHERE Id = :personAccount.Id LIMIT 1];
    
        System.assertEquals(cc2.Id, famAccountUpd.OwnerId, 'Family Account should be reassigned to CC2'); 
        System.assertEquals(cc2.Id, personAccountUpd.OwnerId, 'Person Account should be reassigned to CC2');
        
        CCRoundRobinHelper.clearTestUsers();
    }

    @IsTest
    static void testCCToNonCCChange(){
        CaseOwnerChangeHandlerCC.resetTestState();
        User cc1 = [SELECT Id FROM User WHERE Alias = 'cc1' LIMIT 1];
        User nonCC = [SELECT Id FROM User WHERE Alias = 'nonCC' LIMIT 1]; 
        Case onboardingCase = [SELECT Id, OwnerId FROM Case WHERE Subject = 'Test Onboarding Case' LIMIT 1];
        Account famAccount = [SELECT Id, OwnerId FROM Account WHERE Name = 'Test Family Account' LIMIT 1];

        // Verify initial state
        System.assertEquals(cc1.Id, onboardingCase.OwnerId, 'Case should start with CC1');
        
        Id originalOwnerId = famAccount.OwnerId;

        // Change case owner from CC to non-CC
        onboardingCase.OwnerId = nonCC.Id;

        Test.startTest();
        update onboardingCase; 
        Test.stopTest();

        // Verify account owner did NOT change (CC to non-CC should not trigger update)
        Account famAccountUpd = [SELECT Id, OwnerId FROM Account WHERE Id = :famAccount.Id LIMIT 1];
        System.assertEquals(originalOwnerId, famAccountUpd.OwnerId, 'Account Owner should not change when case moves from CC to non-CC');
    }

    @IsTest
    static void testNonOnboardingCaseChange(){
        CaseOwnerChangeHandlerCC.resetTestState();
        User cc2 = [SELECT Id FROM User WHERE Alias = 'cc2' LIMIT 1];
        Case uwCase = [SELECT Id, OwnerId FROM Case WHERE Subject = 'Test UW Case' LIMIT 1];
        Account famAccount = [SELECT Id, OwnerId FROM Account WHERE Name = 'Test Family Account' LIMIT 1];
        
        Id originalOwnerId = famAccount.OwnerId;

        // Change underwriting case owner (should not trigger account ownership change)
        // Only Onboarding RT with CC-to-CC change should trigger
        uwCase.OwnerId = cc2.Id;

        Test.startTest();
        update uwCase;
        Test.stopTest();

        Account famAccountUpd = [SELECT Id, OwnerId FROM Account WHERE Id = :famAccount.Id LIMIT 1];
        System.assertEquals(originalOwnerId, famAccountUpd.OwnerId, 
            'Account owner should not change for non-Onboarding case owner changes');
    }

    @IsTest
    static void testRoundRobinWithRealSettings(){
        CaseOwnerChangeHandlerCC.resetTestState();
        CCRoundRobinHelper.resetTestState(); // Clear any prior state
        
        User cc1 = [SELECT Id FROM User WHERE Alias = 'cc1' LIMIT 1];
        User cc2 = [SELECT Id FROM User WHERE Alias = 'cc2' LIMIT 1];
        
        // NEW: Limit round robin to only test users
        CCRoundRobinHelper.setTestUsers(new Set<Id>{ cc1.Id, cc2.Id });
        
        Test.startTest();
        User result1 = CCRoundRobinHelper.getNextRoundRobinUser();
        User result2 = CCRoundRobinHelper.getNextRoundRobinUser();
        Test.stopTest();
    
        // Re-query with all needed fields
        result1 = [SELECT Id, Name, Team__c, Round_Robin_Eligibility__c 
                   FROM User WHERE Id = :result1.Id];
        result2 = [SELECT Id, Name, Team__c, Round_Robin_Eligibility__c 
                   FROM User WHERE Id = :result2.Id];
    
        System.assertNotEquals(null, result1, 'Should return a CC user');
        System.assertNotEquals(null, result2, 'Should return a CC user');
        System.assertEquals('Client Coordinator', result1.Team__c, 'User should be a CC');
        System.assertEquals('Client Coordinator', result2.Team__c, 'User should be a CC');
        System.assertEquals('Eligible', result1.Round_Robin_Eligibility__c, 'User should be eligible');
        System.assertEquals('Eligible', result2.Round_Robin_Eligibility__c, 'User should be eligible');
    
        // Verify round robin is working (should alternate between users)
        System.assertNotEquals(result1.Id, result2.Id, 'Round robin should assign to different users');
    
        // Verify settings were updated
        CC_RoundRobinSetting__c setting = CC_RoundRobinSetting__c.getOrgDefaults();
        System.assertNotEquals(null, setting, 'Settings should exist');
        System.assertNotEquals(null, setting.LastAssignedUserId__c, 'Last assigned user should be set');
        
        CCRoundRobinHelper.clearTestUsers(); // Clean up
    }
    
    @IsTest
    static void testUWCaseApprovalWithCCSellingAgent(){
        CaseOwnerChangeHandlerCC.resetTestState();
        // Test that UW case approval does NOT trigger round robin when selling agent is already a CC
        User cc1 = [SELECT Id FROM User WHERE Alias = 'cc1' LIMIT 1];
        Case uwCase = [SELECT Id, ARC_Contract__c FROM Case WHERE Subject = 'Test UW Case' LIMIT 1];
        Contract con = [SELECT Id, ARC_Selling_Agent__c FROM Contract WHERE Id = :uwCase.ARC_Contract__c];
        Account famAccount = [SELECT Id, OwnerId FROM Account WHERE Name = 'Test Family Account' LIMIT 1];
        
        // Set selling agent to a CC
        con.ARC_Selling_Agent__c = cc1.Id;
        update con;
        
        Id originalOwnerId = famAccount.OwnerId;

        uwCase.Status = 'Closed Approved';

        Test.startTest();
        update uwCase;
        Test.stopTest();

        // Account should NOT change owner because selling agent is already a CC
        Account famAccountUpd = [SELECT Id, OwnerId FROM Account WHERE Id = :famAccount.Id];
        System.assertEquals(originalOwnerId, famAccountUpd.OwnerId, 
            'Account owner should not change when selling agent is already a CC');
    }

    @IsTest
    static void testMultipleContractsRoundRobin(){
        CaseOwnerChangeHandlerCC.resetTestState();
        // Test that multiple contracts get different CCs via round robin
        User cc1 = [SELECT Id, Name FROM User WHERE Alias = 'cc1' LIMIT 1];
        User cc2 = [SELECT Id, Name FROM User WHERE Alias = 'cc2' LIMIT 1];
        User nonCC = [SELECT Id FROM User WHERE Alias = 'nonCC' LIMIT 1];
        
        // Get the original test family account
        Account famAccount1 = [SELECT Id FROM Account WHERE Name = 'Test Family Account' LIMIT 1];
        
        // Create second family account with contract
        Account famAccount3 = new Account(
            Name = 'Test Family Account 3',
            OwnerId = nonCC.Id
        );
        insert famAccount3;
    
        Contract c2 = new Contract(
            AccountId = famAccount3.Id,
            Status = 'Draft',
            StartDate = System.today(),
            ContractTerm = 12,
            ARC_Selling_Agent__c = nonCC.Id
        );
        insert c2;
    
        Id underwritingRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('Admission').getRecordTypeId();
    
        Case uwCase2 = new Case(
            RecordTypeId = underwritingRT,
            AccountId = famAccount3.Id,
            Status = 'New',
            OwnerId = cc1.Id,
            Subject = 'Test UW Case 2',
            Description = 'Test',
            ARC_Contract__c = c2.Id
        );
        insert uwCase2;
    
        Test.startTest();
        CCRoundRobinHelper.setMockUser(cc2);
        
        List<Case> casesToUpdate = [SELECT Id, Status FROM Case WHERE Subject LIKE 'Test UW Case%'];
        for (Case c : casesToUpdate) {
            c.Status = 'Closed Approved';
        }
        update casesToUpdate;
        Test.stopTest();
    
        // Query only the accounts that should have been updated (the ones with approved UW cases)
        List<Account> accounts = [
            SELECT Id, OwnerId, Name 
            FROM Account 
            WHERE Name IN ('Test Family Account', 'Test Family Account 3')
        ];
        
        System.assertEquals(2, accounts.size(), 'Should have 2 accounts that were updated');
        
        for (Account a : accounts) {
            System.debug('Account: ' + a.Name + ', Owner: ' + a.OwnerId + ', Expected: ' + cc2.Id);
            System.assertEquals(cc2.Id, a.OwnerId, 
                'Account ' + a.Name + ' should be assigned to mocked CC2');
        }
        
        // Verify Account 2 was NOT changed (no UW case for it)
        Account famAccount2 = [SELECT Id, OwnerId FROM Account WHERE Name = 'Test Family Account2' LIMIT 1];
        System.assertEquals(cc1.Id, famAccount2.OwnerId, 
            'Test Family Account2 should remain with CC1 since it has no UW case');
    
        CCRoundRobinHelper.clearMock();
    }
    
    @IsTest
    static void testBulkCaseUpdates(){
        CaseOwnerChangeHandlerCC.resetTestState();
        CCRoundRobinHelper.resetTestState();
        
        User cc1 = [SELECT Id, Name FROM User WHERE Alias = 'cc1' LIMIT 1];
        User cc2 = [SELECT Id, Name FROM User WHERE Alias = 'cc2' LIMIT 1];
        
        // ADD: Set test users FIRST
        CCRoundRobinHelper.setTestUsers(new Set<Id>{ cc1.Id, cc2.Id });
        
        Account famAccount = [SELECT Id, OwnerId FROM Account WHERE Name = 'Test Family Account' LIMIT 1];
        System.debug('===== INITIAL STATE =====');
        System.debug('Account owner BEFORE: ' + famAccount.OwnerId);
        System.debug('CC1 ID: ' + cc1.Id);
        System.debug('CC2 ID: ' + cc2.Id);
        System.debug('Account owned by CC1? ' + (famAccount.OwnerId == cc1.Id));
        
        // Verify contract exists
        List<Contract> contracts = [SELECT Id, AccountId FROM Contract WHERE AccountId = :famAccount.Id];
        System.debug('Contracts found: ' + contracts.size());
        System.assert(!contracts.isEmpty(), 'Test Family Account should have a contract');
        
        // Create multiple onboarding cases
        Id onboardingRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Onboarding').getRecordTypeId();
        
        List<Case> onboardingCases = new List<Case>();
        for (Integer i = 0; i < 5; i++){
            onboardingCases.add(new Case(
                RecordTypeId = onboardingRT,
                AccountId = famAccount.Id,
                Status = 'New',
                Subject = 'Bulk Test Case ' + i,
                OwnerId = cc1.Id,
                Description = 'Test'
            ));
        }
        insert onboardingCases;
        
        System.debug('===== CASES CREATED =====');
        System.debug('Created ' + onboardingCases.size() + ' cases, all owned by CC1');
        
        // Verify cases were created with correct owner
        List<Case> verifyInsert = [SELECT Id, OwnerId, AccountId, RecordType.DeveloperName 
                                    FROM Case WHERE Id IN :onboardingCases];
        for (Case c : verifyInsert){
            System.debug('Case: ' + c.Id + ', Owner: ' + c.OwnerId + ', Account: ' + c.AccountId + ', RT: ' + c.RecordType.DeveloperName);
            System.assert(c.OwnerId == cc1.Id, 'Case should be owned by CC1 initially');
        }
        
        // Update all to CC2
        for (Case c : onboardingCases){
            c.OwnerId = cc2.Id;
        }
        
        System.debug('===== UPDATING CASES =====');
        System.debug('About to update ' + onboardingCases.size() + ' cases to CC2');
        
        Test.startTest();
        update onboardingCases;
        Test.stopTest();
        
        System.debug('===== AFTER UPDATE =====');
        
        // Verify cases were updated
        List<Case> verifyUpdate = [SELECT Id, OwnerId FROM Case WHERE Id IN :onboardingCases];
        for (Case c : verifyUpdate){
            System.debug('Case after update: ' + c.Id + ', Owner: ' + c.OwnerId);
            System.assert(c.OwnerId == cc2.Id, 'Case should now be owned by CC2');
        }
        
        // Verify account was updated
        famAccount = [SELECT Id, OwnerId FROM Account WHERE Name = 'Test Family Account' LIMIT 1];
        System.debug('Account owner AFTER: ' + famAccount.OwnerId);
        System.debug('Expected (CC2): ' + cc2.Id);
        System.debug('Actual: ' + famAccount.OwnerId);
        System.debug('Match? ' + (famAccount.OwnerId == cc2.Id));
        
        System.assertEquals(cc2.Id, famAccount.OwnerId, 
            'Account should be owned by CC2. Actual owner: ' + famAccount.OwnerId);
        
        CCRoundRobinHelper.clearTestUsers();
    }
}