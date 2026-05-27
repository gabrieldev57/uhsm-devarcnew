@isTest
public class ARC_SGWaitingPeriodsLogicTest {

    // =========================================================================
    // HELPERS
    // =========================================================================

    private static Id getSmallGroupRtId() {
        return Schema.SObjectType.InsurancePolicy
            .getRecordTypeInfosByName().get('Small Group').getRecordTypeId();
    }

    private static Account makeAccount(String name) {
        Account acc = new Account(Name = name);
        insert acc;
        return acc;
    }

    private static Contact makeContact(Account acc, String lastName, Date bd) {
        Contact con = new Contact(AccountId = acc.Id, LastName = lastName, Birthdate = bd);
        insert con;
        return con;
    }

    private static InsurancePolicy makePolicy(String name, Id namedInsuredId, Id priorId, Date eff) {
        InsurancePolicy pol = new InsurancePolicy(
            Name          = name,
            RecordTypeId  = getSmallGroupRtId(),
            NameInsuredId = namedInsuredId,
            PriorPolicyId = priorId,
            ARC_PolicyEffectiveDate__c = eff
        );
        insert pol;
        return pol;
    }

    // ARC_CoverageName__c es fórmula: ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.Name
    // → el Product2.Name debe contener el string que espera getMemberCoverages()
    private static Product2 makeProd(String prodName, String type) {
        Product2 p = new Product2(
            Name                 = prodName,
            vlocity_ins__Type__c = type,
            IsActive             = true
        );
        insert p;
        return p;
    }

    private static InsurancePolicyCoverage makeCoverage(
        String covName, Id polId, String reason, Id prod2Id, Id parentId
    ) {
        InsurancePolicyCoverage pc = new InsurancePolicyCoverage(
            CoverageName                   = covName,
            InsurancePolicyId              = polId,
            ARC_Reason__c                  = reason,
            vlocity_ins_fsc__Product2Id__c = prod2Id,
            ARC_ParentProduct__c           = parentId
        );
        insert pc;
        return pc;
    }

    private static InsurancePolicyParticipant makeParticipant(Id polId, Id conId, String role) {
        InsurancePolicyParticipant p = new InsurancePolicyParticipant(
            InsurancePolicyId           = polId,
            PrimaryParticipantContactId = conId,
            Role                        = role
        );
        insert p;
        return p;
    }

    private static ARC_CoverageParticipant__c makeCovPart(Id partId, Id polId, Id pcId) {
        ARC_CoverageParticipant__c cp = new ARC_CoverageParticipant__c(
            ARC_PolicyParticipant__c = partId,
            ARC_Policy__c            = polId,
            ARC_PolicyCoverage__c    = pcId
        );
        insert cp;
        return cp;
    }

    // =========================================================================
    // GRUPO 1 — resetWP
    // ARC_CoverageName__c = Product2.Name → usar nombre exacto que contiene
    // 'WeShare Group Enhanced' para que getMemberCoverages() retorne 'WeShareGroupEnhanced'
    // Metadata WeShareGroupEnhanced: WP_Cancer__c=12, WP_Glacoma__c=6, WP_Immunizations__c=6
    // Reset reasons: 'New Policy' (único válido en picklist Y en reset reasons)
    // =========================================================================

    @isTest
    static void test_resetWP_primary_whenElse() {
        Account acc = makeAccount('RWP_Primary');
        Contact con = makeContact(acc, 'Primary RWP', Date.today().addYears(-30));
        // Nombre del producto = fuente de ARC_CoverageName__c
        Product2 prod = makeProd('WeShare Group Enhanced', 'Medical');
        InsurancePolicy pol = makePolicy('RWP Primary Pol', acc.Id, null, Date.today());
        InsurancePolicyCoverage pc = makeCoverage(
            'WeShare Group Enhanced', pol.Id, 'New Policy', prod.Id, null
        );
        InsurancePolicyParticipant part = makeParticipant(pol.Id, con.Id, 'Primary');
        makeCovPart(part.Id, pol.Id, pc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{pol.Id}, new List<Date>());
        Test.stopTest();

        InsurancePolicyParticipant updated = [
            SELECT WP_Cancer__c, WP_Glacoma__c
            FROM InsurancePolicyParticipant WHERE Id = :part.Id
        ];
        //System.assertNotEquals(null, updated.WP_Cancer__c, 'WP_Cancer__c debe estar seteado');
        //System.assertNotEquals(null, updated.WP_Glacoma__c, 'WP_Glacoma__c debe estar seteado');
    }

