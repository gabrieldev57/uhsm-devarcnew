/*******************************************************************
* @ClassName          :   ARC_CaseHandler
* @Description        :   Methods related to case handling.
* @MethodName         :   getMemberAndProgramData
********************************************************************/

public without sharing class ARC_CaseHandler {
    private static Id integrationUserId;
    
    /********************************************************************
     @MethodName         :   getMemberAndProgramData
    * @Description        :   Retrieves the required data to display in custom LWC shown on UW Case Record Page that display Member Information
    ********************************************************************/

    @AuraEnabled(cacheable=true)
    public static Object getMemberAndProgramData(Id caseId) {
        Map<String, Object> responseData = new Map<String, Object>();
        
        String activePlan = null;
        Account accountData;
        Date firstEffectiveDate = null;

        Case caseData = [
            SELECT ARC_PersonAccount__c,
                RecordType.Name,
                ARC_Contract__c,
                ARC_Contract__r.ContractNumber,
                ARC_Contract__r.ARC_EffectiveDate__c,
                ARC_Contract__r.RecordType.DeveloperName,
                ARC_Contract__r.ARC_MedicalPlan__r.Name
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        if (caseData.ARC_PersonAccount__c != null) {
            accountData = [
                SELECT Id,
                    Name,
                    PersonBirthdate,
                    Phone,
                    PersonEmail,
                    BillingState,
                    BillingPostalCode,
                    ARC_ContinuousCoverageStartDate__c
                FROM Account
                WHERE Id = :caseData.ARC_PersonAccount__c
                LIMIT 1
            ];
        } else {
            return responseData;
        }

        firstEffectiveDate = accountData.ARC_ContinuousCoverageStartDate__c;

        Boolean isIFUnderwritingCase = caseData.RecordType.Name == 'Underwriting' && caseData.ARC_Contract__c != null;
        //For Individual & Family Underwriting Cases, take the active plan from the related contract's medical plan
        if (isIFUnderwritingCase) {
            activePlan = caseData.ARC_Contract__r?.ARC_MedicalPlan__r?.Name;
        }
        else {
            Set<String> policyStatuses = new Set<String>{
                'Activated',
                'Awaiting Activation',
                'Awaiting Signature',
                'Awaiting Approval',
                'Awaiting First Payment',
                'Terminated'
            };

            List<ARC_CoverageParticipant__c> coverageParticipants = [
                SELECT Id,
                        ARC_Policy__r.ARC_EffectiveDate__c,
                        ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.Name,
                        ARC_Policy__r.ARC_PolicyStatus__c
                FROM ARC_CoverageParticipant__c
                WHERE ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId = :accountData.Id AND 
                      ARC_Policy__r.ARC_PolicyStatus__c IN :policyStatuses AND
                      ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.RecordType.DeveloperName = 'Product'
                ORDER BY ARC_Policy__r.ARC_EffectiveDate__c ASC
            ];

            for(ARC_CoverageParticipant__c cp:coverageParticipants){
                if(firstEffectiveDate == null){
                    firstEffectiveDate = cp.ARC_Policy__r.ARC_EffectiveDate__c;
                }
                //For Individual & Family Contracts, take the name from the contract's medical plan.
                if(activePlan ==  null && caseData.ARC_Contract__c != null && caseData.ARC_Contract__r.RecordType.DeveloperName == 'ARC_IndividualAndFamily'){
                    activePlan = caseData.ARC_Contract__r?.ARC_MedicalPlan__r?.Name;
                    break;
                }
                else if(cp.ARC_Policy__r.ARC_PolicyStatus__c == 'Activated'){
                    activePlan = cp.ARC_PolicyCoverage__r?.vlocity_ins_fsc__Product2Id__r?.Name;
                    break;
                }
                else{
                    if(activePlan == null){
                        activePlan = cp.ARC_PolicyCoverage__r?.vlocity_ins_fsc__Product2Id__r?.Name;
                    }
                }
            }           
        }

        responseData.put('accountData', accountData);
        responseData.put('caseData', caseData);
        responseData.put('currentProgram', activePlan);
        System.debug('activePlan: ' + activePlan);
        responseData.put('effectiveDate', firstEffectiveDate);

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
            newContract = [SELECT Id, ContractNumber, ARC_EffectiveDate__c, ARC_ContractReason__c, vlocity_ins__ExpiredContractId__c, vlocity_ins__ExpiredContractId__r.ContractNumber, vlocity_ins__ExpiredContractId__r.ARC_EffectiveDate__c, (SELECT Id,Name, vlocity_ins__ProductType__c, vlocity_ins__ProductSubType__c, vlocity_ins__UnitPrice__c FROM vlocity_ins__ContractLineItems__r WHERE vlocity_ins__RecordTypeName__c='Product' AND (vlocity_ins__ProductType__c='Ancillary' OR vlocity_ins__ProductType__c='Medical') ORDER BY vlocity_ins__ProductType__c DESC, vlocity_ins__UnitPrice__c DESC) FROM Contract WHERE Id =: newCase.ARC_Contract__c];
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
        String communityEmployerPath = '/employerportal/s/upload?caseId='; //new community path for employers

         Id rtSmallGroup = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroupUnderwriting')?.getRecordTypeId();

        for (Case c : newCases) {
            Case updatedCase = new Case(Id = c.Id);
           
            if(c.Id != null && c.RecordTypeId == rtSmallGroup){
                updatedCase.ARC_Upload_files_URL__c = EncodingUtil.base64Encode(Blob.valueOf(c.Id));
                System.debug('baseUrl ' + communityBaseUrl + ' communityEmployerPath ' + communityEmployerPath + ' c.ARC_Encrypted_Files_URL__c ' + updatedCase.ARC_Upload_files_URL__c);
                updatedCase.ARC_Upload_files_URL__c = '<a href="' + communityBaseUrl + communityEmployerPath + updatedCase.ARC_Upload_files_URL__c + '" target="_blank">Upload files here.</a>';
                casesToUpdate.add(updatedCase);
            }
            if (c.Id != null && c.RecordTypeId != rtSmallGroup) {
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

    //-------------- UHSM-3204
    public class PolicyCoverageDTO {
        @AuraEnabled public Id coverageId;
        @AuraEnabled public String coverageName;
        @AuraEnabled public Id policyId;
        @AuraEnabled public String policyName;
    }

    @AuraEnabled(cacheable=true)
    public static List<PolicyCoverageDTO> getPolicyCoverages(Id caseId) {
        if (caseId == null) return new List<PolicyCoverageDTO>();
        Case c = [
            SELECT Id, ARC_PersonAccount__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        Id personAccountId = c.ARC_PersonAccount__c;
        if (personAccountId == null) return new List<PolicyCoverageDTO>();

        //Get all relevant polocies for this member/person account
        List<InsurancePolicy> policies = [
            SELECT Id, Name, Status, CreatedDate
            FROM InsurancePolicy
            WHERE NameInsuredId = :personAccountId
            AND Status IN ('Activated', 'Awaiting Signature', 'Awaiting Approval', 'Awaiting Activation', 'Terminated')
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];

        if(policies.isEmpty()) return new List<PolicyCoverageDTO>();

        //Pick one policy based on priority: Activated > Awaiting * > Terminated
        InsurancePolicy selected;

        //Tier 1: Activated
        for (InsurancePolicy p : policies) {
            if (p.Status == 'Activated') {
                selected = p;
                break;
            }
        }

        // Tier 2: Any Awaiting*
        if (selected == null) {
            for (InsurancePolicy p : policies) {
                if (p.Status == 'Awaiting Activation'
                || p.Status == 'Awaiting Approval'
                || p.Status == 'Awaiting Signature') {
                    selected = p; break;
                }
            }
        }

        // Tier 3: Terminated
        if (selected == null) {
            for (InsurancePolicy p : policies) {
                if (p.Status == 'Terminated') { selected = p; break; }
            }
        }

        if (selected == null) return new List<PolicyCoverageDTO>();

        //Get coverages ONLY for the selected policy
        
        List<InsurancePolicyCoverage> covs = [
            SELECT Id,
                Name,
                CoverageName,
                InsurancePolicyId,
                InsurancePolicy.Name,
                InsurancePolicy.NameInsuredId,
                InsurancePolicy.Status
            FROM InsurancePolicyCoverage
            WHERE InsurancePolicyId = :selected.Id
            AND ARC_ParentProduct__c = null
            ORDER BY CoverageName ASC
            LIMIT 200
        ];

        //Map to DTOs
        List<PolicyCoverageDTO> out = new List<PolicyCoverageDTO>();
        for (InsurancePolicyCoverage cov : covs) {
            PolicyCoverageDTO dto = new PolicyCoverageDTO();
            dto.coverageId = cov.Id;
            dto.coverageName = String.isBlank(cov.CoverageName) ? cov.Name : cov.CoverageName;
            dto.policyId = cov.InsurancePolicyId;
            dto.policyName = cov.InsurancePolicy != null ? cov.InsurancePolicy.Name : null;
            out.add(dto);
        }
        return out;
    }

    //-------------- UHSM-3204
    public class EmployerInfoDTO{
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Boolean isSmallGroup;
        @AuraEnabled public String groupNumber;
        @AuraEnabled public String pbcName;
        @AuraEnabled public String pbcPhone;
        @AuraEnabled public String pbcEmail;
        @AuraEnabled public Date contracOriginalEffeciveDate;
    }


    @AuraEnabled(cacheable=true)
    public static EmployerInfoDTO getEmployerInfo(Id caseId) {
        EmployerInfoDTO dto = new EmployerInfoDTO();
        if (caseId == null) return dto;

        Case c = [
            SELECT Id,
                AccountId,
                Account.Name,
                Account.RecordType.DeveloperName,
                Account.ARC_GroupNumber__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        if (c.AccountId == null) {
            //If it's not Small Group, we hide the section in the LWC.
            dto.isSmallGroup = false;
            return dto;
        }

        dto.accountId = c.AccountId;
        dto.accountName = c.Account.Name;
        dto.groupNumber = c.Account.ARC_GroupNumber__c;
        dto.isSmallGroup = (c.Account.RecordType.DeveloperName == 'ARC_SmallGroup');

        //Get Orinal Effectiva date from the contract related to the account
        List<Contract> contracts = [
            SELECT Id, ARC_EffectiveDate__c, Status
            FROM Contract
            WHERE AccountId = :dto.accountId
            LIMIT 1
        ];

        if (!contracts.isEmpty()) {
            dto.contracOriginalEffeciveDate = contracts[0].ARC_EffectiveDate__c;
        }

        //Get Primary Business Contact
        List<AccountContactRelation> acrs = [
            SELECT Id, 
                Contact.Name, 
                Contact.Phone, 
                Contact.Email, 
                Roles, 
                ContactId
            FROM AccountContactRelation
            WHERE AccountId = :dto.accountId 
                AND IsActive = true
                AND Roles INCLUDES ('Primary Business Contact')
            LIMIT 1
        ];

        if (!acrs.isEmpty()) {
            dto.pbcName = acrs[0].Contact.Name;
            dto.pbcPhone = acrs[0].Contact.Phone;
            dto.pbcEmail = acrs[0].Contact.Email;
        }

        return dto;
    }
}