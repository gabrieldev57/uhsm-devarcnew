public class ARC_PolicyBatchSchedulable implements Schedulable {
    private String whereClause;

    public ARC_PolicyBatchSchedulable(String whereClause) {
        this.whereClause = whereClause;
    }

    public void execute(SchedulableContext ctx) {
        // Execute the batch job
        Database.executeBatch(new ARC_PolicyTriggerHandler(whereClause), 5);
        // Delete the scheduled job to prevent recurrence
        CronTrigger ct = [SELECT Id FROM CronTrigger WHERE Id = :ctx.getTriggerId()];
        System.abortJob(ct.Id);
    }
}