public class ARC_AgeUpPriceCalculationQueable implements Queueable {
    private List<Ages_Up__c> ageUps;
    public Boolean applyOnPlans;

    public ARC_AgeUpPriceCalculationQueable(List<Ages_Up__c> ageUps) {
        this.ageUps = ageUps;
        this.applyOnPlans = false;
    }

    public void execute(QueueableContext context) {
        Set<Id> contractIds = new Set<Id>();
        Set<Id> contractBypassIds = new Set<Id>();

        for (Ages_Up__c ageUp : ageUps) {
            if(ageUp.ARC_BypassContractEffectiveCheck__c == true){
                contractBypassIds.add(ageUp.Contract__c);
            } else {
                contractIds.add(ageUp.Contract__c);
            }
        }

        system.debug(ageUps);
        system.debug(contractIds);

        Map<Id, vlocity_ins__ContractLineItem__c> plans = new Map<Id, vlocity_ins__ContractLineItem__c>(ARC_AgeUp.getPlans(contractIds));
        Map<Id, List<vlocity_ins__GroupCensusMember__c>> planMembers = mapPlanMembers(plans);
        Map<Id, Date> contractEffectiveDates = mapContractEffectiveDates(ageUps);
        Map<Id, Date> planEffectiveDates = mapPlansEffectiveDate(plans, contractEffectiveDates);

        Map<Id, List<Map<String,Object>>> planUserInputs = mapPlanUserInputs(mapPlanMembers(plans), planEffectiveDates);
        
        List<ARC_PriceCalculation.PlanPricingInput> pricingInputs = new List<ARC_PriceCalculation.PlanPricingInput>();
        for (Id planId : planUserInputs.keySet()) {
            ARC_PriceCalculation.PlanPricingInput input = new ARC_PriceCalculation.PlanPricingInput();
            input.planId = planId;
            input.productId = plans.get(planId).vlocity_ins__Product2Id__c;
            input.priceBeforeAgeUp = plans.get(planId).vlocity_ins__UnitPrice__c;
            input.contractId = plans.get(planId).vlocity_ins__ContractId__c;  // Add this line
            input.userInputs = planUserInputs.get(planId);
            input.plan = plans.get(planId);

            pricingInputs.add(input);
        }

        if (!contractBypassIds.isEmpty()) {
            Map<Id, vlocity_ins__ContractLineItem__c> plansBypass = new Map<Id, vlocity_ins__ContractLineItem__c>(ARC_AgeUp.getPlans(contractBypassIds));
            Map<Id, List<vlocity_ins__GroupCensusMember__c>> planMembersBypass = mapPlanMembers(plansBypass);
            // //Map<Id, Date> contractEffectiveDates = mapContractEffectiveDates(ageUps);
            Map<Id, Date> planEffectiveDatesByPass = mapPlansEffectiveDate(plansBypass, contractEffectiveDates);
            Map<Id, List<Map<String,Object>>> planUserInputsBypass = mapPlanUserInputsBypass(planMembersBypass, planEffectiveDatesByPass, contractBypassIds);
            for (Id planId : planUserInputsBypass.keySet()) {
                ARC_PriceCalculation.PlanPricingInput input = new ARC_PriceCalculation.PlanPricingInput();
                input.planId = planId;
                input.productId = plansBypass.get(planId).vlocity_ins__Product2Id__c;
                input.priceBeforeAgeUp = plansBypass.get(planId).vlocity_ins__UnitPrice__c;
                input.contractId = plansBypass.get(planId).vlocity_ins__ContractId__c;  // Add this line
                input.userInputs = planUserInputsBypass.get(planId);
                input.plan = plansBypass.get(planId);

                pricingInputs.add(input);
            }
            
        }


        ARC_PriceCalculation priceCalc = new ARC_PriceCalculation(pricingInputs);
        List<ARC_PriceCalculation.PlanPricingResult> results = priceCalc.calculatePrices();
        
        processPriceCalculationResults(results, ageUps);
    }

