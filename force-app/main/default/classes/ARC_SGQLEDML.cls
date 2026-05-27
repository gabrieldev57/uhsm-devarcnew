global without sharing class ARC_SGQLEDML {
    public ARC_SGQLEManager manager;
    public Map<String, Object> enrollmentInfo;

    public void processEnrollment(ARC_SGQLEManager manager) {
        Savepoint sp = Database.setSavepoint();
        this.manager = manager;
        this.enrollmentInfo = manager.enrollmentInfo;
        try {
            if (manager.ActionsSelected.contains('isReinstatement')) {
                processPolicy_Reinstatement();
            } else if (manager.ActionsSelected.contains('isDisenrollment')) {
                processPolicy_Disenrollment();
            } else {
                processCensusMembers();
                processPersonAccount();
                processGuardianAccount();
                processExternalInsurancePolicy();
                processExternalInsurancePolicyMember();
                processPolicy();
                processPolicyParticipants();
                processPolicyCoverages();
                processCoverageParticipants();
                processWaitingPeriods();
                processHIPAA();
            }
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('Exception while executing QLE DML operations - changes will be rolled back: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    private void processCensusMembers() {
        if (this.manager.memberIdToCensusMemberMap.isEmpty()) return;
        List<Database.UpsertResult> resultsCreate = Database.upsert(this.manager.memberIdToCensusMemberMap.values(), true);
        for (Database.UpsertResult result : resultsCreate) {
            if (!result.isSuccess()) {
                throw new DmlException('Failed to upsert census: ' + result.getErrors());
            }
        }
    }

    private void processPersonAccount() {
        if (this.manager.memberIdToAccountMap.isEmpty()) return;

        for (String key : this.manager.memberIdToAccountMap.keySet()) {
            Account personAccount = this.manager.memberIdToAccountMap.get(key);
            if (personAccount != null && personAccount.Id == null && this.manager.memberIdToCensusMemberMap.containsKey(key)) {
                personAccount.Census_Member__c = this.manager.memberIdToCensusMemberMap.get(key).Id;
                personAccount.ARC_CensusMember__pc = this.manager.memberIdToCensusMemberMap.get(key).Id;
            }
        }

        List<Id> personAccountsId = new List<Id>();
        List<Account> accountsToUpsert = new List<Account>(this.manager.memberIdToAccountMap.values());
        List<Database.UpsertResult> results = Database.upsert(accountsToUpsert, false);

        for (Database.UpsertResult result : results) {
            if (result.isSuccess()) {
                personAccountsId.add(result.getId());
            } else {
                throw new DmlException('Failed to upsert person account: ' + result.getErrors());
            }
        }

        List<Account> personAccounts = [SELECT Id, PersonContactId FROM Account WHERE Id IN :personAccountsId];
        for (Account personAccount : personAccounts) {
            for (String key : this.manager.memberIdToAccountMap.keySet()) {
                if (personAccount.Id == this.manager.memberIdToAccountMap.get(key).Id) {
                    this.manager.memberIdToPersonContactId.put(key, personAccount.PersonContactId);
                }
            }
        }

        updateRelatedCensusMembers();
    }

    private void processGuardianAccount() {
        Account guardian = this.manager.guardianToInsert;
        if (guardian == null) return;
        Database.UpsertResult result = Database.upsert(guardian, true);
        if (!result.isSuccess()) {
            throw new DmlException('Failed to upsert guardian account: ' + result.getErrors());
        }
        manager.guardianInserted = result.getId();
    }

    private void processExternalInsurancePolicy() {
        if (this.manager.externalPoliciesToInsert.isEmpty()) return;
        List<Database.UpsertResult> resultsUpdate = Database.upsert(this.manager.externalPoliciesToInsert.values(), true);
        for (Database.UpsertResult result : resultsUpdate) {
            if (!result.isSuccess()) {
                throw new DmlException('Failed to upsert external insurance policy: ' + result.getErrors());
            }
        }
    }

    private void processExternalInsurancePolicyMember() {
        if (this.manager.policyKeyToMemberIds.isEmpty()) return;

        for (String policyKey : manager.policyKeyToMemberIds.keySet()) {
            for (String memberId : manager.policyKeyToMemberIds.get(policyKey)) {
                ARC_ExternalInsurancePolicyMember__c externalPolicyMember = new ARC_ExternalInsurancePolicyMember__c();
                externalPolicyMember.ARC_ExternalInsurancePolicy__c = manager.externalPoliciesToInsert.containsKey(policyKey) ? manager.externalPoliciesToInsert.get(policyKey).Id : null;
                externalPolicyMember.ARC_PersonAccount__c = manager.memberIdToAccountMap.containsKey(memberId) ? manager.memberIdToAccountMap.get(memberId).Id : null;
                externalPolicyMember.ARC_CensusMember__c = manager.memberIdToCensusMemberMap.containsKey(memberId) ? manager.memberIdToCensusMemberMap.get(memberId).Id : null;
                this.manager.externalPolicyMembersToInsert.add(externalPolicyMember);
            }
        }

        if (!this.manager.externalPolicyMembersToInsert.isEmpty()) {
            List<Database.UpsertResult> resultsUpdate = Database.upsert(this.manager.externalPolicyMembersToInsert, true);
            for (Database.UpsertResult result : resultsUpdate) {
                if (!result.isSuccess()) {
                    throw new DmlException('Failed to upsert external insurance policy member: ' + result.getErrors());
                }
            }
        }
    }

    private void processPolicy() {
        if (this.manager.policy == null) return;
        if (this.manager.guardianToInsert != null) {
            this.manager.policy.ARC_Guardian__c = this.manager.guardianToInsert.Id;
        }
        Database.UpsertResult result = Database.upsert(this.manager.policy, true);
        if (!result.isSuccess()) {
            throw new DmlException('Failed to upsert policy: ' + result.getErrors());
        }
    }

    private void processPolicyParticipants() {
        if (this.manager.memberIdToPolicyParticipant.isEmpty()) return;

        for (String memberId : this.manager.memberIdToPolicyParticipant.keySet()) {
            InsurancePolicyParticipant polPart = this.manager.memberIdToPolicyParticipant.get(memberId);
            polPart.InsurancePolicyId = this.manager.policy.Id;
            polPart.PrimaryParticipantContactId = this.manager.memberIdToPersonContactId.get(memberId);
        }
        Database.UpsertResult[] results = Database.upsert(this.manager.memberIdToPolicyParticipant.values(), true);
        for (Database.UpsertResult result : results) {
            if (!result.isSuccess()) {
                throw new DmlException('Failed to upsert policy participant: ' + result.getErrors());
            }
        }
    }

    private void processPolicyCoverages() {
        System.debug('>>> [DML] enter in processPolicyCoverages');
        if (this.manager.indexToParentCovToInsert.isEmpty()) return;

        List<InsurancePolicyCoverage> parentCoverages = new List<InsurancePolicyCoverage>();
        for (String key : this.manager.indexToParentCovToInsert.keySet()) {
            InsurancePolicyCoverage polCov = this.manager.indexToParentCovToInsert.get(key);
            polCov.InsurancePolicyId = this.manager.policy.Id;
            parentCoverages.add(polCov);
        }

        List<Database.UpsertResult> parentResults = Database.upsert(parentCoverages, true);
        for (Database.UpsertResult result : parentResults) {
            if (!result.isSuccess()) {
                throw new DmlException('Failed to upsert policy coverage: ' + result.getErrors());
            }
        }

        List<InsurancePolicyCoverage> childCoverages = new List<InsurancePolicyCoverage>();
        for (String key : this.manager.indexToChildCovToInsert.keySet()) {
            List<InsurancePolicyCoverage> polCovList = this.manager.indexToChildCovToInsert.get(key);
            InsurancePolicyCoverage parentPolCov = this.manager.indexToParentCovToInsert.get(key);
            for (InsurancePolicyCoverage polCov : polCovList) {
                polCov.InsurancePolicyId = this.manager.policy.Id;
                polCov.ARC_ParentPolicyCoverage__c = parentPolCov.Id;
            }
            childCoverages.addAll(polCovList);
        }

        if (!childCoverages.isEmpty()) {
            Database.UpsertResult[] childResults = Database.upsert(childCoverages, true);
            for (Database.UpsertResult result : childResults) {
                if (!result.isSuccess()) {
                    throw new DmlException('Failed to upsert child policy coverage: ' + result.getErrors());
                }
            }
        }
    }

    private void processCoverageParticipants() {
        if (this.manager.indexToParentCovToInsert.isEmpty() || this.manager.indexToMemberIds.isEmpty()) return;

        List<ARC_CoverageParticipant__c> coverageParticipantsToInsert = new List<ARC_CoverageParticipant__c>();
        for (String key : this.manager.indexToParentCovToInsert.keySet()) {
            List<String> memberIds = this.manager.indexToMemberIds.get(key);
            if (memberIds == null) continue;
            String primaryCoverageMemberId = getPrimaryCoverageMemberId(memberIds);
            for (String memberId : memberIds) {
                ARC_CoverageParticipant__c covPart = new ARC_CoverageParticipant__c();
                covPart.ARC_PolicyParticipant__c = this.manager.memberIdToPolicyParticipant.get(memberId).Id;
                covPart.ARC_PolicyCoverage__c = this.manager.indexToParentCovToInsert.get(key).Id;
                covPart.ARC_Policy__c = this.manager.policy.Id;
                covPart.ARC_CoverageRole__c = getCoverageRole(memberId, primaryCoverageMemberId);
                coverageParticipantsToInsert.add(covPart);
            }
        }

        if (!coverageParticipantsToInsert.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(coverageParticipantsToInsert, true);
            for (Database.UpsertResult result : results) {
                if (!result.isSuccess()) {
                    throw new DmlException('Failed to upsert coverage participants: ' + result.getErrors());
                }
            }
        }
    }

    private String getPrimaryCoverageMemberId(List<String> coverageMemberIds) {
        if (coverageMemberIds == null || coverageMemberIds.isEmpty()) {
            return null;
        }

        String spouseMemberId;
        String oldestMemberId;
        Date oldestBirthdate;

        for (String memberId : coverageMemberIds) {
            String familyRole = this.manager.memberIdToFamilyRole.get(memberId);
            if (familyRole == 'Primary') {
                return memberId;
            }
            if (familyRole == 'Spouse') {
                spouseMemberId = memberId;
            }

            Date memberBirthdate = this.manager.memberIdToBirthdate.get(memberId);
            if (memberBirthdate != null && (oldestBirthdate == null || memberBirthdate < oldestBirthdate)) {
                oldestBirthdate = memberBirthdate;
                oldestMemberId = memberId;
            }
        }

        if (spouseMemberId != null) {
            return spouseMemberId;
        }

        return oldestMemberId;
    }

    private String getCoverageRole(String memberId, String primaryCoverageMemberId) {
        if (memberId == null) {
            return 'Dependent';
        }
        if (memberId == primaryCoverageMemberId) {
            return 'Primary';
        }

        String familyRole = this.manager.memberIdToFamilyRole.get(memberId);
        if (familyRole == 'Spouse' && this.manager.memberIdToFamilyRole.get(primaryCoverageMemberId) == 'Primary') {
            return 'Spouse';
        }

        return 'Dependent';
    }

    public void processPolicy_Disenrollment() {
        if (this.manager.policiesToDisenroll != null && !this.manager.policiesToDisenroll.isEmpty()) {
            update this.manager.policiesToDisenroll;
        }
    }

    public void processPolicy_Reinstatement() {
        if (this.manager.reinstatementPolicy == null) return;
        // Insert main policy
        insert this.manager.reinstatementPolicy;

        // Link policy ID and insert Participants
        if (this.manager.reinstatementParticipants != null && !this.manager.reinstatementParticipants.isEmpty()) {
            for (InsurancePolicyParticipant part : this.manager.reinstatementParticipants.values()) {
                part.InsurancePolicyId = this.manager.reinstatementPolicy.Id;
            }
            insert this.manager.reinstatementParticipants.values();
        }

        // Insert Coverages
        if (this.manager.reinstatementCoverages != null && !this.manager.reinstatementCoverages.isEmpty()) {
            List<InsurancePolicyCoverage> parentCoverages = new List<InsurancePolicyCoverage>();
            List<InsurancePolicyCoverage> childCoverages = new List<InsurancePolicyCoverage>();

            for (InsurancePolicyCoverage cov : this.manager.reinstatementCoverages.values()) {
                cov.InsurancePolicyId = this.manager.reinstatementPolicy.Id;
                if (cov.ARC_ParentPolicyCoverage__c == null) {
                    parentCoverages.add(cov);
                }
            }
            insert parentCoverages; 

            for (InsurancePolicyCoverage cov : this.manager.reinstatementCoverages.values()) {
                if (cov.ARC_ParentPolicyCoverage__c != null) {
                  
                    if (this.manager.reinstatementCoverages.containsKey(cov.ARC_ParentPolicyCoverage__c)) {
                        cov.ARC_ParentPolicyCoverage__c = this.manager.reinstatementCoverages.get(cov.ARC_ParentPolicyCoverage__c).Id;
                    }
                    childCoverages.add(cov);
                }
            }
            if (!childCoverages.isEmpty()) {
                insert childCoverages;
            }
        }

        // Insert junction objects cross-referencing the newly generated IDs
        if (this.manager.reinstatementCovParts != null && !this.manager.reinstatementCovParts.isEmpty()) {
            List<ARC_CoverageParticipant__c> covPartsToInsert = new List<ARC_CoverageParticipant__c>();
            
            for (ARC_CoverageParticipant__c oldCp : this.manager.reinstatementCovParts) {
                ARC_CoverageParticipant__c newCp = new ARC_CoverageParticipant__c();
                newCp.ARC_Policy__c = this.manager.reinstatementPolicy.Id;
                
                if (this.manager.reinstatementParticipants.containsKey(oldCp.ARC_PolicyParticipant__c)) {
                    newCp.ARC_PolicyParticipant__c = this.manager.reinstatementParticipants.get(oldCp.ARC_PolicyParticipant__c).Id;
                }
                if (this.manager.reinstatementCoverages.containsKey(oldCp.ARC_PolicyCoverage__c)) {
                    newCp.ARC_PolicyCoverage__c = this.manager.reinstatementCoverages.get(oldCp.ARC_PolicyCoverage__c).Id;
                }
                
                covPartsToInsert.add(newCp);
            }
            insert covPartsToInsert;
        }
    }

    private void processWaitingPeriods() {
        if (this.manager.policy != null && this.manager.policy.Id != null) {
            ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{this.manager.policy.Id}, null);
        }
    }

    private void processHIPAA() {
        List<ARC_HipaaAuthorization__c> listOfHipaaToInsert = new List<ARC_HipaaAuthorization__c>();

        if (!this.manager.hipaaCensusMember.isEmpty()) {
            for (String key : this.manager.hipaaCensusMember.keySet()) {
                ARC_HipaaAuthorization__c hipaa = this.manager.hipaaCensusMember.get(key);
                hipaa.ARC_AuthorizedMember__c = this.manager.memberIdToCensusMemberMap.get(key).Id;
                listOfHipaaToInsert.add(hipaa);
            }
        }

        if (!this.manager.hipaaThirdParty.isEmpty()) {
            List<Database.UpsertResult> resultsContact = Database.upsert(this.manager.hipaaExternalContact.values(), true);
            for (Database.UpsertResult result : resultsContact) {
                if (!result.isSuccess()) {
                    throw new DmlException('Failed to upsert HIPAA Contact: ' + result.getErrors());
                }
            }

            for (String key : this.manager.hipaaThirdParty.keySet()) {
                ARC_HipaaAuthorization__c hipaa = this.manager.hipaaThirdParty.get(key);
                hipaa.ARC_ExternalPersonAuthorized__c = this.manager.hipaaExternalContact.get(key).Id;
                listOfHipaaToInsert.add(hipaa);
            }
        }

        if (!this.manager.hipaaLegalGuardian.isEmpty() && this.manager.guardianToInsert != null) {
            Account guardian = [SELECT PersonContactId FROM Account WHERE Id =: this.manager.guardianToInsert.Id LIMIT 1];
            Id personContactId = guardian.PersonContactId;

            for (String key : this.manager.hipaaLegalGuardian.keySet()) {
                ARC_HipaaAuthorization__c hipaa = this.manager.hipaaLegalGuardian.get(key);
                hipaa.ARC_ExternalPersonAuthorized__c = personContactId;
                listOfHipaaToInsert.add(hipaa);
            }
        }

        if (!listOfHipaaToInsert.isEmpty()) {
            List<Database.UpsertResult> results = Database.upsert(listOfHipaaToInsert, true);
            for (Database.UpsertResult result : results) {
                if (!result.isSuccess()) {
                    throw new DmlException('Failed to upsert HIPAA records: ' + result.getErrors());
                }
            }
        }
    }

    private void updateRelatedCensusMembers() {
        if (this.manager.memberIdToCensusMemberMap.isEmpty()) return;

        String primaryMemberId = getPrimaryMemberId();
        for (String key : this.manager.memberIdToCensusMemberMap.keySet()) {
            vlocity_ins__GroupCensusMember__c member = this.manager.memberIdToCensusMemberMap.get(key);
            member.vlocity_ins__ContactId__c = this.manager.memberIdToPersonContactId.get(key);
            if (key != primaryMemberId) {
                member.vlocity_ins__RelatedCensusMemberId__c = this.manager.primaryCensusMemberId;
            }
        }
        Database.UpsertResult[] resultsCreate = Database.upsert(this.manager.memberIdToCensusMemberMap.values(), true);
        for (Database.UpsertResult result : resultsCreate) {
            if (!result.isSuccess()) {
                throw new DmlException('Failed to upsert census: ' + result.getErrors());
            }
        }
    }

    private String getPrimaryMemberId() {
        List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
        if (members == null) return null;
        for (Object memberInfo_obj : members) {
            Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
            if (String.valueOf(memberInfo.get('role')) == 'Primary') {
                return (String)memberInfo.get('memberId');
            }
        }
        return null;
    }
}