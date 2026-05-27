@isTest
private class ARC_LOAPolicyControllerTest {

    private static Account createMemberAccount() {
        Account acc = new Account(
            FirstName = 'Test',
            LastName = 'Member',
            RecordTypeId = Schema.SObjectType.Account
                .getRecordTypeInfosByDeveloperName()
                .get('PersonAccount')
                .getRecordTypeId()
        );
        insert acc;
        return acc;
    }

    private static InsurancePolicy createPolicy(Id nameInsuredId, String reason, String status, Id originalPolicyId) {
        InsurancePolicy policy = new InsurancePolicy(
            Name = 'POL-TEST-' + String.valueOf(DateTime.now().getTime()) + String.valueOf(Math.random()),
            NameInsuredId = nameInsuredId,
            ARC_Reason__c = reason,
            Status = status,
            ARC_PolicyEffectiveDate__c = Date.today().addMonths(-3),
            ARC_PolicyExpirationDate__c = Date.today().addMonths(9)
        );
        if (originalPolicyId != null) {
            policy.OriginalPolicyId = originalPolicyId;
        }
        insert policy;
        return policy;
    }

    private static Case createLOACase(Id personAccountId) {
        Id qleRecordTypeId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('ARC_QualifyEvent')
            .getRecordTypeId();

        Case c = new Case(
            ARC_PersonAccount__c = personAccountId,
            ARC_Reason__c = 'Leave of Absence',
            ARC_QLEType__c = 'Leave of Absence',
            Subject = 'Leave of Absence',
            Description = 'Test LOA case',
            RecordTypeId = qleRecordTypeId,
            arcsona__EventDate__c = Date.today().addMonths(-2),
            ARC_QLEEffectiveDate__c = Date.today().addMonths(4)
        );
        insert c;
        return c;
    }

    @isTest
    static void testGetPoliciesWithQLE_NoPolicies() {
        Account member = createMemberAccount();

        Test.startTest();
        List<ARC_LOAPolicyController.LOARecord> results =
            ARC_LOAPolicyController.getPoliciesWithQLE(member.Id);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Should not return null');
        System.assertEquals(0, results.size(), 'Should return empty');
    }

    @isTest
    static void testGetPoliciesWithQLE_MatchingQLE() {
        Account member = createMemberAccount();
        InsurancePolicy orig = createPolicy(member.Id, 'New Application', 'In Force', null);
        InsurancePolicy rein = createPolicy(member.Id, 'Reinstatement', 'In Force', orig.Id);
        Case qle = createLOACase(member.Id);

        Test.startTest();
        List<ARC_LOAPolicyController.LOARecord> results =
            ARC_LOAPolicyController.getPoliciesWithQLE(member.Id);
        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assertEquals(1, results.size(), 'Should return only one reinstatement policy');
        System.assertEquals(rein.Id, results[0].policyId, 'PolicyID should match');
    }

    @isTest
    static void testUpdateLOADates_InvalidPayload() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            ARC_LOAPolicyController.updateLOADates(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'An exception should be thrown for invalid payload');
    }

    @isTest
    static void testUpdateLOADates_InvalidMemberAccountId() {
        Map<String, Object> payload = new Map<String, Object>{
            'memberAccountId' => 'abc',
            'updates' => new List<Object>{ new Map<String, Object>() }
        };

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            ARC_LOAPolicyController.updateLOADates(payload);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'An exception should be thrown for invalid memberAccountId');
    }

    @isTest
    static void testUpdateLOADates_NoValidUpdates() {
        Account member = createMemberAccount();

        Map<String, Object> payload = new Map<String, Object>{
            'memberAccountId' => (String)member.Id,
            'updates' => new List<Object>()
        };

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            ARC_LOAPolicyController.updateLOADates(payload);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'An exception should be thrown when no valid updates are provided');
    }

    @isTest
    static void testUpdateLOADates_Success() {
        Account member = createMemberAccount();
        InsurancePolicy orig = createPolicy(member.Id, 'New Application', 'In Force', null);
        InsurancePolicy rein = createPolicy(member.Id, 'Reinstatement', 'In Force', orig.Id);
        Case qle = createLOACase(member.Id);

        Date newStartDate = Date.newInstance(2026, 3, 10);
        Date newEndDate = Date.newInstance(2026, 4, 20);

        Map<String, Object> updateRow = new Map<String, Object>{
            'policyId' => (String) rein.Id,
            'startDate' => String.valueOf(newStartDate),
            'endDate' => String.valueOf(newEndDate)
        };

        Map<String, Object> payload = new Map<String, Object>{
            'memberAccountId' => (String) member.Id,
            'updates' => new List<Object>{ updateRow }
        };

        Test.startTest();
        ARC_LOAPolicyController.updateLOADates(payload);
        Test.stopTest();

        InsurancePolicy updatedOrig = [
            SELECT Id, ARC_PolicyExpirationDate__c
            FROM InsurancePolicy
            WHERE Id = :orig.Id
        ];

        InsurancePolicy updatedRein = [
            SELECT Id, ARC_PolicyEffectiveDate__c
            FROM InsurancePolicy
            WHERE Id = :rein.Id
        ];

        Case updatedQle = [
            SELECT Id, arcsona__EventDate__c, ARC_QLEEffectiveDate__c
            FROM Case
            WHERE Id = :qle.Id
        ];

        Date expectedOrigExpiration = Date.newInstance(
            newStartDate.year(),
            newStartDate.month(),
            Date.daysInMonth(newStartDate.year(), newStartDate.month())
        );

        Date expectedReinEffective =
            Date.newInstance(newEndDate.year(), newEndDate.month(), 1).addMonths(1);

        System.assertEquals(expectedOrigExpiration, updatedOrig.ARC_PolicyExpirationDate__c);
        System.assertEquals(expectedReinEffective, updatedRein.ARC_PolicyEffectiveDate__c);
        System.assertEquals(newStartDate, updatedQle.arcsona__EventDate__c);
        System.assertEquals(newEndDate, updatedQle.ARC_QLEEffectiveDate__c);
    }
}