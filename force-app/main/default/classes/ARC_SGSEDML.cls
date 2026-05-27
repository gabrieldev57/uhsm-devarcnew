/**
 * @Description: DML class for Self Enrollment Flow operations for Small Groups.
 * This class handles all database operations for the self enrollment process.
 * 
 * @Author: Agustin Garay
 * @Date: 2025-10-10
 * @Version: 1.0
 */
global without sharing class ARC_SGSEDML {
    
    public ARC_SGSEManager manager;
    public Map<String, Object> enrollmentInfo;

    /**
     * @Description: Main method to process enrollment DML operations
     * @param manager: ARC_SGSEManager instance containing mapped objects
     */
    public void processEnrollment(ARC_SGSEManager manager) {
        Savepoint sp = Database.setSavepoint();
        this.manager = manager;
        this.enrollmentInfo = manager.enrollmentInfo;
        try {
            System.debug('Starting DML operations for Self Enrollment');
            
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

            System.debug('DML operations completed successfully');
            
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('Exception while executing DML operations - changes will be rolled back: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @Description: Processes Census Members DML operations
     */
    private void processCensusMembers() {
        try {
            System.debug('Processing Census DML');  
            if (!this.manager.memberIdToCensusMemberMap.isEmpty()) {

                List<Database.UpsertResult> resultsCreate = Database.upsert(this.manager.memberIdToCensusMemberMap.values(), true);
                for (Database.UpsertResult result : resultsCreate) {
                    if (result.isSuccess()) {
                        System.debug('Census member upserted successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting census: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert census: ' + result.getErrors());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in processCensus: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString()); 
            throw e;
        }
    }
    
    /**
     * @Description: Processes Person Account DML operations
     */
    private void processPersonAccount() {
        try {
            System.debug('Processing Person Account DML');
            
            if (!this.manager.memberIdToAccountMap.isEmpty()) {
                for (String key : this.manager.memberIdToAccountMap.keySet()) {
                    Account personAccount = this.manager.memberIdToAccountMap.get(key);
                    if (personAccount.Id == null) {
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
                        System.debug('Person Account created/updated successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting person account: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert person account: ' + result.getErrors());
                    }
                }

                // ---------------------------------------------------------
                // Retrieve PersonContactId from Person Accounts
                // ---------------------------------------------------------
                List<Account> personAccounts = [SELECT Id, PersonContactId FROM Account WHERE Id IN :personAccountsId];
                    
                for (Account personAccount : personAccounts) {
                    for (String key : this.manager.memberIdToAccountMap.keySet()) {
                        if (personAccount.Id == this.manager.memberIdToAccountMap.get(key).Id) {
                            this.manager.memberIdToPersonContactId.put(key, personAccount.PersonContactId);
                        }
                    }
                }

                // ---------------------------------------------------------
                // Link Census Members And PersonContactId
                // ---------------------------------------------------------
                updateRelatedCensusMembers();
            }
            
        } catch (Exception e) {
            System.debug('Error in processPersonAccount: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

   /**
     * @Description: Processes Policy DML operations
     */
    private void processPolicy() {
        try {
            System.debug('Processing Policy DML');
            
            if (this.manager.policy != null) {

                if (this.manager.guardianToInsert != null) {
                    this.manager.policy.ARC_Guardian__c = this.manager.guardianToInsert.Id;
                }

                Database.UpsertResult result = Database.upsert(this.manager.policy, true);
                if (result.isSuccess()) {
                    System.debug('Policy created successfully: ' + result.getId());
                } else {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error upserting policy: ' + error.getMessage());
                    }
                throw new DmlException('Failed to upsert policy: ' + result.getErrors());
                }
            }
        } catch (Exception e) {
            System.debug('Error in processPolicy: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Processes Policy Participants DML operations
     */
    private void processPolicyParticipants() {
        try {
            if (!this.manager.memberIdToPolicyParticipant.isEmpty()) {
                for (String memberId : this.manager.memberIdToPolicyParticipant.keySet()) {
                    InsurancePolicyParticipant polPart = this.manager.memberIdToPolicyParticipant.get(memberId);
                    polPart.InsurancePolicyId = this.manager.policy.Id;
                    polPart.PrimaryParticipantContactId = this.manager.memberIdToPersonContactId.get(memberId);
                }
                Database.UpsertResult[] results = Database.upsert(this.manager.memberIdToPolicyParticipant.values(), true);
                for (Database.UpsertResult result : results) {
                    if (result.isSuccess()) {
                        System.debug('Policy Participant created successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting policy participant: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert policy participant: ' + result.getErrors());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in processPolicyParticipants: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Processes Policy Coverages DML operations
     */
    private void processPolicyCoverages() {
        try {
            if (!this.manager.indexToParentCovToInsert.isEmpty() && !this.manager.indexToChildCovToInsert.isEmpty()) {
                List<InsurancePolicyCoverage> medicalPolicyCoverage = new List<InsurancePolicyCoverage>();
                //List<InsurancePolicyCoverage> ancillaryPolicyCoverages = new List<InsurancePolicyCoverage>();
                for (String key : this.manager.indexToParentCovToInsert.keySet()) {
                    InsurancePolicyCoverage polCov = this.manager.indexToParentCovToInsert.get(key);
                    polCov.InsurancePolicyId = this.manager.policy.Id;     
                    medicalPolicyCoverage.add(polCov);  
                    /* else {
                        ancillaryPolicyCoverages.add(polCov);
                    } */
                }

                List<Database.UpsertResult> resultMedical = Database.upsert(medicalPolicyCoverage, true);
                for (Database.UpsertResult result : resultMedical) {
                    if (result.isSuccess()) {
                        System.debug('Medical Policy Coverage created successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting medical policy coverage: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert medical policy coverage: ' + result.getErrors());
                    }
                }

                /*
                if (!ancillaryPolicyCoverages.isEmpty()) {
                    for (InsurancePolicyCoverage ancillaryPolCov : ancillaryPolicyCoverages) {
                        ancillaryPolCov.ARC_MedicalPolicyCoverage__c = medicalPolicyCoverage.Id;
                    }
    
                    Database.UpsertResult[] resultsAncillarys = Database.upsert(ancillaryPolicyCoverages, true);
                    for (Database.UpsertResult result : resultsAncillarys) {
                        if (result.isSuccess()) {
                            System.debug('Ancillary Policy Coverages created successfully: ' + result.getId());
                        } else {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error upserting ancillary policy coverage: ' + error.getMessage());
                            }
                            throw new DmlException('Failed to upsert ancillary policy coverage: ' + result.getErrors());
                        }
                    }
                }
                */
                
                List<InsurancePolicyCoverage> childPolicyCoverages = new List<InsurancePolicyCoverage>();
                for (String key : this.manager.indexToChildCovToInsert.keySet()) {
                    List<InsurancePolicyCoverage> polCovList = this.manager.indexToChildCovToInsert.get(key);
                    InsurancePolicyCoverage parentPolCov = this.manager.indexToParentCovToInsert.get(key);
                    for (InsurancePolicyCoverage polCov : polCovList) {
                        polCov.InsurancePolicyId = this.manager.policy.Id;
                        polCov.ARC_ParentPolicyCoverage__c = parentPolCov.Id;
                    }
                    childPolicyCoverages.addAll(polCovList);
                }

                Database.UpsertResult[] resultsChild = Database.upsert(childPolicyCoverages, true);
                for (Database.UpsertResult result : resultsChild) {
                    if (result.isSuccess()) {
                        System.debug('Child Policy Coverages created successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting child policy coverage: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert child policy coverage: ' + result.getErrors());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in processPolicyCoverages: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Processes Coverage Participants DML operations
     */
    private void processCoverageParticipants() {
        try {
            if (!this.manager.indexToParentCovToInsert.isEmpty() && !this.manager.indexToMemberIds.isEmpty()) {
                List<ARC_CoverageParticipant__c> coverageParticipantsToInsert = new List<ARC_CoverageParticipant__c> ();
                for (String key : this.manager.indexToParentCovToInsert.keySet()) {
                    String primaryCoverageMemberId = getPrimaryCoverageMemberId(this.manager.indexToMemberIds.get(key));
                    for (String memberId : this.manager.indexToMemberIds.get(key)) {
                        ARC_CoverageParticipant__c covPart = new ARC_CoverageParticipant__c();
                        covPart.ARC_PolicyParticipant__c = this.manager.memberIdToPolicyParticipant.get(memberId).Id;
                        covPart.ARC_PolicyCoverage__c = this.manager.indexToParentCovToInsert.get(key).Id;
                        covPart.ARC_Policy__c = this.manager.policy.Id;
                        covPart.ARC_CoverageRole__c = getCoverageRole(memberId, primaryCoverageMemberId);

                        if (this.manager.memberIdToBeneficiaries.containsKey(memberId)) {
                            Map<String, Object> beneficiaries = (Map<String, Object>)this.manager.memberIdToBeneficiaries.get(memberId);
                            Map<String, Object> primaryBeneficiary = beneficiaries.containsKey('primaryBeneficiary') ? (Map<String, Object>)beneficiaries.get('primaryBeneficiary') : null;
                            Map<String, Object> secondaryBeneficiary = beneficiaries.containsKey('secondaryBeneficiary') ? (Map<String, Object>)beneficiaries.get('secondaryBeneficiary') : null;

                            if (primaryBeneficiary != null) {
                                String birthdateStr = (String)primaryBeneficiary.get('birthdate');
                                covPart.ARC_PrimaryBeneficiaryName__c = primaryBeneficiary.containsKey('firstName') && primaryBeneficiary.containsKey('lastName') ? (String) primaryBeneficiary.get('firstName') + ' ' + (String) primaryBeneficiary.get('lastName') : primaryBeneficiary.containsKey('fullname') && primaryBeneficiary.get('fullname') != null ? (String)primaryBeneficiary.get('fullname') : null;
                                covPart.ARC_PrimaryBeneficiaryRelationship__c = primaryBeneficiary.containsKey('relationship') ? (String) primaryBeneficiary.get('relationship') : null;
                                covPart.ARC_PrimaryBeneficiaryOther__c = primaryBeneficiary.containsKey('otherRelationship') ? (String) primaryBeneficiary.get('otherRelationship') : null;
                                covPart.ARC_PrimaryBeneficiaryBirthdate__c = String.isNotBlank(birthdateStr) ? Date.valueOf(birthdateStr) : null;
                                covPart.ARC_PrimaryBeneficiaryPhone__c = primaryBeneficiary.containsKey('phone') ? String.valueOf(primaryBeneficiary.get('phone')) : null;
                            }

                            if (secondaryBeneficiary != null) {
                                String birthdateStr = (String)secondaryBeneficiary.get('birthdate');
                                covPart.ARC_SecondaryBeneficiaryName__c = secondaryBeneficiary.containsKey('firstName') && secondaryBeneficiary.containsKey('lastName') ? (String) secondaryBeneficiary.get('firstName') + ' ' + (String) secondaryBeneficiary.get('lastName') : secondaryBeneficiary.containsKey('fullname') && secondaryBeneficiary.get('fullname') != null ? (String)secondaryBeneficiary.get('fullname') : null;
                                covPart.ARC_SecondaryBeneficiaryRelationship__c = secondaryBeneficiary.containsKey('relationship') ? (String) secondaryBeneficiary.get('relationship') : null;
                                covPart.ARC_SecondaryBeneficiaryOther__c = secondaryBeneficiary.containsKey('otherRelationship') ? (String) secondaryBeneficiary.get('otherRelationship') : null;
                                covPart.ARC_SecondaryBeneficiaryBirthdate__c = String.isNotBlank(birthdateStr) ? Date.valueOf(birthdateStr) : null;
                                covPart.ARC_SecondaryBeneficiaryPhone__c = secondaryBeneficiary.containsKey('phone') ? String.valueOf(secondaryBeneficiary.get('phone')) : null;
                            }
                        }

                        coverageParticipantsToInsert.add(covPart);
                    }
                }
                Database.UpsertResult[] results = Database.upsert(coverageParticipantsToInsert, true);

                for (Database.UpsertResult result : results) {
                    if (result.isSuccess()) {
                        System.debug('Coverage Participant created successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting coverage participants: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert coverage participants: ' + result.getErrors());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in processCoverageParticipants: ' + e.getMessage());
            throw e;
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

    /**
     * @Description: Processes WP for the created Policy Participants
     */
    private void processWaitingPeriods() {
        try {
            ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{this.manager.policy.Id}, null);
        } catch (Exception e) {
            System.debug('Error in processWaitingPeriods: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Processes ARC External Insurance Policy Member DML operations
     */
    private void processExternalInsurancePolicy() {
        try {
            System.debug('Processing ARC External Insurance Policy DML');

            if (!this.manager.externalPoliciesToInsert.isEmpty()) {
                List<Database.UpsertResult> resultsUpdate = Database.upsert(this.manager.externalPoliciesToInsert.values(), true);
                for (Database.UpsertResult result : resultsUpdate) {
                    if (result.isSuccess()) {
                        System.debug('External Insurance Policy created/updated successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting external insurance policy: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert external insurance policy: ' + result.getErrors());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in processExternalInsurancePolicy: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Processes ARC External Insurance Policy Member DML operations
     */
    private void processExternalInsurancePolicyMember() {
        try {
            System.debug('Processing ARC External Insurance Policy Member DML');

            if (!this.manager.policyKeyToMemberIds.isEmpty()) {
                for (String policyKey : manager.policyKeyToMemberIds.keySet()) {
                    for (String memberId : manager.policyKeyToMemberIds.get(policyKey)) {
                        ARC_ExternalInsurancePolicyMember__c externalPolicyMember = new ARC_ExternalInsurancePolicyMember__c ();
                        externalPolicyMember.ARC_ExternalInsurancePolicy__c = manager.externalPoliciesToInsert.get(policyKey).Id;
                        externalPolicyMember.ARC_PersonAccount__c = manager.memberIdToAccountMap.get(memberId).Id;
                        externalPolicyMember.ARC_CensusMember__c = manager.memberIdToCensusMemberMap.get(memberId).Id;
                       
                        this.manager.externalPolicyMembersToInsert.add(externalPolicyMember);
                        System.debug('Ext Policy Member of ' + memberId + ': ' + externalPolicyMember);
                    }
                }
                if (!this.manager.externalPolicyMembersToInsert.isEmpty() && this.manager.externalPolicyMembersToInsert.size() > 0) {
                    List<Database.UpsertResult> resultsUpdate = Database.upsert(this.manager.externalPolicyMembersToInsert, true);
                    for (Database.UpsertResult result : resultsUpdate) {
                        if (result.isSuccess()) {
                            System.debug('External Insurance Policy Member created/updated successfully: ' + result.getId());
                        } else {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error upserting external insurance policy member: ' + error.getMessage());
                            }
                            throw new DmlException('Failed to upsert external insurance policy member: ' + result.getErrors());
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in processExternalInsurancePolicyMember: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Processes Group Account DML operations
     */
    private void processGuardianAccount() {
        try {
            System.debug('Processing Guardian Account DML');

            Account guardian = this.manager.guardianToInsert;            
            if (guardian != null) {
                Database.UpsertResult result = Database.upsert(guardian, true);
                if (result.isSuccess()) {
                    manager.guardianInserted = result.getId();
                    System.debug('Guardian Account created/updated successfully: ' + this.manager.guardianInserted);
                } else {
                    for (Database.Error error : result.getErrors()) {
                    System.debug('Error upserting guardian account: ' + error.getMessage());
                    }
                throw new DmlException('Failed to upsert guardian account: ' + result.getErrors());
                }
            }
        } catch (Exception e) {
            System.debug('Error in processGuardianAccount: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Processes HIPAA DML operations
     */
    private void processHIPAA() {
        try {
            System.debug('Processing HIPAA DML');
            List<ARC_HipaaAuthorization__c> listOfHipaaToInsert = new List<ARC_HipaaAuthorization__c>();

            // ---------------------------------------------------------
            // hipaaCensusMember
            // ---------------------------------------------------------
            if (!this.manager.hipaaCensusMember.isEmpty()) {
                for (String key : this.manager.hipaaCensusMember.keySet()) {
                    ARC_HipaaAuthorization__c hipaa = this.manager.hipaaCensusMember.get(key);
                    hipaa.ARC_AuthorizedMember__c = this.manager.memberIdToCensusMemberMap.get(key).Id;
                  //  hipaa.ARC_PrimaryAccount__c = primaryAccountId;
                    listOfHipaaToInsert.add(hipaa);
                }
            }

            // ---------------------------------------------------------
            // hipaaThirdParty
            // ---------------------------------------------------------
            if (!this.manager.hipaaThirdParty.isEmpty()) {
                for (String contactKey : this.manager.hipaaExternalContact.keySet()) {
                    Contact newContact = this.manager.hipaaExternalContact.get(contactKey);
                }

                // ---------------------------------------------------------
                // Contacts for Third Party Hipaa
                // ---------------------------------------------------------
                List<Database.UpsertResult> resultsContact = Database.upsert(this.manager.hipaaExternalContact.values(), true);
                for (Database.UpsertResult result : resultsContact) {
                    if (result.isSuccess()) {
                        System.debug('HIPAA Contact created/updated successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting HIPAA Contact: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert HIPAA Contact: ' + result.getErrors());
                    }
                }

                for (String key : this.manager.hipaaThirdParty.keySet()) {
                    ARC_HipaaAuthorization__c hipaa = this.manager.hipaaThirdParty.get(key);
                    hipaa.ARC_ExternalPersonAuthorized__c = this.manager.hipaaExternalContact.get(key).Id;
                    listOfHipaaToInsert.add(hipaa);
                }
            }

            // ---------------------------------------------------------
            // hipaaLegalGuardian
            // ---------------------------------------------------------
            if (!this.manager.hipaaLegalGuardian.isEmpty()) {
                Account guardian = [SELECT PersonContactId FROM Account WHERE Id =: this.manager.guardianToInsert.Id LIMIT 1];
                Id personContactId = guardian.PersonContactId;

                for (String key : this.manager.hipaaLegalGuardian.keySet()) {
                    ARC_HipaaAuthorization__c hipaa = this.manager.hipaaLegalGuardian.get(key);
                    hipaa.ARC_ExternalPersonAuthorized__c = personContactId;
                    listOfHipaaToInsert.add(hipaa);
                }
            }

            // ---------------------------------------------------------
            // Insert the HIPAA records
            // ---------------------------------------------------------
            if (!listOfHipaaToInsert.isEmpty()) {
                List<Database.UpsertResult> results = Database.upsert(listOfHipaaToInsert, true);
                for (Database.UpsertResult result : results) {
                    if (result.isSuccess()) {
                        System.debug('HIPAA created/updated successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting HIPAA records: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert HIPAA records: ' + result.getErrors());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in processHIPAA: ' + e.getMessage());
            throw e;
        }
    }


    ///////////////////////
    // Auxiliary Methods //
    ///////////////////////
    
    /**
     * @Description: Updates census member records with contact IDs.
     * This method:
     * 1. Links census members to contacts
     * 2. Updates member information
     * 3. Maintains record relationships
     * 4. Ensures data consistency
     * 
     * @throws Exception If member casesUWToInsert fails
     */
    private void updateRelatedCensusMembers() {
        try {
            if (!this.manager.memberIdToCensusMemberMap.isEmpty()) {
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
                    if (result.isSuccess()) {
                        System.debug('Census member created successfully: ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting census: ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert census: ' + result.getErrors());
                    }
                }
            }

        } catch (Exception e) {
            System.debug('Error in updateRelatedCensusMembers: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    private String getPrimaryMemberId() {
        List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
        for (Object memberInfo_obj : members) {
            Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
            if ((String)memberInfo.get('role') == 'Primary') {
                return (String)memberInfo.get('memberExternalId');
            }
        }
        return null;
    }
        
}