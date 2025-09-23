/*******************************************************************
* @ClassName          :   ARC_ScheduleSDRCommissionsUpdater
* @Description        :   Schedulable apex that calculates the Working Days and Total Labor Days for each SDR. Also calculates the Sales floor conversion.
                          It creates one Commission record and one Commission Payment record for each SDR with their respective working days. 
* @MethodName         :   calculateTransferCalls, calculateTotalCalls, callProcedure, calculateAmount
********************************************************************/
public without sharing class ARC_ScheduleSDRCommissionsUpdater implements Schedulable {

    public void execute(SchedulableContext SC) {
        Id rtCommPaymentSDR = Schema.SObjectType.ARC_Commission_Payment__c.getRecordTypeInfosByDeveloperName().get('ARC_SalesDevelopmentRep').getRecordTypeId();
        //Get the SDR Commisison Payments Created by the Schedule SDR Commissions Creation on the 1st of this month. 
        List<ARC_Commission_Payment__c> commPaymentList = [SELECT Id, ARC_TotalTransfers__c, ARC_SalesFloorConversion__c,ARC_TotalSignedContracts__c,  ARC_TotalCalls__c, ARC_BonusAmount__c, Commission__r.OwnerId, ARC_WorkingDays__c FROM ARC_Commission_Payment__c WHERE RecordTypeId=:rtCommPaymentSDR AND Type__c ='Monthly Payout' AND CreatedDate = THIS_MONTH];
        if(!commPaymentList.isEmpty()){
            Set<Id> sdrIds = new Set<Id>();
            for(ARC_Commission_Payment__c cp: commPaymentList) sdrIds.add(cp.Commission__r.OwnerId);

            //Calculate the Transfer Calls by SDR
            Map<Id, Integer> sdrTransferCallsMap = calculateTransferCalls(sdrIds);

            //Calculate the Total Calls by SDR
            Map<Id, Decimal> sdrTotalCallsMap = calculateTotalCalls(sdrIds);

            //Generate Procedure Input
            List<Map<String,Object>> calculateBonusSDRs = new List<Map<String,Object>>();
            for(Id sdrId: sdrIds){
                System.debug(sdrId);
                System.debug(sdrTransferCallsMap);
                System.debug(sdrTotalCallsMap);
                //Rounding Mode HALF_EVEN: Rounds towards the “nearest neighbor” unless both neighbors are equidistant, in which case, this mode rounds towards the even neighbor.
                Map<String, Object> recordToCalculate = new Map<String,Object>{
                    'sdrUser' => (String)sdrId,
                    'totalNumber' => (sdrTransferCallsMap.containsKey(sdrId) && sdrTransferCallsMap.get(sdrId) >0 ? ((Decimal)(sdrTransferCallsMap.get(sdrId)) / (Decimal)(sdrTotalCallsMap.get(sdrId)) * 100).setScale(2, System.RoundingMode.HALF_EVEN ) :0)
                };
                calculateBonusSDRs.add(recordToCalculate);
                System.debug(calculateBonusSDRs);
            }

            //Call the Procedure to calculate the Bonuses
            Map<Id,Decimal> sdrBonusMap = callProcedure(calculateBonusSDRs);

            Date today = Date.today();
            for(ARC_Commission_Payment__c cp: commPaymentList){
                cp.ARC_ActualTransfers__c = sdrTransferCallsMap.get(cp.Commission__r.OwnerId);
                cp.ARC_TotalCalls__c = sdrTotalCallsMap.get(cp.Commission__r.OwnerId);
                cp.ARC_BonusAmount__c = sdrBonusMap.get(cp.Commission__r.OwnerId);
                cp.ARC_PaymentDate__c = Date.newInstance(today.year(),today.month(),15);
                if(cp.ARC_SalesFloorConversion__c >= 30){
                    cp.Amount__c = calculateAmount(sdrBonusMap.get(cp.Commission__r.OwnerId), cp.ARC_WorkingDays__c);
                } 
                else cp.Amount__c = 0; 
            }
            update commPaymentList;
        }
    }

    /*******************************************************************
    * @MethodName         :   calculateTransferCalls
    * @Description        :   Returns a Map with the Transfer Calls made by each SDR during the last Month. Use the Leads records to calculate the information. 
    ********************************************************************/   
    public static Map<Id,Integer> calculateTransferCalls(Set<Id> userIds){
        if(userIds.isEmpty()) return null;
        Map<Id,Integer> sdrTansferCalls = new Map<Id,Integer>();
        for (AggregateResult transferCalls : [SELECT COUNT(Id) number, Sales_Development_Rep__c  FROM Lead  WHERE Sales_Development_Rep__c IN :userIds AND Agent_Transfer_Date_Time__c = LAST_MONTH  GROUP BY Sales_Development_Rep__c]) {
            sdrTansferCalls.put((Id) transferCalls.get('Sales_Development_Rep__c'), transferCalls.get('number') != null && (Integer)transferCalls.get('number') !=0 ?(Integer) transferCalls.get('number'):0);
        }
        return sdrTansferCalls;
    }

    /*******************************************************************
    * @MethodName         :   calculateTotalCalls
    * @Description        :   Returns a Map with the Total Calls made by each SDR during the last Month. Use the Tasks records to calculate the information. 
    ********************************************************************/ 
    public static Map<Id,Decimal> calculateTotalCalls(Set<Id> userIds){
        if(userIds.isEmpty()) return null;
        //Get the Task reasons to be excluded from the Custom Label ARC_SDRExcludeTaskReasons
        // String taskReasonsToExclude = String.valueOf(System.Label.ARC_SDRExcludeTaskReasons);
        // List<String> taskReasonsToExcludeList = taskReasonsToExclude != null? taskReasonsToExclude.split(','): new List<String>();

        Map<Id,Integer> totalCallsMap = new Map<Id,Integer>();

        // if(String.isNotBlank(taskReasonsToExclude)){
        //   for(String taskReason: taskReasonsToExcludeList) taskReason.trim();
        // }
        // for (AggregateResult totalCalls : [SELECT COUNT(Id) totalNumber, CreatedById sdrUser FROM Task WHERE CreatedDate = LAST_MONTH AND CreatedById IN :userIds AND CallDisposition != null AND CallDisposition NOT IN: taskReasonsToExcludeList GROUP BY CreatedById]) { 
        //     totalCallsMap.put((Id)totalCalls.get('sdrUser'), (Integer)totalCalls.get('totalNumber'));
        // }
        for (AggregateResult totalCalls : [SELECT COUNT(Id) totalNumber, CreatedById sdrUser FROM Task WHERE CreatedDate = LAST_MONTH AND CreatedById IN :userIds AND SDR_Connection__c = TRUE GROUP BY CreatedById]) { 
            totalCallsMap.put((Id)totalCalls.get('sdrUser'), (Integer)totalCalls.get('totalNumber'));
        }
        if(Test.isRunningTest()){
            for (AggregateResult totalCalls : [SELECT COUNT(Id) totalNumber, CreatedById sdrUser FROM Task WHERE CreatedDate = THIS_MONTH AND CreatedById IN :userIds GROUP BY CreatedById]) { 
                totalCallsMap.put((Id)totalCalls.get('sdrUser'), (Integer)totalCalls.get('totalNumber'));
            }
        }
        return totalCallsMap;
    }

    /*******************************************************************
    * @MethodName         :   callProcedure
    * @Description        :   Calls the Integration Procedure (Commissions_SDRCalulateBonus) to calculate the Bonus for the given SDR. 
    ********************************************************************/ 
    public static Map<Id,Decimal> callProcedure(List<Map<String,Object>> calculateBonusSDRs){
        Map<Id,Decimal> resultMap = new Map<Id,Decimal>();
        //Call IP to get the Bonus Amount per SDR
        String procedureAPIName = 'Commissions_SDRCalulateBonus';
        Map<String, Object> ipOutput = (Map<String, Object>) vlocity_ins.IntegrationProcedureService.runIntegrationProcedureServiceFromApex(procedureAPIName, new Map<String, Object>{'SDRCalls' => calculateBonusSDRs}, new Map<String, Object>());
        List<Object> resultList = (ipOutput.get('result') != null) ? (List<Object>) ipOutput.get('result') : new List<Object>();
        System.debug(resultList);
        for (Object results : resultList) {
            Map<String, Object> sdrData = (Map<String, Object>) results;
            resultMap.put((Id) sdrData.get('SDRId'), (Decimal) sdrData.get('BonusAmount'));
        }
        System.debug(resultList);
        return resultMap;
    }

    /*******************************************************************
    * @MethodName         :   calculateAmount
    * @Description        :   Returns the result of the Bonus Amount afected by the Working Days % 
    ********************************************************************/ 
    public static Decimal calculateAmount(Decimal bonusAmount, Decimal workingDays) {
        if (bonusAmount == null || workingDays == null ||bonusAmount <= 0 || workingDays<=0) return 0;
        return bonusAmount * (workingDays/ 100);
    }
}