@isTest
public class ARC_CaseBatchUpdateTest {

    @isTest
    static void testBatchProcess() {
        
        List<Case> cases = ARC_TestUtility.createTestCase(5, 'Sales');        
        //insert cases;

        Test.startTest();
        ARC_CaseBatchUpdate batch = new ARC_CaseBatchUpdate();
        Database.executeBatch(batch, 200);  
        Test.stopTest();

        
        List<Case> updatedCases = [SELECT Id, ARC_Upload_files_URL__c FROM Case WHERE Id IN :cases ];//
        
        for (Case c : updatedCases) {
            System.assertNotEquals(null, c.ARC_Upload_files_URL__c, 'The ARC_Upload_files_URL__c should be populated');
            System.debug('Updated Case URL: ' + c.ARC_Upload_files_URL__c);
        }
    }
}