    @TestVisible
    private void processPriceCalculationResults(List<ARC_PriceCalculation.PlanPricingResult> results, List<Ages_Up__c> ageUps) {
        Set<Id> contractIds = new Set<Id>();
        List<vlocity_ins__ContractLineItem__c> plansToUpdate = new List<vlocity_ins__ContractLineItem__c>();
        List<Ages_Up__c> ageUpsToUpdate = new List<Ages_Up__c>();
        Map<Id, Ages_Up__c> ageUpMap = new Map<Id, Ages_Up__c>();
        Map<Id, Decimal> contractOldPrices = new Map<Id, Decimal>();
        for (Ages_Up__c ageUp : ageUps) {
            ageUp.ARC_PriceBeforeAgeUp__c = 0;
            ageUp.ARC_PriceAfterAgeUp__c = 0;
            ageUpMap.put(ageUp.Contract__c, ageUp);
        }

        for (ARC_PriceCalculation.PlanPricingResult result : results) {
            if (result.success) {
                Ages_Up__c ageUp = ageUpMap.get(result.contractId);
                vlocity_ins__ContractLineItem__c plan = result.plan;
                if (ageUp != null) {
                    ageUp.ARC_PriceBeforeAgeUp__c = ageUp.ARC_PriceBeforeAgeUp__c + result.priceBeforeAgeUp;
                    if(result.plan.vlocity_ins__ProductType__c == 'Ancillary'){
                        ageUp.ARC_PriceAfterAgeUp__c = ageUp.ARC_PriceAfterAgeUp__c + result.priceBeforeAgeUp;
                    }else{
                        ageUp.ARC_PriceAfterAgeUp__c = ageUp.ARC_PriceAfterAgeUp__c + result.price;
                    }
                    ageUpMap.put(result.contractId, ageUp);
                }
                
                if (plan != null && plan.vlocity_ins__ProductType__c != 'Ancillary') {
                    plan.vlocity_ins__UnitPrice__c = result.price;
                    Decimal smokerFee = plan.ARC_SmokerFee__c != null ? plan.ARC_SmokerFee__c : 0;
                    Decimal extraDependentFee = plan.ARC_ExtraDependentFee__c != null ? plan.ARC_ExtraDependentFee__c : 0;
                    plan.ARC_OriginalPrice__c = result.price - smokerFee - extraDependentFee;
                    contractIds.add(result.contractId);
                }
                plansToUpdate.add(plan);
            }
        }
        if(applyOnPlans){
            update plansToUpdate;
            ARC_Discounts.applyDiscounts(contractIds, false);
        }else{
            Map<Id, Decimal> contractNewPrices = new Map<Id, Decimal>();
            Map<Id, ARC_PromotionDiscount__c> activeDiscounts = new Map<Id,ARC_PromotionDiscount__c>(ARC_Discounts.getActiveDiscounts(contractIds));
            Map<Id, Map<Id, ARC_PromotionDiscount__c>> discountsByContractId = ARC_Discounts.mapDiscountsByContractId(activeDiscounts);
            Map<Id, List<vlocity_ins__ContractLineItem__c>> plansByContractId = ARC_Discounts.mapPlansByContractId(plansToUpdate);
            for (Id contractId : discountsByContractId.keySet()) {
                List<vlocity_ins__ContractLineItem__c> plans = plansByContractId.get(contractId);
                List<ARC_PromotionDiscount__c> discounts = discountsByContractId.get(contractId).values();
                plans = ARC_Discounts.getPlansWithDiscounts(plans, discounts);
                Decimal totalPrice = ARC_Discounts.calculateTotalPrice(plans);
                contractNewPrices.put(contractId, totalPrice);
            }
            for (Id contractId : contractNewPrices.keySet()) {
                Ages_Up__c ageUp = ageUpMap.get(contractId);
                if (ageUp != null) {
                    ageUp.ARC_PriceAfterAgeUp__c = contractNewPrices.get(contractId);
                    ageUpMap.put(contractId, ageUp);
                }
            }
            update ageUpMap.values();
        }
    }
    

