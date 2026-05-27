public without sharing class ARC_DraftChargentOrder { 
    
    public class FlowInputs { 
        @InvocableVariable public String orderId;
        @InvocableVariable public String transactionExp; 
    }
    
    public class FlowOutputs {
        @InvocableVariable public String responseStatus;
        @InvocableVariable public String errorMessage;
        @InvocableVariable public Boolean isSuccess;
    }
    
    @InvocableMethod
    public static List<FlowOutputs> chargeOrder(List<FlowInputs> request) {
        List<FlowOutputs> results = new List<FlowOutputs>();
        FlowOutputs output = new FlowOutputs();
       
        
        try {
            if (request == null || request.isEmpty()) {
                throw new ChargentException('Request list cannot be null or empty');
            }
            
            String orderId = request[0].orderId;
            String transactionExp = request[0].transactionExp;
            
            // Validate inputs
            if (String.isBlank(orderId)) {
                throw new ChargentException('Order ID is required');
            }
            
            output.responseStatus = callout(orderId, transactionExp);
            
            // Check if Chargent actually succeeded
            if (output.responseStatus == 'Approved') {
                output.isSuccess = true;
            } else {
                output.isSuccess = false;
                // errorMessage will be set by the exception handler if there's a responseMessage
            }
            
        } catch (Exception e) {
            output.isSuccess = false;
            output.errorMessage = e.getMessage(); // User-friendly message only
            String fullError = e.getMessage() + ' | ' + e.getStackTraceString();
            System.debug(LoggingLevel.ERROR, 'ARC_DraftChargentOrder Error: ' + fullError);
            
            // Don't throw error. Return error details to Flow so it can handle gracefully
        }
        
        results.add(output);
        return results;
    }
    
    @TestVisible
    static String handleChargentResponse(Id orderId, String responseJson, String transactionExp) {
        
        // Query for transaction record created by Chargent
        List<ChargentOrders__Transaction__c> transactions = [
            SELECT Id, Transaction_Explanation__c 
            FROM ChargentOrders__Transaction__c 
            WHERE ChargentOrders__Order__c = :orderId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
        
        if (transactions.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'Transaction record not found for Order: ' + orderId);
            throw new ChargentException('Transaction record not found for Order: ' + orderId);
        }
        
        System.debug(LoggingLevel.INFO, 'Transaction found for Order: ' + orderId + ', Transaction Id: ' + transactions[0].Id);
        ChargentOrders__Transaction__c chargentTransaction = transactions[0];
        
        chargentTransaction.Transaction_Explanation__c = transactionExp;
        update chargentTransaction;
        
        // Safe JSON parsing
        if (String.isBlank(responseJson)) {
            throw new ChargentException('Empty response from Chargent API');
        }
        
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(responseJson);
        
        if (!parsed.containsKey('responseStatus')) {
            throw new ChargentException('Response missing responseStatus field. Full response: ' + responseJson);
        }
        
        String responseStatus = (String) parsed.get('responseStatus');
        
        // If status is not Approved, throw exception with responseMessage if available
        if (responseStatus != 'Approved') {
            String errorMsg = 'Charge failed with status: ' + responseStatus;
            if (parsed.containsKey('responseMessage')) {
                String responseMsg = (String) parsed.get('responseMessage');
                if (String.isNotBlank(responseMsg)) {
                    errorMsg = responseMsg;
                }
            }
            throw new ChargentException(errorMsg);
        }
        
        return responseStatus;
    }
    
    //Invocate charge click method on Chargent API with order Id as parameter
    public static String callout(String orderId, String transactionExp) {
        System.debug('=== STARTING CALLOUT for Order: ' + orderId);
        
        // Validate order exists first
        List<ChargentOrders__ChargentOrder__c> orders = [
            SELECT Id 
            FROM ChargentOrders__ChargentOrder__c 
            WHERE Id = :orderId 
            LIMIT 1
        ];
        
        if (orders.isEmpty()) {
            throw new ChargentException('Chargent Order not found: ' + orderId);
        }
        
        ChargentOrders__ChargentOrder__c chargentOrder = orders[0];
        
        if (!Test.isRunningTest()) {
            System.debug('=== BEFORE ChargeOrder_ClickJSON - Limits: ' + Limits.getDMLStatements() + '/' + Limits.getLimitDMLStatements());
            
            ChargentOrders.TChargentOperations.TChargentResult chargeResult =
                ChargentOrders.TChargentOperations.ChargeOrder_ClickJSON(chargentOrder.Id);

            System.debug('=== AFTER ChargeOrder_ClickJSON');
            System.debug('=== ChargeResult: ' + chargeResult);
            System.debug('=== Response Data: ' + chargeResult.responseData);
            
            return handleChargentResponse(
                chargentOrder.Id,
                (String) chargeResult.responseData,
                transactionExp
            );
        } else {
            // Test context 
            // The @TestSetup already created the transaction to simulate what the Chargent package does in production. 
            // The test context doesn't need to duplicate that - it just needs to return a mock response.
            return 'Approved';
        }       
    }
    
    public class ChargentException extends Exception {}
}