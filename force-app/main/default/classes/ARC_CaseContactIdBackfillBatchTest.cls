@isTest
private class ARC_CaseContactIdBackfillBatchTest {
    
    @TestSetup
    static void makeData(){
        List<Contract> contract = ARC_TestUtility.createCompleteEnrollments(1);
        List<Account> account = [SELECT Id FROM Account WHERE ARC_GroupAccount__c = :contract[0].AccountId AND ARC_IsPrimaryMember__c = true];
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 2; i++) {
            Case newCase = new Case (
                Subject = 'test '+i,
                Description = 'test '+i,
                Case_Type__c = 'Program',
                ARC_Reason__c = 'Replacement Materials',
                Origin = 'Email',
                ARC_Type__c = 'Member'
            );
            cases.add(newCase);
        }
        cases[0].ARC_PersonAccount__c = account[0].Id;
        insert cases;
        cases[0].ContactId = null;
        cases[1].AccountId = contract[0].AccountId;
        cases[1].ContactId = null;
        upsert cases;
    }

    @isTest
    static void ARC_CaseContactIdBackfillBatchTest() {
        Test.startTest();
        ARC_CaseContactIdBackfillBatch batch = new ARC_CaseContactIdBackfillBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        List<Case> updatedCases = [SELECT Id, ContactId FROM Case];
        for (Case c : updatedCases) {
            Assert.areNotEqual(c.ContactId, null, 'ContactId was not populated in the case.');
        }
    }
}