/**
 * @Description: Mapper class for Self Enrollment Flow operations for Small Groups.
 * This class handles the mapping of enrollment data to Salesforce objects.
 * 
 * @Author: Agustin Garay
 * @Date: 2025-10-10
 * @Version: 1.0
 */
global without sharing class ARC_SGSEMapper {
    
    public ARC_SGSEManager manager;
    public Map<String, Object> enrollmentInfo;

    /**
     * @Description: Main method to map enrollment data to Salesforce objects
     * @param enrollmentInfo: Map containing enrollment information
     * @param memberData: Map containing member data
     * @param planData: Map containing plan data
     */
    public void mapEnrollmentData(ARC_SGSEManager manager) {
        try {
            this.manager = manager;
            this.enrollmentInfo = manager.enrollmentInfo;

            // Map already existing records
            mapExistingRecords();
            
            // Check if the member already has a policy associated and delete all asociated records.
            checkPolicy();
            
            // Map each object
            mapCensusMembers();
            mapBeneficiaries();
            mapPersonAccounts();
            mapGuardian();
            mapPolicy();
            mapPolicyParticipants();
            mapPolicyCoverages();
            mapExternalInsurancePolicyMember();
            mapHIPAA();
            
            System.debug('Data mapping completed successfully');
            
        } catch (Exception e) {
            System.debug('Error in mapEnrollmentData: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    /**
     * @Description: Maps already existing records sent in the received JSON: GroupCensus, GroupAccount, Contract, PrimaryMember
     */
    private void mapExistingRecords() {
        Map<String, Object> generalInformation = (Map<String, Object>)this.enrollmentInfo.get('generalInformation');
        this.manager.censusId = generalInformation.containsKey('censusId') ? (String)generalInformation.get('censusId') : null;
        this.manager.groupAccountId = generalInformation.containsKey('groupAccountId') ? (String)generalInformation.get('groupAccountId') : null;
        this.manager.accountId = generalInformation.containsKey('accountId') ? (String)generalInformation.get('accountId') : null;
        this.manager.contractId = generalInformation.containsKey('contractId') ? (String)generalInformation.get('contractId') : null;
        this.manager.primaryCensusMemberId = generalInformation.containsKey('primaryCensusMemberId') ? (String)generalInformation.get('primaryCensusMemberId') : null;
        Date contractEffectiveDate = generalInformation.containsKey('effectiveDate') && generalInformation.get('effectiveDate') != null && String.valueOf(generalInformation.get('effectiveDate')) != ''
            ? Date.valueOf((String)generalInformation.get('effectiveDate'))
            : null;
        this.manager.effectiveDate = getEffectiveDate(contractEffectiveDate);
    }
    
    /**
     * @Description: Maps data to Census object for every family member except of the Primary
     */
    private void mapCensusMembers() {
        try {
            System.debug('Mapping Census data');
            
            Map<String, Object> primaryMemberInfo = getPrimaryMemberInfo();
            List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
            String primaryMemberIdentifier;
            //Id recordTypeId = Schema.SObjectType.vlocity_ins__GroupCensusMember__c.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();

            for (Object memberInfo_obj : members) {
                vlocity_ins__GroupCensusMember__c member = new vlocity_ins__GroupCensusMember__c();
                Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
                Map<String, Object> person = (Map<String, Object>)memberInfo.get('person');

                member.vlocity_ins__FirstName__c = person.containsKey('firstName') ? (String)person.get('firstName') : null;
                member.ARC_MiddleInitial__c = person.containsKey('middleInitial') ? (String)person.get('middleInitial') : null;
                member.vlocity_ins__LastName__c = person.containsKey('lastName') ? (String)person.get('lastName') : null;
                member.vlocity_ins__Email__c = person.containsKey('email') ? (String)person.get('email') : null;
                member.ARC_Phone__c = person.containsKey('phone') ? (String)person.get('phone') : null;
                member.vlocity_ins__Birthdate__c = person.containsKey('dob') ? Date.valueOf((String)person.get('dob')) : null;
                member.vlocity_ins__Gender__c = person.containsKey('gender') ? (String)person.get('gender') : null;
                member.vlocity_ins__SocialSecurityNumber__c = person.containsKey('ssn') ? (String)person.get('ssn') : null;

                Map<String, Object> address;
                if ((String)memberInfo.get('role') != 'Primary' && (Boolean)person.get('sameAddressAsPrimary')) {
                    address = (Map<String, Object>)primaryMemberInfo.get('address');
                } else {
                    address = (Map<String, Object>)person.get('address');
                }
                member.ARC_PhysicalAddressStreet__c = address.containsKey('street') ? (String)address.get('street') : null;
                member.ARC_PhysicalAddressCity__c = address.containsKey('city') ? (String)address.get('city') : null;
                member.ARC_PhysicalAddressState__c = address.containsKey('state') ? String.valueOf(address.get('state')).toUpperCase() : null;
                member.ARC_PhysicalAddressZipCode__c = address.containsKey('zip') ? (String)address.get('zip') : null;
                member.ARC_UseParentAddress__c = address.containsKey('sameAddressAsPrimary') ? convertToBoolean(address.get('sameAddressAsPrimary')) : false;
                
                member.ARC_HeightFeet__c = person.containsKey('heightFeet') ? String.valueOf(person.get('heightFeet')) : null;
                member.ARC_HeightInches__c = person.containsKey('heightInches') ? String.valueOf(person.get('heightInches')) : null;
                member.ARC_Weight__c = person.containsKey('weightLbs') ? String.valueOf(person.get('weightLbs')) : null;
                member.ARC_Smoker__c = person.containsKey('smoker') ? convertToBoolean(person.get('smoker')) : null;
                member.ARC_isPregnant__c = person.containsKey('pregnant') ? convertToBoolean(person.get('pregnant')) : null;
                
                member.vlocity_ins__CensusId__c = this.manager.censusId;
                member.vlocity_ins__MemberIdentifier__c = String.valueOf(Datetime.now().getTime()) + '-' + String.valueOf(Math.random());
                if ((String)memberInfo.get('role') == 'Primary') {
                    member.Id = this.manager.primaryCensusMemberId;
                    primaryMemberIdentifier = member.vlocity_ins__MemberIdentifier__c;
                }
                member.vlocity_ins__IsPrimaryMember__c = memberInfo.containsKey('role') ? (String)memberInfo.get('role') == 'Primary' : false;
                member.ARC_DependentRelationship__c = memberInfo.containsKey('role') ? ((String)memberInfo.get('role') != 'Primary' ? (String)memberInfo.get('role') : null) : null;
                member.vlocity_ins__IsSpouse__c = memberInfo.containsKey('role') ? (String)memberInfo.get('role') == 'Spouse' : false;
                this.manager.memberIdToFamilyRole.put((String)memberInfo.get('memberExternalId'), memberInfo.containsKey('role') ? (String)memberInfo.get('role') : null);
                this.manager.memberIdToBirthdate.put((String)memberInfo.get('memberExternalId'), member.vlocity_ins__Birthdate__c);

                member.ARC_EnrollmentCompleted__c = true;
                member.ARC_AllowEnrollmentOutsideOE__c = false;
                if (member.vlocity_ins__Birthdate__c != null) member.ARC_AgeAtEnrollment__c = calculateAge(member.vlocity_ins__Birthdate__c);
                //member.recordTypeId = recordTypeId;

                this.manager.memberIdToCensusMemberMap.put((String)memberInfo.get('memberExternalId'), member);    
            }
            for (vlocity_ins__GroupCensusMember__c member : this.manager.memberIdToCensusMemberMap.values()) {
                if (!member.vlocity_ins__IsPrimaryMember__c) {
                    member.vlocity_ins__PrimaryMemberIdentifier__c = primaryMemberIdentifier;
                }
            }
        } catch (Exception e) {
            System.debug('Error in mapCensusMembers: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    /**
     * @Description: Maps the Member Id to Beneficiaries
     */
    private void mapBeneficiaries() {
        try {
            System.debug('Mapping Beneficiaries data');

            // Get the Members list
            List<Object> members = (List<Object>) this.enrollmentInfo.get('members');

            // Iterate over the list of Members to get their beneficiaries
            for (Object memberInfo_Obj : members) {
                Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;

                // Verify if the member has Beneficiaries
                if (memberInfo.containsKey('beneficiaries') && memberInfo.get('beneficiaries') != null) {
                    Map<String, Object> beneficiariesMap = (Map<String, Object>) memberInfo.get('beneficiaries');
                    String memberExternalId = (String)memberInfo.get('memberExternalId');
                    
                    // Map the Beneficiaries to their Member Id
                    this.manager.memberIdToBeneficiaries.put(memberExternalId, beneficiariesMap);
                }
            }

        } catch (Exception e) {
            System.debug('Error in mapBeneficiaries: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
        }
    }
    
    /**
     * @Description: Maps data to Person Account object
     */
    private void mapPersonAccounts() {
        try {
            if (this.enrollmentInfo.containsKey('members') && this.enrollmentInfo.get('members') != null) {
                System.debug('Mapping Person Account data');

                Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_SGPersonAccount').getRecordTypeId();

                List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
                for (Object memberInfo_obj : members) {
                    Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
                    Map<String, Object> person = (Map<String, Object>)memberInfo.get('person');
                    String memberExtId = (String)memberInfo.get('memberExternalId');
                    Account account = new Account();

                    if (memberInfo.containsKey('role') && memberInfo.get('role') != null && (String)memberInfo.get('role') != 'Primary') {
                        account.RecordTypeId = recordTypeId;
                        account.FirstName = person.containsKey('firstName') ? (String)person.get('firstName') : null;
                        account.LastName = person.containsKey('lastName') ? (String)person.get('lastName') : null;
                        account.ARC_Census__c = this.manager.censusId;
                        account.ARC_PrimaryMemberAccount__c = this.manager.accountId;
                        account.ARC_GroupAccount__c = this.manager.accountId;
                    }
                    else if (memberInfo.containsKey('role') && memberInfo.get('role') != null && (String)memberInfo.get('role') == 'Primary') {
                        account.Id = this.manager.accountId;
                    }
                    this.manager.memberIdToAccountMap.put(memberExtId, account);
                }
            }
            
        } catch (Exception e) {
            System.debug('Error in mapPersonAccounts: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    /**
     * @Description: Maps data to Person Account object
     */
    private void mapGuardian() {
        try {
            System.debug('Mapping Guardian Account data');
            Map<String,Object> generalInfo = this.enrollmentInfo.containsKey('generalInformation') && this.enrollmentInfo.get('generalInformation') != null ? (Map<String,Object>)this.enrollmentInfo.get('generalInformation') : null;

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
                System.debug('Guardian Account in Mapper: ' + manager.guardianToInsert);                
            }

        } catch (Exception e) {
            System.debug('Error in mapGuardian: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Maps data to HIPAA object
     */
    private void mapHIPAA() {
        try {
            System.debug('Mapping HIPAA data');
            
            Map<String, Object> generalInformation = this.enrollmentInfo.containsKey('generalInformation') && this.enrollmentInfo.get('generalInformation') != null ? (Map<String, Object>)this.enrollmentInfo.get('generalInformation') : null;
            
            if (generalInformation.containsKey('hipaa') && generalInformation.get('hipaa') != null) {
                
                List<Object> hipaaList = (List<Object>)generalInformation.get('hipaa');
                ARC_HipaaAuthorization__c newHipaa;

                Integer index = 0;

                for (Object hipaaObj : hipaaList) {
                    Map<String, Object> hipaaTemp = (Map<String, Object>)hipaaObj;
                    index += 1;
                    String temporaryMemberId = 'TMP-0000' + index;

                    if ((Boolean)hipaaTemp.get('CHK_Authorized') == true) {
                        newHipaa = new ARC_HipaaAuthorization__c();
                        newHipaa.Name = (String)hipaaTemp.get('firstName') + ' ' + (String)hipaaTemp.get('lastName');
                        newHipaa.ARC_PrimaryAccount__c = this.manager.accountId;
                    }
                   
                    if ((String)hipaaTemp.get('relationship') == 'Third Party') {

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
                        // ---------------------------------------------------------
                        // Store the external contact information && And the third party hipaa information
                        // ---------------------------------------------------------
                        this.manager.hipaaExternalContact.put(temporaryMemberId, externalPersonal);
                        this.manager.hipaaThirdParty.put(temporaryMemberId, newHipaa);

                    } else if (generalInformation.containsKey('guardian') && generalInformation.get('guardian') != null &&
                              (String)((Map<String, Object>)generalInformation.get('guardian')).get('firstName') == (String)hipaaTemp.get('firstName') &&
                              (String)((Map<String, Object>)generalInformation.get('guardian')).get('lastName') == (String)hipaaTemp.get('lastName') &&
                              (String)((Map<String, Object>)generalInformation.get('guardian')).get('dob') == (String)hipaaTemp.get('dob') ) {
                        // ---------------------------------------------------------        
                        // Store the guardian hipaa
                        // ---------------------------------------------------------
                        this.manager.hipaaLegalGuardian.put(temporaryMemberId, newHipaa);

                    } else {
                        // ---------------------------------------------------------
                        // Store the census member hipaa information
                        // ---------------------------------------------------------
                        this.manager.hipaaCensusMember.put((String)hipaaTemp.get('memberExternalId'), newHipaa);
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug('Error in mapHIPAA: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to Insurance Policy object
     */
    private void mapPolicy() {
        try {
            System.debug('Mapping Insurance Policy data');
            Map<String, Object> generalInformation = (Map<String, Object>)this.enrollmentInfo.get('generalInformation');
            Map<String, Object> medicalMap = generalInformation.containsKey('medicalProgram') && generalInformation.get('medicalProgram') != null ? (Map<String, Object>)generalInformation.get('medicalProgram') : null;
            Map<String, Object> primaryMember = getPrimaryMemberInfo();
            Boolean isLegacy = primaryMember.containsKey('isLegacy') && primaryMember.get('isLegacy') != null ? (Boolean)primaryMember.get('isLegacy') : null;
           
            Decimal mthcontribEE = 0;
            Decimal mthcontribER = 0;
            Decimal basePriceTotal = 0;
            Decimal individualPrice = 0;

            
            InsurancePolicy policy = new InsurancePolicy();

            for (String key : medicalMap.keySet()) {
                Map<String, Object> medical = (Map<String, Object>)medicalMap.get(key);

                if (key.contains('Senior') && isLegacy) {
                    individualPrice = (Decimal)medical.get('individualPrice');
                }
                else if (!key.contains('Senior') && !isLegacy) {
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

            policy.Name = 'ShopAndEnroll Policy';
            policy.PolicyName = (String)primaryMember.get('firstName') + ' ' + (String)primaryMember.get('lastName') + ' - Family';
            policy.Status = 'Awaiting Signature';
            policy.ARC_GroupAccount__c = this.manager.groupAccountId;
            policy.ARC_Reason__c = resolveReason();
            policy.ARC_Contract__c = this.manager.contractId;
            policy.ARC_PolicyEffectiveDate__c = this.manager.effectiveDate;
           // policy.ARC_EndDate__c = null;
            policy.NameInsuredId = this.manager.accountId;
            policy.NameInsuredId = this.manager.accountId;
            policy.EmployeeContribution = mthcontribEE;
            policy.EmployerContribution = mthcontribER;
            policy.ARC_IndividualPrice__c = individualPrice;
            policy.ARC_DependentPrice__c = basePriceTotal - individualPrice;
            //policy.PremiumAmount = (mthcontribEE + mthcontribER);

            // Override existing policy under current contract (reuse same record Id so upsert updates)
            if (this.manager.priorPolicy != null) {
                policy.Id = this.manager.priorPolicy.Id;
            }

            // ---------------------------------------------------------
            // Add input JSON to Insurance Policy for future reference
            // ---------------------------------------------------------
            policy.ARC_JsonSESG__c = JSON.serializePretty(this.enrollmentInfo);

            this.manager.policy = policy;
        } catch (Exception e) {
            System.debug('Error in mapPolicy: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Maps data to Insurance Policy object
     */
    private void mapPolicyParticipants() {
        try {
            System.debug('Mapping Insurance Policy Participants data');

            Map<String, Object> generalInformation = (Map<String, Object>)this.enrollmentInfo.get('generalInformation');
            List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
            for (Object memberInfo_obj : members) {
                Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
                Map<String, Object> person = (Map<String, Object>)memberInfo.get('person');
                
                InsurancePolicyParticipant polPart = new InsurancePolicyParticipant();
                String memberRole = (String)memberInfo.get('role');
                polPart.Role = memberRole == 'Child' ? 'Dependent' : memberRole;
                polPart.ARC_StartDate__c = this.manager.effectiveDate;

                this.manager.memberIdToPolicyParticipant.put((String)memberInfo.get('memberExternalId'), polPart);
            }
            
        } catch (Exception e) {
            System.debug('Error in mapPolicyParticipants: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Maps data to Policy Coverages object
     */
    private void mapPolicyCoverages() {
        try {
            System.debug('Mapping Policy Coverages data');

            // ---------------------------------------------------------
            // Insurance Policy Coverage for Medical and Legacy Products
            // ---------------------------------------------------------
            Map<String, Object> generalInformation = (Map<String, Object>)this.enrollmentInfo.get('generalInformation');
            Map<String, Object> medicalMap = generalInformation.containsKey('medicalProgram') && generalInformation.get('medicalProgram') != null ? (Map<String, Object>)generalInformation.get('medicalProgram') : null;
            List<Object> members = this.enrollmentInfo.containsKey('members') && this.enrollmentInfo.get('members') != null ? (List<Object>)this.enrollmentInfo.get('members') : null;
            Set<Id> parentProductIds = new Set<Id>();

            if (medicalMap != null && members != null) {
                Integer aux = 1;

                for (String key : medicalMap.keySet()) {
                    Map<String, Object> medical = (Map<String, Object>)medicalMap.get(key);
                    

                    for (Object memberInfo_obj : members) {
                        Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
                        String memberExternalId = (String)memberInfo.get('memberExternalId');
                        Map<String, Object> person = (Map<String, Object>)memberInfo.get('person');

                        InsurancePolicyCoverage newIPC = new InsurancePolicyCoverage();
                        newIPC.CoverageName = key;
                        newIPC.vlocity_ins_fsc__Product2Id__c = medical.containsKey('productId') && medical.get('productId') != null ? (Id)medical.get('productId') : null;
                        newIPC.ARC_UnitPrice__c = medical.containsKey('individualPrice') && medical.get('individualPrice') != null ? (Double)medical.get('individualPrice') : null;
                        
                        // Populate contributions via direct field assignment (no metadata/dynamic mapping).
                        newIPC.ARC_EmployeeContribution__c =
                            (medical.containsKey('employeeSplit') && medical.get('employeeSplit') != null)
                                ? toDecimal(medical.get('employeeSplit'))
                                : null;
                        newIPC.ARC_EmployerContribution__c =
                            (medical.containsKey('employerSplit') && medical.get('employerSplit') != null)
                                ? toDecimal(medical.get('employerSplit'))
                                : null;
                        newIPC.ARC_Reason__c = 'New Policy';

                        parentProductIds.add(newIPC.vlocity_ins_fsc__Product2Id__c);  

                        Boolean isLegacy = person.containsKey('isLegacy') && person.get('isLegacy') != null ? (Boolean)person.get('isLegacy') : null;
                        
                        if (isLegacy && key.contains('Senior')) {
                           // this.manager.indexToMemberIds.put('LegacyMedical' + aux, new List<String>());
                            this.manager.indexToParentCovToInsert.put('LegacyMedical' + aux, newIPC);


                            if (!this.manager.indexToMemberIds.containsKey('LegacyMedical' + aux)) {
                                this.manager.indexToMemberIds.put('LegacyMedical' + aux, new List<String>());
                            }

                            this.manager.indexToMemberIds.get('LegacyMedical' + aux).add(memberExternalId);
                            aux ++;
                        }   
                        else if (!isLegacy && !key.contains('Senior')) {
                            // this.manager.indexToMemberIds.put('Medical', new List<String>());
                            this.manager.indexToParentCovToInsert.put('Medical', newIPC);
                            // this.manager.indexToMemberIds.get('Medical').add(memberExternalId);

                            if (!this.manager.indexToMemberIds.containsKey('Medical')) {
                                this.manager.indexToMemberIds.put('Medical', new List<String>());
                            }

                            this.manager.indexToMemberIds.get('Medical').add(memberExternalId);
                        }


                        
                    }
                
                    Decimal basePrice = (Decimal)medical.get('basePrice');
                }
            }
            
            // ---------------------------------------------------------
            // Child Products Mapping
            // ---------------------------------------------------------
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
            for (String key : this.manager.indexToParentCovToInsert.keySet()) {
                InsurancePolicyCoverage parentCov = this.manager.indexToParentCovToInsert.get(key);
                for (Product2 childProduct : productIdToChildProduct.get(parentCov.vlocity_ins_fsc__Product2Id__c)) {
                    InsurancePolicyCoverage childCov = new InsurancePolicyCoverage();
                    childCov.CoverageName = childProduct.Name;
                    childCov.vlocity_ins_fsc__Product2Id__c = childProduct.Id;
                    childCov.ARC_ParentProduct__c = parentCov.vlocity_ins_fsc__Product2Id__c;
                    // Price
                    if (!this.manager.indexToChildCovToInsert.containsKey(key)) {
                        this.manager.indexToChildCovToInsert.put(key, new List<InsurancePolicyCoverage>());
                    }
                    this.manager.indexToChildCovToInsert.get(key).add(childCov);
                }
            }

        } catch (Exception e) {
            System.debug('Error in mapPolicyCoverages: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Maps data to ARC External Insurance Policy and Policy Member object
     */
    private void mapExternalInsurancePolicyMember() {
        try {
            System.debug('Mapping ARC External Insurance Policy data');
            List<Object> enrollmentMembersList = this.enrollmentInfo.containsKey('members') && this.enrollmentInfo.get('members') != null ? (List<Object>)this.enrollmentInfo.get('members') : new List<Object>();

            if (!enrollmentMembersList.isEmpty() && enrollmentMembersList.size() > 0) {
                for (Object member : enrollmentMembersList) {
                    Map<String,Object> memberMap = (Map<String,Object>)member;
                    String memberExternalId = (String)memberMap.get('memberExternalId');

                    if (memberMap.containsKey('currentCoverage') && !((List<Object>)memberMap.get('currentCoverage')).isEmpty() && ((List<Object>)memberMap.get('currentCoverage')).size() > 0) {
                        for (Object coverage : (List<Object>)memberMap.get('currentCoverage')) {

                            Map<String,Object> coverageMap = (Map<String,Object>)coverage;
                            String coverageKey = (String)coverageMap.get('carrier') + '_' + (String)coverageMap.get('policyNumber');
                            
                            // ---------------------------------------------------------
                            // Instance new policy to insert only if it is not already in map of policies
                            // ---------------------------------------------------------
                            if (!manager.externalPoliciesToInsert.containsKey(coverageKey)) {
                                ARC_ExternalInsurancePolicy__c externalPolicy = new ARC_ExternalInsurancePolicy__c();
                                externalPolicy.ARC_InsurerName__c = (String)coverageMap.get('carrier');
                                externalPolicy.ARC_PolicyNumber__c = (String)coverageMap.get('policyNumber');
                                externalPolicy.ARC_InsurerPhone__c = (String)coverageMap.get('carrierPhone'); 
                                externalPolicy.ARC_EffectiveDate__c = (String)coverageMap.get('effectiveDate') != null && (String)coverageMap.get('effectiveDate') != '' ? Date.valueOf((String)coverageMap.get('effectiveDate')) : null;
                                externalPolicy.ARC_ExpirationDate__c = (String)coverageMap.get('expirationDate') != null && (String)coverageMap.get('expirationDate') != '' ? Date.valueOf((String)coverageMap.get('expirationDate')) : null; 
                                externalPolicy.ARC_SourceOfCoverage__c = (String)coverageMap.get('coverageSource');

                                // ---------------------------------------------------------
                                // Add the ext policy to map to insert with coverage key as key
                                // ---------------------------------------------------------
                                manager.externalPoliciesToInsert.put(coverageKey, externalPolicy);
                            }

                            // ---------------------------------------------------------
                            // Add member external Id to Policy to Member map (If key is not in the map, put it and instance a new list and then add it)
                            // ---------------------------------------------------------
                            if (!manager.policyKeyToMemberIds.containsKey(coverageKey)) {
                                manager.policyKeyToMemberIds.put(coverageKey, new List<String>());
                            }
                            manager.policyKeyToMemberIds.get(coverageKey).add(memberExternalId);
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in mapExternalInsurancePolicy: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Delete all related records if already has a policy associated under the current contract.
     *               Scoped to the current contract (ARC_Contract__c) so that policies from other contracts
     *               are not affected. Stores the prior policy in manager.priorPolicy for reason stamping.
     *               If no prior policy exists under the current contract, manager.priorPolicy stays null
     *               and nothing is deleted (new enrollment path).
     *
     
     */
    private void checkPolicy() {
        try {
            List<vlocity_ins__GroupCensusMember__c> members = [
                SELECT vlocity_ins__ContactId__r.AccountId 
                FROM vlocity_ins__GroupCensusMember__c 
                WHERE Id = :this.manager.primaryCensusMemberId 
                LIMIT 1
            ];
            
            if (members.isEmpty() || members[0].vlocity_ins__ContactId__r.AccountId == null) return;
            Id employeeAccountId = members[0].vlocity_ins__ContactId__r.AccountId;

            Set<Id> allFamilyAccountIds = new Set<Id>();
            allFamilyAccountIds.add(employeeAccountId);

            Map<Id, SObject> recordsToDeleteMap = new Map<Id, SObject>();

            // ---------------------------------------------------------
            // Policy — scoped to the current contract
            // ---------------------------------------------------------
            List<InsurancePolicy> policies = [
                SELECT Id,
                    ARC_JsonSESG__c,
                    NameInsuredId,
                    (SELECT Id FROM InsurancePolicyParticipants),
                    (SELECT Id FROM InsurancePolicyCoverages),
                    (SELECT Id FROM CoverageParticipants__r)
                FROM InsurancePolicy
                WHERE NameInsuredId = :employeeAccountId
                  AND ARC_Contract__c = :this.manager.contractId
                LIMIT 1
            ];

            // Store prior policy for renewal detection / reason stamping; null = new enrollment
            this.manager.priorPolicy = policies.isEmpty() ? null : policies[0];

            // If no prior policy exists under this contract, nothing to delete — new enrollment
            if (policies.isEmpty()) return;

            InsurancePolicy pol = policies[0];

            // CoverageParticipants__r
            if (pol.CoverageParticipants__r != null) {
                for(SObject item : pol.CoverageParticipants__r) recordsToDeleteMap.put(item.Id, item);
            }

            // InsurancePolicyCoverages
            if (pol.InsurancePolicyCoverages != null) {
                for(SObject item : pol.InsurancePolicyCoverages) recordsToDeleteMap.put(item.Id, item);
            }

            // InsurancePolicyParticipants
            if (pol.InsurancePolicyParticipants != null) {
                for(SObject item : pol.InsurancePolicyParticipants) recordsToDeleteMap.put(item.Id, item);
            }

            // InsurancePolicy is NOT deleted — it is updated in-place via Database.upsert
            // (mapPolicy sets policy.Id = priorPolicy.Id so the upsert issues an UPDATE, not INSERT).

            // ---------------------------------------------------------
            // Dependents (Accounts and Census Members) | Guardian | HIPAA
            // ---------------------------------------------------------

            // Dependents && Guardian
            List<Account> dependents = [SELECT Id, Census_Member__c FROM Account WHERE ARC_PrimaryMemberAccount__c = :employeeAccountId];
            for (Account dep : dependents) {
                allFamilyAccountIds.add(dep.Id);

                recordsToDeleteMap.put(dep.Id, dep);
                
                if (dep.Census_Member__c != null) {
                    vlocity_ins__GroupCensusMember__c cm = new vlocity_ins__GroupCensusMember__c(Id = dep.Census_Member__c);
                    recordsToDeleteMap.put(cm.Id, cm); 
                }
            }

            // HIPAA
            List<ARC_HipaaAuthorization__c> hipaas = [SELECT Id FROM ARC_HipaaAuthorization__c WHERE ARC_PrimaryAccount__c = :employeeAccountId];
            for (ARC_HipaaAuthorization__c h : hipaas) {
                recordsToDeleteMap.put(h.Id, h);
            }

            // ---------------------------------------------------------
            // External Policy
            // ---------------------------------------------------------
            List<ARC_ExternalInsurancePolicyMember__c> extMembers = [
                SELECT Id, ARC_ExternalInsurancePolicy__c 
                FROM ARC_ExternalInsurancePolicyMember__c 
                WHERE ARC_PersonAccount__c IN :allFamilyAccountIds 
            ];

            for (ARC_ExternalInsurancePolicyMember__c em : extMembers) {
                recordsToDeleteMap.put(em.Id, em);
                
                if (em.ARC_ExternalInsurancePolicy__c != null) {
                    ARC_ExternalInsurancePolicy__c extPol = new ARC_ExternalInsurancePolicy__c(Id = em.ARC_ExternalInsurancePolicy__c);
                    recordsToDeleteMap.put(extPol.Id, extPol);
                }
            }

            // ---------------------------------------------------------
            // DELETE
            // ---------------------------------------------------------
            if (!recordsToDeleteMap.isEmpty()) {
                Map<Schema.SObjectType, List<SObject>> typeBuckets = new Map<Schema.SObjectType, List<SObject>>();
                
                for (SObject obj : recordsToDeleteMap.values()) {
                    Schema.SObjectType type = obj.getSObjectType();
                    if (!typeBuckets.containsKey(type)) {
                        typeBuckets.put(type, new List<SObject>());
                    }
                    typeBuckets.get(type).add(obj);
                }

                List<SObject> sortedList = new List<SObject>();
                for (Schema.SObjectType type : typeBuckets.keySet()) {
                    sortedList.addAll(typeBuckets.get(type));
                }

                delete sortedList;
            }
        }
        catch (Exception e) {
            System.debug('Error in checkPolicy: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Gets the person node for the primary member
     * @return Map<String, Object>: Map of the JSON nodes in "person"
     */
    private Map<String, Object> getPrimaryMemberInfo() {
        List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
        for (Object memberInfo_obj : members) {
            Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
            if ((String)memberInfo.get('role') == 'Primary') {
                return (Map<String, Object>)memberInfo.get('person');
            }
        }
        return null;
    }

    private Date getEffectiveDate(Date contractEffectiveDate) {
        Account groupAccount = [SELECT Id, ARC_NewEmployeeWaitingPeriod__c FROM Account WHERE Id = :this.manager.groupAccountId LIMIT 1];
        Account primaryMemberAccount = [SELECT Id, ARC_HireDate__c FROM Account WHERE Id = :this.manager.accountId LIMIT 1];

        String waitingPeriodValue = (String)groupAccount.ARC_NewEmployeeWaitingPeriod__c;
        Date hireDate = primaryMemberAccount.ARC_HireDate__c;

        Date calculatedDate = null;
        if (hireDate != null) {
            switch on waitingPeriodValue {
                when 'None – effective date of hire' {
                    calculatedDate = hireDate;
                }
                when 'First of the month following hire date' {
                    calculatedDate = getFirstDayOfFollowingMonth(hireDate);
                }
                when 'First of the month following one month from hire date' {
                    calculatedDate = getFirstDayOfFollowingMonth(hireDate.addMonths(1));
                }
                when 'First of the month following two months from hire date' {
                    calculatedDate = getFirstDayOfFollowingMonth(hireDate.addMonths(2));
                }
                when else {
                    // Fallback to immediate eligibility if value is missing/unexpected.
                    calculatedDate = hireDate;
                }
            }
        }

        Date finalEffectiveDate = contractEffectiveDate;
        if (finalEffectiveDate == null || (calculatedDate != null && calculatedDate > finalEffectiveDate)) {
            finalEffectiveDate = calculatedDate;
        }

        System.debug('getEffectiveDate - contractEffectiveDate(JSON): ' + contractEffectiveDate);
        System.debug('getEffectiveDate - hireDate(Account.ARC_HireDate__c): ' + hireDate);
        System.debug('getEffectiveDate - waitingPeriodValue(GroupAccount.ARC_NewEmployeeWaitingPeriod__c): ' + waitingPeriodValue);
        System.debug('getEffectiveDate - calculatedDate(hire + waiting period): ' + calculatedDate);
        System.debug('getEffectiveDate - finalEffectiveDate: ' + finalEffectiveDate);

        return finalEffectiveDate;
    }

    private Date getFirstDayOfFollowingMonth(Date inputDate) {
        return Date.newInstance(inputDate.year(), inputDate.month(), 1).addMonths(1);
    }
    
    /**
     * @Description: Converts a value to Boolean
     * @param value: The value to convert
     * @return Boolean: The converted boolean value
     */
    private Boolean convertToBoolean(Object value) {
        if (value == null) return null;
        if (value instanceof Boolean) return (Boolean)value;
        if (value instanceof String) {
            String strValue = (String)value;
            return strValue.equalsIgnoreCase('true') || strValue.equals('1');
        }
        return null;
    }

    private Integer calculateAge(Date dob) {
        Date today = Date.today();
        Integer age = today.year() - dob.year();
        if (today.month() < dob.month() || 
            (today.month() == dob.month() && today.day() < dob.day())) {
            age--; 
        }
        return age;
    }

    private static Decimal toDecimal(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Decimal) {
            return (Decimal)value;
        }
        if (value instanceof Double) {
            return Decimal.valueOf((Double)value);
        }
        if (value instanceof Integer) {
            return Decimal.valueOf((Integer)value);
        }
        if (value instanceof Long) {
            return Decimal.valueOf((Long)value);
        }
        return Decimal.valueOf(String.valueOf(value));
    }

    /**
     * @Description: Determines the ARC_Reason__c value to stamp on the InsurancePolicy.
     *   Delegates change detection to ARC_SG_Utilities.evaluateChanges, which uses the
     *   ARC_UHSM_Programs2023 calculation matrix for proper Upgrade/Downgrade logic.
     *   - No prior policy under the current contract → 'New Application'
     *   - Prior policy exists → 'Renewal' + any of: Program Upgrade, Program Downgrade, Add Member, Remove Member
     */
    private String resolveReason() {
        if (this.manager.priorPolicy == null) {
            return 'New Application';
        }

        List<String> reasons = new List<String>{ 'Renewal' };

        try {
            Map<String, Object> priorInfo = this.manager.priorPolicy.ARC_JsonSESG__c != null
                ? (Map<String, Object>) JSON.deserializeUntyped(this.manager.priorPolicy.ARC_JsonSESG__c)
                : null;

            if (priorInfo != null) {
                Map<String, Object> priorGeneralInfo = (Map<String, Object>) priorInfo.get('generalInformation');
                Map<String, Object> priorMedicalMap = priorGeneralInfo != null && priorGeneralInfo.containsKey('medicalProgram')
                    ? (Map<String, Object>) priorGeneralInfo.get('medicalProgram')
                    : null;

                if (priorMedicalMap != null) {
                    // Build currentState.currentProducts from prior medicalProgram (already the right format)
                    Map<String, Object> currentProducts = new Map<String, Object>(priorMedicalMap);

                    // Build currentState.currentMembers — assign productId per member based on isLegacy
                    List<Object> priorMemberList = priorInfo.containsKey('members') ? (List<Object>) priorInfo.get('members') : new List<Object>();
                    List<Object> currentMembers = new List<Object>();
                    for (Object m : priorMemberList) {
                        Map<String, Object> priorMember = (Map<String, Object>) m;
                        Map<String, Object> priorPerson = priorMember.containsKey('person') ? (Map<String, Object>) priorMember.get('person') : new Map<String, Object>();
                        Boolean isLegacy = priorPerson.containsKey('isLegacy') && priorPerson.get('isLegacy') != null ? (Boolean) priorPerson.get('isLegacy') : false;
                        currentMembers.add(new Map<String, Object>{
                            'memberExternalId' => priorMember.get('memberExternalId'),
                            'productId'        => getProductIdFromMedicalMap(priorMedicalMap, isLegacy)
                        });
                    }

                    Map<String, Object> currentState = new Map<String, Object>{
                        'currentProducts' => currentProducts,
                        'currentMembers'  => currentMembers
                    };

                    // Enrich new member list with productId (required by evaluateChanges)
                    Map<String, Object> currentGeneralInfo = (Map<String, Object>) this.enrollmentInfo.get('generalInformation');
                    Map<String, Object> currentMedicalMap = currentGeneralInfo != null && currentGeneralInfo.containsKey('medicalProgram')
                        ? (Map<String, Object>) currentGeneralInfo.get('medicalProgram')
                        : null;
                    List<Object> enrichedMembers = new List<Object>();
                    for (Object m : (List<Object>) this.enrollmentInfo.get('members')) {
                        Map<String, Object> member = (Map<String, Object>) m;
                        Map<String, Object> person = member.containsKey('person') ? (Map<String, Object>) member.get('person') : new Map<String, Object>();
                        Boolean isLegacy = person.containsKey('isLegacy') && person.get('isLegacy') != null ? (Boolean) person.get('isLegacy') : false;
                        Map<String, Object> enriched = new Map<String, Object>(member);
                        enriched.put('productId', currentMedicalMap != null ? getProductIdFromMedicalMap(currentMedicalMap, isLegacy) : null);
                        enrichedMembers.add(enriched);
                    }

                    // Build eval payload — shallow-copy generalInformation so evaluateChanges doesn't
                    // mutate the original (it adds qleChanges to generalInformation in place)
                    Map<String, Object> evalGeneralInfo = new Map<String, Object>(currentGeneralInfo);
                    Map<String, Object> evalPayload = new Map<String, Object>(this.enrollmentInfo);
                    evalPayload.put('generalInformation', evalGeneralInfo);
                    evalPayload.put('currentState', currentState);
                    evalPayload.put('members', enrichedMembers);

                    Map<String, Object> result = ARC_SG_Utilities.evaluateChanges(evalPayload);
                    System.debug('resolveReason — evalPayload.currentState: ' + JSON.serializePretty(evalPayload.get('currentState')));
                    System.debug('resolveReason — evalPayload.members: ' + JSON.serializePretty(evalPayload.get('members')));
                    System.debug('resolveReason — qleChanges: ' + JSON.serializePretty(((Map<String,Object>)result.get('generalInformation')).get('qleChanges')));

                    Map<String, Object> resultGeneralInfo = result.containsKey('generalInformation')
                        ? (Map<String, Object>) result.get('generalInformation')
                        : null;
                    Map<String, Boolean> qleChanges = resultGeneralInfo != null && resultGeneralInfo.containsKey('qleChanges')
                        ? (Map<String, Boolean>) resultGeneralInfo.get('qleChanges')
                        : null;

                    if (qleChanges != null) {
                        if (qleChanges.get('programUpgrade')   == true) reasons.add('Program Upgrade');
                        if (qleChanges.get('programDowngrade') == true) reasons.add('Program Downgrade');
                        if (qleChanges.get('addMember')        == true) reasons.add('Add Member');
                        if (qleChanges.get('removeMember')     == true) reasons.add('Remove Member');
                    }
                }
            }
        } catch (Exception e) {
            System.debug('resolveReason: evaluateChanges failed — defaulting to Renewal. ' + e.getMessage());
        }

        return String.join(reasons, ';');
    }

    /**
     * @Description: Returns the productId from medicalProgram for the correct plan tier
     *   (Senior plan for legacy members, non-Senior plan for standard members).
     */
    private String getProductIdFromMedicalMap(Map<String, Object> medicalMap, Boolean isLegacy) {
        for (String planKey : medicalMap.keySet()) {
            Boolean isSeniorPlan = planKey.contains('Senior');
            if ((isLegacy && isSeniorPlan) || (!isLegacy && !isSeniorPlan)) {
                Map<String, Object> plan = (Map<String, Object>) medicalMap.get(planKey);
                return plan != null && plan.containsKey('productId') && plan.get('productId') != null
                    ? String.valueOf(plan.get('productId'))
                    : null;
            }
        }
        return null;
    }
}