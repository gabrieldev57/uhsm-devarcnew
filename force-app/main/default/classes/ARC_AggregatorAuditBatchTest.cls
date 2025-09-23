@isTest
private class ARC_AggregatorAuditBatchTest {

    @isTest
    static void testBatchExecution() {
        // Crear Account de prueba
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Crear Contract vinculado
        Contract con = new Contract(AccountId = acc.Id, StartDate = Date.today(), Status = 'Activated');
        insert con;

        // Crear Aggregators para simular histórico
        List<ARC_Aggregator__c> aggregators = new List<ARC_Aggregator__c>();

        // Caso con 4 valores (probando recorte a los últimos 3)
        aggregators.add(new ARC_Aggregator__c(Name = 'Agg1', ARC_Member__c = acc.Id));
        aggregators.add(new ARC_Aggregator__c(Name = 'Agg2', ARC_Member__c = acc.Id));
        aggregators.add(new ARC_Aggregator__c(Name = 'Agg3', ARC_Member__c = acc.Id));
        aggregators.add(new ARC_Aggregator__c(Name = 'Agg4', ARC_Member__c = acc.Id));

        // Caso con solo 2 valores
        aggregators.add(new ARC_Aggregator__c(Name = 'AggA', ARC_Member__c = acc.Id));
        aggregators.add(new ARC_Aggregator__c(Name = 'AggB', ARC_Member__c = acc.Id));

        insert aggregators;

        Test.startTest();
        // Ejecutar batch
        Database.executeBatch(new ARC_AggregatorAuditBatch(true), 200);
        Test.stopTest();

        // Recuperar los aggregators procesados para validar
        List<ARC_Aggregator__c> processed = [
            SELECT Id, Name
            FROM ARC_Aggregator__c
            WHERE Id IN :aggregators
        ];

        System.assertEquals(6, processed.size(), 'Se deben haber procesado los 6 aggregators creados');
    }
}