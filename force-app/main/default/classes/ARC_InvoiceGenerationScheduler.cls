/**
 * @description Scheduler for monthly invoice generation batch
 * @author lucas.benero@arcsona.com
 * @date 2026-02-09
 */
global class ARC_InvoiceGenerationScheduler implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        // Execute batch with 20 contracts per batch
        Database.executeBatch(new ARC_InvoiceGenerationBatch(), 20);
    }
}