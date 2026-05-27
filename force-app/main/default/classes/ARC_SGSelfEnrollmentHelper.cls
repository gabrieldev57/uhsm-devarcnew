public with sharing class ARC_SGSelfEnrollmentHelper {
    /** fields in the enrollment data
     * @param inputData: Map containing the enrollment data to validate
     * @param outputMap: Map to store validation results
     * @return Map<String, Object>: Response data with validation results
     */
    public static Map<String, Object> validateEnrollmentData(Map<String, Object> inputData, Map<String, Object> outputMap) {
        Map<String, Object> response = new Map<String, Object>();
        try {

            List<String> allErrors = new List<String>();

            if (!inputData.containsKey('enrollmentId') || inputData.get('enrollmentId') == null) {
                return setError(response, outputMap, 'Error enrollmentId is required');
            }
            if (!inputData.containsKey('traceId') || inputData.get('traceId') == null) {
                return setError(response, outputMap, 'Error traceId is required');
            }
            // ---------------------------------------------------------
            // VALIDATE GENERAL INFORMATION
            // ---------------------------------------------------------
            if (!inputData.containsKey('generalInformation') || inputData.get('generalInformation') == null) {
                allErrors.add('Error generalInformation is required');
            }
            else {
                Map<String, Object> generalInformation = (Map<String, Object>)inputData.get('generalInformation');
            
                // List of required fields in generalInformation
                List<String> requiredGenInfoFields = new List<String>{
                    'accountId', 'censusId', 'groupAccountId', 'contractId', 'primaryCensusMemberId', 'effectiveDate', 'totalMonthlyPremium', 'signerEmail'
                };

                List<String> missingGenField = checkMissingFields(generalInformation, requiredGenInfoFields);
                if (!missingGenField.isEmpty()) {
                    allErrors.add('Error in generalInformation: ' + String.join(missingGenField, ', ') + ' is required');
                }

                // ---------------------------------------------------------
                // VALIDATE GUARDIAN
                // ---------------------------------------------------------
                if (generalInformation.containsKey('guardian') && generalInformation.get('guardian') != null) {
                    Map<String, Object> guardian = (Map<String, Object>)generalInformation.get('guardian');

                    // List of required fields in guardian
                    List<String> requiredGuardianFields = new List<String>{
                        'firstName', 'lastName', 'dob', 'gender', 'email', 'phone', 'ssn', 'relationship'
                    };

                    List<String> missingGuardianField = checkMissingFields(guardian, requiredGuardianFields);
                    if (!missingGuardianField.isEmpty()) {
                        allErrors.add('Error in generalInformation:guardian: ' + String.join(missingGuardianField, ', ') + ' is required');
                    }

                    if (guardian.containsKey('address') && guardian.get('address') != null) {
                        Map<String, Object> guardianAddress = (Map<String, Object>)guardian.get('address');

                        // List of required address fields in guardian
                        List<String> requiredGuardianAddressField = new List<String>{
                            'street', 'city', 'state', 'zip'
                        };
                        List<String> missingGuardianAddressField = checkMissingFields(guardianAddress, requiredGuardianAddressField);
                        if (!missingGuardianAddressField.isEmpty()) {
                            allErrors.add('Error in generalInformation:guardian:address: ' + String.join(missingGuardianAddressField, ', ') + ' is required');
                        }
                    } else {
                        allErrors.add('Error in generalInformation:guardian: address is required');
                    } 
                }

                // ---------------------------------------------------------
                // VALIDATE HIPAA
                // ---------------------------------------------------------
                if (!generalInformation.containsKey('hipaa') || generalInformation.get('hipaa') == null) {
                    allErrors.add('Error in generalInformation: hipaa is required');
                }
                else {
                    List<Object> hipaaList = (List<Object>)generalInformation.get('hipaa');

                    List<String> requiredHipaaAddress = new List<String>{
                        'street', 'city', 'state', 'zip'
                    };

                    List<String> aux = new List<String> {'CHK_Authorized', 'phone', 'relationship', 'lastName', 'firstName', 'email'};
                    List<String> requiredHipaaFields = new List<String>();

                    for (Object hipaaObj : hipaaList) {
                        Map<String, Object> hipaa = (Map<String, Object>)hipaaObj;
                        
                        requiredHipaaFields.addAll(aux);

                        if (hipaa.containsKey('relationship') && hipaa.get('relationship') != null) {
                            if ((String)hipaa.get('relationship') == 'Third Party') {
                                //requiredHipaaFields.add('memberId');
                                requiredHipaaFields.add('DAT_DOB');
                            }   
                            else if ((String)hipaa.get('relationship') == 'Parent' || (String)hipaa.get('relationship') == 'Legal Guardian') {
                                requiredHipaaFields.add('dob');
                                requiredHipaaFields.add('ssn');
                                //requiredHipaaFields.add('memberId');
                            }
                            else if ((String)hipaa.get('relationship') == 'Primary' || (String)hipaa.get('relationship') == 'Spouse' || (String)hipaa.get('relationship') == 'Child'){
                                requiredHipaaFields.add('memberExternalId');
                                requiredHipaaFields.add('dob');
                            }
                        } 

                        List<String> missingHipaaField = checkMissingFields(hipaa, requiredHipaaFields);
                        requiredHipaaFields.clear();

                        if (!missingHipaaField.isEmpty()) {
                            allErrors.add('Error in generalInformation:hipaa: ' + String.join(missingHipaaField, ', ') + ' is required');
                        }

                        if (hipaa.containsKey('address') && hipaa.get('address') != null) {
                            Map<String, Object> hipaaAddress = (Map<String, Object>)hipaa.get('address');
                            List<String> missingHipaaAddressField = checkMissingFields(hipaaAddress, requiredHipaaAddress);
                            if (!missingHipaaAddressField.isEmpty()) {
                                allErrors.add('Error in generalInformation:hipaa:address: ' + String.join(missingHipaaAddressField, ', ') + ' is required');
                            }
                        } else {
                            allErrors.add('Error in generalInformation:hipaa: address is required');
                        } 
                    }
                }

                // ---------------------------------------------------------
                // VALIDATE MEDICAL PROGRAM
                // ---------------------------------------------------------
                if (!generalInformation.containsKey('medicalProgram') || generalInformation.get('medicalProgram') == null) {
                    allErrors.add('Error in generalInformation: medicalProgram is required');
                } 
                else {
                    Map<String, Object> medicalProgramsMap = (Map<String, Object>)generalInformation.get('medicalProgram');

                    List<String> requiredMedProgFields = new List<String>{
                        'productId', 'basePrice', 'priceWithContributions', 'individualPrice','tierFactorValue', 'contributionType', 'contributionAmount', 'ARC_PayPeriod__c', 'employeeSplit', 'employerSplit'
                    };

                    for (String programName : medicalProgramsMap.keySet()) {
                        Object progDataObj = medicalProgramsMap.get(programName);

                        if (progDataObj instanceof Map<String, Object>) {
                            Map<String, Object> programDetails = (Map<String, Object>)progDataObj;
                            
                            List<String> missingMedField = checkMissingFields(programDetails, requiredMedProgFields);
                            
                            if (!missingMedField.isEmpty()) {
                                allErrors.add('Error in generalInformation:medicalProgram (' + programName + '): The following fields are required: ' + String.join(missingMedField, ', '));
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------------------
            // VALIDATE MEMBERS
            // ---------------------------------------------------------
            if (!inputData.containsKey('members') || inputData.get('members') == null) {
                allErrors.add('Error members is required');
            }
            else {
                List<Object> membersList = (List<Object>)inputData.get('members');
                if (membersList.isEmpty()) {
                    allErrors.add('Error members list cannot be empty');
                }
                else {
                    // List of required fields in members list
                    List<String> requiredMemberFields = new List<String>{
                        'role', 'person', 'memberExternalId'
                    };
                    List<String> requiredMemberInfoFields = new List<String>{
                        'isLegacy', 'firstName', 'lastName', 'dob', 'gender', 'ssn', 'heightFeet', 'heightInches', 'weightLbs', 'email', 'phone', 'smoker', 'pregnant'
                    };
                    
                    List<String> currentCoverageFields = new List<String>{
                        'carrier', 'policyNumber', 'carrierPhone', 'effectiveDate', 'expirationDate', 'coverageSource', 'coverageType', 'status'
                    };
                    List<String> requiredMemberAddress = new List<String>{
                        'street', 'city', 'state', 'zip'
                    };

                    for (Object memberObj : membersList) {
                        Map<String, Object> member = (Map<String, Object>)memberObj;

                        List<String> missingRoleField = checkMissingFields(member, requiredMemberFields);
                        if (!missingRoleField.isEmpty()) {
                            allErrors.add('Error in members: ' + String.join(missingRoleField, ', ') + ' is required');
                        }

                        Map<String, Object> memberInfo = (Map<String, Object>)member.get('person');
                        List<String> missingMemInfoField = checkMissingFields(memberInfo, requiredMemberInfoFields);
                        if (!missingMemInfoField.isEmpty()) {
                            allErrors.add('Error in members:person: ' + String.join(missingMemInfoField, ', ') + ' is required');
                        }

                        if (memberInfo.containsKey('sameAddressAsPrimary') && memberInfo.get('sameAddressAsPrimary') != null && convertToBoolean(memberInfo.get('sameAddressAsPrimary')) == false) {
                            if (memberInfo.containsKey('address') && memberInfo.get('address') != null) {
                                Map<String, Object> memberAddress = (Map<String, Object>)memberInfo.get('address');
                                List<String> missingAddressField = checkMissingFields(memberAddress, requiredMemberAddress);
                                if (!missingAddressField.isEmpty()) {
                                    allErrors.add('Error in members:person:address: ' + String.join(missingAddressField, ', ') + ' is required');
                                }
                            } else {
                                allErrors.add('Error in members:person: address is required');
                            }  
                        }

                        if(!member.containsKey('currentCoverage')) {
                            allErrors.add('Error members must content list currentCoverage');
                        }

                        if (member.containsKey('currentCoverage') && member.get('currentCoverage') != null) {
                            List<Object> memberCoverageList = (List<Object>)member.get('currentCoverage');

                            for (Object memberCoverageObj : memberCoverageList) {
                                Map<String, Object> memberCoverage = (Map<String, Object>)memberCoverageObj;
                                
                                List<String> missingCoverageField = checkMissingFields(memberCoverage, currentCoverageFields);
                                if (!missingCoverageField.isEmpty()) {
                                    allErrors.add('Error in members:currentCoverage: ' + String.join(missingCoverageField, ', ') + ' is required');
                                }
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------------------
            // FINAL CHECK
            // ---------------------------------------------------------
            if (!allErrors.isEmpty()) {
                String finalErrorMessage = String.join(allErrors, '; ');
                return setError(response, outputMap, finalErrorMessage);
            }

            // ---------------------------------------------------------
            // SUCCESS
            // ---------------------------------------------------------
            response.put('success', true);
            response.put('message', 'Validation passed');
            
            if (outputMap != null) {
                outputMap.put('success', true);
                outputMap.put('validationPassed', true);
            }

        } catch (Exception e) {
            System.debug('Error in validateEnrollmentData: ' + e.getMessage() + '\n' + e.getStackTraceString());
            return setError(response, outputMap, 'System Error: ' + e.getMessage());
        }
        
        return response;
    }

    //Helper: Checks a list of fields against a map and returns the name of the first one that's missing
    private static List<String> checkMissingFields(Map<String, Object> dataMap, List<String> fieldsToCheck) {
        List<String> missingFields = new List<String>();

        for (String field : fieldsToCheck) {
            Boolean isMissing = false;

            // 1. Chequeo de nulo o inexistente
            if (!dataMap.containsKey(field) || dataMap.get(field) == null) {
                isMissing = true;
            } 
        
            if (isMissing) {
                missingFields.add(field);
            }
        }
        return missingFields;
    }

    // Helper: Centralize the creation of error response
    private static Map<String, Object> setError(Map<String, Object> response, Map<String, Object> outputMap, String message) {
        response.put('success', false);
        response.put('errorMessage', message);
        
        if (outputMap != null) {
            outputMap.put('success', false);
            outputMap.put('errorMessage', message);
        }
        return response;
    }

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
     * @Description: Creates integration log record
     * @param operation: The operation being logged
     * @param requestBody: The request body data
     * @return String: The ID of the created log record
     */
    public static String createIntegrationLog(String operation, Map<String,Object> requestBody) {
        try {
            DateTime startTime = DateTime.now();
            
            String primaryName = '';
            Object membersObj = requestBody.get('members');
            List<Object> members = (List<Object>)membersObj;
        
            for (Object memberObj : members) {
              
                Map<String, Object> member = (Map<String, Object>)memberObj;                                
                if (member.containsKey('role')) {
                    String role = (String)member.get('role');
                    if (role == 'Primary') {
                        Map<String,Object> person = (Map<String,Object>)member.get('person');
                        primaryName = person.get('firstName') + ' ' + person.get('lastName');
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
                Endpoint__c = '/api/v1/small-group-enrollment/' + operation,
                ErrorCode__c = null,
                ErrorMessage__c = null,
                FinishedAt__c = null,
                HttpStatus__c = 200,
                Operation__c = 'POST',
                RawJSON_Part1__c = jsonPart1,
                RawJSON_Part2__c = jsonPart2,
                RetryCount__c = 0,
                Service__c = 'processSGSelfEnrollment',
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
    private static void logError(String errorContext, Exception e, String requestData) {
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
}