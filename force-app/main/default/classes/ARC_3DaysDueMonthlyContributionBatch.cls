global class ARC_3DaysDueMonthlyContributionBatch implements Database.Batchable<sObject>,Schedulable{

    public Set<Id> chargentOrdersIds = new Set<Id>();

    global void execute(SchedulableContext sc) {
        ARC_3DaysDueMonthlyContributionBatch b = new ARC_3DaysDueMonthlyContributionBatch(null); 
        database.executebatch(b);
    }

	global ARC_3DaysDueMonthlyContributionBatch(Set<Id> chargentOrdersIds){
        if(chargentOrdersIds != null) this.chargentOrdersIds = chargentOrdersIds;
    }

	global ARC_3DaysDueMonthlyContributionBatch(){
	}

 
    global Database.QueryLocator start(Database.BatchableContext BC){

		Date add3Days = System.today().addDays(3);
		if (Test.isRunningTest()) add3Days = System.today();
 
		if(!this.chargentOrdersIds.isEmpty()){
			System.debug('Has chargents to send');
			return Database.getQueryLocator([
				SELECT 
					ChargentOrders__Next_Transaction_Date__c,
					ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c,
					ChargentOrders__Total__c
				FROM ChargentOrders__ChargentOrder__c 
				WHERE ChargentOrders__Next_Transaction_Date__c =: add3Days
				AND ARC_Contract__r.Status = 'Activated'
				AND ChargentOrders__Payment_Status__c = 'Recurring' 
				AND Id IN:chargentOrdersIds ]);
		}
        else {
			System.debug('Do not filter by any Chargent');
			return Database.getQueryLocator([
			SELECT 
			ChargentOrders__Next_Transaction_Date__c,
			ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c,
			ChargentOrders__Total__c
			FROM ChargentOrders__ChargentOrder__c 
			WHERE ChargentOrders__Next_Transaction_Date__c =: add3Days
			AND ARC_Contract__r.Status = 'Activated'
			AND ChargentOrders__Payment_Status__c = 'Recurring']);
		}

    }
 
    global void execute(Database.BatchableContext BC, List<ChargentOrders__ChargentOrder__c> chargents){
		List<Id> censusIds = new List<Id>();
        for (ChargentOrders__ChargentOrder__c c : chargents) {
            censusIds.add(c.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c);
        }

		Map<Id,vlocity_ins__GroupCensus__c> censusMap = new Map<Id,vlocity_ins__GroupCensus__c>([
			SELECT Id,
				(SELECT
				Id,
				vlocity_ins__ContactId__r.Email,
				vlocity_ins__CensusId__c,
				vlocity_ins__FirstName__c,
				ARC_Age__c
				FROM vlocity_ins__Census_Members__r
				WHERE vlocity_ins__IsPrimaryMember__c = true
				AND ARC_ActiveMember__c = true
				AND vlocity_ins__ContactId__r.Email != null LIMIT 1),

				(SELECT
				ARC_ExternalPersonAuthorized__r.Email,
				ARC_ExternalPersonAuthorized__r.IsPersonAccount
				FROM HipaaAuthorizations__r
				WHERE ARC_ExternalPersonAuthorized__r.Email != null
				ORDER BY ARC_ExternalPersonAuthorized__r.IsPersonAccount DESC LIMIT 1)
			FROM vlocity_ins__GroupCensus__c
			WHERE Id IN: censusIds
		]);

		List<Map<String,Object>> emailsInformation = new List<Map<String,Object>>();
		for (ChargentOrders__ChargentOrder__c c : chargents) {
			vlocity_ins__GroupCensus__c censusRecord = (vlocity_ins__GroupCensus__c)censusMap.get(c.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c);
			vlocity_ins__GroupCensusMember__c primaryMember = censusRecord.vlocity_ins__Census_Members__r.size() > 0? censusRecord.vlocity_ins__Census_Members__r[0] : null;
			ARC_HipaaAuthorization__c guardian = censusRecord.HipaaAuthorizations__r.size() > 0? censusRecord.HipaaAuthorizations__r[0] : null;
			Boolean isMinorMember = primaryMember?.ARC_Age__c < 18;
		
			if (primaryMember != null && isMinorMember && guardian != null) primaryMember.vlocity_ins__ContactId__r.Email = guardian.ARC_ExternalPersonAuthorized__r?.Email;
		
			Map<String, Object> emailData = new Map<String, Object>{'censusMember' => primaryMember,'chargent' => c};
			emailsInformation.add(emailData);
		}
		
		try {
			ARC_Emails.email_5(emailsInformation);
		} catch (Exception e) {
			System.debug(e);
			ARC_Emails.sendErrorMessage(e.getMessage(), e.getLineNumber(), 'ARC_3DaysDueMonthlyContributionBatch.email_5',null);
		}
    }
 
    global void finish(Database.BatchableContext BC){
    }
 }