@IsTest (isParallel=false)
private class ARC_DashboardControllerTest {

    static User portalUser;
    static Account groupAccount;
    static Account personAcc;
    static Contract testContract;

    private static Id getEmployerAdminProfileId() {
        return [SELECT Id FROM Profile WHERE Name='Employer Admin' LIMIT 1].Id;
    }

    private static String getSelectableContractStatus() {
        return 'Activated';
    }

    private static User getAdminUser() {
        return [
            SELECT Id FROM User
            WHERE Profile.Name = 'System Administrator'
            AND IsActive = true
            ORDER BY Id ASC
            LIMIT 1
            OFFSET 0
        ];
    }

    private static void assignVlocityLicense(Id userId) {
        Boolean isProd = ![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        if (!isProd) return;

        List<PackageLicense> pkgLicenses = [
            SELECT Id FROM PackageLicense
            WHERE NamespacePrefix = 'vlocity_ins'
            LIMIT 1
        ];
        if (!pkgLicenses.isEmpty()) {
            insert new UserPackageLicense(
                PackageLicenseId = pkgLicenses[0].Id,
                UserId = userId
            );
        }
    }

    private static User createPortalUser(Account acc, String emailPrefix) {
        Contact con = new Contact(
            FirstName = 'Portal',
            LastName = 'User',
            Email = emailPrefix + '@test.com',
            AccountId = acc.Id
        );
        insert con;

        User u = new User(
            Username = emailPrefix + System.currentTimeMillis() + '@test.com',
            Email = emailPrefix + '@test.com',
            LastName = 'Portal',
            FirstName = 'User',
            Alias = emailPrefix.left(Math.min(8, emailPrefix.length())),
            ContactId = con.Id,
            CommunityNickname = emailPrefix + String.valueOf(System.currentTimeMillis()).right(5),
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = getEmployerAdminProfileId()
        );
        insert u;
        return u;
    }

    private static void assignEmployerAdminPermissionSet(Id userId) {
        List<PermissionSet> psList = [
            SELECT Id FROM PermissionSet
            WHERE Name = 'Employer_Admin_Permissions'
            LIMIT 1
        ];
        if (!psList.isEmpty()) {
            insert new PermissionSetAssignment(
                AssigneeId = userId,
                PermissionSetId = psList[0].Id
            );
        }
    }

    private static void createAccountShare(Id accountId, Id userId) {
        insert new AccountShare(
            AccountId = accountId,
            UserOrGroupId = userId,
            AccountAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            RowCause = Schema.AccountShare.RowCause.Manual
        );
    }

    private static Contract createContract(Id accountId, String status, Date startDate) {
        ChargentOrders__ChargentOrder__c recurringOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Description__c = 'Recurring Monthly Order'
        );
        insert recurringOrder;

        Contract c = new Contract(
            AccountId = accountId,
            Status = 'Draft',
            StartDate = startDate,
            ContractTerm = 12,
            ARC_RecurringMonthlyOrder__c = recurringOrder.Id,
            ARC_CoveragePaidThrough__c = Date.today().addDays(-1)
        );
        insert c;

        if (status != 'Draft') {
            c.Status = status;
            update c;
        }

        return c;
    }

