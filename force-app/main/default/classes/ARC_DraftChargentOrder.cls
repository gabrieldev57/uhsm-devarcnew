public without sharing class ARC_DraftChargentOrder { 
    
    public class FlowInputs { @InvocableVariable public String orderId; }
    
        @InvocableMethod
    public static List<String> chargeOrder (List<FlowInputs> request) {
            String orderId = request[0].orderId;
            List<String> responseList = new List<String>();
            responseList.add(callout(orderId));
            return responseList;
    }
        //Invocate charge click method on Chargent API with order Id as parameter
    public static String callout(string orderId) {
        ChargentOrders__ChargentOrder__c chargentOrder = [SELECT Id FROM ChargentOrders__ChargentOrder__c WHERE Id = : orderId LIMIT 1];
            if (!test.isRunningTest()) {
                ChargentOrders.TChargentOperations.TChargentResult chargeResult = ChargentOrders.TChargentOperations.ChargeOrder_ClickJSON(chargentOrder.Id);
                  return (String)(((Map<String, Object>)JSON.deserializeUntyped((String)chargeResult.responseData)).get('responseStatus'));
        
            } else {
                //Create the Transaction Record
                ChargentOrders__Transaction__c TR = new ChargentOrders__Transaction__c();
                TR.ChargentOrders__Type__c = 'Charge';
                TR.ChargentOrders__Response_Status__c = 'Approved';
                return 'Test';
            }       
    }
 }