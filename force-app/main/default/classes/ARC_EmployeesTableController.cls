public with sharing class ARC_EmployeesTableController {

    @AuraEnabled(cacheable=true)
    public static Boolean checkEnrollmentPermission(List<Id> personIds) {
        Boolean hasPS = FeatureManagement.checkPermission('Launch_Send_Enrollment_Link');

        Boolean hasPermSet = false;
        List<PermissionSetAssignment> psaList = [
            SELECT Id 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :UserInfo.getUserId() 
            AND PermissionSet.Name = 'Employer_Admin_Permissions'
        ];
        if (!psaList.isEmpty()) {
            hasPermSet = true;
        }
        return hasPS || hasPermSet;
    }

    @AuraEnabled(cacheable=true)
    public static Id getUserAccountId() {
        Id accId = [
            SELECT AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED
        ].AccountId;
        return accId;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isOpenEnrollmentActive(Id accountId) {
        User currentUser = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
        List<Contract> contracts = [
            SELECT ARC_OEStartDate__c, ARC_OEEndDate__c 
            FROM Contract WHERE AccountId = :currentUser.AccountId 
            WITH SECURITY_ENFORCED LIMIT 1
        ];
        if (contracts.isEmpty()) return false;
        Date today = Date.today();
        Contract c = contracts[0];
        Boolean inOE = c.ARC_OEStartDate__c != null && c.ARC_OEEndDate__c != null
            && today >= c.ARC_OEStartDate__c && today <= c.ARC_OEEndDate__c;
        if (inOE) return true;
        
        if (accountId != null) {
            List<vlocity_ins__GroupCensusMember__c> members = [
                SELECT vlocity_ins__AccountId__r.ARC_AllowEnrollmentOutsideOE__c
                FROM vlocity_ins__GroupCensusMember__c
                WHERE vlocity_ins__AccountId__c = :accountId
                AND vlocity_ins__IsPrimaryMember__c = true
                WITH SECURITY_ENFORCED LIMIT 1
            ];
            if (!members.isEmpty()) {
                return members[0].vlocity_ins__AccountId__r.ARC_AllowEnrollmentOutsideOE__c == true;
            }
        }
        return false;
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getQLE() {
        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED];
        return [
            SELECT Id, CaseNumber, AccountId, Status, Contact.AccountId, ARC_PersonAccount__c, ARC_PersonAccount__r.Name,
                   arcsona__Type__c, ARC_QLEType__c
            FROM Case
            WHERE Status NOT IN ('Closed Approved','Closed Voided')
              AND ARC_CaseType__c = 'Qualify Event'
              AND AccountId = :currentUser.AccountId
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
        ];
    }



    @AuraEnabled
    public static void updateCases(List<Case> casesToUpdate) {
        try {
            update casesToUpdate;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> getPoliciesfromContracts() {
        Date today = Date.today();
        List<Map<String,Object>> result = new List<Map<String,Object>>();
        List<Map<String,Object>> downloadableData = new List<Map<String,Object>>();
        
        Map<Id, InsurancePolicyParticipant> censusMemberIdToPolicyParticipant = new Map<Id, InsurancePolicyParticipant>();
        Map<Id, List<String>> policyToProductNames = new Map<Id, List<String>>();
        Map<Id, Date> policyToEffectiveDate = new Map<Id, Date>();
        Map<Id, Date> policyToExpirationDate = new Map<Id, Date>();
        Map<Id, List<Map<String, Object>>> primaryMemberToMembers = new Map<Id, List<Map<String, Object>>>();
        Map<Id, String> accountToProducts = new Map<Id, String>();

        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED];

        List<Contract> selectedContracts = [
            SELECT Id, Status, ARC_OEStartDate__c, ARC_OEEndDate__c
            FROM Contract
            WHERE AccountId = :currentUser.AccountId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (selectedContracts.isEmpty()) {
            return new List<Map<String,Object>>();
        }

        Contract selectedContract = selectedContracts[0];

        Map<Id, InsurancePolicy> policiesMap = new Map<Id, InsurancePolicy>([
            SELECT Id, ARC_EffectiveDate__c, ARC_ExpirationDate__c, Status
            FROM InsurancePolicy
            WHERE ARC_Contract__c = :selectedContract.Id
            WITH SECURITY_ENFORCED
        ]);
        List<InsurancePolicy> policies = policiesMap.values();

        for (InsurancePolicy p : policies) {
            policyToEffectiveDate.put(p.Id, p.ARC_EffectiveDate__c);
            policyToExpirationDate.put(p.Id, p.ARC_ExpirationDate__c);
        }

        for (InsurancePolicyCoverage cov : [
            SELECT InsurancePolicyId,
                   vlocity_ins_fsc__Product2Id__r.Name,
                   ARC_ParentProduct__c,
                   (
                       SELECT Id,
                              ARC_ParticipantName__c,
                              ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId
                       FROM Coverage_Participants__r
                   )
            FROM InsurancePolicyCoverage
            WHERE InsurancePolicyId IN :policies
              AND ARC_ParentProduct__c = NULL
            WITH SECURITY_ENFORCED
        ]) {
            if (!policyToProductNames.containsKey(cov.InsurancePolicyId)) {
                policyToProductNames.put(cov.InsurancePolicyId, new List<String>());
            }
            if (cov.vlocity_ins_fsc__Product2Id__r != null) {
                policyToProductNames.get(cov.InsurancePolicyId).add(cov.vlocity_ins_fsc__Product2Id__r.Name);
            }

            for (ARC_CoverageParticipant__c coverageParticipant : cov.Coverage_Participants__r) {
                Id memberAccountId = coverageParticipant.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId;
                String productName = cov.vlocity_ins_fsc__Product2Id__r.Name;

                if (accountToProducts.containsKey(memberAccountId)) {
                    String products = accountToProducts.get(memberAccountId) + '|' + productName;
                    accountToProducts.put(memberAccountId, products);
                } else {
                    accountToProducts.put(memberAccountId, productName);
                }
            }
        }

        List<InsurancePolicyParticipant> participants = [
            SELECT Id,
                   InsurancePolicyId,
                   Role,
                   PrimaryParticipantContactId,
                   PrimaryParticipantContact.Name,
                   PrimaryParticipantContact.Account.Census_Member__r.Id,
                   PrimaryParticipantContact.Account.Census_Member__c,
                   PrimaryParticipantContact.Account.FirstName,
                   PrimaryParticipantContact.Account.LastName,
                   PrimaryParticipantContact.Account.PersonGender,
                   PrimaryParticipantContact.Account.ARC_DependentRelationship__c,
                   PrimaryParticipantContact.Account.ARC_EmployeeType__c,
                   PrimaryParticipantContact.Account.ARC_EmployeeDivision__c,
                   PrimaryParticipantContact.Account.ARC_PrimaryMemberAccount__r.Census_Member__c,
                   PrimaryParticipantContact.Account.Census_Member__r.ARC_ActiveMember__c,
                   PrimaryParticipantContact.Account.Census_Member__r.vlocity_ins__GroupClassId__r.Name,
                   PrimaryParticipantContact.Account.IsActive,
                   PrimaryParticipantContact.Account.PersonBirthdate,
                   PrimaryParticipantContact.Account.vlocity_ins__SocialSecurityNumber__pc,
                   PrimaryParticipantContact.Account.Name,
                   PrimaryParticipantContact.AccountId,
                   PrimaryParticipantContact.Account.ARC_CoverageWaived__c
            FROM InsurancePolicyParticipant
            WHERE InsurancePolicyId IN :policies
        ];

        Set<Id> censusMemberIdsWithPolicy = new Set<Id>();
        Set<Id> censusMemberIdsWithVoidedPolicy = new Set<Id>();

        for (InsurancePolicyParticipant participant : participants) {
            if (participant.Role != 'Primary') {
                continue;
            }

            Id censusMemberId = participant.PrimaryParticipantContact.Account.Census_Member__c;
            InsurancePolicy currentPolicy = policiesMap.get(participant.InsurancePolicyId);
            Integer currentPriority = getPolicyPriority(currentPolicy != null ? currentPolicy.Status : null);

            if (censusMemberIdToPolicyParticipant.containsKey(censusMemberId)) {
                InsurancePolicyParticipant existingParticipant = censusMemberIdToPolicyParticipant.get(censusMemberId);
                InsurancePolicy existingPolicy = policiesMap.get(existingParticipant.InsurancePolicyId);
                Integer existingPriority = getPolicyPriority(existingPolicy != null ? existingPolicy.Status : null);

                if (currentPriority < existingPriority) {
                    censusMemberIdToPolicyParticipant.put(censusMemberId, participant);
                }
            } else {
                censusMemberIdToPolicyParticipant.put(censusMemberId, participant);
            }

            censusMemberIdsWithPolicy.add(censusMemberId);
        }

        for (Id censusMemberId : censusMemberIdToPolicyParticipant.keySet()) {
            InsurancePolicyParticipant p = censusMemberIdToPolicyParticipant.get(censusMemberId);

            if (p.PrimaryParticipantContact == null) {
                continue;
            }

            Boolean isPrimary = p.PrimaryParticipantContact.Account?.ARC_PrimaryMemberAccount__r != null ||
                                p.PrimaryParticipantContact.Account?.Census_Member__c != null;
            if (!isPrimary) {
                continue;
            }

            InsurancePolicy memberPolicy = policiesMap.get(p.InsurancePolicyId);

            Boolean activeMember = false;
            if (p.PrimaryParticipantContact.Account?.Census_Member__r != null) {
                activeMember = p.PrimaryParticipantContact.Account.Census_Member__r.ARC_ActiveMember__c;
            }

            String policyStatus = memberPolicy != null ? memberPolicy.Status : null;
            Boolean pendingEnrollment = false;
            String statusValue = determineStatus(policyStatus, activeMember, pendingEnrollment);

            if (policyStatus == 'Voided') {
                censusMemberIdsWithVoidedPolicy.add(censusMemberId);
                continue;
            }

            Map<String,Object> row = new Map<String,Object>();
            row.put('Id', p.Id);
            row.put('CensusMemberId', censusMemberId);
            row.put('Name', p.PrimaryParticipantContact?.Name != null ? p.PrimaryParticipantContact.Name : 'Unknown');
            row.put('Name1', p.PrimaryParticipantContact.Account?.Name != null ? p.PrimaryParticipantContact.Account.Name : 'Unknown');
            row.put('CoverageWaived', p.PrimaryParticipantContact.Account?.ARC_CoverageWaived__c);
            row.put('Role', p.Role);
            row.put('AccountId', p.PrimaryParticipantContact.AccountId);
            row.put('ContactId', p.PrimaryParticipantContactId);
            row.put('IsActiveMember', activeMember);
            row.put('PolicyStatus', policyStatus);
            row.put('Status', statusValue);
            row.put('IsActive', p.PrimaryParticipantContact.Account?.IsActive);
            row.put(
                'Birthdate',
                p.PrimaryParticipantContact.Account?.PersonBirthdate != null
                    ? p.PrimaryParticipantContact.Account.PersonBirthdate.format()
                    : null
            );
            row.put('SSN', p.PrimaryParticipantContact.Account?.vlocity_ins__SocialSecurityNumber__pc);
            row.put(
                'ProductName',
                policyToProductNames.containsKey(p.InsurancePolicyId)
                    ? String.join(policyToProductNames.get(p.InsurancePolicyId), ', ')
                    : null
            );
            row.put('EffectiveDate', policyToEffectiveDate.get(p.InsurancePolicyId));

            result.add(row);
        }

        List<vlocity_ins__GroupCensusMember__c> membersWithoutPolicy = [
            SELECT Id,
                   Name,
                   vlocity_ins__FirstName__c,
                   vlocity_ins__LastName__c,
                   vlocity_ins__Gender__c,
                   vlocity_ins__Birthdate__c,
                   ARC_DependentRelationship__c,
                   ARC_EmployeeType__c,
                   ARC_EmployeeDivision__c,
                   vlocity_ins__GroupClassId__r.Name,
                   vlocity_ins__RelatedCensusMemberId__c,
                   vlocity_ins__AccountId__c,
                   vlocity_ins__ContactId__c,
                   ARC_ActiveMember__c,
                   vlocity_ins__IsPrimaryMember__c,
                   vlocity_ins__CensusId__r.vlocity_ins__GroupId__c,
                   vlocity_ins__AccountId__r.ARC_CoverageWaived__c,
                   vlocity_ins__AccountId__r.ARC_AllowEnrollmentOutsideOE__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__CensusId__r.vlocity_ins__GroupId__c = :currentUser.AccountId
              AND Id NOT IN :censusMemberIdsWithPolicy
              AND Id NOT IN :censusMemberIdsWithVoidedPolicy
            WITH SECURITY_ENFORCED
        ];

        for (vlocity_ins__GroupCensusMember__c m : membersWithoutPolicy) {
            Map<String,Object> downloadableRow = new Map<String,Object>();
            Boolean pendingEnrollment =
                m.vlocity_ins__AccountId__r.ARC_CoverageWaived__c == false &&
                (
                    (
                        selectedContract.ARC_OEStartDate__c != null &&
                        selectedContract.ARC_OEEndDate__c != null &&
                        today >= selectedContract.ARC_OEStartDate__c &&
                        today <= selectedContract.ARC_OEEndDate__c
                    )
                    ||
                    m.vlocity_ins__AccountId__r.ARC_AllowEnrollmentOutsideOE__c == true
                );
            String statusValue = determineStatus(null, m.ARC_ActiveMember__c, pendingEnrollment);

            if (m.vlocity_ins__IsPrimaryMember__c) {
                Map<String,Object> row = new Map<String,Object>();
                row.put('Id', m.Id);
                row.put('CensusMemberId', m.Id);
                row.put('Name', m.Name);
                row.put('Status', statusValue);
                row.put('ProductName', null);
                row.put('EffectiveDate', null);
                row.put('AccountId', m.vlocity_ins__AccountId__c);
                row.put('ContactId', m.vlocity_ins__ContactId__c);
                row.put('CoverageWaived', m.vlocity_ins__AccountId__r.ARC_CoverageWaived__c);
                result.add(row);
            }

            String primaryMemberId = m.vlocity_ins__RelatedCensusMemberId__c != null ? m.vlocity_ins__RelatedCensusMemberId__c : m.Id;
            downloadableRow.put('FirstName', m.vlocity_ins__FirstName__c);
            downloadableRow.put('LastName', m.vlocity_ins__LastName__c);
            downloadableRow.put('Gender', m.vlocity_ins__Gender__c);
            downloadableRow.put('DOB', m.vlocity_ins__Birthdate__c);
            downloadableRow.put('Relationship', m.ARC_DependentRelationship__c != null ? m.ARC_DependentRelationship__c : 'Primary');
            downloadableRow.put('EmploymentType', m.ARC_EmployeeType__c);
            downloadableRow.put('Division', m.ARC_EmployeeDivision__c);
            downloadableRow.put('JobClass', m.vlocity_ins__GroupClassId__r.Name);
            downloadableRow.put('EffectiveDate', '');
            downloadableRow.put('ExpirationDate', '');
            downloadableRow.put('Programs', '');
            downloadableRow.put('PrimaryMember', primaryMemberId);
            downloadableRow.put('Status', statusValue);
            downloadableRow.put('CoverageWaived', m.vlocity_ins__AccountId__r.ARC_CoverageWaived__c);

            if (!primaryMemberToMembers.containsKey(primaryMemberId)) {
                primaryMemberToMembers.put(primaryMemberId, new List<Map<String,Object>>());
            }
            primaryMemberToMembers.get(primaryMemberId).add(downloadableRow);
        }

        for (Id censusMemberId : censusMemberIdToPolicyParticipant.keySet()) {
            InsurancePolicyParticipant currentParticipant = censusMemberIdToPolicyParticipant.get(censusMemberId);
            Map<String,Object> downloadableRow = new Map<String,Object>();
            Id censusMemberPolicyId = currentParticipant.InsurancePolicyId;
            InsurancePolicy memberPolicy = policiesMap.get(censusMemberPolicyId);
            String primaryMemberId = currentParticipant.PrimaryParticipantContact.Account.ARC_PrimaryMemberAccount__r.Census_Member__c != null
                ? currentParticipant.PrimaryParticipantContact.Account.ARC_PrimaryMemberAccount__r.Census_Member__c
                : currentParticipant.PrimaryParticipantContact.Account.Census_Member__c;

            downloadableRow.put('FirstName', currentParticipant.PrimaryParticipantContact.Account.FirstName);
            downloadableRow.put('LastName', currentParticipant.PrimaryParticipantContact.Account.LastName);
            downloadableRow.put('Gender', currentParticipant.PrimaryParticipantContact.Account.PersonGender);
            downloadableRow.put('DOB', currentParticipant.PrimaryParticipantContact.Account.PersonBirthdate);
            downloadableRow.put(
                'Relationship',
                currentParticipant.PrimaryParticipantContact.Account.ARC_DependentRelationship__c == null
                    ? 'Primary'
                    : currentParticipant.PrimaryParticipantContact.Account.ARC_DependentRelationship__c
            );
            downloadableRow.put('EmploymentType', currentParticipant.PrimaryParticipantContact.Account.ARC_EmployeeType__c);
            downloadableRow.put('Division', currentParticipant.PrimaryParticipantContact.Account.ARC_EmployeeDivision__c);
            downloadableRow.put('JobClass', currentParticipant.PrimaryParticipantContact.Account.Census_Member__r.vlocity_ins__GroupClassId__r.Name);
            downloadableRow.put('EffectiveDate', memberPolicy.ARC_EffectiveDate__c);
            downloadableRow.put('ExpirationDate', memberPolicy.ARC_ExpirationDate__c);
            downloadableRow.put('Programs', accountToProducts.get(currentParticipant.PrimaryParticipantContact.AccountId));
            downloadableRow.put('PrimaryMember', primaryMemberId);
            downloadableRow.put('Status', memberPolicy.Status);
            // Modified: include waived members flag in downloadable census
            downloadableRow.put('CoverageWaived', currentParticipant.PrimaryParticipantContact.Account.ARC_CoverageWaived__c);

            downloadableData.add(downloadableRow);

            if (!primaryMemberToMembers.containsKey(primaryMemberId)) {
                primaryMemberToMembers.put(primaryMemberId, new List<Map<String,Object>>());
            }
            primaryMemberToMembers.get(primaryMemberId).add(downloadableRow);
        }

        List<Map<String,Object>> downloadableOrdered = orderCensusMembers(primaryMemberToMembers);

        result.add(new Map<String,Object>{ 'primaryMemberToMembers' => primaryMemberToMembers });
        result.add(new Map<String,Object>{ 'downloadableData' => downloadableOrdered });

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> getCensusDownloadableData() {
        Date today = Date.today();
        List<Map<String,Object>> result = new List<Map<String,Object>>();
        List<Map<String,Object>> downloadableData = new List<Map<String,Object>>();
        
        Map<Id, InsurancePolicyParticipant> censusMemberIdToPolicyParticipant = new Map<Id, InsurancePolicyParticipant>();
        Map<Id, List<String>> policyToProductNames = new Map<Id, List<String>>();
        Map<Id, Date> policyToEffectiveDate = new Map<Id, Date>();
        Map<Id, Date> policyToExpirationDate = new Map<Id, Date>();
        Map<Id, List<Map<String, Object>>> primaryMemberToMembers = new Map<Id, List<Map<String, Object>>>();
        Map<Id, String> accountToProducts = new Map<Id, String>();

        User currentUser = [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED];

        List<Contract> selectedContracts = [
            SELECT Id, Status, ARC_OEStartDate__c, ARC_OEEndDate__c
            FROM Contract
            WHERE AccountId = :currentUser.AccountId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (selectedContracts.isEmpty()) {
            return new List<Map<String,Object>>();
        }

        Contract selectedContract = selectedContracts[0];

        Map<Id, InsurancePolicy> policiesMap = new Map<Id, InsurancePolicy>([
            SELECT Id, ARC_EffectiveDate__c, ARC_ExpirationDate__c, Status
            FROM InsurancePolicy
            WHERE ARC_Contract__c = :selectedContract.Id
            WITH SECURITY_ENFORCED
        ]);
        List<InsurancePolicy> policies = policiesMap.values();

        for (InsurancePolicy p : policies) {
            policyToEffectiveDate.put(p.Id, p.ARC_EffectiveDate__c);
            policyToExpirationDate.put(p.Id, p.ARC_ExpirationDate__c);
        }

        for (InsurancePolicyCoverage cov : [
            SELECT InsurancePolicyId,
                   vlocity_ins_fsc__Product2Id__r.Name,
                   ARC_ParentProduct__c,
                   (
                       SELECT Id,
                              ARC_ParticipantName__c,
                              ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId
                       FROM Coverage_Participants__r
                   )
            FROM InsurancePolicyCoverage
            WHERE InsurancePolicyId IN :policies
              AND ARC_ParentProduct__c = NULL
            WITH SECURITY_ENFORCED
        ]) {
            if (!policyToProductNames.containsKey(cov.InsurancePolicyId)) {
                policyToProductNames.put(cov.InsurancePolicyId, new List<String>());
            }
            if (cov.vlocity_ins_fsc__Product2Id__r != null) {
                policyToProductNames.get(cov.InsurancePolicyId).add(cov.vlocity_ins_fsc__Product2Id__r.Name);
            }

            for (ARC_CoverageParticipant__c coverageParticipant : cov.Coverage_Participants__r) {
                Id memberAccountId = coverageParticipant.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId;
                String productName = cov.vlocity_ins_fsc__Product2Id__r.Name;

                if (accountToProducts.containsKey(memberAccountId)) {
                    String products = accountToProducts.get(memberAccountId) + '|' + productName;
                    accountToProducts.put(memberAccountId, products);
                } else {
                    accountToProducts.put(memberAccountId, productName);
                }
            }
        }

        List<InsurancePolicyParticipant> participants = [
            SELECT Id,
                   InsurancePolicyId,
                   Role,
                   PrimaryParticipantContactId,
                   PrimaryParticipantContact.Name,
                   PrimaryParticipantContact.Account.Census_Member__r.Id,
                   PrimaryParticipantContact.Account.Census_Member__c,
                   PrimaryParticipantContact.Account.FirstName,
                   PrimaryParticipantContact.Account.LastName,
                   PrimaryParticipantContact.Account.PersonGender,
                   PrimaryParticipantContact.Account.ARC_DependentRelationship__c,
                   PrimaryParticipantContact.Account.ARC_EmployeeType__c,
                   PrimaryParticipantContact.Account.ARC_EmployeeDivision__c,
                   PrimaryParticipantContact.Account.ARC_PrimaryMemberAccount__r.Census_Member__c,
                   PrimaryParticipantContact.Account.Census_Member__r.ARC_ActiveMember__c,
                   PrimaryParticipantContact.Account.Census_Member__r.vlocity_ins__GroupClassId__r.Name,
                   PrimaryParticipantContact.Account.IsActive,
                   PrimaryParticipantContact.Account.PersonBirthdate,
                   PrimaryParticipantContact.Account.vlocity_ins__SocialSecurityNumber__pc,
                   PrimaryParticipantContact.Account.Name,
                   PrimaryParticipantContact.AccountId,
                   PrimaryParticipantContact.Account.ARC_CoverageWaived__c
            FROM InsurancePolicyParticipant
            WHERE InsurancePolicyId IN :policies
        ];

        Set<Id> censusMemberIdsWithPolicy = new Set<Id>();
        Set<Id> censusMemberIdsWithVoidedPolicy = new Set<Id>();

        for (InsurancePolicyParticipant participant : participants) {
            Id censusMemberId = participant.PrimaryParticipantContact.Account.Census_Member__c;
            InsurancePolicy currentPolicy = policiesMap.get(participant.InsurancePolicyId);
            String currentStatus = currentPolicy != null ? currentPolicy.Status : null;

            // Modified: skip voided policies so waived/non-policy members can still be included correctly
            if (currentStatus == 'Voided') {
                censusMemberIdsWithVoidedPolicy.add(censusMemberId);
                continue;
            }

            Integer currentPriority = getPolicyPriority(currentStatus);

            if (censusMemberIdToPolicyParticipant.containsKey(censusMemberId)) {
                InsurancePolicyParticipant existingParticipant = censusMemberIdToPolicyParticipant.get(censusMemberId);
                InsurancePolicy existingPolicy = policiesMap.get(existingParticipant.InsurancePolicyId);
                Integer existingPriority = getPolicyPriority(existingPolicy != null ? existingPolicy.Status : null);

                if (currentPriority < existingPriority) {
                    censusMemberIdToPolicyParticipant.put(censusMemberId, participant);
                }
            } else {
                censusMemberIdToPolicyParticipant.put(censusMemberId, participant);
            }

            censusMemberIdsWithPolicy.add(censusMemberId);
        }

        List<vlocity_ins__GroupCensusMember__c> membersWithoutPolicy = [
            SELECT Id,
                   Name,
                   vlocity_ins__FirstName__c,
                   vlocity_ins__LastName__c,
                   vlocity_ins__Gender__c,
                   vlocity_ins__Birthdate__c,
                   ARC_DependentRelationship__c,
                   ARC_EmployeeType__c,
                   ARC_EmployeeDivision__c,
                   vlocity_ins__GroupClassId__r.Name,
                   vlocity_ins__RelatedCensusMemberId__c,
                   vlocity_ins__AccountId__c,
                   vlocity_ins__ContactId__c,
                   ARC_ActiveMember__c,
                   vlocity_ins__IsPrimaryMember__c,
                   vlocity_ins__CensusId__r.vlocity_ins__GroupId__c,
                   vlocity_ins__AccountId__r.ARC_CoverageWaived__c,
                   vlocity_ins__AccountId__r.ARC_AllowEnrollmentOutsideOE__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__CensusId__r.vlocity_ins__GroupId__c = :currentUser.AccountId
              AND Id NOT IN :censusMemberIdsWithPolicy
              AND Id NOT IN :censusMemberIdsWithVoidedPolicy
            WITH SECURITY_ENFORCED
        ];

        for (vlocity_ins__GroupCensusMember__c m : membersWithoutPolicy) {
            Map<String,Object> downloadableRow = new Map<String,Object>();
            Boolean pendingEnrollment =
                m.vlocity_ins__AccountId__r.ARC_CoverageWaived__c == false &&
                (
                    (
                        selectedContract.ARC_OEStartDate__c != null &&
                        selectedContract.ARC_OEEndDate__c != null &&
                        today >= selectedContract.ARC_OEStartDate__c &&
                        today <= selectedContract.ARC_OEEndDate__c
                    )
                    ||
                    m.vlocity_ins__AccountId__r.ARC_AllowEnrollmentOutsideOE__c == true
                );
            String statusValue = determineStatus(null, m.ARC_ActiveMember__c, pendingEnrollment);

            String primaryMemberId = m.vlocity_ins__RelatedCensusMemberId__c != null ? m.vlocity_ins__RelatedCensusMemberId__c : m.Id;
            downloadableRow.put('FirstName', m.vlocity_ins__FirstName__c);
            downloadableRow.put('LastName', m.vlocity_ins__LastName__c);
            downloadableRow.put('Gender', m.vlocity_ins__Gender__c);
            downloadableRow.put('DOB', m.vlocity_ins__Birthdate__c);
            downloadableRow.put('Relationship', m.ARC_DependentRelationship__c != null ? m.ARC_DependentRelationship__c : 'Primary');
            downloadableRow.put('EmploymentType', m.ARC_EmployeeType__c);
            downloadableRow.put('Division', m.ARC_EmployeeDivision__c);
            downloadableRow.put('JobClass', m.vlocity_ins__GroupClassId__r.Name);
            downloadableRow.put('EffectiveDate', '');
            downloadableRow.put('ExpirationDate', '');
            downloadableRow.put('Programs', '');
            downloadableRow.put('PrimaryMember', primaryMemberId);
            downloadableRow.put('Status', statusValue);
            // Modified: include waived flag for non-policy census members in CSV
            downloadableRow.put('CoverageWaived', m.vlocity_ins__AccountId__r.ARC_CoverageWaived__c);

            if (!primaryMemberToMembers.containsKey(primaryMemberId)) {
                primaryMemberToMembers.put(primaryMemberId, new List<Map<String,Object>>());
            }
            primaryMemberToMembers.get(primaryMemberId).add(downloadableRow);
        }

        for (Id censusMemberId : censusMemberIdToPolicyParticipant.keySet()) {
            InsurancePolicyParticipant currentParticipant = censusMemberIdToPolicyParticipant.get(censusMemberId);
            Map<String,Object> downloadableRow = new Map<String,Object>();
            Id censusMemberPolicyId = currentParticipant.InsurancePolicyId;
            InsurancePolicy memberPolicy = policiesMap.get(censusMemberPolicyId);
            String primaryMemberId = currentParticipant.PrimaryParticipantContact.Account.ARC_PrimaryMemberAccount__r.Census_Member__c != null
                ? currentParticipant.PrimaryParticipantContact.Account.ARC_PrimaryMemberAccount__r.Census_Member__c
                : currentParticipant.PrimaryParticipantContact.Account.Census_Member__c;

            downloadableRow.put('FirstName', currentParticipant.PrimaryParticipantContact.Account.FirstName);
            downloadableRow.put('LastName', currentParticipant.PrimaryParticipantContact.Account.LastName);
            downloadableRow.put('Gender', currentParticipant.PrimaryParticipantContact.Account.PersonGender);
            downloadableRow.put('DOB', currentParticipant.PrimaryParticipantContact.Account.PersonBirthdate);
            downloadableRow.put(
                'Relationship',
                currentParticipant.PrimaryParticipantContact.Account.ARC_DependentRelationship__c == null
                    ? 'Primary'
                    : currentParticipant.PrimaryParticipantContact.Account.ARC_DependentRelationship__c
            );
            downloadableRow.put('EmploymentType', currentParticipant.PrimaryParticipantContact.Account.ARC_EmployeeType__c);
            downloadableRow.put('Division', currentParticipant.PrimaryParticipantContact.Account.ARC_EmployeeDivision__c);
            downloadableRow.put('JobClass', currentParticipant.PrimaryParticipantContact.Account.Census_Member__r.vlocity_ins__GroupClassId__r.Name);
            downloadableRow.put('EffectiveDate', memberPolicy.ARC_EffectiveDate__c);
            downloadableRow.put('ExpirationDate', memberPolicy.ARC_ExpirationDate__c);
            downloadableRow.put('Programs', accountToProducts.get(currentParticipant.PrimaryParticipantContact.AccountId));
            downloadableRow.put('PrimaryMember', primaryMemberId);
            downloadableRow.put('Status', memberPolicy.Status);
            // Modified: include waived flag for policy members in CSV
            downloadableRow.put('CoverageWaived', currentParticipant.PrimaryParticipantContact.Account.ARC_CoverageWaived__c);

            downloadableData.add(downloadableRow);

            if (!primaryMemberToMembers.containsKey(primaryMemberId)) {
                primaryMemberToMembers.put(primaryMemberId, new List<Map<String,Object>>());
            }
            primaryMemberToMembers.get(primaryMemberId).add(downloadableRow);
        }

        List<Map<String,Object>> downloadableOrdered = orderCensusMembers(primaryMemberToMembers);

        result.add(new Map<String,Object>{ 'primaryMemberToMembers' => primaryMemberToMembers });
        result.add(new Map<String,Object>{ 'downloadableData' => downloadableOrdered });

        return downloadableOrdered;
    }

    private static String determineStatus(String policyStatus, Boolean activeMember, Boolean pendingEnrollment) {
        if (policyStatus == 'Activated') {
            return 'Active';
        }

        if (policyStatus != null && policyStatus.contains('Awaiting')) {
            return policyStatus;
        }

        if (policyStatus == null && pendingEnrollment) {
            return 'Pending Enrollment';
        }

        return 'Inactive';
    }

    private static Integer getPolicyPriority(String status) {
        if (status == 'Activated') return 1;
        if (status != null && status.contains('Awaiting')) return 2;
        if (status == null) return 3;
        return 4;
    }

    public static List<Map<String, Object>> orderCensusMembers(Map<Id, List<Map<String, Object>>> inputFamily) {
        List<Map<String, Object>> output = new List<Map<String, Object>>();

        for (Id primaryMemberId : inputFamily.keySet()) {
            List<Map<String, Object>> members = inputFamily.get(primaryMemberId);

            Map<String, Object> primary = null;
            Map<String, Object> spouse = null;
            List<Map<String, Object>> children = new List<Map<String, Object>>();
            List<Map<String, Object>> others = new List<Map<String, Object>>();

            for (Map<String, Object> member : members) {
                String relationship = (String) member.get('Relationship');

                if (relationship == 'Primary') {
                    primary = member;
                } else if (relationship == 'Spouse') {
                    spouse = member;
                } else if (relationship == 'Child') {
                    children.add(member);
                } else {
                    others.add(member);
                }
            }

            if (primary != null) output.add(primary);
            if (spouse != null) output.add(spouse);
            if (!children.isEmpty()) output.addAll(children);
            if (!others.isEmpty()) output.addAll(others);
        }

        return output;
    }
}