@isTest
private class ARC_CreatePartAggregatorsBatchTest {

    @isTest
    static void ARC_CreatePartAggregatorsBatchTest() {
        // Create an account
        Account testGroupAccount = new Account(
            Name = 'Test Group Account',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Group'].Id
        );
        insert testGroupAccount;

        // Create a person account
        Account testPersonAccount = new Account(
            FirstName = 'Test Person',
            LastName = 'Account',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'ARC_IFPPersonAccount'].Id
        );
        insert testPersonAccount;

        List<Account> accountListContactIdsPrimary = [SELECT PersonContactId FROM Account WHERE FirstName = 'Test Person'];

        // Create a contract terminated and a contract activated
        List<Contract> draftContractList = new List<Contract>();
        for (Integer i = 0; i < 2; i++) {
            Contract draftContract = new Contract(
                Name = 'Test Contract',
                Status = 'Draft',
                StartDate = Date.today(),
                AccountId = testGroupAccount.Id
            );
            draftContractList.add(draftContract);
        }
        draftContractList[0].ARC_ContractReason__c = 'Upgraded Spin Off';
        draftContractList[1].ARC_ContractReason__c = 'Remove Member';
        insert draftContractList;

        List<ARC_ContractParticipant__c> contractParticipantPrimaryList = new List<ARC_ContractParticipant__c>();
        for (Integer i = 0; i < 2; i++) {
            ARC_ContractParticipant__c contractParticipantPrimary = new ARC_ContractParticipant__c();
            contractParticipantPrimary.ARC_Contract__c = draftContractList[i].Id;
            contractParticipantPrimary.ARC_PersonAccount__c = testPersonAccount.Id;
            contractParticipantPrimaryList.add(contractParticipantPrimary);
        }
        insert contractParticipantPrimaryList;

        // Create an insurance policy associated with the draft contract
        List<InsurancePolicy> testPolicyList = new List<InsurancePolicy>();
        for (Integer i = 0; i < 2; i++) {
            InsurancePolicy testPolicy = new InsurancePolicy(
                Name = 'Test Policy',
                ARC_Contract__c = draftContractList[i].Id,
                NameInsuredId = testPersonAccount.Id
            );
            testPolicyList.add(testPolicy);
        }
        insert testPolicyList;
        testPolicyList[1].RenewedFromPolicyId = testPolicyList[0].Id;
        update testPolicyList;

        List<ARC_Aggregator__c> testAggregatorList = new List<ARC_Aggregator__c>();
        for (Integer i = 0; i < 2; i++) {
            ARC_Aggregator__c testAggregator = new ARC_Aggregator__c();
            testAggregator.Name = 'Pre Existing Conditions';
            testAggregator.ARC_CreatedIn__c = testPolicyList[0].Id;
            testAggregator.ARC_Member__c = testPersonAccount.Id;
            testAggregatorList.add(testAggregator);
        }
        testAggregatorList[0].ARC_Year__c = '2024';
        testAggregatorList[1].ARC_Year__c = '2025';
        insert testAggregatorList;

        List<InsurancePolicyParticipant> ippList = new List<InsurancePolicyParticipant>();
        for (Integer i = 0; i < 2; i++) {
            InsurancePolicyParticipant ipp = new InsurancePolicyParticipant();
            ipp.PrimaryParticipantContactId = accountListContactIdsPrimary[0].PersonContactId;
            ipp.InsurancePolicyId = testPolicyList[i].Id;
            ipp.Role = 'Primary';
            ippList.add(ipp);
        }
        insert ippList;

        List<ARC_ParticipantAggregator__c> testPersonAggregatorList = new List<ARC_ParticipantAggregator__c>();
        for (Integer i = 0; i < 2; i++) {
            ARC_ParticipantAggregator__c testPersonAggregator = new ARC_ParticipantAggregator__c();
            testPersonAggregator.Name = 'Pre Existing Conditions';
            testPersonAggregator.ARC_Aggregator__c = testAggregatorList[0].Id;
            testPersonAggregator.ARC_PolicyParticipant__c = ippList[i].Id;
            testPersonAggregator.ARC_Policy__c = testPolicyList[i].Id;
            testPersonAggregatorList.add(testPersonAggregator);
        }
        insert testPersonAggregatorList;

        List<ChargentOrders__ChargentOrder__c> testRecurringChargentOrderList = new List<ChargentOrders__ChargentOrder__c>();
        for (Integer i = 0; i < 2; i++) {
            ChargentOrders__ChargentOrder__c testRecurringChargentOrder = new ChargentOrders__ChargentOrder__c();
            testRecurringChargentOrder.ARC_Contract__c = draftContractList[i].Id;
            testRecurringChargentOrder.ChargentOrders__Shipping__c = 232;
            testRecurringChargentOrder.ChargentOrders__Tax__c  = 232;
            testRecurringChargentOrder.ChargentOrders__Charge_Amount__c = 232;
            testRecurringChargentOrder.ChargentOrders__Subtotal__c  = 232;
            testRecurringChargentOrder.ChargentOrders__Charge_Date__c =  '01';
            testRecurringChargentOrder.ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3);
            testRecurringChargentOrder.ChargentOrders__Payment_Status__c = 'Recurring';
            testRecurringChargentOrder.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12);
            testRecurringChargentOrder.ChargentOrders__Payment_Method__c = 'Credit Card';
            testRecurringChargentOrder.ChargentOrders__Card_Last_4__c = '1234';
            testRecurringChargentOrder.ChargentOrders__Card_Type__c = 'VISA';
            testRecurringChargentOrder.ChargentOrders__Card_Expiration_Month__c = '12';
            testRecurringChargentOrder.ChargentOrders__Card_Expiration_Year__c = '2024';
            testRecurringChargentOrder.ChargentOrders__Tokenization__c = '12345678';
            testRecurringChargentOrder.ChargentOrders__Description__c = 'Recurring Monthly Order';
            testRecurringChargentOrderList.add(testRecurringChargentOrder);
        }
        insert testRecurringChargentOrderList;

        // Update the contract to activated and assing a recurring order
        draftContractList[0].Status = 'Activated';
        draftContractList[0].ARC_RecurringMonthlyOrder__c = testRecurringChargentOrderList[0].Id;
        update draftContractList;
        // Update the contract to terminated
        draftContractList[0].Status = 'Terminated';
        update draftContractList;
        draftContractList[1].Status = 'Activated';
        draftContractList[1].ARC_RecurringMonthlyOrder__c = testRecurringChargentOrderList[1].Id;
        update draftContractList;


        Test.startTest();
        ARC_CreatePartAggregatorsBatch batch = new ARC_CreatePartAggregatorsBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        List<ARC_ParticipantAggregator__c> result = [SELECT Id, ARC_Policy__c FROM ARC_ParticipantAggregator__c];
        List<ARC_ParticipantAggregator__c> resultUpgrade = new List<ARC_ParticipantAggregator__c>();
        List<ARC_ParticipantAggregator__c> resultCarryOver = new List<ARC_ParticipantAggregator__c>();
        for (ARC_ParticipantAggregator__c pa : result) {
            if (pa.ARC_Policy__c == testPolicyList[0].Id) {
                resultUpgrade.add(pa);
            } else if (pa.ARC_Policy__c == testPolicyList[0].Id) {
                resultCarryOver.add(pa);
            }
        }

        System.assertEquals(resultUpgrade.size(), 2, 'Participant Aggregator was not created for Upgrade policy');
        System.assertEquals(resultUpgrade.size(), 2, 'Participant Aggregator was not created for Carry Over policy');
    }
}