    private static Map<Id, List<Map<String,Object>>> mapPlanUserInputs(Map<Id, List<vlocity_ins__GroupCensusMember__c>> planMembers, Map<Id,Date> planEffectiveDate){
        Map<Id, List<Map<String,Object>>> mapPlanUserInputs = new Map<Id, List<Map<String,Object>>>();
        for(Id planId : planMembers.keySet()){
            List<Map<String,Object>> memberInputs = new List<Map<String,Object>>();
            Decimal oldestMemberAge = 0;
            
            // First, find the oldest member's age in sixty days
            for(vlocity_ins__GroupCensusMember__c member : planMembers.get(planId)){
                Decimal memberAge = calculateAge(member.vlocity_ins__Birthdate__c, planEffectiveDate.get(planId));
                if(memberAge > oldestMemberAge){
                    oldestMemberAge = memberAge;
                }
            }

            Boolean primaryExists = false;
            for(vlocity_ins__GroupCensusMember__c member : planMembers.get(planId)){
                if(member.vlocity_ins__IsPrimaryMember__c){
                    primaryExists = true;
                    break;
                }
            }

            for(vlocity_ins__GroupCensusMember__c member : planMembers.get(planId)){
                String coverageAIDD = ARC_PCAncillaryUserInputs.getCoverageAidd(member.vlocity_ins__CensusId__r.ARC_CountSpouse__c > 0, Integer.valueOf(member.vlocity_ins__CensusId__r.ARC_CountSuscribers__c), Integer.valueOf(member.vlocity_ins__CensusId__r.ARC_CountChildren__c));
                String coverageSMART = ARC_PCAncillaryUserInputs.getCoverageSmart(member.vlocity_ins__CensusId__r.ARC_CountSpouse__c > 0, Integer.valueOf(member.vlocity_ins__CensusId__r.ARC_CountSuscribers__c), Integer.valueOf(member.vlocity_ins__CensusId__r.ARC_CountChildren__c));
                Integer extraDependants = Integer.valueOf(Math.max(0, member.vlocity_ins__CensusId__r.ARC_CountChildren__c - 3));
                Integer dependants = Integer.valueOf(member.vlocity_ins__CensusId__r.ARC_CountSuscribers__c - 1);

                Map<String,Object> input = new Map<String,Object>{
                    'RF_Census.CM_IsPrimary' => primaryExists ? member.vlocity_ins__IsPrimaryMember__c : true,
                    'RF_Census.CM_Smoker' => member.ARC_Smoker__c,
                    'RF_Census.CRF_PrimaryMemberAge' => oldestMemberAge,
                    'RF_Census.CRF_ExtraDependants' => extraDependants,
                    'RF_Census.CRF_Dependants' => dependants,
                    'RF_Census.CM_State' => member.ARC_PhysicalAddressState__c,
                    'RF_Census.CRF_CoverageAIDD' => coverageAIDD,
                    'RF_Census.CRF_Coverage' => coverageSMART
                };
                if(!primaryExists){
                    primaryExists = true;
                }
                memberInputs.add(input);
            }
            mapPlanUserInputs.put(planId, memberInputs);
        }
        return mapPlanUserInputs;
    }

    private static Map<Id, List<Map<String,Object>>> mapPlanUserInputsBypass(Map<Id, List<vlocity_ins__GroupCensusMember__c>> planMembersBypass, Map<Id, Date> planEffectiveDatesByPass, Set<Id> contractBypassIds){
        Map<Id, List<Map<String,Object>>> mapPlanUserInputsBypass = new Map<Id, List<Map<String,Object>>>();
        Map<Id, ARC_ContractParticipant__c> accountidcContractParticipantMap = new Map<Id, ARC_ContractParticipant__c>();

        List<Contract> retriveContractsDataList = [
            SELECT Id, ARC_EffectiveDate__c, Status,
                (SELECT Id, Name, ARC_Relationship__c, ARC_BirthDate__c, ARC_PersonAccount__c, ARC_Address__StateCode__s, ARC_Smoker__c FROM Contract_Participants__r)
            FROM Contract
            WHERE Id IN :contractBypassIds
        ];

        for (Contract c : retriveContractsDataList) {
            
            for (ARC_ContractParticipant__c cp : c.Contract_Participants__r) {
                accountidcContractParticipantMap.put(cp.ARC_PersonAccount__c, cp);
                system.debug('cp ' + cp);
            }
            
        }

        for(Id planId : planMembersBypass.keySet()){
            List<Map<String,Object>> memberInputs = new List<Map<String,Object>>();

            Integer totalMembers = 0;
            Integer countPrimary = 0;
            Integer countSpouse = 0;
            Integer countChilds = 0;
            Integer oldestMemberAge = 0;

            system.debug('planId '+ planId);

            for(vlocity_ins__GroupCensusMember__c member : planMembersBypass.get(planId)){
                Id memberAccountId = member.vlocity_ins__ContactId__r.AccountId;
                String relationship = accountidcContractParticipantMap.get(memberAccountId).ARC_Relationship__c;
                Date memberBirthdate = accountidcContractParticipantMap.get(memberAccountId).ARC_BirthDate__c;

                Integer memberAge = calculateAge(memberBirthdate, planEffectiveDatesByPass.get(planId));
                if(memberAge > oldestMemberAge){
                    oldestMemberAge = memberAge;
                }

                totalMembers++;

                if(relationship == 'Primary') {
                    countPrimary++;
                } else if(relationship == 'Spouse') {
                    countSpouse++;
                } else if(relationship == 'Child') {
                    countChilds++;
                }
                
            }

            String coverageAIDD;
            String coverageSMART;
            Integer extraDependants = Math.max(countChilds - 3, 0);
            Integer dependants = totalMembers - 1;
            Boolean spouseIsPrimaryOnPlan = countPrimary == 0 && countSpouse == 1 ? true : false;

            // Set Coverages for Anillaries
            if((countPrimary == 1 && countSpouse == 0 && countChilds == 0) || (countPrimary == 0 && countSpouse == 1 && countChilds == 0)){
                coverageSMART = 'Primary';
                coverageAIDD = 'Primary';
            } else if(countPrimary == 1 && countSpouse == 1 && countChilds == 0){
                coverageSMART = 'Primary + Spouse';
                coverageAIDD = 'Primary + Spouse'; 
            } else if((countPrimary == 1 && countSpouse == 0 && countChilds > 0) || (countPrimary == 0 && countSpouse == 1 && countChilds > 0)){
                coverageSMART = 'Primary + Child';
                coverageAIDD = 'Primary + Children';
            } else {
                coverageSMART = 'Family';
                coverageAIDD = 'Family';
            }

            for(vlocity_ins__GroupCensusMember__c member : planMembersBypass.get(planId)){
                Id memberAccountId = member.vlocity_ins__ContactId__r.AccountId;
                String relationship = accountidcContractParticipantMap.get(memberAccountId).ARC_Relationship__c;
                Boolean isSmoker = accountidcContractParticipantMap.get(memberAccountId).ARC_Smoker__c == true ? true : false;
                String memberState = accountidcContractParticipantMap.get(memberAccountId).ARC_Address__StateCode__s;
                Boolean isPrimary = relationship == 'Primary' || relationship == 'Spouse' && spouseIsPrimaryOnPlan == true ? true : false;

                Map<String,Object> input = new Map<String,Object>{
                    'RF_Census.CM_IsPrimary' => isPrimary,
                    'RF_Census.CM_Smoker' => isSmoker,
                    'RF_Census.CRF_PrimaryMemberAge' => oldestMemberAge,
                    'RF_Census.CRF_ExtraDependants' => extraDependants,
                    'RF_Census.CRF_Dependants' => dependants,
                    'RF_Census.CM_State' => memberState,
                    'RF_Census.CRF_CoverageAIDD' => coverageAIDD,
                    'RF_Census.CRF_Coverage' => coverageSMART
                };

                system.debug('input ' + input);
                memberInputs.add(input);
            }

            mapPlanUserInputsBypass.put(planId, memberInputs);
        }


        return mapPlanUserInputsBypass;
    }

