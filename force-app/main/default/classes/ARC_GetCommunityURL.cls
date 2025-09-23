global without sharing class ARC_GetCommunityURL implements vlocity_ins.VlocityOpenInterface {

    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'getCommunityURL') {
            getCommunityURL(inputMap, outputMap, options);
        }
        if (methodName == 'getOrganizationData') {
            getOrganizationData(inputMap, outputMap, options);
        }
        return true;
    }
    public static void getCommunityURL(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        // String instanceId = (String)inputMap.get('instanceId');
        
        Site site = [SELECT Id FROM Site WHERE Name = 'Member_Community' LIMIT 1];

        String communityUrl = [SELECT SecureURL FROM SiteDetail WHERE DurableId =: site.Id].SecureUrl;
        communityUrl = communityUrl.substring(0,communityUrl.length()-8);
        System.debug('Community url: ' + communityUrl);

        

        outputMap.put('communityUrl', communityUrl);
    }

    public static void getOrganizationData(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        try {
            // Get Organization data
            Organization org = [SELECT InstanceName, IsSandbox 
                            FROM Organization 
                            LIMIT 1];

            Domain domain = [SELECT Domain 
                            FROM Domain 
                            LIMIT 1];
            
            // Get User data
            String userId = (String)inputMap.get('userId');
            if (userId != null) {
                User usr = [SELECT Email 
                    FROM User 
                    WHERE Id = :userId];
                    outputMap.put('userEmail', usr.Email);
            }

            
            // Extract domain prefix from domain
            String domainPrefix = '';
            if(domain.Domain != null) {
                domainPrefix = domain.Domain.substringBefore('.');
            }
            
            // Set output values
            outputMap.put('domain', domain.Domain);
            outputMap.put('domainPrefix', domainPrefix);
            outputMap.put('orgInstance', org.InstanceName);
            outputMap.put('isSandbox', org.IsSandbox);
            outputMap.put('isProduction', domainPrefix == domain.Domain);
            
        } catch(Exception e) {
            outputMap.put('error', e.getMessage());
            System.debug('Error in getOrganizationData: ' + e.getMessage());
        }
    }
}