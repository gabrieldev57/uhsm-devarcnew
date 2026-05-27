global with sharing class IntegrationProcedureInvocable {
    @InvocableMethod(label='Integration Procedure' description='Calls an Integration Procedure with flexible JSON input')
    global static List<IntegrationProcedureOutput> runIntegrationServiceInvocable(List<IntegrationProcedureInput> input) {
        System.debug(LoggingLevel.ERROR, 'Input: ' + JSON.serialize(input));
        
        IntegrationProcedureOutput result = new IntegrationProcedureOutput();
        
        try {
            // Parse the JSON input string into a Map
            Map<String, Object> inputMap = new Map<String, Object>();
            
            if (String.isNotBlank(input[0].inputJson)) {
                inputMap = (Map<String, Object>) JSON.deserializeUntyped(input[0].inputJson);
            }
            
            // Call the Integration Procedure
            Object ipResult = vlocity_ins.IntegrationProcedureService.runIntegrationService(
                input[0].procedureAPIName,
                inputMap,
                new Map<String, Object>()
            );
            
            result.output = JSON.serialize(ipResult);
            result.success = true;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage() + ' | ' + e.getStackTraceString();
            System.debug(LoggingLevel.ERROR, 'Error calling IP: ' + result.errorMessage);
        }
        
        System.debug(LoggingLevel.ERROR, 'Output: ' + JSON.serialize(result));
        return new List<IntegrationProcedureOutput>{ result };
    }
    
    global class IntegrationProcedureInput {
        @InvocableVariable(label='Procedure API Name' required=true)
        global String procedureAPIName;
        
        @InvocableVariable(label='Input (JSON)' description='JSON string with input parameters, e.g. {"Id":"001...", "Status":"Active"}' required=false)
        global String inputJson;
    }
    
    global class IntegrationProcedureOutput {
        @InvocableVariable(label='Output (JSON)')
        global String output;
        
        @InvocableVariable(label='Success')
        global Boolean success;
        
        @InvocableVariable(label='Error Message')
        global String errorMessage;
    }
}