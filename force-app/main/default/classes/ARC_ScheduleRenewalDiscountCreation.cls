/*******************************************************************
* @ClassName          :   ARC_ScheduleRenewalDiscountCreation
* @Description        :   Logic of a daily job that get all the applicable contracts for Renewals, create the Renewal Discounts, deactivate the previous if exist
                          and sends a notification to the primary member.
* @MethodName         :   getRenewalDiscountCodes, getContractsApplicableForRenewalDiscounts, createRenewalDiscounts
********************************************************************/
public without sharing class ARC_ScheduleRenewalDiscountCreation implements Schedulable {
    //HOW TO EXECUTE THIS JOB FOR A SPECIFIC RENEWAL DATE
    // ARC_ScheduleRenewalDiscountCreation renewalDisc = new ARC_ScheduleRenewalDiscountCreation();
    // renewalDisc.hardCodedDate = Date.newInstance(2025,01,01);
    // renewalDisc.execute(null);   

    private  List<ARC_PromotionCode__c> renewalDiscountCodes = [SELECT Id, name,ARC_DiscountRate__c,ARC_RenewalDiscountNumber__c FROM ARC_PromotionCode__c WHERE RecordType.Name = 'Renewal Discount' AND ARC_Active__c = TRUE ORDER BY ARC_RenewalDiscountNumber__c ASC];
    private ARC_PromotionCode__c lastRenewalDiscount = new ARC_PromotionCode__c();
    public Date hardCodedDate;
     
    public void execute(SchedulableContext SC) {
        Map<Integer,List<Contract>> renewalNumberContractsMap = new Map<Integer,List<Contract>>();
        //Get all the Renewal Discounts Codes
        Map<Integer,ARC_PromotionCode__c> renewalDiscountCodesMap = getRenewalDiscountCodes(renewalDiscountCodes);
        //Validates that no more than 50 querys areg going to be executed to not exeed the Governor Limits
        if(renewalDiscountCodesMap.size() <= 50){
            //Get all the Contracts applicable for Renewal Discounts
            for(Integer renewalNumber: renewalDiscountCodesMap.keySet()){
                List<Contract> contractsToCreateRD = getContractsApplicableForRenewalDiscounts(renewalNumber);
                if(contractsToCreateRD != null && contractsToCreateRD.size()>0){
                    renewalNumberContractsMap.put(renewalNumber,contractsToCreateRD);
                }
            }
            //Create the Renewal Discounts and deactivate the previous one if exist
            if(renewalNumberContractsMap != null && !renewalNumberContractsMap.isEmpty()){
                createRenewalDiscounts(renewalNumberContractsMap,renewalDiscountCodesMap);
            }
        }
    }
    /*******************************************************************
    * @MethodName         :   getRenewalDiscountCodes
    * @Description        :   Build a Map of Renewal Number and Renewal Discount Code
    ********************************************************************/    
    public Map<Integer,ARC_PromotionCode__c> getRenewalDiscountCodes(List<ARC_PromotionCode__c> renewalCodes){
        if(renewalCodes.isEmpty()) return null;
        Map<Integer,ARC_PromotionCode__c> renewalMaps = new Map<Integer,ARC_PromotionCode__c>();
        for(ARC_PromotionCode__c rc: renewalCodes){
            renewalMaps.put(Integer.valueOf(rc.ARC_RenewalDiscountNumber__c),rc);
            this.lastRenewalDiscount=rc;
        }
        return renewalMaps;
    }
    /*******************************************************************
    * @MethodName         :   getContractsApplicableForRenewalDiscounts
    * @Description        :   Get all the Contracts applicable for any of the Renewal Discounts
    ********************************************************************/ 
    public List<Contract> getContractsApplicableForRenewalDiscounts(Integer renewalNumber){
        System.debug('Renewal number '+ renewalNumber);
        Date nYearsAgoDate = Date.Today().addYears(-renewalNumber); 
        if(this.hardCodedDate != null) nYearsAgoDate = this.hardCodedDate.addYears(-renewalNumber);
        Date oneYearBeforeNYearsAgoDate = nYearsAgoDate.addYears(-1);
        List<Contract> contractList;


        Id rtRenewalDiscount = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Renewal_Discount').getRecordTypeId();
        List<ARC_PromotionDiscount__c> excludedActiveRenewals = [SELECT Id, ARC_Contract__c FROM ARC_PromotionDiscount__c WHERE RecordTypeId = :rtRenewalDiscount AND ARC_RenewalDiscountNumber__c = :renewalNumber AND (ARC_Status__c = 'Activated' OR ARC_Status__c = 'Awaiting Activation')];
        Set<Id> excludedContractIds = new Set<Id>();
        for (ARC_PromotionDiscount__c discount : excludedActiveRenewals) {
            if (discount.ARC_Contract__c != null) {
                excludedContractIds.add(discount.ARC_Contract__c);
            }
        }


        if(renewalNumber == this.lastRenewalDiscount?.ARC_RenewalDiscountNumber__c){
            contractList = [SELECT  Id,
                                    vlocity_ins__EnrollmentCensusId__r.ARC_MinContinuousMembershipStartDate__c
                            FROM Contract 
                            WHERE   Id NOT IN :excludedContractIds
                                    AND vlocity_ins__EnrollmentCensusId__r.ARC_MinContinuousMembershipStartDate__c <= :nYearsAgoDate 
                                    AND Status = 'Activated'
                                    AND ARC_PaidThroughDate__c >= TODAY
                            ];
        }
        else{
            contractList = [SELECT  Id ,
                                    vlocity_ins__EnrollmentCensusId__r.ARC_MinContinuousMembershipStartDate__c
                            FROM Contract 
                            WHERE   Id NOT IN :excludedContractIds
                                    AND vlocity_ins__EnrollmentCensusId__r.ARC_MinContinuousMembershipStartDate__c <= :nYearsAgoDate
                                    AND vlocity_ins__EnrollmentCensusId__r.ARC_MinContinuousMembershipStartDate__c > :oneYearBeforeNYearsAgoDate
                                    AND Status = 'Activated'
                                    AND ARC_PaidThroughDate__c >= TODAY
                            ];
        }
        System.debug('contractList ' + contractList);
        if (contractList != null && contractList.size()>0){
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('excludedContractIds '+ excludedContractIds + ' - contractList '+ contractList), 'excludedContractIds -- ScheduleRenewalDiscountCreation RENEWAL NUMBER ' + renewalNumber, apexErrorEmail);
        }
        return contractList;
    }
    /*******************************************************************
    * @MethodName         :   createRenewalDiscounts
    * @Description        :   Creates the Renewal Discounts for all the Contracts in renewalContractsMap. 
                              Deactivate the previous Renewal Discount if exist.
                              Also send the Email to the Primary Member of the contract
    ********************************************************************/ 
    public void createRenewalDiscounts(Map<Integer,List<Contract>> renewalContractsMap, Map<Integer,ARC_PromotionCode__c> renewalCodesMap){
        if(renewalContractsMap != null && !renewalContractsMap.isEmpty() ){
            Id rtRenewalDiscount = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Renewal_Discount').getRecordTypeId();
            List<ARC_PromotionDiscount__c> renewalDiscountsToCreate = new List<ARC_PromotionDiscount__c>();
            List<ARC_PromotionDiscount__c> renewalDiscountsToDeactivate = new List<ARC_PromotionDiscount__c>();
            
            Map<Id,ARC_PromotionDiscount__c> contractRenewalToDeactivate = new Map<Id,ARC_PromotionDiscount__c>();
            Set<Id> newRenewalIds = new Set<Id>();
            
            for(Integer renewalNumber: renewalContractsMap.keySet()){
                ARC_PromotionCode__c renewalCode = renewalCodesMap.get(renewalNumber);
                List<Contract> contractsApplicableForRenewals = renewalContractsMap.get(renewalNumber);
                for(Contract con: contractsApplicableForRenewals){
                    ARC_PromotionDiscount__c renDiscount = new ARC_PromotionDiscount__c(
                        ARC_Contract__c = con.Id,
                        ARC_PromoCode__c = renewalCode.Id,
                        ARC_Status__c = 'Awaiting Activation',
                        RecordTypeId = rtRenewalDiscount,
                        ARC_StartDate__c = Date.Today()
                    );
                    if(this.hardCodedDate != null) renDiscount.ARC_StartDate__c = this.hardCodedDate;
                    renewalDiscountsToCreate.add(renDiscount);
                }
            }
            try{
                ARC_CreateDiscountsBatch batch = new ARC_CreateDiscountsBatch(renewalDiscountsToCreate);
                Database.executeBatch(batch, 200); // 200 is the batch size
            }catch(Exception e){
                String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
                ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_ScehduleRenewalDiscountCreation: '+e.getMessage()), 'ERROR ScheduleRenewalDiscountCreation', apexErrorEmail);
            }
        }
    }
}