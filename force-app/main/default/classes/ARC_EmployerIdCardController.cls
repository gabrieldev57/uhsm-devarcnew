/**
 * ARC_EmployerIdPortalController
 * Replaces the OmniStudio Integration Procedure "ARC_EmployerIdPortal_Portal"
 * (ProcedureKey: ARC_EmployerIdPortal_Portal).
 *
 * Used as a Remote Action step in OmniScript via invokeMethod('getPortalData').
 *
 * ASSUMPTIONS — review each before deploying:
 *  [A1] %vlocity_namespace% = 'vlocity_ins'. Change globally if org differs.
 *  [A2] ARC_GetCommunityURL.getOrganizationData() called directly (static method).
 *  [A3] InsProductService called via Callable interface, action 'getCoverages',
 *       Output keys assumed: PCP, Specialist, MinuteClinic, UrgentCare,
 *       weShareER, ProductCode (from ARC_TransformPlanData* bundles).
 *  [A4] vlocity_ins__Birthdate__c is the DOB field on GroupCensusMember__c.
 *  [A5] vlocity_ins__InsurancePolicyId__c links GroupCensusMember__c to policy.
 *  [A6] ARC_Census__c links ARC_HipaaAuthorization__c to the census (vlocity_ins__CensusId__c).
 *  [A7] vlocity_ins__Email__c on GroupCensusMember__c stores member email.
 *  [A8] ARC_ActiveMember__c (Boolean) on GroupCensusMember__c.
 *  [A9] Contract.vlocity_ins__EnrollmentCensusId__c = GroupCensusMember__c.vlocity_ins__CensusId__c.
 *  [A10] User.ContactId populated for community users (userId lookup path).
 */
