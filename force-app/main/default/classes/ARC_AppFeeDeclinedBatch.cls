global class ARC_AppFeeDeclinedBatch implements Database.Batchable<sObject>,Schedulable{

    global void execute(SchedulableContext sc) {
        ARC_AppFeeDeclinedBatch b = new ARC_AppFeeDeclinedBatch(); 
        database.executebatch(b);
    }

    global Database.QueryLocator start(Database.BatchableContext BC){

        return Database.getQueryLocator([
            SELECT
			Id,
			Census__c,
			ChargentOrders__Order__r.Id,
			ChargentOrders__Order__r.ARC_Contract__c,
			ChargentOrders__Order__r.ARC_Contract__r.ARC_AppFeeOrder__c,
			ChargentOrders__Order__r.ChargentOrders__Payment_Status__c,
			ChargentOrders__Tokenization__c
            FROM ChargentOrders__Transaction__c
            WHERE ChargentOrders__Type__c = 'Charge'
			AND ChargentOrders__Order__r.ChargentOrders__Description__c = 'App Fee'
			AND ChargentOrders__Response_Status__c = 'Declined'
			AND Census__c != null
			AND	ChargentOrders__Order__r.ARC_Contract__r.Status != 'Terminated'
			AND	ChargentOrders__Order__r.ARC_Contract__r.Status != 'Draft'
        ]);

    }
 
    global void execute(Database.BatchableContext BC, List<ChargentOrders__Transaction__c> transactions){

		Set<Id> censusIds = new Set<Id>();
		Set<Id> contractIds = new Set<Id>();
		Set<Id> chargentIds = new Set<Id>();

		for (ChargentOrders__Transaction__c t : transactions) {
			censusIds.add(t.Census__c);
			contractIds.add(t.ChargentOrders__Order__r.ARC_Contract__c);
			chargentIds.add(t.ChargentOrders__Order__c);
		}

		List<ChargentOrders__Transaction__c> allTransactions = [
			SELECT Id,ChargentOrders__Gateway_Date__c,ChargentOrders__Order__c,ChargentOrders__Response_Status__c
			FROM ChargentOrders__Transaction__c
			WHERE ChargentOrders__Order__c IN: chargentIds
			ORDER BY ChargentOrders__Gateway_Date__c DESC
		];

		Map<String, List<ChargentOrders__Transaction__c>> transactionsByChargent = new Map<String, List<ChargentOrders__Transaction__c>>();
		for (ChargentOrders__Transaction__c t : allTransactions) {
			if(transactionsByChargent?.get(t.ChargentOrders__Order__c) == null){
				transactionsByChargent.put(t.ChargentOrders__Order__c,new List<ChargentOrders__Transaction__c>{t});
			}
			transactionsByChargent.get(t.ChargentOrders__Order__c).add(t);
		}

		List <vlocity_ins__GroupCensusMember__c> censusMembers = [
			SELECT 
			Id,
			vlocity_ins__FirstName__c,
			vlocity_ins__CensusId__c,
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
				WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c IN: contractIds
				AND vlocity_ins__ContractLineId__r.vlocity_ins__RecordTypeName__c = 'Product'
			)
			FROM vlocity_ins__GroupCensusMember__c
			WHERE vlocity_ins__CensusId__c IN: censusIds
			AND vlocity_ins__IsPrimaryMember__c = true
		];

		Map<Id, vlocity_ins__GroupCensusMember__c> cmByCensus = new Map<Id, vlocity_ins__GroupCensusMember__c>();
        for (vlocity_ins__GroupCensusMember__c cm : censusMembers) {
            cmByCensus.put(cm.vlocity_ins__CensusId__c, cm);
        }

		List<ARC_HipaaAuthorization__c> hipaaList = new List<ARC_HipaaAuthorization__c>(
            [SELECT ARC_Census__c,ARC_ExternalPersonAuthorized__r.Email,ARC_ExternalPersonAuthorized__r.IsPersonAccount
            FROM ARC_HipaaAuthorization__c
            WHERE ARC_ExternalPersonAuthorized__r.Email != null
            AND ARC_Census__c IN: censusIds
            ORDER BY ARC_ExternalPersonAuthorized__r.IsPersonAccount DESC]
        );

		Map<String, Object> inputMap = new Map<String, Object>();

        for (ChargentOrders__Transaction__c t : transactions) {
			Boolean isMostRecentTransaction = t.Id == transactionsByChargent.get(t.ChargentOrders__Order__c)[0].Id;
			Boolean isInContract = t.ChargentOrders__Order__r?.ARC_Contract__r?.ARC_AppFeeOrder__c == t.ChargentOrders__Order__r?.Id;
			Boolean isStopped = t.ChargentOrders__Order__r.ChargentOrders__Payment_Status__c == 'Stopped';

			if (isMostRecentTransaction && isInContract && !isStopped) {
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
				email.put('censusMember', primaryMember);
				email.put('transaction', t);
				inputMap.put(t.Id, email);
			}
        }
		
		try {
			Map<String, Object> outputMap = new Map<String, Object>();
			Map<String, Object> optionsMap = new Map<String, Object>();
			ARC_Emails.email_6(inputMap, outputMap, optionsMap);
		} catch (Exception e) {
			System.debug(e);
			ARC_Emails.sendErrorMessage(e.getMessage(), e.getLineNumber(), 'ARC_AppFeeDeclinedBatch.email_6',String.valueOf(censusMembers));
		}

    }
 
    global void finish(Database.BatchableContext BC){

    }
}