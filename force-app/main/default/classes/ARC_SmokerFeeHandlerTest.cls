@isTest
private class ARC_SmokerFeeHandlerTest {

    @TestSetup
    static void makeData(){
        List<Contract> contract = ARC_TestUtility.createCompleteEnrollments(1);

        // Create Calculation Procedure
        vlocity_ins__CalculationProcedure__c calcProc = new vlocity_ins__CalculationProcedure__c(
            Name = ARC_GroupCensusMemberPlanTriggerHandler.CALCULATION_PROCEDURE_NAME
        );
        insert calcProc;
        
        // Create Calculation Procedure Version with test constants
        vlocity_ins__CalculationProcedureVersion__c calcProcVer = new vlocity_ins__CalculationProcedureVersion__c(
            vlocity_ins__CalculationProcedureId__c = calcProc.Id,
            vlocity_ins__IsEnabled__c = true,
            vlocity_ins__Constants__c = '[{"name":"SmokerAditional","value":"25"},{"name":"AmountPerExtraMember","value":"50"}]'
        );
        insert calcProcVer;
    }

    @isTest
    static void applySmokerFeeLogicTest() {
        // Recuperar el miembro creado por la utility
        vlocity_ins__GroupCensusMember__c member = [
            SELECT Id 
            FROM vlocity_ins__GroupCensusMember__c 
            WHERE Name LIKE '%Test Census Member Primary%'  
            LIMIT 1
        ];

        // Armar input para el handler (sin update)
        ARC_SmokerFeeHandler.SmokerInput input = new ARC_SmokerFeeHandler.SmokerInput();
        input.Id = member.Id;
        input.isSmoker = true; // probamos el caso smoker

        Test.startTest();
        ARC_SmokerFeeHandler.applySmokerFeeLogic(new List<ARC_SmokerFeeHandler.SmokerInput>{ input });
        Test.stopTest();
    }

}