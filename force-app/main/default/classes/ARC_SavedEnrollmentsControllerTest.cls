@IsTest
public class ARC_SavedEnrollmentsControllerTest {
    @IsTest
    static void testGetSavedEnrollments() {
        // Create test data
        List<Contract> testContracts = ARC_TestUtility.createContracts(1);
        insert testContracts;

        vlocity_ins__OmniScriptInstance__c testOmniScriptInstance = new vlocity_ins__OmniScriptInstance__c(
            vlocity_ins__ObjectId__c = testContracts[0].Id
        );
        insert testOmniScriptInstance;

        // Call the method to be tested
        List<Map<String, Object>> result = ARC_SavedEnrollmentsController.getSavedEnrollments();

    }
}