global without sharing class ARC_FilterUndCaseMemberReason implements vlocity_ins.VlocityOpenInterface{
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
    if (methodName == 'filterUCM') {
        filterUCM(inputMap, outputMap,options);
    }        
    return true;
    }

    public static void filterUCM(Map<String,Object> inputMap, Map<String,Object> outputMap,Map<String,Object> options) {
        List<Object> newMembers =(List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('newMembers')));
        List<Object> oldMembers = (List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('oldMembers')));
        List<Object> allMembers = (List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('allMembers')));
        String reason = String.valueOf(inputMap.get('Reason'));
        System.debug(newMembers);
        System.debug(oldMembers);
        System.debug(allMembers);
        List<Map<String,Object>> listNewMembers = new List<Map<String,Object>>();
        List<Map<String,Object>> listOldMembers = new List<Map<String,Object>>();
        List<Map<String,Object>> listAllMembers = new List<Map<String,Object>>();

        
        

        for (Object itemObj : newMembers) {
            Map<String, Object> item = (Map<String, Object>) itemObj;
            listNewMembers.add(item);
        }
        for (Object itemObj : oldMembers) {
            Map<String, Object> item = (Map<String, Object>) itemObj;
            listOldMembers.add(item);
        }
        for (Object itemObj : allMembers) {
            Map<String, Object> item = (Map<String, Object>) itemObj;
            listAllMembers.add(item);
        }
        
        
        for (Map<String, Object> member : listAllMembers) {
            Boolean inOld = false;
            Boolean inNew = false;
            for (Map<String, Object> oldMember : listOldMembers) {
                if (member.get('CensusMemberId')==oldMember.get('Id')) {
                    inOld=true;
                }
            }
            for (Map<String, Object> newMember : listNewMembers) {
                if (member.get('CensusMemberId')==newMember.get('Id')) {
                    inNew=true;
                }
            }
            if(inOld && inNew && reason != null){

                member.put('Reason',reason);
            }
            if(inNew && !inOld){
                member.put('Reason','Add Member');
            }
            if(inOld &&!inNew){
                member.put('Reason','Remove Member');
            }
        }
        outputMap.put('UnderwritingCaseMember',listAllMembers);
        System.debug(outputMap);
    }
}