/**
 * @description Batch process that generates PDF documents for Small Group invoices
 *              that don't have a PDF generated yet
 * @author lucas.benero@arcsona.com
 * @last modified date 2026-04-13 by Franca Fattoruso
 */
global class ARC_InvoicePDFGenerationBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private String templateContentVersionId;
    private Integer successCount = 0;
    private Integer failureCount = 0;
    private List<String> errors = new List<String>();
    
    /**
     * @description Constructor that accepts template ContentVersion Id
     * @param templateCVId The ContentVersion Id of the invoice template
     */
    global ARC_InvoicePDFGenerationBatch(String templateCVId) {
        this.templateContentVersionId = templateCVId;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Set<Id> invoicesWithPDF = new Set<Id>();
        for (DocumentGenerationProcess dgp : [SELECT ReferenceObject FROM DocumentGenerationProcess WHERE ReferenceObject != null]) {
            invoicesWithPDF.add(dgp.ReferenceObject);
        }
        
        return Database.getQueryLocator([
            SELECT Id, Name, ARC_Description__c, CreatedDate, ARC_AmountDue__c,
                   ARC_CoverageDateFrom__c, ARC_CoverageDateTo__c, ARC_DueDate__c,
                   ARC_Contract__c,
                   ARC_Contract__r.Account.Name,
                   ARC_Contract__r.Account.ARC_GroupNumber__c,
                   ARC_Contract__r.Account.BillingStreet,
                   ARC_Contract__r.Account.BillingCity,
                   ARC_Contract__r.Account.BillingState,
                   ARC_Contract__r.Account.BillingPostalCode
            FROM ARC_Invoice__c
            WHERE RecordType.DeveloperName = 'ARC_SmallGroup'
              AND Id NOT IN :invoicesWithPDF
        ]);
    }

    global void execute(Database.BatchableContext BC, List<ARC_Invoice__c> invoices) {
        for (ARC_Invoice__c invoice : invoices) {
            try {
                generateInvoicePDF(invoice);
                successCount++;
            } catch (Exception e) {
                failureCount++;
                errors.add('Invoice ' + invoice.Name + ': ' + e.getMessage());
                System.debug('Error generating PDF for Invoice ' + invoice.Name + ': ' + e.getMessage());
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('PDF Generation Complete. Success: ' + successCount + ', Failures: ' + failureCount);
        if (!errors.isEmpty()) {
            System.debug('Errors: ' + String.join(errors, '\n'));
        }
    }
    
    /**
     * @description Generates PDF for a single invoice
     * @param invoice The invoice to generate PDF for
     */
    private void generateInvoicePDF(ARC_Invoice__c invoice) {
        Map<String, Object> tokenData = new Map<String, Object>();
        
        // 1. Employer & Billing Information (Header)
        populateHeaderSection(invoice, tokenData);
        
        // 2. Billing Summary Section
        populateBillingSummarySection(invoice, tokenData);
        
        // 3. Membership Details Section
        populateMembershipDetailsSection(invoice, tokenData);
        
        // 4. Eligibility Changes Section
        populateEligibilityChangesSection(invoice, tokenData);
        
        // 5. SSN Requests Section
        populateSSNRequestsSection(invoice, tokenData);
        
        // Generate PDF
        String title = invoice.ARC_Description__c;
        System.debug('Generating PDF for Invoice: ' + invoice.Id + ' with template: ' + templateContentVersionId);
        System.debug('Token Data:' + tokenData);
        Id dgpId = ARC_DocGenDirectInvoker.generateDocumentWithTokenData(
            invoice.Id,
            templateContentVersionId,
            tokenData,
            title
        );
        System.debug('DocumentGenerationProcess created with Id: ' + dgpId);
    }
    
    /**
     * @description Populates header section with employer and billing information
     */
    private void populateHeaderSection(ARC_Invoice__c invoice, Map<String, Object> tokenData) {
        String billingAddress = '';
        if (invoice.ARC_Contract__r.Account.BillingStreet != null) {
            billingAddress += invoice.ARC_Contract__r.Account.BillingStreet;
        }
        if (invoice.ARC_Contract__r.Account.BillingCity != null) {
            billingAddress += (billingAddress != '' ? ', ' : '') + invoice.ARC_Contract__r.Account.BillingCity;
        }
        if (invoice.ARC_Contract__r.Account.BillingState != null) {
            billingAddress += (billingAddress != '' ? ', ' : '') + invoice.ARC_Contract__r.Account.BillingState;
        }
        if (invoice.ARC_Contract__r.Account.BillingPostalCode != null) {
            billingAddress += (billingAddress != '' ? ' ' : '') + invoice.ARC_Contract__r.Account.BillingPostalCode;
        }
        tokenData.put('BillingAddress', billingAddress);
        
        tokenData.put('CompanyName', invoice.ARC_Contract__r.Account.Name ?? '');
        tokenData.put('BillingAccountNumber', invoice.ARC_Contract__r.Account.ARC_GroupNumber__c ?? '');
        tokenData.put('InvoiceNumber', invoice.Name ?? '');
        
        String billingPeriod = '';
        if (invoice.ARC_CoverageDateFrom__c != null && invoice.ARC_CoverageDateTo__c != null) {
            billingPeriod = invoice.ARC_CoverageDateFrom__c.format() + ' - ' + invoice.ARC_CoverageDateTo__c.format();
        }
        tokenData.put('BillingPeriod', billingPeriod);
        
        tokenData.put('DateBilled', invoice.CreatedDate.format('MM/dd/yyyy'));
        
        String paymentDueDate = invoice.ARC_DueDate__c != null ? invoice.ARC_DueDate__c.format() : '';
        tokenData.put('PaymentDueDate', paymentDueDate);
        tokenData.put('InvoiceStatus', 'OPEN');
    }
    
    /**
     * @description Populates billing summary section.
     *              Credits Brought Forward = ARC_CreditBalanceCarriedForward__c from the previous invoice.
     */
    private void populateBillingSummarySection(ARC_Invoice__c invoice, Map<String, Object> tokenData) {
        List<ARC_Invoice__c> previousInvoices = [
            SELECT Id, ARC_AmountDue__c, ARC_CreditBalanceCarriedForward__c, CreatedDate
            FROM ARC_Invoice__c
            WHERE ARC_Contract__c = :invoice.ARC_Contract__c
              AND ARC_CoverageDateTo__c < :invoice.ARC_CoverageDateFrom__c
            ORDER BY ARC_CoverageDateTo__c DESC
            LIMIT 1
        ];
        
        Decimal priorAmountDue  = 0;
        Decimal priorAmountPaid = 0;
        
        if (!previousInvoices.isEmpty()) {
            ARC_Invoice__c priorInvoice = previousInvoices[0];
            priorAmountDue = priorInvoice.ARC_AmountDue__c ?? 0;
            
            List<ChargentOrders__Transaction__c> transactions = [
                SELECT Id, ChargentOrders__Amount__c
                FROM ChargentOrders__Transaction__c
                WHERE ARC_Invoice__c = :priorInvoice.Id
                  AND ChargentOrders__Response_Status__c = 'Approved'
                LIMIT 1
            ];
            
            if (!transactions.isEmpty()) {
                priorAmountPaid = transactions[0].ChargentOrders__Amount__c ?? 0;
            }
        }
        
        Decimal priorBalance = priorAmountDue - priorAmountPaid;
        
        tokenData.put('SharingPrograms.AmountDue', formatCurrency(priorAmountDue));
        tokenData.put('SharingPrograms.AmountPaid', formatCurrency(priorAmountPaid));
        tokenData.put('SharingPrograms.Balance', formatCurrency(priorBalance));
        tokenData.put('SharingPrograms.SubtotalAmountDue', formatCurrency(priorAmountDue));
        tokenData.put('SharingPrograms.SubtotalAmountPaid', formatCurrency(priorAmountPaid));
        tokenData.put('SharingPrograms.SubtotalBalance', formatCurrency(priorBalance));
        
        List<ARC_InvoiceLineItem__c> lineItems = [
            SELECT Id, ARC_Type__c, ARC_CoverageAmount__c
            FROM ARC_InvoiceLineItem__c
            WHERE ARC_Invoice__c = :invoice.Id
        ];
        
        Decimal currentSharingPrograms = 0;
        Decimal currentAdjustments     = 0;
        
        for (ARC_InvoiceLineItem__c item : lineItems) {
            Decimal amount = item.ARC_CoverageAmount__c ?? 0;
            if (item.ARC_Type__c == 'Coverage') {
                currentSharingPrograms += amount;
            } else if (item.ARC_Type__c == 'Adjustment') {
                currentAdjustments += amount;
            }
        }
        
        Decimal currentCredits = 0;
        if (!previousInvoices.isEmpty() && previousInvoices[0].ARC_CreditBalanceCarriedForward__c != null) {
            currentCredits = previousInvoices[0].ARC_CreditBalanceCarriedForward__c;
        }
        
        Decimal currentSubtotal  = currentSharingPrograms + currentAdjustments + currentCredits;
        Decimal invoiceAmountDue = invoice.ARC_AmountDue__c != null ? invoice.ARC_AmountDue__c : currentSubtotal;
        Decimal totalAmountDue   = invoiceAmountDue + priorBalance;
        
        tokenData.put('CurrentBilling.SharingProgramsAmountDue', formatCurrency(currentSharingPrograms));
        tokenData.put('CurrentBilling.SharingProgramsBalance',   formatCurrency(currentSharingPrograms));
        tokenData.put('CurrentBilling.AdjustmentsAmountDue',     formatCurrency(currentAdjustments));
        tokenData.put('CurrentBilling.AdjustmentsBalance',       formatCurrency(currentAdjustments));
        tokenData.put('CurrentBilling.CreditsAmountDue',         formatCurrency(currentCredits));
        tokenData.put('CurrentBilling.CreditsBalance',           formatCurrency(currentCredits));
        
        tokenData.put('SubtotalAmountDue',  formatCurrency(currentSubtotal));
        tokenData.put('SubtotalBalance',    formatCurrency(currentSubtotal));
        tokenData.put('TotalAmountDue',     formatCurrency(totalAmountDue));
        tokenData.put('Invoice.PaymentDueDate', tokenData.get('PaymentDueDate'));
    }
    
    /**
     * @description Populates membership details section (Coverage line items).
     *              Deduplicates by policy: one row per policy using policy-level totals.
     */
    private void populateMembershipDetailsSection(ARC_Invoice__c invoice, Map<String, Object> tokenData) {
        List<ARC_InvoiceLineItem__c> coverageItems = [
            SELECT Id, ARC_Employee__c, ARC_Employee__r.Name,
                   ARC_Employee__r.LastName,
                   ARC_Employee__r.ARC_Member_ID__c,
                   ARC_Policy__c,
                   ARC_Policy__r.ARC_IndividualPrice__c,
                   ARC_Policy__r.ARC_DependentPrice__c,
                   ARC_Policy__r.ARC_TotalPremiumAmount__c
            FROM ARC_InvoiceLineItem__c
            WHERE ARC_Invoice__c = :invoice.Id
              AND ARC_Type__c = 'Coverage'
            ORDER BY ARC_Employee__r.LastName ASC, ARC_Employee__r.FirstName ASC
        ];

        // Deduplicate by policy: keep only the first ILI per policy (multiple ILIs exist
        // for per-plan breakdown, but the PDF shows one row per policy using policy-level totals).
        Map<Id, ARC_InvoiceLineItem__c> seenPolicies = new Map<Id, ARC_InvoiceLineItem__c>();
        List<ARC_InvoiceLineItem__c> deduped = new List<ARC_InvoiceLineItem__c>();
        for (ARC_InvoiceLineItem__c item : coverageItems) {
            if (!seenPolicies.containsKey(item.ARC_Policy__c)) {
                seenPolicies.put(item.ARC_Policy__c, item);
                deduped.add(item);
            }
        }
        
        List<Object> membershipDetails   = new List<Object>();
        Decimal totalEmployeeAmount      = 0;
        Decimal totalDependentAmount     = 0;
        Decimal totalMonthlyContribution = 0;
        
        Map<Id, PolicyDetails> policyDetailsMap = getPolicyDetails(deduped);
        
        for (ARC_InvoiceLineItem__c item : deduped) {
            Map<String, Object> member = new Map<String, Object>();
            
            member.put('MemberId',   item.ARC_Employee__r.ARC_Member_ID__c ?? '');
            member.put('MemberName', item.ARC_Employee__r.Name ?? '');
            
            PolicyDetails details = policyDetailsMap.get(item.ARC_Policy__c);
            member.put('PlanName',        details != null ? details.productName  : '');
            member.put('NumberEnrolled',  details != null ? String.valueOf(details.memberCount) : '1');
            member.put('ContractType',    details != null ? details.contractType : '');
            
            Decimal empAmount     = item.ARC_Policy__r.ARC_IndividualPrice__c    ?? 0;
            Decimal depAmount     = item.ARC_Policy__r.ARC_DependentPrice__c     ?? 0;
            Decimal monthlyAmount = item.ARC_Policy__r.ARC_TotalPremiumAmount__c ?? 0;
            
            member.put('EmployeeAmount',      formatCurrency(empAmount));
            member.put('DependentAmount',     formatCurrency(depAmount));
            member.put('MonthlyContribution', formatCurrency(monthlyAmount));
            
            totalEmployeeAmount      += empAmount;
            totalDependentAmount     += depAmount;
            totalMonthlyContribution += monthlyAmount;
            
            membershipDetails.add(member);
        }
        
        tokenData.put('Invoice.MembershipDetails', membershipDetails);
        tokenData.put('Membership.EmployeeAmountSubtotal',      formatCurrency(totalEmployeeAmount));
        tokenData.put('Membership.DependentAmountSubtotal',     formatCurrency(totalDependentAmount));
        tokenData.put('Membership.MonthlyContributionSubtotal', formatCurrency(totalMonthlyContribution));
    }
    
    /**
     * @description Populates eligibility changes section (Adjustment line items).
     *              Deduplicates by policy: one row per policy per coverage date, summing
     *              amounts across multiple ILIs that belong to the same policy.
     */
    private void populateEligibilityChangesSection(ARC_Invoice__c invoice, Map<String, Object> tokenData) {
        List<ARC_InvoiceLineItem__c> adjustmentItems = [
            SELECT Id, ARC_Employee__c, ARC_Employee__r.Name,
                   ARC_Employee__r.LastName,
                   ARC_Employee__r.ARC_Member_ID__c,
                   ARC_Policy__c,
                   ARC_Policy__r.ARC_IndividualPrice__c,
                   ARC_Policy__r.ARC_DependentPrice__c,
                   ARC_Policy__r.ARC_TotalPremiumAmount__c,
                   ARC_CoverageAmount__c,
                   ARC_CoverageDateFrom__c
            FROM ARC_InvoiceLineItem__c
            WHERE ARC_Invoice__c = :invoice.Id
              AND ARC_Type__c = 'Adjustment'
            ORDER BY ARC_Employee__r.LastName ASC, ARC_Employee__r.FirstName ASC
        ];

        // Deduplicate by policy + coverage date: consolidate multiple ILIs (one per IPC)
        // into a single row per policy, summing the adjustment amounts.
        // Key: policyId + coverageDate to handle cases where the same policy has
        // adjustments for different periods.
        Map<String, ARC_InvoiceLineItem__c> seenPolicies     = new Map<String, ARC_InvoiceLineItem__c>();
        Map<String, Decimal>                consolidatedAmounts = new Map<String, Decimal>();
        List<String>                        dedupedKeys       = new List<String>();

        for (ARC_InvoiceLineItem__c item : adjustmentItems) {
            String key = String.valueOf(item.ARC_Policy__c) + '_' +
                         String.valueOf(item.ARC_CoverageDateFrom__c);
            if (!seenPolicies.containsKey(key)) {
                seenPolicies.put(key, item);
                consolidatedAmounts.put(key, item.ARC_CoverageAmount__c ?? 0);
                dedupedKeys.add(key);
            } else {
                consolidatedAmounts.put(key, consolidatedAmounts.get(key) + (item.ARC_CoverageAmount__c ?? 0));
            }
        }

        List<Object> eligibilityChanges  = new List<Object>();
        Decimal totalEmployeeAmount      = 0;
        Decimal totalDependentAmount     = 0;
        Decimal totalMonthlyContribution = 0;

        Set<Id> policyIds = new Set<Id>();
        for (ARC_InvoiceLineItem__c item : seenPolicies.values()) {
            if (item.ARC_Policy__c != null) policyIds.add(item.ARC_Policy__c);
        }
        Map<Id, PolicyDetails> policyDetailsMap = getPolicyDetailsForIds(policyIds);

        for (String key : dedupedKeys) {
            ARC_InvoiceLineItem__c item     = seenPolicies.get(key);
            Decimal adjustmentAmount        = consolidatedAmounts.get(key);

            Map<String, Object> change = new Map<String, Object>();

            change.put('MemberId',   item.ARC_Employee__r.ARC_Member_ID__c ?? '');
            change.put('MemberName', item.ARC_Employee__r.Name ?? '');

            PolicyDetails details = policyDetailsMap.get(item.ARC_Policy__c);
            change.put('PlanName',      details != null ? details.productName : '');
            change.put('EffectiveDate', item.ARC_CoverageDateFrom__c != null ? item.ARC_CoverageDateFrom__c.format() : '');
            change.put('ChangeCode',    'TBD');

            Decimal empAmount = 0;
            Decimal depAmount = 0;

            if (item.ARC_Policy__c != null) {
                Decimal policyTotal = item.ARC_Policy__r.ARC_TotalPremiumAmount__c ?? 0;
                if (policyTotal != 0) {
                    Decimal empRate = (item.ARC_Policy__r.ARC_IndividualPrice__c ?? 0) / policyTotal;
                    Decimal depRate = (item.ARC_Policy__r.ARC_DependentPrice__c  ?? 0) / policyTotal;
                    empAmount = adjustmentAmount * empRate;
                    depAmount = adjustmentAmount * depRate;
                }
            }

            change.put('EmployeeAmount',      formatCurrency(empAmount));
            change.put('DependentAmount',     formatCurrency(depAmount));
            change.put('MonthlyContribution', formatCurrency(adjustmentAmount));

            totalEmployeeAmount      += empAmount;
            totalDependentAmount     += depAmount;
            totalMonthlyContribution += adjustmentAmount;

            eligibilityChanges.add(change);
        }
        
        tokenData.put('Invoice.EligibilityChanges',       eligibilityChanges);
        tokenData.put('Invoice.HasEligibilityChanges',    !eligibilityChanges.isEmpty());
        tokenData.put('Invoice.HasNotEligibilityChanges', eligibilityChanges.isEmpty());
        tokenData.put('Invoice.HasOtherTables',           false);
        
        tokenData.put('Eligibility.EmployeeAmountSubtotal',      formatCurrency(totalEmployeeAmount));
        tokenData.put('Eligibility.DependentAmountSubtotal',     formatCurrency(totalDependentAmount));
        tokenData.put('Eligibility.MonthlyContributionSubtotal', formatCurrency(totalMonthlyContribution));
    }
    
    /**
     * @description Populates SSN requests section
     */
    private void populateSSNRequestsSection(ARC_Invoice__c invoice, Map<String, Object> tokenData) {
        List<ARC_InvoiceLineItem__c> coverageItems = [
            SELECT Id, ARC_Employee__c, ARC_Policy__c
            FROM ARC_InvoiceLineItem__c
            WHERE ARC_Invoice__c = :invoice.Id
              AND ARC_Type__c = 'Coverage'
        ];
        
        Set<Id> employeeIds = new Set<Id>();
        Set<Id> policyIds   = new Set<Id>();
        for (ARC_InvoiceLineItem__c item : coverageItems) {
            if (item.ARC_Employee__c != null) employeeIds.add(item.ARC_Employee__c);
            if (item.ARC_Policy__c   != null) policyIds.add(item.ARC_Policy__c);
        }
        
        List<Object> ssnRequests = new List<Object>();
        
        if (!employeeIds.isEmpty() && !policyIds.isEmpty()) {
            List<InsurancePolicyParticipant> participants = [
                SELECT Id, InsurancePolicyId, PrimaryParticipantContactId
                FROM InsurancePolicyParticipant
                WHERE InsurancePolicyId IN :policyIds
            ];
            
            Set<Id> allContactIds = new Set<Id>();
            for (InsurancePolicyParticipant participant : participants) {
                if (participant.PrimaryParticipantContactId != null) {
                    allContactIds.add(participant.PrimaryParticipantContactId);
                }
            }
            
            List<vlocity_ins__GroupCensusMember__c> censusMembers = [
                SELECT Id, Name, vlocity_ins__ContactId__c, Member_ID__c,
                       ARC_DependentRelationship__c, vlocity_ins__SocialSecurityNumber__c,
                       vlocity_ins__IsPrimaryMember__c,
                       vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__c
                FROM vlocity_ins__GroupCensusMember__c
                WHERE vlocity_ins__ContactId__c IN :allContactIds
                ORDER BY vlocity_ins__ContactId__r.LastName ASC, vlocity_ins__ContactId__r.FirstName ASC
            ];
            
            Map<Id, vlocity_ins__GroupCensusMember__c> contactPrimaryCensusMap = new Map<Id, vlocity_ins__GroupCensusMember__c>();
            for (vlocity_ins__GroupCensusMember__c cm : censusMembers) {
                if (cm.vlocity_ins__IsPrimaryMember__c) {
                    contactPrimaryCensusMap.put(cm.vlocity_ins__ContactId__c, cm);
                }
            }
            
            for (vlocity_ins__GroupCensusMember__c censusMember : censusMembers) {
                if (String.isBlank(censusMember.vlocity_ins__SocialSecurityNumber__c)) {
                    Id contactId        = censusMember.vlocity_ins__ContactId__c;
                    Id relatedContactId = censusMember?.vlocity_ins__RelatedCensusMemberId__r?.vlocity_ins__ContactId__c;
                    vlocity_ins__GroupCensusMember__c primaryCensus = contactPrimaryCensusMap.get(relatedContactId ?? contactId);
                    
                    if (primaryCensus != null) {
                        Map<String, Object> ssnRequest = new Map<String, Object>();
                        ssnRequest.put('MemberId',     censusMember.Member_ID__c ?? '');
                        ssnRequest.put('MemberName',   censusMember.Name ?? '');
                        ssnRequest.put('EmployeeName', primaryCensus.Name ?? '');
                        ssnRequests.add(ssnRequest);
                    }
                }
            }
        }
        
        tokenData.put('Invoice.SSNRequests',        ssnRequests);
        tokenData.put('Invoice.HasSSNRequests',     !ssnRequests.isEmpty());
        tokenData.put('Invoice.HasNotSSNRequests',  ssnRequests.isEmpty());
    }
    
    /**
     * @description Gets policy details including product name from coverage and member counts
     */
    private Map<Id, PolicyDetails> getPolicyDetails(List<ARC_InvoiceLineItem__c> coverageItems) {
        Set<Id> policyIds = new Set<Id>();
        for (ARC_InvoiceLineItem__c item : coverageItems) {
            if (item.ARC_Policy__c != null) policyIds.add(item.ARC_Policy__c);
        }
        return getPolicyDetailsForIds(policyIds);
    }
    
    /**
     * @description Gets policy details for given policy IDs
     */
    private Map<Id, PolicyDetails> getPolicyDetailsForIds(Set<Id> policyIds) {
        Map<Id, PolicyDetails> detailsMap = new Map<Id, PolicyDetails>();
        if (policyIds.isEmpty()) return detailsMap;
        
        Map<Id, Set<String>> policyProductDescriptionsMap = new Map<Id, Set<String>>();
        for (InsurancePolicyCoverage coverage : [
            SELECT InsurancePolicyId, vlocity_ins_fsc__Product2Id__r.Description
            FROM InsurancePolicyCoverage
            WHERE InsurancePolicyId IN :policyIds
              AND ARC_ParentProduct__c = null
              AND vlocity_ins_fsc__Product2Id__c != null
        ]) {
            String productDesc = coverage.vlocity_ins_fsc__Product2Id__r.Description;
            if (String.isBlank(productDesc)) continue;
            if (!policyProductDescriptionsMap.containsKey(coverage.InsurancePolicyId)) {
                policyProductDescriptionsMap.put(coverage.InsurancePolicyId, new Set<String>());
            }
            policyProductDescriptionsMap.get(coverage.InsurancePolicyId).add(productDesc);
        }

        Map<Id, String> policyProductMap = new Map<Id, String>();
        for (Id policyId : policyProductDescriptionsMap.keySet()) {
            policyProductMap.put(policyId, String.join(new List<String>(policyProductDescriptionsMap.get(policyId)), ', '));
        }
        
        List<AggregateResult> participantCounts = [
            SELECT InsurancePolicyId, COUNT(Id) cnt
            FROM InsurancePolicyParticipant
            WHERE InsurancePolicyId IN :policyIds
            GROUP BY InsurancePolicyId
        ];
        
        Map<Id, Integer> memberCountMap = new Map<Id, Integer>();
        for (AggregateResult ar : participantCounts) {
            memberCountMap.put((Id)ar.get('InsurancePolicyId'), (Integer)ar.get('cnt'));
        }
        
        for (Id policyId : policyIds) {
            PolicyDetails details  = new PolicyDetails();
            details.productName    = policyProductMap.get(policyId) ?? '';
            Integer memberCount    = memberCountMap.get(policyId) ?? 1;
            details.memberCount    = memberCount;
            details.contractType   = memberCount == 1 ? 'EE' : (memberCount == 2 ? 'EE+1' : 'FAM');
            detailsMap.put(policyId, details);
        }
        
        return detailsMap;
    }
    
    /**
     * @description Inner class to hold policy details
     */
    private class PolicyDetails {
        String  productName;
        Integer memberCount;
        String  contractType;
    }
    
    /**
     * @description Formats decimal as currency string
     */
    private String formatCurrency(Decimal amount) {
        if (amount == null) {
            return '$0.00';
        }
        if (amount < 0) {
            return '-$' + Math.abs(amount).setScale(2, System.RoundingMode.HALF_UP).toPlainString();
        }
        return '$' + amount.setScale(2, System.RoundingMode.HALF_UP).toPlainString();
    }
}