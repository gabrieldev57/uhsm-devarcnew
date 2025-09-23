global without sharing class ARC_CreateUsersForEnroll implements vlocity_ins.VlocityOpenInterface{

    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'createUsers') {
            createUsers(inputMap, outputMap);
        }        
        return true;
    }

    public static void createUsers(Map<String,Object> inputMap, Map<String,Object> outputMap){
        String censusId = (String) inputMap.get('censusId');
        String accountId = (String) inputMap.get('accountId');
        vlocity_ins__GroupCensusMember__c member = [SELECT Id, vlocity_ins__LastName__c, vlocity_ins__FirstName__c, vlocity_ins__Email__c, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c =: censusId AND vlocity_ins__IsPortalUser__c = true LIMIT 1];
        String alias = member.vlocity_ins__FirstName__c.substring(0,1).toLowerCase() + member.vlocity_ins__LastName__c.substring(0,3).toLowerCase();  
        String nickName = member.vlocity_ins__FirstName__c + member.vlocity_ins__LastName__c + Integer.valueof((Math.random() * 10000));
        Profile p = [SELECT Name, Id FROM Profile WHERE Name = 'Member Community' LIMIT 1];

        try {
            User u = new User();
            U.LastName = member.vlocity_ins__LastName__c;
            U.FirstName = member.vlocity_ins__FirstName__c;
            U.Alias = alias;
            U.Email = member.vlocity_ins__Email__c;
            U.Username = member.vlocity_ins__Email__c;
            U.CommunityNickname = nickName;
            U.ContactId = member.vlocity_ins__ContactId__c;
            U.ProfileId = p.Id;
            U.TimeZoneSidKey = 'America/New_York';
            U.LanguageLocaleKey = 'en_US';
            U.EmailEncodingKey = 'UTF-8';
            U.LocaleSidKey = 'en_US';
            insert u;

            outputMap.put('primaryUser', u.Id);    
        } catch (Exception e) {
            System.debug(e);
            outputMap.put('result','Error on user creation: ' + e.getMessage());
        }
    }
}