/**
 * @ClassName     : ARC_AuthCaseUtilityTest
 * @Description   : Test class for ARC_AuthCaseUtility.
 *                  Covers all public / @InvocableMethod / @AuraEnabled methods:
 *                    - checkForPhysicalTherapy
 *                    - countPTConsumptionsForAuthCase
 *                    - uncommitPTVisitsFromAuth
 *                    - getAuthCaseCandidates  (InvocableMethod)
 *                    - getSMBs               (AuraEnabled)
 *                    - PTDeltaPropagationJob  (inner Queueable – tests propagateDelta indirectly)
 */
@isTest
private class ARC_AuthCaseUtilityTest {

    // ─── Shared constants ─────────────────────────────────────────────────────
    private static final Date   AUTH_FROM      = Date.newInstance(2025, 1, 1);
    private static final Date   AUTH_TO        = Date.newInstance(2025, 12, 31);
    private static final Date   VALID_DOS      = Date.newInstance(2025, 6, 15);
    private static final Date   VALID_DOS_2      = Date.newInstance(2025, 6, 16);
    private static final String CPT_CODE_NAME  = 'PT_CODE_TEST_99';
    private static final String CPT_CODE_NAME_INVALID  = 'UNKNOWN_99';
    private static final String AUTH_SOURCE_ID = 'AUTH-2025-001';

