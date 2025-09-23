global class AgesUpBatchClass implements Database.Batchable<sObject>,Schedulable{

    public static List<vlocity_ins__GroupCensusMember__c> memberIds = new List<vlocity_ins__GroupCensusMember__c>();
    private Date contractEffectiveDate;
    private Date memberDOB;
    
    public AgesUpBatchClass() {}
    /**
     * This method is called when the scheduled job is triggered.
     * It creates and executes an instance of the AgesUpBatchClass batch.
     * 
     * @param ctx The SchedulableContext parameter containing the context for the scheduled job.
     */
    global void execute(SchedulableContext ctx) {
        AgesUpBatchClass AgesUp = new AgesUpBatchClass();
        Database.executeBatch(AgesUp, 20);
    }
    
    /**
     * This method is called at the beginning of the batch job.
     * It returns a QueryLocator that defines the scope of records to be processed in batches.
     * 
     * @param BC The Database.BatchableContext parameter that contains the context for the batch job.
     * @return A QueryLocator representing the records to be processed.
 	*/
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
            SELECT Id,
            vlocity_ins__Birthdate__c,
            vlocity_ins__CensusId__c,
            vlocity_ins__ContactId__r.Email,
            Is_Oldest_Member__c,
            vlocity_ins__FirstName__c,
            vlocity_ins__IsPrimaryMember__c,
            ARC_Age__c,
            Age_Change_In_60_Days__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE  ARC_ActiveMember__c=true
            AND ARC_Age__c >= 25 
            AND Is_Oldest_Member__c = true
        ]);
    }

    /**
     * This method is called to process a batch of GroupCensusMember records.
     * 
     * @param BC The Database.BatchableContext parameter that contains the context for the batch job.
     * @param members A list of GroupCensusMember records to be processed in the current batch.
     */
    global void execute(Database.BatchableContext BC, List<vlocity_ins__GroupCensusMember__c> members){
        List<Id> censusIds = new List<Id>();
        List<Id> contractIds = new List<Id>();

        // Add the Census Id from the members List to the censusIds List
		for (vlocity_ins__GroupCensusMember__c cm : members) {
            //censusIds.add(members[0].vlocity_ins__CensusId__c);
            String censusId =cm.vlocity_ins__CensusId__c;
        
            // Add the Activated Contract that is tied to the censusId, to the contracts List
            List<Contract> contracts = [
                SELECT Id, ARC_EffectiveDate__c,vlocity_ins__EnrollmentCensusId__c,Status,ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Date__c,
                Ages_Up_Manuel_Delay__c,CreatedDate
                FROM Contract 
                WHERE vlocity_ins__EnrollmentCensusId__c =: censusId AND Status =: 'Activated' AND ARC_EffectiveDate__c < LAST_N_DAYS:60
                ORDER BY CreatedDate ASC 
                LIMIT 1
            ];    

            // Check to make sure we found an Active Contract
            if (contracts.size() > 0) {
                Date today = Date.today();
                Date ageUpManualDelay;

                String ChargeDate;
                String contractStatus;
                System.debug('birthdate: '+ cm.vlocity_ins__Birthdate__c);

                contractStatus=contracts[0].Status;
                ChargeDate=contracts[0].ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Date__c;
                ageUpManualDelay=contracts[0].Ages_Up_Manuel_Delay__c;       
                contractEffectiveDate=contracts[0].ARC_EffectiveDate__c;
                System.debug('contractEffectiveDate: '+ contractEffectiveDate);

                memberDOB = cm.vlocity_ins__Birthdate__c;
                //Find the next anniversary date of the effective date on the Contract
                Date effectiveDateAnniversary = AgeUpUtilityClass.findNextAnniversary(contractEffectiveDate);
                //Find the next members next birthday
                Date nextBirthday = AgeUpUtilityClass.findNextAnniversary(memberDOB);

                Boolean QualifiedMember=false;                
                QualifiedMember =  cm.Age_Change_In_60_Days__c;

                System.debug('QualifiedMember: '+ QualifiedMember);

                if (QualifiedMember && ageUpManualDelay == null) {
                    //Get the Medical Plan from the Contract
                    List<vlocity_ins__ContractLineItem__c> CLI=[
                        SELECT Id, vlocity_ins__ProductName__c,vlocity_ins__ProductSubType__c,vlocity_ins__ProductType__c,vlocity_ins__ContractId__c 
                        FROM vlocity_ins__ContractLineItem__c 
                        WHERE vlocity_ins__ContractId__c = :contracts[0].Id AND vlocity_ins__ProductType__c='Medical' AND vlocity_ins__ProductSubType__c='PPO' 
                        LIMIT 1];		
                    System.debug('CLI Size: ' + CLI.size());   
                                                            
                    if (CLI.size() > 0 
                        && CLI[0].vlocity_ins__ProductName__c.Contains('WeShare') ) {
                        // ChargeDay is the day of the month that the member is charged
                        Integer ChargeDay = Integer.valueOf(ChargeDate);
                        // MonthAfterBirthday is the birthdate date on the month after the member's birthday
                        // Unclear why, but this is requirement specifically called out in ticket 358
                        // https://uhsm.atlassian.net/browse/UHSM-358
                        Date MonthAfterBirthday = nextBirthday.addMonths(1);
                        // DraftDate is the day we will charge the updated order/contract
                        Date DraftDate;
                        Integer daysUntilBirthday;


                        DraftDate = Date.newInstance(MonthAfterBirthday.year(), MonthAfterBirthday.month(), ChargeDay);
                        DaysUntilBirthday = today.daysBetween(nextBirthday);

                        System.debug('DraftDate: ' + DraftDate);
                        System.debug('DaysUntilBirthday: ' + DaysUntilBirthday);
                    
                        //Check for existing active Healthy Discount
                        Boolean oldMedicalPriceHadHD=false;
                        List<Healthy_Discount__c> hd=[
                            SELECT Id, Is_Active__c,Calculate_expiry_date__c,Contract__c 
                            FROM Healthy_Discount__c 
                            WHERE Contract__c = :contracts[0].Id AND Is_Active__c = true
                            ORDER BY Id DESC 
                            LIMIT 1];

                        if (hd.size() > 0) {
                            if (hd[0].Calculate_expiry_date__c >  DraftDate) {
                                oldMedicalPriceHadHD=true;
                            }else {
                                oldMedicalPriceHadHD=false;
                            }
                        }
                        System.debug('oldMedicalPriceHadHD: ' + oldMedicalPriceHadHD);
                        System.debug('daysUntilBirthday: ' + daysUntilBirthday);

                        String procedureName = 'Reprice_RepriceInSixtydays';
                        Map<String, Object> ipInput = new Map<String, Object> ();
                        Map<String, Object> ipOutput = new Map<String, Object> ();
                        Map<String, Object> ipOptions = new Map<String, Object> ();

                        if (daysUntilBirthday == 60)  {
                                try {
                                    ipInput.put('ContextId', cm.Id);
                                    ipInput.put('DraftDate', DraftDate);
                                    ipInput.put('oldMedicalPriceHadHD', oldMedicalPriceHadHD);
                                    ipOutput = (Map<String, Object>) vlocity_ins.IntegrationProcedureService.runIntegrationService(procedureName, ipInput, ipOptions);
                                    System.debug('IPOutput: ' + ipOutput);
                                } catch (Exception e) {
                                System.debug(e);
                                }
                            }
                    }
                } else {System.debug('Not Qualified and/or Manual Delay');}
            } else {System.debug('No Contract Found');}                                           
        }
    }

    global void finish(Database.BatchableContext BC){
    }

}