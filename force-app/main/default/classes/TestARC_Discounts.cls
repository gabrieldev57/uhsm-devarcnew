public with sharing class TestARC_Discounts {
    
 public static void applyDiscounts(Set<Id> contractIds){
//         List<vlocity_ins__ContractLineItem__c> plans = getPlans(contractIds);
//         List<ARC_PromotionDiscount__c> allRelatedDiscounts = getDiscountsByContractIds(contractIds);
//         List<ARC_PromotionDiscount__c> activeDiscounts = filterByActiveDiscounts(allRelatedDiscounts);
//         List<ARC_PromotionDiscount__c> inactiveDiscounts = filterByInactiveDiscounts(allRelatedDiscounts);
//         plans = getPlansWithDiscounts(plans, activeDiscounts);
//         update plans;
//         populateDiscounts(contractIds);
//         updateOrderPrice(contractIds);
}

//     //ARC_Discounts.populateDiscounts(new Set<Id>{aDGVA0000001JS14AM});
//     public static void populateDiscounts(Set<Id> contractIds){
//         System.debug('populateDiscounts, contractIds: ' + contractIds);
//         Map<Id, ARC_PromotionDiscount__c> relatedDiscounts = new Map<Id,ARC_PromotionDiscount__c>(getDiscountsByContractIds(contractIds));
//         Map<Id, ARC_PromotionDiscount__c> activeDiscounts = new Map<Id,ARC_PromotionDiscount__c>(getActiveDiscounts(contractIds));
//         List<ARC_PromotionDiscount__c> discountsToUpdate = new List<ARC_PromotionDiscount__c>();

//         List<vlocity_ins__ContractLineItem__c> plans = getPlans(contractIds);

//         Map<Id, Map<Id, ARC_PromotionDiscount__c>> activeDiscountsByContractId = mapDiscountsByContractId(activeDiscounts);
//         Map<Id, Map<Id, ARC_PromotionDiscount__c>> discountsByContractId = mapDiscountsByContractId(relatedDiscounts);

//         Map<Id, List<vlocity_ins__ContractLineItem__c>> plansByContractId = mapPlansByContractId(plans);

//         for (Id contractId : discountsByContractId.keySet()) {
//             for(Id discountId : discountsByContractId.get(contractId).keySet()){
//                 ARC_PromotionDiscount__c discount = discountsByContractId.get(contractId).get(discountId);
//                 Map<Id, ARC_PromotionDiscount__c> discountsWithCurrentDiscount = new Map<Id, ARC_PromotionDiscount__c>();
//                 Map<Id, ARC_PromotionDiscount__c> discountsWithoutCurrentDiscount = new Map<Id, ARC_PromotionDiscount__c>();
//                 if (activeDiscountsByContractId.get(contractId) == null) {
//                     activeDiscountsByContractId.put(contractId, new Map<Id, ARC_PromotionDiscount__c>());
//                 }
//                 discountsWithCurrentDiscount.putAll(activeDiscountsByContractId.get(contractId));
//                 discountsWithoutCurrentDiscount.putAll(activeDiscountsByContractId.get(contractId));
//                 if (!discountsWithCurrentDiscount.containsKey(discountId)) {
//                     discountsWithCurrentDiscount.put(discountId, discount);
//                 }
//                 if (discountsWithoutCurrentDiscount.containsKey(discountId)) {
//                     discountsWithoutCurrentDiscount.remove(discountId);
//                 }
//                 discount.ARC_PriceWithDiscount__c = calculateTotalPrice(getPlansWithDiscounts(plansByContractId.get(contractId), discountsWithCurrentDiscount.values()));
//                 discount.ARC_PriceWithoutDiscount__c = calculateTotalPrice(getPlansWithDiscounts(plansByContractId.get(contractId), discountsWithoutCurrentDiscount.values()));

//                 discountsToUpdate.add(discount);

//             }

//         }
        
//         update discountsToUpdate;
//     }

//     public static List<vlocity_ins__ContractLineItem__c> getPlansWithDiscounts(List<vlocity_ins__ContractLineItem__c> plans, List<ARC_PromotionDiscount__c> discounts){
//         if (plans == null) {
//             plans = new List<vlocity_ins__ContractLineItem__c>();
//         }
//         Map<Id, Decimal> totalPercentageDiscountByPlan = percentageDiscountByPlan(discounts, plans);
//         Map<Id, Decimal> totalCurrencyDiscountByPlan = currencyDiscountByPlan(discounts, plans);

//         for(vlocity_ins__ContractLineItem__c plan : plans){
//             Decimal totalPercentageDiscount = totalPercentageDiscountByPlan.get(plan.Id) != null ? totalPercentageDiscountByPlan.get(plan.Id) : 1;
//             Decimal totalCurrencyDiscount = totalCurrencyDiscountByPlan.get(plan.Id) != null ? totalCurrencyDiscountByPlan.get(plan.Id) : 0;
//             //apply the discounts

//             plan.vlocity_ins__UnitPrice__c = ((plan.ARC_OriginalPrice__c - totalCurrencyDiscount) * totalPercentageDiscount) + getFees(plan);
//         }

//         return plans;
//     }

//     public static Decimal getFees(vlocity_ins__ContractLineItem__c plan){
//         Decimal smokerFee = plan.ARC_SmokerFee__c != null ? plan.ARC_SmokerFee__c : 0;
//         Decimal extraDependentFee = plan.ARC_ExtraDependentFee__c != null ? plan.ARC_ExtraDependentFee__c : 0;
//         return smokerFee + extraDependentFee;
//     }

//     public static List<vlocity_ins__ContractLineItem__c> getPlans(Set<Id> contractIds){
//         return [
//             SELECT Id, 
//                 vlocity_ins__UnitPrice__c, 
//                 ARC_OriginalPrice__c,
//                 ARC_SmokerFee__c, 
//                 ARC_ExtraDependentFee__c,
//                 vlocity_ins__ContractId__c,
//                 vlocity_ins__ProductType__c
//             FROM vlocity_ins__ContractLineItem__c 
//             WHERE 
//                 vlocity_ins__ContractId__c IN :contractIds AND 
//                 vlocity_ins__RecordTypeName__c = 'Product' AND
//                 vlocity_ins__ProductType__c IN ('Medical', 'Ancillary')
//         ];
//     }

//     public static List<ARC_PromotionDiscount__c> getActiveDiscounts(Set<Id> contractIds){
//         return [
//             SELECT Id, 
//                 ARC_ApplyOver__c, 
//                 ARC_DiscountRate__c, 
//                 ARC_PromoCode__r.ARC_DiscountRate__c, 
//                 ARC_DiscountedAmount__c,
//                 ARC_PromoCode__r.ARC_DiscountedAmount__c, 
//                 ARC_Status__c,
//                 ARC_PromoCode__r.ARC_ApplyOver__c,
//                 ARC_Contract__c
//             FROM ARC_PromotionDiscount__c 
//             WHERE ARC_Contract__c IN :contractIds AND ARC_Status__c = 'Activated'
//         ];
//     }
    
//     public static List<ARC_PromotionDiscount__c> getDiscountsByIds(Set<Id> discountIds){
//         return [
//             SELECT Id, 
//                 ARC_ApplyOver__c, 
//                 ARC_DiscountRate__c, 
//                 ARC_PromoCode__r.ARC_DiscountRate__c, 
//                 ARC_DiscountedAmount__c,
//                 ARC_PromoCode__r.ARC_DiscountedAmount__c, 
//                 ARC_Status__c ,
//                 ARC_Contract__c,
//                 ARC_PromoCode__r.ARC_ApplyOver__c
//             FROM ARC_PromotionDiscount__c 
//             WHERE Id IN :discountIds
//         ];
//     }

//     public static List<ARC_PromotionDiscount__c> getDiscountsByContractIds(Set<Id> contractIds){
//         return [
//             SELECT Id, 
//                 ARC_ApplyOver__c, 
//                 ARC_DiscountRate__c, 
//                 ARC_PromoCode__r.ARC_DiscountRate__c, 
//                 ARC_DiscountedAmount__c,
//                 ARC_PromoCode__r.ARC_DiscountedAmount__c, 
//                 ARC_Status__c,
//                 ARC_PromoCode__r.ARC_ApplyOver__c,
//                 ARC_Contract__c
//             FROM ARC_PromotionDiscount__c 
//             WHERE ARC_Contract__c IN :contractIds
//         ];
//     }

//     private static boolean isDiscountApplicable(ARC_PromotionDiscount__c discount, vlocity_ins__ContractLineItem__c plan){
//         String applyOver = discount.ARC_ApplyOver__c != null ? discount.ARC_ApplyOver__c : discount.ARC_PromoCode__r.ARC_ApplyOver__c;
//         Boolean isDiscountApplicable = (applyOver == 'Medical' && plan.vlocity_ins__ProductType__c == 'Medical') ||
//             (applyOver == 'Ancillary' && plan.vlocity_ins__ProductType__c == 'Ancillary') ||
//             (applyOver == 'All');
//         return isDiscountApplicable;
//     }

//     private static Map<Id, Map<Id, ARC_PromotionDiscount__c>> mapDiscountsByContractId(Map<Id, ARC_PromotionDiscount__c> discounts){
//         Map<Id, Map<Id, ARC_PromotionDiscount__c>> discountsByContractId = new Map<Id, Map<Id, ARC_PromotionDiscount__c>>();
//         for(Id discountId : discounts.keySet()){
//             ARC_PromotionDiscount__c discount = discounts.get(discountId);
//             if(discountsByContractId.containsKey(discount.ARC_Contract__c)){
//                 discountsByContractId.get(discount.ARC_Contract__c).put(discountId, discount);
//             }else{
//                 discountsByContractId.put(discount.ARC_Contract__c, new Map<Id, ARC_PromotionDiscount__c>{discount.Id => discount});
//             }
//         }
//         return discountsByContractId;
//     }

//     private static Decimal calculateTotalPrice(List<vlocity_ins__ContractLineItem__c> plans) {
//         Decimal totalPrice = 0;
//         for (vlocity_ins__ContractLineItem__c plan : plans) {
//             totalPrice += plan.vlocity_ins__UnitPrice__c;
//         }
//         return totalPrice;
//     }

//     private static Map<Id,Decimal> percentageDiscountByPlan(List<ARC_PromotionDiscount__c> discounts, List<vlocity_ins__ContractLineItem__c> plans){
//         Map<Id,Decimal> totalPercentageDiscountByPlan = new Map<Id,Decimal>();
        
//         for (vlocity_ins__ContractLineItem__c plan : plans) {
//             Decimal totalPercentageDiscount = 1; //starts with 100% of the original price, no discount
//             if (discounts == null) {
//                 continue;
//             }
//             for(ARC_PromotionDiscount__c discount : discounts){
//                 if (plan.vlocity_ins__ContractId__c == discount.ARC_Contract__c) {
//                     if(isDiscountApplicable(discount, plan) == false){
//                         continue;
//                     }
//                     Double discountPercent = discount.ARC_DiscountRate__c != null ? discount.ARC_DiscountRate__c : discount.ARC_PromoCode__r.ARC_DiscountRate__c;
//                     if(discountPercent != null){
//                         totalPercentageDiscount = totalPercentageDiscount * (1 - discountPercent/100);
//                     }
//                 }
//             }
//             totalPercentageDiscountByPlan.put(plan.Id, totalPercentageDiscount);
//         }

//         return totalPercentageDiscountByPlan;
//     }

//     private static Map<Id,Decimal> currencyDiscountByPlan(List<ARC_PromotionDiscount__c> discounts, List<vlocity_ins__ContractLineItem__c> plans){
//         Map<Id,Decimal> totalCurrencyDiscountByPlan = new Map<Id,Decimal>();

//         for (vlocity_ins__ContractLineItem__c plan : plans) {
//             Decimal totalCurrencyDiscount = 0; //starts with 0 discount
//             if (discounts == null) {
//                 continue;
//             }
//             for(ARC_PromotionDiscount__c discount : discounts){
//                 if (plan.vlocity_ins__ContractId__c == discount.ARC_Contract__c) {
//                     if(isDiscountApplicable(discount, plan) == false){
//                         continue;
//                     }
//                     if(discount.ARC_DiscountedAmount__c != null){
//                         totalCurrencyDiscount += discount.ARC_DiscountedAmount__c;
//                     }
//                 }
//             }
//             totalCurrencyDiscountByPlan.put(plan.Id, totalCurrencyDiscount);
//         }

//         return totalCurrencyDiscountByPlan;
//     }

//     private static List<ARC_PromotionDiscount__c> filterByActiveDiscounts(List<ARC_PromotionDiscount__c> discounts){
//         List<ARC_PromotionDiscount__c> activeDiscounts = new List<ARC_PromotionDiscount__c>();
//         for(ARC_PromotionDiscount__c discount : discounts){
//             if(discount.ARC_Status__c == 'Activated'){
//                 activeDiscounts.add(discount);
//             }
//         }
//         return activeDiscounts;
//     }

//     private static List<ARC_PromotionDiscount__c> filterByInactiveDiscounts(List<ARC_PromotionDiscount__c> discounts){
//         List<ARC_PromotionDiscount__c> inactiveDiscounts = new List<ARC_PromotionDiscount__c>();
//         for(ARC_PromotionDiscount__c discount : discounts){
//             if(discount.ARC_Status__c != 'Activated'){
//                 inactiveDiscounts.add(discount);
//             }
//         }
//         return inactiveDiscounts;
//     }

//     private static Map<Id, List<vlocity_ins__ContractLineItem__c>> mapPlansByContractId(List<vlocity_ins__ContractLineItem__c> plans){
//         Map<Id, List<vlocity_ins__ContractLineItem__c>> plansByContractId = new Map<Id, List<vlocity_ins__ContractLineItem__c>>();
//         for(vlocity_ins__ContractLineItem__c plan : plans){
//             if(plansByContractId.containsKey(plan.vlocity_ins__ContractId__c)){
//                 plansByContractId.get(plan.vlocity_ins__ContractId__c).add(plan);
//             }else{
//                 plansByContractId.put(plan.vlocity_ins__ContractId__c, new List<vlocity_ins__ContractLineItem__c>{plan});
//             }
//         }
//         return plansByContractId;
//     }

//     public static void updateOrderPrice(Set<Id> contractId){
//         List<ChargentOrders__ChargentOrder__c> orders = [
//             SELECT Id, ARC_Contract__c, ARC_Contract__r.ARC_TotalPrice__c, Current_Recurring_Order__c
//             FROM ChargentOrders__ChargentOrder__c
//             WHERE ARC_Contract__c IN :contractId AND Current_Recurring_Order__c = true  
//         ];
//         for(ChargentOrders__ChargentOrder__c order : orders){
//             order.ChargentOrders__Subtotal__c = order.ARC_Contract__r.ARC_TotalPrice__c;
//             order.ChargentOrders__Charge_Amount__c = order.ARC_Contract__r.ARC_TotalPrice__c;
//         }
//         update orders;
//     }

//     ////// TOMAS START //////

//     public static void programChangeAndSpinOffApplyDiscounts(Set<Id> contractIds){
//         applyRenewalDiscountFromPcOrSpinOff(contractIds);
//         //cloneHealthyDiscounts(contractIds);
//     }

//     public static void applyRenewalDiscountFromPcOrSpinOff(Set<Id> contractIds) {

//         List<ARC_ContractParticipant__c> participantsByContractId = getContractParticipants(contractIds, false);

//         Map<Integer,Id> renewalDiscountCodeMap = getAndMapRenewalDiscountCodes();
        
//         List<RecordType> discountRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Renewal_Discount' AND SobjectType = 'ARC_PromotionDiscount__c'];
        
//         // Map to catch oldest participant from current contract
//         Map<Id, Date> oldestSinceDateByContract = new Map<Id, Date>();
        
//         for (ARC_ContractParticipant__c participant : participantsByContractId) {
//             if (participant.ARC_PersonAccount__r != null && participant.ARC_PersonAccount__r.ARC_SinceDate__c != null) {
//                 Date sinceDate = participant.ARC_PersonAccount__r.ARC_SinceDate__c;
                
//                 if (!oldestSinceDateByContract.containsKey(participant.ARC_Contract__c) || 
//                     oldestSinceDateByContract.get(participant.ARC_Contract__c) > sinceDate) {
//                     oldestSinceDateByContract.put(participant.ARC_Contract__c, sinceDate);
//                 }
//             }
//         }
    
//         Date currentDate = Date.today();

//         List<ARC_PromotionDiscount__c> renewalDiscountsToInsertList = new List<ARC_PromotionDiscount__c>();
        
//         for (Id contractId : oldestSinceDateByContract.keySet()) {
//             Date oldestSinceDate = oldestSinceDateByContract.get(contractId);
//             Integer yearsPassed = currentDate.year() - oldestSinceDate.year();

//             if (currentDate.addYears(-yearsPassed) < oldestSinceDate) {
//                 yearsPassed -= 1;
//             }

//             if (yearsPassed <= 0) {
//                 System.debug('No Apply Renewal Discount for Contract Id: ' + contractId);
//                 continue;

//             }
    
//             Integer promotionCodeNumber = yearsPassed >= 5 ? 5 : yearsPassed;

//             renewalDiscountsToInsertList.add(assignRenewalDiscountToContract(contractId, renewalDiscountCodeMap.get(promotionCodeNumber), discountRecordTypeId[0].Id));
//         }

//         if (!renewalDiscountsToInsertList.isEmpty()) {
//             insert renewalDiscountsToInsertList;
//         }
//         System.debug('renewalDiscountsToInsertList ' + renewalDiscountsToInsertList);
//     }
    
//     public static void cloneHealthyDiscounts(Set<Id> contractIds){
//         List<Contract> newContracts = [SELECT Id, vlocity_ins__ExpiredContractId__c FROM Contract WHERE Id IN :contractIds];
//         Set<Id> expiredContractIds = new Set<Id>();
//         Map<Id,Id> oldNewContractIds = new Map<Id,Id>();

//         for (Contract contract : newContracts) {
//             expiredContractIds.add(contract.vlocity_ins__ExpiredContractId__c);
//             oldNewContractIds.put(contract.vlocity_ins__ExpiredContractId__c, contract.Id);
//         }    

//         Set<Id> exisitingAccountIds = new Set<Id>();

//         List<ARC_PromotionDiscount__c> discountsToClone = [SELECT Id, Name, ARC_StartDate__c, ARC_Description__c, ARC_EndDate__c,ARC_Status__c, ARC_PromoCode__c, RecordTypeId, ARC_Contract__c 
//                                                             FROM ARC_PromotionDiscount__c  
//                                                             WHERE (ARC_Status__c = 'Activated' OR ARC_Status__c = 'Pending' OR ARC_Status__c = 'Awaiting Activation')
//                                                             AND RecordType.DeveloperName = 'Healthy_Discount'
//                                                             AND ARC_Contract__c IN :expiredContractIds];

        
//         Map<Id, List<ARC_PromotionDiscount__c>> contractDiscounts = new Map<Id, List<ARC_PromotionDiscount__c>>();

//         List<ARC_ContractParticipant__c> currentContractParticipants = getContractParticipants(contractIds, true);

//         Map<Id,List<Account>> contractAccounts = mapContractAccounts(currentContractParticipants);

//         List<ARC_HealthyDiscountAccount__c> discountAccountsToClone = getDiscountAccounts(currentContractParticipants, discountsToClone);
 
//         Map<Id, ARC_PromotionDiscount__c> oldNewDiscounts = new Map<Id, ARC_PromotionDiscount__c>();
//         Map<Id, ARC_HealthyDiscountAccount__c> oldNewDiscountAccounts = new Map<Id, ARC_HealthyDiscountAccount__c>();
//         List<ARC_HealthyDiscountAccount__c> newDiscountAccounts = new List<ARC_HealthyDiscountAccount__c>();
        
//         //clone ARC_PromotionDiscount__c, map old with new
//         for(ARC_PromotionDiscount__c discount : discountsToClone){
//             ARC_PromotionDiscount__c clonedDiscount = new ARC_PromotionDiscount__c(
//                 Name = discount.Name,
//                 ARC_StartDate__c = discount.ARC_StartDate__c,
//                 ARC_Description__c = discount.ARC_Description__c,
//                 ARC_EndDate__c = discount.ARC_EndDate__c,
//                 ARC_Status__c = discount.ARC_Status__c, 
//                 ARC_PromoCode__c = discount.ARC_PromoCode__c,
//                 RecordTypeId = discount.RecordTypeId,
//                 ARC_Contract__c = oldNewContractIds.get(discount.ARC_Contract__c)
//             );
//             oldNewDiscounts.put(discount.Id, clonedDiscount);
//         }

//         insert oldNewDiscounts.values();

//         System.debug('oldNewDiscounts ' + oldNewDiscounts);

//         // Clone ARC_HealthyDiscountAccount__c, map old with new
//         for(ARC_HealthyDiscountAccount__c discountAccount : discountAccountsToClone){
//             exisitingAccountIds.add(discountAccount.ARC_Account__c);
//             ARC_HealthyDiscountAccount__c clonedDiscountAccount = new ARC_HealthyDiscountAccount__c();
//             clonedDiscountAccount.Name = discountAccount.Name;
//             clonedDiscountAccount.ARC_Status__c = discountAccount.ARC_Status__c;
//             clonedDiscountAccount.ARC_DecisionDate__c = discountAccount.ARC_DecisionDate__c;
//             clonedDiscountAccount.ARC_Account__c = discountAccount.ARC_Account__c;
//             clonedDiscountAccount.ARC_Discount__c = oldNewDiscounts.get(discountAccount.ARC_Discount__c).Id;
            
//             newDiscountAccounts.add(clonedDiscountAccount);
//         }
        
//         //If there is a ex Child with a Feature Primary Relationship, we update the new discount to Pending
//         List<ARC_PromotionDiscount__c> discountStatusToUpdateList = new List<ARC_PromotionDiscount__c>();

//         // Create new discount accounts (for new accounts);
//         for(Id contractId : contractAccounts.keySet()){
            
//             for (ARC_PromotionDiscount__c discount : oldNewDiscounts.values()) {

//                 if (discount.ARC_Contract__c == contractId) {
                
//                     for(Account account : contractAccounts.get(contractId)){
//                         if(!exisitingAccountIds.contains(account.Id)){

//                             if (account.ARC_DependentRelationship__c == 'Future Primary') {
//                                 ARC_PromotionDiscount__c discountRecord = new ARC_PromotionDiscount__c(
//                                     Id = discount.Id,
//                                     ARC_Status__c = 'Pending'
//                                 );

//                                 discountStatusToUpdateList.add(discountRecord);

//                             } else {
//                                 // //create new discount account
//                                 ARC_HealthyDiscountAccount__c newDiscountAccount = new ARC_HealthyDiscountAccount__c();
//                                 newDiscountAccount.Name = account.Name;
//                                 newDiscountAccount.ARC_Status__c = 'Pending';
//                                 newDiscountAccount.ARC_Account__c = account.Id;
//                                 newDiscountAccount.ARC_Discount__c = discount.Id;
    
//                                 newDiscountAccounts.add(newDiscountAccount);

//                             }

//                         }
//                     }
//                 }   
//             }
//         }

//         if (!discountStatusToUpdateList.isEmpty()) {
//             update discountStatusToUpdateList;
//         }

//         if (!newDiscountAccounts.isEmpty()) {
//             insert newDiscountAccounts;
//         }
//     }

//     // Helper method to get and map discount codes
//     public static Map<Integer, Id> getAndMapRenewalDiscountCodes(){

//         List<ARC_PromotionCode__c> renewalDiscountDiscountCodes = [SELECT Id, Name FROM ARC_PromotionCode__c WHERE RecordType.DeveloperName = 'Renewal_Discount'];

//         Map<Integer, Id> renewalDiscountCodeMap = new Map<Integer, Id>();
        
//         for (ARC_PromotionCode__c discountCode : renewalDiscountDiscountCodes) {

//             String name = discountCode.Name;
//             Integer levelNumber;

//             if (name.endsWith('1')) {
//                 levelNumber = 1;
//             } else if (name.endsWith('2')) {
//                 levelNumber = 2;
//             } else if (name.endsWith('3')) {
//                 levelNumber = 3;
//             } else if (name.endsWith('4')) {
//                 levelNumber = 4;
//             } else if (name.endsWith('5')) {
//                 levelNumber = 5;
//             }
            
//             if (levelNumber != null) {
//                 renewalDiscountCodeMap.put(levelNumber, discountCode.Id);
//             }
//         }

//         return renewalDiscountCodeMap;
//     }

//     // Helper method to assign a Renewal Disocunt to a Contract
//     public static ARC_PromotionDiscount__c assignRenewalDiscountToContract (Id contractId, Id promeCode, Id RecordTypeId){

//         ARC_PromotionDiscount__c renewalDiscount = new  ARC_PromotionDiscount__c(
//             Name = 'Renewal Discount',
//             ARC_Status__c = 'Activated',
//             ARC_Contract__c = contractId,
//             ARC_PromoCode__c = promeCode,
//             RecordTypeId = RecordTypeId
//         );

//         return renewalDiscount;
//     }

//     // Helper method to get expire contract discountAccounts
//     public static List<ARC_HealthyDiscountAccount__c> getDiscountAccounts(List<ARC_ContractParticipant__c> participants, List<ARC_PromotionDiscount__c> discounts){
//         Set<Id> accountIds = new Set<Id>();
//         for(ARC_ContractParticipant__c participant : participants){
//             accountIds.add(participant.ARC_PersonAccount__c);
//         }

//         return [SELECT Id, Name, ARC_Status__c, ARC_DecisionDate__c, ARC_Account__c, ARC_Discount__c  FROM ARC_HealthyDiscountAccount__c WHERE ARC_Discount__c IN :discounts AND ARC_Account__c IN :accountIds];
//     }

//     // Helper method to retrieve contract participants with filtering on Dependent Relationship != Child if removeChild = true
//     public static List<ARC_ContractParticipant__c> getContractParticipants(Set<Id> contractId, Boolean removeChild) {
//         String query = 'SELECT Id, Name, ARC_PersonAccount__c, ARC_PersonAccount__r.Name, ARC_PersonAccount__r.ARC_SinceDate__c, ARC_Contract__c FROM ARC_ContractParticipant__c WHERE ARC_Contract__c IN :contractId';
        
//         if (removeChild) {
//             query += ' AND ARC_PersonAccount__r.ARC_DependentRelationship__c != \'Child\'';
//         }

//         return Database.query(query);
//     }

//     // Helper method to map contract with person accounts
//     public static Map<Id,List<Account>> mapContractAccounts(List<ARC_ContractParticipant__c> participantsList) {
  
//         Map<Id,List<Account>> contractAccounts = new Map<Id,List<Account>>();

//         for (ARC_ContractParticipant__c cp : participantsList) {
//             Account relatedAccount = new Account(
//                 Id = cp.ARC_PersonAccount__c,
//                 Name = cp.ARC_PersonAccount__r.Name,
//                 ARC_DependentRelationship__c = cp.ARC_PersonAccount__r.ARC_DependentRelationship__c
//             );

//             if (contractAccounts.containsKey(cp.ARC_Contract__c)) {
//                 contractAccounts.get(cp.ARC_Contract__c).add(relatedAccount);
//             } else {
//                 contractAccounts.put(cp.ARC_Contract__c, new List<Account>{relatedAccount});
//             }
//         }

//         return contractAccounts;
//     }

//     ////// TOMAS END //////


//     @InvocableMethod(label='Discounts Manager' description='description' category='Discounts')
//     public static void invocableDiscount(List<DiscountRequest> requests){
//         System.debug(requests);
//         Set<Id> contractIds = new Set<Id>();
//         Map<String, List<Id>> contractIdsByMethod = new Map<String, List<Id>>();
//         for(DiscountRequest request : requests){
//             if(request.contractId != null){
//                 contractIds.add(request.contractId);
//                 if(contractIdsByMethod.containsKey(request.methodName)){
//                     contractIdsByMethod.get(request.methodName).add(request.contractId);
//                 }else{
//                     contractIdsByMethod.put(request.methodName, new List<Id>{request.contractId});
//                 }
//             }
//             if(request.contractIds != null){
//                 contractIds.addAll(request.contractIds);
//                 if(contractIdsByMethod.containsKey(request.methodName)){
//                     contractIdsByMethod.get(request.methodName).addAll(request.contractIds);
//                 }else{
//                     contractIdsByMethod.put(request.methodName, request.contractIds);
//                 }
//             }
//         }
//         System.debug(contractIdsByMethod);
//         if(contractIdsByMethod.containsKey('applyDiscounts')){
//             applyDiscounts(new Set<Id>(contractIdsByMethod.get('applyDiscounts')));
//         }
//         if(contractIdsByMethod.containsKey('populateDiscounts')){
//             System.debug('invocableDiscounts, populateDiscounts: ' + contractIdsByMethod.get('populateDiscounts'));
//             populateDiscounts(new Set<Id>(contractIdsByMethod.get('populateDiscounts')));
//         }
//         if(contractIdsByMethod.containsKey('programChangeAndSpinOffApplyDiscounts')){
//             programChangeAndSpinOffApplyDiscounts(new Set<Id>(contractIdsByMethod.get('programChangeAndSpinOffApplyDiscounts')));
//         }
//     }

//     public class DiscountRequest {
//         @InvocableVariable(label='Method' description='method to execute' required=true)
//         public String methodName;
//         // valid values: applyDiscounts, populateDiscounts

//         @InvocableVariable(label='Contract Id' description='description')
//         public Id contractId;

//         @InvocableVariable(label='Contract Id' description='description')
//         public List<Id> contractIds;
//     }
}