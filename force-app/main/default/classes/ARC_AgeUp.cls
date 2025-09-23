public with sharing class ARC_AgeUp implements Database.Batchable<sObject>, Database.Stateful {
    private Integer DAYS_AMOUNT = 60;
    public List<Ages_Up__c> ageUpsToCalculate = new List<Ages_Up__c>();
    public Boolean applyOnPlans = false;


    public static void applyAgeUp(List<Ages_Up__c> ageUps){        
        // Recalculate prices
        ageUps = [SELECT Id, Name, ARC_EffectiveDate__c, ARC_ManualDelay__c, Contract__r.ARC_EffectiveDate__c, Contract__c, ARC_Account__c  FROM Ages_Up__c WHERE Id IN :ageUps];
        ARC_AgeUp ageUpBatch = new ARC_AgeUp();
        ageUpBatch.applyOnPlans = true;
        ageUpBatch.ageUpsToCalculate.addAll(ageUps);
        Database.executeBatch(ageUpBatch, 1);
    }

    public static void calculateAgeUp(Set<Id> contractIds){
        List<Ages_Up__c> ageUps = [SELECT Id, Name, ARC_EffectiveDate__c, ARC_ManualDelay__c, Contract__r.ARC_EffectiveDate__c, Contract__c, ARC_Account__c  FROM Ages_Up__c WHERE Contract__c IN :contractIds];
        if (ageUps.isEmpty()) {
            return;
        }
        ARC_AgeUp ageUpBatch = new ARC_AgeUp();
        ageUpBatch.applyOnPlans = false;
        ageUpBatch.ageUpsToCalculate.addAll(ageUps);
        Database.executeBatch(ageUpBatch, 1);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        List<Integer> ageGaps = getAgeGaps();
        List<Integer> agePreviousGaps = getAgePreviousGaps();

        
        //Run for accounts without Age Up
        if(this.ageUpsToCalculate.isEmpty()){
            //Get Existing Ageups
            List<Ages_Up__c> existingsAgeUps = [SELECT ARC_Account__c, Contract__c FROM Ages_Up__c WHERE ARC_Applied__c = false AND (ARC_ManualDelay__c != null OR (ARC_ManualDelay__c = null AND ARC_EffectiveDate__c = NEXT_N_DAYS:60))];
    
            Set<Id> existingsAgeUpsAccountsIds = new Set<Id>();
    
            for (Ages_Up__c ageUp : existingsAgeUps) {
                existingsAgeUpsAccountsIds.add(ageUp.ARC_Account__c);
            }
            return Database.getQueryLocator([SELECT Id, FirstName, PersonBirthdate, ARC_IsPrimaryMember__c, ARC_Census__r.ARC_PrimaryAccount__r.FirstName, ARC_Census__r.ARC_PrimaryAccount__r.PersonEmail, (SELECT Id, ARC_PriceBeforeAgeUp__c, ARC_PriceAfterAgeUp__c, ARC_EffectiveDate__c, ARC_ManualDelay__c,Contract__c, Name, Contract__r.ARC_EffectiveDate__c, ARC_Account__c, ARC_ReviewAgeUpPrice__c FROM Age_Up__r WHERE ARC_Applied__c = false AND Contract__r.Status = 'Activated') 
                                            FROM Account 
                                            WHERE (Census_Member__r.ARC_Age__c IN :agePreviousGaps AND Census_Member__r.Age_In_Sixty_Days__c IN :ageGaps AND Census_Member__r.Is_Oldest_Member__c = true) OR Id IN :existingsAgeUpsAccountsIds]);
        }//Run for existing Age ups that needs to be recalculated
        else{
            Set<Id> accountIds = new Set<Id>();
            for (Ages_Up__c ageUp : this.ageUpsToCalculate) {
                accountIds.add(ageUp.ARC_Account__c);
            }
            return Database.getQueryLocator([
                SELECT Id, FirstName, PersonBirthdate, ARC_IsPrimaryMember__c, ARC_Census__r.ARC_PrimaryAccount__r.FirstName, ARC_Census__r.ARC_PrimaryAccount__r.PersonEmail, 
                    (SELECT Id, ARC_PriceBeforeAgeUp__c, ARC_PriceAfterAgeUp__c, ARC_EffectiveDate__c, ARC_ManualDelay__c,Contract__c, Name, Contract__r.ARC_EffectiveDate__c, ARC_Account__c, ARC_ReviewAgeUpPrice__c 
                    FROM Age_Up__r WHERE Id IN :this.ageUpsToCalculate) 
                FROM Account WHERE Id IN :accountIds]);
        }
    }

    public void execute(Database.BatchableContext BC, List<Account> accounts) {

        List<Ages_Up__c> ageUpsToUpsert = new List<Ages_Up__c>();

        if(this.ageUpsToCalculate.isEmpty()){
            Date today = Date.today();
            Set<Id> accountIds = new Set<Id>();
            Map<String,Account> sendAgeUpEmailList = new Map<String,Account>();
            for(Account account : accounts) {
                if(account.Age_Up__r.size() == 0) {
                    accountIds.add(account.Id);
                } else if (account.Age_Up__r.size() == 1) {
                    Date effectiveDate = account.Age_Up__r[0].ARC_ManualDelay__c != null ? account.Age_Up__r[0].ARC_ManualDelay__c : account.Age_Up__r[0].ARC_EffectiveDate__c;          
                    String daysUntilEffectiveDate = String.valueOf(today.daysBetween(effectiveDate));
                    if((daysUntilEffectiveDate == '60' || daysUntilEffectiveDate == '30' || daysUntilEffectiveDate == '14') && !account.Age_Up__r[0].ARC_ReviewAgeUpPrice__c){
                        sendAgeUpEmailList.put(account.Id, account);
                    }
                }
            }
    
            //Send Age Up Email if Age Up is not applied and days until age up effective date is 60, 30 or 14
            if (!sendAgeUpEmailList.isEmpty()) {
                ARC_Emails.email_22(sendAgeUpEmailList, new Map<String,Object>(), new Map<String,Object>());
            }
    
            List<ARC_ContractParticipant__c> participants = [
                SELECT Id, ARC_Contract__c, ARC_Contract__r.ARC_EffectiveDate__c,ARC_Contract__r.ARC_PolicyEffectiveDate__c,ARC_Contract__r.ARC_ContractReason__c, ARC_PersonAccount__c,ARC_PersonAccount__r.Name,ARC_PersonAccount__r.PersonBirthdate, ARC_PersonAccount__r.vlocity_ins__Age__pc,ARC_Contract__r.ARC_MedicalPlan__r.Name  
                FROM ARC_ContractParticipant__c 
                WHERE ARC_PersonAccount__c IN :accountIds AND ARC_Contract__r.Status = 'Activated'];
                
            Set<Id> contractIds = new Set<Id>();

            for (ARC_ContractParticipant__c participant : participants) {
                //Only AgeUp Members 64 with Legacy Program
                if(participant.ARC_PersonAccount__r.vlocity_ins__Age__pc >= 64){
                    if(participant.ARC_Contract__r.ARC_MedicalPlan__r.Name.contains('Legacy')){
                        contractIds.add(participant.ARC_Contract__c);
                    }
                }
                else{
                    contractIds.add(participant.ARC_Contract__c);
                }
            }

            List<vlocity_ins__ContractLineItem__c> weSharePlans = getWeSharePlans(contractIds);
            Set<Id> weShareContractIds = new Set<Id>();
            for (vlocity_ins__ContractLineItem__c plan : weSharePlans) {
                weShareContractIds.add(plan.vlocity_ins__ContractId__c);
            }

            for(ARC_ContractParticipant__c participant : participants) {

                if(!weShareContractIds.contains(participant.ARC_Contract__c)){
                    continue;
                }

                Date birthdate = participant.ARC_PersonAccount__r.PersonBirthdate;
                Integer age = participant.ARC_PersonAccount__r.vlocity_ins__Age__pc.intValue();
                Date nextBirthday = birthdate.addYears(age) < Date.today() ? birthdate.addYears(age + 1) : birthdate.addYears(age);
                Date ageUpEffectiveDate = nextBirthday.addMonths(1).toStartOfMonth();
                Date contractEffectiveDate = participant.ARC_Contract__r.ARC_EffectiveDate__c;
                if(participant.ARC_Contract__r.ARC_ContractReason__c == 'Add Newborn' && participant.ARC_Contract__r.ARC_PolicyEffectiveDate__c != null){
                    contractEffectiveDate = participant.ARC_Contract__r.ARC_PolicyEffectiveDate__c;
                }
                                
                // If the age up effective date is within the next 60 days of the contract effective date, skip the age up
                if(contractEffectiveDate < nextBirthday && nextBirthday < contractEffectiveDate.addDays(DAYS_AMOUNT)){
                    continue;
                }

                Ages_Up__c ageUp = new Ages_Up__c(
                    Name = participant.ARC_PersonAccount__r.Name + ' - Age Up',
                    Contract__c = participant.ARC_Contract__c,
                    ARC_Account__c = participant.ARC_PersonAccount__c,
                    ARC_EffectiveDate__c = ageUpEffectiveDate
                );
                ageUp.Contract__r = new Contract(
                    Id = participant.ARC_Contract__c, 
                    ARC_EffectiveDate__c = participant.ARC_Contract__r.ARC_EffectiveDate__c
                );
    
                ageUpsToUpsert.add(ageUp);
            }
            insert ageUpsToUpsert;
        }else{
            for (Account account : accounts) {
                ageUpsToUpsert.addAll(account.Age_Up__r);
            }
        }
        ARC_AgeUpPriceCalculationQueable ageUpPriceCalculationQueable = new ARC_AgeUpPriceCalculationQueable(ageUpsToUpsert);
        ageUpPriceCalculationQueable.applyOnPlans = this.applyOnPlans;
        System.enqueueJob(ageUpPriceCalculationQueable);
        
    }

    public void finish(Database.BatchableContext BC) {

    }

    private static List<Integer> getAgeGaps(){
        List<String> ageBrackets = System.Label.ARC_AgeBracket.trim().split(',');
        List<Integer> ageBracketList = new List<Integer>();
        for(String age:ageBrackets) ageBracketList.add(Integer.valueOf(age));
        return ageBracketList;
    }

    private static List<Integer> getAgePreviousGaps(){
        List<Integer> ageGaps = getAgeGaps();
        List<Integer> agePreviousGaps = new List<Integer>();
        for (Integer age : ageGaps) {
            agePreviousGaps.add(age - 1);
        }
        return agePreviousGaps;
    }

    public static List<vlocity_ins__ContractLineItem__c> getPlans(Set<Id> contractIds){
        return [
            SELECT Id, 
                vlocity_ins__UnitPrice__c, 
                ARC_OriginalPrice__c,
                ARC_SmokerFee__c, 
                ARC_ExtraDependentFee__c,
                vlocity_ins__ContractId__c,
                vlocity_ins__ProductType__c,
                vlocity_ins__Product2Id__c,
                (
                    SELECT Id, 
                        vlocity_ins__GroupCensusMemberId__r.vlocity_ins__AccountId__c, 
                        vlocity_ins__GroupCensusMemberId__r.ARC_Age__c, 
                        vlocity_ins__GroupCensusMemberId__r.Age_In_Sixty_Days__c,
                        vlocity_ins__GroupCensusMemberId__r.ARC_Smoker__c,
                        vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Birthdate__c,
                        vlocity_ins__GroupCensusMemberId__r.vlocity_ins__IsPrimaryMember__c,
                        vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressState__c,
                        vlocity_ins__GroupCensusMemberId__r.vlocity_ins__CensusId__r.ARC_CountSpouse__c,
                        vlocity_ins__GroupCensusMemberId__r.vlocity_ins__CensusId__r.ARC_CountChildren__c,
                        vlocity_ins__GroupCensusMemberId__r.vlocity_ins__CensusId__r.ARC_CountSuscribers__c,
                        vlocity_ins__GroupCensusMemberId__r.vlocity_ins__CensusId__r.ARC_PrimaryAccount__r.Census_Member__r.ARC_Age__c,
                        vlocity_ins__GroupCensusMemberId__r.vlocity_ins__CensusId__r.ARC_PrimaryAccount__r.Census_Member__r.Age_In_Sixty_Days__c
                    FROM vlocity_ins__Group_Census_Member_Plan__r
                )
            FROM vlocity_ins__ContractLineItem__c 
            WHERE 
                vlocity_ins__ContractId__c IN :contractIds AND
                vlocity_ins__RecordTypeName__c = 'Product' AND
                vlocity_ins__ProductType__c IN ('Medical', 'Ancillary')
        ];
    }

    public static List<vlocity_ins__ContractLineItem__c> getWeSharePlans(Set<Id> contractIds){
        return [
            SELECT vlocity_ins__ContractId__c
            FROM vlocity_ins__ContractLineItem__c 
            WHERE 
                vlocity_ins__ContractId__c IN :contractIds AND
                vlocity_ins__RecordTypeName__c = 'Product' AND
                vlocity_ins__ProductType__c IN ('Medical') AND 
                Name LIKE 'WeShare%' 
        ];
    }

    @InvocableMethod(label='Age Up Manager' description='Age Up Manager, launch age up methods from flows' category='Age Up')
    public static void invocableAgeUp(List<AgeUpRequest> ageUpRequests){
        Boolean executeBatch = false;
        List<Ages_Up__c> ageUps = new List<Ages_Up__c>();
        for(AgeUpRequest ageUpRequest : ageUpRequests){
            if(ageUpRequest.methodName == 'ageUpBatch'){
                executeBatch = true;
            } else if(ageUpRequest.methodName == 'applyAgeUp'){
                ageUps.add(ageUpRequest.ageUp);
            }
        }
        if (executeBatch) {
            Database.executeBatch(new ARC_AgeUp(), 1);
        }
        if (ageUps.size() > 0) {
            applyAgeUp(ageUps);
        }

    }

    public class AgeUpRequest {
        @InvocableVariable(label='Method' description='Method to execute' required=true)
        public String methodName;
        // valid values: applyDiscounts, populateDiscounts

        @InvocableVariable(label='Age Up' description='Contract Id List')
        public Ages_Up__c ageUp;
    }

}