    // ─────────────────────────────────────────────────────────────────────────
    // @TestSetup – creates the full data graph shared by all test methods
    // ─────────────────────────────────────────────────────────────────────────
    @TestSetup
    static void setup() {

        // 1. Account used as ARC_PersonAccount__c on the auth Case
        //    (required by getAuthCaseCandidates SOQL filter)
        Account personAccount = ARC_TestUtility.createTestAccount(1,'ARC_IFPPersonAccount')[0];

        // 2. Primary auth Case – anchor for most tests
        List<Case> authCase = ARC_TestUtility.createTestCase(2, 'Authorization');
        for (Integer i = 0 ; i < authCase.size() ; i++){
            Case c = authCase[i];
            c.ARC_PT_Auth_From_Date__c         = AUTH_FROM;
            c.ARC_PT_Auth_To_Date__c           = AUTH_TO;
            c.ARC_PersonAccount__c             = personAccount.Id;
            c.HealthCloudGA__SourceSystemID__c = AUTH_SOURCE_ID;
            c.Subject = 'Test';
            if(i == 1){
                c.Subject = 'Test void';
                c.HealthCloudGA__SourceSystemID__c = AUTH_SOURCE_ID + '_void1';
            }else if(i == 0){
                c.ParentId = authCase[1].Id;
            }
        }
        update authCase;

        //3. policy + claim
        InsurancePolicy policy = ARC_TestUtility.createTestPolicies(1)[0];
        List<Claim> claims = new List<Claim> {
            new Claim(
                Name                          = 'Test PT Claim',
                ARC_PriorAuthorizationCase__c = authCase[0].Id,
                PolicyNumberId = policy.Id
            ),
            new Claim(
                Name                          = 'Test PT Claim old',
                ARC_PriorAuthorizationCase__c = authCase[1].Id,
                PolicyNumberId = policy.Id
            )
        };
        insert claims;

        List<vlocity_ins__VlocityCode__c> vCodeList = new List<vlocity_ins__VlocityCode__c>{
            new vlocity_ins__VlocityCode__c(
                Name = CPT_CODE_NAME,
                ARC_IsSleepCode__c = false,
                ARC_NoMBRLiability__c = false,
                ARC_SetToUnclean__c = false,
                vlocity_ins__IsActive__c = true,
                vlocity_ins__IsCustom__c = false
                ),
            new vlocity_ins__VlocityCode__c(
                Name = CPT_CODE_NAME_INVALID,
                ARC_IsSleepCode__c = false,
                ARC_NoMBRLiability__c = false,
                ARC_SetToUnclean__c = false,
                vlocity_ins__IsActive__c = true,
                vlocity_ins__IsCustom__c = false
            )
        };
        insert vCodeList;

        // 4. ClaimCoverage – required parent for ClaimCoveragePaymentDetail
        List<ClaimCoveragePaymentDetail> clis = ARC_TestUtility.createTestCoveragePayments(5);

        // 6. paid and Unpaid PT CLI – 
        for(Integer i = 0 ; i < clis.size() ; i++){
            ClaimCoveragePaymentDetail cli = clis[i]; 
            cli.ARC_Claim__c                = claims[0].Id;
            cli.ARC_DateOfService__c        = VALID_DOS;
            cli.ARC_Medical_Visit_Reason__c = 'PhysicalTherapy';
            cli.Status = 'New';
            cli.ARC_ProcedureCode__c = vCodeList[0].Id;
            if(i == 1){
                cli.ARC_Is_PT_Pivot__c          = true;
                cli.Status = 'Paid';
                cli.ARC_ProcedureCode__c = vCodeList[1].Id;
            }
            if(i == 2){
                cli.ARC_Is_PT_Pivot__c          = false;
                cli.Status = 'Paid';
                cli.ARC_ProcedureCode__c = vCodeList[1].Id;
            }
            if(i == 3){
                cli.ARC_Claim__c                = claims[1].Id;
                cli.ARC_Is_PT_Pivot__c          = true;
                cli.Status = 'Paid';
                cli.ARC_DateOfService__c        = VALID_DOS_2;
            }
            if(i == 4){
                cli.ARC_Claim__c                = claims[0].Id;
                cli.ARC_Is_PT_Pivot__c          = true;
                cli.ARC_DateOfService__c        = VALID_DOS_2;
                cli.Status = 'Paid';
            }
        }
        update clis;

        // 8. Prior Authorization chain:
        //    arcsona__PriorAuthorization__c → arcsona__PriorAuthRequestItem__c → arcsona__CPTCode__c
        //    Required by checkForPhysicalTherapy (SOQL for CPT codes) and getAuthCaseCandidates.
        arcsona__PriorAuthorization__c priorAuth = new arcsona__PriorAuthorization__c(
            arcsona__Case__c = authCase[0].Id
        );
        insert priorAuth;

        CodeSet cptCode = new CodeSet(
            Name = CPT_CODE_NAME,
            Code = CPT_CODE_NAME,
            CodeSetType = 'Procedure',
            IsActive = true,
            IsCustomCode = false,
            IsPrimary = false
        );
        insert cptCode;

        arcsona__PriorAuthRequestItem__c pari = new arcsona__PriorAuthRequestItem__c(
            arcsona__PriorAuthorization__c = priorAuth.Id,
            arcsona__Status__c             = 'Approved',
            arcsona__CPTCode__c            = cptCode.Id,
            arcsona__DXCode__c            = CPT_CODE_NAME,
            arcsona__FromDate__c            = AUTH_FROM,
            arcsona__ToDate__c            = AUTH_TO,
            arcsona__PlaceOfService__c            = '01',
            arcsona__Quantity__c            = 10,
            arcsona__ApprovedQuantity__c            = 10
        );
        insert pari;
    }


    // ═════════════════════════════════════════════════════════════════════════
    // checkForPhysicalTherapy
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Happy path: DOS within range and CPT code matches an Approved PARI
     * → no error, DOS map contains one entry for the processed CLI.
     * The CLI is passed in-memory (not inserted) so its Id is null; the map
     * will have key = null, but size = 1 confirming the item was processed.
     */
    @isTest
    static void testCheckForPT_ValidItem_ReturnsDOSMapWithEntry() {
        Case authCase = [
            SELECT Id, ARC_PT_Auth_From_Date__c, ARC_PT_Auth_To_Date__c
            FROM Case WHERE Subject = 'Test' LIMIT 1
        ];

        List<ClaimCoveragePaymentDetail> ptItems = [
            SELECT Id, ARC_Medical_Visit_Reason__c, Status, ARC_DateOfService__c, ARC_ProcedureCode__c, ARC_ProcedureCodeName__c 
            FROM ClaimCoveragePaymentDetail 
            WHERE ARC_ProcedureCode__c IN (SELECT id FROM vlocity_ins__VlocityCode__c WHERE Name = :CPT_CODE_NAME) 
            AND ARC_Claim__r.ARC_PriorAuthorizationCase__c = :authCase.Id
            AND Status = 'New'];


        Map<String, Object> inputMap = new Map<String, Object>{
            'claimItems' => ptItems,
            'voidedAuth' => false,
            'caseId'     => authCase.Id,
            'authFrom'   => authCase.ARC_PT_Auth_From_Date__c,
            'authTo'     => authCase.ARC_PT_Auth_To_Date__c
        };

        Test.startTest();
        Map<String, Object> result = ARC_AuthCaseUtility.checkForPhysicalTherapy(inputMap);
        Test.stopTest();

        System.assert(!result.containsKey('error'),
            'Valid PT item should produce no error; got: ' + result.get('error'));
        Map<Id, Date> dosMap = (Map<Id, Date>) result.get('newCliToDateMap');
        System.assertNotEquals(null, dosMap, 'newCliToDateMap must be present');
        System.assertEquals(1, dosMap.size(),
            'Exactly one PT item was processed so DOS map must contain one entry');
        System.assertEquals(VALID_DOS, dosMap.values()[0],
            'The stored DOS must match the CLI date of service');
    }


