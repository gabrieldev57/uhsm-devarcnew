trigger ARC_Transaction on ChargentOrders__Transaction__c (after update, after insert) {

    if(Trigger.isAfter && Trigger.isInsert){
        //FOR COMISSIONS
        ARC_TransactionHandler.createCommisionPayment(Trigger.new);
 
        //CREATES THE TLI FOR TRANSACTIONS OF TYPE CHARGE
        ARC_TransactionHandler.handleCreationTLI(Trigger.new);
    }

    if(Trigger.isAfter && Trigger.isUpdate){
        Map<Id, ChargentOrders__Transaction__c> newTransactionMap = Trigger.newMap;
        Map<Id, ChargentOrders__Transaction__c> oldTransactionMap = Trigger.oldMap;

        //FOR COMMISSIONS
        Map<String,Object> resultMap = (Map<String,Object>) ARC_TransactionHandler.getTransactionsToProcess(newTransactionMap, oldTransactionMap);
        //Considers the transactions created rejected but after update gets approved
        if(resultMap.containsKey('reprocessTransactions')){
            ARC_TransactionHandler.createCommisionPayment((List<ChargentOrders__Transaction__c>)resultMap.get('reprocessTransactions'));
        }
        //Creates the Refund & Voided Commission payments when there is a refund/void
        if(resultMap.containsKey('oldTransactionRefundTransactionMap')){
            ARC_TransactionHandler.generateRefundCommissionPayments((Map<Id,Id>)resultMap.get('oldTransactionRefundTransactionMap'));
        }

        //CREATE TLI FOR REFUNDS
        ARC_TransactionHandler.handleUpdateCreationTLI(newTransactionMap,oldTransactionMap);

    }
}