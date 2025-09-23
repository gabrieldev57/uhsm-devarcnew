/**
 * @description       : Controller class for creating ARC_ResetPasswordExpirationLink__mdt through de deployment API
 *                      metadata cannot be modified using DML.
 * @author            : Francisco Caliaba
 * @group             : 
 * @last modified on  : 12-22-2023
 * @last modified by  : Francisco Caliaba
**/
public without sharing class ARC_ExpirationLinksController {

    /**
    * @description Inserts ARC_ResetPasswordExpirationLink__mdt records for a List of Users in bulk
    * @author Francisco Caliaba | 12-22-2023 
    * @param users 
    * @param dateOfExpiration 
    **/
    public static void createExpirationLinkBulk(List<User> users, Date dateOfExpiration) {
        Map<Id, User> usersMap = new Map<Id, User>(users);
        List<ARC_ExpirationLink__c> links = [SELECT Id,ARC_UserId__c,ARC_ExpirationDate__c,ARC_IsUsed__c FROM ARC_ExpirationLink__c WHERE ARC_UserId__c IN: usersMap.keySet()];
        Map<String, ARC_ExpirationLink__c> linksMap = new Map<String, ARC_ExpirationLink__c>();
        for (ARC_ExpirationLink__c l : links) {
            linksMap.put(l.ARC_UserId__c, l);
        }

        List<ARC_ExpirationLink__c> linksToUpsert = new List<ARC_ExpirationLink__c>();
        for (User u : users) {
            ARC_ExpirationLink__c l = linksMap.get(u.Id) != null ? (ARC_ExpirationLink__c)linksMap.get(u.Id) : new ARC_ExpirationLink__c();
            l.ARC_ExpirationDate__c = dateOfExpiration;
            l.Name = u.Id;
            l.ARC_UserId__c = u.Id;
            l.ARC_IsUsed__c = false;

            linksToUpsert.add(l);
        }
        Database.upsert(linksToUpsert, false);
    }

    /**
    * @description Inserts ARC_ResetPasswordExpirationLink__mdt records for a List of User ids in bulk
    * @author Francisco Caliaba | 12-22-2023 
    * @param userIds 
    * @param dateOfExpiration 
    **/
    public static void createExpirationLinkBulkIds(List<Id> userIds, Date dateOfExpiration) {
        List<ARC_ExpirationLink__c> links = [SELECT Id,ARC_UserId__c,ARC_ExpirationDate__c,ARC_IsUsed__c FROM ARC_ExpirationLink__c WHERE ARC_UserId__c IN: userIds];
        Map<String, ARC_ExpirationLink__c> linksMap = new Map<String, ARC_ExpirationLink__c>();
        for (ARC_ExpirationLink__c l : links) {
            linksMap.put(l.ARC_UserId__c, l);
        }

        List<ARC_ExpirationLink__c> linksToUpsert = new List<ARC_ExpirationLink__c>();
        for (Id uId : userIds) {
            ARC_ExpirationLink__c l = linksMap.get(uId) != null ? (ARC_ExpirationLink__c)linksMap.get(uId) : new ARC_ExpirationLink__c();
            l.ARC_ExpirationDate__c = dateOfExpiration;
            l.Name = uId;
            l.ARC_UserId__c = uId;
            l.ARC_IsUsed__c = false;
            linksToUpsert.add(l);
        }
        List<Database.UpsertResult> result = Database.upsert(linksToUpsert, false);
        System.debug(result);
    }

    @AuraEnabled
    public static Map<String,Object> validateLink(Id userId) {
        Map<String, Object> response = new Map<String, Object>();
        try {
            List<ARC_ExpirationLink__c> validLinkRecord = [SELECT Id FROM ARC_ExpirationLink__c WHERE ARC_UserId__c =: userId AND ARC_ExpirationDate__c >= :Date.today() AND ARC_IsUsed__c = false LIMIT 1];
            if(!validLinkRecord.isEmpty()){
                response.put('success', true);
                response.put('message', 'Link is valid');
            }
            else{
                response.put('success', false);
                response.put('message', 'Link is not valid or has expired');
            }
        } catch (QueryException e) {
            response.put('success', false);
            response.put('message', 'Link is not valid or has expired');
        }
        return response;
    }

    /**
    * @description Method used to nullify a link once it has been used by the user, so it cannot be used again for security reasons.
    * @author Francisco Caliaba | 12-26-2023 
    * @param userId 
    **/
    public static void closeExpirationLink(Id userId){
        List<ARC_ExpirationLink__c> links = [SELECT Id,ARC_IsUsed__c FROM ARC_ExpirationLink__c WHERE ARC_UserId__c =: userId AND ARC_IsUsed__c = false];
        if(!links.isEmpty()){
            for(ARC_ExpirationLink__c link: links){
                link.ARC_IsUsed__c = true;
            }
            Database.update(links);
        }
    }
}