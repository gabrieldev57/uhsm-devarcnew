/**
 * Purpose:
 * - Entry point for Contact-driven portal user provisioning.
 * - Delegates directly to ARC_SGContactPortalUserHandler to evaluate if an event is needed.
 */
trigger ARC_Contact on Contact (after insert, after update) {
    ARC_SGContactPortalUserHandler.run(Trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate);
}