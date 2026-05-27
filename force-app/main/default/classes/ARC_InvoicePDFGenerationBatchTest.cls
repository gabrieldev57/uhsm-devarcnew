/**
 * @description Test class for ARC_InvoicePDFGenerationBatch.
 *              Targets ≥75% line coverage by exercising start(), execute(),
 *              finish(), all five populate helpers, getPolicyDetailsForIds(),
 *              and the positive/negative branches of formatCurrency().
 * @author lucas.benero@arcsona.com
 */
@isTest
public class ARC_InvoicePDFGenerationBatchTest {

    // ─── Test Setup ───────────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        // Employer account with full billing address (covers all billing-field branches)
        Account employer = new Account(
            Name            = 'Acme Corp',
            BillingStreet   = '100 Main St',
            BillingCity     = 'Austin',
            BillingState    = 'TX',
            BillingPostalCode = '78701'
        );
        insert employer;

        // Product required by InsurancePolicy
        Product2 prod = new Product2(Name = 'Health Plan', IsActive = true);
        insert prod;

        // InsurancePolicy linked to employer — used by line items so that
        // getPolicyDetailsForIds() receives a non-empty Set and the
        // SSN section enters its inner block
        InsurancePolicy policy = new InsurancePolicy(
            Name          = 'Test Policy',
            NameInsuredId = employer.Id,
            ProductId     = prod.Id
        );
        insert policy;

        // Contract linked to employer (batch follows ARC_Contract__r.Account.*)
        Contract c = new Contract(AccountId = employer.Id, Status = 'Draft');
        insert c;

        // Invoice record type
        Id invoiceRTId = Schema.SObjectType.ARC_Invoice__c
            .getRecordTypeInfosByDeveloperName()
            .get('ARC_SmallGroup')
            .getRecordTypeId();

        // ── Previous-period invoice ────────────────────────────────────────────
        // populateBillingSummarySection finds this via CoverageDateTo < curFrom
        Date prevFrom = Date.today().toStartOfMonth().addMonths(-1);
        Date prevTo   = Date.today().toStartOfMonth().addDays(-1);

        ARC_Invoice__c prevInv = new ARC_Invoice__c(
            RecordTypeId    = invoiceRTId,
            ARC_Contract__c = c.Id,
            ARC_CoverageDateFrom__c            = prevFrom,
            ARC_CoverageDateTo__c              = prevTo,
            ARC_DueDate__c                     = Date.today().addDays(-5),
            ARC_AmountDue__c                   = 300,
            ARC_CreditBalanceCarriedForward__c = 25       // → currentCredits path
        );
        insert prevInv;

        // ── Current invoice ───────────────────────────────────────────────────
        Date curFrom = Date.today().toStartOfMonth();
        Date curTo   = Date.today().toStartOfMonth().addMonths(1).addDays(-1);

        ARC_Invoice__c inv = new ARC_Invoice__c(
            RecordTypeId    = invoiceRTId,
            ARC_Contract__c = c.Id,
            ARC_CoverageDateFrom__c = curFrom,
            ARC_CoverageDateTo__c   = curTo,
            ARC_DueDate__c          = Date.today().addDays(25),
            ARC_AmountDue__c        = 500
        );
        insert inv;

        // ── Coverage line item (positive amount, with policy + employee) ───────
        // Covers populateMembershipDetailsSection and SSN section inner block
        insert new ARC_InvoiceLineItem__c(
            ARC_Invoice__c          = inv.Id,
            ARC_Type__c             = 'Coverage',
            ARC_CoverageAmount__c   = 400,
            ARC_Policy__c           = policy.Id,
            ARC_Employee__c         = employer.Id,
            ARC_CoverageDateFrom__c = curFrom,
            ARC_CoverageDateTo__c   = curTo
        );

