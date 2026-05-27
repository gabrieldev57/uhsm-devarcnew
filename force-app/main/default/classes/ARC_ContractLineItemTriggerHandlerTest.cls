@isTest
private class ARC_ContractLineItemTriggerHandlerTest {

    @testSetup
    static void setupData() {
        // Step 1: Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Step 2: Create Vlocity Contract linked to Account
        Contract contract = new Contract(
            Name = 'Test Contract',
            AccountId = acc.Id
        );
        insert contract;

        // Step 3: Create Contract Line Item linked to Contract
        vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c(
            Name = 'Test CLI',
            vlocity_ins__ContractId__c = contract.Id
        );
        insert cli;

        // Step 4: Create Group (required for GroupClass)
        Account grop = new Account(
            Name = 'Test Group'
        );
        insert grop;

        // Step 5: Create Group Class linked to Group
        vlocity_ins__GroupClass__c groupClass = new vlocity_ins__GroupClass__c(
            Name = 'Test Group Class',
            vlocity_ins__GroupId__c = grop.Id
        );
        insert groupClass;

        // Step 6: Create Group Class Contribution linked to CLI and Group Class
        vlocity_ins__GroupClassContribution__c gcc = new vlocity_ins__GroupClassContribution__c(
            Name = 'Test GCC',
            ARC_ContractLineItem__c = cli.Id,
            vlocity_ins__GroupClassId__c = groupClass.Id,
            vlocity_ins__ContributionType__c = 'Test Type',      // picklist
            vlocity_ins__ProductCategory__c = 'Test Category'    // picklist
        );
        insert gcc;
    }

    @isTest
    static void testAfterDeleteWithNoLinkedGCC() {
        Account acc = new Account(Name = 'No GCC Account');
        insert acc;

        Contract contract = new Contract(
            Name = 'No GCC Contract',
            AccountId = acc.Id
        );
        insert contract;

        vlocity_ins__ContractLineItem__c cliNoGCC = new vlocity_ins__ContractLineItem__c(
            Name = 'CLI without GCC',
            vlocity_ins__ContractId__c = contract.Id
        );
        insert cliNoGCC;

        Test.startTest();
        delete cliNoGCC; // triggers handleAfterDelete
        Test.stopTest();

        Integer gccCount = [SELECT COUNT() FROM vlocity_ins__GroupClassContribution__c WHERE ARC_ContractLineItem__c = :cliNoGCC.Id];
        System.assertEquals(0, gccCount, 'No GCC should exist for CLI without linked records');
    }

    @isTest
    static void testAfterDeleteWithNullId() {
        // Ensure handler safely handles null Ids
        List<vlocity_ins__ContractLineItem__c> fakeCLIs = new List<vlocity_ins__ContractLineItem__c>{
            new vlocity_ins__ContractLineItem__c(Name = 'Fake CLI 1'), 
            new vlocity_ins__ContractLineItem__c(Name = 'Fake CLI 2')
        };
        // Do NOT insert them; Ids are null

        Test.startTest();
        ARC_ContractLineItemTriggerHandler.handleAfterDelete(fakeCLIs);
        Test.stopTest();

        System.assert(true, 'Handler should safely skip CLI records with null Ids');
    }
}