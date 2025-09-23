global without sharing class ARC_ContractChanges implements vlocity_ins.VlocityOpenInterface2 {

    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'processChanges') {
            processChanges(inputMap, outputMap, options);
        }else if (methodName == 'processChangesResendContract') {
            processChangesResendContract(inputMap, outputMap, options);
        }
        return true;
    }

    global static void processChanges(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){

		List<Object> changesForContracts = (List<Object>)inputMap.get('changesForContracts');
		List<Map<String,Object>> changesList = new List<Map<String,Object>>();

		String outputActualChanges = '';
		String outputString = '';
		List<Map<String, Object>> oldMedicalProducts = new List<Map<String, Object>> ();
		Boolean keepSMART = false;
		Boolean keepAIDD = false;
		keepSMART = (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepSMART');
		if(inputMap.get('showAddAncillaryChooseProductsKeepSMART') != null && inputMap.get('showAddAncillaryChooseProductsKeepSMART') != '' ){
			keepSMART = (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepSMART');
		}
		if(inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != null && inputMap.get('showAddAncillaryChooseProductsKeepAIDD') != '' ){
			keepAIDD = (Boolean)inputMap.get('showAddAncillaryChooseProductsKeepAIDD');
		}


		for (Object contract : changesForContracts) {
			Map<String,Object> c = (Map<String,Object>)contract;
			Map<String, Object> changesMap = new Map<String, Object>();

			String singleReason = String.valueOf(c.get('SingleReason'));

			if (singleReason.contains('Remove Member')) {
				List<Object> RemovedMembersList = (List<Object>)c.get('RemovedMembers');
				String RemovedMembersString = '';
				for (Object RM : RemovedMembersList) {
					Map<String,Object> Rmember = (Map<String,Object>)RM;

					if ((Boolean)Rmember.get('CHK_Delete') == true) {
						RemovedMembersString += (String)Rmember.get('TXT_FirstNameEB') + ' ' + (String)Rmember.get('TXT_LastNameEB') + ',';
					}
				}
				RemovedMembersString = RemovedMembersString.removeEnd(',');
				outputActualChanges += 'Remove Member' + ', ';
				outputString += (String)c.get('effectiveDate') +' '+ 'Remove Member' +' '+ RemovedMembersString + '\n';


			}

			if (singleReason.contains('Add Member') || singleReason.contains('Add Newborn') || singleReason.contains('Add Existing Member')){
				List<Object> auxSavedMembers = (List<Object>)c.get('auxSavedMembers');
				String AddedMembersString = '';

				for (Object AM : auxSavedMembers) {
					Map<String,Object> Amember = (Map<String,Object>)AM;
					if((Boolean)Amember.get('isNew') == true){
						AddedMembersString += (String)Amember.get('vlocity_ins__FirstName__c') + ' ' + (String)Amember.get('vlocity_ins__LastName__c') + ',';
					}
				}
				AddedMembersString = AddedMembersString.removeEnd(',');
				if(singleReason.contains('Add Member') || singleReason.contains('Add Existing Member')){
					outputActualChanges += 'Add Member' + ', ';
				}else{
					outputActualChanges += 'Add New Born' + ', ';
				}
				outputString += (String)c.get('effectiveDate') +' '+ 'Add Member' +' '+ AddedMembersString + '\n';

			}

			if (singleReason.contains('Program Upgrade') || singleReason.contains('Program Downgrade') ){
				String newProgramName = (String)c.get('MedicalName');
				String programReason = singleReason.contains('Program Upgrade') ? 'Program Upgrade' : 'Program Downgrade';
				outputActualChanges += programReason + ', ';
				outputString += (String)c.get('effectiveDate') +' '+ programReason +' to '+ newProgramName + '\n';
			}

			if ( singleReason.contains('Add Ancillary Product') ) {
				List<Object> productLists = (List<Object>)c.get('productList');
				if ( !productLists.isEmpty() ) {
					String addAncillaryOutput = (String)c.get('effectiveDate') + ' Change Ancillary Product(s) to: ';
					Integer ancillaryChangesCount = 0;
					for ( Object product : productLists ) {
						Map<String,Object> p = (Map<String,Object>)((Map<String,Object>)product).get('selectedProduct');
						if ( (String)p.get('Type__c') == 'Medical') {
							oldMedicalProducts.add(new Map<String, Object>{'Name' => (String)p.get('Name')});
						}
						if ( (String)p.get('Type__c') == 'Ancillary' ) {
							if ( (String)p.get('SubType__c') == 'SMART' && !keepSMART ) {
								oldMedicalProducts.add(new Map<String, Object>{'Name' => (String)p.get('Name')});
								ancillaryChangesCount++;
							}
							if ( (String)p.get('SubType__c') == 'AIDD' && !keepAIDD ) {
								oldMedicalProducts.add(new Map<String, Object>{'Name' => (String)p.get('Name')});
								ancillaryChangesCount++;
							}
							addAncillaryOutput += (String)p.get('Name') + ', ';
						}
					}
					if((ancillaryChangesCount != 0 || !keepAIDD || !keepSMART) || singleReason.split(';').size() == 1){
						outputActualChanges += 'Ancillary Change' + ', ';
						outputString += addAncillaryOutput.removeEnd(', ') + '\n';
					}
				}
			}

			if ( singleReason.contains('Remove Ancillary') ) {
				outputActualChanges += 'Remove Ancillary' + ', ';
				outputString += (String)c.get('effectiveDate') + ' Remove Ancillary\n';
			}
			// if (changesMap.isEmpty() == false) {
			// 	changesList.add(changesMap);
			// }
		}
		
		outputMap.put('actualChanges',outputActualChanges.removeEnd(', '));
        outputMap.put('changesList', outputString.removeEnd('\n'));
        outputMap.put('oldMedicalProducts', oldMedicalProducts);
    }

	global static void processChangesResendContract(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
		String contractReason = (String)inputMap.get('contractReason');
		String effectiveDate = (String)inputMap.get('effectiveDate');
		List<String> changesList = contractReason.split(';');
		String outputActualChanges = '';
		String oldMedicalProducts = '';
		String outputString = '';

		for(String change : changesList){
			//Program upgrade & downgrade
			if(change.contains('Program Upgrade') || change.contains('Program Downgrade')){
				String newProgramName = (String)inputMap.get('newCoreProgram');
				String programReason = change.contains('Program Upgrade') ? 'Program Upgrade' : 'Program Downgrade';
				outputActualChanges += programReason + ', ';
				outputString += effectiveDate +' '+ programReason +' to '+ newProgramName + ', \n';
				//outputString += effectiveDate +' '+ programReason +' to '+ newProgramName ;
			}
			// Add and Remove members
			if (change.contains('Remove Member') || change.contains('Add Member') || change.contains('Add Newborn') || change.contains('Add Existing Member')){
				List<Object> censusmemberListOld = (List<Object>)inputMap.get('censusmemberListOld');
				List<Object> censusmemberListNew = (List<Object>)inputMap.get('censusmemberListNew');
				String AddedMembersString = '';
				String RemovedMembersString = '';
				
				// find removed
				if(change.contains('Remove Member')){
					RemovedMembersString = findMissingMembers(censusmemberListNew, censusmemberListOld, 'remove', false);
					if(RemovedMembersString != ''){
						outputString += effectiveDate +' '+ 'Remove Member' +' '+ RemovedMembersString + ', \n';
						outputActualChanges += 'Remove Member' + ', ';
					}
				}
				// find added
				if( change.contains('Add Member') || change.contains('Add Newborn') || change.contains('Add Existing Member')) {
					AddedMembersString = findMissingMembers(censusmemberListOld, censusmemberListNew, 'add', change.contains('Add Newborn'));
					if(AddedMembersString != ''){
						outputString += effectiveDate +' '+ 'Add Member' +' '+ AddedMembersString + ', \n';	
						AddedMembersString = AddedMembersString.removeEnd(',');
						if(change.contains('Add Member') || change.contains('Add Existing Member')){
							outputActualChanges += 'Add Member' + ', ';
						}else{
							outputActualChanges += 'Add New Born' + ', ';
						}
					}
				}
			}

		}
		
		outputMap.put('actualChanges', outputActualChanges.removeEnd(', '));
        outputMap.put('changesList', outputString.removeEnd(', \n'));
        outputMap.put('oldMedicalProducts', oldMedicalProducts);
	}


	// recieves 2 params : searches for cm in list A (second param) on list B (fisrt param).
	// returns string of member names not found-
	//for REMOVE ListA is oldList, ListB newList
	//for ADD 	 ListA is newList, ListB oldList
	private static String findMissingMembers (List<Object> listB, List<Object> listA, String changeType, Boolean lookForNewborn){

		String membersNotFoundStr = '';
		for( Object cmAObj : listA){
			Map<String, Object> cmA = (Map<String, Object>)cmAObj; 
			Id memberId = (Id)cmA.get('Id');
			Boolean foundMember = false;
			for (Object cmObj : listB){
				Map<String, Object> cm = (Map<String, Object>)cmObj; 
				if( (Id)cm.get('Id') == memberId ) { foundMember = true; }
			}
			if(!foundMember) { 
				if(changeType == 'remove'){
					membersNotFoundStr += (String)cmA.get('vlocity_ins__FirstName__c') + ' ' + (String)cmA.get('vlocity_ins__LastName__c') + ', '; 
				}else if(changeType == 'add'){
					if(!foundMember && lookForNewborn && parseStringToDate((String)cmA.get('vlocity_ins__Birthdate__c')) >= System.today().addDays(-90)){
						membersNotFoundStr += (String)cmA.get('vlocity_ins__FirstName__c') + ' ' + (String)cmA.get('vlocity_ins__LastName__c') + ', '; 
					}else if(!foundMember && !lookForNewborn && parseStringToDate((String)cmA.get('vlocity_ins__Birthdate__c')) < System.today().addDays(-90)){
						membersNotFoundStr += (String)cmA.get('vlocity_ins__FirstName__c') + ' ' + (String)cmA.get('vlocity_ins__LastName__c') + ', '; 
					}
				}
			}
			
		}
		membersNotFoundStr = membersNotFoundStr.removeEnd(', ');
		return membersNotFoundStr;
	}

	private static Date parseStringToDate(String inputDate){
		List<String> splitDate = (List<String>)inputDate.split('/');
		return Date.newInstance(Integer.valueOf(splitDate[2]), Integer.valueOf(splitDate[0]), Integer.valueOf(splitDate[1]));
	}
}