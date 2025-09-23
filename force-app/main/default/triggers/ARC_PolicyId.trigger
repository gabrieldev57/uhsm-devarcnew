trigger ARC_PolicyId on InsurancePolicy (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        ARC_IdHandler.insertPolicyId(Trigger.new);
    }
}