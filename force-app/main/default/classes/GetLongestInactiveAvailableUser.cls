public class GetLongestInactiveAvailableUser {

    public class Request {
        @InvocableVariable(label='User IDs' required=true)
        public List<Id> userIds;
    }

    public class Response {
        @InvocableVariable(label='Longest Inactive User ID')
        public Id userId;
    }

    @InvocableMethod(label='Get Longest Inactive Available User' description='Returns the user ID of the longest inactive available user from the provided list of user IDs')
    public static List<Response> getLongestInactiveUserId(List<Request> requests) {
        Set<Id> previouslyIdentifiedUsers = new Set<Id>();
        List<Response> results = new List<Response>();

        for (Request req : requests) {
            List<Id> currentRequestUserIds = new List<Id>();
            for(Id userId : req.userIds) {
                if(!previouslyIdentifiedUsers.contains(userId)) {
                    currentRequestUserIds.add(userId);
                }
            }

            Id longestInactiveUserId = determineLongestInactiveUserId(currentRequestUserIds, previouslyIdentifiedUsers);

            if(longestInactiveUserId != null) {
                previouslyIdentifiedUsers.add(longestInactiveUserId);
            }

            Response result = new Response();
            result.userId = longestInactiveUserId;
            results.add(result);
        }
        return results;
    }

    private static Id determineLongestInactiveUserId(List<Id> userIds, Set<Id> excludeUsers) {
        // Query User_Skill
        List<User_Skill__c> userSkills = [SELECT User__c, Status__c, Last_Used_Date__c 
                                         FROM User_Skill__c 
                                         WHERE User__c IN :userIds AND User__c NOT IN :excludeUsers
                                         ORDER BY Last_Used_Date__c ASC];

        // Create a set of user IDs that have a User_Skill with 'In use' status
        Set<Id> inUseUsers = new Set<Id>();
        Map<Id, Datetime> userMostRecentLastUsedMap = new Map<Id, Datetime>();
        for (User_Skill__c skill : userSkills) {
            if (skill.Status__c == 'In use') {
                inUseUsers.add(skill.User__c);
            } else if (!userMostRecentLastUsedMap.containsKey(skill.User__c) || skill.Last_Used_Date__c > userMostRecentLastUsedMap.get(skill.User__c)) {
                userMostRecentLastUsedMap.put(skill.User__c, skill.Last_Used_Date__c);
            }
        }

        Id longestInactiveUserId = null;
        Datetime oldestMostRecentDatetime = null;

        // Find the user with the oldest most recent Last_Used_Date__c
        for (Id userId : userMostRecentLastUsedMap.keySet()) {
            if (!inUseUsers.contains(userId)) {
                if (oldestMostRecentDatetime == null || userMostRecentLastUsedMap.get(userId) < oldestMostRecentDatetime) {
                    oldestMostRecentDatetime = userMostRecentLastUsedMap.get(userId);
                    longestInactiveUserId = userId;
                }
            }
        }

        return longestInactiveUserId;
    }
}