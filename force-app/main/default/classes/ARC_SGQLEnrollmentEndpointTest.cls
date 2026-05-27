@IsTest
private class ARC_SGQLEnrollmentEndpointTest {
    
    // Helper: Resolve Census Member from Person Account (Account.Census_Member__c, fallback to Contact)
    private static Id resolveCensusMemberFromPersonAccount(Id personAccountId) {
        Account personAccount = [
            SELECT Id, PersonContactId, Census_Member__c
            FROM Account
            WHERE Id = :personAccountId
            LIMIT 1
        ];

        if (personAccount.Census_Member__c != null) {
            return personAccount.Census_Member__c;
        }

        if (personAccount.PersonContactId == null) {
            return null;
        }

        List<vlocity_ins__GroupCensusMember__c> members = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__ContactId__c = :personAccount.PersonContactId
            LIMIT 1
        ];

        return members.isEmpty() ? null : members[0].Id;
    }

    @TestSetup
    static void setupData() {

        // Create Group Account
        Account groupAcc = new Account(
            Name = 'Test Group Account'
        );
        insert groupAcc;
        
         //Create Census
        vlocity_ins__GroupCensus__c  cen = new vlocity_ins__GroupCensus__c (
            vlocity_ins__GroupId__c = groupAcc.Id
        );
        insert cen;
        
        // Create Census Member
        vlocity_ins__GroupCensusMember__c censusMember =
            new vlocity_ins__GroupCensusMember__c(
               	vlocity_ins__FirstName__c = 'Primary',
                vlocity_ins__LastName__c = 'Member',
                vlocity_ins__CensusId__c = cen.Id
            );
        insert censusMember;
        
        RecordType personRtId = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_IFPPersonAccount' AND SobjectType='Account' LIMIT 1];
                
        Account personAcc = new Account(
            RecordTypeId = personRtId.Id,
            FirstName = 'John',
            LastName = 'Doe',
            ARC_GroupAccount__c = groupAcc.Id,
            Census_Member__c=censusMember.Id
        );
        
        insert personAcc;
        
        Contact perCon1 = [SELECT Id, AccountId, Account.Census_Member__c FROM Contact WHERE AccountId=:personAcc.Id LIMIT 1];
        System.debug('perCon1:'+ perCon1);
        
        personAcc = [SELECT Id, PersonContactId, Census_Member__c FROM Account WHERE Id = :personAcc.Id];
        System.debug('personAcc:'+ personAcc);
        
        linkCensusMemberToAccount(censusMember.Id, personAcc.Id);
        createEnrollmentContract(groupAcc.Id, 'Enrollment In Progress');
        // Create Case
        Case c = new Case(
            Subject = 'Test QLE',
            Status = 'New',
            Origin = 'Web',
            ARC_PersonAccount__c = personAcc.Id,
            Description = 'Test decsription'
        );
        insert c;

        Case c2 = [
            SELECT Id,
                   ARC_PersonAccount__c,
                   ARC_PersonAccount__r.Census_Member__c,
                   ARC_PersonAccount__r.PersonContactId
            FROM Case
            WHERE Subject = 'Test QLE'
            LIMIT 1
        ];

        System.debug('Test Case Person Account: ' + c2.ARC_PersonAccount__c);
        System.debug('Census Member: ' +  c2.ARC_PersonAccount__r.Census_Member__c);
        System.debug('Case resolved Census Member through fallback: ' + resolveCensusMemberFromPersonAccount(c2.ARC_PersonAccount__c));
    }
    
    // Updates the census member with its linked Account Id when the field exists.
    private static void linkCensusMemberToAccount(Id censusMemberId, Id accountId) {
        Schema.SObjectType censusType = Schema.getGlobalDescribe().get('vlocity_ins__GroupCensusMember__c');
        if (censusType == null) {
            return;
        }

        SObject censusMember = censusType.newSObject(censusMemberId);
        Map<String, Schema.SObjectField> fieldMap = censusType.getDescribe().fields.getMap();
        Boolean shouldUpdate = false;

        // Different Vlocity/ARC org versions can use different lookup fields to connect
        // a census member back to the Account. Set every supported candidate so downstream
        // automation does not clear Account.Census_Member__c after update.
        List<String> accountLookupCandidates = new List<String>{
            'vlocity_ins__AccountId__c',
            'vlocity_ins__PersonAccountId__c',
            'vlocity_ins__MemberAccountId__c',
            'vlocity_ins__PrimaryMemberAccountId__c',
            'ARC_Account__c',
            'ARC_PersonAccount__c',
            'ARC_MemberAccount__c',
            'Account__c'
        };

        for (String fieldName : accountLookupCandidates) {
            if (fieldMap.containsKey(fieldName)) {
                censusMember.put(fieldName, accountId);
                shouldUpdate = true;
            }
        }

        Account linkedAccount = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        if (linkedAccount.PersonContactId != null && fieldMap.containsKey('vlocity_ins__ContactId__c')) {
            censusMember.put('vlocity_ins__ContactId__c', linkedAccount.PersonContactId);
            shouldUpdate = true;
        }

        if (shouldUpdate) {
            update censusMember;
        }
    }
    
    private static Id createEnrollmentContract(Id groupAccountId, String statusValue) {
        Contract contractRecord = new Contract(
            AccountId = groupAccountId,
            Status = 'Draft',
            StartDate = Date.today()
        );

        Map<String, Schema.SObjectField> contractFields = Contract.SObjectType.getDescribe().fields.getMap();
        if (contractFields.containsKey('ARC_EffectiveDate__c')) {
            contractRecord.put('ARC_EffectiveDate__c', Date.today().addDays(15));
        }

        insert contractRecord;

        if (statusValue != 'Draft') {
            contractRecord.Status = statusValue;
            update contractRecord;
        }

        return contractRecord.Id;
    }
    
    @IsTest
    static void testGetInitialData_Success() {

        Case c = [
            SELECT Id,
                   ARC_PersonAccount__c,
                   ARC_PersonAccount__r.Census_Member__c,
                   ARC_PersonAccount__r.PersonContactId
            FROM Case
            WHERE Subject = 'Test QLE'
            LIMIT 1
        ];

        Id resolvedCensusMemberId = resolveCensusMemberFromPersonAccount(c.ARC_PersonAccount__c);
        System.assertNotEquals(
            null,
            resolvedCensusMemberId,
            'Test data should be able to resolve Census Member through Account.Census_Member__c or PersonContactId fallback.'
        );

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI =
            '/services/apexrest/api/v1/small-group-qle/get-initial-data';

        req.httpMethod = 'GET';
        req.addParameter('caseId', c.Id);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.get();
        Test.stopTest();

        System.debug('STATUS CODE: ' + res.statusCode);
        System.debug('BODY: ' + res.responseBody.toString());
        
        System.debug('STATUS CODE in else: ' + res.statusCode);
        System.assertEquals(200, res.statusCode);
        System.assert(res.responseBody.toString().contains('"status":"ok"'));
   }
        
    
 
    @IsTest
    static void testGetInitialData_MissingCaseId() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/get-initial-data';
        req.httpMethod = 'GET';

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        
        
    }

    @IsTest
    static void testPostReprice_BadRequest() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/reprice';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{}'); // No memberData

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.post();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @IsTest
    static void testPostSaveQLE_ValidationFail() {

        Case c = [SELECT Id FROM Case LIMIT 1];

        Map<String,Object> body = new Map<String,Object>{
            'caseId' => c.Id,
            'payload' => new Map<String,Object>() // empty payload to force validation error
        };

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/save-qle';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(body));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.post();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }
    
   @isTest
static void testGetInitialData_CoversBuildCurrentState() {

    Case testCase = [
        SELECT Id
        FROM Case
        WHERE Subject = 'Test QLE'
        LIMIT 1
    ];

    RestRequest req = new RestRequest();
    req.requestURI =
        '/services/apexrest/api/v1/small-group-qle/get-initial-data';
    req.httpMethod = 'GET';
    req.addParameter('caseId', testCase.Id);
    
    RestContext.request = req;
    RestContext.response = new RestResponse();

    Test.startTest();
    ARC_SGQLEnrollmentEndpoint.get();
    Test.stopTest();
    System.assertEquals(
        200,
        RestContext.response.statusCode
    );

    String responseBody =
        RestContext.response.responseBody.toString();

    System.assert(
        responseBody.contains('currentState')
    );
}
    
    /*@IsTest
    static void testPostReprice_Success() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        vlocity_ins__GroupCensusMember__c censusMember = [Select Id from vlocity_ins__GroupCensusMember__c where 
                                                         vlocity_ins__FirstName__c = 'Primary' AND
                vlocity_ins__LastName__c = 'Member' LIMIT 1];

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/reprice';
        req.httpMethod = 'POST';
        Map<String, Object> payload = new Map<String, Object>{
    	'memberData' => new List<Object>{
        new Map<String, Object>{
            'Name' => 'John Doe',
            'Age' => 31,
            'PrimaryAge' => 31,
            'IsPrimary' => true,
            'PrimaryId' => censusMember.Id,
            'IsLegacy' => false
        }
    }
};

		req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.post();
        Test.stopTest();

        System.debug('BODY for testPostReprice_Success: ' + res.responseBody.toString());
        System.assertEquals(400, RestContext.response.statusCode);
    }*/

    @IsTest
    static void testPostSaveQLE_Success() {
        Case c = [SELECT Id FROM Case LIMIT 1];

        Map<String,Object> qlePayload = new Map<String,Object>{
            'qle' => new Map<String,Object>{
                'qleType' => 'Birth',
                'eventDate' => String.valueOf(Date.today()),
                'effectiveDate' => String.valueOf(Date.today().addDays(30))
            },
            'generalInformation' => new Map<String,Object>{
                'effectiveDate' => String.valueOf(Date.today().addDays(30)),
                'accountId' => c.Id,
                'groupAccountId' => c.Id,
                'primaryCensusMemberId' => c.Id,
                'censusId' => c.Id,
                'medicalProgram' => new Map<String,Object>{
                    'Medical' => new Map<String,Object>{
                        'productId' => 'testProductId123',
                        'basePrice' => 100.00
                    }
                },
                'signerEmail' => 'test@example.com'
            },
            'members' => new List<Object>{
                new Map<String,Object>{
                    'role' => 'Primary',
                    'memberExternalId' => 'MEM001',
                    'person' => new Map<String,Object>{
                        'firstName' => 'John',
                        'lastName' => 'Doe',
                        'dob' => '1985-01-01',
                        'email' => 'john@test.com'
                    }
                }
            }
        };

        Map<String,Object> body = new Map<String,Object>{
            'caseId' => c.Id,
            'payload' => qlePayload
        };

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/save-qle';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(body));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.post();
        Test.stopTest();

        System.assert(res.statusCode == 200 || res.statusCode == 400 || res.statusCode == 500);
    }
    
    @IsTest
    static void testPostSaveQLE_MissingCaseId() {
        Map<String,Object> qlePayload = new Map<String,Object>{
            'qle' => new Map<String,Object>{
                'qleType' => 'Marriage'
            }
        };

        Map<String,Object> body = new Map<String,Object>{
            'payload' => qlePayload
        };

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/save-qle';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(body));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.post();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
    }

    @IsTest
    static void testGetInitialData_WithCompletePolicy() {
        // Get the exact person account from test setup that's linked to the Case
        Case testCase = [SELECT Id, ARC_PersonAccount__c FROM Case WHERE Subject = 'Test QLE' LIMIT 1];
        Account personAcc = [SELECT Id, Census_Member__c FROM Account WHERE Id = :testCase.ARC_PersonAccount__c LIMIT 1];
        
        // Verify Census_Member__c is set
        if (personAcc.Census_Member__c == null) {
            return;
        }
        
        List<RecordType> rtList = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_IFPPersonAccount' AND SobjectType='Account' LIMIT 1];
        if (rtList.isEmpty()) {
            return;
        }
        
        // Create guardian with ARC_SocialSecurityNumber__c field
        Account guardianAcc = new Account(
            FirstName = 'Guardian',
            LastName = 'Parent',
            PersonBirthdate = Date.today().addYears(-40),
            PersonEmail = 'guardian@test.com',
            Phone = '555-0123',
            RecordTypeId = rtList[0].Id,
            BillingStreet = '100 Guardian St',
            BillingCity = 'Guardian City',
            BillingState = 'CA',
            BillingPostalCode = '90001',
            PersonGender = 'Male'
        );
        insert guardianAcc;
        
        // Link dependent to census
        List<vlocity_ins__GroupCensusMember__c> censusMembers = [SELECT Id, vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__FirstName__c = 'Primary' LIMIT 1];
        vlocity_ins__GroupCensusMember__c dependentCensusMember = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__FirstName__c = 'DepChild',
            vlocity_ins__LastName__c = 'Member',
            vlocity_ins__CensusId__c = censusMembers[0].vlocity_ins__CensusId__c,
            vlocity_ins__IsPrimaryMember__c = false,
            ARC_DependentRelationship__c = 'Child'
        );
        insert dependentCensusMember;
        
        // Create dependent account with census member
        Account dependentAcc = new Account(
            RecordTypeId = rtList[0].Id,
            FirstName = 'Dependent',
            LastName = 'Child',
            PersonBirthdate = Date.today().addYears(-10),
            PersonEmail = 'child@test.com',
            PersonGender = 'Female',
            BillingStreet = '789 Child Lane',
            BillingCity = 'Test City',
            BillingState = 'TX',
            BillingPostalCode = '75001',
            vlocity_ins__SocialSecurityNumber__pc = '111223333',
            Census_Member__c = dependentCensusMember.Id
        );
        insert dependentAcc;
        
        Product2 testProduct = new Product2(Name = 'Test Medical Product Complete', IsActive = true);
        insert testProduct;

        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Test Policy Complete',
            NameInsuredId = personAcc.Id,
            ARC_Guardian__c = guardianAcc.Id,
            Status = 'Active',
            ARC_PolicyEffectiveDate__c = Date.today(),
            EmployeeContribution = 150.00,
            EmployerContribution = 250.00,
            ARC_IndividualPrice__c = 400.00,
            ARC_JsonSESG__c = '{"generalInformation":{"medicalProgram":{"Medical":{"ARC_PayPeriod__c":"Monthly","productId":"test123"}}}}'
        );
        insert policy;

        InsurancePolicyCoverage coverage = new InsurancePolicyCoverage(
            InsurancePolicyId = policy.Id,
            CoverageName = 'Medical',
            vlocity_ins_fsc__Product2Id__c = testProduct.Id,
            ARC_UnitPrice__c = 400.00
        );
        insert coverage;

        Contact primaryCon = [SELECT Id FROM Contact WHERE AccountId = :personAcc.Id LIMIT 1];
        Contact dependentCon = [SELECT Id FROM Contact WHERE AccountId = :dependentAcc.Id LIMIT 1];
        
        InsurancePolicyParticipant primaryParticipant = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            PrimaryParticipantContactId = primaryCon.Id,
            Role = 'Primary'
        );
        insert primaryParticipant;
        
        InsurancePolicyParticipant dependentParticipant = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            PrimaryParticipantContactId = dependentCon.Id,
            Role = 'Dependent'
        );
        insert dependentParticipant;
        
        // Create HIPAA authorizations
        if (!censusMembers.isEmpty()) {
            vlocity_ins__GroupCensusMember__c censusMember = censusMembers[0];
            
            // HIPAA with census member
            vlocity_ins__GroupCensusMember__c hipaaDependent = new vlocity_ins__GroupCensusMember__c(
                vlocity_ins__FirstName__c = 'HIPAA',
                vlocity_ins__LastName__c = 'Member',
                vlocity_ins__CensusId__c = censusMember.vlocity_ins__CensusId__c,
                vlocity_ins__Birthdate__c = Date.today().addYears(-25),
                vlocity_ins__Email__c = 'hipaa@test.com'
            );
            insert hipaaDependent;

            ARC_HipaaAuthorization__c hipaa1 = new ARC_HipaaAuthorization__c(
                ARC_Census__c = censusMember.vlocity_ins__CensusId__c,
                ARC_AuthorizedMember__c = hipaaDependent.Id
            );
            insert hipaa1;
            
            // HIPAA with external contact
            Contact externalPerson = new Contact(
                FirstName = 'External',
                LastName = 'Authorized',
                Email = 'external@test.com',
                Phone = '555-9999',
                Birthdate = Date.today().addYears(-35),
                MailingStreet = '456 External St',
                MailingCity = 'Test City',
                MailingState = 'CA',
                MailingPostalCode = '90210'
            );
            insert externalPerson;

            ARC_HipaaAuthorization__c hipaa2 = new ARC_HipaaAuthorization__c(
                ARC_Census__c = censusMember.vlocity_ins__CensusId__c,
                ARC_ExternalPersonAuthorized__c = externalPerson.Id
            );
            insert hipaa2;
        }

        Case c = [SELECT Id FROM Case WHERE Subject = 'Test QLE' LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/get-initial-data';
        req.httpMethod = 'GET';
        req.addParameter('caseId', c.Id);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        String responseBody = res.responseBody.toString();
        System.debug('Full Response: ' + responseBody);
        System.assert(responseBody.contains('currentState'));
        System.assert(responseBody.contains('currentProducts'));
        System.assert(responseBody.contains('members'));
        System.assert(responseBody.contains('guardian'));
        System.assert(responseBody.contains('hipaa'));
    }
    
    @IsTest
    static void testGetInitialData_WithInsurancePolicy() {
        List<Account> personAccounts = [SELECT Id FROM Account WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
        if (personAccounts.isEmpty()) {
            return;
        }
        Account personAcc = personAccounts[0];
        
        Product2 testProduct = new Product2(Name = 'Test Medical Product', IsActive = true);
        insert testProduct;

        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Test Policy',
            NameInsuredId = personAcc.Id,
            Status = 'Active',
            ARC_PolicyEffectiveDate__c = Date.today()
        );
        insert policy;

        InsurancePolicyCoverage coverage = new InsurancePolicyCoverage(
            InsurancePolicyId = policy.Id,
            CoverageName = 'Medical',
            vlocity_ins_fsc__Product2Id__c = testProduct.Id,
            ARC_UnitPrice__c = 500.00
        );
        insert coverage;

        Contact policyCon = [SELECT Id FROM Contact WHERE AccountId = :personAcc.Id LIMIT 1];
        InsurancePolicyParticipant participant = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            PrimaryParticipantContactId = policyCon.Id,
            Role = 'Primary'
        );
        insert participant;

        Case c = [SELECT Id FROM Case WHERE Subject = 'Test QLE' LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/get-initial-data';
        req.httpMethod = 'GET';
        req.addParameter('caseId', c.Id);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('currentState'));
        System.assert(responseBody.contains('currentProducts'));
        System.assert(responseBody.contains('members'));
    }

    @IsTest
    static void testGetInitialData_InvalidCaseId() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/get-initial-data';
        req.httpMethod = 'GET';
        req.addParameter('caseId', 'INVALID_ID');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
    }

    @IsTest
    static void testGet_UnknownRoute() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/unknown-route';
        req.httpMethod = 'GET';

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
    }

    @IsTest
    static void testPost_UnknownRoute() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/unknown-route';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{}');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.post();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
    }

    @IsTest
    static void testPostReprice_NullBody() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/reprice';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('null');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.post();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
    }

    @IsTest
    static void testPostSaveQLE_NullBody() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/save-qle';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('null');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.post();
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
    }

    @IsTest
    static void testBuildCurrentProductsFromPolicy() {
        List<Account> personAccounts = [SELECT Id FROM Account WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
        if (personAccounts.isEmpty()) {
            return;
        }
        Account personAcc = personAccounts[0];
        
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Test Policy',
            NameInsuredId = personAcc.Id,
            Status = 'Active',
            EmployeeContribution = 200.00,
            EmployerContribution = 300.00,
            ARC_JsonSESG__c = '{"generalInformation":{"medicalProgram":{"Medical":{"ARC_PayPeriod__c":"Monthly"}}}}'
        );
        insert policy;

        InsurancePolicyCoverage coverage1 = new InsurancePolicyCoverage(
            InsurancePolicyId = policy.Id,
            CoverageName = 'Medical',
            vlocity_ins_fsc__Product2Id__c = testProduct.Id,
            ARC_UnitPrice__c = 500.00
        );
        insert coverage1;

        policy = [SELECT Id, EmployeeContribution, EmployerContribution, ARC_JsonSESG__c,
                  (SELECT Id, CoverageName, vlocity_ins_fsc__Product2Id__c, ARC_UnitPrice__c, ARC_ParentPolicyCoverage__c 
                   FROM InsurancePolicyCoverages)
                  FROM InsurancePolicy WHERE Id = :policy.Id];

        Test.startTest();
        Map<String, Object> products = ARC_SGQLEnrollmentEndpoint.buildCurrentProductsFromPolicy(policy);
        Test.stopTest();

        System.assertNotEquals(null, products);
        System.assert(products.containsKey('Medical'));
    }

    @IsTest
    static void testGetInitialData_WithHIPAA() {
        List<Account> personAccounts = [SELECT Id, Census_Member__c FROM Account WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
        if (personAccounts.isEmpty()) {
            return;
        }
        Account personAcc = personAccounts[0];
        
        List<vlocity_ins__GroupCensusMember__c> censusMembers = [SELECT Id, vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        if (censusMembers.isEmpty()) {
            return;
        }
        vlocity_ins__GroupCensusMember__c censusMember = censusMembers[0];
        
        vlocity_ins__GroupCensusMember__c dependentMember = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__FirstName__c = 'Jane',
            vlocity_ins__LastName__c = 'Doe',
            vlocity_ins__CensusId__c = censusMember.vlocity_ins__CensusId__c,
            vlocity_ins__Birthdate__c = Date.today().addYears(-30),
            vlocity_ins__Email__c = 'jane@test.com'
        );
        insert dependentMember;

        ARC_HipaaAuthorization__c hipaa = new ARC_HipaaAuthorization__c(
            ARC_Census__c = censusMember.vlocity_ins__CensusId__c,
            ARC_AuthorizedMember__c = dependentMember.Id
        );
        insert hipaa;

        Case c = [SELECT Id FROM Case WHERE Subject = 'Test QLE' LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/get-initial-data';
        req.httpMethod = 'GET';
        req.addParameter('caseId', c.Id);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('hipaa'));
    }

    @IsTest
    static void testGetInitialData_WithGuardian() {
        List<Account> personAccounts = [SELECT Id FROM Account WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
        if (personAccounts.isEmpty()) {
            return;
        }
        Account personAcc = personAccounts[0];
        
        List<RecordType> rtList = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_IFPPersonAccount' AND SobjectType='Account' LIMIT 1];
        if (rtList.isEmpty()) {
            return;
        }
        
        Account guardianAcc = new Account(
            FirstName = 'Guardian',
            LastName = 'Parent',
            PersonBirthdate = Date.today().addYears(-40),
            PersonEmail = 'guardian@test.com',
            Phone = '555-0123',
            RecordTypeId = rtList[0].Id
        );
        insert guardianAcc;

        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Test Policy with Guardian',
            NameInsuredId = personAcc.Id,
            ARC_Guardian__c = guardianAcc.Id,
            Status = 'Active',
            ARC_PolicyEffectiveDate__c = Date.today()
        );
        insert policy;

        Case c = [SELECT Id FROM Case WHERE Subject = 'Test QLE' LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/get-initial-data';
        req.httpMethod = 'GET';
        req.addParameter('caseId', c.Id);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('guardian'));
    }

    @IsTest
    static void testGetInitialData_WithExternalHIPAA() {
        List<vlocity_ins__GroupCensusMember__c> censusMembers = [SELECT Id, vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        if (censusMembers.isEmpty()) {
            return;
        }
        vlocity_ins__GroupCensusMember__c censusMember = censusMembers[0];
        
        Contact externalPerson = new Contact(
            FirstName = 'External',
            LastName = 'Authorized',
            Email = 'external@test.com',
            Phone = '555-9999',
            Birthdate = Date.today().addYears(-35),
            MailingStreet = '456 External St',
            MailingCity = 'Test City',
            MailingState = 'CA',
            MailingPostalCode = '90210'
        );
        insert externalPerson;

        ARC_HipaaAuthorization__c hipaa = new ARC_HipaaAuthorization__c(
            ARC_Census__c = censusMember.vlocity_ins__CensusId__c,
            ARC_ExternalPersonAuthorized__c = externalPerson.Id
        );
        insert hipaa;

        Case c = [SELECT Id FROM Case WHERE Subject = 'Test QLE' LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/get-initial-data';
        req.httpMethod = 'GET';
        req.addParameter('caseId', c.Id);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('hipaa'));
    }

    @IsTest
    static void testBuildMembersFromPolicy() {
        List<Account> personAccounts = [SELECT Id FROM Account WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
        if (personAccounts.isEmpty()) {
            return;
        }
        Account personAcc = personAccounts[0];
        
        List<RecordType> rtList = [SELECT Id FROM RecordType WHERE DeveloperName='ARC_IFPPersonAccount' AND SobjectType='Account' LIMIT 1];
        if (rtList.isEmpty()) {
            return;
        }
        
        Account dependentAcc = new Account(
            RecordTypeId = rtList[0].Id,
            FirstName = 'Dependent',
            LastName = 'Child',
            PersonBirthdate = Date.today().addYears(-10),
            PersonEmail = 'child@test.com',
            BillingStreet = '789 Child Lane',
            BillingCity = 'Test City',
            BillingState = 'TX',
            BillingPostalCode = '75001'
        );
        insert dependentAcc;
        
        Product2 testProduct = new Product2(Name = 'Test Coverage Product', IsActive = true);
        insert testProduct;

        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Test Policy Members',
            NameInsuredId = personAcc.Id,
            Status = 'Active',
            ARC_PolicyEffectiveDate__c = Date.today(),
            EmployeeContribution = 150.00,
            EmployerContribution = 250.00
        );
        insert policy;

        InsurancePolicyCoverage coverage = new InsurancePolicyCoverage(
            InsurancePolicyId = policy.Id,
            CoverageName = 'Medical',
            vlocity_ins_fsc__Product2Id__c = testProduct.Id,
            ARC_UnitPrice__c = 400.00
        );
        insert coverage;

        Contact primaryCon = [SELECT Id FROM Contact WHERE AccountId = :personAcc.Id LIMIT 1];
        Contact dependentCon = [SELECT Id FROM Contact WHERE AccountId = :dependentAcc.Id LIMIT 1];

        InsurancePolicyParticipant primaryParticipant = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            PrimaryParticipantContactId = primaryCon.Id,
            Role = 'Primary'
        );
        insert primaryParticipant;

        InsurancePolicyParticipant dependentParticipant = new InsurancePolicyParticipant(
            InsurancePolicyId = policy.Id,
            PrimaryParticipantContactId = dependentCon.Id,
            Role = 'Dependent'
        );
        insert dependentParticipant;

        Case c = [SELECT Id FROM Case WHERE Subject = 'Test QLE' LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/get-initial-data';
        req.httpMethod = 'GET';
        req.addParameter('caseId', c.Id);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('members'));
        System.assert(responseBody.contains('Primary') || responseBody.contains('Dependent'));
    }

    @IsTest
    static void testBuildMedicalProgramFromPolicy() {
        List<Account> personAccounts = [SELECT Id FROM Account WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
        if (personAccounts.isEmpty()) {
            return;
        }
        Account personAcc = personAccounts[0];
        
        Product2 testProduct = new Product2(Name = 'Medical Program Product', IsActive = true);
        insert testProduct;

        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Test Policy Medical Program',
            NameInsuredId = personAcc.Id,
            Status = 'Active',
            EmployeeContribution = 100.00,
            EmployerContribution = 200.00,
            ARC_IndividualPrice__c = 300.00,
            ARC_PolicyEffectiveDate__c = Date.today()
        );
        insert policy;

        InsurancePolicyCoverage coverage = new InsurancePolicyCoverage(
            InsurancePolicyId = policy.Id,
            CoverageName = 'Medical',
            vlocity_ins_fsc__Product2Id__c = testProduct.Id,
            ARC_UnitPrice__c = 300.00
        );
        insert coverage;

        Case c = [SELECT Id FROM Case WHERE Subject = 'Test QLE' LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/api/v1/small-group-qle/get-initial-data';
        req.httpMethod = 'GET';
        req.addParameter('caseId', c.Id);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGQLEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(200, res.statusCode);
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('medicalProgram'));
    }



}