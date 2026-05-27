/*******************************************************************
* @ClassName          :   ARC_ContractSearchBar
* @Description        :   Used to generate the contract list (aRC_ContractList360)(LWC) needed data used in the member/person account 360 view
* @MethodName         :   getContracts360, getContractLineItemFields, formatContractLineItemsFor360
********************************************************************/
public with sharing class ARC_ContractSearchBar {
    /*******************************************************************
    * @MethodName         :   getContracts360
    * @Description        :   ("main") Generates the List of JSONs used to generate the contract list (aRC_ContractList360)(LWC)
    ********************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> getContracts360(String keyString, Id recordId){

        List<Map<String,Object>> contractList = new List<Map<String,Object>>();

        Set<Id> contractIds = new Set<Id>();
        Set<Id> spinoffDraftContractIds = new Set<Id>();

        List<vlocity_ins__ContractLineItem__c> contractLineItems = new List<vlocity_ins__ContractLineItem__c>();
        String personFilter;
        keyString = keyString.trim();
        if(recordId.getSobjectType().getDescribe().getName() == 'vlocity_ins__GroupCensusMember__c'){	
            personFilter = 'vlocity_ins__GroupCensusMemberId__c =\''+recordId+'\'';
        }else if(recordId.getSobjectType().getDescribe().getName() == 'Account'){	
            personFilter = 'vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId = \''+recordId+'\'';

            List<ARC_ContractParticipant__c> spinOffDraftCP = [SELECT Id, ARC_Contract__c FROM ARC_ContractParticipant__c WHERE ARC_PersonAccount__c = :recordId AND ARC_Contract__r.Status = 'Draft' AND ARC_Contract__r.ARC_ContractReason__c INCLUDES('Spin Off')];

            if(spinOffDraftCP.size() > 0) {
                for(ARC_ContractParticipant__c cp : spinOffDraftCP){
                    spinoffDraftContractIds.add(cp.ARC_Contract__c);
                }
                system.debug('spinoffDraftcontractIds ' + spinoffDraftContractIds);

                List<Contract> spinoffDraftContractsList = [
                    SELECT Id, ContractNumber, Status, ARC_ContractReason__c, ARC_EffectiveDate__c, ARC_Selling_Agent__r.Name, OwnerId, (SELECT Id, Name FROM Contract_Participants__r)
                    FROM Contract
                    WHERE Id IN :spinoffDraftContractIds
                    ORDER BY CreatedDate DESC
                ];

                if(spinoffDraftContractsList.size() > 0) {
                    // Build a map of picklist API values to labels for ARC_ContractReason__c (multi-select)
                    Schema.DescribeFieldResult reasonDescribe = Contract.ARC_ContractReason__c.getDescribe();
                    Map<String,String> contractReasonMap = new Map<String,String>();
                    for (Schema.PicklistEntry pe : reasonDescribe.getPicklistValues()) {
                        contractReasonMap.put(pe.getValue(), pe.getLabel());
                    }
                    for(Contract c : spinoffDraftContractsList){
                        Map<String,Object> contractMap = new Map<String,Object>();
                        List<String> contractMembersList = new List<String>();
                        contractMap.put('id', c.id);
                        contractMap.put('status', c.Status);
                        contractMap.put('contractNumber', c.ContractNumber);
                        contractMap.put('effectiveDate', c.ARC_EffectiveDate__c);
                        // Convert multi-select picklist API values to labels
                        String reasonLabel = '';
                        if (c.ARC_ContractReason__c != null) {
                            for (String v : c.ARC_ContractReason__c.split(';')) {
                                String key = v != null ? v.trim() : null;
                                if (String.isNotBlank(key)) {
                                    String label = contractReasonMap.containsKey(key) ? contractReasonMap.get(key) : key;
                                    reasonLabel += (reasonLabel == '' ? '' : '; ') + label;
                                }
                            }
                        }
                        contractMap.put('reason', reasonLabel);
                        contractMap.put('sellingAgent', c.ARC_Selling_Agent__r.Name);
                        contractMap.put('ownerId', c.OwnerId);
                        for (ARC_ContractParticipant__c cp : c.Contract_Participants__r) {
                            contractMembersList.add(cp.Name);
                        }
                        String  contractMembers = String.join(contractMembersList, ', ');
                        contractMap.put('members', contractMembers);
                        system.debug('contractMap ' + contractMap);
                        contractList.add(contractMap);
                    }
                }
            }
        }

        if (personFilter != null) {
            for (vlocity_ins__ContractLineItem__c contractLineItem : Database.query(
            'SELECT Id, vlocity_ins__ContractId__c '+
            'FROM vlocity_ins__ContractLineItem__c '+
            'WHERE vlocity_ins__RecordTypeName__c = \'Product\' AND vlocity_ins__ProductType__c = \'Medical\''+
            'AND (vlocity_ins__ContractId__r.contractNumber LIKE \'%'+keyString+'%\' OR vlocity_ins__ContractId__r.Status LIKE \'%'+keyString+'%\') AND  vlocity_ins__ContractId__r.Status != \'Draft\''+
            'AND Id IN (SELECT vlocity_ins__ContractLineId__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE '+ personFilter +') ORDER BY vlocity_ins__ContractId__r.ARC_EffectiveDate__c DESC')) {
                contractIds.add(contractLineItem.vlocity_ins__ContractId__c);
            }
            contractLineItems = Database.query(
                'SELECT '+getContractLineItemFields()+' '+
                'FROM vlocity_ins__ContractLineItem__c '+
                'WHERE vlocity_ins__RecordTypeName__c = \'Product\' '+
                'AND vlocity_ins__ContractId__c IN :contractIds ORDER BY vlocity_ins__ContractId__r.ARC_EffectiveDate__c DESC');
        }
        
        contractList.addAll(formatContractLineItemsFor360(contractLineItems));

        //return formatContractLineItemsFor360(contractLineItems);
        return contractList;
    }

    /*******************************************************************
    * @MethodName         :   getContractLineItemFields
    * @Description        :   returns a list of the contract line items fields used in the query
    ********************************************************************/
    private static String getContractLineItemFields(){
        return 'Id,'+       
        '(SELECT Id, vlocity_ins__GroupCensusMemberId__c, vlocity_ins__GroupCensusMemberId__r.Name, vlocity_ins__GroupCensusMemberId__r.ARC_ActiveMember__c, vlocity_ins__GroupCensusMemberId__r.ARC_DependentRelationship__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId FROM vlocity_ins__Group_Census_Member_Plan__r)members,'+
        'vlocity_ins__ContractId__c,'+
        'vlocity_ins__ContractId__r.Status,'+
        'vlocity_ins__ContractId__r.ContractNumber,'+
        'vlocity_ins__ContractId__r.ARC_EffectiveDate__c,'+
        'vlocity_ins__ContractId__r.ARC_PaidThroughDate__c,'+
        'vlocity_ins__ContractId__r.ARC_ContractReason__c,'+
        'vlocity_ins__ContractId__r.ARC_CancellationReason__c,'+
        'vlocity_ins__ContractId__r.OwnerId,'+
        'vlocity_ins__ContractId__r.ARC_Inactive_Date__c,'+
        'vlocity_ins__ContractId__r.ARC_Case__r.ARC_repricedContract__c,'+
        'vlocity_ins__Product2Id__r.Name,'+
        'vlocity_ins__ProductType__c,'+
        'vlocity_ins__ProductSubType__c,'+
        'vlocity_ins__ContractId__r.ARC_Selling_Agent__r.Name';
    }

    /*******************************************************************
    * @MethodName         :   formatContractLineItemsFor360
    * @Description        :   based on a list of vlocity_ins__ContractLineItem__c, returns a formatted list that will be used in (aRC_ContractList360)(LWC)
    ********************************************************************/
    private static List<Map<String,Object>> formatContractLineItemsFor360(List<vlocity_ins__ContractLineItem__c> contractLineItems){
        List<Map<String,Object>> contractList = new List<Map<String,Object>>();
        Map<Id,String> contractProductNames = getOrderedProductNames(contractLineItems);
        // Get the Contract Status field describe result
        Schema.DescribeFieldResult fieldDescribe = Contract.Status.getDescribe();
        // Get the picklist values for the Contract Status field
        List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
        // Loop through the picklist values
        Map<String,String> contractStatusMap = new Map<String,String>();
        for(Schema.PicklistEntry picklistEntry : picklistValues) {
            contractStatusMap.put(picklistEntry.getValue(),picklistEntry.getLabel());
        }
        // Prepare map of ARC_ContractReason__c values to labels (multi-select)
        Schema.DescribeFieldResult reasonDescribe = Contract.ARC_ContractReason__c.getDescribe();
        Map<String,String> contractReasonMap = new Map<String,String>();
        for (Schema.PicklistEntry pe : reasonDescribe.getPicklistValues()) {
            contractReasonMap.put(pe.getValue(), pe.getLabel());
        }
        // Add contract Ids to set and get permanent members for that set of contracts
        Set<Id> contractIds = new Set<Id>();
        Set<Id> newbornIds = new Set<Id>();
        for (vlocity_ins__ContractLineItem__c cli : contractLineItems) {
            contractIds.add(cli.vlocity_ins__ContractId__c);
            for (vlocity_ins__GroupCensusMemberPlan__c member : cli.vlocity_ins__Group_Census_Member_Plan__r) {
                if(member?.vlocity_ins__GroupCensusMemberId__r?.ARC_DependentRelationship__c == 'Temporary Newborn' || member?.vlocity_ins__GroupCensusMemberId__r?.ARC_DependentRelationship__c == 'Child'){
                    newbornIds.add(member?.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c);
                }
            }
        }
        Map<Id,List<Id>> contractToPermanentMembersMap = getPermanentMembers(contractIds);
        // Get policy participants for newborns per contract
    Map<Id,Map<Id,Object>> contractToPolicyParticipantsMap = getPolicyParticipantPerContract(contractIds,newbornIds);
    Map<Id, List<ContractInfo>> contractsBasedOnNewbornsMap = getRelatedContractBasedOnNewborns(contractIds,newbornIds);
        System.debug('policy participants map: ' + contractToPolicyParticipantsMap);
        System.debug('contract permanent members: ' + contractToPermanentMembersMap);
        for (vlocity_ins__ContractLineItem__c contractLineItem : contractLineItems) {
            if (contractLineItem.vlocity_ins__ProductType__c == 'Medical') {
                Map<String,Object> contractMap = new Map<String,Object>();
                String memberListString = '';
                String memberListTNString = ''; // String to add the Names of the Temporary Newborns
                contractMap.put('id', contractLineItem.vlocity_ins__ContractId__c);
                contractMap.put('status', contractStatusMap.get(contractLineItem.vlocity_ins__ContractId__r.Status));
                contractMap.put('contractNumber', contractLineItem.vlocity_ins__ContractId__r.ContractNumber);
                contractMap.put('effectiveDate', contractLineItem.vlocity_ins__ContractId__r.ARC_EffectiveDate__c);
                if(contractLineItem.vlocity_ins__ContractId__r.ARC_PaidThroughDate__c != null){
                    contractMap.put('paidThroughDate', DateTime.newInstance(
                                                    contractLineItem.vlocity_ins__ContractId__r.ARC_PaidThroughDate__c.year(),
                                                    contractLineItem.vlocity_ins__ContractId__r.ARC_PaidThroughDate__c.month(), 
                                                    contractLineItem.vlocity_ins__ContractId__r.ARC_PaidThroughDate__c.day()).format('MM/dd/yyyy'));
                }
                // Convert multi-select picklist API values to labels
                String reasonLabel = '';
                if (contractLineItem.vlocity_ins__ContractId__r.ARC_ContractReason__c != null) {
                    List<String> labels = new List<String>();
                    for (String v : contractLineItem.vlocity_ins__ContractId__r.ARC_ContractReason__c.split(';')) {
                        String key = v != null ? v.trim() : null;
                        if (String.isNotBlank(key)) {
                            labels.add(contractReasonMap.containsKey(key) ? contractReasonMap.get(key) : key);
                        }
                    }
                    reasonLabel = String.join(labels, '; ');
                }
                contractMap.put('reason', reasonLabel);
                contractMap.put('cancellationReason', contractLineItem.vlocity_ins__ContractId__r.ARC_CancellationReason__c);
                contractMap.put('sellingAgent', contractLineItem.vlocity_ins__ContractId__r.ARC_Selling_Agent__r.Name);
                contractMap.put('ownerId', contractLineItem.vlocity_ins__ContractId__r.OwnerId);
                if(contractLineItem.vlocity_ins__ContractId__r.ARC_Inactive_Date__c != null){
                    contractMap.put('inactiveDate', DateTime.newInstance(
                                                    contractLineItem.vlocity_ins__ContractId__r.ARC_Inactive_Date__c.year(),
                                                    contractLineItem.vlocity_ins__ContractId__r.ARC_Inactive_Date__c.month(), 
                                                    contractLineItem.vlocity_ins__ContractId__r.ARC_Inactive_Date__c.day()).format('MM/dd/yyyy'));
                }
                contractMap.put('productName', contractProductNames.get(contractLineItem.vlocity_ins__ContractId__c).removeEnd(', '));
                if (contractLineItem.vlocity_ins__ContractId__r.ARC_Case__r.ARC_repricedContract__c) {
                    contractMap.put('repriced', contractLineItem.vlocity_ins__ContractId__r.ARC_Case__r.ARC_repricedContract__c ? 'Yes': null);
                }

                // Get permanent members of current contract
                List<Id> permanentMembersIds = contractToPermanentMembersMap.get(contractLineItem.vlocity_ins__ContractId__c);
                //Skip Contracts without Contract Participants 
                if(permanentMembersIds == null){
                    continue;
                }
                for (vlocity_ins__GroupCensusMemberPlan__c member : contractLineItem.vlocity_ins__Group_Census_Member_Plan__r) {
                    Id accountId = member?.vlocity_ins__GroupCensusMemberId__r?.vlocity_ins__ContactId__r?.AccountId;
                    Boolean isActiveMember = member?.vlocity_ins__GroupCensusMemberId__r?.ARC_ActiveMember__c;
                    Boolean isPermanentMember = false;

                    // Boolean to check if current member is a Temporary Newborn
                    Boolean isTemporaryNewborn = member?.vlocity_ins__GroupCensusMemberId__r?.ARC_DependentRelationship__c == 'Temporary Newborn' || member?.vlocity_ins__GroupCensusMemberId__r?.ARC_DependentRelationship__c == 'Child' ? true : false;

                    // Iterate over each permanent member and check if current member is on its list
                    for (Id memberId : permanentMembersIds) {
                        if (memberId == accountId) {
                            // Set variable to true and stop iterating
                            isPermanentMember = true;
                            break;
                        }
                    }
                    // if (isActiveMember || (isActiveMember == false && isPermanentMember)) {
                    if (isPermanentMember) {
                        memberListString += member.vlocity_ins__GroupCensusMemberId__r.Name + ', ';
                    }

                    // Temporary Newborns not are permanent members because don't have contract participants
                    if (isTemporaryNewborn && !isPermanentMember) { 
                        String memberContactId = member.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c;
                        InsurancePolicyParticipant ipp;
                        //Check if policy participant map exists for current contract
                        if(contractToPolicyParticipantsMap != null && contractToPolicyParticipantsMap.containsKey(contractLineItem.vlocity_ins__ContractId__c)) {
                            Map<Id,Object> policyParticipantsMap = contractToPolicyParticipantsMap.get(contractLineItem.vlocity_ins__ContractId__c);
                            // Check if the policy participant exists for the current member
                            if (policyParticipantsMap != null && policyParticipantsMap.containsKey(memberContactId)) {
                                //Get policy participant if exists
                                ipp = (InsurancePolicyParticipant)policyParticipantsMap.get(memberContactId);
                            }
                        }
                        Date ippEndDate = ipp != null ? ipp.ARC_EndDate__c : null;
                        // We get contractInfo based on newborns
                        ContractInfo contractInfo = resolveRelatedContract(contractLineItem.vlocity_ins__ContractId__c, contractsBasedOnNewbornsMap, ippEndDate);
                        Boolean hasGapInCoverage = false;
                        Boolean isPermanentNewborn = false;
                        // Check if contractInfo exists and if the member is a contract participant (added as permanent newborn)
                        if(contractInfo != null && contractInfo.participants.containsKey(memberContactId)) {
                            isPermanentNewborn = true;
                            if (ippEndDate != null && contractInfo.effectiveDate != null) {
                                hasGapInCoverage = ippEndDate.addDays(1) != contractInfo.effectiveDate;
                            }
                        }
                        System.debug('Temporary Newborn: ' + member.vlocity_ins__GroupCensusMemberId__r.Name + ' | hasGapInCoverage: ' + hasGapInCoverage + ' | isPermanentNewborn: ' + isPermanentNewborn);
                        // Add indicator for Temporary Newborns with gap and those who are only temporary
                        if(hasGapInCoverage || !isPermanentNewborn){
                            memberListTNString += member.vlocity_ins__GroupCensusMemberId__r.Name + ' * , ';
                        }else{
                            memberListTNString += member.vlocity_ins__GroupCensusMemberId__r.Name + ', ';
                        }
                    }
                }
                contractMap.put('members', memberListString.removeEnd(', '));
                contractMap.put('temporaryNewborns', memberListTNString.removeEnd(', ')); // Added Temporary Newborns Map
                contractList.add(contractMap);
            }
        }
        return contractList;
    }

    /*******************************************************************
    * @MethodName         :   getOrderedProductNames
    * @Description        :   orders the products in this order: MEDICAL, SMART, AIDD. And returns a map of contractIds and their related products.
    ********************************************************************/
    private static Map<Id,String> getOrderedProductNames( List<vlocity_ins__ContractLineItem__c> contractLineItems){
        Map<Id,String> contractProductNames = new Map<Id,String>();
        for (vlocity_ins__ContractLineItem__c contract : contractLineItems) {
            String productsNames = '';
            String smart = '';
            String aidd = '';
            for (vlocity_ins__ContractLineItem__c contractLineItem : contractLineItems) {
                if (contract.vlocity_ins__ContractId__c == contractlineItem.vlocity_ins__ContractId__c) {
                    if (contractLineItem.vlocity_ins__ProductType__c == 'Medical'){
                        productsNames = contractLineItem.vlocity_ins__Product2Id__r.Name + ', ';
                    }
                    if (contractLineItem.vlocity_ins__ProductSubType__c == 'SMART'){
                        smart += contractLineItem.vlocity_ins__Product2Id__r.Name + ', ';
                    }            
                    if (contractLineItem.vlocity_ins__ProductSubType__c == 'AIDD'){
                        aidd += contractLineItem.vlocity_ins__Product2Id__r.Name + ', ';
                    }
                }
            }
            productsNames = productsNames + smart + aidd;
            contractProductNames.put(contract.vlocity_ins__ContractId__c, productsNames);
        }
        return contractProductNames;
    }

    /*******************************************************************
    * @MethodName         :   getContractParticipantsMap
    * @Description        :   Method to get a map of the permanent members from a set of contracts to exclude temporary newborns
    ********************************************************************/

    private static Map<Id,List<Id>> getPermanentMembers (Set<Id> contractIds) {
        Map<Id,List<Id>> contractToPermanentMembersMap = new Map<Id,List<Id>>();
        List<ARC_ContractParticipant__c> cpList = [SELECT Id, ARC_Contract__c, ARC_PersonAccount__c, ARC_Relationship__c FROM ARC_ContractParticipant__c WHERE ARC_Contract__c IN :contractIds ];
        for (ARC_ContractParticipant__c cp : cpList) {
            Id contractId = cp.ARC_Contract__c;
            if (!contractToPermanentMembersMap.containsKey(contractId)) {
                contractToPermanentMembersMap.put(contractId, new List<Id>());
            }
            contractToPermanentMembersMap.get(contractId).add(cp.ARC_PersonAccount__c);
        }
        return contractToPermanentMembersMap;
    }

    

    /*******************************************************************
    * @MethodName         :   getPolicyParticipantPerContract
    * @Description        :   Method to get a map of the policy participants (newborns) from a set of contracts
    ********************************************************************/

    private static Map<Id,Map<Id,Object>> getPolicyParticipantPerContract (Set<Id> contractIds, Set<Id> newbornIds) {
        Map<Id,Map<Id,Object>> contractToPolicyParticipantsMap = new Map<Id,Map<Id,Object>>();
        List<InsurancePolicyParticipant> ippList = [SELECT Id, InsurancePolicy.ARC_Contract__c,PrimaryParticipantContactId,ARC_EndDate__c FROM InsurancePolicyParticipant WHERE InsurancePolicy.ARC_Contract__c IN :contractIds AND PrimaryParticipantContactId IN :newbornIds];

        for (InsurancePolicyParticipant ipp : ippList) {
            if (!contractToPolicyParticipantsMap.containsKey(ipp.InsurancePolicy.ARC_Contract__c)) {
                contractToPolicyParticipantsMap.put(ipp.InsurancePolicy.ARC_Contract__c, new Map<Id,Object>());
            }
            contractToPolicyParticipantsMap.get(ipp.InsurancePolicy.ARC_Contract__c).put(ipp.PrimaryParticipantContactId, ipp);
        }
        return contractToPolicyParticipantsMap;
    }

    private static ContractInfo resolveRelatedContract(Id contractId, Map<Id, List<ContractInfo>> contractsMap, Date ippEndDate) {
        return resolveRelatedContractRecursive(contractId, contractsMap, ippEndDate, new Set<Id>());
    }

    /*******************************************************************
    * @MethodName         :   resolveRelatedContractRecursive
    * @Description        :   Method to recursively find the related contract based on the current contract Id and ipp end date
    ********************************************************************/

    private static ContractInfo resolveRelatedContractRecursive(Id contractId, Map<Id, List<ContractInfo>> contractsMap, Date ippEndDate, Set<Id> visited) {
        if (contractId == null || contractsMap == null || !contractsMap.containsKey(contractId) || visited.contains(contractId)) {
            return null;
        }
        visited.add(contractId);
        List<ContractInfo> candidates = contractsMap.get(contractId);
        if (candidates == null || candidates.isEmpty()) {
            visited.remove(contractId);
            return null;
        }
        for (ContractInfo candidate : candidates) {
            if (candidate == null) {
                continue;
            }
            Boolean isVoided = 'Voided'.equalsIgnoreCase(candidate.status);
            Boolean isDraft = 'Draft'.equalsIgnoreCase(candidate.status);
            Boolean candidateValid = ippEndDate == null || (candidate.effectiveDate != null && candidate.effectiveDate > ippEndDate);
            if (candidateValid && !isVoided && !isDraft) {
                visited.remove(contractId);
                return candidate;
            }
            ContractInfo downstream = resolveRelatedContractRecursive(candidate.Id, contractsMap, ippEndDate, visited);
            if (downstream != null) {
                visited.remove(contractId);
                return downstream;
            }
        }
        if (ippEndDate == null && !candidates.isEmpty()) {
            visited.remove(contractId);
            return candidates[0];
        }
        visited.remove(contractId);
        return null;
    }

    public class ContractInfo {
        public Date effectiveDate;
        public Id Id;
        public Id relatedContractId;
        public String status;
        public Map<Id, ARC_ContractParticipant__c> participants;

        public ContractInfo() {
            participants = new Map<Id, ARC_ContractParticipant__c>();
        }
    }

    /*******************************************************************
    * @MethodName         :   getRelatedContractBasedOnNewborns
    * @Description        :   Method to get a map of contracts which have contract participants related to the newborns (permanent newborns)
    *********************************************************************/

    public static Map<Id, List<ContractInfo>> getRelatedContractBasedOnNewborns (Set<Id> contractIds, Set<Id> newbornIds) {
        Map<Id, List<ContractInfo>> contractsMap = new Map<Id, List<ContractInfo>>();

        List<Contract> contractList = [
            SELECT Id,
                   ARC_EffectiveDate__c,
                   vlocity_ins__ExpiredContractId__c,
                   Status,
                   (SELECT Id, ARC_PersonAccount__r.PersonContactId
                    FROM Contract_Participants__r
                    WHERE ARC_PersonAccount__r.PersonContactId IN :newbornIds)
            FROM Contract
            WHERE vlocity_ins__ExpiredContractId__c IN :contractIds
        ];

        for (Contract con : contractList) {
            Id expiredId = con.vlocity_ins__ExpiredContractId__c;
            ContractInfo info = new ContractInfo();
            info.effectiveDate = con.ARC_EffectiveDate__c;
            info.Id = con.Id;
            info.relatedContractId = expiredId;
            info.status = con.Status;
            if (con.Contract_Participants__r != null) {
                for (ARC_ContractParticipant__c cp : con.Contract_Participants__r) {
                    Id newbornId = cp.ARC_PersonAccount__r.PersonContactId;
                    info.participants.put(newbornId, cp);
                }
            }
            if (!contractsMap.containsKey(expiredId)) {
                contractsMap.put(expiredId, new List<ContractInfo>());
            }
            contractsMap.get(expiredId).add(info);
        }

        return contractsMap;
    }
}