trigger ARC_DisablePortalUserTrigger on ARC_DisablePortalUser__e (after insert) {

    List<Id> userIds = Trigger.new[0].ARC_UserId__c.split(';');
    List<User> usersToUpdate = new List<User>();
        if(userIds.size()>0){
            for(Id userId: userIds){
                User userRecord = new User(Id = userId, IsPortalEnabled = false);
                usersToUpdate.add(userRecord);
            }
            try{
                update usersToUpdate;
                System.debug('Member Portal Users Deactivated!');
            }
            catch(Exception e){
                System.debug('Error in ARC_LeadSourceTriggerHandler.disableExistingUser: '+e.getMessage());
            }
        }
}