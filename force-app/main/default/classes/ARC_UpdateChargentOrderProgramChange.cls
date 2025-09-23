global without sharing class ARC_UpdateChargentOrderProgramChange implements vlocity_ins.VlocityOpenInterface {
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {

        if (methodName == 'updateOrder') {
            updateOrder(inputMap, outputMap,options);
        }            
        return true;
    }

    /**
     * This method creates the change fee and recurring orders based on the input map.
     * 
     * Used in Program Change
     * 
     * @param inputMap The input map containing the necessary data for the creation of the new orders (Change fee & Recurring).
     * @param outputMap The output map to store the new order IDs.
    */
    public static void updateOrder(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){    
        Id recurringOrderId;
        Id changeFeeOrderId;
        Set<Id> newOrderIds = new Set<Id>(); 
        Id accountId = (String)inputMap.get('accountId');
        Id newContractId;
        String STEP_ChangeReason = (String)inputMap.get('STEP_ChangeReason');
        String oldContractId = (String)inputMap.get('OldContractId');
        String oldChargentOrderId = (String)inputMap.get('OldChargentOrderId');
        Double addMemberFee = (Double)inputMap.get('AddMemberFee');
        Double upgradeFee = (Double)inputMap.get('UpgradeFee');
        String againstDefValue = (String) inputMap.get('AgainstDefault');
        Boolean againstDefault = againstDefValue == 'No';
        System.debug('againstDefValue '+againstDefValue);
        System.debug('againstDefault '+againstDefault);
        Double appFee = 0;
        Boolean isReprice = (String)inputMap.get('isReprice') == 'true';
        Boolean hasChangeFee = STEP_ChangeReason.contains('Program Upgrade') || (STEP_ChangeReason.contains('Add Member') || STEP_ChangeReason.contains('Add Existing Member'));
        Map<String, Object> newContractMap = (Map<String, Object>)inputMap.get('FirstContract');
        List<ChargentOrders__ChargentOrder__c> newOrders = new List<ChargentOrders__ChargentOrder__c>();
        ChargentOrders__ChargentOrder__c originalChargentOrder = new ChargentOrders__ChargentOrder__c();

        if (newContractMap.get('ContractId') != null) {
            newContractId = (String)newContractMap.get('ContractId');
        }

        if ((STEP_ChangeReason == 'Add Member' || STEP_ChangeReason == 'Add Existing Member') || ((STEP_ChangeReason.contains('Add Member') || STEP_ChangeReason.contains('Add Existing Member')) && !STEP_ChangeReason.contains('Upgrade')) && !STEP_ChangeReason.contains('Upgrade')) {
            appFee = addMemberFee;
        } else if (STEP_ChangeReason.contains('Upgrade')) {
            appFee = upgradeFee;
        }

        if (oldChargentOrderId != null && oldChargentOrderId != '') {
            originalChargentOrder = [SELECT id, arc_contract__c, chargentorders__account__c, chargentorders__tokenization__c, chargentorders__billing_city__c, chargentorders__billing_address__c, chargentorders__billing_email__c, chargentorders__billing_state__c, chargentorders__billing_first_name__c, chargentorders__gateway__c, chargentorders__billing_last_name__c, chargentorders__payment_method__c, chargentorders__billing_zip_postal__c, ChargentOrders__Card_Year_Indicator__c, ChargentOrders__Card_Expiration_Month__c, ChargentOrders__Card_Last_4__c, ChargentOrders__Bank_Account_Last_4__c, ChargentOrders__Bank_Routing_Number__c, ChargentOrders__Bank_Name__c, ChargentOrders__Bank_Account_Type__c, ChargentOrders__Bank_Account_Name__c, ARC_FirstMonthPayed__c, ChargentOrders__Card_Month_Indicator__c, ChargentOrders__Card_Expiration_Year__c, ChargentOrders__Card_Number__c, ChargentOrders__Card_Type__c, ChargentOrders__Bank_Account_Number__c, ChargentOrders__Charge_Date__c FROM ChargentOrders__ChargentOrder__c WHERE (Id = :oldChargentOrderId) LIMIT 1];
        } else {
            originalChargentOrder = [SELECT id, arc_contract__c, chargentorders__account__c, chargentorders__tokenization__c, chargentorders__billing_city__c, chargentorders__billing_address__c, chargentorders__billing_email__c, chargentorders__billing_state__c, chargentorders__billing_first_name__c, chargentorders__gateway__c, chargentorders__billing_last_name__c, chargentorders__payment_method__c, chargentorders__billing_zip_postal__c, ChargentOrders__Card_Year_Indicator__c, ChargentOrders__Card_Expiration_Month__c, ChargentOrders__Card_Last_4__c, ChargentOrders__Bank_Account_Last_4__c, ChargentOrders__Bank_Routing_Number__c, ChargentOrders__Bank_Name__c, ChargentOrders__Bank_Account_Type__c, ChargentOrders__Bank_Account_Name__c, ARC_FirstMonthPayed__c, ChargentOrders__Card_Month_Indicator__c, ChargentOrders__Card_Expiration_Year__c, ChargentOrders__Card_Number__c, ChargentOrders__Card_Type__c, ChargentOrders__Bank_Account_Number__c, ChargentOrders__Charge_Date__c FROM ChargentOrders__ChargentOrder__c WHERE (ARC_Contract__c = :oldContractId) AND ChargentOrders__Description__c = 'Recurring Monthly Order' LIMIT 1];
        }

        //generate change fee order
        ChargentOrders__ChargentOrder__c changeFeeOrder;
        if (hasChangeFee) {
            if(!againstDefault){
                changeFeeOrder = generateChangeFeeOrder(originalChargentOrder, newContractId, accountId, appFee, againstDefault);
            } else{
                changeFeeOrder = generateChangeFeeOrder(originalChargentOrder, newContractId, accountId, 0, againstDefault);
            }
        }
        //generate recurring monthly order
        ChargentOrders__ChargentOrder__c recurringFeeOrder = generateRecurringMonthlyOrder(originalChargentOrder, newContractId, accountId, (Decimal)newContractMap.get('NewContractTotalPrice'));
        
        if (hasChangeFee) {
            insert new List<ChargentOrders__ChargentOrder__c>{changeFeeOrder,recurringFeeOrder};
            ChargentOrders__ChargentOrder__c test = [SELECT Id,ARC_AgainstTheDefault__c FROM ChargentOrders__ChargentOrder__c WHERE Id =:changeFeeOrder.Id ];
            System.debug(test);
        } else {
            insert recurringFeeOrder;
        }

        if (isReprice) {
            originalChargentOrder.ChargentOrders__Payment_Status__c = 'Stopped';
            originalChargentOrder.ChargentOrders__Payment_Start_Date__c = null;
            update originalChargentOrder;
        }

        Contract contract = new Contract(
            Id = newContractId,
            ARC_RecurringMonthlyOrder__c = recurringFeeOrder.Id,
            ARC_AppFeeOrder__c = hasChangeFee? changeFeeOrder.Id : null
        );

        update contract;
        newOrderIds.add(recurringFeeOrder.Id);
        if(hasChangeFee) newOrderIds.add(changeFeeOrder.Id);

        outputMap.put('ChargentOrderIds', newOrderIds);
    }

    private static ChargentOrders__ChargentOrder__c generateChangeFeeOrder(ChargentOrders__ChargentOrder__c order, Id contractId, Id accountId, Decimal fee, Boolean againstDefault){
        ChargentOrders__ChargentOrder__c newChangeFeeOrder = generateOrder(order, contractId, accountId);
        newChangeFeeOrder.ChargentOrders__Subtotal__c = fee;
        newChangeFeeOrder.ChargentOrders__Description__c = 'Change Fee';
        newChangeFeeOrder.ChargentOrders__Payment_Frequency__c = 'Once';
        newChangeFeeOrder.ChargentOrders__Payment_Status__c = '';
        newChangeFeeOrder.ChargentOrders__Charge_Amount__c = fee;
        newChangeFeeOrder.ChargentOrders__Charge_Date__c = '';
        newChangeFeeOrder.ARC_AgainstTheDefault__c = againstDefault;
        return newChangeFeeOrder;
    }

    private static ChargentOrders__ChargentOrder__c generateRecurringMonthlyOrder(ChargentOrders__ChargentOrder__c order, Id contractId, Id accountId, Decimal recurringAmmount){
        ChargentOrders__ChargentOrder__c newRecurringMonthlyOrder = generateOrder(order, contractId, accountId);
        newRecurringMonthlyOrder.ChargentOrders__Subtotal__c = recurringAmmount;
        newRecurringMonthlyOrder.ChargentOrders__Charge_Amount__c = recurringAmmount;
        newRecurringMonthlyOrder.ChargentOrders__Description__c = 'Recurring Monthly Order';
        newRecurringMonthlyOrder.ChargentOrders__Payment_Frequency__c = 'Monthly';
        newRecurringMonthlyOrder.ChargentOrders__Payment_Status__c = 'Stopped';
        newRecurringMonthlyOrder.ChargentOrders__Payment_Start_Date__c = System.today();
        newRecurringMonthlyOrder.ARC_FirstMonthPayed__c = order.ARC_FirstMonthPayed__c;
        
        return newRecurringMonthlyOrder;
    }

    private static ChargentOrders__ChargentOrder__c generateOrder(ChargentOrders__ChargentOrder__c order, Id contractId, Id accountId) {
        ChargentOrders__ChargentOrder__c newOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c = accountId,
            ARC_Contract__c = contractId,
            ChargentOrders__Billing_Address__c = order.ChargentOrders__Billing_Address__c,
            ChargentOrders__Billing_City__c = order.ChargentOrders__Billing_City__c,
            ChargentOrders__Billing_Email__c = order.ChargentOrders__Billing_Email__c,
            ChargentOrders__Billing_State__c = order.ChargentOrders__Billing_State__c,
            ChargentOrders__Billing_First_Name__c = order.ChargentOrders__Billing_First_Name__c,
            ChargentOrders__Gateway__c = order.ChargentOrders__Gateway__c,
            ChargentOrders__Billing_Last_Name__c = order.ChargentOrders__Billing_Last_Name__c,
            ChargentOrders__Payment_Method__c = order.ChargentOrders__Payment_Method__c,
            ChargentOrders__Billing_Zip_Postal__c = order.ChargentOrders__Billing_Zip_Postal__c,
            ChargentOrders__Card_Year_Indicator__c = order.ChargentOrders__Card_Year_Indicator__c,
            ChargentOrders__Card_Expiration_Year__c = order.ChargentOrders__Card_Expiration_Year__c,
            ChargentOrders__Card_Expiration_Month__c = order.ChargentOrders__Card_Expiration_Month__c,
            ChargentOrders__Card_Month_Indicator__c = order.ChargentOrders__Card_Month_Indicator__c,
            ChargentOrders__Card_Number__c = order.ChargentOrders__Card_Number__c,
            ChargentOrders__Card_Type__c = order.ChargentOrders__Card_Type__c,
            ChargentOrders__Card_Last_4__c = order.ChargentOrders__Card_Last_4__c,
            ChargentOrders__Bank_Account_Last_4__c = order.ChargentOrders__Bank_Account_Last_4__c,
            ChargentOrders__Bank_Routing_Number__c = order.ChargentOrders__Bank_Routing_Number__c,
            ChargentOrders__Bank_Name__c = order.ChargentOrders__Bank_Name__c,
            ChargentOrders__Bank_Account_Type__c = order.ChargentOrders__Bank_Account_Type__c,
            ChargentOrders__Bank_Account_Name__c = order.ChargentOrders__Bank_Account_Name__c,
            ChargentOrders__Bank_Account_Number__c = order.ChargentOrders__Bank_Account_Number__c,
            ChargentOrders__Tokenization__c = order.ChargentOrders__Tokenization__c,
            ChargentOrders__Manual_Charge__c = true
        );
        return newOrder;
    }

}