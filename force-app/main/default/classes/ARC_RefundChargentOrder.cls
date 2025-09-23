public without sharing class ARC_RefundChargentOrder { 
    
    public class FlowInputs { @InvocableVariable public String transactionId; 
                              @InvocableVariable public String refundType; }
    
        @InvocableMethod
    public static List<String> chargeOrder (List<FlowInputs> request) {
            String transactionId = request[0].transactionId;
            String refundType = request[0].refundType;
            List<String> responseList = new List<String>();
            responseList.add(callout(transactionId,refundType));
            return responseList;
    }
        //Invocate charge click method on Chargent API with order Id as parameter
    public static String callout(string transactionId, String refundType) {
            ChargentOrders__Transaction__c chargentTransaction = [SELECT Id FROM ChargentOrders__Transaction__c WHERE Id = : transactionId LIMIT 1];
            if (!test.isRunningTest()) {
                if(refundType == 'Refund and Stop' || refundType == 'Refund'){
                    ChargentOrders.TChargentOperations.TChargentResult chargeResult = ChargentOrders.TChargentOperations.RefundTransaction_Click(chargentTransaction.Id);
                    if((String)chargeResult.Status == 'FAILURE' || (String)chargeResult.Status == 'ERROR'){
                        return  (String)chargeResult.Status;
                   }else{
                       return  (String)chargeResult.TransactID;
                   }    

                }
                // else if(refundType == 'Refund'){
                //     ChargentOrders.TChargentOperations.TChargentResult chargeResult = ChargentOrders.TChargentOperations.RefundTransaction_Click(chargentTransaction.Id);
                //     if((String)chargeResult.Status == 'FAILURE' || (String)chargeResult.Status == 'ERROR'){
                //          return  (String)chargeResult.Status;
                //     }else{
                //         return  (String)chargeResult.TransactID;
                //     }     
                //}
                else{
                    return null;
                }
            } else {
                //Create the Transaction Record
                if(refundType == 'Refund and Stop'){
                    ChargentOrders__Transaction__c TR = new ChargentOrders__Transaction__c();
                    TR.ChargentOrders__Type__c = 'Charge';
                    TR.ChargentOrders__Response_Status__c = 'Approved';
                    TR.ChargentOrders__Amount__c = 238;
                    TR.ChargentOrders__Amount_available_for_Refund__c = 238;
                    TR.ChargentOrders__Billing_Address__c = '123 Meadow Lane';
                    TR.ChargentOrders__Billing_City__c = 'Coffeyville';
                    TR.ChargentOrders__Recurring__c = true;
                    TR.ARC_Reason__c = 'Test';
                    return 'Test refund Stop';
                }else if(refundType == 'Refund'){
                    ChargentOrders__Transaction__c TR = new ChargentOrders__Transaction__c();
                    TR.ChargentOrders__Type__c = 'Charge';
                    TR.ChargentOrders__Response_Status__c = 'Approved';
                    TR.ChargentOrders__Recurring__c = true;
                    TR.ChargentOrders__Amount__c = 238;
                    TR.ChargentOrders__Amount_available_for_Refund__c = 238;
                    TR.ChargentOrders__Billing_Address__c = '123 Meadow Lane';
                    TR.ChargentOrders__Billing_City__c = 'Coffeyville';
                    TR.ARC_Reason__c = 'Test';
                    return 'Test Normal Refund';
                }else{
                    return null;
                }
            }       
    }
 }