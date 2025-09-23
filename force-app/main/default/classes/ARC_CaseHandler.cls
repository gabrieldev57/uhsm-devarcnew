/*******************************************************************
* @ClassName          :   ARC_CaseHandler
* @Description        :   Methods related to case handling.
* @MethodName         :   getMemberAndProgramData
********************************************************************/

public without sharing class ARC_CaseHandler {
    private static Id integrationUserId;
    
    /*******************************************************************
    * @MethodName         :   getMemberAndProgramData
    * @Description        :   Retrieves the required data to display in custom LWC shown on UW Case Record Page that display Member Information 
    ********************************************************************/

    @AuraEnabled(cacheable=true)
    public static Object getMemberAndProgramData(Id caseId) {
        Map<String, Object> responseData = new Map<String, Object>();
        
        String activePlan = null;
        Account accountData;
        Date firstEffectiveDate = null;
        List<Id> contracts = new List<Id>();

        Case caseData = [SELECT ARC_PersonAccount__c, RecordType.Name, ARC_Contract__c, ARC_Contract__r.ContractNumber, ARC_Contract__r.ARC_EffectiveDate__c FROM Case WHERE Id = :caseId];
        if(caseData.ARC_Contract__c!=null && caseData.RecordType.Name=='Underwriting'){
            vlocity_ins__ContractLineItem__c contractLineItem = [SELECT Id, vlocity_ins__Product2Id__r.Name FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__ProductType__c = 'Medical' AND vlocity_ins__ParentItemId__c=null AND vlocity_ins__ContractId__c =: caseData.ARC_Contract__c LIMIT 1];
            activePlan = contractLineItem?.vlocity_ins__Product2Id__r?.Name;
        }
        if(caseData.ARC_PersonAccount__c!=null){
            accountData = [SELECT Id, Name, PersonBirthdate, Phone, PersonEmail, BillingState, BillingPostalCode FROM Account WHERE Id =: caseData.ARC_PersonAccount__c];
        } else{
            return responseData;
        }
        
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpRelatedToPA = [SELECT Id, vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__r.Name, vlocity_ins__ContractLineId__c, vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status,
        vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.StatusCode, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId, Contract_Effective_Date__c, Contract_Inactive_Date__c
            FROM vlocity_ins__GroupCensusMemberPlan__c 
            WHERE vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId =: accountData.Id AND vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical' AND (
                vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Activated' OR 
                vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Terminated' OR 
                vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Awaiting Activation' OR 
                vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Awaiting Signature' OR 
                vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Awaiting Approval' OR 
                vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Awaiting First Payment')
                 ORDER BY Contract_Effective_Date__c ASC
        ];

        //Date previousEffectiveDate = null;
        Date lastTerminatedDate = null;
        Date latestActiveDate = null;
        vlocity_ins__GroupCensusMemberPlan__c activeContract = null;
        vlocity_ins__GroupCensusMemberPlan__c inApprovalContract = null;
        
        if(caseData.RecordType.Name != 'Underwriting'){
            // Loop through Group Census Member Plans to determine firstEffectiveDate and activePlan
            for (vlocity_ins__GroupCensusMemberPlan__c gcmp : gcmpRelatedToPA) {
                Id contractId = gcmp?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__c;
                
                if (!contracts.contains(contractId)) {
                    contracts.add(contractId);
                    
                    if (firstEffectiveDate == null) {
                        firstEffectiveDate = gcmp.Contract_Effective_Date__c;
                    } else {
                        if (lastTerminatedDate != null && gcmp.Contract_Effective_Date__c > lastTerminatedDate.addDays(1) && gcmp.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.StatusCode != 'InApproval') {
                            firstEffectiveDate = gcmp.Contract_Effective_Date__c;
                        }
                    }

                    if (gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status == 'Activated') {
                        if (latestActiveDate == null || gcmp.Contract_Effective_Date__c > latestActiveDate) {
                            latestActiveDate = gcmp.Contract_Effective_Date__c;
                            activeContract = gcmp;
                        }
                    // Update the inApproval contract if there is no active contract
                    } else if (gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.StatusCode == 'InApproval'){
                        inApprovalContract = gcmp;
                    }
                    // Update the last termination date only for terminated contracts
                    if (gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status == 'Terminated') {
                        lastTerminatedDate = gcmp.Contract_Inactive_Date__c;
                    }
                }
            }
        }

        // Update active plan if there is no active contract but there is an in-approval contract
        if (activeContract != null) {
            activePlan = activeContract?.vlocity_ins__ContractLineId__r?.vlocity_ins__Product2Id__r?.Name;
            if (firstEffectiveDate == null) {
                firstEffectiveDate = activeContract.Contract_Effective_Date__c;
            }
        } else if (inApprovalContract != null) {
            activePlan = inApprovalContract?.vlocity_ins__ContractLineId__r?.vlocity_ins__Product2Id__r?.Name;
            if (firstEffectiveDate == null) {
                firstEffectiveDate = inApprovalContract.Contract_Effective_Date__c;
            }
        }

        // Prepare the response object
        responseData.put('caseData', caseData);
        responseData.put('accountData', accountData);
        responseData.put('contractlist', contracts);
        responseData.put('currentProgram', activePlan);
        if(caseData.RecordType.Name!='Underwriting'){
            responseData.put('effectiveDate', firstEffectiveDate);
        } else{
            responseData.put('effectiveDate', caseData.ARC_Contract__r.ARC_EffectiveDate__c);
        }

        return responseData;
    }

    /*******************************************************************
    * @MethodName         :   updateCasePersonAccount
    * @Description        :   Change the Member (Person Account) linked to the Case.
    ********************************************************************/
    @AuraEnabled
    public static void updateCasePersonAccount(Id caseId, Id personAccountId) {

        Case caseToUpdate = new Case(Id = caseId, ARC_PersonAccount__c = personAccountId);
        update caseToUpdate;
    }


    /*******************************************************************
    * @MethodName         :   getContractComparison
    * @Description        :   Fetch the contract comparison component in UW Case Record Page.
    ********************************************************************/

    @AuraEnabled(cacheable=true)
    public static Object getContractComparison(Id caseId) {
        if(caseId == null) return null;
        Map<String, Object> responseData = new Map<String, Object>();

        Contract newContract ;
        List<vlocity_ins__ContractLineItem__c> oldLineItems;
        List<vlocity_ins__GroupCensusMemberPlan__c> oldMemberPlans;
        List<vlocity_ins__GroupCensusMemberPlan__c> newMemberPlans;
        List<vlocity_ins__ContractLineItem__c> newContractLineItems;
        // Get the new Case and Contract Members
        Case newCase = [SELECT Id, ARC_Contract__c, ARC_ContractEffectiveDate__c FROM Case WHERE Id = :caseId];
        System.debug('newCase');
        System.debug(newCase);

        if(newCase.ARC_Contract__c!=null){
            newContract = [SELECT Id, ContractNumber, ARC_EffectiveDate__c, ARC_ContractReason__c, vlocity_ins__ExpiredContractId__c, vlocity_ins__ExpiredContractId__r.ContractNumber, vlocity_ins__ExpiredContractId__r.ARC_EffectiveDate__c,ARC_PaidThroughDate__c,vlocity_ins__ExpiredContractId__r.ARC_PaidThroughDate__c,  (SELECT Id,Name, vlocity_ins__ProductType__c, vlocity_ins__ProductSubType__c, vlocity_ins__UnitPrice__c FROM vlocity_ins__ContractLineItems__r WHERE vlocity_ins__RecordTypeName__c='Product' AND (vlocity_ins__ProductType__c='Ancillary' OR vlocity_ins__ProductType__c='Medical') ORDER BY vlocity_ins__ProductType__c DESC, vlocity_ins__UnitPrice__c DESC) FROM Contract WHERE Id =: newCase.ARC_Contract__c];
            newContractLineItems = newContract.vlocity_ins__ContractLineItems__r;
            newMemberPlans = [SELECT Id, vlocity_ins__GroupCensusMemberId__c, vlocity_ins__GroupCensusMemberId__r.Name, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__ContractLineId__c IN: newContractLineItems];            
            if(newContract.vlocity_ins__ExpiredContractId__c != null){
                oldLineItems = [SELECT Id, Name, vlocity_ins__ProductType__c, vlocity_ins__ProductSubType__c, vlocity_ins__UnitPrice__c FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__ContractId__c =: newContract.vlocity_ins__ExpiredContractId__c  AND vlocity_ins__RecordTypeName__c='Product' AND (vlocity_ins__ProductType__c='Ancillary' OR vlocity_ins__ProductType__c='Medical')  ORDER BY vlocity_ins__ProductType__c DESC, vlocity_ins__UnitPrice__c DESC];
                oldMemberPlans = [SELECT Id, vlocity_ins__GroupCensusMemberId__c, vlocity_ins__GroupCensusMemberId__r.Name, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__ContractLineId__c IN: oldLineItems];
                Integer lengthDiff = Math.abs(oldLineItems.size() - newContractLineItems.size());
                if(lengthDiff>0){
                    List<vlocity_ins__ContractLineItem__c> emptyClisToAdd = new List<vlocity_ins__ContractLineItem__c>();
                    for (Integer i = 0; i < lengthDiff; i++) {
                        emptyClisToAdd.add(new vlocity_ins__ContractLineItem__c(
                            Name = '',
                            vlocity_ins__UnitPrice__c = null
                        ));
                    }

                    if(newContractLineItems.size() < oldLineItems.size()){
                        newContractLineItems.addAll(emptyClisToAdd);
                    }else{
                        oldLineItems.addAll(emptyClisToAdd);
                    }
                }
            }    
        }
        responseData.put('caseDataAndMembers', newCase);
        responseData.put('newContract', newContract);
        responseData.put('oldContractLineItems', oldLineItems);
        responseData.put('newContractLineItems', newContractLineItems);
        responseData.put('newMemberPlans', newMemberPlans);
        responseData.put('oldMemberPlans', oldMemberPlans);
        return responseData;
    }

    /*******************************************************************
    * @MethodName         :   encryptCaseIds
    * @Description        :   Encrypt Id and dynamically create the community URL.
    ********************************************************************/

    public static void encryptCaseIds(List<Case> newCases) {
        List<Case> casesToUpdate = new List<Case>();
    
        // Get the base URL dynamically
        String communityBaseUrl = URL.getOrgDomainUrl().toExternalForm();
        communityBaseUrl = communityBaseUrl.replace('salesforce', 'site');
        // Define the community path - this should be stored in Custom Metadata or Custom Settings
        String communityPath = '/members/s/upload?caseId='; 
        
        for (Case c : newCases) {
            Case updatedCase = new Case(Id = c.Id);
            if (c.Id != null) {
                updatedCase.ARC_Upload_files_URL__c = EncodingUtil.base64Encode(Blob.valueOf(c.Id));
                System.debug('baseUrl ' + communityBaseUrl + ' communityPath ' + communityPath + ' c.ARC_Encrypted_Files_URL__c ' + updatedCase.ARC_Upload_files_URL__c);
                updatedCase.ARC_Upload_files_URL__c = '<a href="' + communityBaseUrl + communityPath + updatedCase.ARC_Upload_files_URL__c + '" target="_blank">Upload files here.</a>';
                casesToUpdate.add(updatedCase);
            }
        }
    
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }

    /*******************************************************************
    * @MethodName         :   Prevent update Description
    * @Description        :   This method is used to not overrwite the description field by email-to case funcionality
    ********************************************************************/
    public static void preventUpdateDescription(Map<Id,Case> oldCases, Map<Id,Case> newCases) {
        //Check if the current user is the automation user (Integration User)
        if(integrationUserId == null){
            List<User> integrationUser = [SELECT Id, Name FROM User WHERE (Name = 'Integration User') AND IsActive = true LIMIT 1];
            integrationUserId = integrationUser.size()>0 ? integrationUser[0].Id:null;
        }
        Id currentUserId = UserInfo.getUserId();
        if(integrationUserId != null){
            for(Case c : newCases.values()) {
                if(currentUserId == integrationUserId && oldCases.get(c.Id).Description != null){
                    c.Description = oldCases.get(c.Id).Description;
                }
            }
        }
    }
}