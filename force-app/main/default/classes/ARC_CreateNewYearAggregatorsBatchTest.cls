@isTest
private class ARC_CreateNewYearAggregatorsBatchTest {
    
    @TestSetup
    static void makeData(){
        // Insert account
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account account = new Account(RecordTypeId = accRecordTypeId, FirstName = 'Personaccountount', LastName = 'Test');
        account.BillingStreet = '123 Avenue';
        account.BillingState = 'NY';
        account.BillingCity = 'New York';
        account.BillingPostalCode = '12345';
        account.PersonEmail = 'test@email.com';
        account.ARC_IsPrimaryMember__c = true;
        account.ARC_E123MemberIdFromPolicy__c = 'W123456789';
        account.IsActive = true;
        insert account;
        System.debug('Inserted Account Id: ' + account.Id);

        // Insert contract
        Contract contract = ARC_TestUtility.createContractsAA(1)[0];
        insert contract;
        System.debug('Inserted Contract Id: ' + contract.Id);
        contract.Status = 'Activated';
        contract.ARC_ContractReason__c = 'New Application';
        contract.ARC_EffectiveDate__c = Date.today();
        contract.ActivatedDate = Date.today();
        update contract;
        System.debug('Updated Contract Id: ' + contract.Id);

        // Insert product
        Product2 product = new Product2();
        product.Name = 'WeShare 6k ';
        product.ProductCode = 'PROG_UHSM_WeShare6k';
        product.vlocity_ins__Type__c = 'Medical';
        insert product;
        System.debug('Inserted Product Id: ' + product.Id);

        // Insert policy
        InsurancePolicy policy = new InsurancePolicy();
        policy.Name = 'Policy Test';
        policy.ProductId = product.Id;
        policy.ARC_Contract__c = contract.Id;
        policy.NameInsuredId = account.Id;
        insert policy;
        System.debug('Inserted Policy Id: ' + policy.Id);

        Account acc = [SELECT Id, PersonContactId FROM Account WHERE Id = :account.Id LIMIT 1];
        // Insert policy participant
        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant();
        ipp.Role = 'Primary';
        ipp.PrimaryParticipantContactId = acc.PersonContactId;
        ipp.InsurancePolicyId = policy.Id;
        ipp.ARC_StartDate__c = Date.today();
        insert ipp;
        System.debug('Inserted Insurance Policy Participant Id: ' + ipp.Id);
    }


    @isTest
    static void testExecuteSuccess(){
        Test.startTest();
        ARC_CreateNewYearAggregatorsBatch batch = new ARC_CreateNewYearAggregatorsBatch(2026);
        Database.executeBatch(batch);
        Test.stopTest();

        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c];
        List<ARC_ParticipantAggregator__c> participantAggregators = [SELECT Id FROM ARC_ParticipantAggregator__c];
        system.debug('Aggregators created: ' + aggregators.size());
        system.debug('Participant Aggregators created: ' + participantAggregators.size());

        Assert.areEqual(12, aggregators.size(), 'Aggregators were not correctly created');
        Assert.areEqual(11, participantAggregators.size(), 'Participant Aggregators were not correctly created');
    }

    @isTest
    static void testExecuteFail(){
        Test.startTest();
        InsurancePolicy policyToUpdate = [SELECT Id, ProductId, ARC_Contract__c FROM InsurancePolicy WHERE Name = 'Policy Test' LIMIT 1];
        policyToUpdate.ProductId = null; // Insert invalid data to cause error
        update policyToUpdate;
        ARC_CreateNewYearAggregatorsBatch batch = new ARC_CreateNewYearAggregatorsBatch(2026);
        Database.executeBatch(batch);
        Test.stopTest();

        List<ARC_Aggregator__c> aggregators = [SELECT Id FROM ARC_Aggregator__c];
        List<ARC_ParticipantAggregator__c> participantAggregators = [SELECT Id FROM ARC_ParticipantAggregator__c];
        system.debug('Aggregators created: ' + aggregators.size());
        system.debug('Participant Aggregators created: ' + participantAggregators.size());

        Assert.areEqual(0, aggregators.size(), 'Aggregators should not have been created due to error');
        Assert.areEqual(0, participantAggregators.size(), 'Participant Aggregators should not have been created due to error');
    }

}