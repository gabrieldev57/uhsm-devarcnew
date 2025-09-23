public class ARC_CreateRecurringOrder {
    @InvocableMethod(label= 'Create Chargent Order' category= 'Chargent Order')
    public static List<ChargentOrders__ChargentOrder__c> createChargentOrder(List<ChargentOrders__ChargentOrder__c> oldChargentId){
        
         System.debug('oldChargentId: ' + oldChargentId);
		 System.debug('oldChargentId: SIZE ' + oldChargentId.size());

        Set<Id> OldChargentsId = new Set<Id>();
        
        for (ChargentOrders__ChargentOrder__c chId : oldChargentId) {
            OldChargentsId.add(chId.Id);
        }
        
        List<ChargentOrders__ChargentOrder__c> oldChargents = [Select Id, 
                                                        ARC_Contract__c,
                                                        ChargentOrders__Account__c,ChargentOrders__Bank_Account_Last_4__c,ChargentOrders__Bank_Account_Name__c,
                                                        ChargentOrders__Bank_Account_Type__c,ChargentOrders__Bank_Name__c,ChargentOrders__Billing_Address__c,
                                                        ChargentOrders__Billing_City__c,ChargentOrders__Billing_Email__c,ChargentOrders__Billing_First_Name__c,
                                                        ChargentOrders__Billing_Last_Name__c,ChargentOrders__Billing_State__c,ChargentOrders__Billing_Zip_Postal__c,
                                                        ChargentOrders__Card_Last_4__c,ChargentOrders__Card_Month_Indicator__c,ChargentOrders__Card_Type__c,
                                                        ChargentOrders__Card_Year_Indicator__c,ChargentOrders__Charge_Amount__c,ChargentOrders__Description__c,
                                                        ChargentOrders__Gateway__c,ChargentOrders__Payment_Frequency__c,ChargentOrders__Payment_Method__c,
                                                        ChargentOrders__Payment_Status__c,ChargentOrders__Payment_Stop__c,ChargentOrders__Subtotal__c,
                                                        ChargentOrders__Tokenization__c, ARC_Contract__r.ARC_TotalPrice__c, ChargentOrders__Card_Number__c,
                                                        ChargentOrders__Bank_Account_Number__c,ChargentOrders__Bank_Routing_Number__c
                                                        FROM ChargentOrders__ChargentOrder__c WHERE Id IN :OldChargentsId];
        
        
        List<ChargentOrders__ChargentOrder__c> newList = new List<ChargentOrders__ChargentOrder__c>();
        for(ChargentOrders__ChargentOrder__c oldChargent : oldChargents){

            ChargentOrders__ChargentOrder__c newChargent = new ChargentOrders__ChargentOrder__c();
            newChargent.ARC_Contract__c = oldChargent.ARC_Contract__c;
            newChargent.ChargentOrders__Account__c = oldChargent.ChargentOrders__Account__c;
            newChargent.ChargentOrders__Bank_Account_Type__c = oldChargent.ChargentOrders__Bank_Account_Type__c;
            newChargent.ChargentOrders__Bank_Name__c = oldChargent.ChargentOrders__Bank_Name__c;
            newChargent.ChargentOrders__Billing_Address__c = oldChargent.ChargentOrders__Billing_Address__c;
            newChargent.ChargentOrders__Billing_City__c = oldChargent.ChargentOrders__Billing_City__c;
            newChargent.ChargentOrders__Billing_Email__c = oldChargent.ChargentOrders__Billing_Email__c;
            newChargent.ChargentOrders__Billing_First_Name__c = oldChargent.ChargentOrders__Billing_First_Name__c;
            newChargent.ChargentOrders__Billing_Last_Name__c = oldChargent.ChargentOrders__Billing_Last_Name__c;
            newChargent.ChargentOrders__Billing_State__c = oldChargent.ChargentOrders__Billing_State__c;
            newChargent.ChargentOrders__Billing_Zip_Postal__c = oldChargent.ChargentOrders__Billing_Zip_Postal__c;
            newChargent.ChargentOrders__Card_Last_4__c = oldChargent.ChargentOrders__Card_Last_4__c;
            newChargent.ChargentOrders__Card_Expiration_Month__c = oldChargent.ChargentOrders__Card_Month_Indicator__c;
            newChargent.ChargentOrders__Card_Type__c = oldChargent.ChargentOrders__Card_Type__c;
            newChargent.ChargentOrders__Card_Expiration_Year__c = oldChargent.ChargentOrders__Card_Year_Indicator__c;
            newChargent.ChargentOrders__Charge_Amount__c = oldChargent.ARC_Contract__r.ARC_TotalPrice__c;
            newChargent.ChargentOrders__Description__c = 'Recurring Monthly Order';
            newChargent.ChargentOrders__Gateway__c = oldChargent.ChargentOrders__Gateway__c;
            newChargent.ChargentOrders__Payment_Frequency__c = 'Monthly';
            newChargent.ChargentOrders__Payment_Method__c = oldChargent.ChargentOrders__Payment_Method__c;
            newChargent.ChargentOrders__Payment_Status__c = 'Stopped';
            newChargent.ChargentOrders__Payment_Stop__c = 'Unending';
            newChargent.ChargentOrders__Subtotal__c = oldChargent.ARC_Contract__r.ARC_TotalPrice__c;
            newChargent.ChargentOrders__Tokenization__c = oldChargent.ChargentOrders__Tokenization__c;
            newChargent.ChargentOrders__Bank_Account_Last_4__c = oldChargent.ChargentOrders__Bank_Account_Last_4__c;
            newChargent.ChargentOrders__Bank_Account_Name__c =  oldChargent.ChargentOrders__Bank_Account_Name__c;
            newChargent.ChargentOrders__Card_Number__c = oldChargent.ChargentOrders__Card_Number__c;
            newChargent.ChargentOrders__Bank_Account_Number__c = oldChargent.ChargentOrders__Bank_Account_Number__c;
            newChargent.ChargentOrders__Bank_Routing_Number__c = oldChargent.ChargentOrders__Bank_Routing_Number__c;
            newChargent.ChargentOrders__Manual_Charge__c = true;
            newList.add(newChargent);
        }

        insert newList;

        Map<Id, Id> conIdNewOrder = new Map<Id, Id>();
        for(ChargentOrders__ChargentOrder__c ord : newList){
            conIdNewOrder.put(ord.ARC_Contract__c, ord.Id);            
        }

        List<Contract> cons = [SELECT Id, ARC_RecurringMonthlyOrder__c FROM Contract WHERE Id IN :conIdNewOrder.keySet()];

        for(Contract con : cons){
            con.ARC_RecurringMonthlyOrder__c = conIdNewOrder.get(con.Id);
        }

        update cons;

        system.debug(newList.size());
        return newList;
        
    }

}