public with sharing class ARC_CensusMemberCSVController {
    // Controller for CSV-based Census Member upload and management
    
    public class CensusMemberCSVWrapper {
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String gender;
        @AuraEnabled public String dob;
        @AuraEnabled public String hireDate;
        @AuraEnabled public String jobTitle;
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
    }
    
    public class ProcessResult {
        @AuraEnabled public Integer inserted;
        @AuraEnabled public Integer updated;
        @AuraEnabled public Integer deleted;
        @AuraEnabled public Integer skipped;
        @AuraEnabled public List<String> errors;
        @AuraEnabled public List<String> technicalErrors;
        
        public ProcessResult() {
            this.inserted = 0;
            this.updated = 0;
            this.deleted = 0;
            this.skipped = 0;
            this.errors = new List<String>();
            this.technicalErrors = new List<String>();
        }
    }
    
    // For Community Users - uses running user's Account
    @AuraEnabled
    public static ProcessResult processCensusMembersCSVCommunity(String censusMembersJson) {
        ProcessResult result = new ProcessResult();
        Savepoint sp = Database.setSavepoint();
        
        try {
            // Get running user's Account
            Id userId = UserInfo.getUserId();
            User currentUser = [SELECT ContactId, Contact.AccountId FROM User WHERE Id = :userId LIMIT 1];
            
            if (currentUser.ContactId == null || currentUser.Contact.AccountId == null) {
                result.errors.add('Unable to determine your account. Please contact support.');
                return result;
            }
            
            Id accountId = currentUser.Contact.AccountId;
            
            // Parse the CSV data
            List<CensusMemberCSVWrapper> csvMembers = 
                (List<CensusMemberCSVWrapper>) JSON.deserialize(censusMembersJson, List<CensusMemberCSVWrapper>.class);
            
            // Validate all rows first - fail fast if any errors
            Map<String, Set<String>> picklistValues = getPicklistValues();
            validateCSVData(csvMembers, picklistValues, result);
            
            if (!result.errors.isEmpty()) {
                return result; // Return validation errors without saving
            }
            
            // Process with community options (insert only, no delete/overwrite)
            return processCensusMembers(csvMembers, accountId, null, result, sp, false, false, true, false);
            
        } catch (Exception e) {
            Database.rollback(sp);
            
            // User-friendly message
            result.errors.add('An unexpected error occurred while processing your file. Please check your data and try again.');
            
            // Technical details for console
            String technicalMsg = 'Exception: ' + e.getMessage() + ' at line ' + e.getLineNumber() + '. Stack: ' + e.getStackTraceString();
            System.debug(LoggingLevel.ERROR, technicalMsg);
            result.technicalErrors.add(technicalMsg);
            
            result.inserted = 0;
            result.updated = 0;
            result.deleted = 0;
        }
        
        return result;
    }
    
    // For Internal Users - uses Opportunity context
    @AuraEnabled
    public static ProcessResult processCensusMembersCSV(String censusMembersJson, Id oppId) {
        ProcessResult result = new ProcessResult();
        Savepoint sp = Database.setSavepoint();
        
        try {
            // Parse the CSV data
            List<CensusMemberCSVWrapper> csvMembers = 
                (List<CensusMemberCSVWrapper>) JSON.deserialize(censusMembersJson, List<CensusMemberCSVWrapper>.class);
            
            // Validate all rows first - fail fast if any errors
            Map<String, Set<String>> picklistValues = getPicklistValues();
            validateCSVData(csvMembers, picklistValues, result);
            
            if (!result.errors.isEmpty()) {
                return result; // Return validation errors without saving
            }
            
            // Get the Opportunity and related Account
            Opportunity opp = [
                SELECT Id, AccountId, ARC_CensusCsvUploaded__c, RecordType.DeveloperName
                FROM Opportunity 
                WHERE Id = :oppId
                LIMIT 1
            ];
            
            // Renewals: update existing members by SSN but never delete
            Boolean isRenewal = opp.RecordType?.DeveloperName == 'ARC_Renewal';
            return processCensusMembers(csvMembers, opp.AccountId, opp, result, sp, true, !isRenewal, false, isRenewal);
            
        } catch (Exception e) {
            Database.rollback(sp);
            
            // User-friendly message
            result.errors.add('An unexpected error occurred while processing your file. Please check your data and try again.');
            
            // Technical details for console
            String technicalMsg = 'Exception: ' + e.getMessage() + ' at line ' + e.getLineNumber() + '. Stack: ' + e.getStackTraceString();
            System.debug(LoggingLevel.ERROR, technicalMsg);
            result.technicalErrors.add(technicalMsg);
            
            result.inserted = 0;
            result.updated = 0;
            result.deleted = 0;
        }
        
        return result;
    }
    
    // Core processing logic - shared by both internal and community contexts
    private static ProcessResult processCensusMembers(
        List<CensusMemberCSVWrapper> csvMembers,
        Id accountId,
        Opportunity opp,
        ProcessResult result,
        Savepoint sp,
        Boolean allowUpdate,
        Boolean allowDelete,
        Boolean isCommunity,
        Boolean isRenewal
    ) {
        try {
            // Get or Create Census Group
            vlocity_ins__GroupCensus__c census = getCensusGroup(accountId, opp?.Id, isCommunity);
            
            // Get existing Census Members by SSN
            Map<String, vlocity_ins__GroupCensusMember__c> existingMembersBySSN = getExistingCensusMembersBySSN(census.Id);
            
            // Track SSNs from the CSV to determine which members to delete
            Set<String> csvSSNs = new Set<String>();
            
            List<vlocity_ins__GroupCensusMember__c> membersToUpsert = new List<vlocity_ins__GroupCensusMember__c>();
            
            // Process each CSV row
            for (CensusMemberCSVWrapper csvMember : csvMembers) {
                
                csvSSNs.add(csvMember.ssn);
                
                vlocity_ins__GroupCensusMember__c censusMember;
                
                // Check if member exists
                if (existingMembersBySSN.containsKey(csvMember.ssn)) {
                    if (!allowUpdate) {
                        // Skip existing members in community mode
                        result.skipped++;
                        continue;
                    }
                    // Update existing member
                    censusMember = existingMembersBySSN.get(csvMember.ssn);
                } else {
                    // Create new member
                    censusMember = new vlocity_ins__GroupCensusMember__c();
                    censusMember.vlocity_ins__CensusId__c = census.Id;
                }
                
                // Populate Census Member fields
                censusMember.vlocity_ins__FirstName__c = csvMember.firstName;
                censusMember.vlocity_ins__LastName__c = csvMember.lastName;
                censusMember.vlocity_ins__Gender__c = csvMember.gender;
                censusMember.vlocity_ins__Birthdate__c = parseDateString(csvMember.dob);
                censusMember.ARC_HireDate__c = parseDateString(csvMember.hireDate);
                censusMember.ARC_JobTitle__c = csvMember.jobTitle;
                censusMember.ARC_EmployeeType__c = csvMember.employmentType;
                censusMember.ARC_EmployeeDivision__c = csvMember.division;
                censusMember.ARC_JobClass__c = csvMember.jobClass;
                censusMember.vlocity_ins__SocialSecurityNumber__c = csvMember.ssn;
                censusMember.vlocity_ins__Email__c = csvMember.email;
                censusMember.ARC_Phone__c = csvMember.phone;
                censusMember.ARC_PhysicalAddressStreet__c = csvMember.street;
                censusMember.ARC_PhysicalAddressCity__c = csvMember.city;
                censusMember.ARC_PhysicalAddressState__c = csvMember.state;
                censusMember.ARC_PhysicalAddressZipCode__c = csvMember.zipCode;
                censusMember.ARC_AllowEnrollmentOutsideOE__c = isCommunity;
                
                membersToUpsert.add(censusMember);
            }
            
            // Upsert Census Members
            if (!membersToUpsert.isEmpty()) {
                Database.UpsertResult[] upsertResults = Database.upsert(membersToUpsert, false);
                
                // Check results and count actual successes
                for (Integer i = 0; i < upsertResults.size(); i++) {
                    if (upsertResults[i].isSuccess()) {
                        if (upsertResults[i].isCreated()) {
                            result.inserted++;
                        } else {
                            result.updated++;
                        }
                    } else {
                        String memberName = membersToUpsert[i].vlocity_ins__FirstName__c + ' ' + membersToUpsert[i].vlocity_ins__LastName__c;
                        String friendlyMsg = 'Unable to save ' + memberName + '. Please check the data for this member.';
                        
                        // Technical details for console
                        String technicalMsg = 'Error upserting ' + memberName + ': ';
                        for (Database.Error err : upsertResults[i].getErrors()) {
                            technicalMsg += err.getMessage() + '; ';
                        }
                        System.debug(LoggingLevel.ERROR, technicalMsg);
                        result.technicalErrors.add(technicalMsg);
                        
                        result.errors.add(friendlyMsg);
                    }
                }
            }
            
            // Create or Update Person Accounts
            createOrUpdatePersonAccounts(membersToUpsert, accountId, result, census.Id, isCommunity, isRenewal);
            
            // Delete Census Members not in CSV (only if allowed)
            if (allowDelete) {
                deleteMembersNotInCSV(census.Id, csvSSNs, existingMembersBySSN, result);
            }
            
            // Update Opportunity flag on first upload (only if opp provided)
            if (opp != null && opp.ARC_CensusCsvUploaded__c != true) {
                opp.ARC_CensusCsvUploaded__c = true;
                update opp;
            }
            
        } catch (Exception e) {
            Database.rollback(sp);
            
            // User-friendly message
            result.errors.add('An unexpected error occurred while processing your file. Please check your data and try again.');
            
            // Technical details for console
            String technicalMsg = 'Exception: ' + e.getMessage() + ' at line ' + e.getLineNumber() + '. Stack: ' + e.getStackTraceString();
            System.debug(LoggingLevel.ERROR, technicalMsg);
            result.technicalErrors.add(technicalMsg);
            
            result.inserted = 0;
            result.updated = 0;
            result.deleted = 0;
        }
        
        return result;
    }
    
    private static void validateCSVData(List<CensusMemberCSVWrapper> csvMembers, 
                                        Map<String, Set<String>> picklistValues,
                                        ProcessResult result) {
        Integer rowNum = 1; // Start at 1 for header
        
        for (CensusMemberCSVWrapper member : csvMembers) {
            rowNum++;
            String memberName = (String.isNotBlank(member.firstName) ? member.firstName + ' ' : '') + 
                               (String.isNotBlank(member.lastName) ? member.lastName : 'Unknown');
            String rowPrefix = 'Row ' + rowNum + ' (' + memberName + '): ';
            
            // Required field validations
            validateRequiredFields(member, rowPrefix, result);
            
            // Format validations (only if field has value)
            if (String.isNotBlank(member.firstName)) {
                validateName(member.firstName, 'First Name', rowPrefix, result);
            }
            if (String.isNotBlank(member.lastName)) {
                validateName(member.lastName, 'Last Name', rowPrefix, result);
            }
            if (String.isNotBlank(member.gender)) {
                validateGender(member.gender, rowPrefix, result);
            }
            if (String.isNotBlank(member.dob)) {
                validateDateOfBirth(member.dob, rowPrefix, result);
            }
            if (String.isNotBlank(member.hireDate)) {
                validateHireDate(member.hireDate, rowPrefix, result);
            }
            if (String.isNotBlank(member.phone)) {
                validatePhone(member.phone, rowPrefix, result);
            }
            if (String.isNotBlank(member.street)) {
                validateStreet(member.street, rowPrefix, result);
            }
            if (String.isNotBlank(member.city)) {
                validateCity(member.city, rowPrefix, result);
            }
            if (String.isNotBlank(member.zipCode)) {
                validateZipCode(member.zipCode, rowPrefix, result);
            }
            if (String.isNotBlank(member.email)) {
                validateEmail(member.email, rowPrefix, result);
            }
            if (String.isNotBlank(member.employmentType)) {
                validatePicklistValue(member.employmentType, 'Employment Type', picklistValues.get('ARC_EmployeeType__c'), rowPrefix, result);
            }
            if (String.isNotBlank(member.division)) {
                validatePicklistValue(member.division, 'Division', picklistValues.get('ARC_EmployeeDivision__c'), rowPrefix, result);
            }
            if (String.isNotBlank(member.jobClass)) {
                validatePicklistValue(member.jobClass, 'Job Class', picklistValues.get('ARC_JobClass__c'), rowPrefix, result);
            }
        }
    }
    
    // Validation Helper Methods - Organized by validation type
    
    private static void validateRequiredFields(CensusMemberCSVWrapper member, String rowPrefix, ProcessResult result) {
        if (String.isBlank(member.firstName)) {
            result.errors.add(rowPrefix + '[First Name] is required');
        }
        if (String.isBlank(member.lastName)) {
            result.errors.add(rowPrefix + '[Last Name] is required');
        }
        if (String.isBlank(member.gender)) {
            result.errors.add(rowPrefix + '[Gender] is required');
        }
        if (String.isBlank(member.dob)) {
            result.errors.add(rowPrefix + '[DOB] is required');
        }
        if (String.isBlank(member.hireDate)) {
            result.errors.add(rowPrefix + '[Hire Date] is required');
        }
        if (String.isBlank(member.jobTitle)) {
            result.errors.add(rowPrefix + '[Job Title] is required');
        }
        if (String.isBlank(member.employmentType)) {
            result.errors.add(rowPrefix + '[Employment Type] is required');
        }
        if (String.isBlank(member.division)) {
            result.errors.add(rowPrefix + '[Division] is required');
        }
        if (String.isBlank(member.jobClass)) {
            result.errors.add(rowPrefix + '[Job Class] is required');
        }
        if (String.isBlank(member.ssn)) {
            result.errors.add(rowPrefix + '[SSN] is required');
        }
        if (String.isBlank(member.email)) {
            result.errors.add(rowPrefix + '[Email] is required');
        }
        if (String.isBlank(member.phone)) {
            result.errors.add(rowPrefix + '[Phone] is required');
        }
        if (String.isBlank(member.street)) {
            result.errors.add(rowPrefix + '[Street] is required');
        }
        if (String.isBlank(member.city)) {
            result.errors.add(rowPrefix + '[City] is required');
        }
        if (String.isBlank(member.state)) {
            result.errors.add(rowPrefix + '[State] is required');
        }
        if (String.isBlank(member.zipCode)) {
            result.errors.add(rowPrefix + '[Zip Code] is required');
        }
    }
    
    private static void validateName(String name, String fieldName, String rowPrefix, ProcessResult result) {
        if (!Pattern.matches('^[a-zA-Z\\s\\-\\.]+$', name)) {
            result.errors.add(rowPrefix + '[' + fieldName + '] can only contain letters, spaces, hyphens, and periods (you entered: "' + name + '")');
        }
    }
    
    private static void validateGender(String gender, String rowPrefix, ProcessResult result) {
        Set<String> validGenders = new Set<String>{'Male', 'Female'};
        if (!validGenders.contains(gender)) {
            result.errors.add(rowPrefix + '[Gender] "' + gender + '" is not valid. Use: Male or Female');
        }
    }
    
    private static void validateDateOfBirth(String dobStr, String rowPrefix, ProcessResult result) {
        Date parsedDate = parseDateString(dobStr);
        if (parsedDate == null) {
            result.errors.add(rowPrefix + '[DOB] is not a valid date format. Use MM/DD/YYYY or YYYY-MM-DD (you entered: "' + dobStr + '")');
        } else {
            Date today = Date.today();
            if (parsedDate > today) {
                result.errors.add(rowPrefix + '[DOB] cannot be in the future');
            } else if (parsedDate < Date.newInstance(1900, 1, 1)) {
                result.errors.add(rowPrefix + '[DOB] must be after year 1900');
            }
        }
    }
    
    private static void validateHireDate(String hireDateStr, String rowPrefix, ProcessResult result) {
        Date parsedDate = parseDateString(hireDateStr);
        if (parsedDate == null) {
            result.errors.add(rowPrefix + '[Hire Date] is not a valid date format. Use MM/DD/YYYY or YYYY-MM-DD (you entered: "' + hireDateStr + '")');
        }
    }
    
    private static void validatePhone(String phone, String rowPrefix, ProcessResult result) {
        String cleanPhone = phone.replaceAll('[^0-9]', '');
        if (cleanPhone.length() < 10) {
            result.errors.add(rowPrefix + '[Phone] must be at least 10 digits. US format: (555) 123-4567 or 555-123-4567 (you entered: "' + phone + '")');
        } else if (cleanPhone.length() > 15) {
            result.errors.add(rowPrefix + '[Phone] cannot exceed 15 digits (you entered: "' + phone + '")');
        }
    }
    
    private static void validateStreet(String street, String rowPrefix, ProcessResult result) {
        if (!Pattern.matches('^[a-zA-Z0-9\\s\\-\\.,#]+$', street)) {
            result.errors.add(rowPrefix + '[Street] contains invalid characters (you entered: "' + street + '")');
        }
    }
    
    private static void validateCity(String city, String rowPrefix, ProcessResult result) {
        if (!Pattern.matches('^[a-zA-Z\\s\\-\\.]+$', city)) {
            result.errors.add(rowPrefix + '[City] can only contain letters, spaces, hyphens, and periods (you entered: "' + city + '")');
        }
    }
    
    private static void validateZipCode(String zipCode, String rowPrefix, ProcessResult result) {
        String cleanZip = zipCode.replaceAll('[^0-9]', '');
        if (cleanZip.length() != 5 && cleanZip.length() != 9) {
            result.errors.add(rowPrefix + '[Zip Code] must be 5 or 9 digits (you entered: "' + zipCode + '")');
        }
    }
    
    private static void validateEmail(String email, String rowPrefix, ProcessResult result) {
        String emailRegex = '^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        if (!Pattern.matches(emailRegex, email)) {
            result.errors.add(rowPrefix + '[Email] is not valid: "' + email + '"');
        }
    }
    
    private static void validatePicklistValue(String value, String fieldName, Set<String> validValues, String rowPrefix, ProcessResult result) {
        if (!validValues.contains(value)) {
            result.errors.add(rowPrefix + '[' + fieldName + '] "' + value + '" is not valid. Choose from: ' + 
                            String.join(new List<String>(validValues), ', '));
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
            if (entry.isActive()) {
                values.add(entry.getValue());
            }
        }
        return values;
    }
    
    private static Date parseDateString(String dateStr) {
        if (String.isBlank(dateStr)) {
            return null;
        }
        
        try {
            Integer year, month, day;
            
            // Try YYYY-MM-DD format
            if (dateStr.contains('-') && dateStr.indexOf('-') == 4) {
                List<String> parts = dateStr.split('-');
                if (parts.size() == 3) {
                    year = Integer.valueOf(parts[0]);
                    month = Integer.valueOf(parts[1]);
                    day = Integer.valueOf(parts[2]);
                }
            }
            // Try MM/DD/YYYY format
            else if (dateStr.contains('/')) {
                List<String> parts = dateStr.split('/');
                if (parts.size() == 3) {
                    month = Integer.valueOf(parts[0]);
                    day = Integer.valueOf(parts[1]);
                    year = Integer.valueOf(parts[2]);
                }
            }
            
            // Validate date components before creating Date
            if (year != null && month != null && day != null) {
                // Validate month (1-12)
                if (month < 1 || month > 12) {
                    return null;
                }
                
                // Validate day based on month
                if (day < 1 || day > 31) {
                    return null;
                }
                
                // Check days for specific months
                List<Integer> thirtyDayMonths = new List<Integer>{4, 6, 9, 11};
                if (thirtyDayMonths.contains(month) && day > 30) {
                    return null;
                }
                
                // February special handling (leap year check)
                if (month == 2) {
                    Boolean isLeapYear = (Math.mod(year, 4) == 0 && Math.mod(year, 100) != 0) || (Math.mod(year, 400) == 0);
                    if ((isLeapYear && day > 29) || (!isLeapYear && day > 28)) {
                        return null;
                    }
                }
                
                // Create and return the date
                return Date.newInstance(year, month, day);
            }
        } catch (Exception e) {
            System.debug('Error parsing date: ' + dateStr + ' - ' + e.getMessage());
        }
        
        return null;
    }
    
    private static vlocity_ins__GroupCensus__c getCensusGroup(Id accountId, Id oppId, Boolean isCommunity) {
        List<vlocity_ins__GroupCensus__c> existingCensus = [
            SELECT Id 
            FROM vlocity_ins__GroupCensus__c 
            WHERE vlocity_ins__GroupId__c = :accountId 
            LIMIT 1
        ];

        
        
        if (!existingCensus.isEmpty()) {
            // Populate the Census on the Draft Contract
            if(!isCommunity) {
                updateDraftContractWithCensus(accountId, existingCensus[0].Id);
            }
            return existingCensus[0];
        }
        
        if(!isCommunity){
            // Create new Census Group
            Id groupCensusRecordTypeId = Schema.SObjectType.vlocity_ins__GroupCensus__c.getRecordTypeInfosByDeveloperName().get('SmallGroup').getRecordTypeId();
            vlocity_ins__GroupCensus__c newCensus = new vlocity_ins__GroupCensus__c(
                vlocity_ins__GroupId__c = accountId,
                recordTypeId = groupCensusRecordTypeId,
                Name = 'Census - ' + System.now().format()
            );
            insert newCensus;
            
            // Populate the Census on the Draft Contract
            updateDraftContractWithCensus(accountId, newCensus.Id);
            
            return newCensus;
        }else{
            return null;
        }
    }
    
    private static void updateDraftContractWithCensus(Id accountId, Id censusId) {
        // Query for Draft Contract (limit 1 since there can only be one Draft at a time)
        List<Contract> draftContracts = [
            SELECT Id, vlocity_ins__EnrollmentCensusId__c
            FROM Contract
            WHERE AccountId = :accountId
            AND Status = 'Draft'
            LIMIT 1
        ];
        
        if (!draftContracts.isEmpty() && draftContracts[0].vlocity_ins__EnrollmentCensusId__c != censusId) {
            Contract draftContract = draftContracts[0];
            draftContract.vlocity_ins__EnrollmentCensusId__c = censusId;
            update draftContract;
        }
    }
    
    private static Map<String, vlocity_ins__GroupCensusMember__c> getExistingCensusMembersBySSN(Id censusId) {
        Map<String, vlocity_ins__GroupCensusMember__c> membersBySSN = new Map<String, vlocity_ins__GroupCensusMember__c>();
        
        List<vlocity_ins__GroupCensusMember__c> members = [
            SELECT Id, vlocity_ins__SocialSecurityNumber__c, vlocity_ins__FirstName__c, vlocity_ins__LastName__c,
                   vlocity_ins__Gender__c, vlocity_ins__Birthdate__c, ARC_EmployeeType__c, ARC_EmployeeDivision__c,
                   ARC_JobClass__c, vlocity_ins__Email__c, ARC_Phone__c, ARC_PhysicalAddressStreet__c,
                   ARC_PhysicalAddressCity__c, ARC_PhysicalAddressState__c, ARC_PhysicalAddressZipCode__c,
                   vlocity_ins__ContactId__c, vlocity_ins__ContactId__r.AccountId, vlocity_ins__CensusId__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__CensusId__c = :censusId
        ];
        
        for (vlocity_ins__GroupCensusMember__c member : members) {
            if (String.isNotBlank(member.vlocity_ins__SocialSecurityNumber__c)) {
                membersBySSN.put(member.vlocity_ins__SocialSecurityNumber__c, member);
            }
        }
        
        return membersBySSN;
    }
    
    private static Map<String, Account> getExistingPersonAccountsBySSN(List<vlocity_ins__GroupCensusMember__c> censusMembers, Id censusId) {
        Set<String> ssns = new Set<String>();
        for (vlocity_ins__GroupCensusMember__c cm : censusMembers) {
            if (String.isNotBlank(cm.vlocity_ins__SocialSecurityNumber__c)) {
                ssns.add(cm.vlocity_ins__SocialSecurityNumber__c);
            }
        }
        
        Map<String, Account> personAccountsBySSN = new Map<String, Account>();
        if (ssns.isEmpty()) {
            return personAccountsBySSN;
        }
        
        // Query all Person Accounts and filter in code (SSN field is encrypted, can't be filtered in SOQL)
        List<Account> allPersonAccounts = [
            SELECT Id, PersonContactId, vlocity_ins__SocialSecurityNumber__pc, FirstName, LastName
            FROM Account
            WHERE IsPersonAccount = true AND ARC_Census__c = :censusId
        ];
        
        for (Account acc : allPersonAccounts) {
            if (String.isNotBlank(acc.vlocity_ins__SocialSecurityNumber__pc) && 
                ssns.contains(acc.vlocity_ins__SocialSecurityNumber__pc)) {
                personAccountsBySSN.put(acc.vlocity_ins__SocialSecurityNumber__pc, acc);
            }
        }
        
        return personAccountsBySSN;
    }
    
    private static void createOrUpdatePersonAccounts(List<vlocity_ins__GroupCensusMember__c> censusMembers, 
                                                     Id groupAccountId, ProcessResult result, Id censusId, Boolean isCommunity, Boolean isRenewal) {
        // Get existing Person Accounts by SSN (query all and filter in code since SSN is encrypted)
        Map<String, Account> personAccountsBySSN = getExistingPersonAccountsBySSN(censusMembers, censusId);
        
        // Get RecordType for Person Account
        Id personAccountRecordTypeId = getPersonAccountRecordTypeId();
        
        List<Account> accountsToUpsert = new List<Account>();
        Map<String, vlocity_ins__GroupCensusMember__c> ssnToCensusMember = new Map<String, vlocity_ins__GroupCensusMember__c>();
        
        for (vlocity_ins__GroupCensusMember__c cm : censusMembers) {
            if (String.isBlank(cm.vlocity_ins__SocialSecurityNumber__c)) continue;
            
            Account personAccount;
            
            if (personAccountsBySSN.containsKey(cm.vlocity_ins__SocialSecurityNumber__c)) {
                // Update existing Person Account
                personAccount = personAccountsBySSN.get(cm.vlocity_ins__SocialSecurityNumber__c);
            } else {
                // Create new Person Account
                personAccount = new Account();
                if (personAccountRecordTypeId != null) {
                    personAccount.RecordTypeId = personAccountRecordTypeId;
                }
            }
            
            // Populate Person Account fields
            personAccount.FirstName = cm.vlocity_ins__FirstName__c;
            personAccount.LastName = cm.vlocity_ins__LastName__c;
            personAccount.PersonEmail = cm.vlocity_ins__Email__c;
            personAccount.Phone = cm.ARC_Phone__c;
            personAccount.vlocity_ins__SocialSecurityNumber__pc = cm.vlocity_ins__SocialSecurityNumber__c;
            personAccount.PersonBirthdate = cm.vlocity_ins__Birthdate__c;
            personAccount.PersonGender = cm.vlocity_ins__Gender__c;
            personAccount.ARC_HireDate__c = cm.ARC_HireDate__c;
            personAccount.ARC_JobTitle__c = cm.ARC_JobTitle__c;
            personAccount.PersonMailingStreet = cm.ARC_PhysicalAddressStreet__c;
            personAccount.PersonMailingCity = cm.ARC_PhysicalAddressCity__c;
            personAccount.PersonMailingState = cm.ARC_PhysicalAddressState__c;
            personAccount.PersonMailingPostalCode = cm.ARC_PhysicalAddressZipCode__c;
            personAccount.Census_Member__c = cm.Id;
            personAccount.ARC_Census__c = cm.vlocity_ins__CensusId__c;
            personAccount.ARC_AllowEnrollmentOutsideOE__c = isCommunity;
            
            // Renewals: clear waived/termination so re-enrolled members are active
            if (isRenewal) {
                personAccount.ARC_CoverageWaived__c = false;
                personAccount.ARC_TerminationDate__c = null;
            }
            
            accountsToUpsert.add(personAccount);
            ssnToCensusMember.put(cm.vlocity_ins__SocialSecurityNumber__c, cm);
        }
        
        // Upsert Person Accounts
        if (!accountsToUpsert.isEmpty()) {
            Database.UpsertResult[] upsertResults = Database.upsert(accountsToUpsert, false);
            
            // Build map of successful accounts for linking
            Map<Id, Account> successfulAccounts = new Map<Id, Account>();
            for (Integer i = 0; i < upsertResults.size(); i++) {
                if (upsertResults[i].isSuccess()) {
                    Account acc = accountsToUpsert[i];
                    acc.Id = upsertResults[i].getId();
                    successfulAccounts.put(acc.Id, acc);
                } else {
                    Account acc = accountsToUpsert[i];
                    String memberName = acc.FirstName + ' ' + acc.LastName;
                    String friendlyMsg = 'Unable to create account for ' + memberName + '. Please verify the member information.';
                    
                    // Technical details for console
                    String technicalMsg = 'Error upserting Person Account for ' + memberName + ': ';
                    for (Database.Error err : upsertResults[i].getErrors()) {
                        technicalMsg += err.getMessage() + '; ';
                    }
                    System.debug(LoggingLevel.ERROR, technicalMsg);
                    result.technicalErrors.add(technicalMsg);
                    
                    result.errors.add(friendlyMsg);
                }
            }
            
            // Link Person Accounts to Census Members via PersonContactId
            if (!successfulAccounts.isEmpty()) {
                linkPersonAccountsToCensusMembers(successfulAccounts, ssnToCensusMember);
            }
        }
    }
    
    private static void linkPersonAccountsToCensusMembers(Map<Id, Account> accounts, 
                                                          Map<String, vlocity_ins__GroupCensusMember__c> ssnToCensusMember) {
        // Re-query to get PersonContactId (it's populated after insert)
        List<Account> accountsWithContact = [
            SELECT Id, PersonContactId, vlocity_ins__SocialSecurityNumber__pc
            FROM Account
            WHERE Id IN :accounts.keySet()
        ];
        
        List<vlocity_ins__GroupCensusMember__c> membersToUpdate = new List<vlocity_ins__GroupCensusMember__c>();
        
        for (Account acc : accountsWithContact) {
            vlocity_ins__GroupCensusMember__c cm = ssnToCensusMember.get(acc.vlocity_ins__SocialSecurityNumber__pc);
            if (cm != null && cm.vlocity_ins__ContactId__c != acc.PersonContactId) {
                cm.vlocity_ins__ContactId__c = acc.PersonContactId;
                cm.vlocity_ins__AccountId__c = acc.Id;
                membersToUpdate.add(cm);
            }
        }
        
        // Update Census Members with Contact linkage
        if (!membersToUpdate.isEmpty()) {
            update membersToUpdate;
        }
    }
    
    @TestVisible
    private static void deleteMembersNotInCSV(Id censusId, Set<String> csvSSNs, 
                                              Map<String, vlocity_ins__GroupCensusMember__c> existingMembers,
                                              ProcessResult result) {
        List<vlocity_ins__GroupCensusMember__c> membersToDelete = new List<vlocity_ins__GroupCensusMember__c>();
        Set<Id> personAccountIdsToDelete = new Set<Id>();
        
        for (String ssn : existingMembers.keySet()) {
            if (!csvSSNs.contains(ssn)) {
                vlocity_ins__GroupCensusMember__c member = existingMembers.get(ssn);
                membersToDelete.add(member);
                
                // Collect Person Account IDs to delete
                if (member.vlocity_ins__ContactId__r != null && member.vlocity_ins__ContactId__r.AccountId != null) {
                    personAccountIdsToDelete.add(member.vlocity_ins__ContactId__r.AccountId);
                }
            }
        }
        
        if (!membersToDelete.isEmpty()) {
            // Delete Census Members first
            Database.DeleteResult[] deleteResults = Database.delete(membersToDelete, false);
            
            for (Integer i = 0; i < deleteResults.size(); i++) {
                if (deleteResults[i].isSuccess()) {
                    result.deleted++;
                } else {
                    String memberName = membersToDelete[i].vlocity_ins__FirstName__c + ' ' + membersToDelete[i].vlocity_ins__LastName__c;
                    String friendlyMsg = 'Unable to remove ' + memberName + ' from the system.';
                    
                    // Log technical details
                    String technicalMsg = 'Error deleting member ' + memberName + ': ';
                    for (Database.Error err : deleteResults[i].getErrors()) {
                        technicalMsg += err.getMessage() + '; ';
                    }
                    System.debug(LoggingLevel.ERROR, technicalMsg);
                    
                    result.errors.add(friendlyMsg);
                }
            }
            
            // Delete associated Person Accounts
            if (!personAccountIdsToDelete.isEmpty()) {
                Database.DeleteResult[] accountDeleteResults = Database.delete(
                    new List<Id>(personAccountIdsToDelete), 
                    false
                );
                
                for (Database.DeleteResult deleteResult : accountDeleteResults) {
                    if (!deleteResult.isSuccess()) {
                        String friendlyMsg = 'Unable to remove a member account from the system.';
                        
                        // Log technical details
                        String technicalMsg = 'Error deleting Person Account: ';
                        for (Database.Error err : deleteResult.getErrors()) {
                            technicalMsg += err.getMessage() + '; ';
                        }
                        System.debug(LoggingLevel.ERROR, technicalMsg);
                        
                        result.errors.add(friendlyMsg);
                    }
                }
            }
        }
    }
    
    private static Id getPersonAccountRecordTypeId() {
        try {
            Id smallGroupRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_SGPersonAccount').getRecordTypeId();
            return smallGroupRTId;
        } catch (Exception e) {
            System.debug('No Person Account RecordType found: ' + e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getCensusStats(Id oppId) {
        Map<String, Object> stats = new Map<String, Object>();
        
        try {
            Opportunity opp = [SELECT Id, AccountId, ARC_CensusCsvUploaded__c FROM Opportunity WHERE Id = :oppId LIMIT 1];
            
            List<vlocity_ins__GroupCensus__c> censusList = [
                SELECT Id
                FROM vlocity_ins__GroupCensus__c 
                WHERE vlocity_ins__GroupId__c = :opp.AccountId 
                LIMIT 1
            ];
            
            if (!censusList.isEmpty()) {
                Id censusId = censusList[0].Id;
                stats.put('censusId', censusId);
                
                // Count members separately
                Integer memberCount = [
                    SELECT COUNT() 
                    FROM vlocity_ins__GroupCensusMember__c 
                    WHERE vlocity_ins__CensusId__c = :censusId
                ];
                stats.put('memberCount', memberCount);
            } else {
                stats.put('censusId', null);
                stats.put('memberCount', 0);
            }
            
            stats.put('csvUploaded', opp.ARC_CensusCsvUploaded__c == true);
            
        } catch (Exception e) {
            stats.put('error', e.getMessage());
        }
        
        return stats;
    }
    
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getCensusStatsCommunity() {
        Map<String, Object> stats = new Map<String, Object>();
        
        try {
            // Get running user's Account
            Id userId = UserInfo.getUserId();
            User currentUser = [SELECT ContactId, Contact.AccountId FROM User WHERE Id = :userId LIMIT 1];
            
            if (currentUser.ContactId == null || currentUser.Contact.AccountId == null) {
                stats.put('error', 'Unable to determine your account.');
                return stats;
            }
            
            Id accountId = currentUser.Contact.AccountId;
            
            List<vlocity_ins__GroupCensus__c> censusList = [
                SELECT Id
                FROM vlocity_ins__GroupCensus__c 
                WHERE vlocity_ins__GroupId__c = :accountId 
                LIMIT 1
            ];
            
            if (!censusList.isEmpty()) {
                Id censusId = censusList[0].Id;
                stats.put('censusId', censusId);
                
                // Count members separately
                Integer memberCount = [
                    SELECT COUNT() 
                    FROM vlocity_ins__GroupCensusMember__c 
                    WHERE vlocity_ins__CensusId__c = :censusId
                ];
                stats.put('memberCount', memberCount);
            } else {
                stats.put('censusId', null);
                stats.put('memberCount', 0);
            }
            
        } catch (Exception e) {
            stats.put('error', e.getMessage());
        }
        
        return stats;
    }
}