@isTest
private class ARC_PopulateContractPrimaryAddressTest {

    @TestSetup
    static void makeData() {
        List<Contract> contract = ARC_TestUtility.createContractsAA(1);
        insert contract;

        Account famAccount = [SELECT Id FROM Account LIMIT 1];

        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account acc = new Account();
        acc.FirstName = 'TestFirstName';
        acc.LastName = 'TestLastName';
        acc.RecordTypeId = recordTypeId;
        acc.BillingStreet = '123 Main St';
        acc.BillingCity = 'Kansas City';
        acc.BillingState = 'KS';
        acc.BillingPostalCode = '44444';
        acc.IsActive = true;
        acc.ARC_IsPrimaryMember__c = true;
        acc.ARC_GroupAccount__c = contract[0].AccountId;
        insert acc;

        famAccount.ARC_PrimaryMemberAccount__c = acc.Id;
        update famAccount;

        Account accountToContactId = [SELECT Id, PersonContactId FROM Account WHERE FirstName = 'TestFirstName' LIMIT 1];

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = contract[0].AccountId;
        census.ARC_PrimaryAccount__c = acc.Id;
        insert census;

        vlocity_ins__GroupCensus__c censdebug = [SELECT Id, Name, vlocity_ins__GroupId__c, ARC_PrimaryAccount__c FROM vlocity_ins__GroupCensus__c];
        System.debug('censdebug: ' + censdebug);

        vlocity_ins__GroupCensusMember__c cenMem = new vlocity_ins__GroupCensusMember__c();
        cenMem.Name = 'Test Census Member';
        cenMem.vlocity_ins__FirstName__c = 'TestFirstName';
        cenMem.vlocity_ins__LastName__c = 'TestLastName';
        cenMem.vlocity_ins__ContactId__c = accountToContactId.PersonContactId;
        cenMem.vlocity_ins__AccountId__c = accountToContactId.Id;
        cenMem.vlocity_ins__CensusId__c = census.Id;
        cenMem.vlocity_ins__IsPrimaryMember__c = true;
        cenMem.ARC_ActiveMember__c = true;
        cenMem.ARC_PhysicalAddressStreet__c = '123 Main St';
        cenMem.ARC_PhysicalAddressCity__c = 'Kansas City';
        cenMem.ARC_PhysicalAddressState__c = 'KS';
        cenMem.ARC_PhysicalAddressZipCode__c = '44444';
        insert cenMem;

        vlocity_ins__GroupCensusMember__c cenMemdebug = [SELECT Id, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, vlocity_ins__ContactId__c, vlocity_ins__AccountId__c, vlocity_ins__CensusId__c, vlocity_ins__IsPrimaryMember__c, ARC_ActiveMember__c FROM vlocity_ins__GroupCensusMember__c];
        System.debug('cenMemdebug: ' + cenMemdebug);

        contract[0].Status =  'Awaiting Activation';
        contract[0].vlocity_ins__EnrollmentCensusId__c = census.Id;
        update contract;

        census.ARC_PrimaryAccount__c = acc.Id;
        update census;

        Contract cont2 = [SELECT Id, vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.BillingStreet,
          vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.BillingCity, 
          vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.BillingState, 
          vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.BillingPostalCode 
          FROM Contract WHERE Status != 'Draft' AND vlocity_ins__EnrollmentCensusId__c != NULL AND ARC_PrimaryAddress__Street__s = NULL LIMIT 1];

        System.debug('cont2: ' + cont2);
        System.debug('acc2: ' + cont2.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r);

        vlocity_ins__GroupCensus__c censdebug2 = [SELECT Id, Name, vlocity_ins__GroupId__c, ARC_PrimaryAccount__c FROM vlocity_ins__GroupCensus__c];
        System.debug('censdebug2: ' + censdebug2);

        vlocity_ins__GroupCensusMember__c cenMemdebug2 = [SELECT Id, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, vlocity_ins__ContactId__c, vlocity_ins__AccountId__c, vlocity_ins__CensusId__c, vlocity_ins__IsPrimaryMember__c, ARC_ActiveMember__c FROM vlocity_ins__GroupCensusMember__c];
        System.debug('cenMemdebug2: ' + cenMemdebug2);
    }

    @isTest
    static void ARC_PopulateContractPrimaryAddressTest() {
        Test.startTest();
        ARC_PopulateContractPrimaryAddress batch = new ARC_PopulateContractPrimaryAddress();
        Database.executeBatch(batch);
        Test.stopTest();

        Contract cont = [SELECT Id, ARC_PrimaryAddress__Street__s, ARC_PrimaryAddress__City__s, ARC_PrimaryAddress__StateCode__s, ARC_PrimaryAddress__PostalCode__s FROM Contract LIMIT 1];

        Assert.areEqual('123 Main St', cont.ARC_PrimaryAddress__Street__s, 'Street is not being populated correctly');
        Assert.areEqual('Kansas City', cont.ARC_PrimaryAddress__City__s, 'City is not being populated correctly');
        Assert.areEqual('KS', cont.ARC_PrimaryAddress__StateCode__s, 'State is not being populated correctly');
        Assert.areEqual('44444', cont.ARC_PrimaryAddress__PostalCode__s, 'Postal Code is not being populated correctly');
    }
}