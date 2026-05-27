global with sharing class ARC_SGQLEHelper {
    public static Map<String, Object> validateQLEData(Map<String, Object> inputData) {
        Map<String, Object> result = new Map<String, Object>{
            'success' => false,
            'errorMessage' => null
        };

        if (inputData == null) {
            result.put('errorMessage', 'Request body is required');
            return result;
        }

        Map<String, Object> generalInformation = (Map<String, Object>)inputData.get('generalInformation');
        if (generalInformation == null) {
            result.put('errorMessage', 'generalInformation is required');
            return result;
        }

        List<Object> members = (List<Object>)inputData.get('members');
        if (members == null || members.isEmpty()) {
            result.put('errorMessage', 'members is required');
            return result;
        }

        result.put('success', true);
        return result;
    }

    public static String createIntegrationLog(String operation, Map<String,Object> requestBody) {
        try {
            DateTime startTime = DateTime.now();

            String primaryName = '';
            List<Object> members = requestBody != null ? (List<Object>)requestBody.get('members') : null;
            if (members != null) {
                for (Object memberObj : members) {
                    Map<String, Object> member = (Map<String, Object>)memberObj;
                    if (member != null && String.valueOf(member.get('role')) == 'Primary') {
                        Map<String,Object> person = (Map<String,Object>)member.get('person');
                        if (person != null) {
                            primaryName = String.valueOf(person.get('firstName')) + ' ' + String.valueOf(person.get('lastName'));
                        }
                        break;
                    }
                }
            }

            String jsonString = requestBody != null ? JSON.serialize(requestBody) : '';
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
                Endpoint__c = '/api/v1/small-group-qle/' + operation,
                ErrorCode__c = null,
                ErrorMessage__c = null,
                FinishedAt__c = null,
                HttpStatus__c = 200,
                Operation__c = 'POST',
                RawJSON_Part1__c = jsonPart1,
                RawJSON_Part2__c = jsonPart2,
                RetryCount__c = 0,
                Service__c = 'processSmallGroupQLE',
                StartedAt__c = startTime,
                Success__c = true,
                ARC_PrimaryName__c = primaryName
            );

            insert logRecord;
            return logRecord.Id;
        } catch (Exception e) {
            System.debug('Error creating integration log: ' + e.getMessage() + ' ' + e.getStackTraceString());
            return null;
        }
    }

    public static void updateIntegrationLog(String logId, Boolean success, Integer httpStatus, String errorCode, String errorMessage, DateTime finishedAt, Long durationMs, Id groupAccountId, String groupAccountName) {
        try {
            if (String.isBlank(logId)) {
                return;
            }
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
        } catch (Exception e) {
            System.debug('Error updating integration log: ' + e.getMessage());
        }
    }

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

    public static void recalculatePolicyReasons(Set<Id> policyIds) {
        Map<Id, InsurancePolicy> policiesToUpdate = new Map<Id, InsurancePolicy>();
        
        for (InsurancePolicy policy : [
            SELECT Id 
            FROM InsurancePolicy 
            WHERE Id IN :policyIds 
            AND ARC_QLEReason__c != null
        ]) {
            
            policiesToUpdate.put(policy.Id, new InsurancePolicy(
                Id = policy.Id, 
                ARC_Reason__c = null
            ));
        }

        if (policiesToUpdate.isEmpty()) return;

        List<InsurancePolicyCoverage> allIpcs = [
            SELECT InsurancePolicyId, ARC_Reason__c
            FROM InsurancePolicyCoverage
            WHERE InsurancePolicyId IN :policiesToUpdate.keySet()
            AND ARC_Reason__c != null
        ];

        Map<Id, Set<String>> policyReasonsMap = new Map<Id, Set<String>>();

        for (InsurancePolicyCoverage ipc : allIpcs) {
            if (!policyReasonsMap.containsKey(ipc.InsurancePolicyId)) {
                policyReasonsMap.put(ipc.InsurancePolicyId, new Set<String>());
            }

            List<String> reasons = ipc.ARC_Reason__c.split(';');
            for (String reason : reasons) {
                if (String.isNotBlank(reason)) {
                    policyReasonsMap.get(ipc.InsurancePolicyId).add(reason.trim());
                }
            }
        }

        for (Id pId : policyReasonsMap.keySet()) {
            Set<String> uniqueReasons = policyReasonsMap.get(pId);
            if (!uniqueReasons.isEmpty()) {
                String joinedValues = String.join(new List<String>(uniqueReasons), ';');
                policiesToUpdate.get(pId).ARC_Reason__c = joinedValues;
            }
        }

        if (!policiesToUpdate.isEmpty()) {
            Database.SaveResult[] srList = Database.update(policiesToUpdate.values(), false);

            for (Integer i = 0; i < srList.size(); i++) {
                Database.SaveResult sr = srList[i];
                if (!sr.isSuccess()) {
                    Id failedRecordId = policiesToUpdate.values()[i].Id;
                    
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error updating InsurancePolicy (' + failedRecordId + '):');
                        System.debug('Error code: ' + err.getStatusCode());
                        System.debug('Message: ' + err.getMessage());
                        System.debug('Affected Fields: ' + err.getFields());
                    }
                }
            }
        }
    }

    /**
     * Validates the QLE payload structure and required fields.
     * Returns a success flag and a list of validation errors.
     */
    public static Map<String, Object> validateQLEPayload(Map<String, Object> inputData) {
        Map<String, Object> response = new Map<String, Object>();
        List<String> errors = new List<String>();

        if (inputData == null) {
            errors.add('Payload is required.');
            response.put('success', false);
            response.put('errors', errors);
            return response;
        }

        validateRequiredString(inputData, 'enrollmentId', 'enrollmentId', errors);
        validateRequiredString(inputData, 'traceId', 'traceId', errors);

        Map<String, Object> generalInformation = validateRequiredMap(inputData, 'generalInformation', 'generalInformation', errors);
        Map<String, Object> currentState = validateRequiredMap(inputData, 'currentState', 'currentState', errors);
        List<Object> members = validateRequiredList(inputData, 'members', 'members', errors);

        if (generalInformation != null) {
            validateRequiredString(generalInformation, 'accountId', 'generalInformation.accountId', errors);
            validateRequiredString(generalInformation, 'censusId', 'generalInformation.censusId', errors);
            validateRequiredString(generalInformation, 'groupAccountId', 'generalInformation.groupAccountId', errors);
            validateRequiredString(generalInformation, 'contractId', 'generalInformation.contractId', errors);
            validateRequiredString(generalInformation, 'primaryCensusMemberId', 'generalInformation.primaryCensusMemberId', errors);
            validateRequiredString(generalInformation, 'effectiveDate', 'generalInformation.effectiveDate', errors);
            validateRequiredMap(generalInformation, 'medicalProgram', 'generalInformation.medicalProgram', errors);
        }

        if (currentState != null) {
            Map<String, Object> currentPolicy = validateRequiredMap(currentState, 'currentPolicy', 'currentState.currentPolicy', errors);
            if (currentPolicy != null) {
                validateRequiredString(currentPolicy, 'policyId', 'currentState.currentPolicy.policyId', errors);
                validateRequiredString(currentPolicy, 'status', 'currentState.currentPolicy.status', errors);
                validateRequiredString(currentPolicy, 'effectiveDate', 'currentState.currentPolicy.effectiveDate', errors);
            }
        }

        if (members != null) {
            if (members.isEmpty()) {
                errors.add('members cannot be empty.');
            } else {
                for (Integer i = 0; i < members.size(); i++) {
                    String memberPath = 'members[' + i + ']';

                    if (!(members[i] instanceof Map<String, Object>)) {
                        errors.add(memberPath + ' must be an object.');
                        continue;
                    }

                    Map<String, Object> member = (Map<String, Object>)members[i];
                    validateRequiredString(member, 'memberExternalId', memberPath + '.memberExternalId', errors);
                    validateRequiredString(member, 'role', memberPath + '.role', errors);

                    Map<String, Object> person = validateRequiredMap(member, 'person', memberPath + '.person', errors);
                    if (person != null) {
                        validateRequiredString(person, 'firstName', memberPath + '.person.firstName', errors);
                        validateRequiredString(person, 'lastName', memberPath + '.person.lastName', errors);
                        validateRequiredString(person, 'dob', memberPath + '.person.dob', errors);
                    }
                }
            }
        }

        response.put('success', errors.isEmpty());
        response.put('errors', errors);
        return response;
    }

    /**
     * Validates that a field exists, is a string, and is not null, blank, or the literal string "null".
     */
    private static void validateRequiredString(
        Map<String, Object> source,
        String key,
        String fieldPath,
        List<String> errors
    ) {
        if (source == null || !source.containsKey(key)) {
            errors.add(fieldPath + ' is required.');
            return;
        }

        Object value = source.get(key);
        if (!(value instanceof String)) {
            errors.add(fieldPath + ' must be a string.');
            return;
        }

        String strValue = ((String)value);
        if (String.isBlank(strValue) || strValue.trim().toLowerCase() == 'null') {
            errors.add(fieldPath + ' cannot be null, blank, or the literal "null".');
        }
    }

    /**
     * Validates that a field exists and is a map.
     */
    private static Map<String, Object> validateRequiredMap(
        Map<String, Object> source,
        String key,
        String fieldPath,
        List<String> errors
    ) {
        if (source == null || !source.containsKey(key)) {
            errors.add(fieldPath + ' is required.');
            return null;
        }

        Object value = source.get(key);
        if (!(value instanceof Map<String, Object>)) {
            errors.add(fieldPath + ' must be an object.');
            return null;
        }

        return (Map<String, Object>)value;
    }

    /**
     * Validates that a field exists and is a list.
     */
    private static List<Object> validateRequiredList(
        Map<String, Object> source,
        String key,
        String fieldPath,
        List<String> errors
    ) {
        if (source == null || !source.containsKey(key)) {
            errors.add(fieldPath + ' is required.');
            return null;
        }

        Object value = source.get(key);
        if (!(value instanceof List<Object>)) {
            errors.add(fieldPath + ' must be an array.');
            return null;
        }

        return (List<Object>)value;
    }

    /**
     * Builds a readable validation error message to store on the Case.
     */
    public static String buildValidationErrorMessage(List<String> errors) {
        if (errors == null || errors.isEmpty()) {
            return null;
        }

        return 'Validation failed:\n- ' + String.join(errors, '\n- ');
    }
}