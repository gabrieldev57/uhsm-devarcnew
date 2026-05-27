@IsTest
private class ARC_SGSEDMLTest {

    private static Id sharedGroupId;
    private static Id sharedCensusId;

    // =========================
    // Manager Setup
    // =========================
    private static ARC_SGSEManager buildManager() {
        ARC_SGSEManager m = new ARC_SGSEManager(new Map<String, Object>());

        m.memberIdToCensusMemberMap = new Map<String, vlocity_ins__GroupCensusMember__c>();
        m.memberIdToAccountMap = new Map<String, Account>();
        m.memberIdToPersonContactId = new Map<String, Id>();
        m.memberIdToFamilyRole = new Map<String, String>();
        m.memberIdToBirthdate = new Map<String, Date>();
        m.memberIdToPolicyParticipant = new Map<String, InsurancePolicyParticipant>();

        m.indexToParentCovToInsert = new Map<String, InsurancePolicyCoverage>();
        m.indexToChildCovToInsert = new Map<String, List<InsurancePolicyCoverage>>();
        m.indexToMemberIds = new Map<String, List<String>>();

        m.externalPoliciesToInsert = new Map<String, ARC_ExternalInsurancePolicy__c>();
        m.policyKeyToMemberIds = new Map<String, List<String>>();
        m.externalPolicyMembersToInsert = new List<ARC_ExternalInsurancePolicyMember__c>();

        m.hipaaCensusMember = new Map<String, ARC_HipaaAuthorization__c>();
        m.hipaaThirdParty = new Map<String, ARC_HipaaAuthorization__c>();
        m.hipaaExternalContact = new Map<String, Contact>();
        m.hipaaLegalGuardian = new Map<String, ARC_HipaaAuthorization__c>();

        m.enrollmentInfo = new Map<String, Object>();
        return m;
    }

    // =========================
    // Account
    // =========================
    private static Account makeAccount(String name) {
        Account a = new Account(Name = name);
        insert a;
        return a;
    }

    // =========================
    // Census Setup
    // =========================
    private static vlocity_ins__GroupCensusMember__c makeCensus(String name) {

        if (sharedGroupId == null) {
            Account g = new Account(Name='Group');
            insert g;
            sharedGroupId = g.Id;

            vlocity_ins__GroupCensus__c c = new vlocity_ins__GroupCensus__c(
                Name='Census',
                vlocity_ins__GroupId__c=g.Id
            );
            insert c;

            sharedCensusId = c.Id;
        }

        vlocity_ins__GroupCensusMember__c m =
            new vlocity_ins__GroupCensusMember__c(
                Name=name,
                vlocity_ins__CensusId__c=sharedCensusId
            );

        insert m;
        return m;
    }

    // =========================
    // Policy
    // =========================
    private static InsurancePolicy makePolicy(Id accId) {
        InsurancePolicy p = new InsurancePolicy(
            Name='Policy',
            NameInsuredId=accId
        );
        insert p;
        return p;
    }

    // =========================
    // FIXED enrollment builder (NO SYNTAX ERRORS)
    // =========================
    private static void buildEnrollmentInfo(ARC_SGSEManager m, String k1, String k2) {

        List<Object> members = new List<Object>();

        Map<String, Object> primary = new Map<String, Object>();
        primary.put('role', 'Primary');
        primary.put('memberExternalId', k1);

        Map<String, Object> spouse = new Map<String, Object>();
        spouse.put('role', 'Spouse');
        spouse.put('memberExternalId', k2);

        members.add(primary);
        members.add(spouse);

        m.enrollmentInfo.put('members', members);
    }

