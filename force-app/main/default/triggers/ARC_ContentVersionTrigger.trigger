trigger ARC_ContentVersionTrigger on ContentVersion (after insert) {
    ARC_ContentVersionHandler.processAfterInsert(Trigger.new);
}