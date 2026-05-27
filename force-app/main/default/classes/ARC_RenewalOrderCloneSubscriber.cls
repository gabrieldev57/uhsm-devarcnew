public without sharing class ARC_RenewalOrderCloneSubscriber {

    public static void run(List<ARC_RenewalOrderClone__e> events) {
        Map<Id, Id> sourceToNew = new Map<Id, Id>();
        for (ARC_RenewalOrderClone__e evt : events) {
            if (evt.SourceOrderId__c != null && evt.NewOrderId__c != null) {
                sourceToNew.put((Id) evt.SourceOrderId__c, (Id) evt.NewOrderId__c);
            }
        }
        if (sourceToNew.isEmpty()) return;

        // Query encrypted fields from source orders (Integration User must have View Encrypted Data)
        Map<Id, ChargentOrders__ChargentOrder__c> sourcesById = new Map<Id, ChargentOrders__ChargentOrder__c>([
            SELECT Id,
                   ChargentOrders__Card_Number__c,
                   ChargentOrders__Bank_Account_Number__c,
                   ChargentOrders__Bank_Routing_Number__c,
                   ChargentOrders__Tokenization__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id IN :sourceToNew.keySet()
        ]);

        // Query new orders with ALL existing fields so the update is not a partial write
        Set<Id> newOrderIds = new Set<Id>(sourceToNew.values());
        Map<Id, ChargentOrders__ChargentOrder__c> newOrdersById = new Map<Id, ChargentOrders__ChargentOrder__c>([
            SELECT Id,
                   ChargentOrders__Payment_Method__c,
                   ChargentOrders__Gateway__c,
                   ChargentOrders__Account__c,
                   ChargentOrders__Billing_Address__c,
                   ChargentOrders__Billing_City__c,
                   ChargentOrders__Billing_State__c,
                   ChargentOrders__Billing_Zip_Postal__c,
                   ChargentOrders__Billing_Email__c,
                   ChargentOrders__Billing_First_Name__c,
                   ChargentOrders__Billing_Last_Name__c,
                   ChargentOrders__Bank_Name__c,
                   ChargentOrders__Bank_Account_Name__c,
                   ChargentOrders__Bank_Account_Type__c,
                   ChargentOrders__Bank_Account_Last_4__c,
                   ChargentOrders__Card_Expiration_Month__c,
                   ChargentOrders__Card_Expiration_Year__c,
                   ChargentOrders__Card_Type__c,
                   ChargentOrders__Card_Last_4__c,
                   ChargentOrders__Charge_Amount__c,
                   ChargentOrders__Subtotal__c,
                   ChargentOrders__Payment_Frequency__c,
                   ChargentOrders__Payment_Status__c,
                   ChargentOrders__Payment_Stop__c,
                   ChargentOrders__Description__c,
                   ChargentOrders__Manual_Charge__c,
                   ChargentOrders__Card_Number__c,
                   ChargentOrders__Bank_Account_Number__c,
                   ChargentOrders__Bank_Routing_Number__c,
                   ChargentOrders__Tokenization__c,
                   ARC_Contract__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id IN :newOrderIds
        ]);

        List<ChargentOrders__ChargentOrder__c> toUpdate = new List<ChargentOrders__ChargentOrder__c>();
        for (Id srcId : sourceToNew.keySet()) {
            Id newId = sourceToNew.get(srcId);
            if (!sourcesById.containsKey(srcId) || !newOrdersById.containsKey(newId)) continue;

            ChargentOrders__ChargentOrder__c src = sourcesById.get(srcId);
            ChargentOrders__ChargentOrder__c newOrd = newOrdersById.get(newId);

            // Write encrypted fields onto the already-populated new order record
            newOrd.ChargentOrders__Card_Number__c         = src.ChargentOrders__Card_Number__c;
            newOrd.ChargentOrders__Bank_Account_Number__c = src.ChargentOrders__Bank_Account_Number__c;
            newOrd.ChargentOrders__Bank_Routing_Number__c = src.ChargentOrders__Bank_Routing_Number__c;
            newOrd.ChargentOrders__Tokenization__c        = src.ChargentOrders__Tokenization__c;
            toUpdate.add(newOrd);
        }

        if (!toUpdate.isEmpty()) update toUpdate;
    }
}