@isTest
private class AccountTeamsHandlerTest {
    
    @testSetup
    static void setup() {
        // Create test users
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User accountOwner = new User(
            FirstName = 'Account',
            LastName = 'Owner',
            Email = 'account.owner@test.com',
            Username = 'account.owner@test' + System.now().getTime() + '.com',
            Alias = 'accown',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert accountOwner;
        
        User sellingAgent = new User(
            FirstName = 'Selling',
            LastName = 'Agent',
            Email = 'selling.agent@test.com',
            Username = 'selling.agent@test' + System.now().getTime() + '.com',
            Alias = 'selagnt',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert sellingAgent;
        
        User newOwner = new User(
            FirstName = 'New',
            LastName = 'Owner',
            Email = 'new.owner@test.com',
            Username = 'new.owner@test' + System.now().getTime() + '.com',
            Alias = 'newown',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert newOwner;
    }
    
    @isTest
    static void testPreserveSellingAgentOnOwnerChange() {
        User accountOwner = [SELECT Id FROM User WHERE Username LIKE 'account.owner@test%' LIMIT 1];
        User sellingAgent = [SELECT Id FROM User WHERE Username LIKE 'selling.agent@test%' LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE Username LIKE 'new.owner@test%' LIMIT 1];
        
        // Create Account owned by accountOwner
        Account testAccount = new Account(
            Name = 'Test Account',
            OwnerId = accountOwner.Id
        );
        insert testAccount;
        
        // Create AccountTeamMember with 'Selling Agent' role for a DIFFERENT user (not the owner)
        AccountTeamMember originalSellingAgent = new AccountTeamMember(
            AccountId = testAccount.Id,
            UserId = sellingAgent.Id, // Different from account owner
            TeamMemberRole = 'Selling Agent',
            AccountAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            CaseAccessLevel = 'Edit'
        );
        insert originalSellingAgent;
        
        // Verify the team member was created
        List<AccountTeamMember> beforeUpdate = [
            SELECT Id, UserId, TeamMemberRole 
            FROM AccountTeamMember 
            WHERE AccountId = :testAccount.Id
        ];
        System.assertEquals(1, beforeUpdate.size(), 'Should have 1 team member before update');
        System.assertEquals('Selling Agent', beforeUpdate[0].TeamMemberRole, 'Role should be Selling Agent');
        System.assertEquals(sellingAgent.Id, beforeUpdate[0].UserId, 'Team member should be the selling agent user');
        
        Test.startTest();
        
        // Change account owner - this should trigger the preservation logic
        testAccount.OwnerId = newOwner.Id;
        update testAccount;
        
        Test.stopTest();
        
        // Verify the Selling Agent team member was recreated with the SAME user
        List<AccountTeamMember> afterUpdate = [
            SELECT Id, UserId, TeamMemberRole, AccountAccessLevel, 
                   OpportunityAccessLevel, CaseAccessLevel
            FROM AccountTeamMember 
            WHERE AccountId = :testAccount.Id
            AND TeamMemberRole = 'Selling Agent'
        ];
        
        System.assertEquals(1, afterUpdate.size(), 'Should have 1 Selling Agent team member after update');
        System.assertEquals(sellingAgent.Id, afterUpdate[0].UserId, 'Selling Agent should be the same user as before');
        System.assertEquals('Edit', afterUpdate[0].AccountAccessLevel, 'Account access should be preserved');
        System.assertEquals('Edit', afterUpdate[0].OpportunityAccessLevel, 'Opportunity access should be preserved');
        System.assertEquals('Edit', afterUpdate[0].CaseAccessLevel, 'Case access should be preserved');
    }
    
    @isTest
    static void testPreserveSellingAgentWhenOwnerIsSellingAgent() {
        User accountOwner = [SELECT Id FROM User WHERE Username LIKE 'account.owner@test%' LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE Username LIKE 'new.owner@test%' LIMIT 1];
        
        // Create Account owned by accountOwner
        Account testAccount = new Account(
            Name = 'Test Account Owner as Agent',
            OwnerId = accountOwner.Id
        );
        insert testAccount;
        
        // Create AccountTeamMember with 'Selling Agent' role for the OWNER
        AccountTeamMember ownerAsSellingAgent = new AccountTeamMember(
            AccountId = testAccount.Id,
            UserId = accountOwner.Id, // Same as account owner
            TeamMemberRole = 'Selling Agent',
            AccountAccessLevel = 'Read',
            OpportunityAccessLevel = 'None',
            CaseAccessLevel = 'Read'
        );
        insert ownerAsSellingAgent;
        
        Test.startTest();
        
        // Change account owner
        testAccount.OwnerId = newOwner.Id;
        update testAccount;
        
        Test.stopTest();
        
        // Verify the Selling Agent (previous owner) was preserved
        List<AccountTeamMember> afterUpdate = [
            SELECT Id, UserId, TeamMemberRole, AccountAccessLevel
            FROM AccountTeamMember 
            WHERE AccountId = :testAccount.Id
            AND TeamMemberRole = 'Selling Agent'
        ];
        
        System.assertEquals(1, afterUpdate.size(), 'Should have 1 Selling Agent team member after update');
        System.assertEquals(accountOwner.Id, afterUpdate[0].UserId, 'Selling Agent should be the previous owner');
        System.assertEquals('Read', afterUpdate[0].AccountAccessLevel, 'Access level should be preserved');
    }
    
    @isTest
    static void testNoSellingAgentToPreserve() {
        User accountOwner = [SELECT Id FROM User WHERE Username LIKE 'account.owner@test%' LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE Username LIKE 'new.owner@test%' LIMIT 1];
        
        // Create Account without a Selling Agent team member
        Account testAccount = new Account(
            Name = 'Test Account No Agent',
            OwnerId = accountOwner.Id
        );
        insert testAccount;
        
        Test.startTest();
        
        // Change account owner - no Selling Agent to preserve
        testAccount.OwnerId = newOwner.Id;
        update testAccount;
        
        Test.stopTest();
        
        // Verify no Selling Agent team member was created
        List<AccountTeamMember> afterUpdate = [
            SELECT Id 
            FROM AccountTeamMember 
            WHERE AccountId = :testAccount.Id
            AND TeamMemberRole = 'Selling Agent'
        ];
        
        System.assertEquals(0, afterUpdate.size(), 'Should have no Selling Agent team member');
    }
    
    @isTest
    static void testBulkOwnerChange() {
        User accountOwner = [SELECT Id FROM User WHERE Username LIKE 'account.owner@test%' LIMIT 1];
        User sellingAgent = [SELECT Id FROM User WHERE Username LIKE 'selling.agent@test%' LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE Username LIKE 'new.owner@test%' LIMIT 1];
        
        // Create multiple accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Test Account ' + i,
                OwnerId = accountOwner.Id
            ));
        }
        insert accounts;
        
        // Create Selling Agent team members for all accounts
        List<AccountTeamMember> teamMembers = new List<AccountTeamMember>();
        for (Account acc : accounts) {
            teamMembers.add(new AccountTeamMember(
                AccountId = acc.Id,
                UserId = sellingAgent.Id, // Consistent selling agent across all accounts
                TeamMemberRole = 'Selling Agent',
                AccountAccessLevel = 'Read',
                OpportunityAccessLevel = 'Read',
                CaseAccessLevel = 'Read'
            ));
        }
        insert teamMembers;
        
        Test.startTest();
        
        // Bulk update account owners
        for (Account acc : accounts) {
            acc.OwnerId = newOwner.Id;
        }
        update accounts;
        
        Test.stopTest();
        
        // Verify all Selling Agent team members were recreated
        List<AccountTeamMember> afterUpdate = [
            SELECT Id, UserId, TeamMemberRole, AccountAccessLevel
            FROM AccountTeamMember 
            WHERE AccountId IN :accounts
            AND TeamMemberRole = 'Selling Agent'
        ];
        
        System.assertEquals(200, afterUpdate.size(), 'Should have 200 Selling Agent team members after bulk update');
        
        // Verify all have the selling agent user
        for (AccountTeamMember atm : afterUpdate) {
            System.assertEquals(sellingAgent.Id, atm.UserId, 'All team members should reference the selling agent');
            System.assertEquals('Read', atm.AccountAccessLevel, 'Access level should be preserved');
        }
    }
    
