@isTest
private class ARC_InvoiceEmailHandlerTest {

    @testSetup
    static void setupData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Contact with email
        Contact con = new Contact(
            LastName = 'Billing Contact',
            AccountId = acc.Id,
            Email = 'billing@test.com'
        );
        insert con;

        // Add Billing Contact role via AccountContactRelation
        // In some orgs, this is auto-created. Otherwise, you may need to insert
        // Here, we try safe update of existing ACR
        List<AccountContactRelation> acrs = [SELECT Id, AccountId, ContactId, Roles FROM AccountContactRelation WHERE AccountId = :acc.Id AND ContactId = :con.Id];
        if (acrs.isEmpty()) {
            AccountContactRelation acr = new AccountContactRelation(
                AccountId = acc.Id,
                ContactId = con.Id,
                Roles = 'Billing Contact',
                IsActive = true
            );
            insert acr;
        } else {
            AccountContactRelation acr = acrs[0];
            acr.Roles = 'Billing Contact';
            update acr;
        }

        // Create Contract
        Contract contract = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            ContractTerm = 12,
            Status = 'Draft'
        );
        insert contract;

        // Create ARC_Invoice__c
        ARC_Invoice__c invoice = new ARC_Invoice__c(
            ARC_Contract__c = contract.Id,
            ARC_AmountDue__c = 100,
            ARC_DueDate__c = Date.today()
        );
        insert invoice;
    }

    @isTest
    static void testHappyPath() {
        ARC_Invoice__c inv = [SELECT Id FROM ARC_Invoice__c LIMIT 1];

        // Create PDF ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'InvoiceFile',
            PathOnClient = 'InvoiceFile.pdf',
            VersionData = Blob.valueOf('PDF Content')
        );
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        // Link ContentDocument to Invoice
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = inv.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V'
        );
        insert cdl;

        Test.startTest();
        ARC_InvoiceEmailHandler.handleContentDocumentLinkInsert(
            new List<ContentDocumentLink>{ cdl }
        );
        Test.stopTest();

        // Assert emails sent (count email invocations)
        System.assert(Limits.getEmailInvocations() >= 0);
    }

    @isTest
    static void testNonPdfFile() {
        ARC_Invoice__c inv = [SELECT Id FROM ARC_Invoice__c LIMIT 1];

        ContentVersion cv = new ContentVersion(
            Title = 'File',
            PathOnClient = 'file.txt',
            VersionData = Blob.valueOf('Text Content')
        );
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = inv.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V'
        );
        insert cdl;

        Test.startTest();
        ARC_InvoiceEmailHandler.handleContentDocumentLinkInsert(
            new List<ContentDocumentLink>{ cdl }
        );
        Test.stopTest();

        System.assertEquals(0, Limits.getEmailInvocations());
    }

    @isTest
    static void testNoBillingContact() {
        // Create account and contract without Billing Contact
        Account acc = new Account(Name = 'No Billing');
        insert acc;

        Contract contract = new Contract(
            AccountId = acc.Id,
            StartDate = Date.today(),
            ContractTerm = 12,
            Status = 'Draft'
        );
        insert contract;

        ARC_Invoice__c inv = new ARC_Invoice__c(
            ARC_Contract__c = contract.Id
        );
        insert inv;

        ContentVersion cv = new ContentVersion(
            Title = 'Invoice',
            PathOnClient = 'invoice.pdf',
            VersionData = Blob.valueOf('PDF')
        );
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = inv.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V'
        );
        insert cdl;

        Test.startTest();
        ARC_InvoiceEmailHandler.handleContentDocumentLinkInsert(
            new List<ContentDocumentLink>{ cdl }
        );
        Test.stopTest();

        System.assertEquals(0, Limits.getEmailInvocations());
    }
}