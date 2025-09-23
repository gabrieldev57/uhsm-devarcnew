public class ARC_PolicyBatchQueueable implements Queueable{
    private String whereClause;

    // Constructor
    public ARC_PolicyBatchQueueable(String whereClause) {
        this.whereClause = whereClause;
    }

    // Execute method
    public void execute(QueueableContext context) {
        // Execute the batch job
        Database.executeBatch(new ARC_PolicyTriggerHandler(whereClause), 5);
    }
}