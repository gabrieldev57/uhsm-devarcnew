@isTest (isParallel=false)
private class ARC_CensusMemberPortalControllerTest {

    private static String uniqueUsername() {
        return 'testuser' + String.valueOf(Crypto.getRandomInteger()) + '@example.com';
    }

    @isTest static void testGetPicklistOptions() {
        ARC_CensusMemberPortalController.PicklistOptionsDTO dto = ARC_CensusMemberPortalController.getPicklistOptions();
        System.assertNotEquals(null, dto);
        System.assertNotEquals(null, dto.employmentTypes);
        System.assertNotEquals(null, dto.divisions);
        System.assertNotEquals(null, dto.jobClasses);
    }

    @isTest static void testValidateRequired_viaSave() {
        ARC_CensusMemberPortalController.CensusMemberPortalWrapper emptyWrapper = new ARC_CensusMemberPortalController.CensusMemberPortalWrapper();
        String memberJson = JSON.serialize(emptyWrapper);

        ARC_CensusMemberPortalController.SaveResultWrapper result = ARC_CensusMemberPortalController.saveCensusMemberForCurrentUser(memberJson);
        System.assertNotEquals(null, result);
        System.assert(!result.errors.isEmpty());
    }

    @isTest static void testSaveCensusMemberForCurrentUser_success() {
        Account acc = new Account(Name = 'Test Account for Census');
        insert acc;

        Contact c = new Contact(LastName = 'TestContact', AccountId = acc.Id);
        insert c;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Employer Admin' LIMIT 1];

        User u = new User(
            Username = uniqueUsername(),
            Email = 'test+' + String.valueOf(Crypto.getRandomInteger()) + '@example.com',
            LastName = 'User',
            Alias = 'tusr',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            ContactId = c.Id
        );
        insert u;

        ARC_CensusMemberPortalController.PicklistOptionsDTO picks = ARC_CensusMemberPortalController.getPicklistOptions();

        ARC_CensusMemberPortalController.CensusMemberPortalWrapper w = new ARC_CensusMemberPortalController.CensusMemberPortalWrapper();
        w.firstName = 'Javier';
        w.lastName = 'Test';
        w.gender = 'Male';
        w.dob = '1980-01-01';
        w.employmentType = (picks.employmentTypes.isEmpty() ? 'Employee' : picks.employmentTypes[0]);
        w.division = (picks.divisions.isEmpty() ? 'Division' : picks.divisions[0]);
        w.jobClass = (picks.jobClasses.isEmpty() ? 'Job' : picks.jobClasses[0]);
        w.ssn = '123456789';
        w.email = 'javier.test+' + String.valueOf(Crypto.getRandomInteger()) + '@example.com';
        w.phone = '6188371234';
        w.street = '123 Test St';
        w.city = 'California';
        w.state = 'CA';
        w.zipCode = '90001';
        w.effectiveDate = '2025-01-01';

        String memberJson = JSON.serialize(w);

        System.runAs(u) {
            Test.startTest();
            ARC_CensusMemberPortalController.SaveResultWrapper res = ARC_CensusMemberPortalController.saveCensusMemberForCurrentUser(memberJson);
            Test.stopTest();

            System.assert(res != null);
            System.assert(res.errors.isEmpty(), 'Expected no validation errors but found: ' + String.join(res.errors, ';'));
            System.assert(res.success);
            System.assertNotEquals(null, res.censusMemberId);
        }
    }
    @isTest static void testAssignMemberToGroupClasses() {
        Account acc = new Account(Name = 'Test Account for Census');
        insert acc;
    
        Contact c = new Contact(LastName = 'TestContact', AccountId = acc.Id);
        insert c;
    
        // Crear contrato activo
        Contract contract = new Contract(
            AccountId = acc.Id,
            Status = 'Enrollment In Progress',
            StartDate = Date.today()
        );
        insert contract;
    
        // Crear GroupClass asociada al contrato
        vlocity_ins__GroupClass__c gc = new vlocity_ins__GroupClass__c(
            Name = 'General',
            vlocity_ins__GroupId__c = acc.Id,
            ARC_Contract__c = contract.Id,
            ARC_EmployeeTypeModel__c = 'None',
            ARC_EmployeeType__c = 'None',
            ARC_EmployeeDivision__c = 'None',
            vlocity_ins__IsActive__c = true
        );
        insert gc;
    
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Employer Admin' LIMIT 1];
    
        User u = new User(
            Username = uniqueUsername(),
            Email = 'test+' + String.valueOf(Crypto.getRandomInteger()) + '@example.com',
            LastName = 'User',
            Alias = 'tusr',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            ContactId = c.Id
        );
        insert u;
    
        ARC_CensusMemberPortalController.PicklistOptionsDTO picks = ARC_CensusMemberPortalController.getPicklistOptions();
    
        ARC_CensusMemberPortalController.CensusMemberPortalWrapper w = new ARC_CensusMemberPortalController.CensusMemberPortalWrapper();
        w.firstName = 'Ana';
        w.lastName = 'GroupClass';
        w.gender = 'Female';
        w.dob = '1990-05-15';
        w.employmentType = (picks.employmentTypes.isEmpty() ? 'Employee' : picks.employmentTypes[0]);
        w.division = (picks.divisions.isEmpty() ? 'Division' : picks.divisions[0]);
        w.jobClass = (picks.jobClasses.isEmpty() ? 'Job' : picks.jobClasses[0]);
        w.ssn = '987654321';
        w.email = 'ana.test+' + String.valueOf(Crypto.getRandomInteger()) + '@example.com';
        w.phone = '6188371234';
        w.street = '456 Test Ave';
        w.city = 'Los Angeles';
        w.state = 'CA';
        w.zipCode = '90002';
        w.effectiveDate = '2025-01-01';
    
        String memberJson = JSON.serialize(w);
    
        System.runAs(u) {
            Test.startTest();
            ARC_CensusMemberPortalController.SaveResultWrapper res = ARC_CensusMemberPortalController.saveCensusMemberForCurrentUser(memberJson);
            Test.stopTest();
    
            System.assert(res != null);
            System.assert(res.success, 'Expected success but got errors: ' + String.join(res.errors, ';'));
            System.assertNotEquals(null, res.censusMemberId);
    
            // Verificar que se creó la junction
            List<ARC_CensusMemberGroupClass__c> junctions = [
                SELECT Id FROM ARC_CensusMemberGroupClass__c
                WHERE ARC_CensusMember__c = :res.censusMemberId
            ];
            System.assertEquals(1, junctions.size(), 'Expected 1 junction record');
        }
    }
}