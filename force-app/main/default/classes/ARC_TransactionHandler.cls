/*******************************************************************
* @ClassName          :   ARC_TransactionHandler
* @Description        :   Handles the logic for the ARC_Transaction.trigger.
* @MethodName         :   getTransactionsToProcess, createCommisionPayment, ,generateRefundCommissionPayments, linkPromotionToTransaction, createTransactionLineItems
********************************************************************/
public without sharing class ARC_TransactionHandler {

    private static List<String> rtDiscountsTimeUsedAffected = new List<String>{'Temporary_Discount','Promotion_Discount'};

    /*******************************************************************
    * @MethodName         :   getTransactionsToProcess
    * @Description        :   Used to capture the transactions that needs to be considered for the commission payment creation. 
    ********************************************************************/
    public static Map<String,Object> getTransactionsToProcess (Map<Id,ChargentOrders__Transaction__c> newTrans, Map<Id,ChargentOrders__Transaction__c> oldTrans){
        List <ChargentOrders__Transaction__c> transactionToReprocess = new List <ChargentOrders__Transaction__c>();
        Map<Id,Id> oldTransactionRefundTransactionMap = new Map<Id,Id>();
        for(Id transId : newTrans.keySet()){
            String txRecordType = newTrans.get(transId).ARC_ContractRecordTypeName__c;
            if (txRecordType == 'ARC_IndividualAndFamily') {
                if(newTrans.get(transId).ChargentOrders__Response_Status__c =='Approved' && oldTrans.get(transId).ChargentOrders__Response_Status__c !='Approved' ){
                    transactionToReprocess.add(newTrans.get(transId));
                }
                else if(newTrans.get(transId).ARC_RefundedTransaction__c !=  null && oldTrans.get(transId).ARC_RefundedTransaction__c == null && (newTrans.get(transId).ChargentOrders__Type__c == 'Refund' || newTrans.get(transId).ChargentOrders__Type__c == 'Void' )){
                    oldTransactionRefundTransactionMap.put(newTrans.get(transId).ARC_RefundedTransaction__c,transId);
                }
            }
        }
        Map<String,Object> resultMap = new Map<String,Object>();
        if(transactionToReprocess.size()>0) resultMap.put('reprocessTransactions',transactionToReprocess);
        if(!oldTransactionRefundTransactionMap.isEmpty()) resultMap.put('oldTransactionRefundTransactionMap',oldTransactionRefundTransactionMap);
        return resultMap;
    }

    /*******************************************************************
    * @MethodName         :   createCommisionPayment
    * @Description        :   Handles the creation of a Commission Payment when a conrtibution is created. It could be the initial or recurring commission payment, or a refund.
    ********************************************************************/
    public static void createCommisionPayment (List<ChargentOrders__Transaction__c> triggerTransactions){
        // //Add approved transactions to a map grouped by chargent order id
        Map<Id, List<ChargentOrders__Transaction__c>> chargentTransactions = new Map<Id,List<ChargentOrders__Transaction__c>>();
        for (ChargentOrders__Transaction__c t: triggerTransactions) {
            String txRecordType = t.ARC_ContractRecordTypeName__c;
            if(t.ChargentOrders__Response_Status__c == 'Approved' &&  t.ChargentOrders__Type__c == 'Charge' && txRecordType == 'ARC_IndividualAndFamily'){
                String chargentId = t.ChargentOrders__Order__c;
                if (chargentTransactions.get(chargentId) == null) chargentTransactions.put(chargentId, new List<ChargentOrders__Transaction__c>());
                chargentTransactions.get(chargentId).add(t);
            }
        }
        //Get the Chargent Orders
        Map<Id, ChargentOrders__ChargentOrder__c> chargentOrders = new Map<Id, ChargentOrders__ChargentOrder__c>([
            SELECT Id, ARC_Contract__c, ARC_Contract__r.ARC_TotalPrice__c, ChargentOrders__Charge_Amount__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id IN :chargentTransactions.keySet() AND ChargentOrders__Description__c = 'Recurring Monthly Order'
        ]);
        if(chargentOrders.isEmpty() == false){
            Set<Id> contractIds = new Set<Id>();
            List<ChargentOrders__Transaction__c> transactions = new List<ChargentOrders__Transaction__c>();
            //Create a list of contract ids and a the final list of the transactions that meet the criteria to process create commission payments
            for (ChargentOrders__ChargentOrder__c c: chargentOrders.values()) {
                for(ChargentOrders__Transaction__c t:chargentTransactions.get(c.Id)){
                    if(c.ChargentOrders__Charge_Amount__c == Math.abs(t.ChargentOrders__Amount__c) || c.ChargentOrders__Charge_Amount__c == Math.abs(t.ChargentOrders__Amount__c)){
                        contractIds.add(c.ARC_Contract__c);
                        transactions.add(t);
                    } 
                }
            }
            Map<Id,ARC_Commission__c> contractCommission = new Map <Id,ARC_Commission__c>();
            if(contractIds.isEmpty() == false){
                //Get the Commisions and last Commission Payment diff than Refund
                Map<Id,ARC_Commission__c> commissions = new Map <Id,ARC_Commission__c> ([
                    SELECT Id,Contract__c,ARC_InitialCommission__c,ARC_RecurringCommission__c,ARC_ExistingContributions__c,ARC_MemberContribution__c,ARC_RefundsVoidedContributions__c,Contract__r.ARC_EffectiveDate__c,Contract__r.ARC_AwaitingActivationDate__c, (SELECT Id, Type__c, Amount__c FROM Commision_Payments__r WHERE (Type__c = 'Initial' OR Type__c = 'Recurring') ORDER BY CreatedDate Desc LIMIT 1)
                    FROM ARC_Commission__c 
                    WHERE Contract__c IN : contractIds AND Active__c = true
                ]);
                //Create a Map of ContractId - Commission
                for(ARC_Commission__c c : commissions.values()){
                    contractCommission.put(c.Contract__c, c);
                }
            }

            //Create Commission Payment records to insert
            Id commissionPaymentRecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Account Executive' AND SobjectType = 'ARC_Commission_Payment__c'].Id;
            List<ARC_Commission_Payment__c> commissionPaymentsToInsert = new List<ARC_Commission_Payment__c>();

            for (ChargentOrders__Transaction__c t : transactions) {
                ARC_Commission__c commission = contractCommission.get(((ChargentOrders__ChargentOrder__c)chargentOrders.get(t.ChargentOrders__Order__c)).ARC_Contract__c);
                if(commission != null){
                    Decimal existingContributions = commission.ARC_ExistingContributions__c != null ? commission.ARC_ExistingContributions__c:0;

                    //Create the Initial or Recurring Commission Payment.
                    ARC_Commission_Payment__c cpayment = new ARC_Commission_Payment__c();
                    if(commission.ARC_MemberContribution__c - commission.ARC_RefundsVoidedContributions__c == 0 && existingContributions == 0 ){
                        cpayment.Amount__c = commission.ARC_InitialCommission__c;
                        cpayment.Type__c = 'Initial';

                        //Calculate Commission Payment Date
                        if(commission.Contract__r.ARC_AwaitingActivationDate__c != null && (commission.Contract__r.ARC_AwaitingActivationDate__c.date() > commission.Contract__r.ARC_EffectiveDate__c)){
                            if(commission.Contract__r.ARC_AwaitingActivationDate__c.date().day() == 1 ) cpayment.ARC_PaymentDate__c = Date.newInstance(commission.Contract__r.ARC_AwaitingActivationDate__c.date().year(),commission.Contract__r.ARC_AwaitingActivationDate__c.date().month(), 15);
                            else cpayment.ARC_PaymentDate__c = Date.newInstance(commission.Contract__r.ARC_AwaitingActivationDate__c.date().year(),commission.Contract__r.ARC_AwaitingActivationDate__c.date().month(), 15).addMonths(1);
                        }
                        else{
                            if(commission.Contract__r.ARC_EffectiveDate__c.day() == 1 ) cpayment.ARC_PaymentDate__c = Date.newInstance(commission.Contract__r.ARC_EffectiveDate__c.year(),commission.Contract__r.ARC_EffectiveDate__c.month(), 15);
                            else cpayment.ARC_PaymentDate__c = Date.newInstance(commission.Contract__r.ARC_EffectiveDate__c.year(),commission.Contract__r.ARC_EffectiveDate__c.month(), 15).addMonths(1);
                        }
                    }
                    else{
                        cpayment.Amount__c = commission.ARC_RecurringCommission__c;
                        cpayment.Type__c = 'Recurring';
                        cpayment.ARC_PaymentDate__c = (t.CreatedDate.day() <= 15) ?
                        Date.newinstance(t.CreatedDate.year(), t.CreatedDate.month(), 15) :
                        Date.newinstance(t.CreatedDate.year(), t.CreatedDate.addMonths(1).month(), 15);
                    }
                    cpayment.RecordTypeId = commissionPaymentRecordTypeId;
                    cpayment.Commission__c = commission.Id;
                    cpayment.ARC_Transaction__c = t.Id;
                    commissionPaymentsToInsert.add(cpayment);
                }
            }
            Database.insert(commissionPaymentsToInsert, false);
        }
    }
    
    /*******************************************************************
    * @MethodName         :   generateRefundCommissionPayments
    * @Description        :   Creates the the Refund Commission payments if the refunded transaction already created the Commission Payment.
    ********************************************************************/
    public static void generateRefundCommissionPayments(Map<Id,Id> oldTransactionRefundTransactionMap){
        if(!oldTransactionRefundTransactionMap.isEmpty()){
            List<ARC_Commission_Payment__c> refundCommissionsToInsert = new List<ARC_Commission_Payment__c>();
            Set<Id> transactionsFound = new Set<Id>();
            //Get the Commission Payment created by the refunded transaction.
            List<ARC_Commission_Payment__c> commissionsToRefund = [SELECT Id,Amount__c, ARC_Transaction__c, RecordTypeId, Commission__c, ARC_PaymentDate__c  FROM ARC_Commission_Payment__c WHERE ARC_Transaction__c IN: oldTransactionRefundTransactionMap.keySet() AND ARC_Transaction__c != null];
            for(ARC_Commission_Payment__c commToRefund: commissionsToRefund){
                ARC_Commission_Payment__c refundCommPayment = new ARC_Commission_Payment__c();
                refundCommPayment.Amount__c = -commToRefund.Amount__c;
                refundCommPayment.RecordTypeId = commToRefund.RecordTypeId;
                refundCommPayment.Type__c = 'Refund & Void Chargeback';
                refundCommPayment.Commission__c = commToRefund.Commission__c;
                refundCommPayment.ARC_Transaction__c = oldTransactionRefundTransactionMap.get(commToRefund.ARC_Transaction__c);
                if(commToRefund.ARC_PaymentDate__c >= Date.today()) refundCommPayment.ARC_PaymentDate__c = commToRefund.ARC_PaymentDate__c;
                else{
                    refundCommPayment.ARC_PaymentDate__c = (Date.today().day() <= 15) ?
                        Date.newinstance(Date.today().year(), Date.today().month(), 15) :
                        Date.newinstance(Date.today().year(), Date.today().addMonths(1).month(), 15);
                }
                refundCommissionsToInsert.add(refundCommPayment);
                transactionsFound.add(commToRefund.ARC_Transaction__c);
            }
            if(!refundCommissionsToInsert.isEmpty()) Database.insert(refundCommissionsToInsert, false);

            //Get Commissions with Existing Cont >0 AND NO Commission Payments Exist.
            List<ChargentOrders__Transaction__c> transactionsWithoutCP = [SELECT Id, ChargentOrders__Order__c FROM ChargentOrders__Transaction__c WHERE ID NOT IN:transactionsFound AND ID IN:oldTransactionRefundTransactionMap.keySet()];

            if(!transactionsWithoutCP.isEmpty()){
                Set<Id> chargentOrderIds = new Set<Id>();
                for(ChargentOrders__Transaction__c t: transactionsWithoutCP) chargentOrderIds.add(t.ChargentOrders__Order__c);
                List<ARC_Commission__c> commissionsWithoutCP = [SELECT Id,ARC_ExistingContributions__c FROM ARC_Commission__c WHERE Contract__r.ARC_RecurringMonthlyOrder__c IN:chargentOrderIds AND ARC_ExistingContributions__c> 0];
                for(ARC_Commission__c  comm: commissionsWithoutCP){
                    comm.ARC_ExistingContributions__c = comm.ARC_ExistingContributions__c - 1;
                }
                update commissionsWithoutCP;
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   linkPromotionToTransaction
    * @Description        :   This method is to identify if there is a Promotion Discount applied to the transacions processed and populate the lookup field  in Transaction object
                            to Promotion Discount. Also handles the logic to count the used times of that Promotion Discount 
    ********************************************************************/
    public static void linkPromotionToTransaction(Map<Id,ChargentOrders__Transaction__c> transactionsMap) {
        //Fetch all Charges or Refunds plus all their lookup fields
        List<ChargentOrders__Transaction__c> transactions = [
        SELECT Id,
        ChargentOrders__Order__c,
        ChargentOrders__Amount__c,
        ChargentOrders__Order__r.ARC_Contract__c,
        ChargentOrders__Order__r.ARC_Contract__r.ARC_AppFeeOrder__c,
        ChargentOrders__Order__r.ARC_Contract__r.ARC_RecurringMonthlyOrder__c,
        ChargentOrders__Response_Status__c,
        ChargentOrders__Type__c,
        ChargentOrders__Order__r.ChargentOrders__Description__c
        FROM ChargentOrders__Transaction__c 
        WHERE Id IN: transactionsMap.keySet()
        AND ChargentOrders__Response_Status__c = 'Approved'
        AND (ChargentOrders__Type__c = 'Charge' OR ChargentOrders__Type__c = 'Refund')];
        //Construct a contract ids list to use later on to fetch promotion discount linked to those contracts
        List<Id> contractIds = new List<Id>();
        for (ChargentOrders__Transaction__c t : transactions) {
            contractIds.add(t.ChargentOrders__Order__r.ARC_Contract__c);
        }

        //Fetch all the promotion discounts into an indexed map to use later on
        Map<Id,ARC_PromotionDiscount__c> promotionsMap = new Map<Id,ARC_PromotionDiscount__c>([
            SELECT Id,ARC_Contract__c,ARC_TypeOfDiscount__c,ARC_TimesUsed__c,ARC_Active__c
            FROM ARC_PromotionDiscount__c
            WHERE ARC_Contract__c IN: contractIds ORDER BY CreatedDate DESC
        ]);

        //Construct a indexed map of contractId => List of discounts to use later on
        Map<Id, List<ARC_PromotionDiscount__c>> contractIdPromotions = new Map<Id, List<ARC_PromotionDiscount__c>>();
        for (Id promotionId : promotionsMap.keySet()) {
            ARC_PromotionDiscount__c p = promotionsMap.get(promotionId);

            if(p.ARC_Active__c == true){
                if (!contractIdPromotions.containsKey(p.ARC_Contract__c)) {
                    contractIdPromotions.put(p.ARC_Contract__c, new List<ARC_PromotionDiscount__c>());
                }
                contractIdPromotions.get(p.ARC_Contract__c).add(p);
            }
        }

        List<ChargentOrders__Transaction__c> transactionsToUpdate = new List<ChargentOrders__Transaction__c>();
        List<ARC_PromotionDiscount__c> promotionsToUpdate = new List<ARC_PromotionDiscount__c>();
        Map<Id, List<ChargentOrders__Transaction__c>> refundsMap = new Map<Id, List<ChargentOrders__Transaction__c>>();

        /* Iterate through transactions
        Case 1 - If the transaction is a charge and has a promotion record associated add +1 to ARC_TimesUsed__c in the promotion record and populate the lookup ARC_PromotionDiscount__c in the transaction record
        Case 2 - If the transaction is a refund add it to a indexed map of chargentOrderId => refund transaction records */
        for (ChargentOrders__Transaction__c t : transactions) {
            ARC_PromotionDiscount__c promotionRecord = contractIdPromotions.containsKey(t.ChargentOrders__Order__r.ARC_Contract__c) ? contractIdPromotions.get(t.ChargentOrders__Order__r.ARC_Contract__c)[0] : null;
            if (t.ChargentOrders__Type__c == 'Charge' && promotionRecord != null) {
                String orderDescription = t.ChargentOrders__Order__r.ChargentOrders__Description__c;
                Id appFeeOrderId = t.ChargentOrders__Order__r.ARC_Contract__r.ARC_AppFeeOrder__c;
                Id recurringMonthlyOrderId = t.ChargentOrders__Order__r.ARC_Contract__r.ARC_RecurringMonthlyOrder__c;
                String promotionDiscountType = promotionRecord.ARC_TypeOfDiscount__c;
        
                if (((t.ChargentOrders__Order__c == appFeeOrderId) && 
                    (promotionDiscountType == 'App Fee' && orderDescription == 'App Fee') ||
                    (promotionDiscountType == 'Change Fee' && orderDescription == 'Change Fee')) ||
                    ((t.ChargentOrders__Order__c == recurringMonthlyOrderId) && 
                    (promotionDiscountType == 'First Month Payment' || promotionDiscountType == 'Next X Number of Recurring Payments') &&
                    (orderDescription == 'Recurring Monthly Order'))
                )
            {
                promotionRecord.ARC_TimesUsed__c += 1;
                promotionsToUpdate.add(promotionRecord);

                t.ARC_PromotionDiscount__c = promotionRecord.Id;
                transactionsToUpdate.add(t);
            }
            } else if (t.ChargentOrders__Type__c == 'Refund') {
                if (!refundsMap.containsKey(t.ChargentOrders__Order__c)) {
                    refundsMap.put(t.ChargentOrders__Order__c,new List<ChargentOrders__Transaction__c>());
                }
                refundsMap.get(t.ChargentOrders__Order__c).add(t);
            }
        }

        // Query all charges from refunds map and match each refund to it's original charge, populate the refund with the same promotion discount as the charge and substract -1 to ARC_TimesUsed__c in the promotion record
        List<ChargentOrders__Transaction__c> chargeTransactions = [
            SELECT Id,
            ChargentOrders__Order__c,
            ChargentOrders__Amount__c,
            ARC_PromotionDiscount__c
            FROM ChargentOrders__Transaction__c
            WHERE ChargentOrders__Order__c IN: refundsMap.keySet()
            AND ChargentOrders__Type__c = 'Charge'
            AND ChargentOrders__Response_Status__c = 'Approved'
            ORDER BY LastModifiedDate DESC];

        Map<Id, List<ChargentOrders__Transaction__c>> chargesMap = new Map<Id, List<ChargentOrders__Transaction__c>>();

        for (ChargentOrders__Transaction__c ct : chargeTransactions) {
            if (!chargesMap.containsKey(ct.ChargentOrders__Order__c)) {
                chargesMap.put(ct.ChargentOrders__Order__c,new List<ChargentOrders__Transaction__c>());
            }
            chargesMap.get(ct.ChargentOrders__Order__c).add(ct);
        }
        
        for(Id refundOrderId : refundsMap.keySet()){
            List <ChargentOrders__Transaction__c> refund = refundsMap.get(refundOrderId);
            List<ChargentOrders__Transaction__c> charge = chargesMap.get(refundOrderId);

            for(ChargentOrders__Transaction__c ref: refund){
                for(ChargentOrders__Transaction__c ch: charge){
                    if (ch.ARC_PromotionDiscount__c != null && ref.ChargentOrders__Amount__c.abs() == ch.ChargentOrders__Amount__c.abs()){
                        ref.ARC_PromotionDiscount__c = ch.ARC_PromotionDiscount__c;
                        transactionsToUpdate.add(ref);
                        ARC_PromotionDiscount__c promotionRecord = promotionsMap.get(ch.ARC_PromotionDiscount__c);
                        promotionRecord.ARC_TimesUsed__c -= 1;
                        promotionsToUpdate.add(promotionRecord);
                        break;
                    }
                }
            }
        }
        update transactionsToUpdate;
        update promotionsToUpdate;
    }

    /*******************************************************************
    * @MethodName         :   createTransactionLineItems
    * @Description        :   This method is responsible for creating transaction line items based on the provided map of transactions from the trigger. It performs several 
    operations to gather necessary data and constructs a list of ARC_TransactionLineItem__c objects to be inserted into the database.
    If the Order is Recurring one transaction line item is created for each contract line item, otherwise a single transaction line item is created for App Fee, Change Fee
    One-time Fee and E123 Orders
    ********************************************************************/
    public static void createTransactionLineItems(Map<Id, ChargentOrders__Transaction__c> transactionNewMap) {
        List<ARC_TransactionLineItem__c> tliToCreate = new List<ARC_TransactionLineItem__c>();
        Set<Id> contractIds = new Set<Id>();
        Set<Id> refundedTransactionIds = new Set<Id>();
        Map<Id, ARC_PromotionDiscount__c> discountsToUpdateMap = new  Map<Id, ARC_PromotionDiscount__c>();


        List<ChargentOrders__Transaction__c> transactions = [
            SELECT Id, 
            Name, 
            ChargentOrders__Order__r.ARC_Contract__c,
            ChargentOrders__Amount__c,
            ChargentOrders__Type__c,
            ChargentOrders__Order__r.ChargentOrders__Description__c,
            ARC_Reason__c,
            ARC_RefundedTransaction__c,
            ChargentOrders__Order__c,
            ChargentOrders__Order__r.ARC_Contract__r.ARC_OneTimeFeeOrder__c,
            (SELECT Id, ARC_PromotionDiscount__c,ARC_Amount__c, ARC_PromotionDiscount__r.ARC_TimesUsed__c,ARC_PromotionDiscount__r.ARC_AmountToDiscountPerTransaction__c, Name FROM Transaction_Line_Items__r)
            FROM ChargentOrders__Transaction__c
            WHERE (ChargentOrders__Type__c = 'Charge' OR ChargentOrders__Type__c = 'Refund')
            AND ChargentOrders__Response_Status__c = 'Approved'
            AND Id IN :transactionNewMap.keySet()];

        // Collect contract IDs & refunded transaction IDs from transactions
        for (ChargentOrders__Transaction__c t : transactions) {
            contractIds.add(t.ChargentOrders__Order__r.ARC_Contract__c);
            if(t.ARC_RefundedTransaction__c != null) refundedTransactionIds.add(t.ARC_RefundedTransaction__c);
        }

        //Build a map of Contracts with the Related Discounts
        Map<Id,List<ARC_PromotionDiscount__c>> contractDiscountsMap = getContractDiscountMap(contractIds);

        //Build a Map of Refunded TLI on Recurring
        Map<Id, List<ARC_TransactionLineItem__c>> refundedRecurringTransactionTLIMap = new Map<Id, List<ARC_TransactionLineItem__c>>();

        // Retrieve and Map Refunded TLI on Recurring
        if (!refundedTransactionIds.isEmpty()) {
            
            for(ARC_TransactionLineItem__c tli: [SELECT Id, Name,ARC_Type__c,ARC_Amount__c,ARC_Product__c,ARC_PromotionDiscount__c,ARC_Transaction__c,ARC_PromotionDiscount__r.Name, ARC_PromotionDiscount__r.ARC_AmountToDiscountPerTransaction__c, ARC_PromotionDiscount__r.ARC_ApplyOver__c,ARC_PromotionDiscount__r.ARC_TimesUsed__c,ARC_PromotionDiscount__r.RecordType.DeveloperName FROM ARC_TransactionLineItem__c WHERE ARC_Transaction__c IN: refundedTransactionIds]){
                
                if(!refundedRecurringTransactionTLIMap.containsKey(tli.ARC_Transaction__c))refundedRecurringTransactionTLIMap.put(tli.ARC_Transaction__c,new List<ARC_TransactionLineItem__c>{tli});
                else refundedRecurringTransactionTLIMap.get(tli.ARC_Transaction__c).add(tli);

            }
        }

        //Build a Map of Refunded Transactions and TLI for Fees
        Map<Id, List<ARC_TransactionLineItem__c>> refundedTransactionTLIMap = getTransactionTLIWithDiscountsMap(refundedTransactionIds);

        //Build a Map of contract IDs to Contract Line Items
        Map<Id,List<vlocity_ins__ContractLineItem__c>> contractCLIMap = getContractCLIMap(contractIds);

        // Iterate over the transactions and create Transaction Line Items
        for (ChargentOrders__Transaction__c t : transactions) {
            Boolean isRefund = t.ChargentOrders__Type__c.equals('Refund');
            Boolean isOneTimeFee = (t?.ChargentOrders__Order__r?.ARC_Contract__r?.ARC_OneTimeFeeOrder__c <> null && t.ChargentOrders__Order__r.ARC_Contract__r.ARC_OneTimeFeeOrder__c == t.ChargentOrders__Order__c)?true:false;
            System.debug(isOneTimeFee);
            String transactionReason = t.ARC_Reason__c;
            String orderDescription = t.ChargentOrders__Order__r?.ChargentOrders__Description__c;
            Decimal transactionAmount = t.ChargentOrders__Amount__c;
            Id contractId = t.ChargentOrders__Order__r.ARC_Contract__c;
            List<ARC_PromotionDiscount__c> relatedDiscounts;
            List<ARC_TransactionLineItem__c> refundedTLIList;
            List<ARC_TransactionLineItem__c> refundedRecurringTLIList;


            if(!isRefund) {
                relatedDiscounts = contractDiscountsMap.containsKey(contractId)? contractDiscountsMap.get(contractId): new List<ARC_PromotionDiscount__c>();
            } else {
                refundedTLIList = refundedTransactionTLIMap.containsKey(t.ARC_RefundedTransaction__c)?refundedTransactionTLIMap.get(t.ARC_RefundedTransaction__c): new List<ARC_TransactionLineItem__c>();
                refundedRecurringTLIList = refundedRecurringTransactionTLIMap.containsKey(t.ARC_RefundedTransaction__c)?refundedRecurringTransactionTLIMap.get(t.ARC_RefundedTransaction__c): new List<ARC_TransactionLineItem__c>();
            }

            //FOR RECURRING ORDERS CONTRIBUTIONS
            if (t.ChargentOrders__Order__r.ChargentOrders__Description__c?.equals('Recurring Monthly Order') &&
                !transactionReason?.equals('Change Fee') && 
                !transactionReason?.equals('Change Fee Refund')) {

                List<vlocity_ins__ContractLineItem__c> cliList = contractCLIMap.get(contractId);

                if (cliList?.size() > 0) {
                    //Create TLI for Medical || SMART || AIDD || Fees (Smoker & Extra Dependent)
                    if(!isRefund){
                        for (vlocity_ins__ContractLineItem__c cli: cliList) {
                            crateTLIForCLIAndFees(t,cli,tliToCreate,IsRefund);
                        }
                    
                        //Create TLI for Discounts
                        if(!relatedDiscounts.isEmpty()) createDiscountRecurringTLI(t, tliToCreate, relatedDiscounts, discountsToUpdateMap);
                    }
                    else{
                        //Create Refund TLI for Medical || SMART || AIDD || Fees (Smoker & Extra Dependent)
                        for (ARC_TransactionLineItem__c refundTli : refundedRecurringTLIList) {

                            tliToCreate.add(new ARC_TransactionLineItem__c(
                                Name = refundTli?.Name,
                                ARC_Product__c = refundTli?.ARC_Product__c,
                                ARC_Type__c = refundTli?.ARC_Type__c,
                                ARC_PromotionDiscount__c = refundTli?.ARC_PromotionDiscount__c != null ? refundTli.ARC_PromotionDiscount__c : null,
                                ARC_Transaction__c = t?.Id,
                                ARC_Amount__c = -(refundTli?.ARC_Amount__c)
                            ));
                        }                        
                    }
                }

            /* App Fee Change, Change Fee, One Time-Fee refunds already have negative amount */
            } else if (orderDescription?.equals('App Fee') || transactionReason?.equals('Change Fee') || transactionReason?.equals('Change Fee Refund') || orderDescription?.contains('One-Time Fee') || isOneTimeFee){
                System.debug('inside otf validation');
                if(!isRefund) createAppChangeFeeTLIAndDiscountTLI(t, tliToCreate,relatedDiscounts,discountsToUpdateMap);
                else createAppChangeFeeRefundTLIAndDiscountRefundTLI(t, tliToCreate, refundedTLIList, discountsToUpdateMap);
            } 

        }
        
        if (!tliToCreate.isEmpty()) {
            try {
                insert tliToCreate;
            } catch (DmlException e) {
                throw new AuraHandledException('Error in ARC_TransactionHandler.createTransactionLineItems: '+ e.getMessage());
                
            }
        }
        if(!discountsToUpdateMap.isEmpty()){
            try {
                update discountsToUpdateMap.values();
            } catch (DmlException e) {
                throw new AuraHandledException('Error in ARC_TransactionHandler.Update Discounts: '+ e.getMessage());
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   crateTLIForCLIAndFees
    * @Description        :   Creates the TLI for the Contract Line Items and Fees (Smoker & Extra Dependent)
    ********************************************************************/
    public static void crateTLIForCLIAndFees(ChargentOrders__Transaction__c t,vlocity_ins__ContractLineItem__c cli,  List<ARC_TransactionLineItem__c> tliToCreate,Boolean isRefund){
        Boolean isCoreMedical = cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c == 'Medical';

        tliToCreate.add(new ARC_TransactionLineItem__c(
            Name = cli.vlocity_ins__Product2Id__r.Name,
            ARC_Product__c = cli.vlocity_ins__Product2Id__c,
            ARC_Type__c = cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
            ARC_Transaction__c = t.Id,
            ARC_Amount__c = isRefund ? -(cli.ARC_OriginalPrice__c):cli.ARC_OriginalPrice__c
        ));

        if(isCoreMedical){
            if(cli.ARC_SmokerFee__c != null && cli.ARC_SmokerFee__c> 0){
                tliToCreate.add(new ARC_TransactionLineItem__c(
                    Name = 'Smoker Fee',
                    ARC_Transaction__c = t.Id,
                    ARC_Amount__c = isRefund ? -(cli.ARC_SmokerFee__c): cli.ARC_SmokerFee__c,
                    ARC_Type__c = 'Fee'
                ));
            }
            if(cli.ARC_ExtraDependentFee__c != null && cli.ARC_ExtraDependentFee__c> 0){
                tliToCreate.add(new ARC_TransactionLineItem__c(
                    Name = 'Extra Dependent Fee',
                    ARC_Transaction__c = t.Id,
                    ARC_Amount__c = isRefund ? -(cli.ARC_ExtraDependentFee__c): cli.ARC_ExtraDependentFee__c,
                    ARC_Type__c = 'Fee'
                ));
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   consumeDiscountTimeUsed
    * @Description        :   Consume -1 the Time Used of the discount received by parameter
    ********************************************************************/
    public static void consumeDiscountTimeUsed(ARC_PromotionDiscount__c discount,Map<Id, ARC_PromotionDiscount__c> discountsToUpdateMap){
        if(rtDiscountsTimeUsedAffected.contains(discount.RecordType.DeveloperName)){
            if(discountsToUpdateMap.containsKey(discount.Id)){
                discountsToUpdateMap.get(discount.Id).ARC_TimesUsed__c = discountsToUpdateMap.get(discount.Id).ARC_TimesUsed__c + 1;
            }
            else {
                discount.ARC_TimesUsed__c = discount.ARC_TimesUsed__c + 1;
                discountsToUpdateMap.put(discount.Id, discount);
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   incrementDiscountTimeUsed
    * @Description        :   Increment +1 the Time Used of the discount received by parameter
    ********************************************************************/
    public static void incrementDiscountTimeUsed(ARC_TransactionLineItem__c refundTLI,Map<Id, ARC_PromotionDiscount__c> discountsToUpdateMap){
        if(rtDiscountsTimeUsedAffected.contains(refundTLI?.ARC_PromotionDiscount__r?.RecordType?.DeveloperName)){
            if(discountsToUpdateMap.containsKey(refundTLI?.ARC_PromotionDiscount__c)){
                ARC_PromotionDiscount__c discount = discountsToUpdateMap.get(refundTLI?.ARC_PromotionDiscount__c);
                discount.ARC_TimesUsed__c = discount.ARC_TimesUsed__c-1;
                discountsToUpdateMap.put(discount.Id,discount);
            }
            else{
                ARC_PromotionDiscount__c discount = new ARC_PromotionDiscount__c();
                discount.Id = refundTLI?.ARC_PromotionDiscount__c;
                discount.ARC_TimesUsed__c = refundTLI?.ARC_PromotionDiscount__r.ARC_TimesUsed__c -1;
                discountsToUpdateMap.put(discount.Id, discount);
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   getContractDiscountMap
    * @Description        :   Build a Map of Contract IDs and the related Discounts that are activated
    ********************************************************************/
    public static Map<Id,List<ARC_PromotionDiscount__c>> getContractDiscountMap (Set<Id> contractIds){
        Map<Id,List<ARC_PromotionDiscount__c>> resultMap = new Map<Id,List<ARC_PromotionDiscount__c>>();
        for(ARC_PromotionDiscount__c discount: [SELECT Id, ARC_Contract__c, Name, createdDate, ARC_AmountToDiscountPerTransaction__c, ARC_ApplyOver__c, ARC_Active__c, ARC_TimesUsed__c, RecordType.DeveloperName FROM ARC_PromotionDiscount__c WHERE ARC_Active__c = true  AND ARC_Contract__c IN :contractIds ORDER BY CreatedDate ASC]){
            if(!resultMap.containsKey(discount.ARC_Contract__c)) resultMap.put(discount.ARC_Contract__c, new List<ARC_PromotionDiscount__c>{discount});
            else resultMap.get(discount.ARC_Contract__c).add(discount);
        }
        return resultMap;
    }

    /*******************************************************************
    * @MethodName         :   getTransactionTLIWithDiscountsMap
    * @Description        :   Build a Map of Transaction IDs and their related Transaction line Items linked to a Discount
    ********************************************************************/
    public static Map<Id, List<ARC_TransactionLineItem__c>> getTransactionTLIWithDiscountsMap (Set<Id> transactionIds){
        Map<Id, List<ARC_TransactionLineItem__c>> resultMap = new Map<Id, List<ARC_TransactionLineItem__c>>();
        for(ARC_TransactionLineItem__c tli: [SELECT ARC_PromotionDiscount__c,ARC_PromotionDiscount__r.ARC_TimesUsed__c ,ARC_PromotionDiscount__r.Name ,ARC_PromotionDiscount__r.ARC_AmountToDiscountPerTransaction__c, ARC_PromotionDiscount__r.ARC_ApplyOver__c, ARC_PromotionDiscount__r.RecordType.DeveloperName,ARC_Transaction__c FROM ARC_TransactionLineItem__c WHERE ARC_Transaction__c IN: transactionIds AND ARC_PromotionDiscount__c <> null]){
            if(!resultMap.containsKey(tli.ARC_Transaction__c))resultMap.put(tli.ARC_Transaction__c,new List<ARC_TransactionLineItem__c>{tli});
            else resultMap.get(tli.ARC_Transaction__c).add(tli);
        }
        return resultMap;
    }

    /*******************************************************************
    * @MethodName         :   getContractCLIMap
    * @Description        :   Build a Map of Contracts IDs and their related Contract line Items
    ********************************************************************/
    public static Map<Id,List<vlocity_ins__ContractLineItem__c>> getContractCLIMap(Set<Id> contractIds){
        Map<Id,List<vlocity_ins__ContractLineItem__c>> resultMap = new Map<Id,List<vlocity_ins__ContractLineItem__c>>();
        for (vlocity_ins__ContractLineItem__c cli : [SELECT vlocity_ins__ContractId__c, vlocity_ins__UnitPrice__c, vlocity_ins__Product2Id__c, vlocity_ins__Product2Id__r.Name, vlocity_ins__Product2Id__r.vlocity_ins__Type__c, ARC_OriginalPrice__c, ARC_SmokerFee__c, ARC_ExtraDependentFee__c FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__ContractId__c IN :contractIds AND vlocity_ins__Product2Id__r.vlocity_ins__Type__c != null AND vlocity_ins__UnitPrice__c != null AND vlocity_ins__UnitPrice__c > 0 ORDER BY vlocity_ins__ProductType__c DESC ]) {
            if (!resultMap.containsKey(cli.vlocity_ins__ContractId__c)) resultMap.put(cli.vlocity_ins__ContractId__c, new List<vlocity_ins__ContractLineItem__c>{cli});
            else resultMap.get(cli.vlocity_ins__ContractId__c).add(cli);
        }
        return resultMap;
    }

    /*******************************************************************
    * @MethodName         :   createDiscountRecurringTLI
    * @Description        :   Creates the TLI for Discounts used only for Recurring Charge Orders
    ********************************************************************/
    public static void createDiscountRecurringTLI(ChargentOrders__Transaction__c t, List<ARC_TransactionLineItem__c> tliToCreate ,List<ARC_PromotionDiscount__c> relatedDiscounts, Map<Id, ARC_PromotionDiscount__c> discountsToUpdateMap){
        for(ARC_PromotionDiscount__c discount: relatedDiscounts){
            if(discount.ARC_ApplyOver__c != 'App Fee' && discount.ARC_ApplyOver__c !='Change Fee'){
                tliToCreate.add(new ARC_TransactionLineItem__c(
                    Name = discount.Name,
                    ARC_PromotionDiscount__c = discount.Id,
                    ARC_Transaction__c = t.Id,
                    ARC_Amount__c = -(discount.ARC_AmountToDiscountPerTransaction__c),
                    ARC_Type__c = discount.ARC_ApplyOver__c
                ));
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   createDiscountRecurringRefundTLI
    * @Description        :   Creates the Refund TLI for Discounts used only for Recurring Orders refunds.
    ********************************************************************/
    public static void createDiscountRecurringRefundTLI(ChargentOrders__Transaction__c t, List<ARC_TransactionLineItem__c> tliToCreate ,List<ARC_TransactionLineItem__c> refundedTLIList, Map<Id, ARC_PromotionDiscount__c> discountsToUpdateMap){
        for(ARC_TransactionLineItem__c refundTLI: refundedTLIList){
            tliToCreate.add(new ARC_TransactionLineItem__c(
                    Name = refundTLI?.ARC_PromotionDiscount__r?.Name,
                    ARC_PromotionDiscount__c = refundTLI?.ARC_PromotionDiscount__c,
                    ARC_Transaction__c = t?.Id,
                    ARC_Amount__c = refundTLI?.ARC_PromotionDiscount__r?.ARC_AmountToDiscountPerTransaction__c,
                    ARC_Type__c = refundTLI?.ARC_PromotionDiscount__r?.ARC_ApplyOver__c
                ));
        }
    }

    /*******************************************************************
    * @MethodName         :   createAppChangeFeeTLIAndDiscountTLI
    * @Description        :   Creates the App Fees and Change Fees TLI and the Dicounts TLI
    ********************************************************************/
    public static void createAppChangeFeeTLIAndDiscountTLI(ChargentOrders__Transaction__c t, List<ARC_TransactionLineItem__c> tliToCreate, List<ARC_PromotionDiscount__c> relatedDiscounts,Map<Id, ARC_PromotionDiscount__c> discountsToUpdateMap){
        Decimal transAmount = t.ChargentOrders__Amount__c;
        String transReason =  t.ARC_Reason__c;
        String orderReason =  t.ChargentOrders__Order__r.ChargentOrders__Description__c;
        for(ARC_PromotionDiscount__c discount: relatedDiscounts){
            if(discount.ARC_ApplyOver__c == orderReason){
                tliToCreate.add(new ARC_TransactionLineItem__c(
                    ARC_Transaction__c = t.Id,
                    Name = discount.Name,
                    ARC_PromotionDiscount__c= discount.Id,
                    ARC_Amount__c =  -(discount.ARC_AmountToDiscountPerTransaction__c),
                    ARC_Type__c = orderReason
                ));
                transAmount = transAmount+discount.ARC_AmountToDiscountPerTransaction__c;
            }
        }
        tliToCreate.add(new ARC_TransactionLineItem__c(
            ARC_Transaction__c = t.Id,
            Name = transReason,
            ARC_Amount__c = transAmount,
            ARC_Type__c = (!orderReason.contains('App Fee') && !orderReason.contains('Change Fee'))? 'Fee':orderReason
        ));
        System.debug(tliToCreate);
    }

    /*******************************************************************
    * @MethodName         :   createAppChangeFeeRefundTLIAndDiscountRefundTLI
    * @Description        :   Creates the App Fees and Change Fees Refund TLI and the Dicounts Refund TLI
    ********************************************************************/
    public static void createAppChangeFeeRefundTLIAndDiscountRefundTLI(ChargentOrders__Transaction__c t, List<ARC_TransactionLineItem__c> tliToCreate, List<ARC_TransactionLineItem__c> refundedTLIList, Map<Id, ARC_PromotionDiscount__c> discountsToUpdateMap){
        Decimal transAmount = t.ChargentOrders__Amount__c;
        String transReason =  t.ARC_Reason__c;
        String orderReason =  t.ChargentOrders__Order__r.ChargentOrders__Description__c;
        for(ARC_TransactionLineItem__c refundTLI: refundedTLIList){
            tliToCreate.add(new ARC_TransactionLineItem__c(
                    Name = refundTLI?.ARC_PromotionDiscount__r?.Name,
                    ARC_PromotionDiscount__c = refundTLI?.ARC_PromotionDiscount__c,
                    ARC_Transaction__c = t?.Id,
                    ARC_Amount__c = refundTLI?.ARC_PromotionDiscount__r?.ARC_AmountToDiscountPerTransaction__c,
                    ARC_Type__c = refundTLI?.ARC_PromotionDiscount__r?.ARC_ApplyOver__c
                ));
                transAmount = transAmount - refundTLI?.ARC_PromotionDiscount__r?.ARC_AmountToDiscountPerTransaction__c;
        }
        tliToCreate.add(new ARC_TransactionLineItem__c(
            ARC_Transaction__c = t.Id,
            Name = transReason,
            ARC_Amount__c = transAmount,
            ARC_Type__c = (!orderReason.contains('App Fee') && !orderReason.contains('Change Fee'))? 'Fee':orderReason
        ));
    }

    /*******************************************************************
    * @MethodName         :   handleCreationTLI
    * @Description        :   Excecutes the creation of TLI only for Transactions of type Charge after insert
    ********************************************************************/
    public static void handleCreationTLI(List<ChargentOrders__Transaction__c> newTransaction){
        Map<Id, ChargentOrders__Transaction__c> chargeTransactionNewMap = new Map<Id, ChargentOrders__Transaction__c>();
        
        for(ChargentOrders__Transaction__c transactionRecord: newTransaction){
            String txRecordType = transactionRecord.ARC_ContractRecordTypeName__c;
            if(transactionRecord.ChargentOrders__Type__c == 'Charge' && transactionRecord.ChargentOrders__Response_Status__c == 'Approved' && txRecordType == 'ARC_IndividualAndFamily') {
                chargeTransactionNewMap.put(transactionRecord.Id,transactionRecord);
            }
        }
        if(!chargeTransactionNewMap.isEmpty()) ARC_TransactionHandler.createTransactionLineItems(chargeTransactionNewMap);
    }

    /*******************************************************************
    * @MethodName         :   handleUpdateCreationTLI
    * @Description        :   Excecutes the creation of TLI only for Transactions of type Refund after the refunded transaction is linked 
    ********************************************************************/
    public static void handleUpdateCreationTLI(Map<Id,ChargentOrders__Transaction__c> newTransactionMap, Map<Id,ChargentOrders__Transaction__c> oldTransactionMap){
        Map<Id, ChargentOrders__Transaction__c> refundTransactionsMap = new Map<Id, ChargentOrders__Transaction__c>();

        for(Id tId: newTransactionMap.keySet()){
            ChargentOrders__Transaction__c transactionRecord = newTransactionMap.get(tId);
            String txRecordType = transactionRecord.ARC_ContractRecordTypeName__c;
            if(txRecordType == 'ARC_IndividualAndFamily') {
                if(transactionRecord.ChargentOrders__Type__c == 'Refund' && transactionRecord.ChargentOrders__Response_Status__c == 'Approved' && transactionRecord.ARC_RefundedTransaction__c <> null && oldTransactionMap.get(tId).ARC_RefundedTransaction__c == null ){
                    refundTransactionsMap.put(transactionRecord.Id,transactionRecord);
                }
            }
        }
        if(!refundTransactionsMap.isEmpty())ARC_TransactionHandler.createTransactionLineItems(refundTransactionsMap);
    }

    // Recursion prevention flag for updateCoveragePaidThrough
    private static Boolean coveragePaidThroughExecuted = false;

    /*******************************************************************
    * @MethodName         :   updateCoveragePaidThrough
    * @Description        :   Updates Contract.ARC_CoveragePaidThrough__c based on approved transactions
    *                          and handles first month payment logic
    ********************************************************************/
    public static void updateCoveragePaidThrough(List<ChargentOrders__Transaction__c> newTransactions, Map<Id, ChargentOrders__Transaction__c> oldTransactionsMap) {
        if (coveragePaidThroughExecuted) return;
        coveragePaidThroughExecuted = true;

        Set<Id> orderIds = new Set<Id>();
        Map<Id, ChargentOrders__Transaction__c> transactionsToProcess = new Map<Id, ChargentOrders__Transaction__c>();
        Set<Id> revokedChargeIds = new Set<Id>();

        for (ChargentOrders__Transaction__c trans : newTransactions) {
            if (trans.ChargentOrders__Order__c == null) continue;

            String oldStatus = oldTransactionsMap != null ? oldTransactionsMap.get(trans.Id).ChargentOrders__Response_Status__c : null;
            String newStatus = trans.ChargentOrders__Response_Status__c;

            if (newStatus == 'Approved' && oldStatus != 'Approved') {
                orderIds.add(trans.ChargentOrders__Order__c);
                transactionsToProcess.put(trans.Id, trans);
            } else if (oldStatus == 'Approved' && newStatus != 'Approved' && trans.ChargentOrders__Type__c == 'Charge') {
                orderIds.add(trans.ChargentOrders__Order__c);
                revokedChargeIds.add(trans.Id);
                transactionsToProcess.put(trans.Id, trans);
            }
        }

        if (orderIds.isEmpty()) {
            coveragePaidThroughExecuted = false;
            return;
        }

        Map<Id, ChargentOrders__ChargentOrder__c> ordersMap = new Map<Id, ChargentOrders__ChargentOrder__c>([
            SELECT Id, ARC_Contract__c, ARC_Contract__r.ARC_CoveragePaidThrough__c,
                   ARC_Contract__r.RecordType.DeveloperName, ARC_Contract__r.ARC_PaymentFrequency__c,
                   ARC_Contract__r.ARC_EffectiveDate__c, ARC_Contract__r.Status,
                   ARC_FirstMonthPayed__c, ARC_Contract__r.ARC_NextInvoiceCoverageStart__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id IN :orderIds
              AND ARC_Contract__c != null
              AND ARC_Contract__r.RecordType.DeveloperName = 'ARC_SmallGroup'
        ]);

        // ── FIX: build contractId → order map once (O(n) instead of O(n²)) ──
        Map<Id, ChargentOrders__ChargentOrder__c> orderByContract = new Map<Id, ChargentOrders__ChargentOrder__c>();
        for (ChargentOrders__ChargentOrder__c o : ordersMap.values()) {
            orderByContract.put(o.ARC_Contract__c, o);
        }

        // Build map of Contract ID to list of Transactions
        Map<Id, List<ChargentOrders__Transaction__c>> contractTransactionsMap = new Map<Id, List<ChargentOrders__Transaction__c>>();
        for (ChargentOrders__Transaction__c trans : transactionsToProcess.values()) {
            ChargentOrders__ChargentOrder__c order = ordersMap.get(trans.ChargentOrders__Order__c);
            if (order != null) {
                Id contractId = order.ARC_Contract__c;
                if (!contractTransactionsMap.containsKey(contractId)) {
                    contractTransactionsMap.put(contractId, new List<ChargentOrders__Transaction__c>());
                }
                contractTransactionsMap.get(contractId).add(trans);
            }
        }

        List<Contract> contractsToUpdate = new List<Contract>();
        List<ChargentOrders__ChargentOrder__c> ordersToUpdate = new List<ChargentOrders__ChargentOrder__c>();
        List<ChargentOrders__Transaction__c> transactionsToUpdate = new List<ChargentOrders__Transaction__c>();

        for (Id contractId : contractTransactionsMap.keySet()) {
            // ── FIX: direct map lookup instead of inner loop ──
            ChargentOrders__ChargentOrder__c order = orderByContract.get(contractId);
            if (order == null) continue;

            Date currentCoveragePaidThrough = order.ARC_Contract__r.ARC_CoveragePaidThrough__c;
            Date newCoveragePaidThrough = currentCoveragePaidThrough;
            String paymentFrequency = order.ARC_Contract__r.ARC_PaymentFrequency__c;
            Date effectiveDate = order.ARC_Contract__r.ARC_EffectiveDate__c;
            String contractStatus = order.ARC_Contract__r.Status;
            Boolean isFirstMonthPayed = order.ARC_FirstMonthPayed__c != null ? order.ARC_FirstMonthPayed__c : false;

            Boolean needsOrderUpdate = false;
            Boolean needsContractStatusUpdate = false;

            for (ChargentOrders__Transaction__c trans : contractTransactionsMap.get(contractId)) {
                if (trans.ChargentOrders__Type__c == 'Charge' && !revokedChargeIds.contains(trans.Id)) {
                    newCoveragePaidThrough = processCharge(trans, newCoveragePaidThrough);
                    
                    if (!isFirstMonthPayed) {
                        isFirstMonthPayed = true;
                        needsOrderUpdate = true;
                        transactionsToUpdate.add(new ChargentOrders__Transaction__c(
                            Id = trans.Id,
                            ChargentOrders__Recurring__c = false
                        ));
                        if (contractStatus == 'Awaiting First Payment') {
                            needsContractStatusUpdate = true;
                        }
                    }
                    
                } else if (trans.ChargentOrders__Type__c == 'Refund' || trans.ChargentOrders__Type__c == 'Void' || revokedChargeIds.contains(trans.Id)) {
                    newCoveragePaidThrough = processRefund(newCoveragePaidThrough, paymentFrequency);
                    
                    if (effectiveDate != null && newCoveragePaidThrough != null && newCoveragePaidThrough < effectiveDate) {
                        newCoveragePaidThrough = null;
                        if (isFirstMonthPayed) {
                            isFirstMonthPayed = false;
                            needsOrderUpdate = true;
                        }
                        if (contractStatus == 'Awaiting Activation') {
                            needsContractStatusUpdate = true;
                        }
                    }
                }
            }

            if (newCoveragePaidThrough != currentCoveragePaidThrough || needsContractStatusUpdate) {
                Contract contractUpdate = new Contract(
                    Id = contractId,
                    ARC_CoveragePaidThrough__c = newCoveragePaidThrough
                );
                
                if (needsContractStatusUpdate) {
                    if (contractStatus == 'Awaiting First Payment') {
                        contractUpdate.Status = 'Awaiting Activation';
                    } else if (contractStatus == 'Awaiting Activation' && newCoveragePaidThrough == null) {
                        contractUpdate.Status = 'Awaiting First Payment';
                    }
                }
                
                contractsToUpdate.add(contractUpdate);
            }
            
            if (needsOrderUpdate) {
                ordersToUpdate.add(new ChargentOrders__ChargentOrder__c(
                    Id = order.Id,
                    ARC_FirstMonthPayed__c = isFirstMonthPayed
                ));
            }
        }

        if (!contractsToUpdate.isEmpty()) {
            update contractsToUpdate;

            Set<Id> updatedContractIds = new Set<Id>();
            for (Contract c : contractsToUpdate) updatedContractIds.add(c.Id);

            // Bulk calls — single set of queries for all updated contracts
            ARC_ContractBillingService.evaluatePolicyEligibilityForContracts(updatedContractIds);
            ARC_ContractBillingService.recalculateNextBillAmount(updatedContractIds);
        }
        
        if (!ordersToUpdate.isEmpty()) update ordersToUpdate;
        if (!transactionsToUpdate.isEmpty()) update transactionsToUpdate;

        coveragePaidThroughExecuted = false;
    }

    /*******************************************************************
    * @MethodName         :   processCharge
    * @Description        :   Process Charge transaction and return new coverage date
    ********************************************************************/
    private static Date processCharge(ChargentOrders__Transaction__c trans, Date currentCoverage) {
        if (trans.ARC_Cover_To__c != null) {
            if (currentCoverage == null || trans.ARC_Cover_To__c > currentCoverage) {
                return trans.ARC_Cover_To__c;
            }
        }
        return currentCoverage;
    }

    /*******************************************************************
    * @MethodName         :   processRefund
    * @Description        :   Process Refund transaction and return new coverage date (move backwards)
    ********************************************************************/
    private static Date processRefund(Date currentCoverage, String paymentFrequency) {
        if (currentCoverage == null) return null;

        Integer monthsInPeriod = 1;
        if (paymentFrequency == 'Quarterly') {
            monthsInPeriod = 3;
        } else if (paymentFrequency == 'Annual') {
            monthsInPeriod = 12;
        }

        // Use boundary math to avoid day-loss bugs
        // 30/04 → +1d → 01/05 → -1m → 01/04 → -1d → 31/03
        return currentCoverage.addDays(1).addMonths(-monthsInPeriod).addDays(-1);
    }

    /*******************************************************************
    * @MethodName         :   addMonthsToCoverage
    * @Description        :   Helper method to add/subtract months from coverage date based on frequency
    ********************************************************************/
    private static Date addMonthsToCoverage(Date coverageDate, Integer multiplier, String paymentFrequency) {
        if (coverageDate == null) return null;
        
        if (paymentFrequency == 'Monthly') {
            return coverageDate.addMonths(1 * multiplier);
        } else if (paymentFrequency == 'Quarterly') {
            return coverageDate.addMonths(3 * multiplier);
        } else if (paymentFrequency == 'Annual') {
            return coverageDate.addYears(1 * multiplier);
        }
        return coverageDate.addMonths(1 * multiplier);
    }
}