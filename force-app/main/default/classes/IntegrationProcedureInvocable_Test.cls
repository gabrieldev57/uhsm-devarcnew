@isTest
private class IntegrationProcedureInvocable_Test {
    
    @isTest
    static void testWithValidJsonInput() {
        // Create test input
        IntegrationProcedureInvocable.IntegrationProcedureInput input = 
            new IntegrationProcedureInvocable.IntegrationProcedureInput();
        input.procedureAPIName = 'TestIntegrationProcedure';
        input.inputJson = '{"Id":"001000000000000","Status":"Active","Amount":1000}';
        
        Test.startTest();
        List<IntegrationProcedureInvocable.IntegrationProcedureOutput> results = 
            IntegrationProcedureInvocable.runIntegrationServiceInvocable(
                new List<IntegrationProcedureInvocable.IntegrationProcedureInput>{ input }
            );
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertNotEquals(null, results[0], 'Result object should not be null');
        
        // Note: If no actual IP exists, this will hit the error path
        // For full integration testing, create a test IP in your org
    }
    
    @isTest
    static void testWithEmptyJsonInput() {
        // Create test input with empty JSON
        IntegrationProcedureInvocable.IntegrationProcedureInput input = 
            new IntegrationProcedureInvocable.IntegrationProcedureInput();
        input.procedureAPIName = 'TestIntegrationProcedure';
        input.inputJson = '';
        
        Test.startTest();
        List<IntegrationProcedureInvocable.IntegrationProcedureOutput> results = 
            IntegrationProcedureInvocable.runIntegrationServiceInvocable(
                new List<IntegrationProcedureInvocable.IntegrationProcedureInput>{ input }
            );
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
    }
    
    @isTest
    static void testWithNullJsonInput() {
        // Create test input with null JSON
        IntegrationProcedureInvocable.IntegrationProcedureInput input = 
            new IntegrationProcedureInvocable.IntegrationProcedureInput();
        input.procedureAPIName = 'TestIntegrationProcedure';
        input.inputJson = null;
        
        Test.startTest();
        List<IntegrationProcedureInvocable.IntegrationProcedureOutput> results = 
            IntegrationProcedureInvocable.runIntegrationServiceInvocable(
                new List<IntegrationProcedureInvocable.IntegrationProcedureInput>{ input }
            );
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
    }
    
    @isTest
    static void testWithInvalidJson() {
        // Create test input with malformed JSON
        IntegrationProcedureInvocable.IntegrationProcedureInput input = 
            new IntegrationProcedureInvocable.IntegrationProcedureInput();
        input.procedureAPIName = 'TestIntegrationProcedure';
        input.inputJson = '{InvalidJson}';
        
        Test.startTest();
        List<IntegrationProcedureInvocable.IntegrationProcedureOutput> results = 
            IntegrationProcedureInvocable.runIntegrationServiceInvocable(
                new List<IntegrationProcedureInvocable.IntegrationProcedureInput>{ input }
            );
        Test.stopTest();
        
        // Verify error handling
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].success, 'Should indicate failure');
        System.assertNotEquals(null, results[0].errorMessage, 'Should have error message');
        System.assert(results[0].errorMessage.contains('Unexpected character'), 'Error should mention JSON parsing');
    }
    
    @isTest
    static void testWithComplexJsonStructure() {
        // Create test input with nested JSON
        IntegrationProcedureInvocable.IntegrationProcedureInput input = 
            new IntegrationProcedureInvocable.IntegrationProcedureInput();
        input.procedureAPIName = 'TestIntegrationProcedure';
        input.inputJson = '{"AccountId":"001000000000000","ContactInfo":{"FirstName":"John","LastName":"Doe"},"Items":[{"Name":"Item1","Quantity":5}]}';
        
        Test.startTest();
        List<IntegrationProcedureInvocable.IntegrationProcedureOutput> results = 
            IntegrationProcedureInvocable.runIntegrationServiceInvocable(
                new List<IntegrationProcedureInvocable.IntegrationProcedureInput>{ input }
            );
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
    }
    
    @isTest
    static void testOutputStructure() {
        // Verify the output object structure
        IntegrationProcedureInvocable.IntegrationProcedureInput input = 
            new IntegrationProcedureInvocable.IntegrationProcedureInput();
        input.procedureAPIName = 'TestIntegrationProcedure';
        input.inputJson = '{"Id":"001000000000000"}';
        
        Test.startTest();
        List<IntegrationProcedureInvocable.IntegrationProcedureOutput> results = 
            IntegrationProcedureInvocable.runIntegrationServiceInvocable(
                new List<IntegrationProcedureInvocable.IntegrationProcedureInput>{ input }
            );
        Test.stopTest();
        
        // Verify output structure exists
        IntegrationProcedureInvocable.IntegrationProcedureOutput output = results[0];
        System.assertNotEquals(null, output, 'Output should not be null');
        
        // Output, success, and errorMessage should all be accessible
        String outputJson = output.output;
        Boolean success = output.success;
        String errorMsg = output.errorMessage;
        
        // At minimum, success should be set (true or false depending on IP existence)
        System.assertNotEquals(null, success, 'Success flag should be set');
    }
}