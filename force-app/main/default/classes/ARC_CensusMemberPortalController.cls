public with sharing class ARC_CensusMemberPortalController {

    public class CensusMemberPortalWrapper {
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String gender;
        @AuraEnabled public String dob;
        @AuraEnabled public String employmentType;
        @AuraEnabled public String division;
        @AuraEnabled public String jobClass;
        @AuraEnabled public String ssn;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String zipCode;
        @AuraEnabled public String effectiveDate;
        @AuraEnabled public String jobTitle;
        @AuraEnabled public String hireDate;
    }

    public class SaveResultWrapper {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public List<String> errors;
        @AuraEnabled public List<String> technicalErrors;

        @AuraEnabled public Id accountId;
        @AuraEnabled public Id censusId;
        @AuraEnabled public Id censusMemberId;
        @AuraEnabled public Id personAccountId;
        @AuraEnabled public Id personContactId;

        public SaveResultWrapper() {
            success = false;
            errors = new List<String>();
            technicalErrors = new List<String>();
        }
    }

    public class PicklistOptionsDTO {
        @AuraEnabled public List<String> employmentTypes;
        @AuraEnabled public List<String> divisions;
        @AuraEnabled public List<String> jobClasses;

        public PicklistOptionsDTO() {
            employmentTypes = new List<String>();
            divisions = new List<String>();
            jobClasses = new List<String>();
        }
    }

    @AuraEnabled(cacheable=true)
    public static PicklistOptionsDTO getPicklistOptions() {
        Map<String, Set<String>> picklistValues = getPicklistValues();
        PicklistOptionsDTO dto = new PicklistOptionsDTO();

        dto.employmentTypes = new List<String>(picklistValues.get('ARC_EmployeeType__c'));
        dto.divisions = new List<String>(picklistValues.get('ARC_EmployeeDivision__c'));
        dto.jobClasses = new List<String>(picklistValues.get('ARC_JobClass__c'));

        dto.employmentTypes.sort();
        dto.divisions.sort();
        dto.jobClasses.sort();

        return dto;
    }

    @AuraEnabled
    public static SaveResultWrapper saveCensusMemberForCurrentUser(String memberJson) {
        SaveResultWrapper result = new SaveResultWrapper();
        Savepoint sp = Database.setSavepoint();

        try {
            if (String.isBlank(memberJson)) {
                result.errors.add('No member data was provided.');
                return result;
            }

            CensusMemberPortalWrapper member =
                (CensusMemberPortalWrapper) JSON.deserialize(memberJson, CensusMemberPortalWrapper.class);

            validateRequired(member, result);
            if (!result.errors.isEmpty()) return result;

            Map<String, Set<String>> picklistValues = getPicklistValues();
            validatePicklistValue(member.employmentType, 'Employment Type', picklistValues.get('ARC_EmployeeType__c'), result);
            validatePicklistValue(member.division, 'Division', picklistValues.get('ARC_EmployeeDivision__c'), result);
            validatePicklistValue(member.jobClass, 'Job Class', picklistValues.get('ARC_JobClass__c'), result);
            if (!result.errors.isEmpty()) return result;

            Id accountId = getAccountIdForCurrentUser();
            result.accountId = accountId;

            if (accountId == null) {
                result.errors.add('No Account was found for the current user.');
                return result;
            }

            vlocity_ins__GroupCensus__c census = getCensusGroup(accountId);
            result.censusId = census.Id;

            vlocity_ins__GroupCensusMember__c censusMember =
                getExistingCensusMemberBySSN(census.Id, member.ssn);

            Boolean isNewMember = (censusMember == null);
            if (isNewMember) {
                censusMember = new vlocity_ins__GroupCensusMember__c();
                censusMember.vlocity_ins__CensusId__c = census.Id;
            }

            censusMember.vlocity_ins__FirstName__c = member.firstName;
            censusMember.vlocity_ins__LastName__c = member.lastName;
            censusMember.vlocity_ins__Gender__c = member.gender;
            censusMember.vlocity_ins__Birthdate__c = parseDateString(member.dob);
            censusMember.ARC_EmployeeType__c = member.employmentType;
            censusMember.ARC_EmployeeDivision__c = member.division;
            censusMember.ARC_JobClass__c = member.jobClass;
            censusMember.vlocity_ins__SocialSecurityNumber__c = member.ssn;
            censusMember.vlocity_ins__Email__c = member.email;
            censusMember.ARC_Phone__c = member.phone;
            censusMember.ARC_PhysicalAddressStreet__c = member.street;
            censusMember.ARC_PhysicalAddressCity__c = member.city;
            censusMember.ARC_PhysicalAddressState__c = member.state;
            censusMember.ARC_PhysicalAddressZipCode__c = member.zipCode;
            censusMember.ARC_JobTitle__c = member.jobTitle;
            censusMember.ARC_HireDate__c = parseDateString(member.hireDate);
            censusMember.ARC_AllowEnrollmentOutsideOE__c = true;


            if (Schema.sObjectType.vlocity_ins__GroupCensusMember__c.fields.getMap().containsKey('ARC_RequestedEffectiveDate__c')) {
                Date eff = parseDateString(member.effectiveDate);
                if (eff != null) {
                    censusMember.put('ARC_RequestedEffectiveDate__c', eff);
                }
            }
            upsert censusMember;
            result.censusMemberId = censusMember.Id;
           
            if (isNewMember) {
                assignMemberToGroupClasses(censusMember, accountId, result);
            }

            Account personAcc = upsertPersonAccountFromCensusMember(censusMember, result);
            if (personAcc != null) {
                result.personAccountId = personAcc.Id;

                Account accWithContact = [
                    SELECT Id, PersonContactId, vlocity_ins__SocialSecurityNumber__pc
                    FROM Account
                    WHERE Id = :personAcc.Id
                    LIMIT 1
                ];
                result.personContactId = accWithContact.PersonContactId;

                if (accWithContact.PersonContactId != null) {
                    vlocity_ins__GroupCensusMember__c cmUpdate = new vlocity_ins__GroupCensusMember__c(
                        Id = censusMember.Id,
                        vlocity_ins__ContactId__c = accWithContact.PersonContactId,
                        vlocity_ins__AccountId__c = accWithContact.Id
                    );
                    update cmUpdate;
                }
            }

            result.success = true;
            result.message = isNewMember ? 'Member created successfully.' : 'Member updated successfully.';
            return result;

        } catch (Exception e) {
            Database.rollback(sp);
            result.errors.add('An unexpected error occurred while saving the member.');
            result.technicalErrors.add('Exception: ' + e.getMessage() + ' at line ' + e.getLineNumber() + '. Stack: ' + e.getStackTraceString());
            return result;
        }
    }

    private static void validateRequired(CensusMemberPortalWrapper m, SaveResultWrapper result) {
        if (m == null) {
            result.errors.add('Member payload is invalid.');
            return;
        }
        if (String.isBlank(m.firstName)) result.errors.add('[First Name] is required');
        if (String.isBlank(m.lastName)) result.errors.add('[Last Name] is required');
        if (String.isBlank(m.gender)) result.errors.add('[Gender] is required');
        if (String.isBlank(m.dob)) result.errors.add('[DOB] is required');
        if (String.isBlank(m.employmentType)) result.errors.add('[Employment Type] is required');
        if (String.isBlank(m.division)) result.errors.add('[Division] is required');
        if (String.isBlank(m.jobClass)) result.errors.add('[Job Class] is required');
        if (String.isBlank(m.ssn)) result.errors.add('[SSN] is required');
        if (String.isBlank(m.email)) result.errors.add('[Email] is required');
        if (String.isBlank(m.phone)) result.errors.add('[Phone] is required');
        if (String.isBlank(m.street)) result.errors.add('[Street] is required');
        if (String.isBlank(m.city)) result.errors.add('[City] is required');
        if (String.isBlank(m.state)) result.errors.add('[State] is required');
        if (String.isBlank(m.zipCode)) result.errors.add('[Zip Code] is required');
        if (String.isBlank(m.effectiveDate)) result.errors.add('[Effective Date] is required');
    }

    private static void validatePicklistValue(String value, String fieldName, Set<String> validValues, SaveResultWrapper result) {
        if (String.isBlank(value)) return;
        if (validValues == null || !validValues.contains(value)) {
            result.errors.add('[' + fieldName + '] "' + value + '" is not valid.');
        }
    }

    private static Map<String, Set<String>> getPicklistValues() {
        Map<String, Set<String>> picklistMap = new Map<String, Set<String>>();

        Schema.DescribeFieldResult employeeTypeField = vlocity_ins__GroupCensusMember__c.ARC_EmployeeType__c.getDescribe();
        Schema.DescribeFieldResult divisionField = vlocity_ins__GroupCensusMember__c.ARC_EmployeeDivision__c.getDescribe();
        Schema.DescribeFieldResult jobClassField = vlocity_ins__GroupCensusMember__c.ARC_JobClass__c.getDescribe();

        picklistMap.put('ARC_EmployeeType__c', getPicklistValueSet(employeeTypeField));
        picklistMap.put('ARC_EmployeeDivision__c', getPicklistValueSet(divisionField));
        picklistMap.put('ARC_JobClass__c', getPicklistValueSet(jobClassField));

        return picklistMap;
    }

    private static Set<String> getPicklistValueSet(Schema.DescribeFieldResult fieldDescribe) {
        Set<String> values = new Set<String>();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.isActive()) values.add(entry.getValue());
        }
        return values;
    }

    private static Id getAccountIdForCurrentUser() {
        User u = [
            SELECT Id, AccountId, Contact.AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        Id accountId = u.AccountId;
        if (accountId == null && u.Contact != null) {
            accountId = u.Contact.AccountId;
        }
        return accountId;
    }

    private static vlocity_ins__GroupCensus__c getCensusGroup(Id accountId) {
        List<vlocity_ins__GroupCensus__c> existingCensus = [
            SELECT Id
            FROM vlocity_ins__GroupCensus__c
            WHERE vlocity_ins__GroupId__c = :accountId
            LIMIT 1
        ];

        if (!existingCensus.isEmpty()) return existingCensus[0];

        vlocity_ins__GroupCensus__c newCensus = new vlocity_ins__GroupCensus__c(
            vlocity_ins__GroupId__c = accountId,
            Name = 'Census - ' + System.now().format()
        );
        insert newCensus;
        return newCensus;
    }

    private static vlocity_ins__GroupCensusMember__c getExistingCensusMemberBySSN(Id censusId, String ssn) {
        if (censusId == null || String.isBlank(ssn)) return null;

        List<vlocity_ins__GroupCensusMember__c> members = [
            SELECT Id, vlocity_ins__SocialSecurityNumber__c, vlocity_ins__CensusId__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__CensusId__c = :censusId
        ];

        for (vlocity_ins__GroupCensusMember__c m : members) {
            if (String.isNotBlank(m.vlocity_ins__SocialSecurityNumber__c) &&
                m.vlocity_ins__SocialSecurityNumber__c == ssn) {
                return m;
            }
        }
        return null;
    }

    private static Account upsertPersonAccountFromCensusMember(vlocity_ins__GroupCensusMember__c cm, SaveResultWrapper result) {
        if (cm == null || String.isBlank(cm.vlocity_ins__SocialSecurityNumber__c)) return null;

        Map<String, Account> existingBySSN = getExistingPersonAccountsBySSN(
            new List<vlocity_ins__GroupCensusMember__c>{ cm }
        );

        Id personRtId = getPersonAccountRecordTypeId();

        Account personAcc;
        if (existingBySSN.containsKey(cm.vlocity_ins__SocialSecurityNumber__c)) {
            personAcc = existingBySSN.get(cm.vlocity_ins__SocialSecurityNumber__c);
        } else {
            personAcc = new Account();
            if (personRtId != null) personAcc.RecordTypeId = personRtId;
        }

        personAcc.FirstName = cm.vlocity_ins__FirstName__c;
        personAcc.LastName = cm.vlocity_ins__LastName__c;
        personAcc.PersonEmail = cm.vlocity_ins__Email__c;
        personAcc.Phone = cm.ARC_Phone__c;
        personAcc.vlocity_ins__SocialSecurityNumber__pc = cm.vlocity_ins__SocialSecurityNumber__c;
        personAcc.PersonBirthdate = cm.vlocity_ins__Birthdate__c;
        personAcc.PersonGender = cm.vlocity_ins__Gender__c;
        personAcc.PersonMailingStreet = cm.ARC_PhysicalAddressStreet__c;
        personAcc.PersonMailingCity = cm.ARC_PhysicalAddressCity__c;
        personAcc.PersonMailingState = cm.ARC_PhysicalAddressState__c;
        personAcc.PersonMailingPostalCode = cm.ARC_PhysicalAddressZipCode__c;
        personAcc.Census_Member__c = cm.Id;
        personAcc.ARC_Census__c = cm.vlocity_ins__CensusId__c;
        personAcc.ARC_JobTitle__c = cm.ARC_JobTitle__c;
        personAcc.ARC_HireDate__c = cm.ARC_HireDate__c;
        personAcc.ARC_AllowEnrollmentOutsideOE__c = cm.ARC_AllowEnrollmentOutsideOE__c;

        Database.UpsertResult[] r = Database.upsert(new List<Account>{ personAcc }, false);
        if (r[0].isSuccess()) {
            personAcc.Id = r[0].getId();
            return personAcc;
        }

        String technicalMsg = 'Error upserting Person Account: ';
        for (Database.Error err : r[0].getErrors()) {
            technicalMsg += err.getMessage() + '; ';
        }
        result.technicalErrors.add(technicalMsg);
        result.errors.add('Unable to create/update the Person Account for this member.');
        return null;
    }

    private static Map<String, Account> getExistingPersonAccountsBySSN(List<vlocity_ins__GroupCensusMember__c> censusMembers) {
        Set<String> ssns = new Set<String>();
        for (vlocity_ins__GroupCensusMember__c cm : censusMembers) {
            if (String.isNotBlank(cm.vlocity_ins__SocialSecurityNumber__c)) ssns.add(cm.vlocity_ins__SocialSecurityNumber__c);
        }

        Map<String, Account> personAccountsBySSN = new Map<String, Account>();
        if (ssns.isEmpty()) return personAccountsBySSN;

        List<Account> allPersonAccounts = [
            SELECT Id, PersonContactId, vlocity_ins__SocialSecurityNumber__pc, FirstName, LastName
            FROM Account
            WHERE IsPersonAccount = true
        ];

        for (Account acc : allPersonAccounts) {
            if (String.isNotBlank(acc.vlocity_ins__SocialSecurityNumber__pc) &&
                ssns.contains(acc.vlocity_ins__SocialSecurityNumber__pc)) {
                personAccountsBySSN.put(acc.vlocity_ins__SocialSecurityNumber__pc, acc);
            }
        }

        return personAccountsBySSN;
    }

    private static Id getPersonAccountRecordTypeId() {
        try {
            RecordType rt = [
                SELECT Id
                FROM RecordType
                WHERE SObjectType = 'Account'
                AND DeveloperName = 'ARC_SGPersonAccount'
                AND IsActive = true
                LIMIT 1
            ];
            return rt.Id;
        } catch (Exception e) {
            return null;
        }
    }

    private static Date parseDateString(String dateStr) {
        if (String.isBlank(dateStr)) return null;

        try {
            Integer year, month, day;

            if (dateStr.contains('-') && dateStr.indexOf('-') == 4) {
                List<String> parts = dateStr.split('-');
                if (parts.size() == 3) {
                    year = Integer.valueOf(parts[0]);
                    month = Integer.valueOf(parts[1]);
                    day = Integer.valueOf(parts[2]);
                }
            } else if (dateStr.contains('/')) {
                List<String> parts = dateStr.split('/');
                if (parts.size() == 3) {
                    month = Integer.valueOf(parts[0]);
                    day = Integer.valueOf(parts[1]);
                    year = Integer.valueOf(parts[2]);
                }
            }

            if (year != null && month != null && day != null) {
                if (month < 1 || month > 12) return null;
                if (day < 1 || day > 31) return null;

                List<Integer> thirtyDayMonths = new List<Integer>{4, 6, 9, 11};
                if (thirtyDayMonths.contains(month) && day > 30) return null;

                if (month == 2) {
                    Boolean isLeapYear = (Math.mod(year, 4) == 0 && Math.mod(year, 100) != 0) || (Math.mod(year, 400) == 0);
                    if ((isLeapYear && day > 29) || (!isLeapYear && day > 28)) return null;
                }

                return Date.newInstance(year, month, day);
            }
        } catch (Exception e) {
        }

        return null;
    }

    private static void assignMemberToGroupClasses( vlocity_ins__GroupCensusMember__c censusMember, Id accountId, SaveResultWrapper result) {
    try {
        List<Contract> contracts = [
            SELECT Id
            FROM Contract
            WHERE AccountId = :accountId
              AND Status NOT IN ('Draft', 'Voided')
        ];

        if (contracts.isEmpty()) return;

        List<vlocity_ins__GroupClass__c> allGroupClasses = [
            SELECT Id, Name,
                   ARC_EmployeeTypeModel__c,
                   ARC_EmployeeType__c,
                   ARC_EmployeeDivision__c,
                   ARC_Contract__c
            FROM vlocity_ins__GroupClass__c
            WHERE ARC_Contract__c IN :new Map<Id, Contract>(contracts).keySet()
              AND vlocity_ins__IsActive__c = true
        ];

        if (allGroupClasses.isEmpty()) return;

        // Agrupar por contrato
        Map<Id, List<vlocity_ins__GroupClass__c>> gcsByContract = new Map<Id, List<vlocity_ins__GroupClass__c>>();
        for (vlocity_ins__GroupClass__c gc : allGroupClasses) {
            if (!gcsByContract.containsKey(gc.ARC_Contract__c)) {
                gcsByContract.put(gc.ARC_Contract__c, new List<vlocity_ins__GroupClass__c>());
            }
            gcsByContract.get(gc.ARC_Contract__c).add(gc);
        }

        List<ARC_CensusMemberGroupClass__c> junctionsToInsert = new List<ARC_CensusMemberGroupClass__c>();

        for (Id contractId : gcsByContract.keySet()) {
            List<vlocity_ins__GroupClass__c> contractGcs = gcsByContract.get(contractId);

            Id targetGcId = matchGroupClass(
                contractGcs,
                censusMember.ARC_EmployeeType__c,
                censusMember.ARC_EmployeeDivision__c
            );

            if (targetGcId == null) continue;

            String gcName = '';
            for (vlocity_ins__GroupClass__c gc : contractGcs) {
                if (gc.Id == targetGcId) { gcName = gc.Name; break; }
            }

            junctionsToInsert.add(new ARC_CensusMemberGroupClass__c(
                Name                = censusMember.vlocity_ins__FirstName__c + ' '
                                    + censusMember.vlocity_ins__LastName__c + ' - ' + gcName,
                ARC_CensusMember__c = censusMember.Id,
                ARC_GroupClass__c   = targetGcId
            ));
        }

        if (!junctionsToInsert.isEmpty()) {
            insert junctionsToInsert;
        }

    } catch (Exception e) {
        result.technicalErrors.add(
            'Warning - assignMemberToGroupClasses: '
            + e.getMessage() + ' at line ' + e.getLineNumber()
        );
    }
}

private static Id matchGroupClass(
    List<vlocity_ins__GroupClass__c> contractGcs,
    String memberEmpType,
    String memberEmpDiv
) {
    String t = norm(memberEmpType);
    String d = norm(memberEmpDiv);

    for (vlocity_ins__GroupClass__c gc : contractGcs) {
        String gcModel = gc.ARC_EmployeeTypeModel__c;

        if (gcModel == 'None') {
            return gc.Id;
        }
        if (gcModel == 'FullTime_PartTime') {
            if (gc.ARC_EmployeeDivision__c == 'None') {
                if (norm(gc.ARC_EmployeeType__c) == t) return gc.Id;
            } else {
                if (norm(gc.ARC_EmployeeType__c) == t && norm(gc.ARC_EmployeeDivision__c) == d) return gc.Id;
            }
        }
        if (gcModel == 'Exempt_NonExempt') {
            if (norm(gc.ARC_EmployeeDivision__c) == d) return gc.Id;
        }
    }

    return null;
}

private static String norm(String s) {
    if (String.isBlank(s)) return '';
    return s.trim().toLowerCase().replace('-', '').replace(' ', '');
}
    
}