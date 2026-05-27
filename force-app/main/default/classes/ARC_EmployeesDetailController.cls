public with sharing class ARC_EmployeesDetailController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> getParticipantsFromAccount(String accountId) {
        InsurancePolicyParticipant[] participantPrimary = [
            SELECT Id, InsurancePolicyId,PrimaryParticipantContact.Account.BillingAddress 
            FROM InsurancePolicyParticipant 
            WHERE PrimaryParticipantContact.AccountId = :accountId 
            AND Role = 'Primary' AND InsurancePolicy.IsActive = true
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if(participantPrimary.isEmpty()) {
            return new List<Map<String,Object>>();
        }
        // Get participants
        List<InsurancePolicyParticipant> participants = [
            SELECT Id,
                   InsurancePolicyId,
                   Role,
                   PrimaryParticipantContactId,
                   PrimaryParticipantContact.Account.IsActive,
                   PrimaryParticipantContact.Account.vlocity_ins__SocialSecurityNumber__pc,
                   PrimaryParticipantContact.Account.PersonBirthdate, 
                   InsurancePolicy.ARC_EffectiveDate__c,
                   InsurancePolicy.Status, 
                   PrimaryParticipantContact.Name,
                   PrimaryParticipantContact.Account.BillingAddress,
                   PrimaryParticipantContact.Account.ARC_DependentRelationship__c,
                   PrimaryParticipantContact.Account.PersonGender,
                   PrimaryParticipantContact.Account.Account_ID_18__c 
            FROM InsurancePolicyParticipant 
            WHERE InsurancePolicyId =:participantPrimary[0].InsurancePolicyId 
            WITH SECURITY_ENFORCED 
            ];

        
        List<Map<String,Object>> participantsMapList = new List<Map<String,Object>>();
        for (InsurancePolicyParticipant participant : participants) {
            Map<String, Object> participantMap = new Map<String, Object>();
            participantMap.put('Id', participant.Id);
            participantMap.put('Name', participant.PrimaryParticipantContact.Name);
           // participantMap.put('ProductName', participant.InsurancePolicy.Product.Name);
            participantMap.put('Address', participant.PrimaryParticipantContact.Account.BillingAddress);
            participantMap.put('primaryParticipantAddress', participantPrimary[0].PrimaryParticipantContact.Account.BillingAddress);
            participantMap.put('Role', participant.Role);
            participantMap.put('ContactId', participant.PrimaryParticipantContactId);
            participantMap.put('PersonAccountId', participant.PrimaryParticipantContact.Account.Account_ID_18__c);
            participantMap.put('Gender', participant.PrimaryParticipantContact.Account.PersonGender);
            participantMap.put('DependentRelationship', participant.PrimaryParticipantContact.Account.ARC_DependentRelationship__c);
            participantMap.put('IsActive', participant.PrimaryParticipantContact.Account.IsActive);
            participantMap.put('Birthdate', participant.PrimaryParticipantContact.Account.PersonBirthdate != null ? participant.PrimaryParticipantContact.Account.PersonBirthdate: null);
            participantMap.put('SSN', participant.PrimaryParticipantContact.Account.vlocity_ins__SocialSecurityNumber__pc);
            
            
            participantsMapList.add(participantMap);
        }
        return participantsMapList;
    }

    /*
    *new method to get active QLEs for a contact
    */
    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getActiveQLEs(String accountId){

        RecordType caseRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'ARC_QualifyEvent' LIMIT 1];

        List<Case> activeQLEs = [
            SELECT Id, Status, Subject, arcsona__EventDate__c, CaseNumber, ARC_QLEType__c
            FROM Case
            WHERE ARC_PersonAccount__c = :accountId
            AND RecordTypeId = :caseRecordType.Id
            AND Status != 'Closed Voided'
            AND Subject = 'QLE'
            AND arcsona__EventDate__c != null
            ORDER BY arcsona__EventDate__c DESC
        ];

            List<Map<String, Object>> activeQLEList = new List<Map<String, Object>>();
            for(Case qle : activeQLEs){
                activeQLEList.add(new Map<String, Object>{
                    'Id'         => qle.Id,
                    'CaseNumber' => qle.CaseNumber,
                    'Status'     => qle.Status,
                    'QLEType'    => qle.ARC_QLEType__c
                });
            }
            return activeQLEList;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCurrentPolicy(String accountId) {
        // Variables
        Map<String, Object> output = new Map<String, Object>();
        InsurancePolicy bestPolicyOption = null;
        List<String> productNames = new List<String>();
        Map<Id, Date> policyToEffectiveDate = new Map<Id, Date>();

        // Get all Policies related to the Account
        List<InsurancePolicy> policies = [
            SELECT Id, 
                   Status,
                   ARC_EffectiveDate__c,
                   ARC_ExpirationDate__c,
                   ARC_TotalPremiumAmount__c
            FROM InsurancePolicy
            WHERE NameInsuredId = :accountId
        ];
        // Select the best Policy option
        for (InsurancePolicy policy : policies) {
            if (bestPolicyOption != null) {
                if (bestPolicyOption.Status == 'Activated') break;

                if (policy.Status == 'Activated') {
                    bestPolicyOption = policy;
                } else if (policy.Status.contains('Awaiting')) {
                    bestPolicyOption = policy;
                } else if (policy.Status == 'Terminated' && bestPolicyOption.Status == 'Terminated') {
                    if (policy.ARC_ExpirationDate__c < bestPolicyOption.ARC_ExpirationDate__c) {
                        bestPolicyOption = policy;
                    }
                }
            } else {
                bestPolicyOption = policy;
            }
        }

        // No policy found
        if (bestPolicyOption == null) {
            return new Map<String, Object>();
        }

        // Save the output
        output.put('InsurancePolicyId', bestPolicyOption.Id);
        output.put('Status', bestPolicyOption.Status);
        output.put('EffectiveDate', bestPolicyOption.ARC_EffectiveDate__c);
        output.put('TotalPremiumAmount', bestPolicyOption.ARC_TotalPremiumAmount__c);

        // Get the Coverages
        List<InsurancePolicyCoverage> coveragesList = [
            SELECT InsurancePolicyId,
                    vlocity_ins_fsc__Product2Id__r.Name,
                    ARC_ParentProduct__c,
                    ARC_EmployeeContribution__c,
                    ARC_EmployerContribution__c,
                    ARC_UnitPrice__c
            FROM InsurancePolicyCoverage
            WHERE InsurancePolicyId = :bestPolicyOption.Id
            AND ARC_ParentProduct__c = NULL 
            WITH SECURITY_ENFORCED
        ];

        for (InsurancePolicyCoverage coverage : coveragesList) {
            if (coverage.vlocity_ins_fsc__Product2Id__r != null) {
                productNames.add(coverage.vlocity_ins_fsc__Product2Id__r.Name);
            }
        }

        output.put('ProductNames for Policy', productNames);

        // Return the output
        return output;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getDownloadableData(String accountId) {
        // Variables
        List<Map<String, Object>> output = new List<Map<String, Object>>();
        InsurancePolicy bestPolicyOption = null;
        List<String> productNames = new List<String>();
        String productNamesString = '';
        Map<Id, Date> policyToEffectiveDate = new Map<Id, Date>();
        Map<Id, String> accountToProducts = new Map<Id, String>();
        Map<Id, Map<String,Object>> memberIdMap =  new  Map<Id,Map<String,Object>>();

        // Get all Policies related to the Account
        List<InsurancePolicy> policies = [
            SELECT Id, 
                   Status,
                   ARC_EffectiveDate__c,
                   ARC_ExpirationDate__c,
                   ARC_TotalPremiumAmount__c
            FROM InsurancePolicy
            WHERE NameInsuredId = :accountId
        ];

        // Select the best Policy option
        for (InsurancePolicy policy : policies) {
            if (bestPolicyOption != null) {
                if (bestPolicyOption.Status == 'Activated') break;
                if (policy.Status == 'Activated') {
                    bestPolicyOption = policy;
                } else if (policy.Status.contains('Awaiting')) {
                    bestPolicyOption = policy;
                } else if (policy.Status == 'Terminated' && bestPolicyOption.Status == 'Terminated') {
                    if (policy.ARC_ExpirationDate__c < bestPolicyOption.ARC_ExpirationDate__c) {
                        bestPolicyOption = policy;
                    }
                }
            } else {
                bestPolicyOption = policy;
            }
        }

        // Get the Coverages
        List<InsurancePolicyCoverage> coveragesList = [
            SELECT InsurancePolicyId,
                    vlocity_ins_fsc__Product2Id__r.Name,
                    ARC_EmployeeContribution__c,
                    ARC_EmployerContribution__c,
                    ARC_UnitPrice__c,
                    (SELECT Id, 
                        ARC_ParticipantName__c,
                        ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId
                    FROM Coverage_Participants__r)
            FROM InsurancePolicyCoverage
            WHERE InsurancePolicyId = :bestPolicyOption.Id
            AND ARC_ParentProduct__c = NULL 
            WITH SECURITY_ENFORCED
        ];

        for (InsurancePolicyCoverage policyCoverage : coveragesList) {
            for (ARC_CoverageParticipant__c coverageParticipant : policyCoverage.Coverage_Participants__r) {
                Id memberAccountId = coverageParticipant.ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId;
                String productName = policyCoverage.vlocity_ins_fsc__Product2Id__r.Name;
                Map<String,Object> memberMap = new Map<String,Object>{
                    'productName'=> productName,
                    'employerContribution'=> policyCoverage.ARC_EmployerContribution__c,
                    'employeeContribution'=> policyCoverage.ARC_EmployeeContribution__c,
                    'monthlyContribution'=> policyCoverage.ARC_UnitPrice__c
                };
                memberIdMap.put(memberAccountId,memberMap);
            }
        }

        // for (InsurancePolicyCoverage coverage : coveragesList) {
        //     if (coverage.vlocity_ins_fsc__Product2Id__r != null) {
        //         productNames.add(coverage.vlocity_ins_fsc__Product2Id__r.Name);
        //         productNamesString += coverage.vlocity_ins_fsc__Product2Id__r.Name + '|';
        //     }
        // }

        // productNamesString = productNamesString.removeEnd('|');

        // Get Accounts information
        List<Account> accountList = [
            SELECT Id,
                   RecordType.DeveloperName,
                   ARC_IsPrimaryMember__c,
                   FirstName,
                   vlocity_ins__MiddleName__pc,
                   LastName,
                   ARC_EmployeeDivision__c,
                   ARC_EmployeeType__c,
                   vlocity_ins__SocialSecurityNumber__pc,
                   PersonBirthdate,
                   ARC_HireDate__c,
                   ARC_TerminationDate__c,
                   ARC_JobTitle__c,
                   BillingAddress,
                   BillingStreet,
                   BillingCity,
                   BillingState,
                   BillingPostalCode,
                   BillingCountry,
                   Phone,
                   PersonEmail,
                   ARC_GroupAccount__r.ARC_PayPeriod__c,
                   Census_Member__r.ARC_ActiveMember__c,
                   ARC_DependentRelationship__c,
                   ARC_ContinuousMembershipStartDate__c,
                   Census_Member__r.vlocity_ins__GroupClassId__r.Name
            FROM Account
            WHERE Id = :accountId
            OR ARC_PrimaryMemberAccount__c = :accountId
        ];

        // Save the output
        for (Account member : accountList) {
            // Variables
            Map<String, Object> memberOutput = new Map<String, Object>();
            String enrollmentStatus = '';

            if (member.Census_Member__r.ARC_ActiveMember__c) {
                enrollmentStatus = 'Active';
            } else if (bestPolicyOption.Status.contains('Awaiting')) {
                enrollmentStatus = 'Awaiting';
            } else {
                enrollmentStatus = 'Inactive';
            }

            // Get the relationship
            String relationship = '';

            if (member.ARC_IsPrimaryMember__c) {
                relationship = 'Primary';
            } else if (member.RecordType.DeveloperName == 'ARC_Guardian') {
                continue;
            } else {
                relationship = member.ARC_DependentRelationship__c;
            }
            Date memberEndDate = null;

            if (member.ARC_TerminationDate__c != null) {
                memberEndDate = Date.newInstance(
                    member.ARC_TerminationDate__c.year(),
                    member.ARC_TerminationDate__c.month(),
                    Date.daysInMonth(member.ARC_TerminationDate__c.year(), member.ARC_TerminationDate__c.month())
                );
            }
            Map<String,Object> memberMap = memberIdMap.containsKey(member.Id) ? memberIdMap.get(member.Id) : new Map<String,Object>{'productName'=>'','employerContribution'=>0,'employeeContribution'=>0,'monthlyContribution'=>0};
            // Store Account information
            memberOutput.put('FirstName', member.FirstName);
            memberOutput.put('MiddleName', member.vlocity_ins__MiddleName__pc);
            memberOutput.put('LastName', member.LastName);
            memberOutput.put('Division', member.ARC_EmployeeDivision__c);
            memberOutput.put('JobClass', member.Census_Member__r.vlocity_ins__GroupClassId__r.Name);
            memberOutput.put('EmploymentType', member.ARC_EmployeeType__c);
            memberOutput.put('SSN', member.vlocity_ins__SocialSecurityNumber__pc);
            memberOutput.put('DOB', member.PersonBirthdate);
            memberOutput.put('HireDate', member.ARC_HireDate__c);
            memberOutput.put('TerminationDate', member.ARC_TerminationDate__c);
            memberOutput.put('JobTitle', member.ARC_JobTitle__c);
            memberOutput.put('Address', member.BillingAddress);
            memberOutput.put('Street', member.BillingStreet);
            memberOutput.put('City', member.BillingCity);
            memberOutput.put('State', member.BillingState);
            memberOutput.put('ZIP', member.BillingPostalCode);
            memberOutput.put('Country', member.BillingCountry);
            memberOutput.put('Phone', member.Phone);
            memberOutput.put('PersonEmail', member.PersonEmail);
            memberOutput.put('PayPeriod', relationship == 'Primary' ? member.ARC_GroupAccount__r.ARC_PayPeriod__c : null);
            memberOutput.put('Program', String.valueOf(memberMap.get('productName')));
            memberOutput.put('EnrollmentStatus', enrollmentStatus);
            memberOutput.put('Relationship', relationship);
            memberOutput.put('IsPrimary', member.ARC_IsPrimaryMember__c);
            memberOutput.put('EECost',Integer.valueOf(memberMap.get('employeeContribution')));
            memberOutput.put('ERCost',Integer.valueOf(memberMap.get('employerContribution')));
            memberOutput.put('MonthlyAmount',Integer.valueOf(memberMap.get('monthlyContribution')));
            memberOutput.put('MemberStartDate', member.ARC_ContinuousMembershipStartDate__c);
            memberOutput.put('MemberEndDate', memberEndDate);

            output.add(memberOutput);
        }

        output = orderFamilyMembers(output);
        return output;
    }

    public static List<Map<String, Object>> orderFamilyMembers (List<Map<String, Object>> inputFamily) {
        List<Map<String, Object>> output = new List<Map<String, Object>>();

        // Define relationship order
        Map<String, Integer> relationshipOrder = new Map<String, Integer>{
            'Primary' => 0,
            'Spouse'  => 1,
            'Child'   => 2
        };

        // Buckets for ordering
        Map<String, Object> primary  = null;
        Map<String, Object> spouse   = null;
        List<Map<String, Object>> children = new List<Map<String, Object>>();
        List<Map<String, Object>> others   = new List<Map<String, Object>>();

        for (Map<String, Object> member : inputFamily) {
            String relationship = (String) member.get('Relationship');

            if (relationship == 'Primary' || (Boolean) member.get('IsPrimary')) {
                primary = member;
            } else if (relationship == 'Spouse') {
                spouse = member;
            } else if (relationship == 'Child') {
                children.add(member);
            } else {
                others.add(member); // safety net for unexpected values
            }
        }

        // Order family
        if (primary != null) output.add(primary);
        if (spouse  != null) output.add(spouse);
        output.addAll(children);
        output.addAll(others);

        return output;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getProgramsWithMembers(String accountId) {
        // Find best policy (same selection logic as getCurrentPolicy)
        List<InsurancePolicy> policies = [
            SELECT Id,
                   Status,
                   ARC_EffectiveDate__c,
                   ARC_ExpirationDate__c,
                   ARC_TotalPremiumAmount__c,
                   EmployeeContribution,
                   EmployerContribution
            FROM InsurancePolicy
            WHERE NameInsuredId = :accountId
        ];

        InsurancePolicy bestPolicy = null;
        for (InsurancePolicy policy : policies) {
            if (bestPolicy != null) {
                if (bestPolicy.Status == 'Activated') break;
                if (policy.Status == 'Activated') {
                    bestPolicy = policy;
                } else if (policy.Status.contains('Awaiting')) {
                    bestPolicy = policy;
                } else if (policy.Status == 'Terminated' && bestPolicy.Status == 'Terminated') {
                    if (policy.ARC_ExpirationDate__c < bestPolicy.ARC_ExpirationDate__c) {
                        bestPolicy = policy;
                    }
                }
            } else {
                bestPolicy = policy;
            }
        }

        if (bestPolicy == null) return new List<Map<String, Object>>();

        // Get primary account's member ID
        List<Account> accounts = [SELECT Current_Member_Id__c FROM Account WHERE Id = :accountId LIMIT 1];
        String memberId = accounts.isEmpty() ? null : accounts[0].Current_Member_Id__c;

        // Query top-level coverages with their participants
        List<InsurancePolicyCoverage> coverages = [
            SELECT Id,
                   vlocity_ins_fsc__Product2Id__c,
                   vlocity_ins_fsc__Product2Id__r.Name,
                   ARC_UnitPrice__c,
                   ARC_EmployeeContribution__c,
                   ARC_EmployerContribution__c,
                   (SELECT Id,
                           ARC_ParticipantName__c,
                           ARC_PolicyParticipant__r.PrimaryParticipantContact.Name
                    FROM Coverage_Participants__r)
            FROM InsurancePolicyCoverage
            WHERE InsurancePolicyId = :bestPolicy.Id
            AND ARC_ParentProduct__c = NULL
        ];

        List<Map<String, Object>> output = new List<Map<String, Object>>();
        for (InsurancePolicyCoverage coverage : coverages) {
            Map<String, Object> coverageMap = new Map<String, Object>();
            coverageMap.put('Id', coverage.Id);
            coverageMap.put('ProductId', coverage.vlocity_ins_fsc__Product2Id__c);
            coverageMap.put('CoverageToken', bestPolicy.Id + '|' + coverage.Id);
            coverageMap.put('ProductName', coverage.vlocity_ins_fsc__Product2Id__r != null
                ? coverage.vlocity_ins_fsc__Product2Id__r.Name : '');
            coverageMap.put('EffectiveDate', bestPolicy.ARC_EffectiveDate__c);
            coverageMap.put('TotalPerPayPeriod', coverage.ARC_UnitPrice__c);
            coverageMap.put('EmployeeContribution', coverage.ARC_EmployeeContribution__c);
            coverageMap.put('EmployerContribution', coverage.ARC_EmployerContribution__c);
            coverageMap.put('MemberId', memberId);

            Set<String> memberNames = new Set<String>();
            for (ARC_CoverageParticipant__c cp : coverage.Coverage_Participants__r) {
                String name = cp.ARC_ParticipantName__c;
                if (String.isBlank(name) && cp.ARC_PolicyParticipant__r != null
                        && cp.ARC_PolicyParticipant__r.PrimaryParticipantContact != null) {
                    name = cp.ARC_PolicyParticipant__r.PrimaryParticipantContact.Name;
                }
                if (!String.isBlank(name)) memberNames.add(name);
            }
            coverageMap.put('Members', String.join(new List<String>(memberNames), ', '));

            output.add(coverageMap);
        }

        return output;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isAdminOnly() {
        List<PermissionSetAssignment> assignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSet.Name = 'Employer_Admin_Permissions'
            LIMIT 1
        ];
        return !assignments.isEmpty();
    }
}