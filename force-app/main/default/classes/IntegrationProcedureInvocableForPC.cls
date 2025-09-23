global with sharing class IntegrationProcedureInvocableForPC {
 @InvocableMethod(label = 'HealthyDiscount(PC)')
 global static List < IntegrationProcedureOutput > runIntegrationServiceInvocable(List < IntegrationProcedureInput > input) {
  System.debug(LoggingLevel.Error, JSON.serialize(input));
  IntegrationProcedureOutput result = new IntegrationProcedureOutput();
  result.output = JSON.serialize(
   vlocity_ins.IntegrationProcedureService.runIntegrationService(
    input[0].procedureAPIName,
    new Map < String, Object >
    {
     'ContextId' => input[0].input
    },
    new Map < String, Object > ()));
  System.debug(LoggingLevel.Error, JSON.serialize(result));
  return new List < IntegrationProcedureOutput >
   {
    result
   };
 }
 global class IntegrationProcedureInput
 {
  @InvocableVariable(label = 'Procedure Name') global String procedureAPIName;
  @InvocableVariable(label = 'Input') global String input;
 }
 global class IntegrationProcedureOutput
 {
  @InvocableVariable(label = 'Output') global String output;
 }
}