@IsTest
private class ARC_SGQLEBaseServiceTest {
    private class SmallGroupCompositeEnvelopeMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"envelopeId":"TEST-SG-QLE-ENVELOPE","status":"sent","message":"Mock composite envelope sent"}');
            return response;
        }
    }
    private static Case createQLECase(String statusValue) {
        return new Case(
            Subject = 'Test QLE Case',
            Status = statusValue,
            Origin = 'Phone',
            Description = 'This is a test'
        );
    }

    private static String buildNormalQLEPayloadForIntegrationTest(
        Id personAccountId,
        Id groupAccountId,
        Id censusId,
        Id primaryCensusMemberId,
        Id contractId,
        Id priorPolicyId,
        Id currentProductId,
        Id newProductId,
        Date effectiveDate
    ) {
        Map<String, Object> payload = new Map<String, Object>{
            'enrollmentId' => 'TEST-QLE-INTEGRATION-001',
            'traceId' => 'TRACE-QLE-INTEGRATION-001',
            'generalInformation' => new Map<String, Object>{
                'accountId' => String.valueOf(personAccountId),
                'groupAccountId' => String.valueOf(groupAccountId),
                'censusId' => String.valueOf(censusId),
                'contractId' => String.valueOf(contractId),
                'primaryCensusMemberId' => String.valueOf(primaryCensusMemberId),
                'effectiveDate' => String.valueOf(effectiveDate),
                'medicalProgram' => new Map<String, Object>{
                    'New Integration Plan' => new Map<String, Object>{
                        'productId' => String.valueOf(newProductId),
                        'individualPrice' => 100.00,
                        'employeeSplit' => 25.00,
                        'employerSplit' => 75.00,
                        'basePrice' => 100.00
                    }
                },
                'qleType' => 'Marriage',
                'qleSubtype' => 'Gain Eligibility',
                'guardian' => new Map<String, Object>{
                    'relationship' => 'Parent',
                    'firstName' => 'Guardian',
                    'lastName' => 'Test',
                    'dob' => '1980-01-01',
                    'email' => 'guardian.test@example.com',
                    'phone' => '5555555555',
                    'gender' => 'Female',
                    'address' => new Map<String, Object>{
                        'street' => '123 Guardian St',
                        'city' => 'Dallas',
                        'state' => 'TX',
                        'zip' => '75001'
                    }
                },
                'hipaa' => new List<Object>{
                    new Map<String, Object>{
                        'CHK_Authorized' => true,
                        'firstName' => 'Guardian',
                        'lastName' => 'Test',
                        'dob' => '1980-01-01',
                        'relationship' => 'Parent'
                    },
                    new Map<String, Object>{
                        'CHK_Authorized' => true,
                        'firstName' => 'Third',
                        'lastName' => 'Party',
                        'relationship' => 'Third Party',
                        'DAT_DOB' => '1985-01-01',
                        'email' => 'third.party@example.com',
                        'phone' => '5555555555',
                        'address' => new Map<String, Object>{
                            'street' => '456 Third St',
                            'city' => 'Dallas',
                            'state' => 'TX',
                            'zip' => '75002'
                        }
                    },
                    new Map<String, Object>{
                        'CHK_Authorized' => true,
                        'firstName' => 'Fallback',
                        'lastName' => 'Updated',
                        'relationship' => 'Primary',
                        'memberId' => String.valueOf(primaryCensusMemberId)
                    }
                },
                'qleChanges' => new Map<String, Object>{
                    'noChanges' => false,
                    'memberChanges' => true,
                    'productChanges' => false,
                    'policyChanges' => false
                }
            },
            'currentState' => new Map<String, Object>{
                'currentPolicy' => new Map<String, Object>{
                    'policyId' => String.valueOf(priorPolicyId),
                    'employeeAccountId' => String.valueOf(personAccountId),
                    'status' => 'Active',
                    'effectiveDate' => String.valueOf(effectiveDate.addMonths(-1)),
                    'terminationDate' => null
                },
                'currentProducts' => new Map<String, Object>{
                    'Current Integration Plan' => new Map<String, Object>{
                        'productId' => String.valueOf(currentProductId)
                    }
                },
                'currentMembers' => new List<Object>{
                    new Map<String, Object>{
                        'memberExternalId' => 'TEST-MEMBER-PRIMARY-001',
                        'role' => 'Primary',
                        'productId' => String.valueOf(currentProductId),
                        'person' => new Map<String, Object>{
                            'firstName' => 'Fallback',
                            'lastName' => 'Test',
                            'dob' => '1990-01-01',
                            'email' => 'fallback.primary@example.com',
                            'smoker' => false,
                            'isSmoker' => false,
                            'tobaccoUser' => false,
                            'isPregnant' => false,
                            'pregnant' => false
                        }
                    }
                }
            },
            'members' => new List<Object>{
                new Map<String, Object>{
                    'memberExternalId' => 'TEST-MEMBER-PRIMARY-001',
                    'memberId' => String.valueOf(primaryCensusMemberId),
                    'paId' => String.valueOf(personAccountId),
                    'role' => 'Primary',
                    'action' => 'Update',
                    'productId' => String.valueOf(newProductId),
                    'person' => new Map<String, Object>{
                        'firstName' => 'Fallback',
                        'lastName' => 'Updated',
                        'dob' => '1990-01-01',
                        'email' => 'fallback.updated@example.com',
                        'isLegacy' => false,
                        'smoker' => false,
                        'isSmoker' => false,
                        'tobaccoUser' => false,
                        'isPregnant' => false,
                        'pregnant' => false
                    },
                    'qleChanges' => new Map<String, Object>{
                        'demographicChanges' => true
                    }
                }
            }
        };

        return JSON.serialize(payload);
    }

    private static String buildReinstatementLikeQLEPayloadForIntegrationTest(
        Id personAccountId,
        Id groupAccountId,
        Id censusId,
        Id primaryCensusMemberId,
        Id contractId,
        Id priorPolicyId,
        Id currentProductId,
        Id newProductId,
        Date effectiveDate,
        String currentPolicyStatus
    ) {
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(
            buildNormalQLEPayloadForIntegrationTest(
                personAccountId,
                groupAccountId,
                censusId,
                primaryCensusMemberId,
                contractId,
                priorPolicyId,
                currentProductId,
                newProductId,
                effectiveDate
            )
        );

        Map<String, Object> generalInformation = (Map<String, Object>) payload.get('generalInformation');
        generalInformation.put('qleType', 'Other Coverage');
        generalInformation.put('qleSubtype', 'Lose Eligibility');
        generalInformation.put('qleChanges', new Map<String, Object>{
            'noChanges' => false,
            'memberChanges' => true,
            'productChanges' => false,
            'policyChanges' => true
        });

        Map<String, Object> currentState = (Map<String, Object>) payload.get('currentState');
        Map<String, Object> currentPolicy = (Map<String, Object>) currentState.get('currentPolicy');
        currentPolicy.put('status', currentPolicyStatus);
        currentPolicy.put('terminationDate', currentPolicyStatus == 'Terminated' ? String.valueOf(effectiveDate.addDays(-1)) : null);

        return JSON.serialize(payload);
    }

    private static void createUpgradeDowngradeMatrixSetupForIntegrationTest() {
        vlocity_ins__CalculationMatrix__c matrix = new vlocity_ins__CalculationMatrix__c(
            Name = 'ARC_UHSM_Programs2023'
        );
        insert matrix;

        vlocity_ins__CalculationMatrixVersion__c matrixVersion = new vlocity_ins__CalculationMatrixVersion__c(
            Name = 'ARC_UHSM_Programs2023 Test Version',
            vlocity_ins__CalculationMatrixId__c = matrix.Id,
            vlocity_ins__IsEnabled__c = true,
            vlocity_ins__VersionNumber__c = 1
        );
        insert matrixVersion;

        vlocity_ins__CalculationMatrixRow__c matrixRow = new vlocity_ins__CalculationMatrixRow__c(
            Name = 'Current Integration Plan Row',
            vlocity_ins__CalculationMatrixVersionId__c = matrixVersion.Id,
            vlocity_ins__InputData__c = JSON.serialize(new Map<String, Object>{
                'Program' => 'Current Integration Plan'
            }),
            vlocity_ins__OutputData__c = JSON.serialize(new Map<String, Object>{
                'Upgrade Result' => 'New Integration Plan',
                'Downgrade Result' => ''
            })
        );
        insert matrixRow;
    }

    
    private static Map<String, Id> createQLEIntegratedFlowRecords(Id personAccountId, Id groupAccountId) {
        Product2 currentProduct = new Product2(
            Name = 'Current Integration Plan',
            IsActive = true,
            vlocity_ins__Type__c = 'Medical'
        );
        insert currentProduct;

        Product2 newProduct = new Product2(
            Name = 'New Integration Plan',
            IsActive = true,
            vlocity_ins__Type__c = 'Medical'
        );
        insert newProduct;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(
            Name = 'QLE Integration Test Census',
            vlocity_ins__GroupId__c = groupAccountId
        );
        insert census;

        vlocity_ins__GroupCensusMember__c primaryCensusMember = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__CensusId__c = census.Id,
            vlocity_ins__FirstName__c = 'Fallback',
            vlocity_ins__LastName__c = 'Test',
            vlocity_ins__Email__c = 'fallback.primary@example.com',
            vlocity_ins__Birthdate__c = Date.newInstance(1990, 1, 1),
            vlocity_ins__IsPrimaryMember__c = true,
            ARC_ActiveMember__c = true
        );
        insert primaryCensusMember;

        Contract testContract = new Contract(
            AccountId = groupAccountId,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 12
        );
        insert testContract;

        InsurancePolicy priorPolicy = new InsurancePolicy(
            Name = 'QLE Integration Prior Policy',
            PolicyName = 'QLE Integration Prior Policy',
            Status = 'Draft',
            ARC_GroupAccount__c = groupAccountId,
            ARC_Contract__c = testContract.Id,
            ARC_EmployeeAccount__c = personAccountId,
            NameInsuredId = personAccountId,
            ARC_PolicyEffectiveDate__c = Date.today().addMonths(-1)
        );
        insert priorPolicy;

        seedPriorPolicyRelatedRecordsForReinstatement(
            priorPolicy.Id,
            personAccountId,
            currentProduct.Id,
            newProduct.Id
        );

        return new Map<String, Id>{
            'censusId' => census.Id,
            'primaryCensusMemberId' => primaryCensusMember.Id,
            'contractId' => testContract.Id,
            'priorPolicyId' => priorPolicy.Id,
            'currentProductId' => currentProduct.Id,
            'newProductId' => newProduct.Id
        };
    }

    private static void seedPriorPolicyRelatedRecordsForReinstatement(
        Id priorPolicyId,
        Id personAccountId,
        Id currentProductId,
        Id newProductId
    ) {
        Id policyParticipantId = insertInsurancePolicyParticipantForReinstatement(priorPolicyId, personAccountId);

        Id parentCoverageId = insertInsurancePolicyCoverageForReinstatement(
            priorPolicyId,
            currentProductId,
            null,
            'Parent Medical Coverage'
        );

        Id childCoverageId = insertInsurancePolicyCoverageForReinstatement(
            priorPolicyId,
            newProductId,
            parentCoverageId,
            'Child Medical Coverage'
        );

        insertCoverageParticipantForReinstatement(priorPolicyId, parentCoverageId, personAccountId, policyParticipantId);
        insertCoverageParticipantForReinstatement(priorPolicyId, childCoverageId, personAccountId, policyParticipantId);
    }

    private static void putIfFieldExists(SObject record, String fieldName, Object value) {
        if (value == null) {
            return;
        }

        Map<String, Schema.SObjectField> fields = record.getSObjectType().getDescribe().fields.getMap();
        if (!fields.containsKey(fieldName)) {
            return;
        }

        Schema.DescribeFieldResult fieldDescribe = fields.get(fieldName).getDescribe();
        if (!fieldDescribe.isCreateable()) {
            return;
        }

        record.put(fieldName, value);
    }

    private static Id insertInsurancePolicyParticipantForReinstatement(Id priorPolicyId, Id personAccountId) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get('InsurancePolicyParticipant');
        if (objectType == null) {
            return null;
        }

        SObject participant = objectType.newSObject();
        putIfFieldExists(participant, 'Name', 'Prior Policy Participant');
        putIfFieldExists(participant, 'InsurancePolicyId', priorPolicyId);
        putIfFieldExists(participant, 'InsurancePolicyId__c', priorPolicyId);
        putIfFieldExists(participant, 'ARC_InsurancePolicy__c', priorPolicyId);
        putIfFieldExists(participant, 'ParticipantId', personAccountId);
        putIfFieldExists(participant, 'AccountId', personAccountId);
        putIfFieldExists(participant, 'RelatedParticipantId', personAccountId);
        putIfFieldExists(participant, 'ARC_PersonAccount__c', personAccountId);
        putIfFieldExists(participant, 'Role', 'Primary');
        putIfFieldExists(participant, 'Role__c', 'Primary');
        putIfFieldExists(participant, 'ARC_Role__c', 'Primary');
        insert participant;
        return (Id) participant.get('Id');
    }

    private static Id insertInsurancePolicyCoverageForReinstatement(
        Id priorPolicyId,
        Id productId,
        Id parentCoverageId,
        String coverageName
    ) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get('InsurancePolicyCoverage');
        if (objectType == null) {
            return null;
        }

        SObject coverage = objectType.newSObject();
        putIfFieldExists(coverage, 'Name', coverageName);
        putIfFieldExists(coverage, 'InsurancePolicyId', priorPolicyId);
        putIfFieldExists(coverage, 'InsurancePolicyId__c', priorPolicyId);
        putIfFieldExists(coverage, 'ARC_InsurancePolicy__c', priorPolicyId);
        putIfFieldExists(coverage, 'Product2Id', productId);
        putIfFieldExists(coverage, 'ProductId', productId);
        putIfFieldExists(coverage, 'vlocity_ins__Product2Id__c', productId);
        putIfFieldExists(coverage, 'ARC_Product__c', productId);
        putIfFieldExists(coverage, 'ARC_Product2__c', productId);
        putIfFieldExists(coverage, 'ARC_ParentPolicyCoverage__c', parentCoverageId);
        putIfFieldExists(coverage, 'ParentPolicyCoverageId', parentCoverageId);
        putIfFieldExists(coverage, 'Status', 'Active');
        putIfFieldExists(coverage, 'EffectiveDate', Date.today().addMonths(-1));
        putIfFieldExists(coverage, 'ExpirationDate', Date.today().addDays(-1));
        insert coverage;
        return (Id) coverage.get('Id');
    }

    private static void insertCoverageParticipantForReinstatement(Id priorPolicyId, Id policyCoverageId, Id personAccountId, Id policyParticipantId) {
        if (policyCoverageId == null) {
            return;
        }

        Schema.SObjectType objectType = Schema.getGlobalDescribe().get('ARC_CoverageParticipant__c');
        if (objectType == null) {
            return;
        }

        SObject coverageParticipant = objectType.newSObject();
        putIfFieldExists(coverageParticipant, 'Name', 'Prior Coverage Participant');
        putIfFieldExists(coverageParticipant, 'ARC_Policy__c', priorPolicyId);
        putIfFieldExists(coverageParticipant, 'ARC_InsurancePolicy__c', priorPolicyId);
        putIfFieldExists(coverageParticipant, 'InsurancePolicyId__c', priorPolicyId);
        putIfFieldExists(coverageParticipant, 'ARC_PolicyCoverage__c', policyCoverageId);
        putIfFieldExists(coverageParticipant, 'InsurancePolicyCoverageId__c', policyCoverageId);
        putIfFieldExists(coverageParticipant, 'ARC_PersonAccount__c', personAccountId);
        putIfFieldExists(coverageParticipant, 'ARC_PolicyParticipant__c', policyParticipantId);
        putIfFieldExists(coverageParticipant, 'AccountId__c', personAccountId);
        putIfFieldExists(coverageParticipant, 'ARC_Role__c', 'Primary');
        insert coverageParticipant;
    }

    @IsTest
    static void testSaveQLERequestSnapshot_minimalPayload_returnsHandledFailure() {
        Case qleCase = createQLECase('Awaiting Signature');
        insert qleCase;

        String payloadJson = JSON.serialize(new Map<String, Object>{
            'enrollmentId' => 'TEST-ENROLLMENT-001',
            'traceId' => 'TRACE-001',
            'generalInformation' => new Map<String, Object>{
                'accountId' => '001000000000001AAA',
                'censusId' => 'TEST-CENSUS-001',
                'groupAccountId' => '001000000000002AAA',
                'contractId' => '800000000000001AAA',
                'primaryCensusMemberId' => 'TEST-PRIMARY-001',
                'effectiveDate' => '2026-01-01',
                'medicalProgram' => 'Test Medical Program'
            }
        });

        Test.startTest();
        Map<String, Object> result = ARC_SGQLEBaseService.saveQLERequestSnapshot(qleCase.Id, payloadJson);
        Test.stopTest();

        System.assertEquals(false, result.get('success'),
            'A minimal payload should now return a handled failure because saveQLERequestSnapshot also evaluates changes and prepares DocuSign data. Result=' + String.valueOf(result));
        System.assert(
            String.valueOf(result).contains('error') || String.valueOf(result).contains('message'),
            'Handled failure should include diagnostic information. Result=' + String.valueOf(result)
        );

        Case updatedCase = [
            SELECT Id
            FROM Case
            WHERE Id = :qleCase.Id
            LIMIT 1
        ];

        System.assertEquals(qleCase.Id, updatedCase.Id,
            'The Case should still exist after the handled failure.');
    }

    @IsTest
    static void testSaveQLERequestSnapshot_integrationPayload_attemptsDocuSignFlow() {
        createUpgradeDowngradeMatrixSetupForIntegrationTest();

        Account personAccount = new Account(
            LastName = 'Snapshot Integration Test'
        );
        insert personAccount;

        Account groupAccount = new Account(
            Name = 'Snapshot Integration Group Account'
        );
        insert groupAccount;

        Map<String, Id> integratedFlowRecords = createQLEIntegratedFlowRecords(personAccount.Id, groupAccount.Id);

        Case qleCase = createQLECase('New');
        qleCase.ARC_PersonAccount__c = personAccount.Id;
        qleCase.ARC_QLEType__c = 'Marriage';
        qleCase.ARC_QLESubType__c = 'Gain Eligibility';
        qleCase.ARC_QLEEffectiveDate__c = Date.today();
        insert qleCase;

        String payloadJson = buildNormalQLEPayloadForIntegrationTest(
            personAccount.Id,
            groupAccount.Id,
            integratedFlowRecords.get('censusId'),
            integratedFlowRecords.get('primaryCensusMemberId'),
            integratedFlowRecords.get('contractId'),
            integratedFlowRecords.get('priorPolicyId'),
            integratedFlowRecords.get('currentProductId'),
            integratedFlowRecords.get('newProductId'),
            Date.today()
        );

        Test.setMock(HttpCalloutMock.class, new SmallGroupCompositeEnvelopeMock());

        Test.startTest();
        Map<String, Object> result = ARC_SGQLEBaseService.saveQLERequestSnapshot(qleCase.Id, payloadJson);
        Test.stopTest();

        System.assertNotEquals(null, result,
            'saveQLERequestSnapshot should always return a result map.');
        System.assert(result.containsKey('success'),
            'Result should include success flag. Result=' + String.valueOf(result));

        Case refreshedCase = [
            SELECT Status,
                   ARC_QLE_RequestPayload__c,
                   ARC_QLE_SubmittedDateTime__c
            FROM Case
            WHERE Id = :qleCase.Id
            LIMIT 1
        ];

        System.assertEquals('Awaiting Signature', refreshedCase.Status,
            'saveQLERequestSnapshot should normalize the Case status to Awaiting Signature before processing. Result=' + String.valueOf(result));
        System.assertNotEquals(null, refreshedCase.ARC_QLE_RequestPayload__c,
            'The evaluated QLE payload should be stored on the Case when processing reaches the snapshot update. Result=' + String.valueOf(result));
        System.assertNotEquals(null, refreshedCase.ARC_QLE_SubmittedDateTime__c,
            'Submitted datetime should be populated when processing reaches the snapshot update. Result=' + String.valueOf(result));
    }

    @IsTest
    static void testExecute_alreadySuccessful_doesNothing() {
        Case qleCase = createQLECase('Awaiting Signature');
        qleCase.ARC_QLE_ExecutionStatus__c = 'Success';
        qleCase.ARC_QLE_RequestPayload__c = '{"alreadyProcessed":true}';
        insert qleCase;

        Test.startTest();
        ARC_SGQLEBaseService.execute(qleCase.Id, 'Awaiting Signature');
        Test.stopTest();

        Case refreshedCase = [
            SELECT Status,
                   ARC_QLE_ExecutionStatus__c,
                   ARC_QLE_RequestPayload__c,
                   ARC_QLE_LastExecutionError__c
            FROM Case
            WHERE Id = :qleCase.Id
            LIMIT 1
        ];

        System.assertEquals('Success', refreshedCase.ARC_QLE_ExecutionStatus__c,
            'Execution status should remain Success.');

        System.assertEquals('{"alreadyProcessed":true}', refreshedCase.ARC_QLE_RequestPayload__c,
            'Payload should remain unchanged.');

        System.assertEquals(null, refreshedCase.ARC_QLE_LastExecutionError__c,
            'No execution error should be generated.');
    }

    @IsTest
    static void testSaveInvalidQLEPayload_marksCaseAsFailed() {
        Case qleCase = createQLECase('Awaiting Signature');
        insert qleCase;

        String invalidPayload = '{"invalid":true}';
        List<String> validationErrors = new List<String>{ 'Missing required QLE fields' };

        Test.startTest();
        Map<String, Object> result = ARC_SGQLEBaseService.saveInvalidQLEPayload(
            qleCase.Id,
            invalidPayload,
            validationErrors
        );
        Test.stopTest();

        System.assertEquals(false, result.get('success'), 'Invalid payload save should return success false.');
        System.assertEquals(qleCase.Id, result.get('caseId'), 'Result should include the Case Id.');

        Case refreshedCase = [
            SELECT ARC_QLE_InvalidPayload__c,
                ARC_QLE_LastExecutionError__c,
                ARC_QLE_ExecutionStatus__c
            FROM Case
            WHERE Id = :qleCase.Id
            LIMIT 1
        ];

        System.assertEquals(invalidPayload, refreshedCase.ARC_QLE_InvalidPayload__c,
            'Invalid payload should be stored on the Case.');

        System.assert(
            refreshedCase.ARC_QLE_LastExecutionError__c != null &&
            refreshedCase.ARC_QLE_LastExecutionError__c.contains('Missing required QLE fields'),
            'Execution error should include the validation error message.'
        );

        System.assertEquals('Failed', refreshedCase.ARC_QLE_ExecutionStatus__c,
            'Execution status should be marked as Failed.');
    }

    @IsTest
    static void testSaveQLERequestSnapshot_nullCaseId_returnsHandledFailure() {
        Test.startTest();
        Map<String, Object> result = ARC_SGQLEBaseService.saveQLERequestSnapshot(null, '{"valid":true}');
        Test.stopTest();

        System.assertEquals(false, result.get('success'),
            'Expected handled failure when Case Id is null. Result=' + String.valueOf(result));
        System.assert(
            String.valueOf(result).contains('Case ID is required'),
            'Handled failure should identify the missing Case Id. Result=' + String.valueOf(result)
        );
    }

    @IsTest
    static void testSaveQLERequestSnapshot_blankPayload_returnsHandledFailure() {
        Case qleCase = createQLECase('Awaiting Signature');
        insert qleCase;

        Test.startTest();
        Map<String, Object> result = ARC_SGQLEBaseService.saveQLERequestSnapshot(qleCase.Id, '');
        Test.stopTest();

        System.assertEquals(false, result.get('success'),
            'Expected handled failure when payload JSON is blank. Result=' + String.valueOf(result));
        System.assert(
            String.valueOf(result).contains('Payload JSON is required'),
            'Handled failure should identify the missing payload JSON. Result=' + String.valueOf(result)
        );
    }

    @IsTest
    static void testSaveQLERequestSnapshot_disallowedStatus_noLongerThrowsStatusException() {
        Case qleCase = createQLECase('New');
        insert qleCase;

        String payloadJson = JSON.serialize(new Map<String, Object>{
            'enrollmentId' => 'TEST-ENROLLMENT-002',
            'traceId' => 'TRACE-002'
        });

        Test.startTest();
        Map<String, Object> result = ARC_SGQLEBaseService.saveQLERequestSnapshot(qleCase.Id, payloadJson);
        Test.stopTest();

        System.assertEquals(false, result.get('success'),
            'Expected handled failure from downstream payload processing, not a thrown status exception. Result=' + String.valueOf(result));
        System.assert(
            !String.valueOf(result).contains('Case must be in an allowed status before saving the QLE snapshot'),
            'The old disallowed-status exception should no longer be returned because the method now normalizes the Case status before validation. Result=' + String.valueOf(result)
        );
    }

    @IsTest
    static void testExecute_withoutPayloadAndWithoutPersonAccount_marksFailed() {
        Case qleCase = createQLECase('Awaiting Signature');
        insert qleCase;

        Test.startTest();
        ARC_SGQLEBaseService.execute(qleCase.Id, 'Awaiting Signature');
        Test.stopTest();

        Case refreshedCase = [
            SELECT Status,
                   ARC_QLE_ExecutionStatus__c,
                   ARC_QLE_LastExecutionError__c
            FROM Case
            WHERE Id = :qleCase.Id
            LIMIT 1
        ];

        System.assertEquals('Awaiting Signature', refreshedCase.Status,
            'Case status should be restored to the old status after execution failure.');

        System.assertEquals('Failed', refreshedCase.ARC_QLE_ExecutionStatus__c,
            'Execution status should be marked as Failed after fallback payload creation fails.');

        System.assert(
            refreshedCase.ARC_QLE_LastExecutionError__c != null &&
            refreshedCase.ARC_QLE_LastExecutionError__c.contains('No valid payload and no ARC_PersonAccount__c on Case to infer QLE context'),
            'Execution error should explain that fallback payload could not be inferred.'
        );
    }

    @IsTest
    static void testProcessSmallGroupQLE_failure_setsOutputError() {
        Case qleCase = createQLECase('Awaiting Signature');
        insert qleCase;

        Map<String, Object> inputMap = new Map<String, Object>{
            'caseId' => qleCase.Id,
            'oldStatus' => 'Awaiting Signature'
        };
        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_SGQLEBaseService.processSmallGroupQLE(inputMap, outputMap);
        Test.stopTest();

        System.assertEquals(true, outputMap.get('success'),
            'processSmallGroupQLE should return success true because execute handles its own exception internally.');

        System.assertEquals(false, outputMap.containsKey('errorMessage'),
            'No output error message should be added when execute handles the exception internally.');

        Case refreshedCase = [
            SELECT Status,
                   ARC_QLE_ExecutionStatus__c,
                   ARC_QLE_LastExecutionError__c
            FROM Case
            WHERE Id = :qleCase.Id
            LIMIT 1
        ];

        System.assertEquals('Awaiting Signature', refreshedCase.Status,
            'Case status should be restored to the old status after execution failure.');

        System.assertEquals('Failed', refreshedCase.ARC_QLE_ExecutionStatus__c,
            'Case should still be marked Failed by execute.');

        System.assert(
            refreshedCase.ARC_QLE_LastExecutionError__c != null &&
            refreshedCase.ARC_QLE_LastExecutionError__c.contains('No valid payload and no ARC_PersonAccount__c on Case to infer QLE context'),
            'Case should store the fallback payload inference error.'
        );
    }

    @IsTest
    static void testInvokeMethod_processSmallGroupQLE_returnsTrue() {
        Case qleCase = createQLECase('Awaiting Signature');
        insert qleCase;

        Map<String, Object> inputMap = new Map<String, Object>{
            'caseId' => qleCase.Id,
            'oldStatus' => 'Awaiting Signature'
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_SGQLEBaseService service = new ARC_SGQLEBaseService();

        Test.startTest();
        Boolean invokeResult = service.invokeMethod(
            'processSmallGroupQLE',
            inputMap,
            outputMap,
            options
        );
        Test.stopTest();

        System.assertEquals(true, invokeResult,
            'invokeMethod should return true for processSmallGroupQLE.');

        System.assertEquals(true, outputMap.get('success'),
            'Output success should be true because execute handles its own exception internally.');

        Case refreshedCase = [
            SELECT Status,
                   ARC_QLE_ExecutionStatus__c,
                   ARC_QLE_LastExecutionError__c
            FROM Case
            WHERE Id = :qleCase.Id
            LIMIT 1
        ];

        System.assertEquals('Awaiting Signature', refreshedCase.Status,
            'Case status should be restored to the old status after execution failure.');

        System.assertEquals('Failed', refreshedCase.ARC_QLE_ExecutionStatus__c,
            'Case should be marked Failed by execute.');

        System.assert(
            refreshedCase.ARC_QLE_LastExecutionError__c != null &&
            refreshedCase.ARC_QLE_LastExecutionError__c.contains('No valid payload and no ARC_PersonAccount__c on Case to infer QLE context'),
            'Case should store the fallback payload inference error.'
        );
    }

    @IsTest
    static void testReprocessQLE_failedCase_returnsFalse() {
        Case qleCase = createQLECase('Awaiting Signature');
        insert qleCase;

        Test.startTest();
        List<ARC_SGQLEBaseService.ReprocessQLEResult> results = ARC_SGQLEBaseService.reprocessQLE(
            new List<Id>{ qleCase.Id }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(),
            'Reprocess should return one result for one Case Id.');

        System.assertEquals(false, results[0].isSuccess,
            'Reprocess result should be false when execute marks the Case as Failed.');

        Case refreshedCase = [
            SELECT Status,
                   ARC_QLE_ExecutionStatus__c,
                   ARC_QLE_LastExecutionError__c
            FROM Case
            WHERE Id = :qleCase.Id
            LIMIT 1
        ];

        System.assertEquals('Failed', refreshedCase.ARC_QLE_ExecutionStatus__c,
            'Case should be marked Failed after reprocess execution.');

        System.assert(
            refreshedCase.ARC_QLE_LastExecutionError__c != null &&
            refreshedCase.ARC_QLE_LastExecutionError__c.contains('No valid payload and no ARC_PersonAccount__c on Case to infer QLE context'),
            'Case should store the fallback payload inference error.'
        );
    }

    @IsTest
    static void testExecute_payloadWithMinimalJson_marksFailedAndRestoresOldStatus() {
        Case qleCase = createQLECase('Awaiting Signature');
        qleCase.ARC_QLE_RequestPayload__c = JSON.serialize(new Map<String, Object>{
            'enrollmentId' => 'TEST-ENROLLMENT-NO-CHANGES',
            'traceId' => 'TRACE-NO-CHANGES',
            'generalInformation' => new Map<String, Object>{
                'effectiveDate' => String.valueOf(Date.today()),
                'qleChanges' => new Map<String, Object>{
                    'noChanges' => true
                }
            },
            'currentState' => new Map<String, Object>{
                'currentPolicy' => new Map<String, Object>{
                    'status' => 'Active',
                    'effectiveDate' => String.valueOf(Date.today())
                },
                'currentProducts' => new Map<String, Object>(),
                'currentMembers' => new List<Object>()
            },
            'members' => new List<Object>()
        });
        insert qleCase;

        Test.startTest();
        ARC_SGQLEBaseService.execute(qleCase.Id, 'Awaiting Signature');
        Test.stopTest();

        Case refreshedCase = [
            SELECT Status,
                   ARC_QLE_ExecutionStatus__c,
                   ARC_QLE_LastExecutionError__c
            FROM Case
            WHERE Id = :qleCase.Id
            LIMIT 1
        ];

        System.assertEquals('Awaiting Signature', refreshedCase.Status,
            'Case status should be restored to the old status when JSON payload processing fails.');

        System.assertEquals('Failed', refreshedCase.ARC_QLE_ExecutionStatus__c,
            'Execution status should be marked as Failed when the minimal JSON payload cannot be processed successfully.');

        System.assert(
            refreshedCase.ARC_QLE_LastExecutionError__c != null &&
            refreshedCase.ARC_QLE_LastExecutionError__c.contains('List has no rows for assignment to SObject'),
            'Execution error should show that getUpgradeDowngradePlans could not find the required matrix setup data.'
        );
    }

    @IsTest
    static void testExecute_fallbackPayloadWithoutPolicy_reachesUpdatedPayloadLogic() {
        Account personAccount = new Account(
            LastName = 'Fallback Test'
        );
        insert personAccount;

        Case qleCase = createQLECase('Awaiting Signature');
        qleCase.ARC_PersonAccount__c = personAccount.Id;
        qleCase.ARC_QLEType__c = 'Marriage';
        qleCase.ARC_QLESubType__c = 'Gain Eligibility';
        qleCase.ARC_QLEEffectiveDate__c = Date.today();
        insert qleCase;

        Test.startTest();
        ARC_SGQLEBaseService.execute(qleCase.Id, 'Awaiting Signature');
        Test.stopTest();

        Case refreshedCase = [
            SELECT Status,
                   ARC_QLE_ExecutionStatus__c,
                   ARC_QLE_LastExecutionError__c
            FROM Case
            WHERE Id = :qleCase.Id
            LIMIT 1
        ];

        System.assertEquals('Closed Approved', refreshedCase.Status,
            'Case status should be Closed Approved when fallback payload processing completes successfully.');

        System.assertEquals('Success', refreshedCase.ARC_QLE_ExecutionStatus__c,
            'Execution status should be marked as Success after fallback payload processing completes successfully.');

        System.assertEquals(null, refreshedCase.ARC_QLE_LastExecutionError__c,
            'Execution error should be cleared after successful fallback payload processing.');
    }

    @IsTest
    static void testExecute_normalQLEPayload_attemptsIntegratedFlowFromBaseService() {
        createUpgradeDowngradeMatrixSetupForIntegrationTest();

        Account personAccount = new Account(
            LastName = 'Integration Flow Test'
        );
        insert personAccount;

        Account groupAccount = new Account(
            Name = 'Integration Flow Group Account'
        );
        insert groupAccount;

        Map<String, Id> integratedFlowRecords = createQLEIntegratedFlowRecords(personAccount.Id, groupAccount.Id);

        Case qleCase = createQLECase('Awaiting Signature');
        qleCase.ARC_PersonAccount__c = personAccount.Id;
        qleCase.ARC_QLEType__c = 'Marriage';
        qleCase.ARC_QLESubType__c = 'Gain Eligibility';
        qleCase.ARC_QLEEffectiveDate__c = Date.today();
        qleCase.ARC_QLE_RequestPayload__c = buildNormalQLEPayloadForIntegrationTest(
            personAccount.Id,
            groupAccount.Id,
            integratedFlowRecords.get('censusId'),
            integratedFlowRecords.get('primaryCensusMemberId'),
            integratedFlowRecords.get('contractId'),
            integratedFlowRecords.get('priorPolicyId'),
            integratedFlowRecords.get('currentProductId'),
            integratedFlowRecords.get('newProductId'),
            Date.today()
        );
        insert qleCase;

        Test.startTest();
        ARC_SGQLEBaseService.execute(qleCase.Id, 'Awaiting Signature');
        Test.stopTest();

        Case refreshedCase = [
            SELECT Status,
                   ARC_QLE_ExecutionStatus__c,
                   ARC_QLE_LastExecutionError__c,
                   ARC_QLE_RequestPayload__c
            FROM Case
            WHERE Id = :qleCase.Id
            LIMIT 1
        ];

        System.assertNotEquals(null, refreshedCase.ARC_QLE_RequestPayload__c,
            'The integration-style QLE payload should remain stored on the Case.');

        System.assertEquals('Success', refreshedCase.ARC_QLE_ExecutionStatus__c,
            'Expected the integration-style QLE payload to complete successfully and continue into the downstream flow. ' +
            'Actual Status=' + refreshedCase.Status +
            ', ExecutionStatus=' + refreshedCase.ARC_QLE_ExecutionStatus__c +
            ', LastExecutionError=' + refreshedCase.ARC_QLE_LastExecutionError__c
        );

        System.assertEquals('Closed Approved', refreshedCase.Status,
            'Case status should be Closed Approved when the integrated flow completes successfully.');

        System.assertEquals(null, refreshedCase.ARC_QLE_LastExecutionError__c,
            'Execution error should be cleared after a successful integrated flow.');
    }
    
    @IsTest
    static void testExecute_reinstatementLikePayload_coversNewEnrollmentAndReinstatementBranches() {
        createUpgradeDowngradeMatrixSetupForIntegrationTest();

        Account personAccount = new Account(
            LastName = 'Reinstatement Flow Test'
        );
        insert personAccount;

        Account groupAccount = new Account(
            Name = 'Reinstatement Flow Group Account'
        );
        insert groupAccount;

        Map<String, Id> newEnrollmentRecords = createQLEIntegratedFlowRecords(personAccount.Id, groupAccount.Id);
        Map<String, Id> reinstatementRecords = createQLEIntegratedFlowRecords(personAccount.Id, groupAccount.Id);

        InsurancePolicy terminatedPolicy = new InsurancePolicy(
            Id = reinstatementRecords.get('priorPolicyId'),
            Status = 'Terminated'
        );
        update terminatedPolicy;

        Case newEnrollmentCase = createQLECase('Awaiting Signature');
        newEnrollmentCase.ARC_PersonAccount__c = personAccount.Id;
        newEnrollmentCase.ARC_QLEType__c = 'Other Coverage';
        newEnrollmentCase.ARC_QLESubType__c = 'Lose Eligibility';
        newEnrollmentCase.ARC_QLEEffectiveDate__c = Date.today();
        newEnrollmentCase.ARC_QLE_RequestPayload__c = buildReinstatementLikeQLEPayloadForIntegrationTest(
            personAccount.Id,
            groupAccount.Id,
            newEnrollmentRecords.get('censusId'),
            newEnrollmentRecords.get('primaryCensusMemberId'),
            newEnrollmentRecords.get('contractId'),
            newEnrollmentRecords.get('priorPolicyId'),
            newEnrollmentRecords.get('currentProductId'),
            newEnrollmentRecords.get('newProductId'),
            Date.today(),
            'Active'
        );
        insert newEnrollmentCase;

        Case reinstatementCase = createQLECase('Awaiting Signature');
        reinstatementCase.ARC_PersonAccount__c = personAccount.Id;
        reinstatementCase.ARC_QLEType__c = 'Other Coverage';
        reinstatementCase.ARC_QLESubType__c = 'Lose Eligibility';
        reinstatementCase.ARC_QLEEffectiveDate__c = Date.today();
        reinstatementCase.ARC_QLE_RequestPayload__c = buildReinstatementLikeQLEPayloadForIntegrationTest(
            personAccount.Id,
            groupAccount.Id,
            reinstatementRecords.get('censusId'),
            reinstatementRecords.get('primaryCensusMemberId'),
            reinstatementRecords.get('contractId'),
            reinstatementRecords.get('priorPolicyId'),
            reinstatementRecords.get('currentProductId'),
            reinstatementRecords.get('newProductId'),
            Date.today(),
            'Terminated'
        );
        insert reinstatementCase;

        Test.startTest();
        ARC_SGQLEBaseService.execute(newEnrollmentCase.Id, 'Awaiting Signature');
        ARC_SGQLEBaseService.execute(reinstatementCase.Id, 'Awaiting Signature');
        Test.stopTest();

        Map<Id, Case> refreshedCases = new Map<Id, Case>([
            SELECT Status,
                   ARC_QLE_ExecutionStatus__c,
                   ARC_QLE_LastExecutionError__c
            FROM Case
            WHERE Id IN :new List<Id>{ newEnrollmentCase.Id, reinstatementCase.Id }
        ]);

        System.assertEquals('Success', refreshedCases.get(newEnrollmentCase.Id).ARC_QLE_ExecutionStatus__c,
            'Expected the reinstatement-like active-policy scenario to complete successfully and cover the new enrollment branch. ' +
            'Actual Status=' + refreshedCases.get(newEnrollmentCase.Id).Status +
            ', ExecutionStatus=' + refreshedCases.get(newEnrollmentCase.Id).ARC_QLE_ExecutionStatus__c +
            ', LastExecutionError=' + refreshedCases.get(newEnrollmentCase.Id).ARC_QLE_LastExecutionError__c
        );

        System.assertEquals('Success', refreshedCases.get(reinstatementCase.Id).ARC_QLE_ExecutionStatus__c,
            'Expected the terminated-policy scenario to complete successfully and cover the reinstatement branch. ' +
            'Actual Status=' + refreshedCases.get(reinstatementCase.Id).Status +
            ', ExecutionStatus=' + refreshedCases.get(reinstatementCase.Id).ARC_QLE_ExecutionStatus__c +
            ', LastExecutionError=' + refreshedCases.get(reinstatementCase.Id).ARC_QLE_LastExecutionError__c
        );
    }

    @IsTest
    static void testMapPolicy_ReinstatementLOA_directCall_coversInvocableMapper() {
        Account personAccount = new Account(
            LastName = 'LOA Reinstatement Test'
        );
        insert personAccount;

        Account groupAccount = new Account(
            Name = 'LOA Reinstatement Group Account'
        );
        insert groupAccount;

        Map<String, Id> integratedFlowRecords = createQLEIntegratedFlowRecords(personAccount.Id, groupAccount.Id);

        InsurancePolicy activatedPolicy = new InsurancePolicy(
            Id = integratedFlowRecords.get('priorPolicyId'),
            Status = 'Activated'
        );
        update activatedPolicy;

        ARC_SGQLEMapper.ReinstatementRequest request = new ARC_SGQLEMapper.ReinstatementRequest();
        request.oldPolicyId = integratedFlowRecords.get('priorPolicyId');
        request.effectiveDate = Date.today();

        Test.startTest();
        List<ARC_SGQLEMapper.ReinstatementResponse> responses = ARC_SGQLEMapper.mapPolicy_ReinstatementLOA(
            new List<ARC_SGQLEMapper.ReinstatementRequest>{ request }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size(),
            'The LOA reinstatement mapper should return one response for one request.');
        System.assertEquals(true, responses[0].isSuccess,
            'The LOA reinstatement mapper should successfully clone the activated policy.');
    }

    /**
     * Test buildTemplateKey method indirectly through getDocuSignTemplates
     * This test covers the buildTemplateKey method by setting up template records
     * and verifying they are correctly identified and used
     */
    /*@IsTest
    static void testBuildTemplateKey_coversBuildTemplateKeyMethod() {
        // Create calculation matrix for evaluateChanges
        createUpgradeDowngradeMatrixSetupForIntegrationTest();
        
        // Create test template records for different sections
        List<ARC_DocuSignCompositeTemplates__c> templates = new List<ARC_DocuSignCompositeTemplates__c>();
        
        // QLE template
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'QLE Template Test',
            ARC_TemplateName__c = 'Test QLE Template',
            ARC_Section__c = 'QLE',
            ARC_BusinessSegment__c = 'SmallGroup'
        ));
        
        // Application Base template
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'App Base Template Test',
            ARC_TemplateName__c = 'Test Application Base',
            ARC_Section__c = 'Application',
            ARC_BusinessSegment__c = 'SmallGroup',
            ARC_ChildOnly__c = false,
            ARC_IsLegacy__c = false,
            ARC_MinDependents__c = 0,
            ARC_MaxDependents__c = 5
        ));
        
        // Application Senior template
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'App Senior Template Test',
            ARC_TemplateName__c = 'Test Application Senior',
            ARC_Section__c = 'Application',
            ARC_BusinessSegment__c = 'SmallGroup',
            ARC_ChildOnly__c = false,
            ARC_IsLegacy__c = true
        ));
        
        // Application ChildOnly template
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'App ChildOnly Template Test',
            ARC_TemplateName__c = 'Test Application ChildOnly',
            ARC_Section__c = 'Application',
            ARC_BusinessSegment__c = 'SmallGroup',
            ARC_ChildOnly__c = true
        ));
        
        // Application 15D template
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'App 15D Template Test',
            ARC_TemplateName__c = 'Test Application 15D',
            ARC_Section__c = 'Application',
            ARC_BusinessSegment__c = 'SmallGroup',
            ARC_ChildOnly__c = false,
            ARC_IsLegacy__c = false,
            ARC_MinDependents__c = 12,
            ARC_MaxDependents__c = 15
        ));
        
        // Authorization template
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'Auth Template Test',
            ARC_TemplateName__c = 'Test Authorization',
            ARC_Section__c = 'Authorization',
            ARC_BusinessSegment__c = 'SmallGroup'
        ));
        
        // Program Premier template
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'Program Premier Template Test',
            ARC_TemplateName__c = 'Test Program Premier',
            ARC_Section__c = 'Program',
            ARC_ProgramType__c = 'Premier'
        ));
        
        // Program Senior template
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'Program Senior Template Test',
            ARC_TemplateName__c = 'Test Program Senior',
            ARC_Section__c = 'Program',
            ARC_ProgramType__c = 'Senior'
        ));
        
        // State CA template
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'State CA Template Test',
            ARC_TemplateName__c = 'Test State CA',
            ARC_Section__c = 'State',
            ARC_State__c = 'CA',
            ARC_BusinessSegment__c = 'SmallGroup'
        ));
        
        // Disclaimer template
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'Disclaimer Template Test',
            ARC_TemplateName__c = 'Test Disclaimer',
            ARC_Section__c = 'Disclaimer',
            ARC_BusinessSegment__c = 'SmallGroup'
        ));
        
        // Beneficiaries template
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'Beneficiaries Template Test',
            ARC_TemplateName__c = 'Test Beneficiaries',
            ARC_Section__c = 'Beneficiaries',
            ARC_ProgramType__c = 'Premier'
        ));
        
        insert templates;
        
        // Create corresponding vlocity templates
        List<vlocity_ins__VlocityDocuSignTemplate__c> vlocityTemplates = new List<vlocity_ins__VlocityDocuSignTemplate__c>();
        for (ARC_DocuSignCompositeTemplates__c t : templates) {
            vlocityTemplates.add(new vlocity_ins__VlocityDocuSignTemplate__c(
                Name = t.ARC_TemplateName__c,
                vlocity_ins__templateidentifier__c = 'VLOCITY_' + t.Name
            ));
        }
        insert vlocityTemplates;
        
        // Create a payload that will exercise buildTemplateKey for various template types
        Map<String, Object> payload = new Map<String, Object>{
            'generalInformation' => new Map<String, Object>{
                'effectiveDate' => String.valueOf(Date.today()),
                'medicalProgram' => new Map<String, Object>{
                    'Test Premier Plan' => new Map<String, Object>{
                        'productId' => 'PROD_PREMIER_001',
                        'contributionAmount' => 100.00,
                        'ARC_PayPeriod__c' => 'Monthly'
                    }
                }
            },
            'members' => new List<Object>{
                new Map<String, Object>{
                    'role' => 'Primary',
                    'productId' => 'PROD_PREMIER_001',
                    'person' => new Map<String, Object>{
                        'firstName' => 'John',
                        'lastName' => 'Doe',
                        'dob' => '1980-01-01',
                        'email' => 'john.doe@test.com',
                        'phone' => '5555555555',
                        'gender' => 'Male',
                        'address' => new Map<String, Object>{
                            'street' => '123 Main St',
                            'city' => 'Los Angeles',
                            'state' => 'CA',
                            'zip' => '90001'
                        }
                    }
                }
            }
        };
        
        Test.startTest();
        ARC_SGQLE_DocuSign docuSignHandler = new ARC_SGQLE_DocuSign();
        docuSignHandler.getDocuSignData(payload);
        Test.stopTest();
        
        // Verify that templates were identified and added
        System.assertNotEquals(null, docuSignHandler.docuSignTemplates,
            'DocuSign templates list should not be null');
        System.assert(docuSignHandler.docuSignTemplates.size() > 0,
            'At least one template should be identified through buildTemplateKey method');
    }*/

    /**
     * Test mapCaliforniaSection method indirectly through mapDocuSignData
     * This test covers California-specific mapping including DOB breakdown and HIPAA list
     */
    @IsTest
    static void testMapCaliforniaSection_coversCaliforniaMappingLogic() {
        // Create calculation matrix for evaluateChanges
        createUpgradeDowngradeMatrixSetupForIntegrationTest();
        
        // Create test templates required for the flow
        List<ARC_DocuSignCompositeTemplates__c> templates = new List<ARC_DocuSignCompositeTemplates__c>();
        
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'QLE Template CA Test',
            ARC_TemplateName__c = 'Test QLE Template CA',
            ARC_Section__c = 'QLE',
            ARC_BusinessSegment__c = 'SmallGroup'
        ));
        
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'State CA Template Test',
            ARC_TemplateName__c = 'Test State CA Template',
            ARC_Section__c = 'State',
            ARC_State__c = 'CA',
            ARC_BusinessSegment__c = 'SmallGroup'
        ));
        
        insert templates;
        
        List<vlocity_ins__VlocityDocuSignTemplate__c> vlocityTemplates = new List<vlocity_ins__VlocityDocuSignTemplate__c>();
        for (ARC_DocuSignCompositeTemplates__c t : templates) {
            vlocityTemplates.add(new vlocity_ins__VlocityDocuSignTemplate__c(
                Name = t.ARC_TemplateName__c,
                vlocity_ins__templateidentifier__c = 'VLOCITY_CA_' + t.Name
            ));
        }
        insert vlocityTemplates;
        
        // Create payload with California address and HIPAA entries
        Map<String, Object> payload = new Map<String, Object>{
            'generalInformation' => new Map<String, Object>{
                'effectiveDate' => String.valueOf(Date.today()),
                'medicalProgram' => new Map<String, Object>{
                    'Test Enhanced Plan' => new Map<String, Object>{
                        'productId' => 'PROD_ENHANCED_CA_001',
                        'contributionAmount' => 150.00,
                        'ARC_PayPeriod__c' => 'Monthly'
                    }
                },
                'hipaa' => new List<Object>{
                    new Map<String, Object>{
                        'firstName' => 'Jane',
                        'lastName' => 'Smith',
                        'relationship' => 'Spouse',
                        'dob' => '1985-06-15'
                    },
                    new Map<String, Object>{
                        'firstName' => 'Tom',
                        'lastName' => 'Johnson',
                        'relationship' => 'Child',
                        'dob' => '2010-03-20'
                    },
                    new Map<String, Object>{
                        'firstName' => 'Alice',
                        'lastName' => 'Doe',
                        'relationship' => 'Primary',
                        'dob' => '1980-12-01'
                    }
                }
            },
            'currentState' => new Map<String, Object>{
                'currentPolicy' => new Map<String, Object>{
                    'status' => 'Active',
                    'effectiveDate' => String.valueOf(Date.today().addMonths(-1))
                },
                'currentProducts' => new Map<String, Object>{
                    'Current Plan' => new Map<String, Object>{
                        'productId' => 'PROD_CURRENT_001'
                    }
                },
                'currentMembers' => new List<Object>()
            },
            'members' => new List<Object>{
                new Map<String, Object>{
                    'role' => 'Primary',
                    'productId' => 'PROD_ENHANCED_CA_001',
                    'person' => new Map<String, Object>{
                        'firstName' => 'Alice',
                        'lastName' => 'Doe',
                        'dob' => '1980-12-01',
                        'email' => 'alice.doe@test.com',
                        'phone' => '5555551234',
                        'gender' => 'Female',
                        'ssn' => '123456789',
                        'address' => new Map<String, Object>{
                            'street' => '456 California Ave',
                            'city' => 'San Francisco',
                            'state' => 'CA',
                            'zip' => '94102'
                        }
                    }
                }
            }
        };
        
        Test.startTest();
        ARC_SGQLE_DocuSign docuSignHandler = new ARC_SGQLE_DocuSign();
        docuSignHandler.getDocuSignData(payload);
        Test.stopTest();
        
        // Verify California-specific tabs were created
        System.assertNotEquals(null, docuSignHandler.tabsMap,
            'Tabs map should not be null');
        
        Map<String, Object> globalTabs = (Map<String, Object>) docuSignHandler.tabsMap.get('global');
        System.assertNotEquals(null, globalTabs,
            'Global tabs should exist');
        
        Map<String, Object> textTabs = (Map<String, Object>) globalTabs.get('textTabs');
        System.assertNotEquals(null, textTabs,
            'Text tabs should exist');
        
        // Verify Primary DOB breakdown (month, day, year)
        System.assert(textTabs.containsKey('Primary.MonthOfBirth'),
            'Primary.MonthOfBirth should be present for CA member');
        System.assertEquals('12', textTabs.get('Primary.MonthOfBirth'),
            'Primary.MonthOfBirth should be correctly extracted');
        
        System.assert(textTabs.containsKey('Primary.DayOfBirth'),
            'Primary.DayOfBirth should be present for CA member');
        System.assertEquals('1', textTabs.get('Primary.DayOfBirth'),
            'Primary.DayOfBirth should be correctly extracted');
        
        System.assert(textTabs.containsKey('Primary.YearOfBirth'),
            'Primary.YearOfBirth should be present for CA member');
        System.assertEquals('1980', textTabs.get('Primary.YearOfBirth'),
            'Primary.YearOfBirth should be correctly extracted');
        
        // Verify HIPAA list (excluding Primary)
        System.assert(textTabs.containsKey('Hipaa1'),
            'Hipaa1 should be present with first non-Primary HIPAA entry');
        System.assertEquals('Jane Smith', textTabs.get('Hipaa1'),
            'Hipaa1 should contain the Spouse name');
        
        System.assert(textTabs.containsKey('Hipaa2'),
            'Hipaa2 should be present with second non-Primary HIPAA entry');
        System.assertEquals('Tom Johnson', textTabs.get('Hipaa2'),
            'Hipaa2 should contain the Child name');
    }

    /**
     * Additional test for buildTemplateKey with Legacy/Senior templates
     */
    @IsTest
    static void testBuildTemplateKey_withLegacySeniorTemplates() {
        // Create calculation matrix for evaluateChanges
        createUpgradeDowngradeMatrixSetupForIntegrationTest();
        
        // Create Legacy/Senior specific templates
        List<ARC_DocuSignCompositeTemplates__c> templates = new List<ARC_DocuSignCompositeTemplates__c>();
        
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'QLE Senior Test',
            ARC_TemplateName__c = 'Test QLE Senior',
            ARC_Section__c = 'QLE',
            ARC_BusinessSegment__c = 'SmallGroup'
        ));
        
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'App Senior Test',
            ARC_TemplateName__c = 'Test App Senior',
            ARC_Section__c = 'Application',
            ARC_BusinessSegment__c = 'SmallGroup',
            ARC_ChildOnly__c = false,
            ARC_IsLegacy__c = true
        ));
        
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'Auth Senior Test',
            ARC_TemplateName__c = 'Test Auth Senior',
            ARC_Section__c = 'Authorization',
            ARC_BusinessSegment__c = 'SmallGroup'
        ));
        
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'Program Senior Test',
            ARC_TemplateName__c = 'Test Program Senior',
            ARC_Section__c = 'Program',
            ARC_ProgramType__c = 'Senior'
        ));
        
        templates.add(new ARC_DocuSignCompositeTemplates__c(
            Name = 'Disclaimer Senior Test',
            ARC_TemplateName__c = 'Test Disclaimer Senior',
            ARC_Section__c = 'Disclaimer',
            ARC_BusinessSegment__c = 'SmallGroup'
        ));
        
        insert templates;
        
        List<vlocity_ins__VlocityDocuSignTemplate__c> vlocityTemplates = new List<vlocity_ins__VlocityDocuSignTemplate__c>();
        for (ARC_DocuSignCompositeTemplates__c t : templates) {
            vlocityTemplates.add(new vlocity_ins__VlocityDocuSignTemplate__c(
                Name = t.ARC_TemplateName__c,
                vlocity_ins__templateidentifier__c = 'VLOCITY_SENIOR_' + t.Name
            ));
        }
        insert vlocityTemplates;
        
        // Create payload with Senior (Legacy) plan
        Map<String, Object> payload = new Map<String, Object>{
            'generalInformation' => new Map<String, Object>{
                'effectiveDate' => String.valueOf(Date.today()),
                'medicalProgram' => new Map<String, Object>{
                    'WeShare Group Senior' => new Map<String, Object>{
                        'productId' => 'PROD_SENIOR_001',
                        'contributionAmount' => 200.00,
                        'ARC_PayPeriod__c' => 'Monthly'
                    }
                }
            },
            'currentState' => new Map<String, Object>{
                'currentPolicy' => new Map<String, Object>{
                    'status' => 'Active'
                },
                'currentProducts' => new Map<String, Object>(),
                'currentMembers' => new List<Object>()
            },
            'members' => new List<Object>{
                new Map<String, Object>{
                    'role' => 'Primary',
                    'productId' => 'PROD_SENIOR_001',
                    'person' => new Map<String, Object>{
                        'firstName' => 'Senior',
                        'lastName' => 'Member',
                        'dob' => '1950-05-15',
                        'email' => 'senior.member@test.com',
                        'phone' => '5555559999',
                        'gender' => 'Male',
                        'MedicareId' => 'MED123456789',
                        'MedicarePartA' => '2020-01-01',
                        'MedicarePartB' => '2020-01-01',
                        'address' => new Map<String, Object>{
                            'street' => '789 Senior Lane',
                            'city' => 'Phoenix',
                            'state' => 'AZ',
                            'zip' => '85001'
                        }
                    }
                }
            }
        };
        
        Test.startTest();
        ARC_SGQLE_DocuSign docuSignHandler = new ARC_SGQLE_DocuSign();
        docuSignHandler.getDocuSignData(payload);
        Test.stopTest();
        
        // Verify Legacy templates were identified
        System.assertNotEquals(null, docuSignHandler.docuSignTemplates,
            'DocuSign templates should be populated for Legacy plan');
        System.assert(docuSignHandler.docuSignTemplates.size() > 0,
            'Legacy templates should be identified through buildTemplateKey');
        
        // Verify Legacy tabs were created
        Map<String, Object> tabsMap = docuSignHandler.tabsMap;
        System.assertNotEquals(null, tabsMap,
            'Tabs map should exist for Legacy member');
        
        List<Object> legacyMembersTabs = (List<Object>) tabsMap.get('legacyMembers');
        System.assertNotEquals(null, legacyMembersTabs,
            'Legacy members tabs should exist');
        System.assertEquals(1, legacyMembersTabs.size(),
            'Should have one Legacy member tab bucket');
    }
}