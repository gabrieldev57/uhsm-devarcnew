trigger AccountTrigger on Account (before update, after insert, after update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        AccountTeamsHandler.captureSellingAgentData(Trigger.new, Trigger.oldMap);

        // Clear sequence numbers when Member ID changes
        AccountSequenceNumberHandler.clearSequenceOnMemberIdChange(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        AccountTeamsHandler.recreateSellingAgents(Trigger.new, Trigger.oldMap);

        // Assign sequence numbers when needed
        AccountSequenceNumberHandler.assignSequenceNumbers(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        // Assign sequence numbers for new accounts
        AccountSequenceNumberHandler.assignSequenceNumbers(Trigger.new, null);
    }
}