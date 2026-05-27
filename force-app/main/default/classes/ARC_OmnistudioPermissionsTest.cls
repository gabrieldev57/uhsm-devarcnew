@isTest
private class ARC_OmnistudioPermissionsTest {

    @testSetup
    static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'testarc', 
            Email='testuser_arc@testorg.com', 
            EmailEncodingKey='UTF-8', 
            LastName='Testing', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='testuser_arc' + DateTime.now().getTime() + '@testorg.com'
        );
        insert testUser;

        PermissionSet ps = new PermissionSet(
            Label = 'Test Healthy Discount', 
            Name = 'Test_Healthy_Discount'
        );
        insert ps;
    }

    /**
     * @Description: Tests the successful retrieval of permissions when assigned directly to a user.
     */
    @isTest
    static void testInvokeMethodSuccess() {
        User u = [SELECT Id FROM User WHERE Alias = 'testarc' LIMIT 1];
        PermissionSet ps = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Test_Healthy_Discount' LIMIT 1];

        insert new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = ps.Id
        );

        Map<String, Object> inputMap = new Map<String, Object>{
            'UserId' => u.Id,
            'PSName' => ps.Name
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_OmnistudioPermissions arcPerms = new ARC_OmnistudioPermissions();

        Test.startTest();
        Boolean result = arcPerms.invokeMethod('getUserPermissionsHealthyDiscount', inputMap, outputMap, options);
        Test.stopTest();

        // Assertions
        Assert.isTrue(result, 'invokeMethod should return true');
        Assert.isTrue(outputMap.containsKey('Assignments'), 'outputMap must contain Assignments key');
        Assert.isTrue(outputMap.containsKey('UserProfile'), 'outputMap must contain UserProfile key');
        
        List<Map<String, Object>> assignments = (List<Map<String, Object>>)outputMap.get('Assignments');
        Assert.isFalse(assignments.isEmpty(), 'Assignments list should not be empty');
        Assert.areEqual(1, assignments[0].get('ListSize'), 'Reported ListSize should be 1');
    }

    /**
     * @Description: Tests the scenario where no permissions are found for the user.
     */
    @isTest
    static void testNoPermissionsFound() {
        User u = [SELECT Id FROM User WHERE Alias = 'testarc' LIMIT 1];
        
        // Use a dummy Permission Set Name that won't match
        Map<String, Object> inputMap = new Map<String, Object>{
            'UserId' => u.Id,
            'PSName' => 'NonExistentPermissionSet'
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        
        ARC_OmnistudioPermissions arcPerms = new ARC_OmnistudioPermissions();

        Test.startTest();
        arcPerms.invokeMethod('getUserPermissionsHealthyDiscount', inputMap, outputMap, new Map<String, Object>());
        Test.stopTest();

        // Assertions for empty results
        List<Map<String, Object>> assignments = (List<Map<String, Object>>)outputMap.get('Assignments');
        Assert.areEqual(0, assignments[0].get('ListSize'), 'If no permissions found, ListSize should be 0');
    }

    /**
     * @Description: Tests the logic when an invalid method name is passed to the interface.
     */
    @isTest
    static void testInvalidMethod() {
        ARC_OmnistudioPermissions arcPerms = new ARC_OmnistudioPermissions();
        
        Test.startTest();
        Boolean result = arcPerms.invokeMethod('invalidMethodName', new Map<String, Object>(), new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();

        Assert.isTrue(result, 'The implementation returns true even if the method name is not recognized');
    }

    /**
     * @Description: Tests the exception handling block by passing incomplete input data.
     */
    @isTest
    static void testExceptionHandling() {
        Map<String, Object> inputMap = new Map<String, Object>(); 
        Map<String, Object> outputMap = new Map<String, Object>();

        ARC_OmnistudioPermissions arcPerms = new ARC_OmnistudioPermissions();

        Test.startTest();
        try {
            arcPerms.invokeMethod('getUserPermissionsHealthyDiscount', inputMap, outputMap, new Map<String, Object>());
            Assert.fail('An exception should have been thrown due to missing UserId');
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'Exception message should be populated');
        }
        Test.stopTest();
    }
}