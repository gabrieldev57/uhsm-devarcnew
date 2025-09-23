@isTest 
public with sharing class ARC_LWCDataHandlerTasksListViewTest {
 
    @isTest 
    static void ARC_LWCDataHandlerTasksListViewTest() {
        List<Case> cases = ARC_TestUtility.createTestCase(1, 'Admission');
        test.startTest();
        ARC_LWCDataHandlerTasksListView.getTasks(cases[0].Id);
        test.stopTest();
    }
}