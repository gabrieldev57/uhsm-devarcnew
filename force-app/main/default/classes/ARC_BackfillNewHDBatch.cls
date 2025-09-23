global without sharing class ARC_BackfillNewHDBatch implements Database.Batchable<sObject> {

    public Set<Id> healthyDiscountIds = new Set<Id>();
    Integer retries = 0;

    global ARC_BackfillNewHDBatch (Set<Id> healthyDiscountIds){
        System.debug('EXECUTE BATCH FOR SPECIFIC HD');
        this.healthyDiscountIds = healthyDiscountIds;
    }

    global ARC_BackfillNewHDBatch(){}

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (this.healthyDiscountIds.size() > 0) {
            return  Database.getQueryLocator([SELECT Id, Name, Contract__c, PrimaryEffectivedate__c, Healthy_Status__c, Is_Active__c, PrimaryStatus__c, Contract__r.Status,
            SpouseStatus__c, PrimaryDecisionDate__c, SpouseDecisionDate__c FROM Healthy_Discount__c WHERE (Healthy_Status__c = 'Approved' OR Healthy_Status__c = 'Pending') AND Contract__c != null AND Id IN:healthyDiscountIds]);
        } 
        else return Database.getQueryLocator([SELECT Id, Name, Contract__c, PrimaryEffectivedate__c, Healthy_Status__c, Is_Active__c, PrimaryStatus__c, Contract__r.Status,
        SpouseStatus__c, PrimaryDecisionDate__c, SpouseDecisionDate__c FROM Healthy_Discount__c WHERE (Healthy_Status__c = 'Approved' OR Healthy_Status__c = 'Pending') AND Contract__c != null]);
    }

    global void execute(Database.BatchableContext bc, List<Healthy_Discount__c> records){
        //Healthy Discount Promo Code
        List<ARC_PromotionCode__c> healthyDiscount = [SELECT Id, Name FROM ARC_PromotionCode__c WHERE Name = 'Healthy Discount' AND ARC_Active__c = true];
        //Query to get the Health Discount Record Type
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Healthy_Discount' AND SObjectType = 'ARC_PromotionDiscount__c' LIMIT 1]?.Id;
        Set<Id> contractIdWithHD = new Set<Id>();
        Set<Id> healthyDiscountIds = new Set<Id>();
        try{
            List<ARC_PromotionDiscount__c> discountsToUpdate = new List<ARC_PromotionDiscount__c>();
            for(Healthy_Discount__c record: records) {
                //Promotion Discount new object
                healthyDiscountIds.add(record.Id);
                ARC_PromotionDiscount__c discountInfo = new ARC_PromotionDiscount__c();
                Date today = Date.today();
                Date startDate = record.PrimaryEffectivedate__c;
                Date endDate = record.PrimaryEffectivedate__c?.addYears(1);
                System.debug('startDate '+ startDate);
                System.debug('endDate '+endDate);
                String statusHD = record.Healthy_Status__c;
                String statusDiscount;
                if(record.Healthy_Status__c == 'Pending'){
                    statusDiscount = 'Pending';
                } 
                else if (record.Contract__r.Status == 'Awaiting Activation' && record.Is_Active__c == false && startDate > today && endDate > today && statusHD == 'Approved'){
                    statusDiscount = 'Awaiting Activation';
                }
                else if(record.Contract__r.Status == 'Activated' && record.Is_Active__c == true && endDate > today && statusHD == 'Approved'){
                    System.debug('insideActivated');
                    statusDiscount = 'Activated';
                } 
                else if(record.Contract__r.Status == 'Terminated' || (endDate < today && statusHD == 'Approved')){
                    System.debug('insideTerminated');
                    statusDiscount = 'Terminated';
                }
                else {
                    statusDiscount = 'Voided';
                }
                discountInfo.RecordTypeId = recordTypeId;
                discountInfo.Name = 'Healthy Discount';
                discountInfo.ARC_StartDate__c = startDate;
                discountInfo.ARC_EndDate__c = endDate;
                discountInfo.ARC_Status__c = statusDiscount;
                discountInfo.ARC_Contract__c = record.Contract__c;
                discountInfo.ARC_PromoCode__c = healthyDiscount[0].Id;
                discountsToUpdate.add(discountInfo);
                contractIdWithHD.add(record.Contract__c);        
            }
            insert discountsToUpdate;

            if(discountsToUpdate != null && !discountsToUpdate.isEmpty()){
                List<Contract> recordsContract = [SELECT Id, ContractNumber, 
                (SELECT Id, Name, Contract__c, PrimaryEffectivedate__c, Healthy_Status__c, Is_Active__c, PrimaryStatus__c, SpouseStatus__c, PrimaryDecisionDate__c, SpouseDecisionDate__c FROM Healthy_Discounts__r WHERE Healthy_Status__c = 'Approved' OR Healthy_Status__c = 'Pending'),
                (SELECT Id, ARC_StartDate__c  FROM Promotions__r WHERE Id IN :discountsToUpdate),
                (SELECT Id, Name, ARC_PersonAccount__c, ARC_Contract__c, ARC_PersonAccount__r.ARC_IsPrimaryMember__c, ARC_PersonAccount__r.Name, ARC_PersonAccount__r.ARC_DependentRelationship__c FROM Contract_Participants__r WHERE ARC_PersonAccount__r.ARC_DependentRelationship__c = 'Spouse' OR ARC_PersonAccount__r.ARC_IsPrimaryMember__c = true)
                FROM Contract WHERE Status != 'Draft' AND Id IN: contractIdWithHD];
                
                List<ARC_HealthyDiscountAccount__c> healthyDiscountAccountPM = new List<ARC_HealthyDiscountAccount__c>();
                
                if(recordsContract!= null && !recordsContract.isEmpty()){
                    /**CREATE HEALTHY DISCOUNT ACCOUNT**/
                    for(Contract cont: recordsContract) {
                        for(Healthy_Discount__c oldHD: cont.Healthy_Discounts__r){
                            String primaryStatusDiscount = oldHD.PrimaryStatus__c;
                            String hdPrimaryStatus;
                        
                            String spouseStatusDiscount = oldHD.SpouseStatus__c;
                            String hdSpouseStatus;
                        
                            if(primaryStatusDiscount != null){
                                if(primaryStatusDiscount == 'Pending'){
                                    hdPrimaryStatus = 'Pending';
                                }
                                else if(primaryStatusDiscount == 'True'){
                                    hdPrimaryStatus = 'Approved';
                                }
                                else if(primaryStatusDiscount == 'False'){
                                    hdPrimaryStatus = 'Denied';
                                }
                            }
                    
                            if(spouseStatusDiscount != null){
                                if(spouseStatusDiscount == 'Pending'){
                                    hdSpouseStatus = 'Pending';
                                }
                                else if(spouseStatusDiscount == 'True'){
                                    hdSpouseStatus = 'Approved';
                                }
                                else if(spouseStatusDiscount == 'False'){
                                    hdSpouseStatus = 'Denied';
                                }
                            }
                            //Looping Promotions
                            for (ARC_PromotionDiscount__c discount : cont.Promotions__r) {
                                if(discount.ARC_StartDate__c != oldHD.PrimaryEffectivedate__c){
                                    continue;
                                }
                                Boolean primaryFound = false;
                                Boolean spouseFound = false;
                                //Looping Contract Participants
                                for(ARC_ContractParticipant__c contPart: cont.Contract_Participants__r){
                                    if(primaryStatusDiscount != null || spouseStatusDiscount != null){
                                        if((contPart.ARC_PersonAccount__r.ARC_IsPrimaryMember__c == true && !primaryFound) || (contPart.ARC_PersonAccount__r.ARC_DependentRelationship__c == 'Spouse' && !spouseFound)){
                                            ARC_HealthyDiscountAccount__c hdAccountPrimaryMember = new ARC_HealthyDiscountAccount__c();                   
                                            hdAccountPrimaryMember.Name = contPart.ARC_PersonAccount__r?.Name + ' HD';
                                            hdAccountPrimaryMember.ARC_Account__c = contPart.ARC_PersonAccount__c;
                                            hdAccountPrimaryMember.ARC_Discount__c = discount.Id;
                                            if(contPart.ARC_PersonAccount__r.ARC_IsPrimaryMember__c == true){
                                                hdAccountPrimaryMember.ARC_Status__c = hdPrimaryStatus;
                                                hdAccountPrimaryMember.ARC_DecisionDate__c = oldHD.PrimaryDecisionDate__c;
                                                primaryFound=true;
                                            }
                                            else if(contPart.ARC_PersonAccount__r.ARC_DependentRelationship__c == 'Spouse'){
                                                hdAccountPrimaryMember.ARC_Status__c = hdSpouseStatus;
                                                hdAccountPrimaryMember.ARC_DecisionDate__c = oldHD.SpouseDecisionDate__c;
                                                spouseFound=true;
                                            }
                                            healthyDiscountAccountPM.add(hdAccountPrimaryMember);
                                        }
                                    }               
                                }
                            }
                        }
                    }
                    insert healthyDiscountAccountPM;
                }
            }
        }catch(Exception e){
            if(e.getMessage().contains('UNABLE_TO_LOCK_ROW')){
                this.retries++;
                System.debug('Unable to lock row error');
                if(retries< 3){
                    System.debug('Retry this execution');
                    //Retry the Execution of the Batch: 
                    Database.executeBatch(new ARC_BackfillNewHDBatch(healthyDiscountIds),100);
                }
            }
        }
    }
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
}