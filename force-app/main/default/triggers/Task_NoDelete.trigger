/**
 * Before delete trigger on Task object to prevent users without a specific permission set or permission set group 
 * from deleting records. It checks if the user has the required permission via a direct permission set assignment 
 * or through a permission set group. System Administrator profile is exempted from the check and allowed to delete tasks.
 */
trigger Task_NoDelete on Task (before delete) 
{      
	// The name (not label) of the permission set that is required to delete tasks
    String permissionSetName = 'WS_Task_Delete';
    
    // Get the user's ID
    Id userId = UserInfo.getUserId();
    
    // Get the users's profile name
    String userProfileName;    
    List<Profile> profiles = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
    if (!profiles.isEmpty()) {
        userProfileName = profiles[0].Name;
    }

    // Check if the user is a System Administrator
    Boolean isSystemAdmin = userProfileName == 'System Administrator';

    // Check if the user has the specific permission via a permission set or a permission set group, unless they are a System Administrator
    Boolean hasPermissionSet = isSystemAdmin;
    
    if (!isSystemAdmin) {
        // Query the PermissionSet to check for direct permission set assignments
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetName];
        
        if (!permissionSets.isEmpty()) {
            // Query the PermissionSetGroupAssignment to check if the user is assigned to any of the groups that contain the permission set
            List<PermissionSetAssignment> groupAssignments = [SELECT Id 
                                                                   FROM PermissionSetAssignment 
                                                                   WHERE AssigneeId = :userId AND PermissionSetGroupId IN 
                                                                   	(SELECT PermissionSetGroupId 
                                                                     FROM PermissionSetGroupComponent 
                                                                     WHERE PermissionSetId IN :permissionSets)];
            
            List<PermissionSetAssignment> individualAssignments = [SELECT Id 
                                                                   FROM PermissionSetAssignment 
                                                                   WHERE AssigneeId = :userId AND PermissionSetId IN :permissionSets];
        
        
            hasPermissionSet = !groupAssignments.isEmpty() || !individualAssignments.isEmpty();
        }
    }

    // Loop through tasks to determine if deletion should be blocked
    for (Task a : Trigger.old) {
        // Check if the task is more than 2 minutes old
        if (System.now().getTime() - a.CreatedDate.getTime() > (2 * 60 * 1000)) {
            // Block deletion if the task is more than 2 minutes old and the user lacks the necessary permissions
            if (!hasPermissionSet && !isSystemAdmin) {
                a.addError('You are not allowed to delete tasks.');
            }
        }
    }

}