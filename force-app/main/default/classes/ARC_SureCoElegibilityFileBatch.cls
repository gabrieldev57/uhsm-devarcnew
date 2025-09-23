global with sharing class ARC_SureCoElegibilityFileBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    public Set<Id> useThisCensuses = new Set<Id>();
    private Set<Id> contractsAlreadyInFile = new Set<Id>();
    public List<String> sendToEmails = new List<String>();
    
    private Boolean first = true;
    private Boolean last = false;
    public Boolean isFullData = false;
    public Boolean justTerminated = false;
    public Boolean updateLastSent = true;
    public Boolean sendToTestSite = false;

    private Datetime oggi = Datetime.now();
    public Datetime sinceDate;
    private Datetime lastSent;
    
    private Integer memberCount = 0;
    public Integer limitRecords = 0;
    
    private String fileName = Datetime.now().format('YYYYMMdd_HHmmss', 'America/Los_Angeles')+'_UHSM.csv';
    private String stringTXT = 'customer_id,unique_id,primary_unique_id,firstname,middlename,lastname,member_created_timestamp,member_updated_timestamp,dob,address,address2,city,state,zipcode,phone,phone2,email,gender,ssn,member_type,relationship_to_primary,policy_number,product_label,product_created_timestamp,product_cancelled_timestamp,product_effective_timestamp,policy_status,coverage_type,product_unique_id,policy_billing_date,policy_paid_through_date,policy_cancel_reason,policy_hold_date,policy_ hold_reason,policy_hold_type,policy_fulfillment_date,policy_renewal_date,policy_recurring_date,policy_hold_flag,sequence_id,member_status, height, weight';
    
    
    ARC_Eligible_Files__c elegibileFile = [
        SELECT Name,ARC_LastSent_Datetime__c, ARC_EmailsToNotify__c
        FROM ARC_Eligible_Files__c 
        WHERE Name = 'SureCo' 
        LIMIT 1
    ];

        
    global ARC_SureCoElegibilityFileBatch(){
        setLastSent();
    }

    global ARC_SureCoElegibilityFileBatch( Boolean fullData){
        this.isFullData = fullData;  
        setLastSent();
    }

    //Starts with getting all the Activated, Awaitign activation or Terminated Contracts in the org
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = '' + 
            'SELECT vlocity_ins__EnrollmentCensusId__c, ARC_AwaitingActivationDate__c ' + 
            'FROM Contract ' +
            // 'WHERE (Status = \'Activated\' OR Status = \'Awaiting Activation\' OR Status = \'Terminated\')';
            'WHERE '+ 
            (useThisCensuses.size() > 0 ? 'vlocity_ins__EnrollmentCensusId__c IN :useThisCensuses AND ' : '') +
            '('+
            (this.justTerminated ? '' : 'Status = \'Activated\' OR Status = \'Awaiting Activation\' OR ')
            +'Status = \'Terminated\' OR Status = \'Voided\')';
        
            if (0 < this.limitRecords) {
            query += ' LIMIT ' + this.limitRecords;
        }

        return Database.getQueryLocator(query);
    }


    global void execute(Database.BatchableContext bc, List<Contract> contracts) {

        Set<Id> censusIds = new Set<Id>();
        Set<Id> memberIds = new Set<Id>();
        Set<Id> censusIdsToSend = new Set<Id>();
        Set<Id> contractsToUseIds = new Set<Id>();
        for (Contract contract : contracts) {
            censusIds.add(contract.vlocity_ins__EnrollmentCensusId__c);
        }
        System.debug(censusIds);

        List<vlocity_ins__GroupCensusMember__c> members = getMembersByCensusIds(censusIds);
        List<Contract> contractsNonFiltered = getContractsByCensusIds(censusIds, this.justTerminated, this.contractsAlreadyInFile);
        Set<Id> contractsNonFilteredIds = new Set<Id>();
        System.debug(contractsNonFiltered);

        for (Contract contract : contractsNonFiltered) {
            contractsNonFilteredIds.add(contract.Id);
        }
        List<vlocity_ins__GroupCensusMemberPlan__c> groupCensusMemberPlans2 = getGroupCensusMemberPlans(contractsNonFilteredIds);
        // Map<Id, Set<Id>> contractMemberIds2 = getContractMemberIds(groupCensusMemberPlans2);
        Map<Id, Map<Id, Datetime>> contractMemberLastChange = getLastChangeDatetime(groupCensusMemberPlans2, contractsNonFilteredIds);
        

        List<Contract> contractsToUse = getContractsToUse(censusIds, contractsNonFiltered, contractMemberLastChange, this.lastSent);
        for (Contract contract : contractsToUse) {contractsToUseIds.add(contract.Id);}

        
        for (vlocity_ins__GroupCensusMember__c member : members) {memberIds.add(member.Id);}
        // Map<Id, Datetime> memberLastChange = getLastChangeDatetime(memberIds, this.contractsAlreadyInFile);
        
        
        System.debug(contractsToUseIds);
        Map<Id, Boolean> contractFutureCancellation = getContractFutureCancellation(censusIds, contractsNonFiltered);
        List<vlocity_ins__GroupCensusMemberPlan__c> groupCensusMemberPlans = getGroupCensusMemberPlans(contractsToUseIds);
        Map<Id, Set<Id>> contractMemberIds = getContractMemberIds(groupCensusMemberPlans);
        List<vlocity_ins__GroupCensusMember__c> fulfillmentMembers = getGroupCensusMembersAllData(groupCensusMemberPlans);
        Set<Id> memberIdsToUse = new Set<Id>();
        for (vlocity_ins__GroupCensusMember__c member : fulfillmentMembers){memberIdsToUse.add(member.Id);}
        Map<Id, Datetime> contractApprovedDate = getContractApprovedDate(contractsToUse);
        Map<Id, InsurancePolicy> contractPolicy = getContractPolicy(contractsToUseIds);
        Map<Id,Datetime> contractLastPayment = getContractLastPayment(contractsToUse);
        Map<Id, ChargentOrders__ChargentOrder__c> contractChargentOrder = getContractChargentOrder(contractsToUse);
        Map<Id, vlocity_ins__ContractLineItem__c> contractProduct = getContractProduct(contractsToUse);
        Map<Id,Map<String,Object>> memberOldValues = getMemberOldValues(memberIdsToUse, this.lastSent);
        // Map<Id, Map<Id, Datetime>> contractMemberLastChange = getLastChangeDatetime(groupCensusMemberPlans, contractsToUseIds);

        censusIdsToSend = getCensusIdsToSendV2(contractMemberLastChange, members, this.lastSent, this.isFullData);
        System.debug(contractMemberLastChange);
        System.debug(censusIdsToSend);
        for (Contract contract : contractsToUse) {
            if (censusIdsToSend.contains(contract.vlocity_ins__EnrollmentCensusId__c) && contractApprovedDate.get(contract.Id) != null) {
                this.contractsAlreadyInFile.add(contract.Id);
                this.stringTXT = ARC_ElegibilityFileSureCo.generate(
                    this.stringTXT, 
                    contract, 
                    contractProduct.get(contract.Id),
                    fulfillmentMembers, 
                    contractFutureCancellation.get(contract.Id) == null ? false : contractFutureCancellation.get(contract.Id), 
                    contractApprovedDate.get(contract.Id), 
                    contractLastPayment.get(contract.Id), 
                    contractChargentOrder.get(contract.Id), 
                    contractMemberLastChange.get(contract.Id),
                    contractPolicy.get(contract.Id),
                    contractMemberIds,
                    memberOldValues
                );   
            }
        }
        for (Contract contract : contractsToUse) {
            for (vlocity_ins__GroupCensusMember__c memb : fulfillmentMembers) {
                if (memb.vlocity_ins__CensusId__c == contract.vlocity_ins__EnrollmentCensusId__c) {
                    if (censusIdsToSend.contains(memb.vlocity_ins__CensusId__c) && contractApprovedDate.get(contract.Id) != null) {
                        this.memberCount++;
                    }
                }
            }
        }

        // if(Limits.getHeapSize() > Limits.getLimitHeapSize() * 0.4){
        if(this.memberCount > 3000){
            sendFile();
        }
    }

    global void finish(Database.BatchableContext bc) {
        this.last = true;
        sendFile();
        if (this.updateLastSent) {
            this.elegibileFile.ARC_LastSent_Datetime__c = this.oggi;
            update elegibileFile;
        }
    } 

    private void setLastSent(){
        if (this.sinceDate != null) {
            this.lastSent = this.sinceDate;
        }else {
            this.lastSent = this.elegibileFile.ARC_LastSent_Datetime__c;
        }
    }


    private static Map<Id, Map<Id, Datetime>> getLastChangeDatetime(List<vlocity_ins__GroupCensusMemberPlan__c> groupCensusMemberPlans, Set<Id> contractIds){
        Map<Id, Map<Id, Datetime>> contractMemberLastChage = new Map<Id, Map<Id, Datetime>>();
        for (Id contractId : contractIds) {
            Map<Id, Datetime> memberLastChange = new Map<Id, Datetime>();
            for (vlocity_ins__GroupCensusMemberPlan__c memberPlan : groupCensusMemberPlans) {
                if (memberPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c == contractId) {
                    if ((memberPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status == 'Terminated' || memberPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status == 'Voided') && memberPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c != null) {
                        // memberLastChange.put(memberPlan.vlocity_ins__GroupCensusMemberId__c,dateToDatetime(memberPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c));
                        memberLastChange.put(memberPlan.vlocity_ins__GroupCensusMemberId__c,memberPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.LastModifiedDate);
                        contractMemberLastChage.put(contractId, memberLastChange);
                    }else{
                        memberLastChange.put(memberPlan.vlocity_ins__GroupCensusMemberId__c, 
                            memberPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.LastModifiedDate > memberPlan.vlocity_ins__GroupCensusMemberId__r.LastModifiedDate ? 
                            memberPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.LastModifiedDate : 
                            memberPlan.vlocity_ins__GroupCensusMemberId__r.LastModifiedDate);
                        contractMemberLastChage.put(contractId, memberLastChange);
                    }
                }
            }
        }

        return contractMemberLastChage;
    }

    private static List<Contract> getContractsToUse(Set<Id> censusIds, List<Contract> contractsNonFiltered,Map<Id, Map<Id, Datetime>> contractMemberLastChange, Datetime lastSent){
        List<Contract> contractsToUse = new List<Contract>();
        Set<Id> contractsToUseIds = new Set<Id>();

        Contract contractCancellation;
        Contract contractToUse;
        Contract contractAwaitingActivation;
        for (Contract contract : contractsNonFiltered) {
            Boolean includeMember = false;
            if (contractMemberLastChange.get(contract.Id) != null) {
                for (Id memberId : (contractMemberLastChange.get(contract.Id)).keySet()) {
                    if ((contractMemberLastChange.get(contract.Id)).get(memberId) != null) {
                        if ((contractMemberLastChange.get(contract.Id)).get(memberId) > lastSent && contract.Status == 'Activated') {
                            includeMember = true;
                        }
                    }
                }
            }
            
            System.debug(contract.Id);
            if((includeMember || contract.LastModifiedDate > lastSent || contract.ARC_Inactive_Date__c > lastSent || contract.ARC_AwaitingActivationDate__c > lastSent || contract.ARC_EffectiveDate__c >= lastSent) && contractAwaitingActivationConditon(contract)){

                if(!contractsToUseIds.contains(contract.Id)){
                    contractsToUseIds.add(contract.Id);
                    contractsToUse.add(contract);
                }
            } else {
                if (contract.Status == 'Activated') {
                    contractToUse = contract;
                }else if (contract.Status == 'Awaiting Activation') {
                    contractAwaitingActivation = contract;
                }
            }
        }

        if (contractToUse == null) {
            if (contractCancellation != null) {
                contractToUse = contractCancellation;
            }
            if (contractAwaitingActivation != null && contractAwaitingActivationConditon(contractAwaitingActivation)) {
                contractToUse = contractAwaitingActivation;
            }
        }
        if (contractToUse != null) { 
            contractsToUse.add(contractToUse);                
            if (contractCancellation != null) {  
                if (contractCancellation.Id != contractToUse.Id) {
                    if(!contractsToUseIds.contains(contractCancellation.Id)){
                        contractsToUse.add(contractCancellation);
                        contractsToUseIds.add(contractCancellation.Id);

                    }                    
                }
            }             
        }
        return contractsToUse;
    }

    private static Boolean contractAwaitingActivationConditon(Contract contract){
        Boolean valid = true;
        if(contract.Status == 'Awaiting Activation' && !(contract.ARC_ContractReason__c.contains('New Application'))){
            valid = false;
        }
        return valid;
    }

    private static Map<Id, Boolean> getContractFutureCancellation(Set<Id> censusIds, List<Contract> contractsNonFiltered){
        Map<Id, Boolean> contractFutureCancellation = new Map<Id, Boolean>();
        for (Contract contract : contractsNonFiltered) {
            if (contract.vlocity_ins__EnrollmentEndDate__c != null) {
                contractFutureCancellation.put(contract.Id, true);
            }else {
                contractFutureCancellation.put(contract.Id, false);
            }

        }
        return contractFutureCancellation;
    }

    private static Map<Id, Set<Id>> getContractMemberIds(List<vlocity_ins__GroupCensusMemberPlan__c> groupCensusMemberPlans){
        Map<Id, Set<Id>> contractMemberIds = new Map<Id, Set<Id>>();

        for(vlocity_ins__GroupCensusMemberPlan__c gcmp : groupCensusMemberPlans){
            Set<Id> memberIds = contractMemberIds.get(gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c) != null ? contractMemberIds.get(gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c) : new Set<Id>();
            memberIds.add(gcmp.vlocity_ins__GroupCensusMemberId__c);
            contractMemberIds.put(gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c, memberIds);
            
        }

        return contractMemberIds;
    }

    private static Map<Id, Datetime> getContractApprovedDate(List<Contract> contracts){
        Set<Id> contractIds = new Set<Id>();
        Map<Id, Datetime> contractApprovedDate = new Map<Id, Datetime>(); 
        
        for (Contract contract : contracts) {
            contractIds.add(contract.Id);
        }

        List<ContractHistory> contractsHistory = [
            SELECT 
            ContractId, 
            CreatedDate, 
            NewValue 
            FROM ContractHistory 
            WHERE ContractId IN :contractIds 
            ORDER BY CREATEDDATE
        ]; 

        for (Contract contract : contracts) { 
            for(String status : new List<String>{'Awaiting Activation', 'Activated'}){
                if (contractApprovedDate.get(contract.Id) == null) {
                    for (ContractHistory contractHistory : contractsHistory) {
                        if (contractHistory.contractId == contract.Id && contractHistory.NewValue == status) {
                            contractApprovedDate.put(contract.Id, contractHistory.CreatedDate);
                        }
                    }
                }
            }
            
        }

        for (Contract contract : contracts) { 
            if (!contractApprovedDate.containsKey(contract.Id)) {
                contractApprovedDate.put(contract.Id, contract.ARC_AwaitingActivationDate__c);
            }
        }

        return contractApprovedDate;
    }

    private static Set<Id> getCensusIdsToSendV2(Map<Id, Map<Id, Datetime>> contractMemberLastChange, List<vlocity_ins__GroupCensusMember__c> members, Datetime lastSent, Boolean isFullData){
        Set<Id> censusIdsToSend = new Set<Id>();
        Set<Id> memberIds = new Set<Id>();
        // Map<Id, Datetime> memberLastChange = new Map<Id, Datetime>();
        for (Map<Id, Datetime> memberLastChange : contractMemberLastChange.values()) {
            for (Id memberId : memberLastChange.keySet()) {
                System.debug(memberId);
                System.debug(memberLastChange.get(memberId));
                if (memberLastChange.get(memberId) > lastSent || isFullData) {
                    memberIds.add(memberId);
                }
            }
        }
        System.debug(memberIds);
        for (vlocity_ins__GroupCensusMember__c member : members) {
            if (memberIds.contains(member.Id)) {
                censusIdsToSend.add(member.vlocity_ins__CensusId__c);
            }
        }
        return censusIdsToSend;
    }

    private static List<Contract> getContractsByCensusIds(Set<Id> censusIds, Boolean justTerminated, Set<Id> contractsAlreadyInFile){
        String contractFields = 
            'Id,'+
            'ARC_TotalPrice__c,'+
            'vlocity_ins__EnrollmentEndDate__c,'+
            'vlocity_ins__EnrollmentCensusId__c,'+
            'ARC_EffectiveDate__c,'+
            'Status,'+
            'ARC_ContractReason__c,'+
            'ARC_SingleReasonForPC__c,'+
            'ARC_Case__c,'+
            'ARC_CancellationReason__c,'+
            'ARC_OtherCancellationReason__c,'+
            'CreatedDate,'+
            'ContractNumber,'+
            'ARC_RecurringMonthlyOrder__c,'+
            'ARC_AwaitingActivationDate__c,'+
            'ARC_Inactive_Date__c,'+
            'LastModifiedDate,'+
            'E123_CORE_POLICY_NUMBER__C';
        if (justTerminated) {
            return Database.query('SELECT '+contractFields+' FROM Contract WHERE (Status = \'Terminated\' OR Status = \'Voided\')    AND vlocity_ins__EnrollmentCensusId__c IN :censusIds AND Id NOT IN :contractsAlreadyInFile  ORDER BY CreatedDate DESC');
        }else {
            return Database.query('SELECT '+contractFields+' FROM Contract  WHERE (Status = \'Activated\' OR Status = \'Awaiting Activation\' OR Status = \'Terminated\' OR Status = \'Voided\')     AND vlocity_ins__EnrollmentCensusId__c IN :censusIds AND Id NOT IN :contractsAlreadyInFile ORDER BY CreatedDate DESC');
        }
    }

    private static Map<Id,Map<String,Object>> getMemberOldValues(Set<Id> memberIds, Datetime lastSent){
        Map<Id,Map<String,Object>> memberOldValues = new Map<Id,Map<String,Object>>();
        List<vlocity_ins__GroupCensusMember__History> memberHistory = [ SELECT Id, ParentId, Field, OldValue, NewValue, CreatedDate 
            FROM vlocity_ins__GroupCensusMember__History 
            WHERE ParentId IN :memberIds AND
            Field IN :getMemberFieldsToTrack() AND
            CreatedDate > :lastSent
            ORDER BY CreatedDate ASC
        ];

        for (Id memberId : memberIds) {
            for (vlocity_ins__GroupCensusMember__History memberHistoryItem : memberHistory) {
                if (memberHistoryItem.ParentId == memberId) {
                    Map<String,Object> oldValues = memberOldValues.get(memberId) != null ? memberOldValues.get(memberId) : new Map<String,Object>();
                    if(oldValues.get(memberHistoryItem.Field) == null){
                        oldValues.put(memberHistoryItem.Field, memberHistoryItem.OldValue);
                    }
                    if(oldValues.keySet().size() > 0){
                        memberOldValues.put(memberId, oldValues);
                    }
                }
            }

        }

        return memberOldValues;
    }

    private static Set<String> getMemberFieldsToTrack(){
        return new Set<String>{
            'vlocity_ins__FirstName__c',
            'vlocity_ins__LastName__c',
            'vlocity_ins__SocialSecurityNumber__c',
            'vlocity_ins__Birthdate__c'
        };
    }

    private static Map<Id, InsurancePolicy> getContractPolicy(Set<Id> contractIds){
        Map<Id, InsurancePolicy> contractPolicy = new Map<Id, InsurancePolicy>();
        for ( InsurancePolicy p : [SELECT Id, Name, ARC_Contract__c FROM InsurancePolicy WHERE ARC_Contract__c IN :contractIds]) { 
            contractPolicy.put(p.ARC_Contract__c, p);
        }
        return contractPolicy;
    }
    
    private static Map<Id, Datetime>  getContractLastPayment(List<Contract> contracts){
        Map<Id, Datetime> contractLastPayment = new Map<Id, Datetime>();
        Set<Id> chargentOrderIds = new Set<Id>();
        for (Contract contract : contracts) {
            chargentOrderIds.add(contract.ARC_RecurringMonthlyOrder__c);
        }
        List<ChargentOrders__Transaction__c> transactions = [
            SELECT 
            ChargentOrders__Order__c,
            ChargentOrders__Amount__c,
            ChargentOrders__Gateway_Date__c 
            FROM ChargentOrders__Transaction__c 
            WHERE ChargentOrders__Type__c = 'Charge' AND 
            ChargentOrders__Order__c IN :chargentOrderIds 
            ORDER BY ChargentOrders__Gateway_Date__c DESC
        ];
        for (ChargentOrders__Transaction__c trans : transactions) {
            for (Contract contract : contracts) {
                if (contract.ARC_TotalPrice__c == trans.ChargentOrders__Amount__c && contractLastPayment.get(contract.Id)== null) {
                    contractLastPayment.put(contract.Id, trans.ChargentOrders__Gateway_Date__c);
                }
            }    
        }
        return contractLastPayment;
    }

    private static Map<Id, ChargentOrders__ChargentOrder__c>  getContractChargentOrder(List<Contract> contracts){
        Map<Id, ChargentOrders__ChargentOrder__c> contractChargentOrder = new Map<Id, ChargentOrders__ChargentOrder__c>();
        Set<Id> chargentOrderIds = new Set<Id>();
        for (Contract contract : contracts) {
            chargentOrderIds.add(contract.ARC_RecurringMonthlyOrder__c);
        }
        List<ChargentOrders__ChargentOrder__c> chargentOrders = [
            SELECT 
            Id,
            ChargentOrders__Next_Transaction_Date__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id IN :chargentOrderIds
        ]; 

        for (ChargentOrders__ChargentOrder__c order : chargentOrders) {
            for (Contract contract : contracts) {
                if (contract.ARC_RecurringMonthlyOrder__c == order.Id) {
                    contractChargentOrder.put(contract.Id, order);
                }
            }
        }
        return contractChargentOrder;
    }
    
    private static Map<Id, vlocity_ins__ContractLineItem__c>  getContractProduct(List<Contract> contracts) {
        Set<Id> contractIds = new Set<Id>();
        Map<Id, vlocity_ins__ContractLineItem__c>  contractProduct = new Map<Id, vlocity_ins__ContractLineItem__c>();
        RecordType productRecordType = [SELECT Id,DeveloperName FROM RecordType WHERE DeveloperName ='Product' LIMIT 1];
        for(Contract contract: contracts) {
            contractIds.add(contract.Id);
        }
        List<vlocity_ins__ContractLineItem__c> products = [SELECT vlocity_ins__Product2Id__c,vlocity_ins__ProductType__c,vlocity_ins__ProductCode__c, vlocity_ins__ContractId__c FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__Product2Id__r.RecordTypeId = :productRecordType.Id AND vlocity_ins__ProductType__c = 'Medical' AND vlocity_ins__ContractId__c IN :contractIds];
        
        for (vlocity_ins__ContractLineItem__c product : products) {
            for (Contract contract : contracts) {
                if (product.vlocity_ins__ContractId__c == contract.Id) {
                    contractProduct.put(contract.Id, product);
                }
            }
        }
        return contractProduct;
    }

    private static List<vlocity_ins__GroupCensusMember__c> getMembersByCensusIds(Set<Id> censusIds){
        return [
            SELECT 
            Id, vlocity_ins__CensusId__c, LastModifiedDate
            FROM vlocity_ins__GroupCensusMember__c 
            WHERE vlocity_ins__CensusId__c IN :censusIds
        ];
    }

    private static List<vlocity_ins__GroupCensusMember__c> getGroupCensusMembersAllData(List<vlocity_ins__GroupCensusMemberPlan__c> groupCensusMemberPlans){
        Set<Id> memberIds = new Set<Id>();


        for (vlocity_ins__GroupCensusMemberPlan__c memberPlan : groupCensusMemberPlans) {
            memberIds.add(memberPlan.vlocity_ins__GroupCensusMemberId__c);
        }
        
        return [
            SELECT 
            Id,
            ARC_ActiveMember__c,
            e123_member_id__c, 
            Member_ID__c,
            CreatedDate,
            LastModifiedDate,
            vlocity_ins__MemberType__c,
            Name,
            ARC_PhysicalAddressState__c,
            vlocity_ins__FirstName__c,
            vlocity_ins__LastName__c,
            ARC_PhysicalAddressCity__c,
            ARC_PhysicalAddressStreet__c,
            ARC_MiddleInitial__c,
            ARC_PhysicalAddressZipCode__c,
            vlocity_ins__CensusId__c,
            ARC_Phone__c,
            vlocity_ins__Email__c,
            vlocity_ins__Birthdate__c,
            vlocity_ins__Gender__c,
            vlocity_ins__SocialSecurityNumber__c,
            vlocity_ins__IsPrimaryMember__c,
            vlocity_ins__IsSpouse__c,
            vlocity_ins__RelatedCensusMemberId__r.Member_ID__c,
            vlocity_ins__RelatedCensusMemberId__r.e123_member_id__c,
            ARC_Relationship__c,
            ARC_Height__c,
            ARC_Weight__c 
            FROM vlocity_ins__GroupCensusMember__c 
            WHERE Id IN :memberIds
        ];
    }

    private static List<vlocity_ins__GroupCensusMemberPlan__c> getGroupCensusMemberPlans( Set<Id> contractIds){
        return [
            SELECT Id, 
            vlocity_ins__GroupCensusMemberId__c,
            vlocity_ins__GroupCensusMemberId__r.LastModifiedDate,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.LastModifiedDate,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.vlocity_ins__EnrollmentEndDate__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c
            FROM vlocity_ins__GroupCensusMemberPlan__c 
            WHERE 
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c IN :contractIds AND
            vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c  = 'Medical' AND
            (
                (vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status IN ('Terminated','Voided') AND vlocity_ins__GroupCensusMemberId__r.ARC_ActiveMember__c = false) 
                OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status NOT IN ('Terminated','Voided')
            )
        ];
    }





    private void sendEmailNotification(String body, String subject) {
        // if (!([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox)){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            List<String> toAddresses = new List<String>();
            for (String emailString : this.elegibileFile.ARC_EmailsToNotify__c.replace(' ','').split(';')) {
                if (validateEmail(emailString)) {
                    toAddresses.add(emailString);
                }
            }
            if (toAddresses.size() > 0) {
                email.setToAddresses(toAddresses);
                email.setSubject(subject);
                email.setPlainTextBody(body);
                
                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            }
        // }
    }
    
    private void sendFile(){
        if(this.sendToEmails.size() > 0) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            Messaging.EmailFileAttachment sureCoFile = new Messaging.EmailFileAttachment();
            sureCoFile.setFileName(this.filename);
            sureCoFile.setBody(Blob.valueOf(this.stringTXT));
            email.setToAddresses( this.sendToEmails );
            email.setPlainTextBody('TEST');
            email.setFileAttachments(new Messaging.EmailFileAttachment[] {sureCoFile});
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }

        if (this.sendToTestSite) {
            sendFileToServer('TEST/'+this.filename,'UHSM', false);
        }else if (!([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox)) {
            sendFileToServer(this.filename,'SureCo', true);
        }

        this.stringTXT='';
        this.memberCount = 0;
    }

    private void sendFileToServer(String finalFilename, String finalPath, Boolean isProd) {
        try {
            if (this.last) {
                if(!Test.isRunningTest()){
                    FTP2SF.FTP.append('UHSM', 'sureco/' + finalFilename, Blob.valueOf(this.stringTXT));
                    if(isProd){
                        FTP2SF.FTP.Response result = FTP2SF.FTP.trn('UHSM', 'sureco/' + finalFilename, finalPath, 'salesforce/inbound/' +this.filename);
                        if(result.success == true){
                            this.sendEmailNotification('UHSM Member File - File transfer successfully ( '+finalFilename+' )\n\n' + result, 'UHSM Member File - File transfer successfully - '+finalFilename);
                        }else{
                            this.sendEmailNotification('UHSM Member File - File transfer Error ( '+finalFilename+' )\n\n ' + result, 'UHSM Member File - File transfer Error - '+finalFilename);
                        }
                        
                    }
                }
            }else{
                if (this.first )  {
                    if(!Test.isRunningTest()){
                        FTP2SF.FTP.put('UHSM','sureco/'+finalFilename,Blob.valueOf(this.stringTXT));
                    }
                    this.first = false;
                }else{
                    if(!Test.isRunningTest()){
                        FTP2SF.FTP.append('UHSM','sureco/'+finalFilename,Blob.valueOf(this.stringTXT));
                    }
                }
            }
        } catch (Exception e) {

            this.sendEmailNotification('The file was not sent successfully ( '+finalFilename+' )  \n\n '+e, 'Daily UHSM Sales Eligibility upload');
        }
    }

    private static Boolean validateEmail(String email) {
        Boolean res = true;
            
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
        Pattern MyPattern = Pattern.compile(emailRegex);
        Matcher MyMatcher = MyPattern.matcher(email);

        if (!MyMatcher.matches()) 
            res = false;
        return res;	
	}


    private static Datetime dateToDatetime(Date d){
        Integer dd = d.day();
        Integer mm = d.month();
        Integer yyyy = d.year();

        return DateTime.newInstance(yyyy, mm, dd);
    }


    @InvocableMethod(label='Run SureCo File Batch' description='Runs the SureCo File Batch' category='Elegibility Files')
    global static void runSureCoBatch(){
        ARC_SureCoElegibilityFileBatch sureCoBatch = new ARC_SureCoElegibilityFileBatch();
        // sureCoBatch.sendToEmails = new List<String>();
        // sureCoBatch.sendToEmails.add('email@email.com');
        // sureCoBatch.sinceDate = DateTime.newInstance(2022, 11, 17);
        // sureCoBatch.updateLastSent = false;  
        // sureCoBatch.useThisCensuses = new Set<Id>();
		// sureCoBatch.useThisCensuses.add('a3r3C000000t6xmQAA');
		// sureCoBatch.useThisCensuses.add('a3r3C000000t6xcQAA');
		// sureCoBatch.useThisCensuses.add('a3r3C000000t6xwQAA');
        // sureCoBatch.justTerminated = false;
        // sureCoBatch.isFullData = false;
        // sureCoBatch.sendToTestSite = true;
        Database.executeBatch(sureCoBatch, 10);
    }
    

}