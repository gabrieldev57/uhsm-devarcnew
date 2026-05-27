public without sharing class ARC_ContentVersionHandler {
    public static void processAfterInsert(List<ContentVersion> contentVersions) {

        List<String> allowedProfiles = new List<String>{
            'Employer Portal Profile',
            'Employer Admin',
            'Employer Viewer'
        };

        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name IN :allowedProfiles];
        Set<Id> allowedProfileIds = new Map<Id, Profile>(profiles).keySet();

        List<PermissionSetAssignment> psAssignments = [
            SELECT Id FROM PermissionSetAssignment 
            WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSet.Name = 'Employer_Admin_Permissions'
            LIMIT 1
        ];

        Boolean hasAccess = allowedProfileIds.contains(UserInfo.getProfileId()) 
                            || !psAssignments.isEmpty();

        if (!hasAccess) {
            return;
        }

        // Profile profile = [SELECT Id FROM Profile WHERE Name = 'Employer Portal Profile' LIMIT 1];
        // Boolean isEmployerPortalUser = false;
        // if(UserInfo.getProfileId() != profile.Id){
        //     return;
        // }

        List<ContentDocumentLink> linksToCreate = new List<ContentDocumentLink>();
        
        for(ContentVersion cv : contentVersions) {
            if(cv.Guest_Record_fileupload__c != null) {
                linksToCreate.add(new ContentDocumentLink(
                    LinkedEntityId = cv.Guest_Record_fileupload__c,
                    ContentDocumentId = cv.ContentDocumentId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
            }
        }
        
        if(!linksToCreate.isEmpty()) {
            insert linksToCreate;
        }
    }
}