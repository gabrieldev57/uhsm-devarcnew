trigger ARC_AccountContactRelationTrigger on AccountContactRelation (after insert) {
    ARC_SGContactPortalUserHandler.runFromACR(Trigger.New);
}