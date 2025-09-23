global without sharing class ARC_DeleteCensusMembersGuestUser implements vlocity_ins.VlocityOpenInterface {
    
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'deleteCensusMembers') {
            deleteCensusMembers(inputMap, outputMap, options);
        }
        return true;
    }

    public static void deleteCensusMembers(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){

        List<Object> members = (List<Object>)inputMap.get('Members');
        List<Map<String,Object>> listOfMembers = new List<Map<String,Object>>();
        for (Object obj : members) {
            Map<String,Object> tempMap = (Map<String, Object>)obj;
            listOfMembers.add(tempMap);
        }
        Set<String> setId = new Set<String>();
        for (Map<String,Object> mapa : listOfMembers) {
            for (String member : mapa.keySet()) {
                String memberId = vlocity_ins.UserSecurity.decrypt(String.valueOf(mapa.get('Id')));
                setId.add(memberId);
            }
        }
        List<vlocity_ins__GroupCensusMember__c> memberToDelete = [SELECT Id FROM vlocity_ins__GroupCensusMember__c WHERE Id IN :setId];
        if (!memberToDelete.isEmpty()) {
            delete memberToDelete;
        }
        
        outputMap.put('Ids', setId);

    }
}