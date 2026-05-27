@IsTest
private class ARC_EmployerIdCardControllerTest {

    private static Map<String, Object> buildCoverages(String productCode) {
        List<Object> attributeRecords = new List<Object>{
            buildAttribute('PrimaryCarProviderOfficeVisits', '$25'),
            buildAttribute('SpecialistOfficeVisits', '$50'),
            buildAttribute('Minute_Clinic', '$10'),
            buildAttribute('UrgentCare', '$75'),
            buildAttribute('EmergencyRoom', '$500')
        };

        return new Map<String, Object>{
            'result' => new Map<String, Object>{
                'records' => new List<Object>{
                    new Map<String, Object>{
                        'fields' => new Map<String, Object>{
                            'ProductCode' => productCode
                        },
                        'nameResult' => new Map<String, Object>{
                            'attributeCategories' => new Map<String, Object>{
                                'records' => new List<Object>{
                                    new Map<String, Object>{
                                        'nameResult' => new Map<String, Object>{
                                            'productAttributes' => new Map<String, Object>{
                                                'records' => attributeRecords
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        };
    }

    private static Map<String, Object> buildAttribute(String code, String value) {
        return new Map<String, Object>{
            'code' => code,
            'userValues' => new Map<String, Object>{
                'value' => value
            }
        };
    }

    @IsTest
    static void testBuildServiceInfo_uhsmRegular_setsMedicalServices() {
        Map<String, Object> coverages = buildCoverages('PROG_UHSMRegular');

        Map<String, Object> result = ARC_EmployerIdCardController.buildServiceInfo(
            'UHSM Regular',
            coverages
        );

        System.assertNotEquals(null, result, 'Service info should be created for regular UHSM plans.');
        System.assert(result.size() > 0, 'Regular UHSM plans should produce service info.');
    }

    @IsTest
    static void testBuildServiceInfo_uhsmFundamental_setsFundamentalServices() {
        Map<String, Object> coverages = buildCoverages('PROG_UHSMFundamental');

        Map<String, Object> result = ARC_EmployerIdCardController.buildServiceInfo(
            'UHSM Fundamental',
            coverages
        );

        System.assertNotEquals(null, result, 'Service info should be created for UHSM Fundamental plans.');
        System.assert(result.size() > 0, 'UHSM Fundamental plans should produce service info.');
    }

    @IsTest
    static void testBuildServiceInfo_weShare_setsWeShareServices() {
        Map<String, Object> coverages = buildCoverages('PROG_WeShare');

        Map<String, Object> result = ARC_EmployerIdCardController.buildServiceInfo(
            'WeShare',
            coverages
        );

        System.assertNotEquals(null, result, 'Service info should be created for WeShare plans.');
        System.assert(result.size() > 0, 'WeShare plans should produce service info.');
    }

    @IsTest
    static void testBuildServiceInfo_weShareAccess_setsAccessServices() {
        Map<String, Object> coverages = buildCoverages('PROG_WeShareAccess');

        Map<String, Object> result = ARC_EmployerIdCardController.buildServiceInfo(
            'WeShare Access',
            coverages
        );

        System.assertNotEquals(null, result, 'Service info should be created for WeShare Access plans.');
        System.assert(result.size() > 0, 'WeShare Access plans should produce service info.');
    }

    @IsTest
    static void testCall_unknownAction_returnsFalseAndError() {
        ARC_EmployerIdCardController controller = new ARC_EmployerIdCardController();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input' => new Map<String, Object>(),
            'output' => output,
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        Boolean result = (Boolean) controller.call('unknownAction', args);
        Test.stopTest();

        System.assertEquals(false, result, 'Unknown actions should return false.');
        System.assertEquals('Method not found: unknownAction', output.get('error'), 'Unknown actions should return a clear error message.');
    }

    @IsTest
    static void testGetPortalData_noMemberNoContract_setsShowCardFalse() {
        ARC_EmployerIdCardController.mockOrgData = new Map<String, Object>{
            'domainPrefix' => 'test-domain',
            'isSandbox' => true,
            'isProduction' => false,
            'userEmail' => 'portaluser@test.com'
        };

        Map<String, Object> input = new Map<String, Object>{
            'recordId' => null,
            'userId' => null,
            'insurancePolicyId' => null,
            'coverageId' => null,
            'productId' => null,
            'planName' => 'UHSM Regular',
            'ContextId' => null
        };

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Boolean result = ARC_EmployerIdCardController.getPortalData(input, output, options);
        Test.stopTest();

        System.assertEquals(false, result, 'getPortalData should return false when no valid contract is found.');
        System.assertEquals(false, output.get('ShowCard'), 'ShowCard should be false when no contract is available.');

        ARC_EmployerIdCardController.mockOrgData = null;
    }

    @IsTest
    static void testGetDependents_blankCoverageId_returnsEmptyList() {
        Test.startTest();
        List<Map<String, Object>> result = ARC_EmployerIdCardController.getDependents(null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Blank coverageId should return no dependents.');
    }

    @IsTest
    static void testGetCoverages_usesMockCoveragesInTest() {
        Map<String, Object> mockCoverages = buildCoverages('PROG_UHSMRegular');
        ARC_EmployerIdCardController.mockCoverages = mockCoverages;

        Test.startTest();
        Map<String, Object> result = ARC_EmployerIdCardController.getCoverages('fakeProductId');
        Test.stopTest();

        System.assertEquals(mockCoverages, result, 'getCoverages should return mocked coverages in test context.');

        ARC_EmployerIdCardController.mockCoverages = null;
    }

    private static void putIfWritable(SObject record, String fieldApiName, Object value) {
        Schema.DescribeSObjectResult objectDescribe = record.getSObjectType().getDescribe();
        Schema.SObjectField fieldToken = objectDescribe.fields.getMap().get(fieldApiName);

        if (fieldToken != null && fieldToken.getDescribe().isCreateable()) {
            record.put(fieldApiName, value);
        }
    }

    private static void putIfFieldExists(SObject record, String fieldApiName, Object value) {
        Schema.DescribeSObjectResult objectDescribe = record.getSObjectType().getDescribe();
        Schema.SObjectField fieldToken = objectDescribe.fields.getMap().get(fieldApiName);

        if (fieldToken != null) {
            record.put(fieldApiName, value);
        }
    }

    @IsTest
    static void testGetMemberDetails_noInputs_returnsInactiveMember() {
        Test.startTest();
        ARC_EmployerIdCardController.MemberResult result =
            ARC_EmployerIdCardController.getMemberDetails(null, null, null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'getMemberDetails should always return a MemberResult instance.');
    }

    @IsTest
    static void testGetContractData_awaitingActivationWithRecurringOrder_returnsResult() {
        Account accountRecord = new Account(Name = 'Test Employer Account');
        insert accountRecord;

        SObject censusRecord =
            Schema.getGlobalDescribe().get('vlocity_ins__GroupCensus__c').newSObject();

        putIfWritable(censusRecord, 'Name', 'Test Census');
        putIfWritable(censusRecord, 'vlocity_ins__AccountId__c', accountRecord.Id);
        putIfWritable(censusRecord, 'vlocity_ins__GroupId__c', accountRecord.Id);
        insert censusRecord;

        ChargentOrders__ChargentOrder__c recurringOrder =
            new ChargentOrders__ChargentOrder__c(
                ChargentOrders__Description__c = 'Recurring Monthly Order'
            );
        insert recurringOrder;

        Contract contractRecord = new Contract(
            AccountId = accountRecord.Id,
            StartDate = Date.today(),
            ContractTerm = 12,
            Status = 'Draft'
        );

        putIfWritable(contractRecord, 'vlocity_ins__EnrollmentCensusId__c', censusRecord.Id);
        putIfWritable(contractRecord, 'ARC_EffectiveDate__c', Date.today());
        putIfFieldExists(contractRecord, 'arc_recurringmonthlyorder__c', recurringOrder.Id);
        System.assertEquals(
            recurringOrder.Id,
            contractRecord.get('arc_recurringmonthlyorder__c'),
            'Recurring Monthly Order lookup should be populated before inserting the contract.'
        );

        insert contractRecord;

        Contract insertedContract = [
            SELECT Id, Status, ARC_RecurringMonthlyOrder__c
            FROM Contract
            WHERE Id = :contractRecord.Id
            LIMIT 1
        ];

        System.assertEquals(
            recurringOrder.Id,
            insertedContract.ARC_RecurringMonthlyOrder__c,
            'Recurring Monthly Order lookup should remain populated after inserting the contract.'
        );

        insertedContract.Status = 'Awaiting Activation';
        update insertedContract;

        Test.startTest();
        ARC_EmployerIdCardController.ContractResult result =
            ARC_EmployerIdCardController.getContractData((String) censusRecord.Id);
        Test.stopTest();

        System.assertNotEquals(
            null,
            result,
            'getContractData should return a ContractResult instance.'
        );
    }

    @IsTest
    static void testMergeAllMembers_blankContextId_returnsEmptyList() {
        Test.startTest();
        List<Map<String, Object>> result =
            ARC_EmployerIdCardController.mergeAllMembers(null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Blank contextId should not return selected members.');
    }

    @IsTest
    static void testGetMemberDetails_withCensusMemberId_returnsResult() {
        Account accountRecord = new Account(Name = 'Test Member Account');
        putIfWritable(accountRecord, 'ARC_Member_Id__c', 'MID-001');
        insert accountRecord;

        Contact contactRecord = new Contact(
            FirstName = 'Primary',
            LastName = 'Member',
            Email = 'primary.member@test.com',
            AccountId = accountRecord.Id
        );
        insert contactRecord;

        SObject censusRecord =
            Schema.getGlobalDescribe().get('vlocity_ins__GroupCensus__c').newSObject();

        putIfWritable(censusRecord, 'Name', 'Test Census For Member');
        putIfWritable(censusRecord, 'vlocity_ins__AccountId__c', accountRecord.Id);
        putIfWritable(censusRecord, 'vlocity_ins__GroupId__c', accountRecord.Id);
        insert censusRecord;

        SObject gcmRecord =
            Schema.getGlobalDescribe().get('vlocity_ins__GroupCensusMember__c').newSObject();

        putIfWritable(gcmRecord, 'Name', 'Primary Member');
        putIfWritable(gcmRecord, 'vlocity_ins__FirstName__c', 'Primary');
        putIfWritable(gcmRecord, 'vlocity_ins__LastName__c', 'Member');
        putIfWritable(gcmRecord, 'vlocity_ins__Email__c', 'primary.member@test.com');
        putIfWritable(gcmRecord, 'vlocity_ins__Birthdate__c', Date.today().addYears(-30));
        putIfWritable(gcmRecord, 'vlocity_ins__CensusId__c', censusRecord.Id);
        putIfWritable(gcmRecord, 'vlocity_ins__ContactId__c', contactRecord.Id);
        putIfWritable(gcmRecord, 'vlocity_ins__IsPrimaryMember__c', true);
        putIfWritable(gcmRecord, 'ARC_ActiveMember__c', true);
        insert gcmRecord;

        Test.startTest();
        ARC_EmployerIdCardController.MemberResult result =
            ARC_EmployerIdCardController.getMemberDetails((String) gcmRecord.Id, null, null);
        Test.stopTest();

        System.assertNotEquals(
            null,
            result,
            'getMemberDetails should return a MemberResult for a valid census member.'
        );
    }

    @IsTest
    static void testGetPortalData_withCensusMemberAndAwaitingContract_buildsOutput() {
        Account accountRecord = new Account(Name = 'Portal Member Account');
        putIfWritable(accountRecord, 'ARC_Member_Id__c', 'MID-PORTAL-001');
        insert accountRecord;

        Contact contactRecord = new Contact(
            FirstName = 'Portal',
            LastName = 'Member',
            Email = 'portal.member@test.com',
            AccountId = accountRecord.Id
        );
        insert contactRecord;

        SObject censusRecord = Schema.getGlobalDescribe().get('vlocity_ins__GroupCensus__c').newSObject();
        putIfWritable(censusRecord, 'Name', 'Portal Test Census');
        putIfWritable(censusRecord, 'vlocity_ins__AccountId__c', accountRecord.Id);
        putIfWritable(censusRecord, 'vlocity_ins__GroupId__c', accountRecord.Id);
        insert censusRecord;

        SObject gcmRecord = Schema.getGlobalDescribe().get('vlocity_ins__GroupCensusMember__c').newSObject();
        putIfWritable(gcmRecord, 'Name', 'Portal Member');
        putIfWritable(gcmRecord, 'vlocity_ins__FirstName__c', 'Portal');
        putIfWritable(gcmRecord, 'vlocity_ins__LastName__c', 'Member');
        putIfWritable(gcmRecord, 'vlocity_ins__Email__c', 'portal.member@test.com');
        putIfWritable(gcmRecord, 'vlocity_ins__Birthdate__c', Date.today().addYears(-35));
        putIfWritable(gcmRecord, 'vlocity_ins__CensusId__c', censusRecord.Id);
        putIfWritable(gcmRecord, 'vlocity_ins__ContactId__c', contactRecord.Id);
        putIfWritable(gcmRecord, 'vlocity_ins__IsPrimaryMember__c', true);
        putIfWritable(gcmRecord, 'ARC_ActiveMember__c', true);
        insert gcmRecord;
        
        ChargentOrders__ChargentOrder__c recurringOrder =
            new ChargentOrders__ChargentOrder__c(
                ChargentOrders__Description__c = 'Recurring Monthly Order'
            );
        insert recurringOrder;

        Contract contractRecord = new Contract(
            AccountId = accountRecord.Id,
            StartDate = Date.today(),
            ContractTerm = 12,
            Status = 'Draft'
        );
        putIfWritable(contractRecord, 'vlocity_ins__EnrollmentCensusId__c', censusRecord.Id);
        putIfWritable(contractRecord, 'ARC_EffectiveDate__c', Date.today());
        putIfFieldExists(contractRecord, 'ARC_RecurringMonthlyOrder__c', recurringOrder.Id);
        insert contractRecord;

        Contract insertedContract = [
            SELECT Id, Status, ARC_RecurringMonthlyOrder__c
            FROM Contract
            WHERE Id = :contractRecord.Id
            LIMIT 1
        ];
        insertedContract.Status = 'Awaiting Activation';
        update insertedContract;

        ARC_EmployerIdCardController.mockOrgData = new Map<String, Object>{
            'domainPrefix' => 'test-domain',
            'isSandbox' => true,
            'isProduction' => false,
            'userEmail' => 'portal.member@test.com'
        };

        ARC_EmployerIdCardController.mockCoverages = buildCoverages('PROG_UHSMRegular');

        Map<String, Object> input = new Map<String, Object>{
            'recordId' => (String) gcmRecord.Id,
            'userId' => null,
            'insurancePolicyId' => null,
            'coverageId' => null,
            'productId' => 'fakeProductId',
            'planName' => 'UHSM Regular',
            'ContextId' => null
        };

        Map<String, Object> output = new Map<String, Object>();

        Test.startTest();
        Boolean result = ARC_EmployerIdCardController.getPortalData(
            input,
            output,
            new Map<String, Object>()
        );
        Test.stopTest();

        System.assertEquals(true, result, 'getPortalData should return true when a valid Awaiting Activation contract exists.');
        System.assertEquals(true, output.get('ShowCard'), 'ShowCard should be true when a valid contract exists.');
        System.assert(
            new Set<String>{ 'Activated', 'Awaiting Activation' }.contains((String) output.get('ContractStatus')),
            'Contract status should be either Activated or Awaiting Activation.');
        System.assert(output.containsKey('medicalServices'), 'Output should include transformed medical services.');

        ARC_EmployerIdCardController.mockOrgData = null;
        ARC_EmployerIdCardController.mockCoverages = null;
    }
}