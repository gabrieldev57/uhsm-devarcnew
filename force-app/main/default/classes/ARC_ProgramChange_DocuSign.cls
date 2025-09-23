global without sharing class ARC_ProgramChange_DocuSign implements vlocity_ins.VlocityOpenInterface{
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        switch on methodName {
            when 'DocuSignDataTransform'                         { DocuSignDataTransform(inputMap, outputMap, options); }
            when else                                            { throw new AuraHandledException('Unknown method: ' + methodName); }
        }
        return true;
    }

    // MAP of past conditions question for docusign template
    private static Map<String,String> pastConditionsDocuSignMap = new Map<String,String>{
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

    private static Map<String,String> creditCardTypeMap = new Map<String,String>{
        '4' => 'Visa',
        '5' => 'MasterCard',
        '6' => 'Discover'
    };

    private static String effectiveDate;
    private static Map<String,Object> DocuSign = new Map<String,Object>();
    private static Map<String,Object> primaryMember = new Map<String,Object>();
    private static Map<String,Object> spouseMember = new Map<String,Object>();
    private static List<Object> dependents = new List<Object>();
    private static List<Object> memberList = new List<Object>();
    private static Map<String,Object> pcChanges = new Map<String,Object>();
    private static List<Object> oldProductList = new List<Object>();
    private static List<Object> newProductList = new List<Object>();
    private static List<String> pcReasons = new List<String>();
    private static Set<String> oldProductNames = new Set<String>();
    private static Map<String,Object> medicalQuestions = new Map<String,Object>();
    private static List<Object> trueQuestionsList = new List<Object>();
    private static List<Object> pastConditionsList = new List<Object>();
    private static List<Object> cancerTrueList = new List<Object>();
    private static List<Object> prescriptionsTrueList = new List<Object>();

    private static Map<String,Object> selectedContractInfo = new Map<String,Object>();
    private static Map<String,Object> paymentChangeFee = new Map<String,Object>();
    private static Id contractId = null;
    private static String keepCurrentPaymentMethod;
    private static List<String> fullAddressList = new List<String>();


    /*******************************************************************
    * @MethodName         :   DocuSignDataTransform
    * @Description        :   
    ********************************************************************/
    public static void DocuSignDataTransform(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        System.debug('Test0');
        // Output maps
        Map<String, Object> textTabs = new Map<String, Object>();
        Map<String, Object> checkboxTabs = new Map<String, Object>();
        // Get input information
        effectiveDate = (String)inputMap.get('EffectiveDate');
        DocuSign = (Map<String,Object>)inputMap.get('DocuSign');
        // Get members map
        primaryMember = (Map<String,Object>)((Map<String,Object>)inputMap.get('MembersInfo')).get('primaryMember');
        spouseMember = (Map<String,Object>)((Map<String,Object>)inputMap.get('MembersInfo')).get('spouseMember');
        dependents = (List<Object>)((Map<String,Object>)inputMap.get('MembersInfo')).get('dependentMembers');

        // Add primary to memberList
        if (primaryMember != null) {
            memberList.add(primaryMember);
        }
        // Add spouse to memberList
        if (spouseMember != null) {
            memberList.add(spouseMember);
        }
        // Add each dependent to memberList
        if (dependents != null) {
            for (Object dep : dependents) {
                Map<String,Object> depMap =(Map<String,Object>)dep;
                memberList.add(depMap);
            }
        }

        System.debug('Test inputs');
        

        pcChanges = (Map<String,Object>)(DocuSign.get('pcChanges'));
        oldProductList = (List<Object>)DocuSign.get('OldProductList');
        String updateType = (String)inputMap.get('UpdateType');
        if ((updateType != null && updateType.contains('Change to Programs')) || ((String)pcChanges.get('pcReasonsString')).contains('Add Member') || ((String)pcChanges.get('pcReasonsString')).contains('Add Existing Member') || ((String)pcChanges.get('pcReasonsString')).contains('Remove Member')) {
            newProductList = (List<Object>)DocuSign.get('NewProductList');
        }
        pcReasons = ((String)pcChanges.get('pcReasonsString')).split('; ');
        System.debug(pcReasons.contains('Add Member'));
        System.debug(pcReasons.contains('Program Upgrade'));
        if (pcReasons.contains('Add Member') || pcReasons.contains('Program Upgrade')) {
            medicalQuestions = (Map<String,Object>)DocuSign.get('STEP_MedicalQuestions');
        }

        // MEDICAL QUESTIONS MAPS
        Map<String,String> medicalRADMap = new Map<String,String>{
            'RAD_ParentSiblingDiagnosed'=>'BLK_ParentSiblingDiagnosed', // OK
            'RAD_UnexplainedSymptoms'=>'BLK_UnexpectedSymptoms', // OK
            'RAD_PendingTests'=>'BLK_PendingTests', // OK
            'RAD_Cancer'=>'EB_Cancer',
            'RAD_Addictions'=>'BLK_Addictions', // OK
            'RAD_LicenceSuspended'=>'BLK_LicenceSuspended', // OK
            'RAD_PastConditions'=>'EB_PastConditions', 
            'RAD_PrescriptionMedications'=>'ED_MemberPrescription', // OK
            'EB_Physicians' => 'EB_Physicians' // OK
        };
        Map<String,String> medicalKeyBlk = new Map<String,String>{
            'BLK_ParentSiblingDiagnosed' => 'CHKBOX_MemberParentDiagnosed',
            'BLK_UnexpectedSymptoms' => 'CHKBOX_UnexpectedSymptoms',
            'BLK_PendingTests' => 'CHKBOX_PendingTests',
            // 'EB_Cancer' => 'CHKBOX_Cancer',
            'BLK_Addictions' => 'CHKBOX_Addictions',
            'BLK_LicenceSuspended' => 'CHKBOX_LicenceSuspended'
            // 'EB_PastConditions' => 'CHKBOX_PastConditions',
            // 'EB_Physicians' => 'CHKBOX_Physicians'
        };
        Map<String,String> medicalBlkChkbx = new Map<String,String>{
            'CHKBOX_MemberParentDiagnosed' => 'ParentSiblingDiagnosed',
            'CHKBOX_UnexpectedSymptoms' => 'UnexpectedSymptoms',
            'CHKBOX_PendingTests' => 'PendingTests',
            'CHKBOX_Addictions' => 'Addictions',
            'CHKBOX_LicenceSuspended' => 'LicenceSuspended',
            'EB_PastConditions' => 'PastConditions'
        };


        // 


        System.debug('Test1');

        // Get all the questions that are true and its member Id
        if (medicalQuestions != null) {
            for (String RADKey : medicalRADMap.keySet()) {
                // Data management for RAD keys
                if (medicalQuestions.get(RADKey) == 'Yes') {
                    // Manage for 2 specific keys
                    if (RADKey == 'RAD_Cancer' || RADKey == 'RAD_PrescriptionMedications') {
                        Object temp = medicalQuestions.get(medicalRADMap.get(RADKey));
                        if (temp instanceOf Map<String,Object>) {
                            Map<String,Object> memberMap = (Map<String,Object>)temp;
                            if (RADKey == 'RAD_Cancer') {
                                cancerTrueList.add(memberMap);
                            }
                            if (RADKey == 'RAD_PrescriptionMedications') {
                                prescriptionsTrueList.add(memberMap);   
                            }
                        }
                        if (temp instanceOf List<Object>) {
                            for (Object member : (List<Object>)temp) {
                                Map<String,Object> memberMap = (Map<String,Object>)member;
                                if (RADKey == 'RAD_Cancer') {
                                    cancerTrueList.add(memberMap);
                                }
                                if (RADKey == 'RAD_PrescriptionMedications') {
                                    prescriptionsTrueList.add(memberMap);   
                                }
                            }
                        }
                    }
                    else {
                        Object tempBLK = (Object)medicalQuestions.get(medicalRADMap.get(RADKey));
                        if (tempBLK instanceOf List<Object>) {
                            for (Object block : (List<Object>)tempBLK) {
                                Map<String,Object> blockMap = (Map<String,Object>)block;
                                Boolean isTrueQuestion = (Boolean)blockMap.get(medicalKeyBlk.get(medicalRADMap.get(RADKey))) == true ? true : false;
                                System.debug(blockMap.get('memberId')+': '+medicalKeyBlk.get(medicalRADMap.get(RADKey)) +': '+ isTrueQuestion);
                                // Add each member block to list if it is checkbox and is true
                                if (isTrueQuestion) {
                                    trueQuestionsList.add(blockMap);
                                }
                                // Add each member multi selected past conditions to list
                                if (blockMap.get('MULSEL_Conditions') != null) {
                                    String selectedPastConditions = (String)blockMap.get('MULSEL_Conditions');
                                    List<String> tempPastConditionsList = selectedPastConditions.split(';');
                                    Map<String,Object> memberPastConditionsMap = new Map<String,Object> {
                                        'memberId' => blockMap.get('memberId'),
                                        'MULSEL_Conditions' => tempPastConditionsList
                                    };
                                    pastConditionsList.add(memberPastConditionsMap);
                                    System.debug('Should be past conditions map:' + blockMap);
                                    // Add past conditions map for medical notes
                                    cancerTrueList.add(blockMap);
                                }
                                // if (blockMap.get('CHK_MemberBeenDiagnosedWithCancer') == true) {
                                //     pastConditionsList.add(blockMap);
                                // }
                            }
                        }
                        if (tempBLK instanceOf Map<String,Object>) {
                            Map<String,Object> blockMap = (Map<String,Object>)tempBLK;
                            Boolean isTrueQuestion = (Boolean)blockMap.get(medicalKeyBlk.get(medicalRADMap.get(RADKey))) == true ? true : false;
                            // Add each member block to list if it is checkbox and is true
                            if (isTrueQuestion) {
                                trueQuestionsList.add(blockMap);
                            }
                            // Add each member multi selected past conditions to list
                            if (blockMap.get('MULSEL_Conditions') != null) {
                                String selectedPastConditions = (String)blockMap.get('MULSEL_Conditions');
                                List<String> tempPastConditionsList = selectedPastConditions.split(';');
                                Map<String,Object> memberPastConditionsMap = new Map<String,Object> {
                                    'memberId' => blockMap.get('memberId'),
                                    'MULSEL_Conditions' => tempPastConditionsList
                                };
                                pastConditionsList.add(memberPastConditionsMap);
                                // Add past conditions map for medical notes
                                cancerTrueList.add(blockMap);
                            }
                            // if (blockMap.get('CHK_MemberBeenDiagnosedWithCancer') == true) {
                            //     pastConditionsList.add(blockMap);
                            // }
                        }
                    }
                }
                // Data management for EB Phyicians key
                else if (RADKey == 'EB_Physicians') {
                    Object memberPhysician = (Object)medicalQuestions.get(RADKey);
                    if (memberPhysician instanceOf List<Object>) {
                        for (Object member : (List<Object>)memberPhysician) {
                            Map<String,Object> memberMap = (Map<String,Object>)member;
                            if (memberMap != null) {
                                // Set Physician Primary Care tabs for Primary
                                if (memberMap.get('memberId') == primaryMember.get('Id')) {
                                    textTabs.put('Physician NameRow1', memberMap.get('TXT_PhysicianName'));
                                    textTabs.put('CityRow1', memberMap.get('TXT_PhysicianCity'));
                                    textTabs.put('PhoneRow1', memberMap.get('TXT_PhysicianPhone'));
                                }
                                if (spouseMember != null) {
                                    // Set Physician Primary Care tabs for Spouse
                                    if (memberMap.get('memberId') == spouseMember.get('Id')) {
                                        textTabs.put('Physician NameRow2', memberMap.get('TXT_PhysicianName'));
                                        textTabs.put('CityRow2', memberMap.get('TXT_PhysicianCity'));
                                        textTabs.put('PhoneRow2', memberMap.get('TXT_PhysicianPhone'));
                                    }
                                }
                                if (dependents != null) {
                                    Integer index = 3;
                                    // Set Physician Primary Care tabs for Dependents
                                    for (Object dep : dependents) {
                                        Map<String,Object> depMap = (Map<String,Object>)dep;
                                        System.debug(memberMap.get('memberId'));
                                        System.debug(depMap.get('Id'));
                                        if (memberMap.get('memberId') == depMap.get('Id')) {
                                            textTabs.put('Physician NameRow'+index, memberMap.get('TXT_PhysicianName'));
                                            textTabs.put('CityRow'+index, memberMap.get('TXT_PhysicianCity'));
                                            textTabs.put('PhoneRow'+index, memberMap.get('TXT_PhysicianPhone'));
                                        }
                                        index = index + 1;
                                    }
                                }
                            }
                        }
                    }
                    if (memberPhysician instanceOf Map<String,Object>) {
                        Map<String,Object> memberMap = (Map<String,Object>)memberPhysician;
                        if (memberMap != null) {
                            // Set Physician Primary Care tabs for Primary
                            if (memberMap.get('memberId') == primaryMember.get('Id')) {
                                textTabs.put('Physician NameRow1', memberMap.get('TXT_PhysicianName'));
                                textTabs.put('CityRow1', memberMap.get('TXT_PhysicianCity'));
                                textTabs.put('PhoneRow1', memberMap.get('TXT_PhysicianPhone'));
                            }
                            if (spouseMember != null) {
                                // Set Physician Primary Care tabs for Spouse
                                if (memberMap.get('memberId') == spouseMember.get('Id')) {
                                    textTabs.put('Physician NameRow2', memberMap.get('TXT_PhysicianName'));
                                    textTabs.put('CityRow2', memberMap.get('TXT_PhysicianCity'));
                                    textTabs.put('PhoneRow2', memberMap.get('TXT_PhysicianPhone'));
                                }
                            }
                            if (dependents != null) {
                                Integer index = 3;
                                // Set Physician Primary Care tabs for Dependents
                                for (Object dep : dependents) {
                                    Map<String,Object> depMap = (Map<String,Object>)dep;
                                    System.debug(memberMap.get('memberId'));
                                    System.debug(depMap.get('Id'));
                                    if (memberMap.get('memberId') == depMap.get('Id')) {
                                        textTabs.put('Physician NameRow'+index, memberMap.get('TXT_PhysicianName'));
                                        textTabs.put('CityRow'+index, memberMap.get('TXT_PhysicianCity'));
                                        textTabs.put('PhoneRow'+index, memberMap.get('TXT_PhysicianPhone'));
                                    }
                                    index = index + 1;
                                }
                            }
                        }
                    }
                }
            }

            System.debug('Test2');

            // Iterate over true question list and set each member true checkbox
            System.debug(trueQuestionsList);
            System.debug(trueQuestionsList.size());
            if (!trueQuestionsList.isEmpty()) {
                for (String trueKey : medicalBlkChkbx.keySet()) {
                    System.debug(trueKey); 
                    for (Object trueQuestion : trueQuestionsList) {
                        Map<String,Object> trueQuestionMap = (Map<String,Object>)trueQuestion;
                        if (primaryMember.get('Id') == trueQuestionMap.get('memberId') && trueQuestionMap.get(trueKey) == true) {
                            checkboxTabs.put('SectionA Primary ' + medicalBlkChkbx.get(trueKey),true);
                        }
                        if (spouseMember != null) {
                            if (spouseMember.get('Id') == trueQuestionMap.get('memberId') && trueQuestionMap.get(trueKey) == true) {
                                checkboxTabs.put('SectionA Spouse ' + medicalBlkChkbx.get(trueKey), true);
                            }
                        }
                        if (dependents != null) {
                            Integer index = 1;
                            for (Object dep : dependents) {
                                Map<String,Object> depMap = (Map<String,Object>)dep;
                                System.debug(trueQuestionMap);
                                if (depMap.get('Id') == trueQuestionMap.get('memberId') && trueQuestionMap.get(trueKey) == true) {
                                    checkboxTabs.put('SectionA Dependent'+ index + ' ' + medicalBlkChkbx.get(trueKey), true);
                                }
                                index = index + 1;
                            }
                        }
                    }
                }
            }
        }

        System.debug('Test3');

        // Iterate over PAST CONDITIONS for each member and set contained condition checkbox
        if (!pastConditionsList.isEmpty()) {
            for (Object pastCondition : pastConditionsList) {
                Map<String,Object> tempPastConditionMap = (Map<String,Object>)pastCondition;
                List<String> memberSelectedConditions = (List<String>)tempPastConditionMap.get('MULSEL_Conditions');
                for (String selPastCondition : memberSelectedConditions) {
                    if (tempPastConditionMap.get('memberId') == primaryMember.get('Id')) {
                        checkboxTabs.put('SectionA Primary PastConditions', true);
                        checkboxTabs.put('P.' + pastConditionsDocuSignMap.get(selPastCondition), true);
                    }
                    if (spouseMember != null) {
                        if (tempPastConditionMap.get('memberId') == spouseMember.get('Id')) {
                            checkboxTabs.put('SectionA Spouse PastConditions', true);
                            checkboxTabs.put('S.' + pastConditionsDocuSignMap.get(selPastCondition), true);
                        }  
                    }
                    if (dependents != null) {
                        Integer index = 1;
                        for (Object dep : dependents) {
                            Map<String,Object> depMap = (Map<String,Object>)dep;
                            if (tempPastConditionMap.get('memberId') == depMap.get('Id')) {
                                checkboxTabs.put('SectionA Dependent' + index + ' PastConditions', true);
                                checkboxTabs.put('D' + index + '.' +pastConditionsDocuSignMap.get(selPastCondition), true);
                            }
                            index = index + 1;
                        }
                    }
                }
            }
        }

        System.debug('Test4');

        // Iterate over Cancer member list
        System.debug(cancerTrueList);
        if (!cancerTrueList.isEmpty()) {
            Integer index = 1;
            for (Object cancerTrue : cancerTrueList) {
                Map<String,Object> cancerTrueMap = (Map<String,Object>)cancerTrue;
                if (cancerTrueMap.get('CHK_MemberBeenDiagnosedWithCancer') == true) {
                    textTabs.put('MemberRow' + index, cancerTrueMap.get('TXT_MemberNameCancer'));
                    textTabs.put('NoteRow' + index, 'Cancers: ' + cancerTrueMap.get('TXT_TypeOfCancer'));
                    textTabs.put('DateRow' + index, cancerTrueMap.get('DATE_Cancer'));
                    index = index + 1;
                }
                if (cancerTrueMap.containsKey('MULSEL_Conditions')) {
                    textTabs.put('MemberRow' + index, cancerTrueMap.get('TXT_MemberPastConditions'));
                    textTabs.put('NoteRow' + index, cancerTrueMap.get('MULSEL_Conditions'));
                    textTabs.put('DateRow' + index, 'N/A');
                    index = index + 1;
                }
            }
        }

        System.debug('Test5');

        // Iterate over prescription medications member list
        System.debug(prescriptionsTrueList);
        if (!prescriptionsTrueList.isEmpty()) {
            Integer index = 1;
            for (Object prescriptionTrue : prescriptionsTrueList) {
                Map<String,Object> prescriptionTrueMap = (Map<String,Object>)prescriptionTrue;   
                textTabs.put('Family MemberRow' + index, prescriptionTrueMap.get('TXT_MemberName'));
                textTabs.put('Name of MedicationRow' + index, prescriptionTrueMap.get('TXT_NameOfMedication'));
                textTabs.put('Reason for MedicationRow' + index, prescriptionTrueMap.get('TXT_ReasonForMedication'));
                textTabs.put('Date prescribed MoYrRow' + index, prescriptionTrueMap.get('TXT_DatePrescribed'));
                textTabs.put('Date Discontinued MoYrRow' + index, prescriptionTrueMap.get('TXT_DateDiscontinued'));
                textTabs.put('Prescribing PhysicianRow' + index, prescriptionTrueMap.get('TXT_PrescribingPhysician'));
                index = index + 1;
            }
        }



        // MEDICAL QUESTIONS   
        
        System.debug('Test6');

        // Iterate over Primary keys
        if (primaryMember != null) {
            for (String key : primaryMember.keySet()) {
                Object value = (Object)primaryMember.get(key);
                if (key == 'Smoker'|| key == 'Pregnant' || key == 'Gender') continue;
                if (value == true || value == false) {
                    checkboxTabs.put('Primary.'+key, value); // Primary checkbox keys
                }
                else { 
                    textTabs.put('Primary.'+key, value); // Primary string keys
                }
            }
            // Set cancer checkbox for primary
            if (cancerTrueList != null) {
                for (Object cancerTrue : cancerTrueList) {
                    Map<String,Object> cancerTrueMap = (Map<String,Object>)cancerTrue;
                    if (cancerTrueMap.get('TXT_MemberIdCancer') == primaryMember.get('Id')) {
                        checkboxTabs.put('SectionA Primary' + ' Cancers', true);
                    }
                }
            }
            // Set Gender, Smoker and Pregnant docusign keys for Primary
            checkboxTabs.put('Primary.'+ primaryMember.get('Gender'), primaryMember.get('Gender') != null ? true : false);
            checkboxTabs.put('Primary.Smoker', primaryMember.get('Smoker') == true ? true : false);
            checkboxTabs.put('Primary.NotSmoker', primaryMember.get('Smoker') != true ? true : false);
            checkboxTabs.put('Primary.Pregnant', primaryMember.get('Pregnant') == true ? true : false);
            checkboxTabs.put('Primary.NotPregnant', primaryMember.get('Pregnant') != true ? true : false);
        }

        System.debug('Test7');

        // Iterate over Spouse keys
        if (spouseMember != null) {
            for (String key : spouseMember.keySet()) {
                if (key == 'Smoker'|| key=='Pregnant' || key == 'Gender') continue;
                Object value = (Object)spouseMember.get(key);
                if (value == true || value == false) {
                    checkboxTabs.put('Spouse.'+key, value); // Spouse checkbox keys
                }
                else { 
                    textTabs.put('Spouse.'+key, value); // Spouse string keys
                }
            }
            // Set cancer checkbox for Spouse
            if (cancerTrueList != null) {
                for (Object cancerTrue : cancerTrueList) {
                    Map<String,Object> cancerTrueMap = (Map<String,Object>)cancerTrue;
                    if (cancerTrueMap.get('TXT_MemberIdCancer') == spouseMember.get('Id')) {
                        checkboxTabs.put('SectionA Spouse' + ' Cancers', true);
                    }
                }
            }
            
            // Set Gender, Smoker and Pregnant docusign keys for Spouse
            checkboxTabs.put('Spouse.'+ spouseMember.get('Gender'), spouseMember.get('Gender') != null ? true : false);
            checkboxTabs.put('Spouse.Smoker', spouseMember.get('Smoker') == true ? true : false);
            checkboxTabs.put('Spouse.NotSmoker', spouseMember.get('Smoker') != true ? true : false);
            checkboxTabs.put('Spouse.Pregnant', spouseMember.get('Pregnant') == true ? true : false);
            checkboxTabs.put('Spouse.NotPregnant', spouseMember.get('Pregnant') != true ? true : false);
        }

        System.debug('Test8');

        // Iterate over Dependent list
        if (dependents != null) {
            Integer index = 1;
            for (Object dep : dependents) {
                Map<String,Object> depMap = (Map<String,Object>)dep;
                for (String key : depMap.keySet()) {
                    if (key == 'Smoker'|| key=='Pregnant' || key == 'Gender') continue;
                    Object value = (Object)depMap.get(key);
                    if (value == true || value == false) {
                        checkboxTabs.put('Dependent'+index+'.'+key, value); // Dependents checkbox keys
                    }
                    else { 
                        textTabs.put('Dependent'+index+'.'+key, value); // Dependents string keys
                    }
                }
                // Set cancer checkbox for dependents
                if (cancerTrueList != null) {
                    for (Object cancerTrue : cancerTrueList) {
                        Map<String,Object> cancerTrueMap = (Map<String,Object>)cancerTrue;
                        if (cancerTrueMap.get('TXT_MemberIdCancer') == depMap.get('Id')) {
                            checkboxTabs.put('SectionA Dependent'+ index + ' Cancers', true);
                        }
                    }
                }

                checkboxTabs.put('Dependent'+index+'.'+depMap.get('Gender'), depMap.get('Gender') != null ? true : false);
                checkboxTabs.put('Dependent'+index+'.Smoker', depMap.get('Smoker') == true ? true : false);
                checkboxTabs.put('Dependent'+index+'.NotSmoker', depMap.get('Smoker') != true ? true : false);
                checkboxTabs.put('Dependent'+index+'.Pregnant', depMap.get('Pregnant') == true ? true : false);
                checkboxTabs.put('Dependent'+index+'.NotPregnant', depMap.get('Pregnant') != true ? true : false);
                index = index + 1;
            }
        } 

        System.debug('Test9');

        // Iterate over member list and get New, Removed or Existing members
        List<String> addedMemberList = new List<String>();
        List<String> removedMemberList = new List<String>();
        List<String> inactiveMemberList = new List<String>();
        List<Object> allMemberList = new List<Object>();
        allMemberList = (List<Object>)inputMap.get('allMembersInfo');
        if (allMemberList != null) {
            for (Object oldMember : allMemberList) {
                Map<String,Object> oldMemberMap = (Map<String,Object>)oldMember;
                if (oldMemberMap.get('IsNewMember') == true) {
                    String memberName = (String)oldMemberMap.get('vlocity_ins__FirstName__c')+' '+(String)oldMemberMap.get('vlocity_ins__LastName__c');
                    addedMemberList.add(memberName);
                }
                if (oldMemberMap.get('IsRemoveMember') == true) {
                    System.debug('llego a removed member');
                    String memberName = (String)oldMemberMap.get('vlocity_ins__FirstName__c')+' '+(String)oldMemberMap.get('vlocity_ins__LastName__c');
                    System.debug(memberName);
                    removedMemberList.add(memberName);
                }
                if (oldMemberMap.get('IsInactiveMember') == true) {
                    String memberName = (String)oldMemberMap.get('vlocity_ins__FirstName__c')+' '+(String)oldMemberMap.get('vlocity_ins__LastName__c');
                    inactiveMemberList.add(memberName);
                }
            }
        }


        // Concatenate all Requested Changes and set the key
        List<String> requestedChanges = new List<String>();
        System.debug(pcReasons);
        for (String reason : pcReasons) {
            if (reason == 'Add Member') {
                requestedChanges.add(effectiveDate +' '+ reason +' '+ (addedMemberList != null ? String.join(addedMemberList, ', ') : '')); // Add the added members names
            }
            else if (reason == 'Remove Member') {
                requestedChanges.add(effectiveDate +' '+ reason +' '+ (removedMemberList != null ? String.join(removedMemberList, ', ') : '')); // Add the removed members names
            }
            else if (reason == 'Add Existing Member') {
                requestedChanges.add(effectiveDate +' '+ reason +' '+ (inactiveMemberList != null ? String.join(inactiveMemberList, ', ') : '')); // Add the inactive members names
            }
            else if (reason == 'Program Upgrade' || reason == 'Program Downgrade') {
                String productName = (String)((Map<String,Object>)(((Map<String,Object>)inputMap.get('newMedicalProduct')).get('selectedProduct'))).get('Name');
                requestedChanges.add(effectiveDate +' '+ reason +' to '+ productName);
            }
            else {
                requestedChanges.add(effectiveDate +' '+ reason);
            }
        }
        textTabs.put('Info.RequestedChanges', String.join(requestedChanges,'\n'));
        System.debug(String.join(requestedChanges,'\n'));

        System.debug('Test10');

        // PLAN AND PAYMENT INFO
        // Get product names and their members
        if (oldProductList != null) {
            Map<String,String> oldProductsMap = processProductMemberList(oldProductList);
            System.debug(oldProductsMap.get('memberProducts'));
            System.debug(oldProductsMap.get('productNames'));
            textTabs.put('Info.MembersPerProgramOld', oldProductsMap.get('memberProducts'));
            textTabs.put('Info.CurrentProgram', oldProductsMap.get('productNames')); // Set current programs key
            if (newProductList.isEmpty()) {
                System.debug('new product list is NULL');
                textTabs.put('Info.MembersPerProgram', oldProductsMap.get('memberProducts'));
                textTabs.put('Info.MembersPerProgramNew', oldProductsMap.get('memberProducts'));
            }
        }
        System.debug('new product list size is:' + newProductList.size());
        System.debug(newProductList.isEmpty() ? 'EMPTY' : 'NOT EMPTY' );
        if (!newProductList.isEmpty()) {
            Map<String,String> newProductsMap = processProductMemberList(newProductList);
            System.debug(newProductsMap.get('memberProducts'));
            textTabs.put('Info.MembersPerProgram', newProductsMap.get('memberProducts'));
            textTabs.put('Info.MembersPerProgramNew', newProductsMap.get('memberProducts'));
        }   
        
        textTabs.put('Plan.EffectiveDate', effectiveDate); // Set eff date key
        textTabs.put('Info.ReasonForChange', pcChanges.get('pcReasonsString')); // Set pc reasons string key

        Decimal monthlyAmountDecimal;
        Decimal feeAmountDecimal = Decimal.valueOf((Integer)pcChanges.get('feeAmount'));
        textTabs.put('Plan.ApplicationFee', '$ ' + String.valueOf(feeAmountDecimal)); // Set fee amount key
        if ((Boolean)pcChanges.get('createNewContract')) {
            String monthlyAmountString = (String)((Map<String,Object>)((Map<String,Object>)DocuSign.get('PlanSummary')).get('BLK_ProductSummary')).get('TXT_MonthlyPrice');
            monthlyAmountDecimal = Decimal.valueOf(monthlyAmountString.replace('$', '').replace(',', ''));
            textTabs.put('Plan.MonthlyContribution', monthlyAmountString);
            textTabs.put('Payment.MonthlyContribution', monthlyAmountString);

            textTabs.put('Payment.Fee', '$ ' + String.valueOf(feeAmountDecimal));
        }
        System.debug('Monthly DECIMAL:'+monthlyAmountDecimal);

        // PAYMENT INFORMATION
        // Get current chargent order to get current payment method
        if (DocuSign.get('SelectedContractInfo') != null) {
            selectedContractInfo = (Map<string,Object>)DocuSign.get('SelectedContractInfo'); // Get selected contract information
            contractId = (Id)selectedContractInfo.get('ContractID'); // Get selected contract ID
            // Get chargent order linked to selected contract
            ChargentOrders__ChargentOrder__c currentChargentOrder = [SELECT Id, ChargentOrders__Payment_Method__c, ChargentOrders__Credit_Card_Name__c, ChargentOrders__Card_Type__c, ChargentOrders__Card_Last_4__c, ChargentOrders__Card_Year_Indicator__c, ChargentOrders__Billing_Address__c, ChargentOrders__Billing_City__c, ChargentOrders__Billing_State__c, ChargentOrders__Billing_Zip_Postal__c, ChargentOrders__Bank_Name__c, ChargentOrders__Bank_Account_Type__c, ChargentOrders__Bank_Account_Name__c, ChargentOrders__Bank_Account_Last_4__c, ChargentOrders__Bank_Routing_Number__c FROM ChargentOrders__ChargentOrder__c WHERE ARC_Contract__c = :contractId LIMIT 1];
            fullAddressList.add(currentChargentOrder.ChargentOrders__Billing_Address__c);
            fullAddressList.add(currentChargentOrder.ChargentOrders__Billing_City__c);
            fullAddressList.add(currentChargentOrder.ChargentOrders__Billing_State__c);
            fullAddressList.add(currentChargentOrder.ChargentOrders__Billing_Zip_Postal__c);
    
            if (currentChargentOrder != null) {
                // CURRENT CREDIT CARD payment method path
                if (currentChargentOrder.ChargentOrders__Payment_Method__c == 'Credit Card') {
                    checkboxTabs.put('Payment.CreditCardPayment', true);
                    textTabs.put('Payment.NameOnCard', currentChargentOrder.ChargentOrders__Credit_Card_Name__c);
                    textTabs.put('Payment.CardNumber', '**** **** **** ' + currentChargentOrder.ChargentOrders__Card_Last_4__c);
                    textTabs.put('Payment.CardExpYear', currentChargentOrder.ChargentOrders__Card_Year_Indicator__c);
                    textTabs.put('Payment.BillingAddress', String.join(fullAddressList, ', '));
                    if (currentChargentOrder.ChargentOrders__Card_Type__c == 'Mastercard')  {
                        checkboxTabs.put('Payment.MasterCard', true);
                    } else {checkboxTabs.put('Payment.'+currentChargentOrder.ChargentOrders__Card_Type__c, true);
                    }
                    // CURRENT BANK ACCOUNT payment method path
                } else if (currentChargentOrder.ChargentOrders__Payment_Method__c == 'Bank Account') {
                    checkboxTabs.put('Payment.BankAccountPayment', true);
                    textTabs.put('Payment.BankName', currentChargentOrder.ChargentOrders__Bank_Name__c);
                    checkboxTabs.put('Payment.Checking', currentChargentOrder.ChargentOrders__Bank_Account_Type__c == 'Checking Account' ? true : false);
                    checkboxTabs.put('Payment.Savings', currentChargentOrder.ChargentOrders__Bank_Account_Type__c == 'Savings' ? true : false);
                    textTabs.put('Payment.NameOnBankAccount', currentChargentOrder.ChargentOrders__Bank_Account_Name__c);
                    textTabs.put('Payment.AccountNumber', '************'+currentChargentOrder.ChargentOrders__Bank_Account_Last_4__c);
                    textTabs.put('Payment.Routing', String.valueOf(currentChargentOrder.ChargentOrders__Bank_Routing_Number__c));
                }
            }
        }

        if ((Boolean)pcChanges.get('feeApplicable') == true) {
            paymentChangeFee = (Map<String,Object>)DocuSign.get('Step_PaymentChangeFee');
            if (paymentChangeFee.get('RAD_ChargeAppFeeDefTrue') == 'Yes') {
                keepCurrentPaymentMethod = (String)((Map<String,Object>)paymentChangeFee.get('BLK_ChargeFee')).get('RAD_KeepRecurringMethodOfPayment');
                if (((Map<String,Object>)paymentChangeFee.get('BLK_ChargeFee')).containsKey('LWC_PromoDiscountCodeRefactor') && ((Map<String,Object>)paymentChangeFee.get('BLK_ChargeFee')).get('LWC_PromoDiscountCodeRefactor') != null) {
                    if ((String)((Map<String,Object>)((Map<String,Object>)paymentChangeFee.get('BLK_ChargeFee')).get('LWC_PromoDiscountCodeRefactor')).get('ApplyOver') == 'Change Fee') {
                        Decimal feeDiscount = Decimal.valueOf((String)((Map<String,Object>)((Map<String,Object>)paymentChangeFee.get('BLK_ChargeFee')).get('LWC_PromoDiscountCodeRefactor')).get('DiscountAmount'));
                        textTabs.put('Plan.ApplicationFee', '$ ' + String.valueOf(feeAmountDecimal-feeDiscount)); // Set fee amount with discount
                        textTabs.put('Payment.Fee', '$ ' + String.valueOf(monthlyAmountDecimal+feeAmountDecimal-feeDiscount));
                    } else if ((String)((Map<String,Object>)((Map<String,Object>)paymentChangeFee.get('BLK_ChargeFee')).get('LWC_PromoDiscountCodeRefactor')).get('ApplyOver') == 'Medical') {
                        String discountAmountString = (String)((Map<String,Object>)((Map<String,Object>)paymentChangeFee.get('BLK_ChargeFee')).get('LWC_PromoDiscountCodeRefactor')).get('DiscountAmount');
                        System.debug(discountAmountString);
                        Decimal discountAmountDecimal = monthlyAmountDecimal - Decimal.valueOf(discountAmountString.replace(',', ''));
                        System.debug(discountAmountDecimal);
                        textTabs.put('Payment.MonthlyContribution', '$ ' + String.valueOf(discountAmountDecimal));
                        textTabs.put('Payment.Fee', '$ ' + String.valueOf(discountAmountDecimal+feeAmountDecimal));
                    }
                }
            }

            // // Check if current payment method is kept
            // if ((paymentChangeFee.get('RAD_ChargeAppFeeDefTrue') == 'Yes' && keepCurrentPaymentMethod == 'Yes') || paymentChangeFee.get('RAD_ChargeAppFeeDefTrue') == 'No') { // Fee charge, then check if payment information is updated or not
            //     if (currentChargentOrder != null) {
            //         // CURRENT CREDIT CARD payment method path
            //         if (currentChargentOrder.ChargentOrders__Payment_Method__c == 'Credit Card') {
            //             checkboxTabs.put('Payment.CreditCardPayment', true);
            //             textTabs.put('Payment.NameOnCard', currentChargentOrder.ChargentOrders__Credit_Card_Name__c);
            //             textTabs.put('Payment.CardNumber', '**** **** **** ' + currentChargentOrder.ChargentOrders__Card_Last_4__c);
            //             textTabs.put('Payment.CardExpYear', currentChargentOrder.ChargentOrders__Card_Year_Indicator__c);
            //             textTabs.put('Payment.BillingAddress', String.join(fullAddressList, ', '));
            //             if (currentChargentOrder.ChargentOrders__Card_Type__c == 'Mastercard')  {
            //                 checkboxTabs.put('Payment.MasterCard', true);
            //             } else {checkboxTabs.put('Payment.'+currentChargentOrder.ChargentOrders__Card_Type__c, true);
            //             }
            //             // CURRENT BANK ACCOUNT payment method path
            //         } else if (currentChargentOrder.ChargentOrders__Payment_Method__c == 'Bank Account') {
            //             checkboxTabs.put('Payment.BankAccountPayment', true);
            //             textTabs.put('Payment.BankName', currentChargentOrder.ChargentOrders__Bank_Name__c);
            //             checkboxTabs.put('Payment.Checking', currentChargentOrder.ChargentOrders__Bank_Account_Type__c == 'Checking Account' ? true : false);
            //             checkboxTabs.put('Payment.Savings', currentChargentOrder.ChargentOrders__Bank_Account_Type__c == 'Savings' ? true : false);
            //             textTabs.put('Payment.NameOnBankAccount', currentChargentOrder.ChargentOrders__Bank_Account_Name__c);
            //             textTabs.put('Payment.AccountNumber', '************'+currentChargentOrder.ChargentOrders__Bank_Account_Last_4__c);
            //             textTabs.put('Payment.Routing', String.valueOf(currentChargentOrder.ChargentOrders__Bank_Routing_Number__c));
            //         }
            //     }
            // }
            if (paymentChangeFee.get('RAD_ChargeAppFeeDefTrue') == 'Yes' && keepCurrentPaymentMethod == 'No') {
                System.debug('Entro a payment');
                Map<string,Object> updatedMethodInfo = (Map<String,Object>)((Map<String,Object>)paymentChangeFee.get('BLK_ChargeFee')).get('BLK_PaymentInfo');
                // CREDIT CARD UPDATED payment method path
                if ((String)((Map<String,Object>)paymentChangeFee.get('BLK_ChargeFee')).get('RAD_MethodOfPayment') == 'Credit Card') {
                    checkboxTabs.put('Payment.CreditCardPayment', true);
                    Map<string,Object> paymentInfo = (Map<string,Object>)updatedMethodInfo.get('BLK_CreditCard');
                    textTabs.put('Payment.NameOnCard', paymentInfo.get('TXT_FirstNameOnCard')+' '+ paymentInfo.get('TXT_LastNameOnCard'));
                    textTabs.put('Payment.CardNumber', '**** **** **** ' + ((String)paymentInfo.get('TXT_CardNumber')).right(4));
                    textTabs.put('Payment.CardExpYear', paymentInfo.get('SLC_ExpirationMonth') + '/' + paymentInfo.get('SLC_Year'));
                    textTabs.put('Payment.BillingAddress', paymentInfo.get('TXT_BillingAddress_Street')+', '+paymentInfo.get('TXT_BillingAddress_City')+', '+paymentInfo.get('TXT_BillingAddress_State')+', '+paymentInfo.get('TXT_BillingAddress_ZipCode'));
                    checkboxTabs.put('Payment.'+creditCardTypeMap.get(((String)paymentInfo.get('TXT_CardNumber')).substring(0,1)), true);
                }
                // BANK ACCOUNT UPDATED payment method path
                else if ((String)((Map<String,Object>)paymentChangeFee.get('BLK_ChargeFee')).get('RAD_MethodOfPayment') == 'Bank Account') { 
                    checkboxTabs.put('Payment.BankAccountPayment', true);
                    Map<string,Object> paymentInfo = (Map<string,Object>)updatedMethodInfo.get('BLK_BankAccount');
                    textTabs.put('Payment.BankName', paymentInfo.get('TXT_BankName'));
                    checkboxTabs.put('Payment.Checking', paymentInfo.get('SLC_AccType') == 'Checking' ? true : false);
                    checkboxTabs.put('Payment.Savings', paymentInfo.get('SLC_AccType') == 'Savings' ? true : false);
                    textTabs.put('Payment.NameOnBankAccount', paymentInfo.get('TXT_FirstNameOnAccount')+' '+paymentInfo.get('TXT_LastNameOnAccount'));
                    textTabs.put('Payment.AccountNumber', '************'+((String)paymentInfo.get('TXT_AccNumber')).right(4));
                    textTabs.put('Payment.Routing', paymentInfo.get('TXT_RoutingNumber'));
                }
            }
        }

        System.debug('Test11');

        // MEDICARE FOR LEGACY
        Object medicare_obj = DocuSign.get('Medicare');
        System.debug('Test MEDICARE: ' + medicare_obj);
        if (medicare_obj != null && medicare_obj != '') {
            Map<String, Object> medicare = (Map<String, Object>)medicare_obj;
            if ((String)medicare.get('RAD_MedicareId') == 'Yes') {
                Map<String,Object> medicareInfo = (Map<String,Object>)medicare.get('BLK_MedicareId');
                // Medicare ID
                System.debug('Medicare ID: ' + medicareInfo.get('MedicareIdNumber'));
                textTabs.put('Medicare.Number', medicareInfo.containsKey('MedicareIdNumber') ? medicareInfo.get('MedicareIdNumber') : null);
                // Medicare Part A
                checkboxTabs.put('Medicare.PartA', medicareInfo.containsKey('FRML_Show_Part_A_Effective_Date') ? (Boolean)medicareInfo.get('FRML_Show_Part_A_Effective_Date') : null);
                textTabs.put('Medicare.EffectiveDateA', medicareInfo.containsKey('Medicare_A_Effective_Date') && medicareInfo.get('Medicare_A_Effective_Date') != null  ? String.valueOf(date.valueOf((String)medicareInfo.get('Medicare_A_Effective_Date'))) : null);
                // Medicare Part B
                checkboxTabs.put('Medicare.PartB', medicareInfo.containsKey('FRML_Show_Part_B_Effective_Date') ? (Boolean)medicareInfo.get('FRML_Show_Part_B_Effective_Date') : null);
                textTabs.put('Medicare.EffectiveDateB', medicareInfo.containsKey('Part_B_Effective_Date') && medicareInfo.get('Part_B_Effective_Date') != null  ? String.valueOf(date.valueOf((String)medicareInfo.get('Part_B_Effective_Date'))) : null);
                // Medicare Part D
                checkboxTabs.put('Medicare.PartD', medicareInfo.containsKey('FRML_Show_Part_D_Effective_Date') ? (Boolean)medicareInfo.get('FRML_Show_Part_D_Effective_Date') : null);
                textTabs.put('Medicare.EffectiveDateD', medicareInfo.containsKey('Part_D_Effective_Date') && medicareInfo.get('Part_D_Effective_Date') != null ? String.valueOf(date.valueOf((String)medicareInfo.get('Part_D_Effective_Date'))) : null);
            }
        }

        // AGENT NAME
        Id agentId = (Id)DocuSign.get('userId');
        User agent = [SELECT Id,Name FROM User WHERE Id = :agentId LIMIT 1];
        if (agent != null) {
            textTabs.put('Agent.Name', agent.Name);
        }

        // CALIFORNIA TEMPLATE
        String primaryState = (String)inputMap.get('primaryState');
        if (primaryState == 'CA') {
            // PRIMARY NAME CA
            textTabs.put('Primary.Name', primaryMember.get('FirstName') +' '+ primaryMember.get('LastName'));
            // HIPAA
            List<Object> hipaaList = (List<Object>)DocuSign.get('Hipaa');
            Integer index = 1;
            for (Object hipaa : hipaaList) {
                Map<String,Object> hipaaMap = (Map<String,Object>)hipaa;
                textTabs.put('Hipaa' + index, (String)hipaaMap.get('TXT_FullName'));
                index = index + 1;
            }
            // DOB2
            textTabs.put('Primary.DOB2', (String)primaryMember.get('DOB'));
            if (spouseMember != null) {
                textTabs.put('Spouse.DOB2', (String)spouseMember.get('DOB'));
            }
            if (dependents != null) {
                System.debug('test dependents');
                index = 1;
                for (Object dep : dependents) {
                    Map<String,Object> depMap =(Map<String,Object>)dep;
                    textTabs.put('Dependent'+index+'.DOB2', depMap.get('DOB'));
                    index = index + 1;
                }
            }
        }


        outputMap.put('tabs', new Map<String,Object>{
            'checkboxTabs' => checkboxTabs,
            'textTabs' => textTabs
        });
    }

    public static Map<String,String> processProductMemberList(List<Object> productMemberList) {
        Map<String,String> membersProgramsMap = new Map<String,String>();
        List<String> membersPerProgram = new List<String>();
        List<String> programNames = new List<String>();
        System.debug(productMemberList.size());
        System.debug(productMemberList);
        for (Object product : productMemberList) {
            Map<String,Object> productMap = (Map<String,Object>)product; // Map of each old product that contain nodes Name and Census Members
            String productName = (String)((Map<String,Object>)productMap.get('selectedProduct')).get('Name');
            programNames.add(productName);
            List<Object> tempMemberList = (List<Object>)productMap.get('userInputs'); // Temporary list of members of each old product
            List<String> memberStringList = new List<String>(); // List of strings of each member of each product
            for (Object tempMember : tempMemberList) { // Iterate over the list of members of each product
                String fullMemberName = (String)((Map<String,Object>)tempMember).get('FirstName')+' '+(String)((Map<String,Object>)tempMember).get('LastName');
                memberStringList.add(fullMemberName);
            }
            
            String productMember = productName + ': ' + String.join(memberStringList, ', ');
            if ((String)((Map<String,Object>)productMap.get('selectedProduct')).get('Type__c') == 'Medical' && !membersPerProgram.isEmpty()) {
                membersPerProgram.add(0,productMember);
            }
            else {
                membersPerProgram.add(productMember);
            }
        }
        membersProgramsMap.put('memberProducts', String.join(membersPerProgram, '\n'));
        membersProgramsMap.put('productNames', String.join(programNames,', '));

        return membersProgramsMap;
    }
}