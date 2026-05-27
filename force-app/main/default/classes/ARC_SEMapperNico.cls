/**
 * @Description: Mapper class for Self Enrollment Flow operations.
 * This class handles the mapping of enrollment data to Salesforce objects.
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-01-27
 * @Version: 1.0
 */
global without sharing class ARC_SEMapperNico {
    
    // Mapped objects\
    public Map<String, Object> enrollmentInfo { get; set; }
    public vlocity_ins__GroupCensus__c census { get; set; }
    public List<vlocity_ins__GroupCensusMember__c> censusMembers { get; set; }
    public List<Account> personAccounts { get; set; }
    public Account groupAccount { get; set; }
    public Contract contract { get; set; }
    public vlocity_ins__ContractLineItem__c contractLineItem { get; set; }
    public vlocity_ins__GroupCensusMember__c groupCensusMemberPlan { get; set; }
    public ARC_ExternalInsurancePolicyMember__c externalInsurancePolicyMember { get; set; }
    public ARC_ContractParticipant__c contractParticipant { get; set; }
    public ChargentOrders__ChargentOrder__c chargentOrder { get; set; }
    public Case uwCase { get; set; }
    public ARC_UnderwritingCaseMember__c uwCaseMember { get; set; }
    public ARC_HipaaAuthorization__c hippa { get; set; } 
    public ARC_MedicalConditions__c medicalQuestion { get; set; }
    
    public ARC_SEManagerNico manager;

    /**
     * @Description: Main method to map enrollment data to Salesforce objects
     * @param enrollmentInfo: Map containing enrollment information
     * @param memberData: Map containing member data
     * @param planData: Map containing plan data
     */
    public void mapEnrollmentData(ARC_SEManagerNico manager) {
        try {
            this.manager = manager;
            this.enrollmentInfo = manager.enrollmentInfo;
            System.debug('Starting data mapping for Self Enrollment');
            
            // Map each object
            // mapCensus();
            // mapCensusMembers();
            // mapPersonAccounts();
            // mapGroupAccount();
            // mapGuardian();
            // mapContract();
            // mapContractLineItem();
            // mapGroupCensusMemberPlan();
            mapExternalInsurancePolicy();
            mapExternalInsurancePolicyMember();
            // mapContractParticipant();
            // mapChargentOrder();
            // mapUWCase();
            // mapUWCaseMember();
            // mapHIPPA();
            // mapMedicalQuestion();
            
            System.debug('Data mapping completed successfully');
            
        } catch (Exception e) {
            System.debug('Error in mapEnrollmentData: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to Census object
     */
    private void mapCensus() {
        try {
            System.debug('Mapping Census data');

            Map<String, Object> primaryMemberInfo = getPrimaryMemberInfo();

            Id recordTypeId = Schema.SObjectType.vlocity_ins__GroupCensus__c.getRecordTypeInfosByDeveloperName().get('ARC_IndividualAndFamily').getRecordTypeId();
            this.census = new vlocity_ins__GroupCensus__c();
            this.census.Name = (String)primaryMemberInfo.get('firstName') + ' ' + (String)primaryMemberInfo.get('lastName') + ' - Census';
            this.census.RecordTypeId = recordTypeId;
            this.manager.census = this.census;
        } catch (Exception e) {
            System.debug('Error in mapCensus: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to Census object
     */
    private void mapCensusMembers() {
        try {
            System.debug('Mapping Census data');
            
            this.censusMembers = new List<vlocity_ins__GroupCensusMember__c>();
            Map<String, Object> primaryMemberInfo = getPrimaryMemberInfo();
            List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
            for (Object memberInfo_obj : members) {
                vlocity_ins__GroupCensusMember__c member = new vlocity_ins__GroupCensusMember__c();
                
                Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
                System.debug('memberInfo: ' + memberInfo);
                Map<String, Object> person = (Map<String, Object>)memberInfo.get('person');
                System.debug('person: ' + person);

                // Map basic member information
                member.vlocity_ins__FirstName__c = person.containsKey('firstName') ? (String)person.get('firstName') : null;
                member.ARC_MiddleInitial__c = person.containsKey('middleInitial') ? (String)person.get('middleInitial') : null;
                member.vlocity_ins__LastName__c = person.containsKey('lastName') ? (String)person.get('lastName') : null;
                member.vlocity_ins__Email__c = person.containsKey('email') ? (String)person.get('email') : null;
                member.ARC_Phone__c = person.containsKey('phone') ? (String)person.get('phone') : null;
                member.vlocity_ins__Birthdate__c = person.containsKey('dob') ? Date.valueOf((String)person.get('dob')) : null;
                member.vlocity_ins__Gender__c = person.containsKey('gender') ? (String)person.get('gender') : null;
                member.vlocity_ins__SocialSecurityNumber__c = person.containsKey('ssn') ? (String)person.get('ssn') : null;

                // Map address information
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
                
                // Map physical attributes
                member.ARC_HeightFeet__c = person.containsKey('heightFeet') ? String.valueOf(person.get('heightFeet')) : null;
                member.ARC_HeightInches__c = person.containsKey('heightInches') ? String.valueOf(person.get('heightInches')) : null;
                member.ARC_Weight__c = person.containsKey('weightLbs') ? String.valueOf(person.get('weightLbs')) : null;
                member.ARC_Smoker__c = person.containsKey('smoker') ? convertToBoolean(person.get('smoker')) : null;
                member.ARC_isPregnant__c = person.containsKey('pregnant') ? convertToBoolean(person.get('pregnant')) : null;
                
                // Map enrollment specific fields
                member.vlocity_ins__CensusId__c = person.containsKey('censusId') ? (Id)person.get('censusId') : null;
                member.vlocity_ins__MemberIdentifier__c = person.containsKey('memberIdentifier') ? (String)person.get('memberIdentifier') : null;
                member.vlocity_ins__IsPrimaryMember__c = memberInfo.containsKey('role') ? (String)memberInfo.get('role') == 'Primary' : false;
                member.ARC_DependentRelationship__c = memberInfo.containsKey('role') ? ((String)memberInfo.get('role') != 'Primary' ? (String)memberInfo.get('role') : null) : null;
                member.vlocity_ins__IsSpouse__c = memberInfo.containsKey('role') ? (String)memberInfo.get('role') == 'Spouse' : false;
                
                /*
                *
                *
                *
                CENSUS MEMBERS:
                vlocity_ins__MemberIdentifier__c
                vlocity_ins__RelatedCensusMemberId__c *****
                vlocity_ins__PrimaryMemberIdentifier__c
                vlocity_ins__HasSpouse__c


                CENSUS:
                ARC_PrimaryAccount__c
                *
                *
                *
                */


                this.censusMembers.add(member);
                this.manager.memberIdToCensusMemberMap.put((String)memberInfo.get('memberExternalId'), member);
            }  
        } catch (Exception e) {
            System.debug('Error in mapCensusMembers: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to Person Account object
     */
    private void mapPersonAccounts() {
        try {
            System.debug('Mapping Person Account data');

            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();

            this.personAccounts = new List<Account>();
            List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
            for (Object memberInfo_obj : members) {
                Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
                Map<String, Object> person = (Map<String, Object>)memberInfo.get('person');
                Account account = new Account();
                account.RecordTypeId = recordTypeId;
                account.FirstName = person.containsKey('firstName') ? (String)person.get('firstName') : null;
                account.LastName = person.containsKey('lastName') ? (String)person.get('lastName') : null;
                
                this.personAccounts.add(account);
                this.manager.memberIdToAccountMap.put((String)memberInfo.get('memberExternalId'), account);
            }
        } catch (Exception e) {
            System.debug('Error in mapPersonAccounts: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to Group Account (Family) object
     */
    private void mapGroupAccount() {
        try {
            System.debug('Mapping Group Account data');

            this.groupAccount = new Account();
            this.groupAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Group').getRecordTypeId();

            Map<String, Object> primaryMemberInfo = getPrimaryMemberInfo();
            
            // Map group account information
            this.groupAccount.Name = (String)primaryMemberInfo.get('firstName') + ' ' + (String)primaryMemberInfo.get('lastName') + ' Family';
            
            // Map address information (typically same as primary member)
            Map<String, Object> generalInformation = (Map<String, Object>)this.enrollmentInfo.get('generalInformation');
            Map<String, Object> payment = (Map<String, Object>)generalInformation.get('payment');
            Map<String, Object> billingAddress;
            if ((String)payment.get('paymentMethod') == 'credit_card') {
                Map<String, Object> creditCard = (Map<String, Object>)payment.get('creditCard');
                billingAddress = (Map<String, Object>)creditCard.get('billingAddress');
            } else if ((String)payment.get('paymentMethod') == 'bank_account') {
                Map<String, Object> bankAccount = (Map<String, Object>)payment.get('bankAccount');
                billingAddress = (Map<String, Object>)bankAccount.get('billingAddress');
            }
            this.groupAccount.BillingStreet = billingAddress.containsKey('street') ? (String)billingAddress.get('street') : null;
            this.groupAccount.BillingStreet = billingAddress.containsKey('unit') ? this.groupAccount.BillingStreet + ' ' + (String)billingAddress.get('unit') : this.groupAccount.BillingStreet;
            this.groupAccount.BillingCity = billingAddress.containsKey('city') ? (String)billingAddress.get('city') : null;
            this.groupAccount.BillingState = billingAddress.containsKey('state') ? String.valueOf(billingAddress.get('state')).toUpperCase() : null;
            this.groupAccount.BillingPostalCode = billingAddress.containsKey('zip') ? (String)billingAddress.get('zip') : null;
            this.groupAccount.BillingCountry = 'United States';
            
            // Map contact information
            this.groupAccount.Phone = primaryMemberInfo.containsKey('phone') ? (String)primaryMemberInfo.get('phone') : null;
            this.groupAccount.vlocity_ins__Email__c = primaryMemberInfo.containsKey('email') ? (String)primaryMemberInfo.get('email') : null;
            this.manager.groupAccount = this.groupAccount;
        } catch (Exception e) {
            System.debug('Error in mapGroupAccount: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
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
                // Get guardian info from JSON
                Map<String,Object> guardianInfo = (Map<String,Object>)generalInfo.get('guardian');

                // New instance of account for Guardian and get record type id
                Account guardianAccount = new Account();
                Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_Guardian').getRecordTypeId();

                // Fill guardian account fields from JSON
                guardianAccount.RecordTypeId = recordTypeId;
                guardianAccount.ARC_GuardianRelationshipToChild__c = (String)guardianInfo.get('relationship');
                guardianAccount.FirstName = guardianInfo.get('firstName') != null && guardianInfo.get('firstName') != '' ? (String)guardianInfo.get('firstName') : '';
                guardianAccount.LastName = guardianInfo.get('lastName') != null && guardianInfo.get('lastName') != '' ? (String)guardianInfo.get('lastName') : '';
                guardianAccount.Phone = guardianInfo.get('phone') != null && guardianInfo.get('phone') != '' ? (String)guardianInfo.get('phone') : '';
                guardianAccount.PersonEmail = guardianInfo.get('email') != null && guardianInfo.get('email') != '' ? (String)guardianInfo.get('email') : '';
                guardianAccount.vlocity_ins__Email__c = guardianInfo.get('email') != null && guardianInfo.get('email') != '' ? (String)guardianInfo.get('email') : '';
                guardianAccount.PersonGender = guardianInfo.get('gender') != null && guardianInfo.get('gender') != '' ? (String)guardianInfo.get('gender') : '';
                guardianAccount.PersonBirthdate = guardianInfo.get('dob') != null && guardianInfo.get('dob') != '' ? Date.valueOf((String)guardianInfo.get('dob')) : null;
                guardianAccount.ARC_SocialSecurityNumber__c = guardianInfo.get('ssn') != null && guardianInfo.get('ssn') != '' ? (String)guardianInfo.get('ssn') : '';
                guardianAccount.vlocity_ins__SocialSecurityNumber__pc = guardianInfo.get('ssn') != null && guardianInfo.get('ssn') != '' ? (String)guardianInfo.get('ssn') : '';

                if (guardianInfo.containsKey('address') && guardianInfo.get('address') != null) {
                    Map<String,Object> guardianAddress = (Map<String,Object>)guardianInfo.get('address');
                    guardianAccount.BillingStreet = guardianAddress.get('street') != null && guardianAddress.get('street') != '' ? (String)guardianAddress.get('street') : '';
                    guardianAccount.BillingCity = guardianAddress.get('city') != null && guardianAddress.get('city') != '' ? (String)guardianAddress.get('city') : '';
                    guardianAccount.BillingState = guardianAddress.get('state') != null && guardianAddress.get('state') != '' ? (String)guardianAddress.get('state') : '';
                    guardianAccount.BillingPostalCode = guardianAddress.get('zip') != null && guardianAddress.get('zip') != '' ? (String)guardianAddress.get('zip') : '';
                    guardianAccount.BillingCountry = 'United States';
                }

                // Add guardian account to variable in Manager
                manager.guardianToInsert = guardianAccount;
                System.debug('Guardian Account in Mapper: ' + manager.guardianToInsert);                
            }

        } catch (Exception e) {
            System.debug('Error in mapGuardian: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to Contract object
     */
    private void mapContract() {
        try {
            System.debug('Mapping Contract data');
            
            this.contract = new Contract(); 
            
            // Set record type
            this.contract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_IndividualAndFamily').getRecordTypeId();
            
            // Map enrollment information
            this.contract.ARC_EffectiveDate__c = this.enrollmentInfo.containsKey('effectiveDate') ? Date.valueOf((String)this.enrollmentInfo.get('effectiveDate')) : null;
            this.contract.StartDate = this.enrollmentInfo.containsKey('effectiveDate') ? Date.valueOf((String)this.enrollmentInfo.get('effectiveDate')) : null;
            this.contract.ContractTerm = 12;
            this.contract.Status = 'Draft';
            
            // Map census information
            this.contract.vlocity_ins__EnrollmentCensusId__c = this.enrollmentInfo.containsKey('censusId') ? (Id)this.enrollmentInfo.get('censusId') : null;
            
            // Map contract reason
            this.contract.ARC_ContractReason__c = this.enrollmentInfo.containsKey('contractReason') ? (String)this.enrollmentInfo.get('contractReason') : null;
            this.contract.ARC_ContractSubReason__c = this.enrollmentInfo.containsKey('contractSubReason') ? (String)this.enrollmentInfo.get('contractSubReason') : null;
            this.contract.ARC_ContractOtherSubReason__c = this.enrollmentInfo.containsKey('contractOtherSubReason') ? (String)this.enrollmentInfo.get('contractOtherSubReason') : null;
            
            // Map address information from primary member
            this.contract.ARC_PrimaryAddress__Street__s = this.enrollmentInfo.containsKey('addressStreet') ? (String)this.enrollmentInfo.get('addressStreet') : null;
            this.contract.ARC_PrimaryAddress__City__s = this.enrollmentInfo.containsKey('addressCity') ? (String)this.enrollmentInfo.get('addressCity') : null;
            this.contract.ARC_PrimaryAddress__StateCode__s = this.enrollmentInfo.containsKey('addressState') ? String.valueOf(this.enrollmentInfo.get('addressState')).toUpperCase() : null;
            this.contract.ARC_PrimaryAddress__PostalCode__s = this.enrollmentInfo.containsKey('addressZipCode') ? (String)this.enrollmentInfo.get('addressZipCode') : null;
            this.contract.ARC_PrimaryAddress__CountryCode__s = 'US';
            
            // Map agent information
            this.contract.ARC_Selling_Agent__c = this.enrollmentInfo.containsKey('sellingAgentId') ? (Id)this.enrollmentInfo.get('sellingAgentId') : null;
            
            // Map guardian information
            this.contract.ARC_Guardian__c = this.enrollmentInfo.containsKey('guardianId') ? (Id)this.enrollmentInfo.get('guardianId') : null;
            
        } catch (Exception e) {
            System.debug('Error in mapContract: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to Contract Line Item object
     */
    private void mapContractLineItem() {
        try {
            System.debug('Mapping Contract Line Item data');
            
            this.contractLineItem = new vlocity_ins__ContractLineItem__c();
            
            // Map plan information
            this.contractLineItem.Name = this.enrollmentInfo.containsKey('productName') ? (String)this.enrollmentInfo.get('productName') : null;
            this.contractLineItem.vlocity_ins__Product2Id__c = this.enrollmentInfo.containsKey('productId') ? (Id)this.enrollmentInfo.get('productId') : null;
            this.contractLineItem.vlocity_ins__UnitPrice__c = this.enrollmentInfo.containsKey('price') ? (Decimal)this.enrollmentInfo.get('price') : null;
            this.contractLineItem.vlocity_ins__Quantity__c = 1;

            // Map effective date
            this.contractLineItem.vlocity_ins__EffectiveStartDate__c = this.enrollmentInfo.containsKey('effectiveDate') ? 
                DateTime.newInstance(Date.valueOf((String)this.enrollmentInfo.get('effectiveDate')), Time.newInstance(0, 0, 0, 0)).addDays(1) : null;
            
            // Map account information
            this.contractLineItem.vlocity_ins__AccountId__c = enrollmentInfo.containsKey('groupAccountId') ? (Id)enrollmentInfo.get('groupAccountId') : null;
            
        } catch (Exception e) {
            System.debug('Error in mapContractLineItem: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to Group Census Member Plan object
     */
    private void mapGroupCensusMemberPlan() {
        try {
            System.debug('Mapping Group Census Member Plan data');
            
            this.groupCensusMemberPlan = new vlocity_ins__GroupCensusMember__c();
            // Add mapping logic here
            
        } catch (Exception e) {
            System.debug('Error in mapGroupCensusMemberPlan: ' + e.getMessage());
            throw e;
        }
    }

     /**
     * @Description: Maps data to ARC External Insurance Policy object
     */
    private void mapExternalInsurancePolicy() {
        try {
            System.debug('Mapping ARC External Insurance Policy data');
            // Get list of new enrollment members
            List<Object> enrollmentMembersList = this.enrollmentInfo.containsKey('members') && this.enrollmentInfo.get('members') != null ? (List<Object>)this.enrollmentInfo.get('members') : new List<Object>();
            // List<Map<String,Object>> currentCoveragesList = new List<Map<String,Object>>();
            Map<String, ARC_ExternalInsurancePolicy__c> extInsPolToInsert = new Map<String, ARC_ExternalInsurancePolicy__c>();

            if (!enrollmentMembersList.isEmpty() && enrollmentMembersList.size() > 0) {
                Integer interation = 1;
                for (Object member : enrollmentMembersList) {
                    System.debug('Iteration number: ' + interation);
                    Map<String,Object> memberMap = (Map<String,Object>)member;
                    if (memberMap.containsKey('currentCoverage') && !((List<Object>)memberMap.get('currentCoverage')).isEmpty() && ((List<Object>)memberMap.get('currentCoverage')).size() > 0) {
                        System.debug('Member has current coverage!!!');
                        // List<Object> memberCurrentCoverage = (List<Object>)memberMap.get('currentCoverage');
                        for (Object coverage : (List<Object>)memberMap.get('currentCoverage')) {
                            Map<String,Object> coverageMap = (Map<String,Object>)coverage;
                            String coverageKey = (String)coverageMap.get('carrier') + '_' + (String)coverageMap.get('policyNumber');
                            System.debug('Coverage key: ' + coverageKey);
                            
                            // Add policy to insert only if it is not already in map to insert
                            if (!extInsPolToInsert.containsKey(coverageKey)) {
                                ARC_ExternalInsurancePolicy__c policy = new ARC_ExternalInsurancePolicy__c();
                                policy.ARC_InsurerName__c = (String)coverageMap.get('carrier');
                                policy.ARC_PolicyNumber__c = (String)coverageMap.get('policyNumber');
                                policy.ARC_InsurerName__c = (String)((Map<String,Object>)memberMap.get('person')).get('firstName') + ' ' + (String)((Map<String,Object>)memberMap.get('person')).get('lastName');
                                policy.ARC_InsurerPhone__c = (String)((Map<String,Object>)memberMap.get('person')).get('phone');
                                System.debug('Policy ' + interation + ': ' + policy);
                            }
                        }
                    }
                    interation++;
                }
            }
        } catch (Exception e) {
            System.debug('Error in mapExternalInsurancePolicy: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to ARC External Insurance Policy Member object
     */
    private void mapExternalInsurancePolicyMember() {
        try {
            System.debug('Mapping ARC External Insurance Policy Member data');

            ARC_ExternalInsurancePolicy__c extInsPolicy = new ARC_ExternalInsurancePolicy__c();
            // extInsPolicy.ARC_InsurerName__c = null;
            // extInsPolicy.ARC_PolicyNumber__c = null;
            // extInsPolicy.ARC_SourceOfCoverage__c = null;
            // extInsPolicy.ARC_InsurerPhone__c = null;
            // extInsPolicy.ARC_EffectiveDate__c = null;
            // extInsPolicy.ARC_ExpirationDate__c = null;


        
            
        } catch (Exception e) {
            System.debug('Error in mapExternalInsurancePolicyMember: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to Contract Participant object
     */
    private void mapContractParticipant() {
        try {
            System.debug('Mapping Contract Participant data');
            
            this.contractParticipant = new ARC_ContractParticipant__c();
            
            // Map basic member information
            this.contractParticipant.ARC_FirstName__c =this.enrollmentInfo.containsKey('firstName') ? (String)this.enrollmentInfo.get('firstName') : null;
            this.contractParticipant.ARC_LastName__c = this.enrollmentInfo.containsKey('lastName') ? (String)this.enrollmentInfo.get('lastName') : null;
            this.contractParticipant.Name = (this.enrollmentInfo.containsKey('firstName') && this.enrollmentInfo.containsKey('lastName')) ? 
                (String)this.enrollmentInfo.get('firstName') + ' ' + (String)this.enrollmentInfo.get('lastName') : null;
            this.contractParticipant.ARC_Email__c = this.enrollmentInfo.containsKey('email') ? (String)this.enrollmentInfo.get('email') : null;
            this.contractParticipant.ARC_Phone__c = this.enrollmentInfo.containsKey('phone') ? (String)this.enrollmentInfo.get('phone') : null;
            this.contractParticipant.ARC_BirthDate__c = this.enrollmentInfo.containsKey('birthdate') ? Date.valueOf((String)this.enrollmentInfo.get('birthdate')) : null;
            this.contractParticipant.ARC_Gender__c = this.enrollmentInfo.containsKey('gender') ? (String)this.enrollmentInfo.get('gender') : null;
            this.contractParticipant.ARC_Relationship__c = this.enrollmentInfo.containsKey('relationship') ? (String)this.enrollmentInfo.get('relationship') : null;
            this.contractParticipant.ARC_Smoker__c = this.enrollmentInfo.containsKey('smoker') ? convertToBoolean(this.enrollmentInfo.get('smoker')) : null;
            
            // Map address information
            this.contractParticipant.ARC_Address__CountryCode__s = 'US';
            this.contractParticipant.ARC_Address__Street__s = this.enrollmentInfo.containsKey('addressStreet') ? (String)this.enrollmentInfo.get('addressStreet') : null;
            this.contractParticipant.ARC_Address__City__s = this.enrollmentInfo.containsKey('addressCity') ? (String)this.enrollmentInfo.get('addressCity') : null;
            this.contractParticipant.ARC_Address__StateCode__s = this.enrollmentInfo.containsKey('addressState') ? String.valueOf(this.enrollmentInfo.get('addressState')).toUpperCase() : null;
            this.contractParticipant.ARC_Address__PostalCode__s = this.enrollmentInfo.containsKey('addressZipCode') ? (String)this.enrollmentInfo.get('addressZipCode') : null;
            
            // Map physical attributes
            this.contractParticipant.ARC_Height__c = (this.enrollmentInfo.containsKey('heightFeet') && this.enrollmentInfo.containsKey('heightInches')) ? 
                String.valueOf(this.enrollmentInfo.get('heightFeet')) + '\'' + String.valueOf(this.enrollmentInfo.get('heightInches')) : null;
            this.contractParticipant.ARC_Weight__c = this.enrollmentInfo.containsKey('weight') ? String.valueOf(this.enrollmentInfo.get('weight')) : null;
            
        } catch (Exception e) {
            System.debug('Error in mapContractParticipant: ' + e.getMessage());
            throw e;
        }
    }
    
       /**
     * @Description: Maps data to Chargent Order object
     */
    private void mapChargentOrder() {
        try {
            System.debug('Mapping Chargent Order data');
            
            ChargentOrders__ChargentOrder__c appFeeOrder = new ChargentOrders__ChargentOrder__c();

            Map<String,Object> generalInfo = this.enrollmentInfo.containsKey('generalInformation') && this.enrollmentInfo.get('generalInformation') != null ? (Map<String,Object>)this.enrollmentInfo.get('generalInformation') : null;

            if (generalInfo.containsKey('payment') && generalInfo.get('payment') != null) {
                //Get all payment information map from JSON
                Map<String,Object> paymentInfo = (Map<String,Object>)generalInfo.get('payment');
                // Get which payment method selected
                String paymentMethod = paymentInfo.get('paymentMethod') == 'credit_card' ? 'Credit Card' : paymentInfo.get('paymentMethod') == 'bank_account' ? 'Bank Account' : null;
                // Get specific method information depending if method is credit card or bank account
                Map<String,Object> paymentMethodMap = paymentMethod == 'Credit Card' ? (Map<String,Object>)paymentInfo.get('creditCard') : paymentMethod == 'Bank Account' ? (Map<String,Object>)paymentInfo.get('bankAccount') : new Map<String,Object>();

                // Get billing Address Map from JSON
                Map<String,Object> billingAddressMap = paymentMethodMap.containsKey('billingAddress') && paymentMethodMap.get('billingAddress') != null ? (Map<String,Object>)paymentMethodMap.get('billingAddress') : new Map<String,Object>();
                // Get primary address information when payment method is Bank Account
                if (paymentMethod == 'Bank Account' && billingAddressMap.isEmpty()) {
                    List<Object> members = this.enrollmentInfo.containsKey('members') && this.enrollmentInfo.get('members') != null ? (List<Object>)this.enrollmentInfo.get('members') : null;
                    if (members != null && !members.isEmpty()) {
                        for (Object member : members) {
                            Map<String,Object> memberMap = (Map<String,Object>)member;
                            if (memberMap.containsKey('role') && memberMap.get('role') == 'Primary') {
                                billingAddressMap = (Map<String,Object>)((Map<String,Object>)memberMap.get('person')).get('address');
                            }
                        }
                    }
                }
                System.debug('Billing address map: ' + billingAddressMap);

                // App fee order general information mapping
                appFeeOrder.ChargentOrders__Payment_Method__c = paymentMethod;
                appFeeOrder.ChargentOrders__Description__c = 'App Fee';
                appFeeOrder.ARC_FirstMonthPayed__c = false;
                appFeeOrder.ChargentOrders__Subtotal__c = (Integer)paymentInfo.get('fee');
                appFeeOrder.ChargentOrders__Charge_Amount__c = (Integer)paymentInfo.get('fee');
                appFeeOrder.ChargentOrders__Payment_Frequency__c = 'Once';
                appFeeOrder.ChargentOrders__Manual_Charge__c = false;
                appFeeOrder.ChargentOrders__Payment_Status__c = null;
                appFeeOrder.ChargentOrders__Payment_Start_Date__c = paymentInfo.get('feeFuturePaymentDate') != null && paymentInfo.get('feeFuturePaymentDate') != '' ? Date.valueOf((String)paymentInfo.get('feeFuturePaymentDate')) : null;
                appFeeOrder.ChargentOrders__Billing_First_Name__c = (String)paymentMethodMap.get('firstName');
                appFeeOrder.ChargentOrders__Billing_Last_Name__c = (String)paymentMethodMap.get('lastName');
                
                // Address mapping
                appFeeOrder.ChargentOrders__Billing_Address__c = (String)billingAddressMap.get('street');
                appFeeOrder.ChargentOrders__Billing_Address_Line_2__c = (String)billingAddressMap.get('unit');
                appFeeOrder.ChargentOrders__Billing_City__c = (String)billingAddressMap.get('city') ;
                appFeeOrder.ChargentOrders__Billing_State__c = (String)billingAddressMap.get('state');
                appFeeOrder.ChargentOrders__Billing_Zip_Postal__c = (String)billingAddressMap.get('zip');


                // CREDIT CARD
                appFeeOrder.ChargentOrders__Card_Number__c = paymentMethod == 'Credit Card' ? (String)paymentMethodMap.get('cardNumber') : null;
                appFeeOrder.ChargentOrders__Card_Expiration_Month__c = paymentMethod == 'Credit Card' ? (String)paymentMethodMap.get('expirationMonth') : null;
                appFeeOrder.ChargentOrders__Card_Month_Indicator__c = paymentMethod == 'Credit Card' ? (String)paymentMethodMap.get('expirationMonth') : null;
                appFeeOrder.ChargentOrders__Card_Expiration_Year__c = paymentMethod == 'Credit Card' ? (String)paymentMethodMap.get('expirationYear') : null;
                appFeeOrder.ChargentOrders__Card_Year_Indicator__c = paymentMethod == 'Credit Card' ? (String)paymentMethodMap.get('expirationYear') : null;
                appFeeOrder.ChargentOrders__Card_Last_4__c = paymentMethod == 'Credit Card' ? ((String)paymentMethodMap.get('cardNumber')).right(4) : null;

                // BANK ACCOUNT
                appFeeOrder.ChargentOrders__Bank_Routing_Number__c = paymentMethod == 'Bank Account' ? String.valueOf(paymentMethodMap.get('routingNumber')) : null;
                appFeeOrder.ChargentOrders__Bank_Account_Number__c = paymentMethod == 'Bank Account' ? String.valueOf(paymentMethodMap.get('accountNumber')) : null;
                appFeeOrder.ChargentOrders__Bank_Name__c = paymentMethod == 'Bank Account' ? (String)paymentMethodMap.get('bankName') : null;
                appFeeOrder.ChargentOrders__Bank_Account_Type__c = paymentMethod == 'Bank Account' ? (String)paymentMethodMap.get('accountType') : null;
                appFeeOrder.ChargentOrders__Bank_Account_Name__c = paymentMethod == 'Bank Account' ? (String)paymentMethodMap.get('firstName') + ' ' + (String)paymentMethodMap.get('lastName') : null;

                // Get Gateway IDs for Credit Card and Bank Account payment methods
                Id gatewayIdCC = null;
                Id gatewayIdBA = null;
                List<ChargentBase__Gateway__c>  gateways = [SELECT Id, ChargentBase__Available_Payment_Methods__c  FROM ChargentBase__Gateway__c  WHERE ChargentBase__Active__c = true AND ChargentBase__Use_Tokenization__c = true AND ( ChargentBase__Available_Payment_Methods__c INCLUDES ('Credit Card') OR ChargentBase__Available_Payment_Methods__c INCLUDES ('Bank Account'))];
                for(ChargentBase__Gateway__c gateway : gateways){
                    gatewayIdCC = gateway.ChargentBase__Available_Payment_Methods__c.contains('Credit Card') ? gateway.Id : gatewayIdCC;
                    gatewayIdBA = gateway.ChargentBase__Available_Payment_Methods__c.contains('Bank Account') ? gateway.Id : gatewayIdBA;
                }
                appFeeOrder.ChargentOrders__Gateway__c = paymentMethod == 'Credit Card' ? gatewayIdCC : paymentMethod == 'Bank Account' ? gatewayIdBA : null;

                System.debug('App Fee in Mapper: ' + appFeeOrder);
                manager.appFeeOrderToInsert = appFeeOrder;
            }
        } catch (Exception e) {
            System.debug('Error in mapChargentOrder: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to UW Case object
     */
    private void mapUWCase() {
        try {
            System.debug('Mapping UW Case data');
            
            this.uwCase = new Case();
            this.uwCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admission').getRecordTypeId();
            
            // Map case information
            this.uwCase.ARC_Reason__c = 'Underwriting';
            this.uwCase.Case_Type__c = 'Underwriting';
            this.uwCase.Description = 'Underwriting';
            this.uwCase.Origin = 'Internal Enrollment';
            this.uwCase.Subject = 'Underwriting';
            this.uwCase.Type = 'Program Change';
            this.uwCase.Status = 'Draft';
            
            // Map account information
            this.uwCase.AccountId = this.enrollmentInfo.containsKey('groupAccountId') ? (Id)this.enrollmentInfo.get('groupAccountId') : null;
            
            // Map owner information
            this.uwCase.OwnerId = this.enrollmentInfo.containsKey('userId') ? (Id)this.enrollmentInfo.get('userId') : null;
            
        } catch (Exception e) {
            System.debug('Error in mapUWCase: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to UW Case Members object
     */
    private void mapUWCaseMember() {
        try {
            System.debug('Mapping UW Case Member data');
            
            this.uwCaseMember = new ARC_UnderwritingCaseMember__c();
            
            // Map member information
            this.uwCaseMember.Name = (this.enrollmentInfo.containsKey('firstName') && this.enrollmentInfo.containsKey('lastName')) ? 
                (String)this.enrollmentInfo.get('firstName') + ' ' + (String)this.enrollmentInfo.get('lastName') : null;
            
            this.uwCaseMember.ARC_Reason__c = 'Add Member';
            this.uwCaseMember.ARC_ApprovalResolution__c = 'Pending';
            
        } catch (Exception e) {
            System.debug('Error in mapUWCaseMember: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to HIPPA object
     */
    private void mapHIPPA() {
        try {
            System.debug('Mapping HIPPA data');
            
            this.hippa = new ARC_HipaaAuthorization__c();
            
            // Map authorization information
            this.hippa.Name = (this.enrollmentInfo.containsKey('firstName') && this.enrollmentInfo.containsKey('lastName')) ? 
                (String)this.enrollmentInfo.get('firstName') + ' ' + (String)this.enrollmentInfo.get('lastName') : null;
            
            // Map census information
            this.hippa.ARC_Census__c = this.enrollmentInfo.containsKey('censusId') ? (Id)this.enrollmentInfo.get('censusId') : null;
            
        } catch (Exception e) {
            System.debug('Error in mapHIPPA: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to Medical Questions object
     */
    private void mapMedicalQuestion() {
        try {
            System.debug('Mapping Medical Questions data');
            
            this.medicalQuestion = new ARC_MedicalConditions__c();
            
            // Map medical condition information
            this.medicalQuestion.Name = (this.enrollmentInfo.containsKey('firstName') && this.enrollmentInfo.containsKey('lastName')) ? 
                ((String)this.enrollmentInfo.get('firstName') + ' ' + (String)this.enrollmentInfo.get('lastName')).length() > 60 ? 
                    ((String)this.enrollmentInfo.get('firstName') + ' ' + (String)this.enrollmentInfo.get('lastName')).substring(0, 60) + '-Medical Condition' :
                    (String)this.enrollmentInfo.get('firstName') + ' ' + (String)this.enrollmentInfo.get('lastName') + '-Medical Condition' : null;
            
            this.medicalQuestion.ARC_Active__c = true;
            
            // Map medical condition details if available
            this.medicalQuestion.ARC_Condition__c = this.enrollmentInfo.containsKey('medicalConditions') ? (String)this.enrollmentInfo.get('medicalConditions') : null;
            this.medicalQuestion.ARC_OtherConditions__c = this.enrollmentInfo.containsKey('otherConditions') ? (String)this.enrollmentInfo.get('otherConditions') : null;
            this.medicalQuestion.ARC_Currently_Under_Treatment__c = this.enrollmentInfo.containsKey('hasCancer') ? convertToBoolean(this.enrollmentInfo.get('hasCancer')) : null;
            this.medicalQuestion.ARC_Type_Of_Cancer__c = this.enrollmentInfo.containsKey('cancerType') ? (String)this.enrollmentInfo.get('cancerType') : null;
            this.medicalQuestion.ARC_Year_Diagnosed_Cancer__c = this.enrollmentInfo.containsKey('cancerDiagnosisDate') ? Date.valueOf((String)this.enrollmentInfo.get('cancerDiagnosisDate')) : null;
            
        } catch (Exception e) {
            System.debug('Error in mapMedicalQuestion: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @Description: Gets all mapped objects for validation
     * @return List<SObject>: List of all mapped objects
     */
    public List<SObject> getAllMappedObjects() {
        List<SObject> objects = new List<SObject>();
        
        if (this.census != null) objects.add(this.census); 
        //if (this.censusMembers != null) objects.add(this.censusMembers);
        //if (this.personAccounts != null) objects.add(this.personAccounts);
        if (this.groupAccount != null) objects.add(this.groupAccount);
        if (this.contract != null) objects.add(this.contract);
        if (this.contractLineItem != null) objects.add(this.contractLineItem);
        if (this.groupCensusMemberPlan != null) objects.add(this.groupCensusMemberPlan);
        if (this.externalInsurancePolicyMember != null) objects.add(this.externalInsurancePolicyMember);
        if (this.contractParticipant != null) objects.add(this.contractParticipant);
        if (this.chargentOrder != null) objects.add(this.chargentOrder);
        if (this.uwCase != null) objects.add(this.uwCase);
        if (this.uwCaseMember != null) objects.add(this.uwCaseMember);
        if (this.hippa != null) objects.add(this.hippa);
        if (this.medicalQuestion != null) objects.add(this.medicalQuestion);
        
        return objects;
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
}