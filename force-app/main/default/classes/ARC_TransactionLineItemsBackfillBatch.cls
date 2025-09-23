global class ARC_TransactionLineItemsBackfillBatch implements Database.Batchable<sObject>{

    public Set<Id> transactionIds = new Set<Id>();

    global Database.QueryLocator start(Database.BatchableContext BC){

        if (this.transactionIds.size() > 0) {
            return Database.getQueryLocator([
            SELECT Id
            FROM ChargentOrders__Transaction__c
            WHERE (ChargentOrders__Type__c = 'Charge' OR ChargentOrders__Type__c = 'Refund' OR  ChargentOrders__Type__c = 'Chargeback') AND ChargentOrders__Response_Status__c = 'Approved' AND Id IN :transactionIds]);
        }else{
            return Database.getQueryLocator([
            SELECT Id
            FROM ChargentOrders__Transaction__c
            WHERE (ChargentOrders__Type__c = 'Charge' OR ChargentOrders__Type__c = 'Refund' OR  ChargentOrders__Type__c = 'Chargeback') AND ChargentOrders__Response_Status__c = 'Approved']);
        }
        
    }
 
    global void execute(Database.BatchableContext BC, List<ChargentOrders__Transaction__c> transactionsData){
        List<ChargentOrders__Transaction__c> transactions = [
            SELECT Id,
            Name,
            ChargentOrders__Order__r.ARC_Contract__c,
            ChargentOrders__Amount__c,
            ChargentOrders__Type__c,
            ChargentOrders__Order__r.ChargentOrders__Description__c,
            ChargentOrders__Gateway_Date__c,
            ARC_Reason__c,
            (SELECT Id FROM Transaction_Line_Items__r)
            FROM ChargentOrders__Transaction__c WHERE Id IN: transactionsData
            AND ARC_Reason__c != null
            AND ChargentOrders__Amount__c != null
            AND ChargentOrders__Amount__c != 0
            ];
        Set<Id> contractIds = new Set<Id>();
        for (ChargentOrders__Transaction__c t : transactions) {
            if (t.Transaction_Line_Items__r.size() > 0) continue; // CONTINUE if transaction line items are already created
            // Collect contract IDs from transactions
            contractIds.add(t.ChargentOrders__Order__r.ARC_Contract__c);
        }
        // Collect active Heathy Discount records from contracts
        Map<Id,List<Healthy_Discount__c>> contractListHealthyDiscount = new Map<Id,List<Healthy_Discount__c>>();
        for(Healthy_Discount__c hd : [SELECT Contract__c, Old_Contract_Price__c,Healthy_Discount_Price__c,Is_Active__c,Date_Approved__c,Calculate_expiry_date__c,Healthy_Status__c FROM Healthy_Discount__c WHERE Contract__c IN :contractIds AND Healthy_Status__c = 'Approved' AND Old_Contract_Price__c != null AND Healthy_Discount_Price__c != null]){
            if (!contractListHealthyDiscount.containsKey(hd.Contract__c)) {
                contractListHealthyDiscount.put(hd.Contract__c, new List<Healthy_Discount__c>());
            }
            contractListHealthyDiscount.get(hd.Contract__c).add(hd);
        }
        // Query Contract Line Items and build a map of contract IDs to Contract Line Items
        Map<Id,List<vlocity_ins__ContractLineItem__c>> contractListCli = new Map<Id,List<vlocity_ins__ContractLineItem__c>>();
        for (vlocity_ins__ContractLineItem__c cli : [SELECT vlocity_ins__ContractId__c, vlocity_ins__UnitPrice__c, vlocity_ins__Product2Id__c, vlocity_ins__Product2Id__r.Name, vlocity_ins__Product2Id__r.vlocity_ins__Type__c FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__ContractId__c IN :contractIds AND vlocity_ins__Product2Id__r.vlocity_ins__Type__c != null AND vlocity_ins__UnitPrice__c != null AND vlocity_ins__UnitPrice__c > 0 ORDER BY vlocity_ins__ProductType__c DESC]) {
            if (!contractListCli.containsKey(cli.vlocity_ins__ContractId__c)) {
                contractListCli.put(cli.vlocity_ins__ContractId__c, new List<vlocity_ins__ContractLineItem__c>());
            }
            contractListCli.get(cli.vlocity_ins__ContractId__c).add(cli);

        }
        List<Id> transactionsWithNoMatch = new List<Id>();
        List<ARC_TransactionLineItem__c> tliToCreate = new List<ARC_TransactionLineItem__c>();
        for (ChargentOrders__Transaction__c t : transactions) {
            String contractId = t.ChargentOrders__Order__r.ARC_Contract__c;
            Boolean isRefund = (t.ChargentOrders__Type__c.equals('Refund') || t.ChargentOrders__Type__c.equals('Chargeback'));
            List<vlocity_ins__ContractLineItem__c> cliList = contractListCli.get(contractId);
            List<Healthy_Discount__c> healthyDiscounts = (List<Healthy_Discount__c>)contractListHealthyDiscount.get(contractId);
            Decimal transactionAmount = t.ChargentOrders__Amount__c;
            String transactionReason = t.ARC_Reason__c;
            String transactionType = t.ChargentOrders__Type__c;
            String orderDescription = t.ChargentOrders__Order__r?.ChargentOrders__Description__c;
            if(String.isNotBlank(orderDescription)){
                if (orderDescription.equals('Recurring Monthly Order') && !transactionReason?.equals('Change Fee') && !transactionReason?.equals('Change Fee Refund')) {

                    if (cliList?.size() > 0) {
                        Decimal currentCorePrice = 0, sumOfAncillaries = 0;
                        for (vlocity_ins__ContractLineItem__c cli: cliList){
                            if (cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c == 'Medical'){
                                currentCorePrice = cli.vlocity_ins__UnitPrice__c;
                            } else if (cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c == 'Ancillary'){
                                sumOfAncillaries += cli.vlocity_ins__UnitPrice__c;
                            }
                        }
                        Decimal oldCorePrice = 0, priceWithDiscount = 0, healthyDiscountPrice=null;
                        if (healthyDiscounts != null) {
                            for (Healthy_Discount__c hd : healthyDiscounts) {
                                    oldCorePrice = hd.Old_Contract_Price__c;
                                    priceWithDiscount = hd.Healthy_Discount_Price__c;
                                    healthyDiscountPrice =  priceWithDiscount - oldCorePrice;
                            }

                            if (oldCorePrice+sumOfAncillaries == transactionAmount.abs()) { //Transaccion with healthy discount record but with old core price
                                for (vlocity_ins__ContractLineItem__c cli: cliList) {
                                    Boolean isCoreMedical = cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c == 'Medical';
                                    Decimal amount = isCoreMedical? oldCorePrice : cli.vlocity_ins__UnitPrice__c;
                                    amount = isRefund ? -amount : amount;

            
                                    tliToCreate.add(new ARC_TransactionLineItem__c(
                                        Name = cli.vlocity_ins__Product2Id__r.Name,
                                        ARC_Product__c = cli.vlocity_ins__Product2Id__c,
                                        ARC_Type__c = cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                                        ARC_Transaction__c = t.Id,
                                        ARC_Amount__c = amount
                                    ));
                                }
                            } else if(priceWithDiscount+sumOfAncillaries == transactionAmount.abs()){ // Transaccion with Discounted Price
                                for (vlocity_ins__ContractLineItem__c cli: cliList) {
                                    Boolean isCoreMedical = cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c == 'Medical';
                                    Decimal amount = isCoreMedical? oldCorePrice : cli.vlocity_ins__UnitPrice__c;
                                    healthyDiscountPrice = isCoreMedical? healthyDiscountPrice: null;
                                    healthyDiscountPrice = isRefund && healthyDiscountPrice != null ? - healthyDiscountPrice: healthyDiscountPrice;
                                    
            
                                    tliToCreate.add(new ARC_TransactionLineItem__c(
                                        Name = cli.vlocity_ins__Product2Id__r.Name,
                                        ARC_Product__c = cli.vlocity_ins__Product2Id__c,
                                        ARC_Type__c = cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                                        ARC_Transaction__c = t.Id,
                                        ARC_Amount__c = isRefund ? -amount : amount,
                                        ARC_HealthyDiscount__c = healthyDiscountPrice
                                    ));
                                    // Add TLI for the discount if is applied
                                    if(isCoreMedical){
                                        tliToCreate.add(new ARC_TransactionLineItem__c(
                                            Name = 'Healthy Discount',
                                            ARC_Product__c = cli.vlocity_ins__Product2Id__c,
                                            ARC_Type__c = 'Medical',
                                            ARC_Transaction__c = t.Id,
                                            ARC_Amount__c = healthyDiscountPrice
                                        ));
                                    }
                                } 
                            } 
                        }
                        else if (healthyDiscounts == null && (currentCorePrice + sumOfAncillaries == transactionAmount.abs())) { // Transaccion without a healthy discount record
                            for (vlocity_ins__ContractLineItem__c cli: cliList) {
                                Decimal amount = isRefund ? -cli.vlocity_ins__UnitPrice__c : cli.vlocity_ins__UnitPrice__c;
        
                                tliToCreate.add(new ARC_TransactionLineItem__c(
                                    Name = cli.vlocity_ins__Product2Id__r.Name,
                                    ARC_Product__c = cli.vlocity_ins__Product2Id__c,
                                    ARC_Type__c = cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                                    ARC_Transaction__c = t.Id,
                                    ARC_Amount__c = amount
                                ));
                            }
                        } else {
                            transactionsWithNoMatch.add(t.Id);
                        }
                    }
                } else if (orderDescription?.equals('App Fee') || transactionReason?.equals('Change Fee') || transactionReason?.equals('Change Fee Refund') || orderDescription?.contains('One-Time Fee')){
                    tliToCreate.add(new ARC_TransactionLineItem__c(
                        ARC_Transaction__c = t.Id,
                        Name = transactionReason,
                        ARC_Amount__c = transactionAmount
                    ));
                } else if (orderDescription.contains('Chargent Order to Hold E123 Transactions Only')){
                    
                    if (cliList?.size() > 0) {
                        Decimal currentCorePrice = 0, sumOfAncillaries = 0;
                        vlocity_ins__ContractLineItem__c currentCore;
                        Map<Decimal, vlocity_ins__ContractLineItem__c> priceProduct = new Map <Decimal, vlocity_ins__ContractLineItem__c>();
                        for (vlocity_ins__ContractLineItem__c cli: cliList){
                            priceProduct.put(cli.vlocity_ins__UnitPrice__c, cli);
                            if (cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c == 'Medical'){
                                currentCore = cli;
                                currentCorePrice = cli.vlocity_ins__UnitPrice__c;
                            } else if (cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c == 'Ancillary'){
                                sumOfAncillaries += cli.vlocity_ins__UnitPrice__c;
                            }
                        }

                        if (healthyDiscounts != null) {
                            Decimal oldCorePrice = 0, priceWithDiscount = 0;
                            for (Healthy_Discount__c hd : healthyDiscounts) {
                                oldCorePrice = hd.Old_Contract_Price__c;
                                priceWithDiscount = hd.Healthy_Discount_Price__c;
                            }
                            priceProduct.put(oldCorePrice,currentCore);
                            if (t.ChargentOrders__Amount__c.abs() == oldCorePrice + sumOfAncillaries) {
                                for (vlocity_ins__ContractLineItem__c cli: cliList) {
                                    Boolean isCoreMedical = cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c == 'Medical';
                                    Decimal amount = isCoreMedical? oldCorePrice : cli.vlocity_ins__UnitPrice__c;
                                    tliToCreate.add(new ARC_TransactionLineItem__c(
                                        Name = cli.vlocity_ins__Product2Id__r.Name,
                                        ARC_Product__c = cli.vlocity_ins__Product2Id__c,
                                        ARC_Type__c = cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                                        ARC_Transaction__c = t.Id,
                                        ARC_Amount__c = isRefund ? -amount : amount
                                    ));
                                }
                            }
                            else if (priceProduct.containsKey(t.ChargentOrders__Amount__c.abs())){
                                vlocity_ins__ContractLineItem__c cli = priceProduct.get(t.ChargentOrders__Amount__c.abs());

                                tliToCreate.add(new ARC_TransactionLineItem__c(
                                    Name = cli.vlocity_ins__Product2Id__r.Name,
                                    ARC_Product__c = cli.vlocity_ins__Product2Id__c,
                                    ARC_Type__c = cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                                    ARC_Transaction__c = t.Id,
                                    ARC_Amount__c = t.ChargentOrders__Amount__c
                                ));
                            }
                        }

                        if (healthyDiscounts == null) {
                            if(t.ChargentOrders__Amount__c.abs() == currentCorePrice + sumOfAncillaries){
                                for (vlocity_ins__ContractLineItem__c cli: cliList) {
                                    tliToCreate.add(new ARC_TransactionLineItem__c(
                                        Name = cli.vlocity_ins__Product2Id__r.Name,
                                        ARC_Product__c = cli.vlocity_ins__Product2Id__c,
                                        ARC_Type__c = cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                                        ARC_Transaction__c = t.Id,
                                        ARC_Amount__c = isRefund ? -cli.vlocity_ins__UnitPrice__c : cli.vlocity_ins__UnitPrice__c
                                    ));
                                }
                            }
                            else if (priceProduct.containsKey(t.ChargentOrders__Amount__c.abs())) {
                                vlocity_ins__ContractLineItem__c cli = priceProduct.get(t.ChargentOrders__Amount__c.abs());
                                tliToCreate.add(new ARC_TransactionLineItem__c(
                                    Name = cli.vlocity_ins__Product2Id__r.Name,
                                    ARC_Product__c = cli.vlocity_ins__Product2Id__c,
                                    ARC_Type__c = cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                                    ARC_Transaction__c = t.Id,
                                    ARC_Amount__c = isRefund ? -cli.vlocity_ins__UnitPrice__c : cli.vlocity_ins__UnitPrice__c
                                ));
                            }
                        }

                    }
                }
            }
        }

        try {
            insert tliToCreate;
        } catch (DmlException e) {
            System.debug(e.getMessage());
        }
    }

 
    global void finish(Database.BatchableContext BC){
        System.debug('Finished running batch job');
    }
}