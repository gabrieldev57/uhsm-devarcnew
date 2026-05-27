public with sharing class InactiveCCReassignmentSched implements Schedulable {
    public void execute(SchedulableContext sc) {
        InactiveCCReassignmentBatch b = new InactiveCCReassignmentBatch();
        Database.executeBatch(b, 30);  // 30 × 3 = 90 operations (safe)
    }
}