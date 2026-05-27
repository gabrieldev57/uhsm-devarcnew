global without sharing class ARC_SGQLEMapper {
    public ARC_SGQLEManager manager;
    public Map<String, Object> enrollmentInfo;
    private List<String> actionsToExecute = new List<String>();
 
    public void mapEnrollmentData(ARC_SGQLEManager manager) {
        try {
            this.manager = manager;
            this.enrollmentInfo = manager.enrollmentInfo;
 
            mapExistingRecords();
 
            // Distinguishable mappings, according Reinstatement, Disenrollment or none
            Boolean cond1 = this.manager.qleType.contains('Medicare/Medicaid') || this.manager.qleType.contains('Medicaid or CHIP Subsidy') || this.manager.qleType.contains('Other Coverage');
            Boolean cond2 = this.manager.qleType.contains('Military Leave') || this.manager.qleType.contains('Family and Medical Leave (FMLA)');
           
            Boolean isReinstatement = ((cond1) && this.manager.qleSubType.contains('Lose Eligibility')) || ((cond2) && this.manager.qleSubType.contains('Return')) || this.manager.qleType.contains('Court Order');
            Boolean isDisenrollment = ((cond1) && this.manager.qleSubType.contains('Gain Eligibility')) || ((cond2) && this.manager.qleSubType.contains('Leave')) || this.manager.qleType.contains('Death of Employee') || this.manager.qleType.contains('Termination');
 
            // Check for terminated policy to determine Reinstatement vs NewEnrollment
            Boolean hasTerminatedPolicy = checkForTerminatedPolicy();
            Boolean isNewEnrollment = isReinstatement && !hasTerminatedPolicy;

            if (isNewEnrollment) {
                manager.ActionsSelected.add('isNewEnrollment'); 
                actionsToExecute.add('mapNewEnrollment');
            }
            else if (isReinstatement) {
                manager.ActionsSelected.add('isReinstatement');
                actionsToExecute.add('mapPolicy_Reinstatement');
            }
            else if (isDisenrollment) {
                manager.ActionsSelected.add('isDisenrollment');
                actionsToExecute.add('mapPolicy_Disenrollment');
            }
            else {
                actionsToExecute.add('mapCensusMembers');
                actionsToExecute.add('mapPersonAccounts');
                actionsToExecute.add('mapGuardian');
                actionsToExecute.add('mapHIPAA');  
                actionsToExecute.add('mapPolicy');
                actionsToExecute.add('mapPolicyParticipants');
                actionsToExecute.add('mapPolicyCoverages');  
            }
            executeActions(actionsToExecute);
        } catch (Exception e) {
            System.debug('Error in mapEnrollmentData (QLE): ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
 
    /**
     * @Description: Executes the specified actions in sequence
     * @param actionsToExecute: Set of actions to execute
     */
    private void executeActions(List<String> actionsToExecute){
        for(String action : actionsToExecute){
            try {
                switch on action {
                    when 'mapCensusMembers' {
                        mapCensusMembers();
                    }
                    when 'mapPersonAccounts' {
                        mapPersonAccounts();
                    }
                    when 'mapPolicy_Reinstatement' {
                        mapPolicy_Reinstatement();
                    }
                    when 'mapPolicy_Disenrollment' {
                        mapPolicy_Disenrollment();
                    }
                    when 'mapNewEnrollment' {
                        mapNewEnrollment();
                    }
                    when 'mapPolicy' {
                        mapPolicy();
                    }
                    when 'mapPolicyParticipants' {
                        mapPolicyParticipants();
                    }
                    when 'mapPolicyCoverages' {
                        mapPolicyCoverages();
                    }
                    when 'mapGuardian' {
                        mapGuardian();
                    }
                    when 'mapHIPAA' {
                        mapHIPAA();
                    }
                }
            } catch (Exception e) {
               throw e;
            }
        }
    }
 
    private void mapExistingRecords() {
        Map<String, Object> generalInformation = this.enrollmentInfo.containsKey('generalInformation') && this.enrollmentInfo.get('generalInformation') != null ? (Map<String, Object>)this.enrollmentInfo.get('generalInformation') : null;
        Map<String, Object> qle = this.enrollmentInfo.containsKey('qle') && this.enrollmentInfo.get('qle') != null ? (Map<String, Object>)this.enrollmentInfo.get('qle') : null;
       
        if (generalInformation != null) {
            this.manager.censusId = (Id)(generalInformation.containsKey('censusId') ? generalInformation.get('censusId') : null);
            this.manager.groupAccountId = (Id)(generalInformation.containsKey('groupAccountId') ? generalInformation.get('groupAccountId') : null);
            this.manager.accountId = (Id)(generalInformation.containsKey('accountId') ? generalInformation.get('accountId') : null);
            this.manager.contractId = (Id)(generalInformation.containsKey('contractId') ? generalInformation.get('contractId') : null);
            this.manager.primaryCensusMemberId = (Id)(generalInformation.containsKey('primaryCensusMemberId') ? generalInformation.get('primaryCensusMemberId') : null);
            this.manager.qleChanges = generalInformation.containsKey('qleChanges') && generalInformation.get('qleChanges') != null ? (Map<String,Boolean>)generalInformation.get('qleChanges') : null;
 
            if (generalInformation.containsKey('effectiveDate') && generalInformation.get('effectiveDate') != null) {
                this.manager.effectiveDate = Date.valueOf(String.valueOf(generalInformation.get('effectiveDate')));
            }
        }
       
        if (qle != null) {
            this.manager.qleType = qle.containsKey('qleType') && qle.get('qleType') != null ? (String)qle.get('qleType') : null;
            this.manager.qleSubType = qle.containsKey('qleSubtype') && qle.get('qleSubtype') != null ? (String)qle.get('qleSubtype') : null;
        } else {
            // Fallback mode: allow routing from top-level keys when no qle node is present.
            this.manager.qleType = this.enrollmentInfo.containsKey('qleType') && this.enrollmentInfo.get('qleType') != null ? (String)this.enrollmentInfo.get('qleType') : null;
            this.manager.qleSubType = this.enrollmentInfo.containsKey('qleSubtype') && this.enrollmentInfo.get('qleSubtype') != null ? (String)this.enrollmentInfo.get('qleSubtype') : null;
        }
    }

    /**
     * @Description: Check if there is a terminated policy in currentState
     * @return Boolean: true if a terminated policy exists, false otherwise
     */
    private Boolean checkForTerminatedPolicy() {
        try {
            Map<String, Object> currentState = this.enrollmentInfo.containsKey('currentState') && this.enrollmentInfo.get('currentState') != null ? (Map<String, Object>)this.enrollmentInfo.get('currentState') : null;
            Map<String, Object> currentPolicy = currentState != null && currentState.containsKey('currentPolicy') && currentState.get('currentPolicy') != null ? (Map<String, Object>)currentState.get('currentPolicy') : null;

            String policyId = currentPolicy != null && currentPolicy.containsKey('policyId') && currentPolicy.get('policyId') != null ? (String)currentPolicy.get('policyId') : null;

            if (String.isNotBlank(policyId)) {
                List<InsurancePolicy> terminatedPolicies = [
                    SELECT Id
                    FROM InsurancePolicy
                    WHERE Id = :policyId AND Status = 'Terminated'
                    LIMIT 1
                ];
                return !terminatedPolicies.isEmpty();
            }
            return false;
        } catch (Exception e) {
            System.debug('Error in checkForTerminatedPolicy (QLE): ' + e.getMessage());
            return false;
        }
    }

    /**
     * @Description: New enrollment flow - placeholder for now
     */
    private void mapNewEnrollment() {
        try {
            if (this.manager == null || this.manager.accountId == null) {
                System.debug('mapNewEnrollment (QLE): accountId is not available, enrollment link email was not sent.');
                return;
            }

            Account personAccount = [
                SELECT Id, PersonEmail
                FROM Account
                WHERE Id = :this.manager.accountId
                LIMIT 1
            ];

            if (String.isBlank(personAccount.PersonEmail)) {
                System.debug('mapNewEnrollment (QLE): PersonEmail is blank for account ' + personAccount.Id + ', enrollment link email was not sent.');
                return;
            }

            ARC_SendEnrollmentLink360Controller.sendEmail(new List<Id>{ personAccount.Id });
            System.debug('mapNewEnrollment (QLE): enrollment link email send requested for account ' + personAccount.Id + '.');
        } catch (Exception e) {
            System.debug('Error in mapNewEnrollment (QLE): ' + e.getMessage());
            throw e;
        }
    }
 
    private void mapCensusMembers() {
        try {
            Map<String, Object> primaryMemberInfo = getPrimaryMemberInfo();
            List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
            String primaryMemberIdentifier;
 
            for (Object memberInfo_obj : members) {
                Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
                Map<String, Object> person = memberInfo != null ? (Map<String, Object>)memberInfo.get('person') : null;
                String memberAction = memberInfo.containsKey('action') && memberInfo.get('action') != null ? (String)memberInfo.get('action')  : null;
 
                vlocity_ins__GroupCensusMember__c member = new vlocity_ins__GroupCensusMember__c();
               
                member.ARC_ActiveMember__c = true;
                member.vlocity_ins__FirstName__c = person.containsKey('firstName') ? (String)person.get('firstName') : null;
                member.ARC_MiddleInitial__c = person.containsKey('middleInitial') ? (String)person.get('middleInitial') : null;
                member.vlocity_ins__LastName__c = person.containsKey('lastName') ? (String)person.get('lastName') : null;
                member.vlocity_ins__Email__c = person.containsKey('email') ? (String)person.get('email') : null;
                member.ARC_Phone__c = person.containsKey('phone') ? (String)person.get('phone') : null;
                member.vlocity_ins__Birthdate__c = person.containsKey('dob') ? Date.valueOf((String)person.get('dob')) : null;
                member.vlocity_ins__Gender__c = person.containsKey('gender') ? (String)person.get('gender') : null;
                member.vlocity_ins__SocialSecurityNumber__c = person.containsKey('ssn') ? (String)person.get('ssn') : null;
 
                Map<String, Object> address;
                if (String.valueOf(memberInfo.get('role')) != 'Primary' && ARC_IndividualEnrollmentHelper.convertToBoolean(person.get('sameAddressAsPrimary')) == true) {
                    address = primaryMemberInfo != null ? (Map<String, Object>)primaryMemberInfo.get('address') : null;
                } else {
                    address = (Map<String, Object>)person.get('address');
                }
                if (address != null) {
                    member.ARC_PhysicalAddressStreet__c = address.containsKey('street') ? (String)address.get('street') : null;
                    member.ARC_PhysicalAddressCity__c = address.containsKey('city') ? (String)address.get('city') : null;
                    member.ARC_PhysicalAddressState__c = address.containsKey('state') ? String.valueOf(address.get('state')).toUpperCase() : null;
                    member.ARC_PhysicalAddressZipCode__c = address.containsKey('zip') ? (String)address.get('zip') : null;
                    member.ARC_UseParentAddress__c = address.containsKey('sameAddressAsPrimary') ? ARC_IndividualEnrollmentHelper.convertToBoolean(address.get('sameAddressAsPrimary')) : false;
                }
 
                member.ARC_HeightFeet__c = person.containsKey('heightFeet') ? String.valueOf(person.get('heightFeet')) : null;
                member.ARC_HeightInches__c = person.containsKey('heightInches') ? String.valueOf(person.get('heightInches')) : null;
                member.ARC_Weight__c = person.containsKey('weightLbs') ? String.valueOf(person.get('weightLbs')) : null;
                member.ARC_Smoker__c = person.containsKey('smoker') ? ARC_IndividualEnrollmentHelper.convertToBoolean(person.get('smoker')) : null;
                member.ARC_isPregnant__c = person.containsKey('pregnant') ? ARC_IndividualEnrollmentHelper.convertToBoolean(person.get('pregnant')) : null;
 
                member.vlocity_ins__CensusId__c = this.manager.censusId;
                member.vlocity_ins__MemberIdentifier__c = String.valueOf(Datetime.now().getTime()) + '-' + String.valueOf(Math.random());
 
                if (String.valueOf(memberInfo.get('role')) == 'Primary') {
                    member.Id = this.manager.primaryCensusMemberId;
                    primaryMemberIdentifier = member.vlocity_ins__MemberIdentifier__c;
                }
                member.vlocity_ins__IsPrimaryMember__c = memberInfo.containsKey('role') ? String.valueOf(memberInfo.get('role')) == 'Primary' : false;
                member.ARC_DependentRelationship__c = memberInfo.containsKey('role') ? (String.valueOf(memberInfo.get('role')) != 'Primary' ? (String)memberInfo.get('role') : null) : null;
                member.vlocity_ins__IsSpouse__c = memberInfo.containsKey('role') ? String.valueOf(memberInfo.get('role')) == 'Spouse' : false;
                String memberKey = null;
                if (memberAction != null && memberAction != 'Add member' && memberInfo.containsKey('memberId') && memberInfo.get('memberId') != null) {
                    memberKey = (String)memberInfo.get('memberId');
                } else if (memberAction != null && memberAction == 'Add member' && memberInfo.containsKey('memberExternalId') && memberInfo.get('memberExternalId') != null) {
                    memberKey = (String)memberInfo.get('memberExternalId');
                }
                if (memberKey != null) {
                    this.manager.memberIdToFamilyRole.put(memberKey, memberInfo.containsKey('role') ? (String)memberInfo.get('role') : null);
                    this.manager.memberIdToBirthdate.put(memberKey, member.vlocity_ins__Birthdate__c);
                }
       
 
                if (member.vlocity_ins__Birthdate__c != null) {
                    member.ARC_AgeAtEnrollment__c = calculateAge(member.vlocity_ins__Birthdate__c);
                }
 
                if (memberAction != null && memberAction != 'Add member' && memberInfo.containsKey('memberId') && memberInfo.get('memberId') != null) {
                    member.Id = (String)memberInfo.get('memberId');
                    this.manager.memberIdToCensusMemberMap.put(member.Id, member);
                }
                else if (memberAction != null && memberAction == 'Add member' && memberInfo.containsKey('memberExternalId') && memberInfo.get('memberExternalId') != null) {
                    String memberExtId = (String)memberInfo.get('memberExternalId');
                    this.manager.memberIdToCensusMemberMap.put((String)memberInfo.get('memberExternalId'), member);
                }
            }
 
            for (vlocity_ins__GroupCensusMember__c member : this.manager.memberIdToCensusMemberMap.values()) {
                if (!member.vlocity_ins__IsPrimaryMember__c) {
                    member.vlocity_ins__PrimaryMemberIdentifier__c = primaryMemberIdentifier;
                }
            }
        } catch (Exception e) {
            System.debug('Error in mapCensusMembers (QLE | Upsert Member): ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }         
    }
 
    private void mapPersonAccounts() {
        try {
            if (this.enrollmentInfo.containsKey('members') && this.enrollmentInfo.get('members') != null) {
                Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_SGPersonAccount').getRecordTypeId();
 
                List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
                for (Object memberInfo_obj : members) {
                    Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
                    Map<String, Object> person = (Map<String, Object>)memberInfo.get('person');
                    String memberAction = memberInfo.containsKey('action') && memberInfo.get('action') != null ? (String)memberInfo.get('action') : null;
 
                    Account account = new Account();
 
                    if (memberInfo.containsKey('role') && memberInfo.get('role') != null && String.valueOf(memberInfo.get('role')) != 'Primary') {
                        account.RecordTypeId = recordTypeId;
                        account.FirstName = person.containsKey('firstName') ? (String)person.get('firstName') : null;
                        account.LastName = person.containsKey('lastName') ? (String)person.get('lastName') : null;
                        account.ARC_Census__c = this.manager.censusId;
                        account.ARC_PrimaryMemberAccount__c = this.manager.accountId;
                        account.ARC_GroupAccount__c = this.manager.accountId;
                    } else if (memberInfo.containsKey('role') && memberInfo.get('role') != null && String.valueOf(memberInfo.get('role')) == 'Primary') {
                        account.Id = this.manager.accountId;
                    }
 
                    if (memberAction != null && memberAction != 'Add member' && memberInfo.containsKey('memberId') && memberInfo.get('memberId') != null && memberInfo.containsKey('paId') && memberInfo.get('paId') != null) {
                        account.Id = (String)memberInfo.get('paId');
                        this.manager.memberIdToAccountMap.put((String)memberInfo.get('memberId'), account);
                    }
                    else if (memberAction != null && memberAction == 'Add member' && memberInfo.containsKey('memberExternalId') && memberInfo.get('memberExternalId') != null) {
                        String memberExtId = (String)memberInfo.get('memberExternalId');
                        this.manager.memberIdToAccountMap.put(memberExtId, account);
                    }  
                }
            }
        } catch (Exception e) {
            System.debug('Error in mapPersonAccounts (QLE | Upsert): ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
 
    private void mapGuardian() {
        try {
            Map<String,Object> generalInfo = this.enrollmentInfo.containsKey('generalInformation') && this.enrollmentInfo.get('generalInformation') != null ? (Map<String,Object>)this.enrollmentInfo.get('generalInformation') : null;
            if (generalInfo == null) return;
 
            if (generalInfo.containsKey('guardian') && generalInfo.get('guardian') != null && ((Map<String,Object>)generalInfo.get('guardian')).get('firstName') != null && ((Map<String,Object>)generalInfo.get('guardian')).get('firstName') != '') {
                Map<String,Object> guardianInfo = (Map<String,Object>)generalInfo.get('guardian');
 
                Account guardianAccount = new Account();
                Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_Guardian').getRecordTypeId();
 
                guardianAccount.RecordTypeId = recordTypeId;
                guardianAccount.ARC_Guardian__c = true;
                guardianAccount.ARC_GuardianRelationshipToChild__c = guardianInfo.containsKey('relationship') && guardianInfo.get('relationship') != null ? (String)guardianInfo.get('relationship') : null;
                guardianAccount.FirstName = guardianInfo.containsKey('firstName') && guardianInfo.get('firstName') != null ? (String)guardianInfo.get('firstName') : null;
                guardianAccount.LastName = guardianInfo.containsKey('lastName') && guardianInfo.get('lastName') != null ? (String)guardianInfo.get('lastName') : null;
                guardianAccount.vlocity_ins__MiddleName__pc = guardianInfo.containsKey('middleInitial') && guardianInfo.get('middleInitial') != null ? (String)guardianInfo.get('middleInitial') : null;
                guardianAccount.Phone = guardianInfo.containsKey('phone') && guardianInfo.get('phone') != null ? (String)guardianInfo.get('phone') : null;
                guardianAccount.PersonEmail = guardianInfo.containsKey('email') && guardianInfo.get('email') != null ? (String)guardianInfo.get('email') : null;
                guardianAccount.vlocity_ins__Email__c = guardianInfo.containsKey('email') && guardianInfo.get('email') != null ? (String)guardianInfo.get('email') : null;
                guardianAccount.PersonGender = guardianInfo.containsKey('gender') && guardianInfo.get('gender') != null ? (String)guardianInfo.get('gender') : null;
                guardianAccount.PersonBirthdate = guardianInfo.containsKey('dob') && guardianInfo.get('dob') != null ? Date.valueOf((String)guardianInfo.get('dob')) : null;
                guardianAccount.ARC_SocialSecurityNumber__c = guardianInfo.containsKey('ssn') && guardianInfo.get('ssn') != null ? (String)guardianInfo.get('ssn') : null;
                guardianAccount.vlocity_ins__SocialSecurityNumber__pc = guardianInfo.containsKey('ssn') && guardianInfo.get('ssn') != null ? (String)guardianInfo.get('ssn') : null;
                guardianAccount.ARC_GroupAccount__c = this.manager.groupAccountId;
                guardianAccount.ARC_PrimaryMemberAccount__c = this.manager.accountId;
 
                if (guardianInfo.containsKey('address') && guardianInfo.get('address') != null) {
                    Map<String,Object> guardianAddress = (Map<String,Object>)guardianInfo.get('address');
                    guardianAccount.BillingStreet = guardianAddress.containsKey('street') && guardianAddress.get('street') != null ? (String)guardianAddress.get('street') : null;
                    guardianAccount.BillingCity = guardianAddress.containsKey('city') && guardianAddress.get('city') != null ? (String)guardianAddress.get('city') : null;
                    guardianAccount.BillingState = guardianAddress.containsKey('state') && guardianAddress.get('state') != null ? (String)guardianAddress.get('state') : null;
                    guardianAccount.BillingPostalCode = guardianAddress.containsKey('zip') && guardianAddress.get('zip') != null ? (String)guardianAddress.get('zip') : null;
                    guardianAccount.BillingCountry = 'United States';
                }
 
                manager.guardianToInsert = guardianAccount;
            }
        } catch (Exception e) {
            System.debug('Error in mapGuardian (QLE): ' + e.getMessage());
            throw e;
        }
    }
 
    private void mapHIPAA() {
        try {
            Map<String, Object> generalInformation = this.enrollmentInfo.containsKey('generalInformation') && this.enrollmentInfo.get('generalInformation') != null
                ? (Map<String, Object>)this.enrollmentInfo.get('generalInformation')
                : null;
            if (generalInformation == null || !generalInformation.containsKey('hipaa') || generalInformation.get('hipaa') == null) {
                return;
            }
 
            List<Object> hipaaList = (List<Object>)generalInformation.get('hipaa');
            if (hipaaList == null) return;
 
            ARC_HipaaAuthorization__c newHipaa;
            Integer index = 0;
 
            for (Object hipaaObj : hipaaList) {
                Map<String, Object> hipaaTemp = (Map<String, Object>)hipaaObj;
                index += 1;
                String temporaryMemberId = 'TMP-0000' + index;
 
                if (hipaaTemp != null && ARC_IndividualEnrollmentHelper.convertToBoolean(hipaaTemp.get('CHK_Authorized')) == true) {
                    newHipaa = new ARC_HipaaAuthorization__c();
                    newHipaa.Name = String.valueOf(hipaaTemp.get('firstName')) + ' ' + String.valueOf(hipaaTemp.get('lastName'));
                    newHipaa.ARC_PrimaryAccount__c = this.manager.accountId;
                } else {
                    continue;
                }
 
                if (String.valueOf(hipaaTemp.get('relationship')) == 'Third Party') {
                    Contact externalPersonal = new Contact();
                    Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
 
                    externalPersonal.FirstName = hipaaTemp.containsKey('firstName') ? (String)hipaaTemp.get('firstName') : null;
                    externalPersonal.LastName = hipaaTemp.containsKey('lastName') ? (String)hipaaTemp.get('lastName') : null;
                    externalPersonal.Birthdate = hipaaTemp.containsKey('DAT_DOB') ? Date.valueOf((String)hipaaTemp.get('DAT_DOB')) : null;
                    externalPersonal.Email = hipaaTemp.containsKey('email') ? (String)hipaaTemp.get('email') : null;
                    externalPersonal.Phone = hipaaTemp.containsKey('phone') ? (String)hipaaTemp.get('phone') : null;
                    externalPersonal.RecordTypeId = recordTypeId;
                    externalPersonal.ARC_PrimaryAccount__c = this.manager.accountId;
 
                    Map<String,Object> address = hipaaTemp.containsKey('address') ? (Map<String,Object>)hipaaTemp.get('address') : null;
                    if (address != null) {
                        externalPersonal.MailingCity = address.containsKey('city') ? (String)address.get('city') : null;
                        externalPersonal.MailingCountry = 'US';
                        externalPersonal.MailingState = address.containsKey('state') ? (String)address.get('state') : null;
                        externalPersonal.MailingPostalCode = address.containsKey('zip') ? (String)address.get('zip') : null;
                        externalPersonal.MailingStreet = address.containsKey('street') ? (String)address.get('street') : null;
                    }
 
                    this.manager.hipaaExternalContact.put(temporaryMemberId, externalPersonal);
                    this.manager.hipaaThirdParty.put(temporaryMemberId, newHipaa);
                } else if (generalInformation.containsKey('guardian') && generalInformation.get('guardian') != null &&
                           String.valueOf(((Map<String, Object>)generalInformation.get('guardian')).get('firstName')) == String.valueOf(hipaaTemp.get('firstName')) &&
                           String.valueOf(((Map<String, Object>)generalInformation.get('guardian')).get('lastName')) == String.valueOf(hipaaTemp.get('lastName')) &&
                           String.valueOf(((Map<String, Object>)generalInformation.get('guardian')).get('dob')) == String.valueOf(hipaaTemp.get('dob'))) {
                    this.manager.hipaaLegalGuardian.put(temporaryMemberId, newHipaa);
                } else {
                    if (hipaaTemp.containsKey('memberId') && hipaaTemp.get('memberId') != null) { // Member already exists
                        this.manager.hipaaCensusMember.put((String)hipaaTemp.get('memberId'), newHipaa);
                    }
                    else if (hipaaTemp.containsKey('memberExternalId') && hipaaTemp.get('memberExternalId') != null) { // Member doesn't exist
                        this.manager.hipaaCensusMember.put((String)hipaaTemp.get('memberExternalId'), newHipaa);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in mapHIPAA (QLE): ' + e.getMessage());
            throw e;
        }
    }
 
    private void mapPolicy() {
        try {
            Map<String, Object> generalInformation = (Map<String, Object>)this.enrollmentInfo.get('generalInformation');
            Map<String, Object> medicalMap = generalInformation != null && generalInformation.containsKey('medicalProgram') && generalInformation.get('medicalProgram') != null ? (Map<String, Object>)generalInformation.get('medicalProgram') : null;
            Map<String, Object> currentState = this.enrollmentInfo.containsKey('currentState') && this.enrollmentInfo.get('currentState') != null ? (Map<String, Object>)this.enrollmentInfo.get('currentState') : null;
            Map<String, Object> currentPolicy = currentState != null && currentState.containsKey('currentPolicy') && currentState.get('currentPolicy') != null ? (Map<String, Object>)currentState.get('currentPolicy') : null;
            String priorPolicyId = currentPolicy != null && currentPolicy.containsKey('policyId') && currentPolicy.get('policyId') != null ? (String)currentPolicy.get('policyId') : null;
 
            Map<String, Object> qle = (Map<String, Object>)this.enrollmentInfo.get('qle');
            String qleType =  qle != null && qle.containsKey('qleType') && qle.get('qleType') != null ? (String)qle.get('qleType') : null;
 
            Map<String, Object> primaryMember = getPrimaryMemberInfo();
            Boolean isLegacy = primaryMember != null && primaryMember.containsKey('isLegacy') && primaryMember.get('isLegacy') != null ? (Boolean)primaryMember.get('isLegacy') : null;
 
            Decimal mthcontribEE = 0;
            Decimal mthcontribER = 0;
            Decimal basePriceTotal = 0;
            Decimal individualPrice = 0;
 
            if (medicalMap != null) {
                for (String key : medicalMap.keySet()) {
                    Map<String, Object> medical = (Map<String, Object>)medicalMap.get(key);
                    if (medical == null) continue;
 
                    if (key.contains('Senior') && isLegacy) {
                        individualPrice = (Decimal)medical.get('individualPrice');
                    } else if (!key.contains('Senior') && !isLegacy) {
                        individualPrice = (Decimal)medical.get('individualPrice');
                    }
 
                    if (medical.containsKey('employeeSplit') && medical.get('employeeSplit') != null) {
                        mthcontribEE = mthcontribEE + (Decimal)medical.get('employeeSplit');
                    }
                    if (medical.containsKey('employerSplit') && medical.get('employerSplit') != null) {
                        mthcontribER = mthcontribER + (Decimal)medical.get('employerSplit');
                    }
                    if (medical.containsKey('basePrice') && medical.get('basePrice') != null) {
                        basePriceTotal = basePriceTotal + (Decimal)medical.get('basePrice');
                    }
                }
            }
 
            InsurancePolicy policy = new InsurancePolicy();
            if (primaryMember != null) {
                policy.PolicyName = String.valueOf(primaryMember.get('firstName')) + ' ' + String.valueOf(primaryMember.get('lastName')) + ' - Family';
            }
            policy.Name = 'ShopAndEnroll Policy';
            policy.Status = 'Awaiting Signature';
            policy.ARC_Reason__c = 'New Application';
 
            policy.ARC_QLEReason__c = qleType;
            policy.EmployeeContribution = mthcontribEE;
            policy.EmployerContribution = mthcontribER;
            policy.ARC_IndividualPrice__c = individualPrice;
            policy.ARC_DependentPrice__c = basePriceTotal - individualPrice;
       
            policy.ARC_GroupAccount__c = this.manager.groupAccountId;
            policy.ARC_Contract__c = this.manager.contractId;
            policy.ARC_PolicyEffectiveDate__c = this.manager.effectiveDate;
            
            // QLE: Use currentPolicy.employeeAccountId as the insured (Person Account).
            // Fallback to currentMembers[Primary].paId, then manager.accountId.
            Id employeeAccountIdFromPolicy = null;
            if (currentPolicy != null && currentPolicy.containsKey('employeeAccountId') && currentPolicy.get('employeeAccountId') != null) {
                employeeAccountIdFromPolicy = coerceToId(currentPolicy.get('employeeAccountId'));
                if (!isAccountId(employeeAccountIdFromPolicy)) {
                    employeeAccountIdFromPolicy = null;
                }
            }

            Id primaryPersonAccountId = resolvePrimaryPersonAccountIdFromCurrentState();
            Id nameInsuredId =
                (employeeAccountIdFromPolicy != null)
                    ? employeeAccountIdFromPolicy
                    : ((primaryPersonAccountId != null) ? primaryPersonAccountId : this.manager.accountId);
            policy.ARC_EmployeeAccount__c = nameInsuredId;
            policy.NameInsuredId = nameInsuredId;
            policy.PriorPolicyId = priorPolicyId;
 
            this.manager.policy = policy;
        } catch (Exception e) {
            System.debug('Error in mapPolicy (QLE): ' + e.getMessage());
            throw e;
        }
    }
 
    private void mapPolicyParticipants() {
        try {
            List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
            if (members == null) return;
 
            for (Object memberInfo_obj : members) {
               
                Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
                InsurancePolicyParticipant polPart = new InsurancePolicyParticipant();
                String memberRole = (String)memberInfo.get('role');
                polPart.Role = memberRole == 'Child' ? 'Dependent' : memberRole;
                polPart.ARC_StartDate__c = this.manager.effectiveDate;
                String memberAction = memberInfo.containsKey('action') && memberInfo.get('action') != null ? (String)memberInfo.get('action') : null;
                if (memberAction != null && memberAction != 'Add member' && memberInfo.containsKey('memberId') && memberInfo.get('memberId') != null) {
                    this.manager.memberIdToPolicyParticipant.put((String)memberInfo.get('memberId'), polPart);
                }
                else if (memberAction != null && memberAction == 'Add member' && memberInfo.containsKey('memberExternalId') && memberInfo.get('memberExternalId') != null) {
                    this.manager.memberIdToPolicyParticipant.put((String)memberInfo.get('memberExternalId'), polPart);
                }
            }
        } catch (Exception e) {
            System.debug('Error in mapPolicyParticipants (QLE): ' + e.getMessage());
            throw e;
        }
    }
 
    private void mapPolicyCoverages() {
        System.debug('>>> [MAPPER] enter in mapPolicyCoverages');
        try {
            Map<String, Object> generalInformation = (Map<String, Object>)this.enrollmentInfo.get('generalInformation');
            Map<String, Object> medicalMap = generalInformation != null && generalInformation.containsKey('medicalProgram') && generalInformation.get('medicalProgram') != null
                ? (Map<String, Object>)generalInformation.get('medicalProgram')
                : null;
            List<Object> members = this.enrollmentInfo.containsKey('members') && this.enrollmentInfo.get('members') != null ? (List<Object>)this.enrollmentInfo.get('members') : null;
            Set<Id> parentProductIds = new Set<Id>();
 
            if (medicalMap != null && members != null) {
                Integer aux = 1;
                for (String key : medicalMap.keySet()) {
                    Map<String, Object> medical = (Map<String, Object>)medicalMap.get(key);
                    if (medical == null) continue;
 
                    for (Object memberInfo_obj : members) {
                        Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
                        String memberId = null;
                       
                        Map<String, Object> person = (Map<String, Object>)memberInfo.get('person');
 
                        String memberAction = memberInfo.containsKey('action') && memberInfo.get('action') != null ? (String)memberInfo.get('action') : null;
 
                        if (memberAction != null && memberAction != 'Add member' && memberInfo.containsKey('memberId') && memberInfo.get('memberId') != null) {
                            memberId = (String)memberInfo.get('memberId');
                        }
                        else if (memberAction != null && memberAction == 'Add member' && memberInfo.containsKey('memberExternalId') && memberInfo.get('memberExternalId') != null) {
                            memberId = (String)memberInfo.get('memberExternalId');
                        }
 
                        InsurancePolicyCoverage newIPC = new InsurancePolicyCoverage();
                        newIPC.CoverageName = key;
                        newIPC.vlocity_ins_fsc__Product2Id__c = medical.containsKey('productId') && medical.get('productId') != null ? (Id)medical.get('productId') : null;
                        newIPC.ARC_UnitPrice__c = medical.containsKey('individualPrice') && medical.get('individualPrice') != null ? (Double)medical.get('individualPrice') : null;
                        newIPC.ARC_Reason__c = memberAction;
 
                        parentProductIds.add(newIPC.vlocity_ins_fsc__Product2Id__c);
 
                        Boolean isLegacy = person != null && person.containsKey('isLegacy') && person.get('isLegacy') != null ? (Boolean)person.get('isLegacy') : false;
 
                        if (isLegacy && key.contains('Senior')) {
                            this.manager.indexToParentCovToInsert.put('LegacyMedical' + aux, newIPC);
                            if (!this.manager.indexToMemberIds.containsKey('LegacyMedical' + aux)) {
                                this.manager.indexToMemberIds.put('LegacyMedical' + aux, new List<String>());
                            }
                            if (memberId != null) this.manager.indexToMemberIds.get('LegacyMedical' + aux).add(memberId);
                            aux++;
                        } else if (!isLegacy && !key.contains('Senior')) {
                            this.manager.indexToParentCovToInsert.put('Medical', newIPC);
                            if (!this.manager.indexToMemberIds.containsKey('Medical')) {
                                this.manager.indexToMemberIds.put('Medical', new List<String>());
                            }
                            if (memberId != null) this.manager.indexToMemberIds.get('Medical').add(memberId);
                        }
                    }
                }
            }
 
            if (!parentProductIds.isEmpty()) {
                List<vlocity_ins__ProductChildItem__c> pciList = [
                    SELECT Id, vlocity_ins__ParentProductId__c, vlocity_ins__ChildProductId__r.Id, vlocity_ins__ChildProductId__r.Name
                    FROM vlocity_ins__ProductChildItem__c
                    WHERE vlocity_ins__ParentProductId__c IN :parentProductIds
                    AND vlocity_ins__ChildProductId__r.RecordType.Name = 'Coverage Spec'
                ];
 
                Map<Id, List<Product2>> productIdToChildProduct = new Map<Id, List<Product2>>();
                for (vlocity_ins__ProductChildItem__c pci : pciList) {
                    if (!productIdToChildProduct.containsKey(pci.vlocity_ins__ParentProductId__c)) {
                        productIdToChildProduct.put(pci.vlocity_ins__ParentProductId__c, new List<Product2>());
                    }
                    productIdToChildProduct.get(pci.vlocity_ins__ParentProductId__c).add(pci.vlocity_ins__ChildProductId__r);
                }
 
                for (String covKey : this.manager.indexToParentCovToInsert.keySet()) {
                    InsurancePolicyCoverage parentCov = this.manager.indexToParentCovToInsert.get(covKey);
                    List<Product2> childProducts = productIdToChildProduct.get(parentCov.vlocity_ins_fsc__Product2Id__c);
                    if (childProducts == null) continue;
                    for (Product2 childProduct : childProducts) {
                        InsurancePolicyCoverage childCov = new InsurancePolicyCoverage();
                        childCov.CoverageName = childProduct.Name;
                        childCov.vlocity_ins_fsc__Product2Id__c = childProduct.Id;
                        childCov.ARC_ParentProduct__c = parentCov.vlocity_ins_fsc__Product2Id__c;
                        if (!this.manager.indexToChildCovToInsert.containsKey(covKey)) {
                            this.manager.indexToChildCovToInsert.put(covKey, new List<InsurancePolicyCoverage>());
                        }
                        this.manager.indexToChildCovToInsert.get(covKey).add(childCov);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in mapPolicyCoverages (QLE): ' + e.getMessage());
            throw e;
        }
    }
 
    private void mapPolicy_Reinstatement() {
        try {
            Map<String, Object> currentState = this.enrollmentInfo.containsKey('currentState') && this.enrollmentInfo.get('currentState') != null ? (Map<String, Object>)this.enrollmentInfo.get('currentState') : null;
            Map<String, Object> currentPolicy = currentState != null && currentState.containsKey('currentPolicy') && currentState.get('currentPolicy') != null? (Map<String, Object>)currentState.get('currentPolicy') : null;

            String policyId = currentPolicy != null && currentPolicy.containsKey('policyId') && currentPolicy.get('policyId') != null ? (String)currentPolicy.get('policyId') : null;

            if (String.isNotBlank(policyId)) {
                // Query existing policy and related records
                List<InsurancePolicy> oldPolicies = [
                    SELECT Id, Name, PolicyName, ARC_Guardian__c, ARC_Reason__c, ARC_QLEReason__c, EmployeeContribution,
                        EmployerContribution, ARC_IndividualPrice__c, ARC_DependentPrice__c,
                        ARC_GroupAccount__c, ARC_Contract__c, ARC_PolicyEffectiveDate__c,
                        ARC_EmployeeAccount__c, NameInsuredId,
                        (SELECT Id, Role, ARC_StartDate__c, InsurancePolicyId, PrimaryParticipantContactId FROM InsurancePolicyParticipants),
                        (SELECT Id, CoverageName, vlocity_ins_fsc__Product2Id__c, ARC_UnitPrice__c, ARC_Reason__c, ARC_ParentPolicyCoverage__c FROM InsurancePolicyCoverages),
                        (SELECT Id, ARC_PolicyParticipant__c, ARC_PolicyCoverage__c, ARC_Policy__c FROM CoverageParticipants__r)
                    FROM InsurancePolicy
                    WHERE Id = :policyId AND Status = 'Terminated'
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                if (!oldPolicies.isEmpty()) {
                    InsurancePolicy oldPolicy = oldPolicies[0];

                    Map<String, Object> primaryMember = getPrimaryMemberInfo();

                    // Map Policy fields
                    InsurancePolicy newPolicy = new InsurancePolicy();
                    newPolicy.Name = oldPolicy.Name;
                    newPolicy.PolicyName = oldPolicy.PolicyName;
                    newPolicy.ARC_Guardian__c = oldPolicy.ARC_Guardian__c;
                    newPolicy.ARC_Reason__c = oldPolicy.ARC_Reason__c;
                    newPolicy.ARC_QLEReason__c = oldPolicy.ARC_QLEReason__c;
                    newPolicy.EmployeeContribution = oldPolicy.EmployeeContribution;
                    newPolicy.EmployerContribution = oldPolicy.EmployerContribution;
                    newPolicy.ARC_IndividualPrice__c = oldPolicy.ARC_IndividualPrice__c;
                    newPolicy.ARC_DependentPrice__c = oldPolicy.ARC_DependentPrice__c;
                    newPolicy.ARC_GroupAccount__c = oldPolicy.ARC_GroupAccount__c;
                    newPolicy.ARC_Contract__c = oldPolicy.ARC_Contract__c;
                    newPolicy.ARC_EmployeeAccount__c = oldPolicy.ARC_EmployeeAccount__c;
                    newPolicy.NameInsuredId = oldPolicy.NameInsuredId;
                    newPolicy.Status = 'Awaiting Activation';
                    newPolicy.ARC_PolicyEffectiveDate__c = this.manager.effectiveDate;
                    
                    this.manager.reinstatementPolicy = newPolicy;

                    // Map Participants
                    this.manager.reinstatementParticipants = new Map<Id, InsurancePolicyParticipant>();
                    for (InsurancePolicyParticipant oldPart : oldPolicy.InsurancePolicyParticipants) {
                        InsurancePolicyParticipant newPart = new InsurancePolicyParticipant();
                        newPart.Role = oldPart.Role;
                        newPart.ARC_StartDate__c = oldPart.ARC_StartDate__c;
                        newPart.PrimaryParticipantContactId = oldPart.PrimaryParticipantContactId;
                        
                        this.manager.reinstatementParticipants.put(oldPart.Id, newPart);
                    }

                    // Map Coverages
                    this.manager.reinstatementCoverages = new Map<Id, InsurancePolicyCoverage>();
                    for (InsurancePolicyCoverage oldCov : oldPolicy.InsurancePolicyCoverages) {
                        InsurancePolicyCoverage newCov = new InsurancePolicyCoverage();
                        newCov.CoverageName = oldCov.CoverageName;
                        newCov.vlocity_ins_fsc__Product2Id__c = oldCov.vlocity_ins_fsc__Product2Id__c;
                        newCov.ARC_UnitPrice__c = oldCov.ARC_UnitPrice__c;
                        newCov.ARC_Reason__c = oldCov.ARC_Reason__c;
                        newCov.ARC_ParentPolicyCoverage__c = oldCov.ARC_ParentPolicyCoverage__c; 
                        
                        this.manager.reinstatementCoverages.put(oldCov.Id, newCov);
                    }

                    // Store old junction objects to cross-reference later during DML
                    this.manager.reinstatementCovParts = new List<ARC_CoverageParticipant__c>();
                    for (ARC_CoverageParticipant__c oldCp : oldPolicy.CoverageParticipants__r) {
                        this.manager.reinstatementCovParts.add(oldCp);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in mapPolicy_Reinstatement (QLE): ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    private void mapPolicy_Disenrollment() {
        try {
            List<InsurancePolicy> listPolicy = new List<InsurancePolicy>();

            // Query by Employee Account ID to get both Activated and Awaiting policies
            listPolicy = [
                SELECT Id, Status, ARC_PolicyEffectiveDate__c, ARC_PolicyExpirationDate__c
                FROM InsurancePolicy
                WHERE NameInsuredId = :this.manager.accountId 
                AND (Status = 'Activated' OR Status LIKE 'Awaiting%')
            ];

            if (!listPolicy.isEmpty()) {
                for (InsurancePolicy pol : listPolicy) { 

                    if (pol.Status.contains('Awaiting')) {
                        pol.Status = 'Voided';
                        pol.ARC_PolicyExpirationDate__c = pol.ARC_PolicyEffectiveDate__c;
                    } else {
                        pol.ARC_PolicyExpirationDate__c = this.manager.effectiveDate.addDays(-1);
                    }
                }
                
                this.manager.policiesToDisenroll = listPolicy;
            }
        } catch (Exception e) {
            System.debug('Error in mapPolicy_Disenrollment (QLE): ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    public class ReinstatementResponse {
        @InvocableVariable
        public Boolean isSuccess;
    }

    public class ReinstatementRequest {
        @InvocableVariable(required=true label='Old policy Id')
        public Id oldPolicyId;

        @InvocableVariable(required=true label='Effective Date')
        public Date effectiveDate;
    }

    @InvocableMethod(label='Reinstatement: Clone and Insert Policy' description='Clone the old policy for reinstatement')
    public static List<ReinstatementResponse> mapPolicy_ReinstatementLOA(List<ReinstatementRequest> requests) {
        
        List<ReinstatementResponse> responses = new List<ReinstatementResponse>();

        try {
            Set<Id> idsToQuery = new Set<Id>();
            for(ReinstatementRequest req : requests) idsToQuery.add(req.oldPolicyId);

            Map<Id, InsurancePolicy> oldPoliciesMap = new Map<Id, InsurancePolicy>([
                SELECT Id, Name, PolicyName, ARC_Guardian__c, ARC_Reason__c, ARC_QLEReason__c, EmployeeContribution,
                    EmployerContribution, ARC_IndividualPrice__c, ARC_DependentPrice__c,
                    ARC_GroupAccount__c, ARC_Contract__c, ARC_PolicyEffectiveDate__c,
                    ARC_EmployeeAccount__c, NameInsuredId,
                    (SELECT Id, Role, ARC_StartDate__c, InsurancePolicyId, PrimaryParticipantContactId FROM InsurancePolicyParticipants),
                    (SELECT Id, CoverageName, vlocity_ins_fsc__Product2Id__c, ARC_UnitPrice__c, ARC_Reason__c, ARC_ParentPolicyCoverage__c FROM InsurancePolicyCoverages),
                    (SELECT Id, ARC_PolicyParticipant__c, ARC_PolicyCoverage__c, ARC_Policy__c FROM CoverageParticipants__r)
                FROM InsurancePolicy
                WHERE Id IN :idsToQuery AND Status = 'Activated'
                ORDER BY CreatedDate DESC
            ]);

            List<InsurancePolicy> policiesToInsert = new List<InsurancePolicy>();
            Map<Id, InsurancePolicy> oldIdToNewPolicy = new Map<Id, InsurancePolicy>();

            for (ReinstatementRequest req : requests) {
                InsurancePolicy oldPol = oldPoliciesMap.get(req.oldPolicyId);
                if (oldPol != null) {
                    InsurancePolicy newPol = new InsurancePolicy(
                        Name = oldPol.Name,
                        PolicyName = oldPol.PolicyName,
                        ARC_Guardian__c = oldPol.ARC_Guardian__c,
                        ARC_Reason__c = oldPol.ARC_Reason__c,
                        ARC_QLEReason__c = oldPol.ARC_QLEReason__c,
                        EmployeeContribution = oldPol.EmployeeContribution,
                        EmployerContribution = oldPol.EmployerContribution,
                        ARC_IndividualPrice__c = oldPol.ARC_IndividualPrice__c,
                        ARC_DependentPrice__c = oldPol.ARC_DependentPrice__c,
                        ARC_GroupAccount__c = oldPol.ARC_GroupAccount__c,
                        ARC_Contract__c = oldPol.ARC_Contract__c,
                        ARC_EmployeeAccount__c = oldPol.ARC_EmployeeAccount__c,
                        NameInsuredId = oldPol.NameInsuredId,
                        Status = 'Awaiting Activation',
                        ARC_PolicyEffectiveDate__c = req.effectiveDate
                    );
                    policiesToInsert.add(newPol);
                    oldIdToNewPolicy.put(oldPol.Id, newPol);
                }
            }

            if (!policiesToInsert.isEmpty()) insert policiesToInsert;

            List<InsurancePolicyParticipant> participantsToInsert = new List<InsurancePolicyParticipant>();
            List<InsurancePolicyCoverage> coveragesToInsert = new List<InsurancePolicyCoverage>();
            
            Map<Id, InsurancePolicyParticipant> oldIdToNewPart = new Map<Id, InsurancePolicyParticipant>();
            Map<Id, InsurancePolicyCoverage> oldIdToNewCov = new Map<Id, InsurancePolicyCoverage>();

            for (Id oldId : oldIdToNewPolicy.keySet()) {
                InsurancePolicy oldPol = oldPoliciesMap.get(oldId);
                InsurancePolicy newPol = oldIdToNewPolicy.get(oldId);

                for (InsurancePolicyParticipant oldPart : oldPol.InsurancePolicyParticipants) {
                    InsurancePolicyParticipant newPart = new InsurancePolicyParticipant(
                        InsurancePolicyId = newPol.Id,
                        Role = oldPart.Role,
                        ARC_StartDate__c = oldPart.ARC_StartDate__c,
                        PrimaryParticipantContactId = oldPart.PrimaryParticipantContactId
                    );
                    participantsToInsert.add(newPart);
                    oldIdToNewPart.put(oldPart.Id, newPart);
                }

                for (InsurancePolicyCoverage oldCov : oldPol.InsurancePolicyCoverages) {
                    InsurancePolicyCoverage newCov = new InsurancePolicyCoverage(
                        InsurancePolicyId = newPol.Id,
                        CoverageName = oldCov.CoverageName,
                        vlocity_ins_fsc__Product2Id__c = oldCov.vlocity_ins_fsc__Product2Id__c,
                        ARC_UnitPrice__c = oldCov.ARC_UnitPrice__c,
                        ARC_Reason__c = oldCov.ARC_Reason__c,
                        ARC_ParentPolicyCoverage__c = oldCov.ARC_ParentPolicyCoverage__c
                    );
                    coveragesToInsert.add(newCov);
                    oldIdToNewCov.put(oldCov.Id, newCov);
                }
            }

            if (!participantsToInsert.isEmpty()) insert participantsToInsert;
            if (!coveragesToInsert.isEmpty()) insert coveragesToInsert;

            List<ARC_CoverageParticipant__c> junctionsToInsert = new List<ARC_CoverageParticipant__c>();
            for (Id oldId : oldIdToNewPolicy.keySet()) {
                InsurancePolicy oldPol = oldPoliciesMap.get(oldId);
                InsurancePolicy newPol = oldIdToNewPolicy.get(oldId);

                for (ARC_CoverageParticipant__c oldCp : oldPol.CoverageParticipants__r) {
                    junctionsToInsert.add(new ARC_CoverageParticipant__c(
                        ARC_Policy__c = newPol.Id,
                        ARC_PolicyParticipant__c = oldIdToNewPart.get(oldCp.ARC_PolicyParticipant__c)?.Id,
                        ARC_PolicyCoverage__c = oldIdToNewCov.get(oldCp.ARC_PolicyCoverage__c)?.Id,
                        ARC_CoverageRole__c = oldIdToNewPart.get(oldCp.ARC_PolicyParticipant__c)?.Role
                    ));
                }
            }

            if (!junctionsToInsert.isEmpty()) insert junctionsToInsert;

            for (ReinstatementRequest req : requests) {
                ReinstatementResponse res = new ReinstatementResponse();
                InsurancePolicy oldPol = oldPoliciesMap.get(req.oldPolicyId);

                if (oldPol != null && oldIdToNewPolicy.containsKey(oldPol.Id)) {
                    res.isSuccess = true;
                } else {
                    res.isSuccess = false;
                }
                responses.add(res);
            }
            
        } catch (Exception e) {
            System.debug('Error in mapPolicy_ReinstatementLOA: ' + e.getLineNumber() + ' ' + e.getMessage());
          
            responses.clear(); 
            for (ReinstatementRequest req : requests) {
                ReinstatementResponse res = new ReinstatementResponse();
                res.isSuccess = false;
                responses.add(res);
            }
        }

        return responses;
    }
 
    private Map<String, Object> getPrimaryMemberInfo() {
        List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
        if (members == null) return null;
        for (Object memberInfo_obj : members) {
            Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
            if (String.valueOf(memberInfo.get('role')) == 'Primary') {
                return (Map<String, Object>)memberInfo.get('person');
            }
        }
        return null;
    }
    
    private Id resolvePrimaryPersonAccountIdFromCurrentState() {
        Map<String, Object> currentState =
            this.enrollmentInfo != null && this.enrollmentInfo.containsKey('currentState') && this.enrollmentInfo.get('currentState') != null
                ? (Map<String, Object>) this.enrollmentInfo.get('currentState')
                : null;
        List<Object> currentMembers =
            currentState != null && currentState.containsKey('currentMembers') && currentState.get('currentMembers') != null
                ? (List<Object>) currentState.get('currentMembers')
                : null;
        if (currentMembers == null) return null;
        
        for (Object memberObj : currentMembers) {
            Map<String, Object> member = (Map<String, Object>) memberObj;
            if (member == null) continue;
            if (String.valueOf(member.get('role')) != 'Primary') continue;
            
            Object paIdObj = member.get('paId');
            if (paIdObj != null) {
                Id candidate = coerceToId(paIdObj);
                if (isAccountId(candidate)) return candidate;
            }
            
            // Fallbacks: accept only Account IDs (Person Account) for NameInsuredId.
            // Do NOT fall back to 'memberId' because that's commonly a Census Member Id (a3q...),
            // which will throw FIELD_INTEGRITY_EXCEPTION on InsurancePolicy.NameInsuredId.
            for (String key : new List<String>{ 'accountId', 'personAccountId', 'memberAccountId' }) {
                Object idObj = member.get(key);
                if (idObj == null) continue;
                Id candidate = coerceToId(idObj);
                if (isAccountId(candidate)) return candidate;
            }
            
            return null;
        }
        
        return null;
    }
    
    private static Id coerceToId(Object raw) {
        if (raw == null) return null;
        try { return (Id) raw; } catch (Exception ignore) {}
        try { return (Id) String.valueOf(raw); } catch (Exception ignore2) {}
        return null;
    }
    
    private static Boolean isAccountId(Id candidate) {
        if (candidate == null) return false;
        try {
            return candidate.getSObjectType() == Account.SObjectType;
        } catch (Exception e) {
            return false;
        }
    }
 
    private Integer calculateAge(Date dob) {
        Date today = Date.today();
        Integer age = today.year() - dob.year();
        if (today.month() < dob.month() || (today.month() == dob.month() && today.day() < dob.day())) {
            age--;
        }
        return age;
    }
}