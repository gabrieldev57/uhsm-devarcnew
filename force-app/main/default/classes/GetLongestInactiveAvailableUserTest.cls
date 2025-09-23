@isTest
public class GetLongestInactiveAvailableUserTest {
    
    @isTest static void testGetLongestInactiveUserId() {
        // Create Test Users
        List<User> users = new List<User>{
            new User(LastName = 'Test_Inactive_User_1', Email = 'test1@example.com', Alias = 'test1', Username = 'test1InactiveUser@example.com', ProfileId = '00e5f000003Mt1WAAS', TimeZoneSidKey = 'GMT', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'),
            new User(LastName = 'Test_Inactive_User_2', Email = 'test2@example.com', Alias = 'test2', Username = 'test2InactiveUser@example.com', ProfileId = '00e5f000003Mt1WAAS', TimeZoneSidKey = 'GMT', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'),
            new User(LastName = 'Test_Inactive_User_3', Email = 'test3@example.com', Alias = 'test3', Username = 'test3InactiveUser@example.com', ProfileId = '00e5f000003Mt1WAAS', TimeZoneSidKey = 'GMT', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US')
        };
        insert users;

        // Create User Skills
        User_Skill__c userSkill1 = new User_Skill__c(User__c = users[0].Id, Status__c = 'In use', Last_Used_Date__c = DateTime.now().addDays(-3));
        User_Skill__c userSkill2 = new User_Skill__c(User__c = users[1].Id, Status__c = 'Available', Last_Used_Date__c = DateTime.now().addDays(-4));
        User_Skill__c userSkill3 = new User_Skill__c(User__c = users[2].Id, Status__c = 'In use', Last_Used_Date__c = DateTime.now().addDays(-5));
        insert new List<User_Skill__c> { userSkill1, userSkill2, userSkill3};

        // Test
        GetLongestInactiveAvailableUser.Request req1 = new GetLongestInactiveAvailableUser.Request();
        req1.userIds = new List<Id>{users[0].Id, users[1].Id, users[2].Id};
        
        GetLongestInactiveAvailableUser.Request req2 = new GetLongestInactiveAvailableUser.Request();
        req2.userIds = new List<Id>{users[0].Id, users[1].Id};

        List<GetLongestInactiveAvailableUser.Response> results = GetLongestInactiveAvailableUser.getLongestInactiveUserId(new List<GetLongestInactiveAvailableUser.Request> { req1, req2 });

        System.assertEquals(2, results.size(), 'Expected two results');
        System.assertEquals(users[1].Id, results[0].userId, 'Expected User 2 Id for the first request');
        System.assertEquals(null, results[1].userId, 'Expected null for the second request since the longest inactive user was already picked in the first request');
    }
}