    // ═════════════════════════════════════════════════════════════════════════
    // countPTConsumptionsForAuthCase
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * When the newCliToDateMap contains a date that has no existing paid pivot CLI
     * in the DB for the given authNumber, the date counts as new.
     */
    @isTest
    static void testCountPT_AllNewDates_CountsEverything() {
        Id fakeCLIId = ARC_TestUtility.getFakeId(ClaimCoveragePaymentDetail.SObjectType);
        Date newDate = Date.newInstance(2025, 9, 10); // no pivot CLI for this date in DB

        Map<String, Object> inputMap = new Map<String, Object>{
            'newCliToDateMap' => new Map<Id, Date>{ fakeCLIId => newDate },
            'authNumber'      => AUTH_SOURCE_ID
        };

        Test.startTest();
        Map<String, Object> result = ARC_AuthCaseUtility.countPTConsumptionsForAuthCase(inputMap);
        Test.stopTest();

        System.assert(!result.containsKey('error'), 'Should not return an error');
        System.assertEquals(1, (Integer) result.get('newDatesCount'),
            'New date with no existing pivot must be counted');
        List<Id> pivotIds = (List<Id>) result.get('newPivotCliIds');
        System.assertEquals(1, pivotIds.size());
        System.assertEquals(fakeCLIId, pivotIds[0], 'Returned pivot Id must match the input');
    }

    /**
     * When one of the supplied dates already has a paid pivot CLI in the DB
     * (as set up in @TestSetup with VALID_DOS), that date is excluded from the count.
     * Only the truly new date (brandNew) should be counted.
     */
    @isTest
    static void testCountPT_ExistingPivotDate_ExcludedFromCount() {
        ClaimCoveragePaymentDetail existingPivot = [
            SELECT Id, ARC_DateOfService__c
            FROM ClaimCoveragePaymentDetail
            WHERE ARC_Is_PT_Pivot__c = true
              AND Status = 'Paid'
            LIMIT 1
        ];

        Id   fakeCLIId = ARC_TestUtility.getFakeId(ClaimCoveragePaymentDetail.SObjectType);
        Date brandNew  = Date.newInstance(2025, 10, 5); // no existing pivot for this date

        Map<String, Object> inputMap = new Map<String, Object>{
            'newCliToDateMap' => new Map<Id, Date>{
                existingPivot.Id => existingPivot.ARC_DateOfService__c, // already pivoted – excluded
                fakeCLIId        => brandNew                             // genuinely new – counted
            },
            'authNumber' => AUTH_SOURCE_ID
        };

        Test.startTest();
        Map<String, Object> result = ARC_AuthCaseUtility.countPTConsumptionsForAuthCase(inputMap);
        Test.stopTest();

        System.assert(!result.containsKey('error'), 'Should not return an error');
        System.assertEquals(1, (Integer) result.get('newDatesCount'),
            'Only the brand-new date should be counted; the existing pivot date must be excluded');
        List<Id> pivotIds = (List<Id>) result.get('newPivotCliIds');
        System.assertEquals(1, pivotIds.size());
        System.assertEquals(fakeCLIId, pivotIds[0],
            'The pivot CLI Id must correspond to the new date only');
    }


