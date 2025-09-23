global with sharing class ARC_SortMembersForReEnrollment implements vlocity_ins.VlocityOpenInterface {

    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'SortMembers') {
            SortMembers(inputMap, outputMap, options);
        }
        return true;
    }

    global static void SortMembers(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){

        Boolean existsNewMember = false;
        List<Object> newMembers = (List<Object>)inputMap.get('newMembers');
        if(newMembers[0] != null){
            existsNewMember = true;
        }

        List<Object> allMembers = (List<Object>)inputMap.get('allMembers');
        List<Map<String,Object>> listOfAllMembers = new List<Map<String,Object>>();
        List<Map<String,Object>> listOfOldMembers = new List<Map<String,Object>>();
        List<String> listOfNewMembersId = new List<String>();

        if(existsNewMember){
            
            for (Object obj : allMembers) {
                Map<String,Object> tempMap = (Map<String, Object>)obj;
                listOfAllMembers.add(tempMap);
            }
    
            for (Object obj : newMembers) {
                    String theId = (String)obj;
                    listOfNewMembersId.add(theId.trim());
            }
    
            for (Map<String,Object> currentMember : listOfAllMembers) {
                if(!listOfNewMembersId.contains(String.valueOf(currentMember.get('CensusMemberId')))){
                    listofOldMembers.add(currentMember);
                }
            }
    
            List<vlocity_ins__GroupCensusMember__c> newMembersInfo = [SELECT Id, Name FROM vlocity_ins__GroupCensusMember__c WHERE Id IN :listOfNewMembersId];
    
            List<vlocity_ins__GroupCensusMember__c> newList = new List<vlocity_ins__GroupCensusMember__c>();
    
            List<Map<String,String>> listOfNewMembers = new List<Map<String,String>>();
    
            for (vlocity_ins__GroupCensusMember__c member : newMembersInfo) {
                Map<String,String> mapOfNewMembers = new Map<String,String>();
                mapOfNewMembers.put('Id', member.Id);
                mapOfNewMembers.put('Name', member.Name);
                listOfNewMembers.add(mapOfNewMembers);
            }
            outputMap.put('newMembers', listOfNewMembers);
            outputMap.put('oldMembers', listofOldMembers);
        } else {

            outputMap.put('oldMembers', allMembers);
        }

        


    }

}