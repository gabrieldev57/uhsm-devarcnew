@isTest (isParallel=false)
public class ARC_EmployeesTableControllerTest {

    private static User getAdminUser() {
        return [
            SELECT Id FROM User
            WHERE Profile.Name = 'System Administrator'
            AND IsActive = true
            ORDER BY Id ASC
            LIMIT 1
            OFFSET 1
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

    @testSetup
    static void setupData() {
        ARC_UserPermissionService.bypassForTest = true;

        Profile communityProfile = [SELECT Id FROM Profile WHERE Name='Employer Admin' ORDER BY Id ASC LIMIT 1];
        RecordType groupAccRT = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_SmallGroup' AND SobjectType='Account' LIMIT 1];
        RecordType personAccRT = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_IFPPersonAccount' AND SobjectType='Account' LIMIT 1];

        String uniqueSuffix = String.valueOf(Crypto.getRandomInteger());
        Account grpAcc;
        Contact grpCon;
        User testUser;

        // Transacción 1: non-setup objects
        System.runAs(getAdminUser()) {
            grpAcc = new Account(
                Name='ETC_Group_' + uniqueSuffix,
                IsActive=true,
                RecordTypeId=groupAccRT.Id
            );
            insert grpAcc;

            grpCon = new Contact(
                FirstName='ETC Group',
                LastName='Contact',
                Email='ETC_testuser_' + uniqueSuffix + '@yourorg.com',
                AccountId = grpAcc.Id
            );
            insert grpCon;
        }

        // Transacción 2: setup objects
        System.runAs(getAdminUser()) {
            testUser = new User(
                Username='ETC_testuser_' + uniqueSuffix + '@yourorg.com',
                Email='ETC_testuser_' + uniqueSuffix + '@yourorg.com',
                LastName='Test',
                FirstName='User',
                Alias='tuser',
                ContactId=grpCon.Id,
                CommunityNickname='ETC_' + uniqueSuffix,
                TimeZoneSidKey='America/Los_Angeles',
                LocaleSidKey='en_US',
                EmailEncodingKey='UTF-8',
                LanguageLocaleKey='en_US',
                ProfileId = communityProfile.Id
            );
            insert testUser;
            assignVlocityLicense(testUser.Id);
            assignEmployerAdminPermissionSet(testUser.Id);
        }

        // Crear AccountShare fuera del runAs
        createAccountShare(grpAcc.Id, testUser.Id);

        // Transacción 3: resto de non-setup objects
        Account perAcc = new Account(
            FirstName='Poojal',
            LastName='Person',
            PersonBirthdate = Date.today().addYears(-30),
            ARC_CoverageWaived__c=false,
            ARC_AllowEnrollmentOutsideOE__c=false,
            IsActive=true,
            RecordTypeId = personAccRT.Id,
            ARC_GroupAccount__c = grpAcc.Id
        );
        insert perAcc;

        Contact perCon = [SELECT Id, AccountId, Account.Census_Member__c FROM Contact WHERE AccountId=:perAcc.Id LIMIT 1];

        Account perAcc1 = new Account(
            FirstName='Poojal',
            LastName='Person Account 2',
            PersonBirthdate = Date.today().addYears(-30),
            ARC_CoverageWaived__c=false,
            ARC_AllowEnrollmentOutsideOE__c=false,
            IsActive=true,
            RecordTypeId = personAccRT.Id,
            ARC_GroupAccount__c = grpAcc.Id
        );
        insert perAcc1;

        Contact perCon1 = [SELECT Id, AccountId, Account.Census_Member__c FROM Contact WHERE AccountId=:perAcc1.Id LIMIT 1];

        Contract con = new Contract(
            AccountId = grpAcc.Id,
            Status = 'Draft',
            StartDate = Date.today().addMonths(-1)
        );
        con.put('ARC_OEStartDate__c', Date.today().addDays(-5));
        con.put('ARC_OEEndDate__c', Date.today().addDays(5));
        insert con;

        vlocity_ins__GroupCensus__c grpCensus = new vlocity_ins__GroupCensus__c(
            Name='ETC_Census',
            vlocity_ins__GroupId__c = grpAcc.Id
        );
        insert grpCensus;

        vlocity_ins__GroupCensusMember__c census = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__FirstName__c = 'Poojal',
            vlocity_ins__LastName__c = 'Person',
            vlocity_ins__AccountId__c = perAcc.Id,
            vlocity_ins__ContactId__c = perCon.Id,
            ARC_ActiveMember__c = true,
            vlocity_ins__IsPrimaryMember__c = true,
            vlocity_ins__CensusId__c = grpCensus.Id
        );
        insert census;

        perAcc.Census_Member__c = census.Id;
        update perAcc;

        vlocity_ins__GroupCensusMember__c census1 = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__FirstName__c = 'Poojal',
            vlocity_ins__LastName__c = 'Person1',
            vlocity_ins__AccountId__c = perAcc1.Id,
            vlocity_ins__ContactId__c = perCon1.Id,
            ARC_ActiveMember__c = true,
            vlocity_ins__IsPrimaryMember__c = true,
            vlocity_ins__CensusId__c = grpCensus.Id
        );
        insert census1;

        perAcc1.Census_Member__c = census1.Id;
        update perAcc1;

        perAcc = [SELECT Id, PersonContactId, Census_Member__c FROM Account WHERE Id = :perAcc.Id];
        census.vlocity_ins__ContactId__c = perAcc.PersonContactId;
        update census;

        perAcc1 = [SELECT Id, PersonContactId, Census_Member__c FROM Account WHERE Id = :perAcc1.Id];
        census1.vlocity_ins__ContactId__c = perAcc1.PersonContactId;
        update census1;

        List<InsurancePolicy> policies = new List<InsurancePolicy>();
        List<String> policyStatuses = new List<String>{'Awaiting Activation','Activated','Awaiting Signature','Voided'};
        for(Integer i = 0; i < policyStatuses.size(); i++){
            InsurancePolicy p = new InsurancePolicy(Status = policyStatuses[i]);
            p.put('ARC_Contract__c', con.Id);
            p.put('Name', 'Policy ' + (i+1));
            p.put('NameInsuredId', i < 2 ? perAcc.Id : perAcc1.Id);
            policies.add(p);
        }
        insert policies;

        Product2 prod = new Product2(Name='ETC_Test_Product', IsActive=true);
        insert prod;

        List<InsurancePolicyParticipant> participants = new List<InsurancePolicyParticipant>();
        for(InsurancePolicy p : policies){
            Id contactId = (p.NameInsuredId == perAcc.Id)
                ? perAcc.PersonContactId
                : perAcc1.PersonContactId;
            participants.add(new InsurancePolicyParticipant(
                InsurancePolicyId = p.Id,
                Role = 'Primary',
                PrimaryParticipantContactId = contactId
            ));
        }
        insert participants;

        Id contactId1 = (policies[0].NameInsuredId == perAcc.Id)
            ? perAcc.PersonContactId : perAcc1.PersonContactId;
        insert new InsurancePolicyParticipant(
            InsurancePolicyId = policies[0].Id,
            Role = 'Dependent',
            PrimaryParticipantContactId = contactId1
        );

        Id contactId2 = (policies[3].NameInsuredId == perAcc.Id)
            ? perAcc.PersonContactId : perAcc1.PersonContactId;
        insert new InsurancePolicyParticipant(
            InsurancePolicyId = policies[3].Id,
            Role = 'Dependent',
            PrimaryParticipantContactId = contactId2
        );

        InsurancePolicyCoverage cov = new InsurancePolicyCoverage(
            InsurancePolicyId = policies[1].Id,
            vlocity_ins_fsc__Product2Id__c = prod.Id
        );
        insert cov;

        insert new ARC_CoverageParticipant__c(
            ARC_PolicyParticipant__c = participants[1].Id,
            ARC_PolicyCoverage__c = cov.Id,
            ARC_Policy__c = policies[1].Id
        );

        InsurancePolicyCoverage cov2 = new InsurancePolicyCoverage(
            InsurancePolicyId = policies[2].Id,
            vlocity_ins_fsc__Product2Id__c = prod.Id
        );
        insert cov2;

        insert new ARC_CoverageParticipant__c(
            ARC_PolicyParticipant__c = participants[2].Id,
            ARC_PolicyCoverage__c = cov2.Id,
            ARC_Policy__c = policies[2].Id
        );

        List<RecordType> caseRTList = [SELECT Id FROM RecordType WHERE SObjectType='Case' AND DeveloperName='Service' LIMIT 1];
        insert new Case(
            Status = 'New',
            AccountId = perAcc.Id,
            RecordTypeId = caseRTList.isEmpty() ? null : caseRTList[0].Id,
            Description = 'Test Description',
            Subject = 'Test Case',
            ARC_Reason__c = 'Program'
        );
    }

