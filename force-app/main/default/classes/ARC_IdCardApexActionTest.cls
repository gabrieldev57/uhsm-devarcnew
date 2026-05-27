@IsTest
private class ARC_IdCardApexActionTest {

    private static void putIfWritable(SObject record, String fieldApiName, Object value) {
        Schema.SObjectField fieldToken = record.getSObjectType().getDescribe().fields.getMap().get(fieldApiName);
        if (fieldToken != null && fieldToken.getDescribe().isCreateable()) {
            record.put(fieldApiName, value);
        }
    }

    private static void putIfFieldExists(SObject record, String fieldApiName, Object value) {
        Schema.SObjectField fieldToken = record.getSObjectType().getDescribe().fields.getMap().get(fieldApiName);
        if (fieldToken != null) {
            record.put(fieldApiName, value);
        }
    }

    private static Account getSeededAccount() {
        return [
            SELECT Id
            FROM Account
            WHERE Current_Member_Id__c = 'IDCARD-MID-001'
            LIMIT 1
        ];
    }

    @TestSetup
    static void setupData() {
        Account memberAccount = new Account();
        //putIfWritable(memberAccount, 'Name', 'ID Card Test Account');
        putIfWritable(memberAccount, 'FirstName', 'ID');
        putIfWritable(memberAccount, 'LastName', 'Card Member');
        putIfWritable(memberAccount, 'PersonEmail', 'idcard.member@test.com');
        putIfWritable(memberAccount, 'Current_Member_Id__c', 'IDCARD-MID-001');
        putIfWritable(memberAccount, 'ARC_Member_Id__c', 'IDCARD-MID-001');
        insert memberAccount;

        Account insertedMemberAccount = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE Id = :memberAccount.Id
            LIMIT 1
        ];
        Id memberContactId = insertedMemberAccount.PersonContactId;

        Product2 productRecord = new Product2(
            Name = 'WeShare Test Plan',
            IsActive = true
        );
        putIfWritable(productRecord, 'ProductCode', 'WESHARE_TEST');
        putIfFieldExists(productRecord, 'vlocity_ins__parentclassid__c', null);
        insert productRecord;

        InsurancePolicy policyRecord = new InsurancePolicy(
            Name = 'ID Card Test Policy',
            Status = 'Activated',
            NameInsuredId = memberAccount.Id
        );
        putIfWritable(policyRecord, 'EffectiveDate', Date.today().addDays(-10));
        putIfWritable(policyRecord, 'ExpirationDate', Date.today().addYears(1));
        insert policyRecord;

        InsurancePolicyCoverage coverageRecord = new InsurancePolicyCoverage();
        putIfWritable(coverageRecord, 'Name', 'ID Card Test Coverage');
        putIfWritable(coverageRecord, 'InsurancePolicyId', policyRecord.Id);
        putIfWritable(coverageRecord, 'Product2Id', productRecord.Id);
        putIfWritable(coverageRecord, 'vlocity_ins_fsc__Product2Id__c', productRecord.Id);
        putIfWritable(coverageRecord, 'Status', 'Activated');
        putIfWritable(coverageRecord, 'EffectiveDate', Date.today().addDays(-10));
        putIfWritable(coverageRecord, 'ExpirationDate', Date.today().addYears(1));
        putIfWritable(coverageRecord, 'ARC_PrimaryMemberId__c', 'IDCARD-MID-001');
        putIfWritable(coverageRecord, 'ARC_CoveragePrimaryMember__c', memberAccount.Id);
        insert coverageRecord;

        InsurancePolicyParticipant participantRecord = new InsurancePolicyParticipant();
        putIfWritable(participantRecord, 'Name', 'ID Card Test Participant');
        putIfWritable(participantRecord, 'InsurancePolicyId', policyRecord.Id);
        putIfWritable(participantRecord, 'ParticipantAccountId', memberAccount.Id);
        putIfWritable(participantRecord, 'ParticipantContactId', memberContactId);
        putIfWritable(participantRecord, 'RelatedParticipantId', memberContactId);
        putIfWritable(participantRecord, 'Role', 'Primary');
        insert participantRecord;