    @isTest
    static void testOwnerChangeWithDifferentTeamMemberRole() {
        User accountOwner = [SELECT Id FROM User WHERE Username LIKE 'account.owner@test%' LIMIT 1];
        User sellingAgent = [SELECT Id FROM User WHERE Username LIKE 'selling.agent@test%' LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE Username LIKE 'new.owner@test%' LIMIT 1];
        
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Account Different Role',
            OwnerId = accountOwner.Id
        );
        insert testAccount;
        
        // Create AccountTeamMember with different role (not Selling Agent)
        AccountTeamMember teamMember = new AccountTeamMember(
            AccountId = testAccount.Id,
            UserId = sellingAgent.Id,
            TeamMemberRole = 'Account Manager', // Different role
            AccountAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            CaseAccessLevel = 'Edit'
        );
        insert teamMember;
        
        Test.startTest();
        
        // Change account owner
        testAccount.OwnerId = newOwner.Id;
        update testAccount;
        
        Test.stopTest();
        
        // Verify no Selling Agent team member was created (since original wasn't Selling Agent)
        List<AccountTeamMember> afterUpdate = [
            SELECT Id, TeamMemberRole
            FROM AccountTeamMember 
            WHERE AccountId = :testAccount.Id
            AND TeamMemberRole = 'Selling Agent'
        ];
        