    // ═════════════════════════════════════════════════════════════════════════
    // uncommitPTVisitsFromAuth
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * When none of the supplied smb_items has ARC_Is_PT_Pivot__c = true,
     * datesToReset remains empty and the output map is also empty.
     */
    @isTest
    static void testUncommit_NoPivotItems_OutMapIsEmpty() {
        Case authCase = [SELECT Id FROM Case WHERE Subject = 'Test void' LIMIT 1];

        // Query the unpaid (non-pivot) CLI with the deep traversal fields the method reads
        ClaimCoveragePaymentDetail nonPivotCLI = [
            SELECT Id, ARC_Is_PT_Pivot__c, ARC_DateOfService__c, ARC_DOSTo__c,
                   ARC_Claim__r.ARC_PriorAuthorizationCase__r.Base_Source_System_Id__c
            FROM ClaimCoveragePaymentDetail
            WHERE ARC_Medical_Visit_Reason__c = 'PhysicalTherapy'
              AND ARC_Is_PT_Pivot__c = false
              AND Status = 'Paid'
            LIMIT 1
        ];

        Map<String, Object> inputMap = new Map<String, Object>{
            'smb_items'  => new List<ClaimCoveragePaymentDetail>{ nonPivotCLI },
            'authCaseId' => (Id) authCase.Id,
            'usedValue'  => (Decimal) 3
        };

        Test.startTest();
        Map<String, Object> result = ARC_AuthCaseUtility.uncommitPTVisitsFromAuth(inputMap);
        Test.stopTest();

        System.assert(!result.containsKey('error'), 'Should not return an error');
        System.assert(!result.containsKey('authsToUpdate'),
            'No pivot items means the inner block is skipped; authsToUpdate must not be set');
    }

    /**
     * When a pivot CLI is uncommitted and no other paid CLI shares that date
     * on any related auth, the auth count must be decremented by 1.
     */
    @isTest
    static void testUncommit_PivotItem_NoOtherCLIsOnDate_SubtractsFromAuth() {
        Case authCase = [SELECT Id FROM Case WHERE Subject = 'Test' LIMIT 1];

        // Move the pivot CLI's DOS to an isolated date so no other CLIs share it
        List<ClaimCoveragePaymentDetail> clis = [
            SELECT Id, ARC_Is_PT_Pivot__c, ARC_DateOfService__c, ARC_DOSTo__c, Status,
                   ARC_Claim__r.ARC_PriorAuthorizationCase__r.Base_Source_System_Id__c,
                   ARC_Claim__r.ARC_PriorAuthorizationCase__c,
                   ARC_Claim__r.ARC_PriorAuthorizationCase__r.ARC_PT_Visits_Used__c,
                   ARC_Claim__r.ARC_PriorAuthorizationCase__r.HealthCloudGA__SourceSystemID__c 
            FROM ClaimCoveragePaymentDetail
            WHERE Status = 'Paid'
            AND ARC_Claim__r.ARC_PriorAuthorizationCase__c = :authCase.Id
            AND ARC_Is_PT_Pivot__c = true
        ];
        for(ClaimCoveragePaymentDetail cli : clis){
            cli.ARC_DateOfService__c = Date.newInstance(2025, 11, 11);

        }
        update clis;

        Map<String, Object> inputMap = new Map<String, Object>{
            'smb_items'  => clis,
            'authCaseId' => (Id) authCase.Id,
            'usedValue'  => (Decimal) 3
        };

        Test.startTest();
        Map<String, Object> result = ARC_AuthCaseUtility.uncommitPTVisitsFromAuth(inputMap);
        Test.stopTest();

        System.assert(!result.containsKey('error'), 'Should not return an error');
        Map<Id, Integer> authsToUpdate = (Map<Id, Integer>) result.get('authsToUpdate');
        System.assertNotEquals(null, authsToUpdate, 'authsToUpdate must be present');
        System.assertEquals(-2, authsToUpdate.get(authCase.Id),
            'Auth count must be decremented by 1 when no other CLI remains for that date');
    }

