/*******************************************************************
* @ClassName          :   ARC_PromotionCode
* @Description        :   Handles Promotion Code (ARC_PromotionCode__c) related logic
* @MethodName         :   getDocumentInformation
********************************************************************/

global without sharing class ARC_PromotionCode implements vlocity_ins.VlocityOpenInterface {
	public Boolean invokeMethod(String methodName, Map <String,Object> inputMap, Map<String,Object> outputMap, Map <String,Object> options) {
        if (methodName == 'checkActivePromotionCodeExist') {
            checkActivePromotionCodeExist(inputMap, outputMap);
        }
        if (methodName == 'getContractInformation') {
            getContractInformation(inputMap, outputMap);
        }
        if (methodName == 'getDiscountCodeInformation') {
            getDiscountCodeInformation(inputMap, outputMap);
        }
        if (methodName == 'upsertPromotionDiscount') {
            upsertPromotionDiscount(inputMap, outputMap);
        }
        if (methodName == 'getFlexcardData') {
            getFlexcardData(inputMap, outputMap);
        }
        return true;
	}


    /*******************************************************************
    * @MethodName         :   checkActivePromotionCodeExist
    * @Description        :   Performs a query on the SObject ARC_PromotionCode__c to check if there is a currently at least a Promotion code active, returns either true or false.
    * @Author             :   Francisco Caliaba
    * @LastModified       :   08-08-2023
    ********************************************************************/
    public static void checkActivePromotionCodeExist(Map <String,Object> inputMap, Map <String,Object> outMap) {
        List<ARC_PromotionCode__c> listOfCodes = [SELECT Id FROM ARC_PromotionCode__c WHERE ARC_Active__c = true LIMIT 1];
        Boolean ListIsNotEmpty = !listOfCodes.isEmpty()? true : false;
        outMap.put('ListIsNotEmpty', ListIsNotEmpty);
    }


    /*******************************************************************
    * @MethodName         :   getContractInformation
    * @Description        :   Performs a query on the SObject Contract to check if there is a currently an App Fee, Change Fee and fetch the total price and core price to perform discount calculations.
    * @Author             :   Francisco Caliaba
    * @LastModified       :   08-01-2023
    ********************************************************************/
    public static void getContractInformation(Map <String,Object> inputMap, Map <String,Object> outMap) {
        String contractId = String.valueOf(inputMap.get('ContractId'));
        List<Contract> contract = [
            SELECT 
            ARC_AppFeeOrder__r.ChargentOrders__Charge_Amount__c,
            ARC_AppFeeOrder__r.ChargentOrders__Description__c,
            ARC_RecurringMonthlyOrder__r.ChargentOrders__Description__c,
            ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Amount__c,
            ARC_TotalPrice__c,
            ARC_ContractReason__c,
            ARC_SingleReasonForPC__c,
                (SELECT
                vlocity_ins__UnitPrice__c
                FROM vlocity_ins__ContractLineItems__r
                WHERE vlocity_ins__ParentItemId__c = null
                AND vlocity_ins__ProductType__c = 'Medical')
            FROM Contract 
            WHERE Id =: contractId
            LIMIT 1
        ];

        outMap.put('contract', contract[0]);
    }

    /*******************************************************************
    * @MethodName         :   getDiscountCodeInformation
    * @Description        :   Performs a query on the SObject ARC_PromotionCode__c to check if there is a currently active promotional code to apply a discount on the plan price.
    * @Author             :   Francisco Caliaba
    * @LastModified       :   07-31-2023
    ********************************************************************/
    public static void getDiscountCodeInformation(Map <String,Object> inputMap, Map <String,Object> outMap) {
        String promotionCode = String.valueOf(inputMap.get('PromotionCode'));
        List<ARC_PromotionCode__c> code = [
            SELECT
            Id,
            Name,
            ARC_DiscountType__c,
            ARC_DiscountRate__c,
            ARC_DiscountedAmount__c,
            ARC_PromotionCode__c,
            ARC_NumbeOfRecurringPaymentsToDiscount__c,
            ARC_NumberOfTimesCanBeUsed__c,
            ARC_ApplyOver__c
            FROM ARC_PromotionCode__c 
            WHERE ARC_PromotionCode__c =: promotionCode
            AND ARC_Active__c = true 
            LIMIT 1
        ];

        System.debug(code);

        if (!code.isEmpty()) {
            outMap.put('code', code[0]);
        } else {
            outMap.put('code', null);
        }
    }

    /*******************************************************************
    * @MethodName         :   upsertPromotionDiscount
    * @Description        :   Performs an upsert on the SObject ARC_PromotionDiscount__c once the discount is created.
    * @Author             :   Francisco Caliaba
    * @LastModified       :   08-04-2023
    ********************************************************************/
    public static void upsertPromotionDiscount(Map <String,Object> inputMap, Map <String,Object> outMap) {

        if(inputMap.get('discountToUpsert') != null && inputMap.get('discountToUpsert') != ''){
                Map<String,Object> discountToUpsert = (Map<String,Object>)inputMap.get('discountToUpsert');

                System.debug(discountToUpsert.get('Id'));
                System.debug(discountToUpsert.get('PromotionCodeId'));
                System.debug(discountToUpsert.get('PromotionCodeName'));
                System.debug(discountToUpsert.get('ContractId'));
                System.debug(discountToUpsert.get('DiscountAmount'));
                System.debug(discountToUpsert.get('MedicalPrice'));
                System.debug(discountToUpsert.get('NumberOfPayments'));
                System.debug(discountToUpsert.get('DiscountPrice'));
                System.debug(discountToUpsert.get('AgentId'));

                Id promotionDiscountId = (Id)discountToUpsert.get('Id');
                Id promotionCodeId = (Id)discountToUpsert.get('PromotionCodeId');
                String promotionCodeName = (String)discountToUpsert.get('PromotionCodeName');
                Id contractId = (Id)discountToUpsert.get('ContractId');
                Decimal discountAmount = Decimal.valueOf((String)discountToUpsert.get('DiscountAmount'));
                Decimal medicalPrice = discountToUpsert.get('MedicalPrice') != null? (Decimal)discountToUpsert.get('MedicalPrice'):null;
                Integer numberOfPayments = (Integer)discountToUpsert.get('NumberOfPayments');
                Decimal discountPrice = Decimal.valueOf((String)discountToUpsert.get('DiscountPrice'));
                Id agentId = (Id)discountToUpsert.get('AgentId');

                Id promotionDiscountRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByName().get('Promotion Discount').getRecordTypeId();


                ARC_PromotionDiscount__c PromoDiscount = new ARC_PromotionDiscount__c(
                    Id = promotionDiscountId,
                    Name = promotionCodeName,
                    ARC_PromoCode__c = promotionCodeId,
                    ARC_Contract__c = contractId,
                    ARC_AmountToDiscountPerTransaction__c = discountAmount,
                    ARC_CorePriceWithoutDiscount__c = medicalPrice,
                    ARC_NumberOfTimesCanBeUsed__c = numberOfPayments != null && numberOfPayments > 1 ? numberOfPayments : 1,
                    ARC_ExonerateAppChangeFee__c = discountPrice == 0 ? true : false,
                    ARC_Agent__c = agentId,
                    RecordTypeId = promotionDiscountRecordTypeId
                );

                upsert PromoDiscount;
                outmap.put('success', true);
                outmap.put('error', 'OK');
                outMap.put('PromoDiscountId', PromoDiscount.Id);
        }
    }

    /*******************************************************************
    * @MethodName         :   getFlexcardData
    * @Description        :   Performs a query and retrieves necessary information to display the active discount in ARC_PromoDiscountInfo FLEXCARD.
    * @Author             :   Francisco Caliaba
    * @LastModified       :   08-10-2023
    ********************************************************************/
    public static void getFlexcardData(Map <String,Object> inputMap, Map <String,Object> outMap) {
        Id contractId = (Id)inputMap.get('ContractId');
        List<ARC_PromotionDiscount__c> activeDiscount = [
            SELECT Id,ARC_TypeOfDiscount__c,ARC_AmountToDiscountPerTransaction__c,ARC_CorePriceWithoutDiscount__c,ARC_TimesUsed__c,ARC_NumberOfTimesCanBeUsed__c
            FROM ARC_PromotionDiscount__c
            WHERE ARC_Active__c = true
            AND ARC_Contract__c =: contractId LIMIT 1
        ];

        if(!activeDiscount.isEmpty()){
            outMap.put('hasActiveDiscount', true);
            outMap.put('Id', activeDiscount[0].Id);
            outMap.put('Type', activeDiscount[0].ARC_TypeOfDiscount__c);

            String amount = activeDiscount[0].ARC_AmountToDiscountPerTransaction__c != null ? String.valueOf(activeDiscount[0].ARC_AmountToDiscountPerTransaction__c.setScale(2)):'';
            String priceWithoutDiscount = activeDiscount[0].ARC_CorePriceWithoutDiscount__c != null ? String.valueOf(activeDiscount[0].ARC_CorePriceWithoutDiscount__c.setScale(2)): '';

            String priceWithDiscount = (activeDiscount[0].ARC_AmountToDiscountPerTransaction__c != null && activeDiscount[0].ARC_CorePriceWithoutDiscount__c != null) ?
                                        String.valueOf((activeDiscount[0].ARC_CorePriceWithoutDiscount__c - activeDiscount[0].ARC_AmountToDiscountPerTransaction__c).setScale(2)):
                                        '';

            outMap.put('Amount', amount);
            outMap.put('PriceWithoutDiscount', priceWithoutDiscount);
            outMap.put('PriceWithDiscount', priceWithDiscount);
            outMap.put('OverallDiscountUsage', String.valueOf(activeDiscount[0].ARC_TimesUsed__c +'/'+ activeDiscount[0].ARC_NumberOfTimesCanBeUsed__c));

        } else {
            outMap.put('hasActiveDiscount', false);
        }

    }
}