global class ARC_EmployerIdCardController implements Callable {

    // ── Test-injection hooks ──────────────────────────────────────────────────
    @TestVisible static Map<String,Object> mockOrgData;
    @TestVisible static Map<String,Object> mockCoverages;

    // ── Callable entry point (OmniScript Remote Action) ───────────────────────
    global Object call(String action, Map<String, Object> args) {
        Map<String,Object> input  = (Map<String,Object>) args.get('input');
        Map<String,Object> output = (Map<String,Object>) args.get('output');
        Map<String,Object> opts   = new Map<String,Object>();
        try {
            if (action == 'getPortalData') {
                getPortalData(input, output, opts);
                // Round-trip through JSON to ensure all Apex types (Id, Date, etc.)
                // are converted to plain JSON-safe types before OmniScript reads the map
                Map<String,Object> clean = (Map<String,Object>)
                    JSON.deserializeUntyped(JSON.serialize(output));
                output.clear();
                output.putAll(clean);
                return true;
            }
            output.put('error', 'Method not found: ' + action);
            return false;
        } catch (Exception ex) {
            output.put('error', ex.getMessage());
            output.put('stackTrace', ex.getStackTraceString());
            return false;
        }
    }

    // ── Main orchestration ────────────────────────────────────────────────────
    @TestVisible
    static boolean getPortalData(
            Map<String,Object> input,
            Map<String,Object> output,
            Map<String,Object> options) {

        // Inputs (mirrors IP CustomJavaScript / additionalInput fields)
        String recordId          = (String) input.get('recordId');
        String userId            = (String) input.get('userId');
        String insurancePolicyId = (String) input.get('insurancePolicyId');
        String coverageId        = (String) input.get('coverageId');
        String productId         = (String) input.get('productId');
        String planName          = input.get('planName') != null
                                    ? (String) input.get('planName') : '';
        String contextId = (String) input.get('ContextId');

        // Step 2: RA_GetOrganizationData → ARC_GetCommunityURL.getOrganizationData()
        Map<String,Object> orgData    = getOrganizationData(userId);
        String             domainPrefix = (String) orgData.get('domainPrefix');

        // Step 4: DREX_GetCensusMemberDetailsSmallGroup
        //   censusMemberId = IF(ISNOTBLANK(recordId), recordId, NULL)
        //   userId fallback used when recordId is blank
        String censusMemberId = String.isNotBlank(recordId) ? recordId : null;
        MemberResult member   = getMemberDetails(censusMemberId, userId, coverageId);

        // Step 5: DREX_GetContractId → ARC_ExtractCensusContract360
        ContractResult contractResult = getContractData(member.censusId);

        // Step 8: RESP_MemberIsNotActive (inactive in IP but logic preserved)
        //   executionConditionalFormula: IF(ShowCard = true, false, true)
        //   i.e. fires (returns early) when ShowCard is FALSE
        if (!contractResult.showCard) {
            output.put('ShowCard', false);
            return false;
        }

        // Step 6: DREX_ReadGuardians → ARC_ReadGuardianDetailsSmallGroup
        // List<Map<String,Object>> guardians = getGuardians(insurancePolicyId);

        // Steps 9-10: Get Spouse/Child dependents from ARC_CoverageParticipant__c
        List<Map<String,Object>> dependents = getDependents(coverageId);

        // Step 7: LA_AllMembersPlus18 – just return primary 
        List<Map<String,Object>> allMembers = mergeAllMembers(contextId);

        // Step 11: RA_GetCoverages → InsProductService.getCoverages()
        Map<String,Object> coverages = getCoverages(productId);
        System.debug('### getCoverages raw output: ' + JSON.serializePretty(coverages));

        // Steps 12-17: Plan transforms + conditional medical service label SetValues
        Map<String,Object> serviceInfo = buildServiceInfo(planName, coverages);

        // Step 18: ResponseAction – final output assembly
        String senderFirstName = member.senderName != null
            ? member.senderName.split(' ')[0] : null;
        Boolean isSandbox = orgData.get('isSandbox') == true;

        output.put('ShowCard',        true);
        output.put('ContractStatus',  contractResult.contractStatus);
        output.put('LegacyPlan',      planNameLike(planName, 'Legacy'));
        output.put('accessPlan',      planNameLike(planName, 'WeShare Access'));
        output.put('weSharePlan',     planNameLike(planName, 'WeShare'));
        output.put('SelectMembers',   JSON.deserializeUntyped(JSON.serialize(allMembers)));
        output.put('activeMember',    member.activeMember);
        output.put('contactId',       member.contactId);
        output.put('effDate',         contractResult.effectiveDate);
        output.put('email',           member.email);
        output.put('memberid',        member.memberId);
        output.put('memberDOB',       member.memberDOB);
        output.put('planName',        planName);
        output.put('primaryName',     member.senderName);
        output.put('senderFirstName', senderFirstName);
        output.put('userEmail',       orgData.get('userEmail'));
        output.put('isProduction',    orgData.get('isProduction'));
        // output.put('Guardians',       guardians);
        output.put('dependents',      dependents);
        // iframeHostURL variants (from SVURLForDocument / ResponseAction step 18)
        output.put('iframeHostURLCommunity',
            'https://' + domainPrefix +
            '.sandbox.my.site.com/employerportal/servlet/servlet.FileDownload?file=');
        output.put('iframeHostURLCommunityProduction',
            'https://' + domainPrefix +
            '.my.site.com/employerportal/servlet/servlet.FileDownload?file=');
        output.put('iframeHostURLProduction',
            'https://uhsm.file.force.com/servlet/servlet.FileDownload?file=');
        output.put('iframeHostURLSalesforce',
            'https://' + domainPrefix +
            (isSandbox ? '.sandbox' : '') +
            '.file.force.com/servlet/servlet.FileDownload?file=');
        // Nest service labels under medicalServices to match IP output structure
        Map<String,Object> medicalServices = new Map<String,Object>();
        for (String key : serviceInfo.keySet()) {
            if (key.startsWith('service')) {
                medicalServices.put(key, serviceInfo.get(key));
            } else {
                output.put(key, serviceInfo.get(key));
            }
        }
        if (!medicalServices.isEmpty()) {
            output.put('medicalServices', medicalServices);
        }
        return true;
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Step 2 – ARC_GetCommunityURL remote action
    // ═════════════════════════════════════════════════════════════════════════
    @TestVisible
    static Map<String,Object> getOrganizationData(String userId) {
        if (Test.isRunningTest() && mockOrgData != null) {
            return mockOrgData;
        }
        Map<String,Object> inp = new Map<String,Object>{ 'userId' => userId };
        Map<String,Object> out = new Map<String,Object>();
        ARC_GetCommunityURL.getOrganizationData(inp, out, inp);
        return out;
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Step 4 – DREX_GetCensusMembersDetailsSmallGroup → SOQL
    //
    // DR lookup order:
    //   1. User (filter: Id = userId) — used when censusMemberId is null
    //   2. GroupCensusMember__c (filter: Id = censusMemberId)           — Member
    //   4. GroupCensusMember__c (filter: ContactId = primaryContactId,
    //                            IsPrimaryMember = false, ActiveMember = true) — dependents
    //   5. GroupCensusMember__c (filter: Id = censusMemberId,
    //                            IsPrimaryMember = true)                 — Primary
    // DR formula: activeMember = IF(Member exists, true, false)
    // ═════════════════════════════════════════════════════════════════════════
    @TestVisible
    static MemberResult getMemberDetails(
            String censusMemberId, String userId, String coverageId) {

        MemberResult result = new MemberResult();
        vlocity_ins__GroupCensusMember__c gcm;

        if (String.isNotBlank(censusMemberId)) {
            List<vlocity_ins__GroupCensusMember__c> rows = [
                SELECT Id, Name,
                       vlocity_ins__CensusId__c,
                       vlocity_ins__ContactId__c,
                       vlocity_ins__IsPrimaryMember__c,
                       vlocity_ins__ContactId__r.Email,
                       vlocity_ins__ContactId__r.Account.ARC_Member_Id__c,
                       vlocity_ins__ContactId__r.Account.PersonBirthdate,
                       ARC_ActiveMember__c
                FROM vlocity_ins__GroupCensusMember__c
                WHERE Id = :censusMemberId
                LIMIT 1
            ];
            gcm = rows.isEmpty() ? null : rows[0];

        } else if (String.isNotBlank(userId)) {
            // Resolve User → ContactId, then find primary GCM for that contact + policy
            List<User> users = [
                SELECT ContactId
                FROM User
                WHERE Id = :userId
                LIMIT 1
            ];
            if (!users.isEmpty() && users[0].ContactId != null) {
                Id contactId = users[0].ContactId;
                List<vlocity_ins__GroupCensusMember__c> rows = [
                    SELECT Id, Name,
                           vlocity_ins__CensusId__c,
                           vlocity_ins__ContactId__c,
                           vlocity_ins__IsPrimaryMember__c,
                           vlocity_ins__ContactId__r.Email,
                           vlocity_ins__ContactId__r.Account.ARC_Member_Id__c,
                           vlocity_ins__ContactId__r.Account.PersonBirthdate,
                           ARC_ActiveMember__c
                    FROM vlocity_ins__GroupCensusMember__c
                    WHERE vlocity_ins__ContactId__c       = :contactId
                    AND   vlocity_ins__IsPrimaryMember__c = true
                    LIMIT 1
                ];
                gcm = rows.isEmpty() ? null : rows[0];
            }
        }

        if (gcm == null) {
            result.activeMember = false;
            return result;
        }

        result.censusMemberId = gcm.Id;
        result.censusId       = gcm.vlocity_ins__CensusId__c;
        result.contactId      = (Id) gcm.vlocity_ins__ContactId__c;
        result.memberId       = (String) gcm.vlocity_ins__ContactId__r?.Account?.ARC_Member_Id__c;
        result.email          = gcm.vlocity_ins__ContactId__r?.Email;
        result.memberDOB      = gcm.vlocity_ins__ContactId__r?.Account?.PersonBirthdate != null
                                    ? String.valueOf(gcm.vlocity_ins__ContactId__r.Account.PersonBirthdate) : null;
        result.activeMember   = (gcm.ARC_ActiveMember__c == true);
        result.isPrimary      = (gcm.vlocity_ins__IsPrimaryMember__c == true);

        // Use ARC_CoveragePrimaryMember__r.Name and ARC_PrimaryMemberId__c from the
        // specific selected InsurancePolicyCoverage — matches ticket requirements
        String coveragePrimaryName = null;
        if (String.isNotBlank(coverageId)) {
            List<InsurancePolicyCoverage> ipcs = [
                SELECT ARC_CoveragePrimaryMember__r.Name,
                       ARC_PrimaryMemberId__c
                FROM InsurancePolicyCoverage
                WHERE Id = :coverageId
                AND ARC_CoveragePrimaryMember__c != null
                LIMIT 1
            ];
            if (!ipcs.isEmpty()) {
                coveragePrimaryName = ipcs[0].ARC_CoveragePrimaryMember__r.Name;
                if (String.isNotBlank(ipcs[0].ARC_PrimaryMemberId__c)) {
                    result.memberId = ipcs[0].ARC_PrimaryMemberId__c;
                }
            }
        }
        result.senderName = String.isNotBlank(coveragePrimaryName) ? coveragePrimaryName : gcm.Name;
        return result;
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Step 5 – ARC_ExtractCensusContract360 → SOQL
    //
    // DR extracts two Contract buckets (filter by vlocity_ins__EnrollmentCensusId__c):
    //   ContractActive: Status = 'Activated', ORDER BY ARC_EffectiveDate__c DESC, LIMIT 1
    //   ContractLast:   Status != 'Activated' AND != 'Draft',
    //                   ORDER BY ARC_EffectiveDate__c ASC, LIMIT 1
    //
    // DR formulas (exact):
    //   ShowCard     = IF(ContractLast.Status = 'Awaiting Activation'
    //                     || ContractActive.Id != null, true, false)
    //   effectiveDate = IF(ContractActive.ARC_EffectiveDate__c != null,
    //                      ContractActive.ARC_EffectiveDate__c,
    //                      ContractLast.ARC_EffectiveDate__c)
    // ═════════════════════════════════════════════════════════════════════════
    @TestVisible
    static ContractResult getContractData(String censusId) {
        ContractResult cr = new ContractResult();
        if (String.isBlank(censusId)) {
            cr.showCard = false;
            return cr;
        }

        List<Contract> active = [
            SELECT Id, Status, ARC_EffectiveDate__c
            FROM Contract
            WHERE vlocity_ins__EnrollmentCensusId__c = :censusId
            AND   Status = 'Activated'
            ORDER BY ARC_EffectiveDate__c DESC NULLS LAST
            LIMIT 1
        ];

        List<Contract> last = [
            SELECT Id, Status, ARC_EffectiveDate__c
            FROM Contract
            WHERE vlocity_ins__EnrollmentCensusId__c = :censusId
            AND   Status != 'Activated'
            AND   Status != 'Draft'
            ORDER BY ARC_EffectiveDate__c ASC NULLS LAST
            LIMIT 1
        ];

        Contract act = active.isEmpty() ? null : active[0];
        Contract lst = last.isEmpty()   ? null : last[0];

        String lastStatus  = lst?.Status;
        cr.showCard        = (act != null) || (lastStatus == 'Awaiting Activation');
        // DR formula order 7: IF(ContractActive.Id != null, ContractActive.Status, ContractLast.Status)
        cr.contractStatus  = act != null ? act.Status : lastStatus;

        Date effDate      = (act != null && act.ARC_EffectiveDate__c != null)
                                ? act.ARC_EffectiveDate__c
                                : lst?.ARC_EffectiveDate__c;
        cr.effectiveDate  = effDate != null ? String.valueOf(effDate) : null;
        return cr;
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Step 6 – ARC_ReadGuardianDetailsSmallGroup → SOQL
    //
    // DR object: ARC_HipaaAuthorization__c
    //   FilterGroup 0: ARC_AuthorizedMember__c != null   (internal member guardian)
    //   FilterGroup 1: ARC_ExternalPersonAuthorized__c != null (external guardian)
    // Output list 'Guardians' with: Id, ARC_Age__c, Email
    // ═════════════════════════════════════════════════════════════════════════
    // @TestVisible
    // static List<Map<String,Object>> getGuardians(String insurancePolicyId) {
    //     if (String.isBlank(insurancePolicyId)) {
    //         return new List<Map<String,Object>>();
    //     }

    //     List<ARC_HipaaAuthorization__c> auths = [
    //         SELECT ARC_AuthorizedMember__c,
    //                ARC_AuthorizedMember__r.Id,
    //                ARC_AuthorizedMember__r.ARC_Age__c,
    //                ARC_AuthorizedMember__r.vlocity_ins__Email__c,
    //                ARC_ExternalPersonAuthorized__c,
    //                ARC_ExternalPersonAuthorized__r.Id,
    //                ARC_ExternalPersonAuthorized__r.vlocity_ins__Age__c,
    //                ARC_ExternalPersonAuthorized__r.Email
    //         FROM ARC_HipaaAuthorization__c
    //         WHERE ARC_InsurancePolicy__c = :insurancePolicyId
    //         AND  (ARC_AuthorizedMember__c != null
    //               OR ARC_ExternalPersonAuthorized__c != null)
    //     ];

    //     List<Map<String,Object>> guardians = new List<Map<String,Object>>();
    //     for (ARC_HipaaAuthorization__c auth : auths) {
    //         Map<String,Object> g = new Map<String,Object>();
    //         if (auth.ARC_AuthorizedMember__c != null) {
    //             g.put('Id',         auth.ARC_AuthorizedMember__r.Id);
    //             g.put('ARC_Age__c', auth.ARC_AuthorizedMember__r.ARC_Age__c);
    //             g.put('Email',      auth.ARC_AuthorizedMember__r.vlocity_ins__Email__c);
    //         } else {
    //             g.put('Id',         auth.ARC_ExternalPersonAuthorized__r.Id);
    //             g.put('ARC_Age__c', auth.ARC_ExternalPersonAuthorized__r.vlocity_ins__Age__c);
    //             g.put('Email',      auth.ARC_ExternalPersonAuthorized__r.Email);
    //         }
    //         guardians.add(g);
    //     }
    //     return guardians;
    // }

    // ═════════════════════════════════════════════════════════════════════════
    // Steps 9-10 – Get Spouse/Child dependents from ARC_CoverageParticipant__c
    //
    // Filters by the specific selected InsurancePolicyCoverage ID, not all
    // coverages on the policy.
    // ═════════════════════════════════════════════════════════════════════════
    @TestVisible
    static List<Map<String,Object>> getDependents(String coverageId) {
        if (String.isBlank(coverageId)) {
            return new List<Map<String,Object>>();
        }

        List<ARC_CoverageParticipant__c> cps = [
            SELECT Id, ARC_ParticipantName__c
            FROM ARC_CoverageParticipant__c
            WHERE ARC_PolicyCoverage__c = :coverageId
            AND   ARC_CoverageRole__c IN ('Spouse', 'Child','Dependent')
        ];

        List<Map<String,Object>> result = new List<Map<String,Object>>();
        for (ARC_CoverageParticipant__c cp : cps) {
            result.add(new Map<String,Object>{
                'Id'         => cp.Id,
                'Name'       => cp.ARC_ParticipantName__c,
                'Email'      => '',
                'isSelected' => true
            });
        }
        return result;
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Step 7 – LA_AllMembersPlus18 (advancedMerge: Primary list + dependents)
    // ═════════════════════════════════════════════════════════════════════════
    @TestVisible
    static List<Map<String,Object>> mergeAllMembers(String contextId) {
           // MemberResult primary, List<Map<String,Object>> dependents) {

        List<Map<String,Object>> all = new List<Map<String,Object>>();
        // if (primary != null && primary.censusMemberId != null) {
        //     String firstName = primary.senderName != null
        //         ? primary.senderName.split(' ')[0] : null;
        //     all.add(new Map<String,Object>{
        //         'Id'              => primary.censusMemberId,
        //         'Name'            => primary.senderName,
        //         'FirstName'       => firstName,
        //         'MemberId'        => primary.memberId,
        //         'IsPrimaryMember' => true,
        //         'activeMember'    => primary.activeMember,
        //         'Email'           => primary.email != null ? primary.email : '',
        //         'memberDOB'       => primary.memberDOB,
        //         'isSelected'      => true
        //     });
        // }
        // all.addAll(dependents);
        List<InsurancePolicy> policies = [
            SELECT Id, NameInsuredId, NameInsured.FirstName,NameInsured.LastName, NameInsured.PersonEmail
            FROM InsurancePolicy
            WHERE NameInsuredId = :contextId
            AND Status = 'Activated'
            LIMIT 1
        ];
        if (!policies.isEmpty()) {
            InsurancePolicy p = policies[0];
            all.add(new Map<String,Object>{
                'Id'              => p.Id,
                'Name'            => p.NameInsured.FirstName + ' ' + p.NameInsured.LastName,
                'FirstName'       => p.NameInsured.FirstName,
                'MemberId'        => null,
                'IsPrimaryMember' => true,
                'activeMember'    => true,
                'Email'           => p.NameInsured.PersonEmail != null ? p.NameInsured.PersonEmail : '',
                'memberDOB'       => null,
                'isSelected'      => true
            });
        }
        return all;
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Step 11 – RA_GetCoverages → vlocity_ins.InsProductService
    // ═════════════════════════════════════════════════════════════════════════
    @TestVisible
    static Map<String,Object> getCoverages(String productId) {
        if (Test.isRunningTest() && mockCoverages != null) {
            return mockCoverages;
        }
        vlocity_ins.VlocityOpenInterface2 svc =
            (vlocity_ins.VlocityOpenInterface2)
            Type.forName('vlocity_ins', 'InsProductService').newInstance();
        Map<String,Object> inp  = new Map<String,Object>();
        Map<String,Object> out  = new Map<String,Object>();
        Map<String,Object> opts = new Map<String,Object>{ 'productId' => productId };
        svc.invokeMethod('getCoverages', inp, out, opts);
        // Round-trip through JSON to convert vlocity_ins.JSONResult (and other
        // managed-package types) into plain Map/List so transformCoverages can traverse it
        return (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(out));
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Steps 12-17 – Conditional plan transforms + medical service label SetValues
    //
    // Steps 12/13: DRTRANS_PlanData / DRTRANS_PlanDataWeShare (DataRaptor Transform
    //   bundles ARC_TransformPlanDataMemberCard / ARC_TransformPlanDataMemberCardWeShare)
    //   are not in this datapack. [A3] We assume getCoverages() already returns the
    //   required field names. Replace transformCoverages() with an Apex call if needed.
    //
    // Step 12: condition planName LIKE "UHSM", sendJSONPath = RA_GetCoverages
    // Step 13: condition planName LIKE "WeShare", sendJSONPath = RA_GetCoverages
    // Step 14: condition DRTRANS_PlanData:ProductCode == 'PROG_UHSMFundamental'
    // Step 15: condition ProductCode != Fundamental AND planName LIKE "UHSM"
    // Step 16: condition planName LIKE "WeShare" AND NOT LIKE "Access"
    // Step 17: condition planName LIKE "Access"
    // ═════════════════════════════════════════════════════════════════════════
    @TestVisible
    static Map<String,Object> buildServiceInfo(
            String planName, Map<String,Object> coverages) {

        Map<String,Object> result = new Map<String,Object>();
        Boolean isUHSM    = planNameLike(planName, 'UHSM');
        Boolean isWeShare = planNameLike(planName, 'WeShare');
        Boolean isAccess  = planNameLike(planName, 'Access');

        if (isUHSM) {
            // Step 12: DRTRANS_PlanData
            Map<String,Object> planData = transformCoverages(coverages);
            result.putAll(planData);

            String productCode = (String) planData.get('ProductCode');
            if (productCode == 'PROG_UHSMFundamental') {
                // Step 14: SV_SetMedicalServicesFundamental (exact values from IP)
                result.put('serviceDetail1', 'Eligible');
                result.put('serviceDetail2',
                    'Eligible' + '/' + String.valueOf(planData.get('UrgentCare')));
                result.put('serviceDetail3', 'Eligible');
                result.put('serviceName1',   'Hospital/Inpatient/ER:');
                result.put('serviceName2',   'Minute Clinic/Urgent Care:');
                result.put('serviceName3',   'Generic/Brand Rx:');
            } else {
                // Step 15: SV_SetMedicalServices
                result.put('serviceDetail1',
                    String.valueOf(planData.get('PCP')) +
                    ' / ' +
                    String.valueOf(planData.get('Specialist')));
                result.put('serviceDetail2',
                    String.valueOf(planData.get('MinuteClinic')) +
                    ' / ' +
                    String.valueOf(planData.get('UrgentCare')));
                result.put('serviceName1', 'Primary/Specialist:');
                result.put('serviceName2', 'Minute Clinic/Urgent Care:');
            }
        }

        if (isWeShare) {
            // Step 13: DRTRANS_PlanDataWeShare
            Map<String,Object> wsData = transformCoverages(coverages);
            result.putAll(wsData);

            if (!isAccess) {
                // Step 16: SV_SetMedicalServicesWeShare (exact CONCAT formulas from IP)
                result.put('service1',
                    'Primary '       + String.valueOf(wsData.get('PCP')) +
                    ' / Specialist ' + String.valueOf(wsData.get('Specialist')));
                result.put('service2',
                    'Minute Clinic $' + String.valueOf(wsData.get('MinuteClinic')) +
                    ' / Urgent Care ' + String.valueOf(wsData.get('UrgentCare')));
            } else {
                // Step 17: SV_SetMedicalServicesAccess
                // SUBSTRING(weShareER, 0, 3) mirrors IP formula
                String erRaw   = (String) wsData.get('weShareER');
                String erShort = (erRaw != null && erRaw.length() >= 3)
                                    ? erRaw.substring(0, 3) : erRaw;
                result.put('service1', 'Minute Clinic $'  + String.valueOf(wsData.get('MinuteClinic')));
                result.put('service2', 'Urgent Care '    + String.valueOf(wsData.get('UrgentCare')));
                result.put('service3', 'Emergency Room ' + erShort);
            }
        }

        return result;
    }

    // ── Traverses the nested getCoverages response and returns a flat map of
    //    the keys buildServiceInfo expects: PCP, Specialist, MinuteClinic,
    //    UrgentCare, weShareER, ProductCode
    @TestVisible
    static Map<String,Object> transformCoverages(Map<String,Object> coverages) {
        if (coverages == null) return new Map<String,Object>();

        // Walk result.records[0] → collect all productAttribute codes → userValues.value
        Map<String,Object> byCode    = new Map<String,Object>();
        String             prodCode  = null;

        Map<String,Object> result = (Map<String,Object>) coverages.get('result');
        if (result != null) {
            List<Object> recs = (List<Object>) result.get('records');
            if (recs != null && !recs.isEmpty()) {
                Map<String,Object> root = (Map<String,Object>) recs[0];

                // ProductCode lives in root.fields
                Map<String,Object> rf = (Map<String,Object>) root.get('fields');
                if (rf != null) prodCode = (String) rf.get('ProductCode');

                Map<String,Object> nr = (Map<String,Object>) root.get('nameResult');
                if (nr != null) {
                    // Root-level attributeCategories
                    harvestAttrs(byCode, (Map<String,Object>) nr.get('attributeCategories'));

                    // Child product attributeCategories
                    Map<String,Object> children = (Map<String,Object>) nr.get('childProducts');
                    if (children != null) {
                        List<Object> childRecs = (List<Object>) children.get('records');
                        if (childRecs != null) {
                            for (Object c : childRecs) {
                                Map<String,Object> cnr = (Map<String,Object>)
                                    ((Map<String,Object>) c).get('nameResult');
                                if (cnr != null) {
                                    harvestAttrs(byCode,
                                        (Map<String,Object>) cnr.get('attributeCategories'));
                                }
                            }
                        }
                    }
                }
            }
        }

        // Map vlocity attribute codes → flat keys used by buildServiceInfo
        return new Map<String,Object>{
            'ProductCode'  => prodCode,
            'PCP'          => byCode.get('PrimaryCarProviderOfficeVisits'),
            'Specialist'   => byCode.get('SpecialistOfficeVisits'),
            'MinuteClinic' => byCode.get('Minute_Clinic'),
            'UrgentCare'   => byCode.get('UrgentCare'),
            'weShareER'    => byCode.get('EmergencyRoom')
        };
    }

    // Walks attributeCategories → productAttributes, collecting code → userValues.value
    static void harvestAttrs(Map<String,Object> byCode, Map<String,Object> attrCategories) {
        if (attrCategories == null) return;
        List<Object> cats = (List<Object>) attrCategories.get('records');
        if (cats == null) return;
        for (Object catObj : cats) {
            Map<String,Object> catNr = (Map<String,Object>)
                ((Map<String,Object>) catObj).get('nameResult');
            if (catNr == null) continue;
            Map<String,Object> pa = (Map<String,Object>) catNr.get('productAttributes');
            if (pa == null) continue;
            List<Object> attrs = (List<Object>) pa.get('records');
            if (attrs == null) continue;
            for (Object aObj : attrs) {
                Map<String,Object> a    = (Map<String,Object>) aObj;
                String             code = (String) a.get('code');
                Map<String,Object> uv   = (Map<String,Object>) a.get('userValues');
                if (code != null && uv != null) {
                    byCode.put(code, uv.get('value'));
                }
            }
        }
    }

    // ── Utility: case-insensitive LIKE (mirrors OmniScript LIKE operator) ─────
    @TestVisible
    static Boolean planNameLike(String planName, String token) {
        if (String.isBlank(planName) || String.isBlank(token)) return false;
        return planName.containsIgnoreCase(token);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Inner result types
    // ═════════════════════════════════════════════════════════════════════════
    @TestVisible
    class MemberResult {
        String  censusMemberId;
        String  censusId;
        Id      contactId;
        String  memberId;
        String  email;
        String  memberDOB;
        String  senderName;
        Boolean activeMember = false;
        Boolean isPrimary    = false;
    }

    @TestVisible
    class ContractResult {
        Boolean showCard     = false;
        String  contractStatus;
        String  effectiveDate;
    }
}