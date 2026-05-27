public with sharing class ARC_SGQLE_DocuSign {

    private static Map<String,Object> payloadJSON = new Map<String,Object>();
    private static List<Object> memberList = new List<Object>();
    
    private Map<String,Object> primaryInfo = new Map<String,Object>();
    private Integer dependentCount = 0;
    private List<MemberAssignment> memberAssignments = new List<MemberAssignment>(); // Role assignment per member, indexed by position in memberList. Built by computeMemberAssignments().
    private Integer legacyCount = 0; // Number of distinct Legacy programs (0, 1, or 2). Drives both mapping and template selection.
    private Boolean hasWeShareGroup = false; // Whether at least one member is in a non-Legacy (WeShare) program.
    private static Boolean anyMemberInCA = false; // Whether any member has address.state == 'CA'. Drives template selection and tabs mapping.

    public String subject = null; // Subject of the DocuSign envelope, set in getDocuSignData() and used in ARC_DocuSignApi call.
    public List<Object> signerList = new List<Object>(); // List of signers to send to DocuSign, with recipientId, name, email, deliveryMethod, and roleName.
    public List<Map<String,Object>> docuSignTemplates = new List<Map<String,Object>>(); // List of templates to send to DocuSign, with templateId, signerRole, and legacyIndex (for legacy templates).
    public Map<String,Object> tabsMap = new Map<String,Object>(); // Map of tab data to send to DocuSign, keyed by composite template section and member role (e.g. 'Program|Senior|Legacy').
    // public String policyId = null; // Policy Id to be used in tab mapping, extracted from the JSON.

    /**
     * Holds the data we need per medical program while resolving templates.
     */
    private class ProgramInfo {
        String planName;     // e.g. "WeShare Group Senior"
        String productId;    // e.g. "{{PRODUCT_WESHARE_GROUP_SENIOR_ID}}"
        String programType;  // "Senior" | "Premier" | "Essential" | "Enhanced"
        Boolean isLegacy;    // true when planName.contains('Senior')
    }

    /**
     * Holds the role assigned to a member for tabs and signers.
     * - originalRole: 'Primary' | 'Spouse' | 'Child' (from JSON)
     * - tabPrefix:    e.g. 'Legacy', 'Primary', 'Spouse', 'Dependent1'
     * - signerRole:   the roleName for the DocuSign signer (matches tabPrefix)
     * - inLegacy:     true if the member is enrolled in a Legacy/Senior plan
     */
    private class MemberAssignment {
        Integer memberIndex; // 0-based index in memberList
        String originalRole;
        String tabPrefix;
        String signerRole;
        Boolean inLegacy;
    }

    /***************************************************************
     * MAIN ENTRY POINT
     ***************************************************************/
    public void getDocuSignData(Map<String,Object> payload) {
        try {
            System.debug('Executing getDocuSignData...');

            memberList = payload.containsKey('members') && payload.get('members') != null ? (List<Object>)payload.get('members') : new List<Object>();
            primaryInfo = getPrimaryInfo(memberList);
            this.subject = 'Please DocuSign: WeShare healthcare by UHSM Qualified Life Event';
            // this.policyId = (String)((Map<String,Object>)((Map<String,Object>)payload.get('currentState')).get('currentPolicy')).get('policyId');

            // Evaluate reasons and changes based on Payload
            payloadJSON = ARC_SG_Utilities.evaluateChanges(payload);

            // Compute role assignments (Legacy/Primary/Spouse/DependentN) for every member.
            // Must run BEFORE signers/templates/mapping because all three consume this.
            computeMemberAssignments();

            getSignerList();
            getDocuSignTemplates();
            mapDocuSignData();

            // ARC_DocuSignApi.sendCompositeEnvelopeSmallGroup(subject, JSON.serialize(this.signerList), JSON.serialize(this.docuSignTemplates), JSON.serialize(this.tabsMap), null);

        } catch (Exception e) {
            System.debug('Error in getDocuSignData: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    /***************************************************************
     * MEMBER ASSIGNMENTS
     * For each member, decide its tabPrefix / signerRole based on:
     *   - whether the member is enrolled in a Legacy plan (becomes 'Legacy')
     *   - or in a WeShare (non-Legacy) plan (becomes Primary / Spouse / DependentN
     *     according to a re-priorityzation that ignores empty Legacy slots)
     *
     * Hierarchy used for ordering both Legacy and WeShare buckets:
     *   1. The member with originalRole == 'Primary'
     *   2. The member with originalRole == 'Spouse'
     *   3. Other dependents, sorted by age desc (oldest first)
     *
     * Side effects:
     *   - Populates this.memberAssignments (parallel to memberList).
     *   - Sets this.legacyCount and this.hasWeShareGroup.
     ***************************************************************/
    private void computeMemberAssignments() {
        System.debug('Executing computeMemberAssignments...');

        // Build a quick map: productId -> isLegacy, for all medical programs in the JSON.
        Map<String,Boolean> isLegacyByProductId = new Map<String,Boolean>();
        Map<String,Object> medicalProgramsMap = (Map<String,Object>)((Map<String,Object>)payloadJSON.get('generalInformation')).get('medicalProgram');
        if (medicalProgramsMap != null) {
            for (String planName : medicalProgramsMap.keySet()) {
                Map<String,Object> planMap = (Map<String,Object>)medicalProgramsMap.get(planName);
                Boolean isLegacy = planName.contains('Senior');
                isLegacyByProductId.put((String)planMap.get('productId'), isLegacy);
            }
        }

        // Initialize an assignment per member with originalRole and inLegacy already known.
        // We'll fill tabPrefix/signerRole in two ordered passes (Legacy bucket and WeShare bucket).
        this.memberAssignments = new List<MemberAssignment>();
        List<Integer> legacyIndexes = new List<Integer>();
        List<Integer> weShareIndexes = new List<Integer>();

        for (Integer i = 0; i < memberList.size(); i++) {
            Map<String,Object> m = (Map<String,Object>)memberList[i];
            MemberAssignment a = new MemberAssignment();
            a.memberIndex = i;
            a.originalRole = (String)m.get('role');
            String memberProductId = (String)m.get('productId');
            a.inLegacy = (memberProductId != null && isLegacyByProductId.containsKey(memberProductId))
                             ? isLegacyByProductId.get(memberProductId)
                             : false;
            this.memberAssignments.add(a);

            if (a.inLegacy) legacyIndexes.add(i);
            else weShareIndexes.add(i);
        }

        // Order each bucket by hierarchy: Primary > Spouse > dependents (oldest first).
        legacyIndexes = sortByHierarchy(legacyIndexes);
        weShareIndexes = sortByHierarchy(weShareIndexes);

        // Assign Legacy slots. All Legacy members share the same tabPrefix and signerRole
        // ('Legacy') because in DocuSign there is now a single physical Legacy template
        // reused per program. They are distinguished by which composite template instance
        // their data is bound to (handled in ARC_DocuSignApi via the rich tabs map).
        for (Integer idx : legacyIndexes) {
            MemberAssignment a = this.memberAssignments[idx];
            a.tabPrefix = 'Legacy';
            a.signerRole = 'Legacy';
        }
        this.legacyCount = legacyIndexes.size();

        // Assign WeShare slots: first member -> Primary, second -> Spouse only if originally Spouse,
        // otherwise -> Dependent1, Dependent2, ...
        // Rule per spec: hierarchy is Primary > Spouse > dependents-by-age. The first slot is always
        // 'Primary' (regardless of originalRole, so a re-promoted Child can become Primary).
        // 'Spouse' is reserved for the member whose originalRole == 'Spouse' and is in WeShare.
        Integer dependentSlot = 1;
        Boolean primaryAssigned = false;
        for (Integer idx : weShareIndexes) {
            MemberAssignment a = this.memberAssignments[idx];
            if (!primaryAssigned) {
                a.tabPrefix = 'Primary';
                a.signerRole = 'Primary';
                primaryAssigned = true;
            } else if (a.originalRole == 'Spouse') {
                a.tabPrefix = 'Spouse';
                a.signerRole = 'Spouse';
            } else {
                a.tabPrefix = 'Dependent' + dependentSlot;
                a.signerRole = 'Dependent' + dependentSlot;
                dependentSlot++;
            }
        }
        this.hasWeShareGroup = !weShareIndexes.isEmpty();

        System.debug('Legacy count: ' + this.legacyCount + ', has WeShare: ' + this.hasWeShareGroup);
        for (MemberAssignment a : this.memberAssignments) {
            System.debug('Member[' + a.memberIndex + '] originalRole=' + a.originalRole
                + ' inLegacy=' + a.inLegacy + ' tabPrefix=' + a.tabPrefix);
        }
    }


    /***************************************************************
     * SIGNER LIST
     * Adds alwasys the Primary member. If the primary is under 18 (isChildFamily),
     * the guardian (from generalInformation.guardian) signs in their place.
     ***************************************************************/
    private void getSignerList() {
        System.debug('Executing getSignerList...');

        // First pass: Build the signer list, always adding the Primary member (or their guardian if isChildFamily) and the Legacy members to sign the Disclaimer
        Map<String,Object> primaryPersonMap = (Map<String,Object>)primaryInfo.get('person');
        Integer primaryAge = calculateMemberAge(Date.valueOf((String)primaryPersonMap.get('dob')));
        for (Integer i = 1; i <= memberList.size(); i++) {
            Map<String,Object> memberMap = (Map<String,Object>)memberList[i-1];
            Map<String,Object> personMap = (Map<String,Object>)memberMap.get('person');
            Integer memberAge = calculateMemberAge(Date.valueOf((String)personMap.get('dob')));

            // Get the pre-computed signerRole (Legacy / Primary / Spouse / DependentN).
            String signerRole = this.memberAssignments[i-1].signerRole;

            if (memberAge != null && memberAge >= 18 && (signerRole == 'Primary' || signerRole == 'Legacy')) {
                String memberId = memberMap.containsKey('memberId') ? (String)memberMap.get('memberId') : memberMap.containsKey('memberExternalId') ? (String)memberMap.get('memberExternalId') : String.valueOf(i);
                String memberName = (String)personMap.get('firstName') + ' ' + (String)personMap.get('lastName');
                String memberEmail = (String)personMap.get('email');                

                Map<String,Object> signerMap = new Map<String,Object>{
                    'recipientId' => memberId,
                    'name' => memberName,
                    'email' => memberEmail,
                    'deliveryMethod' => 'Email',
                    'roleName' => signerRole
                };
                this.signerList.add(signerMap);
            }
            // Map Guardian as signer when primary is under 18 (isChildFamily).
            // A primary child is always in WeShare (Legacy requires 65+), so signerRole == 'Primary'.
            else if (signerRole == 'Primary' && memberAge != null && memberAge < 18) {
                Map<String,Object> generalInfoMap = (Map<String,Object>)payloadJSON.get('generalInformation');
                Map<String,Object> guardianMap = (generalInfoMap != null && generalInfoMap.get('guardian') != null) ? (Map<String,Object>)generalInfoMap.get('guardian') : null;
                if (guardianMap != null && !guardianMap.isEmpty()) {
                    Map<String,Object> signerMap = new Map<String,Object>{
                        'recipientId' => '1', // Check if Guardian Id is in the JSON
                        'name' => (String)guardianMap.get('firstName') + ' ' + (String)guardianMap.get('lastName'),
                        'email' => (String)guardianMap.get('email'),
                        'deliveryMethod' => 'Email',
                        'roleName' => this.memberAssignments[i-1].signerRole
                    };
                    this.signerList.add(signerMap);
                }
            }
        }
        
        System.debug('Signer List Size: ' + this.signerList.size());
    }


    /***************************************************************
     * COMPOSITE TEMPLATES
     * Final order produced:
     *   IF isChildFamily (primary < 18):
     *     1. Application Child Only (signed by Primary = Guardian)
     *     2. WeShare block (if any WeShare member): Authorization, Program, Beneficiaries?
     *     3. For each Legacy member: App Senior, Authorization, Program Senior (all signed by
     *        Primary), Disclaimer/Member 65 (signed by the Legacy member)
     *   ELSE:
     *     1. WeShare block (if any WeShare member): App Base, App 15D?, Authorization, Program,
     *        Beneficiaries? (all signed by Primary)
     *     2. For each Legacy member: App Senior, Authorization, Program Senior (Primary),
     *        Disclaimer (Legacy)
     *   Then once at the end:
     *     - State|CA (signed by Primary, only if any member's address.state == 'CA')
     *
     * Single physical templates: each section now has ONE template in DocuSign. Legacy
     * programs reuse the same physical template multiple times via separate composite
     * templates, each with its own data bound to a single Legacy member. The Primary signs
     * everything except the Disclaimer (WeShare SG Member 65), which the Legacy member signs.
     *
     * Application keys used in the index:
     *   'Application|Base'      -> ChildOnly=false, IsLegacy=false, MinDeps<=N<=MaxDeps
     *   'Application|Senior'    -> ChildOnly=false, IsLegacy=true
     *   'Application|15D'       -> ChildOnly=false, IsLegacy=false, MinDeps=12 MaxDeps=15
     *   'Application|ChildOnly' -> ChildOnly=true
     *
     * Output: a List<Map> in manager.docuSignData['templatesIdList'] where each entry has:
     *   - templateId:  vlocity template identifier to send to DocuSign
     *   - signerRole:  'Primary' or 'Legacy' (roleName of the recipient for this composite)
     *   - legacyIndex: null for global composites, 0..N-1 for legacy composites (points into
     *                  the legacyMembers buckets in the tabs map)
     ***************************************************************/
    private void getDocuSignTemplates() {
        System.debug('Executing getDocuSignTemplates...');

         // ---- 1. Gather context ----
        Integer primaryAge   = calculateMemberAge(Date.valueOf((String)((Map<String,Object>)primaryInfo.get('person')).get('dob')));
        Boolean isChildFamily = (primaryAge != null && primaryAge < 18);

        // State template applies if ANY member is in CA, not only the primary
        for (Object memberObj : memberList) {
            Map<String,Object> memberMap = (Map<String,Object>)memberObj;
            Map<String,Object> addressMap =  ((Map<String,Object>)memberMap.get('person')).containsKey('address') && ((Map<String,Object>)memberMap.get('person')).get('address') != null && ((Map<String,Object>)memberMap.get('person')).get('address') != '' ? (Map<String,Object>)((Map<String,Object>)memberMap.get('person')).get('address') : null;
            if (addressMap != null && (String)addressMap.get('state') == 'CA') anyMemberInCA = true;
            if ((String)memberMap.get('role') != 'Primary' && (String)memberMap.get('role') != 'Spouse') this.dependentCount++;
        }

        Map<String,Object> medicalProgramsMap = (Map<String,Object>)((Map<String,Object>)payloadJSON.get('generalInformation')).get('medicalProgram');
        List<ProgramInfo> programs = new List<ProgramInfo>();
        for (String planName : medicalProgramsMap.keySet()) {
            Map<String,Object> planMap = (Map<String,Object>)medicalProgramsMap.get(planName);
            ProgramInfo p = new ProgramInfo();
            p.planName    = planName;
            p.productId   = (String)planMap.get('productId');
            p.isLegacy    = planName.contains('Senior');
            p.programType = p.isLegacy ? 'Senior' : planName.contains('Premier') ? 'Premier' : planName.contains('Access')  ? 'Essential' : 'Enhanced';
            programs.add(p);
        }
        // Ensure deterministic order: non-Senior (base) first, Senior last.
        programs = sortProgramsBaseFirst(programs);

        Boolean anyLegacy = false;
        Boolean anyNonLegacy = false;
        for (ProgramInfo p : programs) {
            if (p.isLegacy) anyLegacy = true;
            else anyNonLegacy = true;
        }

        Boolean needs15D = (!isChildFamily && this.dependentCount >= 12 && anyNonLegacy);

        Map<String,Integer> sectionsOrder = new Map<String,Integer>{
            'QLE'           => 1,
            'Application'   => 2,
            'Authorization' => 3,
            'Program'       => 4,
            'Beneficiaries' => 5,
            'Disclaimer'    => 6,
            'State'         => 7
        };

        // Program: WeShare type for non-Senior (should only be 1 WeShare program); Senior is a single template reused per legacy.
        String weShareProgramType = null;
        for (ProgramInfo p : programs) if (!p.isLegacy) {weShareProgramType = p.programType; break;}

        // ---- 2. Build a single SOQL with OR clauses for every section that may apply ----
        // Each section now has a single physical template; legacy programs reuse them.
        List<String> whereClauses = new List<String>();
        for (String section : sectionsOrder.keySet()) {
            if (section == 'QLE' || (section == 'Disclaimer' && anyLegacy)) whereClauses.add('(ARC_Section__c = ' + '\'' + section +'\' AND ARC_BusinessSegment__c = \'SmallGroup\')');
            else if (section == 'Application') {
                if (isChildFamily) {
                    whereClauses.add('(ARC_Section__c = ' + '\'' + section +'\' AND ARC_BusinessSegment__c = \'SmallGroup\' ' + 'AND ARC_ChildOnly__c = TRUE)');
                } else {
                    // Base Application (non-Legacy, non-ChildOnly) for the regular dependent range
                    if (anyNonLegacy) whereClauses.add('(ARC_Section__c = ' + '\'' + section +'\' AND ARC_BusinessSegment__c = \'SmallGroup\' ' + 'AND ARC_ChildOnly__c = FALSE ' + 'AND ARC_IsLegacy__c = FALSE ' + 'AND ARC_MinDependents__c <= ' + this.dependentCount + ' ' + 'AND ARC_MaxDependents__c >= ' + this.dependentCount + ')');
                    // Senior Application (single template, reused per legacy program)
                    if (anyLegacy) whereClauses.add('(ARC_Section__c = ' + '\'' + section +'\' AND ARC_BusinessSegment__c = \'SmallGroup\' ' + 'AND ARC_ChildOnly__c = FALSE ' + 'AND ARC_IsLegacy__c = TRUE)');
                }
            } 
            else if (section == 'Authorization') whereClauses.add('(ARC_Section__c = ' + '\'' + section +'\' AND ARC_BusinessSegment__c = \'SmallGroup\')');
            else if (section == 'Program' || section == 'Beneficiaries') {
                if (weShareProgramType != null) whereClauses.add('(ARC_Section__c = ' + '\'' + section +'\' AND ARC_ProgramType__c = \'' + weShareProgramType + '\')');
                if (section == 'Program' && anyLegacy) whereClauses.add('(ARC_Section__c = ' + '\'' + section +'\' AND ARC_ProgramType__c = \'Senior\')');
            }
            else if (section == 'State' && anyMemberInCA) whereClauses.add('(ARC_Section__c = \'State\' AND ARC_BusinessSegment__c = \'SmallGroup\' AND ARC_State__c = \'CA\')');
        }

        String queryStr = 'SELECT Id, ARC_TemplateName__c, ARC_Section__c, ARC_ProgramType__c, ARC_State__c, ARC_IsLegacy__c, ARC_ChildOnly__c, ARC_BusinessSegment__c, ARC_MinDependents__c, ARC_MaxDependents__c ' +
            'FROM ARC_DocuSignCompositeTemplates__c ' +
            'WHERE ' + String.join(whereClauses, ' OR ');

        List<ARC_DocuSignCompositeTemplates__c> compTemplates = Database.query(queryStr);

        // ---- 3. Index template names by composite key ----
        Map<String,String> templateNameByKey = new Map<String,String>();
        for (ARC_DocuSignCompositeTemplates__c t : compTemplates) {
            String key = buildTemplateKey(t);
            if (key != null) templateNameByKey.put(key, t.ARC_TemplateName__c);
        }

        // ---- 4. Assemble final ordered list of composite template entries ----
        // Each entry is a Map with:
        //   - templateName: name of the template (later resolved to a templateId)
        //   - signerRole:   'Primary' or 'Legacy' (the recipient roleName for this composite)
        //   - legacyIndex:  null for global composites, 0 or 1 for Legacy composites
        // The legacyIndex points into the legacyMembersInOrder list, which determines
        // which member's data is used to fill the tabs of that composite.
        List<Map<String,Object>> orderedComposites = new List<Map<String,Object>>();
        Map<Integer,String> envelopeOrder = new Map<Integer,String>{
            1 => 'QLE',
            2 => 'Base',
            3 => 'Legacy',
            4 => 'State'
        };


        System.debug('Is child family: ' + isChildFamily + ', WeShare program type: ' + weShareProgramType + ', Needs 15D: ' + needs15D + ', Any member in CA: ' + anyMemberInCA + ', HasWeShareGroup: ' + this.hasWeShareGroup + ', Legacy count: ' + this.legacyCount);
        for (Integer order : envelopeOrder.keySet()) {
            String section = envelopeOrder.get(order);
            if (section == 'QLE') addCompositeIfFound(orderedComposites, templateNameByKey, 'QLE', 'Primary', null);
            else if (section == 'Base') {
                if (isChildFamily) {
                    addCompositeIfFound(orderedComposites, templateNameByKey, 'Application|ChildOnly', 'Primary', null);
                } else if (this.hasWeShareGroup && weShareProgramType != null) {
                    addCompositeIfFound(orderedComposites, templateNameByKey, 'Application|Base', 'Primary', null);
                    if (needs15D) addCompositeIfFound(orderedComposites, templateNameByKey, 'Application|15D', 'Primary', null);
                    addCompositeIfFound(orderedComposites, templateNameByKey, 'Authorization', 'Primary', null);
                    addCompositeIfFound(orderedComposites, templateNameByKey, 'Program|' + weShareProgramType, 'Primary', null);
                    addCompositeIfFound(orderedComposites, templateNameByKey, 'Beneficiaries', 'Primary', null);
                }
            }
            else if (section == 'Legacy' && this.legacyCount > 0) {
                for (Integer legacyIdx = 0; legacyIdx < this.legacyCount; legacyIdx++) {
                    addCompositeIfFound(orderedComposites, templateNameByKey, 'Application|Senior', 'Primary', legacyIdx);
                    addCompositeIfFound(orderedComposites, templateNameByKey, 'Authorization', 'Primary', legacyIdx);
                    addCompositeIfFound(orderedComposites, templateNameByKey, 'Program|Senior', 'Primary', legacyIdx);
                    addCompositeIfFound(orderedComposites, templateNameByKey, 'Disclaimer', 'Legacy', legacyIdx);
                }
            }
            else if (section == 'State' && anyMemberInCA) addCompositeIfFound(orderedComposites, templateNameByKey, 'State|CA', 'Primary', null);
        }
        
        Integer index = 1;
        for (Map<String,Object> compTemp : orderedComposites) {
            String templateName = (String)compTemp.get('templateName');
            System.debug('Composite template ' + index + ': ' + templateName);
            index++;
        }

        // ---- 5. Resolve template names to vlocity template identifiers ----
        Set<String> uniqueTemplateNames = new Set<String>();
        for (Map<String,Object> c : orderedComposites) uniqueTemplateNames.add((String)c.get('templateName'));
        Map<String,String> templateNameToId = new Map<String,String>();
        for (vlocity_ins__VlocityDocuSignTemplate__c v : [SELECT Name, vlocity_ins__templateidentifier__c FROM vlocity_ins__VlocityDocuSignTemplate__c WHERE Name IN :uniqueTemplateNames]) templateNameToId.put(v.Name, v.vlocity_ins__templateidentifier__c);

        // Replace templateName with templateId in each entry (keeping signerRole and legacyIndex).
        List<Map<String,Object>> finalComposites = new List<Map<String,Object>>();
        for (Map<String,Object> c : orderedComposites) {
            String templateName = (String)c.get('templateName');
            if (templateNameToId.containsKey(templateName)) {
                finalComposites.add(new Map<String,Object>{
                    'templateId'  => templateNameToId.get(templateName),
                    'signerRole'  => c.get('signerRole'),
                    'legacyIndex' => c.get('legacyIndex')
                });
            } else {
                System.debug('WARNING: no vlocity template id found for name = ' + templateName);
            }
        }

        this.docuSignTemplates = finalComposites;
    }


    /***************************************************************
     * MAP DOCUSIGN DATA
     * Builds checkboxTabs and textTabs for the envelope.
     * NOTE: Payment and Medical Questions are intentionally excluded
     * for the Group flow.
     ***************************************************************/
    private void mapDocuSignData() {
        System.debug('Executing mapDocuSignData...');

        // Global tabs go in this bucket. They are sent on every composite template scoped to 'global' (or applied as the base for legacy composites).
        Map<String,Object> globalCheckboxTabs = new Map<String,Object>();
        Map<String,Object> globalTextTabs = new Map<String,Object>();

        // One bucket per Legacy member. Used by composites with scope=legacy: the bucket at index N corresponds to the Nth Legacy member (in member-assignment order).
        List<Map<String,Object>> legacyMembersTabs = new List<Map<String,Object>>();
        for (Integer i = 0; i < this.legacyCount; i++) {
            legacyMembersTabs.add(new Map<String,Object>{
                'textTabs'     => new Map<String,Object>(),
                'checkboxTabs' => new Map<String,Object>()
            });
        }

        // Quick lookup: memberIndex -> index in legacyMembersTabs (0 or 1), or null if not Legacy.
        Map<Integer,Integer> memberToLegacyIdx = new Map<Integer,Integer>();
        Integer legacyCursor = 0;
        for (MemberAssignment a : this.memberAssignments) {
            if (a.inLegacy) {
                memberToLegacyIdx.put(a.memberIndex, legacyCursor);
                legacyCursor++;
            }
        }

        Map<String,Object> generalInfoMap = payloadJSON.containsKey('generalInformation') ? (Map<String,Object>)payloadJSON.get('generalInformation') : new Map<String,Object>();
        Map<String,Object> currentStateMap = payloadJSON.containsKey('currentState') ? (Map<String,Object>)payloadJSON.get('currentState') : new Map<String,Object>();
        Map<String,Object> medicalProgramsMap = generalInfoMap.containsKey('medicalProgram') ? (Map<String,Object>)generalInfoMap.get('medicalProgram') : new Map<String,Object>();
        Map<String,List<String>> namesByProductId = new Map<String,List<String>>();
        Map<String,Object> memberNamesByAction = new Map<String,Object>();

        // ---- Demographic info ----
        // Members in a Legacy plan -> their tabs go in legacyMembersTabs[N] under prefix 'Legacy'.
        // Members in WeShare       -> their tabs go in globalTextTabs/globalCheckboxTabs under
        //                             prefix 'Primary' / 'Spouse' / 'DependentN'.
        for (Integer i = 0; i < memberList.size(); i++) {
            Map<String,Object> rawMember = (Map<String,Object>)memberList[i];
            Map<String,Object> memberMap = transformMemberMapKeys(rawMember);
            String memberName = (String)memberMap.get('FirstName') + ' ' + (String)memberMap.get('LastName');
            String memberAction = rawMember.containsKey('action') && rawMember.get('action') != null ? (String)rawMember.get('action') : null;

            // Add member name to a quick lookup map by action
            if (memberAction != null) {
                if (!memberNamesByAction.containsKey(memberAction)) memberNamesByAction.put(memberAction, new List<String>{memberName}); 
                else ((List<String>)memberNamesByAction.get(memberAction)).add(memberName);
            }

            // Track membership per program by productId
            String memberProductId = (String)rawMember.get('productId');
            if (memberProductId != null && !namesByProductId.containsKey(memberProductId)) {
                namesByProductId.put(memberProductId, new List<String>{memberName});
            } else if (memberProductId != null && namesByProductId.containsKey(memberProductId)) {
                namesByProductId.get(memberProductId).add(memberName);
            }

            String prefix = this.memberAssignments[i].tabPrefix;
            if (this.memberAssignments[i].inLegacy) {
                Integer legacyIdx = memberToLegacyIdx.get(i);
                Map<String,Object> lText = (Map<String,Object>)legacyMembersTabs[legacyIdx].get('textTabs');
                Map<String,Object> lCheck = (Map<String,Object>)legacyMembersTabs[legacyIdx].get('checkboxTabs');
                mapMemberFields(memberMap, prefix, lCheck, lText);
            } else {
                mapMemberFields(memberMap, prefix, globalCheckboxTabs, globalTextTabs);
            }
        }

        // ---- Plan-level info (global) ----
        if (generalInfoMap.get('effectiveDate') != null) {
            String effectiveDateStr = String.valueOf(Date.valueOf((String)generalInfoMap.get('effectiveDate')));
            globalTextTabs.put('Plan.EffectiveDate', effectiveDateStr);
            globalTextTabs.put('EffectiveDate', effectiveDateStr);
        }
        if (generalInfoMap.get('totalMonthlyPremium') != null) {
            globalTextTabs.put('Plan.MonthlyContribution', String.valueOf(generalInfoMap.get('totalMonthlyPremium')));
        }

        // ---- Members per program section ("Plan name: member1, member2") ----
        List<String> membersPerProgramList = new List<String>();
        for (String planName : medicalProgramsMap.keySet()) {
            String productId = (String)((Map<String,Object>)medicalProgramsMap.get(planName)).get('productId');
            List<String> names = namesByProductId.get(productId);
            if (names != null && !names.isEmpty()) membersPerProgramList.add(planName + ': ' + String.join(names, ', '));
        }
        if (!membersPerProgramList.isEmpty()) {
            globalTextTabs.put('Info.MembersPerProgramNew', String.join(membersPerProgramList, '\n'));
        }

        // ---- Per-program PayPeriod and ContributionAmount ----
        // WeShare plan -> WeShare.* in global bucket.
        // Legacy plans -> Legacy.* in each member's legacy bucket (matched by member's productId).
        Map<String,Object> legacyPlanByProductId = new Map<String,Object>();
        Map<String,String> legacyPlanNameByProductId = new Map<String,String>();
        Map<String,Object> weSharePlanByProductId = new Map<String,Object>();
        Map<String,String> weSharePlanNameByProductId = new Map<String,String>();
        for (String planName : medicalProgramsMap.keySet()) {
            Map<String,Object> planMap = (Map<String,Object>)medicalProgramsMap.get(planName);
            String productId = (String)planMap.get('productId');
            if (planName.contains('Senior')) {
                legacyPlanByProductId.put(productId, planMap);
                legacyPlanNameByProductId.put(productId, planName);
            } else {
                weSharePlanByProductId.put(productId, planMap);
                weSharePlanNameByProductId.put(productId, planName);
            }
        }

        // Walk Legacy members and emit Legacy.PlanName/PayPeriod/ContributionAmount into each member's own legacy bucket.
        for (MemberAssignment a : this.memberAssignments) {
            if (!a.inLegacy) continue;
            Integer legacyIdx = memberToLegacyIdx.get(a.memberIndex);
            String memberProductId = (String)((Map<String,Object>)memberList[a.memberIndex]).get('productId');
            if (memberProductId == null) continue;
            Map<String,Object> planMap = (Map<String,Object>)legacyPlanByProductId.get(memberProductId);
            String planName = legacyPlanNameByProductId.get(memberProductId);
            if (planMap == null) continue;
            String payPeriod = planMap.get('ARC_PayPeriod__c') != null ? (String)planMap.get('ARC_PayPeriod__c') : '';
            String contributionAmount = planMap.get('contributionAmount') != null ? String.valueOf(planMap.get('contributionAmount')) : '';
            Map<String,Object> lText = (Map<String,Object>)legacyMembersTabs[legacyIdx].get('textTabs');
            lText.put('Legacy.PlanName', planName);
            lText.put('Legacy.PayPeriod', payPeriod);
            lText.put('Legacy.ContributionAmount', contributionAmount);
        }

        // WeShare plan tabs (max 1 per enrollment) -> global bucket
        for (String productId : weSharePlanByProductId.keySet()) {
            Map<String,Object> planMap = (Map<String,Object>)weSharePlanByProductId.get(productId);
            String planName = weSharePlanNameByProductId.get(productId);
            String payPeriod = planMap.get('ARC_PayPeriod__c') != null ? (String)planMap.get('ARC_PayPeriod__c') : '';
            String contributionAmount = planMap.get('contributionAmount') != null ? String.valueOf(planMap.get('contributionAmount')) : '';
            globalTextTabs.put('WeShare.PlanName', planName);
            globalTextTabs.put('WeShare.PayPeriod', payPeriod);
            globalTextTabs.put('WeShare.ContributionAmount', contributionAmount);
            globalTextTabs.put('Programs', namesByProductId.containsKey(productId) ? planName + ': ' + String.join(namesByProductId.get(productId), ', ') : planName);
        }

        // ---- Beneficiaries section ----
        // Maps beneficiary info from members that have it. The app guarantees that only
        // members in a Premier plan and 18+ will have beneficiaries in the JSON.
        // Uses global numbering (TXT_MemberName1, TXT_BeneficiaryName1, ...) and no role
        // prefix. These tabs live in a single Beneficiaries template signed by the Primary.
        Integer beneficiaryCounter = 1;
        for (Object memberObj : memberList) {
            Map<String,Object> member = (Map<String,Object>)memberObj;
            String memberName = (String)((Map<String,Object>)member.get('person')).get('firstName') + ' ' + (String)((Map<String,Object>)member.get('person')).get('lastName');
            Map<String,Object> beneficiaries = member.containsKey('beneficiaries') ? (Map<String,Object>)member.get('beneficiaries') : new Map<String,Object>();

            if (beneficiaries.containsKey('primaryBeneficiary')) {
                Map<String,Object> primaryBeneficiary = (Map<String,Object>)beneficiaries.get('primaryBeneficiary');
                globalTextTabs.put('TXT_MemberName' + beneficiaryCounter, memberName);
                globalTextTabs.put('TXT_BeneficiaryName' + beneficiaryCounter, (String)primaryBeneficiary.get('firstName') + ' ' + (String)primaryBeneficiary.get('lastName'));
                globalTextTabs.put('TXT_BeneficiaryDOB' + beneficiaryCounter, (String)primaryBeneficiary.get('birthdate'));
                globalTextTabs.put('TXT_BeneficiaryPhone' + beneficiaryCounter, String.valueOf(primaryBeneficiary.get('phone')));
                globalTextTabs.put('TXT_BeneficiaryRelationship' + beneficiaryCounter, (String)primaryBeneficiary.get('otherRelationship') != '' ? (String)primaryBeneficiary.get('otherRelationship') : (String)primaryBeneficiary.get('relationship'));
                globalTextTabs.put('TXT_BeneficiaryType' + beneficiaryCounter, 'Primary');
                beneficiaryCounter++;
            }

            if (beneficiaries.containsKey('secondaryBeneficiary')) {
                Map<String,Object> secondaryBeneficiary = (Map<String,Object>)beneficiaries.get('secondaryBeneficiary');
                globalTextTabs.put('TXT_MemberName' + beneficiaryCounter, memberName);
                globalTextTabs.put('TXT_BeneficiaryName' + beneficiaryCounter, (String)secondaryBeneficiary.get('firstName') + ' ' + (String)secondaryBeneficiary.get('lastName'));
                globalTextTabs.put('TXT_BeneficiaryDOB' + beneficiaryCounter, (String)secondaryBeneficiary.get('birthdate'));
                globalTextTabs.put('TXT_BeneficiaryPhone' + beneficiaryCounter, String.valueOf(secondaryBeneficiary.get('phone')));
                globalTextTabs.put('TXT_BeneficiaryRelationship' + beneficiaryCounter, (String)secondaryBeneficiary.get('otherRelationship') != '' ? (String)secondaryBeneficiary.get('otherRelationship') : (String)secondaryBeneficiary.get('relationship'));
                globalTextTabs.put('TXT_BeneficiaryType' + beneficiaryCounter, 'Secondary');
                beneficiaryCounter++;
            }
        }

        // ---- California / HIPAA section ----
        // Note: this is intentionally narrower than the State template inclusion rule.
        // The State *template* is added if ANY member is in CA (see getDocuSignTemplates),
        // but the California tabs (Primary DOB breakdown, HIPAA list) only apply when
        // the Primary is the one residing in CA.
        if (anyMemberInCA) mapCaliforniaSection(generalInfoMap, globalTextTabs);

        // ---- QLE section ----
        String effectiveDate = generalInfoMap.get('effectiveDate') != null ? String.valueOf(generalInfoMap.get('effectiveDate')) : null;

        List<Object> currentMemberList = currentStateMap.containsKey('currentMembers') ? (List<Object>)currentStateMap.get('currentMembers') : null;
        Map<String,Object> currentProgramsMap = currentStateMap.containsKey('currentProducts') ? (Map<String,Object>)currentStateMap.get('currentProducts') : null;
        Map<String,List<String>> currentNamesByProductId = new Map<String,List<String>>();

        if (currentMemberList != null && !currentMemberList.isEmpty()) {
            for (Object member : currentMemberList) {
                Map<String,Object> memberMap = (Map<String,Object>)member;
                String memberName = (String)((Map<String,Object>)memberMap.get('person')).get('firstName') + ' ' + (String)((Map<String,Object>)memberMap.get('person')).get('lastName');
                String memberProductId = (String)memberMap.get('productId');
                if (memberProductId != null && !currentNamesByProductId.containsKey(memberProductId)) {
                    currentNamesByProductId.put(memberProductId, new List<String>{memberName});
                } else if (memberProductId != null && currentNamesByProductId.containsKey(memberProductId)) {
                    currentNamesByProductId.get(memberProductId).add(memberName);
                }
            }
        }
        List<String> currentMembersPerProgramList = new List<String>();
        for (String currentPlanName : currentProgramsMap.keySet()) {
            Map<String,Object> currentPlanMap = (Map<String,Object>)currentProgramsMap.get(currentPlanName);
            String currentProductId = (String)currentPlanMap.get('productId');
            List<String> currentNames = currentNamesByProductId.containsKey(currentProductId) ? currentNamesByProductId.get(currentProductId) : null;
            currentMembersPerProgramList.add(currentNames != null ? currentPlanName + ': ' + String.join(currentNames, ', ') : currentPlanName);
        }
        globalTextTabs.put('Info.MembersPerProgramOld', currentMembersPerProgramList.isEmpty() ? '' : String.join(currentMembersPerProgramList, '\n'));
        globalTextTabs.put('Info.CurrentProgram', currentProgramsMap.keySet().size() > 0 ? String.join(currentProgramsMap.keySet(), '; ') : '');

        Map<String,Object> qleInfoMap = payloadJSON.containsKey('qle') ? (Map<String,Object>)payloadJSON.get('qle') : new Map<String,Object>();
        String qleType = qleInfoMap.containsKey('qleType') && qleInfoMap.get('qleType') != null ? (String)qleInfoMap.get('qleType') : '';
        String qleSubtype = qleInfoMap.containsKey('qleSubtype') && qleInfoMap.get('qleSubtype') != null ? (String)qleInfoMap.get('qleSubtype') : '';
        globalTextTabs.put('Info.ReasonForChange', qleType != '' && qleSubtype != '' ? qleType + ' - ' + qleSubtype : qleSubtype == '' ? qleType : '');

        Map<String,Object> qleChangesMap = generalInfoMap.containsKey('qleChanges') ? (Map<String,Object>)generalInfoMap.get('qleChanges') : new Map<String,Object>();
        List<String> qleChangeList = new List<String>();
        if (!qleChangesMap.isEmpty()) {
            for (String qleChange : qleChangesMap.keySet()) {
                if (qleChangesMap.get(qleChange) != null && (Boolean)qleChangesMap.get(qleChange) == true) {
                    String qleChangeStr = '';
                    if (qleChange == 'agingOut') qleChangeStr = 'Aging out';
                    else if (qleChange == 'programDowngrade') qleChangeStr = 'Program Downgrade';
                    else if (qleChange == 'programUpgrade') qleChangeStr = 'Program Upgrade';
                    else if (qleChange == 'removeMember') qleChangeStr = 'Remove Member';
                    else if (qleChange == 'addMember') qleChangeStr = 'Add Member';
                    if (qleChangeStr != '') {
                        if (memberNamesByAction.containsKey(qleChangeStr)) qleChangeList.add(effectiveDate + ' ' + qleChangeStr + ': ' + String.join((List<String>)memberNamesByAction.get(qleChangeStr), ', '));
                        else qleChangeList.add(effectiveDate + ' ' + qleChangeStr);
                    }
                }
            }
        }
        globalTextTabs.put('Info.RequestedChanges', qleChangeList.isEmpty() ? '' : String.join(qleChangeList, '\n'));

        this.tabsMap = new Map<String,Object>{
            'global' => new Map<String,Object>{
                'textTabs'     => globalTextTabs,
                'checkboxTabs' => globalCheckboxTabs
            },
            'legacyMembers' => legacyMembersTabs
        };
        System.debug(JSON.serializePretty(this.tabsMap));
    }




    /*******************************************AUXILIAR METHODS***************************************************** */
    private Integer calculateMemberAge(Date memberDOB) {
        if (memberDOB == null || memberDOB > Date.today()) return null;
        Date today = Date.today();
        Integer age = today.year() - memberDOB.year();
        if (today.month() < memberDOB.month() || (today.month() == memberDOB.month() && today.day() < memberDOB.day())) {
            age--;
        }
        return age;
    }

    private Map<String,Object> getPrimaryInfo(List<Object> memberList) {
        Map<String,Object> primary = new Map<String,Object>();
        if (memberList != null) {
            for (Object member : memberList) {
                if ((String)((Map<String,Object>)member).get('role') == 'Primary') {
                    primary = (Map<String,Object>)member;
                }
            }
        }
        return primary;
    }

    /**
     * Sort programs so non-Senior (base) come first and Senior come last.
     * Within each group, original insertion order is preserved.
     */
    private List<ProgramInfo> sortProgramsBaseFirst(List<ProgramInfo> input) {
        List<ProgramInfo> base   = new List<ProgramInfo>();
        List<ProgramInfo> senior = new List<ProgramInfo>();
        for (ProgramInfo p : input) {
            if (p.isLegacy) senior.add(p);
            else            base.add(p);
        }
        List<ProgramInfo> sorted = new List<ProgramInfo>();
        sorted.addAll(base);
        sorted.addAll(senior);
        return sorted;
    }

    /**
     * Sort a list of memberList indexes by hierarchy:
     *   Primary first, then Spouse, then other dependents oldest-first (by DOB ascending).
     * Returns a new list, leaves input untouched.
     */
    private List<Integer> sortByHierarchy(List<Integer> indexes) {
        Integer primaryIdx = null;
        Integer spouseIdx = null;
        List<Integer> dependents = new List<Integer>();
        for (Integer idx : indexes) {
            String role = (String)((Map<String,Object>)memberList[idx]).get('role');
            if (role == 'Primary') primaryIdx = idx;
            else if (role == 'Spouse') spouseIdx = idx;
            else dependents.add(idx);
        }
        // Sort dependents by DOB ascending (oldest first)
        dependents = sortDependentsByAgeDesc(dependents);

        List<Integer> ordered = new List<Integer>();
        if (primaryIdx != null) ordered.add(primaryIdx);
        if (spouseIdx != null) ordered.add(spouseIdx);
        ordered.addAll(dependents);
        return ordered;
    }

    /**
     * Sort dependent member indexes by age descending (oldest first).
     * Uses a simple insertion sort since the list is small (max ~15).
     */
    private List<Integer> sortDependentsByAgeDesc(List<Integer> indexes) {
        List<Integer> sorted = new List<Integer>(indexes);
        for (Integer i = 1; i < sorted.size(); i++) {
            Integer current = sorted[i];
            Date currentDob = Date.valueOf((String)((Map<String,Object>)((Map<String,Object>)memberList[current]).get('person')).get('dob'));
            Integer j = i - 1;
            while (j >= 0) {
                Date jDob = Date.valueOf((String)((Map<String,Object>)((Map<String,Object>)memberList[sorted[j]]).get('person')).get('dob'));
                // We want oldest first, so the older DOB (smaller Date) comes first.
                if (jDob > currentDob) {
                    sorted[j + 1] = sorted[j];
                    j--;
                } else {
                    break;
                }
            }
            sorted[j + 1] = current;
        }
        return sorted;
    }

    /**
     * Build the composite key used to look up a template by its discriminator attributes.
     * Since each section now has a single physical template, keys no longer carry a slot suffix.
     */
    private String buildTemplateKey(ARC_DocuSignCompositeTemplates__c t) {
        if (t.ARC_Section__c == 'QLE') return 'QLE';
        if (t.ARC_Section__c == 'Application') {
            if (t.ARC_ChildOnly__c == true) return 'Application|ChildOnly';
            if (t.ARC_IsLegacy__c == true) return 'Application|Senior';
            if (t.ARC_MinDependents__c == 12 && t.ARC_MaxDependents__c == 15) return 'Application|15D';
            return 'Application|Base';
        }
        if (t.ARC_Section__c == 'Authorization') return 'Authorization';
        if (t.ARC_Section__c == 'Program') {
            if (t.ARC_ProgramType__c == 'Senior') return 'Program|Senior';
            return 'Program|' + t.ARC_ProgramType__c;
        }
        if (t.ARC_Section__c == 'State') return 'State|' + t.ARC_State__c;
        if (t.ARC_Section__c == 'Disclaimer') return 'Disclaimer';
        if (t.ARC_Section__c == 'Beneficiaries') return 'Beneficiaries';
        return null;
    }

        /**
     * Helper for the rich composite list: looks up the template name by key and pushes
     * a fully-formed composite entry if the name exists.
     */
    private void addCompositeIfFound(List<Map<String,Object>> target, Map<String,String> nameByKey, String key, String signerRole, Integer legacyIndex) {
        if (!nameByKey.containsKey(key)) return;
        target.add(new Map<String,Object>{
            'templateName' => nameByKey.get(key),
            'signerRole'   => signerRole,
            'legacyIndex'  => legacyIndex
        });
    }

    /**
     * Flatten a member (or guardian) map into DocuSign-friendly keys.
     */
    private Map<String,Object> transformMemberMapKeys(Map<String,Object> memberMap) {
        Map<String,Object> personInfoMap = memberMap.containsKey('person') ? (Map<String,Object>)memberMap.get('person') : memberMap;
        String relationship = memberMap.containsKey('role') ? (String)memberMap.get('role') : (String)personInfoMap.get('relationship');
        String height = String.valueOf(personInfoMap.get('heightFeet')) + '\'' + String.valueOf(personInfoMap.get('heightInches')) + '"';
        String memberSSN = (String)personInfoMap.get('ssn');
        Map<String,Object> addressMap = personInfoMap.containsKey('address') && personInfoMap.get('address') != null && personInfoMap.get('address') != '' ? (Map<String,Object>)personInfoMap.get('address') : null;

        return new Map<String,Object>{
            'MemberExternalId' => (String)memberMap.get('memberExternalId'),
            'FirstName' => (String)personInfoMap.get('firstName'),
            'MI' => (String)personInfoMap.get('middleInitial'),
            'LastName' => (String)personInfoMap.get('lastName'),
            'Relationship' => relationship,
            'DOB' => personInfoMap.get('dob') != null ? String.valueOf(Date.valueOf((String)personInfoMap.get('dob'))) : null,
            'Gender' => (String)personInfoMap.get('gender'),
            'Phone' => (String)personInfoMap.get('phone'),
            'Email' => (String)personInfoMap.get('email'),
            'SocialSecurity' => (memberSSN != null && memberSSN.length() >= 4) ? 'XXX-XX-' + memberSSN.right(4) : null,
            'SSN' => (memberSSN != null && memberSSN.length() >= 4) ? 'XXX-XX-' + memberSSN.right(4) : null,
            'Height' => height,
            'Weight' => personInfoMap.get('weightLbs') != null ? String.valueOf(personInfoMap.get('weightLbs')) : null,
            'Pregnant' => personInfoMap.containsKey('pregnant') && personInfoMap.get('pregnant') != null && personInfoMap.get('pregnant') != '' ? (Boolean)personInfoMap.get('pregnant') : null,
            'Smoker' => personInfoMap.containsKey('smoker') && personInfoMap.get('smoker') != null && personInfoMap.get('smoker') != '' ? (Boolean)personInfoMap.get('smoker') : null,
            'Address' => addressMap != null ? (String)addressMap.get('street') : null,
            'City' => addressMap != null ? (String)addressMap.get('city') : null,
            'State' => addressMap != null ? (String)addressMap.get('state') : null,
            'ZipCode' => addressMap != null ? (String)addressMap.get('zip') : null,
            'MedicareNumber' => personInfoMap.containsKey('MedicareId') && personInfoMap.get('MedicareId') != null && personInfoMap.get('MedicareId') != '' ? (String)personInfoMap.get('MedicareId') : null,
            'MedicarePartAEffectiveDate' => personInfoMap.containsKey('MedicarePartA') ? (String)personInfoMap.get('MedicarePartA') : null,
            'MedicarePartBEffectiveDate' => personInfoMap.containsKey('MedicarePartB') ? (String)personInfoMap.get('MedicarePartB') : null,
            'MedicarePartCEffectiveDate' => personInfoMap.containsKey('MedicarePartC') ? (String)personInfoMap.get('MedicarePartC') : null,
            'MedicarePartDEffectiveDate' => personInfoMap.containsKey('MedicarePartD') ? (String)personInfoMap.get('MedicarePartD') : null,
            'MedicarePartA' => personInfoMap.containsKey('MedicarePartA') && personInfoMap.get('MedicarePartA') != null && personInfoMap.get('MedicarePartA') != '' ? true : false,
            'MedicarePartB' => personInfoMap.containsKey('MedicarePartB') && personInfoMap.get('MedicarePartB') != null && personInfoMap.get('MedicarePartB') != '' ? true : false,
            'MedicarePartC' => personInfoMap.containsKey('MedicarePartC') && personInfoMap.get('MedicarePartC') != null && personInfoMap.get('MedicarePartC') != '' ? true : false,
            'MedicarePartD' => personInfoMap.containsKey('MedicarePartD') && personInfoMap.get('MedicarePartD') != null && personInfoMap.get('MedicarePartD') != '' ? true : false
        };
    }

    /**
     * Map a single member's text/checkbox tabs under the given prefix
     * (Primary, Spouse, Dependent1, Dependent2, ...).
     */
    private void mapMemberFields(Map<String,Object> memberMap, String prefix, Map<String,Object> checkboxTabs, Map<String,Object> textTabs) {
        for (String key : memberMap.keySet()) {
            Object value = memberMap.get(key);
            if (value instanceOf Boolean) {
                 if (key == 'Smoker') {
                    checkboxTabs.put(prefix + '.Smoker', value == true);
                    checkboxTabs.put(prefix + '.NotSmoker', value != true);
                } else if (key == 'Pregnant') {
                    checkboxTabs.put(prefix + '.Pregnant', value == true);
                    checkboxTabs.put(prefix + '.NotPregnant', value != true);
                } else {
                    checkboxTabs.put(prefix + '.' + key, value == true);
                }
            }
            else if (value instanceOf String) {
                if (key == 'Gender') {
                    checkboxTabs.put(prefix + '.' + (String)value, true);
                    // IsMale / IsFemale flags as checkboxes
                    checkboxTabs.put(prefix + '.IsMale', value == 'Male');
                    checkboxTabs.put(prefix + '.IsFemale', value == 'Female');
                } else {
                textTabs.put(prefix + '.' + key, (value == null) ? null : (String)value);
                }
            }
        }
    }

    /**
     * California-specific mappings (primary DOB broken out by month/day/year, HIPAA list).
     */
    private void mapCaliforniaSection(Map<String,Object> generalInfoMap, Map<String,Object> textTabs) {
        Map<String,Object> primaryPerson = (Map<String,Object>)primaryInfo.get('person');
        textTabs.put('Primary.FullName', (String)primaryPerson.get('firstName') + ' ' + (String)primaryPerson.get('lastName'));

        if (primaryPerson.get('dob') != null) {
            Date primaryDOB = Date.valueOf((String)primaryPerson.get('dob'));
            textTabs.put('Primary.MonthOfBirth', String.valueOf(primaryDOB.month()));
            textTabs.put('Primary.DayOfBirth', String.valueOf(primaryDOB.day()));
            textTabs.put('Primary.YearOfBirth', String.valueOf(primaryDOB.year()));
        }

        List<Object> hipaaList = generalInfoMap.get('hipaa') != null ? (List<Object>)generalInfoMap.get('hipaa') : new List<Object>();
        Integer idx = 1;
        for (Object hipaa : hipaaList) {
            Map<String,Object> hipaaMap = (Map<String,Object>)hipaa;
            // Only HIPAA entries other than the primary
            if ((String)hipaaMap.get('relationship') != 'Primary') {
                textTabs.put('Hipaa' + idx, (String)hipaaMap.get('firstName') + ' ' + (String)hipaaMap.get('lastName'));
                idx++;
            }
        }
    }

}