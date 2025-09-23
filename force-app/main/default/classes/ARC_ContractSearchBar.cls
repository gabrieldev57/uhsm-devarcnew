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
                    for(Contract c : spinoffDraftContractsList){
                        Map<String,Object> contractMap = new Map<String,Object>();
                        List<String> contractMembersList = new List<String>();
                        contractMap.put('id', c.id);
                        contractMap.put('status', c.Status);
                        contractMap.put('contractNumber', c.ContractNumber);
                        contractMap.put('effectiveDate', c.ARC_EffectiveDate__c);
                        contractMap.put('effectiveDate', c.ARC_EffectiveDate__c);
                        contractMap.put('reason', c.ARC_ContractReason__c);
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
        '(SELECT Id, vlocity_ins__GroupCensusMemberId__c, vlocity_ins__GroupCensusMemberId__r.Name, vlocity_ins__GroupCensusMemberId__r.ARC_ActiveMember__c, vlocity_ins__GroupCensusMemberId__r.ARC_DependentRelationship__c FROM vlocity_ins__Group_Census_Member_Plan__r)members,'+
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
        for (vlocity_ins__ContractLineItem__c contractLineItem : contractLineItems) {
            if (contractLineItem.vlocity_ins__ProductType__c == 'Medical') {
                Map<String,Object> contractMap = new Map<String,Object>();
                String memberListString = '';
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
    
                contractMap.put('reason', contractLineItem.vlocity_ins__ContractId__r.ARC_ContractReason__c?.replace(';', '; '));
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
                for (vlocity_ins__GroupCensusMemberPlan__c member : contractLineItem.vlocity_ins__Group_Census_Member_Plan__r) {
                    Boolean isActiveMember = member?.vlocity_ins__GroupCensusMemberId__r?.ARC_ActiveMember__c;
                    String memberRelationship = member?.vlocity_ins__GroupCensusMemberId__r?.ARC_DependentRelationship__c;
                    if (isActiveMember || (isActiveMember == false && memberRelationship != 'Temporary Newborn')) {
                        memberListString += member.vlocity_ins__GroupCensusMemberId__r.Name + ', ';
                    }
                }
                contractMap.put('members', memberListString.removeEnd(', '));
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
}