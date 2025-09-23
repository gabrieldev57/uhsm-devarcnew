/*******************************************************************
* @ClassName          :   ARC_EmailTemplatesOnDemandController
* @Description        :   Controller used to pass the infroamtion for the LWC ARC_EmailTemplatesOnDemand.
* @MethodName         :   getTemplateInformation
********************************************************************/

global without sharing class ARC_EmailTemplatesOnDemandController implements vlocity_ins.VlocityOpenInterface {
	public Boolean invokeMethod(String methodName, Map < String, Object > inputMap, Map < String, Object > outputMap, Map < String, Object > options) {
  
	  if (methodName == 'getTemplateInformation') {
		getTemplateInformation(inputMap, outputMap);
	  }
	  if (methodName == 'getCaseRecord') {
		getCaseRecord(inputMap, outputMap);
	  }
	  
	  return true;
	}

    /*******************************************************************
    * @MethodName         :   getTemplateInformation
    * @Description        :   Received the person account id or a census member id an return the information to related to that member. (Contracts, Plans, Chargent orders) and the image used in the LWC. 
    ********************************************************************/

	public static void getTemplateInformation(Map < String, Object > inputMap, Map < String, Object > outMap) {
		Id recordId = (Id) inputMap.get('recordId');
		vlocity_ins__GroupCensusMember__c member = new vlocity_ins__GroupCensusMember__c();
		if(recordId.getSobjectType().getDescribe().getName() == 'Account'){
			member = [
				SELECT Id, vlocity_ins__CensusId__c
				FROM vlocity_ins__GroupCensusMember__c 
				WHERE Id =: [SELECT Id, Census_Member__c FROM Account WHERE Id =: recordId LIMIT 1].Census_Member__c LIMIT 1
			];
		} 
		
		vlocity_ins__GroupCensusMember__c primaryMember = [
			SELECT Member_ID__c,e123_member_id_from_policy__c,ARC_Age__c,vlocity_ins__FirstName__c,vlocity_ins__LastName__c, Is_Oldest_Member__c, vlocity_ins__Birthdate__c
			FROM vlocity_ins__GroupCensusMember__c
			WHERE vlocity_ins__CensusId__c =: member.vlocity_ins__CensusId__c
			LIMIT 1
		];
		vlocity_ins__GroupCensusMember__c spouseMember;

		List<vlocity_ins__GroupCensusMember__c> getMemberWithPlans = [
			SELECT Id,vlocity_ins__ContactId__r.AccountId,ARC_DependentRelationship__c, vlocity_ins__Birthdate__c,ARC_Age__c,Is_Oldest_Member__c,
				(
					SELECT
						vlocity_ins__ContractLineId__c,
						vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c,
						vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c,
						vlocity_ins__ContractLineId__r.Name,
						vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c,
						vlocity_ins__ContractLineId__r.vlocity_ins__TotalPrice__c
					FROM vlocity_ins__GroupCensusMemberPlan__r
					WHERE vlocity_ins__ContractLineId__c != null
				)
			FROM vlocity_ins__GroupCensusMember__c
			WHERE vlocity_ins__CensusId__c =: member.vlocity_ins__CensusId__c
		];

		List<vlocity_ins__GroupCensusMember__c> plans = new List<vlocity_ins__GroupCensusMember__c> ();
		for(vlocity_ins__GroupCensusMember__c cm: getMemberWithPlans){
			if(!cm.vlocity_ins__GroupCensusMemberPlan__r.isEmpty()){
				plans.add(cm);
				if(cm.ARC_DependentRelationship__c != null && cm.ARC_DependentRelationship__c == 'Spouse'){
					spouseMember = cm;
				}
			}
		}

		List<ARC_HipaaAuthorization__c> hipaaList = [
			SELECT Id,
			Name,
			ARC_AuthorizedMember__r.Id,
			ARC_AuthorizedMember__r.vlocity_ins__FirstName__c,
			ARC_AuthorizedMember__r.vlocity_ins__LastName__c,
			ARC_AuthorizedMember__r.vlocity_ins__Email__c,
			ARC_AuthorizedMember__r.ARC_Relationship__c,
			ARC_AuthorizedMember__r.Member_ID__c,
			ARC_AuthorizedMember__r.vlocity_ins__Birthdate__c,
			ARC_AuthorizedMember__r.vlocity_ins__ContactId__r.AccountId,
			ARC_ExternalPersonAuthorized__r.FirstName,
			ARC_ExternalPersonAuthorized__r.LastName,
			ARC_ExternalPersonAuthorized__r.Birthdate,
			ARC_ExternalPersonAuthorized__r.Email,
			ARC_ExternalPersonAuthorized__r.IsPersonAccount,
			ARC_ExternalPersonAuthorized__r.Id,
			ARC_ExternalPersonAuthorized__r.AccountId,
			ARC_ExternalPersonAuthorized__r.Account.ARC_GuardianRelationshipToChild__c
			FROM ARC_HipaaAuthorization__c
			WHERE ARC_Census__c =: member.vlocity_ins__CensusId__c
			ORDER BY ARC_AuthorizedMember__r.ARC_Age__c DESC NULLS FIRST
		];

		List<Map<String,Object>> members = new List<Map<String,Object>>();
		for (ARC_HipaaAuthorization__c h : hipaaList) {
			Map<String, Object> memberdatamap = new Map<String, Object>();
			// Census Member Above Legal Age
			if (h.ARC_AuthorizedMember__c != null){
				memberdatamap.put('id', h.ARC_AuthorizedMember__r.vlocity_ins__ContactId__r.AccountId);
				memberdatamap.put('firstname', h.ARC_AuthorizedMember__r.vlocity_ins__FirstName__c);
				memberdatamap.put('lastname', h.ARC_AuthorizedMember__r.vlocity_ins__LastName__c);
				memberdatamap.put('email', h.ARC_AuthorizedMember__r.vlocity_ins__Email__c);
				memberdatamap.put('relationship', h.ARC_AuthorizedMember__r.ARC_Relationship__c);
				memberdatamap.put('birthdate', h.ARC_AuthorizedMember__r.vlocity_ins__Birthdate__c);
				memberdatamap.put('isSelected',  h.ARC_AuthorizedMember__r.Id == member.Id ? true : false);
			}
			else if (h.ARC_ExternalPersonAuthorized__r != null) {
			// Guardian or External Authorized
				memberdatamap.put('id', h.ARC_ExternalPersonAuthorized__r.AccountId != null ? h.ARC_ExternalPersonAuthorized__r.AccountId : h.ARC_ExternalPersonAuthorized__r.Id);
				memberdatamap.put('firstname', h.ARC_ExternalPersonAuthorized__r.FirstName);
				memberdatamap.put('lastname', h.ARC_ExternalPersonAuthorized__r.LastName);
				memberdatamap.put('email', h.ARC_ExternalPersonAuthorized__r.Email);
				memberdatamap.put('relationship', h.ARC_ExternalPersonAuthorized__r.Account?.ARC_GuardianRelationshipToChild__c != null ? 'Guardian':'External Authorized Party');
				memberdatamap.put('birthdate', h.ARC_ExternalPersonAuthorized__r.Birthdate);
				memberdatamap.put('isSelected',  primaryMember.ARC_Age__c < 18? true: false);
			}
			members.add(memberdatamap);
		}

		List <Contract> contracts = [
			SELECT Id,
			CreatedDate,
			Status,
			ARC_EffectiveDate__c,
			ARC_Inactive_Date__c,
			vlocity_ins__ExpiredContractId__c,
			ARC_AppFeeOrder__c,
			ARC_RecurringMonthlyOrder__c,
			ARC_PaidThroughDate__c,
			Next_Contribution_In_sixty_Days__c
			FROM Contract 
			WHERE vlocity_ins__EnrollmentCensusId__c =: member.vlocity_ins__CensusId__c
			ORDER BY ARC_Inactive_Date__c DESC, CreatedDate DESC
		];

		List<Id> contractIds = new List<Id>();
		Map<String, List<Contract>> contractsByStatus = new Map<String, List<Contract>>();

		Contract cont;
		for(Contract con : contracts){
			contractIds.add(con.Id); 
			if (!contractsByStatus.containsKey(con.Status)) {
				contractsByStatus.put(con.Status, new List<Contract>());
			}
			contractsByStatus.get(con.Status).add(con);
		}

		if (contractsByStatus.get('Activated') != null) {
			cont = contractsByStatus.get('Activated')[0];
		} else if (contractsByStatus.get('Awaiting Activation') != null) {
			cont = contractsByStatus.get('Awaiting Activation')[0];
		} else if (contractsByStatus.get('Awaiting Signature') != null) {
			cont = contractsByStatus.get('Awaiting Signature')[0];
		} else if (
			contractsByStatus.get('Awaiting for First Payment') != null
		) {
			cont = contractsByStatus.get('Awaiting for First Payment')[0];
		}

		//Calculate Projected Paid Through Date
		Date oldestMemberBirthDate = primaryMember?.Is_Oldest_Member__c == true ? primaryMember.vlocity_ins__Birthdate__c : spouseMember != null && spouseMember.vlocity_ins__Birthdate__c != null ? spouseMember.vlocity_ins__Birthdate__c : null;
		if(Test.isRunningTest())oldestMemberBirthDate =primaryMember.vlocity_ins__Birthdate__c;
		Boolean already65 = false;
		if((primaryMember != null && primaryMember?.Is_Oldest_Member__c == true && primaryMember.ARC_Age__c != null && primaryMember.ARC_Age__c  >= 65) || (spouseMember != null && spouseMember.Is_Oldest_Member__c == true && spouseMember.ARC_Age__c!= null && spouseMember.ARC_Age__c  >= 65)) {
			already65=true;
		}

		Date nextBirthday;
		Date today = Date.today();
		if(oldestMemberBirthDate != null){
			if ((today.month() != oldestMemberBirthDate.month()) && (oldestMemberBirthDate.month() == 1)) {
				nextBirthday = Date.newInstance(
					today.year()+1,
					oldestMemberBirthDate.month(),
					oldestMemberBirthDate.day()
				);
			} else {
				nextBirthday = Date.newInstance(
					today.year(),
					oldestMemberBirthDate.month(),
					oldestMemberBirthDate.day()
				);
				if(nextBirthday < today) nextBirthday = nextBirthday.addYears(1);
			}
		}
		Date paidThroughDate = cont?.ARC_PaidThroughDate__c;
		Date projectedPaidThroughDate;
		if(paidThroughDate == null){
			paidThroughDate = cont.ARC_EffectiveDate__c.addMonths(1);
			paidThroughDate = paidThroughDate.addDays(-1); 
		}
		if(already65){
			projectedPaidThroughDate = paidThroughDate;
		}
		else{
			projectedPaidThroughDate = ARC_PersonAccount360view.lastDateOfMonth(nextBirthday);
			if(paidThroughDate.day()==14){
				projectedPaidThroughDate = Date.newInstance(nextBirthday.year(),nextBirthday.month(),14);
			}
			if(projectedPaidThroughDate <nextBirthday){
				projectedPaidThroughDate = projectedPaidThroughDate.addMonths(1);
			}
		}

		List<Ages_Up__c> ageup = [
		SELECT Id,Name,ARC_EffectiveDate__c,ARC_ManualDelay__c,ARC_PriceBeforeAgeUp__c,ARC_PriceAfterAgeUp__c,ARC_Applied__c,Contract__c,Draft_Date__c,vlocity_Ins_CensusMemberId__c,AgesUp_Census_Member_Name__c,New_Medical_Price__c,Medical_Price_With_out_HD__c,New_Price__c,Total_Price_With_Out_HD__c,Healthy_Discount__c,Healthy_Discount__r.Is_Active__c,Healthy_Discount__r.Is_HD_Expire__c,Healthy_Discount__r.Calculate_expiry_date__c,AgesUp_Birth_Date__c ,New_Total_Price_with_HD__c, ARC_Account__r.FirstName, ARC_Account__r.ARC_IsPrimaryMember__c, ARC_Account__r.PersonBirthdate 
		FROM Ages_Up__c
		WHERE Contract__c IN : contractIds];


		List<ARC_PromotionDiscount__c> HealthyDiscount = [
			SELECT Id, ARC_EndDate__c
			FROM ARC_PromotionDiscount__c
			WHERE ARC_Contract__c IN : contractIds 
				AND RecordType.DeveloperName = 'Healthy_Discount' 
                AND ARC_Status__c = 'Activated' 
                AND ARC_ContractStatus__c = 'Activated'];

		List<ARC_PromotionDiscount__c> PromotionDiscount = [
		SELECT Id,ARC_Active__c,ARC_CorePriceWithoutDiscount__c 
		FROM ARC_PromotionDiscount__c
		WHERE ARC_Contract__c IN : contractIds AND ARC_Active__c = true
		LIMIT 1];
	
		Map <Id,Contract> contractsMap = new Map <Id,Contract> (contracts);

		List<ChargentOrders__ChargentOrder__c> chargentOrders =[
			SELECT 
			ChargentOrders__Card_Month_Indicator__c, 
			ChargentOrders__Card_Year_Indicator__c, 
			ChargentOrders__Charge_Date__c, 
			ChargentOrders__Total__c, 
			ChargentOrders__Charge_Amount__c, 
			ChargentOrders__Payment_Method__c, 
			ChargentOrders__Card_Last_4__c, 
			ChargentOrders__Bank_Account_Last_4__c, 
			ChargentOrders__Card_Type__c, 
			ChargentOrders__Bank_Account_Name__c,
			ChargentOrders__Bank_Name__c,
			ChargentOrders__Next_Transaction_Date__c,
			ChargentOrders__Payment_Frequency__c,
			ARC_Contract__c,
			ARC_Contract__r.Status,
			ChargentOrders__Tokenization__c,
			ChargentOrders__Description__c,
			(SELECT ChargentOrders__Amount__c,ChargentOrders__Response_Status__c FROM ChargentOrders__Transactions__r)
			FROM ChargentOrders__ChargentOrder__c
			WHERE ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c =: member.vlocity_ins__CensusId__c
			ORDER BY CreatedDate DESC
		];

		List<Document> documents = [
			SELECT Id,Name
			FROM Document
			WHERE Name IN: new List<String>{
				'EFTForm',
				'HealthyDiscountLabResultsCriteria',
				'UHSMLabOrder',
				'FacebookIcon',
				'TwitterIcon',
				'LinkedinIcon',
				'InstagramIcon',
				'WeShareLogo',
				'WeShareAsterisk',
				'Separator',
				'WeShareUHSM',
                'NonLocatesLabOrderForm'
			}
		];

		Map<String, Object> imageURLs = new Map<String, Object>();


		for (Document d : documents) {
			String documentUrl = d.Name == 'EFTForm' || d.Name == 'UHSMLabOrder' || d.Name == 'HealthyDiscountLabResultsCriteria' || d.Name == 'NonLocatesLabOrderForm' ?
			'https://'+ String.valueof(System.URL.getSalesforceBaseURL().gethost())+'/servlet/servlet.FileDownload?file='+ d.Id : // For PDF Documents
			'https://'+ String.valueof(System.URL.getSalesforceBaseURL().gethost())+'/servlet/servlet.ImageServer?id='+ d.Id + '&oid=' + [SELECT Id FROM Organization].Id; // For Images
			imageURLs.put(d.Name, documentUrl);
		}

		outMap.put('memberid', primaryMember.Member_ID__c);
		outMap.put('memberide123', primaryMember.e123_member_id_from_policy__c);
		outMap.put('members', members);
		outMap.put('primaryMember', primaryMember);
		outMap.put('projectedPaidThroughDate', projectedPaidThroughDate);
		outMap.put('plans', plans);
		outMap.put('censusMemberId', member);
		outMap.put('chargentOrders', chargentOrders);
		outMap.put('contracts', contracts);
		outMap.put('imageURLs',imageURLs);
		outMap.put('ageup',ageup);
		outMap.put('currentUser',UserInfo.getName());
		outMap.put('HealthyDiscount',HealthyDiscount);		
		outMap.put('PromotionDiscount',PromotionDiscount);

 	}

	/*******************************************************************
	* @MethodName         :   getCaseRecord
	* @Description        :   Get the case record information based on the case id.
	********************************************************************/
	public static void getCaseRecord(Map < String, Object > inputMap, Map < String, Object > outMap) {
		Id caseId = (Id) inputMap.get('caseId');
		Case caseRecord = [SELECT Id, ARC_PersonAccount__c, ARC_PersonAccount__r.Census_Member__c FROM Case WHERE Id =: caseId LIMIT 1];
		outMap.put('caseRecord', caseRecord);
	}
}