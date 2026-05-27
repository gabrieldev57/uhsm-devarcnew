@IsTest
private class ARC_QuoteTriggerHandlerTest {

    static Id smallGroupQuoteRTId;
    static Id renewalOppRTId;
    static Id contractRTId;
    static Id stdPbId;

    @TestSetup
    static void setupData() {
        
        smallGroupQuoteRTId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Quote'
            AND DeveloperName = 'SmallGroupQuote'
            LIMIT 1
        ].Id;

        renewalOppRTId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Opportunity'
            AND DeveloperName = 'ARC_Renewal'
            LIMIT 1
        ].Id;

        contractRTId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Contract'
            AND DeveloperName = 'ARC_SmallGroup'
            LIMIT 1
        ].Id;
        
        Account acc1 = new Account(Name='Test Account 1');
        Account acc2 = new Account(Name='Test Account 2');
        insert new List<Account>{acc1, acc2};
    
        Date requestedDate = Date.today().addMonths(2);
        Date oeEndDate = requestedDate.addDays(-15); 
        Date oeStartDate = oeEndDate.addDays(-30);
    
        Opportunity opp1 = new Opportunity(
            Name='Opp 1', 
            StageName='Prospecting', 
            CloseDate=Date.today(), 
            AccountId=acc1.Id, 
            ARC_CurvScore__c = 85,
            ARC_RequestedEffectiveDate__c = requestedDate,
            ARC_OEStartDate__c = oeStartDate,
            ARC_OEEndDate__c = oeEndDate
        );
        Opportunity opp2 = new Opportunity(
            Name='Opp 2', 
            StageName='Prospecting', 
            CloseDate=Date.today(), 
            AccountId=acc2.Id, 
            ARC_CurvScore__c = 75
        );
        insert new List<Opportunity>{opp1, opp2};
    
        stdPbId = Test.getStandardPricebookId();
    
        Quote q1 = new Quote(
            Name='Quote 1', 
            OpportunityId=opp1.Id, 
            Status='Draft', 
            Pricebook2Id=stdPbId,
            RecordTypeId = smallGroupQuoteRTId
        );
        Quote q2 = new Quote(
            Name='Quote 2', 
            OpportunityId=opp2.Id, 
            Status='Draft', 
            Pricebook2Id=stdPbId,
            RecordTypeId = smallGroupQuoteRTId
        );
        insert new List<Quote>{q1, q2};
    
        Product2 p1 = new Product2(Name='Product 1', IsActive=true);
        Product2 p2 = new Product2(Name='Product 2', IsActive=true);
        insert new List<Product2>{p1, p2};
    
        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = p1.Id,
            UnitPrice = 100,
            IsActive = true
        );
        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = p2.Id,
            UnitPrice = 50,
            IsActive = true
        );
        insert new List<PricebookEntry>{pbe1, pbe2};
    
        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = q1.Id,
            PricebookEntryId = pbe1.Id,
            Quantity = 1,
            UnitPrice = 100,
            ARC_EligibleForContract__c = 'Pending'
        );
        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = q2.Id,
            PricebookEntryId = pbe2.Id,
            Quantity = 1,
            UnitPrice = 50,
            ARC_EligibleForContract__c = 'Selected'
        );
        insert new List<QuoteLineItem>{qli1, qli2};
    }

    @IsTest
    static void testBeforeUpdateValidation() {
        
        Id smallGroupRTId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Quote'
            AND DeveloperName = 'SmallGroupQuote'
            LIMIT 1
        ].Id;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Date requestedDate = Date.today().addMonths(2);
        Date oeEndDate = requestedDate.addDays(-15);
        Date oeStartDate = oeEndDate.addDays(-30);

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            ARC_CurvScore__c = 85,
            ARC_RequestedEffectiveDate__c = requestedDate,
            ARC_OEStartDate__c = oeStartDate,
            ARC_OEEndDate__c = oeEndDate
        );
        insert opp;

        Id stdPbId = Test.getStandardPricebookId();

        Quote q = new Quote(
            Name = 'Validation Quote',
            Status = 'Draft',
            RecordTypeId = smallGroupRTId,
            OpportunityId = opp.Id,
            Pricebook2Id = stdPbId
        );
        insert q;

        Product2 p = new Product2(Name = 'Product', IsActive = true);
        insert p;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = p.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            ARC_EligibleForContract__c = 'Pending'
        );
        insert qli;

        q.Status = 'Accepted';
        Test.startTest();
        Database.SaveResult sr = Database.update(q, false);
        Test.stopTest();

        System.assert(
            !sr.isSuccess(),
            'Expected validation error'
        );
        
        Boolean foundValidationMessage = false;
        for (Database.Error err : sr.getErrors()) {
            String message = err.getMessage();
            if (message.contains('Quote Status') || message.contains('Pending')) {
                foundValidationMessage = true;
                break;
            }
        }
        System.assert(
            foundValidationMessage,
            'Should show error for line items with Pending status'
        );
    }

    @IsTest
    static void testAfterUpdateCreatesContractAndCLI() {

        Id smallGroupRTId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Quote'
            AND DeveloperName = 'SmallGroupQuote'
            LIMIT 1
        ].Id;

        Id sgOppRTId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Opportunity'
            AND DeveloperName = 'ARC_SmallGroup'
            LIMIT 1
        ].Id;

        Account acc = new Account(Name = 'Account With Contract');
        insert acc;

        Date requestedDate = Date.today().addMonths(2);
        Date oeEndDate = requestedDate.addDays(-15);
        Date oeStartDate = oeEndDate.addDays(-30);

        Opportunity opp = new Opportunity(
            Name = 'Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            ARC_CurvScore__c = 85,
            ARC_RequestedEffectiveDate__c = requestedDate,
            ARC_OEStartDate__c = oeStartDate,
            ARC_OEEndDate__c = oeEndDate,
            RecordTypeId = sgOppRTId
        );
        insert opp;

        Id stdPbId = Test.getStandardPricebookId();

        Quote q = new Quote(
            Name = 'Accepted Quote',
            Status = 'Draft',
            RecordTypeId = smallGroupRTId,
            OpportunityId = opp.Id,
            Pricebook2Id = stdPbId
        );
        insert q;

        Product2 p = new Product2(Name = 'Product', IsActive = true);
        insert p;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = p.Id,
            UnitPrice = 50,
            IsActive = true
        );
        insert pbe;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 50,
            ARC_EligibleForContract__c = 'Selected'
        );
        insert qli;

        vlocity_ins__GroupCensus__c gc = new vlocity_ins__GroupCensus__c(
            vlocity_ins__GroupId__c = acc.Id,
            Name = 'Test Census'
        );
        insert gc;

        q.Status = 'Accepted';

        Test.startTest();
        update q;
        Test.stopTest();

        List<Contract> contracts = [
            SELECT Id, AccountId, ARC_ContractReason__c
            FROM Contract
            WHERE AccountId = :acc.Id
        ];
        System.assertEquals(1, contracts.size(), 'Should create one contract');
        System.assertEquals('New Enrollment', contracts[0].ARC_ContractReason__c);

        List<vlocity_ins__ContractLineItem__c> clis = [
            SELECT Id, vlocity_ins__ContractId__c
            FROM vlocity_ins__ContractLineItem__c
        ];
        System.assertEquals(1, clis.size());
        System.assertEquals(
            contracts[0].Id,
            clis[0].vlocity_ins__ContractId__c
        );
    }

    @IsTest
    static void testRenewalOpportunityWithoutCurvScore() {
        Id smallGroupRTId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Quote'
            AND DeveloperName = 'SmallGroupQuote'
            LIMIT 1
        ].Id;

        Id renewalOppRTId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Opportunity'
            AND DeveloperName = 'ARC_Renewal'
            LIMIT 1
        ].Id;

        Account acc = new Account(Name = 'Renewal Account');
        insert acc;

        Date requestedDate = Date.today().addMonths(2);
        Date oeEndDate = requestedDate.addDays(-15);
        Date oeStartDate = oeEndDate.addDays(-30);

        Opportunity opp = new Opportunity(
            Name = 'Renewal Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            RecordTypeId = renewalOppRTId,
            ARC_CurvScore__c = null,
            ARC_RequestedEffectiveDate__c = requestedDate,
            ARC_OEStartDate__c = oeStartDate,
            ARC_OEEndDate__c = oeEndDate
        );
        insert opp;

        Id stdPbId = Test.getStandardPricebookId();

        Quote q = new Quote(
            Name = 'Renewal Quote',
            Status = 'Draft',
            RecordTypeId = smallGroupRTId,
            OpportunityId = opp.Id,
            Pricebook2Id = stdPbId
        );
        insert q;

        Product2 p = new Product2(Name = 'Product', IsActive = true);
        insert p;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = p.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            ARC_EligibleForContract__c = 'Selected'
        );
        insert qli;

        q.Status = 'Accepted';
        
        Test.startTest();
        Database.SaveResult sr = Database.update(q, false);
        Test.stopTest();

        System.assert(!sr.isSuccess(), 'Should fail when Curv Score is missing for renewal opportunity');
        
        Boolean foundCurvError = false;
        for (Database.Error err : sr.getErrors()) {
            if (err.getMessage().contains('Curv Score')) {
                foundCurvError = true;
                break;
            }
        }
        System.assert(
            foundCurvError,
            'Should show error related to Curv Score'
        );
    }

    @IsTest
    static void testRenewalWithCompleteData() {
        Id smallGroupRTId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Quote'
            AND DeveloperName = 'SmallGroupQuote'
            LIMIT 1
        ].Id;

        Id renewalOppRTId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Opportunity'
            AND DeveloperName = 'ARC_Renewal'
            LIMIT 1
        ].Id;

        Id contractRTId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Contract'
            AND DeveloperName = 'ARC_SmallGroup'
            LIMIT 1
        ].Id;

        Account acc = new Account(Name = 'Complete Renewal Account');
        insert acc;

        Contract activeContract = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            RecordTypeId = contractRTId,
            ARC_ContractReason__c = 'New Enrollment',
            ARC_PaymentFrequency__c = 'Monthly'
        );
        insert activeContract;


        ChargentOrders__ChargentOrder__c existingOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c = acc.Id,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ARC_Contract__c = activeContract.Id,
            ChargentOrders__Description__c = 'Recurring Monthly Order'
        );
        insert existingOrder;

        activeContract.ARC_RecurringMonthlyOrder__c = existingOrder.Id;
        activeContract.Status = 'Activated';
        update activeContract;

        Date requestedEffectiveDate = Date.today().addMonths(2);
        Date oeEndDate = requestedEffectiveDate.addDays(-15); 
        Date oeStartDate = oeEndDate.addDays(-30);

        Opportunity opp = new Opportunity(
            Name = 'Complete Renewal Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            RecordTypeId = renewalOppRTId,
            ARC_CurvScore__c = 90,
            ARC_RequestedEffectiveDate__c = requestedEffectiveDate,
            ARC_OEStartDate__c = oeStartDate,
            ARC_OEEndDate__c = oeEndDate
        );
        insert opp;

        Id stdPbId = Test.getStandardPricebookId();

        Quote q = new Quote(
            Name = 'Complete Renewal Quote',
            Status = 'Draft',
            RecordTypeId = smallGroupRTId,
            OpportunityId = opp.Id,
            Pricebook2Id = stdPbId
        );
        insert q;

        Product2 p = new Product2(Name = 'Product', IsActive = true);
        insert p;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = p.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            ARC_EligibleForContract__c = 'Selected'
        );
        insert qli;

        vlocity_ins__GroupCensus__c gc = new vlocity_ins__GroupCensus__c(
            vlocity_ins__GroupId__c = acc.Id,
            Name = 'Test Census'
        );
        insert gc;

        q.Status = 'Accepted';
        
        Test.startTest();
        update q;
        Test.stopTest();

        List<Contract> contracts = [
            SELECT Id, Status, ARC_ContractReason__c, ARC_CurvScore__c
            FROM Contract
            WHERE AccountId = :acc.Id
            AND ARC_ContractReason__c = 'Renewal'
        ];
        System.assertEquals(1, contracts.size(), 'Should create a renewal contract');
        System.assertEquals(90, contracts[0].ARC_CurvScore__c);
        System.assertEquals('Draft', contracts[0].Status);
        
        List<ChargentOrders__ChargentOrder__c> renewalOrders = [
            SELECT Id, ARC_Contract__c, ChargentOrders__Account__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ARC_Contract__c = :contracts[0].Id
        ];
        System.assertEquals(1, renewalOrders.size(), 'Should create a ChargentOrder for renewal');
    }

    @IsTest
    static void testQuoteWithExistingContractId() {
        Id smallGroupRTId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Quote'
            AND DeveloperName = 'SmallGroupQuote'
            LIMIT 1
        ].Id;

        Id contractRTId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Contract'
            AND DeveloperName = 'ARC_SmallGroup'
            LIMIT 1
        ].Id;

        Account acc = new Account(Name = 'Existing Contract Account');
        insert acc;

        Date requestedDate = Date.today().addMonths(2);

        Opportunity opp = new Opportunity(
            Name = 'Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            ARC_CurvScore__c = 85,
            ARC_RequestedEffectiveDate__c = requestedDate
        );
        insert opp;

        Contract existingContract = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            RecordTypeId = contractRTId,
            ARC_ContractReason__c = 'New Enrollment',
            ARC_PaymentFrequency__c = 'Monthly'
        );
        insert existingContract;

        Id stdPbId = Test.getStandardPricebookId();

        Quote q = new Quote(
            Name = 'Quote With Contract',
            Status = 'Draft',
            RecordTypeId = smallGroupRTId,
            OpportunityId = opp.Id,
            Pricebook2Id = stdPbId,
            ContractId = existingContract.Id
        );
        insert q;

        Product2 p = new Product2(Name = 'Product', IsActive = true);
        insert p;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id = p.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            ARC_EligibleForContract__c = 'Selected'
        );
        insert qli;

        q.Status = 'Accepted';
        
        Test.startTest();
        update q;  
        Test.stopTest();

        List<Contract> contracts = [
            SELECT Id
            FROM Contract
            WHERE AccountId = :acc.Id
        ];
        System.assertEquals(1, contracts.size(), 'Should not create a duplicate contract');
        
        Quote updatedQuote = [SELECT ContractId FROM Quote WHERE Id = :q.Id];
        System.assertEquals(existingContract.Id, updatedQuote.ContractId);
    }
}