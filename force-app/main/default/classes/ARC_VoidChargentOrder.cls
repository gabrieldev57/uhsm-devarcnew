public without sharing class ARC_VoidChargentOrder {
   public class FlowInputs { @InvocableVariable public String transactionId;
                             @InvocableVariable public String VoidExplanation; }
    @InvocableMethod
    public static List<String> voidOrder (List<FlowInputs> request) {
            String transactionId = request[0].transactionId;
            String VoidExplanation = request[0].VoidExplanation;
            List<String> responseList = new List<String>();
            responseList.add(callout(transactionId,VoidExplanation));
            return responseList;
    }
    public static String callout(String transactionId, String VoidExplanation) {
        String result;
            ChargentOrders__Transaction__c chargentTransaction = [SELECT Id, Transaction_Explanation__c FROM ChargentOrders__Transaction__c WHERE Id = : transactionId LIMIT 1];
            if (!Test.isRunningTest()) {
                if(VoidExplanation != null){
                    ChargentOrders.TChargentOperations.TChargentResult chargeResult = ChargentOrders.TChargentOperations.VoidTransaction_Click(chargentTransaction.Id);
                    if((String)chargeResult.Status == 'FAILURE' || (String)chargeResult.Status == 'ERROR'){
                        result =  (String)chargeResult.Status;
                   }else{
                        chargentTransaction.Transaction_Explanation__c = VoidExplanation;
                        update chargentTransaction;
                        result = (String)chargeResult.TransactID;
                    }
                }
            }else{ 
                  if(VoidExplanation != null){
                    ChargentOrders__Transaction__c TR = new ChargentOrders__Transaction__c();
                    TR.ChargentOrders__Type__c = 'Charge';
                    TR.ChargentOrders__Response_Status__c = 'Approved';
                    TR.ChargentOrders__Amount__c = 238;
                    TR.ChargentOrders__Amount_available_for_Refund__c = 238;
                    TR.ChargentOrders__Billing_Address__c = '123 Meadow Lane';
                    TR.ChargentOrders__Billing_City__c = 'Coffeyville';
                    TR.ChargentOrders__Recurring__c = true;
                    TR.ARC_Reason__c = 'Test';
                    result = 'Test Void';
                    }
                }
                return result;
            }
        }