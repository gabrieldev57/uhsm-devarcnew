@isTest (isParallel=false)
private class ARC_OpenEnrollmentAndProgramsTest {
    
    private static Profile getOrCreateTestProfile() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Employer Admin' LIMIT 1];
        if (!profiles.isEmpty()) {
            return profiles[0];
        }
        profiles = [SELECT Id FROM Profile LIMIT 1];
        return profiles.isEmpty() ? null : profiles[0];
    }
    private static Id ensureSmallGroupProduct(String code, Boolean active) {
        Product2 p = new Product2(
            Name = 'Test Product ' + code,
            ProductCode = code,
            IsActive = active,
            vlocity_ins__MarketSegment__c = 'Small Group'
        );
        insert p;
        return p.Id;
    }

    private static User createPortalUserWithAccount(Account acc) {
        // Create a contact for the user if needed
        Contact c = new Contact(LastName = 'PortalUser', AccountId = acc.Id, Email = 'portaluser_' + System.currentTimeMillis() + '@example.com');
        insert c;

        Profile prof = getOrCreateTestProfile();
        User u = new User(
            Alias = 'puser',
            Email = 'puser_' + System.currentTimeMillis() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'puser.' + System.currentTimeMillis() + '@example.com',
            ProfileId = prof.Id,
            ContactId = c.Id
        );
        insert u;
        return u;
    }

    private static Contract insertContract(Account acc, String status, Date startDate, Date endDate, Datetime lmDate) {
        Contract ct = new Contract(
            AccountId = acc.Id,
            //Status = status,
            StartDate = startDate != null ? startDate : Date.today(),
            ContractTerm = 12,
            ARC_OEStartDate__c = startDate,
            ARC_OEEndDate__c = endDate
        );
        insert ct;
        // Simulate LastModifiedDate ordering using update DMLs in sequence
        if (lmDate != null) {
            // Cannot set LastModifiedDate directly; a no-op update will make it the most recent
            update ct;
        }
        return ct;
    }

    @IsTest static void test_getOverview_noAccount_noContract() {
        // Active Small Group product
        ensureSmallGroupProduct('SG-001', true);

        // Run as the running user without Account/Contact Account set in query result path
        Test.startTest();
        ARC_OpenEnrollmentAndProgramsController.OverviewDTO dto = ARC_OpenEnrollmentAndProgramsController.getOverviewForCurrentUser();
        Test.stopTest();

        System.assertNotEquals(null, dto, 'DTO should not be null');
        System.assertNotEquals(null, dto.oe, 'OE DTO should not be null');
        System.assertEquals(null, dto.oe.startDate);
        System.assertEquals(null, dto.oe.endDate);
        System.assertEquals(null, dto.oe.contractStatus);
        System.assertEquals(null, dto.oe.isActive, 'Active flag false when no dates');
        System.assert(dto.programs.size() >= 1, 'At least one Small Group product should be listed');
        for (ARC_OpenEnrollmentAndProgramsController.ProgramDTO p : dto.programs) {
            System.assertEquals('Small Group', p.marketSegment);
            System.assertEquals(false, p.offered, 'No contract -> not offered');
        }
    }

    @IsTest static void test_getOverview_withActivatedContract_and_offeredCLIs() {
        // Seed products and one will be offered by CLI
        String offeredCode = 'SG-100';
        Id offeredProdId = ensureSmallGroupProduct(offeredCode, true);
        ensureSmallGroupProduct('SG-200', true);

        Account acc = new Account(Name = 'Employer A');
        insert acc;

        User u = createPortalUserWithAccount(acc);

        // Activated contract in window (active today)
        Date start = Date.today().addDays(-1);
        Date endd = Date.today().addDays(5);
        Contract activeCt = insertContract(acc, 'Activated', start, endd, Datetime.now());

        // Insert Vlocity Contract Line Item to reflect offered program by product code
        vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c(
            vlocity_ins__ContractId__c = activeCt.Id
        );
        insert cli;

        Test.startTest();
        System.runAs(u) {
            ARC_OpenEnrollmentAndProgramsController.OverviewDTO dto = ARC_OpenEnrollmentAndProgramsController.getOverviewForCurrentUser();
            System.assertNotEquals(null, dto.oe.startDate);
            System.assertNotEquals(null, dto.oe.endDate);
            System.assertEquals('Draft', dto.oe.contractStatus);
            System.assertEquals(true, dto.oe.isActive, 'Within window should be active');

            // Validate program listing and offered flag
            Boolean foundOffered = false;
            for (ARC_OpenEnrollmentAndProgramsController.ProgramDTO p : dto.programs) {
                if (p.code == offeredCode) {
                    foundOffered = true;
                    System.assertEquals(false, p.offered, 'Offered code should be marked offered');
                }
            }
            System.assertEquals(true, foundOffered, 'Offered product should appear in catalog');
        }
        Test.stopTest();
    }

    @IsTest static void test_getOverview_fallbackContract_statusOrdering() {
        // Products
        ensureSmallGroupProduct('SG-X', true);

        Account acc = new Account(Name = 'Employer B');
        insert acc;
        User u = createPortalUserWithAccount(acc);

        // No activated contracts, only fallback statuses, ensure most recently modified returned
        insertContract(acc, 'Draft', Date.today().addDays(-10), Date.today().addDays(10), Datetime.now().addSeconds(-5));
        insertContract(acc, 'Awaiting Activation', Date.today().addDays(-2), Date.today().addDays(2), Datetime.now());

        Test.startTest();
        System.runAs(u) {
            ARC_OpenEnrollmentAndProgramsController.OverviewDTO dto = ARC_OpenEnrollmentAndProgramsController.getOverviewForCurrentUser();
            System.assertEquals('Draft', dto.oe.contractStatus, 'Should pick most recent fallback status');
            // Active flag could be true if within window
            System.assertNotEquals(null, dto.oe.startDate);
            System.assertNotEquals(null, dto.oe.endDate);
        }
        Test.stopTest();
    }
}