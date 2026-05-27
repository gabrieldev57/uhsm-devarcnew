trigger ARC_UserTrigger on User (after insert) {
    if(Trigger.isAfter){
        ARC_UserTriggerHandler.setPermissionSetAndLicenseToPortalUser(Trigger.new, Trigger.oldMap, Trigger.isInsert);
        ARC_UserTriggerHandler.createSharingForRelatedAccount(Trigger.new);
    }
}