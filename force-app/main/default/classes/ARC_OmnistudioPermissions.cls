global without sharing class ARC_OmnistudioPermissions implements vlocity_ins.VlocityOpenInterface {

    /**
     * @Description: Omnistudio permissions class that retrieve information from objects affected by omnistudio permissions.
     * This class implements the VlocityOpenInterface to allow for dynamic method invocation.
     * 
     * @param methodName: The name of the method to be invoked
     * @param inputMap: Map containing input parameters for the method being called
     * @param outputMap: Map to store the results of the method execution
     * @param options: Additional configuration options that may be required for specific implementations
     * @return Boolean: Returns true to indicate method execution (actual validation to be implemented)
    */
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'getUserPermissionsHealthyDiscount') {
            getUserPermissionsHealthyDiscount(inputMap, outputMap, options);
        }
        /*else if (methodName == 'otherMethod') {
            otherMethod(inputMap, outputMap, options);
        }*/
        return true;       
    }    

    /**
     * @Description: Retrieve the User information.
     * 
     * @throws Exception if operations fail
     */
    public static Map<String, Object> getUserPermissionsHealthyDiscount(Map<String, Object> inputData, Map<String,Object> outputMap, Map<String,Object> options) {
        try {
            String userId = (String)inputData.get('UserId');
            String psName = (String)inputData.get('PSName');

            User user = [SELECT Id, ProfileId FROM User WHERE Id =: userId];
            Profile profile = [SELECT Id, Name FROM Profile WHERE Id =: user.ProfileId];

            List<PermissionSetAssignment> permissionSetAssignments = null;
            List<PermissionSetGroupComponent> permissionSetGroupComponent = null;
            List<PermissionSetAssignment> permissionSetGroupAssignments = null;

            // Permission Set Assignament
            permissionSetAssignments = [
                SELECT Id, AssigneeId, PermissionSet.Name, PermissionSetId 
                FROM PermissionSetAssignment 
                WHERE AssigneeId =: userId AND PermissionSet.Name =: psName
            ];

            // Permission Set Group Component
            permissionSetGroupComponent = [
                SELECT Id, PermissionSetGroupId 
                FROM PermissionSetGroupComponent 
                WHERE PermissionSet.Name =: psName
            ];

            Set<Id> permissionSetGroupIdSet = new Set<Id>();
            if (permissionSetGroupComponent != null && !permissionSetGroupComponent.isEmpty()) {
                for (PermissionSetGroupComponent psgc : permissionSetGroupComponent) {
                    permissionSetGroupIdSet.add(psgc.PermissionSetGroupId);
                }
            }

            if (!permissionSetGroupIdSet.isEmpty()) {
                // Permission Set Group Assignament
                permissionSetGroupAssignments = [
                    SELECT Id, AssigneeId, PermissionSet.Name, PermissionSetId, PermissionSetGroupId 
                    FROM PermissionSetAssignment 
                    WHERE AssigneeId =: userId AND PermissionSetGroupId =: permissionSetGroupIdSet
                ];
            }
        
            List<Map<String, Object>> assignamentsList = new List<Map<String, Object>>();

            if (permissionSetAssignments != null && !permissionSetAssignments.isEmpty()) {
                for (PermissionSetAssignment psa : permissionSetAssignments) {
                    Map<String, Object> aux = new Map<String, Object>();

                    aux.put('PemissionSetName', psa.PermissionSet.Name);
                    aux.put('PemissionSetId', psa.PermissionSetId);
                    aux.put('ListSize', 1);

                    assignamentsList.add(aux);
                }
            }
            
            if (permissionSetGroupAssignments != null && !permissionSetGroupAssignments.isEmpty()) {
                for (PermissionSetAssignment psga : permissionSetGroupAssignments) {
                    Map<String, Object> aux = new Map<String, Object>();

                    aux.put('PemissionSetGroupName', psga.PermissionSet.Name);
                    aux.put('PemissionSetGroupId', psga.PermissionSetGroupId);
                    aux.put('ListSize', 1);

                    assignamentsList.add(aux);
                }
            }

            if (assignamentsList.isEmpty()) {
                Map<String, Object> aux = new Map<String, Object>();
                aux.put('ListSize', 0);

                assignamentsList.add(aux);
            }
            
            outputMap.put('Assignments', assignamentsList);
            outputMap.put('UserProfile', profile.Name);

        } catch (Exception e) {
            System.debug('Exception while getUserPermissionsHealthyDiscount: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
        return outputMap;
    }
}