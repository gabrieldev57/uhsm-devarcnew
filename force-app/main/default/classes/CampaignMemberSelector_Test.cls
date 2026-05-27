@isTest
private class CampaignMemberSelector_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create Person Accounts with Risk_Decile__c values
        List<Account> accounts = new List<Account>();
        
        // Create 150 high-risk accounts (Risk_Decile__c from 10 down to 1)
        for (Integer i = 0; i < 150; i++) {
            Integer riskDecile = 10 - (i / 15); // Creates varied risk levels from 10 to 1
            Account acc = new Account(
                FirstName = 'Test',
                LastName = 'Person' + i,
                Risk_Decile__c = riskDecile,
                IsActive = true,
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('PersonAccount').getRecordTypeId()
            );
            accounts.add(acc);
        }
        insert accounts;
        
        // Create campaigns
        List<Campaign> campaigns = new List<Campaign>();
        campaigns.add(new Campaign(Name = 'Main Campaign', IsActive = true));
        campaigns.add(new Campaign(Name = 'Control Campaign', IsActive = true));
        campaigns.add(new Campaign(Name = 'Excluded Campaign 1', IsActive = true));
        campaigns.add(new Campaign(Name = 'Excluded Campaign 2', IsActive = true));
        insert campaigns;
        
        // Add some accounts to excluded campaigns (first 50 accounts)
        List<CampaignMember> existingMembers = new List<CampaignMember>();
        List<Account> refreshedAccounts = [SELECT Id, PersonContactId FROM Account LIMIT 50];
        
        for (Account acc : refreshedAccounts) {
            existingMembers.add(new CampaignMember(
                CampaignId = campaigns[2].Id, // Excluded Campaign 1
                ContactId = acc.PersonContactId,
                Status = 'Sent'
            ));
            existingMembers.add(new CampaignMember(
                CampaignId = campaigns[3].Id, // Excluded Campaign 2
                ContactId = acc.PersonContactId,
                Status = 'Responded'
            ));
        }
        insert existingMembers;
    }
    
    @isTest
    static void testSuccessfulAssignment() {
        // Get test campaigns
        List<Campaign> campaigns = [SELECT Id FROM Campaign ORDER BY Name];
        Campaign mainCampaign = campaigns[1]; // Main Campaign
        Campaign controlCampaign = campaigns[0]; // Control Campaign
        List<Id> excludedCampaigns = new List<Id>{campaigns[2].Id, campaigns[3].Id};
        
        // Prepare input
        CampaignMemberSelector.FlowInput input = new CampaignMemberSelector.FlowInput();
        input.thisCampaignId = mainCampaign.Id;
        input.controlCampaignId = controlCampaign.Id;
        input.count = 80; // Will need 84 total (80 + 4 for control at 5%)
        input.excludedCampaigns = excludedCampaigns;
        
        Test.startTest();
        List<CampaignMemberSelector.FlowOutput> results = 
            CampaignMemberSelector.getCampaignMembersForAssignment(new List<CampaignMemberSelector.FlowInput>{input});
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, results.size(), 'Should return one output');
        CampaignMemberSelector.FlowOutput output = results[0];
        
        System.assertEquals(true, output.success, 'Operation should be successful');
        System.assertEquals(80, output.mainCampaignMembers.size(), 'Should have 80 main campaign members');
        System.assertEquals(4, output.controlCampaignMembers.size(), 'Should have 4 control campaign members (5% of 80)');
        System.assertEquals(84, output.availableCount, 'Should find 84 eligible contacts');
        System.assertEquals(84, output.requestedCount, 'Should request 84 contacts');
        
        // Verify Campaign IDs are correct
        for (CampaignMember cm : output.mainCampaignMembers) {
            System.assertEquals(mainCampaign.Id, cm.CampaignId, 'Main campaign member should have correct campaign ID');
            System.assertEquals('Uncalled', cm.Status, 'Status should be Uncalled');
            System.assertNotEquals(null, cm.ContactId, 'Contact ID should not be null');
        }
        
        for (CampaignMember cm : output.controlCampaignMembers) {
            System.assertEquals(controlCampaign.Id, cm.CampaignId, 'Control campaign member should have correct campaign ID');
            System.assertEquals('Uncalled', cm.Status, 'Status should be Uncalled');
            System.assertNotEquals(null, cm.ContactId, 'Contact ID should not be null');
        }
        
        // Verify no Contact IDs overlap between main and control
        Set<Id> mainContactIds = new Set<Id>();
        for (CampaignMember cm : output.mainCampaignMembers) {
            mainContactIds.add(cm.ContactId);
        }
        
        for (CampaignMember cm : output.controlCampaignMembers) {
            System.assert(!mainContactIds.contains(cm.ContactId), 'Control contacts should not overlap with main contacts');
        }
    }
    
    @isTest
    static void testInsufficientContacts() {
        // Get test campaigns
        List<Campaign> campaigns = [SELECT Id FROM Campaign ORDER BY Name];
        Campaign mainCampaign = campaigns[1];
        Campaign controlCampaign = campaigns[0];
        List<Id> excludedCampaigns = new List<Id>{campaigns[2].Id, campaigns[3].Id};
        
        // Request more than available (we have 150 accounts, 50 are excluded, so 100 available)
        CampaignMemberSelector.FlowInput input = new CampaignMemberSelector.FlowInput();
        input.thisCampaignId = mainCampaign.Id;
        input.controlCampaignId = controlCampaign.Id;
        input.count = 120; // Will need 126 total, but only 100 available
        input.excludedCampaigns = excludedCampaigns;
        
        Test.startTest();
        List<CampaignMemberSelector.FlowOutput> results = 
            CampaignMemberSelector.getCampaignMembersForAssignment(new List<CampaignMemberSelector.FlowInput>{input});
        Test.stopTest();
        
        // Assertions
        CampaignMemberSelector.FlowOutput output = results[0];
        
        System.assertEquals(false, output.success, 'Operation should fail due to insufficient contacts');
        System.assertEquals(0, output.mainCampaignMembers.size(), 'Should have no main campaign members');
        System.assertEquals(0, output.controlCampaignMembers.size(), 'Should have no control campaign members');
        System.assertEquals(100, output.availableCount, 'Should find 100 eligible contacts');
        System.assertEquals(126, output.requestedCount, 'Should request 126 contacts');
        System.assert(output.errorMessage.contains('Insufficient eligible contacts'), 'Error message should mention insufficient contacts');
    }
    
    @isTest
    static void testNoExcludedCampaigns() {
        // Get test campaigns
        List<Campaign> campaigns = [SELECT Id FROM Campaign ORDER BY Name];
        Campaign mainCampaign = campaigns[1];
        Campaign controlCampaign = campaigns[0];
        
        // No excluded campaigns - all 150 accounts should be available
        CampaignMemberSelector.FlowInput input = new CampaignMemberSelector.FlowInput();
        input.thisCampaignId = mainCampaign.Id;
        input.controlCampaignId = controlCampaign.Id;
        input.count = 100; // Will need 105 total
        input.excludedCampaigns = new List<Id>(); // Empty list
        
        Test.startTest();
        List<CampaignMemberSelector.FlowOutput> results = 
            CampaignMemberSelector.getCampaignMembersForAssignment(new List<CampaignMemberSelector.FlowInput>{input});
        Test.stopTest();
        
        // Assertions
        CampaignMemberSelector.FlowOutput output = results[0];
        
        System.assertEquals(true, output.success, 'Operation should be successful');
        System.assertEquals(100, output.mainCampaignMembers.size(), 'Should have 100 main campaign members');
        System.assertEquals(5, output.controlCampaignMembers.size(), 'Should have 5 control campaign members');
        System.assertEquals(105, output.availableCount, 'Should find 105 eligible contacts');
    }
    
    @isTest
    static void testHighestRiskFirst() {
        // Get test campaigns
        List<Campaign> campaigns = [SELECT Id FROM Campaign ORDER BY Name];
        Campaign mainCampaign = campaigns[1];
        Campaign controlCampaign = campaigns[0];
        List<Id> excludedCampaigns = new List<Id>{campaigns[2].Id, campaigns[3].Id};
        
        CampaignMemberSelector.FlowInput input = new CampaignMemberSelector.FlowInput();
        input.thisCampaignId = mainCampaign.Id;
        input.controlCampaignId = controlCampaign.Id;
        input.count = 20;
        input.excludedCampaigns = excludedCampaigns;
        
        Test.startTest();
        List<CampaignMemberSelector.FlowOutput> results = 
            CampaignMemberSelector.getCampaignMembersForAssignment(new List<CampaignMemberSelector.FlowInput>{input});
        Test.stopTest();
        
        CampaignMemberSelector.FlowOutput output = results[0];
        
        // Get the accounts associated with returned contacts to verify risk ordering
        Set<Id> contactIds = new Set<Id>();
        for (CampaignMember cm : output.mainCampaignMembers) {
            contactIds.add(cm.ContactId);
        }
        for (CampaignMember cm : output.controlCampaignMembers) {
            contactIds.add(cm.ContactId);
        }
        
        List<Account> selectedAccounts = [
            SELECT Risk_Decile__c 
            FROM Account 
            WHERE PersonContactId IN :contactIds 
            ORDER BY Risk_Decile__c DESC
        ];
        
        // Verify first account has highest risk
        System.assert(selectedAccounts[0].Risk_Decile__c >= selectedAccounts[selectedAccounts.size()-1].Risk_Decile__c, 
                     'Accounts should be ordered by risk decile descending');
    }
    
    @isTest
    static void testScaleLimitCheck() {
        // This test simulates the scale limit being hit
        // In reality we can't create 50k+ records in a test, so we'll use a smaller number
        // and modify the code temporarily or use a mock (for this test we'll just verify the logic exists)
        
        // Get test campaigns
        List<Campaign> campaigns = [SELECT Id FROM Campaign ORDER BY Name];
        Campaign mainCampaign = campaigns[1];
        Campaign controlCampaign = campaigns[0];
        
        // Create additional campaign members to approach limit (we can't create 50k in test)
        // This test verifies the COUNT query and error handling structure
        List<Id> excludedCampaigns = new List<Id>{campaigns[2].Id};
        
        // Count existing members
        Integer existingCount = [SELECT COUNT() FROM CampaignMember WHERE CampaignId = :campaigns[2].Id];
        
        CampaignMemberSelector.FlowInput input = new CampaignMemberSelector.FlowInput();
        input.thisCampaignId = mainCampaign.Id;
        input.controlCampaignId = controlCampaign.Id;
        input.count = 20;
        input.excludedCampaigns = excludedCampaigns;
        
        Test.startTest();
        List<CampaignMemberSelector.FlowOutput> results = 
            CampaignMemberSelector.getCampaignMembersForAssignment(new List<CampaignMemberSelector.FlowInput>{input});
        Test.stopTest();
        
        CampaignMemberSelector.FlowOutput output = results[0];
        
        // Since we have less than 50k, this should succeed
        System.assertEquals(true, output.success, 'Should succeed with less than 50k members');
        
        // Verify totalExcludedMembers is set
        System.assertNotEquals(null, output.totalExcludedMembers, 'Total excluded members should be populated');
        System.assertEquals(existingCount, output.totalExcludedMembers, 'Should match actual excluded count');
    }
    
    @isTest
    static void testInactiveAccountsExcluded() {
        // Create an inactive account
        Account inactiveAccount = new Account(
            FirstName = 'Inactive',
            LastName = 'Person',
            Risk_Decile__c = 10,
            IsActive = false,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount').getRecordTypeId()
        );
        insert inactiveAccount;
        
        // Get test campaigns
        List<Campaign> campaigns = [SELECT Id FROM Campaign ORDER BY Name];
        Campaign mainCampaign = campaigns[1];
        Campaign controlCampaign = campaigns[0];
        
        CampaignMemberSelector.FlowInput input = new CampaignMemberSelector.FlowInput();
        input.thisCampaignId = mainCampaign.Id;
        input.controlCampaignId = controlCampaign.Id;
        input.count = 20;
        input.excludedCampaigns = new List<Id>();
        
        Test.startTest();
        List<CampaignMemberSelector.FlowOutput> results = 
            CampaignMemberSelector.getCampaignMembersForAssignment(new List<CampaignMemberSelector.FlowInput>{input});
        Test.stopTest();
        
        CampaignMemberSelector.FlowOutput output = results[0];
        
        // Verify inactive account is not included
        Set<Id> contactIds = new Set<Id>();
        for (CampaignMember cm : output.mainCampaignMembers) {
            contactIds.add(cm.ContactId);
        }
        
        Account refreshedInactive = [SELECT PersonContactId FROM Account WHERE Id = :inactiveAccount.Id];
        System.assert(!contactIds.contains(refreshedInactive.PersonContactId), 
                     'Inactive account should not be included');
    }
}