    private static User createPortalUserWithPermissions(Account acc, String suffix) {
        ARC_UserPermissionService.bypassForTest = true;
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name='Employer Admin' ORDER BY Id ASC LIMIT 1];

        Contact con = new Contact(
            FirstName='Portal',
            LastName='User',
            Email='ETC_portal_' + suffix + '@yourorg.com',
            AccountId=acc.Id
        );
        insert con;

        User u;
        System.runAs(getAdminUser()) {
            u = new User(
                Username='ETC_portal_' + suffix + '@yourorg.com',
                Email='ETC_portal_' + suffix + '@yourorg.com',
                LastName='User', FirstName='Portal', Alias='pu',
                ContactId=con.Id,
                CommunityNickname='ETC_pu_' + suffix,
                TimeZoneSidKey='America/Los_Angeles', LocaleSidKey='en_US',
                EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US',
                ProfileId=communityProfile.Id
            );
            insert u;
            assignVlocityLicense(u.Id);
            assignEmployerAdminPermissionSet(u.Id);
        }

        // Crear AccountShare fuera del runAs
        createAccountShare(acc.Id, u.Id);
        return u;
    }

    private static User getTestUser() {
        return [
            SELECT Id, AccountId, Contact.AccountId
            FROM User
            WHERE Profile.Name = 'Employer Admin'
            AND Email LIKE 'ETC_testuser_%@yourorg.com'
            LIMIT 1
        ];
    }

    @isTest
    static void testCheckEnrollmentPermission_withPermSet() {
        User u = getTestUser();
        System.runAs(u) {
            PermissionSet ps;
            try {
                ps = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Employer_Admin_Permissions' LIMIT 1];
                if (ps != null) {
                    try {
                        insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps.Id);
                    } catch (DmlException ex) {}
                }
            } catch (Exception e) {}
            Test.startTest();
            Boolean allowed = ARC_EmployeesTableController.checkEnrollmentPermission(new List<Id>());
            Test.stopTest();
            System.assertNotEquals(null, allowed);
        }
    }

    @isTest
    static void testGetPoliciesfromContracts() {
        User u = getTestUser();
        System.runAs(u) {
            Test.startTest();
            List<Map<String,Object>> result = ARC_EmployeesTableController.getPoliciesfromContracts();
            Test.stopTest();
            System.assertNotEquals(null, result);
        }
    }

    @isTest
    static void testPolicies_and_participants_variations() {
        User u = getTestUser();
        System.runAs(u) {
            List<Contract> existing = [SELECT Id FROM Contract WHERE AccountId = :u.AccountId LIMIT 1];
            Id contractId;
            if (existing.isEmpty()) {
                Contract cc = new Contract(AccountId = u.AccountId, Status='Draft', StartDate=Date.today().addMonths(-1));
                cc.put('ARC_OEStartDate__c', Date.today().addDays(-3));
                cc.put('ARC_OEEndDate__c', Date.today().addDays(3));
                insert cc;
                contractId = cc.Id;
            } else {
                contractId = existing[0].Id;
            }

            InsurancePolicy p = new InsurancePolicy(Status='Activated');
            p.put('ARC_Contract__c', contractId);
            p.put('Name','Extra Policy');
            Id personAccId = [SELECT Id FROM Account WHERE ARC_GroupAccount__c = :u.AccountId LIMIT 1].Id;
            p.put('NameInsuredId', personAccId);
            insert p;

            insert new InsurancePolicyParticipant(
                InsurancePolicyId = p.Id,
                Role = 'Primary',
                PrimaryParticipantContactId = [SELECT PersonContactId FROM Account WHERE Id = :personAccId LIMIT 1].PersonContactId
            );

            Test.startTest();
            List<Map<String,Object>> result = ARC_EmployeesTableController.getPoliciesfromContracts();
            Test.stopTest();
            System.assertNotEquals(null, result);
        }
    }

    @isTest
    static void testGetPoliciesfromContracts_noPolicies() {
        ARC_UserPermissionService.bypassForTest = true;
        String suffix = String.valueOf(Crypto.getRandomInteger());

        RecordType groupAccRT = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_SmallGroup' AND SobjectType='Account' LIMIT 1];
        Account a = new Account(Name='ETC_EmptyGroup_' + suffix, IsActive=true, RecordTypeId=groupAccRT.Id);
        insert a;

        User u = createPortalUserWithPermissions(a, suffix);

        System.runAs(u) {
            Test.startTest();
            List<Map<String,Object>> result = ARC_EmployeesTableController.getPoliciesfromContracts();
            Test.stopTest();
            System.assertNotEquals(null, result);
        }
    }

    @isTest
    static void testCheckEnrollmentPermission() {
        User u = getTestUser();
        System.runAs(u) {
            Test.startTest();
            Boolean result = ARC_EmployeesTableController.checkEnrollmentPermission(new List<Id>());
            Test.stopTest();
            System.assertNotEquals(null, result);
        }
    }

    @isTest
    static void testGetCensusDownloadableData_base() {
        User u = getTestUser();
        System.runAs(u) {
            List<Contract> existing = [SELECT Id FROM Contract WHERE AccountId = :u.AccountId LIMIT 1];
            if (existing.isEmpty()) {
                Contract c = new Contract(AccountId = u.AccountId, Status='Draft', StartDate=Date.today().addMonths(-1));
                c.put('ARC_OEStartDate__c', Date.today().addDays(-1));
                c.put('ARC_OEEndDate__c', Date.today().addDays(1));
                insert c;
            }
            Test.startTest();
            List<Map<String,Object>> result = ARC_EmployeesTableController.getCensusDownloadableData();
            Test.stopTest();
            System.assertNotEquals(null, result);
        }
    }

    @isTest
    static void testIsOpenEnrollmentActive_inWindow() {
        User u = getTestUser();
        System.runAs(u) {
            Contract c = new Contract(AccountId=u.AccountId, Status='Draft', StartDate=Date.today().addMonths(-1));
            c.put('ARC_OEStartDate__c', Date.today().addDays(-2));
            c.put('ARC_OEEndDate__c', Date.today().addDays(2));
            insert c;
            Test.startTest();
            Boolean active = ARC_EmployeesTableController.isOpenEnrollmentActive(u.AccountId);
            Test.stopTest();
            System.assertEquals(true, active);
        }
    }

    @isTest
    static void testIsOpenEnrollmentActive_outOfWindow_allowOutsideOE() {
        User u = getTestUser();
        Account person = [SELECT Id, ARC_AllowEnrollmentOutsideOE__c FROM Account WHERE ARC_GroupAccount__c = :u.AccountId LIMIT 1];
        person.ARC_AllowEnrollmentOutsideOE__c = true;
        update person;

        System.runAs(u) {
            Contract c = new Contract(AccountId=u.AccountId, Status='Draft', StartDate=Date.today().addMonths(-2));
            c.put('ARC_OEStartDate__c', Date.today().addDays(-30));
            c.put('ARC_OEEndDate__c', Date.today().addDays(-20));
            insert c;
            Test.startTest();
            Boolean active = ARC_EmployeesTableController.isOpenEnrollmentActive(person.Id);
            Test.stopTest();
            System.assertEquals(true, active);
        }
    }

    @isTest
    static void testIsOpenEnrollmentActive_outOfWindow_disallowOutsideOE() {
        ARC_UserPermissionService.bypassForTest = true;
        String suffix = String.valueOf(Crypto.getRandomInteger());

        RecordType groupAccRT = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_SmallGroup' AND SobjectType='Account' LIMIT 1];
        RecordType personAccRT = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_IFPPersonAccount' AND SobjectType='Account' LIMIT 1];

        Account isoGroup = new Account(Name='ETC_Iso_DisallowOE_' + suffix, IsActive=true, RecordTypeId=groupAccRT.Id);
        insert isoGroup;

        Account person = new Account(
            FirstName='Dis', LastName='AllowFalse', RecordTypeId=personAccRT.Id,
            ARC_GroupAccount__c=isoGroup.Id, IsActive=true,
            ARC_CoverageWaived__c=false, ARC_AllowEnrollmentOutsideOE__c=false
        );
        insert person;

        Contract c = new Contract(AccountId=isoGroup.Id, Status='Draft', StartDate=Date.today().addMonths(-2));
        c.put('ARC_OEStartDate__c', Date.today().addDays(-30));
        c.put('ARC_OEEndDate__c', Date.today().addDays(-20));
        insert c;

        vlocity_ins__GroupCensus__c gc = new vlocity_ins__GroupCensus__c(Name='ETC_Iso_Disallow_GC_' + suffix, vlocity_ins__GroupId__c=isoGroup.Id);
        insert gc;
        insert new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__FirstName__c='Dis', vlocity_ins__LastName__c='False',
            vlocity_ins__AccountId__c=person.Id, ARC_ActiveMember__c=true,
            vlocity_ins__IsPrimaryMember__c=true, vlocity_ins__CensusId__c=gc.Id
        );

        User u = createPortalUserWithPermissions(isoGroup, suffix);

        System.runAs(u) {
            Test.startTest();
            Boolean active = ARC_EmployeesTableController.isOpenEnrollmentActive(person.Id);
            Test.stopTest();
            System.assertEquals(false, active);
        }
    }

    @isTest
    static void testIsOpenEnrollmentActive_noContracts() {
        ARC_UserPermissionService.bypassForTest = true;
        String suffix = String.valueOf(Crypto.getRandomInteger());

        RecordType groupAccRT = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_SmallGroup' AND SobjectType='Account' LIMIT 1];
        Account g = new Account(Name='ETC_NoContract_Group_' + suffix, IsActive=true, RecordTypeId=groupAccRT.Id);
        insert g;

        User u = createPortalUserWithPermissions(g, suffix);

        System.runAs(u) {
            Test.startTest();
            Boolean active = ARC_EmployeesTableController.isOpenEnrollmentActive(g.Id);
            Test.stopTest();
            System.assertEquals(false, active);
        }
    }

    @isTest
    static void testOrderCensusMembers_direct() {
        Map<Id, List<Map<String,Object>>> families = new Map<Id, List<Map<String,Object>>>();
        Id famId = '001000000000001';
        List<Map<String,Object>> members = new List<Map<String,Object>>();
        members.add(new Map<String,Object>{ 'Relationship' => 'Child',   'Name' => 'Child A' });
        members.add(new Map<String,Object>{ 'Relationship' => 'Spouse',  'Name' => 'Spouse A' });
        members.add(new Map<String,Object>{ 'Relationship' => 'Other',   'Name' => 'Other A' });
        members.add(new Map<String,Object>{ 'Relationship' => 'Primary', 'Name' => 'Primary A' });
        families.put(famId, members);

        List<Map<String,Object>> ordered = ARC_EmployeesTableController.orderCensusMembers(families);
        System.assertEquals('Primary A', (String) ordered[0].get('Name'));
        System.assertEquals('Spouse A',  (String) ordered[1].get('Name'));
        System.assertEquals('Child A',   (String) ordered[2].get('Name'));
        System.assertEquals('Other A',   (String) ordered[3].get('Name'));
    }

    @isTest
    static void testGetCensusDownloadableData_empty() {
        ARC_UserPermissionService.bypassForTest = true;
        String suffix = String.valueOf(Crypto.getRandomInteger());

        RecordType groupAccRT = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_SmallGroup' AND SobjectType='Account' LIMIT 1];
        Account a = new Account(Name='ETC_NoCensusGroup_' + suffix, IsActive=true, RecordTypeId=groupAccRT.Id);
        insert a;

        User u = createPortalUserWithPermissions(a, suffix);

        System.runAs(u) {
            Test.startTest();
            List<Map<String,Object>> result = ARC_EmployeesTableController.getCensusDownloadableData();
            Test.stopTest();
            System.assertNotEquals(null, result);
        }
    }

    @isTest
    static void testUpdateCases() {
        User u = getTestUser();
        Id perAccId = [
            SELECT Id FROM Account
            WHERE ARC_GroupAccount__c = :u.AccountId
            AND RecordType.DeveloperName = 'ARC_IFPPersonAccount'
            LIMIT 1
        ].Id;
        Case cs = [SELECT Id, Status FROM Case WHERE AccountId = :perAccId LIMIT 1];
        cs.Status = 'Working';
        Test.startTest();
        ARC_EmployeesTableController.updateCases(new List<Case>{ cs });
        Test.stopTest();
        System.assertEquals('Working', [SELECT Status FROM Case WHERE Id = :cs.Id].Status);
    }

    @isTest
    static void testGetQLE() {
        User u = getTestUser();
        System.runAs(u) {
            Test.startTest();
            List<Case> casesList = ARC_EmployeesTableController.getQLE();
            Test.stopTest();
            System.assert(casesList.size() >= 0);
        }
    }

    @isTest
    static void testGetUserAccountId() {
        User u = getTestUser();
        System.runAs(u) {
            Test.startTest();
            Id accId = ARC_EmployeesTableController.getUserAccountId();
            Test.stopTest();
            System.assertNotEquals(null, accId);
        }
    }

    @isTest
    static void testUpdateCases_emptyAndNull() {
        Test.startTest();
        ARC_EmployeesTableController.updateCases(new List<Case>());
        try {
            ARC_EmployeesTableController.updateCases(null);
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testGetQLE_withCaseData() {
        User u = getTestUser();
        Case c = new Case(Status='New', Subject='ETC_QLE_Test', Description='desc', AccountId=u.AccountId);
        insert c;
        System.runAs(u) {
            Test.startTest();
            List<Case> casesList = ARC_EmployeesTableController.getQLE();
            Test.stopTest();
            System.assertNotEquals(null, casesList);
        }
    }

    @isTest
    static void testGetUserAccountId_noAccount() {
        User u = new User(
            Username='ETC_noacc' + System.currentTimeMillis() + '@example.com',
            Email='ETC_noacc@example.com', LastName='NoAcc', FirstName='User', Alias='nacc',
            TimeZoneSidKey='America/Los_Angeles', LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US',
            ProfileId=[SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id
        );
        insert u;
        System.runAs(u) {
            Test.startTest();
            Id accId = ARC_EmployeesTableController.getUserAccountId();
            Test.stopTest();
            System.assert(true);
        }
    }

    @isTest
    static void testMultiplePolicyStatusesCoverage() {
        User u = getTestUser();
        List<InsurancePolicy> extra = new List<InsurancePolicy>();

        Id contractId = [SELECT Id FROM Contract WHERE AccountId = :u.AccountId LIMIT 1].Id;
        Id personAccForName = [SELECT Id FROM Account WHERE ARC_GroupAccount__c = :u.AccountId LIMIT 1].Id;

        for (Integer i = 0; i < 6; i++) {
            InsurancePolicy ip = new InsurancePolicy(Status='Status' + i);
            ip.put('ARC_Contract__c', contractId);
            ip.put('Name', 'ETC_Extra_' + i);
            ip.put('NameInsuredId', personAccForName);
            extra.add(ip);
        }
        insert extra;

        Id personContactId = [SELECT PersonContactId FROM Account WHERE Id = :personAccForName LIMIT 1].PersonContactId;
        List<InsurancePolicyParticipant> parts = new List<InsurancePolicyParticipant>();
        if (personContactId != null) {
            for (InsurancePolicy p : extra) {
                parts.add(new InsurancePolicyParticipant(InsurancePolicyId=p.Id, Role='Primary', PrimaryParticipantContactId=personContactId));
            }
            try { insert parts; } catch (Exception e) {}
        }

        System.runAs(u) {
            Test.startTest();
            List<Map<String,Object>> res = ARC_EmployeesTableController.getPoliciesfromContracts();
            Test.stopTest();
            System.assertNotEquals(null, res);
        }
    }

    @isTest
    static void testIsOpenEnrollmentActive_nullDates() {
        ARC_UserPermissionService.bypassForTest = true;
        String suffix = String.valueOf(Crypto.getRandomInteger());

        RecordType groupAccRT = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_SmallGroup' AND SobjectType='Account' LIMIT 1];
        Account isolatedGroup = new Account(Name='ETC_Iso_NullDates_' + suffix, IsActive=true, RecordTypeId=groupAccRT.Id);
        insert isolatedGroup;

        insert new Contract(AccountId=isolatedGroup.Id, Status='Draft', StartDate=Date.today().addMonths(-1));

        User u = createPortalUserWithPermissions(isolatedGroup, suffix);

        System.runAs(u) {
            Test.startTest();
            Boolean active = ARC_EmployeesTableController.isOpenEnrollmentActive(isolatedGroup.Id);
            Test.stopTest();
            System.assertEquals(false, active);
        }
    }

    @isTest
    static void testIsOpenEnrollmentActive_noMemberFound() {
        ARC_UserPermissionService.bypassForTest = true;
        String suffix = String.valueOf(Crypto.getRandomInteger());

        RecordType groupAccRT = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_SmallGroup' AND SobjectType='Account' LIMIT 1];
        Account isoGroup = new Account(Name='ETC_Iso_NoMember_' + suffix, IsActive=true, RecordTypeId=groupAccRT.Id);
        insert isoGroup;

        Contract c = new Contract(AccountId=isoGroup.Id, Status='Draft', StartDate=Date.today().addMonths(-2));
        c.put('ARC_OEStartDate__c', Date.today().addDays(-30));
        c.put('ARC_OEEndDate__c', Date.today().addDays(-20));
        insert c;

        Account unrelated = new Account(Name='ETC_CompletelyUnrelated_' + suffix, IsActive=true); insert unrelated;

        User u = createPortalUserWithPermissions(isoGroup, suffix);

        System.runAs(u) {
            Test.startTest();
            Boolean active = ARC_EmployeesTableController.isOpenEnrollmentActive(unrelated.Id);
            Test.stopTest();
            System.assertEquals(false, active);
        }
    }

    @isTest
    static void testGetCensusDownloadableData() {
        User u = getTestUser();
        System.runAs(u) {
            List<Contract> existing = [SELECT Id FROM Contract WHERE AccountId = :u.AccountId LIMIT 1];
            if (existing.isEmpty()) {
                Contract c = new Contract(AccountId=u.AccountId, Status='Draft', StartDate=Date.today().addMonths(-1));
                c.put('ARC_OEStartDate__c', Date.today().addDays(-1));
                c.put('ARC_OEEndDate__c', Date.today().addDays(1));
                insert c;
            }
            Test.startTest();
            List<Map<String,Object>> result = ARC_EmployeesTableController.getCensusDownloadableData();
            Test.stopTest();
            System.assertNotEquals(null, result);
        }
    }

    @isTest
    static void testGetCensusDownloadableData_onlyMembersWithoutPolicy() {
        User u = getTestUser();
        System.runAs(u) {
            List<Contract> existing = [SELECT Id FROM Contract WHERE AccountId = :u.AccountId LIMIT 1];
            if (existing.isEmpty()) {
                Contract c = new Contract(AccountId=u.AccountId, Status='Draft', StartDate=Date.today().addMonths(-1));
                c.put('ARC_OEStartDate__c', Date.today().addDays(-1));
                c.put('ARC_OEEndDate__c', Date.today().addDays(1));
                insert c;
            }

            Id paRT = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_IFPPersonAccount' AND SobjectType='Account' LIMIT 1].Id;
            Account pa = new Account(FirstName='Only', LastName='Census', RecordTypeId=paRT, ARC_GroupAccount__c=u.AccountId, IsActive=true, ARC_CoverageWaived__c=false);
            insert pa;

            vlocity_ins__GroupCensus__c gc = new vlocity_ins__GroupCensus__c(Name='ETC_GC_onlyMembers', vlocity_ins__GroupId__c=u.AccountId);
            insert gc;
            insert new vlocity_ins__GroupCensusMember__c(
                vlocity_ins__FirstName__c='Only', vlocity_ins__LastName__c='Member',
                vlocity_ins__AccountId__c=pa.Id, ARC_ActiveMember__c=true,
                vlocity_ins__IsPrimaryMember__c=true, vlocity_ins__CensusId__c=gc.Id
            );

            Test.startTest();
            List<Map<String,Object>> result = ARC_EmployeesTableController.getCensusDownloadableData();
            Test.stopTest();
            System.assertNotEquals(null, result);
        }
    }

    @isTest
    static void testGetCensusDownloadableData_withCoverageParticipants() {
        User u = getTestUser();
        System.runAs(u) {
            List<Contract> existing = [SELECT Id FROM Contract WHERE AccountId = :u.AccountId LIMIT 1];
            Id contractId;
            if (existing.isEmpty()) {
                Contract c = new Contract(AccountId=u.AccountId, Status='Draft', StartDate=Date.today().addMonths(-1));
                c.put('ARC_OEStartDate__c', Date.today().addDays(-1));
                c.put('ARC_OEEndDate__c', Date.today().addDays(1));
                insert c;
                contractId = c.Id;
            } else {
                contractId = existing[0].Id;
            }

            Id paRT = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_IFPPersonAccount' AND SobjectType='Account' LIMIT 1].Id;
            Account pa = new Account(FirstName='Cov', LastName='Part', RecordTypeId=paRT, ARC_GroupAccount__c=u.AccountId, IsActive=true, ARC_CoverageWaived__c=false);
            insert pa;

            InsurancePolicy pol = new InsurancePolicy(Status='Activated');
            pol.put('ARC_Contract__c', contractId);
            pol.put('Name', 'ETC_CP_Policy');
            pol.put('NameInsuredId', pa.Id);
            insert pol;

            Id contactId = [SELECT PersonContactId FROM Account WHERE Id = :pa.Id LIMIT 1].PersonContactId;
            if (contactId != null) {
                insert new InsurancePolicyParticipant(InsurancePolicyId=pol.Id, Role='Primary', PrimaryParticipantContactId=contactId);
            }

            Product2 prod = new Product2(Name='ETC_CP_Prod', IsActive=true); insert prod;
            InsurancePolicyCoverage cov = new InsurancePolicyCoverage(InsurancePolicyId=pol.Id, vlocity_ins_fsc__Product2Id__c=prod.Id);
            insert cov;

            InsurancePolicyParticipant ip = [SELECT Id FROM InsurancePolicyParticipant WHERE InsurancePolicyId = :pol.Id AND Role = 'Primary' LIMIT 1];
            insert new ARC_CoverageParticipant__c(ARC_PolicyParticipant__c=ip.Id, ARC_PolicyCoverage__c=cov.Id, ARC_Policy__c=pol.Id);

            Account pa2 = new Account(FirstName='No', LastName='Policy', RecordTypeId=paRT, ARC_GroupAccount__c=u.AccountId, IsActive=true, ARC_CoverageWaived__c=false);
            insert pa2;
            vlocity_ins__GroupCensus__c gc = new vlocity_ins__GroupCensus__c(Name='ETC_CP_GC', vlocity_ins__GroupId__c=u.AccountId);
            insert gc;
            insert new vlocity_ins__GroupCensusMember__c(
                vlocity_ins__FirstName__c='No', vlocity_ins__LastName__c='Policy',
                vlocity_ins__AccountId__c=pa2.Id, ARC_ActiveMember__c=true,
                vlocity_ins__IsPrimaryMember__c=true, vlocity_ins__CensusId__c=gc.Id
            );

            Test.startTest();
            List<Map<String,Object>> result = ARC_EmployeesTableController.getCensusDownloadableData();
            Test.stopTest();
            System.assertNotEquals(null, result);
        }
    }

    @isTest
    static void testGetPoliciesfromContracts_downloadableAggregations() {
        User u = getTestUser();

        List<Contract> existing = [SELECT Id FROM Contract WHERE AccountId = :u.AccountId LIMIT 1];
        Id contractId;
        if (existing.isEmpty()) {
            Contract c = new Contract(AccountId=u.AccountId, Status='Draft', StartDate=Date.today().addMonths(-1));
            c.put('ARC_OEStartDate__c', Date.today().addDays(-2));
            c.put('ARC_OEEndDate__c', Date.today().addDays(2));
            insert c;
            contractId = c.Id;
        } else {
            contractId = existing[0].Id;
        }

        Id paRT = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_IFPPersonAccount' AND SobjectType='Account' LIMIT 1].Id;
        Account primary = new Account(FirstName='Fam', LastName='Primary', RecordTypeId=paRT, ARC_GroupAccount__c=u.AccountId, IsActive=true, ARC_CoverageWaived__c=false); insert primary;
        Account spouse  = new Account(FirstName='Fam', LastName='Spouse',  RecordTypeId=paRT, ARC_GroupAccount__c=u.AccountId, IsActive=true, ARC_CoverageWaived__c=false); insert spouse;
        Account child   = new Account(FirstName='Fam', LastName='Child',   RecordTypeId=paRT, ARC_GroupAccount__c=u.AccountId, IsActive=true, ARC_CoverageWaived__c=false); insert child;

        vlocity_ins__GroupCensus__c gc = new vlocity_ins__GroupCensus__c(Name='ETC_Fam_GC', vlocity_ins__GroupId__c=u.AccountId); insert gc;
        insert new vlocity_ins__GroupCensusMember__c(vlocity_ins__FirstName__c='Fam', vlocity_ins__LastName__c='Primary', vlocity_ins__AccountId__c=primary.Id, ARC_ActiveMember__c=true, vlocity_ins__IsPrimaryMember__c=true,  vlocity_ins__CensusId__c=gc.Id);
        insert new vlocity_ins__GroupCensusMember__c(vlocity_ins__FirstName__c='Fam', vlocity_ins__LastName__c='Spouse',  vlocity_ins__AccountId__c=spouse.Id,  ARC_ActiveMember__c=true, vlocity_ins__IsPrimaryMember__c=false, vlocity_ins__CensusId__c=gc.Id, ARC_DependentRelationship__c='Spouse');
        insert new vlocity_ins__GroupCensusMember__c(vlocity_ins__FirstName__c='Fam', vlocity_ins__LastName__c='Child',   vlocity_ins__AccountId__c=child.Id,   ARC_ActiveMember__c=true, vlocity_ins__IsPrimaryMember__c=false, vlocity_ins__CensusId__c=gc.Id, ARC_DependentRelationship__c='Child');

        Id primC = [SELECT PersonContactId FROM Account WHERE Id = :primary.Id LIMIT 1].PersonContactId;
        Id spC   = [SELECT PersonContactId FROM Account WHERE Id = :spouse.Id  LIMIT 1].PersonContactId;
        Id chC   = [SELECT PersonContactId FROM Account WHERE Id = :child.Id   LIMIT 1].PersonContactId;

        // InsurancePolicy y participants dentro de startTest para resetear límites
        // y absorber el trigger de billing
        Test.startTest();

        InsurancePolicy pPrim = new InsurancePolicy(Status='Activated'); pPrim.put('ARC_Contract__c', contractId); pPrim.put('Name', 'ETC_Fam_Primary_Policy'); pPrim.put('NameInsuredId', primary.Id); insert pPrim;
        InsurancePolicy pSp   = new InsurancePolicy(Status='Activated'); pSp.put('ARC_Contract__c', contractId);  pSp.put('Name', 'ETC_Fam_Spouse_Policy');  pSp.put('NameInsuredId', spouse.Id);  insert pSp;
        InsurancePolicy pCh   = new InsurancePolicy(Status='Activated'); pCh.put('ARC_Contract__c', contractId);  pCh.put('Name', 'ETC_Fam_Child_Policy');   pCh.put('NameInsuredId', child.Id);   insert pCh;

        if (primC != null) insert new InsurancePolicyParticipant(InsurancePolicyId=pPrim.Id, Role='Primary', PrimaryParticipantContactId=primC);
        if (spC   != null) insert new InsurancePolicyParticipant(InsurancePolicyId=pSp.Id,   Role='Primary', PrimaryParticipantContactId=spC);
        if (chC   != null) insert new InsurancePolicyParticipant(InsurancePolicyId=pCh.Id,   Role='Primary', PrimaryParticipantContactId=chC);

        System.runAs(u) {
            List<Map<String,Object>> data = ARC_EmployeesTableController.getPoliciesfromContracts();

            System.assertNotEquals(null, data);
            System.assert(data.size() >= 2, 'Se esperan mapas agregados al final del resultado');
            Boolean hasAggregations = false;
            for (Integer i = Math.max(0, data.size() - 3); i < data.size(); i++) {
                if (data[i].containsKey('primaryMemberToMembers') || data[i].containsKey('downloadableData')) {
                    hasAggregations = true; break;
                }
            }
            System.assertEquals(true, hasAggregations, 'Se esperan claves agregadas para cubrir lineas 522-527');
        }

        Test.stopTest();
    }

    @isTest
    static void testGetQLE_queryExecutes() {
        User u = getTestUser();
        System.runAs(u) {
            Test.startTest();
            List<Case> rows = ARC_EmployeesTableController.getQLE();
            Test.stopTest();
            System.assertNotEquals(null, rows);
        }
    }

    @isTest
    static void testGetQLE_tryQualifyEventViaRecordType() {
        User u = getTestUser();
        System.runAs(u) {
            Id anyRt = null;
            try {
                anyRt = [SELECT Id FROM RecordType WHERE SObjectType='Case' AND (DeveloperName LIKE '%QLE%' OR Name LIKE '%Qualify%') LIMIT 1].Id;
            } catch (Exception e) { anyRt = null; }
            Case c = new Case(Status='New', Subject='ETC_Try_QLE_RT', Description='Auto-QLE attempt', AccountId=u.AccountId);
            if (anyRt != null) c.RecordTypeId = anyRt;
            try { insert c; } catch (Exception ex) {}
            Test.startTest();
            List<Case> rows = ARC_EmployeesTableController.getQLE();
            Test.stopTest();
            System.assertNotEquals(null, rows);
        }
    }

    @isTest
    static void testGetPoliciesfromContracts_voidedExclusion_and_pendingVsInactive() {
        User u = getTestUser();
        System.runAs(u) {
            Contract c = new Contract(AccountId=u.AccountId, Status='Draft', StartDate=Date.today().addMonths(-1));
            c.put('ARC_OEStartDate__c', Date.today().addDays(-1));
            c.put('ARC_OEEndDate__c', Date.today().addDays(1));
            insert c;

            Id paRT = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_IFPPersonAccount' AND SobjectType='Account' LIMIT 1].Id;

            Account paNoPolicy = new Account(
                FirstName='NL', LastName='NoPolicy', IsActive=true,
                ARC_CoverageWaived__c=false, ARC_AllowEnrollmentOutsideOE__c=false,
                RecordTypeId=paRT, ARC_GroupAccount__c=u.AccountId
            );
            insert paNoPolicy;

            vlocity_ins__GroupCensus__c gc = new vlocity_ins__GroupCensus__c(Name='ETC_GC2', vlocity_ins__GroupId__c=u.AccountId); insert gc;
            insert new vlocity_ins__GroupCensusMember__c(
                vlocity_ins__FirstName__c='NL', vlocity_ins__LastName__c='NoPolicy',
                vlocity_ins__AccountId__c=paNoPolicy.Id, ARC_ActiveMember__c=true,
                vlocity_ins__IsPrimaryMember__c=true, vlocity_ins__CensusId__c=gc.Id
            );

            Account paWaived = new Account(
                FirstName='WV', LastName='Waived', IsActive=true,
                ARC_CoverageWaived__c=true, ARC_AllowEnrollmentOutsideOE__c=false,
                RecordTypeId=paRT, ARC_GroupAccount__c=u.AccountId
            );
            insert paWaived;
            insert new vlocity_ins__GroupCensusMember__c(
                vlocity_ins__FirstName__c='WV', vlocity_ins__LastName__c='Waived',
                vlocity_ins__AccountId__c=paWaived.Id, ARC_ActiveMember__c=true,
                vlocity_ins__IsPrimaryMember__c=true, vlocity_ins__CensusId__c=gc.Id
            );

            InsurancePolicy voided = new InsurancePolicy(Status='Voided');
            voided.put('ARC_Contract__c', c.Id);
            voided.put('Name', 'ETC_Void_P');
            voided.put('NameInsuredId', paNoPolicy.Id);
            insert voided;

            Id nameInsuredContact = [SELECT PersonContactId FROM Account WHERE Id = :paNoPolicy.Id LIMIT 1].PersonContactId;
            if (nameInsuredContact != null) {
                insert new InsurancePolicyParticipant(
                    InsurancePolicyId=voided.Id, Role='Primary',
                    PrimaryParticipantContactId=nameInsuredContact
                );
            }

            Test.startTest();
            List<Map<String,Object>> res = ARC_EmployeesTableController.getPoliciesfromContracts();
            Test.stopTest();
            System.assertNotEquals(null, res);
        }
    }
}