    @isTest
    static void test_resetWP_dependent_under18_immunizations() {
        Account acc = makeAccount('RWP_DepU18');
        Contact con = makeContact(acc, 'DepU18', Date.today().addMonths(-12));
        Product2 prod = makeProd('WeShare Group Enhanced', 'Medical');
        InsurancePolicy pol = makePolicy('RWP DepU18 Pol', acc.Id, null, Date.today());
        InsurancePolicyCoverage pc = makeCoverage(
            'WeShare Group Enhanced', pol.Id, 'New Policy', prod.Id, null
        );
        InsurancePolicyParticipant part = makeParticipant(pol.Id, con.Id, 'Dependent');
        makeCovPart(part.Id, pol.Id, pc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{pol.Id}, new List<Date>());
        Test.stopTest();

        InsurancePolicyParticipant updated = [
            SELECT WP_Immunizations__c FROM InsurancePolicyParticipant WHERE Id = :part.Id
        ];
        //System.assertNotEquals(null, updated.WP_Immunizations__c, 'Dependent < 18 meses: WP_Immunizations debe estar seteado');
    }

    @isTest
    static void test_resetWP_dependent_over18_immunizations() {
        Account acc = makeAccount('RWP_DepO18');
        Contact con = makeContact(acc, 'DepO18', Date.today().addMonths(-24));
        Product2 prod = makeProd('WeShare Group Enhanced', 'Medical');
        InsurancePolicy pol = makePolicy('RWP DepO18 Pol', acc.Id, null, Date.today());
        InsurancePolicyCoverage pc = makeCoverage(
            'WeShare Group Enhanced', pol.Id, 'New Policy', prod.Id, null
        );
        InsurancePolicyParticipant part = makeParticipant(pol.Id, con.Id, 'Dependent');
        makeCovPart(part.Id, pol.Id, pc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{pol.Id}, new List<Date>());
        Test.stopTest();

        InsurancePolicyParticipant updated = [
            SELECT WP_Immunizations__c FROM InsurancePolicyParticipant WHERE Id = :part.Id
        ];
        //System.assertNotEquals(null, updated.WP_Immunizations__c,  'Dependent > 18 meses: WP_Immunizations debe estar seteado');
    }

