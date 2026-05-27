/**
 * Purpose:
 * - Platform Event trigger that listens to SG_Portal_User_Provisioning__e.
 * - Dispatches event records to SG_PortalUserProvisionSubscriber for Idempotent processing.
 *
 * Key points:
 * - Keep this trigger thin: no heavy logic.
 * - Subscriber evaluates the Contact's current state vs desired state and performs DML.
 */
trigger ARC_SGPortalUserProvisionTrigger on SG_Portal_User_Provisioning__e (after insert) {
    System.debug(' TRIGGER EXECUTING: ARC_SGPortalUserProvisionTrigger on SG_Portal_User_Provisioning__e');
    System.debug('Events received: ' + Trigger.new.size());
    SG_PortalUserProvisionSubscriber.run(Trigger.New);
}