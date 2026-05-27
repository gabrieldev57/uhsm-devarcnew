@RestResource(urlMapping='/api/v1/small-group-enrollment/*')
global with sharing class ARC_SGEnrollmentEndpoint {

    /** REST-safe alternative to AuraHandledException (Aura-only in Salesforce). */
    public class EnrollmentServiceException extends Exception {}

    // ---- Router helpers ----
    private static String basePath() { return '/services/apexrest/api/v1/small-group-enrollment'; }

    // Previous implementation kept only the last URI segment.
    // Kept here as backup/reference during routing validation.
    /*
    
    private static String pathAfterBase() {
        String uri = RestContext.request.requestURI; // e.g. /api/v1/small-group-enrollment/get-products
        System.debug('Full URI: ' + uri);
        
        Integer lastSlash = uri.lastIndexOf('/');
        if (lastSlash != -1 && lastSlash < uri.length() - 1) {
            String pathAfter = uri.substring(lastSlash);
            System.debug('Path after last slash: ' + pathAfter);
            
            String route = pathAfter.startsWith('/') ? pathAfter.substring(1) : pathAfter;
            System.debug('Route: ' + route);
            return route;
        }
        
        return '';
    }
    */
    
    // Keeps the full route after the base path so GET sub-routes like get-products/{id} are parsed correctly.
    // This is a routing fix only; it does not change the endpoint business logic.
    /** Matches @RestResource urlMapping (path after host, without /services/apexrest). */
    private static final String URL_MAPPING_PREFIX = '/api/v1/small-group-enrollment';

    private static String trimLeadingSlash(String s) {
        if (String.isBlank(s)) {
            return '';
        }
        return s.startsWith('/') ? s.substring(1) : s;
    }

    private static String pathAfterBase() {
        String uri = RestContext.request.requestURI;
        System.debug('Full URI: ' + uri);

        if (String.isBlank(uri)) {
            return '';
        }
        Integer q = uri.indexOf('?');
        if (q != -1) {
            uri = uri.substring(0, q);
        }

        // Typical: /services/apexrest/api/v1/small-group-enrollment/save-enrollment
        String base = basePath();
        Integer baseIndex = uri.indexOf(base);
        if (baseIndex != -1) {
            String pathAfter = trimLeadingSlash(uri.substring(baseIndex + base.length()));
            System.debug('Path after base: ' + pathAfter);
            return pathAfter;
        }

        // Some call paths omit /services/apexrest; requestURI is only the urlMapping + route.
        Integer mapIndex = uri.indexOf(URL_MAPPING_PREFIX);
        if (mapIndex != -1) {
            String pathAfter = trimLeadingSlash(uri.substring(mapIndex + URL_MAPPING_PREFIX.length()));
            System.debug('Path after base (urlMapping only): ' + pathAfter);
            return pathAfter;
        }

        return '';
    }

    private static void json(Integer code, Object body) {
        RestResponse res = RestContext.response;
        res.statusCode = code;
        res.addHeader('Content-Type', 'application/json; charset=UTF-8');
        res.responseBody = Blob.valueOf(JSON.serialize(body));
    }

    //Declared methods for the endpoints to return the response in the correct format   
    //200 - OK
    //201 - Created
    //204 - No Content
    //400 - Bad Request
    //404 - Not Found
    //500 - Internal Server Error
    private static void ok(Object data){ json(200, new Map<String,Object>{ 'status'=>'ok', 'data'=>data }); }
    private static void created(Object data){ json(201, new Map<String,Object>{ 'status'=>'ok', 'data'=>data }); }
    private static void noContent(){ json(204, new Map<String,Object>{ 'status'=>'ok', 'message'=>'Success' }); }
    private static void bad(String msg){ json(400, new Map<String,Object>{ 'status'=>'error', 'message'=>msg }); }
    /** Return 400 when products payload is an error response from Alt/non-Alt service (do not return 200). */
    private static Boolean isProductsError(Map<String, Object> productsData) {
        return productsData != null && productsData.containsKey('error') && productsData.get('error') != null;
    }
    private static void notFound(String msg){ json(404, new Map<String,Object>{ 'status'=>'error', 'message'=>msg }); }
    private static void fail(Exception e){ json(500, new Map<String,Object>{ 'status'=>'error', 'message'=>e.getMessage() }); }

    // ---- GET: e.g. /.../get-products/{memberId}
    @HttpGet
    global static void get() {
        try {
            String route = pathAfterBase(); // e.g. get-products/003XXXXXXXXXXXX
            List<String> seg = route.split('/');
            
            if (seg.size() >= 2 && seg[0] == 'get-products') {
                String memberId = seg[1];
                if (String.isBlank(memberId)) {
                    bad('Member ID is required');
                    return;
                }
                
                try {
                    // Validate member ID format
                    Id primaryCensusMemberId;
                    try {
                        primaryCensusMemberId = (Id)memberId;
                    } catch (Exception e) {
                        bad('Invalid member ID format');
                        return;
                    }
                    
                    // Query member data from Salesforce and build member data list
                    List<ARC_getRatedProductsWithContributions.MemberInput> memberDataList = buildMemberDataFromId(primaryCensusMemberId);
                    
                    // Call ARC_getRatedProductsWithContributions to get priced products
                    String productsJson = ARC_getRatedProductsWithContributions.getProductsWithContributionsJson(memberDataList);
                    
                    // Parse JSON to return as structured response
                    Map<String, Object> productsData = (Map<String, Object>)JSON.deserializeUntyped(productsJson);
                    if (isProductsError(productsData)) {
                        bad((String)productsData.get('error'));
                        return;
                    }
                    ok(new Map<String,Object>{ 
                        'Status'=>'200', 
                        'StatusMessage'=>'Products retrieved successfully',
                        'products' => productsData
                    });
                    return;
                } catch (EnrollmentServiceException e) {
                    bad(e.getMessage());
                    return;
                } catch (Exception e) {
                    System.debug('Error getting products: ' + e.getMessage());
                    System.debug('Stack trace: ' + e.getStackTraceString());
                    bad('Error retrieving products: ' + e.getMessage());
                    return;
                }
            } 
            
            if (route == 'get-existing-data') {
                try {
                    Map<String,Object> body = (Map<String,Object>)JSON.deserializeUntyped(RestContext.request.requestBody.toString());
                    String primaryIdStr = (String)body.get('primaryId');
                    System.debug('primaryId ---> ' + primaryIdStr);
                    if (String.isBlank(primaryIdStr)) {
                        system.debug('primaryIdStr is blank');
                        bad('primaryId is required');
                        return;
                    }
                    Id primaryIdTyped;
                    try {
                        primaryIdTyped = (Id)primaryIdStr;
                    } catch (Exception e) {
                        system.debug('Error getting policy by member id: ' + e.getMessage());
                        system.debug('Stack trace: ' + e.getStackTraceString());
                        bad('Invalid primaryId format');
                        return;
                    }
                    system.debug('primaryIdTyped: ' + primaryIdTyped);
                    Id censusMemberId = resolveCensusMemberId(primaryIdTyped);
                    if (censusMemberId == null) {
                        bad('Unable to resolve census member for primaryId: ' + primaryIdStr);
                        return;
                    }
                    Map<String, Object> memberData = getMemberBasicInformation(censusMemberId);
                    Map<String, Object> generalInformation = new Map<String, Object>{
                        'accountId' => memberData.get('accountId'),
                        'censusId' => memberData.get('censusId'),
                        'groupAccountId' => memberData.get('groupAccountId'),
                        'contractId' => memberData.get('contractId'),
                        // Same census member resolved from primaryId (employee row), not another employee on the group census.
                        'primaryCensusMemberId' => String.valueOf(censusMemberId),
                        'effectiveDate' => memberData.get('effectiveDate')
                    };
                    // Policy resolved inside getMemberBasicInformation via status priority logic
                    Id policyId = memberData.containsKey('policyId') ? (Id)memberData.get('policyId') : null;
                    Map<String, Object> existingDataParsed = policyId != null ? buildEnrollmentDataJson(policyId) : null;

                    ok(new Map<String,Object>{
                        'Status'=>'200',
                        'StatusMessage' => existingDataParsed != null ? 'Member and existing data retrieved successfully' : 'Member data retrieved successfully. There is no policy for the specified Member',
                        'memberData' => memberData,
                        'effectiveDate' => memberData.get('effectiveDate'),
                        'authenticateSSN' => memberData.get('authenticateSSN'),
                        'ARC_AllowDependents__c' => memberData.get('allowEnrollmentDependents'),
                        'allowLegacy' => memberData.containsKey('allowLegacy') && memberData.get('allowLegacy') != null ? memberData.get('allowLegacy') : false,
                        'generalInformation' => generalInformation,
                        'existingData' => existingDataParsed
                    });
                    return;
                } catch (EnrollmentServiceException e) {
                    bad(e.getMessage());
                    return;
                } catch (Exception e) {
                    System.debug('Error getting existing data: ' + e.getMessage());
                    System.debug('Stack trace: ' + e.getStackTraceString());
                    bad('Error retrieving existing data: ' + e.getMessage());
                }
            }
            
            bad('Unknown GET route');
        } catch (Exception e) { fail(e); }
    }

    // ---- POST: e.g. /.../get-products
    @HttpPost
    global static void post() {
        try {
      
            String route = pathAfterBase(); // e.g. get-products
            Map<String,Object> body = (Map<String,Object>)JSON.deserializeUntyped(RestContext.request.requestBody.toString());
            System.debug('body: '+body);
            
            // Check if the route is 'get-products'
            if (route == 'get-products') {
                if (body == null) {
                    bad('Request body is required');
                    return;
                }
                
                // Extract memberData from request body (array of member objects)
                List<Object> memberDataList = (List<Object>)body.get('memberData');
                if (memberDataList == null || memberDataList.isEmpty()) {
                    bad('memberData array is required in request body');
                    return;
                }
                
                try {
                    // Convert memberData to JSON string
                    String memberDataJson = JSON.serialize(memberDataList); 
                    System.debug('Member Data JSON: ' + memberDataJson);
                    
                    // Call ARC_getRatedProductsWithContributions to get priced products
                    String productsJson = ARC_getRatedProductsWithContributions.getProductsWithContributionsJsonFromString(memberDataJson);
                    
                    // Parse JSON to return as structured response
                    Map<String, Object> productsData = (Map<String, Object>)JSON.deserializeUntyped(productsJson);
                    if (isProductsError(productsData)) {
                        bad((String)productsData.get('error'));
                        return;
                    }
                    ok(new Map<String,Object>{  
                        'Status'=>'200', 
                        'StatusMessage'=>'Products retrieved successfully',
                        'products' => productsData
                    });
                    return;
                } catch (Exception e) {
                    System.debug('Error getting products: ' + e.getMessage());
                    System.debug('Stack trace: ' + e.getStackTraceString());
                    String msg = e.getMessage();
                    if (msg != null && msg.contains('VisualForce or Aura')) {
                        bad('Validation failed: primary census member not found or invalid member data.');
                    } else {
                        bad(msg != null ? msg : 'Error retrieving products.');
                    }
                    return;
                }
            }
            if (route == 'get-products-alt') {
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
                    String memberDataJson = JSON.serialize(memberDataList);
                    System.debug('Member Data JSON: ' + memberDataJson);
                    String productsJson = ARC_getRatedProductsWithContributions.getProductsWithContributionsJsonFromString(memberDataJson);
                    Map<String, Object> productsData = (Map<String, Object>)JSON.deserializeUntyped(productsJson);
                    if (isProductsError(productsData)) {
                        bad((String)productsData.get('error'));
                        return;
                    }
                    ok(new Map<String,Object>{
                        'Status'=>'200',
                        'StatusMessage'=>'Products retrieved successfully',
                        'products' => productsData
                    });
                    return;
                } catch (Exception e) {
                    System.debug('Error getting products alt: ' + e.getMessage());
                    System.debug('Stack trace: ' + e.getStackTraceString());
                    String msg = e.getMessage();
                    if (msg != null && msg.contains('VisualForce or Aura')) {
                        bad('Validation failed: primary census member not found or invalid member data.');
                    } else {
                        bad(msg != null ? msg : 'Error retrieving products.');
                    }
                    return;
                }
            }
            else if (route == 'save-enrollment') {
                if (body == null) {
                    bad('Enrollment data is required');
                    return;
                }
                
                DateTime startTime = DateTime.now();
                Map<String, Object> serviceResponse = new Map<String, Object>();
                
                String logId = ARC_SGSelfEnrollmentHelper.createIntegrationLog('save-enrollment', body);
                
                // Step 1: Validate enrollment data using validateEnrollmentData method from ARC_SGSelfEnrollmentHelper
                Map<String, Object> outputMap = new Map<String, Object>();
                Map<String, Object> validationResult = ARC_SGSelfEnrollmentHelper.validateEnrollmentData(body, outputMap);
                System.debug('validationResult: ' + validationResult);
                
                
                if (!(Boolean)validationResult.get('success')) {
                    String errorMessage = (String)validationResult.get('errorMessage');
                    System.debug('Enrollment validation failed: ' + errorMessage);
                    bad(errorMessage);
                    return;
                }                
                
                ok(new Map<String,Object>{ 
                    'Status'=>'200', 
                    'StatusMessage'=>'Enrollment data validated successfully. Processing will continue in background.'
                });             

                
                if (logId == null) {
                    System.debug('Error creating integration log record after response');
                    return;
                }
                 
    
             
                try {
                    outputMap = new Map<String, Object>();
                    serviceResponse = ARC_SGSEBaseService.processSmallGroupSelfEnrollment(body, outputMap);
                    System.debug('serviceResponse: ' + serviceResponse);
                } catch (Exception e) {
                    System.debug('Error calling ARC_SGSEBaseService.processSmallGroupSelfEnrollment: ' + e.getMessage());
                    serviceResponse.put('success', false);
                    serviceResponse.put('errorMessage', e.getMessage());
                    serviceResponse.put('errorStackTrace', e.getStackTraceString());
                }
                Id groupAccountId = serviceResponse.containsKey('groupAccountId') ? (Id)serviceResponse.get('groupAccountId') : null ;
                String groupAccountName = serviceResponse.containsKey('groupAccountId') ? (String)serviceResponse.get('groupAccountName') : 'Not Found.';



                
                // Update integration log with results
                DateTime endTime = DateTime.now();
                Long durationMs = endTime.getTime() - startTime.getTime();
                serviceResponse.put('processedAt', endTime);
                
                try {
                    Boolean isSuccess = (Boolean)serviceResponse.get('success');
                    if (isSuccess == true) {
                        ARC_SGSelfEnrollmentHelper.updateIntegrationLog(logId, true, 200, null, null, endTime, durationMs, groupAccountId, groupAccountName);
                        System.debug('Enrollment processing completed successfully after response');
                    } else {
                        String errorMessage = (String)serviceResponse.get('errorMessage');
                        ARC_SGSelfEnrollmentHelper.updateIntegrationLog(logId, false, 500, 'SERVICE_ERROR', errorMessage, endTime, durationMs, groupAccountId, groupAccountName);
                        System.debug('Error processing self enrollment data save after response: ' + errorMessage);
                    }
                } catch (Exception e) {
                    ARC_SGSelfEnrollmentHelper.updateIntegrationLog(logId, false, 500, 'EXCEPTION', e.getMessage(), endTime, durationMs, groupAccountId, groupAccountName);
                    System.debug('Exception during enrollment processing after response: ' + e.getMessage());
                }
            }
            else {
                bad('Unknown POST route:' + route);
                return;
            }
        } catch (Exception e) { fail(e); }
    }
 
    // ---- PUT: e.g. /.../enrollments/{id}
    @HttpPut
    global static void put() {
        try {
            String path = pathAfterBase(); // enrollments/{id}
            List<String> seg = path.split('/');
            if (seg.size() >= 2 && seg[0] == 'enrollments') {
                String id = seg[1];
                if (!isValidId(id)) { bad('Invalid or missing enrollmentId'); return; }
                Map<String,Object> body = (Map<String,Object>)JSON.deserializeUntyped(RestContext.request.requestBody.toString());
                String status = (String)body.get('status');

                // TODO: update logic
                ok(new Map<String,Object>{ 'message'=>'Enrollment updated', 'enrollmentId'=>id, 'newStatus'=>status });
                return;
            }
            bad('Unknown PUT route');
        } catch (Exception e) { fail(e); }
    }

    // ---- Helpers ----
    private static Boolean isValidId(String s) {
        if (String.isBlank(s)) return false;
        if (!Pattern.matches('^[a-zA-Z0-9]{15,18}$', s)) return false;
        // Optional: ensure it exists
        try { Id tmp = (Id)s; return true; } catch (Exception ex) { return false; }
    }
    
    // Exposed to tests only so the internal member-building logic can be validated without depending on the full REST route.
    /**
     * Builds member data list from a primary census member ID by querying Salesforce
     * This is used for backward compatibility when only the member ID is provided
     */
    @TestVisible
    private static List<ARC_getRatedProductsWithContributions.MemberInput> buildMemberDataFromId(Id primaryCensusMemberId) {
        List<ARC_getRatedProductsWithContributions.MemberInput> memberDataList = new List<ARC_getRatedProductsWithContributions.MemberInput>();
        
        // Query primary member
        List<vlocity_ins__GroupCensusMember__c> primaryMembers = [
            SELECT Id, 
                   Name,
                   ARC_AgeInSixMonths__c,
                   vlocity_ins__IsPrimaryMember__c,
                   vlocity_ins__CensusId__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE Id = :primaryCensusMemberId
            AND vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];
        
        if (primaryMembers.isEmpty()) {
            throw new EnrollmentServiceException('Primary census member not found');
        }
        
        vlocity_ins__GroupCensusMember__c primaryMember = primaryMembers[0];
        Integer primaryAge = primaryMember.ARC_AgeInSixMonths__c != null ? 
            primaryMember.ARC_AgeInSixMonths__c.intValue() : 0;
        
        // Add primary member to list
        ARC_getRatedProductsWithContributions.MemberInput primaryInput = new ARC_getRatedProductsWithContributions.MemberInput();
        primaryInput.Name = primaryMember.Name;
        primaryInput.Age = primaryAge;
        primaryInput.PrimaryAge = primaryAge;
        primaryInput.IsPrimary = true;
        primaryInput.PrimaryId = String.valueOf(primaryMember.Id);
        primaryInput.IsLegacy = false;
        memberDataList.add(primaryInput);
        
        // Query dependent members
        List<vlocity_ins__GroupCensusMember__c> dependents = [
            SELECT Id,
                   Name, 
                   ARC_AgeInSixMonths__c,
                   vlocity_ins__IsPrimaryMember__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__CensusId__c = :primaryMember.vlocity_ins__CensusId__c
            AND vlocity_ins__IsPrimaryMember__c = false
        ];
        
        // Add dependents to list
        for (vlocity_ins__GroupCensusMember__c dependent : dependents) {
            ARC_getRatedProductsWithContributions.MemberInput depInput = new ARC_getRatedProductsWithContributions.MemberInput();
            depInput.Name = dependent.Name;
            depInput.Age = dependent.ARC_AgeInSixMonths__c != null ? 
                dependent.ARC_AgeInSixMonths__c.intValue() : 0;
            depInput.PrimaryAge = primaryAge;
            depInput.IsPrimary = false;
            depInput.PrimaryId = String.valueOf(primaryMember.Id);
            depInput.IsLegacy = false;
            memberDataList.add(depInput);
        }
        
        return memberDataList;
    }

    // Exposed to tests only so the member mapping logic can be validated directly with generated test data.
    private static List<Account> queryPersonAccountForCensusMember(Id censusMemberId) {
        List<Account> accountList = [
            SELECT Id,
                   FirstName,
                   vlocity_ins__MiddleName__pc,
                   LastName,
                   ARC_GroupAccount__c,
                   ARC_GroupAccount__r.ARC_AllowDependents__c,
                   vlocity_ins__Email__c,
                   Phone,
                   PersonBirthdate,
                   PersonGender,
                   ARC_Smoker__c,
                   vlocity_ins__SocialSecurityNumber__pc,
                   Census_Member__r.ARC_HeightFeet__c,
                   Census_Member__r.ARC_HeightInches__c,
                   Census_Member__r.ARC_Weight__c,
                   Census_Member__r.ARC_RequestedEffectiveDate__c,
                   vlocity_ins__EmploymentStatus__pc,
                   ARC_EmployeeType__c,
                   ARC_EmployeeDivision__c,
                   vlocity_ins__Age__pc,
                   Census_Member__r.vlocity_ins__CensusId__c,
                   Census_Member__r.vlocity_ins__GroupClassId__c
            FROM Account
            WHERE Census_Member__c = :censusMemberId
            LIMIT 1
        ];
        if (!accountList.isEmpty()) {
            return accountList;
        }

        List<vlocity_ins__GroupCensusMember__c> censusMembers = [
            SELECT vlocity_ins__ContactId__r.AccountId
            FROM vlocity_ins__GroupCensusMember__c
            WHERE Id = :censusMemberId
            LIMIT 1
        ];
        if (censusMembers.isEmpty()
            || censusMembers[0].vlocity_ins__ContactId__r == null
            || censusMembers[0].vlocity_ins__ContactId__r.AccountId == null) {
            return accountList;
        }

        return [
            SELECT Id,
                   FirstName,
                   vlocity_ins__MiddleName__pc,
                   LastName,
                   ARC_GroupAccount__c,
                   ARC_GroupAccount__r.ARC_AllowDependents__c,
                   vlocity_ins__Email__c,
                   Phone,
                   PersonBirthdate,
                   PersonGender,
                   ARC_Smoker__c,
                   vlocity_ins__SocialSecurityNumber__pc,
                   Census_Member__r.ARC_HeightFeet__c,
                   Census_Member__r.ARC_HeightInches__c,
                   Census_Member__r.ARC_Weight__c,
                   Census_Member__r.ARC_RequestedEffectiveDate__c,
                   vlocity_ins__EmploymentStatus__pc,
                   ARC_EmployeeType__c,
                   ARC_EmployeeDivision__c,
                   vlocity_ins__Age__pc,
                   Census_Member__r.vlocity_ins__CensusId__c,
                   Census_Member__r.vlocity_ins__GroupClassId__c
            FROM Account
            WHERE Id = :censusMembers[0].vlocity_ins__ContactId__r.AccountId
            LIMIT 1
        ];
    }

    /**
     * Get basic member information needed to pre-populate the flow fields.
     * Expects census member Id (vlocity_ins__GroupCensusMember__c); resolves Person Account via Census_Member__c,
     * then gets ARC_AllowDependents__c from the group account (Account.ARC_GroupAccount__r).
     */
    @TestVisible
    private static Map<String, Object> getMemberBasicInformation(Id censusMemberId) {
        System.debug('censusMemberId:' + censusMemberId);
        List<Account> accountList = queryPersonAccountForCensusMember(censusMemberId);
        if (accountList.isEmpty()) {
            throw new EnrollmentServiceException(
                'Census member or associated person account not found for Id: ' + censusMemberId
            );
        }
        Account memberData = accountList[0];

        System.debug('memberData:' + memberData);

        // try{
        //     InsurancePolicy policyData = [SELECT Id,
        //     ARC_Contract__r.ARC_OpenEnrollmentPeriod__c
        //     FROM InsurancePolicy
        //     WHERE NameInsuredId = :memberData.ARC_GroupAccount__c
        //     ORDER BY CreatedDate DESC
        //     LIMIT 1];
        //     System.debug('policyData:' + policyData);
        // } catch (Exception e) {
        //     System.debug('Error getting policy data: ' + e.getMessage());
        //     System.debug('Stack trace: ' + e.getStackTraceString());
        // }
 
        // Store the member information in a map
        Map<String, Object> memberInfo = new Map<String, Object>();
        memberInfo.put('firstName', memberData.FirstName);
        memberInfo.put('middleName', memberData.vlocity_ins__MiddleName__pc);
        memberInfo.put('lastName', memberData.LastName);
        memberInfo.put('accountId', memberData.Id);
        memberInfo.put('groupAccountId', memberData.ARC_GroupAccount__c);
        memberInfo.put('email', memberData.vlocity_ins__Email__c);
        memberInfo.put('phone', memberData.Phone);
        memberInfo.put('dob', memberData.PersonBirthdate);
        memberInfo.put('gender', memberData.PersonGender);
        memberInfo.put('smoker', memberData.ARC_Smoker__c);
        // ARC_AllowDependents__c is on the group account (ARC_GroupAccount__r)
        Boolean allowDependents = (memberData.ARC_GroupAccount__r != null)
        ? memberData.ARC_GroupAccount__r.ARC_AllowDependents__c
        : null;
        memberInfo.put('allowEnrollmentDependents', allowDependents);
        memberInfo.put('authenticateSSN', memberData.vlocity_ins__SocialSecurityNumber__pc);
        memberInfo.put('heightFeet', memberData.Census_Member__r.ARC_HeightFeet__c);
        memberInfo.put('heightInches', memberData.Census_Member__r.ARC_HeightInches__c);
        memberInfo.put('weight', memberData.Census_Member__r.ARC_Weight__c);
        memberInfo.put('censusId', memberData.Census_Member__r.vlocity_ins__CensusId__c);

        //memberInfo.put('insideOpenEnrollment', policyData.ARC_Contract__r.ARC_OpenEnrollmentPeriod__c);
        // Pricing fields
        /*
        memberInfo.put('pricingFields', new Map<String, Object> {
            // 'employmentStatus' => memberData.vlocity_ins__EmploymentStatus__pc,      this is going to be replaced for (Employment -> COBRA | RETIRED)
            //'employeeType' => memberData.ARC_EmployeeType__c,
            //'employeeDivision' => memberData.ARC_EmployeeDivision__c,
            'age' => memberData.vlocity_ins__Age__pc
        });
        */

        //Contract resolution
        List<Contract> cntList = [
            SELECT Id, Status, ARC_EffectiveDate__c, ARC_Inactive_Date__c
            FROM Contract
            WHERE AccountId = :memberData.ARC_GroupAccount__c
              AND Status IN ('Enrollment In Progress', 'Awaiting First Payment', 'Awaiting Activation', 'Activated')
        ];

        Contract cnt;
        Date memberReqDate = memberData?.Census_Member__r?.ARC_RequestedEffectiveDate__c;

        if (!cntList.isEmpty()) {
            if (cntList.size() == 1) {
                cnt = cntList[0];
            } else {
                // More than one contract — try date-range match first
                if (memberReqDate != null) {
                    List<Contract> dateMatches = new List<Contract>();
                    for (Contract c : cntList) {
                        Boolean afterStart = c.ARC_EffectiveDate__c == null || c.ARC_EffectiveDate__c <= memberReqDate;
                        Boolean beforeEnd  = c.ARC_Inactive_Date__c == null  || memberReqDate <= c.ARC_Inactive_Date__c;
                        if (afterStart && beforeEnd) {
                            dateMatches.add(c);
                        }
                    }
                    if (dateMatches.size() == 1) {
                        cnt = dateMatches[0];
                    }
                }
                // If date-range match didn't resolve, use priority tiebreaker
                if (cnt == null) {
                    Map<String, Integer> priorityMap = new Map<String, Integer>{
                        'Enrollment In Progress' => 1,
                        'Awaiting First Payment'  => 2,
                        'Awaiting Activation'     => 3,
                        'Activated'               => 4
                    };
                    Integer bestPriority = 999;
                    for (Contract c : cntList) {
                        Integer p = priorityMap.containsKey(c.Status) ? priorityMap.get(c.Status) : 999;
                        if (p < bestPriority) {
                            bestPriority = p;
                            cnt = c;
                        }
                    }
                }
            }

            memberInfo.put('contractId', cnt.Id);
            if (cnt.Status == 'Enrollment In Progress') {
                memberInfo.put('effectiveDate', cnt.ARC_EffectiveDate__c);
            } else {
                memberInfo.put('effectiveDate', memberReqDate);
            }
        } else {
            memberInfo.put('contractId', null);
            memberInfo.put('effectiveDate', memberReqDate);
        }

        //Group class resolution
       
        Id groupClassId = ARC_getRatedProductsWithContributions.resolveCmgcGroupClassId(censusMemberId, cnt.Id);
        memberInfo.put('primaryCensusMemberId', censusMemberId);

        // Check if member has legacy (senior) program available
        if (groupClassId != null) {
            Boolean hasSeniorProductAvailable = false;
            List<vlocity_ins__GroupClassContribution__c> groupClassContributionList = [SELECT ARC_ContractLineItem__r.vlocity_ins__ProductCode__c FROM vlocity_ins__GroupClassContribution__c WHERE vlocity_ins__GroupClassId__c =: groupClassId];
            if (!groupClassContributionList.isEmpty()) {
                for (vlocity_ins__GroupClassContribution__c gcc : groupClassContributionList) {
                    String productCode = gcc.ARC_ContractLineItem__r.vlocity_ins__ProductCode__c;
                    if (productCode != null && productCode.toLowerCase().contains('senior')) {
                        hasSeniorProductAvailable = true;
                        break;
                    }
                }
            }
            memberInfo.put('allowLegacy', hasSeniorProductAvailable);
        }

        // ---- Insurance Policy Resolution ----
        List<InsurancePolicy> policyList = [
            SELECT Id, Status
            FROM InsurancePolicy
            WHERE (ARC_EmployeeAccount__c = :memberData.Id OR NameInsuredId = :memberData.Id)
              AND Status IN ('Awaiting Signature', 'Awaiting Approval', 'Awaiting Activation', 'Activated')
        ];
        Id resolvedPolicyId = null;
        if (!policyList.isEmpty()) {
            InsurancePolicy selectedPolicy;
            if (policyList.size() == 1) {
                selectedPolicy = policyList[0];
            } else {
                Map<String, Integer> policyPriorityMap = new Map<String, Integer>{
                    'Awaiting Signature'   => 1,
                    'Awaiting Approval'    => 2,
                    'Awaiting Activation'  => 3,
                    'Activated'            => 4
                };
                Integer bestPolicyPriority = 999;
                for (InsurancePolicy pol : policyList) {
                    Integer p = policyPriorityMap.containsKey(pol.Status) ? policyPriorityMap.get(pol.Status) : 999;
                    if (p < bestPolicyPriority) {
                        bestPolicyPriority = p;
                        selectedPolicy = pol;
                    }
                }
            }
            resolvedPolicyId = selectedPolicy.Id;
        }
        memberInfo.put('policyId', resolvedPolicyId);

        return memberInfo;
    }

    /**
     * Resolve census member Id from either census member or account Id.
     */
    private static Id resolveCensusMemberId(Id primaryId) {
        if (primaryId == null) {
            return null;
        }
        if (primaryId.getSObjectType() == vlocity_ins__GroupCensusMember__c.SObjectType) {
            return primaryId;
        }
        if (primaryId.getSObjectType() == Account.SObjectType) {
            List<Account> accounts = [
                SELECT Census_Member__c
                FROM Account
                WHERE Id = :primaryId
                LIMIT 1
            ];
            if (!accounts.isEmpty()) {
                return accounts[0].Census_Member__c;
            }
        }
        return null;
    }

    /**
     * Get active policy associated with given member ID
     */
    private static InsurancePolicy getPolicyByMemberId(Id primaryId) {
        if (primaryId == null) {
            return null;
        }
        system.debug('primaryId: ' + primaryId);

        Id employeeAccountId = primaryId;
        system.debug('employeeAccountId: ' + employeeAccountId);
        if (primaryId.getSObjectType() == vlocity_ins__GroupCensusMember__c.SObjectType) {
            List<vlocity_ins__GroupCensusMember__c> censusRows = [
                SELECT vlocity_ins__AccountId__c
                FROM vlocity_ins__GroupCensusMember__c
                WHERE Id = :primaryId
                LIMIT 1
            ];
            if (censusRows.isEmpty() || censusRows[0].vlocity_ins__AccountId__c == null) {
                return null;
            } 
            employeeAccountId = censusRows[0].vlocity_ins__AccountId__c;
        }
        system.debug('policies: 1 ' + employeeAccountId);

        List<InsurancePolicy> policies = [
            SELECT Id, ARC_JsonSESG__c
            FROM InsurancePolicy
            WHERE ARC_EmployeeAccount__c = :employeeAccountId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        system.debug('policies: 2' + policies);
        if (policies.isEmpty()) {
            policies = [
                SELECT Id, ARC_JsonSESG__c
                FROM InsurancePolicy
                WHERE NameInsuredId = :employeeAccountId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        }
        system.debug('policies: 3' + policies);
        if (policies.isEmpty()) {
            return null;
        }

        return policies[0];
    }

    /**
     * Builds the enrollment pre-fill JSON from Policy and related records,
     * matching the structure expected by the website (same as ARC_JsonSESG__c).
     * Called by get-existing-data instead of reading ARC_JsonSESG__c directly.
     */
    @TestVisible
    public static Map<String, Object> buildEnrollmentDataJson(Id policyId) {
        // ---- SOQL 1: Policy + sub-selects ----
        List<InsurancePolicy> policies = [
            SELECT Id, NameInsuredId, ARC_GroupAccount__c,
                   ARC_Contract__c, ARC_PolicyEffectiveDate__c,
                   EmployeeContribution, EmployerContribution, ARC_IndividualPrice__c,
                   ARC_Guardian__c,
                   (SELECT Id, CoverageName, ARC_UnitPrice__c,
                           ARC_EmployeeContribution__c, ARC_EmployerContribution__c,
                           vlocity_ins_fsc__Product2Id__c, ARC_ParentPolicyCoverage__c
                    FROM InsurancePolicyCoverages),
                   (SELECT Id, PrimaryParticipantContactId,
                           Role
                    FROM InsurancePolicyParticipants)
            FROM InsurancePolicy
            WHERE Id = :policyId
            LIMIT 1
        ];
        if (policies.isEmpty()) return null;
        InsurancePolicy policy = policies[0];

        // ---- ARC_PayPeriod__c lives on the Group Account ----
        String payPeriod = null;
        if (policy.ARC_GroupAccount__c != null) {
            List<Account> groupAccounts = [SELECT ARC_PayPeriod__c FROM Account WHERE Id = :policy.ARC_GroupAccount__c LIMIT 1];
            if (!groupAccounts.isEmpty()) payPeriod = groupAccounts[0].ARC_PayPeriod__c;
        }

        // ---- medicalProgram: parent coverages ----
        Map<String, Object> medicalProgram = new Map<String, Object>();
        Map<Id, Boolean> coverageIsLegacy = new Map<Id, Boolean>();
        for (InsurancePolicyCoverage cov : policy.InsurancePolicyCoverages) {
            if (cov.ARC_ParentPolicyCoverage__c != null) continue;
            String cName = cov.CoverageName != null ? cov.CoverageName.toLowerCase() : '';
            coverageIsLegacy.put(cov.Id, cName.contains('senior') || cName.contains('legacy'));
            medicalProgram.put(cov.CoverageName, new Map<String, Object>{
                'productId'              => cov.vlocity_ins_fsc__Product2Id__c,
                'basePrice'              => cov.ARC_UnitPrice__c,
                'priceWithContributions' => cov.ARC_EmployeeContribution__c,
                'individualPrice'        => policy.ARC_IndividualPrice__c,
                'tierFactorValue'        => 1,
                'contributionType'       => 'Amount',
                'employeeSplit'          => cov.ARC_EmployeeContribution__c,
                'employerSplit'          => cov.ARC_EmployerContribution__c,
                'ARC_PayPeriod__c'       => payPeriod  // same value, comes from Group Account
            });
        }

        // ---- SOQL 2: Accounts for participants ----
        Set<Id> contactIds = new Set<Id>();
        Map<Id, String> contactToRole = new Map<Id, String>();
        for (InsurancePolicyParticipant p : policy.InsurancePolicyParticipants) {
            if (p.PrimaryParticipantContactId != null) {
                contactIds.add(p.PrimaryParticipantContactId);
                contactToRole.put(p.PrimaryParticipantContactId, p.Role);
            }
        }
        Map<Id, Account> contactToAccount = new Map<Id, Account>();
        Map<Id, Account> censusMemberToAccount = new Map<Id, Account>();
        if (!contactIds.isEmpty()) {
            for (Account acc : [
                SELECT Id, PersonContactId, FirstName, vlocity_ins__MiddleName__pc, LastName,
                       PersonEmail, Phone, PersonBirthdate, PersonGender, ARC_Smoker__c,
                       ARC_IsPregnant__c,
                       vlocity_ins__SocialSecurityNumber__pc,
                       BillingStreet, BillingCity, BillingState, BillingPostalCode,
                       Census_Member__c,
                       Census_Member__r.ARC_HeightFeet__c,
                       Census_Member__r.ARC_HeightInches__c,
                       Census_Member__r.ARC_Weight__c,
                       Census_Member__r.vlocity_ins__CensusId__c
                FROM Account
                WHERE PersonContactId IN :contactIds
            ]) {
                contactToAccount.put(acc.PersonContactId, acc);
                if (acc.Census_Member__c != null) censusMemberToAccount.put(acc.Census_Member__c, acc);
            }
        }

        // Primary account: signerEmail, censusId, primaryCensusMemberId
        String signerEmail = null;
        String censusIdStr = null;
        String primaryCensusMemberIdStr = null;
        Account primaryAccount = null;
        Id primaryContactId = null;
        for (Id cId : contactToRole.keySet()) {
            String role = contactToRole.get(cId);
            if (role == 'Named Insured' || role == 'Primary') {
                Account pa = contactToAccount.get(cId);
                if (pa != null) {
                    primaryAccount = pa;
                    primaryContactId = cId;
                    signerEmail = pa.PersonEmail;
                    if (pa.Census_Member__r != null && pa.Census_Member__r.vlocity_ins__CensusId__c != null) {
                        censusIdStr = String.valueOf(pa.Census_Member__r.vlocity_ins__CensusId__c);
                    }
                    if (pa.Census_Member__c != null) {
                        primaryCensusMemberIdStr = String.valueOf(pa.Census_Member__c);
                    }
                }
                break;
            }
        }

        // ---- SOQL 3: Guardian Account ----
        Map<String, Object> guardianMap = null;
        Id guardianPersonContactId = null;
        if (policy.ARC_Guardian__c != null) {
            List<Account> guardians = [
                SELECT PersonContactId, FirstName, vlocity_ins__MiddleName__pc, LastName,
                       Phone, PersonEmail, PersonBirthdate, PersonGender,
                       ARC_SocialSecurityNumber__c, ARC_GuardianRelationshipToChild__c,
                       BillingStreet, BillingCity, BillingState, BillingPostalCode
                FROM Account
                WHERE Id = :policy.ARC_Guardian__c
                LIMIT 1
            ];
            if (!guardians.isEmpty()) {
                Account g = guardians[0];
                guardianPersonContactId = g.PersonContactId;
                guardianMap = new Map<String, Object>{
                    'firstName'     => g.FirstName,
                    'middleInitial' => g.vlocity_ins__MiddleName__pc != null ? g.vlocity_ins__MiddleName__pc : '',
                    'lastName'      => g.LastName,
                    'phone'         => g.Phone,
                    'email'         => g.PersonEmail,
                    'dob'           => g.PersonBirthdate != null ? String.valueOf(g.PersonBirthdate) : null,
                    'gender'        => g.PersonGender,
                    'ssn'           => g.ARC_SocialSecurityNumber__c,
                    'relationship'  => g.ARC_GuardianRelationshipToChild__c,
                    'address'       => new Map<String, Object>{
                        'street' => g.BillingStreet,
                        'city'   => g.BillingCity,
                        'state'  => g.BillingState,
                        'zip'    => g.BillingPostalCode
                    }
                };
            }
        }

        // ---- SOQL 4: HIPAA Authorizations ----
        List<Object> hipaaList = new List<Object>();
        for (ARC_HipaaAuthorization__c h : [
            SELECT ARC_AuthorizedMember__c,
                   ARC_ExternalPersonAuthorized__c,
                   ARC_ExternalPersonAuthorized__r.FirstName,
                   ARC_ExternalPersonAuthorized__r.LastName,
                   ARC_ExternalPersonAuthorized__r.Email,
                   ARC_ExternalPersonAuthorized__r.Phone,
                   ARC_ExternalPersonAuthorized__r.Birthdate,
                   ARC_ExternalPersonAuthorized__r.MailingStreet,
                   ARC_ExternalPersonAuthorized__r.MailingCity,
                   ARC_ExternalPersonAuthorized__r.MailingState,
                   ARC_ExternalPersonAuthorized__r.MailingPostalCode
            FROM ARC_HipaaAuthorization__c
            WHERE ARC_PrimaryAccount__c = :policy.NameInsuredId
        ]) {
            Map<String, Object> entry = new Map<String, Object>{ 'CHK_Authorized' => true };
            if (h.ARC_AuthorizedMember__c != null) {
                // Family member entry (Primary / Spouse / Child)
                Account ma = censusMemberToAccount.get(h.ARC_AuthorizedMember__c);
                if (ma != null) {
                    String rawMRole = contactToRole.get(ma.PersonContactId);
                    String mRole = rawMRole == 'Dependent' ? 'Child' : (rawMRole != null ? rawMRole : 'Primary');
                    entry.put('relationship', mRole);
                    entry.put('firstName',        ma.FirstName);
                    entry.put('middleInitial',    ma.vlocity_ins__MiddleName__pc != null ? ma.vlocity_ins__MiddleName__pc : '');
                    entry.put('lastName',         ma.LastName);
                    entry.put('email',            ma.PersonEmail);
                    entry.put('phone',            ma.Phone);
                    entry.put('dob',              ma.PersonBirthdate != null ? String.valueOf(ma.PersonBirthdate) : null);
                    entry.put('memberExternalId', String.valueOf(ma.PersonContactId));
                    entry.put('address', new Map<String, Object>{
                        'street' => ma.BillingStreet, 'city' => ma.BillingCity,
                        'state'  => ma.BillingState,  'zip'  => ma.BillingPostalCode
                    });
                    hipaaList.add(entry);
                }
            } else if (h.ARC_ExternalPersonAuthorized__c != null) {
                Boolean isGuardian = (guardianPersonContactId != null &&
                                      h.ARC_ExternalPersonAuthorized__c == guardianPersonContactId);
                entry.put('firstName',    h.ARC_ExternalPersonAuthorized__r.FirstName);
                entry.put('middleInitial','');
                entry.put('lastName',     h.ARC_ExternalPersonAuthorized__r.LastName);
                entry.put('email',        h.ARC_ExternalPersonAuthorized__r.Email);
                entry.put('phone',        h.ARC_ExternalPersonAuthorized__r.Phone);
                entry.put('address', new Map<String, Object>{
                    'street' => h.ARC_ExternalPersonAuthorized__r.MailingStreet,
                    'city'   => h.ARC_ExternalPersonAuthorized__r.MailingCity,
                    'state'  => h.ARC_ExternalPersonAuthorized__r.MailingState,
                    'zip'    => h.ARC_ExternalPersonAuthorized__r.MailingPostalCode
                });
                if (isGuardian) {
                    entry.put('relationship', guardianMap != null ? (String)guardianMap.get('relationship') : 'Legal Guardian');
                    entry.put('dob',  h.ARC_ExternalPersonAuthorized__r.Birthdate != null ? String.valueOf(h.ARC_ExternalPersonAuthorized__r.Birthdate) : null);
                    entry.put('ssn',  guardianMap != null ? (String)guardianMap.get('ssn') : null);
                    entry.put('memberId', '');
                } else {
                    entry.put('relationship', 'Third Party');
                    entry.put('DAT_DOB', h.ARC_ExternalPersonAuthorized__r.Birthdate != null ? String.valueOf(h.ARC_ExternalPersonAuthorized__r.Birthdate) : null);
                    entry.put('memberId', '');
                }
                hipaaList.add(entry);
            }
        }

        // ---- SOQL 5: External insurance per member ----
        Set<Id> memberAccountIds = new Set<Id>();
        for (Account acc : contactToAccount.values()) memberAccountIds.add(acc.Id);
        Map<Id, List<Map<String, Object>>> accountToCurrentCoverage = new Map<Id, List<Map<String, Object>>>();
        if (!memberAccountIds.isEmpty()) {
            for (ARC_ExternalInsurancePolicyMember__c em : [
                SELECT ARC_PersonAccount__c,
                       ARC_ExternalInsurancePolicy__r.ARC_InsurerName__c,
                       ARC_ExternalInsurancePolicy__r.ARC_PolicyNumber__c,
                       ARC_ExternalInsurancePolicy__r.ARC_InsurerPhone__c,
                       ARC_ExternalInsurancePolicy__r.ARC_EffectiveDate__c,
                       ARC_ExternalInsurancePolicy__r.ARC_ExpirationDate__c,
                       ARC_ExternalInsurancePolicy__r.ARC_SourceOfCoverage__c
                FROM ARC_ExternalInsurancePolicyMember__c
                WHERE ARC_PersonAccount__c IN :memberAccountIds
            ]) {
                if (!accountToCurrentCoverage.containsKey(em.ARC_PersonAccount__c)) {
                    accountToCurrentCoverage.put(em.ARC_PersonAccount__c, new List<Map<String, Object>>());
                }
                accountToCurrentCoverage.get(em.ARC_PersonAccount__c).add(new Map<String, Object>{
                    'carrier'       => em.ARC_ExternalInsurancePolicy__r.ARC_InsurerName__c,
                    'policyNumber'  => em.ARC_ExternalInsurancePolicy__r.ARC_PolicyNumber__c,
                    'carrierPhone'  => em.ARC_ExternalInsurancePolicy__r.ARC_InsurerPhone__c,
                    'effectiveDate' => em.ARC_ExternalInsurancePolicy__r.ARC_EffectiveDate__c != null ?
                        String.valueOf(em.ARC_ExternalInsurancePolicy__r.ARC_EffectiveDate__c) : null,
                    'expirationDate'=> em.ARC_ExternalInsurancePolicy__r.ARC_ExpirationDate__c != null ?
                        String.valueOf(em.ARC_ExternalInsurancePolicy__r.ARC_ExpirationDate__c) : null,
                    'coverageSource'=> em.ARC_ExternalInsurancePolicy__r.ARC_SourceOfCoverage__c,
                    'coverageType'  => 'Medical',
                    'status'        => 'Active'
                });
            }
        }

        // ---- SOQL 6: Beneficiaries from CoverageParticipants ----
        // mapPolicyParticipants stores InsurancePolicyParticipant.Id; we need to map
        // participantId -> beneficiary data.
        Set<Id> participantIds = new Set<Id>();
        for (InsurancePolicyParticipant p : policy.InsurancePolicyParticipants) participantIds.add(p.Id);
        Map<Id, Map<String, Object>> participantToBeneficiaries = new Map<Id, Map<String, Object>>();
        Map<Id, Boolean> participantIsLegacy = new Map<Id, Boolean>();
        if (!participantIds.isEmpty()) {
            for (ARC_CoverageParticipant__c cp : [
                SELECT ARC_PolicyParticipant__c,
                       ARC_PolicyCoverage__c,
                       ARC_PrimaryBeneficiaryName__c,
                       ARC_PrimaryBeneficiaryRelationship__c,
                       ARC_PrimaryBeneficiaryOther__c,
                       ARC_PrimaryBeneficiaryBirthdate__c,
                       ARC_PrimaryBeneficiaryPhone__c,
                       ARC_SecondaryBeneficiaryName__c,
                       ARC_SecondaryBeneficiaryRelationship__c,
                       ARC_SecondaryBeneficiaryOther__c,
                       ARC_SecondaryBeneficiaryBirthdate__c,
                       ARC_SecondaryBeneficiaryPhone__c
                FROM ARC_CoverageParticipant__c
                WHERE ARC_PolicyParticipant__c IN :participantIds
            ]) {
                // Per-member legacy detection
                if (cp.ARC_PolicyCoverage__c != null && coverageIsLegacy.get(cp.ARC_PolicyCoverage__c) == true) {
                    participantIsLegacy.put(cp.ARC_PolicyParticipant__c, true);
                }
                // Beneficiary mapping (only when beneficiary fields are present)
                if (cp.ARC_PrimaryBeneficiaryName__c == null && cp.ARC_SecondaryBeneficiaryName__c == null) continue;
                if (participantToBeneficiaries.containsKey(cp.ARC_PolicyParticipant__c)) continue;
                Map<String, Object> bens = new Map<String, Object>();
                if (cp.ARC_PrimaryBeneficiaryName__c != null) {
                    bens.put('primaryBeneficiary', new Map<String, Object>{
                        'fullname'          => cp.ARC_PrimaryBeneficiaryName__c,
                        'relationship'      => cp.ARC_PrimaryBeneficiaryRelationship__c,
                        'otherRelationship' => cp.ARC_PrimaryBeneficiaryOther__c,
                        'birthdate'         => cp.ARC_PrimaryBeneficiaryBirthdate__c != null ? String.valueOf(cp.ARC_PrimaryBeneficiaryBirthdate__c) : null,
                        'phone'             => cp.ARC_PrimaryBeneficiaryPhone__c
                    });
                }
                if (cp.ARC_SecondaryBeneficiaryName__c != null) {
                    bens.put('secondaryBeneficiary', new Map<String, Object>{
                        'fullname'          => cp.ARC_SecondaryBeneficiaryName__c,
                        'relationship'      => cp.ARC_SecondaryBeneficiaryRelationship__c,
                        'otherRelationship' => cp.ARC_SecondaryBeneficiaryOther__c,
                        'birthdate'         => cp.ARC_SecondaryBeneficiaryBirthdate__c != null ? String.valueOf(cp.ARC_SecondaryBeneficiaryBirthdate__c) : null,
                        'phone'             => cp.ARC_SecondaryBeneficiaryPhone__c
                    });
                }
                if (!bens.isEmpty()) participantToBeneficiaries.put(cp.ARC_PolicyParticipant__c, bens);
            }
        }

        // ---- Build members list ----
        List<Object> membersList = new List<Object>();
        for (InsurancePolicyParticipant participant : policy.InsurancePolicyParticipants) {
            if (participant.PrimaryParticipantContactId == null) continue;
            Account acc = contactToAccount.get(participant.PrimaryParticipantContactId);
            if (acc == null) continue;
            // mapPolicyParticipants normalises 'Child' -> 'Dependent' before storing;
            // reverse here so the website receives the original role value.
            String outRole = participant.Role == 'Dependent' ? 'Child' : participant.Role;
            Map<String, Object> memberEntry = new Map<String, Object>{
                'memberExternalId' => String.valueOf(participant.PrimaryParticipantContactId),
                'role'             => outRole,
                'currentCoverage'  => accountToCurrentCoverage.containsKey(acc.Id) ?
                    accountToCurrentCoverage.get(acc.Id) : new List<Object>(),
                'person'           => new Map<String, Object>{
                    'firstName'            => acc.FirstName,
                    'middleInitial'        => acc.vlocity_ins__MiddleName__pc != null ? acc.vlocity_ins__MiddleName__pc : '',
                    'lastName'             => acc.LastName,
                    'dob'                  => acc.PersonBirthdate != null ? String.valueOf(acc.PersonBirthdate) : null,
                    'gender'               => acc.PersonGender,
                    'email'                => acc.PersonEmail,
                    'phone'                => acc.Phone,
                    'ssn'                  => acc.vlocity_ins__SocialSecurityNumber__pc,
                    'heightFeet'           => acc.Census_Member__r != null ? acc.Census_Member__r.ARC_HeightFeet__c : null,
                    'heightInches'         => acc.Census_Member__r != null ? acc.Census_Member__r.ARC_HeightInches__c : null,
                    'weightLbs'            => acc.Census_Member__r != null ? acc.Census_Member__r.ARC_Weight__c : null,
                    'smoker'               => acc.ARC_Smoker__c != null ? acc.ARC_Smoker__c : false,
                    'pregnant'             => acc.ARC_IsPregnant__c != null ? acc.ARC_IsPregnant__c : false,
                    'isLegacy'             => participantIsLegacy.containsKey(participant.Id) && participantIsLegacy.get(participant.Id),
                    'sameAddressAsPrimary' => (
                        primaryAccount != null
                        && participant.PrimaryParticipantContactId != primaryContactId
                        && primaryAccount.BillingStreet != null
                        && acc.BillingStreet == primaryAccount.BillingStreet
                        && acc.BillingCity == primaryAccount.BillingCity
                        && acc.BillingState == primaryAccount.BillingState
                        && acc.BillingPostalCode == primaryAccount.BillingPostalCode
                    ),
                    'address'              => new Map<String, Object>{
                        'street' => acc.BillingStreet,
                        'city'   => acc.BillingCity,
                        'state'  => acc.BillingState,
                        'zip'    => acc.BillingPostalCode
                    }
                }
            };
            if (participantToBeneficiaries.containsKey(participant.Id)) {
                memberEntry.put('beneficiaries', participantToBeneficiaries.get(participant.Id));
            }
            membersList.add(memberEntry);
        }

        // ---- Assemble output ----
        return new Map<String, Object>{
            'options' => new Map<String, Object>{
                'useQueueableApexRemoting' => false,
                'queueableChainable'       => false,
                'ignoreCache'              => true,
                'resetCache'               => false,
                'chainable'                => false
            },
            'traceId'            => 'rawPayloadId',
            'enrollmentId'       => String.valueOf(policy.Id),
            'generalInformation' => new Map<String, Object>{
                'accountId'             => policy.NameInsuredId,
                'groupAccountId'        => policy.ARC_GroupAccount__c,
                'contractId'            => policy.ARC_Contract__c,
                'effectiveDate'         => policy.ARC_PolicyEffectiveDate__c != null ? String.valueOf(policy.ARC_PolicyEffectiveDate__c) : null,
                'totalMonthlyPremium'   => policy.EmployeeContribution,
                'signerEmail'           => signerEmail,
                'censusId'              => censusIdStr,
                'primaryCensusMemberId' => primaryCensusMemberIdStr,
                'medicalProgram'        => medicalProgram,
                'hipaa'                 => hipaaList,
                'guardian'              => guardianMap
            },
            'members'            => membersList
        };
    }

}