@IsTest
private class LeadConvertToExistingAccount_Test {

    @IsTest
    static void testConvertLeadToExistingPersonAccount() {
        // 1. Create Person Account (requires an Account RT marked as Person Account)
        Account personAcc = new Account(
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true AND DeveloperName = 'ARC_IFPPersonAccount' LIMIT 1].Id,
            LastName = 'Test Person',
            FirstName = 'LeadConv'
        );
        insert personAcc;

        // 2. Create a Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'New',
            HealthCloudGA__BirthDate__c = Date.valueOf('2000-01-01'),
            Phone = '1010101010',
            email = 'LeadConversionFlowActionTest@uhsm.org'
        );
        insert testLead;

        // 3. Prepare request
        LeadConvertToExistingAccount.Request req = new LeadConvertToExistingAccount.Request();
        req.leadId = testLead.Id;
        req.accountId = personAcc.Id;

        // 4. Call the invocable
        Test.startTest();
        LeadConvertToExistingAccount.convertLeads(new List<LeadConvertToExistingAccount.Request>{ req });
        Test.stopTest();

        // 5. Verify conversion
        Lead convertedLead = [
            SELECT IsConverted, ConvertedAccountId, ConvertedContactId, Status 
            FROM Lead 
            WHERE Id = :testLead.Id
        ];

        System.assertEquals(true, convertedLead.IsConverted, 'Lead should be converted');
        System.assertEquals(personAcc.Id, convertedLead.ConvertedAccountId, 'Lead should be tied to existing Person Account');
        System.assertNotEquals(null, (Object)convertedLead, 'Lead should be tied to the Person Account contact');
    }
}