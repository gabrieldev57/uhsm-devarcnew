@RestResource(urlMapping='/api/v1/small-group-qle/*')
global with sharing class ARC_SGQLEnrollmentEndpoint {
    private static String basePath() { return '/services/apexrest/api/v1/small-group-qle'; }
    private static String pathAfterBase() {
        String uri = RestContext.request.requestURI;
        Integer lastSlash = uri.lastIndexOf('/');
        if (lastSlash != -1 && lastSlash < uri.length() - 1) {
            String pathAfter = uri.substring(lastSlash);
            String route = pathAfter.startsWith('/') ? pathAfter.substring(1) : pathAfter;
            return route;
        }
        return '';
    }

    private static void json(Integer code, Object body) {
        RestResponse res = RestContext.response;
        res.statusCode = code;
        res.addHeader('Content-Type', 'application/json; charset=UTF-8');
        res.responseBody = Blob.valueOf(JSON.serialize(body));
    }

    private static void ok(Object data){ json(200, new Map<String,Object>{ 'status'=>'ok', 'data'=>data }); }
    private static void bad(String msg){ json(400, new Map<String,Object>{ 'status'=>'error', 'message'=>msg }); }
    private static void fail(Exception e){ json(500, new Map<String,Object>{ 'status'=>'error', 'message'=>e.getMessage() }); }

    @HttpGet
    global static void get() {
        try {
            String route = pathAfterBase();

            if (route == 'get-initial-data') {
                Map<String, String> params = RestContext.request.params;
                String caseIdParam = params.get('caseId');
                if (String.isBlank(caseIdParam)) {
                    bad('Case ID (caseId) is required');
                    return;
                }

                Id caseId;
                System.debug('caseId inside get:'+ caseId);
                try {
                    caseId = (Id)caseIdParam;
                } catch (Exception e) {
                    bad('Invalid case ID format');
                    return;
                }

                Case c = getCaseForInitialData(caseId);
                System.debug('Case c:'+c);
                System.debug('Case person account:'+c.ARC_PersonAccount__c);
                System.debug('Case census member:'+c.ARC_PersonAccount__r.Census_Member__c);
                if (c == null || c.ARC_PersonAccount__r.Census_Member__c == null) {
                    System.debug('FULL CASE: ' + JSON.serializePretty(c));
                    bad('Case not found or has no associated census member (ARC_CensusMember__c)');
                    return;
                }
                Id censusMemberId = c.ARC_PersonAccount__r.Census_Member__c;

                Map<String, Object> payload = buildGetInitialDataPayload(c, censusMemberId);
                ok(payload);
                return;
            }
            bad('Unknown GET route');
        } catch (Exception e) { fail(e); }
    }

    @HttpPost
    global static void post() {
        try {
            String route = pathAfterBase();
            Map<String,Object> body = (Map<String,Object>)JSON.deserializeUntyped(RestContext.request.requestBody.toString());
            //Map<String,Object> body = null;

            if (route == 'reprice') {
                if (body == null) {
                    bad('Request body is required');
                    return;
                }
                List<Object> memberDataList = (List<Object>)body.get('memberData');
                if (memberDataList == null || memberDataList.isEmpty()) {
                    bad('memberData array is required in request body');
                    return;
                }

                try {
                    for (Object memberObj : memberDataList) {
                        if (memberObj instanceof Map<String, Object>) {
                            Map<String, Object> memberMap = (Map<String, Object>)memberObj;
                            memberMap.put('useAgeAtEnrollment', true);
                        }
                    }
                    String memberDataJson = JSON.serialize(memberDataList);
                    String productsJson = ARC_getRatedProductsWithContributions.getProductsWithContributionsJsonFromString(memberDataJson);
                    Map<String, Object> productsData = (Map<String, Object>)JSON.deserializeUntyped(productsJson);
                    if (productsData != null && productsData.containsKey('error') && productsData.get('error') != null) {
                        bad((String)productsData.get('error'));
                        return;
                    }
                    ok(new Map<String,Object>{
                        'Status' => '200',
                        'StatusMessage' => 'Products repriced successfully',
                        'products' => productsData
                    });
                    return;
                } catch (Exception e) {
                    ARC_SGQLEHelper.logError('ARC_SGQLEnrollmentEndpoint.reprice', e, JSON.serialize(body));
                    bad('Error repricing products: ' + e.getMessage());
                    return;
                }
            }
            if (route == 'save-qle') {
                if (body == null) {
                    bad('QLE data is required');
                    return;
                }
            
                Map<String, Object> qlePayload = extractQLEPayload(body);
                String caseIdParam = extractCaseId(body);
            
                if (String.isBlank(caseIdParam)) {
                    bad('Case ID (caseId) is required');
                    return;
                }
            
                Id caseId;
                try {
                    caseId = (Id)caseIdParam;
                } catch (Exception e) {
                    bad('Invalid case ID format');
                    return;
                }
            
                DateTime startTime = DateTime.now();
                String logId = ARC_SGQLEHelper.createIntegrationLog('save-qle', qlePayload);
                Map<String, Object> serviceResponse = new Map<String, Object>();
            
                try {
                    Map<String, Object> validation = ARC_SGQLEHelper.validateQLEPayload(qlePayload);
                    List<String> validationErrors = (List<String>)validation.get('errors');
                    Boolean isValid = (Boolean)validation.get('success');
            
                    if (!isValid) {
                        serviceResponse = ARC_SGQLEBaseService.saveInvalidQLEPayload(
                            caseId,
                            JSON.serialize(qlePayload),
                            validationErrors
                        );
            
                        DateTime invalidEndTime = DateTime.now();
                        Long invalidDurationMs = invalidEndTime.getTime() - startTime.getTime();
            
                        ARC_SGQLEHelper.updateIntegrationLog(
                            logId,
                            false,
                            400,
                            'VALIDATION_ERROR',
                            ARC_SGQLEHelper.buildValidationErrorMessage(validationErrors),
                            invalidEndTime,
                            invalidDurationMs,
                            serviceResponse.containsKey('groupAccountId') ? (Id)serviceResponse.get('groupAccountId') : null,
                            serviceResponse.containsKey('groupAccountName') ? (String)serviceResponse.get('groupAccountName') : null
                        );
            
                        RestContext.response.statusCode = 400;
                        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                            'status' => 'error',
                            'message' => 'Validation failed',
                            'errors' => validationErrors
                        }));
                        return;
                    }
            
                    serviceResponse = ARC_SGQLEBaseService.saveQLERequestSnapshot(
                        caseId,
                        JSON.serialize(qlePayload)
                    );
            
                    DateTime endTime = DateTime.now();
                    Long durationMs = endTime.getTime() - startTime.getTime();
            
                    ARC_SGQLEHelper.updateIntegrationLog(
                        logId,
                        true,
                        200,
                        null,
                        null,
                        endTime,
                        durationMs,
                        serviceResponse.containsKey('groupAccountId') ? (Id)serviceResponse.get('groupAccountId') : null,
                        serviceResponse.containsKey('groupAccountName') ? (String)serviceResponse.get('groupAccountName') : null
                    );
            
                    ok(new Map<String, Object>{
                        'Status' => '200',
                        'StatusMessage' => 'QLE snapshot saved successfully.',
                        'caseId' => serviceResponse.get('caseId'),
                        'submittedDateTime' => serviceResponse.get('submittedDateTime'),
                        'caseStatus' => serviceResponse.get('caseStatus')
                    });
                    return;
            
                } catch (Exception e) {
                    DateTime endTime = DateTime.now();
                    Long durationMs = endTime.getTime() - startTime.getTime();
            
                    ARC_SGQLEHelper.updateIntegrationLog(
                        logId,
                        false,
                        500,
                        'SERVICE_ERROR',
                        e.getMessage(),
                        endTime,
                        durationMs,
                        serviceResponse != null && serviceResponse.containsKey('groupAccountId') ? (Id)serviceResponse.get('groupAccountId') : null,
                        serviceResponse != null && serviceResponse.containsKey('groupAccountName') ? (String)serviceResponse.get('groupAccountName') : null
                    );
            
                    fail(e);
                    return;
                }
            }

            bad('Unknown POST route');
        } catch (Exception e) { fail(e); }
    }

    private static Case getCaseForInitialData(Id caseId) {
        System.debug('case id inside getCaseForInitialData:'+ caseId);
        List<Case> cases = [
            SELECT Id,
                   ARC_PersonAccount__c,
                   ARC_PersonAccount__r.Census_Member__c,
                   CreatedDate,
                   ARC_QLEType__c,
                   ARC_QLEEffectiveDate__c,
                   arcsona__EventDate__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        
        System.debug('case inside getCaseForInitialData:'+ cases[0]);
        return cases.isEmpty() ? null : cases[0];
    }

  @TestVisible
    private static Map<String, Object> buildGetInitialDataPayload(Case c, Id primaryCensusMemberId) {
        Map<String, Object> root = new Map<String, Object>();
        root.put('caseId', c.Id);

        root.put('qle', buildQleNode(c));
        root.put('generalInformation', buildGeneralInformation(primaryCensusMemberId));
        root.put('currentState', buildCurrentState(primaryCensusMemberId));

        return root;
    }

    private static Map<String, Object> buildQleNode(Case c) {
        Map<String, Object> qle = new Map<String, Object>();
        qle.put('qleType', c.ARC_QLEType__c);
        qle.put('allowedChanges', null);
        qle.put('eventDate', c.arcsona__EventDate__c);
        qle.put('effectiveDate', c.ARC_QLEEffectiveDate__c);
        qle.put('submittedDateTime', c.CreatedDate != null ? c.CreatedDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') : null);
        return qle;
    }

    private static Map<String, Object> buildGeneralInformation(Id primaryCensusMemberId) {
        Map<String, Object> gi = new Map<String, Object>();
        Account personAccount = getPersonAccountByCensusMember(primaryCensusMemberId);
        if (personAccount == null) {
            return gi;
        }

        gi.put('accountId', personAccount.Id);
        gi.put('censusId', getGroupCensusIdFromCensusMember(primaryCensusMemberId));
        gi.put('groupAccountId', personAccount.ARC_GroupAccount__c);
        gi.put('contractId', null);
        gi.put('primaryCensusMemberId', primaryCensusMemberId);
        gi.put('effectiveDate', null);
        gi.put('medicalProgram', new Map<String, Object>());
        Map<String, Object> guardian = new Map<String, Object>();
        guardian.put('firstName', null);
        guardian.put('middleInitial', null);
        guardian.put('lastName', null);
        guardian.put('dob', null);
        guardian.put('gender', null);
        guardian.put('email', null);
        guardian.put('phone', null);
        guardian.put('ssn', null);
        guardian.put('relationship', null);

        Map<String, Object> guardianAddress = new Map<String, Object>();
        guardianAddress.put('street', null);
        guardianAddress.put('city', null);
        guardianAddress.put('state', null);
        guardianAddress.put('zip', null);
        guardian.put('address', guardianAddress);

        gi.put('guardian', guardian);

        List<Object> hipaaList = new List<Object>();

        Id censusId = getGroupCensusIdFromCensusMember(primaryCensusMemberId);

        if (censusId != null) {
            List<ARC_HipaaAuthorization__c> hipaaRecords = [
                SELECT Id, ARC_AuthorizedMember__r.vlocity_ins__FirstName__c, ARC_AuthorizedMember__r.vlocity_ins__LastName__c, 
                    ARC_AuthorizedMember__r.vlocity_ins__Birthdate__c, ARC_AuthorizedMember__r.Member_ID__c, ARC_AuthorizedMember__r.vlocity_ins__Email__c, 
                    ARC_AuthorizedMember__r.ARC_Phone__c, ARC_AuthorizedMember__r.ARC_Relationship__c, ARC_AuthorizedMember__r.ARC_MiddleInitial__c, 
                    ARC_AuthorizedMember__r.ARC_PhysicalAddressCity__c, ARC_AuthorizedMember__r.ARC_PhysicalAddressState__c, 
                    ARC_AuthorizedMember__r.ARC_PhysicalAddressStreet__c, ARC_AuthorizedMember__r.ARC_PhysicalAddressZipCode__c, 
                    ARC_ExternalPersonAuthorized__r.FirstName, ARC_ExternalPersonAuthorized__r.LastName, ARC_ExternalPersonAuthorized__r.Phone, 
                    ARC_ExternalPersonAuthorized__r.Email, ARC_ExternalPersonAuthorized__r.Birthdate, ARC_ExternalPersonAuthorized__r.vlocity_ins__MiddleName__c, 
                    ARC_ExternalPersonAuthorized__r.MailingAddress, ARC_ExternalPersonAuthorized__r.MailingState, ARC_ExternalPersonAuthorized__r.MailingCity, 
                    ARC_ExternalPersonAuthorized__r.MailingStreet, ARC_ExternalPersonAuthorized__r.MailingPostalCode 
                FROM ARC_HipaaAuthorization__c
                WHERE ARC_Census__r.Id = :censusId
            ];

            for (ARC_HipaaAuthorization__c h : hipaaRecords) {

                // Case 1: Authorized Member
                if (h.ARC_AuthorizedMember__r != null) {
                    Map<String, Object> hipaaNode = new Map<String, Object>();
                    hipaaNode.put('memberExternalId', h.ARC_AuthorizedMember__r.Member_ID__c);
                    hipaaNode.put('CHK_Authorized', null);
                    hipaaNode.put('dob', h.ARC_AuthorizedMember__r.vlocity_ins__Birthdate__c);
                    hipaaNode.put('email', h.ARC_AuthorizedMember__r.vlocity_ins__Email__c);
                    hipaaNode.put('phone', h.ARC_AuthorizedMember__r.ARC_Phone__c);
                    hipaaNode.put('relationship', h.ARC_AuthorizedMember__r.ARC_Relationship__c);
                    hipaaNode.put('middleInitial', h.ARC_AuthorizedMember__r.ARC_MiddleInitial__c);

                    Map<String, Object> address = new Map<String, Object>();
                    address.put('street', h.ARC_AuthorizedMember__r.ARC_PhysicalAddressStreet__c);
                    address.put('city', h.ARC_AuthorizedMember__r.ARC_PhysicalAddressCity__c);
                    address.put('state', h.ARC_AuthorizedMember__r.ARC_PhysicalAddressState__c);
                    address.put('zip', h.ARC_AuthorizedMember__r.ARC_PhysicalAddressZipCode__c);
                    hipaaNode.put('address', address);

                    hipaaNode.put('firstName', h.ARC_AuthorizedMember__r.vlocity_ins__FirstName__c);
                    hipaaNode.put('lastName', h.ARC_AuthorizedMember__r.vlocity_ins__LastName__c);

                    hipaaList.add(hipaaNode);
                }

                // Case 2: External Authorized Person
                if (h.ARC_ExternalPersonAuthorized__r != null) {
                    Map<String, Object> hipaaNode = new Map<String, Object>();
                    hipaaNode.put('memberExternalId', null);
                    hipaaNode.put('CHK_Authorized', null);
                    hipaaNode.put('dob', h.ARC_ExternalPersonAuthorized__r.Birthdate);
                    hipaaNode.put('email', h.ARC_ExternalPersonAuthorized__r.Email);
                    hipaaNode.put('phone', h.ARC_ExternalPersonAuthorized__r.Phone);
                    hipaaNode.put('relationship', null);
                    hipaaNode.put('middleInitial', h.ARC_ExternalPersonAuthorized__r.vlocity_ins__MiddleName__c);

                    Map<String, Object> address = new Map<String, Object>();
                    address.put('street', h.ARC_ExternalPersonAuthorized__r.MailingStreet);
                    address.put('city', h.ARC_ExternalPersonAuthorized__r.MailingCity);
                    address.put('state', h.ARC_ExternalPersonAuthorized__r.MailingState);
                    address.put('zip', h.ARC_ExternalPersonAuthorized__r.MailingPostalCode);
                    hipaaNode.put('address', address);

                    hipaaNode.put('firstName', h.ARC_ExternalPersonAuthorized__r.FirstName);
                    hipaaNode.put('lastName', h.ARC_ExternalPersonAuthorized__r.LastName);

                    hipaaList.add(hipaaNode);
                }
            }
        }

        gi.put('hipaa', hipaaList);
        gi.put('totalMonthlyPremium', null);
        gi.put('signerEmail', personAccount.vlocity_ins__Email__c);

        Id groupAccountId = personAccount.ARC_GroupAccount__c;
        if (groupAccountId != null) {
            Contract cnt = getActiveContractForGroup(groupAccountId);
            if (cnt != null) {
                gi.put('contractId', cnt.Id);
                gi.put('effectiveDate', cnt.ARC_EffectiveDate__c);
            }
        }

        InsurancePolicy pol = getLatestPolicyForPersonAccount(personAccount.Id);
        if (pol != null) {
            gi.put('contractId', pol.ARC_Contract__c != null ? pol.ARC_Contract__c : gi.get('contractId'));
            if (gi.get('effectiveDate') == null && pol.ARC_PolicyEffectiveDate__c != null) {
                gi.put('effectiveDate', pol.ARC_PolicyEffectiveDate__c);
            }
            if (pol.ARC_Guardian__r != null) {
                Map<String, Object> guardianNode = new Map<String, Object>();
                guardianNode.put('firstName', pol.ARC_Guardian__r.FirstName);
                guardianNode.put('middleInitial', pol.ARC_Guardian__r.vlocity_ins__MiddleName__pc);
                guardianNode.put('lastName', pol.ARC_Guardian__r.LastName);
                guardianNode.put('dob', pol.ARC_Guardian__r.PersonBirthdate);
                guardianNode.put('gender', pol.ARC_Guardian__r.PersonGender);
                guardianNode.put('email', pol.ARC_Guardian__r.PersonEmail);
                guardianNode.put('phone', pol.ARC_Guardian__r.Phone);
                guardianNode.put('ssn', pol.ARC_Guardian__r.ARC_SocialSecurityNumber__c);
                guardianNode.put('relationship', pol.ARC_Guardian__r.ARC_GuardianRelationshipToChild__c);

                Map<String, Object> guardianAddressNode = new Map<String, Object>();
                guardianAddressNode.put('street', pol.ARC_Guardian__r.BillingStreet);
                guardianAddressNode.put('city', pol.ARC_Guardian__r.BillingCity);
                guardianAddressNode.put('state', pol.ARC_Guardian__r.BillingState);
                guardianAddressNode.put('zip', pol.ARC_Guardian__r.BillingPostalCode);
                guardianNode.put('address', guardianAddressNode);

                gi.put('guardian', guardianNode);
            }
            Map<String, Object> medicalProgram = buildMedicalProgramFromPolicy(pol);
            if (!medicalProgram.isEmpty()) {
                gi.put('medicalProgram', medicalProgram);
            }
            Decimal totalPremium = pol.EmployeeContribution != null && pol.EmployerContribution != null
                ? pol.EmployeeContribution + pol.EmployerContribution
                : pol.ARC_IndividualPrice__c;
            gi.put('totalMonthlyPremium', totalPremium);
        }

        return gi;
    }

    private static Map<String, Object> buildCurrentState(Id primaryCensusMemberId) {
        Map<String, Object> cs = new Map<String, Object>();
        Account personAccount = getPersonAccountByCensusMember(primaryCensusMemberId);
        if (personAccount == null) {
            cs.put('policy', null);
            cs.put('currentProducts', new Map<String, Object>());
            cs.put('members', new List<Object>());
            return cs;
        }

        InsurancePolicy pol = getLatestPolicyForPersonAccount(personAccount.Id);
        if (pol == null) {
            cs.put('policy', null);
            cs.put('currentProducts', new Map<String, Object>());
            cs.put('members', new List<Object>());
            return cs;
        }

        Map<String, Object> policyNode = new Map<String, Object>();
        policyNode.put('policyId', pol.Id);
        policyNode.put('status', pol.Status);
        policyNode.put('effectiveDate', pol.ARC_PolicyEffectiveDate__c);
        policyNode.put('groupAccountId', pol.ARC_GroupAccount__c);
        policyNode.put('contractId', pol.ARC_Contract__c);
        policyNode.put('employeeAccountId', pol.NameInsuredId);
        cs.put('policy', policyNode);

        Map<String, Object> currentProducts = buildCurrentProductsFromPolicy(pol);
        cs.put('currentProducts', currentProducts);

        List<Object> members = buildMembersFromPolicy(pol);
        cs.put('members', members);

        return cs;
    }

    private static Account getPersonAccountByCensusMember(Id censusMemberId) {
        List<Account> accounts = [
            SELECT Id,
                   FirstName,
                   vlocity_ins__MiddleName__pc,
                   LastName,
                   ARC_GroupAccount__c,
                   vlocity_ins__Email__c,
                   Phone,
                   PersonBirthdate,
                   PersonGender,
                   vlocity_ins__SocialSecurityNumber__pc,
                   BillingStreet,
                   BillingCity,
                   BillingState,
                   BillingPostalCode
            FROM Account
            WHERE Census_Member__c = :censusMemberId
            LIMIT 1
        ];
        return accounts.isEmpty() ? null : accounts[0];
    }

    private static Id getGroupCensusIdFromCensusMember(Id censusMemberId) {
        List<vlocity_ins__GroupCensusMember__c> members = [
            SELECT Id, vlocity_ins__CensusId__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE Id = :censusMemberId
            LIMIT 1
        ];
        return (members.isEmpty() || members[0].vlocity_ins__CensusId__c == null)
            ? null
            : members[0].vlocity_ins__CensusId__c;
    }

    private static Contract getActiveContractForGroup(Id groupAccountId) {
        List<Contract> contracts = [
            SELECT Id, ARC_EffectiveDate__c
            FROM Contract
            WHERE AccountId = :groupAccountId
            AND (Status = 'Enrollment In Progress' OR Status = 'Activated')
            LIMIT 1
        ];
        return contracts.isEmpty() ? null : contracts[0];
    }

    private static InsurancePolicy getLatestPolicyForPersonAccount(Id personAccountId) {
        List<InsurancePolicy> policies = [
            SELECT Id,
                   Status,
                   ARC_PolicyEffectiveDate__c,
                   ARC_GroupAccount__c,
                   ARC_Contract__c,
                   NameInsuredId,
                   EmployeeContribution,
                   EmployerContribution,
                   ARC_IndividualPrice__c,
                   ARC_DependentPrice__c,
                   ARC_JsonSESG__c,
                   ARC_Guardian__r.FirstName,
                   ARC_Guardian__r.LastName,
                   ARC_Guardian__r.PersonBirthdate,
                   ARC_Guardian__r.PersonEmail,
                   ARC_Guardian__r.Phone,
                   ARC_Guardian__r.PersonGender,
                   ARC_Guardian__r.vlocity_ins__MiddleName__pc,
                   ARC_Guardian__r.ARC_SocialSecurityNumber__c,
                   ARC_Guardian__r.ARC_GuardianRelationshipToChild__c,
                   ARC_Guardian__r.BillingStreet,
                   ARC_Guardian__r.BillingCity,
                   ARC_Guardian__r.BillingState,
                   ARC_Guardian__r.BillingPostalCode,
                   (SELECT Id, Role, PrimaryParticipantContactId FROM InsurancePolicyParticipants),
                   (SELECT Id, CoverageName, vlocity_ins_fsc__Product2Id__c, ARC_UnitPrice__c, ARC_ParentPolicyCoverage__c FROM InsurancePolicyCoverages)
            FROM InsurancePolicy
            WHERE NameInsuredId = :personAccountId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return policies.isEmpty() ? null : policies[0];
    }

    private static Map<String, Object> buildMedicalProgramFromPolicy(InsurancePolicy pol) {
        Map<String, Object> medicalProgram = new Map<String, Object>();
        if (pol.InsurancePolicyCoverages == null) {
            return medicalProgram;
        }
        for (InsurancePolicyCoverage cov : pol.InsurancePolicyCoverages) {
            if (cov.ARC_ParentPolicyCoverage__c != null) {
                continue;
            }
            String key = cov.CoverageName;
            if (String.isBlank(key)) {
                continue;
            }
            Map<String, Object> prog = new Map<String, Object>();
            prog.put('productId', cov.vlocity_ins_fsc__Product2Id__c);
            prog.put('basePrice', cov.ARC_UnitPrice__c);
            prog.put('priceWithContributions', cov.ARC_UnitPrice__c);
            prog.put('individualPrice', pol.ARC_IndividualPrice__c);
            prog.put('tierFactorValue', 1);
            prog.put('contributionType', 'Amount');
            prog.put('contributionAmount', pol.EmployeeContribution != null ? pol.EmployeeContribution : 0);
            prog.put('employeeSplit', pol.EmployeeContribution);
            prog.put('employerSplit', pol.EmployerContribution);
            prog.put('ARC_PayPeriod__c', extractPayPeriodFromPolicyJson(pol, key));
            medicalProgram.put(key, prog);
        }
        return medicalProgram;
    }

    private static String extractPayPeriodFromPolicyJson(InsurancePolicy pol, String coverageKey) {
        if (String.isBlank(pol.ARC_JsonSESG__c)) {
            return null;
        }
        try {
            Map<String, Object> seJson = (Map<String, Object>)JSON.deserializeUntyped(pol.ARC_JsonSESG__c);
            Map<String, Object> gi = (Map<String, Object>)seJson.get('generalInformation');
            if (gi == null || !gi.containsKey('medicalProgram')) {
                return null;
            }

            Object medObj = gi.get('medicalProgram');
            if (medObj == null) {
                return null;
            }

            // CASE 1: medicalProgram is a MAP (original logic)
            if (medObj instanceof Map<String, Object>) {
                Map<String, Object> med = (Map<String, Object>)medObj;

                if (String.isNotBlank(coverageKey) && med.containsKey(coverageKey)) {
                    Map<String, Object> prog = (Map<String, Object>)med.get(coverageKey);
                    return prog != null && prog.containsKey('ARC_PayPeriod__c')
                        ? (String)prog.get('ARC_PayPeriod__c')
                        : null;
                }

                for (Object v : med.values()) {
                    if (v instanceof Map<String, Object>) {
                        Map<String, Object> p = (Map<String, Object>)v;
                        if (p.containsKey('ARC_PayPeriod__c') && p.get('ARC_PayPeriod__c') != null) {
                            return (String)p.get('ARC_PayPeriod__c');
                        }
                    }
                }
            }

            // CASE 2: medicalProgram is a LIST
            if (medObj instanceof List<Object>) {
                List<Object> medList = (List<Object>)medObj;

                for (Object item : medList) {
                    if (item instanceof Map<String, Object>) {
                        Map<String, Object> prog = (Map<String, Object>)item;

                        // Try match by name if coverageKey is provided
                        if (String.isNotBlank(coverageKey) && prog.containsKey('name')) {
                            String name = (String)prog.get('name');
                            if (name == coverageKey && prog.containsKey('ARC_PayPeriod__c')) {
                                return (String)prog.get('ARC_PayPeriod__c');
                            }
                        }

                        // fallback: first available value
                        if (prog.containsKey('ARC_PayPeriod__c') && prog.get('ARC_PayPeriod__c') != null) {
                            return (String)prog.get('ARC_PayPeriod__c');
                        }
                    }
                }
            }
        } catch (Exception e) {
            // ignore
        }
        return null;
    }

    
    @TestVisible
    private static Map<String, Object> buildCurrentProductsFromPolicy(InsurancePolicy pol) {
        Map<String, Object> products = new Map<String, Object>();
        if (pol.InsurancePolicyCoverages == null) {
            return products;
        }
        for (InsurancePolicyCoverage cov : pol.InsurancePolicyCoverages) {
            if (cov.ARC_ParentPolicyCoverage__c != null) {
                continue;
            }
            String key = cov.CoverageName;
            if (String.isBlank(key)) {
                continue;
            }
            Map<String, Object> p = new Map<String, Object>();
            p.put('productId', cov.vlocity_ins_fsc__Product2Id__c);
            p.put('basePrice', cov.ARC_UnitPrice__c);
            p.put('employeeSplit', pol.EmployeeContribution);
            p.put('employerSplit', pol.EmployerContribution);
            p.put('ARC_PayPeriod__c', extractPayPeriodFromPolicyJson(pol, key));
            products.put(key, p);
        }
        return products;
    }

    private static List<Object> buildMembersFromPolicy(InsurancePolicy pol) {
        List<Object> members = new List<Object>();
        if (pol.InsurancePolicyParticipants == null || pol.InsurancePolicyParticipants.isEmpty()) {
            return members;
        }

        Set<Id> contactIds = new Set<Id>();
        for (InsurancePolicyParticipant p : pol.InsurancePolicyParticipants) {
            if (p.PrimaryParticipantContactId != null) {
                contactIds.add(p.PrimaryParticipantContactId);
            }
        }
        if (contactIds.isEmpty()) {
            return members;
        }

        Map<Id, Contact> contactsById = new Map<Id, Contact>();
        for (Contact ct : [SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds]) {
            contactsById.put(ct.Id, ct);
        }

        Set<Id> accountIds = new Set<Id>();
        for (Contact ct : contactsById.values()) {
            if (ct.AccountId != null) {
                accountIds.add(ct.AccountId);
            }
        }
        if (accountIds.isEmpty()) {
            return members;
        }

        Map<Id, Account> accountsById = new Map<Id, Account>();
        Map<Id, Id> accountToCensus = new Map<Id, Id>();
        for (Account acc : [
            SELECT Id, FirstName, vlocity_ins__MiddleName__pc, LastName, PersonBirthdate, PersonGender,
                   vlocity_ins__Email__c, Phone, Census_Member__c, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                   vlocity_ins__SocialSecurityNumber__pc
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            accountsById.put(acc.Id, acc);
            if (acc.Census_Member__c != null) {
                accountToCensus.put(acc.Id, acc.Census_Member__c);
            }
        }

        Set<Id> censusIds = new Set<Id>(accountToCensus.values());
        Map<Id, vlocity_ins__GroupCensusMember__c> censusById = new Map<Id, vlocity_ins__GroupCensusMember__c>();
        if (!censusIds.isEmpty()) {
            for (vlocity_ins__GroupCensusMember__c cm : [
                SELECT Id, vlocity_ins__IsPrimaryMember__c, ARC_DependentRelationship__c
                FROM vlocity_ins__GroupCensusMember__c
                WHERE Id IN :censusIds
            ]) {
                censusById.put(cm.Id, cm);
            }
        }

        Id primaryProductId = null;
        if (pol.InsurancePolicyCoverages != null && !pol.InsurancePolicyCoverages.isEmpty()) {
            for (InsurancePolicyCoverage cov : pol.InsurancePolicyCoverages) {
                if (cov.ARC_ParentPolicyCoverage__c == null && cov.vlocity_ins_fsc__Product2Id__c != null) {
                    primaryProductId = cov.vlocity_ins_fsc__Product2Id__c;
                    break;
                }
            }
        }

        for (InsurancePolicyParticipant p : pol.InsurancePolicyParticipants) {
            Contact ct = contactsById.get(p.PrimaryParticipantContactId);
            if (ct == null) {
                continue;
            }
            Account acc = accountsById.get(ct.AccountId);
            if (acc == null) {
                continue;
            }
            Id censusId = accountToCensus.get(acc.Id);
            vlocity_ins__GroupCensusMember__c cm = censusId != null ? censusById.get(censusId) : null;

            String role = p.Role != null ? p.Role : (cm != null && cm.vlocity_ins__IsPrimaryMember__c ? 'Primary' : 'Dependent');

            Map<String, Object> memberNode = new Map<String, Object>();
            memberNode.put('memberExternalId', censusId != null ? String.valueOf(censusId) : String.valueOf(acc.Id));
            memberNode.put('productId', primaryProductId);
            memberNode.put('role', role);
            if (role == 'Dependent' && cm != null && String.isNotBlank(cm.ARC_DependentRelationship__c)) {
                memberNode.put('relationshipToPrimary', cm.ARC_DependentRelationship__c);
            }

            Map<String, Object> existingRef = new Map<String, Object>();
            existingRef.put('censusMemberId', censusId);
            existingRef.put('personAccountId', acc.Id);
            existingRef.put('policyParticipantId', p.Id);
            memberNode.put('existingMemberRef', existingRef);

            Map<String, Object> personNode = new Map<String, Object>();
            personNode.put('isLegacy', false);
            personNode.put('firstName', acc.FirstName);
            personNode.put('middleInitial', acc.vlocity_ins__MiddleName__pc != null ? acc.vlocity_ins__MiddleName__pc : '');
            personNode.put('lastName', acc.LastName);
            personNode.put('dob', acc.PersonBirthdate);
            personNode.put('gender', acc.PersonGender);
            personNode.put('email', acc.vlocity_ins__Email__c);
            personNode.put('phone', acc.Phone);
            personNode.put('ssn', acc.vlocity_ins__SocialSecurityNumber__pc != null ? String.valueOf(acc.vlocity_ins__SocialSecurityNumber__pc) : null);
            personNode.put('sameAddressAsPrimary', role != 'Primary');
            if (acc.BillingStreet != null || acc.BillingCity != null || acc.BillingState != null || acc.BillingPostalCode != null) {
                Map<String, Object> addr = new Map<String, Object>();
                addr.put('street', acc.BillingStreet);
                addr.put('city', acc.BillingCity);
                addr.put('state', acc.BillingState);
                addr.put('zip', acc.BillingPostalCode);
                personNode.put('address', addr);
            }
            memberNode.put('person', personNode);
            members.add(memberNode);
        }

        return members;
    }

    private static Map<String, Object> extractQLEPayload(Map<String, Object> body) {
        if (body == null) {
            return null;
        }
        if (body.containsKey('payload') && body.get('payload') instanceof Map<String, Object>) {
            return (Map<String, Object>)body.get('payload');
        }
        return body;
    }
    
    private static String extractCaseId(Map<String, Object> body) {
        if (body != null && body.containsKey('caseId') && body.get('caseId') != null) {
            return String.valueOf(body.get('caseId'));
        }
        Map<String, String> params = RestContext.request.params;
        return params != null ? params.get('caseId') : null;
    }
}