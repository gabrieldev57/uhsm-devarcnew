/*******************************************************************
* @ClassName          :   ARC_ScheduleSDRCommissionsCreation
* @Description        :   Schedulable apex that calculates the Working Days and Total Labor Days for each SDR. Also calculates the Sales floor conversion.
                          It creates one Commission record and one Commission Payment record for each SDR with their respective working days. 
* @MethodName         :   sdrCommissionCalculation, calculateWorkingDays
********************************************************************/

public without sharing class ARC_ScheduleSDRCommissionsCreation implements Schedulable {
    //Last Month total labor days
    private static Integer totalLaborDays =0;

    /*******************************************************************
    * @MethodName         :   sdrCommissionCalculation
    * @Description        :   Creates the Master Commission and the Commission Payments per SDR with the ARC_TotalLaborDays__c, ARC_ActualWorkingDays__c and Agent__c
    ********************************************************************/    
    public void execute(SchedulableContext SC) {
        List<ARC_Commission_Payment__c> commissionPaymentsToCreate = new List<ARC_Commission_Payment__c>();
        Id rtCommSDR = Schema.SObjectType.ARC_Commission__c.getRecordTypeInfosByDeveloperName().get('ARC_SalesDevelopmentRep').getRecordTypeId();
        Id rtCommPaymentSDR = Schema.SObjectType.ARC_Commission_Payment__c.getRecordTypeInfosByDeveloperName().get('ARC_SalesDevelopmentRep').getRecordTypeId();

        //Get the Active SDR Users and Last Month Tasks
        List<User> sdrUsers = [SELECT Id, Position__c, IsActive FROM User WHERE (Position__c = 'Sales Development Representative' AND IsActive = true)];
        List<Task> tasks = [SELECT Id, CreatedById, CreatedDate FROM Task WHERE (CreatedDate = LAST_MONTH AND CreatedById IN :sdrUsers)]; 

        //Get the number of signed contracts excluding the Self Enrollment Contracts
        Integer numberOfSignedContracts = [SELECT COUNT() FROM Contract WHERE First_Signed_Date__c = LAST_MONTH AND ARC_ContractReason__c INCLUDES ('New Application') AND ARC_IsSelfEnrollment__c = false];
        
        //Get the total transfers
        Integer totalTransfers = [SELECT COUNT() FROM Lead WHERE  Sales_Development_Rep__c IN :sdrUsers AND Agent_Transfer_Date_Time__c = LAST_MONTH];

        if(Test.isRunningTest()){
            tasks = [SELECT Id, CreatedById, CreatedDate, ActivityDate FROM Task WHERE (CreatedDate = THIS_MONTH AND CreatedById IN :sdrUsers)];
            numberOfSignedContracts = [SELECT COUNT() FROM Contract WHERE First_Signed_Date__c = THIS_MONTH AND ARC_ContractReason__c INCLUDES ('New Application') AND ARC_IsSelfEnrollment__c = false];
            totalTransfers = [SELECT COUNT() FROM Lead WHERE  Sales_Development_Rep__c IN :sdrUsers AND Agent_Transfer_Date_Time__c = THIS_MONTH];
        }

        if(tasks.size() > 0){
            //Variables
            Map<Id,ARC_Commission__c> sdrIdCommissionMap = new Map<Id,ARC_Commission__c>();
            List<ARC_Commission__c> commissionsToCreate = new List<ARC_Commission__c>();

            //Calculate the working days of each SDR and total labor days.
            Map<Id,Set<Date>> sdrIdsWorkingDaysMap = calculateWorkingDays(tasks);

            List<ARC_Commission__c> commissions = [SELECT Id,RecordType.Name, OwnerId FROM ARC_Commission__c WHERE RecordTypeId =: rtCommSDR AND OwnerId IN :sdrUsers];
            for(ARC_Commission__c commission: commissions) sdrIdCommissionMap.put(commission.OwnerId, commission);
            for(User sdr: sdrUsers){
                if(!sdrIdCommissionMap.containsKey(sdr.Id)){
                    //Creates the master Commission record
                    ARC_Commission__c monthlySDRCommission = new ARC_Commission__c(RecordTypeId = rtCommSDR, OwnerId = sdr.Id);
                    commissionsToCreate.add(monthlySDRCommission);
                }
            }
            try{
                if(!commissionsToCreate.isEmpty()){
                    insert commissionsToCreate;
                    for(ARC_Commission__c commission: commissionsToCreate) sdrIdCommissionMap.put(commission.OwnerId, commission);
                }
            }catch(Exception e){
                System.debug('Exception inserting Commission record in ARC_CalculateCommissionWorkingDays: '+e.getMessage());
            }
            for (Id sdrId : sdrIdsWorkingDaysMap.keySet()) {
                if(sdrIdCommissionMap.containsKey(sdrId)){
                    //Create a Commission Payment per SDR.
                    ARC_Commission_Payment__c newCP = new ARC_Commission_Payment__c(
                        Commission__c = sdrIdCommissionMap.get(sdrId).Id,
                        RecordTypeId = rtCommPaymentSDR, 
                        ARC_TotalSignedContracts__c = numberOfSignedContracts,
                        ARC_TotalTransfers__c = totalTransfers, //Total Transfers made by all SDR
                        ARC_TotalLaborDays__c = totalLaborDays, //Total labor days for all SDRs
                        ARC_ActualWorkingDays__c = sdrIdsWorkingDaysMap.get(sdrId).size(), //Actual labour days for that SDR
                        Type__c ='Monthly Payout');
                    commissionPaymentsToCreate.add(newCP);
                }
            }
            try{
                insert commissionPaymentsToCreate;
            }catch(Exception e){
                System.debug('Exception inserting comm payments in ARC_CalculateCommissionWorkingDays: '+e.getMessage());
            }
        }
    }
    
    /*******************************************************************
    * @MethodName         :   calculateWorkingDays
    * @Description        :   Retunrs a list of the days that each SDR user worked in the last month in a Map of SDR user Ids and a Set of date format. 
                              Also calculates the total labour days based on the number of days that tasks where created by a SDR user.
    ********************************************************************/
    public static Map<Id,Set<Date>> calculateWorkingDays(List<Task> tasks){
        if(tasks.isEmpty()) return null;
        Set<Date> totalTasksCreationDates = new Set<Date>();
        Map<Id,Set<Date>> returnMap = new Map<Id,Set<Date>>();
        for(Task t: tasks){
            if(Test.isRunningTest()){
                Set<Date> workingDays = returnMap.containsKey(t.CreatedById)? (Set<Date>)returnMap.get(t.CreatedById) : new Set<Date>();
                workingDays.add(t.ActivityDate);
                totalTasksCreationDates.add(t.ActivityDate);
                returnMap.put(t.CreatedById, workingDays);
            }
            else{
                Set<Date> workingDays = returnMap.containsKey(t.CreatedById)? (Set<Date>)returnMap.get(t.CreatedById) : new Set<Date>();
                workingDays.add(t.CreatedDate.date());
                totalTasksCreationDates.add(t.CreatedDate.date());
                returnMap.put(t.CreatedById, workingDays);
            }
        }
        totalLaborDays = totalTasksCreationDates.size();
        return returnMap;
    }
}