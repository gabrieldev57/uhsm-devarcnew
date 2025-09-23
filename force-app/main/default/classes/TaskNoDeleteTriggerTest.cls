@IsTest
public class TaskNoDeleteTriggerTest {
    Private static User testUserWithPermission;
    Private static User testUserWithoutPermission;
    Private static User testUserSystemAdmin;
    Private static Task testTasksWithPermission;
    Private static Task testTasksWithoutPermission;
    Private static Task testTasksSystemAdmin;
    Private static Task tasksToDelete;
    
    public static List<User> setup() {
        // The name (not label) of the permission set that is required to delete tasks
        String permissionSetName = 'WS_Task_Delete';
        
        // Retrieve the permission set to assign to users
        PermissionSet permissionSet = [SELECT Id 
                                       FROM PermissionSet 
                                       WHERE Name = :permissionSetName
                                       LIMIT 1];
        
        // Retrieve the desired profile (e.g., 'WS Sales')
        Profile wsSalesProfile = [SELECT Id 
                                  FROM Profile 
                                  WHERE Name = 'WS Sales'
                                  LIMIT 1];
        
        // Retrieve the desired system administrator profile
        Profile sysAdminProfile = [SELECT Id 
                                   FROM Profile 
                                   WHERE Name = 'System Administrator'
                                   LIMIT 1];
        
        // Retrieve a role to assign to users if necessary
        UserRole wsSalesRole = [SELECT Id 
                                FROM UserRole 
                                WHERE Name = 'Account Executive' 
                                LIMIT 1];
        
        // Create a user with permission set
        User testUserWithPermission = new User(
            FirstName = 'Test',
            LastName = 'UserWithPermission',
            Email = 'userwithpermission@uhsm.org',
            Username = 'userwithpermission@uhsm.org.' + System.currentTimeMillis() + '.test',
            Alias = 'usrwp',
            ProfileId = wsSalesProfile.Id,
            UserRoleId = wsSalesRole.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        
        // Create a user without permission set
        User testUserWithoutPermission = new User(
            FirstName = 'Test',
            LastName = 'UserWithoutPermission',
            Email = 'userwithoutpermission@uhsm.org',
            Username = 'userwithoutpermission@uhsm.org.' + System.currentTimeMillis() + '.test',
            Alias = 'usrwo',
            ProfileId = wsSalesProfile.Id,
            UserRoleId = wsSalesRole.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        
        // Create a system administrator user
        User testUserSystemAdmin = new User(
            FirstName = 'Test',
            LastName = 'SystemAdminUser',
            Email = 'systemadmin@uhsm.org',
            Username = 'systemadmin@uhsm.org.' + System.currentTimeMillis() + '.test',
            Alias = 'sysadm',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        
        // Insert all users
        insert new List<User> { testUserWithPermission, testUserWithoutPermission, testUserSystemAdmin };
        
        // Assign permission set to the user with permission
        PermissionSetAssignment assignment = new PermissionSetAssignment(
            PermissionSetId = permissionSet.Id, 
            AssigneeId = testUserWithPermission.Id
        );
        insert assignment;
        
        System.debug('Assigned Permission Set: ' + assignment.PermissionSetId);
        
        // Return the list of setup users
        return new List<User>{ testUserWithPermission, testUserWithoutPermission, testUserSystemAdmin };
    }

    
    @isTest
    public static void testDeletes(){
        // Create tasks associated with each user
         
        List<User> testUsers = setup();
        
        if (testUsers[0] != null) {
        System.debug('testUserWithPermission in testDeletes: ' + testUsers[0].Id);
        } else {
            System.debug('testUserWithPermission = null');
        }
        
        List <PermissionSetAssignment> assignedPermissionSet = [SELECT Id, PermissionSetId, AssigneeId
                                                        From PermissionSetAssignment
                                                        Where AssigneeId = :testUsers[0].Id];
        
        for (PermissionSetAssignment a : assignedPermissionSet){
            System.debug('Permission Set Id  = ' + a.PermissionSetId);
        }
        
        Task testTasksWithPermission = new Task(OwnerId = testUsers[0].Id, 
                                                Subject = 'With Permission',
                                                Status = 'Completed',
                                                Priority = 'High');
        Task testTasksWithoutPermission = new Task(OwnerId = testUsers[1].Id, 
                                                Subject = 'Without Permission',
                                                Status = 'Completed',
                                                Priority = 'High',
                                                CreatedDate = System.now().addMinutes(-3));
        Task testTasksSystemAdmin = new Task(OwnerId = testUsers[2].Id, 
                                                Subject = 'SystemAdmin Permission',
                                                Status = 'Completed',
                                                Priority = 'High');
        
        // Using RunAs here in order to create a separater DML Transaction from the Permission insert in Setup
        System.runas(testUsers[0]){
            insert testTasksWithPermission;
            insert testTasksWithoutPermission;
            insert testTasksSystemAdmin;      
        }
        // Perform the delete operation on the test tasks
        tasksToDelete = [SELECT Id 
                              FROM Task 
                              WHERE Id = :testTasksWithPermission.Id];
        System.runAs(testUsers[0]) {
            delete tasksToDelete;
        }
        
        // Assert that the tasks are deleted without any errors
        System.assertEquals(0, [SELECT COUNT() 
                                FROM Task 
                                WHERE Id = :testTasksWithPermission.Id]);


        // Perform the delete operation on the test tasks
        tasksToDelete = [SELECT Id 
                         FROM Task 
                         WHERE Id = :testTasksWithoutPermission.Id];
        System.runAs(testUsers[1]) {
            try{
                delete tasksToDelete;
                
            } catch (DmlException ex) {
                System.debug('ex.getDmlType(0): ' + ex.getDmlType(0));
                // Assert that the tasks are not deleted and an error is added
                List<Task> remainingTasks = [SELECT Id 
                                             FROM Task 
                                             WHERE Id = :testTasksWithoutPermission.Id];
                System.assertEquals(1, remainingTasks.size());
            }
        }
        

           
        // Perform the delete operation on the test tasks
       tasksToDelete = [SELECT Id 
                                    FROM Task 
                                    WHERE Id = :testTasksSystemAdmin.Id];
        System.runAs(testUsers[2]) {
            delete tasksToDelete;
        }
       
        // Assert that the tasks are deleted without any errors
        System.assertEquals(0, [SELECT COUNT() 
                                FROM Task 
                                WHERE Id = :testTasksSystemAdmin.Id]);
    }
}