@IsTest (isParallel=false)
public without sharing class aRC_employerPortalMatrixControllerTest {

    private static User getAdminUser() {
        return [
            SELECT Id FROM User
            WHERE Profile.Name = 'System Administrator'
            AND IsActive = true
            ORDER BY Id ASC
            LIMIT 1
            OFFSET 3
        ];
    }

    private static Profile getOrCreateTestProfile() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Employer Admin' LIMIT 1];
        if (!profiles.isEmpty()) {
            return profiles[0];
        }
        profiles = [SELECT Id FROM Profile LIMIT 1];
        return profiles.isEmpty() ? null : profiles[0];
    }

    private static User createTestUser(Id contactId, String uniq, String alias) {
        ARC_UserPermissionService.bypassForTest = true;
        Profile p = getOrCreateTestProfile();
        User u;
        System.runAs(getAdminUser()) {
            u = new User(
                Alias = alias,
                Email = 'tuser_' + uniq + '@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'T' + uniq,
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'tuser_' + uniq + '@example.com',
                ProfileId = p.Id,
                ContactId = contactId
            );
            insert u;
        }
        return u;
    }

    @IsTest
    static void test_getPortalMatrix_userWithContactAccount() {
        Account acc = new Account(Name = 'Account Matrix ' + String.valueOf(Crypto.getRandomInteger()));
        insert acc;

        Contact c = new Contact(LastName = 'Contact1', AccountId = acc.Id);
        insert c;

        Contract contract = new Contract(Name = 'Test Contract', AccountId = acc.Id);
        insert contract;
        vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c(
            Name = 'We Share 9k',
            vlocity_ins__ContractId__c = contract.Id
        );
        insert cli;

        vlocity_ins__GroupClass__c gc = new vlocity_ins__GroupClass__c(
            Name = 'GC2',
            vlocity_ins__GroupId__c = acc.Id,
            vlocity_ins__IsActive__c = true
        );
        insert gc;

        vlocity_ins__GroupClassContribution__c contrib = new vlocity_ins__GroupClassContribution__c(
            vlocity_ins__GroupClassId__c = gc.Id,
            ARC_ContractLineItem__c = cli.Id,
            vlocity_ins__ContributionAmount__c = 100,
            vlocity_ins__ProductCategory__c = 'Medical',
            vlocity_ins__ContributionType__c = 'Flat Amount'
        );
        insert contrib;

        String uniq = String.valueOf(DateTime.now().getTime());
        User u = createTestUser(c.Id, uniq, 'tusr3');

        System.runAs(u) {
            Test.startTest();
            List<aRC_employerPortalMatrixController.GroupClassDTO> res = aRC_employerPortalMatrixController.getPortalMatrixForCurrentUser();
            Test.stopTest();

            System.assertEquals(1, res.size());
            System.assertEquals(true, res[0].hasContributions);
            System.assertEquals(1, res[0].rows.size());
        }
    }

    @IsTest
    static void test_getPortalMatrix_multipleGroupClasses_multipleContributions() {
        Account acc = new Account(Name = 'Account Test ' + String.valueOf(Crypto.getRandomInteger()));
        insert acc;

        Contact con = new Contact(LastName = 'Multiple', AccountId = acc.Id);
        insert con;

        vlocity_ins__GroupClass__c gc1 = new vlocity_ins__GroupClass__c(
            Name = 'General',
            vlocity_ins__GroupId__c = acc.Id,
            vlocity_ins__IsActive__c = true,
            ARC_EmployeeType__c = 'Full Time',
            ARC_EmployeeDivision__c = 'Exempt'
        );
        vlocity_ins__GroupClass__c gc2 = new vlocity_ins__GroupClass__c(
            Name = 'General',
            vlocity_ins__GroupId__c = acc.Id,
            vlocity_ins__IsActive__c = true,
            ARC_EmployeeType__c = 'Part Time',
            ARC_EmployeeDivision__c = 'Non-Exempt'
        );
        insert new List<vlocity_ins__GroupClass__c> { gc1, gc2 };

        Contract contract = new Contract(Name = 'Test Contract Multi', AccountId = acc.Id);
        insert contract;
        vlocity_ins__ContractLineItem__c cli1 = new vlocity_ins__ContractLineItem__c(
            Name = 'We Share 9k',
            vlocity_ins__ContractId__c = contract.Id
        );
        vlocity_ins__ContractLineItem__c cli2 = new vlocity_ins__ContractLineItem__c(
            Name = 'We Share 6k',
            vlocity_ins__ContractId__c = contract.Id
        );
        insert new List<vlocity_ins__ContractLineItem__c> { cli1, cli2 };

        vlocity_ins__GroupClassContribution__c contrib1 = new vlocity_ins__GroupClassContribution__c(
            vlocity_ins__GroupClassId__c = gc1.Id,
            ARC_ContractLineItem__c = cli1.Id,
            vlocity_ins__ContributionPercent__c = 50,
            vlocity_ins__ContributionType__c = 'Percent',
            vlocity_ins__ProductCategory__c = 'Medical',
            ARC_EmployeeType__c = 'Full Time',
            ARC_EmployeeDivision__c = 'Non-Exempt',
            ARC_EmployeeTier__c = 'Family'
        );
        vlocity_ins__GroupClassContribution__c contrib2 = new vlocity_ins__GroupClassContribution__c(
            vlocity_ins__GroupClassId__c = gc1.Id,
            ARC_ContractLineItem__c = null,
            vlocity_ins__ContributionAmount__c = 250,
            vlocity_ins__ContributionType__c = 'Amount',
            vlocity_ins__ProductCategory__c = 'Medical',
            ARC_EmployeeType__c = 'Full Time',
            ARC_EmployeeDivision__c = 'Exempt',
            ARC_EmployeeTier__c = 'Family'
        );
        vlocity_ins__GroupClassContribution__c contrib3 = new vlocity_ins__GroupClassContribution__c(
            vlocity_ins__GroupClassId__c = gc2.Id,
            ARC_ContractLineItem__c = cli2.Id,
            vlocity_ins__ContributionPercent__c = 35,
            vlocity_ins__ContributionType__c = 'Percent',
            vlocity_ins__ProductCategory__c = 'Medical',
            ARC_EmployeeType__c = 'Part Time',
            ARC_EmployeeDivision__c = 'Non-Exempt',
            ARC_EmployeeTier__c = 'Employee Plus One'
        );
        insert new List<vlocity_ins__GroupClassContribution__c> { contrib1, contrib2, contrib3 };

        String uniq = String.valueOf(DateTime.now().getTime());
        User u = createTestUser(con.Id, uniq, 'tmul');

        System.runAs(u) {
            Test.startTest();
            List<aRC_employerPortalMatrixController.GroupClassDTO> res = aRC_employerPortalMatrixController.getPortalMatrixForCurrentUser();
            Test.stopTest();

            System.assertEquals(2, res.size());

            aRC_employerPortalMatrixController.GroupClassDTO dto1 = res[0];
            System.assertEquals('General', dto1.name);
            System.assertEquals('Full Time', dto1.employeeType);
            System.assertEquals('Exempt', dto1.employeeDivision);
            System.assertEquals(true, dto1.hasContributions);
            System.assertEquals(2, dto1.rows.size());
            System.assertNotEquals(null, dto1.rows[0].employeeType);
            System.assertNotEquals(null, dto1.rows[0].employeeTier);
            System.assertNotEquals(null, dto1.rows[1]);
            System.assertEquals('Family', dto1.rows[1].employeeTier);

            aRC_employerPortalMatrixController.GroupClassDTO dto2 = res[1];
            System.assertEquals('General', dto2.name);
            System.assertEquals('Part Time', dto2.employeeType);
            System.assertEquals('Non-Exempt', dto2.employeeDivision);
            System.assertEquals(true, dto2.hasContributions);
            System.assertEquals(1, dto2.rows.size());
            System.assertEquals('Part Time', dto2.rows[0].employeeType);
            System.assertEquals('Employee Plus One', dto2.rows[0].employeeTier);
        }
    }

    @IsTest
    static void test_getPortalMatrix_groupClassNoContributions() {
        Account acc = new Account(Name = 'Account No Contributions ' + String.valueOf(Crypto.getRandomInteger()));
        insert acc;

        Contact con = new Contact(LastName = 'ConNoContrib', AccountId = acc.Id);
        insert con;

        vlocity_ins__GroupClass__c gc = new vlocity_ins__GroupClass__c(
            Name = 'FT_PT',
            vlocity_ins__GroupId__c = acc.Id,
            vlocity_ins__IsActive__c = true
        );
        insert gc;

        String uniq = String.valueOf(DateTime.now().getTime());
        User u = createTestUser(con.Id, uniq, 'temp');

        System.runAs(u) {
            Test.startTest();
            List<aRC_employerPortalMatrixController.GroupClassDTO> res = aRC_employerPortalMatrixController.getPortalMatrixForCurrentUser();
            Test.stopTest();

            System.assertEquals(1, res.size());
            System.assertEquals('FT_PT', res[0].name);
            System.assertEquals(false, res[0].hasContributions);
            System.assertEquals(0, res[0].rows.size());
        }
    }
}