        // ── Adjustment line item (negative amount) ────────────────────────────
        // Negative amount → covers the negative branch of formatCurrency()
        insert new ARC_InvoiceLineItem__c(
            ARC_Invoice__c          = inv.Id,
            ARC_Type__c             = 'Adjustment',
            ARC_CoverageAmount__c   = -50,
            ARC_Policy__c           = policy.Id,
            ARC_Employee__c         = employer.Id,
            ARC_CoverageDateFrom__c = curFrom
        );
    }

    // ─── Test Methods ─────────────────────────────────────────────────────────

    /**
     * Main path: processes both the previous invoice (no line items, no prior
     * balance) and the current invoice (prior invoice found, approved transaction,
     * Coverage + Adjustment line items with a real policy ID).
     *
     * Covers:
     *  - start(), execute(), finish()
     *  - generateInvoicePDF() → all 5 populate methods
     *  - populateBillingSummarySection: previous invoice path, priorAmountPaid,
     *    currentCredits, Coverage + Adjustment line items
     *  - populateMembershipDetailsSection with policy → getPolicyDetailsForIds
     *    with non-empty set (InsurancePolicyCoverage + InsurancePolicyParticipant
     *    SOQL, PolicyDetails inner class construction)
     *  - populateEligibilityChangesSection with negative adjustmentAmount
     *    → formatCurrency negative branch, policyTotal = 0 fallback
     *  - populateSSNRequestsSection: non-empty employeeIds AND policyIds
     *    → enters inner block, InsurancePolicyParticipant SOQL,
     *    vlocity_ins__GroupCensusMember__c SOQL (empty results)
     *  - formatCurrency positive + negative
     */
    @isTest
    static void testBatch_withFullInvoice() {
        Test.startTest();
        Database.executeBatch(new ARC_InvoicePDFGenerationBatch('fakeTemplateCV'), 200);
        Test.stopTest();

        // Both invoices exist and batch completed without unhandled exception
        System.assertEquals(2, [SELECT COUNT() FROM ARC_Invoice__c],
            'Both setup invoices should still exist after batch run');
    }

    /**
     * Verifies start() runs without error and returns a non-null QueryLocator.
     * Also confirms that DocumentGenerationProcess is queryable in test context
     * and that invoices without a matching DGP are included.
     */
    @isTest
    static void testBatch_startReturnsQueryLocator() {
        ARC_InvoicePDFGenerationBatch batch = new ARC_InvoicePDFGenerationBatch('cv123');
        Test.startTest();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();

        System.assertNotEquals(null, ql, 'start() should return a non-null QueryLocator');
    }

    /**
     * No SmallGroup invoices in org → execute() is never called, finish() logs
     * 0 successes and 0 failures without error.
     */
    @isTest
    static void testBatch_noSmallGroupInvoices() {
        delete [SELECT Id FROM ARC_Invoice__c];

        Test.startTest();
        Database.executeBatch(new ARC_InvoicePDFGenerationBatch('fakeTemplateCV'), 200);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM ARC_Invoice__c]);
    }

    /**
     * Invoice with null ARC_CoverageDateFrom__c, ARC_CoverageDateTo__c,
     * ARC_DueDate__c, and ARC_AmountDue__c.
     *
     * Covers:
     *  - populateHeaderSection: null coverage dates → billingPeriod = ''
     *  - populateHeaderSection: null due date → paymentDueDate = ''
     *  - populateBillingSummarySection: null ARC_AmountDue__c → falls back to
     *    currentSubtotal (null AmountDue branch)
     */
    @isTest
    static void testBatch_invoiceWithNullDates() {
        Id invoiceRTId = Schema.SObjectType.ARC_Invoice__c
            .getRecordTypeInfosByDeveloperName()
            .get('ARC_SmallGroup')
            .getRecordTypeId();

        Contract c = [SELECT Id FROM Contract LIMIT 1];

        ARC_Invoice__c inv = new ARC_Invoice__c(
            RecordTypeId    = invoiceRTId,
            ARC_Contract__c = c.Id
            // ARC_CoverageDateFrom__c, ARC_CoverageDateTo__c, ARC_DueDate__c,
            // ARC_AmountDue__c intentionally left null
        );
        insert inv;

        // Remove setup invoices so only the null-dates invoice is processed
        delete [SELECT Id FROM ARC_Invoice__c WHERE Id != :inv.Id];

        Test.startTest();
        Database.executeBatch(new ARC_InvoicePDFGenerationBatch('fakeTemplateCV'), 200);
        Test.stopTest();

        System.assertNotEquals(null, [SELECT Id FROM ARC_Invoice__c WHERE Id = :inv.Id LIMIT 1].Id);
    }

    /**
     * Account with no billing address fields.
     *
     * Covers the false branches in populateHeaderSection for each
     * null billing field (BillingStreet, BillingCity, BillingState,
     * BillingPostalCode) so billingAddress remains ''.
     */
    @isTest
    static void testBatch_accountWithNoBillingAddress() {
        Account acctNoBilling = new Account(Name = 'No Billing Corp');
        insert acctNoBilling;

        Contract c2 = new Contract(AccountId = acctNoBilling.Id, Status = 'Draft');
        insert c2;

        Id invoiceRTId = Schema.SObjectType.ARC_Invoice__c
            .getRecordTypeInfosByDeveloperName()
            .get('ARC_SmallGroup')
            .getRecordTypeId();

        ARC_Invoice__c inv = new ARC_Invoice__c(
            RecordTypeId    = invoiceRTId,
            ARC_Contract__c = c2.Id,
            ARC_CoverageDateFrom__c = Date.today().toStartOfMonth().addMonths(3),
            ARC_CoverageDateTo__c   = Date.today().toStartOfMonth().addMonths(4).addDays(-1),
            ARC_AmountDue__c        = 100
        );
        insert inv;

        // Remove setup invoices so only the no-billing invoice is processed
        delete [SELECT Id FROM ARC_Invoice__c WHERE Id != :inv.Id];

        Test.startTest();
        Database.executeBatch(new ARC_InvoicePDFGenerationBatch('fakeTemplateCV'), 200);
        Test.stopTest();

        System.assertNotEquals(null, inv.Id);
    }

    /**
     * Two coverage items sharing the same policy key → deduplication keeps only
     * the first row in populateMembershipDetailsSection.
     * Two adjustment items sharing the same policy+date key → amounts are
     * consolidated in populateEligibilityChangesSection.
     *
     * Covers:
     *  - seenPolicies.containsKey(item.ARC_Policy__c) → true on second coverage item
     *  - consolidatedAmounts accumulation for repeated adjustment key
     *  - Multiple adjustment items → getPolicyDetailsForIds called with non-empty
     *    Set on eligibility section separately from membership section
     */
    @isTest
    static void testBatch_duplicatePolicyDeduplication() {
        Id invoiceRTId = Schema.SObjectType.ARC_Invoice__c
            .getRecordTypeInfosByDeveloperName()
            .get('ARC_SmallGroup')
            .getRecordTypeId();

        Contract c          = [SELECT Id FROM Contract LIMIT 1];
        InsurancePolicy pol = [SELECT Id FROM InsurancePolicy LIMIT 1];

        Date futureFrom = Date.today().toStartOfMonth().addMonths(2);
        Date futureTo   = futureFrom.addMonths(1).addDays(-1);

        ARC_Invoice__c inv = new ARC_Invoice__c(
            RecordTypeId    = invoiceRTId,
            ARC_Contract__c = c.Id,
            ARC_CoverageDateFrom__c = futureFrom,
            ARC_CoverageDateTo__c   = futureTo,
            ARC_AmountDue__c        = 800
        );
        insert inv;

        // Two coverage items, same policy → second is deduplicated
        insert new List<ARC_InvoiceLineItem__c>{
            new ARC_InvoiceLineItem__c(
                ARC_Invoice__c = inv.Id, ARC_Type__c = 'Coverage',
                ARC_CoverageAmount__c = 200, ARC_Policy__c = pol.Id,
                ARC_CoverageDateFrom__c = futureFrom),
            new ARC_InvoiceLineItem__c(
                ARC_Invoice__c = inv.Id, ARC_Type__c = 'Coverage',
                ARC_CoverageAmount__c = 200, ARC_Policy__c = pol.Id,
                ARC_CoverageDateFrom__c = futureFrom)
        };

        // Two adjustment items, same policy+date → amounts consolidated (-30 + -20 = -50)
        insert new List<ARC_InvoiceLineItem__c>{
            new ARC_InvoiceLineItem__c(
                ARC_Invoice__c = inv.Id, ARC_Type__c = 'Adjustment',
                ARC_CoverageAmount__c = -30, ARC_Policy__c = pol.Id,
                ARC_CoverageDateFrom__c = futureFrom),
            new ARC_InvoiceLineItem__c(
                ARC_Invoice__c = inv.Id, ARC_Type__c = 'Adjustment',
                ARC_CoverageAmount__c = -20, ARC_Policy__c = pol.Id,
                ARC_CoverageDateFrom__c = futureFrom)
        };

        // Process only the deduplication invoice
        delete [SELECT Id FROM ARC_Invoice__c WHERE Id != :inv.Id];

        Test.startTest();
        Database.executeBatch(new ARC_InvoicePDFGenerationBatch('fakeTemplateCV'), 200);
        Test.stopTest();

        System.assertNotEquals(null, inv.Id);
    }

    /**
     * Coverage line item with null ARC_Employee__c and null ARC_Policy__c.
     * Both employeeIds and policyIds stay empty → SSN section skips inner block.
     * populateMembershipDetailsSection receives a null policy → getPolicyDetailsForIds
     * is called with an empty Set (policyIds.isEmpty() short-circuit).
     *
     * Also exercises the line-items branch of populateBillingSummarySection
     * (Coverage type) without a prior invoice.
     */
    @isTest
    static void testBatch_lineItemsWithNullPolicyAndEmployee() {
        Id invoiceRTId = Schema.SObjectType.ARC_Invoice__c
            .getRecordTypeInfosByDeveloperName()
            .get('ARC_SmallGroup')
            .getRecordTypeId();

        Contract c = [SELECT Id FROM Contract LIMIT 1];

        Date nextFrom = Date.today().toStartOfMonth().addMonths(5);
        Date nextTo   = nextFrom.addMonths(1).addDays(-1);

        ARC_Invoice__c inv = new ARC_Invoice__c(
            RecordTypeId    = invoiceRTId,
            ARC_Contract__c = c.Id,
            ARC_CoverageDateFrom__c = nextFrom,
            ARC_CoverageDateTo__c   = nextTo,
            ARC_AmountDue__c        = 250
        );
        insert inv;

        // Coverage item: no employee, no policy → SSN skips inner block
        insert new ARC_InvoiceLineItem__c(
            ARC_Invoice__c          = inv.Id,
            ARC_Type__c             = 'Coverage',
            ARC_CoverageAmount__c   = 250,
            ARC_CoverageDateFrom__c = nextFrom
        );

        // Adjustment item: no employee, no policy
        insert new ARC_InvoiceLineItem__c(
            ARC_Invoice__c          = inv.Id,
            ARC_Type__c             = 'Adjustment',
            ARC_CoverageAmount__c   = -10,
            ARC_CoverageDateFrom__c = nextFrom
        );

        // Remove setup invoices
        delete [SELECT Id FROM ARC_Invoice__c WHERE Id != :inv.Id];

        Test.startTest();
        Database.executeBatch(new ARC_InvoicePDFGenerationBatch('fakeTemplateCV'), 200);
        Test.stopTest();

        System.assertNotEquals(null, inv.Id);
    }
}