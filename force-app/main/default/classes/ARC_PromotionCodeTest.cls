@isTest
public with sharing class ARC_PromotionCodeTest {

    @TestSetup
    static void makeData(){
        ARC_PromotionCode__c appFeePromotionCode = new ARC_PromotionCode__c(
            Name = 'App Fee Test',
            ARC_PromotionCode__c = 'App Fee Test',
            ARC_DiscountType__c = 'App Fee',
            ARC_ApplyOver__c = 'App Fee',
            ARC_DiscountedAmount__c = 10,
            ARC_StartDate__c = Date.today(),
            ARC_EndDate__c = Date.today().addMonths(1)
        );
        insert appFeePromotionCode;

        List<Contract> contract = ARC_TestUtility.createContracts(1);
        insert contract[0];

        //Create Chargent Order    
        ChargentOrders__ChargentOrder__c chargent=new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = contract[0].Id,
            ChargentOrders__Shipping__c = 232,
            ChargentOrders__Tax__c  = 232,
            ChargentOrders__Charge_Amount__c = 232,
            ChargentOrders__Subtotal__c  = 232,
            ChargentOrders__Charge_Date__c =  '01',
            ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3),
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12),
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Last_4__c = '1234',
            ChargentOrders__Card_Type__c = 'VISA',
            ChargentOrders__Card_Expiration_Month__c = '10',
            ChargentOrders__Card_Expiration_Year__c = '2025',
            ChargentOrders__Tokenization__c = '12345678',
            ChargentOrders__Description__c = 'Recurring Monthly Order'
        );
        insert chargent;

        contract[0].ARC_AppFeeOrder__c = chargent.Id;
        update contract[0];

        ARC_PromotionDiscount__c appFeePromotionDiscount = new ARC_PromotionDiscount__c(
            ARC_NumberOfTimesCanBeUsed__c = 1,
            ARC_ExonerateAppChangeFee__c = false,
            ARC_AmountToDiscountPerTransaction__c = 10,
            ARC_TimesUsed__c = 0,
            ARC_PromoCode__c = appFeePromotionCode.Id,
            ARC_Contract__c = contract[0].Id
        );
        insert appFeePromotionDiscount;
    }

    @isTest
    public static void testCheckActivePromotionCodeExist() {
        ARC_PromotionCode classInstance = new ARC_PromotionCode();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        classInstance.invokeMethod('checkActivePromotionCodeExist',input,output,options);

        Assert.areEqual(output.get('ListIsNotEmpty'), true);
    }

    @isTest
    public static void testGetContractInformation() {
        List<Contract> contract = [SELECT Id FROM Contract LIMIT 1];
        ARC_PromotionCode classInstance = new ARC_PromotionCode();
        Map<String, Object> input = new Map<String, Object>{'ContractId'=> contract[0].Id};
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        classInstance.invokeMethod('getContractInformation',input,output,options);

        Assert.areNotEqual(null, output.get('contract'));
    }

    @isTest
    public static void testGetDiscountCodeInformation() {
        List<ARC_PromotionCode__c> code = [SELECT ARC_PromotionCode__c FROM ARC_PromotionCode__c LIMIT 1];

        ARC_PromotionCode classInstance = new ARC_PromotionCode();
        Map<String, Object> input = new Map<String, Object>{'PromotionCode'=> code[0].ARC_PromotionCode__c};
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        classInstance.invokeMethod('getDiscountCodeInformation',input,output,options);
        Assert.areNotEqual(null, output.get('code'));
        
        input.put('PromotionCode', 'Invalid Code');
        classInstance.invokeMethod('getDiscountCodeInformation',input,output,options);
        Assert.areEqual(null, output.get('code'));
    }

    @isTest
    public static void testUpsertPromotionDiscount() {
        List<ARC_PromotionCode__c> code = [SELECT Id,Name,ARC_PromotionCode__c FROM ARC_PromotionCode__c LIMIT 1];
        List<Contract> contract = [SELECT Id FROM Contract LIMIT 1];

        ARC_PromotionCode classInstance = new ARC_PromotionCode();
        Map<String, Object> discountToUpsert = new Map<String, Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        discountToUpsert.put('Id', null);
        discountToUpsert.put('PromotionCodeId',code[0].Id);
        discountToUpsert.put('PromotionCodeName',code[0].Name);
        discountToUpsert.put('ContractId',contract[0].Id);
        discountToUpsert.put('DiscountAmount', '-20.00');
        discountToUpsert.put('MedicalPrice', 500);
        discountToUpsert.put('NumberOfPayments',1);
        discountToUpsert.put('DiscountPrice','70');

        input.put('discountToUpsert', discountToUpsert);

        classInstance.invokeMethod('upsertPromotionDiscount',input,output,options);
        Assert.areEqual(true, output.get('success'));
        Assert.areNotEqual(null, output.get('PromoDiscountId'));
    }

    @isTest
    public static void testGetFlexcardData() {
        List<Contract> contract = [SELECT Id FROM Contract LIMIT 1];
        List<ARC_PromotionDiscount__c> promotionDiscount = [SELECT Id,ARC_TimesUsed__c FROM ARC_PromotionDiscount__c LIMIT 1];
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        input.put('ContractId',contract[0].Id);

        ARC_PromotionCode classInstance = new ARC_PromotionCode();
        classInstance.invokeMethod('getFlexcardData',input,output,options);
        promotionDiscount[0].ARC_TimesUsed__c += 1;
        Assert.areEqual(true, output.get('hasActiveDiscount'));

        update promotionDiscount[0];
        classInstance.invokeMethod('getFlexcardData',input,output,options);
        Assert.areEqual(false, output.get('hasActiveDiscount'));
    }


}