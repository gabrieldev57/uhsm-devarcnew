@isTest
private class ARC_InvoiceGenerationBatchTest {

    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account Small Group');
        insert acc;

        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Charge_Date__c = '15',
            ChargentOrders__Payment_Start_Date__c = Date.today().addDays(1),
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Status__c = 'Recurring'
        );
        insert order;

        Id smallGroupRtId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
                                  .get('ARC_SmallGroup').getRecordTypeId();

        Contract con = new Contract(
            AccountId = acc.Id,
            RecordTypeId = smallGroupRtId,
            Status = 'Draft',  
            ARC_OEEndDate__c = Date.today().addDays(-1), 
            ARC_EffectiveDate__c = Date.today().addDays(14), 
            ARC_NextInvoiceCoverageStart__c = Date.today().addDays(14),
            ARC_PaymentFrequency__c = 'Monthly',
            ARC_RecurringMonthlyOrder__c = order.Id
        );
        insert con;
        
        con.Status = 'Enrollment In Progress';
        update con;

        InsurancePolicy policy = new InsurancePolicy(
            Name = 'POL-TEST-001',
            NameInsuredId = acc.Id, 
            ARC_Contract__c = con.Id,
           // ARC_TotalPremiumAmount__c = 1000,
            ARC_PolicyEffectiveDate__c = Date.today().addDays(-5),
            ARC_PolicyExpirationDate__c = Date.today().addYears(1),
            Status = 'Activated'
        );
        insert policy;

        Product2 prod = new Product2(Name = 'Health Plan A', IsActive = true);
        insert prod;

        InsurancePolicyCoverage cov = new InsurancePolicyCoverage(
            InsurancePolicyId = policy.Id,
            ARC_UnitPrice__c = 1000
        );
        insert cov;

        ARC_Adjustment__c adj = new ARC_Adjustment__c(
            ARC_Contract__c = con.Id,
            ARC_Policy__c = policy.Id,
            ARC_Amount__c = -150, 
            ARC_Status__c = 'Open',
            ARC_CoverageDateFrom__c = Date.today(),
            ARC_CoverageDateTo__c = Date.today().addDays(30)
        );
        insert adj;

        vlocity_ins__DocumentTemplate__c docTemplate = new vlocity_ins__DocumentTemplate__c(
            Name = 'Small Group Invoice Template',
            vlocity_ins__TemplateContentVersionId__c = '068000000000000' 
        );
        insert docTemplate;
    }

    @isTest
    static void testBatchExecution_FirstInvoice() {
        Test.startTest();
        ARC_InvoiceGenerationBatch batch = new ARC_InvoiceGenerationBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        List<ARC_Invoice__c> invoices = [SELECT Id, ARC_AmountDue__c, ARC_Contract__c FROM ARC_Invoice__c];
        System.assert(!invoices.isEmpty(), 'At least one invoice should have been generated.');
        
        List<ARC_InvoiceLineItem__c> lineItems = [SELECT Id, ARC_Type__c FROM ARC_InvoiceLineItem__c WHERE ARC_Invoice__c = :invoices[0].Id];
        System.assert(lineItems.size() >= 2, 'There must be Line Items for both Coverage and Adjustment.');
    }

    @isTest
    static void testCalculateCoverageTo() {
        Date startDate = Date.newInstance(2026, 1, 1);

        // Test Monthly
        Date endMonthly = ARC_InvoiceGenerationBatch.calculateCoverageTo(startDate, 'Monthly');
        System.assertEquals(Date.newInstance(2026, 1, 31), endMonthly, 'Monthly coverage calculation failed.');

        // Test Quarterly
        Date endQuarterly = ARC_InvoiceGenerationBatch.calculateCoverageTo(startDate, 'Quarterly');
        System.assertEquals(Date.newInstance(2026, 3, 31), endQuarterly, 'Quarterly coverage calculation failed.');

        // Test Annually
        Date endAnnually = ARC_InvoiceGenerationBatch.calculateCoverageTo(startDate, 'Annually');
        System.assertEquals(Date.newInstance(2026, 12, 31), endAnnually, 'Annually coverage calculation failed.');
        
        // Test Null
        System.assertEquals(null, ARC_InvoiceGenerationBatch.calculateCoverageTo(null, 'Monthly'));
    }

    @isTest
    static void testCalculateRegularInvoiceDueDate() {
        Date coverageFrom = Date.newInstance(2026, 5, 1); 
        
        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Charge_Date__c = '15'
        );
        insert order;

        Date dueDate = ARC_InvoiceGenerationBatch.calculateRegularInvoiceDueDate(coverageFrom, order.Id, order);
        System.assertEquals(Date.newInstance(2026, 4, 15), dueDate, 'Due date was not calculated correctly.');
    }

    @isTest
    static void testStaticMethods_ManualInvocation() {
       Contract con = [SELECT Id FROM Contract LIMIT 1];
        
        ARC_Invoice__c inv = new ARC_Invoice__c(
            ARC_Contract__c = con.Id,
            ARC_CoverageDateFrom__c = Date.today(),
            ARC_CoverageDateTo__c = Date.today().addDays(30)
        );
        insert inv;

        Map<Id, ARC_Invoice__c> contractToInvoiceMap = new Map<Id, ARC_Invoice__c>{
            con.Id => inv
        };

        Test.startTest();
        ARC_InvoiceGenerationBatch.createInvoiceLineItems(contractToInvoiceMap);
        Test.stopTest();

        ARC_Invoice__c updatedInv = [SELECT Id, ARC_AmountDue__c, ARC_CreditAppliedThisInvoice__c FROM ARC_Invoice__c WHERE Id = :inv.Id];
        
        System.assertNotEquals(null, updatedInv.ARC_AmountDue__c, 'The Amount Due should have been calculated.');
    }
    
    @isTest
    static void testExistingInvoiceCheck_NoDuplicates() {
        Contract con = [SELECT Id, ARC_EffectiveDate__c, ARC_PaymentFrequency__c FROM Contract LIMIT 1];
        
        Date coverageTo = ARC_InvoiceGenerationBatch.calculateCoverageTo(con.ARC_EffectiveDate__c, con.ARC_PaymentFrequency__c);
        
        ARC_Invoice__c existingInv = new ARC_Invoice__c(
            ARC_Contract__c = con.Id,
            ARC_CoverageDateFrom__c = con.ARC_EffectiveDate__c,
            ARC_CoverageDateTo__c = coverageTo
        );
        insert existingInv;
        
        Test.startTest();
        ARC_InvoiceGenerationBatch batch = new ARC_InvoiceGenerationBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        Integer invoiceCount = [SELECT COUNT() FROM ARC_Invoice__c WHERE ARC_Contract__c = :con.Id];
        System.assertEquals(1, invoiceCount, 'Duplicate invoices should not be created for the same coverage period.');
    }

    @isTest
    static void testFallbackToTotalPremiumAmount() {
        Contract con = [SELECT Id, AccountId FROM Contract LIMIT 1];
        
        InsurancePolicy policyNoCoverage = new InsurancePolicy(
            Name = 'POL-NO-COV-002',
            NameInsuredId = con.AccountId, 
            ARC_Contract__c = con.Id,
            ARC_PolicyEffectiveDate__c = Date.today().addDays(-5),
            ARC_PolicyExpirationDate__c = Date.today().addYears(1),
            Status = 'Activated'
        );
        insert policyNoCoverage;

        ARC_Invoice__c inv = new ARC_Invoice__c(
            ARC_Contract__c = con.Id,
            ARC_CoverageDateFrom__c = Date.today(),
            ARC_CoverageDateTo__c = Date.today().addDays(30)
        );
        insert inv;

        Map<Id, ARC_Invoice__c> contractToInvoiceMap = new Map<Id, ARC_Invoice__c>{
            con.Id => inv
        };

        Test.startTest();
        ARC_InvoiceGenerationBatch.createInvoiceLineItems(contractToInvoiceMap);
        Test.stopTest();

        List<ARC_InvoiceLineItem__c> lineItems = [
            SELECT Id, ARC_CoverageAmount__c 
            FROM ARC_InvoiceLineItem__c 
            WHERE ARC_Invoice__c = :inv.Id 
            AND ARC_Policy__c = :policyNoCoverage.Id
            AND ARC_Type__c = 'Coverage'
        ];

        System.assertEquals(1, lineItems.size(), 'One Line Item should have been created for the fallback policy.');
        
        System.assertEquals(0, lineItems[0].ARC_CoverageAmount__c, 'The amount must be 0 because the Roll-Up Summary has no child records.');
    }
 
    @isTest
    static void testProcessRegularInvoices() {
        Account acc = new Account(Name = 'Test Account Regular Invoice');
        insert acc;

        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Charge_Date__c = '15',
            ChargentOrders__Payment_Start_Date__c = Date.today().addDays(1),
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Stop__c = 'Unending',
            ChargentOrders__Description__c = 'Recurring Monthly Order', 
            ChargentOrders__Subtotal__c = 1000, 
            ChargentOrders__Charge_Amount__c = 1000 
        );
        insert order;

        Id smallGroupRtId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName()
                                  .get('ARC_SmallGroup').getRecordTypeId();

        Contract con = new Contract(
            AccountId = acc.Id,
            RecordTypeId = smallGroupRtId,
            Status = 'Draft', 
            ARC_OEEndDate__c = Date.today().addDays(-20), 
            ARC_EffectiveDate__c = Date.today().addDays(-5), 
            ARC_NextInvoiceCoverageStart__c = Date.today(),
            ARC_PaymentFrequency__c = 'Monthly',
            ARC_RecurringMonthlyOrder__c = order.Id,
            ARC_CoveragePaidThrough__c = Date.today().addDays(-1)
        );
        insert con;

        con.Status = 'Activated';
        update con;

        InsurancePolicy testPolicy = new InsurancePolicy(
            Name = 'POL-REG-001',
            NameInsuredId = acc.Id,
            ARC_Contract__c = con.Id,
            ARC_PolicyEffectiveDate__c = Date.today().addDays(-5),
            ARC_PolicyExpirationDate__c = Date.today().addYears(1),
            Status = 'Activated'
        );
        insert testPolicy;

        InsurancePolicyCoverage testCov = new InsurancePolicyCoverage(
            InsurancePolicyId = testPolicy.Id,
            ARC_UnitPrice__c = 500
        );
        insert testCov;

        Contract testContract = [
            SELECT Id, Status, ARC_NextInvoiceCoverageStart__c, ARC_PaymentFrequency__c, 
                   ARC_OEEndDate__c, ARC_RecurringMonthlyOrder__c, ARC_EffectiveDate__c, 
                   ARC_CoveragePaidThrough__c, 
                   ARC_RecurringMonthlyOrder__r.ChargentOrders__Payment_Start_Date__c, 
                   ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Date__c 
            FROM Contract 
            WHERE Id = :con.Id
        ];

        Test.startTest();
        ARC_InvoiceGenerationBatch batch = new ARC_InvoiceGenerationBatch();
        batch.processRegularInvoices(new List<Contract>{ testContract });
        Test.stopTest();

        List<ARC_Invoice__c> invoices = [
            SELECT Id 
            FROM ARC_Invoice__c 
            WHERE ARC_Contract__c = :con.Id
        ];
        
        System.assert(!invoices.isEmpty(), 'A regular invoice should have been generated by directly invoking the TestVisible method.');
    }
}