        ARC_CoverageParticipant__c coverageParticipant = new ARC_CoverageParticipant__c();
        putIfWritable(coverageParticipant, 'Name', 'ID Card Coverage Participant');
        putIfWritable(coverageParticipant, 'ARC_PolicyCoverage__c', coverageRecord.Id);
        putIfWritable(coverageParticipant, 'ARC_PolicyParticipant__c', participantRecord.Id);
        putIfWritable(coverageParticipant, 'ARC_ParticipantContact__c', memberContactId);
        putIfWritable(coverageParticipant, 'ARC_ParticipantAccount__c', memberAccount.Id);
        putIfWritable(coverageParticipant, 'ARC_Role__c', 'Primary');
        putIfWritable(coverageParticipant, 'ARC_CoverageRole__c', 'Primary');
        putIfWritable(coverageParticipant, 'ARC_ParticipantName__c', 'ID Card Member');
        putIfWritable(coverageParticipant, 'ARC_MemberId__c', 'IDCARD-MID-001');
        putIfWritable(coverageParticipant, 'ARC_Policy__c', policyRecord.Id);
        insert coverageParticipant;
    }

    // Builds the standard Callable args shape.
    private static Map<String, Object> buildArgs(Map<String, Object> inputMap) {
        return new Map<String, Object>{
            'input' => inputMap == null ? new Map<String, Object>() : inputMap,
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };
    }

    // Returns the output map after the callable runs.
    private static Map<String, Object> getOutput(Map<String, Object> args) {
        return (Map<String, Object>) args.get('output');
    }

    // Returns the typed result payload from output.
    private static Map<String, Object> getResult(Map<String, Object> outputMap) {
        Object rawResult = outputMap.get('result');
        return rawResult == null ? null : (Map<String, Object>) rawResult;
    }

    // Verifies unknown actions are rejected cleanly.
    @IsTest
    static void testCall_invalidAction_returnsFalseAndError() {
        ARC_IdCardApexAction actionHandler = new ARC_IdCardApexAction();
        Map<String, Object> args = buildArgs(new Map<String, Object>());

        Test.startTest();
        Boolean success = (Boolean) actionHandler.call('unknownAction', args);
        Test.stopTest();

        Map<String, Object> outputMap = getOutput(args);
        System.assertEquals(false, success, 'Unknown actions should return false.');
        System.assertNotEquals(null, outputMap.get('error'), 'Unknown actions should populate an error message.');
        System.assert(String.valueOf(outputMap.get('error')).contains('Method not found'), 'The error should explain that the action is not supported.');
    }

    // Verifies getIdCardOptions handles missing account input safely.
    @IsTest
    static void testCall_getIdCardOptions_missingAccount_returnsErrorResult() {
        ARC_IdCardApexAction actionHandler = new ARC_IdCardApexAction();
        Map<String, Object> args = buildArgs(new Map<String, Object>());

        Test.startTest();
        Boolean success = (Boolean) actionHandler.call('getIdCardOptions', args);
        Test.stopTest();

        Map<String, Object> outputMap = getOutput(args);
        Map<String, Object> resultMap = getResult(outputMap);

        System.assertEquals(true, success, 'Missing account should be handled as a business result, not a thrown exception.');
        System.assertNotEquals(null, resultMap, 'The output should include a result payload.');
        System.assertEquals('Error', String.valueOf(resultMap.get('status')), 'Missing account should return Error status.');
        System.assert(String.valueOf(resultMap.get('message')).contains('Missing AccountId'), 'The result should explain the missing account.');
    }

    // Verifies plan select options return an empty collection when no account can be resolved.
    @IsTest
    static void testCall_getPlanSelectOptions_missingAccount_returnsEmptyList() {
        ARC_IdCardApexAction actionHandler = new ARC_IdCardApexAction();
        Map<String, Object> args = buildArgs(new Map<String, Object>());

        Test.startTest();
        Boolean success = (Boolean) actionHandler.call('getPlanSelectOptions', args);
        Test.stopTest();

        Map<String, Object> outputMap = getOutput(args);
        Object rawOptions = outputMap.get('options');

        System.assertEquals(true, success, 'Missing account should still return successfully for plan options.');
        System.assertNotEquals(null, rawOptions, 'The output should include the options collection.');
        System.assertEquals(0, ((List<Object>) rawOptions).size(), 'Missing account should return no plan options.');
    }

    // Verifies buildPdfData fails fast when required inputs are missing.
    @IsTest
    static void testCall_buildPdfData_missingInputs_returnsFalseAndError() {
        ARC_IdCardApexAction actionHandler = new ARC_IdCardApexAction();
        Map<String, Object> args = buildArgs(new Map<String, Object>());

        Test.startTest();
        Boolean success = (Boolean) actionHandler.call('buildPdfData', args);
        Test.stopTest();

        Map<String, Object> outputMap = getOutput(args);
        System.assertEquals(false, success, 'Missing inputs should make buildPdfData fail.');
        System.assertNotEquals(null, outputMap.get('error'), 'The failure should populate an error message.');
        System.assertNotEquals('', String.valueOf(outputMap.get('error')).trim(), 'The error message should not be blank.');
        System.assertNotEquals(null, outputMap.get('stackTrace'), 'The failure should also capture a stack trace.');
    }

    // Verifies the bundle call returns options and skips pdf generation when account input is missing.
    @IsTest
    static void testCall_getIdCardBundle_missingAccount_returnsOptionsWithoutPdf() {
        ARC_IdCardApexAction actionHandler = new ARC_IdCardApexAction();
        Map<String, Object> args = buildArgs(new Map<String, Object>());

        Test.startTest();
        Boolean success = (Boolean) actionHandler.call('getIdCardBundle', args);
        Test.stopTest();

        Map<String, Object> outputMap = getOutput(args);
        Map<String, Object> optionsMap = outputMap.get('options') == null ? null : (Map<String, Object>) outputMap.get('options');

        System.assertEquals(true, success, 'Bundle call should still return a structured response.');
        System.assertNotEquals(null, optionsMap, 'Bundle output should include options data.');
        System.assertEquals('Error', String.valueOf(optionsMap.get('status')), 'Missing account should bubble up as an Error options status.');
        System.assertEquals(null, outputMap.get('pdfData'), 'No PDF payload should be returned when options are not activated.');
    }

    // Verifies buildPdfData rejects malformed selection tokens.
    @IsTest
    static void testCall_buildPdfData_invalidToken_returnsFalseAndError() {
        ARC_IdCardApexAction actionHandler = new ARC_IdCardApexAction();
        Map<String, Object> args = buildArgs(new Map<String, Object>{
            'ContextId' => UserInfo.getUserId(),
            'selectionToken' => 'bad-token'
        });

        Test.startTest();
        Boolean success = (Boolean) actionHandler.call('buildPdfData', args);
        Test.stopTest();

        Map<String, Object> outputMap = getOutput(args);
        System.assertEquals(false, success, 'Malformed selection tokens should fail the call.');
        System.assertNotEquals(null, outputMap.get('error'), 'The failure should populate an error.');
        System.assertNotEquals('', String.valueOf(outputMap.get('error')).trim(), 'The failure should provide a non-blank error message.');
        System.assertNotEquals(null, outputMap.get('stackTrace'), 'The failure should also capture a stack trace.');
    }

    @IsTest
    static void testCall_getIdCardOptions_happyPath_returnsStructuredResult() {
        ARC_IdCardApexAction actionHandler = new ARC_IdCardApexAction();
        Account seededAccount = getSeededAccount();

        Map<String, Object> args = buildArgs(new Map<String, Object>{
            'ContextId' => seededAccount.Id,
            'accountId' => seededAccount.Id,
            'AccountId' => seededAccount.Id
        });

        Integer activePolicyCount = [
            SELECT COUNT()
            FROM InsurancePolicy
            WHERE NameInsuredId = :seededAccount.Id
            AND Status = 'Activated'
        ];
        System.assertEquals(
            1,
            activePolicyCount,
            'Seeded data should contain one Activated InsurancePolicy for the target account.'
        );

        Integer activeCoverageCount = [
            SELECT COUNT()
            FROM InsurancePolicyCoverage
            WHERE InsurancePolicy.NameInsuredId = :seededAccount.Id
            AND InsurancePolicy.Status = 'Activated'
        ];
        System.assertEquals(
            1,
            activeCoverageCount,
            'Seeded data should contain one coverage related to the Activated InsurancePolicy.'
        );

        Integer coverageParticipantCount = [
            SELECT COUNT()
            FROM ARC_CoverageParticipant__c
            WHERE ARC_PolicyCoverage__r.InsurancePolicy.NameInsuredId = :seededAccount.Id
        ];
        System.assertEquals(
            1,
            coverageParticipantCount,
            'Seeded data should contain one coverage participant connected to the policy coverage.'
        );

        Test.startTest();
        Boolean success = (Boolean) actionHandler.call('getIdCardOptions', args);
        Test.stopTest();

        Map<String, Object> outputMap = getOutput(args);
        Map<String, Object> resultMap = getResult(outputMap);

        System.assertEquals(true, success, 'getIdCardOptions should complete successfully.');
        System.assertNotEquals(null, resultMap, 'getIdCardOptions should return a result payload.');
        System.assertEquals(
            'Activated',
            String.valueOf(resultMap.get('status')),
            'Seeded data should return an Activated ID card option. Full result: ' + JSON.serialize(resultMap)
        );
    }

    @IsTest
    static void testCall_getIdCardBundle_happyPath_returnsStructuredResponse() {
        ARC_IdCardApexAction actionHandler = new ARC_IdCardApexAction();
        Account seededAccount = getSeededAccount();

        Map<String, Object> args = buildArgs(new Map<String, Object>{
            'ContextId' => seededAccount.Id,
            'accountId' => seededAccount.Id,
            'AccountId' => seededAccount.Id
        });

        Test.startTest();
        Boolean success = (Boolean) actionHandler.call('getIdCardBundle', args);
        Test.stopTest();

        Map<String, Object> outputMap = getOutput(args);
        System.assertEquals(true, success, 'getIdCardBundle should complete successfully.');
        System.assertNotEquals(null, outputMap.get('options'), 'Bundle output should include options data.');
    }
}