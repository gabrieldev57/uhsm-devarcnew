global class HDEmailBatchclass implements Database.Batchable<sObject>,Schedulable {
    
    //public static List<Object> memberIds = new List<Object>();
    
    //Add Schedulable method
    global void execute(SchedulableContext ctx) {
        HDEmailBatchclass HDEmail = new HDEmailBatchclass();
        Database.executeBatch(HDEmail);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute      
        return Database.getQueryLocator([
            SELECT Id, ARC_EndDate__c, ARC_Contract__c,ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.FirstName, ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.PersonEmail 
            FROM ARC_PromotionDiscount__c  
            WHERE RecordType.DeveloperName = 'Healthy_Discount' 
                AND ARC_Status__c = 'Activated' 
                AND ARC_ContractStatus__c = 'Activated' 
                AND ARC_EndDate__c != Null
                AND ARC_EndDate__c = NEXT_90_DAYS
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<ARC_PromotionDiscount__c> records){

        Date today = Date.today();
        Map<String,ARC_PromotionDiscount__c> sendHealthyDiscountEmailList = new Map<String,ARC_PromotionDiscount__c>();
        Set<Id> contractIds = new Set<Id>();

        for (ARC_PromotionDiscount__c discount : records) {
            if (discount.ARC_Contract__c != null) contractIds.add(discount.ARC_Contract__c);
        }

        Set<Id> contractsWithAwaitingHealthy = new Set<Id>();
        if (!contractIds.isEmpty()) {
            for (ARC_PromotionDiscount__c hd : [
                SELECT Id, ARC_Contract__c
                FROM ARC_PromotionDiscount__c 
                WHERE RecordType.DeveloperName = 'Healthy_Discount'
                    AND ARC_Status__c = 'Awaiting Activation'
                    AND ARC_Contract__c IN :contractIds
            ]) {
                contractsWithAwaitingHealthy.add(hd.ARC_Contract__c);
            }
        }
        System.debug('contractsWithAwaitingHealthy ' + contractsWithAwaitingHealthy);
        
        for (ARC_PromotionDiscount__c discount : records) {

            String daysUntilEndDate = String.valueOf(today.daysBetween(discount.ARC_EndDate__c));

            System.debug('Contains contract with awaiting HD? ' + contractsWithAwaitingHealthy.contains(discount.ARC_Contract__c));

            if ((daysUntilEndDate == '90' || daysUntilEndDate == '30') && !contractsWithAwaitingHealthy.contains(discount.ARC_Contract__c)) {
                sendHealthyDiscountEmailList.put(discount.Id, discount);
            }
        
        }

        system.debug('sendHealthyDiscountEmailList ' + sendHealthyDiscountEmailList);

        if (!sendHealthyDiscountEmailList.isEmpty()) {
			try {
				ARC_Emails.email_23(sendHealthyDiscountEmailList, new Map<String,Object>(), new Map<String,Object>());
			} catch (Exception e) {
                String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
                ARC_QueableSendFileBatch.sendEmailNotification(('Error in HDEmailBatchclass: '+e.getMessage() + '  -------------  ' + sendHealthyDiscountEmailList), 'Error in HDEmailBatchclas', apexErrorEmail);

			}
        }
    }
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
}