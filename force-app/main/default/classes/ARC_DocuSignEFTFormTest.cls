@isTest
private class ARC_DocuSignEFTFormTest {
    @TestSetup
    static void makeData(){
        List<Contract> contract = ARC_TestUtility.createCompleteEnrollments(1);
        contract[0].Status = 'Awaiting Activation';
        update contract;
        List<Account> account = [SELECT Id FROM Account WHERE ARC_GroupAccount__c = :contract[0].AccountId];
        vlocity_ins__VlocityDocuSignTemplate__c testTemplate = new vlocity_ins__VlocityDocuSignTemplate__c(
            Name = 'WeShare healthcare by UHSM EFT Form',
            vlocity_ins__TemplateIdentifier__c = 'TestIdentifier'
        );
        insert testTemplate;
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 2; i++) {
            Case newCase = new Case (
                ARC_Contract__c = contract[0].Id,
                Subject = 'test '+i,
                Description = 'test '+i,
                Case_Type__c = 'Contribution',
                ARC_Reason__c = 'App/Change Fee Decline',
                Origin = 'Email',
                ARC_PersonAccount__c = account[0].Id,
                ARC_Type__c = 'Member'
            );
            cases.add(newCase);
        }
        cases[0].ARC_Reason__c = 'App/Change Fee Decline';
        cases[1].ARC_Reason__c = 'Recurring Decline';
        insert cases;
    }

    class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"envelopeId": "12345"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void ARC_DocuSignEFTFormTest() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        List<Case> cases = [SELECT Id FROM Case];
        List<Id> caseIds = new List<Id>();
        for (Case case_i : cases) {
            caseIds.add(case_i.Id);
        }
        Test.startTest();
        ARC_DocuSignEFTForm.flowActionSendEFTFormEnvelope(caseIds);
        Test.stopTest();
        List<Case> casesUpdated = [SELECT Id, ARC_LastDocuSignEnvelopeId__c FROM Case];
        for (Case case_i : casesUpdated) {
            System.Assert.areNotEqual(null, case_i.ARC_LastDocuSignEnvelopeId__c, 'Envelope Id was not set.');
        }
    }
}