global without sharing class ARC_ChargentApexAPI implements vlocity_ins.VlocityOpenInterface {
    

        // OS Method
        public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
            if ( methodName == 'charge' ) {
                charge(inputMap, outputMap, options);
            } 
            return true;
        }
        
        //Invocate charge click method on Chargent API with order Id as parameter
        public static void charge(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
            System.debug('test charge');
            String chargentOrderId = (String) inputMap.get('ChargentOrderId');
                if ( !Test.isRunningTest() ) {
                        ChargentOrders.TChargentOperations.TChargentResult chargeResult = ChargentOrders.TChargentOperations.ChargeOrder_Click(chargentOrderId);
                        outputMap.put('chargeResult', (String)(((Map<String, Object>)JSON.deserializeUntyped((String)chargeResult.responseData)).get('responseStatus'))); 
                }
                else {
                    //Create the Transaction Record
                    ChargentOrders__Transaction__c TR = new ChargentOrders__Transaction__c();
                    TR.ChargentOrders__Order__c = chargentOrderId;
                    TR.ChargentOrders__Type__c = 'Charge';
                    TR.ChargentOrders__Response_Status__c = 'Approved';
                }
        }


    // Flow method
    @InvocableMethod(label='Take Chargent Payment' description='Takes the Chargent Order payment from the Id' category='Chargent Order')
    
    public static List<ChargentOrders__ChargentOrder__c> chargeOrder (List<ChargentOrders__ChargentOrder__c> orders) {
        for (ChargentOrders__ChargentOrder__c order : orders) {
            draftOrder(order.Id);
        }
        return orders;
    }

    @future (callout=true)
    public static void draftOrder (String order)
    {
        if (!test.isRunningTest()) {
            ChargentOrders.TChargentOperations.TChargentResult chargeResult = ChargentOrders.TChargentOperations.ChargeOrder_ClickJSON(order);
    
        } else {
            //Create the Transaction Record
            ChargentOrders__Transaction__c TR = new ChargentOrders__Transaction__c();
            TR.ChargentOrders__Type__c = 'Charge';
            TR.ChargentOrders__Response_Status__c = 'Approved';
        }        
      
    }

}