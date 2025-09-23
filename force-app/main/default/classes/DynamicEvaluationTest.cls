@isTest
public class DynamicEvaluationTest {
	
    @isTest static void testDynamicEvaluation() {
        
        // Setup: Create a test Claim
        Claim claim = new Claim(ARC_ClaimTotalAmount__c = 9999, RecordTypeId='0125f000000iK9YAAU', Name='SMB Test - WS');
        insert claim;
        
        DynamicEvaluation.EvaluationRequest req = new DynamicEvaluation.EvaluationRequest();
        req.recordIds = new List<Id>{claim.Id};
        req.expression = 'ARC_ClaimTotalAmount__c < 10000 OR ARC_ClaimTotalAmount__c > 20000';
        
        List<DynamicEvaluation.EvaluationResult> results = DynamicEvaluation.evaluateExpression(new List<DynamicEvaluation.EvaluationRequest> { req });
        
        // Assertions
        System.assertEquals(1, results.size(), 'Expected 1 result');
        System.assertEquals(1, results[0].matchingRecordIds.size(), 'Expected 1 matching record');
        System.assertEquals(claim.Id, results[0].matchingRecordIds[0], 'Expected matching record ID');
    }
}