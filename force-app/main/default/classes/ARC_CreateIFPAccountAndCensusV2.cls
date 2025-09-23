global without sharing class ARC_CreateIFPAccountAndCensusV2 implements vlocity_ins.VlocityOpenInterface2{

    private static List<RecordType> getRecordType() {
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        List<RecordType> rt2 = [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE 
                                (DeveloperName = 'ARC_IFPPersonAccount' AND SobjectType = 'Account') OR
                                (DeveloperName = 'ARC_Guardian' AND SobjectType = 'Account') OR
                                (DeveloperName = 'Group' AND SobjectType = 'Account') OR
                                (DeveloperName = 'ARC_IndividualAndFamily' AND SobjectType = 'vlocity_ins__GroupCensus__c') OR
                                (DeveloperName = 'ARC_IndividualAndFamily' AND SobjectType = 'Contract')];
        return rt2;
    }
    private static final String ACCOUNT_ID = 'AccountId';
    private static final String PERSON_ACCOUNT_ID = 'PersonAccountId';
    private static final String OLDEST_MEMBER_ID = 'OldestMemberId';
    private static final String OPPORTUNITY_ID = 'OpportunityId';
    private static final String CENSUS_ID = 'CensusId';
    private static final String CENSUS_MEMBER_ID = 'CensusMemberId';
    private static final String CONTRACT_ID = 'ContractId';
    private static final String ACCOUNT_FIRST_NAME = 'FirstName';
    private static final String ACCOUNT_MIDDLE_NAME = 'MiddleName';
    private static final String ACCOUNT_LAST_NAME = 'LastName';
    private static final String ACCOUNT_DATE_OF_BIRTH = 'DateOfBirth';
    private static final String ACCOUNT_EMAIL = 'Email';
    private static final String ACCOUNT_BILLING_STREET = 'BillingStreet';
    private static final String ACCOUNT_BILLING_CITY = 'BillingCity';
    private static final String ACCOUNT_BILLING_STATE = 'BillingState';
    private static final String ACCOUNT_BILLING_ZIP_CODE = 'BillingZipCode';
    private static final String ACCOUNT_GENDER = 'Gender';
    private static final String ACCOUNT_EFFECTIVE_DATE = 'EffectiveDate';
    private static final String ACCOUNT_SSN = 'primarySSN';
    private static final String ACCOUNT_HEIGHT_FEET = 'HeightFeet';
    private static final String ACCOUNT_HEIGHT_INCHES = 'HeightInches';
    private static final String ACCOUNT_WEIGHT = 'Weight';
    private static final String ACCOUNT_TIMESTAMP = 'TimeStamp';
    private static final String USER_ID = 'UserId';
    private static final String ACCOUNT_PHONE = 'Phone';
    private static final String USER_PROFILE = 'userProfile';
    private static final String CONTRACT_REASON = 'ContractReason';
    private static final String CONTRACT_TERM = 'contractTerm';
    private static final String GUARDIAN_FIRST_NAME = 'GuardianFirstName';
    private static final String GUARDIAN_LAST_NAME = 'GuardianLastName';
    private static final String GUARDIAN_GENDER = 'GuardianGender';
    private static final String GUARDIAN_STREET = 'GuardianStreet';
    private static final String GUARDIAN_APT = 'GuardianApt';
    private static final String GUARDIAN_CITY = 'GuardianCity';
    private static final String GUARDIAN_STATE = 'GuardianState';
    private static final String GUARDIAN_ZIP_CODE = 'GuardianZipCode';
    private static final String GUARDIAN_EMAIL = 'GuardianEmail';
    private static final String GUARDIAN_PHONE = 'GuardianPhone';
    private static final String GUARDIAN_BIRTHDATE = 'GuardianBirthdate';
    private static final String GUARDIAN_SSN = 'GuardianSSN';
    private static final String GUARDIAN_RELATIONSHIP_TO_CHILD = 'GuardianRelationshipToChild';
    private static final String GUARDIAN_ACCOUNT_ID = 'GuardianAccountId';
	//Variables
	private static String methodName;
    private static String OldestMemberId;
	private static String accountId;
	private static String personAccountId;
	private static String opportunityId;
	private static String censusId;
	private static String censusMemberId;
	private static String contractId;
	private static String accountFirstName;
    private static String accountMiddleName;
	private static String accountLastName;
	private static String accountDateOfBirth;
	private static String accountEmail;
	private static String accountBillingStreet;
	private static String accountBillingCity;
	private static String accountBillingState;
	private static String accountBillingZipCode;
	private static String accountGender;
	private static String accountEffectiveDate;
    private static String primarySSN;
    private static String HeightFeet;
    private static String HeightInches;
    private static String Weight;
    private static String isRenEnrollment;
	private static String TimeStamp;
    private static String UserId;
    private static String accountPhone;
    private static String UserProfile;
    private static String contractReason;
    private static String ContractTerm;
    private static String guardianFirstName;
    private static String guardianLastName;
    private static String guardianGender;
    private static String guardianStreet;
    private static String guardianApt;
    private static String guardianCity;
    private static String guardianState;
    private static String guardianZipCode;
    private static String guardianEmail;
    private static String guardianPhone;
    private static String guardianBirthdate;
    private static String guardianSSN;
    private static String guardianRelationshipToChild;
    private static String guardianAccountId;
    private static Id GroupAccountRecordTypeId;
    private static Id PersonAccountRecordTypeId;
    private static Id GuardianAccountRecordTypeId;
	private static Id IFPCensusRecordTypeId;
	private static Id IFPContractRecordTypeId;

    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options){
        outMapRecordType(outMap);
        setVariables(methodName, inputMap, options);
        if (methodName.equals('createRecords')){
            createRecords(outMap);
        }
        if (methodName.equals('createGuardianAccount')){
            createGuardianAccount(outMap);
            
        }
        return true;
    }

    private static void createGuardianAccount(Map<String,Object> outMap) {
        
        Account newGuardianAccount = insertGuardianAccount(null);
        Id guardianContactId = [SELECT Id FROM Contact WHERE AccountId = :newGuardianAccount.Id].Id;
        outMap.put('GuardianContactId', guardianContactId);
        outMap.put('GuardianAccountId', newGuardianAccount.Id);
    }

    private static void createRecords(Map<String,Object> outMap) {
        //Create Group Account
        Account newAccount = insertAccount();
        //Create Guardian Account
        Account newGuardianAccount = new Account();
        //Create Census
        vlocity_ins__GroupCensus__c newCensus = new vlocity_ins__GroupCensus__c(); 
        if (String.isNotBlank(guardianFirstName)){
            //Create Guardian Account
            newGuardianAccount = insertGuardianAccount(newAccount.Id);
            newCensus = insertCensus(newAccount.Id, newGuardianAccount.Id);
        }else{
            newCensus = insertCensus(newAccount.Id, null);
        }
        //Create Census Member
        vlocity_ins__GroupCensusMember__c newCensusMember = insertCensusMember(newCensus.Id);   
        //Create Contract 
        Contract newContract = insertContract(newAccount.Id, newGuardianAccount.Id);
        String tt = vlocity_ins.UserSecurity.encryptForUser(String.valueOf(newAccount.Id), UserId);
        outMap.put('AccountId', newAccount.Id);
        outMap.put('CensusId', newCensus.Id);
        outMap.put('CensusIdEncrypted', vlocity_ins.UserSecurity.encryptForUser(String.valueOf(newCensus.Id), UserId));
        outMap.put('CensusMemberId', newCensusMember.Id);
        outMap.put('Address', Address());
        outMap.put('ContractId', newContract.Id);
        outMap.put('AccountName', accountFirstName + ' ' + accountLastName);
        outMap.put('UserId', UserId);
        outMap.put('PesonAccountId', newGuardianAccount.Id);
    }

    private static void outMapRecordType(Map<String, Object> outMap) {
        List<RecordType> recordTypeList = ARC_CreateIFPAccountAndCensusV2.getRecordType();
        for (RecordType recType : recordTypeList) {
            if (recType.DeveloperName == 'Group' && recType.SobjectType == 'Account') {
                GroupAccountRecordTypeId = recType.Id;
            } else if (recType.DeveloperName == 'ARC_IndividualAndFamily' && recType.SobjectType == 'vlocity_ins__GroupCensus__c') {
                IFPCensusRecordTypeId = recType.Id;
            } else if (recType.DeveloperName == 'ARC_IndividualAndFamily' && recType.SobjectType == 'Contract') {
                IFPContractRecordTypeId = recType.Id;
                outMap.put('ContractRecordTypeId', recType.Id);
            } else if (recType.DeveloperName == 'ARC_IFPPersonAccount' && recType.SobjectType == 'Account'){
                PersonAccountRecordTypeId = recType.Id;
            }else if(recType.DeveloperName == 'ARC_Guardian' && recType.SobjectType == 'Account'){
                GuardianAccountRecordTypeId = recType.Id;
            }
        }
    }

    private static Account insertGuardianAccount(Id groupAccountId){
        Account newAccount = new Account();
        if (String.isNotBlank(personAccountId)) {
            newAccount.Id = personAccountId;
        }
        if (String.isNotBlank(guardianAccountId)) {
            newAccount.Id = guardianAccountId;
            
        }
        newAccount.RecordTypeId = GuardianAccountRecordTypeId;
        newAccount.ARC_GroupAccount__c = groupAccountId;
        newAccount.Phone = guardianPhone;
        newAccount.FirstName = guardianFirstName;
        newAccount.LastName = guardianLastName;
        newAccount.vlocity_ins__Email__c =  guardianEmail;
        newAccount.PersonEmail =  guardianEmail;
        newAccount.PersonBirthdate =  Date.valueOf(guardianBirthdate);
        newAccount.BillingStreet = guardianStreet;
        newAccount.BillingState = guardianState;
        newAccount.BillingCity = guardianCity;
        newAccount.BillingPostalCode = guardianZipCode;
        newAccount.BillingCountry = 'United States';
        newAccount.ARC_SocialSecurityNumber__c = guardianSSN;
        newAccount.PersonGender = guardianGender;
        newAccount.ARC_GuardianRelationshipToChild__c = guardianRelationshipToChild;

        upsert newAccount;
        return newAccount;
    }

    private static Account insertAccount(){
        Account newAccount = new Account();
        if (String.isNotBlank(accountId)) {
            newAccount.Id = accountId;
        }
        newAccount.RecordTypeId = GroupAccountRecordTypeId;
        newAccount.Phone = accountPhone;
        newAccount.Name = accountFirstName +' '+accountLastName +' Family';
        newAccount.vlocity_ins__Email__c =  accountEmail;
        newAccount.BillingStreet = accountBillingStreet;
        newAccount.BillingState = accountBillingState;
        newAccount.BillingCity = accountBillingCity;
        newAccount.BillingPostalCode = accountBillingZipCode;
        newAccount.BillingCountry = 'United States';
        try {
            upsert newAccount;
        } catch (DmlException e) {
            System.debug('Account: ');
            System.debug(e);
        }
        return newAccount;
    }

    //Marked as TestVisible since it is a private method and actually is not referenced anywhere in the code.
    @TestVisible
    private static Opportunity insertOpportunity(Id AccountId) {
        Opportunity newOpp = new Opportunity();
        if (String.isNotBlank(opportunityId)) {
            newOpp.Id = opportunityId;
        }
        newOpp.Name = accountFirstName + ' ' + accountLastName + ' - Opportunity'; 
        newOpp.AccountId = AccountId;
        newOpp.StageName = 'In Process';
        newOpp.CloseDate = Date.today().addYears(1);
        try {
            upsert newOpp;
        } catch (DmlException e) {
            System.debug('Opportunity: ');
            System.debug(e);
        }
        return newOpp;
    }

    private static vlocity_ins__GroupCensus__c insertCensus(Id AccountId, Id persAccId) {
        vlocity_ins__GroupCensus__c newCensus = new vlocity_ins__GroupCensus__c();
        if (String.isNotBlank(censusId)) {
            newCensus.Id = censusId;
        } else {
            newCensus.vlocity_ins__GroupId__c = AccountId;
            newCensus.ARC_PrimaryAccount__c = AccountId;
        }
        newCensus.Name = accountFirstName + ' ' + accountLastName + ' - Census';
        newCensus.RecordTypeId = IFPCensusRecordTypeId;
        if(String.isNotBlank(guardianFirstName)){
            newCensus.ARC_IsChildFamily__c = true; 
            newCensus.ARC_GuardianAccount__c = persAccId;
        }
        try {
            upsert newCensus;
        } catch (DmlException e) {
            System.debug('Census: ');
            System.debug(e);
        }
        return newCensus;
    }

    private static vlocity_ins__GroupCensusMember__c insertCensusMember(Id GroupId) {
        vlocity_ins__GroupCensusMember__c newCensusMember = new vlocity_ins__GroupCensusMember__c();
        if (String.isNotBlank(censusMemberId)) {
            newCensusMember.Id = censusMemberId;
        } else {
            newCensusMember.vlocity_ins__CensusId__c = GroupId;
        }
        newCensusMember.Name = accountFirstName + ' ' + accountLastName + ' - Census Member';
        newCensusMember.vlocity_ins__MemberIdentifier__c = TimeStamp;
        newCensusMember.vlocity_ins__IsPrimaryMember__c = true;
        newCensusMember.vlocity_ins__Gender__c = accountGender;
        newCensusMember.ARC_Phone__c = accountPhone; 
        newCensusMember.vlocity_ins__Email__c = accountEmail;
        newCensusMember.vlocity_ins__Birthdate__c = Date.valueOf(accountDateOfBirth);
        newCensusMember.vlocity_ins__FirstName__c = accountFirstName;
		newCensusMember.ARC_OldCensusMember__c = OldestMemberId;
        newCensusMember.ARC_MiddleInitial__c = accountMiddleName;
        newCensusMember.vlocity_ins__LastName__c = accountLastName;
        newCensusMember.vlocity_ins__SocialSecurityNumber__c = primarySSN;
        newCensusMember.ARC_HeightFeet__c = HeightFeet;
        newCensusMember.ARC_HeightInches__c = HeightInches;
        newCensusMember.ARC_Weight__c = Weight;
        newCensusMember.vlocity_ins__IsPortalUser__c = true;
        newCensusMember.ARC_PhysicalAddressStreet__c = accountBillingStreet;
        newCensusMember.ARC_PhysicalAddressCity__c = accountBillingCity;
        newCensusMember.ARC_PhysicalAddressState__c = accountBillingState;
        newCensusMember.ARC_PhysicalAddressZipCode__c = accountBillingZipCode;
        try {
            upsert newCensusMember;
        } catch (DmlException e) {
            System.debug('CensusMember: ');
            System.debug(e);
        }
        return newCensusMember;
    }

    private static Contract insertContract(Id AccountId, Id guardianId) {
        Contract newContract = new Contract();
        if (String.isNotBlank(contractId)) {
            newContract.Id = contractId;
        }
        newContract.AccountId = AccountId;
        newContract.RecordTypeId = IFPContractRecordTypeId;
        newContract.ARC_ContractReason__c = contractReason;
        newContract.ARC_Selling_Agent__c = UserId;
        newContract.ContractTerm = Integer.valueOf(ContractTerm);
        newContract.ARC_Guardian__c = guardianId;
        upsert newContract;
        return newContract;
    }

    private static Map<String, String> Address() {
        Map<String, String> BillingAddress = new Map<String, String>();
        BillingAddress.put('BillingZipCode',accountBillingZipCode);
        BillingAddress.put('BillingState', accountBillingState);
        BillingAddress.put('BillingStreet', accountBillingStreet);
        BillingAddress.put('BillingCity', accountBillingCity);
        return BillingAddress;
    }

    private static void setVariables(String methodNameParam, Map<String,Object> inputMap, Map<String,Object> options){
		methodName = methodNameParam;
        //Populate date form options map.
        accountId = String.valueOf(options.get(ACCOUNT_ID));
        personAccountId = String.valueOf(options.get(PERSON_ACCOUNT_ID));
        opportunityId = String.valueOf(options.get(OPPORTUNITY_ID));
        censusId = String.valueOf(options.get(CENSUS_ID));
        censusMemberId = String.valueOf(options.get(CENSUS_MEMBER_ID));
        contractId = String.valueOf(options.get(CONTRACT_ID));
        accountBillingStreet = String.valueOf(options.get(ACCOUNT_BILLING_STREET));
        accountBillingCity = String.valueOf(options.get(ACCOUNT_BILLING_CITY));
        accountBillingState = String.valueOf(options.get(ACCOUNT_BILLING_STATE));
        accountBillingZipCode = String.valueOf(options.get(ACCOUNT_BILLING_ZIP_CODE));
        accountFirstName = String.valueOf(options.get(ACCOUNT_FIRST_NAME));
        accountMiddleName = String.valueOf(options.get(ACCOUNT_MIDDLE_NAME));
        accountLastName = String.valueOf(options.get(ACCOUNT_LAST_NAME));
        accountGender = String.valueOf(options.get(ACCOUNT_GENDER));
        primarySSN = String.valueOf(options.get(ACCOUNT_SSN));
        accountEffectiveDate = String.valueOf(options.get(ACCOUNT_EFFECTIVE_DATE));
        accountPhone = String.valueOf(options.get(ACCOUNT_PHONE));
        accountEmail = String.valueOf(options.get(ACCOUNT_EMAIL));
        TimeStamp = String.valueOf(options.get(ACCOUNT_TIMESTAMP));
        accountDateOfBirth = String.valueOf(options.get(ACCOUNT_DATE_OF_BIRTH));
        HeightInches = String.valueOf(options.get(ACCOUNT_HEIGHT_INCHES));
        HeightFeet = String.valueOf(options.get(ACCOUNT_HEIGHT_FEET));
        Weight = String.valueOf(options.get(ACCOUNT_WEIGHT));
        ContractTerm = String.valueOf(options.get(CONTRACT_TERM));
        contractReason = String.valueOf(options.get(CONTRACT_REASON));
        OldestMemberId = String.valueOf(options.get(OLDEST_MEMBER_ID));
        UserProfile = String.valueOf(options.get(USER_PROFILE));
        UserId = String.valueOf(options.get(USER_ID));
        //Populate date form input map.
        guardianSSN = String.valueOf(inputMap.get(GUARDIAN_SSN));
        guardianBirthdate = String.valueOf(inputMap.get(GUARDIAN_BIRTHDATE));
        guardianPhone = String.valueOf(inputMap.get(GUARDIAN_PHONE));
        guardianEmail = String.valueOf(inputMap.get(GUARDIAN_EMAIL));
        guardianZipCode = String.valueOf(inputMap.get(GUARDIAN_ZIP_CODE));
        guardianState = String.valueOf(inputMap.get(GUARDIAN_STATE));
        guardianCity = String.valueOf(inputMap.get(GUARDIAN_CITY));
        guardianApt = String.valueOf(inputMap.get(GUARDIAN_APT));
        guardianStreet = String.valueOf(inputMap.get(GUARDIAN_STREET));
        guardianGender = String.valueOf(inputMap.get(GUARDIAN_GENDER));
        guardianLastName = String.valueOf(inputMap.get(GUARDIAN_LAST_NAME));
        guardianFirstName = String.valueOf(inputMap.get(GUARDIAN_FIRST_NAME));
        guardianRelationshipToChild = String.valueOf(inputMap.get(GUARDIAN_RELATIONSHIP_TO_CHILD));
        guardianAccountId = String.valueOf(inputMap.get(GUARDIAN_ACCOUNT_ID));
    }
}