    private  Map<Id, Date> mapContractEffectiveDates(List<Ages_Up__c> ageUps){
        Map<Id, Date> contractEffectiveDates = new Map<Id, Date>();
        for(Ages_Up__c ageUp : ageUps){
            Date ageUpEffDate = ageUp.ARC_ManualDelay__c != null ? ageUp.ARC_ManualDelay__c : ageUp.ARC_EffectiveDate__c;
            Date contractEffDate = ageUp.Contract__r.ARC_EffectiveDate__c;

            if(applyOnPlans){
                contractEffectiveDates.put(ageUp.Contract__c, ageUpEffDate > Date.today() ? contractEffDate.addDays(60) : ageUpEffDate );
            }else {
                contractEffectiveDates.put(ageUp.Contract__c, ageUpEffDate);
            }
        }
        return contractEffectiveDates;
    }

    private static Map<Id, Date> mapPlansEffectiveDate(Map<Id,vlocity_ins__ContractLineItem__c> plans, Map<Id, Date> contractEffectiveDates){
        Map<Id, Date> planEffectiveDates = new Map<Id, Date>();
        for(vlocity_ins__ContractLineItem__c plan : plans.values()){
            planEffectiveDates.put(plan.Id, contractEffectiveDates.get(plan.vlocity_ins__ContractId__c));
        }
        return planEffectiveDates;
    }



    private static Map<Id, List<vlocity_ins__GroupCensusMember__c>> mapPlanMembers(Map<Id,vlocity_ins__ContractLineItem__c> plans){
        Map<Id, List<vlocity_ins__GroupCensusMember__c>> planMembers = new Map<Id, List<vlocity_ins__GroupCensusMember__c>>();
        for(vlocity_ins__ContractLineItem__c plan : plans.values()){
            for (vlocity_ins__GroupCensusMemberPlan__c memberPlan : plan.vlocity_ins__Group_Census_Member_Plan__r) {
                if (!planMembers.containsKey(plan.Id)) {
                    planMembers.put(plan.Id, new List<vlocity_ins__GroupCensusMember__c>{memberPlan.vlocity_ins__GroupCensusMemberId__r});
                } else {
                    planMembers.get(plan.Id).add(memberPlan.vlocity_ins__GroupCensusMemberId__r);
                }
            }
        }
        return planMembers;
    }

    private static Integer calculateAge(Date birthDate, Date dateToCalculate) {
        if (birthDate == null || dateToCalculate == null) {
            return null;
        }
        
        Integer age = dateToCalculate.year() - birthDate.year();
        
        // Adjust age if birthday hasn't occurred yet in the calculation year
        if (dateToCalculate.month() < birthDate.month() || 
            (dateToCalculate.month() == birthDate.month() && dateToCalculate.day() < birthDate.day())) {
            age--;
        }
        
        return age;
    }
}




/*

batch 
    execute[
        input1 -> calculate -> update
        input2 -> calculate -> update
        input3 -> calculate -> update
        input4 -> calculate -> update
    ]




*/