public class CCRoundRobinHelper {
    
    @TestVisible
    private static User mockNextCC;
    
    @TestVisible
    private static Set<Id> testUserIds; // NEW: Filter to specific users during tests
    
    // Public method that contains the actual logic
    public static User getNextRoundRobinUser() {
        // Check for mock FIRST
        if (Test.isRunningTest() && mockNextCC != null) {
            System.debug('Using mock user: ' + mockNextCC.Name);
            return mockNextCC;
        }
        
        // Get or create settings record
        CC_RoundRobinSetting__c settings = CC_RoundRobinSetting__c.getOrgDefaults();
        if (settings == null || settings.Id == null) {
            settings = new CC_RoundRobinSetting__c(
                SetupOwnerId = UserInfo.getOrganizationId(),
                LastIndex__c = -1,
                LastAssignedUserId__c = null
            );
            insert settings;
        }
        
        // Lock for update
        settings = [
            SELECT Id, LastIndex__c, LastAssignedUserId__c 
            FROM CC_RoundRobinSetting__c 
            WHERE Id = :settings.Id
            FOR UPDATE
        ];
        
        // Query eligible users WITHOUT locking
        String query = 'SELECT Id, Name FROM User WHERE IsActive = true AND Team__c = \'Client Coordinator\' AND Round_Robin_Eligibility__c = \'Eligible\'';
        
        // NEW: In tests, optionally filter to specific test users
        if (Test.isRunningTest() && testUserIds != null && !testUserIds.isEmpty()) {
            query += ' AND Id IN :testUserIds';
        }
        
        query += ' ORDER BY Name ASC';
        
        List<User> eligibleUsers = Database.query(query);
        
        if (eligibleUsers.isEmpty()) {
            throw new InvocableException('No eligible users found for round robin assignment.');
        }
        
        Integer lastIndex = settings.LastIndex__c != null ? Integer.valueOf(settings.LastIndex__c) : -1;
        Id lastUserId = settings.LastAssignedUserId__c;
        
        Integer nextIndex;
        
        // Handle list changes
        if (lastUserId != null) {
            // Try to find where the last assigned user is NOW
            Integer currentPositionOfLastUser = null;
            for (Integer i = 0; i < eligibleUsers.size(); i++) {
                if (eligibleUsers[i].Id == lastUserId) {
                    currentPositionOfLastUser = i;
                    break;
                }
            }
            
            if (currentPositionOfLastUser != null) {
                // Last user still eligible - assign to next person
                nextIndex = Math.mod(currentPositionOfLastUser + 1, eligibleUsers.size());
            } else {
                // Last user became ineligible
                // Maintain relative position in the list
                if (lastIndex >= eligibleUsers.size()) {
                    // We were past the end, wrap to beginning
                    nextIndex = 0;
                } else {
                    // Assign to whoever is now at that index position
                    nextIndex = lastIndex;
                }
            }
        } else {
            // First assignment ever
            nextIndex = 0;
        }
        
        User nextUser = eligibleUsers[nextIndex];
        
        // Update locked settings record
        settings.LastIndex__c = nextIndex;
        settings.LastAssignedUserId__c = nextUser.Id;
        settings.LastAssignedDateTime__c = System.now();
        update settings;
            
        System.debug('Assigned to: ' + nextUser.Name + ' at index ' + nextIndex + ' out of ' + eligibleUsers.size() + ' users');
        
        return nextUser;
    }
    
    // Invocable wrapper that Flow calls
    @InvocableMethod(label='Get Next Round Robin User')
    public static List<User> getNextRoundRobinUserInvocable(List<RoundRobinRequest> requests) {
        User nextUser = getNextRoundRobinUser();
        return new List<User>{ nextUser };
    }
    
    // Helper methods for testing
    @TestVisible
    public static void setMockUser(User u) {
        mockNextCC = u;
    }
    
    @TestVisible
    public static void clearMock() {
        mockNextCC = null;
    }
    
    // NEW: Set specific users to consider during tests
    @TestVisible
    public static void setTestUsers(Set<Id> userIds) {
        testUserIds = userIds;
    }
    
    // NEW: Clear test user filter
    @TestVisible
    public static void clearTestUsers() {
        testUserIds = null;
    }
    
    public class RoundRobinRequest {
        @InvocableVariable
        public String placeholder;
    }
    
    @TestVisible
    public static void resetTestState() {
        mockNextCC = null;
        testUserIds = null; // NEW: Also clear test user filter
    }
    
    public class InvocableException extends Exception {}
}