        System.assertEquals(0, afterUpdate.size(), 'Should not create Selling Agent team member for different role');
    }
    
    @isTest
    static void testNoOwnerChange() {
        User accountOwner = [SELECT Id FROM User WHERE Username LIKE 'account.owner@test%' LIMIT 1];
        User sellingAgent = [SELECT Id FROM User WHERE Username LIKE 'selling.agent@test%' LIMIT 1];
        
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Account No Change',
            OwnerId = accountOwner.Id
        );
        insert testAccount;
        
        // Create Selling Agent team member
        AccountTeamMember sellingAgentMember = new AccountTeamMember(
            AccountId = testAccount.Id,
            UserId = sellingAgent.Id,
            TeamMemberRole = 'Selling Agent',
            AccountAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            CaseAccessLevel = 'Edit'
        );
        insert sellingAgentMember;
        
        Test.startTest();
        
        // Update account without changing owner
        testAccount.Name = 'Updated Name';
        update testAccount;
        
        Test.stopTest();
        
        // Verify team member count didn't change (no duplicate created)
        List<AccountTeamMember> afterUpdate = [
            SELECT Id 
            FROM AccountTeamMember 
            WHERE AccountId = :testAccount.Id
        ];
        
        System.assertEquals(1, afterUpdate.size(), 'Should still have exactly 1 team member');
    }
    
    @isTest
    static void testMultipleTeamMembersOnlyPreserveSellingAgent() {
        User accountOwner = [SELECT Id FROM User WHERE Username LIKE 'account.owner@test%' LIMIT 1];
        User sellingAgent = [SELECT Id FROM User WHERE Username LIKE 'selling.agent@test%' LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE Username LIKE 'new.owner@test%' LIMIT 1];
        
        // Create a fourth user for additional team member
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User otherUser = new User(
            FirstName = 'Other',
            LastName = 'User',
            Email = 'other.user@test.com',
            Username = 'other.user@test' + System.now().getTime() + '.com',
            Alias = 'other',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert otherUser;
        
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Multiple Team Members',
            OwnerId = accountOwner.Id
        );
        insert testAccount;
        
        // Create multiple team members with different roles
        List<AccountTeamMember> teamMembers = new List<AccountTeamMember>{
            new AccountTeamMember(
                AccountId = testAccount.Id,
                UserId = sellingAgent.Id,
                TeamMemberRole = 'Selling Agent',
                AccountAccessLevel = 'Edit',
                OpportunityAccessLevel = 'Edit',
                CaseAccessLevel = 'Edit'
            ),
            new AccountTeamMember(
                AccountId = testAccount.Id,
                UserId = otherUser.Id,
                TeamMemberRole = 'Account Manager',
                AccountAccessLevel = 'Read',
                OpportunityAccessLevel = 'Read',
                CaseAccessLevel = 'Read'
            )
        };
        insert teamMembers;
        
        // Verify we started with 2 team members
        List<AccountTeamMember> beforeUpdate = [
            SELECT Id FROM AccountTeamMember WHERE AccountId = :testAccount.Id
        ];
        System.assertEquals(2, beforeUpdate.size(), 'Should start with 2 team members');
        
        Test.startTest();
        
        // Change account owner - Salesforce will delete ALL team members
        testAccount.OwnerId = newOwner.Id;
        update testAccount;
        
        Test.stopTest();
        
        // Verify only the Selling Agent was recreated
        List<AccountTeamMember> sellingAgents = [
            SELECT Id, UserId, TeamMemberRole
            FROM AccountTeamMember 
            WHERE AccountId = :testAccount.Id
            AND TeamMemberRole = 'Selling Agent'
        ];
        
        System.assertEquals(1, sellingAgents.size(), 'Should have exactly 1 Selling Agent');
        System.assertEquals(sellingAgent.Id, sellingAgents[0].UserId, 'Selling Agent user should be preserved');
        
        // Verify ONLY the Selling Agent exists (Account Manager was deleted and NOT recreated)
        List<AccountTeamMember> allMembers = [
            SELECT Id, TeamMemberRole, UserId
            FROM AccountTeamMember 
            WHERE AccountId = :testAccount.Id
        ];
        
        System.assertEquals(1, allMembers.size(), 'Should have only 1 team member after owner change');
        System.assertEquals('Selling Agent', allMembers[0].TeamMemberRole, 'Only team member should be Selling Agent');
        
        // Verify the Account Manager role was NOT recreated
        List<AccountTeamMember> accountManagers = [
            SELECT Id FROM AccountTeamMember 
            WHERE AccountId = :testAccount.Id 
            AND TeamMemberRole = 'Account Manager'
        ];
        System.assertEquals(0, accountManagers.size(), 'Account Manager should NOT have been recreated');
    }
    
    @isTest
    static void testPreserveAccessLevels() {
        User accountOwner = [SELECT Id FROM User WHERE Username LIKE 'account.owner@test%' LIMIT 1];
        User sellingAgent = [SELECT Id FROM User WHERE Username LIKE 'selling.agent@test%' LIMIT 1];
        User newOwner = [SELECT Id FROM User WHERE Username LIKE 'new.owner@test%' LIMIT 1];
        
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Access Levels',
            OwnerId = accountOwner.Id
        );
        insert testAccount;
        
        // Create Selling Agent with specific access levels
        AccountTeamMember originalAgent = new AccountTeamMember(
            AccountId = testAccount.Id,
            UserId = sellingAgent.Id,
            TeamMemberRole = 'Selling Agent',
            AccountAccessLevel = 'Read',
            OpportunityAccessLevel = 'None',
            CaseAccessLevel = 'Edit'
        );
        insert originalAgent;
        
        Test.startTest();
        
        // Change account owner
        testAccount.OwnerId = newOwner.Id;
        update testAccount;
        
        Test.stopTest();
        
        // Verify the access levels were preserved exactly
        AccountTeamMember recreatedAgent = [
            SELECT Id, UserId, AccountAccessLevel, OpportunityAccessLevel, CaseAccessLevel
            FROM AccountTeamMember 
            WHERE AccountId = :testAccount.Id
            AND TeamMemberRole = 'Selling Agent'
            LIMIT 1
        ];
        
        System.assertEquals(sellingAgent.Id, recreatedAgent.UserId, 'User should be preserved');
        System.assertEquals('Read', recreatedAgent.AccountAccessLevel, 'Account access should be Read');
        System.assertEquals('None', recreatedAgent.OpportunityAccessLevel, 'Opportunity access should be None');
        System.assertEquals('Edit', recreatedAgent.CaseAccessLevel, 'Case access should be Edit');
    }
}