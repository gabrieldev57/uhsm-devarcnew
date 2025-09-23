global class ARC_TransactionsBatch implements Database.Batchable<sObject>,Schedulable{
    
    global void execute(SchedulableContext sc) {
        ARC_TransactionsBatch b = new ARC_TransactionsBatch(); 
        database.executebatch(b,140);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator([
            SELECT
            Id,
            ChargentOrders__Order__r.Id,
            ChargentOrders__Order__c,
            ChargentOrders__Amount__c,
            ChargentOrders__Order__r.ChargentOrders__Tokenization__c,
            ChargentOrders__Tokenization__c,
            ChargentOrders__Order__r.ARC_Contract__c,
            ChargentOrders__Order__r.ARC_Contract__r.ARC_AppFeeOrder__c,
            ChargentOrders__Order__r.ARC_Contract__r.ARC_RecurringMonthlyOrder__c,
            ChargentOrders__Order__r.ChargentOrders__Charge_Amount__c,
            ChargentOrders__Order__r.ChargentOrders__Description__c,
            ChargentOrders__Response_Status__c,
            ChargentOrders__Order__r.ChargentOrders__Payment_Status__c,
            Census__c
            FROM ChargentOrders__Transaction__c
            WHERE ChargentOrders__Type__c = 'Charge'
            AND (ChargentOrders__Order__r.ChargentOrders__Description__c = 'App Fee' OR ChargentOrders__Order__r.ChargentOrders__Description__c = 'Recurring Monthly Order')
            AND (ChargentOrders__Response_Status__c = 'Approved' OR ChargentOrders__Response_Status__c = 'Declined')
            AND (ChargentOrders__Order__r.ARC_Contract__r.Status = 'Awaiting Activation' OR ChargentOrders__Order__r.ARC_Contract__r.Status = 'Activated' OR ChargentOrders__Order__r.ARC_Contract__r.Status = 'Awaiting First Payment')
            AND CreatedDate = YESTERDAY
            AND Census__c != null
            ORDER BY ChargentOrders__Gateway_Date__c DESC
        ]);
        
    }
    
    global void execute(Database.BatchableContext BC, List<ChargentOrders__Transaction__c> transactions){
        Set<Id> censusIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        Set<Id> chargentOrderIds = new Set<Id>();
        
        Map<String, List<ChargentOrders__Transaction__c>> chargentToTransactionsMap = new Map<String, List<ChargentOrders__Transaction__c>>();

        for (ChargentOrders__Transaction__c t : transactions) {
            censusIds.add(t.Census__c);
            contractIds.add(t.ChargentOrders__Order__r.ARC_Contract__c);
            chargentOrderIds.add(t.ChargentOrders__Order__r.Id);

            if(chargentToTransactionsMap.containsKey(t.ChargentOrders__Order__c) == false){
                chargentToTransactionsMap.put(t.ChargentOrders__Order__c,new List<ChargentOrders__Transaction__c>());
            }
            chargentToTransactionsMap.get(t.ChargentOrders__Order__c).add(t);
        }

        List<ARC_HipaaAuthorization__c> hipaaList = new List<ARC_HipaaAuthorization__c>(
            [SELECT ARC_Census__c,ARC_ExternalPersonAuthorized__r.Email,ARC_ExternalPersonAuthorized__r.IsPersonAccount
            FROM ARC_HipaaAuthorization__c
            WHERE ARC_ExternalPersonAuthorized__r.Email != null
            AND ARC_Census__c IN: censusIds
            ORDER BY ARC_ExternalPersonAuthorized__r.IsPersonAccount DESC]
        );
        
        
        Map<Id,ChargentOrders__ChargentOrder__c> chargentOrders = new Map<Id,ChargentOrders__ChargentOrder__c>([
            SELECT Id,
                (SELECT Id FROM ChargentOrders__Transactions__r)
            FROM ChargentOrders__ChargentOrder__c WHERE Id IN :chargentOrderIds]);
        
        List <vlocity_ins__GroupCensusMember__c> censusMembers = [
            SELECT 
            Id,
            vlocity_ins__FirstName__c,
            vlocity_ins__CensusId__c,
            vlocity_ins__IsPrimaryMember__c,
            vlocity_ins__ContactId__r.Email,
            Member_ID__c,
            e123_member_id_from_policy__c,
            ARC_Age__c,
            (
                SELECT
                vlocity_ins__GroupCensusMemberId__c,
                vlocity_ins__ContractLineId__r.Id,
                vlocity_ins__ContractLineId__r.Name,
                vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c,
                vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c,
                vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c
                FROM vlocity_ins__GroupCensusMemberPlan__r
                WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c IN :contractIds
                AND vlocity_ins__ContractLineId__r.vlocity_ins__RecordTypeName__c = 'Product'
                LIMIT 3
            )
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__CensusId__c IN :censusIds
            AND vlocity_ins__IsPrimaryMember__c = true
        ];
        
        Map<Id, vlocity_ins__GroupCensusMember__c> cmByCensus = new Map<Id, vlocity_ins__GroupCensusMember__c>();
        for (vlocity_ins__GroupCensusMember__c cm : censusMembers) cmByCensus.put(cm.vlocity_ins__CensusId__c, cm);
        
        Map<String,Object> approvedRecurring = new Map<String,Object>();
        Map<String,Object> declinedRecurring = new Map<String,Object>();
        Map<String,Object> declinedAppFee = new Map<String,Object>();
        
        for (ChargentOrders__Transaction__c t : transactions) {
            Map<String, Object> email = new Map<String, Object>();
            vlocity_ins__GroupCensusMember__c primaryMember = (vlocity_ins__GroupCensusMember__c)cmByCensus.get(t.Census__c);

            ARC_HipaaAuthorization__c guardian;
            Boolean isMinorMember = primaryMember.ARC_Age__c < 18;
            if (isMinorMember) {
                for (ARC_HipaaAuthorization__c h : hipaaList) {
                    if(h.ARC_Census__c == primaryMember.vlocity_ins__CensusId__c){
                        guardian = h;
                        break;
                    }
                }
                if (isMinorMember && guardian != null) primaryMember.vlocity_ins__ContactId__r.Email = guardian.ARC_ExternalPersonAuthorized__r.Email;
            }
            ChargentOrders__ChargentOrder__c chargent = (ChargentOrders__ChargentOrder__c)chargentOrders.get(t.ChargentOrders__Order__r.Id);
            email.put('censusMember', primaryMember);
            email.put('transaction', t);
            
            Boolean isRecurring = t.ChargentOrders__Order__r.ChargentOrders__Description__c == 'Recurring Monthly Order';
            Boolean isAppFee = t.ChargentOrders__Order__r.ChargentOrders__Description__c == 'App Fee';
            Boolean isApproved = t.ChargentOrders__Response_Status__c == 'Approved';
            Boolean isDeclined = t.ChargentOrders__Response_Status__c == 'Declined';
            Boolean isStopped = t.ChargentOrders__Order__r.ChargentOrders__Payment_Status__c == 'Stopped';
            Boolean isFirstTransaction = chargent.ChargentOrders__Transactions__r.size() == 1;
            Boolean isInContract = t.ChargentOrders__Order__r.Id == t.ChargentOrders__Order__r?.ARC_Contract__r?.ARC_RecurringMonthlyOrder__c ||
                					t.ChargentOrders__Order__r.Id == t.ChargentOrders__Order__r?.ARC_Contract__r?.ARC_AppFeeOrder__c;
            Boolean isMostRecentTransaction = 
            chargentToTransactionsMap.containsKey(t.ChargentOrders__Order__c) &&
            chargentToTransactionsMap.get(t.ChargentOrders__Order__c).isEmpty() == false &&
            t.Id == chargentToTransactionsMap.get(t.ChargentOrders__Order__c)[0].Id;
                                
            
            if (isRecurring && isApproved && !isFirstTransaction && isInContract && !isStopped ) {
                approvedRecurring.put(t.Id, email);
            }
            else if ( isRecurring && isDeclined && isInContract && !isStopped ) {
                declinedRecurring.put(t.Id, email);
            }                
            else if (isAppFee && isApproved && isInContract && !isStopped){
                continue;
            } 
            else if (isAppFee && isDeclined && isInContract && !isStopped && isMostRecentTransaction) {
                declinedAppFee.put(t.Id, email);
            }
            
        }
        
        System.debug(declinedRecurring);
        try {
            if(!approvedRecurring.isEmpty()) ARC_Emails.email_4(approvedRecurring, new Map<String,Object>(), new Map<String,Object>());
            // if(!declinedAppFee.isEmpty()) ARC_Emails.email_6(declinedAppFee, new Map<String,Object>(), new Map<String,Object>());
        } catch (Exception e) {
            System.debug(e);
            ARC_Emails.sendErrorMessage(e.getMessage(), e.getLineNumber(), 'ARC_TransactionsBatch', '');
        }
    }
    
    global void finish(Database.BatchableContext BC){
    }
}