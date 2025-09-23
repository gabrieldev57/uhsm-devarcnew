global class ARC_CardExpirationBatch implements Database.Batchable<sObject>, Schedulable{

    global void execute(SchedulableContext sc) {
        ARC_CardExpirationBatch b = new ARC_CardExpirationBatch(); 
        database.executebatch(b);
    }

	String nextMonth = String.valueOf(System.today().addMonths(1).month());
	String paddMonth = nextMonth.length() == 1? '0'+ nextMonth : nextMonth;
	String currentYear4 = nextMonth == '1'? String.valueOf(System.today().year() + 1) : String.valueOf(System.today().year());
	String currentYear2 = nextMonth == '1'? String.valueOf(System.today().year() + 1).right(2) : String.valueOf(System.today().year()).right(2);

    global Database.QueryLocator start(Database.BatchableContext BC){
		System.debug('batch starting');
        return Database.getQueryLocator([
			SELECT Id, 
				ARC_Contract__c,
				ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c, 
				ChargentOrders__Tokenization__c,
				ChargentOrders__Card_Last_4__c,
				ChargentOrders__Bank_Account_Name__c,
				ChargentOrders__Bank_Account_Last_4__c,
				ChargentOrders__Card_Year_Indicator__c,
				ChargentOrders__Card_Month_Indicator__c,
				ChargentOrders__Card_Type__c,
				ChargentOrders__Payment_Method__c
			FROM ChargentOrders__ChargentOrder__c
			WHERE ChargentOrders__Payment_Status__c = 'Recurring'
			AND ChargentOrders__Payment_Method__c = 'Credit Card'
			AND ChargentOrders__Tokenization__c != null
			AND ARC_Contract__r.Status = 'Activated'
			AND (ChargentOrders__Card_Month_Indicator__c =: nextMonth OR ChargentOrders__Card_Month_Indicator__c =: paddMonth)
			AND (ChargentOrders__Card_Year_Indicator__c =: currentYear4 OR ChargentOrders__Card_Year_Indicator__c =: currentYear2)
		]);
    }
 
    global void execute(Database.BatchableContext BC, List<ChargentOrders__ChargentOrder__c> chargents){
		System.debug('batch executing');
		System.debug(chargents);

		Set<String> tokens = new Set<String>();
		Set<String> censusIds = new Set<String>();

        for (ChargentOrders__ChargentOrder__c c : chargents) {
            tokens.add(c.ChargentOrders__Tokenization__c);
			censusIds.add(c.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c);
        }

		List<ChargentOrders__ChargentOrder__c> paymentOrders = [
			SELECT Id,
			ChargentOrders__Tokenization__c,
			ChargentOrders__Bank_Account_Name__c,
			ChargentOrders__Bank_Account_Last_4__c,
			ChargentOrders__Card_Year_Indicator__c,
			ChargentOrders__Card_Month_Indicator__c,
			ChargentOrders__Card_Type__c,
			ChargentOrders__Card_Last_4__c,
			ChargentOrders__Payment_Method__c
			FROM ChargentOrders__ChargentOrder__c
			WHERE ChargentOrders__Tokenization__c IN: tokens
			AND (ChargentOrders__Card_Month_Indicator__c =: nextMonth OR ChargentOrders__Card_Month_Indicator__c =: paddMonth)
			AND (ChargentOrders__Card_Year_Indicator__c =: currentYear4 OR ChargentOrders__Card_Year_Indicator__c =: currentYear2)
			AND ChargentOrders__Card_Last_4__c != null
			AND ChargentOrders__Card_Type__c != null
			ORDER BY CreatedDate ASC
		];
		System.debug('Numero de CO: '+paymentOrders.size());

        Map<Id,vlocity_ins__GroupCensus__c> censusMap = new Map<Id,vlocity_ins__GroupCensus__c>([
			SELECT Id,
				(SELECT Id,vlocity_ins__CensusId__c,vlocity_ins__ContactId__r.Email,Member_ID__c,e123_member_id_from_policy__c,vlocity_ins__FirstName__c,ARC_Age__c
				FROM vlocity_ins__Census_Members__r
				WHERE vlocity_ins__IsPrimaryMember__c = true AND ARC_ActiveMember__c = true AND vlocity_ins__ContactId__r.Email != null LIMIT 1),

				(SELECT ARC_ExternalPersonAuthorized__r.Email,ARC_ExternalPersonAuthorized__r.IsPersonAccount
				FROM HipaaAuthorizations__r
				WHERE ARC_ExternalPersonAuthorized__r.Email != null
				ORDER BY ARC_ExternalPersonAuthorized__r.IsPersonAccount DESC LIMIT 1)
			FROM vlocity_ins__GroupCensus__c
			WHERE Id IN: censusIds
		]);

		List<vlocity_ins__ContractLineItem__c> contractLineItems = [
            SELECT vlocity_ins__ContractId__r.vlocity_ins__EnrollmentCensusId__c, vlocity_ins__ProductName__c
            FROM vlocity_ins__ContractLineItem__c
            WHERE vlocity_ins__ContractId__r.vlocity_ins__EnrollmentCensusId__c IN :censusIds AND (vlocity_ins__ContractId__r.Status = 'Activated')
            AND (vlocity_ins__ProductName__c LIKE '%WeShare%' OR vlocity_ins__ProductName__c LIKE '%UHSM%')
        ];
		System.debug('Numero de CLI: '+contractLineItems.size());

		Map<Id, String> productMap = new Map<Id, String>();
		for (vlocity_ins__ContractLineItem__c cli : contractLineItems) {
			productMap.put(cli.vlocity_ins__ContractId__r.vlocity_ins__EnrollmentCensusId__c, cli.vlocity_ins__ProductName__c);
		}

		List<Case> existingExpiringCases = [SELECT Id, ARC_Contract__c, Subject
                                            FROM Case 
                                            WHERE Case_Type__c = 'Contribution' AND ARC_Reason__c = 'CC Expiration Date' AND ARC_Contract__c <> null AND Subject LIKE 'CC expiring%'];
        
        Map<String,Id> contractCaseMap = new Map<String,Id>();
        String existingCaseKey;
        if(existingExpiringCases.size()>0){
            for (Case existingCase: existingExpiringCases){
                existingCaseKey = existingCase.ARC_Contract__c + ' ' + existingCase.Subject;
                contractCaseMap.put(existingCaseKey, existingCase.Id);
            }
        }

		List<Map<String,Object>> emailList9 = new List<Map<String,Object>>();
        List<Map<String,Object>> emailList60 = new List<Map<String,Object>>();

		for (ChargentOrders__ChargentOrder__c c : chargents) {
			vlocity_ins__GroupCensus__c censusRecord = (vlocity_ins__GroupCensus__c)censusMap.get(c.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c);
			vlocity_ins__GroupCensusMember__c primaryMember = censusRecord.vlocity_ins__Census_Members__r.size() > 0? censusRecord.vlocity_ins__Census_Members__r[0] : null;
			ARC_HipaaAuthorization__c guardian = censusRecord.HipaaAuthorizations__r.size() > 0? censusRecord.HipaaAuthorizations__r[0] : null;
			system.debug('Member: ' + primaryMember);
			if (primaryMember != null) {
				Boolean isMinorMember = primaryMember.ARC_Age__c < 18;
				if (isMinorMember && guardian != null) primaryMember.vlocity_ins__ContactId__r.Email = guardian.ARC_ExternalPersonAuthorized__r.Email;
				Map<String, Object> email = new Map<String,Object>();
				email.put('censusMember',primaryMember);
				String contractCaseMapKey = c.ARC_Contract__c + ' ' + 'CC expiring '+c.ChargentOrders__Card_Month_Indicator__c+'/'+c.ChargentOrders__Card_Year_Indicator__c;
				if(contractCaseMap.get(contractCaseMapKey) != null) {
					email.put('caseId', contractCaseMap.get(contractCaseMapKey));
				}
				if(c.ChargentOrders__Card_Last_4__c != null)email.put('chargentOrder',c);
				else{
					for (ChargentOrders__ChargentOrder__c po : paymentOrders) {
						Boolean tokensAreEqual = po.ChargentOrders__Tokenization__c == c.ChargentOrders__Tokenization__c;
						if (tokensAreEqual) {
							email.put('chargentOrder',po);
							break;
						}	
					}
				}
				if(email.get('censusMember')!= null && email.get('chargentOrder')!= null && productMap.get(c.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c)!= null) {
					if(productMap.get(c.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c).contains('WeShare')) {
						emailList9.add(email);
					} else if(productMap.get(c.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c).contains('UHSM')) {
						emailList60.add(email);
					}
				}
			}
		}
		System.debug('Lista de mails 9: '+emailList9.size());
		System.debug('Lista de mails 60: '+emailList60.size());
		Map<String, Object> inputMap9 = new Map<String, Object>{'emails'=> emailList9};
        Map<String, Object> inputMap60 = new Map<String, Object>{'emails'=> emailList60};
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        try {
			System.debug('Pre email9');
            ARC_Emails.email_9(inputMap9, outputMap, optionsMap);
			System.debug('Post email9');
        } catch (Exception e) {
            System.debug(e.getMessage());
            ARC_Emails.sendErrorMessage(e.getMessage(), e.getLineNumber(), 'ARC_CardExpirationBatch.email_9',String.valueOf(emailList9));
        }
        try {
            ARC_Emails.email_60(inputMap60, outputMap, optionsMap);
        } catch (Exception e) {
            System.debug(e.getMessage());
            ARC_Emails.sendErrorMessage(e.getMessage(), e.getLineNumber(), 'ARC_CardExpirationBatch.email_60',String.valueOf(emailList9));
        }
    }
 
    global void finish(Database.BatchableContext BC){
    }
 }