public with sharing class ARC_IndividualEnrollmentHelper {

   public static Map<String, Object> validateEnrollmentData(Map<String, Object> enrollmentData) {
        Map<String, Object> validationResult = new Map<String, Object>();
        List<String> errors = new List<String>();
        Boolean isValid = true;
        String primaryName = '';
        
        try {
            
            if (enrollmentData == null) {
                errors.add('Enrollment data is null');
                isValid = false;
            } else {
                if (!enrollmentData.containsKey('generalInformation') || enrollmentData.get('generalInformation') == null) {
                    errors.add('generalInformation node is missing or null');
                    isValid = false;
                } else {
                    Object generalInfoObj = enrollmentData.get('generalInformation');
                    if (!(generalInfoObj instanceof Map<String, Object>)) {
                        errors.add('generalInformation must be an object, got: ' + generalInfoObj);
                        isValid = false;
                    } else {
                        Map<String, Object> generalInfo = (Map<String, Object>)generalInfoObj;
                        
                        if (!generalInfo.containsKey('effectiveDate') || String.isBlank((String)generalInfo.get('effectiveDate'))) {
                            errors.add('effectiveDate is missing or empty in generalInformation');
                            isValid = false;
                        }
                        
                        if (!generalInfo.containsKey('medicalProgram') || generalInfo.get('medicalProgram') == null) {
                            errors.add('medicalProgram is missing or null in generalInformation');
                            isValid = false;
                        } else {
                            Object medicalProgramObj = generalInfo.get('medicalProgram');
                            if (!(medicalProgramObj instanceof Map<String, Object>)) {
                                errors.add('medicalProgram must be an object, got: ' + medicalProgramObj);
                                isValid = false;
                            } else {
                                Map<String, Object> medicalProgram = (Map<String, Object>)medicalProgramObj;
                                if (!medicalProgram.containsKey('productId') || String.isBlank((String)medicalProgram.get('productId'))) {
                                    errors.add('medicalProgram.productId is missing or empty');
                                    isValid = false;
                                }
                            }
                        }

                        if (!generalInfo.containsKey('leadId') || String.isBlank(String.valueOf(generalInfo.get('leadId')))) {
                            errors.add('leadId is missing or null');
                            isValid = false;
                        }
                        
                        if (!generalInfo.containsKey('payment') || generalInfo.get('payment') == null) {
                            errors.add('payment information is missing or null in generalInformation');
                            isValid = false;
                        } else {
                            Object paymentObj = generalInfo.get('payment');
                            if (!(paymentObj instanceof Map<String, Object>)) {
                                errors.add('payment must be an object, got: ' + paymentObj);
                                isValid = false;
                            } else {
                                Map<String, Object> payment = (Map<String, Object>)paymentObj;
                                if (!payment.containsKey('paymentMethod') || String.isBlank((String)payment.get('paymentMethod'))) {
                                    errors.add('paymentMethod is missing or empty in payment');
                                    isValid = false;
                                } else {
                                    String paymentMethod = (String)payment.get('paymentMethod');
                                    if (paymentMethod == 'credit_card') {
                                        if (!payment.containsKey('creditCard') || payment.get('creditCard') == null) {
                                            errors.add('creditCard information is missing for credit card payment method');
                                            isValid = false;
                                        }
                                    } else if (paymentMethod == 'bank_account') {
                                        if (!payment.containsKey('bankAccount') || payment.get('bankAccount') == null) {
                                            errors.add('bankAccount information is missing for bank account payment method');
                                            isValid = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                if (!enrollmentData.containsKey('members') || enrollmentData.get('members') == null) {
                    errors.add('members node is missing or null');
                    isValid = false;
                } else {
                    Object membersObj = enrollmentData.get('members');
                    if (!(membersObj instanceof List<Object>)) {
                        errors.add('members must be an array, got: ' + membersObj);
                        isValid = false;
                    } else {
                        List<Object> members = (List<Object>)membersObj;
                        if (members.isEmpty()) {
                            errors.add('members list is empty');
                            isValid = false;
                        } else {
                            Boolean hasPrimaryMember = false;
                            Integer memberIndex = 0;
                            
                            for (Object memberObj : members) {
                                if (!(memberObj instanceof Map<String, Object>)) {
                                    errors.add('member[' + memberIndex + '] must be an object, got: ' + memberObj);
                                    isValid = false;
                                    memberIndex++;
                                    continue;
                                }
                                
                                Map<String, Object> member = (Map<String, Object>)memberObj;
                                
                                if (!member.containsKey('role') || String.isBlank((String)member.get('role'))) {
                                    errors.add('member[' + memberIndex + '].role is missing or empty');
                                    isValid = false;
                                } else {
                                    String role = (String)member.get('role');
                                    if (role == 'Primary') {
                                        hasPrimaryMember = true;
                                    }
                                }                                
                                if (!member.containsKey('memberExternalId') || String.isBlank((String)member.get('memberExternalId'))) {
                                    errors.add('member[' + memberIndex + '].memberExternalId is missing or empty');
                                    isValid = false;
                                }                                
                                if (!member.containsKey('person') || member.get('person') == null) {
                                    errors.add('member[' + memberIndex + '].person is missing or null');
                                    isValid = false;
                                } else {
                                    Object personObj = member.get('person');
                                    if (!(personObj instanceof Map<String, Object>)) {
                                        errors.add('member[' + memberIndex + '].person must be an object, got: ' + personObj);
                                        isValid = false;
                                    } else {
                                        Map<String, Object> person = (Map<String, Object>)personObj;
                                        
                                        if (!person.containsKey('firstName') || String.isBlank((String)person.get('firstName'))) {
                                            errors.add('member[' + memberIndex + '].person.firstName is missing or empty');
                                            isValid = false;
                                        }
                                        
                                        if (!person.containsKey('lastName') || String.isBlank((String)person.get('lastName'))) {
                                            errors.add('member[' + memberIndex + '].person.lastName is missing or empty');
                                            isValid = false;
                                        }
                                        
                                        if (!person.containsKey('dob') || String.isBlank((String)person.get('dob'))) {
                                            errors.add('member[' + memberIndex + '].person.dob is missing or empty');
                                            isValid = false;
                                        }
                                        
                                        if (!person.containsKey('gender') || String.isBlank((String)person.get('gender'))) {
                                            errors.add('member[' + memberIndex + '].person.gender is missing or empty');
                                            isValid = false;
                                        }
                                        
                                        Boolean sameAddressAsPrimary = person.containsKey('sameAddressAsPrimary') ? 
                                            convertToBoolean(person.get('sameAddressAsPrimary')) : false;
                                        
                                        if (!sameAddressAsPrimary) {
                                            if (!person.containsKey('address') || person.get('address') == null) {
                                                errors.add('member[' + memberIndex + '].person.address is missing or null (required when sameAddressAsPrimary is false)');
                                                isValid = false;
                                            } else {
                                                Object addressObj = person.get('address');
                                                
                                                if (addressObj instanceof String) {
                                                    String addressStr = (String)addressObj;
                                                    if (String.isBlank(addressStr) || addressStr.equalsIgnoreCase('null')) {
                                                        errors.add('member[' + memberIndex + '].person.address is null or empty string (required when sameAddressAsPrimary is false)');
                                                        isValid = false;
                                                    } else {
                                                        errors.add('member[' + memberIndex + '].person.address must be an object, got string: ' + addressStr);
                                                        isValid = false;
                                                    }
                                                } else if (!(addressObj instanceof Map<String, Object>)) {
                                                    errors.add('member[' + memberIndex + '].person.address must be an object, got: ' + addressObj);
                                                    isValid = false;
                                                } else {
                                                    Map<String, Object> address = (Map<String, Object>)addressObj;
                                                    if (!address.containsKey('street') || String.isBlank((String)address.get('street'))) {
                                                        errors.add('member[' + memberIndex + '].person.address.street is missing or empty');
                                                        isValid = false;
                                                    }
                                                    if (!address.containsKey('city') || String.isBlank((String)address.get('city'))) {
                                                        errors.add('member[' + memberIndex + '].person.address.city is missing or empty');
                                                        isValid = false;
                                                    }
                                                    if (!address.containsKey('state') || String.isBlank((String)address.get('state'))) {
                                                        errors.add('member[' + memberIndex + '].person.address.state is missing or empty');
                                                        isValid = false;
                                                    }
                                                    if (!address.containsKey('zip') || String.isBlank((String)address.get('zip'))) {
                                                        errors.add('member[' + memberIndex + '].person.address.zip is missing or empty');
                                                        isValid = false;
                                                    }
                                                }
                                            }
                                        } else {
                                            System.debug('Member[' + memberIndex + '] has sameAddressAsPrimary=true, skipping address validation');
                                        }
                                    }
                                }
                                
                                memberIndex++;
                            }
                            
                            if (!hasPrimaryMember) {
                                errors.add('No primary member found in members list');
                                isValid = false;
                            }
                        }
                    }
                }
            }
            
            System.debug('Enrollment data validation completed. Valid: ' + isValid + ', Errors: ' + errors.size());
            
        } catch (Exception e) {
            System.debug('Error during enrollment data validation: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            errors.add('Validation error: ' + e.getMessage());
            isValid = false;
        }
        
        validationResult.put('isValid', isValid);
        validationResult.put('errors', errors);
        validationResult.put('errorCount', errors.size());
        validationResult.put('PrimaryName', primaryName);
        
      
        if (!isValid) {
            Map<String, Object> fieldValidation = new Map<String, Object>();
            fieldValidation.put('failedFields', errors);
            fieldValidation.put('summary', 'Validation failed for ' + errors.size() + ' field(s)');
            validationResult.put('fieldValidation', fieldValidation);
        }
        
        return validationResult;
    }

    /**
     * @Description: Converts a value to Boolean
     * @param value: The value to convert
     * @return Boolean: The converted boolean value
     */
    public static Boolean convertToBoolean(Object value) {
        if (value == null) return null;
        if (value instanceof Boolean) return (Boolean)value;
        if (value instanceof String) {
            String strValue = (String)value;
            return strValue.equalsIgnoreCase('true') || strValue.equals('1');
        }
        return null;
    }

    /**
     * @Description: Gets members data from primary member
     * @param memberId: The member ID to query
     * @return Map<String, Object>: Map containing member data
     */
    public static Map<String, Object> getMembersDataFromPrimary(String memberId) {
        Map<String, Object> out = new Map<String, Object>();
        List<vlocity_ins__GroupCensusMember__c> members = [
            SELECT Id, Name, vlocity_ins__Gender__c, ARC_Age__c, vlocity_ins__Birthdate__c,
                   ARC_Smoker__c, vlocity_ins__Email__c, ARC_Weight__c, ARC_Height__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__RelatedCensusMemberId__c = :memberId OR Id = :memberId
        ];
        for (vlocity_ins__GroupCensusMember__c m : members) {
            out.put(m.Id, new Map<String, Object>{
                'id'=>m.Id, 'name'=>m.Name, 'gender'=>m.vlocity_ins__Gender__c, 'age'=>m.ARC_Age__c,
                'birthdate'=>m.vlocity_ins__Birthdate__c, 'smoker'=>m.ARC_Smoker__c,
                'email'=>m.vlocity_ins__Email__c, 'weight'=>m.ARC_Weight__c, 'height'=>m.ARC_Height__c
            });
        }
        return out;
    }

    /**
     * @Description: Creates integration log record
     * @param operation: The operation being logged
     * @param requestBody: The request body data
     * @return String: The ID of the created log record
     */
    public static String createIntegrationLog(String operation, Map<String,Object> requestBody) {
        try {
            DateTime startTime = DateTime.now();
            
            String primaryName = '';
            System.debug('createIntegrationLog 1');
            Object membersObj = requestBody.get('members');
            System.debug('createIntegrationLog 2');
            List<Object> members = (List<Object>)membersObj;
            System.debug('createIntegrationLog 3');
            for (Object memberObj : members) {
                System.debug('createIntegrationLog 4');
                Map<String, Object> member = (Map<String, Object>)memberObj;                                
                if (member.containsKey('role')) {
                    System.debug('createIntegrationLog 5');
                    String role = (String)member.get('role');
                    if (role == 'Primary') {
                        System.debug('createIntegrationLog 6');
                        Map<String,Object> person = (Map<String,Object>)member.get('person');
                        System.debug('createIntegrationLog 7');
                        primaryName = person.get('firstName') + ' ' + person.get('lastName');
                        System.debug('createIntegrationLog 8' + primaryName);
                    }
                }
            }

            String jsonString = JSON.serialize(requestBody);
            String jsonPart1 = '';
            String jsonPart2 = '';
            
            if (jsonString.length() > 131072) {  
                jsonPart1 = jsonString.substring(0, 131072);
                jsonPart2 = jsonString.length() > 262144 ? jsonString.substring(131072, 262144) : jsonString.substring(131072);
            } else {
                jsonPart1 = jsonString;
            }
            
            ARC_IntegrationLog__c logRecord = new ARC_IntegrationLog__c(
                Direction__c = 'Inbound',
                DurationMs__c = 0,  
                Endpoint__c = '/api/v1/individual-enrollment/' + operation,
                ErrorCode__c = null,
                ErrorMessage__c = null,
                FinishedAt__c = null,
                HttpStatus__c = 200,
                Operation__c = 'POST',
                RawJSON_Part1__c = jsonPart1,
                RawJSON_Part2__c = jsonPart2,
                RetryCount__c = 0,
                Service__c = 'processSelfEnrollment',
                StartedAt__c = startTime,
                Success__c = true,
                ARC_PrimaryName__c = primaryName
            );
            
            insert logRecord;
            System.debug('Integration log created with ID: ' + logRecord.Id);
            return logRecord.Id;
        } catch (Exception e) {
            System.debug('Error creating integration log: ' + e.getMessage() + ' ' + e.getStackTraceString() + ' ' + e.getLineNumber());           
            return null;
        }
    }

    /**
     * @Description: Updates integration log record with completion details
     * @param logId: The ID of the log record to update
     * @param success: Whether the operation was successful
     * @param httpStatus: HTTP status code
     * @param errorCode: Error code if applicable
     * @param errorMessage: Error message if applicable
     * @param finishedAt: When the operation finished
     * @param durationMs: Duration in milliseconds
     */
    public static void updateIntegrationLog(String logId, Boolean success, Integer httpStatus, String errorCode, String errorMessage, DateTime finishedAt, Long durationMs, Id groupAccountId, String groupAccountName) {
        try {
            ARC_IntegrationLog__c logRecord = new ARC_IntegrationLog__c(
                Id = logId,
                Success__c = success,
                HttpStatus__c = httpStatus,
                ErrorCode__c = errorCode,
                ErrorMessage__c = errorMessage, 
                FinishedAt__c = finishedAt,
                DurationMs__c = durationMs,
                ARC_GroupAccount__c = groupAccountId,
                ARC_GroupAccountName__c = groupAccountName
            );
            
            update logRecord;
            System.debug('Integration log updated with ID: ' + logId);
        } catch (Exception e) {
            System.debug('Error updating integration log: ' + e.getMessage());           
        }
    }

    /**
     * @Description: Logs errors to Custom_Logs__c for debugging purposes
     * @param errorContext: Context where the error occurred
     * @param e: The exception that occurred
     * @param requestData: The request data that caused the error
     */
    public static void logError(String errorContext, Exception e, String requestData) {
        try {
            Integer MAX_FIELD_SIZE = 131072 - 10;
            
            Custom_Logs__c log = new Custom_Logs__c();
            log.Name = errorContext;
            log.OwnerId = UserInfo.getUserId();
            log.Status__c = 'New';
            
            String logData = 'Error: ' + e.getMessage() + '\n\nRequest Data: ' + requestData + '\n\nStack Trace: ' + e.getStackTraceString();
            
            if (logData.length() > MAX_FIELD_SIZE) {
                log.Log__c = logData.substring(0, MAX_FIELD_SIZE);
                if (logData.length() > MAX_FIELD_SIZE) {
                    Integer remainingLength = Math.min(logData.length() - MAX_FIELD_SIZE, MAX_FIELD_SIZE);
                    log.Log_2__c = logData.substring(MAX_FIELD_SIZE, MAX_FIELD_SIZE + remainingLength);
                }
            } else {
                log.Log__c = logData;
            }
            
            insert log;
        } catch (Exception logException) {
            System.debug('Failed to log error: ' + logException.getMessage());
        }
    }

    /**
     * @Description: Helper method to find primary member from members array
     * @param members: List of member objects
     * @return: Primary member object or null if not found
     */
    private static Map<String, Object> findPrimaryMember(List<Object> members) {
        if (members == null || members.isEmpty()) {
            return null;
        }
        
        for (Object memberObj : members) {
            Map<String, Object> member = (Map<String, Object>) memberObj;
            String role = (String) member.get('role');
            if (role != null && role.equalsIgnoreCase('Primary')) {
                return member;
            }
        }
        return null;
    }

    /**
     * @Description: Creates/Updates the Lead and LeadSource for Self Enrollment and returns the LeadId and LeadSourceId to the OS JSON.
     * @param inputMap: Input parameters map
     * @param outputMap: Output parameters map
     * @param options: Options map
     */
    public static void upsertLeadSourceReferral(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        Id inputLeadId;
        if(String.isNotBlank(String.valueOf(inputMap.get('leadId')))) inputLeadId = (Id)inputMap.get('leadId');
        String inputEmail = (String)inputMap.get('email');
        String inputPhone = (String)inputMap.get('phone');
        Id leadRecordId; 
        List<Lead> leadRecords = new List<Lead>();
        try{
            if(inputLeadId != null) leadRecords = [SELECT Id, FirstName, LastName, Phone, Email  FROM Lead WHERE Id =: inputLeadId];
            else if(String.isNotBlank(inputEmail) && String.isNotBlank(inputPhone)){
                leadRecords = [SELECT Id, FirstName, LastName, Phone, Email  FROM Lead WHERE Phone_Digits__c =: inputPhone AND Email =: inputEmail LIMIT 1];
                if(leadRecords.size()==0) leadRecords = [SELECT Id, FirstName, LastName, Phone, Email FROM Lead WHERE Phone_Digits__c =: inputPhone OR Phone =: inputPhone OR Email =: inputEmail LIMIT 1];
            }
            if(leadRecords.size()==0){
                Lead newLead = new Lead();
                newLead.HealthCloudGA__BirthDate__c = Date.valueOf(String.valueOf(inputMap.get('birthdate')));
                newLead.City = (String)inputMap.get('city');
                newLead.Email = (String)inputMap.get('email');
                newLead.FirstName = (String)inputMap.get('firstName');
                newLead.HealthCloudGA__Gender__c = (String)inputMap.get('gender');
                newLead.LastName = (String)inputMap.get('lastName');
                newLead.Phone = (String)inputMap.get('phone');
                newLead.State = (String) inputMap.get('state');
                newLead.Street = (String) inputMap.get('street');
                newLead.PostalCode = (String) inputMap.get('zipCode');
                newLead.Status = 'Self Enrolling';
                newLead.LeadSource = 'Self Enroll';
                insert newLead;
                leadRecordId= newLead.Id;
            }
            else{
                leadRecordId = leadRecords[0].Id;
            } 

            Lead_Source__c leadSource = new Lead_Source__c();
            leadSource.Lead_Address_City__c = (String)inputMap.get('city');
            leadSource.Lead_Email__c = (String)inputMap.get('email');
            leadSource.Lead_First_Name__c = (String)inputMap.get('firstName');
            leadSource.Lead_Last_Name__c = (String)inputMap.get('lastName');
            leadSource.Lead__c = leadRecordId;
            if(String.isNotBlank(String.valueOf(inputMap.get('leadSourceId')))) leadSource.Id = (Id)inputMap.get('leadSourceId');
            leadSource.Lead_Phone__c = (String)inputMap.get('phone');
            leadSource.Source_Name__c = 'Self Enroll';
            leadSource.Lead_Address_Zip__c = (String)inputMap.get('zipCode');
            leadSource.Lead_Address_Street__c = (String)inputMap.get('street');
            leadSource.Lead_Address_State__c = (String)inputMap.get('state');
            leadSource.LeadsRX_Id__c = (String)inputMap.get('cookieId');
            upsert leadSource;
            outputMap.put('LeadId',leadRecordId);
            outputMap.put('LeadSourceId',leadSource.Id);
            outputMap.put('success',true);
        }catch(Exception e){
             outputMap.put('success',false);
        }
    }

    /**
     * @Description: Validates essential fields in the lead data for lead creation
     * @param leadData: Map containing the lead data to validate
     * @return Map<String, Object>: Validation result with success flag and error messages
     */
    public static Map<String, Object> validateLeadData(Map<String, Object> leadData) {
        Map<String, Object> validationResult = new Map<String, Object>();
        List<String> errors = new List<String>();
        Boolean isValid = true;
        
        try {
            System.debug('Starting lead data validation');
            system.debug('leadData: '+leadData);
            
            if (leadData == null) {
                errors.add('Lead data is null');
                isValid = false;
            } else {
                String firstName = (String)leadData.get('firstName');
                String lastName = (String)leadData.get('lastName');
                String email = (String)leadData.get('email');
                String phone = (String)leadData.get('phone');
                String birthdate = (String)leadData.get('birthdate');
                String gender = (String)leadData.get('gender');
                String street = (String)leadData.get('street');
                String city = (String)leadData.get('city');
                String state = (String)leadData.get('state');
                String zipCode = (String)leadData.get('zipCode');
                String cookieId = (String)leadData.get('cookieId');
                
                if (String.isBlank(firstName)) {
                    errors.add('firstName is missing or empty');
                    isValid = false;
                }
                
                if (String.isBlank(lastName)) {
                    errors.add('lastName is missing or empty');
                    isValid = false;
                }
                
                if (String.isBlank(email)) {
                    errors.add('email is missing or empty');
                    isValid = false;
                }
                
                if (String.isBlank(phone)) {
                    errors.add('phone is missing or empty');
                    isValid = false;
                }
                
                if (String.isNotBlank(email) && !Pattern.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$', email)) {
                    errors.add('email format is invalid');
                    isValid = false;
                }
                
                if (String.isNotBlank(phone) && !Pattern.matches('^[\\d\\s\\-\\(\\)\\+]+$', phone)) {
                    errors.add('phone format contains invalid characters');
                    isValid = false;
                }
                
                if (String.isNotBlank(birthdate)) {
                    try {
                        Date.valueOf(birthdate);
                    } catch (Exception e) {
                        errors.add('birthdate format is invalid. Expected format: YYYY-MM-DD');
                        isValid = false;
                    }
                }
                
                if (String.isNotBlank(gender)) {
                    List<String> validGenders = new List<String>{'Male', 'Female', 'Other', 'Unknown'};
                    if (!validGenders.contains(gender)) {
                        errors.add('gender must be one of: Male, Female, Other, Unknown');
                        isValid = false;
                    }
                }
                
                Boolean hasAnyAddressField = String.isNotBlank(street) || String.isNotBlank(city) || 
                                           String.isNotBlank(state) || String.isNotBlank(zipCode);
                
                if (hasAnyAddressField) {
                    if (String.isBlank(street)) {
                        errors.add('street is required when address information is provided');
                        isValid = false;
                    }
                    if (String.isBlank(city)) {
                        errors.add('city is required when address information is provided');
                        isValid = false;
                    }
                    if (String.isBlank(state)) {
                        errors.add('state is required when address information is provided');
                        isValid = false;
                    }
                    if (String.isBlank(zipCode)) {
                        errors.add('zipCode is required when address information is provided');
                        isValid = false;
                    }
                }
                
                if (String.isNotBlank(zipCode) && !Pattern.matches('^\\d{5}(-\\d{4})?$', zipCode)) {
                    errors.add('zipCode format is invalid. Expected format: 12345 or 12345-6789');
                    isValid = false;
                }
                
                if (String.isNotBlank(state) && !Pattern.matches('^[A-Z]{2}$', state)) {
                    errors.add('state must be a 2-letter state code (e.g., CA, NY, TX)');
                    isValid = false;
                }
            }
            
            validationResult.put('isValid', isValid);
            validationResult.put('errors', errors);
            validationResult.put('errorCount', errors.size());
            
            System.debug('Lead validation completed. Valid: ' + isValid + ', Errors: ' + errors.size());
            
        } catch (Exception e) {
            System.debug('Exception during lead validation: ' + e.getMessage());
            validationResult.put('isValid', false);
            validationResult.put('errors', new List<String>{'Validation error: ' + e.getMessage()});
            validationResult.put('errorCount', 1);
        }
        
        return validationResult;
    }

    /**
     * @Description: Validates essential fields in the promotion code data
     * @param promotionData: Map containing the promotion code data to validate
     * @return Map<String, Object>: Validation result with success flag and error messages
     */
    public static Map<String, Object> validatePromotionCodeData(Map<String, Object> promotionData) {
        Map<String, Object> validationResult = new Map<String, Object>();
        List<String> errors = new List<String>();
        Boolean isValid = true;
        
        try {
            System.debug('Starting promotion code data validation');
            System.debug('promotionData: ' + promotionData);
            
            if (promotionData == null) {
                errors.add('Promotion code data is null');
                isValid = false;
            } else {
                String promotionCode = (String)promotionData.get('promotionCode');
                
                if (String.isBlank(promotionCode)) {
                    errors.add('promotionCode is missing or empty');
                    isValid = false;
                } else {
                    promotionCode = promotionCode != null ? promotionCode.trim() : promotionCode;
                    if (!Pattern.matches('^[a-zA-Z0-9 ]{3,20}$', promotionCode)) {
                        errors.add('promotionCode format is invalid. Must be 3-20 characters: letters, numbers, and spaces only');
                        isValid = false;
                    }
                }
            }
            
            validationResult.put('isValid', isValid);
            validationResult.put('errors', errors);
            validationResult.put('errorCount', errors.size());
            
            System.debug('Promotion code validation completed. Valid: ' + isValid + ', Errors: ' + errors.size());
            
        } catch (Exception e) {
            System.debug('Exception during promotion code validation: ' + e.getMessage());
            validationResult.put('isValid', false);
            validationResult.put('errors', new List<String>{'Validation error: ' + e.getMessage()});
            validationResult.put('errorCount', 1);
        }
        
        return validationResult;
    }

    /**
     * @Description: Validates promotion code and returns discount percentage if valid
     * @param promotionCode: The promotion code to validate
     * @return Map<String, Object>: Validation result with discount percentage or error message
     */
    public static Map<String, Object> validatePromotionCode(String promotionCode) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            System.debug('Validating promotion code: ' + promotionCode);
            
            List<ARC_PromotionCode__c> promotionCodes = [
                SELECT Id, OwnerId, Name, RecordTypeId, CreatedDate, CreatedById, 
                       LastModifiedDate, LastModifiedById, SystemModstamp, LastViewedDate, 
                       LastReferencedDate, ARC_DiscountRate__c, ARC_DiscountType__c, 
                       ARC_DiscountedAmount__c, ARC_EndDate__c, ARC_NumbeOfRecurringPaymentsToDiscount__c, 
                       ARC_NumberOfTimesCanBeUsed__c, ARC_PromotionCode__c, ARC_StartDate__c, 
                       ARC_NumberOfTimesUsed__c, ARC_NumberOfTransactions__c, ARC_Active__c, 
                       ARC_FormulaForNumbOfTimesCanBeUsed__c, ARC_MoneySaved__c, ARC_ApplyOver__c, 
                       ARC_ApplyFirst__c, ARC_RenewalDiscountNumber__c 
                FROM ARC_PromotionCode__c 
                WHERE ARC_Active__c = true 
                AND ARC_PromotionCode__c = :promotionCode
                LIMIT 1
            ];
            
            if (promotionCodes.isEmpty()) {
                result.put('isValid', false);
                result.put('message', 'Invalid promotion code');
                System.debug('No active promotion code found for: ' + promotionCode);
            } else {
                ARC_PromotionCode__c promotion = promotionCodes[0];
                
                Date currentDate = Date.today();
                Boolean isWithinDateRange = true;
                
                if (promotion.ARC_StartDate__c != null && currentDate < promotion.ARC_StartDate__c) {
                    isWithinDateRange = false;
                    System.debug('Promotion code not yet active. Start date: ' + promotion.ARC_StartDate__c);
                }
                
                if (promotion.ARC_EndDate__c != null && currentDate > promotion.ARC_EndDate__c) {
                    isWithinDateRange = false;
                    System.debug('Promotion code has expired. End date: ' + promotion.ARC_EndDate__c);
                }
                
                Boolean isWithinUsageLimit = true;
                if (promotion.ARC_NumberOfTimesCanBeUsed__c != null && 
                    promotion.ARC_NumberOfTimesUsed__c != null &&
                    promotion.ARC_NumberOfTimesUsed__c >= promotion.ARC_NumberOfTimesCanBeUsed__c) {
                    isWithinUsageLimit = false;
                    System.debug('Promotion code usage limit exceeded');
                }
                
                if (!isWithinDateRange) {
                    result.put('isValid', false);
                    result.put('message', 'Promotion code is not currently active');
                } else if (!isWithinUsageLimit) {
                    result.put('isValid', false);
                    result.put('message', 'Promotion code usage limit has been reached');
                } else {
                    Decimal discountPercentage = promotion.ARC_DiscountRate__c;
                    
                    result.put('isValid', true);
                    result.put('discountPercentage', discountPercentage);
                    result.put('promotionId', promotion.Id);
                    result.put('promotionName', promotion.Name);
                    result.put('discountType', promotion.ARC_DiscountType__c);
                    result.put('discountedAmount', promotion.ARC_DiscountedAmount__c);
                    result.put('startDate', promotion.ARC_StartDate__c);
                    result.put('endDate', promotion.ARC_EndDate__c);
                    result.put('timesUsed', promotion.ARC_NumberOfTimesUsed__c);
                    result.put('timesCanBeUsed', promotion.ARC_NumberOfTimesCanBeUsed__c);
                    result.put('numberOfRecurringPaymentsToDiscount', promotion.ARC_NumbeOfRecurringPaymentsToDiscount__c);

                    
                    System.debug('Valid promotion code found. Discount percentage: ' + discountPercentage);
                }
            }
            
        } catch (Exception e) {
            System.debug('Error validating promotion code: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            result.put('isValid', false);
            result.put('message', 'Error validating promotion code: ' + e.getMessage());
        }
        
        return result;
    }
}