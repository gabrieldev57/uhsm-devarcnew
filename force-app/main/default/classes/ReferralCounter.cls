global class ReferralCounter implements Schedulable {
    global void execute(SchedulableContext sc){
        
        ReferralCounterJob.run(); 
    }
}