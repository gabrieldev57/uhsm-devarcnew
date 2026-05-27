@isTest
private class EnvironmentDetectorTest {
    
    @isTest
    static void testGetEnvironmentType() {
        // Start test context
        Test.startTest();
        
        // Call the invocable method
        List<String> results = EnvironmentDetector.getEnvironmentType();
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, results, 'Result should not be null');
        System.assertEquals(1, results.size(), 'Should return exactly one result');
        
        String environmentType = results[0];
        System.assertNotEquals(null, environmentType, 'Environment type should not be null');
        
        // Verify it's either Sandbox or Production
        System.assert(
            environmentType == 'Sandbox' || environmentType == 'Production',
            'Environment should be either Sandbox or Production, got: ' + environmentType
        );
        
        // Additional verification - query Organization to confirm accuracy
        Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];
        String expectedType = org.IsSandbox ? 'Sandbox' : 'Production';
        
        System.assertEquals(
            expectedType, 
            environmentType,
            'Returned environment type should match Organization.IsSandbox'
        );
    }
    
    @isTest
    static void testGetEnvironmentType_MultipleInvocations() {
        // Test that multiple calls return consistent results
        Test.startTest();
        
        List<String> result1 = EnvironmentDetector.getEnvironmentType();
        List<String> result2 = EnvironmentDetector.getEnvironmentType();
        
        Test.stopTest();
        
        // Both calls should return the same value
        System.assertEquals(
            result1[0], 
            result2[0],
            'Multiple invocations should return consistent results'
        );
    }
    
    @isTest
    static void testGetEnvironmentType_SystemContext() {
        // Test that method works regardless of user context
        // This is important since the method is "without sharing"
        
        // Create a test user with minimal permissions
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser = new User(
            Alias = 'envtest',
            Email = 'envtest@uhsm.org.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'envtest' + System.currentTimeMillis() + '@uhsm.org.test'
        );
        
        insert testUser;
        
        Test.startTest();
        
        // Run as standard user without special permissions
        String resultAsUser;
        System.runAs(testUser) {
            List<String> results = EnvironmentDetector.getEnvironmentType();
            resultAsUser = results[0];
        }
        
        Test.stopTest();
        
        // Should still work and return valid environment type
        System.assert(
            resultAsUser == 'Sandbox' || resultAsUser == 'Production',
            'Should work for users without special permissions'
        );
    }
}