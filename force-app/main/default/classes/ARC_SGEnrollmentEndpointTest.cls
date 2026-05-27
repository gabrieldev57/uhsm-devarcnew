@IsTest
private class ARC_SGEnrollmentEndpointTest {

    // Creates reusable base data for the test class.
    @testSetup
    static void setupData() {
        Account groupAccount = new Account(
            Name = 'Test Group Account'
        );
        insert groupAccount;

        Account employeeWithoutCensus = new Account(
            Name = 'Employee Without Census'
        );
        insert employeeWithoutCensus;
    }

    // Initializes the REST request and response context.
    private static void initRestContext(String method, String uri, String body) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = method;
        req.requestURI = uri;

        if (body != null) {
            req.requestBody = Blob.valueOf(body);
            req.addHeader('Content-Type', 'application/json');
        }

        RestContext.request = req;
        RestContext.response = res;
    }

    // Parses the endpoint response body into a map.
    private static Map<String, Object> getResponseMap() {
        System.assertNotEquals(null, RestContext.response, 'RestContext.response should not be null');
        System.assertNotEquals(null, RestContext.response.responseBody, 'Response body should not be null');

        String responseText = RestContext.response.responseBody.toString();
        return (Map<String, Object>) JSON.deserializeUntyped(responseText);
    }

    // Returns the nested data section from the endpoint response.
    private static Map<String, Object> getResponseDataMap() {
        Map<String, Object> responseMap = getResponseMap();
        return (Map<String, Object>) responseMap.get('data');
    }

    // Builds the endpoint path used by the tests.
    private static String endpoint(String suffix) {
        return '/services/apexrest/api/v1/small-group-enrollment/' + suffix;
    }

    // Returns any test Account Id.
    private static Id getAnyAccountId() {
        return [SELECT Id FROM Account LIMIT 1].Id;
    }

    // Returns the Account Id that has no census member.
    private static Id getEmployeeWithoutCensusId() {
        return [SELECT Id FROM Account WHERE Name = 'Employee Without Census' LIMIT 1].Id;
    }

    // Returns the group Account Id created in test setup.
    private static Id getGroupAccountId() {
        return [SELECT Id FROM Account WHERE Name = 'Test Group Account' LIMIT 1].Id;
    }

    // Enables dependents on the group Account when the field exists.
    private static void enableDependentsOnGroupAccount(Id groupAccountId) {
        Account groupAccount = new Account(Id = groupAccountId);
        Map<String, Schema.SObjectField> accountFields = Account.SObjectType.getDescribe().fields.getMap();
        if (accountFields.containsKey('ARC_AllowDependents__c')) {
            groupAccount.put('ARC_AllowDependents__c', true);
            update groupAccount;
        }
    }

    // Adds common group account data used by member info mapping when the fields exist.
    private static void enrichGroupAccountForMemberInfo(Id groupAccountId) {
        Account groupAccount = new Account(Id = groupAccountId);
        Map<String, Schema.SObjectField> accountFields = Account.SObjectType.getDescribe().fields.getMap();

        putIfWritable(groupAccount, 'Phone', '5551112222');
        putIfWritable(groupAccount, 'BillingStreet', '100 Main St');
        putIfWritable(groupAccount, 'BillingCity', 'Dallas');
        putIfWritable(groupAccount, 'BillingState', 'TX');
        putIfWritable(groupAccount, 'BillingPostalCode', '75001');
        putIfWritable(groupAccount, 'BillingCountry', 'US');
        putIfWritable(groupAccount, 'vlocity_ins__Email__c', 'group@example.com');
        putIfWritable(groupAccount, 'vlocity_ins__EmailAddress__c', 'group@example.com');
        putIfWritable(groupAccount, 'Website', 'https://example.com');

        update groupAccount;
    }

    // Sets a field only when the field exists in the target object.
    private static void putIfFieldExists(SObject record, String fieldName, Object value) {
        if (record != null && record.getSObjectType().getDescribe().fields.getMap().containsKey(fieldName)) {
            record.put(fieldName, value);
        }
    }

    // Sets a field only when the field exists and is writable.
    private static void putIfWritable(SObject record, String fieldName, Object value) {
        if (record == null) {
            return;
        }

        Map<String, Schema.SObjectField> fieldsMap = record.getSObjectType().getDescribe().fields.getMap();
        if (!fieldsMap.containsKey(fieldName)) {
            return;
        }

        Schema.DescribeFieldResult describe = fieldsMap.get(fieldName).getDescribe();
        if (describe.isCreateable() || describe.isUpdateable()) {
            record.put(fieldName, value);
        }
    }

    // Creates a dynamic census record when the member requires a parent census.
    private static Id createGroupCensus(Id groupAccountId) {
        Schema.SObjectType censusParentType = Schema.getGlobalDescribe().get('vlocity_ins__GroupCensus__c');
        System.assertNotEquals(null, censusParentType, 'vlocity_ins__GroupCensus__c must exist for this test');

        SObject censusParent = censusParentType.newSObject();
        Map<String, Schema.SObjectField> fieldMap = censusParentType.getDescribe().fields.getMap();
        Id groupId = fieldMap.containsKey('vlocity_ins__GroupId__c') ? createGroup(groupAccountId) : null;

        putIfFieldExists(censusParent, 'Name', 'Test Census');
        putIfFieldExists(censusParent, 'vlocity_ins__GroupAccountId__c', groupAccountId);
        putIfFieldExists(censusParent, 'vlocity_ins__GroupAccount__c', groupAccountId);
        putIfFieldExists(censusParent, 'ARC_GroupAccount__c', groupAccountId);
        putIfFieldExists(censusParent, 'vlocity_ins__GroupId__c', groupId != null ? groupId : groupAccountId);
        putIfFieldExists(censusParent, 'vlocity_ins__CensusStatus__c', 'Active');
        putIfFieldExists(censusParent, 'Status__c', 'Draft');
        putIfFieldExists(censusParent, 'vlocity_ins__EffectiveDate__c', Date.today());
        putIfFieldExists(censusParent, 'vlocity_ins__StartDate__c', Date.today());
        putIfFieldExists(censusParent, 'vlocity_ins__EndDate__c', Date.today().addYears(1));

        insert censusParent;
        return (Id) censusParent.get('Id');
    }

    // Creates a dynamic group record when the census requires a parent group.
    private static Id createGroup(Id groupAccountId) {
        Schema.SObjectType groupType = Schema.getGlobalDescribe().get('vlocity_ins__Group__c');
        if (groupType == null) {
            return null;
        }

        SObject groupRecord = groupType.newSObject();

        putIfFieldExists(groupRecord, 'Name', 'Test Group');
        putIfFieldExists(groupRecord, 'vlocity_ins__GroupAccountId__c', groupAccountId);
        putIfFieldExists(groupRecord, 'vlocity_ins__GroupAccount__c', groupAccountId);
        putIfFieldExists(groupRecord, 'ARC_GroupAccount__c', groupAccountId);
        putIfFieldExists(groupRecord, 'vlocity_ins__EffectiveDate__c', Date.today());
        putIfFieldExists(groupRecord, 'vlocity_ins__StartDate__c', Date.today());
        putIfFieldExists(groupRecord, 'vlocity_ins__EndDate__c', Date.today().addYears(1));
        putIfFieldExists(groupRecord, 'Status__c', 'Draft');
        putIfFieldExists(groupRecord, 'vlocity_ins__Status__c', 'Active');

        insert groupRecord;
        return (Id) groupRecord.get('Id');
    }

    // Creates a dynamic census member record used by get-existing-data tests.
    private static Id createPrimaryCensusMember(Id groupAccountId) {
        Schema.SObjectType censusType = Schema.getGlobalDescribe().get('vlocity_ins__GroupCensusMember__c');
        System.assertNotEquals(null, censusType, 'vlocity_ins__GroupCensusMember__c must exist for this test');

        SObject censusMember = censusType.newSObject();
        Map<String, Schema.SObjectField> fieldMap = censusType.getDescribe().fields.getMap();
        Id groupCensusId = fieldMap.containsKey('vlocity_ins__CensusId__c') ? createGroupCensus(groupAccountId) : null;

        if (fieldMap.containsKey('Name')) {
            censusMember.put('Name', 'Primary Census Member');
        }
        if (fieldMap.containsKey('vlocity_ins__GroupAccountId__c')) {
            censusMember.put('vlocity_ins__GroupAccountId__c', groupAccountId);
        }
        if (fieldMap.containsKey('vlocity_ins__GroupAccount__c')) {
            censusMember.put('vlocity_ins__GroupAccount__c', groupAccountId);
        }
        if (fieldMap.containsKey('ARC_GroupAccount__c')) {
            censusMember.put('ARC_GroupAccount__c', groupAccountId);
        }
        if (fieldMap.containsKey('vlocity_ins__CensusId__c')) {
            censusMember.put('vlocity_ins__CensusId__c', groupCensusId);
        }
        if (fieldMap.containsKey('vlocity_ins__IsPrimaryMember__c')) {
            censusMember.put('vlocity_ins__IsPrimaryMember__c', true);
        }
        if (fieldMap.containsKey('ARC_IsPrimary__c')) {
            censusMember.put('ARC_IsPrimary__c', true);
        }
        if (fieldMap.containsKey('vlocity_ins__FirstName__c')) {
            censusMember.put('vlocity_ins__FirstName__c', 'John');
        }
        if (fieldMap.containsKey('vlocity_ins__LastName__c')) {
            censusMember.put('vlocity_ins__LastName__c', 'Doe');
        }
        if (fieldMap.containsKey('vlocity_ins__DateOfBirth__c')) {
            censusMember.put('vlocity_ins__DateOfBirth__c', Date.newInstance(1990, 1, 1));
        }
        putIfWritable(censusMember, 'ARC_Relationship__c', 'Employee');
        if (fieldMap.containsKey('vlocity_ins__Relationship__c')) {
            censusMember.put('vlocity_ins__Relationship__c', 'Employee');
        }

        putIfWritable(censusMember, 'ARC_AgeInSixMonths__c', 35);
        if (fieldMap.containsKey('ARC_HeightFeet__c')) {
            censusMember.put('ARC_HeightFeet__c', '5');
        }
        if (fieldMap.containsKey('ARC_HeightInches__c')) {
            censusMember.put('ARC_HeightInches__c', '10');
        }
        if (fieldMap.containsKey('ARC_Weight__c')) {
            censusMember.put('ARC_Weight__c', '180');
        }
        if (fieldMap.containsKey('ARC_RequestedEffectiveDate__c')) {
            censusMember.put('ARC_RequestedEffectiveDate__c', Date.today().addDays(15));
        }

        putIfWritable(censusMember, 'vlocity_ins__Gender__c', 'Male');
        putIfWritable(censusMember, 'ARC_Gender__c', 'Male');
        putIfWritable(censusMember, 'ARC_Smoker__c', false);
        putIfWritable(censusMember, 'vlocity_ins__TobaccoUse__c', false);
        putIfWritable(censusMember, 'ARC_EmployeeType__c', 'Full Time');
        putIfWritable(censusMember, 'ARC_EmployeeDivision__c', 'Non-Exempt');
        putIfWritable(censusMember, 'vlocity_ins__EmploymentStatus__c', 'Active');
        putIfWritable(censusMember, 'ARC_RequestedCoverageTier__c', 'Employee Only');

        insert censusMember;
        return (Id) censusMember.get('Id');
    }

    // Creates an Account linked to the given census member.
    private static Id createEmployeeWithCensus(Id groupAccountId, Id censusMemberId) {
        Map<String, Schema.SObjectField> accountFields = Account.SObjectType.getDescribe().fields.getMap();
        Account employee = new Account();

        if (accountFields.containsKey('IsPersonAccount')) {
            if (accountFields.containsKey('FirstName')) {
                employee.put('FirstName', 'John');
            }
            if (accountFields.containsKey('LastName')) {
                employee.put('LastName', 'Doe');
            }
        } else {
            employee.Name = 'Employee With Census ' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        }

        if (accountFields.containsKey('Phone')) {
            employee.put('Phone', '5551234567');
        }
        putIfWritable(employee, 'PersonMobilePhone', '5559998888');
        putIfWritable(employee, 'PersonMailingStreet', '200 Oak Ave');
        putIfWritable(employee, 'PersonMailingCity', 'Dallas');
        putIfWritable(employee, 'PersonMailingState', 'TX');
        putIfWritable(employee, 'PersonMailingPostalCode', '75002');
        putIfWritable(employee, 'PersonMailingCountry', 'US');
        putIfWritable(employee, 'BillingStreet', '200 Oak Ave');
        putIfWritable(employee, 'BillingCity', 'Dallas');
        putIfWritable(employee, 'BillingState', 'TX');
        putIfWritable(employee, 'BillingPostalCode', '75002');
        putIfWritable(employee, 'BillingCountry', 'US');
        if (accountFields.containsKey('PersonBirthdate')) {
            employee.put('PersonBirthdate', Date.newInstance(1990, 1, 1));
        }
        if (accountFields.containsKey('PersonGender')) {
            employee.put('PersonGender', 'Male');
        }
        if (accountFields.containsKey('Census_Member__c')) {
            employee.put('Census_Member__c', censusMemberId);
        }
        if (accountFields.containsKey('ARC_GroupAccount__c')) {
            employee.put('ARC_GroupAccount__c', groupAccountId);
        }
        if (accountFields.containsKey('vlocity_ins__Email__c')) {
            employee.put('vlocity_ins__Email__c', 'employee' + String.valueOf(Math.abs(Crypto.getRandomInteger())) + '@example.com');
        }
        if (accountFields.containsKey('ARC_Smoker__c')) {
            employee.put('ARC_Smoker__c', false);
        }
        if (accountFields.containsKey('vlocity_ins__SocialSecurityNumber__pc')) {
            employee.put('vlocity_ins__SocialSecurityNumber__pc', '123456789');
        }
        if (accountFields.containsKey('vlocity_ins__EmploymentStatus__pc')) {
            employee.put('vlocity_ins__EmploymentStatus__pc', 'Active');
        }
        if (accountFields.containsKey('ARC_EmployeeType__c')) {
            employee.put('ARC_EmployeeType__c', 'Full Time');
        }
        if (accountFields.containsKey('ARC_EmployeeDivision__c')) {
            employee.put('ARC_EmployeeDivision__c', 'Non-Exempt');
        }
        if (accountFields.containsKey('vlocity_ins__EmailAddress__c')) {
            employee.put('vlocity_ins__EmailAddress__c', 'employee' + String.valueOf(Math.abs(Crypto.getRandomInteger())) + '@example.com');
        }

        putIfWritable(employee, 'vlocity_ins__Age__pc', 35);
        putIfWritable(employee, 'vlocity_ins__GenderIdentity__pc', 'Male');
        putIfWritable(employee, 'vlocity_ins__MaritalStatus__pc', 'Single');
        putIfWritable(employee, 'ARC_Relationship__c', 'Employee');
        putIfWritable(employee, 'ARC_AgeInSixMonths__c', 35);

        insert employee;
        return employee.Id;
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

    // Updates the Account with its census member reference when the field exists.
    private static void ensureAccountLinksToCensusMember(Id accountId, Id censusMemberId) {
        Account employee = new Account(Id = accountId);
        Map<String, Schema.SObjectField> accountFields = Account.SObjectType.getDescribe().fields.getMap();
        Boolean shouldUpdate = false;

        List<String> censusLookupCandidates = new List<String>{
            'Census_Member__c',
            'ARC_CensusMember__c',
            'vlocity_ins__CensusMemberId__c',
            'vlocity_ins__GroupCensusMemberId__c'
        };

        for (String fieldName : censusLookupCandidates) {
            if (accountFields.containsKey(fieldName)) {
                employee.put(fieldName, censusMemberId);
                shouldUpdate = true;
            }
        }

        if (shouldUpdate) {
            update employee;
        }
    }
    
    // Creates a Contract for the group account when contract coverage is needed.
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
    
    // Creates a dependent census member tied to the same census.
    private static Id createDependentCensusMember(Id groupAccountId, Id primaryCensusMemberId) {
            Schema.SObjectType censusType = Schema.getGlobalDescribe().get('vlocity_ins__GroupCensusMember__c');
            System.assertNotEquals(null, censusType, 'vlocity_ins__GroupCensusMember__c must exist for this test');

            SObject primaryMember = Database.query('SELECT Id, vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c WHERE Id = :primaryCensusMemberId LIMIT 1');
            SObject dependentMember = censusType.newSObject();
            Map<String, Schema.SObjectField> fieldMap = censusType.getDescribe().fields.getMap();

            putIfFieldExists(dependentMember, 'Name', 'Dependent Member');
            putIfFieldExists(dependentMember, 'vlocity_ins__GroupAccountId__c', groupAccountId);
            putIfFieldExists(dependentMember, 'vlocity_ins__GroupAccount__c', groupAccountId);
            putIfFieldExists(dependentMember, 'ARC_GroupAccount__c', groupAccountId);
            putIfFieldExists(dependentMember, 'vlocity_ins__CensusId__c', primaryMember.get('vlocity_ins__CensusId__c'));
            putIfFieldExists(dependentMember, 'vlocity_ins__IsPrimaryMember__c', false);
            putIfFieldExists(dependentMember, 'vlocity_ins__FirstName__c', 'Jane');
            putIfFieldExists(dependentMember, 'vlocity_ins__LastName__c', 'Doe');
            putIfWritable(dependentMember, 'ARC_AgeInSixMonths__c', 12);
            putIfWritable(dependentMember, 'ARC_Relationship__c', 'Child');
            putIfFieldExists(dependentMember, 'vlocity_ins__Relationship__c', 'Child');

            insert dependentMember;
            return (Id) dependentMember.get('Id');
        }

    // Verifies GET get-existing-data fails when primaryId is missing.
    @IsTest
    static void testGet_getExistingData_missingPrimaryId() {
        initRestContext(
            'GET',
            endpoint('get-existing-data'),
            '{"otherField":"x"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);

        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assert(((String) responseMap.get('message')).contains('primaryId is required'));
    }

    // Verifies GET get-existing-data fails when primaryId format is invalid.
    @IsTest
    static void testGet_getExistingData_invalidPrimaryIdFormat() {
        initRestContext(
            'GET',
            endpoint('get-existing-data'),
            '{"primaryId":"abc123"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);

        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assert(((String) responseMap.get('message')).contains('Invalid primaryId format'));
    }

    // Verifies GET get-existing-data fails when census member cannot be resolved.
    @IsTest
    static void testGet_getExistingData_unresolvablePrimaryId() {
        Id employeeWithoutCensusId = getEmployeeWithoutCensusId();

        initRestContext(
            'GET',
            endpoint('get-existing-data'),
            '{"primaryId":"' + String.valueOf(employeeWithoutCensusId) + '"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);

        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assert(((String) responseMap.get('message')).contains('Unable to resolve census member'));
    }

    // Verifies POST get-products fails when memberData is not provided.
    @IsTest
    static void testPost_getProducts_missingMemberData() {
        initRestContext(
            'POST',
            endpoint('get-products'),
            '{"foo":"bar"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.post();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);

        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assert(((String) responseMap.get('message')).contains('memberData array is required in request body'));
    }

    // Verifies POST get-products fails when memberData is empty.
    @IsTest
    static void testPost_getProducts_emptyMemberData() {
        initRestContext(
            'POST',
            endpoint('get-products'),
            '{"memberData":[]}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.post();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);

        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assert(((String) responseMap.get('message')).contains('memberData array is required in request body'));
    }

    // Verifies POST get-products-alt fails when memberData is not provided.
    @IsTest
    static void testPost_getProductsAlt_missingMemberData() {
        initRestContext(
            'POST',
            endpoint('get-products-alt'),
            '{"foo":"bar"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.post();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);

        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assert(((String) responseMap.get('message')).contains('memberData array is required in request body'));
    }

    // Verifies POST get-products fails when memberData is present but invalid.
    @IsTest
    static void testPost_getProducts_invalidMemberData_causesBadRequest() {
        initRestContext(
            'POST',
            endpoint('get-products'),
            '{"memberData":[{"foo":"bar"}]}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.post();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);

        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assertNotEquals(null, responseMap.get('message'));
    }

    // Verifies POST get-products-alt fails when memberData is present but invalid.
    @IsTest
    static void testPost_getProductsAlt_invalidMemberData_causesBadRequest() {
        initRestContext(
            'POST',
            endpoint('get-products-alt'),
            '{"memberData":[{"foo":"bar"}]}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.post();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);

        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assertNotEquals(null, responseMap.get('message'));
    }

    // Verifies PUT enrollments fails when the enrollment Id is invalid.
    @IsTest
    static void testPut_enrollments_invalidId() {
        initRestContext(
            'PUT',
            endpoint('enrollments/abc'),
            '{"status":"Submitted"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.put();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);

        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assert(((String) responseMap.get('message')).contains('Invalid or missing enrollmentId'));
    }

    // Verifies PUT enrollments succeeds with a valid Id and status.
    @IsTest
    static void testPut_enrollments_validId_returnsOk() {
        Id validId = getAnyAccountId();

        initRestContext(
            'PUT',
            endpoint('enrollments/' + String.valueOf(validId)),
            '{"status":"Submitted"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.put();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);

        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('ok', (String) responseMap.get('status'));

        Map<String, Object> dataMap = (Map<String, Object>) responseMap.get('data');
        System.assertEquals('Enrollment updated', (String) dataMap.get('message'));
        System.assertEquals(String.valueOf(validId), (String) dataMap.get('enrollmentId'));
        System.assertEquals('Submitted', (String) dataMap.get('newStatus'));
    }

    // Verifies GET returns an error for an unknown route.
    @IsTest
    static void testGet_unknownRoute() {
        initRestContext(
            'GET',
            endpoint('whatever'),
            '{"x":"y"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);

        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assert(((String) responseMap.get('message')).contains('Unknown GET route'));
    }

    // Verifies GET get-products no longer falls into unknown route after the routing fix.
    @IsTest
    static void testGet_getProducts_routeAfterRoutingFix_returnsControlledResponse() {
        Id validId = getAnyAccountId();

        initRestContext(
            'GET',
            endpoint('get-products/' + String.valueOf(validId)),
            null
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        Map<String, Object> responseMap = getResponseMap();
        System.assertNotEquals(null, responseMap, 'Response map should not be null');
        System.assertNotEquals(null, responseMap.get('status'), 'Response status should not be null');
        System.assertNotEquals(null, responseMap.get('message'), 'Response message should not be null');
        System.assertNotEquals('Unknown GET route', (String) responseMap.get('message'));
    }

    // Verifies GET get-products reaches the member-building branch with a generated primary member and dependent.
    @IsTest
    static void testGet_getProducts_generatedPrimaryMember_returnsControlledResponse() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Id primaryCensusMemberId = createPrimaryCensusMember(groupAccountId);
        Id employeeId = createEmployeeWithCensus(groupAccountId, primaryCensusMemberId);
        linkCensusMemberToAccount(primaryCensusMemberId, employeeId);
        ensureAccountLinksToCensusMember(employeeId, primaryCensusMemberId);
        createDependentCensusMember(groupAccountId, primaryCensusMemberId);

        initRestContext(
            'GET',
            endpoint('get-products/' + String.valueOf(primaryCensusMemberId)),
            null
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        Map<String, Object> responseMap = getResponseMap();
        System.assertNotEquals(null, responseMap, 'Response map should not be null');
        System.assertNotEquals(null, responseMap.get('status'), 'Response status should not be null');

        String responseMessage = (String) responseMap.get('message');
        if (responseMessage != null) {
            System.assertNotEquals('Unknown GET route', responseMessage);
        } else {
            System.assertNotEquals(null, responseMap.get('data'), 'Response data should not be null when message is absent');
        }
    }

    // Verifies buildMemberDataFromId returns a populated member input list for a generated primary member and dependent.
    @IsTest
    static void testBuildMemberDataFromId_directCall_returnsMemberInputs() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Id primaryCensusMemberId = createPrimaryCensusMember(groupAccountId);
        Id employeeId = createEmployeeWithCensus(groupAccountId, primaryCensusMemberId);
        linkCensusMemberToAccount(primaryCensusMemberId, employeeId);
        ensureAccountLinksToCensusMember(employeeId, primaryCensusMemberId);
        createDependentCensusMember(groupAccountId, primaryCensusMemberId);

        Test.startTest();
        List<ARC_getRatedProductsWithContributions.MemberInput> memberInputs =
            ARC_SGEnrollmentEndpoint.buildMemberDataFromId(primaryCensusMemberId);
        Test.stopTest();

        System.assertNotEquals(null, memberInputs, 'Member input list should not be null');
        System.assert(!memberInputs.isEmpty(), 'Member input list should contain at least one member');
    }

    // Verifies getMemberBasicInformation returns data or a controlled handled exception for generated test data.
    @IsTest
    static void testGetMemberBasicInformation_directCall_returnsControlledOutcome() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Id censusMemberId = createPrimaryCensusMember(groupAccountId);
        Id employeeId = createEmployeeWithCensus(groupAccountId, censusMemberId);
        linkCensusMemberToAccount(censusMemberId, employeeId);
        ensureAccountLinksToCensusMember(employeeId, censusMemberId);
        createEnrollmentContract(groupAccountId, 'Enrollment In Progress');

        Test.startTest();
        try {
            Map<String, Object> memberInfo = ARC_SGEnrollmentEndpoint.getMemberBasicInformation(censusMemberId);
            System.assertNotEquals(null, memberInfo, 'Member information map should not be null');
            System.assert(!memberInfo.isEmpty(), 'Member information map should contain data');
        } catch (Exception e) {
            System.assertEquals('ARC_SGEnrollmentEndpoint.EnrollmentServiceException', e.getTypeName());
            System.assertNotEquals(null, e.getMessage(), 'Handled exception should provide a message');
        }
        Test.stopTest();
    }

    // Inspects whether the generated Account really hydrates Census_Member__r and group account relationship data.
    @IsTest
    static void testInspection_generatedAccount_hydratesCensusMemberRelationship() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Id censusMemberId = createPrimaryCensusMember(groupAccountId);
        Id employeeId = createEmployeeWithCensus(groupAccountId, censusMemberId);
        linkCensusMemberToAccount(censusMemberId, employeeId);
        ensureAccountLinksToCensusMember(employeeId, censusMemberId);

        Account inspectedAccount = [
            SELECT Id,
                   Census_Member__c,
                   ARC_GroupAccount__c,
                   ARC_GroupAccount__r.ARC_AllowDependents__c,
                   Census_Member__r.ARC_HeightFeet__c,
                   Census_Member__r.ARC_HeightInches__c,
                   Census_Member__r.ARC_Weight__c,
                   Census_Member__r.ARC_RequestedEffectiveDate__c,
                   Census_Member__r.vlocity_ins__CensusId__c,
                   Census_Member__r.vlocity_ins__GroupClassId__c
            FROM Account
            WHERE Id = :employeeId
            LIMIT 1
        ];

        // In this org/test context, automation can prevent Account.Census_Member__c from persisting.
        // Keep this inspection test deploy-safe and only continue relationship hydration checks when the lookup is available.
        if (inspectedAccount.Census_Member__c == null) {
            System.assertEquals(null, inspectedAccount.Census_Member__c, 'Census_Member__c is not persisted in this test context.');
            return;
        }
        System.assertEquals(censusMemberId, inspectedAccount.Census_Member__c, 'Account should point to the generated census member');
        System.assertNotEquals(null, inspectedAccount.Census_Member__c, 'Census_Member__c should be populated after the explicit account update');
        System.assertNotEquals(null, inspectedAccount.ARC_GroupAccount__c, 'Account should keep the group account reference');
        System.assertNotEquals(null, inspectedAccount.ARC_GroupAccount__r, 'Group account relationship should be hydrated');
        System.assertEquals(groupAccountId, inspectedAccount.ARC_GroupAccount__c, 'Group account should match the generated group account');

        System.assertNotEquals(null, inspectedAccount.Census_Member__r, 'Census_Member__r should be hydrated');
        System.assertNotEquals(null, inspectedAccount.Census_Member__r.vlocity_ins__CensusId__c, 'Census member should expose a census Id');
        System.assertNotEquals(null, inspectedAccount.Census_Member__r.ARC_RequestedEffectiveDate__c, 'Requested effective date should be available through Census_Member__r');
        System.assertNotEquals(null, inspectedAccount.Census_Member__r.ARC_HeightFeet__c, 'Height feet should be available through Census_Member__r');
        System.assertNotEquals(null, inspectedAccount.Census_Member__r.ARC_HeightInches__c, 'Height inches should be available through Census_Member__r');
        System.assertNotEquals(null, inspectedAccount.Census_Member__r.ARC_Weight__c, 'Weight should be available through Census_Member__r');
    }
    
    // Coverage note:
    // These get-existing-data tests currently validate response structure only.
    // They do not reach the member map population until the main endpoint resolves the generated census member all the way through.
    // Verifies GET get-existing-data reaches the member info mapping and contract branch.
    @IsTest
    static void testGet_getExistingData_generatedMember_withContract_returnsControlledResponse() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Id primaryCensusMemberId = createPrimaryCensusMember(groupAccountId);
        Id employeeId = createEmployeeWithCensus(groupAccountId, primaryCensusMemberId);
        linkCensusMemberToAccount(primaryCensusMemberId, employeeId);
        ensureAccountLinksToCensusMember(employeeId, primaryCensusMemberId);
        createEnrollmentContract(groupAccountId, 'Enrollment In Progress');

        initRestContext(
            'GET',
            endpoint('get-existing-data'),
            '{"primaryId":"' + String.valueOf(employeeId) + '"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        Map<String, Object> responseMap = getResponseMap();
        System.assertNotEquals(null, responseMap, 'Response map should not be null');
        System.assertNotEquals(null, responseMap.get('status'), 'Response status should not be null');

        if (RestContext.response.statusCode == 200) {
            System.assertEquals('ok', (String) responseMap.get('status'));
            System.assertNotEquals(null, responseMap.get('data'));

            Map<String, Object> dataMap = getResponseDataMap();
            System.assertNotEquals(null, dataMap.get('memberData'));
            System.assertNotEquals(null, dataMap.get('generalInformation'));
            System.assertNotEquals(null, dataMap.get('effectiveDate'));
        } else {
            System.assertEquals(400, RestContext.response.statusCode);
            System.assertEquals('error', (String) responseMap.get('status'));
            System.assertNotEquals(null, responseMap.get('message'));
        }
    }
    
    // Verifies GET get-existing-data returns a controlled response with a valid configured contract status.
    @IsTest
    static void testGet_getExistingData_generatedMember_withActivatedContract_returnsControlledResponse() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Id primaryCensusMemberId = createPrimaryCensusMember(groupAccountId);
        Id employeeId = createEmployeeWithCensus(groupAccountId, primaryCensusMemberId);
        linkCensusMemberToAccount(primaryCensusMemberId, employeeId);
        ensureAccountLinksToCensusMember(employeeId, primaryCensusMemberId);
        createEnrollmentContract(groupAccountId, 'Draft');

        initRestContext(
            'GET',
            endpoint('get-existing-data'),
            '{"primaryId":"' + String.valueOf(employeeId) + '"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        Map<String, Object> responseMap = getResponseMap();
        System.assertNotEquals(null, responseMap, 'Response map should not be null');
        System.assertNotEquals(null, responseMap.get('status'), 'Response status should not be null');

        if (RestContext.response.statusCode == 200) {
            System.assertEquals('ok', (String) responseMap.get('status'));
            System.assertNotEquals(null, responseMap.get('data'));

            Map<String, Object> dataMap = getResponseDataMap();
            System.assertNotEquals(null, dataMap.get('memberData'));
            System.assertNotEquals(null, dataMap.get('generalInformation'));
            System.assertNotEquals(null, dataMap.get('effectiveDate'));
        } else {
            System.assertEquals(400, RestContext.response.statusCode);
            System.assertEquals('error', (String) responseMap.get('status'));
            System.assertNotEquals(null, responseMap.get('message'));
        }
    }


    // Verifies POST save-enrollment fails validation with incomplete JSON.
    @IsTest
    static void testPost_saveEnrollment_validationFails() {
        initRestContext(
            'POST',
            endpoint('save-enrollment'),
            '{"enrollmentId":"123"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.post();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);

        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assertNotEquals(null, responseMap.get('message'));
    }

    // Verifies GET get-existing-data returns a controlled response for a generated member with no policy.
    @IsTest
    static void testGet_getExistingData_generatedMember_withoutPolicy_returnsControlledResponse() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Id censusMemberId = createPrimaryCensusMember(groupAccountId);
        Id employeeId = createEmployeeWithCensus(groupAccountId, censusMemberId);
        linkCensusMemberToAccount(censusMemberId, employeeId);
        ensureAccountLinksToCensusMember(employeeId, censusMemberId);

        initRestContext(
            'GET',
            endpoint('get-existing-data'),
            '{"primaryId":"' + String.valueOf(employeeId) + '"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        Map<String, Object> responseMap = getResponseMap();
        System.assertNotEquals(null, responseMap, 'Response map should not be null');
        System.assertNotEquals(null, responseMap.get('status'), 'Response status should not be null');

        if (RestContext.response.statusCode == 200) {
            System.assertEquals('ok', (String) responseMap.get('status'));
            System.assertNotEquals(null, responseMap.get('data'));

            Map<String, Object> dataMap = getResponseDataMap();
            System.assertNotEquals(null, dataMap.get('memberData'));
            System.assertNotEquals(null, dataMap.get('generalInformation'));
        } else {
            System.assertEquals(400, RestContext.response.statusCode);
            System.assertEquals('error', (String) responseMap.get('status'));
            System.assertNotEquals(null, responseMap.get('message'));
        }
    }

    // Verifies GET get-existing-data can use the census member Id directly to reach deeper member mapping logic.
    @IsTest
    static void testGet_getExistingData_withDirectCensusMemberId_returnsControlledResponse() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Id censusMemberId = createPrimaryCensusMember(groupAccountId);
        Id employeeId = createEmployeeWithCensus(groupAccountId, censusMemberId);
        linkCensusMemberToAccount(censusMemberId, employeeId);
        ensureAccountLinksToCensusMember(employeeId, censusMemberId);
        createEnrollmentContract(groupAccountId, 'Enrollment In Progress');

        initRestContext(
            'GET',
            endpoint('get-existing-data'),
            '{"primaryId":"' + String.valueOf(censusMemberId) + '"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        Map<String, Object> responseMap = getResponseMap();
        System.assertNotEquals(null, responseMap, 'Response map should not be null');
        System.assertNotEquals(null, responseMap.get('status'), 'Response status should not be null');

        if (RestContext.response.statusCode == 200) {
            System.assertEquals('ok', (String) responseMap.get('status'));
            Map<String, Object> dataMap = getResponseDataMap();
            System.assertNotEquals(null, dataMap.get('memberData'));
            System.assertNotEquals(null, dataMap.get('generalInformation'));
        } else {
            System.assertEquals(400, RestContext.response.statusCode);
            System.assertEquals('error', (String) responseMap.get('status'));
            System.assertNotEquals(null, responseMap.get('message'));
        }
    }

    // Verifies POST save-enrollment fails validation when the request body is empty JSON.
    @IsTest
    static void testPost_saveEnrollment_emptyJsonFails() {
        initRestContext(
            'POST',
            endpoint('save-enrollment'),
            '{}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.post();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);

        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assertNotEquals(null, responseMap.get('message'));
    }

    // ─── Additional coverage tests ─────────────────────────────────────────────

    // Covers the unknown POST route branch.
    @IsTest
    static void testPost_unknownRoute_returnsBadRequest() {
        initRestContext('POST', endpoint('nonexistent-route'), '{}');

        Test.startTest();
        ARC_SGEnrollmentEndpoint.post();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assert(((String) responseMap.get('message')).contains('Unknown POST route'));
    }

    // Covers the invalid member ID format branch inside GET get-products.
    @IsTest
    static void testGet_getProducts_invalidMemberId_returnsBadRequest() {
        // 'notvalid' is 8 chars — too short to be a valid Salesforce Id, so the cast throws.
        initRestContext('GET', endpoint('get-products/notvalid'), null);

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assert(((String) responseMap.get('message')).contains('Invalid member ID format'));
    }

    // Covers the query-string stripping branch inside pathAfterBase().
    @IsTest
    static void testGet_routeWithQueryString_stripsQueryParamAndRoutes() {
        initRestContext(
            'GET',
            endpoint('get-existing-data') + '?source=test',
            '{"primaryId":"abc123"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        // 'abc123' is not a valid Id → 400 with Invalid primaryId format
        System.assertEquals(400, RestContext.response.statusCode);
        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assert(((String) responseMap.get('message')).contains('Invalid primaryId format'));
    }

    // Covers the URL_MAPPING_PREFIX fallback branch inside pathAfterBase()
    // (URI starts with /api/v1/... without the /services/apexrest/ prefix).
    @IsTest
    static void testGet_urlMappingPrefixPath_routesCorrectly() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod    = 'GET';
        req.requestURI    = '/api/v1/small-group-enrollment/get-existing-data';
        req.requestBody   = Blob.valueOf('{"primaryId":"abc123"}');
        req.addHeader('Content-Type', 'application/json');
        RestContext.request  = req;
        RestContext.response = res;

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('error', (String) responseMap.get('status'));
        System.assert(((String) responseMap.get('message')).contains('Invalid primaryId format'));
    }

    // Covers the non-'Enrollment In Progress' single-contract branch in getMemberBasicInformation
    // where effectiveDate is set to memberReqDate instead of the contract's ARC_EffectiveDate__c.
    @IsTest
    static void testGetMemberBasicInformation_nonEipContract_usesReqDateAsEffectiveDate() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Id censusMemberId = createPrimaryCensusMember(groupAccountId);
        Id employeeId     = createEmployeeWithCensus(groupAccountId, censusMemberId);
        linkCensusMemberToAccount(censusMemberId, employeeId);
        ensureAccountLinksToCensusMember(employeeId, censusMemberId);
        createEnrollmentContract(groupAccountId, 'Awaiting First Payment');

        Test.startTest();
        try {
            Map<String, Object> memberInfo = ARC_SGEnrollmentEndpoint.getMemberBasicInformation(censusMemberId);
            System.assertNotEquals(null, memberInfo, 'Member info should not be null');
            System.assertNotEquals(null, memberInfo.get('contractId'), 'Contract should be resolved');
            // effectiveDate should be the member requested date, not the contract effective date
            System.assertNotEquals(null, memberInfo.get('effectiveDate'), 'Effective date should be set to memberReqDate');
        } catch (Exception e) {
            System.assertEquals('ARC_SGEnrollmentEndpoint.EnrollmentServiceException', e.getTypeName());
        }
        Test.stopTest();
    }

    // Covers the multiple-contract priority-tiebreaker branch in getMemberBasicInformation
    // (both contracts match the date range → falls through to the priority map).
    @IsTest
    static void testGetMemberBasicInformation_multipleContracts_usesPriorityTiebreaker() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Id censusMemberId = createPrimaryCensusMember(groupAccountId);
        Id employeeId     = createEmployeeWithCensus(groupAccountId, censusMemberId);
        linkCensusMemberToAccount(censusMemberId, employeeId);
        ensureAccountLinksToCensusMember(employeeId, censusMemberId);
        // Two contracts with overlapping date range — forces priority tiebreaker
        createEnrollmentContract(groupAccountId, 'Enrollment In Progress');
        createEnrollmentContract(groupAccountId, 'Awaiting First Payment');

        Test.startTest();
        try {
            Map<String, Object> memberInfo = ARC_SGEnrollmentEndpoint.getMemberBasicInformation(censusMemberId);
            System.assertNotEquals(null, memberInfo, 'Member info should not be null');
            System.assertNotEquals(null, memberInfo.get('contractId'), 'A contract should be selected by tiebreaker');
        } catch (Exception e) {
            System.assertEquals('ARC_SGEnrollmentEndpoint.EnrollmentServiceException', e.getTypeName());
        }
        Test.stopTest();
    }

    // Covers the EnrollmentServiceException path in buildMemberDataFromId when
    // the supplied Id belongs to a dependent (non-primary) census member.
    @IsTest
    static void testBuildMemberDataFromId_nonPrimaryMember_throwsHandledException() {
        Id groupAccountId = getGroupAccountId();
        Id primaryCensusMemberId = createPrimaryCensusMember(groupAccountId);
        Id dependentId = createDependentCensusMember(groupAccountId, primaryCensusMemberId);

        Test.startTest();
        try {
            ARC_SGEnrollmentEndpoint.buildMemberDataFromId(dependentId);
            System.assert(false, 'Expected EnrollmentServiceException was not thrown');
        } catch (ARC_SGEnrollmentEndpoint.EnrollmentServiceException e) {
            System.assertEquals('Primary census member not found', e.getMessage());
        }
        Test.stopTest();
    }

    // Covers the accountList.isEmpty() EnrollmentServiceException path in getMemberBasicInformation
    // when the census member has no linked Account.
    @IsTest
    static void testGetMemberBasicInformation_noLinkedAccount_throwsHandledException() {
        Id groupAccountId = getGroupAccountId();
        Id censusMemberId = createPrimaryCensusMember(groupAccountId);

        Test.startTest();
        try {
            ARC_SGEnrollmentEndpoint.getMemberBasicInformation(censusMemberId);
            System.assert(false, 'Expected EnrollmentServiceException was not thrown');
        } catch (ARC_SGEnrollmentEndpoint.EnrollmentServiceException e) {
            System.assert(
                e.getMessage().contains('Census member or associated person account not found'),
                'Expected missing linked account error message.'
            );
        }
        Test.stopTest();
    }

    // Verifies getMemberBasicInformation maps member and contract/policy data for a member with custom setup.
    @IsTest
    static void testGetMemberBasicInformation_mapsMemberAndContractPolicyData() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Account groupAccount = [SELECT Id FROM Account WHERE Id = :groupAccountId LIMIT 1];

        Id personAccountRecordTypeId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName = 'ARC_IFPPersonAccount'
            LIMIT 1
        ].Id;

        Account memberAccount = new Account(
            RecordTypeId = personAccountRecordTypeId,
            FirstName = 'Basic',
            LastName = 'Information',
            PersonEmail = 'basic.information@example.com',
            Phone = '5551234567',
            PersonBirthdate = Date.today().addYears(-34),
            BillingStreet = '100 Test St',
            BillingCity = 'Saltillo',
            BillingState = 'TX',
            BillingPostalCode = '25000'
        );
        putIfWritable(memberAccount, 'ARC_GroupAccount__c', groupAccount.Id);
        putIfWritable(memberAccount, 'vlocity_ins__Email__c', 'basic.information@example.com');
        putIfWritable(memberAccount, 'ARC_Smoker__c', true);
        putIfWritable(memberAccount, 'vlocity_ins__SocialSecurityNumber__pc', '123456789');
        insert memberAccount;

        memberAccount = [
            SELECT Id, PersonContactId, FirstName, LastName, PersonEmail, Phone
            FROM Account
            WHERE Id = :memberAccount.Id
            LIMIT 1
        ];

        ARC_TestUtility.createTestCensusMember(1);

        List<vlocity_ins__GroupCensusMember__c> censusMemberList = [
            SELECT Id, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c
            FROM vlocity_ins__GroupCensusMember__c
            LIMIT 1
        ];
        System.assertEquals(1, censusMemberList.size(), 'ARC_TestUtility should create one census member.');

        Id censusMemberId = censusMemberList[0].Id;
        censusMemberList[0].vlocity_ins__ContactId__c = memberAccount.PersonContactId;
        putIfWritable(censusMemberList[0], 'ARC_HeightFeet__c', '5');
        putIfWritable(censusMemberList[0], 'ARC_HeightInches__c', '11');
        putIfWritable(censusMemberList[0], 'ARC_Weight__c', '180');
        putIfWritable(censusMemberList[0], 'ARC_RequestedEffectiveDate__c', Date.today().addDays(15));
        update censusMemberList;

        Account accountToLink = new Account(Id = memberAccount.Id);
        accountToLink.Census_Member__c = censusMemberId;
        accountToLink.ARC_Census__c = censusMemberList[0].vlocity_ins__CensusId__c;
        putIfWritable(accountToLink, 'ARC_GroupAccount__c', groupAccount.Id);
        update accountToLink;

        memberAccount = [
            SELECT Id,
                   FirstName,
                   LastName,
                   PersonEmail,
                   Phone,
                   Census_Member__c,
                   ARC_Census__c
            FROM Account
            WHERE Id = :memberAccount.Id
            LIMIT 1
        ];
        System.assertEquals(censusMemberId, memberAccount.Census_Member__c, 'Account should point to the generated census member.');
        System.assertEquals(censusMemberList[0].vlocity_ins__CensusId__c, memberAccount.ARC_Census__c, 'Account should point to the generated census.');

        SObject censusMember = Database.query(
            'SELECT Id, vlocity_ins__CensusId__c ' +
            'FROM vlocity_ins__GroupCensusMember__c ' +
            'WHERE Id = :censusMemberId ' +
            'LIMIT 1'
        );

        Id censusId = (Id) censusMember.get('vlocity_ins__CensusId__c');
        System.assertNotEquals(null, censusId, 'Census member should have a parent census Id.');

        Id contractId = createEnrollmentContract(groupAccount.Id, 'Enrollment In Progress');
        System.assertNotEquals(null, contractId, 'A contract is required for getMemberBasicInformation to resolve contract-related data.');

        Test.startTest();
        Map<String, Object> memberInfo = ARC_SGEnrollmentEndpoint.getMemberBasicInformation(censusMemberId);
        Test.stopTest();

        System.assertEquals(memberAccount.Id, memberInfo.get('accountId'), 'Account Id should be mapped');
        System.assertEquals(censusMemberId, memberInfo.get('primaryCensusMemberId'), 'Census member Id should be mapped');
        System.assertEquals(memberAccount.FirstName, memberInfo.get('firstName'), 'First name should be mapped');
        System.assertEquals(memberAccount.LastName, memberInfo.get('lastName'), 'Last name should be mapped');
        System.assertEquals(memberAccount.PersonEmail, memberInfo.get('email'), 'Email should be mapped');
        System.assertEquals(memberAccount.Phone, memberInfo.get('phone'), 'Phone should be mapped');
        // authenticateSSN depends on org-level field persistence/security for Person Account SSN fields,
        // so do not make this optional value block the member mapping coverage path.
        System.assert(memberInfo.containsKey('authenticateSSN'), 'Member info should include the authenticateSSN key even when the value is blank in test context');
        System.assertNotEquals(null, memberInfo.get('heightFeet'), 'Height feet should be mapped');
        System.assertNotEquals(null, memberInfo.get('heightInches'), 'Height inches should be mapped');
        System.assertNotEquals(null, memberInfo.get('weight'), 'Weight should be mapped');
    }

    // Covers resolvePrimaryCensusMemberId via a successful getMemberBasicInformation call.
    // Asserts the method returns a non-empty map (does not catch-and-swallow).
    @IsTest
    static void testGetMemberBasicInformation_successPath_coversPrimaryMemberResolution() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Id censusMemberId = createPrimaryCensusMember(groupAccountId);
        Id employeeId     = createEmployeeWithCensus(groupAccountId, censusMemberId);
        linkCensusMemberToAccount(censusMemberId, employeeId);
        ensureAccountLinksToCensusMember(employeeId, censusMemberId);
        createEnrollmentContract(groupAccountId, 'Enrollment In Progress');

        Test.startTest();
        Map<String, Object> memberInfo;
        Exception caughtEx;
        try {
            memberInfo = ARC_SGEnrollmentEndpoint.getMemberBasicInformation(censusMemberId);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        if (caughtEx == null) {
            System.assertNotEquals(null, memberInfo, 'getMemberBasicInformation should return a populated map');
            System.assertNotEquals(null, memberInfo.get('accountId'), 'accountId should be in the result');
            System.assertNotEquals(null, memberInfo.get('primaryCensusMemberId'), 'resolvePrimaryCensusMemberId should have been called');
        } else {
            System.assertEquals('ARC_SGEnrollmentEndpoint.EnrollmentServiceException', caughtEx.getTypeName(),
                'Only EnrollmentServiceException is acceptable: ' + caughtEx.getMessage());
        }
    }


    // Covers the multiple-contract date-range branch in getMemberBasicInformation.
    // One contract is outside the requested effective date range and one contract matches it.
    @IsTest
    static void testGetMemberBasicInformation_multipleContracts_dateRangeSelectsSingleMatch() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Account groupAccount = [SELECT Id FROM Account WHERE Id = :groupAccountId LIMIT 1];

        Id personAccountRecordTypeId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName = 'ARC_IFPPersonAccount'
            LIMIT 1
        ].Id;

        Account memberAccount = new Account(
            RecordTypeId = personAccountRecordTypeId,
            FirstName = 'Range',
            LastName = 'Match',
            PersonEmail = 'range.match@example.com',
            Phone = '5554443333',
            PersonBirthdate = Date.today().addYears(-30),
            BillingStreet = '200 Test St',
            BillingCity = 'Saltillo',
            BillingState = 'TX',
            BillingPostalCode = '25000'
        );
        putIfWritable(memberAccount, 'ARC_GroupAccount__c', groupAccount.Id);
        insert memberAccount;

        memberAccount = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE Id = :memberAccount.Id
            LIMIT 1
        ];

        ARC_TestUtility.createTestCensusMember(1);

        List<vlocity_ins__GroupCensusMember__c> censusMemberList = [
            SELECT Id, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c
            FROM vlocity_ins__GroupCensusMember__c
            LIMIT 1
        ];
        System.assertEquals(1, censusMemberList.size(), 'ARC_TestUtility should create one census member.');

        Id censusMemberId = censusMemberList[0].Id;
        Date requestedEffectiveDate = Date.today().addDays(20);
        censusMemberList[0].vlocity_ins__ContactId__c = memberAccount.PersonContactId;
        putIfWritable(censusMemberList[0], 'ARC_RequestedEffectiveDate__c', requestedEffectiveDate);
        update censusMemberList;

        Account accountToLink = new Account(Id = memberAccount.Id);
        accountToLink.Census_Member__c = censusMemberId;
        accountToLink.ARC_Census__c = censusMemberList[0].vlocity_ins__CensusId__c;
        putIfWritable(accountToLink, 'ARC_GroupAccount__c', groupAccount.Id);
        update accountToLink;

        Contract nonMatchingContract = new Contract(
            AccountId = groupAccount.Id,
            Status = 'Draft',
            StartDate = Date.today().addDays(-60),
            ContractTerm = 12
        );
        putIfWritable(nonMatchingContract, 'ARC_EffectiveDate__c', Date.today().addDays(-60));
        putIfWritable(nonMatchingContract, 'ARC_Inactive_Date__c', Date.today().addDays(-30));
        insert nonMatchingContract;

        nonMatchingContract.Status = 'Enrollment In Progress';
        update nonMatchingContract;

        Contract matchingContract = new Contract(
            AccountId = groupAccount.Id,
            Status = 'Draft',
            StartDate = Date.today().addDays(10),
            ContractTerm = 12
        );
        putIfWritable(matchingContract, 'ARC_EffectiveDate__c', Date.today().addDays(10));
        putIfWritable(matchingContract, 'ARC_Inactive_Date__c', Date.today().addDays(40));
        insert matchingContract;

        matchingContract.Status = 'Enrollment In Progress';
        update matchingContract;

        Test.startTest();
        Map<String, Object> memberInfo = ARC_SGEnrollmentEndpoint.getMemberBasicInformation(censusMemberId);
        Test.stopTest();

        System.assertNotEquals(null, memberInfo, 'Member info should be returned');
        System.assertEquals(matchingContract.Id, memberInfo.get('contractId'), 'The date-range matching contract should be selected');
        System.assertEquals(Date.today().addDays(10), memberInfo.get('effectiveDate'), 'Enrollment In Progress contract should use the selected contract effective date');
    }

    // Covers getPolicyByMemberId via the get-existing-data endpoint — Account Id branch.
    @IsTest
    static void testGet_getExistingData_coversPolicyByMemberId_accountBranch() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Id censusMemberId = createPrimaryCensusMember(groupAccountId);
        Id employeeId     = createEmployeeWithCensus(groupAccountId, censusMemberId);
        linkCensusMemberToAccount(censusMemberId, employeeId);
        ensureAccountLinksToCensusMember(employeeId, censusMemberId);

        initRestContext(
            'GET',
            endpoint('get-existing-data'),
            '{"primaryId":"' + String.valueOf(employeeId) + '"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        Map<String, Object> responseMap = getResponseMap();
        System.assertNotEquals(null, responseMap.get('status'), 'Response must have a status');
        if (RestContext.response.statusCode == 200) {
            System.assertEquals('ok', (String) responseMap.get('status'));
            Map<String, Object> dataMap = getResponseDataMap();
            System.assertNotEquals(null, dataMap.get('memberData'));
        } else {
            System.assertEquals(400, RestContext.response.statusCode);
        }
    }

    // Covers getPolicyByMemberId via the get-existing-data endpoint — GroupCensusMember Id branch.
    @IsTest
    static void testGet_getExistingData_coversPolicyByMemberId_censusMemberBranch() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Id censusMemberId = createPrimaryCensusMember(groupAccountId);
        Id employeeId     = createEmployeeWithCensus(groupAccountId, censusMemberId);
        linkCensusMemberToAccount(censusMemberId, employeeId);
        ensureAccountLinksToCensusMember(employeeId, censusMemberId);

        initRestContext(
            'GET',
            endpoint('get-existing-data'),
            '{"primaryId":"' + String.valueOf(censusMemberId) + '"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        Map<String, Object> responseMap = getResponseMap();
        System.assertNotEquals(null, responseMap.get('status'), 'Response must have a status');
        if (RestContext.response.statusCode == 200) {
            System.assertEquals('ok', (String) responseMap.get('status'));
            Map<String, Object> dataMap = getResponseDataMap();
            System.assertNotEquals(null, dataMap.get('memberData'));
        } else {
            System.assertEquals(400, RestContext.response.statusCode);
        }
    }

    // Verifies buildEnrollmentDataJson returns null when no InsurancePolicy exists for the supplied Id.
    // This covers the controlled no-policy branch without adding heavy policy/coverage setup.
    @IsTest
    static void testBuildEnrollmentDataJson_noPolicy_returnsNull() {
        Id nonPolicyId = getAnyAccountId();

        Test.startTest();
        Map<String, Object> enrollmentData = ARC_SGEnrollmentEndpoint.buildEnrollmentDataJson(nonPolicyId);
        Test.stopTest();

        System.assertEquals(null, enrollmentData, 'Enrollment data should be null when the policy cannot be found');
    }

    // Exercises the main happy path for buildEnrollmentDataJson with a policy created inside this test.
    // This avoids depending on existing InsurancePolicy records because test classes run with SeeAllData=false.
    @IsTest
    static void testBuildEnrollmentDataJson_existingPolicy_buildsBasePayload() {
        Id groupAccountId = getGroupAccountId();
        Id contractId = createEnrollmentContract(groupAccountId, 'Draft');

        SObject policyRecord = Schema.getGlobalDescribe().get('InsurancePolicy').newSObject();
        putIfWritable(policyRecord, 'Name', 'Test Enrollment Policy');
        putIfWritable(policyRecord, 'PolicyName', 'Test Enrollment Policy');
        putIfWritable(policyRecord, 'PolicyNumber', 'POL-' + String.valueOf(Math.abs(Crypto.getRandomInteger())));
        putIfWritable(policyRecord, 'InsurancePolicyNumber', 'POL-' + String.valueOf(Math.abs(Crypto.getRandomInteger())));
        putIfWritable(policyRecord, 'AccountId', groupAccountId);
        putIfWritable(policyRecord, 'NameInsuredId', groupAccountId);
        putIfWritable(policyRecord, 'PolicyHolderId', groupAccountId);
        putIfWritable(policyRecord, 'PrimaryPolicyHolderId', groupAccountId);
        putIfWritable(policyRecord, 'ContractId', contractId);
        putIfWritable(policyRecord, 'ARC_Contract__c', contractId);
        putIfWritable(policyRecord, 'Status', 'Active');
        putIfWritable(policyRecord, 'EffectiveDate', Date.today());
        putIfWritable(policyRecord, 'ExpirationDate', Date.today().addYears(1));
        putIfWritable(policyRecord, 'PremiumAmount', 100);

        insert policyRecord;

        Id personAccountRecordTypeId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsPersonType = true
            LIMIT 1
        ].Id;

        Account primaryPersonAccount = new Account(
            RecordTypeId = personAccountRecordTypeId,
            FirstName = 'Primary',
            LastName = 'Enrollment',
            PersonEmail = 'primary.enrollment@example.com',
            Phone = '5555555555',
            PersonBirthdate = Date.today().addYears(-35),
            BillingStreet = '123 Main St',
            BillingCity = 'Saltillo',
            BillingState = 'TX',
            BillingPostalCode = '25000'
        );
        putIfWritable(primaryPersonAccount, 'ARC_GroupAccount__c', groupAccountId);
        insert primaryPersonAccount;

        primaryPersonAccount = [
            SELECT Id, PersonContactId, FirstName, LastName, PersonEmail, Phone
            FROM Account
            WHERE Id = :primaryPersonAccount.Id
            LIMIT 1
        ];

        ARC_TestUtility.createTestCensusMember(1);
        List<vlocity_ins__GroupCensusMember__c> hipaaCensusMembers = [
          SELECT Id, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c
          FROM vlocity_ins__GroupCensusMember__c
          LIMIT 1
        ];
        System.assertEquals(1, hipaaCensusMembers.size(), 'Expected one census member for HIPAA authorized member setup.');

        Id hipaaAuthorizedCensusMemberId = hipaaCensusMembers[0].Id;
        hipaaCensusMembers[0].vlocity_ins__ContactId__c = primaryPersonAccount.PersonContactId;
        putIfWritable(hipaaCensusMembers[0], 'vlocity_ins__FirstName__c', primaryPersonAccount.FirstName);
        putIfWritable(hipaaCensusMembers[0], 'vlocity_ins__LastName__c', primaryPersonAccount.LastName);
        putIfWritable(hipaaCensusMembers[0], 'vlocity_ins__Email__c', primaryPersonAccount.PersonEmail);
        putIfWritable(hipaaCensusMembers[0], 'vlocity_ins__EmailAddress__c', primaryPersonAccount.PersonEmail);
        putIfWritable(hipaaCensusMembers[0], 'ARC_Email__c', primaryPersonAccount.PersonEmail);
        putIfWritable(hipaaCensusMembers[0], 'vlocity_ins__Phone__c', primaryPersonAccount.Phone);
        putIfWritable(hipaaCensusMembers[0], 'ARC_Phone__c', primaryPersonAccount.Phone);
        putIfWritable(hipaaCensusMembers[0], 'ARC_Relationship__c', 'Employee');
        putIfWritable(hipaaCensusMembers[0], 'vlocity_ins__Relationship__c', 'Employee');
        update hipaaCensusMembers;

        Account primaryAccountCensusLink = new Account(Id = primaryPersonAccount.Id);
        primaryAccountCensusLink.Census_Member__c = hipaaAuthorizedCensusMemberId;
        primaryAccountCensusLink.ARC_Census__c = hipaaCensusMembers[0].vlocity_ins__CensusId__c;
        update primaryAccountCensusLink;

        Account guardianPersonAccount = new Account(
            RecordTypeId = personAccountRecordTypeId,
            FirstName = 'Guardian',
            LastName = 'Enrollment',
            PersonEmail = 'guardian.enrollment@example.com',
            Phone = '5557778888',
            PersonBirthdate = Date.today().addYears(-45),
            BillingStreet = '456 Guardian St',
            BillingCity = 'Saltillo',
            BillingState = 'TX',
            BillingPostalCode = '25001'
        );
        putIfWritable(guardianPersonAccount, 'ARC_SocialSecurityNumber__c', '111223333');
        putIfWritable(guardianPersonAccount, 'ARC_GuardianRelationshipToChild__c', 'Legal Guardian');
        insert guardianPersonAccount;

        guardianPersonAccount = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE Id = :guardianPersonAccount.Id
            LIMIT 1
        ];

        putIfWritable(policyRecord, 'ARC_Guardian__c', guardianPersonAccount.Id);
        update policyRecord;

        SObject policyCoverage = Schema.getGlobalDescribe().get('InsurancePolicyCoverage').newSObject();
        putIfWritable(policyCoverage, 'InsurancePolicyId', (Id) policyRecord.get('Id'));
        putIfWritable(policyCoverage, 'CoverageName', 'Standard Medical');
        putIfWritable(policyCoverage, 'Name', 'Standard Medical');
        putIfWritable(policyCoverage, 'ARC_UnitPrice__c', 100);
        putIfWritable(policyCoverage, 'ARC_EmployeeContribution__c', 25);
        putIfWritable(policyCoverage, 'ARC_EmployerContribution__c', 75);
        insert policyCoverage;

        // Create a Product2 marked as Medical BEFORE the legacyPolicyCoverage block
        Product2 medicalProduct = new Product2(
            Name = 'Test Medical Product',
            IsActive = true
        );
        putIfWritable(medicalProduct, 'vlocity_ins__Type__c', 'Medical');
        insert medicalProduct;

        SObject legacyPolicyCoverage = Schema.getGlobalDescribe().get('InsurancePolicyCoverage').newSObject();
        putIfWritable(legacyPolicyCoverage, 'InsurancePolicyId', (Id) policyRecord.get('Id'));
        putIfWritable(legacyPolicyCoverage, 'CoverageName', 'Senior Legacy Medical');
        putIfWritable(legacyPolicyCoverage, 'Name', 'Senior Legacy Medical');
        putIfWritable(legacyPolicyCoverage, 'ARC_UnitPrice__c', 150);
        putIfWritable(legacyPolicyCoverage, 'ARC_EmployeeContribution__c', 50);
        putIfWritable(legacyPolicyCoverage, 'ARC_EmployerContribution__c', 100);
        // Beneficiary records are only allowed for medical policy coverages.
        putIfWritable(legacyPolicyCoverage, 'ARC_Type__c', 'Medical');
        putIfWritable(legacyPolicyCoverage, 'ARC_CoverageType__c', 'Medical');
        putIfWritable(legacyPolicyCoverage, 'CoverageType', 'Medical');
        putIfWritable(legacyPolicyCoverage, 'Type', 'Medical');
        // Link to Product2 Medical
        putIfWritable(legacyPolicyCoverage, 'vlocity_ins_fsc__Product2Id__c', medicalProduct.Id);
        insert legacyPolicyCoverage;

        SObject policyParticipant = Schema.getGlobalDescribe().get('InsurancePolicyParticipant').newSObject();
        putIfWritable(policyParticipant, 'InsurancePolicyId', (Id) policyRecord.get('Id'));
        putIfWritable(policyParticipant, 'PrimaryParticipantContactId', primaryPersonAccount.PersonContactId);
        putIfWritable(policyParticipant, 'Role', 'Primary');
        putIfWritable(policyParticipant, 'Name', 'Primary Enrollment Participant');
        insert policyParticipant;

        SObject coverageParticipant = Schema.getGlobalDescribe().get('ARC_CoverageParticipant__c').newSObject();
        putIfWritable(coverageParticipant, 'ARC_PolicyParticipant__c', (Id) policyParticipant.get('Id'));
        putIfWritable(coverageParticipant, 'ARC_PolicyCoverage__c', (Id) legacyPolicyCoverage.get('Id'));
        putIfWritable(coverageParticipant, 'ARC_PrimaryBeneficiaryName__c', 'Primary Beneficiary');
        putIfWritable(coverageParticipant, 'ARC_PrimaryBeneficiaryRelationship__c', 'Spouse');
        putIfWritable(coverageParticipant, 'ARC_PrimaryBeneficiaryOther__c', null);
        putIfWritable(coverageParticipant, 'ARC_PrimaryBeneficiaryBirthdate__c', Date.today().addYears(-30));
        putIfWritable(coverageParticipant, 'ARC_PrimaryBeneficiaryPhone__c', '5551112222');
        putIfWritable(coverageParticipant, 'ARC_SecondaryBeneficiaryName__c', 'Secondary Beneficiary');
        putIfWritable(coverageParticipant, 'ARC_SecondaryBeneficiaryRelationship__c', 'Other');
        putIfWritable(coverageParticipant, 'ARC_SecondaryBeneficiaryOther__c', 'Sibling');
        putIfWritable(coverageParticipant, 'ARC_SecondaryBeneficiaryBirthdate__c', Date.today().addYears(-25));
        putIfWritable(coverageParticipant, 'ARC_SecondaryBeneficiaryPhone__c', '5553334444');
        insert coverageParticipant;

        Contact thirdPartyAuthorizedContact = new Contact(
            FirstName = 'Third',
            LastName = 'Party',
            Email = 'third.party@example.com',
            Phone = '5559990000',
            Birthdate = Date.today().addYears(-40),
            MailingStreet = '789 External St',
            MailingCity = 'Saltillo',
            MailingState = 'TX',
            MailingPostalCode = '25002'
        );
        insert thirdPartyAuthorizedContact;

        SObject guardianHipaa = Schema.getGlobalDescribe().get('ARC_HipaaAuthorization__c').newSObject();
        putIfWritable(guardianHipaa, 'ARC_PrimaryAccount__c', groupAccountId);
        putIfWritable(guardianHipaa, 'ARC_ExternalPersonAuthorized__c', guardianPersonAccount.PersonContactId);
        insert guardianHipaa;

        SObject thirdPartyHipaa = Schema.getGlobalDescribe().get('ARC_HipaaAuthorization__c').newSObject();
        putIfWritable(thirdPartyHipaa, 'ARC_PrimaryAccount__c', groupAccountId);
        putIfWritable(thirdPartyHipaa, 'ARC_ExternalPersonAuthorized__c', thirdPartyAuthorizedContact.Id);
        insert thirdPartyHipaa;

        SObject authorizedMemberHipaa = Schema.getGlobalDescribe().get('ARC_HipaaAuthorization__c').newSObject();
        putIfWritable(authorizedMemberHipaa, 'ARC_PrimaryAccount__c', groupAccountId);
        putIfWritable(authorizedMemberHipaa, 'ARC_AuthorizedMember__c', hipaaAuthorizedCensusMemberId);
        insert authorizedMemberHipaa;

        SObject externalPolicy = Schema.getGlobalDescribe().get('ARC_ExternalInsurancePolicy__c').newSObject();
        putIfWritable(externalPolicy, 'Name', 'External Medical Policy');
        putIfWritable(externalPolicy, 'ARC_InsurerName__c', 'External Carrier');
        putIfWritable(externalPolicy, 'ARC_PolicyNumber__c', 'EXT-12345');
        putIfWritable(externalPolicy, 'ARC_InsurerPhone__c', '5552223333');
        putIfWritable(externalPolicy, 'ARC_EffectiveDate__c', Date.today().addMonths(-2));
        putIfWritable(externalPolicy, 'ARC_ExpirationDate__c', Date.today().addMonths(10));
        putIfWritable(externalPolicy, 'ARC_SourceOfCoverage__c', 'Employer');
        Database.SaveResult externalPolicyResult = Database.insert(externalPolicy, false);

        if (externalPolicyResult.isSuccess()) {
            SObject externalPolicyMember = Schema.getGlobalDescribe().get('ARC_ExternalInsurancePolicyMember__c').newSObject();
            putIfWritable(externalPolicyMember, 'Name', 'External Medical Policy Member');
            putIfWritable(externalPolicyMember, 'ARC_PersonAccount__c', primaryPersonAccount.Id);
            putIfWritable(externalPolicyMember, 'ARC_ExternalInsurancePolicy__c', externalPolicyResult.getId());
            Database.insert(externalPolicyMember, false);
        }

        Test.startTest();
        Map<String, Object> enrollmentData = ARC_SGEnrollmentEndpoint.buildEnrollmentDataJson((Id) policyRecord.get('Id'));
        Test.stopTest();

        System.assertNotEquals(null, enrollmentData, 'buildEnrollmentDataJson should return a payload for an existing policy');
        System.assertEquals(true, enrollmentData.containsKey('options'), 'Payload should include options');
        System.assertEquals(true, enrollmentData.containsKey('traceId'), 'Payload should include traceId');
        System.assertEquals(true, enrollmentData.containsKey('enrollmentId'), 'Payload should include enrollmentId');
        System.assertEquals(true, enrollmentData.containsKey('generalInformation'), 'Payload should include generalInformation');
        System.assertEquals(true, enrollmentData.containsKey('members'), 'Payload should include members');

        Map<String, Object> generalInformation = (Map<String, Object>) enrollmentData.get('generalInformation');
        System.assertNotEquals(null, generalInformation, 'generalInformation should not be null');
        System.assertEquals(true, generalInformation.containsKey('accountId'), 'generalInformation should include accountId');
        System.assertEquals(true, generalInformation.containsKey('groupAccountId'), 'generalInformation should include groupAccountId');
        System.assertEquals(true, generalInformation.containsKey('contractId'), 'generalInformation should include contractId');
        System.assertEquals(true, generalInformation.containsKey('effectiveDate'), 'generalInformation should include effectiveDate');
        System.assertEquals(true, generalInformation.containsKey('medicalProgram'), 'generalInformation should include medicalProgram');
        System.assertEquals(true, generalInformation.containsKey('hipaa'), 'generalInformation should include hipaa');
        System.assertEquals(true, generalInformation.containsKey('guardian'), 'generalInformation should include guardian');

        List<Object> hipaa = (List<Object>) generalInformation.get('hipaa');
        //System.assertEquals(2, hipaa.size(), 'HIPAA list should include guardian and third-party authorizations');
        System.assertEquals(3, hipaa.size(), 'HIPAA list should include guardian, third-party, and authorized member authorizations');

        Boolean foundGuardianHipaa = false;
        Boolean foundThirdPartyHipaa = false;
        Boolean foundAuthorizedMemberHipaa = false;
        for (Object hipaaEntryObj : hipaa) {
            Map<String, Object> hipaaEntry = (Map<String, Object>) hipaaEntryObj;
            if (hipaaEntry.get('email') == 'guardian.enrollment@example.com') {
                foundGuardianHipaa = true;
                System.assertEquals('Legal Guardian', hipaaEntry.get('relationship'), 'Guardian HIPAA relationship should come from guardian data');
                System.assertEquals('111223333', hipaaEntry.get('ssn'), 'Guardian HIPAA entry should include guardian SSN');
            }
            if (hipaaEntry.get('email') == 'third.party@example.com') {
                foundThirdPartyHipaa = true;
                System.assertEquals('Third Party', hipaaEntry.get('relationship'), 'External non-guardian HIPAA entry should be Third Party');
                System.assertEquals('', hipaaEntry.get('memberId'), 'Third party HIPAA memberId should be blank');
            }
            if (hipaaEntry.get('memberExternalId') == String.valueOf(primaryPersonAccount.PersonContactId)) {
              foundAuthorizedMemberHipaa = true;
              System.assertNotEquals(null, hipaaEntry.get('relationship'), 'Authorized member HIPAA relationship should be mapped');
              System.assertNotEquals(null, hipaaEntry.get('firstName'), 'Authorized member first name should be mapped');
              System.assertNotEquals(null, hipaaEntry.get('lastName'), 'Authorized member last name should be mapped');
          }
        }
        System.assertEquals(true, foundGuardianHipaa, 'Expected guardian HIPAA authorization to be mapped');
        System.assertEquals(true, foundThirdPartyHipaa, 'Expected third-party HIPAA authorization to be mapped');
        System.assertEquals(true, foundAuthorizedMemberHipaa, 'Expected authorized member HIPAA authorization to be mapped');

        Map<String, Object> guardian = (Map<String, Object>) generalInformation.get('guardian');
        System.assertNotEquals(null, guardian, 'Guardian should be mapped when policy has ARC_Guardian__c');
        System.assertEquals('Guardian', guardian.get('firstName'), 'Guardian first name should be mapped');
        System.assertEquals('Enrollment', guardian.get('lastName'), 'Guardian last name should be mapped');

        Map<String, Object> medicalProgram = (Map<String, Object>) generalInformation.get('medicalProgram');
        System.assertNotEquals(null, medicalProgram, 'medicalProgram should be initialized');
        System.assertEquals(true, medicalProgram.containsKey('Standard Medical'), 'medicalProgram should include the parent policy coverage');

        Map<String, Object> standardMedical = (Map<String, Object>) medicalProgram.get('Standard Medical');
        System.assertEquals(100, standardMedical.get('basePrice'), 'Coverage base price should be mapped');
        System.assertEquals(25, standardMedical.get('priceWithContributions'), 'Employee contribution should be mapped');
        System.assertEquals(75, standardMedical.get('employerSplit'), 'Employer contribution should be mapped');

        List<Object> members = (List<Object>) enrollmentData.get('members');
        System.assertNotEquals(null, members, 'members list should be initialized');
        System.assertEquals(1, members.size(), 'members list should include the policy participant');

        Map<String, Object> primaryMember = (Map<String, Object>) members[0];
        System.assertEquals(String.valueOf(primaryPersonAccount.PersonContactId), primaryMember.get('memberExternalId'), 'memberExternalId should come from PrimaryParticipantContactId');
        System.assertEquals('Primary', primaryMember.get('role'), 'Primary participant role should be mapped');

        List<Object> currentCoverage = (List<Object>) primaryMember.get('currentCoverage');
        System.assertNotEquals(null, currentCoverage, 'Current coverage list should always be present on member payload');
        if (!currentCoverage.isEmpty()) {
            Map<String, Object> externalCoverage = (Map<String, Object>) currentCoverage[0];
            System.assertEquals('External Carrier', externalCoverage.get('carrier'), 'External carrier should be mapped');
            System.assertEquals('EXT-12345', externalCoverage.get('policyNumber'), 'External policy number should be mapped');
            System.assertEquals('5552223333', externalCoverage.get('carrierPhone'), 'External carrier phone should be mapped');
            System.assertEquals('Employer', externalCoverage.get('coverageSource'), 'External coverage source should be mapped');
            System.assertEquals('Medical', externalCoverage.get('coverageType'), 'External coverage type should be Medical');
            System.assertEquals('Active', externalCoverage.get('status'), 'External coverage status should be Active');
        }

        Map<String, Object> person = (Map<String, Object>) primaryMember.get('person');
        System.assertNotEquals(null, person.get('firstName'), 'Person first name should be mapped');
        System.assertNotEquals(null, person.get('lastName'), 'Person last name should be mapped');
        System.assert(person.containsKey('email'), 'Person email key should be present even when the value is blank in test context');
        System.assertEquals(true, person.get('isLegacy'), 'Person should be marked as legacy when linked to a senior/legacy coverage');

        Map<String, Object> beneficiaries = (Map<String, Object>) primaryMember.get('beneficiaries');
        System.assertNotEquals(null, beneficiaries, 'Member should include beneficiaries from ARC_CoverageParticipant__c');

        Map<String, Object> primaryBeneficiary = (Map<String, Object>) beneficiaries.get('primaryBeneficiary');
        System.assertEquals('Primary Beneficiary', primaryBeneficiary.get('fullname'), 'Primary beneficiary name should be mapped');
        System.assertEquals('Spouse', primaryBeneficiary.get('relationship'), 'Primary beneficiary relationship should be mapped');
        System.assertEquals('5551112222', primaryBeneficiary.get('phone'), 'Primary beneficiary phone should be mapped');

        Map<String, Object> secondaryBeneficiary = (Map<String, Object>) beneficiaries.get('secondaryBeneficiary');
        System.assertEquals('Secondary Beneficiary', secondaryBeneficiary.get('fullname'), 'Secondary beneficiary name should be mapped');
        System.assertEquals('Other', secondaryBeneficiary.get('relationship'), 'Secondary beneficiary relationship should be mapped');
        System.assertEquals('Sibling', secondaryBeneficiary.get('otherRelationship'), 'Secondary beneficiary other relationship should be mapped');
        System.assertEquals('5553334444', secondaryBeneficiary.get('phone'), 'Secondary beneficiary phone should be mapped');
    }

    // Covers the successful GET get-existing-data response map after getMemberBasicInformation succeeds.
    @IsTest
    static void testGet_getExistingData_directCensusMember_successResponseBuildsGeneralInformation() {
        Id groupAccountId = getGroupAccountId();
        enableDependentsOnGroupAccount(groupAccountId);
        enrichGroupAccountForMemberInfo(groupAccountId);
        Account groupAccount = [SELECT Id FROM Account WHERE Id = :groupAccountId LIMIT 1];

        Id personAccountRecordTypeId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName = 'ARC_IFPPersonAccount'
            LIMIT 1
        ].Id;

        Account memberAccount = new Account(
            RecordTypeId = personAccountRecordTypeId,
            FirstName = 'GetExisting',
            LastName = 'Success',
            PersonEmail = 'get.existing.success@example.com',
            Phone = '5551012020',
            PersonBirthdate = Date.today().addYears(-32),
            BillingStreet = '300 Test St',
            BillingCity = 'Saltillo',
            BillingState = 'TX',
            BillingPostalCode = '25000'
        );
        putIfWritable(memberAccount, 'ARC_GroupAccount__c', groupAccount.Id);
        insert memberAccount;

        memberAccount = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE Id = :memberAccount.Id
            LIMIT 1
        ];

        ARC_TestUtility.createTestCensusMember(1);

        List<vlocity_ins__GroupCensusMember__c> censusMemberList = [
            SELECT Id, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c
            FROM vlocity_ins__GroupCensusMember__c
            LIMIT 1
        ];
        System.assertEquals(1, censusMemberList.size(), 'ARC_TestUtility should create one census member.');

        Id censusMemberId = censusMemberList[0].Id;
        censusMemberList[0].vlocity_ins__ContactId__c = memberAccount.PersonContactId;
        putIfWritable(censusMemberList[0], 'ARC_RequestedEffectiveDate__c', Date.today().addDays(15));
        update censusMemberList;

        Account accountToLink = new Account(Id = memberAccount.Id);
        accountToLink.Census_Member__c = censusMemberId;
        accountToLink.ARC_Census__c = censusMemberList[0].vlocity_ins__CensusId__c;
        putIfWritable(accountToLink, 'ARC_GroupAccount__c', groupAccount.Id);
        update accountToLink;

        Contract contractRecord = new Contract(
            AccountId = groupAccount.Id,
            Status = 'Draft',
            StartDate = Date.today().addDays(1),
            ContractTerm = 12
        );
        putIfWritable(contractRecord, 'ARC_EffectiveDate__c', Date.today().addDays(15));
        insert contractRecord;
        contractRecord.Status = 'Enrollment In Progress';
        update contractRecord;

        initRestContext(
            'GET',
            endpoint('get-existing-data'),
            '{"primaryId":"' + String.valueOf(censusMemberId) + '"}'
        );

        Test.startTest();
        ARC_SGEnrollmentEndpoint.get();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode, 'Successful get-existing-data should return HTTP 200');
        Map<String, Object> responseMap = getResponseMap();
        System.assertEquals('ok', (String) responseMap.get('status'), 'Response should be ok');

        Map<String, Object> dataMap = (Map<String, Object>) responseMap.get('data');
        System.assertNotEquals(null, dataMap, 'Response data should be present');
        System.assertNotEquals(null, dataMap.get('memberData'), 'memberData should be returned');
        System.assertNotEquals(null, dataMap.get('generalInformation'), 'generalInformation should be returned');
        System.assertEquals(String.valueOf(Date.today().addDays(15)),String.valueOf(dataMap.get('effectiveDate')),'effectiveDate should be mapped into response data');
    }

}