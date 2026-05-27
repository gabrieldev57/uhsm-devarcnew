@isTest
public class ARC_Beneficiaries360ControllerTest {

    // =========================
    // HELPER: Create Person Account
    // =========================
    private static Account createPersonAccount(Integer age) {
        RecordType paRt = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Account' 
            AND IsPersonType = true 
            LIMIT 1
        ];

        Account person = new Account(
            RecordTypeId = paRt.Id,
            FirstName = 'Test',
            LastName = 'Person',
            PersonBirthdate = Date.today().addYears(-age)
        );
        insert person;

        return person;
    }

    // =========================
    // TEST 1: Activated Policy
    // =========================
    @isTest
    static void testActivatedPolicyScenario() {

        Account groupAcc = new Account(Name = 'Test Group Account');
        insert groupAcc;

        Account person = createPersonAccount(30);
        Id contactId = person.PersonContactId;

        vlocity_ins__GroupCensus__c cen = new vlocity_ins__GroupCensus__c(
            Name = 'Test Census',
            vlocity_ins__GroupId__c = groupAcc.Id
        );
        insert cen;

        vlocity_ins__GroupCensusMember__c census = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__ContactId__c = contactId,
            vlocity_ins__CensusId__c = cen.Id
        );
        insert census;

        groupAcc.Census_Member__c = census.Id;
        groupAcc.ARC_Census__c = cen.Id;
        update groupAcc;

                InsurancePolicy p1 = new InsurancePolicy(
            Status = 'Terminated',
            NameInsuredId = groupAcc.Id,
            Name = 'Policy 1'
        );
        
        InsurancePolicy p2 = new InsurancePolicy(
            Status = 'Activated',
            NameInsuredId = groupAcc.Id,
            Name = 'Policy 2'  
        );
        
        insert new List<InsurancePolicy>{p1, p2};

                InsurancePolicyParticipant ipp1 = new InsurancePolicyParticipant(
            InsurancePolicyId = p1.Id,
            PrimaryParticipantContactId = contactId,
            Role = 'Primary'
        );
        
        InsurancePolicyParticipant ipp2 = new InsurancePolicyParticipant(
            InsurancePolicyId = p2.Id,
            PrimaryParticipantContactId = contactId,
            Role = 'Primary'
        );
        
        insert new List<InsurancePolicyParticipant>{ipp1, ipp2};
        

        Product2 prod = new Product2(
            Name = 'Premier Plan',
            ProductCode = 'Premier123',
            IsActive = true
        );
        insert prod;

        InsurancePolicyCoverage cov = new InsurancePolicyCoverage(
            InsurancePolicyId = p2.Id,
            vlocity_ins_fsc__Product2Id__c = prod.Id
        );
        insert cov;

        ARC_CoverageParticipant__c cp = new ARC_CoverageParticipant__c(
            ARC_PolicyParticipant__c = ipp2.Id,
            ARC_Policy__c = p2.Id,
            ARC_PolicyCoverage__c = cov.Id
        );
        insert cp;

        Test.startTest();
        Map<String, Object> result =
            ARC_Beneficiaries360Controller.getCoverageParticipantId(groupAcc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
		System.assert(result.containsKey('displayComponent'));
		System.assert(result.containsKey('coverageParticipantId'));

    // coverageParticipantId should exist if displayComponent is true
    if ((Boolean)result.get('displayComponent')) {
        System.assertNotEquals(null, result.get('coverageParticipantId'),
            'Coverage Participant should exist when displayComponent is true');
    }
    }

    // =========================
    // TEST 2: Terminated Policy
    // =========================
    @isTest
    static void testTerminatedPolicySelection() {

        Account groupAcc = new Account(Name = 'Test Group Account 2');
        insert groupAcc;

        Account person = createPersonAccount(25);
        Id contactId = person.PersonContactId;

        vlocity_ins__GroupCensus__c cen = new vlocity_ins__GroupCensus__c(
            Name = 'Test Census',
            vlocity_ins__GroupId__c = groupAcc.Id
        );
        insert cen;

        vlocity_ins__GroupCensusMember__c census = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__ContactId__c = contactId,
            vlocity_ins__CensusId__c = cen.Id
        );
        insert census;

        groupAcc.Census_Member__c = census.Id;
        groupAcc.ARC_Census__c = cen.Id;
        update groupAcc;

                InsurancePolicy p1 = new InsurancePolicy(
            Status = 'Terminated',
            NameInsuredId = groupAcc.Id,
            Name = 'Policy Old'
            
        );
        
        InsurancePolicy p2 = new InsurancePolicy(
            Status = 'Terminated',
            NameInsuredId = groupAcc.Id,
            Name = 'Policy New'
           
        );
        
        insert new List<InsurancePolicy>{p1, p2};

        InsurancePolicyParticipant ipp = new InsurancePolicyParticipant(
            InsurancePolicyId = p1.Id,
            PrimaryParticipantContactId = contactId,
            Role = 'Primary'
        );
        insert ipp;

        Product2 prod = new Product2(
            Name = 'Premier Plan',
            ProductCode = 'Premier123',
            IsActive = true
        );
        insert prod;

        InsurancePolicyCoverage cov = new InsurancePolicyCoverage(
            InsurancePolicyId = p1.Id,
            vlocity_ins_fsc__Product2Id__c = prod.Id
        );
        insert cov;

        ARC_CoverageParticipant__c cp = new ARC_CoverageParticipant__c(
            ARC_PolicyParticipant__c = ipp.Id,
            ARC_Policy__c = p1.Id,
            ARC_PolicyCoverage__c = cov.Id
        );
        insert cp;

        Test.startTest();
        Map<String, Object> result =
            ARC_Beneficiaries360Controller.getCoverageParticipantId(groupAcc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
		System.assert(result.containsKey('displayComponent'));
		System.assert(result.containsKey('coverageParticipantId'));
    }

    // =========================
    // TEST 3: Underage Scenario
    // =========================
    @isTest
    static void testAwaitingPolicyBranchAndUnderAge() {

        Account groupAcc = new Account(Name = 'Test Group Account 3');
        insert groupAcc;

        Account person = createPersonAccount(10); // under 18
        Id contactId = person.PersonContactId;

        vlocity_ins__GroupCensus__c cen = new vlocity_ins__GroupCensus__c(
            Name = 'Test Census',
            vlocity_ins__GroupId__c = groupAcc.Id
        );
        insert cen;

        vlocity_ins__GroupCensusMember__c census = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__ContactId__c = contactId,
            vlocity_ins__CensusId__c = cen.Id
        );
        insert census;

        groupAcc.Census_Member__c = census.Id;
        groupAcc.ARC_Census__c = cen.Id;
        update groupAcc;

                       InsurancePolicy p1 = new InsurancePolicy(
            Status = 'Awaiting Approval',
            NameInsuredId = groupAcc.Id,
            Name = 'Policy A'
        );
        
        InsurancePolicy p2 = new InsurancePolicy(
            Status = 'Awaiting Review',
            NameInsuredId = groupAcc.Id,
            Name = 'Policy B'
        );
        
        insert new List<InsurancePolicy>{p1, p2};

        InsurancePolicyParticipant ipp1 = new InsurancePolicyParticipant(
            InsurancePolicyId = p1.Id,
            PrimaryParticipantContactId = contactId,
            Role = 'Primary'
        );
        insert ipp1;
        
        InsurancePolicyParticipant ipp2 = new InsurancePolicyParticipant(
            InsurancePolicyId = p2.Id,
            PrimaryParticipantContactId = contactId,
            Role = 'Primary'
        );
        insert ipp2;

        Product2 prod = new Product2(
            Name = 'Premier Plan',
            ProductCode = 'Premier123',
            IsActive = true
        );
        insert prod;

        InsurancePolicyCoverage cov1 = new InsurancePolicyCoverage(
            InsurancePolicyId = p1.Id,
            vlocity_ins_fsc__Product2Id__c = prod.Id
        );
        insert cov1;
        
        InsurancePolicyCoverage cov2 = new InsurancePolicyCoverage(
            InsurancePolicyId = p2.Id,
            vlocity_ins_fsc__Product2Id__c = prod.Id
        );
        insert cov2;

        ARC_CoverageParticipant__c cp1 = new ARC_CoverageParticipant__c(
            ARC_PolicyParticipant__c = ipp1.Id,
            ARC_Policy__c = p1.Id,
            ARC_PolicyCoverage__c = cov1.Id
        );
        insert cp1;
        
        ARC_CoverageParticipant__c cp2 = new ARC_CoverageParticipant__c(
            ARC_PolicyParticipant__c = ipp2.Id,
            ARC_Policy__c = p2.Id,
            ARC_PolicyCoverage__c = cov2.Id
        );
        insert cp2;

        Test.startTest();
        Map<String, Object> result =
            ARC_Beneficiaries360Controller.getCoverageParticipantId(groupAcc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
		System.assertEquals(false, result.get('displayComponent'),
    	'Underage account should not display component');
		System.assert(result.containsKey('coverageParticipantId'),
    	'Key should exist even if displayComponent is false');
    }
}