/**
 * @description Schedulable class to run ARC_CVSElegibilityFileBatch on a schedule

 */
global class ARC_CVSElegibilityScheduler implements Schedulable {
    
    private Integer batchSize;
    private Integer sendFileEachNMembers;
    private Boolean sendFilesToTestSites;
    
    /**
     * @description Default constructor - uses default batch settings
     */
    global ARC_CVSElegibilityScheduler() {
        this.batchSize = 9;
        this.sendFileEachNMembers = 500;
        this.sendFilesToTestSites = false;
    }
    
    /**
     * @description Constructor with custom settings
     * @param batchSize Number of records per batch
     * @param sendFileEachNMembers Number of members per file chunk
     * @param sendFilesToTestSites Whether to send to test sites
     */
    global ARC_CVSElegibilityScheduler(Integer batchSize, Integer sendFileEachNMembers, Boolean sendFilesToTestSites) {
        this.batchSize = batchSize;
        this.sendFileEachNMembers = sendFileEachNMembers;
        this.sendFilesToTestSites = sendFilesToTestSites;
    }
    
    /**
     * @description Execute method called by the scheduler
     * @param ctx Schedulable context
     */
    global void execute(SchedulableContext ctx) {
        ARC_CVSElegibilityFileBatchPOC batch = new ARC_CVSElegibilityFileBatchPOC();
        batch.sendFileEachNMembers = this.sendFileEachNMembers;
        batch.sendFilesToTestSites = this.sendFilesToTestSites;
        
        Database.executeBatch(batch, this.batchSize);
        
    }
}