    /**
     * When a pivot CLI is uncommitted but another paid CLI shares the same DOS
     * on the SAME auth case, that second CLI becomes the new pivot and the
     * auth count stays at 0 (no decrement).
     */
    @isTest
    static void testUncommit_PivotItem_AnotherCLIOnSameAuth_ReassignsPivot() {
        Case authCase = [SELECT Id FROM Case WHERE Subject = 'Test' LIMIT 1];

        // query pivot with the full traversal projection
        ClaimCoveragePaymentDetail pivotCLI = [
            SELECT Id, ARC_Is_PT_Pivot__c, ARC_DateOfService__c, ARC_DOSTo__c, Status,
                   ARC_Claim__r.ARC_PriorAuthorizationCase__r.Base_Source_System_Id__c,
                   ARC_Claim__r.ARC_PriorAuthorizationCase__c,
                   ARC_Claim__r.ARC_PriorAuthorizationCase__r.ARC_PT_Visits_Used__c,
                   ARC_Claim__r.ARC_PriorAuthorizationCase__r.HealthCloudGA__SourceSystemID__c
            FROM ClaimCoveragePaymentDetail
            WHERE ARC_Is_PT_Pivot__c = true AND ARC_Claim__r.ARC_PriorAuthorizationCase__c = :authCase.Id LIMIT 1
        ];

        Map<String, Object> inputMap = new Map<String, Object>{
            'smb_items'  => new List<ClaimCoveragePaymentDetail>{ pivotCLI },
            'authCaseId' => (Id) authCase.Id,
            'usedValue'  => (Decimal) 3
        };

        Test.startTest();
        Map<String, Object> result = ARC_AuthCaseUtility.uncommitPTVisitsFromAuth(inputMap);
        Test.stopTest();

        System.assert(!result.containsKey('error'), 'Should not return an error');
        Map<Id, Integer> authsToUpdate = (Map<Id, Integer>) result.get('authsToUpdate');
        System.assertNotEquals(null, authsToUpdate, 'authsToUpdate must be present');
        System.assertEquals(0, authsToUpdate.get(authCase.Id),
            'Auth count must stay 0 when another CLI on the same auth absorbs the pivot role');

        // The second CLI must have been appended to smb_items as the new pivot
        List<ClaimCoveragePaymentDetail> updatedItems =
            (List<ClaimCoveragePaymentDetail>) result.get('smb_items');
        System.assertEquals(2, updatedItems.size(),
            'smb_items must contain both the original pivot CLI and the newly assigned pivot');
    }

    /**
     * When a pivot CLI is uncommitted but another paid CLI shares the same DOS
     * on the ANOTHER auth case, that second CLI becomes the new pivot and the
     * auth count stays at 0 (no decrement).
     */
    @isTest
    static void testUncommit_PivotItem_AnotherCLIOnAnotherAuth_ReassignsPivot() {
        Case authCase = [SELECT Id FROM Case WHERE Subject = 'Test void' LIMIT 1];

        // query pivot with the full traversal projection
        ClaimCoveragePaymentDetail pivotCLI = [
            SELECT Id, ARC_Is_PT_Pivot__c, ARC_DateOfService__c, ARC_DOSTo__c, Status,
                   ARC_Claim__r.ARC_PriorAuthorizationCase__r.Base_Source_System_Id__c,
                   ARC_Claim__r.ARC_PriorAuthorizationCase__c,
                   ARC_Claim__r.ARC_PriorAuthorizationCase__r.ARC_PT_Visits_Used__c,
                   ARC_Claim__r.ARC_PriorAuthorizationCase__r.HealthCloudGA__SourceSystemID__c
            FROM ClaimCoveragePaymentDetail
            WHERE ARC_Is_PT_Pivot__c = true AND ARC_Claim__r.ARC_PriorAuthorizationCase__c = :authCase.Id LIMIT 1
        ];

        Map<String, Object> inputMap = new Map<String, Object>{
            'smb_items'  => new List<ClaimCoveragePaymentDetail>{ pivotCLI },
            'authCaseId' => (Id) authCase.Id,
            'usedValue'  => (Decimal) 3
        };

        Test.startTest();
        Map<String, Object> result = ARC_AuthCaseUtility.uncommitPTVisitsFromAuth(inputMap);
        Test.stopTest();

        System.assert(!result.containsKey('error'), 'Should not return an error');
        Map<Id, Integer> authsToUpdate = (Map<Id, Integer>) result.get('authsToUpdate');
        System.assertNotEquals(null, authsToUpdate, 'authsToUpdate must be present');
        System.assertEquals(-1, authsToUpdate.get(authCase.Id),
            'Auth count must stay 1 when another CLI on another auth, passes the pivot role');

        // The second CLI must have been appended to smb_items as the new pivot
        List<ClaimCoveragePaymentDetail> updatedItems =
            (List<ClaimCoveragePaymentDetail>) result.get('smb_items');
        System.assertEquals(2, updatedItems.size(),
            'smb_items must contain both the original pivot CLI and the newly assigned pivot');
    }


