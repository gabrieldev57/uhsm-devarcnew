public class ARC_UserDeactivationService {
    
    public class DeactivationRequest {
        @InvocableVariable(label='User IDs' description='List of User IDs to deactivate' required=true)
        public List<String> userIds;
    }
    
    @future
    public static void deactivateUsersAsync(Set<Id> userIds) {
        if (userIds == null || userIds.isEmpty()) return;
        
        List<User> usersToUpdate = new List<User>();
        for (Id userId : userIds) {
            usersToUpdate.add(new User(Id = userId, IsActive = false));
        }
        
        if (!usersToUpdate.isEmpty()) {
            update usersToUpdate;
        }
    }
    
    @InvocableMethod(label='Deactivate Users' description='Deactivates a list of users by their IDs asynchronously.')
    public static void deactivateUsers(List<DeactivationRequest> requests) {
        if (requests == null || requests.isEmpty()) return;
        
        Set<Id> allUserIds = new Set<Id>();
        for (DeactivationRequest req : requests) {
            if (req.userIds != null && !req.userIds.isEmpty()) {
                for (String userId : req.userIds) {
                    allUserIds.add((Id) userId);
                }
            }
        }
        
        if (!allUserIds.isEmpty()) {
            deactivateUsersAsync(allUserIds);
        }
    }
}