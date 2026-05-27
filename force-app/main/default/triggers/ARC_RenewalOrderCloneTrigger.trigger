trigger ARC_RenewalOrderCloneTrigger on ARC_RenewalOrderClone__e (after insert) {
    ARC_RenewalOrderCloneSubscriber.run(Trigger.new);
}