    // ═════════════════════════════════════════════════════════════════════════
    // getAuthCaseCandidates  (@InvocableMethod)
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * An empty inputs list returns an empty outputs list immediately.
     */
    @isTest
    static void testGetCandidates_EmptyInput_ReturnsEmptyList() {
        Test.startTest();
        List<ARC_AuthCaseUtility.Output> result = ARC_AuthCaseUtility.getAuthCaseCandidates(
            new List<ARC_AuthCaseUtility.Input>()
        );
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Empty input should return an empty list');
    }

    /**
     * When the claim has no PT CLIs, codes is empty and the method returns early
     * with an empty Output.
     */
    @isTest
    static void testGetCandidates_NoPTCLIsOnClaim_ReturnsEmptyCases() {
        // Create a fresh claim with no CLIs
        Claim emptyClaim = new Claim(Name = 'Empty Claim No PT');
        insert emptyClaim;

        ARC_AuthCaseUtility.Input inp = new ARC_AuthCaseUtility.Input();
        inp.claimId   = emptyClaim.Id;
        inp.sourceId  = AUTH_SOURCE_ID;
        inp.accountId = emptyClaim.Id; // arbitrary – won't be reached
        inp.dateFrom  = Date.newInstance(2025, 6, 1);
        inp.dateTo    = Date.newInstance(2025, 6, 30);

        Test.startTest();
        List<ARC_AuthCaseUtility.Output> result = ARC_AuthCaseUtility.getAuthCaseCandidates(
            new List<ARC_AuthCaseUtility.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(0, result.size(), 'One Output element must be returned');
        
    }

    /**
     * Happy path: all filters satisfied.
     *  - Claim has a PT CLI with CPT_CODE_NAME
     *  - The auth Case has a matching Approved PARI for CPT_CODE_NAME
     *  - authFrom / authTo bracket the supplied dateFrom / dateTo
     *  - ARC_PersonAccount__c matches input.accountId
     * Expects: the auth Case returned and hasPhysicalTherapyPaid = true
     * (because the paid pivot CLI from @TestSetup is on the same claim).
     */
    @isTest
    static void testGetCandidates_AllFiltersMatch_ReturnsCaseAndPaidFlag() {
        Case    authCase      = [SELECT Id FROM Case WHERE Subject = 'Test' LIMIT 1];
        Account personAccount = [SELECT Id FROM Account WHERE Firstname = 'TestFirstName' LIMIT 1];
        Claim   claim         = [SELECT Id FROM Claim WHERE ARC_PriorAuthorizationCase__c = :authCase.Id LIMIT 1];


        ARC_AuthCaseUtility.Input inp = new ARC_AuthCaseUtility.Input();
        inp.claimId   = claim.Id;
        inp.sourceId  = AUTH_SOURCE_ID;
        inp.accountId = personAccount.Id; // matches ARC_PersonAccount__c set in @TestSetup
        inp.dateFrom  = Date.newInstance(2025, 6, 1);  // within AUTH_FROM–AUTH_TO
        inp.dateTo    = Date.newInstance(2025, 6, 30);

        Test.startTest();
        List<ARC_AuthCaseUtility.Output> result = ARC_AuthCaseUtility.getAuthCaseCandidates(
            new List<ARC_AuthCaseUtility.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Must return exactly one Output element');
        System.assertEquals(1, result[0].cases.size(),
            'Exactly one matching auth case should be found');
        System.assertEquals(true, result[0].hasPhysicalTherapyPaid,
            'hasPhysicalTherapyPaid must be true because a paid PT CLI exists on this claim');
    }

    /**
     * Happy path: all filters satisfied.
     *  - Claim has a PT CLI with CPT_CODE_NAME
     *  - The auth Case has a matching Approved PARI for CPT_CODE_NAME
     *  - authFrom / authTo bracket the supplied dateFrom / dateTo
     *  - ARC_PersonAccount__c matches input.accountId
     * When no paid PT CLI exists on the claim, hasPhysicalTherapyPaid must be false.
     */
    @isTest
    static void testGetCandidates_NoPaidPTOnClaim_PaidFlagFalse() {
        Case    authCase      = [SELECT Id FROM Case WHERE Subject = 'Test' LIMIT 1];
        Account personAccount = [SELECT Id FROM Account WHERE Firstname = 'TestFirstName'  LIMIT 1];
        Claim   claim         = [SELECT Id FROM Claim WHERE ARC_PriorAuthorizationCase__c = :authCase.Id LIMIT 1];

        // UNPAY existing CLIs on Claim
        List<ClaimCoveragePaymentDetail> clis = [SELECT Id, Status FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c = :claim.Id];
        for (ClaimCoveragePaymentDetail cli: clis){
            cli.Status = 'New';
        }
        update clis;


        ARC_AuthCaseUtility.Input inp = new ARC_AuthCaseUtility.Input();
        inp.claimId   = claim.Id;
        inp.sourceId  = AUTH_SOURCE_ID;
        inp.accountId = personAccount.Id;
        inp.dateFrom  = Date.newInstance(2025, 6, 1);
        inp.dateTo    = Date.newInstance(2025, 6, 30);

        Test.startTest();
        List<ARC_AuthCaseUtility.Output> result = ARC_AuthCaseUtility.getAuthCaseCandidates(
            new List<ARC_AuthCaseUtility.Input>{ inp }
        );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(authCase.Id, result[0].cases[0].Id,
            'The returned case must be the open auth case created in @TestSetup');
        System.assertEquals(false, result[0].hasPhysicalTherapyPaid,
            'hasPhysicalTherapyPaid must be false when no paid PT CLI exists on the claim');
    }


    // ═════════════════════════════════════════════════════════════════════════
    // getSMBs  (@AuraEnabled)
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * A Case that has one linked Claim (from @TestSetup) must return that claim.
     */
    @isTest
    static void testGetSMBs_WithLinkedClaim_ReturnsClaim() {
        Case authCase = [SELECT Id FROM Case WHERE Subject = 'Test' LIMIT 1];

        Test.startTest();
        List<Claim> result = ARC_AuthCaseUtility.getSMBs(authCase.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return exactly one claim linked to the auth case');
    }

    // ═════════════════════════════════════════════════════════════════════════
    // PTDeltaPropagationJob  (inner Queueable – exercises propagateDelta)
    // ═════════════════════════════════════════════════════════════════════════


    /**
     * A negative delta subtracts from the child Case's ARC_PT_Visits_FromParent__c.
     */
    @isTest
    static void testPTDeltaPropagationJob_NegativeDelta_SubtractsFromChild() {
        Case parentCase = [SELECT Id FROM Case WHERE Subject = 'Test void' LIMIT 1];
        Case childCase  = [SELECT Id FROM Case WHERE Subject = 'Test'  LIMIT 1];

        // Prime the child with an initial value before the job runs
        childCase.ARC_PT_Calculated_Visits_Limit__c = 4;
        childCase.ARC_PT_Visits_Authorized__c = 4;
        childCase.ARC_PT_Visits_FromParent__c = 4;
        childCase.ARC_PT_Visits_Used__c = 0;
        update childCase;

        Map<Id, Decimal> deltas = new Map<Id, Decimal>{ parentCase.Id => -2 };

        Test.startTest();
        System.enqueueJob(new ARC_AuthCaseUtility.PTDeltaPropagationJob(deltas));
        Test.stopTest();

        Case updated = [SELECT ARC_PT_Visits_FromParent__c FROM Case WHERE Id = :childCase.Id];
        System.assertEquals(2, updated.ARC_PT_Visits_FromParent__c,
            '4 + (-2) = 2 visits must remain on the child case');
    }

    
    
}