@isTest
private class ARC_GetMemberInteractionsPATest {
    @isTest
    static void testGetInteractions() {
        // Create test account and contact
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        vlocity_ins__GroupCensus__c testCensus = new vlocity_ins__GroupCensus__c(
            vlocity_ins__GroupId__c = testAccount.Id,
            Name = 'Test Census'
        );
        insert testCensus;
        Contact testContact = new Contact(AccountId = testAccount.Id, LastName = 'Test Contact');
        insert testContact;
        vlocity_ins__GroupCensusMember__c testMember = new vlocity_ins__GroupCensusMember__c(
            Name = 'Test Member',
            vlocity_ins__ContactId__c = testContact.Id,
            vlocity_ins__CensusId__c = testCensus.Id
        );
        insert testMember;
        // Create test interactions
        ARC_MemberInteraction__c interaction1 = new ARC_MemberInteraction__c(
            Name = 'Interaction 1',
            Date__c = Date.today(),
            Status__c = 'Open',
            Type__c = 'Phone Call',
            E123_User__c = 'Test User',
            Description__c = 'Test Description',
            Notes__c = 'Test Notes',
            MemberId__c = testMember.Id
        );
        ARC_MemberInteraction__c interaction2 = new ARC_MemberInteraction__c(
            Name = 'Interaction 2',
            Date__c = Date.today(),
            Status__c = 'Closed',
            Type__c = 'Email',
            E123_User__c = 'Test User 2',
            Description__c = 'Test Description 2',
            Notes__c = 'Test Notes 2',
            MemberId__c = testMember.Id
        );
        insert new List<ARC_MemberInteraction__c>{interaction1, interaction2};
        
        // Call the method being tested
        List<Map<String, Object>> result = ARC_GetMemberInteractionsPA.getInteractions(testAccount.Id);
        
        // Verify the results
        System.assertEquals(2, result.size());
        System.assertEquals(interaction1.Id, result[0].get('id'));
        System.assertEquals('/' + interaction1.Id, result[0].get('idURL'));
        System.assertEquals(interaction1.Name, result[0].get('Name'));
        System.assertEquals(interaction1.Date__c, result[0].get('Date'));
        System.assertEquals(interaction1.Status__c, result[0].get('Status'));
        System.assertEquals(interaction1.Type__c, result[0].get('Type'));
        System.assertEquals(interaction1.E123_User__c, result[0].get('E123 User'));
        System.assertEquals(interaction1.Description__c, result[0].get('Description'));
        System.assertEquals(interaction1.Notes__c, result[0].get('Notes'));
        
        System.assertEquals(interaction2.Id, result[1].get('id'));
        System.assertEquals('/' + interaction2.Id, result[1].get('idURL'));
        System.assertEquals(interaction2.Name, result[1].get('Name'));
        System.assertEquals(interaction2.Date__c, result[1].get('Date'));
        System.assertEquals(interaction2.Status__c, result[1].get('Status'));
        System.assertEquals(interaction2.Type__c, result[1].get('Type'));
        System.assertEquals(interaction2.E123_User__c, result[1].get('E123 User'));
        System.assertEquals(interaction2.Description__c, result[1].get('Description'));
        System.assertEquals(interaction2.Notes__c, result[1].get('Notes'));
    }
}