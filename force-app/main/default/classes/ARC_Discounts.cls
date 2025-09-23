public without sharing class ARC_Discounts {

    //this will apply the discounts, call only when a discount is changed to activated/terminated
    public static void applyDiscounts(Set<Id> contractIds, Boolean applyAgeUp) {
        List<vlocity_ins__ContractLineItem__c> plans = getPlans(contractIds);
        List<ARC_PromotionDiscount__c> allRelatedDiscounts = getDiscountsByContractIds(contractIds);
        List<ARC_PromotionDiscount__c> activeDiscounts = filterByActiveDiscounts(allRelatedDiscounts);
        List<ARC_PromotionDiscount__c> activeAppFeeDiscounts = filterByActiveAppFeeDiscounts(allRelatedDiscounts);
        List<ARC_PromotionDiscount__c> inactiveDiscounts = filterByInactiveDiscounts(allRelatedDiscounts);
        //this recalculates the price of the plans with the discounts
        plans = getPlansWithDiscounts(plans, activeDiscounts);
        //Update the Line Items
        update plans;
        //Update the Discount Dollar amountof all related Discounts not terminated and returns the active discounts. 
        activeDiscounts = populateDiscounts(contractIds);
        if(!activeAppFeeDiscounts.isEmpty())applyAppFeeDiscounts(contractIds, activeAppFeeDiscounts);
        //Update the recurring orders
        updateOrderPrice(contractIds);
        Set<Id> contractsWithAgeUp = getContractsWithAgeUp(contractIds);
        if (applyAgeUp && !contractsWithAgeUp.isEmpty()) {
            Age_Up_Calculation__e event = new Age_Up_Calculation__e(
                ARC_ContractIds__c  = String.join(new List<Id>(contractsWithAgeUp), ',')
            );
            Database.SaveResult result = EventBus.publish(event);
        }
    }




    //this will populate the discounts related to the contracts and return the active discounts.
    public static List<ARC_PromotionDiscount__c> populateDiscounts(Set<Id> contractIds){
        Map<Id, ARC_PromotionDiscount__c> relatedDiscounts = new Map<Id,ARC_PromotionDiscount__c>(getDiscountsByContractIds(contractIds));
        Map<Id, ARC_PromotionDiscount__c> activeDiscounts = new Map<Id,ARC_PromotionDiscount__c>(getActiveDiscounts(contractIds));
        List<ARC_PromotionDiscount__c> discountsToUpdate = new List<ARC_PromotionDiscount__c>();
        List<vlocity_ins__ContractLineItem__c> plans = getPlans(contractIds);
        Map<Id, Map<Id, ARC_PromotionDiscount__c>> activeDiscountsByContractId = mapDiscountsByContractId(activeDiscounts);
        Map<Id, Map<Id, ARC_PromotionDiscount__c>> discountsByContractId = mapDiscountsByContractId(relatedDiscounts);
        Map<Id, Map<Id, ARC_PromotionDiscount__c>> discountsByContractIdToUpdate = new Map<Id, Map<Id, ARC_PromotionDiscount__c>>();
        Map<Id, List<vlocity_ins__ContractLineItem__c>> plansByContractId = mapPlansByContractId(plans);
        // System.debug('plansByContractId: ' + plansByContractId);
        // System.debug('discountsByContractId: ' + discountsByContractId);
        // System.debug('activeDiscountsByContractId: ' + activeDiscountsByContractId);
        // System.debug('plans: ' + plans);
        // System.debug('activeDiscounts: ' + activeDiscounts);
        
        for (Id contractId : discountsByContractId.keySet()) {
            for(Id discountId : discountsByContractId.get(contractId).keySet()){
                ARC_PromotionDiscount__c discount = discountsByContractId.get(contractId).get(discountId);
                if(discount.ARC_Status__c == 'Terminated'){
                    continue;
                }
                Map<Id, ARC_PromotionDiscount__c> discountsWithCurrentDiscount = new Map<Id, ARC_PromotionDiscount__c>();
                Map<Id, ARC_PromotionDiscount__c> discountsWithoutCurrentDiscount = new Map<Id, ARC_PromotionDiscount__c>();
                if (activeDiscountsByContractId.get(contractId) == null) {
                    activeDiscountsByContractId.put(contractId, new Map<Id, ARC_PromotionDiscount__c>());
                }
                discountsWithCurrentDiscount.putAll(activeDiscountsByContractId.get(contractId));
                discountsWithoutCurrentDiscount.putAll(activeDiscountsByContractId.get(contractId));
                if (!discountsWithCurrentDiscount.containsKey(discountId)) {
                    discountsWithCurrentDiscount.put(discountId, discount);
                }
                if (discountsWithoutCurrentDiscount.containsKey(discountId)) {
                    discountsWithoutCurrentDiscount.remove(discountId);
                }

                if(isApplyOverAppFee(discount)){
                    if(discount.ARC_PriceWithoutDiscount__c == null || discount.ARC_PriceWithoutDiscount__c == 0){
                        discount.ARC_PriceWithDiscount__c = getAmountWithAppFeeDiscounts(discount.ARC_Contract__r.ARC_AppFeeOrder__r.ChargentOrders__Charge_Amount__c, discountsWithCurrentDiscount.values());
                        discount.ARC_PriceWithoutDiscount__c = discount.ARC_Contract__r.ARC_AppFeeOrder__r.ChargentOrders__Charge_Amount__c;
                    }else{
                        discount.ARC_PriceWithDiscount__c = getAmountWithAppFeeDiscounts(discount.ARC_PriceWithoutDiscount__c, discountsWithCurrentDiscount.values());
                    }
                    discount.ARC_AmountToDiscountPerTransaction__c = discount.ARC_PriceWithoutDiscount__c - discount.ARC_PriceWithDiscount__c;
                }else{
                    // System.debug('discountsWithCurrentDiscount: ' + discountsWithCurrentDiscount.values());
                    discount.ARC_PriceWithDiscount__c = calculateTotalPrice(getPlansWithDiscounts(plansByContractId.get(contractId), discountsWithCurrentDiscount.values())).setScale(2, RoundingMode.HALF_UP);
                    // System.debug('discount.ARC_PriceWithDiscount__c: ' + discount.ARC_PriceWithDiscount__c);
                    // System.debug('discountsWithoutCurrentDiscount: ' + discountsWithoutCurrentDiscount.values());
                    discount.ARC_PriceWithoutDiscount__c = calculateTotalPrice(getPlansWithDiscounts(plansByContractId.get(contractId), discountsWithoutCurrentDiscount.values())).setScale(2, RoundingMode.HALF_UP);
                    // System.debug('discount.ARC_PriceWithoutDiscount__c: ' + discount.ARC_PriceWithoutDiscount__c);
                }
                //POPULATE DISCOUNTBYCONTRACTID
                if(discountsByContractIdToUpdate.get(contractId) == null){
                    discountsByContractIdToUpdate.put(contractId, new Map<Id, ARC_PromotionDiscount__c>());
                }
                discountsByContractIdToUpdate.get(contractId).put(discountId, discount);
            }
        }
        discountsToUpdate = populateDiscountDollarAmmounts(plans, discountsByContractIdToUpdate);
        update discountsToUpdate;
        List<ARC_PromotionDiscount__c> activeDiscountsToReturn = new List<ARC_PromotionDiscount__c>();
        for(ARC_PromotionDiscount__c discount : discountsToUpdate){
            if(activeDiscounts.get(discount.Id) != null){
                activeDiscountsToReturn.add(discount);
            }
        }
        return activeDiscountsToReturn;
    }

    public static List<ARC_PromotionDiscount__c> populateDiscountDollarAmmounts(List<vlocity_ins__ContractLineItem__c> plans, Map<Id, Map<Id, ARC_PromotionDiscount__c>> discountsByContractId){ 
        Map<Id, Decimal> discountAmountMap = new Map<Id, Decimal>();
        List<ARC_PromotionDiscount__c> discountsToUpdate = new List<ARC_PromotionDiscount__c>();
        for (Id contractId : discountsByContractId.keySet()) {
            Map<Id, ARC_PromotionDiscount__c> discounts = discountsByContractId.get(contractId);
            discountsToUpdate.addAll(discounts.values());
        }

        for (vlocity_ins__ContractLineItem__c plan : plans) {
            Decimal remainingPrice = plan.ARC_OriginalPrice__c;
            if(discountsByContractId.get(plan.vlocity_ins__ContractId__c) == null){
                continue;
            }
            List<ARC_PromotionDiscount__c> discountsByPlan = orderDiscounts(discountsByContractId.get(plan.vlocity_ins__ContractId__c).values());
            for (ARC_PromotionDiscount__c discount : discountsByPlan) {
                if (!isDiscountApplicable(discount, plan) || discount.ARC_Status__c != 'Activated') { 
                    continue;
                }
                Double discountAmount = 0;
                Double discountPercent = discount.ARC_DiscountRate__c != null ? discount.ARC_DiscountRate__c : discount.ARC_PromoCode__r.ARC_DiscountRate__c;
                Double discountCurrency = discount.ARC_DiscountedAmount__c != null ? discount.ARC_DiscountedAmount__c : discount.ARC_PromoCode__r.ARC_DiscountedAmount__c;
                if(discountPercent != null && discountPercent > 0){
                    discountAmount = remainingPrice * (discountPercent/100);
                } else if (discountCurrency != null && discountCurrency > 0) {
                    // Fixed amount discount
                    discountAmount = discountCurrency;
                }
                
                // Ensure the discount doesn't exceed the remaining price
                discountAmount = Math.min(discountAmount, remainingPrice);
                
                remainingPrice -= discountAmount;
                
                Decimal totalDiscountAmount = discountAmountMap.containsKey(discount.Id) ? discountAmountMap.get(discount.Id) : 0;
                discountAmountMap.put(discount.Id, totalDiscountAmount + discountAmount);
            }
        }
        
        
        for (ARC_PromotionDiscount__c discount : discountsToUpdate) {
            if (discountAmountMap.containsKey(discount.Id)) {
                discount.ARC_AmountToDiscountPerTransaction__c = discountAmountMap.get(discount.Id).setScale(2, RoundingMode.HALF_UP);
            }
        }
        
        return discountsToUpdate;
    }


    public static List<ARC_PromotionDiscount__c> orderDiscounts(List<ARC_PromotionDiscount__c> discounts) {
        List<ARC_PromotionDiscount__c> orderedDiscounts = new List<ARC_PromotionDiscount__c>();
        
        for (ARC_PromotionDiscount__c discount : discounts) {
            if (discount.ARC_ApplyFirst__c && (discount.ARC_DiscountedAmount__c > 0 || discount.ARC_PromoCode__r.ARC_DiscountedAmount__c > 0)) {
                orderedDiscounts.add(discount);
            } 
        }
        for (ARC_PromotionDiscount__c discount : discounts) {
            if (discount.ARC_DiscountRate__c > 0 || discount.ARC_PromoCode__r.ARC_DiscountRate__c > 0) {
                orderedDiscounts.add(discount);
            } 
        }
        for (ARC_PromotionDiscount__c discount : discounts) {
            if (!discount.ARC_ApplyFirst__c && (discount.ARC_DiscountedAmount__c > 0 || discount.ARC_PromoCode__r.ARC_DiscountedAmount__c > 0)) {
                orderedDiscounts.add(discount);
            } 
        }
        
        
        return orderedDiscounts;
    }


    public static List<vlocity_ins__ContractLineItem__c> getPlansWithDiscounts(List<vlocity_ins__ContractLineItem__c> plans, List<ARC_PromotionDiscount__c> discounts){
        if (plans == null) {
            plans = new List<vlocity_ins__ContractLineItem__c>();
        }
        Map<Id, Decimal> totalPercentageDiscountByPlan = percentageDiscountByPlan(discounts, plans);
        System.debug('totalPercentageDiscountByPlan: ' + totalPercentageDiscountByPlan);
        // Map<Id, Decimal> totalCurrencyDiscountByPlan = currencyDiscountByPlan(discounts, plans);
        Map<Id,Decimal> totalCurrencyDiscountByPlanApplyFirst = currencyDiscountByPlan(filterByApplyFirst(discounts, true), plans);
        Map<Id,Decimal> totalCurrencyDiscountByPlanApplyLast = currencyDiscountByPlan(filterByApplyFirst(discounts, false), plans);

        for(vlocity_ins__ContractLineItem__c plan : plans){
            Decimal totalPercentageDiscount = totalPercentageDiscountByPlan.get(plan.Id) != null ? totalPercentageDiscountByPlan.get(plan.Id) : 1;
            // Decimal totalCurrencyDiscount = totalCurrencyDiscountByPlan.get(plan.Id) != null ? totalCurrencyDiscountByPlan.get(plan.Id) : 0;
            Decimal amountApplyFirstDiscount = totalCurrencyDiscountByPlanApplyFirst.get(plan.Id) != null ? totalCurrencyDiscountByPlanApplyFirst.get(plan.Id) : 0;
            Decimal amountApplyAfterDiscount = totalCurrencyDiscountByPlanApplyLast.get(plan.Id) != null ? totalCurrencyDiscountByPlanApplyLast.get(plan.Id) : 0;

            System.debug('totalPercentageDiscount: ' + totalPercentageDiscount);
            System.debug('amountApplyFirstDiscount: ' + amountApplyFirstDiscount);
            System.debug('amountApplyAfterDiscount: ' + amountApplyAfterDiscount);
            System.debug('original price: ' + plan.ARC_OriginalPrice__c);
            //apply the discounts
            plan.vlocity_ins__UnitPrice__c = (((plan.ARC_OriginalPrice__c - amountApplyFirstDiscount) * totalPercentageDiscount) - amountApplyAfterDiscount + getFees(plan)).setScale(2, RoundingMode.HALF_UP);
        }

        return plans;
    }

    public static Decimal getAmountWithAppFeeDiscounts(Decimal amount, List<ARC_PromotionDiscount__c> discounts){
        Decimal applyFirst= 0;
        Decimal applyAfter = 0;
        Decimal percentage = 1;

        for (ARC_PromotionDiscount__c discount : discounts) {
            if(isApplyOverAppFee(discount)){
                Decimal discountedAmount = discount.ARC_DiscountedAmount__c != null? discount.ARC_DiscountedAmount__c: (discount.ARC_PromoCode__r.ARC_DiscountedAmount__c != null? discount.ARC_PromoCode__r.ARC_DiscountedAmount__c:0);
                Decimal discountedRate = discount.ARC_DiscountRate__c != null? discount.ARC_DiscountRate__c: (discount.ARC_PromoCode__r.ARC_DiscountRate__c != null? discount.ARC_PromoCode__r.ARC_DiscountRate__c:0);
                if(discountedRate > 0){
                    percentage = percentage * (1 - discountedRate/100);
                }else{
                    if(discount.ARC_ApplyFirst__c){
                        applyFirst += discountedAmount;
                    }else{
                        applyAfter += discountedAmount;
                    }
                }
            }
        }
        return (amount - applyFirst) * percentage - applyAfter;
    }

    private static List<ARC_PromotionDiscount__c> filterByApplyFirst(List<ARC_PromotionDiscount__c> discounts, Boolean applyFirst){
        List<ARC_PromotionDiscount__c> applyFirstDiscounts = new List<ARC_PromotionDiscount__c>();
        for(ARC_PromotionDiscount__c discount : discounts){
            if(discount.ARC_ApplyFirst__c == applyFirst){
                applyFirstDiscounts.add(discount);
            }
        }
        return applyFirstDiscounts;
    }

    public static Decimal getFees(vlocity_ins__ContractLineItem__c plan){
        Decimal smokerFee = plan.ARC_SmokerFee__c != null ? plan.ARC_SmokerFee__c : 0;
        Decimal extraDependentFee = plan.ARC_ExtraDependentFee__c != null ? plan.ARC_ExtraDependentFee__c : 0;
        return smokerFee + extraDependentFee;
    }

    public static List<vlocity_ins__ContractLineItem__c> getPlans(Set<Id> contractIds){
        return [
            SELECT Id, 
                vlocity_ins__UnitPrice__c, 
                ARC_OriginalPrice__c,
                ARC_SmokerFee__c, 
                ARC_ExtraDependentFee__c,
                vlocity_ins__ContractId__c,
                vlocity_ins__ProductType__c
            FROM vlocity_ins__ContractLineItem__c 
            WHERE 
                vlocity_ins__ContractId__c IN :contractIds AND 
                vlocity_ins__RecordTypeName__c = 'Product' AND
                vlocity_ins__ProductType__c IN ('Medical', 'Ancillary')
        ];
    }

    public static List<ARC_PromotionDiscount__c> getActiveDiscounts(Set<Id> contractIds){
        return [
            SELECT Id, 
                ARC_Active__c,
                ARC_ApplyOver__c, 
                ARC_ApplyFirst__c,
                ARC_PriceWithoutDiscount__c,
                ARC_PriceWithDiscount__c,
                ARC_DiscountRate__c, 
                ARC_PromoCode__r.ARC_DiscountRate__c, 
                ARC_DiscountedAmount__c,
                ARC_PromoCode__r.ARC_DiscountedAmount__c, 
                ARC_Status__c,
                ARC_PromoCode__r.ARC_ApplyOver__c,
                ARC_Contract__c,
                ARC_Contract__r.ARC_AppFeeOrder__r.ChargentOrders__Charge_Amount__c
            FROM ARC_PromotionDiscount__c 
            WHERE ARC_Contract__c IN :contractIds AND ARC_Status__c = 'Activated'
            ORDER BY CreatedDate ASC
        ];
    }
    
    public static List<ARC_PromotionDiscount__c> getDiscountsByIds(Set<Id> discountIds){
        return [
            SELECT Id, 
                ARC_Active__c,
                ARC_ApplyOver__c, 
                ARC_ApplyFirst__c,
                ARC_PriceWithoutDiscount__c,
                ARC_PriceWithDiscount__c,
                ARC_DiscountRate__c, 
                ARC_PromoCode__r.ARC_DiscountRate__c, 
                ARC_DiscountedAmount__c,
                ARC_PromoCode__r.ARC_DiscountedAmount__c, 
                ARC_Status__c ,
                ARC_Contract__c,
                ARC_PromoCode__r.ARC_ApplyOver__c,
                ARC_Contract__r.ARC_AppFeeOrder__r.ChargentOrders__Charge_Amount__c
            FROM ARC_PromotionDiscount__c 
            WHERE Id IN :discountIds
            ORDER BY CreatedDate ASC

        ];
    }

    public static List<ARC_PromotionDiscount__c> getDiscountsByContractIds(Set<Id> contractIds){
        return [
            SELECT Id, 
                ARC_Active__c,
                ARC_ApplyOver__c, 
                ARC_ApplyFirst__c,
                ARC_DiscountRate__c, 
                ARC_PriceWithoutDiscount__c,
                ARC_PriceWithDiscount__c,
                ARC_PromoCode__r.ARC_DiscountRate__c, 
                ARC_DiscountedAmount__c,
                ARC_PromoCode__r.ARC_DiscountedAmount__c, 
                ARC_Status__c,
                ARC_PromoCode__r.ARC_ApplyOver__c,
                ARC_Contract__c,
                ARC_Contract__r.ARC_AppFeeOrder__r.ChargentOrders__Charge_Amount__c
            FROM ARC_PromotionDiscount__c 
            WHERE ARC_Contract__c IN :contractIds
            ORDER BY CreatedDate ASC
        ];
    }

    public static boolean isDiscountApplicable(ARC_PromotionDiscount__c discount, vlocity_ins__ContractLineItem__c plan){
        String applyOver = discount.ARC_ApplyOver__c != null ? discount.ARC_ApplyOver__c : discount.ARC_PromoCode__r.ARC_ApplyOver__c;
        Boolean isAmount = discount.ARC_DiscountedAmount__c != null || discount.ARC_PromoCode__r.ARC_DiscountedAmount__c != null;
        Boolean isDiscountApplicable = (applyOver == 'Medical' && plan.vlocity_ins__ProductType__c == 'Medical') ||
                                        (applyOver == 'Total Price' && isAmount && plan.vlocity_ins__ProductType__c == 'Medical') ||
                                        (applyOver == 'Total Price' && !isAmount);
        return isDiscountApplicable;
    }

    public static Map<Id, Map<Id, ARC_PromotionDiscount__c>> mapDiscountsByContractId(Map<Id, ARC_PromotionDiscount__c> discounts){
        Map<Id, Map<Id, ARC_PromotionDiscount__c>> discountsByContractId = new Map<Id, Map<Id, ARC_PromotionDiscount__c>>();
        for(Id discountId : discounts.keySet()){
            ARC_PromotionDiscount__c discount = discounts.get(discountId);
            if(discountsByContractId.containsKey(discount.ARC_Contract__c)){
                discountsByContractId.get(discount.ARC_Contract__c).put(discountId, discount);
            }else{
                discountsByContractId.put(discount.ARC_Contract__c, new Map<Id, ARC_PromotionDiscount__c>{discount.Id => discount});
            }
        }
        return discountsByContractId;
    }

    public static Decimal calculateTotalPrice(List<vlocity_ins__ContractLineItem__c> plans) {
        Decimal totalPrice = 0;
        for (vlocity_ins__ContractLineItem__c plan : plans) {
            totalPrice += plan.vlocity_ins__UnitPrice__c;
        }
        return totalPrice;
    }

    public static Map<Id,Decimal> percentageDiscountByPlan(List<ARC_PromotionDiscount__c> discounts, List<vlocity_ins__ContractLineItem__c> plans){
        Map<Id,Decimal> totalPercentageDiscountByPlan = new Map<Id,Decimal>();
        
        for (vlocity_ins__ContractLineItem__c plan : plans) {
            Decimal totalPercentageDiscount = 1; //starts with 100% of the original price, no discount
            if (discounts == null) {
                continue;
            }
            for(ARC_PromotionDiscount__c discount : discounts){
                if (plan.vlocity_ins__ContractId__c == discount.ARC_Contract__c) {
                    if(isDiscountApplicable(discount, plan) == false){
                        continue;
                    }
                    Double discountPercent = discount.ARC_DiscountRate__c != null ? discount.ARC_DiscountRate__c : discount.ARC_PromoCode__r.ARC_DiscountRate__c;
                    if(discountPercent != null){
                        totalPercentageDiscount = totalPercentageDiscount * (1 - discountPercent/100);
                    }
                }
            }
            totalPercentageDiscountByPlan.put(plan.Id, totalPercentageDiscount);
        }

        return totalPercentageDiscountByPlan;
    }

    private static Map<Id,Decimal> currencyDiscountByPlan(List<ARC_PromotionDiscount__c> discounts, List<vlocity_ins__ContractLineItem__c> plans){
        Map<Id,Decimal> totalCurrencyDiscountByPlan = new Map<Id,Decimal>();

        for (vlocity_ins__ContractLineItem__c plan : plans) {
            Decimal totalCurrencyDiscount = 0; //starts with 0 discount
            if (discounts == null) {
                continue;
            }
            for(ARC_PromotionDiscount__c discount : discounts){
                if (plan.vlocity_ins__ContractId__c == discount.ARC_Contract__c) {
                    if(isDiscountApplicable(discount, plan) == false){
                        continue;
                    }
                    if(discount.ARC_DiscountedAmount__c != null){
                        totalCurrencyDiscount += discount.ARC_DiscountedAmount__c;
                    }
                }
            }
            totalCurrencyDiscountByPlan.put(plan.Id, totalCurrencyDiscount);
        }

        return totalCurrencyDiscountByPlan;
    }
    
    public static Map<Id, Decimal> appFeePercentageDiscountByContract(Set<Id> contractIds, List<ARC_PromotionDiscount__c> discounts){
        Map<Id,Decimal> totalPercentageDiscountByContract = new Map<Id,Decimal>();
        if (discounts == null) {
            return totalPercentageDiscountByContract;
        }
        for (Id contractId : contractIds) {
            Decimal totalPercentageDiscount = 1; //starts with 100% of the original price, no discount
            for(ARC_PromotionDiscount__c discount : discounts){
                if(isApplyOverAppFee(discount) && discount.ARC_Contract__c == contractId){
                    Double discountPercent = discount.ARC_DiscountRate__c != null ? discount.ARC_DiscountRate__c : discount.ARC_PromoCode__r.ARC_DiscountRate__c;
                    if(discountPercent != null){
                        totalPercentageDiscount = totalPercentageDiscount * (1 - discountPercent/100);
                    }
                }
            }
            totalPercentageDiscountByContract.put(contractId, totalPercentageDiscount);
        }

        return totalPercentageDiscountByContract;
    }

    public static Map<Id, Decimal> appFeeCurrencyDiscountByContract(Set<Id> contractIds, List<ARC_PromotionDiscount__c> discounts){
        Map<Id,Decimal> totalCurrencyDiscountByContract = new Map<Id,Decimal>();

        if (discounts == null) {
            return totalCurrencyDiscountByContract;
        }

        for (Id contractId : contractIds) {
            Decimal totalCurrencyDiscount = 0; //starts with 0 discount
            for(ARC_PromotionDiscount__c discount : discounts){
                if(isApplyOverAppFee(discount) && discount.ARC_Contract__c == contractId){
                    if(discount.ARC_DiscountedAmount__c != null){
                        totalCurrencyDiscount += discount.ARC_DiscountedAmount__c;
                    }
                }
            }
            totalCurrencyDiscountByContract.put(contractId, totalCurrencyDiscount);
        }

        return totalCurrencyDiscountByContract;
    }

    private static List<ARC_PromotionDiscount__c> filterByActiveDiscounts(List<ARC_PromotionDiscount__c> discounts){
        List<ARC_PromotionDiscount__c> activeDiscounts = new List<ARC_PromotionDiscount__c>();
        for(ARC_PromotionDiscount__c discount : discounts){
            if(discount.ARC_Status__c == 'Activated' && !isApplyOverAppFee(discount)){
                activeDiscounts.add(discount);
            }
        }
        return activeDiscounts;
    }

    private static List<ARC_PromotionDiscount__c> filterByActiveAppFeeDiscounts(List<ARC_PromotionDiscount__c> discounts){
        List<ARC_PromotionDiscount__c> activeAppFeeDiscounts = new List<ARC_PromotionDiscount__c>();
        for(ARC_PromotionDiscount__c discount : discounts){
            if(discount.ARC_Status__c == 'Activated' && isApplyOverAppFee(discount)){
                activeAppFeeDiscounts.add(discount);
            }
        }
        return activeAppFeeDiscounts;
    }

    private static List<ARC_PromotionDiscount__c> filterByInactiveDiscounts(List<ARC_PromotionDiscount__c> discounts){
        List<ARC_PromotionDiscount__c> inactiveDiscounts = new List<ARC_PromotionDiscount__c>();
        for(ARC_PromotionDiscount__c discount : discounts){
            if(discount.ARC_Status__c != 'Activated'){
                inactiveDiscounts.add(discount);
            }
        }
        return inactiveDiscounts;
    }

    public static Map<Id, List<vlocity_ins__ContractLineItem__c>> mapPlansByContractId(List<vlocity_ins__ContractLineItem__c> plans){
        Map<Id, List<vlocity_ins__ContractLineItem__c>> plansByContractId = new Map<Id, List<vlocity_ins__ContractLineItem__c>>();
        for(vlocity_ins__ContractLineItem__c plan : plans){
            if(plansByContractId.containsKey(plan.vlocity_ins__ContractId__c)){
                plansByContractId.get(plan.vlocity_ins__ContractId__c).add(plan);
            }else{
                plansByContractId.put(plan.vlocity_ins__ContractId__c, new List<vlocity_ins__ContractLineItem__c>{plan});
            }
        }
        return plansByContractId;
    }

    //Update the recurring orders
    public static void updateOrderPrice(Set<Id> contractId){
        //Comment this since its not used
        //List<Contract> contracts = [SELECT ARC_AppFeeOrder__c FROM Contract WHERE Id IN :contractId];

        List<ChargentOrders__ChargentOrder__c> orders = [
            SELECT Id, ARC_Contract__c, ARC_Contract__r.ARC_TotalPrice__c, Current_Recurring_Order__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ARC_Contract__c IN :contractId AND Current_Recurring_Order__c = true  
        ];
        for(ChargentOrders__ChargentOrder__c order : orders){
            order.ChargentOrders__Subtotal__c = order.ARC_Contract__r.ARC_TotalPrice__c;
            order.ChargentOrders__Charge_Amount__c = order.ARC_Contract__r.ARC_TotalPrice__c;
            System.debug('order.ARC_Contract__r.ARC_TotalPrice__c  : '+order.ARC_Contract__r.ARC_TotalPrice__c );
            System.debug('order.ChargentOrders__Subtotal__c  : '+order.ChargentOrders__Subtotal__c );
            System.debug('order.ChargentOrders__Charge_Amount__c  : '+order.ChargentOrders__Charge_Amount__c );
        }
        update orders;
    }

    public static List<ChargentOrders__ChargentOrder__c> getAppFeeOrders(Set<Id> contractIds){
        List<Contract> contracts = [SELECT ARC_AppFeeOrder__c FROM Contract WHERE Id IN :contractIds];
        Set<Id> appFeeOrderIds = new Set<Id>();
        for(Contract contract : contracts){
            appFeeOrderIds.add(contract.ARC_AppFeeOrder__c);
        }

        List<ChargentOrders__ChargentOrder__c> orders = [
            SELECT Id, ARC_Contract__c, ARC_Contract__r.ARC_TotalPrice__c, Current_Recurring_Order__c, ChargentOrders__Charge_Amount__c, ChargentOrders__Subtotal__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id IN :appFeeOrderIds  
        ];
        return orders;
    }

    public static void applyAppFeeDiscounts(Set<Id> contractIds, List<ARC_PromotionDiscount__c> discounts) {
        //This query is necessary to get the price with discount calculated
        List<ARC_PromotionDiscount__c> discountsPriceUpdated = [SELECT Id, ARC_Contract__r.ARC_AppFeeOrder__c, ARC_ApplyOver__c, ARC_PromoCode__r.ARC_ApplyOver__c,ARC_PriceWithDiscount__c, ARC_Status__c   FROM ARC_PromotionDiscount__c WHERE Id IN: discounts];
        List<ChargentOrders__ChargentOrder__c> appFeeOrders = getAppFeeOrders(contractIds);
        List<ChargentOrders__ChargentOrder__c> appFeeOrdersToUpdate = new List<ChargentOrders__ChargentOrder__c>();

        //Executed for each app fee && for each discount
        for (ChargentOrders__ChargentOrder__c order : appFeeOrders) {
            for (ARC_PromotionDiscount__c discount : discountsPriceUpdated) {
                if (discount.ARC_Contract__r.ARC_AppFeeOrder__c == order.Id && isApplyOverAppFee(discount) && discount.ARC_Status__c == 'Activated') {
                    order.ChargentOrders__Subtotal__c = discount.ARC_PriceWithDiscount__c;
                    order.ChargentOrders__Charge_Amount__c = discount.ARC_PriceWithDiscount__c;
                    if(!appFeeOrdersToUpdate.contains(order))appFeeOrdersToUpdate.add(order);
                }
            }
        }
        //Update the app fee orders
        update appFeeOrdersToUpdate;
    }

    /*******************************************************************
    * @MethodName         :   programChangeAndSpinOffApplyDiscounts
    * @Description        :   Use in Contract_PC_Spin_Off_Apply_Healthy_Discount_and_Renewal_Discount flow to call applyRenewalDiscountFromPcOrSpinOff and cloneHealthyAndTemporaryDiscounts methods
    ********************************************************************/
    public static void programChangeAndSpinOffApplyDiscounts(Set<Id> contractIds){
        applyRenewalDiscountFromPcOrSpinOff(contractIds);
        cloneHealthyDiscounts(contractIds);
        cloneTemporaryDiscounts(contractIds);
    }

    /*******************************************************************
    * @MethodName         :   applyRenewalDiscountFromPcOrSpinOff
    * @Description        :   Calculate Min Since Date of all Participants Contract and insert Renewal Discount to the contract
    ********************************************************************/
    public static void applyRenewalDiscountFromPcOrSpinOff(Set<Id> contractIds) {

        List<ARC_ContractParticipant__c> participantsByContractId = getContractParticipants(contractIds, false);
        Map<Decimal,Id> renewalDiscountCodeMap = getAndMapRenewalDiscountCodes();

        Id renewalDiscountPromotionRTId =[SELECT Id FROM RecordType WHERE DeveloperName = 'Renewal_Discount' AND SobjectType = 'ARC_PromotionDiscount__c'][0].Id;

        // Map to catch oldest participant from current contract
        Map<Id, Date> oldestSinceDateByContract = new Map<Id, Date>();
        for (ARC_ContractParticipant__c participant : participantsByContractId) {
            if (participant.ARC_PersonAccount__r != null && participant.ARC_PersonAccount__r.ARC_ContinuousMembershipStartDate__c != null) {
                Date sinceDate = participant.ARC_PersonAccount__r.ARC_ContinuousMembershipStartDate__c;
                
                if (!oldestSinceDateByContract.containsKey(participant.ARC_Contract__c) || 
                    oldestSinceDateByContract.get(participant.ARC_Contract__c) > sinceDate) {
                    oldestSinceDateByContract.put(participant.ARC_Contract__c, sinceDate);
                }
            }
        }
        List<ARC_PromotionDiscount__c> renewalDiscountsToInsertList = new List<ARC_PromotionDiscount__c>();
        
        for (Id contractId : oldestSinceDateByContract.keySet()) {
            Date oldestSinceDate = oldestSinceDateByContract.get(contractId);
            Integer yearsPassed = Date.today().year() - oldestSinceDate.year();

            if (Date.today().addYears(-yearsPassed) < oldestSinceDate) {
                yearsPassed -= 1;
            }
            if (yearsPassed <= 0) {
                continue;
            }

            Integer promotionCodeNumber = yearsPassed >= 5 ? 5 : yearsPassed;
            renewalDiscountsToInsertList.add(assignDiscountToContract(contractId, renewalDiscountCodeMap.get(promotionCodeNumber), renewalDiscountPromotionRTId));
        }

        if (!renewalDiscountsToInsertList.isEmpty()) insert renewalDiscountsToInsertList;
    }
    
    /*******************************************************************
    * @MethodName         :   cloneTemporaryDiscounts
    * @Description        :   Clone Temporary Discounts from expire Contract to current Contract
    ********************************************************************/
    public static void cloneTemporaryDiscounts(Set<Id> contractIds){

        Map<Id,Contract> newContracts = new Map<Id,Contract> ([SELECT Id, vlocity_ins__ExpiredContractId__c, ARC_ContractReason__c FROM Contract WHERE Id IN :contractIds]);
        Set<Id> expiredContractIds = new Set<Id>();
        Map<Id,Id> oldNewContractIds = new Map<Id,Id>();

        for (Contract contract : newContracts.values()) {
            expiredContractIds.add(contract.vlocity_ins__ExpiredContractId__c);
            oldNewContractIds.put(contract.vlocity_ins__ExpiredContractId__c, contract.Id);
        }    

        List<ARC_PromotionDiscount__c> temporaryDiscountsToClone = [SELECT Id, Name, ARC_StartDate__c, ARC_Description__c, ARC_EndDate__c,ARC_Status__c, ARC_PromoCode__c, RecordTypeId, ARC_Contract__c, 
                                                            RecordType.DeveloperName,ARC_ApplyOver__c, ARC_DiscountedAmount__c, ARC_DiscountRate__c, ARC_NumberOfTimesCanBeUsed__c, ARC_TimesUsed__c 
                                                            FROM ARC_PromotionDiscount__c  
                                                            WHERE (ARC_Status__c = 'Activated' OR ARC_Status__c = 'Pending' OR ARC_Status__c = 'Awaiting Activation')
                                                            AND RecordType.DeveloperName = 'Temporary_Discount'
                                                            AND ARC_Contract__c IN :expiredContractIds];

        if (temporaryDiscountsToClone.isEmpty()) return;
 
        Map<Id, ARC_PromotionDiscount__c> oldNewDiscounts = new Map<Id, ARC_PromotionDiscount__c>();

        // Clone ARC_PromotionDiscount__c, map old with new
        for (ARC_PromotionDiscount__c discount : temporaryDiscountsToClone){
            Id newContractId = oldNewContractIds.get(discount.ARC_Contract__c);

            if (!newContracts.get(newContractId).ARC_ContractReason__c.contains('Spin Off')){
                ARC_PromotionDiscount__c clonedDiscount = new ARC_PromotionDiscount__c(
                        Name = discount.Name,
                        ARC_StartDate__c = discount.ARC_StartDate__c,
                        ARC_Description__c = discount.ARC_Description__c,
                        ARC_EndDate__c = discount.ARC_EndDate__c,
                        ARC_Status__c = discount.ARC_Status__c, 
                        ARC_PromoCode__c = discount.ARC_PromoCode__c,
                        RecordTypeId = discount.RecordTypeId,
                        ARC_Contract__c = newContractId,
                        ARC_ApplyOver__c = discount.ARC_ApplyOver__c,
                        ARC_DiscountedAmount__c = discount.ARC_DiscountedAmount__c,
                        ARC_DiscountRate__c = discount.ARC_DiscountRate__c,
                        ARC_NumberOfTimesCanBeUsed__c = discount.ARC_NumberOfTimesCanBeUsed__c,
                        ARC_TimesUsed__c = discount.ARC_TimesUsed__c,
                        ARC_Discount__c = discount.Id
                    );
                    oldNewDiscounts.put(discount.Id, clonedDiscount);
            }     
        }

        if (!oldNewDiscounts.isEmpty()) insert oldNewDiscounts.values();

        System.debug(oldNewDiscounts.values());
    }

    /*******************************************************************
    * @MethodName         :   cloneHealthyDiscounts
    * @Description        :   Clone Healthy Discount and Healthy Discount Accounts from expire Contract to current Contract
    ********************************************************************/
    public static void cloneHealthyDiscounts(Set<Id> contractIds){

        Map<Id,Contract> newContracts = new Map<Id,Contract> ([SELECT Id, vlocity_ins__ExpiredContractId__c, ARC_ContractReason__c,ARC_MedicalPlan__c, ARC_MedicalPlan__r.Name FROM Contract WHERE Id IN :contractIds]);
        Set<Id> expiredContractIds = new Set<Id>();
        Map<Id,Id> oldNewContractIds = new Map<Id,Id>();
        Set<Id> exisitingAccountIds = new Set<Id>();

        // Check if new Contract has Healthy Discounts 
        List<ARC_PromotionDiscount__c> newContractHasHdList = [SELECT Id, ARC_Discount__c FROM ARC_PromotionDiscount__c WHERE ARC_Contract__c IN :contractIds AND (ARC_Status__c = 'Activated' OR ARC_Status__c = 'Awaiting Activation')];
        Set<Id> newContractHasHd = new Set<Id>();

        for (Contract contract : newContracts.values()) {
            //Exclude WeShareAcces
            if(contract.ARC_MedicalPlan__c != null && !contract.ARC_MedicalPlan__r.Name.contains('Access')){
                expiredContractIds.add(contract.vlocity_ins__ExpiredContractId__c);
                oldNewContractIds.put(contract.vlocity_ins__ExpiredContractId__c, contract.Id);
            }
        }    

        List<ARC_PromotionDiscount__c> discountsToClone = [SELECT Id, Name, ARC_StartDate__c, ARC_Description__c, ARC_EndDate__c,ARC_Status__c, ARC_PromoCode__c, RecordTypeId, ARC_Contract__c, 
                                                            RecordType.DeveloperName,ARC_ApplyOver__c, ARC_DiscountedAmount__c, ARC_DiscountRate__c, ARC_NumberOfTimesCanBeUsed__c, ARC_TimesUsed__c, ARC_Discount__c 
                                                            FROM ARC_PromotionDiscount__c  
                                                            WHERE (ARC_Status__c = 'Activated' OR ARC_Status__c = 'Pending' OR ARC_Status__c = 'Awaiting Activation')
                                                            AND RecordType.DeveloperName = 'Healthy_Discount'
                                                            AND ARC_Contract__c IN :expiredContractIds];

        // If new Contract has Healthy Discounts and is in discountsToClone List, we will remove it from discountsToClone to avoid duplicate clone
        if (!newContractHasHdList.isEmpty()) {
            
            for (ARC_PromotionDiscount__c HdId : newContractHasHdList) {
                if (HdId.ARC_Discount__c != null) {
                    newContractHasHd.add(HdId.ARC_Discount__c);
                }
            }


            for (Integer i = discountsToClone.size() - 1; i >= 0; i--) {
                if (newContractHasHd.contains(discountsToClone[i].Id)) {
                    discountsToClone.remove(i);
                }
            }

        }
        

        if (discountsToClone.isEmpty()) return;
        
        Map<Id, List<ARC_PromotionDiscount__c>> contractDiscounts = new Map<Id, List<ARC_PromotionDiscount__c>>();

        List<ARC_ContractParticipant__c> currentContractParticipants = getContractParticipants(contractIds, true);

        Map<Id,List<Account>> contractAccounts = mapContractAccounts(currentContractParticipants);

        List<ARC_HealthyDiscountAccount__c> discountAccountsToClone = getDiscountAccounts(currentContractParticipants, discountsToClone);
 
        Map<Id, ARC_PromotionDiscount__c> oldNewDiscounts = new Map<Id, ARC_PromotionDiscount__c>();
        Map<Id, ARC_HealthyDiscountAccount__c> oldNewDiscountAccounts = new Map<Id, ARC_HealthyDiscountAccount__c>();
        List<ARC_HealthyDiscountAccount__c> newDiscountAccounts = new List<ARC_HealthyDiscountAccount__c>();
        
        // Clone ARC_PromotionDiscount__c, map old with new
        for (ARC_PromotionDiscount__c discount : discountsToClone){
            Id newContractId = oldNewContractIds.get(discount.ARC_Contract__c);
            if(contractAccounts.containsKey(newContractId)){
                ARC_PromotionDiscount__c clonedDiscount = new ARC_PromotionDiscount__c(
                    Name = discount.Name,
                    ARC_StartDate__c = discount.ARC_StartDate__c,
                    ARC_Description__c = discount.ARC_Description__c,
                    ARC_EndDate__c = discount.ARC_EndDate__c,
                    ARC_Status__c = discount.ARC_Status__c, 
                    ARC_PromoCode__c = discount.ARC_PromoCode__c,
                    RecordTypeId = discount.RecordTypeId,
                    ARC_Discount__c = discount.Id,
                    ARC_Contract__c = newContractId
                );
                oldNewDiscounts.put(discount.Id, clonedDiscount);
            }     
        }

        if (!oldNewDiscounts.isEmpty()) insert oldNewDiscounts.values();

        System.debug(oldNewDiscounts.values());

        // Clone ARC_HealthyDiscountAccount__c, map old with new
        for (ARC_HealthyDiscountAccount__c discountAccount : discountAccountsToClone){
            exisitingAccountIds.add(discountAccount.ARC_Account__c);
            ARC_HealthyDiscountAccount__c clonedDiscountAccount = new ARC_HealthyDiscountAccount__c();
            clonedDiscountAccount.Name = discountAccount.Name;
            clonedDiscountAccount.ARC_Status__c = discountAccount.ARC_Status__c;
            clonedDiscountAccount.ARC_DecisionDate__c = discountAccount.ARC_DecisionDate__c;
            clonedDiscountAccount.ARC_Account__c = discountAccount.ARC_Account__c;
            clonedDiscountAccount.ARC_Discount__c = oldNewDiscounts.get(discountAccount.ARC_Discount__c).Id;
            
            newDiscountAccounts.add(clonedDiscountAccount);
        }
        
        // If there is a ex Child with a Feature Primary Relationship, we update the new discount to Pending
        List<ARC_PromotionDiscount__c> discountStatusToUpdateList = new List<ARC_PromotionDiscount__c>();

        // Create new discount accounts (for new accounts);
        for (Id contractId : contractAccounts.keySet()){
            for (ARC_PromotionDiscount__c discount : oldNewDiscounts.values()) {
                if (discount.ARC_Contract__c == contractId) {
                    for(Account account : contractAccounts.get(contractId)){
                        if(!exisitingAccountIds.contains(account.Id)){
                            if (account.ARC_DependentRelationship__c == 'Future Primary' || account.ARC_DependentRelationship__c == 'Child') {
                                ARC_PromotionDiscount__c discountRecord = new ARC_PromotionDiscount__c(
                                    Id = discount.Id,
                                    ARC_Status__c = 'Pending'
                                );
                                discountStatusToUpdateList.add(discountRecord);
                            } 
                            // Create new discount account
                            ARC_HealthyDiscountAccount__c newDiscountAccount = new ARC_HealthyDiscountAccount__c();
                            newDiscountAccount.Name = account.Name;
                            if (discount.ARC_Status__c == 'Activated' || discount.ARC_Status__c == 'Awaiting Activation') {
                                newDiscountAccount.ARC_Status__c = 'Approved';
                            } else {
                                newDiscountAccount.ARC_Status__c = 'Pending';
                            }
                            newDiscountAccount.ARC_Account__c = account.Id;
                            newDiscountAccount.ARC_Discount__c = discount.Id;
                            newDiscountAccounts.add(newDiscountAccount);

                        }
                    }
                }   
            }
        }

        if (!discountStatusToUpdateList.isEmpty()) {
            update discountStatusToUpdateList;
        }
        

      

        if (!newDiscountAccounts.isEmpty()) insert newDiscountAccounts;
   
    }


    // Helper method to get and map discount codes
    public static Map<Decimal, Id> getAndMapRenewalDiscountCodes(){

        List<ARC_PromotionCode__c> renewalDiscountDiscountCodes = [SELECT Id, ARC_RenewalDiscountNumber__c FROM ARC_PromotionCode__c WHERE RecordType.DeveloperName = 'Renewal_Discount' AND ARC_Active__c = true];

        Map<Decimal, Id> renewalDiscountCodeMap = new Map<Decimal, Id>();
        
        for (ARC_PromotionCode__c discountCode : renewalDiscountDiscountCodes) {
            renewalDiscountCodeMap.put(discountCode.ARC_RenewalDiscountNumber__c, discountCode.Id);
        }

        return renewalDiscountCodeMap;
    }

    // Helper method to assign a Renewal Disocunt to a Contract
    public static ARC_PromotionDiscount__c assignDiscountToContract (Id contractId, Id promeCode, Id RecordTypeId){

        ARC_PromotionDiscount__c discount = new  ARC_PromotionDiscount__c(
            //Name = 'Renewal Discount',
            ARC_Status__c = 'Activated',
            ARC_Contract__c = contractId,
            ARC_PromoCode__c = promeCode,
            RecordTypeId = RecordTypeId,
            ARC_StartDate__c = Date.today()
        );

        return discount;
    }
    
    // Helper method to get expire contract discountAccounts
    public static List<ARC_HealthyDiscountAccount__c> getDiscountAccounts(List<ARC_ContractParticipant__c> participants, List<ARC_PromotionDiscount__c> discounts){
        Set<Id> accountIds = new Set<Id>();
        for(ARC_ContractParticipant__c participant : participants){
            accountIds.add(participant.ARC_PersonAccount__c);
        }

        return [SELECT Id, Name, ARC_Status__c, ARC_DecisionDate__c, ARC_Account__c, ARC_Discount__c  FROM ARC_HealthyDiscountAccount__c WHERE ARC_Discount__c IN :discounts AND ARC_Account__c IN :accountIds];
    }

    // Helper method to retrieve contract participants with filtering on Dependent Relationship != Child if removeChild = true
    public static List<ARC_ContractParticipant__c> getContractParticipants(Set<Id> contractId, Boolean removeChild) {
        String query = 'SELECT Id, Name, ARC_PersonAccount__c, ARC_PersonAccount__r.Name, ARC_PersonAccount__r.ARC_ContinuousMembershipStartDate__c, ARC_PersonAccount__r.ARC_DependentRelationship__c, ARC_Contract__c FROM ARC_ContractParticipant__c WHERE ARC_Contract__c IN :contractId';
        
        if (removeChild) {
            query += ' AND ARC_PersonAccount__r.ARC_DependentRelationship__c != \'Child\'';
        }

        return Database.query(query);
    }

    // Helper method to map contract with person accounts
    public static Map<Id,List<Account>> mapContractAccounts(List<ARC_ContractParticipant__c> participantsList) {
  
        Map<Id,List<Account>> contractAccounts = new Map<Id,List<Account>>();

        for (ARC_ContractParticipant__c cp : participantsList) {
            Account relatedAccount = new Account(
                Id = cp.ARC_PersonAccount__c,
                Name = cp.ARC_PersonAccount__r.Name,
                ARC_DependentRelationship__c = cp.ARC_PersonAccount__r.ARC_DependentRelationship__c
            );

            if (contractAccounts.containsKey(cp.ARC_Contract__c)) {
                contractAccounts.get(cp.ARC_Contract__c).add(relatedAccount);
            } else {
                contractAccounts.put(cp.ARC_Contract__c, new List<Account>{relatedAccount});
            }
        }

        return contractAccounts;
    }

    public static Boolean isApplyOverAppFee(ARC_PromotionDiscount__c discount){
        return discount.ARC_ApplyOver__c == 'App Fee' || discount.ARC_PromoCode__r.ARC_ApplyOver__c == 'App Fee' || discount.ARC_ApplyOver__c == 'Change Fee' || discount.ARC_PromoCode__r.ARC_ApplyOver__c == 'Change Fee';
    }

    private static Set<Id> getContractsWithAgeUp(Set<Id> contractIds){
        Set<Id> contractIdsWithAgeUp = new Set<Id>();
        List<Contract> contracts = [SELECT Id, (SELECT Id FROM Ages_Ups__r) FROM Contract WHERE Id IN :contractIds];
        for(Contract contract : contracts){
            if(contract.Ages_Ups__r.size() > 0){
                contractIdsWithAgeUp.add(contract.Id);
            }
        }
        return contractIdsWithAgeUp;
    }
  
    @InvocableMethod(label='Discounts Manager' description='Description' category='Discounts')
    public static void invocableDiscount(List<DiscountRequest> requests){
        Set<Id> contractIds = new Set<Id>();
        Map<String, List<Id>> contractIdsByMethod = new Map<String, List<Id>>();
        for(DiscountRequest request : requests){
            if(request.contractId != null){
                contractIds.add(request.contractId);
                if(contractIdsByMethod.containsKey(request.methodName)){
                    contractIdsByMethod.get(request.methodName).add(request.contractId);
                }else{
                    contractIdsByMethod.put(request.methodName, new List<Id>{request.contractId});
                }
            }
            if(request.contractIds != null){
                contractIds.addAll(request.contractIds);
                if(contractIdsByMethod.containsKey(request.methodName)){
                    contractIdsByMethod.get(request.methodName).addAll(request.contractIds);
                }else{
                    contractIdsByMethod.put(request.methodName, request.contractIds);
                }
            }
        }
        if(contractIdsByMethod.containsKey('applyDiscounts')){
            applyDiscounts(new Set<Id>(contractIdsByMethod.get('applyDiscounts')), true);
        }
        if(contractIdsByMethod.containsKey('populateDiscounts')){
            populateDiscounts(new Set<Id>(contractIdsByMethod.get('populateDiscounts')));
        }
        if(contractIdsByMethod.containsKey('programChangeAndSpinOffApplyDiscounts')){
            programChangeAndSpinOffApplyDiscounts(new Set<Id>(contractIdsByMethod.get('programChangeAndSpinOffApplyDiscounts')));
        }
        if(contractIdsByMethod.containsKey('cloneTemporaryDiscounts')){
            cloneTemporaryDiscounts(new Set<Id>(contractIdsByMethod.get('cloneTemporaryDiscounts')));
        }
        if(contractIdsByMethod.containsKey('cloneHealthyDiscounts')){
            cloneHealthyDiscounts(new Set<Id>(contractIdsByMethod.get('cloneHealthyDiscounts')));
        }
        if(contractIdsByMethod.containsKey('applyRenewalDiscountFromPcOrSpinOff')){
            applyRenewalDiscountFromPcOrSpinOff(new Set<Id>(contractIdsByMethod.get('applyRenewalDiscountFromPcOrSpinOff')));
        }
    }

    public class DiscountRequest {
        @InvocableVariable(label='Method' description='Method to execute' required=true)
        public String methodName;
        // valid values: applyDiscounts, populateDiscounts

        @InvocableVariable(label='Contract Id' description='Description')
        public Id contractId;

        @InvocableVariable(label='Contract Id List' description='Description')
        public List<Id> contractIds;
    }

}