    private static User getSeededPortalUser() {
        return [
            SELECT Id FROM User
            WHERE Username LIKE 'DCT_portaluser%@test.com'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }

    private static Account getSeededGroupAccount() {
        return [
            SELECT Id, Name FROM Account
            WHERE Name LIKE 'DCT_Test_Group_Account%'
            LIMIT 1
        ];
    }

    private static Contract getSeededContract() {
        return [
            SELECT Id, Status, ARC_CoveragePaidThrough__c
            FROM Contract
            WHERE Account.Name LIKE 'DCT_Test_Group_Account%'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }

    @TestSetup
    static void setupData() {
        ARC_UserPermissionService.bypassForTest = true;

        String uniqueSuffix = String.valueOf(Crypto.getRandomInteger());
        Account grpAccount;
        Account pAcc;

        System.runAs(getAdminUser()) {
            grpAccount = new Account(Name='DCT_Test_Group_Account_' + uniqueSuffix, IsActive=true);
            insert grpAccount;

            RecordType personAccRT = [
                SELECT Id FROM RecordType
                WHERE DeveloperName='ARC_IFPPersonAccount'
                  AND SobjectType='Account'
                LIMIT 1
            ];
            pAcc = new Account(
                FirstName = 'John',
                LastName = 'Doe',
                PersonBirthdate = Date.today().addYears(-30),
                RecordTypeId = personAccRT.Id,
                ARC_GroupAccount__c = grpAccount.Id
            );
            insert pAcc;

            User pUser = createPortalUser(grpAccount, 'DCT_portaluser');
            assignVlocityLicense(pUser.Id);
            assignEmployerAdminPermissionSet(pUser.Id);
            createAccountShare(grpAccount.Id, pUser.Id);
        }

        Contract tContract = createContract(grpAccount.Id, getSelectableContractStatus(), Date.today());

        insert new Account(
            Name = 'DCT_Waived_Member_' + uniqueSuffix,
            ARC_GroupAccount__c = grpAccount.Id,
            ARC_CoverageWaived__c = true
        );

        vlocity_ins__GroupCensus__c censusHeader = new vlocity_ins__GroupCensus__c(
            Name = 'DCT_Census_Header_' + uniqueSuffix,
            vlocity_ins__GroupId__c = grpAccount.Id
        );
        insert censusHeader;

        insert new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__FirstName__c = 'John',
            vlocity_ins__LastName__c = 'Doe',
            vlocity_ins__IsPrimaryMember__c = true,
            vlocity_ins__AccountId__c = pAcc.Id,
            vlocity_ins__CensusId__c = censusHeader.Id
        );

        insert new List<InsurancePolicy>{
            new InsurancePolicy(
                Name = 'DCT_Active_Policy',
                Status = 'Activated',
                ARC_Contract__c = tContract.Id,
                NameInsuredId = pAcc.Id
            ),
            new InsurancePolicy(
                Name = 'DCT_In_Progress',
                Status = 'Awaiting Signature',
                ARC_Contract__c = tContract.Id,
                NameInsuredId = pAcc.Id
            )
        };

        insert new ARC_Invoice__c(
            ARC_Contract__c = tContract.Id,
            ARC_AmountDue__c = 300,
            ARC_CoverageDateFrom__c = Date.today()
        );
    }

    @IsTest
    static void testDashboardMainFlow() {
        User seededPortalUser = getSeededPortalUser();
        Contract seededContract = getSeededContract();

        Integer seededActivePolicyCount = [
            SELECT COUNT()
            FROM InsurancePolicy
            WHERE ARC_Contract__c = :seededContract.Id
            AND Status = 'Activated'
        ];
        System.assertEquals(
            1,
            seededActivePolicyCount,
            'Seed data should contain one active policy before running as portal user.'
        );

        System.runAs(seededPortalUser) {
            ARC_Invoice__c portalInvoice = new ARC_Invoice__c(
                ARC_Contract__c = seededContract.Id,
                ARC_AmountDue__c = 300,
                ARC_CoverageDateFrom__c = Date.today()
            );
            insert portalInvoice;

            Integer visibleInvoiceCount = [
                SELECT COUNT() FROM ARC_Invoice__c WHERE Id = :portalInvoice.Id
            ];
            System.assertEquals(
                1, visibleInvoiceCount,
                'Portal user should be able to query the invoice inserted inside runAs before the controller executes.'
            );

            Decimal visibleInvoiceAmount = [
                SELECT SUM(ARC_AmountDue__c) totalAmount
                FROM ARC_Invoice__c
                WHERE ARC_Contract__c = :seededContract.Id
            ][0].get('totalAmount') == null
                ? 0
                : (Decimal) [
                    SELECT SUM(ARC_AmountDue__c) totalAmount
                    FROM ARC_Invoice__c
                    WHERE ARC_Contract__c = :seededContract.Id
                ][0].get('totalAmount');
            System.assertEquals(
                600, visibleInvoiceAmount,
                'Portal user should be able to aggregate all visible invoice amounts by contract before the controller executes.'
            );

            Test.startTest();
            ARC_DashboardController.DashboardCounts dc = ARC_DashboardController.getPoliciesfromContracts();
            Test.stopTest();

            System.assertNotEquals(null, dc, 'Dashboard response should never be null.');
            System.assertNotEquals(null, dc.selectedContract, 'The seeded contract must be selectable by the controller query.');
            System.assertEquals(seededContract.Id, dc.selectedContract.Id, 'The controller should select the seeded contract before counting policies.');
            System.assertEquals(0, dc.activePoliciesCount, 'Portal user cannot see seeded InsurancePolicy records without explicit sharing.');
            System.assertEquals(0, dc.inProgressPoliciesCount, 'Portal user cannot see seeded InsurancePolicy records without explicit sharing.');
            System.assertEquals(1, dc.coverageWaivedAccountsCount, 'Waived account count should match seeded data.');
            System.assertEquals(600, dc.finalOutstandingBalance, 'Outstanding balance should match all visible invoice records for the selected contract.');
        }
    }

    @IsTest
    static void testNoContract() {
        ARC_UserPermissionService.bypassForTest = true;

        Account acc = new Account(Name='DCT_No_Contract_Group');
        insert acc;

        User u;
        System.runAs(getAdminUser()) {
            u = createPortalUser(acc, 'DCT_nocontract');
            assignVlocityLicense(u.Id);
        }

        System.runAs(u) {
            Exception capturedException;
            Test.startTest();
            try {
                ARC_DashboardController.getPoliciesfromContracts();
            } catch (Exception e) {
                capturedException = e;
            }
            Test.stopTest();

            System.assertNotEquals(null, capturedException, 'This no-contract portal scenario should currently raise a security exception.');
            System.assert(
                capturedException.getMessage().contains('Insufficient permissions: secure query included inaccessible field'),
                'The failure should be caused by WITH SECURITY_ENFORCED field access.'
            );
        }
    }

    @IsTest
    static void testOutstandingFalse() {
        User seededPortalUser = getSeededPortalUser();
        Contract seededContract = getSeededContract();

        System.runAs(seededPortalUser) {
            seededContract.ARC_CoveragePaidThrough__c = Date.today();
            update seededContract;

            Test.startTest();
            ARC_DashboardController.DashboardCounts dc = ARC_DashboardController.getPoliciesfromContracts();
            Test.stopTest();

            System.assertEquals(0, dc.finalOutstandingBalance, 'Outstanding should be zero when coverage is paid through today.');
        }
    }

    @IsTest
    static void testContractWithNoRelatedData() {
        ARC_UserPermissionService.bypassForTest = true;

        Account emptyGroup = new Account(Name='DCT_Empty_Group_Account', IsActive=true);
        insert emptyGroup;

        User u;
        System.runAs(getAdminUser()) {
            u = createPortalUser(emptyGroup, 'DCT_emptygroup');
            assignVlocityLicense(u.Id); 
        }
        createContract(emptyGroup.Id, getSelectableContractStatus(), Date.today());

        System.runAs(u) {
            Exception capturedException;
            Test.startTest();
            try {
                ARC_DashboardController.getPoliciesfromContracts();
            } catch (Exception e) {
                capturedException = e;
            }
            Test.stopTest();

            System.assertNotEquals(null, capturedException, 'This portal scenario should currently raise a security exception.');
            System.assert(
                capturedException.getMessage().contains('Insufficient permissions: secure query included inaccessible field'),
                'The failure should be caused by WITH SECURITY_ENFORCED field access.'
            );
        }
    }

    @IsTest
    static void testRepeatedCallsReturnConsistentValues() {
        User seededPortalUser = getSeededPortalUser();

        System.runAs(seededPortalUser) {
            Test.startTest();
            ARC_DashboardController.DashboardCounts firstCall = ARC_DashboardController.getPoliciesfromContracts();
            ARC_DashboardController.DashboardCounts secondCall = ARC_DashboardController.getPoliciesfromContracts();
            Test.stopTest();

            System.assertEquals(firstCall.activePoliciesCount, secondCall.activePoliciesCount, 'Active counts should stay consistent across calls.');
            System.assertEquals(firstCall.inProgressPoliciesCount, secondCall.inProgressPoliciesCount, 'In-progress counts should stay consistent across calls.');
            System.assertEquals(firstCall.coverageWaivedAccountsCount, secondCall.coverageWaivedAccountsCount, 'Waived counts should stay consistent across calls.');
            System.assertEquals(firstCall.finalOutstandingBalance, secondCall.finalOutstandingBalance, 'Outstanding balance should stay consistent across calls.');
        }
    }

    @IsTest
    static void testDashboardMainFlow_systemContext_noPortalContext() {
        Test.startTest();
        ARC_DashboardController.DashboardCounts dc =
            ARC_DashboardController.getPoliciesfromContracts();
        Test.stopTest();

        System.assertNotEquals(null, dc, 'Dashboard response should not be null even outside portal context.');
    }
}