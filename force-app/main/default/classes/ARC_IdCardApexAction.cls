global without sharing class ARC_IdCardApexAction implements Callable {

    public class ProgramOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public Id policyId;
        @AuraEnabled public Id coverageId;
        @AuraEnabled public Id productId;
        @AuraEnabled public String planName;
        @AuraEnabled public Date effectiveDate;
        @AuraEnabled public Integer memberCount;
        @AuraEnabled public String primaryMemberName;
        @AuraEnabled public String primaryMemberId;
    }

    public class MemberOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public Id coverageParticipantId;
        @AuraEnabled public Id policyParticipantId;
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactEmail;
        @AuraEnabled public String participantName;
        @AuraEnabled public String role;
        @AuraEnabled public String memberId;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public String relationshipToInsured;
    }

    public class OptionsResponse {
        @AuraEnabled public String status;
        @AuraEnabled public String message;
        @AuraEnabled public List<ProgramOption> programOptions;
        @AuraEnabled public Map<String, List<MemberOption>> membersByProgramToken;
        @AuraEnabled public String primaryContactEmail;
        @AuraEnabled public Id primaryContactId;
        @AuraEnabled public String primaryBusinessContactEmail;
        @AuraEnabled public Id accountId;
        @AuraEnabled public List<Map<String, String>> programSelectOptions;
        @AuraEnabled public List<Map<String, String>> displayProgramOptions;
        @AuraEnabled public Map<String, ProgramOption> programByToken;
        @AuraEnabled public String defaultProgramToken;
        @AuraEnabled public String defaultSelectionToken;
        @AuraEnabled public Integer validProgramCount;
        @AuraEnabled public Boolean skipProgramSelection;

        public OptionsResponse() {
            programOptions = new List<ProgramOption>();
            membersByProgramToken = new Map<String, List<MemberOption>>();
            programSelectOptions = new List<Map<String, String>>();
            displayProgramOptions = new List<Map<String, String>>();
            programByToken = new Map<String, ProgramOption>();
            validProgramCount = 0;
            skipProgramSelection = false;
        }
    }

    public class PdfData {
        @AuraEnabled public Id accountId;
        @AuraEnabled public Id censusMemberId;
        @AuraEnabled public Id insurancePolicyId;
        @AuraEnabled public Id coverageId;
        @AuraEnabled public Id productId;
        @AuraEnabled public String planName;
        @AuraEnabled public Date effectiveDate;
        @AuraEnabled public Id policyParticipantId;
        @AuraEnabled public Id coverageParticipantId;
        @AuraEnabled public Id primaryParticipantContactId;
        @AuraEnabled public String memberName;
        @AuraEnabled public String memberId;
        @AuraEnabled public String role;
        @AuraEnabled public String primaryContactEmail;
        @AuraEnabled public Date memberStartDate;
        @AuraEnabled public Date memberEndDate;
        @AuraEnabled public String relationshipToInsured;
    }

    public class ResultResponse {
        @AuraEnabled public String status;
        @AuraEnabled public String message;
        @AuraEnabled public String selectionTokenUsed;
    }

    private static final String POLICY_STATUS_ACTIVATED = 'Activated';
    private static final String POLICY_STATUS_AWAITING = 'Awaiting Signature';
    private static final String PENDING_MSG = 'This member’s enrollment is still pending or has not yet been signed.';

    global Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');

        try {
            if (action == 'getIdCardOptions') {
                return invokeGetIdCardOptions(input, output);
            } else if (action == 'buildPdfData') {
                return invokeBuildPdfData(input, output);
            } else if (action == 'getIdCardBundle') {
                return invokeGetIdCardBundle(input, output);
            } else if (action == 'getPlanSelectOptions') {
                return invokeGetPlanSelectOptions(input, output);
            } else {
                output.put('error', 'Method not found: ' + action);
                return false;
            }
        } catch (Exception e) {
            output.put('error', e.getMessage());
            output.put('stackTrace', e.getStackTraceString());
            return false;
        }
    }

    private static Id resolveAccountId(Map<String, Object> input) {
        String accountIdStr = input != null ? (String) input.get('ContextId') : null;
        
        if (!String.isNotBlank(accountIdStr)) {
            User u = [
            SELECT Id, AccountId, Contact.AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
            ];

            accountIdStr = u.AccountId;
            if (accountIdStr == null && u.Contact != null) {
                accountIdStr = u.Contact.AccountId;
            }
            
            
        }

        List<Account> accs = [
                SELECT Id, ARC_PrimaryMemberAccount__c
                FROM Account
                WHERE Id = :accountIdStr
                LIMIT 1
        ];
        // check if is employee or dependent, use employee
        if(!accs.isEmpty() && accs[0].ARC_PrimaryMemberAccount__c != null) {
            return accs[0].ARC_PrimaryMemberAccount__c;
        }else{
            return (Id) accountIdStr;
        }
    }

    private Boolean invokeGetPlanSelectOptions(Map<String, Object> input, Map<String, Object> output) {
        Id accountId = resolveAccountId(input);

        List<Map<String, Object>> optionList = new List<Map<String, Object>>();

        if (accountId != null) {
            Set<Id> policyIds = new Set<Id>();
            for (InsurancePolicy p : [
                SELECT Id
                FROM InsurancePolicy
                WHERE NameInsuredId = :accountId
                AND Status = :POLICY_STATUS_ACTIVATED
            ]) {
                policyIds.add(p.Id);
            }

            if (!policyIds.isEmpty()) {
                List<InsurancePolicyCoverage> coverages = [
                    SELECT Id,
                           vlocity_ins_fsc__Product2Id__c,
                           vlocity_ins_fsc__Product2Id__r.Name
                    FROM InsurancePolicyCoverage
                    WHERE InsurancePolicyId IN :policyIds
                    AND vlocity_ins_fsc__Product2Id__r.vlocity_ins__parentclassid__c = null
                ];

                Set<Id> addedPlanIds = new Set<Id>();
                for (InsurancePolicyCoverage cov : coverages) {
                    String planName = cov.vlocity_ins_fsc__Product2Id__r != null
                        ? cov.vlocity_ins_fsc__Product2Id__r.Name
                        : null;

                    String normalizedPlanName = String.isNotBlank(planName)
                        ? planName.toLowerCase().replace(' ', '')
                        : '';

                    Boolean isValidWeSharePlan = normalizedPlanName.contains('weshare');

                    Id productId = cov.vlocity_ins_fsc__Product2Id__c;
                    if (isValidWeSharePlan && productId != null && !addedPlanIds.contains(productId)) {
                        Map<String, Object> option = new Map<String, Object>();
                        option.put('name', productId);
                        option.put('value', planName);
                        optionList.add(option);
                        addedPlanIds.add(productId);
                    }
                }
            }
        }

        output.put('options', optionList);
        return true;
    }

    private Boolean invokeGetIdCardOptions(Map<String, Object> input, Map<String, Object> output) {
        Id accountId = resolveAccountId(input);
        OptionsResponse res = getIdCardOptions(accountId);

        ResultResponse result = new ResultResponse();
        result.status = res.status;
        result.message = res.message;
        result.selectionTokenUsed = null;

        output.put('result', JSON.deserializeUntyped(JSON.serialize(result)));
        output.put('options', JSON.deserializeUntyped(JSON.serialize(res)));
        return true;
    }

    private Boolean invokeBuildPdfData(Map<String, Object> input, Map<String, Object> output) {
        Id accountId = resolveAccountId(input);
        String selectionToken = (String) input.get('selectionToken');

        PdfData res = buildPdfData(accountId, selectionToken);

        ResultResponse result = new ResultResponse();
        result.status = 'Activated';
        result.message = null;
        result.selectionTokenUsed = selectionToken;

        output.put('result', JSON.deserializeUntyped(JSON.serialize(result)));
        output.put('pdfData', JSON.deserializeUntyped(JSON.serialize(res)));
        return true;
    }

    private Boolean invokeGetIdCardBundle(Map<String, Object> input, Map<String, Object> output) {
        Id accountId = resolveAccountId(input);
        String accountIdStr = input != null ? (String) input.get('ContextId') : null;
        output.put('ContextIdOld', accountIdStr);
        String selectionToken = (String) input.get('selectionToken');

        OptionsResponse opts = getIdCardOptions(accountId);

        String tokenToUse = String.isNotBlank(selectionToken)
            ? selectionToken
            : opts.defaultSelectionToken;

        ResultResponse result = new ResultResponse();
        result.status = opts.status;
        result.message = opts.message;
        result.selectionTokenUsed = tokenToUse;

        output.put('result', JSON.deserializeUntyped(JSON.serialize(result)));
        output.put('options', JSON.deserializeUntyped(JSON.serialize(opts)));
        output.put('ContextId', accountId);
        

        if (String.isNotBlank(tokenToUse) && opts != null && opts.status == POLICY_STATUS_ACTIVATED) {
            PdfData pdf = buildPdfData(accountId, tokenToUse);
            output.put('pdfData', JSON.deserializeUntyped(JSON.serialize(pdf)));
        }

        return true;
    }

    @AuraEnabled(cacheable=true)
    public static OptionsResponse getIdCardOptions(Id accountId) {
        OptionsResponse res = new OptionsResponse();

        if (accountId == null) {
            res.status = 'Error';
            res.message = 'Missing AccountId.';
            return res;
        }

        List<InsurancePolicy> activated = [
            SELECT Id, Status, NameInsuredId, ARC_GroupAccount__c
            FROM InsurancePolicy
            WHERE NameInsuredId = :accountId
            AND Status = :POLICY_STATUS_ACTIVATED
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];

        if (activated.isEmpty()) {
            List<InsurancePolicy> pending = [
                SELECT Id, Status
                FROM InsurancePolicy
                WHERE NameInsuredId = :accountId
                AND Status = :POLICY_STATUS_AWAITING
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            res.status = pending.isEmpty() ? 'NotFound' : 'AwaitingSignature';
            res.message = PENDING_MSG;
            return res;
        }

        Set<Id> policyIds = new Set<Id>();
        for (InsurancePolicy p : activated) {
            policyIds.add(p.Id);
            if (res.accountId == null && p.ARC_GroupAccount__c != null) {
                res.accountId = p.ARC_GroupAccount__c;
            }
        }

        List<InsurancePolicyCoverage> coveragesAll = [
            SELECT Id,
                   InsurancePolicyId,
                   vlocity_ins_fsc__Product2Id__c,
                   vlocity_ins_fsc__Product2Id__r.Name,
                   vlocity_ins_fsc__Product2Id__r.vlocity_ins__parentclassid__c,
                   ARC_CoveragePrimaryMember__r.Name,
                   ARC_PrimaryMemberId__c
            FROM InsurancePolicyCoverage
            WHERE InsurancePolicyId IN :policyIds
        ];

        List<InsurancePolicyCoverage> coverages = new List<InsurancePolicyCoverage>();
        for (InsurancePolicyCoverage cov : coveragesAll) {
            if (cov.vlocity_ins_fsc__Product2Id__r == null) {
                continue;
            }

            String planName = cov.vlocity_ins_fsc__Product2Id__r.Name;
            String normalizedPlanName = String.isNotBlank(planName)
                ? planName.toLowerCase().replace(' ', '')
                : '';

            Boolean isParentPlan = cov.vlocity_ins_fsc__Product2Id__r.vlocity_ins__parentclassid__c == null;
            Boolean isValidWeSharePlan = normalizedPlanName.contains('weshare');

            if (isParentPlan && isValidWeSharePlan) {
                coverages.add(cov);
            }
        }

        if (coverages.isEmpty()) {
            res.status = 'NotFound';
            res.message = PENDING_MSG;
            return res;
        }

        Set<Id> coverageIds = new Set<Id>();
        for (InsurancePolicyCoverage c : coverages) {
            coverageIds.add(c.Id);
        }

        List<ARC_CoverageParticipant__c> cps = [
            SELECT Id,
                   ARC_PolicyCoverage__c,
                   ARC_PolicyParticipant__c,
                   ARC_ParticipantName__c,
                   ARC_CoverageName__c,
                   ARC_CoverageRole__c,
                   ARC_Policy__c
            FROM ARC_CoverageParticipant__c
            WHERE ARC_PolicyCoverage__c IN :coverageIds
        ];

        Set<Id> ippIds = new Set<Id>();
        for (ARC_CoverageParticipant__c cp : cps) {
            if (cp.ARC_PolicyParticipant__c != null) {
                ippIds.add(cp.ARC_PolicyParticipant__c);
            }
        }

        Map<Id, InsurancePolicyParticipant> ippById = new Map<Id, InsurancePolicyParticipant>();
        if (!ippIds.isEmpty()) {
            for (InsurancePolicyParticipant ipp : [
                SELECT Id,
                       Role,
                       ARC_MemberID__c,
                       ARC_StartDate__c,
                       ARC_EndDate__c,
                       RelationshipToInsured,
                       PrimaryParticipantContactId,
                       PrimaryParticipantContact.Email,
                       PrimaryParticipantContact.Name
                FROM InsurancePolicyParticipant
                WHERE Id IN :ippIds
            ]) {
                ippById.put(ipp.Id, ipp);
            }
        }

        Map<Id, List<ARC_CoverageParticipant__c>> cpsByCoverage = new Map<Id, List<ARC_CoverageParticipant__c>>();
        for (ARC_CoverageParticipant__c cp : cps) {
            if (cp.ARC_PolicyCoverage__c == null) {
                continue;
            }

            if (!cpsByCoverage.containsKey(cp.ARC_PolicyCoverage__c)) {
                cpsByCoverage.put(cp.ARC_PolicyCoverage__c, new List<ARC_CoverageParticipant__c>());
            }
            cpsByCoverage.get(cp.ARC_PolicyCoverage__c).add(cp);
        }

        for (InsurancePolicyCoverage cov : coverages) {
            String programToken = String.valueOf(cov.InsurancePolicyId) + '|' + String.valueOf(cov.Id);

            ProgramOption po = new ProgramOption();
            po.policyId = cov.InsurancePolicyId;
            po.coverageId = cov.Id;
            po.productId = cov.vlocity_ins_fsc__Product2Id__c;
            po.planName = cov.vlocity_ins_fsc__Product2Id__r != null ? cov.vlocity_ins_fsc__Product2Id__r.Name : null;
            po.effectiveDate = null;
            po.label = po.planName != null ? po.planName : ('Coverage ' + cov.Id);
            po.value = programToken;
            po.primaryMemberName = cov.ARC_CoveragePrimaryMember__r?.Name;
            po.primaryMemberId   = cov.ARC_PrimaryMemberId__c;

            List<ARC_CoverageParticipant__c> covCps = cpsByCoverage.get(cov.Id);
            po.memberCount = covCps == null ? 0 : covCps.size();

            res.programOptions.add(po);
            res.programByToken.put(programToken, po);
            res.programSelectOptions.add(new Map<String, String>{
                'label' => po.label,
                'value' => programToken
            });

            List<MemberOption> memberOptions = new List<MemberOption>();
            if (covCps != null) {
                for (ARC_CoverageParticipant__c cp : covCps) {
                    InsurancePolicyParticipant ipp = ippById.get(cp.ARC_PolicyParticipant__c);

                    MemberOption mo = new MemberOption();
                    mo.coverageParticipantId = cp.Id;
                    mo.policyParticipantId = cp.ARC_PolicyParticipant__c;
                    mo.participantName = cp.ARC_ParticipantName__c;

                    if (ipp != null) {
                        mo.role = ipp.Role;
                        mo.memberId = ipp.ARC_MemberID__c;
                        mo.startDate = (Date) ipp.get('ARC_StartDate__c');
                        mo.endDate = (Date) ipp.get('ARC_EndDate__c');
                        mo.relationshipToInsured = (String) ipp.get('RelationshipToInsured');
                        mo.contactId = ipp.PrimaryParticipantContactId;
                        mo.contactEmail = ipp.PrimaryParticipantContact != null ? ipp.PrimaryParticipantContact.Email : null;

                        if (ipp.PrimaryParticipantContact != null && ipp.PrimaryParticipantContact.Name != null) {
                            mo.participantName = ipp.PrimaryParticipantContact.Name;
                        }
                    } else {
                        mo.role = cp.ARC_CoverageRole__c;
                        mo.memberId = null;
                        mo.startDate = null;
                        mo.endDate = null;
                        mo.relationshipToInsured = null;
                        mo.contactId = null;
                        mo.contactEmail = null;
                    }

                    mo.label =
                        (mo.participantName != null ? mo.participantName : 'Member') +
                        (mo.role != null ? ' (' + mo.role + ')' : '') +
                        (mo.memberId != null ? ' - ' + mo.memberId : '');

                    mo.value = programToken + '|' + String.valueOf(cp.Id);
                    memberOptions.add(mo);

                    if (res.defaultProgramToken == null) {
                        res.defaultProgramToken = programToken;
                    }
                    if (res.defaultSelectionToken == null) {
                        res.defaultSelectionToken = mo.value;
                    }
                    if (mo.role != null && mo.role.equalsIgnoreCase('Primary')) {
                        res.defaultProgramToken = programToken;
                        res.defaultSelectionToken = mo.value;
                    }

                    if (
                        res.primaryContactEmail == null &&
                        mo.role != null &&
                        mo.role.equalsIgnoreCase('Primary') &&
                        mo.contactEmail != null
                    ) {
                        res.primaryContactEmail = mo.contactEmail;
                        res.primaryContactId = mo.contactId;
                    }
                }
            }

            res.membersByProgramToken.put(programToken, memberOptions);

            Boolean isLegacyPlan = String.isNotBlank(po.planName) && po.planName.toLowerCase().contains('legacy');

            if (isLegacyPlan && memberOptions != null && !memberOptions.isEmpty()) {
                for (MemberOption mo : memberOptions) {
                    String memberLabel = String.isNotBlank(mo.participantName) ? mo.participantName : 'Member';
                    res.displayProgramOptions.add(new Map<String, String>{
                        'label' => po.label + ' - ' + memberLabel,
                        'value' => mo.value
                    });
                }
            } else {
                res.displayProgramOptions.add(new Map<String, String>{
                    'label' => po.label,
                    'value' => programToken
                });
            }
        }

        if (res.primaryContactEmail == null) {
            for (String key : res.membersByProgramToken.keySet()) {
                List<MemberOption> mos = res.membersByProgramToken.get(key);
                if (mos != null && !mos.isEmpty() && mos[0].contactEmail != null) {
                    res.primaryContactEmail = mos[0].contactEmail;
                    res.primaryContactId = mos[0].contactId;
                    break;
                }
            }
        }

        List<AccountContactRelation> officerAcrs = [
            SELECT Contact.Email
            FROM AccountContactRelation
            WHERE AccountId = :res.accountId
            AND Roles INCLUDES ('Primary Business Contact')
            AND Contact.Email != null
            LIMIT 1
        ];
        if (!officerAcrs.isEmpty()) {
            res.primaryBusinessContactEmail = officerAcrs[0].Contact.Email;
        }

        res.validProgramCount = res.programOptions != null ? res.programOptions.size() : 0;
        res.skipProgramSelection = res.validProgramCount == 1;
        res.status = POLICY_STATUS_ACTIVATED;
        return res;
    }

    @AuraEnabled(cacheable=true)
    public static PdfData buildPdfData(Id accountId, String selectionToken) {
        if (accountId == null || String.isBlank(selectionToken)) {
            throw new AuraHandledException('Missing inputs.');
        }

        Account acc = [
            SELECT Id, Census_Member__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        List<String> parts = selectionToken.split('\\|');
        if (parts.size() != 3) {
            throw new AuraHandledException('Invalid selection token.');
        }

        Id coverageId = (Id) parts[1];
        Id cpId = (Id) parts[2];

        InsurancePolicyCoverage cov = [
            SELECT Id,
                   InsurancePolicyId,
                   vlocity_ins_fsc__Product2Id__c,
                   vlocity_ins_fsc__Product2Id__r.Name,
                   vlocity_ins_fsc__Product2Id__r.vlocity_ins__parentclassid__c,
                   ARC_CoveragePrimaryMember__r.Name,
                   ARC_CoveragePrimaryMember__r.ARC_Member_Id__c,
                   ARC_PrimaryMemberId__c
            FROM InsurancePolicyCoverage
            WHERE Id = :coverageId
            LIMIT 1
        ];

        ARC_CoverageParticipant__c cp = [
            SELECT Id,
                   ARC_PolicyCoverage__c,
                   ARC_PolicyParticipant__c,
                   ARC_ParticipantName__c,
                   ARC_CoverageRole__c
            FROM ARC_CoverageParticipant__c
            WHERE Id = :cpId
            LIMIT 1
        ];

        InsurancePolicyParticipant ipp = [
            SELECT Id,
                   Role,
                   ARC_MemberID__c,
                   ARC_StartDate__c,
                   ARC_EndDate__c,
                   RelationshipToInsured,
                   PrimaryParticipantContactId,
                   PrimaryParticipantContact.Email,
                   PrimaryParticipantContact.Name
            FROM InsurancePolicyParticipant
            WHERE Id = :cp.ARC_PolicyParticipant__c
            LIMIT 1
        ];

        InsurancePolicy ip = [
            SELECT Id, ARC_PolicyEffectiveDate__c
            FROM InsurancePolicy
            WHERE Id = :cov.InsurancePolicyId
            LIMIT 1
        ];

        PdfData pdf = new PdfData();
        pdf.accountId = accountId;
        pdf.censusMemberId = acc.Census_Member__c;
        pdf.insurancePolicyId = cov.InsurancePolicyId;
        pdf.coverageId = cov.Id;
        pdf.productId = cov.vlocity_ins_fsc__Product2Id__c;
        pdf.planName = cov.vlocity_ins_fsc__Product2Id__r != null ? cov.vlocity_ins_fsc__Product2Id__r.Name : null;
        pdf.effectiveDate = ip.ARC_PolicyEffectiveDate__c;
        pdf.policyParticipantId = ipp.Id;
        pdf.coverageParticipantId = cp.Id;
        pdf.primaryParticipantContactId = ipp.PrimaryParticipantContactId;
        pdf.memberName = cov.ARC_CoveragePrimaryMember__r?.Name;
        pdf.memberId   = String.isNotBlank(cov.ARC_PrimaryMemberId__c)
                            ? cov.ARC_PrimaryMemberId__c
                            : cov.ARC_CoveragePrimaryMember__r?.ARC_Member_Id__c;
        pdf.role = ipp.Role != null ? ipp.Role : cp.ARC_CoverageRole__c;
        pdf.primaryContactEmail = ipp.PrimaryParticipantContact != null ? ipp.PrimaryParticipantContact.Email : null;
        pdf.memberStartDate = (Date) ipp.get('ARC_StartDate__c');
        pdf.memberEndDate = (Date) ipp.get('ARC_EndDate__c');
        pdf.relationshipToInsured = (String) ipp.get('RelationshipToInsured');
        return pdf;
    }
}