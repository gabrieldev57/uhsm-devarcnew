public with sharing class ARC_SG_MemberRatingController {
    
    @AuraEnabled
    public static String sendMemberData(String jsonInput) {
        try {
            Map<String, Object> inputMap = (Map<String, Object>) JSON.deserializeUntyped(jsonInput);

            // Invoke the Integration Procedure
            Map<String, Object> result = (Map<String, Object>) vlocity_ins.IntegrationProcedureService.runIntegrationProcedureServiceFromApex(
                'smallGroup_Rating',
                inputMap,
                new Map<String, Object>()
            );

            // Return result as JSON string
            return JSON.serialize(result);
        } catch (Exception ex) {
            throw new AuraHandledException('Error calling IP: ' + ex.getMessage());
        }
    }
}