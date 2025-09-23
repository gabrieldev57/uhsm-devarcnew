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
            SELECT Id, ARC_EndDate__c, ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.FirstName, ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.PersonEmail 
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
        
        for (ARC_PromotionDiscount__c discount : records) {

            String daysUntilEndDate = String.valueOf(today.daysBetween(discount.ARC_EndDate__c));

            if (daysUntilEndDate == '90' || daysUntilEndDate == '30') {
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