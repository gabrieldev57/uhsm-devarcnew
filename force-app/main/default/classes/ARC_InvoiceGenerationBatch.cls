/**
 * @description Batch process that generates invoices for Small Group contracts:
 *              - Regular invoices on the 1st of each month for Active contracts
 *              - First invoices one day after Open Enrollment ends
 * @author lucas.benero@arcsona.com
 * @date 2026-02-09
 */
global class ARC_InvoiceGenerationBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query Small Group contracts eligible for invoice generation
        // Includes both: Active contracts (monthly) and Enrollment In Progress (first invoice)
        Date yesterday = Date.today().addDays(-1);
        
        Date today = Date.today();

        String query = 'SELECT Id, Status, ARC_NextInvoiceCoverageStart__c, ARC_PaymentFrequency__c, ' +
                      'ARC_OEEndDate__c, ARC_RecurringMonthlyOrder__c, ARC_EffectiveDate__c, ' +
                      'ARC_CoveragePaidThrough__c, ' +
                      'ARC_RecurringMonthlyOrder__r.ChargentOrders__Payment_Start_Date__c, ' +
                      'ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Date__c ' +
                      'FROM Contract ' +
                      'WHERE RecordType.DeveloperName = \'ARC_SmallGroup\' ' +
                      'AND (' +
                          '(Status IN (\'Activated\', \'Awaiting First Payment\') ) OR ' +//AND ARC_NextInvoiceCoverageStart__c <= :today
                          '(Status = \'Enrollment In Progress\' AND ARC_OEEndDate__c = :yesterday)' +
                      ')';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Contract> contracts) {
        // Separate contracts by invoice type
        List<Contract> firstInvoiceContracts = new List<Contract>();
        List<Contract> regularInvoiceContracts = new List<Contract>();
        Date yesterday = Date.today().addDays(-1);
        Date today = Date.today();
        
        for (Contract contract : contracts) {
            if (contract.Status == 'Enrollment In Progress' && contract.ARC_OEEndDate__c == yesterday) {
                firstInvoiceContracts.add(contract);
            } else if (
                (contract.Status == 'Activated' || contract.Status == 'Awaiting First Payment') &&
                // contract.ARC_NextInvoiceCoverageStart__c != null &&
                // contract.ARC_NextInvoiceCoverageStart__c <= today &&
                Date.today().day() == 1
            ) {
                regularInvoiceContracts.add(contract);
            }
        }
        
        // Process first invoices
        if (!firstInvoiceContracts.isEmpty()) {
            processFirstInvoices(firstInvoiceContracts);
        }
        
        // Process regular monthly invoices (only on 1st of month)
        if (!regularInvoiceContracts.isEmpty()) {
            processRegularInvoices(regularInvoiceContracts);
        }
    }
    
    /**
     * @description Process first invoices for contracts that just completed Open Enrollment
     */
    private void processFirstInvoices(List<Contract> contracts) {
        List<ARC_Invoice__c> invoicesToInsert = new List<ARC_Invoice__c>();
        Map<Id, ARC_Invoice__c> contractToInvoiceMap = new Map<Id, ARC_Invoice__c>();
        
        // Step 1: Check for existing invoices to avoid duplicates
        Map<Id, Date> contractCoverageFromMap = new Map<Id, Date>();
        Map<Id, Date> contractCoverageToMap = new Map<Id, Date>();
        
        for (Contract contract : contracts) {
            Date coverageFrom = contract.ARC_EffectiveDate__c;
            if (coverageFrom == null) {
                continue; // Skip contracts without effective date
            }
            Date coverageTo = calculateCoverageTo(coverageFrom, contract.ARC_PaymentFrequency__c);
            if (coverageTo == null) {
                continue; // Skip if coverage calculation failed
            }
            contractCoverageFromMap.put(contract.Id, coverageFrom);
            contractCoverageToMap.put(contract.Id, coverageTo);
        }
        
        if (contractCoverageFromMap.isEmpty()) {
            return; // No valid contracts to process
        }
        
        Set<Id> contractsWithExistingInvoice = checkForExistingInvoices(contractCoverageFromMap, contractCoverageToMap);
        
        // Step 2: Create first Invoices
        for (Contract contract : contracts) {
            if (contractsWithExistingInvoice.contains(contract.Id)) {
                continue;
            }
            
            Date coverageFrom = contractCoverageFromMap.get(contract.Id);
            Date coverageTo = contractCoverageToMap.get(contract.Id);
            
            if (coverageFrom == null || coverageTo == null) {
                continue; // Skip if dates are invalid
            }
            
            Id invoiceRecordTypeId = Schema.SObjectType.ARC_Invoice__c.getRecordTypeInfosByDeveloperName()
                .get('ARC_SmallGroup').getRecordTypeId();
            
            // Calculate Due Date for first invoice (use Payment Start Date)
            Date dueDate = Date.today().addDays(1); // Default fallback
            if (contract.ARC_RecurringMonthlyOrder__c != null && 
                contract.ARC_RecurringMonthlyOrder__r != null &&
                contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Payment_Start_Date__c != null) {
                dueDate = contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Payment_Start_Date__c;
            }
            
            ARC_Invoice__c invoice = new ARC_Invoice__c(
                RecordTypeId = invoiceRecordTypeId,
                ARC_Contract__c = contract.Id,
                ARC_CoverageDateFrom__c = coverageFrom,
                ARC_CoverageDateTo__c = coverageTo,
                ARC_DueDate__c = dueDate,
                ARC_CreditsBroughtForward__c = 0,
                ARC_CreditAppliedThisInvoice__c = 0,
                ARC_CreditBalanceCarriedForward__c = 0
            );
            
            invoicesToInsert.add(invoice);
            contractToInvoiceMap.put(contract.Id, invoice);
        }
        
        if (invoicesToInsert.isEmpty()) {
            return;
        }
        
        insert invoicesToInsert;
        
        // Step 3: Create Invoice Line Items (shared logic)
        createInvoiceLineItems(contractToInvoiceMap);
        
        // Step 4: Update Contract Status, Billing State, and Chargent Order
        List<Contract> contractsToUpdate = new List<Contract>();
        List<ChargentOrders__ChargentOrder__c> ordersToUpdate = new List<ChargentOrders__ChargentOrder__c>();
        
        for (Contract contract : contracts) {
            if (!contractToInvoiceMap.containsKey(contract.Id)) {
                continue;
            }
            
            ARC_Invoice__c invoice = contractToInvoiceMap.get(contract.Id);
            
            if (invoice == null || invoice.ARC_CoverageDateTo__c == null) {
                continue; // Skip if invoice or date is invalid
            }
            
            // Update Contract Status, Billing State, Last Unpaid Invoice, and Open Credit Balance
            contractsToUpdate.add(new Contract(
                Id = contract.Id,
                Status = 'Awaiting First Payment',
                ARC_CoverageInvoicedThrough__c = invoice.ARC_CoverageDateTo__c,
                ARC_NextInvoiceCoverageStart__c = invoice.ARC_CoverageDateTo__c.addDays(1),
                ARC_LastUnpaidInvoice__c = invoice.Id,
                ARC_OpenCreditBalance__c = invoice.ARC_CreditBalanceCarriedForward__c != null ? invoice.ARC_CreditBalanceCarriedForward__c : 0,
                ARC_NextToBeBilledAmount__c = invoice.ARC_AmountDue__c != null ? invoice.ARC_AmountDue__c : 0
            ));
            
            // Update Chargent Order with payment start date and charge amounts
            if (contract.ARC_RecurringMonthlyOrder__c != null) {
                Decimal amountDue = invoice.ARC_AmountDue__c != null ? invoice.ARC_AmountDue__c : 0;
                ordersToUpdate.add(new ChargentOrders__ChargentOrder__c(
                    Id = contract.ARC_RecurringMonthlyOrder__c,
                    ChargentOrders__Payment_Frequency__c = 'Monthly',
                    ChargentOrders__Payment_Status__c = 'Recurring',
                    ChargentOrders__Payment_Stop__c = 'Unending',
                    ChargentOrders__Payment_Start_Date__c = Date.today().addDays(1),
                    ChargentOrders__Subtotal__c = amountDue,
                    ChargentOrders__Charge_Amount__c = amountDue
                ));
            }
        }
        
        if (!contractsToUpdate.isEmpty()) {
            update contractsToUpdate;
        }
        
        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }
    
    /**
     * @description Process regular monthly invoices for active contracts
     */
    @TestVisible private void processRegularInvoices(List<Contract> contracts) {
        List<ARC_Invoice__c> invoicesToInsert = new List<ARC_Invoice__c>();
        Map<Id, ARC_Invoice__c> contractToInvoiceMap = new Map<Id, ARC_Invoice__c>();
        
        // Step 1: Check for existing invoices to avoid duplicates
        Map<Id, Date> contractCoverageFromMap = new Map<Id, Date>();
        Map<Id, Date> contractCoverageToMap = new Map<Id, Date>();
        
        for (Contract contract : contracts) {
            Date coverageFrom = contract.ARC_NextInvoiceCoverageStart__c;
            if (coverageFrom == null) {
                continue; // Skip contracts without next invoice coverage start
            }
            Date coverageTo = calculateCoverageTo(coverageFrom, contract.ARC_PaymentFrequency__c);
            if (coverageTo == null) {
                continue; // Skip if coverage calculation failed
            }
            contractCoverageFromMap.put(contract.Id, coverageFrom);
            contractCoverageToMap.put(contract.Id, coverageTo);
        }
        
        if (contractCoverageFromMap.isEmpty()) {
            return; // No valid contracts to process
        }
        
        Set<Id> contractsWithExistingInvoice = checkForExistingInvoices(contractCoverageFromMap, contractCoverageToMap);
        
        // Step 2: Create monthly Invoices
        for (Contract contract : contracts) {
            if (contractsWithExistingInvoice.contains(contract.Id)) {
                continue;
            }
            
            Date coverageFrom = contractCoverageFromMap.get(contract.Id);
            Date coverageTo = contractCoverageToMap.get(contract.Id);
            
            if (coverageFrom == null || coverageTo == null) {
                continue; // Skip if dates are invalid
            }
            
            // Calculate Due Date for regular invoice (month prior to Coverage Date From + Charge Date day)
            Date dueDate = calculateRegularInvoiceDueDate(
                coverageFrom,
                contract.ARC_RecurringMonthlyOrder__c,
                contract.ARC_RecurringMonthlyOrder__r
            );
            
            ARC_Invoice__c invoice = new ARC_Invoice__c(
                ARC_Contract__c = contract.Id,
                ARC_CoverageDateFrom__c = coverageFrom,
                ARC_CoverageDateTo__c = coverageTo,
                ARC_DueDate__c = dueDate,
                ARC_CreditsBroughtForward__c = 0,
                ARC_CreditAppliedThisInvoice__c = 0,
                ARC_CreditBalanceCarriedForward__c = 0
            );
            
            invoicesToInsert.add(invoice);
            contractToInvoiceMap.put(contract.Id, invoice);
        }
        
        if (invoicesToInsert.isEmpty()) {
            return;
        }
        
        insert invoicesToInsert;
        
        // Step 3: Create Invoice Line Items (shared logic)
        createInvoiceLineItems(contractToInvoiceMap);
        
        // Step 4: Update Contract Billing State and Chargent Order for next pending invoices
        List<Contract> contractsToUpdate = new List<Contract>();
        List<ChargentOrders__ChargentOrder__c> ordersToUpdate = new List<ChargentOrders__ChargentOrder__c>();
        
        for (Contract contract : contracts) {
            if (!contractToInvoiceMap.containsKey(contract.Id)) {
                continue;
            }
            
            ARC_Invoice__c invoice = contractToInvoiceMap.get(contract.Id);
            
            if (invoice == null || invoice.ARC_CoverageDateTo__c == null) {
                continue; // Skip if invoice or date is invalid
            }
            
            // Check if this invoice is the next pending payment period
            Boolean isNextPendingInvoice = false;
            if (contract.ARC_CoveragePaidThrough__c != null) {
                // Next pending period starts the day after ARC_CoveragePaidThrough__c
                Date nextPeriodStart = contract.ARC_CoveragePaidThrough__c.addDays(1);
                isNextPendingInvoice = (invoice.ARC_CoverageDateFrom__c == nextPeriodStart);
            } else if (contract.ARC_CoveragePaidThrough__c == null && contract.ARC_EffectiveDate__c != null) {
                // If no payment yet, check if invoice starts at effective date
                isNextPendingInvoice = (invoice.ARC_CoverageDateFrom__c == contract.ARC_EffectiveDate__c);
            }
            
            // Update Contract
            Contract contractUpdate = new Contract(
                Id = contract.Id,
                ARC_CoverageInvoicedThrough__c = invoice.ARC_CoverageDateTo__c,
                ARC_NextInvoiceCoverageStart__c = invoice.ARC_CoverageDateTo__c.addDays(1),
                ARC_OpenCreditBalance__c = invoice.ARC_CreditBalanceCarriedForward__c != null ? invoice.ARC_CreditBalanceCarriedForward__c : 0
            );
            
            // If this is the next pending invoice, update ARC_LastUnpaidInvoice__c
            if (isNextPendingInvoice) {
                contractUpdate.ARC_LastUnpaidInvoice__c = invoice.Id;
                contractUpdate.ARC_NextToBeBilledAmount__c = invoice.ARC_AmountDue__c != null ? invoice.ARC_AmountDue__c : 0;
            }
            
            contractsToUpdate.add(contractUpdate);
            
            // If this is the next pending invoice, update Chargent Order amounts
            if (isNextPendingInvoice && contract.ARC_RecurringMonthlyOrder__c != null) {
                Decimal amountDue = invoice.ARC_AmountDue__c != null ? invoice.ARC_AmountDue__c : 0;
            
                ChargentOrders__ChargentOrder__c orderToUpdate = new ChargentOrders__ChargentOrder__c(
                    Id = contract.ARC_RecurringMonthlyOrder__c,
                    ChargentOrders__Subtotal__c = amountDue,
                    ChargentOrders__Charge_Amount__c = amountDue
                );
            
                // If amount is 0, move Payment Start Date to next payment cycle
                if (amountDue == 0 && contract.ARC_CoveragePaidThrough__c != null) {
                    Integer yearVal = contract.ARC_CoveragePaidThrough__c.year();
                    Integer monthVal = contract.ARC_CoveragePaidThrough__c.month();
                    Integer dayVal = contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Date__c != null ? Integer.valueOf(contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Date__c) : 15;
            
                    orderToUpdate.ChargentOrders__Payment_Start_Date__c = Date.newInstance(yearVal, monthVal, dayVal);
                }
            
                ordersToUpdate.add(orderToUpdate);
            }
        }
        
        if (!contractsToUpdate.isEmpty()) {
            update contractsToUpdate;
        }
        
        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }
    
    /**
     * @description Check for existing invoices to avoid duplicate generation
     * @return Set of Contract Ids that already have an invoice for the coverage period
     */
    private Set<Id> checkForExistingInvoices(Map<Id, Date> contractCoverageFromMap, Map<Id, Date> contractCoverageToMap) {
        Set<Id> contractsWithExistingInvoice = new Set<Id>();
        
        if (contractCoverageFromMap.isEmpty()) {
            return contractsWithExistingInvoice; // Return empty set if no contracts to check
        }
        
        List<ARC_Invoice__c> existingInvoices = [
            SELECT Id, ARC_Contract__c, ARC_CoverageDateFrom__c, ARC_CoverageDateTo__c
            FROM ARC_Invoice__c
            WHERE ARC_Contract__c IN :contractCoverageFromMap.keySet()
        ];
        
        for (ARC_Invoice__c existing : existingInvoices) {
            Date expectedFrom = contractCoverageFromMap.get(existing.ARC_Contract__c);
            Date expectedTo = contractCoverageToMap.get(existing.ARC_Contract__c);
            
            // Check if invoice already exists for this exact period
            if (existing.ARC_CoverageDateFrom__c == expectedFrom && 
                existing.ARC_CoverageDateTo__c == expectedTo) {
                contractsWithExistingInvoice.add(existing.ARC_Contract__c);
            }
        }
        
        return contractsWithExistingInvoice;
    }
    
    /**
     * @description Create Invoice Line Items for policies and adjustments, apply credits
     */
    public static void createInvoiceLineItems(Map<Id, ARC_Invoice__c> contractToInvoiceMap) {
        List<ARC_InvoiceLineItem__c> lineItemsToInsert = new List<ARC_InvoiceLineItem__c>();
        
        // Query eligible Policies and create Coverage Invoice Line Items
        Map<Id, List<InsurancePolicy>> contractPoliciesMap = getEligiblePolicies(contractToInvoiceMap);

        // Collect all eligible policy Ids to query their plan-level coverages
        Set<Id> allPolicyIds = new Set<Id>();
        for (List<InsurancePolicy> pList : contractPoliciesMap.values()) {
            for (InsurancePolicy p : pList) {
                allPolicyIds.add(p.Id);
            }
        }

        // Build a map of policyId -> list of parent plan coverages (ARC_ParentPolicyCoverage__c = null)
        Map<Id, List<InsurancePolicyCoverage>> policyCoveragesMap = new Map<Id, List<InsurancePolicyCoverage>>();
        for (InsurancePolicyCoverage cov : [
            SELECT Id, InsurancePolicyId,
                   vlocity_ins_fsc__Product2Id__r.Name,
                   ARC_UnitPrice__c
            FROM InsurancePolicyCoverage
            WHERE InsurancePolicyId IN :allPolicyIds
              AND ARC_ParentPolicyCoverage__c = null
        ]) {
            if (!policyCoveragesMap.containsKey(cov.InsurancePolicyId)) {
                policyCoveragesMap.put(cov.InsurancePolicyId, new List<InsurancePolicyCoverage>());
            }
            policyCoveragesMap.get(cov.InsurancePolicyId).add(cov);
        }
        
        for (Id contractId : contractPoliciesMap.keySet()) {
            ARC_Invoice__c invoice = contractToInvoiceMap.get(contractId);
            List<InsurancePolicy> policies = contractPoliciesMap.get(contractId);
            
            if (invoice == null || policies.isEmpty()) {
                continue; // Skip if invoice is invalid or no policies
            }
            
            for (InsurancePolicy policy : policies) {
                String coverFrom = invoice.ARC_CoverageDateFrom__c != null ? invoice.ARC_CoverageDateFrom__c.format() : '';
                String coverTo = invoice.ARC_CoverageDateTo__c != null ? invoice.ARC_CoverageDateTo__c.format() : '';
                String policyNum = policy.Name != null ? policy.Name : '';
                List<InsurancePolicyCoverage> planCoverages = policyCoveragesMap.get(policy.Id);

                if (planCoverages != null && !planCoverages.isEmpty()) {
                    // One ILI per plan coverage — breakdown by plan for reporting
                    for (InsurancePolicyCoverage cov : planCoverages) {
                        String planName = cov.vlocity_ins_fsc__Product2Id__r != null
                            ? cov.vlocity_ins_fsc__Product2Id__r.Name
                            : 'Plan';
                        lineItemsToInsert.add(new ARC_InvoiceLineItem__c(
                            Name = 'Coverage - ' + coverFrom + '-' + coverTo + ' - Policy ' + policyNum,
                            ARC_Invoice__c = invoice.Id,
                            ARC_Type__c = 'Coverage',
                            ARC_Policy__c = policy.Id,
                            ARC_PolicyCoverage__c = cov.Id,
                            ARC_Employee__c = policy.NameInsuredId,
                            ARC_CoverageDateFrom__c = invoice.ARC_CoverageDateFrom__c,
                            ARC_CoverageDateTo__c = invoice.ARC_CoverageDateTo__c,
                            ARC_CoverageAmount__c = cov.ARC_UnitPrice__c != null ? cov.ARC_UnitPrice__c : 0
                        ));
                    }
                } else {
                    // Fallback: no plan coverages found — one ILI at policy total
                    lineItemsToInsert.add(new ARC_InvoiceLineItem__c(
                        Name = 'Coverage - ' + coverFrom + '-' + coverTo + ' - Policy ' + policyNum,
                        ARC_Invoice__c = invoice.Id,
                        ARC_Type__c = 'Coverage',
                        ARC_Policy__c = policy.Id,
                        ARC_Employee__c = policy.NameInsuredId,
                        ARC_CoverageDateFrom__c = invoice.ARC_CoverageDateFrom__c,
                        ARC_CoverageDateTo__c = invoice.ARC_CoverageDateTo__c,
                        ARC_CoverageAmount__c = policy.ARC_TotalPremiumAmount__c != null ? policy.ARC_TotalPremiumAmount__c : 0
                    ));
                }
            }
        }
        
        // Insert Coverage line items first
        if (!lineItemsToInsert.isEmpty()) {
            insert lineItemsToInsert;
        }
        
        // SECTION 1: Adjustment Presentation (One-Time Display)
        // Retrieve all Open Adjustments where Invoice is null and display them
        Map<Id, List<ARC_Adjustment__c>> contractAdjustmentsMap = getOpenAdjustments(contractToInvoiceMap.keySet());
        List<ARC_InvoiceLineItem__c> adjustmentLineItems = new List<ARC_InvoiceLineItem__c>();
        List<ARC_Adjustment__c> adjustmentsToLinkToInvoice = new List<ARC_Adjustment__c>();
        
        // Get policy info for adjustments
        Set<Id> adjPolicyIds = new Set<Id>();
        for (List<ARC_Adjustment__c> adjList : contractAdjustmentsMap.values()) {
            for (ARC_Adjustment__c adj : adjList) {
                if (adj.ARC_Policy__c != null) {
                    adjPolicyIds.add(adj.ARC_Policy__c);
                }
            }
        }
        Map<Id, InsurancePolicy> adjPolicyMap = new Map<Id, InsurancePolicy>(
            [SELECT Id, Name, NameInsuredId FROM InsurancePolicy WHERE Id IN :adjPolicyIds]
        );
        
        // Create line items for ALL adjustments with FULL amounts (one-time display)
        for (Id contractId : contractAdjustmentsMap.keySet()) {
            ARC_Invoice__c invoice = contractToInvoiceMap.get(contractId);
            List<ARC_Adjustment__c> adjustments = contractAdjustmentsMap.get(contractId);
            
            if (invoice == null || adjustments.isEmpty()) {
                continue;
            }
            
            for (ARC_Adjustment__c adj : adjustments) {
                // Only create line items for adjustments not yet linked to an invoice (one-time display)
                if (adj.ARC_Invoice__c == null) {
                    Date coverFrom = adj.ARC_CoverageDateFrom__c != null ? adj.ARC_CoverageDateFrom__c : invoice.ARC_CoverageDateFrom__c;
                    Date coverTo = adj.ARC_CoverageDateTo__c != null ? adj.ARC_CoverageDateTo__c : invoice.ARC_CoverageDateTo__c;
                    String coverFromStr = coverFrom != null ? coverFrom.format() : '';
                    String coverToStr = coverTo != null ? coverTo.format() : '';
                    String policyNum = '';
                    if (adj.ARC_Policy__c != null && adjPolicyMap.containsKey(adj.ARC_Policy__c)) {
                        policyNum = adjPolicyMap.get(adj.ARC_Policy__c).Name != null ? adjPolicyMap.get(adj.ARC_Policy__c).Name : '';
                    }
                    
                    // Create line item with FULL adjustment amount for display
                    ARC_InvoiceLineItem__c ili = new ARC_InvoiceLineItem__c(
                        Name = 'Adjustment - ' + coverFromStr + '-' + coverToStr + ' - Policy ' + policyNum,
                        ARC_Invoice__c = invoice.Id,
                        ARC_Type__c = 'Adjustment',
                        ARC_Adjustment__c = adj.Id,
                        ARC_Policy__c = adj.ARC_Policy__c,
                        ARC_PolicyCoverage__c = adj.ARC_PolicyCoverage__c,
                        ARC_CoverageDateFrom__c = coverFrom,
                        ARC_CoverageDateTo__c = coverTo,
                        ARC_Employee__c = adj.ARC_Policy__c != null && adjPolicyMap.containsKey(adj.ARC_Policy__c) ? adjPolicyMap.get(adj.ARC_Policy__c).NameInsuredId : null,
                        ARC_CoverageAmount__c = adj.ARC_Amount__c != null ? adj.ARC_Amount__c : 0
                    );
                    adjustmentLineItems.add(ili);
                    
                    // Link adjustment to invoice (ensures one-time display)
                    adjustmentsToLinkToInvoice.add(new ARC_Adjustment__c(
                        Id = adj.Id,
                        ARC_Invoice__c = invoice.Id
                    ));
                }
            }
        }
        
        if (!adjustmentLineItems.isEmpty()) {
            insert adjustmentLineItems;
        }
        
        if (!adjustmentsToLinkToInvoice.isEmpty()) {
            update adjustmentsToLinkToInvoice;
        }
        
        // SECTION 2 & 3: Credit & Charge Application + Adjustment State Updates
        // Calculate credit application and update adjustment status
        List<ARC_Adjustment__c> adjustmentsToUpdateStatus = new List<ARC_Adjustment__c>();
        
        for (Id contractId : contractToInvoiceMap.keySet()) {
            ARC_Invoice__c invoice = contractToInvoiceMap.get(contractId);
            List<ARC_Adjustment__c> adjustments = contractAdjustmentsMap.get(contractId);
            
            if (invoice == null) {
                continue;
            }
            
            // Apply credit calculation logic for this invoice
            applyCreditLogic(
                invoice,
                adjustments,
                adjustmentsToUpdateStatus
            );
        }
        
        if (!adjustmentsToUpdateStatus.isEmpty()) {
            update adjustmentsToUpdateStatus;
        }
        
        // Update invoices with calculated amounts
        List<ARC_Invoice__c> invoicesToUpdate = new List<ARC_Invoice__c>();
        for (ARC_Invoice__c invoice : contractToInvoiceMap.values()) {
            invoicesToUpdate.add(invoice);
        }
        
        if (!invoicesToUpdate.isEmpty()) {
            update invoicesToUpdate;
        }
    }
    
    /**
     * @description Calculate and apply credit logic according to user story specification
     * @param invoice The invoice being processed
     * @param allAdjustments All adjustments for this invoice (displayed on invoice)
     * @param adjustmentsToUpdate List to accumulate adjustments with updated status
     */
    public static void applyCreditLogic(
        ARC_Invoice__c invoice,
        List<ARC_Adjustment__c> allAdjustments,
        List<ARC_Adjustment__c> adjustmentsToUpdate
    ) {
        // SECTION 2: Credit & Charge Application
        
        // Step 1: Credits Brought Forward = previous invoice's Credit Balance Carried Forward
        Decimal creditsBroughtForward = 0;
        List<ARC_Invoice__c> previousInvoices = [
            SELECT Id, ARC_CreditBalanceCarriedForward__c
            FROM ARC_Invoice__c
            WHERE ARC_Contract__c = :invoice.ARC_Contract__c
              AND ARC_CoverageDateFrom__c < :invoice.ARC_CoverageDateFrom__c
            ORDER BY ARC_CoverageDateFrom__c DESC
            LIMIT 1
        ];
        
        if (!previousInvoices.isEmpty() && previousInvoices[0].ARC_CreditBalanceCarriedForward__c != null) {
            creditsBroughtForward = previousInvoices[0].ARC_CreditBalanceCarriedForward__c;
        }
        
        invoice.ARC_CreditsBroughtForward__c = creditsBroughtForward;
        
        // Step 2: Calculate Coverage Amount
        Decimal coverageAmount = 0;
        List<ARC_InvoiceLineItem__c> coverageItems = [
            SELECT Id, ARC_CoverageAmount__c
            FROM ARC_InvoiceLineItem__c
            WHERE ARC_Invoice__c = :invoice.Id
              AND ARC_Type__c = 'Coverage'
        ];
        
        for (ARC_InvoiceLineItem__c item : coverageItems) {
            coverageAmount += (item.ARC_CoverageAmount__c != null ? item.ARC_CoverageAmount__c : 0);
        }
        
        List<ARC_InvoiceLineItem__c> adjustmentItems = [
            SELECT Id, ARC_CoverageAmount__c
            FROM ARC_InvoiceLineItem__c
            WHERE ARC_Invoice__c = :invoice.Id
              AND ARC_Type__c = 'Adjustment'
        ];
        
        Decimal totalCharges = coverageAmount;
        Decimal totalCredits = 0;
        
        for (ARC_InvoiceLineItem__c item : adjustmentItems) {
            Decimal adjAmount = item.ARC_CoverageAmount__c != null ? item.ARC_CoverageAmount__c : 0;
            if (adjAmount > 0) {
                totalCharges += adjAmount; // Add charges to what's owed
            } else if (adjAmount < 0) {
                totalCredits += adjAmount; // Accumulate credits (negative values)
            }
        }
        
        Decimal amountDue = totalCharges + totalCredits;
        
        Decimal creditAppliedThisInvoice = 0;
        if (creditsBroughtForward < 0 && amountDue > 0) {
            creditAppliedThisInvoice = Math.min(Math.abs(creditsBroughtForward), amountDue);
            amountDue -= creditAppliedThisInvoice;
        }
        
        // If adjustment credits exceeded coverage, carry that excess forward
        Decimal creditBalanceCarriedForward = 0;
        if (amountDue < 0) {
            creditBalanceCarriedForward = amountDue; // excess credit from adjustment line items
            amountDue = 0;
        }
        // Any unused brought-forward credit also carries forward
        creditBalanceCarriedForward += creditsBroughtForward + creditAppliedThisInvoice;
        if (creditBalanceCarriedForward > 0) {
            creditBalanceCarriedForward = 0;
        }
        
        // Update invoice fields
        invoice.ARC_CreditAppliedThisInvoice__c = creditAppliedThisInvoice;
        invoice.ARC_AmountDue__c = amountDue;
        invoice.ARC_CreditBalanceCarriedForward__c = creditBalanceCarriedForward;
        
        // All adjustments presented on this invoice are marked Applied immediately.
        // Any remaining credit is carried forward via ARC_CreditBalanceCarriedForward__c / Contract.ARC_OpenCreditBalance__c.
        if (allAdjustments != null && !allAdjustments.isEmpty()) {
            for (ARC_Adjustment__c adj : allAdjustments) {
                adjustmentsToUpdate.add(new ARC_Adjustment__c(
                    Id = adj.Id,
                    ARC_Status__c = 'Applied'
                ));
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Chain PDF generation batch for newly created invoices
        try {
            // Query template to get ContentVersion Id
            List<vlocity_ins__DocumentTemplate__c> templates = [
                SELECT Id, Name, vlocity_ins__TemplateContentVersionId__c
                FROM vlocity_ins__DocumentTemplate__c
                WHERE Name = 'Small Group Invoice Template'
                LIMIT 1
            ];
            
            if (!templates.isEmpty() && templates[0].vlocity_ins__TemplateContentVersionId__c != null) {
                String templateCVId = templates[0].vlocity_ins__TemplateContentVersionId__c;
                ARC_InvoicePDFGenerationBatch pdfBatch = new ARC_InvoicePDFGenerationBatch(templateCVId);
                Database.executeBatch(pdfBatch, 10);
            } else {
                System.debug('Error: Small Group Invoice template not found or missing ContentVersion Id');
            }
        } catch (Exception e) {
            System.debug('Error launching PDF generation batch: ' + e.getMessage());
        }
    }
    
    /**
     * @description Calculate due date for regular invoices (month prior to coverage + charge date day)
     * @param coverageFrom The coverage start date
     * @param chargentOrderId The Chargent Order ID (for null check)
     * @param chargentOrder The Chargent Order record with charge date
     * @return Calculated due date
     */
    public static Date calculateRegularInvoiceDueDate(
        Date coverageFrom,
        Id chargentOrderId,
        ChargentOrders__ChargentOrder__c chargentOrder
    ) {
        if (coverageFrom == null) {
            return Date.today(); // Fallback
        }
        
        // Get month prior to coverage from
        Date priorMonth = coverageFrom.addMonths(-1);
        Integer year = priorMonth.year();
        Integer month = priorMonth.month();
        Integer day = 1; 
        
        // Get charge date day from ChargentOrder (picklist field returns text)
        if (chargentOrderId != null && 
            chargentOrder != null && 
            chargentOrder.ChargentOrders__Charge_Date__c != null) {
            try {
                day = Integer.valueOf(chargentOrder.ChargentOrders__Charge_Date__c);
            } catch (Exception e) {
                System.debug('Error parsing Charge Date: ' + e.getMessage());
            }
        }
        
        
        
        return Date.newInstance(year, month, day);
    }
    
    /**
     * @description Calculate coverage end date based on start date and payment frequency
     */
    public static Date calculateCoverageTo(Date coverageFrom, String paymentFrequency) {
        if (coverageFrom == null) {
            return null;
        }
        
        Integer monthsToAdd = 1; // Default Monthly
        
        if (paymentFrequency == 'Quarterly') {
            monthsToAdd = 3;
        } else if (paymentFrequency == 'Annually') {
            monthsToAdd = 12;
        }
        
        // Add months and subtract 1 day to get last day of billing period
        return coverageFrom.addMonths(monthsToAdd).addDays(-1);
    }
    
    /**
     * @description Query eligible policies for contracts and group by contract ID
     */
    public static Map<Id, List<InsurancePolicy>> getEligiblePolicies(Map<Id, ARC_Invoice__c> contractToInvoiceMap) {
        Map<Id, List<InsurancePolicy>> result = new Map<Id, List<InsurancePolicy>>();
        
        // Build map of contract to coverage dates for filtering
        Map<Id, Date> contractCoverageFrom = new Map<Id, Date>();
        Map<Id, Date> contractCoverageTo = new Map<Id, Date>();
        
        for (Id contractId : contractToInvoiceMap.keySet()) {
            ARC_Invoice__c invoice = contractToInvoiceMap.get(contractId);
            contractCoverageFrom.put(contractId, invoice.ARC_CoverageDateFrom__c);
            contractCoverageTo.put(contractId, invoice.ARC_CoverageDateTo__c);
        }
        
        // Query all policies for these contracts
        List<InsurancePolicy> allPolicies = [
            SELECT Id, ARC_Contract__c, NameInsuredId, ARC_TotalPremiumAmount__c,
                   ARC_PolicyEffectiveDate__c, ARC_PolicyExpirationDate__c, Status, Name
            FROM InsurancePolicy
            WHERE ARC_Contract__c IN :contractToInvoiceMap.keySet()
              AND Status IN ('Activated', 'Awaiting Activation', 'Terminated')
        ];
        
        // Filter policies based on coverage period eligibility
        for (InsurancePolicy policy : allPolicies) {
            Date coverageFrom = contractCoverageFrom.get(policy.ARC_Contract__c);
            Date coverageTo = contractCoverageTo.get(policy.ARC_Contract__c);
            
            // Check: EffectiveDate <= Coverage To AND (EndDate is null OR EndDate >= Coverage From)
            Boolean effectiveDateValid = policy.ARC_PolicyEffectiveDate__c != null && 
                                        policy.ARC_PolicyEffectiveDate__c <= coverageTo;
            Boolean expirationDateValid = policy.ARC_PolicyExpirationDate__c == null || 
                                         policy.ARC_PolicyExpirationDate__c >= coverageFrom;
            
            if (effectiveDateValid && expirationDateValid) {
                if (!result.containsKey(policy.ARC_Contract__c)) {
                    result.put(policy.ARC_Contract__c, new List<InsurancePolicy>());
                }
                result.get(policy.ARC_Contract__c).add(policy);
            }
        }
        
        return result;
    }
    
    /**
     * @description Query open/partially applied adjustments for contracts and group by contract ID
     */
    public static Map<Id, List<ARC_Adjustment__c>> getOpenAdjustments(Set<Id> contractIds) {
        Map<Id, List<ARC_Adjustment__c>> result = new Map<Id, List<ARC_Adjustment__c>>();
        
        List<ARC_Adjustment__c> adjustments = [
            SELECT Id, ARC_Contract__c, ARC_Policy__c, ARC_PolicyCoverage__c, ARC_Amount__c,
                   ARC_CoverageDateFrom__c, ARC_CoverageDateTo__c,
                   ARC_Status__c, ARC_Invoice__c
            FROM ARC_Adjustment__c
            WHERE ARC_Contract__c IN :contractIds
              AND ARC_Status__c = 'Open'
            ORDER BY ARC_CoverageDateFrom__c ASC
        ];
        
        for (ARC_Adjustment__c adj : adjustments) {
            if (!result.containsKey(adj.ARC_Contract__c)) {
                result.put(adj.ARC_Contract__c, new List<ARC_Adjustment__c>());
            }
            result.get(adj.ARC_Contract__c).add(adj);
        }
        
        return result;
    }
}