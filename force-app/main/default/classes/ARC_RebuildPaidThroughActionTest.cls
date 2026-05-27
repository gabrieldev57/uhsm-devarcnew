@IsTest
public class ARC_RebuildPaidThroughActionTest {

    /**
     * Test: Rebuild with no Contract Id provided
     */
    @isTest
    static void test_rebuild_noContractId() {
        Test.startTest();
        ARC_RebuildPaidThroughAction.RebuildRequest req = new ARC_RebuildPaidThroughAction.RebuildRequest();
        req.contractId = null;

        List<ARC_RebuildPaidThroughAction.RebuildResult> results = 
            ARC_RebuildPaidThroughAction.rebuild(new List<ARC_RebuildPaidThroughAction.RebuildRequest>{req});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].success, 'Should fail when no Contract Id provided');
        System.assert(results[0].message.contains('No Contract Id'), 'Message should indicate missing Contract Id');
    }

    /**
     * Test: Rebuild with non-existent Contract Id
     */
    @isTest
    static void test_rebuild_contractNotFound() {
        // Create a fake Contract Id that doesn't exist
        Id fakeContractId = Schema.SObjectType.Contract.getKeyPrefix() + '000000000000';

        Test.startTest();
        ARC_RebuildPaidThroughAction.RebuildRequest req = new ARC_RebuildPaidThroughAction.RebuildRequest();
        req.contractId = fakeContractId;

        List<ARC_RebuildPaidThroughAction.RebuildResult> results = 
            ARC_RebuildPaidThroughAction.rebuild(new List<ARC_RebuildPaidThroughAction.RebuildRequest>{req});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].success, 'Should fail when contract not found');
        System.assert(results[0].message.contains('not found'), 'Message should indicate contract not found');
    }

    /**
     * Test: Rebuild with valid Contract but no Chargent Order
     */
    @isTest
    static void test_rebuild_noChargentOrder() {
        // Setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Id smallGroupRT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        Contract contract = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 12,
            RecordTypeId = smallGroupRT,
            ARC_EffectiveDate__c = Date.today(),
            ARC_PaymentFrequency__c = 'Monthly',
            ARC_CoveragePaidThrough__c = Date.today().addMonths(1)
        );
        insert contract;

        Test.startTest();
        ARC_RebuildPaidThroughAction.RebuildRequest req = new ARC_RebuildPaidThroughAction.RebuildRequest();
        req.contractId = contract.Id;

        List<ARC_RebuildPaidThroughAction.RebuildResult> results = 
            ARC_RebuildPaidThroughAction.rebuild(new List<ARC_RebuildPaidThroughAction.RebuildRequest>{req});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].success, 'Should fail when no Chargent Order');
        System.assert(results[0].message.contains('No Chargent Order'), 'Message should indicate no Chargent Order');
    }

    /**
     * Test: Rebuild with Chargent Order but no approved transactions
     */
    @isTest
    static void test_rebuild_noTransactions() {
        // Setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Charge_Amount__c = 100.00
        );
        insert order;

        Id smallGroupRT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        Contract contract = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 12,
            RecordTypeId = smallGroupRT,
            ARC_EffectiveDate__c = Date.today(),
            ARC_PaymentFrequency__c = 'Monthly',
            ARC_RecurringMonthlyOrder__c = order.Id,
            ARC_CoveragePaidThrough__c = Date.today().addMonths(1)
        );
        insert contract;

        Test.startTest();
        ARC_RebuildPaidThroughAction.RebuildRequest req = new ARC_RebuildPaidThroughAction.RebuildRequest();
        req.contractId = contract.Id;

        List<ARC_RebuildPaidThroughAction.RebuildResult> results = 
            ARC_RebuildPaidThroughAction.rebuild(new List<ARC_RebuildPaidThroughAction.RebuildRequest>{req});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Should succeed with no transactions');
        System.assertEquals(null, results[0].newCoveragePaidThrough, 'Coverage should be reset to null');
        System.assert(results[0].message.contains('No approved transactions'), 'Message should indicate no transactions');

        // Verify contract was updated
        Contract updatedContract = [SELECT ARC_CoveragePaidThrough__c FROM Contract WHERE Id = :contract.Id];
        System.assertEquals(null, updatedContract.ARC_CoveragePaidThrough__c, 'Coverage Paid Through should be null');
    }

    /**
     * Test: Rebuild with single Charge transaction (Monthly)
     */
    @isTest
    static void test_rebuild_singleChargeMonthly() {
        // Setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Charge_Amount__c = 100.00
        );
        insert order;

        Date effectiveDate = Date.today();
        Date coverTo = effectiveDate.addMonths(1).addDays(-1);

        Id smallGroupRT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        Contract contract = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            StartDate = effectiveDate,
            ContractTerm = 12,
            RecordTypeId = smallGroupRT,
            ARC_EffectiveDate__c = effectiveDate,
            ARC_PaymentFrequency__c = 'Monthly',
            ARC_RecurringMonthlyOrder__c = order.Id
        );
        insert contract;

        ChargentOrders__Transaction__c charge = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = order.Id,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved',
            ARC_Cover_To__c = coverTo
        );
        insert charge;

        Test.startTest();
        ARC_RebuildPaidThroughAction.RebuildRequest req = new ARC_RebuildPaidThroughAction.RebuildRequest();
        req.contractId = contract.Id;

        List<ARC_RebuildPaidThroughAction.RebuildResult> results = 
            ARC_RebuildPaidThroughAction.rebuild(new List<ARC_RebuildPaidThroughAction.RebuildRequest>{req});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Should succeed');
        System.assertEquals(coverTo, results[0].newCoveragePaidThrough, 'Coverage should match transaction Cover To date');

        // Verify contract was updated
        Contract updatedContract = [SELECT ARC_CoveragePaidThrough__c FROM Contract WHERE Id = :contract.Id];
        System.assertEquals(coverTo, updatedContract.ARC_CoveragePaidThrough__c, 'Coverage Paid Through should be updated');
    }

    /**
     * Test: Rebuild with multiple Charge transactions (Quarterly)
     */
    @isTest
    static void test_rebuild_multipleChargesQuarterly() {
        // Setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Charge_Amount__c = 300.00
        );
        insert order;

        Date effectiveDate = Date.today();
        Date coverTo1 = effectiveDate.addMonths(3).addDays(-1);
        Date coverTo2 = effectiveDate.addMonths(6).addDays(-1);

        Id smallGroupRT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        Contract contract = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            StartDate = effectiveDate,
            ContractTerm = 12,
            RecordTypeId = smallGroupRT,
            ARC_EffectiveDate__c = effectiveDate,
            ARC_PaymentFrequency__c = 'Quarterly',
            ARC_RecurringMonthlyOrder__c = order.Id
        );
        insert contract;

        List<ChargentOrders__Transaction__c> charges = new List<ChargentOrders__Transaction__c>{
            new ChargentOrders__Transaction__c(
                ChargentOrders__Order__c = order.Id,
                ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Response_Status__c = 'Approved',
                ARC_Cover_To__c = coverTo1
            ),
            new ChargentOrders__Transaction__c(
                ChargentOrders__Order__c = order.Id,
                ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Response_Status__c = 'Approved',
                ARC_Cover_To__c = coverTo2
            )
        };
        insert charges;

        Test.startTest();
        ARC_RebuildPaidThroughAction.RebuildRequest req = new ARC_RebuildPaidThroughAction.RebuildRequest();
        req.contractId = contract.Id;

        List<ARC_RebuildPaidThroughAction.RebuildResult> results = 
            ARC_RebuildPaidThroughAction.rebuild(new List<ARC_RebuildPaidThroughAction.RebuildRequest>{req});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Should succeed');
        System.assertEquals(coverTo2, results[0].newCoveragePaidThrough, 'Coverage should be the latest Cover To date');
    }

    /**
     * Test: Rebuild with Charge then Refund (Annual)
     */
    @isTest
    static void test_rebuild_chargeAndRefundAnnual() {
        // Setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Charge_Amount__c = 1200.00
        );
        insert order;

        Date effectiveDate = Date.newInstance(2024, 1, 1);
        Date coverTo1 = Date.newInstance(2024, 12, 31);
        Date coverTo2 = Date.newInstance(2025, 12, 31);

        Id smallGroupRT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        Contract contract = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            StartDate = effectiveDate,
            ContractTerm = 12,
            RecordTypeId = smallGroupRT,
            ARC_EffectiveDate__c = effectiveDate,
            ARC_PaymentFrequency__c = 'Annual',
            ARC_RecurringMonthlyOrder__c = order.Id
        );
        insert contract;

        // Insert two charges to establish coverage through 2025
        List<ChargentOrders__Transaction__c> charges = new List<ChargentOrders__Transaction__c>{
            new ChargentOrders__Transaction__c(
                ChargentOrders__Order__c = order.Id,
                ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Response_Status__c = 'Approved',
                ARC_Cover_To__c = coverTo1
            ),
            new ChargentOrders__Transaction__c(
                ChargentOrders__Order__c = order.Id,
                ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Response_Status__c = 'Approved',
                ARC_Cover_To__c = coverTo2
            )
        };
        insert charges;

        // Then insert refund (will roll back coverage by 12 months from 2025-12-31 to 2024-12-31)
        ChargentOrders__Transaction__c refund = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = order.Id,
            ChargentOrders__Type__c = 'Refund',
            ChargentOrders__Response_Status__c = 'Approved'
        );
        insert refund;

        Test.startTest();
        ARC_RebuildPaidThroughAction.RebuildRequest req = new ARC_RebuildPaidThroughAction.RebuildRequest();
        req.contractId = contract.Id;

        List<ARC_RebuildPaidThroughAction.RebuildResult> results = 
            ARC_RebuildPaidThroughAction.rebuild(new List<ARC_RebuildPaidThroughAction.RebuildRequest>{req});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Should succeed');
        // Refund should roll back 12 months from 2025-12-31: +1d = 2026-01-01, -12m = 2025-01-01, -1d = 2024-12-31
        Date expectedCoverage = Date.newInstance(2024, 12, 31);
        System.assertEquals(expectedCoverage, results[0].newCoveragePaidThrough, 'Coverage should be rolled back by 12 months');
    }

    /**
     * Test: Rebuild with Charge then Void
     */
    @isTest
    static void test_rebuild_chargeAndVoid() {
        // Setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Charge_Amount__c = 100.00
        );
        insert order;

        Date effectiveDate = Date.today();
        Date coverTo1 = effectiveDate.addMonths(1).addDays(-1);
        Date coverTo2 = effectiveDate.addMonths(2).addDays(-1);

        Id smallGroupRT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        Contract contract = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            StartDate = effectiveDate,
            ContractTerm = 12,
            RecordTypeId = smallGroupRT,
            ARC_EffectiveDate__c = effectiveDate,
            ARC_PaymentFrequency__c = 'Monthly',
            ARC_RecurringMonthlyOrder__c = order.Id
        );
        insert contract;

        // Insert two charges to establish coverage through 2 months
        List<ChargentOrders__Transaction__c> charges = new List<ChargentOrders__Transaction__c>{
            new ChargentOrders__Transaction__c(
                ChargentOrders__Order__c = order.Id,
                ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Response_Status__c = 'Approved',
                ARC_Cover_To__c = coverTo1
            ),
            new ChargentOrders__Transaction__c(
                ChargentOrders__Order__c = order.Id,
                ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Response_Status__c = 'Approved',
                ARC_Cover_To__c = coverTo2
            )
        };
        insert charges;

        // Then insert void (will roll back coverage by 1 month)
        ChargentOrders__Transaction__c voidTx = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = order.Id,
            ChargentOrders__Type__c = 'Void',
            ChargentOrders__Response_Status__c = 'Approved'
        );
        insert voidTx;

        Test.startTest();
        ARC_RebuildPaidThroughAction.RebuildRequest req = new ARC_RebuildPaidThroughAction.RebuildRequest();
        req.contractId = contract.Id;

        List<ARC_RebuildPaidThroughAction.RebuildResult> results = 
            ARC_RebuildPaidThroughAction.rebuild(new List<ARC_RebuildPaidThroughAction.RebuildRequest>{req});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Should succeed');
        // Void should roll back coverage by 1 month from coverTo2
        Date expectedCoverage = coverTo2.addDays(1).addMonths(-1).addDays(-1);
        System.assertEquals(expectedCoverage, results[0].newCoveragePaidThrough, 'Coverage should be rolled back by void');
    }

    /**
     * Test: Rebuild with Refund that rolls back before effective date (should become null)
     */
    @isTest
    static void test_rebuild_refundBeforeEffectiveDate() {
        // Setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Charge_Amount__c = 100.00
        );
        insert order;

        Date effectiveDate = Date.today();
        Date coverTo = effectiveDate.addDays(15); // Less than 1 month

        Id smallGroupRT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        Contract contract = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            StartDate = effectiveDate,
            ContractTerm = 12,
            RecordTypeId = smallGroupRT,
            ARC_EffectiveDate__c = effectiveDate,
            ARC_PaymentFrequency__c = 'Monthly',
            ARC_RecurringMonthlyOrder__c = order.Id
        );
        insert contract;

        ChargentOrders__Transaction__c charge = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = order.Id,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved',
            ARC_Cover_To__c = coverTo
        );
        insert charge;

        // Refund will roll back and result in date before effective date
        ChargentOrders__Transaction__c refund = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = order.Id,
            ChargentOrders__Type__c = 'Refund',
            ChargentOrders__Response_Status__c = 'Approved'
        );
        insert refund;

        Test.startTest();
        ARC_RebuildPaidThroughAction.RebuildRequest req = new ARC_RebuildPaidThroughAction.RebuildRequest();
        req.contractId = contract.Id;

        List<ARC_RebuildPaidThroughAction.RebuildResult> results = 
            ARC_RebuildPaidThroughAction.rebuild(new List<ARC_RebuildPaidThroughAction.RebuildRequest>{req});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Should succeed');
        System.assertEquals(null, results[0].newCoveragePaidThrough, 'Coverage should be null when rolled back before effective date');
    }

    /**
     * Test: Rebuild with multiple contracts (bulk processing)
     */
    @isTest
    static void test_rebuild_bulkMultipleContracts() {
        // Setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        List<ChargentOrders__ChargentOrder__c> orders = new List<ChargentOrders__ChargentOrder__c>{
            new ChargentOrders__ChargentOrder__c(ChargentOrders__Charge_Amount__c = 100.00),
            new ChargentOrders__ChargentOrder__c(ChargentOrders__Charge_Amount__c = 200.00)
        };
        insert orders;

        Date effectiveDate = Date.today();
        Id smallGroupRT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();

        List<Contract> contracts = new List<Contract>{
            new Contract(
                AccountId = acc.Id,
                Status = 'Draft',
                StartDate = effectiveDate,
                ContractTerm = 12,
                RecordTypeId = smallGroupRT,
                ARC_EffectiveDate__c = effectiveDate,
                ARC_PaymentFrequency__c = 'Monthly',
                ARC_RecurringMonthlyOrder__c = orders[0].Id
            ),
            new Contract(
                AccountId = acc.Id,
                Status = 'Draft',
                StartDate = effectiveDate,
                ContractTerm = 12,
                RecordTypeId = smallGroupRT,
                ARC_EffectiveDate__c = effectiveDate,
                ARC_PaymentFrequency__c = 'Quarterly',
                ARC_RecurringMonthlyOrder__c = orders[1].Id
            )
        };
        insert contracts;

        // Add transactions
        List<ChargentOrders__Transaction__c> transactions = new List<ChargentOrders__Transaction__c>{
            new ChargentOrders__Transaction__c(
                ChargentOrders__Order__c = orders[0].Id,
                ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Response_Status__c = 'Approved',
                ARC_Cover_To__c = effectiveDate.addMonths(1).addDays(-1)
            ),
            new ChargentOrders__Transaction__c(
                ChargentOrders__Order__c = orders[1].Id,
                ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Response_Status__c = 'Approved',
                ARC_Cover_To__c = effectiveDate.addMonths(3).addDays(-1)
            )
        };
        insert transactions;

        Test.startTest();
        List<ARC_RebuildPaidThroughAction.RebuildRequest> requests = new List<ARC_RebuildPaidThroughAction.RebuildRequest>{
            new ARC_RebuildPaidThroughAction.RebuildRequest(),
            new ARC_RebuildPaidThroughAction.RebuildRequest()
        };
        requests[0].contractId = contracts[0].Id;
        requests[1].contractId = contracts[1].Id;

        List<ARC_RebuildPaidThroughAction.RebuildResult> results = 
            ARC_RebuildPaidThroughAction.rebuild(requests);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return two results');
        System.assertEquals(true, results[0].success, 'First rebuild should succeed');
        System.assertEquals(true, results[1].success, 'Second rebuild should succeed');
        System.assertEquals(effectiveDate.addMonths(1).addDays(-1), results[0].newCoveragePaidThrough, 'First contract coverage');
        System.assertEquals(effectiveDate.addMonths(3).addDays(-1), results[1].newCoveragePaidThrough, 'Second contract coverage');
    }

    /**
     * Test: Charge with null ARC_Cover_To__c (should not advance coverage)
     */
    @isTest
    static void test_rebuild_chargeWithNullCoverTo() {
        // Setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Charge_Amount__c = 100.00
        );
        insert order;

        Date effectiveDate = Date.today();

        Id smallGroupRT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        Contract contract = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            StartDate = effectiveDate,
            ContractTerm = 12,
            RecordTypeId = smallGroupRT,
            ARC_EffectiveDate__c = effectiveDate,
            ARC_PaymentFrequency__c = 'Monthly',
            ARC_RecurringMonthlyOrder__c = order.Id
        );
        insert contract;

        ChargentOrders__Transaction__c charge = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = order.Id,
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Response_Status__c = 'Approved',
            ARC_Cover_To__c = null // Null Cover To
        );
        insert charge;

        Test.startTest();
        ARC_RebuildPaidThroughAction.RebuildRequest req = new ARC_RebuildPaidThroughAction.RebuildRequest();
        req.contractId = contract.Id;

        List<ARC_RebuildPaidThroughAction.RebuildResult> results = 
            ARC_RebuildPaidThroughAction.rebuild(new List<ARC_RebuildPaidThroughAction.RebuildRequest>{req});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Should succeed');
        System.assertEquals(null, results[0].newCoveragePaidThrough, 'Coverage should remain null');
    }

    /**
     * Test: Multiple charges with different cover dates (should use latest)
     */
    @isTest
    static void test_rebuild_multipleChargesTakesLatest() {
        // Setup
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Charge_Amount__c = 100.00
        );
        insert order;

        Date effectiveDate = Date.today();
        Date coverTo1 = effectiveDate.addMonths(1).addDays(-1);
        Date coverTo2 = effectiveDate.addMonths(2).addDays(-1); // Later date
        Date coverTo3 = effectiveDate.addMonths(1).addDays(10); // In between

        Id smallGroupRT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        Contract contract = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            StartDate = effectiveDate,
            ContractTerm = 12,
            RecordTypeId = smallGroupRT,
            ARC_EffectiveDate__c = effectiveDate,
            ARC_PaymentFrequency__c = 'Monthly',
            ARC_RecurringMonthlyOrder__c = order.Id
        );
        insert contract;

        List<ChargentOrders__Transaction__c> charges = new List<ChargentOrders__Transaction__c>{
            new ChargentOrders__Transaction__c(
                ChargentOrders__Order__c = order.Id,
                ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Response_Status__c = 'Approved',
                ARC_Cover_To__c = coverTo1
            ),
            new ChargentOrders__Transaction__c(
                ChargentOrders__Order__c = order.Id,
                ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Response_Status__c = 'Approved',
                ARC_Cover_To__c = coverTo2
            ),
            new ChargentOrders__Transaction__c(
                ChargentOrders__Order__c = order.Id,
                ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Response_Status__c = 'Approved',
                ARC_Cover_To__c = coverTo3
            )
        };
        insert charges;

        Test.startTest();
        ARC_RebuildPaidThroughAction.RebuildRequest req = new ARC_RebuildPaidThroughAction.RebuildRequest();
        req.contractId = contract.Id;

        List<ARC_RebuildPaidThroughAction.RebuildResult> results = 
            ARC_RebuildPaidThroughAction.rebuild(new List<ARC_RebuildPaidThroughAction.RebuildRequest>{req});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Should succeed');
        System.assertEquals(coverTo2, results[0].newCoveragePaidThrough, 'Should use the latest Cover To date');
    }
}