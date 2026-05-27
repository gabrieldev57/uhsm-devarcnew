/**
 * @description Controller for the Generate Missed Invoices button on Contract.
 *              Identifies and creates all past-due invoices not yet generated,
 *              from the Effective Date up to today, applying open adjustments
 *              to the first generated invoice.
 * @author lucas.benero@arcsona.com
 */
public with sharing class ARC_MissedInvoiceController {

    /**
     * @description Entry point called from the LWC button.
     * @param contractId The Contract record Id
     * @return Result message to display in the UI
     */
    @AuraEnabled
    public static String generateMissedInvoices(Id contractId) {
        // Query contract with all needed fields
        Contract contract = [
            SELECT Id, Status, ARC_EffectiveDate__c, ARC_PaymentFrequency__c,
                   ARC_CoverageInvoicedThrough__c, ARC_NextInvoiceCoverageStart__c,
                   ARC_CoveragePaidThrough__c, ARC_LastUnpaidInvoice__c,
                   ARC_RecurringMonthlyOrder__c,
                   ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Date__c,
                   ARC_RecurringMonthlyOrder__r.ChargentOrders__Payment_Start_Date__c
            FROM Contract
            WHERE Id = :contractId
            LIMIT 1
        ];

        if (contract.Status != 'Activated' && contract.Status != 'Awaiting First Payment' && contract.Status != 'Awaiting Activation') {
            throw new AuraHandledException(
                'Missed invoices can only be generated when the contract is in Activated or Awaiting First Payment status.'
            );
        }

        if (contract.ARC_EffectiveDate__c == null) {
            throw new AuraHandledException(
                'Cannot generate missed invoices: the contract has no Effective Date.'
            );
        }

        // Determine the start of the first missing period
        Date nextCoverageStart;
        if (contract.ARC_CoverageInvoicedThrough__c != null) {
            nextCoverageStart = contract.ARC_CoverageInvoicedThrough__c.addDays(1);
        } else {
            nextCoverageStart = contract.ARC_EffectiveDate__c;
        }

        // Build list of all missing periods up to (but not including) the current month
        // "Missed" = periods whose coverage start is before today
        List<Date[]> missingPeriods = new List<Date[]>();
        Date periodStart = nextCoverageStart;
        Date generateUpTo = Date.today().toStartOfMonth().addMonths(1);

        while (periodStart <= generateUpTo) {
            Date periodEnd = ARC_InvoiceGenerationBatch.calculateCoverageTo(periodStart, contract.ARC_PaymentFrequency__c);
            missingPeriods.add(new Date[]{ periodStart, periodEnd });
            periodStart = periodEnd.addDays(1);
        }

        if (missingPeriods.isEmpty()) {
            return 'There are no missed invoices to generate for this contract.';
        }

        // Create invoice records for each missing period
        Id invoiceRecordTypeId = Schema.SObjectType.ARC_Invoice__c
            .getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();

        List<ARC_Invoice__c> invoicesToInsert = new List<ARC_Invoice__c>();

        for (Date[] period : missingPeriods) {

            ARC_Invoice__c invoice = new ARC_Invoice__c(
                RecordTypeId = invoiceRecordTypeId,
                ARC_Contract__c = contractId,
                ARC_CoverageDateFrom__c = period[0],
                ARC_CoverageDateTo__c = period[1],
                ARC_DueDate__c = period[0], // due date = coverage start for missed invoices
                ARC_CreditsBroughtForward__c = 0,
                ARC_CreditAppliedThisInvoice__c = 0,
                ARC_CreditBalanceCarriedForward__c = 0
            );
            invoicesToInsert.add(invoice);
        }

        insert invoicesToInsert;

        // Process line items and credits one invoice at a time (sequential so credit carry-forward is correct)
        for (ARC_Invoice__c invoice : invoicesToInsert) {
            ARC_InvoiceGenerationBatch.createInvoiceLineItems(
                new Map<Id, ARC_Invoice__c>{ contractId => invoice }
            );
        }

        ARC_Invoice__c lastInvoice = invoicesToInsert[invoicesToInsert.size() - 1];

        Contract contractUpdate = new Contract(
            Id = contractId,
            ARC_CoverageInvoicedThrough__c = lastInvoice.ARC_CoverageDateTo__c,
            ARC_NextInvoiceCoverageStart__c = lastInvoice.ARC_CoverageDateTo__c.addDays(1)
        );

        // Set LastUnpaidInvoice to the first invoice after CoveragePaidThrough
        Date paidThrough = contract.ARC_CoveragePaidThrough__c;
        for (ARC_Invoice__c inv : invoicesToInsert) {
            if (paidThrough == null || inv.ARC_CoverageDateFrom__c > paidThrough) {
                contractUpdate.ARC_LastUnpaidInvoice__c = inv.Id;
                break;
            }
        }

        update contractUpdate;

        // Update Chargent Order amount to the first unpaid invoice amount
        if (contract.ARC_RecurringMonthlyOrder__c != null && contractUpdate.ARC_LastUnpaidInvoice__c != null) {
            // Re-query to get the calculated AmountDue after line items were created
            ARC_Invoice__c unpaidInvoice = [
                SELECT ARC_AmountDue__c FROM ARC_Invoice__c
                WHERE Id = :contractUpdate.ARC_LastUnpaidInvoice__c LIMIT 1
            ];
            Decimal amountDue = unpaidInvoice.ARC_AmountDue__c != null ? unpaidInvoice.ARC_AmountDue__c : 0;
            update new ChargentOrders__ChargentOrder__c(
                Id = contract.ARC_RecurringMonthlyOrder__c,
                ChargentOrders__Subtotal__c = amountDue,
                ChargentOrders__Charge_Amount__c = amountDue
            );
        }

        Integer count = invoicesToInsert.size();

        // Trigger PDF generation for the newly created invoices
        List<vlocity_ins__DocumentTemplate__c> templates = [
            SELECT vlocity_ins__TemplateContentVersionId__c
            FROM vlocity_ins__DocumentTemplate__c
            WHERE Name = 'Small Group Invoice'
            LIMIT 1
        ];
        if (!templates.isEmpty() && templates[0].vlocity_ins__TemplateContentVersionId__c != null) {
            Database.executeBatch(
                new ARC_InvoicePDFGenerationBatch(templates[0].vlocity_ins__TemplateContentVersionId__c),
                10
            );
        }

        return count + ' missed invoice' + (count > 1 ? 's were' : ' was') + ' successfully generated.';
    }
}