/**
 * Runs in system context when invoked from Flow
 * Users do not need access to the Organization object
 */
public without sharing class EnvironmentDetector {
    
    @InvocableMethod(label='Get Environment Type' 
                     description='Returns whether running in Sandbox or Production')
    public static List<String> getEnvironmentType() {
        List<String> result = new List<String>();
        
        // This query runs with system privileges
        // regardless of the running user's permissions
        Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];
        result.add(org.IsSandbox ? 'Sandbox' : 'Production');
        
        return result;
    }
}