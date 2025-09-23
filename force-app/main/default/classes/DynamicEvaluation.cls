public class DynamicEvaluation {

    public class EvaluationRequest {
        @InvocableVariable(required = true)
        public List<Id> recordIds;

        @InvocableVariable(required = true)
        public String expression;
    }

    public class EvaluationResult {
        @InvocableVariable
        public List<Id> matchingRecordIds;
    }

    @InvocableMethod(label='Evaluate Dynamic Expression' description='Evaluates a condition based on the given expression and returns matching record IDs.')
    public static List<EvaluationResult> evaluateExpression(List<EvaluationRequest> requests) {
        List<EvaluationResult> results = new List<EvaluationResult>();

        for (EvaluationRequest request : requests) {
            EvaluationResult result = new EvaluationResult();
            result.matchingRecordIds = new List<Id>();
            
            if(request.recordIds != null && !request.recordIds.isEmpty()) {
                String objectName = getObjectName(request.recordIds[0]);

                List<Id> currentRecordIds = request.recordIds;
                
                String query = 'SELECT Id FROM ' + objectName + 
                               ' WHERE Id IN :currentRecordIds AND (' + request.expression + ')';

                System.debug('Generated SOQL: ' + query);
                
                List<SObject> records = Database.query(query);
                for(SObject record : records) {
                    result.matchingRecordIds.add(record.Id);
                }
            }
            
            results.add(result);
        }

        return results;
    }

    private static String getObjectName(Id recordId) {
        return recordId.getSObjectType().getDescribe().getName();
    }
}