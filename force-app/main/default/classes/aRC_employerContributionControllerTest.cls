@IsTest
public without sharing class aRC_employerContributionControllerTest {

    private static Opportunity makeOppFromCensus(Id censusId) {
        vlocity_ins__GroupCensus__c census = [
            SELECT Id, vlocity_ins__GroupId__c
            FROM vlocity_ins__GroupCensus__c
            WHERE Id = :censusId
            LIMIT 1
        ];

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = census.vlocity_ins__GroupId__c
        );
        insert opp;
        return opp;
    }

    private static void setMember(vlocity_ins__GroupCensusMember__c m, String empType, String empDiv) {
        m.ARC_EmployeeType__c = empType;
        m.ARC_EmployeeDivision__c = empDiv;
    }

    @IsTest
    static void test_getGroupClassPreview_Combined_Counts() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(4);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        setMember(members[0], 'Full Time', 'Exempt');
        setMember(members[1], 'Full Time', 'Non-Exempt');
        setMember(members[2], 'Part Time', 'Exempt');
        setMember(members[3], 'Part Time', 'Non-Exempt');
        update members;

        Test.startTest();
        aRC_employerContributionController.PreviewData dto =
            aRC_employerContributionController.getGroupClassPreview(opp.Id, 'COMBINED');
        Test.stopTest();

        System.assertNotEquals(null, dto);
        System.assertEquals(true, dto.hasCensus);
        System.assertEquals(0, dto.unknownCount);
        System.assertEquals(4, dto.rows.size());

        Map<String, Integer> byLabel = new Map<String, Integer>();
        for (aRC_employerContributionController.GroupClassRow r : dto.rows) {
            byLabel.put(r.label, r.memberCount);
        }

        System.assertEquals(1, byLabel.get('Full Time – Exempt'));
        System.assertEquals(1, byLabel.get('Full Time – Non-Exempt'));
        System.assertEquals(1, byLabel.get('Part Time – Exempt'));
        System.assertEquals(1, byLabel.get('Part Time – Non-Exempt'));
    }

    @IsTest
    static void test_resetGroupClasses_deletes_and_resets_flag() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(1);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        vlocity_ins__GroupClass__c gc = new vlocity_ins__GroupClass__c(
            Name = 'ToDelete',
            ARC_Opportunity__c = opp.Id,
            vlocity_ins__GroupId__c = opp.AccountId
        );
        insert gc;

        opp.ARC_GroupClassesContributionsDefined__c = true;
        update opp;

        Test.startTest();
        aRC_employerContributionController.resetGroupClasses(opp.Id);
        Test.stopTest();

        Integer remaining = [
            SELECT COUNT()
            FROM vlocity_ins__GroupClass__c
            WHERE ARC_Opportunity__c = :opp.Id
        ];
        System.assertEquals(0, remaining);

        Opportunity refreshed = [
            SELECT ARC_GroupClassesContributionsDefined__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        System.assertEquals(false, refreshed.ARC_GroupClassesContributionsDefined__c);
    }

    @IsTest
    static void test_getGroupClassFromOpportunity_returns_contributions_and_programs() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(1);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        Contract draft = new Contract(
            AccountId = opp.AccountId,
            Status = 'Draft',
            StartDate = Date.today()
        );
        insert draft;

        opp.ContractId = draft.Id;
        update opp;

        vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c(
            Name = 'CLI-1',
            vlocity_ins__ContractId__c = draft.Id
        );
        insert cli;

        vlocity_ins__GroupClass__c gc = new vlocity_ins__GroupClass__c(
            Name = 'GC1',
            ARC_Opportunity__c = opp.Id,
            vlocity_ins__GroupId__c = opp.AccountId,
            ARC_EmployeeTypeModel__c = 'FullTime_PartTime',
            ARC_EmployeeType__c = 'Full Time',
            ARC_EmployeeDivision__c = 'Exempt',
            ARC_ContributionMethod__c = 'Flat_Percentage'
        );
        insert gc;

        vlocity_ins__GroupClassContribution__c c = new vlocity_ins__GroupClassContribution__c(
            vlocity_ins__GroupClassId__c = gc.Id,
            ARC_ContractLineItem__c = cli.Id,
            vlocity_ins__ContributionPercent__c = 5,
            vlocity_ins__ProductCategory__c = 'Medical',
            vlocity_ins__ContributionType__c = 'Percent'
        );
        insert c;

        Test.startTest();
        Map<String,Object> payload =
            aRC_employerContributionController.getGroupClassFromOpportunity(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, payload);

        List<Object> gcs = (List<Object>) payload.get('groupClasses');
        System.assertEquals(1, gcs.size());

        Map<String,Object> gcMap = (Map<String,Object>) gcs[0];
        System.assertEquals(true, (Boolean) gcMap.get('hasContributions'));

        List<Object> programs = (List<Object>) gcMap.get('programs');
        System.assertEquals(1, programs.size());

        Map<String,Object> prog = (Map<String,Object>) programs[0];
        List<Object> contribs = (List<Object>) prog.get('contributions');
        System.assertEquals(1, contribs.size());

        Map<String,Object> contribMap = (Map<String,Object>) contribs[0];
        System.assertEquals('Medical', (String) contribMap.get('vlocity_ins__ProductCategory__c'));
    }

    @IsTest
    static void test_getGroupClassPreview_Exempt_Counts() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(2);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        members[0].ARC_EmployeeDivision__c = 'Exempt';
        members[1].ARC_EmployeeDivision__c = 'Non-Exempt';
        update members;

        aRC_employerContributionController.PreviewData dto =
            aRC_employerContributionController.getGroupClassPreview(opp.Id, 'EXEMPT');

        Map<String,Integer> byLabel = new Map<String,Integer>();
        for (aRC_employerContributionController.GroupClassRow r : dto.rows) {
            byLabel.put(r.label, r.memberCount);
        }

        System.assertEquals(1, byLabel.get('Exempt'));
        System.assertEquals(1, byLabel.get('Non-Exempt'));
    }

    @IsTest
    static void test_getGroupClassPreview_UnknownCount() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(2);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        members[0].ARC_EmployeeType__c = null;
        members[0].ARC_EmployeeDivision__c = null;
        members[1].ARC_EmployeeType__c = 'Full Time';
        members[1].ARC_EmployeeDivision__c = 'Exempt';
        update members;

        aRC_employerContributionController.PreviewData dto =
            aRC_employerContributionController.getGroupClassPreview(opp.Id, 'COMBINED');

        System.assertEquals(1, dto.unknownCount);
    }

    @IsTest
    static void test_createGroupClassesAndAssignMembers_None_ReuseGeneral() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(2);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        vlocity_ins__GroupClass__c gc = new vlocity_ins__GroupClass__c(
            Name = 'General',
            vlocity_ins__GroupId__c = opp.AccountId,
            ARC_Opportunity__c = opp.Id,
            ARC_EmployeeTypeModel__c = 'None',
            ARC_EmployeeType__c = 'None',
            ARC_EmployeeDivision__c = 'None',
            vlocity_ins__IsActive__c = true
        );
        insert gc;

        aRC_employerContributionController.CreateRequest req =
            new aRC_employerContributionController.CreateRequest();
        req.opportunityId = opp.Id;
        req.segmentationMode = 'NONE';
        req.includeEmptyChoice = 'EXCLUDE_EMPTY';

        aRC_employerContributionController.CreateResponse resp =
            aRC_employerContributionController.createGroupClassesAndAssignMembers(req);

        System.assertEquals(true, resp.success);
        System.assertEquals(0, resp.groupClassesCreated);
        System.assertEquals(2, resp.membersUpdated);
    }

    @IsTest
    static void test_getGroupClassPreview_NullOpp() {
        Test.startTest();
        aRC_employerContributionController.PreviewData dto =
            aRC_employerContributionController.getGroupClassPreview(null, 'COMBINED');
        Test.stopTest();

        System.assertNotEquals(null, dto);
        System.assertEquals(false, dto.hasCensus);
        System.assertNotEquals(null, dto.rows);
    }

    @IsTest
    static void test_getGroupClassPreview_OppWithoutAccount() {
        Opportunity opp = new Opportunity(
            Name = 'No Account Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Test.startTest();
        aRC_employerContributionController.PreviewData dto =
            aRC_employerContributionController.getGroupClassPreview(opp.Id, 'COMBINED');
        Test.stopTest();

        System.assertEquals(false, dto.hasCensus);
    }

    @IsTest
    static void test_getGroupClassPreview_OppWithAccountNoCensus() {
        Account acc = new Account(Name = 'Acc No Census');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Opp No Census',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        Test.startTest();
        aRC_employerContributionController.PreviewData dto =
            aRC_employerContributionController.getGroupClassPreview(opp.Id, 'COMBINED');
        Test.stopTest();

        System.assertEquals(false, dto.hasCensus);
    }

    @IsTest
    static void test_createGroupClassesAndAssignMembers_General_AllowsBlank() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(3);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        for (vlocity_ins__GroupCensusMember__c m : members) {
            m.ARC_EmployeeType__c = null;
            m.ARC_EmployeeDivision__c = null;
            m.vlocity_ins__GroupClassId__c = null;
        }
        update members;

        aRC_employerContributionController.CreateRequest req =
            new aRC_employerContributionController.CreateRequest();
        req.opportunityId = opp.Id;
        req.segmentationMode = 'NONE';
        req.includeEmptyChoice = 'EXCLUDE_EMPTY';

        Test.startTest();
        aRC_employerContributionController.CreateResponse resp =
            aRC_employerContributionController.createGroupClassesAndAssignMembers(req);
        Test.stopTest();

        System.assertEquals(true, resp.success);
        System.assertEquals(1, resp.groupClassesCreated);
        System.assertEquals(3, resp.membersUpdated);

        List<vlocity_ins__GroupClass__c> gcs = [
            SELECT Id, Name
            FROM vlocity_ins__GroupClass__c
            WHERE ARC_Opportunity__c = :opp.Id
        ];

        System.assertEquals(1, gcs.size());
        System.assertEquals('General', gcs[0].Name);
    }

    @IsTest
    static void test_createGroupClassesAndAssignMembers_Combined_Success_ExcludeEmpty() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(4);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        setMember(members[0], 'Full Time', 'Exempt');
        setMember(members[1], 'Full Time', 'Exempt');
        setMember(members[2], 'Full Time', 'Non-Exempt');
        setMember(members[3], 'Part Time', 'Non-Exempt');

        for (vlocity_ins__GroupCensusMember__c m : members) {
            m.vlocity_ins__GroupClassId__c = null;
        }
        update members;

        aRC_employerContributionController.CreateRequest req =
            new aRC_employerContributionController.CreateRequest();
        req.opportunityId = opp.Id;
        req.segmentationMode = 'COMBINED';
        req.includeEmptyChoice = 'EXCLUDE_EMPTY';

        Test.startTest();
        aRC_employerContributionController.CreateResponse resp =
            aRC_employerContributionController.createGroupClassesAndAssignMembers(req);
        Test.stopTest();

        System.assertEquals(true, resp.success);
        System.assertEquals(3, resp.groupClassesCreated);
        System.assertEquals(4, resp.membersUpdated);

        List<vlocity_ins__GroupClass__c> gcs = [
            SELECT Id, Name
            FROM vlocity_ins__GroupClass__c
            WHERE ARC_Opportunity__c = :opp.Id
        ];
        System.assertEquals(3, gcs.size());
    }

    @IsTest
    static void test_getGroupClassPreview_FTPT_Counts() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(3);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        members[0].ARC_EmployeeType__c = 'Full Time';
        members[1].ARC_EmployeeType__c = 'Full Time';
        members[2].ARC_EmployeeType__c = 'Part Time';
        update members;

        aRC_employerContributionController.PreviewData dto =
            aRC_employerContributionController.getGroupClassPreview(opp.Id, 'FT_PT');

        System.assertEquals(true, dto.hasCensus);

        Map<String,Integer> byLabel = new Map<String,Integer>();
        for (aRC_employerContributionController.GroupClassRow r : dto.rows) {
            byLabel.put(r.label, r.memberCount);
        }

        System.assertEquals(2, byLabel.get('Full Time'));
        System.assertEquals(1, byLabel.get('Part Time'));
    }

    @IsTest
    static void test_saveGroupClassConfiguration_noDraftContract_throws() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(1);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        Map<String,Object> payload = new Map<String,Object>{
            'opportunityId' => opp.Id
        };

        Boolean threw = false;
        try {
            aRC_employerContributionController.saveGroupClassConfiguration(JSON.serialize(payload));
        } catch (AuraHandledException e) {
            threw = true;
        }

        System.assertEquals(true, threw);
    }

    @IsTest
    static void test_saveGroupClassConfiguration_no_exception() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(1);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        Contract draft = new Contract(
            AccountId = opp.AccountId,
            Status = 'Draft',
            StartDate = Date.today()
        );
        insert draft;

        opp.ContractId = draft.Id;
        update opp;

        vlocity_ins__GroupClass__c gc = new vlocity_ins__GroupClass__c(
            Name = 'GC Test',
            ARC_Opportunity__c = opp.Id,
            vlocity_ins__GroupId__c = opp.AccountId,
            ARC_EmployeeTypeModel__c = 'None',
            ARC_EmployeeType__c = 'None',
            ARC_EmployeeDivision__c = 'None',
            ARC_ContributionMethod__c = 'Flat_Percentage',
            ARC_ApplyProgramBased__c = false,
            ARC_ApplyEmployeeTier__c = false,
            vlocity_ins__IsActive__c = true
        );
        insert gc;

        Map<String,Object> gcMap = new Map<String,Object>{
            'Id' => gc.Id,
            'Name' => 'GC Test',
            'ARC_EmployeeTypeModel__c' => 'None',
            'ARC_EmployeeType__c' => 'None',
            'ARC_EmployeeDivision__c' => 'None',
            'ARC_ContributionMethod__c' => 'Flat_Percentage',
            'ARC_ApplyProgramBased__c' => false,
            'ARC_ApplyEmployeeTier__c' => false,
            'programs' => new List<Object>()
        };

        Map<String,Object> payload = new Map<String,Object>{
            'opportunityId' => opp.Id,
            'groupClasses' => new List<Object>{ gcMap }
        };

        Test.startTest();
        Map<String,Object> result =
            aRC_employerContributionController.saveGroupClassConfiguration(JSON.serialize(payload));
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(true, (Boolean) result.get('success'));
    }

    @IsTest
    static void test_createGroupClassesAndAssignMembers_FT_PT() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(2);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        members[0].ARC_EmployeeType__c = 'Full Time';
        members[0].ARC_EmployeeDivision__c = null;
        members[1].ARC_EmployeeType__c = 'Part Time';
        members[1].ARC_EmployeeDivision__c = null;

        for (vlocity_ins__GroupCensusMember__c m : members) {
            m.vlocity_ins__GroupClassId__c = null;
        }
        update members;

        aRC_employerContributionController.CreateRequest req =
            new aRC_employerContributionController.CreateRequest();
        req.opportunityId = opp.Id;
        req.segmentationMode = 'FT_PT';
        req.includeEmptyChoice = 'EXCLUDE_EMPTY';

        Test.startTest();
        aRC_employerContributionController.CreateResponse resp =
            aRC_employerContributionController.createGroupClassesAndAssignMembers(req);
        Test.stopTest();

        System.assertEquals(true, resp.success);
        System.assertEquals(2, resp.groupClassesCreated);
        System.assertEquals(2, resp.membersUpdated);

        List<vlocity_ins__GroupClass__c> gcs = [
            SELECT Id, Name
            FROM vlocity_ins__GroupClass__c
            WHERE ARC_Opportunity__c = :opp.Id
        ];

        System.assertEquals(2, gcs.size());

        Map<String, String> nameMap = new Map<String, String>();
        for (vlocity_ins__GroupClass__c g : gcs) {
            nameMap.put(g.Name, g.Name);
        }

        System.assert(nameMap.containsKey('Full Time'));
        System.assert(nameMap.containsKey('Part Time'));
    }

    @IsTest
    static void test_createGroupClassesAndAssignMembers_Combined_UnknownMembers_Throws() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(2);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        for (vlocity_ins__GroupCensusMember__c m : members) {
            m.ARC_EmployeeType__c = null;
            m.ARC_EmployeeDivision__c = null;
            m.vlocity_ins__GroupClassId__c = null;
        }
        update members;

        aRC_employerContributionController.CreateRequest req =
            new aRC_employerContributionController.CreateRequest();
        req.opportunityId = opp.Id;
        req.segmentationMode = 'COMBINED';
        req.includeEmptyChoice = 'EXCLUDE_EMPTY';

        Boolean threw = false;

        Test.startTest();
        try {
            aRC_employerContributionController.createGroupClassesAndAssignMembers(req);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @IsTest
    static void test_createGroupClassesAndAssignMembers_Combined_IncludeEmpty_CreatesAllClasses() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(1);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        members[0].ARC_EmployeeType__c = 'Full Time';
        members[0].ARC_EmployeeDivision__c = 'Exempt';
        members[0].vlocity_ins__GroupClassId__c = null;
        update members;

        aRC_employerContributionController.CreateRequest req =
            new aRC_employerContributionController.CreateRequest();
        req.opportunityId = opp.Id;
        req.segmentationMode = 'COMBINED';
        req.includeEmptyChoice = 'INCLUDE_EMPTY';

        Test.startTest();
        aRC_employerContributionController.CreateResponse resp =
            aRC_employerContributionController.createGroupClassesAndAssignMembers(req);
        Test.stopTest();

        System.assertEquals(true, resp.success);
        System.assertEquals(4, resp.groupClassesCreated);
        System.assertEquals(1, resp.membersUpdated);

        Integer gcCount = [
            SELECT COUNT()
            FROM vlocity_ins__GroupClass__c
            WHERE ARC_Opportunity__c = :opp.Id
        ];

        System.assertEquals(4, gcCount);
    }

    @IsTest
    static void test_createGroupClassesAndAssignMembers_ExistingNonGeneral_Throws() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(1);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        vlocity_ins__GroupClass__c gc = new vlocity_ins__GroupClass__c(
            Name = 'Existing Non General',
            ARC_Opportunity__c = opp.Id,
            vlocity_ins__GroupId__c = opp.AccountId
        );
        insert gc;

        aRC_employerContributionController.CreateRequest req =
            new aRC_employerContributionController.CreateRequest();
        req.opportunityId = opp.Id;
        req.segmentationMode = 'NONE';
        req.includeEmptyChoice = 'EXCLUDE_EMPTY';

        Boolean threw = false;

        Test.startTest();
        try {
            aRC_employerContributionController.createGroupClassesAndAssignMembers(req);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @IsTest
    static void test_createGroupClassesAndAssignMembers_ExistingSegmented_Throws() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(1);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        members[0].ARC_EmployeeType__c = 'Full Time';
        members[0].ARC_EmployeeDivision__c = 'Exempt';
        update members;

        vlocity_ins__GroupClass__c gc = new vlocity_ins__GroupClass__c(
            Name = 'General',
            ARC_Opportunity__c = opp.Id,
            vlocity_ins__GroupId__c = opp.AccountId,
            ARC_EmployeeTypeModel__c = 'None',
            ARC_EmployeeType__c = 'None',
            ARC_EmployeeDivision__c = 'None',
            vlocity_ins__IsActive__c = true
        );
        insert gc;

        aRC_employerContributionController.CreateRequest req =
            new aRC_employerContributionController.CreateRequest();
        req.opportunityId = opp.Id;
        req.segmentationMode = 'FT_PT';
        req.includeEmptyChoice = 'EXCLUDE_EMPTY';

        Boolean threw = false;

        Test.startTest();
        try {
            aRC_employerContributionController.createGroupClassesAndAssignMembers(req);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @IsTest
    static void test_createGroupClassesAndAssignMembers_Exempt_Success() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(2);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        members[0].ARC_EmployeeDivision__c = 'Exempt';
        members[1].ARC_EmployeeDivision__c = 'Non-Exempt';

        for (vlocity_ins__GroupCensusMember__c m : members) {
            m.ARC_EmployeeType__c = null;
            m.vlocity_ins__GroupClassId__c = null;
        }
        update members;

        aRC_employerContributionController.CreateRequest req =
            new aRC_employerContributionController.CreateRequest();
        req.opportunityId = opp.Id;
        req.segmentationMode = 'EXEMPT';
        req.includeEmptyChoice = 'EXCLUDE_EMPTY';

        Test.startTest();
        aRC_employerContributionController.CreateResponse resp =
            aRC_employerContributionController.createGroupClassesAndAssignMembers(req);
        Test.stopTest();

        System.assertEquals(true, resp.success);
        System.assertEquals(2, resp.groupClassesCreated);
        System.assertEquals(2, resp.membersUpdated);
    }

    @IsTest
    static void test_getGroupClassPreview_InvalidMode_Throws() {
        Boolean threw = false;

        Test.startTest();
        try {
            aRC_employerContributionController.getGroupClassPreview(null, 'BAD_MODE');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @IsTest
    static void test_resetGroupClasses_Null_Throws() {
        Boolean threw = false;

        Test.startTest();
        try {
            aRC_employerContributionController.resetGroupClasses(null);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @IsTest
    static void test_getGroupClassFromOpportunity_EmptyPaths() {
        Test.startTest();

        Map<String,Object> nullResult =
            aRC_employerContributionController.getGroupClassFromOpportunity(null);

        Opportunity oppWithoutAccount = new Opportunity(
            Name = 'Opp Without Account',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert oppWithoutAccount;

        Map<String,Object> noAccountResult =
            aRC_employerContributionController.getGroupClassFromOpportunity(oppWithoutAccount.Id);

        Account acc = new Account(Name = 'Account No Contract');
        insert acc;

        Opportunity oppNoContract = new Opportunity(
            Name = 'Opp No Contract',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert oppNoContract;

        Map<String,Object> noContractResult =
            aRC_employerContributionController.getGroupClassFromOpportunity(oppNoContract.Id);

        Test.stopTest();

        System.assertEquals(0, ((List<Object>) nullResult.get('groupClasses')).size());
        System.assertEquals(0, ((List<Object>) noAccountResult.get('groupClasses')).size());
        System.assertEquals(0, ((List<Object>) noContractResult.get('groupClasses')).size());
    }

    @IsTest
    static void test_saveGroupClassConfiguration_GroupClassesPayload_UpsertsCliAndContribution() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(1);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        Contract draft = new Contract(
            AccountId = opp.AccountId,
            Status = 'Draft',
            StartDate = Date.today()
        );
        insert draft;

        opp.ContractId = draft.Id;
        update opp;

        Product2 product = new Product2(
            Name = 'Medical Plan',
            IsActive = true,
            Description = 'Medical Plan Description'
        );
        insert product;

        vlocity_ins__GroupClass__c gc = new vlocity_ins__GroupClass__c(
            Name = 'Full Time Medical',
            ARC_Opportunity__c = opp.Id,
            vlocity_ins__GroupId__c = opp.AccountId,
            ARC_EmployeeTypeModel__c = 'FullTime_PartTime',
            ARC_EmployeeType__c = 'Full Time',
            ARC_EmployeeDivision__c = 'Exempt',
            ARC_ContributionMethod__c = 'Flat_Percentage',
            ARC_ApplyProgramBased__c = false,
            ARC_ApplyEmployeeTier__c = false,
            vlocity_ins__IsActive__c = true
        );
        insert gc;

        Map<String,Object> contrib = new Map<String,Object>{
            'id' => null,
            'Name' => 'Medical Contrib',
            'ARC_EmployeeType__c' => 'Full Time',
            'ARC_EmployeeDivision__c' => 'Exempt',
            'ARC_EmployeeTier__c' => 'None',
            'vlocity_ins__ProductCategory__c' => 'Medical',
            'vlocity_ins__ContributionPercent__c' => 50,
            'vlocity_ins__ContributionType__c' => 'Percent'
        };

        Map<String,Object> program = new Map<String,Object>{
            'productName' => 'Medical Plan',
            'contractLineItemId' => null,
            'productId' => product.Id,
            'contributions' => new List<Object>{ contrib }
        };

        Map<String,Object> gcMap = new Map<String,Object>{
            'Id' => gc.Id,
            'Name' => 'Full Time Medical',
            'ARC_EmployeeTypeModel__c' => 'FullTime_PartTime',
            'ARC_EmployeeType__c' => 'Full Time',
            'ARC_EmployeeDivision__c' => 'Exempt',
            'ARC_ContributionMethod__c' => 'Flat_Percentage',
            'ARC_ApplyProgramBased__c' => false,
            'ARC_ApplyEmployeeTier__c' => false,
            'programs' => new List<Object>{ program }
        };

        Map<String,Object> payload = new Map<String,Object>{
            'opportunityId' => opp.Id,
            'groupClasses' => new List<Object>{ gcMap }
        };

        Test.startTest();
        Map<String,Object> result =
            aRC_employerContributionController.saveGroupClassConfiguration(JSON.serialize(payload));
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(true, (Boolean) result.get('success'));

        List<vlocity_ins__GroupClassContribution__c> savedContribs = [
            SELECT Id,
                   Name,
                   vlocity_ins__ContributionPercent__c,
                   vlocity_ins__ProductCategory__c
            FROM vlocity_ins__GroupClassContribution__c
            WHERE vlocity_ins__GroupClassId__c = :gc.Id
        ];

        System.assertEquals(1, savedContribs.size());
        System.assertEquals('Medical Contrib', savedContribs[0].Name);
        System.assertEquals(Decimal.valueOf(50), savedContribs[0].vlocity_ins__ContributionPercent__c);
        System.assertEquals('Medical', savedContribs[0].vlocity_ins__ProductCategory__c);
    }

    @IsTest
    static void test_saveGroupClassConfiguration_SinglePayload_ProgramBasedComplete() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(1);
        Opportunity opp = makeOppFromCensus(members[0].vlocity_ins__CensusId__c);

        Contract draft = new Contract(
            AccountId = opp.AccountId,
            Status = 'Draft',
            StartDate = Date.today()
        );
        insert draft;

        opp.ContractId = draft.Id;
        update opp;

        Product2 product = new Product2(
            Name = 'Program Product',
            IsActive = true,
            Description = 'Program Product Description'
        );
        insert product;

        vlocity_ins__ContractLineItem__c oldCli = new vlocity_ins__ContractLineItem__c(
            Name = 'Old CLI To Delete',
            vlocity_ins__ContractId__c = draft.Id
        );
        insert oldCli;

        vlocity_ins__GroupClass__c gc = new vlocity_ins__GroupClass__c(
            Name = 'Full Time Program Based',
            ARC_Opportunity__c = opp.Id,
            vlocity_ins__GroupId__c = opp.AccountId,
            ARC_EmployeeTypeModel__c = 'FullTime_PartTime',
            ARC_EmployeeType__c = 'Full Time',
            ARC_EmployeeDivision__c = 'Exempt',
            ARC_ContributionMethod__c = 'Flat_Percentage',
            ARC_ApplyProgramBased__c = true,
            ARC_ApplyEmployeeTier__c = false,
            vlocity_ins__IsActive__c = true
        );
        insert gc;

        Map<String,Object> contrib = new Map<String,Object>{
            'id' => null,
            'ARC_EmployeeType__c' => 'Full Time',
            'ARC_EmployeeDivision__c' => 'Exempt',
            'ARC_EmployeeTier__c' => 'None',
            'vlocity_ins__ProductCategory__c' => 'Medical',
            'vlocity_ins__ContributionPercent__c' => 25,
            'vlocity_ins__ContributionType__c' => 'Percent'
        };

        Map<String,Object> program = new Map<String,Object>{
            'productName' => 'Program Product',
            'contractLineItemId' => null,
            'productId' => product.Id,
            'contributions' => new List<Object>{ contrib }
        };

        Map<String,Object> payload = new Map<String,Object>{
            'opportunityId' => opp.Id,
            'groupClassId' => gc.Id,
            'groupClassName' => 'Full Time Program Based',
            'employeeTypeModel' => 'FullTime_PartTime',
            'ARC_EmployeeType__c' => 'Full Time',
            'ARC_EmployeeDivision__c' => 'Exempt',
            'applyProgramBased' => true,
            'applyEmployeeTier' => false,
            'contributionMethod' => 'Flat_Percentage',
            'programs' => new List<Object>{ program }
        };

        Test.startTest();
        Map<String,Object> result =
            aRC_employerContributionController.saveGroupClassConfiguration(JSON.serialize(payload));
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(true, (Boolean) result.get('success'));
        System.assertEquals(true, (Boolean) result.get('ARC_GroupClassesContributionsDefined__c'));

        Integer oldCliCount = [
            SELECT COUNT()
            FROM vlocity_ins__ContractLineItem__c
            WHERE Id = :oldCli.Id
        ];
        System.assertEquals(0, oldCliCount);

        List<vlocity_ins__GroupClassContribution__c> savedContribs = [
            SELECT Id,
                   Name,
                   vlocity_ins__ContributionPercent__c,
                   vlocity_ins__ProductCategory__c
            FROM vlocity_ins__GroupClassContribution__c
            WHERE vlocity_ins__GroupClassId__c = :gc.Id
        ];

        System.assertEquals(1, savedContribs.size());
        System.assertEquals('Program Product - Full Time - Exempt', savedContribs[0].Name);
        System.assertEquals(Decimal.valueOf(25), savedContribs[0].vlocity_ins__ContributionPercent__c);
        System.assertEquals('Medical', savedContribs[0].vlocity_ins__ProductCategory__c);
    }
}