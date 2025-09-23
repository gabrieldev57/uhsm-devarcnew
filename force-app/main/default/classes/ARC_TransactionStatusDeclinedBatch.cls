global class ARC_TransactionStatusDeclinedBatch implements Database.Batchable<sObject>,Schedulable{

    global void execute(SchedulableContext sc) {
        ARC_TransactionStatusDeclinedBatch b = new ARC_TransactionStatusDeclinedBatch(); 
        database.executebatch(b);
    }

    global Database.QueryLocator start(Database.BatchableContext BC){

        return Database.getQueryLocator([
            SELECT
			Id,
			Census__c,
			ChargentOrders__Order__r.ARC_Contract__c
            FROM ChargentOrders__Transaction__c
            WHERE ChargentOrders__Type__c = 'Charge'
			AND ChargentOrders__Order__r.ChargentOrders__Description__c = 'App Fee'
			AND ChargentOrders__Response_Status__c = 'Declined'
			AND Census__c != null
			AND	ChargentOrders__Order__r.ARC_Contract__r.Status != 'Terminated'
			AND	ChargentOrders__Order__r.ARC_Contract__r.Status != 'Draft'
			AND CreatedDate = LAST_N_DAYS:6
        ]);

    }
 
    global void execute(Database.BatchableContext BC, List<ChargentOrders__Transaction__c> transactions){

		Set<Id> censusIds = new Set<Id>();
		Set<Id> contractIds = new Set<Id>();

		for (ChargentOrders__Transaction__c t : transactions) {
			censusIds.add(t.Census__c);
			contractIds.add(t.ChargentOrders__Order__r.ARC_Contract__c);
		}

		List <vlocity_ins__GroupCensusMember__c> censusMembers = [
			SELECT 
			Id,
			vlocity_ins__FirstName__c,
			vlocity_ins__CensusId__c,
			vlocity_ins__ContactId__r.Email,
			Member_ID__c,
			e123_member_id_from_policy__c,
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


		try {
			Map<String, Object> inputMap = new Map<String, Object>{'censusMembers'=> censusMembers};
			Map<String, Object> outputMap = new Map<String, Object>();
			Map<String, Object> optionsMap = new Map<String, Object>();
			ARC_Emails.email_6(inputMap, outputMap, optionsMap);
		} catch (Exception e) {
			System.debug(e);
			
		}

    }
 
    global void finish(Database.BatchableContext BC){

    }
}