public with sharing class ARC_QuoteTriggerHandler {
    
    private static final Id SMALL_GROUP_QUOTE_RT_ID = [
        SELECT Id
        FROM RecordType
        WHERE SObjectType = 'Quote'
        AND DeveloperName = 'SmallGroupQuote'
        LIMIT 1
    ].Id;

    public static void validateQuoteLineItemsBeforeAccept(
        List<Quote> newQuotes,
        Map<Id, Quote> oldMap
    ) {
        
        Boolean hasSmallGroup = false;
        for (Quote q : newQuotes) {
            if (q.RecordTypeId == SMALL_GROUP_QUOTE_RT_ID) {
                hasSmallGroup = true;
                break;
            }
        }

        if (!hasSmallGroup) {
            return;
        }

        Set<Id> quotesToValidate = new Set<Id>();
        for (Quote q : newQuotes) {
            if (
                q.RecordTypeId == SMALL_GROUP_QUOTE_RT_ID &&
                q.Status == 'Accepted' &&
                oldMap.get(q.Id).Status != 'Accepted'
            ) {
                quotesToValidate.add(q.Id);
            }
        }
        if (quotesToValidate.isEmpty()) return;

        Set<Id> quotesWithPending = new Set<Id>();
            for (AggregateResult ar : [
                SELECT QuoteId qId
                FROM QuoteLineItem
                WHERE QuoteId IN :quotesToValidate
                AND ARC_EligibleForContract__c = 'Pending'
                GROUP BY QuoteId
            ]) {
                quotesWithPending.add((Id) ar.get('qId'));
            }

            //
            Map<Id, Quote> quotesToValidateMap = new Map<Id, Quote>([
            SELECT Id, OpportunityId
            FROM Quote
            WHERE Id IN :quotesToValidate
        ]);

        Set<Id> oppIds = new Set<Id>();
        for (Quote q : quotesToValidateMap.values()) {
            if (q.OpportunityId != null) oppIds.add(q.OpportunityId);
        }

        Map<Id, Opportunity> oppMap = oppIds.isEmpty()
            ? new Map<Id, Opportunity>()
            : new Map<Id, Opportunity>([
                SELECT Id, RecordType.DeveloperName, ARC_CurvScore__c
                FROM Opportunity
                WHERE Id IN :oppIds
            ]);

        Set<Id> quotesWithMissingCurvScore = new Set<Id>();
        for (Quote q : quotesToValidateMap.values()) {
            Opportunity opp = oppMap.get(q.OpportunityId);
            if (
                opp != null &&
                opp.RecordType?.DeveloperName == 'ARC_Renewal' &&
                opp.ARC_CurvScore__c == null
            ) {
                quotesWithMissingCurvScore.add(q.Id);
            }
        }
        //


        // if (quotesWithPending.isEmpty()) return;
        // if (quotesWithMissingCurvScore.isEmpty()) return;

        for (Quote q : newQuotes) {
            if (quotesWithPending.contains(q.Id)) {
                q.addError(
                    'You cannot change the Quote Status to Accepted while there are Quote Line Items with "Eligible For Contract" set to Pending.'
                );
            }
            if (quotesWithMissingCurvScore.contains(q.Id)) {
                q.addError(
                    'Unable to create Contract. The associated Opportunity is missing a Curv Score value. Please contact your Administrator before proceeding.'
                );
            }
        }
    }

    public static void updateOpportunitiesStage(List<Quote> quotes, Map<Id, Id> quoteToContractMap) {
        Set<Id> oppIds = new Set<Id>();
        for (Quote q : quotes) if (q.OpportunityId != null) oppIds.add(q.OpportunityId);
        if (oppIds.isEmpty()) return;

        Map<Id, Id> oppIdToContractId = new Map<Id, Id>();
        for (Quote q : quotes) {
            if (q.OpportunityId != null && quoteToContractMap.containsKey(q.Id)) {
                oppIdToContractId.put(q.OpportunityId, quoteToContractMap.get(q.Id));
            }
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Id oppId : oppIds) {
            oppsToUpdate.add(new Opportunity(
                Id = oppId,
                StageName = 'Negotiation/Review',
                ContractId = oppIdToContractId.get(oppId)
            ));
        }
        update oppsToUpdate;
    }


    public static void createContractsAndCLIs(List<Quote> quotes, Map<Id, Id> quoteToContractMap) {
        if (quotes.isEmpty()) return;

        Map<Id, Quote> quoteMap = new Map<Id, Quote>(
            [SELECT Id, AccountId, OpportunityId FROM Quote WHERE Id IN :quotes]
        );

        Set<Id> oppIds = new Set<Id>();
        for (Quote q : quoteMap.values()) if (q.OpportunityId != null) oppIds.add(q.OpportunityId);

        Map<Id, Opportunity> oppMap = oppIds.isEmpty()
            ? new Map<Id, Opportunity>()
            : new Map<Id, Opportunity>(
                [SELECT Id, ARC_RequestedEffectiveDate__c, ARC_OEStartDate__c, ARC_OEEndDate__c, RecordType.DeveloperName, ARC_CurvScore__c 
                FROM Opportunity 
                WHERE Id IN :oppIds]
            );

        Set<Id> accountIds = new Set<Id>();
        for (Quote q : quoteMap.values()) {
            if (q.AccountId != null) {
                accountIds.add(q.AccountId);  
            }
        }

        List<ChargentOrders__ChargentOrder__c> existingOrders = new List<ChargentOrders__ChargentOrder__c>();
        if (!accountIds.isEmpty()) {
            existingOrders = [
                SELECT Id, ChargentOrders__Account__c, ARC_Contract__c
                FROM ChargentOrders__ChargentOrder__c
                WHERE ARC_Contract__c = null
                AND ChargentOrders__Account__c IN :accountIds        
                LIMIT 1
            ];
        }
        
        Map<Id, Id> accountIdToChargentOrderMap = new Map<Id, Id>();
        for (ChargentOrders__ChargentOrder__c existingOrder : existingOrders) {
            accountIdToChargentOrderMap.put(existingOrder.ChargentOrders__Account__c, existingOrder.Id);
        }

        Map<Id, Id> accountToCensusMap = new Map<Id, Id>();
        if (!accountIds.isEmpty()) {
            for (vlocity_ins__GroupCensus__c gc : [
                SELECT Id, vlocity_ins__GroupId__c
                FROM vlocity_ins__GroupCensus__c
                WHERE vlocity_ins__GroupId__c IN :accountIds
            ]) {
                accountToCensusMap.put(gc.vlocity_ins__GroupId__c, gc.Id);
            }
        }

        // ---- Renewal: locate Active Contracts and their ChargentOrders to use as source for cloning ----
        Set<Id> renewalAccountIds = new Set<Id>();
        for (Quote q : quoteMap.values()) {
            Opportunity opp = oppMap.get(q.OpportunityId);
            if (opp?.RecordType?.DeveloperName == 'ARC_Renewal' && q.AccountId != null) {
                renewalAccountIds.add(q.AccountId);
            }
        }

        // accountId -> source ChargentOrder to clone for Renewals
        Map<Id, ChargentOrders__ChargentOrder__c> renewalAccountToSourceOrder = new Map<Id, ChargentOrders__ChargentOrder__c>();
        if (!renewalAccountIds.isEmpty()) {
            Map<Id, Id> renewalAccountToOrderId = new Map<Id, Id>();
            for (Contract ac : [
                SELECT Id, AccountId, ARC_RecurringMonthlyOrder__c
                FROM Contract
                WHERE AccountId IN :renewalAccountIds
                  AND Status = 'Activated'
                  AND ARC_RecurringMonthlyOrder__c != null
            ]) {
                renewalAccountToOrderId.put(ac.AccountId, ac.ARC_RecurringMonthlyOrder__c);
            }
            if (!renewalAccountToOrderId.isEmpty()) {
                Set<Id> sourceOrderIds = new Set<Id>(renewalAccountToOrderId.values());
                Map<Id, ChargentOrders__ChargentOrder__c> ordersById = new Map<Id, ChargentOrders__ChargentOrder__c>([
                    SELECT Id,
                           ChargentOrders__Payment_Method__c,
                           ChargentOrders__Description__c,
                           ChargentOrders__Billing_Address__c,
                           ChargentOrders__Billing_City__c,
                           ChargentOrders__Billing_State__c,
                           ChargentOrders__Billing_Zip_Postal__c,
                           ChargentOrders__Bank_Name__c,
                           ChargentOrders__Bank_Account_Name__c,
                           ChargentOrders__Bank_Account_Type__c,
                           ChargentOrders__Card_Expiration_Month__c,
                           ChargentOrders__Card_Expiration_Year__c,
                           ChargentOrders__Gateway__c,
                            ChargentOrders__Tokenization__c,
                            ChargentOrders__Card_Type__c,
                            ChargentOrders__Bank_Account_Last_4__c,
                            ChargentOrders__Card_Last_4__c
                    FROM ChargentOrders__ChargentOrder__c
                    WHERE Id IN :sourceOrderIds
                ]);
                for (Id accId : renewalAccountToOrderId.keySet()) {
                    Id ordId = renewalAccountToOrderId.get(accId);
                    if (ordersById.containsKey(ordId)) {
                        renewalAccountToSourceOrder.put(accId, ordersById.get(ordId));
                    }
                }
            }
        }

        Id contractRTId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Contract'
            AND DeveloperName = 'ARC_SmallGroup'
            LIMIT 1
        ].Id;

        List<Contract> contractsToInsert = new List<Contract>();
        for (Quote q : quoteMap.values()) {
            Opportunity opp = oppMap.get(q.OpportunityId);
            Boolean isRenewal = opp?.RecordType?.DeveloperName == 'ARC_Renewal';

            // if (isRenewal && opp.ARC_CurvScore__c == null) {
            //     q.addError('Unable to create Contract. The associated Opportunity is missing a Curv Score value. Please contact your Administrator before proceeding.');
            //     continue; 
            // }

            Contract c = new Contract(
                RecordTypeId = contractRTId,
                Status = 'Draft',
                AccountId = q.AccountId,
                ARC_ContractReason__c = isRenewal ? 'Renewal' : 'New Enrollment',
                ARC_PaymentFrequency__c = 'Monthly'
            );
            
            // if (isRenewal) {
            //     c.ARC_CurvScore__c = opp.ARC_CurvScore__c;
            // }
            if (opp != null && opp.ARC_CurvScore__c != null) {
                c.ARC_CurvScore__c = opp.ARC_CurvScore__c;
            }

            // For Renewals, a new ChargentOrder is created post-insert; skip linking an existing one.
            if (!isRenewal && accountIdToChargentOrderMap.containsKey(q.AccountId)) {
                c.ARC_RecurringMonthlyOrder__c = accountIdToChargentOrderMap.get(q.AccountId);
            }

            if (accountToCensusMap.containsKey(q.AccountId)) {
                c.vlocity_ins__EnrollmentCensusId__c = accountToCensusMap.get(q.AccountId);
            }

            //Opportunity opp = oppMap.get(q.OpportunityId);
            if (opp != null && opp.ARC_OEStartDate__c != null) {
                c.ARC_OEStartDate__c = opp.ARC_OEStartDate__c;
            }
            if (opp != null && opp.ARC_OEEndDate__c != null) {
                c.ARC_OEEndDate__c = opp.ARC_OEEndDate__c;
            }
            if (opp != null && opp.ARC_RequestedEffectiveDate__c != null) {
                c.ARC_EffectiveDate__c = opp.ARC_RequestedEffectiveDate__c;
            }
            contractsToInsert.add(c);
        }

        insert contractsToInsert;

        List<ChargentOrders__ChargentOrder__c> chargentOrdersToUpdate = new List<ChargentOrders__ChargentOrder__c>();
        for (Contract c : contractsToInsert) {
            if (c.ARC_RecurringMonthlyOrder__c != null) {
                chargentOrdersToUpdate.add(
                    new ChargentOrders__ChargentOrder__c(
                        Id = c.ARC_RecurringMonthlyOrder__c,
                        ARC_Contract__c = c.Id
                    )
                );
            }
        }
        if (!chargentOrdersToUpdate.isEmpty()) {
            update chargentOrdersToUpdate;
        }

        // ---- Post-insert: create new ChargentOrders for Renewal contracts ----
        List<ChargentOrders__ChargentOrder__c> newRenewalOrders = new List<ChargentOrders__ChargentOrder__c>();
        List<Contract> renewalContractsToLink = new List<Contract>();
        for (Contract c : contractsToInsert) {
            if (c.ARC_ContractReason__c == 'Renewal' && renewalAccountToSourceOrder.containsKey(c.AccountId)) {
                ChargentOrders__ChargentOrder__c src = renewalAccountToSourceOrder.get(c.AccountId);
                newRenewalOrders.add(new ChargentOrders__ChargentOrder__c(
                    ChargentOrders__Account__c            = c.AccountId,
                    ChargentOrders__Payment_Method__c     = src.ChargentOrders__Payment_Method__c,
                    ChargentOrders__Description__c        = src.ChargentOrders__Description__c,
                    ChargentOrders__Billing_Address__c    = src.ChargentOrders__Billing_Address__c,
                    ChargentOrders__Billing_City__c       = src.ChargentOrders__Billing_City__c,
                    ChargentOrders__Billing_State__c      = src.ChargentOrders__Billing_State__c,
                    ChargentOrders__Billing_Zip_Postal__c = src.ChargentOrders__Billing_Zip_Postal__c,
                    ChargentOrders__Bank_Name__c          = src.ChargentOrders__Bank_Name__c,
                    ChargentOrders__Bank_Account_Name__c  = src.ChargentOrders__Bank_Account_Name__c,
                    ChargentOrders__Bank_Account_Type__c  = src.ChargentOrders__Bank_Account_Type__c,
                    ChargentOrders__Card_Expiration_Month__c = src.ChargentOrders__Card_Expiration_Month__c,
                    ChargentOrders__Card_Expiration_Year__c  = src.ChargentOrders__Card_Expiration_Year__c,
                    ChargentOrders__Gateway__c            = src.ChargentOrders__Gateway__c,
                    ARC_Contract__c                       = c.Id,
                    ChargentOrders__Tokenization__c       = src.ChargentOrders__Tokenization__c,
                    ChargentOrders__Card_Type__c         = src.ChargentOrders__Card_Type__c,
                    ChargentOrders__Bank_Account_Last_4__c = src.ChargentOrders__Bank_Account_Last_4__c,
                    ChargentOrders__Card_Last_4__c         = src.ChargentOrders__Card_Last_4__c
                ));
                renewalContractsToLink.add(c);
            }
        }
        if (!newRenewalOrders.isEmpty()) {
            insert newRenewalOrders;
            List<Contract> contractOrderLinks = new List<Contract>();
            for (Integer i = 0; i < newRenewalOrders.size(); i++) {
                contractOrderLinks.add(new Contract(
                    Id = renewalContractsToLink[i].Id,
                    ARC_RecurringMonthlyOrder__c = newRenewalOrders[i].Id
                ));
            }
            update contractOrderLinks;
            // Publish PE so Automated Process user (with View Encrypted Data) can copy encrypted fields
            List<ARC_RenewalOrderClone__e> cloneEvents = new List<ARC_RenewalOrderClone__e>();
            for (Integer i = 0; i < newRenewalOrders.size(); i++) {
                Id srcOrderId = renewalAccountToSourceOrder.get(renewalContractsToLink[i].AccountId).Id;
                cloneEvents.add(new ARC_RenewalOrderClone__e(
                    SourceOrderId__c = srcOrderId,
                    NewOrderId__c    = newRenewalOrders[i].Id
                ));
            }
            if (!cloneEvents.isEmpty()) EventBus.publish(cloneEvents);
            
        }

        // Map quotes to their new contracts and update Quote.ContractId
        Integer idx = 0;
        List<Quote> quotesToUpdate = new List<Quote>();
        for (Quote q : quoteMap.values()) {
            Id newContractId = contractsToInsert[idx++].Id;
            quoteToContractMap.put(q.Id, newContractId);
            quotesToUpdate.add(new Quote(
                Id = q.Id,
                ContractId = newContractId
            ));
        }
        update quotesToUpdate;

        List<QuoteLineItem> selectedQLIs = [
            SELECT Id, QuoteId, Product2Id, Product2.Name
            FROM QuoteLineItem
            WHERE QuoteId IN :quoteMap.keySet()
            AND ARC_EligibleForContract__c = 'Selected'
        ];

        List<vlocity_ins__ContractLineItem__c> clisToInsert = new List<vlocity_ins__ContractLineItem__c>();
        for (QuoteLineItem qli : selectedQLIs) {
            clisToInsert.add(new vlocity_ins__ContractLineItem__c(
                Name = qli.Product2.Name,
                vlocity_ins__Product2Id__c = qli.Product2Id,
                vlocity_ins__ContractId__c = quoteToContractMap.get(qli.QuoteId)
            ));
        }

        if (!clisToInsert.isEmpty()) insert clisToInsert;
    }

    public static void processAcceptedQuote(List<Quote> acceptedQuotes) {
        if (acceptedQuotes.isEmpty()) return;

        List<Quote> quotesToProcess = new List<Quote>();
        Map<Id, Id> quoteToContractMap = new Map<Id, Id>();

        for (Quote q : acceptedQuotes) {
            if (q.ContractId != null) {
                quoteToContractMap.put(q.Id, q.ContractId);
            } else {
                quotesToProcess.add(q);
            }
        }

        ARC_QuoteTriggerHandler.createContractsAndCLIs(quotesToProcess, quoteToContractMap);
        ARC_QuoteTriggerHandler.updateOpportunitiesStage(quotesToProcess, quoteToContractMap);
    }

    public static void handleBeforeUpdate(
        List<Quote> newQuotes,
        Map<Id, Quote> oldMap
    ) {
        validateQuoteLineItemsBeforeAccept(newQuotes, oldMap);
    }

    public static void handleAfterUpdate(
        List<Quote> newQuotes,
        Map<Id, Quote> oldMap
    ) {
        List<Quote> acceptedQuotes = new List<Quote>();

        for (Quote q : newQuotes) {
            if (
                q.RecordTypeId == SMALL_GROUP_QUOTE_RT_ID &&
                q.Status == 'Accepted' &&
                oldMap.get(q.Id).Status != 'Accepted'
            ) {
                acceptedQuotes.add(q);
            }
        }

        processAcceptedQuote(acceptedQuotes);
    }
}