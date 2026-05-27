public with sharing class ARC_ProcessIntegrationLog {
    // File: IntegrationLogActionService.cls
    public class Result {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Integer httpStatus;
        @AuraEnabled public String errorCode;
        @AuraEnabled public String errorMessage;
    } 

    /** 
     * Simple synchronous action:
     * - Reads RawJSON_Part1__c + RawJSON_Part2__c
     * - Calls your processor: IntegrationLogProcessor.process(rawJson, logRec)
     * - Writes back Success/HttpStatus/ErrorCode/ErrorMessage
     */
    @AuraEnabled
    public static Result process(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('recordId is required.');
        }

        ARC_IntegrationLog__c logRec = [
            SELECT Id, Name,
                   RawJSON_Part1__c, RawJSON_Part2__c,
                   Success__c, HttpStatus__c, ErrorCode__c, ErrorMessage__c, Service__c,
                   StartedAt__c, FinishedAt__c, DurationMs__c
            FROM ARC_IntegrationLog__c 
            WHERE Id = :recordId
            LIMIT 1
        ];

        String rawJson =
            (logRec.RawJSON_Part1__c == null ? '' : logRec.RawJSON_Part1__c) +
            (logRec.RawJSON_Part2__c == null ? '' : logRec.RawJSON_Part2__c);

        Result out = new Result();
        
        // Capture start time
        DateTime startTime = DateTime.now();
        Long startTimeMs = startTime.getTime();

        try {
            System.debug('rawJson: ' + rawJson);
            
            // Parse the raw JSON to extract enrollment data
            Map<String, Object> inputData = new Map<String, Object>();
            if (String.isNotBlank(rawJson)) {
                try {
                    inputData = (Map<String, Object>) JSON.deserializeUntyped(rawJson);
                } catch (JSONException jsonEx) {
                    throw new AuraHandledException('Invalid JSON format: ' + jsonEx.getMessage());
                }
            }

            String serviceToUse = logRec.Service__c;
            if (String.isBlank(serviceToUse)) {
                serviceToUse = 'processSelfEnrollment';
            }
            // Call ARC_SEBaseService using invokeMethod pattern
            Map<String, Object> outputMap = new Map<String, Object>();

            // Call the appropriate service method based on the serviceToUse
            if (serviceToUse == 'processSmallGroupSelfEnrollment') {
                ARC_SGSEBaseService service = new ARC_SGSEBaseService();
                service.invokeMethod(serviceToUse, inputData, outputMap, new Map<String, Object>());
            } else {
                ARC_SEBaseService service = new ARC_SEBaseService();
                service.invokeMethod(serviceToUse, inputData, outputMap, new Map<String, Object>());
            }
            
            // Create service response based on outputMap
            Map<String, Object> serviceResponse = new Map<String, Object>();
            serviceResponse.put('success', outputMap.get('success'));
            serviceResponse.put('message', outputMap.get('success') == true ? (String) outputMap.get('message') : (String) outputMap.get('errorMessage'));
            serviceResponse.put('errorMessage', outputMap.get('errorMessage'));
            
            // Update the log record with the service response
            Boolean serviceSuccess = (Boolean) serviceResponse.get('success');
            logRec.Success__c = serviceSuccess;
            
            if (serviceSuccess) {
                logRec.HttpStatus__c = 200;
                logRec.ErrorCode__c = null;
                logRec.ErrorMessage__c = (String) serviceResponse.get('message');
                out.success = true;
                out.httpStatus = 200;
                out.errorCode = null;
                out.errorMessage = (String) serviceResponse.get('message');
            } else {
                logRec.HttpStatus__c = 400;
                logRec.ErrorCode__c = 'SERVICE_ERROR';
                logRec.ErrorMessage__c = (String) serviceResponse.get('errorMessage');
                out.success = false;
                out.httpStatus = 400;
                out.errorCode = 'SERVICE_ERROR';
                out.errorMessage = (String) serviceResponse.get('errorMessage');
            }
            
            // Capture finish time and calculate processing duration
            DateTime finishTime = DateTime.now();
            Long finishTimeMs = finishTime.getTime();
            Long processingTimeMs = finishTimeMs - startTimeMs;
            
            // Update timing fields
            logRec.StartedAt__c = startTime;
            logRec.FinishedAt__c = finishTime;
            logRec.DurationMs__c = processingTimeMs;
            
            update logRec;

        } catch (Exception e) {
            // Best-effort error writeback
            try {
                // Capture finish time and calculate processing duration even for exceptions
                DateTime finishTime = DateTime.now();
                Long finishTimeMs = finishTime.getTime();
                Long processingTimeMs = finishTimeMs - startTimeMs;
                
                logRec.Success__c      = false;
                logRec.ErrorCode__c    = 'EXCEPTION';
                logRec.ErrorMessage__c = e.getMessage();
                logRec.StartedAt__c = startTime;
                logRec.FinishedAt__c = finishTime;
                logRec.DurationMs__c = processingTimeMs;
                update logRec;
            } catch (Exception ignore) {}

            out.success      = false;
            out.errorCode    = 'EXCEPTION';
            out.errorMessage = e.getMessage();
        }

        return out;
    }
}