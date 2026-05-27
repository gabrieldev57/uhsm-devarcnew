@IsTest
private class AccountShareHandlerTest {
   @TestSetup
   static void setupData() {
       // Create a test user who will be added to the Account Team
       Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
       User testUser = new User(
           Alias = 'tuser',
           Email = 'testuser@example.com',
           EmailEncodingKey = 'UTF-8',
           LastName = 'Tester',
           LanguageLocaleKey = 'en_US',
           LocaleSidKey = 'en_US',
           TimeZoneSidKey = 'America/Los_Angeles',
           ProfileId = p.Id,
           Username = 'tuser' + DateTime.now().getTime() + '@example.com'
       );
       insert testUser;
       // Insert Accounts
       insert new List<Account>{
           new Account(Name = 'Test Account 1'),
           new Account(Name = 'Test Account 2')
       };
   }
   @IsTest
   static void testAddTeamMembers() {
       User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
       List<Account> accounts = [SELECT Id, Name FROM Account];
       AccountShareHandler.InputWrapper input = new AccountShareHandler.InputWrapper();
       input.accountIds = new List<Id>();
       for (Account a : accounts) {
           input.accountIds.add(a.Id);
       }
       input.userId = testUser.Id;
       input.role = 'Client Coordinator';
       input.accessLevel = 'Edit';
       Test.startTest();
       AccountShareHandler.addTeamMembers(new List<AccountShareHandler.InputWrapper>{ input });
       Test.stopTest();
       List<AccountTeamMember> atms = [
           SELECT AccountId, UserId, TeamMemberRole, AccountAccessLevel
           FROM AccountTeamMember
           WHERE UserId = :testUser.Id
       ];
       System.assertEquals(accounts.size(), atms.size(), 'Should create team members for each account');
       for (AccountTeamMember atm : atms) {
           System.assertEquals('Client Coordinator', atm.TeamMemberRole);
           System.assertEquals('Edit', atm.AccountAccessLevel);
       }
   }
   @IsTest
   static void testIdempotency_NoDuplicates() {
       User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
       List<Account> accounts = [SELECT Id FROM Account];
       AccountShareHandler.InputWrapper input = new AccountShareHandler.InputWrapper();
       input.accountIds = new List<Id>();
       for (Account a : accounts) {
           input.accountIds.add(a.Id);
       }
       input.userId = testUser.Id;
       input.role = 'Client Coordinator';
       input.accessLevel = 'Edit';
       // Call twice
       Test.startTest();
       AccountShareHandler.addTeamMembers(new List<AccountShareHandler.InputWrapper>{ input });
       AccountShareHandler.addTeamMembers(new List<AccountShareHandler.InputWrapper>{ input });
       Test.stopTest();
       Integer count = [SELECT COUNT() FROM AccountTeamMember WHERE UserId = :testUser.Id];
       System.assertEquals(accounts.size(), count, 'No duplicate AccountTeamMembers should exist');
   }
   @IsTest
   static void testNoAccounts_NoCrash() {
       User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
       AccountShareHandler.InputWrapper input = new AccountShareHandler.InputWrapper();
       input.accountIds = new List<Id>(); // empty list
       input.userId = testUser.Id;
       input.role = 'Client Coordinator';
       input.accessLevel = 'Read';
       Test.startTest();
       AccountShareHandler.addTeamMembers(new List<AccountShareHandler.InputWrapper>{ input });
       Test.stopTest();
       // Verify nothing inserted
       Integer count = [SELECT COUNT() FROM AccountTeamMember WHERE UserId = :testUser.Id];
       System.assertEquals(0, count, 'No accounts means no ATM should be created');
   }
   @IsTest
   static void testNullAccounts_NoCrash() {
       User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
       AccountShareHandler.InputWrapper input = new AccountShareHandler.InputWrapper();
       input.accountIds = null; // simulate Flow sending null
       input.userId = testUser.Id;
       input.role = 'Client Coordinator';
       input.accessLevel = 'Read';
       Test.startTest();
       AccountShareHandler.addTeamMembers(new List<AccountShareHandler.InputWrapper>{ input });
       Test.stopTest();
       // Verify nothing inserted
       Integer count = [SELECT COUNT() FROM AccountTeamMember WHERE UserId = :testUser.Id];
       System.assertEquals(0, count, 'Null accounts should not cause any inserts');
   }
}