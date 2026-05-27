public with sharing class ARC_SE_DocuSign {
    // public ARC_SEManagerNico manager;
    public ARC_SEManager manager;
    public Map<String,Object> enrollmentInfo = new Map<String,Object>();
    public List<Object> memberList = new List<Object>();
    public Map<String,Object> primaryInfo = new Map<String,Object>();
    public Integer dependentCount = 0;

    private static Map<String,String> creditCardType = new Map<String,String>{
        '2' => 'MasterCard',
        '3' => 'Amex',
        '4' => 'Visa',
        '5' => 'MasterCard',
        '6' => 'Discover'
    };

    private static Map<String,String> medicalKeysMap = new Map<String,String>{
        'familyHistory' => 'ParentSiblingDiagnosed', // Q1
        'symptoms' => 'UnexpectedSymptoms', // Q2
        'consulted' => 'PendingTests', // Q3
        'cancer' => 'Cancers', // Q4
        'otherDx' => 'PastConditions', // Q5
        'substance' => 'Addictions', // Q6
        'dui' => 'LicenceSuspended' // Q7
    };  

    private static List<String> MQGroup1 = new List<String> {
        'familyHistory','symptoms','consulted','otherDx','substance','dui'
    };

    private static Map<String,String> pastConditionsMap = new Map<String,String>{
        'Alcohol Abuse' => '1',
        'ALS' => '2',
        'Alzheimer’s Disease' => '3',
        'Abdominal Aortic Aneurysm' => '4',
        'Aneurysm, Cerebral' => '5',
        'Autism Spectrum Disorders' => '6',
        'Bipolar with 2 or more current medications' => '7',
        'Cerebral Palsy' => '8',
        'Chronic Obstructive Pulmonary Disease (COPD)' => '9',
        'Chronic Kidney Disease, stage 3b, 4 or 5' => '10',
        'Cystic Fibrosis' => '11',
        'Dementia' => '12',
        'Diabetes, Type I' => '13',
        'Diabetes, Type 2 when taking 2 heart medications, or have kidney/liver disease' =>  '14',
        'Down’s Syndrome' => '15',
        'Ectasia' => '16',
        'Emphysema' => '17',
        'Fragile X Syndrome' => '18',
        'Fibromyalgia (w/ treatment)' => '19',
        'Hepatitis (Chronic Viral B & C)' => '20',
        'HIV/AIDS' => '21',
        'Lupus' => '22',
        'Macular Degeneration (wet or dry)' => '23',
        'Marfan’s Syndrome' => '24',
        'Morbid Obesity (BMI > 40)' => '25',
        'Multiple Sclerosis' => '26',
        'Muscular Dystrophy' => '27',
        'Paralysis' => '28',
        'Parkinson’s Disease' => '29',
        'Rheumatoid Arthritis w/ biologic treatment' => '30',
        'Schizophrenia with 2 or more current medications' => '31',
        'Sickle-Cell Disease' => '32',
        'Sjogren Syndrome' => '33',
        'Spina Bifida' => '34',
        'Systemic Lupus Erythematosus' => '35',
        'Typhoid' => '36',
        'Underweight (BMI <15)' => '37',
        'Inpatient Psychiatric Treatment within past 5 years' => '38',
        'Treatment with Naloxone, Suboxone, Methadone or any other medication to treat addiction within the past 5 years' => '39'
    };

    public void getDocuSignData (ARC_SEManager manager) {
        try {
            this.manager = manager;
            this.enrollmentInfo = manager.enrollmentInfo;

            // Get member list and primary info
            this.memberList = (List<Object>)this.enrollmentInfo.get('members');
            this.primaryInfo = getPrimaryInfo(this.memberList);

            // Get signer list
            getSignerList();
            // Get template Id
            getDocuSignTemplateId();
            // Map DocuSign data
            mapDocuSignData();

            // Serialize DocuSign JSON data 
            manager.serializedSignerList = manager.docuSignData.containsKey('signerList') && manager.docuSignData.get('signerList') != null ? JSON.serialize(manager.docuSignData.get('signerList')) : '';
            manager.serializedTemplatesId = manager.docuSignData.containsKey('templatesIdList') && manager.docuSignData.get('templatesIdList') != null ? JSON.serialize(manager.docuSignData.get('templatesIdList')) : '';
            manager.serializedTabsMap = manager.docuSignData.containsKey('tabs') && manager.docuSignData.get('tabs') != null ? JSON.serialize(manager.docuSignData.get('tabs')) : '';

        } catch (Exception e) {
            System.debug('Error in getDocuSignData: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }


    /**
     * Get the signer list to sign the DocuSign
     */
    private void getSignerList() {
        System.debug('Getting signer list');
        List<Map<String,Object>> signerList = new List<Map<String,Object>>();
        Integer signersCount = 0;

        for (Object member : this.memberList) {
            Date memberDOB = Date.valueOf((String)((Map<String,Object>)((Map<String,Object>)member).get('person')).get('dob')); // Get current member DOB
            Integer memberAge = calculateMemberAge(memberDOB); // Calculate member age
            if (memberAge >= 18) signersCount++;
        }

        // Build Signer List for COMPOSITE TEMPLATES
        Integer signerDependentCount = 0;
        for (Integer i = 1; i <= this.memberList.size(); i++) {
            Map<String,Object> signerMap = new Map<String,Object>(); // Map to add to signer list
            Map<String,Object> memberMap = (Map<String,Object>)memberList[i-1]; // Map of current member
            Date memberDOB = Date.valueOf((String)((Map<String,Object>)memberMap.get('person')).get('dob')); // Get current member DOB
            Integer memberAge = calculateMemberAge(memberDOB); // Calculate member age
            String memberRelationship = (String)memberMap.get('role'); // Get member relationship
            // Add member to signer list if it 18 or older
            if (memberAge >= 18) {
                if (memberRelationship != 'Primary' && memberRelationship != 'Spouse') signerDependentCount++;
                String memberName = (String)((Map<String,Object>)memberMap.get('person')).get('firstName') + ' ' + (String)((Map<String,Object>)memberMap.get('person')).get('lastName');
                String memberEmail = String.valueOf((String)((Map<String,Object>)memberMap.get('person')).get('email'));
                String memberPhone = String.valueOf((String)((Map<String,Object>)memberMap.get('person')).get('phone'));
                //String accessCode = String.valueOf((String)((Map<String,Object>)memberMap.get('person')).get('ssn'));
                signerMap.put('recipientId', String.valueOf(i));
                signerMap.put('name', memberName);
                signerMap.put('email', memberEmail);
                //signerMap.put('accessCode', accessCode);
                signerMap.put('deliveryMethod', 'Email');
                signerMap.put('roleName', memberRelationship == 'Primary' || memberRelationship == 'Spouse' ? memberRelationship : 'Dependent' + signerDependentCount);
                signerList.add(signerMap);
            }
            // Map Guardian as signer when primary is under 18
            else if (memberAge < 18 && memberRelationship == 'Primary') {
                Map<String,Object> guardianMap = (Map<String,Object>)((Map<String,Object>)this.enrollmentInfo.get('generalInformation')).get('guardian');
                if (guardianMap != null && !guardianMap.isEmpty()) {
                    signerMap.put('recipientId', String.valueOf(i));
                    signerMap.put('name', (String)guardianMap.get('firstName') + ' ' + (String)guardianMap.get('lastName'));
                    signerMap.put('email', (String)guardianMap.get('email'));
                    signerMap.put('roleName', 'Primary');
                    signerList.add(signerMap);
                }
            }
            // Increase dependent count if member is Child
            this.dependentCount = memberRelationship == 'Primary' || memberRelationship == 'Spouse' ? this.dependentCount : this.dependentCount + 1;
        }
        System.debug('Signer List in getSignerList method: ' + signerList);
        manager.docuSignData.put('signerList', signerList);
    }

    /**
     * @Description: Get template Id to use for envelope based on number of dependents, primary state
     */
    private void getDocuSignTemplateId() {
        // System.debug('Getting DocuSign template ID...');
        // // Get number of dependents
        // Integer dependents = this.dependentCount;
        // System.debug('Number of dependents: ' + dependents);

        // // Get state of primary member
        // String primaryState = (String)((Map<String,Object>)((Map<String,Object>)primaryInfo.get('person')).get('address')).get('state');
        // System.debug('Primary state: ' + primaryState);

        // // Check if plan is Legacy
        // Boolean isLegacy = false;
        // String medicalPlanName;
        // Map<String,Object> medicalPlanMap = (Map<String,Object>)((Map<String,Object>)enrollmentInfo.get('generalInformation')).get('medicalProgram');
        // if (medicalPlanMap != null && !medicalPlanMap.isEmpty()) {
        //     medicalPlanName = (String)medicalPlanMap.get('name');
        //     isLegacy = medicalPlanName == 'WeShare Legacy' ? true : false;
        // }

        // // Check if primary is minor
        // Integer primaryAge = calculateMemberAge(Date.valueOf((String)((Map<String,Object>)primaryInfo.get('person')).get('dob')));
        // Boolean isPrimaryUnder18 = primaryAge < 18 ? true : false;

        // // Query
        // String templateNameStr = '';
        // if (isLegacy) {
        //     templateNameStr = primaryState == 'CA' ? 'WeShare Legacy Membership Application CA' : 'WeShare Legacy Membership Application';
        // } else {
        //     String queryStr = 'SELECT ARC_Template_Name__c, ARC_DRTransform__c ';
        //     queryStr += 'FROM ARC_DocuSignTemplates__c';
        //     queryStr += ' WHERE ARC_Contract_Reasons__c LIKE \'%New Application%\'';
        //     queryStr += ' AND ARC_Min_Dependents__c <= ' + dependents;
        //     queryStr += ' AND ARC_Max_Dependents__c >= ' + dependents;
        //     if (isPrimaryUnder18) queryStr += ' AND ARC_ChildOnly__c = true';
        //     if (primaryState == 'CA') queryStr += ' AND ARC_State__c = \'CA\'';
        //     queryStr += medicalPlanName.contains('Access') ? ' AND ARC_PlanType__c = \'Access\'' : medicalPlanName.contains('Legacy') ? ' AND ARC_PlanType__c = \'Legacy\'' : ' AND ARC_PlanType__c = \'WeShare\'';
        //     // if (medicalPlanName.contains('Access')) {
        //     //     queryStr += ' AND ARC_PlanType__c = \'Access\'';
        //     // } else {
        //     //     queryStr += ' AND ARC_PlanType__c = \'WeShare\'';
        //     // }
        //     queryStr += ' ORDER BY ARC_Template_Name__c ASC LIMIT 1';
        //     ARC_DocuSignTemplates__c templateSettings = Database.query(queryStr);
        //     templateNameStr = templateSettings.ARC_Template_Name__c;
        // }
        // System.debug('templateNameStr: ' + templateNameStr);
        // vlocity_ins__VlocityDocuSignTemplate__c template = [
        //     SELECT Id, Name, vlocity_ins__templateidentifier__c
        //     FROM vlocity_ins__VlocityDocuSignTemplate__c
        //     WHERE name = :templateNameStr
        //     ORDER BY LastModifiedDate DESC LIMIT 1
        // ];
        // System.debug('template: ' + template);
        // Map<String, Object> DocuSignTemplateId = new Map<String, Object>();
        // DocuSignTemplateId.put('Id', template.Id);
        // DocuSignTemplateId.put('Name', template.Name);
        // DocuSignTemplateId.put('TemplateId', template.vlocity_ins__templateidentifier__c);
        // manager.docuSignData.put('DocuSignTemplateId', DocuSignTemplateId);


        // COMPOSITE TEMPLATES INTEGRATION
        System.debug('STARTING COMPOSITE TEMPLATES...');
        
        // Get number of dependents
        Integer dependents = this.dependentCount;
        System.debug('Number of dependents: ' + dependents);
        // Check if it is a Child Family
        Integer primaryAge = calculateMemberAge(Date.valueOf((String)((Map<String,Object>)primaryInfo.get('person')).get('dob')));
        Boolean isChildFamily = primaryAge < 18 ? true : false;
        System.debug('Is Child Family? ' + isChildFamily);
        // Get state of primary member
        String primaryState = (String)((Map<String,Object>)((Map<String,Object>)primaryInfo.get('person')).get('address')).get('state');
        System.debug('Primary State: ' + primaryState);
        // Get medical program selected type
        Map<String,Object> medicalPlanMap = (Map<String,Object>)((Map<String,Object>)enrollmentInfo.get('generalInformation')).get('medicalProgram');
        String medicalPlanName = (String)medicalPlanMap.get('name');
        String programType = medicalPlanName.contains('Legacy') ? 'Senior' : medicalPlanName.contains('Premier') ? 'Premier' : medicalPlanName.contains('Access') ? 'Essential' : 'Enhanced';
        System.debug('Program Type: ' + programType);
        // Check if it is Legacy
        Boolean isLegacy = medicalPlanName.contains('Legacy') ? true : false;

        // Section order map
        Map<String,Integer> orderMap = new Map<String,Integer> {
            'Application' => 1,
            'Program' => 2,
            'Beneficiaries' => 3,
            'Payment' => 4, 
            'State' => 5
        };

        List<String> clausesList = new List<String>();
        for (String section : orderMap.keySet()) {
            String sectionStr = '(ARC_Section__c = ' + '\'' + section +'\' ';

            if (section == 'Application') {
                sectionStr += 'AND ARC_BusinessSegment__c = \'IndividualAndFamily\' AND ARC_MinDependents__c <= ' + dependents + ' AND ARC_MaxDependents__c >= ' + dependents + ' AND ARC_ChildOnly__c = ' + isChildFamily + ' AND ARC_IsLegacy__c = ' + isLegacy;
            } else if (section == 'Program' || section == 'Beneficiaries') {
                sectionStr += 'AND ARC_ProgramType__c = \'' + programType + '\'';
            } else if (section == 'State') {
                sectionStr += 'AND ARC_State__c = \'' + primaryState + '\'';
            }
            sectionStr += ')';
            clausesList.add(sectionStr);
        }

        // Query
        String queryStr = 'SELECT Id, ARC_TemplateName__c, ARC_Section__c FROM ARC_DocuSignCompositeTemplates__c '; // Base query string
        if (clausesList != null && !clausesList.isEmpty()) {
            String allClausesStr = String.join(clausesList, ' OR ');
            queryStr += 'WHERE ' + allClausesStr;
        }
        System.debug('Query String: ' + queryStr);

        List<ARC_DocuSignCompositeTemplates__c> compTemplates = Database.query(queryStr);
        List<String> templatesList = new List<String>();
        Map<Integer,String> orderToTemplateNameMap = new Map<Integer,String>();
        for (ARC_DocuSignCompositeTemplates__c compTemplate : compTemplates) {
            String templateName = compTemplate.ARC_TemplateName__c;
            orderToTemplateNameMap.put(orderMap.get(compTemplate.ARC_Section__c), templateName);
            templatesList.add(templateName);
        }
        List<vlocity_ins__VlocityDocuSignTemplate__c> templates = [
            SELECT Id, Name, vlocity_ins__templateidentifier__c
            FROM vlocity_ins__VlocityDocuSignTemplate__c
            WHERE Name IN :templatesList
        ];


        // Order the vlocity templates in the correct seciton order
        Map<String,String> tempNameToTempId = new Map<String,String>();
        for (vlocity_ins__VlocityDocuSignTemplate__c temp : templates) {
            String tempName = temp.Name;
            tempNameToTempId.put(tempName, temp.vlocity_ins__templateidentifier__c);
        }

        List<String> finalTemplatesIdList = new List<String>();
        for (Integer i = 1 ; i <= orderMap.values().size() ; i++) {
            String tempNameToAdd = orderToTemplateNameMap.get(i);
            System.debug('Template ' + i + ': ' + tempNameToAdd);
            if (tempNameToAdd != null) {
                finalTemplatesIdList.add(tempNameToTempId.get(tempNameToAdd));
            }
        }
        System.debug('Final template id list: ' + finalTemplatesIdList );

        // manager.docuSignData.put('templatesIdList', finalTemplatesIdList);
        manager.docuSignData.put('templatesIdList', finalTemplatesIdList);

    }
    
    /**
     * @Description: Map and get the DocuSign data to fill the template
     */
    private void mapDocuSignData() {
        System.debug('Mapping docusign data');
        // Maps to return
        Map<String,Object> checkboxTabs = new Map<String,Object>();
        Map<String,Object> textTabs = new Map<String,Object>();

        // Get general data maps from JSON
        Map<String,Object> generalInfoMap = (Map<String,Object>)enrollmentInfo.get('generalInformation');
        Map<String,Object> paymentMap = (Map<String,Object>)generalInfoMap.get('payment');
        Map<String,Object> medicalPlanMap = (Map<String,Object>)generalInfoMap.get('medicalProgram');

        // Variables to be used later
        List<String> memberNamesList = new List<String>(); // List of all member names
        List<String> membersPerProgramList = new List<String>(); // List of all plans with its members concatanated for each plan
        Map<String, Map<String,List<String>>> parentAncillaryGroupMembers = new Map<String, Map<String,List<String>>>();  // Map with ancillary name as key and a list of members as value for each ancillary

        // ITERATE OVER MEMBER LIST
        Integer dependent = 0; // Index for members section in DS template
        Integer dependentCA = 0; // Index for CA members section with DOB
        Integer medicalNotesIndex = 1; // Index for medical notes section in DS template
        Integer prescriptionsIndex = 1; // Index for prescriptions section in DS template
        for (Object member : this.memberList) {
            Map<String,Object> memberMap = transformMemberMapKeys((Map<String,Object>)member); // Get member map with the keys transformed for DS keys
            String memberName = (String)memberMap.get('FirstName') + ' ' + (String)memberMap.get('LastName');
            Integer memberAge = memberMap.containsKey('DOB') ? calculateMemberAge(Date.valueOf((String)memberMap.get('DOB'))) : null;
            System.debug('Member age: '+ memberAge);
            memberNamesList.add(memberName);
            // DEMOGRAPHIC INFORMATION
            // Map primary member keys
            if ((String)memberMap.get('Relationship') == 'Primary') {
                for (String key : memberMap.keySet()) {
                    if (key == 'Smoker' || key == 'Pregnant' || key == 'Gender') {
                        checkboxTabs.put('Primary.' + (String)memberMap.get('Gender'), true);
                        checkboxTabs.put('Primary.Smoker', memberMap.get('Smoker') == true ? true : false);
                        checkboxTabs.put('Primary.NotSmoker', memberMap.get('Smoker') != true ? true : false);
                        checkboxTabs.put('Primary.Pregnant', memberMap.get('Pregnant') == true ? true : false);
                        checkboxTabs.put('Primary.NotPregnant', memberMap.get('Pregnant') != true ? true : false);      
                    } else {
                        textTabs.put('Primary.' + key, (String)memberMap.get(key));
                        if (key == 'DOB') textTabs.put('Primary.DOB2', memberAge >= 18 ? String.valueOf(Date.valueOf(String.valueOf(memberMap.get(key)))) : null);
                    }
                }
            }
            // Map spouse member keys
            else if ((String)memberMap.get('Relationship') == 'Spouse') {
                for (String key : memberMap.keySet()) {
                    if (key == 'Smoker' || key == 'Pregnant' || key == 'Gender') {
                        checkboxTabs.put('Spouse.' + (String)memberMap.get('Gender'), true);
                        checkboxTabs.put('Spouse.Smoker', memberMap.get('Smoker') == true ? true : false);
                        checkboxTabs.put('Spouse.NotSmoker', memberMap.get('Smoker') != true ? true : false);
                        checkboxTabs.put('Spouse.Pregnant', memberMap.get('Pregnant') == true ? true : false);
                        checkboxTabs.put('Spouse.NotPregnant', memberMap.get('Pregnant') != true ? true : false);      
                    } else {
                        textTabs.put('Spouse.' + key, (String)memberMap.get(key));
                        if (key == 'DOB') textTabs.put('Spouse.DOB2', memberAge >= 18 ? String.valueOf(Date.valueOf(String.valueOf(memberMap.get(key)))) : null);
                    }
                }
            }
            // Map dependent members keys
            else {
                dependent++;
                for (String key : memberMap.keySet()) {
                    if (key == 'Smoker' || key == 'Pregnant' || key == 'Gender') {
                        checkboxTabs.put('Dependent' + dependent + '.' + (String)memberMap.get('Gender'), true);
                        checkboxTabs.put('Dependent' + dependent + '.Smoker', memberMap.get('Smoker') == true ? true : false);
                        checkboxTabs.put('Dependent' + dependent + '.NotSmoker', memberMap.get('Smoker') != true ? true : false);
                        checkboxTabs.put('Dependent' + dependent + '.Pregnant', memberMap.get('Pregnant') == true ? true : false);
                        checkboxTabs.put('Dependent' + dependent + '.NotPregnant', memberMap.get('Pregnant') != true ? true : false);      
                    } else {
                        textTabs.put('Dependent' + dependent + '.' + key, (String)memberMap.get(key));
                        if (key == 'DOB' && memberAge >= 18) dependentCA++; 
                        if (key == 'DOB') textTabs.put('Dependent' + dependentCA + '.DOB2', memberAge >= 18 ? String.valueOf(Date.valueOf(String.valueOf(memberMap.get(key)))) : null);
                    }
                }
            }
            // Get ancillary programs for current member and add to map
            List<Object> ancillaryList = ((Map<String,Object>)member).containsKey('ancillaryCarePrograms') ? (List<Object>)((Map<String,Object>)member).get('ancillaryCarePrograms') : new List<Object>();

            if (ancillaryList != null &&  !ancillaryList.isEmpty()) {

                String relationship = (String)memberMap.get('Relationship');

                for (Object ancillary_obj : ancillaryList) {
                    Map<String, Object> ancillary = (Map<String, Object>)ancillary_obj;
                    String planName = ancillary.containsKey('planName') ? (String)ancillary.get('planName') : null;
                    Boolean shareAncillary = ancillary.containsKey('share') ? (Boolean)ancillary.get('share') : false;
                    String ancillaryKey;

                    if(shareAncillary == true){
                        ancillaryKey = 'Share';
                    } else {
                        ancillaryKey = 'Parent';
                        if (relationship == 'Primary' || relationship == 'Spouse') {
                            ancillaryKey += relationship;
                        } else {
                            ancillaryKey += (String)ancillary.get('relatedTo');
                        }
                    }
                    
                    ancillaryKey += (String)ancillary.get('productCode');

                    if (!parentAncillaryGroupMembers.containsKey(ancillaryKey)) {
                        parentAncillaryGroupMembers.put(ancillaryKey, new Map<String,List<String>>());
                    }

                    Map<String, List<String>> planMap = parentAncillaryGroupMembers.get(ancillaryKey);

                    // Ensure the inner map has the planName key
                    if (!planMap.containsKey(planName)) {
                        planMap.put(planName, new List<String>());
                    }

                    // Add the memberName to the corresponding plan list
                    planMap.get(planName).add(memberName);
                }
            }


            // MEDICAL QUESTIONS
            // Get member medical questions map
            Map<String,Object> memberMedicalQuestionsMap = ((Map<String,Object>)member).containsKey('medicalQuestions') && !((Map<String,Object>)((Map<String,Object>)member).get('medicalQuestions')).isEmpty() ? (Map<String,Object>)((Map<String,Object>)member).get('medicalQuestions') : new Map<String,Object>();
            if (!memberMedicalQuestionsMap.isEmpty()) {
                for (String mqKey : memberMedicalQuestionsMap.keySet()) {
                // Map member medical questions 1,2,3,5,6,7
                    if (MQGroup1.contains(mqKey)) {
                        String answer = (String)((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('answer');
                        if (answer == 'yes') {
                            if ((String)memberMap.get('Relationship') == 'Primary') checkboxTabs.put('SectionA Primary ' + medicalKeysMap.get(mqKey), true);
                            if ((String)memberMap.get('Relationship') == 'Spouse') checkboxTabs.put('SectionA Spouse ' + medicalKeysMap.get(mqKey), true);
                            if ((String)memberMap.get('Relationship') == 'Child') checkboxTabs.put('SectionA Dependent' + dependent + ' ' + medicalKeysMap.get(mqKey), true);
                            textTabs.put('MemberRow'+medicalNotesIndex, memberName);
                            // Map other conditions section 
                            if (mqKey == 'otherDx') {
                                List<String> otherDxList =  new List<String>();
                                if (((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).containsKey('selectedDiagnoses') && ((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('selectedDiagnoses') != null) {
                                    for (Object condition : (List<Object>)((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('selectedDiagnoses')) {
                                        otherDxList.add((String)condition);
                                        if ((String)memberMap.get('Relationship') == 'Primary') checkboxTabs.put('P.' + pastConditionsMap.get((String)condition) , true);
                                        if ((String)memberMap.get('Relationship') == 'Spouse') checkboxTabs.put('S.' + pastConditionsMap.get((String)condition), true);
                                        if ((String)memberMap.get('Relationship') == 'Child') checkboxTabs.put('D' + dependent + '.' + pastConditionsMap.get((String)condition), true);
                                    }
                                }
                                textTabs.put('NoteRow'+medicalNotesIndex, !otherDxList.isEmpty() ? String.join(otherDxList, ', ') : null);
                                textTabs.put('DateRow'+medicalNotesIndex, 'N/A');
                            } else {  
                                textTabs.put('NoteRow'+medicalNotesIndex, ((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('notes') != null ? medicalKeysMap.get(mqKey) + ': ' + (String)((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('notes') : null);
                                textTabs.put('DateRow'+medicalNotesIndex, ((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('date') != null ? String.valueOf(Date.valueOf(String.valueOf(((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('date')))) : null);
                            }
                            medicalNotesIndex++;
                        }
                    }
                    // Cancers
                    else if (mqKey == 'cancer') {
                        for (Object cancer : (List<Object>)memberMedicalQuestionsMap.get(mqKey)) {
                            Map<String,Object> cancerMap = (Map<String,Object>)cancer;
                            if ((String)cancerMap.get('answer') == 'yes') {
                                if ((String)memberMap.get('Relationship') == 'Primary') checkboxTabs.put('SectionA Primary ' + medicalKeysMap.get(mqKey), true);
                                if ((String)memberMap.get('Relationship') == 'Spouse') checkboxTabs.put('SectionA Spouse ' + medicalKeysMap.get(mqKey), true);
                                if ((String)memberMap.get('Relationship') == 'Child') checkboxTabs.put('SectionA Dependent' + dependent + ' ' + medicalKeysMap.get(mqKey), true);
                                textTabs.put('MemberRow'+medicalNotesIndex, memberName);
                                textTabs.put('NoteRow'+medicalNotesIndex, cancerMap.containsKey('cancerType') ? medicalKeysMap.get(mqKey) + ': ' + (String)cancerMap.get('cancerType') : null);
                                textTabs.put('DateRow'+medicalNotesIndex, cancerMap.containsKey('diagnoseDate') ? String.valueOf(Date.valueOf(String.valueOf(cancerMap.get('diagnoseDate')))) : null);
                                medicalNotesIndex++;
                            }
                        }

                    }
                    // Physicians
                    else if (mqKey == 'pcp' && (String)((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('hasPcp') == 'yes') {
                        if ((String)memberMap.get('Relationship') == 'Primary') {
                            textTabs.put('Physician NameRow1', ((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).containsKey('name') ? (String)((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('name') : null);
                            textTabs.put('CityRow1', ((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).containsKey('city') ? (String)((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('city') : null);
                            textTabs.put('PhoneRow1', ((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).containsKey('phone') ? (String)((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('phone') : null);
                        } else if ((String)memberMap.get('Relationship') == 'Spouse') {
                            textTabs.put('Physician NameRow2', ((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).containsKey('name') ? (String)((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('name') : null);
                            textTabs.put('CityRow2', ((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).containsKey('city') ? (String)((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('city') : null);
                            textTabs.put('PhoneRow2', ((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).containsKey('phone') ? (String)((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('phone') : null);
                        } else if ((String)memberMap.get('Relationship') == 'Child') {
                            textTabs.put('Physician NameRow' + (dependent+2), ((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).containsKey('name') ? (String)((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('name') : null);
                            textTabs.put('CityRow' + (dependent+2), ((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).containsKey('city') ? (String)((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('city') : null);
                            textTabs.put('PhoneRow' + (dependent+2), ((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).containsKey('phone') ? (String)((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('phone') : null);
                        }
                    }
                    // Prescriptions
                    else if (mqKey == 'prescriptions') {
                        String answer = (String)((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('answer');
                        if (answer == 'yes') {
                            for (Object medication : (List<Object>)((Map<String,Object>)memberMedicalQuestionsMap.get(mqKey)).get('medications')) {
                                Map<String,Object> medicationMap = (Map<String,Object>)medication;
                                textTabs.put('Family MemberRow'+prescriptionsIndex, memberName);
                                textTabs.put('Name of MedicationRow'+prescriptionsIndex, medicationMap.containsKey('name') ? (String)medicationMap.get('name') : null);
                                textTabs.put('Reason for MedicationRow'+prescriptionsIndex, medicationMap.containsKey('prescribedFor') ? (String)medicationMap.get('prescribedFor') : null);
                                textTabs.put('Date prescribed MoYrRow'+prescriptionsIndex, medicationMap.containsKey('startDate') ? String.valueOf(Date.valueOf(String.valueOf(medicationMap.get('startDate')))) : null);
                                textTabs.put('Date Discontinued MoYrRow'+prescriptionsIndex, medicationMap.containsKey('endDate') ?  String.valueOf(Date.valueOf(String.valueOf(medicationMap.get('endDate')))) : null);
                                textTabs.put('Prescribing PhysicianRow'+prescriptionsIndex, medicationMap.containsKey('prescribedBy') ? (String)medicationMap.get('prescribedBy') : null);
                                prescriptionsIndex++;
                            }
                        }
                    }
                }
            }
        }


        // GENERAL INFORMATION
        String effectiveDate = String.valueOf(Date.valueOf(String.valueOf(generalInfoMap.get('effectiveDate'))));
        textTabs.put('Plan.EffectiveDate', effectiveDate);

        Decimal monthlyContribution = (Decimal)generalInfoMap.get('totalMonthlyPremium');
        Decimal appFee = (Decimal)paymentMap.get('discountPrice');
        appFee= appFee.setScale(2);
        monthlyContribution = monthlyContribution.setScale(2);
        Decimal totalAmount = monthlyContribution + appFee;
        textTabs.put('Plan.MonthlyContribution', String.valueOf(monthlyContribution));
        textTabs.put('Plan.ApplicationFee', String.valueOf(appFee));
        textTabs.put('Payment.MonthlyContribution', String.valueOf(monthlyContribution));
        textTabs.put('Payment.Fee', String.valueOf(appFee));
        textTabs.put('Payment.FirstMonthFee', String.valueOf(totalAmount));

        // String promoCode = paymentMap.containsKey('promoName') && paymentMap.get('promoName') != null && paymentMap.get('promoName') != '' ? (String)paymentMap.get('promoName') : null;
        String promoCodeId = paymentMap.containsKey('promoCode') && paymentMap.get('promoCode') != null && paymentMap.get('promoCode') != '' ? (String)paymentMap.get('promoCode') : null;
        if (promoCodeId != null) {
            ARC_PromotionCode__c promoCodeRecord = [
                SELECT Id, ARC_DiscountedAmount__c, ARC_DiscountRate__c
                FROM ARC_PromotionCode__c 
                WHERE Id = :promoCodeId
                LIMIT 1
            ];
            String discountRateString = promoCodeRecord.ARC_DiscountRate__c != null ? String.valueOf((promoCodeRecord.ARC_DiscountRate__c).setScale(0, RoundingMode.HALF_UP)) + '%' : null;
            String promoAmountOrRate = promoCodeRecord.ARC_DiscountedAmount__c != null && paymentMap.get('discountAmount') != null ? '$' + String.valueOf(paymentMap.get('discountAmount')) : promoCodeRecord.ARC_DiscountRate__c != null ? discountRateString : null;
            textTabs.put('PromotionDiscount', promoAmountOrRate);
        }


        // Map Members per program section
        String medicalPlanName = !medicalPlanMap.isEmpty() && medicalPlanMap.containsKey('name') ? (String)medicalPlanMap.get('name') : null;
        String medicalMembers = medicalPlanName != null && medicalPlanName != '' ? medicalPlanName + ': ' + String.join(memberNamesList, ', ') : null;
        if (medicalMembers != null) membersPerProgramList.add(medicalMembers);

        if (parentAncillaryGroupMembers != null && !parentAncillaryGroupMembers.isEmpty()) {
            for (String ancillaryKey : parentAncillaryGroupMembers.keySet()) {
                Map<String, List<String>> planMap = parentAncillaryGroupMembers.get(ancillaryKey);

                for (String planName : planMap.keySet()) {
                    List<String> members = planMap.get(planName);
                    String memberList = String.join(members, ', ');
                    String ancillaryString = planName + ': ' + memberList;
                    membersPerProgramList.add(ancillaryString);
                }
            }
        }


        if (membersPerProgramList != null && !membersPerProgramList.isEmpty()) textTabs.put('Info.MembersPerProgram', String.join(membersPerProgramList, '\n'));
        
        // BENEFICIARIES INFORMATION
        System.debug('Mapping beneficiaries');
        Integer counter = 1;
        for (Object member_obj : this.memberList) {
            Map<String, Object> member = (Map<String, Object>) member_obj;
            String memberName = (String)((Map<String,Object>)member.get('person')).get('firstName') + ' ' + (String)((Map<String,Object>)member.get('person')).get('lastName');
            Map<String, Object> beneficiaries = member.containsKey('beneficiaries') ? (Map<String, Object>) member.get('beneficiaries') : new Map<String, Object>();

            if (beneficiaries.containsKey('primaryBeneficiary')) {
                Map<String, Object> primaryBeneficiary = (Map<String, Object>) beneficiaries.get('primaryBeneficiary');
                textTabs.put('TXT_MemberName' + counter, memberName);
                textTabs.put('TXT_BeneficiaryName' + counter, (String)primaryBeneficiary.get('firstName') + ' ' + (String)primaryBeneficiary.get('lastName'));
                textTabs.put('TXT_BeneficiaryDOB' + counter, (String)primaryBeneficiary.get('birthdate'));
                textTabs.put('TXT_BeneficiaryPhone' + counter, String.valueOf(primaryBeneficiary.get('phone')));
                textTabs.put('TXT_BeneficiaryRelationship' + counter, (String)primaryBeneficiary.get('otherRelationship') != '' ? (String)primaryBeneficiary.get('otherRelationship') : (String)primaryBeneficiary.get('relationship'));
                textTabs.put('TXT_BeneficiaryType' + counter, 'Primary');
                counter++;
            }

            if (beneficiaries.containsKey('secondaryBeneficiary')) {
                Map<String, Object> secondaryBeneficiary = (Map<String, Object>) beneficiaries.get('secondaryBeneficiary');
                textTabs.put('TXT_MemberName' + counter, memberName);
                textTabs.put('TXT_BeneficiaryName' + counter, (String)secondaryBeneficiary.get('firstName') + ' ' + (String)secondaryBeneficiary.get('lastName'));
                textTabs.put('TXT_BeneficiaryDOB' + counter, (String)secondaryBeneficiary.get('birthdate'));
                textTabs.put('TXT_BeneficiaryPhone' + counter, String.valueOf(secondaryBeneficiary.get('phone')));
                textTabs.put('TXT_BeneficiaryRelationship' + counter, (String)secondaryBeneficiary.get('otherRelationship') != '' ? (String)secondaryBeneficiary.get('otherRelationship') : (String)secondaryBeneficiary.get('relationship'));
                textTabs.put('TXT_BeneficiaryType' + counter, 'Secondary');
                counter++;
            }
        }
        System.debug('Beneficiaries mapped');

        // PAYMENT INFORMATION
        Map<String,Object> creditCardMap = paymentMap.containsKey('creditCard') && !((Map<String,Object>)paymentMap.get('creditCard')).isEmpty() ? (Map<String,Object>)paymentMap.get('creditCard') : new Map<String,Object>();
        Map<String,Object> bankAccountMap = paymentMap.containsKey('bankAccount') && !((Map<String,Object>)paymentMap.get('bankAccount')).isEmpty() ? (Map<String,Object>)paymentMap.get('bankAccount') : new Map<String,Object>();
        checkboxTabs.put('Payment.CreditCardPayment', paymentMap.containsKey('paymentMethod') && paymentMap.get('paymentMethod') != null && paymentMap.get('paymentMethod') == 'credit_card' ? true : false);
        checkboxTabs.put('Payment.BankAccountPayment', paymentMap.containsKey('paymentMethod') && paymentMap.get('paymentMethod') != null && paymentMap.get('paymentMethod') == 'bank_account' ? true : false);

        // Credit card keys
        List<String> addressKeysList = new List<String>();
        if (!creditCardMap.isEmpty()) {
            for (String addressKey : ((Map<String,Object>)creditCardMap.get('billingAddress')).keySet()) {
                String value = (String)((Map<String,Object>)creditCardMap.get('billingAddress')).get(addressKey);
                if (value != null && value != '') {
                    addressKeysList.add(value);
                }
            }
            textTabs.put('Payment.NameOnCard', creditCardMap.containsKey('firstName') && creditCardMap.containsKey('lastName') ? (String)creditCardMap.get('firstName') + ' ' + (String)creditCardMap.get('lastName') : null);
            textTabs.put('Payment.CardNumber', creditCardMap.containsKey('cardNumber') ? '**** **** **** ' + ((String)creditCardMap.get('cardNumber')).right(4) : null);
            textTabs.put('Payment.CardExpYear', creditCardMap.containsKey('expirationMonth') && creditCardMap.containsKey('expirationYear') ? String.valueOf(creditCardMap.get('expirationMonth')) + '/' + String.valueOf(creditCardMap.get('expirationYear')) : null);
            textTabs.put('Payment.BillingAddress', !addressKeysList.isEmpty() ? String.join(addressKeysList, ', ') : null);
            checkboxTabs.put('Payment.' + (String)creditCardType.get(((String)creditCardMap.get('cardNumber')).substring(0, 1)), true);
        }
        
        // Bank account keys
        if (!bankAccountMap.isEmpty()) {
            String encryptedBankAccountNumber = bankAccountMap.containsKey('accountNumber') && bankAccountMap.get('accountNumber') != null ? encryptAccountNumber(String.valueOf(bankAccountMap.get('accountNumber'))) : null;
            checkboxTabs.put('Payment.Checking', bankAccountMap.containsKey('accountType') && (String)bankAccountMap.get('accountType') == 'Checking' ? true : false);
            checkboxTabs.put('Payment.Savings', bankAccountMap.containsKey('accountType') && (String)bankAccountMap.get('accountType') == 'Savings' ? true : false);
            textTabs.put('Payment.BankName', bankAccountMap.containsKey('bankName') ? (String)bankAccountMap.get('bankName') : null);
            textTabs.put('Payment.NameOnBankAccount', bankAccountMap.containsKey('firstName') && bankAccountMap.containsKey('lastName') ? (String)bankAccountMap.get('firstName') + ' ' + (String)bankAccountMap.get('lastName') : null);
            textTabs.put('Payment.AccountNumber', !bankAccountMap.isEmpty() ? encryptedBankAccountNumber : null);
            textTabs.put('Payment.Routing', bankAccountMap.containsKey('routingNumber') ? String.valueOf(bankAccountMap.get('routingNumber')) : null);
        }


        // GUARDIAN INFORMATION
        if (generalInfoMap.containsKey('guardian') && (Map<String,Object>)generalInfoMap.get('guardian') != null && !((Map<String,Object>)generalInfoMap.get('guardian')).isEmpty()) {
            Map<String,Object> guardianMap = transformMemberMapKeys((Map<String,Object>)generalInfoMap.get('guardian'));
            for (String guardianKey : guardianMap.keySet()) {
                if (guardianKey == 'Smoker' || guardianKey == 'Pregnant' || guardianKey == 'Height' || guardianKey == 'Weight') continue; // Information not required for guardians
                if (guardianKey == 'Relationship') textTabs.put('Guardian.GuardianRelationshipToChild', (String)guardianMap.get(guardianKey));
                if (guardianKey == 'Gender') {
                     checkboxTabs.put('Guardian.' + (String)guardianMap.get('Gender'), true);
                } else {
                    textTabs.put('Guardian.' + guardianKey, (String)guardianMap.get(guardianKey));
                }
            }
        }
        

        // LEGACY INFORMATION
        if (medicalPlanName == 'WeShare Legacy') {
            Map<String,Object> primaryPersonMap = (Map<String,Object>)primaryInfo.get('person') != null && !((Map<String,Object>)primaryInfo.get('person')).isEmpty() ? (Map<String,Object>)primaryInfo.get('person') : new Map<String,Object>();
            // Medicare ID
            textTabs.put('Medicare.Number', primaryPersonMap.containsKey('medicareId') ? (String)primaryPersonMap.get('medicareId') : null);
            // Medicare Part A
            checkboxTabs.put('Medicare.PartA', primaryPersonMap.containsKey('medicarePartA') ? (Boolean)primaryPersonMap.get('medicarePartA') : false);
            textTabs.put('Medicare.EffectiveDateA', primaryPersonMap.containsKey('medicareEffectiveDate A') ? String.valueOf(Date.valueOf(String.valueOf(primaryPersonMap.get('medicareEffectiveDate A')))) : null);
            // Medicare Part B
            checkboxTabs.put('Medicare.PartB', primaryPersonMap.containsKey('medicarePartB') ? (Boolean)primaryPersonMap.get('medicarePartB') : false);
            textTabs.put('Medicare.EffectiveDateB', primaryPersonMap.containsKey('medicareEffectiveDate B') ? String.valueOf(Date.valueOf(String.valueOf(primaryPersonMap.get('medicareEffectiveDate B')))) : null);
            // Medicare Part C
            checkboxTabs.put('Medicare.PartC', primaryPersonMap.containsKey('medicarePartC') ? (Boolean)primaryPersonMap.get('medicarePartC') : false);
            // Medicare Part D
            checkboxTabs.put('Medicare.PartD', primaryPersonMap.containsKey('medicarePartD') ? (Boolean)primaryPersonMap.get('medicarePartD') : false);
            textTabs.put('Medicare.EffectiveDateD', primaryPersonMap.containsKey('medicareEffectiveDate D') ? String.valueOf(Date.valueOf(String.valueOf(primaryPersonMap.get('medicareEffectiveDate D')))) : null);
        }


        // CALIFORNIA INFORMATION
        String primaryState = (String)((Map<String,Object>)((Map<String,Object>)primaryInfo.get('person')).get('address')).get('state');
        if (primaryState == 'CA') {
            Date primaryDOB = primaryInfo.containsKey('person') && !((Map<String,Object>)primaryInfo.get('person')).isEmpty() ? Date.valueOf((String)((Map<String,Object>)primaryInfo.get('person')).get('dob')) : null;
            textTabs.put('Primary.Name', primaryInfo.containsKey('person') && !((Map<String,Object>)primaryInfo.get('person')).isEmpty() ? (String)((Map<String,Object>)primaryInfo.get('person')).get('firstName') + ' ' + (String)((Map<String,Object>)primaryInfo.get('person')).get('lastName') : null);
            textTabs.put('Primary.MonthOfBirth', primaryDOB != null ? String.valueOf(primaryDOB.month()) : null);
            textTabs.put('Primary.DayOfBirth', primaryDOB != null ? String.valueOf(primaryDOB.day()) : null);
            textTabs.put('Primary.YearOfBirth', primaryDOB != null ? String.valueOf(primaryDOB.year()) : null);
            // Get list of hipaa from JSON
            List<Object> hipaaList = generalInfoMap.containsKey('hipaa') && generalInfoMap.get('hipaa') != null ? (List<Object>)generalInfoMap.get('hipaa') : new List<Object>();
            if (!hipaaList.isEmpty() && hipaaList.size() > 0) {
                Integer tempIndex = 1;
                for (Object hipaa : hipaaList) {
                    Map<String,Object> hipaaMap = (Map<String,Object>)hipaa;
                    // Map only hipaa different to primary
                    if (hipaaMap.get('relationship') != 'primary') {
                        textTabs.put('Hipaa' + tempIndex, (String)hipaaMap.get('firstName') + ' ' + (String)hipaaMap.get('lastName'));
                        tempIndex++;
                    }
                }
            }
        }
        

        // AGENT NAME
        String agentName = generalInfoMap.containsKey('hadAssistance') && !((Map<String,Object>)generalInfoMap.get('hadAssistance')).isEmpty() ? (String)((Map<String,Object>)generalInfoMap.get('hadAssistance')).get('agentName') : null;
        textTabs.put('Agent.Name', agentName != null ? agentName : '');

        // Add tabs map to DocuSign all data map
        manager.docuSignData.put('tabs', new Map<String,Object>{
            'checkboxTabs' => checkboxTabs,
            'textTabs' => textTabs
        });
        // manager.SerializedDocuSignData = JSON.serialize(manager.docuSignData);
        // System.debug('Serialized JSON DS Data: ' + manager.SerializedDocuSignData);

        // manager.tabMap.put('checkboxTabs', checkboxTabs);
        // manager.tabMap.put('textTabs', textTabs);

    }

    // /**
    //  * @Description: Method to send the DocuSign envelope asynchronously
    //  * @param inputJSON: Serialized JSON with all the input information to send the envelope
    //  * @param contractId: contract Id inserted in SE process that need to be updated with the envelope Id 
    //  */
    // @future(callout=true)
    // public static void sendEnvelopeAsync(String inputJSON, Id contractId) {
    //     Map<String,Object> inputMap = (Map<String,Object>)JSON.deserializeUntyped(inputJSON); // Convert input JSON string into Map to use when sending envelope
    //     List<Object> signerList = (List<Object>)inputMap.get('signerList'); // Get signer list from input
    //     String templateId = (String)((Map<String,Object>)inputMap.get('DocuSignTemplateId')).get('TemplateId'); // Get template Id from input
    //     Map<String,Object> outputMap = new Map<String,Object>(); // Output map to return sendEnvelope method
    //     // Options map where template Id, signer list and other parameters can be included
    //     Map<String,Object> options = new Map<String, Object>{
    //         'docuSignTemplatesGroup' => new List<Object>{
    //             new Map<String, Object>{
    //                 'docuSignTemplate' => templateId,
    //                 'sendJSONPath' => null,
    //                 'sendJSONNode' => null,
    //                 'includeToSend' => true,
    //                 'signerList' => signerList,
    //                 'TFDRresp' => null
    //             }
    //         },
    //         'elementName' => 'DS_SendEnvelope'
    //         // 'ignoreCache' => false,
    //         // 'useQueueableApexRemoting' => false,
    //         // 'useContinuation' => false
    //     }; 

    //     // Call through the Vlocity interface and call sendEnvelope method
    //     vlocity_ins.DefaultDocuSignOmniScriptIntegration docusignIntegration = new vlocity_ins.DefaultDocuSignOmniScriptIntegration();
    //     docusignIntegration.invokeMethod('sendEnvelope', inputMap, outputMap, options);
    //     System.debug('DocuSign sendEnvelope result => ' + outputMap);
        
    //     // Update the contract of SE with the envelope ID
    //     System.debug('Contract ID: ' + contractId);
    //     if (outputMap.containsKey('DS_SendEnvelope') && contractId != null) {
    //         String envelopeId = ((Map<String,Object>)outputMap.get('DS_SendEnvelope')).get('status') == 'sent' ? (String)((Map<String,Object>)outputMap.get('DS_SendEnvelope')).get('envelopeId') : null;
    //         Contract contractToUpdate = new Contract();
    //         contractToUpdate.Id = contractId;
    //         contractToUpdate.vlocity_ins__LastDocuSignEnvelopeId__c = envelopeId;
    //         contractToUpdate.vlocity_ins__LastDocuSignEnvelopeStatus__c = envelopeId != null ? 'Pending' : null;
    //         update contractToUpdate;
    //     }
        
    // }


    /**************************************************AUXILIAR METHODS************************************************************** */
        /**
     * @Description: Auxiliar method to transform member map keys
     * @param memberMap: All the member information map received from JSON
     */

    private Map<String,Object> transformMemberMapKeys(Map<String,Object> memberMap) {
        // Set map and variables depending if it is a member map or guardian
        Map<String,Object> personInfoMap = memberMap.containsKey('person') ? (Map<String,Object>)memberMap.get('person') : memberMap;
        String relationship = memberMap.containsKey('role') ? (String)memberMap.get('role') : (String)personInfoMap.get('relationship');
        String height = String.valueOf(personInfoMap.get('heightFeet')) + '\'' + String.valueOf(personInfoMap.get('heightInches')) + '\"';
        String memberSSN = (String)personInfoMap.get('ssn');
        Map<String,Object> addressMap = personInfoMap.containsKey('address') && personInfoMap.get('address') != null && personInfoMap.get('address') != '' ? (Map<String,Object>)personInfoMap.get('address') : new Map<String,Object>();
        
        Map<String,Object> transformedMemberMap = new Map<String,Object> {
            'MemberExternalId' => (String)memberMap.get('memberExternalId'),
            'FirstName' => (String)personInfoMap.get('firstName'),
            'MI' => (String)personInfoMap.get('middleInitial'),
            'LastName' => (String)personInfoMap.get('lastName'),
            'Relationship' => relationship,
            'DOB' => String.valueOf(Date.valueOf(String.valueOf(personInfoMap.get('dob')))),
            // 'DOB2' => String.valueOf(Date.valueOf(String.valueOf(personInfoMap.get('dob')))),
            'Gender' => (String)personInfoMap.get('gender'),
            'Phone' => (String)personInfoMap.get('phone'),
            'Email' => (String)personInfoMap.get('email'),
            'SocialSecurity' => 'XXX-XX-' + memberSSN.right(4),
            'SSN' => (String)personInfoMap.get('ssn'),
            'Height' => height,
            'Weight' => String.valueOf(personInfoMap.get('weightLbs')),
            'Pregnant' => (Boolean)personInfoMap.get('pregnant'),
            'Smoker' => (Boolean)personInfoMap.get('smoker'),
            'Address' => (String)addressMap.get('street'),
            'City' => (String)addressMap.get('city'),
            'State' => (String)addressMap.get('state'),
            'ZipCode' => (String)addressMap.get('zip')
        };

        return transformedMemberMap;
    }

    /**
     * @Description: Auxiliar method to calculate the member age based on member Date of Birth
     * @param memberDOB: Member date of birth
     */
    private Integer calculateMemberAge(Date memberDOB) {
        if (memberDOB == null || memberDOB > Date.today()) {
            return null;
        } else {
            Date today = Date.today();
            Integer memberAge = today.year()-memberDOB.year();

            // Adjust age if birthdate has not occurred yet
            if (today.month() < memberDOB.month() || (today.month() == memberDOB.month() && today.day() < memberDOB.day())) {
            memberAge--;
            }
            return memberAge;
        }
    }

    /**
     * @Description: Auxiliar method to get the primary member from a member list
     * @param memberList: All member list received from JSON
     */
    private Map<String,Object> getPrimaryInfo(List<Object> memberList) {
        Map<String,Object> primaryInfo = new Map<String,Object>();
        if (memberList != null && !memberList.isEmpty()) {
            for (Object member : memberList) {
                String relationship = (String)((Map<String,Object>)member).get('role');
                primaryInfo = relationship == 'Primary' ? (Map<String,Object>)member : primaryInfo;
            }
        }
        return primaryInfo;
    }

    /**
     * @Description: Auxiliar method to encrypt account number
     * @param accNumberString: Bank account number in string format
     */
    private String encryptAccountNumber(String accNumberString) {
        String encryptedString = '';
        Integer accNumberLength = accNumberString.length();
        // Substitute first account numbers for * until last 4 digits, then add last 4 digits
        if (accNumberLength > 4) {
            for (Integer i = 1 ; i < accNumberLength - 4 ; i++) {
                encryptedString += '*';
            }
            encryptedString += accNumberString.right(4);
        }
        return encryptedString;
    }

}