    // =========================
    // ALL PATHS TEST
    // =========================
    @IsTest
    static void testProcessEnrollment_AllPaths() {

        ARC_SGSEManager m = buildManager();

        vlocity_ins__GroupCensusMember__c cm1 = makeCensus('M1');
        vlocity_ins__GroupCensusMember__c cm2 = makeCensus('M2');

        String k1 = cm1.Id;
        String k2 = cm2.Id;

        buildEnrollmentInfo(m, k1, k2);

        m.primaryCensusMemberId = k1;

        Account a1 = makeAccount('A1');
        Account a2 = makeAccount('A2');

        m.memberIdToAccountMap.put(k1, a1);
        m.memberIdToAccountMap.put(k2, a2);

        m.memberIdToCensusMemberMap.put(k1, cm1);
        m.memberIdToCensusMemberMap.put(k2, cm2);

        m.guardianToInsert = makeAccount('Guardian');

        m.policy = makePolicy(a1.Id);

        m.memberIdToFamilyRole.put(k1, 'Primary');
        m.memberIdToFamilyRole.put(k2, 'Spouse');

        m.memberIdToBirthdate.put(k1, Date.newInstance(1980,1,1));
        m.memberIdToBirthdate.put(k2, Date.newInstance(1990,1,1));

        InsurancePolicyParticipant pp1 = new InsurancePolicyParticipant(Role='Primary');
        InsurancePolicyParticipant pp2 = new InsurancePolicyParticipant(Role='Dependent');

        m.memberIdToPolicyParticipant.put(k1, pp1);
        m.memberIdToPolicyParticipant.put(k2, pp2);

        m.memberIdToBeneficiaries = new Map<String, Object>();

        Map<String, Object> primaryBeneficiary = new Map<String, Object>();
        primaryBeneficiary.put('firstName', 'Primary');
        primaryBeneficiary.put('lastName', 'Beneficiary');
        primaryBeneficiary.put('relationship', 'Spouse');
        primaryBeneficiary.put('otherRelationship', '');
        primaryBeneficiary.put('birthdate', '1985-01-15');
        primaryBeneficiary.put('phone', '5551112222');

        Map<String, Object> secondaryBeneficiary = new Map<String, Object>();
        secondaryBeneficiary.put('fullname', 'Secondary Beneficiary');
        secondaryBeneficiary.put('relationship', 'Other');
        secondaryBeneficiary.put('otherRelationship', 'Friend');
        secondaryBeneficiary.put('birthdate', '1991-02-20');
        secondaryBeneficiary.put('phone', '5551119999');

        Map<String, Object> beneficiariesByMember = new Map<String, Object>();
        beneficiariesByMember.put('primaryBeneficiary', primaryBeneficiary);
        beneficiariesByMember.put('secondaryBeneficiary', secondaryBeneficiary);

        m.memberIdToBeneficiaries.put(k1, beneficiariesByMember);

        Product2 medicalProduct = new Product2(
            Name = 'Test Medical Product',
            IsActive = true
        );
        medicalProduct.vlocity_ins__Type__c = 'Medical';
        insert medicalProduct;

        InsurancePolicyCoverage medicalParentCoverage = new InsurancePolicyCoverage(
            ARC_UnitPrice__c = 10,
            vlocity_ins_fsc__Product2Id__c = medicalProduct.Id
        );

        m.indexToParentCovToInsert.put('1', medicalParentCoverage);

        m.indexToChildCovToInsert.put('1',
            new List<InsurancePolicyCoverage>{
                new InsurancePolicyCoverage(ARC_UnitPrice__c=5)
            }
        );

        m.indexToMemberIds.put('1', new List<String>{k1, k2});

        m.externalPoliciesToInsert.put('PK1',
            new ARC_ExternalInsurancePolicy__c(
                ARC_InsurerName__c='Test Insurer'
            )
        );

        m.policyKeyToMemberIds.put('PK1', new List<String>{k1, k2});

        m.hipaaCensusMember.put(k1, new ARC_HipaaAuthorization__c(Name='H1'));
        m.hipaaExternalContact.put('TP', new Contact(LastName='TP'));
        m.hipaaThirdParty.put('TP', new ARC_HipaaAuthorization__c(Name='H2'));
        m.hipaaLegalGuardian.put('LG', new ARC_HipaaAuthorization__c(Name='H3'));

        Test.startTest();
        new ARC_SGSEDML().processEnrollment(m);
        Test.stopTest();

        System.assertNotEquals(null, m.guardianInserted);
    }

    // =========================
    // ROLLBACK TEST (FOR EXCEPTION PATH COVERAGE)
    // =========================
    @IsTest
    static void testProcessEnrollment_Rollback() {

        ARC_SGSEManager m = buildManager();

        vlocity_ins__GroupCensusMember__c cm = makeCensus('X');
        String key = cm.Id;

        Account acc = makeAccount('Broken');

        m.memberIdToAccountMap.put(key, acc);

        // IMPORTANT: must still set enrollmentInfo OR it may NPE
        buildEnrollmentInfo(m, key, key);

        // force failure in processPolicy()
        m.policy = null;

        Boolean failed = false;

        Test.startTest();
        try {
            new ARC_SGSEDML().processEnrollment(m);
        } catch (Exception e) {
            failed = true;
        }
        Test.stopTest();

        System.assertEquals(true, failed);
    }
}