/**
 * @Description: Mapper class for Self Enrollment Flow operations.
 * This class handles the mapping of enrollment data to Salesforce objects.
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-01-27
 * @Version: 1.0
 */
global without sharing class ARC_SEMapper {
    
    // Mapped objects\
    public Map<String, Object> enrollmentInfo { get; set; }
    public vlocity_ins__GroupCensus__c census { get; set; }
    public List<vlocity_ins__GroupCensusMember__c> censusMembers { get; set; }
    public List<Account> personAccounts { get; set; }
    public Account groupAccount { get; set; }
    // public Contract contract { get; set; }
    // public vlocity_ins__ContractLineItem__c contractLineItem { get; set; }
    // public vlocity_ins__GroupCensusMember__c groupCensusMemberPlan { get; set; }
    // public ARC_ExternalInsurancePolicyMember__c externalInsurancePolicyMember { get; set; }
    // public ARC_ContractParticipant__c contractParticipant { get; set; }
    // public ChargentOrders__ChargentOrder__c chargentOrder { get; set; }
    public Case uwCase { get; set; }
    public Case onboardingCase { get; set; }
    // public ARC_UnderwritingCaseMember__c uwCaseMember { get; set; }
    // public ARC_HipaaAuthorization__c hippa { get; set; } 
    // public ARC_MedicalConditions__c medicalQuestion { get; set; }
    
    public ARC_SEManager manager;

    /**
     * @Description: Main method to map enrollment data to Salesforce objects
     * @param enrollmentInfo: Map containing enrollment information
     * @param memberData: Map containing member data
     * @param planData: Map containing plan data
     */
    public void mapEnrollmentData(ARC_SEManager manager) {
        try {
            this.manager = manager;
            this.enrollmentInfo = manager.enrollmentInfo;
            System.debug('Starting data mapping for Self Enrollment');
            
            // Map each object
            mapSellingAgent();
            mapCensus();
            mapCensusMembers();
            mapBeneficiaries();
            mapPersonAccounts();
            mapGroupAccount();
            mapGuardian();
            mapContract();
            mapContractLineItem();
            mapExternalInsurancePolicyMember();
            mapContractParticipant();
            mapChargentOrder();
            mapUWCase();
            mapUWCaseMember();
            mapOnboardingCase();
            mapPromotionDiscount();
            mapCriticalCarePromotionDiscount();
            mapHIPPA();
            mapMedicalQuestion();
            
            System.debug('Data mapping completed successfully');
            
        } catch (Exception e) {
            System.debug('Error in mapEnrollmentData: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    private void mapSellingAgent(){
        try{
            Map<String, Object> generalInformation = (Map<String, Object>)this.enrollmentInfo.get('generalInformation');
            // Map agent information
            if (generalInformation.containsKey('hadAssistance')) {
                Map<String, Object> hadAssistance = (Map<String, Object>)generalInformation.get('hadAssistance');
                if (hadAssistance.containsKey('agentId') && hadAssistance.get('agentId') != null && (String)hadAssistance.get('agentId') != '') {
                    manager.sellingAgentId = (Id)hadAssistance.get('agentId');
                } else {
                    manager.sellingAgentId = null;
                }
            }
            else{
                manager.sellingAgentId = null;
            }
        } catch (Exception e) {
            System.debug('Error in mapCensus: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
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
            String primaryMemberIdentifier;
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
                if(address.containsKey('unit') && address.get('unit') != null && (String)address.get('unit') != ''){
                    member.ARC_PhysicalAddressStreet__c = member.ARC_PhysicalAddressStreet__c + ' Apt/Unit ' + (String)address.get('unit');
                }
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
                member.vlocity_ins__MemberIdentifier__c = String.valueOf(Datetime.now().getTime()) + '-' + String.valueOf(Math.random());
                if ((String)memberInfo.get('role') == 'Primary') {
                    primaryMemberIdentifier = member.vlocity_ins__MemberIdentifier__c;
                }
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
                if (memberInfo.containsKey('beneficiaries')) {
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
            System.debug('Mapping Person Account data');

            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();

            this.personAccounts = new List<Account>();
            List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
            for (Object memberInfo_obj : members) {
                Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
                Map<String, Object> person = (Map<String, Object>)memberInfo.get('person');
                String role = (String)memberInfo.get('role');
                Account account = new Account();
                account.RecordTypeId = recordTypeId;
                account.FirstName = person.containsKey('firstName') ? (String)person.get('firstName') : null;
                account.LastName = person.containsKey('lastName') ? (String)person.get('lastName') : null;
                if(role == 'Primary' && person.containsKey('medicareId')){
                    account.Medicare_ID__c = (String)person.get('medicareId');
                    if(person.containsKey('medicarePartA') && (Boolean) person.get('medicarePartA')) account.Medicare_Part_A_Effective_Date__c = person.containsKey('medicareEffectiveDate A') ? Date.valueOf((String)person.get('medicareEffectiveDate A')) : null;
                    if(person.containsKey('medicarePartB') && (Boolean) person.get('medicarePartB')) account.Medicare_Part_B_Effective_Date__c = person.containsKey('medicareEffectiveDate B') ? Date.valueOf((String)person.get('medicareEffectiveDate B')) : null;
                    if(person.containsKey('medicarePartD') && (Boolean) person.get('medicarePartD')) account.Medicare_Part_D_Effective_Date__c = person.containsKey('medicareEffectiveDate D') ? Date.valueOf((String)person.get('medicareEffectiveDate D')) : null;
                }
                //Owner Selling Agent
                if (manager.sellingAgentId != null) {
                    account.OwnerId = manager.sellingAgentId;
                } 
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
            //Owner Selling Agent
            if (manager.sellingAgentId != null) {
                this.groupAccount.OwnerId = manager.sellingAgentId;
            } 
            
            // Map address information (typically same as primary member)
            Map<String, Object> generalInformation = (Map<String, Object>)this.enrollmentInfo.get('generalInformation');
            Map<String, Object> payment = (Map<String, Object>)generalInformation.get('payment');
            Map<String, Object> billingAddress;
            if ((String)payment.get('paymentMethod') == 'credit_card') {
                Map<String, Object> creditCard = (Map<String, Object>)payment.get('creditCard');
                billingAddress = (Map<String, Object>)creditCard.get('billingAddress');
                this.groupAccount.BillingStreet = billingAddress.containsKey('street') ? (String)billingAddress.get('street') : null;
                this.groupAccount.BillingStreet = billingAddress.containsKey('unit') ? this.groupAccount.BillingStreet + ' ' + (String)billingAddress.get('unit') : this.groupAccount.BillingStreet;
                this.groupAccount.BillingCity = billingAddress.containsKey('city') ? (String)billingAddress.get('city') : null;
                this.groupAccount.BillingState = billingAddress.containsKey('state') ? String.valueOf(billingAddress.get('state')).toUpperCase() : null;
                this.groupAccount.BillingPostalCode = billingAddress.containsKey('zip') ? (String)billingAddress.get('zip') : null;
                this.groupAccount.BillingCountry = 'United States';
            } else if ((String)payment.get('paymentMethod') == 'bank_account') {
                Map<String, Object> bankAccount = (Map<String, Object>)payment.get('bankAccount');
                billingAddress = (Map<String, Object>)primaryMemberInfo.get('address');
                this.groupAccount.BillingStreet = billingAddress.containsKey('street') ? (String)billingAddress.get('street') : null;
                this.groupAccount.BillingStreet = billingAddress.containsKey('unit') ? this.groupAccount.BillingStreet + ' ' + (String)billingAddress.get('unit') : this.groupAccount.BillingStreet;
                this.groupAccount.BillingCity = billingAddress.containsKey('city') ? (String)billingAddress.get('city') : null;
                this.groupAccount.BillingState = billingAddress.containsKey('state') ? String.valueOf(billingAddress.get('state')).toUpperCase() : null;
                this.groupAccount.BillingPostalCode = billingAddress.containsKey('zip') ? (String)billingAddress.get('zip') : null;
                this.groupAccount.BillingCountry = 'United States';                
            }

            
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

            // System.debug('Guardian First Name: ' + ((Map<String,Object>)generalInfo.get('guardian')).get('firstName') + ' ' + ((Map<String,Object>)generalInfo.get('guardian')).get('lastName'));
            boolean guardianExists = false;
            if (generalInfo.containsKey('guardian') && generalInfo.get('guardian') != null && ((Map<String,Object>)generalInfo.get('guardian')).get('firstName') != null && ((Map<String,Object>)generalInfo.get('guardian')).get('firstName') != '') {
                guardianExists = true;
            }
            System.debug('Guardian Exists: ' + guardianExists);
            if (guardianExists) {
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
            
            Map<String, Object> generalInformation = (Map<String, Object>)this.enrollmentInfo.get('generalInformation');
            Map<String, Object> primaryMemberInfo = getPrimaryMemberInfo();
            Map<String, Object> address = (Map<String, Object>)primaryMemberInfo.get('address');

            Contract contract = new Contract(); 
            
            // Set record type
            contract.RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_IndividualAndFamily').getRecordTypeId();
            
            // Map enrollment information
            contract.ARC_EffectiveDate__c = generalInformation.containsKey('effectiveDate') ? Date.valueOf((String)generalInformation.get('effectiveDate')) : null;
            contract.StartDate = generalInformation.containsKey('effectiveDate') ? Date.valueOf((String)generalInformation.get('effectiveDate')) : null;
            contract.ContractTerm = 12;
            contract.Status = 'Draft';
            
            // Map contract reason
            contract.ARC_ContractReason__c = 'New Application';
            
            // Map address information from primary member
            contract.ARC_PrimaryAddress__Street__s = address.containsKey('street') ? (String)address.get('street') : null;
            contract.ARC_PrimaryAddress__City__s = address.containsKey('city') ? (String)address.get('city') : null;
            contract.ARC_PrimaryAddress__StateCode__s = address.containsKey('state') ? String.valueOf(address.get('state')).toUpperCase() : null;
            contract.ARC_PrimaryAddress__PostalCode__s = address.containsKey('zip') ? (String)address.get('zip') : null;
            contract.ARC_PrimaryAddress__CountryCode__s = 'US';
            
            // Map agent information
            if (manager.sellingAgentId != null) {
                contract.ARC_Selling_Agent__c = manager.sellingAgentId;
                contract.OwnerId = manager.sellingAgentId;
            } else {
                User guestUser = [SELECT Id FROM User WHERE Name = 'Member Community Site Guest User' LIMIT 1];
                contract.ARC_Selling_Agent__c = guestUser.Id;
            }
            this.manager.contract = contract;
            
        } catch (Exception e) {
            System.debug('Error in mapContract: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to Contract Line Item object
     */
    private void mapContractLineItem() {
        try {
            System.debug('Mapping Contract Line Item data');
            
            // Medical Product Mapping
            Map<String, Object> generalInformation = (Map<String, Object>)this.enrollmentInfo.get('generalInformation');
            Map<String, Object> medicalProgram = (Map<String, Object>)generalInformation.get('medicalProgram');
            Set<Id> parentProductIds = new Set<Id>();

            vlocity_ins__ContractLineItem__c contractLineItem = new vlocity_ins__ContractLineItem__c();
            
            contractLineItem.Name = medicalProgram.containsKey('name') ? (String)medicalProgram.get('name') : null;
            contractLineItem.vlocity_ins__Product2Id__c = medicalProgram.containsKey('productId') ? (Id)medicalProgram.get('productId') : null;
            contractLineItem.vlocity_ins__UnitPrice__c = medicalProgram.containsKey('price') ? (Decimal)medicalProgram.get('price') : null;
            contractLineItem.vlocity_ins__Quantity__c = 1;
            contractLineItem.vlocity_ins__EffectiveStartDate__c = this.enrollmentInfo.containsKey('effectiveDate') ? 
                DateTime.newInstance(Date.valueOf((String)this.enrollmentInfo.get('effectiveDate')), Time.newInstance(0, 0, 0, 0)).addDays(1) : null;
            parentProductIds.add(contractLineItem.vlocity_ins__Product2Id__c);
            
            this.manager.indexToParentCLIToInsert.put('ParentMedical', contractLineItem);
            List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
            this.manager.indexToMemberIds.put('ParentMedical', new List<String>());

            // Ancillary Product Mapping
            for (Object memberInfo_obj : members) {
                Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
                String memberExternalId = (String)memberInfo.get('memberExternalId');
                this.manager.indexToMemberIds.get('ParentMedical').add(memberExternalId);

                if (memberInfo.containsKey('ancillaryCarePrograms')) {
                    List<Object> ancillaryCarePrograms = (List<Object>)memberInfo.get('ancillaryCarePrograms');
                    if (ancillaryCarePrograms.isEmpty()) continue;
                    String role = (String)memberInfo.get('role');
                    for (Object ancillary_obj : ancillaryCarePrograms) {
                        Map<String, Object> ancillary = (Map<String, Object>)ancillary_obj;

                        Boolean shareAncillary = ancillary.containsKey('share') ? (Boolean)ancillary.get('share') : false;

                        String ancillaryKey;
                        String productCode = (String)ancillary.get('productCode');

                        if(shareAncillary == true){
                            ancillaryKey = 'Share';
                        } else {
                            ancillaryKey = 'Parent';
                            if (role == 'Primary' || role == 'Spouse') {
                                ancillaryKey += role;
                            } else if (productCode == 'PROG_CriticalCare' || productCode == 'PROG_AccidentalInjury') {
                                ancillaryKey += memberExternalId;
                            } else {
                                ancillaryKey += (String)ancillary.get('relatedTo');
                            }
                        }
                        ancillaryKey += (String)ancillary.get('productCode');

                        if (!this.manager.indexToParentCLIToInsert.containsKey(ancillaryKey)) {
                            vlocity_ins__ContractLineItem__c contractLineItemAncillary = new vlocity_ins__ContractLineItem__c();

                            contractLineItemAncillary.Name = ancillary.containsKey('planName') ? (String)ancillary.get('planName') : null;
                            contractLineItemAncillary.vlocity_ins__Product2Id__c = ancillary.containsKey('id') ? (Id)ancillary.get('id') : null;
                            contractLineItemAncillary.vlocity_ins__UnitPrice__c = ancillary.containsKey('basePrice') ? (Decimal)ancillary.get('basePrice') : null;
                            contractLineItemAncillary.vlocity_ins__Quantity__c = 1;
                            contractLineItemAncillary.vlocity_ins__EffectiveStartDate__c = this.enrollmentInfo.containsKey('effectiveDate') ? 
                            DateTime.newInstance(Date.valueOf((String)this.enrollmentInfo.get('effectiveDate')), Time.newInstance(0, 0, 0, 0)).addDays(1) : null;
                            parentProductIds.add(contractLineItemAncillary.vlocity_ins__Product2Id__c);

                            this.manager.indexToParentCLIToInsert.put(ancillaryKey, contractLineItemAncillary);
                            this.manager.indexToMemberIds.put(ancillaryKey, new List<String>());
                        }
                        this.manager.indexToMemberIds.get(ancillaryKey).add(memberExternalId);
                    }
                }
            }

            // Child Product Mapping
            List<vlocity_ins__ProductChildItem__c> pciList = [
                SELECT Id, vlocity_ins__ParentProductId__c, vlocity_ins__ChildProductId__r.Id, vlocity_ins__ChildProductId__r.Name
                FROM vlocity_ins__ProductChildItem__c
                WHERE vlocity_ins__ParentProductId__c IN :parentProductIds
                AND vlocity_ins__ChildProductId__r.RecordType.Name = 'Coverage Spec'
            ];
            Map<Id, List<Product2>> productIdToChildProduct = new Map<Id, List<Product2>>();
            Map<String, vlocity_ins__ProductChildItem__c> productParentChildIdToPCI = new Map<String, vlocity_ins__ProductChildItem__c>();
            for (vlocity_ins__ProductChildItem__c pci : pciList) {
                if (!productIdToChildProduct.containsKey(pci.vlocity_ins__ParentProductId__c)) {
                    productIdToChildProduct.put(pci.vlocity_ins__ParentProductId__c, new List<Product2>());
                }
                productIdToChildProduct.get(pci.vlocity_ins__ParentProductId__c).add(pci.vlocity_ins__ChildProductId__r);
                String parentChildKey = pci.vlocity_ins__ParentProductId__c + '-' + pci.vlocity_ins__ChildProductId__r.Id;
                productParentChildIdToPCI.put(parentChildKey, pci);
            }
            for (String key : this.manager.indexToParentCLIToInsert.keySet()) {
                vlocity_ins__ContractLineItem__c parentCLI = this.manager.indexToParentCLIToInsert.get(key);
                for (Product2 childProduct : productIdToChildProduct.get(parentCLI.vlocity_ins__Product2Id__c)) {
                    vlocity_ins__ContractLineItem__c childCLI = new vlocity_ins__ContractLineItem__c();
                    childCLI.Name = childProduct.Name;
                    childCLI.vlocity_ins__ProductId__c = parentCLI.vlocity_ins__Product2Id__c;
                    childCLI.vlocity_ins__Product2Id__c = childProduct.Id;
                    String parentChildKey = childCLI.vlocity_ins__ProductId__c + '-' + childCLI.vlocity_ins__Product2Id__c;
                    childCLI.vlocity_ins__ProductChildItemId__c = productParentChildIdToPCI.get(parentChildKey).Id;
                    if (!this.manager.indexToChildCLIToInsert.containsKey(key)) {
                        this.manager.indexToChildCLIToInsert.put(key, new List<vlocity_ins__ContractLineItem__c>());
                    }
                    this.manager.indexToChildCLIToInsert.get(key).add(childCLI);
                }
            }
        } catch (Exception e) {
            System.debug('Error in mapContractLineItem: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
/**
     * @Description: Maps data to ARC External Insurance Policy and Policy Member object
     */
    private void mapExternalInsurancePolicyMember() {
        try {
            System.debug('Mapping ARC External Insurance Policy data');
            // Get list of new enrollment members
            List<Object> enrollmentMembersList = this.enrollmentInfo.containsKey('members') && this.enrollmentInfo.get('members') != null ? (List<Object>)this.enrollmentInfo.get('members') : new List<Object>();

            if (!enrollmentMembersList.isEmpty() && enrollmentMembersList.size() > 0) {
                for (Object member : enrollmentMembersList) {
                    Map<String,Object> memberMap = (Map<String,Object>)member;
                    String memberExternalId = (String)memberMap.get('memberExternalId');

                    if (memberMap.containsKey('currentCoverage') && !((List<Object>)memberMap.get('currentCoverage')).isEmpty() && ((List<Object>)memberMap.get('currentCoverage')).size() > 0) {
                        for (Object coverage : (List<Object>)memberMap.get('currentCoverage')) {

                            Map<String,Object> coverageMap = (Map<String,Object>)coverage;
                            String coverageKey = (String)coverageMap.get('carrier') + '_' + (String)coverageMap.get('policyNumber');
                            
                            // Instance new policy to insert only if it is not already in map of policies
                            if (!manager.externalPoliciesToInsert.containsKey(coverageKey)) {
                                ARC_ExternalInsurancePolicy__c externalPolicy = new ARC_ExternalInsurancePolicy__c();
                                externalPolicy.ARC_InsurerName__c = (String)coverageMap.get('carrier');
                                externalPolicy.ARC_PolicyNumber__c = (String)coverageMap.get('policyNumber');
                                externalPolicy.ARC_InsurerPhone__c = (String)coverageMap.get('carrierPhone'); // PENDING TO ADD TO JSON INPUT
                                externalPolicy.ARC_EffectiveDate__c = (String)coverageMap.get('effectiveDate') != null && (String)coverageMap.get('effectiveDate') != '' ? Date.valueOf((String)coverageMap.get('effectiveDate')) : null; // PENDING TO ADD TO JSON INPUT
                                externalPolicy.ARC_ExpirationDate__c = (String)coverageMap.get('expirationDate') != null && (String)coverageMap.get('expirationDate') != '' ? Date.valueOf((String)coverageMap.get('expirationDate')) : null; // PENDING TO ADD TO JSON INPUT
                                externalPolicy.ARC_SourceOfCoverage__c = (String)coverageMap.get('coverageSource'); // PENDING TO ADD TO JSON INPUT

                                // Add the ext policy to map to insert with coverage key as key
                                manager.externalPoliciesToInsert.put(coverageKey,externalPolicy);
                            }

                            // Add member external Id to Policy to Member map (If key is not in the map, put it and instance a new list and then add it)
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
     * @Description: Maps data to Contract Participant object
     */
    private void mapContractParticipant() {
        try {
            System.debug('Mapping Contract Participant data');
            
            List<Object> members = (List<Object>)this.enrollmentInfo.get('members');

            for (Object memberInfo_obj : members) {
                Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
                Map<String, Object> person = (Map<String, Object>)memberInfo.get('person');
                ARC_ContractParticipant__c contractParticipantTemp = new ARC_ContractParticipant__c();

                // Map basic member information
                contractParticipantTemp.ARC_FirstName__c = person.containsKey('firstName') ? (String)person.get('firstName') : null;
                contractParticipantTemp.ARC_LastName__c = person.containsKey('lastName') ? (String)person.get('lastName') : null;
                contractParticipantTemp.Name = (person.containsKey('firstName') && person.containsKey('lastName')) ? 
                    (String)person.get('firstName') + ' ' + (String)person.get('lastName') : null;

                contractParticipantTemp.ARC_Email__c = person.containsKey('email') ? (String)person.get('email') : null;
                contractParticipantTemp.ARC_Phone__c = person.containsKey('phone') ? (String)person.get('phone') : null;
                contractParticipantTemp.ARC_BirthDate__c = person.containsKey('dob') ? Date.valueOf((String)person.get('dob')) : null;
                contractParticipantTemp.ARC_Gender__c = person.containsKey('gender') ? (String)person.get('gender') : null;
                contractParticipantTemp.ARC_Relationship__c = memberInfo.containsKey('role') ? (String)memberInfo.get('role') : null;
                contractParticipantTemp.ARC_Smoker__c = person.containsKey('smoker') ? convertToBoolean(person.get('smoker')) : null;
                
                // Map address information
                Object personAddressObj = (Object)person.get('address');
                if (personAddressObj instanceof Map<String, Object>) {
                    contractParticipantTemp.ARC_Address__CountryCode__s = 'US';
                    Map<String, Object> personAddress = (Map<String, Object>)personAddressObj;
                    contractParticipantTemp.ARC_Address__Street__s = personAddress.containsKey('street') ? (String)personAddress.get('street') : null;
                    contractParticipantTemp.ARC_Address__City__s = personAddress.containsKey('city') ? (String)personAddress.get('city') : null;
                    contractParticipantTemp.ARC_Address__StateCode__s = personAddress.containsKey('state') ? String.valueOf(personAddress.get('state')).toUpperCase() : null;
                    contractParticipantTemp.ARC_Address__PostalCode__s = personAddress.containsKey('zip') ? (String)personAddress.get('zip') : null;
                }
                
                
                // Map physical attributes
                contractParticipantTemp.ARC_Height__c = (person.containsKey('heightFeet') && person.containsKey('heightInches')) ? 
                    String.valueOf(person.get('heightFeet')) + '\'' + String.valueOf(person.get('heightInches')) : null;
                contractParticipantTemp.ARC_Weight__c = person.containsKey('weightLbs') ? String.valueOf(person.get('weightLbs')) : null;

                // Add the Contract Participant to the memberIdtoContractParticipantMap
                this.manager.memberIdtoContractParticipantMap.put((String)memberInfo.get('memberExternalId'), contractParticipantTemp);
            }
            
            
            
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
                appFeeOrder.ChargentOrders__Card_Number__c = paymentMethod == 'Credit Card' ? String.valueOf(paymentMethodMap.get('cardNumber')) : null;
                appFeeOrder.ChargentOrders__Card_Expiration_Month__c = paymentMethod == 'Credit Card' ? String.valueOf(paymentMethodMap.get('expirationMonth')) : null;
                appFeeOrder.ChargentOrders__Card_Month_Indicator__c = paymentMethod == 'Credit Card' ? String.valueOf(paymentMethodMap.get('expirationMonth')) : null;
                appFeeOrder.ChargentOrders__Card_Expiration_Year__c = paymentMethod == 'Credit Card' ? String.valueOf(paymentMethodMap.get('expirationYear')) : null;
                appFeeOrder.ChargentOrders__Card_Year_Indicator__c = paymentMethod == 'Credit Card' ? String.valueOf(paymentMethodMap.get('expirationYear')) : null;
                appFeeOrder.ChargentOrders__Card_Last_4__c = paymentMethod == 'Credit Card' ? (String.valueOf(paymentMethodMap.get('cardNumber'))).right(4) : null;

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
     * @Description: Maps data to Promotion Discount object
     */
    private void mapPromotionDiscount(){
        try {
            Map<String, Object> generalInformation = this.enrollmentInfo.containsKey('generalInformation') && this.enrollmentInfo.get('generalInformation') != null ? (Map<String, Object>)this.enrollmentInfo.get('generalInformation') : null;
            
            if (generalInformation.containsKey('payment') && generalInformation.get('payment') != null) {

                // Get all payment information map from JSON
                Map<String,Object> payment = (Map<String,Object>)generalInformation.get('payment');

                if (payment.containsKey('promoCode') && payment.get('promoCode') != null) {
                        
                    Id recordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Promotion_Discount').getRecordTypeId();

                    ARC_PromotionDiscount__c discount = new ARC_PromotionDiscount__c();

                    discount.ARC_PromoCode__c = payment.containsKey('promoCode') && payment.get('promoCode') != null && payment.get('promoCode') != '' ? (String) payment.get('promoCode') : null;
                    discount.ARC_Contract__c = null;
                    discount.ARC_AmountToDiscountPerTransaction__c = payment.containsKey('discountAmount') && payment.get('discountAmount') != null ? (Decimal)payment.get('discountAmount') : null;

                    Map<String, Object> medicalProgram = generalInformation.containsKey('medicalProgram') && generalInformation.get('medicalProgram') != null ? (Map<String, Object>)generalInformation.get('medicalProgram') : null;
                    discount.ARC_CorePriceWithoutDiscount__c = medicalProgram.containsKey('price') && medicalProgram.get('price') != null ? (Decimal)medicalProgram.get('price') : null;
                    discount.ARC_NumberOfTimesCanBeUsed__c = payment.containsKey('numberOfPayments') ? (Integer) payment.get('numberOfPayments') : 1;
                    discount.ARC_ExonerateAppChangeFee__c = payment.containsKey('discountPrice') && (Decimal)payment.get('discountPrice') == 0 ? true : false;
                    // discount.ARC_DiscountedAmount__c = ?;

                    if(generalInformation.containsKey('hadAssistance') && generalInformation.get('hadAssistance') != null && ((Map<String, Object>)generalInformation.get('hadAssistance')).containsKey('agentId') && ((Map<String, Object>)generalInformation.get('hadAssistance')).get('agentId') != null && ((Map<String, Object>)generalInformation.get('hadAssistance')).get('agentId') != '') {
                        Map<String, Object> assistanceInfo = generalInformation.containsKey('hadAssistance') && generalInformation.get('hadAssistance') != null ? (Map<String, Object>)generalInformation.get('hadAssistance') : new Map<String,Object>();
                        discount.ARC_Agent__c = assistanceInfo.containsKey('agentId') && assistanceInfo.get('agentId') != null ? (Id) assistanceInfo.get('agentId') : null;
                        discount.RecordTypeId = recordTypeId;
                    }
                    manager.promotionDiscountToInsert.add(discount);
                }
            }
        }
        catch (Exception e) {
            System.debug('Exception mapPromotionDiscount: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
     * @Description: Detects PROG_CriticalCare (SMART) + PROG_AccidentalInjury (AIDD) 
     * bundle per member and prepares an ARC_PromotionDiscount__c for each matching pair.
     */
    private void mapCriticalCarePromotionDiscount() {
        try {
            System.debug('Mapping Critical Care / Accidental Injury Promotion Discount');

            List<Object> members = (List<Object>)this.enrollmentInfo.get('members');

            for (Object memberInfo_obj : members) {
                Map<String, Object> memberInfo = (Map<String, Object>)memberInfo_obj;
                String memberExternalId = (String)memberInfo.get('memberExternalId');
                String role = (String)memberInfo.get('role');

                if (!memberInfo.containsKey('ancillaryCarePrograms')) continue;
                List<Object> ancillaryList = (List<Object>)memberInfo.get('ancillaryCarePrograms');
                if (ancillaryList == null || ancillaryList.isEmpty()) continue;

                String smartKey = null;
                String aiddKey  = null;

                for (Object anc_obj : ancillaryList) {
                    Map<String, Object> anc = (Map<String, Object>)anc_obj;
                    String productCode = (String)anc.get('productCode');

                    // Build the same ancillaryKey used in mapContractLineItem
                    String ancillaryKey = 'Parent';
                    String relatedTo = (String)anc.get('relatedTo');
                    if (role == 'Primary' || role == 'Spouse') {
                        ancillaryKey += role;
                    } else {
                        ancillaryKey += memberExternalId;
                    }
                    ancillaryKey += productCode;

                    if (productCode == 'PROG_CriticalCare') {
                        smartKey = ancillaryKey;
                    } else if (productCode == 'PROG_AccidentalInjury') {
                        aiddKey = ancillaryKey;
                    }
                }

                // Only create the bundle record when BOTH products are present
                if (smartKey != null && aiddKey != null) {
                    System.debug('Bundle found for member ' + memberExternalId + ' | SMART key: ' + smartKey + ' | AIDD key: ' + aiddKey);

                    // Track keys so DML can resolve GCMP IDs later
                    this.manager.memberIdToCriticalCareBundle.put(memberExternalId,new Map<String, String>{ 'SMART' => smartKey, 'AIDD' => aiddKey });

                    // Prepare the PromotionDiscount shell (GCMP IDs filled in DML)
                    Id recordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c
                        .getRecordTypeInfosByDeveloperName()
                        .get('Ancillary_Discount')
                        .getRecordTypeId();

                    ARC_PromotionDiscount__c pd = new ARC_PromotionDiscount__c();
                    pd.RecordTypeId  = recordTypeId;
                    pd.ARC_Contract__c = null; // filled in DML
                    pd.ARC_SMART__c = null; // filled in DML after GCMP insert
                    pd.ARC_AIDD__c = null; // filled in DML after GCMP insert
                    
                    this.manager.promotionDiscountToInsert.add(pd);
                }
            }
        } catch (Exception e) {
            System.debug('Error in mapCriticalCarePromotionDiscount: ' 
                + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
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
            this.uwCase.Description = 'Eligibility';
            this.uwCase.Subject = 'Eligibility';
            this.uwCase.Origin = 'Member Enrollment';
            this.uwCase.Type = 'New Membership';
            this.uwCase.Status = 'Draft';
            this.uwCase.Reason = 'Shop And Enroll';
            Map<String, Object> generalInformation = (Map<String, Object>)this.enrollmentInfo.get('generalInformation');

            this.manager.uwCase = this.uwCase;
            
        } catch (Exception e) {
            System.debug('Error in mapUWCase: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to Onboarding Case object
     */
     private void mapOnboardingCase() {
        try {
            System.debug('Mapping Onboarding Case data');
            String enrollmentType = this.enrollmentInfo.containsKey('enrollmentType')?(String)this.enrollmentInfo.get('enrollmentType'):null;
            if(enrollmentType != null && enrollmentType.toUpperCase() == 'INTERNAL'){
                this.onboardingCase = new Case();
                this.onboardingCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Onboarding').getRecordTypeId();
    
                Map<String, Object> primaryMemberInfo = getPrimaryMemberInfo();
                if (primaryMemberInfo != null) {
                    this.onboardingCase.Subject = (String)primaryMemberInfo.get('firstName') + ' ' + (String)primaryMemberInfo.get('lastName') + ' Onboarding';
                }
                else{
                    this.onboardingCase.Subject = 'Onboarding';
                }
                
                // Map case information
                this.onboardingCase.ARC_Reason__c = 'Onboarding';
                this.onboardingCase.Case_Type__c = 'Onboarding';
                this.onboardingCase.Description =  System.Label.ARC_OnboardingCaseDescription;
                this.onboardingCase.Origin = 'Internal';
                this.onboardingCase.Status = 'New';
                this.onboardingCase.Reason = 'Onboarding';
                //Owner Selling Agent
                if (manager.sellingAgentId != null) {
                    this.onboardingCase.OwnerId = manager.sellingAgentId;
                } 
                this.manager.onboardingCase = this.onboardingCase;
            }
            
        } catch (Exception e) {
            System.debug('Error in mapUWCase: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to UW Case Members object
     */
    private void mapUWCaseMember() {
        try {
            List<Object> members = (List<Object>)this.enrollmentInfo.get('members');
            for (Object member_obj : members) {
                Map<String, Object> member = (Map<String, Object>)member_obj;
                Map<String, Object> person = (Map<String, Object>)member.get('person');
                ARC_UnderwritingCaseMember__c newCaseMember;
                newCaseMember = new ARC_UnderwritingCaseMember__c();
                newCaseMember.ARC_ApprovalResolution__c = 'Pending';
                newCasemember.Name = (String)person.get('firstName') + ' ' + (String)person.get('lastName');
                newCaseMember.ARC_Reason__c = 'New Application';

                this.manager.uwCaseMembers.put((String)member.get('memberExternalId'), newCaseMember);
            }
        } catch (Exception e) {
            System.debug('Error in mapUWCaseMember: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @Description: Maps data to HIPPA object
     */
    private void mapHIPPA() {
        try {
            System.debug('Mapping HIPPA data');
            
            // Get hipaa information
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
                        // newHipaa.ARC_Census__c = ''; // map in DML
                        // newHipaa.ARC_AuthorizedMember__c = ''; // map in DML
                    }
                   
                    if ((String)hipaaTemp.get('relationship') == 'Third Party') {
                        // newHipaa.ARC_ExternalPersonAuthorized__c = ''; // map in DML

                        Contact externalPersonal = new Contact();
                        Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('ARC_HipaaAuthorization').getRecordTypeId();

                        externalPersonal.FirstName = hipaaTemp.containsKey('firstName') ? (String)hipaaTemp.get('firstName') : null;
                        externalPersonal.LastName = hipaaTemp.containsKey('lastName') ? (String)hipaaTemp.get('lastName') : null;
                        externalPersonal.Birthdate = hipaaTemp.containsKey('DAT_DOB') ? Date.valueOf((String)hipaaTemp.get('DAT_DOB')) : null;
                        externalPersonal.Email = hipaaTemp.containsKey('email') ? (String)hipaaTemp.get('email') : null;
                        externalPersonal.Phone = hipaaTemp.containsKey('phone') ? (String)hipaaTemp.get('phone') : null;
                        externalPersonal.RecordTypeId = recordTypeId;
                        // externalPersonal.AccountId = ''; // map in DML

                        Map<String,Object> address = hipaaTemp.containsKey('address') ? (Map<String,Object>)hipaaTemp.get('address') : null;

                        if (address != null) {
                            externalPersonal.MailingCity = address.containsKey('city') ? (String)address.get('city') : null;
                            externalPersonal.MailingCountry = 'US'; // CHECK THIS
                            externalPersonal.MailingState = address.containsKey('state') ? (String)address.get('state') : null;
                            externalPersonal.MailingPostalCode = address.containsKey('zip') ? (String)address.get('zip') : null;
                            externalPersonal.MailingStreet = address.containsKey('street') ? (String)address.get('street') : null; 
                        }

                        // Store the external contact information
                        this.manager.hippaExternalContact.put(temporaryMemberId, externalPersonal);
                        // Store the third party hipaa information
                        this.manager.hipaaThirdParty.put(temporaryMemberId, newHipaa);

                    } else if (generalInformation.containsKey('guardian') && generalInformation.get('guardian') != null && (String)((Map<String, Object>)generalInformation.get('guardian')).get('firstName') == (String)hipaaTemp.get('firstName') &&
                              (String)((Map<String, Object>)generalInformation.get('guardian')).get('lastName') == (String)hipaaTemp.get('lastName') &&
                              (String)((Map<String, Object>)generalInformation.get('guardian')).get('dob') == (String)hipaaTemp.get('dob') ) {
                        // This is the guardian node
                        this.manager.hipaaLegalGuardian.put(temporaryMemberId, newHipaa);
                    } else {
                        // Store the census member hipaa information
                        this.manager.hipaaCensusMember.put((String)hipaaTemp.get('memberExternalId'), newHipaa);
                    }
                }
            }
            
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
            
            
           
            // Get new enrollment member list
            List<Object> enrollmentMembersList = this.enrollmentInfo.containsKey('members') && this.enrollmentInfo.get('members') != null ? (List<Object>)this.enrollmentInfo.get('members') : new List<Object>();

            Map<String, ARC_MedicalConditions__c> medicalConditionsToInsert = new Map<String, ARC_MedicalConditions__c>(); // For Questions Group 1
            Map<String, List<vlocity_ins__ConsumerDrug__c>> prescriptionsMap = new Map<String, List<vlocity_ins__ConsumerDrug__c>>(); // For Questions Group 3
            List<String> medicalConditionsGroupOneList = new List<String> {
                'familyHistory', 'symptoms', 'consulted', 'substance', 'dui', 'otherDx'
            };

            if (!enrollmentMembersList.isEmpty() && enrollmentMembersList.size() > 0) {
                // Iterate over each member
                for (Object member : enrollmentMembersList) {
                    // Get needed information
                    Map<String,Object> memberMap = (Map<String,Object>)member;
                    Map<String,Object> medicalQuestionsMap = (Map<String,Object>)memberMap.get('medicalQuestions');
                    String memberExternalId = (String)memberMap.get('memberExternalId');
                    String memberName = (String)((Map<String,Object>)memberMap.get('person')).get('firstName') + ' ' + (String)((Map<String,Object>)memberMap.get('person')).get('lastName');

                    // Process Group 1 - Medical Conditions - Q1,Q2,Q3,Q5,Q6,Q7
                    if (medicalQuestionsMap != null && !medicalQuestionsMap.isEmpty()) {
                        for (String blockName : medicalQuestionsMap.keySet()) {
                            List<Object> medicalConditionListToProcess = convertObjectToList(medicalQuestionsMap.get(blockName));
                            // Check if there medical questions to process and if it is in Group 1
                            if (medicalConditionListToProcess != null && medicalConditionsGroupOneList.contains(blockName)) {
                                processMedicalQuestionsFirstGroup(medicalConditionsToInsert, medicalConditionListToProcess, blockName, memberExternalId, memberName);
                            }
                        }
                        if (medicalConditionsToInsert.get(memberExternalId) != null) {
                            // If member has medical conditions to insert, add it to map to insert by member external ID
                            if (!manager.medicalConditionsByMemberToInsert.containsKey(memberExternalId)) {
                                manager.medicalConditionsByMemberToInsert.put(memberExternalId, new List<ARC_MedicalConditions__c>());
                            }
                            manager.medicalConditionsByMemberToInsert.get(memberExternalId).add(medicalConditionsToInsert.get(memberExternalId));
                        }
                    }

                    // Process Group 2 - Cancer - Q4
                    if (medicalQuestionsMap.containsKey('cancer') && medicalQuestionsMap.get('cancer') != null) {
                        List<Object> cancerList = convertObjectToList(medicalQuestionsMap.get('cancer'));
                        if (!cancerList.isEmpty() && cancerList.size() > 0) {
                            for (Object cancer : cancerList) {
                                Map<String,Object> tempCancerMap = (Map<String,Object>)cancer;
                                if ((String)tempCancerMap.get('answer') == 'yes') {
                                    ARC_MedicalConditions__c mcC = new ARC_MedicalConditions__c();
                                    mcC.name = memberName.length() > 60 ? memberName.substring(0,60) + '-Medical Condition' : memberName+'-Medical Condition';
                                    mcC.ARC_Currently_Under_Treatment__c = (Boolean)tempCancerMap.get('underTreatment');
                                    mcC.ARC_Type_Of_Cancer__c =(String)tempCancerMap.get('cancerType');
                                    mcC.ARC_Year_Diagnosed_Cancer__c = (String)tempCancerMap.get('diagnoseDate') != null ? Date.valueOf((String)tempCancerMap.get('diagnoseDate')) : null;
                                    mcC.ARC_Active__c = true;

                                    if (!manager.medicalConditionsByMemberToInsert.containsKey(memberExternalId)) {
                                        manager.medicalConditionsByMemberToInsert.put(memberExternalId, new List<ARC_MedicalConditions__c>());
                                    }
                                    manager.medicalConditionsByMemberToInsert.get(memberExternalId).add(mcC);
                                }
                            }
                        }
                    }


                    // Process Group 3 - Prescriptions - Q8
                    if (medicalQuestionsMap.containsKey('prescriptions') && medicalQuestionsMap.get('prescriptions') != null) {
                        Map<String,Object> consumerDrugMap = (Map<String,Object>)medicalQuestionsMap.get('prescriptions');
                        if (consumerDrugMap.containsKey('answer') && consumerDrugMap.get('answer') == 'yes') {
                            List<Object> consumerDrugList = convertObjectToList(consumerDrugMap.get('medications'));
                            if (!consumerDrugList.isEmpty() && consumerDrugList.size() > 0) {
                                for (Object consumerDrug : consumerDrugList) {
                                    Map<String,Object> tempConsumerDrugMap = (Map<String,Object>)consumerDrug;
                                    vlocity_ins__ConsumerDrug__c cd = new vlocity_ins__ConsumerDrug__c();
                                    cd.Name = (String)tempConsumerDrugMap.get('name');
                                    cd.vlocity_ins__PrescribedBy__c = (String)tempConsumerDrugMap.get('prescribedBy'); // PENDING TO ADD TO JSON INPUT
                                    cd.vlocity_ins__MedicationStartDate__c = (String)tempConsumerDrugMap.get('startDate') != null && (String)tempConsumerDrugMap.get('startDate') != '' ? Date.valueOf((String)tempConsumerDrugMap.get('startDate')) : null; // PENDING TO ADD TO JSON INPUT
                                    cd.vlocity_ins__MedicationEndDate__c = (String)tempConsumerDrugMap.get('endDate') != null && (String)tempConsumerDrugMap.get('endDate') != '' ? Date.valueOf((String)tempConsumerDrugMap.get('endDate')) : null; // PENDING TO ADD TO JSON INPUT
                                    cd.ARC_Reason__c = (String)tempConsumerDrugMap.get('prescribedFor');
                                    cd.ARC_Active__c = cd.vlocity_ins__MedicationEndDate__c != null && cd.vlocity_ins__MedicationEndDate__c <= Date.today() ? false : true;
                                    cd.vlocity_ins__IsActive__c = cd.vlocity_ins__MedicationEndDate__c != null && cd.vlocity_ins__MedicationEndDate__c <= Date.today() ? false : true;

                                    if (!manager.consumerDrugsByMemberToInsert.containsKey(memberExternalId)) {
                                        manager.consumerDrugsByMemberToInsert.put(memberExternalId, new List<vlocity_ins__ConsumerDrug__c>());
                                    }
                                    manager.consumerDrugsByMemberToInsert.get(memberExternalId).add(cd);
                                }
                            }
                        }
                    }



                    // Process Group 4 - Physicians - Q9
                    if(medicalQuestionsMap.containsKey('pcp') && medicalQuestionsMap.get('pcp') != null) {
                        Map<String,Object> pcpMap = (Map<String,Object>)medicalQuestionsMap.get('pcp');
                        if(pcpMap.containsKey('hasPcp') && pcpMap.get('hasPcp') == 'yes') {
                            vlocity_ins__GroupCensusMember__c memberMapTemp = manager.memberIdToCensusMemberMap.get(memberExternalId);
                            if (memberMapTemp != null) {
                                memberMapTemp.ARC_PhysicianName__c = pcpMap.containsKey('name') ? (String)pcpMap.get('name') : null;
                                memberMapTemp.ARC_PhysicianPhone__c = pcpMap.containsKey('phone') ? (String)pcpMap.get('phone') : null;
                                memberMapTemp.ARC_PhysicianCity__c = pcpMap.containsKey('city') ? (String)pcpMap.get('city') : null;
                                System.debug('Updated Member with PCP info: ' + memberMapTemp);
                            }
                        }
                    }


                }

                System.debug('Medical Conditions to Insert: ');
                System.debug(JSON.serializePretty(manager.medicalConditionsByMemberToInsert));
                System.debug('Prescriptions to Insert: ');
                System.debug(JSON.serializePretty(manager.consumerDrugsByMemberToInsert));
                
            }

            
        } catch (Exception e) {
            System.debug('Error in mapMedicalQuestion: ' + e.getMessage());
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

    /**
    * @Description: Converts an Object to a List of Objects. If the Object is a Map,
    * it wraps it in a new List. If it's already a List, it returns it.
    * Returns null if the input Object is null.
    * @param value: The Object to convert.
    * @return List<Object>: The converted List of Objects.
    */
    private List<Object> convertObjectToList(Object value) {
        if (value == null) return null;

        List<Object> objectList = new List<Object>();

        if (value instanceof Map<String, Object>) {
            objectList.add(value); 
        } else if (value instanceof List<Object>) {
            objectList = (List<Object>)value;
        }

        return objectList;
    }

    /**
    * Processes a list of data records for a specific medical condition block and updates the provided medical condition map.
    * @param medicalConditionsToInsert A map where the key is the member ID (String) and the value is the corresponding ARC_MedicalConditions__c record. This map will be updated with information extracted from the block data.
    * @param medicalConditionList A list of Objects, where each Object represents a record containing data for the specific medical condition block. Each Object is expected to be a Map<String, Object>.
    * @param blockName A String indicating the name of the medical condition block being processed. This is used to determine the specific fields to extract and the logic to apply.
    * @param memberMap A Map with the information of the member that is being iterated
    */
    private void processMedicalQuestionsFirstGroup(Map<String, ARC_MedicalConditions__c> medicalConditionsToInsert, List<Object> medicalConditionList, String blockName, String memberExternalId, String memberName) {
        if (medicalConditionList != null) {
            for (Object recordObj : medicalConditionList) {
                if (recordObj != null) {
                    Map<String, Object> recordMap = (Map<String, Object>)recordObj;
                    Boolean isBlockActiveForMember = false; // Variable to check if any block is activated per member
                    
                    ARC_MedicalConditions__c mc = medicalConditionsToInsert.get(memberExternalId) != null ? medicalConditionsToInsert.get(memberExternalId): new ARC_MedicalConditions__c();
       
                    // Logic per blocke
                    if (blockName == 'familyHistory') {
                        Boolean hasParentSiblingDiagnosed = (String)recordMap.get('answer') == 'yes' ? true : false;
                        if (hasParentSiblingDiagnosed == true) {
                            isBlockActiveForMember = true;
                            mc.ARC_ParentsOrSiblingsDiagnosed__c = hasParentSiblingDiagnosed;
                            mc.ARC_ParentsOrSiblingsDiagnosedDate__c = (String)recordMap.get('date') != null ? Date.valueOf((String)recordMap.get('date')) : null;
                            mc.ARC_ParentsOrSiblingsDiagnosedNote__c = (String)recordMap.get('notes');
                        }
                    } else if (blockName == 'symptoms') {
                        Boolean hasUnexpectedSymptoms = (String)recordMap.get('answer') == 'yes' ? true : false;
                        if (hasUnexpectedSymptoms == true) {
                            isBlockActiveForMember = true;
                            mc.ARC_UnexplainedConditions__c = hasUnexpectedSymptoms;
                            mc.ARC_Unexplained_Conditions_Date__c = (String)recordMap.get('date') != null ? Date.valueOf((String)recordMap.get('date')) : null;
                            mc.ARC_Unexplained_Conditions_Notes__c = (String)recordMap.get('notes');
                        }
                    } else if (blockName == 'consulted') {
                        Boolean hasPendingTests = (String)recordMap.get('answer') == 'yes' ? true : false;
                        if (hasPendingTests == true) {
                            isBlockActiveForMember = true;
                            mc.ARC_Tests__c = hasPendingTests;
                            mc.ARC_Tests_Date__c = (String)recordMap.get('date') != null ? Date.valueOf((String)recordMap.get('date')) : null;
                            mc.ARC_Tests_Notes__c = (String)recordMap.get('notes');
                        }
                    } else if (blockName == 'substance') {
                        Boolean hasAddiction = (String)recordMap.get('answer') == 'yes' ? true : false;
                        if (hasAddiction == true) {
                            isBlockActiveForMember = true;
                            mc.ARC_IllegalDrugsAlcohol__c = hasAddiction;
                            mc.ARC_Illegal_Drugs_Alcohol_Date__c = (String)recordMap.get('date') != null ? Date.valueOf((String)recordMap.get('date')) : null;
                            mc.ARC_Illegal_Drugs_Alcohol_Notes__c = (String)recordMap.get('notes');
                        }
                    } else if (blockName == 'dui') {
                        Boolean hasLicenceSuspended = (String)recordMap.get('answer') == 'yes' ? true : false;
                        if (hasLicenceSuspended == true) {
                            isBlockActiveForMember = true;
                            mc.ARC_LicenceSuspended__c = hasLicenceSuspended;
                            mc.ARC_LicenseSuspendedDate__c = (String)recordMap.get('date') != null ? Date.valueOf((String)recordMap.get('date')) : null;
                            mc.ARC_LicenceSuspendedNote__c = (String)recordMap.get('notes');
                        }
                    } else if (blockName == 'otherDx') {
                        Boolean hasPrescriptions = (String)recordMap.get('answer') == 'yes' ? true : false;
                        List<Object> prescriptionsList = (List<Object>)recordMap.get('selectedDiagnoses');
                        String conditions = String.join(prescriptionsList, ';');
                        String otherConditions = (String)recordMap.get('otherText');
    
                        if (!String.isBlank(conditions) || !String.isBlank(otherConditions)) {
                            isBlockActiveForMember = true;
                            mc.ARC_Condition__c = conditions;
                            mc.ARC_OtherConditions__c = otherConditions;
                        }
                    }
                    // Only add to the map if any block is activated per member
                    if (isBlockActiveForMember) {
                        if(memberName != null && memberName.length()>60){
                            mc.Name = memberName.substring(0,60) + '-Medical Condition';
                        }
                        else mc.Name = memberName + '-Medical Condition';
                        mc.ARC_Active__c = true;
                        medicalConditionsToInsert.put(memberExternalId, mc);
                    }
                }
            }
        }
    }
}