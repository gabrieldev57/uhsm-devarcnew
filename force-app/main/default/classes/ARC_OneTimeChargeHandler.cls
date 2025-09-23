global with sharing class ARC_OneTimeChargeHandler implements vlocity_ins.VlocityOpenInterface{
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        switch on methodName {
            when 'createOneTimeCharge' {
                createOneTimeCharge(inputMap, outputMap, options);
            }
            when 'leaveOrderAsBefore' {
                leaveOrderAsBefore(inputMap, outputMap, options);
            
            }
        }
        if ( methodName == 'createOneTimeCharge' ) {
            
        } 
        return true;
    }

    /*
        "ChargentOrder": {
            "ChargentOrders__Description__c": "%AddOneTimeCharge:Reason%",
            "ChargentOrders__Subtotal__c": "%AddOneTimeCharge:ChargeFeeAmount%",
            "OneTimeId": "%ChargentOrder:OneTimeId%",
            "Id": "%ChargentOrder:Id%"
        },
    */

    public static void createOneTimeCharge(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        Boolean useRecurringOrder = (Boolean) inputMap.get('useRecurringOrder');
        Double chargeFeeAmount = (Double) inputMap.get('chargeFeeAmount');
        String reason = (String) inputMap.get('reason');
        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c();
        Contract contract;
        
        Map<String,Object> orderBackup = new Map<String,Object>();
        Map<String,Object> contractOrders = (Map<String,Object>) inputMap.get('contractOrders');
        Id existingOrderId = getExisingOrderId(contractOrders, useRecurringOrder);
        

        //UPDATE/CREATE ORDER

        order = getOrderById(existingOrderId);
        if (useRecurringOrder) {
            orderBackup = new Map<String,Object>{
                'Id' => order.Id,
                'ChargentOrders__Subtotal__c' => order.ChargentOrders__Subtotal__c,
                'ChargentOrders__Charge_Amount__c' => order.ChargentOrders__Charge_Amount__c,
                'ChargentOrders__Description__c' => order.ChargentOrders__Description__c
            };
        }
        if(contractOrders.get('ARC_OneTimeFeeOrder__c') == null && !useRecurringOrder){
            order = generateNewOrder(order);
        }
        order = chargeOneTimeFee(order, chargeFeeAmount, reason);

        upsert order;

        if(contractOrders.get('ARC_OneTimeFeeOrder__c') == null && !useRecurringOrder){
            contract = new Contract(Id = order.ARC_Contract__c, ARC_OneTimeFeeOrder__c = order.Id);
            update contract;
        }

        outputMap.put('chargentOrderId', order.Id);
        outputMap.put('orderBackup', orderBackup);
    }

    private static ChargentOrders__ChargentOrder__c generateNewOrder(ChargentOrders__ChargentOrder__c order) {
        ChargentOrders__ChargentOrder__c newOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c = order.ChargentOrders__Account__c,
            ARC_Contract__c = order.ARC_Contract__c,
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
            ChargentOrders__Manual_Charge__c = order.ChargentOrders__Manual_Charge__c
        );
        return newOrder;
    }

    private static ChargentOrders__ChargentOrder__c getOrderById(Id orderId){
        return [
            SELECT 
                Id,
                ChargentOrders__Account__c,
                ARC_Contract__c,
                ChargentOrders__Billing_Address__c,
                ChargentOrders__Billing_City__c,
                ChargentOrders__Billing_Email__c,
                ChargentOrders__Billing_State__c,
                ChargentOrders__Billing_First_Name__c,
                ChargentOrders__Gateway__c,
                ChargentOrders__Billing_Last_Name__c,
                ChargentOrders__Payment_Method__c,
                ChargentOrders__Billing_Zip_Postal__c,
                ChargentOrders__Card_Year_Indicator__c,
                ChargentOrders__Card_Expiration_Year__c,
                ChargentOrders__Card_Expiration_Month__c,
                ChargentOrders__Card_Month_Indicator__c,
                ChargentOrders__Card_Number__c,
                ChargentOrders__Card_Type__c,
                ChargentOrders__Card_Last_4__c,
                ChargentOrders__Bank_Account_Last_4__c,
                ChargentOrders__Bank_Routing_Number__c,
                ChargentOrders__Bank_Name__c,
                ChargentOrders__Bank_Account_Type__c,
                ChargentOrders__Bank_Account_Name__c,
                ChargentOrders__Bank_Account_Number__c,
                ChargentOrders__Tokenization__c,
                ChargentOrders__Manual_Charge__c,
                ChargentOrders__Subtotal__c,
                ChargentOrders__Charge_Amount__c,
                ChargentOrders__Description__c
            FROM ChargentOrders__ChargentOrder__c 
            WHERE Id = :orderId LIMIT 1
        ];
    }

    private static Id getExisingOrderId(Map<String,Object> contractOrders, Boolean useRecurringOrder){
        if(useRecurringOrder){
            return (Id)contractOrders.get('ARC_RecurringMonthlyOrder__c');
        }else{
            if(contractOrders.get('ARC_OneTimeFeeOrder__c') != null){
                return (Id)contractOrders.get('ARC_OneTimeFeeOrder__c');
            }else if(contractOrders.get('ARC_RecurringMonthlyOrder__c') != null){
                return (Id)contractOrders.get('ARC_RecurringMonthlyOrder__c');
            }else if(contractOrders.get('ARC_AppFeeOrder__c') != null){
                return (Id)contractOrders.get('ARC_AppFeeOrder__c');
            }
            return null;
        }
    }

    private static ChargentOrders__ChargentOrder__c chargeOneTimeFee(ChargentOrders__ChargentOrder__c order, Double chargeFeeAmount, String reason){
        order.ChargentOrders__Subtotal__c = chargeFeeAmount;
        order.ChargentOrders__Charge_Amount__c = chargeFeeAmount;
        if (reason!=null && reason != '') {
            order.ChargentOrders__Description__c = reason;
        }
        return order;
    }

    public static void leaveOrderAsBefore(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String,Object> orderBackup = (Map<String,Object>) inputMap.get('orderBackup');
        update new ChargentOrders__ChargentOrder__c(
            Id = (Id)orderBackup.get('Id'),
            ChargentOrders__Subtotal__c = (Decimal)orderBackup.get('ChargentOrders__Subtotal__c'),
            ChargentOrders__Charge_Amount__c = (Decimal)orderBackup.get('ChargentOrders__Charge_Amount__c'),
            ChargentOrders__Description__c = (String)orderBackup.get('ChargentOrders__Description__c')
        );
    }






}