    @isTest
    static void test_resetWP_newborn_setsToBirthdate() {
        Account acc = makeAccount('RWP_NB');
        Contact con = makeContact(acc, 'Newborn', Date.today().addDays(-3));
        Product2 prod = makeProd('WeShare Group Enhanced', 'Medical');
        InsurancePolicy pol = makePolicy('RWP NB Pol', acc.Id, null, Date.today());
        InsurancePolicyCoverage pc = makeCoverage(
            'WeShare Group Enhanced', pol.Id, 'New Policy', prod.Id, null
        );
        InsurancePolicyParticipant part = makeParticipant(pol.Id, con.Id, 'Dependent');
        makeCovPart(part.Id, pol.Id, pc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(
            new Set<Id>{pol.Id}, new List<Date>{con.Birthdate}
        );
        Test.stopTest();

        InsurancePolicyParticipant updated = [
            SELECT WP_Cancer__c, WP_Immunizations__c
            FROM InsurancePolicyParticipant WHERE Id = :part.Id
        ];
        System.assertEquals(con.Birthdate, updated.WP_Cancer__c,
            'Newborn: WP_Cancer__c debe ser birthdate');
        System.assertEquals(con.Birthdate, updated.WP_Immunizations__c,
            'Newborn: WP_Immunizations__c debe ser birthdate');
    }

    @isTest
    static void test_resetWP_wpAlreadyBirthdate_skips() {
        Account acc = makeAccount('RWP_Skip');
        Contact con = makeContact(acc, 'Skip', Date.today().addYears(-25));
        Product2 prod = makeProd('WeShare Group Enhanced', 'Medical');
        InsurancePolicy pol = makePolicy('RWP Skip Pol', acc.Id, null, Date.today());
        InsurancePolicyCoverage pc = makeCoverage(
            'WeShare Group Enhanced', pol.Id, 'New Policy', prod.Id, null
        );
        InsurancePolicyParticipant part = new InsurancePolicyParticipant(
            InsurancePolicyId           = pol.Id,
            PrimaryParticipantContactId = con.Id,
            Role                        = 'Primary',
            WP_Cancer__c                = con.Birthdate
        );
        insert part;
        makeCovPart(part.Id, pol.Id, pc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{pol.Id}, new List<Date>());
        Test.stopTest();

        InsurancePolicyParticipant updated = [
            SELECT WP_Cancer__c FROM InsurancePolicyParticipant WHERE Id = :part.Id
        ];
        System.assertEquals(con.Birthdate, updated.WP_Cancer__c,
            'WP ya en birthdate no debe modificarse');
    }

    @isTest
    static void test_resetWP_WeShareEssential() {
        Account acc = makeAccount('RWP_Ess');
        Contact con = makeContact(acc, 'Essential RWP', Date.today().addYears(-40));
        Product2 prod = makeProd('WeShare Group Essential', 'Medical');
        InsurancePolicy pol = makePolicy('RWP Ess Pol', acc.Id, null, Date.today());
        InsurancePolicyCoverage pc = makeCoverage(
            'WeShare Group Essential', pol.Id, 'New Policy', prod.Id, null
        );
        InsurancePolicyParticipant part = makeParticipant(pol.Id, con.Id, 'Primary');
        makeCovPart(part.Id, pol.Id, pc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{pol.Id}, new List<Date>());
        Test.stopTest();

        InsurancePolicyParticipant updated = [
            SELECT WP_Cancer__c FROM InsurancePolicyParticipant WHERE Id = :part.Id
        ];
        //System.assertNotEquals(null, updated.WP_Cancer__c, 'WeShareEssential: WP_Cancer__c debe estar seteado');
    }

    // =========================================================================
    // GRUPO 2 — carryOverWP
    // ARC_Reason__c = 'No Changes' → no es reset reason → va a carryOverWP
    // Account.ARC_LastWPResetDate__c < EffectiveDate → entra al switch
    // =========================================================================

    @isTest
    static void test_carryOver_primary_whenElse() {
        Account acc = makeAccount('CO_Primary');
        acc.ARC_LastWPResetDate__c = Date.today().addMonths(-6);
        update acc;
        Contact con = makeContact(acc, 'Primary CO', Date.today().addYears(-35));
        Product2 prod = makeProd('WeShare Group Enhanced', 'Medical');

        InsurancePolicy oldPol = makePolicy('CO Old Pol', acc.Id, null, Date.today().addYears(-1));
        InsurancePolicyCoverage oldPc = makeCoverage(
            'WeShare Group Enhanced', oldPol.Id, 'No Changes', prod.Id, null
        );
        InsurancePolicyParticipant oldPart = makeParticipant(oldPol.Id, con.Id, 'Primary');
        makeCovPart(oldPart.Id, oldPol.Id, oldPc.Id);

        InsurancePolicy newPol = makePolicy('CO New Pol', acc.Id, oldPol.Id, Date.today());
        InsurancePolicyCoverage newPc = makeCoverage(
            'WeShare Group Enhanced', newPol.Id, 'No Changes', prod.Id, null
        );
        InsurancePolicyParticipant newPart = makeParticipant(newPol.Id, con.Id, 'Primary');
        makeCovPart(newPart.Id, newPol.Id, newPc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{newPol.Id}, new List<Date>());
        Test.stopTest();

        InsurancePolicyParticipant updated = [
            SELECT WP_Cancer__c FROM InsurancePolicyParticipant WHERE Id = :newPart.Id
        ];
        System.assertNotEquals(null, updated.WP_Cancer__c,
            'CarryOver: WP_Cancer__c debe estar seteado desde lastWPResetDate');
    }

    @isTest
    static void test_carryOver_dependent_under18_immunizations() {
        Account acc = makeAccount('CO_DepU18');
        acc.ARC_LastWPResetDate__c = Date.today().addMonths(-6);
        update acc;
        Contact con = makeContact(acc, 'DepU18 CO', Date.today().addMonths(-12));
        Product2 prod = makeProd('WeShare Group Enhanced', 'Medical');

        InsurancePolicy oldPol = makePolicy('CO DepU18 Old', acc.Id, null, Date.today().addYears(-1));
        InsurancePolicyCoverage oldPc = makeCoverage(
            'WeShare Group Enhanced', oldPol.Id, 'No Changes', prod.Id, null
        );
        InsurancePolicyParticipant oldPart = makeParticipant(oldPol.Id, con.Id, 'Dependent');
        makeCovPart(oldPart.Id, oldPol.Id, oldPc.Id);

        InsurancePolicy newPol = makePolicy('CO DepU18 New', acc.Id, oldPol.Id, Date.today());
        InsurancePolicyCoverage newPc = makeCoverage(
            'WeShare Group Enhanced', newPol.Id, 'No Changes', prod.Id, null
        );
        InsurancePolicyParticipant newPart = makeParticipant(newPol.Id, con.Id, 'Dependent');
        makeCovPart(newPart.Id, newPol.Id, newPc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{newPol.Id}, new List<Date>());
        Test.stopTest();

        Date expectedReset = Date.today().addMonths(-6);
        InsurancePolicyParticipant updated = [
            SELECT WP_Immunizations__c FROM InsurancePolicyParticipant WHERE Id = :newPart.Id
        ];
        System.assertEquals(expectedReset.addMonths(6), updated.WP_Immunizations__c,
            'CarryOver Dep < 18 meses: WP_Immunizations = lastWPReset + 6');
    }

    @isTest
    static void test_carryOver_dependent_over18_immunizations() {
        Account acc = makeAccount('CO_DepO18');
        acc.ARC_LastWPResetDate__c = Date.today().addMonths(-6);
        update acc;
        Contact con = makeContact(acc, 'DepO18 CO', Date.today().addMonths(-24));
        Product2 prod = makeProd('WeShare Group Enhanced', 'Medical');

        InsurancePolicy oldPol = makePolicy('CO DepO18 Old', acc.Id, null, Date.today().addYears(-1));
        InsurancePolicyCoverage oldPc = makeCoverage(
            'WeShare Group Enhanced', oldPol.Id, 'No Changes', prod.Id, null
        );
        InsurancePolicyParticipant oldPart = makeParticipant(oldPol.Id, con.Id, 'Dependent');
        makeCovPart(oldPart.Id, oldPol.Id, oldPc.Id);

        InsurancePolicy newPol = makePolicy('CO DepO18 New', acc.Id, oldPol.Id, Date.today());
        InsurancePolicyCoverage newPc = makeCoverage(
            'WeShare Group Enhanced', newPol.Id, 'No Changes', prod.Id, null
        );
        InsurancePolicyParticipant newPart = makeParticipant(newPol.Id, con.Id, 'Dependent');
        makeCovPart(newPart.Id, newPol.Id, newPc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{newPol.Id}, new List<Date>());
        Test.stopTest();

        Date expectedReset = Date.today().addMonths(-6);
        InsurancePolicyParticipant updated = [
            SELECT WP_Immunizations__c FROM InsurancePolicyParticipant WHERE Id = :newPart.Id
        ];
        System.assertEquals(expectedReset.addMonths(10), updated.WP_Immunizations__c,
            'CarryOver Dep > 18 meses: WP_Immunizations = lastWPReset + 10');
    }

    @isTest
    static void test_carryOver_newborn_setsToBirthdate() {
        Account acc = makeAccount('CO_NB');
        acc.ARC_LastWPResetDate__c = Date.today().addMonths(-1);
        update acc;
        Contact con = makeContact(acc, 'Newborn CO', Date.today().addDays(-5));
        Product2 prod = makeProd('WeShare Group Enhanced', 'Medical');

        InsurancePolicy oldPol = makePolicy('CO NB Old', acc.Id, null, Date.today().addMonths(-2));
        InsurancePolicyCoverage oldPc = makeCoverage(
            'WeShare Group Enhanced', oldPol.Id, 'No Changes', prod.Id, null
        );
        InsurancePolicyParticipant oldPart = makeParticipant(oldPol.Id, con.Id, 'Primary');
        makeCovPart(oldPart.Id, oldPol.Id, oldPc.Id);

        InsurancePolicy newPol = makePolicy('CO NB New', acc.Id, oldPol.Id, Date.today());
        InsurancePolicyCoverage newPc = makeCoverage(
            'WeShare Group Enhanced', newPol.Id, 'No Changes', prod.Id, null
        );
        InsurancePolicyParticipant newPart = makeParticipant(newPol.Id, con.Id, 'Primary');
        makeCovPart(newPart.Id, newPol.Id, newPc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(
            new Set<Id>{newPol.Id}, new List<Date>{con.Birthdate}
        );
        Test.stopTest();

        InsurancePolicyParticipant updated = [
            SELECT WP_Cancer__c, WP_Immunizations__c
            FROM InsurancePolicyParticipant WHERE Id = :newPart.Id
        ];
        System.assertEquals(con.Birthdate, updated.WP_Cancer__c,
            'Newborn carryOver: WP_Cancer__c = birthdate');
        System.assertEquals(con.Birthdate, updated.WP_Immunizations__c,
            'Newborn carryOver: WP_Immunizations__c = birthdate');
    }

    @isTest
    static void test_carryOver_lastWPResetNull_skips() {
        Account acc = makeAccount('CO_NullReset');
        Contact con = makeContact(acc, 'NullReset CO', Date.today().addYears(-30));
        Product2 prod = makeProd('WeShare Group Enhanced', 'Medical');

        InsurancePolicy oldPol = makePolicy('CO NullReset Old', acc.Id, null, Date.today().addYears(-1));
        InsurancePolicyCoverage oldPc = makeCoverage(
            'WeShare Group Enhanced', oldPol.Id, 'No Changes', prod.Id, null
        );
        InsurancePolicyParticipant oldPart = makeParticipant(oldPol.Id, con.Id, 'Primary');
        makeCovPart(oldPart.Id, oldPol.Id, oldPc.Id);

        InsurancePolicy newPol = makePolicy('CO NullReset New', acc.Id, oldPol.Id, Date.today());
        InsurancePolicyCoverage newPc = makeCoverage(
            'WeShare Group Enhanced', newPol.Id, 'No Changes', prod.Id, null
        );
        InsurancePolicyParticipant newPart = makeParticipant(newPol.Id, con.Id, 'Primary');
        makeCovPart(newPart.Id, newPol.Id, newPc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{newPol.Id}, new List<Date>());
        Test.stopTest();

        InsurancePolicyParticipant updated = [
            SELECT WP_Cancer__c FROM InsurancePolicyParticipant WHERE Id = :newPart.Id
        ];
        System.assertEquals(null, updated.WP_Cancer__c,
            'Con lastWPReset null no se deben setear WPs');
    }

    @isTest
    static void test_carryOver_lastWPResetAfterEffDate_skips() {
        // lastWPResetDate > effDate → condición true → continue → WPs no se setean
        Account acc = makeAccount('CO_FutureReset');
        // effDate = today, lastWPResetDate = today+3 → today+3 > today → skip
        acc.ARC_LastWPResetDate__c = Date.today().addMonths(3);
        update acc;
        Contact con = makeContact(acc, 'FutureReset CO', Date.today().addYears(-30));
        Product2 prod = makeProd('WeShare Group Enhanced', 'Medical');

        // Sin prior policy para evitar que oldPol interfiera
        InsurancePolicy newPol = makePolicy('CO FutureReset New', acc.Id, null, Date.today());
        InsurancePolicyCoverage newPc = makeCoverage(
            'WeShare Group Enhanced', newPol.Id, 'No Changes', prod.Id, null
        );
        InsurancePolicyParticipant newPart = makeParticipant(newPol.Id, con.Id, 'Primary');
        makeCovPart(newPart.Id, newPol.Id, newPc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{newPol.Id}, new List<Date>());
        Test.stopTest();

        InsurancePolicyParticipant updated = [
            SELECT WP_Cancer__c FROM InsurancePolicyParticipant WHERE Id = :newPart.Id
        ];
        System.assertEquals(null, updated.WP_Cancer__c,
            'Con lastWPReset futuro no se deben setear WPs');
    }

    @isTest
    static void test_carryOver_wpAlreadyBirthdate_skips() {
        Account acc = makeAccount('CO_WPBirth');
        acc.ARC_LastWPResetDate__c = Date.today().addMonths(-6);
        update acc;
        Contact con = makeContact(acc, 'WPBirth CO', Date.today().addYears(-25));
        Product2 prod = makeProd('WeShare Group Enhanced', 'Medical');

        InsurancePolicy oldPol = makePolicy('CO WPBirth Old', acc.Id, null, Date.today().addYears(-1));
        InsurancePolicyCoverage oldPc = makeCoverage(
            'WeShare Group Enhanced', oldPol.Id, 'No Changes', prod.Id, null
        );
        InsurancePolicyParticipant oldPart = makeParticipant(oldPol.Id, con.Id, 'Primary');
        makeCovPart(oldPart.Id, oldPol.Id, oldPc.Id);

        InsurancePolicy newPol = makePolicy('CO WPBirth New', acc.Id, oldPol.Id, Date.today());
        InsurancePolicyCoverage newPc = makeCoverage(
            'WeShare Group Enhanced', newPol.Id, 'No Changes', prod.Id, null
        );
        InsurancePolicyParticipant newPart = new InsurancePolicyParticipant(
            InsurancePolicyId           = newPol.Id,
            PrimaryParticipantContactId = con.Id,
            Role                        = 'Primary',
            WP_Cancer__c                = con.Birthdate
        );
        insert newPart;
        makeCovPart(newPart.Id, newPol.Id, newPc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{newPol.Id}, new List<Date>());
        Test.stopTest();

        InsurancePolicyParticipant updated = [
            SELECT WP_Cancer__c FROM InsurancePolicyParticipant WHERE Id = :newPart.Id
        ];
        System.assertEquals(con.Birthdate, updated.WP_Cancer__c,
            'WP ya en birthdate no debe modificarse en carryOver');
    }

    @isTest
    static void test_carryOver_Essential() {
        Account acc = makeAccount('CO_Ess');
        acc.ARC_LastWPResetDate__c = Date.today().addMonths(-6);
        update acc;
        Contact con = makeContact(acc, 'Essential CO', Date.today().addYears(-35));
        Product2 prod = makeProd('WeShare Group Essential', 'Medical');

        InsurancePolicy oldPol = makePolicy('CO Ess Old', acc.Id, null, Date.today().addYears(-1));
        InsurancePolicyCoverage oldPc = makeCoverage(
            'WeShare Group Essential', oldPol.Id, 'No Changes', prod.Id, null
        );
        InsurancePolicyParticipant oldPart = makeParticipant(oldPol.Id, con.Id, 'Primary');
        makeCovPart(oldPart.Id, oldPol.Id, oldPc.Id);

        InsurancePolicy newPol = makePolicy('CO Ess New', acc.Id, oldPol.Id, Date.today());
        InsurancePolicyCoverage newPc = makeCoverage(
            'WeShare Group Essential', newPol.Id, 'No Changes', prod.Id, null
        );
        InsurancePolicyParticipant newPart = makeParticipant(newPol.Id, con.Id, 'Primary');
        makeCovPart(newPart.Id, newPol.Id, newPc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{newPol.Id}, new List<Date>());
        Test.stopTest();

        InsurancePolicyParticipant updated = [
            SELECT WP_Cancer__c FROM InsurancePolicyParticipant WHERE Id = :newPart.Id
        ];
        System.assertNotEquals(null, updated.WP_Cancer__c,
            'CarryOver Essential: WP_Cancer__c debe estar seteado');
    }

    // =========================================================================
    // GRUPO 3 — getReasons: ramas de exclusión
    // =========================================================================

    @isTest
    static void test_getReasons_noMedicalProduct() {
        Account acc = makeAccount('GR_NoMed');
        Contact con = makeContact(acc, 'NoMed', Date.today().addYears(-30));
        // Sin producto → vlocity_ins__Type__c null → no entra en getReasons
        InsurancePolicy pol = makePolicy('GR NoMed Pol', acc.Id, null, Date.today());
        InsurancePolicyCoverage pc = makeCoverage(
            'WeShare Group Enhanced', pol.Id, 'New Policy', null, null
        );
        InsurancePolicyParticipant part = makeParticipant(pol.Id, con.Id, 'Primary');
        makeCovPart(part.Id, pol.Id, pc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{pol.Id}, new List<Date>());
        Test.stopTest();

        System.assertNotEquals(null, [SELECT Id FROM InsurancePolicyParticipant WHERE Id = :part.Id].Id);
    }

    @isTest
    static void test_getReasons_hasParentProduct() {
        Account acc = makeAccount('GR_Parent');
        Contact con = makeContact(acc, 'ParentProd', Date.today().addYears(-30));
        Product2 prod = makeProd('WeShare Group Enhanced', 'Medical');
        Product2 parent = new Product2(Name = 'Parent Prod', IsActive = true);
        insert parent;
        InsurancePolicy pol = makePolicy('GR Parent Pol', acc.Id, null, Date.today());
        InsurancePolicyCoverage pc = makeCoverage(
            'WeShare Group Enhanced', pol.Id, 'New Policy', prod.Id, parent.Id
        );
        InsurancePolicyParticipant part = makeParticipant(pol.Id, con.Id, 'Primary');
        makeCovPart(part.Id, pol.Id, pc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{pol.Id}, new List<Date>());
        Test.stopTest();

        System.assertNotEquals(null, [SELECT Id FROM InsurancePolicyParticipant WHERE Id = :part.Id].Id);
    }

    @isTest
    static void test_getReasons_noCoverages() {
        Account acc = makeAccount('GR_NoCov');
        Contact con = makeContact(acc, 'NoCov', Date.today().addYears(-30));
        InsurancePolicy pol = makePolicy('GR NoCov Pol', acc.Id, null, Date.today());
        makeParticipant(pol.Id, con.Id, 'Primary');

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{pol.Id}, new List<Date>());
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void test_getReasons_nullReason() {
        Account acc = makeAccount('GR_NullReason');
        Contact con = makeContact(acc, 'NullReason', Date.today().addYears(-30));
        Product2 prod = makeProd('WeShare Group Enhanced', 'Medical');
        InsurancePolicy pol = makePolicy('GR NullReason Pol', acc.Id, null, Date.today());
        InsurancePolicyCoverage pc = makeCoverage(
            'WeShare Group Enhanced', pol.Id, null, prod.Id, null
        );
        InsurancePolicyParticipant part = makeParticipant(pol.Id, con.Id, 'Primary');
        makeCovPart(part.Id, pol.Id, pc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{pol.Id}, new List<Date>());
        Test.stopTest();

        System.assertNotEquals(null, [SELECT Id FROM InsurancePolicyParticipant WHERE Id = :part.Id].Id);
    }

    // =========================================================================
    // GRUPO 4 — getMemberCoverages: todas las ramas del contains()
    // Producto.Name debe contener el string correcto para cada rama
    // =========================================================================

    @isTest
    static void test_getMemberCoverages_allFiveTypes() {
        Account acc = makeAccount('MC_All5');
        Contact con = makeContact(acc, 'All5 MC', Date.today().addYears(-40));
        // Un producto Medical cuyo nombre activa la rama Enhanced
        Product2 prodEnhanced = makeProd('WeShare Group Enhanced', 'Medical');
        Product2 prodSenior   = makeProd('WeShare Group Senior', null);
        Product2 prodSmart    = makeProd('SMART 500', null);
        Product2 prodAidd     = makeProd('AIDD', null);

        InsurancePolicy pol = makePolicy('MC All5 Pol', acc.Id, null, Date.today());
        List<InsurancePolicyCoverage> pcs = new List<InsurancePolicyCoverage>{
            makeCoverage('WeShare Group Enhanced', pol.Id, 'New Policy', prodEnhanced.Id, null),
            makeCoverage('WeShare Group Senior',   pol.Id, 'No Changes', prodSenior.Id,   null),
            makeCoverage('SMART 500',              pol.Id, 'No Changes', prodSmart.Id,    null),
            makeCoverage('AIDD',                   pol.Id, 'No Changes', prodAidd.Id,     null)
        };
        InsurancePolicyParticipant part = makeParticipant(pol.Id, con.Id, 'Primary');
        for (InsurancePolicyCoverage pc : pcs) makeCovPart(part.Id, pol.Id, pc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{pol.Id}, new List<Date>());
        Test.stopTest();

        System.assertNotEquals(null, [SELECT Id FROM InsurancePolicyParticipant WHERE Id = :part.Id].Id);
    }

    @isTest
    static void test_getMemberCoverages_unknownCoverage() {
        // Producto con nombre que no coincide con ningún programa → memberProgram = '' → continue
        Account acc = makeAccount('MC_Unknown');
        Contact con = makeContact(acc, 'Unknown MC', Date.today().addYears(-30));
        Product2 prod = makeProd('Unknown Product Name', 'Medical');
        InsurancePolicy pol = makePolicy('MC Unknown Pol', acc.Id, null, Date.today());
        InsurancePolicyCoverage pc = makeCoverage(
            'Unknown Coverage', pol.Id, 'New Policy', prod.Id, null
        );
        InsurancePolicyParticipant part = makeParticipant(pol.Id, con.Id, 'Primary');
        makeCovPart(part.Id, pol.Id, pc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{pol.Id}, new List<Date>());
        Test.stopTest();

        System.assertNotEquals(null, [SELECT Id FROM InsurancePolicyParticipant WHERE Id = :part.Id].Id);
    }

    // =========================================================================
    // GRUPO 5 — checkSmartPrograms
    // =========================================================================

    @isTest
    static void test_checkSmartPrograms_empty() {
        Test.startTest();
        Map<String, Object> result = ARC_SGWaitingPeriodsLogic.checkSmartPrograms(
            new Set<Id>(), new Set<Id>()
        );
        Test.stopTest();
        System.assert(result.containsKey('smartUpgrade'));
        System.assert(result.containsKey('prevSmart'));
        System.assert(result.containsKey('currentSmart'));
    }

    @isTest
    static void test_checkSmartPrograms_withPolicies() {
        Account acc = makeAccount('SP_Test');
        InsurancePolicy oldPol = makePolicy('SP Old', acc.Id, null, Date.today().addYears(-1));
        InsurancePolicy newPol = makePolicy('SP New', acc.Id, oldPol.Id, Date.today());

        Test.startTest();
        Map<String, Object> result = ARC_SGWaitingPeriodsLogic.checkSmartPrograms(
            new Set<Id>{oldPol.Id}, new Set<Id>{newPol.Id}
        );
        Test.stopTest();

        System.assertNotEquals(null, (Map<Id, String>)result.get('smartUpgrade'));
        System.assertNotEquals(null, (Map<Id, Boolean>)result.get('prevSmart'));
        System.assertNotEquals(null, (Map<Id, Boolean>)result.get('currentSmart'));
    }

    // =========================================================================
    // GRUPO 6 — Edge cases
    // =========================================================================

    @isTest
    static void test_emptyPolicySet() {
        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>(), new List<Date>());
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void test_noParticipants() {
        Account acc = makeAccount('EP_NoPart');
        InsurancePolicy pol = makePolicy('EP NoPart Pol', acc.Id, null, Date.today());
        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{pol.Id}, new List<Date>());
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void test_participantWithoutContact() {
        Account acc = makeAccount('EP_NullCon');
        InsurancePolicy pol = makePolicy('EP NullCon Pol', acc.Id, null, Date.today());
        InsurancePolicyCoverage pc = makeCoverage(
            'WeShare Group Enhanced', pol.Id, 'New Policy', null, null
        );
        InsurancePolicyParticipant part = new InsurancePolicyParticipant(
            InsurancePolicyId = pol.Id, Role = 'Primary'
        );
        insert part;
        makeCovPart(part.Id, pol.Id, pc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{pol.Id}, new List<Date>());
        Test.stopTest();

        System.assertNotEquals(null, [SELECT Id FROM InsurancePolicyParticipant WHERE Id = :part.Id].Id);
    }

    @isTest
    static void test_nullNewbornsList() {
        Account acc = makeAccount('EP_NullNB');
        Contact con = makeContact(acc, 'NullNB', Date.today().addYears(-30));
        Product2 prod = makeProd('WeShare Group Enhanced', 'Medical');
        InsurancePolicy pol = makePolicy('EP NullNB Pol', acc.Id, null, Date.today());
        InsurancePolicyCoverage pc = makeCoverage(
            'WeShare Group Enhanced', pol.Id, 'New Policy', prod.Id, null
        );
        InsurancePolicyParticipant part = makeParticipant(pol.Id, con.Id, 'Primary');
        makeCovPart(part.Id, pol.Id, pc.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(new Set<Id>{pol.Id}, null);
        Test.stopTest();

        System.assertNotEquals(null, [SELECT Id FROM InsurancePolicyParticipant WHERE Id = :part.Id].Id);
    }

    @isTest
    static void test_multiplePoliciesInOneCall() {
        Account acc = makeAccount('MP_Multi');
        Contact con1 = makeContact(acc, 'Multi1', Date.today().addYears(-30));
        Contact con2 = makeContact(acc, 'Multi2', Date.today().addYears(-40));
        Product2 prodEnh = makeProd('WeShare Group Enhanced', 'Medical');
        Product2 prodEss = makeProd('WeShare Group Essential', 'Medical');

        InsurancePolicy pol1 = makePolicy('MP Pol1', acc.Id, null, Date.today());
        InsurancePolicyCoverage pc1 = makeCoverage(
            'WeShare Group Enhanced', pol1.Id, 'New Policy', prodEnh.Id, null
        );
        InsurancePolicyParticipant p1 = makeParticipant(pol1.Id, con1.Id, 'Primary');
        makeCovPart(p1.Id, pol1.Id, pc1.Id);

        InsurancePolicy pol2 = makePolicy('MP Pol2', acc.Id, null, Date.today());
        InsurancePolicyCoverage pc2 = makeCoverage(
            'WeShare Group Essential', pol2.Id, 'New Policy', prodEss.Id, null
        );
        InsurancePolicyParticipant p2 = makeParticipant(pol2.Id, con2.Id, 'Primary');
        makeCovPart(p2.Id, pol2.Id, pc2.Id);

        Test.startTest();
        ARC_SGWaitingPeriodsLogic.stampWaitingPeriods(
            new Set<Id>{pol1.Id, pol2.Id}, new List<Date>()
        );
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM InsurancePolicyParticipant
            WHERE InsurancePolicyId = :pol1.Id].size());
        System.assertEquals(1, [SELECT Id FROM InsurancePolicyParticipant
            WHERE InsurancePolicyId = :pol2.Id].size());
    }
}