@isTest
private with sharing class ARC_MissedInvoiceControllerTest {
    private static final Date BASE_EFFECTIVE_DATE = Date.today().toStartOfMonth().addMonths(-1);
    private static final Date PRIOR_INVOICED_THROUGH_DATE = BASE_EFFECTIVE_DATE.addMonths(1).addDays(-1);
    private static final Date PAID_THROUGH_DATE = PRIOR_INVOICED_THROUGH_DATE;
    private static final String VALID_CONTROLLER_STATUS = 'Awaiting First Payment';

    @testSetup
    static void setup() {
        Account baseAccount = new Account(
            Name = 'Missed Invoice Test Account'
        );
        insert baseAccount;

        Contract baseContract = createContract(
            baseAccount.Id,
            'Draft',
            BASE_EFFECTIVE_DATE,
            null,
            null,
            'Monthly'
        );
        insert baseContract;
    }

    @isTest
    static void testGenerateMissedInvoices_throwsForInvalidStatus() {
        Account baseAccount = getBaseAccount();
        Contract invalidStatusContract = createContract(
            baseAccount.Id,
            'Draft',
            BASE_EFFECTIVE_DATE,
            null,
            null,
            'Monthly'
        );
        insert invalidStatusContract;

        Test.startTest();
        Boolean didThrow = false;
        try {
            ARC_MissedInvoiceController.generateMissedInvoices(invalidStatusContract.Id);
        } catch (AuraHandledException ex) {
            didThrow = true;
            System.assertNotEquals(null, ex,
                'The invalid status path should throw an AuraHandledException.');
        }
        System.assertEquals(true, didThrow,
            'The method should throw an AuraHandledException when the contract status is not allowed.');
        Test.stopTest();
    }

    @isTest
    static void testGenerateMissedInvoices_throwsWhenEffectiveDateIsMissing() {
        Account baseAccount = getBaseAccount();
        Contract missingEffectiveDateContract = createContract(
            baseAccount.Id,
            'Draft',
            null,
            null,
            null,
            'Monthly'
        );
        insert missingEffectiveDateContract;
        missingEffectiveDateContract.Status = VALID_CONTROLLER_STATUS;
        update missingEffectiveDateContract;

        Test.startTest();
        Boolean didThrow = false;
        try {
            ARC_MissedInvoiceController.generateMissedInvoices(missingEffectiveDateContract.Id);
        } catch (AuraHandledException ex) {
            didThrow = true;
            System.assertNotEquals(null, ex,
                'The missing effective date path should throw an AuraHandledException.');
        }
        System.assertEquals(true, didThrow,
            'The method should throw an AuraHandledException when the contract has no effective date.');
        Test.stopTest();
    }

    @isTest
    static void testGenerateMissedInvoices_startsFromEffectiveDateWhenNothingHasBeenInvoiced() {
        Account baseAccount = getBaseAccount();
        Contract freshContract = createContract(
            baseAccount.Id,
            'Draft',
            BASE_EFFECTIVE_DATE,
            null,
            null,
            'Monthly'
        );
        insert freshContract;
        freshContract.Status = VALID_CONTROLLER_STATUS;
        update freshContract;

        Test.startTest();
        String resultMessage = ARC_MissedInvoiceController.generateMissedInvoices(freshContract.Id);
        Test.stopTest();

        List<ARC_Invoice__c> createdInvoices = getInvoicesForContract(freshContract.Id);
        Contract refreshedContract = getContractById(freshContract.Id);

        System.assert(
            resultMessage != null && resultMessage.toLowerCase().contains('successfully generated'),
            'The method should return a success message when missed invoices are created. Actual: ' + resultMessage
        );
        System.assert(createdInvoices.size() > 0,
            'At least one missed invoice should be created when the contract has never been invoiced.');
        System.assertEquals(BASE_EFFECTIVE_DATE, createdInvoices[0].ARC_CoverageDateFrom__c,
            'The first missed invoice should begin at the contract effective date when nothing has been invoiced yet.');
        System.assertEquals(createdInvoices[createdInvoices.size() - 1].ARC_CoverageDateTo__c, refreshedContract.ARC_CoverageInvoicedThrough__c,
            'The contract should be updated through the last generated invoice coverage end date.');
        System.assertEquals(refreshedContract.ARC_CoverageInvoicedThrough__c.addDays(1), refreshedContract.ARC_NextInvoiceCoverageStart__c,
            'The next invoice coverage start should be one day after the new invoiced-through date.');
        System.assertEquals(createdInvoices[0].Id, refreshedContract.ARC_LastUnpaidInvoice__c,
            'When coverage paid through is blank, the first generated invoice should become the last unpaid invoice reference.');
    }

    @isTest
    static void testGenerateMissedInvoices_startsAfterCoverageInvoicedThroughAndUpdatesContract() {
        Account baseAccount = getBaseAccount();
        Date previouslyInvoicedThrough = PRIOR_INVOICED_THROUGH_DATE;
        Date paidThrough = PAID_THROUGH_DATE;

        Contract rolloverContract = createContract(
            baseAccount.Id,
            'Draft',
            BASE_EFFECTIVE_DATE,
            previouslyInvoicedThrough,
            paidThrough,
            'Monthly'
        );
        insert rolloverContract;
        rolloverContract.Status = VALID_CONTROLLER_STATUS;
        update rolloverContract;

        Test.startTest();
        String resultMessage = ARC_MissedInvoiceController.generateMissedInvoices(rolloverContract.Id);
        Test.stopTest();

        List<ARC_Invoice__c> createdInvoices = getInvoicesForContract(rolloverContract.Id);
        Contract refreshedContract = getContractById(rolloverContract.Id);
        Id expectedLastUnpaidInvoiceId = null;
        for (ARC_Invoice__c invoiceRecord : createdInvoices) {
            if (invoiceRecord.ARC_CoverageDateFrom__c > paidThrough) {
                expectedLastUnpaidInvoiceId = invoiceRecord.Id;
                break;
            }
        }

        System.assert(
            resultMessage != null && resultMessage.toLowerCase().contains('successfully generated'),
            'The method should return a success message when it creates rollover missed invoices. Actual: ' + resultMessage
        );
        System.assert(createdInvoices.size() > 0,
            'The contract should receive missed invoices after the prior invoiced-through date.');
        System.assertEquals(previouslyInvoicedThrough.addDays(1), createdInvoices[0].ARC_CoverageDateFrom__c,
            'The first new missed invoice should start the day after the prior invoiced-through date.');
        System.assertEquals(createdInvoices[createdInvoices.size() - 1].ARC_CoverageDateTo__c, refreshedContract.ARC_CoverageInvoicedThrough__c,
            'The contract should roll its invoiced-through date forward to the end of the last generated invoice.');
        System.assertEquals(refreshedContract.ARC_CoverageInvoicedThrough__c.addDays(1), refreshedContract.ARC_NextInvoiceCoverageStart__c,
            'The next invoice coverage start should remain aligned to one day after the new invoiced-through date.');
        System.assertEquals(expectedLastUnpaidInvoiceId, refreshedContract.ARC_LastUnpaidInvoice__c,
            'The contract should point to the first invoice whose coverage start falls after the paid-through date.');
    }

    private static Account getBaseAccount() {
        return [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'Missed Invoice Test Account'
            LIMIT 1
        ];
    }

    private static Contract getContractById(Id contractId) {
        return [
            SELECT Id, AccountId, Status, ARC_EffectiveDate__c, ARC_PaymentFrequency__c,
                   ARC_CoverageInvoicedThrough__c, ARC_CoveragePaidThrough__c,
                   ARC_NextInvoiceCoverageStart__c, ARC_LastUnpaidInvoice__c
            FROM Contract
            WHERE Id = :contractId
            LIMIT 1
        ];
    }

    private static List<ARC_Invoice__c> getInvoicesForContract(Id contractId) {
        return [
            SELECT Id, ARC_Contract__c, ARC_CoverageDateFrom__c, ARC_CoverageDateTo__c,
                   ARC_DueDate__c, ARC_AmountDue__c
            FROM ARC_Invoice__c
            WHERE ARC_Contract__c = :contractId
            ORDER BY ARC_CoverageDateFrom__c ASC
        ];
    }

    private static Contract createContract(
        Id accountId,
        String status,
        Date effectiveDate,
        Date coverageInvoicedThrough,
        Date coveragePaidThrough,
        String paymentFrequency
    ) {
        return new Contract(
            AccountId = accountId,
            Status = status,
            StartDate = BASE_EFFECTIVE_DATE,
            ContractTerm = 12,
            ARC_EffectiveDate__c = effectiveDate,
            ARC_CoverageInvoicedThrough__c = coverageInvoicedThrough,
            ARC_CoveragePaidThrough__c = coveragePaidThrough,
            ARC_PaymentFrequency__c = paymentFrequency
        );
    }
}